FROM python:3.14-slim

RUN pip install --no-cache-dir uv

WORKDIR /app

# Generate uv.lock locally first: `cd backend && uv lock`
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

COPY src ./src
RUN uv sync --frozen --no-dev

EXPOSE 8000

CMD ["uv", "run", "uvicorn", "agent_backend.main:app", "--host", "0.0.0.0", "--port", "8000"]
