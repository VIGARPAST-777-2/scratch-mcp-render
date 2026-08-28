FROM python:3.13-slim

# System deps for potential native extensions and healthchecks
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install uv for fast dependency management
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Clone the upstream scratch-mcp (powered by scratchattach) at a pinned commit
# for reproducibility. Update the commit SHA when you want a newer version.
ARG SCRATCH_MCP_REF=main
RUN git clone --depth 1 --branch ${SCRATCH_MCP_REF} https://github.com/uukelele/scratch-mcp.git /app/scratch-mcp \
    && cd /app/scratch-mcp \
    && uv sync --frozen --no-dev || uv sync --no-dev

# Our thin wrapper that forces Streamable HTTP transport for remote/Render use
COPY server_http.py /app/server_http.py
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Persist session data outside the image layer (Render disk or volume)
ENV SCRATCH_MCP_DATA_DIR=/data
ENV PYTHONPATH=/app/scratch-mcp
ENV PATH="/app/scratch-mcp/.venv/bin:$PATH"

# Render injects PORT; FastMCP reads FASTMCP_PORT / host settings
ENV FASTMCP_HOST=0.0.0.0
ENV FASTMCP_TRANSPORT=streamable-http
ENV FASTMCP_STREAMABLE_HTTP_PATH=/mcp
ENV FASTMCP_STATELESS_HTTP=true

# Create data dir
RUN mkdir -p /data

EXPOSE 8000

# Healthcheck for Render
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
  CMD curl -f http://localhost:${PORT:-8000}/mcp || curl -f http://localhost:${PORT:-8000}/health || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]
