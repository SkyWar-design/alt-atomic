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
    echo "Creating group $group_name"
    groupadd "$group_name"
  fi
}

append_group docker
append_group lxd
append_group libvirt

# Получаем всех пользователей с UID >= 1000
userarray=($(awk -F: '$3 >= 1000 {print $1}' /etc/passwd))

# Проверяем, есть ли пользователи
if [[ ${#userarray[@]} -eq 0 ]]; then
  echo "No users with UID >= 1000 found."
  exit 0
fi

# Добавляем пользователей в необходимые группы
for user in "${userarray[@]}"; do
  echo "Adding user $user to groups"
  usermod -aG docker $user
  usermod -aG lxd $user
  usermod -aG fuse $user
  usermod -aG libvirt $user
done

# Запоминаем выполнение вместе с версией скрипта
echo "Writing state file"
echo "$GROUP_SETUP_VER" > "$GROUP_SETUP_VER_FILE"
