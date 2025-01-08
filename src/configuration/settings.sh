#!/bin/bash
set -e

echo "Running settings.sh"

mkdir -p /var/root /var/home /var/mnt /var/opt /etc/atomic
rm -rf /mnt && ln -s var/mnt /mnt
rm -rf /opt && ln -s var/opt /opt
rm -rf /media && ln -s run/media /media

rm -rf /root && ln -s var/root /root
rm -rf /home && ln -s var/home /home
ln -s sysroot/ostree /ostree

mkdir /var/lib/apt/lists/partial
rm -f /etc/fstab
mkdir /sysroot
cp -a ./source/bootupd/ /usr/lib/
mkdir -p /usr/local/bin
mkdir -p /usr/lib/ostree

echo "[sysroot]" > /usr/lib/ostree/prepare-root.conf
echo "readonly = true" >> /usr/lib/ostree/prepare-root.conf

# Отключаем SELINUX
echo "SELINUX=disabled" > /etc/selinux/config

# Создаём файл /etc/sudoers.d/allow-wheel-nopass если его нет
touch /etc/sudoers.d/allow-wheel-nopass
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/allow-wheel-nopass

# Настройка vconsole
touch /etc/vconsole.conf
echo "KEYMAP=ru" > /etc/vconsole.conf
echo "FONT=latarcyrheb-sun16" > /etc/vconsole.conf

# Включаем сервис ostree-remount
mkdir -p /etc/systemd/system/local-fs.target.wants/
ln -s /usr/lib/systemd/system/ostree-remount.service /etc/systemd/system/local-fs.target.wants/ostree-remount.service

# копируем службы
cp /src/configuration/user_exec/systemd/system/* /usr/lib/systemd/system/
cp /src/configuration/user_exec/systemd/user/* /usr/lib/systemd/user/

# копируем скрипты
cp /src/configuration/user_exec/libexec/* /usr/libexec/

# Включаем сервисы
systemctl enable docker.socket
systemctl enable podman.socket
systemctl enable atomic-groups.service
systemctl enable brew-setup.service
systemctl enable brew-upgrade.timer
systemctl enable brew-update.timer
systemctl --global enable flatpak-install.service

# Расширение лимитов на число открытых файлов для всех юзеров. (при обновлении системы открывается большое число файлов/слоев)
grep -qE "^\* hard nofile 978160$" /etc/security/limits.conf || echo "* hard nofile 978160" >> /etc/security/limits.conf
grep -qE "^\* soft nofile 978160$" /etc/security/limits.conf || echo "* soft nofile 978160" >> /etc/security/limits.conf

# Синхронизируем конфиги
rsync -av --progress /src/source/etc/ /etc/

# Локаль
echo 'LANG=ru_RU.UTF-8' | tee /etc/locale.conf /etc/sysconfig/i18n

echo "End settings.sh"
