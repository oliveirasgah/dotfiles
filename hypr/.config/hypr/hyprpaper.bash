#!/usr/bin/bash

pgrep -x hyprpaper >/dev/null || (hyprpaper &)

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

WALLPAPER=$(find "$WALLPAPER_DIR" -type f | shuf -n 1)

# hyprpaper's IPC socket isn't up immediately after launch (slow on a cold
# login), so retry until it accepts the request (up to ~15s).
for _ in $(seq 60); do
    hyprctl hyprpaper wallpaper ",$WALLPAPER,cover" >/dev/null 2>&1 && exit 0
    sleep 0.25
done

exit 1
