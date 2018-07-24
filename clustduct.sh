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
PXEROOTDIR=/srv/tftpboot/
PXEDIR=clustduct
PXETEMPLATE=pxe.tmpl
LOGGING=1
CLUSTDUCTCONF=/etc/clustduct.conf
DELETEOLDMACFILES=0
DOMAIN=cluster.suse
NETNR=01

# global variables - use with care
need_reread=0


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
	logerr "updating info for $1 ip=${node_genders_ip} mac=${node_genders_mac}"
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
			echo "$node_genders_ip ${1}.${DOMAIN} ${1}" >> $HOSTSFILE
		fi
}

function update_hosts {
	node_genders_ip=$(nodeattr -f $GENDERSFILE -v $1 ip)
	need_reread=0
	test ${node_genders_ip} && grep $node_genders_ip $HOSTSFILE >> /dev/null
	if [ $? -eq 1 ] ; then
		need_reread=1
		echo "$node_genders_ip ${1}.${DOMAIN} ${1}" >> $HOSTSFILE
	fi

}

# create a list from all boot entries which have the value provided by functioncall
function get_boot_entries() {
	for entry in $(nodeattr -f $GENDERSFILE -n $1); do
		cat <<EOF
LABEL $entry
EOF
		for label_entry in $(nodeattr -f $GENDERSFILE -l $entry); do
			echo $label_entry | grep 'nextboot=' > /dev/null || \
			echo $label_entry | grep -v $1 | sed 's/\(=\|\\ws\)/ /g' | \
			sed 's/\(\\eq\)/=/g' | sed 's/^/\t/'
		done
	done
}
function get_node_boot() {
	bootimage=$(nodeattr -f $GENDERSFILE -v $1 bootimage)
	if [ ! -z $bootimage ] ; then
		echo "LABEL $bootimage"
		for label_entry in $(nodeattr -f $GENDERSFILE -l $bootimage); do
			echo $label_entry | grep 'nextboot=' > /dev/null || \
			echo $label_entry | grep -v $1 | sed 's/\(=\|\\ws\)/ /g' | \
			sed 's/\(\\eq\)/=/g' | sed 's/^/\t/'
		done
	echo "	DEFAULT"
	fi
}
# creates the individual node entry 
function create_node_entry() {
	if [ $# -ne 2 ] ; then
		echo "function must be called like:"
		echo "create_node_entry NODE ENTRYFILE"
		echo "but was called: create_node_entry $*"
		exit 1
	fi
	node=$1
	nodefile=$2
	cat > ${PXEROOTDIR}/${nodefile} <<EOF
DEFAULT menu
PROMPT 0
MENUTILE $node
EOF
	# not used right now, but keep oppurtunities open
	if [ -e ${PXEROOTDIR}/${PXEDIR}/${PXETEMPLATE} ] ; then
		cat ${PXEROOTDIR}/${PXEDIR}/${PXETEMPLATE} \
			>> ${PXEROOTDIR}/${nodefile}
	fi
	cat >> ${PXEROOTDIR}/${nodefile} <<EOF
$(get_node_boot $node)
$(get_boot_entries mandatoryentry)
LABEL go_back
	MENU LABEL Go to default
	KERNEL menu.c32
	APPEND pxelinux.cfg/default
EOF
}

# ETHERSFILE or HOSTSFILE gets update we have to send a SIGHUB to
# the dnsmasq process to get them read in
function send_sighup {
	# function is simple atm, butmay become complicated if 
	# other userids are used
	logerr "sending SIGHUP to dnsmasq"
	pkill --signal SIGHUP  dnsmasq
}

if [ ! -e $GENDERSFILE ] ; then
	logerr "genders config at $GENDERSFILE does not exist"
	exit 0
fi
#echo "$0 $*" >&2
# start main program
test $LOGGING && echo "called with $*" >&2
case $1 in 
	init)
		for node in $(nodeattr -f $GENDERSFILE -n "ip&&mac") ; do 
			logerr "init: creating entries for host ${node}"
			update_host_ethers $node
		done
		for node in $(nodeattr -f $GENDERSFILE -n "ip") ; do 
			logerr "init: filling up $HOSTSFILE with $node"
			update_hosts $node

		done
		if [ $need_reread -ne 0 ] ; then
			send_sighup
		fi
		# remove blank lines from ETHERSFILE
		sed -i '/^\s$/d' $ETHERSFILE
	;;
	add)
		genders_host_bymac=$(nodeattr -f $GENDERSFILE -q mac=${2})
		if [ $genders_host_bymac ] ; then 
			logerr "add: $genders_host_bymac known in genders, but not by dnsmasq"
			update_host_ethers $genders_host_bymac
		else if [ -e $LINEAR_ADD ] ; then
			# find free host
			freehost=$(nodeattr -f $GENDERSFILE -nX mac ip | head -n1)
			if [ $freehost ] ; then
				# add the mac to the genders file, then we can do the rest
				logerr "add: new mac=${2} to ${freehost}"
				echo "${freehost} mac=${2}" >> $GENDERSFILE 
				update_host_ethers $freehost
			fi
		fi fi
		if [ $need_reread -ne 0 ] ; then
			send_sighup
		fi
	;;
	old) 
		# check if we know the mac
		genders_host_bymac=$(nodeattr -f $GENDERSFILE -qn mac=${2})
		# wc -l does not work with substitutions, so no echo $var below
		if [ $( nodeattr -f $GENDERSFILE -qn mac=${2} | wc -l) -gt 1 ] ; then
			echo "genders database corrupted, more than one entry for mac=${2}"
			echo "entries are ${genders_host_bymac}"
			exit 1
		fi
		genders_host_byip=$(nodeattr -f $GENDERSFILE -qn ip=${3})
		if [ $( nodeattr -f $GENDERSFILE -qn ip=${3} | wc -l) -gt 1 ] ; then
			echo "genders database corrupted, more than one entry for ip=${3}"
			echo "entries are ${genders_host_byip}"
			exit 1
		fi
                # mac is unknown to genders
		if [ -z ${genders_host_bymac} ] ; then
			if [ -z ${genders_host_byip} ] && [ -e $LINEAR_ADD ] ; then
				freehost=$(nodeattr -f $GENDERSFILE -X mac ip | head -n1)
				if [ $freehost ] ; then
					logerr "old: add mac=${2} to ${freehost}"
					echo "${freehost} mac=${2}" >> $GENDERSFILE 
					update_host_ethers $freehost
				fi
			fi
		else
			if [ "x${genders_host_byip}" != "x${genders_host_bymac}" ] ; then
				# ip address has changed in genders database
				# delete ip in hosts as mac has predecende
				# delete entry only if it was present
				genders_ip=$(nodeattr -f $GENDERSFILE -v ${genders_host_bymac} ip)
				logerr "old: changing from ip=${3} to ip=${genders_ip} for mac=${2}"
				# delete only when /etc/ethers does not represent genders state
				#grep -i ${2} $ETHERSFILE | grep ${genders_ip} > /dev/null || \
					(sed -i "s/,*mac=${2}//" $ETHERSFILE; echo deleted entry for ${2} in $ETHERSFILE)
				update_host_ethers ${genders_host_bymac}

			fi
		fi
		if [ $need_reread -ne 0 ] ; then
			send_sighup
		fi
	;;
	tftp)
		logerr "Called with tftp, options were $*" 
		# test if called file contains clustduct_pxe
		echo $4 | grep "clustduct_pxe" > /dev/null
		if [ $? -eq 0 ] ; then
			nodename=$(basename $4 | sed 's/\.clustduct_pxe//')
			# handle image and installation part
			bootimage=$(nodeattr -f $GENDERSFILE -v $nodename bootimage)
			if [ ! -z $bootimage ] ; then
				# just do something if we have a bootimage
				echo "booted with image $*"	
			fi
			# handle ip and mac address part
			genders_ip=$(nodeattr -f $GENDERSFILE -v $nodename ip)
			genders_mac=$(nodeattr -f $GENDERSFILE -v $nodename mac)
			real_mac=$(ip neigh show $3| cut -f 5 -d ' ')
			echo "in tftp tree, nodename $nodename, mac: $real_mac, ip: $3"
			if [ -z $real_mac ] ; then
				echo "No mac address in ip stack, exiting"
				exit 1
			fi
			if [ -z $genders_ip ] ; then
				logerr "ip $3 not in genders, exiting"
				exit 1
			fi
			if [ -z $genders_mac ] ; then 
				logerr "tftp: booted as ${nodename}, but mac $real_mac unknown in genders"
				other_node_mac=$(nodeattr -f $GENDERSFILE -q mac=${real_mac})
				if [ ! -z $other_node_mac ] ; then
					echo "genders database contains mac=$real_mac as node $other_node_mac, deleting entry"
					sed -i "s/,*mac=${real_mac}//" $GENDERSFILE
				
				fi
				echo "$nodename mac=${real_mac}" >> $GENDERSFILE 
				update_host_ethers $nodename
			else
				if [ $real_mac != $genders_mac ] ; then
					loggerr "mac (${real_mac}) is different for node $nodename in genders"
					loggerr "deleting mac (${genders_mac}) in $GENDERSFILE"
					sed -i "s/,*mac=${genders_mac}//" $GENDERSFILE
					logerr "adding new mac ${genders_mac} will be added"
					echo "$nodename mac=${real_mac}" >> $GENDERSFILE 
					update_host_ethers $nodename
				else 
					logerr "right node ${nodename}, booted with right mac $real_mac"
				fi
			fi
			if [ $need_reread -ne 0 ] ; then
				send_sighup
			fi
		fi # end for grep clustduct_pxe
		# check for the sent/selected image so that we honor the nextboot entry
		genders_host_byip=$(nodeattr -f $GENDERSFILE -qn ip=${3})
		if [ -n $genders_host_byip ] ; then
			bootimage=$(nodeattr -f $GENDERSFILE -v $genders_host_byip  bootimage)
			# we have a bootimage
			if [ -n $bootimage ] ; then
				# get from the append entry the labled rd.kiwi.install.image value
				append=$(nodeattr -f $GENDERSFILE -v $bootimage append)
				if [ -n $append ] ; then
					os_image=$(echo $append |  sed 's/.*rd.kiwi.install.pxewsrd.kiwi.install.image\\eq\([^,]*\),.*/\1/' | cut -f 6,7  -d '/')	
					echo "got following os_image $os_image compared to ${PXEROOTDIR}$4"
					if [ "x$os_image" == "x${PXEROOTDIR}$4" ] ; then
						# check if the bootimage requires an action, what means it has the entry nextboot
						nextboot=$(nodeattr -f $GENDERSFILE -v $bootimage nextboot)
						if [ -n $nextboot ] ; then
							# subsitute bootimaget entry 
							logerr "changed boot entry for node=$genders_host_byip from $bootimage to $nextboot"
							sed -i "s/\(^${genders_host_byip}.*bootimage=\)$bootimage/\1$nextboot/" $GENDERSFILE
							genders_mac=$(nodeattr -f $GENDERSFILE -v ${genders_host_byip} mac)
							if [ -n ${genders_mac} ] ; then
								trans_mac=${genders_mac,,}
								trans_mac=$(echo $trans_mac | tr ':' '-')
								create_node_entry $genders_host_byip pxelinux.cfg/${NETNR}-${trans_mac}
							fi
						fi
					fi
				fi
			fi
		fi
	;;
	pxemenu)
		logerr "Starting to create pxe boot structure"
		if [ ! -e ${PXEROOTDIR}/${PXEDIR} ] ; then
			mkdir -p ${PXEROOTDIR}/${PXEDIR}
		fi
		# clean up the files (of explicit mac adresses)
		for file in ${PXEROOTDIR}/${PXEDIR}/* ; do
			if [ $DELETEOLDMACFILES -ne 0 ] ; then
				echo $file | grep -E '[0-9,a-z]{2}-[0-9,a-z]{2}-[0-9,a-z]{2}-[0-9,a-z]{2}-[0-9,a-z]{2}-[0-9,a-z]{2}-[0-9,a-z]{2}' > /dev/null && rm $file
			fi	
		done
		incrementcount=0
		nodes=$(nodeattr -f $GENDERSFILE -n ip)	
		nr_nodes=$(nodeattr -f $GENDERSFILE -n ip | wc -l)
		base=${BASE:-10}
		exponent=$(echo "scale=0; l($nr_nodes)/l($base)" | bc -l)
		counter=1
		level=0
		i=1
		# clean up preexisting entries
		rm ${PXEROOTDIR}/${PXEDIR}/clustduct-nodes 
		for node in ${nodes}; do
			if [ $counter -eq 1 ] ; then
				i_inc=$(($i-1))
				for n in $(seq 1 $exponent) ; do
					modulo=$(echo "scale=0; ${i_inc}%($base^$n)" | bc -l)
					if [ $modulo -eq 0 ] ; then
						cat >> ${PXEROOTDIR}/${PXEDIR}/clustduct-nodes  <<EOF
MENU BEGIN list_${node}
MENU LABEL Boot $node to ENDNODE
EOF
						level=$(($level+1))
					fi
				done
			
			fi
			# to pxe menu structure
			cat >> ${PXEROOTDIR}/${PXEDIR}/clustduct-nodes <<EOF
LABEL $node
	MENU LABEL Boot as node $node
	KERNEL menu.c32
	APPEND ${PXEDIR}/${node}.clustduct_pxe
EOF
			# to the node file
			create_node_entry $node ${PXEDIR}/${node}.clustduct_pxe  
			genders_mac=$(nodeattr -f $GENDERSFILE -v $node mac)
			if [ ! -z ${genders_mac} ] ; then
				trans_mac=${genders_mac,,}
				trans_mac=$(echo $trans_mac | tr ':' '-')
				create_node_entry $node pxelinux.cfg/${NETNR}-${trans_mac}
			fi
			if [ $counter -eq ${base} ] ; then
				for n in $(seq 1 $exponent) ; do
					modulo=$(echo "scale=0; $i%($base^$n)" | bc -l)
					if [ $modulo -eq 0 ] ; then
						cat >> ${PXEROOTDIR}/${PXEDIR}/clustduct-nodes  <<EOF
LABEL go_back
	MENU LABEL Go back...
	MENU EXIT
MENU END
EOF
						sed -i "s/ENDNODE/$node/" ${PXEROOTDIR}/${PXEDIR}/clustduct-nodes 

						level=$(($level-1))
					fi
				done
			
			fi

			if [ ${counter} -lt ${base} ] ; then
				counter=$(($counter+1))
			else
				counter=1
			fi
			i=$(($i+1))
		done
		for n in $(seq 1 $level); do
			cat >> ${PXEROOTDIR}/${PXEDIR}/clustduct-nodes  <<EOF
LABEL go_back
	MENU LABEL Go back...
	MENU EXIT
MENU END
EOF
		done
		cat >> ${PXEROOTDIR}/${PXEDIR}/clustduct-nodes  <<EOF
LABEL go_back
	MENU LABEL Go back...
	KERNEL menu.c32
	APPEND ~
EOF
	;;
	*)
		logerr "Unkown option, called with  $* ,  doing nothing"
	;;
esac
