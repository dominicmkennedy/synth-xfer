from dataclasses import dataclass
from io import StringIO
import re
from typing import Any, Iterator, Literal, cast

from pysmt.environment import Environment
from pysmt.exceptions import SolverReturnedUnknownResultError
from pysmt.solvers.solver import Model as PySMTModel
from pysmt.typing import BOOL, BVType
from xdsl.context import Context
from xdsl.dialects.builtin import FunctionType, IntegerType, ModuleOp
from xdsl.dialects.func import FuncOp, ReturnOp
from xdsl.dialects.smt import BoolType, ConstantBoolOp
from xdsl.ir import Operation
from xdsl.transforms.canonicalize import CanonicalizePass
from xdsl_smt.dialects.smt_dialect import DefineFunOp
from xdsl_smt.dialects.transfer import (
    AbstractValueType,
    GetOp,
    MakeOp,
    TransIntegerType,
    TupleType,
)
from xdsl_smt.passes.dead_code_elimination import DeadCodeElimination
from xdsl_smt.passes.lower_effects import LowerEffectPass
from xdsl_smt.passes.lower_pairs import LowerPairs
from xdsl_smt.passes.lower_to_smt import func_to_smt_patterns
from xdsl_smt.passes.lower_to_smt.lower_to_smt import LowerToSMTPass
from xdsl_smt.passes.lower_to_smt.smt_lowerer import SMTLowerer
from xdsl_smt.passes.merge_func_results import MergeFuncResultsPass
from xdsl_smt.passes.transfer_inline import FunctionCallInline
from xdsl_smt.passes.transfer_unroll_loop import UnrollTransferLoop
from xdsl_smt.semantics.arith_semantics import arith_semantics
from xdsl_smt.semantics.builtin_semantics import IntegerTypeSemantics
from xdsl_smt.semantics.comb_semantics import comb_semantics
from xdsl_smt.semantics.transfer_semantics import (
    AbstractValueTypeSemantics,
    TransferIntegerTypeSemantics,
    transfer_semantics,
)
from xdsl_smt.traits.smt_printer import print_to_smtlib
from xdsl_smt.utils.transfer_function_check_util import (
    backward_soundness_check,
    forward_soundness_check,
)
from xdsl_smt.utils.transfer_function_util import (
    FunctionCollection,
    SMTTransferFunction,
    TransferFunction,
)

# TODO do we still need this
_TMP_MODULE: list[ModuleOp] = []

_DECLARE_CONST_BV_RE = re.compile(
    r"^\(declare-const\s+(\S+)\s+\(_\s+BitVec\s+(\d+)\s*\)\)\s*$"
)
_DECLARE_CONST_BOOL_RE = re.compile(r"^\(declare-const\s+(\S+)\s+Bool\)\s*$")
_DECLARE_FUN_BV_RE = re.compile(
    r"^\(declare-fun\s+(\S+)\s+\(\)\s+\(_\s+BitVec\s+(\d+)\s*\)\)\s*$"
)
_DECLARE_FUN_BOOL_RE = re.compile(r"^\(declare-fun\s+(\S+)\s+\(\)\s+Bool\)\s*$")
SMTSolverName = Literal["z3", "cvc5"]


@dataclass(frozen=True)
class BVCounterexampleModel:
    assignments: dict[str, int]

    def __iter__(self) -> Iterator[tuple[str, int]]:
        return iter(self.assignments.items())


def _ensure_z3_api() -> None:
    """
    PySMT expects the z3 python package to export solver APIs at top-level.
    Some environments expose them under z3.z3 only, so mirror those symbols.
    """
    import z3

    if hasattr(z3, "set_param"):
        return

    import z3.z3 as z3_impl

    for name in dir(z3_impl):
        if not hasattr(z3, name):
            setattr(z3, name, getattr(z3_impl, name))


def _declare_smt_symbols(env: Environment, smtlib: str) -> None:
    """
    Register declared constants in the PySMT environment so that model symbols
    round-trip to original names instead of anonymous backend names.
    """
    manager = env.formula_manager
    declared: set[str] = set()
    for raw_line in smtlib.splitlines():
        line = raw_line.strip()

        match = _DECLARE_CONST_BV_RE.match(line) or _DECLARE_FUN_BV_RE.match(line)
        if match is not None:
            name = match.group(1)
            if name not in declared:
                manager.Symbol(name, BVType(int(match.group(2))))
                declared.add(name)
            continue

        match = _DECLARE_CONST_BOOL_RE.match(line) or _DECLARE_FUN_BOOL_RE.match(line)
        if match is not None:
            name = match.group(1)
            if name not in declared:
                manager.Symbol(name, BOOL)
                declared.add(name)


