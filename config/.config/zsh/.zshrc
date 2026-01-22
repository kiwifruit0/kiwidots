# ------------------------------ 
# basic env
# ------------------------------ 
export PATH="$HOME/.local/bin:$PATH"
export ZDOTDIR="$HOME/.config/zsh"
export PROMPT_CLEANUP=false

# ------------------------------ 
# initialize znap
# ------------------------------ 
source "$ZDOTDIR/znap/znap.zsh"

# ------------------------------ 
# prompt
# ------------------------------ 
znap eval oh-my-posh 'oh-my-posh init zsh --config $ZDOTDIR/ohmyposhtheme.toml'

# ------------------------------ 
# plugins
# ------------------------------ 
znap source zsh-users/zsh-autosuggestions
znap source zsh-users/zsh-completions

zvm_config() {
  ZVM_VI_HIGHLIGHT_FOREGROUND=#2e3440
  ZVM_VI_HIGHLIGHT_BACKGROUND=#8fbcbb
  ZVM_VI_HIGHLIGHT_EXTRASTYLE=bold

  ZVM_INIT_MODE=sourcing
}
ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT
znap source jeffreytse/zsh-vi-mode

znap source zsh-users/zsh-syntax-highlighting

# ------------------------------ 
# options + keybindings
# ------------------------------ 
setopt autocd
unsetopt beep
zle_highlight=(paste:none)
bindkey '^F' autosuggest-accept

HISTFILE=$ZDOTDIR/.zsh_history
HISTSIZE=1000
SAVEHIST=1000

# ------------------------------ 
# aliases
# ------------------------------ 
alias c='clear'
alias icat='kitty icat'
alias se='sudo -E nvim'
alias ls='ls --color=auto'
alias l='ls --color=auto -la'
alias :q='exit'
alias elt='exa --long --tree --git'
alias omp='oh-my-posh'

# ------------------------------
# other envs
# ------------------------------
# Use znap eval to cache these environment scripts so they don't run every time
[ -f "$HOME/.ghcup/env" ] && znap eval ghcup-env 'cat "$HOME/.ghcup/env"'
[ -f "$HOME/.local/share/../bin/env" ] && znap eval local-env 'cat "$HOME/.local/share/../bin/env"'

