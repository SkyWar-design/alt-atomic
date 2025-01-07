#!/bin/bash

set -e  # Скрипт остановится при первой ошибке

echo "Installing Flatpak"
apt-get install -y flatpak

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "Updating Flatpak repositories..."
flatpak update -y

flatpak install flathub com.github.tchx84.Flatseal
flatpak install flathub com.mattjakeman.ExtensionManager

echo "End installing Flatpak"