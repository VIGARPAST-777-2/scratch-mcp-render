# scratch-mcp-render

**MCP Server for Scratch**, based on the excellent open-source project [uukelele/scratch-mcp](https://github.com/uukelele/scratch-mcp) (powered by [scratchattach](https://github.com/TimMcCool/scratchattach)).

This repository packages it so you can deploy it as a **Web Service on Render** (or any Docker host) using **Streamable HTTP** transport. Agents (Cursor, Claude Desktop, etc.) can then connect to it remotely instead of running the stdio server locally.

> Upstream: [https://github.com/uukelele/scratch-mcp](https://github.com/uukelele/scratch-mcp)  
> Credits: uukelele, TimMcCool / scratchattach, aspizu (goboscript / sb2gs)

## What you get

All the tools from the original MCP:

- **Sessions** – login with username/password, session id, or browser cookie
- **Profile** – bio, “what I’m working on”, profile picture
- **Reading Scratch** – user/project info, search, inbox
- **Comments** – read / post / reply on projects, studios, profiles
- **Social actions** – follow, love, favourite, studios, become Scratcher
- **Project lifecycle** – new / open / download / build / publish with goboscript
- **Assets** – costumes & sounds

See the [upstream README](https://github.com/uukelele/scratch-mcp) for the full tool table and agent workflow notes.

## Deploy on Render (recommended)

1. Fork or use this repo.
2. Go to [Render Dashboard](https://dashboard.render.com) → **New** → **Web Service**.
3. Connect the GitHub repository.
4. Settings:
   - **Runtime**: Docker
   - **Dockerfile Path**: `./Dockerfile`
   - **Instance type**: Free (or any paid plan)
5. (Optional but recommended) Add a **Persistent Disk** mounted at `/data` so Scratch sessions survive restarts.
6. Environment variables (optional):

   | Variable | Default | Description |
   |----------|---------|-------------|
   | `FASTMCP_TRANSPORT` | `streamable-http` | `streamable-http` or `sse` |
   | `FASTMCP_HOST` | `0.0.0.0` | Bind address |
   | `SCRATCH_MCP_DATA_DIR` | `/data` | Where sessions.json is stored |
   | `PORT` | injected by Render | Do not override |

7. Deploy. After the build finishes your MCP endpoint will be:

   ```
   https://<your-service>.onrender.com/mcp
   ```

### Connect from an MCP client

**Cursor / Claude / any Streamable-HTTP client**:

```json
{
  "mcpServers": {
    "scratch": {
      "url": "https://<your-service>.onrender.com/mcp",
      "transport": "streamable-http"
    }
  }
}
```

Some older clients still use the SSE style:

```json
{
  "mcpServers": {
    "scratch": {
      "url": "https://<your-service>.onrender.com/sse",
      "transport": "sse"
    }
  }
}
```

(If you need pure SSE, set `FASTMCP_TRANSPORT=sse` in Render env vars.)

## Local Docker test

```bash
docker build -t scratch-mcp-render .
docker run --rm -p 8000:8000 \
  -e PORT=8000 \
  -v $(pwd)/data:/data \
  scratch-mcp-render
```

Then point your client at `http://localhost:8000/mcp`.

## Important notes for remote use

- **Authentication**: The original MCP expects the agent to call `social_connect_session` (username + password, session id, etc.). On a remote server the credentials travel over the network — use HTTPS (Render provides it) and treat the endpoint as sensitive.
- **Ephemeral filesystem**: On the free Render plan the container filesystem is ephemeral. Mount a disk at `/data` (or set `SCRATCH_MCP_DATA_DIR`) if you want sessions to persist across deploys.
- **goboscript / project building**: The Rust toolchain (goboscript + sb2gs) is **not** installed in this image by default (keeps the image small and build fast). Social tools work without it. If you need project creation/compilation, extend the Dockerfile with the Rust toolchain install steps from the upstream README.
- **Timeouts**: Compiling / publishing can take a long time; clients should allow generous timeouts (the upstream config uses 600 000 ms).

## Updating the upstream code

The Dockerfile clones `uukelele/scratch-mcp` at build time. To pin a specific commit or tag, change the `SCRATCH_MCP_REF` build-arg:

```dockerfile
ARG SCRATCH_MCP_REF=<commit-or-tag>
```

or pass it at build time:

```bash
docker build --build-arg SCRATCH_MCP_REF=abc1234 -t scratch-mcp-render .
```

## License

MIT (same as upstream). This packaging repo only adds the Docker/Render layer.
