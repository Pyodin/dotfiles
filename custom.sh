#!/usr/bin/env bash
# Tools not in the Ubuntu repos. Runs under `bash -e`; $SUDO comes from install.sh.

# on WSL the Windows PATH is appended, so only count tools that resolve to a Linux path
have() { case "$(type -P "$1")" in ''|/mnt/*) return 1 ;; esac; }

ARCH=$(dpkg --print-architecture)

# az, Azure CLI
if ! have az; then
  curl -fsSL https://aka.ms/InstallAzureCLIDeb | $SUDO bash
fi

# kubectl and kubelogin, via az
if [ ! -x ~/.local/bin/kubectl ] || [ ! -x ~/.local/bin/kubelogin ]; then
  /usr/bin/az aks install-cli \
    --install-location ~/.local/bin/kubectl \
    --kubelogin-install-location ~/.local/bin/kubelogin
fi

# k9s, Kubernetes TUI
if ! have k9s; then
  curl -fsSL "https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_$ARCH.tar.gz" |
    tar -xz -C /tmp k9s
  $SUDO install -m 755 /tmp/k9s /usr/local/bin/k9s
  rm -f /tmp/k9s
fi

# flux, GitOps CLI
if ! have flux; then
  curl -fsSL https://fluxcd.io/install.sh | $SUDO bash
fi

# win32yank, clipboard bridge for tmux right-click paste under WSL
if [ ! -x ~/.local/bin/win32yank.exe ]; then
  curl -fsSL -o /tmp/win32yank.zip \
    https://github.com/equalsraf/win32yank/releases/download/v0.1.1/win32yank-x64.zip
  unzip -o -q /tmp/win32yank.zip -d /tmp win32yank.exe
  install -m 755 /tmp/win32yank.exe ~/.local/bin/win32yank.exe
  rm -f /tmp/win32yank.zip /tmp/win32yank.exe
fi
