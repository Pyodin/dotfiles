alias v='vim'
alias t='tmux new -A -s main'
alias k='kubectl'
alias kx='kubectx'
alias kns='kubens'

# /usr/bin/az is a bash wrapper, so `az aks bastion` opens bash; calling python directly makes it open zsh
[[ -x /opt/az/bin/python3 ]] && alias az='AZ_INSTALLER=DEB /opt/az/bin/python3 -Im azure.cli'

alias dotfiles='cd $DOTFILES'
alias aliases='vim $DOTFILES/home/.aliases.zsh'
alias reload='exec zsh'
