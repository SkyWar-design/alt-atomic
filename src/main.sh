#!/bin/bash
set -e

echo "Running main.sh..."

./install/branding.sh
./install/settings.sh
./install/kernel.sh
./make/bootupd.sh
./make/bootc.sh
./install/ostree.sh

echo "All scripts executed successfully."