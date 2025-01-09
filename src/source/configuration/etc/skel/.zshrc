# Установить алиасы
alias ll='ls -la'
alias ..='cd ..'
alias neofetch=fastfetch

eval "$(starship init bash)"

# Настройка кэша автодополнений
zcompdump_file="${ZDOTDIR:-$HOME}/.zcompdump"

# Кэш: если файл кэша существует и моложе суток - используем
if [[ -f $zcompdump_file && $(( $(date +%s) - $(stat -c %Y $zcompdump_file) )) -lt 86400 ]]; then
    autoload -Uz compinit && compinit -C -d "$zcompdump_file"
else
    autoload -Uz compinit && compinit -d "$zcompdump_file"
fi