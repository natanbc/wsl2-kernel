#!/bin/sh
set -e

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

BUILT="$1"
[ -d "$BUILT" ]                || die "Unable to find built kernel at '$BUILT'"
[ -r "$BUILT/Module.symvers" ] || die "Please build the kernel at '$BUILT'"

SRC="$2"
[ -d "$SRC" ] || die "Unable to find clean kernel at '$SRC'"

make -C "$SRC" mrproper CC=cc HOSTCC=cc

DST=${3:-/lib/modules/$(make -C "$BUILT" CC=cc HOSTCC=cc -s kernelrelease LOCALVERSION=)/build}

echo "BUILT=$BUILT"
echo "SRC=  $SRC"
echo "DST=  $DST"
#exit 0

cp "$BUILT/Module.symvers" "$OBJ/"
cp "$BUILT/.config"        "$OBJ/.config"
"$ME/gen_mod_headers" "$OUT" "$SRC" "$OBJ"

echo "Copying results... (press enter)"
read meme
sudo mkdir -p "$(dirname "$DST")"
sudo mv "$OUT" "$DST"

rm -rf "$OBJ" "$OUT"
