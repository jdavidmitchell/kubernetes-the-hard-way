#!/bin/sh

# The ssh public key was copied to /root/.ssh in the DockerFile
PUBLICKEY=/root/.ssh/aws_compute_engine.pub

if [ ! -e "${PWD}/03-provisioning/.terraform" ] 
then
  echo "### terraform init ..."
  terraform init 03-provisioning
  echo
fi

if [ -e "${PWD}/kubernetes.tfstate" ]
then
  echo "### moving kubernetes.tfstate to k8s.tfstate"
  mv ${PWD}/kubernetes.tfstate ${PWD}/k8s.tfstate
  echo
fi

terraform apply -auto-approve -var region="${AWS_REGION}" -var pubkey="${PUBLICKEY}" -state="kubernetes.tfstate" 03-provisioning

#read varname

cd /root/app/04-certs
./gen-certs.sh

cd /root/app/05-kubeconfig
./gen-conf.sh

cd /root/app/06-encryption
./gen-encrypt.sh

cd /root/app
00-ansible/create-inventory.sh

ansible-playbook -i inventory.cfg 07-etcd/etcd-playbook.yml

ansible-playbook -i inventory.cfg 08-kube-controller/kube-controller-playbook.yml
ansible-playbook -i inventory.cfg 08-kube-controller/rbac-playbook.yml
ansible-playbook -i inventory.cfg 08-kube-controller/http-health-checks.yml

ansible-playbook -i inventory.cfg 09-kubelet/kubelet-playbook.yml

./10-kubectl/setup-kubectl.sh

./11-network/network-conf.sh

./12-coredns/setup-coredns.sh
