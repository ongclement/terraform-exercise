#!/bin/bash

echo "Initiating bootstrap & updating package manager..."
yum update -y
mkfs.ext4 /dev/xvdh
mkdir /data

echo "Mounting EBS volume..."
mount /dev/xvdh /data

BLK_ID=$(blkid /dev/xvdh | cut -f2 -d" ")

if [[ -z $BLK_ID ]]; then
  echo "No block id found"
  exit 1
fi

echo "$BLK_ID     /data   xfs    defaults   0   2" | sudo tee --append /etc/fstab
sudo mount -a

echo "Bootstrapping Complete!"