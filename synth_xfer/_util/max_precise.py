from dataclasses import dataclass, field, replace
from enum import StrEnum
from io import StringIO
from multiprocessing import Pool

import pandas as pd
from xdsl.context import Context
from xdsl.dialects.arith import Arith
from xdsl.dialects.builtin import Builtin, IntegerType, ModuleOp, StringAttr, i1
from xdsl.dialects.func import Func, FuncOp
from xdsl.dialects.smt import ConstantBoolOp
from xdsl.ir import Operation, OpResult
from xdsl.transforms.canonicalize import CanonicalizePass
from xdsl_smt.dialects.smt_bitvector_dialect import ConstantOp
from xdsl_smt.dialects.smt_dialect import (
    AssertOp,
    CallOp,
    DeclareConstOp,
    DefineFunOp,
    EqOp,
)
from xdsl_smt.dialects.smt_utils_dialect import FirstOp, PairOp, PairType
from xdsl_smt.dialects.transfer import Transfer, TransIntegerType
from xdsl_smt.passes.dead_code_elimination import DeadCodeElimination
from xdsl_smt.passes.lower_pairs import LowerPairs
from xdsl_smt.passes.transfer_inline import FunctionCallInline
from xdsl_smt.traits.smt_printer import print_to_smtlib
from xdsl_smt.utils.transfer_function_util import get_argument_instances_with_effect

from synth_xfer._util.domain import AbstractDomain, get_bvs_from_abst
from synth_xfer._util.parse_mlir import HelperFuncs
from synth_xfer._util.pattern_dsl import ArgRef, NodeRef, PatternDag, PatternRef
from synth_xfer._util.smt_solver import IncrementalSolver, SolverKind, make_solver
from synth_xfer._util.tsv import EnumData
from synth_xfer._util.verifier import lower_to_smt_module

_CTX: Context | None = None


def _get_ctx() -> Context:
    global _CTX
    if _CTX is None:
        ctx = Context()
        ctx.load_dialect(Arith)
        ctx.load_dialect(Builtin)
        ctx.load_dialect(Func)
        ctx.load_dialect(Transfer)
        _CTX = ctx
    return _CTX


