<!-- Comments
Comments -->

## Task

Implement a KnownBits transfer function for operation `<OP>` in this repo

## Reasoning (before implementing)

- Reason about the operation semantics and how KnownBits (known-zero, known-one) should be updated for each output before writing MLIR.
- Aim for **sound** and **precise** transfers; prefer a well-reasoned design over the first implementation that passes eval.
- If a candidate gets low metrics or errors, analyze why (e.g. wrong propagation, missing cases) and improve the design, not only fix syntax.

## Requirements

1. Implement `kb_<op>.mlir` in the same MLIR style as the examples I provided to you.
2. Function has symbol name `kb_<op>`.
3. KnownBits encoding:
   - index 0 = known-zero mask
   - index 1 = known-one mask
4. Use existing primitive included in the following Avaliable Operators section, which aligned with the LLVM APInt semantics.
5. The program should be in SSA (Single Static Assigment) form. **Each line only has 1 operation**. Do not write `%x = %y` (that is invalid MLIR); every definition must be an operation call; use SSA values directly in the next operation or in `transfer.make`.

## Workflow Instructions

Follow this workflow:
1. Reason first: For this operation, what do known-zero and known-one mean for each output? Which cases or sub-expressions do you need to handle? Plan the transfer structure before writing code.
2. Output a candidate MLIR based on that reasoning.
3. Call the eval tool with that MLIR (pass the raw MLIR string as the argument).
4. If the tool returns an error, fix the MLIR and go back to step 3.
5. Otherwise the tool returns metrics (Sound %% and Exact %%). If Sound %% is not 100, you should fix the soundness of your transfer function. If Exact %% is low, reason about which cases can be improved and try again.
6. When the tool returns sound (Sound %% = 100) and you are satisfied with the precision (Exact %% is high), return that MLIR as your final answer (MLIR only, no explanation).

## Concrete Operation

The semantics of concrete operator you need to synthesize abstract transfer function for:
<CONCRETE_OPERATION>

## Output Template and Examples

The output MLIR programs should fit in the following templates:
<PROGRAM_TEMPLATES>

These and some examples of transfer functions:
<TRANSFORMER_EXAMPLES>

## Available Operators

<PRIMITIVE_OPERATORS>

## Available Library Functions

<LIBRARY_FUNCTIONS>
