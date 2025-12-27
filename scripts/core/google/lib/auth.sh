#!/bin/bash
# Google OAuth Authentication Library
# Handles token refresh, validation, and OAuth flows

set -euo pipefail

# Load environment if .env exists (search up directory tree)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Search for .env file starting from current directory and moving up
current_dir="$PWD"
while [[ "$current_dir" != "/" ]]; do
    if [[ -f "$current_dir/.env" ]]; then
        source "$current_dir/.env"
        break
    fi
    current_dir="$(dirname "$current_dir")"
done

# If .env not found, show helpful error
if [[ -z "${GOOGLE_CLIENT_ID:-}" ]]; then
    echo "ERROR: .env file not found. Please run this script from the project root directory." >&2
    echo "The .env file should be in the same directory as the main project files." >&2
    exit 1
fi

# Configuration
# Set defaults only if not already set
[[ -z "${TOKEN_EXPIRY_BUFFER:-}" ]] && TOKEN_EXPIRY_BUFFER=300  # 5 minutes buffer before expiry
[[ -z "${MAX_RETRY_ATTEMPTS:-}" ]] && MAX_RETRY_ATTEMPTS=3

# Token cache file (not readonly to allow override)
TOKEN_CACHE_FILE="${GOOGLE_TOKEN_CACHE:-/tmp/google_tokens.cache}"

# Logging
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $*" >&2; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }
log_debug() { [[ "${DEBUG:-false}" == "true" ]] && echo "[$(date +'%Y-%m-%d %H:%M:%S')] DEBUG: $*" >&2; }

# Validate required environment variables
validate_config() {
    local required_vars=("GOOGLE_CLIENT_ID" "GOOGLE_CLIENT_SECRET" "GOOGLE_REFRESH_TOKEN")

    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log_error "Missing required environment variable: $var"
            return 1
        fi
    done

    return 0
}

# Get cached access token
get_cached_token() {
    if [[ -f "$TOKEN_CACHE_FILE" ]]; then
        local cached_token cached_expiry
        cached_token=$(jq -r '.access_token // empty' "$TOKEN_CACHE_FILE" 2>/dev/null || echo "")
        cached_expiry=$(jq -r '.expires_at // 0' "$TOKEN_CACHE_FILE" 2>/dev/null || echo "0")

        if [[ -n "$cached_token" && "$cached_expiry" -gt $(($(date +%s) + TOKEN_EXPIRY_BUFFER)) ]]; then
            log_debug "Using cached access token"
            echo "$cached_token"
            return 0
        fi
    fi

    return 1
}

# Refresh access token
refresh_access_token() {
    local refresh_token="$1"
    local attempt=1

    while [[ $attempt -le $MAX_RETRY_ATTEMPTS ]]; do
        log_debug "Token refresh attempt $attempt/$MAX_RETRY_ATTEMPTS"

        local response
        response=$(curl -s -X POST https://oauth2.googleapis.com/token \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -d "client_id=$GOOGLE_CLIENT_ID&client_secret=$GOOGLE_CLIENT_SECRET&refresh_token=$refresh_token&grant_type=refresh_token")

        log_debug "Refresh response: $response"

        # Check for errors
        if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
            local error_msg
            error_msg=$(echo "$response" | jq -r '.error_description // .error')
            log_error "Token refresh failed: $error_msg"

            if [[ $error_msg == *"invalid_grant"* ]]; then
                log_error "Refresh token is invalid/expired. Need to reauthorize."
                return 1
            fi

            ((attempt++))
            sleep 1
            continue
        fi

        # Extract new tokens
        local access_token expires_in new_refresh_token
        access_token=$(echo "$response" | jq -r '.access_token')
        expires_in=$(echo "$response" | jq -r '.expires_in // 3600')
        new_refresh_token=$(echo "$response" | jq -r '.refresh_token // empty')

        if [[ -z "$access_token" ]]; then
            log_error "No access token received in response"
            return 1
        fi

        # Cache the token
        local expires_at=$(( $(date +%s) + expires_in ))
        local cache_data="{\"access_token\":\"$access_token\",\"expires_at\":$expires_at}"

        if [[ -n "$new_refresh_token" ]]; then
            cache_data=$(echo "$cache_data" | jq --arg rt "$new_refresh_token" '.refresh_token = $rt')
            log_info "Received new refresh token, updating .env"
            # Update .env file with new refresh token
            sed -i.bak "s/GOOGLE_REFRESH_TOKEN=.*/GOOGLE_REFRESH_TOKEN=$new_refresh_token/" .env 2>/dev/null || true
        fi

        echo "$cache_data" > "$TOKEN_CACHE_FILE"
        log_debug "Token cached successfully"

        echo "$access_token"
        return 0
    done

    log_error "Failed to refresh token after $MAX_RETRY_ATTEMPTS attempts"
    return 1
}

# Get valid access token (cached or refreshed)
get_access_token() {
    local force_refresh="${1:-false}"

    if [[ "$force_refresh" != "true" ]]; then
        local cached_token
        cached_token=$(get_cached_token)
        if [[ -n "$cached_token" ]]; then
            echo "$cached_token"
            return 0
        fi
    fi

    log_info "Refreshing access token..."
    local token
    token=$(refresh_access_token "$GOOGLE_REFRESH_TOKEN")
    if [[ -n "$token" ]]; then
        echo "$token"
        return 0
    fi

    log_error "Failed to obtain access token"
    return 1
}

# Validate token works with a test API call
validate_token() {
    local access_token="$1"

    # Test with Gmail API (lightweight call)
    local response
    response=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $access_token" \
        "https://gmail.googleapis.com/gmail/v1/users/me/profile" -o /dev/null)

    if [[ "$response" == "200" ]]; then
        log_debug "Token validation successful"
        return 0
    else
        log_error "Token validation failed (HTTP $response)"
        return 1
    fi
}

# Main token getter with validation
ensure_valid_token() {
    local force_refresh="${1:-false}"

    validate_config || return 1

    local token
    token=$(get_access_token "$force_refresh")
    if [[ -z "$token" ]]; then
        return 1
    fi

    if validate_token "$token"; then
        echo "$token"
        return 0
    else
        log_info "Cached token invalid, forcing refresh..."
        token=$(get_access_token "true")
        if [[ -n "$token" ]] && validate_token "$token"; then
            echo "$token"
            return 0
        fi
    fi

    return 1
}

# Clean up expired cache
cleanup_cache() {
    if [[ -f "$TOKEN_CACHE_FILE" ]]; then
        local expires_at
        expires_at=$(jq -r '.expires_at // 0' "$TOKEN_CACHE_FILE" 2>/dev/null || echo "0")

        if [[ $expires_at -lt $(date +%s) ]]; then
            log_debug "Removing expired token cache"
            rm -f "$TOKEN_CACHE_FILE"
        fi
    fi
}

# Initialize
cleanup_cache