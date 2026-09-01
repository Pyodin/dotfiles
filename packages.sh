#!/usr/bin/env bash
#
# Everything this machine needs. Plain shell - edit freely, add lines.
# Run by install.sh with `bash -e`, so the first failing command stops the file.
# $SUDO is set for you (empty if you are already root).

$SUDO apt-get update -qq

# Anything available in the Ubuntu repos goes on this line.
$SUDO apt-get install -y zsh git tmux vim curl


# --- Tools that are not in the Ubuntu repos ---------------------------------
# Each block is guarded so re-running install.sh is cheap.

# k9s - Kubernetes TUI, published as a GitHub release.
if ! command -v k9s >/dev/null 2>&1; then
  k9s_url="https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz"
  curl -fsSL "$k9s_url" | tar -xz -C /tmp k9s \
    && $SUDO install -m 755 /tmp/k9s /usr/local/bin/k9s \
    && rm -f /tmp/k9s
fi

# azure-cli - needs Microsoft's apt repository, which their script adds.
if ! command -v az >/dev/null 2>&1; then
  curl -fsSL https://aka.ms/InstallAzureCLIDeb | $SUDO bash
fi

# docker is NOT installed here: on WSL it comes from Docker Desktop on the
# Windows side (/usr/bin/docker is a symlink into /mnt/wsl/docker-desktop/).
# Enable it in Docker Desktop > Settings > Resources > WSL integration.
