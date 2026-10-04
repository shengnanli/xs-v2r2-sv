// =============================================================================
// tb —— ExeUnit_1 双例化 UT（由 scripts/gen_exeunits_ut.py 生成，勿手改）
//   golden ExeUnit_1 vs 重写 ExeUnit_1_xs；每拍比较全部 118 个输出口（!==）。
//   激励 / 覆盖 / 判据见生成器 TARGETS 里本目标一节。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int WARM = 21;
  localparam int RESET_ODDS = 20000;
  longint errors = 0, checks = 0;
  int cyc;
  bit clock = 0;
  always #5 clock = ~clock;
  logic reset;

  logic io_in_valid;
  logic [34:0] io_in_bits_fuType;
  logic [8:0] io_in_bits_fuOpType;
  logic [63:0] io_in_bits_src_0;
  logic [63:0] io_in_bits_src_1;
  logic [63:0] io_in_bits_imm;
  logic [4:0] io_in_bits_nextPcOffset;
  logic io_in_bits_robIdx_flag;
  logic [7:0] io_in_bits_robIdx_value;
  logic [7:0] io_in_bits_pdest;
  logic io_in_bits_rfWen;
  logic [49:0] io_in_bits_pc;
  logic io_in_bits_preDecode_valid;
  logic io_in_bits_preDecode_isRVC;
  logic [1:0] io_in_bits_preDecode_brType;
  logic io_in_bits_preDecode_isCall;
  logic io_in_bits_preDecode_isRet;
  logic io_in_bits_ftqIdx_flag;
  logic [5:0] io_in_bits_ftqIdx_value;
  logic [3:0] io_in_bits_ftqOffset;
  logic [49:0] io_in_bits_predictInfo_target;
  logic io_in_bits_predictInfo_taken;
  logic io_in_bits_perfDebugInfo_eliminatedMove;
  logic [63:0] io_in_bits_perfDebugInfo_renameTime;
  logic [63:0] io_in_bits_perfDebugInfo_dispatchTime;
  logic [63:0] io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] io_in_bits_perfDebugInfo_issueTime;
  logic [63:0] io_in_bits_perfDebugInfo_writebackTime;
  logic [63:0] io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  logic [63:0] io_in_bits_perfDebugInfo_tlbFirstReqTime;
  logic [63:0] io_in_bits_perfDebugInfo_tlbRespTime;
  logic [55:0] io_in_bits_debug_seqNum_seqNum;
  logic [7:0] io_in_bits_debug_seqNum_uopIdx;
  logic io_out_ready;
  logic io_instrAddrTransType_bare;
  logic io_instrAddrTransType_sv39;
  logic io_instrAddrTransType_sv39x4;
  logic io_instrAddrTransType_sv48;
  logic io_instrAddrTransType_sv48x4;
  wire  g_io_in_ready, i_io_in_ready;
  wire  g_io_out_valid, i_io_out_valid;
  wire  [63:0] g_io_out_bits_data_0, i_io_out_bits_data_0;
  wire  [63:0] g_io_out_bits_data_1, i_io_out_bits_data_1;
  wire  [7:0] g_io_out_bits_pdest, i_io_out_bits_pdest;
  wire  g_io_out_bits_robIdx_flag, i_io_out_bits_robIdx_flag;
  wire  [7:0] g_io_out_bits_robIdx_value, i_io_out_bits_robIdx_value;
  wire  g_io_out_bits_intWen, i_io_out_bits_intWen;
  wire  g_io_out_bits_redirect_valid, i_io_out_bits_redirect_valid;
  wire  g_io_out_bits_redirect_bits_isRVC, i_io_out_bits_redirect_bits_isRVC;
  wire  g_io_out_bits_redirect_bits_robIdx_flag, i_io_out_bits_redirect_bits_robIdx_flag;
  wire  [7:0] g_io_out_bits_redirect_bits_robIdx_value, i_io_out_bits_redirect_bits_robIdx_value;
  wire  g_io_out_bits_redirect_bits_ftqIdx_flag, i_io_out_bits_redirect_bits_ftqIdx_flag;
  wire  [5:0] g_io_out_bits_redirect_bits_ftqIdx_value, i_io_out_bits_redirect_bits_ftqIdx_value;
  wire  [3:0] g_io_out_bits_redirect_bits_ftqOffset, i_io_out_bits_redirect_bits_ftqOffset;
  wire  g_io_out_bits_redirect_bits_level, i_io_out_bits_redirect_bits_level;
  wire  g_io_out_bits_redirect_bits_interrupt, i_io_out_bits_redirect_bits_interrupt;
  wire  [49:0] g_io_out_bits_redirect_bits_cfiUpdate_pc, i_io_out_bits_redirect_bits_cfiUpdate_pc;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_pd_valid, i_io_out_bits_redirect_bits_cfiUpdate_pd_valid;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_pd_isRVC, i_io_out_bits_redirect_bits_cfiUpdate_pd_isRVC;
  wire  [1:0] g_io_out_bits_redirect_bits_cfiUpdate_pd_brType, i_io_out_bits_redirect_bits_cfiUpdate_pd_brType;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_pd_isCall, i_io_out_bits_redirect_bits_cfiUpdate_pd_isCall;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_pd_isRet, i_io_out_bits_redirect_bits_cfiUpdate_pd_isRet;
  wire  [3:0] g_io_out_bits_redirect_bits_cfiUpdate_ssp, i_io_out_bits_redirect_bits_cfiUpdate_ssp;
  wire  [2:0] g_io_out_bits_redirect_bits_cfiUpdate_sctr, i_io_out_bits_redirect_bits_cfiUpdate_sctr;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_TOSW_flag, i_io_out_bits_redirect_bits_cfiUpdate_TOSW_flag;
  wire  [4:0] g_io_out_bits_redirect_bits_cfiUpdate_TOSW_value, i_io_out_bits_redirect_bits_cfiUpdate_TOSW_value;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_TOSR_flag, i_io_out_bits_redirect_bits_cfiUpdate_TOSR_flag;
  wire  [4:0] g_io_out_bits_redirect_bits_cfiUpdate_TOSR_value, i_io_out_bits_redirect_bits_cfiUpdate_TOSR_value;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_NOS_flag, i_io_out_bits_redirect_bits_cfiUpdate_NOS_flag;
  wire  [4:0] g_io_out_bits_redirect_bits_cfiUpdate_NOS_value, i_io_out_bits_redirect_bits_cfiUpdate_NOS_value;
  wire  [49:0] g_io_out_bits_redirect_bits_cfiUpdate_topAddr, i_io_out_bits_redirect_bits_cfiUpdate_topAddr;
  wire  [10:0] g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist;
  wire  [10:0] g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist;
  wire  [6:0] g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist;
  wire  [7:0] g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist;
  wire  [8:0] g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist;
  wire  [3:0] g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist;
  wire  [7:0] g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist;
  wire  [8:0] g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist;
  wire  [6:0] g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist;
  wire  [7:0] g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist;
  wire  [6:0] g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist;
  wire  [8:0] g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist;
  wire  [6:0] g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist;
  wire  [7:0] g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist;
  wire  [7:0] g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist;
  wire  [7:0] g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist;
  wire  [10:0] g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist;
  wire  [7:0] g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3;
  wire  [2:0] g_io_out_bits_redirect_bits_cfiUpdate_lastBrNumOH, i_io_out_bits_redirect_bits_cfiUpdate_lastBrNumOH;
  wire  [3:0] g_io_out_bits_redirect_bits_cfiUpdate_ghr, i_io_out_bits_redirect_bits_cfiUpdate_ghr;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_histPtr_flag, i_io_out_bits_redirect_bits_cfiUpdate_histPtr_flag;
  wire  [7:0] g_io_out_bits_redirect_bits_cfiUpdate_histPtr_value, i_io_out_bits_redirect_bits_cfiUpdate_histPtr_value;
  wire  [9:0] g_io_out_bits_redirect_bits_cfiUpdate_specCnt_0, i_io_out_bits_redirect_bits_cfiUpdate_specCnt_0;
  wire  [9:0] g_io_out_bits_redirect_bits_cfiUpdate_specCnt_1, i_io_out_bits_redirect_bits_cfiUpdate_specCnt_1;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_br_hit, i_io_out_bits_redirect_bits_cfiUpdate_br_hit;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_jr_hit, i_io_out_bits_redirect_bits_cfiUpdate_jr_hit;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_sc_hit, i_io_out_bits_redirect_bits_cfiUpdate_sc_hit;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_predTaken, i_io_out_bits_redirect_bits_cfiUpdate_predTaken;
  wire  [49:0] g_io_out_bits_redirect_bits_cfiUpdate_target, i_io_out_bits_redirect_bits_cfiUpdate_target;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_taken, i_io_out_bits_redirect_bits_cfiUpdate_taken;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_isMisPred, i_io_out_bits_redirect_bits_cfiUpdate_isMisPred;
  wire  [1:0] g_io_out_bits_redirect_bits_cfiUpdate_shift, i_io_out_bits_redirect_bits_cfiUpdate_shift;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_addIntoHist, i_io_out_bits_redirect_bits_cfiUpdate_addIntoHist;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_backendIGPF, i_io_out_bits_redirect_bits_cfiUpdate_backendIGPF;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_backendIPF, i_io_out_bits_redirect_bits_cfiUpdate_backendIPF;
  wire  g_io_out_bits_redirect_bits_cfiUpdate_backendIAF, i_io_out_bits_redirect_bits_cfiUpdate_backendIAF;
  wire  [63:0] g_io_out_bits_redirect_bits_fullTarget, i_io_out_bits_redirect_bits_fullTarget;
  wire  g_io_out_bits_redirect_bits_satpFlush, i_io_out_bits_redirect_bits_satpFlush;
  wire  g_io_out_bits_redirect_bits_isVlsException, i_io_out_bits_redirect_bits_isVlsException;
  wire  g_io_out_bits_redirect_bits_stFtqIdx_flag, i_io_out_bits_redirect_bits_stFtqIdx_flag;
  wire  [5:0] g_io_out_bits_redirect_bits_stFtqIdx_value, i_io_out_bits_redirect_bits_stFtqIdx_value;
  wire  [3:0] g_io_out_bits_redirect_bits_stFtqOffset, i_io_out_bits_redirect_bits_stFtqOffset;
  wire  [63:0] g_io_out_bits_redirect_bits_debug_runahead_checkpoint_id, i_io_out_bits_redirect_bits_debug_runahead_checkpoint_id;
  wire  g_io_out_bits_redirect_bits_debugIsCtrl, i_io_out_bits_redirect_bits_debugIsCtrl;
  wire  g_io_out_bits_redirect_bits_debugIsMemVio, i_io_out_bits_redirect_bits_debugIsMemVio;
  wire  g_io_out_bits_predecodeInfo_valid, i_io_out_bits_predecodeInfo_valid;
  wire  g_io_out_bits_predecodeInfo_isRVC, i_io_out_bits_predecodeInfo_isRVC;
  wire  [1:0] g_io_out_bits_predecodeInfo_brType, i_io_out_bits_predecodeInfo_brType;
  wire  g_io_out_bits_predecodeInfo_isCall, i_io_out_bits_predecodeInfo_isCall;
  wire  g_io_out_bits_predecodeInfo_isRet, i_io_out_bits_predecodeInfo_isRet;
  wire  g_io_out_bits_debugInfo_eliminatedMove, i_io_out_bits_debugInfo_eliminatedMove;
  wire  [63:0] g_io_out_bits_debugInfo_renameTime, i_io_out_bits_debugInfo_renameTime;
  wire  [63:0] g_io_out_bits_debugInfo_dispatchTime, i_io_out_bits_debugInfo_dispatchTime;
  wire  [63:0] g_io_out_bits_debugInfo_enqRsTime, i_io_out_bits_debugInfo_enqRsTime;
  wire  [63:0] g_io_out_bits_debugInfo_selectTime, i_io_out_bits_debugInfo_selectTime;
  wire  [63:0] g_io_out_bits_debugInfo_issueTime, i_io_out_bits_debugInfo_issueTime;
  wire  [63:0] g_io_out_bits_debugInfo_writebackTime, i_io_out_bits_debugInfo_writebackTime;
  wire  [63:0] g_io_out_bits_debugInfo_runahead_checkpoint_id, i_io_out_bits_debugInfo_runahead_checkpoint_id;
  wire  [63:0] g_io_out_bits_debugInfo_tlbFirstReqTime, i_io_out_bits_debugInfo_tlbFirstReqTime;
  wire  [63:0] g_io_out_bits_debugInfo_tlbRespTime, i_io_out_bits_debugInfo_tlbRespTime;
  wire  [55:0] g_io_out_bits_debug_seqNum_seqNum, i_io_out_bits_debug_seqNum_seqNum;
  wire  [7:0] g_io_out_bits_debug_seqNum_uopIdx, i_io_out_bits_debug_seqNum_uopIdx;
  localparam int NFU = 2;
  logic [34:0] fu_code [NFU] = '{35'h2, 35'h1};
  longint c_in [NFU];
  longint c_out [NFU];
  longint c_stall = 0, c_flush = 0, c_nofu = 0, c_cg_on = 0, c_cg_off = 0, c_busy = 0;

  ExeUnit_1 u_g (
    .clock(clock),
    .reset(reset),
    .io_in_valid(io_in_valid),
    .io_in_bits_fuType(io_in_bits_fuType),
    .io_in_bits_fuOpType(io_in_bits_fuOpType),
    .io_in_bits_src_0(io_in_bits_src_0),
    .io_in_bits_src_1(io_in_bits_src_1),
    .io_in_bits_imm(io_in_bits_imm),
    .io_in_bits_nextPcOffset(io_in_bits_nextPcOffset),
    .io_in_bits_robIdx_flag(io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(io_in_bits_robIdx_value),
    .io_in_bits_pdest(io_in_bits_pdest),
    .io_in_bits_rfWen(io_in_bits_rfWen),
    .io_in_bits_pc(io_in_bits_pc),
    .io_in_bits_preDecode_valid(io_in_bits_preDecode_valid),
    .io_in_bits_preDecode_isRVC(io_in_bits_preDecode_isRVC),
    .io_in_bits_preDecode_brType(io_in_bits_preDecode_brType),
    .io_in_bits_preDecode_isCall(io_in_bits_preDecode_isCall),
    .io_in_bits_preDecode_isRet(io_in_bits_preDecode_isRet),
    .io_in_bits_ftqIdx_flag(io_in_bits_ftqIdx_flag),
    .io_in_bits_ftqIdx_value(io_in_bits_ftqIdx_value),
    .io_in_bits_ftqOffset(io_in_bits_ftqOffset),
    .io_in_bits_predictInfo_target(io_in_bits_predictInfo_target),
    .io_in_bits_predictInfo_taken(io_in_bits_predictInfo_taken),
    .io_in_bits_perfDebugInfo_eliminatedMove(io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(io_out_ready),
    .io_instrAddrTransType_bare(io_instrAddrTransType_bare),
    .io_instrAddrTransType_sv39(io_instrAddrTransType_sv39),
    .io_instrAddrTransType_sv39x4(io_instrAddrTransType_sv39x4),
    .io_instrAddrTransType_sv48(io_instrAddrTransType_sv48),
    .io_instrAddrTransType_sv48x4(io_instrAddrTransType_sv48x4),
    .io_in_ready(g_io_in_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_data_0(g_io_out_bits_data_0),
    .io_out_bits_data_1(g_io_out_bits_data_1),
    .io_out_bits_pdest(g_io_out_bits_pdest),
    .io_out_bits_robIdx_flag(g_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(g_io_out_bits_robIdx_value),
    .io_out_bits_intWen(g_io_out_bits_intWen),
    .io_out_bits_redirect_valid(g_io_out_bits_redirect_valid),
    .io_out_bits_redirect_bits_isRVC(g_io_out_bits_redirect_bits_isRVC),
    .io_out_bits_redirect_bits_robIdx_flag(g_io_out_bits_redirect_bits_robIdx_flag),
    .io_out_bits_redirect_bits_robIdx_value(g_io_out_bits_redirect_bits_robIdx_value),
    .io_out_bits_redirect_bits_ftqIdx_flag(g_io_out_bits_redirect_bits_ftqIdx_flag),
    .io_out_bits_redirect_bits_ftqIdx_value(g_io_out_bits_redirect_bits_ftqIdx_value),
    .io_out_bits_redirect_bits_ftqOffset(g_io_out_bits_redirect_bits_ftqOffset),
    .io_out_bits_redirect_bits_level(g_io_out_bits_redirect_bits_level),
    .io_out_bits_redirect_bits_interrupt(g_io_out_bits_redirect_bits_interrupt),
    .io_out_bits_redirect_bits_cfiUpdate_pc(g_io_out_bits_redirect_bits_cfiUpdate_pc),
    .io_out_bits_redirect_bits_cfiUpdate_pd_valid(g_io_out_bits_redirect_bits_cfiUpdate_pd_valid),
    .io_out_bits_redirect_bits_cfiUpdate_pd_isRVC(g_io_out_bits_redirect_bits_cfiUpdate_pd_isRVC),
    .io_out_bits_redirect_bits_cfiUpdate_pd_brType(g_io_out_bits_redirect_bits_cfiUpdate_pd_brType),
    .io_out_bits_redirect_bits_cfiUpdate_pd_isCall(g_io_out_bits_redirect_bits_cfiUpdate_pd_isCall),
    .io_out_bits_redirect_bits_cfiUpdate_pd_isRet(g_io_out_bits_redirect_bits_cfiUpdate_pd_isRet),
    .io_out_bits_redirect_bits_cfiUpdate_ssp(g_io_out_bits_redirect_bits_cfiUpdate_ssp),
    .io_out_bits_redirect_bits_cfiUpdate_sctr(g_io_out_bits_redirect_bits_cfiUpdate_sctr),
    .io_out_bits_redirect_bits_cfiUpdate_TOSW_flag(g_io_out_bits_redirect_bits_cfiUpdate_TOSW_flag),
    .io_out_bits_redirect_bits_cfiUpdate_TOSW_value(g_io_out_bits_redirect_bits_cfiUpdate_TOSW_value),
    .io_out_bits_redirect_bits_cfiUpdate_TOSR_flag(g_io_out_bits_redirect_bits_cfiUpdate_TOSR_flag),
    .io_out_bits_redirect_bits_cfiUpdate_TOSR_value(g_io_out_bits_redirect_bits_cfiUpdate_TOSR_value),
    .io_out_bits_redirect_bits_cfiUpdate_NOS_flag(g_io_out_bits_redirect_bits_cfiUpdate_NOS_flag),
    .io_out_bits_redirect_bits_cfiUpdate_NOS_value(g_io_out_bits_redirect_bits_cfiUpdate_NOS_value),
    .io_out_bits_redirect_bits_cfiUpdate_topAddr(g_io_out_bits_redirect_bits_cfiUpdate_topAddr),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist(g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist(g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist(g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist(g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist(g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist(g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist(g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist(g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist(g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist(g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist(g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist(g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist(g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist(g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist(g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist(g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist(g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist(g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0(g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1(g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2(g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3(g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0(g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1(g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2(g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3(g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0(g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1(g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2(g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3(g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0(g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1(g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2(g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3(g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0(g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1(g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2(g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3(g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0(g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1(g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2(g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3(g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3),
    .io_out_bits_redirect_bits_cfiUpdate_lastBrNumOH(g_io_out_bits_redirect_bits_cfiUpdate_lastBrNumOH),
    .io_out_bits_redirect_bits_cfiUpdate_ghr(g_io_out_bits_redirect_bits_cfiUpdate_ghr),
    .io_out_bits_redirect_bits_cfiUpdate_histPtr_flag(g_io_out_bits_redirect_bits_cfiUpdate_histPtr_flag),
    .io_out_bits_redirect_bits_cfiUpdate_histPtr_value(g_io_out_bits_redirect_bits_cfiUpdate_histPtr_value),
    .io_out_bits_redirect_bits_cfiUpdate_specCnt_0(g_io_out_bits_redirect_bits_cfiUpdate_specCnt_0),
    .io_out_bits_redirect_bits_cfiUpdate_specCnt_1(g_io_out_bits_redirect_bits_cfiUpdate_specCnt_1),
    .io_out_bits_redirect_bits_cfiUpdate_br_hit(g_io_out_bits_redirect_bits_cfiUpdate_br_hit),
    .io_out_bits_redirect_bits_cfiUpdate_jr_hit(g_io_out_bits_redirect_bits_cfiUpdate_jr_hit),
    .io_out_bits_redirect_bits_cfiUpdate_sc_hit(g_io_out_bits_redirect_bits_cfiUpdate_sc_hit),
    .io_out_bits_redirect_bits_cfiUpdate_predTaken(g_io_out_bits_redirect_bits_cfiUpdate_predTaken),
    .io_out_bits_redirect_bits_cfiUpdate_target(g_io_out_bits_redirect_bits_cfiUpdate_target),
    .io_out_bits_redirect_bits_cfiUpdate_taken(g_io_out_bits_redirect_bits_cfiUpdate_taken),
    .io_out_bits_redirect_bits_cfiUpdate_isMisPred(g_io_out_bits_redirect_bits_cfiUpdate_isMisPred),
    .io_out_bits_redirect_bits_cfiUpdate_shift(g_io_out_bits_redirect_bits_cfiUpdate_shift),
    .io_out_bits_redirect_bits_cfiUpdate_addIntoHist(g_io_out_bits_redirect_bits_cfiUpdate_addIntoHist),
    .io_out_bits_redirect_bits_cfiUpdate_backendIGPF(g_io_out_bits_redirect_bits_cfiUpdate_backendIGPF),
    .io_out_bits_redirect_bits_cfiUpdate_backendIPF(g_io_out_bits_redirect_bits_cfiUpdate_backendIPF),
    .io_out_bits_redirect_bits_cfiUpdate_backendIAF(g_io_out_bits_redirect_bits_cfiUpdate_backendIAF),
    .io_out_bits_redirect_bits_fullTarget(g_io_out_bits_redirect_bits_fullTarget),
    .io_out_bits_redirect_bits_satpFlush(g_io_out_bits_redirect_bits_satpFlush),
    .io_out_bits_redirect_bits_isVlsException(g_io_out_bits_redirect_bits_isVlsException),
    .io_out_bits_redirect_bits_stFtqIdx_flag(g_io_out_bits_redirect_bits_stFtqIdx_flag),
    .io_out_bits_redirect_bits_stFtqIdx_value(g_io_out_bits_redirect_bits_stFtqIdx_value),
    .io_out_bits_redirect_bits_stFtqOffset(g_io_out_bits_redirect_bits_stFtqOffset),
    .io_out_bits_redirect_bits_debug_runahead_checkpoint_id(g_io_out_bits_redirect_bits_debug_runahead_checkpoint_id),
    .io_out_bits_redirect_bits_debugIsCtrl(g_io_out_bits_redirect_bits_debugIsCtrl),
    .io_out_bits_redirect_bits_debugIsMemVio(g_io_out_bits_redirect_bits_debugIsMemVio),
    .io_out_bits_predecodeInfo_valid(g_io_out_bits_predecodeInfo_valid),
    .io_out_bits_predecodeInfo_isRVC(g_io_out_bits_predecodeInfo_isRVC),
    .io_out_bits_predecodeInfo_brType(g_io_out_bits_predecodeInfo_brType),
    .io_out_bits_predecodeInfo_isCall(g_io_out_bits_predecodeInfo_isCall),
    .io_out_bits_predecodeInfo_isRet(g_io_out_bits_predecodeInfo_isRet),
    .io_out_bits_debugInfo_eliminatedMove(g_io_out_bits_debugInfo_eliminatedMove),
    .io_out_bits_debugInfo_renameTime(g_io_out_bits_debugInfo_renameTime),
    .io_out_bits_debugInfo_dispatchTime(g_io_out_bits_debugInfo_dispatchTime),
    .io_out_bits_debugInfo_enqRsTime(g_io_out_bits_debugInfo_enqRsTime),
    .io_out_bits_debugInfo_selectTime(g_io_out_bits_debugInfo_selectTime),
    .io_out_bits_debugInfo_issueTime(g_io_out_bits_debugInfo_issueTime),
    .io_out_bits_debugInfo_writebackTime(g_io_out_bits_debugInfo_writebackTime),
    .io_out_bits_debugInfo_runahead_checkpoint_id(g_io_out_bits_debugInfo_runahead_checkpoint_id),
    .io_out_bits_debugInfo_tlbFirstReqTime(g_io_out_bits_debugInfo_tlbFirstReqTime),
    .io_out_bits_debugInfo_tlbRespTime(g_io_out_bits_debugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(g_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(g_io_out_bits_debug_seqNum_uopIdx)
  );
  ExeUnit_1_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_valid(io_in_valid),
    .io_in_bits_fuType(io_in_bits_fuType),
    .io_in_bits_fuOpType(io_in_bits_fuOpType),
    .io_in_bits_src_0(io_in_bits_src_0),
    .io_in_bits_src_1(io_in_bits_src_1),
    .io_in_bits_imm(io_in_bits_imm),
    .io_in_bits_nextPcOffset(io_in_bits_nextPcOffset),
    .io_in_bits_robIdx_flag(io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(io_in_bits_robIdx_value),
    .io_in_bits_pdest(io_in_bits_pdest),
    .io_in_bits_rfWen(io_in_bits_rfWen),
    .io_in_bits_pc(io_in_bits_pc),
    .io_in_bits_preDecode_valid(io_in_bits_preDecode_valid),
    .io_in_bits_preDecode_isRVC(io_in_bits_preDecode_isRVC),
    .io_in_bits_preDecode_brType(io_in_bits_preDecode_brType),
    .io_in_bits_preDecode_isCall(io_in_bits_preDecode_isCall),
    .io_in_bits_preDecode_isRet(io_in_bits_preDecode_isRet),
    .io_in_bits_ftqIdx_flag(io_in_bits_ftqIdx_flag),
    .io_in_bits_ftqIdx_value(io_in_bits_ftqIdx_value),
    .io_in_bits_ftqOffset(io_in_bits_ftqOffset),
    .io_in_bits_predictInfo_target(io_in_bits_predictInfo_target),
    .io_in_bits_predictInfo_taken(io_in_bits_predictInfo_taken),
    .io_in_bits_perfDebugInfo_eliminatedMove(io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(io_out_ready),
    .io_instrAddrTransType_bare(io_instrAddrTransType_bare),
    .io_instrAddrTransType_sv39(io_instrAddrTransType_sv39),
    .io_instrAddrTransType_sv39x4(io_instrAddrTransType_sv39x4),
    .io_instrAddrTransType_sv48(io_instrAddrTransType_sv48),
    .io_instrAddrTransType_sv48x4(io_instrAddrTransType_sv48x4),
    .io_in_ready(i_io_in_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_data_0(i_io_out_bits_data_0),
    .io_out_bits_data_1(i_io_out_bits_data_1),
    .io_out_bits_pdest(i_io_out_bits_pdest),
    .io_out_bits_robIdx_flag(i_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(i_io_out_bits_robIdx_value),
    .io_out_bits_intWen(i_io_out_bits_intWen),
    .io_out_bits_redirect_valid(i_io_out_bits_redirect_valid),
    .io_out_bits_redirect_bits_isRVC(i_io_out_bits_redirect_bits_isRVC),
    .io_out_bits_redirect_bits_robIdx_flag(i_io_out_bits_redirect_bits_robIdx_flag),
    .io_out_bits_redirect_bits_robIdx_value(i_io_out_bits_redirect_bits_robIdx_value),
    .io_out_bits_redirect_bits_ftqIdx_flag(i_io_out_bits_redirect_bits_ftqIdx_flag),
    .io_out_bits_redirect_bits_ftqIdx_value(i_io_out_bits_redirect_bits_ftqIdx_value),
    .io_out_bits_redirect_bits_ftqOffset(i_io_out_bits_redirect_bits_ftqOffset),
    .io_out_bits_redirect_bits_level(i_io_out_bits_redirect_bits_level),
    .io_out_bits_redirect_bits_interrupt(i_io_out_bits_redirect_bits_interrupt),
    .io_out_bits_redirect_bits_cfiUpdate_pc(i_io_out_bits_redirect_bits_cfiUpdate_pc),
    .io_out_bits_redirect_bits_cfiUpdate_pd_valid(i_io_out_bits_redirect_bits_cfiUpdate_pd_valid),
    .io_out_bits_redirect_bits_cfiUpdate_pd_isRVC(i_io_out_bits_redirect_bits_cfiUpdate_pd_isRVC),
    .io_out_bits_redirect_bits_cfiUpdate_pd_brType(i_io_out_bits_redirect_bits_cfiUpdate_pd_brType),
    .io_out_bits_redirect_bits_cfiUpdate_pd_isCall(i_io_out_bits_redirect_bits_cfiUpdate_pd_isCall),
    .io_out_bits_redirect_bits_cfiUpdate_pd_isRet(i_io_out_bits_redirect_bits_cfiUpdate_pd_isRet),
    .io_out_bits_redirect_bits_cfiUpdate_ssp(i_io_out_bits_redirect_bits_cfiUpdate_ssp),
    .io_out_bits_redirect_bits_cfiUpdate_sctr(i_io_out_bits_redirect_bits_cfiUpdate_sctr),
    .io_out_bits_redirect_bits_cfiUpdate_TOSW_flag(i_io_out_bits_redirect_bits_cfiUpdate_TOSW_flag),
    .io_out_bits_redirect_bits_cfiUpdate_TOSW_value(i_io_out_bits_redirect_bits_cfiUpdate_TOSW_value),
    .io_out_bits_redirect_bits_cfiUpdate_TOSR_flag(i_io_out_bits_redirect_bits_cfiUpdate_TOSR_flag),
    .io_out_bits_redirect_bits_cfiUpdate_TOSR_value(i_io_out_bits_redirect_bits_cfiUpdate_TOSR_value),
    .io_out_bits_redirect_bits_cfiUpdate_NOS_flag(i_io_out_bits_redirect_bits_cfiUpdate_NOS_flag),
    .io_out_bits_redirect_bits_cfiUpdate_NOS_value(i_io_out_bits_redirect_bits_cfiUpdate_NOS_value),
    .io_out_bits_redirect_bits_cfiUpdate_topAddr(i_io_out_bits_redirect_bits_cfiUpdate_topAddr),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist(i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist(i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist(i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist(i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist(i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist(i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist(i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist(i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist(i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist(i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist(i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist(i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist(i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist(i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist(i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist(i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist(i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist(i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0(i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1(i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2(i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3(i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0(i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1(i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2(i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3(i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0(i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1(i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2(i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3(i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0(i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1(i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2(i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3(i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0(i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1(i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2(i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3(i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0(i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1(i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2(i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2),
    .io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3(i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3),
    .io_out_bits_redirect_bits_cfiUpdate_lastBrNumOH(i_io_out_bits_redirect_bits_cfiUpdate_lastBrNumOH),
    .io_out_bits_redirect_bits_cfiUpdate_ghr(i_io_out_bits_redirect_bits_cfiUpdate_ghr),
    .io_out_bits_redirect_bits_cfiUpdate_histPtr_flag(i_io_out_bits_redirect_bits_cfiUpdate_histPtr_flag),
    .io_out_bits_redirect_bits_cfiUpdate_histPtr_value(i_io_out_bits_redirect_bits_cfiUpdate_histPtr_value),
    .io_out_bits_redirect_bits_cfiUpdate_specCnt_0(i_io_out_bits_redirect_bits_cfiUpdate_specCnt_0),
    .io_out_bits_redirect_bits_cfiUpdate_specCnt_1(i_io_out_bits_redirect_bits_cfiUpdate_specCnt_1),
    .io_out_bits_redirect_bits_cfiUpdate_br_hit(i_io_out_bits_redirect_bits_cfiUpdate_br_hit),
    .io_out_bits_redirect_bits_cfiUpdate_jr_hit(i_io_out_bits_redirect_bits_cfiUpdate_jr_hit),
    .io_out_bits_redirect_bits_cfiUpdate_sc_hit(i_io_out_bits_redirect_bits_cfiUpdate_sc_hit),
    .io_out_bits_redirect_bits_cfiUpdate_predTaken(i_io_out_bits_redirect_bits_cfiUpdate_predTaken),
    .io_out_bits_redirect_bits_cfiUpdate_target(i_io_out_bits_redirect_bits_cfiUpdate_target),
    .io_out_bits_redirect_bits_cfiUpdate_taken(i_io_out_bits_redirect_bits_cfiUpdate_taken),
    .io_out_bits_redirect_bits_cfiUpdate_isMisPred(i_io_out_bits_redirect_bits_cfiUpdate_isMisPred),
    .io_out_bits_redirect_bits_cfiUpdate_shift(i_io_out_bits_redirect_bits_cfiUpdate_shift),
    .io_out_bits_redirect_bits_cfiUpdate_addIntoHist(i_io_out_bits_redirect_bits_cfiUpdate_addIntoHist),
    .io_out_bits_redirect_bits_cfiUpdate_backendIGPF(i_io_out_bits_redirect_bits_cfiUpdate_backendIGPF),
    .io_out_bits_redirect_bits_cfiUpdate_backendIPF(i_io_out_bits_redirect_bits_cfiUpdate_backendIPF),
    .io_out_bits_redirect_bits_cfiUpdate_backendIAF(i_io_out_bits_redirect_bits_cfiUpdate_backendIAF),
    .io_out_bits_redirect_bits_fullTarget(i_io_out_bits_redirect_bits_fullTarget),
    .io_out_bits_redirect_bits_satpFlush(i_io_out_bits_redirect_bits_satpFlush),
    .io_out_bits_redirect_bits_isVlsException(i_io_out_bits_redirect_bits_isVlsException),
    .io_out_bits_redirect_bits_stFtqIdx_flag(i_io_out_bits_redirect_bits_stFtqIdx_flag),
    .io_out_bits_redirect_bits_stFtqIdx_value(i_io_out_bits_redirect_bits_stFtqIdx_value),
    .io_out_bits_redirect_bits_stFtqOffset(i_io_out_bits_redirect_bits_stFtqOffset),
    .io_out_bits_redirect_bits_debug_runahead_checkpoint_id(i_io_out_bits_redirect_bits_debug_runahead_checkpoint_id),
    .io_out_bits_redirect_bits_debugIsCtrl(i_io_out_bits_redirect_bits_debugIsCtrl),
    .io_out_bits_redirect_bits_debugIsMemVio(i_io_out_bits_redirect_bits_debugIsMemVio),
    .io_out_bits_predecodeInfo_valid(i_io_out_bits_predecodeInfo_valid),
    .io_out_bits_predecodeInfo_isRVC(i_io_out_bits_predecodeInfo_isRVC),
    .io_out_bits_predecodeInfo_brType(i_io_out_bits_predecodeInfo_brType),
    .io_out_bits_predecodeInfo_isCall(i_io_out_bits_predecodeInfo_isCall),
    .io_out_bits_predecodeInfo_isRet(i_io_out_bits_predecodeInfo_isRet),
    .io_out_bits_debugInfo_eliminatedMove(i_io_out_bits_debugInfo_eliminatedMove),
    .io_out_bits_debugInfo_renameTime(i_io_out_bits_debugInfo_renameTime),
    .io_out_bits_debugInfo_dispatchTime(i_io_out_bits_debugInfo_dispatchTime),
    .io_out_bits_debugInfo_enqRsTime(i_io_out_bits_debugInfo_enqRsTime),
    .io_out_bits_debugInfo_selectTime(i_io_out_bits_debugInfo_selectTime),
    .io_out_bits_debugInfo_issueTime(i_io_out_bits_debugInfo_issueTime),
    .io_out_bits_debugInfo_writebackTime(i_io_out_bits_debugInfo_writebackTime),
    .io_out_bits_debugInfo_runahead_checkpoint_id(i_io_out_bits_debugInfo_runahead_checkpoint_id),
    .io_out_bits_debugInfo_tlbFirstReqTime(i_io_out_bits_debugInfo_tlbFirstReqTime),
    .io_out_bits_debugInfo_tlbRespTime(i_io_out_bits_debugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(i_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(i_io_out_bits_debug_seqNum_uopIdx)
  );

  // 每拍激励：先全随机，再按目标语义覆盖
  task automatic drive();
    io_in_valid = 1'($urandom);
    io_in_bits_fuType = 35'({$urandom(), $urandom()});
    io_in_bits_fuOpType = 9'($urandom);
    io_in_bits_src_0 = 64'({$urandom(), $urandom()});
    io_in_bits_src_1 = 64'({$urandom(), $urandom()});
    io_in_bits_imm = 64'({$urandom(), $urandom()});
    io_in_bits_nextPcOffset = 5'($urandom);
    io_in_bits_robIdx_flag = 1'($urandom);
    io_in_bits_robIdx_value = 8'($urandom);
    io_in_bits_pdest = 8'($urandom);
    io_in_bits_rfWen = 1'($urandom);
    io_in_bits_pc = 50'({$urandom(), $urandom()});
    io_in_bits_preDecode_valid = 1'($urandom);
    io_in_bits_preDecode_isRVC = 1'($urandom);
    io_in_bits_preDecode_brType = 2'($urandom);
    io_in_bits_preDecode_isCall = 1'($urandom);
    io_in_bits_preDecode_isRet = 1'($urandom);
    io_in_bits_ftqIdx_flag = 1'($urandom);
    io_in_bits_ftqIdx_value = 6'($urandom);
    io_in_bits_ftqOffset = 4'($urandom);
    io_in_bits_predictInfo_target = 50'({$urandom(), $urandom()});
    io_in_bits_predictInfo_taken = 1'($urandom);
    io_in_bits_perfDebugInfo_eliminatedMove = 1'($urandom);
    io_in_bits_perfDebugInfo_renameTime = 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_dispatchTime = 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_enqRsTime = 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_selectTime = 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_issueTime = 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_writebackTime = 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_runahead_checkpoint_id = 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_tlbFirstReqTime = 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_tlbRespTime = 64'({$urandom(), $urandom()});
    io_in_bits_debug_seqNum_seqNum = 56'({$urandom(), $urandom()});
    io_in_bits_debug_seqNum_uopIdx = 8'($urandom);
    io_out_ready = 1'($urandom);
    io_instrAddrTransType_bare = 1'($urandom);
    io_instrAddrTransType_sv39 = 1'($urandom);
    io_instrAddrTransType_sv39x4 = 1'($urandom);
    io_instrAddrTransType_sv48 = 1'($urandom);
    io_instrAddrTransType_sv48x4 = 1'($urandom);
    // fuType：85% 取本外壳某个 FU 的编码（与 Dispatcher 的 acceptVec 一致），其余全随机
    //   （多数不命中任何 FU：Dispatcher 不派发，指令被吞 —— 这条路两侧也必须一致）
    if ($urandom_range(0, 99) < 85) io_in_bits_fuType = fu_code[$urandom_range(0, NFU - 1)];
    io_in_valid  = ($urandom_range(0, 9) < 6);
    io_out_ready = ($urandom_range(0, 9) != 0);           // 10% 反压
    io_in_bits_robIdx_value = 8'($urandom_range(0, 15));  // 窄范围：冲刷比较两种结果都常见
    // 暖机：复位撤销后轮流给每个 FU 发有效指令、不反压不冲刷，把各级不复位的寄存器写成确定值
    if (cyc < WARM) begin
      io_in_valid = 1; io_out_ready = 1;
      io_in_bits_fuType = fu_code[cyc % NFU];
    end

  endtask

  task automatic compare();
    checks++; if (g_io_in_ready !== i_io_in_ready) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_in_ready g=%h i=%h", cyc, g_io_in_ready, i_io_in_ready); end
    checks++; if (g_io_out_valid !== i_io_out_valid) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_valid g=%h i=%h", cyc, g_io_out_valid, i_io_out_valid); end
    checks++; if (g_io_out_bits_data_0 !== i_io_out_bits_data_0) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_data_0 g=%h i=%h", cyc, g_io_out_bits_data_0, i_io_out_bits_data_0); end
    checks++; if (g_io_out_bits_data_1 !== i_io_out_bits_data_1) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_data_1 g=%h i=%h", cyc, g_io_out_bits_data_1, i_io_out_bits_data_1); end
    checks++; if (g_io_out_bits_pdest !== i_io_out_bits_pdest) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_pdest g=%h i=%h", cyc, g_io_out_bits_pdest, i_io_out_bits_pdest); end
    checks++; if (g_io_out_bits_robIdx_flag !== i_io_out_bits_robIdx_flag) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_robIdx_flag g=%h i=%h", cyc, g_io_out_bits_robIdx_flag, i_io_out_bits_robIdx_flag); end
    checks++; if (g_io_out_bits_robIdx_value !== i_io_out_bits_robIdx_value) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_robIdx_value g=%h i=%h", cyc, g_io_out_bits_robIdx_value, i_io_out_bits_robIdx_value); end
    checks++; if (g_io_out_bits_intWen !== i_io_out_bits_intWen) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_intWen g=%h i=%h", cyc, g_io_out_bits_intWen, i_io_out_bits_intWen); end
    checks++; if (g_io_out_bits_redirect_valid !== i_io_out_bits_redirect_valid) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_valid g=%h i=%h", cyc, g_io_out_bits_redirect_valid, i_io_out_bits_redirect_valid); end
    checks++; if (g_io_out_bits_redirect_bits_isRVC !== i_io_out_bits_redirect_bits_isRVC) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_isRVC g=%h i=%h", cyc, g_io_out_bits_redirect_bits_isRVC, i_io_out_bits_redirect_bits_isRVC); end
    checks++; if (g_io_out_bits_redirect_bits_robIdx_flag !== i_io_out_bits_redirect_bits_robIdx_flag) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_robIdx_flag g=%h i=%h", cyc, g_io_out_bits_redirect_bits_robIdx_flag, i_io_out_bits_redirect_bits_robIdx_flag); end
    checks++; if (g_io_out_bits_redirect_bits_robIdx_value !== i_io_out_bits_redirect_bits_robIdx_value) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_robIdx_value g=%h i=%h", cyc, g_io_out_bits_redirect_bits_robIdx_value, i_io_out_bits_redirect_bits_robIdx_value); end
    checks++; if (g_io_out_bits_redirect_bits_ftqIdx_flag !== i_io_out_bits_redirect_bits_ftqIdx_flag) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_ftqIdx_flag g=%h i=%h", cyc, g_io_out_bits_redirect_bits_ftqIdx_flag, i_io_out_bits_redirect_bits_ftqIdx_flag); end
    checks++; if (g_io_out_bits_redirect_bits_ftqIdx_value !== i_io_out_bits_redirect_bits_ftqIdx_value) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_ftqIdx_value g=%h i=%h", cyc, g_io_out_bits_redirect_bits_ftqIdx_value, i_io_out_bits_redirect_bits_ftqIdx_value); end
    checks++; if (g_io_out_bits_redirect_bits_ftqOffset !== i_io_out_bits_redirect_bits_ftqOffset) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_ftqOffset g=%h i=%h", cyc, g_io_out_bits_redirect_bits_ftqOffset, i_io_out_bits_redirect_bits_ftqOffset); end
    checks++; if (g_io_out_bits_redirect_bits_level !== i_io_out_bits_redirect_bits_level) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_level g=%h i=%h", cyc, g_io_out_bits_redirect_bits_level, i_io_out_bits_redirect_bits_level); end
    checks++; if (g_io_out_bits_redirect_bits_interrupt !== i_io_out_bits_redirect_bits_interrupt) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_interrupt g=%h i=%h", cyc, g_io_out_bits_redirect_bits_interrupt, i_io_out_bits_redirect_bits_interrupt); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_pc !== i_io_out_bits_redirect_bits_cfiUpdate_pc) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_pc g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_pc, i_io_out_bits_redirect_bits_cfiUpdate_pc); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_pd_valid !== i_io_out_bits_redirect_bits_cfiUpdate_pd_valid) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_pd_valid g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_pd_valid, i_io_out_bits_redirect_bits_cfiUpdate_pd_valid); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_pd_isRVC !== i_io_out_bits_redirect_bits_cfiUpdate_pd_isRVC) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_pd_isRVC g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_pd_isRVC, i_io_out_bits_redirect_bits_cfiUpdate_pd_isRVC); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_pd_brType !== i_io_out_bits_redirect_bits_cfiUpdate_pd_brType) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_pd_brType g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_pd_brType, i_io_out_bits_redirect_bits_cfiUpdate_pd_brType); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_pd_isCall !== i_io_out_bits_redirect_bits_cfiUpdate_pd_isCall) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_pd_isCall g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_pd_isCall, i_io_out_bits_redirect_bits_cfiUpdate_pd_isCall); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_pd_isRet !== i_io_out_bits_redirect_bits_cfiUpdate_pd_isRet) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_pd_isRet g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_pd_isRet, i_io_out_bits_redirect_bits_cfiUpdate_pd_isRet); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_ssp !== i_io_out_bits_redirect_bits_cfiUpdate_ssp) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_ssp g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_ssp, i_io_out_bits_redirect_bits_cfiUpdate_ssp); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_sctr !== i_io_out_bits_redirect_bits_cfiUpdate_sctr) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_sctr g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_sctr, i_io_out_bits_redirect_bits_cfiUpdate_sctr); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_TOSW_flag !== i_io_out_bits_redirect_bits_cfiUpdate_TOSW_flag) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_TOSW_flag g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_TOSW_flag, i_io_out_bits_redirect_bits_cfiUpdate_TOSW_flag); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_TOSW_value !== i_io_out_bits_redirect_bits_cfiUpdate_TOSW_value) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_TOSW_value g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_TOSW_value, i_io_out_bits_redirect_bits_cfiUpdate_TOSW_value); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_TOSR_flag !== i_io_out_bits_redirect_bits_cfiUpdate_TOSR_flag) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_TOSR_flag g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_TOSR_flag, i_io_out_bits_redirect_bits_cfiUpdate_TOSR_flag); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_TOSR_value !== i_io_out_bits_redirect_bits_cfiUpdate_TOSR_value) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_TOSR_value g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_TOSR_value, i_io_out_bits_redirect_bits_cfiUpdate_TOSR_value); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_NOS_flag !== i_io_out_bits_redirect_bits_cfiUpdate_NOS_flag) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_NOS_flag g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_NOS_flag, i_io_out_bits_redirect_bits_cfiUpdate_NOS_flag); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_NOS_value !== i_io_out_bits_redirect_bits_cfiUpdate_NOS_value) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_NOS_value g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_NOS_value, i_io_out_bits_redirect_bits_cfiUpdate_NOS_value); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_topAddr !== i_io_out_bits_redirect_bits_cfiUpdate_topAddr) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_topAddr g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_topAddr, i_io_out_bits_redirect_bits_cfiUpdate_topAddr); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist !== i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist !== i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist !== i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist !== i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist !== i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist !== i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist !== i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist !== i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist !== i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist !== i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist !== i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist !== i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist !== i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist !== i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist !== i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist !== i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist !== i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist !== i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist, i_io_out_bits_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0 !== i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0 g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1 !== i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1 g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2 !== i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2 g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3 !== i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3 g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0 !== i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0 g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1 !== i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1 g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2 !== i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2 g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3 !== i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3 g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0 !== i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0 g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1 !== i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1 g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2 !== i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2 g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3 !== i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3 g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0 !== i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0 g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1 !== i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1 g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2 !== i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2 g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3 !== i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3 g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0 !== i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0 g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1 !== i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1 g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2 !== i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2 g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3 !== i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3 g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0 !== i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0 g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1 !== i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1 g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2 !== i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2 g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3 !== i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3 g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3, i_io_out_bits_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_lastBrNumOH !== i_io_out_bits_redirect_bits_cfiUpdate_lastBrNumOH) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_lastBrNumOH g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_lastBrNumOH, i_io_out_bits_redirect_bits_cfiUpdate_lastBrNumOH); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_ghr !== i_io_out_bits_redirect_bits_cfiUpdate_ghr) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_ghr g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_ghr, i_io_out_bits_redirect_bits_cfiUpdate_ghr); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_histPtr_flag !== i_io_out_bits_redirect_bits_cfiUpdate_histPtr_flag) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_histPtr_flag g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_histPtr_flag, i_io_out_bits_redirect_bits_cfiUpdate_histPtr_flag); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_histPtr_value !== i_io_out_bits_redirect_bits_cfiUpdate_histPtr_value) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_histPtr_value g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_histPtr_value, i_io_out_bits_redirect_bits_cfiUpdate_histPtr_value); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_specCnt_0 !== i_io_out_bits_redirect_bits_cfiUpdate_specCnt_0) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_specCnt_0 g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_specCnt_0, i_io_out_bits_redirect_bits_cfiUpdate_specCnt_0); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_specCnt_1 !== i_io_out_bits_redirect_bits_cfiUpdate_specCnt_1) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_specCnt_1 g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_specCnt_1, i_io_out_bits_redirect_bits_cfiUpdate_specCnt_1); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_br_hit !== i_io_out_bits_redirect_bits_cfiUpdate_br_hit) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_br_hit g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_br_hit, i_io_out_bits_redirect_bits_cfiUpdate_br_hit); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_jr_hit !== i_io_out_bits_redirect_bits_cfiUpdate_jr_hit) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_jr_hit g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_jr_hit, i_io_out_bits_redirect_bits_cfiUpdate_jr_hit); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_sc_hit !== i_io_out_bits_redirect_bits_cfiUpdate_sc_hit) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_sc_hit g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_sc_hit, i_io_out_bits_redirect_bits_cfiUpdate_sc_hit); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_predTaken !== i_io_out_bits_redirect_bits_cfiUpdate_predTaken) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_predTaken g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_predTaken, i_io_out_bits_redirect_bits_cfiUpdate_predTaken); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_target !== i_io_out_bits_redirect_bits_cfiUpdate_target) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_target g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_target, i_io_out_bits_redirect_bits_cfiUpdate_target); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_taken !== i_io_out_bits_redirect_bits_cfiUpdate_taken) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_taken g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_taken, i_io_out_bits_redirect_bits_cfiUpdate_taken); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_isMisPred !== i_io_out_bits_redirect_bits_cfiUpdate_isMisPred) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_isMisPred g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_isMisPred, i_io_out_bits_redirect_bits_cfiUpdate_isMisPred); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_shift !== i_io_out_bits_redirect_bits_cfiUpdate_shift) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_shift g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_shift, i_io_out_bits_redirect_bits_cfiUpdate_shift); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_addIntoHist !== i_io_out_bits_redirect_bits_cfiUpdate_addIntoHist) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_addIntoHist g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_addIntoHist, i_io_out_bits_redirect_bits_cfiUpdate_addIntoHist); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_backendIGPF !== i_io_out_bits_redirect_bits_cfiUpdate_backendIGPF) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_backendIGPF g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_backendIGPF, i_io_out_bits_redirect_bits_cfiUpdate_backendIGPF); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_backendIPF !== i_io_out_bits_redirect_bits_cfiUpdate_backendIPF) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_backendIPF g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_backendIPF, i_io_out_bits_redirect_bits_cfiUpdate_backendIPF); end
    checks++; if (g_io_out_bits_redirect_bits_cfiUpdate_backendIAF !== i_io_out_bits_redirect_bits_cfiUpdate_backendIAF) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_cfiUpdate_backendIAF g=%h i=%h", cyc, g_io_out_bits_redirect_bits_cfiUpdate_backendIAF, i_io_out_bits_redirect_bits_cfiUpdate_backendIAF); end
    checks++; if (g_io_out_bits_redirect_bits_fullTarget !== i_io_out_bits_redirect_bits_fullTarget) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_fullTarget g=%h i=%h", cyc, g_io_out_bits_redirect_bits_fullTarget, i_io_out_bits_redirect_bits_fullTarget); end
    checks++; if (g_io_out_bits_redirect_bits_satpFlush !== i_io_out_bits_redirect_bits_satpFlush) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_satpFlush g=%h i=%h", cyc, g_io_out_bits_redirect_bits_satpFlush, i_io_out_bits_redirect_bits_satpFlush); end
    checks++; if (g_io_out_bits_redirect_bits_isVlsException !== i_io_out_bits_redirect_bits_isVlsException) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_isVlsException g=%h i=%h", cyc, g_io_out_bits_redirect_bits_isVlsException, i_io_out_bits_redirect_bits_isVlsException); end
    checks++; if (g_io_out_bits_redirect_bits_stFtqIdx_flag !== i_io_out_bits_redirect_bits_stFtqIdx_flag) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_stFtqIdx_flag g=%h i=%h", cyc, g_io_out_bits_redirect_bits_stFtqIdx_flag, i_io_out_bits_redirect_bits_stFtqIdx_flag); end
    checks++; if (g_io_out_bits_redirect_bits_stFtqIdx_value !== i_io_out_bits_redirect_bits_stFtqIdx_value) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_stFtqIdx_value g=%h i=%h", cyc, g_io_out_bits_redirect_bits_stFtqIdx_value, i_io_out_bits_redirect_bits_stFtqIdx_value); end
    checks++; if (g_io_out_bits_redirect_bits_stFtqOffset !== i_io_out_bits_redirect_bits_stFtqOffset) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_stFtqOffset g=%h i=%h", cyc, g_io_out_bits_redirect_bits_stFtqOffset, i_io_out_bits_redirect_bits_stFtqOffset); end
    checks++; if (g_io_out_bits_redirect_bits_debug_runahead_checkpoint_id !== i_io_out_bits_redirect_bits_debug_runahead_checkpoint_id) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_debug_runahead_checkpoint_id g=%h i=%h", cyc, g_io_out_bits_redirect_bits_debug_runahead_checkpoint_id, i_io_out_bits_redirect_bits_debug_runahead_checkpoint_id); end
    checks++; if (g_io_out_bits_redirect_bits_debugIsCtrl !== i_io_out_bits_redirect_bits_debugIsCtrl) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_debugIsCtrl g=%h i=%h", cyc, g_io_out_bits_redirect_bits_debugIsCtrl, i_io_out_bits_redirect_bits_debugIsCtrl); end
    checks++; if (g_io_out_bits_redirect_bits_debugIsMemVio !== i_io_out_bits_redirect_bits_debugIsMemVio) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_redirect_bits_debugIsMemVio g=%h i=%h", cyc, g_io_out_bits_redirect_bits_debugIsMemVio, i_io_out_bits_redirect_bits_debugIsMemVio); end
    checks++; if (g_io_out_bits_predecodeInfo_valid !== i_io_out_bits_predecodeInfo_valid) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_predecodeInfo_valid g=%h i=%h", cyc, g_io_out_bits_predecodeInfo_valid, i_io_out_bits_predecodeInfo_valid); end
    checks++; if (g_io_out_bits_predecodeInfo_isRVC !== i_io_out_bits_predecodeInfo_isRVC) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_predecodeInfo_isRVC g=%h i=%h", cyc, g_io_out_bits_predecodeInfo_isRVC, i_io_out_bits_predecodeInfo_isRVC); end
    checks++; if (g_io_out_bits_predecodeInfo_brType !== i_io_out_bits_predecodeInfo_brType) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_predecodeInfo_brType g=%h i=%h", cyc, g_io_out_bits_predecodeInfo_brType, i_io_out_bits_predecodeInfo_brType); end
    checks++; if (g_io_out_bits_predecodeInfo_isCall !== i_io_out_bits_predecodeInfo_isCall) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_predecodeInfo_isCall g=%h i=%h", cyc, g_io_out_bits_predecodeInfo_isCall, i_io_out_bits_predecodeInfo_isCall); end
    checks++; if (g_io_out_bits_predecodeInfo_isRet !== i_io_out_bits_predecodeInfo_isRet) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_predecodeInfo_isRet g=%h i=%h", cyc, g_io_out_bits_predecodeInfo_isRet, i_io_out_bits_predecodeInfo_isRet); end
    checks++; if (g_io_out_bits_debugInfo_eliminatedMove !== i_io_out_bits_debugInfo_eliminatedMove) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debugInfo_eliminatedMove g=%h i=%h", cyc, g_io_out_bits_debugInfo_eliminatedMove, i_io_out_bits_debugInfo_eliminatedMove); end
    checks++; if (g_io_out_bits_debugInfo_renameTime !== i_io_out_bits_debugInfo_renameTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debugInfo_renameTime g=%h i=%h", cyc, g_io_out_bits_debugInfo_renameTime, i_io_out_bits_debugInfo_renameTime); end
    checks++; if (g_io_out_bits_debugInfo_dispatchTime !== i_io_out_bits_debugInfo_dispatchTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debugInfo_dispatchTime g=%h i=%h", cyc, g_io_out_bits_debugInfo_dispatchTime, i_io_out_bits_debugInfo_dispatchTime); end
    checks++; if (g_io_out_bits_debugInfo_enqRsTime !== i_io_out_bits_debugInfo_enqRsTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debugInfo_enqRsTime g=%h i=%h", cyc, g_io_out_bits_debugInfo_enqRsTime, i_io_out_bits_debugInfo_enqRsTime); end
    checks++; if (g_io_out_bits_debugInfo_selectTime !== i_io_out_bits_debugInfo_selectTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debugInfo_selectTime g=%h i=%h", cyc, g_io_out_bits_debugInfo_selectTime, i_io_out_bits_debugInfo_selectTime); end
    checks++; if (g_io_out_bits_debugInfo_issueTime !== i_io_out_bits_debugInfo_issueTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debugInfo_issueTime g=%h i=%h", cyc, g_io_out_bits_debugInfo_issueTime, i_io_out_bits_debugInfo_issueTime); end
    checks++; if (g_io_out_bits_debugInfo_writebackTime !== i_io_out_bits_debugInfo_writebackTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debugInfo_writebackTime g=%h i=%h", cyc, g_io_out_bits_debugInfo_writebackTime, i_io_out_bits_debugInfo_writebackTime); end
    checks++; if (g_io_out_bits_debugInfo_runahead_checkpoint_id !== i_io_out_bits_debugInfo_runahead_checkpoint_id) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debugInfo_runahead_checkpoint_id g=%h i=%h", cyc, g_io_out_bits_debugInfo_runahead_checkpoint_id, i_io_out_bits_debugInfo_runahead_checkpoint_id); end
    checks++; if (g_io_out_bits_debugInfo_tlbFirstReqTime !== i_io_out_bits_debugInfo_tlbFirstReqTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debugInfo_tlbFirstReqTime g=%h i=%h", cyc, g_io_out_bits_debugInfo_tlbFirstReqTime, i_io_out_bits_debugInfo_tlbFirstReqTime); end
    checks++; if (g_io_out_bits_debugInfo_tlbRespTime !== i_io_out_bits_debugInfo_tlbRespTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debugInfo_tlbRespTime g=%h i=%h", cyc, g_io_out_bits_debugInfo_tlbRespTime, i_io_out_bits_debugInfo_tlbRespTime); end
    checks++; if (g_io_out_bits_debug_seqNum_seqNum !== i_io_out_bits_debug_seqNum_seqNum) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debug_seqNum_seqNum g=%h i=%h", cyc, g_io_out_bits_debug_seqNum_seqNum, i_io_out_bits_debug_seqNum_seqNum); end
    checks++; if (g_io_out_bits_debug_seqNum_uopIdx !== i_io_out_bits_debug_seqNum_uopIdx) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debug_seqNum_uopIdx g=%h i=%h", cyc, g_io_out_bits_debug_seqNum_uopIdx, i_io_out_bits_debug_seqNum_uopIdx); end
  endtask

  task automatic sample_cov();
    if (u_g._in1ToN_io_out_0_valid && u_g._brh_io_in_ready) c_in[0]++;
    if (u_g._brh_io_out_valid) c_out[0]++;
    if (u_g._in1ToN_io_out_1_valid && u_g._jmp_io_in_ready) c_in[1]++;
    if (u_g._jmp_io_out_valid) c_out[1]++;
    if (io_in_valid && !(io_in_bits_fuType inside {35'h2, 35'h1})) c_nofu++;
    if (g_io_out_valid && !io_out_ready) c_stall++;

  endtask

  initial begin
    bit ok;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    foreach (c_in[k]) begin c_in[k] = 0; c_out[k] = 0; end
    reset = 1;
    drive();
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      reset = (cyc < 5) || ($urandom_range(0, RESET_ODDS - 1) == 0);
      drive();
      #4;
      if (cyc >= WARM) compare();
      if (!reset) sample_cov();
    end
    $display("cov in=%p out=%p stall=%0d flush=%0d nofu=%0d cg_on=%0d cg_off=%0d busy=%0d", c_in, c_out, c_stall, c_flush, c_nofu, c_cg_on, c_cg_off, c_busy);
    ok = (errors == 0) && (checks > 1000);
    if (!(c_in[0] > 1000)) begin ok = 0; $display("cov LOW: c_in[0] > 1000"); end
    if (!(c_out[0] > 1000)) begin ok = 0; $display("cov LOW: c_out[0] > 1000"); end
    if (!(c_in[1] > 1000)) begin ok = 0; $display("cov LOW: c_in[1] > 1000"); end
    if (!(c_out[1] > 1000)) begin ok = 0; $display("cov LOW: c_out[1] > 1000"); end
    if (!(c_stall > 1000)) begin ok = 0; $display("cov LOW: c_stall > 1000"); end
    if (!(c_nofu > 1000)) begin ok = 0; $display("cov LOW: c_nofu > 1000"); end
    $display("checks=%0d errors=%0d", checks, errors);
    if (ok) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
