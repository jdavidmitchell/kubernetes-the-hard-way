#!/bin/bash

PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '

# some more ls aliases
alias ll='ls -al'
alias la='ls -A'
alias l='ls -CF'

# Edit the versions below to try different versions.
# Editing the versions below could break the installation, if the versions are not found.
export ETCD_VERSION=v3.4.0
export CNI_VERSION=0.7.1
export CNI_PLUGINS_VERSION=0.8.2
export CONTAINERD_VERSION=1.2.9

# The AWS region to create the cluster
export AWS_REGION="us-west-1"

