#!/usr/bin/env bash
# Tools not in the Ubuntu repos. Runs under `bash -e`; $SUDO comes from install.sh.

ARCH=$(dpkg --print-architecture)

# az, Azure CLI
if ! command -v az >/dev/null; then
  curl -fsSL https://aka.ms/InstallAzureCLIDeb | $SUDO bash
fi

# kubectl and kubelogin, via az
if [ ! -x ~/.local/bin/kubectl ] || [ ! -x ~/.local/bin/kubelogin ]; then
  az aks install-cli \
    --install-location ~/.local/bin/kubectl \
    --kubelogin-install-location ~/.local/bin/kubelogin
fi

# k9s, Kubernetes TUI
if ! command -v k9s >/dev/null; then
  curl -fsSL "https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_$ARCH.tar.gz" |
    tar -xz -C /tmp k9s
  $SUDO install -m 755 /tmp/k9s /usr/local/bin/k9s
  rm -f /tmp/k9s
fi

# flux, GitOps CLI
if ! command -v flux >/dev/null; then
  curl -fsSL https://fluxcd.io/install.sh | $SUDO bash
fi
