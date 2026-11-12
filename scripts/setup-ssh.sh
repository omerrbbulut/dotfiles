#!/usr/bin/env bash

set -Eeuo pipefail

SSH_DIR="$HOME/.ssh"
WORK_CONFIG="$SSH_DIR/config.work"
WORK_IDENTITY="$HOME/.config/git/work.gitconfig"
PERSONAL_IDENTITY="$HOME/.config/git/personal.gitconfig"
WORK_EMAIL=""

log() {
    printf '\033[1;34m[INFO]\033[0m %s\n' "$*"
}

ok() {
    printf '\033[1;32m[OK]\033[0m %s\n' "$*"
}

warn() {
    printf '\033[1;33m[WARN]\033[0m %s\n' "$*" >&2
}

confirm() {
    local answer

    # Do not prompt when standard input is not interactive.
    if [[ ! -t 0 ]]; then
        warn "Non-interactive session: skipping prompt: $1"
        return 1
    fi

    if ! read -r -p "$1 [y/N]: " answer; then
        warn "Unable to read user input."
        return 1
    fi

    [[ "$answer" =~ ^[Yy]$ ]]
}

create_key() {
    local name="$1"
    local email="$2"
    local key="$SSH_DIR/$name"

    if [[ -e "$key" || -L "$key" ]]; then
        ok "Existing key preserved: $name"
        return
    fi

    if [[ -e "$key.pub" || -L "$key.pub" ]]; then
        warn "Public key exists without private key: $name"
        return
    fi

    if confirm "Create SSH key $name?"; then
        ssh-keygen \
            -t ed25519 \
            -a 100 \
            -C "$email" \
            -f "$key"

        chmod 600 "$key"
        chmod 644 "$key.pub"

        ok "SSH key created: $name"
    fi
}

add_key_to_agent() {
    local key="$1"
    local fingerprint
    local agent_status

    [[ -f "$key" ]] || return 0

    if [[ -z "${SSH_AUTH_SOCK:-}" ||
          ! -S "${SSH_AUTH_SOCK:-}" ]]; then
        warn "SSH agent unavailable. Skipping ssh-add."
        return 0
    fi

    # Check that the agent is accessible.
    ssh-add -l >/dev/null 2>&1 && agent_status=0 || agent_status=$?

    if (( agent_status == 2 )); then
        warn "Cannot communicate with SSH agent."
        return 0
    fi

    # Fingerprint of the public key.
    if [[ ! -f "$key.pub" ]]; then
        warn "Public key missing: $key.pub"
        return 1
    fi

    fingerprint="$(
        ssh-keygen -lf "$key.pub" -E sha256 |
            awk '{print $2}'
    )"

    # Skip keys that are already loaded.
    if ssh-add -l -E sha256 2>/dev/null |
       awk '{print $2}' |
       grep -Fxq "$fingerprint"; then
        ok "SSH key already loaded: $(basename "$key")"
        return 0
    fi

    if confirm "Add $(basename "$key") to SSH agent?"; then
        ssh-add "$key"
        ok "SSH key added: $(basename "$key")"
    fi
}

configure_work_identity() {
    local name
    local default_name

    # Existing local identity: reuse its email.
    if [[ -f "$WORK_IDENTITY" && ! -L "$WORK_IDENTITY" ]]; then
        WORK_EMAIL="$(git config -f "$WORK_IDENTITY" --get user.email || true)"

        if [[ -n "$WORK_EMAIL" ]]; then
            ok "Existing work Git identity preserved"
            return 0
        fi
    fi

    if [[ ! -t 0 ]]; then
        warn "Non-interactive session: skipping work Git identity."
        return 1
    fi

    default_name="$(git config -f "$PERSONAL_IDENTITY" --get user.name 2>/dev/null || true)"

    read -r -p "Work Git name [$default_name]: " name
    read -r -p "Work Git email: " WORK_EMAIL

    name="${name:-$default_name}"

    if [[ -z "$name" ||
          ! "$WORK_EMAIL" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]]; then
        warn "Invalid work name or email."
        WORK_EMAIL=""
        return 1
    fi

    # Replace a stale symlink from older versions that tracked this file.
    [[ -L "$WORK_IDENTITY" ]] && rm -f "$WORK_IDENTITY"

    mkdir -p "$(dirname "$WORK_IDENTITY")"

    (
        umask 077
        git config -f "$WORK_IDENTITY" user.name "$name"
        git config -f "$WORK_IDENTITY" user.email "$WORK_EMAIL"
    ) || {
        warn "Could not create $WORK_IDENTITY"
        WORK_EMAIL=""
        return 1
    }

    ok "Work Git identity created: $WORK_IDENTITY"
}

