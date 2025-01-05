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

# dracut: создаем initramfs с нужными модулями и функциями
dracut --force \
       --kver "$KERNEL_VERSION" \
       --add "qemu ostree virtiofs btrfs base" \
       --add-drivers "
           ext4
           ahci
           ahci_platform
           sd_mod
           evdev
           virtio_blk
           virtio_pci
           virtio_net
           virtio-gpu
           virtio_input
           virtio_scsi
           virtio_console
           virtio_blk
           virtio-rng
           virtio_net
           virtio_pci
           virtio-mmio
           drm/virtio
           virtio_input
           i915
           amdgpu
           snd_hda_intel
           snd_hda_codec
           snd_hda_core
           snd_pcm
           snd_timer
           soundcore
           joydev
           evdev
           overlay
           fuse
           net_failover
           crc32_generic
           ata_piix
           drivers/hid
           drivers/pci
           drivers/mmc
           drivers/usb/host
           drivers/usb/storage
           drivers/nvmem
           drivers/nvme
           drivers/video/fbdev
       " \
       "${BOOT_DIR}/initramfs-${KERNEL_VERSION}.img"

# Копируем vmlinuz и initramfs
echo "Copying vmlinuz and initramfs..."
cp "${BOOT_DIR}/vmlinuz-${KERNEL_VERSION}" "${KERNEL_DIR}/${KERNEL_VERSION}/vmlinuz"
cp "${BOOT_DIR}/initramfs-${KERNEL_VERSION}.img" "${KERNEL_DIR}/${KERNEL_VERSION}/initramfs.img"

echo "End kernel_setup.sh"