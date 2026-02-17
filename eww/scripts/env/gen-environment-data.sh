#!/bin/bash

printf '%b' "Collecting Open Weather data through user IP...\n"

max_attempts=5
attempt=1

while true; do
  cache_dir="/tmp/environment-data.json"
  if [ -f $cache_dir ]; then
    rm $cache_dir
  fi

  payload=$(curl -w ":%{http_code}" -s ipinfo.io)
  status="${payload##*:}"
  body="${payload%:*}"
  if [ $((status)) -gt 399 ] || [ $((status)) -eq 0 ]; then
    if [ $attempt -eq $max_attempts ]; then
      msg="Could not read geolocation using user IP! Status code: ${status}"
      printf '%b' "${msg}\n"
      echo "${msg}" | systemd-cat -t weather -p "err"
      exit 1
    else
      sleep 8
      attempt=$((attempt+1))
      continue
    fi
  fi

  geolocation=(
    $(curl -s https://geoip.kde.org/v1/ubiquity | \
        xmllint --xpath 'concat(/Response/Latitude, ",", /Response/Longitude)' - | \
        tr ',' ' ')
  )

  lat="${geolocation[0]}"
  lon="${geolocation[1]}"

  cred=$(cat /etc/minimalist_conquer/cred.json | jq -r '.api_key')
  status=$(curl -w "%{http_code}" -s "https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${cred}" -o $cache_dir)

  if [ $((status)) -gt 399 ] || [ $((status)) -eq 0 ]; then
    if [ $attempt -eq $max_attempts ]; then
      msg="Could not read Open Weather API! Status code: ${status}"
      printf '%b' "${msg}\n"
      echo "${msg}" | systemd-cat -t weather -p "err"
      exit 1
    else
      sleep 8
      attempt=$((attempt+1))
      continue
    fi
  fi

  touch $cache_dir
  echo "${res}" >> $cache_dir

  echo "Successfully loaded weather data!" | systemd-cat -t weather -p "info"
  break
done

printf '%b' "Successfully cached Open Weather data! Exiting.\n"
