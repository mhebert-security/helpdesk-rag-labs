"""FastAPI entrypoint for the helpdesk RAG chatbot.

v0 is intentionally insecure. There is no authentication, no output
sanitization, the system prompt rides in the request body, and retrieval
applies no ACL filter. Each of those gaps is the subject of a later lab.
"""

from __future__ import annotations

import logging
import os
import time

from dotenv import load_dotenv
from fastapi import FastAPI, Request
from azure.ai.inference import ChatCompletionsClient
from azure.ai.inference.models import SystemMessage, UserMessage, AssistantMessage
from azure.core.credentials import AzureKeyCredential
from pydantic import BaseModel

from src.orchestrator.chat import build_messages, default_system_prompt
from src.retriever.search import retrieve
from src.session.store import SessionStore

load_dotenv()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("helpdesk")

# App Insights telemetry. v0 uses OpenTelemetry when the package is present
# and falls back to a plain logger otherwise. The chat.request event is the
# baseline stream every later detection rule reads.
try:
    from azure.monitor.opentelemetry import configure_azure_monitor
    from opentelemetry import trace as otel_trace

    if os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING"):
        configure_azure_monitor()
    _tracer = otel_trace.get_tracer(__name__)
    _OTEL_AVAILABLE = True
except Exception:  # pragma: no cover - only reached when the package is absent
    _tracer = None
    _OTEL_AVAILABLE = False

app = FastAPI(title="Helpdesk RAG", version="v0")
store = SessionStore()


class ChatRequest(BaseModel):
    message: str
    session_id: str | None = None
    system_prompt: str | None = None


class ChatResponse(BaseModel):
    response: str
    sources: list[str]


def _client_ip(request: Request) -> str:
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else "unknown"


def _emit_chat_request(session_id: str | None, prompt_len: int, ip: str) -> None:
    """Emit the chat.request telemetry event."""
    if _OTEL_AVAILABLE and _tracer is not None:
        with _tracer.start_as_current_span("chat.request") as span:
            span.set_attribute("session_id", session_id or "")
            span.set_attribute("prompt_len", prompt_len)
            span.set_attribute("ip", ip)
            span.set_attribute("timestamp", time.time())
    else:
        logger.info(
            "chat.request session_id=%s prompt_len=%d ip=%s",
            session_id,
            prompt_len,
            ip,
        )


def _call_model(messages: list[dict]) -> str:
    endpoint = os.getenv("AZURE_AI_FOUNDRY_ENDPOINT")
    key = os.getenv("AZURE_AI_FOUNDRY_KEY")
    model = os.getenv("AZURE_AI_FOUNDRY_MODEL", "DeepSeek-R1")
    if not endpoint or not key:
        raise RuntimeError(
            "AZURE_AI_FOUNDRY_ENDPOINT and AZURE_AI_FOUNDRY_KEY must be set"
        )

    client = ChatCompletionsClient(
        endpoint=endpoint,
        credential=AzureKeyCredential(key),
    )
    completion = client.complete(model=model, messages=messages)
    return completion.choices[0].message.content or ""


@app.get("/api/health")
def health() -> dict:
    return {"status": "ok"}


@app.post("/api/chat", response_model=ChatResponse)
def chat(body: ChatRequest, request: Request) -> ChatResponse:
    session_id = body.session_id or "default"
    ip = _client_ip(request)

    _emit_chat_request(session_id, len(body.message), ip)

    # v0: retrieve without an ACL filter (insecure by design).
    chunks = retrieve(body.message)

    # v0: the system prompt may come from the request body (insecure).
    system_prompt = body.system_prompt or default_system_prompt()

    messages = build_messages(
        system_prompt=system_prompt,
        chunks=chunks,
        question=body.message,
        history=store.get_history(session_id),
    )

    answer = _call_model(messages)

    store.append_turn(session_id, "user", body.message)
    store.append_turn(session_id, "assistant", answer)

    return ChatResponse(response=answer, sources=[chunk["source"] for chunk in chunks])
