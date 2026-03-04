from argparse import (
    ArgumentDefaultsHelpFormatter,
    ArgumentParser,
    Namespace,
)
from io import StringIO
from pathlib import Path

from xdsl.context import Context
from xdsl.dialects.arith import Arith
from xdsl.dialects.builtin import Builtin, ModuleOp
from xdsl.dialects.func import Func, FuncOp
from xdsl.dialects.smt import BitVectorType, BoolType, ConstantBoolOp
from xdsl.ir import Operation
from xdsl.transforms.canonicalize import CanonicalizePass
from xdsl_smt.dialects.smt_bitvector_dialect import ConstantOp, ExtractOp
from xdsl_smt.dialects.smt_dialect import (
    AssertOp,
    CallOp,
    DeclareConstOp,
    DefineFunOp,
    EqOp,
)
from xdsl_smt.dialects.smt_utils_dialect import FirstOp, PairOp, PairType
from xdsl_smt.dialects.transfer import Transfer
from xdsl_smt.passes.dead_code_elimination import DeadCodeElimination
from xdsl_smt.passes.lower_pairs import LowerPairs
from xdsl_smt.passes.transfer_inline import FunctionCallInline
from xdsl_smt.traits.smt_printer import print_to_smtlib
from xdsl_smt.utils.transfer_function_util import get_argument_instances_with_effect
from z3 import Solver, parse_smt2_string, sat, unknown

from synth_xfer._util.parse_mlir import parse_mlir
from synth_xfer._util.verifier import _lower_to_smt_module


def _get_args() -> Namespace:
    p = ArgumentParser(formatter_class=ArgumentDefaultsHelpFormatter)

    p.add_argument("transfer_functions", type=Path, help="path to transfer function")
    p.add_argument("--domain", type=str, help="The abstract domain")
    p.add_argument("--args", type=str, help="The abstract arguments")
    p.add_argument(
        "--bitwidth", type=int, help="The bit width, default value is 8", default=8
    )
    p.add_argument(
        "--timeout", type=int, help="The z3 timeout default value is 5", default=5
    )
    return p.parse_args()


CONCRETE_FUNCTION_NAME = "concrete_op"
GET_INSTANCE_CONSTRAINT = "getInstanceConstraint"
OP_CONSTRAINT = "op_constraint"
ABSTRACT_DOMAIN_LENGTH = 0
TIMEOUT = 2


def get_concrete_func(op: ModuleOp) -> DefineFunOp:
    for func in op.ops:
        if isinstance(func, DefineFunOp):
            func_name = func.fun_name
            if func_name is not None and func_name == CONCRETE_FUNCTION_NAME:
                return func
    assert False


def get_instance_constraint(module: ModuleOp) -> DefineFunOp:
    for func in module.ops:
        if isinstance(func, DefineFunOp):
            func_name = func.fun_name
            if func_name is not None and func_name == GET_INSTANCE_CONSTRAINT:
                return func
    assert False


def get_op_constraint(module: ModuleOp) -> DefineFunOp | None:
    for func in module.ops:
        if isinstance(func, DefineFunOp):
            func_name = func.fun_name
            if func_name is not None and func_name == OP_CONSTRAINT:
                return func
    assert False


def parse_single_arg_knownbits(arg: str) -> list[int]:
    result = [0, 0]
    for ch in arg:
        if ch == "0":
            result[0] |= 1
        elif ch == "1":
            result[1] |= 1
        result[0] <<= 1
        result[1] <<= 1
    result[0] >>= 1
    result[1] >>= 1
    return result


def parse_args_str(args_str: str, domain: str, bitwidth: int) -> list[list[int]]:
    if domain == "KnownBits":
        global ABSTRACT_DOMAIN_LENGTH
        ABSTRACT_DOMAIN_LENGTH = 2
        args = args_str.split(",")
        result: list[list[int]] = []
        for i, arg in enumerate(args):
            if len(arg) != bitwidth:
                assert False and f"{i}-th arg mismatches with bitwidth {bitwidth}!"
            result.append(parse_single_arg_knownbits(arg))
        return result
    else:
        assert False and f"{domain} doesn't support right now"
        return []


