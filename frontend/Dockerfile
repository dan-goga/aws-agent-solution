FROM python:3.14-slim

RUN pip install --no-cache-dir uv

WORKDIR /app

# Generate uv.lock locally first: `cd frontend && uv lock`
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

COPY src ./src
RUN uv sync --frozen --no-dev

EXPOSE 8501

CMD ["uv", "run", "streamlit", "run", "src/agent_frontend/app.py", "--server.port=8501", "--server.address=0.0.0.0"]
