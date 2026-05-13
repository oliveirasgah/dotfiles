#!/usr/bin/env bash
# Waybar custom module: pending repo + AUR updates via checkupdates and yay.
# Output: JSON {text, tooltip, alt, class}.

repo="$(checkupdates 2>/dev/null)"
aur="$(yay -Qua 2>/dev/null)"

[ -n "$repo" ] && repo_n=$(printf '%s\n' "$repo" | wc -l) || repo_n=0
[ -n "$aur" ]  && aur_n=$(printf '%s\n'  "$aur"  | wc -l) || aur_n=0
count=$((repo_n + aur_n))

if [ "$count" -eq 0 ]; then
  jq -nc \
    --arg t "" \
    --arg tt "System up to date" \
    --arg c "updated" \
    '{text:$t, alt:$c, tooltip:$tt, class:$c}'
else
  tooltip=""
  if [ "$repo_n" -gt 0 ]; then
    tooltip+="<b>Repo ($repo_n)</b>"$'\n'"$(printf '%s\n' "$repo" | head -25)"
    [ "$repo_n" -gt 25 ] && tooltip+=$'\n'"… and $((repo_n - 25)) more"
  fi
  if [ "$aur_n" -gt 0 ]; then
    [ -n "$tooltip" ] && tooltip+=$'\n\n'
    tooltip+="<b>AUR ($aur_n)</b>"$'\n'"$(printf '%s\n' "$aur" | head -25)"
    [ "$aur_n" -gt 25 ] && tooltip+=$'\n'"… and $((aur_n - 25)) more"
  fi
  jq -nc \
    --arg t "$count" \
    --arg tt "$tooltip" \
    --arg c "updates-pending" \
    '{text:$t, alt:$c, tooltip:$tt, class:$c}'
fi
