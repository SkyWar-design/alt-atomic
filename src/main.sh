#!/bin/bash


# любая ошибка остановит выполнение
set -e

echo "Running main.sh..."

# Базовые пакеты для работы системы
./packages/apt_prepare.sh
./packages/base.sh
./packages/DE/GNOME/gnome.sh
./packages/apt_ending.sh

# Настройка
./configuration/branding.sh
./configuration/settings.sh
./configuration/user.sh
./configuration/kernel.sh
./make/zstd.sh
./make/cargo.sh
./make/bootupd.sh
./make/bootc.sh
./make/brew.sh
./make/zsh-plugins.sh
./make/atomic-actions.sh
./configuration/clear.sh

echo "All scripts executed successfully."