#!/bin/sh
set -e

# Clone the source

BRANCH=linux-msft-wsl-5.10.y
git clone --depth=1 --branch=$BRANCH https://github.com/Microsoft/WSL2-Linux-Kernel kernel

# Apply clang patch
(cd kernel && git apply --ignore-space-change --ignore-whitespace ../clang.patch)

# Copy, edit the config
cat /proc/config.gz | gunzip > kernel-config
make -C kernel CC=cc HOSTCC=cc KCONFIG_CONFIG=../kernel-config oldconfig menuconfig

# Clean the kernel
make -C kernel CC=cc HOSTCC=cc clean mrproper

# Make a copy for later building /lib/modules
cp -r kernel kernel-clean

# Copy config to kernel
cp kernel-config kernel/.config

# Build the kernel 
make -C kernel CC=cc HOSTCC=cc LOCALVERSION= -j$(nproc)

# Create the headers
./headers.sh kernel kernel-clean # [path/to/headers/install/dir (defaults to /lib/modules/.../build)]


