{ pkgs ? import (builtins.fetchTarball {
  name = "nixos-23.11-2024-07-09";
  url = "https://github.com/nixos/nixpkgs/archive/205fd4226592cc83fd4c0885a3e4c9c400efabb5.tar.gz";
  sha256 = "1f5d2g1p6nfwycpmrnnmc2xmcszp804adp16knjvdkj8nz36y1fg";
}) {} }:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    autoconf
    automake
    bash
    bc
    binutils
    bison
    cacert
    cpio
    curl
    elfutils
    flex
    gcc
    git
    gnumake
    kmod
    libtool
    ncurses
    openssl
    perl
    util-linux
  ];
}

