#!/bin/bash

if ! command -v bluetoothctl &> /dev/null; then
    notify-send -u critical "Erro Bluetooth" "bluetoothctl não encontrado"
    exit 1
fi

bt_power=$(bluetoothctl show 2>/dev/null | grep "Powered:" | awk '{print $2}')
if [ "$bt_power" != "yes" ]; then
    bluetoothctl power on
    sleep 2
fi

bluetoothctl scan on &
SCAN_PID=$!

sleep 8

kill $SCAN_PID 2>/dev/null
bluetoothctl scan off 2>/dev/null

discovered_count=$(bluetoothctl devices | wc -l)
paired_count=$(bluetoothctl devices Paired | wc -l)
new_count=$((discovered_count - paired_count))

# Atualiza interface
if command -v eww &> /dev/null; then
    eww update bluetooth-devices="$(~/.config/eww/scripts/bluetooth/bluetooth-list.sh)" 2>/dev/null
fi
