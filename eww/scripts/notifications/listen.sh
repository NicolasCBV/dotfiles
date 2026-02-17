#!/bin/bash

DATA_DIR="$HOME/.local/share/eww"
NOTIF_FILE="$DATA_DIR/notifications.json"
CACHE_DIR="$HOME/.cache/eww"

mkdir -p "$DATA_DIR" "$CACHE_DIR"

[ ! -f "$NOTIF_FILE" ] && echo '{"notifications":[]}' > "$NOTIF_FILE"

monitor_notifications() {
    dbus-monitor "interface='org.freedesktop.Notifications',member='Notify'" | \
    while read -r line; do
        if [[ "$line" =~ string\ \"(.*)\" ]]; then
            BUFFER+=("${BASH_REMATCH[1]}")
            
            if [ ${#BUFFER[@]} -ge 4 ]; then
                APP="${BUFFER[0]}"
                SUMMARY="${BUFFER[2]}"
                BODY="${BUFFER[3]}"
                
                if [ -n "$SUMMARY" ]; then
                    TIMESTAMP=$(date +%s)
                    ID=$(date +%s%N | sha256sum | head -c 16)
                    
                    jq --arg id "$ID" \
                       --arg app "$APP" \
                       --arg summary "$SUMMARY" \
                       --arg body "$BODY" \
                       --arg time "$TIMESTAMP" \
                       '.notifications += [{
                           id: $id,
                           app: $app,
                           summary: $summary,
                           body: $body,
                           timestamp: ($time | tonumber),
                           read: false
                       }]' "$NOTIF_FILE" > "$NOTIF_FILE.tmp" && mv "$NOTIF_FILE.tmp" "$NOTIF_FILE"
                    
                    eww update notifications_unread=$(jq '[.notifications[] | select(.read == false)] | length' "$NOTIF_FILE")
                fi
                
                BUFFER=()
            fi
        fi
    done
}

monitor_notifications
