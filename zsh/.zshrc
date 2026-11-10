# ==========================================
# ZSH CONFIGURATION
# ==========================================

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
# ------------------------------------------

if [[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# ------------------------------------------
# ALIASES
# ------------------------------------------

alias ll='ls -lah'
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
# ------------------------------------------

if [[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
