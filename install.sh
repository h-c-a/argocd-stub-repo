#!/usr/bin/env bash
set -eu

# Install k3d (latest or pin a specific version)
echo "🚀 === Installing k3d ==="
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Install kubectl using stable version
echo "🛠️ === Installing kubectl ==="
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
echo "📦 Using kubectl version: ${KUBECTL_VERSION}"
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

# Install Argo CD CLI
echo "📦 === Installing Argo CD CLI ==="
ARGOCD_VERSION="v2.7.3"
echo "📦 Using Argo CD version: ${ARGOCD_VERSION}"
curl -sSL -o /usr/local/bin/argocd \
    "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-amd64"
chmod +x /usr/local/bin/argocd

# Verify installations
echo "🔍 === Verifying installations ==="
echo "k3d version: $(k3d version)"
echo "kubectl version: $(kubectl version --client -o json | jq -r '.clientVersion.gitVersion')"
echo "argocd version: $(argocd version --client | grep 'argocd: ' | cut -d ' ' -f2)"

echo "✅ === Successfully installed all tools ==="
