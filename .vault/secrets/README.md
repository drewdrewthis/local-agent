# Encrypted Secrets

This directory contains encrypted sensitive files using `age`.

## Setup on a new device

1. Clone the repo
2. Run `./scripts/secrets/decrypt`
3. Enter the password when prompted

## After changing sensitive files

Run `./scripts/secrets/encrypt` to update the encrypted versions, then commit.

## Files

- `env.age` - API tokens (.env)
- `life-context.md.age` - Personal context (agent-notes/life-context.md)
