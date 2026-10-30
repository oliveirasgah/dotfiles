#!/usr/bin/env bash
# RCC (FortiGate) IPsec VPN through NetworkManager-libreswan.
#
#   ./bootstrap/vpn-rcc.sh
#
# Settings mirror the FortiClient export (rcc.conf): IKEv1 aggressive mode,
# PSK + XAuth, phase 1 AES256/SHA256/DH14, phase 2 AES128/SHA256/DH14,
# mode-config, full tunnel.
#
# Prompts for the pre-shared key and the XAuth username. The PSK is fed to
# nmcli over stdin so it never shows up in argv or the sudo journal. The
# XAuth password is not stored: it is asked on every connect.
#
# Installs/configures:
#   - networkmanager-libreswan (AUR, via yay)
#   - ikev1-policy=accept in /etc/ipsec.conf (libreswan 5 drops IKEv1)
#   - ipsec.service enabled (the NM plugin expects pluto to be running)
#   - system NM connection "RCC", autoconnect off
#
# leftid must not look like an IP: the plugin keys the PSK as "@<leftid>",
# which only matches an FQDN-style ID. The gateway accepts any peer ID.
# Idempotent; re-running replaces the RCC connection.
set -euo pipefail

CON_NAME=RCC
SERVER=191.240.146.198
LEFT_ID=rcc-linux

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31m==>\033[0m %s\n' "$*" >&2; exit 1; }

require_not_root() {
	[[ $EUID -ne 0 ]] || err "Run as a regular user with sudo privileges, not as root."
}

install_plugin() {
	if pacman -Qi networkmanager-libreswan &>/dev/null; then
		log "networkmanager-libreswan already installed"
		return
	fi
	command -v yay &>/dev/null || err "yay not found; run bootstrap/install.sh first."
	log "Installing networkmanager-libreswan (AUR)"
	yay -S --needed --noconfirm networkmanager-libreswan
}

configure_libreswan() {
	if sudo grep -qE '^\s*ikev1-policy\s*=\s*accept' /etc/ipsec.conf; then
		log "IKEv1 already allowed in /etc/ipsec.conf"
	else
		log "Allowing IKEv1 in /etc/ipsec.conf"
		sudo grep -q '^config setup$' /etc/ipsec.conf \
			|| err "No 'config setup' section in /etc/ipsec.conf"
		sudo sed -i 's/^config setup$/config setup\n\tikev1-policy=accept/' /etc/ipsec.conf
	fi

	log "Initializing the libreswan NSS database"
	sudo ipsec checknss

	log "Enabling ipsec.service"
	sudo systemctl enable --now ipsec
}

read_credentials() {
	read -rp "XAuth username: " XAUTH_USER
	[[ -n $XAUTH_USER ]] || err "Username is required."
	[[ $XAUTH_USER != *,* ]] || err "Username must not contain commas."

	read -rsp "Pre-shared key: " PSK; echo
	[[ -n $PSK ]] || err "Pre-shared key is required."
	[[ $PSK != *$'\n'* && $PSK != *,* ]] \
		|| err "Pre-shared key contains a comma; nmcli can't take it, set it in nm-connection-editor."
}

create_connection() {
	if nmcli -g NAME connection show | grep -qx "$CON_NAME"; then
		log "Replacing existing $CON_NAME connection"
		sudo nmcli connection delete id "$CON_NAME" >/dev/null
	fi

	log "Creating $CON_NAME connection"
	sudo nmcli connection add type vpn vpn-type libreswan con-name "$CON_NAME" \
		connection.autoconnect no \
		vpn.data "right = $SERVER, ikev2 = no, leftid = $LEFT_ID, leftxauthusername = $XAUTH_USER, ike = aes256-sha2_256;modp2048, esp = aes128-sha2_256;modp2048, ikelifetime = 24h, salifetime = 12h, dpddelay = 5s, dpdtimeout = 15s, pskinputmodes = save, pskvalue-flags = 0, xauthpasswordinputmodes = ask, xauthpassword-flags = 2" \
		>/dev/null

	log "Storing the pre-shared key"
	printf 'set vpn.secrets pskvalue = %s\nsave persistent\nquit\n' "$PSK" \
		| sudo nmcli connection edit id "$CON_NAME" >/dev/null
	unset PSK

	sudo nmcli -s -g vpn.secrets connection show id "$CON_NAME" | grep -q '^pskvalue = ' \
		|| err "Pre-shared key was not saved."
}

main() {
	require_not_root
	sudo -v
	install_plugin
	configure_libreswan
	read_credentials
	create_connection
	log "Done. Connect from the Waybar VPN picker (SUPER+CTRL+V) or: nmcli --ask connection up id $CON_NAME"
}

main "$@"