configure_work_gitlab() {
    local hostname
    local port

    if [[ -e "$WORK_CONFIG" || -L "$WORK_CONFIG" ]]; then
        ok "Existing work configuration preserved"
        return
    fi

    read -r -p "GitLab hostname or IP: " hostname
    read -r -p "GitLab SSH port [22]: " port

    port="${port:-22}"

    # Reject URLs and unexpected characters.
    if [[ ! "$hostname" =~ ^[a-zA-Z0-9._:-]+$ ||
          "$hostname" == *://* ]]; then
        warn "Enter a hostname or IP, not an HTTP URL."
        return 1
    fi

    if [[ ! "$port" =~ ^[0-9]+$ ]] ||
       (( 10#$port < 1 || 10#$port > 65535 )); then
        warn "Invalid SSH port."
        return 1
    fi

    (
        umask 077
        set -C

        cat > "$WORK_CONFIG" <<EOF
# Local corporate SSH configuration
# Not tracked by Git

Host gitlab-work
    HostName $hostname
    User git
    Port $port
    IdentityFile ~/.ssh/gitlab_work
    IdentitiesOnly yes
    AddKeysToAgent yes
EOF
    ) || {
        warn "Could not safely create $WORK_CONFIG"
        return 1
    }
    ok "Corporate SSH configuration created"
}

main() {
    log "Preparing SSH directory..."

    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"

    # --------------------------------------
    # PERSONAL GITHUB
    # --------------------------------------

    create_key github_personal "omerrbbulut@gmail.com"

    # --------------------------------------
    # CORPORATE GITLAB (OPTIONAL)
    # --------------------------------------

    if [[ -e "$WORK_CONFIG" || -L "$WORK_CONFIG" ]]; then
        ok "Existing work configuration preserved"

        if configure_work_identity; then
            create_key gitlab_work "$WORK_EMAIL"
        fi

    elif confirm "Configure corporate GitLab?"; then

        if configure_work_identity; then
            create_key gitlab_work "$WORK_EMAIL"
        fi

        if [[ -f "$SSH_DIR/gitlab_work" &&
              -f "$SSH_DIR/gitlab_work.pub" ]]; then

            configure_work_gitlab

        else
            warn "GitLab SSH key is missing."
            warn "Corporate GitLab configuration skipped."
        fi

    else
        log "Corporate GitLab setup skipped"
    fi

    # --------------------------------------
    # SSH AGENT
    # --------------------------------------

    add_key_to_agent "$SSH_DIR/github_personal"
    add_key_to_agent "$SSH_DIR/gitlab_work"

    # --------------------------------------
    # AGENT STATUS
    # --------------------------------------

    if [[ -n "${SSH_AUTH_SOCK:-}" &&
          -S "${SSH_AUTH_SOCK:-}" ]]; then

        local agent_status

        ssh-add -l >/dev/null 2>&1 &&
            agent_status=0 || agent_status=$?

        case "$agent_status" in
            0)
                log "SSH agent identities:"
                ssh-add -l
                ;;
            1)
                log "SSH agent is available but has no identities."
                ;;
            *)
                warn "SSH agent is not responding."
                ;;
        esac
    else
        log "SSH agent is not available in this session."
    fi

    ok "SSH setup completed"
}

main "$@"
