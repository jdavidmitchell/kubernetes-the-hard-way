#!/bin/bash
for instance in controller-0 controller-1 controller-2; do
  external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')
  scp -i ssh/kubernetes.id_rsa cfg/admin.kubeconfig cfg/kube-controller-manager.kubeconfig cfg/kube-scheduler.kubeconfig \
    ubuntu@${external_ip}:~/
done
