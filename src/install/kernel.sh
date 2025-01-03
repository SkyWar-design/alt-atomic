#!/bin/bash
set -euo pipefail

echo "Running kernel_setup.sh..."

# Находим версию ядра
KERNEL_DIR="/usr/lib/modules"
BOOT_DIR="/boot"

echo "Detecting kernel version..."
KERNEL_VERSION=$(ls "$KERNEL_DIR" | head -n 1)

if [[ -z "$KERNEL_VERSION" ]]; then
    echo "Error: No kernel version found in $KERNEL_DIR."
    exit 1
fi

echo "Kernel version detected: $KERNEL_VERSION"
echo "Generating initramfs for kernel version $KERNEL_VERSION..."
dracut --force \
       --kver "$KERNEL_VERSION" \
       --add "qemu ostree virtiofs btrfs" \
       --add-drivers "virtio_blk virtio_pci virtio_net" \
       "${BOOT_DIR}/initramfs-${KERNEL_VERSION}.img"

# Копируем vmlinuz и initramfs
echo "Copying vmlinuz and initramfs..."
cp "${BOOT_DIR}/vmlinuz-${KERNEL_VERSION}" "${KERNEL_DIR}/${KERNEL_VERSION}/vmlinuz"
cp "${BOOT_DIR}/initramfs-${KERNEL_VERSION}.img" "${KERNEL_DIR}/${KERNEL_VERSION}/initramfs.img"

echo "End kernel_setup.sh"