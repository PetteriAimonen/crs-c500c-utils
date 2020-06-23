;; ./getrotspd
;; speed: 10
;; rotspd: 50.0000
;; linspd: 1016.00
;; linacc: 2540.00
;; rotacc: 899.544
;; parts: 0x4b010302 -5443 -3279 -47759 425 -19826 -89682 0 0
;; angles: 9.56777 -5.76387 -78.1875 -0.933838 -43.5630 197.055 0.00000 0.00000
;;
;; Press the PAUSE/CONTINUE button to gain robot point of control.
;; 5deg move time at 1deg/s: 1904
;; 5deg move time at 5deg/s: 1924
;; 5deg move time at 20%: 1029
;; 5deg move time at 50%: 528
;; zeropoint: 0xfa010302 0 0 0 0 0 0 0 0
;; 90deg: 0x0f010302 -51200 51200 102400 -40960 40960 -40960 0 0

main
    int i
    int[2] tm1
    int[2] tm2
    float rotspd, linspd, linacc, rotacc
    int speedx
    ploc pos2
    union
        ploc pos
        int[9] parts
    end union tmp
    float[8] angles
    float[8] angles2
    
    rotspd_get(rotspd)
    linspd_get(linspd)
    linacc_get(linacc)
    rotacc_get(rotacc)
    speed_get(speedx)
    printf("speed: {}\n", speedx)
    printf("rotspd: {}\n", rotspd)
    printf("linspd: {}\n", linspd)
    printf("linacc: {}\n", linacc)
    printf("rotacc: {}\n", rotacc)
    
    loc_class_set(tmp.pos, loc_precision)
    loc_class_set(pos2, loc_precision)
    here(tmp.pos)
    
    printf("parts: 0x{08x} {} {} {} {} {} {} {} {}\n",
        tmp.parts[0], tmp.parts[1], tmp.parts[2], tmp.parts[3],
        tmp.parts[4], tmp.parts[5], tmp.parts[6], tmp.parts[7],
        tmp.parts[8])
    
    motor_to_joint(tmp.pos, angles)
    printf("angles: {} {} {} {} {} {} {} {}\n",
        angles[0], angles[1], angles[2], angles[3],
        angles[4], angles[5], angles[6], angles[7])
    
    ctl_get()

    for i = 1 to 100
        printf("\n\n# Speed: {}\n", i)
        angles[0] = -25
        speedx = 50
        speed_set(speedx)
        joint_to_motor(angles, tmp.pos)
        move(tmp.pos)
        
        angles[0] = 25
        speedx = i
        speed_set(speedx)
        joint_to_motor(angles, tmp.pos)
            
        mtime(&tm1)
        move(tmp.pos)
        
        while !robotisfinished()
            here(pos2)
            motor_to_joint(pos2, angles2)
            mtime(&tm2)
            printf("{} {} {}\n", i, tm2[0]-tm1[0], angles2[0])
        end while
        
        mtime(&tm2)
        printf("# 50 deg move time at {}%: {}\n", tm2[0]-tm1[0], i)
    end for
    
    angles[0] = 0
    joint_to_motor(angles, tmp.pos)
    move(tmp.pos)
        
    for i = 0 to 7
        angles[i] = 0
    end for
    
    joint_to_motor(angles, tmp.pos)
    printf("zeropoint: 0x{08x} {} {} {} {} {} {} {} {}\n",
        tmp.parts[0], tmp.parts[1], tmp.parts[2], tmp.parts[3],
        tmp.parts[4], tmp.parts[5], tmp.parts[6], tmp.parts[7],
        tmp.parts[8])

    for i = 0 to 7
        angles[i] = 90
    end for
    
    joint_to_motor(angles, tmp.pos)
    printf("90deg: 0x{08x} {} {} {} {} {} {} {} {}\n",
        tmp.parts[0], tmp.parts[1], tmp.parts[2], tmp.parts[3],
        tmp.parts[4], tmp.parts[5], tmp.parts[6], tmp.parts[7],
        tmp.parts[8])

end main

