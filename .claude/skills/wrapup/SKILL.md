---
name: wrapup
description: End-of-session ritual - journal update, calendar check, quick housekeeping
argument-hint: [optional notes about the day]
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Wrapup Skill

End-of-day/session ritual to capture progress and prepare for next time.

## What it does

1. **Journal Update** - Record what happened today
2. **Calendar Check** - Verify upcoming events, flag conflicts
3. **Quick Housekeeping** - Check repo state, uncommitted work
4. **Open Items** - Note anything unfinished for next session

## Journal Format

Update `.vault/journal/YYYY-MM-DD.md` with:

```markdown
---
date: YYYY-MM-DD
mood: [one or two words - tired, focused, anxious, good, etc.]
health: [if relevant - sick, recovering, fine]
tef_days: [days until Feb 14]
civics_days: [days until Feb 18]
tags: [relevant tags - study, setup, admin, personal, etc.]
---

# YYYY-MM-DD

## Feeling
[How they said they were feeling, or skip if not mentioned]

## Done
- [Concrete things accomplished]

## Decided
- [Decisions made]

## Learned
- [New information, insights]

## Open
- [Unfinished items, blockers, things for tomorrow]
```

## Calendar Check

Use Google Calendar MCP or scripts to:
- List events for next 3 days
- Flag any scheduling conflicts
- Remind about upcoming exams/deadlines

Key dates to always track:
- TEF exam: Feb 14, 2026
- Civics exam: Feb 18, 2026

## Housekeeping Check

Quick scan:
- Any uncommitted changes? (`git status`)
- Any stale files in scratchpad?
- Encryption up to date? (remind if .vault changed but not encrypted)

## Context Check

At the end, ask:
> **Context check:** Anything change about your situation, goals, or how you're feeling that should update context.md?

Only prompt - don't auto-update. The context doc (`.vault/context.md`) tracks life state, not daily events.

## Tone

- Keep it brief - they're wrapping up, not starting
- Celebrate wins, don't guilt about misses
- If they're burned out, acknowledge it and keep light

## Example Output

```
## Wrapup - Jan 31

**Done today:**
- Took civics baseline: 27/40 (68%)
- First ChatGPT tutor session - all 13 errors reviewed
- Set up encryption scripts, study tracking system

**Decided:**
- Focus on Système institutionnel first (most errors)
- Use ChatGPT GPT for combined civics + French practice

**Calendar next 3 days:**
- Feb 1: (nothing scheduled)
- Feb 2: (nothing scheduled)
- Feb 3: (nothing scheduled)
- ⚠️ TEF exam in 14 days

**Open:**
- Government structure deep-dive (next study session)
- Train ticket to book

**Repo:**
- ✓ All changes committed
- ✓ Vault encrypted

Good session. Rest up.
```

## When to use

User says things like:
- "let's wrap up"
- "I'm done for today"
- "/wrapup"
- "that's it for now"
