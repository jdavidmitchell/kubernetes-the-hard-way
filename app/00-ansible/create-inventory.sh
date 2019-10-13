#!/bin/sh

echo "[all]" > inventory.cfg
for instance in worker-0 worker-1 worker-2; do   external_ip=$(aws ec2 describe-instances \
     --filters "Name=tag:Name,Values=${instance}" \
     --output text --query 'Reservations[].Instances[].PublicIpAddress'); echo ${external_ip} >> inventory.cfg ; done
for instance in controller-0 controller-1 controller-2; do   external_ip=$(aws ec2 describe-instances \
     --filters "Name=tag:Name,Values=${instance}" \
     --output text --query 'Reservations[].Instances[].PublicIpAddress'); echo ${external_ip} >> inventory.cfg ; done
echo "[workers]" >> inventory.cfg
for instance in worker-0 worker-1 worker-2; do   external_ip=$(aws ec2 describe-instances \
     --filters "Name=tag:Name,Values=${instance}" \
     --output text --query 'Reservations[].Instances[].PublicIpAddress'); echo ${external_ip} >> inventory.cfg ; done
echo "[controllers]" >> inventory.cfg
for instance in controller-0 controller-1 controller-2; do   external_ip=$(aws ec2 describe-instances \
     --filters "Name=tag:Name,Values=${instance}" \
     --output text --query 'Reservations[].Instances[].PublicIpAddress'); echo ${external_ip} >> inventory.cfg ; done
echo "[controller-0]" >> inventory.cfg
external_ip=$(aws ec2 describe-instances \
     --filters "Name=tag:Name,Values=controller-0" \
     --output text --query 'Reservations[].Instances[].PublicIpAddress'); echo ${external_ip} >> inventory.cfg
echo "[all:vars]" >> inventory.cfg
echo "ansible_python_interpreter=/usr/bin/python3" >> inventory.cfg

