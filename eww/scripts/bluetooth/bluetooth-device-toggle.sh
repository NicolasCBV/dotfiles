#!/bin/bash
MAC="$(echo "${1}" | base64 -d 2>/dev/null)"
if [ -z "$MAC" ]; then
    notify-send -u critical "Erro Bluetooth" "Endereço MAC inválido"
    exit 1
fi
if ! command -v bluetoothctl &> /dev/null; then
    notify-send -u critical "Erro Bluetooth" "bluetoothctl não encontrado"
    exit 1
fi
DEVICE_NAME=$(bluetoothctl info "$MAC" 2>/dev/null | grep "Name:" | cut -d' ' -f2-)
if [ -z "$DEVICE_NAME" ]; then
    DEVICE_NAME="$MAC"
fi
is_connected() {
    echo 'info "$MAC"' | bluetoothctl | grep -q "Connected: yes"
}
is_paired() {
    echo 'info "$MAC"' | bluetoothctl | grep -q "Paired: yes"
}
update_eww() {
    sleep 1
    if command -v eww &> /dev/null; then
        eww update bluetooth-status="$(~/.config/eww/scripts/bluetooth/bluetooth-status.sh)" 2>/dev/null
        eww update bluetooth-devices="$(~/.config/eww/scripts/bluetooth/bluetooth-list.sh)" 2>/dev/null
    fi
}
LOG_FILE="/tmp/bluetooth-connect.log"
echo "$(date): Processando '$DEVICE_NAME' ($MAC)" >> "$LOG_FILE"

echo "Running!"
if ! is_connected; then
    echo "Connecting!"

    if ! is_paired; then 
        echo -e "agent on\ndefault-agent" | bluetoothctl > /dev/null 2>&1
        
        OUTPUT=$(timeout 30 bash -c "printf 'pair %s\nquit\n' '$MAC' | bluetoothctl" 2>&1)
        EXIT_CODE=$?
        
        if [ $EXIT_CODE -eq 124 ]; then
            notify-send -u critical "Erro Bluetooth" "Timeout ao parear com $DEVICE_NAME"
            echo "$(date): Timeout ao parear" >> "$LOG_FILE"
            exit 1
        fi
        
        if [ $EXIT_CODE -ne 0 ]; then
            if echo "$OUTPUT" | grep -qi "already"; then
                :
            elif echo "$OUTPUT" | grep -qi "confirm"; then
                notify-send "Bluetooth" "Confirme o pareamento em $DEVICE_NAME"
                sleep 3
            else
                ERROR_MSG=$(echo "$OUTPUT" | grep -i "failed\|error" | tail -n1)
                [ -z "$ERROR_MSG" ] && ERROR_MSG="Falha desconhecida"
                notify-send -u critical "Erro Bluetooth" "Falha ao parear: $ERROR_MSG"
                echo "$(date): Erro ao parear: $OUTPUT" >> "$LOG_FILE"
                exit 1
            fi
        fi
        
        printf "trust %s\nquit\n" "$MAC" | bluetoothctl > /dev/null 2>&1
        
        sleep 1
    fi

    OUTPUT=$({ echo "connect $MAC"; sleep 5; } | timeout 20 bluetoothctl 2>&1)
    EXIT_CODE=$?

    sleep 3

    if [ $EXIT_CODE -eq 124 ]; then
        notify-send -u critical "Erro Bluetooth" "Timeout ao conectar a $DEVICE_NAME"
        echo "$(date): Timeout ao conectar" >> "$LOG_FILE"
        exit 1
    fi
else
    OUTPUT=$(printf "disconnect %s\nquit\n" "$MAC" | bluetoothctl 2>&1)
    EXIT_CODE=$?
    
    sleep 3
    
    if is_connected; then
        notify-send -u critical "Erro Bluetooth" "Falha ao desconectar de $DEVICE_NAME"
        echo "$(date): Erro ao desconectar: $OUTPUT" >> "$LOG_FILE"
        exit 1
    else
        notify-send "Bluetooth" "Desconectado de $DEVICE_NAME"
        echo "$(date): Desconectado de '$DEVICE_NAME'" >> "$LOG_FILE"
        update_eww &
        exit 0
    fi
fi
