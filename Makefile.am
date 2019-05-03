AUTOMAKE_OPTIONS = foreign

sbin_SCRIPTS = src/clustduct.lua src/write_bf.lua src/prepare_tftp.sh

luaexec_SCRIPTS = src/bfcommons.lua

clustductconfddir = $(sysconfdir)/clustduct.d
clustductconfd_DATA = configs/grub_iptemplate configs/pxe_iptemplate configs/clustduct.conf

clustductconfdir = $(sysconfdir)
clustductconf_DATA = configs/clustduct.conf

clustductdocdir = $(docdir)
clustductdoc_DATA = doc/* Usage.md Readme.md COPYING Bugs.md configs/default configs/grub.cfg

#FIXME Evil hack to point to the real /
#tftpdir= $(prefix)/../srv/tftpboot/pxelinux.cfg
#tftp_DATA = configs/default
#
#efidir = $(prefix)/../srv/tftpboot/EFI/x86
#efi_DATA = configs/grub.cfg

kiwiopensusebasedir = $(docdir)/kiwi-descriptions/openSUSE/x86_64/suse-leap-15.0-JeOS
kiwiopensusebase_DATA = kiwi-descriptions/openSUSE/x86_64/suse-leap-15.0-JeOS/Dicefile \
            kiwi-descriptions/openSUSE/x86_64/suse-leap-15.0-JeOS/config.sh \
            kiwi-descriptions/openSUSE/x86_64/suse-leap-15.0-JeOS/config.xml

kiwiopensuserootdir = $(kiwiopensusebasedir)/root
kiwiopensuseroot_DATA = kiwi-descriptions/openSUSE/x86_64/suse-leap-15.0-JeOS/root/.kiwi_grub_config.trigger

kiwiopensuseetcdir = $(kiwiopensuserootdir)/etc
kiwiopensuseetc_DATA = kiwi-descriptions/openSUSE/x86_64/suse-leap-15.0-JeOS/root/etc/motd

kiwiopensusenetdir = $(kiwiopensuseetcdir)/sysconfig/network
kiwiopensusenet_DATA = kiwi-descriptions/openSUSE/x86_64/suse-leap-15.0-JeOS/root/etc/sysconfig/network/ifcfg-lan0 \
            kiwi-descriptions/openSUSE/x86_64/suse-leap-15.0-JeOS/root/etc/sysconfig/network/dhcp

kiwiopensuseudevdir = $(kiwiopensuseetcdir)/udev/rules.d/
kiwiopensuseudev_DATA = kiwi-descriptions/openSUSE/x86_64/suse-leap-15.0-JeOS/root/etc/udev/rules.d/70-persistent-net.rules

kiwiopensusesystemdir = $(kiwiopensuserootdir)/usr/lib/systemd/system/
kiwiopensusesystem_DATA = kiwi-descriptions/openSUSE/x86_64/suse-leap-15.0-JeOS/root/usr/lib/systemd/system/grub_config.service

kiwislebasedir = $(docdir)/kiwi-descriptions/SUSE/x86_64/sle-hpc-15.1-JeOS
kiwislebase_DATA = kiwi-descriptions/SUSE/x86_64/sle-hpc-15.1-JeOS/Dicefile \
            kiwi-descriptions/SUSE/x86_64/sle-hpc-15.1-JeOS/config.sh \
            kiwi-descriptions/SUSE/x86_64/sle-hpc-15.1-JeOS/config.xml

kiwislerootdir = $(kiwislebasedir)/root
kiwisleroot_DATA = kiwi-descriptions/SUSE/x86_64/sle-hpc-15.1-JeOS/root/.kiwi_grub_config.trigger

kiwisleetcdir = $(kiwislerootdir)/etc
kiwisleetc_DATA = kiwi-descriptions/SUSE/x86_64/sle-hpc-15.1-JeOS/root/etc/motd

kiwislenetdir = $(kiwisleetcdir)/sysconfig/network
kiwislenet_DATA = kiwi-descriptions/SUSE/x86_64/sle-hpc-15.1-JeOS/root/etc/sysconfig/network/ifcfg-lan0 \
            kiwi-descriptions/SUSE/x86_64/sle-hpc-15.1-JeOS/root/etc/sysconfig/network/dhcp

kiwisleudevdir = $(kiwisleetcdir)/udev/rules.d/
kiwisleudev_DATA = kiwi-descriptions/SUSE/x86_64/sle-hpc-15.1-JeOS/root/etc/udev/rules.d/70-persistent-net.rules

kiwislesystemdir = $(kiwislerootdir)/usr/lib/systemd/system/
kiwislesystem_DATA = kiwi-descriptions/SUSE/x86_64/sle-hpc-15.1-JeOS/root/usr/lib/systemd/system/grub_config.service \
                     kiwi-descriptions/SUSE/x86_64/sle-hpc-15.1-JeOS/root/etc/systemd/system/RegisterFirst.service
