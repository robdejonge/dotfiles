### THE COMMON STUFF ###

# Get operating system
unamestr=$(uname)
PLATFORM=${unamestr:l} 
unset unamestr

# Some 


# Configure zsh 
setopt AUTO_CD    # enabled changing directories without typing 'cd' command
autoload -U colors && colors

# Set history parameters
setopt HIST_SAVE_NO_DUPS
setopt inc_append_history
setopt share_history
HISTFILE=${ZCACHEDIR}/history
export HISTSIZE=10000000
export SAVEHIST=10000000

# Basic auto/tab complete
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit -d ${ZCACHEDIR}/zcompdump-$ZSH_VERSION
_comp_options+=(globdots)		# Include hidden files.
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Load other bits and pieces if they exist
for file in aliases prompt functions; do 
[ -f ${ZDOTDIR}/$file ] && source ${ZDOTDIR}/$file; done
unset file

### THE OS-SPECIFIC STUFF ###

case "$PLATFORM" in 

  linux)
    export SYSLOG=/var/log/syslog
    ;;

  darwin)
    export SYSLOG=/var/log/system.log 
    export INBOX=${HOME}/Desktop/Inbox
    export OUTBOX=${HOME}/Desktop/Outbox
    export PATH=${PATH}:${HOME}/Scripts
    ;;

esac

# Use Ctrl-x,Ctrl-l to get the output of the last command
zmodload -i zsh/parameter
insert-last-command-output() {
LBUFFER+="$(eval $history[$((HISTCMD-1))])"
}
zle -N insert-last-command-output
bindkey "^L^V" insert-last-command-output

# navigation key bindings
bindkey -e
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line
bindkey '\e\e[D' backward-word
bindkey '\e\e[C' forward-word

# remove duplicates from path
PATH=$(echo "$PATH" | awk -v RS=':' -v ORS=":" '!a[$1]++{if (NR > 1) printf ORS; printf $a[$1]}')
