# ==========================================
# ZSH CONFIGURATION
# ==========================================

# ------------------------------------------
# USER BINARIES
# ------------------------------------------

typeset -U path

path=(
    "$HOME/.local/bin"
    $path
)

export PATH

# ------------------------------------------
# HISTORY
# ------------------------------------------

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY

# ------------------------------------------
# COMPLETION
# ------------------------------------------

autoload -Uz compinit

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

compinit

# ------------------------------------------
# KEYBINDINGS
# ------------------------------------------

bindkey -e

# ------------------------------------------
# FZF
# ------------------------------------------

if [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
    source /usr/share/doc/fzf/examples/key-bindings.zsh
fi

if [[ -f /usr/share/doc/fzf/examples/completion.zsh ]]; then
    source /usr/share/doc/fzf/examples/completion.zsh
fi

# ------------------------------------------
# ZOXIDE
# ------------------------------------------

if (( $+commands[zoxide] )); then
    eval "$(zoxide init zsh)"
fi

# ------------------------------------------
# AUTOSUGGESTIONS
# Ubuntu / Arch compatible
# ------------------------------------------

for plugin in \
    /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
do
    if [[ -f "$plugin" ]]; then
        source "$plugin"
        break
    fi
done

# ------------------------------------------
# ALIASES
# ------------------------------------------

# Directory listings: eza when available, colored ls otherwise
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --group-directories-first --icons=auto'
    alias ll='eza -lah --group-directories-first --icons=auto --git --time-style=long-iso'
    alias la='eza -a --group-directories-first --icons=auto'
    alias lt='eza --tree --level=2 --group-directories-first --icons=auto --git-ignore'
else
    alias ls='ls --color=auto'
    alias ll='ls -lah --color=auto'
    alias la='ls -A --color=auto'
fi
alias ..='cd ..'
alias ...='cd ../..'

# Git
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate'
alias ga='git add'
alias gc='git commit'

# tmux
alias ta='tmux attach'
alias tl='tmux list-sessions'
alias tn='tmux new -s'

# ------------------------------------------
# STARSHIP
# ------------------------------------------

if (( $+commands[starship] )); then
    eval "$(starship init zsh)"
fi

# ------------------------------------------
# SYNTAX HIGHLIGHTING
# Keep near the end
# Ubuntu / Arch compatible
# ------------------------------------------

for plugin in \
    /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
    /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
do
    if [[ -f "$plugin" ]]; then
        source "$plugin"
        break
    fi
done
