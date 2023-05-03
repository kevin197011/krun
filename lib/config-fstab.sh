# Copyright (c) 2023 kk
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# name=sdb
# m_path=/data
# UUID=1c419d6c-5064-4a2b-953c-05b2c67edb15 /data                       xfs     defaults        0 0

lsblk

echo ''
printf "disk name: "
read name
echo ''
printf "mount path: "
read m_path

(lsblk | grep -q -w ${name}) || exit 1

mkdir -p ${m_path}

# mkfs.xfs /dev/${name}

uuid=$(blkid | grep -w '${name}' | grep -Ewo '[[:xdigit:]]{8}(-[[:xdigit:]]{4}){3}-[[:xdigit:]]{12}')

grep -q ${uuid} /etc/fstab && echo 'fstab already config disk name, exit!' && exit 2

mount /dev/${name} ${m_path} && echo "UUID=${uuid} ${m_path}                       xfs     defaults        0 0" >> /etc/fstab