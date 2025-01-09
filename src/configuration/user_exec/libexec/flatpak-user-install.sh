#!/usr/bin/env bash

# Данный скрипт устанавливает приложения Flatpak в пространство пользователя, срабатывает один раз (или по версии).
GROUP_SETUP_VER=1
GROUP_SETUP_VER_FILE="$HOME/.local/share/flatpak-user-install"

# Проверяем выполнение
if [ -f "$GROUP_SETUP_VER_FILE" ]; then
    GROUP_SETUP_VER_RAN="$(cat "$GROUP_SETUP_VER_FILE")"
else
    GROUP_SETUP_VER_RAN=""
fi

if [ "$GROUP_SETUP_VER" = "$GROUP_SETUP_VER_RAN" ]; then
    echo "Flatpak user install (version $GROUP_SETUP_VER) has already run. Exiting..."
    exit 0
fi

echo "Installing user-level Flatpaks..."

flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user -y flathub com.mattjakeman.ExtensionManager
flatpak install --user -y flathub com.github.tchx84.Flatseal
flatpak install --user -y flathub org.gnome.World.PikaBackup
flatpak install --user -y flathub org.gnome.NautilusPreviewer
flatpak install --user -y flathub org.telegram.desktop

echo "Done installing user-level Flatpaks"

# Запоминаем выполнение вместе с версией скрипта
echo "Writing state file"
echo "$GROUP_SETUP_VER" > "$GROUP_SETUP_VER_FILE"