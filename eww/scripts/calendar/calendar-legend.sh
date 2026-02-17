#!/bin/bash

STATE_DIR="$HOME/.cache/eww/calendar"
STATE_FILE="$STATE_DIR/current_month"
MARKS_FILE="/etc/eww/cred/gcal-sync/calendar_marks.json"

if [ ! -f "$STATE_FILE" ]; then
    echo ""
    exit 0
fi

CURRENT=$(cat "$STATE_FILE")

if [ ! -f "$MARKS_FILE" ]; then
    echo ""
    exit 0
fi

event_count=$(jq --arg month "$CURRENT" '[.marks[]? | select(.date | startswith($month))] | length' "$MARKS_FILE" 2>/dev/null)

if [ "$event_count" = "0" ] || [ -z "$event_count" ]; then
    echo ""
    exit 0
fi

echo '(box :orientation "v" :space-evenly false :spacing 4'

jq -r --arg month "$CURRENT" '.marks[]? | 
    select(.date | startswith($month)) | 
    [.date, .title, .color] | @tsv' "$MARKS_FILE" 2>/dev/null | sort | while IFS=$'\t' read -r date title color; do
    
    [ -z "$date" ] && continue
    
    if [ -z "$color" ]; then
        color="#3b82f6"
    fi
    
    day="${date##*-}"
    day=$((10#$day))
    
    title_escaped=$(printf '%s' "$title" | sed 's/"/\\"/g' | sed "s/'/\\'/g")
    
    cat << EOF
  (box
    :class "calendar-legend-item"
    :orientation "h"
    :space-evenly false
    :spacing 8
    (label
      :class "calendar-legend-icon"
      :style "color: $color; font-size: 16px;"
      :text "●")
    (label
      :class "calendar-legend-text"
      :text "Dia $day: $title_escaped"
      :halign "start"
      :limit-width 55
      :wrap false))
EOF
done

echo ')'
