Vagrant.require_version ">= 1.5"
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  controller_ip = "192.168.50.130"
  config.vm.box = "bento/centos-7.1"
  (0..2).each do |i|
    config.vm.define "machine#{i}" do |machine|
      machine.vm.provider :virtualbox do |v|
                v.name = "machine#{i}"
                v.customize [
                    "modifyvm", :id,
                    "--name", "machine#{i}",
                    "--memory", 512,
                    "--cpus", 1,
                ]
      end
      machine.vm.hostname="machine#{i}"
      ip="192.168.50.13#{i}"
      puts "**** USE SCRIPT FOR ", 
           machine.vm.hostname, 
           ip,
           controller_ip,
           "*****"
      machine.vm.provision :shell, path: "FullScript.sh", :args => "192.168.50.13#{i} #{i}"
      machine.vm.network "public_network", :bridge => "enp5s0", ip: "192.168.50.13#{i}"
      case "#{i}"
      when "0"
        machine.vm.network "private_network", :bridge => "enp5s0", ip: "192.168.50.10"
      #when "1" "2"
        #machine.vm.network "forwarded_port", guest: 3306, host: "3306"
      end
    end
  end
end
