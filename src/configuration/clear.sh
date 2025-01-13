#!/bin/bash

# не может control работать в атомарной системе, правами нужно управлять с помощью групп
rm -rf /etc/control.d/*
rm -rf /src/*
rm -rf /home/root/*
truncate -s 0 /var/log/lastlog