#!/bin/bash -e

#cp /home/portworx/admin.conf $HOME/.kube/config

while true; do
    NUM_READY=`kubectl get nodes 2> /dev/null | grep -v NAME | awk '{print $2}' | grep -e ^Ready | wc -l`
    if [ "${NUM_READY}" == "4" ]; then
        echo "All ${NUM_READY} Kubernetes nodes are ready !"
        break
    else
        echo "Waiting for Kubernetes nodes to be ready. Current ready nodes: ${NUM_READY}"
    fi
    sleep 5
done

while true; do
    NUM_READY=`kubectl get pods -n kube-system -l name=portworx -o wide | grep Running | grep 2/2 | wc -l`
    if [ "${NUM_READY}" == "3" ]; then
        echo "All portworx nodes are ready !"
        break
    else
        echo "Waiting for portworx nodes to be ready. Current ready nodes: ${NUM_READY}"
    fi
    sleep 5
done


while true; do
    NUM_READY=`kubectl get po -n central -l app=grafana -o wide | grep Running | grep 1/1 | wc -l`
    if [ "${NUM_READY}" == "1" ]; then
        echo "All portworx monitoring nodes are ready !"
        break
    else
        echo "Waiting for portworx monitoring nodes to be ready. Current ready nodes: ${NUM_READY}"
    fi
    sleep 5
done

while true; do
    NUM_READY=`kubectl get po -l app=postgres -o wide | grep Running | grep 1/1 | wc -l`
    if [ "${NUM_READY}" == "1" ]; then
        echo "Demo Application is ready !"
        break
    else
        echo "Waiting for Demo Application to be deployed."
    fi
    sleep 45
done

echo ""
echo "Your lab is ready, please proceed..."
