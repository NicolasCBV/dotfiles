#!/bin/bash

cd ~/.config/eww

rm ./eww.scss
cat main.scss \
	./widgets/wifi/wifi.scss \
	./widgets/bluetooth/bluetooth.scss \
	./widgets/battery/battery.scss \
	./widgets/volume/volume.scss \
	./widgets/spotify/spotify.scss \
	./widgets/calendar/calendar.scss \
	./widgets/notifications/notification-toast.scss \
	./widgets/notifications/notifications.scss \
	./widgets/workspaces/workspaces.scss > eww.scss
echo "Done!"
