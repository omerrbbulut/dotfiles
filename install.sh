#!/usr/bin/env bash

set -Eeuo pipefail

# ==========================================
# DOTFILES INSTALLER
# Ubuntu / Arch Linux
# GNU Stow
# ==========================================

DOTFILES_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P
)"

PACKAGES_DIR="$DOTFILES_DIR/packages"

STOW_PACKAGES=(
    kitty
    zsh
    starship
    tmux
    git
)

INSTALL_PACKAGES=false
INSTALL_STARSHIP=false
INSTALL_FONT=false
DRY_RUN=false

# ==========================================
# LOGGING
# ==========================================

info() {
    printf '\033[1;34m[INFO]\033[0m %s\n' "$*"
}

success() {
    printf '\033[1;32m[OK]\033[0m %s\n' "$*"
}

warn() {
    printf '\033[1;33m[WARN]\033[0m %s\n' "$*" >&2
}

error() {
    printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2
}

die() {
    error "$*"
    exit 1
}

# ==========================================
# HELP
# ==========================================

usage() {
    cat <<'EOF'
Dotfiles Installer

Usage:
  ./install.sh [OPTIONS]

Options:
  --dry-run     Simulate Stow operations
  --packages    Install OS packages
  --starship    Install Starship if missing
  --font        Install JetBrainsMono Nerd Font if missing
  --all         Run all installation steps
  -h, --help    Show this help

Without options, only Stow links are managed.
EOF
}

# ==========================================
# ARGUMENT PARSING
# ==========================================

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            ;;
        --packages)
            INSTALL_PACKAGES=true
            ;;
        --starship)
            INSTALL_STARSHIP=true
            ;;
        --font)
            INSTALL_FONT=true
            ;;
        --all)
            INSTALL_PACKAGES=true
            INSTALL_STARSHIP=true
            INSTALL_FONT=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "Unknown argument: $1"
            ;;
    esac
    shift
done

# ==========================================
# OS DETECTION
# ==========================================

detect_os() {
    [[ -f /etc/os-release ]] || die "Cannot detect OS."

    # shellcheck disable=SC1091
    source /etc/os-release

    case "$ID" in
        ubuntu)
            OS="ubuntu"
            ;;
        arch)
            OS="arch"
            ;;
        *)
            die "Unsupported distribution: $ID"
            ;;
    esac

    success "Detected OS: $PRETTY_NAME"
}

# ==========================================
# DEPENDENCIES
# ==========================================

require_command() {
    command -v "$1" >/dev/null 2>&1 ||
        die "Required command not found: $1"
}

# ==========================================
# SYSTEM PACKAGES
# ==========================================

install_system_packages() {
    local script="$PACKAGES_DIR/$OS.sh"

    [[ -f "$script" ]] ||
        die "Package script missing: $script"

    info "Installing packages for $OS"

    bash "$script"

    success "System package installation completed"
}

# ==========================================
# STARSHIP
# ==========================================

install_starship() {
    if command -v starship >/dev/null 2>&1; then
        success "Starship already installed"
        return
    fi

    require_command curl

    info "Downloading Starship installer"

    local installer
    installer="$(mktemp)"

    curl -fsSL https://starship.rs/install.sh \
        -o "$installer" || {
            rm -f "$installer"
            die "Failed to download Starship installer."
        }

    info "Review the installer before running it."
    info "Installer saved at: $installer"

    printf 'Run the downloaded installer? [y/N] '
    read -r answer

    if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
        warn "Starship installation skipped"
        rm -f "$installer"
        return
    fi

    sh "$installer" -b "$HOME/.local/bin"

    rm -f "$installer"

    success "Starship installed to ~/.local/bin"
}

# ==========================================
# NERD FONT
# ==========================================

install_font() {
    require_command curl
    require_command unzip
    require_command fc-cache
    require_command fc-match

    if fc-list : family | grep -qi \
        'JetBrainsMono Nerd Font'; then
        success "JetBrainsMono Nerd Font already installed"
        return
    fi

    local version="v3.5.1"
    local font_dir="$HOME/.local/share/fonts/JetBrainsMonoNerd"
    local archive

    archive="$(mktemp --suffix=.zip)"

    info "Downloading JetBrainsMono Nerd Font $version"

    curl -fL \
        "https://github.com/ryanoasis/nerd-fonts/releases/download/${version}/JetBrainsMono.zip" \
        -o "$archive" || {
            rm -f "$archive"
            die "Font download failed."
        }

    mkdir -p "$font_dir"

    unzip -oq "$archive" '*.ttf' -d "$font_dir"

    rm -f "$archive"

    fc-cache -f "$font_dir"

    success "JetBrainsMono Nerd Font installed"
}

