#!/usr/bin/env bash
# Continuous-output waybar custom module for fcitx5 IME state.
# fcitx5 does not broadcast state-change signals on dbus (only method
# returns to queries), so we poll at 10 Hz. Output is throttled — JSON is
# emitted only when the state actually changes, so waybar's GUI thread
# stays idle between toggles.
#
# fcitx5-remote returns:
#   0  = not running
#   1  = inactive
#   2  = active

prev=""
while :; do
  case "$(fcitx5-remote 2>/dev/null)" in
    2) curr='{"text":"あ","class":"active"}' ;;
    *) curr='{"text":"あ","class":"inactive"}' ;;
  esac
  if [ "$curr" != "$prev" ]; then
    printf '%s\n' "$curr"
    prev="$curr"
  fi
  sleep 0.1
done
