#!/bin/bash

# this is an official way of telling Rocks to format OS
# drive and recreate it in the next rebuild.
for file in $(mount | awk '{print $3}')
do
        if [ -f $file/.rocks-release ]; then
                rm -f $file/.rocks-release
        fi
done

printf "INFO: file .rocks-release removed.\n"