# ==========================================
# GNU STOW
# ==========================================

install_dotfiles() {
    require_command stow

    info "Dotfiles directory: $DOTFILES_DIR"
    info "Target directory: $HOME"

    local packages=()
    local package

    for package in "${STOW_PACKAGES[@]}"; do
        if [[ -d "$DOTFILES_DIR/$package" ]] &&
           [[ -n "$(find "$DOTFILES_DIR/$package" -type f -print -quit)" ]]; then
            packages+=("$package")
        else
            warn "Skipping empty/missing package: $package"
        fi
    done

    (( ${#packages[@]} > 0 )) ||
        die "No Stow packages found."

    info "Checking Stow conflicts..."

    stow \
        -d "$DOTFILES_DIR" \
        -t "$HOME" \
        --no-folding \
        -nv \
        "${packages[@]}" ||
        die "Stow conflict detected. No links created."

    if [[ "$DRY_RUN" == true ]]; then
        success "Dry-run completed"
        return
    fi

    info "Creating Stow links..."

    stow \
        -d "$DOTFILES_DIR" \
        -t "$HOME" \
        --no-folding \
        -v \
        "${packages[@]}"

    success "Dotfiles linked successfully"
}

# ==========================================
# VERIFICATION
# ==========================================

verify_installation() {
    info "Verifying configuration files"

    local files=(
        "$HOME/.config/kitty/kitty.conf"
        "$HOME/.config/starship.toml"
        "$HOME/.zshrc"
        "$HOME/.tmux.conf"
    )

    local file

    for file in "${files[@]}"; do
        if [[ -L "$file" && -f "$file" ]]; then
            success "$file"
        else
            warn "Missing or not linked: $file"
        fi
    done
}

# ==========================================
# TMUX PLUGINS
# ==========================================

install_tmux_plugins() {
    local plugin_dir="$HOME/.tmux/plugins"
    local tpm_dir="$plugin_dir/tpm"

    info "Checking tmux plugins..."

    if [[ "$DRY_RUN" == true ]]; then
        info "[DRY-RUN] Would check/install TPM"
        info "[DRY-RUN] Would install configured tmux plugins"
        return 0
    fi

    require_command git
    require_command tmux

    # --------------------------------------
    # INSTALL TPM
    # --------------------------------------

    if [[ -d "$tpm_dir/.git" ]]; then
        success "TPM already installed"
    elif [[ -e "$tpm_dir" ]]; then
        die "TPM directory exists but is not a Git repository: $tpm_dir"
    else
        info "Installing TPM..."

        mkdir -p "$plugin_dir"

        git clone --depth 1 \
            https://github.com/tmux-plugins/tpm \
            "$tpm_dir"

        success "TPM installed"
    fi

    # --------------------------------------
    # INSTALL PLUGINS
    # --------------------------------------

    local installer="$tpm_dir/bin/install_plugins"

    [[ -x "$installer" ]] ||
        die "TPM plugin installer not found: $installer"

    [[ -f "$HOME/.tmux.conf" ]] ||
        die "tmux configuration not found"

    info "Installing configured tmux plugins..."

    "$installer" ||
        die "tmux plugin installation failed"

    # --------------------------------------
    # VERIFY PLUGINS
    # --------------------------------------

    local plugin

    for plugin in \
        tmux \
        tmux-resurrect \
        tmux-continuum
    do
        if [[ -d "$plugin_dir/$plugin/.git" ]]; then
            success "$plugin installed"
        else
            die "Missing or incomplete tmux plugin: $plugin"
        fi
    done

    success "tmux plugins ready"
}

# ==========================================
# MAIN
# ==========================================

main() {
    detect_os

    if [[ "$DRY_RUN" == true ]]; then
        info "DRY-RUN MODE"

        if [[ "$INSTALL_PACKAGES" == true ||
              "$INSTALL_STARSHIP" == true ||
              "$INSTALL_FONT" == true ]]; then
            warn "Skipping all software installations in dry-run mode"
        fi
    else
        if [[ "$INSTALL_PACKAGES" == true ]]; then
            install_system_packages
        fi

        if [[ "$INSTALL_STARSHIP" == true ]]; then
            install_starship
        fi

        if [[ "$INSTALL_FONT" == true ]]; then
            install_font
        fi
    fi

    install_dotfiles

    # Install tmux plugins after Stow configuration
    install_tmux_plugins

    if [[ "$DRY_RUN" != true ]]; then
	verify_installation
    fi

    success "Dotfiles setup completed!"
}

main "$@"
