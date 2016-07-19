#!/bin/bash

set -x


source ./common.sh

checkroot

# Make sure master ip is properly set
if [ -z ${MASTER_IP} ]; then
    echo "MASTER_IP is not set."
	exit 1
fi

installcommon
setEtcHosts
setupFlanneld
setDockertoFlannel
setSELINUX
getLatestk8sVersion


docker run \
    --volume=/:/rootfs:ro \
    --volume=/sys:/sys:rw \
    --volume=/dev:/dev \
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
        --api-servers=http://${MASTER_IP}:8080 \
        --v=2 \
        --address=0.0.0.0 \
        --enable-server \
        --containerized \
        --cluster-dns=10.1.0.10 \
        --cluster-domain=cluster.local
