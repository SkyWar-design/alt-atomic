FROM registry.altlinux.org/sisyphus/base:latest

# Устанавливаем все зависимости
RUN apt-get update && apt-get install -y \
    mount \
    bluez \
    podman \
    btrfs-progs \
    mc \
    htop \
    nano \
    passwd \
    efivar \
    shim-unsigned  \
    shim-signed \
    efitools \
    glibc-utils \
    su \
    sudo \
    virtiofsd \
    which \
    ostree \
    libostree-devel \
    fuse-overlayfs \
    git \
    wget \
    composefs \
    skopeo \
    efibootmgr \
    grub \
    grub-efi \
    grub-btrfs \
    containers-common \
    curl \
    losetup \
    build-essential \
    unzip \
    util-linux \
    coreutils \
    systemd \
    systemd-devel \
    dosfstools \
    e2fsprogs \
    iputils \
    NetworkManager \
    attr \
    sfdisk \
    rust \
    pkg-config \
    openssl \
    openssl-devel \
    glib2 \
    glib2-devel \
    libgio \
    libgio-devel \
    dracut \
    kernel-image-6.12 \
    kernel-headers-6.12 \
    rsync \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2) Turn SELinux off inside container:
RUN echo "SELINUX=disabled" > /etc/selinux/config

# Добавляем права
RUN echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/allow-wheel-nopass

# Настраиваем systemd-службы
RUN mkdir -p /etc/systemd/system/local-fs.target.wants/ && \
    ln -s /usr/lib/systemd/system/ostree-remount.service /etc/systemd/system/local-fs.target.wants/ostree-remount.service
#RUN ln -s /usr/lib/systemd/system/NetworkManager.service \
#       /etc/systemd/system/multi-user.target.wants/NetworkManager.service

# Настраиваем os-release (косметика)
RUN echo "ID=alt" > /etc/os-release && \
    echo "NAME=\"ALT Atomic\"" >> /etc/os-release && \
    echo "VERSION=\"6.12 Atomic Build\"" >> /etc/os-release

# Включаем readonly в конфиг OSTree (при загрузке)
RUN mkdir -p /usr/lib/ostree && \
    echo "[sysroot]" > /usr/lib/ostree/prepare-root.conf && \
    echo "readonly = true" >> /usr/lib/ostree/prepare-root.conf
    # Если нужно включить composefs:
#    echo "[composefs]" >> /usr/lib/ostree/prepare-root.conf && \
#    echo "enabled = true" >> /usr/lib/ostree/prepare-root.conf

# Скачиваем и собираем zstd (пример)
WORKDIR /tmp
RUN wget https://github.com/facebook/zstd/releases/download/v1.5.5/zstd-1.5.5.tar.gz && \
    tar -xzf zstd-1.5.5.tar.gz && \
    cd zstd-1.5.5 && \
    make && make install && \
    cd .. && rm -rf zstd-1.5.5*

# Настройка PKG_CONFIG_PATH (для libzstd.pc)
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/lib/pkgconfig"

# Устанавливаем Rust + Cargo через Rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    . /root/.cargo/env && \
    rustup default stable

ENV PATH="/root/.cargo/bin:${PATH}"

# создаем папку
RUN mkdir -p /usr/local/bin

# Сборка bootupd (которая включает bootupd и bootupctl)
WORKDIR /tmp
RUN wget https://github.com/coreos/bootupd/archive/refs/tags/v0.2.25.zip -O bootupd.zip && \
    unzip bootupd.zip && \
    cd bootupd-0.2.25 && \
    # ALT - не такой как все, grub2 не существует, изменяем хардкод
    sed -i 's/\bgrub2\b/grub/g' src/grubconfigs.rs && \
    sed -i 's|let cruft = \["loader", "grub2"\];|let cruft = \["loader", "grub"\];|' src/efi.rs && \
    sed -i 's|usr/sbin/grub2-install|usr/sbin/grub-install|' src/bios.rs && \
    sed -i '/if !rpmout.status.success()/a \        return Ok(ContentMetadata { timestamp: chrono::Utc::now(), version: "unknown".to_string() });' \
        src/packagesystem.rs && \
    sed -i '/std::io::stderr().write_all(&rpmout.stderr)/d' src/packagesystem.rs && \
    sed -i '/bail!("Failed to invoke rpm -qf")/d' src/packagesystem.rs && \
    cargo build --release && \
    # Устанавливаем bootupd
    install -m 0755 target/release/bootupd /usr/local/bin/bootupd && \
    ln -sf /usr/local/bin/bootupd /usr/local/bin/bootupctl && \
    ln -sf /usr/local/bin/bootupd /usr/bin/bootupctl && \
    cd .. && rm -rf bootupd*

