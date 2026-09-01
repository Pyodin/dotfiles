# dotfiles

My shell environment, reproducible on a new machine with one command.

## Setup on a new machine

```sh
git clone https://github.com/<you>/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
exec zsh
```

That installs the core packages, oh-my-zsh with the theme and plugins, and
symlinks everything in `home/` into `$HOME`.

## Layout

```
packages.sh     what to install - edit this to add tools
home/           files symlinked into $HOME (1:1, by filename)
  .zshrc
  .p10k.zsh     powerlevel10k prompt config
  .tmux.conf
  .gitconfig    shared git settings; identity is NOT here (see below)
install.sh      the bootstrap script
```

Targets Ubuntu.

## Adding a tool

Edit `packages.sh`. Most things are one word on the apt line:

```sh
$SUDO apt-get install -y zsh git tmux vim curl ripgrep fzf jq
```

Anything not in the Ubuntu repos gets its own guarded block lower down in the
same file - `k9s` (GitHub release) and `azure-cli` (Microsoft apt repo) are
already there as working examples. Wrap new ones in a
`if ! command -v <tool>` check so re-running stays cheap.

`packages.sh` runs under `bash -e`, so the first failing command stops the file
and `install.sh` reports it. Your dotfiles still get linked either way.

## What install.sh does

1. **Runs `packages.sh`** to install your tools.
2. **Installs oh-my-zsh** and clones the theme and plugins that `.zshrc` expects:
   powerlevel10k, zsh-autosuggestions, you-should-use, fast-syntax-highlighting,
   zsh-autocomplete.
3. **Symlinks** every `home/.*` file into `$HOME`. Anything already in the way is
   moved to `~/.dotfiles-backup/<timestamp>/` first — it never overwrites.
4. **Writes `~/.gitconfig.local`** with your name and email (prompts for them).
5. **Sets zsh as the default shell** via `chsh`.

Every step is idempotent — re-run it any time to pull plugin updates and repair
links.

```sh
./install.sh --link-only       # just redo the symlinks
./install.sh --skip-packages   # skip packages.sh
./install.sh --help
```

## Secrets stay out of this repo

Git identity lives in `~/.gitconfig.local`, which `home/.gitconfig` pulls in via
`[include]` and `.gitignore` excludes. Credential directories — `~/.aws`,
`~/.azure`, `~/.kube`, `~/.config/k9s` — are deliberately not tracked. Keep it
that way if you ever push this publicly.

## Not installed by this repo

`docker` on WSL comes from Docker Desktop on the Windows side — `/usr/bin/docker`
is a symlink into `/mnt/wsl/docker-desktop/`. Enable it in Docker Desktop →
Settings → Resources → WSL integration. Same for `npm` and `code`, which resolve
to Windows binaries through `/mnt/c`.

## Adding a dotfile

Move the real file in and re-link:

```sh
mv ~/.vimrc ~/dotfiles/home/.vimrc
./install.sh --link-only
git add home/.vimrc && git commit -m "Add .vimrc"
```

Because the files are symlinked, editing `~/.zshrc` edits the repo directly —
`git status` in `~/dotfiles` always shows your real configuration drift.

## Notes on the zsh setup

`.zshrc` seeds `$fpath` with zsh-autocomplete's `Completions/` directory *before*
sourcing `oh-my-zsh.sh`. This is load-bearing: oh-my-zsh runs `compinit` before it
sources plugin files, so without it zsh-autocomplete's completion functions are
never registered and every completion raises
`command not found: _autocomplete__unambiguous`.

Plugin order matters too. `fast-syntax-highlighting` wraps every ZLE widget at
load time, so it comes after the plugins it should highlight — but *before*
`zsh-autocomplete`, which pre-declares placeholder widgets it only defines lazily;
wrapping those produces `unhandled ZLE widget` warnings.

`~/.oh-my-zsh` and the plugin clones are managed by `install.sh`, not tracked here.
