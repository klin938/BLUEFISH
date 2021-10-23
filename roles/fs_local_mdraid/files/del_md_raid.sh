#!/bin/bash

MOUNT_POINT="$1"
MD_DEV_NAME="$2"
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

umount -f $MOUNT_POINT
sleep 5

mdadm --stop /dev/$MD_DEV_NAME
sleep 5
	
for i in "${DISKS[@]}";
do
	printf "INFO: mdadm zeroing superblock of $i$PARTSUFFIX.\n"
	mdadm --zero-superblock $i$PARTSUFFIX --force
	sleep 5
	echo -e "rm 1\n quit " | parted $i;
done
	
sleep 5

exit 0

