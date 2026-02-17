#!/bin/bash
active_ws=$(hyprctl activeworkspace -j | jq -r '.id')
hypr_ws=$(hyprctl workspaces -j | jq -r '.[] | "\(.id):\(.windows)"')

declare -A ws_windows
while IFS=: read -r ws_id count; do
    ws_windows[$ws_id]=$count
done <<< "$hypr_ws"

echo "["
for i in {1..6}; do
    is_active="false"; is_occupied="false"
    [[ "$i" == "$active_ws" ]] && is_active="true"
    [[ "${ws_windows[$i]:-0}" -gt 0 ]] && is_occupied="true"
    
    printf '{"id":%d,"active":%s,"occupied":%s}' "$i" "$is_active" "$is_occupied"
    [[ $i -lt 6 ]] && echo ","
done
echo "]"
