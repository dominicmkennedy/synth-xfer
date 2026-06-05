from argparse import ArgumentParser, BooleanOptionalAction
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
import shutil

from synth_xfer._util.pattern_dsl import ArgRef, PatternDag, PatternOp, PatternRef


@dataclass(frozen=True)
class PatternSpec:
    id: str
    dag: PatternDag
    root: PatternOp
    index: int


NSW = "OverflowingBinaryOperator::NoSignedWrap"
NUW = "OverflowingBinaryOperator::NoUnsignedWrap"
NSWNUW = f"({NSW} | {NUW})"

OP_MATCHER: dict[PatternOp, str] = {
    PatternOp.Abs: "m_Intrinsic<Intrinsic::abs>({0}, m_SpecificInt(0))",
    PatternOp.AbsUndef: "m_Intrinsic<Intrinsic::abs>({0}, m_SpecificInt(1))",
    PatternOp.PopCount: "m_Intrinsic<Intrinsic::ctpop>({0})",
    PatternOp.CountLZero: "m_Intrinsic<Intrinsic::ctlz>({0}, m_SpecificInt(0))",
    PatternOp.CountLZeroUndef: "m_Intrinsic<Intrinsic::ctlz>({0}, m_SpecificInt(1))",
    PatternOp.CountRZero: "m_Intrinsic<Intrinsic::cttz>({0}, m_SpecificInt(0))",
    PatternOp.CountRZeroUndef: "m_Intrinsic<Intrinsic::cttz>({0}, m_SpecificInt(1))",
    PatternOp.Add: "m_c_ExactWrapAdd<0>({0}, {1})",
    PatternOp.AddNsw: f"m_c_ExactWrapAdd<{NSW}>({{0}}, {{1}})",
    PatternOp.AddNuw: f"m_c_ExactWrapAdd<{NUW}>({{0}}, {{1}})",
    PatternOp.AddNswNuw: "m_c_NSWNUWAdd({0}, {1})",
    PatternOp.And: "m_c_And({0}, {1})",
    PatternOp.Ashr: "m_AShr({0}, {1})",
    PatternOp.AshrExact: "m_Exact(m_AShr({0}, {1}))",
    PatternOp.Lshr: "m_LShr({0}, {1})",
    PatternOp.LshrExact: "m_Exact(m_LShr({0}, {1}))",
    PatternOp.Mul: "m_c_ExactWrapMul<0>({0}, {1})",
    PatternOp.MulNsw: f"m_c_ExactWrapMul<{NSW}>({{0}}, {{1}})",
    PatternOp.MulNuw: f"m_c_ExactWrapMul<{NUW}>({{0}}, {{1}})",
    PatternOp.MulNswNuw: "m_c_NSWNUWMul({0}, {1})",
    PatternOp.Or: "m_c_Or({0}, {1})",
    PatternOp.OrDisjoint: "m_c_DisjointOr({0}, {1})",
    PatternOp.Sdiv: "m_SDiv({0}, {1})",
    PatternOp.SdivExact: "m_Exact(m_SDiv({0}, {1}))",
    PatternOp.Shl: "m_ExactWrapShl<0>({0}, {1})",
    PatternOp.ShlNsw: f"m_ExactWrapShl<{NSW}>({{0}}, {{1}})",
    PatternOp.ShlNuw: f"m_ExactWrapShl<{NUW}>({{0}}, {{1}})",
    PatternOp.ShlNswNuw: f"m_ExactWrapShl<{NSWNUW}>({{0}}, {{1}})",
    PatternOp.Mods: "m_SRem({0}, {1})",
    PatternOp.Sub: "m_ExactWrapSub<0>({0}, {1})",
    PatternOp.SubNsw: f"m_ExactWrapSub<{NSW}>({{0}}, {{1}})",
    PatternOp.SubNuw: f"m_ExactWrapSub<{NUW}>({{0}}, {{1}})",
    PatternOp.SubNswNuw: f"m_ExactWrapSub<{NSWNUW}>({{0}}, {{1}})",
    PatternOp.Udiv: "m_UDiv({0}, {1})",
    PatternOp.UdivExact: "m_Exact(m_UDiv({0}, {1}))",
    PatternOp.Modu: "m_URem({0}, {1})",
    PatternOp.Xor: "m_c_Xor({0}, {1})",
    PatternOp.Umax: "m_c_UMax({0}, {1})",
    PatternOp.Umin: "m_c_UMin({0}, {1})",
    PatternOp.Smax: "m_c_SMax({0}, {1})",
    PatternOp.Smin: "m_c_SMin({0}, {1})",
    PatternOp.SaddSat: "m_c_Intrinsic<Intrinsic::sadd_sat>({0}, {1})",
    PatternOp.UaddSat: "m_c_Intrinsic<Intrinsic::uadd_sat>({0}, {1})",
    PatternOp.SsubSat: "m_Intrinsic<Intrinsic::ssub_sat>({0}, {1})",
    PatternOp.UsubSat: "m_Intrinsic<Intrinsic::usub_sat>({0}, {1})",
    PatternOp.SmulSat: "m_c_IntrinsicWithScale<Intrinsic::smul_fix_sat>({0}, {1}, m_SpecificInt(0))",
    PatternOp.UmulSat: "m_c_IntrinsicWithScale<Intrinsic::umul_fix_sat>({0}, {1}, m_SpecificInt(0))",
    PatternOp.SshlSat: "m_Intrinsic<Intrinsic::sshl_sat>({0}, {1})",
    PatternOp.UshlSat: "m_Intrinsic<Intrinsic::ushl_sat>({0}, {1})",
    PatternOp.ICmpEq: "m_c_SpecificICmp(ICmpInst::ICMP_EQ, {0}, {1})",
    PatternOp.ICmpNe: "m_c_SpecificICmp(ICmpInst::ICMP_NE, {0}, {1})",
    PatternOp.ICmpSlt: "m_c_SpecificICmp(ICmpInst::ICMP_SLT, {0}, {1})",
    PatternOp.ICmpSle: "m_c_SpecificICmp(ICmpInst::ICMP_SLE, {0}, {1})",
    PatternOp.ICmpUlt: "m_c_SpecificICmp(ICmpInst::ICMP_ULT, {0}, {1})",
    PatternOp.ICmpUle: "m_c_SpecificICmp(ICmpInst::ICMP_ULE, {0}, {1})",
    PatternOp.TruncToBool: "m_TruncToBool({0})",
    PatternOp.ZextBool: "m_ZExtBool({0})",
    PatternOp.SextBool: "m_SExtBool({0})",
    PatternOp.Select: "m_Select({0}, {1}, {2})",
}


