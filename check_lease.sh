#!/bin/bash
LEASEFILE=/var/lib/misc/dnsmasq.leases
echo "$(date) Evil lease script called with: $*" >> /root/evil_lease.log
#echo "$(date) $(env) " >> /root/evil_lease.log
#echo "$(date) sleeping $(sleep 10)">> /root/evil_lease.log
#echo "$(date) exiting">> /root/evil_lease.log
case $1 in 
	add)
		echo "Got new address $2, wants $3"
		echo "$(( $(date +%s) + 3600)) 52:54:00:cf:35:59 192.168.100.55 test-node1 *" >> $LEASEFILE
	;;
	old) 
		echo "Got old address $2, wants $3"
		sed -i "d/$3/" $LEASEFILE
		echo "$(( $(date +%s) + 3600)) 52:54:00:cf:35:59 192.168.100.55 test-node1 *" >> $LEASEFILE
	;;
	tftp)
		echo "Called with tftp, doing nothing"
	;;
	*)
		echo "Unkown option,  doing nothing"
	;;
esac
