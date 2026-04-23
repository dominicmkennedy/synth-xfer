"""Library learning workflow helpers."""

import argparse
import json
from pathlib import Path

from agents import Agent, Runner, function_tool

from agent.stitch.converter import pattern_to_mlir_program
from agent.stitch.search import search_patterns

from .agent_helper import format_agent_run_dump
from .util import (
    FunctionDocumentation,
    LibraryFunction,
    LibraryState,
    SynthesisResult,
    SynthesisTask,
    dump_library,
    extract_op_name,
    get_api_key,
    load_initial_library,
    save_file,
    summarize_token_usage,
)


def _run_agent_learn(
    prompt: str,
    api_key: str,
    previous_library: LibraryState,
    synthesis_results: list[SynthesisResult],
    model: str,
    ops_path: Path,
    instructions_path: Path,
    max_turns: int,
) -> tuple[LibraryState, object]:
    """Run agent to learn library functions. Returns (LibraryState, run_result)."""
    del api_key  # Reserved for future model/provider auth parity.

    @function_tool
    def get_corpus_functions() -> str:
        """Return the corpus MLIR programs to learn library funcs from"""
        corpus = set()
        for result in synthesis_results:
            for soln in result.solution_iters:
                corpus.add(soln)
        return "\n".join([str(s) for s in corpus])

    @function_tool
    def get_available_primitives() -> str:
        """Return the allowed primitive operators documentation (agent/ops.md)."""
        return ops_path.read_text(encoding="utf-8")

    @function_tool
    def list_library_functions() -> str:
        """List available library functions as JSON dictionary of func names and docstrings"""
        funcs = {
            func.function_name: func.docstring for func in previous_library.functions
        }
        return json.dumps(funcs)

    @function_tool
    def get_library_function(name: str) -> str:
        """Return the source of a function by its name"""
        for func in previous_library.functions:
            if func.function_name == name:
                return func.source

        raise ValueError("name must refer to a function in the library")

    @function_tool
    def search_library_functions(query: str, top_k: int = 3) -> str:
        """Search library functions by substring. Returns JSON array of matches with function name and docstring."""
        if top_k <= 0:
            return "[]"
        q = query.strip()
        if not q:
            return "[]"
        matches: list[dict] = []
        for func in previous_library.functions:
            searchable = f"{func.function_name}\n{func.docstring}\n{func.source}"
            if searchable.lower().find(q.lower()) == -1:
                continue
            matches.append(
                {
                    "function_name": func.function_name,
                    "docstring": func.docstring,
                }
            )
            if len(matches) >= top_k:
                break
        return json.dumps(matches)

    agent = Agent(
        name="LibraryFunctionLearner",
        instructions=instructions_path.read_text(encoding="utf-8").strip(),
        tools=[
            get_corpus_functions,
            get_available_primitives,
            list_library_functions,
            get_library_function,
            search_library_functions,
        ],
        model=model,
        output_type=LibraryState,
    )

    result = Runner.run_sync(agent, prompt, max_turns=max_turns)

    return (result.final_output, result)


def _name_one_function(
    api_key: str,
    model: str,
    ops_path: Path,
    instructions_path: Path,
    max_turns: int,
    library: LibraryState,
    func_to_name: str,
) -> tuple[LibraryFunction, object]:
    """Given the source for an MLIR function, provide a name and docstring for it agentically."""
    del api_key  # Reserved for future model/provider auth parity.

    prompt = "Name and document the MLIR function. Call get_function_code() to fetch it, look up any func.call callees with get_library_function(), and consult get_primitives() if needed. Return a snake_case function_name and a one-to-two sentence docstring describing what the function computes semantically."

    @function_tool
    def get_function_code() -> str:
        """Return the code of the function to be named and documented"""
        return func_to_name

    @function_tool
    def get_library_function(name: str) -> str:
        """Return the source of a func.call by its name"""
        for func in library.functions:
            if func.function_name == name:
                return func.source

        raise ValueError("name must refer to a function in the library")

    @function_tool
    def get_primitives() -> str:
        """Return the primitive operators documentation (agent/ops.md)."""
        return ops_path.read_text(encoding="utf-8")

    agent = Agent(
        name="AutoDocumenter",
        instructions=instructions_path.read_text(encoding="utf-8").strip(),
        tools=[
            get_function_code,
            get_library_function,
            get_primitives,
        ],
        model=model,
        output_type=FunctionDocumentation,
    )

    result = Runner.run_sync(agent, prompt, max_turns=max_turns)

    def _reformat_source(source: str, func_name: str, docstring: str) -> str:
        """Takes in MLIR function, sets name to func_name, and adds docstring"""
        comment = "\n// " + " ".join(docstring.splitlines())
        renamed = source.replace("@pattern", f"@{func_name}", 1)
        first, _, rest = renamed.partition("\n")
        return f"{first}  {comment}\n{rest}"

    new_source = _reformat_source(
        source=func_to_name,
        func_name=result.final_output.function_name,
        docstring=result.final_output.docstring,
    )
    lib_func = LibraryFunction(
        function_name=result.final_output.function_name,
        docstring=result.final_output.docstring,
        source=new_source,
    )

    return (lib_func, result)


