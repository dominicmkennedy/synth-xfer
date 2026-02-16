<!-- Comments
Comments -->

## Task

Implement or improve a KnownBits transfer function for operation `<OP>` in this repo

## Key Clarification

- CI integration is NOT required for this task.
- The important tools are `verify` and `eval-final`.
- The width list below is a suggestion only; choose widths freely to maximize useful signal.

## Requirements

1. Implement `kb_<op>.mlir` in the same MLIR style as the examples I provided to you.
2. Function signature must be:
   ```
   (!transfer.abs_value<[!transfer.integer, !transfer.integer]>, !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.abs_value<[!transfer.integer, !transfer.integer]>
   ```
   with symbol name `kb_<op>`.

3. KnownBits encoding:
   - index 0 = known-zero mask
   - index 1 = known-one mask

4. Transfer must be **sound** and as **precise** as possible.

5. Keep code bitwidth-agnostic:
   - no special cases for specific bitwidths (e.g., no "if bw==…" logic).

6. Use existing primitive (`transfer.and`,  `transfer.add`, `transfer.sub`, `transfer.shl`, `transfer.lshr`, `transfer.constant`, `transfer.get_all_ones`, etc.) included in `ops.md`, which aligned with the LLVM APInt semantics.

7. The program should be in SSA (Single Static Assigment) form. **Each line only has 1 operation** in `ops.md`.

<!-- ## Testing Guidance

- Use `verify` as the soundness oracle.
- Use `eval-final` as the precision/quality metric.
- You may choose any widths (examples: 4,8,16,24,32,40,48). The list is not mandatory.
- Prefer testing widths separately (and in parallel if convenient) so one slow width does not block all results.

## Commands Template

- `verify --xfer-file tests/data/kb_<op>.mlir --bw <chosen-widths> --timeout 60 --domain KnownBits --op mlir/Operations/<Op>.mlir`
- `eval-final tests/data/kb_<op>.mlir --domain KnownBits --op mlir/Operations/<Op>.mlir` -->
