FROM python:2.7-alpine

ENV CFSSL_VERSION=R1.2 \
    TERRAFORM_VERSION=0.12.10 \
    KUBE_VERSION=v1.15.4

ENV TERRAFORM_FILE=terraform_${TERRAFORM_VERSION}_linux_amd64.zip

RUN apk update && \
    apk add bash curl wget git openssh-client gcc make musl-dev libffi-dev openssl-dev groff jq less && \
    curl -o /usr/local/bin/cfssl https://pkg.cfssl.org/$CFSSL_VERSION/cfssl_linux-amd64 && \
    curl -o /usr/local/bin/cfssljson https://pkg.cfssl.org/$CFSSL_VERSION/cfssljson_linux-amd64 && \
    curl -o /root/$TERRAFORM_FILE https://releases.hashicorp.com/terraform/$TERRAFORM_VERSION/$TERRAFORM_FILE && \
    curl -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$KUBE_VERSION/bin/linux/amd64/kubectl && \
    curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "/root/awscli-bundle.zip"

WORKDIR /root

RUN unzip $TERRAFORM_FILE && \
    mv terraform /usr/local/bin && \
    rm $TERRAFORM_FILE && \
    unzip /root/awscli-bundle.zip && \
    /root/awscli-bundle/install -b /usr/local/bin/aws && \
    mkdir /root/.aws && \
    rm /root/awscli-bundle.zip && \
    chmod +x /usr/local/bin/cfssl* /usr/local/bin/kubectl && \
    pip2 install ansible

ADD profile /root/.bashrc
ADD ansible.cfg /root/.ansible.cfg
ADD .aws/credentials /root/.aws/credentials
ADD .aws/config /root/.aws/config
ADD .ssh/aws_compute_engine /root/.ssh/aws_compute_engine
ADD .ssh/aws_compute_engine.pub /root/.ssh/aws_compute_engine.pub

WORKDIR /root/app

ENTRYPOINT [ "/bin/bash" ]

