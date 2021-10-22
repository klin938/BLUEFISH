#!/bin/bash

# the blacklist item can be any information provided by smartctl -i such as:
# Model Number:                       Dell Express Flash NVMe P4500 4.0TB SFF
# Serial Number:                      PHLF814501WD4P0IGN
# Firmware Version:                   QDV1DP15

BLACKLIST=(SSDPED1K750GA PLACEHOLDER)

DISKS=( "$@" )
NUM_DISKS="${#DISKS[@]}"

declare -a filtered_disks

for d in "${DISKS[@]}";
do
        for bl in "${BLACKLIST[@]}";
        do
                if smartctl -i $d | grep -q $bl; then
                        #echo "Block device $d is on the /dev/md127 blacklist: $bl, skipping..."
                        break
                fi
                # if reach the end of the blacklist, this disk is selected
                if [ "$bl" == ${BLACKLIST[-1]} ]; then
                        filtered_disks+=( $d )
                fi
        done
done

num_filtered_disks=${#filtered_disks[@]}

printf '%s\n' "${filtered_disks[@]}" | tr '\n' ' '

exit 0
