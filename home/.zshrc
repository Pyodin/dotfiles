# p10k instant prompt, must stay at the top
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export DOTFILES="$HOME/dotfiles"
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# first word of each line
plugins=(${${(f)"$(<$DOTFILES/plugins.txt)"}%% *})

# must come before oh-my-zsh.sh, see README
fpath=("$ZSH/custom/plugins/zsh-autocomplete/Completions" $fpath)
source "$ZSH/oh-my-zsh.sh"

# zsh-autocomplete hijacks Ctrl+R, give it back to the classic search
bindkey "^R" .history-incremental-search-backward

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
source ~/.aliases.zsh
typeset -U path
export PATH="$HOME/.local/bin:$PATH"
