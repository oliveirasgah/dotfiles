#!/usr/bin/env bash
# Rofi-based picker for the default audio sink (output) or source (input).
# Usage: sound-picker.sh [output|input]
#   no arg → top-level menu (Output / Input / Mixer)
#   output → directly pick a sink
#   input  → directly pick a source

theme="$HOME/.config/rofi/sound-picker.rasi"

# cursor_anchor / run_rofi
source "$HOME/.config/rofi/scripts/picker-lib.sh"

pick_device() {
  local kind="$1"
  local label_kind get_default set_default list_streams move_stream top_icon top_color extra

  if [ "$kind" = "sink" ]; then
    label_kind="Output"
    top_icon=""
    top_color="@green"
    get_default="pactl get-default-sink"
    set_default="pactl set-default-sink"
    list_streams="pactl list short sink-inputs"
    move_stream="pactl move-sink-input"
  else
    label_kind="Input"
    top_icon=""
    top_color="@lavender"
    get_default="pactl get-default-source"
    set_default="pactl set-default-source"
    list_streams="pactl list short source-outputs"
    move_stream="pactl move-source-output"
  fi

  current="$($get_default)"

  mapfile -t entries < <(
    pactl -f json list "${kind}s" 2>/dev/null \
      | jq -r --arg cur "$current" '
          .[]
          | select((.name | startswith("auto_null")) | not)
          | (if .name == $cur then "● " else "  " end) as $mark
          | ($mark + (.description // .name)) + "\t" + .name
        '
  )

  if [ "${#entries[@]}" -eq 0 ]; then
    notify-send "Sound picker" "No ${kind}s found"
    return
  fi

  extra="textbox-prompt-colon { str: \"${top_icon}\"; text-color: ${top_color}; }"

  labels="$(printf '%s\n' "${entries[@]}" | cut -f1)"
  chosen_label="$(printf '%s\n' "$labels" | run_rofi "$label_kind" "Select default $label_kind device" "$extra")"
  [ -z "$chosen_label" ] && return

  chosen_name="$(printf '%s\n' "${entries[@]}" \
    | awk -F'\t' -v l="$chosen_label" '$1 == l { print $2; exit }')"
  [ -z "$chosen_name" ] && return

  $set_default "$chosen_name" || return

  while read -r id _; do
    [ -n "$id" ] && $move_stream "$id" "$chosen_name" >/dev/null 2>&1
  done < <($list_streams 2>/dev/null)
}

case "${1:-menu}" in
  output) pick_device sink   ; exit ;;
  input)  pick_device source ; exit ;;
esac

top_choice="$(printf ' Output device\n Input device\n Mixer (pavucontrol)\n' \
  | run_rofi "Sound" "Choose what to change" "")"

case "$top_choice" in
  *"Output device") pick_device sink ;;
  *"Input device")  pick_device source ;;
  *"Mixer"*)        pavucontrol & disown ;;
esac
