## Task: Extract a reusable library from KnownBits transfer functions

You are given a set of synthesized KnownBits transfer functions. Your goal is to identify reusable sub-computations across them and factor these out as named helper functions in a library module.

Use tools to fetch all materials; do not assume they are in this message:
- `get_corpus_functions()`: the synthesized transfer functions to learn from
- `get_available_primitives()`: the allowed primitive operators
- `get_library_text()`: the existing library (do not duplicate functions already present)

## Background: KnownBits representation

Each abstract value is a 2-element container `!transfer.abs_value<[!transfer.integer, !transfer.integer]>`:
- element **0**: known-zero mask — a bit set here means that bit is definitely 0
- element **1**: known-one mask — a bit set here means that bit is definitely 1

The complement of known-zero gives the "maybe-one" mask; the complement of known-one gives the "maybe-zero" mask.

## What to extract

A good library function:
1. **Encodes a meaningful semantic concept** — e.g., "extract the maybe-zero mask", "compute the carry-propagate bits", "get the minimum possible concrete value of a KnownBits". Prefer names that describe what the function *means*, not how it is computed.
2. **Appears across multiple transfer functions**, or is a large, self-contained sub-computation that would reduce duplication if future transfer functions were refactored to use it.
3. **Is non-trivial** — it should be at least 3 operations long. Do not extract single-op wrappers.
4. **Is general** — parameters should be abstract values or integers; do not hard-code bitwidth-specific constants unless the concept is inherently about a specific constant.

Do **not** extract the transfer functions themselves (e.g. `@kb_add`). Only extract helper functions that could be called from within transfer functions.

## Output format

Return a JSON object with a `functions` array. Each element has three fields:

- `function_name` — `snake_case` name matching the `@name` in the MLIR (e.g., `"maybe_zero"`)
- `docstring` — one sentence describing what the function computes semantically (e.g., `"Returns the mask of bits that might be 0: complement of known-one."`)
- `source` — the complete `func.func` definition in valid MLIR, using SSA form, one allowed operation per line, with arguments typed as `!transfer.integer` or `!transfer.abs_value<[!transfer.integer, !transfer.integer]>` as appropriate. The first line inside the function body must be a `//` comment containing the docstring verbatim.

Example output shape (illustrative, do not copy verbatim):

```json
{
  "functions": [
    {
      "function_name": "maybe_zero",
      "docstring": "Returns the mask of bits that might be 0: complement of known-one.",
      "source": "func.func @maybe_zero(%kb : !transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer {\n  //Returns the mask of bits that might be 0: complement of known-one.\n  %known1 = \"transfer.get\"(%kb) {index = 1} : (!transfer.abs_value<[!transfer.integer, !transfer.integer]>) -> !transfer.integer\n  %all_ones = \"transfer.get_all_ones\"(%known1) : (!transfer.integer) -> !transfer.integer\n  %res = \"transfer.xor\"(%known1, %all_ones) : (!transfer.integer, !transfer.integer) -> !transfer.integer\n  func.return %res : !transfer.integer\n}"
    }
  ]
}
```

## Required workflow

1. Call `get_corpus_functions()` to read the synthesized transfer functions. For each one, annotate (mentally) which sub-sequences of operations compute a semantically coherent intermediate result.
2. Call `get_library_text()` to see what helpers already exist — do not re-emit anything already present or trivially equivalent.
3. Call `get_available_primitives()` to confirm which operations are allowed.
4. Look for sub-computations that appear in more than one function, or that are large enough to deserve a name on their own.
5. For each candidate, decide on a precise semantic description and a clear name.
6. Write the MLIR for each helper function. Verify it uses only allowed primitives and is in valid SSA form.
7. Return the JSON object with the `functions` array — no surrounding explanation, no transfer functions, no markdown fences around the final answer.
