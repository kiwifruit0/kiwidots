# ------------------------------ 
# set env variables
# ------------------------------ 
export PATH=$PATH:$HOME/.local/bin
export ZDOTDIR=$HOME/.config/zsh

# ------------------------------ 
# znap
# ------------------------------ 
source $ZDOTDIR/znap/znap.zsh  # Start Znap
# Download Znap, if it's not there yet.
#[[ -r ~/.config/zsh/znap/znap.zsh ]] ||
#    git clone --depth 1 -- \
#        https://github.com/marlonrichert/zsh-snap.git $ZDOTDIR/znap

# ------------------------------ 
# oh-my-posh prompt
# ------------------------------ 
znap eval oh-my-posh 'oh-my-posh init zsh --config $ZDOTDIR/ohmyposhtheme.toml --print'

# ------------------------------ 
# plugins
# ------------------------------ 
znap source zsh-users/zsh-autosuggestions
znap source zsh-users/zsh-completions
znap source zsh-users/zsh-syntax-highlighting

# ------------------------------ 
# options
# ------------------------------ 
setopt autocd
unsetopt beep
zle_highlight=(paste:none)
bindkey '^F' autosuggest-accept  # Ctrl+F fill suggestion

# ------------------------------
# vim mode
# ------------------------------
# changing highlight colors to nord theme
zvm_config() {
  ZVM_VI_HIGHLIGHT_FOREGROUND=#2e3440
  ZVM_VI_HIGHLIGHT_BACKGROUND=#8fbcbb
  ZVM_VI_HIGHLIGHT_EXTRASTYLE=bold
}
znap source jeffreytse/zsh-vi-mode

# start in insert mode to prevent redraw lag
ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT

# ------------------------------ 
# settings
# ------------------------------ 
HISTFILE=$ZDOTDIR/.zsh_history
HISTSIZE=1000
SAVEHIST=1000

# ------------------------------ 
# aliases
# ------------------------------ 
alias c='clear'
alias icat='kitty icat'
alias se='sudoedit'
alias ls='ls --color=auto'
alias l='ls --color=auto -la'
alias :q='exit'
alias elt='exa --long --tree --git'
alias timeshift-gtk='sudo -E HOME=/root XDG_CACHE_HOME=/root/.cache timeshift-gtk'

# tmux aliases
alias tn='tmux new-session -s'
alias tl='tmux list-sessions'
alias ta='tmux attach-session'

# ------------------------------
# other
# ------------------------------
[ -f "/home/kiwi/.ghcup/env" ] && . "/home/kiwi/.ghcup/env" # ghcup-env
. "$HOME/.local/share/../bin/env"

# distrobox fixes
# export XDG_RUNTIME_DIR=/run/user/1000
export PULSE_SERVER=unix:/run/user/1000/pulse/native
export PIPEWIRE_RUNTIME_DIR=/run/user/1000
export QT_FONT_DPI=192
