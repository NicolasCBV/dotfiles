#!/bin/bash

nmcli -t -f active,security dev wifi | grep -E 'yes|sim' | cut -d':' -f2 | sed 's/--/Aberta/' || echo "N/A"

