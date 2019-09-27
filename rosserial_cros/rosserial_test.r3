.include "rosserial_packets.r3"

main
    string[]@ serialport
    int fd
    rosserial_packet p
    
    open(fd, serialport@, O_RDWR, 0)
    
    while 1==1
        if rosserial_recv_packet(fd, p) == true then
            printf("Got packet, len: %d, topic: %d\n", p.msg_len, p.topic_id)
        end if
    end while
end main
