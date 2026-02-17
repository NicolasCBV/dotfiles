#!/bin/bash

DATA_DIR="$HOME/.local/share/eww"
CACHE_DIR="$HOME/.cache/eww/notifications"
NOTIF_FILE="$DATA_DIR/notifications.json"

mkdir -p "$DATA_DIR" "$CACHE_DIR"
[ ! -f "$NOTIF_FILE" ] && echo '{"notifications":[]}' > "$NOTIF_FILE"

add_notification() {
    local app="$1"
    local summary="$2"
    local body="$3"
    local urgency="${4:-1}"
    
    app="${app//\"/}"
    summary="${summary//\"/}"
    body="${body//\"/}"
    
    TIMESTAMP=$(date +%s)
    ID=$(date +%s%N | sha256sum | head -c 16)
    
    jq --arg id "$ID" \
       --arg app "$app" \
       --arg summary "$summary" \
       --arg body "$body" \
       --arg time "$TIMESTAMP" \
       --argjson urgency "$urgency" \
       '.notifications += [{
           id: $id,
           app: $app,
           summary: $summary,
           body: $body,
           timestamp: ($time | tonumber),
           urgency: $urgency,
           read: false,
           dispatch: false
       }]' "$NOTIF_FILE" > "$NOTIF_FILE.tmp" && mv "$NOTIF_FILE.tmp" "$NOTIF_FILE"
    
    eww update notifications_unread=$(jq '[.notifications[] | select(.read == false)] | length' "$NOTIF_FILE") 2>/dev/null
    
    ~/.config/eww/scripts/notifications/manager.sh check-undispatched 2>/dev/null &
}

dbus-monitor --session "interface='org.freedesktop.Notifications',member='Notify'" | \
while read -r line; do
    if [[ "$line" =~ method\ call ]]; then
        BUFFER=()
        CAPTURE=true
        URGENCY=1
    elif [[ "$CAPTURE" == true ]]; then
        if [[ "$line" =~ string\ \"(.*)\" ]]; then
            BUFFER+=("${BASH_REMATCH[1]}")
        elif [[ "$line" =~ byte\ ([0-9]+) ]]; then
            URGENCY="${BASH_REMATCH[1]}"
        fi
        
        if [ ${#BUFFER[@]} -ge 4 ]; then
            APP="${BUFFER[0]}"
            SUMMARY="${BUFFER[2]}"
            BODY="${BUFFER[3]}"
            
            if [ -n "$SUMMARY" ]; then
                add_notification "$APP" "$SUMMARY" "$BODY" "$URGENCY"
            fi
            
            CAPTURE=false
            BUFFER=()
        fi
    fi
done
