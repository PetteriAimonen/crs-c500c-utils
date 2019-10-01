.ifndef ROSSERIAL_PACKETS_INCLUDED
.define ROSSERIAL_PACKETS_INCLUDED

.include "rosmsg.r3"

.ifndef ROSSERIAL_MAXPACKETLEN
.define ROSSERIAL_MAXPACKETLEN 256
.endif

.ifndef ROSSERIAL_FIFOLEN
.define ROSSERIAL_FIFOLEN 512
.endif

const TOPICID_PUBLISH   = 0
const TOPICID_SUBSCRIBE = 1
const TOPICID_LOG       = 7
const TOPICID_TIME      = 10

int g_rosserial_fd = -1
int g_rosserial_packet_errors = 0
int g_rosserial_packet_start = 0
string[ROSSERIAL_FIFOLEN] g_rosserial_txfifo = ""
string[ROSSERIAL_FIFOLEN] g_rosserial_rxfifo = ""

;; Removes `bytes` oldest bytes from the fifo and copies rest of data
;; to the beginning of the buffer. This copy is done so that we don't
;; need to worry about wrapping around end of the buffer in other code.
sub rosserial_fifo_remove(var string[] fifo, int bytes)
    str_edit(fifo, "", 0, bytes)
end sub

;; Read and write to serial port until it would block.
sub rosserial_readwrite()
    int len
    len = readsa(g_rosserial_fd, g_rosserial_rxfifo, ROSSERIAL_FIFOLEN - str_len(g_rosserial_rxfifo))
    
    len = writes(g_rosserial_fd, g_rosserial_txfifo, 0)
    if len > 0 then
        rosserial_fifo_remove(g_rosserial_txfifo, len)
    end if
end sub

func int rosserial_checksum(string[] value, int startidx, int endidx)
    int sum = 0, i
    for i = startidx to endidx
        sum += str_chr_get(value, i)
    end for
    return 255 - (sum & 255)
end func

;; Call this to begin writing packet to the tx fifo.
;; It returns offset to the start of message data, this offset must
;; be passed to rosserial_end_packet().
;; If tx fifo is full, waits until there is enough space.
func int rosserial_start_packet(int topic_id)
    while str_len(g_rosserial_txfifo) + 8 + ROSSERIAL_MAXPACKETLEN > ROSSERIAL_FIFOLEN
        rosserial_readwrite()
        msleep(10)
    end while
    
    int offset
    offset = str_len(g_rosserial_txfifo)
    str_len_set(g_rosserial_txfifo, offset + 8 + ROSSERIAL_MAXPACKETLEN)
    str_chr_set(g_rosserial_txfifo, offset + 0, 0xFF)
    str_chr_set(g_rosserial_txfifo, offset + 1, 0xFE)
    str_chr_set(g_rosserial_txfifo, offset + 2, 0x00) ;; Message len
    str_chr_set(g_rosserial_txfifo, offset + 3, 0x00)
    str_chr_set(g_rosserial_txfifo, offset + 4, 0xFF) ;; Message len checksum
    str_chr_set(g_rosserial_txfifo, offset + 5, (topic_id & 0xFF))
    str_chr_set(g_rosserial_txfifo, offset + 6, (topic_id >> 8) & 0xFF)
    
    g_rosserial_packet_start = offset
    return offset + 7
end func

sub rosserial_end_packet(int end_offset)
    int msg_len
    msg_len = end_offset - g_rosserial_packet_start - 7
    str_len_set(g_rosserial_txfifo, end_offset + 1)
    str_chr_set(g_rosserial_txfifo, g_rosserial_packet_start + 2, (msg_len & 0xFF))
    str_chr_set(g_rosserial_txfifo, g_rosserial_packet_start + 3, (msg_len >> 8) & 0xFF)
    str_chr_set(g_rosserial_txfifo, g_rosserial_packet_start + 4,
                rosserial_checksum(g_rosserial_txfifo, g_rosserial_packet_start + 2, g_rosserial_packet_start + 3))
    str_chr_set(g_rosserial_txfifo, end_offset,
                rosserial_checksum(g_rosserial_txfifo, g_rosserial_packet_start + 5, end_offset - 1))
end sub

;; Check if there is a valid packet to be read.
;; Returns message length or -1 if there is no packet to be read.
;; Message start offset is always 0
func int rosserial_start_read_packet(var int topic_id)
    int i
    
    if str_len(g_rosserial_rxfifo) < 8
        return -1
    end if
    
    if str_chr_get(g_rosserial_rxfifo, 0) != 0xFF then
        ;; Resync with start of next packet
        g_rosserial_packet_errors += 1
        for i = 1 to str_len(g_rosserial_rxfifo)-1
            if str_chr_get(g_rosserial_rxfifo, i) == 0xFF then
                rosserial_fifo_remove(g_rosserial_rxfifo, i)
            end if
        end for
        
        if str_chr_get(g_rosserial_rxfifo, 0) != 0xFF then
            return -1
        end if
    end if
    
    if str_chr_get(g_rosserial_rxfifo, 1) != 0xFE then
        printf("rosserial: protocol version error {}\n", str_chr_get(g_rosserial_rxfifo, 1))
        g_rosserial_packet_errors += 1
        rosserial_fifo_remove(g_rosserial_rxfifo, 1)
        return -1
    end if
    
    if rosserial_checksum(g_rosserial_rxfifo, 2, 3) != str_chr_get(g_rosserial_rxfifo, 4) then
        printf("rosserial: length checksum error\n")
        g_rosserial_packet_errors += 1
        rosserial_fifo_remove(g_rosserial_rxfifo, 2)
        return -1
    end if
    
    int msg_len
    msg_len = str_chr_get(g_rosserial_rxfifo, 2) | (str_chr_get(g_rosserial_rxfifo, 3) << 8)
    topic_id = str_chr_get(g_rosserial_rxfifo, 5) | (str_chr_get(g_rosserial_rxfifo, 6) << 8)
    
    if str_len(g_rosserial_rxfifo) < 8 + msg_len then
        ;; Message is not complete yet
        return -1
    end if
    
    if rosserial_checksum(g_rosserial_rxfifo, 5, 6 + msg_len) != str_chr_get(g_rosserial_rxfifo, 7 + msg_len) then
        printf("rosserial: message checksum error\n")
        g_rosserial_packet_errors += 1
        rosserial_fifo_remove(g_rosserial_rxfifo, 8 + msg_len)
        return -1
    end if
    
    return msg_len
end func

;; Finish reading a message and remove from fifo
sub rosserial_end_read_packet(int msg_len)
    rosserial_fifo_remove(g_rosserial_rxfifo, 8 + msg_len)
end sub

;; Send TopicInfo reply for publishing a topic
sub rosserial_publish(int topic_id, string[] topic_name, string[] message_type, string[] md5sum)
    int offset
    offset = rosserial_start_packet(TOPICID_PUBLISH)
    offset = rosmsg_write_uint16(g_rosserial_txfifo, offset, topic_id)
    offset = rosmsg_write_string(g_rosserial_txfifo, offset, topic_name)
    offset = rosmsg_write_string(g_rosserial_txfifo, offset, message_type)
    offset = rosmsg_write_string(g_rosserial_txfifo, offset, md5sum)
    offset = rosmsg_write_int32(g_rosserial_txfifo, offset, ROSSERIAL_MAXPACKETLEN)
    rosserial_end_packet(offset)
end sub

.endif
