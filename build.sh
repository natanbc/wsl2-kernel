#!/bin/sh
set -e

# Clone the sources
LINUX_BRANCH="linux-msft-wsl-5.10.y"
ZFS_TAG="zfs-2.0.6"

git clone --depth=1 --branch="$LINUX_BRANCH"  https://github.com/Microsoft/WSL2-Linux-Kernel kernel
git clone --depth=1 --branch="$ZFS_TAG"       https://github.com/openzfs/zfs                 zfs

# Apply clang patch
(cd kernel && git apply ../clang.patch)

# i'm done with this shit
# this braindead build system refuses to use the CC/HOSTCC environment variables
# and hardcodes `gcc` instead of `cc` as the default compiler
mkdir -p fuck_this_shitty_build_system
ln -sf "$(command -v cc)" fuck_this_shitty_build_system/gcc
export PATH="$PATH:$(pwd)/fuck_this_shitty_build_system"

# shut up stop adding + to the end of my versions
export LOCALVERSION=""

# the stupid kernel build system doesn't respect these but maybe zfs does
export CC=cc
export HOSTCC=cc

if [ -e /proc/config.gz ]; then
    cat /proc/config.gz | gunzip > kernel-config
    make -C kernel KCONFIG_CONFIG=../kernel-config oldconfig menuconfig
else
    make -C kernel KCONFIG_CONFIG=../kernel-config defconfig menuconfig
fi
make -C kernel clean mrproper

cp kernel-config kernel/.config


sed -i "s|.*CONFIG_LOCALVERSION_AUTO.*|CONFIG_LOCALVERSION_AUTO=n|" kernel/.config
make -C kernel prepare scripts
sed -i "s|.*CONFIG_LOCALVERSION_AUTO.*|CONFIG_LOCALVERSION_AUTO=n|" kernel/.config

echo "CONFIG_ZFS=y" >> kernel/.config

# Add zfs to the kernel
(cd zfs && ./autogen.sh)
(cd zfs && ./configure --enable-linux-builtin --with-config=kernel --with-linux=../kernel --with-linux-obj=../kernel)
(cd zfs && ./copy-builtin ../kernel)

# Make a copy for later building /lib/modules
cp -r kernel kernel-clean

# Build the kernel 
make -C kernel LOCALVERSION= -j$(nproc)

# Create the headers
./headers.sh kernel kernel-clean # [path/to/headers/install/dir (defaults to /lib/modules/.../build)]


