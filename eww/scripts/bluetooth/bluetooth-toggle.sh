#!/bin/bash

(
    exec timeout 3s bash << 'EOF'
    
    LOG_FILE="/tmp/bluetooth-toggle.log"
    echo "$(date): Script iniciado" >> "$LOG_FILE"
    
    BT_STATUS=$(rfkill list bluetooth | grep -q "Soft blocked: no" && echo "on" || echo "off")
    
    if [ "$BT_STATUS" = "on" ]; then
        notify-send "Bluetooth" "Desligando..."
        rfkill block bluetooth
        echo "$(date): Bluetooth desligado" >> "$LOG_FILE"
    else
        notify-send "Bluetooth" "Ligando..."
        rfkill unblock bluetooth
        echo "$(date): Bluetooth ligado" >> "$LOG_FILE"
    fi
    
    sleep 0.3
    if command -v eww &> /dev/null; then
        eww update bluetooth-status="$($HOME/.config/eww/scripts/bluetooth/bluetooth-status.sh)" 2>/dev/null || true
        eww update bluetooth-devices="$($HOME/.config/eww/scripts/bluetooth/bluetooth-list.sh)" 2>/dev/null || true
    fi
    
    echo "$(date): Script finalizado" >> "$LOG_FILE"
EOF
) &

exit 0
