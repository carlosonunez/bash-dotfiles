localhost_public_key="ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEArHx9wusMOms+98L8l2o3pVgSROtqOz+AJIq9zeENVZb41nw7RDgxjQpLIRZ0QcOoL0xX5j02QSmAtsM4zh8TbS4SlObh8XnFgr2az1gDvfTwz3ZiqyFartl9rj251oUZNLbY97tkCks0H3NkZpKBetzebje0PFcKFgdPi/CZml1c24oqzMHeN+SyRbZAFzspz0pBWa+sUFKnlESZljbn/+EeMpJ3bzJ9V+vX9OjuIOG1Qprrz4ZhVyyfH4uT3DrrngmsAGcSX5x0jsdoIzSujVPF/yhnUSNOqcR9rKhv3Xg53Q4MDPmjn/ZkCL7HRETI4Ljiw0cSKMXMEDzSKHDQFw== rsa-key-20170529"
nonputty_localhost_public_key="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC3lX38I8cJIuNzUqdb7J4o4D8EbaghdPvJvOqPtdgDHeT57p80qLebN0TTIJUA19tjeCy9SxHWgnE32Dgd8zl0uilxSphoCWSXjNvS1BKTRMwzv9WFmTAq8/2WdZkV5jDMQw2dKNzYtoDoH4716xc8uyLbu6exnI0oCgAvwy5oZ7rS0EbkNin+r3kKEFzdjaJiIsv4wKVnMPhXxel1ArOvF5XQxsKkGJTw4DHnY8ODKmQor+l2l1r1Lsr5yijdruqVmGNphzmicWmpk0EtSyUggwWu0K1lmRfky13Nc1d0Adt2oCfHAYO8e8YAWSRTzzEw4V2Es7oqL3IY+Lx+JbyH"
onedrive_path="C:\\Users\\accou\\OneDrive"
bash_setup_github_repo_url="git@github.carlosnunez.me:carlosonunez/setup.git"
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.hostname = "carlosonunez"
  config.vm.network :private_network, ip: "192.168.0.50"
  config.vm.network :forwarded_port, guest: 2376, host: 2376
  config.vm.network :forwarded_port, guest: 5000, host: 5000
  config.vm.provision "file", source: "#{onedrive_path}\\ssh_keys",
    destination: "/home/ubuntu/.ssh"
  config.vm.provision "file", 
    source: "#{onedrive_path}\\ssh_keys\\config",
    destination: "/home/ubuntu/.ssh"
  config.vm.provision "shell",
    inline: "mv /home/ubuntu/.ssh/ssh_keys/* /home/ubuntu/.ssh"
  config.vm.provision "shell",
    inline: "chmod -R 644 ~/.ssh/*"
  [ localhost_public_key, nonputty_localhost_public_key ].each do |key|
      config.vm.provision "shell",
        inline: "echo '#{key}' > /home/ubuntu/.ssh/authorized_keys"
  end
  config.vm.provision "shell",
    inline: "mkdir /home/ubuntu/src; git clone #{bash_setup_github_repo_url} /home/ubuntu/src/setup"

  config.ssh.forward_x11 = true
  config.ssh.keys_only = true
  config.ssh.private_key_path = "#{onedrive_path}//ssh_keys//localhost"
end
