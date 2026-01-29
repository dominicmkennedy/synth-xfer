# NiceToMeetYou

![DOI](https://img.shields.io/badge/DOI-10.1145%2F3776722-informational)
![Artifact](https://img.shields.io/badge/artifact-evaluated-success)
![CI](https://github.com/dominicmkennedy/synth-xfer/actions/workflows/ci.yml/badge.svg)
![Python](https://img.shields.io/badge/python-%E2%89%A53.13-blue)

**NiceToMeetYou** is a tool for synthesizing transformers for abstract interpretation.

Publication: [Nice to Meet You: Synthesizing Practical MLIR Abstract Transformers](https://dl.acm.org/doi/10.1145/3776722)

## Requirements

- Python >= 3.13  
- Clang >= 18

## Setup

1. Create and activate a Python virtual environment.
2. Install in editable mode with dev dependencies: 
```bash
pip install -e .[dev]
```
3. Run tests to confirm the C++ bindings built correctly:
```bash
pytest -vv
```

## Usage

The project provides six executables:

| Executable      | Description                                                                           |
|-----------------|---------------------------------------------------------------------------------------|
| `sxf`           | Given an abstract domain and a concrete function, synthesizes an abstract transformer |
| `benchmark`     | Runs multiple synthesis experiments in parallel across available CPU cores            |
| `eval-final`    | Measures the precision of a previously synthesized transformer                        |
| `verify`        | Checks the soundness of a previously synthesized transformer                          |
| `lower-to-llvm` | Lowers a synthesized transformer from MLIR to LLVM IR                                 |
| `simplifier`    | Applies a peephole optimizer to simplify synthesized transformer code                 |
