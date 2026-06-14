#!/usr/bin/env bash
# Pipeline steps 6-7: build table-backed transformers from the pruned tables
# produced by phase1_build_tables.sh, wire them into opt, rebuild, and run the
# benchmark to collect optimization stats.
#
# Deliverable: the stats JSON at STATS.
#
# Run from the synth-xfer repo root, inside the venv. LLVM_DIR and BENCH_DIR are
# required; the rest have defaults. Point TABLE_DIR at phase 1's output. e.g.
#   LLVM_DIR=~/repos/llvm-project BENCH_DIR=~/repos/llvm-opt-benchmark \
#       TABLE_DIR=outputs/run1/tables STATS=outputs/run1/stats.json ./phase2_eval.sh
#
#   LLVM_DIR    LLVM checkout with build/bin/opt   (required)
#   BENCH_DIR   llvm-opt-benchmark checkout        (required)
#   TABLE_DIR   pruned tables from phase 1         (default outputs/pruned)
#   STATS       where the stats JSON goes          (default outputs/stats.json)
#   FILTER      benchmark subdir filter, "" = all  (default "" = whole suite)
set -euo pipefail

: "${LLVM_DIR:?must be set to the llvm-project checkout (with build/bin/opt)}"
: "${BENCH_DIR:?must be set to the llvm-opt-benchmark checkout}"
TABLE_DIR="${TABLE_DIR:-outputs/pruned}"
STATS="${STATS:-outputs/stats.json}"
FILTER="${FILTER:-}"

OPT="$LLVM_DIR/build/bin/opt"
filter_arg=()
[[ -n "$FILTER" ]] && filter_arg=(--filter "$FILTER")

mkdir -p "$(dirname "$STATS")"

echo ">>> [1/3] table transformers -> dispatcher (--include-helper)"
python3 -m synth_xfer.llvm_eval.generate_xfers tables \
    --table-dir "$TABLE_DIR" --llvm-dir "$LLVM_DIR"

echo ">>> [2/3] rebuild opt"
ninja -C "$LLVM_DIR/build" opt

echo ">>> [3/3] benchmark -> stats"
python3 -m synth_xfer.llvm_eval.run_opt_benchmark \
    --bench-path "$BENCH_DIR" --opt-path "$OPT" \
    --stats "$STATS" "${filter_arg[@]}"

echo ">>> done. stats in $STATS"
