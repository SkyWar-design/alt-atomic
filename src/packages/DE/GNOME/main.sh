#!/bin/bash

echo "Installing GNOME packages"

apt-get install -y gnome3-minimal \
firefox \
gnome-software-disable-updates \
gnome-tweaks \
fonts-ttf-liberation \
fonts-ttf-dejavu \
qt5-wayland \
qt6-wayland \
wayland-utils \
vulkan-tools \
xorg-drv-qxl \
xorg-drv-spiceqxl \
xorg-drv-intel \
xorg-drv-amdgpu \
xorg-drv-vmware \
xorg-drv-nouveau \
xorg-drv-radeon

# Обновление шрифтов
fc-cache -fv

# Неожиданно Alt linux в /var/lib/openvpn/dev записывает устройство urandom
# устройства запрещено включать в коммит, только файлы и сим-линки
rm -f /var/lib/openvpn/dev/urandom
ln -s /dev/urandom /var/lib/openvpn/dev/urandom

# Меняем Display manager
rm /usr/lib/systemd/system/display-manager.service
ln -s /usr/lib/systemd/system/gdm.service /usr/lib/systemd/system/display-manager.service

# Установка Flatpak приложений
/src/packages/DE/GNOME/fpatpak.sh

echo "End installing GNOME packages"