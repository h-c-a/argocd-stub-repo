# Kubernetes Configuration Management

This repository contains both Helm charts and Kustomize configurations for managing Kubernetes applications. It demonstrates two popular approaches to Kubernetes configuration management, allowing teams to choose the most appropriate tool for their use case.

## Repository Structure 

- `helm/`: Contains Helm charts for deploying applications.
- `kustomize/`: Contains Kustomize configurations for deploying applications.
- `argocd/`: Contains ArgoCD configurations for deploying applications.
- `examples/`: Contains examples of how to use the Helm and Kustomize configurations.

## Configuration Approaches

### Helm

- Template-based approach
- Good for complex applications
- Built-in package management
- Supports rollbacks
- Values-based configuration

### Kustomize

- Template-free approach
- Patch-based customization
- Native Kubernetes support
- Overlay-based configuration
- Simpler learning curve

## Prerequisites

- Kubernetes cluster (v1.16+)
- ArgoCD installed
- kubectl configured
- Helm (v3+) for Helm deployments
- Kustomize (v4+) for Kustomize deployments
- Nginx Ingress Controller
- (Optional) cert-manager for SSL/TLS

## Helm Deployment

1. Navigate to the Helm directory: 
2. Run `helm install hello-world-staging ./hello-world --namespace hello-world --create-namespace`
3. Run `helm install hello-world-production ./hello-world --namespace hello-world --create-namespace`

## Kustomize Deployment

1. Navigate to the Kustomize directory: 
2. Run `kustomize build overlays/staging | kubectl apply -f -`
3. Run `kustomize build overlays/production | kubectl apply -f -`
4. Run `kubectl get deployments -n hello-world` to verify the deployments were created.

## ArgoCD Deployment

1. Navigate to the ArgoCD directory: 
2. Run `argocd app create hello-world-staging --repo https://github.com/your-git-repo-url.git --path helm/hello-world --dest-server https://kubernetes.default.svc --dest-namespace hello-world --sync-policy automated --self-heal --create-namespace`
3. Run `argocd app create hello-world-production --repo https://github.com/your-git-repo-url.git --path helm/hello-world --dest-server https://kubernetes.default.svc --dest-namespace hello-world --sync-policy automated --self-heal --create-namespace`
