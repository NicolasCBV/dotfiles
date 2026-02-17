#!/bin/bash

position=$(playerctl --player=spotify position 2>/dev/null)

length=$(playerctl --player=spotify metadata mpris:length 2>/dev/null)

if [ -z "$position" ] || [ -z "$length" ] || [ "$length" = "0" ]; then
    echo "0"
    exit 0
fi

length_seconds=$(echo "scale=2; $length / 1000000" | bc)

percent=$(echo "scale=2; ($position / $length_seconds) * 100" | bc)

percent_int=$(printf "%.0f" "$percent")

echo "$percent_int"
