# Load Homebrew autocomplete
if [ -d "/home/linuxbrew/.linuxbrew/share/zsh/site-functions" ]; then
    fpath+=(/home/linuxbrew/.linuxbrew/share/zsh/site-functions)
fi

# Load brew command
if [[ -o interactive ]] && [[ -d /home/linuxbrew/.linuxbrew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  if type brew &>/dev/null; then
    if [[ -w /home/linuxbrew/.linuxbrew ]]; then
      if [[ ! -L "$(brew --prefix)/share/zsh/site-functions/_brew" ]]; then
        brew completions link
      fi
    fi
  fi
fi