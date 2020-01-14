.ifndef SERIAL_FRAMING_INCLUDED
.define SERIAL_FRAMING_INCLUDED

;; Implements a simple serial framing format.
;;
;; Each packet will start with sync word 0x??FEFFFF where ?? is the checksum.
;; After that comes the simple_message 4-byte length prefix N.
;; After that, N bytes of data.
;; Checksum is computed as sum of all bytes after the length prefix, mod 256.

func int checksum(void @buf, int nwords)
    union
        int@ p
        int pval
    end union tmp
    int i
    int sum = 0
    int v
    
    tmp.p = buf
    
    for i = 0 to nwords - 1
        v = tmp.p@
        tmp.pval += 1
        sum += v & 255
        sum += (v >> 8) & 255
        sum += (v >> 16) & 255
        sum += (v >> 24) & 255
    end for
    
    return sum & 255
end func

;; Adds framing header and transmits packet over serial.
sub write_packet(int fd, void @buf, int nwords)
    int[2] hdr
    hdr[0] = 0x00FEFFFF
    hdr[1] = nwords * 4
    hdr[0] |= checksum(buf, nwords) << 24
    write(fd, &hdr, 2)
    write(fd, buf, nwords)
end sub

;; Reads framing header and packet payload.
;; Function returns packet length.
;; If packet does not fit in buffer or fails checksum,
;; it is skipped and this returns 0.
func int read_packet(int fd, void @buf, int bufsize)
    string[2] framing
    int frame1 = 0, frame2 = 0, expected_checksum = 0, actual_checksum = 0
    int rdlen = 0, packet_length = 0
    
    ;; Wait for 0xFF 0xFE sequence
    do
        rdlen = reads(fd, framing, 1)
        frame2 = frame1
        frame1 = str_chr_get(framing, 0)
    until rdlen != 1 or (frame1 == 0xFE && frame2 == 0xFF)
    
    if rdlen != 1 then
        printf("Read error: {}\n", rdlen)
        return 0
    end if
    
    ;; Read packet checksum
    rdlen = reads(fd, framing, 1)
    if rdlen != 1 then
        printf("Read error: {}\n", rdlen)
        return 0
    end if
    expected_checksum = str_chr_get(framing, 0)
    
    ;; Read packet length
    rdlen = read(fd, &packet_length, 1)
    if rdlen != 1 then
        printf("Read error: {}\n", rdlen)
        return 0
    end if
    
    packet_length = (packet_length + 3) / 4
    
    if packet_length > bufsize then
        printf("Too long packet: {} bytes\n", packet_length)
        return 0
    end if
    
    ;; Read payload
    rdlen = read(fd, buf, packet_length)
    if rdlen != packet_length then
        printf("Read error: {}\n", rdlen)
        return 0
    end if
    
    ;; Verify checksum
    actual_checksum = checksum(buf, packet_length)
    if actual_checksum != expected_checksum then
        printf("Checksum failure: {} in header, {} calculated\n",
               expected_checksum, actual_checksum)
        return 0
    end if
    
    return packet_length
end func

.endif
