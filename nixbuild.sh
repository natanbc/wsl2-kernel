#!/usr/bin/env nix-shell
#! nix-shell --pure -p autoconf automake bash bc llvmPackages_17.bintools bison cacert llvmPackages_17.clangUseLLVM cpio curl elfutils flex git gnumake kmod libtool ncurses openssl perl util-linux -i sh
ME="$(dirname -- "$(readlink -f -- "$0")")"
exec "$ME/build.sh" "$@"

