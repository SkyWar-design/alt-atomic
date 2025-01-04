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
cp -a ./source/bootupd/ /usr/lib/
mkdir -p /usr/local/bin
mkdir -p /usr/lib/ostree

echo "[sysroot]" > /usr/lib/ostree/prepare-root.conf
echo "readonly = true" >> /usr/lib/ostree/prepare-root.conf

echo "SELINUX=disabled" > /etc/selinux/config
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/allow-wheel-nopass
mkdir -p /etc/systemd/system/local-fs.target.wants/
ln -s /usr/lib/systemd/system/ostree-remount.service /etc/systemd/system/local-fs.target.wants/ostree-remount.service

# Расширение лимитов на число открытых файлов для всех юзеров. (при обновлении системы открывается большое число файлов/слоев)
grep -qE "^\* hard nofile 97816$" /etc/security/limits.conf || echo "* hard nofile 97816" >> /etc/security/limits.conf
grep -qE "^\* soft nofile 97816$" /etc/security/limits.conf || echo "* soft nofile 97816" >> /etc/security/limits.conf

echo "End settings.sh"
