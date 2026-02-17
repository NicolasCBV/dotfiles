#!/bin/sh

/usr/bin/setsid /usr/bin/xdg-open "$1" >/dev/null 2>&1 < /dev/null &
