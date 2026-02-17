#!/bin/bash

echo "(box :orientation \"v\" :spacing 4"

available_networks=$(nmcli -t -f SSID,SIGNAL,SECURITY device wifi list 2>/dev/null)

if [ -z "$available_networks" ]; then
    cat <<'EOF'
  (box
    :class "wifi-empty-state"
    :orientation "v"
    :spacing 12
    :space-evenly false
    (label
      :class "wifi-empty-icon"
      :text "󰤭")
    (label
      :class "wifi-empty-title"
      :text "Nenhuma rede encontrada")
    (label
      :class "wifi-empty-subtitle"
      :text "Ative o WiFi ou aproxime-se de uma rede")))
EOF
    echo ")"
    exit 0
fi

echo "$available_networks" | while IFS=: read -r ssid signal security; do
    signal=$(echo "$signal" | xargs)
    security=$(echo "$security" | xargs)
    
    if [ -z "$ssid" ]; then
        continue
    fi
    
    parsed_signal=$((signal))
    if [ $parsed_signal -gt 75 ]; then
        icon="󰤨"
    elif [ $parsed_signal -gt 50 ]; then
        icon="󰤥"
    elif [ $parsed_signal -gt 25 ]; then
        icon="󰤢"
    else
        icon="󰤟"
    fi
    
    if echo "$security" | grep -q "WPA"; then
        lock_icon=""
    else
        lock_icon="󰿆"
    fi
    
    # Codifica o SSID em base64 para evitar problemas com espaços e caracteres especiais
    ssid_b64=$(echo -n "$ssid" | base64 -w 0)
    
    cat <<EOF
  (eventbox
    :cursor "pointer"
    (button
      :class "wifi-network-item"
      :onclick "bash ~/.config/eww/scripts/wifi/wifi-connect.sh '$ssid_b64' &"
      (box
        :orientation "h"
        :space-evenly false
        :spacing 12
        (label :class "network-icon" :text "$icon")
        (box
          :orientation "v"
          :halign "start"
          :hexpand true
          (label :class "network-ssid" :text "$ssid" :halign "start")
          (label :class "network-security" :text "$lock_icon $security" :halign "start"))
        (label :class "network-signal" :text "${signal}%"))))
EOF
done

echo ")"
