from argparse import ArgumentParser
from collections import defaultdict
import csv
from dataclasses import dataclass
from pathlib import Path
import sys
from typing import cast

from synth_xfer._util.domain import AbstractDomain, get_bvs_from_abst
from synth_xfer._util.pattern_dsl import ArgRef, PatternDag, PatternOp, PatternRef
from synth_xfer._util.tsv import EnumData


@dataclass(frozen=True)
class PatternSpec:
    id: str
    dag: PatternDag
    root: PatternOp
    index: int


TableRows = dict[int, list[tuple[list[str], str]]]


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
    PatternOp.ICmpEq: "m_c_IntSpecificICmp(ICmpInst::ICMP_EQ, {0}, {1})",
    PatternOp.ICmpNe: "m_c_IntSpecificICmp(ICmpInst::ICMP_NE, {0}, {1})",
    PatternOp.ICmpSlt: "m_c_IntSpecificICmp(ICmpInst::ICMP_SLT, {0}, {1})",
    PatternOp.ICmpSle: "m_c_IntSpecificICmp(ICmpInst::ICMP_SLE, {0}, {1})",
    PatternOp.ICmpUlt: "m_c_IntSpecificICmp(ICmpInst::ICMP_ULT, {0}, {1})",
    PatternOp.ICmpUle: "m_c_IntSpecificICmp(ICmpInst::ICMP_ULE, {0}, {1})",
    PatternOp.TruncToBool: "m_TruncToBool({0})",
    PatternOp.ZextBool: "m_ZExtBool({0})",
    PatternOp.SextBool: "m_SExtBool({0})",
    PatternOp.Select: "m_Select({0}, {1}, {2})",
}

BLOB_LIMIT = 60000


WIDTH_CHANGING_OPS = frozenset(
    {
        PatternOp.ICmpEq,
        PatternOp.ICmpNe,
        PatternOp.ICmpSlt,
        PatternOp.ICmpSle,
        PatternOp.ICmpSgt,
        PatternOp.ICmpSge,
        PatternOp.ICmpUlt,
        PatternOp.ICmpUle,
        PatternOp.ICmpUgt,
        PatternOp.ICmpUge,
        PatternOp.TruncToBool,
        PatternOp.ZextBool,
        PatternOp.SextBool,
    }
)


def _cr_prefix(domain: AbstractDomain) -> str:
    if domain == AbstractDomain.SConstRange:
        return "SCR"
    if domain == AbstractDomain.UConstRange:
        return "UCR"
    raise NotImplementedError(domain)


def _symbol_id(domain: AbstractDomain, pid: str) -> str:
    if domain == AbstractDomain.KnownBits:
        return pid
    return f"{_cr_prefix(domain)}{pid}"


def render_cr_top(pid: str, arity: int, domain: AbstractDomain) -> str:
    args = [f"const ConstantRange &ssa_{i}" for i in range(arity)]
    sig = ", ".join(["unsigned bw", *args])
    symbol = _symbol_id(domain, pid)
    return (
        f"namespace {symbol} {{\n"
        f"ConstantRange solution({sig}) {{\n"
        f"\treturn ConstantRange::getFull(bw);\n"
        f"}}\n}}\n"
    )


def render_kb_top(pid: str, arity: int) -> str:
    sig = ", ".join([f"std::array<APInt, 2> ssa_{i}" for i in range(arity)])
    return (
        f"namespace {pid} {{\n"
        f"std::array<APInt, 2> solution(unsigned bw, {sig}) {{\n"
        f"\treturn std::array<APInt, 2>{{APInt(bw, 0), APInt(bw, 0)}};\n"
        f"}}\n}}\n"
    )


def _kb_masks(s: str, bw: int) -> tuple[int, int]:
    parsed = get_bvs_from_abst(
        s, AbstractDomain.KnownBits, bw if s == "(bottom)" else len(s)
    )
    if parsed is None:
        mask = (1 << bw) - 1
        return mask, mask
    return parsed


