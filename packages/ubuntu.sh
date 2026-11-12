#!/usr/bin/env bash

set -Eeuo pipefail

# ==========================================
# DOTFILES - UBUNTU PACKAGES
# Ubuntu 24.04+
# ==========================================

log() {
    printf '\n\033[1;34m[INFO]\033[0m %s\n' "$1"
}

error() {
    printf '\n\033[1;31m[ERROR]\033[0m %s\n' "$1" >&2
}

# ------------------------------------------
# OS CHECK
# ------------------------------------------

if [[ ! -f /etc/os-release ]]; then
    error "Cannot detect operating system."
    exit 1
fi

source /etc/os-release

if [[ "$ID" != "ubuntu" ]]; then
    error "This script is intended for Ubuntu."
    exit 1
fi

log "Detected: $PRETTY_NAME"

# ------------------------------------------
# PACKAGE LIST
# ------------------------------------------

PACKAGES=(
    # Core
    git
    curl
    wget
    unzip
    zip
    ca-certificates
    build-essential
    software-properties-common

    # Terminal
    kitty
    tmux
    zsh
    stow

    # Zsh plugins
    zsh-autosuggestions
    zsh-syntax-highlighting

    # CLI utilities
    fzf
    zoxide
    ripgrep
    fd-find
    bat
    btop
    eza
    tree
    jq

    # Clipboard
    xclip
    wl-clipboard

    # Development
    cmake
    ninja-build
    gdb
    clang
    clangd
    lldb
    pkg-config
    python3
    python3-pip
    python3-venv

    # Editor
    neovim

    # Fonts
    fonts-jetbrains-mono
    fontconfig
)

# ------------------------------------------
# APT
# ------------------------------------------

log "Updating package indexes..."
sudo apt-get update

log "Checking package availability..."

MISSING_PACKAGES=()

for package in "${PACKAGES[@]}"; do
    candidate="$(
        apt-cache policy "$package" |
            awk '/Candidate:/ {print $2; exit}'
    )"

    if [[ -z "$candidate" || "$candidate" == "(none)" ]]; then
        MISSING_PACKAGES+=("$package")
    fi
done

if (( ${#MISSING_PACKAGES[@]} > 0 )); then
    error "Packages unavailable: ${MISSING_PACKAGES[*]}"
    error "Check enabled Ubuntu repositories, including universe."
    exit 1
fi

log "All requested packages are available."

log "Installing packages..."
sudo apt-get install -y "${PACKAGES[@]}"

# ------------------------------------------
# UBUNTU CLI COMPATIBILITY
# ------------------------------------------

log "Configuring CLI compatibility..."

USER_BIN="$HOME/.local/bin"
mkdir -p "$USER_BIN"

create_compat_link() {
    local source_cmd="$1"
    local target_cmd="$2"
    local source_path
    local target_path="$USER_BIN/$target_cmd"

    # Nothing to do if the standard command already exists.
    if command -v "$target_cmd" >/dev/null 2>&1; then
        log "$target_cmd already available"
        return 0
    fi

    # Verify the Ubuntu-specific command exists.
    if ! source_path="$(command -v "$source_cmd")"; then
        error "Command not found: $source_cmd"
        return 1
    fi

    # Preserve an existing correct symlink.
    if [[ -L "$target_path" ]] &&
       [[ "$(readlink "$target_path")" == "$source_path" ]]; then
	log "$target_cmd compatibility link already configured"
	return 0
    fi

    # Never overwrite an existing file or unrelated symlink.
    if [[ -e "$target_path" || -L "$target_path" ]]; then
	error "Conflicting path: $target_path"
	return 1
    fi

    ln -s "$source_path" "$target_path"

    log "Created $target_cmd -> $source_cmd"
}

# Ubuntu may provide these binaries under different names.
create_compat_link fdfind fd
create_compat_link batcat bat

# ------------------------------------------
# FINISH
# ------------------------------------------

log "Ubuntu package installation completed."
