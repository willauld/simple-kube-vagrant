#!/bin/bash

INTERNAL_IP=$1
CONTROLLER_IP=$3
echo INTERNAL_IP = $INTERNAL_IP, CONTROLLER_IP = $CONTROLLER_IP

if [ $2 == "0" ]; then
  NODE="USER"
elif [ $2 == "1" ]; then
  NODE="MASTER"
else
  NODE="WORKER"
fi
echo NODE        = $NODE

sudo systemctl stop firewalld
sudo systemctl disable firewalld

sudo yum -y install ntp
sudo systemctl start ntpd
sudo systemctl enable ntpd

if [ $NODE == "USER" ]; then
  
  cd /vagrant
  echo Provisioning the USER at `pwd`

  if ! [ -f kubectl ]; then
    wget https://storage.googleapis.com/kubernetes-release/release/v1.4.0/bin/linux/amd64/kubectl
    chmod +x kubectl
  fi
  sudo cp kubectl /usr/bin/

  sudo yum -y install mysql

elif [ $NODE == "MASTER" ]; then
  echo Provisioning the MASTER at `pwd`

  sudo yum -y install etcd kubernetes
  
  # Edit in place w/sed /etc/etcd/etcd.conf to ensure we have these values; 
  #ETCD_NAME=default
  #ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
  #ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
  #ETCD_ADVERTISE_CLIENT_URLS="http://localhost:2379"

  sudo sed -i \
    -e s/.*ETCD_NAME=.*$/ETCD_NAME=default/g \
    -e s%.*ETCD_DATA_DIR=.*$%ETCD_DATA_DIR=\"/var/lib/etcd/default.etcd\"%g \
    -e s%.*ETCD_LISTEN_CLIENT_URLS=.*$%ETCD_LISTEN_CLIENT_URLS=\"http://0.0.0.0:2379\"%g \
    -e s%.*ETCD_ADVERTISE_CLIENT_URLS=.*$%ETCD_ADVERTISE_CLIENT_URLS=\"http://localhost:2379\"%g \
    /etc/etcd/etcd.conf 

  # Edit with sed /etc/kubernetes/apiserver to ensure we have these values
  #KUBE_API_ADDRESS="--address=0.0.0.0"
  #KUBE_API_PORT="--port=8080"
  #KUBELET_PORT="--kubelet_port=10250"
  #KUBE_ETCD_SERVERS="--etcd_servers=http://127.0.0.1:2379"
  #KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.254.0.0/16"
  #KUBE_ADMISSION_CONTROL="--admission_control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ResourceQuota"
  #KUBE_API_ARGS="--bind-address=$INTERNAL_IP"

  sudo sed -i \
    -e s/.*KUBE_API_ADDRESS=.*$/KUBE_API_ADDRESS=\"--address=0.0.0.0\"/g \
    -e s/.*KUBE_API_PORT=.*$/KUBE_API_PORT=\"--port=8080\"/g \
    -e s%.*KUBELET_PORT=.*$%KUBELET_PORT=\"--kubelet_port=10250\"%g \
    -e s%.*KUBE_ETCD_SERVERS=.*$%KUBE_ETCD_SERVERS=\"--etcd_servers=http://127.0.0.1:2379\"%g \
    -e s%.*KUBE_SERVICE_ADDRESSES=.*$%KUBE_SERVICE_ADDRESSES=\"--service-cluster-ip-range=10.254.0.0/16\"%g \
    -e s%.*KUBE_ADMISSION_CONTROL=.*$%KUBE_ADMISSION_CONTROL=\"--admission_control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ResourceQuota\"%g \
    -e s%.*KUBE_API_ARGS=.*$%KUBE_API_ARGS=\"--bind-address=$INTERNAL_IP\"%g \
    /etc/kubernetes/apiserver 

  for SERVICES in etcd kube-apiserver kube-controller-manager kube-scheduler; do
    sudo systemctl daemon-reload
    sudo systemctl restart $SERVICES
    sudo systemctl enable $SERVICES
    sudo systemctl status $SERVICES 
  done

  etcdctl mk /atomic.io/network/config '{"Network":"172.17.0.0/16"}'

  kubectl get nodes

else # not MASTER or USER

  echo Provisioning a WORKER at `pwd`

  sudo yum -y install flannel kubernetes

  # EDIT w/sed /etc/sysconfig/flanneld to ensure we have:
  #FLANNEL_ETCD_ENDPOINTS="http://$CONTROLLER_IP:2379"

  sudo sed -i \
    -e s%.*FLANNEL_ETCD_ENDPOINTS=.*$%FLANNEL_ETCD_ENDPOINTS=\"http://$CONTROLLER_IP:2379\"%g \
    /etc/sysconfig/flanneld #### > fl.conf

  # EDIT w/sed /etc/kubernetes/config to ensure we have:
  #KUBE_MASTER="--master=http://$CONTROLLER_IP:8080"

  sudo sed -i \
    -e s%.*KUBE_MASTER=.*$%KUBE_MASTER=\"--master=http://$CONTROLLER_IP:8080\"%g \
    /etc/kubernetes/config #### > kube.conf

  # EDIT w/sed /etc/kubernetes/kubelet to ensure we have:
  #KUBELET_ADDRESS="--address=0.0.0.0"
  #KUBELET_PORT="--port=10250"
  # change the hostname to this host’s IP address
  #KUBELET_HOSTNAME="--hostname_override=$INTERNAL_IP"
  #KUBELET_API_SERVER="--api_servers=http://$CONTROLLER_IP:8080"
  #KUBELET_ARGS=""

  sudo sed -i \
    -e s%.*KUBELET_ADDRESS=.*$%KUBELET_ADDRESS=\"--address=0.0.0.0\"%g \
    -e s%.*KUBELET_PORT=.*$%KUBELET_PORT=\"--port=10250\"%g \
    -e s%.*KUBELET_HOSTNAME=.*$%KUBELET_HOSTNAME=\"--hostname_override=$INTERNAL_IP\"%g \
    -e s%.*KUBELET_API_SERVER=.*$%KUBELET_API_SERVER=\"--api_servers=http://$CONTROLLER_IP:8080\"%g \
    -e s%.*KUBELET_ARGS=.*$%KUBELET_ARGS=\"\"%g \
    /etc/kubernetes/kubelet ####> kubelet.conf

  for SERVICES in kube-proxy kubelet docker flanneld; do
    sudo systemctl daemon-reload
    sudo systemctl restart $SERVICES
    sudo systemctl enable $SERVICES
    sudo systemctl status $SERVICES 
  done

  ip a | grep flannel | grep inet

fi

