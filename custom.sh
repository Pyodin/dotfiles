#!/usr/bin/env bash
# Tools not in the Ubuntu repos. Runs under `bash -e`; $SUDO comes from install.sh.

ARCH=$(dpkg --print-architecture)

if ! command -v kubectl >/dev/null; then
  VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
  curl -fsSL "https://dl.k8s.io/release/$VERSION/bin/linux/$ARCH/kubectl" -o /tmp/kubectl
  $SUDO install -m 755 /tmp/kubectl /usr/local/bin/kubectl
  rm -f /tmp/kubectl
fi

if ! command -v k9s >/dev/null; then
  curl -fsSL "https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_$ARCH.tar.gz" |
    tar -xz -C /tmp k9s
  $SUDO install -m 755 /tmp/k9s /usr/local/bin/k9s
  rm -f /tmp/k9s
fi

if ! command -v az >/dev/null; then
  curl -fsSL https://aka.ms/InstallAzureCLIDeb | $SUDO bash
fi
