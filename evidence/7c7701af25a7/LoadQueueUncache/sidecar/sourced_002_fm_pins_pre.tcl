# LoadQueueUncache FM「匹配前」钉点 —— 自动生成：scripts/gen_lquncache.py（勿手改）
#
# 只消名差，不修错配：set_user_match 只声明两点对应，比较照比；不约束 ref、不改 appvar、
# 不加黑盒、不 dont_verify。两类名差：
#   (a) golden 顶层寄存器是按字段展平的 s2_req_<k>_<字段> 等（651 个寄存器 / 5037 位），
#       重写核是结构体数组 u_core/s2_req_q_reg[k]\[字段][b] 等（形状取自 LoadQueueReplay /
#       InstrUncache 的 matched.rpt 实测：字段名下标带一个反斜杠，数字下标不带）；
#   (b) 5 个 PipelineRegModule 实例的 payload：golden io_out_bits_r_<字段>_reg[b]，
#       重写件是一根向量 u_core/<实例>/u_core/bits_q_reg[偏移+b]（6327 位，含 5 个 valid）。
# 条目 / FreeList / 仲裁器内部不钉（名字只差一层 u_core，交给 FM 自动配对）。
# fail-closed：set_user_match 从不抛异常（没配上返回 0），逐条数返回值；
# 拒一条、或成功数不等于字面整数 11364，就 error（safe interp 里 exit 被隐藏）。
# 进 fm.log 的输出一律 ASCII。
set ::LQU_PIN_EXPECT 11364
set ::LQU_PIN_OK 0
set ::LQU_PIN_BAD 0
proc lqu_pin1 {r i} {
  if {[set_user_match $r $i]} { incr ::LQU_PIN_OK } else {
    incr ::LQU_PIN_BAD
    if {$::LQU_PIN_BAD <= 10} { puts "LQU_PIN_FAIL: $r <-> $i" }
  }
}
# 寄存器 g（宽 w）<-> 核内 i：w==1 时两侧都不带位下标
proc lqu_pin {g i w} {
  set r "r:/WORK/LoadQueueUncache/${g}_reg"
  set m "i:/WORK/LoadQueueUncache/u_core/$i"
  if {$w == 1} { lqu_pin1 $r $m } else {
    for {set b 0} {$b < $w} {incr b} { lqu_pin1 "$r\[$b\]" "$m\[$b\]" }
  }
}
# 流水寄存器实例 p 的字段 f（宽 w，向量偏移 lsb）
proc lqu_pipe {p f w lsb} {
  set r "r:/WORK/LoadQueueUncache/$p/io_out_bits_r_${f}_reg"
  set m "i:/WORK/LoadQueueUncache/u_core/$p/u_core/bits_q_reg"
  if {$w == 1} { lqu_pin1 $r "$m\[$lsb\]" } else {
    for {set b 0} {$b < $w} {incr b} { lqu_pin1 "$r\[$b\]" "$m\[[expr {$lsb + $b}]\]" }
  }
}
puts "LQU_PIN_BEGIN LoadQueueUncache expect=$::LQU_PIN_EXPECT"
lqu_pin s2_req_0_uop_instr {s2_req_q_reg[0]\[uop_instr]} 32
lqu_pin s2_req_0_uop_pc {s2_req_q_reg[0]\[uop_pc]} 50
lqu_pin s2_req_0_uop_foldpc {s2_req_q_reg[0]\[uop_foldpc]} 10
lqu_pin s2_req_0_uop_exceptionVec_0 {s2_req_q_reg[0]\[uop_exceptionVec_0]} 1
lqu_pin s2_req_0_uop_exceptionVec_1 {s2_req_q_reg[0]\[uop_exceptionVec_1]} 1
lqu_pin s2_req_0_uop_exceptionVec_2 {s2_req_q_reg[0]\[uop_exceptionVec_2]} 1
lqu_pin s2_req_0_uop_exceptionVec_3 {s2_req_q_reg[0]\[uop_exceptionVec_3]} 1
lqu_pin s2_req_0_uop_exceptionVec_4 {s2_req_q_reg[0]\[uop_exceptionVec_4]} 1
lqu_pin s2_req_0_uop_exceptionVec_5 {s2_req_q_reg[0]\[uop_exceptionVec_5]} 1
lqu_pin s2_req_0_uop_exceptionVec_6 {s2_req_q_reg[0]\[uop_exceptionVec_6]} 1
lqu_pin s2_req_0_uop_exceptionVec_7 {s2_req_q_reg[0]\[uop_exceptionVec_7]} 1
lqu_pin s2_req_0_uop_exceptionVec_8 {s2_req_q_reg[0]\[uop_exceptionVec_8]} 1
lqu_pin s2_req_0_uop_exceptionVec_9 {s2_req_q_reg[0]\[uop_exceptionVec_9]} 1
lqu_pin s2_req_0_uop_exceptionVec_10 {s2_req_q_reg[0]\[uop_exceptionVec_10]} 1
lqu_pin s2_req_0_uop_exceptionVec_11 {s2_req_q_reg[0]\[uop_exceptionVec_11]} 1
lqu_pin s2_req_0_uop_exceptionVec_12 {s2_req_q_reg[0]\[uop_exceptionVec_12]} 1
lqu_pin s2_req_0_uop_exceptionVec_13 {s2_req_q_reg[0]\[uop_exceptionVec_13]} 1
lqu_pin s2_req_0_uop_exceptionVec_14 {s2_req_q_reg[0]\[uop_exceptionVec_14]} 1
lqu_pin s2_req_0_uop_exceptionVec_15 {s2_req_q_reg[0]\[uop_exceptionVec_15]} 1
lqu_pin s2_req_0_uop_exceptionVec_16 {s2_req_q_reg[0]\[uop_exceptionVec_16]} 1
lqu_pin s2_req_0_uop_exceptionVec_17 {s2_req_q_reg[0]\[uop_exceptionVec_17]} 1
lqu_pin s2_req_0_uop_exceptionVec_18 {s2_req_q_reg[0]\[uop_exceptionVec_18]} 1
lqu_pin s2_req_0_uop_exceptionVec_19 {s2_req_q_reg[0]\[uop_exceptionVec_19]} 1
lqu_pin s2_req_0_uop_exceptionVec_20 {s2_req_q_reg[0]\[uop_exceptionVec_20]} 1
lqu_pin s2_req_0_uop_exceptionVec_21 {s2_req_q_reg[0]\[uop_exceptionVec_21]} 1
lqu_pin s2_req_0_uop_exceptionVec_22 {s2_req_q_reg[0]\[uop_exceptionVec_22]} 1
lqu_pin s2_req_0_uop_exceptionVec_23 {s2_req_q_reg[0]\[uop_exceptionVec_23]} 1
lqu_pin s2_req_0_uop_isFetchMalAddr {s2_req_q_reg[0]\[uop_isFetchMalAddr]} 1
lqu_pin s2_req_0_uop_hasException {s2_req_q_reg[0]\[uop_hasException]} 1
lqu_pin s2_req_0_uop_trigger {s2_req_q_reg[0]\[uop_trigger]} 4
lqu_pin s2_req_0_uop_preDecodeInfo_valid {s2_req_q_reg[0]\[uop_preDecodeInfo_valid]} 1
lqu_pin s2_req_0_uop_preDecodeInfo_isRVC {s2_req_q_reg[0]\[uop_preDecodeInfo_isRVC]} 1
lqu_pin s2_req_0_uop_preDecodeInfo_brType {s2_req_q_reg[0]\[uop_preDecodeInfo_brType]} 2
lqu_pin s2_req_0_uop_preDecodeInfo_isCall {s2_req_q_reg[0]\[uop_preDecodeInfo_isCall]} 1
lqu_pin s2_req_0_uop_preDecodeInfo_isRet {s2_req_q_reg[0]\[uop_preDecodeInfo_isRet]} 1
lqu_pin s2_req_0_uop_pred_taken {s2_req_q_reg[0]\[uop_pred_taken]} 1
lqu_pin s2_req_0_uop_crossPageIPFFix {s2_req_q_reg[0]\[uop_crossPageIPFFix]} 1
lqu_pin s2_req_0_uop_ftqPtr_flag {s2_req_q_reg[0]\[uop_ftqPtr_flag]} 1
lqu_pin s2_req_0_uop_ftqPtr_value {s2_req_q_reg[0]\[uop_ftqPtr_value]} 6
lqu_pin s2_req_0_uop_ftqOffset {s2_req_q_reg[0]\[uop_ftqOffset]} 4
lqu_pin s2_req_0_uop_satpFlushFirstFetchFault {s2_req_q_reg[0]\[uop_satpFlushFirstFetchFault]} 1
lqu_pin s2_req_0_uop_srcType_0 {s2_req_q_reg[0]\[uop_srcType_0]} 4
lqu_pin s2_req_0_uop_srcType_1 {s2_req_q_reg[0]\[uop_srcType_1]} 4
lqu_pin s2_req_0_uop_srcType_2 {s2_req_q_reg[0]\[uop_srcType_2]} 4
lqu_pin s2_req_0_uop_srcType_3 {s2_req_q_reg[0]\[uop_srcType_3]} 4
lqu_pin s2_req_0_uop_srcType_4 {s2_req_q_reg[0]\[uop_srcType_4]} 4
lqu_pin s2_req_0_uop_ldest {s2_req_q_reg[0]\[uop_ldest]} 6
lqu_pin s2_req_0_uop_fuType {s2_req_q_reg[0]\[uop_fuType]} 35
lqu_pin s2_req_0_uop_fuOpType {s2_req_q_reg[0]\[uop_fuOpType]} 9
lqu_pin s2_req_0_uop_rfWen {s2_req_q_reg[0]\[uop_rfWen]} 1
lqu_pin s2_req_0_uop_fpWen {s2_req_q_reg[0]\[uop_fpWen]} 1
lqu_pin s2_req_0_uop_vecWen {s2_req_q_reg[0]\[uop_vecWen]} 1
lqu_pin s2_req_0_uop_v0Wen {s2_req_q_reg[0]\[uop_v0Wen]} 1
lqu_pin s2_req_0_uop_vlWen {s2_req_q_reg[0]\[uop_vlWen]} 1
lqu_pin s2_req_0_uop_isXSTrap {s2_req_q_reg[0]\[uop_isXSTrap]} 1
lqu_pin s2_req_0_uop_waitForward {s2_req_q_reg[0]\[uop_waitForward]} 1
lqu_pin s2_req_0_uop_blockBackward {s2_req_q_reg[0]\[uop_blockBackward]} 1
lqu_pin s2_req_0_uop_canRobCompress {s2_req_q_reg[0]\[uop_canRobCompress]} 1
lqu_pin s2_req_0_uop_selImm {s2_req_q_reg[0]\[uop_selImm]} 4
lqu_pin s2_req_0_uop_imm {s2_req_q_reg[0]\[uop_imm]} 32
lqu_pin s2_req_0_uop_fpu_typeTagOut {s2_req_q_reg[0]\[uop_fpu_typeTagOut]} 2
lqu_pin s2_req_0_uop_fpu_wflags {s2_req_q_reg[0]\[uop_fpu_wflags]} 1
lqu_pin s2_req_0_uop_fpu_typ {s2_req_q_reg[0]\[uop_fpu_typ]} 2
lqu_pin s2_req_0_uop_fpu_fmt {s2_req_q_reg[0]\[uop_fpu_fmt]} 2
lqu_pin s2_req_0_uop_fpu_rm {s2_req_q_reg[0]\[uop_fpu_rm]} 3
lqu_pin s2_req_0_uop_vpu_vill {s2_req_q_reg[0]\[uop_vpu_vill]} 1
lqu_pin s2_req_0_uop_vpu_vma {s2_req_q_reg[0]\[uop_vpu_vma]} 1
lqu_pin s2_req_0_uop_vpu_vta {s2_req_q_reg[0]\[uop_vpu_vta]} 1
lqu_pin s2_req_0_uop_vpu_vsew {s2_req_q_reg[0]\[uop_vpu_vsew]} 2
lqu_pin s2_req_0_uop_vpu_vlmul {s2_req_q_reg[0]\[uop_vpu_vlmul]} 3
lqu_pin s2_req_0_uop_vpu_specVill {s2_req_q_reg[0]\[uop_vpu_specVill]} 1
lqu_pin s2_req_0_uop_vpu_specVma {s2_req_q_reg[0]\[uop_vpu_specVma]} 1
lqu_pin s2_req_0_uop_vpu_specVta {s2_req_q_reg[0]\[uop_vpu_specVta]} 1
lqu_pin s2_req_0_uop_vpu_specVsew {s2_req_q_reg[0]\[uop_vpu_specVsew]} 2
lqu_pin s2_req_0_uop_vpu_specVlmul {s2_req_q_reg[0]\[uop_vpu_specVlmul]} 3
lqu_pin s2_req_0_uop_vpu_vm {s2_req_q_reg[0]\[uop_vpu_vm]} 1
lqu_pin s2_req_0_uop_vpu_vstart {s2_req_q_reg[0]\[uop_vpu_vstart]} 8
lqu_pin s2_req_0_uop_vpu_frm {s2_req_q_reg[0]\[uop_vpu_frm]} 3
lqu_pin s2_req_0_uop_vpu_fpu_isFpToVecInst {s2_req_q_reg[0]\[uop_vpu_fpu_isFpToVecInst]} 1
lqu_pin s2_req_0_uop_vpu_fpu_isFP32Instr {s2_req_q_reg[0]\[uop_vpu_fpu_isFP32Instr]} 1
lqu_pin s2_req_0_uop_vpu_fpu_isFP64Instr {s2_req_q_reg[0]\[uop_vpu_fpu_isFP64Instr]} 1
lqu_pin s2_req_0_uop_vpu_fpu_isReduction {s2_req_q_reg[0]\[uop_vpu_fpu_isReduction]} 1
lqu_pin s2_req_0_uop_vpu_fpu_isFoldTo1_2 {s2_req_q_reg[0]\[uop_vpu_fpu_isFoldTo1_2]} 1
lqu_pin s2_req_0_uop_vpu_fpu_isFoldTo1_4 {s2_req_q_reg[0]\[uop_vpu_fpu_isFoldTo1_4]} 1
lqu_pin s2_req_0_uop_vpu_fpu_isFoldTo1_8 {s2_req_q_reg[0]\[uop_vpu_fpu_isFoldTo1_8]} 1
lqu_pin s2_req_0_uop_vpu_vxrm {s2_req_q_reg[0]\[uop_vpu_vxrm]} 2
lqu_pin s2_req_0_uop_vpu_vuopIdx {s2_req_q_reg[0]\[uop_vpu_vuopIdx]} 7
lqu_pin s2_req_0_uop_vpu_lastUop {s2_req_q_reg[0]\[uop_vpu_lastUop]} 1
lqu_pin s2_req_0_uop_vpu_vmask {s2_req_q_reg[0]\[uop_vpu_vmask]} 128
lqu_pin s2_req_0_uop_vpu_vl {s2_req_q_reg[0]\[uop_vpu_vl]} 8
lqu_pin s2_req_0_uop_vpu_nf {s2_req_q_reg[0]\[uop_vpu_nf]} 3
lqu_pin s2_req_0_uop_vpu_veew {s2_req_q_reg[0]\[uop_vpu_veew]} 2
lqu_pin s2_req_0_uop_vpu_isReverse {s2_req_q_reg[0]\[uop_vpu_isReverse]} 1
lqu_pin s2_req_0_uop_vpu_isExt {s2_req_q_reg[0]\[uop_vpu_isExt]} 1
lqu_pin s2_req_0_uop_vpu_isNarrow {s2_req_q_reg[0]\[uop_vpu_isNarrow]} 1
lqu_pin s2_req_0_uop_vpu_isDstMask {s2_req_q_reg[0]\[uop_vpu_isDstMask]} 1
lqu_pin s2_req_0_uop_vpu_isOpMask {s2_req_q_reg[0]\[uop_vpu_isOpMask]} 1
lqu_pin s2_req_0_uop_vpu_isMove {s2_req_q_reg[0]\[uop_vpu_isMove]} 1
lqu_pin s2_req_0_uop_vpu_isDependOldVd {s2_req_q_reg[0]\[uop_vpu_isDependOldVd]} 1
lqu_pin s2_req_0_uop_vpu_isWritePartVd {s2_req_q_reg[0]\[uop_vpu_isWritePartVd]} 1
lqu_pin s2_req_0_uop_vpu_isVleff {s2_req_q_reg[0]\[uop_vpu_isVleff]} 1
lqu_pin s2_req_0_uop_vlsInstr {s2_req_q_reg[0]\[uop_vlsInstr]} 1
lqu_pin s2_req_0_uop_wfflags {s2_req_q_reg[0]\[uop_wfflags]} 1
lqu_pin s2_req_0_uop_isMove {s2_req_q_reg[0]\[uop_isMove]} 1
lqu_pin s2_req_0_uop_isDropAmocasSta {s2_req_q_reg[0]\[uop_isDropAmocasSta]} 1
lqu_pin s2_req_0_uop_uopIdx {s2_req_q_reg[0]\[uop_uopIdx]} 7
lqu_pin s2_req_0_uop_isVset {s2_req_q_reg[0]\[uop_isVset]} 1
lqu_pin s2_req_0_uop_firstUop {s2_req_q_reg[0]\[uop_firstUop]} 1
lqu_pin s2_req_0_uop_lastUop {s2_req_q_reg[0]\[uop_lastUop]} 1
lqu_pin s2_req_0_uop_numUops {s2_req_q_reg[0]\[uop_numUops]} 7
lqu_pin s2_req_0_uop_numWB {s2_req_q_reg[0]\[uop_numWB]} 7
lqu_pin s2_req_0_uop_commitType {s2_req_q_reg[0]\[uop_commitType]} 3
lqu_pin s2_req_0_uop_srcState_0 {s2_req_q_reg[0]\[uop_srcState_0]} 1
lqu_pin s2_req_0_uop_srcState_1 {s2_req_q_reg[0]\[uop_srcState_1]} 1
lqu_pin s2_req_0_uop_srcState_2 {s2_req_q_reg[0]\[uop_srcState_2]} 1
lqu_pin s2_req_0_uop_srcState_3 {s2_req_q_reg[0]\[uop_srcState_3]} 1
lqu_pin s2_req_0_uop_srcState_4 {s2_req_q_reg[0]\[uop_srcState_4]} 1
lqu_pin s2_req_0_uop_srcLoadDependency_0_0 {s2_req_q_reg[0]\[uop_srcLoadDependency_0_0]} 2
lqu_pin s2_req_0_uop_srcLoadDependency_0_1 {s2_req_q_reg[0]\[uop_srcLoadDependency_0_1]} 2
lqu_pin s2_req_0_uop_srcLoadDependency_0_2 {s2_req_q_reg[0]\[uop_srcLoadDependency_0_2]} 2
lqu_pin s2_req_0_uop_srcLoadDependency_1_0 {s2_req_q_reg[0]\[uop_srcLoadDependency_1_0]} 2
lqu_pin s2_req_0_uop_srcLoadDependency_1_1 {s2_req_q_reg[0]\[uop_srcLoadDependency_1_1]} 2
lqu_pin s2_req_0_uop_srcLoadDependency_1_2 {s2_req_q_reg[0]\[uop_srcLoadDependency_1_2]} 2
lqu_pin s2_req_0_uop_srcLoadDependency_2_0 {s2_req_q_reg[0]\[uop_srcLoadDependency_2_0]} 2
lqu_pin s2_req_0_uop_srcLoadDependency_2_1 {s2_req_q_reg[0]\[uop_srcLoadDependency_2_1]} 2
lqu_pin s2_req_0_uop_srcLoadDependency_2_2 {s2_req_q_reg[0]\[uop_srcLoadDependency_2_2]} 2
lqu_pin s2_req_0_uop_srcLoadDependency_3_0 {s2_req_q_reg[0]\[uop_srcLoadDependency_3_0]} 2
lqu_pin s2_req_0_uop_srcLoadDependency_3_1 {s2_req_q_reg[0]\[uop_srcLoadDependency_3_1]} 2
lqu_pin s2_req_0_uop_srcLoadDependency_3_2 {s2_req_q_reg[0]\[uop_srcLoadDependency_3_2]} 2
lqu_pin s2_req_0_uop_srcLoadDependency_4_0 {s2_req_q_reg[0]\[uop_srcLoadDependency_4_0]} 2
lqu_pin s2_req_0_uop_srcLoadDependency_4_1 {s2_req_q_reg[0]\[uop_srcLoadDependency_4_1]} 2
lqu_pin s2_req_0_uop_srcLoadDependency_4_2 {s2_req_q_reg[0]\[uop_srcLoadDependency_4_2]} 2
lqu_pin s2_req_0_uop_psrc_0 {s2_req_q_reg[0]\[uop_psrc_0]} 8
lqu_pin s2_req_0_uop_psrc_1 {s2_req_q_reg[0]\[uop_psrc_1]} 8
lqu_pin s2_req_0_uop_psrc_2 {s2_req_q_reg[0]\[uop_psrc_2]} 8
lqu_pin s2_req_0_uop_psrc_3 {s2_req_q_reg[0]\[uop_psrc_3]} 8
lqu_pin s2_req_0_uop_psrc_4 {s2_req_q_reg[0]\[uop_psrc_4]} 8
lqu_pin s2_req_0_uop_pdest {s2_req_q_reg[0]\[uop_pdest]} 8
lqu_pin s2_req_0_uop_useRegCache_0 {s2_req_q_reg[0]\[uop_useRegCache_0]} 1
lqu_pin s2_req_0_uop_useRegCache_1 {s2_req_q_reg[0]\[uop_useRegCache_1]} 1
lqu_pin s2_req_0_uop_regCacheIdx_0 {s2_req_q_reg[0]\[uop_regCacheIdx_0]} 5
lqu_pin s2_req_0_uop_regCacheIdx_1 {s2_req_q_reg[0]\[uop_regCacheIdx_1]} 5
lqu_pin s2_req_0_uop_robIdx_flag {s2_req_q_reg[0]\[uop_robIdx_flag]} 1
lqu_pin s2_req_0_uop_robIdx_value {s2_req_q_reg[0]\[uop_robIdx_value]} 8
lqu_pin s2_req_0_uop_instrSize {s2_req_q_reg[0]\[uop_instrSize]} 3
lqu_pin s2_req_0_uop_dirtyFs {s2_req_q_reg[0]\[uop_dirtyFs]} 1
lqu_pin s2_req_0_uop_dirtyVs {s2_req_q_reg[0]\[uop_dirtyVs]} 1
lqu_pin s2_req_0_uop_traceBlockInPipe_itype {s2_req_q_reg[0]\[uop_traceBlockInPipe_itype]} 4
lqu_pin s2_req_0_uop_traceBlockInPipe_iretire {s2_req_q_reg[0]\[uop_traceBlockInPipe_iretire]} 4
lqu_pin s2_req_0_uop_traceBlockInPipe_ilastsize {s2_req_q_reg[0]\[uop_traceBlockInPipe_ilastsize]} 1
lqu_pin s2_req_0_uop_eliminatedMove {s2_req_q_reg[0]\[uop_eliminatedMove]} 1
lqu_pin s2_req_0_uop_snapshot {s2_req_q_reg[0]\[uop_snapshot]} 1
lqu_pin s2_req_0_uop_debugInfo_eliminatedMove {s2_req_q_reg[0]\[uop_debugInfo_eliminatedMove]} 1
lqu_pin s2_req_0_uop_debugInfo_renameTime {s2_req_q_reg[0]\[uop_debugInfo_renameTime]} 64
lqu_pin s2_req_0_uop_debugInfo_dispatchTime {s2_req_q_reg[0]\[uop_debugInfo_dispatchTime]} 64
lqu_pin s2_req_0_uop_debugInfo_enqRsTime {s2_req_q_reg[0]\[uop_debugInfo_enqRsTime]} 64
lqu_pin s2_req_0_uop_debugInfo_selectTime {s2_req_q_reg[0]\[uop_debugInfo_selectTime]} 64
lqu_pin s2_req_0_uop_debugInfo_issueTime {s2_req_q_reg[0]\[uop_debugInfo_issueTime]} 64
lqu_pin s2_req_0_uop_debugInfo_writebackTime {s2_req_q_reg[0]\[uop_debugInfo_writebackTime]} 64
lqu_pin s2_req_0_uop_debugInfo_runahead_checkpoint_id {s2_req_q_reg[0]\[uop_debugInfo_runahead_checkpoint_id]} 64
lqu_pin s2_req_0_uop_debugInfo_tlbFirstReqTime {s2_req_q_reg[0]\[uop_debugInfo_tlbFirstReqTime]} 64
lqu_pin s2_req_0_uop_debugInfo_tlbRespTime {s2_req_q_reg[0]\[uop_debugInfo_tlbRespTime]} 64
lqu_pin s2_req_0_uop_debug_seqNum_seqNum {s2_req_q_reg[0]\[uop_debug_seqNum_seqNum]} 56
lqu_pin s2_req_0_uop_debug_seqNum_uopIdx {s2_req_q_reg[0]\[uop_debug_seqNum_uopIdx]} 8
lqu_pin s2_req_0_uop_storeSetHit {s2_req_q_reg[0]\[uop_storeSetHit]} 1
lqu_pin s2_req_0_uop_waitForRobIdx_flag {s2_req_q_reg[0]\[uop_waitForRobIdx_flag]} 1
lqu_pin s2_req_0_uop_waitForRobIdx_value {s2_req_q_reg[0]\[uop_waitForRobIdx_value]} 8
lqu_pin s2_req_0_uop_loadWaitBit {s2_req_q_reg[0]\[uop_loadWaitBit]} 1
lqu_pin s2_req_0_uop_loadWaitStrict {s2_req_q_reg[0]\[uop_loadWaitStrict]} 1
lqu_pin s2_req_0_uop_ssid {s2_req_q_reg[0]\[uop_ssid]} 5
lqu_pin s2_req_0_uop_lqIdx_flag {s2_req_q_reg[0]\[uop_lqIdx_flag]} 1
lqu_pin s2_req_0_uop_lqIdx_value {s2_req_q_reg[0]\[uop_lqIdx_value]} 7
lqu_pin s2_req_0_uop_sqIdx_flag {s2_req_q_reg[0]\[uop_sqIdx_flag]} 1
lqu_pin s2_req_0_uop_sqIdx_value {s2_req_q_reg[0]\[uop_sqIdx_value]} 6
lqu_pin s2_req_0_uop_singleStep {s2_req_q_reg[0]\[uop_singleStep]} 1
lqu_pin s2_req_0_uop_debug_fuType {s2_req_q_reg[0]\[uop_debug_fuType]} 35
lqu_pin s2_req_0_uop_debug_sim_trig {s2_req_q_reg[0]\[uop_debug_sim_trig]} 1
lqu_pin s2_req_0_uop_numLsElem {s2_req_q_reg[0]\[uop_numLsElem]} 5
lqu_pin s2_req_0_vaddr {s2_req_q_reg[0]\[vaddr]} 50
lqu_pin s2_req_0_fullva {s2_req_q_reg[0]\[fullva]} 64
lqu_pin s2_req_0_paddr {s2_req_q_reg[0]\[paddr]} 48
lqu_pin s2_req_0_gpaddr {s2_req_q_reg[0]\[gpaddr]} 64
lqu_pin s2_req_0_mask {s2_req_q_reg[0]\[mask]} 16
lqu_pin s2_req_0_nc {s2_req_q_reg[0]\[nc]} 1
lqu_pin s2_req_0_mmio {s2_req_q_reg[0]\[mmio]} 1
lqu_pin s2_req_0_memBackTypeMM {s2_req_q_reg[0]\[memBackTypeMM]} 1
lqu_pin s2_req_0_isHyper {s2_req_q_reg[0]\[isHyper]} 1
lqu_pin s2_req_0_isForVSnonLeafPTE {s2_req_q_reg[0]\[isForVSnonLeafPTE]} 1
lqu_pin s2_req_0_isvec {s2_req_q_reg[0]\[isvec]} 1
lqu_pin s2_req_0_is128bit {s2_req_q_reg[0]\[is128bit]} 1
lqu_pin s2_req_0_vecActive {s2_req_q_reg[0]\[vecActive]} 1
lqu_pin s2_req_0_schedIndex {s2_req_q_reg[0]\[schedIndex]} 7
lqu_pin s2_req_0_rep_info_cause_0 {s2_req_q_reg[0]\[rep_info_cause_0]} 1
lqu_pin s2_req_0_rep_info_cause_1 {s2_req_q_reg[0]\[rep_info_cause_1]} 1
lqu_pin s2_req_0_rep_info_cause_2 {s2_req_q_reg[0]\[rep_info_cause_2]} 1
lqu_pin s2_req_0_rep_info_cause_3 {s2_req_q_reg[0]\[rep_info_cause_3]} 1
lqu_pin s2_req_0_rep_info_cause_4 {s2_req_q_reg[0]\[rep_info_cause_4]} 1
lqu_pin s2_req_0_rep_info_cause_5 {s2_req_q_reg[0]\[rep_info_cause_5]} 1
lqu_pin s2_req_0_rep_info_cause_6 {s2_req_q_reg[0]\[rep_info_cause_6]} 1
lqu_pin s2_req_0_rep_info_cause_7 {s2_req_q_reg[0]\[rep_info_cause_7]} 1
lqu_pin s2_req_0_rep_info_cause_8 {s2_req_q_reg[0]\[rep_info_cause_8]} 1
lqu_pin s2_req_0_rep_info_cause_9 {s2_req_q_reg[0]\[rep_info_cause_9]} 1
lqu_pin s2_req_0_rep_info_cause_10 {s2_req_q_reg[0]\[rep_info_cause_10]} 1
lqu_pin s2_req_1_uop_instr {s2_req_q_reg[1]\[uop_instr]} 32
lqu_pin s2_req_1_uop_pc {s2_req_q_reg[1]\[uop_pc]} 50
lqu_pin s2_req_1_uop_foldpc {s2_req_q_reg[1]\[uop_foldpc]} 10
lqu_pin s2_req_1_uop_exceptionVec_0 {s2_req_q_reg[1]\[uop_exceptionVec_0]} 1
lqu_pin s2_req_1_uop_exceptionVec_1 {s2_req_q_reg[1]\[uop_exceptionVec_1]} 1
lqu_pin s2_req_1_uop_exceptionVec_2 {s2_req_q_reg[1]\[uop_exceptionVec_2]} 1
lqu_pin s2_req_1_uop_exceptionVec_3 {s2_req_q_reg[1]\[uop_exceptionVec_3]} 1
lqu_pin s2_req_1_uop_exceptionVec_4 {s2_req_q_reg[1]\[uop_exceptionVec_4]} 1
lqu_pin s2_req_1_uop_exceptionVec_5 {s2_req_q_reg[1]\[uop_exceptionVec_5]} 1
lqu_pin s2_req_1_uop_exceptionVec_6 {s2_req_q_reg[1]\[uop_exceptionVec_6]} 1
lqu_pin s2_req_1_uop_exceptionVec_7 {s2_req_q_reg[1]\[uop_exceptionVec_7]} 1
lqu_pin s2_req_1_uop_exceptionVec_8 {s2_req_q_reg[1]\[uop_exceptionVec_8]} 1
lqu_pin s2_req_1_uop_exceptionVec_9 {s2_req_q_reg[1]\[uop_exceptionVec_9]} 1
lqu_pin s2_req_1_uop_exceptionVec_10 {s2_req_q_reg[1]\[uop_exceptionVec_10]} 1
lqu_pin s2_req_1_uop_exceptionVec_11 {s2_req_q_reg[1]\[uop_exceptionVec_11]} 1
lqu_pin s2_req_1_uop_exceptionVec_12 {s2_req_q_reg[1]\[uop_exceptionVec_12]} 1
lqu_pin s2_req_1_uop_exceptionVec_13 {s2_req_q_reg[1]\[uop_exceptionVec_13]} 1
lqu_pin s2_req_1_uop_exceptionVec_14 {s2_req_q_reg[1]\[uop_exceptionVec_14]} 1
lqu_pin s2_req_1_uop_exceptionVec_15 {s2_req_q_reg[1]\[uop_exceptionVec_15]} 1
lqu_pin s2_req_1_uop_exceptionVec_16 {s2_req_q_reg[1]\[uop_exceptionVec_16]} 1
lqu_pin s2_req_1_uop_exceptionVec_17 {s2_req_q_reg[1]\[uop_exceptionVec_17]} 1
lqu_pin s2_req_1_uop_exceptionVec_18 {s2_req_q_reg[1]\[uop_exceptionVec_18]} 1
lqu_pin s2_req_1_uop_exceptionVec_19 {s2_req_q_reg[1]\[uop_exceptionVec_19]} 1
lqu_pin s2_req_1_uop_exceptionVec_20 {s2_req_q_reg[1]\[uop_exceptionVec_20]} 1
lqu_pin s2_req_1_uop_exceptionVec_21 {s2_req_q_reg[1]\[uop_exceptionVec_21]} 1
lqu_pin s2_req_1_uop_exceptionVec_22 {s2_req_q_reg[1]\[uop_exceptionVec_22]} 1
lqu_pin s2_req_1_uop_exceptionVec_23 {s2_req_q_reg[1]\[uop_exceptionVec_23]} 1
lqu_pin s2_req_1_uop_isFetchMalAddr {s2_req_q_reg[1]\[uop_isFetchMalAddr]} 1
lqu_pin s2_req_1_uop_hasException {s2_req_q_reg[1]\[uop_hasException]} 1
lqu_pin s2_req_1_uop_trigger {s2_req_q_reg[1]\[uop_trigger]} 4
lqu_pin s2_req_1_uop_preDecodeInfo_valid {s2_req_q_reg[1]\[uop_preDecodeInfo_valid]} 1
lqu_pin s2_req_1_uop_preDecodeInfo_isRVC {s2_req_q_reg[1]\[uop_preDecodeInfo_isRVC]} 1
lqu_pin s2_req_1_uop_preDecodeInfo_brType {s2_req_q_reg[1]\[uop_preDecodeInfo_brType]} 2
lqu_pin s2_req_1_uop_preDecodeInfo_isCall {s2_req_q_reg[1]\[uop_preDecodeInfo_isCall]} 1
lqu_pin s2_req_1_uop_preDecodeInfo_isRet {s2_req_q_reg[1]\[uop_preDecodeInfo_isRet]} 1
lqu_pin s2_req_1_uop_pred_taken {s2_req_q_reg[1]\[uop_pred_taken]} 1
lqu_pin s2_req_1_uop_crossPageIPFFix {s2_req_q_reg[1]\[uop_crossPageIPFFix]} 1
lqu_pin s2_req_1_uop_ftqPtr_flag {s2_req_q_reg[1]\[uop_ftqPtr_flag]} 1
lqu_pin s2_req_1_uop_ftqPtr_value {s2_req_q_reg[1]\[uop_ftqPtr_value]} 6
lqu_pin s2_req_1_uop_ftqOffset {s2_req_q_reg[1]\[uop_ftqOffset]} 4
lqu_pin s2_req_1_uop_satpFlushFirstFetchFault {s2_req_q_reg[1]\[uop_satpFlushFirstFetchFault]} 1
lqu_pin s2_req_1_uop_srcType_0 {s2_req_q_reg[1]\[uop_srcType_0]} 4
lqu_pin s2_req_1_uop_srcType_1 {s2_req_q_reg[1]\[uop_srcType_1]} 4
lqu_pin s2_req_1_uop_srcType_2 {s2_req_q_reg[1]\[uop_srcType_2]} 4
lqu_pin s2_req_1_uop_srcType_3 {s2_req_q_reg[1]\[uop_srcType_3]} 4
lqu_pin s2_req_1_uop_srcType_4 {s2_req_q_reg[1]\[uop_srcType_4]} 4
lqu_pin s2_req_1_uop_ldest {s2_req_q_reg[1]\[uop_ldest]} 6
lqu_pin s2_req_1_uop_fuType {s2_req_q_reg[1]\[uop_fuType]} 35
lqu_pin s2_req_1_uop_fuOpType {s2_req_q_reg[1]\[uop_fuOpType]} 9
lqu_pin s2_req_1_uop_rfWen {s2_req_q_reg[1]\[uop_rfWen]} 1
lqu_pin s2_req_1_uop_fpWen {s2_req_q_reg[1]\[uop_fpWen]} 1
lqu_pin s2_req_1_uop_vecWen {s2_req_q_reg[1]\[uop_vecWen]} 1
lqu_pin s2_req_1_uop_v0Wen {s2_req_q_reg[1]\[uop_v0Wen]} 1
lqu_pin s2_req_1_uop_vlWen {s2_req_q_reg[1]\[uop_vlWen]} 1
lqu_pin s2_req_1_uop_isXSTrap {s2_req_q_reg[1]\[uop_isXSTrap]} 1
lqu_pin s2_req_1_uop_waitForward {s2_req_q_reg[1]\[uop_waitForward]} 1
lqu_pin s2_req_1_uop_blockBackward {s2_req_q_reg[1]\[uop_blockBackward]} 1
lqu_pin s2_req_1_uop_canRobCompress {s2_req_q_reg[1]\[uop_canRobCompress]} 1
lqu_pin s2_req_1_uop_selImm {s2_req_q_reg[1]\[uop_selImm]} 4
lqu_pin s2_req_1_uop_imm {s2_req_q_reg[1]\[uop_imm]} 32
lqu_pin s2_req_1_uop_fpu_typeTagOut {s2_req_q_reg[1]\[uop_fpu_typeTagOut]} 2
lqu_pin s2_req_1_uop_fpu_wflags {s2_req_q_reg[1]\[uop_fpu_wflags]} 1
lqu_pin s2_req_1_uop_fpu_typ {s2_req_q_reg[1]\[uop_fpu_typ]} 2
lqu_pin s2_req_1_uop_fpu_fmt {s2_req_q_reg[1]\[uop_fpu_fmt]} 2
lqu_pin s2_req_1_uop_fpu_rm {s2_req_q_reg[1]\[uop_fpu_rm]} 3
lqu_pin s2_req_1_uop_vpu_vill {s2_req_q_reg[1]\[uop_vpu_vill]} 1
lqu_pin s2_req_1_uop_vpu_vma {s2_req_q_reg[1]\[uop_vpu_vma]} 1
lqu_pin s2_req_1_uop_vpu_vta {s2_req_q_reg[1]\[uop_vpu_vta]} 1
lqu_pin s2_req_1_uop_vpu_vsew {s2_req_q_reg[1]\[uop_vpu_vsew]} 2
lqu_pin s2_req_1_uop_vpu_vlmul {s2_req_q_reg[1]\[uop_vpu_vlmul]} 3
lqu_pin s2_req_1_uop_vpu_specVill {s2_req_q_reg[1]\[uop_vpu_specVill]} 1
lqu_pin s2_req_1_uop_vpu_specVma {s2_req_q_reg[1]\[uop_vpu_specVma]} 1
lqu_pin s2_req_1_uop_vpu_specVta {s2_req_q_reg[1]\[uop_vpu_specVta]} 1
lqu_pin s2_req_1_uop_vpu_specVsew {s2_req_q_reg[1]\[uop_vpu_specVsew]} 2
lqu_pin s2_req_1_uop_vpu_specVlmul {s2_req_q_reg[1]\[uop_vpu_specVlmul]} 3
lqu_pin s2_req_1_uop_vpu_vm {s2_req_q_reg[1]\[uop_vpu_vm]} 1
lqu_pin s2_req_1_uop_vpu_vstart {s2_req_q_reg[1]\[uop_vpu_vstart]} 8
lqu_pin s2_req_1_uop_vpu_frm {s2_req_q_reg[1]\[uop_vpu_frm]} 3
lqu_pin s2_req_1_uop_vpu_fpu_isFpToVecInst {s2_req_q_reg[1]\[uop_vpu_fpu_isFpToVecInst]} 1
lqu_pin s2_req_1_uop_vpu_fpu_isFP32Instr {s2_req_q_reg[1]\[uop_vpu_fpu_isFP32Instr]} 1
lqu_pin s2_req_1_uop_vpu_fpu_isFP64Instr {s2_req_q_reg[1]\[uop_vpu_fpu_isFP64Instr]} 1
lqu_pin s2_req_1_uop_vpu_fpu_isReduction {s2_req_q_reg[1]\[uop_vpu_fpu_isReduction]} 1
lqu_pin s2_req_1_uop_vpu_fpu_isFoldTo1_2 {s2_req_q_reg[1]\[uop_vpu_fpu_isFoldTo1_2]} 1
lqu_pin s2_req_1_uop_vpu_fpu_isFoldTo1_4 {s2_req_q_reg[1]\[uop_vpu_fpu_isFoldTo1_4]} 1
lqu_pin s2_req_1_uop_vpu_fpu_isFoldTo1_8 {s2_req_q_reg[1]\[uop_vpu_fpu_isFoldTo1_8]} 1
lqu_pin s2_req_1_uop_vpu_vxrm {s2_req_q_reg[1]\[uop_vpu_vxrm]} 2
lqu_pin s2_req_1_uop_vpu_vuopIdx {s2_req_q_reg[1]\[uop_vpu_vuopIdx]} 7
lqu_pin s2_req_1_uop_vpu_lastUop {s2_req_q_reg[1]\[uop_vpu_lastUop]} 1
lqu_pin s2_req_1_uop_vpu_vmask {s2_req_q_reg[1]\[uop_vpu_vmask]} 128
lqu_pin s2_req_1_uop_vpu_vl {s2_req_q_reg[1]\[uop_vpu_vl]} 8
lqu_pin s2_req_1_uop_vpu_nf {s2_req_q_reg[1]\[uop_vpu_nf]} 3
lqu_pin s2_req_1_uop_vpu_veew {s2_req_q_reg[1]\[uop_vpu_veew]} 2
lqu_pin s2_req_1_uop_vpu_isReverse {s2_req_q_reg[1]\[uop_vpu_isReverse]} 1
lqu_pin s2_req_1_uop_vpu_isExt {s2_req_q_reg[1]\[uop_vpu_isExt]} 1
lqu_pin s2_req_1_uop_vpu_isNarrow {s2_req_q_reg[1]\[uop_vpu_isNarrow]} 1
lqu_pin s2_req_1_uop_vpu_isDstMask {s2_req_q_reg[1]\[uop_vpu_isDstMask]} 1
lqu_pin s2_req_1_uop_vpu_isOpMask {s2_req_q_reg[1]\[uop_vpu_isOpMask]} 1
lqu_pin s2_req_1_uop_vpu_isMove {s2_req_q_reg[1]\[uop_vpu_isMove]} 1
lqu_pin s2_req_1_uop_vpu_isDependOldVd {s2_req_q_reg[1]\[uop_vpu_isDependOldVd]} 1
lqu_pin s2_req_1_uop_vpu_isWritePartVd {s2_req_q_reg[1]\[uop_vpu_isWritePartVd]} 1
lqu_pin s2_req_1_uop_vpu_isVleff {s2_req_q_reg[1]\[uop_vpu_isVleff]} 1
lqu_pin s2_req_1_uop_vlsInstr {s2_req_q_reg[1]\[uop_vlsInstr]} 1
lqu_pin s2_req_1_uop_wfflags {s2_req_q_reg[1]\[uop_wfflags]} 1
lqu_pin s2_req_1_uop_isMove {s2_req_q_reg[1]\[uop_isMove]} 1
lqu_pin s2_req_1_uop_isDropAmocasSta {s2_req_q_reg[1]\[uop_isDropAmocasSta]} 1
lqu_pin s2_req_1_uop_uopIdx {s2_req_q_reg[1]\[uop_uopIdx]} 7
lqu_pin s2_req_1_uop_isVset {s2_req_q_reg[1]\[uop_isVset]} 1
lqu_pin s2_req_1_uop_firstUop {s2_req_q_reg[1]\[uop_firstUop]} 1
lqu_pin s2_req_1_uop_lastUop {s2_req_q_reg[1]\[uop_lastUop]} 1
lqu_pin s2_req_1_uop_numUops {s2_req_q_reg[1]\[uop_numUops]} 7
lqu_pin s2_req_1_uop_numWB {s2_req_q_reg[1]\[uop_numWB]} 7
lqu_pin s2_req_1_uop_commitType {s2_req_q_reg[1]\[uop_commitType]} 3
lqu_pin s2_req_1_uop_srcState_0 {s2_req_q_reg[1]\[uop_srcState_0]} 1
lqu_pin s2_req_1_uop_srcState_1 {s2_req_q_reg[1]\[uop_srcState_1]} 1
lqu_pin s2_req_1_uop_srcState_2 {s2_req_q_reg[1]\[uop_srcState_2]} 1
lqu_pin s2_req_1_uop_srcState_3 {s2_req_q_reg[1]\[uop_srcState_3]} 1
lqu_pin s2_req_1_uop_srcState_4 {s2_req_q_reg[1]\[uop_srcState_4]} 1
lqu_pin s2_req_1_uop_srcLoadDependency_0_0 {s2_req_q_reg[1]\[uop_srcLoadDependency_0_0]} 2
lqu_pin s2_req_1_uop_srcLoadDependency_0_1 {s2_req_q_reg[1]\[uop_srcLoadDependency_0_1]} 2
lqu_pin s2_req_1_uop_srcLoadDependency_0_2 {s2_req_q_reg[1]\[uop_srcLoadDependency_0_2]} 2
lqu_pin s2_req_1_uop_srcLoadDependency_1_0 {s2_req_q_reg[1]\[uop_srcLoadDependency_1_0]} 2
lqu_pin s2_req_1_uop_srcLoadDependency_1_1 {s2_req_q_reg[1]\[uop_srcLoadDependency_1_1]} 2
lqu_pin s2_req_1_uop_srcLoadDependency_1_2 {s2_req_q_reg[1]\[uop_srcLoadDependency_1_2]} 2
lqu_pin s2_req_1_uop_srcLoadDependency_2_0 {s2_req_q_reg[1]\[uop_srcLoadDependency_2_0]} 2
lqu_pin s2_req_1_uop_srcLoadDependency_2_1 {s2_req_q_reg[1]\[uop_srcLoadDependency_2_1]} 2
lqu_pin s2_req_1_uop_srcLoadDependency_2_2 {s2_req_q_reg[1]\[uop_srcLoadDependency_2_2]} 2
lqu_pin s2_req_1_uop_srcLoadDependency_3_0 {s2_req_q_reg[1]\[uop_srcLoadDependency_3_0]} 2
lqu_pin s2_req_1_uop_srcLoadDependency_3_1 {s2_req_q_reg[1]\[uop_srcLoadDependency_3_1]} 2
lqu_pin s2_req_1_uop_srcLoadDependency_3_2 {s2_req_q_reg[1]\[uop_srcLoadDependency_3_2]} 2
lqu_pin s2_req_1_uop_srcLoadDependency_4_0 {s2_req_q_reg[1]\[uop_srcLoadDependency_4_0]} 2
lqu_pin s2_req_1_uop_srcLoadDependency_4_1 {s2_req_q_reg[1]\[uop_srcLoadDependency_4_1]} 2
lqu_pin s2_req_1_uop_srcLoadDependency_4_2 {s2_req_q_reg[1]\[uop_srcLoadDependency_4_2]} 2
lqu_pin s2_req_1_uop_psrc_0 {s2_req_q_reg[1]\[uop_psrc_0]} 8
lqu_pin s2_req_1_uop_psrc_1 {s2_req_q_reg[1]\[uop_psrc_1]} 8
lqu_pin s2_req_1_uop_psrc_2 {s2_req_q_reg[1]\[uop_psrc_2]} 8
lqu_pin s2_req_1_uop_psrc_3 {s2_req_q_reg[1]\[uop_psrc_3]} 8
lqu_pin s2_req_1_uop_psrc_4 {s2_req_q_reg[1]\[uop_psrc_4]} 8
lqu_pin s2_req_1_uop_pdest {s2_req_q_reg[1]\[uop_pdest]} 8
lqu_pin s2_req_1_uop_useRegCache_0 {s2_req_q_reg[1]\[uop_useRegCache_0]} 1
lqu_pin s2_req_1_uop_useRegCache_1 {s2_req_q_reg[1]\[uop_useRegCache_1]} 1
lqu_pin s2_req_1_uop_regCacheIdx_0 {s2_req_q_reg[1]\[uop_regCacheIdx_0]} 5
lqu_pin s2_req_1_uop_regCacheIdx_1 {s2_req_q_reg[1]\[uop_regCacheIdx_1]} 5
lqu_pin s2_req_1_uop_robIdx_flag {s2_req_q_reg[1]\[uop_robIdx_flag]} 1
lqu_pin s2_req_1_uop_robIdx_value {s2_req_q_reg[1]\[uop_robIdx_value]} 8
lqu_pin s2_req_1_uop_instrSize {s2_req_q_reg[1]\[uop_instrSize]} 3
lqu_pin s2_req_1_uop_dirtyFs {s2_req_q_reg[1]\[uop_dirtyFs]} 1
lqu_pin s2_req_1_uop_dirtyVs {s2_req_q_reg[1]\[uop_dirtyVs]} 1
lqu_pin s2_req_1_uop_traceBlockInPipe_itype {s2_req_q_reg[1]\[uop_traceBlockInPipe_itype]} 4
lqu_pin s2_req_1_uop_traceBlockInPipe_iretire {s2_req_q_reg[1]\[uop_traceBlockInPipe_iretire]} 4
lqu_pin s2_req_1_uop_traceBlockInPipe_ilastsize {s2_req_q_reg[1]\[uop_traceBlockInPipe_ilastsize]} 1
lqu_pin s2_req_1_uop_eliminatedMove {s2_req_q_reg[1]\[uop_eliminatedMove]} 1
lqu_pin s2_req_1_uop_snapshot {s2_req_q_reg[1]\[uop_snapshot]} 1
lqu_pin s2_req_1_uop_debugInfo_eliminatedMove {s2_req_q_reg[1]\[uop_debugInfo_eliminatedMove]} 1
lqu_pin s2_req_1_uop_debugInfo_renameTime {s2_req_q_reg[1]\[uop_debugInfo_renameTime]} 64
lqu_pin s2_req_1_uop_debugInfo_dispatchTime {s2_req_q_reg[1]\[uop_debugInfo_dispatchTime]} 64
lqu_pin s2_req_1_uop_debugInfo_enqRsTime {s2_req_q_reg[1]\[uop_debugInfo_enqRsTime]} 64
lqu_pin s2_req_1_uop_debugInfo_selectTime {s2_req_q_reg[1]\[uop_debugInfo_selectTime]} 64
lqu_pin s2_req_1_uop_debugInfo_issueTime {s2_req_q_reg[1]\[uop_debugInfo_issueTime]} 64
lqu_pin s2_req_1_uop_debugInfo_writebackTime {s2_req_q_reg[1]\[uop_debugInfo_writebackTime]} 64
lqu_pin s2_req_1_uop_debugInfo_runahead_checkpoint_id {s2_req_q_reg[1]\[uop_debugInfo_runahead_checkpoint_id]} 64
lqu_pin s2_req_1_uop_debugInfo_tlbFirstReqTime {s2_req_q_reg[1]\[uop_debugInfo_tlbFirstReqTime]} 64
lqu_pin s2_req_1_uop_debugInfo_tlbRespTime {s2_req_q_reg[1]\[uop_debugInfo_tlbRespTime]} 64
lqu_pin s2_req_1_uop_debug_seqNum_seqNum {s2_req_q_reg[1]\[uop_debug_seqNum_seqNum]} 56
lqu_pin s2_req_1_uop_debug_seqNum_uopIdx {s2_req_q_reg[1]\[uop_debug_seqNum_uopIdx]} 8
lqu_pin s2_req_1_uop_storeSetHit {s2_req_q_reg[1]\[uop_storeSetHit]} 1
lqu_pin s2_req_1_uop_waitForRobIdx_flag {s2_req_q_reg[1]\[uop_waitForRobIdx_flag]} 1
lqu_pin s2_req_1_uop_waitForRobIdx_value {s2_req_q_reg[1]\[uop_waitForRobIdx_value]} 8
lqu_pin s2_req_1_uop_loadWaitBit {s2_req_q_reg[1]\[uop_loadWaitBit]} 1
lqu_pin s2_req_1_uop_loadWaitStrict {s2_req_q_reg[1]\[uop_loadWaitStrict]} 1
lqu_pin s2_req_1_uop_ssid {s2_req_q_reg[1]\[uop_ssid]} 5
lqu_pin s2_req_1_uop_lqIdx_flag {s2_req_q_reg[1]\[uop_lqIdx_flag]} 1
lqu_pin s2_req_1_uop_lqIdx_value {s2_req_q_reg[1]\[uop_lqIdx_value]} 7
lqu_pin s2_req_1_uop_sqIdx_flag {s2_req_q_reg[1]\[uop_sqIdx_flag]} 1
lqu_pin s2_req_1_uop_sqIdx_value {s2_req_q_reg[1]\[uop_sqIdx_value]} 6
lqu_pin s2_req_1_uop_singleStep {s2_req_q_reg[1]\[uop_singleStep]} 1
lqu_pin s2_req_1_uop_debug_fuType {s2_req_q_reg[1]\[uop_debug_fuType]} 35
lqu_pin s2_req_1_uop_debug_sim_trig {s2_req_q_reg[1]\[uop_debug_sim_trig]} 1
lqu_pin s2_req_1_uop_numLsElem {s2_req_q_reg[1]\[uop_numLsElem]} 5
lqu_pin s2_req_1_vaddr {s2_req_q_reg[1]\[vaddr]} 50
lqu_pin s2_req_1_fullva {s2_req_q_reg[1]\[fullva]} 64
lqu_pin s2_req_1_paddr {s2_req_q_reg[1]\[paddr]} 48
lqu_pin s2_req_1_gpaddr {s2_req_q_reg[1]\[gpaddr]} 64
lqu_pin s2_req_1_mask {s2_req_q_reg[1]\[mask]} 16
lqu_pin s2_req_1_nc {s2_req_q_reg[1]\[nc]} 1
lqu_pin s2_req_1_mmio {s2_req_q_reg[1]\[mmio]} 1
lqu_pin s2_req_1_memBackTypeMM {s2_req_q_reg[1]\[memBackTypeMM]} 1
lqu_pin s2_req_1_isHyper {s2_req_q_reg[1]\[isHyper]} 1
lqu_pin s2_req_1_isForVSnonLeafPTE {s2_req_q_reg[1]\[isForVSnonLeafPTE]} 1
lqu_pin s2_req_1_isvec {s2_req_q_reg[1]\[isvec]} 1
lqu_pin s2_req_1_is128bit {s2_req_q_reg[1]\[is128bit]} 1
lqu_pin s2_req_1_vecActive {s2_req_q_reg[1]\[vecActive]} 1
lqu_pin s2_req_1_schedIndex {s2_req_q_reg[1]\[schedIndex]} 7
lqu_pin s2_req_1_rep_info_cause_0 {s2_req_q_reg[1]\[rep_info_cause_0]} 1
lqu_pin s2_req_1_rep_info_cause_1 {s2_req_q_reg[1]\[rep_info_cause_1]} 1
lqu_pin s2_req_1_rep_info_cause_2 {s2_req_q_reg[1]\[rep_info_cause_2]} 1
lqu_pin s2_req_1_rep_info_cause_3 {s2_req_q_reg[1]\[rep_info_cause_3]} 1
lqu_pin s2_req_1_rep_info_cause_4 {s2_req_q_reg[1]\[rep_info_cause_4]} 1
lqu_pin s2_req_1_rep_info_cause_5 {s2_req_q_reg[1]\[rep_info_cause_5]} 1
lqu_pin s2_req_1_rep_info_cause_6 {s2_req_q_reg[1]\[rep_info_cause_6]} 1
lqu_pin s2_req_1_rep_info_cause_7 {s2_req_q_reg[1]\[rep_info_cause_7]} 1
lqu_pin s2_req_1_rep_info_cause_8 {s2_req_q_reg[1]\[rep_info_cause_8]} 1
lqu_pin s2_req_1_rep_info_cause_9 {s2_req_q_reg[1]\[rep_info_cause_9]} 1
lqu_pin s2_req_1_rep_info_cause_10 {s2_req_q_reg[1]\[rep_info_cause_10]} 1
lqu_pin s2_req_2_uop_instr {s2_req_q_reg[2]\[uop_instr]} 32
lqu_pin s2_req_2_uop_pc {s2_req_q_reg[2]\[uop_pc]} 50
lqu_pin s2_req_2_uop_foldpc {s2_req_q_reg[2]\[uop_foldpc]} 10
lqu_pin s2_req_2_uop_exceptionVec_0 {s2_req_q_reg[2]\[uop_exceptionVec_0]} 1
lqu_pin s2_req_2_uop_exceptionVec_1 {s2_req_q_reg[2]\[uop_exceptionVec_1]} 1
lqu_pin s2_req_2_uop_exceptionVec_2 {s2_req_q_reg[2]\[uop_exceptionVec_2]} 1
lqu_pin s2_req_2_uop_exceptionVec_3 {s2_req_q_reg[2]\[uop_exceptionVec_3]} 1
lqu_pin s2_req_2_uop_exceptionVec_4 {s2_req_q_reg[2]\[uop_exceptionVec_4]} 1
lqu_pin s2_req_2_uop_exceptionVec_5 {s2_req_q_reg[2]\[uop_exceptionVec_5]} 1
lqu_pin s2_req_2_uop_exceptionVec_6 {s2_req_q_reg[2]\[uop_exceptionVec_6]} 1
lqu_pin s2_req_2_uop_exceptionVec_7 {s2_req_q_reg[2]\[uop_exceptionVec_7]} 1
lqu_pin s2_req_2_uop_exceptionVec_8 {s2_req_q_reg[2]\[uop_exceptionVec_8]} 1
lqu_pin s2_req_2_uop_exceptionVec_9 {s2_req_q_reg[2]\[uop_exceptionVec_9]} 1
lqu_pin s2_req_2_uop_exceptionVec_10 {s2_req_q_reg[2]\[uop_exceptionVec_10]} 1
lqu_pin s2_req_2_uop_exceptionVec_11 {s2_req_q_reg[2]\[uop_exceptionVec_11]} 1
lqu_pin s2_req_2_uop_exceptionVec_12 {s2_req_q_reg[2]\[uop_exceptionVec_12]} 1
lqu_pin s2_req_2_uop_exceptionVec_13 {s2_req_q_reg[2]\[uop_exceptionVec_13]} 1
lqu_pin s2_req_2_uop_exceptionVec_14 {s2_req_q_reg[2]\[uop_exceptionVec_14]} 1
lqu_pin s2_req_2_uop_exceptionVec_15 {s2_req_q_reg[2]\[uop_exceptionVec_15]} 1
lqu_pin s2_req_2_uop_exceptionVec_16 {s2_req_q_reg[2]\[uop_exceptionVec_16]} 1
lqu_pin s2_req_2_uop_exceptionVec_17 {s2_req_q_reg[2]\[uop_exceptionVec_17]} 1
lqu_pin s2_req_2_uop_exceptionVec_18 {s2_req_q_reg[2]\[uop_exceptionVec_18]} 1
lqu_pin s2_req_2_uop_exceptionVec_19 {s2_req_q_reg[2]\[uop_exceptionVec_19]} 1
lqu_pin s2_req_2_uop_exceptionVec_20 {s2_req_q_reg[2]\[uop_exceptionVec_20]} 1
lqu_pin s2_req_2_uop_exceptionVec_21 {s2_req_q_reg[2]\[uop_exceptionVec_21]} 1
lqu_pin s2_req_2_uop_exceptionVec_22 {s2_req_q_reg[2]\[uop_exceptionVec_22]} 1
lqu_pin s2_req_2_uop_exceptionVec_23 {s2_req_q_reg[2]\[uop_exceptionVec_23]} 1
lqu_pin s2_req_2_uop_isFetchMalAddr {s2_req_q_reg[2]\[uop_isFetchMalAddr]} 1
lqu_pin s2_req_2_uop_hasException {s2_req_q_reg[2]\[uop_hasException]} 1
lqu_pin s2_req_2_uop_trigger {s2_req_q_reg[2]\[uop_trigger]} 4
lqu_pin s2_req_2_uop_preDecodeInfo_valid {s2_req_q_reg[2]\[uop_preDecodeInfo_valid]} 1
lqu_pin s2_req_2_uop_preDecodeInfo_isRVC {s2_req_q_reg[2]\[uop_preDecodeInfo_isRVC]} 1
lqu_pin s2_req_2_uop_preDecodeInfo_brType {s2_req_q_reg[2]\[uop_preDecodeInfo_brType]} 2
lqu_pin s2_req_2_uop_preDecodeInfo_isCall {s2_req_q_reg[2]\[uop_preDecodeInfo_isCall]} 1
lqu_pin s2_req_2_uop_preDecodeInfo_isRet {s2_req_q_reg[2]\[uop_preDecodeInfo_isRet]} 1
lqu_pin s2_req_2_uop_pred_taken {s2_req_q_reg[2]\[uop_pred_taken]} 1
lqu_pin s2_req_2_uop_crossPageIPFFix {s2_req_q_reg[2]\[uop_crossPageIPFFix]} 1
lqu_pin s2_req_2_uop_ftqPtr_flag {s2_req_q_reg[2]\[uop_ftqPtr_flag]} 1
lqu_pin s2_req_2_uop_ftqPtr_value {s2_req_q_reg[2]\[uop_ftqPtr_value]} 6
lqu_pin s2_req_2_uop_ftqOffset {s2_req_q_reg[2]\[uop_ftqOffset]} 4
lqu_pin s2_req_2_uop_satpFlushFirstFetchFault {s2_req_q_reg[2]\[uop_satpFlushFirstFetchFault]} 1
lqu_pin s2_req_2_uop_srcType_0 {s2_req_q_reg[2]\[uop_srcType_0]} 4
lqu_pin s2_req_2_uop_srcType_1 {s2_req_q_reg[2]\[uop_srcType_1]} 4
lqu_pin s2_req_2_uop_srcType_2 {s2_req_q_reg[2]\[uop_srcType_2]} 4
lqu_pin s2_req_2_uop_srcType_3 {s2_req_q_reg[2]\[uop_srcType_3]} 4
lqu_pin s2_req_2_uop_srcType_4 {s2_req_q_reg[2]\[uop_srcType_4]} 4
lqu_pin s2_req_2_uop_ldest {s2_req_q_reg[2]\[uop_ldest]} 6
lqu_pin s2_req_2_uop_fuType {s2_req_q_reg[2]\[uop_fuType]} 35
lqu_pin s2_req_2_uop_fuOpType {s2_req_q_reg[2]\[uop_fuOpType]} 9
lqu_pin s2_req_2_uop_rfWen {s2_req_q_reg[2]\[uop_rfWen]} 1
lqu_pin s2_req_2_uop_fpWen {s2_req_q_reg[2]\[uop_fpWen]} 1
lqu_pin s2_req_2_uop_vecWen {s2_req_q_reg[2]\[uop_vecWen]} 1
lqu_pin s2_req_2_uop_v0Wen {s2_req_q_reg[2]\[uop_v0Wen]} 1
lqu_pin s2_req_2_uop_vlWen {s2_req_q_reg[2]\[uop_vlWen]} 1
lqu_pin s2_req_2_uop_isXSTrap {s2_req_q_reg[2]\[uop_isXSTrap]} 1
lqu_pin s2_req_2_uop_waitForward {s2_req_q_reg[2]\[uop_waitForward]} 1
lqu_pin s2_req_2_uop_blockBackward {s2_req_q_reg[2]\[uop_blockBackward]} 1
lqu_pin s2_req_2_uop_canRobCompress {s2_req_q_reg[2]\[uop_canRobCompress]} 1
lqu_pin s2_req_2_uop_selImm {s2_req_q_reg[2]\[uop_selImm]} 4
lqu_pin s2_req_2_uop_imm {s2_req_q_reg[2]\[uop_imm]} 32
lqu_pin s2_req_2_uop_fpu_typeTagOut {s2_req_q_reg[2]\[uop_fpu_typeTagOut]} 2
lqu_pin s2_req_2_uop_fpu_wflags {s2_req_q_reg[2]\[uop_fpu_wflags]} 1
lqu_pin s2_req_2_uop_fpu_typ {s2_req_q_reg[2]\[uop_fpu_typ]} 2
lqu_pin s2_req_2_uop_fpu_fmt {s2_req_q_reg[2]\[uop_fpu_fmt]} 2
lqu_pin s2_req_2_uop_fpu_rm {s2_req_q_reg[2]\[uop_fpu_rm]} 3
lqu_pin s2_req_2_uop_vpu_vill {s2_req_q_reg[2]\[uop_vpu_vill]} 1
lqu_pin s2_req_2_uop_vpu_vma {s2_req_q_reg[2]\[uop_vpu_vma]} 1
lqu_pin s2_req_2_uop_vpu_vta {s2_req_q_reg[2]\[uop_vpu_vta]} 1
lqu_pin s2_req_2_uop_vpu_vsew {s2_req_q_reg[2]\[uop_vpu_vsew]} 2
lqu_pin s2_req_2_uop_vpu_vlmul {s2_req_q_reg[2]\[uop_vpu_vlmul]} 3
lqu_pin s2_req_2_uop_vpu_specVill {s2_req_q_reg[2]\[uop_vpu_specVill]} 1
lqu_pin s2_req_2_uop_vpu_specVma {s2_req_q_reg[2]\[uop_vpu_specVma]} 1
lqu_pin s2_req_2_uop_vpu_specVta {s2_req_q_reg[2]\[uop_vpu_specVta]} 1
lqu_pin s2_req_2_uop_vpu_specVsew {s2_req_q_reg[2]\[uop_vpu_specVsew]} 2
lqu_pin s2_req_2_uop_vpu_specVlmul {s2_req_q_reg[2]\[uop_vpu_specVlmul]} 3
lqu_pin s2_req_2_uop_vpu_vm {s2_req_q_reg[2]\[uop_vpu_vm]} 1
lqu_pin s2_req_2_uop_vpu_vstart {s2_req_q_reg[2]\[uop_vpu_vstart]} 8
lqu_pin s2_req_2_uop_vpu_frm {s2_req_q_reg[2]\[uop_vpu_frm]} 3
lqu_pin s2_req_2_uop_vpu_fpu_isFpToVecInst {s2_req_q_reg[2]\[uop_vpu_fpu_isFpToVecInst]} 1
lqu_pin s2_req_2_uop_vpu_fpu_isFP32Instr {s2_req_q_reg[2]\[uop_vpu_fpu_isFP32Instr]} 1
lqu_pin s2_req_2_uop_vpu_fpu_isFP64Instr {s2_req_q_reg[2]\[uop_vpu_fpu_isFP64Instr]} 1
lqu_pin s2_req_2_uop_vpu_fpu_isReduction {s2_req_q_reg[2]\[uop_vpu_fpu_isReduction]} 1
lqu_pin s2_req_2_uop_vpu_fpu_isFoldTo1_2 {s2_req_q_reg[2]\[uop_vpu_fpu_isFoldTo1_2]} 1
lqu_pin s2_req_2_uop_vpu_fpu_isFoldTo1_4 {s2_req_q_reg[2]\[uop_vpu_fpu_isFoldTo1_4]} 1
lqu_pin s2_req_2_uop_vpu_fpu_isFoldTo1_8 {s2_req_q_reg[2]\[uop_vpu_fpu_isFoldTo1_8]} 1
lqu_pin s2_req_2_uop_vpu_vxrm {s2_req_q_reg[2]\[uop_vpu_vxrm]} 2
lqu_pin s2_req_2_uop_vpu_vuopIdx {s2_req_q_reg[2]\[uop_vpu_vuopIdx]} 7
lqu_pin s2_req_2_uop_vpu_lastUop {s2_req_q_reg[2]\[uop_vpu_lastUop]} 1
lqu_pin s2_req_2_uop_vpu_vmask {s2_req_q_reg[2]\[uop_vpu_vmask]} 128
lqu_pin s2_req_2_uop_vpu_vl {s2_req_q_reg[2]\[uop_vpu_vl]} 8
lqu_pin s2_req_2_uop_vpu_nf {s2_req_q_reg[2]\[uop_vpu_nf]} 3
lqu_pin s2_req_2_uop_vpu_veew {s2_req_q_reg[2]\[uop_vpu_veew]} 2
lqu_pin s2_req_2_uop_vpu_isReverse {s2_req_q_reg[2]\[uop_vpu_isReverse]} 1
lqu_pin s2_req_2_uop_vpu_isExt {s2_req_q_reg[2]\[uop_vpu_isExt]} 1
lqu_pin s2_req_2_uop_vpu_isNarrow {s2_req_q_reg[2]\[uop_vpu_isNarrow]} 1
lqu_pin s2_req_2_uop_vpu_isDstMask {s2_req_q_reg[2]\[uop_vpu_isDstMask]} 1
lqu_pin s2_req_2_uop_vpu_isOpMask {s2_req_q_reg[2]\[uop_vpu_isOpMask]} 1
lqu_pin s2_req_2_uop_vpu_isMove {s2_req_q_reg[2]\[uop_vpu_isMove]} 1
lqu_pin s2_req_2_uop_vpu_isDependOldVd {s2_req_q_reg[2]\[uop_vpu_isDependOldVd]} 1
lqu_pin s2_req_2_uop_vpu_isWritePartVd {s2_req_q_reg[2]\[uop_vpu_isWritePartVd]} 1
lqu_pin s2_req_2_uop_vpu_isVleff {s2_req_q_reg[2]\[uop_vpu_isVleff]} 1
lqu_pin s2_req_2_uop_vlsInstr {s2_req_q_reg[2]\[uop_vlsInstr]} 1
lqu_pin s2_req_2_uop_wfflags {s2_req_q_reg[2]\[uop_wfflags]} 1
lqu_pin s2_req_2_uop_isMove {s2_req_q_reg[2]\[uop_isMove]} 1
lqu_pin s2_req_2_uop_isDropAmocasSta {s2_req_q_reg[2]\[uop_isDropAmocasSta]} 1
lqu_pin s2_req_2_uop_uopIdx {s2_req_q_reg[2]\[uop_uopIdx]} 7
lqu_pin s2_req_2_uop_isVset {s2_req_q_reg[2]\[uop_isVset]} 1
lqu_pin s2_req_2_uop_firstUop {s2_req_q_reg[2]\[uop_firstUop]} 1
lqu_pin s2_req_2_uop_lastUop {s2_req_q_reg[2]\[uop_lastUop]} 1
lqu_pin s2_req_2_uop_numUops {s2_req_q_reg[2]\[uop_numUops]} 7
lqu_pin s2_req_2_uop_numWB {s2_req_q_reg[2]\[uop_numWB]} 7
lqu_pin s2_req_2_uop_commitType {s2_req_q_reg[2]\[uop_commitType]} 3
lqu_pin s2_req_2_uop_srcState_0 {s2_req_q_reg[2]\[uop_srcState_0]} 1
lqu_pin s2_req_2_uop_srcState_1 {s2_req_q_reg[2]\[uop_srcState_1]} 1
lqu_pin s2_req_2_uop_srcState_2 {s2_req_q_reg[2]\[uop_srcState_2]} 1
lqu_pin s2_req_2_uop_srcState_3 {s2_req_q_reg[2]\[uop_srcState_3]} 1
lqu_pin s2_req_2_uop_srcState_4 {s2_req_q_reg[2]\[uop_srcState_4]} 1
lqu_pin s2_req_2_uop_srcLoadDependency_0_0 {s2_req_q_reg[2]\[uop_srcLoadDependency_0_0]} 2
lqu_pin s2_req_2_uop_srcLoadDependency_0_1 {s2_req_q_reg[2]\[uop_srcLoadDependency_0_1]} 2
lqu_pin s2_req_2_uop_srcLoadDependency_0_2 {s2_req_q_reg[2]\[uop_srcLoadDependency_0_2]} 2
lqu_pin s2_req_2_uop_srcLoadDependency_1_0 {s2_req_q_reg[2]\[uop_srcLoadDependency_1_0]} 2
lqu_pin s2_req_2_uop_srcLoadDependency_1_1 {s2_req_q_reg[2]\[uop_srcLoadDependency_1_1]} 2
lqu_pin s2_req_2_uop_srcLoadDependency_1_2 {s2_req_q_reg[2]\[uop_srcLoadDependency_1_2]} 2
lqu_pin s2_req_2_uop_srcLoadDependency_2_0 {s2_req_q_reg[2]\[uop_srcLoadDependency_2_0]} 2
lqu_pin s2_req_2_uop_srcLoadDependency_2_1 {s2_req_q_reg[2]\[uop_srcLoadDependency_2_1]} 2
lqu_pin s2_req_2_uop_srcLoadDependency_2_2 {s2_req_q_reg[2]\[uop_srcLoadDependency_2_2]} 2
lqu_pin s2_req_2_uop_srcLoadDependency_3_0 {s2_req_q_reg[2]\[uop_srcLoadDependency_3_0]} 2
lqu_pin s2_req_2_uop_srcLoadDependency_3_1 {s2_req_q_reg[2]\[uop_srcLoadDependency_3_1]} 2
lqu_pin s2_req_2_uop_srcLoadDependency_3_2 {s2_req_q_reg[2]\[uop_srcLoadDependency_3_2]} 2
lqu_pin s2_req_2_uop_srcLoadDependency_4_0 {s2_req_q_reg[2]\[uop_srcLoadDependency_4_0]} 2
lqu_pin s2_req_2_uop_srcLoadDependency_4_1 {s2_req_q_reg[2]\[uop_srcLoadDependency_4_1]} 2
lqu_pin s2_req_2_uop_srcLoadDependency_4_2 {s2_req_q_reg[2]\[uop_srcLoadDependency_4_2]} 2
lqu_pin s2_req_2_uop_psrc_0 {s2_req_q_reg[2]\[uop_psrc_0]} 8
lqu_pin s2_req_2_uop_psrc_1 {s2_req_q_reg[2]\[uop_psrc_1]} 8
lqu_pin s2_req_2_uop_psrc_2 {s2_req_q_reg[2]\[uop_psrc_2]} 8
lqu_pin s2_req_2_uop_psrc_3 {s2_req_q_reg[2]\[uop_psrc_3]} 8
lqu_pin s2_req_2_uop_psrc_4 {s2_req_q_reg[2]\[uop_psrc_4]} 8
lqu_pin s2_req_2_uop_pdest {s2_req_q_reg[2]\[uop_pdest]} 8
lqu_pin s2_req_2_uop_useRegCache_0 {s2_req_q_reg[2]\[uop_useRegCache_0]} 1
lqu_pin s2_req_2_uop_useRegCache_1 {s2_req_q_reg[2]\[uop_useRegCache_1]} 1
lqu_pin s2_req_2_uop_regCacheIdx_0 {s2_req_q_reg[2]\[uop_regCacheIdx_0]} 5
lqu_pin s2_req_2_uop_regCacheIdx_1 {s2_req_q_reg[2]\[uop_regCacheIdx_1]} 5
lqu_pin s2_req_2_uop_robIdx_flag {s2_req_q_reg[2]\[uop_robIdx_flag]} 1
lqu_pin s2_req_2_uop_robIdx_value {s2_req_q_reg[2]\[uop_robIdx_value]} 8
lqu_pin s2_req_2_uop_instrSize {s2_req_q_reg[2]\[uop_instrSize]} 3
lqu_pin s2_req_2_uop_dirtyFs {s2_req_q_reg[2]\[uop_dirtyFs]} 1
lqu_pin s2_req_2_uop_dirtyVs {s2_req_q_reg[2]\[uop_dirtyVs]} 1
lqu_pin s2_req_2_uop_traceBlockInPipe_itype {s2_req_q_reg[2]\[uop_traceBlockInPipe_itype]} 4
lqu_pin s2_req_2_uop_traceBlockInPipe_iretire {s2_req_q_reg[2]\[uop_traceBlockInPipe_iretire]} 4
lqu_pin s2_req_2_uop_traceBlockInPipe_ilastsize {s2_req_q_reg[2]\[uop_traceBlockInPipe_ilastsize]} 1
lqu_pin s2_req_2_uop_eliminatedMove {s2_req_q_reg[2]\[uop_eliminatedMove]} 1
lqu_pin s2_req_2_uop_snapshot {s2_req_q_reg[2]\[uop_snapshot]} 1
lqu_pin s2_req_2_uop_debugInfo_eliminatedMove {s2_req_q_reg[2]\[uop_debugInfo_eliminatedMove]} 1
lqu_pin s2_req_2_uop_debugInfo_renameTime {s2_req_q_reg[2]\[uop_debugInfo_renameTime]} 64
lqu_pin s2_req_2_uop_debugInfo_dispatchTime {s2_req_q_reg[2]\[uop_debugInfo_dispatchTime]} 64
lqu_pin s2_req_2_uop_debugInfo_enqRsTime {s2_req_q_reg[2]\[uop_debugInfo_enqRsTime]} 64
lqu_pin s2_req_2_uop_debugInfo_selectTime {s2_req_q_reg[2]\[uop_debugInfo_selectTime]} 64
lqu_pin s2_req_2_uop_debugInfo_issueTime {s2_req_q_reg[2]\[uop_debugInfo_issueTime]} 64
lqu_pin s2_req_2_uop_debugInfo_writebackTime {s2_req_q_reg[2]\[uop_debugInfo_writebackTime]} 64
lqu_pin s2_req_2_uop_debugInfo_runahead_checkpoint_id {s2_req_q_reg[2]\[uop_debugInfo_runahead_checkpoint_id]} 64
lqu_pin s2_req_2_uop_debugInfo_tlbFirstReqTime {s2_req_q_reg[2]\[uop_debugInfo_tlbFirstReqTime]} 64
lqu_pin s2_req_2_uop_debugInfo_tlbRespTime {s2_req_q_reg[2]\[uop_debugInfo_tlbRespTime]} 64
lqu_pin s2_req_2_uop_debug_seqNum_seqNum {s2_req_q_reg[2]\[uop_debug_seqNum_seqNum]} 56
lqu_pin s2_req_2_uop_debug_seqNum_uopIdx {s2_req_q_reg[2]\[uop_debug_seqNum_uopIdx]} 8
lqu_pin s2_req_2_uop_storeSetHit {s2_req_q_reg[2]\[uop_storeSetHit]} 1
lqu_pin s2_req_2_uop_waitForRobIdx_flag {s2_req_q_reg[2]\[uop_waitForRobIdx_flag]} 1
lqu_pin s2_req_2_uop_waitForRobIdx_value {s2_req_q_reg[2]\[uop_waitForRobIdx_value]} 8
lqu_pin s2_req_2_uop_loadWaitBit {s2_req_q_reg[2]\[uop_loadWaitBit]} 1
lqu_pin s2_req_2_uop_loadWaitStrict {s2_req_q_reg[2]\[uop_loadWaitStrict]} 1
lqu_pin s2_req_2_uop_ssid {s2_req_q_reg[2]\[uop_ssid]} 5
lqu_pin s2_req_2_uop_lqIdx_flag {s2_req_q_reg[2]\[uop_lqIdx_flag]} 1
lqu_pin s2_req_2_uop_lqIdx_value {s2_req_q_reg[2]\[uop_lqIdx_value]} 7
lqu_pin s2_req_2_uop_sqIdx_flag {s2_req_q_reg[2]\[uop_sqIdx_flag]} 1
lqu_pin s2_req_2_uop_sqIdx_value {s2_req_q_reg[2]\[uop_sqIdx_value]} 6
lqu_pin s2_req_2_uop_singleStep {s2_req_q_reg[2]\[uop_singleStep]} 1
lqu_pin s2_req_2_uop_debug_fuType {s2_req_q_reg[2]\[uop_debug_fuType]} 35
lqu_pin s2_req_2_uop_debug_sim_trig {s2_req_q_reg[2]\[uop_debug_sim_trig]} 1
lqu_pin s2_req_2_uop_numLsElem {s2_req_q_reg[2]\[uop_numLsElem]} 5
lqu_pin s2_req_2_vaddr {s2_req_q_reg[2]\[vaddr]} 50
lqu_pin s2_req_2_fullva {s2_req_q_reg[2]\[fullva]} 64
lqu_pin s2_req_2_paddr {s2_req_q_reg[2]\[paddr]} 48
lqu_pin s2_req_2_gpaddr {s2_req_q_reg[2]\[gpaddr]} 64
lqu_pin s2_req_2_mask {s2_req_q_reg[2]\[mask]} 16
lqu_pin s2_req_2_nc {s2_req_q_reg[2]\[nc]} 1
lqu_pin s2_req_2_mmio {s2_req_q_reg[2]\[mmio]} 1
lqu_pin s2_req_2_memBackTypeMM {s2_req_q_reg[2]\[memBackTypeMM]} 1
lqu_pin s2_req_2_isHyper {s2_req_q_reg[2]\[isHyper]} 1
lqu_pin s2_req_2_isForVSnonLeafPTE {s2_req_q_reg[2]\[isForVSnonLeafPTE]} 1
lqu_pin s2_req_2_isvec {s2_req_q_reg[2]\[isvec]} 1
lqu_pin s2_req_2_is128bit {s2_req_q_reg[2]\[is128bit]} 1
lqu_pin s2_req_2_vecActive {s2_req_q_reg[2]\[vecActive]} 1
lqu_pin s2_req_2_schedIndex {s2_req_q_reg[2]\[schedIndex]} 7
lqu_pin s2_req_2_rep_info_cause_0 {s2_req_q_reg[2]\[rep_info_cause_0]} 1
lqu_pin s2_req_2_rep_info_cause_1 {s2_req_q_reg[2]\[rep_info_cause_1]} 1
lqu_pin s2_req_2_rep_info_cause_2 {s2_req_q_reg[2]\[rep_info_cause_2]} 1
lqu_pin s2_req_2_rep_info_cause_3 {s2_req_q_reg[2]\[rep_info_cause_3]} 1
lqu_pin s2_req_2_rep_info_cause_4 {s2_req_q_reg[2]\[rep_info_cause_4]} 1
lqu_pin s2_req_2_rep_info_cause_5 {s2_req_q_reg[2]\[rep_info_cause_5]} 1
lqu_pin s2_req_2_rep_info_cause_6 {s2_req_q_reg[2]\[rep_info_cause_6]} 1
lqu_pin s2_req_2_rep_info_cause_7 {s2_req_q_reg[2]\[rep_info_cause_7]} 1
lqu_pin s2_req_2_rep_info_cause_8 {s2_req_q_reg[2]\[rep_info_cause_8]} 1
lqu_pin s2_req_2_rep_info_cause_9 {s2_req_q_reg[2]\[rep_info_cause_9]} 1
lqu_pin s2_req_2_rep_info_cause_10 {s2_req_q_reg[2]\[rep_info_cause_10]} 1
lqu_pin s2_valid_REG {s2_valid_q_reg[0]} 1
lqu_pin s2_valid_REG_1_valid {s2_redirect_q_reg[0]\[valid]} 1
lqu_pin s2_valid_REG_1_bits_robIdx_flag {s2_redirect_q_reg[0]\[robIdx_flag]} 1
lqu_pin s2_valid_REG_1_bits_robIdx_value {s2_redirect_q_reg[0]\[robIdx_value]} 8
lqu_pin s2_valid_REG_1_bits_level {s2_redirect_q_reg[0]\[level]} 1
lqu_pin s2_valid_REG_2 {s2_valid_q_reg[1]} 1
lqu_pin s2_valid_REG_3_valid {s2_redirect_q_reg[1]\[valid]} 1
lqu_pin s2_valid_REG_3_bits_robIdx_flag {s2_redirect_q_reg[1]\[robIdx_flag]} 1
lqu_pin s2_valid_REG_3_bits_robIdx_value {s2_redirect_q_reg[1]\[robIdx_value]} 8
lqu_pin s2_valid_REG_3_bits_level {s2_redirect_q_reg[1]\[level]} 1
lqu_pin s2_valid_REG_4 {s2_valid_q_reg[2]} 1
lqu_pin s2_valid_REG_5_valid {s2_redirect_q_reg[2]\[valid]} 1
lqu_pin s2_valid_REG_5_bits_robIdx_flag {s2_redirect_q_reg[2]\[robIdx_flag]} 1
lqu_pin s2_valid_REG_5_bits_robIdx_value {s2_redirect_q_reg[2]\[robIdx_value]} 8
lqu_pin s2_valid_REG_5_bits_level {s2_redirect_q_reg[2]\[level]} 1
lqu_pin io_mmioRawData_2_r_lqData {mmio_raw_q_reg\[lqData]} 64
lqu_pin io_mmioRawData_2_r_uop_fuOpType {mmio_raw_q_reg\[uop_fuOpType]} 9
lqu_pin io_mmioRawData_2_r_uop_fpWen {mmio_raw_q_reg\[uop_fpWen]} 1
lqu_pin io_mmioRawData_2_r_addrOffset {mmio_raw_q_reg\[addrOffset]} 3
lqu_pin io_rob_loadMmio_0_REG {rob_load_mmio_q_reg[0]} 1
lqu_pin io_rob_loadMmioUop_0_r_robIdx_value {rob_load_mmio_rob_q_reg[0]} 8
lqu_pin io_rob_loadMmio_1_REG {rob_load_mmio_q_reg[1]} 1
lqu_pin io_rob_loadMmioUop_1_r_robIdx_value {rob_load_mmio_rob_q_reg[1]} 8
lqu_pin io_rob_loadMmio_2_REG {rob_load_mmio_q_reg[2]} 1
lqu_pin io_rob_loadMmioUop_2_r_robIdx_value {rob_load_mmio_rob_q_reg[2]} 8
lqu_pin lastCycleRedirect_valid_REG {last_redirect_q_reg\[valid]} 1
lqu_pin lastCycleRedirect_bits_r_robIdx_flag {last_redirect_q_reg\[robIdx_flag]} 1
lqu_pin lastCycleRedirect_bits_r_robIdx_value {last_redirect_q_reg\[robIdx_value]} 8
lqu_pin lastCycleRedirect_bits_r_level {last_redirect_q_reg\[level]} 1
lqu_pin lastLastCycleRedirect_valid_REG {last2_redirect_q_reg\[valid]} 1
lqu_pin lastLastCycleRedirect_bits_r_robIdx_flag {last2_redirect_q_reg\[robIdx_flag]} 1
lqu_pin lastLastCycleRedirect_bits_r_robIdx_value {last2_redirect_q_reg\[robIdx_value]} 8
lqu_pin lastLastCycleRedirect_bits_r_level {last2_redirect_q_reg\[level]} 1
lqu_pin io_rollback_valid_last_REG {rollback_valid_q_reg} 1
lqu_pin io_rollback_bits_r_isRVC {rollback_q_reg\[isRVC]} 1
lqu_pin io_rollback_bits_r_robIdx_flag {rollback_q_reg\[robIdx_flag]} 1
lqu_pin io_rollback_bits_r_robIdx_value {rollback_q_reg\[robIdx_value]} 8
lqu_pin io_rollback_bits_r_ftqIdx_flag {rollback_q_reg\[ftqIdx_flag]} 1
lqu_pin io_rollback_bits_r_ftqIdx_value {rollback_q_reg\[ftqIdx_value]} 6
lqu_pin io_rollback_bits_r_ftqOffset {rollback_q_reg\[ftqOffset]} 4
lqu_pin io_rollback_bits_r_level {rollback_q_reg\[level]} 1
lqu_pin io_rollback_bits_r_debug_runahead_checkpoint_id {rollback_q_reg\[debug_runahead_checkpoint_id]} 64
lqu_pin1 r:/WORK/LoadQueueUncache/pipelineReg/pipeline_reg_valid_reg i:/WORK/LoadQueueUncache/u_core/pipelineReg/u_core/valid_q_reg
lqu_pipe pipelineReg robIdx_flag 1 192
lqu_pipe pipelineReg robIdx_value 8 184
lqu_pipe pipelineReg cmd 5 179
lqu_pipe pipelineReg addr 48 131
lqu_pipe pipelineReg vaddr 50 81
lqu_pipe pipelineReg data 64 17
lqu_pipe pipelineReg mask 8 9
lqu_pipe pipelineReg id 7 2
lqu_pipe pipelineReg nc 1 1
lqu_pipe pipelineReg memBackTypeMM 1 0
lqu_pin1 r:/WORK/LoadQueueUncache/pipelineReg_1/pipeline_reg_valid_reg i:/WORK/LoadQueueUncache/u_core/pipelineReg_1/u_core/valid_q_reg
lqu_pipe pipelineReg_1 uop_instr 32 1396
lqu_pipe pipelineReg_1 uop_pc 50 1346
lqu_pipe pipelineReg_1 uop_foldpc 10 1336
lqu_pipe pipelineReg_1 uop_exceptionVec_0 1 1335
lqu_pipe pipelineReg_1 uop_exceptionVec_1 1 1334
lqu_pipe pipelineReg_1 uop_exceptionVec_2 1 1333
lqu_pipe pipelineReg_1 uop_exceptionVec_3 1 1332
lqu_pipe pipelineReg_1 uop_exceptionVec_4 1 1331
lqu_pipe pipelineReg_1 uop_exceptionVec_5 1 1330
lqu_pipe pipelineReg_1 uop_exceptionVec_6 1 1329
lqu_pipe pipelineReg_1 uop_exceptionVec_7 1 1328
lqu_pipe pipelineReg_1 uop_exceptionVec_8 1 1327
lqu_pipe pipelineReg_1 uop_exceptionVec_9 1 1326
lqu_pipe pipelineReg_1 uop_exceptionVec_10 1 1325
lqu_pipe pipelineReg_1 uop_exceptionVec_11 1 1324
lqu_pipe pipelineReg_1 uop_exceptionVec_12 1 1323
lqu_pipe pipelineReg_1 uop_exceptionVec_13 1 1322
lqu_pipe pipelineReg_1 uop_exceptionVec_14 1 1321
lqu_pipe pipelineReg_1 uop_exceptionVec_15 1 1320
lqu_pipe pipelineReg_1 uop_exceptionVec_16 1 1319
lqu_pipe pipelineReg_1 uop_exceptionVec_17 1 1318
lqu_pipe pipelineReg_1 uop_exceptionVec_18 1 1317
lqu_pipe pipelineReg_1 uop_exceptionVec_19 1 1316
lqu_pipe pipelineReg_1 uop_exceptionVec_20 1 1315
lqu_pipe pipelineReg_1 uop_exceptionVec_21 1 1314
lqu_pipe pipelineReg_1 uop_exceptionVec_22 1 1313
lqu_pipe pipelineReg_1 uop_exceptionVec_23 1 1312
lqu_pipe pipelineReg_1 uop_isFetchMalAddr 1 1311
lqu_pipe pipelineReg_1 uop_hasException 1 1310
lqu_pipe pipelineReg_1 uop_trigger 4 1306
lqu_pipe pipelineReg_1 uop_preDecodeInfo_valid 1 1305
lqu_pipe pipelineReg_1 uop_preDecodeInfo_isRVC 1 1304
lqu_pipe pipelineReg_1 uop_preDecodeInfo_brType 2 1302
lqu_pipe pipelineReg_1 uop_preDecodeInfo_isCall 1 1301
lqu_pipe pipelineReg_1 uop_preDecodeInfo_isRet 1 1300
lqu_pipe pipelineReg_1 uop_pred_taken 1 1299
lqu_pipe pipelineReg_1 uop_crossPageIPFFix 1 1298
lqu_pipe pipelineReg_1 uop_ftqPtr_flag 1 1297
lqu_pipe pipelineReg_1 uop_ftqPtr_value 6 1291
lqu_pipe pipelineReg_1 uop_ftqOffset 4 1287
lqu_pipe pipelineReg_1 uop_satpFlushFirstFetchFault 1 1286
lqu_pipe pipelineReg_1 uop_srcType_0 4 1282
lqu_pipe pipelineReg_1 uop_srcType_1 4 1278
lqu_pipe pipelineReg_1 uop_srcType_2 4 1274
lqu_pipe pipelineReg_1 uop_srcType_3 4 1270
lqu_pipe pipelineReg_1 uop_srcType_4 4 1266
lqu_pipe pipelineReg_1 uop_ldest 6 1260
lqu_pipe pipelineReg_1 uop_fuType 35 1225
lqu_pipe pipelineReg_1 uop_fuOpType 9 1216
lqu_pipe pipelineReg_1 uop_rfWen 1 1215
lqu_pipe pipelineReg_1 uop_fpWen 1 1214
lqu_pipe pipelineReg_1 uop_vecWen 1 1213
lqu_pipe pipelineReg_1 uop_v0Wen 1 1212
lqu_pipe pipelineReg_1 uop_vlWen 1 1211
lqu_pipe pipelineReg_1 uop_isXSTrap 1 1210
lqu_pipe pipelineReg_1 uop_waitForward 1 1209
lqu_pipe pipelineReg_1 uop_blockBackward 1 1208
lqu_pipe pipelineReg_1 uop_flushPipe 1 1207
lqu_pipe pipelineReg_1 uop_canRobCompress 1 1206
lqu_pipe pipelineReg_1 uop_selImm 4 1202
lqu_pipe pipelineReg_1 uop_imm 32 1170
lqu_pipe pipelineReg_1 uop_fpu_typeTagOut 2 1168
lqu_pipe pipelineReg_1 uop_fpu_wflags 1 1167
lqu_pipe pipelineReg_1 uop_fpu_typ 2 1165
lqu_pipe pipelineReg_1 uop_fpu_fmt 2 1163
lqu_pipe pipelineReg_1 uop_fpu_rm 3 1160
lqu_pipe pipelineReg_1 uop_vpu_vill 1 1159
lqu_pipe pipelineReg_1 uop_vpu_vma 1 1158
lqu_pipe pipelineReg_1 uop_vpu_vta 1 1157
lqu_pipe pipelineReg_1 uop_vpu_vsew 2 1155
lqu_pipe pipelineReg_1 uop_vpu_vlmul 3 1152
lqu_pipe pipelineReg_1 uop_vpu_specVill 1 1151
lqu_pipe pipelineReg_1 uop_vpu_specVma 1 1150
lqu_pipe pipelineReg_1 uop_vpu_specVta 1 1149
lqu_pipe pipelineReg_1 uop_vpu_specVsew 2 1147
lqu_pipe pipelineReg_1 uop_vpu_specVlmul 3 1144
lqu_pipe pipelineReg_1 uop_vpu_vm 1 1143
lqu_pipe pipelineReg_1 uop_vpu_vstart 8 1135
lqu_pipe pipelineReg_1 uop_vpu_frm 3 1132
lqu_pipe pipelineReg_1 uop_vpu_fpu_isFpToVecInst 1 1131
lqu_pipe pipelineReg_1 uop_vpu_fpu_isFP32Instr 1 1130
lqu_pipe pipelineReg_1 uop_vpu_fpu_isFP64Instr 1 1129
lqu_pipe pipelineReg_1 uop_vpu_fpu_isReduction 1 1128
lqu_pipe pipelineReg_1 uop_vpu_fpu_isFoldTo1_2 1 1127
lqu_pipe pipelineReg_1 uop_vpu_fpu_isFoldTo1_4 1 1126
lqu_pipe pipelineReg_1 uop_vpu_fpu_isFoldTo1_8 1 1125
lqu_pipe pipelineReg_1 uop_vpu_vxrm 2 1123
lqu_pipe pipelineReg_1 uop_vpu_vuopIdx 7 1116
lqu_pipe pipelineReg_1 uop_vpu_lastUop 1 1115
lqu_pipe pipelineReg_1 uop_vpu_vmask 128 987
lqu_pipe pipelineReg_1 uop_vpu_vl 8 979
lqu_pipe pipelineReg_1 uop_vpu_nf 3 976
lqu_pipe pipelineReg_1 uop_vpu_veew 2 974
lqu_pipe pipelineReg_1 uop_vpu_isReverse 1 973
lqu_pipe pipelineReg_1 uop_vpu_isExt 1 972
lqu_pipe pipelineReg_1 uop_vpu_isNarrow 1 971
lqu_pipe pipelineReg_1 uop_vpu_isDstMask 1 970
lqu_pipe pipelineReg_1 uop_vpu_isOpMask 1 969
lqu_pipe pipelineReg_1 uop_vpu_isMove 1 968
lqu_pipe pipelineReg_1 uop_vpu_isDependOldVd 1 967
lqu_pipe pipelineReg_1 uop_vpu_isWritePartVd 1 966
lqu_pipe pipelineReg_1 uop_vpu_isVleff 1 965
lqu_pipe pipelineReg_1 uop_vlsInstr 1 964
lqu_pipe pipelineReg_1 uop_wfflags 1 963
lqu_pipe pipelineReg_1 uop_isMove 1 962
lqu_pipe pipelineReg_1 uop_isDropAmocasSta 1 961
lqu_pipe pipelineReg_1 uop_uopIdx 7 954
lqu_pipe pipelineReg_1 uop_isVset 1 953
lqu_pipe pipelineReg_1 uop_firstUop 1 952
lqu_pipe pipelineReg_1 uop_lastUop 1 951
lqu_pipe pipelineReg_1 uop_numUops 7 944
lqu_pipe pipelineReg_1 uop_numWB 7 937
lqu_pipe pipelineReg_1 uop_commitType 3 934
lqu_pipe pipelineReg_1 uop_srcState_0 1 933
lqu_pipe pipelineReg_1 uop_srcState_1 1 932
lqu_pipe pipelineReg_1 uop_srcState_2 1 931
lqu_pipe pipelineReg_1 uop_srcState_3 1 930
lqu_pipe pipelineReg_1 uop_srcState_4 1 929
lqu_pipe pipelineReg_1 uop_srcLoadDependency_0_0 2 927
lqu_pipe pipelineReg_1 uop_srcLoadDependency_0_1 2 925
lqu_pipe pipelineReg_1 uop_srcLoadDependency_0_2 2 923
lqu_pipe pipelineReg_1 uop_srcLoadDependency_1_0 2 921
lqu_pipe pipelineReg_1 uop_srcLoadDependency_1_1 2 919
lqu_pipe pipelineReg_1 uop_srcLoadDependency_1_2 2 917
lqu_pipe pipelineReg_1 uop_srcLoadDependency_2_0 2 915
lqu_pipe pipelineReg_1 uop_srcLoadDependency_2_1 2 913
lqu_pipe pipelineReg_1 uop_srcLoadDependency_2_2 2 911
lqu_pipe pipelineReg_1 uop_srcLoadDependency_3_0 2 909
lqu_pipe pipelineReg_1 uop_srcLoadDependency_3_1 2 907
lqu_pipe pipelineReg_1 uop_srcLoadDependency_3_2 2 905
lqu_pipe pipelineReg_1 uop_srcLoadDependency_4_0 2 903
lqu_pipe pipelineReg_1 uop_srcLoadDependency_4_1 2 901
lqu_pipe pipelineReg_1 uop_srcLoadDependency_4_2 2 899
lqu_pipe pipelineReg_1 uop_psrc_0 8 891
lqu_pipe pipelineReg_1 uop_psrc_1 8 883
lqu_pipe pipelineReg_1 uop_psrc_2 8 875
lqu_pipe pipelineReg_1 uop_psrc_3 8 867
lqu_pipe pipelineReg_1 uop_psrc_4 8 859
lqu_pipe pipelineReg_1 uop_pdest 8 851
lqu_pipe pipelineReg_1 uop_useRegCache_0 1 850
lqu_pipe pipelineReg_1 uop_useRegCache_1 1 849
lqu_pipe pipelineReg_1 uop_regCacheIdx_0 5 844
lqu_pipe pipelineReg_1 uop_regCacheIdx_1 5 839
lqu_pipe pipelineReg_1 uop_robIdx_flag 1 838
lqu_pipe pipelineReg_1 uop_robIdx_value 8 830
lqu_pipe pipelineReg_1 uop_instrSize 3 827
lqu_pipe pipelineReg_1 uop_dirtyFs 1 826
lqu_pipe pipelineReg_1 uop_dirtyVs 1 825
lqu_pipe pipelineReg_1 uop_traceBlockInPipe_itype 4 821
lqu_pipe pipelineReg_1 uop_traceBlockInPipe_iretire 4 817
lqu_pipe pipelineReg_1 uop_traceBlockInPipe_ilastsize 1 816
lqu_pipe pipelineReg_1 uop_eliminatedMove 1 815
lqu_pipe pipelineReg_1 uop_snapshot 1 814
lqu_pipe pipelineReg_1 uop_debugInfo_eliminatedMove 1 813
lqu_pipe pipelineReg_1 uop_debugInfo_renameTime 64 749
lqu_pipe pipelineReg_1 uop_debugInfo_dispatchTime 64 685
lqu_pipe pipelineReg_1 uop_debugInfo_enqRsTime 64 621
lqu_pipe pipelineReg_1 uop_debugInfo_selectTime 64 557
lqu_pipe pipelineReg_1 uop_debugInfo_issueTime 64 493
lqu_pipe pipelineReg_1 uop_debugInfo_writebackTime 64 429
lqu_pipe pipelineReg_1 uop_debugInfo_runahead_checkpoint_id 64 365
lqu_pipe pipelineReg_1 uop_debugInfo_tlbFirstReqTime 64 301
lqu_pipe pipelineReg_1 uop_debugInfo_tlbRespTime 64 237
lqu_pipe pipelineReg_1 uop_debug_seqNum_seqNum 56 181
lqu_pipe pipelineReg_1 uop_debug_seqNum_uopIdx 8 173
lqu_pipe pipelineReg_1 uop_storeSetHit 1 172
lqu_pipe pipelineReg_1 uop_waitForRobIdx_flag 1 171
lqu_pipe pipelineReg_1 uop_waitForRobIdx_value 8 163
lqu_pipe pipelineReg_1 uop_loadWaitBit 1 162
lqu_pipe pipelineReg_1 uop_loadWaitStrict 1 161
lqu_pipe pipelineReg_1 uop_ssid 5 156
lqu_pipe pipelineReg_1 uop_lqIdx_flag 1 155
lqu_pipe pipelineReg_1 uop_lqIdx_value 7 148
lqu_pipe pipelineReg_1 uop_sqIdx_flag 1 147
lqu_pipe pipelineReg_1 uop_sqIdx_value 6 141
lqu_pipe pipelineReg_1 uop_singleStep 1 140
lqu_pipe pipelineReg_1 uop_replayInst 1 139
lqu_pipe pipelineReg_1 uop_debug_fuType 35 104
lqu_pipe pipelineReg_1 uop_debug_sim_trig 1 103
lqu_pipe pipelineReg_1 uop_numLsElem 5 98
lqu_pipe pipelineReg_1 debug_paddr 48 50
lqu_pipe pipelineReg_1 debug_vaddr 50 0
lqu_pin1 r:/WORK/LoadQueueUncache/pipelineReg_2/pipeline_reg_valid_reg i:/WORK/LoadQueueUncache/u_core/pipelineReg_2/u_core/valid_q_reg
lqu_pipe pipelineReg_2 uop_instr 32 1535
lqu_pipe pipelineReg_2 uop_pc 50 1485
lqu_pipe pipelineReg_2 uop_foldpc 10 1475
lqu_pipe pipelineReg_2 uop_exceptionVec_0 1 1474
lqu_pipe pipelineReg_2 uop_exceptionVec_1 1 1473
lqu_pipe pipelineReg_2 uop_exceptionVec_2 1 1472
lqu_pipe pipelineReg_2 uop_exceptionVec_3 1 1471
lqu_pipe pipelineReg_2 uop_exceptionVec_4 1 1470
lqu_pipe pipelineReg_2 uop_exceptionVec_5 1 1469
lqu_pipe pipelineReg_2 uop_exceptionVec_6 1 1468
lqu_pipe pipelineReg_2 uop_exceptionVec_7 1 1467
lqu_pipe pipelineReg_2 uop_exceptionVec_8 1 1466
lqu_pipe pipelineReg_2 uop_exceptionVec_9 1 1465
lqu_pipe pipelineReg_2 uop_exceptionVec_10 1 1464
lqu_pipe pipelineReg_2 uop_exceptionVec_11 1 1463
lqu_pipe pipelineReg_2 uop_exceptionVec_12 1 1462
lqu_pipe pipelineReg_2 uop_exceptionVec_13 1 1461
lqu_pipe pipelineReg_2 uop_exceptionVec_14 1 1460
lqu_pipe pipelineReg_2 uop_exceptionVec_15 1 1459
lqu_pipe pipelineReg_2 uop_exceptionVec_16 1 1458
lqu_pipe pipelineReg_2 uop_exceptionVec_17 1 1457
lqu_pipe pipelineReg_2 uop_exceptionVec_18 1 1456
lqu_pipe pipelineReg_2 uop_exceptionVec_19 1 1455
lqu_pipe pipelineReg_2 uop_exceptionVec_20 1 1454
lqu_pipe pipelineReg_2 uop_exceptionVec_21 1 1453
lqu_pipe pipelineReg_2 uop_exceptionVec_22 1 1452
lqu_pipe pipelineReg_2 uop_exceptionVec_23 1 1451
lqu_pipe pipelineReg_2 uop_isFetchMalAddr 1 1450
lqu_pipe pipelineReg_2 uop_hasException 1 1449
lqu_pipe pipelineReg_2 uop_trigger 4 1445
lqu_pipe pipelineReg_2 uop_preDecodeInfo_valid 1 1444
lqu_pipe pipelineReg_2 uop_preDecodeInfo_isRVC 1 1443
lqu_pipe pipelineReg_2 uop_preDecodeInfo_brType 2 1441
lqu_pipe pipelineReg_2 uop_preDecodeInfo_isCall 1 1440
lqu_pipe pipelineReg_2 uop_preDecodeInfo_isRet 1 1439
lqu_pipe pipelineReg_2 uop_pred_taken 1 1438
lqu_pipe pipelineReg_2 uop_crossPageIPFFix 1 1437
lqu_pipe pipelineReg_2 uop_ftqPtr_flag 1 1436
lqu_pipe pipelineReg_2 uop_ftqPtr_value 6 1430
lqu_pipe pipelineReg_2 uop_ftqOffset 4 1426
lqu_pipe pipelineReg_2 uop_satpFlushFirstFetchFault 1 1425
lqu_pipe pipelineReg_2 uop_srcType_0 4 1421
lqu_pipe pipelineReg_2 uop_srcType_1 4 1417
lqu_pipe pipelineReg_2 uop_srcType_2 4 1413
lqu_pipe pipelineReg_2 uop_srcType_3 4 1409
lqu_pipe pipelineReg_2 uop_srcType_4 4 1405
lqu_pipe pipelineReg_2 uop_ldest 6 1399
lqu_pipe pipelineReg_2 uop_fuType 35 1364
lqu_pipe pipelineReg_2 uop_fuOpType 9 1355
lqu_pipe pipelineReg_2 uop_rfWen 1 1354
lqu_pipe pipelineReg_2 uop_fpWen 1 1353
lqu_pipe pipelineReg_2 uop_vecWen 1 1352
lqu_pipe pipelineReg_2 uop_v0Wen 1 1351
lqu_pipe pipelineReg_2 uop_vlWen 1 1350
lqu_pipe pipelineReg_2 uop_isXSTrap 1 1349
lqu_pipe pipelineReg_2 uop_waitForward 1 1348
lqu_pipe pipelineReg_2 uop_blockBackward 1 1347
lqu_pipe pipelineReg_2 uop_flushPipe 1 1346
lqu_pipe pipelineReg_2 uop_canRobCompress 1 1345
lqu_pipe pipelineReg_2 uop_selImm 4 1341
lqu_pipe pipelineReg_2 uop_imm 32 1309
lqu_pipe pipelineReg_2 uop_fpu_typeTagOut 2 1307
lqu_pipe pipelineReg_2 uop_fpu_wflags 1 1306
lqu_pipe pipelineReg_2 uop_fpu_typ 2 1304
lqu_pipe pipelineReg_2 uop_fpu_fmt 2 1302
lqu_pipe pipelineReg_2 uop_fpu_rm 3 1299
lqu_pipe pipelineReg_2 uop_vpu_vill 1 1298
lqu_pipe pipelineReg_2 uop_vpu_vma 1 1297
lqu_pipe pipelineReg_2 uop_vpu_vta 1 1296
lqu_pipe pipelineReg_2 uop_vpu_vsew 2 1294
lqu_pipe pipelineReg_2 uop_vpu_vlmul 3 1291
lqu_pipe pipelineReg_2 uop_vpu_specVill 1 1290
lqu_pipe pipelineReg_2 uop_vpu_specVma 1 1289
lqu_pipe pipelineReg_2 uop_vpu_specVta 1 1288
lqu_pipe pipelineReg_2 uop_vpu_specVsew 2 1286
lqu_pipe pipelineReg_2 uop_vpu_specVlmul 3 1283
lqu_pipe pipelineReg_2 uop_vpu_vm 1 1282
lqu_pipe pipelineReg_2 uop_vpu_vstart 8 1274
lqu_pipe pipelineReg_2 uop_vpu_frm 3 1271
lqu_pipe pipelineReg_2 uop_vpu_fpu_isFpToVecInst 1 1270
lqu_pipe pipelineReg_2 uop_vpu_fpu_isFP32Instr 1 1269
lqu_pipe pipelineReg_2 uop_vpu_fpu_isFP64Instr 1 1268
lqu_pipe pipelineReg_2 uop_vpu_fpu_isReduction 1 1267
lqu_pipe pipelineReg_2 uop_vpu_fpu_isFoldTo1_2 1 1266
lqu_pipe pipelineReg_2 uop_vpu_fpu_isFoldTo1_4 1 1265
lqu_pipe pipelineReg_2 uop_vpu_fpu_isFoldTo1_8 1 1264
lqu_pipe pipelineReg_2 uop_vpu_vxrm 2 1262
lqu_pipe pipelineReg_2 uop_vpu_vuopIdx 7 1255
lqu_pipe pipelineReg_2 uop_vpu_lastUop 1 1254
lqu_pipe pipelineReg_2 uop_vpu_vmask 128 1126
lqu_pipe pipelineReg_2 uop_vpu_vl 8 1118
lqu_pipe pipelineReg_2 uop_vpu_nf 3 1115
lqu_pipe pipelineReg_2 uop_vpu_veew 2 1113
lqu_pipe pipelineReg_2 uop_vpu_isReverse 1 1112
lqu_pipe pipelineReg_2 uop_vpu_isExt 1 1111
lqu_pipe pipelineReg_2 uop_vpu_isNarrow 1 1110
lqu_pipe pipelineReg_2 uop_vpu_isDstMask 1 1109
lqu_pipe pipelineReg_2 uop_vpu_isOpMask 1 1108
lqu_pipe pipelineReg_2 uop_vpu_isMove 1 1107
lqu_pipe pipelineReg_2 uop_vpu_isDependOldVd 1 1106
lqu_pipe pipelineReg_2 uop_vpu_isWritePartVd 1 1105
lqu_pipe pipelineReg_2 uop_vpu_isVleff 1 1104
lqu_pipe pipelineReg_2 uop_vlsInstr 1 1103
lqu_pipe pipelineReg_2 uop_wfflags 1 1102
lqu_pipe pipelineReg_2 uop_isMove 1 1101
lqu_pipe pipelineReg_2 uop_isDropAmocasSta 1 1100
lqu_pipe pipelineReg_2 uop_uopIdx 7 1093
lqu_pipe pipelineReg_2 uop_isVset 1 1092
lqu_pipe pipelineReg_2 uop_firstUop 1 1091
lqu_pipe pipelineReg_2 uop_lastUop 1 1090
lqu_pipe pipelineReg_2 uop_numUops 7 1083
lqu_pipe pipelineReg_2 uop_numWB 7 1076
lqu_pipe pipelineReg_2 uop_commitType 3 1073
lqu_pipe pipelineReg_2 uop_srcState_0 1 1072
lqu_pipe pipelineReg_2 uop_srcState_1 1 1071
lqu_pipe pipelineReg_2 uop_srcState_2 1 1070
lqu_pipe pipelineReg_2 uop_srcState_3 1 1069
lqu_pipe pipelineReg_2 uop_srcState_4 1 1068
lqu_pipe pipelineReg_2 uop_srcLoadDependency_0_0 2 1066
lqu_pipe pipelineReg_2 uop_srcLoadDependency_0_1 2 1064
lqu_pipe pipelineReg_2 uop_srcLoadDependency_0_2 2 1062
lqu_pipe pipelineReg_2 uop_srcLoadDependency_1_0 2 1060
lqu_pipe pipelineReg_2 uop_srcLoadDependency_1_1 2 1058
lqu_pipe pipelineReg_2 uop_srcLoadDependency_1_2 2 1056
lqu_pipe pipelineReg_2 uop_srcLoadDependency_2_0 2 1054
lqu_pipe pipelineReg_2 uop_srcLoadDependency_2_1 2 1052
lqu_pipe pipelineReg_2 uop_srcLoadDependency_2_2 2 1050
lqu_pipe pipelineReg_2 uop_srcLoadDependency_3_0 2 1048
lqu_pipe pipelineReg_2 uop_srcLoadDependency_3_1 2 1046
lqu_pipe pipelineReg_2 uop_srcLoadDependency_3_2 2 1044
lqu_pipe pipelineReg_2 uop_srcLoadDependency_4_0 2 1042
lqu_pipe pipelineReg_2 uop_srcLoadDependency_4_1 2 1040
lqu_pipe pipelineReg_2 uop_srcLoadDependency_4_2 2 1038
lqu_pipe pipelineReg_2 uop_psrc_0 8 1030
lqu_pipe pipelineReg_2 uop_psrc_1 8 1022
lqu_pipe pipelineReg_2 uop_psrc_2 8 1014
lqu_pipe pipelineReg_2 uop_psrc_3 8 1006
lqu_pipe pipelineReg_2 uop_psrc_4 8 998
lqu_pipe pipelineReg_2 uop_pdest 8 990
lqu_pipe pipelineReg_2 uop_useRegCache_0 1 989
lqu_pipe pipelineReg_2 uop_useRegCache_1 1 988
lqu_pipe pipelineReg_2 uop_regCacheIdx_0 5 983
lqu_pipe pipelineReg_2 uop_regCacheIdx_1 5 978
lqu_pipe pipelineReg_2 uop_robIdx_flag 1 977
lqu_pipe pipelineReg_2 uop_robIdx_value 8 969
lqu_pipe pipelineReg_2 uop_instrSize 3 966
lqu_pipe pipelineReg_2 uop_dirtyFs 1 965
lqu_pipe pipelineReg_2 uop_dirtyVs 1 964
lqu_pipe pipelineReg_2 uop_traceBlockInPipe_itype 4 960
lqu_pipe pipelineReg_2 uop_traceBlockInPipe_iretire 4 956
lqu_pipe pipelineReg_2 uop_traceBlockInPipe_ilastsize 1 955
lqu_pipe pipelineReg_2 uop_eliminatedMove 1 954
lqu_pipe pipelineReg_2 uop_snapshot 1 953
lqu_pipe pipelineReg_2 uop_debugInfo_eliminatedMove 1 952
lqu_pipe pipelineReg_2 uop_debugInfo_renameTime 64 888
lqu_pipe pipelineReg_2 uop_debugInfo_dispatchTime 64 824
lqu_pipe pipelineReg_2 uop_debugInfo_enqRsTime 64 760
lqu_pipe pipelineReg_2 uop_debugInfo_selectTime 64 696
lqu_pipe pipelineReg_2 uop_debugInfo_issueTime 64 632
lqu_pipe pipelineReg_2 uop_debugInfo_writebackTime 64 568
lqu_pipe pipelineReg_2 uop_debugInfo_runahead_checkpoint_id 64 504
lqu_pipe pipelineReg_2 uop_debugInfo_tlbFirstReqTime 64 440
lqu_pipe pipelineReg_2 uop_debugInfo_tlbRespTime 64 376
lqu_pipe pipelineReg_2 uop_debug_seqNum_seqNum 56 320
lqu_pipe pipelineReg_2 uop_debug_seqNum_uopIdx 8 312
lqu_pipe pipelineReg_2 uop_storeSetHit 1 311
lqu_pipe pipelineReg_2 uop_waitForRobIdx_flag 1 310
lqu_pipe pipelineReg_2 uop_waitForRobIdx_value 8 302
lqu_pipe pipelineReg_2 uop_loadWaitBit 1 301
lqu_pipe pipelineReg_2 uop_loadWaitStrict 1 300
lqu_pipe pipelineReg_2 uop_ssid 5 295
lqu_pipe pipelineReg_2 uop_lqIdx_flag 1 294
lqu_pipe pipelineReg_2 uop_lqIdx_value 7 287
lqu_pipe pipelineReg_2 uop_sqIdx_flag 1 286
lqu_pipe pipelineReg_2 uop_sqIdx_value 6 280
lqu_pipe pipelineReg_2 uop_singleStep 1 279
lqu_pipe pipelineReg_2 uop_replayInst 1 278
lqu_pipe pipelineReg_2 uop_debug_fuType 35 243
lqu_pipe pipelineReg_2 uop_debug_sim_trig 1 242
lqu_pipe pipelineReg_2 uop_numLsElem 5 237
lqu_pipe pipelineReg_2 vaddr 50 187
lqu_pipe pipelineReg_2 paddr 48 139
lqu_pipe pipelineReg_2 data 129 10
lqu_pipe pipelineReg_2 isvec 1 9
lqu_pipe pipelineReg_2 is128bit 1 8
lqu_pipe pipelineReg_2 vecActive 1 7
lqu_pipe pipelineReg_2 schedIndex 7 0
lqu_pin1 r:/WORK/LoadQueueUncache/pipelineReg_3/pipeline_reg_valid_reg i:/WORK/LoadQueueUncache/u_core/pipelineReg_3/u_core/valid_q_reg
lqu_pipe pipelineReg_3 uop_instr 32 1535
lqu_pipe pipelineReg_3 uop_pc 50 1485
lqu_pipe pipelineReg_3 uop_foldpc 10 1475
lqu_pipe pipelineReg_3 uop_exceptionVec_0 1 1474
lqu_pipe pipelineReg_3 uop_exceptionVec_1 1 1473
lqu_pipe pipelineReg_3 uop_exceptionVec_2 1 1472
lqu_pipe pipelineReg_3 uop_exceptionVec_3 1 1471
lqu_pipe pipelineReg_3 uop_exceptionVec_4 1 1470
lqu_pipe pipelineReg_3 uop_exceptionVec_5 1 1469
lqu_pipe pipelineReg_3 uop_exceptionVec_6 1 1468
lqu_pipe pipelineReg_3 uop_exceptionVec_7 1 1467
lqu_pipe pipelineReg_3 uop_exceptionVec_8 1 1466
lqu_pipe pipelineReg_3 uop_exceptionVec_9 1 1465
lqu_pipe pipelineReg_3 uop_exceptionVec_10 1 1464
lqu_pipe pipelineReg_3 uop_exceptionVec_11 1 1463
lqu_pipe pipelineReg_3 uop_exceptionVec_12 1 1462
lqu_pipe pipelineReg_3 uop_exceptionVec_13 1 1461
lqu_pipe pipelineReg_3 uop_exceptionVec_14 1 1460
lqu_pipe pipelineReg_3 uop_exceptionVec_15 1 1459
lqu_pipe pipelineReg_3 uop_exceptionVec_16 1 1458
lqu_pipe pipelineReg_3 uop_exceptionVec_17 1 1457
lqu_pipe pipelineReg_3 uop_exceptionVec_18 1 1456
lqu_pipe pipelineReg_3 uop_exceptionVec_19 1 1455
lqu_pipe pipelineReg_3 uop_exceptionVec_20 1 1454
lqu_pipe pipelineReg_3 uop_exceptionVec_21 1 1453
lqu_pipe pipelineReg_3 uop_exceptionVec_22 1 1452
lqu_pipe pipelineReg_3 uop_exceptionVec_23 1 1451
lqu_pipe pipelineReg_3 uop_isFetchMalAddr 1 1450
lqu_pipe pipelineReg_3 uop_hasException 1 1449
lqu_pipe pipelineReg_3 uop_trigger 4 1445
lqu_pipe pipelineReg_3 uop_preDecodeInfo_valid 1 1444
lqu_pipe pipelineReg_3 uop_preDecodeInfo_isRVC 1 1443
lqu_pipe pipelineReg_3 uop_preDecodeInfo_brType 2 1441
lqu_pipe pipelineReg_3 uop_preDecodeInfo_isCall 1 1440
lqu_pipe pipelineReg_3 uop_preDecodeInfo_isRet 1 1439
lqu_pipe pipelineReg_3 uop_pred_taken 1 1438
lqu_pipe pipelineReg_3 uop_crossPageIPFFix 1 1437
lqu_pipe pipelineReg_3 uop_ftqPtr_flag 1 1436
lqu_pipe pipelineReg_3 uop_ftqPtr_value 6 1430
lqu_pipe pipelineReg_3 uop_ftqOffset 4 1426
lqu_pipe pipelineReg_3 uop_satpFlushFirstFetchFault 1 1425
lqu_pipe pipelineReg_3 uop_srcType_0 4 1421
lqu_pipe pipelineReg_3 uop_srcType_1 4 1417
lqu_pipe pipelineReg_3 uop_srcType_2 4 1413
lqu_pipe pipelineReg_3 uop_srcType_3 4 1409
lqu_pipe pipelineReg_3 uop_srcType_4 4 1405
lqu_pipe pipelineReg_3 uop_ldest 6 1399
lqu_pipe pipelineReg_3 uop_fuType 35 1364
lqu_pipe pipelineReg_3 uop_fuOpType 9 1355
lqu_pipe pipelineReg_3 uop_rfWen 1 1354
lqu_pipe pipelineReg_3 uop_fpWen 1 1353
lqu_pipe pipelineReg_3 uop_vecWen 1 1352
lqu_pipe pipelineReg_3 uop_v0Wen 1 1351
lqu_pipe pipelineReg_3 uop_vlWen 1 1350
lqu_pipe pipelineReg_3 uop_isXSTrap 1 1349
lqu_pipe pipelineReg_3 uop_waitForward 1 1348
lqu_pipe pipelineReg_3 uop_blockBackward 1 1347
lqu_pipe pipelineReg_3 uop_flushPipe 1 1346
lqu_pipe pipelineReg_3 uop_canRobCompress 1 1345
lqu_pipe pipelineReg_3 uop_selImm 4 1341
lqu_pipe pipelineReg_3 uop_imm 32 1309
lqu_pipe pipelineReg_3 uop_fpu_typeTagOut 2 1307
lqu_pipe pipelineReg_3 uop_fpu_wflags 1 1306
lqu_pipe pipelineReg_3 uop_fpu_typ 2 1304
lqu_pipe pipelineReg_3 uop_fpu_fmt 2 1302
lqu_pipe pipelineReg_3 uop_fpu_rm 3 1299
lqu_pipe pipelineReg_3 uop_vpu_vill 1 1298
lqu_pipe pipelineReg_3 uop_vpu_vma 1 1297
lqu_pipe pipelineReg_3 uop_vpu_vta 1 1296
lqu_pipe pipelineReg_3 uop_vpu_vsew 2 1294
lqu_pipe pipelineReg_3 uop_vpu_vlmul 3 1291
lqu_pipe pipelineReg_3 uop_vpu_specVill 1 1290
lqu_pipe pipelineReg_3 uop_vpu_specVma 1 1289
lqu_pipe pipelineReg_3 uop_vpu_specVta 1 1288
lqu_pipe pipelineReg_3 uop_vpu_specVsew 2 1286
lqu_pipe pipelineReg_3 uop_vpu_specVlmul 3 1283
lqu_pipe pipelineReg_3 uop_vpu_vm 1 1282
lqu_pipe pipelineReg_3 uop_vpu_vstart 8 1274
lqu_pipe pipelineReg_3 uop_vpu_frm 3 1271
lqu_pipe pipelineReg_3 uop_vpu_fpu_isFpToVecInst 1 1270
lqu_pipe pipelineReg_3 uop_vpu_fpu_isFP32Instr 1 1269
lqu_pipe pipelineReg_3 uop_vpu_fpu_isFP64Instr 1 1268
lqu_pipe pipelineReg_3 uop_vpu_fpu_isReduction 1 1267
lqu_pipe pipelineReg_3 uop_vpu_fpu_isFoldTo1_2 1 1266
lqu_pipe pipelineReg_3 uop_vpu_fpu_isFoldTo1_4 1 1265
lqu_pipe pipelineReg_3 uop_vpu_fpu_isFoldTo1_8 1 1264
lqu_pipe pipelineReg_3 uop_vpu_vxrm 2 1262
lqu_pipe pipelineReg_3 uop_vpu_vuopIdx 7 1255
lqu_pipe pipelineReg_3 uop_vpu_lastUop 1 1254
lqu_pipe pipelineReg_3 uop_vpu_vmask 128 1126
lqu_pipe pipelineReg_3 uop_vpu_vl 8 1118
lqu_pipe pipelineReg_3 uop_vpu_nf 3 1115
lqu_pipe pipelineReg_3 uop_vpu_veew 2 1113
lqu_pipe pipelineReg_3 uop_vpu_isReverse 1 1112
lqu_pipe pipelineReg_3 uop_vpu_isExt 1 1111
lqu_pipe pipelineReg_3 uop_vpu_isNarrow 1 1110
lqu_pipe pipelineReg_3 uop_vpu_isDstMask 1 1109
lqu_pipe pipelineReg_3 uop_vpu_isOpMask 1 1108
lqu_pipe pipelineReg_3 uop_vpu_isMove 1 1107
lqu_pipe pipelineReg_3 uop_vpu_isDependOldVd 1 1106
lqu_pipe pipelineReg_3 uop_vpu_isWritePartVd 1 1105
lqu_pipe pipelineReg_3 uop_vpu_isVleff 1 1104
lqu_pipe pipelineReg_3 uop_vlsInstr 1 1103
lqu_pipe pipelineReg_3 uop_wfflags 1 1102
lqu_pipe pipelineReg_3 uop_isMove 1 1101
lqu_pipe pipelineReg_3 uop_isDropAmocasSta 1 1100
lqu_pipe pipelineReg_3 uop_uopIdx 7 1093
lqu_pipe pipelineReg_3 uop_isVset 1 1092
lqu_pipe pipelineReg_3 uop_firstUop 1 1091
lqu_pipe pipelineReg_3 uop_lastUop 1 1090
lqu_pipe pipelineReg_3 uop_numUops 7 1083
lqu_pipe pipelineReg_3 uop_numWB 7 1076
lqu_pipe pipelineReg_3 uop_commitType 3 1073
lqu_pipe pipelineReg_3 uop_srcState_0 1 1072
lqu_pipe pipelineReg_3 uop_srcState_1 1 1071
lqu_pipe pipelineReg_3 uop_srcState_2 1 1070
lqu_pipe pipelineReg_3 uop_srcState_3 1 1069
lqu_pipe pipelineReg_3 uop_srcState_4 1 1068
lqu_pipe pipelineReg_3 uop_srcLoadDependency_0_0 2 1066
lqu_pipe pipelineReg_3 uop_srcLoadDependency_0_1 2 1064
lqu_pipe pipelineReg_3 uop_srcLoadDependency_0_2 2 1062
lqu_pipe pipelineReg_3 uop_srcLoadDependency_1_0 2 1060
lqu_pipe pipelineReg_3 uop_srcLoadDependency_1_1 2 1058
lqu_pipe pipelineReg_3 uop_srcLoadDependency_1_2 2 1056
lqu_pipe pipelineReg_3 uop_srcLoadDependency_2_0 2 1054
lqu_pipe pipelineReg_3 uop_srcLoadDependency_2_1 2 1052
lqu_pipe pipelineReg_3 uop_srcLoadDependency_2_2 2 1050
lqu_pipe pipelineReg_3 uop_srcLoadDependency_3_0 2 1048
lqu_pipe pipelineReg_3 uop_srcLoadDependency_3_1 2 1046
lqu_pipe pipelineReg_3 uop_srcLoadDependency_3_2 2 1044
lqu_pipe pipelineReg_3 uop_srcLoadDependency_4_0 2 1042
lqu_pipe pipelineReg_3 uop_srcLoadDependency_4_1 2 1040
lqu_pipe pipelineReg_3 uop_srcLoadDependency_4_2 2 1038
lqu_pipe pipelineReg_3 uop_psrc_0 8 1030
lqu_pipe pipelineReg_3 uop_psrc_1 8 1022
lqu_pipe pipelineReg_3 uop_psrc_2 8 1014
lqu_pipe pipelineReg_3 uop_psrc_3 8 1006
lqu_pipe pipelineReg_3 uop_psrc_4 8 998
lqu_pipe pipelineReg_3 uop_pdest 8 990
lqu_pipe pipelineReg_3 uop_useRegCache_0 1 989
lqu_pipe pipelineReg_3 uop_useRegCache_1 1 988
lqu_pipe pipelineReg_3 uop_regCacheIdx_0 5 983
lqu_pipe pipelineReg_3 uop_regCacheIdx_1 5 978
lqu_pipe pipelineReg_3 uop_robIdx_flag 1 977
lqu_pipe pipelineReg_3 uop_robIdx_value 8 969
lqu_pipe pipelineReg_3 uop_instrSize 3 966
lqu_pipe pipelineReg_3 uop_dirtyFs 1 965
lqu_pipe pipelineReg_3 uop_dirtyVs 1 964
lqu_pipe pipelineReg_3 uop_traceBlockInPipe_itype 4 960
lqu_pipe pipelineReg_3 uop_traceBlockInPipe_iretire 4 956
lqu_pipe pipelineReg_3 uop_traceBlockInPipe_ilastsize 1 955
lqu_pipe pipelineReg_3 uop_eliminatedMove 1 954
lqu_pipe pipelineReg_3 uop_snapshot 1 953
lqu_pipe pipelineReg_3 uop_debugInfo_eliminatedMove 1 952
lqu_pipe pipelineReg_3 uop_debugInfo_renameTime 64 888
lqu_pipe pipelineReg_3 uop_debugInfo_dispatchTime 64 824
lqu_pipe pipelineReg_3 uop_debugInfo_enqRsTime 64 760
lqu_pipe pipelineReg_3 uop_debugInfo_selectTime 64 696
lqu_pipe pipelineReg_3 uop_debugInfo_issueTime 64 632
lqu_pipe pipelineReg_3 uop_debugInfo_writebackTime 64 568
lqu_pipe pipelineReg_3 uop_debugInfo_runahead_checkpoint_id 64 504
lqu_pipe pipelineReg_3 uop_debugInfo_tlbFirstReqTime 64 440
lqu_pipe pipelineReg_3 uop_debugInfo_tlbRespTime 64 376
lqu_pipe pipelineReg_3 uop_debug_seqNum_seqNum 56 320
lqu_pipe pipelineReg_3 uop_debug_seqNum_uopIdx 8 312
lqu_pipe pipelineReg_3 uop_storeSetHit 1 311
lqu_pipe pipelineReg_3 uop_waitForRobIdx_flag 1 310
lqu_pipe pipelineReg_3 uop_waitForRobIdx_value 8 302
lqu_pipe pipelineReg_3 uop_loadWaitBit 1 301
lqu_pipe pipelineReg_3 uop_loadWaitStrict 1 300
lqu_pipe pipelineReg_3 uop_ssid 5 295
lqu_pipe pipelineReg_3 uop_lqIdx_flag 1 294
lqu_pipe pipelineReg_3 uop_lqIdx_value 7 287
lqu_pipe pipelineReg_3 uop_sqIdx_flag 1 286
lqu_pipe pipelineReg_3 uop_sqIdx_value 6 280
lqu_pipe pipelineReg_3 uop_singleStep 1 279
lqu_pipe pipelineReg_3 uop_replayInst 1 278
lqu_pipe pipelineReg_3 uop_debug_fuType 35 243
lqu_pipe pipelineReg_3 uop_debug_sim_trig 1 242
lqu_pipe pipelineReg_3 uop_numLsElem 5 237
lqu_pipe pipelineReg_3 vaddr 50 187
lqu_pipe pipelineReg_3 paddr 48 139
lqu_pipe pipelineReg_3 data 129 10
lqu_pipe pipelineReg_3 isvec 1 9
lqu_pipe pipelineReg_3 is128bit 1 8
lqu_pipe pipelineReg_3 vecActive 1 7
lqu_pipe pipelineReg_3 schedIndex 7 0
lqu_pin1 r:/WORK/LoadQueueUncache/pipelineReg_4/pipeline_reg_valid_reg i:/WORK/LoadQueueUncache/u_core/pipelineReg_4/u_core/valid_q_reg
lqu_pipe pipelineReg_4 uop_instr 32 1535
lqu_pipe pipelineReg_4 uop_pc 50 1485
lqu_pipe pipelineReg_4 uop_foldpc 10 1475
lqu_pipe pipelineReg_4 uop_exceptionVec_0 1 1474
lqu_pipe pipelineReg_4 uop_exceptionVec_1 1 1473
lqu_pipe pipelineReg_4 uop_exceptionVec_2 1 1472
lqu_pipe pipelineReg_4 uop_exceptionVec_3 1 1471
lqu_pipe pipelineReg_4 uop_exceptionVec_4 1 1470
lqu_pipe pipelineReg_4 uop_exceptionVec_5 1 1469
lqu_pipe pipelineReg_4 uop_exceptionVec_6 1 1468
lqu_pipe pipelineReg_4 uop_exceptionVec_7 1 1467
lqu_pipe pipelineReg_4 uop_exceptionVec_8 1 1466
lqu_pipe pipelineReg_4 uop_exceptionVec_9 1 1465
lqu_pipe pipelineReg_4 uop_exceptionVec_10 1 1464
lqu_pipe pipelineReg_4 uop_exceptionVec_11 1 1463
lqu_pipe pipelineReg_4 uop_exceptionVec_12 1 1462
lqu_pipe pipelineReg_4 uop_exceptionVec_13 1 1461
lqu_pipe pipelineReg_4 uop_exceptionVec_14 1 1460
lqu_pipe pipelineReg_4 uop_exceptionVec_15 1 1459
lqu_pipe pipelineReg_4 uop_exceptionVec_16 1 1458
lqu_pipe pipelineReg_4 uop_exceptionVec_17 1 1457
lqu_pipe pipelineReg_4 uop_exceptionVec_18 1 1456
lqu_pipe pipelineReg_4 uop_exceptionVec_19 1 1455
lqu_pipe pipelineReg_4 uop_exceptionVec_20 1 1454
lqu_pipe pipelineReg_4 uop_exceptionVec_21 1 1453
lqu_pipe pipelineReg_4 uop_exceptionVec_22 1 1452
lqu_pipe pipelineReg_4 uop_exceptionVec_23 1 1451
lqu_pipe pipelineReg_4 uop_isFetchMalAddr 1 1450
lqu_pipe pipelineReg_4 uop_hasException 1 1449
lqu_pipe pipelineReg_4 uop_trigger 4 1445
lqu_pipe pipelineReg_4 uop_preDecodeInfo_valid 1 1444
lqu_pipe pipelineReg_4 uop_preDecodeInfo_isRVC 1 1443
lqu_pipe pipelineReg_4 uop_preDecodeInfo_brType 2 1441
lqu_pipe pipelineReg_4 uop_preDecodeInfo_isCall 1 1440
lqu_pipe pipelineReg_4 uop_preDecodeInfo_isRet 1 1439
lqu_pipe pipelineReg_4 uop_pred_taken 1 1438
lqu_pipe pipelineReg_4 uop_crossPageIPFFix 1 1437
lqu_pipe pipelineReg_4 uop_ftqPtr_flag 1 1436
lqu_pipe pipelineReg_4 uop_ftqPtr_value 6 1430
lqu_pipe pipelineReg_4 uop_ftqOffset 4 1426
lqu_pipe pipelineReg_4 uop_satpFlushFirstFetchFault 1 1425
lqu_pipe pipelineReg_4 uop_srcType_0 4 1421
lqu_pipe pipelineReg_4 uop_srcType_1 4 1417
lqu_pipe pipelineReg_4 uop_srcType_2 4 1413
lqu_pipe pipelineReg_4 uop_srcType_3 4 1409
lqu_pipe pipelineReg_4 uop_srcType_4 4 1405
lqu_pipe pipelineReg_4 uop_ldest 6 1399
lqu_pipe pipelineReg_4 uop_fuType 35 1364
lqu_pipe pipelineReg_4 uop_fuOpType 9 1355
lqu_pipe pipelineReg_4 uop_rfWen 1 1354
lqu_pipe pipelineReg_4 uop_fpWen 1 1353
lqu_pipe pipelineReg_4 uop_vecWen 1 1352
lqu_pipe pipelineReg_4 uop_v0Wen 1 1351
lqu_pipe pipelineReg_4 uop_vlWen 1 1350
lqu_pipe pipelineReg_4 uop_isXSTrap 1 1349
lqu_pipe pipelineReg_4 uop_waitForward 1 1348
lqu_pipe pipelineReg_4 uop_blockBackward 1 1347
lqu_pipe pipelineReg_4 uop_flushPipe 1 1346
lqu_pipe pipelineReg_4 uop_canRobCompress 1 1345
lqu_pipe pipelineReg_4 uop_selImm 4 1341
lqu_pipe pipelineReg_4 uop_imm 32 1309
lqu_pipe pipelineReg_4 uop_fpu_typeTagOut 2 1307
lqu_pipe pipelineReg_4 uop_fpu_wflags 1 1306
lqu_pipe pipelineReg_4 uop_fpu_typ 2 1304
lqu_pipe pipelineReg_4 uop_fpu_fmt 2 1302
lqu_pipe pipelineReg_4 uop_fpu_rm 3 1299
lqu_pipe pipelineReg_4 uop_vpu_vill 1 1298
lqu_pipe pipelineReg_4 uop_vpu_vma 1 1297
lqu_pipe pipelineReg_4 uop_vpu_vta 1 1296
lqu_pipe pipelineReg_4 uop_vpu_vsew 2 1294
lqu_pipe pipelineReg_4 uop_vpu_vlmul 3 1291
lqu_pipe pipelineReg_4 uop_vpu_specVill 1 1290
lqu_pipe pipelineReg_4 uop_vpu_specVma 1 1289
lqu_pipe pipelineReg_4 uop_vpu_specVta 1 1288
lqu_pipe pipelineReg_4 uop_vpu_specVsew 2 1286
lqu_pipe pipelineReg_4 uop_vpu_specVlmul 3 1283
lqu_pipe pipelineReg_4 uop_vpu_vm 1 1282
lqu_pipe pipelineReg_4 uop_vpu_vstart 8 1274
lqu_pipe pipelineReg_4 uop_vpu_frm 3 1271
lqu_pipe pipelineReg_4 uop_vpu_fpu_isFpToVecInst 1 1270
lqu_pipe pipelineReg_4 uop_vpu_fpu_isFP32Instr 1 1269
lqu_pipe pipelineReg_4 uop_vpu_fpu_isFP64Instr 1 1268
lqu_pipe pipelineReg_4 uop_vpu_fpu_isReduction 1 1267
lqu_pipe pipelineReg_4 uop_vpu_fpu_isFoldTo1_2 1 1266
lqu_pipe pipelineReg_4 uop_vpu_fpu_isFoldTo1_4 1 1265
lqu_pipe pipelineReg_4 uop_vpu_fpu_isFoldTo1_8 1 1264
lqu_pipe pipelineReg_4 uop_vpu_vxrm 2 1262
lqu_pipe pipelineReg_4 uop_vpu_vuopIdx 7 1255
lqu_pipe pipelineReg_4 uop_vpu_lastUop 1 1254
lqu_pipe pipelineReg_4 uop_vpu_vmask 128 1126
lqu_pipe pipelineReg_4 uop_vpu_vl 8 1118
lqu_pipe pipelineReg_4 uop_vpu_nf 3 1115
lqu_pipe pipelineReg_4 uop_vpu_veew 2 1113
lqu_pipe pipelineReg_4 uop_vpu_isReverse 1 1112
lqu_pipe pipelineReg_4 uop_vpu_isExt 1 1111
lqu_pipe pipelineReg_4 uop_vpu_isNarrow 1 1110
lqu_pipe pipelineReg_4 uop_vpu_isDstMask 1 1109
lqu_pipe pipelineReg_4 uop_vpu_isOpMask 1 1108
lqu_pipe pipelineReg_4 uop_vpu_isMove 1 1107
lqu_pipe pipelineReg_4 uop_vpu_isDependOldVd 1 1106
lqu_pipe pipelineReg_4 uop_vpu_isWritePartVd 1 1105
lqu_pipe pipelineReg_4 uop_vpu_isVleff 1 1104
lqu_pipe pipelineReg_4 uop_vlsInstr 1 1103
lqu_pipe pipelineReg_4 uop_wfflags 1 1102
lqu_pipe pipelineReg_4 uop_isMove 1 1101
lqu_pipe pipelineReg_4 uop_isDropAmocasSta 1 1100
lqu_pipe pipelineReg_4 uop_uopIdx 7 1093
lqu_pipe pipelineReg_4 uop_isVset 1 1092
lqu_pipe pipelineReg_4 uop_firstUop 1 1091
lqu_pipe pipelineReg_4 uop_lastUop 1 1090
lqu_pipe pipelineReg_4 uop_numUops 7 1083
lqu_pipe pipelineReg_4 uop_numWB 7 1076
lqu_pipe pipelineReg_4 uop_commitType 3 1073
lqu_pipe pipelineReg_4 uop_srcState_0 1 1072
lqu_pipe pipelineReg_4 uop_srcState_1 1 1071
lqu_pipe pipelineReg_4 uop_srcState_2 1 1070
lqu_pipe pipelineReg_4 uop_srcState_3 1 1069
lqu_pipe pipelineReg_4 uop_srcState_4 1 1068
lqu_pipe pipelineReg_4 uop_srcLoadDependency_0_0 2 1066
lqu_pipe pipelineReg_4 uop_srcLoadDependency_0_1 2 1064
lqu_pipe pipelineReg_4 uop_srcLoadDependency_0_2 2 1062
lqu_pipe pipelineReg_4 uop_srcLoadDependency_1_0 2 1060
lqu_pipe pipelineReg_4 uop_srcLoadDependency_1_1 2 1058
lqu_pipe pipelineReg_4 uop_srcLoadDependency_1_2 2 1056
lqu_pipe pipelineReg_4 uop_srcLoadDependency_2_0 2 1054
lqu_pipe pipelineReg_4 uop_srcLoadDependency_2_1 2 1052
lqu_pipe pipelineReg_4 uop_srcLoadDependency_2_2 2 1050
lqu_pipe pipelineReg_4 uop_srcLoadDependency_3_0 2 1048
lqu_pipe pipelineReg_4 uop_srcLoadDependency_3_1 2 1046
lqu_pipe pipelineReg_4 uop_srcLoadDependency_3_2 2 1044
lqu_pipe pipelineReg_4 uop_srcLoadDependency_4_0 2 1042
lqu_pipe pipelineReg_4 uop_srcLoadDependency_4_1 2 1040
lqu_pipe pipelineReg_4 uop_srcLoadDependency_4_2 2 1038
lqu_pipe pipelineReg_4 uop_psrc_0 8 1030
lqu_pipe pipelineReg_4 uop_psrc_1 8 1022
lqu_pipe pipelineReg_4 uop_psrc_2 8 1014
lqu_pipe pipelineReg_4 uop_psrc_3 8 1006
lqu_pipe pipelineReg_4 uop_psrc_4 8 998
lqu_pipe pipelineReg_4 uop_pdest 8 990
lqu_pipe pipelineReg_4 uop_useRegCache_0 1 989
lqu_pipe pipelineReg_4 uop_useRegCache_1 1 988
lqu_pipe pipelineReg_4 uop_regCacheIdx_0 5 983
lqu_pipe pipelineReg_4 uop_regCacheIdx_1 5 978
lqu_pipe pipelineReg_4 uop_robIdx_flag 1 977
lqu_pipe pipelineReg_4 uop_robIdx_value 8 969
lqu_pipe pipelineReg_4 uop_instrSize 3 966
lqu_pipe pipelineReg_4 uop_dirtyFs 1 965
lqu_pipe pipelineReg_4 uop_dirtyVs 1 964
lqu_pipe pipelineReg_4 uop_traceBlockInPipe_itype 4 960
lqu_pipe pipelineReg_4 uop_traceBlockInPipe_iretire 4 956
lqu_pipe pipelineReg_4 uop_traceBlockInPipe_ilastsize 1 955
lqu_pipe pipelineReg_4 uop_eliminatedMove 1 954
lqu_pipe pipelineReg_4 uop_snapshot 1 953
lqu_pipe pipelineReg_4 uop_debugInfo_eliminatedMove 1 952
lqu_pipe pipelineReg_4 uop_debugInfo_renameTime 64 888
lqu_pipe pipelineReg_4 uop_debugInfo_dispatchTime 64 824
lqu_pipe pipelineReg_4 uop_debugInfo_enqRsTime 64 760
lqu_pipe pipelineReg_4 uop_debugInfo_selectTime 64 696
lqu_pipe pipelineReg_4 uop_debugInfo_issueTime 64 632
lqu_pipe pipelineReg_4 uop_debugInfo_writebackTime 64 568
lqu_pipe pipelineReg_4 uop_debugInfo_runahead_checkpoint_id 64 504
lqu_pipe pipelineReg_4 uop_debugInfo_tlbFirstReqTime 64 440
lqu_pipe pipelineReg_4 uop_debugInfo_tlbRespTime 64 376
lqu_pipe pipelineReg_4 uop_debug_seqNum_seqNum 56 320
lqu_pipe pipelineReg_4 uop_debug_seqNum_uopIdx 8 312
lqu_pipe pipelineReg_4 uop_storeSetHit 1 311
lqu_pipe pipelineReg_4 uop_waitForRobIdx_flag 1 310
lqu_pipe pipelineReg_4 uop_waitForRobIdx_value 8 302
lqu_pipe pipelineReg_4 uop_loadWaitBit 1 301
lqu_pipe pipelineReg_4 uop_loadWaitStrict 1 300
lqu_pipe pipelineReg_4 uop_ssid 5 295
lqu_pipe pipelineReg_4 uop_lqIdx_flag 1 294
lqu_pipe pipelineReg_4 uop_lqIdx_value 7 287
lqu_pipe pipelineReg_4 uop_sqIdx_flag 1 286
lqu_pipe pipelineReg_4 uop_sqIdx_value 6 280
lqu_pipe pipelineReg_4 uop_singleStep 1 279
lqu_pipe pipelineReg_4 uop_replayInst 1 278
lqu_pipe pipelineReg_4 uop_debug_fuType 35 243
lqu_pipe pipelineReg_4 uop_debug_sim_trig 1 242
lqu_pipe pipelineReg_4 uop_numLsElem 5 237
lqu_pipe pipelineReg_4 vaddr 50 187
lqu_pipe pipelineReg_4 paddr 48 139
lqu_pipe pipelineReg_4 data 129 10
lqu_pipe pipelineReg_4 isvec 1 9
lqu_pipe pipelineReg_4 is128bit 1 8
lqu_pipe pipelineReg_4 vecActive 1 7
lqu_pipe pipelineReg_4 schedIndex 7 0
puts "LQU_PIN_END LoadQueueUncache ok=$::LQU_PIN_OK bad=$::LQU_PIN_BAD"
if {$::LQU_PIN_BAD != 0} { error "LQU_PIN_MISS=$::LQU_PIN_BAD" }
if {$::LQU_PIN_OK != 11364} { error "LQU_PIN_COUNT=$::LQU_PIN_OK expect=11364" }
