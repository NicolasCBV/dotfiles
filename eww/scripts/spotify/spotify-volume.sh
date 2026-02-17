#!/bin/bash

volume=$(playerctl --player=spotify volume 2>/dev/null)

if [ -z "$volume" ]; then
    echo "50"
    exit 0
fi

volume_percent=$(echo "scale=0; $volume * 100 / 1" | bc)

echo "$volume_percent"
