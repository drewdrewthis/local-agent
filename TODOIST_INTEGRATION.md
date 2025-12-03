# Todoist API Integration

## Official CLI Status
- **No official Todoist CLI exists**
- Multiple unofficial CLIs available but not recommended for production use
- Direct API integration is the most reliable approach

## API Details
- **Base URL**: https://api.todoist.com/rest/v2/ (v1 is deprecated!)
- **Auth**: Bearer token in Authorization header
- **Token Location**: https://app.todoist.com/app/settings/integrations/developer

## Key Endpoints
- `GET /tasks` - List all tasks
- `POST /tasks` - Create task
- `POST /tasks/{id}/close` - Complete task
- `GET /projects` - List projects

## Implementation Notes
- **Use REST API v2** - v1 endpoints return deprecation warnings
- Handle rate limits (450 requests/hour for free tier)
- Store API token securely (env var, not hardcoded)
- Parse JSON responses for CLI output
- Field names changed in v2 (e.g., `is_completed` instead of `completed`)

## Usage Pattern
```bash
export TODOIST_TOKEN="your_token_here"
curl -H "Authorization: Bearer $TODOIST_TOKEN" https://api.todoist.com/rest/v2/tasks
```