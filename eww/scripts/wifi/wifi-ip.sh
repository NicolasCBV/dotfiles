#!/bin/bash

ip -4 addr show $(nmcli -t -f device,type dev | grep ':wifi$' | cut -d':' -f1) 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo "N/A"