def _strip_check_sat(smtlib: str) -> str:
    lines = [line for line in smtlib.splitlines() if line.strip() != "(check-sat)"]
    return "\n".join(lines)


def _ensure_set_logic(smtlib: str) -> str:
    for line in smtlib.splitlines():
        if line.strip().startswith("(set-logic "):
            return smtlib
    return "(set-logic ALL)\n" + smtlib


def _extract_bv_assignments(model: PySMTModel) -> BVCounterexampleModel:
    assignments: dict[str, int] = {}
    for symbol, value in model:
        if symbol.is_symbol() and value.is_bv_constant():
            assignments[symbol.symbol_name()] = value.bv_unsigned_value()
    return BVCounterexampleModel(assignments)


def _verify_pattern_z3(smtlib: str, timeout: int) -> tuple[bool | None, BVCounterexampleModel | None]:
    env = Environment()
    _declare_smt_symbols(env, smtlib)
    with env.factory.Solver(name="z3", solver_options={"timeout": timeout * 1000}) as s:
        solver_impl = cast(Any, s)
        solver_impl.z3.from_string(_strip_check_sat(smtlib))
        try:
            is_sat = s.solve()
        except SolverReturnedUnknownResultError:
            return None, None

        if is_sat:
            return False, _extract_bv_assignments(s.get_model())
        return True, None


def _verify_pattern_cvc5(
    smtlib: str, timeout: int
) -> tuple[bool | None, BVCounterexampleModel | None]:
    try:
        import cvc5 as cvc5_module
    except ImportError as e:
        raise RuntimeError("cvc5 python package is required for --solver cvc5") from e
    cvc5 = cast(Any, cvc5_module)

    solver = cvc5.Solver()
    solver.setOption("produce-models", "true")
    solver.setOption("tlimit-per", str(timeout * 1000))
    parser = cvc5.InputParser(solver)
    parser.setStringInput(
        cvc5.InputLanguage.SMT_LIB_2_6, _ensure_set_logic(smtlib), "query.smt2"
    )
    symbol_manager = parser.getSymbolManager()
    result: str | None = None
    while not parser.done():
        command = parser.nextCommand()
        if command.isNull():
            break
        out = command.invoke(solver, symbol_manager)
        if command.getCommandName() == "check-sat":
            result = str(out).strip()

    if result is None:
        result_obj = solver.checkSat()
        if result_obj.isSat():
            result = "sat"
        elif result_obj.isUnsat():
            result = "unsat"
        else:
            result = "unknown"

    if result.startswith("unknown"):
        return None, None
    if result.startswith("unsat"):
        return True, None
    if not result.startswith("sat"):
        raise RuntimeError(f"Unexpected cvc5 check-sat result: {result}")

    assignments: dict[str, int] = {}
    for term in symbol_manager.getDeclaredTerms():
        sort = term.getSort()
        if sort.isBitVector():
            value = solver.getValue(term)
            assignments[str(term)] = int(value.getBitVectorValue(10))
    return False, BVCounterexampleModel(assignments)


def _verify_pattern(
    ctx: Context, op: ModuleOp, timeout: int, solver_name: SMTSolverName
) -> tuple[bool | None, BVCounterexampleModel | None]:
    cloned_op = op.clone()
    LowerPairs().apply(ctx, cloned_op)
    CanonicalizePass().apply(ctx, cloned_op)
    DeadCodeElimination().apply(ctx, cloned_op)

    stream = StringIO()
    print_to_smtlib(cloned_op, stream)
    smtlib = stream.getvalue()
    _ensure_z3_api()
    if solver_name == "z3":
        return _verify_pattern_z3(smtlib, timeout)
    if solver_name == "cvc5":
        return _verify_pattern_cvc5(smtlib, timeout)
    raise ValueError(f"Unsupported solver: {solver_name}")


