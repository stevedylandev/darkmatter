# DARKMATTER

![cover](https://files.stevedylan.dev/darkmatter.png)

An opinionated terminal setup using [Ghostty](https://ghostty.org), zsh, [Starship](https://starship.rs), and [AIChat](https://github.com/sigoden/aichat)

## Why DARKMATTER?

To me, the terminal has always been a sacred place. Any developer who has accomplished something in their terminal probably feels the same way. However that experience can be hampered by how it's configured. It can take a fair bit of research and time to build a setup you really enjoy, so understandably there are more developers these days turning to closed sourced VC backed solutions. DARKMATTER is my attempt to break that dependency for those who wish to take it.

DARKMATTER is an opinionated setup of Ghostty and zsh, providing sensible defaults and maximum compatability for what developers need day to day. It also features some of my favorite terminal tools that help make your experience that much sweeter. I hope you can take this kit as a starting place and continue to modify and tweak it to your liking!

At the moment this setup and installation flow is designed for MacOS and [Homebrew](https://brew.sh), but by all means feel free to help support the project by creating scripts for Linux or Windows!

## Installation

> [!NOTE]
> [Homebrew](https://brew.sh) is required to setup DARKMATTER

There are two ways you can get DARKMATTER running on your computer

### Install Script

This will by far be the easiest method and the one I recommend; just copy and paste.

```bash
curl -sSL https://darkmatter.build/install.sh | bash
```

[Install script source code](/install.sh)

<details>
  <summary>###Manual Setup</summary>

You can also create the DARKMATTER setup manually by following these steps.

**1. Install Packages**

Run the following commands to install packages for DARKMATTER

```bash
brew install zsh zsh-autosuggestions zsh-syntax-highlighting starship eza zoxide aichat btop

brew install --cask ghostty
```

**2. Setup zsh**

Create a file in your home directory called `.zshrc` with the following contents

```bash
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

# Setup zoxide and starship
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
```

**3. Setup Ghostty**

If it's not already there, create a text file at `~/.config/ghostty/config` with the following contents

```
font-family = CommitMono Nerd Font
font-family-bold = CommitMono Nerd Font
font-family-italic = CommitMono Nerd Font
font-family-bold-italic = CommitMono Nerd Font
font-size = 14

confirm-close-surface = false
clipboard-read = allow
clipboard-write = allow
mouse-hide-while-typing = true
window-padding-x = 6
window-padding-balance = true
window-save-state = always
window-width = 85
window-height = 30

background = #121113
foreground = #ffffff

selection-background = #222222
selection-foreground = #000000

palette = 0=#121113
palette = 1=#5f8787
palette = 2=#fbcb97
palette = 3=#e78a53
palette = 4=#888888
palette = 5=#999999
palette = 6=#aaaaaa
palette = 7=#c1c1c1
palette = 8=#333333
palette = 9=#5f8787
palette = 10=#fbcb97
palette = 11=#e78a53
palette = 12=#888888
palette = 13=#999999
palette = 14=#aaaaaa
palette = 15=#c1c1c1

auto-update-channel = stable
click-repeat-interval = 500
```


**4. Install CommitMono**

DARKMATTER uses a open sourced font called [CommitMono](https://commitmono.com) and in this repo you can download special Nerd Font patched versions of it, which include nice icons used by several of the programs already installed. Check them out in the `assets` folder in this repo.

**5. Open Ghostty!**

After following these steps you should be able to open Ghostty and you will have the DARKMATTER setup

</details>

## Usage
