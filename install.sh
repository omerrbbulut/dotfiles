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
    ssh
)

INSTALL_PACKAGES=false
INSTALL_STARSHIP=false
INSTALL_FONT=false
INSTALL_SSH=false
DRY_RUN=false
CHECK_ONLY=false

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
  --check       Verify installation without modifications
  --dry-run     Simulate Stow operations
  --packages    Install OS packages
  --starship    Install Starship if missing
  --font        Install JetBrainsMono Nerd Font if missing
  --ssh         Configure SSH keys and agent
  --all         Run all installation steps including SSH
  -h, --help    Show this help

Without options, only Stow links are managed.
EOF
}

# ==========================================
# ARGUMENT PARSING
# ==========================================

while [[ $# -gt 0 ]]; do
    case "$1" in
	--check)
	    CHECK_ONLY=true
	    ;;
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
        --ssh)
            INSTALL_SSH=true
            ;;
        --all)
            INSTALL_PACKAGES=true
            INSTALL_STARSHIP=true
            INSTALL_FONT=true
	    INSTALL_SSH=true
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
    [[ -f /etc/os-release ]] ||
        die "Cannot detect operating system."

    # shellcheck disable=SC1091
    source /etc/os-release

    case "$ID" in
        ubuntu)
            OS="ubuntu"

            case "${VERSION_ID:-}" in
                "24.04")
                    success "Supported Ubuntu version: $PRETTY_NAME"
                    ;;
                "26.04")
                    warn "Ubuntu 26.04 support is experimental."
                    warn "Installation has not been validated on this release."
                    ;;
                *)
                    die "Unsupported Ubuntu version: ${VERSION_ID:-unknown}. Supported: 24.04, experimental: 26.04."
                    ;;
            esac
            ;;
        *)
            die "Unsupported distribution: $ID. Arch Linux support is future work."
            ;;
    esac
}

# ==========================================
# DEPENDENCIES
# ==========================================

require_command() {
    command -v "$1" >/dev/null 2>&1 ||
        die "Required command not found: $1"
}

