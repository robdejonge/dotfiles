### THE COMMON STUFF ###

# Configure zsh 
setopt AUTO_CD    # enabled changing directories without typing 'cd' command
autoload -U colors && colors

# Command history parameters
setopt HIST_SAVE_NO_DUPS
setopt inc_append_history
setopt share_history
export HISTFILE=${XDG_CACHE_HOME}/zsh/history
export HISTSIZE=10000000
export SAVEHIST=10000000

# Autocomplete bits
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit -d ${XDG_CACHE_HOME}/zsh/zcompdump-$ZSH_VERSION
_comp_options+=(globdots)		# Include hidden files.
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
export CASE_SENSITIVE=true

### THE OS-SPECIFIC STUFF ###

case "$OSTYPE" in 

  linux*)
    export SYSLOG=/var/log/syslog
    export PATH=${PATH}:/opt/local/bin
    ;;

  darwin*)
    export SYSLOG=/var/log/system.log 
    export INBOX=${HOME}/Desktop/Inbox
    export OUTBOX=${HOME}/Desktop/Outbox
    export PATH=${PATH}:${HOME}/Scripts
    ;;
    
  openbsd*)
    export SYSLOG=/var/log/messages
    export PATH=${PATH}:/opt/local/bin
    ;;

esac

export PATH=${PATH}:$HOME/.bin

# Use ctrl-l, ctrl-v to paste the output of the last command
zmodload -i zsh/parameter
insert-last-command-output() { 
  LBUFFER+="$(eval $history[$((HISTCMD-1))])" 
}
zle -N insert-last-command-output
bindkey "^l^v" insert-last-command-output

# navigation key bindings
# bindkey -e
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line
bindkey '\e\e[D' backward-word
bindkey '\e\e[C' forward-word

# My other files
for file in path aliases functions prompt; do 
[ -f ${ZDOTDIR}/$file ] && source ${ZDOTDIR}/$file; done
unset file

# Remove duplicates from path
PATH=$(echo "$PATH" | awk -v RS=':' -v ORS=":" '!a[$1]++{if (NR > 1) printf ORS; printf $a[$1]}')
