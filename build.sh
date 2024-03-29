#!/bin/sh
set -euf

# Clone the sources

# linux-msft-wsl-5.15.y / 5.15.79.1
LINUX_COMMIT="7ade21a9d938a1b39c1754156537782a4be5dc50"
# 2.1.7
ZFS_COMMIT="21bd7661334cd865d17934bebbcaf8d3356279ee"

get_repo() {
    mkdir "$3"
    curl -L "https://github.com/$1/archive/$2.tar.gz" | tar --strip-components=1 -C "$3" -xzf -
}

if [ ! -e kernel-clone ]; then
    get_repo "Microsoft/WSL2-Linux-Kernel" "$LINUX_COMMIT" kernel-clone
fi

if [ ! -e zfs-clone ]; then
    get_repo "openzfs/zfs"                 "$ZFS_COMMIT"   zfs-clone
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