@dataclass
class MaxPreciseQueryBuilder:
    domain: AbstractDomain
    result_width: int
    arg_widths: list[int]
    arg_is_i1: list[bool]
    abstract_arg_values: list[tuple[int, int]]
    instance_constraint_iN: DefineFunOp
    instance_constraint_i1: DefineFunOp | None
    concrete_op: DefineFunOp
    op_constraint: DefineFunOp | None
    _const_false: ConstantBoolOp = field(init=False, repr=False)

    def _input_vars(self) -> list[DeclareConstOp]:
        input_vars = [
            x
            for x in get_argument_instances_with_effect(self.concrete_op, {})
            if isinstance(x, DeclareConstOp)
        ]
        assert len(input_vars) + 1 == len(self.concrete_op.func_type.inputs)
        return input_vars

    def _get_op_constraint(self, inputs: list[DeclareConstOp]) -> list[Operation]:
        if self.op_constraint is None:
            return []

        true_ops, true_value = self._poison_result_true()
        call_op = CallOp(self.op_constraint.ret, inputs + [self._const_false.result])
        eq_op = EqOp(true_value, call_op.res[0])
        assert_op = AssertOp(eq_op.res)
        return true_ops + [call_op, eq_op, assert_op]

    def _poison_result_true(self) -> tuple[list[Operation], OpResult]:
        const_i1 = ConstantOp.from_int_value(1, 1)
        pair_op = PairOp(const_i1.res, self._const_false.result)
        pair_res_op = PairOp(pair_op.res, self._const_false.result)
        return [const_i1, pair_op, pair_res_op], pair_res_op.res

    def _to_pair_value(self, val_list: list[ConstantOp]) -> tuple[list[PairOp], OpResult]:
        last_val = self._const_false.result
        result: list[PairOp] = []
        for val in val_list[::-1]:
            result.append(PairOp(val.res, last_val))
            last_val = result[-1].res
        return result, result[-1].res

    def _abstract_values(self) -> tuple[list[Operation], list[OpResult]]:
        ops: list[Operation] = []
        values: list[OpResult] = []
        for abst_bv, arg_width in zip(self.abstract_arg_values, self.arg_widths):
            constant_ops = [
                ConstantOp.from_int_value(x % (2**arg_width), arg_width) for x in abst_bv
            ]
            pair_ops, pair_value = self._to_pair_value(constant_ops)
            ops += constant_ops + pair_ops
            values.append(pair_value)
        return ops, values

    def _instance_constraint(self, arg_is_i1: bool) -> DefineFunOp:
        if arg_is_i1:
            assert self.instance_constraint_i1 is not None
            return self.instance_constraint_i1
        return self.instance_constraint_iN

    def _concrete_payload(self, value: OpResult) -> tuple[list[Operation], OpResult]:
        result: list[Operation] = []
        while isinstance(value.type, PairType):
            first_op = FirstOp(value)
            result.append(first_op)
            value = first_op.res
        return result, value

    def _get_in_constraint(
        self,
        abstract_inputs: list[OpResult],
        inputs: list[DeclareConstOp],
    ) -> list[Operation]:
        result: list[Operation] = []
        true_ops, true_value = self._poison_result_true()
        for abstract_input, concrete_input, arg_is_i1 in zip(
            abstract_inputs, inputs, self.arg_is_i1
        ):
            instance_constraint = self._instance_constraint(arg_is_i1)
            payload_ops, concrete_payload = self._concrete_payload(concrete_input.res)
            call_op = CallOp(
                instance_constraint.ret,
                [abstract_input, concrete_payload, self._const_false.result],
            )
            eq_op = EqOp(true_value, call_op.res[0])
            assert_op = AssertOp(eq_op.res)

            result += payload_ops + [call_op, eq_op, assert_op]
        return true_ops + result

    def build(self) -> ModuleOp:
        input_arguments = self._input_vars()
        self._const_false = ConstantBoolOp(False)

        abstract_ops, abstract_inputs = self._abstract_values()
        op_constraint = self._get_op_constraint(input_arguments)
        concrete_call = CallOp(self.concrete_op.ret, input_arguments)
        concrete_result_ops, concrete_result = self._concrete_payload(
            concrete_call.res[0]
        )

        result_var = DeclareConstOp(concrete_result.type)
        result_var.res.name_hint = "result"
        result_eq = EqOp(result_var.res, concrete_result)
        result_assert = AssertOp(result_eq.res)

        return ModuleOp(
            input_arguments
            + [self._const_false]
            + abstract_ops
            + op_constraint
            + self._get_in_constraint(abstract_inputs, input_arguments)
            + [concrete_call]
            + concrete_result_ops
            + [result_var, result_eq, result_assert]
        )


@dataclass(frozen=True)
class PreparedQuery:
    solver: IncrementalSolver
    result_width: int

    @classmethod
    def from_module(
        cls,
        ctx: Context,
        smt_mod: ModuleOp,
        result_width: int,
        timeout: int,
        solver_kind: SolverKind,
    ) -> "PreparedQuery":
        module = smt_mod.clone()
        FunctionCallInline(True, {}).apply(ctx, module)
        LowerPairs().apply(ctx, module)
        CanonicalizePass().apply(ctx, module)
        DeadCodeElimination().apply(ctx, module)
        stream = StringIO()
        print_to_smtlib(module, stream)

        solver = make_solver(solver_kind, stream.getvalue(), timeout)
        return cls(solver=solver, result_width=result_width)

    def is_sat(self) -> bool:
        result = self.solver.check()
        if result is None:
            raise TimeoutError()
        return result

    def check(self, probe: str) -> bool:
        self.solver.push()
        try:
            self.solver.add_smt2(f"(assert {probe})")
            result = self.solver.check()
        finally:
            self.solver.pop()

        if result is None:
            raise TimeoutError()
        return result

    def bv_val(self, val: int) -> str:
        return f"(_ bv{val % (2**self.result_width)} {self.result_width})"


@dataclass(frozen=True)
class ComputeMaxPrecise:
    query: PreparedQuery
    bitwidth: int

    def compute(self) -> str:
        raise NotImplementedError


