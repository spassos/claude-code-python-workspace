# ============================================================
# Multi-stage Dockerfile for Python Cloud Run services
#
# Usage:
#   Build for production: docker build --target production -t my-app .
#   Build for dev:        docker build --target development -t my-app-dev .
#
# Adapt:
#   - Replace <APP_MODULE> with your module name (e.g. "app.main:app")
#   - Replace <APP_NAME> with your package name (e.g. "my_app")
#   - Adjust Python version if needed
# ============================================================

# ── Stage 1: builder ────────────────────────────────────────
FROM python:3.12-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry (or use pip/uv — adapt as needed)
# Option A: Poetry
# ENV POETRY_VERSION=1.8.3
# RUN pip install poetry==$POETRY_VERSION
# COPY pyproject.toml poetry.lock ./
# RUN poetry config virtualenvs.create false \
#     && poetry install --only main --no-interaction --no-ansi

# Option B: pip with pyproject.toml extras
COPY pyproject.toml ./
# If you have a requirements.txt generated from pyproject.toml:
# COPY requirements.txt ./
# RUN pip install --no-cache-dir -r requirements.txt

# Option C: uv (fastest)
# RUN pip install uv
# COPY pyproject.toml uv.lock ./
# RUN uv sync --no-dev

RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -e "."

# Copy application source
COPY src/ ./src/


# ── Stage 2: production ─────────────────────────────────────
FROM python:3.12-slim AS production

# Security: run as non-root user
RUN groupadd --gid 1001 appgroup \
    && useradd --uid 1001 --gid 1001 --no-create-home appuser

WORKDIR /app

# Copy only the installed packages and source from builder
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /app/src ./src

# Cloud Run: must listen on $PORT (default 8080)
ENV PORT=8080

# Switch to non-root user
USER appuser

# Expose the port (documentation only — Cloud Run uses $PORT)
EXPOSE 8080

# Health check (optional — Cloud Run has its own probe)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:${PORT}/health')"

# Start command
# Replace <APP_MODULE> with your actual module path, e.g. "app.main:app"
CMD ["python", "-m", "uvicorn", "<APP_MODULE>", "--host", "0.0.0.0", "--port", "8080"]


# ── Stage 3: development (optional) ─────────────────────────
FROM builder AS development

# Install dev dependencies
# Poetry: poetry install --with dev
# pip:    pip install -e ".[dev]"
RUN pip install --no-cache-dir -e ".[dev]"

# Run with auto-reload for local development
CMD ["python", "-m", "uvicorn", "<APP_MODULE>", "--host", "0.0.0.0", "--port", "8080", "--reload"]
