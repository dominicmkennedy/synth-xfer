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
set -euo pipefail

: "${LLVM_DIR:?must be set to the llvm-project checkout (with build/bin/opt)}"
: "${BENCH_DIR:?must be set to the llvm-opt-benchmark checkout}"
: "${PAT_LIST:?must be set to a TSV with a \`pattern\` column}"
WORK_DIR="${WORK_DIR:-outputs/run}"
FILTER="${FILTER:-}"
FILES="${FILES:-}"

OPT="$LLVM_DIR/build/bin/opt"
filter_arg=()
[[ -n "$FILTER" ]] && filter_arg+=(--filter "$FILTER")
[[ -n "$FILES" ]] && filter_arg+=(--filter-file "$FILES")

mkdir -p "$WORK_DIR"

echo ">>> [1/5] stub transformers -> dispatcher"
python3 -m synth_xfer.llvm_eval.generate_xfers stubs \
    --patterns "$PAT_LIST" -d KnownBits --llvm-dir "$LLVM_DIR"

echo ">>> [2/5] rebuild opt"
ninja -C "$LLVM_DIR/build" opt

echo ">>> [3/5] benchmark -> histogram"
python3 -m synth_xfer.llvm_eval.run_opt_benchmark \
    --bench-path "$BENCH_DIR" --opt-path "$OPT" \
    --pattern-hist "$WORK_DIR/hist" "${filter_arg[@]}"

echo ">>> [4/5] max-precise (ideal outputs)"
python3 -m synth_xfer.llvm_eval.run_max_precise \
    "$WORK_DIR/hist" --output-dir "$WORK_DIR/tables"

echo ">>> [5/5] prune tables"
python3 -m synth_xfer.llvm_eval.prune_tables \
    --tsv-dir "$WORK_DIR/tables" --out-dir "$WORK_DIR/pruned"

echo ">>> done. pruned tables in $WORK_DIR/pruned (pass as TABLE_DIR to phase2_eval.sh)"
