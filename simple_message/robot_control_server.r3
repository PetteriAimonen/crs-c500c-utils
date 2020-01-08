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

;; Message types from https://github.com/ros-industrial/rep/blob/master/rep-I0004.rst#standard-messages
const MSGTYPE_PING = 1
const MSGTYPE_GET_VERSION = 2
const MSGTYPE_JOINT_TRAJ_PT = 11

;; Communication types from https://github.com/gavanderhoorn/rep-ros-i/blob/a88596b8a12b95a1d3bfb0987fa23389c686199a/rep-ixxxx.rst#communication-types
const COMMTYPE_TOPIC = 1
const COMMTYPE_REQUEST = 2
const COMMTYPE_REPLY = 3

;; Reply codes from https://github.com/gavanderhoorn/rep-ros-i/blob/a88596b8a12b95a1d3bfb0987fa23389c686199a/rep-ixxxx.rst#reply-codes
const REPLYTYPE_INVALID = 0
const REPLYTYPE_SUCCESS = 1
const REPLYTYPE_FAILURE = 2

;; Special sequence numbers
const SEQ_START_TRAJECTORY_DOWNLOAD = -1
const SEQ_START_TRAJECTORY_STREAMING = -2
const SEQ_START_END_TRAJECTORY = -3
const SEQ_STOP_TRAJECTORY = -4

typedef ping_t struct
    int[10] data
end struct

typedef joint_traj_pt_t struct
    int sequence
    float[10] joints
    float velocity
    float duration
end struct

typedef request_packet_t struct
    int msg_type
    int comm_type
    int reply_code
    union
        ping_t ping
        get_version_t get_version
        joint_traj_pt_t joint_traj_pt
    end union payload
    int[10] reserved
end struct

typedef get_version_t struct
    int major
    int minor
    int patch
end struct

typedef reply_packet_t struct
    int msg_type
    int comm_type
    int reply_code
    union
        get_version_t version
        int[10] reserved
    end union payload
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

func process_trajectory_point(joint_traj_pt_t trajpt)
    ploc robot_pos
    float[8] joint_angles
    float rad_to_deg
    rad_to_deg = 180.0 / 3.1415926535
    int status
    int speed_percent
    static int prev_sequence = 0

    if trajpt.sequence == SEQ_START_TRAJECTORY_DOWNLOAD then
        printf("Trajectory download not supported!\n")
        return false
    elseif trajpt.sequence == SEQ_START_TRAJECTORY_STREAMING then
        ;; This message is not currently used by ROS
        return true
    elseif trajpt.sequence == SEQ_STOP_TRAJECTORY then
        robot_abort()
        return true
    elseif trajpt.sequence >= 0
        if trajpt.sequence == 0
            ;; Start of new trajectory
            if ctl_get() < 0 then
                printf("Failed to get point of control.\n")
                return false
            end if
            
            online(ON)
            prev_sequence = 0
        elseif trajpt.sequence != prev_sequence + 1 then
            printf("Wrong sequence number: {} after {}\n", trajpt.sequence, prev_sequence)
            robot_abort()
            return false
        end if
        
        loc_class_set(robot_pos, loc_precision)
        here(robot_pos) ;; To initialize flags & machine type
        
        joint_angles[0] = -trajpt.joints[0] * rad_to_deg
        joint_angles[1] = -trajpt.joints[1] * rad_to_deg
        joint_angles[2] = -trajpt.joints[2] * rad_to_deg
        joint_angles[3] = -trajpt.joints[3] * rad_to_deg
        joint_angles[4] = -trajpt.joints[4] * rad_to_deg
        joint_angles[5] = -trajpt.joints[5] * rad_to_deg
        speed_percent = <int>(trajpt.velocity * 100 + 0.5)
        if speed_percent < 1 then
            speed_percent = 1
        elseif speed_percent > 100 then
            speed_percent = 100
        end if
        
        printf("Would move to {5.1} {5.1} {5.1} {5.1} {5.1} {5.1} at speed {}\n"
               joint_angles[0], joint_angles[1], joint_angles[2], 
               joint_angles[3], joint_angles[4], joint_angles[5], 
               speed_percent)

        ;;speed_set(speed_percent)
        ;;joint_to_motor(joint_angles, robot_pos)
        ;;status = move(robot_pos)
        
        if status < 0 then
            printf("move() failed: {}\n", status)
            return false
        end if
        
        return true
    end if

    printf("Unknown sequence number: {}\n", trajpt.sequence)
    robot_abort()
    return false
end func

sub process_single_packet(int fd)
    request_packet_t request
    reply_packet_t reply
    int packet_len
    packet_len = read_packet(fd, &request, sizeof(request))

    if packet_len > 0 then
        memset(&reply, 0, sizeof(reply))

        if request.msg_type == MSGTYPE_PING then
            reply.msg_type = MSGTYPE_PING
            reply.comm_type = COMMTYPE_REPLY
            reply.reply_code = REPLYTYPE_SUCCESS
            write_packet(fd, &reply, 13)
        elseif request.msg_type == MSGTYPE_GET_VERSION then
            reply.msg_type = MSGTYPE_GET_VERSION
            reply.comm_type = COMMTYPE_REPLY
            reply.reply_code = REPLYTYPE_SUCCESS
            reply.payload.version.major = 1
            reply.payload.version.minor = 0
            reply.payload.version.patch = 0
            write_packet(fd, &reply, 6)
        else if request.msg_type == MSGTYPE_JOINT_TRAJ_PT then
            reply.msg_type = MSGTYPE_JOINT_TRAJ_PT
            reply.comm_type = COMMTYPE_REPLY
            if process_trajectory_point(request.payload) then
                reply.reply_code = REPLYTYPE_SUCCESS
            else
                reply.reply_code = REPLYTYPE_FAILURE
            end if
            write_packet(fd, &reply, 13)
        end if
    end if
end sub

main
    int fd
    int seq = 0
    
    open(fd, "/dev/sio1", O_RDWR | O_BINARY, 0)
    
    sio_ioctl_conf serial_conf
    ioctl(fd, IOCTL_GETC, &serial_conf)
    serial_conf.baud = 115200
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
        process_single_packet(fd)
    end while
end main

