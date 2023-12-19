# Marcus Stack

This folder contains a Docker Compose file that stands up "Marcus," the
everything box for our house.

Marcus runs the following services:

- **AdGuard Home**: Whole-home ad blocking
- **Home Assistant**: Centralized light, sensor and alarm system control and
  HomeKit bridge

## Backups and Restores

Marcus Stack uses `rclone` to backup and restore its configuration from Google
Drive. Instructions for configuring `rclone` are in 1Password for now.
