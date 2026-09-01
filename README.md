# dotfiles

My shell profile — zsh, oh-my-zsh, powerlevel10k, tmux, git — on any Ubuntu machine.

```sh
git clone https://github.com/<you>/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
exec zsh
```

## Layout

```
packages.sh   what to install
home/         symlinked into $HOME (.zshrc, .p10k.zsh, .tmux.conf, .gitconfig)
install.sh    the bootstrap
```

`install.sh` runs `packages.sh`, installs oh-my-zsh with the theme and plugins
`.zshrc` expects, symlinks `home/*` into `$HOME`, asks for your git identity, and
sets zsh as the login shell. Re-run it any time — it updates plugins and repairs
links. Anything it would overwrite goes to `~/.dotfiles-backup/<timestamp>/` first.

```sh
./install.sh --link-only       # just redo the symlinks
./install.sh --skip-packages   # skip packages.sh
```

## Adding things

A tool: add it to the apt line in `packages.sh`. If it isn't in the Ubuntu repos,
add a guarded block below — `k9s` and `azure-cli` are there as examples.

A dotfile: `mv ~/.vimrc home/.vimrc && ./install.sh --link-only`, then commit it.
The files are symlinks, so editing `~/.zshrc` edits the repo — `git status` here
always shows your real config drift.

## Secrets

Git identity lives in `~/.gitconfig.local`, which `home/.gitconfig` includes and
`.gitignore` excludes. `~/.aws`, `~/.azure`, `~/.kube` and `~/.config/k9s` are not
tracked. Keep it that way if you push this publicly.

## Two load-bearing details in .zshrc

`$fpath` is seeded with zsh-autocomplete's `Completions/` *before* `oh-my-zsh.sh`
is sourced: oh-my-zsh runs `compinit` before sourcing plugins, so without it every
completion fails with `command not found: _autocomplete__unambiguous`.

`fast-syntax-highlighting` is listed before `zsh-autocomplete`, because it wraps
every ZLE widget at load time and zsh-autocomplete pre-declares placeholder
widgets it only defines lazily.
