#!/usr/bin/env bash
# Tracks which notifications the user has acknowledged via click/dismiss
# (anything except auto-timeout). Writes acked IDs to a state file the
# waybar mako-count script reads to filter the displayed count.
#
# Close reasons (per freedesktop spec):
#   1 = expired (auto-timeout)        → keep counting (still pending)
#   2 = dismissed by user             → ack
#   3 = closed by CloseNotification   → ack (e.g. after invoke-action)
#   4 = undefined                     → ack

ACKED_FILE="${XDG_RUNTIME_DIR:-/tmp}/mako-acked.txt"
mkdir -p "$(dirname "$ACKED_FILE")"
touch "$ACKED_FILE"

prune() {
  local hist
  hist="$(makoctl history -j 2>/dev/null | jq -r '.[]?.id // empty' | sort -u)"
  if [ -z "$hist" ]; then
    : > "$ACKED_FILE"
  elif [ -s "$ACKED_FILE" ]; then
    grep -F -x -f <(printf '%s\n' "$hist") "$ACKED_FILE" > "$ACKED_FILE.new" 2>/dev/null || : > "$ACKED_FILE.new"
    mv "$ACKED_FILE.new" "$ACKED_FILE"
  fi
}

/usr/bin/dbus-monitor --session \
  "interface='org.freedesktop.Notifications',member='NotificationClosed'" 2>/dev/null |
while IFS= read -r line; do
  case "$line" in
    *member=NotificationClosed*)
      IFS= read -r id_line || continue
      IFS= read -r reason_line || continue
      id="$(printf '%s' "$id_line" | awk '{print $NF}')"
      reason="$(printf '%s' "$reason_line" | awk '{print $NF}')"
      if [ -n "$id" ] && [ -n "$reason" ] && [ "$reason" != "1" ]; then
        echo "$id" >> "$ACKED_FILE"
        prune
        pkill -RTMIN+8 waybar 2>/dev/null
      fi
      ;;
  esac
done
