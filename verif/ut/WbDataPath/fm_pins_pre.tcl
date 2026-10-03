# WbDataPath FM「匹配前」钉点 —— 自动生成：scripts/gen_wbdatapath.py（勿手改）
#
# 只消名差：两个 VldMergeUnit 实例里，golden 的 wbReg 是逐字段寄存器 wbReg_bits_<f>_reg，
# 重写核是一个 packed struct 寄存器 u_core/wb_bits_reg\[..]\[..]。其中大部分位在 WbDataPath
# 里没有读者（合并单元只把 valid/data/pdest/3 个 wen 交给仲裁器），FM 的签名分析配不上
# 无扇出的寄存器 —— 不钉就是两侧各 1904 个 unmatched unread。
# set_user_match 只声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。
# fail-closed：逐条数返回值，拒一条或总数不等于字面整数就 error。进 fm.log 的输出一律 ASCII。
set ::WBDP_PIN_EXPECT 2268
set ::WBDP_PIN_OK 0
set ::WBDP_PIN_BAD 0
proc wbdp_pin {inst g i w} {
  set pairs {}
  if {$w == 1} {
    lappend pairs "r:/WORK/WbDataPath/$inst/wbReg_bits_${g}_reg" "i:/WORK/WbDataPath/$inst/u_core/wb_bits_reg$i"
  } else {
    for {set b 0} {$b < $w} {incr b} {
      lappend pairs "r:/WORK/WbDataPath/$inst/wbReg_bits_${g}_reg\[$b\]" "i:/WORK/WbDataPath/$inst/u_core/wb_bits_reg$i\[$b\]"
    }
  }
  foreach {r m} $pairs {
    if {[set_user_match $r $m]} { incr ::WBDP_PIN_OK } else {
      incr ::WBDP_PIN_BAD
      if {$::WBDP_PIN_BAD <= 10} { puts "WBDP_PIN_FAIL: $r <-> $m" }
    }
  }
}
puts "WBDP_PIN_BEGIN WbDataPath expect=$::WBDP_PIN_EXPECT"
wbdp_pin vldMgu_0 data_0 {\[data_0]} 128
wbdp_pin vldMgu_0 pdest {\[pdest]} 7
wbdp_pin vldMgu_0 robIdx_flag {\[robIdx]\[flag]} 1
wbdp_pin vldMgu_0 robIdx_value {\[robIdx]\[value]} 8
wbdp_pin vldMgu_0 vecWen {\[vecWen]} 1
wbdp_pin vldMgu_0 v0Wen {\[v0Wen]} 1
wbdp_pin vldMgu_0 vlWen {\[vlWen]} 1
wbdp_pin vldMgu_0 exceptionVec_0 {\[exceptionVec][0]} 1
wbdp_pin vldMgu_0 exceptionVec_1 {\[exceptionVec][1]} 1
wbdp_pin vldMgu_0 exceptionVec_2 {\[exceptionVec][2]} 1
wbdp_pin vldMgu_0 exceptionVec_3 {\[exceptionVec][3]} 1
wbdp_pin vldMgu_0 exceptionVec_4 {\[exceptionVec][4]} 1
wbdp_pin vldMgu_0 exceptionVec_5 {\[exceptionVec][5]} 1
wbdp_pin vldMgu_0 exceptionVec_6 {\[exceptionVec][6]} 1
wbdp_pin vldMgu_0 exceptionVec_7 {\[exceptionVec][7]} 1
wbdp_pin vldMgu_0 exceptionVec_8 {\[exceptionVec][8]} 1
wbdp_pin vldMgu_0 exceptionVec_9 {\[exceptionVec][9]} 1
wbdp_pin vldMgu_0 exceptionVec_10 {\[exceptionVec][10]} 1
wbdp_pin vldMgu_0 exceptionVec_11 {\[exceptionVec][11]} 1
wbdp_pin vldMgu_0 exceptionVec_12 {\[exceptionVec][12]} 1
wbdp_pin vldMgu_0 exceptionVec_13 {\[exceptionVec][13]} 1
wbdp_pin vldMgu_0 exceptionVec_14 {\[exceptionVec][14]} 1
wbdp_pin vldMgu_0 exceptionVec_15 {\[exceptionVec][15]} 1
wbdp_pin vldMgu_0 exceptionVec_16 {\[exceptionVec][16]} 1
wbdp_pin vldMgu_0 exceptionVec_17 {\[exceptionVec][17]} 1
wbdp_pin vldMgu_0 exceptionVec_18 {\[exceptionVec][18]} 1
wbdp_pin vldMgu_0 exceptionVec_19 {\[exceptionVec][19]} 1
wbdp_pin vldMgu_0 exceptionVec_20 {\[exceptionVec][20]} 1
wbdp_pin vldMgu_0 exceptionVec_21 {\[exceptionVec][21]} 1
wbdp_pin vldMgu_0 exceptionVec_22 {\[exceptionVec][22]} 1
wbdp_pin vldMgu_0 exceptionVec_23 {\[exceptionVec][23]} 1
wbdp_pin vldMgu_0 flushPipe {\[flushPipe]} 1
wbdp_pin vldMgu_0 replay {\[replay]} 1
wbdp_pin vldMgu_0 trigger {\[trigger]} 4
wbdp_pin vldMgu_0 vls_vpu_vill {\[vls]\[vpu]\[vill]} 1
wbdp_pin vldMgu_0 vls_vpu_vma {\[vls]\[vpu]\[vma]} 1
wbdp_pin vldMgu_0 vls_vpu_vta {\[vls]\[vpu]\[vta]} 1
wbdp_pin vldMgu_0 vls_vpu_vsew {\[vls]\[vpu]\[vsew]} 2
wbdp_pin vldMgu_0 vls_vpu_vlmul {\[vls]\[vpu]\[vlmul]} 3
wbdp_pin vldMgu_0 vls_vpu_specVill {\[vls]\[vpu]\[specVill]} 1
wbdp_pin vldMgu_0 vls_vpu_specVma {\[vls]\[vpu]\[specVma]} 1
wbdp_pin vldMgu_0 vls_vpu_specVta {\[vls]\[vpu]\[specVta]} 1
wbdp_pin vldMgu_0 vls_vpu_specVsew {\[vls]\[vpu]\[specVsew]} 2
wbdp_pin vldMgu_0 vls_vpu_specVlmul {\[vls]\[vpu]\[specVlmul]} 3
wbdp_pin vldMgu_0 vls_vpu_vm {\[vls]\[vpu]\[vm]} 1
wbdp_pin vldMgu_0 vls_vpu_vstart {\[vls]\[vpu]\[vstart]} 8
wbdp_pin vldMgu_0 vls_vpu_frm {\[vls]\[vpu]\[frm]} 3
wbdp_pin vldMgu_0 vls_vpu_fpu_isFpToVecInst {\[vls]\[vpu]\[fpu]\[isFpToVecInst]} 1
wbdp_pin vldMgu_0 vls_vpu_fpu_isFP32Instr {\[vls]\[vpu]\[fpu]\[isFP32Instr]} 1
wbdp_pin vldMgu_0 vls_vpu_fpu_isFP64Instr {\[vls]\[vpu]\[fpu]\[isFP64Instr]} 1
wbdp_pin vldMgu_0 vls_vpu_fpu_isReduction {\[vls]\[vpu]\[fpu]\[isReduction]} 1
wbdp_pin vldMgu_0 vls_vpu_fpu_isFoldTo1_2 {\[vls]\[vpu]\[fpu]\[isFoldTo1_2]} 1
wbdp_pin vldMgu_0 vls_vpu_fpu_isFoldTo1_4 {\[vls]\[vpu]\[fpu]\[isFoldTo1_4]} 1
wbdp_pin vldMgu_0 vls_vpu_fpu_isFoldTo1_8 {\[vls]\[vpu]\[fpu]\[isFoldTo1_8]} 1
wbdp_pin vldMgu_0 vls_vpu_vxrm {\[vls]\[vpu]\[vxrm]} 2
wbdp_pin vldMgu_0 vls_vpu_vuopIdx {\[vls]\[vpu]\[vuopIdx]} 7
wbdp_pin vldMgu_0 vls_vpu_lastUop {\[vls]\[vpu]\[lastUop]} 1
wbdp_pin vldMgu_0 vls_vpu_vmask {\[vls]\[vpu]\[vmask]} 128
wbdp_pin vldMgu_0 vls_vpu_vl {\[vls]\[vpu]\[vl]} 8
wbdp_pin vldMgu_0 vls_vpu_nf {\[vls]\[vpu]\[nf]} 3
wbdp_pin vldMgu_0 vls_vpu_veew {\[vls]\[vpu]\[veew]} 2
wbdp_pin vldMgu_0 vls_vpu_isReverse {\[vls]\[vpu]\[isReverse]} 1
wbdp_pin vldMgu_0 vls_vpu_isExt {\[vls]\[vpu]\[isExt]} 1
wbdp_pin vldMgu_0 vls_vpu_isNarrow {\[vls]\[vpu]\[isNarrow]} 1
wbdp_pin vldMgu_0 vls_vpu_isDstMask {\[vls]\[vpu]\[isDstMask]} 1
wbdp_pin vldMgu_0 vls_vpu_isOpMask {\[vls]\[vpu]\[isOpMask]} 1
wbdp_pin vldMgu_0 vls_vpu_isMove {\[vls]\[vpu]\[isMove]} 1
wbdp_pin vldMgu_0 vls_vpu_isDependOldVd {\[vls]\[vpu]\[isDependOldVd]} 1
wbdp_pin vldMgu_0 vls_vpu_isWritePartVd {\[vls]\[vpu]\[isWritePartVd]} 1
wbdp_pin vldMgu_0 vls_vpu_isVleff {\[vls]\[vpu]\[isVleff]} 1
wbdp_pin vldMgu_0 vls_oldVdPsrc {\[vls]\[oldVdPsrc]} 8
wbdp_pin vldMgu_0 vls_vdIdx {\[vls]\[vdIdx]} 3
wbdp_pin vldMgu_0 vls_vdIdxInField {\[vls]\[vdIdxInField]} 3
wbdp_pin vldMgu_0 vls_isIndexed {\[vls]\[isIndexed]} 1
wbdp_pin vldMgu_0 vls_isMasked {\[vls]\[isMasked]} 1
wbdp_pin vldMgu_0 vls_isStrided {\[vls]\[isStrided]} 1
wbdp_pin vldMgu_0 vls_isWhole {\[vls]\[isWhole]} 1
wbdp_pin vldMgu_0 vls_isVecLoad {\[vls]\[isVecLoad]} 1
wbdp_pin vldMgu_0 vls_isVlm {\[vls]\[isVlm]} 1
wbdp_pin vldMgu_0 debug_isMMIO {\[debug]\[isMMIO]} 1
wbdp_pin vldMgu_0 debug_isNCIO {\[debug]\[isNCIO]} 1
wbdp_pin vldMgu_0 debug_isPerfCnt {\[debug]\[isPerfCnt]} 1
wbdp_pin vldMgu_0 debug_paddr {\[debug]\[paddr]} 48
wbdp_pin vldMgu_0 debug_vaddr {\[debug]\[vaddr]} 50
wbdp_pin vldMgu_0 debugInfo_eliminatedMove {\[debugInfo]\[eliminatedMove]} 1
wbdp_pin vldMgu_0 debugInfo_renameTime {\[debugInfo]\[renameTime]} 64
wbdp_pin vldMgu_0 debugInfo_dispatchTime {\[debugInfo]\[dispatchTime]} 64
wbdp_pin vldMgu_0 debugInfo_enqRsTime {\[debugInfo]\[enqRsTime]} 64
wbdp_pin vldMgu_0 debugInfo_selectTime {\[debugInfo]\[selectTime]} 64
wbdp_pin vldMgu_0 debugInfo_issueTime {\[debugInfo]\[issueTime]} 64
wbdp_pin vldMgu_0 debugInfo_writebackTime {\[debugInfo]\[writebackTime]} 64
wbdp_pin vldMgu_0 debugInfo_runahead_checkpoint_id {\[debugInfo]\[runahead_checkpoint_id]} 64
wbdp_pin vldMgu_0 debugInfo_tlbFirstReqTime {\[debugInfo]\[tlbFirstReqTime]} 64
wbdp_pin vldMgu_0 debugInfo_tlbRespTime {\[debugInfo]\[tlbRespTime]} 64
wbdp_pin vldMgu_0 debug_seqNum_seqNum {\[debug]\[seqNum]\[seqNum]} 56
wbdp_pin vldMgu_0 debug_seqNum_uopIdx {\[debug]\[seqNum]\[uopIdx]} 8
wbdp_pin vldMgu_1 data_0 {\[data_0]} 128
wbdp_pin vldMgu_1 pdest {\[pdest]} 7
wbdp_pin vldMgu_1 robIdx_flag {\[robIdx]\[flag]} 1
wbdp_pin vldMgu_1 robIdx_value {\[robIdx]\[value]} 8
wbdp_pin vldMgu_1 vecWen {\[vecWen]} 1
wbdp_pin vldMgu_1 v0Wen {\[v0Wen]} 1
wbdp_pin vldMgu_1 vlWen {\[vlWen]} 1
wbdp_pin vldMgu_1 exceptionVec_0 {\[exceptionVec][0]} 1
wbdp_pin vldMgu_1 exceptionVec_1 {\[exceptionVec][1]} 1
wbdp_pin vldMgu_1 exceptionVec_2 {\[exceptionVec][2]} 1
wbdp_pin vldMgu_1 exceptionVec_3 {\[exceptionVec][3]} 1
wbdp_pin vldMgu_1 exceptionVec_4 {\[exceptionVec][4]} 1
wbdp_pin vldMgu_1 exceptionVec_5 {\[exceptionVec][5]} 1
wbdp_pin vldMgu_1 exceptionVec_6 {\[exceptionVec][6]} 1
wbdp_pin vldMgu_1 exceptionVec_7 {\[exceptionVec][7]} 1
wbdp_pin vldMgu_1 exceptionVec_8 {\[exceptionVec][8]} 1
wbdp_pin vldMgu_1 exceptionVec_9 {\[exceptionVec][9]} 1
wbdp_pin vldMgu_1 exceptionVec_10 {\[exceptionVec][10]} 1
wbdp_pin vldMgu_1 exceptionVec_11 {\[exceptionVec][11]} 1
wbdp_pin vldMgu_1 exceptionVec_12 {\[exceptionVec][12]} 1
wbdp_pin vldMgu_1 exceptionVec_13 {\[exceptionVec][13]} 1
wbdp_pin vldMgu_1 exceptionVec_14 {\[exceptionVec][14]} 1
wbdp_pin vldMgu_1 exceptionVec_15 {\[exceptionVec][15]} 1
wbdp_pin vldMgu_1 exceptionVec_16 {\[exceptionVec][16]} 1
wbdp_pin vldMgu_1 exceptionVec_17 {\[exceptionVec][17]} 1
wbdp_pin vldMgu_1 exceptionVec_18 {\[exceptionVec][18]} 1
wbdp_pin vldMgu_1 exceptionVec_19 {\[exceptionVec][19]} 1
wbdp_pin vldMgu_1 exceptionVec_20 {\[exceptionVec][20]} 1
wbdp_pin vldMgu_1 exceptionVec_21 {\[exceptionVec][21]} 1
wbdp_pin vldMgu_1 exceptionVec_22 {\[exceptionVec][22]} 1
wbdp_pin vldMgu_1 exceptionVec_23 {\[exceptionVec][23]} 1
wbdp_pin vldMgu_1 flushPipe {\[flushPipe]} 1
wbdp_pin vldMgu_1 replay {\[replay]} 1
wbdp_pin vldMgu_1 trigger {\[trigger]} 4
wbdp_pin vldMgu_1 vls_vpu_vill {\[vls]\[vpu]\[vill]} 1
wbdp_pin vldMgu_1 vls_vpu_vma {\[vls]\[vpu]\[vma]} 1
wbdp_pin vldMgu_1 vls_vpu_vta {\[vls]\[vpu]\[vta]} 1
wbdp_pin vldMgu_1 vls_vpu_vsew {\[vls]\[vpu]\[vsew]} 2
wbdp_pin vldMgu_1 vls_vpu_vlmul {\[vls]\[vpu]\[vlmul]} 3
wbdp_pin vldMgu_1 vls_vpu_specVill {\[vls]\[vpu]\[specVill]} 1
wbdp_pin vldMgu_1 vls_vpu_specVma {\[vls]\[vpu]\[specVma]} 1
wbdp_pin vldMgu_1 vls_vpu_specVta {\[vls]\[vpu]\[specVta]} 1
wbdp_pin vldMgu_1 vls_vpu_specVsew {\[vls]\[vpu]\[specVsew]} 2
wbdp_pin vldMgu_1 vls_vpu_specVlmul {\[vls]\[vpu]\[specVlmul]} 3
wbdp_pin vldMgu_1 vls_vpu_vm {\[vls]\[vpu]\[vm]} 1
wbdp_pin vldMgu_1 vls_vpu_vstart {\[vls]\[vpu]\[vstart]} 8
wbdp_pin vldMgu_1 vls_vpu_frm {\[vls]\[vpu]\[frm]} 3
wbdp_pin vldMgu_1 vls_vpu_fpu_isFpToVecInst {\[vls]\[vpu]\[fpu]\[isFpToVecInst]} 1
wbdp_pin vldMgu_1 vls_vpu_fpu_isFP32Instr {\[vls]\[vpu]\[fpu]\[isFP32Instr]} 1
wbdp_pin vldMgu_1 vls_vpu_fpu_isFP64Instr {\[vls]\[vpu]\[fpu]\[isFP64Instr]} 1
wbdp_pin vldMgu_1 vls_vpu_fpu_isReduction {\[vls]\[vpu]\[fpu]\[isReduction]} 1
wbdp_pin vldMgu_1 vls_vpu_fpu_isFoldTo1_2 {\[vls]\[vpu]\[fpu]\[isFoldTo1_2]} 1
wbdp_pin vldMgu_1 vls_vpu_fpu_isFoldTo1_4 {\[vls]\[vpu]\[fpu]\[isFoldTo1_4]} 1
wbdp_pin vldMgu_1 vls_vpu_fpu_isFoldTo1_8 {\[vls]\[vpu]\[fpu]\[isFoldTo1_8]} 1
wbdp_pin vldMgu_1 vls_vpu_vxrm {\[vls]\[vpu]\[vxrm]} 2
wbdp_pin vldMgu_1 vls_vpu_vuopIdx {\[vls]\[vpu]\[vuopIdx]} 7
wbdp_pin vldMgu_1 vls_vpu_lastUop {\[vls]\[vpu]\[lastUop]} 1
wbdp_pin vldMgu_1 vls_vpu_vmask {\[vls]\[vpu]\[vmask]} 128
wbdp_pin vldMgu_1 vls_vpu_vl {\[vls]\[vpu]\[vl]} 8
wbdp_pin vldMgu_1 vls_vpu_nf {\[vls]\[vpu]\[nf]} 3
wbdp_pin vldMgu_1 vls_vpu_veew {\[vls]\[vpu]\[veew]} 2
wbdp_pin vldMgu_1 vls_vpu_isReverse {\[vls]\[vpu]\[isReverse]} 1
wbdp_pin vldMgu_1 vls_vpu_isExt {\[vls]\[vpu]\[isExt]} 1
wbdp_pin vldMgu_1 vls_vpu_isNarrow {\[vls]\[vpu]\[isNarrow]} 1
wbdp_pin vldMgu_1 vls_vpu_isDstMask {\[vls]\[vpu]\[isDstMask]} 1
wbdp_pin vldMgu_1 vls_vpu_isOpMask {\[vls]\[vpu]\[isOpMask]} 1
wbdp_pin vldMgu_1 vls_vpu_isMove {\[vls]\[vpu]\[isMove]} 1
wbdp_pin vldMgu_1 vls_vpu_isDependOldVd {\[vls]\[vpu]\[isDependOldVd]} 1
wbdp_pin vldMgu_1 vls_vpu_isWritePartVd {\[vls]\[vpu]\[isWritePartVd]} 1
wbdp_pin vldMgu_1 vls_vpu_isVleff {\[vls]\[vpu]\[isVleff]} 1
wbdp_pin vldMgu_1 vls_oldVdPsrc {\[vls]\[oldVdPsrc]} 8
wbdp_pin vldMgu_1 vls_vdIdx {\[vls]\[vdIdx]} 3
wbdp_pin vldMgu_1 vls_vdIdxInField {\[vls]\[vdIdxInField]} 3
wbdp_pin vldMgu_1 vls_isIndexed {\[vls]\[isIndexed]} 1
wbdp_pin vldMgu_1 vls_isMasked {\[vls]\[isMasked]} 1
wbdp_pin vldMgu_1 vls_isStrided {\[vls]\[isStrided]} 1
wbdp_pin vldMgu_1 vls_isWhole {\[vls]\[isWhole]} 1
wbdp_pin vldMgu_1 vls_isVecLoad {\[vls]\[isVecLoad]} 1
wbdp_pin vldMgu_1 vls_isVlm {\[vls]\[isVlm]} 1
wbdp_pin vldMgu_1 debug_isMMIO {\[debug]\[isMMIO]} 1
wbdp_pin vldMgu_1 debug_isNCIO {\[debug]\[isNCIO]} 1
wbdp_pin vldMgu_1 debug_isPerfCnt {\[debug]\[isPerfCnt]} 1
wbdp_pin vldMgu_1 debug_paddr {\[debug]\[paddr]} 48
wbdp_pin vldMgu_1 debug_vaddr {\[debug]\[vaddr]} 50
wbdp_pin vldMgu_1 debugInfo_eliminatedMove {\[debugInfo]\[eliminatedMove]} 1
wbdp_pin vldMgu_1 debugInfo_renameTime {\[debugInfo]\[renameTime]} 64
wbdp_pin vldMgu_1 debugInfo_dispatchTime {\[debugInfo]\[dispatchTime]} 64
wbdp_pin vldMgu_1 debugInfo_enqRsTime {\[debugInfo]\[enqRsTime]} 64
wbdp_pin vldMgu_1 debugInfo_selectTime {\[debugInfo]\[selectTime]} 64
wbdp_pin vldMgu_1 debugInfo_issueTime {\[debugInfo]\[issueTime]} 64
wbdp_pin vldMgu_1 debugInfo_writebackTime {\[debugInfo]\[writebackTime]} 64
wbdp_pin vldMgu_1 debugInfo_runahead_checkpoint_id {\[debugInfo]\[runahead_checkpoint_id]} 64
wbdp_pin vldMgu_1 debugInfo_tlbFirstReqTime {\[debugInfo]\[tlbFirstReqTime]} 64
wbdp_pin vldMgu_1 debugInfo_tlbRespTime {\[debugInfo]\[tlbRespTime]} 64
wbdp_pin vldMgu_1 debug_seqNum_seqNum {\[debug]\[seqNum]\[seqNum]} 56
wbdp_pin vldMgu_1 debug_seqNum_uopIdx {\[debug]\[seqNum]\[uopIdx]} 8
puts "WBDP_PIN_END WbDataPath ok=$::WBDP_PIN_OK bad=$::WBDP_PIN_BAD"
if {$::WBDP_PIN_BAD != 0} { error "WBDP_PIN_MISS=$::WBDP_PIN_BAD" }
if {$::WBDP_PIN_OK != 2268} { error "WBDP_PIN_COUNT=$::WBDP_PIN_OK expect=2268" }
