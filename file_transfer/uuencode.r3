;; RAPL-3 implementation of uuencode. Reads a file from CROS filesystem and
;; writes uuencoded data to stdout.
func uuencode(int value)
    if value == 0 then
        return '`'
    else
        return value + 32
    end if
end func

main
    string[]@ filename
    string[80] buffer
    string[80] line
    int len, fd
    int c0, c1, c2
    
    if argc() != 2 then
        printf("Usage: uuencode <filename>\n")
        exit(1)
    end if
    
    filename = argv(1)
    open(fd, filename@, O_RDONLY, 0)
    
    printf("begin 644 {}\n", filename)
    
    do
        len = reads(fd, buffer, 45)
        
        str_len_set(line, (len + 2)/3 * 4 + 1)
        str_chr_set(line, 0, uuencode(len))
        
        for i = 0 to (len+2)/3
            c0 = str_chr_get(buffer, i*3+0)
            c1 = str_chr_get(buffer, i*3+1)
            c2 = str_chr_get(buffer, i*3+2)
            str_chr_set(line, i*4+1, uuencode(c0 >> 2))
            str_chr_set(line, i*4+2, uuencode(((c0 & 0x03) << 4) | (c1 >> 4)))
            str_chr_set(line, i*4+3, uuencode(((c1 & 0x0F) << 2) | (c2 >> 6)))
            str_chr_set(line, i*4+4, uuencode(c2 & 0x3F))
        end for
        
        printf("{}\n", line)
    until len == 0
    close(fd)
    
    printf("end\n")
end main
