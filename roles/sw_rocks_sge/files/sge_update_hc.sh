#!/bin/bash
############################################################
# This is a script that adds any custom complex attributes
# to a SGE node. The script should be run on the execution
# node directly.
#
# - exit 0 successful change
# - exit 2 no change made
# - exit 1 trouble
#
############################################################

exec >> /tmp/sge_update_hc.log
exec 2>&1

# delta-x-x.local etc
HOST=$1

# This is rocks cluster specific, make sure root knows where to
# find SGE binaries
. /etc/profile.d/sge-binaries.sh

qconf -se "$HOST" | grep "complex_values"> /tmp/qconf_se.tmp
qconf_rc=0

function update_nvgpu() {
	nv="$(lspci | grep -i nvidia | wc -l)"

	if [[ "$nv" -gt 0 ]]; then
		printf "\n[$(date)] $HOST: $nv x NVIDIA cards found, adding hc < nvgpu > if not exist...\n"
		qconf -aattr exechost complex_values nvgpu="$nv" "$HOST"
		qconf_rc=$?
	else
		printf "\n[$(date)] $HOST: NO NVIDIA cards found, removing hc < nvgpu > if exist...\n"
		qconf -dattr exechost complex_values nvgpu "$HOST"
		qconf_rc=$?
	fi		
}

#
#
#
function update_fast_dm() {
	# NCI data mover
	DM_NETWORK="129.94.120."
	nic_dev="$(ip addr show | grep $DM_NETWORK | awk '{print $NF}')"
	
	if [[ -z "$nic_dev" ]]; then
		printf "\n[$(date)] $HOST: NCI DM network not configured, removing hc < fast_dm > if exist...\n"
		qconf -dattr exechost complex_values fast_dm "$HOST"
		qconf_rc=$?
	else
		printf "\n[$(date)] $HOST: NCI DM network configured, adding hc < fast_dm > if not exist...\n"
		qconf -aattr exechost complex_values fast_dm=100 "$HOST"
		qconf_rc=$?
	fi
}

#
#
#
function update_mem_req() {
	
	MEMREQ="$(unbuffer qhost -F -h $HOST | grep mem_requested | awk -F= '{print $2}')"
	MEMTOT="$(unbuffer qhost -F -h $HOST | grep mem_total | awk -F= '{print $2}')"
	
	if [[ -z "$MEMREQ" ]]; then
		printf "\n[$(date)] $HOST: adding hc < mem_requested=$MEMTOT >...\n"
		qconf -aattr exechost complex_values mem_requested="$MEMTOT" "$HOST"
		qconf_rc=$?
	else
		printf "\n[$(date)] $HOST: hc < mem_requested=$MEMREQ > set up correctly. No change.\n"
	fi
}

#
#
#
function update_tmp_req() {
	TMPREQ="$(unbuffer qhost -F -h $HOST | grep tmp_requested | awk -F= '{print $2}')"
	TMPTOT="$(unbuffer qhost -F -h $HOST | grep tmptot | awk -F= '{print $2}')"

	if [[ -z "$TMPREQ" ]]; then
		printf "\n[$(date)] $HOST: adding hc < tmp_requested=$TMPTOT >...\n"
		qconf -aattr exechost complex_values tmp_requested="$TMPTOT" "$HOST"
		qconf_rc=$?
	else
		printf "\n[$(date)] $HOST: hc < tmp_requested=$TMPREQ > set up correctly. No change.\n"
	fi
}

printf "\n############################$(date)####################################\n"

case "$2" in
	"nvgpu")
		update_nvgpu
		;;
	"fast_dm")
		update_fast_dm
    		;;
	"mem_requested")
		update_mem_req
		;;
	"tmp_requested")
		update_tmp_req
		;;
	*)
		echo "Usage: $0 HOSTNAME.local [nvgpu|fast_dm|mem_requested|tmp_requested]"
		exit 1
		;;
esac

# when qconf return 0, we need to decide if it was
# successful modification, or no modification made.
if [[ "$qconf_rc" -eq 0 ]]; then
	qconf -se "$HOST" | grep "complex_values" > /tmp/qconf_se.new
	diff /tmp/qconf_se.tmp /tmp/qconf_se.new
	diff_rc=$?
	if [[ "$diff_rc" -eq 0 ]]; then
		exit 2 # NO change found
	elif [[ "$diff_rc" -eq 1 ]]; then
		exit 0 # changes found
	else
		exit "$diff_rc" # trouble
	fi	
else
	exit "$qconf_rc"
fi