# Сборка bootc
WORKDIR /tmp
RUN wget https://github.com/containers/bootc/archive/refs/tags/v1.1.3.zip -O bootc.zip && \
    unzip bootc.zip && \
    cd bootc-1.1.3 && \
    cargo build --release && \
    install -m 0755 target/release/bootc /usr/local/bin/bootc && \
    cd .. && rm -rf bootc*

# Генерация initramfs для «первого» найденного ядра
# RUN dracut --force --kver "$(ls /usr/lib/modules | head -n 1)"
RUN KVER="$(ls /usr/lib/modules | head -n 1)" && \
    dracut --force \
           --kver "$KVER" \
           --add "qemu ostree virtiofs btrfs" \
           --add-drivers "virtio_blk virtio_pci virtio_net" \
           "/boot/initramfs-$KVER.img"

# Копируем vmlinuz и initramfs в соответствующую папку
RUN set -ex && \
    KERNEL_VERSION="$(ls /usr/lib/modules | head -n 1)" && \
    cp "/boot/vmlinuz-${KERNEL_VERSION}"       "/usr/lib/modules/${KERNEL_VERSION}/vmlinuz" && \
    cp "/boot/initramfs-${KERNEL_VERSION}.img" "/usr/lib/modules/${KERNEL_VERSION}/initramfs.img"

# Удаление содержимого папки /boot, но оставляем саму папку
# RUN rm -rf /boot/* || true

# Восстанавливаем папку для apt
RUN mkdir /var/lib/apt/lists/partial

# Удаляем fstab
RUN rm -f /etc/fstab

# Создаем папки
RUN mkdir /sysroot
RUN mkdir -p /usr/lib/bootupd/updates

# Копируем bootupd (grub-утилита)
COPY bootupd/ /usr/lib/bootupd/

#
# --- Настройка паок ---
#
RUN mkdir -p /var/root /var/home /mnt /media /opt
RUN ln -s var/mnt /mnt
RUN ln -s var/opt /opt
RUN ln -s run/media /media
RUN rm -rf /root && ln -s var/root /root
RUN rm -rf /home && ln -s var/home /home
RUN ln -s sysroot/ostree /ostree

# Создаём пользователя "atomic" и задаём пароль "atomic"
RUN useradd -m -G wheel -s /bin/bash atomic && \
    echo "atomic:atomic" | chpasswd && \
    mkdir -p /var/home/atomic && chown atomic:atomic /var/home/atomic

# 12) Создаём каталог /sysroot/ostree/repo и инициализируем его
RUN mkdir -p /sysroot/ostree/repo && \
    ostree --repo=/sysroot/ostree/repo init --mode=archive

# 13) Копируем текущее содержимое контейнера в /tmp/rootfscopy
RUN mkdir -p /tmp/rootfscopy && \
    rsync -aAX \
      --exclude=/dev \
      --exclude=/proc \
      --exclude=/sys \
      --exclude=/run \
      --exclude=/boot \
      --exclude=/tmp \
      --exclude=/var/tmp \
      --exclude=/var/lib/containers \
      --exclude=/output \
      / /tmp/rootfscopy/

# Создаем пустые папки после копирования
RUN #mkdir -p /tmp/rootfscopy/run
RUN #mkdir -p /tmp/rootfscopy/dev
RUN #mkdir -p /tmp/rootfscopy/proc
RUN mkdir -p /tmp/rootfscopy/var/tmp
RUN mkdir -p /tmp/rootfscopy/boot
RUN #mkdir -p /tmp/rootfscopy/tmp

# 14) Делаем ostree-коммит уже в /sysroot/ostree/repo
RUN ostree --repo=/sysroot/ostree/repo commit \
    --branch=alt/atomic \
    --subject "Initial ALT Atomic Commit" \
    --tree=dir=/tmp/rootfscopy

WORKDIR /
LABEL containers.bootc=1