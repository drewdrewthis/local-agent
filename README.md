# Clara Gemmastone Agent

Autonomous agent running in a sandboxed Docker environment with headed browser access.

## Architecture

```
local-agent/           ← This repo (mounted into container)
├── AGENTS.md          # Agent identity and rules
├── RULES.md           # Operational boundaries
├── scripts/
│   ├── core/          # Human-maintained API scripts
│   │   ├── google/    # Gmail, Calendar, Sheets, Drive
│   │   └── todoist/   # Task management
│   └── agent/         # Agent-written scripts (self-modifying)
│       └── registry.json
└── agent-notes/       # Agent knowledge base
```

## Container Capabilities

- **Playwright headed browser** via VNC (port 6080)
- **Google APIs**: Gmail, Calendar, Sheets, Drive
- **Todoist API**: Task management
- **Git write access**: Agent can commit/push to this repo
- **Self-modifying scripts**: Agent maintains `scripts/agent/`

## Usage

```bash
# Build and start
make build
make start

# Access VNC browser
open http://localhost:6080

# Shell into container
make shell

# Test API connectivity
make test-apis
```

## Agent Script Convention

Scripts in `scripts/agent/` must:
1. Have header comments with purpose/usage
2. Be registered in `registry.json`
3. Use APIs first, browser as fallback

## Environment

Create `.env` with:
```
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
GOOGLE_REFRESH_TOKEN=...
TODOIST_TOKEN=...
```

