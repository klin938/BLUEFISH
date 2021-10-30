#!/bin/bash
############################################################
# This is a script that adds any custom complex attributes
# to a SGE node. The script should be run when:
# 1) adding new nodes
# 2) capacity expansion (add more RAM etc). In this case, make
#    sure to delete the existing complex attr FIRST, so the
#    script add it back with the updated amount.
############################################################

exec >> /tmp/sge_add_complex_attr.log
exec 2>&1

printf "\n############################$(date)####################################\n"

# Supply a hostname or get current host
_hostname=${1:-`/bin/hostname`}

# This is rocks cluster specific, make sure root knows where to
# find SGE binaries
. /etc/profile.d/sge-binaries.sh

qconf -se $_hostname > /tmp/qconf_se.tmp

qconf_run=0
qconf_rc=0

###############################
# Add or udpate complex attr
# tmp_requested
###############################
TMPREQ=`unbuffer qhost -F -h $_hostname | grep tmp_requested | awk -F= '{print $2}'`
TMPTOT=`unbuffer qhost -F -h $_hostname | grep tmptot | awk -F= '{print $2}'`

if [[ -z "$TMPREQ" ]]; then
        printf "\ntmp_requested not found, adding it now (tmp_requested=$TMPTOT)...\n"
        qconf -aattr exechost complex_values tmp_requested="$TMPTOT" "$_hostname"
        ((qconf_rc+=$?))
        ((qconf_run++))
else
        printf "\ntmp_requested($TMPREQ) has been set up correctly. No change required.\n"
fi

###############################
# Add or udpate complex attr
# mem_requested
###############################
MEMREQ=`unbuffer qhost -F -h $_hostname | grep mem_requested | awk -F= '{print $2}'`
MEMTOT=`unbuffer qhost -F -h $_hostname | grep mem_total | awk -F= '{print $2}'`

if [[ -z "$MEMREQ" ]]; then
        printf "\nmem_requested not found, adding it now (mem_requested=$MEMTOT)...\n"
        qconf -aattr exechost complex_values mem_requested="$MEMTOT" "$_hostname"
        ((qconf_rc+=$?))
        ((qconf_run++))
else
        printf "\nmem_requested($MEMREQ) has been set up correctly. No change required.\n"
fi

##############################
# Compare new changes. Mainly
# for debugging purposes.
##############################
qconf -se $_hostname > /tmp/qconf_se.new

diff /tmp/qconf_se.tmp /tmp/qconf_se.new

#
# We notify Ansible three different outcomes according
# to the values of qconf_run and qconf_rc.
#
if [[ "$qconf_run" -eq 0 ]]; then
        exit 0 # qconf not run, no change
elif [[ "$qconf_rc" -eq 0 ]]; then
        exit 1 # qconf ran without error
else
        exit 2 # qconf ran with error
fi
