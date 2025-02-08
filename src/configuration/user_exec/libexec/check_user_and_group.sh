#!/bin/bash
# Скрипт объединяет учетные записи и группы из базовых файлов (/usr/etc/passwd и /usr/etc/group)
# с локальными (/etc/passwd и /etc/group) в режиме bootc usr-overlay.
# Основная идея:
#   - Для passwd: оставить записи с UID>=1000 из локального файла и взять системные (UID<1000)
#     из базового файла.
#   - Для group: итоговый merged-файл должен содержать все группы из базового файла,
#     а также локальные группы, отсутствующие в базовом, если они являются primary для каких-либо пользователей.
#
# Перед запуском сделайте резервные копии /etc/passwd и /etc/group.
#
set -euo pipefail

echo "=== Начало синхронизации пользователей и групп ==="

###############################################################################
# Часть 1. Добавление пользователей в указанные дополнительные группы
###############################################################################
groups_to_add=(docker lxd cuse fuse libvirt adm wheel uucp cdrom cdwriter audio users video netadmin scanner xgrp camera render usershares)

# Получаем всех пользователей с UID >= 1000, исключая "nobody"
userarray=($(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd))
if [[ ${#userarray[@]} -eq 0 ]]; then
    echo "Нет пользователей с UID >= 1000."
    exit 0
fi

for user in "${userarray[@]}"; do
    echo "Обрабатываем пользователя $user..."
    for grp in "${groups_to_add[@]}"; do
        if ! getent group "$grp" >/dev/null 2>&1; then
            echo "Группа $grp не существует, пропускаем для $user."
            continue
        fi
        if id -nG "$user" | tr ' ' '\n' | grep -qx "$grp"; then
            echo "Пользователь $user уже в группе $grp, пропускаем."
        else
            echo "Добавляем пользователя $user в группу $grp..."
            usermod -aG "$grp" "$user"
        fi
    done
done

###############################################################################
# Часть 2. Объединение /etc/passwd
###############################################################################
BASE_PASSWD="/usr/etc/passwd"
LOCAL_PASSWD="/etc/passwd"
MERGED_PASSWD="/tmp/merged-passwd.$$"

declare -A base_passwd_arr   # username -> полная строка из базового файла
declare -A local_passwd_arr  # username -> полная строка из локального файла

# Чтение базового файла (предполагается, что здесь только системные аккаунты)
while IFS=: read -r username passwd uid gid gecos home shell; do
    [[ -z "$username" ]] && continue
    base_passwd_arr["$username"]="${username}:${passwd}:${uid}:${gid}:${gecos}:${home}:${shell}"
done < "$BASE_PASSWD"

# Чтение локального файла
while IFS=: read -r username passwd uid gid gecos home shell; do
    [[ -z "$username" ]] && continue
    local_passwd_arr["$username"]="${username}:${passwd}:${uid}:${gid}:${gecos}:${home}:${shell}"
done < "$LOCAL_PASSWD"

# Формируем новый merged-файл.
> "$MERGED_PASSWD"

# Сначала добавляем локальные записи для пользователей с UID>=1000 (обычные пользователи)
for username in "${!local_passwd_arr[@]}"; do
    IFS=: read -r _ _ local_uid _ _ _ _ <<< "${local_passwd_arr[$username]}"
    if (( local_uid >= 1000 )); then
        echo "${local_passwd_arr[$username]}" >> "$MERGED_PASSWD"
    fi
done

# Затем добавляем системные записи (UID<1000) из базового файла
for username in "${!base_passwd_arr[@]}"; do
    IFS=: read -r _ _ base_uid _ _ _ _ <<< "${base_passwd_arr[$username]}"
    if (( base_uid < 1000 )); then
        echo "${base_passwd_arr[$username]}" >> "$MERGED_PASSWD"
    fi
done

sort "$MERGED_PASSWD" -o "$MERGED_PASSWD"
echo "Объединение /etc/passwd завершено. Результат: $MERGED_PASSWD"

cp "$LOCAL_PASSWD" "${LOCAL_PASSWD}.bak"
mv "$MERGED_PASSWD" "$LOCAL_PASSWD"
echo "/etc/passwd обновлён."

###############################################################################
# Часть 3. Объединение /etc/group
###############################################################################
BASE_GROUP="/usr/etc/group"
LOCAL_GROUP="/etc/group"
MERGED_GROUP="/tmp/merged-group.$$"

declare -A base_group_arr  # group -> полная строка из базового файла
declare -A base_gid_arr    # group -> gid из базового файла
declare -A local_group_arr # group -> полная строка из локального файла

# Чтение базового файла групп
while IFS=: read -r grp pwd gid members; do
    [[ -z "$grp" ]] && continue
    base_group_arr["$grp"]="${grp}:${pwd}:${gid}:${members}"
    base_gid_arr["$grp"]="$gid"
done < "$BASE_GROUP"

# Чтение локального файла групп
while IFS=: read -r grp pwd gid members; do
    [[ -z "$grp" ]] && continue
    local_group_arr["$grp"]="${grp}:${pwd}:${gid}:${members}"
done < "$LOCAL_GROUP"

# Составляем список основных групп, используемых в /etc/passwd.
# Для каждого пользователя (например, с UID>=1000 и системных) определяем primary group по 4-му полю.
declare -A primary_groups  # group_name -> 1
while IFS=: read -r username _ _ gid _; do
    grp_name=$(getent group "$gid" | cut -d: -f1)
    if [[ -n "$grp_name" ]]; then
        primary_groups["$grp_name"]=1
    fi
done < "$LOCAL_PASSWD"

> "$MERGED_GROUP"

# 1. Для групп, присутствующих в базовом файле: используем их,
#    если локально есть такая группа, обновляем GID, оставляя прочие поля.
for grp in "${!base_group_arr[@]}"; do
    base_gid_val="${base_gid_arr[$grp]}"
    if [[ -n "${local_group_arr[$grp]:-}" ]]; then
        IFS=: read -r lgrp lpwd lgid lmembers <<< "${local_group_arr[$grp]}"
        if [[ "$lgid" != "$base_gid_val" ]]; then
            echo "Обновление группы '$grp': локальный GID $lgid заменяется на базовый GID $base_gid_val."
            lgid="$base_gid_val"
        fi
        echo "${grp}:${lpwd}:${lgid}:${lmembers}" >> "$MERGED_GROUP"
    else
        echo "Добавление группы '$grp' из базового файла, так как её нет в /etc/group."
        echo "${base_group_arr[$grp]}" >> "$MERGED_GROUP"
    fi
done

# 2. Добавляем в итоговый merged-файл те группы, которые есть в локальном файле,
#    но отсутствуют в базовом, если они являются основными для каких-либо пользователей.
for grp in "${!local_group_arr[@]}"; do
    if [[ -z "${base_group_arr[$grp]:-}" ]]; then
        if [[ -n "${primary_groups[$grp]:-}" ]]; then
            echo "Сохраняется локальная группа '$grp', так как она является основной для пользователя."
            echo "${local_group_arr[$grp]}" >> "$MERGED_GROUP"
        else
            echo "Удаление локальной группы '$grp', отсутствующей в базовом файле и не являющейся основной."
        fi
    fi
done

sort "$MERGED_GROUP" -o "$MERGED_GROUP"
echo "Объединение /etc/group завершено. Результат: $MERGED_GROUP"

cp "$LOCAL_GROUP" "${LOCAL_GROUP}.bak"
mv "$MERGED_GROUP" "$LOCAL_GROUP"
echo "/etc/group обновлён."

echo "=== Синхронизация завершена ==="