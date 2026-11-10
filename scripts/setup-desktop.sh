#!/bin/bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
mapfile -t packages < <(sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$repo_dir/desktop/packages.txt")

case "${1:-}" in
    --dry-run)
        echo "Would install/upgrade the system and these Arch packages:"
        printf '  %s\n' "${packages[@]}"
        echo "Would install Bibata Modern Classic 2.0.6 and missing Znap / Oh My Posh."
        echo "Would enable Bluetooth, keyd, PipeWire, WirePlumber, and the battery timer for next login/boot."
        echo "Would enable NetworkManager unless another network manager is already enabled."
        exit 0
        ;;
    --packages|--configure) ;;
    *) echo "Use install.sh --desktop [--dry-run]." >&2; exit 2 ;;
esac

[[ -f /etc/arch-release ]] || { echo "Desktop setup supports Arch Linux only." >&2; exit 1; }
(( EUID != 0 )) || { echo "Run desktop setup as your normal user." >&2; exit 1; }

if [[ $1 == --packages ]]; then
    # Upgrade along with installation: Arch does not support partial upgrades.
    sudo pacman -Syu --needed -- "${packages[@]}"
    exit 0
fi

asset_tmp=$(mktemp -d)
trap 'rm -rf "$asset_tmp"' EXIT

cursor_dir="$HOME/.local/share/icons/Bibata-Modern-Classic"
if [[ ! -f "$cursor_dir/index.theme" ]]; then
    curl --fail --silent --show-error --location \
        https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.6/Bibata-Modern-Classic.tar.xz \
        --output "$asset_tmp/bibata.tar.xz"
    echo "4cfe5256374d7a465e05d6590dbc10745dc9d362bf955eaa2ac79b4070b0f3aa  $asset_tmp/bibata.tar.xz" | sha256sum --check
    tar -xJf "$asset_tmp/bibata.tar.xz" -C "$asset_tmp"
    mkdir -p "$HOME/.local/share/icons"
    mv "$asset_tmp/Bibata-Modern-Classic" "$cursor_dir"
fi

if [[ ! -r "$HOME/.config/zsh/znap/znap.zsh" ]]; then
    git clone --depth 1 https://github.com/marlonrichert/zsh-snap.git "$HOME/.config/zsh/znap"
fi

if ! command -v oh-my-posh >/dev/null && [[ ! -x "$HOME/.local/bin/oh-my-posh" ]]; then
    [[ $(uname -m) == x86_64 ]] || { echo "The pinned Oh My Posh binary requires x86_64." >&2; exit 1; }
    curl --fail --silent --show-error --location \
        https://github.com/JanDeDobbeleer/oh-my-posh/releases/download/v32.0.0/posh-linux-amd64 \
        --output "$asset_tmp/oh-my-posh"
    echo "55f9b15e49827bf2d79bdafde28e93808b6f84be7677db8e3b2196772b081a26  $asset_tmp/oh-my-posh" | sha256sum --check
    install -Dm755 "$asset_tmp/oh-my-posh" "$HOME/.local/bin/oh-my-posh"
fi

sudo systemctl enable bluetooth.service keyd.service
if systemctl is-enabled --quiet systemd-networkd.service connman.service 2>/dev/null; then
    echo "Manual step: switch off the existing network manager before enabling NetworkManager.service."
else
    sudo systemctl enable NetworkManager.service
fi
sudo systemctl daemon-reload
# Enable without contacting a session bus; services start on next login/boot.
SYSTEMD_OFFLINE=1 systemctl --user --no-reload enable pipewire.socket pipewire-pulse.socket wireplumber.service battery_notify.timer
