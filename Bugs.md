# Known Bugs
## hostname is *localhost* in JeOS node
The hostname is not set to the dns name on an image create by JeOS.
This can be changed by setting the value *DHCLIENT_SET_HOSTNAME="no"* 
to *DHCLIENT_SET_HOSTNAME="yes"*
in the file 
```
/etc/sysconfig/network/dhcp
```
This file is most likely created with the template
```
/usr/share/fillup-templates/sysconfig.dhcp-network
```
where the value *DHCLIENT_SET_HOSTNAME="no"* is set and not changed as this happens with yast? in a normal setup.

## kiwi commanline order
The image can be modifed after the build step by modifying the root directory. The command for this is 
```
kiwi --type=oem system create --root=/tmp/jeos15_image3/build/image-root/  \
--target-dir=/tmp/jeos15_image3/
```
and not 
```
kiwi system create --root=/tmp/jeos15_image3/build/image-root/  \
--target-dir=/tmp/jeos15_image3/ --type=oem
```
so the *--typ=oem* is a positional dependened argument.
