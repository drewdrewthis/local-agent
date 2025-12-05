#!/bin/bash
# Google Integration Utilities
# Helper functions for logging, formatting, and common operations

set -euo pipefail

# Configuration
readonly LOG_FILE="${GOOGLE_LOG_FILE:-logs/google_integration.log}"
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

# Cleanup function for temporary files
cleanup_temp_files() {
    local temp_dir="${TMPDIR:-/tmp}"
    local pattern="google_*_temp"

    # Remove old temp files (older than 1 hour)
    find "$temp_dir" -name "$pattern" -type f -mmin +60 -delete 2>/dev/null || true
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

# Format file sizes
format_file_size() {
    local size="$1"

    if [[ $size -gt 1073741824 ]]; then
        printf "%.1fGB" $(echo "scale=1; $size/1073741824" | bc)
    elif [[ $size -gt 1048576 ]]; then
        printf "%.1fMB" $(echo "scale=1; $size/1048576" | bc)
    elif [[ $size -gt 1024 ]]; then
        printf "%.1fKB" $(echo "scale=1; $size/1024" | bc)
    else
        printf "%dB" "$size"
    fi
}

# Validate date format
validate_date() {
    local date="$1"

    if [[ ! "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        log_error "Invalid date format: $date (expected YYYY-MM-DD)"
        return 1
    fi

    # Additional validation for reasonable dates
    local year month day
    year=$(echo "$date" | cut -d- -f1)
    month=$(echo "$date" | cut -d- -f2)
    day=$(echo "$date" | cut -d- -f3)

    if [[ $year -lt 2000 ]] || [[ $year -gt 2100 ]] || \
       [[ $month -lt 1 ]] || [[ $month -gt 12 ]] || \
       [[ $day -lt 1 ]] || [[ $day -gt 31 ]]; then
        log_error "Date out of reasonable range: $date"
        return 1
    fi

    return 0
}

# Calculate date differences
date_diff_days() {
    local date1="$1"
    local date2="$2"

    # Use date command to calculate difference
    local epoch1 epoch2
    epoch1=$(date -j -f "%Y-%m-%d" "$date1" "+%s" 2>/dev/null || date -d "$date1" "+%s" 2>/dev/null)
    epoch2=$(date -j -f "%Y-%m-%d" "$date2" "+%s" 2>/dev/null || date -d "$date2" "+%s" 2>/dev/null)

    echo $(( (epoch2 - epoch1) / 86400 ))
}

# Generate random string
random_string() {
    local length="${1:-32}"
    openssl rand -hex "$length" 2>/dev/null || cat /dev/urandom | head -c "$length" | xxd -p
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Validate required commands
validate_dependencies() {
    local required_commands=("curl" "jq" "openssl")

    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            log_error "Required command not found: $cmd"
            log_error "Please install $cmd to use Google integrations"
            return 1
        fi
    done

    return 0
}

# Setup environment
setup_environment() {
    setup_logging
    cleanup_temp_files

    if ! validate_dependencies; then
        exit 1
    fi
}

# Export functions for external use
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_error "This is a library file, not meant to be executed directly"
    exit 1
fi