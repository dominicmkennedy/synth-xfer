"""Direct LLM prompting method for transformer synthesis."""

from openai import OpenAI


def _use_responses_api(model: str) -> bool:
    """True if model uses Responses API (GPT-5, o-series, Codex)."""
    m = model.lower()
    return "-codex" in m or any(m.startswith(v) for v in ["gpt-5", "o1", "o3", "o4"])


def call_llm(prompt: str, api_key: str, model: str = "gpt-4") -> tuple[str, dict]:
    """Call OpenAI API and return (content, usage_dict)."""
    client = OpenAI(api_key=api_key)
    system_msg = (
        "You are an expert in MLIR and abstract interpretation. Generate sound, "
        "precise abstract transformers. Output only MLIR code without explanation."
    )

    if _use_responses_api(model):
        response = client.responses.create(
            model=model,
            instructions=system_msg,
            input=[{"role": "user", "content": [{"type": "input_text", "text": prompt}]}],
            max_output_tokens=64000,
        )
        content = response.output_text
        u = response.usage
        usage = {
            "input_tokens": u.input_tokens if u else 0,
            "output_tokens": u.output_tokens if u else 0,
            "reasoning_tokens": (
                u.output_tokens_details.reasoning_tokens
                if u
                and u.output_tokens_details
                and hasattr(u.output_tokens_details, "reasoning_tokens")
                else 0
            ),
        }
    else:
        response = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": system_msg},
                {"role": "user", "content": prompt},
            ],
            temperature=0.7,
            max_tokens=5000,
        )
        content = response.choices[0].message.content
        u = response.usage
        usage = {
            "input_tokens": u.prompt_tokens if u else 0,
            "output_tokens": u.completion_tokens if u else 0,
            "reasoning_tokens": 0,
        }

    if not content:
        raise ValueError("LLM response content is None or empty")

    return content.strip(), usage
