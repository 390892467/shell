#!/bin/bash
#
dirarr=(0 1 2 3 4 5 6 7 8 9 10 11)
fdarr=(c d e f g h i j k l m n)
num=${#dirarr[@]}
for ((x=0;x<$num;x++));do
      parted -s /dev/sd${fdarr[x]} mklabel gpt
      parted -s /dev/sd${fdarr[x]} mkpart ext4 0% 100%
      sleep 2
      mkfs.ext4 /dev/sd${fdarr[x]}1
      mkdir /dfsdisk${dirarr[x]} -p
      mount /dev/sd${fdarr[x]}1 /dfsdisk${dirarr[x]}
      uuid=$(blkid -s UUID /dev/sd${fdarr[x]}1 | awk -F\" '{print $2}')
      cat >> /etc/fstab<<EOF
UUID=${uuid} /dfsdisk${dirarr[x]}         ext4    defaults        1 0
EOF
      sleep 2
done
