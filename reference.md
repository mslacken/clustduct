# clustduct reference

The deployment tool `clustduct` connects the `genders` database to the `dnsmasq` service. During initialization the files `/etc/ethers` and `/etc/hosts` are populated by the node entries from the genders database.

## components of `clustduct`
The central component is the script 
`/usr/sbin/clustduct.lua`
and is called directly by `dnsmasq` at every dhcp and tftp activity of dnsmasq.

The script 
## genders database
The genders database is the single flat file located under `/etc/genders`. The format is 
```
IDENTIFICATION KEY=VALUE
```
as *IDENTIFICATION* the name of the node or image is used. The node entry will be expanded to the FQDN. For the use of `clustduct` every node needs a single entry for every `KEY` and `VALUE` as the scripts may add and delete whole lines. An example database is shown below:

```
compute-01 ip=192.168.100.11
compute-02 ip=192.168.100.12
compute-03 ip=192.168.100.13
compute-03 mac=aa:bb:cc:dd:ee:ff
```

As `genders` does not allow white spaces and other special characters, so following translation table is used

### special node entries

value | description
------|------------
ip | used a ip address, *must* be present for node entry
mac | used as for dhpd
install | image entry which be used as default boot for node, inferior to boot
boot | image entry for boot, takes precedence over install entry


### special characters

character | character description | value in `genders`
----------|-----------------------|-------------------
' ' | whitespace | \\ws
= | equals | \\eq

### image and boot entries

If an IDENTIFICATION in the `genders` datanase has KEY called 'menu' it is interpreted as a boot entry for `grub` called from (U)EFI and/or pxe network boot. Following values used for the boot entries are common for PXE and `grub`. All values which are not listed below will be ignored.

value | description
------|-----------
menu | will be expanded the label of menu
kernel | kernel which be used to boot, could also be a chainloader
append | options appended to the kernel entry
mandatory | will be added to *all* node entries
nextboot | will be used as boot entry after trigger event
trigger | download if file name will be used as trigger event



#### Options for PXE boot

value | description
------|------------
com32 | used instead of kernel, used for chainloading
initrd | used as initrd in the append entry

#### Options for `grub` entries called from EFI

value | description
------|------------
initrdefi | used as initrdefi
set | used as set, like timeouts ...
chainloader | the used chainloader entries
grub | value is used without directly without 'grub'

