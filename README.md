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

## Example Synthesis Runs

### Quick Run

Here's a simple invocation of the `sxf` program for quick testing (should take ~60s):

```bash
sxf --op mlir/Operations/And.mlir \
    --domain KnownBits            \
    --num-iters 2                 \
    --num-steps 100               \
    --num-mcmc 50                 \
    --seed 2333
```

Output:
```
Top Solution | Exact 1.2346% |
Iteration 0  | Exact 62.4295% | 1 solutions | 22.7674s |
Iteration 1  | Exact 96.7078% | 3 solutions | 39.6943s |
Final Soln   | Exact 96.7078% | 3 solutions |
```

(The final output may be different depending on your system's RNG differences).

The command reads the MLIR program `mlir/Operations/And.mlir` and writes addtional output infor into `outputs/KnownBits_And/`.

### Dataset-Driven Run

Use an existing input dataset (metadata in the TSV determines op/domain/bitwidth workloads):

```bash
sxf --input knownbits_and_input_data.tsv \
    --num-iters 2                        \
    --num-steps 100                      \
    --num-mcmc 50
```

### Full Experiment Setup

This is a more comprehensive invocation closer to the experiment setup used in the paper (this can take up to an hour depending on your machine):

```bash
sxf --op mlir/Operations/Add.mlir     \
    --domain KnownBits                \
    --num-iters 5                     \
    --num-steps 1000                  \
    --num-mcmc 100                    \
    --mbw 8,5000 16,5000              \
    --hbw 32,5000,10000 64,5000,10000 \
    --vbw 4,8,16,32,64
```

## Important CLI Options for `sxf`

| CLI flag                         | Description                                                                                                                                                                          |
|----------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `--op <path>`                    | Path to a concrete operation or pattern (`.mlir` file) to synthesize an abstract transformer for.                                                                                    |
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
Entries under `patterns` may be either operation names like `Add` or integer pattern ids like `017`.

Example:

```yaml
KnownBits:
  patterns: [Add, 017]
  arity:
    2:
      lbw: [4]
      mbw: [[8, 1000]]
      hbw: [[64, 1000, 1000]]
    3:
      lbw: []
      mbw: [[4, 1000], [8, 1000]]
      hbw: [[64, 1000, 1000]]

UConstRange:
  patterns: [008, 081]
  arity:
    4:
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
| `--op <Path>`        | Path to the concrete operation (`.mlir` file), for the concrete semantics to verify with.                                                          |
| `--timeout <int>`    | Timeout flag (in seconds) to pass to the selected SMT solver (this is a per bit-width timeout).                                                    |
| `--solver <Name>`    | SMT solver backend to use. Choices: `z3`, `cvc5`, `bitwuzla` (default: `bitwuzla`).                                                                |

For example:
```bash
verify --xfer-file tests/data/kb_xor.mlir \
       --bw 4-8,16,32                     \
       --domain KnownBits                 \
       --op mlir/Operations/Xor.mlir      \
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
run-xfer --xfer-file tests/data/kb_or.mlir --bw 4 -d KnownBits --args="00??; 11?0"
# or
run-xfer --xfer-file tests/data/cr_add.mlir --bw 4 -d UConstRange --args="[5, 10]; [2, 3]"
```

## Important CLI Options for `eval-xfer`

| CLI flag                | Description                                                                                                                 |
|-------------------------|-----------------------------------------------------------------------------------------------------------------------------|
| `--xfer-file <Path>`    | One or more transformer `.mlir` files. Mutually exclusive with `--solution-dir`.                                            |
| `--solution-dir <Path>` | Path to an `sxf` solution directory containing `solution.mlir` files and `config.log` metadata. Generated mode only.        |
| `--xfer-name <str>`     | Name of the transformer function to evaluate for `--xfer-file` inputs. Not allowed with `--solution-dir`.                   |
| `-i, --input <Path>`    | Existing enum TSV dataset to evaluate against. Dataset mode only. Cannot be combined with `--solution-dir`.                 |
| `--domain <Name>`       | Abstract domain for generated eval with `--xfer-file`. Required when `--input` is omitted and `--solution-dir` is not used. |
| `--op <Path>`           | Concrete operation used to generate an eval workload on the fly for `--xfer-file`. Required in generated mode.              |
| `--exact-bw`            | Exact-scoring workload. Accepts `bw` or `bw,samples`. Default: `8,1000`.                                                    |
| `--dist-bw`             | Distance-scoring workload. Accepts `bw`, `bw,samples`, or `bw,lat_samples,crt_samples`. Default: `64,1000,100000`.          |
| `-o, --output <Path>`   | Write the evaluation table as CSV.                                                                                          |

Generated eval from explicit transformer files:
```bash
eval-xfer --xfer-file tests/data/kb_and.mlir tests/data/kb_or.mlir \
          --domain KnownBits                                       \
          --op mlir/Operations/And.mlir                            \
          --exact-bw 8,1000                                        \
          --dist-bw 64,1000,100000
```

Dataset eval:
```bash
eval-xfer --xfer-file tests/data/kb_and.mlir \
          --input generated_from_enum.tsv
```

Generated eval from an `sxf` solution directory:
```bash
eval-xfer --solution-dir outputs/ \
```

## Important CLI Options for `pattern`

The `pattern` executable provides four subcommands:

| Subcommand                | Purpose                                                                       |
|---------------------------|-------------------------------------------------------------------------------|
| `pattern analyze`         | Determine SSA reuse and if the composite and sequential transformers coincide |
| `pattern make-sequential` | Make a sequential transformer out of the synthesized mlir operations          |
| `pattern generate-input`  | Generate abstract inputs for patterns, mined LLVM's seen abstract inputs      |
| `pattern eval`            | Evaluate a composite and sequential transformer                               |

### `pattern analyze`

| CLI flag          | Description                                |
|-------------------|--------------------------------------------|
| `--pattern <Path>`| Pattern MLIR file to analyze.              |
| `--domain <Name>` | Abstract domain to analyze the pattern in. |

Example:
```bash
pattern analyze --pattern mlir/Patterns/008.mlir --domain KnownBits
```

### `pattern make-sequential`

| CLI flag              | Description                                                                                                 |
|-----------------------|-------------------------------------------------------------------------------------------------------------|
| `--pattern <Path>`    | Pattern MLIR file to lower into a sequential transformer.                                                   |
| `--domain <Name>`     | Abstract domain to build the sequential transformer in.                                                     |
| `--xfer-dir <Path>`   | Directory containing synthesized component-op solutions (expects the same format as a benchmark output dir) |
| `-o, --output <Path>` | Output MLIR file for the sequential transformer.                                                            |

Example:
```bash
pattern make-sequential \
  --pattern mlir/Patterns/008.mlir \
  --domain KnownBits \
  --xfer-dir outputs \
  -o pattern_008_seq.mlir
```

### `pattern generate-input`

| CLI flag                   | Description                                                                                     |
|----------------------------|-------------------------------------------------------------------------------------------------|
| `--pattern <Path>`         | Pattern MLIR file to generate inputs for.                                                       |
| `--domain <Name>`          | Abstract domain to generate inputs in.                                                          |
| `--mbw <bw,samples>`       | Bitwidth/sample-count pairs to sample that compute the ideal abstract output with `max-precise` |
| `--hbw <bw,samples>`       | Bitwidth/sample-count pairs to sample but not compute the ideal value                           |
| `--data-dir <Path>`        | Directory containing per-domain input TSVs used for sampling.                                   |
| `--sampling-alpha <Float>` | Exponent applied to `count` before weighted row sampling. Default `0.70`                        |
| `--weight-beta <Float>`    | Exponent applied to the proposal probability when emitting row weights. Default `0.15`          |
| `--timeout <int>`          | Per-row ideal-computation timeout in seconds for `--mbw` rows.                                  |
| `--solver <Name>`          | SMT solver backend for ideal computation. Choices: `z3`, `cvc5`, `bitwuzla`.                    |
| `--max-failures <int>`     | Max consecutive duplicate/timeout rejections before failing. Default `1000`.                    |
| `-o, --output <Path>`      | Output enum TSV.                                                                                |

Example (This command may take several minutes or more depending on the size of `mbw`):
```bash
pattern generate-input             \
  --pattern mlir/Patterns/008.mlir \
  --domain KnownBits               \
  --mbw 8,10000                    \
  --hbw 64,10000                   \
  --data-dir notes/input_data      \
  -o pattern_008_enum_data.tsv
```

### `pattern eval`

| CLI flag                  | Description                                                            |
|---------------------------|------------------------------------------------------------------------|
| `--sequential-xfer <Path>`| Sequential MLIR transformer, typically from `pattern make-sequential`. |
| `--composite-xfer <Path>` | Composite MLIR transformer to compare against.                         |
| `--xfer-name <str>`       | Optional function name inside the composite MLIR file.                 |
| `-i, --input <Path>`      | Enum TSV input data, typically from `pattern generate-input`.          |
| `--exact-bw <int>`        | Bitwidth used for exact pattern eval.                                  |
| `--norm-bw <int>`         | Bitwidth used for norm pattern eval.                                   |

Example:
```bash
pattern eval                             \
  --sequential-xfer pattern_008_seq.mlir \
  --composite-xfer composite_008.mlir    \
  -i pattern_008_enum_data.tsv           \
```

## Important CLI Options for `simplifier`

| CLI flag         | Description                                                                                                      |
|------------------|------------------------------------------------------------------------------------------------------------------|
| `<input_path>`   | Path to a transformer `.mlir` file. Accepts a single function or a module (defaults to the `solution` function). |
| `--rewrite-meet` | Rewrite the meet of all rewritten functions instead of individual functions.                                     |
| `--quiet`        | Suppress or enable console output from the optimizer (default: quiet).                                           |

## Important CLI Options for `max-precise`

| CLI flag          | Description                                                                         |
|-------------------|-------------------------------------------------------------------------------------|
| `--op`            | Path to a concrete operation or pattern (`.mlir` file).                             |
| `--args`          | The string representation of abstract value inputs.                                 |
| `--bw`            | The bitwidth of the arguments.                                                      |
| `--domain`        | The abstract domain (e.g. `KnownBits`, `UConstRange`, `SConstRange`).               |
| `--timeout`       | Timeout in seconds for the selected SMT solver.                                     |
| `--solver <Name>` | SMT solver backend to use. Choices: `z3`, `cvc5`, `bitwuzla` (default: `bitwuzla`). |
| `--input`         | Takes an enum `.tsv`, and will solve all `hbw` rows.                                |

Example:
```bash
max-precise --op mlir/Operations/Or.mlir --bw 4 -d KnownBits --args "00??; 11??"
# or
max-precise --op mlir/Operations/Add.mlir --bw 4 -d UConstRange --args="[5, 10]; [2, 3]"
```
