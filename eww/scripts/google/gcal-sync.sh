#!/bin/bash

# ============================================================================
# Google Calendar Sync - Com suporte a eventos recorrentes
# ============================================================================

CONFIG_DIR="$HOME/.local/eww/gcal-sync"
CRED_DIR="/etc/eww/cred"
TOKEN_FILE="$CRED_DIR/token.json"
COLOR_MAP_FILE="$CONFIG_DIR/color_map.json"
OUTPUT_FILE="/etc/eww/cred/gcal-sync/calendar_marks.json"

API_BASE="https://www.googleapis.com/calendar/v3"

refresh_token_if_needed() {
    if [ ! -f "$TOKEN_FILE" ]; then
        echo "Token não encontrado. Execute: bash gcal-oauth-setup.sh"
        exit 1
    fi

    REFRESH_TOKEN=$(jq -r '.refresh_token // empty' "$TOKEN_FILE")

    if [ -z "$REFRESH_TOKEN" ]; then
        echo "Sem refresh token - usando access token atual"
        return 0
    fi

    CLIENT_ID=$(jq -r '.client_id' "$TOKEN_FILE")
    CLIENT_SECRET=$(jq -r '.client_secret' "$TOKEN_FILE")

    NEW_TOKEN=$(curl -s -X POST https://oauth2.googleapis.com/token \
        -d "client_id=$CLIENT_ID" \
        -d "client_secret=$CLIENT_SECRET" \
        -d "refresh_token=$REFRESH_TOKEN" \
        -d "grant_type=refresh_token")

    NEW_ACCESS_TOKEN=$(echo "$NEW_TOKEN" | jq -r '.access_token // empty')

    if [ -n "$NEW_ACCESS_TOKEN" ]; then
        TMP_FILE=$(mktemp /tmp/token_XXXXXX.json)
        jq --arg token "$NEW_ACCESS_TOKEN" '.access_token = $token' \
            "$TOKEN_FILE" > "$TMP_FILE"
        sudo mv "$TMP_FILE" "$TOKEN_FILE"
    fi
}

get_access_token() {
    jq -r '.access_token' "$TOKEN_FILE"
}

list_calendars() {
    local token="$1"

    curl -s -H "Authorization: Bearer $token" \
        "$API_BASE/users/me/calendarList" |
    jq -r '.items[] |
        select(.accessRole == "owner" or .accessRole == "writer" or .accessRole == "reader") |
        "\(.id)|\(.summary)|\(.backgroundColor // "#3b82f6")"'
}