def run_stitch_learn(
    version: int,
    previous_library: LibraryState,
    synthesis_results: list[SynthesisResult],
    max_instructions: int,
    top_k: int,
    args,
    api_key: str,
) -> LibraryState:
    """Learns library functions with Stitch. Learns func names and docstring agentically."""

    print(f"Library learning with Stitch and autodoc agent, version {version}")

    output_dir = Path(args.output)

    progs = set()
    for result in synthesis_results:
        for soln in result.solution_iters:
            progs.add(soln)

    result = search_patterns(
        progs=list(progs), max_instructions=max_instructions, top_k=top_k
    )
    mlir_hits = [
        pattern_to_mlir_program(h.pattern, result.program_dags)
        for h in result.hits
        if h.pattern.inst_count >= 2
    ]

    if args.dump_agent_run:
        hits = [h for h in result.hits if h.pattern.inst_count >= 2]
        stitch_log = ""
        for hit in hits:
            stitch_log += f"=== utility={hit.utility} | size = {hit.pattern.inst_count} | {hit.total_matches} matches ===\n"
            stitch_log += f"{hit.pattern}\n"

        dump_path = save_file(
            stitch_log,
            output_dir,
            f"stitch_log_{version}.log",
        )
        print(f"  Stitch run dump: {dump_path}")

    print(f"  Using model {args.library_model}")

    new_lib_funcs: list[LibraryFunction] = []
    agent_log = ""
    for i, hit in enumerate(mlir_hits):
        print(f"  Documenting function {i + 1}/{len(mlir_hits)}")
        lib_func, run_result = _name_one_function(
            api_key=api_key,
            model=args.library_model,
            ops_path=args.ops,
            instructions_path=args.autodoc_instructions,
            max_turns=args.max_turns,
            library=previous_library,
            func_to_name=hit,
        )
        new_lib_funcs.append(lib_func)
        agent_log += f"\n========== Autodoc for {lib_func.function_name} ==========\n"
        agent_log += format_agent_run_dump(run_result, model=args.library_model)

    if args.dump_agent_run:
        dump_path = save_file(
            agent_log,
            output_dir,
            f"autodoc_log_{version}.log",
        )
        print(f"  Autodoc run dump: {dump_path}")

    merged = LibraryState(functions=previous_library.functions + new_lib_funcs)
    lib_dir = output_dir / f"library{version}"
    dump_library(merged, lib_dir)
    print(f"Library: {lib_dir}")

    return merged


def run_library_learn_task(
    version: int,
    previous_library: LibraryState,
    synthesis_results: list[SynthesisResult],
    args,
    api_key: str,
) -> LibraryState:
    """Learn a new library version from synthesized task results."""

    print(f"\nLearning library version {version}")

    prompt = args.library_prompt.read_text()

    output_dir = Path(args.output)
    print(f"Using model: {args.library_model}")

    llm_output, run_result = _run_agent_learn(
        prompt=prompt,
        api_key=api_key,
        previous_library=previous_library,
        synthesis_results=synthesis_results,
        model=args.library_model,
        ops_path=args.ops,
        instructions_path=args.library_instructions,
        max_turns=args.max_turns,
    )

    summary = summarize_token_usage(run_result, model=args.library_model)
    print(summary)

    if args.dump_agent_run:
        dump_path = save_file(
            format_agent_run_dump(run_result, model=args.library_model),
            output_dir,
            f"learn_agent_{version}.log",
        )
        print(f"Agent run dump: {dump_path}")

    existing_names = {f.function_name for f in previous_library.functions}
    new_functions = [
        f for f in llm_output.functions if f.function_name not in existing_names
    ]
    merged = LibraryState(functions=previous_library.functions + new_functions)

    lib_dir = output_dir / f"library{version}"
    dump_library(merged, lib_dir)
    print(f"Library: {lib_dir}")

    return merged


