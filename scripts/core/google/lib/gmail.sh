#!/bin/bash
# Gmail API Library
# Functions for Gmail operations: reading, archiving, sending

set -euo pipefail

# Load dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/api.sh"

# Configuration
readonly GMAIL_API_BASE="https://gmail.googleapis.com/gmail/v1/users/me"
readonly MAX_RESULTS_DEFAULT=50

# Logging
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $*" >&2; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }
log_debug() { [[ "${DEBUG:-false}" == "true" ]] && echo "[$(date +'%Y-%m-%d %H:%M:%S')] DEBUG: $*" >&2; }

# Get user profile
gmail_get_profile() {
    local response
    response=$(api_call "GET" "$GMAIL_API_BASE/profile")

    if [[ -n "$response" ]]; then
        echo "$response" | jq '.'
        return 0
    fi

    return 1
}

# List messages with filtering
gmail_list_messages() {
    local query="${1:-}"
    local max_results="${2:-$MAX_RESULTS_DEFAULT}"
    local label_ids="${3:-}"

    local url="$GMAIL_API_BASE/messages?maxResults=$max_results"

    if [[ -n "$query" ]]; then
        url="$url&q=$(url_encode "$query")"
    fi

    if [[ -n "$label_ids" ]]; then
        url="$url&labelIds=$(url_encode "$label_ids")"
    fi

    local response
    response=$(api_call "GET" "$url")

    if [[ -n "$response" ]]; then
        echo "$response"
        return 0
    fi

    return 1
}

# Get detailed message
gmail_get_message() {
    local message_id="$1"
    local format="${2:-full}"  # metadata, minimal, or full

    local url="$GMAIL_API_BASE/messages/$message_id?format=$format"

    local response
    response=$(api_call "GET" "$url")

    if [[ -n "$response" ]]; then
        echo "$response"
        return 0
    fi

    return 1
}

# Archive message (remove INBOX label)
gmail_archive_message() {
    local message_id="$1"

    local data='{"removeLabelIds": ["INBOX"]}'

    local response
    response=$(api_call "POST" "$GMAIL_API_BASE/messages/$message_id/modify" "$data")

    if [[ -n "$response" ]]; then
        log_info "Archived message: $message_id"
        echo "$response"
        return 0
    fi

    return 1
}

# Archive multiple messages
gmail_archive_messages() {
    local message_ids=("$@")

    if [[ ${#message_ids[@]} -eq 0 ]]; then
        log_error "No message IDs provided"
        return 1
    fi

    # Convert array to comma-separated string
    local ids_string
    printf -v ids_string '%s,' "${message_ids[@]}"
    ids_string="${ids_string%,}"

    local url="$GMAIL_API_BASE/messages/batchModify"
    local data="{\"removeLabelIds\": [\"INBOX\"], \"ids\": [\"${ids_string//,/\",\"}\"]}"

    local response
    response=$(api_call "POST" "$url" "$data")

    if [[ -n "$response" ]]; then
        log_info "Archived ${#message_ids[@]} messages"
        echo "$response"
        return 0
    fi

    return 1
}

# Send email
gmail_send_message() {
    local to="$1"
    local subject="$2"
    local body="$3"
    local from_name="${4:-Clara Gemmastone}"
    local from_email="${5:-clara.gemmastone@gmail.com}"

    # Validate inputs
    validate_email "$to" || return 1
    [[ -z "$subject" ]] && { log_error "Subject is required"; return 1; }
    [[ -z "$body" ]] && { log_error "Body is required"; return 1; }

    # Create RFC 5322 email
    local email_content
    email_content="From: $from_name <$from_email>
To: $to
Subject: $subject
Content-Type: text/plain; charset=UTF-8

$body"

    # Base64 encode (URL-safe)
    local encoded_email
    encoded_email=$(echo -e "$email_content" | base64 -w 0 | tr '/+' '_-' | tr -d '=')

    local data="{\"raw\": \"$encoded_email\"}"

    local response
    response=$(api_call "POST" "$GMAIL_API_BASE/messages/send" "$data")

    if [[ -n "$response" ]]; then
        log_info "Email sent successfully"
        echo "$response"
        return 0
    fi

    return 1
}

# Search messages
gmail_search() {
    local query="$1"
    local max_results="${2:-20}"

    [[ -z "$query" ]] && { log_error "Search query is required"; return 1; }

    gmail_list_messages "$query" "$max_results"
}

# Get unread count
gmail_get_unread_count() {
    local response
    response=$(gmail_list_messages "label:unread" "500")

    if [[ -n "$response" ]]; then
        local count
        count=$(safe_jq "$response" '.messages | length' "0")
        echo "$count"
        return 0
    fi

    return 1
}

# Mark message as read
gmail_mark_as_read() {
    local message_id="$1"

    local data='{"removeLabelIds": ["UNREAD"]}'

    local response
    response=$(api_call "POST" "$GMAIL_API_BASE/messages/$message_id/modify" "$data")

    if [[ -n "$response" ]]; then
        log_info "Marked message as read: $message_id"
        echo "$response"
        return 0
    fi

    return 1
}

# Get message thread
gmail_get_thread() {
    local thread_id="$1"

    local response
    response=$(api_call "GET" "$GMAIL_API_BASE/threads/$thread_id")

    if [[ -n "$response" ]]; then
        echo "$response"
        return 0
    fi

    return 1
}

# Format email for display
gmail_format_email() {
    local message_json="$1"

    local id subject from date snippet labels
    id=$(safe_jq "$message_json" ".id" "unknown")
    subject=$(extract_header "$message_json" "Subject")
    from=$(extract_header "$message_json" "From")
    date=$(extract_header "$message_json" "Date")
    snippet=$(safe_jq "$message_json" ".snippet" "")
    labels=$(safe_jq "$message_json" ".labelIds | join(\", \")" "")

    cat << EOF
ID: $id
From: ${from:-Unknown}
Subject: ${subject:-No Subject}
Date: ${date:-Unknown}
Labels: ${labels:-None}
Snippet: ${snippet:0:150}...

---
EOF
}

# Export functions for external use
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_error "This is a library file, not meant to be executed directly"
    exit 1
fi