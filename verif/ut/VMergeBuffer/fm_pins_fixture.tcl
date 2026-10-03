# VARIANTS: VLMergeBufferImp VSMergeBufferImp
# ---------------------------------------------------------------------------
# VMergeBuffer 钉点文件（fm_pins.tcl，「匹配后」）的**夹具**（scripts/pin_call_equiv.py 用，
# 不参与 FM 跑）。见 TLBFA/fm_pins_fixture.tcl 头部关于"为什么动态文件需要夹具"的说明。
# 同目录 fm_pins_pre.tcl 是静态的（1023×出队口数 的字面表），不调查询动词，本夹具对它无影响。
#
# ★点集来源★：这里固定的是**真实 FM 在签核跑里返回的未匹配点集合**（两侧各 18807 /
# 17584，= 钉点文件里写死的 expect）。它不是能从 golden 寄存器声明直接推出的"全部"——
# 有一部分位被 FM 按名/签名配上了，剩下的才进未匹配（例如 VL 的 brodenMergeDataReg_2
# 只剩 [248..255]、latchFlowNum_reg 只剩 [1]）。所以本表由真实 fm.log 的
# "Set a match" 回显机械压缩得来（逐对 = 一行 ref/impl 基名 + 位区间 + 条目下标区间），
# 再展开后与回显逐条比对：
#   evidence/a16cbfcc0c1d/{VLMergeBufferImp,VSMergeBufferImp}/fm.log
#   VL 18807 条 / VS 17584 条 —— 桩序列与回显逐字节相同。
#
# 行格式：{ref 基名} {impl 相对 u_core 的基名} 位 下标
#   ref  = r:/WORK/<top>/<ref 基名>[<b>]     impl = i:/WORK/<top>/u_core/<impl 基名>[<b>]
#   %i   = 条目/口下标占位；位 '-' = 1 位寄存器（无 [b]），否则是区间串（a-b 或 {a-b c}）；
#   下标 '-' = 基名里没有下标，否则同为区间串。
# impl 名里的 `g_data_merge.` 是可读核 generate 块前缀（钉点文件 _mb_leaf 去掉它取叶名）。
#
# ★已知局限（如实写出）★：钉点文件把 `report_unmatched_points -list` 与
# `... -status unread -list` 两份报告 concat 后再 lsort -unique，fm.log 不回显这两份
# 报告各自的内容，所以本夹具把全集放在默认报告里、unread 报告返回空。对调用序列没有
# 影响（concat+去重后集合相同），但意味着"删掉 unread 那一路查询"这种改动本夹具判不红。
# ---------------------------------------------------------------------------
set _FX_MB_TAB {
    VLMergeBufferImp {
        {{brodenMergeDataReg_%i_reg} {g_data_merge.brodenMergeDataReg_reg[%i]} 0-255 1}
        {{brodenMergeDataReg_%i_reg} {g_data_merge.brodenMergeDataReg_reg[%i]} 248-255 2}
        {{brodenMergeDataReg_reg} {g_data_merge.brodenMergeDataReg_reg[0]} 0-255 -}
        {{brodenMergeMaskReg_%i_reg} {g_data_merge.brodenMergeMaskReg_reg[%i]} 0-31 1}
        {{brodenMergeMaskReg_%i_reg} {g_data_merge.brodenMergeMaskReg_reg[%i]} 31 2}
        {{brodenMergeMaskReg_reg} {g_data_merge.brodenMergeMaskReg_reg[0]} 0-31 -}
        {{entries_%i_data_reg} {entries_data_reg[%i]} 0-127 0-15}
        {{entries_%i_elemIdx_reg} {entries_elemIdx_reg[%i]} 0-7 0-15}
        {{entries_%i_exceptionVec_13_reg} {entries_exceptionVec_reg[%i][3]} - 0-15}
        {{entries_%i_exceptionVec_19_reg} {entries_exceptionVec_reg[%i][4]} - 0-15}
        {{entries_%i_exceptionVec_21_reg} {entries_exceptionVec_reg[%i][5]} - 0-15}
        {{entries_%i_exceptionVec_3_reg} {entries_exceptionVec_reg[%i][0]} - 0-15}
        {{entries_%i_exceptionVec_4_reg} {entries_exceptionVec_reg[%i][1]} - 0-15}
        {{entries_%i_exceptionVec_5_reg} {entries_exceptionVec_reg[%i][2]} - 0-15}
        {{entries_%i_flowNum_reg} {entries_flowNum_reg[%i]} 0-4 0-15}
        {{entries_%i_flushState_reg} {entries_flushState_reg[%i]} - 0-15}
        {{entries_%i_fof_reg} {entries_fof_reg[%i]} - 0-15}
        {{entries_%i_gpaddr_reg} {entries_gpaddr_reg[%i]} 0-63 0-15}
        {{entries_%i_isForVSnonLeafPTE_reg} {entries_isForVSnonLeafPTE_reg[%i]} - 0-15}
        {{entries_%i_mask_reg} {entries_mask_reg[%i]} 0-15 0-15}
        {{entries_%i_originVl_reg} {entries_originVl_reg[%i]} 0-7 0-15}
        {{entries_%i_replayFlowMask_reg} {entries_replayFlowMask_reg[%i]} 0-15 0-15}
        {{entries_%i_replayFlowNum_reg} {entries_replayFlowNum_reg[%i]} 0-4 0-15}
        {{entries_%i_sourceType_reg} {entries_sourceType_reg[%i]} 0-2 0-15}
        {{entries_%i_uop_debugInfo_dispatchTime_reg} {entries_uop_debugInfo_dispatchTime_reg[%i]} 0-63 0-15}
        {{entries_%i_uop_debugInfo_eliminatedMove_reg} {entries_uop_debugInfo_eliminatedMove_reg[%i]} - 0-15}
        {{entries_%i_uop_debugInfo_enqRsTime_reg} {entries_uop_debugInfo_enqRsTime_reg[%i]} 0-63 0-15}
        {{entries_%i_uop_debugInfo_issueTime_reg} {entries_uop_debugInfo_issueTime_reg[%i]} 0-63 0-15}
        {{entries_%i_uop_debugInfo_renameTime_reg} {entries_uop_debugInfo_renameTime_reg[%i]} 0-63 0-15}
        {{entries_%i_uop_debugInfo_runahead_checkpoint_id_reg} {entries_uop_debugInfo_runahead_checkpoint_id_reg[%i]} 0-63 0-15}
        {{entries_%i_uop_debugInfo_selectTime_reg} {entries_uop_debugInfo_selectTime_reg[%i]} 0-63 0-15}
        {{entries_%i_uop_debugInfo_tlbFirstReqTime_reg} {entries_uop_debugInfo_tlbFirstReqTime_reg[%i]} 0-63 0-15}
        {{entries_%i_uop_debugInfo_tlbRespTime_reg} {entries_uop_debugInfo_tlbRespTime_reg[%i]} 0-63 0-15}
        {{entries_%i_uop_debugInfo_writebackTime_reg} {entries_uop_debugInfo_writebackTime_reg[%i]} 0-63 0-15}
        {{entries_%i_uop_debug_seqNum_seqNum_reg} {entries_uop_debug_seqNum_seqNum_reg[%i]} 0-55 0-15}
        {{entries_%i_uop_debug_seqNum_uopIdx_reg} {entries_uop_debug_seqNum_uopIdx_reg[%i]} 0-7 0-15}
        {{entries_%i_uop_flushPipe_reg} {entries_uop_flushPipe_reg[%i]} - 0-15}
        {{entries_%i_uop_fuOpType_reg} {entries_uop_fuOpType_reg[%i]} 0-8 0-15}
        {{entries_%i_uop_lqIdx_flag_reg} {entries_uop_lqIdx_flag_reg[%i]} - 0-15}
        {{entries_%i_uop_lqIdx_value_reg} {entries_uop_lqIdx_value_reg[%i]} 0-6 0-15}
        {{entries_%i_uop_pdest_reg} {entries_uop_pdest_reg[%i]} 0-7 0-15}
        {{entries_%i_uop_psrc_2_reg} {entries_uop_psrc_2_reg[%i]} 0-7 0-15}
        {{entries_%i_uop_replayInst_reg} {entries_uop_replayInst_reg[%i]} - 0-15}
        {{entries_%i_uop_robIdx_flag_reg} {entries_uop_robIdx_flag_reg[%i]} - 0-15}
        {{entries_%i_uop_robIdx_value_reg} {entries_uop_robIdx_value_reg[%i]} 0-7 0-15}
        {{entries_%i_uop_sqIdx_flag_reg} {entries_uop_sqIdx_flag_reg[%i]} - 0-15}
        {{entries_%i_uop_sqIdx_value_reg} {entries_uop_sqIdx_value_reg[%i]} 0-5 0-15}
        {{entries_%i_uop_trigger_reg} {entries_uop_trigger_reg[%i]} 0-3 0-15}
        {{entries_%i_uop_uopIdx_reg} {entries_uop_uopIdx_reg[%i]} 0-6 0-15}
        {{entries_%i_uop_v0Wen_reg} {entries_uop_v0Wen_reg[%i]} - 0-15}
        {{entries_%i_uop_vecWen_reg} {entries_uop_vecWen_reg[%i]} - 0-15}
        {{entries_%i_uop_vlWen_reg} {entries_uop_vlWen_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_fpu_isFP32Instr_reg} {entries_uop_vpu_fpu_isFP32Instr_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_fpu_isFP64Instr_reg} {entries_uop_vpu_fpu_isFP64Instr_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_fpu_isFoldTo1_2_reg} {entries_uop_vpu_fpu_isFoldTo1_2_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_fpu_isFoldTo1_4_reg} {entries_uop_vpu_fpu_isFoldTo1_4_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_fpu_isFoldTo1_8_reg} {entries_uop_vpu_fpu_isFoldTo1_8_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_fpu_isFpToVecInst_reg} {entries_uop_vpu_fpu_isFpToVecInst_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_fpu_isReduction_reg} {entries_uop_vpu_fpu_isReduction_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_frm_reg} {entries_uop_vpu_frm_reg[%i]} 0-2 0-15}
        {{entries_%i_uop_vpu_isDependOldVd_reg} {entries_uop_vpu_isDependOldVd_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_isDstMask_reg} {entries_uop_vpu_isDstMask_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_isExt_reg} {entries_uop_vpu_isExt_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_isMove_reg} {entries_uop_vpu_isMove_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_isNarrow_reg} {entries_uop_vpu_isNarrow_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_isOpMask_reg} {entries_uop_vpu_isOpMask_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_isReverse_reg} {entries_uop_vpu_isReverse_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_isVleff_reg} {entries_uop_vpu_isVleff_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_isWritePartVd_reg} {entries_uop_vpu_isWritePartVd_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_lastUop_reg} {entries_uop_vpu_lastUop_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_nf_reg} {entries_uop_vpu_nf_reg[%i]} 0-2 0-15}
        {{entries_%i_uop_vpu_specVill_reg} {entries_uop_vpu_specVill_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_specVlmul_reg} {entries_uop_vpu_specVlmul_reg[%i]} 0-2 0-15}
        {{entries_%i_uop_vpu_specVma_reg} {entries_uop_vpu_specVma_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_specVsew_reg} {entries_uop_vpu_specVsew_reg[%i]} 0-1 0-15}
        {{entries_%i_uop_vpu_specVta_reg} {entries_uop_vpu_specVta_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_veew_reg} {entries_uop_vpu_veew_reg[%i]} 0-1 0-15}
        {{entries_%i_uop_vpu_vill_reg} {entries_uop_vpu_vill_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_vlmul_reg} {entries_uop_vpu_vlmul_reg[%i]} 0-2 0-15}
        {{entries_%i_uop_vpu_vm_reg} {entries_uop_vpu_vm_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_vma_reg} {entries_uop_vpu_vma_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_vsew_reg} {entries_uop_vpu_vsew_reg[%i]} 0-1 0-15}
        {{entries_%i_uop_vpu_vta_reg} {entries_uop_vpu_vta_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_vuopIdx_reg} {entries_uop_vpu_vuopIdx_reg[%i]} 0-6 0-15}
        {{entries_%i_uop_vpu_vxrm_reg} {entries_uop_vpu_vxrm_reg[%i]} 0-1 0-15}
        {{entries_%i_vaNeedExt_reg} {entries_vaNeedExt_reg[%i]} - 0-15}
        {{entries_%i_vaddr_reg} {entries_vaddr_reg[%i]} 0-63 0-15}
        {{entries_%i_vdIdx_reg} {entries_vdIdx_reg[%i]} 0-2 0-15}
        {{entries_%i_vl_reg} {entries_vl_reg[%i]} 0-7 0-15}
        {{entries_%i_vlmax_reg} {entries_vlmax_reg[%i]} 0-7 0-15}
        {{entries_%i_vstart_reg} {entries_vstart_reg[%i]} 0-7 0-15}
        {{latchFlowNum_%i_reg} {cnt_flowNum_reg[%i]} 0-1 1-2}
        {{latchFlowNum_reg} {cnt_flowNum_reg[0]} 1 -}
        {{latchMergeByPre_%i_reg} {cnt_mergedByPrev_reg[%i]} - 1-2}
        {{latchMergeByPre_reg} {cnt_mergedByPrev_reg[0]} - -}
        {{latchWbIndex_%i_reg} {cnt_idx_reg[%i]} 0-3 1-2}
        {{latchWbIndex_reg} {cnt_idx_reg[0]} 0-3 -}
        {{latchWbValid_%i_reg} {cnt_valid_reg[%i]} - 1-2}
        {{latchWbValid_reg} {cnt_valid_reg[0]} - -}
        {{mergeDataReg_%i_r_reg} {g_data_merge.mergeDataReg_reg[%i]} 0-127 0-2}
        {{mergePortMatrixHasExcpWrap_%i_0_reg} {wbv_hasExcp_reg[%i][0]} - 1-2}
        {{mergePortMatrixHasExcpWrap_%i_1_reg} {wbv_hasExcp_reg[%i][1]} - 2}
        {{mergedByPrevPortReg_%i_reg} {g_data_merge.mergedByPrevPortReg_reg[%i]} - 1-2}
        {{mergedByPrevPortReg_reg} {g_data_merge.mergedByPrevPortReg_reg[0]} - -}
        {{mergedByPrevPortVecWrap_%i_reg} {wbv_mergedByPrev_reg[%i]} - 0-2}
        {{pipeBitsReg_%i_mBIndex_reg} {wbv_mBIndex_reg[%i]} 0-3 0-2}
        {{pipeValidReg_%i_reg} {wbv_valid_reg[%i]} - 0-2}
        {{pipewbValidReg_%i_REG_reg} {g_data_merge.pipewbValidReg_reg[%i]} - 0-2}
        {{wbIndexReg_%i_r_reg} {g_data_merge.wbIndexReg_reg[%i]} 0-3 0-2}
    }
    VSMergeBufferImp {
        {{entries_%i_elemIdx_reg} {entries_elemIdx_reg[%i]} 0-7 0-15}
        {{entries_%i_exceptionVec_15_reg} {entries_exceptionVec_reg[%i][3]} - 0-15}
        {{entries_%i_exceptionVec_19_reg} {entries_exceptionVec_reg[%i][4]} - 0-15}
        {{entries_%i_exceptionVec_23_reg} {entries_exceptionVec_reg[%i][5]} - 0-15}
        {{entries_%i_exceptionVec_3_reg} {entries_exceptionVec_reg[%i][0]} - 0-15}
        {{entries_%i_exceptionVec_6_reg} {entries_exceptionVec_reg[%i][1]} - 0-15}
        {{entries_%i_exceptionVec_7_reg} {entries_exceptionVec_reg[%i][2]} - 0-15}
        {{entries_%i_flowNum_reg} {entries_flowNum_reg[%i]} 0-4 0-15}
        {{entries_%i_gpaddr_reg} {entries_gpaddr_reg[%i]} 0-63 0-15}
        {{entries_%i_isForVSnonLeafPTE_reg} {entries_isForVSnonLeafPTE_reg[%i]} - 0-15}
        {{entries_%i_isPartReplay_reg} {entries_isPartReplay_reg[%i]} - 0-15}
        {{entries_%i_mask_reg} {entries_mask_reg[%i]} 0-15 0-15}
        {{entries_%i_replayFlowMask_reg} {entries_replayFlowMask_reg[%i]} 0-15 0-15}
        {{entries_%i_replayFlowNum_reg} {entries_replayFlowNum_reg[%i]} 0-4 0-15}
        {{entries_%i_sourceType_reg} {entries_sourceType_reg[%i]} 0-2 0-15}
        {{entries_%i_uop_debugInfo_dispatchTime_reg} {entries_uop_debugInfo_dispatchTime_reg[%i]} 0-63 0-15}
        {{entries_%i_uop_debugInfo_eliminatedMove_reg} {entries_uop_debugInfo_eliminatedMove_reg[%i]} - 0-15}
        {{entries_%i_uop_debugInfo_enqRsTime_reg} {entries_uop_debugInfo_enqRsTime_reg[%i]} 0-63 0-15}
        {{entries_%i_uop_debugInfo_issueTime_reg} {entries_uop_debugInfo_issueTime_reg[%i]} 0-63 0-15}
        {{entries_%i_uop_debugInfo_renameTime_reg} {entries_uop_debugInfo_renameTime_reg[%i]} 0-63 0-15}
        {{entries_%i_uop_debugInfo_runahead_checkpoint_id_reg} {entries_uop_debugInfo_runahead_checkpoint_id_reg[%i]} 0-63 0-15}
        {{entries_%i_uop_debugInfo_selectTime_reg} {entries_uop_debugInfo_selectTime_reg[%i]} 0-63 0-15}
        {{entries_%i_uop_debugInfo_tlbFirstReqTime_reg} {entries_uop_debugInfo_tlbFirstReqTime_reg[%i]} 0-63 0-15}
        {{entries_%i_uop_debugInfo_tlbRespTime_reg} {entries_uop_debugInfo_tlbRespTime_reg[%i]} 0-63 0-15}
        {{entries_%i_uop_debugInfo_writebackTime_reg} {entries_uop_debugInfo_writebackTime_reg[%i]} 0-63 0-15}
        {{entries_%i_uop_debug_seqNum_seqNum_reg} {entries_uop_debug_seqNum_seqNum_reg[%i]} 0-55 0-15}
        {{entries_%i_uop_debug_seqNum_uopIdx_reg} {entries_uop_debug_seqNum_uopIdx_reg[%i]} 0-7 0-15}
        {{entries_%i_uop_flushPipe_reg} {entries_uop_flushPipe_reg[%i]} - 0-15}
        {{entries_%i_uop_fuOpType_reg} {entries_uop_fuOpType_reg[%i]} 0-8 0-15}
        {{entries_%i_uop_lqIdx_flag_reg} {entries_uop_lqIdx_flag_reg[%i]} - 0-15}
        {{entries_%i_uop_lqIdx_value_reg} {entries_uop_lqIdx_value_reg[%i]} 0-6 0-15}
        {{entries_%i_uop_pdest_reg} {entries_uop_pdest_reg[%i]} 0-7 0-15}
        {{entries_%i_uop_psrc_2_reg} {entries_uop_psrc_2_reg[%i]} 0-7 0-15}
        {{entries_%i_uop_replayInst_reg} {entries_uop_replayInst_reg[%i]} - 0-15}
        {{entries_%i_uop_robIdx_flag_reg} {entries_uop_robIdx_flag_reg[%i]} - 0-15}
        {{entries_%i_uop_robIdx_value_reg} {entries_uop_robIdx_value_reg[%i]} 0-7 0-15}
        {{entries_%i_uop_sqIdx_flag_reg} {entries_uop_sqIdx_flag_reg[%i]} - 0-15}
        {{entries_%i_uop_sqIdx_value_reg} {entries_uop_sqIdx_value_reg[%i]} 0-5 0-15}
        {{entries_%i_uop_trigger_reg} {entries_uop_trigger_reg[%i]} 0-3 0-15}
        {{entries_%i_uop_uopIdx_reg} {entries_uop_uopIdx_reg[%i]} 0-6 0-15}
        {{entries_%i_uop_v0Wen_reg} {entries_uop_v0Wen_reg[%i]} - 0-15}
        {{entries_%i_uop_vecWen_reg} {entries_uop_vecWen_reg[%i]} - 0-15}
        {{entries_%i_uop_vlWen_reg} {entries_uop_vlWen_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_fpu_isFP32Instr_reg} {entries_uop_vpu_fpu_isFP32Instr_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_fpu_isFP64Instr_reg} {entries_uop_vpu_fpu_isFP64Instr_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_fpu_isFoldTo1_2_reg} {entries_uop_vpu_fpu_isFoldTo1_2_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_fpu_isFoldTo1_4_reg} {entries_uop_vpu_fpu_isFoldTo1_4_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_fpu_isFoldTo1_8_reg} {entries_uop_vpu_fpu_isFoldTo1_8_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_fpu_isFpToVecInst_reg} {entries_uop_vpu_fpu_isFpToVecInst_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_fpu_isReduction_reg} {entries_uop_vpu_fpu_isReduction_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_frm_reg} {entries_uop_vpu_frm_reg[%i]} 0-2 0-15}
        {{entries_%i_uop_vpu_isDependOldVd_reg} {entries_uop_vpu_isDependOldVd_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_isDstMask_reg} {entries_uop_vpu_isDstMask_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_isExt_reg} {entries_uop_vpu_isExt_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_isMove_reg} {entries_uop_vpu_isMove_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_isNarrow_reg} {entries_uop_vpu_isNarrow_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_isOpMask_reg} {entries_uop_vpu_isOpMask_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_isReverse_reg} {entries_uop_vpu_isReverse_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_isVleff_reg} {entries_uop_vpu_isVleff_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_isWritePartVd_reg} {entries_uop_vpu_isWritePartVd_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_lastUop_reg} {entries_uop_vpu_lastUop_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_nf_reg} {entries_uop_vpu_nf_reg[%i]} 0-2 0-15}
        {{entries_%i_uop_vpu_specVill_reg} {entries_uop_vpu_specVill_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_specVlmul_reg} {entries_uop_vpu_specVlmul_reg[%i]} 0-2 0-15}
        {{entries_%i_uop_vpu_specVma_reg} {entries_uop_vpu_specVma_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_specVsew_reg} {entries_uop_vpu_specVsew_reg[%i]} 0-1 0-15}
        {{entries_%i_uop_vpu_specVta_reg} {entries_uop_vpu_specVta_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_veew_reg} {entries_uop_vpu_veew_reg[%i]} 0-1 0-15}
        {{entries_%i_uop_vpu_vill_reg} {entries_uop_vpu_vill_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_vl_reg} {entries_uop_vpu_vl_reg[%i]} 0-7 0-15}
        {{entries_%i_uop_vpu_vlmul_reg} {entries_uop_vpu_vlmul_reg[%i]} 0-2 0-15}
        {{entries_%i_uop_vpu_vm_reg} {entries_uop_vpu_vm_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_vma_reg} {entries_uop_vpu_vma_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_vmask_reg} {entries_uop_vpu_vmask_reg[%i]} 0-127 0-15}
        {{entries_%i_uop_vpu_vsew_reg} {entries_uop_vpu_vsew_reg[%i]} 0-1 0-15}
        {{entries_%i_uop_vpu_vta_reg} {entries_uop_vpu_vta_reg[%i]} - 0-15}
        {{entries_%i_uop_vpu_vuopIdx_reg} {entries_uop_vpu_vuopIdx_reg[%i]} 0-6 0-15}
        {{entries_%i_uop_vpu_vxrm_reg} {entries_uop_vpu_vxrm_reg[%i]} 0-1 0-15}
        {{entries_%i_vaNeedExt_reg} {entries_vaNeedExt_reg[%i]} - 0-15}
        {{entries_%i_vaddr_reg} {entries_vaddr_reg[%i]} 0-63 0-15}
        {{entries_%i_vlmax_reg} {entries_vlmax_reg[%i]} 0-7 0-15}
        {{entries_%i_vstart_reg} {entries_vstart_reg[%i]} 0-7 0-15}
    }
}
proc _fx_mb_expand {spec} {
    # 区间串展开：'a-b' -> a..b，单个数 -> 它自己（不存在"计数"写法，免得 {1} 有歧义）
    set out {}
    foreach tok $spec {
        if {[regexp {^(\d+)-(\d+)$} $tok -> a b]} {
            for {set k $a} {$k <= $b} {incr k} { lappend out $k }
        } elseif {[string is integer -strict $tok]} {
            lappend out $tok
        } else {
            error "VMergeBuffer fixture: bad range token '$tok'"
        }
    }
    return $out
}
proc report_unmatched_points {args} {
    global top _FX_MB_TAB
    if {![dict exists $_FX_MB_TAB $top]} { error "VMergeBuffer fixture: unknown variant $top" }
    if {[lsearch -exact $args unread] >= 0} { return {} }
    set ref {} ; set impl {}
    foreach row [dict get $_FX_MB_TAB $top] {
        lassign $row rb ib w ks
        set klist [expr {$ks eq "-" ? {{}} : [_fx_mb_expand $ks]}]
        foreach k $klist {
            set r "r:/WORK/$top/[string map [list %i $k] $rb]"
            set i "i:/WORK/$top/u_core/[string map [list %i $k] $ib]"
            if {$w eq "-"} {
                lappend ref $r ; lappend impl $i
            } else {
                foreach b [_fx_mb_expand $w] {
                    lappend ref  "$r\[$b\]"
                    lappend impl "$i\[$b\]"
                }
            }
        }
    }
    if {[lindex $args 0] eq "-reference"} { return $ref }
    return $impl
}
