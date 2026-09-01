#!/usr/bin/env bash
# Bootstrap an Ubuntu machine: install tools, symlink dotfiles. Safe to re-run.
set -euo pipefail

DOTFILES="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
CUSTOM="$HOME/.oh-my-zsh/custom"

PLUGINS="
romkatv/powerlevel10k|themes/powerlevel10k
zsh-users/zsh-autosuggestions|plugins/zsh-autosuggestions
MichaelAquilina/zsh-you-should-use|plugins/you-should-use
zdharma-continuum/fast-syntax-highlighting|plugins/fast-syntax-highlighting
marlonrichert/zsh-autocomplete|plugins/zsh-autocomplete
"

link_only=0
skip_packages=0
for arg in "$@"; do
  case $arg in
    --link-only)     link_only=1 ;;
    --skip-packages) skip_packages=1 ;;
    -h|--help) echo "usage: install.sh [--link-only] [--skip-packages]"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

SUDO=""
[ "$(id -u)" -eq 0 ] || SUDO=sudo

step() { printf '\n\033[1m%s\033[0m\n' "$*"; }
log()  { printf '  %s\n' "$*"; }

packages() {
  (( skip_packages )) && { log "skipped"; return; }
  if SUDO="$SUDO" bash -e "$DOTFILES/packages.sh"; then
    log "done"
  else
    log "packages.sh failed (exit $?), continuing"
  fi
}

oh_my_zsh() {
  [ -d "$HOME/.oh-my-zsh/.git" ] && { log "already installed"; return; }
  git clone --depth 1 -q https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
  log "installed"
}

plugins() {
  local repo dir name
  while IFS='|' read -r repo dir; do
    [ -n "$repo" ] || continue
    name="${dir##*/}"
    dir="$CUSTOM/$dir"
    if [ -d "$dir/.git" ]; then
      git -C "$dir" pull --ff-only -q 2>/dev/null && log "$name updated" || log "$name kept"
    else
      git clone --depth 1 -q "https://github.com/$repo.git" "$dir"
      log "$name cloned"
    fi
  done <<< "$PLUGINS"
}

link() {
  local src name dest
  for src in "$DOTFILES"/home/.[!.]*; do
    [ -e "$src" ] || continue
    name="${src##*/}"
    dest="$HOME/$name"
    if [ "$(readlink -f "$dest")" = "$src" ]; then
      log "$name ok"
    else
      if [ -e "$dest" ] || [ -L "$dest" ]; then
        mkdir -p "$BACKUP"
        mv "$dest" "$BACKUP/"
        log "$name backed up"
      fi
      ln -s "$src" "$dest"
      log "$name linked"
    fi
  done
}

git_identity() {
  local file="$HOME/.gitconfig.local" name="" email=""
  [ -f "$file" ] && { log "already set"; return; }
  read -rp "  git user.name : " name || true
  read -rp "  git user.email: " email || true
  printf '[user]\n\tname = %s\n\temail = %s\n' "$name" "$email" > "$file"
  log "wrote $file"
}

default_shell() {
  local zsh
  zsh=$(command -v zsh) || { log "zsh not installed"; return; }
  [ "${SHELL:-}" = "$zsh" ] && { log "already zsh"; return; }
  chsh -s "$zsh" 2>/dev/null && log "set to zsh" || log "failed, run: chsh -s $zsh"
}

if (( link_only )); then
  step "Dotfiles"; link
else
  step "Packages";      packages
  step "oh-my-zsh";     oh_my_zsh
  step "Plugins";       plugins
  step "Dotfiles";      link
  step "Git identity";  git_identity
  step "Default shell"; default_shell
fi

step "Done"
[ -d "$BACKUP" ] && log "replaced files kept in $BACKUP"
log "start a new shell, or: exec zsh"
