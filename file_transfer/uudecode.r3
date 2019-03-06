;; RAPL-3 implementation of uudecode. Reads uuencoded data from stdin and
;; writes to a file in the CROS filesystem.
;;
;; This has been written without empty lines so that it can be pasted to edit
;; on CROS. Type "edit uudecode.r3" to serial terminal, then "e" and enter.
;; Then paste this file. Press enter to terminate insert mode, and type "s" to
;; save and "q" to quit. Compile with "r3c uudecode.r3" and run with
;; "./uudecode". After you have uudecode available, it can be used to transfer
;; other files more easily.
main
    string[80] line
    string[80] filename
    int pos, len, fd
    int c0, c1, c2, c3
    freadline(stdin,-1,line,80) ;; Read header line, "begin xxx filename.txt"
    pos = str_chr_rfind(line, ' ') + 1
    str_substr(filename, line, pos, str_len(line) - pos)
    open(fd, filename, O_CREATE | O_TRUNC | O_WRONLY, M_READ | M_WRITE)
    do
        freadline(stdin,-1,line,80)
        len = str_chr_get(line, 0) - 32
        str_edit(line, "", 0, 1) ;; Remove length character
        for i = 0 to str_len(line)/3
            c0 = str_chr_get(line, i*4+0) - 32
            c1 = str_chr_get(line, i*4+1) - 32
            c2 = str_chr_get(line, i*4+2) - 32
            c3 = str_chr_get(line, i*4+3) - 32
            str_chr_set(line, i*3+0, ((c0 << 2) | (c1 >> 4)) & 0xFF)
            str_chr_set(line, i*3+1, ((c1 << 4) | (c2 >> 2)) & 0xFF)
            str_chr_set(line, i*3+2, ((c2 << 6) | (c3 >> 0)) & 0xFF)
        end for
        writes(fd, line, 1en)
    until len == 0
    close(fd)
    freadline(stdin,-1,line,80) ;; Read trailer line, "end"
end main
