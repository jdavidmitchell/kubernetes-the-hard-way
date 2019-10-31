#!/bin/sh

KUBERNETES_PUBLIC_ADDRESS=$(aws elbv2 describe-load-balancers \
  --names 'kubernetes' \
  --output text --query 'LoadBalancers[].DNSName')
echo "Kubernetes public address: ${KUBERNETES_PUBLIC_ADDRESS}"

kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=./04-certs/ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443

kubectl config set-credentials admin \
  --client-certificate=./04-certs/admin.pem \
  --client-key=./04-certs/admin-key.pem

kubectl config set-context kubernetes-the-hard-way \
  --cluster=kubernetes-the-hard-way \
  --user=admin

kubectl config use-context kubernetes-the-hard-way

kubectl get componentstatuses
