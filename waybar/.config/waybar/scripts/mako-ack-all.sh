#!/usr/bin/env bash
# Bell click handler: dismiss all visible bubbles AND acknowledge anything
# already in history. After this, the bell stops glowing until a new
# notification arrives.

ACKED_FILE="${XDG_RUNTIME_DIR:-/tmp}/mako-acked.txt"
mkdir -p "$(dirname "$ACKED_FILE")"
touch "$ACKED_FILE"

makoctl dismiss --all 2>/dev/null
makoctl history -j 2>/dev/null | jq -r '.[]?.id // empty' >> "$ACKED_FILE"
sort -u -o "$ACKED_FILE" "$ACKED_FILE" 2>/dev/null || true

pkill -RTMIN+8 waybar 2>/dev/null
