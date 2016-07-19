# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|

  config.vm.provider "libvirt" do |libvirt, override|
    libvirt.driver = "kvm"
    libvirt.memory = 4096
    libvirt.cpus = 4
  end

  config.vm.define "master" do |master|
    master.vm.box = "fedora/23-cloud-base"
    config.vm.hostname = "master"
  end

  config.vm.define "node1" do |node1|
    node1.vm.box = "fedora/23-cloud-base"
    config.vm.hostname = "node1"
  end

  config.vm.define "node2" do |node2|
    node2.vm.box = "fedora/23-cloud-base"
    config.vm.hostname = "node2"
  end
end
