#!/usr/bin/env bash
# Shared helpers for the cursor-anchored rofi pickers (sound, vpn).
# Source this file and set $theme to the .rasi to use before calling run_rofi.

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
# Single-click accept and base styling come from $theme.
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
