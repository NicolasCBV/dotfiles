#!/bin/bash

current_loop=$(playerctl --player=spotify loop 2>/dev/null)

case "$current_loop" in
    "None")
        playerctl --player=spotify loop Playlist
        ;;
    "Playlist")
        playerctl --player=spotify loop Track
        ;;
    "Track")
        playerctl --player=spotify loop None
        ;;
    *)
        playerctl --player=spotify loop Playlist
        ;;
esac
