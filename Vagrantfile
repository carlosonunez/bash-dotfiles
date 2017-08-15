localhost_public_key="ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEArHx9wusMOms+98L8l2o3pVgSROtqOz+AJIq9zeENVZb41nw7RDgxjQpLIRZ0QcOoL0xX5j02QSmAtsM4zh8TbS4SlObh8XnFgr2az1gDvfTwz3ZiqyFartl9rj251oUZNLbY97tkCks0H3NkZpKBetzebje0PFcKFgdPi/CZml1c24oqzMHeN+SyRbZAFzspz0pBWa+sUFKnlESZljbn/+EeMpJ3bzJ9V+vX9OjuIOG1Qprrz4ZhVyyfH4uT3DrrngmsAGcSX5x0jsdoIzSujVPF/yhnUSNOqcR9rKhv3Xg53Q4MDPmjn/ZkCL7HRETI4Ljiw0cSKMXMEDzSKHDQFw== rsa-key-20170529"
ubuntu.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.hostname = "carlosonunez"
  config.vm.network :private_network, ip: "192.168.0.50"
  config.vm.network :forwarded_port, guest: 2376, host: 2376
  config.vm.network :forwarded_port, guest: 5000, host: 5000
  config.vm.provision "file", source: "C:\\Users\\accou\\OneDrive\\ssh_keys",
    destination: "/home/ubuntu/.ssh"
  config.vm.provision "shell",
    inline: "chmod -R 644 ~/.ssh/*"
  config.vm.provision "shell",
    inline: "echo '#{localhost_public_key}' > ~/.ssh/authorized_keys"
  config.ssh.forward_x11 = true
  config.ssh.keys_only = true
end
