# clustduct reference

The deployment tool `clustduct` connects the `genders` database to the `dnsmasq` service. During initialization the files `/etc/ethers` and `/etc/hosts` are populated by `node` entries from the genders database. `clustduct` also monitors *tftp* file transfers and can so be used to deploy prebuilt images to `compute nodes`.

## components of `clustduct`
The central component of `clustduct` is the script
`/usr/sbin/clustduct.lua`
and is called directly by `dnsmasq` at every dhcp and tftp activity of `dnsmasq`.

Two scripts are used to create and maintain the directory and file structure for booting and installing the `compute nodes`. In order to copy the files from the `syslinux` package the shell script
```
/usr/sbin/prepare_tftp.sh
```
can be used. For the creation of the files used for `grub` or PXE the `lua` script
```
/usr/sbin/write_bf.lua
```
can be used. It can be used with following command line options

option | description
-------|--------------------------------------------------
-n NODE| create configuration only for given and not all nodes
-o DIRECTORY| base directory to write boot file to
-c DIRECTORY| search directory for configuration files

## configuration of `clustduct`
The script 
```
/usr/sbin/clustduc.lua
```
can be configured with the file
```
/etc/clustduct.conf
```
which is not parsed, but is itself a `lua` table. Following values can be used

option  | description
--------|--------------------------------------------------
ethers | location of the ethers files, default is `/etc/ethers`
hosts | location of the hosts files, default is `/etc/hosts`
genders |location of the genders database, default is `/etc/genders` 
domain | domain to which the nodes are expanded, *must* be the same as in `/etc/dnsmasq.conf`
linear_add | if *true*, nodes with unknown `mac` addresses will be added to the `genders` database
confdir | the directory where clustduct searches for template files, `/etc/clustduct.d/` is used as default

## template files

During the initializaton of `clustduct` or by calling `write_bf.lua` individual entries for every node are created. As templates for the menus shown at boot time, two files are used:
For the PXE boot, the file
```
/etc/clustduct.d/pxe_iptemplate
``` 
and for `grub` the file
```
/etc/clustduct.d/grub_iptemplate
```
is used. Following values are substituted

value | description
------|--------------------------------------------------
$NODE | replaced with node name
$MAC  | replaced with mac address
$IP   | replaced with ip address



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

### special node entries

value | description
------|--------------------------------------------------
ip | used a ip address, *must* be present for node entry
mac | used as for dhpd
install | image entry which be used as default boot for node, inferior to boot
boot | image entry for boot, takes precedence over install entry


### special characters

As `genders` does not allow white spaces and other special characters, so following translation table is used

character | character description | value in `genders`
----------|-----------------------|-------------------
' ' | whitespace | \\ws
= | equals | \\eq

### image and boot entries

If an IDENTIFICATION in the `genders` database has KEY called 'menu' it is interpreted as a boot entry for `grub` called from (U)EFI and/or pxe network boot. Following values used for the boot entries are common for PXE and `grub`. All values which are not listed below will be ignored.

value | description
------|--------------------------------------------------
menu | will be expanded the label of menu
kernel | kernel which be used to boot, could also be a chainloader
append | options appended to the kernel entry
mandatory | will be added to *all* node entries
nextboot | will be used as boot entry after trigger event
trigger | download if file name will be used as trigger event



#### Options for PXE boot

value | description
------|--------------------------------------------------
com32 | used instead of kernel, used for chainloading
initrd | used as initrd in the append entry

#### Options for `grub` entries called from EFI

value | description
------|--------------------------------------------------
initrdefi | used as initrdefi
set | used as set, like timeouts ...
chainloader | the used chainloader entries
grub | value is used without directly without 'grub'

