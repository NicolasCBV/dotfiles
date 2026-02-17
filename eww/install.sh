#!/bin/bash

printf '%b' "\nSetting fonts...\n"
script_dir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
sudo cp -r $script_dir/fonts/* /usr/share/fonts

cred_dir=/etc/eww/cred
if [ ! -d $cred_dir ]; then
	sudo mkdir $cred_dir
fi

printf '%b' '\nSetting Google Calendar API...\n'
$script_dir/scripts/google/oauth.sh

printf '%b' '\nSetting Open Weather API...\n'
read -sp "Please insert your Open Weather API Key: " key

ow_file=$cred_dir/cred.json
if [ -f $ow_file ]; then
	sudo rm $ow_file
fi

if [ -z $key ]; then
	printf '%b' "\nAPI key should not be empty!"
	exit 1
fi

json="{\"api_key\": \"${key}\"}"
printf '%b' $json | sudo tee -a $ow_file > /dev/null

sudo rsync -avh $script_dir/ $cred_dir

printf '%b' "\nSetting cron job and daemon for Open Weather...\n"
env_path=$HOME/.config/eww/scripts/env/gen-environment-data.sh
calendar_path=$HOME/.config/eww/scripts/google/gcal-sync.sh

sudo cp $env_path /usr/bin/environment.collect
sudo cp $script_dir/daemons/environment-data.conf /etc/systemd/system/environment-daemon.service
sudo cp $script_dir/daemons/environment-data.timer /etc/systemd/system/environment-daemon.timer

sudo cp $calendar_path /usr/bin/gcal.sync
sudo cp $script_dir/daemons/calendar-fetcher.conf /etc/systemd/system/gcal-daemon.service
sudo cp $script_dir/daemons/calendar-fetcher.timer /etc/systemd/system/gcal-daemon.timer

sudo systemctl daemon-reload
sudo systemctl enable --now environment-daemon.service
sudo systemctl enable --now environment-daemon.timer

sudo systemctl enable --now gcal-daemon.service
sudo systemctl enable --now gcal-daemon.timer

if [ $(($?)) -ne 0 ]; then
	printf '%b' "\nCould not run first execution, please check your network connection and your API key!\n"
	exit 1
fi
printf '%b' "\nEverything is ready to be used!\n"
