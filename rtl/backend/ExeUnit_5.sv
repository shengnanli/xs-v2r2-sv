// =============================================================================
// ExeUnit_5 —— 执行单元外壳（golden 同名 wrapper；由 scripts/gen_exeunit.py 从 G1 golden 生成，勿手改）
// -----------------------------------------------------------------------------
// FU（按 Dispatcher 出口序）：brh(BranchUnit, 延迟 0), jmp(JumpUnit, 延迟 0), i2f(IntToFP_3, 延迟 2, 门控), VSetRiWi(VSetRiWi, 延迟 0), VSetRiWvf(VSetRiWvf, 延迟 0), i2v(IntFPToVec, 延迟 0)
// inPipe：2 级；字段 robIdx[9]×2级, pdest[8]×2级, fpWen[1]×2级, fpu_wflags[1]×2级
// instrAddrTransType 打一拍：brh, jmp 各一份
// 机制全部在 xs_ExeUnit_core（发射握手 / inPipe 冲刷流水 / 时钟门控使能 / 写回有效）与
//   xs_ExeUnit_wbsel（写回字段 Mux1H）里；本文件只有例化、连线与字段打包。
// 子模块：Dispatcher 与各 FU、ClockGate 均为已签核件（两侧白盒，实例名与 golden 相同）。
// golden 对照：G1-canonical/golden-rtl/ExeUnit_5.sv
// 本文件导航（一个 golden 模块一个文件，不拆；行号由生成器回填）：
//   L215   子模块输出线（名字 = golden 的 _<实例>_<端口> 去掉前导下划线）
//   L665   外壳控制核
//   L710   inPipe 第 s 级字段拆包（只拆有 FU 读的那些）
//   L717   Dispatcher：按 fuType 把指令派给一个 FU
//   L903   功能单元
//   L1409  时钟门控（E 来自核 §3；TE 来自 DFT 的 cg_bore）
//   L1417  写回：io.out.valid 与各字段的 Mux1H
// =============================================================================
module ExeUnit_5(
  input          clock,
  input          reset,
  input          io_flush_valid,
  input          io_flush_bits_robIdx_flag,
  input  [7:0]   io_flush_bits_robIdx_value,
  input          io_flush_bits_level,
  output         io_in_ready,
  input          io_in_valid,
  input  [34:0]  io_in_bits_fuType,
  input  [8:0]   io_in_bits_fuOpType,
  input  [63:0]  io_in_bits_src_0,
  input  [63:0]  io_in_bits_src_1,
  input  [63:0]  io_in_bits_imm,
  input  [4:0]   io_in_bits_nextPcOffset,
  input          io_in_bits_robIdx_flag,
  input  [7:0]   io_in_bits_robIdx_value,
  input  [7:0]   io_in_bits_pdest,
  input          io_in_bits_rfWen,
  input          io_in_bits_fpWen,
  input          io_in_bits_vecWen,
  input          io_in_bits_v0Wen,
  input          io_in_bits_vlWen,
  input  [1:0]   io_in_bits_fpu_typeTagOut,
  input          io_in_bits_fpu_wflags,
  input  [1:0]   io_in_bits_fpu_typ,
  input  [2:0]   io_in_bits_fpu_rm,
  input  [49:0]  io_in_bits_pc,
  input          io_in_bits_preDecode_valid,
  input          io_in_bits_preDecode_isRVC,
  input  [1:0]   io_in_bits_preDecode_brType,
  input          io_in_bits_preDecode_isCall,
  input          io_in_bits_preDecode_isRet,
  input          io_in_bits_ftqIdx_flag,
  input  [5:0]   io_in_bits_ftqIdx_value,
  input  [3:0]   io_in_bits_ftqOffset,
  input  [49:0]  io_in_bits_predictInfo_target,
  input          io_in_bits_predictInfo_taken,
  input          io_in_bits_perfDebugInfo_eliminatedMove,
  input  [63:0]  io_in_bits_perfDebugInfo_renameTime,
  input  [63:0]  io_in_bits_perfDebugInfo_dispatchTime,
  input  [63:0]  io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0]  io_in_bits_perfDebugInfo_selectTime,
  input  [63:0]  io_in_bits_perfDebugInfo_issueTime,
  input  [63:0]  io_in_bits_perfDebugInfo_writebackTime,
  input  [63:0]  io_in_bits_perfDebugInfo_runahead_checkpoint_id,
  input  [63:0]  io_in_bits_perfDebugInfo_tlbFirstReqTime,
  input  [63:0]  io_in_bits_perfDebugInfo_tlbRespTime,
  input  [55:0]  io_in_bits_debug_seqNum_seqNum,
  input  [7:0]   io_in_bits_debug_seqNum_uopIdx,
  input          io_out_ready,
  output         io_out_valid,
  output [127:0] io_out_bits_data_0,
  output [127:0] io_out_bits_data_1,
  output [127:0] io_out_bits_data_2,
  output [127:0] io_out_bits_data_3,
  output [127:0] io_out_bits_data_4,
  output [127:0] io_out_bits_data_5,
  output [7:0]   io_out_bits_pdest,
  output         io_out_bits_robIdx_flag,
  output [7:0]   io_out_bits_robIdx_value,
  output         io_out_bits_intWen,
  output         io_out_bits_fpWen,
  output         io_out_bits_vecWen,
  output         io_out_bits_v0Wen,
  output         io_out_bits_vlWen,
  output         io_out_bits_redirect_valid,
  output         io_out_bits_redirect_bits_isRVC,
  output         io_out_bits_redirect_bits_robIdx_flag,
  output [7:0]   io_out_bits_redirect_bits_robIdx_value,
  output         io_out_bits_redirect_bits_ftqIdx_flag,
  output [5:0]   io_out_bits_redirect_bits_ftqIdx_value,
  output [3:0]   io_out_bits_redirect_bits_ftqOffset,
  output         io_out_bits_redirect_bits_level,
  output         io_out_bits_redirect_bits_interrupt,
  output [49:0]  io_out_bits_redirect_bits_cfiUpdate_pc,
  output         io_out_bits_redirect_bits_cfiUpdate_pd_valid,
  output         io_out_bits_redirect_bits_cfiUpdate_pd_isRVC,
  output [1:0]   io_out_bits_redirect_bits_cfiUpdate_pd_brType,
  output         io_out_bits_redirect_bits_cfiUpdate_pd_isCall,
  output         io_out_bits_redirect_bits_cfiUpdate_pd_isRet,
  output [3:0]   io_out_bits_redirect_bits_cfiUpdate_ssp,
  output [2:0]   io_out_bits_redirect_bits_cfiUpdate_sctr,
  output         io_out_bits_redirect_bits_cfiUpdate_TOSW_flag,
  output [4:0]   io_out_bits_redirect_bits_cfiUpdate_TOSW_value,
  output         io_out_bits_redirect_bits_cfiUpdate_TOSR_flag,
  output [4:0]   io_out_bits_redirect_bits_cfiUpdate_TOSR_value,
  output         io_out_bits_redirect_bits_cfiUpdate_NOS_flag,
  output [4:0]   io_out_bits_redirect_bits_cfiUpdate_NOS_value,
  output [49:0]  io_out_bits_redirect_bits_cfiUpdate_topAddr,
  output [10:0]  io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist,
  output [10:0]  io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist,
  output [6:0]   io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist,
  output [7:0]   io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist,
  output [8:0]   io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist,
  output [3:0]   io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist,
  output [7:0]   io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist,
  output [8:0]   io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist,
  output [6:0]   io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist,
  output [7:0]   io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist,
  output [6:0]   io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist,
  output [8:0]   io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist,
  output [6:0]   io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist,
  output [7:0]   io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist,
  output [7:0]   io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist,
  output [7:0]   io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist,
  output [10:0]  io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist,
  output [7:0]   io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist,
  output         io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0,
  output         io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1,
  output         io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2,
  output         io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3,
  output         io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0,
  output         io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1,
  output         io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2,
  output         io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3,
  output         io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0,
  output         io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1,
  output         io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2,
  output         io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3,
  output         io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0,
  output         io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1,
  output         io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2,
  output         io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3,
  output         io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0,
  output         io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1,
  output         io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2,
  output         io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3,
  output         io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0,
  output         io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1,
  output         io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2,
  output         io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3,
  output [2:0]   io_out_bits_redirect_bits_cfiUpdate_lastBrNumOH,
  output [3:0]   io_out_bits_redirect_bits_cfiUpdate_ghr,
  output         io_out_bits_redirect_bits_cfiUpdate_histPtr_flag,
  output [7:0]   io_out_bits_redirect_bits_cfiUpdate_histPtr_value,
  output [9:0]   io_out_bits_redirect_bits_cfiUpdate_specCnt_0,
  output [9:0]   io_out_bits_redirect_bits_cfiUpdate_specCnt_1,
  output         io_out_bits_redirect_bits_cfiUpdate_br_hit,
  output         io_out_bits_redirect_bits_cfiUpdate_jr_hit,
  output         io_out_bits_redirect_bits_cfiUpdate_sc_hit,
  output         io_out_bits_redirect_bits_cfiUpdate_predTaken,
  output [49:0]  io_out_bits_redirect_bits_cfiUpdate_target,
  output         io_out_bits_redirect_bits_cfiUpdate_taken,
  output         io_out_bits_redirect_bits_cfiUpdate_isMisPred,
  output [1:0]   io_out_bits_redirect_bits_cfiUpdate_shift,
  output         io_out_bits_redirect_bits_cfiUpdate_addIntoHist,
  output         io_out_bits_redirect_bits_cfiUpdate_backendIGPF,
  output         io_out_bits_redirect_bits_cfiUpdate_backendIPF,
  output         io_out_bits_redirect_bits_cfiUpdate_backendIAF,
  output [63:0]  io_out_bits_redirect_bits_fullTarget,
  output         io_out_bits_redirect_bits_satpFlush,
  output         io_out_bits_redirect_bits_isVlsException,
  output         io_out_bits_redirect_bits_stFtqIdx_flag,
  output [5:0]   io_out_bits_redirect_bits_stFtqIdx_value,
  output [3:0]   io_out_bits_redirect_bits_stFtqOffset,
  output [63:0]  io_out_bits_redirect_bits_debug_runahead_checkpoint_id,
  output         io_out_bits_redirect_bits_debugIsCtrl,
  output         io_out_bits_redirect_bits_debugIsMemVio,
  output [4:0]   io_out_bits_fflags,
  output         io_out_bits_wflags,
  output         io_out_bits_predecodeInfo_valid,
  output         io_out_bits_predecodeInfo_isRVC,
  output [1:0]   io_out_bits_predecodeInfo_brType,
  output         io_out_bits_predecodeInfo_isCall,
  output         io_out_bits_predecodeInfo_isRet,
  output         io_out_bits_debugInfo_eliminatedMove,
  output [63:0]  io_out_bits_debugInfo_renameTime,
  output [63:0]  io_out_bits_debugInfo_dispatchTime,
  output [63:0]  io_out_bits_debugInfo_enqRsTime,
  output [63:0]  io_out_bits_debugInfo_selectTime,
  output [63:0]  io_out_bits_debugInfo_issueTime,
  output [63:0]  io_out_bits_debugInfo_writebackTime,
  output [63:0]  io_out_bits_debugInfo_runahead_checkpoint_id,
  output [63:0]  io_out_bits_debugInfo_tlbFirstReqTime,
  output [63:0]  io_out_bits_debugInfo_tlbRespTime,
  output [55:0]  io_out_bits_debug_seqNum_seqNum,
  output [7:0]   io_out_bits_debug_seqNum_uopIdx,
  input  [2:0]   io_frm,
  output         io_vtype_valid,
  output         io_vtype_bits_illegal,
  output         io_vtype_bits_vma,
  output         io_vtype_bits_vta,
  output [1:0]   io_vtype_bits_vsew,
  output [2:0]   io_vtype_bits_vlmul,
  output         io_vlIsZero,
  output         io_vlIsVlmax,
  input          io_instrAddrTransType_bare,
  input          io_instrAddrTransType_sv39,
  input          io_instrAddrTransType_sv39x4,
  input          io_instrAddrTransType_sv48,
  input          io_instrAddrTransType_sv48x4,
  input          cg_bore_cgen
);

  // ---- 子模块输出线（名字 = golden 的 _<实例>_<端口> 去掉前导下划线）----
  wire in1ToN_io_out_0_valid;
  wire [8:0] in1ToN_io_out_0_bits_fuOpType;
  wire [63:0] in1ToN_io_out_0_bits_imm;
  wire [4:0] in1ToN_io_out_0_bits_nextPcOffset;
  wire in1ToN_io_out_0_bits_robIdx_flag;
  wire [7:0] in1ToN_io_out_0_bits_robIdx_value;
  wire [7:0] in1ToN_io_out_0_bits_pdest;
  wire [49:0] in1ToN_io_out_0_bits_pc;
  wire in1ToN_io_out_0_bits_preDecode_valid;
  wire in1ToN_io_out_0_bits_preDecode_isRVC;
  wire [1:0] in1ToN_io_out_0_bits_preDecode_brType;
  wire in1ToN_io_out_0_bits_preDecode_isCall;
  wire in1ToN_io_out_0_bits_preDecode_isRet;
  wire in1ToN_io_out_0_bits_ftqIdx_flag;
  wire [5:0] in1ToN_io_out_0_bits_ftqIdx_value;
  wire [3:0] in1ToN_io_out_0_bits_ftqOffset;
  wire in1ToN_io_out_0_bits_predictInfo_taken;
  wire in1ToN_io_out_0_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] in1ToN_io_out_0_bits_perfDebugInfo_renameTime;
  wire [63:0] in1ToN_io_out_0_bits_perfDebugInfo_dispatchTime;
  wire [63:0] in1ToN_io_out_0_bits_perfDebugInfo_enqRsTime;
  wire [63:0] in1ToN_io_out_0_bits_perfDebugInfo_selectTime;
  wire [63:0] in1ToN_io_out_0_bits_perfDebugInfo_issueTime;
  wire [63:0] in1ToN_io_out_0_bits_perfDebugInfo_writebackTime;
  wire [63:0] in1ToN_io_out_0_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] in1ToN_io_out_0_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] in1ToN_io_out_0_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] in1ToN_io_out_0_bits_debug_seqNum_seqNum;
  wire [7:0] in1ToN_io_out_0_bits_debug_seqNum_uopIdx;
  wire in1ToN_io_out_1_valid;
  wire [8:0] in1ToN_io_out_1_bits_fuOpType;
  wire [63:0] in1ToN_io_out_1_bits_imm;
  wire [4:0] in1ToN_io_out_1_bits_nextPcOffset;
  wire in1ToN_io_out_1_bits_robIdx_flag;
  wire [7:0] in1ToN_io_out_1_bits_robIdx_value;
  wire [7:0] in1ToN_io_out_1_bits_pdest;
  wire in1ToN_io_out_1_bits_rfWen;
  wire [49:0] in1ToN_io_out_1_bits_pc;
  wire in1ToN_io_out_1_bits_preDecode_valid;
  wire in1ToN_io_out_1_bits_preDecode_isRVC;
  wire [1:0] in1ToN_io_out_1_bits_preDecode_brType;
  wire in1ToN_io_out_1_bits_preDecode_isCall;
  wire in1ToN_io_out_1_bits_preDecode_isRet;
  wire in1ToN_io_out_1_bits_ftqIdx_flag;
  wire [5:0] in1ToN_io_out_1_bits_ftqIdx_value;
  wire [3:0] in1ToN_io_out_1_bits_ftqOffset;
  wire [49:0] in1ToN_io_out_1_bits_predictInfo_target;
  wire in1ToN_io_out_1_bits_predictInfo_taken;
  wire in1ToN_io_out_1_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] in1ToN_io_out_1_bits_perfDebugInfo_renameTime;
  wire [63:0] in1ToN_io_out_1_bits_perfDebugInfo_dispatchTime;
  wire [63:0] in1ToN_io_out_1_bits_perfDebugInfo_enqRsTime;
  wire [63:0] in1ToN_io_out_1_bits_perfDebugInfo_selectTime;
  wire [63:0] in1ToN_io_out_1_bits_perfDebugInfo_issueTime;
  wire [63:0] in1ToN_io_out_1_bits_perfDebugInfo_writebackTime;
  wire [63:0] in1ToN_io_out_1_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] in1ToN_io_out_1_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] in1ToN_io_out_1_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] in1ToN_io_out_1_bits_debug_seqNum_seqNum;
  wire [7:0] in1ToN_io_out_1_bits_debug_seqNum_uopIdx;
  wire in1ToN_io_out_2_valid;
  wire [1:0] in1ToN_io_out_2_bits_fpu_typeTagOut;
  wire in1ToN_io_out_2_bits_fpu_wflags;
  wire [1:0] in1ToN_io_out_2_bits_fpu_typ;
  wire [2:0] in1ToN_io_out_2_bits_fpu_rm;
  wire in1ToN_io_out_2_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] in1ToN_io_out_2_bits_perfDebugInfo_renameTime;
  wire [63:0] in1ToN_io_out_2_bits_perfDebugInfo_dispatchTime;
  wire [63:0] in1ToN_io_out_2_bits_perfDebugInfo_enqRsTime;
  wire [63:0] in1ToN_io_out_2_bits_perfDebugInfo_selectTime;
  wire [63:0] in1ToN_io_out_2_bits_perfDebugInfo_issueTime;
  wire [63:0] in1ToN_io_out_2_bits_perfDebugInfo_writebackTime;
  wire [63:0] in1ToN_io_out_2_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] in1ToN_io_out_2_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] in1ToN_io_out_2_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] in1ToN_io_out_2_bits_debug_seqNum_seqNum;
  wire [7:0] in1ToN_io_out_2_bits_debug_seqNum_uopIdx;
  wire in1ToN_io_out_3_valid;
  wire [8:0] in1ToN_io_out_3_bits_fuOpType;
  wire in1ToN_io_out_3_bits_robIdx_flag;
  wire [7:0] in1ToN_io_out_3_bits_robIdx_value;
  wire [7:0] in1ToN_io_out_3_bits_pdest;
  wire in1ToN_io_out_3_bits_rfWen;
  wire in1ToN_io_out_3_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] in1ToN_io_out_3_bits_perfDebugInfo_renameTime;
  wire [63:0] in1ToN_io_out_3_bits_perfDebugInfo_dispatchTime;
  wire [63:0] in1ToN_io_out_3_bits_perfDebugInfo_enqRsTime;
  wire [63:0] in1ToN_io_out_3_bits_perfDebugInfo_selectTime;
  wire [63:0] in1ToN_io_out_3_bits_perfDebugInfo_issueTime;
  wire [63:0] in1ToN_io_out_3_bits_perfDebugInfo_writebackTime;
  wire [63:0] in1ToN_io_out_3_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] in1ToN_io_out_3_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] in1ToN_io_out_3_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] in1ToN_io_out_3_bits_debug_seqNum_seqNum;
  wire [7:0] in1ToN_io_out_3_bits_debug_seqNum_uopIdx;
  wire in1ToN_io_out_4_valid;
  wire [8:0] in1ToN_io_out_4_bits_fuOpType;
  wire in1ToN_io_out_4_bits_robIdx_flag;
  wire [7:0] in1ToN_io_out_4_bits_robIdx_value;
  wire [7:0] in1ToN_io_out_4_bits_pdest;
  wire in1ToN_io_out_4_bits_vlWen;
  wire in1ToN_io_out_4_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] in1ToN_io_out_4_bits_perfDebugInfo_renameTime;
  wire [63:0] in1ToN_io_out_4_bits_perfDebugInfo_dispatchTime;
  wire [63:0] in1ToN_io_out_4_bits_perfDebugInfo_enqRsTime;
  wire [63:0] in1ToN_io_out_4_bits_perfDebugInfo_selectTime;
  wire [63:0] in1ToN_io_out_4_bits_perfDebugInfo_issueTime;
  wire [63:0] in1ToN_io_out_4_bits_perfDebugInfo_writebackTime;
  wire [63:0] in1ToN_io_out_4_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] in1ToN_io_out_4_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] in1ToN_io_out_4_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] in1ToN_io_out_4_bits_debug_seqNum_seqNum;
  wire [7:0] in1ToN_io_out_4_bits_debug_seqNum_uopIdx;
  wire in1ToN_io_out_5_valid;
  wire [8:0] in1ToN_io_out_5_bits_fuOpType;
  wire in1ToN_io_out_5_bits_robIdx_flag;
  wire [7:0] in1ToN_io_out_5_bits_robIdx_value;
  wire [7:0] in1ToN_io_out_5_bits_pdest;
  wire in1ToN_io_out_5_bits_fpWen;
  wire in1ToN_io_out_5_bits_vecWen;
  wire in1ToN_io_out_5_bits_v0Wen;
  wire in1ToN_io_out_5_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] in1ToN_io_out_5_bits_perfDebugInfo_renameTime;
  wire [63:0] in1ToN_io_out_5_bits_perfDebugInfo_dispatchTime;
  wire [63:0] in1ToN_io_out_5_bits_perfDebugInfo_enqRsTime;
  wire [63:0] in1ToN_io_out_5_bits_perfDebugInfo_selectTime;
  wire [63:0] in1ToN_io_out_5_bits_perfDebugInfo_issueTime;
  wire [63:0] in1ToN_io_out_5_bits_perfDebugInfo_writebackTime;
  wire [63:0] in1ToN_io_out_5_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] in1ToN_io_out_5_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] in1ToN_io_out_5_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] in1ToN_io_out_5_bits_debug_seqNum_seqNum;
  wire [7:0] in1ToN_io_out_5_bits_debug_seqNum_uopIdx;
  wire ClockGate_Q;
  wire i2v_io_in_ready;
  wire i2v_io_out_valid;
  wire i2v_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] i2v_io_out_bits_ctrl_robIdx_value;
  wire [7:0] i2v_io_out_bits_ctrl_pdest;
  wire i2v_io_out_bits_ctrl_fpWen;
  wire i2v_io_out_bits_ctrl_vecWen;
  wire i2v_io_out_bits_ctrl_v0Wen;
  wire [127:0] i2v_io_out_bits_res_data;
  wire i2v_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] i2v_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0] i2v_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0] i2v_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] i2v_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] i2v_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] i2v_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0] i2v_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] i2v_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] i2v_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] i2v_io_out_bits_debug_seqNum_seqNum;
  wire [7:0] i2v_io_out_bits_debug_seqNum_uopIdx;
  wire VSetRiWvf_io_in_ready;
  wire VSetRiWvf_io_out_valid;
  wire VSetRiWvf_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] VSetRiWvf_io_out_bits_ctrl_robIdx_value;
  wire [7:0] VSetRiWvf_io_out_bits_ctrl_pdest;
  wire VSetRiWvf_io_out_bits_ctrl_vlWen;
  wire [63:0] VSetRiWvf_io_out_bits_res_data;
  wire VSetRiWvf_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] VSetRiWvf_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0] VSetRiWvf_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0] VSetRiWvf_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] VSetRiWvf_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] VSetRiWvf_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] VSetRiWvf_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0] VSetRiWvf_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] VSetRiWvf_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] VSetRiWvf_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] VSetRiWvf_io_out_bits_debug_seqNum_seqNum;
  wire [7:0] VSetRiWvf_io_out_bits_debug_seqNum_uopIdx;
  wire VSetRiWi_io_in_ready;
  wire VSetRiWi_io_out_valid;
  wire VSetRiWi_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] VSetRiWi_io_out_bits_ctrl_robIdx_value;
  wire [7:0] VSetRiWi_io_out_bits_ctrl_pdest;
  wire VSetRiWi_io_out_bits_ctrl_rfWen;
  wire [63:0] VSetRiWi_io_out_bits_res_data;
  wire VSetRiWi_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] VSetRiWi_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0] VSetRiWi_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0] VSetRiWi_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] VSetRiWi_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] VSetRiWi_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] VSetRiWi_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0] VSetRiWi_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] VSetRiWi_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] VSetRiWi_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] VSetRiWi_io_out_bits_debug_seqNum_seqNum;
  wire [7:0] VSetRiWi_io_out_bits_debug_seqNum_uopIdx;
  wire i2f_io_in_ready;
  wire i2f_io_out_valid;
  wire i2f_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] i2f_io_out_bits_ctrl_robIdx_value;
  wire [7:0] i2f_io_out_bits_ctrl_pdest;
  wire i2f_io_out_bits_ctrl_fpWen;
  wire i2f_io_out_bits_ctrl_fpu_wflags;
  wire [63:0] i2f_io_out_bits_res_data;
  wire [4:0] i2f_io_out_bits_res_fflags;
  wire i2f_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] i2f_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0] i2f_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0] i2f_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] i2f_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] i2f_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] i2f_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0] i2f_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] i2f_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] i2f_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] i2f_io_out_bits_debug_seqNum_seqNum;
  wire [7:0] i2f_io_out_bits_debug_seqNum_uopIdx;
  wire jmp_io_in_ready;
  wire jmp_io_out_valid;
  wire jmp_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] jmp_io_out_bits_ctrl_robIdx_value;
  wire [7:0] jmp_io_out_bits_ctrl_pdest;
  wire jmp_io_out_bits_ctrl_rfWen;
  wire jmp_io_out_bits_ctrl_preDecode_valid;
  wire jmp_io_out_bits_ctrl_preDecode_isRVC;
  wire [1:0] jmp_io_out_bits_ctrl_preDecode_brType;
  wire jmp_io_out_bits_ctrl_preDecode_isCall;
  wire jmp_io_out_bits_ctrl_preDecode_isRet;
  wire [63:0] jmp_io_out_bits_res_data;
  wire jmp_io_out_bits_res_redirect_valid;
  wire jmp_io_out_bits_res_redirect_bits_isRVC;
  wire jmp_io_out_bits_res_redirect_bits_robIdx_flag;
  wire [7:0] jmp_io_out_bits_res_redirect_bits_robIdx_value;
  wire jmp_io_out_bits_res_redirect_bits_ftqIdx_flag;
  wire [5:0] jmp_io_out_bits_res_redirect_bits_ftqIdx_value;
  wire [3:0] jmp_io_out_bits_res_redirect_bits_ftqOffset;
  wire jmp_io_out_bits_res_redirect_bits_level;
  wire jmp_io_out_bits_res_redirect_bits_interrupt;
  wire [49:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_pc;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_pd_valid;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC;
  wire [1:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_pd_brType;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet;
  wire [3:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_ssp;
  wire [2:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_sctr;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag;
  wire [4:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag;
  wire [4:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag;
  wire [4:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_NOS_value;
  wire [49:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_topAddr;
  wire [10:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist;
  wire [10:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist;
  wire [6:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist;
  wire [7:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist;
  wire [8:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist;
  wire [3:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist;
  wire [7:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist;
  wire [8:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist;
  wire [6:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist;
  wire [7:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist;
  wire [6:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist;
  wire [8:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist;
  wire [6:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist;
  wire [7:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist;
  wire [7:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist;
  wire [7:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist;
  wire [10:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist;
  wire [7:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3;
  wire [2:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH;
  wire [3:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_ghr;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag;
  wire [7:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value;
  wire [9:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0;
  wire [9:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_br_hit;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_jr_hit;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_sc_hit;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_predTaken;
  wire [49:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_target;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_taken;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_isMisPred;
  wire [1:0] jmp_io_out_bits_res_redirect_bits_cfiUpdate_shift;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_backendIPF;
  wire jmp_io_out_bits_res_redirect_bits_cfiUpdate_backendIAF;
  wire [63:0] jmp_io_out_bits_res_redirect_bits_fullTarget;
  wire jmp_io_out_bits_res_redirect_bits_satpFlush;
  wire jmp_io_out_bits_res_redirect_bits_isVlsException;
  wire jmp_io_out_bits_res_redirect_bits_stFtqIdx_flag;
  wire [5:0] jmp_io_out_bits_res_redirect_bits_stFtqIdx_value;
  wire [3:0] jmp_io_out_bits_res_redirect_bits_stFtqOffset;
  wire [63:0] jmp_io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id;
  wire jmp_io_out_bits_res_redirect_bits_debugIsCtrl;
  wire jmp_io_out_bits_res_redirect_bits_debugIsMemVio;
  wire jmp_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] jmp_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0] jmp_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0] jmp_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] jmp_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] jmp_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] jmp_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0] jmp_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] jmp_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] jmp_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] jmp_io_out_bits_debug_seqNum_seqNum;
  wire [7:0] jmp_io_out_bits_debug_seqNum_uopIdx;
  wire brh_io_in_ready;
  wire brh_io_out_valid;
  wire brh_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] brh_io_out_bits_ctrl_robIdx_value;
  wire [7:0] brh_io_out_bits_ctrl_pdest;
  wire brh_io_out_bits_ctrl_preDecode_valid;
  wire brh_io_out_bits_ctrl_preDecode_isRVC;
  wire [1:0] brh_io_out_bits_ctrl_preDecode_brType;
  wire brh_io_out_bits_ctrl_preDecode_isCall;
  wire brh_io_out_bits_ctrl_preDecode_isRet;
  wire [63:0] brh_io_out_bits_res_data;
  wire brh_io_out_bits_res_redirect_valid;
  wire brh_io_out_bits_res_redirect_bits_isRVC;
  wire brh_io_out_bits_res_redirect_bits_robIdx_flag;
  wire [7:0] brh_io_out_bits_res_redirect_bits_robIdx_value;
  wire brh_io_out_bits_res_redirect_bits_ftqIdx_flag;
  wire [5:0] brh_io_out_bits_res_redirect_bits_ftqIdx_value;
  wire [3:0] brh_io_out_bits_res_redirect_bits_ftqOffset;
  wire brh_io_out_bits_res_redirect_bits_level;
  wire brh_io_out_bits_res_redirect_bits_interrupt;
  wire [49:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_pc;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_pd_valid;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC;
  wire [1:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_pd_brType;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet;
  wire [3:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_ssp;
  wire [2:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_sctr;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag;
  wire [4:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag;
  wire [4:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag;
  wire [4:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_NOS_value;
  wire [49:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_topAddr;
  wire [10:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist;
  wire [10:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist;
  wire [6:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist;
  wire [7:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist;
  wire [8:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist;
  wire [3:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist;
  wire [7:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist;
  wire [8:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist;
  wire [6:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist;
  wire [7:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist;
  wire [6:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist;
  wire [8:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist;
  wire [6:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist;
  wire [7:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist;
  wire [7:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist;
  wire [7:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist;
  wire [10:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist;
  wire [7:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3;
  wire [2:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH;
  wire [3:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_ghr;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag;
  wire [7:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value;
  wire [9:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0;
  wire [9:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_br_hit;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_jr_hit;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_sc_hit;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_predTaken;
  wire [49:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_target;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_taken;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_isMisPred;
  wire [1:0] brh_io_out_bits_res_redirect_bits_cfiUpdate_shift;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_backendIPF;
  wire brh_io_out_bits_res_redirect_bits_cfiUpdate_backendIAF;
  wire [63:0] brh_io_out_bits_res_redirect_bits_fullTarget;
  wire brh_io_out_bits_res_redirect_bits_satpFlush;
  wire brh_io_out_bits_res_redirect_bits_isVlsException;
  wire brh_io_out_bits_res_redirect_bits_stFtqIdx_flag;
  wire [5:0] brh_io_out_bits_res_redirect_bits_stFtqIdx_value;
  wire [3:0] brh_io_out_bits_res_redirect_bits_stFtqOffset;
  wire [63:0] brh_io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id;
  wire brh_io_out_bits_res_redirect_bits_debugIsCtrl;
  wire brh_io_out_bits_res_redirect_bits_debugIsMemVio;
  wire brh_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] brh_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0] brh_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0] brh_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] brh_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] brh_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] brh_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0] brh_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] brh_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] brh_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] brh_io_out_bits_debug_seqNum_seqNum;
  wire [7:0] brh_io_out_bits_debug_seqNum_uopIdx;
  wire in1ToN_io_in_ready;

  // ---- 外壳控制核 ----
  localparam int N_FU    = 6;
  localparam int LAT_MAX = 2;
  localparam int PAY_W   = 19;
  wire                     disp_in_valid;
  wire [LAT_MAX:0]         pipe_valid;
  wire [LAT_MAX:0][PAY_W-1:0] pipe_data;
  wire [N_FU-1:0]          fu_clk_en;
  wire [1:0][4:0]        att_q;
  wire                     out_valid;
  xs_ExeUnit_core #(
    .N_FU         (N_FU),
    .FU_LAT       ('{0, 0, 2, 0, 0, 0}),
    .FU_UNCERTAIN ('{0, 0, 0, 0, 0, 0}),
    .HAS_BUSY     (1'b0),
    .LAT_MAX      (LAT_MAX),
    .NF           (4),
    .FIELD_W      ('{9, 8, 1, 1}),
    .FIELD_DEPTH  ('{2, 2, 2, 2}),
    .PAY_W        (PAY_W),
    .N_ATT        (2)
  ) u_core (
    .clock           (clock),
    .reset           (reset),
    .flush_valid     (io_flush_valid),
    .flush_rob_flag  (io_flush_bits_robIdx_flag),
    .flush_rob_value (io_flush_bits_robIdx_value),
    .flush_level     (io_flush_bits_level),
    .in_valid        (io_in_valid),
    .in_ready        (io_in_ready),
    .in_payload      ({io_in_bits_fpu_wflags, io_in_bits_fpWen, io_in_bits_pdest, io_in_bits_robIdx_flag, io_in_bits_robIdx_value}),
    .disp_in_valid   (disp_in_valid),
    .disp_in_ready   (in1ToN_io_in_ready),
    .pipe_valid      (pipe_valid),
    .pipe_data       (pipe_data),
    .fu_in_valid     ({in1ToN_io_out_5_valid, in1ToN_io_out_4_valid, in1ToN_io_out_3_valid, in1ToN_io_out_2_valid, in1ToN_io_out_1_valid, in1ToN_io_out_0_valid}),
    .fu_in_ready     ({i2v_io_in_ready, VSetRiWvf_io_in_ready, VSetRiWi_io_in_ready, i2f_io_in_ready, jmp_io_in_ready, brh_io_in_ready}),
    .fu_out_valid    ({i2v_io_out_valid, VSetRiWvf_io_out_valid, VSetRiWi_io_out_valid, i2f_io_out_valid, jmp_io_out_valid, brh_io_out_valid}),
    .out_ready       (io_out_ready),
    .fu_clk_en       (fu_clk_en),
    .att_in          ({io_instrAddrTransType_sv48x4, io_instrAddrTransType_sv48, io_instrAddrTransType_sv39x4, io_instrAddrTransType_sv39, io_instrAddrTransType_bare}),
    .att_q           (att_q),
    .out_valid       (out_valid)
  );

  // ---- inPipe 第 s 级字段拆包（只拆有 FU 读的那些）----
  wire pipe2_fpWen = pipe_data[2][17];
  wire pipe2_fpu_wflags = pipe_data[2][18];
  wire [7:0] pipe2_pdest = pipe_data[2][16:9];
  wire pipe2_robIdx_flag = pipe_data[2][8];
  wire [7:0] pipe2_robIdx_value = pipe_data[2][7:0];

  // ---- Dispatcher：按 fuType 把指令派给一个 FU ----
  Dispatcher_5 in1ToN (
    .clock                                              (clock),
    .reset                                              (reset),
    .io_in_ready                                        (in1ToN_io_in_ready),
    .io_in_valid                                        (disp_in_valid),
    .io_in_bits_fuType                                  (io_in_bits_fuType),
    .io_in_bits_fuOpType                                (io_in_bits_fuOpType),
    .io_in_bits_imm                                     (io_in_bits_imm),
    .io_in_bits_nextPcOffset                            (io_in_bits_nextPcOffset),
    .io_in_bits_robIdx_flag                             (io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value                            (io_in_bits_robIdx_value),
    .io_in_bits_pdest                                   (io_in_bits_pdest),
    .io_in_bits_rfWen                                   (io_in_bits_rfWen),
    .io_in_bits_fpWen                                   (io_in_bits_fpWen),
    .io_in_bits_vecWen                                  (io_in_bits_vecWen),
    .io_in_bits_v0Wen                                   (io_in_bits_v0Wen),
    .io_in_bits_vlWen                                   (io_in_bits_vlWen),
    .io_in_bits_fpu_typeTagOut                          (io_in_bits_fpu_typeTagOut),
    .io_in_bits_fpu_wflags                              (io_in_bits_fpu_wflags),
    .io_in_bits_fpu_typ                                 (io_in_bits_fpu_typ),
    .io_in_bits_fpu_rm                                  (io_in_bits_fpu_rm),
    .io_in_bits_pc                                      (io_in_bits_pc),
    .io_in_bits_preDecode_valid                         (io_in_bits_preDecode_valid),
    .io_in_bits_preDecode_isRVC                         (io_in_bits_preDecode_isRVC),
    .io_in_bits_preDecode_brType                        (io_in_bits_preDecode_brType),
    .io_in_bits_preDecode_isCall                        (io_in_bits_preDecode_isCall),
    .io_in_bits_preDecode_isRet                         (io_in_bits_preDecode_isRet),
    .io_in_bits_ftqIdx_flag                             (io_in_bits_ftqIdx_flag),
    .io_in_bits_ftqIdx_value                            (io_in_bits_ftqIdx_value),
    .io_in_bits_ftqOffset                               (io_in_bits_ftqOffset),
    .io_in_bits_predictInfo_target                      (io_in_bits_predictInfo_target),
    .io_in_bits_predictInfo_taken                       (io_in_bits_predictInfo_taken),
    .io_in_bits_perfDebugInfo_eliminatedMove            (io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime                (io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime              (io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime                 (io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime                (io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime                 (io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime             (io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id    (io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime           (io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime               (io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum                     (io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx                     (io_in_bits_debug_seqNum_uopIdx),
    .io_out_0_ready                                     (brh_io_in_ready),
    .io_out_0_valid                                     (in1ToN_io_out_0_valid),
    .io_out_0_bits_fuOpType                             (in1ToN_io_out_0_bits_fuOpType),
    .io_out_0_bits_imm                                  (in1ToN_io_out_0_bits_imm),
    .io_out_0_bits_nextPcOffset                         (in1ToN_io_out_0_bits_nextPcOffset),
    .io_out_0_bits_robIdx_flag                          (in1ToN_io_out_0_bits_robIdx_flag),
    .io_out_0_bits_robIdx_value                         (in1ToN_io_out_0_bits_robIdx_value),
    .io_out_0_bits_pdest                                (in1ToN_io_out_0_bits_pdest),
    .io_out_0_bits_pc                                   (in1ToN_io_out_0_bits_pc),
    .io_out_0_bits_preDecode_valid                      (in1ToN_io_out_0_bits_preDecode_valid),
    .io_out_0_bits_preDecode_isRVC                      (in1ToN_io_out_0_bits_preDecode_isRVC),
    .io_out_0_bits_preDecode_brType                     (in1ToN_io_out_0_bits_preDecode_brType),
    .io_out_0_bits_preDecode_isCall                     (in1ToN_io_out_0_bits_preDecode_isCall),
    .io_out_0_bits_preDecode_isRet                      (in1ToN_io_out_0_bits_preDecode_isRet),
    .io_out_0_bits_ftqIdx_flag                          (in1ToN_io_out_0_bits_ftqIdx_flag),
    .io_out_0_bits_ftqIdx_value                         (in1ToN_io_out_0_bits_ftqIdx_value),
    .io_out_0_bits_ftqOffset                            (in1ToN_io_out_0_bits_ftqOffset),
    .io_out_0_bits_predictInfo_taken                    (in1ToN_io_out_0_bits_predictInfo_taken),
    .io_out_0_bits_perfDebugInfo_eliminatedMove         (in1ToN_io_out_0_bits_perfDebugInfo_eliminatedMove),
    .io_out_0_bits_perfDebugInfo_renameTime             (in1ToN_io_out_0_bits_perfDebugInfo_renameTime),
    .io_out_0_bits_perfDebugInfo_dispatchTime           (in1ToN_io_out_0_bits_perfDebugInfo_dispatchTime),
    .io_out_0_bits_perfDebugInfo_enqRsTime              (in1ToN_io_out_0_bits_perfDebugInfo_enqRsTime),
    .io_out_0_bits_perfDebugInfo_selectTime             (in1ToN_io_out_0_bits_perfDebugInfo_selectTime),
    .io_out_0_bits_perfDebugInfo_issueTime              (in1ToN_io_out_0_bits_perfDebugInfo_issueTime),
    .io_out_0_bits_perfDebugInfo_writebackTime          (in1ToN_io_out_0_bits_perfDebugInfo_writebackTime),
    .io_out_0_bits_perfDebugInfo_runahead_checkpoint_id (in1ToN_io_out_0_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_0_bits_perfDebugInfo_tlbFirstReqTime        (in1ToN_io_out_0_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_0_bits_perfDebugInfo_tlbRespTime            (in1ToN_io_out_0_bits_perfDebugInfo_tlbRespTime),
    .io_out_0_bits_debug_seqNum_seqNum                  (in1ToN_io_out_0_bits_debug_seqNum_seqNum),
    .io_out_0_bits_debug_seqNum_uopIdx                  (in1ToN_io_out_0_bits_debug_seqNum_uopIdx),
    .io_out_1_ready                                     (jmp_io_in_ready),
    .io_out_1_valid                                     (in1ToN_io_out_1_valid),
    .io_out_1_bits_fuOpType                             (in1ToN_io_out_1_bits_fuOpType),
    .io_out_1_bits_imm                                  (in1ToN_io_out_1_bits_imm),
    .io_out_1_bits_nextPcOffset                         (in1ToN_io_out_1_bits_nextPcOffset),
    .io_out_1_bits_robIdx_flag                          (in1ToN_io_out_1_bits_robIdx_flag),
    .io_out_1_bits_robIdx_value                         (in1ToN_io_out_1_bits_robIdx_value),
    .io_out_1_bits_pdest                                (in1ToN_io_out_1_bits_pdest),
    .io_out_1_bits_rfWen                                (in1ToN_io_out_1_bits_rfWen),
    .io_out_1_bits_pc                                   (in1ToN_io_out_1_bits_pc),
    .io_out_1_bits_preDecode_valid                      (in1ToN_io_out_1_bits_preDecode_valid),
    .io_out_1_bits_preDecode_isRVC                      (in1ToN_io_out_1_bits_preDecode_isRVC),
    .io_out_1_bits_preDecode_brType                     (in1ToN_io_out_1_bits_preDecode_brType),
    .io_out_1_bits_preDecode_isCall                     (in1ToN_io_out_1_bits_preDecode_isCall),
    .io_out_1_bits_preDecode_isRet                      (in1ToN_io_out_1_bits_preDecode_isRet),
    .io_out_1_bits_ftqIdx_flag                          (in1ToN_io_out_1_bits_ftqIdx_flag),
    .io_out_1_bits_ftqIdx_value                         (in1ToN_io_out_1_bits_ftqIdx_value),
    .io_out_1_bits_ftqOffset                            (in1ToN_io_out_1_bits_ftqOffset),
    .io_out_1_bits_predictInfo_target                   (in1ToN_io_out_1_bits_predictInfo_target),
    .io_out_1_bits_predictInfo_taken                    (in1ToN_io_out_1_bits_predictInfo_taken),
    .io_out_1_bits_perfDebugInfo_eliminatedMove         (in1ToN_io_out_1_bits_perfDebugInfo_eliminatedMove),
    .io_out_1_bits_perfDebugInfo_renameTime             (in1ToN_io_out_1_bits_perfDebugInfo_renameTime),
    .io_out_1_bits_perfDebugInfo_dispatchTime           (in1ToN_io_out_1_bits_perfDebugInfo_dispatchTime),
    .io_out_1_bits_perfDebugInfo_enqRsTime              (in1ToN_io_out_1_bits_perfDebugInfo_enqRsTime),
    .io_out_1_bits_perfDebugInfo_selectTime             (in1ToN_io_out_1_bits_perfDebugInfo_selectTime),
    .io_out_1_bits_perfDebugInfo_issueTime              (in1ToN_io_out_1_bits_perfDebugInfo_issueTime),
    .io_out_1_bits_perfDebugInfo_writebackTime          (in1ToN_io_out_1_bits_perfDebugInfo_writebackTime),
    .io_out_1_bits_perfDebugInfo_runahead_checkpoint_id (in1ToN_io_out_1_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_1_bits_perfDebugInfo_tlbFirstReqTime        (in1ToN_io_out_1_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_1_bits_perfDebugInfo_tlbRespTime            (in1ToN_io_out_1_bits_perfDebugInfo_tlbRespTime),
    .io_out_1_bits_debug_seqNum_seqNum                  (in1ToN_io_out_1_bits_debug_seqNum_seqNum),
    .io_out_1_bits_debug_seqNum_uopIdx                  (in1ToN_io_out_1_bits_debug_seqNum_uopIdx),
    .io_out_2_ready                                     (i2f_io_in_ready),
    .io_out_2_valid                                     (in1ToN_io_out_2_valid),
    .io_out_2_bits_fpu_typeTagOut                       (in1ToN_io_out_2_bits_fpu_typeTagOut),
    .io_out_2_bits_fpu_wflags                           (in1ToN_io_out_2_bits_fpu_wflags),
    .io_out_2_bits_fpu_typ                              (in1ToN_io_out_2_bits_fpu_typ),
    .io_out_2_bits_fpu_rm                               (in1ToN_io_out_2_bits_fpu_rm),
    .io_out_2_bits_perfDebugInfo_eliminatedMove         (in1ToN_io_out_2_bits_perfDebugInfo_eliminatedMove),
    .io_out_2_bits_perfDebugInfo_renameTime             (in1ToN_io_out_2_bits_perfDebugInfo_renameTime),
    .io_out_2_bits_perfDebugInfo_dispatchTime           (in1ToN_io_out_2_bits_perfDebugInfo_dispatchTime),
    .io_out_2_bits_perfDebugInfo_enqRsTime              (in1ToN_io_out_2_bits_perfDebugInfo_enqRsTime),
    .io_out_2_bits_perfDebugInfo_selectTime             (in1ToN_io_out_2_bits_perfDebugInfo_selectTime),
    .io_out_2_bits_perfDebugInfo_issueTime              (in1ToN_io_out_2_bits_perfDebugInfo_issueTime),
    .io_out_2_bits_perfDebugInfo_writebackTime          (in1ToN_io_out_2_bits_perfDebugInfo_writebackTime),
    .io_out_2_bits_perfDebugInfo_runahead_checkpoint_id (in1ToN_io_out_2_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_2_bits_perfDebugInfo_tlbFirstReqTime        (in1ToN_io_out_2_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_2_bits_perfDebugInfo_tlbRespTime            (in1ToN_io_out_2_bits_perfDebugInfo_tlbRespTime),
    .io_out_2_bits_debug_seqNum_seqNum                  (in1ToN_io_out_2_bits_debug_seqNum_seqNum),
    .io_out_2_bits_debug_seqNum_uopIdx                  (in1ToN_io_out_2_bits_debug_seqNum_uopIdx),
    .io_out_3_ready                                     (VSetRiWi_io_in_ready),
    .io_out_3_valid                                     (in1ToN_io_out_3_valid),
    .io_out_3_bits_fuOpType                             (in1ToN_io_out_3_bits_fuOpType),
    .io_out_3_bits_robIdx_flag                          (in1ToN_io_out_3_bits_robIdx_flag),
    .io_out_3_bits_robIdx_value                         (in1ToN_io_out_3_bits_robIdx_value),
    .io_out_3_bits_pdest                                (in1ToN_io_out_3_bits_pdest),
    .io_out_3_bits_rfWen                                (in1ToN_io_out_3_bits_rfWen),
    .io_out_3_bits_perfDebugInfo_eliminatedMove         (in1ToN_io_out_3_bits_perfDebugInfo_eliminatedMove),
    .io_out_3_bits_perfDebugInfo_renameTime             (in1ToN_io_out_3_bits_perfDebugInfo_renameTime),
    .io_out_3_bits_perfDebugInfo_dispatchTime           (in1ToN_io_out_3_bits_perfDebugInfo_dispatchTime),
    .io_out_3_bits_perfDebugInfo_enqRsTime              (in1ToN_io_out_3_bits_perfDebugInfo_enqRsTime),
    .io_out_3_bits_perfDebugInfo_selectTime             (in1ToN_io_out_3_bits_perfDebugInfo_selectTime),
    .io_out_3_bits_perfDebugInfo_issueTime              (in1ToN_io_out_3_bits_perfDebugInfo_issueTime),
    .io_out_3_bits_perfDebugInfo_writebackTime          (in1ToN_io_out_3_bits_perfDebugInfo_writebackTime),
    .io_out_3_bits_perfDebugInfo_runahead_checkpoint_id (in1ToN_io_out_3_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_3_bits_perfDebugInfo_tlbFirstReqTime        (in1ToN_io_out_3_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_3_bits_perfDebugInfo_tlbRespTime            (in1ToN_io_out_3_bits_perfDebugInfo_tlbRespTime),
    .io_out_3_bits_debug_seqNum_seqNum                  (in1ToN_io_out_3_bits_debug_seqNum_seqNum),
    .io_out_3_bits_debug_seqNum_uopIdx                  (in1ToN_io_out_3_bits_debug_seqNum_uopIdx),
    .io_out_4_ready                                     (VSetRiWvf_io_in_ready),
    .io_out_4_valid                                     (in1ToN_io_out_4_valid),
    .io_out_4_bits_fuOpType                             (in1ToN_io_out_4_bits_fuOpType),
    .io_out_4_bits_robIdx_flag                          (in1ToN_io_out_4_bits_robIdx_flag),
    .io_out_4_bits_robIdx_value                         (in1ToN_io_out_4_bits_robIdx_value),
    .io_out_4_bits_pdest                                (in1ToN_io_out_4_bits_pdest),
    .io_out_4_bits_vlWen                                (in1ToN_io_out_4_bits_vlWen),
    .io_out_4_bits_perfDebugInfo_eliminatedMove         (in1ToN_io_out_4_bits_perfDebugInfo_eliminatedMove),
    .io_out_4_bits_perfDebugInfo_renameTime             (in1ToN_io_out_4_bits_perfDebugInfo_renameTime),
    .io_out_4_bits_perfDebugInfo_dispatchTime           (in1ToN_io_out_4_bits_perfDebugInfo_dispatchTime),
    .io_out_4_bits_perfDebugInfo_enqRsTime              (in1ToN_io_out_4_bits_perfDebugInfo_enqRsTime),
    .io_out_4_bits_perfDebugInfo_selectTime             (in1ToN_io_out_4_bits_perfDebugInfo_selectTime),
    .io_out_4_bits_perfDebugInfo_issueTime              (in1ToN_io_out_4_bits_perfDebugInfo_issueTime),
    .io_out_4_bits_perfDebugInfo_writebackTime          (in1ToN_io_out_4_bits_perfDebugInfo_writebackTime),
    .io_out_4_bits_perfDebugInfo_runahead_checkpoint_id (in1ToN_io_out_4_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_4_bits_perfDebugInfo_tlbFirstReqTime        (in1ToN_io_out_4_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_4_bits_perfDebugInfo_tlbRespTime            (in1ToN_io_out_4_bits_perfDebugInfo_tlbRespTime),
    .io_out_4_bits_debug_seqNum_seqNum                  (in1ToN_io_out_4_bits_debug_seqNum_seqNum),
    .io_out_4_bits_debug_seqNum_uopIdx                  (in1ToN_io_out_4_bits_debug_seqNum_uopIdx),
    .io_out_5_ready                                     (i2v_io_in_ready),
    .io_out_5_valid                                     (in1ToN_io_out_5_valid),
    .io_out_5_bits_fuOpType                             (in1ToN_io_out_5_bits_fuOpType),
    .io_out_5_bits_robIdx_flag                          (in1ToN_io_out_5_bits_robIdx_flag),
    .io_out_5_bits_robIdx_value                         (in1ToN_io_out_5_bits_robIdx_value),
    .io_out_5_bits_pdest                                (in1ToN_io_out_5_bits_pdest),
    .io_out_5_bits_fpWen                                (in1ToN_io_out_5_bits_fpWen),
    .io_out_5_bits_vecWen                               (in1ToN_io_out_5_bits_vecWen),
    .io_out_5_bits_v0Wen                                (in1ToN_io_out_5_bits_v0Wen),
    .io_out_5_bits_perfDebugInfo_eliminatedMove         (in1ToN_io_out_5_bits_perfDebugInfo_eliminatedMove),
    .io_out_5_bits_perfDebugInfo_renameTime             (in1ToN_io_out_5_bits_perfDebugInfo_renameTime),
    .io_out_5_bits_perfDebugInfo_dispatchTime           (in1ToN_io_out_5_bits_perfDebugInfo_dispatchTime),
    .io_out_5_bits_perfDebugInfo_enqRsTime              (in1ToN_io_out_5_bits_perfDebugInfo_enqRsTime),
    .io_out_5_bits_perfDebugInfo_selectTime             (in1ToN_io_out_5_bits_perfDebugInfo_selectTime),
    .io_out_5_bits_perfDebugInfo_issueTime              (in1ToN_io_out_5_bits_perfDebugInfo_issueTime),
    .io_out_5_bits_perfDebugInfo_writebackTime          (in1ToN_io_out_5_bits_perfDebugInfo_writebackTime),
    .io_out_5_bits_perfDebugInfo_runahead_checkpoint_id (in1ToN_io_out_5_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_5_bits_perfDebugInfo_tlbFirstReqTime        (in1ToN_io_out_5_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_5_bits_perfDebugInfo_tlbRespTime            (in1ToN_io_out_5_bits_perfDebugInfo_tlbRespTime),
    .io_out_5_bits_debug_seqNum_seqNum                  (in1ToN_io_out_5_bits_debug_seqNum_seqNum),
    .io_out_5_bits_debug_seqNum_uopIdx                  (in1ToN_io_out_5_bits_debug_seqNum_uopIdx)
  );

  // ---- 功能单元 ----
  BranchUnit brh (
    .io_in_ready                                                             (brh_io_in_ready),
    .io_in_valid                                                             (in1ToN_io_out_0_valid),
    .io_in_bits_ctrl_fuOpType                                                (in1ToN_io_out_0_bits_fuOpType),
    .io_in_bits_ctrl_robIdx_flag                                             (in1ToN_io_out_0_bits_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value                                            (in1ToN_io_out_0_bits_robIdx_value),
    .io_in_bits_ctrl_pdest                                                   (in1ToN_io_out_0_bits_pdest),
    .io_in_bits_ctrl_preDecode_valid                                         (in1ToN_io_out_0_bits_preDecode_valid),
    .io_in_bits_ctrl_preDecode_isRVC                                         (in1ToN_io_out_0_bits_preDecode_isRVC),
    .io_in_bits_ctrl_preDecode_brType                                        (in1ToN_io_out_0_bits_preDecode_brType),
    .io_in_bits_ctrl_preDecode_isCall                                        (in1ToN_io_out_0_bits_preDecode_isCall),
    .io_in_bits_ctrl_preDecode_isRet                                         (in1ToN_io_out_0_bits_preDecode_isRet),
    .io_in_bits_ctrl_ftqIdx_flag                                             (in1ToN_io_out_0_bits_ftqIdx_flag),
    .io_in_bits_ctrl_ftqIdx_value                                            (in1ToN_io_out_0_bits_ftqIdx_value),
    .io_in_bits_ctrl_ftqOffset                                               (in1ToN_io_out_0_bits_ftqOffset),
    .io_in_bits_ctrl_predictInfo_taken                                       (in1ToN_io_out_0_bits_predictInfo_taken),
    .io_in_bits_data_src_1                                                   (io_in_bits_src_1),
    .io_in_bits_data_src_0                                                   (io_in_bits_src_0),
    .io_in_bits_data_imm                                                     (in1ToN_io_out_0_bits_imm),
    .io_in_bits_data_pc                                                      (in1ToN_io_out_0_bits_pc),
    .io_in_bits_data_nextPcOffset                                            (in1ToN_io_out_0_bits_nextPcOffset),
    .io_in_bits_perfDebugInfo_eliminatedMove                                 (in1ToN_io_out_0_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime                                     (in1ToN_io_out_0_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime                                   (in1ToN_io_out_0_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime                                      (in1ToN_io_out_0_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime                                     (in1ToN_io_out_0_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime                                      (in1ToN_io_out_0_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime                                  (in1ToN_io_out_0_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id                         (in1ToN_io_out_0_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime                                (in1ToN_io_out_0_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime                                    (in1ToN_io_out_0_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum                                          (in1ToN_io_out_0_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx                                          (in1ToN_io_out_0_bits_debug_seqNum_uopIdx),
    .io_out_ready                                                            (io_out_ready),
    .io_out_valid                                                            (brh_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag                                            (brh_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value                                           (brh_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest                                                  (brh_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_preDecode_valid                                        (brh_io_out_bits_ctrl_preDecode_valid),
    .io_out_bits_ctrl_preDecode_isRVC                                        (brh_io_out_bits_ctrl_preDecode_isRVC),
    .io_out_bits_ctrl_preDecode_brType                                       (brh_io_out_bits_ctrl_preDecode_brType),
    .io_out_bits_ctrl_preDecode_isCall                                       (brh_io_out_bits_ctrl_preDecode_isCall),
    .io_out_bits_ctrl_preDecode_isRet                                        (brh_io_out_bits_ctrl_preDecode_isRet),
    .io_out_bits_res_data                                                    (brh_io_out_bits_res_data),
    .io_out_bits_res_redirect_valid                                          (brh_io_out_bits_res_redirect_valid),
    .io_out_bits_res_redirect_bits_isRVC                                     (brh_io_out_bits_res_redirect_bits_isRVC),
    .io_out_bits_res_redirect_bits_robIdx_flag                               (brh_io_out_bits_res_redirect_bits_robIdx_flag),
    .io_out_bits_res_redirect_bits_robIdx_value                              (brh_io_out_bits_res_redirect_bits_robIdx_value),
    .io_out_bits_res_redirect_bits_ftqIdx_flag                               (brh_io_out_bits_res_redirect_bits_ftqIdx_flag),
    .io_out_bits_res_redirect_bits_ftqIdx_value                              (brh_io_out_bits_res_redirect_bits_ftqIdx_value),
    .io_out_bits_res_redirect_bits_ftqOffset                                 (brh_io_out_bits_res_redirect_bits_ftqOffset),
    .io_out_bits_res_redirect_bits_level                                     (brh_io_out_bits_res_redirect_bits_level),
    .io_out_bits_res_redirect_bits_interrupt                                 (brh_io_out_bits_res_redirect_bits_interrupt),
    .io_out_bits_res_redirect_bits_cfiUpdate_pc                              (brh_io_out_bits_res_redirect_bits_cfiUpdate_pc),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_valid                        (brh_io_out_bits_res_redirect_bits_cfiUpdate_pd_valid),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC                        (brh_io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_brType                       (brh_io_out_bits_res_redirect_bits_cfiUpdate_pd_brType),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall                       (brh_io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet                        (brh_io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet),
    .io_out_bits_res_redirect_bits_cfiUpdate_ssp                             (brh_io_out_bits_res_redirect_bits_cfiUpdate_ssp),
    .io_out_bits_res_redirect_bits_cfiUpdate_sctr                            (brh_io_out_bits_res_redirect_bits_cfiUpdate_sctr),
    .io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag                       (brh_io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag),
    .io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value                      (brh_io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value),
    .io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag                       (brh_io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag),
    .io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value                      (brh_io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value),
    .io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag                        (brh_io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag),
    .io_out_bits_res_redirect_bits_cfiUpdate_NOS_value                       (brh_io_out_bits_res_redirect_bits_cfiUpdate_NOS_value),
    .io_out_bits_res_redirect_bits_cfiUpdate_topAddr                         (brh_io_out_bits_res_redirect_bits_cfiUpdate_topAddr),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist (brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist (brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist (brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist (brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist (brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist (brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist (brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist (brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist  (brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist  (brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist  (brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist  (brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist  (brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist  (brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist  (brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist  (brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist  (brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist  (brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0            (brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1            (brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2            (brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3            (brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0            (brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1            (brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2            (brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3            (brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0            (brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1            (brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2            (brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3            (brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0            (brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1            (brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2            (brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3            (brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0            (brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1            (brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2            (brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3            (brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0            (brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1            (brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2            (brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3            (brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3),
    .io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH                     (brh_io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH),
    .io_out_bits_res_redirect_bits_cfiUpdate_ghr                             (brh_io_out_bits_res_redirect_bits_cfiUpdate_ghr),
    .io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag                    (brh_io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag),
    .io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value                   (brh_io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value),
    .io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0                       (brh_io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1                       (brh_io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_br_hit                          (brh_io_out_bits_res_redirect_bits_cfiUpdate_br_hit),
    .io_out_bits_res_redirect_bits_cfiUpdate_jr_hit                          (brh_io_out_bits_res_redirect_bits_cfiUpdate_jr_hit),
    .io_out_bits_res_redirect_bits_cfiUpdate_sc_hit                          (brh_io_out_bits_res_redirect_bits_cfiUpdate_sc_hit),
    .io_out_bits_res_redirect_bits_cfiUpdate_predTaken                       (brh_io_out_bits_res_redirect_bits_cfiUpdate_predTaken),
    .io_out_bits_res_redirect_bits_cfiUpdate_target                          (brh_io_out_bits_res_redirect_bits_cfiUpdate_target),
    .io_out_bits_res_redirect_bits_cfiUpdate_taken                           (brh_io_out_bits_res_redirect_bits_cfiUpdate_taken),
    .io_out_bits_res_redirect_bits_cfiUpdate_isMisPred                       (brh_io_out_bits_res_redirect_bits_cfiUpdate_isMisPred),
    .io_out_bits_res_redirect_bits_cfiUpdate_shift                           (brh_io_out_bits_res_redirect_bits_cfiUpdate_shift),
    .io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist                     (brh_io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist),
    .io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF                     (brh_io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF),
    .io_out_bits_res_redirect_bits_cfiUpdate_backendIPF                      (brh_io_out_bits_res_redirect_bits_cfiUpdate_backendIPF),
    .io_out_bits_res_redirect_bits_cfiUpdate_backendIAF                      (brh_io_out_bits_res_redirect_bits_cfiUpdate_backendIAF),
    .io_out_bits_res_redirect_bits_fullTarget                                (brh_io_out_bits_res_redirect_bits_fullTarget),
    .io_out_bits_res_redirect_bits_satpFlush                                 (brh_io_out_bits_res_redirect_bits_satpFlush),
    .io_out_bits_res_redirect_bits_isVlsException                            (brh_io_out_bits_res_redirect_bits_isVlsException),
    .io_out_bits_res_redirect_bits_stFtqIdx_flag                             (brh_io_out_bits_res_redirect_bits_stFtqIdx_flag),
    .io_out_bits_res_redirect_bits_stFtqIdx_value                            (brh_io_out_bits_res_redirect_bits_stFtqIdx_value),
    .io_out_bits_res_redirect_bits_stFtqOffset                               (brh_io_out_bits_res_redirect_bits_stFtqOffset),
    .io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id              (brh_io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id),
    .io_out_bits_res_redirect_bits_debugIsCtrl                               (brh_io_out_bits_res_redirect_bits_debugIsCtrl),
    .io_out_bits_res_redirect_bits_debugIsMemVio                             (brh_io_out_bits_res_redirect_bits_debugIsMemVio),
    .io_out_bits_perfDebugInfo_eliminatedMove                                (brh_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime                                    (brh_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime                                  (brh_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime                                     (brh_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime                                    (brh_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime                                     (brh_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime                                 (brh_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id                        (brh_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime                               (brh_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime                                   (brh_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                                         (brh_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx                                         (brh_io_out_bits_debug_seqNum_uopIdx),
    .io_instrAddrTransType_bare                                              (att_q[0][0]),
    .io_instrAddrTransType_sv39                                              (att_q[0][1]),
    .io_instrAddrTransType_sv39x4                                            (att_q[0][2]),
    .io_instrAddrTransType_sv48                                              (att_q[0][3]),
    .io_instrAddrTransType_sv48x4                                            (att_q[0][4])
  );
  JumpUnit jmp (
    .io_in_ready                                                             (jmp_io_in_ready),
    .io_in_valid                                                             (in1ToN_io_out_1_valid),
    .io_in_bits_ctrl_fuOpType                                                (in1ToN_io_out_1_bits_fuOpType),
    .io_in_bits_ctrl_robIdx_flag                                             (in1ToN_io_out_1_bits_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value                                            (in1ToN_io_out_1_bits_robIdx_value),
    .io_in_bits_ctrl_pdest                                                   (in1ToN_io_out_1_bits_pdest),
    .io_in_bits_ctrl_rfWen                                                   (in1ToN_io_out_1_bits_rfWen),
    .io_in_bits_ctrl_preDecode_valid                                         (in1ToN_io_out_1_bits_preDecode_valid),
    .io_in_bits_ctrl_preDecode_isRVC                                         (in1ToN_io_out_1_bits_preDecode_isRVC),
    .io_in_bits_ctrl_preDecode_brType                                        (in1ToN_io_out_1_bits_preDecode_brType),
    .io_in_bits_ctrl_preDecode_isCall                                        (in1ToN_io_out_1_bits_preDecode_isCall),
    .io_in_bits_ctrl_preDecode_isRet                                         (in1ToN_io_out_1_bits_preDecode_isRet),
    .io_in_bits_ctrl_ftqIdx_flag                                             (in1ToN_io_out_1_bits_ftqIdx_flag),
    .io_in_bits_ctrl_ftqIdx_value                                            (in1ToN_io_out_1_bits_ftqIdx_value),
    .io_in_bits_ctrl_ftqOffset                                               (in1ToN_io_out_1_bits_ftqOffset),
    .io_in_bits_ctrl_predictInfo_target                                      (in1ToN_io_out_1_bits_predictInfo_target),
    .io_in_bits_ctrl_predictInfo_taken                                       (in1ToN_io_out_1_bits_predictInfo_taken),
    .io_in_bits_data_src_0                                                   (io_in_bits_src_0),
    .io_in_bits_data_imm                                                     (in1ToN_io_out_1_bits_imm),
    .io_in_bits_data_pc                                                      (in1ToN_io_out_1_bits_pc),
    .io_in_bits_data_nextPcOffset                                            (in1ToN_io_out_1_bits_nextPcOffset),
    .io_in_bits_perfDebugInfo_eliminatedMove                                 (in1ToN_io_out_1_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime                                     (in1ToN_io_out_1_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime                                   (in1ToN_io_out_1_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime                                      (in1ToN_io_out_1_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime                                     (in1ToN_io_out_1_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime                                      (in1ToN_io_out_1_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime                                  (in1ToN_io_out_1_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id                         (in1ToN_io_out_1_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime                                (in1ToN_io_out_1_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime                                    (in1ToN_io_out_1_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum                                          (in1ToN_io_out_1_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx                                          (in1ToN_io_out_1_bits_debug_seqNum_uopIdx),
    .io_out_ready                                                            (io_out_ready),
    .io_out_valid                                                            (jmp_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag                                            (jmp_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value                                           (jmp_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest                                                  (jmp_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_rfWen                                                  (jmp_io_out_bits_ctrl_rfWen),
    .io_out_bits_ctrl_preDecode_valid                                        (jmp_io_out_bits_ctrl_preDecode_valid),
    .io_out_bits_ctrl_preDecode_isRVC                                        (jmp_io_out_bits_ctrl_preDecode_isRVC),
    .io_out_bits_ctrl_preDecode_brType                                       (jmp_io_out_bits_ctrl_preDecode_brType),
    .io_out_bits_ctrl_preDecode_isCall                                       (jmp_io_out_bits_ctrl_preDecode_isCall),
    .io_out_bits_ctrl_preDecode_isRet                                        (jmp_io_out_bits_ctrl_preDecode_isRet),
    .io_out_bits_res_data                                                    (jmp_io_out_bits_res_data),
    .io_out_bits_res_redirect_valid                                          (jmp_io_out_bits_res_redirect_valid),
    .io_out_bits_res_redirect_bits_isRVC                                     (jmp_io_out_bits_res_redirect_bits_isRVC),
    .io_out_bits_res_redirect_bits_robIdx_flag                               (jmp_io_out_bits_res_redirect_bits_robIdx_flag),
    .io_out_bits_res_redirect_bits_robIdx_value                              (jmp_io_out_bits_res_redirect_bits_robIdx_value),
    .io_out_bits_res_redirect_bits_ftqIdx_flag                               (jmp_io_out_bits_res_redirect_bits_ftqIdx_flag),
    .io_out_bits_res_redirect_bits_ftqIdx_value                              (jmp_io_out_bits_res_redirect_bits_ftqIdx_value),
    .io_out_bits_res_redirect_bits_ftqOffset                                 (jmp_io_out_bits_res_redirect_bits_ftqOffset),
    .io_out_bits_res_redirect_bits_level                                     (jmp_io_out_bits_res_redirect_bits_level),
    .io_out_bits_res_redirect_bits_interrupt                                 (jmp_io_out_bits_res_redirect_bits_interrupt),
    .io_out_bits_res_redirect_bits_cfiUpdate_pc                              (jmp_io_out_bits_res_redirect_bits_cfiUpdate_pc),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_valid                        (jmp_io_out_bits_res_redirect_bits_cfiUpdate_pd_valid),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC                        (jmp_io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_brType                       (jmp_io_out_bits_res_redirect_bits_cfiUpdate_pd_brType),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall                       (jmp_io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet                        (jmp_io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet),
    .io_out_bits_res_redirect_bits_cfiUpdate_ssp                             (jmp_io_out_bits_res_redirect_bits_cfiUpdate_ssp),
    .io_out_bits_res_redirect_bits_cfiUpdate_sctr                            (jmp_io_out_bits_res_redirect_bits_cfiUpdate_sctr),
    .io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag                       (jmp_io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag),
    .io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value                      (jmp_io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value),
    .io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag                       (jmp_io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag),
    .io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value                      (jmp_io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value),
    .io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag                        (jmp_io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag),
    .io_out_bits_res_redirect_bits_cfiUpdate_NOS_value                       (jmp_io_out_bits_res_redirect_bits_cfiUpdate_NOS_value),
    .io_out_bits_res_redirect_bits_cfiUpdate_topAddr                         (jmp_io_out_bits_res_redirect_bits_cfiUpdate_topAddr),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist (jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist (jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist (jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist (jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist (jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist (jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist (jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist (jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist  (jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist  (jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist  (jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist  (jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist  (jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist  (jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist  (jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist  (jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist  (jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist  (jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0            (jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1            (jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2            (jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3            (jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0            (jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1            (jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2            (jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3            (jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0            (jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1            (jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2            (jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3            (jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0            (jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1            (jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2            (jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3            (jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0            (jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1            (jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2            (jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3            (jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0            (jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1            (jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2            (jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3            (jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3),
    .io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH                     (jmp_io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH),
    .io_out_bits_res_redirect_bits_cfiUpdate_ghr                             (jmp_io_out_bits_res_redirect_bits_cfiUpdate_ghr),
    .io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag                    (jmp_io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag),
    .io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value                   (jmp_io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value),
    .io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0                       (jmp_io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1                       (jmp_io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_br_hit                          (jmp_io_out_bits_res_redirect_bits_cfiUpdate_br_hit),
    .io_out_bits_res_redirect_bits_cfiUpdate_jr_hit                          (jmp_io_out_bits_res_redirect_bits_cfiUpdate_jr_hit),
    .io_out_bits_res_redirect_bits_cfiUpdate_sc_hit                          (jmp_io_out_bits_res_redirect_bits_cfiUpdate_sc_hit),
    .io_out_bits_res_redirect_bits_cfiUpdate_predTaken                       (jmp_io_out_bits_res_redirect_bits_cfiUpdate_predTaken),
    .io_out_bits_res_redirect_bits_cfiUpdate_target                          (jmp_io_out_bits_res_redirect_bits_cfiUpdate_target),
    .io_out_bits_res_redirect_bits_cfiUpdate_taken                           (jmp_io_out_bits_res_redirect_bits_cfiUpdate_taken),
    .io_out_bits_res_redirect_bits_cfiUpdate_isMisPred                       (jmp_io_out_bits_res_redirect_bits_cfiUpdate_isMisPred),
    .io_out_bits_res_redirect_bits_cfiUpdate_shift                           (jmp_io_out_bits_res_redirect_bits_cfiUpdate_shift),
    .io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist                     (jmp_io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist),
    .io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF                     (jmp_io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF),
    .io_out_bits_res_redirect_bits_cfiUpdate_backendIPF                      (jmp_io_out_bits_res_redirect_bits_cfiUpdate_backendIPF),
    .io_out_bits_res_redirect_bits_cfiUpdate_backendIAF                      (jmp_io_out_bits_res_redirect_bits_cfiUpdate_backendIAF),
    .io_out_bits_res_redirect_bits_fullTarget                                (jmp_io_out_bits_res_redirect_bits_fullTarget),
    .io_out_bits_res_redirect_bits_satpFlush                                 (jmp_io_out_bits_res_redirect_bits_satpFlush),
    .io_out_bits_res_redirect_bits_isVlsException                            (jmp_io_out_bits_res_redirect_bits_isVlsException),
    .io_out_bits_res_redirect_bits_stFtqIdx_flag                             (jmp_io_out_bits_res_redirect_bits_stFtqIdx_flag),
    .io_out_bits_res_redirect_bits_stFtqIdx_value                            (jmp_io_out_bits_res_redirect_bits_stFtqIdx_value),
    .io_out_bits_res_redirect_bits_stFtqOffset                               (jmp_io_out_bits_res_redirect_bits_stFtqOffset),
    .io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id              (jmp_io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id),
    .io_out_bits_res_redirect_bits_debugIsCtrl                               (jmp_io_out_bits_res_redirect_bits_debugIsCtrl),
    .io_out_bits_res_redirect_bits_debugIsMemVio                             (jmp_io_out_bits_res_redirect_bits_debugIsMemVio),
    .io_out_bits_perfDebugInfo_eliminatedMove                                (jmp_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime                                    (jmp_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime                                  (jmp_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime                                     (jmp_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime                                    (jmp_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime                                     (jmp_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime                                 (jmp_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id                        (jmp_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime                               (jmp_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime                                   (jmp_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                                         (jmp_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx                                         (jmp_io_out_bits_debug_seqNum_uopIdx),
    .io_instrAddrTransType_bare                                              (att_q[1][0]),
    .io_instrAddrTransType_sv39                                              (att_q[1][1]),
    .io_instrAddrTransType_sv39x4                                            (att_q[1][2]),
    .io_instrAddrTransType_sv48                                              (att_q[1][3]),
    .io_instrAddrTransType_sv48x4                                            (att_q[1][4])
  );
  IntToFP_3 i2f (
    .clock                                            (ClockGate_Q),
    .reset                                            (reset),
    .io_in_ready                                      (i2f_io_in_ready),
    .io_in_valid                                      (in1ToN_io_out_2_valid),
    .io_in_bits_ctrl_fpu_typeTagOut                   (in1ToN_io_out_2_bits_fpu_typeTagOut),
    .io_in_bits_ctrl_fpu_wflags                       (in1ToN_io_out_2_bits_fpu_wflags),
    .io_in_bits_ctrl_fpu_typ                          (in1ToN_io_out_2_bits_fpu_typ),
    .io_in_bits_ctrl_fpu_rm                           (in1ToN_io_out_2_bits_fpu_rm),
    .io_in_bits_ctrlPipe_2_robIdx_flag                (pipe2_robIdx_flag),
    .io_in_bits_ctrlPipe_2_robIdx_value               (pipe2_robIdx_value),
    .io_in_bits_ctrlPipe_2_pdest                      (pipe2_pdest),
    .io_in_bits_ctrlPipe_2_fpWen                      (pipe2_fpWen),
    .io_in_bits_ctrlPipe_2_fpu_wflags                 (pipe2_fpu_wflags),
    .io_in_bits_validPipe_0                           (io_in_valid),
    .io_in_bits_validPipe_1                           (pipe_valid[1]),
    .io_in_bits_validPipe_2                           (pipe_valid[2]),
    .io_in_bits_data_src_0                            (io_in_bits_src_0),
    .io_in_bits_perfDebugInfo_eliminatedMove          (in1ToN_io_out_2_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime              (in1ToN_io_out_2_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime            (in1ToN_io_out_2_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime               (in1ToN_io_out_2_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime              (in1ToN_io_out_2_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime               (in1ToN_io_out_2_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime           (in1ToN_io_out_2_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id  (in1ToN_io_out_2_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime         (in1ToN_io_out_2_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime             (in1ToN_io_out_2_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum                   (in1ToN_io_out_2_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx                   (in1ToN_io_out_2_bits_debug_seqNum_uopIdx),
    .io_out_ready                                     (io_out_ready),
    .io_out_valid                                     (i2f_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag                     (i2f_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value                    (i2f_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest                           (i2f_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_fpWen                           (i2f_io_out_bits_ctrl_fpWen),
    .io_out_bits_ctrl_fpu_wflags                      (i2f_io_out_bits_ctrl_fpu_wflags),
    .io_out_bits_res_data                             (i2f_io_out_bits_res_data),
    .io_out_bits_res_fflags                           (i2f_io_out_bits_res_fflags),
    .io_out_bits_perfDebugInfo_eliminatedMove         (i2f_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime             (i2f_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime           (i2f_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime              (i2f_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime             (i2f_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime              (i2f_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime          (i2f_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (i2f_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime        (i2f_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime            (i2f_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                  (i2f_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx                  (i2f_io_out_bits_debug_seqNum_uopIdx),
    .io_frm                                           (io_frm)
  );
  VSetRiWi VSetRiWi (
    .io_in_ready                                      (VSetRiWi_io_in_ready),
    .io_in_valid                                      (in1ToN_io_out_3_valid),
    .io_in_bits_ctrl_fuOpType                         (in1ToN_io_out_3_bits_fuOpType),
    .io_in_bits_ctrl_robIdx_flag                      (in1ToN_io_out_3_bits_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value                     (in1ToN_io_out_3_bits_robIdx_value),
    .io_in_bits_ctrl_pdest                            (in1ToN_io_out_3_bits_pdest),
    .io_in_bits_ctrl_rfWen                            (in1ToN_io_out_3_bits_rfWen),
    .io_in_bits_data_src_1                            (io_in_bits_src_1),
    .io_in_bits_data_src_0                            (io_in_bits_src_0),
    .io_in_bits_perfDebugInfo_eliminatedMove          (in1ToN_io_out_3_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime              (in1ToN_io_out_3_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime            (in1ToN_io_out_3_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime               (in1ToN_io_out_3_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime              (in1ToN_io_out_3_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime               (in1ToN_io_out_3_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime           (in1ToN_io_out_3_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id  (in1ToN_io_out_3_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime         (in1ToN_io_out_3_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime             (in1ToN_io_out_3_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum                   (in1ToN_io_out_3_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx                   (in1ToN_io_out_3_bits_debug_seqNum_uopIdx),
    .io_out_ready                                     (io_out_ready),
    .io_out_valid                                     (VSetRiWi_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag                     (VSetRiWi_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value                    (VSetRiWi_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest                           (VSetRiWi_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_rfWen                           (VSetRiWi_io_out_bits_ctrl_rfWen),
    .io_out_bits_res_data                             (VSetRiWi_io_out_bits_res_data),
    .io_out_bits_perfDebugInfo_eliminatedMove         (VSetRiWi_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime             (VSetRiWi_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime           (VSetRiWi_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime              (VSetRiWi_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime             (VSetRiWi_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime              (VSetRiWi_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime          (VSetRiWi_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (VSetRiWi_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime        (VSetRiWi_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime            (VSetRiWi_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                  (VSetRiWi_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx                  (VSetRiWi_io_out_bits_debug_seqNum_uopIdx)
  );
  VSetRiWvf VSetRiWvf (
    .io_in_ready                                      (VSetRiWvf_io_in_ready),
    .io_in_valid                                      (in1ToN_io_out_4_valid),
    .io_in_bits_ctrl_fuOpType                         (in1ToN_io_out_4_bits_fuOpType),
    .io_in_bits_ctrl_robIdx_flag                      (in1ToN_io_out_4_bits_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value                     (in1ToN_io_out_4_bits_robIdx_value),
    .io_in_bits_ctrl_pdest                            (in1ToN_io_out_4_bits_pdest),
    .io_in_bits_ctrl_vlWen                            (in1ToN_io_out_4_bits_vlWen),
    .io_in_bits_data_src_1                            (io_in_bits_src_1),
    .io_in_bits_data_src_0                            (io_in_bits_src_0),
    .io_in_bits_perfDebugInfo_eliminatedMove          (in1ToN_io_out_4_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime              (in1ToN_io_out_4_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime            (in1ToN_io_out_4_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime               (in1ToN_io_out_4_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime              (in1ToN_io_out_4_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime               (in1ToN_io_out_4_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime           (in1ToN_io_out_4_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id  (in1ToN_io_out_4_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime         (in1ToN_io_out_4_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime             (in1ToN_io_out_4_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum                   (in1ToN_io_out_4_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx                   (in1ToN_io_out_4_bits_debug_seqNum_uopIdx),
    .io_out_ready                                     (io_out_ready),
    .io_out_valid                                     (VSetRiWvf_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag                     (VSetRiWvf_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value                    (VSetRiWvf_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest                           (VSetRiWvf_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_vlWen                           (VSetRiWvf_io_out_bits_ctrl_vlWen),
    .io_out_bits_res_data                             (VSetRiWvf_io_out_bits_res_data),
    .io_out_bits_perfDebugInfo_eliminatedMove         (VSetRiWvf_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime             (VSetRiWvf_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime           (VSetRiWvf_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime              (VSetRiWvf_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime             (VSetRiWvf_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime              (VSetRiWvf_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime          (VSetRiWvf_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (VSetRiWvf_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime        (VSetRiWvf_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime            (VSetRiWvf_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                  (VSetRiWvf_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx                  (VSetRiWvf_io_out_bits_debug_seqNum_uopIdx),
    .io_vtype_valid                                   (io_vtype_valid),
    .io_vtype_bits_illegal                            (io_vtype_bits_illegal),
    .io_vtype_bits_vma                                (io_vtype_bits_vma),
    .io_vtype_bits_vta                                (io_vtype_bits_vta),
    .io_vtype_bits_vsew                               (io_vtype_bits_vsew),
    .io_vtype_bits_vlmul                              (io_vtype_bits_vlmul),
    .io_vlIsZero                                      (io_vlIsZero),
    .io_vlIsVlmax                                     (io_vlIsVlmax)
  );
  IntFPToVec i2v (
    .io_in_ready                                      (i2v_io_in_ready),
    .io_in_valid                                      (in1ToN_io_out_5_valid),
    .io_in_bits_ctrl_fuOpType                         (in1ToN_io_out_5_bits_fuOpType),
    .io_in_bits_ctrl_robIdx_flag                      (in1ToN_io_out_5_bits_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value                     (in1ToN_io_out_5_bits_robIdx_value),
    .io_in_bits_ctrl_pdest                            (in1ToN_io_out_5_bits_pdest),
    .io_in_bits_ctrl_fpWen                            (in1ToN_io_out_5_bits_fpWen),
    .io_in_bits_ctrl_vecWen                           (in1ToN_io_out_5_bits_vecWen),
    .io_in_bits_ctrl_v0Wen                            (in1ToN_io_out_5_bits_v0Wen),
    .io_in_bits_validPipe_0                           (io_in_valid),
    .io_in_bits_data_src_1                            (io_in_bits_src_1),
    .io_in_bits_data_src_0                            (io_in_bits_src_0),
    .io_in_bits_perfDebugInfo_eliminatedMove          (in1ToN_io_out_5_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime              (in1ToN_io_out_5_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime            (in1ToN_io_out_5_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime               (in1ToN_io_out_5_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime              (in1ToN_io_out_5_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime               (in1ToN_io_out_5_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime           (in1ToN_io_out_5_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id  (in1ToN_io_out_5_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime         (in1ToN_io_out_5_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime             (in1ToN_io_out_5_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum                   (in1ToN_io_out_5_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx                   (in1ToN_io_out_5_bits_debug_seqNum_uopIdx),
    .io_out_ready                                     (io_out_ready),
    .io_out_valid                                     (i2v_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag                     (i2v_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value                    (i2v_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest                           (i2v_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_fpWen                           (i2v_io_out_bits_ctrl_fpWen),
    .io_out_bits_ctrl_vecWen                          (i2v_io_out_bits_ctrl_vecWen),
    .io_out_bits_ctrl_v0Wen                           (i2v_io_out_bits_ctrl_v0Wen),
    .io_out_bits_res_data                             (i2v_io_out_bits_res_data),
    .io_out_bits_perfDebugInfo_eliminatedMove         (i2v_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime             (i2v_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime           (i2v_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime              (i2v_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime             (i2v_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime              (i2v_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime          (i2v_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (i2v_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime        (i2v_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime            (i2v_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum                  (i2v_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx                  (i2v_io_out_bits_debug_seqNum_uopIdx)
  );

  // ---- 时钟门控（E 来自核 §3；TE 来自 DFT 的 cg_bore）----
  ClockGate ClockGate (
    .TE (cg_bore_cgen),
    .E  (fu_clk_en[2]),
    .CK (clock),
    .Q  (ClockGate_Q)
  );

  // ---- 写回：io.out.valid 与各字段的 Mux1H ----
  assign io_out_valid = out_valid;
  assign io_out_bits_data_3 = i2v_io_out_bits_res_data;   // 只有 i2v 产出：单元素 Mux1H 直通
  assign io_out_bits_data_4 = i2v_io_out_bits_res_data;   // 只有 i2v 产出：单元素 Mux1H 直通
  assign io_out_bits_data_5 = {64'h0, VSetRiWvf_io_out_bits_res_data};   // 只有 VSetRiWvf 产出：单元素 Mux1H 直通
  // 第 0 组：brh, jmp, i2f, VSetRiWi, VSetRiWvf, i2v 共同产出 —— data_0, pdest, robIdx_flag, robIdx_value, debugInfo_eliminatedMove, debugInfo_renameTime, debugInfo_dispatchTime, debugInfo_enqRsTime, debugInfo_selectTime, debugInfo_issueTime, debugInfo_writebackTime, debugInfo_runahead_checkpoint_id, debugInfo_tlbFirstReqTime, debugInfo_tlbRespTime, debug_seqNum_seqNum, debug_seqNum_uopIdx
  wire [785:0] wb0_out;
  xs_ExeUnit_wbsel #(.N(6), .W(786)) wb0 (
    .sel  ({i2v_io_out_valid, VSetRiWvf_io_out_valid, VSetRiWi_io_out_valid, i2f_io_out_valid, jmp_io_out_valid, brh_io_out_valid}),
    .data ({
      {i2v_io_out_bits_res_data,
       i2v_io_out_bits_ctrl_pdest,
       i2v_io_out_bits_ctrl_robIdx_flag,
       i2v_io_out_bits_ctrl_robIdx_value,
       i2v_io_out_bits_perfDebugInfo_eliminatedMove,
       i2v_io_out_bits_perfDebugInfo_renameTime,
       i2v_io_out_bits_perfDebugInfo_dispatchTime,
       i2v_io_out_bits_perfDebugInfo_enqRsTime,
       i2v_io_out_bits_perfDebugInfo_selectTime,
       i2v_io_out_bits_perfDebugInfo_issueTime,
       i2v_io_out_bits_perfDebugInfo_writebackTime,
       i2v_io_out_bits_perfDebugInfo_runahead_checkpoint_id,
       i2v_io_out_bits_perfDebugInfo_tlbFirstReqTime,
       i2v_io_out_bits_perfDebugInfo_tlbRespTime,
       i2v_io_out_bits_debug_seqNum_seqNum,
       i2v_io_out_bits_debug_seqNum_uopIdx},
      {{64'h0, VSetRiWvf_io_out_bits_res_data},
       VSetRiWvf_io_out_bits_ctrl_pdest,
       VSetRiWvf_io_out_bits_ctrl_robIdx_flag,
       VSetRiWvf_io_out_bits_ctrl_robIdx_value,
       VSetRiWvf_io_out_bits_perfDebugInfo_eliminatedMove,
       VSetRiWvf_io_out_bits_perfDebugInfo_renameTime,
       VSetRiWvf_io_out_bits_perfDebugInfo_dispatchTime,
       VSetRiWvf_io_out_bits_perfDebugInfo_enqRsTime,
       VSetRiWvf_io_out_bits_perfDebugInfo_selectTime,
       VSetRiWvf_io_out_bits_perfDebugInfo_issueTime,
       VSetRiWvf_io_out_bits_perfDebugInfo_writebackTime,
       VSetRiWvf_io_out_bits_perfDebugInfo_runahead_checkpoint_id,
       VSetRiWvf_io_out_bits_perfDebugInfo_tlbFirstReqTime,
       VSetRiWvf_io_out_bits_perfDebugInfo_tlbRespTime,
       VSetRiWvf_io_out_bits_debug_seqNum_seqNum,
       VSetRiWvf_io_out_bits_debug_seqNum_uopIdx},
      {{64'h0, VSetRiWi_io_out_bits_res_data},
       VSetRiWi_io_out_bits_ctrl_pdest,
       VSetRiWi_io_out_bits_ctrl_robIdx_flag,
       VSetRiWi_io_out_bits_ctrl_robIdx_value,
       VSetRiWi_io_out_bits_perfDebugInfo_eliminatedMove,
       VSetRiWi_io_out_bits_perfDebugInfo_renameTime,
       VSetRiWi_io_out_bits_perfDebugInfo_dispatchTime,
       VSetRiWi_io_out_bits_perfDebugInfo_enqRsTime,
       VSetRiWi_io_out_bits_perfDebugInfo_selectTime,
       VSetRiWi_io_out_bits_perfDebugInfo_issueTime,
       VSetRiWi_io_out_bits_perfDebugInfo_writebackTime,
       VSetRiWi_io_out_bits_perfDebugInfo_runahead_checkpoint_id,
       VSetRiWi_io_out_bits_perfDebugInfo_tlbFirstReqTime,
       VSetRiWi_io_out_bits_perfDebugInfo_tlbRespTime,
       VSetRiWi_io_out_bits_debug_seqNum_seqNum,
       VSetRiWi_io_out_bits_debug_seqNum_uopIdx},
      {{64'h0, i2f_io_out_bits_res_data},
       i2f_io_out_bits_ctrl_pdest,
       i2f_io_out_bits_ctrl_robIdx_flag,
       i2f_io_out_bits_ctrl_robIdx_value,
       i2f_io_out_bits_perfDebugInfo_eliminatedMove,
       i2f_io_out_bits_perfDebugInfo_renameTime,
       i2f_io_out_bits_perfDebugInfo_dispatchTime,
       i2f_io_out_bits_perfDebugInfo_enqRsTime,
       i2f_io_out_bits_perfDebugInfo_selectTime,
       i2f_io_out_bits_perfDebugInfo_issueTime,
       i2f_io_out_bits_perfDebugInfo_writebackTime,
       i2f_io_out_bits_perfDebugInfo_runahead_checkpoint_id,
       i2f_io_out_bits_perfDebugInfo_tlbFirstReqTime,
       i2f_io_out_bits_perfDebugInfo_tlbRespTime,
       i2f_io_out_bits_debug_seqNum_seqNum,
       i2f_io_out_bits_debug_seqNum_uopIdx},
      {{64'h0, jmp_io_out_bits_res_data},
       jmp_io_out_bits_ctrl_pdest,
       jmp_io_out_bits_ctrl_robIdx_flag,
       jmp_io_out_bits_ctrl_robIdx_value,
       jmp_io_out_bits_perfDebugInfo_eliminatedMove,
       jmp_io_out_bits_perfDebugInfo_renameTime,
       jmp_io_out_bits_perfDebugInfo_dispatchTime,
       jmp_io_out_bits_perfDebugInfo_enqRsTime,
       jmp_io_out_bits_perfDebugInfo_selectTime,
       jmp_io_out_bits_perfDebugInfo_issueTime,
       jmp_io_out_bits_perfDebugInfo_writebackTime,
       jmp_io_out_bits_perfDebugInfo_runahead_checkpoint_id,
       jmp_io_out_bits_perfDebugInfo_tlbFirstReqTime,
       jmp_io_out_bits_perfDebugInfo_tlbRespTime,
       jmp_io_out_bits_debug_seqNum_seqNum,
       jmp_io_out_bits_debug_seqNum_uopIdx},
      {{64'h0, brh_io_out_bits_res_data},
       brh_io_out_bits_ctrl_pdest,
       brh_io_out_bits_ctrl_robIdx_flag,
       brh_io_out_bits_ctrl_robIdx_value,
       brh_io_out_bits_perfDebugInfo_eliminatedMove,
       brh_io_out_bits_perfDebugInfo_renameTime,
       brh_io_out_bits_perfDebugInfo_dispatchTime,
       brh_io_out_bits_perfDebugInfo_enqRsTime,
       brh_io_out_bits_perfDebugInfo_selectTime,
       brh_io_out_bits_perfDebugInfo_issueTime,
       brh_io_out_bits_perfDebugInfo_writebackTime,
       brh_io_out_bits_perfDebugInfo_runahead_checkpoint_id,
       brh_io_out_bits_perfDebugInfo_tlbFirstReqTime,
       brh_io_out_bits_perfDebugInfo_tlbRespTime,
       brh_io_out_bits_debug_seqNum_seqNum,
       brh_io_out_bits_debug_seqNum_uopIdx}
    }),
    .out  (wb0_out)
  );
  assign {
    io_out_bits_data_0,
    io_out_bits_pdest,
    io_out_bits_robIdx_flag,
    io_out_bits_robIdx_value,
    io_out_bits_debugInfo_eliminatedMove,
    io_out_bits_debugInfo_renameTime,
    io_out_bits_debugInfo_dispatchTime,
    io_out_bits_debugInfo_enqRsTime,
    io_out_bits_debugInfo_selectTime,
    io_out_bits_debugInfo_issueTime,
    io_out_bits_debugInfo_writebackTime,
    io_out_bits_debugInfo_runahead_checkpoint_id,
    io_out_bits_debugInfo_tlbFirstReqTime,
    io_out_bits_debugInfo_tlbRespTime,
    io_out_bits_debug_seqNum_seqNum,
    io_out_bits_debug_seqNum_uopIdx
  } = wb0_out;
  // 第 1 组：jmp, VSetRiWi 共同产出 —— data_1, intWen
  wire [128:0] wb1_out;
  xs_ExeUnit_wbsel #(.N(2), .W(129)) wb1 (
    .sel  ({VSetRiWi_io_out_valid, jmp_io_out_valid}),
    .data ({
      {{64'h0, VSetRiWi_io_out_bits_res_data},
       VSetRiWi_io_out_bits_ctrl_rfWen},
      {{64'h0, jmp_io_out_bits_res_data},
       jmp_io_out_bits_ctrl_rfWen}
    }),
    .out  (wb1_out)
  );
  assign {
    io_out_bits_data_1,
    io_out_bits_intWen
  } = wb1_out;
  // 第 2 组：i2f, i2v 共同产出 —— data_2, fpWen
  wire [128:0] wb2_out;
  xs_ExeUnit_wbsel #(.N(2), .W(129)) wb2 (
    .sel  ({i2v_io_out_valid, i2f_io_out_valid}),
    .data ({
      {i2v_io_out_bits_res_data,
       i2v_io_out_bits_ctrl_fpWen},
      {{64'h0, i2f_io_out_bits_res_data},
       i2f_io_out_bits_ctrl_fpWen}
    }),
    .out  (wb2_out)
  );
  assign {
    io_out_bits_data_2,
    io_out_bits_fpWen
  } = wb2_out;
  // 第 3 组：i2v 共同产出 —— vecWen, v0Wen
  wire [1:0] wb3_out;
  xs_ExeUnit_wbsel #(.N(1), .W(2)) wb3 (
    .sel  ({i2v_io_out_valid}),
    .data ({
      {i2v_io_out_bits_ctrl_vecWen,
       i2v_io_out_bits_ctrl_v0Wen}
    }),
    .out  (wb3_out)
  );
  assign {
    io_out_bits_vecWen,
    io_out_bits_v0Wen
  } = wb3_out;
  // 第 4 组：VSetRiWvf 共同产出 —— vlWen
  wire [0:0] wb4_out;
  xs_ExeUnit_wbsel #(.N(1), .W(1)) wb4 (
    .sel  ({VSetRiWvf_io_out_valid}),
    .data ({
      VSetRiWvf_io_out_bits_ctrl_vlWen
    }),
    .out  (wb4_out)
  );
  assign io_out_bits_vlWen = wb4_out;
  // 第 5 组：brh, jmp 共同产出 —— redirect_valid, redirect_bits_isRVC, redirect_bits_robIdx_flag, redirect_bits_robIdx_value, redirect_bits_ftqIdx_flag, redirect_bits_ftqIdx_value, redirect_bits_ftqOffset, redirect_bits_level, redirect_bits_interrupt, redirect_bits_cfiUpdate_pc, redirect_bits_cfiUpdate_pd_valid, redirect_bits_cfiUpdate_pd_isRVC, redirect_bits_cfiUpdate_pd_brType, redirect_bits_cfiUpdate_pd_isCall, redirect_bits_cfiUpdate_pd_isRet, redirect_bits_cfiUpdate_ssp, redirect_bits_cfiUpdate_sctr, redirect_bits_cfiUpdate_TOSW_flag, redirect_bits_cfiUpdate_TOSW_value, redirect_bits_cfiUpdate_TOSR_flag, redirect_bits_cfiUpdate_TOSR_value, redirect_bits_cfiUpdate_NOS_flag, redirect_bits_cfiUpdate_NOS_value, redirect_bits_cfiUpdate_topAddr, redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist, redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist, redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist, redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist, redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist, redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist, redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist, redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist, redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist, redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist, redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist, redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist, redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist, redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist, redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist, redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist, redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist, redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist, redirect_bits_cfiUpdate_afhob_afhob_5_bits_0, redirect_bits_cfiUpdate_afhob_afhob_5_bits_1, redirect_bits_cfiUpdate_afhob_afhob_5_bits_2, redirect_bits_cfiUpdate_afhob_afhob_5_bits_3, redirect_bits_cfiUpdate_afhob_afhob_4_bits_0, redirect_bits_cfiUpdate_afhob_afhob_4_bits_1, redirect_bits_cfiUpdate_afhob_afhob_4_bits_2, redirect_bits_cfiUpdate_afhob_afhob_4_bits_3, redirect_bits_cfiUpdate_afhob_afhob_3_bits_0, redirect_bits_cfiUpdate_afhob_afhob_3_bits_1, redirect_bits_cfiUpdate_afhob_afhob_3_bits_2, redirect_bits_cfiUpdate_afhob_afhob_3_bits_3, redirect_bits_cfiUpdate_afhob_afhob_2_bits_0, redirect_bits_cfiUpdate_afhob_afhob_2_bits_1, redirect_bits_cfiUpdate_afhob_afhob_2_bits_2, redirect_bits_cfiUpdate_afhob_afhob_2_bits_3, redirect_bits_cfiUpdate_afhob_afhob_1_bits_0, redirect_bits_cfiUpdate_afhob_afhob_1_bits_1, redirect_bits_cfiUpdate_afhob_afhob_1_bits_2, redirect_bits_cfiUpdate_afhob_afhob_1_bits_3, redirect_bits_cfiUpdate_afhob_afhob_0_bits_0, redirect_bits_cfiUpdate_afhob_afhob_0_bits_1, redirect_bits_cfiUpdate_afhob_afhob_0_bits_2, redirect_bits_cfiUpdate_afhob_afhob_0_bits_3, redirect_bits_cfiUpdate_lastBrNumOH, redirect_bits_cfiUpdate_ghr, redirect_bits_cfiUpdate_histPtr_flag, redirect_bits_cfiUpdate_histPtr_value, redirect_bits_cfiUpdate_specCnt_0, redirect_bits_cfiUpdate_specCnt_1, redirect_bits_cfiUpdate_br_hit, redirect_bits_cfiUpdate_jr_hit, redirect_bits_cfiUpdate_sc_hit, redirect_bits_cfiUpdate_predTaken, redirect_bits_cfiUpdate_target, redirect_bits_cfiUpdate_taken, redirect_bits_cfiUpdate_isMisPred, redirect_bits_cfiUpdate_shift, redirect_bits_cfiUpdate_addIntoHist, redirect_bits_cfiUpdate_backendIGPF, redirect_bits_cfiUpdate_backendIPF, redirect_bits_cfiUpdate_backendIAF, redirect_bits_fullTarget, redirect_bits_satpFlush, redirect_bits_isVlsException, redirect_bits_stFtqIdx_flag, redirect_bits_stFtqIdx_value, redirect_bits_stFtqOffset, redirect_bits_debug_runahead_checkpoint_id, redirect_bits_debugIsCtrl, redirect_bits_debugIsMemVio, predecodeInfo_valid, predecodeInfo_isRVC, predecodeInfo_brType, predecodeInfo_isCall, predecodeInfo_isRet
  wire [573:0] wb5_out;
  xs_ExeUnit_wbsel #(.N(2), .W(574)) wb5 (
    .sel  ({jmp_io_out_valid, brh_io_out_valid}),
    .data ({
      {jmp_io_out_bits_res_redirect_valid,
       jmp_io_out_bits_res_redirect_bits_isRVC,
       jmp_io_out_bits_res_redirect_bits_robIdx_flag,
       jmp_io_out_bits_res_redirect_bits_robIdx_value,
       jmp_io_out_bits_res_redirect_bits_ftqIdx_flag,
       jmp_io_out_bits_res_redirect_bits_ftqIdx_value,
       jmp_io_out_bits_res_redirect_bits_ftqOffset,
       jmp_io_out_bits_res_redirect_bits_level,
       jmp_io_out_bits_res_redirect_bits_interrupt,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_pc,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_pd_valid,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_pd_brType,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_ssp,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_sctr,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_NOS_value,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_topAddr,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_ghr,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_br_hit,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_jr_hit,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_sc_hit,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_predTaken,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_target,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_taken,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_isMisPred,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_shift,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_backendIPF,
       jmp_io_out_bits_res_redirect_bits_cfiUpdate_backendIAF,
       jmp_io_out_bits_res_redirect_bits_fullTarget,
       jmp_io_out_bits_res_redirect_bits_satpFlush,
       jmp_io_out_bits_res_redirect_bits_isVlsException,
       jmp_io_out_bits_res_redirect_bits_stFtqIdx_flag,
       jmp_io_out_bits_res_redirect_bits_stFtqIdx_value,
       jmp_io_out_bits_res_redirect_bits_stFtqOffset,
       jmp_io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id,
       jmp_io_out_bits_res_redirect_bits_debugIsCtrl,
       jmp_io_out_bits_res_redirect_bits_debugIsMemVio,
       jmp_io_out_bits_ctrl_preDecode_valid,
       jmp_io_out_bits_ctrl_preDecode_isRVC,
       jmp_io_out_bits_ctrl_preDecode_brType,
       jmp_io_out_bits_ctrl_preDecode_isCall,
       jmp_io_out_bits_ctrl_preDecode_isRet},
      {brh_io_out_bits_res_redirect_valid,
       brh_io_out_bits_res_redirect_bits_isRVC,
       brh_io_out_bits_res_redirect_bits_robIdx_flag,
       brh_io_out_bits_res_redirect_bits_robIdx_value,
       brh_io_out_bits_res_redirect_bits_ftqIdx_flag,
       brh_io_out_bits_res_redirect_bits_ftqIdx_value,
       brh_io_out_bits_res_redirect_bits_ftqOffset,
       brh_io_out_bits_res_redirect_bits_level,
       brh_io_out_bits_res_redirect_bits_interrupt,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_pc,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_pd_valid,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_pd_brType,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_ssp,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_sctr,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_NOS_value,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_topAddr,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_ghr,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_br_hit,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_jr_hit,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_sc_hit,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_predTaken,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_target,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_taken,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_isMisPred,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_shift,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_backendIPF,
       brh_io_out_bits_res_redirect_bits_cfiUpdate_backendIAF,
       brh_io_out_bits_res_redirect_bits_fullTarget,
       brh_io_out_bits_res_redirect_bits_satpFlush,
       brh_io_out_bits_res_redirect_bits_isVlsException,
       brh_io_out_bits_res_redirect_bits_stFtqIdx_flag,
       brh_io_out_bits_res_redirect_bits_stFtqIdx_value,
       brh_io_out_bits_res_redirect_bits_stFtqOffset,
       brh_io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id,
       brh_io_out_bits_res_redirect_bits_debugIsCtrl,
       brh_io_out_bits_res_redirect_bits_debugIsMemVio,
       brh_io_out_bits_ctrl_preDecode_valid,
       brh_io_out_bits_ctrl_preDecode_isRVC,
       brh_io_out_bits_ctrl_preDecode_brType,
       brh_io_out_bits_ctrl_preDecode_isCall,
       brh_io_out_bits_ctrl_preDecode_isRet}
    }),
    .out  (wb5_out)
  );
  assign {
    io_out_bits_redirect_valid,
    io_out_bits_redirect_bits_isRVC,
    io_out_bits_redirect_bits_robIdx_flag,
    io_out_bits_redirect_bits_robIdx_value,
    io_out_bits_redirect_bits_ftqIdx_flag,
    io_out_bits_redirect_bits_ftqIdx_value,
    io_out_bits_redirect_bits_ftqOffset,
    io_out_bits_redirect_bits_level,
    io_out_bits_redirect_bits_interrupt,
    io_out_bits_redirect_bits_cfiUpdate_pc,
    io_out_bits_redirect_bits_cfiUpdate_pd_valid,
    io_out_bits_redirect_bits_cfiUpdate_pd_isRVC,
    io_out_bits_redirect_bits_cfiUpdate_pd_brType,
    io_out_bits_redirect_bits_cfiUpdate_pd_isCall,
    io_out_bits_redirect_bits_cfiUpdate_pd_isRet,
    io_out_bits_redirect_bits_cfiUpdate_ssp,
    io_out_bits_redirect_bits_cfiUpdate_sctr,
    io_out_bits_redirect_bits_cfiUpdate_TOSW_flag,
    io_out_bits_redirect_bits_cfiUpdate_TOSW_value,
    io_out_bits_redirect_bits_cfiUpdate_TOSR_flag,
    io_out_bits_redirect_bits_cfiUpdate_TOSR_value,
    io_out_bits_redirect_bits_cfiUpdate_NOS_flag,
    io_out_bits_redirect_bits_cfiUpdate_NOS_value,
    io_out_bits_redirect_bits_cfiUpdate_topAddr,
    io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist,
    io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist,
    io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist,
    io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist,
    io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist,
    io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist,
    io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist,
    io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist,
    io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist,
    io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist,
    io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist,
    io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist,
    io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist,
    io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist,
    io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist,
    io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist,
    io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist,
    io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist,
    io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0,
    io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1,
    io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2,
    io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3,
    io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0,
    io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1,
    io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2,
    io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3,
    io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0,
    io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1,
    io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2,
    io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3,
    io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0,
    io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1,
    io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2,
    io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3,
    io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0,
    io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1,
    io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2,
    io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3,
    io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0,
    io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1,
    io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2,
    io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3,
    io_out_bits_redirect_bits_cfiUpdate_lastBrNumOH,
    io_out_bits_redirect_bits_cfiUpdate_ghr,
    io_out_bits_redirect_bits_cfiUpdate_histPtr_flag,
    io_out_bits_redirect_bits_cfiUpdate_histPtr_value,
    io_out_bits_redirect_bits_cfiUpdate_specCnt_0,
    io_out_bits_redirect_bits_cfiUpdate_specCnt_1,
    io_out_bits_redirect_bits_cfiUpdate_br_hit,
    io_out_bits_redirect_bits_cfiUpdate_jr_hit,
    io_out_bits_redirect_bits_cfiUpdate_sc_hit,
    io_out_bits_redirect_bits_cfiUpdate_predTaken,
    io_out_bits_redirect_bits_cfiUpdate_target,
    io_out_bits_redirect_bits_cfiUpdate_taken,
    io_out_bits_redirect_bits_cfiUpdate_isMisPred,
    io_out_bits_redirect_bits_cfiUpdate_shift,
    io_out_bits_redirect_bits_cfiUpdate_addIntoHist,
    io_out_bits_redirect_bits_cfiUpdate_backendIGPF,
    io_out_bits_redirect_bits_cfiUpdate_backendIPF,
    io_out_bits_redirect_bits_cfiUpdate_backendIAF,
    io_out_bits_redirect_bits_fullTarget,
    io_out_bits_redirect_bits_satpFlush,
    io_out_bits_redirect_bits_isVlsException,
    io_out_bits_redirect_bits_stFtqIdx_flag,
    io_out_bits_redirect_bits_stFtqIdx_value,
    io_out_bits_redirect_bits_stFtqOffset,
    io_out_bits_redirect_bits_debug_runahead_checkpoint_id,
    io_out_bits_redirect_bits_debugIsCtrl,
    io_out_bits_redirect_bits_debugIsMemVio,
    io_out_bits_predecodeInfo_valid,
    io_out_bits_predecodeInfo_isRVC,
    io_out_bits_predecodeInfo_brType,
    io_out_bits_predecodeInfo_isCall,
    io_out_bits_predecodeInfo_isRet
  } = wb5_out;
  // 第 6 组：i2f 共同产出 —— fflags, wflags
  wire [5:0] wb6_out;
  xs_ExeUnit_wbsel #(.N(1), .W(6)) wb6 (
    .sel  ({i2f_io_out_valid}),
    .data ({
      {i2f_io_out_bits_res_fflags,
       i2f_io_out_bits_ctrl_fpu_wflags}
    }),
    .out  (wb6_out)
  );
  assign {
    io_out_bits_fflags,
    io_out_bits_wflags
  } = wb6_out;

endmodule
