#!/usr/bin/env bash
# Single entry point for mako-related waybar integration.
#
#   mako.sh tracker   long-running dbus listener (start once at login).
#                     Signals waybar (RTMIN+8) on any Notify or non-timeout
#                     NotificationClosed, and records user-ack'd IDs.
#   mako.sh count     one-shot JSON for the waybar custom module.
#   mako.sh replay    pop the latest unread history bubble (left-click).
#   mako.sh ack       dismiss visible + ack all history (right-click).
#
# Acknowledgement model: any close reason other than 1 (timeout) is treated
# as the user having seen it. Acked IDs live in $ACKED_FILE.

set -u

ACKED_FILE="${XDG_RUNTIME_DIR:-/tmp}/mako-acked.txt"
WAYBAR_SIGNAL=8

mkdir -p "$(dirname "$ACKED_FILE")"
touch "$ACKED_FILE"

signal_waybar() { pkill -RTMIN+$WAYBAR_SIGNAL waybar 2>/dev/null || true; }

# All notifications currently in mako's history (JSON array, possibly empty).
hist_json() { makoctl history -j 2>/dev/null || echo '[]'; }
list_json() { makoctl list    -j 2>/dev/null || echo '[]'; }

# Drop acked IDs that no longer appear in history (keeps the file small).
prune_acked() {
  [ -s "$ACKED_FILE" ] || return
  local hist
  hist="$(hist_json | jq -r '.. | objects | .id? // empty' | sort -u)"
  if [ -z "$hist" ]; then
    : > "$ACKED_FILE"
  else
    grep -F -x -f <(printf '%s\n' "$hist") "$ACKED_FILE" > "$ACKED_FILE.new" 2>/dev/null || : > "$ACKED_FILE.new"
    mv "$ACKED_FILE.new" "$ACKED_FILE"
  fi
}

# Emit JSON for the count module.
cmd_count() {
  local vis his acked_csv count tooltip
  vis="$(list_json | jq -c '[.. | objects | select(has("id"))]')"
  his="$(hist_json | jq -c '[.. | objects | select(has("id"))]')"
  acked_csv="$(sort -u "$ACKED_FILE" 2>/dev/null | paste -sd, -)"

  count="$(jq -n --argjson v "$vis" --argjson h "$his" --arg acked "$acked_csv" '
    ($acked | split(",") | map(select(. != "") | tonumber)) as $a
    | ($v | length) + ([$h[] | select(.id as $id | $a | index($id) | not)] | length)
  ')"

  if [ "$count" -eq 0 ]; then
    jq -nc '{text:"", alt:"empty", tooltip:"No notifications", class:"empty"}'
    return
  fi

  tooltip="$(jq -nr --argjson v "$vis" --argjson h "$his" --arg acked "$acked_csv" '
    ($acked | split(",") | map(select(. != "") | tonumber)) as $a
    | ($v + [$h[] | select(.id as $id | $a | index($id) | not)])
    | .[:10]
    | map("• \(.app_name): \(.summary)")
    | join("\n")
  ')"
  [ "$count" -gt 10 ] && tooltip="$tooltip"$'\n'"… and $((count - 10)) more"

  jq -nc --arg t "$count" --arg tt "$tooltip" \
    '{text:$t, alt:"has-notifications", tooltip:$tt, class:"has-notifications"}'
}

# Re-pop the latest unread history entry, then mark it acked.
cmd_replay() {
  local acked_csv next_json orig_id app summary body urgency icon
  acked_csv="$(sort -u "$ACKED_FILE" 2>/dev/null | paste -sd, -)"

  next_json="$(hist_json | jq -c --arg acked "$acked_csv" '
    ($acked | split(",") | map(select(. != "") | tonumber)) as $a
    | [.[] | select(.id as $id | $a | index($id) | not)]
    | sort_by(.id) | reverse | first
  ')"

  [ -z "$next_json" ] || [ "$next_json" = "null" ] && exit 0

  orig_id="$(jq -r '.id'                      <<<"$next_json")"
  app="$(jq     -r '.app_name // empty'        <<<"$next_json")"
  summary="$(jq -r '.summary  // "(no summary)"' <<<"$next_json")"
  body="$(jq    -r '.body     // empty'        <<<"$next_json")"
  urgency="$(jq -r '.urgency  // "normal"'     <<<"$next_json")"
  icon="$(jq    -r '.app_icon // empty'        <<<"$next_json")"

  echo "$orig_id" >> "$ACKED_FILE"

  local args=(--urgency="$urgency")
  [ -n "$app"  ] && args+=(--app-name="$app")
  [ -n "$icon" ] && args+=(--icon="$icon")
  notify-send "${args[@]}" "$summary" "$body"
  signal_waybar
}

# Dismiss all visible + ack all history.
cmd_ack() {
  makoctl dismiss --all 2>/dev/null
  hist_json | jq -r '.[]?.id // empty' >> "$ACKED_FILE"
  sort -u -o "$ACKED_FILE" "$ACKED_FILE" 2>/dev/null || true
  signal_waybar
}

# Long-running dbus listener. Refreshes waybar on any notification activity
# and records user-acked IDs (close reason != 1 == timeout).
cmd_tracker() {
  /usr/bin/dbus-monitor --session \
    "interface='org.freedesktop.Notifications',member='Notify'" \
    "interface='org.freedesktop.Notifications',member='NotificationClosed'" 2>/dev/null \
  | while IFS= read -r line; do
      case "$line" in
        *member=Notify*)
          signal_waybar
          ;;
        *member=NotificationClosed*)
          IFS= read -r id_line     || continue
          IFS= read -r reason_line || continue
          id="$(awk '{print $NF}'  <<<"$id_line")"
          reason="$(awk '{print $NF}' <<<"$reason_line")"
          if [ -n "$id" ] && [ -n "$reason" ] && [ "$reason" != "1" ]; then
            echo "$id" >> "$ACKED_FILE"
            prune_acked
          fi
          signal_waybar
          ;;
      esac
    done
}

case "${1:-count}" in
  count)   cmd_count ;;
  replay)  cmd_replay ;;
  ack)     cmd_ack ;;
  tracker) cmd_tracker ;;
  *) echo "usage: $0 {count|replay|ack|tracker}" >&2; exit 2 ;;
esac
