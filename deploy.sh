#!/bin/bash

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
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
kubectl get nodes -o wide

# Download istioctl
curl -sL https://istio.io/downloadIstioctl | sh -
export PATH=$PATH:${PWD}/.istioctl/bin

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

