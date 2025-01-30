#!/bin/bash

echo "Installing GNOME packages"

# Неожиданно Alt linux в /var/lib/openvpn/dev записывает устройство urandom
# устройства запрещено включать в коммит, только файлы и сим-линки
rm -f /var/lib/openvpn/dev/urandom
ln -s /dev/urandom /var/lib/openvpn/dev/urandom

# Удаляем неактуальный ярлык
#rm -f /usr/share/applications/indexhtml.desktop

# Спрячем приложения
sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/htop.desktop
sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/nvtop.desktop
sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/org.gnome.Console.desktop

# включим GDM
systemctl enable gdm
systemctl enable avahi-daemon
systemctl enable wsdd
systemctl mask packagekit.service

# Синхронизируем конфиги
rsync -av --progress /src/source/configuration/DE/GNOME/etc/ /etc/

# Обновление dconf
dconf update

# Включаем pam_gnome_keyring для gnome-initial-setup
#echo "auth optional pam_gnome_keyring.so" >> /etc/pam.d/gdm-launch-environment
#echo "session optional pam_gnome_keyring.so auto_start" >> /etc/pam.d/gdm-launch-environment

# Включение первоначальной настройки InitialSetupEnable
#sed -i '/^\[daemon\]/a InitialSetupEnable=True' /etc/gdm/custom.conf

# Убираем строки связанные с проверкой user = gdm, иначе gnome-initial-setup НЕ РАБОТАЕТ
#FILE="/etc/pam.d/gdm-launch-environment"
#if [[ -f "$FILE" ]]; then
#    sed -i '/user = gdm/s/^/# /' "$FILE"
#fi

# Включаем создание домашних папок
sed -i 's/^[[:space:]]*enabled=false/enabled=True/i' /etc/xdg/user-dirs.conf

echo "End installing GNOME packages"