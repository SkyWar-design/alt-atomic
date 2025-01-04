FROM registry.altlinux.org/sisyphus/base:latest

# Устанавливаем зависимости и копируем скрипты
RUN apt-get update && apt-get install -y \
    mount \
    bluez \
    podman \
    btrfs-progs \
    mc \
    nano \
    passwd \
    bubblewrap \
    efivar \
    shim-unsigned  \
    libselinux \
    policycoreutils \
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

# Копируем скрипты
COPY src /src

# Устанавливаем переменные окружения
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/lib/pkgconfig"
ENV PATH="/root/.cargo/bin:${PATH}"

# В глановм Dockerfile делаем один RUN запуск потому что увеличние их числа - добавляет ненужные слои и увеличивает обьем образа
# Делаем главный скрипт исполняемым и запускаем его
WORKDIR /src
RUN chmod +x main.sh && ./main.sh

LABEL containers.bootc=1