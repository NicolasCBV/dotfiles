#!/bin/bash

PROFILE="$1"

if [ -z "$PROFILE" ]; then
    echo "Uso: $0 [power-saver|balanced|performance]"
    exit 1
fi

if command -v powerprofilesctl &> /dev/null; then
    powerprofilesctl set "$PROFILE" 2>/dev/null
    exit 0
fi

if command -v cpupower &> /dev/null; then
    case "$PROFILE" in
        power-saver)
            pkexec cpupower frequency-set -g powersave
            ;;
        balanced)
            pkexec cpupower frequency-set -g schedutil
            ;;
        performance)
            pkexec cpupower frequency-set -g performance
            ;;
    esac
    exit 0
fi

GOVERNOR=""
case "$PROFILE" in
    power-saver)
        GOVERNOR="powersave"
        ;;
    balanced)
        GOVERNOR="schedutil"
        ;;
    performance)
        GOVERNOR="performance"
        ;;
    *)
        echo "Perfil inválido: $PROFILE"
        exit 1
        ;;
esac

if [ -d "/sys/devices/system/cpu/cpu0/cpufreq" ]; then
    AVAILABLE=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null)
    
    if [[ "$AVAILABLE" == *"$GOVERNOR"* ]]; then
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            echo "$GOVERNOR" | pkexec tee "$cpu" > /dev/null 2>&1
        done
    else
        echo "Governor '$GOVERNOR' não disponível. Disponíveis: $AVAILABLE"
        exit 1
    fi
fi
