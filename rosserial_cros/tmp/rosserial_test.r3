.include "rosmsg.r3"
.include "TopicInfo.r3"
.include "JointState.r3"
.include "rosserial_packets.r3"

main
    int fd
    int status
    rosserial_packet p
    
    open(fd, "/dev/sio0", O_RDWR, 0)
    
    while 1==1
        status = rosserial_recv_packet(fd, p)
        if status == 0 then
            printf("Got packet, len: {}, topic: {}\n", p.msg_len, p.topic_id)
        else
            printf("Recv status: {}\n", status)
        end if
        
        if p.topic_id == 0 and p.msg_len = 0 then
            ;; Request for topic list
            printf("Sending topic list\n")
            rosmsg_rosserial_msgs_TopicInfo topic_msg
            memset(&topic_msg, 0, sizeof(topic_msg))
            topic_msg.topic_id = 255
            str_append(topic_msg.topic_name, "/test")
            str_append(topic_msg.message_type, rosmsg_sensor_msgs_JointState_type)
            str_append(topic_msg.md5sum, rosmsg_sensor_msgs_JointState_md5)
            topic_msg.buffer_size = ROSSERIAL_MAXPACKETLEN
            
            p.topic_id = rosserial_msgs_ID_PUBLISHER
            p.msg_len = rosmsg_rosserial_msgs_TopicInfo_serialize(p.msg_data, 0, topic_msg)
            
            rosserial_send_packet(fd, p)
        end if
    end while
end main
