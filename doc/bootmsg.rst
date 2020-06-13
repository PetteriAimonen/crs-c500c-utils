CRS C500C Diagnostic Monitor v2.0
Initializing MCE...Ok.
Testing h/w semaphores...Ok.
Motherboard SN: RCB0218428
Booting...
System has 870 free pages (3563520K)

CROS -- CRS Robot Operating System -- v 3.1.1249

sio0: serial I/O Hardware found: NS16550
sio1: serial I/O Hardware found: NS16550
sio2: serial I/O Hardware found: NS16550
sio3: serial I/O Hardware found: NS16550
fpanel: Initializing front panel
mce0: MCE Driver V1.0
mce0: detected by probe (0x0ab1eca9)
lpt0: parallel port driver V1.0
lpt0: supports SPP, PS2, ECP
Checking the Memory FileSystem (NVFS)...
  Phase Ia: check inode sanity
  Phase Ib: check allocation bitmap
  Phase II: check connectivity
  Phase IIIa: make files contiguous
  Phase IIIb: defragment
The NVFS is valid.
Mounting root MFS filesystem.
Checking that NVRAM and FLASH images match...

init (process 1) is now running
mce0: loading firmware
mce0: firmware load complete (196396 bytes loaded).
mce0: MCE Version Code:
MCE Core 2.1.1236 Jun 15 2001 09:37:17
F3 Kinematics Model v2.00, Jun 15 2001 09:37:58
init: running /bin/shell -c /conf/rc
(No ACI daemon running)
$$ #! /bin/shell
$$ 
$$ # Rotate the High-performance Com Link log files and start the daemon:
$$ rm /log/hcl.log.2
$$ mv -f /log/hcl.log.1 /log/hcl.log.2
$$ mv -f /log/hcl.log.0 /log/hcl.log.1
$$ mv -f /log/hcl.log   /log/hcl.log.0
$$ /sbin/hcl -q &
[Started process 13]
$$ 
$$ # Start the robot server and initialize the robot
$$ /sbin/robotsrv &
[Started process 15]
$$ msleep 1000
��/sbin/robotsrv: Metric units in use
/sbin/robotsrv: machine axes: 6, transform axes: 6, total axes: 6
/sbin/robotsrv: kinematics and F-network initialization succeeded
/sbin/robotsrv: Robot calibration data read
/sbin/robotsrv: F Robot calibrated
/sbin/robotsrv: Gripper cal data read
/sbin/robotsrv: Robot has been running for 6235.23 hours
$$ /sbin/f3adjust


***** Running amplifier diagnostics *****

Amplifier Status
1......OK   2......OK   3......OK   
4......OK   5......OK   6......OK   
$$ 
$$ # Check the startup.sh file
$$ /bin/auto -c
$$ 
$$ exit 0

init: starting interactive shell[process 25]

(Connecting to ACID)
$$ pendant &
[Started process 27]
$$ 
$ 

