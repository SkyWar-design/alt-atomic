#!/bin/bash
# Причина этого скрипта в том что ALT не поддерживает systemd-sysusers. Смотреть https://lists.altlinux.org/pipermail/devel-distro/2025-January/003139.html
# Скрипт добавляет необходимые группы в пользователей, а та же синхронизирует системные группы и пользователей на основе файлов из ostree коммита /usr/etc/group и /usr/etc/passwd
#
# uid и gid назначаются динамически.
#

set -euo pipefail

###############################################################################
# Часть 1. Добавление пользователей в указанные дополнительные группы
###############################################################################

# Массив групп, в которые нужно добавить пользователей
groups=(docker lxd cuse fuse libvirt adm wheel uucp cdrom cdwriter audio users video netadmin scanner xgrp camera render usershares)

# Получаем всех пользователей с UID >= 1000, исключая nobody
userarray=($(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd))

# Проверяем, есть ли пользователи
if [[ ${#userarray[@]} -eq 0 ]]; then
    echo "No users with UID >= 1000 found."
    exit 0
fi

# Добавляем пользователей в указанные группы
for user in "${userarray[@]}"; do
    echo "Обрабатываем пользователя $user..."
    for group in "${groups[@]}"; do
        # Проверяем, существует ли группа
        if ! getent group "$group" >/dev/null 2>&1; then
            echo "Группа $group не существует, пропускаем добавление для пользователя $user."
            continue
        fi

        # Проверяем, состоит ли пользователь уже в группе
        if id -nG "$user" | tr ' ' '\n' | grep -qx "$group"; then
            echo "Пользователь $user уже состоит в группе $group, пропускаем."
        else
            echo "Добавляем пользователя $user в группу $group..."
            usermod -aG "$group" "$user"
        fi
    done
done

###############################################################################
# Часть 2. Объединение /etc/passwd
###############################################################################

BASE_PASSWD="/usr/etc/passwd"
LOCAL_PASSWD="/etc/passwd"
MERGED_PASSWD="/tmp/merged-passwd.$$"

declare -A base_passwd    # Ассоциативный массив: username -> полная строка из базового файла
declare -A local_passwd   # Ассоциативный массив: username -> полная строка из локального файла

# Чтение базового файла (предполагается, что здесь только системные аккаунты)
while IFS=: read -r username passwd uid gid gecos home shell; do
    [[ -z "$username" ]] && continue
    base_passwd["$username"]="${username}:${passwd}:${uid}:${gid}:${gecos}:${home}:${shell}"
done < "$BASE_PASSWD"

# Чтение локального файла
while IFS=: read -r username passwd uid gid gecos home shell; do
    [[ -z "$username" ]] && continue
    local_passwd["$username"]="${username}:${passwd}:${uid}:${gid}:${gecos}:${home}:${shell}"
done < "$LOCAL_PASSWD"

# Создаем новый merged-файл.
> "$MERGED_PASSWD"

# Сначала записываем локальные учётные записи для пользователей с UID >= 1000 (обычные)
for username in "${!local_passwd[@]}"; do
    IFS=: read -r _ _ local_uid _ _ _ _ <<< "${local_passwd[$username]}"
    if (( local_uid >= 1000 )); then
        echo "${local_passwd[$username]}" >> "$MERGED_PASSWD"
    fi
done

# Затем для системных учетных записей (UID < 1000) берем базовые записи.
for username in "${!base_passwd[@]}"; do
    IFS=: read -r _ _ base_uid _ _ _ _ <<< "${base_passwd[$username]}"
    if (( base_uid < 1000 )); then
        echo "${base_passwd[$username]}" >> "$MERGED_PASSWD"
    fi
done

# Сортируем итоговый файл по, например, username (при необходимости)
sort "$MERGED_PASSWD" -o "$MERGED_PASSWD"

echo "Объединение /etc/passwd завершено. Результат: $MERGED_PASSWD"

# Резервное копирование локального файла passwd
cp "$LOCAL_PASSWD" "${LOCAL_PASSWD}.bak"
# Замена локального файла объединённым файлом
mv "$MERGED_PASSWD" "$LOCAL_PASSWD"
echo "/etc/passwd обновлён."

###############################################################################
# Часть 3. Объединение /etc/group
###############################################################################

BASE_GROUP="/usr/etc/group"
LOCAL_GROUP="/etc/group"
MERGED_GROUP="/tmp/merged-group.$$"

declare -A base_gid         # base_gid[group] = gid из базового файла
declare -A base_group_line  # base_group_line[group] = полная строка из базового файла
declare -A local_group_line # local_group_line[group] = полная строка из локального файла

# Читаем базовый файл групп
while IFS=: read -r grp pwd gid members; do
    [[ -z "$grp" ]] && continue
    base_gid["$grp"]="$gid"
    base_group_line["$grp"]="${grp}:${pwd}:${gid}:${members}"
done < "$BASE_GROUP"

# Читаем локальный файл групп
while IFS=: read -r grp pwd gid members; do
    [[ -z "$grp" ]] && continue
    local_group_line["$grp"]="${grp}:${pwd}:${gid}:${members}"
done < "$LOCAL_GROUP"

> "$MERGED_GROUP"

# Проходим по группам из базового файла: итоговый список должен содержать только группы, присутствующие в базовом файле.
for grp in "${!base_group_line[@]}"; do
    base_gid_val="${base_gid[$grp]}"
    if [[ -n "${local_group_line[$grp]:-}" ]]; then
        # Группа присутствует локально – проверяем GID
        IFS=: read -r lgrp lpwd lgid lmembers <<< "${local_group_line[$grp]}"
        if [[ "$lgid" != "$base_gid_val" ]]; then
            echo "Обновление группы '$grp': локальный GID $lgid заменяется на базовый GID $base_gid_val."
            lgid="$base_gid_val"
        fi
        echo "${grp}:${lpwd}:${lgid}:${lmembers}" >> "$MERGED_GROUP"
    else
        echo "Добавление группы '$grp' из базового файла, так как она отсутствует в /etc/group."
        echo "${base_group_line[$grp]}" >> "$MERGED_GROUP"
    fi
done

# Удаляем из локального файла те группы, которых нет в базовом файле.
# (По условию итоговый список должен содержать только группы из базового файла.)
# Для наглядности можно вывести сообщение о том, какие группы будут удалены.
TMP_LOCAL="/tmp/new-local-group.$$"
> "$TMP_LOCAL"
while IFS=: read -r grp rest; do
    if [[ -n "${base_group_line[$grp]:-}" ]]; then
        echo "${grp}:${rest}" >> "$TMP_LOCAL"
    else
        echo "Удаление локальной группы '$grp', отсутствующей в базовом файле."
    fi
done < "$LOCAL_GROUP"
# Но итоговый merged-файл уже сформирован только на основе базового набора.
sort "$MERGED_GROUP" -o "$MERGED_GROUP"

echo "Объединение /etc/group завершено. Результат: $MERGED_GROUP"

cp "$LOCAL_GROUP" "${LOCAL_GROUP}.bak"
mv "$MERGED_GROUP" "$LOCAL_GROUP"
echo "/etc/group обновлён."

echo "=== Объединение завершено ==="