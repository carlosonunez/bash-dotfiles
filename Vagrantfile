ssh_keys_path="C:/Users/accou/OneDrive/ssh_keys"
bash_setup_github_repo_url="git@github.carlosnunez.me:carlosonunez/setup.git"
exposed_ports = [ 22, 80, 443, 2376, 5000 ]
Vagrant.configure("2") do |config|
  config.vm.provider :virtualbox do |provider|
    provider.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    provider.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    provider.customize ["modifyvm", :id, "--nictype1", "virtio"]
  end
  config.vm.box = "ubuntu/xenial64"
  config.vm.hostname = "carlosonunez"
  config.vm.network :private_network, ip: "192.168.1.50"
  config.vm.provision "file", source: ssh_keys_path, destination: '/tmp/ssh_keys'
  exposed_ports.each do |port|
    config.vm.network :forwarded_port, guest: port, host: port
  end
  File.foreach("#{ssh_keys_path}/authorized_keys") do |authorized_key|
    config.vm.provision "shell", inline: "echo '#{authorized_key}' >> /home/ubuntu/.ssh/authorized_keys"
  end
  # Using the 'file' provisioner doesn't work. It keeps trying to copy it as a directory.
  Dir.glob("#{ssh_keys_path}/*").select { |file| !File.readlines(file).grep(/BEGIN RSA/).empty? }.each do |file| 
    file_name = File.basename(file)
    config.vm.provision "shell", inline: "cp -v /home/ubuntu/ssh_keys/#{file_name} /home/ubuntu/.ssh/#{file_name}"
  end
  config.vm.provision "shell", inline: "chmod -R 600 /home/ubuntu/.ssh/*"
  config.vm.provision "shell",
    inline: "mkdir -p /home/ubuntu/src && git clone #{bash_setup_github_repo_url} /home/ubuntu/src/setup'"
  config.vm.provision "shell", inline: 'sh /home/ubuntu/src/setup/setup.sh'
end
