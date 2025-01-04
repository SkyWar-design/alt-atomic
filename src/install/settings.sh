#!/bin/bash
set -e

echo "Running settings.sh"

mkdir -p /var/root /var/home /mnt /media /opt
ln -s var/mnt /mnt
ln -s var/opt /opt
ln -s run/media /media
rm -rf /root && ln -s var/root /root
rm -rf /home && ln -s var/home /home
ln -s sysroot/ostree /ostree

# Создаём пользователя "atomic" и задаём пароль "atomic"
useradd -m -G wheel -s /bin/bash atomic && \
echo "atomic:atomic" | chpasswd && \
mkdir -p /var/home/atomic && chown atomic:atomic /var/home/atomic

mkdir /var/lib/apt/lists/partial
rm -f /etc/fstab
mkdir /sysroot
mkdir -p /usr/lib/bootupd/updates
cp -a ../source/bootupd/ /usr/lib/bootupd/
mkdir -p /usr/local/bin
mkdir -p /usr/lib/ostree

echo "[sysroot]" > /usr/lib/ostree/prepare-root.conf
echo "readonly = true" >> /usr/lib/ostree/prepare-root.conf

echo "SELINUX=disabled" > /etc/selinux/config
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/allow-wheel-nopass
mkdir -p /etc/systemd/system/local-fs.target.wants/
ln -s /usr/lib/systemd/system/ostree-remount.service /etc/systemd/system/local-fs.target.wants/ostree-remount.service

echo "End settings.sh"