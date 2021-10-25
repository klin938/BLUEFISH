#!/bin/bash

#
# mount or umount
#
ACTION="$1"
#
# A number which is deduced from the list of block dev will be
# appended to the prefix, when prefix is "d" for example, the
# mount point name will be:
# 
# d0, d1, d2 etc.
#
MNT_PREFIX="$2"
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

END="$(( $NUM_DISKS - 1 ))"

for i in $(seq 0 $END);
do
	mnt_point="$MNT_PREFIX$i"

	if [ "$ACTION" = "mount" ]; then
		printf "INFO: mounting ${DISKS[$i]}$PARTSUFFIX to /${mnt_point}\n"
		mkdir "/$mnt_point"
		chmod 777 "/$mnt_point"
		mount ${DISKS[$i]}$PARTSUFFIX /$mnt_point

	elif [ "$ACTION" = "umount" ]; then
		printf "INFO: umounting ${DISKS[$i]}$PARTSUFFIX from /${mnt_point}\n"
		fuser -k "/$mnt_point"
		sleep 20
		umount -f "/$mnt_point"
		sleep 10
		rm -rf "/$mnt_point"
	fi
done
exit 0

