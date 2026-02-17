#!/bin/bash

username="$USER"
hour=$(date +%H)

if [[ "$LANG" == pt_BR* ]]; then
    if [ "$hour" -lt 6 ]; then
        echo "Boa madrugada, $username!"
    elif [ "$hour" -lt 12 ]; then
        echo "Bom dia, $username!"
    elif [ "$hour" -lt 18 ]; then
        echo "Boa tarde, $username!"
    else
        echo "Boa noite, $username!"
    fi
else
    if [ "$hour" -ge 6 ] && [ "$hour" -lt 12 ]; then
        echo "Good morning, $username!"
    elif [ "$hour" -ge 12 ] && [ "$hour" -lt 18 ]; then
        echo "Good afternoon, $username!"
    else
        echo "Good evening, $username!"
    fi
fi
