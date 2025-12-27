# Todoist CLI Library

A comprehensive command-line interface for Todoist task management with batch operations, filtering, and automation capabilities.

## Features

- 🚀 **Fast task operations**: Add, complete, delete, search
- 📊 **Smart filtering**: Overdue, today, priority-based, custom queries
- 🔄 **Batch operations**: Handle multiple tasks at once
- 🏗️ **Project management**: List and manage projects
- 📅 **Due date handling**: Flexible date parsing and formatting
- 🛡️ **Error handling**: Robust API error management and retries
- 📝 **Detailed logging**: Debug and audit capabilities

## Quick Start

### Prerequisites

- Todoist API token (get from https://app.todoist.com/app/settings/integrations/developer)
- `curl`, `jq` installed
- `.env` file with `TODOIST_TOKEN=your_token_here`

### Basic Usage

```bash
# Add a task
./scripts/todoist/bin/todoist add "Buy groceries" -p 2 -d tomorrow

# List today's tasks
./scripts/todoist/bin/todoist today

# Complete tasks
./scripts/todoist/bin/todoist complete 123456789

# Search for tasks
./scripts/todoist/bin/todoist search "NY trip"

# Quick add (minimal typing)
./scripts/todoist/bin/todoist-quick-add -p 3 "Call dentist urgently"
```

## Library Structure

```
scripts/todoist/
├── lib/           # Core library files
│   ├── auth.sh    # API authentication
│   ├── api.sh     # Common API utilities
│   ├── tasks.sh   # Task operations
│   ├── projects.sh # Project management
│   └── utils.sh   # Logging and helpers
├── bin/           # Executable scripts
│   ├── todoist       # Main CLI tool
│   └── todoist-quick-add # Fast task adding
├── config/        # Configuration (future)
└── README.md      # This file
```

## Main Commands

### Task Management

```bash
# Add tasks
todoist add "Task content" -p 3 -d tomorrow
todoist add "Subtask" --parent 123456789

# List tasks
todoist list                    # All tasks
todoist list --filter today     # Today's tasks
todoist list --filter overdue   # Overdue tasks

# Quick lists
todoist today      # Today's tasks
todoist tomorrow   # Tomorrow's tasks
todoist overdue    # Overdue tasks
todoist urgent     # Priority 4 tasks

# Complete tasks
todoist complete 123456789 987654321
todoist done 123456789    # Alias

# Delete tasks
todoist delete 123456789
todoist rm 123456789      # Alias

# Search tasks
todoist search "meeting"
```

### Project Management

```bash
# List all projects
todoist projects
```

## Advanced Usage

### Batch Operations

```bash
# Complete multiple tasks
todoist complete 111 222 333 --no-confirm

# Delete multiple tasks
todoist delete 111 222 333 --no-confirm
```

### Priority and Due Dates

```bash
# Priority levels: 1=Low, 2=Medium, 3=High, 4=Urgent
todoist add "Urgent task" -p 4

# Due date formats
todoist add "Task" -d 2025-12-25     # Specific date
todoist add "Task" -d today          # Today
todoist add "Task" -d tomorrow       # Tomorrow
todoist add "Task" -d yesterday      # Yesterday
```

### Filtering and Search

```bash
# Filter examples
todoist list --filter "today"        # Due today
todoist list --filter "overdue"      # Overdue tasks
todoist list --filter "priority 4"   # Urgent tasks
todoist list --filter "#project"     # Tasks in specific project

# Search by content
todoist search "meeting"             # Tasks containing "meeting"
todoist search "NY trip"             # Tasks about NY trip
```

## Configuration

### Environment Variables

- `TODOIST_TOKEN`: Your Todoist API token (required)
- `DEBUG=true`: Enable debug logging
- `LOG_TO_FILE=true`: Write logs to file
- `NON_INTERACTIVE=true`: Skip confirmation prompts

### Logging

Logs are written to `logs/todoist_integration.log` with automatic rotation.

```bash
# Enable debug mode
DEBUG=true todoist list

# View recent logs
tail -f logs/todoist_integration.log
```

## Library API

### Task Functions

```bash
tasks_create "content" priority due_date project_id parent_id
tasks_get_all [filter]
tasks_get task_id
tasks_complete task_id
tasks_delete task_id
tasks_search "query"
tasks_update task_id updates_json
```

### Project Functions

```bash
projects_get_all
projects_get project_id
projects_create "name" [parent_id]
```

### Utility Functions

```bash
format_task task_json      # Pretty print task
validate_task_id id        # Check if valid ID
parse_due_date "date"      # Parse various date formats
```

## Error Handling

The library includes comprehensive error handling:

- **API retries** for transient failures
- **Token validation** with automatic refresh attempts
- **Input validation** for dates and task IDs
- **Meaningful error messages** for troubleshooting
- **Graceful degradation** when API is unavailable

## Examples

### Daily Workflow

```bash
# Morning: Check today's tasks
todoist today

# Add new tasks
todoist add "Review quarterly reports" -p 3 -d today
todoist add "Team standup" -p 2 -d today

# Complete finished tasks
todoist complete 123456789

# Evening: Review progress
todoist overdue
```

### Project Management

```bash
# Check all projects
todoist projects

# Add tasks to specific project
todoist add "Design mockups" --project "Website Redesign"
```

### Batch Operations

```bash
# Complete all tasks from a search
todoist search "meeting"  # Find task IDs
todoist complete 111 222 333 --no-confirm
```

## Contributing

When adding new features:

1. Follow existing patterns in the library files
2. Add comprehensive error handling
3. Update command-line help text
4. Test with various scenarios
5. Update this README

## Security

- API tokens are read from `.env` file only
- No sensitive data is logged
- HTTPS-only API communication
- Input validation prevents injection attacks

---

**Built for efficient Todoist task management from the command line** ⚡