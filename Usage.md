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
#### Software installation
In the first step install the required packages on the management node. This can be done with
```
zypper in dnsmasq genders syslinux
```
We also need following two git archives
```
git clone https://github.com/SUSE/kiwi-descriptions
```
which are the descriptions for creating the node images. As second archive the clustduct script which povides the connection between the **genders** database and **dnsmasq** is needed.
```
git clone https://github.com/mslacken/clustduct.git
```

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

### Dnsmasq configuration
The dnsmasq configuration file following options have to be changed:
```
interface=eth0
```
or 
```
listen-address=192.168.100.253
```
If an additional dynamic range is wanted, the option 
```
dhcp-range=192.168.100.50,192.168.100.60,12h
```
can be set.
The local domain can be set via the keyword 
```
local=/cluster.suse/
```
For the image deployment *tftp* has to enabled via
```
enable-tftp
tftp-root=/srv/tftpboot/
```
and set the pxe boot option
```
dhcp-boot=pxelinux.0
```
Now dnsmasq has be configured in such a way, that it reads the host informations from the genders database
```
dhcp-script=path_to_clustduct/clustduct.sh
```

### Genders databases configuration for the nodes
Now the cluster nodes have to be defined by creating a genders database for them. For every node a new line containing the *ip*-attribute, which will be used as ip address for the compute node, must be set.
```
test-node1 ip=192.168.100.1
test-node2 ip=192.168.100.2
test-node3 ip=192.168.100.3,mac=aa:bb:cc:dd:ee:ff
```
If the mac addresses of the hosts are known they could also be added now, if not they can be set on the pxe boot menu or will be added on the node boot up.

###JeOS leap 15.0 image creation
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

Now the image can be built with
```
kiwi-ng --type oem system build \
--description kiwi-descriptions/suse/x86\_64/suse-leap-15.0-JeOS \
--target-dir /tmp/myimage_oem_pxe
```
In order to serve this image, it has to be transfered to the right location. For this create an directory under the tfp tree with 
```
mkdir -p /srv/tftpboot/leap15/
```
now extract image to the direcotry with
```
cd /srv/tftpboot/leap15/
tar xJf /tmp/myimage_oem_pxe/LimeJeOS-Leap-15.0.x86_64-1.15.0.install.tar.xz

```
### pxe boot structure
The initial menu for pxe boot has to be created with the file */srv/tftpboot/pxelinux.cfg/default* with the content
```
DEFAULT menu
PROMPT 0
MENU TITLE Hombrew pxe boot

LABEL ClustDuct
        MENU LABEL Boot as node ...
        KERNEL menu.c32
        APPEND clustduct/clustduct-nodes


```
For proper funactionality the necessay components of the *syslinux* package has to copied to the *tftpboot* dir
```
cp /usr/share/syslinux/chain.c32 /usr/share/syslinux/menu.c32 /usr/share/syslinux/pxelinux.0 /usr/share/syslinux/reboot.c32 /srv/tftpboot/
```
### image/boot entries in genders
Boot entries for the nodes will also be created from the genders database. Entries must have the following form

```
JeOS15.0 APPEND=initrd\eq/leap15/pxeboot.initrd.xz\wsrd.kiwi.install.pxe\wsrd.kiwi.install.image=tftp://192.168.100.253/leap15/LimeJeOS-Leap-15.0.xz,KERNEL=/leap15/LimeJeOS-Leap-15.0.kernel
local MENU=DEFAULT,APPEND=hd0,COM32=chain.c32,MENU=LABEL\ws(local\wsboot)
```

#### NOTE
The genders database must not have have spaces, thus we use *\\ws* instead. Also the equal character *=* is interpreted, so we use *\\ws* instead.

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

