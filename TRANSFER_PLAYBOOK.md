# Transfer Function Playbook (`<DOMAIN>`, `<OP>`)

Implement or improve one transfer function in this repo.

## Scope Per Task (Hard Rule)

- Work on exactly one abstract domain and one operation at a time.
- Allowed domains: `KnownBits`, `UConstRange` (unsigned constant range), `SConstRange` (signed constant range).
- If asked to handle multiple domains or multiple ops, split that into separate tasks and run this playbook once per `(domain, op)` pair.

## Key Clarifications

- CI integration is not required for this task.
- Primary tools are `verify` and `final-eval`.
- `final-eval` must always use: `--exact-bw 8,1000 --norm-bw 64,10000,1000`.
- Width lists are suggestions only; choose widths that maximize useful signal.
- You may optionally suggest concrete missing `transfer` dialect integer ops that would enable better precision or efficiency.

## Shared Requirements

1. Use this exact transfer function signature:

```mlir
(!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
```

2. Transfer must be sound and as precise as possible.
3. Keep code bitwidth-agnostic.
4. Keep solver timeout at or below `120` seconds.
5. Keep changes minimal and repo-consistent.
6. Reuse existing transfer primitives whenever possible.

## SSA IR Discipline (Important)

- This MLIR parser uses strict SSA form: each `%name = ...` must be an operation result.
- Do not write alias assignments like `%x = %y : !transfer.integer`.
- If you need another reference, reuse the original SSA value directly.
- After drafting a transfer file, run a quick single-width `verify` first to catch parser/syntax issues, then run broader widths.

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

KnownBits:

```bash
verify --xfer-file tests/data/kb_<op>.mlir --bw <chosen-widths> --timeout 60 --domain KnownBits --op mlir/Operations/<Op>.mlir
final-eval tests/data/kb_<op>.mlir --domain KnownBits --op mlir/Operations/<Op>.mlir --exact-bw 8,1000 --norm-bw 64,10000,1000
```

Unsigned ConstantRange (`UConstRange`):

```bash
verify --xfer-file tests/data/ucr_<op>.mlir --bw <chosen-widths> --timeout 60 --domain UConstRange --op mlir/Operations/<Op>.mlir
final-eval tests/data/ucr_<op>.mlir --domain UConstRange --op mlir/Operations/<Op>.mlir --exact-bw 8,1000 --norm-bw 64,10000,1000
```

Signed ConstantRange (`SConstRange`):

```bash
verify --xfer-file tests/data/scr_<op>.mlir --bw <chosen-widths> --timeout 60 --domain SConstRange --op mlir/Operations/<Op>.mlir
final-eval tests/data/scr_<op>.mlir --domain SConstRange --op mlir/Operations/<Op>.mlir --exact-bw 8,1000 --norm-bw 64,10000,1000
```

## Testing Guidance

- Use `verify` as the soundness oracle.
- Use `final-eval` as the precision/quality metric.
- Suggested widths include `4, 8, 16, 24, 32, 40, 48, 56, 64`, but choose as needed.
- Prefer separate width runs (parallel if convenient) so one slow width does not block all results.

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
3. `final-eval` table values (run with `--exact-bw 8,1000 --norm-bw 64,10000,1000`).
4. Precision and soundness caveats, clearly separating `timeout/unresolved` from `unsound`.
