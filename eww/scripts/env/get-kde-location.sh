#!/bin/bash

ENV_DATA="/tmp/environment-data.json"

if [ ! -f "$ENV_DATA" ]; then
    echo "Erro: $ENV_DATA não encontrado" >&2
    exit 1
fi

case "$1" in
    lat)
        jq -r '.coord.lat // 0' "$ENV_DATA" 2>/dev/null || echo "0"
        ;;
    lon)
        jq -r '.coord.lon // 0' "$ENV_DATA" 2>/dev/null || echo "0"
        ;;
    city)
        jq -r '.name // "Desconhecido"' "$ENV_DATA" 2>/dev/null || echo "Desconhecido"
        ;;
    coords)
        lat=$(jq -r '.coord.lat // 0' "$ENV_DATA" 2>/dev/null)
        lon=$(jq -r '.coord.lon // 0' "$ENV_DATA" 2>/dev/null)
        echo "Lat: ${lat}° | Lon: ${lon}°"
        ;;
    *)
        cat "$ENV_DATA" 2>/dev/null || echo '{"error": "No data"}'
        ;;
esac
