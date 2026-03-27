from argparse import (
    ArgumentDefaultsHelpFormatter,
    ArgumentParser,
    Namespace,
)
from dataclasses import dataclass, replace
from io import StringIO
from multiprocessing import Pool
from pathlib import Path

import pandas as pd
from xdsl.context import Context
from xdsl.dialects.arith import Arith
from xdsl.dialects.builtin import Builtin, ModuleOp
from xdsl.dialects.func import Func
from xdsl.dialects.smt import BitVectorType, BoolType, ConstantBoolOp
from xdsl.ir import Attribute, Operation
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

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.parse_mlir import get_helper_funcs
from synth_xfer._util.tsv import EnumData
from synth_xfer._util.verifier import lower_to_smt_module


def _get_args() -> Namespace:
    p = ArgumentParser(formatter_class=ArgumentDefaultsHelpFormatter)

    p.add_argument("--op", type=Path, help="path to op or pattern")
    p.add_argument("-i", "--input", type=Path, help="path to enum TSV")
    p.add_argument("-o", "--output", type=Path, help="output TSV path")
    p.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(x) for x in AbstractDomain],
        help="Abstract Domain",
    )
    p.add_argument("--args", type=str, help="The abstract arguments")
    p.add_argument("--bw", type=int, help="Bitwidth")
    p.add_argument("--timeout", type=int, help="z3 timeout", default=10)

    args = p.parse_args()
    if args.input is not None:
        invalid_flags: list[str] = []
        if args.op is not None:
            invalid_flags.append("--op")
        if args.domain is not None:
            invalid_flags.append("--domain")
        if args.args is not None:
            invalid_flags.append("--args")
        if args.bw is not None:
            invalid_flags.append("--bw")
        if invalid_flags:
            p.error(f"{', '.join(invalid_flags)} cannot be used with --input")
        return args

    missing_flags: list[str] = []
    if args.op is None:
        missing_flags.append("--op")
    if args.domain is None:
        missing_flags.append("--domain")
    if args.args is None:
        missing_flags.append("--args")
    if args.bw is None:
        missing_flags.append("--bw")
    if missing_flags:
        p.error(f"missing required arguments: {', '.join(missing_flags)}")
    if args.output is not None:
        p.error("--output can only be used with --input")
    return args


def _parse_kb_str(arg: str) -> tuple[int, int]:
    known_z, known_o = 0, 0

    for ch in arg:
        if ch == "0":
            known_z |= 1
        elif ch == "1":
            known_o |= 1
        known_z <<= 1
        known_o <<= 1

    known_z >>= 1
    known_o >>= 1
    return known_z, known_o


def _parse_args_str(
    args_str: str, domain: AbstractDomain, bitwidth: int
) -> list[tuple[int, int]]:
    if domain == AbstractDomain.KnownBits:
        args = args_str.split(",")
        result: list[tuple[int, int]] = []
        for arg in args:
            if len(arg) != bitwidth:
                raise ValueError(f"arg len: {len(arg)} != bitwidth: {bitwidth}")

            result.append(_parse_kb_str(arg))
        return result
    else:
        raise NotImplementedError(f"Max precise not implemented for {domain} yet")


def _get_abst_args(
    arity: int, conc_ty: Attribute, d: AbstractDomain
) -> list[DeclareConstOp]:
    assert isinstance(conc_ty, BitVectorType)

    abstract_type = BoolType()
    for _ in range(d.vec_size):
        abstract_type = PairType(conc_ty, abstract_type)

    return [DeclareConstOp(abstract_type) for _ in range(arity)]


def _to_pair_op(
    constant_bool: ConstantBoolOp, val_list: list[ConstantOp]
) -> list[PairOp]:
    last_val = constant_bool.result
    result: list[PairOp] = []
    for val in val_list[::-1]:
        result.append(PairOp(val.res, last_val))
        last_val = result[-1].res
    return result


def _get_abst_constraint(
    const_false: ConstantBoolOp,
    abst_arg_types: list[DeclareConstOp],
    abst_bitvectors: list[tuple[int, int]],
    bitwidth: int,
) -> list[Operation]:
    result: list[Operation] = []
    for abst_bv, abst_arg_type in zip(abst_bitvectors, abst_arg_types):
        constant_ops = [ConstantOp.from_int_value(x, bitwidth) for x in abst_bv]
        pair_op = _to_pair_op(const_false, constant_ops)
        eq_op = EqOp(pair_op[-1].res, abst_arg_type.res)
        assert_op = AssertOp(eq_op.res)
        result += constant_ops + pair_op + [eq_op, assert_op]
    return result


