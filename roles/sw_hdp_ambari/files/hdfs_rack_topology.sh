#!/usr/bin/env bash

if [ -z $1 ]; then
	printf "Usage: $0 IP1 IP2 IP3 ...\n"
	exit 2
fi

RACK_DEFAULT=default
RACK_UNKNOWN=unknown
RACK_DICEVM=dice_vm

declare -A RACK_P1

RACK_P1[1]="P1_B1"
RACK_P1[2]="P1_B2"
RACK_P1[3]="P1_B3"
RACK_P1[4]="P1_B4"
RACK_P1[5]="P1_A3"
RACK_P1[6]="P1_A4"

while read -r ip; do
	hostname="$(nslookup $ip | grep "name =" | head -n1 | awk -F " = " '{print $2}')"
	if [ -z "$hostname" ]; then
		printf "/rack-$RACK_UNKNOWN\n"
	else
		# goingmerry-1-11-mlx.mlx
		r="$(echo $hostname | awk -F "-" '{print $2}')"
		s="$(echo $hostname | awk -F "-" '{print $3}')"
		
		#printf "[$ip]   RACK: $r    SLOT: $s    $hostname\n"
		
		if [ "${RACK_P1[$r]+abc}" ]; then
			printf "/rack-${RACK_P1[$r]}\n"
		elif echo "$r" | grep -q 'hdp\|cdp' || echo "$s" | grep -q 'ambari\|ctrl'; then
			printf "/rack-$RACK_DICEVM\n"
		else
			printf "/rack-$RACK_UNKNOWN\n"
		fi
	fi
done <<< "$(echo $@ | xargs -n 1)"

exit 0
