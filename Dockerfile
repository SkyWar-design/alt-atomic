FROM registry.altlinux.org/sisyphus/base:latest AS builder

# Устанавливаем переменные окружения
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/lib/pkgconfig" \
    PATH="/root/.cargo/bin:${PATH}"

# Копируем скрипты
COPY src /src

WORKDIR /src

# Выполняем скрипт сборки с кэшированием
RUN --mount=type=cache,target=/var/cache/apt \
    ./main.sh

# Финальный этап
FROM registry.altlinux.org/sisyphus/base:latest

# Копируем только необходимые файлы из этапа сборки
COPY --from=builder /src /src

# Устанавливаем переменные окружения
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/lib/pkgconfig" \
    PATH="/root/.cargo/bin:${PATH}"

WORKDIR /

# Помечаем образ как bootc совместимый
LABEL containers.bootc=1

# Оптимизация для Buildx
ARG BUILDKIT_INLINE_CACHE=1

CMD /sbin/init