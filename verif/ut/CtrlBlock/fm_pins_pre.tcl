# ============================================================================
# fm_pins_pre.tcl -- CtrlBlock wbdelayed 窄寄存器**匹配前**全族双射钉点
# (codex 0127 Lane A; GENERATED -- DO NOT EDIT BY HAND)
#   regen: python3 scripts/gen_ctrlblock_pin_manifest.py --wbd \
#            --wbd-golden <golden>/CtrlBlock.sv \
#            --wbd-svh rtl/backend/ctrlblock_wbdelayed.svh \
#            --wbd-wbpack rtl/backend/ctrlblock_wbpack.svh \
#            --wbd-inventory verif/ut/CtrlBlock/wbdelayed_field_inventory.json \
#            --wbd-out-manifest verif/ut/CtrlBlock/ctrlblock_wbd_prepin_manifest.json \
#            --wbd-out-pretcl verif/ut/CtrlBlock/fm_pins_pre.tcl
# ----------------------------------------------------------------------------
# 为什么必须匹配前(FM_PIN_PRE_TCL): gate3(SGN-CtrlBlock-1786114121)实证, 窄化后
# 32 个 hold-clear 常数窄标量在 FM merge/常数配对 shuffle 下留 13 个 golden 侧
# lane-20 exceptionVec unmatched(compare_ref=13), impl 对象不再出现在 unmatched
# 池 => 匹配后 pin 机器(fm_pins.tcl)拿不到。user match 在首次 match 前钉全族 329
# 寄存器/5362 位, 先于 auto-match/merge, 双射确定性成立。
# 32 个 hold-clear 对: golden `r <= ~valid & r` vs impl RegEnable(valid, d=0)
# -- next-state 表达式形不同但函数相同(valid?0:self), FM 匹配后**实际比较**证明,
# 非 dont_verify/非 vmucp/非强配(两侧同为 Constrained-0X 常数)。
# bijection: ctrlblock_wbd_prepin_manifest.json (sha256 pairs=364229a011e82678c061f2e327dda31c4176981b6a809759ea1e3bb2cede0eeb)
# 运行时 fail-closed: 任一 set_user_match 失败或计数≠预期 => error 中止 gate
# (对象缺失=RTL/golden 漂移, 早停优于跑完得一个误导性 PARTIAL)。
# ============================================================================
proc ctrlblock_wbd_prepin { top } {
    # {golden_reg_base impl_wbd_base width} x 329
    set pairs {
        delayedNotFlushedWriteBack_delayed_bits_r_debugInfo_enqRsTime wbd0_debugInfo_enqRsTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_debugInfo_issueTime wbd0_debugInfo_issueTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_debugInfo_selectTime wbd0_debugInfo_selectTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_robIdx_value wbd0_robIdx_value 8
        delayedNotFlushedWriteBack_delayed_bits_r_1_debugInfo_enqRsTime wbd1_debugInfo_enqRsTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_1_debugInfo_issueTime wbd1_debugInfo_issueTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_1_debugInfo_selectTime wbd1_debugInfo_selectTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_1_redirect_bits_cfiUpdate_isMisPred wbd1_redirect_bits_cfiUpdate_isMisPred 1
        delayedNotFlushedWriteBack_delayed_bits_r_1_redirect_bits_cfiUpdate_taken wbd1_redirect_bits_cfiUpdate_taken 1
        delayedNotFlushedWriteBack_delayed_bits_r_1_redirect_valid wbd1_redirect_valid 1
        delayedNotFlushedWriteBack_delayed_bits_r_1_robIdx_value wbd1_robIdx_value 8
        delayedNotFlushedWriteBack_delayed_bits_r_2_debugInfo_enqRsTime wbd2_debugInfo_enqRsTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_2_debugInfo_issueTime wbd2_debugInfo_issueTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_2_debugInfo_selectTime wbd2_debugInfo_selectTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_2_robIdx_value wbd2_robIdx_value 8
        delayedNotFlushedWriteBack_delayed_bits_r_3_debugInfo_enqRsTime wbd3_debugInfo_enqRsTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_3_debugInfo_issueTime wbd3_debugInfo_issueTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_3_debugInfo_selectTime wbd3_debugInfo_selectTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_3_redirect_bits_cfiUpdate_isMisPred wbd3_redirect_bits_cfiUpdate_isMisPred 1
        delayedNotFlushedWriteBack_delayed_bits_r_3_redirect_bits_cfiUpdate_taken wbd3_redirect_bits_cfiUpdate_taken 1
        delayedNotFlushedWriteBack_delayed_bits_r_3_redirect_valid wbd3_redirect_valid 1
        delayedNotFlushedWriteBack_delayed_bits_r_3_robIdx_value wbd3_robIdx_value 8
        delayedNotFlushedWriteBack_delayed_bits_r_4_debugInfo_enqRsTime wbd4_debugInfo_enqRsTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_4_debugInfo_issueTime wbd4_debugInfo_issueTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_4_debugInfo_selectTime wbd4_debugInfo_selectTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_4_robIdx_value wbd4_robIdx_value 8
        delayedNotFlushedWriteBack_delayed_bits_r_5_debugInfo_enqRsTime wbd5_debugInfo_enqRsTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_5_debugInfo_issueTime wbd5_debugInfo_issueTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_5_debugInfo_selectTime wbd5_debugInfo_selectTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_5_fflags wbd5_fflags 5
        delayedNotFlushedWriteBack_delayed_bits_r_5_redirect_bits_cfiUpdate_isMisPred wbd5_redirect_bits_cfiUpdate_isMisPred 1
        delayedNotFlushedWriteBack_delayed_bits_r_5_redirect_bits_cfiUpdate_taken wbd5_redirect_bits_cfiUpdate_taken 1
        delayedNotFlushedWriteBack_delayed_bits_r_5_redirect_valid wbd5_redirect_valid 1
        delayedNotFlushedWriteBack_delayed_bits_r_5_robIdx_value wbd5_robIdx_value 8
        delayedNotFlushedWriteBack_delayed_bits_r_5_wflags wbd5_wflags 1
        delayedNotFlushedWriteBack_delayed_bits_r_6_debugInfo_enqRsTime wbd6_debugInfo_enqRsTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_6_debugInfo_issueTime wbd6_debugInfo_issueTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_6_debugInfo_selectTime wbd6_debugInfo_selectTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_6_robIdx_value wbd6_robIdx_value 8
        delayedNotFlushedWriteBack_delayed_bits_r_7_debugInfo_enqRsTime wbd7_debugInfo_enqRsTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_7_debugInfo_issueTime wbd7_debugInfo_issueTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_7_debugInfo_selectTime wbd7_debugInfo_selectTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_7_debug_isPerfCnt wbd7_debug_isPerfCnt 1
        delayedNotFlushedWriteBack_delayed_bits_r_7_exceptionVec_10 wbd7_exceptionVec_10 1
        delayedNotFlushedWriteBack_delayed_bits_r_7_exceptionVec_11 wbd7_exceptionVec_11 1
        delayedNotFlushedWriteBack_delayed_bits_r_7_exceptionVec_2 wbd7_exceptionVec_2 1
        delayedNotFlushedWriteBack_delayed_bits_r_7_exceptionVec_22 wbd7_exceptionVec_22 1
        delayedNotFlushedWriteBack_delayed_bits_r_7_exceptionVec_3 wbd7_exceptionVec_3 1
        delayedNotFlushedWriteBack_delayed_bits_r_7_exceptionVec_8 wbd7_exceptionVec_8 1
        delayedNotFlushedWriteBack_delayed_bits_r_7_exceptionVec_9 wbd7_exceptionVec_9 1
        delayedNotFlushedWriteBack_delayed_bits_r_7_flushPipe wbd7_flushPipe 1
        delayedNotFlushedWriteBack_delayed_bits_r_7_redirect_bits_cfiUpdate_isMisPred wbd7_redirect_bits_cfiUpdate_isMisPred 1
        delayedNotFlushedWriteBack_delayed_bits_r_7_redirect_valid wbd7_redirect_valid 1
        delayedNotFlushedWriteBack_delayed_bits_r_7_robIdx_flag wbd7_robIdx_flag 1
        delayedNotFlushedWriteBack_delayed_bits_r_7_robIdx_value wbd7_robIdx_value 8
        delayedNotFlushedWriteBack_delayed_bits_r_8_debugInfo_enqRsTime wbd8_debugInfo_enqRsTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_8_debugInfo_issueTime wbd8_debugInfo_issueTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_8_debugInfo_selectTime wbd8_debugInfo_selectTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_8_fflags wbd8_fflags 5
        delayedNotFlushedWriteBack_delayed_bits_r_8_robIdx_value wbd8_robIdx_value 8
        delayedNotFlushedWriteBack_delayed_bits_r_8_wflags wbd8_wflags 1
        delayedNotFlushedWriteBack_delayed_bits_r_9_debugInfo_enqRsTime wbd9_debugInfo_enqRsTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_9_debugInfo_issueTime wbd9_debugInfo_issueTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_9_debugInfo_selectTime wbd9_debugInfo_selectTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_9_fflags wbd9_fflags 5
        delayedNotFlushedWriteBack_delayed_bits_r_9_robIdx_value wbd9_robIdx_value 8
        delayedNotFlushedWriteBack_delayed_bits_r_9_wflags wbd9_wflags 1
        delayedNotFlushedWriteBack_delayed_bits_r_10_debugInfo_enqRsTime wbd10_debugInfo_enqRsTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_10_debugInfo_issueTime wbd10_debugInfo_issueTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_10_debugInfo_selectTime wbd10_debugInfo_selectTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_10_fflags wbd10_fflags 5
        delayedNotFlushedWriteBack_delayed_bits_r_10_robIdx_value wbd10_robIdx_value 8
        delayedNotFlushedWriteBack_delayed_bits_r_10_wflags wbd10_wflags 1
        delayedNotFlushedWriteBack_delayed_bits_r_11_debugInfo_enqRsTime wbd11_debugInfo_enqRsTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_11_debugInfo_issueTime wbd11_debugInfo_issueTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_11_debugInfo_selectTime wbd11_debugInfo_selectTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_11_fflags wbd11_fflags 5
        delayedNotFlushedWriteBack_delayed_bits_r_11_robIdx_value wbd11_robIdx_value 8
        delayedNotFlushedWriteBack_delayed_bits_r_11_wflags wbd11_wflags 1
        delayedNotFlushedWriteBack_delayed_bits_r_12_debugInfo_enqRsTime wbd12_debugInfo_enqRsTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_12_debugInfo_issueTime wbd12_debugInfo_issueTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_12_debugInfo_selectTime wbd12_debugInfo_selectTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_12_fflags wbd12_fflags 5
        delayedNotFlushedWriteBack_delayed_bits_r_12_robIdx_value wbd12_robIdx_value 8
        delayedNotFlushedWriteBack_delayed_bits_r_12_wflags wbd12_wflags 1
        delayedNotFlushedWriteBack_delayed_bits_r_13_debugInfo_enqRsTime wbd13_debugInfo_enqRsTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_13_debugInfo_issueTime wbd13_debugInfo_issueTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_13_debugInfo_selectTime wbd13_debugInfo_selectTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_13_exceptionVec_2 wbd13_exceptionVec_2 1
        delayedNotFlushedWriteBack_delayed_bits_r_13_fflags wbd13_fflags 5
        delayedNotFlushedWriteBack_delayed_bits_r_13_robIdx_flag wbd13_robIdx_flag 1
        delayedNotFlushedWriteBack_delayed_bits_r_13_robIdx_value wbd13_robIdx_value 8
        delayedNotFlushedWriteBack_delayed_bits_r_13_vxsat wbd13_vxsat 1
        delayedNotFlushedWriteBack_delayed_bits_r_13_wflags wbd13_wflags 1
        delayedNotFlushedWriteBack_delayed_bits_r_14_debugInfo_enqRsTime wbd14_debugInfo_enqRsTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_14_debugInfo_issueTime wbd14_debugInfo_issueTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_14_debugInfo_selectTime wbd14_debugInfo_selectTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_14_exceptionVec_2 wbd14_exceptionVec_2 1
        delayedNotFlushedWriteBack_delayed_bits_r_14_fflags wbd14_fflags 5
        delayedNotFlushedWriteBack_delayed_bits_r_14_robIdx_flag wbd14_robIdx_flag 1
        delayedNotFlushedWriteBack_delayed_bits_r_14_robIdx_value wbd14_robIdx_value 8
        delayedNotFlushedWriteBack_delayed_bits_r_14_wflags wbd14_wflags 1
        delayedNotFlushedWriteBack_delayed_bits_r_15_debugInfo_enqRsTime wbd15_debugInfo_enqRsTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_15_debugInfo_issueTime wbd15_debugInfo_issueTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_15_debugInfo_selectTime wbd15_debugInfo_selectTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_15_fflags wbd15_fflags 5
        delayedNotFlushedWriteBack_delayed_bits_r_15_robIdx_flag wbd15_robIdx_flag 1
        delayedNotFlushedWriteBack_delayed_bits_r_15_robIdx_value wbd15_robIdx_value 8
        delayedNotFlushedWriteBack_delayed_bits_r_15_vxsat wbd15_vxsat 1
        delayedNotFlushedWriteBack_delayed_bits_r_15_wflags wbd15_wflags 1
        delayedNotFlushedWriteBack_delayed_bits_r_16_debugInfo_enqRsTime wbd16_debugInfo_enqRsTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_16_debugInfo_issueTime wbd16_debugInfo_issueTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_16_debugInfo_selectTime wbd16_debugInfo_selectTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_16_fflags wbd16_fflags 5
        delayedNotFlushedWriteBack_delayed_bits_r_16_robIdx_flag wbd16_robIdx_flag 1
        delayedNotFlushedWriteBack_delayed_bits_r_16_robIdx_value wbd16_robIdx_value 8
        delayedNotFlushedWriteBack_delayed_bits_r_16_wflags wbd16_wflags 1
        delayedNotFlushedWriteBack_delayed_bits_r_17_debugInfo_enqRsTime wbd17_debugInfo_enqRsTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_17_debugInfo_issueTime wbd17_debugInfo_issueTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_17_debugInfo_selectTime wbd17_debugInfo_selectTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_17_fflags wbd17_fflags 5
        delayedNotFlushedWriteBack_delayed_bits_r_17_robIdx_flag wbd17_robIdx_flag 1
        delayedNotFlushedWriteBack_delayed_bits_r_17_robIdx_value wbd17_robIdx_value 8
        delayedNotFlushedWriteBack_delayed_bits_r_17_wflags wbd17_wflags 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_debugInfo_enqRsTime wbd18_debugInfo_enqRsTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_18_debugInfo_issueTime wbd18_debugInfo_issueTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_18_debugInfo_selectTime wbd18_debugInfo_selectTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_18_debug_isMMIO wbd18_debug_isMMIO 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_debug_isNCIO wbd18_debug_isNCIO 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_debug_isPerfCnt wbd18_debug_isPerfCnt 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_exceptionVec_0 wbd18_exceptionVec_0 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_exceptionVec_1 wbd18_exceptionVec_1 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_exceptionVec_10 wbd18_exceptionVec_10 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_exceptionVec_11 wbd18_exceptionVec_11 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_exceptionVec_12 wbd18_exceptionVec_12 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_exceptionVec_13 wbd18_exceptionVec_13 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_exceptionVec_14 wbd18_exceptionVec_14 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_exceptionVec_15 wbd18_exceptionVec_15 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_exceptionVec_16 wbd18_exceptionVec_16 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_exceptionVec_17 wbd18_exceptionVec_17 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_exceptionVec_18 wbd18_exceptionVec_18 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_exceptionVec_19 wbd18_exceptionVec_19 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_exceptionVec_2 wbd18_exceptionVec_2 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_exceptionVec_20 wbd18_exceptionVec_20 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_exceptionVec_21 wbd18_exceptionVec_21 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_exceptionVec_22 wbd18_exceptionVec_22 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_exceptionVec_23 wbd18_exceptionVec_23 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_exceptionVec_3 wbd18_exceptionVec_3 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_exceptionVec_4 wbd18_exceptionVec_4 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_exceptionVec_5 wbd18_exceptionVec_5 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_exceptionVec_6 wbd18_exceptionVec_6 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_exceptionVec_7 wbd18_exceptionVec_7 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_exceptionVec_8 wbd18_exceptionVec_8 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_exceptionVec_9 wbd18_exceptionVec_9 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_flushPipe wbd18_flushPipe 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_robIdx_flag wbd18_robIdx_flag 1
        delayedNotFlushedWriteBack_delayed_bits_r_18_robIdx_value wbd18_robIdx_value 8
        delayedNotFlushedWriteBack_delayed_bits_r_18_trigger wbd18_trigger 4
        delayedNotFlushedWriteBack_delayed_bits_r_19_debugInfo_enqRsTime wbd19_debugInfo_enqRsTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_19_debugInfo_issueTime wbd19_debugInfo_issueTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_19_debugInfo_selectTime wbd19_debugInfo_selectTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_19_debug_isMMIO wbd19_debug_isMMIO 1
        delayedNotFlushedWriteBack_delayed_bits_r_19_debug_isNCIO wbd19_debug_isNCIO 1
        delayedNotFlushedWriteBack_delayed_bits_r_19_exceptionVec_15 wbd19_exceptionVec_15 1
        delayedNotFlushedWriteBack_delayed_bits_r_19_exceptionVec_19 wbd19_exceptionVec_19 1
        delayedNotFlushedWriteBack_delayed_bits_r_19_exceptionVec_23 wbd19_exceptionVec_23 1
        delayedNotFlushedWriteBack_delayed_bits_r_19_exceptionVec_3 wbd19_exceptionVec_3 1
        delayedNotFlushedWriteBack_delayed_bits_r_19_exceptionVec_6 wbd19_exceptionVec_6 1
        delayedNotFlushedWriteBack_delayed_bits_r_19_exceptionVec_7 wbd19_exceptionVec_7 1
        delayedNotFlushedWriteBack_delayed_bits_r_19_robIdx_flag wbd19_robIdx_flag 1
        delayedNotFlushedWriteBack_delayed_bits_r_19_robIdx_value wbd19_robIdx_value 8
        delayedNotFlushedWriteBack_delayed_bits_r_19_trigger wbd19_trigger 4
        delayedNotFlushedWriteBack_delayed_bits_r_20_debugInfo_enqRsTime wbd20_debugInfo_enqRsTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_20_debugInfo_issueTime wbd20_debugInfo_issueTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_20_debugInfo_selectTime wbd20_debugInfo_selectTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_20_debug_isMMIO wbd20_debug_isMMIO 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_debug_isNCIO wbd20_debug_isNCIO 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_debug_isPerfCnt wbd20_debug_isPerfCnt 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_exceptionVec_0 wbd20_exceptionVec_0 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_exceptionVec_1 wbd20_exceptionVec_1 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_exceptionVec_10 wbd20_exceptionVec_10 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_exceptionVec_11 wbd20_exceptionVec_11 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_exceptionVec_12 wbd20_exceptionVec_12 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_exceptionVec_13 wbd20_exceptionVec_13 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_exceptionVec_14 wbd20_exceptionVec_14 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_exceptionVec_15 wbd20_exceptionVec_15 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_exceptionVec_16 wbd20_exceptionVec_16 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_exceptionVec_17 wbd20_exceptionVec_17 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_exceptionVec_18 wbd20_exceptionVec_18 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_exceptionVec_19 wbd20_exceptionVec_19 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_exceptionVec_2 wbd20_exceptionVec_2 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_exceptionVec_20 wbd20_exceptionVec_20 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_exceptionVec_21 wbd20_exceptionVec_21 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_exceptionVec_22 wbd20_exceptionVec_22 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_exceptionVec_23 wbd20_exceptionVec_23 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_exceptionVec_3 wbd20_exceptionVec_3 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_exceptionVec_4 wbd20_exceptionVec_4 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_exceptionVec_5 wbd20_exceptionVec_5 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_exceptionVec_6 wbd20_exceptionVec_6 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_exceptionVec_7 wbd20_exceptionVec_7 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_exceptionVec_8 wbd20_exceptionVec_8 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_exceptionVec_9 wbd20_exceptionVec_9 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_flushPipe wbd20_flushPipe 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_replay wbd20_replay 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_robIdx_flag wbd20_robIdx_flag 1
        delayedNotFlushedWriteBack_delayed_bits_r_20_robIdx_value wbd20_robIdx_value 8
        delayedNotFlushedWriteBack_delayed_bits_r_20_trigger wbd20_trigger 4
        delayedNotFlushedWriteBack_delayed_bits_r_21_debugInfo_enqRsTime wbd21_debugInfo_enqRsTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_21_debugInfo_issueTime wbd21_debugInfo_issueTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_21_debugInfo_selectTime wbd21_debugInfo_selectTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_21_debug_isMMIO wbd21_debug_isMMIO 1
        delayedNotFlushedWriteBack_delayed_bits_r_21_debug_isNCIO wbd21_debug_isNCIO 1
        delayedNotFlushedWriteBack_delayed_bits_r_21_debug_isPerfCnt wbd21_debug_isPerfCnt 1
        delayedNotFlushedWriteBack_delayed_bits_r_21_exceptionVec_13 wbd21_exceptionVec_13 1
        delayedNotFlushedWriteBack_delayed_bits_r_21_exceptionVec_19 wbd21_exceptionVec_19 1
        delayedNotFlushedWriteBack_delayed_bits_r_21_exceptionVec_21 wbd21_exceptionVec_21 1
        delayedNotFlushedWriteBack_delayed_bits_r_21_exceptionVec_3 wbd21_exceptionVec_3 1
        delayedNotFlushedWriteBack_delayed_bits_r_21_exceptionVec_4 wbd21_exceptionVec_4 1
        delayedNotFlushedWriteBack_delayed_bits_r_21_exceptionVec_5 wbd21_exceptionVec_5 1
        delayedNotFlushedWriteBack_delayed_bits_r_21_flushPipe wbd21_flushPipe 1
        delayedNotFlushedWriteBack_delayed_bits_r_21_replay wbd21_replay 1
        delayedNotFlushedWriteBack_delayed_bits_r_21_robIdx_flag wbd21_robIdx_flag 1
        delayedNotFlushedWriteBack_delayed_bits_r_21_robIdx_value wbd21_robIdx_value 8
        delayedNotFlushedWriteBack_delayed_bits_r_21_trigger wbd21_trigger 4
        delayedNotFlushedWriteBack_delayed_bits_r_22_debugInfo_enqRsTime wbd22_debugInfo_enqRsTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_22_debugInfo_issueTime wbd22_debugInfo_issueTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_22_debugInfo_selectTime wbd22_debugInfo_selectTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_22_debug_isMMIO wbd22_debug_isMMIO 1
        delayedNotFlushedWriteBack_delayed_bits_r_22_debug_isNCIO wbd22_debug_isNCIO 1
        delayedNotFlushedWriteBack_delayed_bits_r_22_debug_isPerfCnt wbd22_debug_isPerfCnt 1
        delayedNotFlushedWriteBack_delayed_bits_r_22_exceptionVec_13 wbd22_exceptionVec_13 1
        delayedNotFlushedWriteBack_delayed_bits_r_22_exceptionVec_19 wbd22_exceptionVec_19 1
        delayedNotFlushedWriteBack_delayed_bits_r_22_exceptionVec_21 wbd22_exceptionVec_21 1
        delayedNotFlushedWriteBack_delayed_bits_r_22_exceptionVec_3 wbd22_exceptionVec_3 1
        delayedNotFlushedWriteBack_delayed_bits_r_22_exceptionVec_4 wbd22_exceptionVec_4 1
        delayedNotFlushedWriteBack_delayed_bits_r_22_exceptionVec_5 wbd22_exceptionVec_5 1
        delayedNotFlushedWriteBack_delayed_bits_r_22_flushPipe wbd22_flushPipe 1
        delayedNotFlushedWriteBack_delayed_bits_r_22_replay wbd22_replay 1
        delayedNotFlushedWriteBack_delayed_bits_r_22_robIdx_flag wbd22_robIdx_flag 1
        delayedNotFlushedWriteBack_delayed_bits_r_22_robIdx_value wbd22_robIdx_value 8
        delayedNotFlushedWriteBack_delayed_bits_r_22_trigger wbd22_trigger 4
        delayedNotFlushedWriteBack_delayed_bits_r_23_debugInfo_enqRsTime wbd23_debugInfo_enqRsTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_23_debugInfo_issueTime wbd23_debugInfo_issueTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_23_debugInfo_selectTime wbd23_debugInfo_selectTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_23_debug_isMMIO wbd23_debug_isMMIO 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_debug_isNCIO wbd23_debug_isNCIO 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_debug_isPerfCnt wbd23_debug_isPerfCnt 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_exceptionVec_0 wbd23_exceptionVec_0 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_exceptionVec_1 wbd23_exceptionVec_1 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_exceptionVec_10 wbd23_exceptionVec_10 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_exceptionVec_11 wbd23_exceptionVec_11 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_exceptionVec_12 wbd23_exceptionVec_12 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_exceptionVec_13 wbd23_exceptionVec_13 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_exceptionVec_14 wbd23_exceptionVec_14 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_exceptionVec_15 wbd23_exceptionVec_15 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_exceptionVec_16 wbd23_exceptionVec_16 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_exceptionVec_17 wbd23_exceptionVec_17 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_exceptionVec_18 wbd23_exceptionVec_18 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_exceptionVec_19 wbd23_exceptionVec_19 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_exceptionVec_2 wbd23_exceptionVec_2 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_exceptionVec_20 wbd23_exceptionVec_20 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_exceptionVec_21 wbd23_exceptionVec_21 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_exceptionVec_22 wbd23_exceptionVec_22 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_exceptionVec_23 wbd23_exceptionVec_23 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_exceptionVec_3 wbd23_exceptionVec_3 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_exceptionVec_4 wbd23_exceptionVec_4 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_exceptionVec_5 wbd23_exceptionVec_5 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_exceptionVec_6 wbd23_exceptionVec_6 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_exceptionVec_7 wbd23_exceptionVec_7 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_exceptionVec_8 wbd23_exceptionVec_8 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_exceptionVec_9 wbd23_exceptionVec_9 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_flushPipe wbd23_flushPipe 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_pdest wbd23_pdest 7
        delayedNotFlushedWriteBack_delayed_bits_r_23_replay wbd23_replay 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_robIdx_flag wbd23_robIdx_flag 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_robIdx_value wbd23_robIdx_value 8
        delayedNotFlushedWriteBack_delayed_bits_r_23_trigger wbd23_trigger 4
        delayedNotFlushedWriteBack_delayed_bits_r_23_v0Wen wbd23_v0Wen 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_vecWen wbd23_vecWen 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_vls_isIndexed wbd23_vls_isIndexed 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_vls_isStrided wbd23_vls_isStrided 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_vls_isVecLoad wbd23_vls_isVecLoad 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_vls_isVlm wbd23_vls_isVlm 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_vls_isWhole wbd23_vls_isWhole 1
        delayedNotFlushedWriteBack_delayed_bits_r_23_vls_vdIdx wbd23_vls_vdIdx 3
        delayedNotFlushedWriteBack_delayed_bits_r_23_vls_vpu_nf wbd23_vls_vpu_nf 3
        delayedNotFlushedWriteBack_delayed_bits_r_23_vls_vpu_veew wbd23_vls_vpu_veew 2
        delayedNotFlushedWriteBack_delayed_bits_r_23_vls_vpu_vlmul wbd23_vls_vpu_vlmul 3
        delayedNotFlushedWriteBack_delayed_bits_r_23_vls_vpu_vsew wbd23_vls_vpu_vsew 2
        delayedNotFlushedWriteBack_delayed_bits_r_23_vls_vpu_vstart wbd23_vls_vpu_vstart 8
        delayedNotFlushedWriteBack_delayed_bits_r_23_vls_vpu_vuopIdx wbd23_vls_vpu_vuopIdx 7
        delayedNotFlushedWriteBack_delayed_bits_r_24_debugInfo_enqRsTime wbd24_debugInfo_enqRsTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_24_debugInfo_issueTime wbd24_debugInfo_issueTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_24_debugInfo_selectTime wbd24_debugInfo_selectTime 64
        delayedNotFlushedWriteBack_delayed_bits_r_24_debug_isMMIO wbd24_debug_isMMIO 1
        delayedNotFlushedWriteBack_delayed_bits_r_24_debug_isNCIO wbd24_debug_isNCIO 1
        delayedNotFlushedWriteBack_delayed_bits_r_24_debug_isPerfCnt wbd24_debug_isPerfCnt 1
        delayedNotFlushedWriteBack_delayed_bits_r_24_exceptionVec_13 wbd24_exceptionVec_13 1
        delayedNotFlushedWriteBack_delayed_bits_r_24_exceptionVec_15 wbd24_exceptionVec_15 1
        delayedNotFlushedWriteBack_delayed_bits_r_24_exceptionVec_19 wbd24_exceptionVec_19 1
        delayedNotFlushedWriteBack_delayed_bits_r_24_exceptionVec_21 wbd24_exceptionVec_21 1
        delayedNotFlushedWriteBack_delayed_bits_r_24_exceptionVec_23 wbd24_exceptionVec_23 1
        delayedNotFlushedWriteBack_delayed_bits_r_24_exceptionVec_3 wbd24_exceptionVec_3 1
        delayedNotFlushedWriteBack_delayed_bits_r_24_exceptionVec_4 wbd24_exceptionVec_4 1
        delayedNotFlushedWriteBack_delayed_bits_r_24_exceptionVec_5 wbd24_exceptionVec_5 1
        delayedNotFlushedWriteBack_delayed_bits_r_24_exceptionVec_6 wbd24_exceptionVec_6 1
        delayedNotFlushedWriteBack_delayed_bits_r_24_exceptionVec_7 wbd24_exceptionVec_7 1
        delayedNotFlushedWriteBack_delayed_bits_r_24_flushPipe wbd24_flushPipe 1
        delayedNotFlushedWriteBack_delayed_bits_r_24_pdest wbd24_pdest 7
        delayedNotFlushedWriteBack_delayed_bits_r_24_replay wbd24_replay 1
        delayedNotFlushedWriteBack_delayed_bits_r_24_robIdx_flag wbd24_robIdx_flag 1
        delayedNotFlushedWriteBack_delayed_bits_r_24_robIdx_value wbd24_robIdx_value 8
        delayedNotFlushedWriteBack_delayed_bits_r_24_trigger wbd24_trigger 4
        delayedNotFlushedWriteBack_delayed_bits_r_24_v0Wen wbd24_v0Wen 1
        delayedNotFlushedWriteBack_delayed_bits_r_24_vecWen wbd24_vecWen 1
        delayedNotFlushedWriteBack_delayed_bits_r_24_vls_isIndexed wbd24_vls_isIndexed 1
        delayedNotFlushedWriteBack_delayed_bits_r_24_vls_isStrided wbd24_vls_isStrided 1
        delayedNotFlushedWriteBack_delayed_bits_r_24_vls_isVecLoad wbd24_vls_isVecLoad 1
        delayedNotFlushedWriteBack_delayed_bits_r_24_vls_isVlm wbd24_vls_isVlm 1
        delayedNotFlushedWriteBack_delayed_bits_r_24_vls_isWhole wbd24_vls_isWhole 1
        delayedNotFlushedWriteBack_delayed_bits_r_24_vls_vdIdx wbd24_vls_vdIdx 3
        delayedNotFlushedWriteBack_delayed_bits_r_24_vls_vpu_nf wbd24_vls_vpu_nf 3
        delayedNotFlushedWriteBack_delayed_bits_r_24_vls_vpu_veew wbd24_vls_vpu_veew 2
        delayedNotFlushedWriteBack_delayed_bits_r_24_vls_vpu_vlmul wbd24_vls_vpu_vlmul 3
        delayedNotFlushedWriteBack_delayed_bits_r_24_vls_vpu_vsew wbd24_vls_vpu_vsew 2
        delayedNotFlushedWriteBack_delayed_bits_r_24_vls_vpu_vstart wbd24_vls_vpu_vstart 8
        delayedNotFlushedWriteBack_delayed_bits_r_24_vls_vpu_vuopIdx wbd24_vls_vpu_vuopIdx 7
        delayedNotFlushedWriteBack_delayed_bits_r_25_robIdx_value wbd25_robIdx_value 8
        delayedNotFlushedWriteBack_delayed_bits_r_26_robIdx_value wbd26_robIdx_value 8
    }
    set n 0
    set fails 0
    foreach {rb ib w} $pairs {
        for {set b 0} {$b < $w} {incr b} {
            if {$w == 1} {
                set rp "r:/WORK/${top}/${rb}_reg"
                set ip "i:/WORK/${top}/u_core/${ib}_reg"
            } else {
                set rp "r:/WORK/${top}/${rb}_reg\[$b\]"
                set ip "i:/WORK/${top}/u_core/${ib}_reg\[$b\]"
            }
            if {[catch {set_user_match $rp $ip} msg]} {
                incr fails
                puts "CTRLBLOCK_WBD_PREPIN_FAIL: $rp <-> $ip ($msg)"
            } else {
                incr n
            }
        }
    }
    puts "CTRLBLOCK_WBD_PREPIN: $n pinned, $fails failed (expect 5362/0)"
    if {$fails != 0 || $n != 5362} {
        error "CTRLBLOCK_WBD_PREPIN_FAIL: n=$n fails=$fails expect=5362/0 (wbd 双射破; 中止 gate)"
    }
}
ctrlblock_wbd_prepin $top
