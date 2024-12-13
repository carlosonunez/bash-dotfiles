# Marcus Stack

Marcus is a terribly-named whole-home automation service powered by Flatcar
Linux.

## Services Provided

- **AdGuard Home**: Whole-home ad blocking!
- **Home Assistant**: Centralized smart home control and HomeKit hub
  for IoT devices that don't speak HomeKit.
- **Calibre**: A private eBook library of books mostly sourced from Amazon
  Kindle.
- **Scrypted**: HomeKit Secure Recording for Ring

## Provisioning

> **NOTE**: This is a work in progress!

1. Download a Debian live CD ISO and burn it to a USB stick:

```sh
# Replace /dev/disk4 with whatever device is mapped to the USB stick
# in `diskutil list`
diskutil eraseDisk FAT32 BOOTDISK /dev/disk4
diskutil unmountDisk /dev/disk4
hdiutil convert -o ~/Downloads/image.dmg -format UDRW /path/to/debian/iso
dd if=~/Downloads/image.dmg of=/dev/disk4 bs=1M status=progress
```

2. Copy the Flatcar Ignition file to either that same USB stick or another one:

```sh
make view_flatcar_ignition > /Volumes/SOME_OTHER_DISK/config.ign
```

> **NOTE**: Add `ENABLE_RPI_SERVICE=1` to the command above if Marcus
> will run on a Raspberry Pi.

3. Insert the disks into the machine that will be running Marcus. Start it and
   boot into the Debian live environment.

4. Bring up a network interface and mount the disks, if needed.

5. Install Flatcar:

```sh
# Replace /dev/vda with whatever device is mapped to the target drive in the
# machine; use `lsblk` to retrieve it.
apt -y update
apt -y install btrfs-progs gawk
wget -O - https://raw.githubusercontent.com/flatcar/init/flatcar-master/bin/flatcar-install | \
    bash -s -- -d /dev/vda -i /mnt/some_other_disk/config.ign
```

6. Reboot. Marcus services should start automatically.