def init_module(module: ModuleOp, domain: str):
    if domain == "KnownBits":
        get_instance_constraint_str = """
        "func.func"() ({
^bb0(%arg0: !transfer.abs_value<[!transfer.integer, !transfer.integer]>, %inst: !transfer.integer):
  %arg00 = "transfer.get"(%arg0) {index=0:index}: (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %arg01 = "transfer.get"(%arg0) {index=1:index}: (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer
  %neg_inst = "transfer.neg"(%inst) : (!transfer.integer) -> !transfer.integer
  %or1 = "transfer.or"(%neg_inst,%arg00): (!transfer.integer, !transfer.integer)->!transfer.integer
  %or2 = "transfer.or"(%inst,%arg01): (!transfer.integer, !transfer.integer)->!transfer.integer
  %cmp1="transfer.cmp"(%or1,%neg_inst){predicate=0:i64}:(!transfer.integer, !transfer.integer)->i1
  %cmp2="transfer.cmp"(%or2,%inst){predicate=0:i64}:(!transfer.integer, !transfer.integer)->i1
  %result="arith.andi"(%cmp1,%cmp2):(i1,i1)->i1
  "func.return"(%result) : (i1) -> ()
}) {function_type = (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.integer) -> i1, sym_name = "getInstanceConstraint"} : () -> ()
        """
        get_instance_constraint_func = parse_mlir(get_instance_constraint_str)
    else:
        assert False
    assert isinstance(get_instance_constraint_func, FuncOp)
    module.body.block.add_op(get_instance_constraint_func)


def get_abstract_input_arguments(
    concrete_args: list[DeclareConstOp],
) -> list[DeclareConstOp]:
    concrete_type = concrete_args[0].res.type
    assert isinstance(concrete_type, BitVectorType)
    abstract_type = BoolType()
    assert ABSTRACT_DOMAIN_LENGTH > 1
    for i in range(ABSTRACT_DOMAIN_LENGTH):
        abstract_type = PairType(concrete_type, abstract_type)
    return [DeclareConstOp(abstract_type) for _ in concrete_args]


def to_constant_ops(val_list: list[int], bitwidth: int) -> list[ConstantOp]:
    result: list[ConstantOp] = []
    for val in val_list:
        result.append(ConstantOp.from_int_value(val, bitwidth))
    return result


def to_pair_op(constant_bool: ConstantBoolOp, val_list: list[ConstantOp]) -> list[PairOp]:
    last_val = constant_bool.result
    result: list[PairOp] = []
    for val in val_list[::-1]:
        result.append(PairOp(val.res, last_val))
        last_val = result[-1].res
    return result


def get_abstract_input_constraint(
    const_false: ConstantBoolOp,
    abstract_inputs: list[DeclareConstOp],
    abstract_domains: list[list[int]],
    bitwidth: int,
) -> list[Operation]:
    result: list[Operation] = []
    for abstract_domain, abstract_input in zip(abstract_domains, abstract_inputs):
        constant_ops = to_constant_ops(abstract_domain, bitwidth)
        pair_op = to_pair_op(const_false, constant_ops)
        eq_op = EqOp(pair_op[-1].res, abstract_input.res)
        assert_op = AssertOp(eq_op.res)
        result += constant_ops + pair_op + [eq_op, assert_op]
    return result


def get_input_op_constraint(
    op_constraint: DefineFunOp, inputs: list[DeclareConstOp]
) -> list[Operation]:
    constant_i1 = ConstantOp.from_int_value(1, 1)
    constant_bool = ConstantBoolOp(False)
    pair_op = PairOp(constant_i1.res, constant_bool.result)
    pair_res_op = PairOp(pair_op.res, constant_bool.result)
    call_op = CallOp(op_constraint.ret, inputs + [constant_bool.result])
    eq_op = EqOp(pair_res_op.res, call_op.res[0])
    assert_op = AssertOp(eq_op.res)
    return [constant_i1, constant_bool, pair_op, pair_res_op, call_op, eq_op, assert_op]


def get_input_constraint(
    abstract_inputs: list[DeclareConstOp],
    inputs: list[DeclareConstOp],
    instance_constraint: DefineFunOp,
) -> list[Operation]:
    result: list[Operation] = []
    constant_i1 = ConstantOp.from_int_value(1, 1)
    constant_bool = ConstantBoolOp(False)
    pair_op = PairOp(constant_i1.res, constant_bool.result)
    pair_res_op = PairOp(pair_op.res, constant_bool.result)
    for abstract_input, concrete_input in zip(abstract_inputs, inputs):
        call_op = CallOp(
            instance_constraint.ret,
            [abstract_input, concrete_input, constant_bool.result],
        )
        eq_op = EqOp(pair_res_op.res, call_op.res[0])
        assert_op = AssertOp(eq_op.res)

        result += [call_op, eq_op, assert_op]
    return [constant_i1, constant_bool, pair_op, pair_res_op] + result


