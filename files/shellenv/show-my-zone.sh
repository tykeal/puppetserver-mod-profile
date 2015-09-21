case "${HOSTNAME#*.}" in
  int.*)
    export PS1='[\u@\h\[\e[0;33m\].int\[\e[0;0m\] \W]\$ '
  ;;
  dmz.*)
    export PS1='[\u@\h\[\e[0;33m\].dmz\[\e[0;0m\] \W]\$ '
  ;;
  web.*)
    export PS1='[\u@\h\[\e[0;33m\].web\[\e[0;0m\] \W]\$ '
  ;;
  ci.*)
    export PS1='[\u@\h\[\e[0;33m\].ci\[\e[0;0m\] \W]\$ '
  ;;
  fe.*)
    export PS1='[\u@\h\[\e[0;33m\].fe\[\e[0;0m\] \W]\$ '
  ;;
esac

