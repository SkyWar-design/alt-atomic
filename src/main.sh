#!/bin/bash

# любая ошибка остановит выполнение
set -e

echo "Running main.sh..."

# Пакеты
./packages/apt_prepare.sh
./packages/base.sh           # базовые пакеты для работы системы
./packages/DE/gnome.sh       # почему бы и нет
./packages/apt_ending.sh

# Настройка
./install/branding.sh
./install/settings.sh
./install/kernel.sh
./make/zstd.sh
./make/cargo.sh
./make/bootupd.sh
./make/bootc.sh
./install/ostree.sh

echo "All scripts executed successfully."