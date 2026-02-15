# Transfer Function Playbook (`<DOMAIN>`, `<OP>`)

Implement or improve one transfer function in this repo.

## Scope Per Task (Hard Rule)

- Work on exactly one abstract domain and one operation at a time.
- Allowed domains: `KnownBits`, `UConstRange` (unsigned constant range), `SConstRange` (signed constant range).
- If asked to handle multiple domains or multiple ops, split that into separate tasks and run this playbook once per `(domain, op)` pair.

## Key Clarifications

- CI integration is not required for this task.
- Primary tools are `verify-upto` and `eval-final`.
- `eval-final` must always use: `--exact-bw 8,1000 --norm-bw 64,10000,1000`.
- For `verify-upto`, always use `--bw 64`.
- `verify-upto` accepts the same `--bw` syntax as `verify`, but it uses the maximum provided value as the upper bound it checks (`1..max_bw`).
- To reduce runtime during intermediate checks, lower `--timeout` instead of lowering `--bw`.
- You may optionally suggest concrete missing `transfer` dialect integer ops that would enable better precision or efficiency.

## Placeholder Conventions

- `<DOMAIN>`: one of `KnownBits`, `UConstRange`, `SConstRange`.
- `<OP>`: concrete op filename stem in `mlir/Operations` (case-sensitive), e.g. `Shl`.
- `<op>`: lowercase stem used in transfer filenames under `tests/data`, e.g. `shl`.

## Tool Bug Policy (Required)

- If you hit a bug in any tool in this repository (for example `verify-upto`, `eval-final`, `sxf`, lowering, or parsing), stop normal transfer-function work immediately.
- Report the bug clearly to the user first (minimal reproducer command, observed behavior, traceback/signature, and any relevant output paths/log files).
- Do not attempt a workaround by default.
- Mining logs/artifacts from the failed run is allowed, but only after the bug has been reported to the user.
- Only proceed with a workaround if the user explicitly asks for one after the bug report.
- If a workaround is requested, keep it scoped and temporary, and clearly label which results were obtained under workaround conditions.

## Shared Requirements

1. Use this exact transfer function signature:

```mlir
(!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
```

2. Transfer must be sound and as precise as possible.
3. Keep code bitwidth-agnostic.
4. Keep solver timeout at or below `120` seconds. It is fine to use lower timeouts to quickly ascertain the soundness of intermediate or partial transfer functions, but use `--timeout 120` for your final reported `verify-upto` run.
5. Keep changes minimal and repo-consistent.
6. Reuse existing transfer primitives whenever possible.

## Construction Strategy (Recommended)

- Prefer composing the final transfer as the meet of several simpler transfer functions, each capturing one sound insight.
- Keep each candidate independently sound; the meet of sound candidates is also sound.
- Typical candidates include:
  - exact special cases (`lhs == 0`, `rhs == 0`, both operands constant),
  - validity/feasibility filters (e.g., whether the op constraints allow any concrete pair in-range),
  - monotonic endpoint bounds valid under explicit guards (sign-partitioned or no-overflow conditions).
- When encoding a meet in-range domains, use domain-consistent intersection logic (e.g., lower via `smax`/`umax`, upper via `smin`/`umin` as appropriate).

## Optional Idea Mining with `sxf` (5-minute Budget)

- If progress stalls, use `sxf` to generate ideas, not final code.
- Cap runtime to about 5 minutes:

```bash
timeout 300 sxf mlir/Operations/<OP>.mlir \
  -o /tmp/<DOMAIN>_<OP>_ideas \
  -d <DOMAIN> \
  --num-iters 1 \
  --num-steps 600 \
  --num-mcmc 80 \
  --program-length 40 \
  --condition-length 12 \
  --num-abd-procs 0 \
  --num-unsound-candidates 0 \
  --vbw 1-16 \
  --random-seed <seed>
```

- To get the most from this command:
  - If `timeout` is unavailable on your system, use `gtimeout` with the same arguments.
  - Run 2-3 different seeds and compare recurring patterns.
  - Keep `--num-iters 1`; in this workflow you want candidate ideas quickly, not a full synthesis run.
  - Use moderate `--num-steps`/`--num-mcmc` (for example, `400-1200` and `60-120`) to trade breadth vs. depth.
  - Inspect `/tmp/<DOMAIN>_<OP>_ideas/info.log` and `/tmp/<DOMAIN>_<OP>_ideas/debug.log` for high-precision partial candidates and reusable guard patterns.
  - Treat mined snippets as hypotheses: manually simplify, convert to meet-style sub-transfers, then re-check with `verify-upto`.
  - If `sxf` fails or times out, partial logs can still be useful for extracting ideas.
  - If the failure appears to be a tool bug, first report the bug per the Tool Bug Policy, then mine the failed-run logs.

