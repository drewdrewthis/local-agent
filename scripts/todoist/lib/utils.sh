#!/bin/bash
# Todoist Utilities Library
# Helper functions for logging, formatting, and common operations

set -euo pipefail

# Configuration
readonly LOG_FILE="${TODOIST_LOG_FILE:-logs/todoist_integration.log}"
readonly LOG_MAX_SIZE=10485760  # 10MB
readonly LOG_MAX_FILES=5

# Logging functions
log_info() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $*"
    echo "$message" >&2

    if [[ "${LOG_TO_FILE:-true}" == "true" ]]; then
        echo "$message" >> "$LOG_FILE"
        rotate_log_if_needed
    fi
}

log_error() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*"
    echo "$message" >&2

    if [[ "${LOG_TO_FILE:-true}" == "true" ]]; then
        echo "$message" >> "$LOG_FILE"
        rotate_log_if_needed
    fi
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        local message="[$(date +'%Y-%m-%d %H:%M:%S')] DEBUG: $*"
        echo "$message" >&2

        if [[ "${LOG_TO_FILE:-true}" == "true" ]]; then
            echo "$message" >> "$LOG_FILE"
        fi
    fi
}

log_warn() {
    local message="[$(date +'%Y-%m-%d %H:%M:%S')] WARN: $*"
    echo "$message" >&2

    if [[ "${LOG_TO_FILE:-true}" == "true" ]]; then
        echo "$message" >> "$LOG_FILE"
        rotate_log_if_needed
    fi
}

# Rotate log file if it gets too large
rotate_log_if_needed() {
    if [[ -f "$LOG_FILE" ]] && [[ $(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null) -gt $LOG_MAX_SIZE ]]; then
        log_info "Rotating log file..."

        # Rotate existing logs
        for ((i=LOG_MAX_FILES-1; i>=1; i--)); do
            if [[ -f "${LOG_FILE}.$i" ]]; then
                mv "${LOG_FILE}.$i" "${LOG_FILE}.$((i+1))"
            fi
        done

        # Move current log
        if [[ -f "${LOG_FILE}.1" ]]; then
            mv "$LOG_FILE" "${LOG_FILE}.1"
        else
            cp "$LOG_FILE" "${LOG_FILE}.1"
            : > "$LOG_FILE"  # Truncate current log
        fi
    fi
}

# Setup logging directory
setup_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"

    # Create log file if it doesn't exist
    if [[ ! -f "$LOG_FILE" ]]; then
        touch "$LOG_FILE"
        log_info "Created log file: $LOG_FILE"
    fi
}

# Format task priority for display
display_priority() {
    local priority="$1"

    case "$priority" in
        1) echo "🔵 Low" ;;
        2) echo "🟡 Medium" ;;
        3) echo "🟠 High" ;;
        4) echo "🔴 Urgent" ;;
        *) echo "⚪ Unknown" ;;
    esac
}

# Format due date for display
display_due_date() {
    local due_date="$1"
    local due_info="$2"

    if [[ -z "$due_date" ]]; then
        echo "No due date"
        return
    fi

    # Check if it's today, tomorrow, etc.
    local today tomorrow yesterday
    today=$(date +%Y-%m-%d)
    tomorrow=$(date -v+1d +%Y-%m-%d 2>/dev/null || date -d tomorrow +%Y-%m-%d 2>/dev/null)
    yesterday=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d yesterday +%Y-%m-%d 2>/dev/null)

    case "$due_date" in
        "$today") echo "📅 Today" ;;
        "$tomorrow") echo "📅 Tomorrow" ;;
        "$yesterday") echo "📅 Yesterday" ;;
        *)
            # Format as readable date
            local day_name
            day_name=$(date -j -f "%Y-%m-%d" "$due_date" "+%A" 2>/dev/null || date -d "$due_date" "+%A" 2>/dev/null || echo "")
            if [[ -n "$day_name" ]]; then
                echo "📅 $day_name ($due_date)"
            else
                echo "📅 $due_date"
            fi
            ;;
    esac
}

# Check if task is overdue
is_overdue() {
    local due_date="$1"

    if [[ -z "$due_date" ]]; then
        return 1  # Not overdue if no due date
    fi

    local today
    today=$(date +%Y-%m-%d)

    if [[ "$due_date" < "$today" ]]; then
        return 0  # Overdue
    else
        return 1  # Not overdue
    fi
}

# Validate required commands
validate_dependencies() {
    local required_commands=("curl" "jq")

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "Required command not found: $cmd"
            log_error "Please install $cmd to use Todoist integrations"
            return 1
        fi
    done

    return 0
}

# Setup environment
setup_environment() {
    setup_logging

    if ! validate_dependencies; then
        exit 1
    fi
}

# Interactive confirmation
confirm_action() {
    local message="$1"
    local default="${2:-n}"

    echo -n "$message (y/N): " >&2

    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        echo "no (non-interactive mode)" >&2
        return 1
    fi

    read -r response
    case "${response:-$default}" in
        [Yy]|[Yy][Ee][Ss]) return 0 ;;
        *) return 1 ;;
    esac
}

# Progress bar for long operations
show_progress() {
    local current="$1"
    local total="$2"
    local width=50

    if [[ $total -eq 0 ]]; then
        return
    fi

    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))

    printf "\rProgress: [%-${width}s] %d/%d (%d%%)" \
        "$(printf '%.0s#' $(seq 1 $completed))" \
        "$current" "$total" "$percentage"
}

# Export functions for external use
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_error "This is a library file, not meant to be executed directly"
    exit 1
fi