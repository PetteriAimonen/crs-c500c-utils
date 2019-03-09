#!/usr/bin/python
# Downloads nvram contents from the bootloader mode.
# To enter bootloader, boot C500C with F1, F2 and P/C held down.
#
# Filesystem copying is activated by "fsave now", after which the controller
# sends some header. This should be acknowledged with 0x06, after which the
# controller sends 1028 byte block. First 3 bytes are header and last 1 byte
# is some kind of checksum, which this script ignores.

import sys
import serial
import time
s = serial.Serial("/dev/ttyUSB0", 57600, timeout = 0.2)

if len(sys.argv) < 2 or sys.argv[1] not in ('nvram', 'flash'):
    sys.stderr.write("Usage: bootloader_download.py <nvram|flash>")
    sys.exit(1)

if sys.argv[1] == 'nvram':
    s.write("\nnvsave now\n")
    outfile = open('nvram.bin', 'wb')
else:
    s.write("\nfsave now\n")
    outfile = open('flash.bin', 'wb')

time.sleep(1.0)
print repr(s.read(1024))
s.write("\r")
time.sleep(1.0)
print repr(s.read(1024))

while True:
    s.write('\x06')
    time.sleep(0.2)
    data = s.read(1028)
    
    if data[0] != '\x02':
        break
    
    outfile.write(data[3:][:1024])
    
    print("Got %d bytes: %s..%s" % (len(data), repr(data)[:30], repr(data)[-10:]))
    
    if len(data) < 1024:
        break

