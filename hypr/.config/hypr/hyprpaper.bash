#!/usr/bin/bash

pgrep -x hyprpaper || (hyprpaper &)

sleep 0.5

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

WALLPAPER=$(find "$WALLPAPER_DIR" -type f | shuf -n 1)

hyprctl hyprpaper wallpaper ",$WALLPAPER,cover"
