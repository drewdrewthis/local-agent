#!/bin/bash
# Google API Utilities Library
# Common functions for API calls, error handling, and data processing

set -euo pipefail

# Load auth library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/auth.sh"

# Configuration
readonly DEFAULT_TIMEOUT=30
readonly MAX_RETRIES=3

# Logging
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $*" >&2; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }
log_debug() { [[ "${DEBUG:-false}" == "true" ]] && echo "[$(date +'%Y-%m-%d %H:%M:%S')] DEBUG: $*" >&2; }

# Make authenticated API call with retry logic
api_call() {
    local method="${1:-GET}"
    local url="$2"
    local data="${3:-}"
    local timeout="${4:-$DEFAULT_TIMEOUT}"

    local attempt=1
    local response_code

    while [[ $attempt -le $MAX_RETRIES ]]; do
        log_debug "API call attempt $attempt/$MAX_RETRIES: $method $url"

        local token
        token=$(ensure_valid_token)
        if [[ -z "$token" ]]; then
            log_error "No valid access token available"
            return 1
        fi

        local curl_args=(-s -w "%{http_code}" -H "Authorization: Bearer $token")

        if [[ "$method" == "POST" ]] || [[ "$method" == "PUT" ]]; then
            curl_args+=(-X "$method" -H "Content-Type: application/json" -d "$data")
        elif [[ "$method" != "GET" ]]; then
            curl_args+=(-X "$method")
        fi

        curl_args+=(--max-time "$timeout" "$url")

        local response
        response=$(curl "${curl_args[@]}")

        response_code="${response: -3}"
        response_body="${response%???}"

        log_debug "Response code: $response_code"

        # Handle different response codes
        case "$response_code" in
            200|201|202|204)
                echo "$response_body"
                return 0
                ;;
            401)
                log_info "Token expired, forcing refresh..."
                ensure_valid_token "true" >/dev/null
                ((attempt++))
                continue
                ;;
            403)
                if echo "$response_body" | jq -e '.error.message' >/dev/null 2>&1; then
                    local error_msg
                    error_msg=$(echo "$response_body" | jq -r '.error.message')
                    if [[ "$error_msg" == *"insufficientPermissions"* ]]; then
                        log_error "Insufficient permissions. Check OAuth scopes."
                        return 1
                    fi
                fi
                ((attempt++))
                sleep 1
                continue
                ;;
            429)
                log_info "Rate limited, waiting before retry..."
                sleep $((attempt * 2))
                ((attempt++))
                continue
                ;;
            5*)
                log_error "Server error ($response_code), retrying..."
                sleep $attempt
                ((attempt++))
                continue
                ;;
            *)
                log_error "API call failed with HTTP $response_code: $response_body"
                return 1
                ;;
        esac
    done

    log_error "API call failed after $MAX_RETRIES attempts"
    return 1
}

# Safe JSON parsing with error handling
safe_jq() {
    local json="$1"
    local filter="$2"
    local default="${3:-}"

    if [[ -z "$json" ]]; then
        echo "$default"
        return 1
    fi

    local result
    result=$(echo "$json" | jq -r "$filter" 2>/dev/null || echo "")

    if [[ -z "$result" ]] && [[ -n "$default" ]]; then
        echo "$default"
    else
        echo "$result"
    fi
}

# Extract email headers safely
extract_header() {
    local json="$1"
    local header_name="$2"

    safe_jq "$json" ".payload.headers[] | select(.name == \"$header_name\") | .value" ""
}

# Format email summary
format_email_summary() {
    local message_json="$1"

    local id subject from snippet date
    id=$(safe_jq "$message_json" ".id" "unknown")
    subject=$(extract_header "$message_json" "Subject")
    from=$(extract_header "$message_json" "From")
    snippet=$(safe_jq "$message_json" ".snippet" "")
    date=$(extract_header "$message_json" "Date")

    # Clean up subject and from
    subject="${subject:-No Subject}"
    from="${from:-Unknown Sender}"

    # Truncate long fields
    subject="${subject:0:80}"
    from="${from:0:50}"
    snippet="${snippet:0:100}"

    printf "%-15s | %-50s | %-80s | %s\n" "$id" "$from" "$subject" "${snippet}..."
}

# Batch process items with progress
batch_process() {
    local items=("$@")
    local total=${#items[@]}
    local processed=0

    for item in "${items[@]}"; do
        ((processed++))
        log_debug "Processing $processed/$total: $item"

        if ! "$@"; then
            log_error "Failed to process item: $item"
            return 1
        fi

        # Progress indicator for large batches
        if [[ $((processed % 10)) -eq 0 ]]; then
            log_info "Processed $processed/$total items"
        fi
    done

    log_info "Successfully processed $total items"
}

# Validate email address format
validate_email() {
    local email="$1"

    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        log_error "Invalid email format: $email"
        return 1
    fi

    return 0
}

# URL encode for API calls
url_encode() {
    local string="$1"
    printf '%s' "$string" | jq -sRr @uri
}

# Generate random ID for new events
generate_id() {
    openssl rand -hex 16
}

# Format date for Google APIs
format_date() {
    local date_string="$1"

    # Validate date format (YYYY-MM-DD)
    if [[ ! "$date_string" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        log_error "Invalid date format. Expected YYYY-MM-DD, got: $date_string"
        return 1
    fi

    echo "$date_string"
}

# Parse date range for calendar events
parse_date_range() {
    local start_date="$1"
    local end_date="$2"

    if [[ -z "$start_date" ]] || [[ -z "$end_date" ]]; then
        log_error "Start and end dates are required"
        return 1
    fi

    # Validate and format dates
    start_date=$(format_date "$start_date") || return 1
    end_date=$(format_date "$end_date") || return 1

    echo "{\"start\":{\"date\":\"$start_date\"},\"end\":{\"date\":\"$end_date\"}}"
}