# Jumploader

This repository contains the tools to build a minimal Linux kernel image
which can then be booted directly as an EFI executable in order to
jump into another Linux installation.

## How to build

Get the nix package manager or use a nix docker image and then run `nix build .#kernelWithInitrd"`.
The resulting kernel image can be found in `result/bzImage`. Since this kernel has EFISTUB enabled,
you may directly boot it as an EFI application (i.e. `mv result/bzImage jumploader.efi`).

## How to use

The built system looks for a partition with the label `rootfs` and then attempts to locate
`$rootfs/boot/vmlinuz` and `$rootfs/boot/initrd.img`.
