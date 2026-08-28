#!/bin/bash
set -euo pipefail

# Render (and most PaaS) inject PORT. Make sure FastMCP sees it.
export PORT="${PORT:-8000}"
export FASTMCP_PORT="$PORT"
export FASTMCP_HOST="${FASTMCP_HOST:-0.0.0.0}"
export FASTMCP_TRANSPORT="${FASTMCP_TRANSPORT:-streamable-http}"
export SCRATCH_MCP_DATA_DIR="${SCRATCH_MCP_DATA_DIR:-/data}"

mkdir -p "$SCRATCH_MCP_DATA_DIR"

cd /app
exec python /app/server_http.py
