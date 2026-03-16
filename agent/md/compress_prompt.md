## Task: Compress MLIR code using a provided library

You are given a library of named MLIR helper functions and an MLIR function to compress. Your goal is to replace inline sub-computations in the target function with calls to the appropriate library helpers, reducing the size of the code without changing its behavior.

## Library functions

The following helper functions are available for use. You may call any of them from within the target function:

```mlir
<LIBRARY>
```

## Target function to compress

```mlir
<TARGET>
```

## Rules

1. **Preserve semantics exactly.** The compressed function must produce identical results to the original for all valid inputs. If no compression is possible without changing behavior, output the original function unchanged.
2. **Only use provided library functions.** Do not introduce new helper functions, inline new abstractions, or reference functions not present in the library above.
3. **Replace, do not restructure.** Substitute matching sub-computations with library calls. Do not reorder operations, merge unrelated sequences, or otherwise refactor beyond what the substitution requires.
4. **Match sub-computations precisely.** A library function may replace a sequence of operations only if the sequence computes exactly the same value under the same semantics as the library function body. Partial matches are not valid substitutions.
5. **Maintain valid SSA form.** All SSA values must be defined before use. Update value names as needed after substitution.
6. **Do not compress if it changes behavior.** If there is any doubt about whether a substitution is semantically equivalent, do not make it.

## Required workflow

1. Read the target function carefully and identify all sub-sequences of operations.
2. For each library function, check whether any sub-sequence in the target computes the same result with the same operands.
3. For each valid match, replace the sub-sequence with a call to the library function, threading the result SSA value through the rest of the function.
4. Verify the final function is in valid SSA form and is semantically equivalent to the original.
5. Output the compressed function as plaintext MLIR — no explanation, no markdown fences, no module wrapper unless the original had one.
