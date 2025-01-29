#!/bin/bash

echo "Installing GNOME packages"

apt-get install -y \
  gnome-session-wayland \
  gnome-session-xsession \
  gnome-control-center \
  gnome-shell \
  gnome-shell-extensions \
  gnome-tweaks \
  dconf-editor \
  fonts-otf-abattis-cantarell \
  gnome-backgrounds \
  yelp \
  gnome-system-monitor \
  gnome-logs \
  gnome-calculator \
  gnome-calendar \
  gnome-characters \
  gvfs-backends \
  fuse-gvfs \
  nautilus \
  nautilus-share \
  samba-usershares \
  file-roller \
  gnome-text-editor \
  loupe \
  gnome-weather \
  gnome-clocks \
  gnome-maps \
  gnome-icon-theme \
  gnome-icon-theme-symbolic \
  gnome-themes-extra \
  libgtk2-engine-adwaita \
  gnome-user-docs \
  gnome-tour \
  papers \
  power-profiles-daemon \
  g4music \
  key-rack \
  gnome-extension-manager \
  firefox \
  fonts-ttf-cjkuni-ukai \
  gnome-browser-connector \
  gnome-software \
  gnome-tweaks \
  gnome-keyring-ssh \
  fonts-ttf-liberation \
  fonts-ttf-dejavu \
  qt5-wayland \
  qt6-wayland \
  wayland-utils \
  vulkan-tools \
  xorg-drv-libinput \
  xorg-drv-qxl \
  xorg-drv-spiceqxl \
  xorg-drv-intel \
  xorg-drv-amdgpu \
  xorg-drv-vmware \
  xorg-drv-nouveau \
  gnome-console \
  ptyxis \
  pipewire \
  wireplumber \
  gnome-shell-extension-appindicator \
  gnome-shell-extension-dash-to-dock \
  avahi-daemon \
  cups-browsed \
  fwupd \
  libnss-mdns \
  iucode_tool

# Настройка
/src/packages/DE/GNOME/settings.sh

echo "End installing GNOME packages"