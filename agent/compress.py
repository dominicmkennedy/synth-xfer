"""Library learning workflow helpers."""

from pathlib import Path
import re

from agents import Agent, Runner

from .agent_helper import format_agent_run_dump
from .shared import build_compression_prompt
from .util import (
    LibraryState,
    SynthesisResult,
    clean_llm_output,
    merge_library_text,
    print_token_usage,
    save_file,
)

_MD_DIR = Path(__file__).parent / "md"


def _read_instruction_file(name: str) -> str:
    text = (_MD_DIR / name).read_text(encoding="utf-8")
    return text.strip()


LEARN_INSTRUCTIONS = _read_instruction_file("compress_instructions.md")


def _run_agent_compress(
    prompt: str,
    api_key: str,
    model: str = "gpt-4",
) -> tuple[str, object]:
    """Run agent to compress a target file. Returns (final_output, run_result)."""

    agent = Agent(
        name="TargetFileCompressor",
        instructions=COMPRESS_INSTRUCTIONS,
        model=model,
    )

    result = Runner.run_sync(agent, prompt)

    return (result.final_output, result)



def run_single_compression(
    target: SynthesisResult,
    library: LibraryState,
    args,
    api_key,
) -> SynthesisResult:
    op_name = target.task.op_name
    print(f"\nRunning compression on {op_name}")

    # Read prompt
    prompt_template_raw = args.compress_prompt.read_text()
    prompt_template = re.sub(
        r"<!--.*?-->", "", prompt_template_raw, flags=re.DOTALL
    ).strip()

    output_dir = Path(args.output)
    log_dir = output_dir / "log"

    print(f"Using model: {args.model}")

    prompt = build_compression_prompt(
        prompt_template=prompt_template,
        target=target,
        lib=library,
    )


    llm_output, run_result = _run_agent_compress(
        prompt=prompt,
        api_key=api_key,
        model=args.model,
    )
    target_text = clean_llm_output(llm_output)

    if args.safe_compress and target.eval_summary:
        pattern = r"Sound %:\s*(?P<sound>[\d.]+),\s*Exact %:\s*(?P<exact>[\d.]+)"
        match = re.search(pattern, target.eval_summary)

        curr_sound = float(match.group("sound"))
        curr_exact = float(match.group("exact"))

        compressed_eval = run_eval(
            op_file_path=Path(target.task.op_file),
            transformer=SynthesisResult(
                task=target.task,
                solution_text=target_text,
                transformer_path=target.transformer_path,
                eval_summary=None,
            ),
            library=library,
            op_name=target.task.op_name,
        )

        match = re.search(pattern, compressed_eval)

        compressed_sound = float(match.group("sound"))
        compressed_exact = float(match.group("exact"))

        if abs(compressed_sound - curr_sound) > 0.1:
            print(f"Compression of {target.task.op_name} failed.")
            print(f"    Soundness before compression: {curr_sound}")
            print(f"    Soundness after compression: {compressed_sound}")
            return target

        if abs(compressed_exact - curr_exact) > 0.1:
            print(f"Compression of {target.task.op_name} failed.")
            print(f"    Exactness before compression: {curr_exact}")
            print(f"    Exactness after compression: {compressed_exact}")
            return target

        print("Safe compression successful!")

    if args.dump_agent_run:
        dump_path = log_dir / f"compress_run_{op_name}.txt"
        dump_path.write_text(format_agent_run_dump(run_result), encoding="utf-8")
        print(f"Agent run dump: {dump_path}")

    (log_dir / f"compress_output_{op_name}.txt").write_text(llm_output)

    transformer_file = save_transformer(target_text, output_dir, target.task.op_name)
    print(f"Transformer: {transformer_file}")

    return SynthesisResult(
        task=target.task,
        solution_text=target_text,
        transformer_path=target.transformer_path,
        eval_summary=target.eval_summary,
    )
