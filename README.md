# NiceToMeetYou

![DOI](https://img.shields.io/badge/DOI-10.1145%2F3776722-informational)
![Artifact](https://img.shields.io/badge/artifact-evaluated-success)
![CI](https://github.com/dominicmkennedy/synth-xfer/actions/workflows/ci.yml/badge.svg)
![Python](https://img.shields.io/badge/python-%E2%89%A53.13-blue)

**NiceToMeetYou** is a tool for synthesizing transformers for abstract interpretation.

Publication: [Nice to Meet You: Synthesizing Practical MLIR Abstract Transformers](https://dl.acm.org/doi/10.1145/3776722)

## Requirements

- Python == 3.13
- Clang >= 18

## Setup

1. Create and activate a Python virtual environment.
```bash
python3 -m venv .venv
source .venv/bin/activate
```
2. Install in editable mode with dev dependencies:
```bash
pip install -e ".[dev]"
```
3. Run tests to confirm the C++ bindings built correctly:
```bash
pytest -vv
```

## Usage

The project provides nine executables,
these executables depend on paths in the repo the should be run from the project root.

| Executable      | Description                                                                                               |
|-----------------|-----------------------------------------------------------------------------------------------------------|
| `sxf`           | Given either a concrete function or a benchmark config, synthesizes abstract transformers (the main tool) |
| `run-xfer`      | Runs synthesized transformer(s) on explicit inputs from stdin or enum TSV datasets                        |
| `eval-xfer`     | Evaluates synthesized transformer(s) against enum TSV datasets or generate workloads                      |
| `verify`        | Checks the soundness of a previously synthesized transformer                                              |
| `lower-to-llvm` | Lowers a synthesized transformer from MLIR to LLVM IR                                                     |
| `simplifier`    | Applies a peephole optimizer to simplify synthesized transformer code                                     |
| `enum`          | Samples an abstract input space and enumerates the optimal output for a concrete operation                |
| `max-precise`   | Computes the most precise abstract result for a concrete operation and abstract inputs                    |
| `pattern`       | Analyzes pattern completeness and generates pattern input datasets                                        |
| `format-mlir`   | Format transfer dialect MLIR code.                                                                        |

## Example Synthesis Runs

### Quick Run

Here's a simple invocation of the `sxf` program for quick testing (should take ~60s):

```bash
sxf --op And           \
    --domain KnownBits \
    --num-iters 2      \
    --num-steps 100    \
    --num-mcmc 50      \
    --seed 2333
```

Output:
```
Running KnownBits And
Top Solution | Exact 1.2346% | Dist 3499.2000 |
Iteration 0  | Exact 62.4295% | Dist 583.2000 | 1 solutions | 21.4510s |
Iteration 1  | Exact 62.5667% | Dist 580.8000 | 4 solutions | 35.7060s |
Final Soln   | Exact 62.5667% | 4 solutions |
```
Addtional output info is written to `outputs/KnownBits_And/`.

(The final output may differ slightly depending on your system RNG).

### Dataset-Driven Run

Use an existing input dataset (metadata in the TSV determines op/domain/bitwidth workloads):

```bash
sxf --input input_data/KnownBits/And.tsv \
    --num-iters 2                        \
    --num-steps 100                      \
    --num-mcmc 50
```

### Full Experiment Setup

This is a more comprehensive invocation closer to the experiment setup used in the paper (this can take up to an hour depending on your machine):

```bash
sxf --op "AshrExact(Sub(arg0, arg1), arg2)" \
    --domain KnownBits                      \
    --num-iters 5                           \
    --num-steps 1000                        \
    --num-mcmc 100                          \
    --mbw 8,1000                            \
    --hbw 32,5000,10000 64,5000,10000       \
    --vbw 4,8,16,32,64
```

## Important CLI Options for `sxf`

| CLI flag                         | Description                                                                                                                                                                          |
|----------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `--op <str>`                     | Concrete expression or operation to synthesize an abstract transformer for.                                                                                                          |
| `-i, --input <path>`             | Path to an existing dataset TSV. In dataset mode, op/domain/bitwidth workloads are read from dataset metadata.                                                                       |
| `--benchmark <path>`             | Path to a benchmark YAML file. Runs multiple synthesis jobs in parallel using the per-domain, per-arity settings from the file.                                                      |
| `-o <path>`                      | Output directory where synthesized results and intermediate outputs will be written.                                                                                                 |
| `--seed <int>`                   | Seed for the random number generator to make runs reproducible.                                                                                                                      |
| `--domain <Name>`                | Abstract domain to evaluate (e.g., `KnownBits`, `UConstRange`, `SConstRange`).                                                                                                       |
| `--num-iters <int>`              | Number of iterations for the synthesizer (default: `10`).                                                                                                                            |
| `--num-steps <int>`              | Number of mutation steps in one iteration (default: `1500`).                                                                                                                         |
| `--num-mcmc <int>`               | Number of MCMC processes that run in parallel (default: `100`).                                                                                                                      |
| `--program-length <int>`         | Length of one single synthesized transformer (default: `28`).                                                                                                                        |
| `--vbw <list[int]>`              | Bitwidths to verify at. Accepts ranges (e.g., `4-64`) or comma-separated values (e.g., `8,16,32,64`). (default: `4-64`).                                                             |
| `--lbw <list[int]>`              | Low-bitwidths to evaluate exhaustively (default: `4`).                                                                                                                               |
| `--mbw <list[int,int]>`          | Mid-bitwidths to sample abstract values with, but enumerate the concretizations of each of them exhaustively. Format: `bitwidth,num_samples` (e.g., `8,5000`).                       |
| `--hbw <list[int,int,int]>`      | High-bitwidths to sample abstract values with, and sample the concretizations of each of them. Format: `bitwidth,num_abstract_samples,num_concrete_samples` (e.g., `64,5000,10000`). |
| `--num-abd-procs <int>`          | Number of MCMC processes used for abduction. Must be less than `num_mcmc` (default: `30`).                                                                                           |
| `--condition-length <int>`       | Length of synthesized abduction (default: `10`).                                                                                                                                     |
| `--num-unsound-candidates <int>` | Number of unsound candidates considered for abduction (default: `15`).                                                                                                               |
| `--solver <Name>`                | SMT solver backend to use for verification. Choices: `z3`, `cvc5`, `bitwuzla` (default: `z3`).                                                                                       |
| `--optimize`                     | Run e-graph-based rewrite optimizer on synthesized candidates.                                                                                                                       |
| `--debug`                        | Write `debug.log` to the output directory (default: off).                                                                                                                            |

Exactly one of `--op` or `--benchmark` must be provided.

When using `--benchmark`, the bitwidth controls come from the YAML file rather than the command line.

When using `--input`, do not pass `--op`, `--domain`, `--benchmark`, `--lbw`, `--mbw`, or `--hbw`.

### Benchmark Configs

The `--benchmark` flag accepts a YAML file whose top-level keys are domains.
Each domain contains a list of `patterns` and bitwidth settings per pattern arity.

Example:

```yaml
KnownBits:
  patterns: ["And", "Sub(Xor(PopCount(arg0), arg1), Sdiv(arg2, arg3))"]
  arity:
    2:
      lbw: [4]
      mbw: [[8, 1000]]
      hbw: [[64, 1000, 1000]]
    4:
      lbw: []
      mbw: [[4, 1000], [8, 1000]]
      hbw: [[64, 1000, 1000]]

UConstRange:
  patterns: ["AddNuw", "Xor(arg0, Sub(arg0, arg1))"]
  arity:
    2:
      lbw: []
      mbw: [[4, 1000]]
      hbw: [[8, 1000, 1000]]
```

And run it with:

```bash
sxf --benchmark bench.yaml \
    --num-iters 5          \
    --num-steps 1000       \
    --num-mcmc 100
```

## Important CLI Options for `verify`

| CLI flag             | Description                                                                                                                                        |
|----------------------|----------------------------------------------------------------------------------------------------------------------------------------------------|
| `--xfer-file <Path>` | Path to the transformer (`.mlir` file), to be transformer to verified.                                                                             |
| `--xfer-name <str>`  | Name of the function in the transformer file to verify (defaults to `solution`, or the only function in the transformer file if there's just one). |
| `--bw <list[int]>`   | Bitwidth(s) to verify at (e.g. `-bw 4`, `-bw 4-64` or `-bw 4,8,16`).                                                                               |
| `--domain <Name>`    | Abstract domain semantics to verify with (e.g., `KnownBits`, `UConstRange`, `SConstRange`).                                                        |
| `--op <str>`         | Concrete expression or operation to verify with.                                                                                                   |
| `--timeout <int>`    | Timeout flag (in seconds) to pass to the selected SMT solver (this is a per bit-width timeout).                                                    |
| `--solver <Name>`    | SMT solver backend to use. Choices: `z3`, `cvc5`, `bitwuzla` (default: `bitwuzla`).                                                                |

For example:
```bash
verify --xfer-file tests/data/ideal_xfers/kb_xor.mlir \
       --bw 4-8,16,32                                 \
       --domain KnownBits                             \
       --op Xor                                       \
       --solver cvc5
```
Should produce:
```
4  bits | sound   | took 0.0342s
5  bits | sound   | took 0.0249s
6  bits | sound   | took 0.0256s
7  bits | sound   | took 0.0248s
8  bits | sound   | took 0.0240s
16 bits | sound   | took 0.0246s
32 bits | sound   | took 0.0282s
```

## Important CLI Options for `run-xfer`

| CLI flag              | Description                                                                                                                 |
|-----------------------|-----------------------------------------------------------------------------------------------------------------------------|
| `--xfer-file <Path>`  | One or more transformer `.mlir` files.                                                                                      |
| `--xfer-name <str>`   | Name of the transformer function to evaluate (defaults to `solution`, or the only function in the file if there's just one) |
| `-i, --input <Path>`  | Existing enum TSV dataset. If omitted, `run-xfer` uses `--args`.                                                            |
| `--bw <int>`          | Bitwidth for args apply mode. Required when `--input` is omitted.                                                           |
| `--domain <Name>`     | Abstract domain for args apply mode. Required when `--input` is omitted.                                                    |
| `--args <Name>`       | The string representation of abstract value inputs. (args are `;` separated)                                                |
| `-o, --output <Path>` | Write the resulting table as TSV.                                                                                           |

Example invocation:
```bash
run-xfer --xfer-file tests/data/ideal_xfers/kb_xor.mlir --bw 4 -d KnownBits --args="00??; 11?0"
# or
run-xfer --xfer-file tests/data/ideal_xfers/ucr_add.mlir --bw 4 -d UConstRange --args="[5, 10]; [2, 3]"
```

## Important CLI Options for `eval-xfer`

| CLI flag                | Description                                                                                                                 |
|-------------------------|-----------------------------------------------------------------------------------------------------------------------------|
| `--xfer-file <Path>`    | One or more transformer `.mlir` files. Mutually exclusive with `--solution-dir`.                                            |
| `--solution-dir <Path>` | Path to an `sxf` solution directory containing `solution.mlir` files and `config.log` metadata. Generated mode only.        |
| `--xfer-name <str>`     | Name of the transformer function to evaluate for `--xfer-file` inputs. Not allowed with `--solution-dir`.                   |
| `-i, --input <Path>`    | Existing enum TSV dataset to evaluate against. Dataset mode only. Cannot be combined with `--solution-dir`.                 |
| `--domain <Name>`       | Abstract domain for generated eval with `--xfer-file`. Required when `--input` is omitted and `--solution-dir` is not used. |
| `--op <str>`            | Concrete expression or operation used to generate an eval workload on the fly for `--xfer-file`. Required in generated mode |
| `--exact-bw`            | Exact-scoring workload. Accepts `bw` or `bw,samples`. Default: `8,1000`.                                                    |
| `--dist-bw`             | Distance-scoring workload. Accepts `bw`, `bw,samples`, or `bw,lat_samples,crt_samples`. Default: `64,1000,100000`.          |
| `-o, --output <Path>`   | Write the evaluation table as CSV.                                                                                          |

Generated eval from explicit transformer files:
```bash
eval-xfer --xfer-file tests/data/ideal_xfers/kb_and.mlir tests/data/ideal_xfers/kb_xor.mlir \
          --domain KnownBits                                                                \
          --op And                                                                          \
          --exact-bw 8,1000                                                                 \
          --dist-bw 64,1000,100000
```

Dataset eval:
```bash
eval-xfer --xfer-file tests/data/ideal_xfers/kb_and.mlir \
          --input generated_from_enum.tsv
```

## Important CLI Options for `pattern`

The `pattern` executable provides four subcommands:

| Subcommand                | Purpose                                                                       |
|---------------------------|-------------------------------------------------------------------------------|
| `pattern analyze`         | Determine SSA reuse and if the composite and sequential transformers coincide |
| `pattern lift`            | Lift a pattern expression into the internal MLIR representation               |
| `pattern generate-input`  | Generate abstract inputs for patterns, mined LLVM's seen abstract inputs      |
| `pattern eval`            | Evaluate a composite transformer compared to LLVM's sequential version        |

### `pattern analyze`

| CLI flag          | Description                                |
|-------------------|--------------------------------------------|
| `--op <str>`      | expression to analyze.                     |
| `--domain <Name>` | Abstract domain to analyze the pattern in. |

Example:
```bash
pattern analyze -d KnownBits --op "Select(ICmpUlt(AddNsw(Umax(arg0, arg1), arg0), arg0), arg2, Umin(arg3, arg2))"
```

### `pattern generate-input`

| CLI flag                   | Description                                                                                     |
|----------------------------|-------------------------------------------------------------------------------------------------|
| `--op <str>`               | pattern expression to generate input for.                                                       |
| `--domain <Name>`          | Abstract domain to generate inputs in.                                                          |
| `--mbw <bw,samples>`       | Bitwidth/sample-count pairs to sample that compute the ideal abstract output with `max-precise` |
| `--hbw <bw,samples>`       | Bitwidth/sample-count pairs to sample but not compute the ideal value                           |
| `--sampling-alpha <Float>` | Exponent applied to `count` before weighted row sampling. Default `0.70`                        |
| `--weight-beta <Float>`    | Exponent applied to the proposal probability when emitting row weights. Default `0.15`          |
| `--timeout <int>`          | Per-row ideal-computation timeout in seconds for `--mbw` rows.                                  |
| `--solver <Name>`          | SMT solver backend for ideal computation. Choices: `z3`, `cvc5`, `bitwuzla`.                    |
| `--max-failures <int>`     | Max consecutive duplicate/timeout rejections before failing. Default `1000`.                    |
| `-o, --output <Path>`      | Output enum TSV.                                                                                |

Example (This command may take several minutes or more depending on the size of `mbw`):
```bash
pattern generate-input                    \
  --op "AshrExact(Sub(arg0, arg1), arg2)" \
  --domain KnownBits                      \
  --mbw 8,100                             \
  --hbw 64,100                            \
  -o pattern_data.tsv
```

### `pattern eval`

| CLI flag                  | Description                                                   |
|---------------------------|---------------------------------------------------------------|
| `--composite-xfer <Path>` | Composite MLIR transformer to compare against.                |
| `--xfer-name <str>`       | Optional function name inside the composite MLIR file.        |
| `-i, --input <Path>`      | Enum TSV input data, typically from `pattern generate-input`. |
| `--bw <int>`              | Bitwidth used for the eval (default: 8).                       |

Prints a table comparing the LLVM seq pattern against the composite transformer at the chosen bitwidth.

Example:
```bash
pattern eval                          \
  --composite-xfer composite_008.mlir \
  -i pattern_data.tsv                 \
  --bw 8
```

## Important CLI Options for `simplifier`

The simplifier runs an [egglog](https://github.com/egraphs-good/egglog) e-graph saturation and re-emits the rewritten MLIR.

| CLI flag                | Description                                                                                                                                                            |
|-------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `<input_path>`          | Path to a transformer `.mlir` file. Accepts a single `func.func` or a `builtin.module` of functions.                                                                   |
| `--domain <Name>`       | (required) Abstract domain whose axioms (if any) apply during rewriting. Choices: `KnownBits`, `UConstRange`, `SConstRange`, `Mod3`, `Mod5`, `Mod7`, `Mod11`, `Mod13`.  |
| `-o, --output <Path>`   | Write the rewritten module to this file. If omitted, the module is printed to stdout.                                                                                  |
| `--max-iterations <int>`| Hard upper bound on egraph saturation passes per function (default: `6`).                                                                                              |
| `--step-time-limit <s>` | Per-iteration wall-clock cap in seconds (default: `1.0`). After any single iteration exceeds this budget, no further iterations are started — the egraph has grown enough that the next iteration is expected to be at least as slow. Egglog cannot be interrupted mid-iteration, so the check happens after each pass returns. |
| `-q, --quiet`           | Suppress per-iteration logging (default: quiet). Use `--no-quiet` for verbose output.                                                                                  |

Example:
```bash
simplifier tests/data/ideal_xfers/kb_and.mlir \
           --domain KnownBits                 \
           -o rewritten.mlir
```

## Important CLI Options for `max-precise`

| CLI flag          | Description                                                                         |
|-------------------|-------------------------------------------------------------------------------------|
| `--op <str>`      | Path to a concrete operation or expression to solve for                             |
| `--args`          | The string representation of abstract value inputs.                                 |
| `--bw`            | The bitwidth of the arguments.                                                      |
| `--domain`        | The abstract domain (e.g. `KnownBits`, `UConstRange`, `SConstRange`).               |
| `--timeout`       | Timeout in seconds for the selected SMT solver.                                     |
| `--solver <Name>` | SMT solver backend to use. Choices: `z3`, `cvc5`, `bitwuzla` (default: `bitwuzla`). |
| `--input`         | Takes an enum `.tsv`, and will solve all `hbw` rows.                                |

Example:
```bash
max-precise --op Xor --bw 4 -d KnownBits --args "00??; 11??"
# or
max-precise --op Add --bw 4 -d UConstRange --args="[5, 10]; [2, 3]"
```
