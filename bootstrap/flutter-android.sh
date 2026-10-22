#!/usr/bin/env bash
# Flutter + Android SDK toolchain, installed under $HOME.
#
#   ./bootstrap/flutter-android.sh            # Flutter 3.47.5 (default)
#   ./bootstrap/flutter-android.sh 3.48.0     # another Flutter tag
#
# Installs/configures:
#   - jdk21-openjdk (pacman); system default JDK is left untouched,
#     Flutter/Gradle are pointed at JDK 21 via `flutter config --jdk-dir`
#   - Flutter SDK at ~/development/flutter, pinned to a git tag
#   - Android cmdline-tools at ~/Android/Sdk (sha1-verified download)
#   - platform-tools, platforms;android-36, build-tools;36.0.0
#
# PATH/ANDROID_HOME live in zsh/.config/zshrc/40-flutter-android.
# The NDK is not installed here: Gradle fetches the version Flutter
# requests on the first build. Idempotent; safe to re-run.
set -euo pipefail

FLUTTER_VERSION="${1:-3.47.5}"
FLUTTER_DIR="$HOME/development/flutter"
FLUTTER_REPO=https://github.com/flutter/flutter.git

ANDROID_SDK="$HOME/Android/Sdk"
ANDROID_REPO=https://dl.google.com/android/repository
SDK_PACKAGES=("platform-tools" "platforms;android-36" "build-tools;36.0.0")

JDK_PKG=jdk21-openjdk
JDK_DIR=/usr/lib/jvm/java-21-openjdk

# Anaconda ships its own curl/xz earlier in PATH; use the system ones.
CURL=/usr/bin/curl

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

install_system_deps() {
	log "Ensuring system packages ($JDK_PKG, git, curl, unzip, xz)"
	local pkg
	for pkg in "$JDK_PKG" git curl unzip xz which; do
		ensure_pacman_pkg "$pkg"
	done
	[[ -x $JDK_DIR/bin/java ]] || err "JDK 21 not found at $JDK_DIR"
}

install_flutter() {
	if [[ -d $FLUTTER_DIR && ! -d $FLUTTER_DIR/.git ]]; then
		err "$FLUTTER_DIR exists but is not a git checkout; move it away and re-run."
	fi

	if [[ ! -d $FLUTTER_DIR ]]; then
		log "Cloning Flutter $FLUTTER_VERSION into $FLUTTER_DIR"
		mkdir -p "$(dirname "$FLUTTER_DIR")"
		git clone --branch "$FLUTTER_VERSION" --depth 1 "$FLUTTER_REPO" "$FLUTTER_DIR"
		return
	fi

	local current
	current="$(git -C "$FLUTTER_DIR" describe --tags --exact-match 2>/dev/null || true)"
	if [[ $current == "$FLUTTER_VERSION" ]]; then
		log "Flutter already at $FLUTTER_VERSION"
		return
	fi

	log "Switching Flutter from ${current:-<untagged>} to $FLUTTER_VERSION"
	git -C "$FLUTTER_DIR" fetch --depth 1 origin tag "$FLUTTER_VERSION"
	git -C "$FLUTTER_DIR" checkout --quiet "$FLUTTER_VERSION"
}

install_cmdline_tools() {
	local dest="$ANDROID_SDK/cmdline-tools/latest"
	if [[ -x $dest/bin/sdkmanager ]]; then
		log "Android cmdline-tools already installed"
		return
	fi

	log "Resolving latest Android cmdline-tools"
	local tmp manifest zip sha1
	tmp="$(mktemp -d)"
	trap 'rm -rf "$tmp"; trap - RETURN' RETURN

	manifest="$tmp/repository2-3.xml"
	"$CURL" -fsSL "$ANDROID_REPO/repository2-3.xml" -o "$manifest"

	zip="$(grep -o 'commandlinetools-linux-[0-9]*_latest\.zip' "$manifest" | sort -V | tail -1)"
	[[ -n $zip ]] || err "Could not find cmdline-tools in the Android repository manifest"

	sha1="$(grep -B1 "<url>$zip</url>" "$manifest" | grep -o '[0-9a-f]\{40\}' | sort -u)"
	[[ $sha1 =~ ^[0-9a-f]{40}$ ]] || err "Could not resolve a single sha1 for $zip"

	log "Downloading $zip"
	"$CURL" -fL --progress-bar "$ANDROID_REPO/$zip" -o "$tmp/$zip"
	echo "$sha1  $tmp/$zip" | sha1sum --check --quiet || err "Checksum mismatch for $zip"

	unzip -q "$tmp/$zip" -d "$tmp/extract"
	mkdir -p "$ANDROID_SDK/cmdline-tools"
	rm -rf "$dest"
	mv "$tmp/extract/cmdline-tools" "$dest"
}

install_sdk_packages() {
	local sdkmanager="$ANDROID_SDK/cmdline-tools/latest/bin/sdkmanager"
	export JAVA_HOME="$JDK_DIR"

	log "Reviewing Android SDK licenses (answer 'y' to accept)"
	"$sdkmanager" --sdk_root="$ANDROID_SDK" --licenses

	log "Installing Android SDK packages: ${SDK_PACKAGES[*]}"
	"$sdkmanager" --sdk_root="$ANDROID_SDK" --install "${SDK_PACKAGES[@]}"
}

configure_flutter() {
	local flutter="$FLUTTER_DIR/bin/flutter"
	export ANDROID_HOME="$ANDROID_SDK"
	export JAVA_HOME="$JDK_DIR"

	log "Configuring Flutter (JDK 21, Android SDK, analytics off)"
	"$flutter" --disable-analytics >/dev/null
	"$flutter" config --no-analytics --jdk-dir "$JDK_DIR" --android-sdk "$ANDROID_SDK" >/dev/null
	"$FLUTTER_DIR/bin/dart" --disable-analytics >/dev/null

	log "Precaching Android artifacts"
	"$flutter" precache --android

	log "flutter doctor -v"
	"$flutter" doctor -v || warn "flutter doctor reported issues (see above)"
}

print_post_install() {
	cat <<-EOF

	$(log "Flutter + Android toolchain ready.")

	Next steps:
	  1. Open a new shell (or: source ~/.zshrc) to pick up
	     ~/.config/zshrc/40-flutter-android.

	  2. Check: flutter --version   # expect $FLUTTER_VERSION

	  3. For a physical device: enable USB debugging, plug it in, run 'adb devices'.
	EOF
}

main() {
	require_arch
	require_not_root
	install_system_deps
	install_flutter
	install_cmdline_tools
	install_sdk_packages
	configure_flutter
	print_post_install
}

main "$@"
