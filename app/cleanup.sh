#!/bin/sh

terraform destroy -state=kubernetes.tfstate -auto-approve

rm 06-encryption/encryption-config.yaml

rm 05-kubeconfig/*.kubeconfig

rm 04-certs/*.pem
rm 04-certs/*.csr

