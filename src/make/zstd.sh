#!/bin/bash
set -e

echo "Running zstd.sh"

cd /tmp
wget https://github.com/facebook/zstd/releases/download/v1.5.5/zstd-1.5.5.tar.gz
tar -xzf zstd-1.5.5.tar.gz
cd zstd-1.5.5
make
make install
cd ..
rm -rf zstd-1.5.5 zstd-1.5.5.tar.gz

cd /tmp
echo "End zstd.sh"