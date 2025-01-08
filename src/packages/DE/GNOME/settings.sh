#!/bin/bash

echo "Installing GNOME packages"

# Обновление шрифтов
fc-cache -fv

# Неожиданно Alt linux в /var/lib/openvpn/dev записывает устройство urandom
# устройства запрещено включать в коммит, только файлы и сим-линки
rm -f /var/lib/openvpn/dev/urandom
ln -s /dev/urandom /var/lib/openvpn/dev/urandom

# Меняем Display manager
rm /usr/lib/systemd/system/display-manager.service
ln -s /usr/lib/systemd/system/gdm.service /usr/lib/systemd/system/display-manager.service

# Удаляем неактуальный ярлык
rm -f /usr/share/applications/indexhtml.desktop

# Устанавливаем источники для клавиатуры
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'ru')]"

# Спрячем приложения
sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/htop.desktop
sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/nvtop.desktop
sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/org.gnome.Console.desktop

# Установим Ptyxis как терминал по умолчанию (он умеет нативно работать контейнерами и показывать их)
update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator $(which ptyxis) 100
update-alternatives --set x-terminal-emulator $(which ptyxis)
gsettings set org.gnome.desktop.default-applications.terminal exec 'ptyxis'

# Устанавливаем приложения по умолчанию
gsettings set org.gnome.shell favorite-apps "['firefox.desktop', 'org.gnome.TextEditor.desktop', 'app.devsuite.Ptyxis.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Software.desktop']"

# Включаем расширения
gsettings set org.gnome.shell enabled-extensions "['appindicatorsupport@rgcjonas.gmail.com', 'dash-to-dock@micxgx.gmail.com', 'blur-my-shell@aunetx']"

cp /src/source/gnome-initial-setup-first-login.desktop /etc/xdg/autostart/gnome-initial-setup-first-login.desktop

echo "End installing GNOME packages"