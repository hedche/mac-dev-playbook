#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title OCR Create Event
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖

# Get the frontmost window bounds using AppleScript
window_info=$(osascript <<EOF
tell application "System Events"
    set frontApp to name of first process whose frontmost is true
    tell process frontApp
        set winBounds to bounds of front window
    end tell
end tell
return frontApp & "|" & (item 1 of winBounds as text) & "," & (item 2 of winBounds as text) & "," & (item 3 of winBounds as text) & "," & (item 4 of winBounds as text)
EOF
)

# Parse info
app_name=$(echo "$window_info" | cut -d'|' -f1)
bounds=$(echo "$window_info" | cut -d'|' -f2)

# Take a screenshot of the active window bounds
screenshot_path="/tmp/active_window.png"
screencapture -R"$bounds" "$screenshot_path"

# Run OCR (using Raycast's capture-text helper under the hood if installed)
ocr_text=$(tesseract "$screenshot_path" stdout 2>/dev/null)

# Fallback: if OCR empty, use window title
if [ -z "$ocr_text" ]; then
  ocr_text="$app_name window"
fi

# Send to AI for parsing
event_json=$(echo "$ocr_text" | raycast-ai "
You are a scheduling assistant. Extract a calendar event from this text.
Respond ONLY in strict JSON with keys: title, description, url, start, end.
- start and end must be ISO 8601 (e.g. 2025-09-23T14:00:00)
- Handle vague phrases like 'tomorrow 3pm' relative to now ($(date -u +"%Y-%m-%dT%H:%M:%SZ"))
- If no end, assume 1 hour duration.
Text:
\"$ocr_text\"
")

# Parse JSON
title=$(echo "$event_json" | jq -r '.title')
description=$(echo "$event_json" | jq -r '.description')
url=$(echo "$event_json" | jq -r '.url')
start=$(echo "$event_json" | jq -r '.start')
end=$(echo "$event_json" | jq -r '.end')

# Create Calendar event
osascript <<EOF
tell application "Calendar"
    tell calendar "Home"
        make new event with properties {summary:"$title", description:"$description", url:"$url", start date:date "$start", end date:date "$end"}
    end tell
end tell
EOF
