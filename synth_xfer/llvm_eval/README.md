# llvm_eval pipeline

Measure and improve LLVM KnownBits transfer functions on real code. Two passes
over the benchmark suite: first wire in **stub** transformers to harvest the
real-world inputs each pattern is queried with (a histogram), then wire in
**lookup-table** transformers built from the SMT-optimal output for those
inputs and measure the optimization stats.

Run from the `synth-xfer` repo root inside the venv.

## Pipeline
1. Generate stub transformers (returning top) and wire them into opt.
2. Rebuild opt.
3. Run the benchmark to collect a per-pattern histogram of the abstract inputs each pattern is matched with.
4. Fill in the SMT-optimal (max-precise) output for every histogram row.
5. Prune the tables (drop top/bottom/subsumed rows).
6. Generate table-backed transformers from the pruned tables and wire them into opt.
7. Run the benchmark again to collect optimization stats.

## Quick start

Two wrapper scripts cover the pipeline. Phase 1 (steps 1-5) produces pruned
lookup tables in `TABLE_DIR`; phase 2 (steps 6-7) consumes them and writes the
optimization stats to `STATS`.

`LLVM_DIR` and `BENCH_DIR` are required for both

```bash
export LLVM_DIR=~/path/to/llvm-project
export BENCH_DIR=~/path/to/llvm-opt-benchmark

# steps 1-5: histogram -> max-precise -> pruned tables (-> TABLE_DIR)
PAT_LIST=tests/data/pattern/top_10_pattern.tsv \
TABLE_DIR=outputs/pruned \
    ./synth_xfer/llvm_eval/phase1_build_tables.sh

# steps 6-7: table-backed transformers -> stats (-> STATS)
TABLE_DIR=outputs/pruned STATS=outputs/stats.json \
    ./synth_xfer/llvm_eval/phase2_eval.sh
```

`FILTER` restricts the benchmark to one subdir; empty (the default) runs the
whole suite — set e.g. `FILTER=cvc5` for a quick run.

## Commands

To run the steps by hand instead of via the scripts. Set the paths once:

```bash
LLVM_DIR=~/path/to/llvm-project
BENCH_DIR=~/path/to/llvm-opt-benchmark
OPT=$LLVM_DIR/build/bin/opt
```

```bash
# 1. stub transformers -> dispatcher
python3 -m synth_xfer.llvm_eval.build_xfer \
    --pat-list llvm_results/top_10_pattern.tsv \
    --output-dir outputs/test_pat/xfer \
    -d KnownBits
python3 -m synth_xfer.llvm_eval.generate_matcher \
    --input-dir outputs/test_pat/xfer \
    --llvm-dir $LLVM_DIR

# 2. rebuild opt
ninja -C $LLVM_DIR/build opt

# 3. benchmark -> per-pattern histogram
python3 -m synth_xfer.llvm_eval.run_opt_benchmark \
    --bench-path $BENCH_DIR \
    --opt-path $OPT \
    --pattern-hist outputs/test_pat/hist

# 4. fill SMT-optimal output (max-precise)
python3 -m synth_xfer.llvm_eval.run_max_precise \
    outputs/test_pat/hist \
    --output-dir outputs/test_pat/tables

# 5. prune the tables
python3 -m synth_xfer.llvm_eval.prune_tables \
    --tsv-dir outputs/test_pat/tables \
    --out-dir outputs/test_pat/pruned

# 6. table-backed transformers -> dispatcher (--include-helper needed for blobs) -> rebuild
python3 -m synth_xfer.llvm_eval.build_xfer \
    --table-dir outputs/test_pat/pruned \
    --output-dir outputs/test_pat/xfer
python3 -m synth_xfer.llvm_eval.generate_matcher \
    --input-dir outputs/test_pat/xfer \
    --llvm-dir $LLVM_DIR \
    --include-helper
ninja -C $LLVM_DIR/build opt

# 7. benchmark -> optimization stats
python3 -m synth_xfer.llvm_eval.run_opt_benchmark \
    --bench-path $BENCH_DIR \
    --opt-path $OPT \
    --stats outputs/test_stats.json
```
