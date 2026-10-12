"""Reset an LLVM checkout's generated pattern transformers to the no-op state.

Removes everything under llvm/lib/Analysis/Generated/patterns/ and overwrites the
three *PatternDispatch.inc files with empty dispatchers, undoing whatever
generate_xfers last wired in.
"""

from argparse import ArgumentParser
from pathlib import Path
import shutil
import sys

GENERATED_SUBDIR = Path("llvm/lib/Analysis/Generated")

DISPATCH_STUBS: dict[str, str] = {
    "UConstRangePatternDispatch.inc": """\
static void computePatternUCRMatches(const Operator *, bool, AssumptionCache *,
                                     const Instruction *, const DominatorTree *,
                                     unsigned,
                                     SmallVectorImpl<PatternMatchCR> &) {}

static void recordUCRPatternImpact(unsigned, uint64_t, uint64_t, bool) {}
""",
    "SConstRangePatternDispatch.inc": """\
static void computePatternSCRMatches(const Operator *, bool, AssumptionCache *,
                                     const Instruction *, const DominatorTree *,
                                     unsigned,
                                     SmallVectorImpl<PatternMatchCR> &) {}

static void recordSCRPatternImpact(unsigned, uint64_t, uint64_t, bool) {}
""",
    "KnownBitsPatternDispatch.inc": """\
static void computePatternKBMatches(const Operator *, const SimplifyQuery &,
                                    unsigned,
                                    SmallVectorImpl<PatternMatchKB> &) {}

static void recordKBPatternImpact(unsigned, unsigned, uint64_t, bool) {}
""",
}


def restore(llvm_dir: Path) -> None:
    generated_dir = llvm_dir / GENERATED_SUBDIR
    generated_dir.mkdir(parents=True, exist_ok=True)

    patterns_dir = generated_dir / "patterns"
    patterns_dir.mkdir(exist_ok=True)
    removed = 0
    for entry in patterns_dir.iterdir():
        if entry.is_dir() and not entry.is_symlink():
            shutil.rmtree(entry)
        else:
            entry.unlink()
        removed += 1
    print(f"removed {removed} entries from {patterns_dir}")

    for name, text in DISPATCH_STUBS.items():
        out = generated_dir / name
        out.write_text(text)
        print(f"wrote no-op dispatcher -> {out}")


def main() -> None:
    ap = ArgumentParser(
        description="Reset an LLVM checkout's generated pattern transformers to no-ops"
    )
    ap.add_argument("llvm_dir", type=Path, help="Root of the LLVM git repository")
    args = ap.parse_args()

    llvm_dir: Path = args.llvm_dir
    if not (llvm_dir / "llvm" / "lib" / "Analysis").is_dir():
        sys.exit(f"error: {llvm_dir} does not look like an LLVM repository root")
    restore(llvm_dir)


if __name__ == "__main__":
    main()
