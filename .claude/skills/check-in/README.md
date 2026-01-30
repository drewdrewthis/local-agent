# Check-In Skill

Daily check-in ritual for maintaining continuity across sessions and devices.

## Usage

```
/check-in           # Default check-in
/check-in morning   # Morning focus
/check-in evening   # Evening reflection
```

## Journal Format

Session logs in `.vault/journal/` track:
- **Done** - actions taken, tasks completed
- **Decided** - choices made, directions chosen
- **Learned** - new info, context discovered
- **Open** - unresolved items for next time
- **Feeling** - user status (optional)

## Encryption

Journal entries are encrypted with `age`:
```bash
age -e -p -o .vault/journal/2026-01-30.md.age draft.md
```

Push to sync across devices.
