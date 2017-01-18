#!/bin/bash

echo Configuring kubectl for remote access to kubernetes cluster

KUBERNETES_IP="192.168.50.131"

kubectl config set-cluster kubernetes \
  --server=http://${KUBERNETES_IP}:8080

kubectl config set-credentials kubeuser/kubernetes \
  --username=kubeuser \
  --password=kubepassword

kubectl config set-context default/kubernetes/kubeuser \
  --user=kubeuser/kubernetes \
  --namespace=default \
  --cluster=kubernetes

kubectl config use-context default/kubernetes/kubeuser


####
echo now test to see the kubectl on host can talk to vagrant kubeNode cluster
####

echo kubectl get componentstatuses
kubectl get componentstatuses

echo kubectl get nodes
kubectl get nodes

