"""Synthesis workflow helpers."""

import json
from pathlib import Path
import time

from agents import Agent, Runner, function_tool

from synth_xfer._util.domain import AbstractDomain

from .agent_helper import format_agent_run_dump
from .util import (
    LibraryState,
    SynthesisResult,
    SynthesisTask,
    clean_llm_output,
    eval_transformer,
    merge_library_text,
    print_token_usage,
    save_file,
)


def run_agent_synthesis(
    prompt: str,
    op_file: str,
    op_name: str,
    api_key: str,
    library: LibraryState,
    model: str,
    max_turns: int,
    template_path: Path,
    ops_path: Path,
    examples_dir: Path,
    instructions_path: Path,
) -> tuple[str, object]:
    """Run agent to synthesize transformer. Returns (final_output, run_result)."""
    del api_key  # Reserved for future model/provider auth parity.

    @function_tool
    def get_task_bundle() -> str:
        """Return the concrete operation/task bundle as JSON (op_name, op_file, and op_content)."""
        op_path = Path(op_file)
        bundle = {
            "op_name": op_name,
            "op_file": str(op_path),
            "op_content": op_path.read_text(encoding="utf-8"),
        }
        return json.dumps(bundle)

    @function_tool
    def get_program_templates() -> str:
        """Return the MLIR output templates (agent/template.mlir)."""
        return template_path.read_text(encoding="utf-8")

    @function_tool
    def get_available_primitives() -> str:
        """Return the allowed primitive operators documentation (agent/ops.md)."""
        return ops_path.read_text(encoding="utf-8")

    @function_tool
    def get_library_text() -> str:
        """Return the library (in MLIR) containing reusable helper functions mined from previous synthesis rounds. Prefer calling these functions in your solution to keep the program short."""
        return library.functions_text

    @function_tool
    def list_examples() -> str:
        """List available example transformer files as JSON array of filenames."""
        names = (
            [p.name for p in sorted(examples_dir.glob("*.mlir"))]
            if examples_dir.exists()
            else []
        )
        return json.dumps(names)

    @function_tool
    def get_example(name: str) -> str:
        """Return the contents of one example transformer file by filename (e.g. 'kb_xor.mlir')."""
        p = (examples_dir / name).resolve()
        ex_dir = examples_dir.resolve()
        if ex_dir not in p.parents:
            raise ValueError(
                "example name must refer to a file under the examples directory"
            )
        if p.suffix != ".mlir":
            raise ValueError("example must be a .mlir file")
        return p.read_text(encoding="utf-8")

    @function_tool
    def search_examples(query: str, top_k: int = 3) -> str:
        """Search example transformer files by substring. Returns JSON array of matches with filename and snippet."""
        if top_k <= 0:
            return "[]"
        q = query.strip()
        if not q:
            return "[]"
        matches: list[dict] = []
        for p in sorted(examples_dir.glob("*.mlir")) if examples_dir.exists() else []:
            text = p.read_text(encoding="utf-8", errors="replace")
            idx = text.lower().find(q.lower())
            if idx == -1:
                continue
            start = max(0, idx - 200)
            end = min(len(text), idx + 200)
            matches.append(
                {"name": p.name, "start": start, "end": end, "snippet": text[start:end]}
            )
            if len(matches) >= top_k:
                break
        return json.dumps(matches)

    @function_tool
    def run_eval_tool(transformer_mlir: str) -> str:
        """Evaluate the generated transformer MLIR for the current operation (e.g. kb_<op>). Pass the raw MLIR code as a string. Evaluate on a low bitwidth (default: 4), and a high bitwidth (default: 64). Returns a short summary:
        - Sound %: the percentage of inputs for which the output abstract value is sound
        - Exact %: the percentage of inputs for which the output abstract value is exactly the same the optimal transfer function (perfect precision)
        - Norm: ignore for now
        """
        full_soln = merge_library_text(library.functions_text, transformer_mlir)

        # Xuanyu: let agent understand simple metrics first for now. Use Norm later.
        return eval_transformer(
            solution_path=full_soln,
            op_path=Path(op_file),
            domain=AbstractDomain.KnownBits,
            xfer_name=f"kb_{op_name.lower()}",
        )

    agent = Agent(
        name="TransformerSynthesizer",
        instructions=instructions_path.read_text(encoding="utf-8").strip(),
        tools=[
            get_task_bundle,
            get_program_templates,
            get_available_primitives,
            get_library_text,
            list_examples,
            get_example,
            search_examples,
            run_eval_tool,
        ],
        model=model,
    )

    result = Runner.run_sync(agent, prompt, max_turns=max_turns)

    return (result.final_output, result)


