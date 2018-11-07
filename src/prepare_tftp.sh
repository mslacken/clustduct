#!/bin/bash
TFTPDIR=${TFTPDIR+/srv/tftpdir}
mkdir -p ${TFTPDIR}/clustduct
mkdir -p ${TFTPDIR}/EFI/x86/
cp /usr/share/syslinux/chain.c32 /usr/share/syslinux/menu.c32 /usr/share/syslinux/pxelinux.0 /usr/share/s
yslinux/reboot.c32 $TFTPDIR
cp /usr/lib64/efi/shim.efi ${TFTPDIR}/EFI/x86/bootx64.efi
cp /usr/lib64/efi/grub.efi ${TFTPDIR}/EFI/x86/
