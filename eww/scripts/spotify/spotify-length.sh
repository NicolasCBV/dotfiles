#!/bin/bash

length=$(playerctl --player=spotify metadata mpris:length 2>/dev/null)

if [ -z "$length" ] || [ "$length" = "0" ]; then
    echo "0:00"
    exit 0
fi

length_seconds=$((length / 1000000))

minutes=$((length_seconds / 60))
seconds=$((length_seconds % 60))

printf "%d:%02d" "$minutes" "$seconds"
