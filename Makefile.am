AUTOMAKE_OPTIONS = foreign

sbin_SCRIPTS = src/clustduct.lua src/write_bf.lua

luaexec_SCRIPTS = src/bfcommons.lua

clustductconfdir = $(sysconfdir)/clustduct.d
clustductconf_DATA = configs/grub_iptemplate configs/pxe_iptemplate

clustductdocdir = $(docdir)
clustductdoc_DATA = doc/* Usage.md COPYING Bugs.md

tftpdir= $(prefix)/srv/tftpboot
tftpdir_DATA = configs/defaults

efidir = $(prefix)/srv/tftpboot/EFI/x86
efidir_DATA = configs/grub.cfg

