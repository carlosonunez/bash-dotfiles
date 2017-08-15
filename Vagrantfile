Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.hostname = "carlosonunez"
  config.vm.network :private_network, ip: "192.168.0.50"
  config.vm.network :forwarded_port, guest: 2376, host: 2376
  config.vm.network :forwarded_port, guest: 5000, host: 5000
  config.vm.synced_folder "C:\\Users\\accou\\OneDrive\\ssh_keys", "/home/vagrant/.ssh/inherited_keys"
  config.ssh.forward_x11 = true
  config.ssh.keys_only = true
end