def build_stub_transformers(
    patterns: Path,
    domain: AbstractDomain,
    top: int | None,
    patterns_per_root: int | None,
    count_at_least: int | None,
) -> dict[str, str]:
    with patterns.open(newline="") as f:
        reader = csv.DictReader(f, delimiter="\t")
        if not reader.fieldnames or "pattern" not in reader.fieldnames:
            sys.exit(f"{patterns}: no 'pattern' column")

        dags: list[PatternDag] = []
        for row in reader:
            if count_at_least is not None and int(row["count"]) < count_at_least:
                continue
            dags.append(PatternDag(row["pattern"].strip()))

    if patterns_per_root is not None:
        root_counts: dict[PatternOp, int] = defaultdict(int)
        capped_dags: list[PatternDag] = []
        for dag in dags:
            root = dag.nodes[dag.result.index].op
            if root_counts[root] >= patterns_per_root:
                continue
            root_counts[root] += 1
            capped_dags.append(dag)
        dags = capped_dags

    if top is not None:
        dags = dags[:top]

    if domain == AbstractDomain.KnownBits:
        return {dag.to_id(): render_kb_top(dag.to_id(), dag.num_args) for dag in dags}
    return {dag.to_id(): render_cr_top(dag.to_id(), dag.num_args, domain) for dag in dags}


def _read_table_tsv(path: Path) -> tuple[str, AbstractDomain, int, TableRows]:
    """Returns (pattern id, domain, arity, {bw: [(args, ideal), ...]})."""
    with path.open() as f:
        data = EnumData.read_tsv(f)
    if "ideal" not in data.enumdata.columns:
        sys.exit(f"{path.name}: no 'ideal' column; run max-precise first")

    domain = data.metadata.domain
    arity = data.metadata.arity
    arg_cols = [f"arg_{a}" for a in range(arity)]
    groups: TableRows = defaultdict(list)
    for _, row in data.enumdata.iterrows():
        bw = int(cast(int, row["bw"]))
        args = [str(row[c]) for c in arg_cols]
        ideal = str(row["ideal"])
        if domain not in (
            AbstractDomain.KnownBits,
            AbstractDomain.SConstRange,
            AbstractDomain.UConstRange,
        ):
            raise NotImplementedError(f"{path.name}: {domain} not supported")
        if "(bottom)" in args:
            continue
        groups[bw].append((args, ideal))

    return data.metadata.op.to_id(), domain, arity, groups


def emit_kb_inline(
    pid: str,
    arity: int,
    groups: TableRows,
) -> str:
    sig = ", ".join(
        ["unsigned bw"] + [f"std::array<APInt, 2> ssa_{i}" for i in range(arity)]
    )
    entries = []
    for bw in sorted(groups):
        for args, ideal in groups[bw]:
            zo = [_kb_masks(s, bw) for s in args]
            oz, oo = _kb_masks(ideal, bw)
            arg_z = ", ".join(f"0x{z:X}ULL" for z, _ in zo)
            arg_o = ", ".join(f"0x{o:X}ULL" for _, o in zo)
            entries.append(
                f"  {{{bw}u, {{{arg_z}}}, {{{arg_o}}}, 0x{oz:X}ULL, 0x{oo:X}ULL}},"
            )
    loads = "\n".join(
        f"  inZ[{i}] = ssa_{i}[0].getZExtValue();\n  inO[{i}] = ssa_{i}[1].getZExtValue();"
        for i in range(arity)
    )
    width_guard = " || ".join(f"ssa_{i}[0].getBitWidth() > 64" for i in range(arity))
    entries_block = "\n".join(entries)
    return f"""namespace {pid} {{
namespace {{
struct Entry {{ unsigned bw; uint64_t argZ[{arity}], argO[{arity}], outZ, outO; }};
static constexpr Entry kEntries[] = {{
{entries_block}
}};
}} // namespace

std::array<APInt, 2> solution({sig}) {{
  unsigned opbw = ssa_0[0].getBitWidth();
  if ({width_guard}) return std::array<APInt, 2>{{APInt(bw, 0), APInt(bw, 0)}};
  uint64_t inZ[{arity}], inO[{arity}];
{loads}
  uint64_t outZ = 0, outO = 0;
  for (const Entry &E : kEntries) {{
    if (E.bw != opbw) continue;
    bool match = true;
    for (unsigned a = 0; a < {arity}; ++a)
      if ((E.argZ[a] & ~inZ[a]) | (E.argO[a] & ~inO[a])) {{ match = false; break; }}
    if (match) outZ |= E.outZ, outO |= E.outO;
  }}
  return std::array<APInt, 2>{{APInt(bw, outZ), APInt(bw, outO)}};
}}
}}
"""


