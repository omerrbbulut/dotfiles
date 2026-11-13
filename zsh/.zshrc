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

# Cached completions for tools that generate their own.
ZSH_COMPLETION_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
mkdir -p "$ZSH_COMPLETION_CACHE"
fpath=("$ZSH_COMPLETION_CACHE" $fpath)

# GitHub CLI: regenerate only when the gh binary is newer than the cache.
if (( $+commands[gh] )); then
    if [[ ! -s "$ZSH_COMPLETION_CACHE/_gh" ||
          "$commands[gh]" -nt "$ZSH_COMPLETION_CACHE/_gh" ]]; then
        gh completion -s zsh >| "$ZSH_COMPLETION_CACHE/_gh" 2>/dev/null
    fi
fi

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

compinit

# ------------------------------------------
# KEYBINDINGS
# ------------------------------------------

# ------------------------------------------
# KEYBINDINGS
# Ubuntu / Arch / GNOME Terminal / Kitty
# ------------------------------------------

# Emacs-style line editing
bindkey -e

# Ctrl + Left / Right: Navigate between words
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word

# Alternative terminal escape sequences
bindkey '^[[5D' backward-word
bindkey '^[[5C' forward-word

# Ctrl + Delete: Delete next word
bindkey '^[[3;5~' kill-word

# Ctrl + Backspace: Delete previous word
bindkey '^H' backward-kill-word

# Home / End: Beginning / end of line
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line

# Delete
bindkey '^[[3~' delete-char

# Ctrl + A / E: Beginning / end of line
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line

# Alt + Left / Right: Navigate between words
bindkey '^[^[[D' backward-word
bindkey '^[^[[C' forward-word

# Alt + Backspace: Delete previous word
bindkey '^[^?' backward-kill-word

# Ctrl + W: Delete previous word
bindkey '^W' backward-kill-word

# Ctrl + U: Delete from cursor to beginning
bindkey '^U' backward-kill-line

# Ctrl + K: Delete from cursor to end
bindkey '^K' kill-line

# Ctrl + Y: Paste last deleted text
bindkey '^Y' yank

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
export PATH="$HOME/.local/bin:$PATH"
