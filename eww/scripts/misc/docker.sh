#!/bin/bash

if pgrep -x dockerd > /dev/null; then
	if [ ! -z "$(docker ps -q)" ]; then
		echo "  online"
		exit 0
	else
		echo "  offline"
		exit 0
	fi
fi