def main():
    parser = argparse.ArgumentParser(description="Learn library functions")
    parser.add_argument(
        "input_files",
        nargs="+",
        help="MLIR files to learn from (e.g., mlir/Operations/Add.mlir)",
    )
    parser.add_argument(
        "-o", "--output", default="outputs/agent", help="Output directory"
    )
    parser.add_argument(
        "--library-model",
        default="gpt-5.1-codex-mini",
        help="OpenAI model used for library learning",
    )
    parser.add_argument(
        "--dump-agent-run",
        action="store_true",
        help="Dump full agent run (messages, tool calls, outputs) to output dir",
    )
    parser.add_argument(
        "--stitch",
        action="store_true",
        help="Run library learning with Stitch",
    )
    parser.add_argument(
        "--library-instructions",
        type=Path,
        default=Path(__file__).parent / "md" / "library_instructions.md",
        help="Path to library agent instructions file (default: agent/md/library_instructions.md)",
    )
    parser.add_argument(
        "--autodoc-instructions",
        type=Path,
        default=Path(__file__).parent / "md" / "autodoc_instructions.md",
        help="Path to autodoc agent instructions file (default: agent/md/autodoc_instructions.md)",
    )
    parser.add_argument(
        "--library-prompt",
        type=Path,
        default=Path(__file__).parent / "md" / "library_prompt.md",
        help="Path to library learning prompt template (default: agent/md/library_prompt.md)",
    )
    parser.add_argument(
        "--ops",
        type=Path,
        default=Path(__file__).parent / "md" / "ops.md",
        help="Path to ops.md file (default: agent/ops.md)",
    )
    parser.add_argument(
        "--library-dir",
        type=Path,
        default=None,
        help="Optional initial library directory for library-learning workflow",
    )
    parser.add_argument(
        "--rounds",
        type=int,
        default=1,
        help="Number of library-learn rounds to run (default: 1)",
    )
    parser.add_argument(
        "--max-turns",
        type=int,
        default=20,
        help="Max iterations for agent (default: 20, use 2-3 for fast dev)",
    )

    args = parser.parse_args()

    # Validate arguments
    if len(args.input_files) < 2:
        parser.error("input_file: need at least two files to learn from")

    for input_file in args.input_files:
        if not Path(input_file).exists():
            parser.error(f"input_file: path does not exist: {input_file}")

    for name, path in [
        ("--library-instructions", args.library_instructions),
        ("--autodoc-instructions", args.autodoc_instructions),
        ("--library-prompt", args.library_prompt),
        ("--ops", args.ops),
    ]:
        if not path.exists():
            parser.error(f"{name}: path does not exist: {path}")

    if args.library_dir is not None and not args.library_dir.is_dir():
        parser.error(f"--library-dir: not a directory: {args.library_dir}")

    if args.max_turns <= 0:
        parser.error("--max-turns: must be greater than 0")

    # Parse input files
    corpus = []
    for input_file in args.input_files:
        task = SynthesisTask("", extract_op_name(input_file))
        result = SynthesisResult(
            task=task,
            solution_iters=[Path(input_file).read_text()],
            eval_summary=None,
        )
        corpus.append(result)

    api_key = get_api_key()
    lib = load_initial_library(args.library_dir)

    for rnd in range(args.rounds):
        if args.stitch:
            lib = run_stitch_learn(
                version=rnd,
                previous_library=lib,
                synthesis_results=corpus,
                max_instructions=10,
                top_k=5,
                args=args,
                api_key=api_key,
            )
        else:
            lib = run_library_learn_task(
                version=rnd,
                previous_library=lib,
                synthesis_results=corpus,
                args=args,
                api_key=api_key,
            )

    print("Library learning complete")

    return 0
