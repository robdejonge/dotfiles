#!/bin/zsh

mkdir -p $XDG_CACHE_HOME
mkdir -p $XDG_CACHE_HOME/zsh
mkdir -p $XDG_CACHE_HOME/vim
mkdir -p $XDG_CACHE_HOME/vim/undodir
mkdir -p $XDG_DATA_HOME
mkdir -p $XDG_DATA_HOME/mail

touch $XDG_CACHE_HOME/zsh/history
touch $XDG_DATA_HOME/mail/mbox