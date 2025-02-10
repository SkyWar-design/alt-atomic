#!/bin/bash


# любая ошибка остановит выполнение
set -e

echo "Running main.sh..."

# Базовые пакеты для работы системы
./packages/apt_prepare.sh
./packages/base.sh
./packages/DE/GNOME/gnome.sh
if [ "$BUILD_TYPE" = "nvidia" ]; then
   ./packages/components/nvidia/packages.sh
fi
./packages/apt_ending.sh

# Настройка
./configuration/branding.sh
./configuration/settings.sh
./configuration/user.sh
if [ "$BUILD_TYPE" = "nvidia" ]; then
   ./configuration/nvidia.sh
fi
./configuration/kernel.sh

# Сборка программ
./make/zstd.sh
./make/cargo.sh
./make/bootupd.sh
./make/bootc.sh
./make/brew.sh
./make/zsh-plugins.sh
./make/atomic-actions.sh
./configuration/clear.sh

echo "All scripts executed successfully."