#!/bin/bash

EWW_OPEN="./scripts/xdg/eww-open-url.sh"

STATE_DIR="$HOME/.cache/eww/calendar"
STATE_FILE="$STATE_DIR/current_month"
MARKS_FILE="/etc/eww/cred/gcal-sync/calendar_marks.json"
mkdir -p "$STATE_DIR"
if [ ! -f "$STATE_FILE" ]; then
    date '+%Y-%m' > "$STATE_FILE"
fi
CURRENT=$(cat "$STATE_FILE")
YEAR="${CURRENT%-*}"
MONTH="${CURRENT#*-}"
TODAY=$(date '+%Y-%m-%d')
FIRST_DAY=$(date -d "$CURRENT-01" '+%u')
[ "$FIRST_DAY" = "7" ] && FIRST_DAY=0
DAYS_IN_MONTH=$(date -d "$CURRENT-01 + 1 month - 1 day" '+%d')
PREV_MONTH=$(date -d "$CURRENT-01 - 1 day" '+%Y-%m')
PREV_MONTH_DAYS=$(date -d "$PREV_MONTH-01 + 1 month - 1 day" '+%d')
PREV_START=$((PREV_MONTH_DAYS - FIRST_DAY + 1))
PREV_YEAR="${PREV_MONTH%-*}"
PREV_MONTH_NUM="${PREV_MONTH#*-}"
NEXT_MONTH=$(date -d "$CURRENT-01 + 1 month" '+%Y-%m')
NEXT_YEAR="${NEXT_MONTH%-*}"
NEXT_MONTH_NUM="${NEXT_MONTH#*-}"
declare -A MARKS
if [ -f "$MARKS_FILE" ]; then
    while IFS='|' read -r date color title; do
        if [ -n "$date" ]; then
            if [[ "$date" == "$CURRENT"* ]]; then
                MARKS["$date"]="$color"
            fi
        fi
    done < <(jq -r '.marks[]? | "\(.date)|\(.color)|\(.title)"' "$MARKS_FILE" 2>/dev/null)
fi
OUTPUT='(box :orientation "v" :space-evenly false'
day_count=0
for ((i=PREV_START; i<=PREV_MONTH_DAYS; i++)); do
    [ $day_count -eq 0 ] && OUTPUT+=$'\n  (box :orientation "h" :space-evenly true'
    gcal_url="https://calendar.google.com/calendar/r/day/$PREV_YEAR/$PREV_MONTH_NUM/$(printf "%02d" $i)"
    OUTPUT+=$'\n    (button :class "calendar-day other-month" :onclick "xdg-open '"'$gcal_url'"'" (label :text "'$i'"))'
    ((day_count++))
done
for ((day=1; day<=DAYS_IN_MONTH; day++)); do
    [ $day_count -eq 0 ] && OUTPUT+=$'\n  (box :orientation "h" :space-evenly true'
    
    date_str="$YEAR-$MONTH-$(printf "%02d" $day)"
    gcal_url="https://calendar.google.com/calendar/r/day/$YEAR/$MONTH/$(printf "%02d" $day)"
    
    classes="calendar-day"
    style=""
    
    [ "$date_str" = "$TODAY" ] && classes+=" today"
    
    if [ -n "${MARKS[$date_str]}" ]; then
        color="${MARKS[$date_str]}"
        classes+=" marked"
        style=" :style \"border-color: $color; color: $color;\""
    fi
    
    onclick_cmd="$EWW_OPEN '$gcal_url'"
    OUTPUT+=$'\n    (button :class "'$classes'"'$style' :onclick "'"$onclick_cmd"'" (label :text "'$day'"))'

    ((day_count++))
    
    if [ $day_count -eq 7 ]; then
        OUTPUT+=$'\n  )'
        day_count=0
    fi
done
if [ $day_count -ne 0 ]; then
    next_day=1
    while [ $day_count -lt 7 ]; do
        gcal_url="https://calendar.google.com/calendar/r/day/$NEXT_YEAR/$NEXT_MONTH_NUM/$(printf "%02d" $next_day)"
        onclick_cmd="$EWW_OPEN '$gcal_url'"
        OUTPUT+=$'\n    (button :class "'$classes'"'$style' :onclick "'"$onclick_cmd"'" (label :text "'$day'"))'

        ((next_day++))
        ((day_count++))
    done
    OUTPUT+=$'\n  )'
fi
OUTPUT+=$'\n)'
echo "$OUTPUT"