def run_eval(
    op_file_path: str,
    transformer: SynthesisResult,
    library: LibraryState,
    op_name: str,
) -> str:
    """Evaluate the transformer via eval_transformer (no subprocess)."""
    print("\nRunning eval (Python)...")

    cleaned_mlir = clean_llm_output(transformer.solution_text)
    full_soln = merge_library_text(library.functions_text, cleaned_mlir)

    return eval_transformer(
        full_soln, Path(op_file_path), AbstractDomain.KnownBits, f"kb_{op_name.lower()}"
    )


def run_single_synthesis_task(
    task: SynthesisTask,
    round_num: int,
    library: LibraryState,
    args,
    api_key: str,
) -> SynthesisResult:
    """Run one synthesis task with current library context."""
    print(f"Synthesizing: round={round_num}, op={task.op_name}")

    op_lower = task.op_name.lower()
    # Xuanyu: make this a md file
    prompt = (
        "Task: Synthesize a KnownBits transfer function in MLIR.\n"
        f"- Operation name: {task.op_name}\n"
        f"- Operation file: {task.op_file}\n"
        "\n"
        "Use tools to fetch all materials; do not assume they are in this message:\n"
        "- get_task_bundle(): concrete op MLIR\n"
        "- get_program_templates(): output templates\n"
        "- get_available_primitives(): allowed operators\n"
        "- get_library_text(): available helper functions\n"
        "- list_examples()/search_examples()/get_example(): reference implementations\n"
        "- run_eval_tool(mlir): evaluate your candidate\n"
        "\n"
        "Prioritize reusing functions from get_library_text() — they are mined from previous rounds and can potentially shorten your solution significantly.\n"
        "\n"
        "Output contract:\n"
        f"- Return ONLY MLIR func.func @kb_{op_lower}\n"
        "- One operation per line; SSA form; no explanations.\n"
        "\n"
        f"You have a maximum of {args.max_turns} iterations to complete this task.  "
        "Do not exceed this limit. If you are going to exceed the limit, you should return the current MLIR you have generated."
    )

    output_dir = Path(args.output)
    print(f"Using model: {args.model}")
    t0 = time.monotonic()
    llm_output, run_result = run_agent_synthesis(
        prompt,
        task.op_file,
        task.op_name,
        api_key,
        library,
        args.model,
        args.max_turns,
        template_path=args.template,
        ops_path=args.ops,
        examples_dir=args.examples_dir,
        instructions_path=args.agent_instructions,
    )
    synthesis_time = time.monotonic() - t0
    print_token_usage(run_result)
    if args.dump_agent_run:
        dump_path = save_file(
            format_agent_run_dump(run_result),
            output_dir,
            f"synth_agent_r{round_num}_{task.op_name.lower()}.log",
        )
        print(f"Agent run dump: {dump_path}")

    transformer_file = save_file(
        clean_llm_output(llm_output),
        output_dir,
        f"kb_r{round_num}_{task.op_name.lower()}.mlir",
    )
    print(f"Transformer: {transformer_file}")

    result = SynthesisResult(task, llm_output, transformer_file, None)

    eval_summary: str | None = None
    if not args.skip_eval:
        eval_summary = run_eval(task.op_file, result, library, task.op_name)
        print(f"Eval result:\n{eval_summary}")
        save_file(
            f"synthesis_time: {synthesis_time:.2f}s\n\n{eval_summary}",
            output_dir,
            f"eval_r{round_num}_{task.op_name.lower()}.txt",
        )

    return SynthesisResult(task, llm_output, transformer_file, eval_summary)
