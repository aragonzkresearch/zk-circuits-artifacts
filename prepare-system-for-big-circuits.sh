#!/bin/sh

# https://hackmd.io/V-7Aal05Tiy-ozmzTGBYPA
# https://hackmd.io/SUlyJfrNTDqBkSyGJ7E0cQ

# swap preparation
fallocate -l 15G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
cat /etc/fstab

echo "swap created, now, add to /etc/sysctl.conf:
vm.swappiness=1
vm.max_map_count=10000000"


# rapidsnark needs:
sudo apt install build-essential
sudo apt install libgmp-dev
sudo apt install libsodium-dev
sudo apt install nasm
sudo apt install nlohmann-json3-dev
