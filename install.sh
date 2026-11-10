#!/bin/bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
home_config=false
system_config=false
desktop=false
spicetify=false
dry_run=false

usage() {
    cat <<'EOF'
Usage: ./install.sh [OPTIONS]
  --home        Link home configuration (default when no scope is selected)
  --system      Link all system configuration, including legacy Ly files (sudo)
  --desktop     Install the minimal Arch desktop, link home/desktop system files,
                and enable its services (sudo; excludes legacy Ly/suspend files)
  --spicetify    Set up Spotify's text / Nord theme independently
  --dry-run     Preview selected actions and Stow conflicts without changes
  -h, --help    Show this help

Scopes can be combined. Existing conflicting files are never overwritten.
EOF
}

for arg in "$@"; do
    case "$arg" in
        --home) home_config=true ;;
        --system) system_config=true ;;
        --desktop) desktop=true; home_config=true ;;
        --spicetify) spicetify=true ;;
        --dry-run) dry_run=true ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $arg" >&2; usage >&2; exit 2 ;;
    esac
done
if ! $home_config && ! $system_config && ! $desktop && ! $spicetify; then
    home_config=true
fi

completed=()
summary() {
    local result=$?
    if (( result != 0 )); then
        echo "Setup stopped (exit $result). Resolve the error above before rerunning." >&2
    fi
    if (( ${#completed[@]} )); then
        printf '\nCompleted:\n'
        printf '  - %s\n' "${completed[@]}"
    fi
}
trap summary EXIT

if $desktop && [[ ! -f /etc/arch-release ]]; then
    echo "--desktop supports Arch Linux only." >&2
    exit 1
fi
if ! $dry_run && (( EUID == 0 )); then
    echo "Run this as your normal user; system actions use sudo." >&2
    exit 1
fi

home_stow=(stow --dir="$repo_dir" --target="$HOME" --restow --verbose)
system_stow=(stow --dir="$repo_dir" --target=/ --restow --verbose)
if $desktop && ! $system_config; then
    system_stow+=(--ignore='^etc/(ly(/|$)|systemd/system/user-suspend@\.service$)')
fi

if $dry_run && $desktop; then
    "$repo_dir/scripts/setup-desktop.sh" --dry-run
fi
if $dry_run && $spicetify; then
    echo "Would run scripts/setup-spicetify.sh (text / Nord)."
fi

if $home_config || $system_config || $desktop; then
    if ! command -v stow >/dev/null; then
        echo "Install GNU Stow first (Arch: sudo pacman -Syu --needed stow)." >&2
        exit 1
    fi
    echo "Checking Stow conflicts before making changes..."
    conflicts=false
    if $home_config; then
        "${home_stow[@]}" --simulate config || conflicts=true
    fi
    if $system_config || $desktop; then
        "${system_stow[@]}" --simulate system || conflicts=true
    fi
    if $conflicts; then
        echo "Back up and move the conflicting files listed above, then rerun. Nothing has been changed." >&2
        exit 1
    fi
fi

if $dry_run; then
    echo "Dry run complete. No files, packages, or services changed."
    exit 0
fi

if $system_config || $desktop; then
    command -v sudo >/dev/null || { echo "Missing dependency: sudo" >&2; exit 1; }
    sudo -v
fi
if $desktop; then
    "$repo_dir/scripts/setup-desktop.sh" --packages
    completed+=("Arch desktop packages installed")
    # Keep newly downloaded assets and service enablement links out of the checkout.
    mkdir -p "$HOME/.config/systemd/user" "$HOME/.config/zsh" "$HOME/.local/share/icons"
fi
if $home_config; then
    "${home_stow[@]}" config
    completed+=("Home configuration linked")
fi
if $system_config || $desktop; then
    sudo "${system_stow[@]}" system
    completed+=("System configuration linked")
fi
if $desktop; then
    "$repo_dir/scripts/setup-desktop.sh" --configure
    completed+=("Desktop cursor, shell dependencies, and services configured")
    echo "Reboot, then select Hyprland in your existing login manager or run start-hyprland from a TTY."
fi
if $spicetify; then
    "$repo_dir/scripts/setup-spicetify.sh"
    completed+=("Spicetify text / Nord applied; reopen Spotify")
fi

