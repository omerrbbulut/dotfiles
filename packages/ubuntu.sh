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

log "Installing packages..."
sudo apt-get install -y "${PACKAGES[@]}"

# ------------------------------------------
# UBUNTU CLI COMPATIBILITY
# ------------------------------------------

log "Configuring CLI compatibility..."

USER_BIN="$HOME/.local/bin"

mkdir -p "$USER_BIN"

# fd-find -> fd
if command -v fdfind >/dev/null 2>&1; then
    if ! command -v fd >/dev/null 2>&1; then
        ln -sfn "$(command -v fdfind)" "$USER_BIN/fd"
        log "Created fd -> fdfind"
    fi
fi

# batcat -> bat
if command -v batcat >/dev/null 2>&1; then
    if ! command -v bat >/dev/null 2>&1; then
        ln -sfn "$(command -v batcat)" "$USER_BIN/bat"
        log "Created bat -> batcat"
    fi
fi

# ------------------------------------------
# FINISH
# ------------------------------------------

log "Ubuntu package installation completed."
