#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STOW_PACKAGES=(zsh git nvim hypr waybar mako fuzzel ohmyposh btop fastfetch)

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31m==>\033[0m %s\n' "$*" >&2; exit 1; }

require_arch() {
	[[ -f /etc/arch-release ]] || err "This script only runs on Arch Linux."
}

require_not_root() {
	[[ $EUID -ne 0 ]] || err "Run as a regular user with sudo privileges, not as root."
}

ensure_pacman_pkg() {
	pacman -Qi "$1" &>/dev/null || sudo pacman -S --needed --noconfirm "$1"
}

ensure_yay() {
	if command -v yay &>/dev/null; then
		log "yay already installed"
		return
	fi
	log "Installing yay from AUR"
	ensure_pacman_pkg base-devel
	ensure_pacman_pkg git
	local tmp
	tmp="$(mktemp -d)"
	git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
	(cd "$tmp/yay-bin" && makepkg -si --noconfirm)
	rm -rf "$tmp"
}

install_pacman() {
	local list="$DOTFILES/bootstrap/packages-pacman.txt"
	[[ -f $list ]] || err "Missing $list"
	log "Installing pacman packages"
	# shellcheck disable=SC2046
	sudo pacman -S --needed --noconfirm $(grep -vE '^\s*(#|$)' "$list")
}

install_aur() {
	local list="$DOTFILES/bootstrap/packages-aur.txt"
	[[ -f $list ]] || err "Missing $list"
	log "Installing AUR packages"
	# shellcheck disable=SC2046
	yay -S --needed --noconfirm $(grep -vE '^\s*(#|$)' "$list")
}

stow_all() {
	ensure_pacman_pkg stow
	log "Stowing packages into \$HOME"
	cd "$DOTFILES"
	for pkg in "${STOW_PACKAGES[@]}"; do
		if [[ -d $pkg ]]; then
			stow --target="$HOME" --restow "$pkg"
			printf '    linked: %s\n' "$pkg"
		else
			warn "Skipping missing stow package: $pkg"
		fi
	done
}

ensure_login_shell_zsh() {
	local zsh_path=/usr/bin/zsh
	if [[ ! -x $zsh_path ]]; then
		warn "zsh not found at $zsh_path; skipping login-shell change"
		return
	fi
	local current
	current="$(getent passwd "$USER" | cut -d: -f7)"
	if [[ $current == "$zsh_path" ]]; then
		log "Login shell already zsh"
		return
	fi
	log "Setting login shell to zsh (you may be prompted for your password)"
	chsh -s "$zsh_path"
}

print_post_install() {
	cat <<-EOF

	$(log "Bootstrap complete.")

	Next steps:
	  1. Set your git identity (not tracked):
	       cp ~/dotfiles/git/.gitconfig.local.example ~/.gitconfig.local
	       \$EDITOR ~/.gitconfig.local

	  2. Enable services:
	       sudo systemctl enable --now gdm docker
	       systemctl --user enable --now pipewire wireplumber

	  3. Log out and back in to start a Hyprland session via GDM.
	EOF
}

main() {
	require_arch
	require_not_root
	ensure_pacman_pkg git
	ensure_pacman_pkg base-devel
	ensure_yay
	install_pacman
	install_aur
	stow_all
	ensure_login_shell_zsh
	print_post_install
}

main "$@"