fetch_events() {
    local token="$1"
    local calendar_id="$2"
    local time_min="$3"
    local time_max="$4"

    local encoded_id
    encoded_id=$(printf %s "$calendar_id" | jq -sRr @uri)

    curl -s -H "Authorization: Bearer $token" \
        "$API_BASE/calendars/$encoded_id/events?timeMin=$time_min&timeMax=$time_max&singleEvents=true&orderBy=startTime&maxResults=2500" |
    jq -r --arg cal_id "$calendar_id" '.items[]? |
        select(.status != "cancelled") |
        {
            date:        (.start.date // (.start.dateTime | split("T")[0])),
            title:       .summary,
            calendar_id: $cal_id,
            recurrence:  (if .recurringEventId then "recurring" else null end),
            time_start:  (.start.dateTime // "" | if . != "" then (split("T")[1] | split("+")[0] | split("-")[0] | .[0:5]) else "" end),
            time_end:    (.end.dateTime   // "" | if . != "" then (split("T")[1] | split("+")[0] | split("-")[0] | .[0:5]) else "" end)
        } |
        select(.date != null) |
        "\(.date)|\(.title)|\(.calendar_id)|\(.recurrence // "")|\(.time_start)|\(.time_end)"'
}

get_calendar_color() {
    local calendar_name="$1"
    local default_color="${2:-#3b82f6}"

    if [ -f "$COLOR_MAP_FILE" ]; then
        color=$(jq -r --arg cal "$calendar_name" --arg def "$default_color" \
            '.calendars[$cal] // $def' "$COLOR_MAP_FILE")
        echo "$color"
    else
        echo "$default_color"
    fi
}

# Formata o título com horário quando disponível.
# Eventos de dia inteiro nao tem time_start, entao o titulo fica sem horario.
# Exemplos:
#   "09:00-10:30 Reuniao"   (evento com inicio e fim)
#   "09:00 Reuniao"         (evento com inicio mas sem fim informado)
#   "Feriado Nacional"      (evento de dia inteiro)
format_title() {
    local title="$1"
    local time_start="$2"
    local time_end="$3"

    if [ -n "$time_start" ] && [ -n "$time_end" ]; then
        echo "${time_start}-${time_end} ${title}"
    elif [ -n "$time_start" ]; then
        echo "${time_start} ${title}"
    else
        echo "${title}"
    fi
}

sync_calendar() {
    echo "Sincronizando Google Calendar (com eventos recorrentes)..."

    refresh_token_if_needed

    TOKEN=$(get_access_token)

    if [ -z "$TOKEN" ]; then
        echo "Erro ao obter token"
        exit 1
    fi

    START_DATE=$(date '+%Y-%m-%d')
    END_DATE=$(date -d '+12 months' '+%Y-%m-%d')
    TIME_MIN="${START_DATE}T00:00:00Z"
    TIME_MAX="${END_DATE}T23:59:59Z"

    echo "Periodo: $START_DATE ate $END_DATE"
    echo "Eventos recorrentes serao expandidos"

    echo "Buscando calendarios..."
    CALENDARS=$(list_calendars "$TOKEN")

    if [ -z "$CALENDARS" ]; then
        echo "Nenhum calendario encontrado"
        exit 1
    fi

    declare -A events_map
    recurring_count=0
    total_count=0

    while IFS='|' read -r cal_id cal_name cal_color; do
        echo "$cal_name"

        events=$(fetch_events "$TOKEN" "$cal_id" "$TIME_MIN" "$TIME_MAX")

        # Le os 6 campos: date|title|calendar_id|recurrence|time_start|time_end
        while IFS='|' read -r date title calendar_id is_recurring time_start time_end; do
            [ -z "$date" ] && continue

            ((total_count++))
            [ "$is_recurring" = "recurring" ] && ((recurring_count++))

            color=$(get_calendar_color "$cal_name" "$cal_color")

            formatted_title=$(format_title "$title" "$time_start" "$time_end")

            if [ -z "${events_map[$date]}" ]; then
                events_map[$date]="${formatted_title}|${color}"
            fi
        done <<< "$events"
    done <<< "$CALENDARS"

    echo ""
    echo "Gerando JSON..."

    TMP_OUTPUT=$(mktemp /tmp/calendar_marks_XXXXXX.json)

    echo "{"             > "$TMP_OUTPUT"
    echo '  "marks": [' >> "$TMP_OUTPUT"

    first=true
    for date in $(printf '%s\n' "${!events_map[@]}" | sort); do
        IFS='|' read -r title color <<< "${events_map[$date]}"

        if [ "$first" = false ]; then
            echo "," >> "$TMP_OUTPUT"
        fi
        first=false

        title_escaped=$(printf '%s' "$title" | perl -0777 -pe 's/\s+\z//' | jq -Rs .)

        cat >> "$TMP_OUTPUT" << ENDJSON
    {
      "date": "$date",
      "title": $title_escaped,
      "color": "$color"
    }
ENDJSON
    done

    echo ""       >> "$TMP_OUTPUT"
    echo '  ]'    >> "$TMP_OUTPUT"
    echo '}'      >> "$TMP_OUTPUT"

    if jq '.' "$TMP_OUTPUT" > /dev/null 2>&1; then
        mv "$TMP_OUTPUT" "$OUTPUT_FILE"
        chmod o+r "$OUTPUT_FILE"
        event_count=$(jq '.marks | length' "$OUTPUT_FILE")
        echo "Sincronizacao concluida!"
        echo "Total de eventos processados: $total_count"
        echo "Eventos recorrentes expandidos: $recurring_count"
        echo "Marcacoes unicas por data: $event_count"
    else
        echo "Erro ao gerar JSON"
        rm -f "$TMP_OUTPUT"
        exit 1
    fi
}

list_available_calendars() {
    echo "Calendarios disponiveis:"
    echo ""

    refresh_token_if_needed
    TOKEN=$(get_access_token)

    list_calendars "$TOKEN" | while IFS='|' read -r id name color; do
        echo "  - $name"
        echo "    ID: $id"
        echo "    Cor: $color"
        echo ""
    done
}

test_connection() {
    echo "Testando conexao com Google Calendar API..."

    refresh_token_if_needed
    TOKEN=$(get_access_token)

    RESPONSE=$(curl -s -w "\n%{http_code}" -H "Authorization: Bearer $TOKEN" \
        "$API_BASE/users/me/calendarList")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    if [ "$HTTP_CODE" = "200" ]; then
        CAL_COUNT=$(echo "$BODY" | jq '.items | length')
        echo "Conexao bem-sucedida!"
        echo "Calendarios encontrados: $CAL_COUNT"
    else
        echo "Erro na conexao"
        echo "HTTP Code: $HTTP_CODE"
        echo "$BODY" | jq '.'
        exit 1
    fi
}

mkdir -p "$CONFIG_DIR"

case "${1:-sync}" in
    sync)
        sync_calendar
        ;;
    list)
        list_available_calendars
        ;;
    test)
        test_connection
        ;;
    *)
        echo "Uso: $0 [sync|list|test]"
        echo ""
        echo "Comandos:"
        echo "  sync - Sincronizar calendarios (expande recorrentes)"
        echo "  list - Listar calendarios disponiveis"
        echo "  test - Testar conexao com API"
        exit 1
        ;;
esac





























































































































































































































































