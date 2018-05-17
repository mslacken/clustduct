#!/bin/bash
LEASEFILE=/var/lib/misc/dnsmasq.leases
LINEAR_ADD=/var/lib/misc/dnsmasq.linear_add
GENDERSFILE=/etc/genders
ETHERSFILE=/etc/ethers
HOSTSFILE=/etc/hosts
LOGGING=0

#DNSMASQCONF=/etc/dnsmasq.conf
#DNSMASQCONFDIR=/etc/dnsmasq.d

function update_host_ethers {
	node_genders_mac=$(nodeattr -f $GENDERSFILE -v $1 mac)
	node_genders_ip=$(nodeattr -f $GENDERSFILE -v $1 ip)
	test $LOGGING && echo "updating info for $1 ip=${node_genders_ip=} mac=${node_genders_mac}" >&2
	test ${node_genders_mac} && test ${node_genders_ip} && \
		grep $node_genders_mac $ETHERSFILE &> /dev/null || \
		echo "$node_genders_mac $node_genders_ip # $0 $(date)" >> $ETHERSFILE
	test ${node_genders_ip} && \
		grep $node_genders_ip $HOSTSFILE &> /dev/null || \
		echo "$node_genders_ip ${1} # $0 $(date)" >> $HOSTSFILE

}

# ETHERSFILE or HOSTSFILE gets update we have to send a SIGHUB to
# the dnsmasq process to get them read in
function send_sighup {
	# function is simple atm, butmay become complicated if 
	# other userids are used
	pkill --signal SIGHUP  dnsmasq
}

if [ ! -e $GENDERSFILE ] ; then
	echo "genders config at $GENDERSFILE does not exist" >&2 
	exit 0
fi
#echo "$0 $*" >&2
# start main program
case $1 in 
	init)
		for node in $(nodeattr -f $GENDERSFILE -n "mac&&ip") ; do 
			test $LOGGING && echo "init: creating netries for host ${node}" >&2
			update_host_ethers $node
		done
	;;
	add)
		genders_host_bymac=$(nodeattr -f $GENDERSFILE -q mac=${2})
		if [ $genders_host_bymac ] ; then 
			test $LOGGING && echo "add: $genders_host_bymac known in genders, but not by dnsmasq" >&2
			update_host_ethers $genders_host_bymac
			send_sighup
		else if [ -e $LINEAR_ADD ] ; then
			# find free host
			freehost=$(nodeattr -f $GENDERSFILE -X mac ip | head -n1)
			if [ $freehost ] ; then
				# add the mac to the genders file, then we can do the rest
				test $LOGGING && echo "add: new mac=${2} to ${freehost}" >&2
				echo "${freehost} mac=${2} # added by $0 $(date)" >> $GENDERSFILE 
				update_host_ethers $freehost
				send_sighup
			fi
		fi fi
	;;
	old) 
		# check if we know the mac
		genders_host_bymac=$(nodeattr -f $GENDERSFILE -q mac=${2})
		genders_host_byip=$(nodeattr -f $GENDERSFILE -q ip=${3})
                # mac is unknown to genders
		if [ -z ${genders_host_bymac} ] ; then
			if [ -z ${genders_host_byip} ] && [ -e $LINEAR_ADD ] ; then
				freehost=$(nodeattr -f $GENDERSFILE -X mac ip | head -n1)
				if [ $freehost ] ; then
					test $LOGGING && echo "old: add mac=${2} to ${freehost}" >&2
					echo "${freehost} mac=${2} # added by $0 $(date)" >> $GENDERSFILE 
					update_host_ethers $freehost
					send_sighup
				fi
			fi
		else
			if [ "x${genders_host_byip}" != "x${genders_host_bymac}" ] ; then
				# ip address has changed in genders database
				# delete ip in hosts as mac has predecende
				test $LOGGING && echo "old: setting new ip=${3} and mac=${3} for ${genders_host_bymac}" >&2
				sed -i "/${2}/d" $ETHERSFILE
				update_host_ethers ${genders_host_bymac}
				send_sighup

			fi
		fi
	;;
	tftp)
		echo "Called with tftp, doing nothing atm"
	;;
	*)
		echo "Unkown option,  doing nothing"
	;;
esac
