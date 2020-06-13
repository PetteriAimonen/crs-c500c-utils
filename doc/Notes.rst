The system has a 486 processor for the main operating system.

RAPL-3 code appears to execute under some kind of bytecode interpreter in /sbin/r3interp.
The bytecode interpreter works on 32-bit instructions where the first byte
is opcode and the three following bytes identify source and destination registers.

A simple for loop executes at 174000 iterations per second.

Most binaries appear to be in bytecode, but /bin/rc1 compiler is in x86 machine code.
It gets identified as rc1: FreeBSD/i386 compact demand paged executable

crosver tells:
System type: 'CROS-104 on a C500C'
Version:     3.1.1249
Click size:  4096
msec/tick:   5


