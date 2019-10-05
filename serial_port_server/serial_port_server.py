#!/usr/bin/env python

# This file implements a simple framing & checksum scheme
# for CROS serial communication on top of simple_message
# protocol.
#
# Each packet will start with sync word 0x??FEFFFF where ?? is the checksum.
# After that comes the simple_message 4-byte length prefix N.
# After that, N bytes of data.
# Checksum is computed as sum of all bytes after the length prefix, mod 256.

import sys
import serial
import socket
import struct

if len(sys.argv) < 4:
    sys.stderr.write("Usage: python serial_port_server.py /dev/ttyS0 115200 11002\n")
    sys.exit(1)

sport = serial.Serial(port = sys.argv[1], baudrate = int(sys.argv[2]), rtscts = True, dsrdtr = True)
#sport = open('/home/robokasi/cutecom.log', 'r')

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(('localhost', int(sys.argv[3])))
server.listen(1)

while True:
    conn, addr = server.accept()
    print 'Connection address:', addr
    try:
        while True:
            sync = sport.read(1)
            while ord(sync) != 0xFF: sync = sport.read(1)
            while ord(sync) != 0xFE: sync = sport.read(1)
            
            checksum = ord(sport.read(1))
            lenword = sport.read(4)
            msg_len = struct.unpack("<I", lenword)[0]
            data = sport.read(msg_len)
            
            #print(' '.join('%02x' % ord(v) for v in data))
            
            expected_checksum = sum(map(ord, data)) & 255
            if expected_checksum == checksum:
                #print("Checksum ok 0x%02x, len %d" % (checksum, msg_len))
                conn.send(lenword + data)
            else:
                print("Checksum fail, 0x%02x vs. 0x%02x, len %d" % (expected_checksum, checksum, msg_len))
    except socket.error, e:
        print(e)
    conn.close()

