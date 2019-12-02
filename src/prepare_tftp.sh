#!/bin/bash
TFTPDIR=${TFTPDIR-/srv/tftpboot}
test -d $TFTPDIR || mkdir -pv $TFTPDIR
cp -v /usr/share/syslinux/chain.c32 /usr/share/syslinux/menu.c32 /usr/share/syslinux/pxelinux.0 /usr/share/syslinux/reboot.c32 $TFTPDIR
mkdir -pv ${TFTPDIR}/pxelinux.cfg/
cp -v /usr/share/doc/clustduct/default.example ${TFTPDIR}/pxelinux.cfg/default
mkdir -pv ${TFTPDIR}/EFI/x86/
cp -v /usr/lib64/efi/shim.efi ${TFTPDIR}/EFI/x86/bootx64.efi
cp -v /usr/lib64/efi/grub.efi ${TFTPDIR}/EFI/x86/
cp -v /usr/share/doc/clustduct/grub.cfg ${TFTPDIR}/EFI/x86/
mkdir -pv ${TFTPDIR}/clustduct
