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
    gnupg
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
# GITHUB CLI (OFFICIAL REPOSITORY)
# ------------------------------------------

# Ubuntu's gh package lags behind upstream, so use GitHub's apt repository.
# The signing keyring is verified against GitHub's published fingerprints:
# https://github.com/cli/cli/blob/trunk/docs/install_linux.md

GH_KEYRING="/etc/apt/keyrings/githubcli-archive-keyring.gpg"
GH_KEYRING_URL="https://cli.github.com/packages/githubcli-archive-keyring.gpg"
GH_SOURCE="/etc/apt/sources.list.d/github-cli.list"
GH_FINGERPRINTS=(
    2C6106201985B60E6C7AC87323F3D4EA75716059
    7F38BBB59D064DBCB3D84D725612B36462313325
)

# Succeed only if every primary key in the keyring is a published one.
verify_gh_keyring() {
    local keyring="$1"
    local fingerprint
    local found=0

    while read -r fingerprint; do
        [[ " ${GH_FINGERPRINTS[*]} " == *" $fingerprint "* ]] || return 1
        found=1
    done < <(
        gpg --show-keys --with-colons "$keyring" 2>/dev/null |
            awk -F: '$1 == "pub" {primary = 1; next}
                     $1 == "fpr" && primary {print $10; primary = 0}'
    )

    (( found ))
}

setup_github_cli_repo() {
    local tmp_keyring
    local source_line

    source_line="deb [arch=$(dpkg --print-architecture) signed-by=$GH_KEYRING] https://cli.github.com/packages stable main"

    if [[ -f "$GH_KEYRING" ]] && verify_gh_keyring "$GH_KEYRING" &&
       [[ -f "$GH_SOURCE" && "$(cat "$GH_SOURCE")" == "$source_line" ]]; then
        log "GitHub CLI repository already configured."
        return 0
    fi

    tmp_keyring="$(mktemp)"

    if ! curl -fsSL -o "$tmp_keyring" "$GH_KEYRING_URL"; then
        rm -f "$tmp_keyring"
        error "Could not download the GitHub CLI signing key."
        return 1
    fi

    if ! verify_gh_keyring "$tmp_keyring"; then
        rm -f "$tmp_keyring"
        error "GitHub CLI signing key fingerprint mismatch. Repository not added."
        return 1
    fi

    # Called from an if statement, so errexit does not apply here.
    sudo install -d -m 755 /etc/apt/keyrings &&
        sudo install -m 644 "$tmp_keyring" "$GH_KEYRING" || {
        rm -f "$tmp_keyring"
        error "Could not install the GitHub CLI signing key."
        return 1
    }

    rm -f "$tmp_keyring"

    printf '%s\n' "$source_line" | sudo tee "$GH_SOURCE" >/dev/null || {
        error "Could not add the GitHub CLI repository."
        return 1
    }

    log "GitHub CLI repository added."
}

log "Installing GitHub CLI..."

if setup_github_cli_repo; then
    sudo apt-get update
else
    error "Falling back to the Ubuntu gh package."
fi

sudo apt-get install -y gh

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
