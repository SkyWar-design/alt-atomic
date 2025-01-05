#!/bin/bash

# любая ошибка остановит выполнение
set -e

echo "Running main.sh..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # Абсолютный путь к директории скрипта
CONFIG_FILE="$SCRIPT_DIR/source/initrd.mk.oem"  # Абсолютный путь к initrd.mk.oem

echo "$CONFIG_FILE"
cat "$CONFIG_FILE"
# Пакеты
#./packages/apt_prepare.sh
#./packages/base.sh           # базовые пакеты для работы системы
#./packages/DE/gnome.sh       # почему бы и нет
#./packages/apt_ending.sh
#
## Настройка
#./configuration/branding.sh
#./configuration/settings.sh
#./configuration/kernel.sh
#./make/zstd.sh
#./make/cargo.sh
#./make/bootupd.sh
#./make/bootc.sh
#./configuration/ostree.sh

echo "All scripts executed successfully."