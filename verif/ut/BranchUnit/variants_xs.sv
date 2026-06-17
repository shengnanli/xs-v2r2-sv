// 自动生成：scripts/gen_ctrlflow_fu.py —— 勿手改
module BranchUnit_xs(
  input  io_in_valid,
  input  [8:0] io_in_bits_ctrl_fuOpType,
  input  io_in_bits_ctrl_robIdx_flag,
  input  [7:0] io_in_bits_ctrl_robIdx_value,
  input  [7:0] io_in_bits_ctrl_pdest,
  input  io_in_bits_ctrl_ftqIdx_flag,
  input  [5:0] io_in_bits_ctrl_ftqIdx_value,
  input  [3:0] io_in_bits_ctrl_ftqOffset,
  input  io_in_bits_ctrl_predictInfo_taken,
  input  [63:0] io_in_bits_data_src_1,
  input  [63:0] io_in_bits_data_src_0,
  input  [63:0] io_in_bits_data_imm,
  input  [49:0] io_in_bits_data_pc,
  input  [4:0] io_in_bits_data_nextPcOffset,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  output io_out_valid,
  output io_out_bits_ctrl_robIdx_flag,
  output [7:0] io_out_bits_ctrl_robIdx_value,
  output [7:0] io_out_bits_ctrl_pdest,
  output [63:0] io_out_bits_res_data,
  output io_out_bits_res_redirect_valid,
  output io_out_bits_res_redirect_bits_isRVC,
  output io_out_bits_res_redirect_bits_robIdx_flag,
  output [7:0] io_out_bits_res_redirect_bits_robIdx_value,
  output io_out_bits_res_redirect_bits_ftqIdx_flag,
  output [5:0] io_out_bits_res_redirect_bits_ftqIdx_value,
  output [3:0] io_out_bits_res_redirect_bits_ftqOffset,
  output io_out_bits_res_redirect_bits_level,
  output io_out_bits_res_redirect_bits_interrupt,
  output [49:0] io_out_bits_res_redirect_bits_cfiUpdate_pc,
  output io_out_bits_res_redirect_bits_cfiUpdate_pd_valid,
  output io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC,
  output [1:0] io_out_bits_res_redirect_bits_cfiUpdate_pd_brType,
  output io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall,
  output io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet,
  output [3:0] io_out_bits_res_redirect_bits_cfiUpdate_ssp,
  output [2:0] io_out_bits_res_redirect_bits_cfiUpdate_sctr,
  output io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag,
  output [4:0] io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value,
  output io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag,
  output [4:0] io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value,
  output io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag,
  output [4:0] io_out_bits_res_redirect_bits_cfiUpdate_NOS_value,
  output [49:0] io_out_bits_res_redirect_bits_cfiUpdate_topAddr,
  output [10:0] io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist,
  output [10:0] io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist,
  output [6:0] io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist,
  output [7:0] io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist,
  output [8:0] io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist,
  output [3:0] io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist,
  output [7:0] io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist,
  output [8:0] io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist,
  output [6:0] io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist,
  output [7:0] io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist,
  output [6:0] io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist,
  output [8:0] io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist,
  output [6:0] io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist,
  output [7:0] io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist,
  output [7:0] io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist,
  output [7:0] io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist,
  output [10:0] io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist,
  output [7:0] io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist,
  output io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0,
  output io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1,
  output io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2,
  output io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3,
  output io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0,
  output io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1,
  output io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2,
  output io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3,
  output io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0,
  output io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1,
  output io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2,
  output io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3,
  output io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0,
  output io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1,
  output io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2,
  output io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3,
  output io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0,
  output io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1,
  output io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2,
  output io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3,
  output io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0,
  output io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1,
  output io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2,
  output io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3,
  output [2:0] io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH,
  output [3:0] io_out_bits_res_redirect_bits_cfiUpdate_ghr,
  output io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag,
  output [7:0] io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value,
  output [9:0] io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0,
  output [9:0] io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1,
  output io_out_bits_res_redirect_bits_cfiUpdate_br_hit,
  output io_out_bits_res_redirect_bits_cfiUpdate_jr_hit,
  output io_out_bits_res_redirect_bits_cfiUpdate_sc_hit,
  output io_out_bits_res_redirect_bits_cfiUpdate_predTaken,
  output [49:0] io_out_bits_res_redirect_bits_cfiUpdate_target,
  output io_out_bits_res_redirect_bits_cfiUpdate_taken,
  output io_out_bits_res_redirect_bits_cfiUpdate_isMisPred,
  output [1:0] io_out_bits_res_redirect_bits_cfiUpdate_shift,
  output io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist,
  output io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF,
  output io_out_bits_res_redirect_bits_cfiUpdate_backendIPF,
  output io_out_bits_res_redirect_bits_cfiUpdate_backendIAF,
  output [63:0] io_out_bits_res_redirect_bits_fullTarget,
  output io_out_bits_res_redirect_bits_stFtqIdx_flag,
  output [5:0] io_out_bits_res_redirect_bits_stFtqIdx_value,
  output [3:0] io_out_bits_res_redirect_bits_stFtqOffset,
  output [63:0] io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id,
  output io_out_bits_res_redirect_bits_debugIsCtrl,
  output io_out_bits_res_redirect_bits_debugIsMemVio,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime,
  input  io_instrAddrTransType_bare,
  input  io_instrAddrTransType_sv39,
  input  io_instrAddrTransType_sv39x4,
  input  io_instrAddrTransType_sv48,
  input  io_instrAddrTransType_sv48x4
);

  xs_BranchUnit_core u_core (
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_robIdx_flag(io_in_bits_ctrl_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value(io_in_bits_ctrl_robIdx_value),
    .io_in_bits_ctrl_pdest(io_in_bits_ctrl_pdest),
    .io_in_bits_ctrl_ftqIdx_flag(io_in_bits_ctrl_ftqIdx_flag),
    .io_in_bits_ctrl_ftqIdx_value(io_in_bits_ctrl_ftqIdx_value),
    .io_in_bits_ctrl_ftqOffset(io_in_bits_ctrl_ftqOffset),
    .io_in_bits_ctrl_predictInfo_taken(io_in_bits_ctrl_predictInfo_taken),
    .io_in_bits_data_src_1(io_in_bits_data_src_1),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_data_imm(io_in_bits_data_imm),
    .io_in_bits_data_pc(io_in_bits_data_pc),
    .io_in_bits_data_nextPcOffset(io_in_bits_data_nextPcOffset),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_instrAddrTransType_bare(io_instrAddrTransType_bare),
    .io_instrAddrTransType_sv39(io_instrAddrTransType_sv39),
    .io_instrAddrTransType_sv39x4(io_instrAddrTransType_sv39x4),
    .io_instrAddrTransType_sv48(io_instrAddrTransType_sv48),
    .io_instrAddrTransType_sv48x4(io_instrAddrTransType_sv48x4),
    .io_out_valid(io_out_valid),
    .io_out_bits_ctrl_robIdx_flag(io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value(io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest(io_out_bits_ctrl_pdest),
    .io_out_bits_res_data(io_out_bits_res_data),
    .io_out_bits_res_redirect_valid(io_out_bits_res_redirect_valid),
    .io_out_bits_res_redirect_bits_robIdx_flag(io_out_bits_res_redirect_bits_robIdx_flag),
    .io_out_bits_res_redirect_bits_robIdx_value(io_out_bits_res_redirect_bits_robIdx_value),
    .io_out_bits_res_redirect_bits_ftqIdx_flag(io_out_bits_res_redirect_bits_ftqIdx_flag),
    .io_out_bits_res_redirect_bits_ftqIdx_value(io_out_bits_res_redirect_bits_ftqIdx_value),
    .io_out_bits_res_redirect_bits_ftqOffset(io_out_bits_res_redirect_bits_ftqOffset),
    .io_out_bits_res_redirect_bits_cfiUpdate_pc(io_out_bits_res_redirect_bits_cfiUpdate_pc),
    .io_out_bits_res_redirect_bits_cfiUpdate_predTaken(io_out_bits_res_redirect_bits_cfiUpdate_predTaken),
    .io_out_bits_res_redirect_bits_cfiUpdate_target(io_out_bits_res_redirect_bits_cfiUpdate_target),
    .io_out_bits_res_redirect_bits_cfiUpdate_taken(io_out_bits_res_redirect_bits_cfiUpdate_taken),
    .io_out_bits_res_redirect_bits_cfiUpdate_isMisPred(io_out_bits_res_redirect_bits_cfiUpdate_isMisPred),
    .io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF(io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF),
    .io_out_bits_res_redirect_bits_cfiUpdate_backendIPF(io_out_bits_res_redirect_bits_cfiUpdate_backendIPF),
    .io_out_bits_res_redirect_bits_cfiUpdate_backendIAF(io_out_bits_res_redirect_bits_cfiUpdate_backendIAF),
    .io_out_bits_res_redirect_bits_fullTarget(io_out_bits_res_redirect_bits_fullTarget),
    .io_out_bits_perfDebugInfo_enqRsTime(io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(io_out_bits_perfDebugInfo_issueTime)
  );

  // —— 本单元不产生的 cfiUpdate/历史/afhob 等字段, 置 golden 常量 ——
  assign io_out_bits_res_redirect_bits_isRVC = 1'h0;
  assign io_out_bits_res_redirect_bits_level = 1'h0;
  assign io_out_bits_res_redirect_bits_interrupt = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_pd_valid = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_pd_brType = 2'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_ssp = 4'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_sctr = 3'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value = 5'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value = 5'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_NOS_value = 5'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_topAddr = 50'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist = 11'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist = 11'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist = 7'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist = 8'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist = 9'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist = 4'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist = 8'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist = 9'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist = 7'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist = 8'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist = 7'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist = 9'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist = 7'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist = 8'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist = 8'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist = 8'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist = 11'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist = 8'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3 = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH = 3'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_ghr = 4'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value = 8'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0 = 10'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1 = 10'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_br_hit = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_jr_hit = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_sc_hit = 1'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_shift = 2'h0;
  assign io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist = 1'h0;
  assign io_out_bits_res_redirect_bits_stFtqIdx_flag = 1'h0;
  assign io_out_bits_res_redirect_bits_stFtqIdx_value = 6'h0;
  assign io_out_bits_res_redirect_bits_stFtqOffset = 4'h0;
  assign io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id = 64'h0;
  assign io_out_bits_res_redirect_bits_debugIsCtrl = 1'h0;
  assign io_out_bits_res_redirect_bits_debugIsMemVio = 1'h0;
endmodule
