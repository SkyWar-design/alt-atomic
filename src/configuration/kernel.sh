#!/bin/bash
set -euo pipefail

echo "Running kernel_setup.sh..."

# Определяем пути
KERNEL_DIR="/usr/lib/modules"
BOOT_DIR="/boot"
CONFIG_FILE="/src/source/initrd.mk.oem"  # Абсолютный путь к initrd.mk.oem

# Определяем версии ядра
kver=$(rpm -qa 'kernel-image*' --qf '%{version}-%{name}-%{release}\n' | sed 's/kernel-image-//')

if [ -z "$kver" ]; then
    echo "** No kernel versions found" >&2
    exit 1
fi

cd "$BOOT_DIR"

for KVER in $kver; do
    echo "Generating initramfs for kernel version $KVER..."

    # Используем make-initrd для создания initramfs
    make-initrd -N -v -k "$KVER" AUTODETECT= -c "$CONFIG_FILE" \
        || { echo "** Error: make-initrd failed for $KVER" >&2; exit 1; }

    # Определяем имя файла ядра в зависимости от архитектуры
    case "$(uname -m)" in
    e2k*)
        kname="image";;
    *)
        kname="vmlinuz";;
    esac

    # Создаем символические ссылки для ядра и initramfs
    echo "Creating symbolic links..."
    rm -f "$kname" initrd.img
    ln -s "$kname-$KVER" "$kname" || true
    ln -s "initrd-$KVER.img" "initrd.img"
done

# Копируем файлы в KERNEL_DIR
echo "Copying kernel and initramfs to $KERNEL_DIR..."
for KVER in $kver; do
    mkdir -p "$KERNEL_DIR/$KVER"
    cp "$BOOT_DIR/vmlinuz-$KVER" "$KERNEL_DIR/$KVER/vmlinuz"
    cp "$BOOT_DIR/initrd-$KVER.img" "$KERNEL_DIR/$KVER/initramfs.img"
done

echo "End kernel_setup.sh"