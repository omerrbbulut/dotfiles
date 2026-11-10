#!/usr/bin/env bash

set -Eeuo pipefail

# ==========================================
# DOTFILES - ARCH LINUX PACKAGES
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

if [[ "$ID" != "arch" ]]; then
    error "This script is intended for Arch Linux."
    exit 1
fi

log "Detected: $PRETTY_NAME"

# ------------------------------------------
# PACKAGE LIST
# ------------------------------------------

PACKAGES=(
    # Core
    base-devel
    git
    curl
    wget
    unzip
    zip
    ca-certificates

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
    fd
    bat
    btop
    tree
    jq

    # Clipboard
    xclip
    wl-clipboard

    # Development
    cmake
    ninja
    gdb
    clang
    lldb
    pkgconf
    python
    python-pip
    python-virtualenv

    # Editor
    neovim

    # Fonts
    ttf-jetbrains-mono
    fontconfig
)

# ------------------------------------------
# PACMAN
# ------------------------------------------

log "Updating system and installing required packages..."

sudo pacman -Syu --needed "${PACKAGES[@]}"

# ------------------------------------------
# FINISH
# ------------------------------------------

log "Arch Linux package installation completed."
