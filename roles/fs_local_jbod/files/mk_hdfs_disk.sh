#!/bin/bash

#
# The partition suffix is different between SAS/SATA and NVMe:
#
# SAS/SATA - look like sdc1 sdd1 sde1 so the var is "1"
#
# NVMe/SSD - look like nvme3n1p1 nvme9n1p1 so the var is "p1"
#
PARTSUFFIX="$1"
EXT_LABEL="$2"

#
# BASH101 remove first two elements from the args array the
# rest of args is expected to be a list of block dev which
# will be put into a new array.
#
set -- "${@:3}"
DISKS=( "$@" )
NUM_DISKS="${#DISKS[@]}"

printf "INFO: [$NUM_DISKS] block devices selected for HDFS on this node:\n"
printf '%s\n' "${DISKS[@]}"

rc=0
disk_modified=0

for i in "${DISKS[@]}";
do
	if [[ ! -e "$i$PARTSUFFIX" || "$(/sbin/e2label $i$PARTSUFFIX)" != "$EXT_LABEL" ]]; then
		printf "INFO: $i$PARTSUFFIX neither exist nor having the expected format, it will be created.\n"
		
		echo -e "rm 1\n quit " | parted $i # try to remove it anyway
		sleep 5

		echo -e "mklabel msdos\n mkpart primary 1 -1\n quit " | parted $i
		sleep 5

		mke2fs -t ext4 -E nodiscard -L $EXT_LABEL $i$PARTSUFFIX
                (( rc += $? ))
                (( disk_modified += 1 ))
	else
		printf "SKIPPED: $i$PARTSUFFIX exists and has the expected format.\n"
	fi
done

if [ "$disk_modified" -eq 0 ]; then
	printf "INFO: no disk has been modified, no change required.\n"
	exit 0
else
	exit $rc
fi


