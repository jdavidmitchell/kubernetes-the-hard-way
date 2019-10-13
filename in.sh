#!/bin/sh

if [ ! -e "${PWD}/.ssh/aws_compute_engine" ]
then
  echo "### aws_compute_engine does not exit. Creating ssh public-private key."
  mkdir -p ${PWD}/.ssh
  # ⚠️ Here we create a key with no passphrase
  ssh-keygen -q -P "" -f ${PWD}/.ssh/aws_compute_engine
else 
  echo "### .ssh/aws_compute_engine file exits. Skipping ssh key creation."
fi

if [ ! -e "${PWD}/.aws/credentials" ]
then
  mkdir -p ${PWD}/.aws
  cp ${HOME}/.aws/credentials ${PWD}/.aws/credentials
else
  echo "### .aws/credentials file exits. Skipping the copying of the credentials file from ~/.aws/credentials."
fi

if [ ! -e "${PWD}/.aws/config" ]
then
  mkdir -p ${PWD}/.aws
  cp ${HOME}/.aws/config ${PWD}/.aws/config
else
  echo "### .aws/config file exits. Skipping the copying of the config file from ~/.aws/config."
fi
  
docker build . -t k8s-on-gce/tools

if [ $? -eq 0 ]; then
    docker rm -f k8s-on-aws-tools 
    
    docker run -it \
        -v $PWD/app:/root/app \
        -p 8001:8001 \
        --name k8s-on-aws-tools k8s-on-gce/tools
fi
