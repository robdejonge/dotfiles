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

# Use ctrl-l, ctrl-v to paste the output of the last command
zmodload -i zsh/parameter
insert-last-command-output() { 
  LBUFFER+="$(eval $history[$((HISTCMD-1))])" 
}
zle -N insert-last-command-output
bindkey "^l^v" insert-last-command-output

# Navigation key bindings to edit the commandline 
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line
bindkey '\e\e[D' backward-word
bindkey '\e\e[C' forward-word

# Set the terminal window title bar
function set_terminal_title_preexec() {
    print -Pn "\e]0;%n@%m: $1\a"
}

function set_terminal_title_precmd() {
    print -Pn "\e]0;%n@%m: %~\a"
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec set_terminal_title_preexec
add-zsh-hook precmd set_terminal_title_precmd

# Load my other files
for file in functions aliases path prompt; do 
[ -f ${ZDOTDIR}/$file ] && source ${ZDOTDIR}/$file; done
unset file

# Cleanup
deduplicate-path

# Check if dotfiles need updating
dotfiles-check
