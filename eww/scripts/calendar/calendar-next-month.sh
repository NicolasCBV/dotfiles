#!/bin/bash

STATE_DIR="$HOME/.cache/eww/calendar"
STATE_FILE="$STATE_DIR/current_month"

mkdir -p "$STATE_DIR"

if [ ! -f "$STATE_FILE" ]; then
    date '+%Y-%m' > "$STATE_FILE"
fi

CURRENT=$(cat "$STATE_FILE")

NEW_DATE=$(date -d "$CURRENT-01 + 1 month" '+%Y-%m')

echo "$NEW_DATE" > "$STATE_FILE"
