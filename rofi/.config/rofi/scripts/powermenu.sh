#!/usr/bin/env bash
# Rofi-based power menu — replaces wlogout.

theme="$HOME/.config/rofi/powermenu.rasi"

lock=" Lock"
suspend="󰒲 Suspend"
logout="󰗽 Log out"
reboot="󰜉 Reboot"
shutdown="⏻ Shutdown"

host="$(hostname)"
up="$(uptime -p 2>/dev/null | sed 's/^up //')"

chosen="$(printf '%s\n%s\n%s\n%s\n%s\n' \
  "$lock" "$suspend" "$logout" "$reboot" "$shutdown" \
  | rofi -dmenu \
      -p "Power" \
      -mesg "  $host  ·  up $up" \
      -theme "$theme")"

case "$chosen" in
  "$lock")     hyprlock & disown ;;
  "$suspend")  systemctl suspend ;;
  "$logout")   hyprctl dispatch exit ;;
  "$reboot")   systemctl reboot ;;
  "$shutdown") systemctl poweroff ;;
esac
