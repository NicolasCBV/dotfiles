#!/bin/bash

position=$(playerctl --player=spotify position 2>/dev/null)

if [ -z "$position" ] || [ "$position" = "0" ]; then
    echo "0:00"
    exit 0
fi

minutes=$(echo "$position / 60" | bc)
seconds=$(echo "$position % 60" | bc)

printf "%d:%02d" "$minutes" "$seconds"
