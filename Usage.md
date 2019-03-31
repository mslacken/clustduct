# Bare metal deployment with dnsmasq and kiwi
If a smaller clusters should be deployed on bare metal with `clustduct`, following prerequisites must be met:

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
The *managment server* can be installed via the *HPC Managment Server (Head Node)* role, but other means of setup are also possible. 

After the installation of the package `clustduct`, all necessary components are available.
Following services must be **disabled**

  * firewall
  * apparmor

Following packages must be installed:

  * python3-kiwi
  * tftp.socket

Following services must be **enabled** and **running**

  * sshd
  * tftp

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
  * dynamic range
```
dhcp-range=192.168.100.50,192.168.100.60,12h (modify to your needs)
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
dhcp-script=/usr/sbin/clustduct.sh
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
  * *gateway* for the *cluster network*
```
dhcp-option=option:router,192.168.100.1 (modify to your needs)
```

Once dnsmasq has been configured, it may be (re)started.

## `genders` databases for the node configuration
The genders database connects the *mac* addresses of the *compute nodes* with the *ip* address and the corresponding FQDN . A flat file in `/etc/genders` is used as database. If the mac addresses of the hosts are known they could also be added before the node installation, if not they can be set during the boot process or, depending on the configuration, will be added in linear manner.

### Adding known `mac` addresses to `genders`
Previosily known `mac` addresses of nodes can be added to the database by adding a single line whic contains the node name and mac address to the file `/etc/genders`. The format must be like
```
NODENAME mac=$MACADDRESS
```
## JeOS leap 15.0 image creation
Descriptions for creating images can be found under the directory
```
/usr/share/doc/clustduct/kiwi-descriptions/[open]SUSE/
```
The install image is prepared with
```
cd /usr/share/doc/clustduct
kiwi-ng --type oem system prepare\
--description kiwi-descriptions/suse/x86_64/suse-leap-15.0-JeOS \
--root /tmp/leap15_oem_pxe
```
Now the root file system for the new nodes is available under `/tmp/leap15_oem_pxe` and simple modifications can be made to it, but they will be lost if a new system is created via the `kiwi-ng system prepare` command. To install the *compute nodes* the image has to be packed. This is done with the commands:
```
mkdir /tmp/packed_image
kiwi-ng --type=oem system create --root=/tmp/leap15_oem_pxe  \
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
