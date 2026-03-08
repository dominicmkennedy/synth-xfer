## Task: Synthesize KnownBits transfer for `<OP>`

Implement a sound and high-precision KnownBits transfer function for operation `<OP>` in this repository.

You will write **one MLIR file**: `kb_<op>.mlir`, defining a function with symbol name `kb_<op>`.

## Context: What KnownBits means here

KnownBits is represented as a 2-element container for each value:

- element **0**: known-zero mask
- element **1**: known-one mask

A bit set in known-zero means that bit is definitely 0; a bit set in known-one means that bit is definitely 1. Your transfer must maintain **soundness** (never claim a bit is known if it might not be).

## Concrete semantics of `<OP>`

Use this as the semantics of the concrete operator:

<CONCRETE_OPERATION>

## Constraints: MLIR form and allowed building blocks

1. **Style match:** Follow the same MLIR style as the provided templates/examples.
2. **SSA only:** The program must be in SSA form.
3. **One op per line:** Every line must be exactly one allowed MLIR operation. Do **not** write `%x = %y`; instead, thread SSA values directly into subsequent ops or into `transfer.make`.
4. **Use only allowed ops:** Use only primitives from the “Available Operators” section (aligned with LLVM APInt semantics), plus any listed library helpers. Use a library function through `func.call`
```mlir
%res = func.call @f(%arg0, %arg1) : (arg0_type, arg1_type) -> res_type
```

### Available primitives

<PRIMITIVE_OPERATORS>

### Available library helpers

```mlir
<LIBRARY_FUNCTIONS>
```

## Templates and reference implementations

### Output templates

Your output must fit one of these templates:

```mlir
<PROGRAM_TEMPLATES>
```

### Examples

Those are example transformers for other concrete operations:

<TRANSFORMER_EXAMPLES>

## Required workflow (must follow)

1. Reason first: For this operation, what do known-zero and known-one mean for each output? Which cases or sub-expressions do you need to handle? Plan the transfer structure before writing code.
2. Output a candidate MLIR based on that reasoning.
3. Call the eval tool with that MLIR (pass the raw MLIR string as the argument).
4. If the tool returns an error, fix the MLIR and go back to step 3.
5. Otherwise the tool returns metrics (Sound %% and Exact %%). If Sound %% is not 100, you should fix the soundness of your transfer function. If Exact %% is low, reason about which cases can be improved and try again.
6. When the tool returns sound (Sound %% = 100) and you are satisfied with the precision (Exact %% is high), return that MLIR as your final answer (MLIR only, no explanation).
