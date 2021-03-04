#!/bin/bash

sudo apt-get remove -y docker docker-engine docker.io containerd runc
sudo apt-get update -y

sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg

sudo rm /usr/share/keyrings/docker-archive-keyring.gpg
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Download and install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.10.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Set up kind cluster
kind create cluster --wait 5m

# show clusters
kind get clusters

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version --client
kubectl get nodes -o wide

# Download istioctl
curl -sL https://istio.io/downloadIstioctl | sh -
export PATH=$PATH:$HOME/.istioctl/bin

# Deploy the operator in istio-operator ns
# -i istio-system
# --revision Target control plane revision for the command. (default ``)
# --tag The tag for the operator controller image. (default `unknown`)
istioctl operator init

# Install istio
kubectl create ns istio-system
kubectl apply -f benchmarkoperator.yaml

# Enable istio injection for default ns
kubectl label namespace default istio-injection=enabled


# Prometheus
kubectl create ns istio-prometheus
kubectl apply -f prometheus.yaml
# Grafana
kubectl apply -f grafana.yaml
#Jaeger
kubectl apply -f jaeger.yaml
# Kiali (Apply twice to avoid a race issue)
kubectl apply -f kiali.yaml
kubectl apply -f kiali.yaml


# VirtualServices for the above services
kubectl apply -f virtualservices.yaml