## SSA IR Discipline (Important)

- This MLIR parser uses strict SSA form: each `%name = ...` must be an operation result.
- Do not write alias assignments like `%x = %y : !transfer.integer`.
- If you need another reference, reuse the original SSA value directly.
- After drafting a transfer file, run a quick timeout-limited `verify-upto` first (still with `--bw 64`) to catch parser/syntax issues, then run your final `--timeout 120` check.

## Domain-Specific Mapping

Choose one row only for a given task.

| Domain | File | Symbol | Encoding |
|---|---|---|---|
| `KnownBits` | `tests/data/kb_<op>.mlir` | `kb_<op>` | index `0` = known-zero mask, index `1` = known-one mask |
| `UConstRange` | `tests/data/ucr_<op>.mlir` | `ucr_<op>` | index `0` = lower bound, index `1` = upper bound |
| `SConstRange` | `tests/data/scr_<op>.mlir` | `scr_<op>` | index `0` = lower bound, index `1` = upper bound |

## Domain-Specific Primitive Guidance

- `KnownBits`: prefer `transfer.and`, `transfer.or`, `transfer.xor`, `transfer.add`, `transfer.sub`, `transfer.shl`, `transfer.lshr`, `transfer.constant`, `transfer.get_all_ones`.
- `UConstRange` and `SConstRange`: same as above, plus `transfer.cmp`, `transfer.select`, `transfer.uadd_overflow` when useful.

## Command Templates

Run only the commands for your chosen domain.
Optional `sxf` idea-mining above is still allowed and does not conflict with this rule.

KnownBits:

```bash
verify-upto --xfer-file tests/data/kb_<op>.mlir --bw 64 --timeout 120 --domain KnownBits --op mlir/Operations/<OP>.mlir
eval-final tests/data/kb_<op>.mlir --domain KnownBits --op mlir/Operations/<OP>.mlir --exact-bw 8,1000 --norm-bw 64,10000,1000
```

Unsigned ConstantRange (`UConstRange`):

```bash
verify-upto --xfer-file tests/data/ucr_<op>.mlir --bw 64 --timeout 120 --domain UConstRange --op mlir/Operations/<OP>.mlir
eval-final tests/data/ucr_<op>.mlir --domain UConstRange --op mlir/Operations/<OP>.mlir --exact-bw 8,1000 --norm-bw 64,10000,1000
```

Signed ConstantRange (`SConstRange`):

```bash
verify-upto --xfer-file tests/data/scr_<op>.mlir --bw 64 --timeout 120 --domain SConstRange --op mlir/Operations/<OP>.mlir
eval-final tests/data/scr_<op>.mlir --domain SConstRange --op mlir/Operations/<OP>.mlir --exact-bw 8,1000 --norm-bw 64,10000,1000
```

## Testing Guidance

- Use `verify-upto` as the soundness oracle.
- `verify-upto` uses the same core arguments as `verify`, checks bitwidths from `1` up to the requested max width, and stops early on the first `timeout`.
- Use `eval-final` as the precision/quality metric.
- Always use `--bw 64` for `verify-upto`.
- For faster intermediate feedback, lower `--timeout` (never lower `--bw`).
- For final reporting, use `--timeout 120`.

## Optional Test File Updates (Only If Asked)

KnownBits:
- `tests/test_verif.py`: `test_verif_kb_<op>()`
- `tests/test_jit.py`: `test_jit_with_kb_<op>()`

UConstRange:
- `tests/test_verif.py`: `test_verif_ucr_<op>()`
- `tests/test_jit.py`: `test_jit_with_ucr_<op>()`

SConstRange:
- `tests/test_verif.py`: `test_verif_scr_<op>()` (if present/needed)
- `tests/test_jit.py`: `test_jit_with_scr_<op>()` (if present/needed)

## Required Return Format

1. Files changed.
2. Soundness results per tested bitwidth (`sound` / `unsound` / `timeout` plus runtime).
3. `eval-final` table values (run with `--exact-bw 8,1000 --norm-bw 64,10000,1000`).
4. Precision and soundness caveats, clearly separating `timeout/unresolved` from `unsound`.
