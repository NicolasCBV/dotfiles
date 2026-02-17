#!/bin/bash

STATE_DIR="$HOME/.cache/eww/calendar"
STATE_FILE="$STATE_DIR/current_month"

mkdir -p "$STATE_DIR"

if [ ! -f "$STATE_FILE" ]; then
    date '+%Y-%m' > "$STATE_FILE"
fi

CURRENT=$(cat "$STATE_FILE")
YEAR=$(echo "$CURRENT" | cut -d'-' -f1)
MONTH=$(echo "$CURRENT" | cut -d'-' -f2)

case "$MONTH" in
    01) MONTH_NAME="Janeiro" ;;
    02) MONTH_NAME="Fevereiro" ;;
    03) MONTH_NAME="Março" ;;
    04) MONTH_NAME="Abril" ;;
    05) MONTH_NAME="Maio" ;;
    06) MONTH_NAME="Junho" ;;
    07) MONTH_NAME="Julho" ;;
    08) MONTH_NAME="Agosto" ;;
    09) MONTH_NAME="Setembro" ;;
    10) MONTH_NAME="Outubro" ;;
    11) MONTH_NAME="Novembro" ;;
    12) MONTH_NAME="Dezembro" ;;
esac

echo "$MONTH_NAME $YEAR"
