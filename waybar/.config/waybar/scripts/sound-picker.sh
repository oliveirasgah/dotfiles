#!/usr/bin/env bash
# Rofi-based picker for the default audio sink (output) or source (input).
# Usage: sound-picker.sh [output|input]
#   no arg → top-level menu (Output / Input / Mixer)
#   output → directly pick a sink
#   input  → directly pick a source

theme="$HOME/.config/rofi/sound-picker.rasi"

# Cursor-anchored rofi positioning fragment for -theme-str.
cursor_anchor() {
  local cx cy mon_x mon_y mon_w mon_h mid lcx lcy anchor xoff yoff
  read -r cx cy < <(hyprctl cursorpos 2>/dev/null | tr ',' ' ')
  [ -z "$cx" ] && return

  # Detect the monitor under the cursor, accounting for rotation (transform
  # 1 and 3 are 90° rotations that swap logical width and height).
  read -r mon_x mon_y mon_w mon_h < <(
    hyprctl monitors -j 2>/dev/null \
      | jq -r --argjson x "$cx" --argjson y "$cy" '
          .[]
          | (if (.transform == 1 or .transform == 3) then .height else .width  end) as $w
          | (if (.transform == 1 or .transform == 3) then .width  else .height end) as $h
          | select($x >= .x and $x < (.x + $w) and $y >= .y and $y < (.y + $h))
          | "\(.x) \(.y) \($w) \($h)"
        '
  )
  [ -z "$mon_w" ] && return

  lcx=$(( cx - mon_x ))
  lcy=$(( cy - mon_y ))
  mid=$(( mon_h / 2 ))

  if [ "$lcy" -lt "$mid" ]; then
    anchor="north west"
    yoff=$lcy
  else
    anchor="south west"
    yoff=$(( mon_h - lcy ))
  fi

  printf 'window { location: north west; anchor: %s; x-offset: %dpx; y-offset: %dpx; }' \
    "$anchor" "$lcx" "$yoff"
}

# Run rofi with cursor anchoring + per-call extras.
# Single-click accept and base styling come from sound-picker.rasi.
# Backgrounds a Python listener on Hyprland's event socket: the moment the
# active window changes to anything other than rofi (incl. empty-desktop
# clicks where the class becomes ""), it kills rofi.
run_rofi() {
  local prompt="$1" mesg="$2" extra="$3"
  local override watcher
  override="$(cursor_anchor)
$extra"

  ( python3 - <<'PY'
import os, socket, sys
try:
    sig = os.environ["HYPRLAND_INSTANCE_SIGNATURE"]
    xrd = os.environ["XDG_RUNTIME_DIR"]
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.connect(os.path.join(xrd, "hypr", sig, ".socket2.sock"))
except Exception:
    sys.exit(1)
buf = b""
while True:
    chunk = s.recv(4096)
    if not chunk:
        break
    buf += chunk
    while b"\n" in buf:
        line, _, buf = buf.partition(b"\n")
        t = line.decode(errors="replace")
        if t.startswith("activewindow>>"):
            cls = t.split(">>", 1)[1].split(",", 1)[0].lower()
            if not cls.startswith("rofi"):
                sys.exit(0)
PY
    pkill -x rofi 2>/dev/null
  ) &
  watcher=$!

  rofi -dmenu -p "$prompt" -mesg "$mesg" -theme "$theme" -theme-str "$override"

  pkill -P "$watcher" 2>/dev/null
  kill "$watcher" 2>/dev/null
  wait "$watcher" 2>/dev/null
}

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
