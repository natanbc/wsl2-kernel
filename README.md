# Usage

## Clone the source

```
git clone https://github.com/Microsoft/WSL2-Linux-Kernel kernel
```

## Edit the config

```
make -C kernel CC=cc HOSTCC=cc KCONFIG_CONFIG=Microsoft/config-wsl menuconfig
```


## Make a copy

```
cp -r kernel kernel-clean
```

## Build the kernel 

```
make -C kernel CC=cc HOSTCC=cc KCONFIG_CONFIG=Microsoft/config-wsl -j$(nproc)
```

## Create the headers

```
./headers.sh kernel kernel-clean [path/to/headers/install/dir (defaults to /lib/modules/.../build)]
```



