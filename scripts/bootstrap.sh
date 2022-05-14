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

#echo "Installing nginx server"
#amazon-linux-extras install nginx1
#
#echo "Changing default root directory to /data"
#sed -i '/root/c\        root         /data;' /etc/nginx/nginx.conf
#
#echo "Creating index file"
#echo "Hello" > /data/index.html
#
#echo "Starting up nginx server"
#service nginx start