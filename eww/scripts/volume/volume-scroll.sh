#!/bin/bash

direction=$1

if [ "$direction" = "up" ]; then
    wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
elif [ "$direction" = "down" ]; then
    wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
fi
