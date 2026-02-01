#!/bin/bash
# Google Calendar API Library
# Functions for calendar operations: listing, creating, modifying events

set -euo pipefail

# Load dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/api.sh"

# Configuration
readonly CALENDAR_API_BASE="https://www.googleapis.com/calendar/v3"
readonly DEFAULT_CALENDAR="818038fcccbba275a732fa90d4c1aff3daf91e16bb2822796f988e1d3127f482@group.calendar.google.com"

# Logging
log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $*" >&2; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }
log_debug() { [[ "${DEBUG:-false}" == "true" ]] && echo "[$(date +'%Y-%m-%d %H:%M:%S')] DEBUG: $*" >&2; }

# List calendars
calendar_list_calendars() {
    local response
    response=$(api_call "GET" "$CALENDAR_API_BASE/users/me/calendarList")

    if [[ -n "$response" ]]; then
        echo "$response" | jq '.'
        return 0
    fi

    return 1
}

# Get calendar details
calendar_get_calendar() {
    local calendar_id="${1:-$DEFAULT_CALENDAR}"

    local response
    response=$(api_call "GET" "$CALENDAR_API_BASE/calendars/$calendar_id")

    if [[ -n "$response" ]]; then
        echo "$response" | jq '.'
        return 0
    fi

    return 1
}

# List events
calendar_list_events() {
    local calendar_id="${1:-$DEFAULT_CALENDAR}"
    local time_min="${2:-}"
    local time_max="${3:-}"
    local max_results="${4:-250}"
    local query="${5:-}"

    local url="$CALENDAR_API_BASE/calendars/$(url_encode "$calendar_id")/events?maxResults=$max_results&singleEvents=true&orderBy=startTime"

    if [[ -n "$time_min" ]]; then
        url="$url&timeMin=$time_min"
    fi

    if [[ -n "$time_max" ]]; then
        url="$url&timeMax=$time_max"
    fi

    if [[ -n "$query" ]]; then
        url="$url&q=$(url_encode "$query")"
    fi

    local response
    response=$(api_call "GET" "$url")

    if [[ -n "$response" ]]; then
        echo "$response"
        return 0
    fi

    return 1
}

# Create event
calendar_create_event() {
    local calendar_id="$1"
    local summary="$2"
    local start_date="$3"
    local end_date="$4"
    local description="${5:-}"
    local location="${6:-}"

    # Validate inputs
    [[ -z "$calendar_id" ]] && { log_error "Calendar ID is required"; return 1; }
    [[ -z "$summary" ]] && { log_error "Summary is required"; return 1; }
    [[ -z "$start_date" ]] && { log_error "Start date is required"; return 1; }
    [[ -z "$end_date" ]] && { log_error "End date is required"; return 1; }

    # Parse dates
    local date_range
    date_range=$(parse_date_range "$start_date" "$end_date")
    if [[ -z "$date_range" ]]; then
        return 1
    fi

    # Build event data
    local event_data="{
        \"summary\": \"$summary\",
        $date_range,
        \"transparency\": \"transparent\",
        \"reminders\": {\"useDefault\": false}
    }"

    if [[ -n "$description" ]]; then
        event_data=$(echo "$event_data" | jq --arg desc "$description" '.description = $desc')
    fi

    if [[ -n "$location" ]]; then
        event_data=$(echo "$event_data" | jq --arg loc "$location" '.location = $loc')
    fi

    local url="$CALENDAR_API_BASE/calendars/$(url_encode "$calendar_id")/events"
    local response
    response=$(api_call "POST" "$url" "$event_data")

    if [[ -n "$response" ]]; then
        log_info "Event created: $summary"
        echo "$response"
        return 0
    fi

    return 1
}

# Update event
calendar_update_event() {
    local calendar_id="$1"
    local event_id="$2"
    local updates="$3"  # JSON string of updates

    [[ -z "$calendar_id" ]] && { log_error "Calendar ID is required"; return 1; }
    [[ -z "$event_id" ]] && { log_error "Event ID is required"; return 1; }
    [[ -z "$updates" ]] && { log_error "Updates are required"; return 1; }

    local url="$CALENDAR_API_BASE/calendars/$(url_encode "$calendar_id")/events/$event_id"
    local response
    response=$(api_call "PUT" "$url" "$updates")

    if [[ -n "$response" ]]; then
        log_info "Event updated: $event_id"
        echo "$response"
        return 0
    fi

    return 1
}

# Delete event
calendar_delete_event() {
    local calendar_id="$1"
    local event_id="$2"

    [[ -z "$calendar_id" ]] && { log_error "Calendar ID is required"; return 1; }
    [[ -z "$event_id" ]] && { log_error "Event ID is required"; return 1; }

    local url="$CALENDAR_API_BASE/calendars/$(url_encode "$calendar_id")/events/$event_id"
    local response
    response=$(api_call "DELETE" "$url")

    # DELETE returns empty response on success
    if [[ $? -eq 0 ]]; then
        log_info "Event deleted: $event_id"
        return 0
    fi

    return 1
}

# Get event details
calendar_get_event() {
    local calendar_id="$1"
    local event_id="$2"

    [[ -z "$calendar_id" ]] && { log_error "Calendar ID is required"; return 1; }
    [[ -z "$event_id" ]] && { log_error "Event ID is required"; return 1; }

    local url="$CALENDAR_API_BASE/calendars/$(url_encode "$calendar_id")/events/$event_id"
    local response
    response=$(api_call "GET" "$url")

    if [[ -n "$response" ]]; then
        echo "$response"
        return 0
    fi

    return 1
}

# Format event for display
calendar_format_event() {
    local event_json="$1"

    local summary start_date end_date location description
    summary=$(safe_jq "$event_json" ".summary" "Untitled Event")
    start_date=$(safe_jq "$event_json" ".start.date" "")
    end_date=$(safe_jq "$event_json" ".end.date" "")
    location=$(safe_jq "$event_json" ".location" "")
    description=$(safe_jq "$event_json" ".description" "")

    cat << EOF
📅 $summary
   Start: ${start_date:-Unknown}
   End: ${end_date:-Unknown}
   ${location:+Location: $location}
   ${description:+$description}

EOF
}

# Search events by query
calendar_search_events() {
    local query="$1"
    local calendar_id="${2:-$DEFAULT_CALENDAR}"

    [[ -z "$query" ]] && { log_error "Search query is required"; return 1; }

    calendar_list_events "$calendar_id" "" "" "100" "$query"
}

# Quick add event (natural language)
calendar_quick_add() {
    local text="$1"
    local calendar_id="${2:-$DEFAULT_CALENDAR}"

    [[ -z "$text" ]] && { log_error "Event text is required"; return 1; }

    local url="$CALENDAR_API_BASE/calendars/$(url_encode "$calendar_id")/events/quickAdd?text=$(url_encode "$text")"
    local response
    response=$(api_call "POST" "$url")

    if [[ -n "$response" ]]; then
        log_info "Quick event added: $text"
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