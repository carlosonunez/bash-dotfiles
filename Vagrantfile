vm_memory = 2048
vm_cpus = 2
vm_nic_type = "Am79C973"
ssh_keys_path="C:/Users/accou/OneDrive/ssh_keys"
bash_setup_github_repo_url="git@github.carlosnunez.me:carlosonunez/setup.git"
exposed_ports = [ 22, 80, 443, 2376, 5000 ]
Vagrant.configure("2") do |config|
  config.vm.provider :virtualbox do |provider|
    provider.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    provider.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    provider.customize ["modifyvm", :id, "--nictype1", vm_nic_type]
    provider.customize ["modifyvm", :id, "--ioapic", "on"]
    provider.memory = vm_memory
    provider.cpus = vm_cpus
  end
  config.vm.box = "ubuntu/xenial64"
  config.vm.hostname = "carlosonunez"
  config.vm.network :private_network, ip: "192.168.1.50"
  exposed_ports.each do |port|
    config.vm.network :forwarded_port, guest: port, host: port
  end
  config.vm.provision "shell", inline: "sudo sh -c 'rm -rf /home/ubuntu/.ssh && mkdir /home/ubuntu/.ssh'"
  Dir.glob("#{ssh_keys_path}/*").select do |file|
    /authorized_keys|config/.match?(file) || !File.readlines(file).grep(/BEGIN RSA/).empty?
  end.each do |ssh_config_file|
    file_name = File.basename(ssh_config_file)
    config.vm.provision "shell", inline: "echo '#{File.read(ssh_config_file)}' > /home/ubuntu/.ssh/#{file_name}"
  end
  config.vm.provision "shell", inline: "sudo chown -R ubuntu:ubuntu /home/ubuntu/.ssh"
  config.vm.provision "shell", inline: "sudo -u ubuntu chmod -R 600 /home/ubuntu/.ssh/*"
  config.vm.provision "shell",
    inline: "sudo -iu ubuntu bash -c 'mkdir -p /home/ubuntu/src && git clone #{bash_setup_github_repo_url} /home/ubuntu/src/setup'"
  config.vm.provision "shell", inline: 'sudo -iu ubuntu bash /home/ubuntu/src/setup/setup.sh'
end
