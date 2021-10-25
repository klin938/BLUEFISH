#!/bin/bash

#
# The partition suffix is different between SAS/SATA and NVMe:
#
# SAS/SATA - look like sdc1 sdd1 sde1 so the var is "1"
#
# NVMe/SSD - look like nvme3n1p1 nvme9n1p1 so the var is "p1"
#
PARTSUFFIX="$1"
#
# Remove the first element from the args array. The remaining
# should be just list of block dev and will be put into a new
# array.
#
set -- "${@:2}"
DISKS=( "$@" )
NUM_DISKS="${#DISKS[@]}"

for i in "${DISKS[@]}";
do
	printf "INFO: formating block device $i$PARTSUFFIX.\n"
	dd if=/dev/zero of=$i$PARTSUFFIX bs=1M count=1024
	echo -e "rm 1\n quit " | parted $i
	sleep 5
done

exit 0

