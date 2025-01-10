#!/bin/bash
set -euo pipefail

echo "Running bootupd.sh"

# Define repository and paths
BOOTUPD_REPO="https://github.com/SkyWar-design/bootupd.git"
BOOTUPD_BUILD_DIR="/tmp/bootupd"

# Clone the repository
cd /tmp
echo "Cloning bootupd repository from ${BOOTUPD_REPO}..."
git clone "${BOOTUPD_REPO}" "${BOOTUPD_BUILD_DIR}"

# Change to the build directory
cd "${BOOTUPD_BUILD_DIR}"

# Build the project with Cargo
echo "Building bootupd..."
cargo build --release

# Install bootupd and create symlinks
echo "Installing bootupd..."
install -m 0755 target/release/bootupd /usr/local/bin/bootupd
ln -sf /usr/local/bin/bootupd /usr/local/bin/bootupctl
ln -sf /usr/local/bin/bootupd /usr/bin/bootupctl

# Remove temporary files
echo "Cleaning up..."
cd /tmp
rm -rf "${BOOTUPD_BUILD_DIR}"

echo "End bootupd"