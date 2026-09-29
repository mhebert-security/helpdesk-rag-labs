"""Message assembly for the Azure OpenAI chat completion call.

v0 lets the system prompt ride in the request body, which is the injection
surface lab 01 closes. The user turn formats retrieved chunks as context
above the employee question.
"""

from __future__ import annotations

import os

_PROMPTS_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "prompts")
SYSTEM_PROMPT_PATH = os.path.join(_PROMPTS_DIR, "system.txt")
RAG_TEMPLATE_PATH = os.path.join(_PROMPTS_DIR, "rag-template.txt")


def _read(path: str) -> str:
    with open(path, encoding="utf-8") as handle:
        return handle.read().strip()


def default_system_prompt() -> str:
    """Return the server-side system prompt.

    An environment override (SYSTEM_PROMPT) wins over the checked-in file so
    operators can tune it without editing code.
    """
    return os.getenv("SYSTEM_PROMPT") or _read(SYSTEM_PROMPT_PATH)


def _format_context(chunks: list[dict]) -> str:
    """Render retrieved chunks as numbered context blocks."""
    blocks = []
    for index, chunk in enumerate(chunks, start=1):
        source = chunk.get("source", "unknown")
        content = chunk.get("content", "")
        blocks.append(f"[{index}] (source: {source})\n{content}")
    return "\n\n".join(blocks)


def build_messages(
    *,
    system_prompt: str,
    chunks: list[dict],
    question: str,
    history: list[dict] | None = None,
) -> list[dict]:
    """Assemble the messages array for one completion call.

    v0 uses the system prompt verbatim from the caller (no isolation) and
    formats retrieved chunks as context above the employee question.
    """
    template = _read(RAG_TEMPLATE_PATH)
    user_content = template.format(
        context=_format_context(chunks),
        question=question,
    )

    messages: list[dict] = [{"role": "system", "content": system_prompt}]
    messages.extend(history or [])
    messages.append({"role": "user", "content": user_content})
    return messages
