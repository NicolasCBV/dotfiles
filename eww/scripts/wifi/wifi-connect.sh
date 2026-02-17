#!/bin/bash

SSID="$(echo "${1}" | base64 -d)"

if [ -z "$SSID" ]; then
    notify-send "Erro WiFi" "SSID não fornecido"
    exit 1
fi

saved_connections=$(nmcli -t -f TYPE,NAME connection show 2>/dev/null | grep "^802-11-wireless:" | cut -d: -f2 | sed 's/ */ /g' | sed 's/^ *//;s/ *$//')

if echo "$saved_connections" | grep -Fxq "$SSID"; then
    OUTPUT=$(nmcli connection up "$SSID" 2>&1)
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]; then
        exit 0
    else
        notify-send "WiFi" "Perfil corrompido. Pedindo senha novamente..."
        nmcli connection delete "$SSID" 2>/dev/null
        echo "$(date): Perfil deletado para '$SSID' - Erro: $OUTPUT" >> /tmp/wifi-connect.log
    fi
fi

PASSWORD=$(zenity --password --title="Conectar ao WiFi" --text="Digite a senha para '$SSID':")

if [ -z "$PASSWORD" ]; then
    notify-send "WiFi" "Conexão cancelada"
    exit 0
fi

WIFI_DEVICE=$(nmcli -t -f DEVICE,TYPE device | grep ":wifi$" | head -n1 | cut -d: -f1)

if [ -z "$WIFI_DEVICE" ]; then
    notify-send "Erro WiFi" "Dispositivo WiFi não encontrado"
    exit 1
fi

nmcli connection delete "$SSID" 2>/dev/null

OUTPUT=$(nmcli device wifi connect "$SSID" password "$PASSWORD" ifname "$WIFI_DEVICE" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo "$(date): Conectado com sucesso a '$SSID'" >> /tmp/wifi-connect.log
else
    ERROR_MSG=$(echo "$OUTPUT" | tail -n1)
    notify-send "Erro WiFi" "$ERROR_MSG"
    echo "$(date): Falha ao conectar a '$SSID': $OUTPUT" >> /tmp/wifi-connect.log
fi
