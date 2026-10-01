# load common path and environment 
source ~/.config/zsh/path
source ~/.config/zsh/environment

# load any machine-specific local environment stuff, if any 
[[ -r $ZDOTDIR/zshenv.local ]] && source $ZDOTDIR/zshenv.local
