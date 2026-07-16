#!/usr/bin/env bash
# Rofi picker: bind the Wacom tablet to DP-1, HDMI-A-1, or both screens.
# Applies live via `hyprctl eval` (hyprctl keyword is disabled under the Lua
# parser). left_handed is re-asserted each time so the 180° rotation set in
# hyprland.lua survives the output change.

theme="$HOME/.config/rofi/sound-picker.rasi"
device="wacom-one-by-wacom-s-pen"

dp1="󰍹 DP-1 — ultrawide"
hdmi="󰍹 HDMI-A-1 — vertical"
both="󰍺 Both screens"

chosen="$(printf '%s\n%s\n%s\n' "$dp1" "$hdmi" "$both" \
  | rofi -dmenu \
      -p "Tablet" \
      -mesg "  Map pen input to…" \
      -theme "$theme" \
      -theme-str 'textbox-prompt-colon { str: "󰓶"; }')"

case "$chosen" in
  "$dp1")  output="DP-1"      ; label="DP-1 (ultrawide)" ;;
  "$hdmi") output="HDMI-A-1"  ; label="HDMI-A-1 (vertical)" ;;
  "$both") output=""          ; label="both screens" ;;
  *)       exit 0 ;;  # cancelled
esac

hyprctl eval "hl.device({ name = \"$device\", left_handed = true, output = \"$output\" })" >/dev/null

command -v notify-send >/dev/null && notify-send -a "Tablet" "Wacom tablet" "Mapped to $label"
