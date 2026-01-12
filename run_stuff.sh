#!/usr/bin/env bash
set -euo pipefail

OPS=(
  Abds
  Add
#   Mul
#   Sub
#   SshlSat
  Udiv
#   Umax
#   Shl
#   AvgFloorU
#   Smin
#   UaddSat
  Modu
#   SubNuw
)

# Max concurrent seeds
MAX_JOBS=8

# Seed range
SEED_START=1
# since 48 / 8 is nice 
SEED_END=48

# Common sxf args for 64-bit experiment
DOMAIN="KnownBits"
NUM_ITERS=1
TOTAL_ROUNDS=300
VBW=64
HBW="64,5000,10000"
MBW="8,5000"
LBW_FLAG="-lbw"

########################################
# Helpers
########################################

wait_for_slot() {
    while :; do
        njobs=$(jobs -p | wc -l | tr -d '[:space:]')
        if [ "$njobs" -lt "$MAX_JOBS" ]; then
            break
        fi
        wait || true
    done
}

run_mode_for_op() {
    local op="$1"
    local mode="$2"  # baseline_64 | mab_64 logically

    local op_lc
    op_lc=$(printf "%s" "$op" | tr '[:upper:]' '[:lower:]')

    local mode_flag=""
    local out_root="results/${mode}/${op_lc}"

    if [[ "$mode" == "baseline_64" ]]; then
        mode_flag=""
    elif [[ "$mode" == "mab_64" ]]; then
        mode_flag="-mab op"
    elif [[ "$mode" == "mab_subsets_64" ]]; then
        mode_flag="-mab subs"
    else
        echo "Unknown mode: $mode" >&2
        exit 1
    fi

    mkdir -p "$out_root"

    echo "=== Running $mode for $op (seeds ${SEED_START}..${SEED_END}) ==="

    #
    # Launch seeds
    #
    local start_time=$(date +%s)
    for ((seed=SEED_START; seed<=SEED_END; seed++)); do
        wait_for_slot

        seed_dir="${out_root}/seed_${seed}"
        mkdir -p "$seed_dir"

        out_file="${seed_dir}/run.log"

        echo "  -> ${mode}, ${op}, seed ${seed}"

        sxf "mlir/Operations/${op}.mlir" \
            -o "${seed_dir}" \
            -random_seed "${seed}" \
            -domain "${DOMAIN}" \
            -num_iters "${NUM_ITERS}" \
            -total_rounds "${TOTAL_ROUNDS}" \
            ${mode_flag} \
            -vbw "${VBW}" \
            -hbw "${HBW}" \
            -mbw "${MBW}" \
            ${LBW_FLAG} \
            > "${out_file}" 2>&1 &
    done

    wait || true
    local end_time=$(date +%s)
    local elapsed_time=$((end_time - start_time))
    local elapsed_minutes=$((elapsed_time / 60))
    local elapsed_seconds=$((elapsed_time % 60))

    #
    # Build compact summary
    #
    local summary_file="${out_root}/all_seeds.txt"
    local label="${mode}_output"

    echo "=== Building summary for ${mode} / ${op} ==="
    echo "# Total time: ${elapsed_minutes}m ${elapsed_seconds}s (${elapsed_time}s)" > "${summary_file}"
    echo "# seed ${label}" >> "${summary_file}"

    for ((seed=SEED_START; seed<=SEED_END; seed++)); do
        seed_dir="${out_root}/seed_${seed}"
        run_log="${seed_dir}/run.log"

        if [ ! -f "$run_log" ]; then
            echo "${seed}  [missing run.log]" >> "$summary_file"
            continue
        fi

        final_line=$(grep 'Final Soln' "$run_log" | tail -n 1 || true)

        if [ -z "$final_line" ]; then
            final_line="Final Soln   | Exact NA | NA solutions |  # no final solution"
        fi

        echo "${seed}  ${final_line}" >> "$summary_file"
    done
}

########################################
# Main
########################################

for op in "${OPS[@]}"; do
    run_mode_for_op "$op" "baseline_64"
    run_mode_for_op "$op" "mab_64"
    run_mode_for_op "$op" "mab_subsets_64"
done

echo "All done."
