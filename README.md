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
| `eval-final`    | Measures the precision of a previously synthesized transformer                                            |
| `run-xfer`      | Runs a synthesized transformer on explicit inputs or evaluation datasets                                  |
| `verify`        | Checks the soundness of a previously synthesized transformer                                              |
| `lower-to-llvm` | Lowers a synthesized transformer from MLIR to LLVM IR                                                     |
| `simplifier`    | Applies a peephole optimizer to simplify synthesized transformer code                                     |
| `enum`          | Samples an abstract input space and enumerates the optimal output for a concrete operation                |
| `max-precise`   | Computes the most precise abstract result for a concrete operation and abstract inputs using z3           |
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
| `--optimize`                     | Run e-graph-based rewrite optimizer on synthesized candidates.                                                                                                                       |
| `--quiet`                        | Suppress verbose output.                                                                                                                                                             |

Exactly one of `--op` or `--benchmark` must be provided.

When using `--benchmark`, the bitwidth controls come from the YAML file rather than the command line.

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
| `--timeout <int>`    | Timeout flag (in seconds) to pass to z3 (this is a per bit-width timeout).                                                                         |

For example:
```bash
verify --xfer-file tests/data/kb_xor.mlir \
       --bw 4-8,16,32                     \
       --domain KnownBits                 \
       --op mlir/Operations/Xor.mlir
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

## Important CLI Options for `eval-final`

| CLI flag              | Description                                                                                                                                         |
|-----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| `<input_path>`        | Path to a solutions directory (with `config.log`) or a single transformer `.mlir` file.                                                             |
| `--domain <Name>`     | Abstract domain (required only when `<input_path>` is a single transformer file).                                                                   |
| `--op <Path>`         | Path to the concrete operation (`.mlir` file) (required only when `<input_path>` is a single transformer file).                                     |
| `--xfer-name <str>`   | Name of the transformer function to evaluate (defaults to `solution`, or the only function in the file if there's just one).                        |
| `--exact-bw <tuple>`  | Bitwidth for exact percent reporting. Accepts `bw` or `bw,num_samples` (e.g. `4`, or `8,5000`).                                                     |
| `--norm-bw <tuple>`   | Bitwidth for norm score reporting. Accepts `bw`, `bw,num_samples`, or `bw,num_abs_samples,num_conc_samples` (e.g. `4`, `8,5000` or `64,5000,5000`). |
| `-o, --output <Path>` | Write results as CSV to the given path.                                                                                                             |

For example:
```bash
eval-final tests/data/kb_and.mlir        \
           --domain KnownBits            \
           --op mlir/Operations/And.mlir \
           --exact-bw 8,5000             \
           --norm-bw 64,5000,5000
```
Should produce:
```
Exact bw: (8, 5000)
Norm bw:  (64, 5000, 5000)
      Domain   Op  Top Exact %  Synth Exact %  Top Norm  Synth Norm
0  KnownBits  And         4.02          100.0   2494.34           0
```

(With small differences due to RNG).

## Important CLI Options for `simplifier`

| CLI flag         | Description                                                                                                      |
|------------------|------------------------------------------------------------------------------------------------------------------|
| `<input_path>`   | Path to a transformer `.mlir` file. Accepts a single function or a module (defaults to the `solution` function). |
| `--rewrite-meet` | Rewrite the meet of all rewritten functions instead of individual functions.                                     |
| `--quiet`        | Suppress or enable console output from the optimizer (default: quiet).                                           |

## Important CLI Options for `max-precise`

Example usage: `max-precise --op mlir/Operations/Or.mlir -d KnownBits --args "00??,11??" --bw 4`

| CLI flag    | Description                                            |
|-------------|--------------------------------------------------------|
| `--op`      | Path to a concrete operation or pattern (`.mlir` file) |
| `--args`    | The string representation of abstract value inputs.    |
| `--bw`      | The bitwidth of the arguments                          |
| `--domain`  | The domain (only KnownBits is implemented now)         |
| `--timeout` | Timeout in seconds                                     |
| `--input`   | Takes an enum `.tsv`, and will sovle all `hbw` rows    |
