#!/usr/bin/env bash
# Everything that has to exist on a cluster before an application can deploy.
# Run once per cluster, after terraform apply.
set -euo pipefail

ENV="${1:?usage: bootstrap-cluster.sh <staging|prod>}"
cd "$(dirname "$0")/.."

CLUSTER=$(terraform -chdir="envs/$ENV" output -raw cluster_name)
REGION=$(terraform -chdir="envs/$ENV" output -raw region 2>/dev/null || echo eu-central-1)
OIDC_ARN=$(terraform -chdir="envs/$ENV" output -raw oidc_provider_arn)

echo "==> kubeconfig for $CLUSTER"
aws eks update-kubeconfig --name "$CLUSTER" --region "$REGION"

echo "==> ingress-nginx"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"=nlb \
  --set controller.metrics.enabled=true \
  --wait

echo "==> cert-manager"
helm repo add jetstack https://charts.jetstack.io >/dev/null
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set crds.enabled=true \
  --wait

echo "==> cluster-autoscaler"
# Discovers node groups by tag rather than being told about them, so adding a
# group in Terraform needs no change here.
helm repo add autoscaler https://kubernetes.github.io/autoscaler >/dev/null
helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName="$CLUSTER" \
  --set awsRegion="$REGION" \
  --set extraArgs.balance-similar-node-groups=true \
  --set extraArgs.skip-nodes-with-system-pods=false \
  --wait

echo "==> done. oidc provider: $OIDC_ARN"
kubectl get nodes -o wide