check_requirements() {
    info "Checking installation requirements..."

    local missing=()
    local commands=(stow)
    local cmd

    # tmux is required only for actual plugin installation.
    if [[ "$DRY_RUN" != true ]]; then
        commands+=(git tmux)
    fi

    # curl is required when downloading Starship or Nerd Font.
    if [[ "$DRY_RUN" != true ]] &&
       [[ "$INSTALL_STARSHIP" == true ||
          "$INSTALL_FONT" == true ]]; then
        commands+=(curl)
    fi

    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    if (( ${#missing[@]} > 0 )); then
        die "Required tools are missing: ${missing[*]}"
    fi

    success "All required tools available"
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

    local install_dir="$HOME/.local/bin"

    mkdir -p "$install_dir"

    if ! sh "$installer" -b "$install_dir" -y; then
        rm -f "$installer"
        die "Starship installation failed."
    fi

    rm -f "$installer"

    success "Starship installed to $install_dir"
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
# SSH SETUP
# ==========================================

install_ssh() {
    local script="$DOTFILES_DIR/scripts/setup-ssh.sh"

    [[ -f "$script" ]] ||
        die "SSH setup script missing: $script"

    require_command ssh
    require_command ssh-keygen
    require_command ssh-add

    info "Setting up SSH..."

    bash "$script"

    success "SSH setup completed"
}

# ==========================================
# GNU STOW
# ==========================================

install_dotfiles() {
    require_command stow


    # Secure SSH directory before creating Stow links
    if [[ "$DRY_RUN" != true ]]; then
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
    fi

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

check_installation() {
    local failed=0

    info "Checking dotfiles installation..."

    local commands=(
        kitty
        zsh
        starship
        tmux
        stow
        git
        fzf
        zoxide
    )

    local cmd

    for cmd in "${commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            success "$cmd installed"
        else
            warn "$cmd missing"
            failed=1
        fi
    done

    local files=(
        "$HOME/.zshrc"
        "$HOME/.tmux.conf"
        "$HOME/.gitconfig"
        "$HOME/.config/kitty/kitty.conf"
        "$HOME/.config/starship.toml"
        "$HOME/.config/git/personal.gitconfig"
        "$HOME/.config/git/work.gitconfig"
	"$HOME/.ssh/config"
    )

    local file

    for file in "${files[@]}"; do
        if [[ -L "$file" && -f "$file" ]]; then
            success "Linked: $file"
        else
            warn "Missing or not linked: $file"
            failed=1
        fi
    done

    if fc-list : family | grep -i 'JetBrainsMono Nerd Font' >/dev/null; then
	success "Nerd Font installed"
    else
    	warn "Nerd Font missing"
	failed=1
    fi


    # --------------------------------------
    # SSH VERIFICATION
    # --------------------------------------

    if [[ -d "$HOME/.ssh" ]] &&
       [[ "$(stat -c '%a' "$HOME/.ssh")" == "700" ]]; then
        success "SSH directory permissions: 700"
    else
        warn "SSH directory missing or permissions incorrect"
        failed=1
    fi

    if [[ -f "$HOME/.ssh/github_personal" &&
          -f "$HOME/.ssh/github_personal.pub" ]]; then
        success "GitHub SSH key pair available"
    else
        warn "GitHub SSH key pair missing"
        failed=1
    fi

    if [[ -f "$HOME/.ssh/gitlab_work" &&
          -f "$HOME/.ssh/gitlab_work.pub" ]]; then
        success "GitLab SSH key pair available"
    else
        warn "GitLab SSH key pair missing"
        failed=1
    fi

    if [[ -f "$HOME/.ssh/config.work" ]]; then
        success "Corporate SSH configuration available"
    else
        warn "Corporate SSH configuration missing"
        failed=1
    fi

    if [[ -n "${SSH_AUTH_SOCK:-}" &&
          -S "${SSH_AUTH_SOCK:-}" ]] &&
       ssh-add -l >/dev/null 2>&1; then
        success "SSH agent accessible"
    else
        warn "SSH agent unavailable or no identities loaded"
    fi

    # --------------------------------------
    # TMUX PLUGIN VERIFICATION
    # --------------------------------------

    local plugins=(
        tpm
        tmux
        tmux-resurrect
        tmux-continuum
    )

    local plugin

    for plugin in "${plugins[@]}"; do
        if [[ -d "$HOME/.tmux/plugins/$plugin/.git" ]]; then
            success "tmux plugin: $plugin"
        else
            warn "tmux plugin missing: $plugin"
            failed=1
        fi
    done

    if (( failed )); then
        error "Some checks failed"
        return 1
    fi

    success "All checks passed"
}

# ==========================================
# PRE-INSTALLATION CHECKS
# ==========================================

preflight_stow() {
    info "Running Stow preflight checks..."

    # Bootstrap GNU Stow on a fresh Ubuntu installation.
    if ! command -v stow >/dev/null 2>&1; then
        if [[ "$DRY_RUN" == true ]]; then
            die "GNU Stow is required for dry-run. Install stow first."
        fi

        if [[ "$INSTALL_PACKAGES" != true ]]; then
            die "GNU Stow is missing. Install stow or use --all."
        fi

        info "Installing GNU Stow bootstrap dependency..."

        sudo apt-get update
        sudo apt-get install -y stow
    fi

    require_command stow

    # Check all expected Stow packages exist.
    local package

    for package in "${STOW_PACKAGES[@]}"; do
        [[ -d "$DOTFILES_DIR/$package" ]] ||
            die "Missing Stow package: $package"
    done

    # Check for conflicts without modifying files.
    if ! stow \
        -d "$DOTFILES_DIR" \
        -t "$HOME" \
        --no-folding \
        -nv \
        "${STOW_PACKAGES[@]}"; then

        die "Stow conflicts detected. Installation aborted."
    fi

    success "Stow preflight checks passed"
}

# ==========================================
# MAIN
# ==========================================

main() {
    detect_os

    # --------------------------------------
    # CHECK ONLY
    # --------------------------------------

    if [[ "$CHECK_ONLY" == true ]]; then
        check_installation
        return
    fi

    # --------------------------------------
    # DRY RUN
    # --------------------------------------

    if [[ "$DRY_RUN" == true ]]; then
        info "DRY-RUN MODE"

        if [[ "$INSTALL_PACKAGES" == true ||
              "$INSTALL_STARSHIP" == true ||
              "$INSTALL_FONT" == true ||
              "$INSTALL_SSH" == true ]]; then
            warn "Skipping all software installations in dry-run mode"
        fi
    fi

    # --------------------------------------
    # PRE-INSTALLATION CHECKS
    # --------------------------------------

    preflight_stow

    # --------------------------------------
    # SYSTEM PACKAGES
    # --------------------------------------

    if [[ "$DRY_RUN" != true &&
          "$INSTALL_PACKAGES" == true ]]; then
        install_system_packages
    fi

    # --------------------------------------
    # DEPENDENCIES
    # --------------------------------------

    check_requirements

    # --------------------------------------
    # OPTIONAL COMPONENTS
    # --------------------------------------

    if [[ "$DRY_RUN" != true ]]; then
        if [[ "$INSTALL_STARSHIP" == true ]]; then
            install_starship
        fi

        if [[ "$INSTALL_FONT" == true ]]; then
            install_font
        fi
    fi

    # --------------------------------------
    # GNU STOW
    # --------------------------------------

    install_dotfiles

    # --------------------------------------
    # SSH
    # --------------------------------------

    if [[ "$INSTALL_SSH" == true &&
          "$DRY_RUN" != true ]]; then
        install_ssh
    fi

    # --------------------------------------
    # TMUX PLUGINS
    # --------------------------------------

    install_tmux_plugins

    # --------------------------------------
    # VERIFICATION
    # --------------------------------------

    if [[ "$DRY_RUN" != true ]]; then
        verify_installation
    fi

    success "Dotfiles setup completed!"
}

main "$@"
