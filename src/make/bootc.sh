#!/bin/bash
set -euo pipefail

echo "Running bootc.sh..."

# Определяем версии и пути
BOOTC_VERSION="1.1.3"
BOOTC_ARCHIVE="bootc-${BOOTC_VERSION}.zip"
BOOTC_URL="https://github.com/containers/bootc/archive/refs/tags/v${BOOTC_VERSION}.zip"
BOOTC_BUILD_DIR="/tmp/bootc-${BOOTC_VERSION}"

# Скачиваем архив с исходниками bootc
cd /tmp
echo "Downloading bootc version ${BOOTC_VERSION}..."
wget "${BOOTC_URL}" -O "${BOOTC_ARCHIVE}"

# Распаковываем архив
echo "Extracting bootc..."
unzip "${BOOTC_ARCHIVE}"

# Переходим в директорию сборки
cd "${BOOTC_BUILD_DIR}"

# Собираем проект с помощью Cargo
echo "Building bootc..."
cargo build --release

# Устанавливаем bootc
echo "Installing bootc..."
install -m 0755 target/release/bootc /usr/local/bin/bootc

# Убираем временные файлы
echo "Cleaning up..."
cd /tmp
rm -rf "${BOOTC_BUILD_DIR}" "${BOOTC_ARCHIVE}"

echo "bootc.sh completed successfully."