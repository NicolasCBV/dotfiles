#!/bin/bash

WIFI_INTERFACE=$(nmcli -t -f DEVICE,TYPE,STATE device | grep ":wifi:connected" | cut -d: -f1 | head -n1)

if [ -z "$WIFI_INTERFACE" ]; then
    echo "-- Mbps"
    exit 0
fi

if command -v iw &> /dev/null; then
    SPEED=$(iw dev "$WIFI_INTERFACE" link 2>/dev/null | grep -i "tx bitrate" | awk '{print $3 " " $4}')
    
    if [ -n "$SPEED" ]; then
        echo "$SPEED"
        exit 0
    fi
fi

if command -v iwconfig &> /dev/null; then
    SPEED=$(iwconfig "$WIFI_INTERFACE" 2>/dev/null | grep "Bit Rate" | awk -F'=' '{print $2}' | awk '{print $1 " " $2}')
    
    if [ -n "$SPEED" ]; then
        echo "$SPEED"
        exit 0
    fi
fi

SPEED=$(nmcli -f GENERAL.DEVICE,GENERAL.TYPE,GENERAL.STATE,GENERAL.CONNECTION device show "$WIFI_INTERFACE" 2>/dev/null | grep -i "speed" | awk '{print $2}')

if [ -n "$SPEED" ]; then
    echo "$SPEED Mbps"
else
    echo "-- Mbps"
fi
