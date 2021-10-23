#!/bin/bash

MD_DEV_NAME="$1"
MD_RAID_LEVEL="$2"
#
# The partition suffix is different between SAS/SATA and NVMe:
#
# SAS/SATA - look like sdc1 sdd1 sde1 so the var is "1"
#
# NVMe/SSD - look like nvme3n1p1 nvme9n1p1 so the var is "p1"
#
PARTSUFFIX="$3"

# BASH101 remove first three elements from the args array the
# rest of args should be just the block dev which will be put
# in a new array.
set -- "${@:4}"
DISKS=( "$@" )
NUM_DISKS="${#DISKS[@]}"

printf "INFO: [$NUM_DISKS] block devices selected for MD RAID:\n"
printf '%s\n' "${DISKS[@]}"

if [ ! -e /dev/$MD_DEV_NAME ]; then

	printf "INFO: /dev/$MD_DEV_NAME does not exist, proceeding to the array assembling.\n"

	for i in "${DISKS[@]}";
	do
		if [ ! -e $i$PARTSUFFIX ]; then
			printf "INFO: $i$PARTSUFFIX does not exist, new partition will be created on ${i}.\n"
			parted -s $i "mklabel gpt" "mkpart primary 1 -1" "set 1 raid on"
			sleep 5
		else
			printf "SKIPPED: $i$PARTSUFFIX partition exists.\n"
		fi	
		
		mdadm --zero-superblock $i$PARTSUFFIX --force
		array_disks="$array_disks $i$PARTSUFFIX"
	done
	
	printf "INFO: assembling MD RAID, MD_DEV: [/dev/$MD_DEV_NAME] RAID_LEVEL: [$MD_RAID_LEVEL] RAID_MEMBER: [$array_disks]\n"

	if [[ "$MD_RAID_LEVEL" -eq 1 ]]; then
		expect -c "set timeout 10" -c "spawn /sbin/mdadm -C /dev/$MD_DEV_NAME -l $MD_RAID_LEVEL -n $NUM_DISKS $array_disks" \
			-c "expect -re \"Continue.*\"" -c "send \"yes\r\"" -c "expect eof"
	else
		mdadm -C /dev/$MD_DEV_NAME -l $MD_RAID_LEVEL -n $NUM_DISKS $array_disks --force
	fi

	sleep 5
	mdadm -D --test /dev/$MD_DEV_NAME
	# We only care about the final RAID assmebly result. Partitioning or
        # zero superblock of each block dev are fail OK tasks as they are
        # just acting as extra checking the device condition. --test option
	# will return 0 if normal or 1, 2, 4 for failures.
else
	printf "SKIPPED: /dev/$MD_DEV_NAME found, no change required.\n"
fi
