#!/bin/bash
set -e

echo "Running branding.sh"

echo "ID=alt" > /etc/os-release
echo "NAME=\"ALT Atomic\"" >> /etc/os-release
echo "VERSION=\"6.12 Atomic Build\"" >> /etc/os-release

echo "ENd branding.sh"