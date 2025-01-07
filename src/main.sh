#!/bin/bash

# любая ошибка остановит выполнение
set -e

echo "Running main.sh..."

# Пакеты
./packages/apt_prepare.sh
./packages/base.sh           # базовые пакеты для работы системы
./packages/DE/gnome.sh
#./packages/DE/mate.sh
./packages/fpatpak.sh
./packages/apt_ending.sh

# Настройка
./configuration/branding.sh
./configuration/settings.sh
./configuration/kernel.sh
./make/zstd.sh
./make/cargo.sh
./make/bootupd.sh
./make/bootc.sh
./configuration/ostree.sh

echo "All scripts executed successfully."