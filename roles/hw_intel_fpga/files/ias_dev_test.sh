#!/bin/bash

ias_home="${1:-/opt/inteldevstack}"

source $ias_home/init_env.sh

rc=0

fpgabist $OPAE_PLATFORM_ROOT/hw/samples/nlb_mode_3/bin/nlb_mode_3_unsigned.gbs
(( rc += $? ))

sleep 5

fpgabist $OPAE_PLATFORM_ROOT/hw/samples/dma_afu/bin/dma_afu_unsigned.gbs
(( rc += $? ))

sleep 5

fpgasupdate $OPAE_PLATFORM_ROOT/hw/samples/nlb_mode_0/bin/nlb_mode_0_unsigned.gbs
(( rc += $? ))

cd $OPAE_PLATFORM_ROOT/sw

tar xf opae-1.1.2-2.tar.gz

cd opae-1.1.2-2

gcc -o hello_fpga -std=gnu99 -rdynamic -ljson-c -luuid -lpthread -lopae-c -lm -Wl,-rpath -lopae-c $OPAE_PLATFORM_ROOT/sw/opae*/samples/hello_fpga.c

./hello_fpga
(( rc += $? ))

exit $rc
