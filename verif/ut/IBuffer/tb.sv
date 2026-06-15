// 手写：IBuffer golden vs _xs 双例化逐拍随机比对 testbench
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 40000;
  int unsigned WARMUP  = 2000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int unsigned cycle = 0;
  always #5 clk = ~clk;
  always @(posedge clk) cycle++;

  logic io_flush;
  logic io_ControlRedirect;
  logic io_ControlBTBMissBubble;
  logic io_TAGEMissBubble;
  logic io_SCMissBubble;
  logic io_ITTAGEMissBubble;
  logic io_RASMissBubble;
  logic io_MemVioRedirect;
  logic io_in_valid;
  logic [31:0] io_in_bits_instrs_0;
  logic [31:0] io_in_bits_instrs_1;
  logic [31:0] io_in_bits_instrs_2;
  logic [31:0] io_in_bits_instrs_3;
  logic [31:0] io_in_bits_instrs_4;
  logic [31:0] io_in_bits_instrs_5;
  logic [31:0] io_in_bits_instrs_6;
  logic [31:0] io_in_bits_instrs_7;
  logic [31:0] io_in_bits_instrs_8;
  logic [31:0] io_in_bits_instrs_9;
  logic [31:0] io_in_bits_instrs_10;
  logic [31:0] io_in_bits_instrs_11;
  logic [31:0] io_in_bits_instrs_12;
  logic [31:0] io_in_bits_instrs_13;
  logic [31:0] io_in_bits_instrs_14;
  logic [31:0] io_in_bits_instrs_15;
  logic [15:0] io_in_bits_valid;
  logic [15:0] io_in_bits_enqEnable;
  logic io_in_bits_pd_0_isRVC;
  logic [1:0] io_in_bits_pd_0_brType;
  logic io_in_bits_pd_1_isRVC;
  logic [1:0] io_in_bits_pd_1_brType;
  logic io_in_bits_pd_2_isRVC;
  logic [1:0] io_in_bits_pd_2_brType;
  logic io_in_bits_pd_3_isRVC;
  logic [1:0] io_in_bits_pd_3_brType;
  logic io_in_bits_pd_4_isRVC;
  logic [1:0] io_in_bits_pd_4_brType;
  logic io_in_bits_pd_5_isRVC;
  logic [1:0] io_in_bits_pd_5_brType;
  logic io_in_bits_pd_6_isRVC;
  logic [1:0] io_in_bits_pd_6_brType;
  logic io_in_bits_pd_7_isRVC;
  logic [1:0] io_in_bits_pd_7_brType;
  logic io_in_bits_pd_8_isRVC;
  logic [1:0] io_in_bits_pd_8_brType;
  logic io_in_bits_pd_9_isRVC;
  logic [1:0] io_in_bits_pd_9_brType;
  logic io_in_bits_pd_10_isRVC;
  logic [1:0] io_in_bits_pd_10_brType;
  logic io_in_bits_pd_11_isRVC;
  logic [1:0] io_in_bits_pd_11_brType;
  logic io_in_bits_pd_12_isRVC;
  logic [1:0] io_in_bits_pd_12_brType;
  logic io_in_bits_pd_13_isRVC;
  logic [1:0] io_in_bits_pd_13_brType;
  logic io_in_bits_pd_14_isRVC;
  logic [1:0] io_in_bits_pd_14_brType;
  logic io_in_bits_pd_15_isRVC;
  logic [1:0] io_in_bits_pd_15_brType;
  logic [9:0] io_in_bits_foldpc_0;
  logic [9:0] io_in_bits_foldpc_1;
  logic [9:0] io_in_bits_foldpc_2;
  logic [9:0] io_in_bits_foldpc_3;
  logic [9:0] io_in_bits_foldpc_4;
  logic [9:0] io_in_bits_foldpc_5;
  logic [9:0] io_in_bits_foldpc_6;
  logic [9:0] io_in_bits_foldpc_7;
  logic [9:0] io_in_bits_foldpc_8;
  logic [9:0] io_in_bits_foldpc_9;
  logic [9:0] io_in_bits_foldpc_10;
  logic [9:0] io_in_bits_foldpc_11;
  logic [9:0] io_in_bits_foldpc_12;
  logic [9:0] io_in_bits_foldpc_13;
  logic [9:0] io_in_bits_foldpc_14;
  logic [9:0] io_in_bits_foldpc_15;
  logic io_in_bits_ftqOffset_0_valid;
  logic io_in_bits_ftqOffset_1_valid;
  logic io_in_bits_ftqOffset_2_valid;
  logic io_in_bits_ftqOffset_3_valid;
  logic io_in_bits_ftqOffset_4_valid;
  logic io_in_bits_ftqOffset_5_valid;
  logic io_in_bits_ftqOffset_6_valid;
  logic io_in_bits_ftqOffset_7_valid;
  logic io_in_bits_ftqOffset_8_valid;
  logic io_in_bits_ftqOffset_9_valid;
  logic io_in_bits_ftqOffset_10_valid;
  logic io_in_bits_ftqOffset_11_valid;
  logic io_in_bits_ftqOffset_12_valid;
  logic io_in_bits_ftqOffset_13_valid;
  logic io_in_bits_ftqOffset_14_valid;
  logic io_in_bits_ftqOffset_15_valid;
  logic io_in_bits_backendException_0;
  logic [1:0] io_in_bits_exceptionType_0;
  logic [1:0] io_in_bits_exceptionType_1;
  logic [1:0] io_in_bits_exceptionType_2;
  logic [1:0] io_in_bits_exceptionType_3;
  logic [1:0] io_in_bits_exceptionType_4;
  logic [1:0] io_in_bits_exceptionType_5;
  logic [1:0] io_in_bits_exceptionType_6;
  logic [1:0] io_in_bits_exceptionType_7;
  logic [1:0] io_in_bits_exceptionType_8;
  logic [1:0] io_in_bits_exceptionType_9;
  logic [1:0] io_in_bits_exceptionType_10;
  logic [1:0] io_in_bits_exceptionType_11;
  logic [1:0] io_in_bits_exceptionType_12;
  logic [1:0] io_in_bits_exceptionType_13;
  logic [1:0] io_in_bits_exceptionType_14;
  logic [1:0] io_in_bits_exceptionType_15;
  logic io_in_bits_crossPageIPFFix_0;
  logic io_in_bits_crossPageIPFFix_1;
  logic io_in_bits_crossPageIPFFix_2;
  logic io_in_bits_crossPageIPFFix_3;
  logic io_in_bits_crossPageIPFFix_4;
  logic io_in_bits_crossPageIPFFix_5;
  logic io_in_bits_crossPageIPFFix_6;
  logic io_in_bits_crossPageIPFFix_7;
  logic io_in_bits_crossPageIPFFix_8;
  logic io_in_bits_crossPageIPFFix_9;
  logic io_in_bits_crossPageIPFFix_10;
  logic io_in_bits_crossPageIPFFix_11;
  logic io_in_bits_crossPageIPFFix_12;
  logic io_in_bits_crossPageIPFFix_13;
  logic io_in_bits_crossPageIPFFix_14;
  logic io_in_bits_crossPageIPFFix_15;
  logic io_in_bits_illegalInstr_0;
  logic io_in_bits_illegalInstr_1;
  logic io_in_bits_illegalInstr_2;
  logic io_in_bits_illegalInstr_3;
  logic io_in_bits_illegalInstr_4;
  logic io_in_bits_illegalInstr_5;
  logic io_in_bits_illegalInstr_6;
  logic io_in_bits_illegalInstr_7;
  logic io_in_bits_illegalInstr_8;
  logic io_in_bits_illegalInstr_9;
  logic io_in_bits_illegalInstr_10;
  logic io_in_bits_illegalInstr_11;
  logic io_in_bits_illegalInstr_12;
  logic io_in_bits_illegalInstr_13;
  logic io_in_bits_illegalInstr_14;
  logic io_in_bits_illegalInstr_15;
  logic [3:0] io_in_bits_triggered_0;
  logic [3:0] io_in_bits_triggered_1;
  logic [3:0] io_in_bits_triggered_2;
  logic [3:0] io_in_bits_triggered_3;
  logic [3:0] io_in_bits_triggered_4;
  logic [3:0] io_in_bits_triggered_5;
  logic [3:0] io_in_bits_triggered_6;
  logic [3:0] io_in_bits_triggered_7;
  logic [3:0] io_in_bits_triggered_8;
  logic [3:0] io_in_bits_triggered_9;
  logic [3:0] io_in_bits_triggered_10;
  logic [3:0] io_in_bits_triggered_11;
  logic [3:0] io_in_bits_triggered_12;
  logic [3:0] io_in_bits_triggered_13;
  logic [3:0] io_in_bits_triggered_14;
  logic [3:0] io_in_bits_triggered_15;
  logic io_in_bits_isLastInFtqEntry_0;
  logic io_in_bits_isLastInFtqEntry_1;
  logic io_in_bits_isLastInFtqEntry_2;
  logic io_in_bits_isLastInFtqEntry_3;
  logic io_in_bits_isLastInFtqEntry_4;
  logic io_in_bits_isLastInFtqEntry_5;
  logic io_in_bits_isLastInFtqEntry_6;
  logic io_in_bits_isLastInFtqEntry_7;
  logic io_in_bits_isLastInFtqEntry_8;
  logic io_in_bits_isLastInFtqEntry_9;
  logic io_in_bits_isLastInFtqEntry_10;
  logic io_in_bits_isLastInFtqEntry_11;
  logic io_in_bits_isLastInFtqEntry_12;
  logic io_in_bits_isLastInFtqEntry_13;
  logic io_in_bits_isLastInFtqEntry_14;
  logic io_in_bits_isLastInFtqEntry_15;
  logic [49:0] io_in_bits_pc_0;
  logic [49:0] io_in_bits_pc_1;
  logic [49:0] io_in_bits_pc_2;
  logic [49:0] io_in_bits_pc_3;
  logic [49:0] io_in_bits_pc_4;
  logic [49:0] io_in_bits_pc_5;
  logic [49:0] io_in_bits_pc_6;
  logic [49:0] io_in_bits_pc_7;
  logic [49:0] io_in_bits_pc_8;
  logic [49:0] io_in_bits_pc_9;
  logic [49:0] io_in_bits_pc_10;
  logic [49:0] io_in_bits_pc_11;
  logic [49:0] io_in_bits_pc_12;
  logic [49:0] io_in_bits_pc_13;
  logic [49:0] io_in_bits_pc_14;
  logic [49:0] io_in_bits_pc_15;
  logic io_in_bits_ftqPtr_flag;
  logic [5:0] io_in_bits_ftqPtr_value;
  logic io_in_bits_topdown_info_reasons_0;
  logic io_in_bits_topdown_info_reasons_1;
  logic io_in_bits_topdown_info_reasons_2;
  logic io_in_bits_topdown_info_reasons_3;
  logic io_in_bits_topdown_info_reasons_4;
  logic io_in_bits_topdown_info_reasons_5;
  logic io_in_bits_topdown_info_reasons_6;
  logic io_in_bits_topdown_info_reasons_7;
  logic io_in_bits_topdown_info_reasons_8;
  logic io_in_bits_topdown_info_reasons_9;
  logic io_in_bits_topdown_info_reasons_10;
  logic io_in_bits_topdown_info_reasons_11;
  logic io_in_bits_topdown_info_reasons_12;
  logic io_in_bits_topdown_info_reasons_13;
  logic io_in_bits_topdown_info_reasons_14;
  logic io_in_bits_topdown_info_reasons_15;
  logic io_in_bits_topdown_info_reasons_16;
  logic io_in_bits_topdown_info_reasons_17;
  logic io_in_bits_topdown_info_reasons_18;
  logic io_in_bits_topdown_info_reasons_19;
  logic io_in_bits_topdown_info_reasons_20;
  logic io_in_bits_topdown_info_reasons_21;
  logic io_in_bits_topdown_info_reasons_22;
  logic io_in_bits_topdown_info_reasons_23;
  logic io_in_bits_topdown_info_reasons_24;
  logic io_in_bits_topdown_info_reasons_25;
  logic io_in_bits_topdown_info_reasons_26;
  logic io_in_bits_topdown_info_reasons_27;
  logic io_in_bits_topdown_info_reasons_28;
  logic io_in_bits_topdown_info_reasons_29;
  logic io_in_bits_topdown_info_reasons_30;
  logic io_in_bits_topdown_info_reasons_31;
  logic io_in_bits_topdown_info_reasons_32;
  logic io_in_bits_topdown_info_reasons_33;
  logic io_in_bits_topdown_info_reasons_34;
  logic io_in_bits_topdown_info_reasons_35;
  logic io_in_bits_topdown_info_reasons_36;
  logic io_in_bits_topdown_info_reasons_37;
  logic io_decodeCanAccept;
  logic io_stallReason_backReason_valid;
  logic [5:0] io_stallReason_backReason_bits;
  wire g_io_in_ready;
  wire i_io_in_ready;
  wire g_io_out_0_valid;
  wire i_io_out_0_valid;
  wire [31:0] g_io_out_0_bits_instr;
  wire [31:0] i_io_out_0_bits_instr;
  wire [49:0] g_io_out_0_bits_pc;
  wire [49:0] i_io_out_0_bits_pc;
  wire [9:0] g_io_out_0_bits_foldpc;
  wire [9:0] i_io_out_0_bits_foldpc;
  wire g_io_out_0_bits_exceptionVec_1;
  wire i_io_out_0_bits_exceptionVec_1;
  wire g_io_out_0_bits_exceptionVec_2;
  wire i_io_out_0_bits_exceptionVec_2;
  wire g_io_out_0_bits_exceptionVec_12;
  wire i_io_out_0_bits_exceptionVec_12;
  wire g_io_out_0_bits_exceptionVec_20;
  wire i_io_out_0_bits_exceptionVec_20;
  wire g_io_out_0_bits_backendException;
  wire i_io_out_0_bits_backendException;
  wire [3:0] g_io_out_0_bits_trigger;
  wire [3:0] i_io_out_0_bits_trigger;
  wire g_io_out_0_bits_pd_isRVC;
  wire i_io_out_0_bits_pd_isRVC;
  wire [1:0] g_io_out_0_bits_pd_brType;
  wire [1:0] i_io_out_0_bits_pd_brType;
  wire g_io_out_0_bits_pred_taken;
  wire i_io_out_0_bits_pred_taken;
  wire g_io_out_0_bits_crossPageIPFFix;
  wire i_io_out_0_bits_crossPageIPFFix;
  wire g_io_out_0_bits_ftqPtr_flag;
  wire i_io_out_0_bits_ftqPtr_flag;
  wire [5:0] g_io_out_0_bits_ftqPtr_value;
  wire [5:0] i_io_out_0_bits_ftqPtr_value;
  wire [3:0] g_io_out_0_bits_ftqOffset;
  wire [3:0] i_io_out_0_bits_ftqOffset;
  wire g_io_out_0_bits_isLastInFtqEntry;
  wire i_io_out_0_bits_isLastInFtqEntry;
  wire g_io_out_1_valid;
  wire i_io_out_1_valid;
  wire [31:0] g_io_out_1_bits_instr;
  wire [31:0] i_io_out_1_bits_instr;
  wire [49:0] g_io_out_1_bits_pc;
  wire [49:0] i_io_out_1_bits_pc;
  wire [9:0] g_io_out_1_bits_foldpc;
  wire [9:0] i_io_out_1_bits_foldpc;
  wire g_io_out_1_bits_exceptionVec_1;
  wire i_io_out_1_bits_exceptionVec_1;
  wire g_io_out_1_bits_exceptionVec_2;
  wire i_io_out_1_bits_exceptionVec_2;
  wire g_io_out_1_bits_exceptionVec_12;
  wire i_io_out_1_bits_exceptionVec_12;
  wire g_io_out_1_bits_exceptionVec_20;
  wire i_io_out_1_bits_exceptionVec_20;
  wire g_io_out_1_bits_backendException;
  wire i_io_out_1_bits_backendException;
  wire [3:0] g_io_out_1_bits_trigger;
  wire [3:0] i_io_out_1_bits_trigger;
  wire g_io_out_1_bits_pd_isRVC;
  wire i_io_out_1_bits_pd_isRVC;
  wire [1:0] g_io_out_1_bits_pd_brType;
  wire [1:0] i_io_out_1_bits_pd_brType;
  wire g_io_out_1_bits_pred_taken;
  wire i_io_out_1_bits_pred_taken;
  wire g_io_out_1_bits_crossPageIPFFix;
  wire i_io_out_1_bits_crossPageIPFFix;
  wire g_io_out_1_bits_ftqPtr_flag;
  wire i_io_out_1_bits_ftqPtr_flag;
  wire [5:0] g_io_out_1_bits_ftqPtr_value;
  wire [5:0] i_io_out_1_bits_ftqPtr_value;
  wire [3:0] g_io_out_1_bits_ftqOffset;
  wire [3:0] i_io_out_1_bits_ftqOffset;
  wire g_io_out_1_bits_isLastInFtqEntry;
  wire i_io_out_1_bits_isLastInFtqEntry;
  wire g_io_out_2_valid;
  wire i_io_out_2_valid;
  wire [31:0] g_io_out_2_bits_instr;
  wire [31:0] i_io_out_2_bits_instr;
  wire [49:0] g_io_out_2_bits_pc;
  wire [49:0] i_io_out_2_bits_pc;
  wire [9:0] g_io_out_2_bits_foldpc;
  wire [9:0] i_io_out_2_bits_foldpc;
  wire g_io_out_2_bits_exceptionVec_1;
  wire i_io_out_2_bits_exceptionVec_1;
  wire g_io_out_2_bits_exceptionVec_2;
  wire i_io_out_2_bits_exceptionVec_2;
  wire g_io_out_2_bits_exceptionVec_12;
  wire i_io_out_2_bits_exceptionVec_12;
  wire g_io_out_2_bits_exceptionVec_20;
  wire i_io_out_2_bits_exceptionVec_20;
  wire g_io_out_2_bits_backendException;
  wire i_io_out_2_bits_backendException;
  wire [3:0] g_io_out_2_bits_trigger;
  wire [3:0] i_io_out_2_bits_trigger;
  wire g_io_out_2_bits_pd_isRVC;
  wire i_io_out_2_bits_pd_isRVC;
  wire [1:0] g_io_out_2_bits_pd_brType;
  wire [1:0] i_io_out_2_bits_pd_brType;
  wire g_io_out_2_bits_pred_taken;
  wire i_io_out_2_bits_pred_taken;
  wire g_io_out_2_bits_crossPageIPFFix;
  wire i_io_out_2_bits_crossPageIPFFix;
  wire g_io_out_2_bits_ftqPtr_flag;
  wire i_io_out_2_bits_ftqPtr_flag;
  wire [5:0] g_io_out_2_bits_ftqPtr_value;
  wire [5:0] i_io_out_2_bits_ftqPtr_value;
  wire [3:0] g_io_out_2_bits_ftqOffset;
  wire [3:0] i_io_out_2_bits_ftqOffset;
  wire g_io_out_2_bits_isLastInFtqEntry;
  wire i_io_out_2_bits_isLastInFtqEntry;
  wire g_io_out_3_valid;
  wire i_io_out_3_valid;
  wire [31:0] g_io_out_3_bits_instr;
  wire [31:0] i_io_out_3_bits_instr;
  wire [49:0] g_io_out_3_bits_pc;
  wire [49:0] i_io_out_3_bits_pc;
  wire [9:0] g_io_out_3_bits_foldpc;
  wire [9:0] i_io_out_3_bits_foldpc;
  wire g_io_out_3_bits_exceptionVec_1;
  wire i_io_out_3_bits_exceptionVec_1;
  wire g_io_out_3_bits_exceptionVec_2;
  wire i_io_out_3_bits_exceptionVec_2;
  wire g_io_out_3_bits_exceptionVec_12;
  wire i_io_out_3_bits_exceptionVec_12;
  wire g_io_out_3_bits_exceptionVec_20;
  wire i_io_out_3_bits_exceptionVec_20;
  wire g_io_out_3_bits_backendException;
  wire i_io_out_3_bits_backendException;
  wire [3:0] g_io_out_3_bits_trigger;
  wire [3:0] i_io_out_3_bits_trigger;
  wire g_io_out_3_bits_pd_isRVC;
  wire i_io_out_3_bits_pd_isRVC;
  wire [1:0] g_io_out_3_bits_pd_brType;
  wire [1:0] i_io_out_3_bits_pd_brType;
  wire g_io_out_3_bits_pred_taken;
  wire i_io_out_3_bits_pred_taken;
  wire g_io_out_3_bits_crossPageIPFFix;
  wire i_io_out_3_bits_crossPageIPFFix;
  wire g_io_out_3_bits_ftqPtr_flag;
  wire i_io_out_3_bits_ftqPtr_flag;
  wire [5:0] g_io_out_3_bits_ftqPtr_value;
  wire [5:0] i_io_out_3_bits_ftqPtr_value;
  wire [3:0] g_io_out_3_bits_ftqOffset;
  wire [3:0] i_io_out_3_bits_ftqOffset;
  wire g_io_out_3_bits_isLastInFtqEntry;
  wire i_io_out_3_bits_isLastInFtqEntry;
  wire g_io_out_4_valid;
  wire i_io_out_4_valid;
  wire [31:0] g_io_out_4_bits_instr;
  wire [31:0] i_io_out_4_bits_instr;
  wire [49:0] g_io_out_4_bits_pc;
  wire [49:0] i_io_out_4_bits_pc;
  wire [9:0] g_io_out_4_bits_foldpc;
  wire [9:0] i_io_out_4_bits_foldpc;
  wire g_io_out_4_bits_exceptionVec_1;
  wire i_io_out_4_bits_exceptionVec_1;
  wire g_io_out_4_bits_exceptionVec_2;
  wire i_io_out_4_bits_exceptionVec_2;
  wire g_io_out_4_bits_exceptionVec_12;
  wire i_io_out_4_bits_exceptionVec_12;
  wire g_io_out_4_bits_exceptionVec_20;
  wire i_io_out_4_bits_exceptionVec_20;
  wire g_io_out_4_bits_backendException;
  wire i_io_out_4_bits_backendException;
  wire [3:0] g_io_out_4_bits_trigger;
  wire [3:0] i_io_out_4_bits_trigger;
  wire g_io_out_4_bits_pd_isRVC;
  wire i_io_out_4_bits_pd_isRVC;
  wire [1:0] g_io_out_4_bits_pd_brType;
  wire [1:0] i_io_out_4_bits_pd_brType;
  wire g_io_out_4_bits_pred_taken;
  wire i_io_out_4_bits_pred_taken;
  wire g_io_out_4_bits_crossPageIPFFix;
  wire i_io_out_4_bits_crossPageIPFFix;
  wire g_io_out_4_bits_ftqPtr_flag;
  wire i_io_out_4_bits_ftqPtr_flag;
  wire [5:0] g_io_out_4_bits_ftqPtr_value;
  wire [5:0] i_io_out_4_bits_ftqPtr_value;
  wire [3:0] g_io_out_4_bits_ftqOffset;
  wire [3:0] i_io_out_4_bits_ftqOffset;
  wire g_io_out_4_bits_isLastInFtqEntry;
  wire i_io_out_4_bits_isLastInFtqEntry;
  wire g_io_out_5_valid;
  wire i_io_out_5_valid;
  wire [31:0] g_io_out_5_bits_instr;
  wire [31:0] i_io_out_5_bits_instr;
  wire [49:0] g_io_out_5_bits_pc;
  wire [49:0] i_io_out_5_bits_pc;
  wire [9:0] g_io_out_5_bits_foldpc;
  wire [9:0] i_io_out_5_bits_foldpc;
  wire g_io_out_5_bits_exceptionVec_1;
  wire i_io_out_5_bits_exceptionVec_1;
  wire g_io_out_5_bits_exceptionVec_2;
  wire i_io_out_5_bits_exceptionVec_2;
  wire g_io_out_5_bits_exceptionVec_12;
  wire i_io_out_5_bits_exceptionVec_12;
  wire g_io_out_5_bits_exceptionVec_20;
  wire i_io_out_5_bits_exceptionVec_20;
  wire g_io_out_5_bits_backendException;
  wire i_io_out_5_bits_backendException;
  wire [3:0] g_io_out_5_bits_trigger;
  wire [3:0] i_io_out_5_bits_trigger;
  wire g_io_out_5_bits_pd_isRVC;
  wire i_io_out_5_bits_pd_isRVC;
  wire [1:0] g_io_out_5_bits_pd_brType;
  wire [1:0] i_io_out_5_bits_pd_brType;
  wire g_io_out_5_bits_pred_taken;
  wire i_io_out_5_bits_pred_taken;
  wire g_io_out_5_bits_crossPageIPFFix;
  wire i_io_out_5_bits_crossPageIPFFix;
  wire g_io_out_5_bits_ftqPtr_flag;
  wire i_io_out_5_bits_ftqPtr_flag;
  wire [5:0] g_io_out_5_bits_ftqPtr_value;
  wire [5:0] i_io_out_5_bits_ftqPtr_value;
  wire [3:0] g_io_out_5_bits_ftqOffset;
  wire [3:0] i_io_out_5_bits_ftqOffset;
  wire g_io_out_5_bits_isLastInFtqEntry;
  wire i_io_out_5_bits_isLastInFtqEntry;
  wire [5:0] g_io_stallReason_reason_0;
  wire [5:0] i_io_stallReason_reason_0;
  wire [5:0] g_io_stallReason_reason_1;
  wire [5:0] i_io_stallReason_reason_1;
  wire [5:0] g_io_stallReason_reason_2;
  wire [5:0] i_io_stallReason_reason_2;
  wire [5:0] g_io_stallReason_reason_3;
  wire [5:0] i_io_stallReason_reason_3;
  wire [5:0] g_io_stallReason_reason_4;
  wire [5:0] i_io_stallReason_reason_4;
  wire [5:0] g_io_stallReason_reason_5;
  wire [5:0] i_io_stallReason_reason_5;
  wire [5:0] g_io_perf_0_value;
  wire [5:0] i_io_perf_0_value;
  wire [5:0] g_io_perf_1_value;
  wire [5:0] i_io_perf_1_value;
  wire [5:0] g_io_perf_2_value;
  wire [5:0] i_io_perf_2_value;
  wire [5:0] g_io_perf_3_value;
  wire [5:0] i_io_perf_3_value;
  wire [5:0] g_io_perf_4_value;
  wire [5:0] i_io_perf_4_value;
  wire [5:0] g_io_perf_5_value;
  wire [5:0] i_io_perf_5_value;
  wire [5:0] g_io_perf_6_value;
  wire [5:0] i_io_perf_6_value;
  wire [5:0] g_io_perf_7_value;
  wire [5:0] i_io_perf_7_value;
  wire [5:0] g_io_perf_8_value;
  wire [5:0] i_io_perf_8_value;

  IBuffer    u_g (.clock(clk), .reset(rst), .io_flush(io_flush), .io_ControlRedirect(io_ControlRedirect), .io_ControlBTBMissBubble(io_ControlBTBMissBubble), .io_TAGEMissBubble(io_TAGEMissBubble), .io_SCMissBubble(io_SCMissBubble), .io_ITTAGEMissBubble(io_ITTAGEMissBubble), .io_RASMissBubble(io_RASMissBubble), .io_MemVioRedirect(io_MemVioRedirect), .io_in_valid(io_in_valid), .io_in_bits_instrs_0(io_in_bits_instrs_0), .io_in_bits_instrs_1(io_in_bits_instrs_1), .io_in_bits_instrs_2(io_in_bits_instrs_2), .io_in_bits_instrs_3(io_in_bits_instrs_3), .io_in_bits_instrs_4(io_in_bits_instrs_4), .io_in_bits_instrs_5(io_in_bits_instrs_5), .io_in_bits_instrs_6(io_in_bits_instrs_6), .io_in_bits_instrs_7(io_in_bits_instrs_7), .io_in_bits_instrs_8(io_in_bits_instrs_8), .io_in_bits_instrs_9(io_in_bits_instrs_9), .io_in_bits_instrs_10(io_in_bits_instrs_10), .io_in_bits_instrs_11(io_in_bits_instrs_11), .io_in_bits_instrs_12(io_in_bits_instrs_12), .io_in_bits_instrs_13(io_in_bits_instrs_13), .io_in_bits_instrs_14(io_in_bits_instrs_14), .io_in_bits_instrs_15(io_in_bits_instrs_15), .io_in_bits_valid(io_in_bits_valid), .io_in_bits_enqEnable(io_in_bits_enqEnable), .io_in_bits_pd_0_isRVC(io_in_bits_pd_0_isRVC), .io_in_bits_pd_0_brType(io_in_bits_pd_0_brType), .io_in_bits_pd_1_isRVC(io_in_bits_pd_1_isRVC), .io_in_bits_pd_1_brType(io_in_bits_pd_1_brType), .io_in_bits_pd_2_isRVC(io_in_bits_pd_2_isRVC), .io_in_bits_pd_2_brType(io_in_bits_pd_2_brType), .io_in_bits_pd_3_isRVC(io_in_bits_pd_3_isRVC), .io_in_bits_pd_3_brType(io_in_bits_pd_3_brType), .io_in_bits_pd_4_isRVC(io_in_bits_pd_4_isRVC), .io_in_bits_pd_4_brType(io_in_bits_pd_4_brType), .io_in_bits_pd_5_isRVC(io_in_bits_pd_5_isRVC), .io_in_bits_pd_5_brType(io_in_bits_pd_5_brType), .io_in_bits_pd_6_isRVC(io_in_bits_pd_6_isRVC), .io_in_bits_pd_6_brType(io_in_bits_pd_6_brType), .io_in_bits_pd_7_isRVC(io_in_bits_pd_7_isRVC), .io_in_bits_pd_7_brType(io_in_bits_pd_7_brType), .io_in_bits_pd_8_isRVC(io_in_bits_pd_8_isRVC), .io_in_bits_pd_8_brType(io_in_bits_pd_8_brType), .io_in_bits_pd_9_isRVC(io_in_bits_pd_9_isRVC), .io_in_bits_pd_9_brType(io_in_bits_pd_9_brType), .io_in_bits_pd_10_isRVC(io_in_bits_pd_10_isRVC), .io_in_bits_pd_10_brType(io_in_bits_pd_10_brType), .io_in_bits_pd_11_isRVC(io_in_bits_pd_11_isRVC), .io_in_bits_pd_11_brType(io_in_bits_pd_11_brType), .io_in_bits_pd_12_isRVC(io_in_bits_pd_12_isRVC), .io_in_bits_pd_12_brType(io_in_bits_pd_12_brType), .io_in_bits_pd_13_isRVC(io_in_bits_pd_13_isRVC), .io_in_bits_pd_13_brType(io_in_bits_pd_13_brType), .io_in_bits_pd_14_isRVC(io_in_bits_pd_14_isRVC), .io_in_bits_pd_14_brType(io_in_bits_pd_14_brType), .io_in_bits_pd_15_isRVC(io_in_bits_pd_15_isRVC), .io_in_bits_pd_15_brType(io_in_bits_pd_15_brType), .io_in_bits_foldpc_0(io_in_bits_foldpc_0), .io_in_bits_foldpc_1(io_in_bits_foldpc_1), .io_in_bits_foldpc_2(io_in_bits_foldpc_2), .io_in_bits_foldpc_3(io_in_bits_foldpc_3), .io_in_bits_foldpc_4(io_in_bits_foldpc_4), .io_in_bits_foldpc_5(io_in_bits_foldpc_5), .io_in_bits_foldpc_6(io_in_bits_foldpc_6), .io_in_bits_foldpc_7(io_in_bits_foldpc_7), .io_in_bits_foldpc_8(io_in_bits_foldpc_8), .io_in_bits_foldpc_9(io_in_bits_foldpc_9), .io_in_bits_foldpc_10(io_in_bits_foldpc_10), .io_in_bits_foldpc_11(io_in_bits_foldpc_11), .io_in_bits_foldpc_12(io_in_bits_foldpc_12), .io_in_bits_foldpc_13(io_in_bits_foldpc_13), .io_in_bits_foldpc_14(io_in_bits_foldpc_14), .io_in_bits_foldpc_15(io_in_bits_foldpc_15), .io_in_bits_ftqOffset_0_valid(io_in_bits_ftqOffset_0_valid), .io_in_bits_ftqOffset_1_valid(io_in_bits_ftqOffset_1_valid), .io_in_bits_ftqOffset_2_valid(io_in_bits_ftqOffset_2_valid), .io_in_bits_ftqOffset_3_valid(io_in_bits_ftqOffset_3_valid), .io_in_bits_ftqOffset_4_valid(io_in_bits_ftqOffset_4_valid), .io_in_bits_ftqOffset_5_valid(io_in_bits_ftqOffset_5_valid), .io_in_bits_ftqOffset_6_valid(io_in_bits_ftqOffset_6_valid), .io_in_bits_ftqOffset_7_valid(io_in_bits_ftqOffset_7_valid), .io_in_bits_ftqOffset_8_valid(io_in_bits_ftqOffset_8_valid), .io_in_bits_ftqOffset_9_valid(io_in_bits_ftqOffset_9_valid), .io_in_bits_ftqOffset_10_valid(io_in_bits_ftqOffset_10_valid), .io_in_bits_ftqOffset_11_valid(io_in_bits_ftqOffset_11_valid), .io_in_bits_ftqOffset_12_valid(io_in_bits_ftqOffset_12_valid), .io_in_bits_ftqOffset_13_valid(io_in_bits_ftqOffset_13_valid), .io_in_bits_ftqOffset_14_valid(io_in_bits_ftqOffset_14_valid), .io_in_bits_ftqOffset_15_valid(io_in_bits_ftqOffset_15_valid), .io_in_bits_backendException_0(io_in_bits_backendException_0), .io_in_bits_exceptionType_0(io_in_bits_exceptionType_0), .io_in_bits_exceptionType_1(io_in_bits_exceptionType_1), .io_in_bits_exceptionType_2(io_in_bits_exceptionType_2), .io_in_bits_exceptionType_3(io_in_bits_exceptionType_3), .io_in_bits_exceptionType_4(io_in_bits_exceptionType_4), .io_in_bits_exceptionType_5(io_in_bits_exceptionType_5), .io_in_bits_exceptionType_6(io_in_bits_exceptionType_6), .io_in_bits_exceptionType_7(io_in_bits_exceptionType_7), .io_in_bits_exceptionType_8(io_in_bits_exceptionType_8), .io_in_bits_exceptionType_9(io_in_bits_exceptionType_9), .io_in_bits_exceptionType_10(io_in_bits_exceptionType_10), .io_in_bits_exceptionType_11(io_in_bits_exceptionType_11), .io_in_bits_exceptionType_12(io_in_bits_exceptionType_12), .io_in_bits_exceptionType_13(io_in_bits_exceptionType_13), .io_in_bits_exceptionType_14(io_in_bits_exceptionType_14), .io_in_bits_exceptionType_15(io_in_bits_exceptionType_15), .io_in_bits_crossPageIPFFix_0(io_in_bits_crossPageIPFFix_0), .io_in_bits_crossPageIPFFix_1(io_in_bits_crossPageIPFFix_1), .io_in_bits_crossPageIPFFix_2(io_in_bits_crossPageIPFFix_2), .io_in_bits_crossPageIPFFix_3(io_in_bits_crossPageIPFFix_3), .io_in_bits_crossPageIPFFix_4(io_in_bits_crossPageIPFFix_4), .io_in_bits_crossPageIPFFix_5(io_in_bits_crossPageIPFFix_5), .io_in_bits_crossPageIPFFix_6(io_in_bits_crossPageIPFFix_6), .io_in_bits_crossPageIPFFix_7(io_in_bits_crossPageIPFFix_7), .io_in_bits_crossPageIPFFix_8(io_in_bits_crossPageIPFFix_8), .io_in_bits_crossPageIPFFix_9(io_in_bits_crossPageIPFFix_9), .io_in_bits_crossPageIPFFix_10(io_in_bits_crossPageIPFFix_10), .io_in_bits_crossPageIPFFix_11(io_in_bits_crossPageIPFFix_11), .io_in_bits_crossPageIPFFix_12(io_in_bits_crossPageIPFFix_12), .io_in_bits_crossPageIPFFix_13(io_in_bits_crossPageIPFFix_13), .io_in_bits_crossPageIPFFix_14(io_in_bits_crossPageIPFFix_14), .io_in_bits_crossPageIPFFix_15(io_in_bits_crossPageIPFFix_15), .io_in_bits_illegalInstr_0(io_in_bits_illegalInstr_0), .io_in_bits_illegalInstr_1(io_in_bits_illegalInstr_1), .io_in_bits_illegalInstr_2(io_in_bits_illegalInstr_2), .io_in_bits_illegalInstr_3(io_in_bits_illegalInstr_3), .io_in_bits_illegalInstr_4(io_in_bits_illegalInstr_4), .io_in_bits_illegalInstr_5(io_in_bits_illegalInstr_5), .io_in_bits_illegalInstr_6(io_in_bits_illegalInstr_6), .io_in_bits_illegalInstr_7(io_in_bits_illegalInstr_7), .io_in_bits_illegalInstr_8(io_in_bits_illegalInstr_8), .io_in_bits_illegalInstr_9(io_in_bits_illegalInstr_9), .io_in_bits_illegalInstr_10(io_in_bits_illegalInstr_10), .io_in_bits_illegalInstr_11(io_in_bits_illegalInstr_11), .io_in_bits_illegalInstr_12(io_in_bits_illegalInstr_12), .io_in_bits_illegalInstr_13(io_in_bits_illegalInstr_13), .io_in_bits_illegalInstr_14(io_in_bits_illegalInstr_14), .io_in_bits_illegalInstr_15(io_in_bits_illegalInstr_15), .io_in_bits_triggered_0(io_in_bits_triggered_0), .io_in_bits_triggered_1(io_in_bits_triggered_1), .io_in_bits_triggered_2(io_in_bits_triggered_2), .io_in_bits_triggered_3(io_in_bits_triggered_3), .io_in_bits_triggered_4(io_in_bits_triggered_4), .io_in_bits_triggered_5(io_in_bits_triggered_5), .io_in_bits_triggered_6(io_in_bits_triggered_6), .io_in_bits_triggered_7(io_in_bits_triggered_7), .io_in_bits_triggered_8(io_in_bits_triggered_8), .io_in_bits_triggered_9(io_in_bits_triggered_9), .io_in_bits_triggered_10(io_in_bits_triggered_10), .io_in_bits_triggered_11(io_in_bits_triggered_11), .io_in_bits_triggered_12(io_in_bits_triggered_12), .io_in_bits_triggered_13(io_in_bits_triggered_13), .io_in_bits_triggered_14(io_in_bits_triggered_14), .io_in_bits_triggered_15(io_in_bits_triggered_15), .io_in_bits_isLastInFtqEntry_0(io_in_bits_isLastInFtqEntry_0), .io_in_bits_isLastInFtqEntry_1(io_in_bits_isLastInFtqEntry_1), .io_in_bits_isLastInFtqEntry_2(io_in_bits_isLastInFtqEntry_2), .io_in_bits_isLastInFtqEntry_3(io_in_bits_isLastInFtqEntry_3), .io_in_bits_isLastInFtqEntry_4(io_in_bits_isLastInFtqEntry_4), .io_in_bits_isLastInFtqEntry_5(io_in_bits_isLastInFtqEntry_5), .io_in_bits_isLastInFtqEntry_6(io_in_bits_isLastInFtqEntry_6), .io_in_bits_isLastInFtqEntry_7(io_in_bits_isLastInFtqEntry_7), .io_in_bits_isLastInFtqEntry_8(io_in_bits_isLastInFtqEntry_8), .io_in_bits_isLastInFtqEntry_9(io_in_bits_isLastInFtqEntry_9), .io_in_bits_isLastInFtqEntry_10(io_in_bits_isLastInFtqEntry_10), .io_in_bits_isLastInFtqEntry_11(io_in_bits_isLastInFtqEntry_11), .io_in_bits_isLastInFtqEntry_12(io_in_bits_isLastInFtqEntry_12), .io_in_bits_isLastInFtqEntry_13(io_in_bits_isLastInFtqEntry_13), .io_in_bits_isLastInFtqEntry_14(io_in_bits_isLastInFtqEntry_14), .io_in_bits_isLastInFtqEntry_15(io_in_bits_isLastInFtqEntry_15), .io_in_bits_pc_0(io_in_bits_pc_0), .io_in_bits_pc_1(io_in_bits_pc_1), .io_in_bits_pc_2(io_in_bits_pc_2), .io_in_bits_pc_3(io_in_bits_pc_3), .io_in_bits_pc_4(io_in_bits_pc_4), .io_in_bits_pc_5(io_in_bits_pc_5), .io_in_bits_pc_6(io_in_bits_pc_6), .io_in_bits_pc_7(io_in_bits_pc_7), .io_in_bits_pc_8(io_in_bits_pc_8), .io_in_bits_pc_9(io_in_bits_pc_9), .io_in_bits_pc_10(io_in_bits_pc_10), .io_in_bits_pc_11(io_in_bits_pc_11), .io_in_bits_pc_12(io_in_bits_pc_12), .io_in_bits_pc_13(io_in_bits_pc_13), .io_in_bits_pc_14(io_in_bits_pc_14), .io_in_bits_pc_15(io_in_bits_pc_15), .io_in_bits_ftqPtr_flag(io_in_bits_ftqPtr_flag), .io_in_bits_ftqPtr_value(io_in_bits_ftqPtr_value), .io_in_bits_topdown_info_reasons_0(io_in_bits_topdown_info_reasons_0), .io_in_bits_topdown_info_reasons_1(io_in_bits_topdown_info_reasons_1), .io_in_bits_topdown_info_reasons_2(io_in_bits_topdown_info_reasons_2), .io_in_bits_topdown_info_reasons_3(io_in_bits_topdown_info_reasons_3), .io_in_bits_topdown_info_reasons_4(io_in_bits_topdown_info_reasons_4), .io_in_bits_topdown_info_reasons_5(io_in_bits_topdown_info_reasons_5), .io_in_bits_topdown_info_reasons_6(io_in_bits_topdown_info_reasons_6), .io_in_bits_topdown_info_reasons_7(io_in_bits_topdown_info_reasons_7), .io_in_bits_topdown_info_reasons_8(io_in_bits_topdown_info_reasons_8), .io_in_bits_topdown_info_reasons_9(io_in_bits_topdown_info_reasons_9), .io_in_bits_topdown_info_reasons_10(io_in_bits_topdown_info_reasons_10), .io_in_bits_topdown_info_reasons_11(io_in_bits_topdown_info_reasons_11), .io_in_bits_topdown_info_reasons_12(io_in_bits_topdown_info_reasons_12), .io_in_bits_topdown_info_reasons_13(io_in_bits_topdown_info_reasons_13), .io_in_bits_topdown_info_reasons_14(io_in_bits_topdown_info_reasons_14), .io_in_bits_topdown_info_reasons_15(io_in_bits_topdown_info_reasons_15), .io_in_bits_topdown_info_reasons_16(io_in_bits_topdown_info_reasons_16), .io_in_bits_topdown_info_reasons_17(io_in_bits_topdown_info_reasons_17), .io_in_bits_topdown_info_reasons_18(io_in_bits_topdown_info_reasons_18), .io_in_bits_topdown_info_reasons_19(io_in_bits_topdown_info_reasons_19), .io_in_bits_topdown_info_reasons_20(io_in_bits_topdown_info_reasons_20), .io_in_bits_topdown_info_reasons_21(io_in_bits_topdown_info_reasons_21), .io_in_bits_topdown_info_reasons_22(io_in_bits_topdown_info_reasons_22), .io_in_bits_topdown_info_reasons_23(io_in_bits_topdown_info_reasons_23), .io_in_bits_topdown_info_reasons_24(io_in_bits_topdown_info_reasons_24), .io_in_bits_topdown_info_reasons_25(io_in_bits_topdown_info_reasons_25), .io_in_bits_topdown_info_reasons_26(io_in_bits_topdown_info_reasons_26), .io_in_bits_topdown_info_reasons_27(io_in_bits_topdown_info_reasons_27), .io_in_bits_topdown_info_reasons_28(io_in_bits_topdown_info_reasons_28), .io_in_bits_topdown_info_reasons_29(io_in_bits_topdown_info_reasons_29), .io_in_bits_topdown_info_reasons_30(io_in_bits_topdown_info_reasons_30), .io_in_bits_topdown_info_reasons_31(io_in_bits_topdown_info_reasons_31), .io_in_bits_topdown_info_reasons_32(io_in_bits_topdown_info_reasons_32), .io_in_bits_topdown_info_reasons_33(io_in_bits_topdown_info_reasons_33), .io_in_bits_topdown_info_reasons_34(io_in_bits_topdown_info_reasons_34), .io_in_bits_topdown_info_reasons_35(io_in_bits_topdown_info_reasons_35), .io_in_bits_topdown_info_reasons_36(io_in_bits_topdown_info_reasons_36), .io_in_bits_topdown_info_reasons_37(io_in_bits_topdown_info_reasons_37), .io_decodeCanAccept(io_decodeCanAccept), .io_stallReason_backReason_valid(io_stallReason_backReason_valid), .io_stallReason_backReason_bits(io_stallReason_backReason_bits), .io_in_ready(g_io_in_ready), .io_out_0_valid(g_io_out_0_valid), .io_out_0_bits_instr(g_io_out_0_bits_instr), .io_out_0_bits_pc(g_io_out_0_bits_pc), .io_out_0_bits_foldpc(g_io_out_0_bits_foldpc), .io_out_0_bits_exceptionVec_1(g_io_out_0_bits_exceptionVec_1), .io_out_0_bits_exceptionVec_2(g_io_out_0_bits_exceptionVec_2), .io_out_0_bits_exceptionVec_12(g_io_out_0_bits_exceptionVec_12), .io_out_0_bits_exceptionVec_20(g_io_out_0_bits_exceptionVec_20), .io_out_0_bits_backendException(g_io_out_0_bits_backendException), .io_out_0_bits_trigger(g_io_out_0_bits_trigger), .io_out_0_bits_pd_isRVC(g_io_out_0_bits_pd_isRVC), .io_out_0_bits_pd_brType(g_io_out_0_bits_pd_brType), .io_out_0_bits_pred_taken(g_io_out_0_bits_pred_taken), .io_out_0_bits_crossPageIPFFix(g_io_out_0_bits_crossPageIPFFix), .io_out_0_bits_ftqPtr_flag(g_io_out_0_bits_ftqPtr_flag), .io_out_0_bits_ftqPtr_value(g_io_out_0_bits_ftqPtr_value), .io_out_0_bits_ftqOffset(g_io_out_0_bits_ftqOffset), .io_out_0_bits_isLastInFtqEntry(g_io_out_0_bits_isLastInFtqEntry), .io_out_1_valid(g_io_out_1_valid), .io_out_1_bits_instr(g_io_out_1_bits_instr), .io_out_1_bits_pc(g_io_out_1_bits_pc), .io_out_1_bits_foldpc(g_io_out_1_bits_foldpc), .io_out_1_bits_exceptionVec_1(g_io_out_1_bits_exceptionVec_1), .io_out_1_bits_exceptionVec_2(g_io_out_1_bits_exceptionVec_2), .io_out_1_bits_exceptionVec_12(g_io_out_1_bits_exceptionVec_12), .io_out_1_bits_exceptionVec_20(g_io_out_1_bits_exceptionVec_20), .io_out_1_bits_backendException(g_io_out_1_bits_backendException), .io_out_1_bits_trigger(g_io_out_1_bits_trigger), .io_out_1_bits_pd_isRVC(g_io_out_1_bits_pd_isRVC), .io_out_1_bits_pd_brType(g_io_out_1_bits_pd_brType), .io_out_1_bits_pred_taken(g_io_out_1_bits_pred_taken), .io_out_1_bits_crossPageIPFFix(g_io_out_1_bits_crossPageIPFFix), .io_out_1_bits_ftqPtr_flag(g_io_out_1_bits_ftqPtr_flag), .io_out_1_bits_ftqPtr_value(g_io_out_1_bits_ftqPtr_value), .io_out_1_bits_ftqOffset(g_io_out_1_bits_ftqOffset), .io_out_1_bits_isLastInFtqEntry(g_io_out_1_bits_isLastInFtqEntry), .io_out_2_valid(g_io_out_2_valid), .io_out_2_bits_instr(g_io_out_2_bits_instr), .io_out_2_bits_pc(g_io_out_2_bits_pc), .io_out_2_bits_foldpc(g_io_out_2_bits_foldpc), .io_out_2_bits_exceptionVec_1(g_io_out_2_bits_exceptionVec_1), .io_out_2_bits_exceptionVec_2(g_io_out_2_bits_exceptionVec_2), .io_out_2_bits_exceptionVec_12(g_io_out_2_bits_exceptionVec_12), .io_out_2_bits_exceptionVec_20(g_io_out_2_bits_exceptionVec_20), .io_out_2_bits_backendException(g_io_out_2_bits_backendException), .io_out_2_bits_trigger(g_io_out_2_bits_trigger), .io_out_2_bits_pd_isRVC(g_io_out_2_bits_pd_isRVC), .io_out_2_bits_pd_brType(g_io_out_2_bits_pd_brType), .io_out_2_bits_pred_taken(g_io_out_2_bits_pred_taken), .io_out_2_bits_crossPageIPFFix(g_io_out_2_bits_crossPageIPFFix), .io_out_2_bits_ftqPtr_flag(g_io_out_2_bits_ftqPtr_flag), .io_out_2_bits_ftqPtr_value(g_io_out_2_bits_ftqPtr_value), .io_out_2_bits_ftqOffset(g_io_out_2_bits_ftqOffset), .io_out_2_bits_isLastInFtqEntry(g_io_out_2_bits_isLastInFtqEntry), .io_out_3_valid(g_io_out_3_valid), .io_out_3_bits_instr(g_io_out_3_bits_instr), .io_out_3_bits_pc(g_io_out_3_bits_pc), .io_out_3_bits_foldpc(g_io_out_3_bits_foldpc), .io_out_3_bits_exceptionVec_1(g_io_out_3_bits_exceptionVec_1), .io_out_3_bits_exceptionVec_2(g_io_out_3_bits_exceptionVec_2), .io_out_3_bits_exceptionVec_12(g_io_out_3_bits_exceptionVec_12), .io_out_3_bits_exceptionVec_20(g_io_out_3_bits_exceptionVec_20), .io_out_3_bits_backendException(g_io_out_3_bits_backendException), .io_out_3_bits_trigger(g_io_out_3_bits_trigger), .io_out_3_bits_pd_isRVC(g_io_out_3_bits_pd_isRVC), .io_out_3_bits_pd_brType(g_io_out_3_bits_pd_brType), .io_out_3_bits_pred_taken(g_io_out_3_bits_pred_taken), .io_out_3_bits_crossPageIPFFix(g_io_out_3_bits_crossPageIPFFix), .io_out_3_bits_ftqPtr_flag(g_io_out_3_bits_ftqPtr_flag), .io_out_3_bits_ftqPtr_value(g_io_out_3_bits_ftqPtr_value), .io_out_3_bits_ftqOffset(g_io_out_3_bits_ftqOffset), .io_out_3_bits_isLastInFtqEntry(g_io_out_3_bits_isLastInFtqEntry), .io_out_4_valid(g_io_out_4_valid), .io_out_4_bits_instr(g_io_out_4_bits_instr), .io_out_4_bits_pc(g_io_out_4_bits_pc), .io_out_4_bits_foldpc(g_io_out_4_bits_foldpc), .io_out_4_bits_exceptionVec_1(g_io_out_4_bits_exceptionVec_1), .io_out_4_bits_exceptionVec_2(g_io_out_4_bits_exceptionVec_2), .io_out_4_bits_exceptionVec_12(g_io_out_4_bits_exceptionVec_12), .io_out_4_bits_exceptionVec_20(g_io_out_4_bits_exceptionVec_20), .io_out_4_bits_backendException(g_io_out_4_bits_backendException), .io_out_4_bits_trigger(g_io_out_4_bits_trigger), .io_out_4_bits_pd_isRVC(g_io_out_4_bits_pd_isRVC), .io_out_4_bits_pd_brType(g_io_out_4_bits_pd_brType), .io_out_4_bits_pred_taken(g_io_out_4_bits_pred_taken), .io_out_4_bits_crossPageIPFFix(g_io_out_4_bits_crossPageIPFFix), .io_out_4_bits_ftqPtr_flag(g_io_out_4_bits_ftqPtr_flag), .io_out_4_bits_ftqPtr_value(g_io_out_4_bits_ftqPtr_value), .io_out_4_bits_ftqOffset(g_io_out_4_bits_ftqOffset), .io_out_4_bits_isLastInFtqEntry(g_io_out_4_bits_isLastInFtqEntry), .io_out_5_valid(g_io_out_5_valid), .io_out_5_bits_instr(g_io_out_5_bits_instr), .io_out_5_bits_pc(g_io_out_5_bits_pc), .io_out_5_bits_foldpc(g_io_out_5_bits_foldpc), .io_out_5_bits_exceptionVec_1(g_io_out_5_bits_exceptionVec_1), .io_out_5_bits_exceptionVec_2(g_io_out_5_bits_exceptionVec_2), .io_out_5_bits_exceptionVec_12(g_io_out_5_bits_exceptionVec_12), .io_out_5_bits_exceptionVec_20(g_io_out_5_bits_exceptionVec_20), .io_out_5_bits_backendException(g_io_out_5_bits_backendException), .io_out_5_bits_trigger(g_io_out_5_bits_trigger), .io_out_5_bits_pd_isRVC(g_io_out_5_bits_pd_isRVC), .io_out_5_bits_pd_brType(g_io_out_5_bits_pd_brType), .io_out_5_bits_pred_taken(g_io_out_5_bits_pred_taken), .io_out_5_bits_crossPageIPFFix(g_io_out_5_bits_crossPageIPFFix), .io_out_5_bits_ftqPtr_flag(g_io_out_5_bits_ftqPtr_flag), .io_out_5_bits_ftqPtr_value(g_io_out_5_bits_ftqPtr_value), .io_out_5_bits_ftqOffset(g_io_out_5_bits_ftqOffset), .io_out_5_bits_isLastInFtqEntry(g_io_out_5_bits_isLastInFtqEntry), .io_stallReason_reason_0(g_io_stallReason_reason_0), .io_stallReason_reason_1(g_io_stallReason_reason_1), .io_stallReason_reason_2(g_io_stallReason_reason_2), .io_stallReason_reason_3(g_io_stallReason_reason_3), .io_stallReason_reason_4(g_io_stallReason_reason_4), .io_stallReason_reason_5(g_io_stallReason_reason_5), .io_perf_0_value(g_io_perf_0_value), .io_perf_1_value(g_io_perf_1_value), .io_perf_2_value(g_io_perf_2_value), .io_perf_3_value(g_io_perf_3_value), .io_perf_4_value(g_io_perf_4_value), .io_perf_5_value(g_io_perf_5_value), .io_perf_6_value(g_io_perf_6_value), .io_perf_7_value(g_io_perf_7_value), .io_perf_8_value(g_io_perf_8_value));
  IBuffer_xs u_i (.clock(clk), .reset(rst), .io_flush(io_flush), .io_ControlRedirect(io_ControlRedirect), .io_ControlBTBMissBubble(io_ControlBTBMissBubble), .io_TAGEMissBubble(io_TAGEMissBubble), .io_SCMissBubble(io_SCMissBubble), .io_ITTAGEMissBubble(io_ITTAGEMissBubble), .io_RASMissBubble(io_RASMissBubble), .io_MemVioRedirect(io_MemVioRedirect), .io_in_valid(io_in_valid), .io_in_bits_instrs_0(io_in_bits_instrs_0), .io_in_bits_instrs_1(io_in_bits_instrs_1), .io_in_bits_instrs_2(io_in_bits_instrs_2), .io_in_bits_instrs_3(io_in_bits_instrs_3), .io_in_bits_instrs_4(io_in_bits_instrs_4), .io_in_bits_instrs_5(io_in_bits_instrs_5), .io_in_bits_instrs_6(io_in_bits_instrs_6), .io_in_bits_instrs_7(io_in_bits_instrs_7), .io_in_bits_instrs_8(io_in_bits_instrs_8), .io_in_bits_instrs_9(io_in_bits_instrs_9), .io_in_bits_instrs_10(io_in_bits_instrs_10), .io_in_bits_instrs_11(io_in_bits_instrs_11), .io_in_bits_instrs_12(io_in_bits_instrs_12), .io_in_bits_instrs_13(io_in_bits_instrs_13), .io_in_bits_instrs_14(io_in_bits_instrs_14), .io_in_bits_instrs_15(io_in_bits_instrs_15), .io_in_bits_valid(io_in_bits_valid), .io_in_bits_enqEnable(io_in_bits_enqEnable), .io_in_bits_pd_0_isRVC(io_in_bits_pd_0_isRVC), .io_in_bits_pd_0_brType(io_in_bits_pd_0_brType), .io_in_bits_pd_1_isRVC(io_in_bits_pd_1_isRVC), .io_in_bits_pd_1_brType(io_in_bits_pd_1_brType), .io_in_bits_pd_2_isRVC(io_in_bits_pd_2_isRVC), .io_in_bits_pd_2_brType(io_in_bits_pd_2_brType), .io_in_bits_pd_3_isRVC(io_in_bits_pd_3_isRVC), .io_in_bits_pd_3_brType(io_in_bits_pd_3_brType), .io_in_bits_pd_4_isRVC(io_in_bits_pd_4_isRVC), .io_in_bits_pd_4_brType(io_in_bits_pd_4_brType), .io_in_bits_pd_5_isRVC(io_in_bits_pd_5_isRVC), .io_in_bits_pd_5_brType(io_in_bits_pd_5_brType), .io_in_bits_pd_6_isRVC(io_in_bits_pd_6_isRVC), .io_in_bits_pd_6_brType(io_in_bits_pd_6_brType), .io_in_bits_pd_7_isRVC(io_in_bits_pd_7_isRVC), .io_in_bits_pd_7_brType(io_in_bits_pd_7_brType), .io_in_bits_pd_8_isRVC(io_in_bits_pd_8_isRVC), .io_in_bits_pd_8_brType(io_in_bits_pd_8_brType), .io_in_bits_pd_9_isRVC(io_in_bits_pd_9_isRVC), .io_in_bits_pd_9_brType(io_in_bits_pd_9_brType), .io_in_bits_pd_10_isRVC(io_in_bits_pd_10_isRVC), .io_in_bits_pd_10_brType(io_in_bits_pd_10_brType), .io_in_bits_pd_11_isRVC(io_in_bits_pd_11_isRVC), .io_in_bits_pd_11_brType(io_in_bits_pd_11_brType), .io_in_bits_pd_12_isRVC(io_in_bits_pd_12_isRVC), .io_in_bits_pd_12_brType(io_in_bits_pd_12_brType), .io_in_bits_pd_13_isRVC(io_in_bits_pd_13_isRVC), .io_in_bits_pd_13_brType(io_in_bits_pd_13_brType), .io_in_bits_pd_14_isRVC(io_in_bits_pd_14_isRVC), .io_in_bits_pd_14_brType(io_in_bits_pd_14_brType), .io_in_bits_pd_15_isRVC(io_in_bits_pd_15_isRVC), .io_in_bits_pd_15_brType(io_in_bits_pd_15_brType), .io_in_bits_foldpc_0(io_in_bits_foldpc_0), .io_in_bits_foldpc_1(io_in_bits_foldpc_1), .io_in_bits_foldpc_2(io_in_bits_foldpc_2), .io_in_bits_foldpc_3(io_in_bits_foldpc_3), .io_in_bits_foldpc_4(io_in_bits_foldpc_4), .io_in_bits_foldpc_5(io_in_bits_foldpc_5), .io_in_bits_foldpc_6(io_in_bits_foldpc_6), .io_in_bits_foldpc_7(io_in_bits_foldpc_7), .io_in_bits_foldpc_8(io_in_bits_foldpc_8), .io_in_bits_foldpc_9(io_in_bits_foldpc_9), .io_in_bits_foldpc_10(io_in_bits_foldpc_10), .io_in_bits_foldpc_11(io_in_bits_foldpc_11), .io_in_bits_foldpc_12(io_in_bits_foldpc_12), .io_in_bits_foldpc_13(io_in_bits_foldpc_13), .io_in_bits_foldpc_14(io_in_bits_foldpc_14), .io_in_bits_foldpc_15(io_in_bits_foldpc_15), .io_in_bits_ftqOffset_0_valid(io_in_bits_ftqOffset_0_valid), .io_in_bits_ftqOffset_1_valid(io_in_bits_ftqOffset_1_valid), .io_in_bits_ftqOffset_2_valid(io_in_bits_ftqOffset_2_valid), .io_in_bits_ftqOffset_3_valid(io_in_bits_ftqOffset_3_valid), .io_in_bits_ftqOffset_4_valid(io_in_bits_ftqOffset_4_valid), .io_in_bits_ftqOffset_5_valid(io_in_bits_ftqOffset_5_valid), .io_in_bits_ftqOffset_6_valid(io_in_bits_ftqOffset_6_valid), .io_in_bits_ftqOffset_7_valid(io_in_bits_ftqOffset_7_valid), .io_in_bits_ftqOffset_8_valid(io_in_bits_ftqOffset_8_valid), .io_in_bits_ftqOffset_9_valid(io_in_bits_ftqOffset_9_valid), .io_in_bits_ftqOffset_10_valid(io_in_bits_ftqOffset_10_valid), .io_in_bits_ftqOffset_11_valid(io_in_bits_ftqOffset_11_valid), .io_in_bits_ftqOffset_12_valid(io_in_bits_ftqOffset_12_valid), .io_in_bits_ftqOffset_13_valid(io_in_bits_ftqOffset_13_valid), .io_in_bits_ftqOffset_14_valid(io_in_bits_ftqOffset_14_valid), .io_in_bits_ftqOffset_15_valid(io_in_bits_ftqOffset_15_valid), .io_in_bits_backendException_0(io_in_bits_backendException_0), .io_in_bits_exceptionType_0(io_in_bits_exceptionType_0), .io_in_bits_exceptionType_1(io_in_bits_exceptionType_1), .io_in_bits_exceptionType_2(io_in_bits_exceptionType_2), .io_in_bits_exceptionType_3(io_in_bits_exceptionType_3), .io_in_bits_exceptionType_4(io_in_bits_exceptionType_4), .io_in_bits_exceptionType_5(io_in_bits_exceptionType_5), .io_in_bits_exceptionType_6(io_in_bits_exceptionType_6), .io_in_bits_exceptionType_7(io_in_bits_exceptionType_7), .io_in_bits_exceptionType_8(io_in_bits_exceptionType_8), .io_in_bits_exceptionType_9(io_in_bits_exceptionType_9), .io_in_bits_exceptionType_10(io_in_bits_exceptionType_10), .io_in_bits_exceptionType_11(io_in_bits_exceptionType_11), .io_in_bits_exceptionType_12(io_in_bits_exceptionType_12), .io_in_bits_exceptionType_13(io_in_bits_exceptionType_13), .io_in_bits_exceptionType_14(io_in_bits_exceptionType_14), .io_in_bits_exceptionType_15(io_in_bits_exceptionType_15), .io_in_bits_crossPageIPFFix_0(io_in_bits_crossPageIPFFix_0), .io_in_bits_crossPageIPFFix_1(io_in_bits_crossPageIPFFix_1), .io_in_bits_crossPageIPFFix_2(io_in_bits_crossPageIPFFix_2), .io_in_bits_crossPageIPFFix_3(io_in_bits_crossPageIPFFix_3), .io_in_bits_crossPageIPFFix_4(io_in_bits_crossPageIPFFix_4), .io_in_bits_crossPageIPFFix_5(io_in_bits_crossPageIPFFix_5), .io_in_bits_crossPageIPFFix_6(io_in_bits_crossPageIPFFix_6), .io_in_bits_crossPageIPFFix_7(io_in_bits_crossPageIPFFix_7), .io_in_bits_crossPageIPFFix_8(io_in_bits_crossPageIPFFix_8), .io_in_bits_crossPageIPFFix_9(io_in_bits_crossPageIPFFix_9), .io_in_bits_crossPageIPFFix_10(io_in_bits_crossPageIPFFix_10), .io_in_bits_crossPageIPFFix_11(io_in_bits_crossPageIPFFix_11), .io_in_bits_crossPageIPFFix_12(io_in_bits_crossPageIPFFix_12), .io_in_bits_crossPageIPFFix_13(io_in_bits_crossPageIPFFix_13), .io_in_bits_crossPageIPFFix_14(io_in_bits_crossPageIPFFix_14), .io_in_bits_crossPageIPFFix_15(io_in_bits_crossPageIPFFix_15), .io_in_bits_illegalInstr_0(io_in_bits_illegalInstr_0), .io_in_bits_illegalInstr_1(io_in_bits_illegalInstr_1), .io_in_bits_illegalInstr_2(io_in_bits_illegalInstr_2), .io_in_bits_illegalInstr_3(io_in_bits_illegalInstr_3), .io_in_bits_illegalInstr_4(io_in_bits_illegalInstr_4), .io_in_bits_illegalInstr_5(io_in_bits_illegalInstr_5), .io_in_bits_illegalInstr_6(io_in_bits_illegalInstr_6), .io_in_bits_illegalInstr_7(io_in_bits_illegalInstr_7), .io_in_bits_illegalInstr_8(io_in_bits_illegalInstr_8), .io_in_bits_illegalInstr_9(io_in_bits_illegalInstr_9), .io_in_bits_illegalInstr_10(io_in_bits_illegalInstr_10), .io_in_bits_illegalInstr_11(io_in_bits_illegalInstr_11), .io_in_bits_illegalInstr_12(io_in_bits_illegalInstr_12), .io_in_bits_illegalInstr_13(io_in_bits_illegalInstr_13), .io_in_bits_illegalInstr_14(io_in_bits_illegalInstr_14), .io_in_bits_illegalInstr_15(io_in_bits_illegalInstr_15), .io_in_bits_triggered_0(io_in_bits_triggered_0), .io_in_bits_triggered_1(io_in_bits_triggered_1), .io_in_bits_triggered_2(io_in_bits_triggered_2), .io_in_bits_triggered_3(io_in_bits_triggered_3), .io_in_bits_triggered_4(io_in_bits_triggered_4), .io_in_bits_triggered_5(io_in_bits_triggered_5), .io_in_bits_triggered_6(io_in_bits_triggered_6), .io_in_bits_triggered_7(io_in_bits_triggered_7), .io_in_bits_triggered_8(io_in_bits_triggered_8), .io_in_bits_triggered_9(io_in_bits_triggered_9), .io_in_bits_triggered_10(io_in_bits_triggered_10), .io_in_bits_triggered_11(io_in_bits_triggered_11), .io_in_bits_triggered_12(io_in_bits_triggered_12), .io_in_bits_triggered_13(io_in_bits_triggered_13), .io_in_bits_triggered_14(io_in_bits_triggered_14), .io_in_bits_triggered_15(io_in_bits_triggered_15), .io_in_bits_isLastInFtqEntry_0(io_in_bits_isLastInFtqEntry_0), .io_in_bits_isLastInFtqEntry_1(io_in_bits_isLastInFtqEntry_1), .io_in_bits_isLastInFtqEntry_2(io_in_bits_isLastInFtqEntry_2), .io_in_bits_isLastInFtqEntry_3(io_in_bits_isLastInFtqEntry_3), .io_in_bits_isLastInFtqEntry_4(io_in_bits_isLastInFtqEntry_4), .io_in_bits_isLastInFtqEntry_5(io_in_bits_isLastInFtqEntry_5), .io_in_bits_isLastInFtqEntry_6(io_in_bits_isLastInFtqEntry_6), .io_in_bits_isLastInFtqEntry_7(io_in_bits_isLastInFtqEntry_7), .io_in_bits_isLastInFtqEntry_8(io_in_bits_isLastInFtqEntry_8), .io_in_bits_isLastInFtqEntry_9(io_in_bits_isLastInFtqEntry_9), .io_in_bits_isLastInFtqEntry_10(io_in_bits_isLastInFtqEntry_10), .io_in_bits_isLastInFtqEntry_11(io_in_bits_isLastInFtqEntry_11), .io_in_bits_isLastInFtqEntry_12(io_in_bits_isLastInFtqEntry_12), .io_in_bits_isLastInFtqEntry_13(io_in_bits_isLastInFtqEntry_13), .io_in_bits_isLastInFtqEntry_14(io_in_bits_isLastInFtqEntry_14), .io_in_bits_isLastInFtqEntry_15(io_in_bits_isLastInFtqEntry_15), .io_in_bits_pc_0(io_in_bits_pc_0), .io_in_bits_pc_1(io_in_bits_pc_1), .io_in_bits_pc_2(io_in_bits_pc_2), .io_in_bits_pc_3(io_in_bits_pc_3), .io_in_bits_pc_4(io_in_bits_pc_4), .io_in_bits_pc_5(io_in_bits_pc_5), .io_in_bits_pc_6(io_in_bits_pc_6), .io_in_bits_pc_7(io_in_bits_pc_7), .io_in_bits_pc_8(io_in_bits_pc_8), .io_in_bits_pc_9(io_in_bits_pc_9), .io_in_bits_pc_10(io_in_bits_pc_10), .io_in_bits_pc_11(io_in_bits_pc_11), .io_in_bits_pc_12(io_in_bits_pc_12), .io_in_bits_pc_13(io_in_bits_pc_13), .io_in_bits_pc_14(io_in_bits_pc_14), .io_in_bits_pc_15(io_in_bits_pc_15), .io_in_bits_ftqPtr_flag(io_in_bits_ftqPtr_flag), .io_in_bits_ftqPtr_value(io_in_bits_ftqPtr_value), .io_in_bits_topdown_info_reasons_0(io_in_bits_topdown_info_reasons_0), .io_in_bits_topdown_info_reasons_1(io_in_bits_topdown_info_reasons_1), .io_in_bits_topdown_info_reasons_2(io_in_bits_topdown_info_reasons_2), .io_in_bits_topdown_info_reasons_3(io_in_bits_topdown_info_reasons_3), .io_in_bits_topdown_info_reasons_4(io_in_bits_topdown_info_reasons_4), .io_in_bits_topdown_info_reasons_5(io_in_bits_topdown_info_reasons_5), .io_in_bits_topdown_info_reasons_6(io_in_bits_topdown_info_reasons_6), .io_in_bits_topdown_info_reasons_7(io_in_bits_topdown_info_reasons_7), .io_in_bits_topdown_info_reasons_8(io_in_bits_topdown_info_reasons_8), .io_in_bits_topdown_info_reasons_9(io_in_bits_topdown_info_reasons_9), .io_in_bits_topdown_info_reasons_10(io_in_bits_topdown_info_reasons_10), .io_in_bits_topdown_info_reasons_11(io_in_bits_topdown_info_reasons_11), .io_in_bits_topdown_info_reasons_12(io_in_bits_topdown_info_reasons_12), .io_in_bits_topdown_info_reasons_13(io_in_bits_topdown_info_reasons_13), .io_in_bits_topdown_info_reasons_14(io_in_bits_topdown_info_reasons_14), .io_in_bits_topdown_info_reasons_15(io_in_bits_topdown_info_reasons_15), .io_in_bits_topdown_info_reasons_16(io_in_bits_topdown_info_reasons_16), .io_in_bits_topdown_info_reasons_17(io_in_bits_topdown_info_reasons_17), .io_in_bits_topdown_info_reasons_18(io_in_bits_topdown_info_reasons_18), .io_in_bits_topdown_info_reasons_19(io_in_bits_topdown_info_reasons_19), .io_in_bits_topdown_info_reasons_20(io_in_bits_topdown_info_reasons_20), .io_in_bits_topdown_info_reasons_21(io_in_bits_topdown_info_reasons_21), .io_in_bits_topdown_info_reasons_22(io_in_bits_topdown_info_reasons_22), .io_in_bits_topdown_info_reasons_23(io_in_bits_topdown_info_reasons_23), .io_in_bits_topdown_info_reasons_24(io_in_bits_topdown_info_reasons_24), .io_in_bits_topdown_info_reasons_25(io_in_bits_topdown_info_reasons_25), .io_in_bits_topdown_info_reasons_26(io_in_bits_topdown_info_reasons_26), .io_in_bits_topdown_info_reasons_27(io_in_bits_topdown_info_reasons_27), .io_in_bits_topdown_info_reasons_28(io_in_bits_topdown_info_reasons_28), .io_in_bits_topdown_info_reasons_29(io_in_bits_topdown_info_reasons_29), .io_in_bits_topdown_info_reasons_30(io_in_bits_topdown_info_reasons_30), .io_in_bits_topdown_info_reasons_31(io_in_bits_topdown_info_reasons_31), .io_in_bits_topdown_info_reasons_32(io_in_bits_topdown_info_reasons_32), .io_in_bits_topdown_info_reasons_33(io_in_bits_topdown_info_reasons_33), .io_in_bits_topdown_info_reasons_34(io_in_bits_topdown_info_reasons_34), .io_in_bits_topdown_info_reasons_35(io_in_bits_topdown_info_reasons_35), .io_in_bits_topdown_info_reasons_36(io_in_bits_topdown_info_reasons_36), .io_in_bits_topdown_info_reasons_37(io_in_bits_topdown_info_reasons_37), .io_decodeCanAccept(io_decodeCanAccept), .io_stallReason_backReason_valid(io_stallReason_backReason_valid), .io_stallReason_backReason_bits(io_stallReason_backReason_bits), .io_in_ready(i_io_in_ready), .io_out_0_valid(i_io_out_0_valid), .io_out_0_bits_instr(i_io_out_0_bits_instr), .io_out_0_bits_pc(i_io_out_0_bits_pc), .io_out_0_bits_foldpc(i_io_out_0_bits_foldpc), .io_out_0_bits_exceptionVec_1(i_io_out_0_bits_exceptionVec_1), .io_out_0_bits_exceptionVec_2(i_io_out_0_bits_exceptionVec_2), .io_out_0_bits_exceptionVec_12(i_io_out_0_bits_exceptionVec_12), .io_out_0_bits_exceptionVec_20(i_io_out_0_bits_exceptionVec_20), .io_out_0_bits_backendException(i_io_out_0_bits_backendException), .io_out_0_bits_trigger(i_io_out_0_bits_trigger), .io_out_0_bits_pd_isRVC(i_io_out_0_bits_pd_isRVC), .io_out_0_bits_pd_brType(i_io_out_0_bits_pd_brType), .io_out_0_bits_pred_taken(i_io_out_0_bits_pred_taken), .io_out_0_bits_crossPageIPFFix(i_io_out_0_bits_crossPageIPFFix), .io_out_0_bits_ftqPtr_flag(i_io_out_0_bits_ftqPtr_flag), .io_out_0_bits_ftqPtr_value(i_io_out_0_bits_ftqPtr_value), .io_out_0_bits_ftqOffset(i_io_out_0_bits_ftqOffset), .io_out_0_bits_isLastInFtqEntry(i_io_out_0_bits_isLastInFtqEntry), .io_out_1_valid(i_io_out_1_valid), .io_out_1_bits_instr(i_io_out_1_bits_instr), .io_out_1_bits_pc(i_io_out_1_bits_pc), .io_out_1_bits_foldpc(i_io_out_1_bits_foldpc), .io_out_1_bits_exceptionVec_1(i_io_out_1_bits_exceptionVec_1), .io_out_1_bits_exceptionVec_2(i_io_out_1_bits_exceptionVec_2), .io_out_1_bits_exceptionVec_12(i_io_out_1_bits_exceptionVec_12), .io_out_1_bits_exceptionVec_20(i_io_out_1_bits_exceptionVec_20), .io_out_1_bits_backendException(i_io_out_1_bits_backendException), .io_out_1_bits_trigger(i_io_out_1_bits_trigger), .io_out_1_bits_pd_isRVC(i_io_out_1_bits_pd_isRVC), .io_out_1_bits_pd_brType(i_io_out_1_bits_pd_brType), .io_out_1_bits_pred_taken(i_io_out_1_bits_pred_taken), .io_out_1_bits_crossPageIPFFix(i_io_out_1_bits_crossPageIPFFix), .io_out_1_bits_ftqPtr_flag(i_io_out_1_bits_ftqPtr_flag), .io_out_1_bits_ftqPtr_value(i_io_out_1_bits_ftqPtr_value), .io_out_1_bits_ftqOffset(i_io_out_1_bits_ftqOffset), .io_out_1_bits_isLastInFtqEntry(i_io_out_1_bits_isLastInFtqEntry), .io_out_2_valid(i_io_out_2_valid), .io_out_2_bits_instr(i_io_out_2_bits_instr), .io_out_2_bits_pc(i_io_out_2_bits_pc), .io_out_2_bits_foldpc(i_io_out_2_bits_foldpc), .io_out_2_bits_exceptionVec_1(i_io_out_2_bits_exceptionVec_1), .io_out_2_bits_exceptionVec_2(i_io_out_2_bits_exceptionVec_2), .io_out_2_bits_exceptionVec_12(i_io_out_2_bits_exceptionVec_12), .io_out_2_bits_exceptionVec_20(i_io_out_2_bits_exceptionVec_20), .io_out_2_bits_backendException(i_io_out_2_bits_backendException), .io_out_2_bits_trigger(i_io_out_2_bits_trigger), .io_out_2_bits_pd_isRVC(i_io_out_2_bits_pd_isRVC), .io_out_2_bits_pd_brType(i_io_out_2_bits_pd_brType), .io_out_2_bits_pred_taken(i_io_out_2_bits_pred_taken), .io_out_2_bits_crossPageIPFFix(i_io_out_2_bits_crossPageIPFFix), .io_out_2_bits_ftqPtr_flag(i_io_out_2_bits_ftqPtr_flag), .io_out_2_bits_ftqPtr_value(i_io_out_2_bits_ftqPtr_value), .io_out_2_bits_ftqOffset(i_io_out_2_bits_ftqOffset), .io_out_2_bits_isLastInFtqEntry(i_io_out_2_bits_isLastInFtqEntry), .io_out_3_valid(i_io_out_3_valid), .io_out_3_bits_instr(i_io_out_3_bits_instr), .io_out_3_bits_pc(i_io_out_3_bits_pc), .io_out_3_bits_foldpc(i_io_out_3_bits_foldpc), .io_out_3_bits_exceptionVec_1(i_io_out_3_bits_exceptionVec_1), .io_out_3_bits_exceptionVec_2(i_io_out_3_bits_exceptionVec_2), .io_out_3_bits_exceptionVec_12(i_io_out_3_bits_exceptionVec_12), .io_out_3_bits_exceptionVec_20(i_io_out_3_bits_exceptionVec_20), .io_out_3_bits_backendException(i_io_out_3_bits_backendException), .io_out_3_bits_trigger(i_io_out_3_bits_trigger), .io_out_3_bits_pd_isRVC(i_io_out_3_bits_pd_isRVC), .io_out_3_bits_pd_brType(i_io_out_3_bits_pd_brType), .io_out_3_bits_pred_taken(i_io_out_3_bits_pred_taken), .io_out_3_bits_crossPageIPFFix(i_io_out_3_bits_crossPageIPFFix), .io_out_3_bits_ftqPtr_flag(i_io_out_3_bits_ftqPtr_flag), .io_out_3_bits_ftqPtr_value(i_io_out_3_bits_ftqPtr_value), .io_out_3_bits_ftqOffset(i_io_out_3_bits_ftqOffset), .io_out_3_bits_isLastInFtqEntry(i_io_out_3_bits_isLastInFtqEntry), .io_out_4_valid(i_io_out_4_valid), .io_out_4_bits_instr(i_io_out_4_bits_instr), .io_out_4_bits_pc(i_io_out_4_bits_pc), .io_out_4_bits_foldpc(i_io_out_4_bits_foldpc), .io_out_4_bits_exceptionVec_1(i_io_out_4_bits_exceptionVec_1), .io_out_4_bits_exceptionVec_2(i_io_out_4_bits_exceptionVec_2), .io_out_4_bits_exceptionVec_12(i_io_out_4_bits_exceptionVec_12), .io_out_4_bits_exceptionVec_20(i_io_out_4_bits_exceptionVec_20), .io_out_4_bits_backendException(i_io_out_4_bits_backendException), .io_out_4_bits_trigger(i_io_out_4_bits_trigger), .io_out_4_bits_pd_isRVC(i_io_out_4_bits_pd_isRVC), .io_out_4_bits_pd_brType(i_io_out_4_bits_pd_brType), .io_out_4_bits_pred_taken(i_io_out_4_bits_pred_taken), .io_out_4_bits_crossPageIPFFix(i_io_out_4_bits_crossPageIPFFix), .io_out_4_bits_ftqPtr_flag(i_io_out_4_bits_ftqPtr_flag), .io_out_4_bits_ftqPtr_value(i_io_out_4_bits_ftqPtr_value), .io_out_4_bits_ftqOffset(i_io_out_4_bits_ftqOffset), .io_out_4_bits_isLastInFtqEntry(i_io_out_4_bits_isLastInFtqEntry), .io_out_5_valid(i_io_out_5_valid), .io_out_5_bits_instr(i_io_out_5_bits_instr), .io_out_5_bits_pc(i_io_out_5_bits_pc), .io_out_5_bits_foldpc(i_io_out_5_bits_foldpc), .io_out_5_bits_exceptionVec_1(i_io_out_5_bits_exceptionVec_1), .io_out_5_bits_exceptionVec_2(i_io_out_5_bits_exceptionVec_2), .io_out_5_bits_exceptionVec_12(i_io_out_5_bits_exceptionVec_12), .io_out_5_bits_exceptionVec_20(i_io_out_5_bits_exceptionVec_20), .io_out_5_bits_backendException(i_io_out_5_bits_backendException), .io_out_5_bits_trigger(i_io_out_5_bits_trigger), .io_out_5_bits_pd_isRVC(i_io_out_5_bits_pd_isRVC), .io_out_5_bits_pd_brType(i_io_out_5_bits_pd_brType), .io_out_5_bits_pred_taken(i_io_out_5_bits_pred_taken), .io_out_5_bits_crossPageIPFFix(i_io_out_5_bits_crossPageIPFFix), .io_out_5_bits_ftqPtr_flag(i_io_out_5_bits_ftqPtr_flag), .io_out_5_bits_ftqPtr_value(i_io_out_5_bits_ftqPtr_value), .io_out_5_bits_ftqOffset(i_io_out_5_bits_ftqOffset), .io_out_5_bits_isLastInFtqEntry(i_io_out_5_bits_isLastInFtqEntry), .io_stallReason_reason_0(i_io_stallReason_reason_0), .io_stallReason_reason_1(i_io_stallReason_reason_1), .io_stallReason_reason_2(i_io_stallReason_reason_2), .io_stallReason_reason_3(i_io_stallReason_reason_3), .io_stallReason_reason_4(i_io_stallReason_reason_4), .io_stallReason_reason_5(i_io_stallReason_reason_5), .io_perf_0_value(i_io_perf_0_value), .io_perf_1_value(i_io_perf_1_value), .io_perf_2_value(i_io_perf_2_value), .io_perf_3_value(i_io_perf_3_value), .io_perf_4_value(i_io_perf_4_value), .io_perf_5_value(i_io_perf_5_value), .io_perf_6_value(i_io_perf_6_value), .io_perf_7_value(i_io_perf_7_value), .io_perf_8_value(i_io_perf_8_value));

  always @(negedge clk) begin
    if (rst) begin
      io_in_valid <= 1'b0;
      io_flush <= 1'b0;
      io_decodeCanAccept <= 1'b0;
      io_stallReason_backReason_valid <= 1'b0;
    end else begin
      io_flush <= ($urandom_range(0,31) == 0);
      io_in_valid <= ($urandom_range(0,3) != 0);
      io_decodeCanAccept <= ($urandom_range(0,3) != 0);
      io_stallReason_backReason_valid <= ($urandom_range(0,15) == 0);
      io_stallReason_backReason_bits <= 6'($urandom);
      io_ControlRedirect <= 1'($urandom);
      io_ControlBTBMissBubble <= 1'($urandom);
      io_TAGEMissBubble <= 1'($urandom);
      io_SCMissBubble <= 1'($urandom);
      io_ITTAGEMissBubble <= 1'($urandom);
      io_RASMissBubble <= 1'($urandom);
      io_MemVioRedirect <= 1'($urandom);
      io_in_bits_instrs_0 <= 32'($urandom);
      io_in_bits_instrs_1 <= 32'($urandom);
      io_in_bits_instrs_2 <= 32'($urandom);
      io_in_bits_instrs_3 <= 32'($urandom);
      io_in_bits_instrs_4 <= 32'($urandom);
      io_in_bits_instrs_5 <= 32'($urandom);
      io_in_bits_instrs_6 <= 32'($urandom);
      io_in_bits_instrs_7 <= 32'($urandom);
      io_in_bits_instrs_8 <= 32'($urandom);
      io_in_bits_instrs_9 <= 32'($urandom);
      io_in_bits_instrs_10 <= 32'($urandom);
      io_in_bits_instrs_11 <= 32'($urandom);
      io_in_bits_instrs_12 <= 32'($urandom);
      io_in_bits_instrs_13 <= 32'($urandom);
      io_in_bits_instrs_14 <= 32'($urandom);
      io_in_bits_instrs_15 <= 32'($urandom);
      io_in_bits_valid <= 16'($urandom);
      io_in_bits_enqEnable <= 16'($urandom);
      io_in_bits_pd_0_isRVC <= 1'($urandom);
      io_in_bits_pd_0_brType <= 2'($urandom);
      io_in_bits_pd_1_isRVC <= 1'($urandom);
      io_in_bits_pd_1_brType <= 2'($urandom);
      io_in_bits_pd_2_isRVC <= 1'($urandom);
      io_in_bits_pd_2_brType <= 2'($urandom);
      io_in_bits_pd_3_isRVC <= 1'($urandom);
      io_in_bits_pd_3_brType <= 2'($urandom);
      io_in_bits_pd_4_isRVC <= 1'($urandom);
      io_in_bits_pd_4_brType <= 2'($urandom);
      io_in_bits_pd_5_isRVC <= 1'($urandom);
      io_in_bits_pd_5_brType <= 2'($urandom);
      io_in_bits_pd_6_isRVC <= 1'($urandom);
      io_in_bits_pd_6_brType <= 2'($urandom);
      io_in_bits_pd_7_isRVC <= 1'($urandom);
      io_in_bits_pd_7_brType <= 2'($urandom);
      io_in_bits_pd_8_isRVC <= 1'($urandom);
      io_in_bits_pd_8_brType <= 2'($urandom);
      io_in_bits_pd_9_isRVC <= 1'($urandom);
      io_in_bits_pd_9_brType <= 2'($urandom);
      io_in_bits_pd_10_isRVC <= 1'($urandom);
      io_in_bits_pd_10_brType <= 2'($urandom);
      io_in_bits_pd_11_isRVC <= 1'($urandom);
      io_in_bits_pd_11_brType <= 2'($urandom);
      io_in_bits_pd_12_isRVC <= 1'($urandom);
      io_in_bits_pd_12_brType <= 2'($urandom);
      io_in_bits_pd_13_isRVC <= 1'($urandom);
      io_in_bits_pd_13_brType <= 2'($urandom);
      io_in_bits_pd_14_isRVC <= 1'($urandom);
      io_in_bits_pd_14_brType <= 2'($urandom);
      io_in_bits_pd_15_isRVC <= 1'($urandom);
      io_in_bits_pd_15_brType <= 2'($urandom);
      io_in_bits_foldpc_0 <= 10'($urandom);
      io_in_bits_foldpc_1 <= 10'($urandom);
      io_in_bits_foldpc_2 <= 10'($urandom);
      io_in_bits_foldpc_3 <= 10'($urandom);
      io_in_bits_foldpc_4 <= 10'($urandom);
      io_in_bits_foldpc_5 <= 10'($urandom);
      io_in_bits_foldpc_6 <= 10'($urandom);
      io_in_bits_foldpc_7 <= 10'($urandom);
      io_in_bits_foldpc_8 <= 10'($urandom);
      io_in_bits_foldpc_9 <= 10'($urandom);
      io_in_bits_foldpc_10 <= 10'($urandom);
      io_in_bits_foldpc_11 <= 10'($urandom);
      io_in_bits_foldpc_12 <= 10'($urandom);
      io_in_bits_foldpc_13 <= 10'($urandom);
      io_in_bits_foldpc_14 <= 10'($urandom);
      io_in_bits_foldpc_15 <= 10'($urandom);
      io_in_bits_ftqOffset_0_valid <= 1'($urandom);
      io_in_bits_ftqOffset_1_valid <= 1'($urandom);
      io_in_bits_ftqOffset_2_valid <= 1'($urandom);
      io_in_bits_ftqOffset_3_valid <= 1'($urandom);
      io_in_bits_ftqOffset_4_valid <= 1'($urandom);
      io_in_bits_ftqOffset_5_valid <= 1'($urandom);
      io_in_bits_ftqOffset_6_valid <= 1'($urandom);
      io_in_bits_ftqOffset_7_valid <= 1'($urandom);
      io_in_bits_ftqOffset_8_valid <= 1'($urandom);
      io_in_bits_ftqOffset_9_valid <= 1'($urandom);
      io_in_bits_ftqOffset_10_valid <= 1'($urandom);
      io_in_bits_ftqOffset_11_valid <= 1'($urandom);
      io_in_bits_ftqOffset_12_valid <= 1'($urandom);
      io_in_bits_ftqOffset_13_valid <= 1'($urandom);
      io_in_bits_ftqOffset_14_valid <= 1'($urandom);
      io_in_bits_ftqOffset_15_valid <= 1'($urandom);
      io_in_bits_backendException_0 <= 1'($urandom);
      io_in_bits_exceptionType_0 <= 2'($urandom);
      io_in_bits_exceptionType_1 <= 2'($urandom);
      io_in_bits_exceptionType_2 <= 2'($urandom);
      io_in_bits_exceptionType_3 <= 2'($urandom);
      io_in_bits_exceptionType_4 <= 2'($urandom);
      io_in_bits_exceptionType_5 <= 2'($urandom);
      io_in_bits_exceptionType_6 <= 2'($urandom);
      io_in_bits_exceptionType_7 <= 2'($urandom);
      io_in_bits_exceptionType_8 <= 2'($urandom);
      io_in_bits_exceptionType_9 <= 2'($urandom);
      io_in_bits_exceptionType_10 <= 2'($urandom);
      io_in_bits_exceptionType_11 <= 2'($urandom);
      io_in_bits_exceptionType_12 <= 2'($urandom);
      io_in_bits_exceptionType_13 <= 2'($urandom);
      io_in_bits_exceptionType_14 <= 2'($urandom);
      io_in_bits_exceptionType_15 <= 2'($urandom);
      io_in_bits_crossPageIPFFix_0 <= 1'($urandom);
      io_in_bits_crossPageIPFFix_1 <= 1'($urandom);
      io_in_bits_crossPageIPFFix_2 <= 1'($urandom);
      io_in_bits_crossPageIPFFix_3 <= 1'($urandom);
      io_in_bits_crossPageIPFFix_4 <= 1'($urandom);
      io_in_bits_crossPageIPFFix_5 <= 1'($urandom);
      io_in_bits_crossPageIPFFix_6 <= 1'($urandom);
      io_in_bits_crossPageIPFFix_7 <= 1'($urandom);
      io_in_bits_crossPageIPFFix_8 <= 1'($urandom);
      io_in_bits_crossPageIPFFix_9 <= 1'($urandom);
      io_in_bits_crossPageIPFFix_10 <= 1'($urandom);
      io_in_bits_crossPageIPFFix_11 <= 1'($urandom);
      io_in_bits_crossPageIPFFix_12 <= 1'($urandom);
      io_in_bits_crossPageIPFFix_13 <= 1'($urandom);
      io_in_bits_crossPageIPFFix_14 <= 1'($urandom);
      io_in_bits_crossPageIPFFix_15 <= 1'($urandom);
      io_in_bits_illegalInstr_0 <= 1'($urandom);
      io_in_bits_illegalInstr_1 <= 1'($urandom);
      io_in_bits_illegalInstr_2 <= 1'($urandom);
      io_in_bits_illegalInstr_3 <= 1'($urandom);
      io_in_bits_illegalInstr_4 <= 1'($urandom);
      io_in_bits_illegalInstr_5 <= 1'($urandom);
      io_in_bits_illegalInstr_6 <= 1'($urandom);
      io_in_bits_illegalInstr_7 <= 1'($urandom);
      io_in_bits_illegalInstr_8 <= 1'($urandom);
      io_in_bits_illegalInstr_9 <= 1'($urandom);
      io_in_bits_illegalInstr_10 <= 1'($urandom);
      io_in_bits_illegalInstr_11 <= 1'($urandom);
      io_in_bits_illegalInstr_12 <= 1'($urandom);
      io_in_bits_illegalInstr_13 <= 1'($urandom);
      io_in_bits_illegalInstr_14 <= 1'($urandom);
      io_in_bits_illegalInstr_15 <= 1'($urandom);
      io_in_bits_triggered_0 <= 4'($urandom);
      io_in_bits_triggered_1 <= 4'($urandom);
      io_in_bits_triggered_2 <= 4'($urandom);
      io_in_bits_triggered_3 <= 4'($urandom);
      io_in_bits_triggered_4 <= 4'($urandom);
      io_in_bits_triggered_5 <= 4'($urandom);
      io_in_bits_triggered_6 <= 4'($urandom);
      io_in_bits_triggered_7 <= 4'($urandom);
      io_in_bits_triggered_8 <= 4'($urandom);
      io_in_bits_triggered_9 <= 4'($urandom);
      io_in_bits_triggered_10 <= 4'($urandom);
      io_in_bits_triggered_11 <= 4'($urandom);
      io_in_bits_triggered_12 <= 4'($urandom);
      io_in_bits_triggered_13 <= 4'($urandom);
      io_in_bits_triggered_14 <= 4'($urandom);
      io_in_bits_triggered_15 <= 4'($urandom);
      io_in_bits_isLastInFtqEntry_0 <= 1'($urandom);
      io_in_bits_isLastInFtqEntry_1 <= 1'($urandom);
      io_in_bits_isLastInFtqEntry_2 <= 1'($urandom);
      io_in_bits_isLastInFtqEntry_3 <= 1'($urandom);
      io_in_bits_isLastInFtqEntry_4 <= 1'($urandom);
      io_in_bits_isLastInFtqEntry_5 <= 1'($urandom);
      io_in_bits_isLastInFtqEntry_6 <= 1'($urandom);
      io_in_bits_isLastInFtqEntry_7 <= 1'($urandom);
      io_in_bits_isLastInFtqEntry_8 <= 1'($urandom);
      io_in_bits_isLastInFtqEntry_9 <= 1'($urandom);
      io_in_bits_isLastInFtqEntry_10 <= 1'($urandom);
      io_in_bits_isLastInFtqEntry_11 <= 1'($urandom);
      io_in_bits_isLastInFtqEntry_12 <= 1'($urandom);
      io_in_bits_isLastInFtqEntry_13 <= 1'($urandom);
      io_in_bits_isLastInFtqEntry_14 <= 1'($urandom);
      io_in_bits_isLastInFtqEntry_15 <= 1'($urandom);
      io_in_bits_pc_0 <= 50'({$urandom(),$urandom()});
      io_in_bits_pc_1 <= 50'({$urandom(),$urandom()});
      io_in_bits_pc_2 <= 50'({$urandom(),$urandom()});
      io_in_bits_pc_3 <= 50'({$urandom(),$urandom()});
      io_in_bits_pc_4 <= 50'({$urandom(),$urandom()});
      io_in_bits_pc_5 <= 50'({$urandom(),$urandom()});
      io_in_bits_pc_6 <= 50'({$urandom(),$urandom()});
      io_in_bits_pc_7 <= 50'({$urandom(),$urandom()});
      io_in_bits_pc_8 <= 50'({$urandom(),$urandom()});
      io_in_bits_pc_9 <= 50'({$urandom(),$urandom()});
      io_in_bits_pc_10 <= 50'({$urandom(),$urandom()});
      io_in_bits_pc_11 <= 50'({$urandom(),$urandom()});
      io_in_bits_pc_12 <= 50'({$urandom(),$urandom()});
      io_in_bits_pc_13 <= 50'({$urandom(),$urandom()});
      io_in_bits_pc_14 <= 50'({$urandom(),$urandom()});
      io_in_bits_pc_15 <= 50'({$urandom(),$urandom()});
      io_in_bits_ftqPtr_flag <= 1'($urandom);
      io_in_bits_ftqPtr_value <= 6'($urandom);
      io_in_bits_topdown_info_reasons_0 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_1 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_2 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_3 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_4 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_5 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_6 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_7 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_8 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_9 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_10 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_11 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_12 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_13 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_14 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_15 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_16 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_17 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_18 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_19 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_20 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_21 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_22 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_23 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_24 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_25 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_26 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_27 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_28 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_29 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_30 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_31 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_32 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_33 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_34 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_35 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_36 <= 1'($urandom);
      io_in_bits_topdown_info_reasons_37 <= 1'($urandom);
    end
  end

  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4;
    checks++;
    if (g_io_in_ready !== i_io_in_ready) begin errors++;
      if (errors<=40) $display("[%0t] io_in_ready mismatch: g=%h i=%h", $time, g_io_in_ready, i_io_in_ready); end
    if (g_io_out_0_valid !== i_io_out_0_valid) begin errors++;
      if (errors<=40) $display("[%0t] io_out_0_valid mismatch: g=%h i=%h", $time, g_io_out_0_valid, i_io_out_0_valid); end
    if (g_io_out_0_bits_instr !== i_io_out_0_bits_instr) begin errors++;
      if (errors<=40) $display("[%0t] io_out_0_bits_instr mismatch: g=%h i=%h", $time, g_io_out_0_bits_instr, i_io_out_0_bits_instr); end
    if (g_io_out_0_bits_pc !== i_io_out_0_bits_pc) begin errors++;
      if (errors<=40) $display("[%0t] io_out_0_bits_pc mismatch: g=%h i=%h", $time, g_io_out_0_bits_pc, i_io_out_0_bits_pc); end
    if (g_io_out_0_bits_foldpc !== i_io_out_0_bits_foldpc) begin errors++;
      if (errors<=40) $display("[%0t] io_out_0_bits_foldpc mismatch: g=%h i=%h", $time, g_io_out_0_bits_foldpc, i_io_out_0_bits_foldpc); end
    if (g_io_out_0_bits_exceptionVec_1 !== i_io_out_0_bits_exceptionVec_1) begin errors++;
      if (errors<=40) $display("[%0t] io_out_0_bits_exceptionVec_1 mismatch: g=%h i=%h", $time, g_io_out_0_bits_exceptionVec_1, i_io_out_0_bits_exceptionVec_1); end
    if (g_io_out_0_bits_exceptionVec_2 !== i_io_out_0_bits_exceptionVec_2) begin errors++;
      if (errors<=40) $display("[%0t] io_out_0_bits_exceptionVec_2 mismatch: g=%h i=%h", $time, g_io_out_0_bits_exceptionVec_2, i_io_out_0_bits_exceptionVec_2); end
    if (g_io_out_0_bits_exceptionVec_12 !== i_io_out_0_bits_exceptionVec_12) begin errors++;
      if (errors<=40) $display("[%0t] io_out_0_bits_exceptionVec_12 mismatch: g=%h i=%h", $time, g_io_out_0_bits_exceptionVec_12, i_io_out_0_bits_exceptionVec_12); end
    if (g_io_out_0_bits_exceptionVec_20 !== i_io_out_0_bits_exceptionVec_20) begin errors++;
      if (errors<=40) $display("[%0t] io_out_0_bits_exceptionVec_20 mismatch: g=%h i=%h", $time, g_io_out_0_bits_exceptionVec_20, i_io_out_0_bits_exceptionVec_20); end
    if (g_io_out_0_bits_backendException !== i_io_out_0_bits_backendException) begin errors++;
      if (errors<=40) $display("[%0t] io_out_0_bits_backendException mismatch: g=%h i=%h", $time, g_io_out_0_bits_backendException, i_io_out_0_bits_backendException); end
    if (g_io_out_0_bits_trigger !== i_io_out_0_bits_trigger) begin errors++;
      if (errors<=40) $display("[%0t] io_out_0_bits_trigger mismatch: g=%h i=%h", $time, g_io_out_0_bits_trigger, i_io_out_0_bits_trigger); end
    if (g_io_out_0_bits_pd_isRVC !== i_io_out_0_bits_pd_isRVC) begin errors++;
      if (errors<=40) $display("[%0t] io_out_0_bits_pd_isRVC mismatch: g=%h i=%h", $time, g_io_out_0_bits_pd_isRVC, i_io_out_0_bits_pd_isRVC); end
    if (g_io_out_0_bits_pd_brType !== i_io_out_0_bits_pd_brType) begin errors++;
      if (errors<=40) $display("[%0t] io_out_0_bits_pd_brType mismatch: g=%h i=%h", $time, g_io_out_0_bits_pd_brType, i_io_out_0_bits_pd_brType); end
    if (g_io_out_0_bits_pred_taken !== i_io_out_0_bits_pred_taken) begin errors++;
      if (errors<=40) $display("[%0t] io_out_0_bits_pred_taken mismatch: g=%h i=%h", $time, g_io_out_0_bits_pred_taken, i_io_out_0_bits_pred_taken); end
    if (g_io_out_0_bits_crossPageIPFFix !== i_io_out_0_bits_crossPageIPFFix) begin errors++;
      if (errors<=40) $display("[%0t] io_out_0_bits_crossPageIPFFix mismatch: g=%h i=%h", $time, g_io_out_0_bits_crossPageIPFFix, i_io_out_0_bits_crossPageIPFFix); end
    if (g_io_out_0_bits_ftqPtr_flag !== i_io_out_0_bits_ftqPtr_flag) begin errors++;
      if (errors<=40) $display("[%0t] io_out_0_bits_ftqPtr_flag mismatch: g=%h i=%h", $time, g_io_out_0_bits_ftqPtr_flag, i_io_out_0_bits_ftqPtr_flag); end
    if (g_io_out_0_bits_ftqPtr_value !== i_io_out_0_bits_ftqPtr_value) begin errors++;
      if (errors<=40) $display("[%0t] io_out_0_bits_ftqPtr_value mismatch: g=%h i=%h", $time, g_io_out_0_bits_ftqPtr_value, i_io_out_0_bits_ftqPtr_value); end
    if (g_io_out_0_bits_ftqOffset !== i_io_out_0_bits_ftqOffset) begin errors++;
      if (errors<=40) $display("[%0t] io_out_0_bits_ftqOffset mismatch: g=%h i=%h", $time, g_io_out_0_bits_ftqOffset, i_io_out_0_bits_ftqOffset); end
    if (g_io_out_0_bits_isLastInFtqEntry !== i_io_out_0_bits_isLastInFtqEntry) begin errors++;
      if (errors<=40) $display("[%0t] io_out_0_bits_isLastInFtqEntry mismatch: g=%h i=%h", $time, g_io_out_0_bits_isLastInFtqEntry, i_io_out_0_bits_isLastInFtqEntry); end
    if (g_io_out_1_valid !== i_io_out_1_valid) begin errors++;
      if (errors<=40) $display("[%0t] io_out_1_valid mismatch: g=%h i=%h", $time, g_io_out_1_valid, i_io_out_1_valid); end
    if (g_io_out_1_bits_instr !== i_io_out_1_bits_instr) begin errors++;
      if (errors<=40) $display("[%0t] io_out_1_bits_instr mismatch: g=%h i=%h", $time, g_io_out_1_bits_instr, i_io_out_1_bits_instr); end
    if (g_io_out_1_bits_pc !== i_io_out_1_bits_pc) begin errors++;
      if (errors<=40) $display("[%0t] io_out_1_bits_pc mismatch: g=%h i=%h", $time, g_io_out_1_bits_pc, i_io_out_1_bits_pc); end
    if (g_io_out_1_bits_foldpc !== i_io_out_1_bits_foldpc) begin errors++;
      if (errors<=40) $display("[%0t] io_out_1_bits_foldpc mismatch: g=%h i=%h", $time, g_io_out_1_bits_foldpc, i_io_out_1_bits_foldpc); end
    if (g_io_out_1_bits_exceptionVec_1 !== i_io_out_1_bits_exceptionVec_1) begin errors++;
      if (errors<=40) $display("[%0t] io_out_1_bits_exceptionVec_1 mismatch: g=%h i=%h", $time, g_io_out_1_bits_exceptionVec_1, i_io_out_1_bits_exceptionVec_1); end
    if (g_io_out_1_bits_exceptionVec_2 !== i_io_out_1_bits_exceptionVec_2) begin errors++;
      if (errors<=40) $display("[%0t] io_out_1_bits_exceptionVec_2 mismatch: g=%h i=%h", $time, g_io_out_1_bits_exceptionVec_2, i_io_out_1_bits_exceptionVec_2); end
    if (g_io_out_1_bits_exceptionVec_12 !== i_io_out_1_bits_exceptionVec_12) begin errors++;
      if (errors<=40) $display("[%0t] io_out_1_bits_exceptionVec_12 mismatch: g=%h i=%h", $time, g_io_out_1_bits_exceptionVec_12, i_io_out_1_bits_exceptionVec_12); end
    if (g_io_out_1_bits_exceptionVec_20 !== i_io_out_1_bits_exceptionVec_20) begin errors++;
      if (errors<=40) $display("[%0t] io_out_1_bits_exceptionVec_20 mismatch: g=%h i=%h", $time, g_io_out_1_bits_exceptionVec_20, i_io_out_1_bits_exceptionVec_20); end
    if (g_io_out_1_bits_backendException !== i_io_out_1_bits_backendException) begin errors++;
      if (errors<=40) $display("[%0t] io_out_1_bits_backendException mismatch: g=%h i=%h", $time, g_io_out_1_bits_backendException, i_io_out_1_bits_backendException); end
    if (g_io_out_1_bits_trigger !== i_io_out_1_bits_trigger) begin errors++;
      if (errors<=40) $display("[%0t] io_out_1_bits_trigger mismatch: g=%h i=%h", $time, g_io_out_1_bits_trigger, i_io_out_1_bits_trigger); end
    if (g_io_out_1_bits_pd_isRVC !== i_io_out_1_bits_pd_isRVC) begin errors++;
      if (errors<=40) $display("[%0t] io_out_1_bits_pd_isRVC mismatch: g=%h i=%h", $time, g_io_out_1_bits_pd_isRVC, i_io_out_1_bits_pd_isRVC); end
    if (g_io_out_1_bits_pd_brType !== i_io_out_1_bits_pd_brType) begin errors++;
      if (errors<=40) $display("[%0t] io_out_1_bits_pd_brType mismatch: g=%h i=%h", $time, g_io_out_1_bits_pd_brType, i_io_out_1_bits_pd_brType); end
    if (g_io_out_1_bits_pred_taken !== i_io_out_1_bits_pred_taken) begin errors++;
      if (errors<=40) $display("[%0t] io_out_1_bits_pred_taken mismatch: g=%h i=%h", $time, g_io_out_1_bits_pred_taken, i_io_out_1_bits_pred_taken); end
    if (g_io_out_1_bits_crossPageIPFFix !== i_io_out_1_bits_crossPageIPFFix) begin errors++;
      if (errors<=40) $display("[%0t] io_out_1_bits_crossPageIPFFix mismatch: g=%h i=%h", $time, g_io_out_1_bits_crossPageIPFFix, i_io_out_1_bits_crossPageIPFFix); end
    if (g_io_out_1_bits_ftqPtr_flag !== i_io_out_1_bits_ftqPtr_flag) begin errors++;
      if (errors<=40) $display("[%0t] io_out_1_bits_ftqPtr_flag mismatch: g=%h i=%h", $time, g_io_out_1_bits_ftqPtr_flag, i_io_out_1_bits_ftqPtr_flag); end
    if (g_io_out_1_bits_ftqPtr_value !== i_io_out_1_bits_ftqPtr_value) begin errors++;
      if (errors<=40) $display("[%0t] io_out_1_bits_ftqPtr_value mismatch: g=%h i=%h", $time, g_io_out_1_bits_ftqPtr_value, i_io_out_1_bits_ftqPtr_value); end
    if (g_io_out_1_bits_ftqOffset !== i_io_out_1_bits_ftqOffset) begin errors++;
      if (errors<=40) $display("[%0t] io_out_1_bits_ftqOffset mismatch: g=%h i=%h", $time, g_io_out_1_bits_ftqOffset, i_io_out_1_bits_ftqOffset); end
    if (g_io_out_1_bits_isLastInFtqEntry !== i_io_out_1_bits_isLastInFtqEntry) begin errors++;
      if (errors<=40) $display("[%0t] io_out_1_bits_isLastInFtqEntry mismatch: g=%h i=%h", $time, g_io_out_1_bits_isLastInFtqEntry, i_io_out_1_bits_isLastInFtqEntry); end
    if (g_io_out_2_valid !== i_io_out_2_valid) begin errors++;
      if (errors<=40) $display("[%0t] io_out_2_valid mismatch: g=%h i=%h", $time, g_io_out_2_valid, i_io_out_2_valid); end
    if (g_io_out_2_bits_instr !== i_io_out_2_bits_instr) begin errors++;
      if (errors<=40) $display("[%0t] io_out_2_bits_instr mismatch: g=%h i=%h", $time, g_io_out_2_bits_instr, i_io_out_2_bits_instr); end
    if (g_io_out_2_bits_pc !== i_io_out_2_bits_pc) begin errors++;
      if (errors<=40) $display("[%0t] io_out_2_bits_pc mismatch: g=%h i=%h", $time, g_io_out_2_bits_pc, i_io_out_2_bits_pc); end
    if (g_io_out_2_bits_foldpc !== i_io_out_2_bits_foldpc) begin errors++;
      if (errors<=40) $display("[%0t] io_out_2_bits_foldpc mismatch: g=%h i=%h", $time, g_io_out_2_bits_foldpc, i_io_out_2_bits_foldpc); end
    if (g_io_out_2_bits_exceptionVec_1 !== i_io_out_2_bits_exceptionVec_1) begin errors++;
      if (errors<=40) $display("[%0t] io_out_2_bits_exceptionVec_1 mismatch: g=%h i=%h", $time, g_io_out_2_bits_exceptionVec_1, i_io_out_2_bits_exceptionVec_1); end
    if (g_io_out_2_bits_exceptionVec_2 !== i_io_out_2_bits_exceptionVec_2) begin errors++;
      if (errors<=40) $display("[%0t] io_out_2_bits_exceptionVec_2 mismatch: g=%h i=%h", $time, g_io_out_2_bits_exceptionVec_2, i_io_out_2_bits_exceptionVec_2); end
    if (g_io_out_2_bits_exceptionVec_12 !== i_io_out_2_bits_exceptionVec_12) begin errors++;
      if (errors<=40) $display("[%0t] io_out_2_bits_exceptionVec_12 mismatch: g=%h i=%h", $time, g_io_out_2_bits_exceptionVec_12, i_io_out_2_bits_exceptionVec_12); end
    if (g_io_out_2_bits_exceptionVec_20 !== i_io_out_2_bits_exceptionVec_20) begin errors++;
      if (errors<=40) $display("[%0t] io_out_2_bits_exceptionVec_20 mismatch: g=%h i=%h", $time, g_io_out_2_bits_exceptionVec_20, i_io_out_2_bits_exceptionVec_20); end
    if (g_io_out_2_bits_backendException !== i_io_out_2_bits_backendException) begin errors++;
      if (errors<=40) $display("[%0t] io_out_2_bits_backendException mismatch: g=%h i=%h", $time, g_io_out_2_bits_backendException, i_io_out_2_bits_backendException); end
    if (g_io_out_2_bits_trigger !== i_io_out_2_bits_trigger) begin errors++;
      if (errors<=40) $display("[%0t] io_out_2_bits_trigger mismatch: g=%h i=%h", $time, g_io_out_2_bits_trigger, i_io_out_2_bits_trigger); end
    if (g_io_out_2_bits_pd_isRVC !== i_io_out_2_bits_pd_isRVC) begin errors++;
      if (errors<=40) $display("[%0t] io_out_2_bits_pd_isRVC mismatch: g=%h i=%h", $time, g_io_out_2_bits_pd_isRVC, i_io_out_2_bits_pd_isRVC); end
    if (g_io_out_2_bits_pd_brType !== i_io_out_2_bits_pd_brType) begin errors++;
      if (errors<=40) $display("[%0t] io_out_2_bits_pd_brType mismatch: g=%h i=%h", $time, g_io_out_2_bits_pd_brType, i_io_out_2_bits_pd_brType); end
    if (g_io_out_2_bits_pred_taken !== i_io_out_2_bits_pred_taken) begin errors++;
      if (errors<=40) $display("[%0t] io_out_2_bits_pred_taken mismatch: g=%h i=%h", $time, g_io_out_2_bits_pred_taken, i_io_out_2_bits_pred_taken); end
    if (g_io_out_2_bits_crossPageIPFFix !== i_io_out_2_bits_crossPageIPFFix) begin errors++;
      if (errors<=40) $display("[%0t] io_out_2_bits_crossPageIPFFix mismatch: g=%h i=%h", $time, g_io_out_2_bits_crossPageIPFFix, i_io_out_2_bits_crossPageIPFFix); end
    if (g_io_out_2_bits_ftqPtr_flag !== i_io_out_2_bits_ftqPtr_flag) begin errors++;
      if (errors<=40) $display("[%0t] io_out_2_bits_ftqPtr_flag mismatch: g=%h i=%h", $time, g_io_out_2_bits_ftqPtr_flag, i_io_out_2_bits_ftqPtr_flag); end
    if (g_io_out_2_bits_ftqPtr_value !== i_io_out_2_bits_ftqPtr_value) begin errors++;
      if (errors<=40) $display("[%0t] io_out_2_bits_ftqPtr_value mismatch: g=%h i=%h", $time, g_io_out_2_bits_ftqPtr_value, i_io_out_2_bits_ftqPtr_value); end
    if (g_io_out_2_bits_ftqOffset !== i_io_out_2_bits_ftqOffset) begin errors++;
      if (errors<=40) $display("[%0t] io_out_2_bits_ftqOffset mismatch: g=%h i=%h", $time, g_io_out_2_bits_ftqOffset, i_io_out_2_bits_ftqOffset); end
    if (g_io_out_2_bits_isLastInFtqEntry !== i_io_out_2_bits_isLastInFtqEntry) begin errors++;
      if (errors<=40) $display("[%0t] io_out_2_bits_isLastInFtqEntry mismatch: g=%h i=%h", $time, g_io_out_2_bits_isLastInFtqEntry, i_io_out_2_bits_isLastInFtqEntry); end
    if (g_io_out_3_valid !== i_io_out_3_valid) begin errors++;
      if (errors<=40) $display("[%0t] io_out_3_valid mismatch: g=%h i=%h", $time, g_io_out_3_valid, i_io_out_3_valid); end
    if (g_io_out_3_bits_instr !== i_io_out_3_bits_instr) begin errors++;
      if (errors<=40) $display("[%0t] io_out_3_bits_instr mismatch: g=%h i=%h", $time, g_io_out_3_bits_instr, i_io_out_3_bits_instr); end
    if (g_io_out_3_bits_pc !== i_io_out_3_bits_pc) begin errors++;
      if (errors<=40) $display("[%0t] io_out_3_bits_pc mismatch: g=%h i=%h", $time, g_io_out_3_bits_pc, i_io_out_3_bits_pc); end
    if (g_io_out_3_bits_foldpc !== i_io_out_3_bits_foldpc) begin errors++;
      if (errors<=40) $display("[%0t] io_out_3_bits_foldpc mismatch: g=%h i=%h", $time, g_io_out_3_bits_foldpc, i_io_out_3_bits_foldpc); end
    if (g_io_out_3_bits_exceptionVec_1 !== i_io_out_3_bits_exceptionVec_1) begin errors++;
      if (errors<=40) $display("[%0t] io_out_3_bits_exceptionVec_1 mismatch: g=%h i=%h", $time, g_io_out_3_bits_exceptionVec_1, i_io_out_3_bits_exceptionVec_1); end
    if (g_io_out_3_bits_exceptionVec_2 !== i_io_out_3_bits_exceptionVec_2) begin errors++;
      if (errors<=40) $display("[%0t] io_out_3_bits_exceptionVec_2 mismatch: g=%h i=%h", $time, g_io_out_3_bits_exceptionVec_2, i_io_out_3_bits_exceptionVec_2); end
    if (g_io_out_3_bits_exceptionVec_12 !== i_io_out_3_bits_exceptionVec_12) begin errors++;
      if (errors<=40) $display("[%0t] io_out_3_bits_exceptionVec_12 mismatch: g=%h i=%h", $time, g_io_out_3_bits_exceptionVec_12, i_io_out_3_bits_exceptionVec_12); end
    if (g_io_out_3_bits_exceptionVec_20 !== i_io_out_3_bits_exceptionVec_20) begin errors++;
      if (errors<=40) $display("[%0t] io_out_3_bits_exceptionVec_20 mismatch: g=%h i=%h", $time, g_io_out_3_bits_exceptionVec_20, i_io_out_3_bits_exceptionVec_20); end
    if (g_io_out_3_bits_backendException !== i_io_out_3_bits_backendException) begin errors++;
      if (errors<=40) $display("[%0t] io_out_3_bits_backendException mismatch: g=%h i=%h", $time, g_io_out_3_bits_backendException, i_io_out_3_bits_backendException); end
    if (g_io_out_3_bits_trigger !== i_io_out_3_bits_trigger) begin errors++;
      if (errors<=40) $display("[%0t] io_out_3_bits_trigger mismatch: g=%h i=%h", $time, g_io_out_3_bits_trigger, i_io_out_3_bits_trigger); end
    if (g_io_out_3_bits_pd_isRVC !== i_io_out_3_bits_pd_isRVC) begin errors++;
      if (errors<=40) $display("[%0t] io_out_3_bits_pd_isRVC mismatch: g=%h i=%h", $time, g_io_out_3_bits_pd_isRVC, i_io_out_3_bits_pd_isRVC); end
    if (g_io_out_3_bits_pd_brType !== i_io_out_3_bits_pd_brType) begin errors++;
      if (errors<=40) $display("[%0t] io_out_3_bits_pd_brType mismatch: g=%h i=%h", $time, g_io_out_3_bits_pd_brType, i_io_out_3_bits_pd_brType); end
    if (g_io_out_3_bits_pred_taken !== i_io_out_3_bits_pred_taken) begin errors++;
      if (errors<=40) $display("[%0t] io_out_3_bits_pred_taken mismatch: g=%h i=%h", $time, g_io_out_3_bits_pred_taken, i_io_out_3_bits_pred_taken); end
    if (g_io_out_3_bits_crossPageIPFFix !== i_io_out_3_bits_crossPageIPFFix) begin errors++;
      if (errors<=40) $display("[%0t] io_out_3_bits_crossPageIPFFix mismatch: g=%h i=%h", $time, g_io_out_3_bits_crossPageIPFFix, i_io_out_3_bits_crossPageIPFFix); end
    if (g_io_out_3_bits_ftqPtr_flag !== i_io_out_3_bits_ftqPtr_flag) begin errors++;
      if (errors<=40) $display("[%0t] io_out_3_bits_ftqPtr_flag mismatch: g=%h i=%h", $time, g_io_out_3_bits_ftqPtr_flag, i_io_out_3_bits_ftqPtr_flag); end
    if (g_io_out_3_bits_ftqPtr_value !== i_io_out_3_bits_ftqPtr_value) begin errors++;
      if (errors<=40) $display("[%0t] io_out_3_bits_ftqPtr_value mismatch: g=%h i=%h", $time, g_io_out_3_bits_ftqPtr_value, i_io_out_3_bits_ftqPtr_value); end
    if (g_io_out_3_bits_ftqOffset !== i_io_out_3_bits_ftqOffset) begin errors++;
      if (errors<=40) $display("[%0t] io_out_3_bits_ftqOffset mismatch: g=%h i=%h", $time, g_io_out_3_bits_ftqOffset, i_io_out_3_bits_ftqOffset); end
    if (g_io_out_3_bits_isLastInFtqEntry !== i_io_out_3_bits_isLastInFtqEntry) begin errors++;
      if (errors<=40) $display("[%0t] io_out_3_bits_isLastInFtqEntry mismatch: g=%h i=%h", $time, g_io_out_3_bits_isLastInFtqEntry, i_io_out_3_bits_isLastInFtqEntry); end
    if (g_io_out_4_valid !== i_io_out_4_valid) begin errors++;
      if (errors<=40) $display("[%0t] io_out_4_valid mismatch: g=%h i=%h", $time, g_io_out_4_valid, i_io_out_4_valid); end
    if (g_io_out_4_bits_instr !== i_io_out_4_bits_instr) begin errors++;
      if (errors<=40) $display("[%0t] io_out_4_bits_instr mismatch: g=%h i=%h", $time, g_io_out_4_bits_instr, i_io_out_4_bits_instr); end
    if (g_io_out_4_bits_pc !== i_io_out_4_bits_pc) begin errors++;
      if (errors<=40) $display("[%0t] io_out_4_bits_pc mismatch: g=%h i=%h", $time, g_io_out_4_bits_pc, i_io_out_4_bits_pc); end
    if (g_io_out_4_bits_foldpc !== i_io_out_4_bits_foldpc) begin errors++;
      if (errors<=40) $display("[%0t] io_out_4_bits_foldpc mismatch: g=%h i=%h", $time, g_io_out_4_bits_foldpc, i_io_out_4_bits_foldpc); end
    if (g_io_out_4_bits_exceptionVec_1 !== i_io_out_4_bits_exceptionVec_1) begin errors++;
      if (errors<=40) $display("[%0t] io_out_4_bits_exceptionVec_1 mismatch: g=%h i=%h", $time, g_io_out_4_bits_exceptionVec_1, i_io_out_4_bits_exceptionVec_1); end
    if (g_io_out_4_bits_exceptionVec_2 !== i_io_out_4_bits_exceptionVec_2) begin errors++;
      if (errors<=40) $display("[%0t] io_out_4_bits_exceptionVec_2 mismatch: g=%h i=%h", $time, g_io_out_4_bits_exceptionVec_2, i_io_out_4_bits_exceptionVec_2); end
    if (g_io_out_4_bits_exceptionVec_12 !== i_io_out_4_bits_exceptionVec_12) begin errors++;
      if (errors<=40) $display("[%0t] io_out_4_bits_exceptionVec_12 mismatch: g=%h i=%h", $time, g_io_out_4_bits_exceptionVec_12, i_io_out_4_bits_exceptionVec_12); end
    if (g_io_out_4_bits_exceptionVec_20 !== i_io_out_4_bits_exceptionVec_20) begin errors++;
      if (errors<=40) $display("[%0t] io_out_4_bits_exceptionVec_20 mismatch: g=%h i=%h", $time, g_io_out_4_bits_exceptionVec_20, i_io_out_4_bits_exceptionVec_20); end
    if (g_io_out_4_bits_backendException !== i_io_out_4_bits_backendException) begin errors++;
      if (errors<=40) $display("[%0t] io_out_4_bits_backendException mismatch: g=%h i=%h", $time, g_io_out_4_bits_backendException, i_io_out_4_bits_backendException); end
    if (g_io_out_4_bits_trigger !== i_io_out_4_bits_trigger) begin errors++;
      if (errors<=40) $display("[%0t] io_out_4_bits_trigger mismatch: g=%h i=%h", $time, g_io_out_4_bits_trigger, i_io_out_4_bits_trigger); end
    if (g_io_out_4_bits_pd_isRVC !== i_io_out_4_bits_pd_isRVC) begin errors++;
      if (errors<=40) $display("[%0t] io_out_4_bits_pd_isRVC mismatch: g=%h i=%h", $time, g_io_out_4_bits_pd_isRVC, i_io_out_4_bits_pd_isRVC); end
    if (g_io_out_4_bits_pd_brType !== i_io_out_4_bits_pd_brType) begin errors++;
      if (errors<=40) $display("[%0t] io_out_4_bits_pd_brType mismatch: g=%h i=%h", $time, g_io_out_4_bits_pd_brType, i_io_out_4_bits_pd_brType); end
    if (g_io_out_4_bits_pred_taken !== i_io_out_4_bits_pred_taken) begin errors++;
      if (errors<=40) $display("[%0t] io_out_4_bits_pred_taken mismatch: g=%h i=%h", $time, g_io_out_4_bits_pred_taken, i_io_out_4_bits_pred_taken); end
    if (g_io_out_4_bits_crossPageIPFFix !== i_io_out_4_bits_crossPageIPFFix) begin errors++;
      if (errors<=40) $display("[%0t] io_out_4_bits_crossPageIPFFix mismatch: g=%h i=%h", $time, g_io_out_4_bits_crossPageIPFFix, i_io_out_4_bits_crossPageIPFFix); end
    if (g_io_out_4_bits_ftqPtr_flag !== i_io_out_4_bits_ftqPtr_flag) begin errors++;
      if (errors<=40) $display("[%0t] io_out_4_bits_ftqPtr_flag mismatch: g=%h i=%h", $time, g_io_out_4_bits_ftqPtr_flag, i_io_out_4_bits_ftqPtr_flag); end
    if (g_io_out_4_bits_ftqPtr_value !== i_io_out_4_bits_ftqPtr_value) begin errors++;
      if (errors<=40) $display("[%0t] io_out_4_bits_ftqPtr_value mismatch: g=%h i=%h", $time, g_io_out_4_bits_ftqPtr_value, i_io_out_4_bits_ftqPtr_value); end
    if (g_io_out_4_bits_ftqOffset !== i_io_out_4_bits_ftqOffset) begin errors++;
      if (errors<=40) $display("[%0t] io_out_4_bits_ftqOffset mismatch: g=%h i=%h", $time, g_io_out_4_bits_ftqOffset, i_io_out_4_bits_ftqOffset); end
    if (g_io_out_4_bits_isLastInFtqEntry !== i_io_out_4_bits_isLastInFtqEntry) begin errors++;
      if (errors<=40) $display("[%0t] io_out_4_bits_isLastInFtqEntry mismatch: g=%h i=%h", $time, g_io_out_4_bits_isLastInFtqEntry, i_io_out_4_bits_isLastInFtqEntry); end
    if (g_io_out_5_valid !== i_io_out_5_valid) begin errors++;
      if (errors<=40) $display("[%0t] io_out_5_valid mismatch: g=%h i=%h", $time, g_io_out_5_valid, i_io_out_5_valid); end
    if (g_io_out_5_bits_instr !== i_io_out_5_bits_instr) begin errors++;
      if (errors<=40) $display("[%0t] io_out_5_bits_instr mismatch: g=%h i=%h", $time, g_io_out_5_bits_instr, i_io_out_5_bits_instr); end
    if (g_io_out_5_bits_pc !== i_io_out_5_bits_pc) begin errors++;
      if (errors<=40) $display("[%0t] io_out_5_bits_pc mismatch: g=%h i=%h", $time, g_io_out_5_bits_pc, i_io_out_5_bits_pc); end
    if (g_io_out_5_bits_foldpc !== i_io_out_5_bits_foldpc) begin errors++;
      if (errors<=40) $display("[%0t] io_out_5_bits_foldpc mismatch: g=%h i=%h", $time, g_io_out_5_bits_foldpc, i_io_out_5_bits_foldpc); end
    if (g_io_out_5_bits_exceptionVec_1 !== i_io_out_5_bits_exceptionVec_1) begin errors++;
      if (errors<=40) $display("[%0t] io_out_5_bits_exceptionVec_1 mismatch: g=%h i=%h", $time, g_io_out_5_bits_exceptionVec_1, i_io_out_5_bits_exceptionVec_1); end
    if (g_io_out_5_bits_exceptionVec_2 !== i_io_out_5_bits_exceptionVec_2) begin errors++;
      if (errors<=40) $display("[%0t] io_out_5_bits_exceptionVec_2 mismatch: g=%h i=%h", $time, g_io_out_5_bits_exceptionVec_2, i_io_out_5_bits_exceptionVec_2); end
    if (g_io_out_5_bits_exceptionVec_12 !== i_io_out_5_bits_exceptionVec_12) begin errors++;
      if (errors<=40) $display("[%0t] io_out_5_bits_exceptionVec_12 mismatch: g=%h i=%h", $time, g_io_out_5_bits_exceptionVec_12, i_io_out_5_bits_exceptionVec_12); end
    if (g_io_out_5_bits_exceptionVec_20 !== i_io_out_5_bits_exceptionVec_20) begin errors++;
      if (errors<=40) $display("[%0t] io_out_5_bits_exceptionVec_20 mismatch: g=%h i=%h", $time, g_io_out_5_bits_exceptionVec_20, i_io_out_5_bits_exceptionVec_20); end
    if (g_io_out_5_bits_backendException !== i_io_out_5_bits_backendException) begin errors++;
      if (errors<=40) $display("[%0t] io_out_5_bits_backendException mismatch: g=%h i=%h", $time, g_io_out_5_bits_backendException, i_io_out_5_bits_backendException); end
    if (g_io_out_5_bits_trigger !== i_io_out_5_bits_trigger) begin errors++;
      if (errors<=40) $display("[%0t] io_out_5_bits_trigger mismatch: g=%h i=%h", $time, g_io_out_5_bits_trigger, i_io_out_5_bits_trigger); end
    if (g_io_out_5_bits_pd_isRVC !== i_io_out_5_bits_pd_isRVC) begin errors++;
      if (errors<=40) $display("[%0t] io_out_5_bits_pd_isRVC mismatch: g=%h i=%h", $time, g_io_out_5_bits_pd_isRVC, i_io_out_5_bits_pd_isRVC); end
    if (g_io_out_5_bits_pd_brType !== i_io_out_5_bits_pd_brType) begin errors++;
      if (errors<=40) $display("[%0t] io_out_5_bits_pd_brType mismatch: g=%h i=%h", $time, g_io_out_5_bits_pd_brType, i_io_out_5_bits_pd_brType); end
    if (g_io_out_5_bits_pred_taken !== i_io_out_5_bits_pred_taken) begin errors++;
      if (errors<=40) $display("[%0t] io_out_5_bits_pred_taken mismatch: g=%h i=%h", $time, g_io_out_5_bits_pred_taken, i_io_out_5_bits_pred_taken); end
    if (g_io_out_5_bits_crossPageIPFFix !== i_io_out_5_bits_crossPageIPFFix) begin errors++;
      if (errors<=40) $display("[%0t] io_out_5_bits_crossPageIPFFix mismatch: g=%h i=%h", $time, g_io_out_5_bits_crossPageIPFFix, i_io_out_5_bits_crossPageIPFFix); end
    if (g_io_out_5_bits_ftqPtr_flag !== i_io_out_5_bits_ftqPtr_flag) begin errors++;
      if (errors<=40) $display("[%0t] io_out_5_bits_ftqPtr_flag mismatch: g=%h i=%h", $time, g_io_out_5_bits_ftqPtr_flag, i_io_out_5_bits_ftqPtr_flag); end
    if (g_io_out_5_bits_ftqPtr_value !== i_io_out_5_bits_ftqPtr_value) begin errors++;
      if (errors<=40) $display("[%0t] io_out_5_bits_ftqPtr_value mismatch: g=%h i=%h", $time, g_io_out_5_bits_ftqPtr_value, i_io_out_5_bits_ftqPtr_value); end
    if (g_io_out_5_bits_ftqOffset !== i_io_out_5_bits_ftqOffset) begin errors++;
      if (errors<=40) $display("[%0t] io_out_5_bits_ftqOffset mismatch: g=%h i=%h", $time, g_io_out_5_bits_ftqOffset, i_io_out_5_bits_ftqOffset); end
    if (g_io_out_5_bits_isLastInFtqEntry !== i_io_out_5_bits_isLastInFtqEntry) begin errors++;
      if (errors<=40) $display("[%0t] io_out_5_bits_isLastInFtqEntry mismatch: g=%h i=%h", $time, g_io_out_5_bits_isLastInFtqEntry, i_io_out_5_bits_isLastInFtqEntry); end
    if (g_io_stallReason_reason_0 !== i_io_stallReason_reason_0) begin errors++;
      if (errors<=40) $display("[%0t] io_stallReason_reason_0 mismatch: g=%h i=%h", $time, g_io_stallReason_reason_0, i_io_stallReason_reason_0); end
    if (g_io_stallReason_reason_1 !== i_io_stallReason_reason_1) begin errors++;
      if (errors<=40) $display("[%0t] io_stallReason_reason_1 mismatch: g=%h i=%h", $time, g_io_stallReason_reason_1, i_io_stallReason_reason_1); end
    if (g_io_stallReason_reason_2 !== i_io_stallReason_reason_2) begin errors++;
      if (errors<=40) $display("[%0t] io_stallReason_reason_2 mismatch: g=%h i=%h", $time, g_io_stallReason_reason_2, i_io_stallReason_reason_2); end
    if (g_io_stallReason_reason_3 !== i_io_stallReason_reason_3) begin errors++;
      if (errors<=40) $display("[%0t] io_stallReason_reason_3 mismatch: g=%h i=%h", $time, g_io_stallReason_reason_3, i_io_stallReason_reason_3); end
    if (g_io_stallReason_reason_4 !== i_io_stallReason_reason_4) begin errors++;
      if (errors<=40) $display("[%0t] io_stallReason_reason_4 mismatch: g=%h i=%h", $time, g_io_stallReason_reason_4, i_io_stallReason_reason_4); end
    if (g_io_stallReason_reason_5 !== i_io_stallReason_reason_5) begin errors++;
      if (errors<=40) $display("[%0t] io_stallReason_reason_5 mismatch: g=%h i=%h", $time, g_io_stallReason_reason_5, i_io_stallReason_reason_5); end
    if (g_io_perf_0_value !== i_io_perf_0_value) begin errors++;
      if (errors<=40) $display("[%0t] io_perf_0_value mismatch: g=%h i=%h", $time, g_io_perf_0_value, i_io_perf_0_value); end
    if (g_io_perf_1_value !== i_io_perf_1_value) begin errors++;
      if (errors<=40) $display("[%0t] io_perf_1_value mismatch: g=%h i=%h", $time, g_io_perf_1_value, i_io_perf_1_value); end
    if (g_io_perf_2_value !== i_io_perf_2_value) begin errors++;
      if (errors<=40) $display("[%0t] io_perf_2_value mismatch: g=%h i=%h", $time, g_io_perf_2_value, i_io_perf_2_value); end
    if (g_io_perf_3_value !== i_io_perf_3_value) begin errors++;
      if (errors<=40) $display("[%0t] io_perf_3_value mismatch: g=%h i=%h", $time, g_io_perf_3_value, i_io_perf_3_value); end
    if (g_io_perf_4_value !== i_io_perf_4_value) begin errors++;
      if (errors<=40) $display("[%0t] io_perf_4_value mismatch: g=%h i=%h", $time, g_io_perf_4_value, i_io_perf_4_value); end
    if (g_io_perf_5_value !== i_io_perf_5_value) begin errors++;
      if (errors<=40) $display("[%0t] io_perf_5_value mismatch: g=%h i=%h", $time, g_io_perf_5_value, i_io_perf_5_value); end
    if (g_io_perf_6_value !== i_io_perf_6_value) begin errors++;
      if (errors<=40) $display("[%0t] io_perf_6_value mismatch: g=%h i=%h", $time, g_io_perf_6_value, i_io_perf_6_value); end
    if (g_io_perf_7_value !== i_io_perf_7_value) begin errors++;
      if (errors<=40) $display("[%0t] io_perf_7_value mismatch: g=%h i=%h", $time, g_io_perf_7_value, i_io_perf_7_value); end
    if (g_io_perf_8_value !== i_io_perf_8_value) begin errors++;
      if (errors<=40) $display("[%0t] io_perf_8_value mismatch: g=%h i=%h", $time, g_io_perf_8_value, i_io_perf_8_value); end
  end

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 40000;
    rst = 1;
    repeat (5) @(posedge clk);
    rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("---------------------------------------------");
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
