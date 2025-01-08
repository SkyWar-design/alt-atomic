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
ptyxis \
gnome-shell-extension-appindicator \
gnome-shell-extension-blur-my-shell \
gnome-shell-extension-dash-to-dock

# Установка Flatpak приложений
/src/packages/DE/GNOME/fpatpak.sh

# Настройка
/src/packages/DE/GNOME/settings.sh

echo "End installing GNOME packages"