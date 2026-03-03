<!-- Comments
Comments -->

## Task

Implement a KnownBits transfer function for operation `<OP>` in this repo

## Key Clarification

- CI integration is NOT required for this task.
- The important tools are `verify` and `eval-final`.
- The width list below is a suggestion only; choose widths freely to maximize useful signal.

## Reasoning (before implementing)

- Reason about the operation semantics and how KnownBits (known-zero, known-one) should be updated for each output before writing MLIR.
- Aim for **sound** and **precise** transfers; prefer a well-reasoned design over the first implementation that passes eval.
- If a candidate gets low metrics or errors, analyze why (e.g. wrong propagation, missing cases) and improve the design, not only fix syntax.

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

4. Transfer must be sound and as precise as possible.

5. Keep code bitwidth-agnostic:
   - no special cases for specific bitwidths (e.g., no "if bw==…" logic).

6. Use existing primitive included in `ops.md`, which aligned with the LLVM APInt semantics.

7. The program should be in SSA (Single Static Assigment) form. **Each line only has 1 operation** from `ops.md`. Do not write `%x = %y` (that is invalid MLIR); every definition must be an operation call; use SSA values directly in the next operation or in `transfer.make`.
