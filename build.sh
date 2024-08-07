#!/bin/sh
set -euf

# Clone the sources

# linux-msft-wsl-6.6.y / 6.6.36.3
LINUX_COMMIT="149cbd13f7c04e5a9343532590866f31b5844c70"
# 2.2.5
ZFS_COMMIT="33174af15112ed5c53299da2d28e763b0163f428"


DO_MENUCONFIG=0
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --menuconfig)
            DO_MENUCONFIG=1
            shift
            ;;
        *)
            echo "Usage: $0 [--menuconfig]" 1>&2
            exit 1
            ;;
    esac
done


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
export CC=clang
export HOSTCC=clang

if [ ! -e kernel-config ]; then
    if [ -e /proc/config.gz ]; then
        cat /proc/config.gz | gunzip > kernel-config
    fi
fi
make -C kernel LOCALVERSION= KCONFIG_CONFIG=../kernel-config CC=clang clean mrproper prepare scripts

# Add zfs to the kernel
(cd zfs && ./autogen.sh)
(cd zfs && KERNEL_CC=clang ./configure --enable-linux-builtin --with-config=kernel --with-linux=../kernel --with-linux-obj=../kernel)
(cd zfs && ./copy-builtin ../kernel)

if [ "$DO_MENUCONFIG" = 1 ]; then
    make -C kernel LOCALVERSION= KCONFIG_CONFIG=../kernel-config CC=clang menuconfig
fi

sed -Ei "s|.*CONFIG_ZFS[ =].*|CONFIG_ZFS=y|" kernel-config
sed -Ei "s|.*CONFIG_LOCALVERSION_AUTO[ =]*|CONFIG_LOCALVERSION_AUTO=n|" kernel-config

if ! grep -q "CONFIG_ZFS=y" kernel-config; then
    echo "CONFIG_ZFS=y" >> kernel-config
fi

cp kernel-config kernel/.config

# Make a copy for later building /lib/modules
cp -r kernel kernel-clean

# Build the kernel 
make -C kernel LOCALVERSION= CC=clang -j$(nproc)

# Create the headers
./headers.sh kernel kernel-clean # [path/to/headers/install/dir (defaults to lib/modules/.../build)]


