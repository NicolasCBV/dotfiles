#!/bin/bash

WEATHER_FILE="/tmp/environment-data.json"

fallback_text() {
    if [[ "$LANG" == pt_BR* ]]; then
        echo "Não foi possível ler informações do tempo! Verifique a sua conexão com a internet e sua chave API da Open Weather."
    else
        echo "Could not read weather information properly! Please check your network connection or Open Weather API key."
    fi
}

if [ ! -f "$WEATHER_FILE" ]; then
    fallback_text
    exit 0
fi

temp=$(jq -r '.main.temp' "$WEATHER_FILE" 2>/dev/null)
speed=$(jq -r '.wind.speed' "$WEATHER_FILE" 2>/dev/null)
humidity=$(jq -r '.main.humidity' "$WEATHER_FILE" 2>/dev/null)
city=$(jq -r '.name' "$WEATHER_FILE" 2>/dev/null)

if [ "$temp" = "null" ] || [ -z "$temp" ]; then
    fallback_text
    exit 0
fi

temp_c=$(awk "BEGIN {printf \"%.2f\", $temp - 273.15}")

speed_kmh=$(awk "BEGIN {printf \"%.2f\", $speed * 3.6}")

if [[ "$LANG" == pt_BR* ]]; then
    echo "A temperatura atual em $city é de ${temp_c}°C, com velocidade do vento de ${speed_kmh} km/h e umidade de ${humidity}%."
else
    echo "The current temperature at $city is ${temp_c}°C, with a wind speed of ${speed_kmh} km/h and humidity at ${humidity}%."
fi
