#!/bin/bash
#destroy.sh [2018-06-22]
#Destroy the VMs according to the VMIDs listed in a ${LIST_OF_VMIDS} text file
#config
CURRENT_DATE=`date '+%h %d, %Y @ %H:%M %Z'`
LOG_DATE=`date '+%Y%m%d.%H%M'`
LOG_FILE="/scripts/destroy.`uname -n`.${LOG_DATE}.log"
LIST_OF_VMIDS="/scripts/vmid.list"
DESTROYED_COUNT=0
USER=`who | awk '{print $1}'`
#start
clear
echo '########################'
echo '# destroy.sh June 2018 #'
echo '########################'$'\n'
echo 'Logging started on ['`uname -n`'].'
echo 'Executed by '${USER}' on '${CURRENT_DATE} >> ${LOG_FILE}
echo 'The script will attempt to destroy the following Virtual Machines from this ESXi'$'\n'
echo 'VMID'$'\tName'
echo '------------------------------------------'
for i in `cat ${LIST_OF_VMIDS}`; do	
	echo $i$'\t'`vim-cmd vmsvc/get.summary $i 2>dev/null| grep name | cut -c15- | sed 's/...$//'`
done
read -p $'\nAre you sure you want to destroy the VMs listed above? (y/n)' CONFIRMATION
if [ $CONFIRMATION = 'n' ] || [ -r $CONFIRMATION ] || [ -s $CONFIRMATION ]; then 
	echo 'No VMs will be destroyed without explicit CONFIRMATION.' | tee -a ${LOG_FILE}
	echo $'\nReview log file: '${LOG_FILE}$'\n'	
	exit 0	
else
	echo $'\n'`date '+%Y-%m-%d %H:%M:%S '`'Processing started.' | tee -a ${LOG_FILE}
	for i in `cat ${LIST_OF_VMIDS}`; do
		for j in `vim-cmd /vmsvc/getallvms | awk '{print $1}' | tail -n +2`; do
			if [ $i -eq $j ]; then
				#Check for power state
				if [ `vim-cmd /vmsvc/power.getstate $i 2>dev/null | grep -c  "Powered on"` -eq 1 ]; then
					#Power off
					echo `date '+%Y-%m-%d %H:%M:%S '`'Shutting down VM: '`vim-cmd vmsvc/get.summary $i 2>dev/null| grep name | cut -c15- | sed 's/...$//'` | tee -a ${LOG_FILE}
					vim-cmd /vmsvc/power.off $i 1,2>dev/null
				fi
				#Destroy
				echo `date '+%Y-%m-%d %H:%M:%S '`'Destroying VM: '`vim-cmd vmsvc/get.summary $i 2>dev/null| grep name | cut -c15- | sed 's/...$//'` | tee -a ${LOG_FILE}
				vim-cmd /vmsvc/destroy $i 1,2>dev/null
				DESTROYED_COUNT=$((DESTROYED_COUNT+1))
			fi
		done	
	done
	#Review
	for i in `cat ${LIST_OF_VMIDS}`; do
		for j in `vim-cmd /vmsvc/getallvms | awk '{print $1}' | tail -n +2`; do
			if [ $i -eq $j ]; then
				echo `date '+%Y-%m-%d %H:%M:%S '`'Vmid '$i' was not destroyed.' | tee -a ${LOG_FILE}
			fi
		done
	done	
	echo `date '+%Y-%m-%d %H:%M:%S '`'Done processing. '$DESTROYED_COUNT' VMs destroyed.'$'\n' | tee -a ${LOG_FILE}
fi
echo 'Review log file: '${LOG_FILE}$'\n'
#eol