@dataclass(frozen=True)
class KnownBitsMaxPrecise(ComputeMaxPrecise):
    def check_ith_bit(self, ith: int) -> str | None:
        ith_bit = f"((_ extract {ith} {ith}) $result)"
        can_be_z = self.query.check(f"(= {ith_bit} (_ bv0 1))")
        can_be_o = self.query.check(f"(= {ith_bit} (_ bv1 1))")
        if can_be_o and can_be_z:
            return "?"
        if (not can_be_z) and (not can_be_o):
            return None
        if not can_be_z:
            return "1"
        if not can_be_o:
            return "0"
        raise AssertionError("unreachable")

    def compute(self) -> str:
        result = ""
        for i in range(self.bitwidth):
            ith_result = self.check_ith_bit(i)
            if ith_result is None:
                return "(bottom)"
            result = ith_result + result
        return result


@dataclass(frozen=True)
class IntervalMaxPrecise(ComputeMaxPrecise):
    def _can_be_leq(self, val: int) -> bool:
        return self.query.check(self._cmp_leq("$result", val))

    def _can_be_geq(self, val: int) -> bool:
        return self.query.check(self._cmp_geq("$result", val))

    def _cmp_leq(self, concrete_res: str, val: int) -> str:
        raise NotImplementedError

    def _cmp_geq(self, concrete_res: str, val: int) -> str:
        raise NotImplementedError

    def min_value(self) -> int:
        raise NotImplementedError

    def max_value(self) -> int:
        raise NotImplementedError

    def format_result(self, lower_bound: int, upper_bound: int) -> str:
        raise NotImplementedError

    def lower_bound(self) -> int | None:
        if not self.query.is_sat():
            return None

        lo, hi = self.min_value(), self.max_value()
        while lo < hi:
            mid = (lo + hi) // 2
            if self._can_be_leq(mid):
                hi = mid
            else:
                lo = mid + 1
        return lo

    def upper_bound(self, lower_bound: int) -> int:
        lo, hi = lower_bound, self.max_value()
        while lo < hi:
            mid = (lo + hi + 1) // 2
            if self._can_be_geq(mid):
                lo = mid
            else:
                hi = mid - 1
        return lo

    def compute(self) -> str:
        lower_bound = self.lower_bound()
        if lower_bound is None:
            return "(bottom)"
        return self.format_result(lower_bound, self.upper_bound(lower_bound))


@dataclass(frozen=True)
class UConstRangeMaxPrecise(IntervalMaxPrecise):
    def _cmp_leq(self, concrete_res: str, val: int) -> str:
        return f"(bvule {concrete_res} {self.query.bv_val(val)})"

    def _cmp_geq(self, concrete_res: str, val: int) -> str:
        return f"(bvuge {concrete_res} {self.query.bv_val(val)})"

    def min_value(self) -> int:
        return 0

    def max_value(self) -> int:
        return 2**self.bitwidth - 1

    def format_result(self, lower_bound: int, upper_bound: int) -> str:
        return f"[{lower_bound}, {upper_bound}]"


