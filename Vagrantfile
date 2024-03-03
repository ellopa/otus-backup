# -*- mode: ruby -*-
# vi: set ft=ruby :
ENV['VAGRANT_EXPERIMENTAL'] = "disks"

Vagrant.configure("2") do |config|
    config.vm.box = "centos/7"    

    config.vm.provider "virtualbox" do |v|
        v.memory = 512
        v.cpus = 1
    end

    config.vm.define "client" do |client|
        client.vm.network "private_network", ip: "192.168.56.13", virtualbox__intnet: "net1"
        client.vm.hostname = "client"
    end   

    config.vm.define "backup_server" do |backup_server|
        backup_server.vm.network "private_network", ip: "192.168.56.14", virtualbox__intnet: "net1"
        backup_server.vm.hostname = "backupserver"
        backup_server.vm.disk :disk, size: "2GB", name: "backup"
    end
       

    config.vm.provision "ansible" do |ansible|
        ansible.playbook = "playbook.yml"
        ansible.limit = "all"
        ansible.host_key_checking = "false"
        ansible.raw_arguments = Shellwords.shellsplit(ENV['ANSIBLE_ARGS']) if ENV['ANSIBLE_ARGS']
    end    
end
