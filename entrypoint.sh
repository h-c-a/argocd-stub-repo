#!/usr/bin/env bash
set -eu

CLUSTER_NAME="${CLUSTER_NAME}"
# Function to wait for a specific resource to be ready
wait_for_resource() {
  local namespace="$1"
  local resource_type="$2"
  local resource_name="$3"
  local condition="$4"
  local timeout="${5:-300}"

  echo "⏳ Waiting for $resource_type/$resource_name in namespace $namespace to meet condition: $condition..."
  kubectl wait --for=condition="${condition}" --timeout="${timeout}s" "${resource_type}" "${resource_name}" -n "${namespace}" || {
    echo "❌ Timed out waiting for $resource_type/$resource_name to become ready."
    exit 1
  }
}

# Wait for the Docker daemon to be ready
echo "⏳ Waiting for Docker daemon to start..."
for i in {1..10}; do
  if docker info >/dev/null 2>&1; then
    echo "✅ Docker is ready!"
    break
  fi
  echo "🚧 Docker not ready yet, retrying... (Attempt $i/10)"
  sleep 2
  if [ "$i" -eq 10 ]; then
    echo "❌ Docker failed to start within the expected time."
    exit 1
  fi
done

KUBECONFIG_PATH="/root/.kube/config"

echo "🔧 === Creating k3d cluster '${CLUSTER_NAME}' ==="
# Create the k3d cluster
k3d cluster create "${CLUSTER_NAME}" \
    --k3s-arg="--disable=traefik@server:0" \
    --api-port 6550 \
    -p "8080:443@loadbalancer" \
    --wait

# Export kubeconfig
echo "🔧 Setting up kubeconfig..."
KUBECONFIG_DIR="/root/.kube"

# Ensure kubeconfig directory exists
mkdir -p "${KUBECONFIG_DIR}"
k3d kubeconfig get "${CLUSTER_NAME}" > "${KUBECONFIG_DIR}/config"
echo 'run "export KUBECONFIG=$(pwd)/kube/config"'

echo "🚀 === Installing Argo CD in the 'argocd' namespace ==="
# Ensure the namespace exists before applying the manifest
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for Argo CD server deployment to be available
wait_for_resource "argocd" "deployment" "argocd-server" "available"

# Patch the Argo CD server service to LoadBalancer
echo "🔧 === Patching Argo CD server service to type=LoadBalancer ==="
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Wait for the LoadBalancer to get an external IP (or hostname)
echo "⏳ Waiting for LoadBalancer to become ready..."
timeout=300  # 5-minute timeout
elapsed=0
while ! kubectl get svc argocd-server -n argocd -o jsonpath="{.status.loadBalancer.ingress}" | grep -q 'hostname\|ip'; do
  if [ "$elapsed" -ge "$timeout" ]; then
    echo "❌ Timed out waiting for Argo CD LoadBalancer to be ready."
    exit 1
  fi
  echo "🚧 Argo CD LoadBalancer not ready yet..."
  sleep 3
  elapsed=$((elapsed + 3))
done

# Retrieve the initial admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "🎉 Argo CD deployed successfully!"
echo "🌐 Access it at: https://localhost:8080"
echo "👤 Login username: admin"
echo "🔑 Initial admin password: ${ARGOCD_PASSWORD}"

# Log in via Argo CD CLI
echo "🔐 Logging into Argo CD CLI..."
argocd login localhost:8080 \
  --username "admin" \
  --password "${ARGOCD_PASSWORD}" \
  --insecure

echo "✅ Kubeconfig written to ${KUBECONFIG_DIR}/config"
echo "🔗 To use kubectl with this cluster, run:"
echo "    export KUBECONFIG=${KUBECONFIG_DIR}/config"
echo "🌐 Verify your cluster by running:"
echo "    kubectl cluster-info"

echo "✅ Setup complete."

# If additional arguments are provided, execute them
if [ $# -gt 0 ]; then
    echo "🚀 Executing provided command: $@"
    exec "$@"
else
    # Check if we're in local development environment (defaults to false)
    if [ "${RUN_LOCAL:-false}" = "true" ]; then
        # Keep the container running for local development
        echo "✅ Setup complete. Running in local environment, keeping container alive..."
        exec tail -f /dev/null
    else
        # Default to CI behavior - exit after completion
        echo "✅ Setup complete. Exiting..."
        exit 0
    fi
fi