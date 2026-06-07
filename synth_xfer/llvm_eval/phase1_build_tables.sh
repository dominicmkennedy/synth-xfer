#!/usr/bin/env bash
# Pipeline steps 1-5: build stub transformers, harvest a per-pattern histogram
# from the benchmark, fill in SMT-optimal (max-precise) outputs, and prune.
#
# Deliverable: the pruned lookup tables in TABLE_DIR (input to phase2_eval.sh).
# All other intermediates (transformer .inc, histograms, ideal tables) go to a
# temp dir that is removed on exit.
#
# Run from the synth-xfer repo root, inside the venv. LLVM_DIR, BENCH_DIR and
# PAT_LIST are required; the rest have defaults. e.g.
#   LLVM_DIR=~/repos/llvm-project BENCH_DIR=~/repos/llvm-opt-benchmark \
#       PAT_LIST=tests/data/pattern/top_10_pattern.tsv \
#       TABLE_DIR=outputs/run1/tables ./phase1_build_tables.sh
#
#   LLVM_DIR    LLVM checkout with build/bin/opt   (required)
#   BENCH_DIR   llvm-opt-benchmark checkout        (required)
#   PAT_LIST    TSV with a `pattern` column        (required)
#   TABLE_DIR   where the pruned tables go         (default outputs/pruned)
#   FILTER      benchmark subdir filter, "" = all  (default "" = whole suite)
set -euo pipefail

: "${LLVM_DIR:?must be set to the llvm-project checkout (with build/bin/opt)}"
: "${BENCH_DIR:?must be set to the llvm-opt-benchmark checkout}"
: "${PAT_LIST:?must be set to a TSV with a \`pattern\` column}"
TABLE_DIR="${TABLE_DIR:-outputs/pruned}"
FILTER="${FILTER:-}"

OPT="$LLVM_DIR/build/bin/opt"
filter_arg=()
[[ -n "$FILTER" ]] && filter_arg=(--filter "$FILTER")

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo ">>> [1/5] stub transformers -> dispatcher"
python3 -m synth_xfer.llvm_eval.build_xfer \
    --pat-list "$PAT_LIST" --output-dir "$TMP/xfer" -d KnownBits
python3 -m synth_xfer.llvm_eval.generate_matcher \
    --input-dir "$TMP/xfer" --llvm-dir "$LLVM_DIR"

echo ">>> [2/5] rebuild opt"
ninja -C "$LLVM_DIR/build" opt

echo ">>> [3/5] benchmark -> histogram"
python3 -m synth_xfer.llvm_eval.run_opt_benchmark \
    --bench-path "$BENCH_DIR" --opt-path "$OPT" \
    --pattern-hist "$TMP/hist" "${filter_arg[@]}"

echo ">>> [4/5] max-precise (ideal outputs)"
python3 -m synth_xfer.llvm_eval.run_max_precise \
    "$TMP/hist" --output-dir "$TMP/tables"

echo ">>> [5/5] prune tables"
python3 -m synth_xfer.llvm_eval.prune_tables \
    --tsv-dir "$TMP/tables" --out-dir "$TABLE_DIR"

echo ">>> done. pruned tables in $TABLE_DIR (pass as TABLE_DIR to phase2_eval.sh)"
