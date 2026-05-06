# dotfiles

Personal dotfiles and Arch Linux bootstrap.

Manages shell, editor, terminal, and Hyprland desktop configs via [GNU Stow](https://www.gnu.org/software/stow/), and bootstraps a fresh Arch install with `yay` plus a curated package set.

## Quick start (fresh Arch machine)

```sh
git clone https://github.com/oliveirasgah/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap/install.sh
```

The script:

1. Verifies you're on Arch and not running as root.
2. Installs `yay` if missing (clones `yay-bin` from AUR, builds, installs).
3. Installs everything in `bootstrap/packages-pacman.txt` via `pacman`.
4. Installs everything in `bootstrap/packages-aur.txt` via `yay`.
5. Symlinks every Stow package into `$HOME` (`stow -t $HOME bash git nvim …`).
6. Prints a post-install checklist.

The script is idempotent — re-running it is a no-op once everything is in place.

## Post-install

1. **Git identity** — `~/.gitconfig` is included via `~/.gitconfig.local`. Copy the example and fill in name/email:
   ```sh
   cp ~/dotfiles/git/.gitconfig.local.example ~/.gitconfig.local
   $EDITOR ~/.gitconfig.local
   ```
2. **Enable system services**:
   ```sh
   sudo systemctl enable --now gdm docker
   systemctl --user enable --now pipewire wireplumber
   ```
3. **Log out and back in** to land in the Hyprland session via GDM.

## Stow packages

| Package    | Symlinks |
|------------|----------|
| `bash`     | `~/.bashrc`, `~/.bash_profile`, `~/.bash_logout`, `~/.xprofile`, `~/.yarnrc` |
| `git`      | `~/.gitconfig` (identity loaded from `~/.gitconfig.local`) |
| `nvim`     | `~/.config/nvim/` |
| `alacritty`| `~/.config/alacritty/` |
| `hypr`     | `~/.config/hypr/` |
| `waybar`   | `~/.config/waybar/` |
| `mako`     | `~/.config/mako/` |
| `fuzzel`   | `~/.config/fuzzel/` |
| `ohmyposh` | `~/.config/ohmyposh/` |
| `btop`     | `~/.config/btop/` |
| `fastfetch`| `~/.config/fastfetch/` |

Add only what you want: `cd ~/dotfiles && stow bash git nvim`.
Remove a package: `stow -D bash`.

## Snapshot vs install lists

- `bootstrap/packages-pacman.txt`, `packages-aur.txt` — **curated install set**. What the bootstrap installs on a fresh machine.
- `bootstrap/snapshot-pacman.txt`, `snapshot-aur.txt` — **full explicit-package snapshot** of the source machine (`pacman -Qqen` and `pacman -Qqm`). Reference only — diff against a target machine to see drift.

The Arch base set (`base`, `base-devel`, `linux`, `linux-firmware`, `intel-ucode`, `sudo`, `less`, `man-db`, `grub`, `efibootmgr`, `networkmanager`, `systemd-resolvconf`) is assumed already present and is not in the install lists.

## What is NOT tracked

For privacy and safety, these are never committed:

- `~/.ssh/` — SSH keys
- `~/.gnupg/` — GPG keys
- `~/.docker/`, `~/.aws/` — credentials
- `~/.config/discord/`, browser profiles — app state and tokens
- `~/.gitconfig.local` — your name and email (gitignored; create from `git/.gitconfig.local.example`)

## Refreshing the snapshot

After installing or removing packages on the source machine:

```sh
pacman -Qqen > ~/dotfiles/bootstrap/snapshot-pacman.txt
pacman -Qqm  > ~/dotfiles/bootstrap/snapshot-aur.txt
```

Update the curated install lists by hand to match anything you want bootstrapped on new machines.
