#!/bin/bash

volume_decimal=$(awk "BEGIN {printf \"%.2f\", $1 / 100}")
wpctl set-volume @DEFAULT_AUDIO_SOURCE@ "$volume_decimal" --limit 1.5
