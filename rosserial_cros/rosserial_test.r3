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
    end while
end main
