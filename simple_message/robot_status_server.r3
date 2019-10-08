;; This file implements the robot status reporting server for
;; ROS Industrial simple_message protocol, as described in
;; http://wiki.ros.org/simple_message and
;; https://github.com/gavanderhoorn/rep-ros-i/blob/a88596b8a12b95a1d3bfb0987fa23389c686199a/rep-ixxxx.rst
;;
;; The nodes implemented in industrial_robot_client package
;; expect this service to be available on TCP port 11002.
;; The serial port can be configured with stty and socat/ncat
;; can be used to connect it to the TCP port.

.include "serial_framing.r3"

typedef joint_position_t struct
    int msgtype
    int commtype
    int replytype
    int sequence
    float[10] joints
end struct

sub send_joint_position(int fd)
    ploc robot_pos
    float[8] joint_angles
    joint_position_t packet
    float deg_to_rad
    deg_to_rad = 3.1415926535 / 180.0

    ;; Get robot position
    loc_class_set(robot_pos, loc_precision)
    here(robot_pos)
    motor_to_joint(robot_pos, joint_angles)

    memset(&packet, 0, sizeof(packet))
    packet.msgtype = 10  ;; MsgType 10=JOINT_POSITION
    packet.commtype = 1  ;; CommType 1=TOPIC
    packet.replytype = 0 ;; ReplyType 0=INVALID
    packet.sequence = 0  ;; Sequence is not used for status reports

    ;; This is designed to be used with the KUKA KR3 model on ROS side,
    ;; which is dimensionally equivalent but rotation angles are
    ;; reversed compared to CRS F3 representation.
    packet.joints[0] = -joint_angles[0] * deg_to_rad
    packet.joints[1] = -joint_angles[1] * deg_to_rad
    packet.joints[2] = -joint_angles[2] * deg_to_rad
    packet.joints[3] = -joint_angles[3] * deg_to_rad
    packet.joints[4] = -joint_angles[4] * deg_to_rad
    packet.joints[5] = -joint_angles[5] * deg_to_rad
    
    write_packet(fd, &packet, sizeof(packet))
end sub

typedef status_t struct
    int msgtype
    int commtype
    int replytype
    int drives_powered
    int e_stopped
    int errorcode
    int in_error
    int in_motion
    int mode
    int motion_possible
end struct

sub send_status(int fd)
    status_t packet
    int[8] axstatus
    int i
    
    axis_status(axstatus)
    
    memset(&packet, 0, sizeof(packet))
    packet.msgtype = 13  ;; MsgType 13=STATUS
    packet.commtype = 1  ;; CommType 1=TOPIC
    packet.replytype = 0 ;; ReplyType 0=INVALID
    
    if robotispowered() > 0 then
        packet.drives_powered = 1
    else
        packet.drives_powered = 0
    end if
    
    packet.e_stopped = -1
    
    for i = 0 to 5
        ;; Check axis error status bits
        if axstatus[i] & 0x4710 != 0 then
            packet.errorcode = (axstatus[i] << 8) | (i + 1)
            packet.in_error = 1
        end if
    end for
    
    for i = 0 to 5
        ;; Check axis done bit
        if axstatus[i] & 0x8000 == 0 then
            packet.in_motion = 1
        end if
    end for
    
    packet.mode = -1 ;; Manual / automatic mode not implemented yet
    packet.motion_possible = 1
    
    write_packet(fd, &packet, sizeof(packet))
end sub

main
    int fd
    int seq = 0
    
    open(fd, "/dev/sio1", O_RDWR | O_BINARY, 0)
    
    sio_ioctl_conf serial_conf
    ioctl(fd, IOCTL_GETC, &serial_conf)
    serial_conf.baud = 57600
    serial_conf.OutxCtsFlow = 1
    serial_conf.OutxDsrFlow = 1
    serial_conf.DtrControl = 1
    serial_conf.DsrSensitivity = 1
    serial_conf.OutX = 0
    serial_conf.InX = 0
    serial_conf.RtsControl = 1
    serial_conf.fifotrig = 2
    ioctl(fd, IOCTL_PUTC, &serial_conf)
    
    while 1==1        
        send_joint_position(fd)
        send_status(fd)
        
        printf("Sent packet {}\n", seq)
        seq += 1
    end while
end main

