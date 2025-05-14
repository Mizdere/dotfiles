#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Colorful output
alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Prompt
PS1='[\u@\h \W]\$ '

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

if [[ $TERM == "xterm-kitty" ]]; then
  fastfetch --gpu-hide-type integrated
fi

alias fastfetch='fastfetch --gpu-hide-type integrated'
