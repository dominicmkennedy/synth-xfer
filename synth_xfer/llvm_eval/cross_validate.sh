#!/usr/bin/env bash
# K-fold cross-validation over llvm-opt-benchmark.
#
# Folds are size-balanced (cv_split.py). For each fold: train (phase 1) on the
# other folds -> lookup tables, then eval (phase 2) on the held-out fold ->
# stats.json. Folds run sequentially (they share one opt build / Generated tree).
#
# Run from the synth-xfer repo root, inside the venv. Required env vars:
#   LLVM_DIR    LLVM checkout with build/bin/opt
#   BENCH_DIR   llvm-opt-benchmark checkout
#   PAT_LIST    TSV with a `pattern` column
# Optional:
#   CV_DIR      results root                                 (default outputs/cv)
#   K           number of folds                              (default 10)
#   SUBSET      comma-separated dir names to restrict CV to  (default whole suite)
#
# Per-fold outputs: CV_DIR/fold_<i>/{dirs.txt, tables/, stats.json}
set -euo pipefail

: "${LLVM_DIR:?must be set to the llvm-project checkout (with build/bin/opt)}"
: "${BENCH_DIR:?must be set to the llvm-opt-benchmark checkout}"
: "${PAT_LIST:?must be set to a TSV with a \`pattern\` column}"
export LLVM_DIR BENCH_DIR PAT_LIST
CV_DIR="${CV_DIR:-outputs/cv}"
K="${K:-10}"
SUBSET="${SUBSET:-}"

here="$(cd "$(dirname "$0")" && pwd)"
include_arg=()
[[ -n "$SUBSET" ]] && include_arg=(--include "$SUBSET")

echo ">>> splitting into $K size-balanced folds under $CV_DIR"
python3 -m synth_xfer.llvm_eval.cv_split \
    --bench-path "$BENCH_DIR" --k "$K" --out-dir "$CV_DIR" "${include_arg[@]}"

for ((k = 0; k < K; k++)); do
    held="$(paste -sd, "$CV_DIR/fold_$k/dirs.txt")"
    train=""
    for ((j = 0; j < K; j++)); do
        [[ $j -eq $k ]] && continue
        train+=",$(paste -sd, "$CV_DIR/fold_$j/dirs.txt")"
    done
    train="${train#,}"

    echo
    echo "############ fold $k / $((K - 1)) ############"
    echo ">>> train (phase 1) on folds != $k"
    TABLE_DIR="$CV_DIR/fold_$k/tables" FILTER="$train" \
        "$here/phase1_build_tables.sh"

    echo ">>> eval (phase 2) on held-out fold $k"
    TABLE_DIR="$CV_DIR/fold_$k/tables" STATS="$CV_DIR/fold_$k/stats.json" FILTER="$held" \
        "$here/phase2_eval.sh"
done

echo
echo ">>> cross-validation done. per-fold stats:"
for ((k = 0; k < K; k++)); do
    echo "  fold $k: $CV_DIR/fold_$k/stats.json"
done
