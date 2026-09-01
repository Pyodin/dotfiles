# dotfiles

My shell profile — zsh, oh-my-zsh, powerlevel10k, tmux, git, kubectl — on any Ubuntu machine.

```sh
git clone https://github.com/<you>/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
exec zsh
```

The repo must live at `~/dotfiles`: `.zshrc` reads `plugins.txt` from there.

## Layout

```
install.sh    the bootstrap
apt.txt       apt packages, one per line
custom.sh     everything not in the Ubuntu repos (curl installs, etc.)
plugins.txt   oh-my-zsh plugins, in load order; a URL after the name means "clone it"
home/         symlinked into $HOME (.zshrc, .aliases.zsh, .p10k.zsh, .tmux.conf, .gitconfig)
```

`install.sh` installs `apt.txt`, runs `custom.sh`, installs oh-my-zsh, powerlevel10k
and the plugins in `plugins.txt`, symlinks `home/*` into `$HOME`, asks for your git
identity, and sets zsh as the login shell. Re-run it any time — it updates plugins
and repairs links. Anything it would overwrite goes to `~/.dotfiles-backup/<timestamp>/` first.

```sh
./install.sh --link-only       # just redo the symlinks
./install.sh --skip-packages   # skip apt.txt and custom.sh
```

## Adding things

An apt package: add a line to `apt.txt`.

Anything else: add a guarded block to `custom.sh` — `kubectl`, `k9s` and `azure-cli` are there as examples.

A plugin: add a line to `plugins.txt`, then `./install.sh --skip-packages`. Plugins
bundled with oh-my-zsh (`git`, `kubectl`, …) need only the name. Others need the git
URL, and the name must match the `*.plugin.zsh` file inside that repo.

An alias: edit `home/.aliases.zsh` (or run `aliases`).

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

`fast-syntax-highlighting` is listed before `zsh-autocomplete` in `plugins.txt`,
because it wraps every ZLE widget at load time and zsh-autocomplete pre-declares
placeholder widgets it only defines lazily.
