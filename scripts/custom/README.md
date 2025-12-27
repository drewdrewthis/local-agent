# Agent Scripts

Scripts in this directory are created and maintained by the agent (Clara Gemmastone).

## Convention

Every script must:
1. Have a header block with purpose, usage, and creation date
2. Be registered in `registry.json`
3. Use API-first approach (REST before browser)
4. Source shared libraries from `../core/`

## Creating New Scripts

```bash
agent-new-script my-script-name
```

## Registry Format

```json
{
  "scripts": [
    {
      "name": "example.sh",
      "purpose": "Brief description",
      "created": "2025-01-01",
      "apis": ["gmail", "todoist"],
      "requires_browser": false
    }
  ]
}
```