def emit_kb_blob(
    pid: str,
    arity: int,
    groups: TableRows,
) -> str:
    sig = ", ".join(
        ["unsigned bw"] + [f"std::array<APInt, 2> ssa_{i}" for i in range(arity)]
    )
    blobs, tables = [], []
    for bw in sorted(groups):
        mask_bytes = (bw + 7) // 8
        per_chunk = max(1, BLOB_LIMIT // (2 * (arity + 1) * mask_bytes))
        rows = groups[bw]
        for ci, start in enumerate(range(0, len(rows), per_chunk)):
            chunk = rows[start : start + per_chunk]
            name = f"kBlob_bw{bw}_{ci}"
            lits = []
            for args, ideal in chunk:
                row = bytearray()
                for s in args:
                    z, o = _kb_masks(s, bw)
                    row += z.to_bytes(mask_bytes, "little") + o.to_bytes(
                        mask_bytes, "little"
                    )
                z, o = _kb_masks(ideal, bw)
                row += z.to_bytes(mask_bytes, "little") + o.to_bytes(mask_bytes, "little")
                lits.append('    "' + "".join(f"\\x{b:02x}" for b in row) + '"')
            blobs.append(
                f"static const unsigned char {name}[] =\n" + "\n".join(lits) + ";"
            )
            tables.append(f"  {{{bw}u, {len(chunk)}u, {name}}},")
    arg_list = ", ".join(f"ssa_{i}" for i in range(arity))
    blob_block = "\n".join(blobs)
    table_block = "\n".join(tables)
    return f"""namespace {pid} {{
namespace {{
{blob_block}

static const ::KnownBitsPatterns::BwTable kTables[] = {{
{table_block}
}};
}} // namespace

std::array<APInt, 2> solution({sig}) {{
  const std::array<APInt, 2> args[{arity}] = {{{arg_list}}};
  return ::KnownBitsPatterns::lookupKB<{arity}>(bw, args, kTables, std::size(kTables));
}}
}}
"""


def _word_bytes(bw: int) -> int:
    return (bw + 7) // 8


def _le_bytes(value: int, bw: int) -> bytes:
    return (value % (1 << bw)).to_bytes(_word_bytes(bw), "little")


def _cr_bounds(s: str, domain: AbstractDomain, bw: int) -> tuple[int, int]:
    interval = get_bvs_from_abst(s, domain, bw)
    if interval is None:
        return 0, 0

    lo, hi = interval
    if domain == AbstractDomain.UConstRange:
        umax = (1 << bw) - 1
        if lo == 0 and hi == umax:
            return umax, umax
        upper = 0 if hi == umax else hi + 1
    elif domain == AbstractDomain.SConstRange:
        smin = -(1 << (bw - 1))
        smax = (1 << (bw - 1)) - 1
        if lo == smin and hi == smax:
            umax = (1 << bw) - 1
            return umax, umax
        upper = smin if hi == smax else hi + 1
    else:
        raise NotImplementedError(domain)

    return lo, upper


def _cr_range_bytes(s: str, domain: AbstractDomain, bw: int) -> bytes:
    lower, upper = _cr_bounds(s, domain, bw)
    return _le_bytes(lower, bw) + _le_bytes(upper, bw)


def emit_cr_blob(
    pid: str,
    arity: int,
    groups: TableRows,
    domain: AbstractDomain,
) -> str:
    args = [f"const ConstantRange &ssa_{i}" for i in range(arity)]
    sig = ", ".join(["unsigned bw", *args])
    symbol = _symbol_id(domain, pid)
    lookup = f"lookup{_cr_prefix(domain)}<{arity}>"

    blobs: list[str] = []
    tables: list[str] = []
    for bw in sorted(groups):
        mask_bytes = _word_bytes(bw)
        row_bytes = 2 * (arity + 1) * mask_bytes
        per_chunk = max(1, BLOB_LIMIT // row_bytes)
        rows = groups[bw]
        for ci, start in enumerate(range(0, len(rows), per_chunk)):
            chunk = rows[start : start + per_chunk]
            name = f"kBlob_bw{bw}_{ci}"
            lits: list[str] = []
            for row_args, ideal in chunk:
                row = bytearray()
                for arg in row_args:
                    row += _cr_range_bytes(arg, domain, bw)
                row += _cr_range_bytes(ideal, domain, bw)
                lits.append('    "' + "".join(f"\\x{b:02x}" for b in row) + '"')
            blobs.append(
                f"static const unsigned char {name}[] =\n" + "\n".join(lits) + ";"
            )
            tables.append(f"  {{{bw}u, {len(chunk)}u, {name}}},")

    arg_list = ", ".join(f"ssa_{i}" for i in range(arity))
    blob_block = "\n".join(blobs)
    table_block = "\n".join(tables)
    return f"""namespace {symbol} {{
namespace {{
{blob_block}

static const ::ConstantRangePatterns::CRTable kTables[] = {{
{table_block}
}};
}} // namespace

ConstantRange solution({sig}) {{
  const std::array<ConstantRange, {arity}> args = {{{arg_list}}};
  return ::ConstantRangePatterns::{lookup}(bw, args, kTables, std::size(kTables));
}}
}}
"""


def build_table_transformers(
    table_dir: Path,
    inline_threshold: int,
) -> dict[AbstractDomain, dict[str, str]]:
    transformers: dict[AbstractDomain, dict[str, str]] = defaultdict(dict)
    tsv_files = sorted(table_dir.glob("*.tsv"))

    stats: dict[AbstractDomain, dict[str, int]] = defaultdict(
        lambda: {"stub": 0, "inline": 0, "blob": 0, "rows": 0}
    )
    for path in tsv_files:
        pid, domain, arity, groups = _read_table_tsv(path)
        total = sum(map(len, groups.values()))
        stats[domain]["rows"] += total

        if domain == AbstractDomain.KnownBits:
            if not groups:
                transformers[domain][pid] = render_kb_top(pid, arity)
                stats[domain]["stub"] += 1
            elif max(groups) <= 64 and total <= inline_threshold:
                transformers[domain][pid] = emit_kb_inline(pid, arity, groups)
                stats[domain]["inline"] += 1
            else:
                transformers[domain][pid] = emit_kb_blob(pid, arity, groups)
                stats[domain]["blob"] += 1
        else:
            if not groups:
                transformers[domain][pid] = render_cr_top(pid, arity, domain)
                stats[domain]["stub"] += 1
            else:
                transformers[domain][pid] = emit_cr_blob(pid, arity, groups, domain)
                stats[domain]["blob"] += 1

    print(f"Processed {len(tsv_files)} TSVs from {table_dir}:")
    for domain in sorted(stats.keys(), key=str):
        s = stats[domain]
        print(
            f"  {domain}: stub: {s['stub']}  inline: {s['inline']}  "
            f"blob: {s['blob']}  (rows: {s['rows']})"
        )

    return transformers


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


def _emit_bw_guard(arity: int) -> str:
    value_bw = "V->getType()->getScalarSizeInBits()"

    arg_checks = " || ".join(f"!CheckBW(Arg{i})" for i in range(arity))
    return f"""  unsigned MatchBW = ResBW == 1 ? 0 : ResBW;
  auto CheckBW = [&](const Value *V) {{
    unsigned BW = {value_bw};
    if (BW == 1)
      return true;
    if (MatchBW == 0) {{
      MatchBW = BW;
      return true;
    }}
    return BW == MatchBW;
  }};
  if ({arg_checks})
    return std::nullopt;
"""


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


def _emit_dispatch(
    domain: AbstractDomain, roots: dict[PatternOp, list[PatternSpec]]
) -> str:
    out: list[str] = []
    if domain == AbstractDomain.KnownBits:
        fn_name = "computePatternKBMatches"
        match_ty = "PatternMatchKB"
        query_arg = ", const SimplifyQuery &Q"
        match_args = "I, Q, Depth + 1"
        classify_arg = "Q.IIQ"
    elif domain == AbstractDomain.SConstRange:
        fn_name = "computePatternSCRMatches"
        match_ty = "PatternMatchCR"
        query_arg = (
            ", bool UseInstrInfo, AssumptionCache *AC,\n"
            "                                    const Instruction *CtxI, const DominatorTree *DT"
        )
        match_args = "I, UseInstrInfo, AC, CtxI, DT, Depth + 1"
        classify_arg = "InstrInfoQuery(UseInstrInfo)"
    elif domain == AbstractDomain.UConstRange:
        fn_name = "computePatternUCRMatches"
        match_ty = "PatternMatchCR"
        query_arg = (
            ", bool UseInstrInfo, AssumptionCache *AC,\n"
            "                                    const Instruction *CtxI, const DominatorTree *DT"
        )
        match_args = "I, UseInstrInfo, AC, CtxI, DT, Depth + 1"
        classify_arg = "InstrInfoQuery(UseInstrInfo)"
    else:
        raise NotImplementedError(domain)

    out.append(f"static void {fn_name}(const Operator *I{query_arg}, unsigned Depth,\n")
    out.append(
        f"                                    SmallVectorImpl<{match_ty}> &Matches) {{\n"
    )
    out.append(f"  switch (classifyPatternOp(I, {classify_arg})) {{\n")
    for root in sorted(roots.keys()):
        out.append(f"  case PatternOp::{root.value}:\n")
        for spec in roots[root]:
            out.append(
                f"    if (auto M = match{_symbol_id(domain, spec.id)}({match_args}))\n"
            )
            out.append("      Matches.push_back(std::move(*M));\n")
        out.append("    break;\n")
    out.append("  default:\n")
    out.append("    break;\n")
    out.append("  }\n")
    out.append("}\n")
    return "".join(out)


def _emit_pattern_impact_stats(specs: list[PatternSpec], domain: AbstractDomain) -> str:
    out: list[str] = []
    if domain == AbstractDomain.KnownBits:
        out.append(
            "static void recordKBPatternImpact(unsigned ID, unsigned BitsAdded,\n"
            "                                  uint64_t RelativeReduced, bool Conflict) {\n"
        )
    elif domain in (AbstractDomain.SConstRange, AbstractDomain.UConstRange):
        out.append(
            f"static void record{_cr_prefix(domain)}PatternImpact(unsigned ID, uint64_t PrecisionBitsAdded,\n"
            "                                  uint64_t RelativeReduced, bool Bottom) {\n"
        )
    else:
        raise NotImplementedError(domain)

    out.append("  switch (ID) {\n")
    for spec in specs:
        out.append(f"  case {spec.index}:\n")
        if domain == AbstractDomain.KnownBits:
            out.append(
                f"    if (BitsAdded > 0 || RelativeReduced > 0) ++Num{spec.id}ImprovedQueries;\n"
            )
            out.append(f"    {spec.id}BitsAdded += BitsAdded;\n")
            out.append(f"    {spec.id}RelativeReduced += RelativeReduced;\n")
            out.append(f"    if (Conflict) ++Num{spec.id}Conflicts;\n")
        else:
            symbol = _symbol_id(domain, spec.id)
            out.append(
                f"    if (PrecisionBitsAdded > 0 || RelativeReduced > 0) ++Num{symbol}ImprovedQueries;\n"
            )
            out.append(f"    {symbol}PrecisionBitsAdded += PrecisionBitsAdded;\n")
            out.append(f"    {symbol}RelativeReduced += RelativeReduced;\n")
            out.append(f"    if (Bottom) ++Num{symbol}Bottom;\n")
        out.append("    return;\n")
    out.append("  default:\n")
    out.append("    return;\n")
    out.append("  }\n")
    out.append("}\n")
    return "".join(out)


@dataclass(frozen=True)
class DispatcherEmitter:
    specs: list[PatternSpec]
    domain: AbstractDomain

    @classmethod
    def from_transformers(
        cls, transformers: dict[str, str], domain: AbstractDomain
    ) -> "DispatcherEmitter":
        patterns = sorted((pid, PatternDag.from_id(pid)) for pid in transformers)
        specs = [
            PatternSpec(
                id=pid,
                dag=dag,
                root=dag.nodes[dag.result.index].op,
                index=i,
            )
            for i, (pid, dag) in enumerate(patterns)
        ]
        return cls(specs, domain)

    @property
    def roots(self) -> dict[PatternOp, list[PatternSpec]]:
        roots: dict[PatternOp, list[PatternSpec]] = defaultdict(list)
        for spec in self.specs:
            roots[spec.root].append(spec)
        return roots

    def _stat(self, name: str, spec: PatternSpec, desc: str) -> str:
        return (
            f"ALWAYS_ENABLED_STATISTIC({name}, "
            f'"{self.domain} DAG pattern {spec.dag} {desc}");\n'
        )

    def _stat_specs(self) -> list[tuple[str, str]]:
        if self.domain == AbstractDomain.KnownBits:
            return [
                ("Num{id}Matches", "matches"),
                ("Num{id}ImprovedQueries", "improved queries against vanilla analysis"),
                ("{id}BitsAdded", "total bits added against vanilla analysis"),
                (
                    "{id}RelativeReduced",
                    "total normalized KB precision added by pattern KB meet, in parts per 1000",
                ),
                ("Num{id}Conflicts", "meet conflicts against vanilla analysis"),
            ]

        return [
            ("Num{id}Matches", "matches"),
            ("Num{id}ImprovedQueries", "improved queries against vanilla analysis"),
            (
                "{id}PrecisionBitsAdded",
                "total precision bits added against vanilla analysis",
            ),
            (
                "{id}RelativeReduced",
                "total scaled relative set-size reduction against vanilla analysis",
            ),
            ("Num{id}Bottom", "bottom intersections against vanilla analysis"),
        ]

    def _emit_stats(self, spec: PatternSpec) -> str:
        symbol = _symbol_id(self.domain, spec.id)
        return "".join(
            self._stat(name.format(id=symbol), spec, desc)
            for name, desc in self._stat_specs()
        )

    def emit(self) -> str:
        out: list[str] = []
        out.append("// Auto-generated by generate_xfers.py. Do not edit.\n")
        out.extend(
            f'#include "patterns/{_symbol_id(self.domain, spec.id)}.inc" // {spec.dag}\n'
            for spec in self.specs
        )
        out.append("\n")

        for spec in self.specs:
            out.append(self._emit_stats(spec))
        out.append("\n")

        for spec in self.specs:
            out.append(self.emit_pattern_function(spec))
            out.append("\n")

        out.append(_emit_pattern_impact_stats(self.specs, self.domain))
        out.append("\n")
        out.append(_emit_dispatch(self.domain, self.roots))
        return "".join(out)

    def emit_pattern_function(self, spec: PatternSpec) -> str:
        r = range(spec.dag.num_args)
        arg_decl = "const Value " + ", ".join(f"*Arg{i} = nullptr" for i in r) + ";"

        matcher = _emit_match_expr(spec.dag, spec.dag.result, set())
        pid_int = spec.index
        depths = spec.dag.arg_depths()
        max_offset = max(depths.values()) - 1
        out: list[str] = []

        if self.domain == AbstractDomain.KnownBits:
            out.append(
                f"static std::optional<PatternMatchKB> match{spec.id}(const Operator *I, const SimplifyQuery &Q, unsigned Depth) {{\n"
            )
        else:
            out.append(
                f"static std::optional<PatternMatchCR> match{_symbol_id(self.domain, spec.id)}(const Operator *I, bool UseInstrInfo, AssumptionCache *AC, const Instruction *CtxI, const DominatorTree *DT, unsigned Depth) {{\n"
            )
        # The deepest leaf recurses at Depth + max_offset, if that would exceed the recursion cap, decline the match
        # This keeps every leaf call within computeKnownBits's Depth <= MaxAnalysisRecursionDepth contract
        out.append(
            f"  if (Depth + {max_offset} > MaxAnalysisRecursionDepth)\n"
            f"    return std::nullopt;\n"
        )
        out.append(f"  {arg_decl}\n")
        out.append(_emit_guard(matcher))
        out.append("  unsigned ResBW = I->getType()->getScalarSizeInBits();\n")
        # Non-integer results (e.g. pointers) report bw 0; skip them so we never
        # build a zero-width KnownBits.
        out.append("  if (ResBW == 0)\n    return std::nullopt;\n")
        if any(node.op in WIDTH_CHANGING_OPS for node in spec.dag.nodes):
            out.append(_emit_bw_guard(spec.dag.num_args))
        out.append(f"  ++Num{_symbol_id(self.domain, spec.id)}Matches;\n")
        if self.domain == AbstractDomain.KnownBits:
            for i in r:
                # Effective depth: charge each leaf its true nesting level so a nested
                # operand recurses with the same budget vanilla computeKnownBitsFromOperator would give it.
                offset = depths[ArgRef(i)] - 1
                depth_expr = "Depth" if offset == 0 else f"Depth + {offset}"
                out.append(
                    f"  auto KBArg{i} = computeKnownBits(Arg{i}, Q, {depth_expr});\n"
                )
            for i in r:
                out.append(f"  auto ArrArg{i} = kbToArr(KBArg{i});\n")
            # Pass the matched value's result width so a pattern whose root changes width
            # (Select, icmp, *ext-from-bool) returns a KnownBits sized to I, not to an
            # operand. This is the same width VanillaKnown uses, so the meet in
            # computeKnownBits never hits an APInt bit-width mismatch.
            arg_list = ", ".join(["ResBW", *(f"ArrArg{i}" for i in r)])
            out.append(f"  auto Out = arrToKB({spec.id}::solution({arg_list}));\n")
            inputs_init = ", ".join(f"KBArg{i}" for i in r)
            out.append(
                f"  return PatternMatchKB{{{pid_int}u, std::move(Out), {{{inputs_init}}}}};\n"
            )
        else:
            for i in r:
                offset = depths[ArgRef(i)] - 1
                depth_expr = "Depth" if offset == 0 else f"Depth + {offset}"
                for_signed = (
                    "true" if self.domain == AbstractDomain.SConstRange else "false"
                )
                out.append(
                    f"  auto CRArg{i} = computeConstantRange(Arg{i}, {for_signed}, UseInstrInfo, AC, CtxI, DT, {depth_expr});\n"
                )
            arg_list = ", ".join(["ResBW", *(f"CRArg{i}" for i in r)])
            out.append(
                f"  auto Out = {_symbol_id(self.domain, spec.id)}::solution({arg_list});\n"
            )
            inputs_init = ", ".join(f"CRArg{i}" for i in r)
            out.append(
                f"  return PatternMatchCR{{{pid_int}u, std::move(Out), {{{inputs_init}}}}};\n"
            )
        out.append("}\n")
        return "".join(out)


def wire_transformers(
    llvm_dir: Path,
    transformers: dict[str, str],
    domain: AbstractDomain,
) -> None:
    # write transformers into Generated/patterns, clearing any stale ones first
    # An empty pattern set is valid: it yields a no-op dispatcher
    emitter = DispatcherEmitter.from_transformers(transformers, domain)
    generated_dir = llvm_dir / "llvm/lib/Analysis/Generated"
    generated_dir.mkdir(parents=True, exist_ok=True)

    patterns_dst = generated_dir / "patterns"
    patterns_dst.mkdir(parents=True, exist_ok=True)
    for old in patterns_dst.glob("*.inc"):
        if domain == AbstractDomain.KnownBits:
            if not old.stem.startswith(("SCR", "UCR")):
                old.unlink()
        elif old.stem.startswith(_cr_prefix(domain)):
            old.unlink()

    for spec in emitter.specs:
        symbol = _symbol_id(domain, spec.id)
        (patterns_dst / f"{symbol}.inc").write_text(transformers[spec.id])

    if domain == AbstractDomain.KnownBits:
        dispatch_out = generated_dir / "KnownBitsPatternDispatch.inc"
    elif domain == AbstractDomain.UConstRange:
        dispatch_out = generated_dir / "UConstRangePatternDispatch.inc"
    elif domain == AbstractDomain.SConstRange:
        dispatch_out = generated_dir / "SConstRangePatternDispatch.inc"
    else:
        raise NotImplementedError()

    dispatch_out.write_text(emitter.emit())

    print(f"wrote {len(emitter.specs)} pattern .inc -> {patterns_dst}")
    print(f"wrote dispatcher -> {dispatch_out}")


def main() -> None:
    ap = ArgumentParser(description="Generate xfer tables and wire the dispatch to LLVM")
    subcommands = ap.add_subparsers(dest="mode", required=True)

    stubs = subcommands.add_parser("stubs", help="generate top-returning stubs")
    stubs.add_argument("--patterns", type=Path, required=True, help="TSV with patterns")
    stubs.add_argument(
        "-d",
        "--domain",
        type=str,
        choices=[str(x) for x in AbstractDomain],
        required=True,
    )
    stubs.add_argument(
        "--llvm-dir",
        type=Path,
        required=True,
        help="Path to LLVM project repo root",
    )
    stubs.add_argument(
        "--top",
        type=int,
        default=None,
        help="generate stubs only for the first N pattern rows",
    )
    stubs.add_argument(
        "--patterns-per-root",
        type=int,
        default=None,
        help="maximum number of stubs to generate for each root op",
    )
    stubs.add_argument(
        "--count-at-least",
        type=int,
        default=None,
        help="generate stubs only for patterns with count >= this value",
    )

    tables = subcommands.add_parser("tables", help="generate lookup-table xfers")
    tables.add_argument(
        "--table-dir",
        type=Path,
        required=True,
        help="directory of ideal-filled <id>.tsv files",
    )
    tables.add_argument(
        "--llvm-dir",
        type=Path,
        required=True,
        help="Path to LLVM project repo root",
    )
    tables.add_argument(
        "--inline-threshold",
        type=int,
        default=16,
        help="row count <= this AND max bw <= 64 uses constexpr Entry[]",
    )

    args = ap.parse_args()
    if args.mode == "stubs":
        d = AbstractDomain[args.domain]
        transformers = build_stub_transformers(
            args.patterns,
            d,
            args.top,
            args.patterns_per_root,
            args.count_at_least,
        )
        wire_transformers(args.llvm_dir, transformers, d)
    else:
        transformers_by_domain = build_table_transformers(
            args.table_dir, args.inline_threshold
        )
        for domain, transformers in sorted(transformers_by_domain.items(), key=str):
            wire_transformers(args.llvm_dir, transformers, domain)


if __name__ == "__main__":
    main()
