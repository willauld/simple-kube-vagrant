#!/bin/bash

cd ~

set +x

kubectl get nodes

mkdir -p pods
cd pods

cp /vagrant/mysql_pod.yaml mysql.yaml

kubectl create -f mysql.yaml

kubectl get pods

cp /vagrant/mysql-service.yaml mysql-service.yaml

####
#### Need to modify the IP in the above yaml file
####
POD_NODE_IP=`kubectl describe pod mysql | grep Node | awk -F "/" '{ print $2 }'`
sed -i s/POD_NODE_IP/$POD_NODE_IP/  mysql-service.yaml

kubectl create -f mysql-service.yaml

kubectl get services


