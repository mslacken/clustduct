AUTOMAKE_OPTIONS = foreign

sbin_SCRIPTS = src/clustduct.lua src/write_bf.lua

luaexec_SCRIPTS = src/bfcommons.lua

clustductconfddir = $(sysconfdir)/clustduct.d
clustductconfd_DATA = configs/grub_iptemplate configs/pxe_iptemplate configs/clustduct.conf

clustductconfdir = $(sysconfdir)
clustductconf_DATA = configs/clustduct.conf

clustductdocdir = $(docdir)
clustductdoc_DATA = doc/* Usage.md COPYING Bugs.md

#FIXME Evil hack to point to the real /
tftpdir= $(prefix)/../srv/tftpboot/pxelinux.cfg
tftp_DATA = configs/default

efidir = $(prefix)/../srv/tftpboot/EFI/x86
efi_DATA = configs/grub.cfg

