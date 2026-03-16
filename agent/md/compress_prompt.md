## Task: Compress MLIR code using a provided library

You are given an MLIR transfer function to compress. Your goal is to replace inline sub-computations with calls to library helper functions, reducing the size of the code without changing its behavior.

Use tools to fetch all materials; do not assume they are in this message:
- `get_target_file()`: the MLIR transfer function to compress
- `get_library_text()`: the available helper functions you may call
- `get_available_primitives()`: the allowed primitive operators
- `verify_correctness(mlir)`: confirm your compressed version is semantically equivalent

## Rules

1. **Preserve semantics exactly.** The compressed function must produce identical results to the original for all valid inputs. If no compression is possible without changing behavior, output the original function unchanged.
2. **Only use provided library functions.** Do not introduce new helper functions, inline new abstractions, or reference functions not present in the library.
3. **Replace, do not restructure.** Substitute matching sub-computations with library calls. Do not reorder operations, merge unrelated sequences, or otherwise refactor beyond what the substitution requires.
4. **Match sub-computations precisely.** A library function may replace a sequence of operations only if the sequence computes exactly the same value under the same semantics as the library function body. Partial matches are not valid substitutions.
5. **Maintain valid SSA form.** All SSA values must be defined before use. Update value names as needed after substitution.
6. **Do not compress if it changes behavior.** If there is any doubt about whether a substitution is semantically equivalent, do not make it.

## Required workflow

1. Call `get_target_file()` to read the transfer function to compress.
2. Call `get_library_text()` to see what helper functions are available.
3. For each library function, check whether any sub-sequence in the target computes the same result with the same operands.
4. For each valid match, replace the sub-sequence with a call to the library function, threading the result SSA value through the rest of the function.
5. Call `verify_correctness(mlir)` with your compressed function to confirm it is semantically equivalent to the original.
6. If correctness check fails, revise your substitutions and re-verify before outputting.
7. Output the compressed function as plaintext MLIR — no explanation, no markdown fences, no module wrapper unless the original had one.