def _split_top_level_args(s: str) -> list[str]:
    args: list[str] = []
    depth_paren = 0
    depth_angle = 0
    start = 0
    for i, ch in enumerate(s):
        if ch == "(":
            depth_paren += 1
        elif ch == ")":
            depth_paren -= 1
        elif ch == "<":
            depth_angle += 1
        elif ch == ">":
            depth_angle -= 1
        elif ch == "," and depth_paren == 0 and depth_angle == 0:
            args.append(s[start:i].strip())
            start = i + 1
    args.append(s[start:].strip())
    return args


def _parse_call(expr: str) -> tuple[str, list[str]] | None:
    expr = expr.strip()
    if not expr.endswith(")"):
        return None
    lpar = expr.find("(")
    if lpar < 0:
        return None
    callee = expr[:lpar].strip()
    inner = expr[lpar + 1 : -1]
    depth = 0
    for ch in inner:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth < 0:
                return None
    if depth != 0:
        return None
    return callee, _split_top_level_args(inner)


def _format_matcher(expr: str, indent: int, width: int) -> list[str]:
    one_line = (" " * indent) + expr
    if len(one_line) <= width:
        return [one_line]

    parsed = _parse_call(expr)
    if not parsed:
        return [one_line]
    callee, args = parsed
    if not args:
        return [(" " * indent) + f"{callee}()"]

    out = [(" " * indent) + f"{callee}("]
    for i, arg in enumerate(args):
        arg_lines = _format_matcher(arg, indent + 2, width)
        if i != len(args) - 1:
            arg_lines[-1] += ","
        out.extend(arg_lines)
    out.append((" " * indent) + ")")
    return out


def _emit_guard(matcher: str) -> str:
    one_line = f"  if (!match(I, {matcher})) return std::nullopt;"
    if len(one_line) <= 100:
        return one_line + "\n"

    matcher_lines = _format_matcher(matcher, indent=0, width=84)
    if len(matcher_lines) == 1:
        return f"  if (!match(I, {matcher_lines[0]}))\n    return std::nullopt;\n"
    hang = " " * len("  if (!match(I, ")
    out: list[str] = []
    out.append(f"  if (!match(I, {matcher_lines[0].strip()}\n")
    for line in matcher_lines[1:-1]:
        out.append(f"{hang}{line}\n")
    out.append(f"{hang}{matcher_lines[-1]}))\n")
    out.append("    return std::nullopt;\n")
    return "".join(out)


