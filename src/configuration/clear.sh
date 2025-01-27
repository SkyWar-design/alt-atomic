#!/bin/bash

# не может control работать в атомарной системе, правами нужно управлять с помощью групп
#rm -rf /etc/control.d/*
rm -rf /src/*
rm -rf /var/root/.cargo
rm -rf /var/root/.rustup
rm -rf /var/root/.cache
truncate -s 0 /var/log/lastlog