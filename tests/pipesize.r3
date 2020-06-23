main
    int ps_id,i,status
    int fd_pipe_rd, fd_pipe_wr
    pipe (fd_pipe_rd, fd_pipe_wr)

    for i=1 to 2048
        write(fd_pipe_wr, &i, 1)
        printf("wrote {}\n", i)
    end for
end main

