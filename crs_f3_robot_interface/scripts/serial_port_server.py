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
import select

class SerialPortServer:
    def __init__(self, hostname, tcp_port, serial_port, baudrate):
        self.connections = []
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.socket.bind((hostname, tcp_port))
        self.socket.listen(5)
        
        self.serial = serial.Serial(port = serial_port, baudrate = baudrate, rtscts = True)
        self.rx_packet = ''
    
    def handle_serial(self):
        '''Handle any waiting data on the serial port.'''
        waiting = self.serial.inWaiting()
        if waiting > 0:
            self.rx_packet += self.serial.read(waiting)
        
        while len(self.rx_packet) >= 8:
            if self.rx_packet[:3] != '\xFF\xFF\xFE':
                # Skip bytes until packet start
                pos = self.rx_packet.find('\xFF\xFF\xFE', 1)
                if pos > 0:
                    self.rx_packet = self.rx_packet[pos:]
                else:
                    self.rx_packet = self.rx_packet[-2:]
                    return
        
            if len(self.rx_packet) < 8:
                return
        
            lenword = self.rx_packet[4:8]
            msg_len = struct.unpack("<I", lenword)[0]
            
            if msg_len > 4096:
                sys.stderr.write("Rejecting too long packet: %d\n" % msg_len)
                self.rx_packet = self.rx_packet[3:]
                return
            
            if len(self.rx_packet) < msg_len + 8:
                # Packet is not yet complete
                return
            
            payload = self.rx_packet[8:msg_len + 8]
            checksum = sum(map(ord, payload)) & 255
            
            if checksum != ord(self.rx_packet[3]):
                sys.stderr.write("Checksum in packet 0x%02x, actual 0x%02x, data %s\n" %
                                 (ord(self.rx_packet[3]), checksum, 
                                  ' '.join('%02x' % ord(x) for x in payload)))
                self.rx_packet = self.rx_packet[3:]
                return
            
            to_remove = []
            
            for connection in self.connections:
                try:
                    connection.send(lenword + payload)
                except socket.error, e:
                    sys.stderr.write("Connection error: %s\n" % e)
                    connection.close()
                    to_remove.append(connection)
            
            for conn in to_remove:
                self.connections.remove(conn)
            
            self.rx_packet = self.rx_packet[msg_len + 8:]

    def handle_new_connection(self):
        '''Handle new incoming connection'''
        conn, addr = self.socket.accept()
        sys.stderr.write("Connection from %s\n" % str(addr))
        conn.settimeout(0.5)
        self.connections.append(conn)

    def handle_packet_from_connection(self, connection):
        '''Handle packet coming from active network connection.'''
        try:
            lenword = connection.recv(4)
            
            if not lenword:
                sys.stderr.write("Connection closed.\n")
                connection.close()
                self.connections.remove(connection)
                return
            
            msg_len = struct.unpack("<I", lenword)[0]

            if msg_len > 4096:
                raise Exception("Rejecting invalid length: %d" % msg_len)
            
            payload = connection.recv(msg_len)
            checksum = sum(map(ord, payload)) & 255
            self.serial.write("\xFF\xFF\xFE" + chr(checksum) + lenword + payload)
        except Exception, e:
            sys.stderr.write("Invalid packet from network: %s\n" % e)
            connection.close()
            self.connections.remove(connection)

    def wait_and_handle(self, timeout):
        '''Wait for event and handle it.'''
        ports = [self.serial, self.socket] + self.connections
        readable, writable, errored = select.select(ports, [], self.connections, timeout)

        for conn in errored:
            sys.stderr.write("Connection closed.\n")
            self.connections.remove(conn)
        
        for conn in readable:
            if conn is self.serial:
                self.handle_serial()
            elif conn is self.socket:
                self.handle_new_connection()
            elif conn in self.connections:
                self.handle_packet_from_connection(conn)

if __name__ == '__main__':
    if len(sys.argv) < 4:
        sys.stderr.write("Usage: python serial_port_server.py /dev/ttyS0 115200 11002\n")
        sys.exit(1)

    server = SerialPortServer("localhost", int(sys.argv[3]), sys.argv[1], int(sys.argv[2]))
    
    while True:
        server.wait_and_handle(1.0)
