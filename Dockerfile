FROM registry.altlinux.org/sisyphus/base:latest

# Устанавливаем зависимости
RUN apt-get update && apt-get install -y \
    mount \
    bluez \
    podman \
    btrfs-progs \
    mc \
    nano \
    passwd \
    glibc-utils \
    su \
    sudo \
    which \
    ostree \
    libostree-devel \
    fuse-overlayfs \
    git \
    wget \
    curl \
    losetup \
    build-essential \
    unzip \
    util-linux \
    coreutils \
    systemd \
    dosfstools \
    e2fsprogs \
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
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Настраиваем os-release
RUN echo "ID=alt" > /etc/os-release && \
    echo "NAME=\"ALT Atomic\"" >> /etc/os-release && \
    echo "VERSION=\"6.12 Atomic Build\"" >> /etc/os-release

# Настраиваем OSTree и composefs
RUN mkdir -p /usr/lib/ostree && \
    echo -e "[sysroot]\nreadonly = true" > /usr/lib/ostree/prepare-root.conf
    #echo -e "[composefs]\nenabled = true\n[sysroot]\nreadonly = true" > /usr/lib/ostree/prepare-root.conf

# Скачиваем и собираем zstd
WORKDIR /tmp
RUN wget https://github.com/facebook/zstd/releases/download/v1.5.5/zstd-1.5.5.tar.gz && \
    tar -xzf zstd-1.5.5.tar.gz && \
    cd zstd-1.5.5 && \
    make && make install && \
    cd .. && rm -rf zstd-1.5.5*

# Настраиваем PKG_CONFIG_PATH для поиска libzstd.pc
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/lib/pkgconfig"

# Устанавливаем Rust и Cargo через Rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    . /root/.cargo/env && \
    rustup default stable

# Добавляем путь к Cargo в PATH
ENV PATH="/root/.cargo/bin:${PATH}"


# Скачиваем и собираем bootupd
WORKDIR /tmp
RUN wget https://github.com/coreos/bootupd/archive/refs/tags/v0.2.25.zip -O bootupd.zip && \
    unzip bootupd.zip && \
    cd bootupd-0.2.25 && \
    cargo build --release && \
    install -m 0755 target/release/bootupd /usr/local/bin/bootupd && \
    cd .. && rm -rf bootupd*

# Скачиваем и собираем bootc
WORKDIR /tmp
RUN wget https://github.com/containers/bootc/archive/refs/tags/v1.1.3.zip -O bootc.zip && \
    unzip bootc.zip && \
    cd bootc-1.1.3 && \
    cargo build --release && \
    install -m 0755 target/release/bootc /usr/local/bin/bootc && \
    cd .. && rm -rf bootc*

# Генерация initramfs
RUN dracut --force --kver $(ls /usr/lib/modules | head -n 1)

# Копируем ядро и initramfs в структуру OSTree
RUN cp /boot/vmlinuz-6.12.6-6.12-alt1 /usr/lib/modules/6.12.6-6.12-alt1/vmlinuz && \
    cp /boot/initramfs-6.12.6-6.12-alt1.img /usr/lib/modules/6.12.6-6.12-alt1/initramfs.img

# Добавление файла конфигурации для Podman
#RUN mkdir -p /etc/containers && \
#    echo "[storage]" > /etc/containers/storage.conf && \
#    echo "driver = \"overlay\"" >> /etc/containers/storage.conf && \
#    echo "graphroot = \"/var/lib/containers/storage\"" >> /etc/containers/storage.conf && \
#    echo "runroot = \"/run/containers/storage\"" >> /etc/containers/storage.conf

# Подготовка базовых директорий
RUN mkdir -p /tmp/base-system/etc && \
    mkdir -p /tmp/base-system/var && \
    mkdir -p /tmp/base-system/usr && \
    mkdir -p /tmp/base-system/tmp && \
    echo "Welcome to ALT Atomic!" > /tmp/base-system/tmp/welcome.txt

# Создание символических ссылок
RUN ln -s /usr/bin /tmp/base-system/bin && \
    ln -s /usr/lib /tmp/base-system/lib && \
    ln -s /usr/lib64 /tmp/base-system/lib64 && \
    ln -s /home /tmp/base-system/home && \
    ln -s /mnt /tmp/base-system/mnt && \
    ln -s /var/opt /tmp/base-system/opt

# Инициализация OSTree репозитория
RUN mkdir -p /ostree/repo && \
    ostree --repo=/ostree/repo init --mode=archive

# Добавление первого коммита
RUN ostree --repo=/ostree/repo commit -s "Initial ALT Atomic Commit with kernel and initramfs" \
    -b alt/atomic --tree=dir=/tmp/base-system

# Установка метки для совместимости с bootc
LABEL containers.bootc=1