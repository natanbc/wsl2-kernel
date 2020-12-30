#!/bin/sh

die() {
    echo "$@" 1>&2;
    exit 1;
}

if [ $# -lt 2 ]; then
    die "Usage: $0 path/to/built/kernel path/to/clean/kernel [path/to/headers/install/dir]" 1>&2;
fi

ME=$(dirname $(readlink -f $0))
OBJ=$(mktemp -d)
OUT=$(mktemp -d)
CONFIG=Microsoft/config-wsl

BUILT="$1"
[ -d "$BUILT" ]                || die "Unable to find built kernel"
[ -r "$BUILT/Module.symvers" ] || die "Please build the kernel"
[ -r "$BUILT/$CONFIG" ]        || die "Unable to find config file"

SRC="$2"
[ -d "$SRC" ] || die "Unable to find clean kernel"

DST=${3:-/lib/modules/$(make -C "$SRC" CC=cc HOSTCC=cc -s kernelrelease LOCALVERSION=)/build}

echo "BUILT=$BUILT"
echo "SRC=  $SRC"
echo "DST=  $DST"
#exit 0

cp "$BUILT/Module.symvers" "$OBJ/"
cp "$BUILT/$CONFIG"        "$OBJ/.config"
"$ME/gen_mod_headers" "$OUT" "$SRC" "$OBJ"

mkdir -p "$(dirname "$DST")"
mv "$OUT" "$DST"

rm -rf "$OBJ" "$OUT"
