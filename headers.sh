#!/bin/sh

if [ $# -lt 2 ]; then
    echo "Usage: $0 path/to/kernel path/to/headers/install/dir" 1>&2;
    exit 1;
fi

ME=$(dirname $(readlink -f $0))
D=$(mktemp -d)
cp "$1/Module.symvers" "$D/"
cp "$1/Microsoft/config-wsl" "$D/.config"
"$ME/gen_mod_headers" "$2" "$1" "$D"
rm -rf $D
