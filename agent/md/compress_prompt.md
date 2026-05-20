Compress the target transfer function by replacing sub-computations with library calls.

- Call `get_target_file()`, fetch the library, find exact sub-sequence matches, then verify correctness.
- Return only the compressed MLIR as plaintext — no explanation, no markdown fences.
