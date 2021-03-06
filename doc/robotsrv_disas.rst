/bin/rdb can be used to study applications

rdb> run
run
Executing: '/sbin/robotsrv'
[Started process 133]
Program loaded; stopped at robotsrv.r3:2088
rdb> segments
segments
Segments:
  0x000000[0x0000]  NULL
  0x010000[0xfc00]  Stack
  0x020000[0xfc00]  Heap
  0x030000[0x077f]  Data for /sbin/robotsrv
  0x040000[0x23f4]  Text for /sbin/robotsrv
  0x050000[0x016b]  Data for syslib
  0x060000[0x0947]  Text for syslib
  0x070000[0x01a0]  Data for robotlib
  0x080000[0x1b4e]  Text for robotlib

rdb> symbols
symbols
sock_fd                          var     0x030000 int
MCE_fd                           var     0x030001 int
pid0                             var     0x030002 int
pid1                             var     0x030003 int
reset_requested                  var     0x030004 int
control_pid                      var     0x030005 int
poc_check_disable                var     0x030006 int
feedback_check_enable            var     0x030007 int
armpower                         var     0x030008 int
currmode                         var     0x030009 int
product_code                     var     0x03000a int
mach_type                        var     0x03000b int
transform_axes                   var     0x03000c int
machine_axes                     var     0x03000d int
ForceControlEnabled              var     0x03000e int
track                            var     0x03000f int
actual_axes                      var     0x030010 int
tooloffset                       var     0x030011 cloc
baseoffset                       var     0x03001a cloc
trackposlength                   var     0x030023 float
trackneglength                   var     0x030024 float
trackxratio                      var     0x030025 float
currentgriptype                  var     0x030026 int
Metric_Mode_On                   var     0x030027 int
forcecode                        var     0x030028 int
fixedAngle                       var     0x030029 float
config_table                     var     0x03002a -
cfg_name                         var     0x030056 string[32]
grip_intercept                   var     0x03005f float
grip_slope                       var     0x030060 float
gripper_calibrated               var     0x030061 int
currentgripforce                 var     0x030062 int
cal_loc                          var     0x030063 ploc
mark_loc                         var     0x03006c ploc
robot_calibrated                 var     0x030075 int
robot_homed                      var     0x030076 int
poweroff_loc                     var     0x030077 ploc
poweron_loc                      var     0x030080 ploc
axis_homed                       var     0x030089 int[8]
armpowerfd                       var     0x030091 int
verbosity_on                     var     0x030092 int
AdvancedErrorMode                var     0x030093 int
ErrorInProgress                  var     0x030094 int
asynch_info                      var     0x030095 -
asynch_queue                     var     0x030097 int[8]
aq_head                          var     0x03009f int
aq_tail                          var     0x0300a0 int
asynch_queue_put                 sub     0x040001 -
asynch_queue_get                 func    0x040010 int
asynch_queue_clear               sub     0x040022 -
asynch_queue_dump1               func    0x040027 int
asynch_queue_dump                sub     0x040045 -
ap_sig_procs                     var     0x0300a1 -
init_ap_sigs                     sub     0x04004d -
advancedProcs                    var     0x0300ad int[32]
nAdvanced                        var     0x0300cd int
usesAdvancedMode                 func    0x04005a int
recordAdvancedMode               command 0x04006d int
poc_process_exists               func    0x0400c5 int
set_server_home_status           command 0x0400d9 int
read_calibration                 sub     0x0400ff -
backup_cal_file                  command 0x0401ae int
GetFCPassword                    func    0x04020b int
odo_fd                           var     0x0300ce int
odo_last_on                      var     0x0300cf int
odo                              var     0x0300d0 -
odometer_init                    sub     0x04025c -
odometer_fini                    sub     0x0402db -
odometer_update                  sub     0x0402fe -
odometer_value                   func    0x040326 int
odometer_reset                   sub     0x040336 -
load_gripper_calibration         sub     0x04035f -
s_big_buff                       var     0x0300d2 int[128]
KinDevSend                       func    0x0403aa int
KinDevRcv                        func    0x0403f4 int
send_reset                       command 0x040418 int
cancel_recovery                  command 0x040431 int
resetErrorHandling               sub     0x04044a -
stubby                           func    0x040464 int
rservice_getpv                   func    0x040472 int
rservice_getobs                  func    0x04047b int
rservice_relobs                  func    0x040484 int
rservice_getctl                  func    0x040496 int
rservice_relctl                  func    0x0404c6 int
rservice_ctl_give                func    0x0404d8 int
rservice_getpos                  func    0x0404fe int
rservice_accel                   func    0x040537 int
rservice_tool                    func    0x040571 int
rservice_base                    func    0x0405ae int
rservice_stance                  func    0x0405eb int
rservice_maxvel                  func    0x0406bb int
rservice_getconf                 func    0x0406f5 int
rservice_joint                   func    0x040716 int
rservice_motor                   func    0x040743 int
rservice_limp                    func    0x040770 int
rservice_abspos                  func    0x0407af int
rservice_linspeeds               func    0x0407e1 int
rservice_ready                   func    0x04081b int
rservice_calrdy                  func    0x040843 int
rservice_align                   func    0x04086b int
rservice_appro                   func    0x040894 int
rservice_jog                     func    0x0408bd int
rservice_tooljog                 func    0x040902 int
rservice_finish                  func    0x040947 int
rservice_gripfinish              func    0x040979 int
rservice_gripstop                func    0x0409a6 int
rservice_halt                    func    0x0409c3 int
rservice_online                  func    0x0409e0 int
rservice_speed                   func    0x040a13 int
rservice_rinfo                   func    0x040a4a int
rservice_sinfo                   func    0x040a85 int
rservice_odo                     func    0x040aac int
rservice_armpower                func    0x040ac8 int
rservice_motor_to_joint          func    0x040aed int
rservice_joint_to_motor          func    0x040b13 int
rservice_motor_to_world          func    0x040b4c int
rservice_setgriptype             func    0x040b90 int
rservice_grip                    func    0x040bcb int
rservice_getgripdist             func    0x040c44 int
rservice_hswoffset               func    0x040c79 int
rservice_calhome                 func    0x040c9c int
rservice_getaxisstatus           func    0x040db4 int
rservice_getversion              func    0x040dd5 int
manbuffer                        var     0x030152 -
rservice_setmanmode              func    0x040e10 int
rservice_startmmove              func    0x040e4d int
rservice_stopmmove               func    0x040e93 int
rservice_getmode                 func    0x040ec8 int
rservice_gain                    func    0x040ed0 int
rservice_servostat               func    0x040eff int
rservice_servo196packet2         func    0x040f20 int
rservice_lock                    func    0x040f42 int
rservice_enableflags             func    0x040f6b int
rservice_linklength              func    0x040f97 int
rservice_xpulses                 func    0x040fdd int
rservice_xratio                  func    0x041017 int
rservice_jointlim                func    0x04105b int
rservice_output                  func    0x04109c int
rservice_input                   func    0x0410cc int
rservice_setaps                  func    0x0410ea int
rservice_geterrstate             func    0x041121 int
rservice_axconf                  func    0x04113a int
rservice_joint_to_world          func    0x04117b int
rservice_world_to_motor          func    0x0411bb int
rservice_world_to_joint          func    0x0411f8 int
rservice_locpostmult             func    0x041220 int
rservice_locpremult              func    0x041242 int
rservice_memdiag                 func    0x041264 int
rservice_ctinit                  func    0x041283 int
rservice_ctpack                  func    0x0412ac int
rservice_cttrig                  func    0x0412ca int
rservice_ctgopath                func    0x0412e8 int
rservice_metric                  func    0x041311 int
rservice_calgrip                 func    0x04134b int
p_lights_fd                      var     0x03015e int
p_status_fd                      var     0x03015f int
p_buttons_fd                     var     0x030160 int
rservice_genpanel                func    0x0413b2 int
rservice_forcepwd_set            func    0x041454 int
rservice_robot_cfg               func    0x041460 int
rservice_force                   func    0x041485 int
rservice_forcepar                func    0x0414b4 int
rservice_forcecal                func    0x0414e1 int
rservice_forcefr                 func    0x04150a int
rservice_getforcedata            func    0x041534 int
rservice_setliveman              func    0x041557 int
rservice_getanalog               func    0x041587 int
rservice_setsensoroff            func    0x0415aa int
rservice_autohome                func    0x0415d3 int
rservice_clearerror              func    0x041818 int
rservice_topath                  func    0x04183d int
rservice_resume                  func    0x041865 int
rservice_is_recoverable          func    0x04188d int
rservice_rcancel                 func    0x0418aa int
rservice_param                   func    0x0418d2 int
rservice_recovery                func    0x041901 int
rserver_services                 var     0x03018c -
poweroffloc_write                sub     0x04191f -
poweroffloc_read                 sub     0x041a7c -
poweronloc_read                  sub     0x041b46 -
sig_ignore_handler               sub     0x041bab -
sig_arm_off_handler              sub     0x041bae -
sig_power_handler                sub     0x041bc0 -
sig_fwd                          sub     0x041c76 -
sig_halt_handler                 sub     0x041c80 -
sig_die_handler                  sub     0x041cc7 -
sig_verbose_switch               sub     0x041cf2 -
init_MCE                         sub     0x041d0e -
tasklist                         var     0x0301ed -
background_in_count              var     0x030425 int
background_out_count             var     0x030426 int
init_tasklist                    sub     0x04209a -
sock_send                        command 0x0420bf int
wait_for_reset_complete          sub     0x0420fd -
adjust_nesting                   sub     0x042120 -
receive_from_socket              sub     0x042143 -
respond_to_socket                sub     0x042204 -
main                             command 0x042265 int

