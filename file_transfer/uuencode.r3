;; RAPL-3 implementation of uuencode. Reads a file from CROS filesystem and
;; writes uuencoded data to stdout.
main
    string[80] buffer
    string[80] line
    int len, fd
    int c0, c1, c2
    
    if argc() != 2 then
        printf("Usage: uuencode <filename>\n")
        exit(1)
    end if
    
    open(fd, argv(1), O_RDONLY, 0)
    
    printf("begin 644 {}\n", argv(1))
    
    do
        len = reads(fd, buffer, 45)
        
        str_len_set(line, (len + 2)/3 * 4 + 1)
        str_chr_set(line, 0, len + 32)
        
        for i = 0 to (len+2)/3
            c0 = str_chr_get(buffer, i*3+0)
            c1 = str_chr_get(buffer, i*3+1)
            c2 = str_chr_get(buffer, i*3+2)
            str_chr_set(line, i*4+0, (c0 >> 2) + 32)
            str_chr_set(line, i*4+1, (((c0 & 0x03) << 4) | (c1 >> 4)) + 32)
            str_chr_set(line, i*4+2, (((c1 & 0x0F) << 2) | (c2 >> 6)) + 32)
            str_chr_set(line, i*4+3, (c2 & 0x3F) + 32)
        end for
        
        str_chr_set(line, str_len(line) - 1, '\n')
        writes(stdout, line, str_len(line))
    until len == 0
    close(fd)
    
    printf("end\n");
end main
