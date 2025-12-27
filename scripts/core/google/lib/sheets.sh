#!/bin/bash

# Google Sheets API Library
# Provides functions for reading and writing Google Sheets

source "$(dirname "${BASH_SOURCE[0]}")/api.sh"

# Sheets API base URL
SHEETS_API_BASE="https://sheets.googleapis.com/v4/spreadsheets"

# Read sheet data
# Usage: sheets_get_values <spreadsheet_id> <range> [major_dimension]
sheets_get_values() {
    local spreadsheet_id="$1"
    local range="$2"
    local major_dimension="${3:-ROWS}"

    local url="${SHEETS_API_BASE}/${spreadsheet_id}/values/${range}?majorDimension=${major_dimension}"

    api_call "GET" "$url"
}

# Write sheet data
# Usage: sheets_update_values <spreadsheet_id> <range> <values_json>
sheets_update_values() {
    local spreadsheet_id="$1"
    local range="$2"
    local values_json="$3"

    local url="${SHEETS_API_BASE}/${spreadsheet_id}/values/${range}?valueInputOption=RAW"

    api_call "PUT" "$url" "$values_json"
}

# Append sheet data
# Usage: sheets_append_values <spreadsheet_id> <range> <values_json>
sheets_append_values() {
    local spreadsheet_id="$1"
    local range="$2"
    local values_json="$3"

    local url="${SHEETS_API_BASE}/${spreadsheet_id}/values/${range}:append?valueInputOption=RAW"

    api_call "POST" "$url" "$values_json"
}

# Get spreadsheet metadata
# Usage: sheets_get_metadata <spreadsheet_id>
sheets_get_metadata() {
    local spreadsheet_id="$1"

    local url="${SHEETS_API_BASE}/${spreadsheet_id}"

    api_call "GET" "$url"
}

# Clear sheet range
# Usage: sheets_clear_values <spreadsheet_id> <range>
sheets_clear_values() {
    local spreadsheet_id="$1"
    local range="$2"

    local url="${SHEETS_API_BASE}/${spreadsheet_id}/values/${range}:clear"

    api_call "POST" "$url"
}