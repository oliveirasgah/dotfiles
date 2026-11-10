#!/usr/bin/env bash
# Import FortiClient VPN profiles into NetworkManager (libreswan).
#
#   bootstrap/vpn-forticlient.sh [-l | -d] [-n NAME] FILE
#
#   FILE     FortiClient configuration export (XML, usually *.conf)
#   -l       list the profiles in FILE and exit
#   -d       dry run: print the NetworkManager keyfiles, change nothing
#   -n NAME  only import the profile called NAME
#
# Each IPsec profile becomes a system NetworkManager-libreswan connection with
# the same name and autoconnect off; re-running replaces it. Carried over:
# gateway, IKE version, main/aggressive mode, phase 1/2 proposals and DH
# groups, PFS, lifetimes, DPD, peer ID, XAuth username, and a single split
# tunnel network.
#
# The pre-shared key can't be carried over: FortiClient stores it encrypted
# ("EncX ..."), so it is asked for. It is the tunnel's IPsec PSK from the VPN
# admin, NOT the password used to import the file into FortiClient. It reaches
# NetworkManager through a root-only keyfile, never the command line. The XAuth
# password is not stored; it is asked on every connect.
#
# Skipped with a reason: certificate or SAML/SSO login, IKEv2 with EAP user
# login (libreswan can't do EAP-MSCHAPv2), custom IKE ports, several split
# tunnel networks. SSL VPN profiles get an openfortivpn command instead.
#
# The rofi VPN picker runs this when "Import config" is given a FortiClient file.
set -euo pipefail

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31m==>\033[0m %s\n' "$*" >&2; exit 1; }

usage() { sed -n '2,9{s/^# \{0,1\}//;p}' "$0"; exit "${1:-0}"; }

# Field order of the records printed by parse().
FIELDS=(kind name server ver mode ike esp pfs ikelife salife dpddelay dpdtimeout
	xauth user psk peerid localid rightsubnet problems notes)

# FortiClient XML -> one record per connection, fields joined by \x1f.
parse() {
	python3 -I - "$1" <<'PY'
import ipaddress, re, sys
import xml.etree.ElementTree as ET

ENC = {"3DES": "3des", "AES128": "aes128", "AES192": "aes192", "AES256": "aes256",
       "AES128GCM": "aes_gcm128", "AES256GCM": "aes_gcm256",
       "CHACHA20POLY1305": "chacha20_poly1305"}
AEAD = {"aes_gcm128", "aes_gcm256", "chacha20_poly1305"}
HASH = {"MD5": "md5", "SHA1": "sha1", "SHA256": "sha2_256",
        "SHA384": "sha2_384", "SHA512": "sha2_512"}
DH = {"2": "modp1024", "5": "modp1536", "14": "modp2048", "15": "modp3072",
      "16": "modp4096", "17": "modp6144", "18": "modp8192",
      "19": "dh19", "20": "dh20", "21": "dh21", "31": "dh31"}
ENCRYPTED = re.compile(r"^Enc\w*\s")

def text(el, path, default=""):
    e = el.find(path) if el is not None else None
    if e is None or e.text is None:
        return default
    return " ".join(e.text.split()) or default

def proposals(el, dhgroups, problems, phase, esp, ikev2):
    dhs = []
    for g in filter(None, (g.strip() for g in re.split(r"[;,\s]", dhgroups))):
        if g in DH:
            dhs.append(DH[g])
        else:
            problems.append(f"{phase}: DH group {g} is not supported")
    out = []
    for p in el.findall("proposals/proposal") if el is not None else []:
        parts = (p.text or "").strip().upper().split("|")
        if len(parts) != 2:
            problems.append(f"{phase}: unreadable proposal {p.text!r}")
            continue
        enc, mac = parts[0], parts[1].removeprefix("PRF")
        if enc not in ENC:
            problems.append(f"{phase}: cipher {enc} is not supported")
            continue
        if mac not in HASH:
            problems.append(f"{phase}: hash {mac} is not supported")
            continue
        if ENC[enc] in AEAD and not esp and not ikev2:
            problems.append(f"{phase}: {enc} needs IKEv2")
            continue
        # AEAD ciphers carry their own integrity in ESP.
        base = ENC[enc] if esp and ENC[enc] in AEAD else f"{ENC[enc]}-{HASH[mac]}"
        for s in ([f"{base};{d}" for d in dhs] or [base]):
            if s not in out:
                out.append(s)
    if not out:
        problems.append(f"{phase}: no usable proposals")
    return ",".join(out)

try:
    root = ET.parse(sys.argv[1]).getroot()
except ET.ParseError:
    sys.exit("Not an XML file. Password-protected FortiClient backups can't be "
             "read; export the configuration again without a password.")
except OSError as e:
    sys.exit(str(e))
if root.tag != "forticlient_configuration":
    sys.exit(f"Not a FortiClient configuration export (root element <{root.tag}>).")

def emit(*fields):
    print("\x1f".join(str(f).replace("\x1f", " ").replace("\n", " ") for f in fields))

for vpn in root.iter("ipsecvpn"):
    for conn in vpn.findall("connections/connection"):
        ike, ips = conn.find("ike_settings"), conn.find("ipsec_settings")
        problems, notes = [], []
        name = text(conn, "name")
        ikev2 = text(ike, "version", "1") == "2"

        server = text(ike, "server")
        if ";" in server:
            notes.append("several gateways listed; using the first")
            server = server.split(";")[0].strip()
        if not server:
            problems.append("no gateway address")

        auth = text(ike, "authentication_method", "Preshared Key")
        if "preshared" not in re.sub(r"[\s_-]", "", auth.lower()):
            problems.append(f'"{auth}" login (only pre-shared key is supported)')
        if text(ike, "sso_enabled", "0") == "1":
            problems.append("SAML/SSO login")
        port = text(ike, "udp_port", "500")
        if port != "500":
            problems.append(f"custom IKE port {port}")

        xauth = text(ike, "xauth/enabled", "0") == "1"
        if ikev2 and xauth:
            problems.append("IKEv2 with EAP user login (libreswan can't do EAP-MSCHAPv2)")
        user = text(ike, "xauth/username")
        if ENCRYPTED.match(user):
            user = ""
        psk_el = ike.find("auth_data/preshared_key") if ike is not None else None
        psk = (psk_el.text or "").strip() if psk_el is not None else ""
        if ENCRYPTED.match(psk):
            psk = ""

        if ips is not None and text(ips, "use_vip", "1") == "1":
            vip = text(ips, "virtualip/type", "modeconfig").lower()
            if vip != "modeconfig":
                problems.append(f'virtual IP by "{vip}" (only mode-config is supported)')

        ike_p = proposals(ike, text(ike, "dhgroup"), problems, "phase 1", False, ikev2)
        pfs = text(ips, "pfs", "1") == "1"
        esp_p = proposals(ips, text(ips, "dhgroup") if pfs else "", problems,
                          "phase 2", True, ikev2)

        ikelife = text(ike, "key_life")
        salife = (text(ips, "key_life_seconds")
                  if text(ips, "key_life_type", "seconds") in ("seconds", "both") else "")
        dpddelay = dpdtimeout = ""
        if text(ike, "dpd", "1") == "1":
            interval = int(text(ike, "dpd_retry_interval", "5") or 5)
            dpddelay = interval
            dpdtimeout = interval * int(text(ike, "dpd_retry_count", "3") or 3)

        nets, full = [], False
        for n in ips.findall("remote_networks/network") if ips is not None else []:
            addr, mask = text(n, "addr"), text(n, "mask")
            if ":" in addr or ":" in mask:
                continue
            try:
                net = ipaddress.IPv4Network(f"{addr}/{mask}", strict=False)
            except ValueError:
                problems.append(f"unreadable remote network {addr}/{mask}")
                continue
            if net.prefixlen == 0:
                full = True
            elif str(net) not in nets:
                nets.append(str(net))
        rightsubnet = ""
        if nets and not full:
            if len(nets) == 1:
                rightsubnet = nets[0]
                notes.append(f"split tunnel: only {rightsubnet} goes through the VPN")
            else:
                problems.append(f"split tunnel with {len(nets)} networks")

        emit("ipsec", name, server, 2 if ikev2 else 1,
             text(ike, "mode", "main").lower(), ike_p, esp_p, int(pfs),
             ikelife, salife, dpddelay, dpdtimeout, int(xauth), user, psk,
             text(ike, "peerid"), text(ike, "localid"), rightsubnet,
             "; ".join(problems), "; ".join(notes))

for vpn in root.iter("sslvpn"):
    for conn in vpn.findall("connections/connection"):
        user = text(conn, "username")
        emit("ssl", text(conn, "name"), text(conn, "server"), "", "", "", "", "",
             "", "", "", "", "", "" if ENCRYPTED.match(user) else user, "", "", "",
             "", "SSL VPN (not handled by NetworkManager here)", "")
PY
}

# Loads record $1 into the variables named in FIELDS.
load_record() { IFS=$'\x1f' read -r "${FIELDS[@]}" <<<"$1"; }

describe() {
	if [[ $kind == ssl ]]; then
		printf '  %s: SSL VPN, gateway %s\n' "$name" "$server"
	else
		printf '  %s: IPsec IKEv%s%s, gateway %s, %s\n' "$name" "$ver" \
			"$([[ $ver == 1 ]] && printf ' %s mode' "$mode")" "$server" \
			"$([[ $xauth == 1 ]] && echo 'PSK + XAuth' || echo 'PSK')"
	fi
	[[ -z $notes ]] || printf '      note: %s\n' "$notes"
	[[ -z $problems ]] || printf '      skipped: %s\n' "$problems"
	if [[ $kind == ssl ]]; then
		printf '      connect with: sudo openfortivpn %s%s  (pacman -S openfortivpn)\n' \
			"$server" "${user:+ -u $user}"
	fi
}

# GKeyFile string escaping.
kf() {
	local s=${1//\\/\\\\}
	s=${s//$'\n'/\\n}
	[[ $s != ' '* ]] || s="\\s${s:1}"
	printf '%s' "$s"
}
kv() { [[ -z $2 ]] || printf '%s=%s\n' "$1" "$(kf "$2")"; }

# NetworkManager keyfile for the loaded record; uses $uuid, $user, $psk.
build_keyfile() {
	printf '[connection]\nid=%s\nuuid=%s\ntype=vpn\nautoconnect=false\n\n' "$(kf "$name")" "$uuid"
	printf '[vpn]\nservice-type=org.freedesktop.NetworkManager.libreswan\n'
	kv right "$server"
	if [[ $ver == 2 ]]; then
		kv ikev2 insist
		kv leftid "$localid"
	else
		kv ikev2 no
		# The plugin switches IKEv1 to aggressive mode whenever leftid is set.
		[[ $mode != aggressive ]] || kv leftid "${localid:-$(uname -n)}"
	fi
	kv rightid "$peerid"
	if [[ $xauth == 1 ]]; then
		kv leftxauthusername "$user"
		kv xauthpasswordinputmodes ask
		kv xauthpassword-flags 2
	fi
	kv ike "$ike"
	kv esp "$esp"
	[[ $pfs == 1 ]] || kv pfs no
	kv ikelifetime "${ikelife:+${ikelife}s}"
	kv salifetime "${salife:+${salife}s}"
	kv dpddelay "${dpddelay:+${dpddelay}s}"
	kv dpdtimeout "${dpdtimeout:+${dpdtimeout}s}"
	kv rightsubnet "$rightsubnet"
	kv pskinputmodes save
	kv pskvalue-flags 0
	printf '\n[vpn-secrets]\n'
	kv pskvalue "$psk"
	printf '\n[ipv4]\nmethod=auto\n\n[ipv6]\nmethod=auto\n'
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
	local need_ikev1=$1
	if [[ $need_ikev1 == 1 ]]; then
		if sudo grep -qE '^\s*ikev1-policy\s*=\s*accept' /etc/ipsec.conf; then
			log "IKEv1 already allowed in /etc/ipsec.conf"
		else
			# libreswan 5 drops IKEv1 unless told otherwise.
			log "Allowing IKEv1 in /etc/ipsec.conf"
			sudo grep -q '^config setup$' /etc/ipsec.conf \
				|| err "No 'config setup' section in /etc/ipsec.conf"
			sudo sed -i 's/^config setup$/config setup\n\tikev1-policy=accept/' /etc/ipsec.conf
		fi
	fi
	log "Initializing the libreswan NSS database"
	sudo ipsec checknss
	# The NM plugin expects pluto to be running already.
	log "Enabling ipsec.service"
	sudo systemctl enable --now ipsec
	if systemctl is-active -q forticlient 2>/dev/null; then
		warn "FortiClient is running. It and libreswan both use UDP 500/4500;"
		warn "don't connect a FortiClient IPsec VPN while this one is up."
	fi
}

read_secrets() {
	if [[ $xauth == 1 ]]; then
		local entered
		read -rp "  XAuth username${user:+ [$user]}: " entered
		user=${entered:-$user}
		[[ -n $user ]] || err "Username is required."
	fi
	if [[ -n $psk ]]; then
		log "Using the pre-shared key stored unencrypted in the file"
		return
	fi
	local again
	read -rsp "  Pre-shared key (IPsec PSK, not the FortiClient import password): " psk; echo
	[[ -n $psk ]] || err "Pre-shared key is required."
	read -rsp "  Pre-shared key again: " again; echo
	[[ $psk == "$again" ]] || err "The keys don't match."
	[[ $psk != *$'\n'* ]] || err "The key can't contain a newline."
}

write_connection() {
	local dir=/etc/NetworkManager/system-connections path
	while nmcli -g NAME connection show | grep -Fx -- "$name" >/dev/null; do
		log "Replacing existing \"$name\" connection"
		sudo nmcli connection delete id "$name" >/dev/null
	done
	path="$dir/${name//[^A-Za-z0-9._-]/_}.nmconnection"
	! sudo test -e "$path" || path="${path%.nmconnection}-${uuid:0:8}.nmconnection"

	log "Creating \"$name\" connection"
	sudo install -m 600 -o root -g root /dev/null "$path"
	build_keyfile | sudo tee "$path" >/dev/null
	if ! sudo nmcli connection load "$path"; then
		sudo rm -f "$path"
		err "NetworkManager rejected the connection for \"$name\"."
	fi
	sudo nmcli -s -g vpn.secrets connection show uuid "$uuid" | grep 'pskvalue' >/dev/null \
		|| err "Pre-shared key for \"$name\" was not saved."
}

main() {
	local mode_list=0 mode_dry=0 only="" opt
	while getopts ':ldn:h' opt; do
		case $opt in
			l) mode_list=1 ;;
			d) mode_dry=1 ;;
			n) only=$OPTARG ;;
			h) usage ;;
			*) usage 1 >&2 ;;
		esac
	done
	shift $((OPTIND - 1))
	[[ $# -eq 1 ]] || usage 1 >&2
	local file=$1 out
	[[ -r $file ]] || err "Can't read $file"
	out=$(parse "$file") || err "Can't import $file"

	local -a records=() importable=()
	[[ -z $out ]] || mapfile -t records <<<"$out"
	local rec need_ikev1=0 found=0
	log "Profiles in $(basename "$file"):"
	for rec in "${records[@]}"; do
		load_record "$rec"
		[[ -z $only || $name == "$only" ]] || continue
		found=1
		describe
		if [[ $kind == ipsec && -z $problems ]]; then
			importable+=("$rec")
			[[ $ver == 2 ]] || need_ikev1=1
		fi
	done
	[[ $found == 1 ]] || err "No ${only:+profile named \"$only\" }found in $file"
	[[ $mode_list == 0 ]] || exit 0
	[[ ${#importable[@]} -gt 0 ]] || err "Nothing to import."

	local uuid
	if [[ $mode_dry == 1 ]]; then
		for rec in "${importable[@]}"; do
			load_record "$rec"
			uuid=00000000-0000-0000-0000-000000000000
			[[ $xauth == 0 || -n $user ]] || user='<asked at import>'
			psk='<asked at import>'
			printf '\n# --- %s ---\n' "$name"
			build_keyfile
		done
		exit 0
	fi

	[[ $EUID -ne 0 ]] || err "Run as a regular user with sudo privileges, not as root."
	sudo -v
	install_plugin
	configure_libreswan "$need_ikev1"

	local -a done_names=()
	for rec in "${importable[@]}"; do
		load_record "$rec"
		echo
		log "$name"
		read_secrets
		uuid=$(</proc/sys/kernel/random/uuid)
		write_connection
		unset psk
		done_names+=("$name")
	done

	echo
	log "Imported: ${done_names[*]}"
	log "Connect from the Waybar VPN picker (SUPER+CTRL+V) or: nmcli --ask connection up id \"${done_names[0]}\""
	log "\"received Hash Payload does not match computed value\" in journalctl -u ipsec means a wrong pre-shared key."
}

main "$@"
