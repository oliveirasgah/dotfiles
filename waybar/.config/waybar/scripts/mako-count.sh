#!/usr/bin/env bash
# Waybar custom module: count of pending notifications.
# Pending = visible bubbles + history items the user hasn't acknowledged
# (acknowledgement = anything except auto-timeout, tracked by mako-tracker.sh).
# Output: JSON {text, tooltip, alt, class}.

ACKED_FILE="${XDG_RUNTIME_DIR:-/tmp}/mako-acked.txt"

list_json="$(makoctl list -j 2>/dev/null)"
hist_json="$(makoctl history -j 2>/dev/null)"
[ -z "$list_json" ] && list_json="[]"
[ -z "$hist_json" ] && hist_json="[]"

flat() { printf '%s' "$1" | jq -c '[.. | objects | select(has("id"))]'; }
vis="$(flat "$list_json")"
his="$(flat "$hist_json")"

acked_csv=""
if [ -s "$ACKED_FILE" ]; then
  acked_csv="$(sort -u "$ACKED_FILE" | tr '\n' ',' | sed 's/,$//')"
fi

count="$(jq -n \
  --argjson v "$vis" \
  --argjson h "$his" \
  --arg acked "$acked_csv" '
    ($acked | split(",") | map(select(. != "") | tonumber)) as $a
    | ($v | length) + ([$h[] | select(.id as $id | $a | index($id) | not)] | length)
  ')"

if [ "$count" -eq 0 ]; then
  jq -nc --arg t "" --arg tt "No notifications" --arg c "empty" \
    '{text:$t, alt:$c, tooltip:$tt, class:$c}'
else
  tooltip="$(jq -nr \
    --argjson v "$vis" \
    --argjson h "$his" \
    --arg acked "$acked_csv" '
      ($acked | split(",") | map(select(. != "") | tonumber)) as $a
      | ($v + [$h[] | select(.id as $id | $a | index($id) | not)])
      | .[:10]
      | map("• \(.app_name): \(.summary)")
      | join("\n")
    ')"
  if [ "$count" -gt 10 ]; then
    tooltip="$tooltip"$'\n'"… and $((count - 10)) more"
  fi
  jq -nc --arg t "$count" --arg tt "$tooltip" --arg c "has-notifications" \
    '{text:$t, alt:$c, tooltip:$tt, class:$c}'
fi
