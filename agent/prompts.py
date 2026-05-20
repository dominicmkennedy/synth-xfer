"""Prompt template loader and per-domain fragment substitution."""

from dataclasses import dataclass
from pathlib import Path
import re

from synth_xfer._util.domain import AbstractDomain


@dataclass(frozen=True)
class DomainFragment:
    """Per-domain prompt fragment loaded from agent/md/domains/<DomainName>.md."""

    semantics: str
    bottom_repr: str


_SECTION_HEADER = re.compile(r"^##\s+([A-Z_]+)\s*$")


def _split_sections(text: str) -> dict[str, str]:
    sections: dict[str, list[str]] = {}
    current: str | None = None
    for line in text.splitlines():
        m = _SECTION_HEADER.match(line.strip())
        if m:
            current = m.group(1)
            assert current is not None
            sections[current] = []
            continue
        if current is not None:
            sections[current].append(line)
    return {k: "\n".join(v).strip() for k, v in sections.items()}


def load_domain_fragment(domains_dir: Path, domain: AbstractDomain) -> DomainFragment:
    """Load and parse the per-domain fragment file."""
    path = domains_dir / f"{domain.name}.md"
    if not path.is_file():
        raise FileNotFoundError(f"Domain fragment not found for {domain.name}: {path}")
    sections = _split_sections(path.read_text(encoding="utf-8"))
    if "DOMAIN_SEMANTICS" not in sections:
        raise ValueError(
            f"Domain fragment {path} is missing required section: DOMAIN_SEMANTICS"
        )
    return DomainFragment(
        semantics=sections["DOMAIN_SEMANTICS"].strip(),
        bottom_repr=sections.get("BOTTOM_REPR", "").strip(),
    )


def fill_template(
    template: str,
    domain: AbstractDomain,
    fragment: DomainFragment,
    *,
    op_name: str = "",
    op_file: str = "",
) -> str:
    """Substitute domain placeholders and (optionally) per-task placeholders."""
    out = template
    out = out.replace("{DOMAIN_NAME}", domain.name)
    out = out.replace("{DOMAIN_SEMANTICS}", fragment.semantics)
    out = out.replace("{BOTTOM_REPR}", fragment.bottom_repr)
    if op_name:
        out = out.replace("<OP>", op_name)
        out = out.replace("<op>", op_name)
    if op_file:
        out = out.replace("<OP_FILE>", op_file)
    return out
