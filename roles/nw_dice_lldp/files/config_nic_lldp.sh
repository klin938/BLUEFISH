#!/bin/bash

#
# RC returns -1 for any error
# RC returns 0 for successfully change
# RC return 1 for no change
#

NOCHANGE=1

nic=$1

if [ -z "$nic" ]; then
  echo "Usage: $0 INTERFACE"
  exit -1
fi

stat=$(lldptool -i $nic -t -V sysName)

if [[ "$stat" == *"not found"* ]]; then
  echo "Interface $nic: $stat"
  exit $NOCHANGE
fi

if [ -z "$stat" ]; then
  echo "Interface $nic: enabling lldp"

  lldptool set-lldp -i $nic adminStatus=rxtx

  lldptool -T -i $nic -V sysName enableTx=yes

  lldptool -T -i $nic -V portDesc enableTx=yes

  lldptool -T -i $nic -V sysDesc enableTx=yes

  lldptool -T -i $nic -V sysCap enableTx=yes

  lldptool -T -i $nic -V mngAddr enableTx=yes

  exit 0
else
  echo "Interface $nic: lldp config exist"
  exit $NOCHANGE
fi

exit -1

