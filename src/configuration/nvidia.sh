#!/bin/bash

echo "Running nvidia settings"

touch /usr/lib/bootc/kargs.d/10-nvidia.toml
echo "kargs = [\"nvidia_drm.modeset=1\"]" > /usr/lib/bootc/kargs.d/10-nvidia.toml

# Включаем сервисы
systemctl enable nvidia-suspend
systemctl enable nvidia-hibernate
systemctl enable nvidia-resume

echo "End nvidia settings"