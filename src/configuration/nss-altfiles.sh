#!/bin/bash
set -euo pipefail

echo "Запуск скрипта переноса системных записей..."

# Определяем исходные файлы
ETC_PASSWD="/etc/passwd"
ETC_GROUP="/etc/group"

# Определяем файлы для альтернативного хранилища
LIB_PASSWD="/lib/passwd"
LIB_GROUP="/lib/group"

# Создаем временные файлы (в директории /tmp)
TMP_ETC_PASSWD="/tmp/new-etc-passwd.$$"
TMP_LIB_PASSWD="/tmp/new-lib-passwd.$$"
TMP_ETC_GROUP="/tmp/new-etc-group.$$"
TMP_LIB_GROUP="/tmp/new-lib-group.$$"

# Фильтрация /etc/passwd:
# - Записи, которые нужно перенести (системные, кроме root): UID != 0 и UID < 1000
awk -F: '($3 != 0 && $3 < 1000){ print }' "$ETC_PASSWD" > "$TMP_LIB_PASSWD"
# - Записи, которые останутся в /etc: UID == 0 или UID >= 1000
awk -F: '($3 == 0 || $3 >= 1000){ print }' "$ETC_PASSWD" > "$TMP_ETC_PASSWD"

# Фильтрация /etc/group:
# - Переносим записи: GID != 0 и GID < 1000
awk -F: '($3 != 0 && $3 < 1000){ print }' "$ETC_GROUP" > "$TMP_LIB_GROUP"
# - Оставляем записи: GID == 0 или GID >= 1000
awk -F: '($3 == 0 || $3 >= 1000){ print }' "$ETC_GROUP" > "$TMP_ETC_GROUP"

echo "Записи для альтернативного хранилища (системные) отобраны:"
echo "  - $TMP_LIB_PASSWD содержит записи для /lib/passwd"
echo "  - $TMP_LIB_GROUP содержит записи для /lib/group"

# Создаем резервные копии исходных файлов
cp "$ETC_PASSWD" "${ETC_PASSWD}.bak"
cp "$ETC_GROUP" "${ETC_GROUP}.bak"

# Перезаписываем файлы:
mv "$TMP_ETC_PASSWD" "$ETC_PASSWD"
mv "$TMP_LIB_PASSWD" "$LIB_PASSWD"
mv "$TMP_ETC_GROUP" "$ETC_GROUP"
mv "$TMP_LIB_GROUP" "$LIB_GROUP"

echo "End nss-altfiles.sh"