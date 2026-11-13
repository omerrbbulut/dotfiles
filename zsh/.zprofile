# ==========================================
# ZSH LOGIN ENVIRONMENT
# ==========================================

typeset -U path

# STM32CubeCLI
if [[ -d "$HOME/.local/stm32cube/bin" ]]; then
    path=("$HOME/.local/stm32cube/bin" $path)
fi

# STM32CubeProgrammer
if [[ -d /opt/st/STM32CubeProgrammer/bin ]]; then
    path=(/opt/st/STM32CubeProgrammer/bin $path)
fi

export PATH
