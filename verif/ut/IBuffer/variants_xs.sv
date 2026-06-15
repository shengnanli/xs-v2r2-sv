// 自动适配层（手写）：golden 同名扁平端口 ↔ 可读核 xs_IBuffer_core 的 struct/数组端口
// 仅做机械的位打包/拆包，允许平铺。供 Formality 等价比对与系统替换。
module IBuffer_xs(
  input clock,
  input reset,
  input io_flush,
  input io_ControlRedirect,
  input io_ControlBTBMissBubble,
  input io_TAGEMissBubble,
  input io_SCMissBubble,
  input io_ITTAGEMissBubble,
  input io_RASMissBubble,
  input io_MemVioRedirect,
  output io_in_ready,
  input io_in_valid,
  input [31:0] io_in_bits_instrs_0,
  input [31:0] io_in_bits_instrs_1,
  input [31:0] io_in_bits_instrs_2,
  input [31:0] io_in_bits_instrs_3,
  input [31:0] io_in_bits_instrs_4,
  input [31:0] io_in_bits_instrs_5,
  input [31:0] io_in_bits_instrs_6,
  input [31:0] io_in_bits_instrs_7,
  input [31:0] io_in_bits_instrs_8,
  input [31:0] io_in_bits_instrs_9,
  input [31:0] io_in_bits_instrs_10,
  input [31:0] io_in_bits_instrs_11,
  input [31:0] io_in_bits_instrs_12,
  input [31:0] io_in_bits_instrs_13,
  input [31:0] io_in_bits_instrs_14,
  input [31:0] io_in_bits_instrs_15,
  input [15:0] io_in_bits_valid,
  input [15:0] io_in_bits_enqEnable,
  input io_in_bits_pd_0_isRVC,
  input [1:0] io_in_bits_pd_0_brType,
  input io_in_bits_pd_1_isRVC,
  input [1:0] io_in_bits_pd_1_brType,
  input io_in_bits_pd_2_isRVC,
  input [1:0] io_in_bits_pd_2_brType,
  input io_in_bits_pd_3_isRVC,
  input [1:0] io_in_bits_pd_3_brType,
  input io_in_bits_pd_4_isRVC,
  input [1:0] io_in_bits_pd_4_brType,
  input io_in_bits_pd_5_isRVC,
  input [1:0] io_in_bits_pd_5_brType,
  input io_in_bits_pd_6_isRVC,
  input [1:0] io_in_bits_pd_6_brType,
  input io_in_bits_pd_7_isRVC,
  input [1:0] io_in_bits_pd_7_brType,
  input io_in_bits_pd_8_isRVC,
  input [1:0] io_in_bits_pd_8_brType,
  input io_in_bits_pd_9_isRVC,
  input [1:0] io_in_bits_pd_9_brType,
  input io_in_bits_pd_10_isRVC,
  input [1:0] io_in_bits_pd_10_brType,
  input io_in_bits_pd_11_isRVC,
  input [1:0] io_in_bits_pd_11_brType,
  input io_in_bits_pd_12_isRVC,
  input [1:0] io_in_bits_pd_12_brType,
  input io_in_bits_pd_13_isRVC,
  input [1:0] io_in_bits_pd_13_brType,
  input io_in_bits_pd_14_isRVC,
  input [1:0] io_in_bits_pd_14_brType,
  input io_in_bits_pd_15_isRVC,
  input [1:0] io_in_bits_pd_15_brType,
  input [9:0] io_in_bits_foldpc_0,
  input [9:0] io_in_bits_foldpc_1,
  input [9:0] io_in_bits_foldpc_2,
  input [9:0] io_in_bits_foldpc_3,
  input [9:0] io_in_bits_foldpc_4,
  input [9:0] io_in_bits_foldpc_5,
  input [9:0] io_in_bits_foldpc_6,
  input [9:0] io_in_bits_foldpc_7,
  input [9:0] io_in_bits_foldpc_8,
  input [9:0] io_in_bits_foldpc_9,
  input [9:0] io_in_bits_foldpc_10,
  input [9:0] io_in_bits_foldpc_11,
  input [9:0] io_in_bits_foldpc_12,
  input [9:0] io_in_bits_foldpc_13,
  input [9:0] io_in_bits_foldpc_14,
  input [9:0] io_in_bits_foldpc_15,
  input io_in_bits_ftqOffset_0_valid,
  input io_in_bits_ftqOffset_1_valid,
  input io_in_bits_ftqOffset_2_valid,
  input io_in_bits_ftqOffset_3_valid,
  input io_in_bits_ftqOffset_4_valid,
  input io_in_bits_ftqOffset_5_valid,
  input io_in_bits_ftqOffset_6_valid,
  input io_in_bits_ftqOffset_7_valid,
  input io_in_bits_ftqOffset_8_valid,
  input io_in_bits_ftqOffset_9_valid,
  input io_in_bits_ftqOffset_10_valid,
  input io_in_bits_ftqOffset_11_valid,
  input io_in_bits_ftqOffset_12_valid,
  input io_in_bits_ftqOffset_13_valid,
  input io_in_bits_ftqOffset_14_valid,
  input io_in_bits_ftqOffset_15_valid,
  input io_in_bits_backendException_0,
  input [1:0] io_in_bits_exceptionType_0,
  input [1:0] io_in_bits_exceptionType_1,
  input [1:0] io_in_bits_exceptionType_2,
  input [1:0] io_in_bits_exceptionType_3,
  input [1:0] io_in_bits_exceptionType_4,
  input [1:0] io_in_bits_exceptionType_5,
  input [1:0] io_in_bits_exceptionType_6,
  input [1:0] io_in_bits_exceptionType_7,
  input [1:0] io_in_bits_exceptionType_8,
  input [1:0] io_in_bits_exceptionType_9,
  input [1:0] io_in_bits_exceptionType_10,
  input [1:0] io_in_bits_exceptionType_11,
  input [1:0] io_in_bits_exceptionType_12,
  input [1:0] io_in_bits_exceptionType_13,
  input [1:0] io_in_bits_exceptionType_14,
  input [1:0] io_in_bits_exceptionType_15,
  input io_in_bits_crossPageIPFFix_0,
  input io_in_bits_crossPageIPFFix_1,
  input io_in_bits_crossPageIPFFix_2,
  input io_in_bits_crossPageIPFFix_3,
  input io_in_bits_crossPageIPFFix_4,
  input io_in_bits_crossPageIPFFix_5,
  input io_in_bits_crossPageIPFFix_6,
  input io_in_bits_crossPageIPFFix_7,
  input io_in_bits_crossPageIPFFix_8,
  input io_in_bits_crossPageIPFFix_9,
  input io_in_bits_crossPageIPFFix_10,
  input io_in_bits_crossPageIPFFix_11,
  input io_in_bits_crossPageIPFFix_12,
  input io_in_bits_crossPageIPFFix_13,
  input io_in_bits_crossPageIPFFix_14,
  input io_in_bits_crossPageIPFFix_15,
  input io_in_bits_illegalInstr_0,
  input io_in_bits_illegalInstr_1,
  input io_in_bits_illegalInstr_2,
  input io_in_bits_illegalInstr_3,
  input io_in_bits_illegalInstr_4,
  input io_in_bits_illegalInstr_5,
  input io_in_bits_illegalInstr_6,
  input io_in_bits_illegalInstr_7,
  input io_in_bits_illegalInstr_8,
  input io_in_bits_illegalInstr_9,
  input io_in_bits_illegalInstr_10,
  input io_in_bits_illegalInstr_11,
  input io_in_bits_illegalInstr_12,
  input io_in_bits_illegalInstr_13,
  input io_in_bits_illegalInstr_14,
  input io_in_bits_illegalInstr_15,
  input [3:0] io_in_bits_triggered_0,
  input [3:0] io_in_bits_triggered_1,
  input [3:0] io_in_bits_triggered_2,
  input [3:0] io_in_bits_triggered_3,
  input [3:0] io_in_bits_triggered_4,
  input [3:0] io_in_bits_triggered_5,
  input [3:0] io_in_bits_triggered_6,
  input [3:0] io_in_bits_triggered_7,
  input [3:0] io_in_bits_triggered_8,
  input [3:0] io_in_bits_triggered_9,
  input [3:0] io_in_bits_triggered_10,
  input [3:0] io_in_bits_triggered_11,
  input [3:0] io_in_bits_triggered_12,
  input [3:0] io_in_bits_triggered_13,
  input [3:0] io_in_bits_triggered_14,
  input [3:0] io_in_bits_triggered_15,
  input io_in_bits_isLastInFtqEntry_0,
  input io_in_bits_isLastInFtqEntry_1,
  input io_in_bits_isLastInFtqEntry_2,
  input io_in_bits_isLastInFtqEntry_3,
  input io_in_bits_isLastInFtqEntry_4,
  input io_in_bits_isLastInFtqEntry_5,
  input io_in_bits_isLastInFtqEntry_6,
  input io_in_bits_isLastInFtqEntry_7,
  input io_in_bits_isLastInFtqEntry_8,
  input io_in_bits_isLastInFtqEntry_9,
  input io_in_bits_isLastInFtqEntry_10,
  input io_in_bits_isLastInFtqEntry_11,
  input io_in_bits_isLastInFtqEntry_12,
  input io_in_bits_isLastInFtqEntry_13,
  input io_in_bits_isLastInFtqEntry_14,
  input io_in_bits_isLastInFtqEntry_15,
  input [49:0] io_in_bits_pc_0,
  input [49:0] io_in_bits_pc_1,
  input [49:0] io_in_bits_pc_2,
  input [49:0] io_in_bits_pc_3,
  input [49:0] io_in_bits_pc_4,
  input [49:0] io_in_bits_pc_5,
  input [49:0] io_in_bits_pc_6,
  input [49:0] io_in_bits_pc_7,
  input [49:0] io_in_bits_pc_8,
  input [49:0] io_in_bits_pc_9,
  input [49:0] io_in_bits_pc_10,
  input [49:0] io_in_bits_pc_11,
  input [49:0] io_in_bits_pc_12,
  input [49:0] io_in_bits_pc_13,
  input [49:0] io_in_bits_pc_14,
  input [49:0] io_in_bits_pc_15,
  input io_in_bits_ftqPtr_flag,
  input [5:0] io_in_bits_ftqPtr_value,
  input io_in_bits_topdown_info_reasons_0,
  input io_in_bits_topdown_info_reasons_1,
  input io_in_bits_topdown_info_reasons_2,
  input io_in_bits_topdown_info_reasons_3,
  input io_in_bits_topdown_info_reasons_4,
  input io_in_bits_topdown_info_reasons_5,
  input io_in_bits_topdown_info_reasons_6,
  input io_in_bits_topdown_info_reasons_7,
  input io_in_bits_topdown_info_reasons_8,
  input io_in_bits_topdown_info_reasons_9,
  input io_in_bits_topdown_info_reasons_10,
  input io_in_bits_topdown_info_reasons_11,
  input io_in_bits_topdown_info_reasons_12,
  input io_in_bits_topdown_info_reasons_13,
  input io_in_bits_topdown_info_reasons_14,
  input io_in_bits_topdown_info_reasons_15,
  input io_in_bits_topdown_info_reasons_16,
  input io_in_bits_topdown_info_reasons_17,
  input io_in_bits_topdown_info_reasons_18,
  input io_in_bits_topdown_info_reasons_19,
  input io_in_bits_topdown_info_reasons_20,
  input io_in_bits_topdown_info_reasons_21,
  input io_in_bits_topdown_info_reasons_22,
  input io_in_bits_topdown_info_reasons_23,
  input io_in_bits_topdown_info_reasons_24,
  input io_in_bits_topdown_info_reasons_25,
  input io_in_bits_topdown_info_reasons_26,
  input io_in_bits_topdown_info_reasons_27,
  input io_in_bits_topdown_info_reasons_28,
  input io_in_bits_topdown_info_reasons_29,
  input io_in_bits_topdown_info_reasons_30,
  input io_in_bits_topdown_info_reasons_31,
  input io_in_bits_topdown_info_reasons_32,
  input io_in_bits_topdown_info_reasons_33,
  input io_in_bits_topdown_info_reasons_34,
  input io_in_bits_topdown_info_reasons_35,
  input io_in_bits_topdown_info_reasons_36,
  input io_in_bits_topdown_info_reasons_37,
  output io_out_0_valid,
  output [31:0] io_out_0_bits_instr,
  output [49:0] io_out_0_bits_pc,
  output [9:0] io_out_0_bits_foldpc,
  output io_out_0_bits_exceptionVec_1,
  output io_out_0_bits_exceptionVec_2,
  output io_out_0_bits_exceptionVec_12,
  output io_out_0_bits_exceptionVec_20,
  output io_out_0_bits_backendException,
  output [3:0] io_out_0_bits_trigger,
  output io_out_0_bits_pd_isRVC,
  output [1:0] io_out_0_bits_pd_brType,
  output io_out_0_bits_pred_taken,
  output io_out_0_bits_crossPageIPFFix,
  output io_out_0_bits_ftqPtr_flag,
  output [5:0] io_out_0_bits_ftqPtr_value,
  output [3:0] io_out_0_bits_ftqOffset,
  output io_out_0_bits_isLastInFtqEntry,
  output io_out_1_valid,
  output [31:0] io_out_1_bits_instr,
  output [49:0] io_out_1_bits_pc,
  output [9:0] io_out_1_bits_foldpc,
  output io_out_1_bits_exceptionVec_1,
  output io_out_1_bits_exceptionVec_2,
  output io_out_1_bits_exceptionVec_12,
  output io_out_1_bits_exceptionVec_20,
  output io_out_1_bits_backendException,
  output [3:0] io_out_1_bits_trigger,
  output io_out_1_bits_pd_isRVC,
  output [1:0] io_out_1_bits_pd_brType,
  output io_out_1_bits_pred_taken,
  output io_out_1_bits_crossPageIPFFix,
  output io_out_1_bits_ftqPtr_flag,
  output [5:0] io_out_1_bits_ftqPtr_value,
  output [3:0] io_out_1_bits_ftqOffset,
  output io_out_1_bits_isLastInFtqEntry,
  output io_out_2_valid,
  output [31:0] io_out_2_bits_instr,
  output [49:0] io_out_2_bits_pc,
  output [9:0] io_out_2_bits_foldpc,
  output io_out_2_bits_exceptionVec_1,
  output io_out_2_bits_exceptionVec_2,
  output io_out_2_bits_exceptionVec_12,
  output io_out_2_bits_exceptionVec_20,
  output io_out_2_bits_backendException,
  output [3:0] io_out_2_bits_trigger,
  output io_out_2_bits_pd_isRVC,
  output [1:0] io_out_2_bits_pd_brType,
  output io_out_2_bits_pred_taken,
  output io_out_2_bits_crossPageIPFFix,
  output io_out_2_bits_ftqPtr_flag,
  output [5:0] io_out_2_bits_ftqPtr_value,
  output [3:0] io_out_2_bits_ftqOffset,
  output io_out_2_bits_isLastInFtqEntry,
  output io_out_3_valid,
  output [31:0] io_out_3_bits_instr,
  output [49:0] io_out_3_bits_pc,
  output [9:0] io_out_3_bits_foldpc,
  output io_out_3_bits_exceptionVec_1,
  output io_out_3_bits_exceptionVec_2,
  output io_out_3_bits_exceptionVec_12,
  output io_out_3_bits_exceptionVec_20,
  output io_out_3_bits_backendException,
  output [3:0] io_out_3_bits_trigger,
  output io_out_3_bits_pd_isRVC,
  output [1:0] io_out_3_bits_pd_brType,
  output io_out_3_bits_pred_taken,
  output io_out_3_bits_crossPageIPFFix,
  output io_out_3_bits_ftqPtr_flag,
  output [5:0] io_out_3_bits_ftqPtr_value,
  output [3:0] io_out_3_bits_ftqOffset,
  output io_out_3_bits_isLastInFtqEntry,
  output io_out_4_valid,
  output [31:0] io_out_4_bits_instr,
  output [49:0] io_out_4_bits_pc,
  output [9:0] io_out_4_bits_foldpc,
  output io_out_4_bits_exceptionVec_1,
  output io_out_4_bits_exceptionVec_2,
  output io_out_4_bits_exceptionVec_12,
  output io_out_4_bits_exceptionVec_20,
  output io_out_4_bits_backendException,
  output [3:0] io_out_4_bits_trigger,
  output io_out_4_bits_pd_isRVC,
  output [1:0] io_out_4_bits_pd_brType,
  output io_out_4_bits_pred_taken,
  output io_out_4_bits_crossPageIPFFix,
  output io_out_4_bits_ftqPtr_flag,
  output [5:0] io_out_4_bits_ftqPtr_value,
  output [3:0] io_out_4_bits_ftqOffset,
  output io_out_4_bits_isLastInFtqEntry,
  output io_out_5_valid,
  output [31:0] io_out_5_bits_instr,
  output [49:0] io_out_5_bits_pc,
  output [9:0] io_out_5_bits_foldpc,
  output io_out_5_bits_exceptionVec_1,
  output io_out_5_bits_exceptionVec_2,
  output io_out_5_bits_exceptionVec_12,
  output io_out_5_bits_exceptionVec_20,
  output io_out_5_bits_backendException,
  output [3:0] io_out_5_bits_trigger,
  output io_out_5_bits_pd_isRVC,
  output [1:0] io_out_5_bits_pd_brType,
  output io_out_5_bits_pred_taken,
  output io_out_5_bits_crossPageIPFFix,
  output io_out_5_bits_ftqPtr_flag,
  output [5:0] io_out_5_bits_ftqPtr_value,
  output [3:0] io_out_5_bits_ftqOffset,
  output io_out_5_bits_isLastInFtqEntry,
  input io_decodeCanAccept,
  output [5:0] io_stallReason_reason_0,
  output [5:0] io_stallReason_reason_1,
  output [5:0] io_stallReason_reason_2,
  output [5:0] io_stallReason_reason_3,
  output [5:0] io_stallReason_reason_4,
  output [5:0] io_stallReason_reason_5,
  input io_stallReason_backReason_valid,
  input [5:0] io_stallReason_backReason_bits,
  output [5:0] io_perf_0_value,
  output [5:0] io_perf_1_value,
  output [5:0] io_perf_2_value,
  output [5:0] io_perf_3_value,
  output [5:0] io_perf_4_value,
  output [5:0] io_perf_5_value,
  output [5:0] io_perf_6_value,
  output [5:0] io_perf_7_value,
  output [5:0] io_perf_8_value
);

  // ---- 打包输入到核侧数组 ----
  wire [15:0][31:0] c_in_instrs;
  wire [15:0]       c_in_pd_isRVC;
  wire [15:0][1:0]  c_in_pd_brType;
  wire [15:0][9:0]  c_in_foldpc;
  wire [15:0]       c_in_ftqOffset_valid;
  wire [15:0][1:0]  c_in_exceptionType;
  wire [15:0]       c_in_crossPageIPFFix;
  wire [15:0]       c_in_illegalInstr;
  wire [15:0][3:0]  c_in_triggered;
  wire [15:0]       c_in_isLastInFtqEntry;
  wire [15:0][49:0] c_in_pc;
  wire [37:0]       c_topdown;

  assign c_in_instrs[0]=io_in_bits_instrs_0;
  assign c_in_pd_isRVC[0]=io_in_bits_pd_0_isRVC;
  assign c_in_pd_brType[0]=io_in_bits_pd_0_brType;
  assign c_in_foldpc[0]=io_in_bits_foldpc_0;
  assign c_in_ftqOffset_valid[0]=io_in_bits_ftqOffset_0_valid;
  assign c_in_exceptionType[0]=io_in_bits_exceptionType_0;
  assign c_in_crossPageIPFFix[0]=io_in_bits_crossPageIPFFix_0;
  assign c_in_illegalInstr[0]=io_in_bits_illegalInstr_0;
  assign c_in_triggered[0]=io_in_bits_triggered_0;
  assign c_in_isLastInFtqEntry[0]=io_in_bits_isLastInFtqEntry_0;
  assign c_in_pc[0]=io_in_bits_pc_0;
  assign c_in_instrs[1]=io_in_bits_instrs_1;
  assign c_in_pd_isRVC[1]=io_in_bits_pd_1_isRVC;
  assign c_in_pd_brType[1]=io_in_bits_pd_1_brType;
  assign c_in_foldpc[1]=io_in_bits_foldpc_1;
  assign c_in_ftqOffset_valid[1]=io_in_bits_ftqOffset_1_valid;
  assign c_in_exceptionType[1]=io_in_bits_exceptionType_1;
  assign c_in_crossPageIPFFix[1]=io_in_bits_crossPageIPFFix_1;
  assign c_in_illegalInstr[1]=io_in_bits_illegalInstr_1;
  assign c_in_triggered[1]=io_in_bits_triggered_1;
  assign c_in_isLastInFtqEntry[1]=io_in_bits_isLastInFtqEntry_1;
  assign c_in_pc[1]=io_in_bits_pc_1;
  assign c_in_instrs[2]=io_in_bits_instrs_2;
  assign c_in_pd_isRVC[2]=io_in_bits_pd_2_isRVC;
  assign c_in_pd_brType[2]=io_in_bits_pd_2_brType;
  assign c_in_foldpc[2]=io_in_bits_foldpc_2;
  assign c_in_ftqOffset_valid[2]=io_in_bits_ftqOffset_2_valid;
  assign c_in_exceptionType[2]=io_in_bits_exceptionType_2;
  assign c_in_crossPageIPFFix[2]=io_in_bits_crossPageIPFFix_2;
  assign c_in_illegalInstr[2]=io_in_bits_illegalInstr_2;
  assign c_in_triggered[2]=io_in_bits_triggered_2;
  assign c_in_isLastInFtqEntry[2]=io_in_bits_isLastInFtqEntry_2;
  assign c_in_pc[2]=io_in_bits_pc_2;
  assign c_in_instrs[3]=io_in_bits_instrs_3;
  assign c_in_pd_isRVC[3]=io_in_bits_pd_3_isRVC;
  assign c_in_pd_brType[3]=io_in_bits_pd_3_brType;
  assign c_in_foldpc[3]=io_in_bits_foldpc_3;
  assign c_in_ftqOffset_valid[3]=io_in_bits_ftqOffset_3_valid;
  assign c_in_exceptionType[3]=io_in_bits_exceptionType_3;
  assign c_in_crossPageIPFFix[3]=io_in_bits_crossPageIPFFix_3;
  assign c_in_illegalInstr[3]=io_in_bits_illegalInstr_3;
  assign c_in_triggered[3]=io_in_bits_triggered_3;
  assign c_in_isLastInFtqEntry[3]=io_in_bits_isLastInFtqEntry_3;
  assign c_in_pc[3]=io_in_bits_pc_3;
  assign c_in_instrs[4]=io_in_bits_instrs_4;
  assign c_in_pd_isRVC[4]=io_in_bits_pd_4_isRVC;
  assign c_in_pd_brType[4]=io_in_bits_pd_4_brType;
  assign c_in_foldpc[4]=io_in_bits_foldpc_4;
  assign c_in_ftqOffset_valid[4]=io_in_bits_ftqOffset_4_valid;
  assign c_in_exceptionType[4]=io_in_bits_exceptionType_4;
  assign c_in_crossPageIPFFix[4]=io_in_bits_crossPageIPFFix_4;
  assign c_in_illegalInstr[4]=io_in_bits_illegalInstr_4;
  assign c_in_triggered[4]=io_in_bits_triggered_4;
  assign c_in_isLastInFtqEntry[4]=io_in_bits_isLastInFtqEntry_4;
  assign c_in_pc[4]=io_in_bits_pc_4;
  assign c_in_instrs[5]=io_in_bits_instrs_5;
  assign c_in_pd_isRVC[5]=io_in_bits_pd_5_isRVC;
  assign c_in_pd_brType[5]=io_in_bits_pd_5_brType;
  assign c_in_foldpc[5]=io_in_bits_foldpc_5;
  assign c_in_ftqOffset_valid[5]=io_in_bits_ftqOffset_5_valid;
  assign c_in_exceptionType[5]=io_in_bits_exceptionType_5;
  assign c_in_crossPageIPFFix[5]=io_in_bits_crossPageIPFFix_5;
  assign c_in_illegalInstr[5]=io_in_bits_illegalInstr_5;
  assign c_in_triggered[5]=io_in_bits_triggered_5;
  assign c_in_isLastInFtqEntry[5]=io_in_bits_isLastInFtqEntry_5;
  assign c_in_pc[5]=io_in_bits_pc_5;
  assign c_in_instrs[6]=io_in_bits_instrs_6;
  assign c_in_pd_isRVC[6]=io_in_bits_pd_6_isRVC;
  assign c_in_pd_brType[6]=io_in_bits_pd_6_brType;
  assign c_in_foldpc[6]=io_in_bits_foldpc_6;
  assign c_in_ftqOffset_valid[6]=io_in_bits_ftqOffset_6_valid;
  assign c_in_exceptionType[6]=io_in_bits_exceptionType_6;
  assign c_in_crossPageIPFFix[6]=io_in_bits_crossPageIPFFix_6;
  assign c_in_illegalInstr[6]=io_in_bits_illegalInstr_6;
  assign c_in_triggered[6]=io_in_bits_triggered_6;
  assign c_in_isLastInFtqEntry[6]=io_in_bits_isLastInFtqEntry_6;
  assign c_in_pc[6]=io_in_bits_pc_6;
  assign c_in_instrs[7]=io_in_bits_instrs_7;
  assign c_in_pd_isRVC[7]=io_in_bits_pd_7_isRVC;
  assign c_in_pd_brType[7]=io_in_bits_pd_7_brType;
  assign c_in_foldpc[7]=io_in_bits_foldpc_7;
  assign c_in_ftqOffset_valid[7]=io_in_bits_ftqOffset_7_valid;
  assign c_in_exceptionType[7]=io_in_bits_exceptionType_7;
  assign c_in_crossPageIPFFix[7]=io_in_bits_crossPageIPFFix_7;
  assign c_in_illegalInstr[7]=io_in_bits_illegalInstr_7;
  assign c_in_triggered[7]=io_in_bits_triggered_7;
  assign c_in_isLastInFtqEntry[7]=io_in_bits_isLastInFtqEntry_7;
  assign c_in_pc[7]=io_in_bits_pc_7;
  assign c_in_instrs[8]=io_in_bits_instrs_8;
  assign c_in_pd_isRVC[8]=io_in_bits_pd_8_isRVC;
  assign c_in_pd_brType[8]=io_in_bits_pd_8_brType;
  assign c_in_foldpc[8]=io_in_bits_foldpc_8;
  assign c_in_ftqOffset_valid[8]=io_in_bits_ftqOffset_8_valid;
  assign c_in_exceptionType[8]=io_in_bits_exceptionType_8;
  assign c_in_crossPageIPFFix[8]=io_in_bits_crossPageIPFFix_8;
  assign c_in_illegalInstr[8]=io_in_bits_illegalInstr_8;
  assign c_in_triggered[8]=io_in_bits_triggered_8;
  assign c_in_isLastInFtqEntry[8]=io_in_bits_isLastInFtqEntry_8;
  assign c_in_pc[8]=io_in_bits_pc_8;
  assign c_in_instrs[9]=io_in_bits_instrs_9;
  assign c_in_pd_isRVC[9]=io_in_bits_pd_9_isRVC;
  assign c_in_pd_brType[9]=io_in_bits_pd_9_brType;
  assign c_in_foldpc[9]=io_in_bits_foldpc_9;
  assign c_in_ftqOffset_valid[9]=io_in_bits_ftqOffset_9_valid;
  assign c_in_exceptionType[9]=io_in_bits_exceptionType_9;
  assign c_in_crossPageIPFFix[9]=io_in_bits_crossPageIPFFix_9;
  assign c_in_illegalInstr[9]=io_in_bits_illegalInstr_9;
  assign c_in_triggered[9]=io_in_bits_triggered_9;
  assign c_in_isLastInFtqEntry[9]=io_in_bits_isLastInFtqEntry_9;
  assign c_in_pc[9]=io_in_bits_pc_9;
  assign c_in_instrs[10]=io_in_bits_instrs_10;
  assign c_in_pd_isRVC[10]=io_in_bits_pd_10_isRVC;
  assign c_in_pd_brType[10]=io_in_bits_pd_10_brType;
  assign c_in_foldpc[10]=io_in_bits_foldpc_10;
  assign c_in_ftqOffset_valid[10]=io_in_bits_ftqOffset_10_valid;
  assign c_in_exceptionType[10]=io_in_bits_exceptionType_10;
  assign c_in_crossPageIPFFix[10]=io_in_bits_crossPageIPFFix_10;
  assign c_in_illegalInstr[10]=io_in_bits_illegalInstr_10;
  assign c_in_triggered[10]=io_in_bits_triggered_10;
  assign c_in_isLastInFtqEntry[10]=io_in_bits_isLastInFtqEntry_10;
  assign c_in_pc[10]=io_in_bits_pc_10;
  assign c_in_instrs[11]=io_in_bits_instrs_11;
  assign c_in_pd_isRVC[11]=io_in_bits_pd_11_isRVC;
  assign c_in_pd_brType[11]=io_in_bits_pd_11_brType;
  assign c_in_foldpc[11]=io_in_bits_foldpc_11;
  assign c_in_ftqOffset_valid[11]=io_in_bits_ftqOffset_11_valid;
  assign c_in_exceptionType[11]=io_in_bits_exceptionType_11;
  assign c_in_crossPageIPFFix[11]=io_in_bits_crossPageIPFFix_11;
  assign c_in_illegalInstr[11]=io_in_bits_illegalInstr_11;
  assign c_in_triggered[11]=io_in_bits_triggered_11;
  assign c_in_isLastInFtqEntry[11]=io_in_bits_isLastInFtqEntry_11;
  assign c_in_pc[11]=io_in_bits_pc_11;
  assign c_in_instrs[12]=io_in_bits_instrs_12;
  assign c_in_pd_isRVC[12]=io_in_bits_pd_12_isRVC;
  assign c_in_pd_brType[12]=io_in_bits_pd_12_brType;
  assign c_in_foldpc[12]=io_in_bits_foldpc_12;
  assign c_in_ftqOffset_valid[12]=io_in_bits_ftqOffset_12_valid;
  assign c_in_exceptionType[12]=io_in_bits_exceptionType_12;
  assign c_in_crossPageIPFFix[12]=io_in_bits_crossPageIPFFix_12;
  assign c_in_illegalInstr[12]=io_in_bits_illegalInstr_12;
  assign c_in_triggered[12]=io_in_bits_triggered_12;
  assign c_in_isLastInFtqEntry[12]=io_in_bits_isLastInFtqEntry_12;
  assign c_in_pc[12]=io_in_bits_pc_12;
  assign c_in_instrs[13]=io_in_bits_instrs_13;
  assign c_in_pd_isRVC[13]=io_in_bits_pd_13_isRVC;
  assign c_in_pd_brType[13]=io_in_bits_pd_13_brType;
  assign c_in_foldpc[13]=io_in_bits_foldpc_13;
  assign c_in_ftqOffset_valid[13]=io_in_bits_ftqOffset_13_valid;
  assign c_in_exceptionType[13]=io_in_bits_exceptionType_13;
  assign c_in_crossPageIPFFix[13]=io_in_bits_crossPageIPFFix_13;
  assign c_in_illegalInstr[13]=io_in_bits_illegalInstr_13;
  assign c_in_triggered[13]=io_in_bits_triggered_13;
  assign c_in_isLastInFtqEntry[13]=io_in_bits_isLastInFtqEntry_13;
  assign c_in_pc[13]=io_in_bits_pc_13;
  assign c_in_instrs[14]=io_in_bits_instrs_14;
  assign c_in_pd_isRVC[14]=io_in_bits_pd_14_isRVC;
  assign c_in_pd_brType[14]=io_in_bits_pd_14_brType;
  assign c_in_foldpc[14]=io_in_bits_foldpc_14;
  assign c_in_ftqOffset_valid[14]=io_in_bits_ftqOffset_14_valid;
  assign c_in_exceptionType[14]=io_in_bits_exceptionType_14;
  assign c_in_crossPageIPFFix[14]=io_in_bits_crossPageIPFFix_14;
  assign c_in_illegalInstr[14]=io_in_bits_illegalInstr_14;
  assign c_in_triggered[14]=io_in_bits_triggered_14;
  assign c_in_isLastInFtqEntry[14]=io_in_bits_isLastInFtqEntry_14;
  assign c_in_pc[14]=io_in_bits_pc_14;
  assign c_in_instrs[15]=io_in_bits_instrs_15;
  assign c_in_pd_isRVC[15]=io_in_bits_pd_15_isRVC;
  assign c_in_pd_brType[15]=io_in_bits_pd_15_brType;
  assign c_in_foldpc[15]=io_in_bits_foldpc_15;
  assign c_in_ftqOffset_valid[15]=io_in_bits_ftqOffset_15_valid;
  assign c_in_exceptionType[15]=io_in_bits_exceptionType_15;
  assign c_in_crossPageIPFFix[15]=io_in_bits_crossPageIPFFix_15;
  assign c_in_illegalInstr[15]=io_in_bits_illegalInstr_15;
  assign c_in_triggered[15]=io_in_bits_triggered_15;
  assign c_in_isLastInFtqEntry[15]=io_in_bits_isLastInFtqEntry_15;
  assign c_in_pc[15]=io_in_bits_pc_15;
  assign c_topdown[0]=io_in_bits_topdown_info_reasons_0;
  assign c_topdown[1]=io_in_bits_topdown_info_reasons_1;
  assign c_topdown[2]=io_in_bits_topdown_info_reasons_2;
  assign c_topdown[3]=io_in_bits_topdown_info_reasons_3;
  assign c_topdown[4]=io_in_bits_topdown_info_reasons_4;
  assign c_topdown[5]=io_in_bits_topdown_info_reasons_5;
  assign c_topdown[6]=io_in_bits_topdown_info_reasons_6;
  assign c_topdown[7]=io_in_bits_topdown_info_reasons_7;
  assign c_topdown[8]=io_in_bits_topdown_info_reasons_8;
  assign c_topdown[9]=io_in_bits_topdown_info_reasons_9;
  assign c_topdown[10]=io_in_bits_topdown_info_reasons_10;
  assign c_topdown[11]=io_in_bits_topdown_info_reasons_11;
  assign c_topdown[12]=io_in_bits_topdown_info_reasons_12;
  assign c_topdown[13]=io_in_bits_topdown_info_reasons_13;
  assign c_topdown[14]=io_in_bits_topdown_info_reasons_14;
  assign c_topdown[15]=io_in_bits_topdown_info_reasons_15;
  assign c_topdown[16]=io_in_bits_topdown_info_reasons_16;
  assign c_topdown[17]=io_in_bits_topdown_info_reasons_17;
  assign c_topdown[18]=io_in_bits_topdown_info_reasons_18;
  assign c_topdown[19]=io_in_bits_topdown_info_reasons_19;
  assign c_topdown[20]=io_in_bits_topdown_info_reasons_20;
  assign c_topdown[21]=io_in_bits_topdown_info_reasons_21;
  assign c_topdown[22]=io_in_bits_topdown_info_reasons_22;
  assign c_topdown[23]=io_in_bits_topdown_info_reasons_23;
  assign c_topdown[24]=io_in_bits_topdown_info_reasons_24;
  assign c_topdown[25]=io_in_bits_topdown_info_reasons_25;
  assign c_topdown[26]=io_in_bits_topdown_info_reasons_26;
  assign c_topdown[27]=io_in_bits_topdown_info_reasons_27;
  assign c_topdown[28]=io_in_bits_topdown_info_reasons_28;
  assign c_topdown[29]=io_in_bits_topdown_info_reasons_29;
  assign c_topdown[30]=io_in_bits_topdown_info_reasons_30;
  assign c_topdown[31]=io_in_bits_topdown_info_reasons_31;
  assign c_topdown[32]=io_in_bits_topdown_info_reasons_32;
  assign c_topdown[33]=io_in_bits_topdown_info_reasons_33;
  assign c_topdown[34]=io_in_bits_topdown_info_reasons_34;
  assign c_topdown[35]=io_in_bits_topdown_info_reasons_35;
  assign c_topdown[36]=io_in_bits_topdown_info_reasons_36;
  assign c_topdown[37]=io_in_bits_topdown_info_reasons_37;

  // ---- 核侧输出数组（再拆到扁平端口）----
  wire [5:0]        c_out_valid;
  wire [5:0][31:0]  c_out_instr;
  wire [5:0][49:0]  c_out_pc;
  wire [5:0][9:0]   c_out_foldpc;
  wire [5:0]        c_out_ev_pf, c_out_ev_af, c_out_ev_gpf, c_out_ev_ii;
  wire [5:0]        c_out_backendException;
  wire [5:0][3:0]   c_out_trigger;
  wire [5:0]        c_out_pd_isRVC;
  wire [5:0][1:0]   c_out_pd_brType;
  wire [5:0]        c_out_pred_taken;
  wire [5:0]        c_out_crossPageIPFFix;
  wire [5:0]        c_out_ftqPtr_flag;
  wire [5:0][5:0]   c_out_ftqPtr_value;
  wire [5:0][3:0]   c_out_ftqOffset;
  wire [5:0]        c_out_isLastInFtqEntry;
  wire [5:0][5:0]   c_stallReason;
  wire [8:0][5:0]   c_perf;

  assign io_out_0_valid=c_out_valid[0];
  assign io_out_0_bits_instr=c_out_instr[0];
  assign io_out_0_bits_pc=c_out_pc[0];
  assign io_out_0_bits_foldpc=c_out_foldpc[0];
  assign io_out_0_bits_exceptionVec_1=c_out_ev_af[0];
  assign io_out_0_bits_exceptionVec_2=c_out_ev_ii[0];
  assign io_out_0_bits_exceptionVec_12=c_out_ev_pf[0];
  assign io_out_0_bits_exceptionVec_20=c_out_ev_gpf[0];
  assign io_out_0_bits_backendException=c_out_backendException[0];
  assign io_out_0_bits_trigger=c_out_trigger[0];
  assign io_out_0_bits_pd_isRVC=c_out_pd_isRVC[0];
  assign io_out_0_bits_pd_brType=c_out_pd_brType[0];
  assign io_out_0_bits_pred_taken=c_out_pred_taken[0];
  assign io_out_0_bits_crossPageIPFFix=c_out_crossPageIPFFix[0];
  assign io_out_0_bits_ftqPtr_flag=c_out_ftqPtr_flag[0];
  assign io_out_0_bits_ftqPtr_value=c_out_ftqPtr_value[0];
  assign io_out_0_bits_ftqOffset=c_out_ftqOffset[0];
  assign io_out_0_bits_isLastInFtqEntry=c_out_isLastInFtqEntry[0];
  assign io_stallReason_reason_0=c_stallReason[0];
  assign io_out_1_valid=c_out_valid[1];
  assign io_out_1_bits_instr=c_out_instr[1];
  assign io_out_1_bits_pc=c_out_pc[1];
  assign io_out_1_bits_foldpc=c_out_foldpc[1];
  assign io_out_1_bits_exceptionVec_1=c_out_ev_af[1];
  assign io_out_1_bits_exceptionVec_2=c_out_ev_ii[1];
  assign io_out_1_bits_exceptionVec_12=c_out_ev_pf[1];
  assign io_out_1_bits_exceptionVec_20=c_out_ev_gpf[1];
  assign io_out_1_bits_backendException=c_out_backendException[1];
  assign io_out_1_bits_trigger=c_out_trigger[1];
  assign io_out_1_bits_pd_isRVC=c_out_pd_isRVC[1];
  assign io_out_1_bits_pd_brType=c_out_pd_brType[1];
  assign io_out_1_bits_pred_taken=c_out_pred_taken[1];
  assign io_out_1_bits_crossPageIPFFix=c_out_crossPageIPFFix[1];
  assign io_out_1_bits_ftqPtr_flag=c_out_ftqPtr_flag[1];
  assign io_out_1_bits_ftqPtr_value=c_out_ftqPtr_value[1];
  assign io_out_1_bits_ftqOffset=c_out_ftqOffset[1];
  assign io_out_1_bits_isLastInFtqEntry=c_out_isLastInFtqEntry[1];
  assign io_stallReason_reason_1=c_stallReason[1];
  assign io_out_2_valid=c_out_valid[2];
  assign io_out_2_bits_instr=c_out_instr[2];
  assign io_out_2_bits_pc=c_out_pc[2];
  assign io_out_2_bits_foldpc=c_out_foldpc[2];
  assign io_out_2_bits_exceptionVec_1=c_out_ev_af[2];
  assign io_out_2_bits_exceptionVec_2=c_out_ev_ii[2];
  assign io_out_2_bits_exceptionVec_12=c_out_ev_pf[2];
  assign io_out_2_bits_exceptionVec_20=c_out_ev_gpf[2];
  assign io_out_2_bits_backendException=c_out_backendException[2];
  assign io_out_2_bits_trigger=c_out_trigger[2];
  assign io_out_2_bits_pd_isRVC=c_out_pd_isRVC[2];
  assign io_out_2_bits_pd_brType=c_out_pd_brType[2];
  assign io_out_2_bits_pred_taken=c_out_pred_taken[2];
  assign io_out_2_bits_crossPageIPFFix=c_out_crossPageIPFFix[2];
  assign io_out_2_bits_ftqPtr_flag=c_out_ftqPtr_flag[2];
  assign io_out_2_bits_ftqPtr_value=c_out_ftqPtr_value[2];
  assign io_out_2_bits_ftqOffset=c_out_ftqOffset[2];
  assign io_out_2_bits_isLastInFtqEntry=c_out_isLastInFtqEntry[2];
  assign io_stallReason_reason_2=c_stallReason[2];
  assign io_out_3_valid=c_out_valid[3];
  assign io_out_3_bits_instr=c_out_instr[3];
  assign io_out_3_bits_pc=c_out_pc[3];
  assign io_out_3_bits_foldpc=c_out_foldpc[3];
  assign io_out_3_bits_exceptionVec_1=c_out_ev_af[3];
  assign io_out_3_bits_exceptionVec_2=c_out_ev_ii[3];
  assign io_out_3_bits_exceptionVec_12=c_out_ev_pf[3];
  assign io_out_3_bits_exceptionVec_20=c_out_ev_gpf[3];
  assign io_out_3_bits_backendException=c_out_backendException[3];
  assign io_out_3_bits_trigger=c_out_trigger[3];
  assign io_out_3_bits_pd_isRVC=c_out_pd_isRVC[3];
  assign io_out_3_bits_pd_brType=c_out_pd_brType[3];
  assign io_out_3_bits_pred_taken=c_out_pred_taken[3];
  assign io_out_3_bits_crossPageIPFFix=c_out_crossPageIPFFix[3];
  assign io_out_3_bits_ftqPtr_flag=c_out_ftqPtr_flag[3];
  assign io_out_3_bits_ftqPtr_value=c_out_ftqPtr_value[3];
  assign io_out_3_bits_ftqOffset=c_out_ftqOffset[3];
  assign io_out_3_bits_isLastInFtqEntry=c_out_isLastInFtqEntry[3];
  assign io_stallReason_reason_3=c_stallReason[3];
  assign io_out_4_valid=c_out_valid[4];
  assign io_out_4_bits_instr=c_out_instr[4];
  assign io_out_4_bits_pc=c_out_pc[4];
  assign io_out_4_bits_foldpc=c_out_foldpc[4];
  assign io_out_4_bits_exceptionVec_1=c_out_ev_af[4];
  assign io_out_4_bits_exceptionVec_2=c_out_ev_ii[4];
  assign io_out_4_bits_exceptionVec_12=c_out_ev_pf[4];
  assign io_out_4_bits_exceptionVec_20=c_out_ev_gpf[4];
  assign io_out_4_bits_backendException=c_out_backendException[4];
  assign io_out_4_bits_trigger=c_out_trigger[4];
  assign io_out_4_bits_pd_isRVC=c_out_pd_isRVC[4];
  assign io_out_4_bits_pd_brType=c_out_pd_brType[4];
  assign io_out_4_bits_pred_taken=c_out_pred_taken[4];
  assign io_out_4_bits_crossPageIPFFix=c_out_crossPageIPFFix[4];
  assign io_out_4_bits_ftqPtr_flag=c_out_ftqPtr_flag[4];
  assign io_out_4_bits_ftqPtr_value=c_out_ftqPtr_value[4];
  assign io_out_4_bits_ftqOffset=c_out_ftqOffset[4];
  assign io_out_4_bits_isLastInFtqEntry=c_out_isLastInFtqEntry[4];
  assign io_stallReason_reason_4=c_stallReason[4];
  assign io_out_5_valid=c_out_valid[5];
  assign io_out_5_bits_instr=c_out_instr[5];
  assign io_out_5_bits_pc=c_out_pc[5];
  assign io_out_5_bits_foldpc=c_out_foldpc[5];
  assign io_out_5_bits_exceptionVec_1=c_out_ev_af[5];
  assign io_out_5_bits_exceptionVec_2=c_out_ev_ii[5];
  assign io_out_5_bits_exceptionVec_12=c_out_ev_pf[5];
  assign io_out_5_bits_exceptionVec_20=c_out_ev_gpf[5];
  assign io_out_5_bits_backendException=c_out_backendException[5];
  assign io_out_5_bits_trigger=c_out_trigger[5];
  assign io_out_5_bits_pd_isRVC=c_out_pd_isRVC[5];
  assign io_out_5_bits_pd_brType=c_out_pd_brType[5];
  assign io_out_5_bits_pred_taken=c_out_pred_taken[5];
  assign io_out_5_bits_crossPageIPFFix=c_out_crossPageIPFFix[5];
  assign io_out_5_bits_ftqPtr_flag=c_out_ftqPtr_flag[5];
  assign io_out_5_bits_ftqPtr_value=c_out_ftqPtr_value[5];
  assign io_out_5_bits_ftqOffset=c_out_ftqOffset[5];
  assign io_out_5_bits_isLastInFtqEntry=c_out_isLastInFtqEntry[5];
  assign io_stallReason_reason_5=c_stallReason[5];
  assign io_perf_0_value=c_perf[0];
  assign io_perf_1_value=c_perf[1];
  assign io_perf_2_value=c_perf[2];
  assign io_perf_3_value=c_perf[3];
  assign io_perf_4_value=c_perf[4];
  assign io_perf_5_value=c_perf[5];
  assign io_perf_6_value=c_perf[6];
  assign io_perf_7_value=c_perf[7];
  assign io_perf_8_value=c_perf[8];

  xs_IBuffer_core u_core (
    .clock(clock), .reset(reset),
    .flush(io_flush),
    .ControlRedirect(io_ControlRedirect),
    .ControlBTBMissBubble(io_ControlBTBMissBubble),
    .TAGEMissBubble(io_TAGEMissBubble),
    .SCMissBubble(io_SCMissBubble),
    .ITTAGEMissBubble(io_ITTAGEMissBubble),
    .RASMissBubble(io_RASMissBubble),
    .MemVioRedirect(io_MemVioRedirect),
    .in_ready(io_in_ready),
    .in_valid(io_in_valid),
    .in_instrs(c_in_instrs),
    .in_valid_mask(io_in_bits_valid),
    .in_enqEnable(io_in_bits_enqEnable),
    .in_pd_isRVC(c_in_pd_isRVC),
    .in_pd_brType(c_in_pd_brType),
    .in_foldpc(c_in_foldpc),
    .in_ftqOffset_valid(c_in_ftqOffset_valid),
    .in_backendException0(io_in_bits_backendException_0),
    .in_exceptionType(c_in_exceptionType),
    .in_crossPageIPFFix(c_in_crossPageIPFFix),
    .in_illegalInstr(c_in_illegalInstr),
    .in_triggered(c_in_triggered),
    .in_isLastInFtqEntry(c_in_isLastInFtqEntry),
    .in_pc(c_in_pc),
    .in_ftqPtr_flag(io_in_bits_ftqPtr_flag),
    .in_ftqPtr_value(io_in_bits_ftqPtr_value),
    .out_valid(c_out_valid),
    .out_instr(c_out_instr),
    .out_pc(c_out_pc),
    .out_foldpc(c_out_foldpc),
    .out_exceptionVec_instrPageFault(c_out_ev_pf),
    .out_exceptionVec_instrAccessFault(c_out_ev_af),
    .out_exceptionVec_instrGuestPageFault(c_out_ev_gpf),
    .out_exceptionVec_EX_II(c_out_ev_ii),
    .out_backendException(c_out_backendException),
    .out_trigger(c_out_trigger),
    .out_pd_isRVC(c_out_pd_isRVC),
    .out_pd_brType(c_out_pd_brType),
    .out_pred_taken(c_out_pred_taken),
    .out_crossPageIPFFix(c_out_crossPageIPFFix),
    .out_ftqPtr_flag(c_out_ftqPtr_flag),
    .out_ftqPtr_value(c_out_ftqPtr_value),
    .out_ftqOffset(c_out_ftqOffset),
    .out_isLastInFtqEntry(c_out_isLastInFtqEntry),
    .decodeCanAccept(io_decodeCanAccept),
    .full(/* golden DCE: io.full 顶层未连接 */),
    .stallReason_reason(c_stallReason),
    .stallReason_backReason_valid(io_stallReason_backReason_valid),
    .stallReason_backReason_bits(io_stallReason_backReason_bits),
    .topdown_info_reasons(c_topdown),
    .perf_value(c_perf)
  );
endmodule
