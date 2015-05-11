# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Domain alias
if [ "${HOSTNAME#*.}" = "linux-foundation.org" ]; then
    PS1="[\u@\[\e[1;34m\]lf\[\e[1;30m\]-\[\e[0m\]\h \W]\\$ "
elif [ "${HOSTNAME#*.}" = "linux.com" ]; then
    PS1="[\u@\[\e[1;33m\]lcom\[\e[1;30m\]-\[\e[0m\]\h \W]\\$ "
elif [ "${HOSTNAME#*.}" = "cvo.opendaylight.org" ]; then
    PS1="[\u@\[\e[1;31m\]odl-cvo\[\e[1;30m\]-\[\e[0m\]\h \W]\\$ "
elif [ "${HOSTNAME#*.}" = "dfw.opendaylight.org" ]; then
    PS1="[\u@\[\e[1;31m\]odl-dfw\[\e[1;30m\]-\[\e[0m\]\h \W]\\$ "
elif [ "${HOSTNAME#*.}" = "dfw.odlforge.org" ]; then
    PS1="[\u@\[\e[1;31m\]odlf-dfw\[\e[1;30m\]-\[\e[0m\]\h \W]\\$ "
fi

# User specific aliases and functions
alias vi=vim
