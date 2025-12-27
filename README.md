# Clara Sandbox

Sandboxed environment for cursor-cli autonomous coding agent.

## What This Is

This repo **is the workspace** for cursor-cli. The agent:

- Runs inside this Docker container
- Has full filesystem access (within container)
- Writes and maintains its own scripts
- Commits and pushes changes to evolve itself
- Uses Playwright MCP for headed browser automation
- Accesses Google/Todoist APIs via bash scripts it maintains

## Structure

```
├── AGENTS.md          # Agent identity (Clara Gemmastone)
├── RULES.md           # Operational boundaries
├── scripts/           # Agent-maintained automation
│   ├── google/        # Gmail, Calendar, Sheets, Drive APIs
│   ├── todoist/       # Task management API
│   └── custom/        # Any scripts agent creates
└── agent-notes/       # Agent knowledge base
```

## Running

```bash
make build    # Build container
make start    # Start (VNC at http://localhost:6080)
make shell    # Shell into container
```

## Environment

`.env` contains API credentials (not committed):

```
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
GOOGLE_REFRESH_TOKEN=...
TODOIST_TOKEN=...
```

## Agent Capabilities

- **Browser**: Playwright headed via VNC (port 6080)
- **APIs**: Google (Gmail, Calendar, Sheets, Drive), Todoist
- **Git**: Full commit/push access to this repo
- **Scripts**: Creates and maintains bash automation
