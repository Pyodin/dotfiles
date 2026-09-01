#!/usr/bin/env bash
#
# Bootstrap a machine: install core tools, then symlink dotfiles into $HOME.
# Safe to re-run; every step is idempotent.
#
#   ./install.sh                 install packages, plugins, and link dotfiles
#   ./install.sh --link-only     only (re)create the symlinks
#   ./install.sh --skip-packages skip the package manager step
#   ./install.sh --help

set -euo pipefail

DOTFILES="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$ZSH_DIR/custom"

SKIP_PACKAGES=0
LINK_ONLY=0

# ---------------------------------------------------------------- output ----
if [ -t 1 ]; then
  BOLD=$'\033[1m'; RED=$'\033[31m'; GREEN=$'\033[32m'
  YELLOW=$'\033[33m'; BLUE=$'\033[34m'; RESET=$'\033[0m'
else
  BOLD=; RED=; GREEN=; YELLOW=; BLUE=; RESET=
fi

info()  { printf '%s==>%s %s\n'  "$BLUE$BOLD" "$RESET" "$*"; }
ok()    { printf '  %s+%s %s\n'  "$GREEN" "$RESET" "$*"; }
skip()  { printf '  %s=%s %s\n'  "$YELLOW" "$RESET" "$*"; }
warn()  { printf '  %s!%s %s\n'  "$YELLOW" "$RESET" "$*" >&2; }
die()   { printf '%serror:%s %s\n' "$RED$BOLD" "$RESET" "$*" >&2; exit 1; }

usage() { sed -n '2,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0; }

while [ $# -gt 0 ]; do
  case "$1" in
    --skip-packages) SKIP_PACKAGES=1 ;;
    --link-only)     LINK_ONLY=1 ;;
    -h|--help)       usage ;;
    *)               die "unknown option: $1 (try --help)" ;;
  esac
  shift
done

# -------------------------------------------------------------- platform ----
OS="$(uname -s)"
PKG=""
IS_WSL=0

grep -qi microsoft /proc/version 2>/dev/null && IS_WSL=1

detect_platform() {
  case "$OS" in
    Linux)
      if   command -v apt-get >/dev/null 2>&1; then PKG=apt
      elif command -v dnf     >/dev/null 2>&1; then PKG=dnf
      elif command -v pacman  >/dev/null 2>&1; then PKG=pacman
      elif command -v zypper  >/dev/null 2>&1; then PKG=zypper
      fi
      ;;
    Darwin)
      command -v brew >/dev/null 2>&1 && PKG=brew
      ;;
  esac

  local label="$OS"
  [ "$IS_WSL" -eq 1 ] && label="$OS (WSL)"
  info "Platform: $label, package manager: ${PKG:-none found}"
}

# --------------------------------------------------------------- packages ---
# Core only: a working shell, multiplexer, editor, and the tools needed to
# fetch everything else.
PACKAGES_COMMON="zsh git tmux vim curl"

install_packages() {
  if [ "$SKIP_PACKAGES" -eq 1 ]; then
    skip "package install (--skip-packages)"
    return
  fi

  info "Installing core packages"

  if [ -z "$PKG" ]; then
    warn "no supported package manager found; install these yourself:"
    warn "  $PACKAGES_COMMON"
    return
  fi

  # Only sudo when we are not already root.
  local SUDO=""
  if [ "$(id -u)" -ne 0 ]; then
    command -v sudo >/dev/null 2>&1 && SUDO=sudo \
      || die "need root or sudo to install packages (or use --skip-packages)"
  fi

  case "$PKG" in
    apt)
      $SUDO apt-get update -qq
      # shellcheck disable=SC2086
      $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $PACKAGES_COMMON
      ;;
    dnf)    $SUDO dnf install -y $PACKAGES_COMMON ;;
    pacman) $SUDO pacman -Sy --needed --noconfirm $PACKAGES_COMMON ;;
    zypper) $SUDO zypper --non-interactive install $PACKAGES_COMMON ;;
    brew)   brew install $PACKAGES_COMMON ;;
  esac
  ok "core packages present"
}

# ------------------------------------------------------------ oh-my-zsh -----
install_oh_my_zsh() {
  info "Setting up oh-my-zsh"
  if [ -d "$ZSH_DIR/.git" ]; then
    skip "oh-my-zsh already installed"
    return
  fi
  if [ -e "$ZSH_DIR" ]; then
    die "$ZSH_DIR exists but is not a git checkout; move it aside and re-run"
  fi
  git clone --depth 1 -q https://github.com/ohmyzsh/ohmyzsh.git "$ZSH_DIR"
  ok "oh-my-zsh installed"
}