def _emit_match_expr(
    dag: PatternDag,
    ref: PatternRef,
    seen_args: set[int],
) -> str:
    if isinstance(ref, ArgRef):
        if ref.index in seen_args:
            return f"m_Deferred(Arg{ref.index})"
        seen_args.add(ref.index)
        return f"m_Value(Arg{ref.index})"

    node = dag.nodes[ref.index]
    args = [_emit_match_expr(dag, operand, seen_args) for operand in node.operands]

    return OP_MATCHER[node.op].format(*args)


def _emit_pattern_function(spec: PatternSpec) -> str:
    r = range(spec.dag.num_args)
    arg_decl = "const Value " + ", ".join(f"*Arg{i} = nullptr" for i in r) + ";"

    matcher = _emit_match_expr(spec.dag, spec.dag.result, set())
    pid_int = spec.index
    depths = spec.dag.arg_depths()
    max_offset = max(depths.values()) - 1
    out: list[str] = []
    out.append(
        f"static std::optional<PatternMatchKB> match{spec.id}(const Operator *I, const SimplifyQuery &Q, unsigned Depth) {{\n"
    )
    # The deepest matched leaf recurses at Depth + max_offset (see effective-depth
    # note below). If that would exceed the recursion cap, decline the match so the
    # query falls back to vanilla known bits. This both keeps every leaf call within
    # computeKnownBits's Depth <= MaxAnalysisRecursionDepth contract and makes the
    # pattern's budget identical to the no-transformer baseline -- a pattern never
    # gets credit for analyzing a subtree deeper than vanilla could reach. Only
    # emitted for nested patterns; flat (max_offset == 0) patterns can never exceed.
    if max_offset > 0:
        out.append(
            f"  if (Depth + {max_offset} > MaxAnalysisRecursionDepth)\n"
            f"    return std::nullopt;\n"
        )
    out.append(f"  {arg_decl}\n")
    out.append(_emit_guard(matcher))
    out.append(f"  ++Num{spec.id}Matches;\n")
    for i in r:
        # Effective depth: charge each leaf its true nesting level so a nested
        # operand (e.g. b/c in add(a, add(b, c))) recurses with the same budget
        # vanilla computeKnownBitsFromOperator would give it. Level-1 leaves keep
        # plain `Depth`, so flat patterns are byte-for-byte unchanged. The guard
        # above guarantees Depth + offset <= MaxAnalysisRecursionDepth here.
        offset = depths[ArgRef(i)] - 1
        depth_expr = "Depth" if offset == 0 else f"Depth + {offset}"
        out.append(f"  auto KBArg{i} = computeKnownBits(Arg{i}, Q, {depth_expr});\n")
    for i in r:
        out.append(f"  auto ArrArg{i} = kbToArr(KBArg{i});\n")
    arg_list = ", ".join(f"ArrArg{i}" for i in r)
    out.append(f"  auto Out = arrToKB({spec.id}::solution({arg_list}));\n")
    inputs_init = ", ".join(f"KBArg{i}" for i in r)
    out.append(
        f"  return PatternMatchKB{{{pid_int}u, std::move(Out), {{{inputs_init}}}}};\n"
    )
    out.append("}\n")
    return "".join(out)


def _emit_dispatch(roots: dict[PatternOp, list[PatternSpec]]) -> str:
    out: list[str] = []
    out.append(
        "static void computePatternKBMatches(const Operator *I, const SimplifyQuery &Q,\n"
    )
    out.append("                                    unsigned Depth,\n")
    out.append(
        "                                    SmallVectorImpl<PatternMatchKB> &Matches) {\n"
    )
    out.append("  switch (classifyPatternOp(I, Q)) {\n")
    for root in sorted(roots.keys()):
        out.append(f"  case PatternOp::{root.value}:\n")
        for spec in roots[root]:
            out.append(f"    if (auto M = match{spec.id}(I, Q, Depth + 1))\n")
            out.append("      Matches.push_back(std::move(*M));\n")
        out.append("    break;\n")
    out.append("  default:\n")
    out.append("    break;\n")
    out.append("  }\n")
    out.append("}\n")
    return "".join(out)


