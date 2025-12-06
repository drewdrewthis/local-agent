#!/bin/bash
# Todoist API Authentication Library
# Handles API tokens and authentication

set -euo pipefail

# Load environment if .env exists and variables not already set
if [[ -f ".env" ]] && [[ -z "${TODOIST_TOKEN:-}" ]]; then
    source .env
fi

# Configuration
if [[ -z "${TODOIST_API_BASE:-}" ]]; then
    readonly TODOIST_API_BASE="https://api.todoist.com/rest/v2"
fi
if [[ -z "${TOKEN_CACHE_FILE:-}" ]]; then
    readonly TOKEN_CACHE_FILE="${TODOIST_TOKEN_CACHE:-/tmp/todoist_token.cache}"
fi

# Logging
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $*" >&2; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }
log_debug() { [[ "${DEBUG:-false}" == "true" ]] && echo "[$(date +'%Y-%m-%d %H:%M:%S')] DEBUG: $*" >&2; }

# Validate required environment variables
validate_config() {
    if [[ -z "${TODOIST_TOKEN:-}" ]]; then
        log_error "Missing required environment variable: TODOIST_TOKEN"
        log_error "Set TODOIST_TOKEN in your .env file"
        log_error "Get token from: https://app.todoist.com/app/settings/integrations/developer"
        return 1
    fi

    return 0
}

# Test token validity
validate_token() {
    local token="$1"

    local response
    response=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $token" \
        "$TODOIST_API_BASE/projects" -o /dev/null)

    if [[ "$response" == "200" ]]; then
        log_debug "Token validation successful"
        return 0
    else
        log_error "Token validation failed (HTTP $response)"
        return 1
    fi
}

# Ensure valid token is available
ensure_valid_token() {
    validate_config || return 1

    if validate_token "$TODOIST_TOKEN"; then
        echo "$TODOIST_TOKEN"
        return 0
    else
        log_error "Invalid Todoist token"
        return 1
    fi
}

# Export functions for external use
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_error "This is a library file, not meant to be executed directly"
    exit 1
fi