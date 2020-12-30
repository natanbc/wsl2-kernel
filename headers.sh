#!/bin/sh

die() {
    echo "$@" 1>&2;
    exit 1;
}

if [ $# -lt 1 ]; then
    die "Usage: $0 path/to/kernel [path/to/headers/install/dir]" 1>&2;
fi

ME=$(dirname $(readlink -f $0))
OBJ=$(mktemp -d)
CONFIG=Microsoft/config-wsl
SRC="$1"

[ -d "$SRC" ]                || die "Unable to find kernel source"
[ -r "$SRC/Module.symvers" ] || die "Please build the kernel"
[ -r "$SRC/$CONFIG" ]        || die "Unable to find config file"

DST=${2:-$(make -C "$SRC" CC=cc HOSTCC=cc -s kernelrelease LOCALVERSION=)}

cp "$SRC/Module.symvers" "$OBJ/"
cp "$SRC/$CONFIG"        "$OBJ/.config"
"$ME/gen_mod_headers" "$DST" "$SRC" "$OBJ"
rm -rf $OBJ
