# PredChecker FM「匹配前」钉点 —— 自动生成：scripts/gen_newifu_lane.py（勿手改）
#
# 只消 golden 扁平寄存器名与重写核数组名之间的命名鸿沟（依据见生成器文件头）。
# set_user_match 只是声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。
# fail-closed：set_user_match 从不抛异常（返回 0 = 没配上），所以逐条数返回值；
# 拒一条或总数不等于字面整数（= 所列 golden 寄存器位数之和）就 error。
# 进 fm.log 的输出一律 ASCII。
set ::PREDCHECKER_PIN_OK 0
set ::PREDCHECKER_PIN_BAD 0
proc predchecker_pin {g i w} {
  if {$w == 1} {
    set pairs [list "r:/WORK/PredChecker/${g}_reg" "i:/WORK/PredChecker/${i}"]
  } else {
    set pairs {}
    for {set b 0} {$b < $w} {incr b} {
      lappend pairs "r:/WORK/PredChecker/${g}_reg\[$b\]" "i:/WORK/PredChecker/${i}\[$b\]"
    }
  }
  foreach {r m} $pairs {
    if {[set_user_match $r $m]} { incr ::PREDCHECKER_PIN_OK } else {
      incr ::PREDCHECKER_PIN_BAD
      if {$::PREDCHECKER_PIN_BAD <= 10} { puts "PREDCHECKER_PIN_FAIL: $r <-> $m" }
    }
  }
}
puts "PREDCHECKER_PIN_BEGIN PredChecker expect=1799"
predchecker_pin fixedRangeNext u_core/fixedRange_q_reg 16
predchecker_pin instrValidNext_0 u_core/instrValid_q_reg\[0\] 1
predchecker_pin instrValidNext_1 u_core/instrValid_q_reg\[1\] 1
predchecker_pin instrValidNext_2 u_core/instrValid_q_reg\[2\] 1
predchecker_pin instrValidNext_3 u_core/instrValid_q_reg\[3\] 1
predchecker_pin instrValidNext_4 u_core/instrValid_q_reg\[4\] 1
predchecker_pin instrValidNext_5 u_core/instrValid_q_reg\[5\] 1
predchecker_pin instrValidNext_6 u_core/instrValid_q_reg\[6\] 1
predchecker_pin instrValidNext_7 u_core/instrValid_q_reg\[7\] 1
predchecker_pin instrValidNext_8 u_core/instrValid_q_reg\[8\] 1
predchecker_pin instrValidNext_9 u_core/instrValid_q_reg\[9\] 1
predchecker_pin instrValidNext_10 u_core/instrValid_q_reg\[10\] 1
predchecker_pin instrValidNext_11 u_core/instrValid_q_reg\[11\] 1
predchecker_pin instrValidNext_12 u_core/instrValid_q_reg\[12\] 1
predchecker_pin instrValidNext_13 u_core/instrValid_q_reg\[13\] 1
predchecker_pin instrValidNext_14 u_core/instrValid_q_reg\[14\] 1
predchecker_pin instrValidNext_15 u_core/instrValid_q_reg\[15\] 1
predchecker_pin takenIdxNext u_core/takenIdx_q_reg 4
predchecker_pin predTakenNext u_core/predTaken_q_reg 1
predchecker_pin predTargetNext u_core/predTarget_q_reg 50
predchecker_pin jumpTargetsNext_0 u_core/jumpTarget_q_reg\[0\] 50
predchecker_pin jumpTargetsNext_1 u_core/jumpTarget_q_reg\[1\] 50
predchecker_pin jumpTargetsNext_2 u_core/jumpTarget_q_reg\[2\] 50
predchecker_pin jumpTargetsNext_3 u_core/jumpTarget_q_reg\[3\] 50
predchecker_pin jumpTargetsNext_4 u_core/jumpTarget_q_reg\[4\] 50
predchecker_pin jumpTargetsNext_5 u_core/jumpTarget_q_reg\[5\] 50
predchecker_pin jumpTargetsNext_6 u_core/jumpTarget_q_reg\[6\] 50
predchecker_pin jumpTargetsNext_7 u_core/jumpTarget_q_reg\[7\] 50
predchecker_pin jumpTargetsNext_8 u_core/jumpTarget_q_reg\[8\] 50
predchecker_pin jumpTargetsNext_9 u_core/jumpTarget_q_reg\[9\] 50
predchecker_pin jumpTargetsNext_10 u_core/jumpTarget_q_reg\[10\] 50
predchecker_pin jumpTargetsNext_11 u_core/jumpTarget_q_reg\[11\] 50
predchecker_pin jumpTargetsNext_12 u_core/jumpTarget_q_reg\[12\] 50
predchecker_pin jumpTargetsNext_13 u_core/jumpTarget_q_reg\[13\] 50
predchecker_pin jumpTargetsNext_14 u_core/jumpTarget_q_reg\[14\] 50
predchecker_pin jumpTargetsNext_15 u_core/jumpTarget_q_reg\[15\] 50
predchecker_pin seqTargetsNext_0 u_core/seqTarget_q_reg\[0\] 50
predchecker_pin seqTargetsNext_1 u_core/seqTarget_q_reg\[1\] 50
predchecker_pin seqTargetsNext_2 u_core/seqTarget_q_reg\[2\] 50
predchecker_pin seqTargetsNext_3 u_core/seqTarget_q_reg\[3\] 50
predchecker_pin seqTargetsNext_4 u_core/seqTarget_q_reg\[4\] 50
predchecker_pin seqTargetsNext_5 u_core/seqTarget_q_reg\[5\] 50
predchecker_pin seqTargetsNext_6 u_core/seqTarget_q_reg\[6\] 50
predchecker_pin seqTargetsNext_7 u_core/seqTarget_q_reg\[7\] 50
predchecker_pin seqTargetsNext_8 u_core/seqTarget_q_reg\[8\] 50
predchecker_pin seqTargetsNext_9 u_core/seqTarget_q_reg\[9\] 50
predchecker_pin seqTargetsNext_10 u_core/seqTarget_q_reg\[10\] 50
predchecker_pin seqTargetsNext_11 u_core/seqTarget_q_reg\[11\] 50
predchecker_pin seqTargetsNext_12 u_core/seqTarget_q_reg\[12\] 50
predchecker_pin seqTargetsNext_13 u_core/seqTarget_q_reg\[13\] 50
predchecker_pin seqTargetsNext_14 u_core/seqTarget_q_reg\[14\] 50
predchecker_pin seqTargetsNext_15 u_core/seqTarget_q_reg\[15\] 50
predchecker_pin pdsNext_0_brType u_core/brType_q_reg\[0\] 2
predchecker_pin pdsNext_1_brType u_core/brType_q_reg\[1\] 2
predchecker_pin pdsNext_2_brType u_core/brType_q_reg\[2\] 2
predchecker_pin pdsNext_3_brType u_core/brType_q_reg\[3\] 2
predchecker_pin pdsNext_4_brType u_core/brType_q_reg\[4\] 2
predchecker_pin pdsNext_5_brType u_core/brType_q_reg\[5\] 2
predchecker_pin pdsNext_6_brType u_core/brType_q_reg\[6\] 2
predchecker_pin pdsNext_7_brType u_core/brType_q_reg\[7\] 2
predchecker_pin pdsNext_8_brType u_core/brType_q_reg\[8\] 2
predchecker_pin pdsNext_9_brType u_core/brType_q_reg\[9\] 2
predchecker_pin pdsNext_10_brType u_core/brType_q_reg\[10\] 2
predchecker_pin pdsNext_11_brType u_core/brType_q_reg\[11\] 2
predchecker_pin pdsNext_12_brType u_core/brType_q_reg\[12\] 2
predchecker_pin pdsNext_13_brType u_core/brType_q_reg\[13\] 2
predchecker_pin pdsNext_14_brType u_core/brType_q_reg\[14\] 2
predchecker_pin pdsNext_15_brType u_core/brType_q_reg\[15\] 2
predchecker_pin jalFaultVecNext_0 u_core/jalFault_q_reg\[0\] 1
predchecker_pin jalFaultVecNext_1 u_core/jalFault_q_reg\[1\] 1
predchecker_pin jalFaultVecNext_2 u_core/jalFault_q_reg\[2\] 1
predchecker_pin jalFaultVecNext_3 u_core/jalFault_q_reg\[3\] 1
predchecker_pin jalFaultVecNext_4 u_core/jalFault_q_reg\[4\] 1
predchecker_pin jalFaultVecNext_5 u_core/jalFault_q_reg\[5\] 1
predchecker_pin jalFaultVecNext_6 u_core/jalFault_q_reg\[6\] 1
predchecker_pin jalFaultVecNext_7 u_core/jalFault_q_reg\[7\] 1
predchecker_pin jalFaultVecNext_8 u_core/jalFault_q_reg\[8\] 1
predchecker_pin jalFaultVecNext_9 u_core/jalFault_q_reg\[9\] 1
predchecker_pin jalFaultVecNext_10 u_core/jalFault_q_reg\[10\] 1
predchecker_pin jalFaultVecNext_11 u_core/jalFault_q_reg\[11\] 1
predchecker_pin jalFaultVecNext_12 u_core/jalFault_q_reg\[12\] 1
predchecker_pin jalFaultVecNext_13 u_core/jalFault_q_reg\[13\] 1
predchecker_pin jalFaultVecNext_14 u_core/jalFault_q_reg\[14\] 1
predchecker_pin jalFaultVecNext_15 u_core/jalFault_q_reg\[15\] 1
predchecker_pin jalrFaultVecNext_0 u_core/jalrFault_q_reg\[0\] 1
predchecker_pin jalrFaultVecNext_1 u_core/jalrFault_q_reg\[1\] 1
predchecker_pin jalrFaultVecNext_2 u_core/jalrFault_q_reg\[2\] 1
predchecker_pin jalrFaultVecNext_3 u_core/jalrFault_q_reg\[3\] 1
predchecker_pin jalrFaultVecNext_4 u_core/jalrFault_q_reg\[4\] 1
predchecker_pin jalrFaultVecNext_5 u_core/jalrFault_q_reg\[5\] 1
predchecker_pin jalrFaultVecNext_6 u_core/jalrFault_q_reg\[6\] 1
predchecker_pin jalrFaultVecNext_7 u_core/jalrFault_q_reg\[7\] 1
predchecker_pin jalrFaultVecNext_8 u_core/jalrFault_q_reg\[8\] 1
predchecker_pin jalrFaultVecNext_9 u_core/jalrFault_q_reg\[9\] 1
predchecker_pin jalrFaultVecNext_10 u_core/jalrFault_q_reg\[10\] 1
predchecker_pin jalrFaultVecNext_11 u_core/jalrFault_q_reg\[11\] 1
predchecker_pin jalrFaultVecNext_12 u_core/jalrFault_q_reg\[12\] 1
predchecker_pin jalrFaultVecNext_13 u_core/jalrFault_q_reg\[13\] 1
predchecker_pin jalrFaultVecNext_14 u_core/jalrFault_q_reg\[14\] 1
predchecker_pin jalrFaultVecNext_15 u_core/jalrFault_q_reg\[15\] 1
predchecker_pin retFaultVecNext_0 u_core/retFault_q_reg\[0\] 1
predchecker_pin retFaultVecNext_1 u_core/retFault_q_reg\[1\] 1
predchecker_pin retFaultVecNext_2 u_core/retFault_q_reg\[2\] 1
predchecker_pin retFaultVecNext_3 u_core/retFault_q_reg\[3\] 1
predchecker_pin retFaultVecNext_4 u_core/retFault_q_reg\[4\] 1
predchecker_pin retFaultVecNext_5 u_core/retFault_q_reg\[5\] 1
predchecker_pin retFaultVecNext_6 u_core/retFault_q_reg\[6\] 1
predchecker_pin retFaultVecNext_7 u_core/retFault_q_reg\[7\] 1
predchecker_pin retFaultVecNext_8 u_core/retFault_q_reg\[8\] 1
predchecker_pin retFaultVecNext_9 u_core/retFault_q_reg\[9\] 1
predchecker_pin retFaultVecNext_10 u_core/retFault_q_reg\[10\] 1
predchecker_pin retFaultVecNext_11 u_core/retFault_q_reg\[11\] 1
predchecker_pin retFaultVecNext_12 u_core/retFault_q_reg\[12\] 1
predchecker_pin retFaultVecNext_13 u_core/retFault_q_reg\[13\] 1
predchecker_pin retFaultVecNext_14 u_core/retFault_q_reg\[14\] 1
predchecker_pin retFaultVecNext_15 u_core/retFault_q_reg\[15\] 1
predchecker_pin notCFITakenNext_0 u_core/notCfiTaken_q_reg\[0\] 1
predchecker_pin notCFITakenNext_1 u_core/notCfiTaken_q_reg\[1\] 1
predchecker_pin notCFITakenNext_2 u_core/notCfiTaken_q_reg\[2\] 1
predchecker_pin notCFITakenNext_3 u_core/notCfiTaken_q_reg\[3\] 1
predchecker_pin notCFITakenNext_4 u_core/notCfiTaken_q_reg\[4\] 1
predchecker_pin notCFITakenNext_5 u_core/notCfiTaken_q_reg\[5\] 1
predchecker_pin notCFITakenNext_6 u_core/notCfiTaken_q_reg\[6\] 1
predchecker_pin notCFITakenNext_7 u_core/notCfiTaken_q_reg\[7\] 1
predchecker_pin notCFITakenNext_8 u_core/notCfiTaken_q_reg\[8\] 1
predchecker_pin notCFITakenNext_9 u_core/notCfiTaken_q_reg\[9\] 1
predchecker_pin notCFITakenNext_10 u_core/notCfiTaken_q_reg\[10\] 1
predchecker_pin notCFITakenNext_11 u_core/notCfiTaken_q_reg\[11\] 1
predchecker_pin notCFITakenNext_12 u_core/notCfiTaken_q_reg\[12\] 1
predchecker_pin notCFITakenNext_13 u_core/notCfiTaken_q_reg\[13\] 1
predchecker_pin notCFITakenNext_14 u_core/notCfiTaken_q_reg\[14\] 1
predchecker_pin notCFITakenNext_15 u_core/notCfiTaken_q_reg\[15\] 1
predchecker_pin invalidTakenNext_0 u_core/invalidTaken_q_reg\[0\] 1
predchecker_pin invalidTakenNext_1 u_core/invalidTaken_q_reg\[1\] 1
predchecker_pin invalidTakenNext_2 u_core/invalidTaken_q_reg\[2\] 1
predchecker_pin invalidTakenNext_3 u_core/invalidTaken_q_reg\[3\] 1
predchecker_pin invalidTakenNext_4 u_core/invalidTaken_q_reg\[4\] 1
predchecker_pin invalidTakenNext_5 u_core/invalidTaken_q_reg\[5\] 1
predchecker_pin invalidTakenNext_6 u_core/invalidTaken_q_reg\[6\] 1
predchecker_pin invalidTakenNext_7 u_core/invalidTaken_q_reg\[7\] 1
predchecker_pin invalidTakenNext_8 u_core/invalidTaken_q_reg\[8\] 1
predchecker_pin invalidTakenNext_9 u_core/invalidTaken_q_reg\[9\] 1
predchecker_pin invalidTakenNext_10 u_core/invalidTaken_q_reg\[10\] 1
predchecker_pin invalidTakenNext_11 u_core/invalidTaken_q_reg\[11\] 1
predchecker_pin invalidTakenNext_12 u_core/invalidTaken_q_reg\[12\] 1
predchecker_pin invalidTakenNext_13 u_core/invalidTaken_q_reg\[13\] 1
predchecker_pin invalidTakenNext_14 u_core/invalidTaken_q_reg\[14\] 1
predchecker_pin invalidTakenNext_15 u_core/invalidTaken_q_reg\[15\] 1
puts "PREDCHECKER_PIN_END PredChecker ok=$::PREDCHECKER_PIN_OK bad=$::PREDCHECKER_PIN_BAD"
if {$::PREDCHECKER_PIN_BAD != 0} { error "PREDCHECKER_PIN_MISS=$::PREDCHECKER_PIN_BAD" }
if {$::PREDCHECKER_PIN_OK != 1799} { error "PREDCHECKER_PIN_COUNT=$::PREDCHECKER_PIN_OK expect=1799" }
