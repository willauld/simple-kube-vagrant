Vagrant.require_version ">= 1.5"
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  base_ip_str = "192.168.50.13"
  controller_ip = "#{base_ip_str}1"   # "192.168.50.131"

  config.vm.box = "bento/centos-7.1"

  (0..3).each do |i|
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
      ip="#{base_ip_str}#{i}"

      machine.vm.provision :shell, 
        path: "FullScript.sh", 
        :args => "#{ip} #{i} #{controller_ip}"

      machine.vm.network "public_network", 
        :bridge => "enp5s0",
        ip: "#{ip}" 

      case "#{i}"
      when "1" # the controller machine
        #machine.vm.network "private_network", :bridge => "enp5s0", ip: "192.168.50.10" 
      end
    end
  end
end
