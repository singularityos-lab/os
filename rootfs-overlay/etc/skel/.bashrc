# ~/.bashrc for Singularity user sessions
[ -z "$PS1" ] && return
export PS1='\u@\h:\w\$ '
export EDITOR=nano
alias ls='ls --color=auto'
alias ll='ls -alh'
