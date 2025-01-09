#!/bin/bash
set -e

echo "Running branding.sh"

echo "Atomic" > /etc/hostname
cat << EOF > /etc/os-release
NAME="ALT Atomic"
VERSION="0.1"
VERSION_ID="0.1"
ID=altlinux
ID_LIKE="altlinux"
PLATFORM_ID="platform:altlinux"
PRETTY_NAME="ALT Atomic"
VARIANT="Atomic"
VARIANT_ID="atomic"
EOF

echo "End branding.sh"