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



# Bare metal deployment with dnsmasq and kiwi
To deploy a cluster with `clustduct`, following prerequisites must be met:

   * internet access
   * separate network without an active dhcp server
     * *gateway* of the *cluster network*
   * *DNS* server outside of the cluster network

In this setup one node, from now on called *managment server*, provides *DNS* and *dhcp* information to the other nodes, called *compute nodes*.  The *managment server* is also used to generate images with *kiwi* and provide them to the *compute nodes*.

## Table of used values

Key | Example value | Used value
----|---------------|----------------
*cluster network* | 192.168.100.0/24 | ___________
*gateway*         | 192.168.100.1 |___________
*DNS server*      | 192.168.100.1 |___________
*dynamic range*   | 192.168.100.50-60 |___________
*static address*  | 192.168.100.254 |___________
*domain*          | cluster.suse |___________

## Setup of *managment server*
The *managment server* may be installed via the *HPC Managment Server (Head Node)* role, but other means of setup are also possible.

After installing the package `clustduct`, all necessary components are available.
Following services must be **disabled**

  * firewall
  * apparmor

Following packages must be installed:

  * python3-kiwi

Following services must be **enabled** and **running**

  * sshd

Following service must be **enabled**

  * dnsmasq

Furthermore, set up a static IP address.

  * static ip address


NOTE: Disable apparmor

In some profiles, `apparmor` is installed and has a preconfigured profile for `dnsmasq`. It must be disabled which can be done in two ways.

   * The profile for `dnsmasq` can be disabled with
```
aa-disable /etc/apparmor.d/usr.sbin.dnsmasq
```
   * or the `apparmor` service can be disabled with

```
systemctl disable apparmor.service
```
afterwards the machine must be rebooted.

WARNING: Disabling the `apparmor` profile introduces security issues which can be ignored as the *cluster network* is assumed to be a protected network.

## Dnsmasq configuration
The package *clustduct* contains also an example configuration for *dnsmasq* in `/usr/share/doc/clustduct/dnsmasq.example` which has following differences to shipped *dnsmasq* configuration:

  * local domain (modify to your needs)
```
local=/cluster.suse/
```
  * dynamic range (modify to your needs)
```
dhcp-range=192.168.100.50,192.168.100.60,12h
```
  * tftp enabled and deployment directory
```
enable-tftp
tftp-root=/srv/tftpboot/
```
  * pxe boot option for *x86_64*
```
dhcp-boot=pxelinux.0
```
  * *clustduct* script
```
dhcp-luascript=/usr/sbin/clustduct.lua
```
  * enable mac management
```
read-ethers
```
  * `dnsmasq` is executed as root
```
user=root
group=root
```
  * *gateway* for the *cluster network* (modify to your needs)
```
dhcp-option=option:router,192.168.100.1
```

Once dnsmasq has been configured, it may be (re)started.

## `genders` databases for the node configuration
The genders database connects the *mac* addresses of the *compute nodes* with the *ip* address and the corresponding FQDN . A flat file in `/etc/genders` is used as database. If the mac addresses of the hosts are known they may also be added before the node installation, if not they can be set during the boot process or, depending on the configuration, will be added in linear manner.

### Adding known `mac` addresses to `genders`
Previosily known `mac` addresses of nodes may be added to the database by adding a single line which contains the node name and mac address to the file `/etc/genders`. The format must be like
```
NODENAME mac=$MACADDRESS
```
After editing the `genders` database it is advisable to check its syntax by
executing `nodeattr -k`.

