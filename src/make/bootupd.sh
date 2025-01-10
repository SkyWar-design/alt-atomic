#!/bin/bash
set -euo pipefail

echo "Running bootupd.sh"

# Определяем версии и пути
BOOTUPD_VERSION="0.2.25"
BOOTUPD_ARCHIVE="bootupd-${BOOTUPD_VERSION}.zip"
BOOTUPD_URL="https://github.com/coreos/bootupd/archive/refs/tags/v${BOOTUPD_VERSION}.zip"
BOOTUPD_BUILD_DIR="/tmp/bootupd-${BOOTUPD_VERSION}"

# Скачиваем архив с исходниками bootupd
cd /tmp
echo "Downloading bootupd version ${BOOTUPD_VERSION}..."
wget "${BOOTUPD_URL}" -O "${BOOTUPD_ARCHIVE}"

# Распаковываем архив
echo "Extracting bootupd..."
unzip "${BOOTUPD_ARCHIVE}"

# Переходим в директорию сборки
cd "${BOOTUPD_BUILD_DIR}"

# Вносим изменения в исходники для совместимости с ALT Linux
echo "Applying ALT Linux specific patches..."
sed -i 's/\bgrub2\b/grub/g' src/grubconfigs.rs
sed -i 's|let cruft = \["loader", "grub2"\];|let cruft = \["loader", "grub"\];|' src/efi.rs
sed -i 's|usr/sbin/grub2-install|usr/sbin/grub-install|' src/bios.rs
sed -i '/let boot_dir = Path::new(dest_root).join("boot");/a \
        #[cfg(target_arch = "x86_64")]\
        cmd.args(["--target", "x86_64-efi"])\
            .args(["--boot-directory", boot_dir.to_str().unwrap()])\
            .args(["--modules", "mdraid1x part_gpt"])\
            .arg(device);' src/bios.rs
sed -i '/if !rpmout.status.success()/a \        return Ok(ContentMetadata { timestamp: chrono::Utc::now(), version: "unknown".to_string() });' \
    src/packagesystem.rs
sed -i '/std::io::stderr().write_all(&rpmout.stderr)/d' src/packagesystem.rs
sed -i '/bail!("Failed to invoke rpm -qf")/d' src/packagesystem.rs

# Собираем проект с помощью Cargo
echo "Building bootupd..."
cargo build --release

# Устанавливаем bootupd и создаём ссылки
echo "Installing bootupd..."
install -m 0755 target/release/bootupd /usr/local/bin/bootupd
ln -sf /usr/local/bin/bootupd /usr/local/bin/bootupctl
ln -sf /usr/local/bin/bootupd /usr/bin/bootupctl

# Убираем временные файлы
echo "Cleaning up..."
cd /tmp
rm -rf "${BOOTUPD_BUILD_DIR}" "${BOOTUPD_ARCHIVE}"

echo "End bootupd"