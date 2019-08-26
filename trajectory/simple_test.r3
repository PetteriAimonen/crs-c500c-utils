main
    online(ON) ;; Turn on motion planner queue
    
    int i, j
    c_mtime_t start, timeval
    mtime(&start)

    ;;stance_set(REACH_FORWARD, ELBOW_DOWN, WRIST_NOFLIP)
    stance_set(REACH_FORWARD, ELBOW_FREE, WRIST_NOFLIP)

    cloc[6] points
    here(points[0])
    here(points[1])
    here(points[2])
    here(points[3])
    here(points[4])
    here(points[5])
    
    cloc offset1 = cloc{0, -50, 0, 0, 0, 0, 0, 0, 0}
    cloc offset2 = cloc{0, 0, 50, 0, 0, 0, 0, 0, 0}
    cloc offset3 = cloc{0, -1, 0, 0, 0, 0, 0, 0, 0}
    cloc offset4 = cloc{0, 0, 1, 0, 0, 0, 0, 0, 0}
    
    shift_w(points[0], offset1)
    shift_w(points[1], offset3)
    shift_w(points[3], offset4)
    shift_w(points[4], offset2)
    
    for i = 0 to 10
        for j = 0 to 5
            mtime(&timeval)
            printf("At {} POS: {} {}\n", timeval[0] - start[0], i, j)
            moves(points[j])
        end for
    end for
    
    finish()
    mtime(&timeval)
    printf("{} Done!\n", timeval[0] - start[0])
end main

    
