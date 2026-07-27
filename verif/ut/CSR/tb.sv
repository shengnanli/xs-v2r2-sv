// =============================================================================
// tb —— CSR assembly parent UT: golden CSR (u_g) vs 可读核 CSR_xs (u_i) 逐拍比对。
// 两 DUT 共用确定性 NewCSR/IMSICGateWay stub (csr_child_stub.sv) + golden
//   TrapInstMod/TrapTvalMod/IMSIC/IntFile 真体 => 胶合逻辑差异必现于输出比对。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk=0, rst=1;
  int errors=0, checks=0;
  always #5 clk=~clk;

  logic io_flush_valid;
  logic io_flush_bits_robIdx_flag;
  logic [7:0] io_flush_bits_robIdx_value;
  logic io_flush_bits_ftqIdx_flag;
  logic [5:0] io_flush_bits_ftqIdx_value;
  logic [3:0] io_flush_bits_ftqOffset;
  logic io_flush_bits_level;
  logic io_flush_bits_cfiUpdate_backendIGPF;
  logic io_flush_bits_cfiUpdate_backendIPF;
  logic io_flush_bits_cfiUpdate_backendIAF;
  logic [63:0] io_flush_bits_fullTarget;
  logic io_in_valid;
  logic [8:0] io_in_bits_ctrl_fuOpType;
  logic io_in_bits_ctrl_robIdx_flag;
  logic [7:0] io_in_bits_ctrl_robIdx_value;
  logic [7:0] io_in_bits_ctrl_pdest;
  logic io_in_bits_ctrl_rfWen;
  logic io_in_bits_ctrl_ftqIdx_flag;
  logic [5:0] io_in_bits_ctrl_ftqIdx_value;
  logic [3:0] io_in_bits_ctrl_ftqOffset;
  logic [63:0] io_in_bits_data_src_0;
  logic [63:0] io_in_bits_data_imm;
  logic [63:0] io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] io_in_bits_perfDebugInfo_issueTime;
  logic io_out_ready;
  logic [7:0] io_csrin_hartId;
  logic io_csrin_msiInfo_valid;
  logic [10:0] io_csrin_msiInfo_bits;
  logic io_csrin_criticalErrorState;
  logic io_csrin_clintTime_valid;
  logic [63:0] io_csrin_clintTime_bits;
  logic io_csrin_l2FlushDone;
  logic io_csrin_trapInstInfo_valid;
  logic [31:0] io_csrin_trapInstInfo_bits_instr;
  logic io_csrin_trapInstInfo_bits_ftqPtr_flag;
  logic [5:0] io_csrin_trapInstInfo_bits_ftqPtr_value;
  logic [3:0] io_csrin_trapInstInfo_bits_ftqOffset;
  logic io_csrin_fromVecExcpMod_busy;
  logic [5:0] io_csrio_perf_perfEventsFrontend_0_value;
  logic [5:0] io_csrio_perf_perfEventsFrontend_1_value;
  logic [5:0] io_csrio_perf_perfEventsFrontend_2_value;
  logic [5:0] io_csrio_perf_perfEventsFrontend_3_value;
  logic [5:0] io_csrio_perf_perfEventsFrontend_4_value;
  logic [5:0] io_csrio_perf_perfEventsFrontend_5_value;
  logic [5:0] io_csrio_perf_perfEventsFrontend_6_value;
  logic [5:0] io_csrio_perf_perfEventsFrontend_7_value;
  logic [5:0] io_csrio_perf_perfEventsBackend_0_value;
  logic [5:0] io_csrio_perf_perfEventsBackend_1_value;
  logic [5:0] io_csrio_perf_perfEventsBackend_2_value;
  logic [5:0] io_csrio_perf_perfEventsBackend_3_value;
  logic [5:0] io_csrio_perf_perfEventsBackend_4_value;
  logic [5:0] io_csrio_perf_perfEventsBackend_5_value;
  logic [5:0] io_csrio_perf_perfEventsBackend_6_value;
  logic [5:0] io_csrio_perf_perfEventsBackend_7_value;
  logic [5:0] io_csrio_perf_perfEventsLsu_0_value;
  logic [5:0] io_csrio_perf_perfEventsLsu_1_value;
  logic [5:0] io_csrio_perf_perfEventsLsu_2_value;
  logic [5:0] io_csrio_perf_perfEventsLsu_3_value;
  logic [5:0] io_csrio_perf_perfEventsLsu_4_value;
  logic [5:0] io_csrio_perf_perfEventsLsu_5_value;
  logic [5:0] io_csrio_perf_perfEventsLsu_6_value;
  logic [5:0] io_csrio_perf_perfEventsLsu_7_value;
  logic [5:0] io_csrio_perf_perfEventsHc_0_value;
  logic [5:0] io_csrio_perf_perfEventsHc_1_value;
  logic [5:0] io_csrio_perf_perfEventsHc_2_value;
  logic [5:0] io_csrio_perf_perfEventsHc_3_value;
  logic [5:0] io_csrio_perf_perfEventsHc_4_value;
  logic [5:0] io_csrio_perf_perfEventsHc_5_value;
  logic [5:0] io_csrio_perf_perfEventsHc_6_value;
  logic [5:0] io_csrio_perf_perfEventsHc_7_value;
  logic [5:0] io_csrio_perf_perfEventsHc_8_value;
  logic [5:0] io_csrio_perf_perfEventsHc_9_value;
  logic [5:0] io_csrio_perf_perfEventsHc_10_value;
  logic [5:0] io_csrio_perf_perfEventsHc_11_value;
  logic [5:0] io_csrio_perf_perfEventsHc_12_value;
  logic [5:0] io_csrio_perf_perfEventsHc_13_value;
  logic [5:0] io_csrio_perf_perfEventsHc_14_value;
  logic [5:0] io_csrio_perf_perfEventsHc_15_value;
  logic [5:0] io_csrio_perf_perfEventsHc_16_value;
  logic [5:0] io_csrio_perf_perfEventsHc_17_value;
  logic [5:0] io_csrio_perf_perfEventsHc_18_value;
  logic [5:0] io_csrio_perf_perfEventsHc_19_value;
  logic [5:0] io_csrio_perf_perfEventsHc_20_value;
  logic [5:0] io_csrio_perf_perfEventsHc_21_value;
  logic [5:0] io_csrio_perf_perfEventsHc_22_value;
  logic [5:0] io_csrio_perf_perfEventsHc_23_value;
  logic [5:0] io_csrio_perf_perfEventsHc_24_value;
  logic [5:0] io_csrio_perf_perfEventsHc_25_value;
  logic [5:0] io_csrio_perf_perfEventsHc_26_value;
  logic [5:0] io_csrio_perf_perfEventsHc_27_value;
  logic [5:0] io_csrio_perf_perfEventsHc_28_value;
  logic [5:0] io_csrio_perf_perfEventsHc_29_value;
  logic [5:0] io_csrio_perf_perfEventsHc_30_value;
  logic [5:0] io_csrio_perf_perfEventsHc_31_value;
  logic [5:0] io_csrio_perf_perfEventsHc_32_value;
  logic [5:0] io_csrio_perf_perfEventsHc_33_value;
  logic [5:0] io_csrio_perf_perfEventsHc_34_value;
  logic [5:0] io_csrio_perf_perfEventsHc_35_value;
  logic [5:0] io_csrio_perf_perfEventsHc_36_value;
  logic [5:0] io_csrio_perf_perfEventsHc_37_value;
  logic [5:0] io_csrio_perf_perfEventsHc_38_value;
  logic [5:0] io_csrio_perf_perfEventsHc_39_value;
  logic [5:0] io_csrio_perf_perfEventsHc_40_value;
  logic [5:0] io_csrio_perf_perfEventsHc_41_value;
  logic [5:0] io_csrio_perf_perfEventsHc_42_value;
  logic [5:0] io_csrio_perf_perfEventsHc_43_value;
  logic [5:0] io_csrio_perf_perfEventsHc_44_value;
  logic [5:0] io_csrio_perf_perfEventsHc_45_value;
  logic [5:0] io_csrio_perf_perfEventsHc_46_value;
  logic [5:0] io_csrio_perf_perfEventsHc_47_value;
  logic [6:0] io_csrio_perf_retiredInstr;
  logic io_csrio_fpu_fflags_valid;
  logic [4:0] io_csrio_fpu_fflags_bits;
  logic io_csrio_fpu_dirty_fs;
  logic [63:0] io_csrio_vpu_vl;
  logic io_csrio_vpu_set_vstart_valid;
  logic [63:0] io_csrio_vpu_set_vstart_bits;
  logic io_csrio_vpu_set_vtype_valid;
  logic [63:0] io_csrio_vpu_set_vtype_bits;
  logic io_csrio_vpu_set_vxsat_valid;
  logic io_csrio_vpu_set_vxsat_bits;
  logic io_csrio_vpu_dirty_vs;
  logic io_csrio_exception_valid;
  logic [49:0] io_csrio_exception_bits_pc;
  logic io_csrio_exception_bits_exceptionVec_0;
  logic io_csrio_exception_bits_exceptionVec_1;
  logic io_csrio_exception_bits_exceptionVec_2;
  logic io_csrio_exception_bits_exceptionVec_3;
  logic io_csrio_exception_bits_exceptionVec_4;
  logic io_csrio_exception_bits_exceptionVec_5;
  logic io_csrio_exception_bits_exceptionVec_6;
  logic io_csrio_exception_bits_exceptionVec_7;
  logic io_csrio_exception_bits_exceptionVec_8;
  logic io_csrio_exception_bits_exceptionVec_9;
  logic io_csrio_exception_bits_exceptionVec_10;
  logic io_csrio_exception_bits_exceptionVec_11;
  logic io_csrio_exception_bits_exceptionVec_12;
  logic io_csrio_exception_bits_exceptionVec_13;
  logic io_csrio_exception_bits_exceptionVec_14;
  logic io_csrio_exception_bits_exceptionVec_15;
  logic io_csrio_exception_bits_exceptionVec_16;
  logic io_csrio_exception_bits_exceptionVec_17;
  logic io_csrio_exception_bits_exceptionVec_18;
  logic io_csrio_exception_bits_exceptionVec_19;
  logic io_csrio_exception_bits_exceptionVec_20;
  logic io_csrio_exception_bits_exceptionVec_21;
  logic io_csrio_exception_bits_exceptionVec_22;
  logic io_csrio_exception_bits_exceptionVec_23;
  logic io_csrio_exception_bits_isPcBkpt;
  logic io_csrio_exception_bits_isFetchMalAddr;
  logic [63:0] io_csrio_exception_bits_gpaddr;
  logic io_csrio_exception_bits_singleStep;
  logic io_csrio_exception_bits_crossPageIPFFix;
  logic io_csrio_exception_bits_isInterrupt;
  logic io_csrio_exception_bits_isHls;
  logic [3:0] io_csrio_exception_bits_trigger;
  logic io_csrio_exception_bits_isForVSnonLeafPTE;
  logic io_csrio_robDeqPtr_flag;
  logic [7:0] io_csrio_robDeqPtr_value;
  logic [63:0] io_csrio_memExceptionVAddr;
  logic [63:0] io_csrio_memExceptionGPAddr;
  logic io_csrio_memExceptionIsForVSnonLeafPTE;
  logic io_csrio_externalInterrupt_mtip;
  logic io_csrio_externalInterrupt_msip;
  logic io_csrio_externalInterrupt_meip;
  logic io_csrio_externalInterrupt_seip;
  logic io_csrio_externalInterrupt_debug;
  logic io_csrio_externalInterrupt_nmi_nmi_31;
  logic io_csrio_externalInterrupt_nmi_nmi_43;

  logic g_io_in_ready;
  logic i_io_in_ready;
  logic g_io_out_valid;
  logic i_io_out_valid;
  logic g_io_out_bits_ctrl_robIdx_flag;
  logic i_io_out_bits_ctrl_robIdx_flag;
  logic [7:0] g_io_out_bits_ctrl_robIdx_value;
  logic [7:0] i_io_out_bits_ctrl_robIdx_value;
  logic [7:0] g_io_out_bits_ctrl_pdest;
  logic [7:0] i_io_out_bits_ctrl_pdest;
  logic g_io_out_bits_ctrl_rfWen;
  logic i_io_out_bits_ctrl_rfWen;
  logic g_io_out_bits_ctrl_exceptionVec_2;
  logic i_io_out_bits_ctrl_exceptionVec_2;
  logic g_io_out_bits_ctrl_exceptionVec_3;
  logic i_io_out_bits_ctrl_exceptionVec_3;
  logic g_io_out_bits_ctrl_exceptionVec_8;
  logic i_io_out_bits_ctrl_exceptionVec_8;
  logic g_io_out_bits_ctrl_exceptionVec_9;
  logic i_io_out_bits_ctrl_exceptionVec_9;
  logic g_io_out_bits_ctrl_exceptionVec_10;
  logic i_io_out_bits_ctrl_exceptionVec_10;
  logic g_io_out_bits_ctrl_exceptionVec_11;
  logic i_io_out_bits_ctrl_exceptionVec_11;
  logic g_io_out_bits_ctrl_exceptionVec_22;
  logic i_io_out_bits_ctrl_exceptionVec_22;
  logic g_io_out_bits_ctrl_flushPipe;
  logic i_io_out_bits_ctrl_flushPipe;
  logic [63:0] g_io_out_bits_res_data;
  logic [63:0] i_io_out_bits_res_data;
  logic g_io_out_bits_res_redirect_valid;
  logic i_io_out_bits_res_redirect_valid;
  logic g_io_out_bits_res_redirect_bits_isRVC;
  logic i_io_out_bits_res_redirect_bits_isRVC;
  logic g_io_out_bits_res_redirect_bits_robIdx_flag;
  logic i_io_out_bits_res_redirect_bits_robIdx_flag;
  logic [7:0] g_io_out_bits_res_redirect_bits_robIdx_value;
  logic [7:0] i_io_out_bits_res_redirect_bits_robIdx_value;
  logic g_io_out_bits_res_redirect_bits_ftqIdx_flag;
  logic i_io_out_bits_res_redirect_bits_ftqIdx_flag;
  logic [5:0] g_io_out_bits_res_redirect_bits_ftqIdx_value;
  logic [5:0] i_io_out_bits_res_redirect_bits_ftqIdx_value;
  logic [3:0] g_io_out_bits_res_redirect_bits_ftqOffset;
  logic [3:0] i_io_out_bits_res_redirect_bits_ftqOffset;
  logic g_io_out_bits_res_redirect_bits_level;
  logic i_io_out_bits_res_redirect_bits_level;
  logic g_io_out_bits_res_redirect_bits_interrupt;
  logic i_io_out_bits_res_redirect_bits_interrupt;
  logic [49:0] g_io_out_bits_res_redirect_bits_cfiUpdate_pc;
  logic [49:0] i_io_out_bits_res_redirect_bits_cfiUpdate_pc;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_pd_valid;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_pd_valid;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC;
  logic [1:0] g_io_out_bits_res_redirect_bits_cfiUpdate_pd_brType;
  logic [1:0] i_io_out_bits_res_redirect_bits_cfiUpdate_pd_brType;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet;
  logic [3:0] g_io_out_bits_res_redirect_bits_cfiUpdate_ssp;
  logic [3:0] i_io_out_bits_res_redirect_bits_cfiUpdate_ssp;
  logic [2:0] g_io_out_bits_res_redirect_bits_cfiUpdate_sctr;
  logic [2:0] i_io_out_bits_res_redirect_bits_cfiUpdate_sctr;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag;
  logic [4:0] g_io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value;
  logic [4:0] i_io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag;
  logic [4:0] g_io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value;
  logic [4:0] i_io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag;
  logic [4:0] g_io_out_bits_res_redirect_bits_cfiUpdate_NOS_value;
  logic [4:0] i_io_out_bits_res_redirect_bits_cfiUpdate_NOS_value;
  logic [49:0] g_io_out_bits_res_redirect_bits_cfiUpdate_topAddr;
  logic [49:0] i_io_out_bits_res_redirect_bits_cfiUpdate_topAddr;
  logic [10:0] g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist;
  logic [10:0] i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist;
  logic [10:0] g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist;
  logic [10:0] i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist;
  logic [6:0] g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist;
  logic [6:0] i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist;
  logic [7:0] g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist;
  logic [7:0] i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist;
  logic [8:0] g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist;
  logic [8:0] i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist;
  logic [3:0] g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist;
  logic [3:0] i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist;
  logic [7:0] g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist;
  logic [7:0] i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist;
  logic [8:0] g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist;
  logic [8:0] i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist;
  logic [6:0] g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist;
  logic [6:0] i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist;
  logic [7:0] g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist;
  logic [7:0] i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist;
  logic [6:0] g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist;
  logic [6:0] i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist;
  logic [8:0] g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist;
  logic [8:0] i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist;
  logic [6:0] g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist;
  logic [6:0] i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist;
  logic [7:0] g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist;
  logic [7:0] i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist;
  logic [7:0] g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist;
  logic [7:0] i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist;
  logic [7:0] g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist;
  logic [7:0] i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist;
  logic [10:0] g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist;
  logic [10:0] i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist;
  logic [7:0] g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist;
  logic [7:0] i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3;
  logic [2:0] g_io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH;
  logic [2:0] i_io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH;
  logic [3:0] g_io_out_bits_res_redirect_bits_cfiUpdate_ghr;
  logic [3:0] i_io_out_bits_res_redirect_bits_cfiUpdate_ghr;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag;
  logic [7:0] g_io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value;
  logic [7:0] i_io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value;
  logic [9:0] g_io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0;
  logic [9:0] i_io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0;
  logic [9:0] g_io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1;
  logic [9:0] i_io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_br_hit;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_br_hit;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_jr_hit;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_jr_hit;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_sc_hit;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_sc_hit;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_predTaken;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_predTaken;
  logic [49:0] g_io_out_bits_res_redirect_bits_cfiUpdate_target;
  logic [49:0] i_io_out_bits_res_redirect_bits_cfiUpdate_target;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_taken;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_taken;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_isMisPred;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_isMisPred;
  logic [1:0] g_io_out_bits_res_redirect_bits_cfiUpdate_shift;
  logic [1:0] i_io_out_bits_res_redirect_bits_cfiUpdate_shift;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_backendIPF;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_backendIPF;
  logic g_io_out_bits_res_redirect_bits_cfiUpdate_backendIAF;
  logic i_io_out_bits_res_redirect_bits_cfiUpdate_backendIAF;
  logic [63:0] g_io_out_bits_res_redirect_bits_fullTarget;
  logic [63:0] i_io_out_bits_res_redirect_bits_fullTarget;
  logic g_io_out_bits_res_redirect_bits_stFtqIdx_flag;
  logic i_io_out_bits_res_redirect_bits_stFtqIdx_flag;
  logic [5:0] g_io_out_bits_res_redirect_bits_stFtqIdx_value;
  logic [5:0] i_io_out_bits_res_redirect_bits_stFtqIdx_value;
  logic [3:0] g_io_out_bits_res_redirect_bits_stFtqOffset;
  logic [3:0] i_io_out_bits_res_redirect_bits_stFtqOffset;
  logic [63:0] g_io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id;
  logic [63:0] i_io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id;
  logic g_io_out_bits_res_redirect_bits_debugIsCtrl;
  logic i_io_out_bits_res_redirect_bits_debugIsCtrl;
  logic g_io_out_bits_res_redirect_bits_debugIsMemVio;
  logic i_io_out_bits_res_redirect_bits_debugIsMemVio;
  logic [63:0] g_io_out_bits_perfDebugInfo_enqRsTime;
  logic [63:0] i_io_out_bits_perfDebugInfo_enqRsTime;
  logic [63:0] g_io_out_bits_perfDebugInfo_selectTime;
  logic [63:0] i_io_out_bits_perfDebugInfo_selectTime;
  logic [63:0] g_io_out_bits_perfDebugInfo_issueTime;
  logic [63:0] i_io_out_bits_perfDebugInfo_issueTime;
  logic g_io_csrio_criticalErrorState;
  logic i_io_csrio_criticalErrorState;
  logic g_io_csrio_isPerfCnt;
  logic i_io_csrio_isPerfCnt;
  logic [2:0] g_io_csrio_fpu_frm;
  logic [2:0] i_io_csrio_fpu_frm;
  logic [63:0] g_io_csrio_vpu_vstart;
  logic [63:0] i_io_csrio_vpu_vstart;
  logic [1:0] g_io_csrio_vpu_vxrm;
  logic [1:0] i_io_csrio_vpu_vxrm;
  logic [63:0] g_io_csrio_trapTarget_pc;
  logic [63:0] i_io_csrio_trapTarget_pc;
  logic g_io_csrio_trapTarget_raiseIPF;
  logic i_io_csrio_trapTarget_raiseIPF;
  logic g_io_csrio_trapTarget_raiseIAF;
  logic i_io_csrio_trapTarget_raiseIAF;
  logic g_io_csrio_trapTarget_raiseIGPF;
  logic i_io_csrio_trapTarget_raiseIGPF;
  logic g_io_csrio_interrupt;
  logic i_io_csrio_interrupt;
  logic g_io_csrio_wfi_event;
  logic i_io_csrio_wfi_event;
  logic [63:0] g_io_csrio_traceCSR_cause;
  logic [63:0] i_io_csrio_traceCSR_cause;
  logic [49:0] g_io_csrio_traceCSR_tval;
  logic [49:0] i_io_csrio_traceCSR_tval;
  logic [2:0] g_io_csrio_traceCSR_lastPriv;
  logic [2:0] i_io_csrio_traceCSR_lastPriv;
  logic [2:0] g_io_csrio_traceCSR_currentPriv;
  logic [2:0] i_io_csrio_traceCSR_currentPriv;
  logic [3:0] g_io_csrio_tlb_satp_mode;
  logic [3:0] i_io_csrio_tlb_satp_mode;
  logic [15:0] g_io_csrio_tlb_satp_asid;
  logic [15:0] i_io_csrio_tlb_satp_asid;
  logic [43:0] g_io_csrio_tlb_satp_ppn;
  logic [43:0] i_io_csrio_tlb_satp_ppn;
  logic g_io_csrio_tlb_satp_changed;
  logic i_io_csrio_tlb_satp_changed;
  logic [3:0] g_io_csrio_tlb_vsatp_mode;
  logic [3:0] i_io_csrio_tlb_vsatp_mode;
  logic [15:0] g_io_csrio_tlb_vsatp_asid;
  logic [15:0] i_io_csrio_tlb_vsatp_asid;
  logic [43:0] g_io_csrio_tlb_vsatp_ppn;
  logic [43:0] i_io_csrio_tlb_vsatp_ppn;
  logic g_io_csrio_tlb_vsatp_changed;
  logic i_io_csrio_tlb_vsatp_changed;
  logic [3:0] g_io_csrio_tlb_hgatp_mode;
  logic [3:0] i_io_csrio_tlb_hgatp_mode;
  logic [15:0] g_io_csrio_tlb_hgatp_vmid;
  logic [15:0] i_io_csrio_tlb_hgatp_vmid;
  logic [43:0] g_io_csrio_tlb_hgatp_ppn;
  logic [43:0] i_io_csrio_tlb_hgatp_ppn;
  logic g_io_csrio_tlb_hgatp_changed;
  logic i_io_csrio_tlb_hgatp_changed;
  logic g_io_csrio_tlb_priv_mxr;
  logic i_io_csrio_tlb_priv_mxr;
  logic g_io_csrio_tlb_priv_sum;
  logic i_io_csrio_tlb_priv_sum;
  logic g_io_csrio_tlb_priv_vmxr;
  logic i_io_csrio_tlb_priv_vmxr;
  logic g_io_csrio_tlb_priv_vsum;
  logic i_io_csrio_tlb_priv_vsum;
  logic g_io_csrio_tlb_priv_virt;
  logic i_io_csrio_tlb_priv_virt;
  logic g_io_csrio_tlb_priv_spvp;
  logic i_io_csrio_tlb_priv_spvp;
  logic [1:0] g_io_csrio_tlb_priv_imode;
  logic [1:0] i_io_csrio_tlb_priv_imode;
  logic [1:0] g_io_csrio_tlb_priv_dmode;
  logic [1:0] i_io_csrio_tlb_priv_dmode;
  logic g_io_csrio_tlb_mPBMTE;
  logic i_io_csrio_tlb_mPBMTE;
  logic g_io_csrio_tlb_hPBMTE;
  logic i_io_csrio_tlb_hPBMTE;
  logic [1:0] g_io_csrio_tlb_pmm_mseccfg;
  logic [1:0] i_io_csrio_tlb_pmm_mseccfg;
  logic [1:0] g_io_csrio_tlb_pmm_menvcfg;
  logic [1:0] i_io_csrio_tlb_pmm_menvcfg;
  logic [1:0] g_io_csrio_tlb_pmm_henvcfg;
  logic [1:0] i_io_csrio_tlb_pmm_henvcfg;
  logic [1:0] g_io_csrio_tlb_pmm_hstatus;
  logic [1:0] i_io_csrio_tlb_pmm_hstatus;
  logic [1:0] g_io_csrio_tlb_pmm_senvcfg;
  logic [1:0] i_io_csrio_tlb_pmm_senvcfg;
  logic g_io_csrio_customCtrl_pf_ctrl_l1I_pf_enable;
  logic i_io_csrio_customCtrl_pf_ctrl_l1I_pf_enable;
  logic g_io_csrio_customCtrl_pf_ctrl_l2_pf_enable;
  logic i_io_csrio_customCtrl_pf_ctrl_l2_pf_enable;
  logic g_io_csrio_customCtrl_pf_ctrl_l1D_pf_enable;
  logic i_io_csrio_customCtrl_pf_ctrl_l1D_pf_enable;
  logic g_io_csrio_customCtrl_pf_ctrl_l1D_pf_train_on_hit;
  logic i_io_csrio_customCtrl_pf_ctrl_l1D_pf_train_on_hit;
  logic g_io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_agt;
  logic i_io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_agt;
  logic g_io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_pht;
  logic i_io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_pht;
  logic [3:0] g_io_csrio_customCtrl_pf_ctrl_l1D_pf_active_threshold;
  logic [3:0] i_io_csrio_customCtrl_pf_ctrl_l1D_pf_active_threshold;
  logic [5:0] g_io_csrio_customCtrl_pf_ctrl_l1D_pf_active_stride;
  logic [5:0] i_io_csrio_customCtrl_pf_ctrl_l1D_pf_active_stride;
  logic g_io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_stride;
  logic i_io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_stride;
  logic g_io_csrio_customCtrl_pf_ctrl_l2_pf_store_only;
  logic i_io_csrio_customCtrl_pf_ctrl_l2_pf_store_only;
  logic g_io_csrio_customCtrl_pf_ctrl_l2_pf_recv_enable;
  logic i_io_csrio_customCtrl_pf_ctrl_l2_pf_recv_enable;
  logic g_io_csrio_customCtrl_pf_ctrl_l2_pf_pbop_enable;
  logic i_io_csrio_customCtrl_pf_ctrl_l2_pf_pbop_enable;
  logic g_io_csrio_customCtrl_pf_ctrl_l2_pf_vbop_enable;
  logic i_io_csrio_customCtrl_pf_ctrl_l2_pf_vbop_enable;
  logic [4:0] g_io_csrio_customCtrl_lvpred_timeout;
  logic [4:0] i_io_csrio_customCtrl_lvpred_timeout;
  logic g_io_csrio_customCtrl_bp_ctrl_ubtb_enable;
  logic i_io_csrio_customCtrl_bp_ctrl_ubtb_enable;
  logic g_io_csrio_customCtrl_bp_ctrl_btb_enable;
  logic i_io_csrio_customCtrl_bp_ctrl_btb_enable;
  logic g_io_csrio_customCtrl_bp_ctrl_tage_enable;
  logic i_io_csrio_customCtrl_bp_ctrl_tage_enable;
  logic g_io_csrio_customCtrl_bp_ctrl_sc_enable;
  logic i_io_csrio_customCtrl_bp_ctrl_sc_enable;
  logic g_io_csrio_customCtrl_bp_ctrl_ras_enable;
  logic i_io_csrio_customCtrl_bp_ctrl_ras_enable;
  logic g_io_csrio_customCtrl_ldld_vio_check_enable;
  logic i_io_csrio_customCtrl_ldld_vio_check_enable;
  logic g_io_csrio_customCtrl_cache_error_enable;
  logic i_io_csrio_customCtrl_cache_error_enable;
  logic g_io_csrio_customCtrl_uncache_write_outstanding_enable;
  logic i_io_csrio_customCtrl_uncache_write_outstanding_enable;
  logic g_io_csrio_customCtrl_hd_misalign_st_enable;
  logic i_io_csrio_customCtrl_hd_misalign_st_enable;
  logic g_io_csrio_customCtrl_hd_misalign_ld_enable;
  logic i_io_csrio_customCtrl_hd_misalign_ld_enable;
  logic g_io_csrio_customCtrl_power_down_enable;
  logic i_io_csrio_customCtrl_power_down_enable;
  logic g_io_csrio_customCtrl_flush_l2_enable;
  logic i_io_csrio_customCtrl_flush_l2_enable;
  logic g_io_csrio_customCtrl_fusion_enable;
  logic i_io_csrio_customCtrl_fusion_enable;
  logic g_io_csrio_customCtrl_wfi_enable;
  logic i_io_csrio_customCtrl_wfi_enable;
  logic g_io_csrio_customCtrl_distribute_csr_w_valid;
  logic i_io_csrio_customCtrl_distribute_csr_w_valid;
  logic [11:0] g_io_csrio_customCtrl_distribute_csr_w_bits_addr;
  logic [11:0] i_io_csrio_customCtrl_distribute_csr_w_bits_addr;
  logic [63:0] g_io_csrio_customCtrl_distribute_csr_w_bits_data;
  logic [63:0] i_io_csrio_customCtrl_distribute_csr_w_bits_data;
  logic g_io_csrio_customCtrl_singlestep;
  logic i_io_csrio_customCtrl_singlestep;
  logic g_io_csrio_customCtrl_frontend_trigger_tUpdate_valid;
  logic i_io_csrio_customCtrl_frontend_trigger_tUpdate_valid;
  logic [1:0] g_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_addr;
  logic [1:0] i_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_addr;
  logic [1:0] g_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_matchType;
  logic [1:0] i_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_matchType;
  logic g_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_select;
  logic i_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_select;
  logic [3:0] g_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_action;
  logic [3:0] i_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_action;
  logic g_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_chain;
  logic i_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_chain;
  logic [63:0] g_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_tdata2;
  logic [63:0] i_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_tdata2;
  logic g_io_csrio_customCtrl_frontend_trigger_tEnableVec_0;
  logic i_io_csrio_customCtrl_frontend_trigger_tEnableVec_0;
  logic g_io_csrio_customCtrl_frontend_trigger_tEnableVec_1;
  logic i_io_csrio_customCtrl_frontend_trigger_tEnableVec_1;
  logic g_io_csrio_customCtrl_frontend_trigger_tEnableVec_2;
  logic i_io_csrio_customCtrl_frontend_trigger_tEnableVec_2;
  logic g_io_csrio_customCtrl_frontend_trigger_tEnableVec_3;
  logic i_io_csrio_customCtrl_frontend_trigger_tEnableVec_3;
  logic g_io_csrio_customCtrl_frontend_trigger_debugMode;
  logic i_io_csrio_customCtrl_frontend_trigger_debugMode;
  logic g_io_csrio_customCtrl_frontend_trigger_triggerCanRaiseBpExp;
  logic i_io_csrio_customCtrl_frontend_trigger_triggerCanRaiseBpExp;
  logic g_io_csrio_customCtrl_mem_trigger_tUpdate_valid;
  logic i_io_csrio_customCtrl_mem_trigger_tUpdate_valid;
  logic [1:0] g_io_csrio_customCtrl_mem_trigger_tUpdate_bits_addr;
  logic [1:0] i_io_csrio_customCtrl_mem_trigger_tUpdate_bits_addr;
  logic [1:0] g_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_matchType;
  logic [1:0] i_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_matchType;
  logic g_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_select;
  logic i_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_select;
  logic [3:0] g_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_action;
  logic [3:0] i_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_action;
  logic g_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_chain;
  logic i_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_chain;
  logic g_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_store;
  logic i_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_store;
  logic g_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_load;
  logic i_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_load;
  logic [63:0] g_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_tdata2;
  logic [63:0] i_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_tdata2;
  logic g_io_csrio_customCtrl_mem_trigger_tEnableVec_0;
  logic i_io_csrio_customCtrl_mem_trigger_tEnableVec_0;
  logic g_io_csrio_customCtrl_mem_trigger_tEnableVec_1;
  logic i_io_csrio_customCtrl_mem_trigger_tEnableVec_1;
  logic g_io_csrio_customCtrl_mem_trigger_tEnableVec_2;
  logic i_io_csrio_customCtrl_mem_trigger_tEnableVec_2;
  logic g_io_csrio_customCtrl_mem_trigger_tEnableVec_3;
  logic i_io_csrio_customCtrl_mem_trigger_tEnableVec_3;
  logic g_io_csrio_customCtrl_mem_trigger_debugMode;
  logic i_io_csrio_customCtrl_mem_trigger_debugMode;
  logic g_io_csrio_customCtrl_mem_trigger_triggerCanRaiseBpExp;
  logic i_io_csrio_customCtrl_mem_trigger_triggerCanRaiseBpExp;
  logic g_io_csrio_customCtrl_fsIsOff;
  logic i_io_csrio_customCtrl_fsIsOff;
  logic g_io_csrio_instrAddrTransType_bare;
  logic i_io_csrio_instrAddrTransType_bare;
  logic g_io_csrio_instrAddrTransType_sv39;
  logic i_io_csrio_instrAddrTransType_sv39;
  logic g_io_csrio_instrAddrTransType_sv39x4;
  logic i_io_csrio_instrAddrTransType_sv39x4;
  logic g_io_csrio_instrAddrTransType_sv48;
  logic i_io_csrio_instrAddrTransType_sv48;
  logic g_io_csrio_instrAddrTransType_sv48x4;
  logic i_io_csrio_instrAddrTransType_sv48x4;
  logic g_io_csrToDecode_illegalInst_sfenceVMA;
  logic i_io_csrToDecode_illegalInst_sfenceVMA;
  logic g_io_csrToDecode_illegalInst_sfencePart;
  logic i_io_csrToDecode_illegalInst_sfencePart;
  logic g_io_csrToDecode_illegalInst_hfenceGVMA;
  logic i_io_csrToDecode_illegalInst_hfenceGVMA;
  logic g_io_csrToDecode_illegalInst_hfenceVVMA;
  logic i_io_csrToDecode_illegalInst_hfenceVVMA;
  logic g_io_csrToDecode_illegalInst_hlsv;
  logic i_io_csrToDecode_illegalInst_hlsv;
  logic g_io_csrToDecode_illegalInst_fsIsOff;
  logic i_io_csrToDecode_illegalInst_fsIsOff;
  logic g_io_csrToDecode_illegalInst_vsIsOff;
  logic i_io_csrToDecode_illegalInst_vsIsOff;
  logic g_io_csrToDecode_illegalInst_wfi;
  logic i_io_csrToDecode_illegalInst_wfi;
  logic g_io_csrToDecode_illegalInst_wrs_nto;
  logic i_io_csrToDecode_illegalInst_wrs_nto;
  logic g_io_csrToDecode_illegalInst_frm;
  logic i_io_csrToDecode_illegalInst_frm;
  logic g_io_csrToDecode_illegalInst_cboZ;
  logic i_io_csrToDecode_illegalInst_cboZ;
  logic g_io_csrToDecode_illegalInst_cboCF;
  logic i_io_csrToDecode_illegalInst_cboCF;
  logic g_io_csrToDecode_illegalInst_cboI;
  logic i_io_csrToDecode_illegalInst_cboI;
  logic g_io_csrToDecode_virtualInst_sfenceVMA;
  logic i_io_csrToDecode_virtualInst_sfenceVMA;
  logic g_io_csrToDecode_virtualInst_sfencePart;
  logic i_io_csrToDecode_virtualInst_sfencePart;
  logic g_io_csrToDecode_virtualInst_hfence;
  logic i_io_csrToDecode_virtualInst_hfence;
  logic g_io_csrToDecode_virtualInst_hlsv;
  logic i_io_csrToDecode_virtualInst_hlsv;
  logic g_io_csrToDecode_virtualInst_wfi;
  logic i_io_csrToDecode_virtualInst_wfi;
  logic g_io_csrToDecode_virtualInst_wrs_nto;
  logic i_io_csrToDecode_virtualInst_wrs_nto;
  logic g_io_csrToDecode_virtualInst_cboZ;
  logic i_io_csrToDecode_virtualInst_cboZ;
  logic g_io_csrToDecode_virtualInst_cboCF;
  logic i_io_csrToDecode_virtualInst_cboCF;
  logic g_io_csrToDecode_virtualInst_cboI;
  logic i_io_csrToDecode_virtualInst_cboI;
  logic g_io_csrToDecode_special_cboI2F;
  logic i_io_csrToDecode_special_cboI2F;
  logic g_io_error_0;
  logic i_io_error_0;

  CSR u_g (
    .clock(clk),
    .reset(rst),
    .io_flush_valid(io_flush_valid),
    .io_flush_bits_robIdx_flag(io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value(io_flush_bits_robIdx_value),
    .io_flush_bits_ftqIdx_flag(io_flush_bits_ftqIdx_flag),
    .io_flush_bits_ftqIdx_value(io_flush_bits_ftqIdx_value),
    .io_flush_bits_ftqOffset(io_flush_bits_ftqOffset),
    .io_flush_bits_level(io_flush_bits_level),
    .io_flush_bits_cfiUpdate_backendIGPF(io_flush_bits_cfiUpdate_backendIGPF),
    .io_flush_bits_cfiUpdate_backendIPF(io_flush_bits_cfiUpdate_backendIPF),
    .io_flush_bits_cfiUpdate_backendIAF(io_flush_bits_cfiUpdate_backendIAF),
    .io_flush_bits_fullTarget(io_flush_bits_fullTarget),
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_robIdx_flag(io_in_bits_ctrl_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value(io_in_bits_ctrl_robIdx_value),
    .io_in_bits_ctrl_pdest(io_in_bits_ctrl_pdest),
    .io_in_bits_ctrl_rfWen(io_in_bits_ctrl_rfWen),
    .io_in_bits_ctrl_ftqIdx_flag(io_in_bits_ctrl_ftqIdx_flag),
    .io_in_bits_ctrl_ftqIdx_value(io_in_bits_ctrl_ftqIdx_value),
    .io_in_bits_ctrl_ftqOffset(io_in_bits_ctrl_ftqOffset),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_data_imm(io_in_bits_data_imm),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_out_ready(io_out_ready),
    .io_csrin_hartId(io_csrin_hartId),
    .io_csrin_msiInfo_valid(io_csrin_msiInfo_valid),
    .io_csrin_msiInfo_bits(io_csrin_msiInfo_bits),
    .io_csrin_criticalErrorState(io_csrin_criticalErrorState),
    .io_csrin_clintTime_valid(io_csrin_clintTime_valid),
    .io_csrin_clintTime_bits(io_csrin_clintTime_bits),
    .io_csrin_l2FlushDone(io_csrin_l2FlushDone),
    .io_csrin_trapInstInfo_valid(io_csrin_trapInstInfo_valid),
    .io_csrin_trapInstInfo_bits_instr(io_csrin_trapInstInfo_bits_instr),
    .io_csrin_trapInstInfo_bits_ftqPtr_flag(io_csrin_trapInstInfo_bits_ftqPtr_flag),
    .io_csrin_trapInstInfo_bits_ftqPtr_value(io_csrin_trapInstInfo_bits_ftqPtr_value),
    .io_csrin_trapInstInfo_bits_ftqOffset(io_csrin_trapInstInfo_bits_ftqOffset),
    .io_csrin_fromVecExcpMod_busy(io_csrin_fromVecExcpMod_busy),
    .io_csrio_perf_perfEventsFrontend_0_value(io_csrio_perf_perfEventsFrontend_0_value),
    .io_csrio_perf_perfEventsFrontend_1_value(io_csrio_perf_perfEventsFrontend_1_value),
    .io_csrio_perf_perfEventsFrontend_2_value(io_csrio_perf_perfEventsFrontend_2_value),
    .io_csrio_perf_perfEventsFrontend_3_value(io_csrio_perf_perfEventsFrontend_3_value),
    .io_csrio_perf_perfEventsFrontend_4_value(io_csrio_perf_perfEventsFrontend_4_value),
    .io_csrio_perf_perfEventsFrontend_5_value(io_csrio_perf_perfEventsFrontend_5_value),
    .io_csrio_perf_perfEventsFrontend_6_value(io_csrio_perf_perfEventsFrontend_6_value),
    .io_csrio_perf_perfEventsFrontend_7_value(io_csrio_perf_perfEventsFrontend_7_value),
    .io_csrio_perf_perfEventsBackend_0_value(io_csrio_perf_perfEventsBackend_0_value),
    .io_csrio_perf_perfEventsBackend_1_value(io_csrio_perf_perfEventsBackend_1_value),
    .io_csrio_perf_perfEventsBackend_2_value(io_csrio_perf_perfEventsBackend_2_value),
    .io_csrio_perf_perfEventsBackend_3_value(io_csrio_perf_perfEventsBackend_3_value),
    .io_csrio_perf_perfEventsBackend_4_value(io_csrio_perf_perfEventsBackend_4_value),
    .io_csrio_perf_perfEventsBackend_5_value(io_csrio_perf_perfEventsBackend_5_value),
    .io_csrio_perf_perfEventsBackend_6_value(io_csrio_perf_perfEventsBackend_6_value),
    .io_csrio_perf_perfEventsBackend_7_value(io_csrio_perf_perfEventsBackend_7_value),
    .io_csrio_perf_perfEventsLsu_0_value(io_csrio_perf_perfEventsLsu_0_value),
    .io_csrio_perf_perfEventsLsu_1_value(io_csrio_perf_perfEventsLsu_1_value),
    .io_csrio_perf_perfEventsLsu_2_value(io_csrio_perf_perfEventsLsu_2_value),
    .io_csrio_perf_perfEventsLsu_3_value(io_csrio_perf_perfEventsLsu_3_value),
    .io_csrio_perf_perfEventsLsu_4_value(io_csrio_perf_perfEventsLsu_4_value),
    .io_csrio_perf_perfEventsLsu_5_value(io_csrio_perf_perfEventsLsu_5_value),
    .io_csrio_perf_perfEventsLsu_6_value(io_csrio_perf_perfEventsLsu_6_value),
    .io_csrio_perf_perfEventsLsu_7_value(io_csrio_perf_perfEventsLsu_7_value),
    .io_csrio_perf_perfEventsHc_0_value(io_csrio_perf_perfEventsHc_0_value),
    .io_csrio_perf_perfEventsHc_1_value(io_csrio_perf_perfEventsHc_1_value),
    .io_csrio_perf_perfEventsHc_2_value(io_csrio_perf_perfEventsHc_2_value),
    .io_csrio_perf_perfEventsHc_3_value(io_csrio_perf_perfEventsHc_3_value),
    .io_csrio_perf_perfEventsHc_4_value(io_csrio_perf_perfEventsHc_4_value),
    .io_csrio_perf_perfEventsHc_5_value(io_csrio_perf_perfEventsHc_5_value),
    .io_csrio_perf_perfEventsHc_6_value(io_csrio_perf_perfEventsHc_6_value),
    .io_csrio_perf_perfEventsHc_7_value(io_csrio_perf_perfEventsHc_7_value),
    .io_csrio_perf_perfEventsHc_8_value(io_csrio_perf_perfEventsHc_8_value),
    .io_csrio_perf_perfEventsHc_9_value(io_csrio_perf_perfEventsHc_9_value),
    .io_csrio_perf_perfEventsHc_10_value(io_csrio_perf_perfEventsHc_10_value),
    .io_csrio_perf_perfEventsHc_11_value(io_csrio_perf_perfEventsHc_11_value),
    .io_csrio_perf_perfEventsHc_12_value(io_csrio_perf_perfEventsHc_12_value),
    .io_csrio_perf_perfEventsHc_13_value(io_csrio_perf_perfEventsHc_13_value),
    .io_csrio_perf_perfEventsHc_14_value(io_csrio_perf_perfEventsHc_14_value),
    .io_csrio_perf_perfEventsHc_15_value(io_csrio_perf_perfEventsHc_15_value),
    .io_csrio_perf_perfEventsHc_16_value(io_csrio_perf_perfEventsHc_16_value),
    .io_csrio_perf_perfEventsHc_17_value(io_csrio_perf_perfEventsHc_17_value),
    .io_csrio_perf_perfEventsHc_18_value(io_csrio_perf_perfEventsHc_18_value),
    .io_csrio_perf_perfEventsHc_19_value(io_csrio_perf_perfEventsHc_19_value),
    .io_csrio_perf_perfEventsHc_20_value(io_csrio_perf_perfEventsHc_20_value),
    .io_csrio_perf_perfEventsHc_21_value(io_csrio_perf_perfEventsHc_21_value),
    .io_csrio_perf_perfEventsHc_22_value(io_csrio_perf_perfEventsHc_22_value),
    .io_csrio_perf_perfEventsHc_23_value(io_csrio_perf_perfEventsHc_23_value),
    .io_csrio_perf_perfEventsHc_24_value(io_csrio_perf_perfEventsHc_24_value),
    .io_csrio_perf_perfEventsHc_25_value(io_csrio_perf_perfEventsHc_25_value),
    .io_csrio_perf_perfEventsHc_26_value(io_csrio_perf_perfEventsHc_26_value),
    .io_csrio_perf_perfEventsHc_27_value(io_csrio_perf_perfEventsHc_27_value),
    .io_csrio_perf_perfEventsHc_28_value(io_csrio_perf_perfEventsHc_28_value),
    .io_csrio_perf_perfEventsHc_29_value(io_csrio_perf_perfEventsHc_29_value),
    .io_csrio_perf_perfEventsHc_30_value(io_csrio_perf_perfEventsHc_30_value),
    .io_csrio_perf_perfEventsHc_31_value(io_csrio_perf_perfEventsHc_31_value),
    .io_csrio_perf_perfEventsHc_32_value(io_csrio_perf_perfEventsHc_32_value),
    .io_csrio_perf_perfEventsHc_33_value(io_csrio_perf_perfEventsHc_33_value),
    .io_csrio_perf_perfEventsHc_34_value(io_csrio_perf_perfEventsHc_34_value),
    .io_csrio_perf_perfEventsHc_35_value(io_csrio_perf_perfEventsHc_35_value),
    .io_csrio_perf_perfEventsHc_36_value(io_csrio_perf_perfEventsHc_36_value),
    .io_csrio_perf_perfEventsHc_37_value(io_csrio_perf_perfEventsHc_37_value),
    .io_csrio_perf_perfEventsHc_38_value(io_csrio_perf_perfEventsHc_38_value),
    .io_csrio_perf_perfEventsHc_39_value(io_csrio_perf_perfEventsHc_39_value),
    .io_csrio_perf_perfEventsHc_40_value(io_csrio_perf_perfEventsHc_40_value),
    .io_csrio_perf_perfEventsHc_41_value(io_csrio_perf_perfEventsHc_41_value),
    .io_csrio_perf_perfEventsHc_42_value(io_csrio_perf_perfEventsHc_42_value),
    .io_csrio_perf_perfEventsHc_43_value(io_csrio_perf_perfEventsHc_43_value),
    .io_csrio_perf_perfEventsHc_44_value(io_csrio_perf_perfEventsHc_44_value),
    .io_csrio_perf_perfEventsHc_45_value(io_csrio_perf_perfEventsHc_45_value),
    .io_csrio_perf_perfEventsHc_46_value(io_csrio_perf_perfEventsHc_46_value),
    .io_csrio_perf_perfEventsHc_47_value(io_csrio_perf_perfEventsHc_47_value),
    .io_csrio_perf_retiredInstr(io_csrio_perf_retiredInstr),
    .io_csrio_fpu_fflags_valid(io_csrio_fpu_fflags_valid),
    .io_csrio_fpu_fflags_bits(io_csrio_fpu_fflags_bits),
    .io_csrio_fpu_dirty_fs(io_csrio_fpu_dirty_fs),
    .io_csrio_vpu_vl(io_csrio_vpu_vl),
    .io_csrio_vpu_set_vstart_valid(io_csrio_vpu_set_vstart_valid),
    .io_csrio_vpu_set_vstart_bits(io_csrio_vpu_set_vstart_bits),
    .io_csrio_vpu_set_vtype_valid(io_csrio_vpu_set_vtype_valid),
    .io_csrio_vpu_set_vtype_bits(io_csrio_vpu_set_vtype_bits),
    .io_csrio_vpu_set_vxsat_valid(io_csrio_vpu_set_vxsat_valid),
    .io_csrio_vpu_set_vxsat_bits(io_csrio_vpu_set_vxsat_bits),
    .io_csrio_vpu_dirty_vs(io_csrio_vpu_dirty_vs),
    .io_csrio_exception_valid(io_csrio_exception_valid),
    .io_csrio_exception_bits_pc(io_csrio_exception_bits_pc),
    .io_csrio_exception_bits_exceptionVec_0(io_csrio_exception_bits_exceptionVec_0),
    .io_csrio_exception_bits_exceptionVec_1(io_csrio_exception_bits_exceptionVec_1),
    .io_csrio_exception_bits_exceptionVec_2(io_csrio_exception_bits_exceptionVec_2),
    .io_csrio_exception_bits_exceptionVec_3(io_csrio_exception_bits_exceptionVec_3),
    .io_csrio_exception_bits_exceptionVec_4(io_csrio_exception_bits_exceptionVec_4),
    .io_csrio_exception_bits_exceptionVec_5(io_csrio_exception_bits_exceptionVec_5),
    .io_csrio_exception_bits_exceptionVec_6(io_csrio_exception_bits_exceptionVec_6),
    .io_csrio_exception_bits_exceptionVec_7(io_csrio_exception_bits_exceptionVec_7),
    .io_csrio_exception_bits_exceptionVec_8(io_csrio_exception_bits_exceptionVec_8),
    .io_csrio_exception_bits_exceptionVec_9(io_csrio_exception_bits_exceptionVec_9),
    .io_csrio_exception_bits_exceptionVec_10(io_csrio_exception_bits_exceptionVec_10),
    .io_csrio_exception_bits_exceptionVec_11(io_csrio_exception_bits_exceptionVec_11),
    .io_csrio_exception_bits_exceptionVec_12(io_csrio_exception_bits_exceptionVec_12),
    .io_csrio_exception_bits_exceptionVec_13(io_csrio_exception_bits_exceptionVec_13),
    .io_csrio_exception_bits_exceptionVec_14(io_csrio_exception_bits_exceptionVec_14),
    .io_csrio_exception_bits_exceptionVec_15(io_csrio_exception_bits_exceptionVec_15),
    .io_csrio_exception_bits_exceptionVec_16(io_csrio_exception_bits_exceptionVec_16),
    .io_csrio_exception_bits_exceptionVec_17(io_csrio_exception_bits_exceptionVec_17),
    .io_csrio_exception_bits_exceptionVec_18(io_csrio_exception_bits_exceptionVec_18),
    .io_csrio_exception_bits_exceptionVec_19(io_csrio_exception_bits_exceptionVec_19),
    .io_csrio_exception_bits_exceptionVec_20(io_csrio_exception_bits_exceptionVec_20),
    .io_csrio_exception_bits_exceptionVec_21(io_csrio_exception_bits_exceptionVec_21),
    .io_csrio_exception_bits_exceptionVec_22(io_csrio_exception_bits_exceptionVec_22),
    .io_csrio_exception_bits_exceptionVec_23(io_csrio_exception_bits_exceptionVec_23),
    .io_csrio_exception_bits_isPcBkpt(io_csrio_exception_bits_isPcBkpt),
    .io_csrio_exception_bits_isFetchMalAddr(io_csrio_exception_bits_isFetchMalAddr),
    .io_csrio_exception_bits_gpaddr(io_csrio_exception_bits_gpaddr),
    .io_csrio_exception_bits_singleStep(io_csrio_exception_bits_singleStep),
    .io_csrio_exception_bits_crossPageIPFFix(io_csrio_exception_bits_crossPageIPFFix),
    .io_csrio_exception_bits_isInterrupt(io_csrio_exception_bits_isInterrupt),
    .io_csrio_exception_bits_isHls(io_csrio_exception_bits_isHls),
    .io_csrio_exception_bits_trigger(io_csrio_exception_bits_trigger),
    .io_csrio_exception_bits_isForVSnonLeafPTE(io_csrio_exception_bits_isForVSnonLeafPTE),
    .io_csrio_robDeqPtr_flag(io_csrio_robDeqPtr_flag),
    .io_csrio_robDeqPtr_value(io_csrio_robDeqPtr_value),
    .io_csrio_memExceptionVAddr(io_csrio_memExceptionVAddr),
    .io_csrio_memExceptionGPAddr(io_csrio_memExceptionGPAddr),
    .io_csrio_memExceptionIsForVSnonLeafPTE(io_csrio_memExceptionIsForVSnonLeafPTE),
    .io_csrio_externalInterrupt_mtip(io_csrio_externalInterrupt_mtip),
    .io_csrio_externalInterrupt_msip(io_csrio_externalInterrupt_msip),
    .io_csrio_externalInterrupt_meip(io_csrio_externalInterrupt_meip),
    .io_csrio_externalInterrupt_seip(io_csrio_externalInterrupt_seip),
    .io_csrio_externalInterrupt_debug(io_csrio_externalInterrupt_debug),
    .io_csrio_externalInterrupt_nmi_nmi_31(io_csrio_externalInterrupt_nmi_nmi_31),
    .io_csrio_externalInterrupt_nmi_nmi_43(io_csrio_externalInterrupt_nmi_nmi_43),
    .io_in_ready(g_io_in_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag(g_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value(g_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest(g_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_rfWen(g_io_out_bits_ctrl_rfWen),
    .io_out_bits_ctrl_exceptionVec_2(g_io_out_bits_ctrl_exceptionVec_2),
    .io_out_bits_ctrl_exceptionVec_3(g_io_out_bits_ctrl_exceptionVec_3),
    .io_out_bits_ctrl_exceptionVec_8(g_io_out_bits_ctrl_exceptionVec_8),
    .io_out_bits_ctrl_exceptionVec_9(g_io_out_bits_ctrl_exceptionVec_9),
    .io_out_bits_ctrl_exceptionVec_10(g_io_out_bits_ctrl_exceptionVec_10),
    .io_out_bits_ctrl_exceptionVec_11(g_io_out_bits_ctrl_exceptionVec_11),
    .io_out_bits_ctrl_exceptionVec_22(g_io_out_bits_ctrl_exceptionVec_22),
    .io_out_bits_ctrl_flushPipe(g_io_out_bits_ctrl_flushPipe),
    .io_out_bits_res_data(g_io_out_bits_res_data),
    .io_out_bits_res_redirect_valid(g_io_out_bits_res_redirect_valid),
    .io_out_bits_res_redirect_bits_isRVC(g_io_out_bits_res_redirect_bits_isRVC),
    .io_out_bits_res_redirect_bits_robIdx_flag(g_io_out_bits_res_redirect_bits_robIdx_flag),
    .io_out_bits_res_redirect_bits_robIdx_value(g_io_out_bits_res_redirect_bits_robIdx_value),
    .io_out_bits_res_redirect_bits_ftqIdx_flag(g_io_out_bits_res_redirect_bits_ftqIdx_flag),
    .io_out_bits_res_redirect_bits_ftqIdx_value(g_io_out_bits_res_redirect_bits_ftqIdx_value),
    .io_out_bits_res_redirect_bits_ftqOffset(g_io_out_bits_res_redirect_bits_ftqOffset),
    .io_out_bits_res_redirect_bits_level(g_io_out_bits_res_redirect_bits_level),
    .io_out_bits_res_redirect_bits_interrupt(g_io_out_bits_res_redirect_bits_interrupt),
    .io_out_bits_res_redirect_bits_cfiUpdate_pc(g_io_out_bits_res_redirect_bits_cfiUpdate_pc),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_valid(g_io_out_bits_res_redirect_bits_cfiUpdate_pd_valid),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC(g_io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_brType(g_io_out_bits_res_redirect_bits_cfiUpdate_pd_brType),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall(g_io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet(g_io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet),
    .io_out_bits_res_redirect_bits_cfiUpdate_ssp(g_io_out_bits_res_redirect_bits_cfiUpdate_ssp),
    .io_out_bits_res_redirect_bits_cfiUpdate_sctr(g_io_out_bits_res_redirect_bits_cfiUpdate_sctr),
    .io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag(g_io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag),
    .io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value(g_io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value),
    .io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag(g_io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag),
    .io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value(g_io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value),
    .io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag(g_io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag),
    .io_out_bits_res_redirect_bits_cfiUpdate_NOS_value(g_io_out_bits_res_redirect_bits_cfiUpdate_NOS_value),
    .io_out_bits_res_redirect_bits_cfiUpdate_topAddr(g_io_out_bits_res_redirect_bits_cfiUpdate_topAddr),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3),
    .io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH(g_io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH),
    .io_out_bits_res_redirect_bits_cfiUpdate_ghr(g_io_out_bits_res_redirect_bits_cfiUpdate_ghr),
    .io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag(g_io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag),
    .io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value(g_io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value),
    .io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0(g_io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1(g_io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_br_hit(g_io_out_bits_res_redirect_bits_cfiUpdate_br_hit),
    .io_out_bits_res_redirect_bits_cfiUpdate_jr_hit(g_io_out_bits_res_redirect_bits_cfiUpdate_jr_hit),
    .io_out_bits_res_redirect_bits_cfiUpdate_sc_hit(g_io_out_bits_res_redirect_bits_cfiUpdate_sc_hit),
    .io_out_bits_res_redirect_bits_cfiUpdate_predTaken(g_io_out_bits_res_redirect_bits_cfiUpdate_predTaken),
    .io_out_bits_res_redirect_bits_cfiUpdate_target(g_io_out_bits_res_redirect_bits_cfiUpdate_target),
    .io_out_bits_res_redirect_bits_cfiUpdate_taken(g_io_out_bits_res_redirect_bits_cfiUpdate_taken),
    .io_out_bits_res_redirect_bits_cfiUpdate_isMisPred(g_io_out_bits_res_redirect_bits_cfiUpdate_isMisPred),
    .io_out_bits_res_redirect_bits_cfiUpdate_shift(g_io_out_bits_res_redirect_bits_cfiUpdate_shift),
    .io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist(g_io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist),
    .io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF(g_io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF),
    .io_out_bits_res_redirect_bits_cfiUpdate_backendIPF(g_io_out_bits_res_redirect_bits_cfiUpdate_backendIPF),
    .io_out_bits_res_redirect_bits_cfiUpdate_backendIAF(g_io_out_bits_res_redirect_bits_cfiUpdate_backendIAF),
    .io_out_bits_res_redirect_bits_fullTarget(g_io_out_bits_res_redirect_bits_fullTarget),
    .io_out_bits_res_redirect_bits_stFtqIdx_flag(g_io_out_bits_res_redirect_bits_stFtqIdx_flag),
    .io_out_bits_res_redirect_bits_stFtqIdx_value(g_io_out_bits_res_redirect_bits_stFtqIdx_value),
    .io_out_bits_res_redirect_bits_stFtqOffset(g_io_out_bits_res_redirect_bits_stFtqOffset),
    .io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id(g_io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id),
    .io_out_bits_res_redirect_bits_debugIsCtrl(g_io_out_bits_res_redirect_bits_debugIsCtrl),
    .io_out_bits_res_redirect_bits_debugIsMemVio(g_io_out_bits_res_redirect_bits_debugIsMemVio),
    .io_out_bits_perfDebugInfo_enqRsTime(g_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(g_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(g_io_out_bits_perfDebugInfo_issueTime),
    .io_csrio_criticalErrorState(g_io_csrio_criticalErrorState),
    .io_csrio_isPerfCnt(g_io_csrio_isPerfCnt),
    .io_csrio_fpu_frm(g_io_csrio_fpu_frm),
    .io_csrio_vpu_vstart(g_io_csrio_vpu_vstart),
    .io_csrio_vpu_vxrm(g_io_csrio_vpu_vxrm),
    .io_csrio_trapTarget_pc(g_io_csrio_trapTarget_pc),
    .io_csrio_trapTarget_raiseIPF(g_io_csrio_trapTarget_raiseIPF),
    .io_csrio_trapTarget_raiseIAF(g_io_csrio_trapTarget_raiseIAF),
    .io_csrio_trapTarget_raiseIGPF(g_io_csrio_trapTarget_raiseIGPF),
    .io_csrio_interrupt(g_io_csrio_interrupt),
    .io_csrio_wfi_event(g_io_csrio_wfi_event),
    .io_csrio_traceCSR_cause(g_io_csrio_traceCSR_cause),
    .io_csrio_traceCSR_tval(g_io_csrio_traceCSR_tval),
    .io_csrio_traceCSR_lastPriv(g_io_csrio_traceCSR_lastPriv),
    .io_csrio_traceCSR_currentPriv(g_io_csrio_traceCSR_currentPriv),
    .io_csrio_tlb_satp_mode(g_io_csrio_tlb_satp_mode),
    .io_csrio_tlb_satp_asid(g_io_csrio_tlb_satp_asid),
    .io_csrio_tlb_satp_ppn(g_io_csrio_tlb_satp_ppn),
    .io_csrio_tlb_satp_changed(g_io_csrio_tlb_satp_changed),
    .io_csrio_tlb_vsatp_mode(g_io_csrio_tlb_vsatp_mode),
    .io_csrio_tlb_vsatp_asid(g_io_csrio_tlb_vsatp_asid),
    .io_csrio_tlb_vsatp_ppn(g_io_csrio_tlb_vsatp_ppn),
    .io_csrio_tlb_vsatp_changed(g_io_csrio_tlb_vsatp_changed),
    .io_csrio_tlb_hgatp_mode(g_io_csrio_tlb_hgatp_mode),
    .io_csrio_tlb_hgatp_vmid(g_io_csrio_tlb_hgatp_vmid),
    .io_csrio_tlb_hgatp_ppn(g_io_csrio_tlb_hgatp_ppn),
    .io_csrio_tlb_hgatp_changed(g_io_csrio_tlb_hgatp_changed),
    .io_csrio_tlb_priv_mxr(g_io_csrio_tlb_priv_mxr),
    .io_csrio_tlb_priv_sum(g_io_csrio_tlb_priv_sum),
    .io_csrio_tlb_priv_vmxr(g_io_csrio_tlb_priv_vmxr),
    .io_csrio_tlb_priv_vsum(g_io_csrio_tlb_priv_vsum),
    .io_csrio_tlb_priv_virt(g_io_csrio_tlb_priv_virt),
    .io_csrio_tlb_priv_spvp(g_io_csrio_tlb_priv_spvp),
    .io_csrio_tlb_priv_imode(g_io_csrio_tlb_priv_imode),
    .io_csrio_tlb_priv_dmode(g_io_csrio_tlb_priv_dmode),
    .io_csrio_tlb_mPBMTE(g_io_csrio_tlb_mPBMTE),
    .io_csrio_tlb_hPBMTE(g_io_csrio_tlb_hPBMTE),
    .io_csrio_tlb_pmm_mseccfg(g_io_csrio_tlb_pmm_mseccfg),
    .io_csrio_tlb_pmm_menvcfg(g_io_csrio_tlb_pmm_menvcfg),
    .io_csrio_tlb_pmm_henvcfg(g_io_csrio_tlb_pmm_henvcfg),
    .io_csrio_tlb_pmm_hstatus(g_io_csrio_tlb_pmm_hstatus),
    .io_csrio_tlb_pmm_senvcfg(g_io_csrio_tlb_pmm_senvcfg),
    .io_csrio_customCtrl_pf_ctrl_l1I_pf_enable(g_io_csrio_customCtrl_pf_ctrl_l1I_pf_enable),
    .io_csrio_customCtrl_pf_ctrl_l2_pf_enable(g_io_csrio_customCtrl_pf_ctrl_l2_pf_enable),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_enable(g_io_csrio_customCtrl_pf_ctrl_l1D_pf_enable),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_train_on_hit(g_io_csrio_customCtrl_pf_ctrl_l1D_pf_train_on_hit),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_agt(g_io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_agt),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_pht(g_io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_pht),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_active_threshold(g_io_csrio_customCtrl_pf_ctrl_l1D_pf_active_threshold),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_active_stride(g_io_csrio_customCtrl_pf_ctrl_l1D_pf_active_stride),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_stride(g_io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_stride),
    .io_csrio_customCtrl_pf_ctrl_l2_pf_store_only(g_io_csrio_customCtrl_pf_ctrl_l2_pf_store_only),
    .io_csrio_customCtrl_pf_ctrl_l2_pf_recv_enable(g_io_csrio_customCtrl_pf_ctrl_l2_pf_recv_enable),
    .io_csrio_customCtrl_pf_ctrl_l2_pf_pbop_enable(g_io_csrio_customCtrl_pf_ctrl_l2_pf_pbop_enable),
    .io_csrio_customCtrl_pf_ctrl_l2_pf_vbop_enable(g_io_csrio_customCtrl_pf_ctrl_l2_pf_vbop_enable),
    .io_csrio_customCtrl_lvpred_timeout(g_io_csrio_customCtrl_lvpred_timeout),
    .io_csrio_customCtrl_bp_ctrl_ubtb_enable(g_io_csrio_customCtrl_bp_ctrl_ubtb_enable),
    .io_csrio_customCtrl_bp_ctrl_btb_enable(g_io_csrio_customCtrl_bp_ctrl_btb_enable),
    .io_csrio_customCtrl_bp_ctrl_tage_enable(g_io_csrio_customCtrl_bp_ctrl_tage_enable),
    .io_csrio_customCtrl_bp_ctrl_sc_enable(g_io_csrio_customCtrl_bp_ctrl_sc_enable),
    .io_csrio_customCtrl_bp_ctrl_ras_enable(g_io_csrio_customCtrl_bp_ctrl_ras_enable),
    .io_csrio_customCtrl_ldld_vio_check_enable(g_io_csrio_customCtrl_ldld_vio_check_enable),
    .io_csrio_customCtrl_cache_error_enable(g_io_csrio_customCtrl_cache_error_enable),
    .io_csrio_customCtrl_uncache_write_outstanding_enable(g_io_csrio_customCtrl_uncache_write_outstanding_enable),
    .io_csrio_customCtrl_hd_misalign_st_enable(g_io_csrio_customCtrl_hd_misalign_st_enable),
    .io_csrio_customCtrl_hd_misalign_ld_enable(g_io_csrio_customCtrl_hd_misalign_ld_enable),
    .io_csrio_customCtrl_power_down_enable(g_io_csrio_customCtrl_power_down_enable),
    .io_csrio_customCtrl_flush_l2_enable(g_io_csrio_customCtrl_flush_l2_enable),
    .io_csrio_customCtrl_fusion_enable(g_io_csrio_customCtrl_fusion_enable),
    .io_csrio_customCtrl_wfi_enable(g_io_csrio_customCtrl_wfi_enable),
    .io_csrio_customCtrl_distribute_csr_w_valid(g_io_csrio_customCtrl_distribute_csr_w_valid),
    .io_csrio_customCtrl_distribute_csr_w_bits_addr(g_io_csrio_customCtrl_distribute_csr_w_bits_addr),
    .io_csrio_customCtrl_distribute_csr_w_bits_data(g_io_csrio_customCtrl_distribute_csr_w_bits_data),
    .io_csrio_customCtrl_singlestep(g_io_csrio_customCtrl_singlestep),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_valid(g_io_csrio_customCtrl_frontend_trigger_tUpdate_valid),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_bits_addr(g_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_addr),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_matchType(g_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_matchType),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_select(g_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_select),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_action(g_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_action),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_chain(g_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_chain),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_tdata2(g_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_tdata2),
    .io_csrio_customCtrl_frontend_trigger_tEnableVec_0(g_io_csrio_customCtrl_frontend_trigger_tEnableVec_0),
    .io_csrio_customCtrl_frontend_trigger_tEnableVec_1(g_io_csrio_customCtrl_frontend_trigger_tEnableVec_1),
    .io_csrio_customCtrl_frontend_trigger_tEnableVec_2(g_io_csrio_customCtrl_frontend_trigger_tEnableVec_2),
    .io_csrio_customCtrl_frontend_trigger_tEnableVec_3(g_io_csrio_customCtrl_frontend_trigger_tEnableVec_3),
    .io_csrio_customCtrl_frontend_trigger_debugMode(g_io_csrio_customCtrl_frontend_trigger_debugMode),
    .io_csrio_customCtrl_frontend_trigger_triggerCanRaiseBpExp(g_io_csrio_customCtrl_frontend_trigger_triggerCanRaiseBpExp),
    .io_csrio_customCtrl_mem_trigger_tUpdate_valid(g_io_csrio_customCtrl_mem_trigger_tUpdate_valid),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_addr(g_io_csrio_customCtrl_mem_trigger_tUpdate_bits_addr),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_matchType(g_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_matchType),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_select(g_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_select),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_action(g_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_action),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_chain(g_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_chain),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_store(g_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_store),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_load(g_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_load),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_tdata2(g_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_tdata2),
    .io_csrio_customCtrl_mem_trigger_tEnableVec_0(g_io_csrio_customCtrl_mem_trigger_tEnableVec_0),
    .io_csrio_customCtrl_mem_trigger_tEnableVec_1(g_io_csrio_customCtrl_mem_trigger_tEnableVec_1),
    .io_csrio_customCtrl_mem_trigger_tEnableVec_2(g_io_csrio_customCtrl_mem_trigger_tEnableVec_2),
    .io_csrio_customCtrl_mem_trigger_tEnableVec_3(g_io_csrio_customCtrl_mem_trigger_tEnableVec_3),
    .io_csrio_customCtrl_mem_trigger_debugMode(g_io_csrio_customCtrl_mem_trigger_debugMode),
    .io_csrio_customCtrl_mem_trigger_triggerCanRaiseBpExp(g_io_csrio_customCtrl_mem_trigger_triggerCanRaiseBpExp),
    .io_csrio_customCtrl_fsIsOff(g_io_csrio_customCtrl_fsIsOff),
    .io_csrio_instrAddrTransType_bare(g_io_csrio_instrAddrTransType_bare),
    .io_csrio_instrAddrTransType_sv39(g_io_csrio_instrAddrTransType_sv39),
    .io_csrio_instrAddrTransType_sv39x4(g_io_csrio_instrAddrTransType_sv39x4),
    .io_csrio_instrAddrTransType_sv48(g_io_csrio_instrAddrTransType_sv48),
    .io_csrio_instrAddrTransType_sv48x4(g_io_csrio_instrAddrTransType_sv48x4),
    .io_csrToDecode_illegalInst_sfenceVMA(g_io_csrToDecode_illegalInst_sfenceVMA),
    .io_csrToDecode_illegalInst_sfencePart(g_io_csrToDecode_illegalInst_sfencePart),
    .io_csrToDecode_illegalInst_hfenceGVMA(g_io_csrToDecode_illegalInst_hfenceGVMA),
    .io_csrToDecode_illegalInst_hfenceVVMA(g_io_csrToDecode_illegalInst_hfenceVVMA),
    .io_csrToDecode_illegalInst_hlsv(g_io_csrToDecode_illegalInst_hlsv),
    .io_csrToDecode_illegalInst_fsIsOff(g_io_csrToDecode_illegalInst_fsIsOff),
    .io_csrToDecode_illegalInst_vsIsOff(g_io_csrToDecode_illegalInst_vsIsOff),
    .io_csrToDecode_illegalInst_wfi(g_io_csrToDecode_illegalInst_wfi),
    .io_csrToDecode_illegalInst_wrs_nto(g_io_csrToDecode_illegalInst_wrs_nto),
    .io_csrToDecode_illegalInst_frm(g_io_csrToDecode_illegalInst_frm),
    .io_csrToDecode_illegalInst_cboZ(g_io_csrToDecode_illegalInst_cboZ),
    .io_csrToDecode_illegalInst_cboCF(g_io_csrToDecode_illegalInst_cboCF),
    .io_csrToDecode_illegalInst_cboI(g_io_csrToDecode_illegalInst_cboI),
    .io_csrToDecode_virtualInst_sfenceVMA(g_io_csrToDecode_virtualInst_sfenceVMA),
    .io_csrToDecode_virtualInst_sfencePart(g_io_csrToDecode_virtualInst_sfencePart),
    .io_csrToDecode_virtualInst_hfence(g_io_csrToDecode_virtualInst_hfence),
    .io_csrToDecode_virtualInst_hlsv(g_io_csrToDecode_virtualInst_hlsv),
    .io_csrToDecode_virtualInst_wfi(g_io_csrToDecode_virtualInst_wfi),
    .io_csrToDecode_virtualInst_wrs_nto(g_io_csrToDecode_virtualInst_wrs_nto),
    .io_csrToDecode_virtualInst_cboZ(g_io_csrToDecode_virtualInst_cboZ),
    .io_csrToDecode_virtualInst_cboCF(g_io_csrToDecode_virtualInst_cboCF),
    .io_csrToDecode_virtualInst_cboI(g_io_csrToDecode_virtualInst_cboI),
    .io_csrToDecode_special_cboI2F(g_io_csrToDecode_special_cboI2F),
    .io_error_0(g_io_error_0)
  );
  CSR_xs u_i (
    .clock(clk),
    .reset(rst),
    .io_flush_valid(io_flush_valid),
    .io_flush_bits_robIdx_flag(io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value(io_flush_bits_robIdx_value),
    .io_flush_bits_ftqIdx_flag(io_flush_bits_ftqIdx_flag),
    .io_flush_bits_ftqIdx_value(io_flush_bits_ftqIdx_value),
    .io_flush_bits_ftqOffset(io_flush_bits_ftqOffset),
    .io_flush_bits_level(io_flush_bits_level),
    .io_flush_bits_cfiUpdate_backendIGPF(io_flush_bits_cfiUpdate_backendIGPF),
    .io_flush_bits_cfiUpdate_backendIPF(io_flush_bits_cfiUpdate_backendIPF),
    .io_flush_bits_cfiUpdate_backendIAF(io_flush_bits_cfiUpdate_backendIAF),
    .io_flush_bits_fullTarget(io_flush_bits_fullTarget),
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_robIdx_flag(io_in_bits_ctrl_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value(io_in_bits_ctrl_robIdx_value),
    .io_in_bits_ctrl_pdest(io_in_bits_ctrl_pdest),
    .io_in_bits_ctrl_rfWen(io_in_bits_ctrl_rfWen),
    .io_in_bits_ctrl_ftqIdx_flag(io_in_bits_ctrl_ftqIdx_flag),
    .io_in_bits_ctrl_ftqIdx_value(io_in_bits_ctrl_ftqIdx_value),
    .io_in_bits_ctrl_ftqOffset(io_in_bits_ctrl_ftqOffset),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_data_imm(io_in_bits_data_imm),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_out_ready(io_out_ready),
    .io_csrin_hartId(io_csrin_hartId),
    .io_csrin_msiInfo_valid(io_csrin_msiInfo_valid),
    .io_csrin_msiInfo_bits(io_csrin_msiInfo_bits),
    .io_csrin_criticalErrorState(io_csrin_criticalErrorState),
    .io_csrin_clintTime_valid(io_csrin_clintTime_valid),
    .io_csrin_clintTime_bits(io_csrin_clintTime_bits),
    .io_csrin_l2FlushDone(io_csrin_l2FlushDone),
    .io_csrin_trapInstInfo_valid(io_csrin_trapInstInfo_valid),
    .io_csrin_trapInstInfo_bits_instr(io_csrin_trapInstInfo_bits_instr),
    .io_csrin_trapInstInfo_bits_ftqPtr_flag(io_csrin_trapInstInfo_bits_ftqPtr_flag),
    .io_csrin_trapInstInfo_bits_ftqPtr_value(io_csrin_trapInstInfo_bits_ftqPtr_value),
    .io_csrin_trapInstInfo_bits_ftqOffset(io_csrin_trapInstInfo_bits_ftqOffset),
    .io_csrin_fromVecExcpMod_busy(io_csrin_fromVecExcpMod_busy),
    .io_csrio_perf_perfEventsFrontend_0_value(io_csrio_perf_perfEventsFrontend_0_value),
    .io_csrio_perf_perfEventsFrontend_1_value(io_csrio_perf_perfEventsFrontend_1_value),
    .io_csrio_perf_perfEventsFrontend_2_value(io_csrio_perf_perfEventsFrontend_2_value),
    .io_csrio_perf_perfEventsFrontend_3_value(io_csrio_perf_perfEventsFrontend_3_value),
    .io_csrio_perf_perfEventsFrontend_4_value(io_csrio_perf_perfEventsFrontend_4_value),
    .io_csrio_perf_perfEventsFrontend_5_value(io_csrio_perf_perfEventsFrontend_5_value),
    .io_csrio_perf_perfEventsFrontend_6_value(io_csrio_perf_perfEventsFrontend_6_value),
    .io_csrio_perf_perfEventsFrontend_7_value(io_csrio_perf_perfEventsFrontend_7_value),
    .io_csrio_perf_perfEventsBackend_0_value(io_csrio_perf_perfEventsBackend_0_value),
    .io_csrio_perf_perfEventsBackend_1_value(io_csrio_perf_perfEventsBackend_1_value),
    .io_csrio_perf_perfEventsBackend_2_value(io_csrio_perf_perfEventsBackend_2_value),
    .io_csrio_perf_perfEventsBackend_3_value(io_csrio_perf_perfEventsBackend_3_value),
    .io_csrio_perf_perfEventsBackend_4_value(io_csrio_perf_perfEventsBackend_4_value),
    .io_csrio_perf_perfEventsBackend_5_value(io_csrio_perf_perfEventsBackend_5_value),
    .io_csrio_perf_perfEventsBackend_6_value(io_csrio_perf_perfEventsBackend_6_value),
    .io_csrio_perf_perfEventsBackend_7_value(io_csrio_perf_perfEventsBackend_7_value),
    .io_csrio_perf_perfEventsLsu_0_value(io_csrio_perf_perfEventsLsu_0_value),
    .io_csrio_perf_perfEventsLsu_1_value(io_csrio_perf_perfEventsLsu_1_value),
    .io_csrio_perf_perfEventsLsu_2_value(io_csrio_perf_perfEventsLsu_2_value),
    .io_csrio_perf_perfEventsLsu_3_value(io_csrio_perf_perfEventsLsu_3_value),
    .io_csrio_perf_perfEventsLsu_4_value(io_csrio_perf_perfEventsLsu_4_value),
    .io_csrio_perf_perfEventsLsu_5_value(io_csrio_perf_perfEventsLsu_5_value),
    .io_csrio_perf_perfEventsLsu_6_value(io_csrio_perf_perfEventsLsu_6_value),
    .io_csrio_perf_perfEventsLsu_7_value(io_csrio_perf_perfEventsLsu_7_value),
    .io_csrio_perf_perfEventsHc_0_value(io_csrio_perf_perfEventsHc_0_value),
    .io_csrio_perf_perfEventsHc_1_value(io_csrio_perf_perfEventsHc_1_value),
    .io_csrio_perf_perfEventsHc_2_value(io_csrio_perf_perfEventsHc_2_value),
    .io_csrio_perf_perfEventsHc_3_value(io_csrio_perf_perfEventsHc_3_value),
    .io_csrio_perf_perfEventsHc_4_value(io_csrio_perf_perfEventsHc_4_value),
    .io_csrio_perf_perfEventsHc_5_value(io_csrio_perf_perfEventsHc_5_value),
    .io_csrio_perf_perfEventsHc_6_value(io_csrio_perf_perfEventsHc_6_value),
    .io_csrio_perf_perfEventsHc_7_value(io_csrio_perf_perfEventsHc_7_value),
    .io_csrio_perf_perfEventsHc_8_value(io_csrio_perf_perfEventsHc_8_value),
    .io_csrio_perf_perfEventsHc_9_value(io_csrio_perf_perfEventsHc_9_value),
    .io_csrio_perf_perfEventsHc_10_value(io_csrio_perf_perfEventsHc_10_value),
    .io_csrio_perf_perfEventsHc_11_value(io_csrio_perf_perfEventsHc_11_value),
    .io_csrio_perf_perfEventsHc_12_value(io_csrio_perf_perfEventsHc_12_value),
    .io_csrio_perf_perfEventsHc_13_value(io_csrio_perf_perfEventsHc_13_value),
    .io_csrio_perf_perfEventsHc_14_value(io_csrio_perf_perfEventsHc_14_value),
    .io_csrio_perf_perfEventsHc_15_value(io_csrio_perf_perfEventsHc_15_value),
    .io_csrio_perf_perfEventsHc_16_value(io_csrio_perf_perfEventsHc_16_value),
    .io_csrio_perf_perfEventsHc_17_value(io_csrio_perf_perfEventsHc_17_value),
    .io_csrio_perf_perfEventsHc_18_value(io_csrio_perf_perfEventsHc_18_value),
    .io_csrio_perf_perfEventsHc_19_value(io_csrio_perf_perfEventsHc_19_value),
    .io_csrio_perf_perfEventsHc_20_value(io_csrio_perf_perfEventsHc_20_value),
    .io_csrio_perf_perfEventsHc_21_value(io_csrio_perf_perfEventsHc_21_value),
    .io_csrio_perf_perfEventsHc_22_value(io_csrio_perf_perfEventsHc_22_value),
    .io_csrio_perf_perfEventsHc_23_value(io_csrio_perf_perfEventsHc_23_value),
    .io_csrio_perf_perfEventsHc_24_value(io_csrio_perf_perfEventsHc_24_value),
    .io_csrio_perf_perfEventsHc_25_value(io_csrio_perf_perfEventsHc_25_value),
    .io_csrio_perf_perfEventsHc_26_value(io_csrio_perf_perfEventsHc_26_value),
    .io_csrio_perf_perfEventsHc_27_value(io_csrio_perf_perfEventsHc_27_value),
    .io_csrio_perf_perfEventsHc_28_value(io_csrio_perf_perfEventsHc_28_value),
    .io_csrio_perf_perfEventsHc_29_value(io_csrio_perf_perfEventsHc_29_value),
    .io_csrio_perf_perfEventsHc_30_value(io_csrio_perf_perfEventsHc_30_value),
    .io_csrio_perf_perfEventsHc_31_value(io_csrio_perf_perfEventsHc_31_value),
    .io_csrio_perf_perfEventsHc_32_value(io_csrio_perf_perfEventsHc_32_value),
    .io_csrio_perf_perfEventsHc_33_value(io_csrio_perf_perfEventsHc_33_value),
    .io_csrio_perf_perfEventsHc_34_value(io_csrio_perf_perfEventsHc_34_value),
    .io_csrio_perf_perfEventsHc_35_value(io_csrio_perf_perfEventsHc_35_value),
    .io_csrio_perf_perfEventsHc_36_value(io_csrio_perf_perfEventsHc_36_value),
    .io_csrio_perf_perfEventsHc_37_value(io_csrio_perf_perfEventsHc_37_value),
    .io_csrio_perf_perfEventsHc_38_value(io_csrio_perf_perfEventsHc_38_value),
    .io_csrio_perf_perfEventsHc_39_value(io_csrio_perf_perfEventsHc_39_value),
    .io_csrio_perf_perfEventsHc_40_value(io_csrio_perf_perfEventsHc_40_value),
    .io_csrio_perf_perfEventsHc_41_value(io_csrio_perf_perfEventsHc_41_value),
    .io_csrio_perf_perfEventsHc_42_value(io_csrio_perf_perfEventsHc_42_value),
    .io_csrio_perf_perfEventsHc_43_value(io_csrio_perf_perfEventsHc_43_value),
    .io_csrio_perf_perfEventsHc_44_value(io_csrio_perf_perfEventsHc_44_value),
    .io_csrio_perf_perfEventsHc_45_value(io_csrio_perf_perfEventsHc_45_value),
    .io_csrio_perf_perfEventsHc_46_value(io_csrio_perf_perfEventsHc_46_value),
    .io_csrio_perf_perfEventsHc_47_value(io_csrio_perf_perfEventsHc_47_value),
    .io_csrio_perf_retiredInstr(io_csrio_perf_retiredInstr),
    .io_csrio_fpu_fflags_valid(io_csrio_fpu_fflags_valid),
    .io_csrio_fpu_fflags_bits(io_csrio_fpu_fflags_bits),
    .io_csrio_fpu_dirty_fs(io_csrio_fpu_dirty_fs),
    .io_csrio_vpu_vl(io_csrio_vpu_vl),
    .io_csrio_vpu_set_vstart_valid(io_csrio_vpu_set_vstart_valid),
    .io_csrio_vpu_set_vstart_bits(io_csrio_vpu_set_vstart_bits),
    .io_csrio_vpu_set_vtype_valid(io_csrio_vpu_set_vtype_valid),
    .io_csrio_vpu_set_vtype_bits(io_csrio_vpu_set_vtype_bits),
    .io_csrio_vpu_set_vxsat_valid(io_csrio_vpu_set_vxsat_valid),
    .io_csrio_vpu_set_vxsat_bits(io_csrio_vpu_set_vxsat_bits),
    .io_csrio_vpu_dirty_vs(io_csrio_vpu_dirty_vs),
    .io_csrio_exception_valid(io_csrio_exception_valid),
    .io_csrio_exception_bits_pc(io_csrio_exception_bits_pc),
    .io_csrio_exception_bits_exceptionVec_0(io_csrio_exception_bits_exceptionVec_0),
    .io_csrio_exception_bits_exceptionVec_1(io_csrio_exception_bits_exceptionVec_1),
    .io_csrio_exception_bits_exceptionVec_2(io_csrio_exception_bits_exceptionVec_2),
    .io_csrio_exception_bits_exceptionVec_3(io_csrio_exception_bits_exceptionVec_3),
    .io_csrio_exception_bits_exceptionVec_4(io_csrio_exception_bits_exceptionVec_4),
    .io_csrio_exception_bits_exceptionVec_5(io_csrio_exception_bits_exceptionVec_5),
    .io_csrio_exception_bits_exceptionVec_6(io_csrio_exception_bits_exceptionVec_6),
    .io_csrio_exception_bits_exceptionVec_7(io_csrio_exception_bits_exceptionVec_7),
    .io_csrio_exception_bits_exceptionVec_8(io_csrio_exception_bits_exceptionVec_8),
    .io_csrio_exception_bits_exceptionVec_9(io_csrio_exception_bits_exceptionVec_9),
    .io_csrio_exception_bits_exceptionVec_10(io_csrio_exception_bits_exceptionVec_10),
    .io_csrio_exception_bits_exceptionVec_11(io_csrio_exception_bits_exceptionVec_11),
    .io_csrio_exception_bits_exceptionVec_12(io_csrio_exception_bits_exceptionVec_12),
    .io_csrio_exception_bits_exceptionVec_13(io_csrio_exception_bits_exceptionVec_13),
    .io_csrio_exception_bits_exceptionVec_14(io_csrio_exception_bits_exceptionVec_14),
    .io_csrio_exception_bits_exceptionVec_15(io_csrio_exception_bits_exceptionVec_15),
    .io_csrio_exception_bits_exceptionVec_16(io_csrio_exception_bits_exceptionVec_16),
    .io_csrio_exception_bits_exceptionVec_17(io_csrio_exception_bits_exceptionVec_17),
    .io_csrio_exception_bits_exceptionVec_18(io_csrio_exception_bits_exceptionVec_18),
    .io_csrio_exception_bits_exceptionVec_19(io_csrio_exception_bits_exceptionVec_19),
    .io_csrio_exception_bits_exceptionVec_20(io_csrio_exception_bits_exceptionVec_20),
    .io_csrio_exception_bits_exceptionVec_21(io_csrio_exception_bits_exceptionVec_21),
    .io_csrio_exception_bits_exceptionVec_22(io_csrio_exception_bits_exceptionVec_22),
    .io_csrio_exception_bits_exceptionVec_23(io_csrio_exception_bits_exceptionVec_23),
    .io_csrio_exception_bits_isPcBkpt(io_csrio_exception_bits_isPcBkpt),
    .io_csrio_exception_bits_isFetchMalAddr(io_csrio_exception_bits_isFetchMalAddr),
    .io_csrio_exception_bits_gpaddr(io_csrio_exception_bits_gpaddr),
    .io_csrio_exception_bits_singleStep(io_csrio_exception_bits_singleStep),
    .io_csrio_exception_bits_crossPageIPFFix(io_csrio_exception_bits_crossPageIPFFix),
    .io_csrio_exception_bits_isInterrupt(io_csrio_exception_bits_isInterrupt),
    .io_csrio_exception_bits_isHls(io_csrio_exception_bits_isHls),
    .io_csrio_exception_bits_trigger(io_csrio_exception_bits_trigger),
    .io_csrio_exception_bits_isForVSnonLeafPTE(io_csrio_exception_bits_isForVSnonLeafPTE),
    .io_csrio_robDeqPtr_flag(io_csrio_robDeqPtr_flag),
    .io_csrio_robDeqPtr_value(io_csrio_robDeqPtr_value),
    .io_csrio_memExceptionVAddr(io_csrio_memExceptionVAddr),
    .io_csrio_memExceptionGPAddr(io_csrio_memExceptionGPAddr),
    .io_csrio_memExceptionIsForVSnonLeafPTE(io_csrio_memExceptionIsForVSnonLeafPTE),
    .io_csrio_externalInterrupt_mtip(io_csrio_externalInterrupt_mtip),
    .io_csrio_externalInterrupt_msip(io_csrio_externalInterrupt_msip),
    .io_csrio_externalInterrupt_meip(io_csrio_externalInterrupt_meip),
    .io_csrio_externalInterrupt_seip(io_csrio_externalInterrupt_seip),
    .io_csrio_externalInterrupt_debug(io_csrio_externalInterrupt_debug),
    .io_csrio_externalInterrupt_nmi_nmi_31(io_csrio_externalInterrupt_nmi_nmi_31),
    .io_csrio_externalInterrupt_nmi_nmi_43(io_csrio_externalInterrupt_nmi_nmi_43),
    .io_in_ready(i_io_in_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag(i_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value(i_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest(i_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_rfWen(i_io_out_bits_ctrl_rfWen),
    .io_out_bits_ctrl_exceptionVec_2(i_io_out_bits_ctrl_exceptionVec_2),
    .io_out_bits_ctrl_exceptionVec_3(i_io_out_bits_ctrl_exceptionVec_3),
    .io_out_bits_ctrl_exceptionVec_8(i_io_out_bits_ctrl_exceptionVec_8),
    .io_out_bits_ctrl_exceptionVec_9(i_io_out_bits_ctrl_exceptionVec_9),
    .io_out_bits_ctrl_exceptionVec_10(i_io_out_bits_ctrl_exceptionVec_10),
    .io_out_bits_ctrl_exceptionVec_11(i_io_out_bits_ctrl_exceptionVec_11),
    .io_out_bits_ctrl_exceptionVec_22(i_io_out_bits_ctrl_exceptionVec_22),
    .io_out_bits_ctrl_flushPipe(i_io_out_bits_ctrl_flushPipe),
    .io_out_bits_res_data(i_io_out_bits_res_data),
    .io_out_bits_res_redirect_valid(i_io_out_bits_res_redirect_valid),
    .io_out_bits_res_redirect_bits_isRVC(i_io_out_bits_res_redirect_bits_isRVC),
    .io_out_bits_res_redirect_bits_robIdx_flag(i_io_out_bits_res_redirect_bits_robIdx_flag),
    .io_out_bits_res_redirect_bits_robIdx_value(i_io_out_bits_res_redirect_bits_robIdx_value),
    .io_out_bits_res_redirect_bits_ftqIdx_flag(i_io_out_bits_res_redirect_bits_ftqIdx_flag),
    .io_out_bits_res_redirect_bits_ftqIdx_value(i_io_out_bits_res_redirect_bits_ftqIdx_value),
    .io_out_bits_res_redirect_bits_ftqOffset(i_io_out_bits_res_redirect_bits_ftqOffset),
    .io_out_bits_res_redirect_bits_level(i_io_out_bits_res_redirect_bits_level),
    .io_out_bits_res_redirect_bits_interrupt(i_io_out_bits_res_redirect_bits_interrupt),
    .io_out_bits_res_redirect_bits_cfiUpdate_pc(i_io_out_bits_res_redirect_bits_cfiUpdate_pc),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_valid(i_io_out_bits_res_redirect_bits_cfiUpdate_pd_valid),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC(i_io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_brType(i_io_out_bits_res_redirect_bits_cfiUpdate_pd_brType),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall(i_io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall),
    .io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet(i_io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet),
    .io_out_bits_res_redirect_bits_cfiUpdate_ssp(i_io_out_bits_res_redirect_bits_cfiUpdate_ssp),
    .io_out_bits_res_redirect_bits_cfiUpdate_sctr(i_io_out_bits_res_redirect_bits_cfiUpdate_sctr),
    .io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag(i_io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag),
    .io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value(i_io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value),
    .io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag(i_io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag),
    .io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value(i_io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value),
    .io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag(i_io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag),
    .io_out_bits_res_redirect_bits_cfiUpdate_NOS_value(i_io_out_bits_res_redirect_bits_cfiUpdate_NOS_value),
    .io_out_bits_res_redirect_bits_cfiUpdate_topAddr(i_io_out_bits_res_redirect_bits_cfiUpdate_topAddr),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist(i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist(i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist(i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist(i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist(i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist(i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist(i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist(i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist(i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist(i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist(i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist(i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist(i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist(i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist(i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist(i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist(i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist(i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0(i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1(i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2(i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3(i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0(i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1(i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2(i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3(i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0(i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1(i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2(i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3(i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0(i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1(i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2(i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3(i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0(i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1(i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2(i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3(i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0(i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1(i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2(i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2),
    .io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3(i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3),
    .io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH(i_io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH),
    .io_out_bits_res_redirect_bits_cfiUpdate_ghr(i_io_out_bits_res_redirect_bits_cfiUpdate_ghr),
    .io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag(i_io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag),
    .io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value(i_io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value),
    .io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0(i_io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0),
    .io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1(i_io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1),
    .io_out_bits_res_redirect_bits_cfiUpdate_br_hit(i_io_out_bits_res_redirect_bits_cfiUpdate_br_hit),
    .io_out_bits_res_redirect_bits_cfiUpdate_jr_hit(i_io_out_bits_res_redirect_bits_cfiUpdate_jr_hit),
    .io_out_bits_res_redirect_bits_cfiUpdate_sc_hit(i_io_out_bits_res_redirect_bits_cfiUpdate_sc_hit),
    .io_out_bits_res_redirect_bits_cfiUpdate_predTaken(i_io_out_bits_res_redirect_bits_cfiUpdate_predTaken),
    .io_out_bits_res_redirect_bits_cfiUpdate_target(i_io_out_bits_res_redirect_bits_cfiUpdate_target),
    .io_out_bits_res_redirect_bits_cfiUpdate_taken(i_io_out_bits_res_redirect_bits_cfiUpdate_taken),
    .io_out_bits_res_redirect_bits_cfiUpdate_isMisPred(i_io_out_bits_res_redirect_bits_cfiUpdate_isMisPred),
    .io_out_bits_res_redirect_bits_cfiUpdate_shift(i_io_out_bits_res_redirect_bits_cfiUpdate_shift),
    .io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist(i_io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist),
    .io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF(i_io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF),
    .io_out_bits_res_redirect_bits_cfiUpdate_backendIPF(i_io_out_bits_res_redirect_bits_cfiUpdate_backendIPF),
    .io_out_bits_res_redirect_bits_cfiUpdate_backendIAF(i_io_out_bits_res_redirect_bits_cfiUpdate_backendIAF),
    .io_out_bits_res_redirect_bits_fullTarget(i_io_out_bits_res_redirect_bits_fullTarget),
    .io_out_bits_res_redirect_bits_stFtqIdx_flag(i_io_out_bits_res_redirect_bits_stFtqIdx_flag),
    .io_out_bits_res_redirect_bits_stFtqIdx_value(i_io_out_bits_res_redirect_bits_stFtqIdx_value),
    .io_out_bits_res_redirect_bits_stFtqOffset(i_io_out_bits_res_redirect_bits_stFtqOffset),
    .io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id(i_io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id),
    .io_out_bits_res_redirect_bits_debugIsCtrl(i_io_out_bits_res_redirect_bits_debugIsCtrl),
    .io_out_bits_res_redirect_bits_debugIsMemVio(i_io_out_bits_res_redirect_bits_debugIsMemVio),
    .io_out_bits_perfDebugInfo_enqRsTime(i_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(i_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(i_io_out_bits_perfDebugInfo_issueTime),
    .io_csrio_criticalErrorState(i_io_csrio_criticalErrorState),
    .io_csrio_isPerfCnt(i_io_csrio_isPerfCnt),
    .io_csrio_fpu_frm(i_io_csrio_fpu_frm),
    .io_csrio_vpu_vstart(i_io_csrio_vpu_vstart),
    .io_csrio_vpu_vxrm(i_io_csrio_vpu_vxrm),
    .io_csrio_trapTarget_pc(i_io_csrio_trapTarget_pc),
    .io_csrio_trapTarget_raiseIPF(i_io_csrio_trapTarget_raiseIPF),
    .io_csrio_trapTarget_raiseIAF(i_io_csrio_trapTarget_raiseIAF),
    .io_csrio_trapTarget_raiseIGPF(i_io_csrio_trapTarget_raiseIGPF),
    .io_csrio_interrupt(i_io_csrio_interrupt),
    .io_csrio_wfi_event(i_io_csrio_wfi_event),
    .io_csrio_traceCSR_cause(i_io_csrio_traceCSR_cause),
    .io_csrio_traceCSR_tval(i_io_csrio_traceCSR_tval),
    .io_csrio_traceCSR_lastPriv(i_io_csrio_traceCSR_lastPriv),
    .io_csrio_traceCSR_currentPriv(i_io_csrio_traceCSR_currentPriv),
    .io_csrio_tlb_satp_mode(i_io_csrio_tlb_satp_mode),
    .io_csrio_tlb_satp_asid(i_io_csrio_tlb_satp_asid),
    .io_csrio_tlb_satp_ppn(i_io_csrio_tlb_satp_ppn),
    .io_csrio_tlb_satp_changed(i_io_csrio_tlb_satp_changed),
    .io_csrio_tlb_vsatp_mode(i_io_csrio_tlb_vsatp_mode),
    .io_csrio_tlb_vsatp_asid(i_io_csrio_tlb_vsatp_asid),
    .io_csrio_tlb_vsatp_ppn(i_io_csrio_tlb_vsatp_ppn),
    .io_csrio_tlb_vsatp_changed(i_io_csrio_tlb_vsatp_changed),
    .io_csrio_tlb_hgatp_mode(i_io_csrio_tlb_hgatp_mode),
    .io_csrio_tlb_hgatp_vmid(i_io_csrio_tlb_hgatp_vmid),
    .io_csrio_tlb_hgatp_ppn(i_io_csrio_tlb_hgatp_ppn),
    .io_csrio_tlb_hgatp_changed(i_io_csrio_tlb_hgatp_changed),
    .io_csrio_tlb_priv_mxr(i_io_csrio_tlb_priv_mxr),
    .io_csrio_tlb_priv_sum(i_io_csrio_tlb_priv_sum),
    .io_csrio_tlb_priv_vmxr(i_io_csrio_tlb_priv_vmxr),
    .io_csrio_tlb_priv_vsum(i_io_csrio_tlb_priv_vsum),
    .io_csrio_tlb_priv_virt(i_io_csrio_tlb_priv_virt),
    .io_csrio_tlb_priv_spvp(i_io_csrio_tlb_priv_spvp),
    .io_csrio_tlb_priv_imode(i_io_csrio_tlb_priv_imode),
    .io_csrio_tlb_priv_dmode(i_io_csrio_tlb_priv_dmode),
    .io_csrio_tlb_mPBMTE(i_io_csrio_tlb_mPBMTE),
    .io_csrio_tlb_hPBMTE(i_io_csrio_tlb_hPBMTE),
    .io_csrio_tlb_pmm_mseccfg(i_io_csrio_tlb_pmm_mseccfg),
    .io_csrio_tlb_pmm_menvcfg(i_io_csrio_tlb_pmm_menvcfg),
    .io_csrio_tlb_pmm_henvcfg(i_io_csrio_tlb_pmm_henvcfg),
    .io_csrio_tlb_pmm_hstatus(i_io_csrio_tlb_pmm_hstatus),
    .io_csrio_tlb_pmm_senvcfg(i_io_csrio_tlb_pmm_senvcfg),
    .io_csrio_customCtrl_pf_ctrl_l1I_pf_enable(i_io_csrio_customCtrl_pf_ctrl_l1I_pf_enable),
    .io_csrio_customCtrl_pf_ctrl_l2_pf_enable(i_io_csrio_customCtrl_pf_ctrl_l2_pf_enable),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_enable(i_io_csrio_customCtrl_pf_ctrl_l1D_pf_enable),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_train_on_hit(i_io_csrio_customCtrl_pf_ctrl_l1D_pf_train_on_hit),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_agt(i_io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_agt),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_pht(i_io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_pht),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_active_threshold(i_io_csrio_customCtrl_pf_ctrl_l1D_pf_active_threshold),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_active_stride(i_io_csrio_customCtrl_pf_ctrl_l1D_pf_active_stride),
    .io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_stride(i_io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_stride),
    .io_csrio_customCtrl_pf_ctrl_l2_pf_store_only(i_io_csrio_customCtrl_pf_ctrl_l2_pf_store_only),
    .io_csrio_customCtrl_pf_ctrl_l2_pf_recv_enable(i_io_csrio_customCtrl_pf_ctrl_l2_pf_recv_enable),
    .io_csrio_customCtrl_pf_ctrl_l2_pf_pbop_enable(i_io_csrio_customCtrl_pf_ctrl_l2_pf_pbop_enable),
    .io_csrio_customCtrl_pf_ctrl_l2_pf_vbop_enable(i_io_csrio_customCtrl_pf_ctrl_l2_pf_vbop_enable),
    .io_csrio_customCtrl_lvpred_timeout(i_io_csrio_customCtrl_lvpred_timeout),
    .io_csrio_customCtrl_bp_ctrl_ubtb_enable(i_io_csrio_customCtrl_bp_ctrl_ubtb_enable),
    .io_csrio_customCtrl_bp_ctrl_btb_enable(i_io_csrio_customCtrl_bp_ctrl_btb_enable),
    .io_csrio_customCtrl_bp_ctrl_tage_enable(i_io_csrio_customCtrl_bp_ctrl_tage_enable),
    .io_csrio_customCtrl_bp_ctrl_sc_enable(i_io_csrio_customCtrl_bp_ctrl_sc_enable),
    .io_csrio_customCtrl_bp_ctrl_ras_enable(i_io_csrio_customCtrl_bp_ctrl_ras_enable),
    .io_csrio_customCtrl_ldld_vio_check_enable(i_io_csrio_customCtrl_ldld_vio_check_enable),
    .io_csrio_customCtrl_cache_error_enable(i_io_csrio_customCtrl_cache_error_enable),
    .io_csrio_customCtrl_uncache_write_outstanding_enable(i_io_csrio_customCtrl_uncache_write_outstanding_enable),
    .io_csrio_customCtrl_hd_misalign_st_enable(i_io_csrio_customCtrl_hd_misalign_st_enable),
    .io_csrio_customCtrl_hd_misalign_ld_enable(i_io_csrio_customCtrl_hd_misalign_ld_enable),
    .io_csrio_customCtrl_power_down_enable(i_io_csrio_customCtrl_power_down_enable),
    .io_csrio_customCtrl_flush_l2_enable(i_io_csrio_customCtrl_flush_l2_enable),
    .io_csrio_customCtrl_fusion_enable(i_io_csrio_customCtrl_fusion_enable),
    .io_csrio_customCtrl_wfi_enable(i_io_csrio_customCtrl_wfi_enable),
    .io_csrio_customCtrl_distribute_csr_w_valid(i_io_csrio_customCtrl_distribute_csr_w_valid),
    .io_csrio_customCtrl_distribute_csr_w_bits_addr(i_io_csrio_customCtrl_distribute_csr_w_bits_addr),
    .io_csrio_customCtrl_distribute_csr_w_bits_data(i_io_csrio_customCtrl_distribute_csr_w_bits_data),
    .io_csrio_customCtrl_singlestep(i_io_csrio_customCtrl_singlestep),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_valid(i_io_csrio_customCtrl_frontend_trigger_tUpdate_valid),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_bits_addr(i_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_addr),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_matchType(i_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_matchType),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_select(i_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_select),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_action(i_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_action),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_chain(i_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_chain),
    .io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_tdata2(i_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_tdata2),
    .io_csrio_customCtrl_frontend_trigger_tEnableVec_0(i_io_csrio_customCtrl_frontend_trigger_tEnableVec_0),
    .io_csrio_customCtrl_frontend_trigger_tEnableVec_1(i_io_csrio_customCtrl_frontend_trigger_tEnableVec_1),
    .io_csrio_customCtrl_frontend_trigger_tEnableVec_2(i_io_csrio_customCtrl_frontend_trigger_tEnableVec_2),
    .io_csrio_customCtrl_frontend_trigger_tEnableVec_3(i_io_csrio_customCtrl_frontend_trigger_tEnableVec_3),
    .io_csrio_customCtrl_frontend_trigger_debugMode(i_io_csrio_customCtrl_frontend_trigger_debugMode),
    .io_csrio_customCtrl_frontend_trigger_triggerCanRaiseBpExp(i_io_csrio_customCtrl_frontend_trigger_triggerCanRaiseBpExp),
    .io_csrio_customCtrl_mem_trigger_tUpdate_valid(i_io_csrio_customCtrl_mem_trigger_tUpdate_valid),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_addr(i_io_csrio_customCtrl_mem_trigger_tUpdate_bits_addr),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_matchType(i_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_matchType),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_select(i_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_select),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_action(i_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_action),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_chain(i_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_chain),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_store(i_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_store),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_load(i_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_load),
    .io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_tdata2(i_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_tdata2),
    .io_csrio_customCtrl_mem_trigger_tEnableVec_0(i_io_csrio_customCtrl_mem_trigger_tEnableVec_0),
    .io_csrio_customCtrl_mem_trigger_tEnableVec_1(i_io_csrio_customCtrl_mem_trigger_tEnableVec_1),
    .io_csrio_customCtrl_mem_trigger_tEnableVec_2(i_io_csrio_customCtrl_mem_trigger_tEnableVec_2),
    .io_csrio_customCtrl_mem_trigger_tEnableVec_3(i_io_csrio_customCtrl_mem_trigger_tEnableVec_3),
    .io_csrio_customCtrl_mem_trigger_debugMode(i_io_csrio_customCtrl_mem_trigger_debugMode),
    .io_csrio_customCtrl_mem_trigger_triggerCanRaiseBpExp(i_io_csrio_customCtrl_mem_trigger_triggerCanRaiseBpExp),
    .io_csrio_customCtrl_fsIsOff(i_io_csrio_customCtrl_fsIsOff),
    .io_csrio_instrAddrTransType_bare(i_io_csrio_instrAddrTransType_bare),
    .io_csrio_instrAddrTransType_sv39(i_io_csrio_instrAddrTransType_sv39),
    .io_csrio_instrAddrTransType_sv39x4(i_io_csrio_instrAddrTransType_sv39x4),
    .io_csrio_instrAddrTransType_sv48(i_io_csrio_instrAddrTransType_sv48),
    .io_csrio_instrAddrTransType_sv48x4(i_io_csrio_instrAddrTransType_sv48x4),
    .io_csrToDecode_illegalInst_sfenceVMA(i_io_csrToDecode_illegalInst_sfenceVMA),
    .io_csrToDecode_illegalInst_sfencePart(i_io_csrToDecode_illegalInst_sfencePart),
    .io_csrToDecode_illegalInst_hfenceGVMA(i_io_csrToDecode_illegalInst_hfenceGVMA),
    .io_csrToDecode_illegalInst_hfenceVVMA(i_io_csrToDecode_illegalInst_hfenceVVMA),
    .io_csrToDecode_illegalInst_hlsv(i_io_csrToDecode_illegalInst_hlsv),
    .io_csrToDecode_illegalInst_fsIsOff(i_io_csrToDecode_illegalInst_fsIsOff),
    .io_csrToDecode_illegalInst_vsIsOff(i_io_csrToDecode_illegalInst_vsIsOff),
    .io_csrToDecode_illegalInst_wfi(i_io_csrToDecode_illegalInst_wfi),
    .io_csrToDecode_illegalInst_wrs_nto(i_io_csrToDecode_illegalInst_wrs_nto),
    .io_csrToDecode_illegalInst_frm(i_io_csrToDecode_illegalInst_frm),
    .io_csrToDecode_illegalInst_cboZ(i_io_csrToDecode_illegalInst_cboZ),
    .io_csrToDecode_illegalInst_cboCF(i_io_csrToDecode_illegalInst_cboCF),
    .io_csrToDecode_illegalInst_cboI(i_io_csrToDecode_illegalInst_cboI),
    .io_csrToDecode_virtualInst_sfenceVMA(i_io_csrToDecode_virtualInst_sfenceVMA),
    .io_csrToDecode_virtualInst_sfencePart(i_io_csrToDecode_virtualInst_sfencePart),
    .io_csrToDecode_virtualInst_hfence(i_io_csrToDecode_virtualInst_hfence),
    .io_csrToDecode_virtualInst_hlsv(i_io_csrToDecode_virtualInst_hlsv),
    .io_csrToDecode_virtualInst_wfi(i_io_csrToDecode_virtualInst_wfi),
    .io_csrToDecode_virtualInst_wrs_nto(i_io_csrToDecode_virtualInst_wrs_nto),
    .io_csrToDecode_virtualInst_cboZ(i_io_csrToDecode_virtualInst_cboZ),
    .io_csrToDecode_virtualInst_cboCF(i_io_csrToDecode_virtualInst_cboCF),
    .io_csrToDecode_virtualInst_cboI(i_io_csrToDecode_virtualInst_cboI),
    .io_csrToDecode_special_cboI2F(i_io_csrToDecode_special_cboI2F),
    .io_error_0(i_io_error_0)
  );

  task automatic drive_inputs();
    io_flush_valid = $urandom;
    io_flush_bits_robIdx_flag = $urandom;
    io_flush_bits_robIdx_value = $urandom;
    io_flush_bits_ftqIdx_flag = $urandom;
    io_flush_bits_ftqIdx_value = $urandom;
    io_flush_bits_ftqOffset = $urandom;
    io_flush_bits_level = $urandom;
    io_flush_bits_cfiUpdate_backendIGPF = $urandom;
    io_flush_bits_cfiUpdate_backendIPF = $urandom;
    io_flush_bits_cfiUpdate_backendIAF = $urandom;
    io_flush_bits_fullTarget = {$urandom,$urandom};
    io_in_valid = $urandom;
    io_in_bits_ctrl_fuOpType = $urandom;
    io_in_bits_ctrl_robIdx_flag = $urandom;
    io_in_bits_ctrl_robIdx_value = $urandom;
    io_in_bits_ctrl_pdest = $urandom;
    io_in_bits_ctrl_rfWen = $urandom;
    io_in_bits_ctrl_ftqIdx_flag = $urandom;
    io_in_bits_ctrl_ftqIdx_value = $urandom;
    io_in_bits_ctrl_ftqOffset = $urandom;
    io_in_bits_data_src_0 = {$urandom,$urandom};
    io_in_bits_data_imm = {$urandom,$urandom};
    io_in_bits_perfDebugInfo_enqRsTime = {$urandom,$urandom};
    io_in_bits_perfDebugInfo_selectTime = {$urandom,$urandom};
    io_in_bits_perfDebugInfo_issueTime = {$urandom,$urandom};
    io_out_ready = $urandom;
    io_csrin_hartId = $urandom;
    io_csrin_msiInfo_valid = $urandom;
    io_csrin_msiInfo_bits = $urandom;
    io_csrin_criticalErrorState = $urandom;
    io_csrin_clintTime_valid = $urandom;
    io_csrin_clintTime_bits = {$urandom,$urandom};
    io_csrin_l2FlushDone = $urandom;
    io_csrin_trapInstInfo_valid = $urandom;
    io_csrin_trapInstInfo_bits_instr = $urandom;
    io_csrin_trapInstInfo_bits_ftqPtr_flag = $urandom;
    io_csrin_trapInstInfo_bits_ftqPtr_value = $urandom;
    io_csrin_trapInstInfo_bits_ftqOffset = $urandom;
    io_csrin_fromVecExcpMod_busy = $urandom;
    io_csrio_perf_perfEventsFrontend_0_value = $urandom;
    io_csrio_perf_perfEventsFrontend_1_value = $urandom;
    io_csrio_perf_perfEventsFrontend_2_value = $urandom;
    io_csrio_perf_perfEventsFrontend_3_value = $urandom;
    io_csrio_perf_perfEventsFrontend_4_value = $urandom;
    io_csrio_perf_perfEventsFrontend_5_value = $urandom;
    io_csrio_perf_perfEventsFrontend_6_value = $urandom;
    io_csrio_perf_perfEventsFrontend_7_value = $urandom;
    io_csrio_perf_perfEventsBackend_0_value = $urandom;
    io_csrio_perf_perfEventsBackend_1_value = $urandom;
    io_csrio_perf_perfEventsBackend_2_value = $urandom;
    io_csrio_perf_perfEventsBackend_3_value = $urandom;
    io_csrio_perf_perfEventsBackend_4_value = $urandom;
    io_csrio_perf_perfEventsBackend_5_value = $urandom;
    io_csrio_perf_perfEventsBackend_6_value = $urandom;
    io_csrio_perf_perfEventsBackend_7_value = $urandom;
    io_csrio_perf_perfEventsLsu_0_value = $urandom;
    io_csrio_perf_perfEventsLsu_1_value = $urandom;
    io_csrio_perf_perfEventsLsu_2_value = $urandom;
    io_csrio_perf_perfEventsLsu_3_value = $urandom;
    io_csrio_perf_perfEventsLsu_4_value = $urandom;
    io_csrio_perf_perfEventsLsu_5_value = $urandom;
    io_csrio_perf_perfEventsLsu_6_value = $urandom;
    io_csrio_perf_perfEventsLsu_7_value = $urandom;
    io_csrio_perf_perfEventsHc_0_value = $urandom;
    io_csrio_perf_perfEventsHc_1_value = $urandom;
    io_csrio_perf_perfEventsHc_2_value = $urandom;
    io_csrio_perf_perfEventsHc_3_value = $urandom;
    io_csrio_perf_perfEventsHc_4_value = $urandom;
    io_csrio_perf_perfEventsHc_5_value = $urandom;
    io_csrio_perf_perfEventsHc_6_value = $urandom;
    io_csrio_perf_perfEventsHc_7_value = $urandom;
    io_csrio_perf_perfEventsHc_8_value = $urandom;
    io_csrio_perf_perfEventsHc_9_value = $urandom;
    io_csrio_perf_perfEventsHc_10_value = $urandom;
    io_csrio_perf_perfEventsHc_11_value = $urandom;
    io_csrio_perf_perfEventsHc_12_value = $urandom;
    io_csrio_perf_perfEventsHc_13_value = $urandom;
    io_csrio_perf_perfEventsHc_14_value = $urandom;
    io_csrio_perf_perfEventsHc_15_value = $urandom;
    io_csrio_perf_perfEventsHc_16_value = $urandom;
    io_csrio_perf_perfEventsHc_17_value = $urandom;
    io_csrio_perf_perfEventsHc_18_value = $urandom;
    io_csrio_perf_perfEventsHc_19_value = $urandom;
    io_csrio_perf_perfEventsHc_20_value = $urandom;
    io_csrio_perf_perfEventsHc_21_value = $urandom;
    io_csrio_perf_perfEventsHc_22_value = $urandom;
    io_csrio_perf_perfEventsHc_23_value = $urandom;
    io_csrio_perf_perfEventsHc_24_value = $urandom;
    io_csrio_perf_perfEventsHc_25_value = $urandom;
    io_csrio_perf_perfEventsHc_26_value = $urandom;
    io_csrio_perf_perfEventsHc_27_value = $urandom;
    io_csrio_perf_perfEventsHc_28_value = $urandom;
    io_csrio_perf_perfEventsHc_29_value = $urandom;
    io_csrio_perf_perfEventsHc_30_value = $urandom;
    io_csrio_perf_perfEventsHc_31_value = $urandom;
    io_csrio_perf_perfEventsHc_32_value = $urandom;
    io_csrio_perf_perfEventsHc_33_value = $urandom;
    io_csrio_perf_perfEventsHc_34_value = $urandom;
    io_csrio_perf_perfEventsHc_35_value = $urandom;
    io_csrio_perf_perfEventsHc_36_value = $urandom;
    io_csrio_perf_perfEventsHc_37_value = $urandom;
    io_csrio_perf_perfEventsHc_38_value = $urandom;
    io_csrio_perf_perfEventsHc_39_value = $urandom;
    io_csrio_perf_perfEventsHc_40_value = $urandom;
    io_csrio_perf_perfEventsHc_41_value = $urandom;
    io_csrio_perf_perfEventsHc_42_value = $urandom;
    io_csrio_perf_perfEventsHc_43_value = $urandom;
    io_csrio_perf_perfEventsHc_44_value = $urandom;
    io_csrio_perf_perfEventsHc_45_value = $urandom;
    io_csrio_perf_perfEventsHc_46_value = $urandom;
    io_csrio_perf_perfEventsHc_47_value = $urandom;
    io_csrio_perf_retiredInstr = $urandom;
    io_csrio_fpu_fflags_valid = $urandom;
    io_csrio_fpu_fflags_bits = $urandom;
    io_csrio_fpu_dirty_fs = $urandom;
    io_csrio_vpu_vl = {$urandom,$urandom};
    io_csrio_vpu_set_vstart_valid = $urandom;
    io_csrio_vpu_set_vstart_bits = {$urandom,$urandom};
    io_csrio_vpu_set_vtype_valid = $urandom;
    io_csrio_vpu_set_vtype_bits = {$urandom,$urandom};
    io_csrio_vpu_set_vxsat_valid = $urandom;
    io_csrio_vpu_set_vxsat_bits = $urandom;
    io_csrio_vpu_dirty_vs = $urandom;
    io_csrio_exception_valid = $urandom;
    io_csrio_exception_bits_pc = {$urandom,$urandom};
    io_csrio_exception_bits_exceptionVec_0 = $urandom;
    io_csrio_exception_bits_exceptionVec_1 = $urandom;
    io_csrio_exception_bits_exceptionVec_2 = $urandom;
    io_csrio_exception_bits_exceptionVec_3 = $urandom;
    io_csrio_exception_bits_exceptionVec_4 = $urandom;
    io_csrio_exception_bits_exceptionVec_5 = $urandom;
    io_csrio_exception_bits_exceptionVec_6 = $urandom;
    io_csrio_exception_bits_exceptionVec_7 = $urandom;
    io_csrio_exception_bits_exceptionVec_8 = $urandom;
    io_csrio_exception_bits_exceptionVec_9 = $urandom;
    io_csrio_exception_bits_exceptionVec_10 = $urandom;
    io_csrio_exception_bits_exceptionVec_11 = $urandom;
    io_csrio_exception_bits_exceptionVec_12 = $urandom;
    io_csrio_exception_bits_exceptionVec_13 = $urandom;
    io_csrio_exception_bits_exceptionVec_14 = $urandom;
    io_csrio_exception_bits_exceptionVec_15 = $urandom;
    io_csrio_exception_bits_exceptionVec_16 = $urandom;
    io_csrio_exception_bits_exceptionVec_17 = $urandom;
    io_csrio_exception_bits_exceptionVec_18 = $urandom;
    io_csrio_exception_bits_exceptionVec_19 = $urandom;
    io_csrio_exception_bits_exceptionVec_20 = $urandom;
    io_csrio_exception_bits_exceptionVec_21 = $urandom;
    io_csrio_exception_bits_exceptionVec_22 = $urandom;
    io_csrio_exception_bits_exceptionVec_23 = $urandom;
    io_csrio_exception_bits_isPcBkpt = $urandom;
    io_csrio_exception_bits_isFetchMalAddr = $urandom;
    io_csrio_exception_bits_gpaddr = {$urandom,$urandom};
    io_csrio_exception_bits_singleStep = $urandom;
    io_csrio_exception_bits_crossPageIPFFix = $urandom;
    io_csrio_exception_bits_isInterrupt = $urandom;
    io_csrio_exception_bits_isHls = $urandom;
    io_csrio_exception_bits_trigger = $urandom;
    io_csrio_exception_bits_isForVSnonLeafPTE = $urandom;
    io_csrio_robDeqPtr_flag = $urandom;
    io_csrio_robDeqPtr_value = $urandom;
    io_csrio_memExceptionVAddr = {$urandom,$urandom};
    io_csrio_memExceptionGPAddr = {$urandom,$urandom};
    io_csrio_memExceptionIsForVSnonLeafPTE = $urandom;
    io_csrio_externalInterrupt_mtip = $urandom;
    io_csrio_externalInterrupt_msip = $urandom;
    io_csrio_externalInterrupt_meip = $urandom;
    io_csrio_externalInterrupt_seip = $urandom;
    io_csrio_externalInterrupt_debug = $urandom;
    io_csrio_externalInterrupt_nmi_nmi_31 = $urandom;
    io_csrio_externalInterrupt_nmi_nmi_43 = $urandom;
  endtask

  `define CK(g,i,nm) if(!$isunknown(g)&&(g)!==(i))begin errors++; if(errors<=80)$display("[%0t] %s g=%h i=%h",$time,nm,g,i);end checks++;

  task automatic check_outputs();
    `CK(g_io_in_ready, i_io_in_ready, "io_in_ready")
    `CK(g_io_out_valid, i_io_out_valid, "io_out_valid")
    `CK(g_io_out_bits_ctrl_robIdx_flag, i_io_out_bits_ctrl_robIdx_flag, "io_out_bits_ctrl_robIdx_flag")
    `CK(g_io_out_bits_ctrl_robIdx_value, i_io_out_bits_ctrl_robIdx_value, "io_out_bits_ctrl_robIdx_value")
    `CK(g_io_out_bits_ctrl_pdest, i_io_out_bits_ctrl_pdest, "io_out_bits_ctrl_pdest")
    `CK(g_io_out_bits_ctrl_rfWen, i_io_out_bits_ctrl_rfWen, "io_out_bits_ctrl_rfWen")
    `CK(g_io_out_bits_ctrl_exceptionVec_2, i_io_out_bits_ctrl_exceptionVec_2, "io_out_bits_ctrl_exceptionVec_2")
    `CK(g_io_out_bits_ctrl_exceptionVec_3, i_io_out_bits_ctrl_exceptionVec_3, "io_out_bits_ctrl_exceptionVec_3")
    `CK(g_io_out_bits_ctrl_exceptionVec_8, i_io_out_bits_ctrl_exceptionVec_8, "io_out_bits_ctrl_exceptionVec_8")
    `CK(g_io_out_bits_ctrl_exceptionVec_9, i_io_out_bits_ctrl_exceptionVec_9, "io_out_bits_ctrl_exceptionVec_9")
    `CK(g_io_out_bits_ctrl_exceptionVec_10, i_io_out_bits_ctrl_exceptionVec_10, "io_out_bits_ctrl_exceptionVec_10")
    `CK(g_io_out_bits_ctrl_exceptionVec_11, i_io_out_bits_ctrl_exceptionVec_11, "io_out_bits_ctrl_exceptionVec_11")
    `CK(g_io_out_bits_ctrl_exceptionVec_22, i_io_out_bits_ctrl_exceptionVec_22, "io_out_bits_ctrl_exceptionVec_22")
    `CK(g_io_out_bits_ctrl_flushPipe, i_io_out_bits_ctrl_flushPipe, "io_out_bits_ctrl_flushPipe")
    `CK(g_io_out_bits_res_data, i_io_out_bits_res_data, "io_out_bits_res_data")
    `CK(g_io_out_bits_res_redirect_valid, i_io_out_bits_res_redirect_valid, "io_out_bits_res_redirect_valid")
    `CK(g_io_out_bits_res_redirect_bits_isRVC, i_io_out_bits_res_redirect_bits_isRVC, "io_out_bits_res_redirect_bits_isRVC")
    `CK(g_io_out_bits_res_redirect_bits_robIdx_flag, i_io_out_bits_res_redirect_bits_robIdx_flag, "io_out_bits_res_redirect_bits_robIdx_flag")
    `CK(g_io_out_bits_res_redirect_bits_robIdx_value, i_io_out_bits_res_redirect_bits_robIdx_value, "io_out_bits_res_redirect_bits_robIdx_value")
    `CK(g_io_out_bits_res_redirect_bits_ftqIdx_flag, i_io_out_bits_res_redirect_bits_ftqIdx_flag, "io_out_bits_res_redirect_bits_ftqIdx_flag")
    `CK(g_io_out_bits_res_redirect_bits_ftqIdx_value, i_io_out_bits_res_redirect_bits_ftqIdx_value, "io_out_bits_res_redirect_bits_ftqIdx_value")
    `CK(g_io_out_bits_res_redirect_bits_ftqOffset, i_io_out_bits_res_redirect_bits_ftqOffset, "io_out_bits_res_redirect_bits_ftqOffset")
    `CK(g_io_out_bits_res_redirect_bits_level, i_io_out_bits_res_redirect_bits_level, "io_out_bits_res_redirect_bits_level")
    `CK(g_io_out_bits_res_redirect_bits_interrupt, i_io_out_bits_res_redirect_bits_interrupt, "io_out_bits_res_redirect_bits_interrupt")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_pc, i_io_out_bits_res_redirect_bits_cfiUpdate_pc, "io_out_bits_res_redirect_bits_cfiUpdate_pc")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_pd_valid, i_io_out_bits_res_redirect_bits_cfiUpdate_pd_valid, "io_out_bits_res_redirect_bits_cfiUpdate_pd_valid")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC, i_io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC, "io_out_bits_res_redirect_bits_cfiUpdate_pd_isRVC")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_pd_brType, i_io_out_bits_res_redirect_bits_cfiUpdate_pd_brType, "io_out_bits_res_redirect_bits_cfiUpdate_pd_brType")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall, i_io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall, "io_out_bits_res_redirect_bits_cfiUpdate_pd_isCall")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet, i_io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet, "io_out_bits_res_redirect_bits_cfiUpdate_pd_isRet")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_ssp, i_io_out_bits_res_redirect_bits_cfiUpdate_ssp, "io_out_bits_res_redirect_bits_cfiUpdate_ssp")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_sctr, i_io_out_bits_res_redirect_bits_cfiUpdate_sctr, "io_out_bits_res_redirect_bits_cfiUpdate_sctr")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag, i_io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag, "io_out_bits_res_redirect_bits_cfiUpdate_TOSW_flag")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value, i_io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value, "io_out_bits_res_redirect_bits_cfiUpdate_TOSW_value")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag, i_io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag, "io_out_bits_res_redirect_bits_cfiUpdate_TOSR_flag")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value, i_io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value, "io_out_bits_res_redirect_bits_cfiUpdate_TOSR_value")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag, i_io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag, "io_out_bits_res_redirect_bits_cfiUpdate_NOS_flag")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_NOS_value, i_io_out_bits_res_redirect_bits_cfiUpdate_NOS_value, "io_out_bits_res_redirect_bits_cfiUpdate_NOS_value")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_topAddr, i_io_out_bits_res_redirect_bits_cfiUpdate_topAddr, "io_out_bits_res_redirect_bits_cfiUpdate_topAddr")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist, i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist, "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist, i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist, "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist, i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist, "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist, i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist, "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist, i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist, "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist, i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist, "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist, i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist, "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist, i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist, "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist, i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist, "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist, i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist, "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist, i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist, "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist, i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist, "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist, i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist, "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist, i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist, "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist, i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist, "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist, i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist, "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist, i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist, "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist, i_io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist, "io_out_bits_res_redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0, i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0, "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_0")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1, i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1, "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_1")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2, i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2, "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_2")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3, i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3, "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_5_bits_3")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0, i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0, "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_0")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1, i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1, "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_1")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2, i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2, "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_2")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3, i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3, "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_4_bits_3")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0, i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0, "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_0")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1, i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1, "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_1")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2, i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2, "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_2")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3, i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3, "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_3_bits_3")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0, i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0, "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_0")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1, i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1, "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_1")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2, i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2, "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_2")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3, i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3, "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_2_bits_3")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0, i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0, "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_0")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1, i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1, "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_1")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2, i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2, "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_2")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3, i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3, "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_1_bits_3")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0, i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0, "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_0")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1, i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1, "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_1")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2, i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2, "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_2")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3, i_io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3, "io_out_bits_res_redirect_bits_cfiUpdate_afhob_afhob_0_bits_3")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH, i_io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH, "io_out_bits_res_redirect_bits_cfiUpdate_lastBrNumOH")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_ghr, i_io_out_bits_res_redirect_bits_cfiUpdate_ghr, "io_out_bits_res_redirect_bits_cfiUpdate_ghr")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag, i_io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag, "io_out_bits_res_redirect_bits_cfiUpdate_histPtr_flag")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value, i_io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value, "io_out_bits_res_redirect_bits_cfiUpdate_histPtr_value")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0, i_io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0, "io_out_bits_res_redirect_bits_cfiUpdate_specCnt_0")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1, i_io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1, "io_out_bits_res_redirect_bits_cfiUpdate_specCnt_1")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_br_hit, i_io_out_bits_res_redirect_bits_cfiUpdate_br_hit, "io_out_bits_res_redirect_bits_cfiUpdate_br_hit")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_jr_hit, i_io_out_bits_res_redirect_bits_cfiUpdate_jr_hit, "io_out_bits_res_redirect_bits_cfiUpdate_jr_hit")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_sc_hit, i_io_out_bits_res_redirect_bits_cfiUpdate_sc_hit, "io_out_bits_res_redirect_bits_cfiUpdate_sc_hit")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_predTaken, i_io_out_bits_res_redirect_bits_cfiUpdate_predTaken, "io_out_bits_res_redirect_bits_cfiUpdate_predTaken")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_target, i_io_out_bits_res_redirect_bits_cfiUpdate_target, "io_out_bits_res_redirect_bits_cfiUpdate_target")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_taken, i_io_out_bits_res_redirect_bits_cfiUpdate_taken, "io_out_bits_res_redirect_bits_cfiUpdate_taken")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_isMisPred, i_io_out_bits_res_redirect_bits_cfiUpdate_isMisPred, "io_out_bits_res_redirect_bits_cfiUpdate_isMisPred")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_shift, i_io_out_bits_res_redirect_bits_cfiUpdate_shift, "io_out_bits_res_redirect_bits_cfiUpdate_shift")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist, i_io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist, "io_out_bits_res_redirect_bits_cfiUpdate_addIntoHist")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF, i_io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF, "io_out_bits_res_redirect_bits_cfiUpdate_backendIGPF")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_backendIPF, i_io_out_bits_res_redirect_bits_cfiUpdate_backendIPF, "io_out_bits_res_redirect_bits_cfiUpdate_backendIPF")
    `CK(g_io_out_bits_res_redirect_bits_cfiUpdate_backendIAF, i_io_out_bits_res_redirect_bits_cfiUpdate_backendIAF, "io_out_bits_res_redirect_bits_cfiUpdate_backendIAF")
    `CK(g_io_out_bits_res_redirect_bits_fullTarget, i_io_out_bits_res_redirect_bits_fullTarget, "io_out_bits_res_redirect_bits_fullTarget")
    `CK(g_io_out_bits_res_redirect_bits_stFtqIdx_flag, i_io_out_bits_res_redirect_bits_stFtqIdx_flag, "io_out_bits_res_redirect_bits_stFtqIdx_flag")
    `CK(g_io_out_bits_res_redirect_bits_stFtqIdx_value, i_io_out_bits_res_redirect_bits_stFtqIdx_value, "io_out_bits_res_redirect_bits_stFtqIdx_value")
    `CK(g_io_out_bits_res_redirect_bits_stFtqOffset, i_io_out_bits_res_redirect_bits_stFtqOffset, "io_out_bits_res_redirect_bits_stFtqOffset")
    `CK(g_io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id, i_io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id, "io_out_bits_res_redirect_bits_debug_runahead_checkpoint_id")
    `CK(g_io_out_bits_res_redirect_bits_debugIsCtrl, i_io_out_bits_res_redirect_bits_debugIsCtrl, "io_out_bits_res_redirect_bits_debugIsCtrl")
    `CK(g_io_out_bits_res_redirect_bits_debugIsMemVio, i_io_out_bits_res_redirect_bits_debugIsMemVio, "io_out_bits_res_redirect_bits_debugIsMemVio")
    `CK(g_io_out_bits_perfDebugInfo_enqRsTime, i_io_out_bits_perfDebugInfo_enqRsTime, "io_out_bits_perfDebugInfo_enqRsTime")
    `CK(g_io_out_bits_perfDebugInfo_selectTime, i_io_out_bits_perfDebugInfo_selectTime, "io_out_bits_perfDebugInfo_selectTime")
    `CK(g_io_out_bits_perfDebugInfo_issueTime, i_io_out_bits_perfDebugInfo_issueTime, "io_out_bits_perfDebugInfo_issueTime")
    `CK(g_io_csrio_criticalErrorState, i_io_csrio_criticalErrorState, "io_csrio_criticalErrorState")
    `CK(g_io_csrio_isPerfCnt, i_io_csrio_isPerfCnt, "io_csrio_isPerfCnt")
    `CK(g_io_csrio_fpu_frm, i_io_csrio_fpu_frm, "io_csrio_fpu_frm")
    `CK(g_io_csrio_vpu_vstart, i_io_csrio_vpu_vstart, "io_csrio_vpu_vstart")
    `CK(g_io_csrio_vpu_vxrm, i_io_csrio_vpu_vxrm, "io_csrio_vpu_vxrm")
    `CK(g_io_csrio_trapTarget_pc, i_io_csrio_trapTarget_pc, "io_csrio_trapTarget_pc")
    `CK(g_io_csrio_trapTarget_raiseIPF, i_io_csrio_trapTarget_raiseIPF, "io_csrio_trapTarget_raiseIPF")
    `CK(g_io_csrio_trapTarget_raiseIAF, i_io_csrio_trapTarget_raiseIAF, "io_csrio_trapTarget_raiseIAF")
    `CK(g_io_csrio_trapTarget_raiseIGPF, i_io_csrio_trapTarget_raiseIGPF, "io_csrio_trapTarget_raiseIGPF")
    `CK(g_io_csrio_interrupt, i_io_csrio_interrupt, "io_csrio_interrupt")
    `CK(g_io_csrio_wfi_event, i_io_csrio_wfi_event, "io_csrio_wfi_event")
    `CK(g_io_csrio_traceCSR_cause, i_io_csrio_traceCSR_cause, "io_csrio_traceCSR_cause")
    `CK(g_io_csrio_traceCSR_tval, i_io_csrio_traceCSR_tval, "io_csrio_traceCSR_tval")
    `CK(g_io_csrio_traceCSR_lastPriv, i_io_csrio_traceCSR_lastPriv, "io_csrio_traceCSR_lastPriv")
    `CK(g_io_csrio_traceCSR_currentPriv, i_io_csrio_traceCSR_currentPriv, "io_csrio_traceCSR_currentPriv")
    `CK(g_io_csrio_tlb_satp_mode, i_io_csrio_tlb_satp_mode, "io_csrio_tlb_satp_mode")
    `CK(g_io_csrio_tlb_satp_asid, i_io_csrio_tlb_satp_asid, "io_csrio_tlb_satp_asid")
    `CK(g_io_csrio_tlb_satp_ppn, i_io_csrio_tlb_satp_ppn, "io_csrio_tlb_satp_ppn")
    `CK(g_io_csrio_tlb_satp_changed, i_io_csrio_tlb_satp_changed, "io_csrio_tlb_satp_changed")
    `CK(g_io_csrio_tlb_vsatp_mode, i_io_csrio_tlb_vsatp_mode, "io_csrio_tlb_vsatp_mode")
    `CK(g_io_csrio_tlb_vsatp_asid, i_io_csrio_tlb_vsatp_asid, "io_csrio_tlb_vsatp_asid")
    `CK(g_io_csrio_tlb_vsatp_ppn, i_io_csrio_tlb_vsatp_ppn, "io_csrio_tlb_vsatp_ppn")
    `CK(g_io_csrio_tlb_vsatp_changed, i_io_csrio_tlb_vsatp_changed, "io_csrio_tlb_vsatp_changed")
    `CK(g_io_csrio_tlb_hgatp_mode, i_io_csrio_tlb_hgatp_mode, "io_csrio_tlb_hgatp_mode")
    `CK(g_io_csrio_tlb_hgatp_vmid, i_io_csrio_tlb_hgatp_vmid, "io_csrio_tlb_hgatp_vmid")
    `CK(g_io_csrio_tlb_hgatp_ppn, i_io_csrio_tlb_hgatp_ppn, "io_csrio_tlb_hgatp_ppn")
    `CK(g_io_csrio_tlb_hgatp_changed, i_io_csrio_tlb_hgatp_changed, "io_csrio_tlb_hgatp_changed")
    `CK(g_io_csrio_tlb_priv_mxr, i_io_csrio_tlb_priv_mxr, "io_csrio_tlb_priv_mxr")
    `CK(g_io_csrio_tlb_priv_sum, i_io_csrio_tlb_priv_sum, "io_csrio_tlb_priv_sum")
    `CK(g_io_csrio_tlb_priv_vmxr, i_io_csrio_tlb_priv_vmxr, "io_csrio_tlb_priv_vmxr")
    `CK(g_io_csrio_tlb_priv_vsum, i_io_csrio_tlb_priv_vsum, "io_csrio_tlb_priv_vsum")
    `CK(g_io_csrio_tlb_priv_virt, i_io_csrio_tlb_priv_virt, "io_csrio_tlb_priv_virt")
    `CK(g_io_csrio_tlb_priv_spvp, i_io_csrio_tlb_priv_spvp, "io_csrio_tlb_priv_spvp")
    `CK(g_io_csrio_tlb_priv_imode, i_io_csrio_tlb_priv_imode, "io_csrio_tlb_priv_imode")
    `CK(g_io_csrio_tlb_priv_dmode, i_io_csrio_tlb_priv_dmode, "io_csrio_tlb_priv_dmode")
    `CK(g_io_csrio_tlb_mPBMTE, i_io_csrio_tlb_mPBMTE, "io_csrio_tlb_mPBMTE")
    `CK(g_io_csrio_tlb_hPBMTE, i_io_csrio_tlb_hPBMTE, "io_csrio_tlb_hPBMTE")
    `CK(g_io_csrio_tlb_pmm_mseccfg, i_io_csrio_tlb_pmm_mseccfg, "io_csrio_tlb_pmm_mseccfg")
    `CK(g_io_csrio_tlb_pmm_menvcfg, i_io_csrio_tlb_pmm_menvcfg, "io_csrio_tlb_pmm_menvcfg")
    `CK(g_io_csrio_tlb_pmm_henvcfg, i_io_csrio_tlb_pmm_henvcfg, "io_csrio_tlb_pmm_henvcfg")
    `CK(g_io_csrio_tlb_pmm_hstatus, i_io_csrio_tlb_pmm_hstatus, "io_csrio_tlb_pmm_hstatus")
    `CK(g_io_csrio_tlb_pmm_senvcfg, i_io_csrio_tlb_pmm_senvcfg, "io_csrio_tlb_pmm_senvcfg")
    `CK(g_io_csrio_customCtrl_pf_ctrl_l1I_pf_enable, i_io_csrio_customCtrl_pf_ctrl_l1I_pf_enable, "io_csrio_customCtrl_pf_ctrl_l1I_pf_enable")
    `CK(g_io_csrio_customCtrl_pf_ctrl_l2_pf_enable, i_io_csrio_customCtrl_pf_ctrl_l2_pf_enable, "io_csrio_customCtrl_pf_ctrl_l2_pf_enable")
    `CK(g_io_csrio_customCtrl_pf_ctrl_l1D_pf_enable, i_io_csrio_customCtrl_pf_ctrl_l1D_pf_enable, "io_csrio_customCtrl_pf_ctrl_l1D_pf_enable")
    `CK(g_io_csrio_customCtrl_pf_ctrl_l1D_pf_train_on_hit, i_io_csrio_customCtrl_pf_ctrl_l1D_pf_train_on_hit, "io_csrio_customCtrl_pf_ctrl_l1D_pf_train_on_hit")
    `CK(g_io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_agt, i_io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_agt, "io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_agt")
    `CK(g_io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_pht, i_io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_pht, "io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_pht")
    `CK(g_io_csrio_customCtrl_pf_ctrl_l1D_pf_active_threshold, i_io_csrio_customCtrl_pf_ctrl_l1D_pf_active_threshold, "io_csrio_customCtrl_pf_ctrl_l1D_pf_active_threshold")
    `CK(g_io_csrio_customCtrl_pf_ctrl_l1D_pf_active_stride, i_io_csrio_customCtrl_pf_ctrl_l1D_pf_active_stride, "io_csrio_customCtrl_pf_ctrl_l1D_pf_active_stride")
    `CK(g_io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_stride, i_io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_stride, "io_csrio_customCtrl_pf_ctrl_l1D_pf_enable_stride")
    `CK(g_io_csrio_customCtrl_pf_ctrl_l2_pf_store_only, i_io_csrio_customCtrl_pf_ctrl_l2_pf_store_only, "io_csrio_customCtrl_pf_ctrl_l2_pf_store_only")
    `CK(g_io_csrio_customCtrl_pf_ctrl_l2_pf_recv_enable, i_io_csrio_customCtrl_pf_ctrl_l2_pf_recv_enable, "io_csrio_customCtrl_pf_ctrl_l2_pf_recv_enable")
    `CK(g_io_csrio_customCtrl_pf_ctrl_l2_pf_pbop_enable, i_io_csrio_customCtrl_pf_ctrl_l2_pf_pbop_enable, "io_csrio_customCtrl_pf_ctrl_l2_pf_pbop_enable")
    `CK(g_io_csrio_customCtrl_pf_ctrl_l2_pf_vbop_enable, i_io_csrio_customCtrl_pf_ctrl_l2_pf_vbop_enable, "io_csrio_customCtrl_pf_ctrl_l2_pf_vbop_enable")
    `CK(g_io_csrio_customCtrl_lvpred_timeout, i_io_csrio_customCtrl_lvpred_timeout, "io_csrio_customCtrl_lvpred_timeout")
    `CK(g_io_csrio_customCtrl_bp_ctrl_ubtb_enable, i_io_csrio_customCtrl_bp_ctrl_ubtb_enable, "io_csrio_customCtrl_bp_ctrl_ubtb_enable")
    `CK(g_io_csrio_customCtrl_bp_ctrl_btb_enable, i_io_csrio_customCtrl_bp_ctrl_btb_enable, "io_csrio_customCtrl_bp_ctrl_btb_enable")
    `CK(g_io_csrio_customCtrl_bp_ctrl_tage_enable, i_io_csrio_customCtrl_bp_ctrl_tage_enable, "io_csrio_customCtrl_bp_ctrl_tage_enable")
    `CK(g_io_csrio_customCtrl_bp_ctrl_sc_enable, i_io_csrio_customCtrl_bp_ctrl_sc_enable, "io_csrio_customCtrl_bp_ctrl_sc_enable")
    `CK(g_io_csrio_customCtrl_bp_ctrl_ras_enable, i_io_csrio_customCtrl_bp_ctrl_ras_enable, "io_csrio_customCtrl_bp_ctrl_ras_enable")
    `CK(g_io_csrio_customCtrl_ldld_vio_check_enable, i_io_csrio_customCtrl_ldld_vio_check_enable, "io_csrio_customCtrl_ldld_vio_check_enable")
    `CK(g_io_csrio_customCtrl_cache_error_enable, i_io_csrio_customCtrl_cache_error_enable, "io_csrio_customCtrl_cache_error_enable")
    `CK(g_io_csrio_customCtrl_uncache_write_outstanding_enable, i_io_csrio_customCtrl_uncache_write_outstanding_enable, "io_csrio_customCtrl_uncache_write_outstanding_enable")
    `CK(g_io_csrio_customCtrl_hd_misalign_st_enable, i_io_csrio_customCtrl_hd_misalign_st_enable, "io_csrio_customCtrl_hd_misalign_st_enable")
    `CK(g_io_csrio_customCtrl_hd_misalign_ld_enable, i_io_csrio_customCtrl_hd_misalign_ld_enable, "io_csrio_customCtrl_hd_misalign_ld_enable")
    `CK(g_io_csrio_customCtrl_power_down_enable, i_io_csrio_customCtrl_power_down_enable, "io_csrio_customCtrl_power_down_enable")
    `CK(g_io_csrio_customCtrl_flush_l2_enable, i_io_csrio_customCtrl_flush_l2_enable, "io_csrio_customCtrl_flush_l2_enable")
    `CK(g_io_csrio_customCtrl_fusion_enable, i_io_csrio_customCtrl_fusion_enable, "io_csrio_customCtrl_fusion_enable")
    `CK(g_io_csrio_customCtrl_wfi_enable, i_io_csrio_customCtrl_wfi_enable, "io_csrio_customCtrl_wfi_enable")
    `CK(g_io_csrio_customCtrl_distribute_csr_w_valid, i_io_csrio_customCtrl_distribute_csr_w_valid, "io_csrio_customCtrl_distribute_csr_w_valid")
    `CK(g_io_csrio_customCtrl_distribute_csr_w_bits_addr, i_io_csrio_customCtrl_distribute_csr_w_bits_addr, "io_csrio_customCtrl_distribute_csr_w_bits_addr")
    `CK(g_io_csrio_customCtrl_distribute_csr_w_bits_data, i_io_csrio_customCtrl_distribute_csr_w_bits_data, "io_csrio_customCtrl_distribute_csr_w_bits_data")
    `CK(g_io_csrio_customCtrl_singlestep, i_io_csrio_customCtrl_singlestep, "io_csrio_customCtrl_singlestep")
    `CK(g_io_csrio_customCtrl_frontend_trigger_tUpdate_valid, i_io_csrio_customCtrl_frontend_trigger_tUpdate_valid, "io_csrio_customCtrl_frontend_trigger_tUpdate_valid")
    `CK(g_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_addr, i_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_addr, "io_csrio_customCtrl_frontend_trigger_tUpdate_bits_addr")
    `CK(g_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_matchType, i_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_matchType, "io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_matchType")
    `CK(g_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_select, i_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_select, "io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_select")
    `CK(g_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_action, i_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_action, "io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_action")
    `CK(g_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_chain, i_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_chain, "io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_chain")
    `CK(g_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_tdata2, i_io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_tdata2, "io_csrio_customCtrl_frontend_trigger_tUpdate_bits_tdata_tdata2")
    `CK(g_io_csrio_customCtrl_frontend_trigger_tEnableVec_0, i_io_csrio_customCtrl_frontend_trigger_tEnableVec_0, "io_csrio_customCtrl_frontend_trigger_tEnableVec_0")
    `CK(g_io_csrio_customCtrl_frontend_trigger_tEnableVec_1, i_io_csrio_customCtrl_frontend_trigger_tEnableVec_1, "io_csrio_customCtrl_frontend_trigger_tEnableVec_1")
    `CK(g_io_csrio_customCtrl_frontend_trigger_tEnableVec_2, i_io_csrio_customCtrl_frontend_trigger_tEnableVec_2, "io_csrio_customCtrl_frontend_trigger_tEnableVec_2")
    `CK(g_io_csrio_customCtrl_frontend_trigger_tEnableVec_3, i_io_csrio_customCtrl_frontend_trigger_tEnableVec_3, "io_csrio_customCtrl_frontend_trigger_tEnableVec_3")
    `CK(g_io_csrio_customCtrl_frontend_trigger_debugMode, i_io_csrio_customCtrl_frontend_trigger_debugMode, "io_csrio_customCtrl_frontend_trigger_debugMode")
    `CK(g_io_csrio_customCtrl_frontend_trigger_triggerCanRaiseBpExp, i_io_csrio_customCtrl_frontend_trigger_triggerCanRaiseBpExp, "io_csrio_customCtrl_frontend_trigger_triggerCanRaiseBpExp")
    `CK(g_io_csrio_customCtrl_mem_trigger_tUpdate_valid, i_io_csrio_customCtrl_mem_trigger_tUpdate_valid, "io_csrio_customCtrl_mem_trigger_tUpdate_valid")
    `CK(g_io_csrio_customCtrl_mem_trigger_tUpdate_bits_addr, i_io_csrio_customCtrl_mem_trigger_tUpdate_bits_addr, "io_csrio_customCtrl_mem_trigger_tUpdate_bits_addr")
    `CK(g_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_matchType, i_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_matchType, "io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_matchType")
    `CK(g_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_select, i_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_select, "io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_select")
    `CK(g_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_action, i_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_action, "io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_action")
    `CK(g_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_chain, i_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_chain, "io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_chain")
    `CK(g_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_store, i_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_store, "io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_store")
    `CK(g_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_load, i_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_load, "io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_load")
    `CK(g_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_tdata2, i_io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_tdata2, "io_csrio_customCtrl_mem_trigger_tUpdate_bits_tdata_tdata2")
    `CK(g_io_csrio_customCtrl_mem_trigger_tEnableVec_0, i_io_csrio_customCtrl_mem_trigger_tEnableVec_0, "io_csrio_customCtrl_mem_trigger_tEnableVec_0")
    `CK(g_io_csrio_customCtrl_mem_trigger_tEnableVec_1, i_io_csrio_customCtrl_mem_trigger_tEnableVec_1, "io_csrio_customCtrl_mem_trigger_tEnableVec_1")
    `CK(g_io_csrio_customCtrl_mem_trigger_tEnableVec_2, i_io_csrio_customCtrl_mem_trigger_tEnableVec_2, "io_csrio_customCtrl_mem_trigger_tEnableVec_2")
    `CK(g_io_csrio_customCtrl_mem_trigger_tEnableVec_3, i_io_csrio_customCtrl_mem_trigger_tEnableVec_3, "io_csrio_customCtrl_mem_trigger_tEnableVec_3")
    `CK(g_io_csrio_customCtrl_mem_trigger_debugMode, i_io_csrio_customCtrl_mem_trigger_debugMode, "io_csrio_customCtrl_mem_trigger_debugMode")
    `CK(g_io_csrio_customCtrl_mem_trigger_triggerCanRaiseBpExp, i_io_csrio_customCtrl_mem_trigger_triggerCanRaiseBpExp, "io_csrio_customCtrl_mem_trigger_triggerCanRaiseBpExp")
    `CK(g_io_csrio_customCtrl_fsIsOff, i_io_csrio_customCtrl_fsIsOff, "io_csrio_customCtrl_fsIsOff")
    `CK(g_io_csrio_instrAddrTransType_bare, i_io_csrio_instrAddrTransType_bare, "io_csrio_instrAddrTransType_bare")
    `CK(g_io_csrio_instrAddrTransType_sv39, i_io_csrio_instrAddrTransType_sv39, "io_csrio_instrAddrTransType_sv39")
    `CK(g_io_csrio_instrAddrTransType_sv39x4, i_io_csrio_instrAddrTransType_sv39x4, "io_csrio_instrAddrTransType_sv39x4")
    `CK(g_io_csrio_instrAddrTransType_sv48, i_io_csrio_instrAddrTransType_sv48, "io_csrio_instrAddrTransType_sv48")
    `CK(g_io_csrio_instrAddrTransType_sv48x4, i_io_csrio_instrAddrTransType_sv48x4, "io_csrio_instrAddrTransType_sv48x4")
    `CK(g_io_csrToDecode_illegalInst_sfenceVMA, i_io_csrToDecode_illegalInst_sfenceVMA, "io_csrToDecode_illegalInst_sfenceVMA")
    `CK(g_io_csrToDecode_illegalInst_sfencePart, i_io_csrToDecode_illegalInst_sfencePart, "io_csrToDecode_illegalInst_sfencePart")
    `CK(g_io_csrToDecode_illegalInst_hfenceGVMA, i_io_csrToDecode_illegalInst_hfenceGVMA, "io_csrToDecode_illegalInst_hfenceGVMA")
    `CK(g_io_csrToDecode_illegalInst_hfenceVVMA, i_io_csrToDecode_illegalInst_hfenceVVMA, "io_csrToDecode_illegalInst_hfenceVVMA")
    `CK(g_io_csrToDecode_illegalInst_hlsv, i_io_csrToDecode_illegalInst_hlsv, "io_csrToDecode_illegalInst_hlsv")
    `CK(g_io_csrToDecode_illegalInst_fsIsOff, i_io_csrToDecode_illegalInst_fsIsOff, "io_csrToDecode_illegalInst_fsIsOff")
    `CK(g_io_csrToDecode_illegalInst_vsIsOff, i_io_csrToDecode_illegalInst_vsIsOff, "io_csrToDecode_illegalInst_vsIsOff")
    `CK(g_io_csrToDecode_illegalInst_wfi, i_io_csrToDecode_illegalInst_wfi, "io_csrToDecode_illegalInst_wfi")
    `CK(g_io_csrToDecode_illegalInst_wrs_nto, i_io_csrToDecode_illegalInst_wrs_nto, "io_csrToDecode_illegalInst_wrs_nto")
    `CK(g_io_csrToDecode_illegalInst_frm, i_io_csrToDecode_illegalInst_frm, "io_csrToDecode_illegalInst_frm")
    `CK(g_io_csrToDecode_illegalInst_cboZ, i_io_csrToDecode_illegalInst_cboZ, "io_csrToDecode_illegalInst_cboZ")
    `CK(g_io_csrToDecode_illegalInst_cboCF, i_io_csrToDecode_illegalInst_cboCF, "io_csrToDecode_illegalInst_cboCF")
    `CK(g_io_csrToDecode_illegalInst_cboI, i_io_csrToDecode_illegalInst_cboI, "io_csrToDecode_illegalInst_cboI")
    `CK(g_io_csrToDecode_virtualInst_sfenceVMA, i_io_csrToDecode_virtualInst_sfenceVMA, "io_csrToDecode_virtualInst_sfenceVMA")
    `CK(g_io_csrToDecode_virtualInst_sfencePart, i_io_csrToDecode_virtualInst_sfencePart, "io_csrToDecode_virtualInst_sfencePart")
    `CK(g_io_csrToDecode_virtualInst_hfence, i_io_csrToDecode_virtualInst_hfence, "io_csrToDecode_virtualInst_hfence")
    `CK(g_io_csrToDecode_virtualInst_hlsv, i_io_csrToDecode_virtualInst_hlsv, "io_csrToDecode_virtualInst_hlsv")
    `CK(g_io_csrToDecode_virtualInst_wfi, i_io_csrToDecode_virtualInst_wfi, "io_csrToDecode_virtualInst_wfi")
    `CK(g_io_csrToDecode_virtualInst_wrs_nto, i_io_csrToDecode_virtualInst_wrs_nto, "io_csrToDecode_virtualInst_wrs_nto")
    `CK(g_io_csrToDecode_virtualInst_cboZ, i_io_csrToDecode_virtualInst_cboZ, "io_csrToDecode_virtualInst_cboZ")
    `CK(g_io_csrToDecode_virtualInst_cboCF, i_io_csrToDecode_virtualInst_cboCF, "io_csrToDecode_virtualInst_cboCF")
    `CK(g_io_csrToDecode_virtualInst_cboI, i_io_csrToDecode_virtualInst_cboI, "io_csrToDecode_virtualInst_cboI")
    `CK(g_io_csrToDecode_special_cboI2F, i_io_csrToDecode_special_cboI2F, "io_csrToDecode_special_cboI2F")
    `CK(g_io_error_0, i_io_error_0, "io_error_0")
  endtask

  initial begin
    io_flush_valid = 0;
    io_flush_bits_robIdx_flag = 0;
    io_flush_bits_robIdx_value = 0;
    io_flush_bits_ftqIdx_flag = 0;
    io_flush_bits_ftqIdx_value = 0;
    io_flush_bits_ftqOffset = 0;
    io_flush_bits_level = 0;
    io_flush_bits_cfiUpdate_backendIGPF = 0;
    io_flush_bits_cfiUpdate_backendIPF = 0;
    io_flush_bits_cfiUpdate_backendIAF = 0;
    io_flush_bits_fullTarget = 0;
    io_in_valid = 0;
    io_in_bits_ctrl_fuOpType = 0;
    io_in_bits_ctrl_robIdx_flag = 0;
    io_in_bits_ctrl_robIdx_value = 0;
    io_in_bits_ctrl_pdest = 0;
    io_in_bits_ctrl_rfWen = 0;
    io_in_bits_ctrl_ftqIdx_flag = 0;
    io_in_bits_ctrl_ftqIdx_value = 0;
    io_in_bits_ctrl_ftqOffset = 0;
    io_in_bits_data_src_0 = 0;
    io_in_bits_data_imm = 0;
    io_in_bits_perfDebugInfo_enqRsTime = 0;
    io_in_bits_perfDebugInfo_selectTime = 0;
    io_in_bits_perfDebugInfo_issueTime = 0;
    io_out_ready = 0;
    io_csrin_hartId = 0;
    io_csrin_msiInfo_valid = 0;
    io_csrin_msiInfo_bits = 0;
    io_csrin_criticalErrorState = 0;
    io_csrin_clintTime_valid = 0;
    io_csrin_clintTime_bits = 0;
    io_csrin_l2FlushDone = 0;
    io_csrin_trapInstInfo_valid = 0;
    io_csrin_trapInstInfo_bits_instr = 0;
    io_csrin_trapInstInfo_bits_ftqPtr_flag = 0;
    io_csrin_trapInstInfo_bits_ftqPtr_value = 0;
    io_csrin_trapInstInfo_bits_ftqOffset = 0;
    io_csrin_fromVecExcpMod_busy = 0;
    io_csrio_perf_perfEventsFrontend_0_value = 0;
    io_csrio_perf_perfEventsFrontend_1_value = 0;
    io_csrio_perf_perfEventsFrontend_2_value = 0;
    io_csrio_perf_perfEventsFrontend_3_value = 0;
    io_csrio_perf_perfEventsFrontend_4_value = 0;
    io_csrio_perf_perfEventsFrontend_5_value = 0;
    io_csrio_perf_perfEventsFrontend_6_value = 0;
    io_csrio_perf_perfEventsFrontend_7_value = 0;
    io_csrio_perf_perfEventsBackend_0_value = 0;
    io_csrio_perf_perfEventsBackend_1_value = 0;
    io_csrio_perf_perfEventsBackend_2_value = 0;
    io_csrio_perf_perfEventsBackend_3_value = 0;
    io_csrio_perf_perfEventsBackend_4_value = 0;
    io_csrio_perf_perfEventsBackend_5_value = 0;
    io_csrio_perf_perfEventsBackend_6_value = 0;
    io_csrio_perf_perfEventsBackend_7_value = 0;
    io_csrio_perf_perfEventsLsu_0_value = 0;
    io_csrio_perf_perfEventsLsu_1_value = 0;
    io_csrio_perf_perfEventsLsu_2_value = 0;
    io_csrio_perf_perfEventsLsu_3_value = 0;
    io_csrio_perf_perfEventsLsu_4_value = 0;
    io_csrio_perf_perfEventsLsu_5_value = 0;
    io_csrio_perf_perfEventsLsu_6_value = 0;
    io_csrio_perf_perfEventsLsu_7_value = 0;
    io_csrio_perf_perfEventsHc_0_value = 0;
    io_csrio_perf_perfEventsHc_1_value = 0;
    io_csrio_perf_perfEventsHc_2_value = 0;
    io_csrio_perf_perfEventsHc_3_value = 0;
    io_csrio_perf_perfEventsHc_4_value = 0;
    io_csrio_perf_perfEventsHc_5_value = 0;
    io_csrio_perf_perfEventsHc_6_value = 0;
    io_csrio_perf_perfEventsHc_7_value = 0;
    io_csrio_perf_perfEventsHc_8_value = 0;
    io_csrio_perf_perfEventsHc_9_value = 0;
    io_csrio_perf_perfEventsHc_10_value = 0;
    io_csrio_perf_perfEventsHc_11_value = 0;
    io_csrio_perf_perfEventsHc_12_value = 0;
    io_csrio_perf_perfEventsHc_13_value = 0;
    io_csrio_perf_perfEventsHc_14_value = 0;
    io_csrio_perf_perfEventsHc_15_value = 0;
    io_csrio_perf_perfEventsHc_16_value = 0;
    io_csrio_perf_perfEventsHc_17_value = 0;
    io_csrio_perf_perfEventsHc_18_value = 0;
    io_csrio_perf_perfEventsHc_19_value = 0;
    io_csrio_perf_perfEventsHc_20_value = 0;
    io_csrio_perf_perfEventsHc_21_value = 0;
    io_csrio_perf_perfEventsHc_22_value = 0;
    io_csrio_perf_perfEventsHc_23_value = 0;
    io_csrio_perf_perfEventsHc_24_value = 0;
    io_csrio_perf_perfEventsHc_25_value = 0;
    io_csrio_perf_perfEventsHc_26_value = 0;
    io_csrio_perf_perfEventsHc_27_value = 0;
    io_csrio_perf_perfEventsHc_28_value = 0;
    io_csrio_perf_perfEventsHc_29_value = 0;
    io_csrio_perf_perfEventsHc_30_value = 0;
    io_csrio_perf_perfEventsHc_31_value = 0;
    io_csrio_perf_perfEventsHc_32_value = 0;
    io_csrio_perf_perfEventsHc_33_value = 0;
    io_csrio_perf_perfEventsHc_34_value = 0;
    io_csrio_perf_perfEventsHc_35_value = 0;
    io_csrio_perf_perfEventsHc_36_value = 0;
    io_csrio_perf_perfEventsHc_37_value = 0;
    io_csrio_perf_perfEventsHc_38_value = 0;
    io_csrio_perf_perfEventsHc_39_value = 0;
    io_csrio_perf_perfEventsHc_40_value = 0;
    io_csrio_perf_perfEventsHc_41_value = 0;
    io_csrio_perf_perfEventsHc_42_value = 0;
    io_csrio_perf_perfEventsHc_43_value = 0;
    io_csrio_perf_perfEventsHc_44_value = 0;
    io_csrio_perf_perfEventsHc_45_value = 0;
    io_csrio_perf_perfEventsHc_46_value = 0;
    io_csrio_perf_perfEventsHc_47_value = 0;
    io_csrio_perf_retiredInstr = 0;
    io_csrio_fpu_fflags_valid = 0;
    io_csrio_fpu_fflags_bits = 0;
    io_csrio_fpu_dirty_fs = 0;
    io_csrio_vpu_vl = 0;
    io_csrio_vpu_set_vstart_valid = 0;
    io_csrio_vpu_set_vstart_bits = 0;
    io_csrio_vpu_set_vtype_valid = 0;
    io_csrio_vpu_set_vtype_bits = 0;
    io_csrio_vpu_set_vxsat_valid = 0;
    io_csrio_vpu_set_vxsat_bits = 0;
    io_csrio_vpu_dirty_vs = 0;
    io_csrio_exception_valid = 0;
    io_csrio_exception_bits_pc = 0;
    io_csrio_exception_bits_exceptionVec_0 = 0;
    io_csrio_exception_bits_exceptionVec_1 = 0;
    io_csrio_exception_bits_exceptionVec_2 = 0;
    io_csrio_exception_bits_exceptionVec_3 = 0;
    io_csrio_exception_bits_exceptionVec_4 = 0;
    io_csrio_exception_bits_exceptionVec_5 = 0;
    io_csrio_exception_bits_exceptionVec_6 = 0;
    io_csrio_exception_bits_exceptionVec_7 = 0;
    io_csrio_exception_bits_exceptionVec_8 = 0;
    io_csrio_exception_bits_exceptionVec_9 = 0;
    io_csrio_exception_bits_exceptionVec_10 = 0;
    io_csrio_exception_bits_exceptionVec_11 = 0;
    io_csrio_exception_bits_exceptionVec_12 = 0;
    io_csrio_exception_bits_exceptionVec_13 = 0;
    io_csrio_exception_bits_exceptionVec_14 = 0;
    io_csrio_exception_bits_exceptionVec_15 = 0;
    io_csrio_exception_bits_exceptionVec_16 = 0;
    io_csrio_exception_bits_exceptionVec_17 = 0;
    io_csrio_exception_bits_exceptionVec_18 = 0;
    io_csrio_exception_bits_exceptionVec_19 = 0;
    io_csrio_exception_bits_exceptionVec_20 = 0;
    io_csrio_exception_bits_exceptionVec_21 = 0;
    io_csrio_exception_bits_exceptionVec_22 = 0;
    io_csrio_exception_bits_exceptionVec_23 = 0;
    io_csrio_exception_bits_isPcBkpt = 0;
    io_csrio_exception_bits_isFetchMalAddr = 0;
    io_csrio_exception_bits_gpaddr = 0;
    io_csrio_exception_bits_singleStep = 0;
    io_csrio_exception_bits_crossPageIPFFix = 0;
    io_csrio_exception_bits_isInterrupt = 0;
    io_csrio_exception_bits_isHls = 0;
    io_csrio_exception_bits_trigger = 0;
    io_csrio_exception_bits_isForVSnonLeafPTE = 0;
    io_csrio_robDeqPtr_flag = 0;
    io_csrio_robDeqPtr_value = 0;
    io_csrio_memExceptionVAddr = 0;
    io_csrio_memExceptionGPAddr = 0;
    io_csrio_memExceptionIsForVSnonLeafPTE = 0;
    io_csrio_externalInterrupt_mtip = 0;
    io_csrio_externalInterrupt_msip = 0;
    io_csrio_externalInterrupt_meip = 0;
    io_csrio_externalInterrupt_seip = 0;
    io_csrio_externalInterrupt_debug = 0;
    io_csrio_externalInterrupt_nmi_nmi_31 = 0;
    io_csrio_externalInterrupt_nmi_nmi_43 = 0;
    repeat(4) @(posedge clk);
    #1 rst=0;
    drive_inputs();
    repeat(NCYCLES) begin
      @(posedge clk);
      #1 check_outputs();
      drive_inputs();
    end
    $display("checks=%0d errors=%0d",checks,errors);
    if(errors==0 && checks>1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
