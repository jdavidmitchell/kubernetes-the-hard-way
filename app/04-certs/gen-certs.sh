#!/bin/sh

echo "Generating CA certificate..."
cfssl gencert -initca ca-csr.json | cfssljson -bare ca

if [ ! -f ca-key.pem ]||[ ! -f ca.pem ]; then
    echo "Error creating CA certificates"
    exit -1
fi

echo "Generating admin certificate..."
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json | cfssljson -bare admin

if [ ! -f admin-key.pem ]||[ ! -f admin.pem ]; then
    echo "Error creating admin certificate"
    exit -1
fi

echo "Generating worker certificates..."
for i in 0 1 2; do
  instance="worker-${i}"
  instance_hostname="ip-10-240-0-2${i}"
  cat > ${instance}-csr.json <<EOF
{
  "CN": "system:node:${instance_hostname}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:nodes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

  external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  internal_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" \
    --output text --query 'Reservations[].Instances[].PrivateIpAddress')

  cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -hostname=${instance_hostname},${external_ip},${internal_ip} \
    -profile=kubernetes \
    worker-${i}-csr.json | cfssljson -bare worker-${i}
done

echo "Generating controler-manager certificate..."
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

if [ ! -f kube-controller-manager-key.pem ]||[ ! -f kube-controller-manager.pem ]; then
    echo "Error creating kube-controller-manager certificates"
    exit -1
fi

echo "Generating kube-proxy certificate..."
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy

if [ ! -f kube-proxy-key.pem ]||[ ! -f kube-proxy.pem ]; then
    echo "Error creating kube-proxy certificates"
    exit -1
fi

echo "Generating scheduler certificate..."
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-scheduler-csr.json | cfssljson -bare kube-scheduler

if [ ! -f kube-scheduler-key.pem ]||[ ! -f kube-scheduler.pem ]; then
    echo "Error creating kube-scheduler certificates"
    exit -1
fi

#LOAD_BALANCER_ARN=$(aws elbv2 describe-load-balancers \
#  --names 'kubernetes' --output text --query 'LoadBalancers[].LoadBalancerArn')
#KUBERNETES_PUBLIC_ADDRESS=$(aws elbv2 describe-load-balancers \
#  --load-balancer-arns ${LOAD_BALANCER_ARN} \
#  --output text --query 'LoadBalancers[].DNSName')
KUBERNETES_PUBLIC_ADDRESS=$(aws elbv2 describe-load-balancers \
  --names 'kubernetes' \
  --output text --query 'LoadBalancers[].DNSName')

echo "Generating kubernetes certificate..."
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=10.32.0.1,10.240.0.10,10.240.0.11,10.240.0.12,${KUBERNETES_PUBLIC_ADDRESS},127.0.0.1,kubernetes.default \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

if [ ! -f kubernetes-key.pem ]||[ ! -f kubernetes.pem ]; then
    echo "Error creating kubernetes certificates"
    exit -1
fi

echo "Generating service account certificate..."
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  service-account-csr.json | cfssljson -bare service-account

if [ ! -f service-account-key.pem ]||[ ! -f service-account.pem ]; then
    echo "Error creating service-account certificates"
    exit -1
fi

