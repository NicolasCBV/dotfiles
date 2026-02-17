#!/bin/bash

CACHE_DIR="$HOME/.cache/eww/notifications"
QUEUE_FILE="$CACHE_DIR/queue"
ACTIVE_FILE="$CACHE_DIR/active"
QUEUE_LOCK="/tmp/eww_notif_queue.lock"
MAX_VISIBLE=3

mkdir -p "$CACHE_DIR"
touch "$QUEUE_FILE" "$ACTIVE_FILE"

escape_for_eww() {
    local text="$1"
    text="${text//\"/\\\"}"
    text="${text//\$/\\\$}"
    text="${text//\`/\\\`}"
    echo "$text"
}

validate_number() {
    case "$1" in
        ''|*[!0-9]*) echo "1" ;;
        *) echo "$1" ;;
    esac
}

validate_slot() {
    case "$1" in
        1|2|3) echo "$1" ;;
        *) echo "" ;;
    esac
}

get_urgency_class() {
    case "$1" in
        0) echo "low" ;;
        2) echo "critical" ;;
        *) echo "normal" ;;
    esac
}

get_urgency_timeout() {
    case "$1" in
        0) echo 3000 ;;
        2) echo 0 ;;
        *) echo 5000 ;;
    esac
}

show_notification() {
    local id="$1"
    local app="$2"
    local summary="$3"
    local body="$4"
    local urgency="$5"
    local slot="$6"
    
    slot=$(validate_slot "$slot")
    [ -z "$slot" ] && return 1
    
    urgency=$(validate_number "$urgency")

    summary=$(echo "$summary" | sed 's/\\n/\n/g')
    body=$(echo "$body" | sed 's/\\n/\n/g')
    
    body=$(echo "$body" | fold -w 50 -s)
    
    id=$(escape_for_eww "$id")
    app=$(escape_for_eww "$app")
    summary=$(escape_for_eww "$summary")
    body=$(escape_for_eww "$body")
    
    local urgency_class=$(get_urgency_class "$urgency")
    local timeout=$(get_urgency_timeout "$urgency")
    
    echo "  🔔 Mostrando notificação no slot $slot: [$app] $summary" >&2
    
    eww update notif_${slot}_visible=true 2>/dev/null
    eww update notif_${slot}_id="$id" 2>/dev/null
    eww update notif_${slot}_app="$app" 2>/dev/null
    eww update notif_${slot}_summary="$summary" 2>/dev/null
    eww update notif_${slot}_body="$body" 2>/dev/null
    eww update notif_${slot}_urgency="$urgency_class" 2>/dev/null
    
    if [ "$timeout" != "0" ]; then
        (
            sleep "$((timeout / 1000))"
            hide_notification "$slot"
        ) &
    fi
    
    return 0
}

hide_notification() {
    local slot=$(validate_slot "$1")
    [ -z "$slot" ] && return 1
    
    echo "  Ocultando notificação do slot $slot" >&2
    
    eww update "notif_${slot}_visible=false" 2>/dev/null
    
    local timeout=0
    while [ -f "$QUEUE_LOCK" ] && [ $timeout -lt 50 ]; do
        sleep 0.1
        timeout=$((timeout + 1))
    done
    
    touch "$QUEUE_LOCK"
    grep -v "^${slot}|" "$ACTIVE_FILE" > "$ACTIVE_FILE.tmp" 2>/dev/null && \
        mv "$ACTIVE_FILE.tmp" "$ACTIVE_FILE"
    rm -f "$QUEUE_LOCK"
    
    process_queue
}

find_free_slot() {
    for i in {1..3}; do
        if ! grep -q "^${i}|" "$ACTIVE_FILE" 2>/dev/null; then
            echo "$i"
            return
        fi
    done
    echo ""
}

process_queue() {
    for i in {1..3}; do
        local visible=$(eww get notif_${i}_visible 2>/dev/null || echo "false")
        if [ "$visible" = "false" ]; then
            grep -v "^${i}|" "$ACTIVE_FILE" > "$ACTIVE_FILE.tmp" 2>/dev/null && \
                mv "$ACTIVE_FILE.tmp" "$ACTIVE_FILE"
        fi
    done

    if [ ! -s "$QUEUE_FILE" ]; then
        return 0
    fi
    
    local active_count=$(wc -l < "$ACTIVE_FILE" 2>/dev/null || echo "0")
    if [ "$active_count" -ge "$MAX_VISIBLE" ]; then
        echo "  ⏸ Fila pausada: $active_count/$MAX_VISIBLE slots em uso" >&2
        return 0
    fi
    
    local timeout=0
    while [ -f "$QUEUE_LOCK" ] && [ $timeout -lt 50 ]; do
        sleep 0.1
        timeout=$((timeout + 1))
    done
    
    touch "$QUEUE_LOCK"
    
    local line=$(head -n 1 "$QUEUE_FILE" 2>/dev/null)
    
    if [ -n "$line" ]; then
        tail -n +2 "$QUEUE_FILE" > "$QUEUE_FILE.tmp" 2>/dev/null && \
            mv "$QUEUE_FILE.tmp" "$QUEUE_FILE"
    fi
    
    rm -f "$QUEUE_LOCK"
    
    if [ -z "$line" ]; then
        return 0
    fi
    
    IFS='|' read -r id app summary body urgency <<< "$line"
    
    if [ -z "$summary" ]; then
        echo "  ⚠ Notificação sem summary, pulando" >&2
        process_queue
        return 0
    fi
    
    local slot=$(find_free_slot)
    if [ -z "$slot" ]; then
        echo "  ⚠ Nenhum slot livre, recolocando na fila" >&2
        touch "$QUEUE_LOCK"
        echo "$line" | cat - "$QUEUE_FILE" > "$QUEUE_FILE.tmp" && \
            mv "$QUEUE_FILE.tmp" "$QUEUE_FILE"
        rm -f "$QUEUE_LOCK"
        return 0
    fi
    
    echo "${slot}|${id}" >> "$ACTIVE_FILE"
    
    if show_notification "$id" "$app" "$summary" "$body" "$urgency" "$slot"; then
        echo "  ✓ Notificação exibida com sucesso" >&2
    else
        echo "  ✗ Erro ao exibir notificação" >&2
        grep -v "^${slot}|" "$ACTIVE_FILE" > "$ACTIVE_FILE.tmp" 2>/dev/null && \
            mv "$ACTIVE_FILE.tmp" "$ACTIVE_FILE"
    fi
    
    local remaining_slots=$((MAX_VISIBLE - $(wc -l < "$ACTIVE_FILE" 2>/dev/null || echo "0")))
    if [ $remaining_slots -gt 0 ] && [ -s "$QUEUE_FILE" ]; then
        sleep 0.1
        process_queue
    fi
}

case "$1" in
    process)
        echo "  🔄 Processando fila de notificações..." >&2
        process_queue
        ;;
    close)
        if [ -z "$2" ]; then
            echo "  ✗ Erro: slot não especificado para close" >&2
            exit 1
        fi
        hide_notification "$2"
        ;;
    *)
        echo "Uso: $0 {process|close SLOT}" >&2
        exit 1
        ;;
esac
