# Synth Transfer

## Setup

1. Create and activate a Python virtual environment:

```bash
# create the venv
python3 -m venv .venv
# activate it
source .venv/bin/activate
```

2. Install development dependencies and editable package:

```bash
pip install -e .[dev]
```

3. Run tests to verify the C++ bindings built correctly:

```bash
pytest
```

## Example runs

### Quick toy run

Here's a simple invocation of the `sxf` CLI for quick testing:

```bash
sxf mlir/Operations/And.mlir -o outputs/And -domain KnownBits -num_iters 2 -num_steps 100 -num_mcmc 50 -random_seed 2333
```

Output:
```
Top Solution | Exact 1.2346% |
Iteration 0  | Exact 62.4295% | 1 solutions | 22.7674s |
Iteration 1  | Exact 96.7078% | 3 solutions | 39.6943s |
Final Soln   | Exact 96.7078% | 3 solutions |
```

The command reads the MLIR program `mlir/Operations/And.mlir` and writes outputs into `outputs/And`.

### Full experiment setup

This is a more comprehensive invocation closer to the experiment setup used in the paper:

```bash
sxf mlir/Operations/Add.mlir -o outputs/Add -domain KnownBits -num_iters 5 -num_steps 1000 -num_mcmc 100 -mbw 8,5000 16,5000 -hbw 32,5000,10000 64,5000,10000 -vbw 4,8,16,32,64
```

## CLI options (example flags explained)

- `-o <path>`: Output directory where synthesized results and intermediate outputs will be written.
- `-random-seed <int>`: Seed for the random number generator to make runs reproducible.
- `-domain <Name>`: Abstract domain to evaluate (e.g., `KnownBits`, `UConstRange`, `SConstRange`).
- `-num-iters <int>`: Number of iterations for the synthesizer (default: `10`).
- `-num-steps <int>`: Number of mutation steps in one iteration (default: `1500`).
- `-num-mcmc <int>`: Number of MCMC processes that run in parallel (default: `100`).
- `-program_length <int>`: Length of one single synthesized transformer (default: `28`).
- `-vbw <list[int]>`: Bitwidths to verify at. Accepts ranges (e.g., `4-64`) or comma-separated values (e.g., `8,16,32,64`). (default: `4-64`).
- `-lbw <list[int]>`: Low-bitwidths to evaluate exhaustively (default: `4`).
- `-mbw <list[int,int]>`: Mid-bitwidths to sample abstract values with, but enumerate the concretizations of each of them exhaustively. Format: `bitwidth,num_samples` (e.g., `8,5000`).
- `-hbw <list[int,int,int]>`: High-bitwidths to sample abstract values with, and sample the concretizations of each of them. Format: `bitwidth,num_abstract_samples,num_concrete_samples` (e.g., `64,5000,10000`).
- `-num-abd-procs <int>`: Number of MCMC processes used for abduction. Must be less than `num_mcmc` (default: `30`).
- `-condition-length <int>`: Length of synthesized abduction (default: `10`).
- `-num-unsound-candidates <int>`: Number of unsound candidates considered for abduction (default: `15`).
- `-optimize`: Run e-graph-based rewrite optimizer on synthesized candidates.
- `-quiet`: Suppress verbose output.
