#!/usr/bin/env bash
# Pipeline steps 1-5: build stub transformers, harvest a per-pattern histogram
# from the benchmark, fill in SMT-optimal (max-precise) outputs, and prune.
#
# Deliverable: the pruned lookup tables in WORK_DIR/pruned (input to
# phase2_eval.sh). All intermediates (histograms, ideal tables) persist under
# WORK_DIR too, so an interrupted run is not wiped.
#
# Run from the synth-xfer repo root, inside the venv. LLVM_DIR, BENCH_DIR and
# PAT_LIST are required; the rest have defaults. e.g.
#   LLVM_DIR=~/repos/llvm-project BENCH_DIR=~/repos/llvm-opt-benchmark \
#       PAT_LIST=tests/data/pattern/top_10_pattern.tsv \
#       WORK_DIR=outputs/run1 ./phase1_build_tables.sh
#
#   LLVM_DIR    LLVM checkout with build/bin/opt   (required)
#   BENCH_DIR   llvm-opt-benchmark checkout        (required)
#   PAT_LIST    TSV with a `pattern` column        (required)
#   WORK_DIR    holds all artifacts (hist/,        (default outputs/run)
#               tables/, pruned/); pass
#               WORK_DIR/pruned as TABLE_DIR to phase2
#   FILTER      benchmark subdir filter, "" = all  (default "" = whole suite)
#   FILES       file listing bench-relative .ll     (default "" = no file filter)
#               paths to restrict to (--filter-file)
#   TABLE_TIMEOUT  per-table wall-clock cap in seconds  (default "" = no cap)
#               for step 4; a table over the cap is logged as FAIL instead of
#               blocking the run forever
#   RESUME      1 = skip steps whose outputs already   (default 0)
#               exist (histogram, pruned tables), for
#               restarting an interrupted run with the
#               same PAT_LIST
set -euo pipefail

: "${LLVM_DIR:?must be set to the llvm-project checkout (with build/bin/opt)}"
: "${BENCH_DIR:?must be set to the llvm-opt-benchmark checkout}"
: "${PAT_LIST:?must be set to a TSV with a \`pattern\` column}"
WORK_DIR="${WORK_DIR:-outputs/run}"
FILTER="${FILTER:-}"
FILES="${FILES:-}"
TABLE_TIMEOUT="${TABLE_TIMEOUT:-}"
RESUME="${RESUME:-0}"

OPT="$LLVM_DIR/build/bin/opt"
filter_arg=()
[[ -n "$FILTER" ]] && filter_arg+=(--filter "$FILTER")
[[ -n "$FILES" ]] && filter_arg+=(--filter-file "$FILES")

table_timeout_arg=()
[[ -n "$TABLE_TIMEOUT" ]] && table_timeout_arg+=(--table-timeout "$TABLE_TIMEOUT")

mkdir -p "$WORK_DIR"

# True when RESUME=1 and $1 already holds at least one .tsv.
have_tsv() {
    [[ "$RESUME" == 1 ]] && compgen -G "$1/*.tsv" > /dev/null
}

# Steps 1-3 exist only to produce the histogram, so on resume they go together.
if have_tsv "$WORK_DIR/hist"; then
    echo ">>> [1-3/5] histogram present in $WORK_DIR/hist, skipping (RESUME=1)"
else
    echo ">>> [1/5] stub transformers -> dispatcher"
    python3 -m synth_xfer.llvm_eval.generate_xfers stubs \
        --patterns "$PAT_LIST" -d KnownBits --llvm-dir "$LLVM_DIR"

    echo ">>> [2/5] rebuild opt"
    ninja -C "$LLVM_DIR/build" opt

    echo ">>> [3/5] benchmark -> histogram"
    python3 -m synth_xfer.llvm_eval.run_opt_benchmark \
        --bench-path "$BENCH_DIR" --opt-path "$OPT" \
        --pattern-hist "$WORK_DIR/hist" "${filter_arg[@]}"
fi

# run_max_precise resumes on its own: it skips any table already written to
# --output-dir, so an interrupted step 4 picks up where it left off.
echo ">>> [4/5] max-precise (ideal outputs)"
python3 -m synth_xfer.llvm_eval.run_max_precise \
    "$WORK_DIR/hist" --output-dir "$WORK_DIR/tables" "${table_timeout_arg[@]}"

if have_tsv "$WORK_DIR/pruned"; then
    echo ">>> [5/5] pruned tables present in $WORK_DIR/pruned, skipping (RESUME=1)"
else
    echo ">>> [5/5] prune tables"
    python3 -m synth_xfer.llvm_eval.prune_tables \
        --tsv-dir "$WORK_DIR/tables" --out-dir "$WORK_DIR/pruned"
fi

echo ">>> done. pruned tables in $WORK_DIR/pruned (pass as TABLE_DIR to phase2_eval.sh)"
