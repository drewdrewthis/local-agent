#!/bin/bash

# Direct Google Sheets API call to update housing data
# Spreadsheet ID: 1QYXsOTnYDSENkbYN9f5YzuQ8CE6BleWEpnRWIRsXvaA

# Load environment
source .env

# Get access token
echo "Getting access token..."
ACCESS_TOKEN=$(curl -s -X POST https://oauth2.googleapis.com/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=$GOOGLE_CLIENT_ID" \
  -d "client_secret=$GOOGLE_CLIENT_SECRET" \
  -d "refresh_token=$GOOGLE_REFRESH_TOKEN" \
  -d "grant_type=refresh_token" | jq -r '.access_token')

if [ "$ACCESS_TOKEN" = "null" ] || [ -z "$ACCESS_TOKEN" ]; then
    echo "Failed to get access token"
    exit 1
fi

echo "Got access token, updating sheet..."

# Housing data
DATA='{
  "values": [
    ["Name", "Location", "Status", "Occupants", "Price", "Apartment Size", "Room Size", "Phone", "Notes"],
    ["Jason", "Rue de Smyrne, Marseille", "Replied", "2", "400€", "70 m²", "", "04 91 47 05 50", "5-bedroom flat, FLATSHARING, Available, likes sport/cooking/discussion"],
    ["Anne", "Place Alexandre Labadie, Marseille", "Replied", "7", "675€", "320 m²", "", "", "10-bedroom flat, FLATSHARING, Available, can visit apartment"],
    ["Gilles", "Rue Saint Pierre, Marseille (5e)", "Replied", "1", "600€ (all inclusive)", "100 m²", "Furnished room with double bed", "", "HOMESTAY, Available from 01/01/2026, south-facing balcony, near universities, tram/metro"],
    ["Lola", "Boulevard Demandolx, Marseille", "Replied", "2", "490€", "70 m²", "", "", "4-bedroom house, FLATSHARING, Family colocation with mom, child, Colombians, student, cat"],
    ["Pierre", "Boulevard De La Liberté, Marseille", "Replied", "3", "420€", "118 m²", "", "", "5-bedroom flat, HOMESTAY, Deactivated - no longer available"]
  ]
}'

# Update sheet
RESPONSE=$(curl -s -X PUT \
  "https://sheets.googleapis.com/v4/spreadsheets/1QYXsOTnYDSENkbYN9f5YzuQ8CE6BleWEpnRWIRsXvaA/values/Sheet1!A1:I6?valueInputOption=RAW" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$DATA")

echo "Response: $RESPONSE"

if echo "$RESPONSE" | jq -e '.updatedRange' >/dev/null 2>&1; then
    echo "✅ Successfully updated spreadsheet!"
    echo "$RESPONSE" | jq -r '.updatedRange'
else
    echo "❌ Failed to update spreadsheet"
    echo "$RESPONSE"
fi