# Each entry: <git url>|<destination directory>
# The p10k theme and the four plugins referenced by .zshrc.
REPOS="
https://github.com/romkatv/powerlevel10k.git|$ZSH_CUSTOM/themes/powerlevel10k
https://github.com/zsh-users/zsh-autosuggestions.git|$ZSH_CUSTOM/plugins/zsh-autosuggestions
https://github.com/MichaelAquilina/zsh-you-should-use.git|$ZSH_CUSTOM/plugins/you-should-use
https://github.com/zdharma-continuum/fast-syntax-highlighting.git|$ZSH_CUSTOM/plugins/fast-syntax-highlighting
https://github.com/marlonrichert/zsh-autocomplete.git|$ZSH_CUSTOM/plugins/zsh-autocomplete
"

install_zsh_plugins() {
  info "Setting up zsh theme and plugins"
  local url dest name entry
  while IFS='|' read -r url dest; do
    [ -n "${url:-}" ] || continue
    name="$(basename "$dest")"
    if [ -d "$dest/.git" ]; then
      # Already there: try to update, but never fail the whole install for it.
      if git -C "$dest" pull --ff-only -q 2>/dev/null; then
        ok "$name (updated)"
      else
        skip "$name (present; could not fast-forward, left as is)"
      fi
    else
      mkdir -p "$(dirname "$dest")"
      git clone --depth 1 -q "$url" "$dest"
      ok "$name (cloned)"
    fi
  done <<< "$(printf '%s\n' "$REPOS" | sed '/^[[:space:]]*$/d')"
}

# ----------------------------------------------------------------- links ----
# Back up whatever is in the way, then point it at the repo.
link_one() {
  local src="$1" dest="$2"

  if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
    skip "$(basename "$dest") already linked"
    return
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$BACKUP_DIR"
    mv "$dest" "$BACKUP_DIR/"
    warn "$(basename "$dest") existed -> backed up to $BACKUP_DIR/"
  fi

  ln -s "$src" "$dest"
  ok "$(basename "$dest") -> $src"
}

link_dotfiles() {
  info "Linking dotfiles into $HOME"
  local src
  # Dotfiles live in home/ and map 1:1 onto $HOME.
  for src in "$DOTFILES"/home/.[!.]*; do
    [ -e "$src" ] || continue
    link_one "$src" "$HOME/$(basename "$src")"
  done
}

# ------------------------------------------------------- local git identity --
# Kept out of the repo so the repo stays shareable.
setup_git_identity() {
  info "Git identity"
  local target="$HOME/.gitconfig.local"

  if [ -f "$target" ]; then
    skip "~/.gitconfig.local already exists"
    return
  fi

  local name="" email=""
  if [ -t 0 ]; then
    printf '  git user.name : '  ; read -r name
    printf '  git user.email: '  ; read -r email
  fi

  if [ -z "$name" ] || [ -z "$email" ]; then
    cat > "$target" <<'TEMPLATE'
# Fill these in, then run: git config --global --list
[user]
	name =
	email =
TEMPLATE
    warn "wrote a template to $target - fill in name and email"
  else
    cat > "$target" <<IDENTITY
[user]
	name = $name
	email = $email
IDENTITY
    ok "wrote $target"
  fi
}

# ----------------------------------------------------------- default shell --
set_default_shell() {
  info "Default shell"
  local zsh_path
  zsh_path="$(command -v zsh 2>/dev/null || true)"

  [ -n "$zsh_path" ] || { warn "zsh not installed; skipping"; return; }

  if [ "${SHELL:-}" = "$zsh_path" ]; then
    skip "already zsh"
    return
  fi

  # /etc/shells must list it or chsh refuses.
  if [ -w /etc/shells ] || grep -qxF "$zsh_path" /etc/shells 2>/dev/null; then
    :
  else
    warn "$zsh_path missing from /etc/shells; you may need to add it"
  fi

  if chsh -s "$zsh_path" 2>/dev/null; then
    ok "default shell set to zsh (takes effect on next login)"
  else
    warn "could not change shell automatically; run: chsh -s $zsh_path"
  fi
}

# ------------------------------------------------------------------ main ----
main() {
  info "Dotfiles: $DOTFILES"
  detect_platform

  if [ "$LINK_ONLY" -eq 1 ]; then
    link_dotfiles
  else
    install_packages
    install_oh_my_zsh
    install_zsh_plugins
    link_dotfiles
    setup_git_identity
    set_default_shell
  fi

  printf '\n%sDone.%s ' "$GREEN$BOLD" "$RESET"
  if [ -d "$BACKUP_DIR" ]; then
    printf 'Replaced files are in %s\n' "$BACKUP_DIR"
  else
    printf 'Nothing needed backing up.\n'
  fi
  printf 'Start a new shell, or run: %sexec zsh%s\n' "$BOLD" "$RESET"
}

main
