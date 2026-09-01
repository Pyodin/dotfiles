#!/usr/bin/env bash
# Bootstrap an Ubuntu machine: install tools, symlink dotfiles. Safe to re-run.
set -euo pipefail

DOTFILES="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
CUSTOM="$HOME/.oh-my-zsh/custom"

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

apt_packages() {
  (( skip_packages )) && { log "skipped"; return; }
  $SUDO apt-get update -qq
  if grep -v '^#' "$DOTFILES/apt.txt" | xargs $SUDO apt-get install -y -qq; then
    log "done"
  else
    log "apt failed, continuing"
  fi
}

custom_packages() {
  (( skip_packages )) && { log "skipped"; return; }
  if SUDO="$SUDO" bash -e "$DOTFILES/custom.sh"; then
    log "done"
  else
    log "custom.sh failed, continuing"
  fi
}

oh_my_zsh() {
  [ -d "$HOME/.oh-my-zsh/.git" ] && { log "already installed"; return; }
  git clone --depth 1 -q https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
  log "installed"
}

clone_or_update() {
  local url=$1 dir=$2 name=${2##*/}
  if [ -d "$dir/.git" ]; then
    git -C "$dir" pull --ff-only -q 2>/dev/null && log "$name updated" || log "$name kept"
  else
    git clone --depth 1 -q "$url" "$dir" </dev/null
    log "$name cloned"
  fi
}

theme() {
  clone_or_update https://github.com/romkatv/powerlevel10k "$CUSTOM/themes/powerlevel10k"
}

plugins() {
  local name url
  while read -r name url; do
    [ -n "$url" ] || continue
    clone_or_update "$url" "$CUSTOM/plugins/$name"
  done < "$DOTFILES/plugins.txt"
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
  step "Apt packages";    apt_packages
  step "Custom packages"; custom_packages
  step "oh-my-zsh";       oh_my_zsh
  step "Theme";           theme
  step "Plugins";         plugins
  step "Dotfiles";        link
  step "Git identity";    git_identity
  step "Default shell";   default_shell
fi

step "Done"
[ -d "$BACKUP" ] && log "replaced files kept in $BACKUP"
log "start a new shell, or: exec zsh"
