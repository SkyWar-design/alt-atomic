#!/bin/bash
set -euo pipefail

echo "Запуск скрипта nss-altfiles.sh..."

# Исходные файлы
ETC_PASSWD="/etc/passwd"
ETC_GROUP="/etc/group"

# Файлы для альтернативного хранилища
LIB_PASSWD="/lib/passwd"
LIB_GROUP="/lib/group"

# Временные файлы
TMP_ETC_PASSWD="/tmp/new-etc-passwd.$$"
TMP_LIB_PASSWD="/tmp/new-lib-passwd.$$"
TMP_ETC_GROUP="/tmp/new-etc-group.$$"
TMP_LIB_GROUP="/tmp/new-lib-group.$$"

# Фильтрация /etc/passwd:
# Переносим записи для системных пользователей: UID != 0 и UID < 1000
awk -F: '($3 != 0 && $3 < 1000){ print }' "$ETC_PASSWD" > "$TMP_LIB_PASSWD"
# В /etc оставляем записи: UID == 0 или UID >= 1000
awk -F: '($3 == 0 || $3 >= 1000){ print }' "$ETC_PASSWD" > "$TMP_ETC_PASSWD"

# Фильтрация /etc/group:
# Для альтернативного файла переносим только группы с GID != 0 и GID < 1000,
# при этом исключаем группу "wheel" (она должна остаться в /etc).
awk -F: '($1 != "wheel") && ($3 != 0 && $3 < 1000){ print }' "$ETC_GROUP" > "$TMP_LIB_GROUP"
# В /etc оставляем группы, где GID == 0 или GID >= 1000, а также группу "wheel"
awk -F: '($3 == 0 || $3 >= 1000 || $1 == "wheel"){ print }' "$ETC_GROUP" > "$TMP_ETC_GROUP"

echo "Записи для альтернативного хранилища отобраны:"
echo "  - $TMP_LIB_PASSWD содержит системные записи для /lib/passwd"
echo "  - $TMP_LIB_GROUP содержит записи (за исключением 'wheel') для /lib/group"

# Создаем резервные копии исходных файлов
cp "$ETC_PASSWD" "${ETC_PASSWD}.bak"
cp "$ETC_GROUP" "${ETC_GROUP}.bak"

# Перезаписываем файлы
mv "$TMP_ETC_PASSWD" "$ETC_PASSWD"
mv "$TMP_LIB_PASSWD" "$LIB_PASSWD"
mv "$TMP_ETC_GROUP" "$ETC_GROUP"
mv "$TMP_LIB_GROUP" "$LIB_GROUP"

echo "Перенос завершен."
echo "В /lib/passwd находятся системные учётные записи (UID от 1 до 999)."
echo "В /lib/group находятся группы с GID от 1 до 999, кроме группы 'wheel'."
echo "В /etc/passwd остались записи с UID 0 или ≥ 1000."
echo "В /etc/group остались группы с GID 0 или ≥ 1000, а также группа 'wheel'."

echo "End nss-altfiles.sh"