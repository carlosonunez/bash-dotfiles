variable "ignition_file" {
  type = string
}

variable "box_path" {
  type = string
}

packer {
  required_plugins {
    vagrant = {
      source = "github.com/hashicorp/vagrant"
      version = "~> 1"
    }
  }
}

source "qemu" "machine" {
  accelerator = "hvf"
  boot_wait = "10s"
  boot_command = [
    "root<enter><wait3s>",
    "passwd root<enter><wait2s>",
    "alpine123!<enter><wait2s>",
    "alpine123!<enter><wait2s>",
    "echo 'iface eth0 inet dhcp' >> /etc/network/interfaces<enter><wait>",
    "ifup eth0<enter><wait5s>",
    "apk add openssh<enter><wait>",
    "sed -Ei 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config<enter><wait>",
    "/etc/init.d/sshd restart<enter><wait1s>"
  ]
  boot_key_interval = "10ms"
  cores = 4
  cpus = 4
  disk_size = "20G"
  format = "qcow2"
  iso_checksum = "7d6f065d18af54c3686dceae51235661"
  # TODO: Un-hardcode Alpine version.
  iso_url = "https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/aarch64/alpine-standard-3.20.3-aarch64.iso"
  machine_type = "virt"
  net_device = "virtio-net-pci"
  output_directory = "out"
  # -boot=n works around "no function defined" errors that come up from qemu failing to exclude
  # the '-boot' option while building qemu args.
  qemuargs = [
    [ "-cpu", "host" ],
    [ "-boot", "n" ],
    [ "-bios", "/opt/homebrew/share/qemu/edk2-aarch64-code.fd" ],
    [ "-device", "virtio-gpu" ],
    [ "-device", "virtio-scsi-pci,id=scsi-bus" ],
    [ "-device", "nec-usb-xhci,id=usb-bus" ],
    [ "-device", "usb-kbd,bus=usb-bus.0" ]
  ]
  qemu_binary = "qemu-system-aarch64"
  shutdown_command = "halt -d 0"
  sockets = 1
  ssh_password = "alpine123!"
  ssh_username = "root"
  threads = 1
  use_default_display = true
  vm_name = "faux-marcus-bootstrap"
  vnc_port_max = 5959
  vnc_port_min = 5959
  vnc_use_password = true
  vnc_password = "supersecret"
}

build {
  sources = [ "source.qemu.machine" ]

  provisioner "file" {
    source = var.ignition_file
    destination = "/tmp/ignition.json"
  }

  # TODO: Un-hardcode Alpine version.
  provisioner "shell" {
    inline = [
      "echo 'https://dl-cdn.alpinelinux.org/alpine/v3.20/main' > /etc/apk/repositories",
      "echo 'https://dl-cdn.alpinelinux.org/alpine/v3.20/community' >> /etc/apk/repositories",
      "apk update",
      "apk add bash blkid lsblk btrfs-progs btrfs-progs-extra gawk gpg mdadm-udev eudev wipefs wget gpg-agent coreutils",
      "modprobe btrfs vfat ext4",
      "wget -O - https://raw.githubusercontent.com/flatcar/init/flatcar-master/bin/flatcar-install | bash -s -- -d /dev/vda -i /tmp/ignition.json"
    ]
  }

  post-processor "vagrant" {
    output = var.box_path
  }
}
