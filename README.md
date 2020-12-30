# Usage

```
# Clone the source
BRANCH=linux-msft-wsl-5.4.y
git clone --depth=1 --branch=$BRANCH https://github.com/Microsoft/WSL2-Linux-Kernel kernel

# Edit the config
# (or copy some other config to that file)
make -C kernel CC=cc HOSTCC=cc KCONFIG_CONFIG=Microsoft/config-wsl menuconfig


# Make a copy for later building /lib/modules
cp -r kernel kernel-clean

# Build the kernel 
make -C kernel CC=cc HOSTCC=cc KCONFIG_CONFIG=Microsoft/config-wsl -j$(nproc)

# Create the headers
./headers.sh kernel kernel-clean [path/to/headers/install/dir (defaults to /lib/modules/.../build)]
```



