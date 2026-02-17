#!/bin/bash

if command -v powerprofilesctl &> /dev/null; then
    powerprofilesctl get 2>/dev/null
    exit 0
fi

if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" ]; then
    GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
    
    case "$GOVERNOR" in
        powersave)
            echo "power-saver"
            ;;
        schedutil|ondemand)
            echo "balanced"
            ;;
        performance)
            echo "performance"
            ;;
        *)
            echo "balanced"
            ;;
    esac
    exit 0
fi

echo "balanced"
