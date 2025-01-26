FROM registry.altlinux.org/sisyphus/base:latest

# Копируем скрипты
COPY src /src

# Устанавливаем переменные окружения
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/lib/pkgconfig"
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /src

# Базовые пакеты для работы системы
RUN ./packages/apt_prepare.sh
RUN ./packages/base.sh
RUN ./packages/DE/GNOME/gnome.sh
RUN ./packages/apt_ending.sh

# Настройка
RUN ./configuration/branding.sh
RUN ./configuration/settings.sh
RUN ./configuration/user.sh
RUN ./configuration/kernel.sh
RUN ./make/zstd.sh
RUN ./make/cargo.sh
RUN ./make/bootupd.sh
RUN ./make/bootc.sh
RUN ./make/brew.sh
RUN ./make/zsh-plugins.sh
RUN ./make/atomic-actions.sh
RUN ./configuration/clear.sh

# Делаем один RUN запуск, потому что увеличние их числа добавляет ненужные слои и увеличивает обьем образа
# RUN chmod +x main.sh && ./main.sh

WORKDIR /
# Помечаем образ как bootc совместимый
LABEL containers.bootc=1

# Оптимизация для Buildx
ARG BUILDKIT_INLINE_CACHE=1