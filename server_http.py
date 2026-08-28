"""
Thin wrapper around uukelele/scratch-mcp so it can run as a remote
MCP server (Streamable HTTP) on platforms like Render.

Original server only exposes stdio. This process:
1. Restores any persisted Scratch sessions from disk
2. Starts FastMCP with transport="streamable-http" (or SSE)
   bound to 0.0.0.0 and the PORT provided by the host.
"""

from __future__ import annotations

import os
import sys

# Make sure the cloned package is importable
sys.path.insert(0, "/app/scratch-mcp")

from scratch_mcp.server import mcp  # noqa: E402
from scratch_mcp.utils import _restore  # noqa: E402

# Import side-effect modules that register all the tools
import scratch_mcp.projects  # noqa: E402, F401
import scratch_mcp.social  # noqa: E402, F401


def main() -> None:
    _restore()

    host = os.getenv("FASTMCP_HOST", "0.0.0.0")
    port = int(os.getenv("PORT") or os.getenv("FASTMCP_PORT") or "8000")
    transport = os.getenv("FASTMCP_TRANSPORT", "streamable-http")
    path = os.getenv("FASTMCP_STREAMABLE_HTTP_PATH", "/mcp")

    # FastMCP 3.x accepts these kwargs; older versions fall back to settings
    run_kwargs = {
        "transport": transport,
        "host": host,
        "port": port,
    }

    # Prefer streamable-http path when supported
    if transport in ("streamable-http", "http"):
        run_kwargs["path"] = path

    print(f"Starting Scratch MCP on {transport}://{host}:{port}{path}", flush=True)
    mcp.run(**run_kwargs)


if __name__ == "__main__":
    main()