def _emit_pattern_impact_stats(specs: list[PatternSpec]) -> str:
    out: list[str] = []
    out.append(
        "static void recordPatternImpact(unsigned ID, unsigned BitsAdded, bool Conflict) {\n"
    )
    out.append("  switch (ID) {\n")
    for spec in specs:
        out.append(f"  case {spec.index}:\n")
        out.append(
            f"    if (BitsAdded > 0) ++Num{spec.id}ImprovedQueries, {spec.id}BitsAdded += BitsAdded;\n"
        )
        out.append(f"    if (Conflict) ++Num{spec.id}Conflicts;\n")
        out.append("    return;\n")
    out.append("  default:\n")
    out.append("    return;\n")
    out.append("  }\n")
    out.append("}\n")
    return "".join(out)


def main() -> None:
    ap = ArgumentParser(
        description="Generate KnownBitsPatternDispatch.inc from a transformer "
        "folder (a subdir of expression-named <id>.inc files) and copy the "
        ".inc files into the Generated tree."
    )
    ap.add_argument(
        "--input-dir",
        type=Path,
        required=True,
        help="Transformer folder laid out as <input_dir>/inc/, holding one <id>.inc per pattern.",
    )
    ap.add_argument(
        "--llvm-dir",
        type=Path,
        required=True,
        help="Path to LLVM project repo root",
    )
    ap.add_argument(
        "--include-helper",
        action=BooleanOptionalAction,
        default=False,
        help='Emit #include "table_helper.inc" in the dispatcher. Needed for lookup-table transformers;',
    )
    args = ap.parse_args()

    inc_files = sorted((Path(args.input_dir) / "inc").glob("*.inc"))
    patterns = sorted({f.stem: PatternDag.from_id(f.stem) for f in inc_files}.items())

    # The numeric routing id is the pattern's position in sorted-id order.
    # Both this generator and gen_optimized.py derive it the same way from the same
    # id set, so the histogram ids line up with the dispatcher's.
    specs: list[PatternSpec] = [
        PatternSpec(
            id=pid,
            dag=dag,
            root=dag.nodes[dag.result.index].op,
            index=i,
        )
        for i, (pid, dag) in enumerate(patterns)
    ]

    roots: dict[PatternOp, list[PatternSpec]] = defaultdict(list)
    for spec in specs:
        roots[spec.root].append(spec)

    # Copy the transformer .inc files into <generated-dir>/patterns, clearing any
    # stale ones first so a smaller pattern set doesn't leave orphans behind.
    # An empty pattern set is valid: it yields a no-op dispatcher (opt runs with no pattern matching)
    generated_dir = args.llvm_dir / "llvm/lib/Analysis/Generated"
    patterns_dst = generated_dir / "patterns"
    if patterns_dst.exists():
        shutil.rmtree(patterns_dst)
    patterns_dst.mkdir(parents=True)

    for spec in specs:
        src = Path(args.input_dir) / "inc" / f"{spec.id}.inc"
        if not src.is_file():
            raise ValueError(f"missing {src} for pattern {spec.id}")
        shutil.copyfile(src, patterns_dst / f"{spec.id}.inc")

    out: list[str] = []
    out.append("// Auto-generated by generate_matcher.py. Do not edit.\n")
    if args.include_helper:
        out.append('#include "table_helper.inc"\n')
    out.extend(f'#include "patterns/{spec.id}.inc" // {spec.dag}\n' for spec in specs)
    out.append("\n")

    for spec in specs:
        out.append(
            f'ALWAYS_ENABLED_STATISTIC(Num{spec.id}Matches, "KnownBits DAG pattern {spec.dag} matches");\n'
        )
        out.append(
            f'ALWAYS_ENABLED_STATISTIC(Num{spec.id}ImprovedQueries, "KnownBits DAG pattern {spec.dag} improved queries against vanilla known bits");\n'
        )
        out.append(
            f'ALWAYS_ENABLED_STATISTIC({spec.id}BitsAdded, "KnownBits DAG pattern {spec.dag} total bits added against vanilla known bits");\n'
        )
        out.append(
            f'ALWAYS_ENABLED_STATISTIC(Num{spec.id}Conflicts, "KnownBits DAG pattern {spec.dag} meet conflicts against vanilla known bits");\n'
        )
    out.append("\n")

    for spec in specs:
        out.append(_emit_pattern_function(spec))
        out.append("\n")

    out.append(_emit_pattern_impact_stats(specs))
    out.append("\n")
    out.append(_emit_dispatch(roots))

    dispatch_out = generated_dir / "KnownBitsPatternDispatch.inc"
    dispatch_out.write_text("".join(out))

    print(f"copied {len(specs)} pattern .inc -> {patterns_dst}")
    print(f"wrote dispatcher -> {dispatch_out} (include helper: {args.include_helper})")


if __name__ == "__main__":
    main()
