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

kiwibasedir = $(docdir)/kiwi-descriptions/suse/x86_64/suse-leap-15.0-JeOS
kiwibase_DATA = kiwi-descriptions/suse/x86_64/suse-leap-15.0-JeOS/Dicefile \
            kiwi-descriptions/suse/x86_64/suse-leap-15.0-JeOS/config.sh \
            kiwi-descriptions/suse/x86_64/suse-leap-15.0-JeOS/config.xml 

kiwirootdir = $(kiwibasedir)/root
kiwiroot_DATA = kiwi-descriptions/suse/x86_64/suse-leap-15.0-JeOS/root/.kiwi_grub_config.trigger 

kiwietcdir = $(kiwirootdir)/etc
kiwietc_DATA = kiwi-descriptions/suse/x86_64/suse-leap-15.0-JeOS/root/etc/motd 

kiwinetdir = $(kiwietcdir)/sysconfig/network
kiwinet_DATA = kiwi-descriptions/suse/x86_64/suse-leap-15.0-JeOS/root/etc/sysconfig/network/ifcfg-lan0 \
            kiwi-descriptions/suse/x86_64/suse-leap-15.0-JeOS/root/etc/sysconfig/network/dhcp 

kiwiudevdir = $(kiwietcdir)/udev/rules.d/
kiwiudev_DATA = kiwi-descriptions/suse/x86_64/suse-leap-15.0-JeOS/root/etc/udev/rules.d/70-persistent-net.rules 

kiwisystemdir = $(kiwirootdir)/usr/lib/systemd/system/
kiwisystem_DATA = kiwi-descriptions/suse/x86_64/suse-leap-15.0-JeOS/root/usr/lib/systemd/system/grub_config.service