@dataclass(frozen=True)
class SConstRangeMaxPrecise(IntervalMaxPrecise):
    def _cmp_leq(self, concrete_res: str, val: int) -> str:
        return f"(bvsle {concrete_res} {self.query.bv_val(val)})"

    def _cmp_geq(self, concrete_res: str, val: int) -> str:
        return f"(bvsge {concrete_res} {self.query.bv_val(val)})"

    def min_value(self) -> int:
        return -(2**self.bitwidth // 2)

    def max_value(self) -> int:
        return (2**self.bitwidth // 2) - 1

    def format_result(self, lower_bound: int, upper_bound: int) -> str:
        return f"[{lower_bound}, {upper_bound}]"


def _get_max_precise_computer(
    domain: AbstractDomain, query: PreparedQuery, bw: int
) -> ComputeMaxPrecise:
    if domain == AbstractDomain.KnownBits:
        return KnownBitsMaxPrecise(query, bw)
    if domain == AbstractDomain.UConstRange:
        return UConstRangeMaxPrecise(query, bw)
    if domain == AbstractDomain.SConstRange:
        return SConstRangeMaxPrecise(query, bw)

    raise NotImplementedError(f"Max precise not implemented for {domain}")


def _concrete_width(ty: TransIntegerType | IntegerType, bw: int) -> int:
    if isinstance(ty, TransIntegerType):
        return bw
    return ty.width.data


def _lower_instance_constraint(
    func_name: str,
    instance_constraint: FuncOp,
    width: int,
    ctx: Context,
) -> DefineFunOp:
    func = instance_constraint.clone()
    func.sym_name = StringAttr(func_name)
    lower_to_smt_module(m := ModuleOp([func]), width, ctx)
    lowered = next(iter(m.ops))
    assert isinstance(lowered, DefineFunOp)
    return lowered


@dataclass(frozen=True)
class RowTask:
    index: int
    bw: int
    args: tuple[str, ...]


@dataclass(frozen=True)
class RowResult:
    index: int
    ideal: str | None = None
    sequential_ideal: str | None = None
    timed_out: bool = False


@dataclass(frozen=True)
class RowProcessor:
    pattern: PatternDag
    domain: AbstractDomain
    timeout: int
    solver_kind: SolverKind

    def __call__(self, task: RowTask) -> RowResult:
        try:
            ideal, sequential_ideal = compute_max_pair(
                self.pattern,
                self.domain,
                task.bw,
                task.args,
                self.timeout,
                self.solver_kind,
            )
            return RowResult(
                index=task.index,
                ideal=ideal,
                sequential_ideal=sequential_ideal,
            )
        except TimeoutError:
            return RowResult(index=task.index, timed_out=True)


def compute_max_precise(
    pattern: PatternDag,
    domain: AbstractDomain,
    bw: int,
    args: tuple[str, ...],
    timeout: int,
    solver_kind: SolverKind,
) -> str:
    ctx = _get_ctx()

    hlprs = HelperFuncs(pattern, domain)
    if len(hlprs.crt_func.args) != len(args):
        raise ValueError(
            f"arity of expression ({len(hlprs.crt_func.args)}) doesn't match number of args provided ({len(args)})"
        )

    arg_widths = [_concrete_width(arg_ty, bw) for arg_ty in hlprs.conc_arg_ty]
    arg_is_i1 = [arg_ty == i1 for arg_ty in hlprs.conc_arg_ty]
    result_width = _concrete_width(hlprs.conc_ret_ty, bw)
    parsed_args = [
        get_bvs_from_abst(arg, domain, arg_width)
        for arg, arg_width in zip(args, arg_widths)
    ]
    if any(arg is None for arg in parsed_args):
        return "(bottom)"
    abst_arg_values = [arg for arg in parsed_args if arg is not None]

    fns = [hlprs.crt_func, hlprs.op_constraint_func]
    lower_to_smt_module(m := ModuleOp([x.clone() for x in fns if x is not None]), bw, ctx)
    m_ops = iter(m.ops)
    concrete_op = next(m_ops)
    op_constraint = next(m_ops, None)
    assert isinstance(concrete_op, DefineFunOp)
    assert isinstance(op_constraint, DefineFunOp) or op_constraint is None

    instance_constraint_iN = _lower_instance_constraint(
        "abstract_val_contains_iN", hlprs.instance_constraint_func, bw, ctx
    )
    instance_constraint_i1 = (
        _lower_instance_constraint(
            "abstract_val_contains_i1", hlprs.instance_constraint_func, 1, ctx
        )
        if any(arg_is_i1)
        else None
    )

    smt_mod = MaxPreciseQueryBuilder(
        domain=domain,
        result_width=result_width,
        arg_widths=arg_widths,
        arg_is_i1=arg_is_i1,
        abstract_arg_values=abst_arg_values,
        instance_constraint_iN=instance_constraint_iN,
        instance_constraint_i1=instance_constraint_i1,
        concrete_op=concrete_op,
        op_constraint=op_constraint,
    ).build()

    query = PreparedQuery.from_module(ctx, smt_mod, result_width, timeout, solver_kind)
    computer = _get_max_precise_computer(domain, query, result_width)
    return computer.compute()


def compute_sequential_root_max_precise(
    pattern: PatternDag,
    domain: AbstractDomain,
    bw: int,
    args: tuple[str, ...],
    timeout: int,
    solver_kind: SolverKind,
) -> str:
    values: dict[PatternRef, str] = {ArgRef(index): arg for index, arg in enumerate(args)}
    for node_index, node in enumerate(pattern.nodes):
        node_args = tuple(values[operand] for operand in node.operands)
        values[NodeRef(node_index)] = compute_max_precise(
            PatternDag.single_node(node.op),
            domain,
            bw,
            node_args,
            timeout,
            solver_kind,
        )
    return values[pattern.result]


def compute_max_pair(
    pattern: PatternDag,
    domain: AbstractDomain,
    bw: int,
    args: tuple[str, ...],
    timeout: int,
    solver_kind: SolverKind,
) -> tuple[str, str]:
    composite = compute_max_precise(pattern, domain, bw, args, timeout, solver_kind)
    if pattern.is_op():
        return composite, composite
    sequential = compute_sequential_root_max_precise(
        pattern,
        domain,
        bw,
        args,
        timeout,
        solver_kind,
    )
    return composite, sequential


def _comment_row(row: pd.Series, columns: list[str]) -> str:
    return "# " + "\t".join(str(row[column]) for column in columns)


def fill_hbw_rows(
    data: EnumData,
    timeout: int,
    solver_kind: SolverKind,
) -> tuple[EnumData, list[str]]:
    hbw_bws = {bw for bw, _, _ in data.metadata.hbw}
    arg_cols = [f"arg_{i}" for i in range(data.metadata.arity)]
    tasks = [
        RowTask(
            index=int(index),  # type: ignore
            bw=int(row["bw"]),  # type: ignore
            args=tuple(str(row[col]) for col in arg_cols),
        )
        for index, row in data.enumdata.iterrows()
        if int(row["bw"]) in hbw_bws  # type: ignore
    ]

    processor = RowProcessor(data.metadata.op, data.metadata.domain, timeout, solver_kind)
    if len(tasks) <= 1:
        results = [processor(task) for task in tasks]
    else:
        with Pool() as pool:
            results = pool.map(processor, tasks)

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
        assert result.sequential_ideal is not None
        df.at[result.index, "ideal"] = result.ideal
        df.at[result.index, "sequential_ideal"] = result.sequential_ideal

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


class EdgeLossKind(StrEnum):
    incomplete = "incomplete"
    upstream_loss = "upstream-loss"
    root_masked = "root-masked"
    complete = "complete"


@dataclass(frozen=True)
class SequentialEdgeAnalysis:
    dest: NodeRef
    source: PatternRef
    dest_cut_comp: str
    root_cut_comp: str
    dest_cut_seq: str
    root_cut_seq: str
    dest_rel_loss: bool
    root_rel_loss: bool
    dest_seq_loss: bool
    root_seq_loss: bool
    local_kind: EdgeLossKind


@dataclass(frozen=True)
class SequentialDivergence:
    ref: NodeRef
    composite: str
    sequential: str


@dataclass(frozen=True)
class SequentialMaxPreciseAnalysis:
    composite: str
    sequential: str
    comp_values: dict[PatternRef, str]
    seq_values: dict[PatternRef, str]
    edges: tuple[SequentialEdgeAnalysis, ...]
    minimal_divergences: tuple[SequentialDivergence, ...]


@dataclass(frozen=True)
class Cut:
    edge: tuple[NodeRef, int]
    value: str


def _compute_subdag_max_precise(
    pattern: PatternDag,
    root: PatternRef,
    value_map: dict[PatternRef, str],
    domain: AbstractDomain,
    bw: int,
    timeout: int,
    solver_kind: SolverKind,
    cut: Cut | None = None,
) -> str:
    subdag, arg_sources, cut_arg_index = pattern.subdag_with_cut(
        root, None if cut is None else cut.edge
    )
    subdag_args = tuple(
        cut.value
        if cut is not None and cut_arg_index is not None and index == cut_arg_index
        else value_map[src]
        for index, src in enumerate(arg_sources)
    )
    return compute_max_precise(subdag, domain, bw, subdag_args, timeout, solver_kind)


def _compute_node_values(
    pattern: PatternDag,
    domain: AbstractDomain,
    bw: int,
    args: tuple[str, ...],
    timeout: int,
    solver_kind: SolverKind,
    *,
    sequential: bool,
) -> dict[PatternRef, str]:
    values: dict[PatternRef, str] = {ArgRef(index): arg for index, arg in enumerate(args)}
    for node_index, node in enumerate(pattern.nodes):
        node_ref = NodeRef(node_index)
        if sequential:
            node_args = tuple(values[operand] for operand in node.operands)
            values[node_ref] = compute_max_precise(
                PatternDag.single_node(node.op),
                domain,
                bw,
                node_args,
                timeout,
                solver_kind,
            )
        else:
            values[node_ref] = _compute_subdag_max_precise(
                pattern,
                node_ref,
                values,
                domain,
                bw,
                timeout,
                solver_kind,
            )
    return values


def _edge_analyses(
    pattern: PatternDag,
    comp_values: dict[PatternRef, str],
    seq_values: dict[PatternRef, str],
    domain: AbstractDomain,
    bw: int,
    timeout: int,
    solver_kind: SolverKind,
) -> tuple[SequentialEdgeAnalysis, ...]:
    root = pattern.result
    result: list[SequentialEdgeAnalysis] = []
    for dest_index, node in enumerate(pattern.nodes):
        dest = NodeRef(dest_index)
        for operand_index, source in enumerate(node.operands):
            edge = (dest, operand_index)

            def eval_cut(cut_root: NodeRef, value: str) -> str:
                return _compute_subdag_max_precise(
                    pattern,
                    cut_root,
                    comp_values,
                    domain,
                    bw,
                    timeout,
                    solver_kind,
                    Cut(edge, value),
                )

            source_comp = comp_values[source]
            source_seq = seq_values[source]

            dest_cut_comp = eval_cut(dest, source_comp)
            root_cut_comp = dest_cut_comp if dest == root else eval_cut(root, source_comp)

            if source_seq == source_comp:
                dest_cut_seq = dest_cut_comp
                root_cut_seq = root_cut_comp
            else:
                dest_cut_seq = eval_cut(dest, source_seq)
                root_cut_seq = (
                    dest_cut_seq if dest == root else eval_cut(root, source_seq)
                )

            dest_rel_loss = dest_cut_comp != comp_values[dest]
            root_rel_loss = root_cut_comp != comp_values[root]
            dest_seq_loss = dest_cut_seq != comp_values[dest]
            root_seq_loss = root_cut_seq != comp_values[root]
            if dest_rel_loss:
                local_kind = (
                    EdgeLossKind.incomplete if root_rel_loss else EdgeLossKind.root_masked
                )
            elif dest_seq_loss:
                local_kind = (
                    EdgeLossKind.upstream_loss
                    if root_seq_loss
                    else EdgeLossKind.root_masked
                )
            else:
                local_kind = EdgeLossKind.complete
            result.append(
                SequentialEdgeAnalysis(
                    dest=dest,
                    source=source,
                    dest_cut_comp=dest_cut_comp,
                    root_cut_comp=root_cut_comp,
                    dest_cut_seq=dest_cut_seq,
                    root_cut_seq=root_cut_seq,
                    dest_rel_loss=dest_rel_loss,
                    root_rel_loss=root_rel_loss,
                    dest_seq_loss=dest_seq_loss,
                    root_seq_loss=root_seq_loss,
                    local_kind=local_kind,
                )
            )
    return tuple(result)


def _minimal_divergences(
    pattern: PatternDag,
    comp_values: dict[PatternRef, str],
    seq_values: dict[PatternRef, str],
) -> tuple[SequentialDivergence, ...]:
    divergent: set[NodeRef] = set()
    for index, _ in enumerate(pattern.nodes):
        ref = NodeRef(index)
        if comp_values[ref] != seq_values[ref]:
            divergent.add(ref)
    result: list[SequentialDivergence] = []
    for ref in sorted(divergent, key=lambda node_ref: node_ref.index):
        if any(
            isinstance(operand, NodeRef) and operand in divergent
            for operand in pattern.nodes[ref.index].operands
        ):
            continue
        result.append(
            SequentialDivergence(
                ref=ref,
                composite=comp_values[ref],
                sequential=seq_values[ref],
            )
        )
    return tuple(result)


def sequential_max_precise(
    pattern: PatternDag,
    domain: AbstractDomain,
    bw: int,
    args: tuple[str, ...],
    timeout: int,
    solver_kind: SolverKind,
) -> SequentialMaxPreciseAnalysis:
    if len(args) != pattern.num_args:
        raise ValueError(
            f"arity of expression ({pattern.num_args}) doesn't match number of args provided ({len(args)})"
        )

    seq_values = _compute_node_values(
        pattern, domain, bw, args, timeout, solver_kind, sequential=True
    )
    comp_values = _compute_node_values(
        pattern, domain, bw, args, timeout, solver_kind, sequential=False
    )
    return SequentialMaxPreciseAnalysis(
        composite=comp_values[pattern.result],
        sequential=seq_values[pattern.result],
        comp_values=comp_values,
        seq_values=seq_values,
        edges=_edge_analyses(
            pattern, comp_values, seq_values, domain, bw, timeout, solver_kind
        ),
        minimal_divergences=_minimal_divergences(pattern, comp_values, seq_values),
    )


@dataclass
class AbsOpConstraintQueryBuilder:
    """Builds an SMT query that constant-folds abs_op_constraint over a fully
    concrete tuple of abstract argument values. The query is SAT iff the
    constraint holds for those values (it has no free variables)."""

    bitwidth: int
    abstract_arg_values: list[tuple[int, int]]
    abs_op_constraint: DefineFunOp
    _const_false: ConstantBoolOp = field(init=False, repr=False)

    def _to_pair_value(self, val_list: list[ConstantOp]) -> tuple[list[PairOp], OpResult]:
        last_val = self._const_false.result
        result: list[PairOp] = []
        for val in val_list[::-1]:
            result.append(PairOp(val.res, last_val))
            last_val = result[-1].res
        return result, result[-1].res

    def build(self) -> ModuleOp:
        self._const_false = ConstantBoolOp(False)
        ops: list[Operation] = [self._const_false]

        abstract_inputs: list[OpResult] = []
        for abst_bv in self.abstract_arg_values:
            constant_ops = [
                ConstantOp.from_int_value(x % (2**self.bitwidth), self.bitwidth)
                for x in abst_bv
            ]
            pair_ops, pair_value = self._to_pair_value(constant_ops)
            ops += constant_ops + pair_ops
            abstract_inputs.append(pair_value)

        const_i1 = ConstantOp.from_int_value(1, 1)
        pair_op = PairOp(const_i1.res, self._const_false.result)
        pair_res_op = PairOp(pair_op.res, self._const_false.result)
        call_op = CallOp(
            self.abs_op_constraint.ret,
            abstract_inputs + [self._const_false.result],
        )
        eq_op = EqOp(pair_res_op.res, call_op.res[0])
        assert_op = AssertOp(eq_op.res)

        return ModuleOp(ops + [const_i1, pair_op, pair_res_op, call_op, eq_op, assert_op])


def check_abs_op_constraint(
    pattern: PatternDag,
    domain: AbstractDomain,
    bw: int,
    args: tuple[str, ...],
    timeout: int,
    solver_kind: SolverKind,
) -> bool:
    """Return True if `args` satisfy the pattern's abs_op_constraint (or the
    pattern has none). Used as a rejection-sampling filter, so anything
    uncertain (malformed args, bottom, solver timeout) returns False."""
    hlprs = HelperFuncs(pattern, domain)
    if hlprs.abs_op_constraint_func is None:
        return True

    try:
        parsed_args = [get_bvs_from_abst(arg, domain, bw) for arg in args]
    except ValueError:
        return False
    if any(arg is None for arg in parsed_args):
        return False
    abst_arg_values = [arg for arg in parsed_args if arg is not None]

    ctx = _get_ctx()
    lower_to_smt_module(m := ModuleOp([hlprs.abs_op_constraint_func.clone()]), bw, ctx)
    abs_op_constraint = next(iter(m.ops))
    assert isinstance(abs_op_constraint, DefineFunOp)

    smt_mod = AbsOpConstraintQueryBuilder(
        bitwidth=bw,
        abstract_arg_values=abst_arg_values,
        abs_op_constraint=abs_op_constraint,
    ).build()

    query = PreparedQuery.from_module(ctx, smt_mod, bw, timeout, solver_kind)
    try:
        return query.is_sat()
    except TimeoutError:
        return False
