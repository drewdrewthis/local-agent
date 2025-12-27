#!/bin/bash
# Todoist API Utilities Library
# Common functions for API calls and data processing

set -euo pipefail

# Load auth library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/auth.sh"

# Configuration
if [[ -z "${DEFAULT_TIMEOUT:-}" ]]; then
    readonly DEFAULT_TIMEOUT=30
fi
if [[ -z "${MAX_RETRIES:-}" ]]; then
    readonly MAX_RETRIES=3
fi

# Logging
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $*" >&2; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }
log_debug() { [[ "${DEBUG:-false}" == "true" ]] && echo "[$(date +'%Y-%m-%d %H:%M:%S')] DEBUG: $*" >&2; }

# Make authenticated API call with retry logic
api_call() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"
    local timeout="${4:-$DEFAULT_TIMEOUT}"

    local attempt=1
    local response_code

    while [[ $attempt -le $MAX_RETRIES ]]; do
        log_debug "API call attempt $attempt/$MAX_RETRIES: $method $endpoint"

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

        curl_args+=(--max-time "$timeout" "$TODOIST_API_BASE$endpoint")

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
            400)
                log_error "Bad request: $response_body"
                return 1
                ;;
            401)
                log_error "Authentication failed. Check your TODOIST_TOKEN."
                return 1
                ;;
            403)
                log_error "Forbidden. Check your token permissions."
                return 1
                ;;
            404)
                log_error "Not found: $endpoint"
                return 1
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

# Format priority level for display
format_priority() {
    local priority="$1"

    case "$priority" in
        1) echo "Low" ;;
        2) echo "Medium" ;;
        3) echo "High" ;;
        4) echo "Urgent" ;;
        *) echo "Unknown" ;;
    esac
}

# Parse due date string
parse_due_date() {
    local due_string="$1"

    # Handle common formats
    case "$due_string" in
        today|Today|TODAY)
            echo "$(date +%Y-%m-%d)"
            ;;
        tomorrow|Tomorrow|TOMORROW)
            echo "$(date -v+1d +%Y-%m-%d)"
            ;;
        yesterday|yesterday|YESTERDAY)
            echo "$(date -v-1d +%Y-%m-%d)"
            ;;
        *)
            # Try to parse as YYYY-MM-DD
            if [[ "$due_string" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                echo "$due_string"
            else
                log_error "Unsupported due date format: $due_string"
                log_error "Use YYYY-MM-DD, 'today', 'tomorrow', or 'yesterday'"
                return 1
            fi
            ;;
    esac
}

# Validate task ID format
validate_task_id() {
    local task_id="$1"

    if [[ ! "$task_id" =~ ^[0-9]+$ ]]; then
        log_error "Invalid task ID format: $task_id (must be numeric)"
        return 1
    fi

    return 0
}

# Format task for display
format_task() {
    local task_json="$1"

    local id content priority due project_name labels
    id=$(safe_jq "$task_json" ".id" "unknown")
    content=$(safe_jq "$task_json" ".content" "No content")
    priority=$(safe_jq "$task_json" ".priority" "1")
    due=$(safe_jq "$task_json" ".due.date" "")
    project_name=$(safe_jq "$task_json" ".project_name" "")
    labels=$(safe_jq "$task_json" ".labels | join(\", \")" "")

    local priority_text
    priority_text=$(format_priority "$priority")

    printf "%-12s | %-50s | %-8s | %-12s | %s\n" \
        "$id" "$content" "$priority_text" "${due:-No due date}" "$project_name"
}

# Batch process tasks
batch_process_tasks() {
    local operation="$1"
    shift
    local task_ids=("$@")
    local total=${#task_ids[@]}

    log_info "Processing $total tasks with operation: $operation"

    local processed=0
    local failed=0

    for task_id in "${task_ids[@]}"; do
        ((processed++))

        if ! "$operation" "$task_id"; then
            ((failed++))
            log_error "Failed to process task: $task_id"
        fi

        # Progress indicator
        if [[ $((processed % 5)) -eq 0 ]]; then
            log_info "Processed $processed/$total tasks ($failed failed)"
        fi
    done

    if [[ $failed -eq 0 ]]; then
        log_info "Successfully processed all $total tasks"
    else
        log_error "Processed $((total - failed))/$total tasks successfully ($failed failed)"
    fi
}

# Export functions for external use
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_error "This is a library file, not meant to be executed directly"
    exit 1
fi