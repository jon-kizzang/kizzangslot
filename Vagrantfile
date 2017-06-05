# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"
CHEF_PATH = "/Development/kizzangChef"
SYNC_PATH = "."
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  
  config.vm.box = "ubuntu14.04"
  config.vm.box_url = "https://oss-binaries.phusionpassenger.com/vagrant/boxes/latest/ubuntu-14.04-amd64-vbox.box"
  config.vm.network "private_network", ip: "192.168.33.103"
  config.vm.hostname = "dev-slot.kizzang.com"
  config.ssh.forward_agent = true
  config.ssh.forward_x11   = true

  config.vm.provider "virtualbox" do |vb|
    vb.customize(["modifyvm", :id, "--natdnshostresolver1", "off"  ])
    vb.customize(["modifyvm", :id, "--natdnsproxy1",        "off"  ])
    vb.customize(["modifyvm", :id, "--memory",              "1024" ])
  end


  
  config.omnibus.chef_version = '11.16.0'
  config.vm.provision :chef_solo do |chef|


   chef.cookbooks_path = "#{CHEF_PATH}/cookbooks", "#{CHEF_PATH}/site-cookbooks"
   chef.environments_path = "#{CHEF_PATH}/environments" 
   chef.environment = "vagrant" 
   chef.roles_path = "#{CHEF_PATH}/roles"
   chef.data_bags_path = "#{CHEF_PATH}/data_bags"
   chef.encrypted_data_bag_secret_key_path = "#{CHEF_PATH}/.chef/encrypted_data_bag_secret"
   chef.add_role('slot_server')
  end

  config.vm.synced_folder("#{SYNC_PATH}", "/vagrant",
                          :owner => "vagrant",
                          :group => "vagrant",
                          :mount_options => ['dmode=777','fmode=777']) 
end
