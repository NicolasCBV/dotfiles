#!/bin/bash

DATA_DIR="$HOME/.local/share/eww"
NOTIF_FILE="$DATA_DIR/notifications.json"
CACHE_DIR="$HOME/.cache/eww/notifications"
QUEUE_FILE="$CACHE_DIR/queue"
DISPLAY_SCRIPT="$HOME/.config/eww/scripts/notifications/display.sh"
WATCH_INTERVAL=1

mkdir -p "$DATA_DIR" "$CACHE_DIR"
[ ! -f "$NOTIF_FILE" ] && echo '{"notifications":[]}' > "$NOTIF_FILE"
touch "$QUEUE_FILE"

LOCK_FILE="/tmp/eww_notif_watcher.lock"
QUEUE_LOCK="/tmp/eww_notif_queue.lock"

cleanup() {
    rm -f "$LOCK_FILE"
    exit 0
}

trap cleanup INT TERM EXIT

if [ -f "$LOCK_FILE" ]; then
    LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null)
    if [ -n "$LOCK_PID" ] && kill -0 "$LOCK_PID" 2>/dev/null; then
        echo "Watcher já está rodando (PID: $LOCK_PID)" >&2
        exit 1
    fi
    rm -f "$LOCK_FILE"
fi

echo $$ > "$LOCK_FILE"

echo "🔄 Watcher de notificações iniciado (PID: $$)" >&2

sanitize_text() {
    local text="$1"
    
    text="${text//$'\n'/ }"
    text="${text//$'\r'/ }"
    text="${text//$'\t'/ }"
    
    text="${text//|/·}"
    
    text=$(echo "$text" | tr -s ' ')
    
    text=$(echo "$text" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    if [ ${#text} -gt 500 ]; then
        text="${text:0:497}..."
    fi
    
    echo "$text"
}

add_to_queue() {
    local id="$1"
    local app="$2"
    local summary="$3"
    local body="$4"
    local urgency="$5"
    
    local timeout=0
    while [ -f "$QUEUE_LOCK" ] && [ $timeout -lt 50 ]; do
        sleep 0.1
        timeout=$((timeout + 1))
    done
    
    touch "$QUEUE_LOCK"
    
    echo "$id|$app|$summary|$body|$urgency" >> "$QUEUE_FILE"
    
    rm -f "$QUEUE_LOCK"
}

dispatch_notifications() {
    local undispatched=$(jq -r '.notifications[] | select(.dispatch == false) | 
                                [.id, .app, .summary, .body, (.urgency // 1)] | @tsv' \
                                "$NOTIF_FILE" 2>/dev/null)
    
    if [ -z "$undispatched" ]; then
        return 0
    fi
    
    local count=0
    local ids_to_dispatch=()
    
    while IFS=$'\t' read -r id app summary body urgency; do
        [ -z "$id" ] && continue
        
        app=$(sanitize_text "$app")
        summary=$(sanitize_text "$summary")
        body=$(sanitize_text "$body")
        
        case "$urgency" in
            0|1|2) ;;
            *) urgency=1 ;;
        esac
        
        if [ -z "$summary" ]; then
            ids_to_dispatch+=("$id")
            continue
        fi
        
        add_to_queue "$id" "$app" "$summary" "$body" "$urgency"
        
        ids_to_dispatch+=("$id")
        
        count=$((count + 1))
        
        echo "  📬 Enfileirada: [$app] $summary" >&2
        
    done <<< "$undispatched"
    
    if [ ${#ids_to_dispatch[@]} -gt 0 ]; then
        local jq_filter='.'
        for id in "${ids_to_dispatch[@]}"; do
            jq_filter="$jq_filter | (.notifications[] | select(.id == \"$id\") | .dispatch) = true"
        done
        
        jq "$jq_filter" "$NOTIF_FILE" > "$NOTIF_FILE.tmp" && \
        mv "$NOTIF_FILE.tmp" "$NOTIF_FILE"
    fi
    
    if [ $count -gt 0 ]; then
        echo "  ✓ Disparadas $count notificações" >&2
        
        if [ -x "$DISPLAY_SCRIPT" ]; then
            for i in {1..3}; do
                "$DISPLAY_SCRIPT" process 2>/dev/null && break
                sleep 0.2
            done
        else
            echo "  ⚠ display.sh não encontrado ou sem permissão de execução" >&2
        fi
        
        local unread_count=$(jq '[.notifications[] | select(.read == false)] | length' "$NOTIF_FILE" 2>/dev/null)
        eww update notifications_unread="$unread_count" 2>/dev/null &
    fi
}

echo "  Monitorando notificações a cada ${WATCH_INTERVAL}s..." >&2
echo "  Pressione Ctrl+C para parar" >&2
echo "" >&2

while true; do
    dispatch_notifications
    sleep "$WATCH_INTERVAL"
done
