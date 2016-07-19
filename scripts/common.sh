#!/bin/bash

set -x


function checkroot () {
	# Run as root
	if [ "$(id -u)" != "0" ]; then
    	echo >&2 "Please run as root"
	    exit 1
	fi
}

function installcommon () {
	# Install requirements
	echo 'fastestmirror=1' | tee -a /etc/dnf/dnf.conf
	dnf -y update
	dnf -y install docker git wget flannel
}

function setEtcHosts () {
	# Set master's IP in /etc/hosts
	echo "${MASTER_IP} master" | tee -a /etc/hosts
	# in fedora on vagrant localhost and 127.0.0.1 are not mapped so this thing
	echo "127.0.0.1 localhost" | tee -a /etc/hosts
}

function setupFlanneld () {
	echo "
FLANNEL_ETCD=\"http://${MASTER_IP}:2379\"
FLANNEL_ETCD_KEY=\"/mycluster/network/\"
FLANNEL_OPTIONS=\"--iface=eth0\"
	" > /etc/sysconfig/flanneld

	systemctl enable --now flanneld && systemctl status flanneld

}

function setDockertoFlannel () {

# set up docker to use flannel
# here extra things added are
# EnvironmentFile=-/run/flannel/subnet.env
# --bip=${FLANNEL_SUBNET} \
# --mtu=${FLANNEL_MTU} \
# and the default docker network options are removed
# EnvironmentFile=-/etc/sysconfig/docker-network
#  $DOCKER_NETWORK_OPTIONS \
#  $INSECURE_REGISTRY \

	echo "
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.com
After=network.target
Wants=docker-storage-setup.service

[Service]
Type=notify
NotifyAccess=all
EnvironmentFile=-/run/flannel/subnet.env
EnvironmentFile=-/etc/sysconfig/docker
EnvironmentFile=-/etc/sysconfig/docker-storage
Environment=GOTRACEBACK=crash
ExecStart=/bin/sh -c '/usr/bin/docker daemon \
          --exec-opt native.cgroupdriver=systemd \
          \$OPTIONS \
          \$DOCKER_STORAGE_OPTIONS \
      --bip=\${FLANNEL_SUBNET} \
      --mtu=\${FLANNEL_MTU} \
          2>&1 | /usr/bin/forward-journald -tag docker'
ExecReload=/bin/kill -s HUP \$MAINPID
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity
MountFlags=slave
StandardOutput=null
StandardError=null
TimeoutStartSec=0
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
	" > /usr/lib/systemd/system/docker.service

	systemctl daemon-reload && systemctl restart docker

}

function setSELINUX () {
	# set up folders for kubernetes with SELINUX permissions
	# for more info read: https://deshmukhsuraj.wordpress.com/2016/06/01/running-kubernetes-in-container-on-fedoracentos/
	mkdir -p /var/lib/kubelet/
	chcon -R -t svirt_sandbox_file_t /var/lib/kubelet/
	chcon -R -t svirt_sandbox_file_t /var/lib/docker/
}

function getLatestk8sVersion () {
	# get latest version of k8s
	# taken from: http://kubernetes.io/docs/getting-started-guides/docker/
	export K8S_VERSION=$(curl -sS https://storage.googleapis.com/kubernetes-release/release/latest.txt)
}

function getStablek8sVersion () {
	export K8S_VERSION=$(curl -sS https://storage.googleapis.com/kubernetes-release/release/stable.txt)
}

function downloadkubectl () {
	# download the kubectl
	# taken from: http://kubernetes.io/docs/getting-started-guides/docker/
	curl -sSL "http://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/kubectl" > /usr/bin/kubectl
	chmod +x /usr/bin/kubectl
}
