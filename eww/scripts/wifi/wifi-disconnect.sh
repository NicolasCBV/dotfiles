#!/bin/bash
nmcli device disconnect "$(nmcli -t -f device,type dev | grep ':wifi$' | cut -d':' -f1)"
