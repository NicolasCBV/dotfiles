#!/bin/bash

if ! command -v bluetoothctl &> /dev/null; then
    echo "unavailable"
    exit 0
fi

if ! systemctl is-active --quiet bluetooth 2>/dev/null; then
    echo "disconnected"
    exit 0
fi

BT_POWER=$(echo "show" | bluetoothctl 2>/dev/null | grep -i "Powered:" | awk '{print $2}')

if [ -z "$BT_POWER" ]; then
    BT_POWER=$(timeout 2 bluetoothctl show 2>/dev/null | grep -i "Powered:" | awk '{print $2}')
fi

if [ -z "$BT_POWER" ]; then
    if command -v dbus-send &> /dev/null; then
        BT_POWER=$(dbus-send --system --print-reply --dest=org.bluez \
            /org/bluez/hci0 org.freedesktop.DBus.Properties.Get \
            string:org.bluez.Adapter1 string:Powered 2>/dev/null | \
            grep -i "boolean" | awk '{print $2}')
        
        [ "$BT_POWER" = "true" ] && BT_POWER="yes"
        [ "$BT_POWER" = "false" ] && BT_POWER="no"
    fi
fi

if [ -z "$BT_POWER" ]; then
    if [ -d "/sys/class/bluetooth/hci0" ]; then
        BT_POWER="yes"
    fi
fi

if [ -z "$BT_POWER" ] || [ "$BT_POWER" = "no" ]; then
    echo "disconnected"
    exit 0
fi

CONNECTED_DEVICES=$(echo "devices Connected" | bluetoothctl 2>/dev/null | grep "^Device")

if [ -z "$CONNECTED_DEVICES" ]; then
    CONNECTED_DEVICES=$(timeout 2 bluetoothctl devices Connected 2>/dev/null | grep "^Device")
fi

if [ -n "$CONNECTED_DEVICES" ]; then
    echo "connected"
else
    echo "on"
fi
