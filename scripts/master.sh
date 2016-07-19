#!/bin/bash

set -x

source ./common.sh


checkroot

# Make sure master ip is properly set
if [ -z ${MASTER_IP} ]; then
    MASTER_IP=$(hostname -I | awk '{print $1}')
	echo "MASTER_IP is set to: ${MASTER_IP}"
fi

installcommon
dnf -y install etcd

setEtcHosts

# set etcd config
# exposes 2379 and 4001 on all interfaces
echo '
# [member]
ETCD_NAME=default
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379,http://0.0.0.0:4001"

#[cluster]
ETCD_ADVERTISE_CLIENT_URLS="http://0.0.0.0:2379,http://0.0.0.0:4001"
' > /etc/etcd/etcd.conf
systemctl enable --now etcd && systemctl status etcd

# give some time for etcd server to comeup
sleep 10
# set up flannel
# assumes that 10.1.0.0/16 network is not used anywhere
# change it to any network that does not conflict
echo '
{
    "Network":"10.1.0.0/16",
    "SubnetLen": 24,
    "Backend": {
        "Type": "vxlan"
     }
}
' > ~/flannel.json

# here the key is set to "/mycluster/network" you can choose anything
etcdctl set /mycluster/network/config < ~/flannel.json

setupFlanneld
setDockertoFlannel

setSELINUX
getLatestk8sVersion

# taken from https://github.com/kubernetes/kubernetes.github.io/blob/master/docs/getting-started-guides/docker-multinode/master.md#starting-the-kubernetes-master
docker run \
    --volume=/:/rootfs:ro \
    --volume=/sys:/sys:rw \
    --volume=/var/lib/docker/:/var/lib/docker:rw \
    --volume=/var/lib/kubelet/:/var/lib/kubelet:rw \
    --volume=/var/run:/var/run:rw \
    --net=host \
    --privileged=true \
    --pid=host \
    -d \
    gcr.io/google_containers/hyperkube-amd64:${K8S_VERSION} \
    /hyperkube kubelet \
        --allow-privileged=true \
        --api-servers=http://localhost:8080 \
        --v=2 \
        --address=0.0.0.0 \
        --enable-server \
        --hostname-override=127.0.0.1 \
        --config=/etc/kubernetes/manifests-multi \
        --containerized \
        --cluster-dns=10.1.0.10 \
        --cluster-domain=cluster.local

downloadkubectl
