#!/bin/bash

echo "START"
cd /root/portworx-setup/kubespray

cat > wait_for_ssh.yml <<EOF
---
- name: wait for connection to new VMs
  hosts: all
  tasks:
  - name: Wait for ssh
    wait_for:
      port: 22
      host: '{{ (ansible_ssh_host|default(ansible_host))|default(inventory_hostname) }}'
      search_regex: OpenSSH
      delay: 10
    connection: local
EOF

echo "waiting for SSH come up on the VMs"
until ansible-playbook -i inventory/testdrivecluster/hosts.yaml wait_for_ssh.yml
do
  echo "waiting, then trying again"
  sleep 10
done

#Restart NTP on VM/lab resume
ansible all -i inventory/testdrivecluster/hosts.yaml -m shell -b -a "systemctl restart chronyd"
#ansible all -i inventory/testdrivecluster/hosts.yaml -m shell -b -a "systemctl restart portworx"

rm wait_for_ssh.yml

# Grafana pod should be restarted to fix transport errors on lab resumes/ntp reboot
export KUBECONFIG=/root/portworx-setup/kubespray/inventory/testdrivecluster/artifacts/admin.conf
#kubectl label nodes node2 node3 node4 px/service=restart
kubectl delete po -n kube-system -l name=portworx --wait=false
# Stork, CSI, Grafana dont like px or NTP reboot, so we let them restart
kubectl delete po -n central -l app=pxcentral-grafana --wait=false
kubectl delete po -n kube-system -l name=stork --wait=false
kubectl delete po -n kube-system -l app=px-csi-driver --wait=false

# Refresh the app to make sure no old cache is used.
cd /home/portworx/testdrive-workspace/example
kubectl create -f postgres-db.yaml
sleep 3
kubectl create -f k8s-webapp.yaml

echo "Ran resume operation script to sync ntp, $(date)" >> /root/portworx-setup/resume-op.log

echo "FINISH"
