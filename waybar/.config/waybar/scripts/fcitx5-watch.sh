#!/usr/bin/env bash

prev_status=""

while true; do
  curr_status="$(fcitx5-remote)"

  if [ "$curr_status" != "$prev_status" ]; then
    if [ "$curr_status" = "2" ]; then
      echo '{"text":"あ","class":"active"}'
    else
      echo '{"text":"あ","class":"inactive"}'
    fi

    prev_status="$curr_status"
  fi
done
