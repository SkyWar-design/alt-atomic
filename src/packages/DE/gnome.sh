#!/bin/bash

echo "Installing GNOME packages"

apt-get install -y gnome3-minimal

# Неожиданно Alt linux для GNOME в /var/lib/openvpn/dev записывает устройство urandom
# устройства запрещено включать в коммит, только файлы и сим-линки
rm -f /var/lib/openvpn/dev/urandom
ln -s /dev/urandom /var/lib/openvpn/dev/urandom

# Меняем поломанный Display manager
rm /usr/lib/systemd/system/display-manager.service
ln -s /usr/lib/systemd/system/gdm.service /usr/lib/systemd/system/display-manager.service

echo "End installing GNOME packages"