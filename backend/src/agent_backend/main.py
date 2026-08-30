from __future__ import annotations

import logging

from fastapi import FastAPI
from pydantic import BaseModel

from .agent import build_agent
from .config import get_langfuse_handler
from .tools import get_history, save_turn

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("agent_backend")

app = FastAPI(title="AWS Agent POC Backend")
_agent = build_agent()


class ChatRequest(BaseModel):
    session_id: str
    message: str


class ChatResponse(BaseModel):
    reply: str


@app.get("/api/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/api/chat", response_model=ChatResponse)
def chat(request: ChatRequest) -> ChatResponse:
    history = get_history(request.session_id)
    messages = [
        {
            "role": "user" if item["role"] == "human" else "assistant",
            "content": item["content"],
        }
        for item in history
    ]
    messages.append({"role": "user", "content": request.message})

    callbacks = []
    handler = get_langfuse_handler()
    if handler is not None:
        callbacks.append(handler)

    result = _agent.invoke({"messages": messages}, config={"callbacks": callbacks})
    reply = result["messages"][-1].text

    save_turn(request.session_id, "human", request.message)
    save_turn(request.session_id, "ai", reply)

    return ChatResponse(reply=reply)