def check_sat(ctx: Context, module: ModuleOp) -> bool:
    FunctionCallInline(True, {}).apply(ctx, module)
    LowerPairs().apply(ctx, module)
    CanonicalizePass().apply(ctx, module)
    DeadCodeElimination().apply(ctx, module)
    stream = StringIO()
    print_to_smtlib(module, stream)
    s = Solver()
    s.set(timeout=TIMEOUT * 1000)
    s.add(parse_smt2_string(stream.getvalue()))
    r = s.check()
    assert r != unknown
    return r == sat


def query_ith_bit(ctx: Context, module: ModuleOp, ith_bit: int, bit_val: int) -> bool:
    block = module.body.block
    concrete_res = block.last_op
    assert isinstance(concrete_res, CallOp)
    first_op = FirstOp(concrete_res.res[0])
    ith_bit_op = ExtractOp(first_op.res, ith_bit, ith_bit)
    const_bv_op = ConstantOp.from_int_value(bit_val, 1)
    eq_op = EqOp(ith_bit_op.res, const_bv_op.res)
    assert_op = AssertOp(eq_op.res)
    block.add_ops([first_op, ith_bit_op, const_bv_op, eq_op, assert_op])
    return check_sat(ctx, module)


def check_ith_knownbit(ctx: Context, verify_module: ModuleOp, ith: int) -> str | None:
    query_zero_module = verify_module.clone()
    query_one_module = verify_module.clone()
    could_be_zero = query_ith_bit(ctx, query_zero_module, ith, 0)
    could_be_one = query_ith_bit(ctx, query_one_module, ith, 1)
    if could_be_one and could_be_zero:
        return "?"
    elif (not could_be_zero) and (not could_be_one):
        assert False and "found conflicts"
    elif not could_be_zero:
        return "1"
    elif not could_be_one:
        return "0"


def main() -> None:
    args = _get_args()
    ctx = Context()
    ctx.load_dialect(Arith)
    ctx.load_dialect(Builtin)
    ctx.load_dialect(Func)
    ctx.load_dialect(Transfer)

    module = parse_mlir(args.transfer_functions)
    assert isinstance(module, ModuleOp)

    domain = args.domain
    bitwidth = args.bitwidth
    args_str = args.args
    global TIMEOUT
    TIMEOUT = args.timeout
    abstract_domains = parse_args_str(args_str, domain, bitwidth)
    init_module(module, domain)

    _lower_to_smt_module(module, bitwidth, ctx)
    concrete_op = get_concrete_func(module)
    instance_constraint = get_instance_constraint(module)
    op_constraint = get_op_constraint(module)

    input_arguments = [
        arg
        for arg in get_argument_instances_with_effect(concrete_op, {})
        if isinstance(arg, DeclareConstOp)
    ]
    assert len(input_arguments) == len(concrete_op.func_type.inputs)
    abstract_input_arguments = get_abstract_input_arguments(input_arguments)
    const_false = ConstantBoolOp(False)
    abstract_input_constraints = get_abstract_input_constraint(
        const_false, abstract_input_arguments, abstract_domains, bitwidth
    )
    input_constraints = get_input_constraint(
        abstract_input_arguments, input_arguments, instance_constraint
    )
    input_op_constraint = []
    if op_constraint is not None:
        input_op_constraint = get_input_op_constraint(op_constraint, input_arguments)
    concrete_result = CallOp(concrete_op.ret, input_arguments)

    verify_module = ModuleOp(
        input_arguments
        + [const_false]
        + abstract_input_arguments
        + abstract_input_constraints
        + input_op_constraint
        + input_constraints
        + [concrete_result]
    )

    result = ""
    for i in range(bitwidth):
        ith_result = check_ith_knownbit(ctx, verify_module, i)
        assert ith_result is not None
        result = ith_result + result
    print(result)


if __name__ == "__main__":
    main()
