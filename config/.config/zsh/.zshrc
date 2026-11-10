# ------------------------------ 
# set env variables
# ------------------------------ 
export PATH=$PATH:$HOME/.local/bin
export ZDOTDIR=$HOME/.config/zsh

# ------------------------------ 
# znap
# ------------------------------ 
# Download Znap, if it's not there yet.
#[[ -r $ZDOTDIR/znap/znap.zsh ]] ||
#    git clone --depth 1 -- \
#        https://github.com/marlonrichert/zsh-snap.git $ZDOTDIR/znap
source $ZDOTDIR/znap/znap.zsh  # Start Znap

# ------------------------------ 
# oh-my-posh prompt
# ------------------------------ 
# Oh My Posh reads the stable palette path on each prompt.
_theme_prompt="$HOME/.config/desktop-theme/current/prompt.toml"
[[ -r $_theme_prompt ]] || _theme_prompt="$ZDOTDIR/ohmyposhtheme.toml"
znap eval oh-my-posh 'oh-my-posh init zsh --config $_theme_prompt --print'
# Explicit config bypasses Oh My Posh's per-session palette cache after switching.
_kiwidots_omp() {
  command oh-my-posh --config "$_theme_prompt" "$@"
}
_omp_executable=_kiwidots_omp

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
# Fallback until the desktop palette is initialized
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
alias se='sudo -E nvim'
alias ls='ls --color=auto'
alias l='ls --color=auto -la'
alias :q='exit'
alias elt='exa --long --tree --git'
alias timeshift-gtk='sudo -E HOME=/root XDG_CACHE_HOME=/root/.cache timeshift-gtk'
alias leet='nvim leetcode.nvim'
alias ablewine='WINEPREFIX=/home/kiwi/apps/ableton/.ableton-wine'
alias omp='oh-my-posh'
alias wlc="wl-copy"

# tmux aliases
alias tn='tmux new-session -s'
alias tl='tmux list-sessions'
alias ta='tmux attach-session'

# ------------------------------
# other
# ------------------------------

[[ -r "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/dev/scripts/:$PATH"

if [ -f "./venv/bin/activate" ]; then
    source ./venv/bin/activate
fi
export PATH="/home/kiwi/bin:$PATH"

[ -f ~/.env.secrets ] && source ~/.env.secrets
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"
export CHROME_EXECUTABLE=/usr/bin/chromium
export PATH=~/.npm-global/bin:$PATH

# Refresh palette-dependent shell highlights after a desktop theme change.
_kiwidots_theme_refresh() {
  local palette="$HOME/.config/desktop-theme/current/shell.zsh"
  [[ -r $palette ]] && source "$palette"
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _kiwidots_theme_refresh
_kiwidots_theme_refresh
