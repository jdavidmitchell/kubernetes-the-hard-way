#!/bin/sh

kubectl create -f 12-coredns/core-dns.yml

kubectl get pods -l k8s-app=kube-dns -n kube-system
