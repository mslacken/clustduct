#Bare metal deplpoyment with dnsmasq and kiwi
Currtently it is not possible to deploy the HPC nodes on bare metal via any tools. This document provides intial thougths and describes the necessary tools and steps.

##Used software
For the bare metal provisioning we need following software packages

   * **dnsmasq** in for dhpc, dns and tftp managment
   * **kiwi-ng **for creating stateful (installation on disk) and stateless installs
   * **genders** as central database tool and format
   * **syslinux** providing the necessary pxe boot infratsructure
   * **clustduct** which connects dnsmasq with genders

Additional purpose beyond bare metal provision may depend on following packages

   * **slurm** as workload manager
   * **salt** for node configuration
   * **powerman** for management of the physical machines

##Quick start guide
###Prerequesteries
This software was tested with a *openSuSE Leap 15.0* which has following prerequestaries:
  * no firewall
  * sshd running
  * no apparmor
  * static ip address

#### Disable apparmor
In some profiles **apparmor** is installed and has a preconfigured profile for dnsmasq. This must be disabled which can be done by two ways. You can 

   * disable apparmor service with

```
systemctl disable apparmor.service
```
and reboot the machine, or 

   * disable the profile with

```
aa-disable /etc/apparmor.d/usr.sbin.dnsmasq
```
##### Note
Disabeling the **apparmor** profile introduces some security issues, which we are ignoring a the moment.

### Software installation with prepackaged clustduct
In the first step the repo of clustuct is added and the package is installed
```
zypper ar \
https://download.opensuse.org/repositories/home:/mslacken:/prov/\
openSUSE_Leap_15.0/home:mslacken:prov.repo
zypper ref
zypper in clustduct
```
### Dnsmasq configuration
In the dnsmasq configuration file */etc/dnsmasq.conf* following options have to be changed:

  * the local domain:
```
local=/cluster.suse/
```
  * if an additional dynamic range is wanted:
```
dhcp-range=192.168.100.50,192.168.100.60,12h
```
  * image deployment via *tftp* has to enabled via
```
enable-tftp
tftp-root=/srv/tftpboot/
```
  * pxe boot option for *x86_64*
```
dhcp-boot=pxelinux.0
```
  * connect dnsmasq the genders database via clustduct
```
dhcp-script=/usr/sbin/clustduct.sh
```
  * enable mac managenemnt
```
read-ethers
```
  * run dnsmasq as root (will change in the future)
```
user=root
group=root
```
  * the default route might also be set with
```
dhcp-option=option:router,192.168.100.1
```




### Genders databases configuration for the nodes
Now the cluster nodes have to be defined by creating a genders database for them. The genders database, a flat file in */etc/genders*, must contain for every node a new line wth the *ip*-attribute, which will be used as ip address for the compute node. If the mac addresses of the hosts are known they could also be added now, if not they can be set on the pxe boot menu or will be added on the node boot up.
```
compute-01 ip=192.168.100.11
compute-02 ip=192.168.100.12
compute-03 ip=192.168.100.13,mac=aa:bb:cc:dd:ee:ff
```
A basic database can be created with the command
```
for i in $(seq 1 20); do echo "compute-$(printf %02g $i) ip=192.168.100.$(($i+10))"; done > /etc/genders
```
For booting the node ther must also be entries in the genders database. Boot from local disk can allowed by adding following entry to */etc/genders*
```
local menu=label\wsboot\wsfrom\wslocal\wsdisk,com32=chain.c32,append=hd0,mandatoryentry

```
For creating the boot entries for every node call the command
```
/usr/sbin/clustduct.sh pxemenu
```
and popuble the file */etc/hosts/* with
```
/usr/sbin/clustduct.sh init
```
#### NOTE
The genders database must not have have spaces, thus we use *\\ws* instead. Also the equal character *=* is interpreted, so we use *\\ws* instead.

When the keyword *mandatoryentry* is used a boot entry for this 'image' for every node is created.




###JeOS leap 15.0 image creation
Kiwi must be installed with
```
zypper in python3-kiwi
```
For the creation of boot images do following
```
git clone https://github.com/SUSE/kiwi-descriptions
```
which are the descriptions for creating the node images. As second archive the clustduct script which povides the connection between the **genders** database and **dnsmasq** is needed.
```
git clone https://github.com/mslacken/clustduct.git
```
The previosily downloaded kiwi descriptions allow an easy creation of images for installing the compute nodes. The configuration for the JeOS Leap 15.0 can be found under 
```
kiwi-descriptions/suse/x86_64/suse-leap-15.0-JeOS/config.xml
```
For the installation on the harddisk, following line must be changed from
```
installiso="true"
``` 
to 
```
installpxe="true"
```
For easy deployment to the section *<oemconfig>* the entry
```
<oem-unattended>true</oem-unattended>
```
is added and as well the packgage *salt-minion* is added in the section *<packages type="image">* with
```
<package name="salt-minion"/>
```

Now the image can be perpared with
```
kiwi-ng --type oem system prepare\
--description kiwi-descriptions/suse/x86\_64/suse-leap-15.0-JeOS \
--root /tmp/leap15_oem_pxe
```
As a root image now exists, we can easily some minor modifications there, like copying the ssh-key, enable the *salt-minion* with
````
systemctl --root /tmp/leap15_oem_pxe enable salt-minion
```
and configured by adding following two lines to the file */tmp/leap15_oem_pxe/etc/salt/minion*
```
master: leap15-clustduct.cluster.suse
startup_states: highstate
```
As the hostname should be updated by *dhcp* we have to enable this by setting
```
DHCLIENT_SET_HOSTNAME="yes"
```
in the file */tmp/leap15_oem_pxe/etc/sysconfig/network/dhcp*

