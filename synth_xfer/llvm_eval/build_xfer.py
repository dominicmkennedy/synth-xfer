import argparse
from collections import defaultdict
import csv
from pathlib import Path
import re
import sys
from typing import cast

from synth_xfer._util.domain import AbstractDomain
from synth_xfer._util.pattern_dsl import PatternDag
from synth_xfer._util.tsv import EnumData


def render_kb_top(pid: str, arity: int) -> str:
    """A stub KnownBits transformer whose solution() returns top.

    `bw` is the *result* bit width, supplied by the dispatcher from the matched
    instruction's result type. Deriving it from an operand would be wrong for
    patterns whose root changes width (e.g. Select -- operand 0 is the i1
    condition; icmp -- the result is i1; sext/zext-from-bool).
    """
    sig = ", ".join(
        ["unsigned bw"] + [f"std::array<APInt, 2> ssa_{i}" for i in range(arity)]
    )
    return (
        f"namespace {pid} {{\n"
        f"std::array<APInt, 2> solution({sig}) {{\n"
        f"\treturn std::array<APInt, 2>{{APInt(bw, 0), APInt(bw, 0)}};\n"
        f"}}\n}}\n"
    )


def prepare_inc_dir(out_dir: Path) -> None:
    """Create out_dir and remove any stale *.inc from a prior run."""
    out_dir.mkdir(parents=True, exist_ok=True)
    for stale in out_dir.glob("*.inc"):
        stale.unlink()


def ternary_to_zo(s: str) -> tuple[int, int]:
    """Convert ternary string (MSB-first) to (zero_mask, one_mask)."""
    zero = one = 0
    for i, ch in enumerate(reversed(s)):
        if ch == "0":
            zero |= 1 << i
        elif ch == "1":
            one |= 1 << i
    return zero, one


# --------------------------------------------------------------------------- #
# stubs mode (--pat-list)
# --------------------------------------------------------------------------- #
def build_stubs(pat_list: Path, out_dir: Path, domain_name: str) -> None:
    domain = AbstractDomain[domain_name]
    if domain != AbstractDomain.KnownBits:
        raise NotImplementedError(f"{domain} not supported yet")

    with pat_list.open(newline="") as f:
        reader = csv.DictReader(f, delimiter="\t")
        if not reader.fieldnames or "pattern" not in reader.fieldnames:
            sys.exit(f"{pat_list}: no 'pattern' column")
        patterns = [PatternDag(row["pattern"].strip()) for row in reader]

    prepare_inc_dir(out_dir)
    for p in patterns:
        (out_dir / f"{p.to_id()}.inc").write_text(render_kb_top(p.to_id(), p.num_args))
    print(f"wrote {len(patterns)} files")


# --------------------------------------------------------------------------- #
# tables mode (--table-dir)
# --------------------------------------------------------------------------- #
def _rows_from_tsv(path: Path) -> tuple[int, dict[int, list[tuple[list[str], str]]]]:
    """Returns (arity, {bw: [(args, ideal), ...]}) of non-bottom rows.

    `args`/`ideal` are MSB-first '0'/'1'/'?' ternary strings. `bw` is the
    enumeration's operand-domain width, but any individual operand or the
    result may instead be an i1 (width 1) -- e.g. a Select condition, an
    i1 input to Sext/ZextBool, or the i1 result of an icmp-rooted pattern.
    Each field is therefore validated at its own width (`bw` or 1), not `bw`.
    """
    with path.open() as f:
        data = EnumData.read_tsv(f)
    if data.metadata.domain != AbstractDomain.KnownBits:
        raise NotImplementedError(f"{path.name}: {data.metadata.domain} not supported")
    if "ideal" not in data.enumdata.columns:
        sys.exit(f"{path.name}: no 'ideal' column; run max-precise first")

    arity = data.metadata.arity
    arg_cols = [f"arg_{a}" for a in range(arity)]
    groups: dict[int, list[tuple[list[str], str]]] = defaultdict(list)
    for _, row in data.enumdata.iterrows():
        bw = int(cast(int, row["bw"]))
        args = [str(row[c]) for c in arg_cols]
        ideal = str(row["ideal"])
        if any(s == "(bottom)" for s in (*args, ideal)):
            continue
        for s in (*args, ideal):
            if not re.fullmatch(r"[01?]+", s) or len(s) not in (bw, 1):
                raise ValueError(
                    f"{path}: bad ternary string {s!r}; expected width {bw} or 1"
                )
        groups[bw].append((args, ideal))
    return arity, groups


