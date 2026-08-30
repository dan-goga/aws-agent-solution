from __future__ import annotations

from langchain.agents import AgentExecutor, create_tool_calling_agent
from langchain_anthropic import ChatAnthropic
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder

from .config import settings
from .tools import estimate_cost

SYSTEM_PROMPT = (
    "You are a helpful cloud cost assistant running as a proof-of-concept "
    "agent on AWS. When asked about the cost of AWS resources, use the "
    "estimate_cost tool rather than guessing from memory."
)


def build_agent_executor() -> AgentExecutor:
    llm = ChatAnthropic(
        model=settings.anthropic_model,
        api_key=settings.anthropic_api_key,
        temperature=0,
    )

    prompt = ChatPromptTemplate.from_messages(
        [
            ("system", SYSTEM_PROMPT),
            MessagesPlaceholder("chat_history", optional=True),
            ("human", "{input}"),
            MessagesPlaceholder("agent_scratchpad"),
        ]
    )

    tools = [estimate_cost]
    agent = create_tool_calling_agent(llm, tools, prompt)
    return AgentExecutor(agent=agent, tools=tools, verbose=False)
