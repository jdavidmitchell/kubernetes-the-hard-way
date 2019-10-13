#!/bin/sh

terraform destroy -state=”kubernetes.tfstate” -auto-approve 03-provisioning/

#destroy web firewall
#terraform destroy 11-network

rm 07-etcd/*.retry

rm 06-encryption/encryption-config.yaml

rm 05-kubeconfig/*.kubeconfig

rm 04-certs/*.pem
rm 04-certs/*.csr

