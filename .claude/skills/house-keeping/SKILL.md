---
name: house-keeping
description: Repo structure, conventions, and organization - the sherpa for where things go
argument-hint: [question or task]
allowed-tools: Read, Write, Bash, Edit, Glob, Grep
---

# House-Keeping (Sherpa)

You are the sherpa for this repo. You own the structure, conventions, and organization.

## Repo Structure

```
local-agent/
├── .vault/                     # Everything personal (encrypted)
│   ├── context.md.age          # Life situation, goals
│   ├── journal/                # Session logs: done, decided, learned, open, feeling
│   ├── docs/                   # Projects, plans, reference material
│   │   ├── projects/
│   │   └── budget-tracking.md
│   └── secrets/
│       └── env.age             # API tokens
├── .claude/
│   └── skills/                 # Claude Code skills only
│       ├── check-in/
│       └── house-keeping/
├── scripts/                    # Automation code
├── AGENTS.md                   # Agent rules
├── CLAUDE.md                   # References AGENTS.md
└── .env                        # Decrypted tokens (gitignored)
```

## The Split

- **`.vault/`** = everything about Drew (personal, encrypted)
- **Everything else** = operational (how Claude works, not personal)

## Conventions

### `.vault/` - Personal (Encrypted)
All personal data, encrypted with `age`:
- `context.md` - Life situation, goals
- `journal/` - Session logs (done, decided, learned, open, feeling)
- `docs/` - Projects, plans, reference material
- `secrets/` - API tokens

### `.claude/skills/` - Skills Only
Official Claude Code directory. Only skills (SKILL.md files).

### `scripts/` - Automation
Code organized by integration (google, todoist, secrets).

### Root Level
- `AGENTS.md` - All agent rules
- `CLAUDE.md` - References AGENTS.md
- `.env` - Decrypted secrets (gitignored)

## Decision Framework

1. **Is it about Drew?** → `.vault/` (encrypt it)
2. **Is it a skill?** → `.claude/skills/`
3. **Is it automation code?** → `scripts/`
4. **Is it agent config?** → `AGENTS.md`

## Encryption

```bash
# Encrypt
age -e -p -o file.age file.md && rm file.md

# Decrypt
age -d file.age > file.md

# Helpers
./scripts/secrets/encrypt
./scripts/secrets/decrypt
```
