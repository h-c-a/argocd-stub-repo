# syntax=docker/dockerfile:1

FROM ubuntu:24.04

ENV TZ=Etc/UTC \
    DEBIAN_FRONTEND=noninteractive \
    CLUSTER_NAME=k3d-test \
    KUBECONFIG=/root/.kube/config \
    RUN_LOCAL=false

# Install necessary packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    iptables \
    openssl \
    curl \
    jq \
    bash \
    wget \
    tzdata \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set timezone
RUN ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && dpkg-reconfigure -f noninteractive tzdata

# Copy Docker binaries
COPY --from=docker:dind /usr/local/bin/ /usr/local/bin/

# Copy and run install script
COPY install.sh /install.sh
RUN chmod +x /install.sh && /install.sh

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"] 