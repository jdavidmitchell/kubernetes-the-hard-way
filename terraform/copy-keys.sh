#!/bin/bash
for instance in controller-0 controller-1 controller-2; do
  external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')
  scp -i ssh/kubernetes.id_rsa tls/ca.pem tls/ca-key.pem tls/kubernetes-key.pem tls/kubernetes.pem \
    tls/service-account-key.pem tls/service-account.pem \
    cfg/encryption-config.yaml \
    ubuntu@${external_ip}:~/
done