def _lower_to_smt_module(module: ModuleOp, width: int, ctx: Context):
    SMTLowerer.rewrite_patterns = {**func_to_smt_patterns}
    SMTLowerer.type_lowerers = {
        IntegerType: IntegerTypeSemantics(),
        AbstractValueType: AbstractValueTypeSemantics(),
        TransIntegerType: TransferIntegerTypeSemantics(width),
        TupleType: AbstractValueTypeSemantics(),
    }
    SMTLowerer.op_semantics = {
        **arith_semantics,
        **transfer_semantics,
        **comb_semantics,
    }

    LowerToSMTPass().apply(ctx, module)
    MergeFuncResultsPass().apply(ctx, module)
    LowerEffectPass().apply(ctx, module)


def _add_poison_to_conc_fn(concrete_func: FuncOp) -> FuncOp:
    """
    Input: a concrete function with shape (trans.integer, trans.integer) -> trans.integer
    Output: a new function with shape (tuple<trans.integer, bool>
    """
    result_func = concrete_func.clone()
    block = result_func.body.block
    # Add poison to every args
    new_arg_type = TupleType([TransIntegerType(), BoolType()])
    while isinstance(result_func.args[0].type, TransIntegerType):
        new_arg = block.insert_arg(new_arg_type, len(result_func.args))
        new_get_op = GetOp(new_arg, 0)
        assert block.first_op is not None
        block.insert_op_before(new_get_op, block.first_op)
        result_func.args[0].replace_by(new_get_op.result)
        block.erase_arg(result_func.args[0])
    last_op = block.last_op
    assert last_op is not None
    poison_val = ConstantBoolOp(False)
    poison_val.is_ancestor
    new_return_val = MakeOp([last_op.operands[0], poison_val.result])
    block.insert_ops_before([poison_val, new_return_val], last_op)
    last_op.operands[0] = new_return_val.result
    new_args_type = [arg.type for arg in result_func.args]
    new_return_type = new_return_val.result.type
    result_func.function_type = FunctionType.from_lists(new_args_type, [new_return_type])
    return result_func


def _create_smt_function(func: FuncOp, width: int, ctx: Context) -> DefineFunOp:
    """
    Input: a function with type FuncOp
    Return: the function lowered to SMT dialect with specified width

    We might reuse some function with specific width so we save it to global TMP_MODULE
    Class FunctionCollection is the only caller of this function and maintains all generated SMT functions
    """

    global _TMP_MODULE
    _TMP_MODULE.append(ModuleOp([func.clone()]))
    _lower_to_smt_module(_TMP_MODULE[-1], width, ctx)
    resultFunc = _TMP_MODULE[-1].ops.first
    assert isinstance(resultFunc, DefineFunOp)
    return resultFunc


def _soundness_check(
    smt_transfer_function: SMTTransferFunction,
    domain_constraint: FunctionCollection,
    instance_constraint: FunctionCollection,
    int_attr: dict[int, int],
    ctx: Context,
    timeout: int,
    solver_name: SMTSolverName,
) -> tuple[bool | None, BVCounterexampleModel | None]:
    query_module = ModuleOp([])
    if smt_transfer_function.is_forward:
        added_ops: list[Operation] = forward_soundness_check(
            smt_transfer_function,
            domain_constraint,
            instance_constraint,
            int_attr,
        )
    else:
        added_ops: list[Operation] = backward_soundness_check(
            smt_transfer_function,
            domain_constraint,
            instance_constraint,
            int_attr,
        )
    query_module.body.block.add_ops(added_ops)
    FunctionCallInline(True, {}).apply(ctx, query_module)

    return _verify_pattern(ctx, query_module, timeout, solver_name)


def _verify_smt_transfer_function(
    smt_transfer_function: SMTTransferFunction,
    domain_constraint: FunctionCollection,
    instance_constraint: FunctionCollection,
    ctx: Context,
    timeout: int,
    solver_name: SMTSolverName,
) -> tuple[bool | None, BVCounterexampleModel | None]:
    assert smt_transfer_function.concrete_function is not None
    assert smt_transfer_function.transfer_function is not None

    int_attr: dict[int, int] = {}
    soundness_result = _soundness_check(
        smt_transfer_function,
        domain_constraint,
        instance_constraint,
        int_attr,
        ctx,
        timeout,
        solver_name,
    )

    return soundness_result


