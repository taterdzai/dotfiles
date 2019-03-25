#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Aliases

# Use git with bare repository to manage dotfiles
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
if [ -x /usr/bin/dircolors ]; then
    # Colorful ls
    alias ls='ls --color=auto'
    # Colorful grep
    alias grep='grep --color=auto'
fi

# Configuration

# Disable logging repeated commands
export HISTCONTROL=ignoredups
# Append to history
shopt -s histappend
export PROMPT_COMMAND='history -a;history -c;history -r'
# Complete after *comand*
complete -cf sudo
complete -cf man
complete -cf torsocks

# Prompt

# Detect color support
if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    PS1="\[\e[0;32m\]\u";
    PS1+="\[\e[0;36m\]@";
    # Detect remote control
    case $(ps -o comm= -p $PPID) in
        sshd|*/sshd)
            PS1+="\[\e[1;31m\]\h";;
        *)
            PS1+="\[\e[1;33m\]\h";;
    esac
    PS1+="\[\e[0;36m\]: ";
    PS1+="\[\e[0;34m\]\w ";
    # Detect root
    if [ $EUID = 0 ]; then
        PS1+="\[\e[0;36m\]Λ";
    else
        PS1+="\[\e[0;36m\]λ";
    fi
    PS1+="\[\e[0m\] ";
    PS2="\[\e[0;36m\]\ \[\e[0m\]";
else
    PS1="\u@\h:\W\\$ ";
    PS2="\ ";
fi
