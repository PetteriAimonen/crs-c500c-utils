typedef rosserial_packet struct
    int msg_len
    int topic_id
    string[256] msg_data
end struct

func rosserial_checksum(string[] value, int startidx, int endidx, int prev_checksum)
    int sum = 0
    for i = startidx to endidx
        sum += str_chr_get(value, i)
    end for
    sum += 255 - prev_checksum
    return 255 - (sum & 255)
end func

sub rosserial_send_packet(int fd, rosserial_packet p)
    string[8] hdr
    str_len_set(hdr, 7)
    str_chr_set(hdr, 0, 0xFF)
    str_chr_set(hdr, 1, 0xFE)
    str_chr_set(hdr, 2, (p.msg_len & 0xFF))
    str_chr_set(hdr, 3, (p.msg_len >> 8) & 0xFF)
    str_chr_set(hdr, 4, rosserial_checksum(hdr, 2, 3, 0))
    str_chr_set(hdr, 5, (p.topic_id & 0xFF))
    str_chr_set(hdr, 6, (p.topic_id >> 8) & 0xFF)
    writes(fd, hdr, 7)
    writes(fd, p.msg_data, p.msg_len)

    str_chr_set(hdr, 0, rosserial_checksum(hdr, 5, 6, rosserial_checksum(p.msg_data, 0, p.msg_len - 1, 255)))
    writes(fd, hdr, 1)
end sub

func rosserial_recv_packet(int fd, var rosserial_packet p)
    string[8] hdr
    int len
    
    ;; First sync byte = 0xFF
    do
        len = reads(fd, hdr, 1)
    until len != 1 or str_chr_get(hdr, 0) == 0xFF
    printf("byte0: {}\n", str_chr_get(hdr, 0))
    if len != 1 or str_chr_get(hdr, 0) != 0xFF then
        return -1
    end if
    
    ;; Second sync byte = 0xFE
    len = reads(fd, hdr, 1)
    if len != 1 or str_chr_get(hdr, 0) != 0xFE then
        printf("byte1: {}\n", str_chr_get(hdr, 0))
        return -2
    end if
    
    ;; Rest of header
    len = reads(fd, hdr, 5)
    if len != 5 then
        return -3
    end if
    
    ;; Message length
    p.msg_len = str_chr_get(hdr, 0) | (str_chr_get(hdr, 1) << 8)
    printf("bytes: {} {} {} {}\n", str_chr_get(hdr, 0), str_chr_get(hdr, 1), str_chr_get(hdr, 2), str_chr_get(hdr, 3))
    if rosserial_checksum(hdr, 0, 1, 255) != str_chr_get(hdr, 2) then
        return -4
    end if
    
    if p.msg_len > 256 then
        return -5
    end if
    
    ;; Topic ID
    p.topic_id = str_chr_get(hdr, 3) | (str_chr_get(hdr, 4) << 8)
    
    ;; Message data
    len = reads(fd, p.msg_data, p.msg_len)
    if len != p.msg_len then
        return -6
    end if
    
    ;; Checksum
    len = reads(fd, hdr, 1)
    if len != 1 then
        return -7
    end if
    
    if rosserial_checksum(hdr, 3, 4, rosserial_checksum(p.msg_data, 0, p.msg_len - 1, 255)) != str_chr_get(hdr, 0) then
        return -8
    end if
    
    return 0
end func


