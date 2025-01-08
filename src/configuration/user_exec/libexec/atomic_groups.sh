#!/usr/bin/env bash

# Данный скрипт добавляет юзеров в необходимые группы, срабатывает один раз (или по версии).
GROUP_SETUP_VER=1
GROUP_SETUP_VER_FILE="/etc/atomic/atomic-groups"

# Проверяем выполнение
if [ -f "$GROUP_SETUP_VER_FILE" ]; then
    GROUP_SETUP_VER_RAN="$(cat "$GROUP_SETUP_VER_FILE")"
else
    GROUP_SETUP_VER_RAN=""
fi

# Проверяем выполнение
if [[ -f $GROUP_SETUP_VER_FILE && "$GROUP_SETUP_VER" = "$GROUP_SETUP_VER_RAN" ]]; then
  echo "Group setup has already run. Exiting..."
  exit 0
fi

append_group() {
  local group_name="$1"
  if ! grep -q "^$group_name:" /etc/group; then
    echo "Appending $group_name to /etc/group"
    grep "^$group_name:" /usr/lib/group | tee -a /etc/group > /dev/null
  fi
}

append_group docker
append_group lxd
append_group libvirt

# Получаем всех пользователей из группы "users" (GID 100)
userarray=($(getent group 100 | cut -d ":" -f 4 | tr ',' '\n'))

# Добавляем всех пользователей из группы "users" в необходимые группы
for user in "${userarray[@]}"
do
  usermod -aG docker $user
  usermod -aG lxd $user
  usermod -aG libvirt $user
done

# Запоминаем выполнение вместе с версией скрипта
echo "Writing state file"
echo "$GROUP_SETUP_VER" > "$GROUP_SETUP_VER_FILE"
