#!/usr/bin/env bash
# Replay the latest UNREAD notification (highest history ID not in the
# acked file). Pops a fresh bubble with the original content, then marks
# the original history entry as acknowledged so the bell count drops by 1.

ACKED_FILE="${XDG_RUNTIME_DIR:-/tmp}/mako-acked.txt"
mkdir -p "$(dirname "$ACKED_FILE")"
touch "$ACKED_FILE"

acked_csv="$(sort -u "$ACKED_FILE" 2>/dev/null | tr '\n' ',' | sed 's/,$//')"

next_json="$(makoctl history -j 2>/dev/null | jq -c \
  --arg acked "$acked_csv" '
    ($acked | split(",") | map(select(. != "") | tonumber)) as $a
    | [.[] | select(.id as $id | $a | index($id) | not)]
    | sort_by(.id) | reverse | first
  ')"

if [ -z "$next_json" ] || [ "$next_json" = "null" ]; then
  exit 0
fi

orig_id="$(printf '%s' "$next_json" | jq -r '.id')"
app="$(printf '%s'     "$next_json" | jq -r '.app_name // empty')"
summary="$(printf '%s' "$next_json" | jq -r '.summary  // "(no summary)"')"
body="$(printf '%s'    "$next_json" | jq -r '.body     // empty')"
urgency="$(printf '%s' "$next_json" | jq -r '.urgency  // "normal"')"
icon="$(printf '%s'    "$next_json" | jq -r '.app_icon // empty')"

echo "$orig_id" >> "$ACKED_FILE"

args=(--urgency="$urgency")
[ -n "$app" ]  && args+=(--app-name="$app")
[ -n "$icon" ] && args+=(--icon="$icon")
notify-send "${args[@]}" "$summary" "$body"

pkill -RTMIN+8 waybar 2>/dev/null