def _build_init_module(
    transfer_function: FuncOp,
    concrete_func: FuncOp,
    helper_funcs: list[FuncOp],
    ctx: Context,
):
    INSTANCE_CONSTRAINT = "getInstanceConstraint"
    DOMAIN_CONSTRAINT = "getConstraint"

    func_name_to_func: dict[str, FuncOp] = {}
    module_op = ModuleOp([])
    functions: list[FuncOp] = [transfer_function.clone()]
    functions.append(_add_poison_to_conc_fn(concrete_func))
    module_op.body.block.add_ops(functions + [func.clone() for func in helper_funcs])
    domain_constraint: FunctionCollection | None = None
    instance_constraint: FunctionCollection | None = None
    transfer_function_obj: TransferFunction | None = None
    transfer_function_name = transfer_function.sym_name.data
    for func in module_op.ops:
        assert isinstance(func, FuncOp)
        func_name = func.sym_name.data
        if func_name in func_name_to_func:
            print(
                [func.sym_name.data for func in helper_funcs]
                + [transfer_function.sym_name.data]
            )
            raise ValueError("Found function with the same name in the input")

        func_name_to_func[func_name] = func

        # Check func validity
        assert len(func.function_type.inputs) == len(func.args)
        for func_type_arg, arg in zip(func.function_type.inputs, func.args):
            assert func_type_arg == arg.type
        return_op = func.body.block.last_op
        assert return_op is not None and isinstance(return_op, ReturnOp)
        assert return_op.operands[0].type == func.function_type.outputs.data[0]
        # End of check function type

        if func_name == transfer_function_name:
            assert transfer_function_obj is None
            transfer_function_obj = TransferFunction(func)
        if func_name == DOMAIN_CONSTRAINT:
            assert domain_constraint is None
            domain_constraint = FunctionCollection(func, _create_smt_function, ctx)
        elif func_name == INSTANCE_CONSTRAINT:
            assert instance_constraint is None
            instance_constraint = FunctionCollection(func, _create_smt_function, ctx)

    assert domain_constraint is not None
    assert instance_constraint is not None
    assert transfer_function_obj is not None

    func_name_to_func[transfer_function.sym_name.data] = transfer_function
    return (
        module_op,
        func_name_to_func,
        transfer_function_obj,
        domain_constraint,
        instance_constraint,
    )


def verify_transfer_function(
    transfer_function: FuncOp,
    concrete_func: FuncOp,
    helper_funcs: list[FuncOp],
    width: int,
    timeout: int,
    solver_name: SMTSolverName = "z3",
) -> tuple[bool | None, BVCounterexampleModel | None]:
    ctx = Context()

    (
        module_op,
        func_name_to_func,
        transfer_function_obj,
        domain_constraint,
        instance_constraint,
    ) = _build_init_module(transfer_function, concrete_func, helper_funcs, ctx)

    FunctionCallInline(False, func_name_to_func).apply(ctx, module_op)

    smt_module = module_op.clone()

    # expand for loops
    unrollTransferLoop = UnrollTransferLoop(width)
    assert isinstance(smt_module, ModuleOp)
    unrollTransferLoop.apply(ctx, smt_module)

    concrete_func_name: str = concrete_func.sym_name.data
    assert concrete_func_name is not None

    _lower_to_smt_module(smt_module, width, ctx)

    func_name_to_smt_func: dict[str, DefineFunOp] = {}
    for op in smt_module.ops:
        if isinstance(op, DefineFunOp):
            op_func_name = op.fun_name
            assert op_func_name is not None
            func_name = op_func_name.data
            func_name_to_smt_func[func_name] = op

    func_name = transfer_function.sym_name.data
    assert func_name is not None

    smt_concrete_func = func_name_to_smt_func.get(concrete_func_name, None)
    assert smt_concrete_func is not None
    smt_transfer_function = func_name_to_smt_func.get(func_name, None)
    abs_op_constraint = func_name_to_smt_func.get("abs_op_constraint", None)
    op_constraint = func_name_to_smt_func.get("op_constraint", None)

    smt_transfer_function_obj = SMTTransferFunction(
        transfer_function_obj,
        func_name,
        concrete_func_name,
        abs_op_constraint,
        op_constraint,
        None,
        None,
        None,
        None,
        smt_transfer_function,
        smt_concrete_func,
    )

    return _verify_smt_transfer_function(
        smt_transfer_function_obj,
        domain_constraint,
        instance_constraint,
        ctx,
        timeout,
        solver_name,
    )
