if [ -n "$DISTROBOX_ENTER_PATH" ]; then
    echo "Switching to bash inside Distrobox..."
    exec /bin/bash
    exit 0
fi

# Установить алиасы
alias ll='ls -la'
alias ..='cd ..'
alias neofetch=fastfetch

export STARSHIP_CONFIG=/etc/starship/starship.toml
eval "$(starship init zsh)"

# Настройка кэша автодополнений
zcompdump_file="${ZDOTDIR:-$HOME}/.zcompdump"

# Кэш: если файл кэша существует и моложе суток - используем
if [[ -f $zcompdump_file && $(( $(date +%s) - $(stat -c %Y $zcompdump_file) )) -lt 86400 ]]; then
    autoload -Uz compinit && compinit -C -d "$zcompdump_file"
else
    autoload -Uz compinit && compinit -d "$zcompdump_file"
fi