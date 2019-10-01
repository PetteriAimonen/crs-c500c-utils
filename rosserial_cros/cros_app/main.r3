.include "rosserial.r3"

const TOPICID_TEST = 256

main
    int msg_len
    int offset
    int topic_id
    int[2] prevtime
    int[2] nowtime
    
    mtime(&prevtime)
    
    open(g_rosserial_fd, "/dev/sio0", O_RDWR | O_NONBLOCK, 0)
    
    while 1==1
        rosserial_readwrite()
        
        msg_len = rosserial_start_read_packet(topic_id)
        
        if msg_len == 0 and topic_id == 0 then
            ;; Request for topic list
            printf("Sending topic list\n")
            rosserial_publish(TOPICID_TEST, "/test", "std_msgs/String", "992ce8a1687cec8c8bd883ec73ca41d1")
        elseif msg_len > 0 then
            printf("Got message for topic {}, len {}\n", topic_id, msg_len)
        else
            delay(10)
        end if
        
        rosserial_end_read_packet(msg_len)
        
        mtime(&nowtime)
        
        if nowtime[0] > prevtime[0] + 10000 then
            printf("Sending test message\n")
            offset = rosserial_start_packet(TOPICID_TEST)
            printf("Offset1 {}\n", offset)
            offset = rosmsg_write_string(g_rosserial_txfifo, offset, "Testing!")
            printf("Offset2 {}\n", offset)
            rosserial_end_packet(offset)
            
            mtime(&prevtime)
        end if
    end while
end main
