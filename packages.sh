#!/usr/bin/env bash
# What to install. Runs under `bash -e`; $SUDO is set by install.sh.

$SUDO apt-get update -qq
$SUDO apt-get install -y zsh git tmux vim curl

# Not in the Ubuntu repos:

if ! command -v k9s >/dev/null; then
  curl -fsSL https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz |
    tar -xz -C /tmp k9s
  $SUDO install -m 755 /tmp/k9s /usr/local/bin/k9s
  rm -f /tmp/k9s
fi

if ! command -v az >/dev/null; then
  curl -fsSL https://aka.ms/InstallAzureCLIDeb | $SUDO bash
fi
