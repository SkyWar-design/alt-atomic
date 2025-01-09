#!/bin/bash
set -e

echo "Running branding.sh"

echo "Atomic" > /etc/hostname
echo "ID=alt" > /etc/os-release
echo "NAME=\"ALT Atomic Test\"" >> /etc/os-release
echo "VERSION=\"0.1\"" >> /etc/os-release
echo "VERSION_ID=\"0.1\"" >> /etc/os-release

echo "End branding.sh"