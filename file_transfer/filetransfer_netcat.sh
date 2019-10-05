#!/bin/bash

# This is a simple script to send files to CROS.
# It assumes that there is ncat on localhost:11010 connected to
# to the CROS serial port, as implemented by cros_console.service.
# It also requires you've already installed uudecode in /bin.
#
# Then just run: ./filetransfer_netcat.sh myfile.r3
#
# Files will be dumped in the current directory on CROS side.

TMP=`tempfile`
for var in "$@"
do
    (
        echo uudecode
        uuencode $var $var
        echo
    ) | netcat -q 2 localhost 11010 >/dev/null
done


