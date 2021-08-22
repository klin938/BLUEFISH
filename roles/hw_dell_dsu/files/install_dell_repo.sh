#!/bin/bash

cd /tmp
curl -O https://linux.dell.com/repo/hardware/dsu/bootstrap.cgi

# PADMIN-36 this expect script handles the first expect string as optional prompt
# which will NOT  appear if the CGI has completed successfully previously.
/usr/bin/expect -c '
set timeout 20
spawn bash /tmp/bootstrap.cgi
expect {
	"Do you want*" {
		send "y\r"
		exp_continue
	}
	"Done" {
		expect eof
	}
}
'

exit $?
