# latestkube

This repo has scripts that bring up latest multi-node k8s on docker.
So the docs of k8s when running k8s entirely on docker, they run everything from docker, so this causes problems and does not play well with interfaces. What this does differently is install etcd and flannel directly via package and configure them before and then bring up k8s in docker container. This is done because, required packages for running those services are available.

This script assumes that vagrant is installed. That's the only pre-requisite.

So I created this script which will bring up master, node1 and node2, if you wish you can add more nodes to the Vagrantfile.

Steps:

Clone this repo and bring up machines

```bash
$ git clone https://github.com/surajssd/latestkube
$ cd latestkube
$ vagrant up
```

On master:

```
$ vagrant ssh master
[vagrant@master ~]$ sudo -i
[root@master ~]# cd /vagrant/scripts/
[root@master scripts]# sh ./master.sh
```


On other nodes:
```
$ vagrant ssh node1
[vagrant@master ~]$ sudo -i
```

Get IP address of `master` from other machine.
```
[root@master ~]# export MASTER_IP=192.168.121.144
[root@master ~]# cd /vagrant/scripts/
[root@master scripts]# sh ./node.sh
```


Ref:

- Run a single node k8s on docker http://kubernetes.io/docs/getting-started-guides/docker/
- Run a multi-node k8s master on docker https://github.com/kubernetes/kubernetes.github.io/blob/master/docs/getting-started-guides/docker-multinode/master.md
- Run a multi-node k8s node on docker https://github.com/kubernetes/kubernetes.github.io/blob/master/docs/getting-started-guides/docker-multinode/worker.md
- Setting up flannel https://deshmukhsuraj.wordpress.com/2016/02/29/flannel-demo/
- SELINUX issue with k8s in docker https://deshmukhsuraj.wordpress.com/2016/06/01/running-kubernetes-in-container-on-fedoracentos/
