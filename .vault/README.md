# .vault

Everything personal. Encrypted with `age`.

## Structure

```
.vault/
├── context.md.age    # Life situation, goals
├── journal/          # Session logs (done, decided, learned, open, feeling)
├── docs/             # Projects, plans, reference
└── secrets/
    └── env.age       # API tokens
```

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

## Sync

Encrypted files are safe to commit:
```bash
git add .vault/
git commit -m "vault update"
git push
```
