#!/usr/bin/env bash
# Continuous-output waybar custom module for NetworkManager VPN state.
# Covers both NM plugin VPNs (type "vpn", e.g. OpenVPN) and native
# WireGuard connections, including the ones Proton VPN creates on the fly.
# Event-driven: re-evaluates on every `nmcli monitor` line, but JSON is
# emitted only when the state actually changes.

status() {
  local type state dev name label ip conn_class="disconnected"
  local -a lines=()

  while IFS=: read -r type state dev name; do
    name="${name//\\:/:}"
    case "$type" in
      wireguard) label="WireGuard" ;;
      vpn)
        label="$(nmcli -g vpn.service-type connection show id "$name" 2>/dev/null)"
        label="${label##*.}"
        [ "$label" = "openvpn" ] && label="OpenVPN"
        ;;
      *) continue ;;
    esac

    case "$state" in
      activated)
        conn_class="connected"
        ip="$(nmcli -g IP4.ADDRESS connection show id "$name" 2>/dev/null | head -1)"
        lines+=("$name — $label${ip:+ · ${ip%%/*}}${dev:+ · $dev}")
        ;;
      activating)
        [ "$conn_class" = "connected" ] || conn_class="connecting"
        lines+=("Connecting to $name…")
        ;;
    esac
  done < <(nmcli -g TYPE,STATE,DEVICE,NAME connection show --active 2>/dev/null)

  local icon tooltip
  case "$conn_class" in
    connected)  icon="󰦝" ;;
    connecting) icon="󱆢" ;;
    *)          icon="󰦜"; lines=("VPN: off") ;;
  esac
  tooltip="$(printf '%s\n' "${lines[@]}")"

  jq -cn --arg t "$icon" --arg c "$conn_class" --arg tt "$tooltip" \
    '{text: $t, class: $c, tooltip: $tt}'
}

prev=""
while :; do
  # The leading echo forces an initial render; restart if NM goes away.
  { echo; nmcli monitor 2>/dev/null; } | while read -r _; do
    curr="$(status)"
    if [ "$curr" != "$prev" ]; then
      printf '%s\n' "$curr"
      prev="$curr"
    fi
  done
  sleep 2
done
