from __future__ import annotations

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(extra="ignore")

    # Injected via ECS's native `secrets` block (Secrets Manager), lands as a
    # plain env var — never fetched via SDK at runtime.
    anthropic_api_key: str
    anthropic_model: str = "claude-haiku-4-5-20251001"

    aws_region: str = "us-east-1"
    dynamodb_table_name: str
    lambda_tool_function_name: str

    # Optional: leave blank to disable Langfuse tracing.
    langfuse_public_key: str = ""
    langfuse_secret_key: str = ""
    langfuse_host: str = "https://cloud.langfuse.com"


settings = Settings()


def get_langfuse_handler():
    """Return a Langfuse callback handler, or None if tracing isn't configured."""
    if not settings.langfuse_public_key or not settings.langfuse_secret_key:
        return None

    from langfuse.callback import CallbackHandler

    return CallbackHandler(
        public_key=settings.langfuse_public_key,
        secret_key=settings.langfuse_secret_key,
        host=settings.langfuse_host,
    )
