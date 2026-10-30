#!/usr/bin/env bash
# Rofi-based picker for NetworkManager VPN connections (WireGuard + plugin
# VPNs such as OpenVPN). Only one VPN is kept active at a time.
# Usage: vpn-picker.sh [menu|down]
#   menu (default) → list connections + import / Proton / editor actions
#   down           → disconnect every active VPN

theme="$HOME/.config/rofi/sound-picker.rasi"

# cursor_anchor / run_rofi
source "$HOME/.config/rofi/scripts/picker-lib.sh"

# UUIDs of active VPN connections, one per line.
active_vpns() {
  nmcli -g TYPE,UUID connection show --active 2>/dev/null \
    | awk -F: '$1 == "vpn" || $1 == "wireguard" { print $2 }'
}

vpn_down_all() {
  local uuid
  while read -r uuid; do
    [ -n "$uuid" ] && nmcli connection down uuid "$uuid" >/dev/null 2>&1
  done < <(active_vpns)
}

vpn_up() {
  local uuid="$1" name="$2" out
  vpn_down_all
  if ! out="$(nmcli connection up uuid "$uuid" 2>&1)"; then
    # No secret agent runs in this session, so connections that need a
    # password at connect time get an interactive nmcli in a terminal.
    if printf '%s' "$out" | grep -qi 'secret'; then
      kitty --class float-general -e sh -c \
        'nmcli --ask connection up uuid "$1" || { echo; read -n 1 -s -r -p "Failed. Press any key…"; }' \
        _ "$uuid"
    else
      notify-send -u critical "VPN" "Failed to connect to $name"$'\n'"$out"
    fi
  fi
}

vpn_import() {
  local file type out uuid
  file="$(zenity --file-selection --title="Import VPN config" \
    --file-filter='VPN configs | *.conf *.ovpn' 2>/dev/null)" || return
  case "$file" in
    *.conf) type="wireguard" ;;
    *.ovpn) type="openvpn" ;;
    *) notify-send "VPN" "Unsupported file: $file"; return ;;
  esac

  if ! out="$(nmcli connection import type "$type" file "$file" 2>&1)"; then
    notify-send -u critical "VPN" "Import failed"$'\n'"$out"
    return
  fi
  # Imported profiles default to autoconnect; keep VPNs on-demand only.
  uuid="$(printf '%s' "$out" | grep -oE '[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}' | head -1)"
  [ -n "$uuid" ] && nmcli connection modify uuid "$uuid" connection.autoconnect no
  notify-send "VPN" "Imported $(basename "$file")"
}

case "${1:-menu}" in
  down) vpn_down_all; exit ;;
esac

active="$(active_vpns)"

# label \t uuid \t name
mapfile -t entries < <(
  nmcli -g TYPE,UUID,NAME connection show 2>/dev/null \
    | while IFS=: read -r type uuid name; do
        name="${name//\\:/:}"
        case "$type" in
          wireguard) kind="WireGuard" ;;
          vpn)       kind="VPN" ;;
          *)         continue ;;
        esac
        if grep -qx "$uuid" <<<"$active"; then
          printf '● 󰦝 %s  (%s)\t%s\t%s\n' "$name" "$kind" "$uuid" "$name"
        else
          printf '  󰒙 %s  (%s)\t%s\t%s\n' "$name" "$kind" "$uuid" "$name"
        fi
      done
)

act_import="󰋺 Import config (.conf / .ovpn)"
act_proton="󰇧 Open Proton VPN app"
act_editor="󰒓 Edit connections"

extra='textbox-prompt-colon { str: "󰖂"; text-color: @green; }'

chosen="$(
  { printf '%s\n' "${entries[@]}" | cut -f1 | sed '/^$/d'
    printf '%s\n' "$act_import" "$act_proton" "$act_editor"
  } | run_rofi "VPN" "Select a connection (active one disconnects)" "$extra"
)"
[ -z "$chosen" ] && exit

case "$chosen" in
  "$act_import") vpn_import; exit ;;
  "$act_proton") protonvpn-app >/dev/null 2>&1 & disown; exit ;;
  "$act_editor")
    if command -v nm-connection-editor >/dev/null; then
      nm-connection-editor >/dev/null 2>&1 & disown
    else
      notify-send "VPN" "nm-connection-editor is not installed"
    fi
    exit ;;
esac

IFS=$'\t' read -r _ uuid name < <(
  printf '%s\n' "${entries[@]}" | awk -F'\t' -v l="$chosen" '$1 == l { print; exit }'
)
[ -z "$uuid" ] && exit

if grep -qx "$uuid" <<<"$active"; then
  nmcli connection down uuid "$uuid" >/dev/null 2>&1
else
  vpn_up "$uuid" "$name"
fi
