#!/bin/bash

echo "Installing Flatpak"

apt-get install -y flatpak

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

#echo "Updating Flatpak repositories..."
#flatpak update -y
#
#flatpak install -y flathub com.mattjakeman.ExtensionManager
#flatpak install -y flathub com.github.tchx84.Flatseal

echo "End installing Flatpak"