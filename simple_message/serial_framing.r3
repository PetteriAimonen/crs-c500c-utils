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

;; It seems there is something wrong with how CROS handles serial port
;; writing. If a lot of data is written at once, some of it gets dropped
;; occassionally. This function waits 1 ms between every word to keep
;; FIFO fill level low enough. At 57600 bps, 1 word should take about
;; 0.8 ms on the serial line.
sub write_with_delay(int fd, void @buf, int nwords)
    union
        int@ p
        int pval
    end union tmp
    
    int len
    
    tmp.p = buf
    
    while nwords > 0
        len = write(fd, tmp.p, 1)
        tmp.pval += len
        nwords -= len
        delay(1)
    end while
end sub

sub write_packet(int fd, void @buf, int nwords)
    int[2] hdr
    int wrlen = 0
    hdr[0] = 0x00FEFFFF
    hdr[1] = nwords * 4
    
    hdr[0] |= checksum(buf, nwords) << 24
    write_with_delay(fd, &hdr, 2)
    write_with_delay(fd, buf, nwords)
end sub

.endif
