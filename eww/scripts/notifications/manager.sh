#!/bin/bash

DATA_DIR="$HOME/.local/share/eww"
NOTIF_FILE="$DATA_DIR/notifications.json"
CACHE_DIR="$HOME/.cache/eww/notifications"
QUEUE_FILE="$CACHE_DIR/queue"

mkdir -p "$DATA_DIR" "$CACHE_DIR"
[ ! -f "$NOTIF_FILE" ] && echo '{"notifications":[]}' > "$NOTIF_FILE"
touch "$QUEUE_FILE"

escape_string() {
    local str="$1"
    str="${str//$'\n'/ }"
    str="${str//$'\r'/ }"
    str="${str//$'\t'/ }"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    echo "$str"
}

generate_list() {
    local notif_count=$(jq '.notifications | length' "$NOTIF_FILE" 2>/dev/null || echo "0")
    
    local OUTPUT='(box :class "notifications-list" :orientation "v" :spacing 8'
    
    if [ "$notif_count" -eq 0 ] || [ -z "$notif_count" ]; then
        OUTPUT+=$'\n  (box'
        OUTPUT+=$'\n    :class "notifications-empty"'
        OUTPUT+=$'\n    :orientation "v"'
        OUTPUT+=$'\n    :valign "center"'
        OUTPUT+=$'\n    :spacing 8'
        OUTPUT+=$'\n    (label :text "󰂜" :class "empty-icon")'
        OUTPUT+=$'\n    (label :text "Nenhuma notificação" :class "empty-text"))'
    else
        local now=$(date +%s)
        
        while IFS=$'\t' read -r id app summary body timestamp read_status; do
            [ -z "$id" ] && continue
            
            id=$(escape_string "$id")
            app=$(escape_string "$app")
            summary=$(escape_string "$summary")
            body=$(escape_string "$body")
            
            if [ "$read_status" = "true" ]; then
                local item_class="notification-item read"
                local mark_visible="false"
            else
                local item_class="notification-item unread"
                local mark_visible="true"
            fi
            
            local diff=$((now - timestamp))
            local time_text
            if [ $diff -gt 86400 ]; then
                time_text="$((diff / 86400))d"
            elif [ $diff -gt 3600 ]; then
                time_text="$((diff / 3600))h"
            elif [ $diff -gt 60 ]; then
                time_text="$((diff / 60))m"
            else
                time_text="agora"
            fi
            
            local body_visible="true"
            [ -z "$body" ] || [ "$body" = "null" ] && body_visible="false"
            
            OUTPUT+=$'\n  (box :class "'"$item_class"'" :orientation "v" :space-evenly false :spacing 4'
            OUTPUT+=$'\n    (box :class "notification-header" :orientation "h" :space-evenly false'
            OUTPUT+=$'\n      (label :class "notification-app" :text "'"$app"'" :halign "start" :hexpand true :limit-width 40)'
            OUTPUT+=$'\n      (label :class "notification-time" :text "'"$time_text"'" :halign "end"))'
            OUTPUT+=$'\n    (label :class "notification-summary" :text "'"$summary"'" :halign "start" :wrap true)'
            
            [ "$body_visible" = "true" ] && \
                OUTPUT+=$'\n    (label :class "notification-body" :text "'"$body"'" :halign "start" :wrap true)'
            
            OUTPUT+=$'\n    (box :class "notification-actions" :orientation "h" :halign "end" :space-evenly false :spacing 8'
            
            if [ "$mark_visible" = "true" ]; then
                OUTPUT+=$'\n      (eventbox :cursor "pointer"'
                OUTPUT+=$'\n        (button :class "action-button mark-read"'
                OUTPUT+=$'\n                :onclick "~/.config/eww/scripts/notifications/manager.sh mark-read '"'$id'"' &"'
                OUTPUT+=$'\n                (label :text "󰄬")))'
            fi
            
            OUTPUT+=$'\n      (eventbox :cursor "pointer"'
            OUTPUT+=$'\n        (button :class "action-button remove"'
            OUTPUT+=$'\n                :onclick "~/.config/eww/scripts/notifications/manager.sh remove '"'$id'"' &"'
            OUTPUT+=$'\n                (label :text "󰆴"))))'
            OUTPUT+=$'\n  )'
            
        done < <(jq -r '.notifications | sort_by(.timestamp) | reverse | .[0:15] | .[] | 
                       [.id, .app, .summary, .body, .timestamp, .read] | @tsv' \
                       "$NOTIF_FILE" 2>/dev/null)
    fi
    
    OUTPUT+=$'\n)'
    echo "$OUTPUT"
}

update_widgets() {
    local counts=$(jq -r '[
        (.notifications | length),
        ([.notifications[] | select(.read == false)] | length)
    ] | @tsv' "$NOTIF_FILE" 2>/dev/null || echo "0	0")
    
    local unread_count=$(echo "$counts" | cut -f2)
    
    {
        eww update notifications_unread="$unread_count" 2>/dev/null
        eww update notifications_widget="$(generate_list)" 2>/dev/null
    } &
}

LOCK_FILE="/tmp/eww_notif_update.lock"
update_widgets_debounced() {
    if [ -f "$LOCK_FILE" ]; then
        touch "${LOCK_FILE}.pending"
        return
    fi
    
    touch "$LOCK_FILE"
    
    update_widgets
    
    (
        sleep 0.3
        rm -f "$LOCK_FILE"
        
        if [ -f "${LOCK_FILE}.pending" ]; then
            rm -f "${LOCK_FILE}.pending"
            update_widgets
        fi
    ) &
}

check_undispatched() {
    echo "⚠️  AVISO: O watcher.sh agora faz isso automaticamente" >&2
    echo "   Este comando é mantido apenas para uso manual/debug" >&2
    echo "" >&2
    
    local undispatched_count=$(jq '[.notifications[] | select(.dispatch == false)] | length' "$NOTIF_FILE" 2>/dev/null)
    
    if [ "$undispatched_count" -eq 0 ]; then
        echo "✓ Nenhuma notificação pendente" >&2
        return 0
    fi
    
    echo "  Encontradas $undispatched_count notificações não disparadas" >&2
    echo "  O watcher deve disparar automaticamente em ~1 segundo" >&2
    echo "" >&2
    echo "  Se quiser forçar agora, use:" >&2
    echo "  force-process-notifications.sh" >&2
}

case "$1" in
    list)
        generate_list
        ;;
    
    mark-read)
        [ -z "$2" ] && exit 1
        jq --arg id "$2" \
           '(.notifications[] | select(.id == $id) | .read) = true' \
           "$NOTIF_FILE" > "$NOTIF_FILE.tmp" && \
        mv "$NOTIF_FILE.tmp" "$NOTIF_FILE"
        
        update_widgets_debounced
        ;;
    
    remove)
        [ -z "$2" ] && exit 1
        jq --arg id "$2" \
           '.notifications = [.notifications[] | select(.id != $id)]' \
           "$NOTIF_FILE" > "$NOTIF_FILE.tmp" && \
        mv "$NOTIF_FILE.tmp" "$NOTIF_FILE"
        
        update_widgets_debounced
        ;;
    
    clear-all)
        echo '{"notifications":[]}' > "$NOTIF_FILE"
        update_widgets_debounced
        ;;
    
    unread-count)
        jq -r '[.notifications[] | select(.read == false)] | length' \
           "$NOTIF_FILE" 2>/dev/null || echo "0"
        ;;
    
    check-undispatched)
        check_undispatched
        ;;
    
    *)
        echo "Uso: $0 {list|mark-read|remove|clear-all|unread-count|check-undispatched}"
        echo ""
        echo "NOTA: Na versão 3.0, o watcher.sh faz dispatch automático."
        echo "      check-undispatched é mantido apenas para debug."
        exit 1
        ;;
esac
