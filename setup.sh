#!/bin/bash
set -e

KUBECTL=kubectl

kind create cluster --name=bensheim
kubectx kind-bensheim

kubectl create namespace upbound-system
helm install uxp --namespace upbound-system upbound-stable/universal-crossplane --version 1.15.0-up.1 --wait
kubectl -n upbound-system wait deploy crossplane --for condition=Available --timeout=60s

cat <<EOF | kubectl apply -f -
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws-s3
spec:
  package: xpkg.upbound.io/upbound/provider-aws-s3:v1.2.0
EOF

echo "Waiting until all installed provider packages are healthy..."
kubectl wait provider.pkg --all --for condition=Healthy --timeout 5m

echo "Creating cloud credential secret..."
kubectl -n upbound-system create secret generic aws-creds --from-literal=credentials="${CREDENTIALS}" \
    --dry-run=client -o yaml | kubectl apply -f -

echo "Creating a default provider config..."
cat <<EOF | kubectl apply -f -
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    secretRef:
      key: credentials
      name: aws-creds
      namespace: upbound-system
    source: Secret
EOF
