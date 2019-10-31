#!/bin/sh

ROUTE_TABLE_ID=$(aws ec2 describe-route-tables \
    --filters "Name=tag:Name,Values=kubernetes" \
    --output text --query 'RouteTables[].RouteTableId')
echo "kubernetes route-table-id is ${ROUTE_TABLE_ID}"

for instance in worker-0 worker-1 worker-2; do
  instance_id_ip="$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}" "Name=instance-state-name,Values=running" \
    --output text --query 'Reservations[].Instances[].[InstanceId,PrivateIpAddress]')"
  instance_id="$(echo "${instance_id_ip}" | cut -f1)"
  instance_ip="$(echo "${instance_id_ip}" | cut -f2)"
  pod_cidr="$(aws ec2 describe-instance-attribute \
    --instance-id "${instance_id}" \
    --attribute userData \
    --output text --query 'UserData.Value' \
    | base64 -d | tr "|" "\n" | grep "^pod-cidr" | cut -d'=' -f2)"
  echo "${instance} ip is: ${instance_ip}; cidr is: ${pod_cidr}"

  aws ec2 create-route \
    --route-table-id "${ROUTE_TABLE_ID}" \
    --destination-cidr-block "${pod_cidr}" \
    --instance-id "${instance_id}"
done

aws ec2 describe-route-tables \
  --route-table-ids "${ROUTE_TABLE_ID}" \
  --query 'RouteTables[].Routes'

