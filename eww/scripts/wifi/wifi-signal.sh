#!/bin/bash

nmcli -t -f active,signal dev wifi | grep -E 'yes|sim' | cut -d':' -f2 || echo "0"
