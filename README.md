# simple-kube-vagrant

# Simple multi-server Kubernetes implementation using Vagrant

Summary: This project constructs a kubernetes cluster with one controller and one or more worker nodes. It is based closely on [the SeveralNines post](http://severalnines.com/blog/installing-kubernetes-cluster-minions-centos7-manage-pods-services). The networking is still not correct in that, as is, the cluster is not reachable from the outside. See the discussion below for more details.

Current status:
* Single controler running etcd, kube-apiserver, kube-controller-manager and kube-scheduler
* One or more worker nodes running flannel, docker, kubelet, kube-proxy
* Vagrant ``` network: Not quite right, I may be running into a bug here. All servers are connected with a "public_network" with static IP, all servers include the Vagrant NAT interface and the controller server is also getting a "private_network" w/static IP. However, the private network does not seem to be doing its part at all. See below for a more complete discussion. ```
* May still be a bit glitchy, not much testing

Content:
* A Vagrantfile: Gets everything needed and creates provisions (with bash script) and makes available the kubernetes cluster
* A bash script used to provision the cluster, FullScript.sh
* A bash script used to create and start a SQL service, AfterUp.sh
* A bash script used to smoke test the SQL service, ClientDo.sh

Requirements:
* A system with VirtualBox and Vagrant installed.
* 4 GB of RAM
* ? GB of free disk space

Tested on:
* Host system Ubuntu 16.04

How to use:
* Open and read through [the SeveralNines post](http://severalnines.com/blog/installing-kubernetes-cluster-minions-centos7-manage-pods-services) that this code automates to see what is to be done
* Assuming Vagrant and VirtualBox are installed, download the code from the repository
* Go to the directory with the repository and type "vagrant up"
* If all goes well you'll have several vbox VMs running a kubernetes cluster
* "vagrant ssh machine0"
* Then from inside machine0 (this is the controller) type "/vagrant/AfterUp.sh" to create the SQL service
* After the service has had time to come up type "/vagrant/ClientDo.sh" to test the see mySQL working.

Discussion:
My goal is to has several environments where I can explore the kubernetes infrastructure more completely. This project creates a simple environment less complicated than what we would have in a production environment so we can see the individual parts work or not. I put this together after running into networking issues on a more complicated HA cluster but see the same issues here. 

Initial symptom: I used only a vagrant "private_network" with static IPs while developing the provisioning scripts and Vagrantfile. The cluster was reachable (including w/kubectl) from the host. Everything worked as expected until creating the first pod in the kubernetes cluster. At this point the state would remain in "pending" forever with no signs of any trouble orther than there was no forward progress. I changed the vagrant network to "public_network" still with static IPs and the container is created properly. However, all connectivity from the host goes away. 

Because the IPs are on a different subnet (same LAN but using static IPs) than the host it is not accessable from the host. Anyway to regain the host connectivity I added a "private_network" on the controller but this does not seem to function properly. I can see it in machine0 as expected and on the host I see a vboxnet interface but I can't ping machine0 from the host or access it in any way. 