def _get_op_constraint(
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


def _get_in_constraint(
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


@dataclass(frozen=True)
class KnownBitsChecker:
    ctx: Context
    timeout: int

    def _make_z3_call(self, module: ModuleOp) -> bool:
        FunctionCallInline(True, {}).apply(self.ctx, module)
        LowerPairs().apply(self.ctx, module)
        CanonicalizePass().apply(self.ctx, module)
        DeadCodeElimination().apply(self.ctx, module)
        stream = StringIO()
        print_to_smtlib(module, stream)

        solver = Solver()
        solver.set(timeout=self.timeout * 1000)
        solver.add(parse_smt2_string(stream.getvalue()))

        result = solver.check()
        if result == unknown:
            raise TimeoutError()
        return result == sat

    def _ith_bit_is(self, module: ModuleOp, ith_bit: int, bit_val: int) -> bool:
        block = module.body.block
        concrete_res = block.last_op
        assert isinstance(concrete_res, CallOp)
        first_op = FirstOp(concrete_res.res[0])
        ith_bit_op = ExtractOp(first_op.res, ith_bit, ith_bit)
        const_bv_op = ConstantOp.from_int_value(bit_val, 1)
        eq_op = EqOp(ith_bit_op.res, const_bv_op.res)
        assert_op = AssertOp(eq_op.res)
        block.add_ops([first_op, ith_bit_op, const_bv_op, eq_op, assert_op])
        try:
            return self._make_z3_call(module)
        except TimeoutError:
            print(
                f"timeout after {self.timeout}s, checking if bit {ith_bit} can be {bit_val}"
            )
            raise

    def check_ith_bit(self, verify_module: ModuleOp, ith: int) -> str | None:
        can_be_z = self._ith_bit_is(verify_module.clone(), ith, 0)
        can_be_o = self._ith_bit_is(verify_module.clone(), ith, 1)
        if can_be_o and can_be_z:
            return "?"
        if (not can_be_z) and (not can_be_o):
            return None
        if not can_be_z:
            return "1"
        if not can_be_o:
            return "0"


@dataclass(frozen=True)
class RowTask:
    index: int
    op_path: Path
    domain: AbstractDomain
    bw: int
    args_str: str
    timeout: int


@dataclass(frozen=True)
class RowResult:
    index: int
    ideal: str | None = None
    timed_out: bool = False


def _resolve_metadata_op(op: str) -> Path:
    if op.startswith("pattern_"):
        return Path("mlir") / "Patterns" / f"{op.removeprefix('pattern_')}.mlir"
    return Path("mlir") / "Operations" / f"{op}.mlir"


def _compute_max_precise(
    op_path: Path,
    domain: AbstractDomain,
    bw: int,
    args_str: str,
    timeout: int,
) -> str:
    ctx = Context()
    ctx.load_dialect(Arith)
    ctx.load_dialect(Builtin)
    ctx.load_dialect(Func)
    ctx.load_dialect(Transfer)

    hlprs = get_helper_funcs(op_path, domain)
    abstract_args = _parse_args_str(args_str, domain, bw)

    fns = [hlprs.instance_constraint_func, hlprs.crt_func, hlprs.op_constraint_func]
    lower_to_smt_module(m := ModuleOp([x.clone() for x in fns if x is not None]), bw, ctx)
    m_ops = iter(m.ops)
    instance_constraint = next(m_ops)
    concrete_op = next(m_ops)
    op_constraint = next(m_ops, None)
    assert isinstance(instance_constraint, DefineFunOp)
    assert isinstance(concrete_op, DefineFunOp)
    assert isinstance(op_constraint, DefineFunOp) or op_constraint is None

    input_arguments = [
        arg
        for arg in get_argument_instances_with_effect(concrete_op, {})
        if isinstance(arg, DeclareConstOp)
    ]
    assert len(input_arguments) + 1 == len(concrete_op.func_type.inputs)
    smt_arg_type = _get_abst_args(
        len(input_arguments), input_arguments[0].res.type, domain
    )

    input_op_constraint = []
    if op_constraint is not None:
        input_op_constraint = _get_op_constraint(op_constraint, input_arguments)

    verify_module = ModuleOp(
        input_arguments
        + smt_arg_type
        + _get_abst_constraint(ConstantBoolOp(False), smt_arg_type, abstract_args, bw)
        + input_op_constraint
        + _get_in_constraint(smt_arg_type, input_arguments, instance_constraint)
        + [CallOp(concrete_op.ret, input_arguments)]
    )

    result = ""
    checker = KnownBitsChecker(ctx=ctx, timeout=timeout)
    for i in range(bw):
        ith_result = checker.check_ith_bit(verify_module, i)
        if ith_result is None:
            return "(bottom)"
        result = ith_result + result

    return result


def _process_row(task: RowTask) -> RowResult:
    try:
        return RowResult(
            index=task.index,
            ideal=_compute_max_precise(
                task.op_path, task.domain, task.bw, task.args_str, task.timeout
            ),
        )
    except TimeoutError:
        return RowResult(index=task.index, timed_out=True)


def _comment_row(row: pd.Series, columns: list[str]) -> str:
    return "# " + "\t".join(str(row[column]) for column in columns)


def _write_enum_tsv(path: Path, data: EnumData, commented_rows: list[str]) -> None:
    frontmatter = f"# ---\n{data.metadata.dump_commented()}\n# ---\n"
    with path.open("w") as f:
        f.write(frontmatter)
        for row in commented_rows:
            f.write(row)
            f.write("\n")
        data.enumdata.to_csv(
            f,
            sep="\t",
            index=False,
            header=True,
            lineterminator="\n",
        )


def _fill_hbw_rows(data: EnumData, timeout: int) -> tuple[EnumData, list[str]]:
    op_path = _resolve_metadata_op(data.metadata.op)
    hbw_bws = {bw for bw, _, _ in data.metadata.hbw}
    arg_cols = [f"arg_{i}" for i in range(data.metadata.arity)]
    tasks = [
        RowTask(
            index=int(index),  # type: ignore
            op_path=op_path,
            domain=data.metadata.domain,
            bw=int(row["bw"]),  # type: ignore
            args_str=",".join(str(row[col]) for col in arg_cols),
            timeout=timeout,
        )
        for index, row in data.enumdata.iterrows()
        if int(row["bw"]) in hbw_bws  # type: ignore
    ]

    if not tasks:
        return data, []

    with Pool() as pool:
        results = pool.map(_process_row, tasks)

    df = data.enumdata.copy()
    columns = list(df.columns)
    commented_rows: list[str] = []
    timed_out_indexes: list[int] = []

    for result in results:
        if result.timed_out:
            row = df.loc[result.index]
            print(
                f"timeout: row={result.index + 2} bw={row['bw']} args="
                + ",".join(str(row[col]) for col in arg_cols)
            )
            commented_rows.append(_comment_row(row, columns))
            timed_out_indexes.append(result.index)
            continue

        assert result.ideal is not None
        df.at[result.index, "ideal"] = result.ideal

    if timed_out_indexes:
        df = df.drop(index=timed_out_indexes).reset_index(drop=True)

    completed_hbw = sorted(hbw_bws)
    preserved_mbw = [entry for entry in data.metadata.mbw if entry[0] not in hbw_bws]
    generated_mbw = [(bw, int((df["bw"] == bw).sum())) for bw in completed_hbw]
    metadata = replace(
        data.metadata,
        mbw=preserved_mbw + generated_mbw,
        hbw=[],
    )

    return EnumData(metadata, df), commented_rows


def _run_input_mode(args: Namespace) -> None:
    assert args.input is not None
    with args.input.open() as f:
        data = EnumData.read_tsv(f)

    updated, commented_rows = _fill_hbw_rows(data, args.timeout)
    output_path = args.input if args.output is None else args.output
    _write_enum_tsv(output_path, updated, commented_rows)


def _run_single_mode(args: Namespace) -> None:
    assert args.op is not None
    assert args.domain is not None
    assert args.args is not None
    assert args.bw is not None
    print(
        _compute_max_precise(
            args.op,
            AbstractDomain[args.domain],
            args.bw,
            args.args,
            args.timeout,
        )
    )


def main() -> None:
    args = _get_args()
    if args.input is not None:
        _run_input_mode(args)
        return
    _run_single_mode(args)


if __name__ == "__main__":
    main()