def emit_inline(
    pid: str, arity: int, groups: dict[int, list[tuple[list[str], str]]]
) -> str:
    sig = ", ".join(
        ["unsigned bw"] + [f"std::array<APInt, 2> ssa_{i}" for i in range(arity)]
    )
    entries = []
    for bw in sorted(groups):
        for args, ideal in groups[bw]:
            zo = [ternary_to_zo(s) for s in args]
            oz, oo = ternary_to_zo(ideal)
            argZ = ", ".join(f"0x{z:X}ULL" for z, _ in zo)
            argO = ", ".join(f"0x{o:X}ULL" for _, o in zo)
            entries.append(
                f"  {{{bw}u, {{{argZ}}}, {{{argO}}}, 0x{oz:X}ULL, 0x{oo:X}ULL}},"
            )
    loads = "\n".join(
        f"  inZ[{i}] = ssa_{i}[0].getZExtValue();\n  inO[{i}] = ssa_{i}[1].getZExtValue();"
        for i in range(arity)
    )
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
  if (opbw > 64) return std::array<APInt, 2>{{APInt(bw, 0), APInt(bw, 0)}};
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


# Adjacent string literals concatenate into one object, which the standard only
# guarantees can hold 65536 bytes. Chunk rows across arrays to stay under that.
BLOB_LIMIT = 60000


def emit_blob(
    pid: str, arity: int, groups: dict[int, list[tuple[list[str], str]]]
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
                for s in (*args, ideal):
                    z, o = ternary_to_zo(s)
                    row += z.to_bytes(mask_bytes, "little") + o.to_bytes(
                        mask_bytes, "little"
                    )
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


def build_tables(table_dir: Path, out_dir: Path, inline_threshold: int) -> None:
    tsv_files = sorted(table_dir.glob("*.tsv"))
    prepare_inc_dir(out_dir)
    if not tsv_files:
        print(f"warning: no TSVs in {table_dir}; wrote 0 transformers (no-op dispatcher)")
        return

    n_stub = n_inline = n_blob = n_rows = 0
    for path in tsv_files:
        pid = path.stem  # the expression-derived pattern id
        arity, groups = _rows_from_tsv(path)
        total = sum(map(len, groups.values()))
        n_rows += total

        if not groups:
            content, n_stub = render_kb_top(pid, arity), n_stub + 1
        elif max(groups) <= 64 and total <= inline_threshold:
            content, n_inline = emit_inline(pid, arity, groups), n_inline + 1
        else:
            content, n_blob = emit_blob(pid, arity, groups), n_blob + 1
        (out_dir / f"{pid}.inc").write_text(content)

    print(f"Processed {len(tsv_files)} TSVs from {table_dir} -> {out_dir}:")
    print(f"  stub: {n_stub}  inline: {n_inline}  blob: {n_blob}  (rows: {n_rows})")


def main() -> None:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument(
        "--pat-list",
        type=Path,
        help="stubs: TSV with a `pattern` column of expression strings",
    )
    src.add_argument(
        "--table-dir", type=Path, help="tables: directory of ideal-filled <id>.tsv files"
    )
    ap.add_argument(
        "--output-dir",
        type=Path,
        required=True,
        help="Output dir: <id>.inc files are written here",
    )
    ap.add_argument(
        "-d",
        "--domain",
        choices=[str(x) for x in AbstractDomain],
        help="stubs: abstract domain (required with --pat-list)",
    )
    ap.add_argument(
        "--inline-threshold",
        type=int,
        default=16,
        help="tables: row count <= this AND max bw <= 64 -> inline "
        "constexpr Entry[]; otherwise byte-blob (default 16)",
    )
    args = ap.parse_args()

    if args.pat_list is not None:
        if args.domain is None:
            ap.error("--pat-list requires -d/--domain")
        build_stubs(args.pat_list, args.output_dir, args.domain)
    else:
        build_tables(args.table_dir, args.output_dir, args.inline_threshold)


if __name__ == "__main__":
    main()
