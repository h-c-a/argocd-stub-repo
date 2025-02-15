#!/bin/sh
set -e

# Start Docker daemon
dockerd &
sleep 5

# Create k3d cluster
k3d cluster create test-cluster --wait

# Configure kubectl
mkdir -p /root/.kube
k3d kubeconfig get test-cluster > /root/.kube/config

# Get nodes
kubectl get nodes

exec "$@" 