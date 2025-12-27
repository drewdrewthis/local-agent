#!/bin/bash
# Todoist Projects Library
# Functions for project and section operations

set -euo pipefail

# Load dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/api.sh"

# Logging
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $*" >&2; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }
log_debug() { [[ "${DEBUG:-false}" == "true" ]] && echo "[$(date +'%Y-%m-%d %H:%M:%S')] DEBUG: $*" >&2; }

# Get all projects
projects_get_all() {
    local response
    response=$(api_call "GET" "/projects")

    if [[ -n "$response" ]]; then
        echo "$response"
        return 0
    fi

    return 1
}

# Get specific project
projects_get() {
    local project_id="$1"

    [[ -z "$project_id" ]] && { log_error "Project ID is required"; return 1; }

    local response
    response=$(api_call "GET" "/projects/$project_id")

    if [[ -n "$response" ]]; then
        echo "$response"
        return 0
    fi

    return 1
}

# Create new project
projects_create() {
    local name="$1"
    local parent_id="${2:-}"

    [[ -z "$name" ]] && { log_error "Project name is required"; return 1; }

    local payload="{\"name\": \"$name\"}"

    if [[ -n "$parent_id" ]]; then
        payload="{\"name\": \"$name\", \"parent_id\": \"$parent_id\"}"
    fi

    local response
    response=$(api_call "POST" "/projects" "$payload")

    if [[ -n "$response" ]]; then
        local project_id
        project_id=$(safe_jq "$response" ".id")
        log_info "Created project: $name (ID: $project_id)"
        echo "$response"
        return 0
    fi

    return 1
}

# Update project
projects_update() {
    local project_id="$1"
    local updates="$2"

    [[ -z "$project_id" ]] && { log_error "Project ID is required"; return 1; }
    [[ -z "$updates" ]] && { log_error "Updates are required"; return 1; }

    local response
    response=$(api_call "POST" "/projects/$project_id" "$updates")

    if [[ -n "$response" ]]; then
        log_info "Updated project: $project_id"
        echo "$response"
        return 0
    fi

    return 1
}

# Delete project
projects_delete() {
    local project_id="$1"

    [[ -z "$project_id" ]] && { log_error "Project ID is required"; return 1; }

    local response
    response=$(api_call "DELETE" "/projects/$project_id")

    # DELETE returns 204 No Content on success
    if [[ $? -eq 0 ]]; then
        log_info "Deleted project: $project_id"
        return 0
    fi

    return 1
}

# Get project sections
projects_get_sections() {
    local project_id="$1"

    [[ -z "$project_id" ]] && { log_error "Project ID is required"; return 1; }

    local response
    response=$(api_call "GET" "/projects/$project_id/sections")

    if [[ -n "$response" ]]; then
        echo "$response"
        return 0
    fi

    return 1
}

# Create section in project
projects_create_section() {
    local project_id="$1"
    local name="$2"

    [[ -z "$project_id" ]] && { log_error "Project ID is required"; return 1; }
    [[ -z "$name" ]] && { log_error "Section name is required"; return 1; }

    local payload="{\"name\": \"$name\", \"project_id\": \"$project_id\"}"

    local response
    response=$(api_call "POST" "/sections" "$payload")

    if [[ -n "$response" ]]; then
        local section_id
        section_id=$(safe_jq "$response" ".id")
        log_info "Created section: $name (ID: $section_id)"
        echo "$response"
        return 0
    fi

    return 1
}

# Get project collaborators
projects_get_collaborators() {
    local project_id="$1"

    [[ -z "$project_id" ]] && { log_error "Project ID is required"; return 1; }

    local response
    response=$(api_call "GET" "/projects/$project_id/collaborators")

    if [[ -n "$response" ]]; then
        echo "$response"
        return 0
    fi

    return 1
}

# Format project for display
format_project() {
    local project_json="$1"

    local id name color parent_id
    id=$(safe_jq "$project_json" ".id" "unknown")
    name=$(safe_jq "$project_json" ".name" "Unknown")
    color=$(safe_jq "$project_json" ".color" "")
    parent_id=$(safe_jq "$project_json" ".parent_id" "")

    printf "%-12s | %-30s | %-10s | %s\n" \
        "$id" "$name" "${color:-default}" "${parent_id:-root}"
}

# Find project by name
projects_find_by_name() {
    local project_name="$1"

    [[ -z "$project_name" ]] && { log_error "Project name is required"; return 1; }

    local projects
    projects=$(projects_get_all)

    if [[ -z "$projects" ]]; then
        return 1
    fi

    echo "$projects" | jq -r ".[] | select(.name == \"$project_name\") | .id" 2>/dev/null
}

# Export functions for external use
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_error "This is a library file, not meant to be executed directly"
    exit 1
fi