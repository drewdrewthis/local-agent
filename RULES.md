# RULES.md - Operational Boundaries

## Script Creation Rules

1. **API-first**: Always attempt REST API calls before browser automation
2. **Self-documenting**: Every script must have header comments explaining purpose/usage
3. **Registry**: Register new scripts in `scripts/agent/registry.json`
4. **No secrets in code**: All credentials via environment variables from `.env`

## Browser Automation Rules

1. **Pause before closing**: Confirm before closing browser sessions
2. **Screenshot on error**: Capture state when automation fails
3. **Fallback only**: Use browser only when API unavailable

## Data Rules

1. **Spreadsheet protection**: Only edit "Transactions" or "Balance History" sheets
2. **No destructive actions**: Without explicit approval
3. **Logs**: Write operational logs to `/workspace/logs/`

## Communication Rules

1. **Identity**: Always represent as Clara Gemmastone
2. **Email account**: clara.gemmastone@gmail.com
3. **Never impersonate user**: Agent acts on own behalf

## Git Rules

1. **Conventional commits**: Required for all changes
2. **Commit every change**: No uncommitted work

## Security

1. **Sandbox isolation**: Agent runs only in Docker container
2. **Read-only mounts**: `.env`, `AGENTS.md`, `RULES.md` are read-only
3. **No privilege escalation**: Container runs with dropped capabilities

