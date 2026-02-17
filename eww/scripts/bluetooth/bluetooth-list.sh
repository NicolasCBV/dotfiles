#!/bin/bash

get_device_icon() {
    local device_type="$1"
    
    case "$device_type" in
        *audio*|*headset*|*headphones*|*speaker*)
            echo "󰋋"
            ;;
        *mouse*)
            echo "󰍽"
            ;;
        *keyboard*)
            echo "󰌌"
            ;;
        *phone*|*mobile*)
            echo "󰄜"
            ;;
        *computer*|*laptop*)
            echo "󰟀"
            ;;
        *gamepad*|*joystick*|*controller*)
            echo "󰖺"
            ;;
        *watch*)
            echo "󰔡"
            ;;
        *tablet*)
            echo "󰓶"
            ;;
        *)
            echo "󰂯"
            ;;
    esac
}

get_battery_icon() {
    local battery="$1"
    
    if [ "$battery" -ge 90 ]; then
        echo "󰁹"
    elif [ "$battery" -ge 70 ]; then
        echo "󰂀"
    elif [ "$battery" -ge 50 ]; then
        echo "󰁾"
    elif [ "$battery" -ge 30 ]; then
        echo "󰁼"
    elif [ "$battery" -ge 10 ]; then
        echo "󰁺"
    else
        echo "󰂎"
    fi
}

if ! command -v bluetoothctl &> /dev/null; then
    cat <<'EOF'
(box :orientation "v" :spacing 4
  (box
    :class "bluetooth-empty-state"
    :orientation "v"
    :spacing 12
    :space-evenly false
    (label
      :class "bluetooth-empty-icon"
      :text "󰂲")
    (label
      :class "bluetooth-empty-title"
      :text "Bluetooth não disponível")
    (label
      :class "bluetooth-empty-subtitle"
      :text "Instale bluez e bluez-utils")))
EOF
    exit 0
fi

bt_power=$(echo "show" | bluetoothctl 2>/dev/null | grep "Powered:" | awk '{print $2}')

if [ -z "$bt_power" ]; then
    bt_power=$(timeout 2 bluetoothctl show 2>/dev/null | grep "Powered:" | awk '{print $2}')
fi

if [ "$bt_power" != "yes" ]; then
    cat <<'EOF'
(box :orientation "v" :spacing 4
  (box
    :class "bluetooth-empty-state"
    :orientation "v"
    :spacing 12
    :space-evenly false
    (label
      :class "bluetooth-empty-icon"
      :text "󰂲")
    (label
      :class "bluetooth-empty-title"
      :text "Bluetooth desligado")
    (label
      :class "bluetooth-empty-subtitle"
      :text "Ative o Bluetooth para ver dispositivos")
    (eventbox
      :cursor "pointer"
      (button
        :class "bluetooth-empty-action-btn"
        :onclick "~/.config/eww/scripts/bluetooth/bluetooth-toggle.sh"
        (box
          :orientation "h"
          :spacing 8
          :space-evenly false
          :halign "center"
          (label :class "bluetooth-empty-action-icon" :text "󰂯")
          (label :text "Ativar Bluetooth"))))))
EOF
    exit 0
fi

echo "(box :orientation \"v\" :spacing 4"

paired_devices=$(echo "devices Paired" | bluetoothctl 2>/dev/null | grep "^Device")

if [ -z "$paired_devices" ]; then
    paired_devices=$(timeout 2 bluetoothctl devices Paired 2>/dev/null | grep "^Device")
fi

declare -A shown_devices

show_device() {
    local mac="$1"
    local name="$2"
    
    if [ -n "${shown_devices[$mac]}" ]; then
        return
    fi
    shown_devices[$mac]=1
    
    device_info=$(echo "info $mac" | bluetoothctl 2>/dev/null)
    
    if [ -z "$device_info" ]; then
        device_info=$(timeout 2 bluetoothctl info "$mac" 2>/dev/null)
    fi
    
    is_connected=$(echo "$device_info" | grep "Connected:" | awk '{print $2}')
    
    device_type=$(echo "$device_info" | grep -i "Icon:" | awk '{print tolower($2)}')
    if [ -z "$device_type" ]; then
        if echo "$device_info" | grep -qi "0000110b\|0000110e"; then
            device_type="audio"
        fi
    fi
    
    icon=$(get_device_icon "$device_type")
    
    if [ "$is_connected" = "yes" ]; then
        status="Conectado"
        status_class="connected"
        action_text="Desconectar"
    else
        status="Pareado"
        status_class="paired"
        action_text="Conectar"
    fi
    
    mac_b64=$(echo -n "$mac" | base64 -w 0)
    
    battery=$(echo "$device_info" | grep -i "Battery Percentage:" | awk '{print $4}' | tr -d '()')
    battery_display=""
    if [ -n "$battery" ]; then
        battery_icon=$(get_battery_icon "$battery")
        battery_display="(box :class \"device-battery\" :spacing 4 :space-evenly false (label :class \"battery-icon\" :text \"$battery_icon\") (label :text \"${battery}%\"))"
    fi
    
    name_escaped=$(echo "$name" | sed 's/"/\\"/g')
    
    cat <<EOF
  (eventbox
    :cursor "pointer"
    (button
      :class "bluetooth-device-item ${status_class}"
      :onclick "~/.config/eww/scripts/bluetooth/bluetooth-device-toggle.sh ${mac_b64} &"
      (box
        :orientation "h"
        :space-evenly false
        :spacing 12
        (label :class "device-icon" :text "$icon")
        (box
          :orientation "v"
          :halign "start"
          :hexpand true
          :spacing 2
          :space-evenly false
          (label :class "device-name" :text "$name_escaped" :halign "start" :limit-width 25 :truncate true)
          (box
            :orientation "h"
            :spacing 8
            :space-evenly false
            (label :class "device-status" :text "$status")
            $battery_display))
        (label :class "device-arrow" :text ""))))
EOF
}

device_count=0
if [ -n "$paired_devices" ]; then
    while IFS= read -r line; do
        mac=$(echo "$line" | awk '{print $2}')
        name=$(echo "$line" | cut -d' ' -f3-)
        
        [ -z "$mac" ] && continue
        
        show_device "$mac" "$name"
        ((device_count++))
    done <<< "$paired_devices"
fi

if [ $device_count -eq 0 ]; then
    cat <<'EOF'
  (box
    :class "bluetooth-empty-state"
    :orientation "v"
    :spacing 12
    :space-evenly false
    (label
      :class "bluetooth-empty-icon"
      :text "󰂱")
    (label
      :class "bluetooth-empty-title"
      :text "Nenhum dispositivo pareado")
    (label
      :class "bluetooth-empty-subtitle"
      :text "Use o Blueman para parear novos dispositivos")
    (eventbox
      :cursor "pointer"
      (button
        :class "bluetooth-empty-action-btn"
        :onclick "blueman-manager &"
        :halign "center"
        (box
          :orientation "h"
          :spacing 8
          :space-evenly false
          (label :class "bluetooth-empty-action-icon" :text "󰒓" :halign "center")
          (label :text "Abrir Blueman" :halign "center")))))
EOF
fi

echo ")"
