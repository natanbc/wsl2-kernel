#!/bin/sh
set -e

# Clone the sources
LINUX_BRANCH="linux-msft-wsl-5.15.y"
ZFS_TAG="zfs-2.1.5"

if [ ! -e kernel-clone ]; then
    git clone --depth=1 --branch="$LINUX_BRANCH"  https://github.com/Microsoft/WSL2-Linux-Kernel kernel-clone
fi

if [ ! -e zfs-clone ]; then
    git clone --depth=1 --branch="$ZFS_TAG"       https://github.com/openzfs/zfs                 zfs-clone
    (cd zfs-clone && git apply ../zfs.patch)
fi

if [ ! -e kernel ]; then 
    cp -r kernel-clone kernel
fi
if [ ! -e zfs ]; then
    cp -r zfs-clone zfs
fi


# i'm done with this shit
# this braindead build system refuses to use the CC/HOSTCC environment variables
# and hardcodes `gcc` instead of `cc` as the default compiler
mkdir -p fuck_this_shitty_build_system
ln -sf "$(command -v cc)" fuck_this_shitty_build_system/gcc
export PATH="$(pwd)/fuck_this_shitty_build_system:$PATH"

# shut up stop adding + to the end of my versions
export LOCALVERSION=""

# the stupid kernel build system doesn't respect these but maybe zfs does
export CC=cc
export HOSTCC=cc

if [ ! -e kernel-config ]; then
    if [ -e /proc/config.gz ]; then
        cat /proc/config.gz | gunzip > kernel-config
        make -C kernel KCONFIG_CONFIG=../kernel-config oldconfig menuconfig
    else
        make -C kernel KCONFIG_CONFIG=../kernel-config defconfig menuconfig
    fi
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
make -C kernel LOCALVERSION= -j$(nproc) CC=clang

# Create the headers
./headers.sh kernel kernel-clean # [path/to/headers/install/dir (defaults to /lib/modules/.../build)]


