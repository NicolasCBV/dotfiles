#!/bin/bash

CACHE_DIR="$HOME/.cache/eww/spotify_covers"
mkdir -p "$CACHE_DIR"

ART_URL=$(playerctl --player=spotify metadata mpris:artUrl 2>/dev/null)

if [ -z "$ART_URL" ]; then
    echo ""
    exit 0
fi

HASH=$(echo -n "$ART_URL" | md5sum | cut -d' ' -f1)
COVER_PATH="$CACHE_DIR/${HASH}.jpg"

if [ -f "$COVER_PATH" ]; then
    echo "$COVER_PATH"
    exit 0
fi

if curl -s -o "$COVER_PATH" "$ART_URL" 2>/dev/null; then
    echo "$COVER_PATH"
else
    echo ""
fi
