#!/bin/bash
# clustduct.sh works as a duct tape between dnsmasq and genders
#
# Copyright (C) 2018 Christian Goll <cgoll@suse.de>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

# defauly values maybe overwritten with the ones in config file
LEASEFILE=/var/lib/misc/dnsmasq.leases
LINEAR_ADD=/var/lib/misc/dnsmasq.linear_add
GENDERSFILE=/etc/genders
ETHERSFILE=/etc/ethers
HOSTSFILE=/etc/hosts
LOGGING=1
CLUSTDUCTCONF=/etc/clustduct.conf

if [ -e $CLUSTDUCTCONF ] ; then
source $CLUSTDUCTCONF
fi

function logerr {
	level=${2:-1}
	if [ $level -le $LOGGING ] ; then 
		echo $1 >&2
	fi
}


function update_host_ethers {
	node_genders_mac=$(nodeattr -f $GENDERSFILE -v $1 mac)
	node_genders_ip=$(nodeattr -f $GENDERSFILE -v $1 ip)
	need_reread=0
	logerr "updating info for $1 ip=${node_genders_ip} mac=${node_genders_mac}" >&2
	test ${node_genders_mac} && test ${node_genders_ip} && \
		grep $node_genders_mac $ETHERSFILE > /dev/null
		if [ $? -eq 1 ] ; then
			need_reread=1
			echo "$node_genders_mac $node_genders_ip" >> $ETHERSFILE
		fi

	test ${node_genders_ip} && \
		grep $node_genders_mac $ETHERSFILE > /dev/null
		if [ $? -eq 1 ] ; then
			need_reread=1
			echo "$node_genders_ip ${1}" >> $HOSTSFILE
		fi
	if [ $need_reread -ne 0 ] ; then
		send_sighup
	fi
}
# ETHERSFILE or HOSTSFILE gets update we have to send a SIGHUB to
# the dnsmasq process to get them read in
function send_sighup {
	# function is simple atm, butmay become complicated if 
	# other userids are used
	logerr "sending SIGHUP to dnsmasq" >&2
	pkill --signal SIGHUP  dnsmasq
}

if [ ! -e $GENDERSFILE ] ; then
	echo "genders config at $GENDERSFILE does not exist" >&2 
	exit 0
fi
#echo "$0 $*" >&2
# start main program
test $LOGGING && echo "called with $*" >&2
case $1 in 
	init)
		for node in $(nodeattr -f $GENDERSFILE -n "mac&&ip") ; do 
			logerr "init: creating entries for host ${node}" >&2
			update_host_ethers $node
		done
	;;
	add)
		genders_host_bymac=$(nodeattr -f $GENDERSFILE -q mac=${2})
		if [ $genders_host_bymac ] ; then 
			logerr "add: $genders_host_bymac known in genders, but not by dnsmasq" >&2
			update_host_ethers $genders_host_bymac
		else if [ -e $LINEAR_ADD ] ; then
			# find free host
			freehost=$(nodeattr -f $GENDERSFILE -X mac ip | head -n1)
			if [ $freehost ] ; then
				# add the mac to the genders file, then we can do the rest
				logerr "add: new mac=${2} to ${freehost}" >&2
				echo "${freehost} mac=${2} # added by $0 $(date)" >> $GENDERSFILE 
				update_host_ethers $freehost
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
					logerr "old: add mac=${2} to ${freehost}" >&2
					echo "${freehost} mac=${2} # added by $0 $(date)" >> $GENDERSFILE 
					update_host_ethers $freehost
				fi
			fi
		else
			if [ "x${genders_host_byip}" != "x${genders_host_bymac}" ] ; then
				# ip address has changed in genders database
				# delete ip in hosts as mac has predecende
				# delete entry only if it was present
				genders_ip=$(nodeattr -f $GENDERSFILE -v ${genders_host_bymac} ip)
				logerr "old: changing from ip=${3} to ip=${genders_ip} for mac=${2}" >&2
				# delete only when /etc/ethers does not reperesent genders state
				grep -i ${2} $ETHERSFILE | grep ${genders_ip} > /dev/null || \
					(sed -i "/${2}/d" $ETHERSFILE; echo deleted entry for ${2} in $ETHERSFILE)
				update_host_ethers ${genders_host_bymac}

			fi
		fi
	;;
	tftp)
		logerr "Called with tftp, doing nothing atm" >&2
	;;
	*)
		logerr "Unkown option, called with  $* ,  doing nothing" >&2
	;;
esac
