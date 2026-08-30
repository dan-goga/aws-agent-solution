from __future__ import annotations

from langchain.agents import create_agent
from langchain_anthropic import ChatAnthropic

from .config import settings
from .tools import estimate_cost

SYSTEM_PROMPT = (
    "You are a helpful cloud cost assistant running as a proof-of-concept "
    "agent on AWS. When asked about the cost of AWS resources, use the "
    "estimate_cost tool rather than guessing from memory."
)


def build_agent():
    llm = ChatAnthropic(
        model=settings.anthropic_model,
        api_key=settings.anthropic_api_key,
        temperature=0,
    )

    return create_agent(
        model=llm,
        tools=[estimate_cost],
        system_prompt=SYSTEM_PROMPT,
    )
