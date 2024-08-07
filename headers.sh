#!/bin/sh
set -e

die() {
    echo "$@" 1>&2;
    exit 1;
}

if [ $# -lt 2 ]; then
    die "Usage: $0 path/to/built/kernel path/to/clean/kernel [path/to/headers/install/dir]" 1>&2;
fi

ME="$(dirname -- $(readlink -f -- "$0"))"
TMP="$(mktemp -d)"
trap "rm -rf $TMP" EXIT

mkdir -p "$TMP/lib/modules"

BUILT="$1"
[ -d "$BUILT" ]                || die "Unable to find built kernel at '$BUILT'"
[ -r "$BUILT/Module.symvers" ] || die "Please build the kernel at '$BUILT'"

SRC="$2"
[ -d "$SRC" ] || die "Unable to find clean kernel at '$SRC'"

make -C "$SRC" mrproper CC="$CC"

VERSION="$(make -C "$BUILT" CC="$CC" -s kernelrelease LOCALVERSION=)"
DST="${3:-lib/modules/$VERSION}"

echo "VER=  $VERSION"
echo "BUILT=$BUILT"
echo "SRC=  $SRC"
echo "DST=  $DST"
#exit 0

BASE="$TMP/lib/modules/$VERSION"
OUT="$BASE/build"
OBJ="$TMP/obj"
mkdir "$OBJ"

cp "$BUILT/Module.symvers" "$OBJ/"
cp "$BUILT/.config"        "$OBJ/.config"
"$ME/gen_mod_headers" "$OUT" "$SRC" "$OBJ"

depmod -b "$TMP" "$VERSION"

if [ -e "$DST" ]; then
    while true; do
        printf "Destination '$DST' already exists, overwrite? [Y/n] "
        read r;
        case "$r" in
            y|Y|"")
                break
                ;;
            n|N)
                def_dir="lib_modules_$VERSION"
                while true; do
                    printf "New destination directory: [$def_dir] "
                    read dir;
                    if [ -z "$dir" ]; then
                        dir="$def_dir"
                    fi
                    if [ -e "$dir" ]; then
                        echo "Directory already exists"
                        continue
                    fi
                    mkdir -p "$(dirname -- "$dir")"
                    mv "$BASE" "$dir"
                    exit 0
                done
                ;;
            *)
                echo "Invalid option"
                ;;
        esac
    done
fi

mkdir -p "$(dirname -- "$DST")"
mv "$BASE" "$DST"
