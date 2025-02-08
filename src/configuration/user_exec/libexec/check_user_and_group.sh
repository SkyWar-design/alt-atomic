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
groups=(docker lxd cuse _xfsscrub fuse libvirt adm wheel uucp cdrom cdwriter audio users video netadmin scanner xgrp camera render usershares)

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
# Часть 2. Создание системных групп и пользователей по файлам /usr/etc/group и /usr/etc/passwd
###############################################################################

# Функция для логгирования
log() {
    echo "[INFO] $*"
}

error() {
    echo "[ERROR] $*" >&2
}

# Проверяем наличие файлов
if [ ! -f /usr/etc/group ]; then
    error "/usr/etc/group не найден!"
    exit 1
fi

if [ ! -f /usr/etc/passwd ]; then
    error "/usr/etc/passwd не найден!"
    exit 1
fi

# Ассоциативный массив для сопоставления gid -> group_name из /usr/etc/group
declare -A gid_to_group

log "Обработка файла /usr/etc/group..."
while IFS=: read -r group_name _ gid members; do
    # Если поле gid не является числом – пропускаем
    if ! [[ "$gid" =~ ^[0-9]+$ ]]; then
        continue
    fi
    # Рассматриваем только системные группы (gid < 1000)
    if [ "$gid" -ge 1000 ]; then
        continue
    fi

    # Запоминаем соответствие gid -> group_name для последующего использования
    gid_to_group["$gid"]="$group_name"

    if getent group "$group_name" >/dev/null 2>&1; then
        log "Группа '$group_name' уже существует – пропускаем создание."
    else
        log "Создаём группу '$group_name'..."
        # Создаём системную группу; система подберёт свободный gid
        groupadd --system "$group_name"
    fi
done < /usr/etc/group

log "Обработка файла /usr/etc/passwd..."
while IFS=: read -r username _ uid gid gecos home shell; do
    # Проверяем, что uid является числом; если нет – пропускаем
    if ! [[ "$uid" =~ ^[0-9]+$ ]]; then
        continue
    fi
    # Рассматриваем только системных пользователей (uid < 1000)
    if [ "$uid" -ge 1000 ]; then
        continue
    fi

   if getent passwd "$username" >/dev/null 2>&1; then
       log "Пользователь '$username' уже существует – пропускаем создание."
   else
       # Определяем имя основной группы для пользователя.
       primary_group="${gid_to_group[$gid]:-}"
       if [ -z "$primary_group" ]; then
           primary_group="$username"
           if ! getent group "$primary_group" >/dev/null 2>&1; then
               log "Основная группа '$primary_group' для пользователя '$username' не найдена – создаём."
               groupadd --system "$primary_group"
           fi
       fi

       # Если shell равен '/dev/null', используем корректный путь, например /sbin/nologin.
       effective_shell="$shell"
       if [ "$shell" = "/dev/null" ]; then
            #effective_shell="/sbin/nologin"
            effective_shell="/dev/null"
       fi

       # Если home равен '/dev/null' или TCB-каталог уже существует, используем флаг -M.
       if [ "$home" = "/dev/null" ] || [ -d "/etc/tcb/$username" ]; then
            if [ -d "/etc/tcb/$username" ]; then
                log "TCB-каталог /etc/tcb/$username уже существует, готовлюсь к переименованию."
                if [ -d "/etc/tcb/${username}.bak" ]; then
                    log "Резервный каталог /etc/tcb/${username}.bak уже существует, удаляю его."
                    rm -rf "/etc/tcb/${username}.bak"
                fi
                mv "/etc/tcb/$username" "/etc/tcb/${username}.bak"
            fi
            log "Создаю пользователя '$username' с флагом -M (не создавать домашнюю директорию), основная группа '$primary_group', home='$home', shell='$effective_shell'."
            # Пытаемся создать пользователя с опцией -M; если useradd завершится с ошибкой, игнорируем её.
            if ! useradd --system -M -g "$primary_group" -c "$gecos" -d "$home" -s "$effective_shell" "$username"; then
                log "Ошибка при создании пользователя '$username', возможно, TCB-каталог уже существует."
            fi
            # Если временный каталог был создан, возвращаем его обратно и устанавливаем права.
            if [ -d "/etc/tcb/${username}.bak" ]; then
                log "Восстанавливаю TCB-каталог для пользователя '$username'."
                mv "/etc/tcb/${username}.bak" "/etc/tcb/$username"
                chown "$username:$primary_group" "/etc/tcb/$username"
            fi
       else
            log "Создаю пользователя '$username' с основной группой '$primary_group', home='$home', shell='$effective_shell'."
            useradd --system -g "$primary_group" -c "$gecos" -d "$home" -s "$effective_shell" "$username"
            # Если home не '/dev/null' или '/' и директория отсутствует, создаём её.
            if [[ "$home" != "/dev/null" && "$home" != "/" && ! -d "$home" ]]; then
                log "Создаю директорию '$home' для пользователя '$username'."
                mkdir -p "$home"
                chown "$username:$primary_group" "$home"
            fi
       fi
   fi
done < /usr/etc/passwd

# Дополнительная проверка директорий для всех системных пользователей (uid < 1000)
while IFS=: read -r username _ uid _ _ home _; do
    # Исключаем пользователей с uid >= 1000, а также записи, у которых home равен '/dev/null' или '/',
    # дополнительно исключаем root и nobody, а также директории, начинающиеся с /usr.
    if [[ "$uid" -ge 1000 || "$home" == "/dev/null" || "$home" == "/" || "$username" == "root" || "$username" == "nobody" || "$home" == /usr* ]]; then
        continue
    fi

    if [ -d "$home" ]; then
        log "Директория '$home' для пользователя '$username' уже существует."
    else
        log "Создаю домашнюю директорию '$home' для пользователя '$username'."
        mkdir -p "$home"
        # Получаем основную группу пользователя (четвертое поле)
        primary_group=$(getent passwd "$username" | cut -d: -f4)
        chown "$username:$primary_group" "$home"
    fi
done < /usr/etc/passwd

# Дополнительно: добавляем пользователей в supplementary-группы согласно спискам в /usr/etc/group.
log "Обработка дополнительных членов групп из /usr/etc/group..."
while IFS=: read -r group_name _ _ members; do
    # Если список членов пуст – пропускаем
    [ -z "$members" ] && continue

    # Разбиваем список членов по запятой
    IFS=',' read -ra user_list <<< "$members"
    for member in "${user_list[@]}"; do
        # Удаляем возможные пробелы по краям
        member="$(echo "$member" | xargs)"
        [ -z "$member" ] && continue

        # Проверяем, что пользователь существует и является системным (uid < 1000)
        if user_info=$(getent passwd "$member"); then
            user_uid=$(echo "$user_info" | cut -d: -f3)
            if [ "$user_uid" -ge 1000 ]; then
                continue
            fi
            # Если пользователь уже входит в группу – пропускаем
            if id -nG "$member" | tr ' ' '\n' | grep -qx "$group_name"; then
                log "Пользователь '$member' уже является членом группы '$group_name' – пропускаем."
            else
                log "Добавляем пользователя '$member' в группу '$group_name' как дополнительную."
                usermod -a -G "$group_name" "$member"
            fi
        else
            log "Пользователь '$member' из списка группы '$group_name' не найден в системе – пропускаем."
        fi
    done
done < /usr/etc/group
