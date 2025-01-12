#!/bin/bash

# Создаём пользователя "atomic" и задаём пароль "atomic"
#useradd -m -G wheel -s /bin/bash atomic && \
#echo "atomic:atomic" | chpasswd && \
#mkdir -p /var/home/atomic && chown atomic:atomic /var/home/atomic