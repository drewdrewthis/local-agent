#!/bin/bash
# Todoist Tasks Library
# Functions for task operations: create, read, update, delete

set -euo pipefail

# Load dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/api.sh"

# Logging
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $*" >&2; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }
log_debug() { [[ "${DEBUG:-false}" == "true" ]] && echo "[$(date +'%Y-%m-%d %H:%M:%S')] DEBUG: $*" >&2; }

# Get all tasks
tasks_get_all() {
    local filter="${1:-}"

    local endpoint="/tasks"
    if [[ -n "$filter" ]]; then
        endpoint="$endpoint?filter=$filter"
    fi

    local response
    response=$(api_call "GET" "$endpoint")

    if [[ -n "$response" ]]; then
        echo "$response"
        return 0
    fi

    return 1
}

# Get specific task
tasks_get() {
    local task_id="$1"

    validate_task_id "$task_id" || return 1

    local response
    response=$(api_call "GET" "/tasks/$task_id")

    if [[ -n "$response" ]]; then
        echo "$response"
        return 0
    fi

    return 1
}

# Create new task
tasks_create() {
    local content="$1"
    local priority="${2:-1}"
    local due_date="${3:-}"
    local project_id="${4:-}"
    local parent_id="${5:-}"
    local description="${6:-}"

    [[ -z "$content" ]] && { log_error "Task content is required"; return 1; }

    # Validate priority
    [[ ! "$priority" =~ ^[1-4]$ ]] && { log_error "Priority must be 1-4"; return 1; }

    # Build JSON payload
    local payload="{\"content\": \"$content\", \"priority\": $priority"

    if [[ -n "$due_date" ]]; then
        # Parse due date if it's not already in YYYY-MM-DD format
        if [[ ! "$due_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            due_date=$(parse_due_date "$due_date")
            [[ -z "$due_date" ]] && return 1
        fi
        payload="$payload, \"due_date\": \"$due_date\""
    fi

    if [[ -n "$project_id" ]]; then
        payload="$payload, \"project_id\": \"$project_id\""
    fi

    if [[ -n "$parent_id" ]]; then
        payload="$payload, \"parent_id\": \"$parent_id\""
    fi

    if [[ -n "$description" ]]; then
        payload="$payload, \"description\": \"$description\""
    fi

    payload="$payload}"

    local response
    response=$(api_call "POST" "/tasks" "$payload")

    if [[ -n "$response" ]]; then
        local task_id
        task_id=$(safe_jq "$response" ".id")
        log_info "Created task: $content (ID: $task_id)"
        echo "$response"
        return 0
    fi

    return 1
}

# Update task
tasks_update() {
    local task_id="$1"
    local updates="$2"

    validate_task_id "$task_id" || return 1
    [[ -z "$updates" ]] && { log_error "Updates are required"; return 1; }

    local response
    response=$(api_call "POST" "/tasks/$task_id" "$updates")

    if [[ -n "$response" ]]; then
        log_info "Updated task: $task_id"
        echo "$response"
        return 0
    fi

    return 1
}

# Complete task
tasks_complete() {
    local task_id="$1"

    validate_task_id "$task_id" || return 1

    local response
    response=$(api_call "POST" "/tasks/$task_id/close")

    # Close endpoint returns 204 No Content on success
    if [[ $? -eq 0 ]]; then
        log_info "Completed task: $task_id"
        return 0
    fi

    return 1
}

# Reopen task
tasks_reopen() {
    local task_id="$1"

    validate_task_id "$task_id" || return 1

    local response
    response=$(api_call "POST" "/tasks/$task_id/reopen")

    if [[ -n "$response" ]]; then
        log_info "Reopened task: $task_id"
        echo "$response"
        return 0
    fi

    return 1
}

# Delete task
tasks_delete() {
    local task_id="$1"

    validate_task_id "$task_id" || return 1

    local response
    response=$(api_call "DELETE" "/tasks/$task_id")

    # DELETE returns 204 No Content on success
    if [[ $? -eq 0 ]]; then
        log_info "Deleted task: $task_id"
        return 0
    fi

    return 1
}

# Search tasks by content
tasks_search() {
    local query="$1"
    local limit="${2:-50}"

    [[ -z "$query" ]] && { log_error "Search query is required"; return 1; }

    # Use filter parameter for searching
    local filter
    filter=$(printf 'search: "%s"' "$query")

    tasks_get_all "$filter"
}

# Get tasks by project
tasks_by_project() {
    local project_id="$1"

    [[ -z "$project_id" ]] && { log_error "Project ID is required"; return 1; }

    local filter="#$project_id"
    tasks_get_all "$filter"
}

# Get overdue tasks
tasks_overdue() {
    local filter="overdue"
    tasks_get_all "$filter"
}

# Get tasks due today
tasks_due_today() {
    local filter="today"
    tasks_get_all "$filter"
}

# Get tasks due tomorrow
tasks_due_tomorrow() {
    local filter="tomorrow"
    tasks_get_all "$filter"
}

# Get high priority tasks
tasks_high_priority() {
    local filter="priority 3"
    tasks_get_all "$filter"
}

# Get urgent tasks
tasks_urgent() {
    local filter="priority 4"
    tasks_get_all "$filter"
}

# Update task priority
tasks_set_priority() {
    local task_id="$1"
    local priority="$2"

    validate_task_id "$task_id" || return 1
    [[ ! "$priority" =~ ^[1-4]$ ]] && { log_error "Priority must be 1-4"; return 1; }

    local updates="{\"priority\": $priority}"
    tasks_update "$task_id" "$updates"
}

# Update task due date
tasks_set_due_date() {
    local task_id="$1"
    local due_date="$2"

    validate_task_id "$task_id" || return 1
    [[ -z "$due_date" ]] && { log_error "Due date is required"; return 1; }

    due_date=$(parse_due_date "$due_date")
    [[ -z "$due_date" ]] && return 1

    local updates="{\"due_date\": \"$due_date\"}"
    tasks_update "$task_id" "$updates"
}

# Update task content
tasks_set_content() {
    local task_id="$1"
    local content="$2"

    validate_task_id "$task_id" || return 1
    [[ -z "$content" ]] && { log_error "Content is required"; return 1; }

    local updates="{\"content\": \"$content\"}"
    tasks_update "$task_id" "$updates"
}

# Get task comments
tasks_get_comments() {
    local task_id="$1"

    validate_task_id "$task_id" || return 1

    local response
    response=$(api_call "GET" "/tasks/$task_id/comments")

    if [[ -n "$response" ]]; then
        echo "$response"
        return 0
    fi

    return 1
}

# Add comment to task
tasks_add_comment() {
    local task_id="$1"
    local content="$2"

    validate_task_id "$task_id" || return 1
    [[ -z "$content" ]] && { log_error "Comment content is required"; return 1; }

    local payload="{\"content\": \"$content\"}"

    local response
    response=$(api_call "POST" "/tasks/$task_id/comments" "$payload")

    if [[ -n "$response" ]]; then
        log_info "Added comment to task: $task_id"
        echo "$response"
        return 0
    fi

    return 1
}

# Export functions for external use
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_error "This is a library file, not meant to be executed directly"
    exit 1
fi