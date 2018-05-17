#!/bin/bash
LEASEFILE=/var/lib/misc/dnsmasq.leases
GENDERSFILE=/etc/genders
#DNSMASQCONF=/etc/dnsmasq.conf
#DNSMASQCONFDIR=/etc/dnsmasq.d

#echo "$0 $*" >&2
# start main program
case $1 in 
	init)
		# add all nodes which have a mac in genders and are not present in the leases file
		touch $LEASEFILE
		for node in $(nodeattr -f $GENDERSFILE -n "mac&&ip") ; do 
			grep $node $LEASEFILE &> /dev/null || echo "$(date +%s) $(nodeattr -v $node mac) $(nodeattr -v $node ip) $node * # init entry" >> $LEASEFILE
		done
		cat $LEASEFILE
	;;
	add)
		lease_time=${DNSMASQ_LEASE_LENGTH:-${DNSMASQ_LEASE_EXPIRES:-$(date +%s)}}
		known_genders_host=$(nodeattr -f $GENDERSFILE -q mac=${2})
		if [ -z $known_genders_host ] ; then
                        # set the dynamic ip, which host creates
			echo "$lease_time ${2} ${3} ${4:-*} ${DNSMASQ_CLIENT_ID:-*} # add entry, dynamic range" | tee >> $LEASEFILE
		else
			# set the ip which we extract from the genders database
			known_genders_ip=$(nodeattr -f $GENDERSFILE -v $known_genders_host ip)
			echo "${lease_time} ${2} ${known_genders_ip} ${known_genders_host} ${DNSMASQ_CLIENT_ID:-*} # add entry from genders" | tee -a $LEASEFILE
		fi
	;;
	old) 
		lease_time=${DNSMASQ_LEASE_LENGTH:-${DNSMASQ_LEASE_EXPIRES:-$(date +%s)}}
		# check if we know the mac
		known_genders_host_mac=$(nodeattr -f $GENDERSFILE -q mac=${2})
		known_genders_host_ip=$(nodeattr -f $GENDERSFILE -q ip=${3})
                # mac is unknown to genders
		if [ -z ${known_genders_host_mac} ] ; then
			if [ -z ${known_genders_host_ip} ] ; then
			# if ip is also unknown, the host it in dynmic range, leave it there
				echo sed -i "/${2}/d" $LEASEFILE	>&2	
				sed -i "/${2}/d" $LEASEFILE	
				echo "${lease_time} ${2} ${3} ${4:-*} ${DNSMASQ_CLIENT_ID:-*} # old entry dynamic range" | tee -a $LEASEFILE 

			else
			# mac is unknown but we ip is in genders range, forcing dynamic ip would require
			# complicated parsing of config file so leave it alone for now 
			# and sent invalid ip
				echo "${lease_time} ${2} 0.0.0.0 ${4:-*} ${DNSMASQ_CLIENT_ID:-*} # known genders ip, unknown mac"
			fi
		else
			# check if we are in sync with genders database
			if [ "x${known_genders_host_mac}" == "x${known_genders_host_ip}" ] ; then
				# delete old entry
				echo sed -i "/${known_genders_host_mac}/d" $LEASEFILE	>&2	
				sed -i "/${known_genders_host_mac}/d" $LEASEFILE	
				echo "${lease_time} ${2} ${3} ${4} ${DNSMASQ_CLIENT_ID:-*} # old entry, renewing" | tee -a $LEASEFILE
			else
				# on mismatch we take the ip from the genders database
				known_genders_ip=$(nodeattr -f $GENDERSFILE -v $known_genders_host_mac ip)
				echo sed -i "/${known_genders_host_mac}/d" $LEASEFILE	>&2
				sed -i "/${known_genders_host_mac}/d" $LEASEFILE	
				echo "${lease_time} ${2} ${known_genders_ip} ${known_genders_host_mac} ${DNSMASQ_CLIENT_ID:-*} # old entry, but new ip from genders" | tee -a $LEASEFILE
			fi
		fi
	;;
	tftp)
		echo "Called with tftp, doing nothing"
	;;
	*)
		echo "Unkown option,  doing nothing"
	;;
esac
