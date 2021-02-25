# XDG 
export XDG_CACHE_HOME=$HOME/.cache
export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share

# editor 
export EDITOR=vi
export VISUAL=vi

# zsh
export ZDOTDIR=$XDG_CONFIG_HOME/zsh
export HISTFILE=${ZDOTDIR}/history
export HISTSIZE=10000000
export SAVEHIST=10000000

export VIMINIT="source $XDG_CONFIG_HOME/vim/vimrc"
export LESSHISTFILE=$XDG_CACHE_HOME/less/history
