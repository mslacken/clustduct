#Deployment for HPC product
Currtently it is not possible to deploy the HPC nodes on bare metal via any tools. This document provides intial thougths and describes the necessary tools and steps.

##Used software

   * **dnsmasq** for dhpc, dns and tftp managment
   * **kiwi-ng **for creating stateful (installation on disk) and stateless installs
   * **genders** as cnetral database tool and format
   * **slurm** as workload manager
   * **salt** for node configuration
   * **powerman** for management of the physical machines
   * **clustduct** which connects dnsmasq with genders
   * **syslinux** providing the necessary pxe boot infratsructure

##Quick start guide
###Prerequesteries
In the first step install the required packages on the management node. This can be done with
```
zypper in dnsmasq genders
```
### Genders databases configuration
Now the cluster nodes have to be defined by creating a genders database for them. For every a new line containing the *ip*-attribute which will be used as ip address for the compute node.
```
test-node1 ip=192.168.100.1
test-node2 ip=192.168.100.2
test-node3 ip=192.168.100.3,mac=aa:bb:cc:dd:ee:ff
JeOS kernel=/image/LimeJeOS-Leap-42.3.kernel,append=initrd=/boot/initrd&nbsp;rd.kiwi.install.pxe&nbsp;rd.kiwi.install.image=tftp://192.168.100.253/image/LimeJeOS-Leap-42.3.xz,menu=label&nbsp;liveJeOS42.3
local menu=label&nbsp;boot&nbsp;from&nbsp;local&nbsp;disk,com32=chain.c32,append=hd0,mandatoryentry
```
If the mac addresses of the hosts are known they could also be added now, if not they can be set on the pxe boot menu or will be added on the node boot up.

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
Now dnsmasq has be configured in such a way, that it reads the host informations from the genders database
```
dhcp-script=/usr/bin/clustduct.sh
```
For non root functionality of dnsmasq we have to the change the attributes of following files
```
chgrp tftp /etc/hosts
chmod g+w /etc/hosts
chgrp tftp /etc/ethers
chmod g+w /etc/ethers
```
###Image creation and pxe config
Clone the kiwi desriptions with
```
git clone  https://github.com/SUSE/kiwi-descriptions
```
and select an appropriate image. For the next steps the suse-leap-15.0-JeOS is selected. In the
configuration file config.xml change 
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
--description kiwi-descriptions/suse/x86\_64/suse-leap-42.3-JeOS \
--target-dir /tmp/myimage_oem_pxe
```
and copy the kernel initrd and image to the approriate dirs
```
cp LimeJeOS-Leap-42.3.xz /srv/tftpboot/image
cp LimeJeOS-Leap-42.3.md5 /srv/tftpboot/image
cp LimeJeOS-Leap-42.3.initrd  /srv/tftpboot/image/
cp LimeJeOS-Leap-42.3.kernel /srv/tftpboot/image/
```
Also the file /srv/tftpboot/pxelinux.cfg/default
with the content
```
DEFAULT menu
PROMPT 0
MENU TITLE Hombrew pxe boot
TIMEOUT 600
TOTALTIMEOUT 6000
ONTIMEOUT JeOS

LABEL local
        MENU LABEL (local)
        MENU DEFAULT
        COM32 chain.c32
        APPEND hd0

LABEL JeOS
        kernel /image/LimeJeOS-Leap-42.3.kernel
        MENU LABEL liveJeOS42.3
        append initrd=/boot/initrd rd.kiwi.install.pxe \
        rd.kiwi.install.image=tftp://192.168.100.253/image/LimeJeOS-Leap-42.3.xz
```
has to be created and the files from the syslinux distribuition copied to the appropriate places:
```
cp /usr/share/syslinux/chain.c32 /usr/share/syslinux/menu.c32 /usr/share/syslinux/pxelinux.0 /srv/tftboot/
```
###Deployment of the nodes
Simply start dnsmasq with
```
systemctl enable dnsmasq
systemctl start dnsqmasq
```
