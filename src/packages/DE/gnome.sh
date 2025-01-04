#!/bin/bash

echo "Installing GNOME packages"

apt-get install -y gnome3-minimal

# Неожиданно Alt linux для GNOME в /var/lib/openvpn/dev записывает устройство urandom
# устройства запрещено включать в коммит, только файлы и сим-линки
rm -f /var/lib/openvpn/dev/urandom
ln -s /dev/urandom /var/lib/openvpn/dev/urandom

echo "End installing GNOME packages"