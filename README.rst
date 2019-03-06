Tools for Thermo CRS C500C Robot Controller
===========================================

This repository contains various tools that are useful with the Thermo CRS
C500C robot arm controllers. These were manufactured between 1997 and 2002
and are used with CRS F3, A465 and A255 robot arms.

Various documentation can be found on Google, I have collected them here:
http://jpa.kapsi.fi/stuff/other/crs_robot/

Original software
-----------------
The original system is meant to be used with Robcomm3 Windows software, which
I do not have available. It would directly support file transfer to and from
the controller using some unknown protocol.

The controller itself runs some kind of embedded Unix-alike called CROS. It
can be accessed by the serial port on the front of the device with default
baudrate of 57600 bps.

The controller has both a nvram-based filesystem backed up by a 3.6V lithium
battery, and a flash memory that is used to initialize the filesystem if the
backup battery fails. By holding down F1, F2 and P/C buttons down while booting
the device goes into diagnostic mode that allows transferring flash and nvram
contents to/from PC using XMODEM protocol.

In the filesystem there is available a few useful tools, such as `r3c` compiler
for the RAPL-3 language and `edit` as a simple line editor.

File transfer
-------------
To permit easy file transfer between PC and CROS, first step is to install
`uudecode` on the target. After that other files can be transferred using it.

G Code interpreter
------------------
Eventual goal of this project is to implement a G code interpreter in RAPL-3.
It would read G-code commands from the serial port and execute them as robot
movements.

