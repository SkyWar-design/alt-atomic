#!/bin/bash
set -e

echo "Running ostree.sh"

mkdir -p /sysroot/ostree/repo
ostree --repo=/sysroot/ostree/repo init --mode=archive
mkdir -p /tmp/rootfscopy

rsync -aA \
  --exclude=/dev \
  --exclude=/proc \
  --exclude=/sys \
  --exclude=/run \
  --exclude=/boot \
  --exclude=/tmp \
  --exclude=/var/tmp \
  --exclude=/var/lib/containers \
  --exclude=/var/lib/openvpn/dev \
  --exclude=/output \
  / /tmp/rootfscopy/

mkdir -p /tmp/rootfscopy/var/tmp
ostree --repo=/sysroot/ostree/repo commit --branch=alt/atomic --subject "Initial ALT Atomic Commit" --tree=dir=/tmp/rootfscopy
rm -rf /tmp/rootfscopy

echo "End ostree.sh"