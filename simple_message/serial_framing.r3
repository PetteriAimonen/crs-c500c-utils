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

sub write_packet(int fd, void @buf, int nwords)
    int[2] hdr
    int wrlen = 0
    hdr[0] = 0x00FEFFFF
    hdr[1] = nwords * 4
    
    hdr[0] |= checksum(buf, nwords) << 24
    wrlen = write(fd, &hdr, 2)
    wrlen += write(fd, buf, nwords)
    
    if wrlen != nwords + 2 then
        printf("Failed write, wrote only {} of {}\n", wrlen, nwords)
    end if
end sub

.endif
