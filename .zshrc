# history setup
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

# completion using arrow keys (based on history)
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# completion using vim keys
bindkey '^k' history-search-backward
bindkey '^j' history-search-forward

# Source zsh plugins
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Alias / keyboard shortcuts
alias cd="z"
alias ls="eza --icons=always"
alias ai="aichat"

# Exports
export BAT_THEME="ansi"

# fzf settings
source <(fzf --zsh)
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude ".git"'
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
  --color=fg:#c1c1c1,fg+:#ffffff,bg:#121113,bg+:#222222
  --color=hl:#5f8787,hl+:#fbcb97,info:#e78a53,marker:#fbcb97
  --color=prompt:#e78a53,spinner:#5f8787,pointer:#fbcb97,header:#aaaaaa
  --color=border:#333333,label:#888888,query:#ffffff
  --border="rounded" --border-label="" --preview-window="border-rounded" --prompt="> "
  --marker=">" --pointer="◆" --separator="─" --scrollbar="│"'

# Setup zoxide and starship
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
