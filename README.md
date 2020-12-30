# Usage

- Clone the source: https://github.com/Microsoft/WSL2-Linux-Kernel
- Edit the config (`make CC=cc HOSTCC=cc KCONFIG_CONFIG=Microsoft/config-wsl menuconfig`)
- Build the kernel (`make CC=cc HOSTCC=cc KCONFIG_CONFIG=Microsoft/config-wsl -j$(nproc)`)
- Run `./headers.sh path/to/clone [path/to/headers/install/dir]`


