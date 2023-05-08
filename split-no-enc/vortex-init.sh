#!/bin/bash

# Ensures the entire script is run as root.
if [[ $UID != 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

echo "Creating Partition Table"
parted /dev/nvme0n1 -- mklabel gpt

echo "Creating Boot Partition"
parted /dev/nvme0n1 -- mkpart ESP fat32 1MB 512MB
parted /dev/nvme0n1 -- set 1 esp on

echo "Creating Swap Partition"
parted /dev/nvme0n1 -- mkpart primary linux-swap 512MB 18GB

echo "Creating Main Partition"
parted /dev/nvme0n1 -- mkpart primary 18GB 100%

echo "Formatting Boot Partition"
mkfs.fat -F 32 -n boot /dev/nvme0n1p1

echo "Formatting Swap Partition"
mkswap -L swap /dev/nvme0n1p2

#-------------------------------------------
echo "Creating LVM for user partitions"
pvcreate /dev/nvme0n1p3
vgcreate pool /dev/nvme0n1p3

lvcreate -L 50G -n nix-store pool
lvcreate -L 180G -n root-que pool
lvcreate -L 180G -n root-xin pool
lvcreate -l 100%FREE -n root-guest pool

echo "Formatting Root Partitions"
mkfs.ext4 /dev/pool/root-que
mkfs.ext4 /dev/pool/root-xin
mkfs.ext4 /dev/pool/root-guest
mkfs.ext4 /dev/pool/nix-store

echo "Activating Swap"
swapon /dev/nvme0n1p2

echo -e "Run vortex-install.sh for each user"