In order to serve this image, it has to be packed with the command
```
mkdir /tmp/packed_image
kiwi --type=oem system create --root=/tmp/leap15_oem_pxe  \
--target-dir=/tmp/packed_image
```
To send the images to the nodes, the right location must created with with 
```
mkdir -p /srv/tftpboot/leap15/
```
now extract image to the direcotry with
```
cd /srv/tftpboot/leap15/
tar xJf /tmp/packed_image/LimeJeOS-Leap-15.0.x86_64-1.15.0.install.tar.xz

```
To make the image available in genders add following two lines to */etc/genders*
```
JeOS15 APPEND=initrd\eq/leap15/pxeboot.initrd.xz\wsrd.kiwi.install.pxe\ws\
rd.kiwi.install.image\eqtftp://192.168.100.254/leap15/LimeJeOS-Leap-15.0.xz,\
KERNEL=/leap15/LimeJeOS-Leap-15.0.kernel
compute-[01-20] bootimage=JeOS15
```
and flatten/recreate the genders database and the bootsructure with
```
/usr/sbin/clustduct.sh clean
/usr/sbin/clustduct.sh pxemenu
```
#Configuraion management with salt
## Prerequesteries
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
and the defintion for the node as *srv/salt/top.sls*
```
base:
  'compute-[0-2][0-9].cluster.suse':
    - compute-node

```
we also have to create the config files for *lus-lmod* with
```
mkdir /srv/salt/shared_module
cp /etc/profile.d/lmod* /srv/salt/shared_module
```
and create a pillar for distributing the genders database by creating the file */srv/pillar/top.sls* with the content
```
base:
  '*':
    - genders
```
and the genders pillar */srv/pillar/genders.sls*
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
## Bug
The genders database must be readable by salt, change this with
```
chmod 644 /etc/genders
```

# Deprecated Info
### pxe boot structure
The initial menu for pxe boot has created with the file */srv/tftpboot/pxelinux.cfg/default* with the content
```
DEFAULT menu
PROMPT 0
MENU TITLE Hombrew pxe boot

LABEL ClustDuct
        MENU LABEL Boot as node ...
        KERNEL menu.c32
        APPEND clustduct/clustduct-nodes


```
For proper funactionality the necessary components of the *syslinux* package has to copied to the *tftpboot* dir
```
cp /usr/share/syslinux/chain.c32 /usr/share/syslinux/menu.c32 /usr/share/syslinux/pxelinux.0 \
/usr/share/syslinux/reboot.c32 /srv/tftpboot/
```
### image/boot entries in genders
Boot entries for the nodes will also be created from the genders database. Entries must have the following form

```
JeOS15.0 APPEND=initrd\eq/leap15/pxeboot.initrd.xz\wsrd.kiwi.install.pxe\wsrd.kiwi.install.image=tftp://192.168.100.253/leap15/LimeJeOS-Leap-15.0.xz,KERNEL=/leap15/LimeJeOS-Leap-15.0.kernel
local MENU=DEFAULT,APPEND=hd0,COM32=chain.c32,MENU=LABEL\ws(local\wsboot)
```

### Create pxe boot structure
The pxe boot structure can be created with the command
```
clustduct pxemenu
```
###Deployment of the nodes
Simply start dnsmasq with
```
systemctl enable dnsmasq
systemctl start dnsqmasq
```
## Running clusduct as non root user
For non root functionality of dnsmasq we have to the change the attributes of following files
```
chgrp tftp /etc/hosts
chmod g+w /etc/hosts
chgrp tftp /etc/ethers
chmod g+w /etc/ethers
```
jkljlk
```
kiwi-ng --type oem system build \
--description kiwi-descriptions/suse/x86\_64/suse-leap-15.0-JeOS \
--target-dir /tmp/myimage_oem_pxe
```