## Install image creation
Sample kiwi configurations for creating images can be found under the directory
```
/usr/share/doc/clustduct/kiwi-descriptions/SUSE/
```
and
```
/usr/share/doc/clustduct/kiwi-descriptions/openSUSE/
```
The install image is prepared with
```
cd /usr/share/doc/clustduct
kiwi --type oem system prepare\
--description kiwi-descriptions/suse/x86_64/suse-leap-15.0-JeOS \
--root /tmp/leap15_oem_pxe
```
Now the root file system for the new nodes is available under `/tmp/leap15_oem_pxe` and simple modifications can be made to it, but they will be lost if a new system is created via the `kiwi system prepare` command. To install the *compute nodes* the image has to be packed. This is done with the commands:
```
mkdir /tmp/packed_image
kiwi --type=oem system create --root=/tmp/leap15_oem_pxe  \
--target-dir=/tmp/packed_image
```

## Preparing the *tftboot* directory
For the deployment of the *compute nodes* the *tftpboot* directory `/srv/tftpboot` must be prepared with the command 
```
prepare-tftp.sh
``` 
which installs the necessary files for booting and installing the *compute nodes* over the network via *PXE* or *UEFI*. Finally the directory which holds the image for the *compute nodes* must be created with
```
mkdir -p /srv/tftpboot/leap15/
```
and the previously packed image extracted to
```
cd /srv/tftpboot/leap15/
tar xJf /tmp/packed_image/LimeJeOS-Leap-15.0.x86_64-1.15.0.install.tar.xz

```
it. 



# Configuration management with salt
## Prerequisites
Configure a *nfs-server* with following *exports*
```
/usr/lib/hpc	*(ro,root_squash,sync,no_subtree_check)
/usr/share/lmod/modulefiles	*(ro,root_squash,sync,no_subtree_check)
/usr/share/lmod/moduledeps	*(ro,root_squash,sync,no_subtree_check)
```

## Salt formulas
The salt formula */srv/salt/compute-node.sls* is used to configure the compute nodes. The formula has the contents
```
nfs-client:
    pkg.installed: []
neovim:
    pkg.installed: []
lua-lmod:
    pkg.installed: []
genders:
    pkg.installed: []

/usr/lib/hpc:
   mount.mounted:
      - device: leap15-clustduct:/usr/lib/hpc
      - fstype: nfs
      - mkmnt: True
      - opts:
         - defaults
      - require:
        - pkg: nfs-client

/usr/share/lmod/modulefiles:
   mount.mounted:
      - device: leap15-clustduct:/usr/share/lmod/modulefiles
      - fstype: nfs
      - mkmnt: True
      - opts:
         - defaults
      - require:
        - pkg: nfs-client

/usr/share/lmod/moduledeps:
   mount.mounted:
      - device: leap15-clustduct:/usr/share/lmod/moduledeps
      - fstype: nfs
      - mkmnt: True
      - opts:
         - defaults
      - require:
        - pkg: nfs-client

/etc/profile.d/lmod.sh:
    file.managed:
      - source: salt://shared_module/lmod.sh
      - mode: 644
      - user: root
      - group: root
      - require:
        - pkg: lua-lmod

/etc/profile.d/lmod.csh:
    file.managed:
      - source: salt://shared_module/lmod.csh
      - mode: 644
      - user: root
      - group: root
      - require:
        - pkg: lua-lmod

/etc/genders:
    file.managed:
      - contents_pillar: genders:database
      - mode: 644
      - user: root
      - group: root
      - require:
        - pkg: genders
```
and the definition for the node as *srv/salt/top.sls*
```
base:
  'compute-[0-2][0-9].cluster.suse':
    - compute-node

```
we also have to create the configuration files for *lua-lmod* with
```
mkdir /srv/salt/shared_module
cp /etc/profile.d/lmod* /srv/salt/shared_module
```
and create a pillar for distributing the genders database by creating the file `/srv/pillar/top.sls` with the content
```
base:
  '*':
    - genders
```
and the genders pillar `/srv/pillar/genders.sls`
```
genders:
    database: |
        {{ salt['cmd.run']('nodeattr --expand' ) | indent(8) }}
```
Now accept the key with
```
salt-key -A
```
and the node should install the rest.
