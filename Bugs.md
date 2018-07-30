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
