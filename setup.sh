#!/bin/bash

echo "--------------- Install Pre-reqs and Kubespray ---------------"
apt-get install sshpass -y
sleep 30
apt-get install curl -y
sleep 30
apt-get install ansible -y
sleep 30
apt-get install python3 -y
sleep 30
apt-get install python-pip -y
sleep 30
pip2 install jinja2
sleep 30
mkdir /root/portworx-setup/
cd /root/portworx-setup/
git clone https://github.com/kubernetes-sigs/kubespray.git
cd kubespray/
pip3 install -r requirements.txt
sleep 30
mkdir /root/portworx-setup/kubespray/inventory/testdrivecluster
cp -rfp inventory/sample/* inventory/testdrivecluster/
wget https://raw.githubusercontent.com/bhavin04890/pxtestdrive/main/hosts.yaml
cp hosts.yaml /root/portworx-setup/kubespray/inventory/testdrivecluster/hosts.yaml
sleep 3
wget https://raw.githubusercontent.com/bhavin04890/pxtestdrive/main/k8s-cluster.yaml
cp k8s-cluster.yaml /root/portworx-setup/kubespray/inventory/testdrivecluster/group_vars/k8s_cluster/k8s-cluster.yaml
sleep 3
wget https://raw.githubusercontent.com/bhavin04890/pxtestdrive/main/all.yaml
cp all.yaml /root/portworx-setup/kubespray/inventory/testdrivecluster/group_vars/all/all.yaml
sleep 3
wget https://raw.githubusercontent.com/bhavin04890/pxtestdrive/main/cluster.yaml
sleep 3
ansible-playbook -i /root/portworx-setup/kubespray/inventory/testdrivecluster/hosts.yaml --become --become-user=root cluster.yaml --extra-vars "ansible_sudo_pass=Password1"
sleep 1080

echo "--------------- Kubernetes Installed ---------------"

snap install kubectl --classic
sleep 30
snap install helm --classic
sleep 30
export PATH=$PATH:/snap/bin
mkdir $HOME/.kube/
cp inventory/testdrivecluster/artifacts/admin.conf $HOME/.kube/config
mkdir /home/portworx/.kube/
cp inventory/testdrivecluster/artifacts/admin.conf /home/portworx/.kube/config
chmod 666 /home/portworx/.kube/config
chown -R portworx:portworx /home/portworx/.kube/
chmod 666 $HOME/.kube/config
chown -R root:root /home/portworx/.kube/

mkdir /home/portworx/testdrive-workspace
mkdir /home/portworx/testdrive-workspace/example
mkdir /home/portworx/testdrive-workspace/testdrive-guide
mkdir /home/portworx/testdrive-workspace/assets

cd /home/portworx/testdrive-workspace/assets

kubectl apply -f 'https://install.portworx.com/2.9?comp=pxoperator'
sleep 10
kubectl apply -f 'https://install.portworx.com/2.9?operator=true&mc=false&kbver=&b=true&s=%2Fdev%2Fsdb&j=auto&c=px-cluster&stork=true&csi=true&tel=false&st=k8s'
sleep 480

echo "--------------- Portworx Enterprise Deployed ---------------"

helm repo add portworx http://charts.portworx.io/ && helm repo update
sleep 10
wget https://raw.githubusercontent.com/bhavin04890/pxtestdrive/main/values-px-central.yaml
helm install px-central portworx/px-central --namespace central --create-namespace --version 2.1.1 -f values-px-central.yaml

sleep 480

echo "--------------- PX-Backup Deployed ---------------"

VER=$(kubectl version --short | awk -Fv '/Server Version: / {print $3}')
kubectl apply -f  "http://install.portworx.com/2.9/?comp=prometheus-operator&kbver=$VER"
sleep 30

wget https://raw.githubusercontent.com/bhavin04890/pxtestdrive/main/service-monitor.yaml
kubectl apply -f service-monitor.yaml
sleep 30

wget https://raw.githubusercontent.com/bhavin04890/pxtestdrive/main/alertmanager.yaml
kubectl create secret generic alertmanager-portworx --from-file=alertmanager.yaml -n central
sleep 30

wget https://raw.githubusercontent.com/bhavin04890/pxtestdrive/main/alertmanager-cluster.yaml
kubectl apply -f alertmanager-cluster.yaml
sleep 30

wget https://raw.githubusercontent.com/bhavin04890/pxtestdrive/main/alertmanager-service.yaml
kubectl apply -f alertmanager-service.yaml
sleep 30

wget https://raw.githubusercontent.com/bhavin04890/pxtestdrive/main/prometheus-rules.yaml
kubectl apply -f prometheus-rules.yaml
sleep 30

wget https://raw.githubusercontent.com/bhavin04890/pxtestdrive/main/prometheus-cluster.yaml
kubectl apply -f prometheus-cluster.yaml
sleep 30

wget https://raw.githubusercontent.com/bhavin04890/pxtestdrive/main/grafana-dashboard-config.yaml
kubectl -n central create configmap grafana-dashboard-config --from-file=grafana-dashboard-config.yaml
sleep 30

wget https://raw.githubusercontent.com/bhavin04890/pxtestdrive/main/grafana-datasource.yaml
kubectl -n central create configmap grafana-source-config --from-file=grafana-datasource.yaml
sleep 30

curl "https://docs.portworx.com/samples/k8s/pxc/portworx-cluster-dashboard.json" -o portworx-cluster-dashboard.json && \
curl "https://docs.portworx.com/samples/k8s/pxc/portworx-node-dashboard.json" -o portworx-node-dashboard.json && \
curl "https://docs.portworx.com/samples/k8s/pxc/portworx-volume-dashboard.json" -o portworx-volume-dashboard.json && \
curl "https://docs.portworx.com/samples/k8s/pxc/portworx-etcd-dashboard.json" -o portworx-etcd-dashboard.json && \
kubectl -n central create configmap grafana-dashboards --from-file=portworx-cluster-dashboard.json --from-file=portworx-node-dashboard.json --from-file=portworx-volume-dashboard.json --from-file=portworx-etcd-dashboard.json
sleep 30

wget https://raw.githubusercontent.com/bhavin04890/pxtestdrive/main/grafana.yaml
kubectl apply -f grafana.yaml
sleep 30

echo "--------------- Monitoring Installed ---------------"
