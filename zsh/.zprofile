# ==========================================
# ZSH LOGIN ENVIRONMENT
# ==========================================

typeset -U path

# Machine-specific settings (not tracked), e.g. extra tool paths
if [[ -f "$HOME/.zprofile.local" ]]; then
    source "$HOME/.zprofile.local"
fi

export PATH
