FROM registry.altlinux.org/sisyphus/base:latest

# Копируем скрипты
COPY src /src

# Устанавливаем переменные окружения
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/lib/pkgconfig"
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /src
# Делаем один RUN запуск, потому что увеличние их числа добавляет ненужные слои и увеличивает обьем образа
RUN chmod +x main.sh && ./main.sh

WORKDIR /
# Помечаем образ как bootc совместимый
LABEL containers.bootc=1