#!/bin/bash

echo "Installing nvidia packages"

apt-get install -y apt-repo-lakostis-kmodules apt-repo-lakostis && \
apt-get update && \
apt-get install -y kernel-modules-nvidia-open-6.12 libnvidia-opencl libnvoptix cuda-libs

echo "End installing nvidia packages"