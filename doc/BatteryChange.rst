Changing CRS F3 Robot Arm Batteries
-----------------------------------

The F3 robot arm contains 3 AA NiMH batteries behind the connector
cover in the bottom of the arm assembly. The batteries are
used to retain encoder position while the arm is powered off.

The drain on the batteries should be somewhere between
0.1 mA and 0.6 mA, it appears to vary. When the robot is powered
on the batteries are charged with 30 mA current. When left off,
the batteries will run out in less than a year.

Empty and leaked batteries is a common problem for many broken
F3 robot arms, and is relatively easy to fix.

The batteries can be replaced with either alkaline or low-discharge
NiMH batteries. After replacement the robot needs to be rehomed.

For homing, all the axes need to be moved into position indicated
by calibration markers near the joints. To be able to move the three
largest axes, power up the controller and hold down brake release
button on the side of the arm.

In CROS console execute `/diag/encres`, `/diag/zero` and finally `/diag/cal`.
After executing these commands, the status command `w2` should report pulse
count on all axes as 0 pulses (+-1 errors are common), and also joint angles
as 0.00 degrees (+-0.01 errors are common).

Restart the controller.

To verify that the calibration works, use the pendant to move the robot
head to close to a horizontal surface in `VEL JOINT` mode. Then switch to 
`VEL WORLD` mode, and test moves in X and Y directions. Robot should
keep constant distance from the surface. Usually if calibration is wrong,
robot will entirely refuse to move in `VEL WORLD` mode.

