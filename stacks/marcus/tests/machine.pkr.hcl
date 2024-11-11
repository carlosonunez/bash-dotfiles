variable "ignition_file" {
  type = string
}

packer {
  required_plugins {
    qemu = {
      version = "1.1.0"
      source = "github.com/hashicorp/qemu"
    }
    vagrant = {
      source = "github.com/hashicorp/vagrant"
      version = "~> 1"
    }
  }
}

source "qemu" "machine" {
  iso_url = "https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/aarch64/alpine-standard-3.20.3-aarch64.iso"
  iso_checksum = "7d6f065d18af54c3686dceae51235661"
  output_directory = "out"
  shutdown_command = "halt -d 0"
  disk_size = "5000M"
  format = "qcow2"
  accelerator = "hvf"
  efi_boot = true
  efi_firmware_code = "/opt/homebrew/share/qemu/edk2-aarch64-code.fd"
  efi_firmware_vars = "/opt/homebrew/share/qemu/edk2-arm-vars.fd"
  vm_name = "faux-marcus-bootstrap"
  boot_wait = "60s"
  ssh_username = "root"
  ssh_password = "alpine123!"
  boot_command = [
    "root<enter><wait>",
    "passwd root<enter>",
    "alpine123!<enter>",
    "alpine123!<enter>",
    "sed -Ei 's/PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config<enter>",
    "/etc/init.d/sshd restart"
  ]
  qemu_binary = "qemu-system-aarch64"
  qemuargs = [
    [ "-machine", "virt"],
    [ "-display", "cocoa" ],
    [ "-device", "virtio-gpu-pci" ],
    [ "-device", "virtio-serial" ],
    [ "-device", "virtio-rng-pci" ],
    [ "-device", "virtio-balloon" ],
    [ "-monitor", "unix:monitor.sock,server,nowait" ]
  ]
}

build {
  sources = [ "source.qemu.machine" ]

  provisioner "file" {
    source = var.ignition_file
    destination = "/tmp/ignition.json"
  }

  provisioner "shell" {
    inline = [
      "apk add bash btrfs-progs btrfs-progs-extra gawk gpg mdadm-udev eudev wipefs wget gpg-agent coreutils",
      "wget -O - https://raw.githubusercontent.com/flatcar/init/flatcar-master/bin/flatcar-install | bash -s -- -d /dev/vda -i /tmp/ignition.json"
    ]
  }

  post-processor "vagrant" {
    keep_input_artifact = true
    output = "faux-marcus.box"
  }
}
