#!/usr/bin/env bash

name=2happyOS
file=zig-out/bin/kernel

if grub-file --is-x86-multiboot $file; then
  echo multiboot confirmed
else
  echo the file is not multiboot
fi

mkdir -p iso/boot/grub
cp $file iso/boot/$name
cp iso/grub.cfg iso/boot/grub/grub.cfg
grub-mkrescue -o $name.iso iso &> /dev/null


qemu-system-i386 -display gtk -cdrom $name.iso
