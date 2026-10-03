// 自动生成：verif/ut/ExceptionGen/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// ExceptionGen 双例化逐拍比对：golden vs 重写 ExceptionGen_xs，全部 io_state_* 逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= ExceptionGen =================
  int unsigned eg_mode = 0;
  logic       eg_win_flag = 1'b0;
  logic [7:0] eg_win_base = 8'd0;
  function automatic logic [8:0] eg_rob();
    logic [7:0] v;
    if ($urandom_range(0, 7) == 0) return 9'($urandom);
    v = eg_win_base + 8'($urandom_range(0, 7));
    return {eg_win_flag ^ ($urandom_range(0, 15) == 0), v};
  endfunction
  logic eg_reset;
  logic eg_io_redirect_valid;
  logic eg_io_redirect_bits_robIdx_flag;
  logic [7:0] eg_io_redirect_bits_robIdx_value;
  logic eg_io_redirect_bits_level;
  logic eg_io_flush;
  logic eg_io_enq_0_valid;
  logic eg_io_enq_0_bits_robIdx_flag;
  logic [7:0] eg_io_enq_0_bits_robIdx_value;
  logic [5:0] eg_io_enq_0_bits_ftqPtr_value;
  logic [3:0] eg_io_enq_0_bits_ftqOffset;
  logic eg_io_enq_0_bits_hasException;
  logic eg_io_enq_0_bits_exceptionVec_0;
  logic eg_io_enq_0_bits_exceptionVec_1;
  logic eg_io_enq_0_bits_exceptionVec_2;
  logic eg_io_enq_0_bits_exceptionVec_3;
  logic eg_io_enq_0_bits_exceptionVec_12;
  logic eg_io_enq_0_bits_exceptionVec_20;
  logic eg_io_enq_0_bits_exceptionVec_22;
  logic eg_io_enq_0_bits_isFetchMalAddr;
  logic eg_io_enq_0_bits_satpFlushFirstFetchFault;
  logic eg_io_enq_0_bits_flushPipe;
  logic eg_io_enq_0_bits_isVset;
  logic eg_io_enq_0_bits_singleStep;
  logic eg_io_enq_0_bits_crossPageIPFFix;
  logic [3:0] eg_io_enq_0_bits_trigger;
  logic eg_io_enq_1_valid;
  logic eg_io_enq_1_bits_robIdx_flag;
  logic [7:0] eg_io_enq_1_bits_robIdx_value;
  logic [5:0] eg_io_enq_1_bits_ftqPtr_value;
  logic [3:0] eg_io_enq_1_bits_ftqOffset;
  logic eg_io_enq_1_bits_hasException;
  logic eg_io_enq_1_bits_exceptionVec_0;
  logic eg_io_enq_1_bits_exceptionVec_1;
  logic eg_io_enq_1_bits_exceptionVec_2;
  logic eg_io_enq_1_bits_exceptionVec_3;
  logic eg_io_enq_1_bits_exceptionVec_12;
  logic eg_io_enq_1_bits_exceptionVec_20;
  logic eg_io_enq_1_bits_exceptionVec_22;
  logic eg_io_enq_1_bits_isFetchMalAddr;
  logic eg_io_enq_1_bits_satpFlushFirstFetchFault;
  logic eg_io_enq_1_bits_flushPipe;
  logic eg_io_enq_1_bits_isVset;
  logic eg_io_enq_1_bits_singleStep;
  logic eg_io_enq_1_bits_crossPageIPFFix;
  logic [3:0] eg_io_enq_1_bits_trigger;
  logic eg_io_enq_2_valid;
  logic eg_io_enq_2_bits_robIdx_flag;
  logic [7:0] eg_io_enq_2_bits_robIdx_value;
  logic [5:0] eg_io_enq_2_bits_ftqPtr_value;
  logic [3:0] eg_io_enq_2_bits_ftqOffset;
  logic eg_io_enq_2_bits_hasException;
  logic eg_io_enq_2_bits_exceptionVec_0;
  logic eg_io_enq_2_bits_exceptionVec_1;
  logic eg_io_enq_2_bits_exceptionVec_2;
  logic eg_io_enq_2_bits_exceptionVec_3;
  logic eg_io_enq_2_bits_exceptionVec_12;
  logic eg_io_enq_2_bits_exceptionVec_20;
  logic eg_io_enq_2_bits_exceptionVec_22;
  logic eg_io_enq_2_bits_isFetchMalAddr;
  logic eg_io_enq_2_bits_satpFlushFirstFetchFault;
  logic eg_io_enq_2_bits_flushPipe;
  logic eg_io_enq_2_bits_isVset;
  logic eg_io_enq_2_bits_singleStep;
  logic eg_io_enq_2_bits_crossPageIPFFix;
  logic [3:0] eg_io_enq_2_bits_trigger;
  logic eg_io_enq_3_valid;
  logic eg_io_enq_3_bits_robIdx_flag;
  logic [7:0] eg_io_enq_3_bits_robIdx_value;
  logic [5:0] eg_io_enq_3_bits_ftqPtr_value;
  logic [3:0] eg_io_enq_3_bits_ftqOffset;
  logic eg_io_enq_3_bits_hasException;
  logic eg_io_enq_3_bits_exceptionVec_0;
  logic eg_io_enq_3_bits_exceptionVec_1;
  logic eg_io_enq_3_bits_exceptionVec_2;
  logic eg_io_enq_3_bits_exceptionVec_3;
  logic eg_io_enq_3_bits_exceptionVec_12;
  logic eg_io_enq_3_bits_exceptionVec_20;
  logic eg_io_enq_3_bits_exceptionVec_22;
  logic eg_io_enq_3_bits_isFetchMalAddr;
  logic eg_io_enq_3_bits_satpFlushFirstFetchFault;
  logic eg_io_enq_3_bits_flushPipe;
  logic eg_io_enq_3_bits_isVset;
  logic eg_io_enq_3_bits_singleStep;
  logic eg_io_enq_3_bits_crossPageIPFFix;
  logic [3:0] eg_io_enq_3_bits_trigger;
  logic eg_io_enq_4_valid;
  logic eg_io_enq_4_bits_robIdx_flag;
  logic [7:0] eg_io_enq_4_bits_robIdx_value;
  logic [5:0] eg_io_enq_4_bits_ftqPtr_value;
  logic [3:0] eg_io_enq_4_bits_ftqOffset;
  logic eg_io_enq_4_bits_hasException;
  logic eg_io_enq_4_bits_exceptionVec_0;
  logic eg_io_enq_4_bits_exceptionVec_1;
  logic eg_io_enq_4_bits_exceptionVec_2;
  logic eg_io_enq_4_bits_exceptionVec_3;
  logic eg_io_enq_4_bits_exceptionVec_12;
  logic eg_io_enq_4_bits_exceptionVec_20;
  logic eg_io_enq_4_bits_exceptionVec_22;
  logic eg_io_enq_4_bits_isFetchMalAddr;
  logic eg_io_enq_4_bits_satpFlushFirstFetchFault;
  logic eg_io_enq_4_bits_flushPipe;
  logic eg_io_enq_4_bits_isVset;
  logic eg_io_enq_4_bits_singleStep;
  logic eg_io_enq_4_bits_crossPageIPFFix;
  logic [3:0] eg_io_enq_4_bits_trigger;
  logic eg_io_enq_5_valid;
  logic eg_io_enq_5_bits_robIdx_flag;
  logic [7:0] eg_io_enq_5_bits_robIdx_value;
  logic [5:0] eg_io_enq_5_bits_ftqPtr_value;
  logic [3:0] eg_io_enq_5_bits_ftqOffset;
  logic eg_io_enq_5_bits_hasException;
  logic eg_io_enq_5_bits_exceptionVec_0;
  logic eg_io_enq_5_bits_exceptionVec_1;
  logic eg_io_enq_5_bits_exceptionVec_2;
  logic eg_io_enq_5_bits_exceptionVec_3;
  logic eg_io_enq_5_bits_exceptionVec_12;
  logic eg_io_enq_5_bits_exceptionVec_20;
  logic eg_io_enq_5_bits_exceptionVec_22;
  logic eg_io_enq_5_bits_isFetchMalAddr;
  logic eg_io_enq_5_bits_satpFlushFirstFetchFault;
  logic eg_io_enq_5_bits_flushPipe;
  logic eg_io_enq_5_bits_isVset;
  logic eg_io_enq_5_bits_singleStep;
  logic eg_io_enq_5_bits_crossPageIPFFix;
  logic [3:0] eg_io_enq_5_bits_trigger;
  logic eg_io_wb_0_valid;
  logic eg_io_wb_0_bits_robIdx_flag;
  logic [7:0] eg_io_wb_0_bits_robIdx_value;
  logic eg_io_wb_0_bits_hasException;
  logic eg_io_wb_0_bits_exceptionVec_2;
  logic eg_io_wb_0_bits_exceptionVec_3;
  logic eg_io_wb_0_bits_exceptionVec_8;
  logic eg_io_wb_0_bits_exceptionVec_9;
  logic eg_io_wb_0_bits_exceptionVec_10;
  logic eg_io_wb_0_bits_exceptionVec_11;
  logic eg_io_wb_0_bits_exceptionVec_22;
  logic eg_io_wb_0_bits_flushPipe;
  logic eg_io_wb_0_bits_satpFlushPipe;
  logic eg_io_wb_1_valid;
  logic eg_io_wb_1_bits_robIdx_flag;
  logic [7:0] eg_io_wb_1_bits_robIdx_value;
  logic eg_io_wb_1_bits_hasException;
  logic eg_io_wb_1_bits_exceptionVec_2;
  logic eg_io_wb_2_valid;
  logic eg_io_wb_2_bits_robIdx_flag;
  logic [7:0] eg_io_wb_2_bits_robIdx_value;
  logic eg_io_wb_2_bits_hasException;
  logic eg_io_wb_2_bits_exceptionVec_2;
  logic eg_io_wb_3_bits_robIdx_flag;
  logic [7:0] eg_io_wb_3_bits_robIdx_value;
  logic eg_io_wb_4_bits_robIdx_flag;
  logic [7:0] eg_io_wb_4_bits_robIdx_value;
  logic eg_io_wb_5_bits_robIdx_flag;
  logic [7:0] eg_io_wb_5_bits_robIdx_value;
  logic eg_io_wb_6_valid;
  logic eg_io_wb_6_bits_robIdx_flag;
  logic [7:0] eg_io_wb_6_bits_robIdx_value;
  logic eg_io_wb_6_bits_hasException;
  logic eg_io_wb_6_bits_exceptionVec_0;
  logic eg_io_wb_6_bits_exceptionVec_1;
  logic eg_io_wb_6_bits_exceptionVec_2;
  logic eg_io_wb_6_bits_exceptionVec_3;
  logic eg_io_wb_6_bits_exceptionVec_4;
  logic eg_io_wb_6_bits_exceptionVec_5;
  logic eg_io_wb_6_bits_exceptionVec_6;
  logic eg_io_wb_6_bits_exceptionVec_7;
  logic eg_io_wb_6_bits_exceptionVec_8;
  logic eg_io_wb_6_bits_exceptionVec_9;
  logic eg_io_wb_6_bits_exceptionVec_10;
  logic eg_io_wb_6_bits_exceptionVec_11;
  logic eg_io_wb_6_bits_exceptionVec_12;
  logic eg_io_wb_6_bits_exceptionVec_13;
  logic eg_io_wb_6_bits_exceptionVec_14;
  logic eg_io_wb_6_bits_exceptionVec_15;
  logic eg_io_wb_6_bits_exceptionVec_16;
  logic eg_io_wb_6_bits_exceptionVec_17;
  logic eg_io_wb_6_bits_exceptionVec_18;
  logic eg_io_wb_6_bits_exceptionVec_19;
  logic eg_io_wb_6_bits_exceptionVec_20;
  logic eg_io_wb_6_bits_exceptionVec_21;
  logic eg_io_wb_6_bits_exceptionVec_22;
  logic eg_io_wb_6_bits_exceptionVec_23;
  logic eg_io_wb_6_bits_flushPipe;
  logic [3:0] eg_io_wb_6_bits_trigger;
  logic eg_io_wb_7_valid;
  logic eg_io_wb_7_bits_robIdx_flag;
  logic [7:0] eg_io_wb_7_bits_robIdx_value;
  logic eg_io_wb_7_bits_hasException;
  logic eg_io_wb_7_bits_exceptionVec_0;
  logic eg_io_wb_7_bits_exceptionVec_1;
  logic eg_io_wb_7_bits_exceptionVec_2;
  logic eg_io_wb_7_bits_exceptionVec_3;
  logic eg_io_wb_7_bits_exceptionVec_4;
  logic eg_io_wb_7_bits_exceptionVec_5;
  logic eg_io_wb_7_bits_exceptionVec_6;
  logic eg_io_wb_7_bits_exceptionVec_7;
  logic eg_io_wb_7_bits_exceptionVec_8;
  logic eg_io_wb_7_bits_exceptionVec_9;
  logic eg_io_wb_7_bits_exceptionVec_10;
  logic eg_io_wb_7_bits_exceptionVec_11;
  logic eg_io_wb_7_bits_exceptionVec_12;
  logic eg_io_wb_7_bits_exceptionVec_13;
  logic eg_io_wb_7_bits_exceptionVec_14;
  logic eg_io_wb_7_bits_exceptionVec_15;
  logic eg_io_wb_7_bits_exceptionVec_16;
  logic eg_io_wb_7_bits_exceptionVec_17;
  logic eg_io_wb_7_bits_exceptionVec_18;
  logic eg_io_wb_7_bits_exceptionVec_19;
  logic eg_io_wb_7_bits_exceptionVec_20;
  logic eg_io_wb_7_bits_exceptionVec_21;
  logic eg_io_wb_7_bits_exceptionVec_22;
  logic eg_io_wb_7_bits_exceptionVec_23;
  logic eg_io_wb_7_bits_flushPipe;
  logic [3:0] eg_io_wb_7_bits_trigger;
  logic eg_io_wb_8_valid;
  logic eg_io_wb_8_bits_robIdx_flag;
  logic [7:0] eg_io_wb_8_bits_robIdx_value;
  logic eg_io_wb_8_bits_hasException;
  logic eg_io_wb_8_bits_exceptionVec_0;
  logic eg_io_wb_8_bits_exceptionVec_1;
  logic eg_io_wb_8_bits_exceptionVec_2;
  logic eg_io_wb_8_bits_exceptionVec_3;
  logic eg_io_wb_8_bits_exceptionVec_4;
  logic eg_io_wb_8_bits_exceptionVec_5;
  logic eg_io_wb_8_bits_exceptionVec_6;
  logic eg_io_wb_8_bits_exceptionVec_7;
  logic eg_io_wb_8_bits_exceptionVec_8;
  logic eg_io_wb_8_bits_exceptionVec_9;
  logic eg_io_wb_8_bits_exceptionVec_10;
  logic eg_io_wb_8_bits_exceptionVec_11;
  logic eg_io_wb_8_bits_exceptionVec_12;
  logic eg_io_wb_8_bits_exceptionVec_13;
  logic eg_io_wb_8_bits_exceptionVec_14;
  logic eg_io_wb_8_bits_exceptionVec_15;
  logic eg_io_wb_8_bits_exceptionVec_16;
  logic eg_io_wb_8_bits_exceptionVec_17;
  logic eg_io_wb_8_bits_exceptionVec_18;
  logic eg_io_wb_8_bits_exceptionVec_19;
  logic eg_io_wb_8_bits_exceptionVec_20;
  logic eg_io_wb_8_bits_exceptionVec_21;
  logic eg_io_wb_8_bits_exceptionVec_22;
  logic eg_io_wb_8_bits_exceptionVec_23;
  logic eg_io_wb_8_bits_flushPipe;
  logic eg_io_wb_8_bits_replayInst;
  logic [3:0] eg_io_wb_8_bits_trigger;
  logic eg_io_wb_9_valid;
  logic eg_io_wb_9_bits_robIdx_flag;
  logic [7:0] eg_io_wb_9_bits_robIdx_value;
  logic eg_io_wb_9_bits_hasException;
  logic eg_io_wb_9_bits_exceptionVec_0;
  logic eg_io_wb_9_bits_exceptionVec_1;
  logic eg_io_wb_9_bits_exceptionVec_2;
  logic eg_io_wb_9_bits_exceptionVec_3;
  logic eg_io_wb_9_bits_exceptionVec_4;
  logic eg_io_wb_9_bits_exceptionVec_5;
  logic eg_io_wb_9_bits_exceptionVec_6;
  logic eg_io_wb_9_bits_exceptionVec_7;
  logic eg_io_wb_9_bits_exceptionVec_8;
  logic eg_io_wb_9_bits_exceptionVec_9;
  logic eg_io_wb_9_bits_exceptionVec_10;
  logic eg_io_wb_9_bits_exceptionVec_11;
  logic eg_io_wb_9_bits_exceptionVec_12;
  logic eg_io_wb_9_bits_exceptionVec_13;
  logic eg_io_wb_9_bits_exceptionVec_14;
  logic eg_io_wb_9_bits_exceptionVec_15;
  logic eg_io_wb_9_bits_exceptionVec_16;
  logic eg_io_wb_9_bits_exceptionVec_17;
  logic eg_io_wb_9_bits_exceptionVec_18;
  logic eg_io_wb_9_bits_exceptionVec_19;
  logic eg_io_wb_9_bits_exceptionVec_20;
  logic eg_io_wb_9_bits_exceptionVec_21;
  logic eg_io_wb_9_bits_exceptionVec_22;
  logic eg_io_wb_9_bits_exceptionVec_23;
  logic eg_io_wb_9_bits_flushPipe;
  logic eg_io_wb_9_bits_replayInst;
  logic [3:0] eg_io_wb_9_bits_trigger;
  logic eg_io_wb_10_valid;
  logic eg_io_wb_10_bits_robIdx_flag;
  logic [7:0] eg_io_wb_10_bits_robIdx_value;
  logic eg_io_wb_10_bits_hasException;
  logic eg_io_wb_10_bits_exceptionVec_0;
  logic eg_io_wb_10_bits_exceptionVec_1;
  logic eg_io_wb_10_bits_exceptionVec_2;
  logic eg_io_wb_10_bits_exceptionVec_3;
  logic eg_io_wb_10_bits_exceptionVec_4;
  logic eg_io_wb_10_bits_exceptionVec_5;
  logic eg_io_wb_10_bits_exceptionVec_6;
  logic eg_io_wb_10_bits_exceptionVec_7;
  logic eg_io_wb_10_bits_exceptionVec_8;
  logic eg_io_wb_10_bits_exceptionVec_9;
  logic eg_io_wb_10_bits_exceptionVec_10;
  logic eg_io_wb_10_bits_exceptionVec_11;
  logic eg_io_wb_10_bits_exceptionVec_12;
  logic eg_io_wb_10_bits_exceptionVec_13;
  logic eg_io_wb_10_bits_exceptionVec_14;
  logic eg_io_wb_10_bits_exceptionVec_15;
  logic eg_io_wb_10_bits_exceptionVec_16;
  logic eg_io_wb_10_bits_exceptionVec_17;
  logic eg_io_wb_10_bits_exceptionVec_18;
  logic eg_io_wb_10_bits_exceptionVec_19;
  logic eg_io_wb_10_bits_exceptionVec_20;
  logic eg_io_wb_10_bits_exceptionVec_21;
  logic eg_io_wb_10_bits_exceptionVec_22;
  logic eg_io_wb_10_bits_exceptionVec_23;
  logic eg_io_wb_10_bits_flushPipe;
  logic eg_io_wb_10_bits_replayInst;
  logic [3:0] eg_io_wb_10_bits_trigger;
  logic eg_io_wb_11_valid;
  logic eg_io_wb_11_bits_robIdx_flag;
  logic [7:0] eg_io_wb_11_bits_robIdx_value;
  logic eg_io_wb_11_bits_hasException;
  logic eg_io_wb_11_bits_exceptionVec_0;
  logic eg_io_wb_11_bits_exceptionVec_1;
  logic eg_io_wb_11_bits_exceptionVec_2;
  logic eg_io_wb_11_bits_exceptionVec_3;
  logic eg_io_wb_11_bits_exceptionVec_4;
  logic eg_io_wb_11_bits_exceptionVec_5;
  logic eg_io_wb_11_bits_exceptionVec_6;
  logic eg_io_wb_11_bits_exceptionVec_7;
  logic eg_io_wb_11_bits_exceptionVec_8;
  logic eg_io_wb_11_bits_exceptionVec_9;
  logic eg_io_wb_11_bits_exceptionVec_10;
  logic eg_io_wb_11_bits_exceptionVec_11;
  logic eg_io_wb_11_bits_exceptionVec_12;
  logic eg_io_wb_11_bits_exceptionVec_13;
  logic eg_io_wb_11_bits_exceptionVec_14;
  logic eg_io_wb_11_bits_exceptionVec_15;
  logic eg_io_wb_11_bits_exceptionVec_16;
  logic eg_io_wb_11_bits_exceptionVec_17;
  logic eg_io_wb_11_bits_exceptionVec_18;
  logic eg_io_wb_11_bits_exceptionVec_19;
  logic eg_io_wb_11_bits_exceptionVec_20;
  logic eg_io_wb_11_bits_exceptionVec_21;
  logic eg_io_wb_11_bits_exceptionVec_22;
  logic eg_io_wb_11_bits_exceptionVec_23;
  logic eg_io_wb_11_bits_flushPipe;
  logic eg_io_wb_11_bits_replayInst;
  logic [3:0] eg_io_wb_11_bits_trigger;
  logic eg_io_wb_11_bits_vstartEn;
  logic [63:0] eg_io_wb_11_bits_vstart;
  logic [6:0] eg_io_wb_11_bits_vuopIdx;
  logic eg_io_wb_11_bits_isVecLoad;
  logic eg_io_wb_11_bits_isVlm;
  logic eg_io_wb_11_bits_isStrided;
  logic eg_io_wb_11_bits_isIndexed;
  logic eg_io_wb_11_bits_isWhole;
  logic [2:0] eg_io_wb_11_bits_nf;
  logic [1:0] eg_io_wb_11_bits_vsew;
  logic [1:0] eg_io_wb_11_bits_veew;
  logic [2:0] eg_io_wb_11_bits_vlmul;
  logic eg_io_wb_12_valid;
  logic eg_io_wb_12_bits_robIdx_flag;
  logic [7:0] eg_io_wb_12_bits_robIdx_value;
  logic eg_io_wb_12_bits_hasException;
  logic eg_io_wb_12_bits_exceptionVec_0;
  logic eg_io_wb_12_bits_exceptionVec_1;
  logic eg_io_wb_12_bits_exceptionVec_2;
  logic eg_io_wb_12_bits_exceptionVec_3;
  logic eg_io_wb_12_bits_exceptionVec_4;
  logic eg_io_wb_12_bits_exceptionVec_5;
  logic eg_io_wb_12_bits_exceptionVec_6;
  logic eg_io_wb_12_bits_exceptionVec_7;
  logic eg_io_wb_12_bits_exceptionVec_8;
  logic eg_io_wb_12_bits_exceptionVec_9;
  logic eg_io_wb_12_bits_exceptionVec_10;
  logic eg_io_wb_12_bits_exceptionVec_11;
  logic eg_io_wb_12_bits_exceptionVec_12;
  logic eg_io_wb_12_bits_exceptionVec_13;
  logic eg_io_wb_12_bits_exceptionVec_14;
  logic eg_io_wb_12_bits_exceptionVec_15;
  logic eg_io_wb_12_bits_exceptionVec_16;
  logic eg_io_wb_12_bits_exceptionVec_17;
  logic eg_io_wb_12_bits_exceptionVec_18;
  logic eg_io_wb_12_bits_exceptionVec_19;
  logic eg_io_wb_12_bits_exceptionVec_20;
  logic eg_io_wb_12_bits_exceptionVec_21;
  logic eg_io_wb_12_bits_exceptionVec_22;
  logic eg_io_wb_12_bits_exceptionVec_23;
  logic eg_io_wb_12_bits_flushPipe;
  logic eg_io_wb_12_bits_replayInst;
  logic [3:0] eg_io_wb_12_bits_trigger;
  logic eg_io_wb_12_bits_vstartEn;
  logic [63:0] eg_io_wb_12_bits_vstart;
  logic [6:0] eg_io_wb_12_bits_vuopIdx;
  logic eg_io_wb_12_bits_isVecLoad;
  logic eg_io_wb_12_bits_isVlm;
  logic eg_io_wb_12_bits_isStrided;
  logic eg_io_wb_12_bits_isIndexed;
  logic eg_io_wb_12_bits_isWhole;
  logic [2:0] eg_io_wb_12_bits_nf;
  logic [1:0] eg_io_wb_12_bits_vsew;
  logic [1:0] eg_io_wb_12_bits_veew;
  logic [2:0] eg_io_wb_12_bits_vlmul;
  wire  eg_g_io_state_valid, eg_i_io_state_valid;
  logic eg_s0_io_state_valid = '0, eg_s1_io_state_valid = '0;
  wire  eg_g_io_state_bits_robIdx_flag, eg_i_io_state_bits_robIdx_flag;
  logic eg_s0_io_state_bits_robIdx_flag = '0, eg_s1_io_state_bits_robIdx_flag = '0;
  wire  [7:0] eg_g_io_state_bits_robIdx_value, eg_i_io_state_bits_robIdx_value;
  logic [7:0] eg_s0_io_state_bits_robIdx_value = '0, eg_s1_io_state_bits_robIdx_value = '0;
  wire  [5:0] eg_g_io_state_bits_ftqPtr_value, eg_i_io_state_bits_ftqPtr_value;
  logic [5:0] eg_s0_io_state_bits_ftqPtr_value = '0, eg_s1_io_state_bits_ftqPtr_value = '0;
  wire  [3:0] eg_g_io_state_bits_ftqOffset, eg_i_io_state_bits_ftqOffset;
  logic [3:0] eg_s0_io_state_bits_ftqOffset = '0, eg_s1_io_state_bits_ftqOffset = '0;
  wire  eg_g_io_state_bits_hasException, eg_i_io_state_bits_hasException;
  logic eg_s0_io_state_bits_hasException = '0, eg_s1_io_state_bits_hasException = '0;
  wire  eg_g_io_state_bits_isEnqExcp, eg_i_io_state_bits_isEnqExcp;
  logic eg_s0_io_state_bits_isEnqExcp = '0, eg_s1_io_state_bits_isEnqExcp = '0;
  wire  eg_g_io_state_bits_exceptionVec_0, eg_i_io_state_bits_exceptionVec_0;
  logic eg_s0_io_state_bits_exceptionVec_0 = '0, eg_s1_io_state_bits_exceptionVec_0 = '0;
  wire  eg_g_io_state_bits_exceptionVec_1, eg_i_io_state_bits_exceptionVec_1;
  logic eg_s0_io_state_bits_exceptionVec_1 = '0, eg_s1_io_state_bits_exceptionVec_1 = '0;
  wire  eg_g_io_state_bits_exceptionVec_2, eg_i_io_state_bits_exceptionVec_2;
  logic eg_s0_io_state_bits_exceptionVec_2 = '0, eg_s1_io_state_bits_exceptionVec_2 = '0;
  wire  eg_g_io_state_bits_exceptionVec_3, eg_i_io_state_bits_exceptionVec_3;
  logic eg_s0_io_state_bits_exceptionVec_3 = '0, eg_s1_io_state_bits_exceptionVec_3 = '0;
  wire  eg_g_io_state_bits_exceptionVec_4, eg_i_io_state_bits_exceptionVec_4;
  logic eg_s0_io_state_bits_exceptionVec_4 = '0, eg_s1_io_state_bits_exceptionVec_4 = '0;
  wire  eg_g_io_state_bits_exceptionVec_5, eg_i_io_state_bits_exceptionVec_5;
  logic eg_s0_io_state_bits_exceptionVec_5 = '0, eg_s1_io_state_bits_exceptionVec_5 = '0;
  wire  eg_g_io_state_bits_exceptionVec_6, eg_i_io_state_bits_exceptionVec_6;
  logic eg_s0_io_state_bits_exceptionVec_6 = '0, eg_s1_io_state_bits_exceptionVec_6 = '0;
  wire  eg_g_io_state_bits_exceptionVec_7, eg_i_io_state_bits_exceptionVec_7;
  logic eg_s0_io_state_bits_exceptionVec_7 = '0, eg_s1_io_state_bits_exceptionVec_7 = '0;
  wire  eg_g_io_state_bits_exceptionVec_8, eg_i_io_state_bits_exceptionVec_8;
  logic eg_s0_io_state_bits_exceptionVec_8 = '0, eg_s1_io_state_bits_exceptionVec_8 = '0;
  wire  eg_g_io_state_bits_exceptionVec_9, eg_i_io_state_bits_exceptionVec_9;
  logic eg_s0_io_state_bits_exceptionVec_9 = '0, eg_s1_io_state_bits_exceptionVec_9 = '0;
  wire  eg_g_io_state_bits_exceptionVec_10, eg_i_io_state_bits_exceptionVec_10;
  logic eg_s0_io_state_bits_exceptionVec_10 = '0, eg_s1_io_state_bits_exceptionVec_10 = '0;
  wire  eg_g_io_state_bits_exceptionVec_11, eg_i_io_state_bits_exceptionVec_11;
  logic eg_s0_io_state_bits_exceptionVec_11 = '0, eg_s1_io_state_bits_exceptionVec_11 = '0;
  wire  eg_g_io_state_bits_exceptionVec_12, eg_i_io_state_bits_exceptionVec_12;
  logic eg_s0_io_state_bits_exceptionVec_12 = '0, eg_s1_io_state_bits_exceptionVec_12 = '0;
  wire  eg_g_io_state_bits_exceptionVec_13, eg_i_io_state_bits_exceptionVec_13;
  logic eg_s0_io_state_bits_exceptionVec_13 = '0, eg_s1_io_state_bits_exceptionVec_13 = '0;
  wire  eg_g_io_state_bits_exceptionVec_14, eg_i_io_state_bits_exceptionVec_14;
  logic eg_s0_io_state_bits_exceptionVec_14 = '0, eg_s1_io_state_bits_exceptionVec_14 = '0;
  wire  eg_g_io_state_bits_exceptionVec_15, eg_i_io_state_bits_exceptionVec_15;
  logic eg_s0_io_state_bits_exceptionVec_15 = '0, eg_s1_io_state_bits_exceptionVec_15 = '0;
  wire  eg_g_io_state_bits_exceptionVec_16, eg_i_io_state_bits_exceptionVec_16;
  logic eg_s0_io_state_bits_exceptionVec_16 = '0, eg_s1_io_state_bits_exceptionVec_16 = '0;
  wire  eg_g_io_state_bits_exceptionVec_17, eg_i_io_state_bits_exceptionVec_17;
  logic eg_s0_io_state_bits_exceptionVec_17 = '0, eg_s1_io_state_bits_exceptionVec_17 = '0;
  wire  eg_g_io_state_bits_exceptionVec_18, eg_i_io_state_bits_exceptionVec_18;
  logic eg_s0_io_state_bits_exceptionVec_18 = '0, eg_s1_io_state_bits_exceptionVec_18 = '0;
  wire  eg_g_io_state_bits_exceptionVec_19, eg_i_io_state_bits_exceptionVec_19;
  logic eg_s0_io_state_bits_exceptionVec_19 = '0, eg_s1_io_state_bits_exceptionVec_19 = '0;
  wire  eg_g_io_state_bits_exceptionVec_20, eg_i_io_state_bits_exceptionVec_20;
  logic eg_s0_io_state_bits_exceptionVec_20 = '0, eg_s1_io_state_bits_exceptionVec_20 = '0;
  wire  eg_g_io_state_bits_exceptionVec_21, eg_i_io_state_bits_exceptionVec_21;
  logic eg_s0_io_state_bits_exceptionVec_21 = '0, eg_s1_io_state_bits_exceptionVec_21 = '0;
  wire  eg_g_io_state_bits_exceptionVec_22, eg_i_io_state_bits_exceptionVec_22;
  logic eg_s0_io_state_bits_exceptionVec_22 = '0, eg_s1_io_state_bits_exceptionVec_22 = '0;
  wire  eg_g_io_state_bits_exceptionVec_23, eg_i_io_state_bits_exceptionVec_23;
  logic eg_s0_io_state_bits_exceptionVec_23 = '0, eg_s1_io_state_bits_exceptionVec_23 = '0;
  wire  eg_g_io_state_bits_isFetchMalAddr, eg_i_io_state_bits_isFetchMalAddr;
  logic eg_s0_io_state_bits_isFetchMalAddr = '0, eg_s1_io_state_bits_isFetchMalAddr = '0;
  wire  eg_g_io_state_bits_satpFlushFirstFetchFault, eg_i_io_state_bits_satpFlushFirstFetchFault;
  logic eg_s0_io_state_bits_satpFlushFirstFetchFault = '0, eg_s1_io_state_bits_satpFlushFirstFetchFault = '0;
  wire  eg_g_io_state_bits_flushPipe, eg_i_io_state_bits_flushPipe;
  logic eg_s0_io_state_bits_flushPipe = '0, eg_s1_io_state_bits_flushPipe = '0;
  wire  eg_g_io_state_bits_satpFlushPipe, eg_i_io_state_bits_satpFlushPipe;
  logic eg_s0_io_state_bits_satpFlushPipe = '0, eg_s1_io_state_bits_satpFlushPipe = '0;
  wire  eg_g_io_state_bits_isVset, eg_i_io_state_bits_isVset;
  logic eg_s0_io_state_bits_isVset = '0, eg_s1_io_state_bits_isVset = '0;
  wire  eg_g_io_state_bits_replayInst, eg_i_io_state_bits_replayInst;
  logic eg_s0_io_state_bits_replayInst = '0, eg_s1_io_state_bits_replayInst = '0;
  wire  eg_g_io_state_bits_singleStep, eg_i_io_state_bits_singleStep;
  logic eg_s0_io_state_bits_singleStep = '0, eg_s1_io_state_bits_singleStep = '0;
  wire  eg_g_io_state_bits_crossPageIPFFix, eg_i_io_state_bits_crossPageIPFFix;
  logic eg_s0_io_state_bits_crossPageIPFFix = '0, eg_s1_io_state_bits_crossPageIPFFix = '0;
  wire  [3:0] eg_g_io_state_bits_trigger, eg_i_io_state_bits_trigger;
  logic [3:0] eg_s0_io_state_bits_trigger = '0, eg_s1_io_state_bits_trigger = '0;
  wire  eg_g_io_state_bits_vstartEn, eg_i_io_state_bits_vstartEn;
  logic eg_s0_io_state_bits_vstartEn = '0, eg_s1_io_state_bits_vstartEn = '0;
  wire  [63:0] eg_g_io_state_bits_vstart, eg_i_io_state_bits_vstart;
  logic [63:0] eg_s0_io_state_bits_vstart = '0, eg_s1_io_state_bits_vstart = '0;
  wire  eg_g_io_state_bits_isVecLoad, eg_i_io_state_bits_isVecLoad;
  logic eg_s0_io_state_bits_isVecLoad = '0, eg_s1_io_state_bits_isVecLoad = '0;
  wire  eg_g_io_state_bits_isVlm, eg_i_io_state_bits_isVlm;
  logic eg_s0_io_state_bits_isVlm = '0, eg_s1_io_state_bits_isVlm = '0;
  wire  eg_g_io_state_bits_isStrided, eg_i_io_state_bits_isStrided;
  logic eg_s0_io_state_bits_isStrided = '0, eg_s1_io_state_bits_isStrided = '0;
  wire  eg_g_io_state_bits_isIndexed, eg_i_io_state_bits_isIndexed;
  logic eg_s0_io_state_bits_isIndexed = '0, eg_s1_io_state_bits_isIndexed = '0;
  wire  eg_g_io_state_bits_isWhole, eg_i_io_state_bits_isWhole;
  logic eg_s0_io_state_bits_isWhole = '0, eg_s1_io_state_bits_isWhole = '0;
  wire  [2:0] eg_g_io_state_bits_nf, eg_i_io_state_bits_nf;
  logic [2:0] eg_s0_io_state_bits_nf = '0, eg_s1_io_state_bits_nf = '0;
  wire  [1:0] eg_g_io_state_bits_vsew, eg_i_io_state_bits_vsew;
  logic [1:0] eg_s0_io_state_bits_vsew = '0, eg_s1_io_state_bits_vsew = '0;
  wire  [1:0] eg_g_io_state_bits_veew, eg_i_io_state_bits_veew;
  logic [1:0] eg_s0_io_state_bits_veew = '0, eg_s1_io_state_bits_veew = '0;
  wire  [2:0] eg_g_io_state_bits_vlmul, eg_i_io_state_bits_vlmul;
  logic [2:0] eg_s0_io_state_bits_vlmul = '0, eg_s1_io_state_bits_vlmul = '0;
  int eg_cov_s1_older_replace = 0;
  int eg_cov_s1_same_merge = 0;
  int eg_cov_enq_into_empty = 0;
  int eg_cov_current_flushed = 0;
  logic [0:0] eg_armed = '0;
  int eg_armed_at = -1;
  ExceptionGen eg_u_gold (
    .clock(clk),
    .reset(eg_reset),
    .io_redirect_valid(eg_io_redirect_valid),
    .io_redirect_bits_robIdx_flag(eg_io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value(eg_io_redirect_bits_robIdx_value),
    .io_redirect_bits_level(eg_io_redirect_bits_level),
    .io_flush(eg_io_flush),
    .io_enq_0_valid(eg_io_enq_0_valid),
    .io_enq_0_bits_robIdx_flag(eg_io_enq_0_bits_robIdx_flag),
    .io_enq_0_bits_robIdx_value(eg_io_enq_0_bits_robIdx_value),
    .io_enq_0_bits_ftqPtr_value(eg_io_enq_0_bits_ftqPtr_value),
    .io_enq_0_bits_ftqOffset(eg_io_enq_0_bits_ftqOffset),
    .io_enq_0_bits_hasException(eg_io_enq_0_bits_hasException),
    .io_enq_0_bits_exceptionVec_0(eg_io_enq_0_bits_exceptionVec_0),
    .io_enq_0_bits_exceptionVec_1(eg_io_enq_0_bits_exceptionVec_1),
    .io_enq_0_bits_exceptionVec_2(eg_io_enq_0_bits_exceptionVec_2),
    .io_enq_0_bits_exceptionVec_3(eg_io_enq_0_bits_exceptionVec_3),
    .io_enq_0_bits_exceptionVec_12(eg_io_enq_0_bits_exceptionVec_12),
    .io_enq_0_bits_exceptionVec_20(eg_io_enq_0_bits_exceptionVec_20),
    .io_enq_0_bits_exceptionVec_22(eg_io_enq_0_bits_exceptionVec_22),
    .io_enq_0_bits_isFetchMalAddr(eg_io_enq_0_bits_isFetchMalAddr),
    .io_enq_0_bits_satpFlushFirstFetchFault(eg_io_enq_0_bits_satpFlushFirstFetchFault),
    .io_enq_0_bits_flushPipe(eg_io_enq_0_bits_flushPipe),
    .io_enq_0_bits_isVset(eg_io_enq_0_bits_isVset),
    .io_enq_0_bits_singleStep(eg_io_enq_0_bits_singleStep),
    .io_enq_0_bits_crossPageIPFFix(eg_io_enq_0_bits_crossPageIPFFix),
    .io_enq_0_bits_trigger(eg_io_enq_0_bits_trigger),
    .io_enq_1_valid(eg_io_enq_1_valid),
    .io_enq_1_bits_robIdx_flag(eg_io_enq_1_bits_robIdx_flag),
    .io_enq_1_bits_robIdx_value(eg_io_enq_1_bits_robIdx_value),
    .io_enq_1_bits_ftqPtr_value(eg_io_enq_1_bits_ftqPtr_value),
    .io_enq_1_bits_ftqOffset(eg_io_enq_1_bits_ftqOffset),
    .io_enq_1_bits_hasException(eg_io_enq_1_bits_hasException),
    .io_enq_1_bits_exceptionVec_0(eg_io_enq_1_bits_exceptionVec_0),
    .io_enq_1_bits_exceptionVec_1(eg_io_enq_1_bits_exceptionVec_1),
    .io_enq_1_bits_exceptionVec_2(eg_io_enq_1_bits_exceptionVec_2),
    .io_enq_1_bits_exceptionVec_3(eg_io_enq_1_bits_exceptionVec_3),
    .io_enq_1_bits_exceptionVec_12(eg_io_enq_1_bits_exceptionVec_12),
    .io_enq_1_bits_exceptionVec_20(eg_io_enq_1_bits_exceptionVec_20),
    .io_enq_1_bits_exceptionVec_22(eg_io_enq_1_bits_exceptionVec_22),
    .io_enq_1_bits_isFetchMalAddr(eg_io_enq_1_bits_isFetchMalAddr),
    .io_enq_1_bits_satpFlushFirstFetchFault(eg_io_enq_1_bits_satpFlushFirstFetchFault),
    .io_enq_1_bits_flushPipe(eg_io_enq_1_bits_flushPipe),
    .io_enq_1_bits_isVset(eg_io_enq_1_bits_isVset),
    .io_enq_1_bits_singleStep(eg_io_enq_1_bits_singleStep),
    .io_enq_1_bits_crossPageIPFFix(eg_io_enq_1_bits_crossPageIPFFix),
    .io_enq_1_bits_trigger(eg_io_enq_1_bits_trigger),
    .io_enq_2_valid(eg_io_enq_2_valid),
    .io_enq_2_bits_robIdx_flag(eg_io_enq_2_bits_robIdx_flag),
    .io_enq_2_bits_robIdx_value(eg_io_enq_2_bits_robIdx_value),
    .io_enq_2_bits_ftqPtr_value(eg_io_enq_2_bits_ftqPtr_value),
    .io_enq_2_bits_ftqOffset(eg_io_enq_2_bits_ftqOffset),
    .io_enq_2_bits_hasException(eg_io_enq_2_bits_hasException),
    .io_enq_2_bits_exceptionVec_0(eg_io_enq_2_bits_exceptionVec_0),
    .io_enq_2_bits_exceptionVec_1(eg_io_enq_2_bits_exceptionVec_1),
    .io_enq_2_bits_exceptionVec_2(eg_io_enq_2_bits_exceptionVec_2),
    .io_enq_2_bits_exceptionVec_3(eg_io_enq_2_bits_exceptionVec_3),
    .io_enq_2_bits_exceptionVec_12(eg_io_enq_2_bits_exceptionVec_12),
    .io_enq_2_bits_exceptionVec_20(eg_io_enq_2_bits_exceptionVec_20),
    .io_enq_2_bits_exceptionVec_22(eg_io_enq_2_bits_exceptionVec_22),
    .io_enq_2_bits_isFetchMalAddr(eg_io_enq_2_bits_isFetchMalAddr),
    .io_enq_2_bits_satpFlushFirstFetchFault(eg_io_enq_2_bits_satpFlushFirstFetchFault),
    .io_enq_2_bits_flushPipe(eg_io_enq_2_bits_flushPipe),
    .io_enq_2_bits_isVset(eg_io_enq_2_bits_isVset),
    .io_enq_2_bits_singleStep(eg_io_enq_2_bits_singleStep),
    .io_enq_2_bits_crossPageIPFFix(eg_io_enq_2_bits_crossPageIPFFix),
    .io_enq_2_bits_trigger(eg_io_enq_2_bits_trigger),
    .io_enq_3_valid(eg_io_enq_3_valid),
    .io_enq_3_bits_robIdx_flag(eg_io_enq_3_bits_robIdx_flag),
    .io_enq_3_bits_robIdx_value(eg_io_enq_3_bits_robIdx_value),
    .io_enq_3_bits_ftqPtr_value(eg_io_enq_3_bits_ftqPtr_value),
    .io_enq_3_bits_ftqOffset(eg_io_enq_3_bits_ftqOffset),
    .io_enq_3_bits_hasException(eg_io_enq_3_bits_hasException),
    .io_enq_3_bits_exceptionVec_0(eg_io_enq_3_bits_exceptionVec_0),
    .io_enq_3_bits_exceptionVec_1(eg_io_enq_3_bits_exceptionVec_1),
    .io_enq_3_bits_exceptionVec_2(eg_io_enq_3_bits_exceptionVec_2),
    .io_enq_3_bits_exceptionVec_3(eg_io_enq_3_bits_exceptionVec_3),
    .io_enq_3_bits_exceptionVec_12(eg_io_enq_3_bits_exceptionVec_12),
    .io_enq_3_bits_exceptionVec_20(eg_io_enq_3_bits_exceptionVec_20),
    .io_enq_3_bits_exceptionVec_22(eg_io_enq_3_bits_exceptionVec_22),
    .io_enq_3_bits_isFetchMalAddr(eg_io_enq_3_bits_isFetchMalAddr),
    .io_enq_3_bits_satpFlushFirstFetchFault(eg_io_enq_3_bits_satpFlushFirstFetchFault),
    .io_enq_3_bits_flushPipe(eg_io_enq_3_bits_flushPipe),
    .io_enq_3_bits_isVset(eg_io_enq_3_bits_isVset),
    .io_enq_3_bits_singleStep(eg_io_enq_3_bits_singleStep),
    .io_enq_3_bits_crossPageIPFFix(eg_io_enq_3_bits_crossPageIPFFix),
    .io_enq_3_bits_trigger(eg_io_enq_3_bits_trigger),
    .io_enq_4_valid(eg_io_enq_4_valid),
    .io_enq_4_bits_robIdx_flag(eg_io_enq_4_bits_robIdx_flag),
    .io_enq_4_bits_robIdx_value(eg_io_enq_4_bits_robIdx_value),
    .io_enq_4_bits_ftqPtr_value(eg_io_enq_4_bits_ftqPtr_value),
    .io_enq_4_bits_ftqOffset(eg_io_enq_4_bits_ftqOffset),
    .io_enq_4_bits_hasException(eg_io_enq_4_bits_hasException),
    .io_enq_4_bits_exceptionVec_0(eg_io_enq_4_bits_exceptionVec_0),
    .io_enq_4_bits_exceptionVec_1(eg_io_enq_4_bits_exceptionVec_1),
    .io_enq_4_bits_exceptionVec_2(eg_io_enq_4_bits_exceptionVec_2),
    .io_enq_4_bits_exceptionVec_3(eg_io_enq_4_bits_exceptionVec_3),
    .io_enq_4_bits_exceptionVec_12(eg_io_enq_4_bits_exceptionVec_12),
    .io_enq_4_bits_exceptionVec_20(eg_io_enq_4_bits_exceptionVec_20),
    .io_enq_4_bits_exceptionVec_22(eg_io_enq_4_bits_exceptionVec_22),
    .io_enq_4_bits_isFetchMalAddr(eg_io_enq_4_bits_isFetchMalAddr),
    .io_enq_4_bits_satpFlushFirstFetchFault(eg_io_enq_4_bits_satpFlushFirstFetchFault),
    .io_enq_4_bits_flushPipe(eg_io_enq_4_bits_flushPipe),
    .io_enq_4_bits_isVset(eg_io_enq_4_bits_isVset),
    .io_enq_4_bits_singleStep(eg_io_enq_4_bits_singleStep),
    .io_enq_4_bits_crossPageIPFFix(eg_io_enq_4_bits_crossPageIPFFix),
    .io_enq_4_bits_trigger(eg_io_enq_4_bits_trigger),
    .io_enq_5_valid(eg_io_enq_5_valid),
    .io_enq_5_bits_robIdx_flag(eg_io_enq_5_bits_robIdx_flag),
    .io_enq_5_bits_robIdx_value(eg_io_enq_5_bits_robIdx_value),
    .io_enq_5_bits_ftqPtr_value(eg_io_enq_5_bits_ftqPtr_value),
    .io_enq_5_bits_ftqOffset(eg_io_enq_5_bits_ftqOffset),
    .io_enq_5_bits_hasException(eg_io_enq_5_bits_hasException),
    .io_enq_5_bits_exceptionVec_0(eg_io_enq_5_bits_exceptionVec_0),
    .io_enq_5_bits_exceptionVec_1(eg_io_enq_5_bits_exceptionVec_1),
    .io_enq_5_bits_exceptionVec_2(eg_io_enq_5_bits_exceptionVec_2),
    .io_enq_5_bits_exceptionVec_3(eg_io_enq_5_bits_exceptionVec_3),
    .io_enq_5_bits_exceptionVec_12(eg_io_enq_5_bits_exceptionVec_12),
    .io_enq_5_bits_exceptionVec_20(eg_io_enq_5_bits_exceptionVec_20),
    .io_enq_5_bits_exceptionVec_22(eg_io_enq_5_bits_exceptionVec_22),
    .io_enq_5_bits_isFetchMalAddr(eg_io_enq_5_bits_isFetchMalAddr),
    .io_enq_5_bits_satpFlushFirstFetchFault(eg_io_enq_5_bits_satpFlushFirstFetchFault),
    .io_enq_5_bits_flushPipe(eg_io_enq_5_bits_flushPipe),
    .io_enq_5_bits_isVset(eg_io_enq_5_bits_isVset),
    .io_enq_5_bits_singleStep(eg_io_enq_5_bits_singleStep),
    .io_enq_5_bits_crossPageIPFFix(eg_io_enq_5_bits_crossPageIPFFix),
    .io_enq_5_bits_trigger(eg_io_enq_5_bits_trigger),
    .io_wb_0_valid(eg_io_wb_0_valid),
    .io_wb_0_bits_robIdx_flag(eg_io_wb_0_bits_robIdx_flag),
    .io_wb_0_bits_robIdx_value(eg_io_wb_0_bits_robIdx_value),
    .io_wb_0_bits_hasException(eg_io_wb_0_bits_hasException),
    .io_wb_0_bits_exceptionVec_2(eg_io_wb_0_bits_exceptionVec_2),
    .io_wb_0_bits_exceptionVec_3(eg_io_wb_0_bits_exceptionVec_3),
    .io_wb_0_bits_exceptionVec_8(eg_io_wb_0_bits_exceptionVec_8),
    .io_wb_0_bits_exceptionVec_9(eg_io_wb_0_bits_exceptionVec_9),
    .io_wb_0_bits_exceptionVec_10(eg_io_wb_0_bits_exceptionVec_10),
    .io_wb_0_bits_exceptionVec_11(eg_io_wb_0_bits_exceptionVec_11),
    .io_wb_0_bits_exceptionVec_22(eg_io_wb_0_bits_exceptionVec_22),
    .io_wb_0_bits_flushPipe(eg_io_wb_0_bits_flushPipe),
    .io_wb_0_bits_satpFlushPipe(eg_io_wb_0_bits_satpFlushPipe),
    .io_wb_1_valid(eg_io_wb_1_valid),
    .io_wb_1_bits_robIdx_flag(eg_io_wb_1_bits_robIdx_flag),
    .io_wb_1_bits_robIdx_value(eg_io_wb_1_bits_robIdx_value),
    .io_wb_1_bits_hasException(eg_io_wb_1_bits_hasException),
    .io_wb_1_bits_exceptionVec_2(eg_io_wb_1_bits_exceptionVec_2),
    .io_wb_2_valid(eg_io_wb_2_valid),
    .io_wb_2_bits_robIdx_flag(eg_io_wb_2_bits_robIdx_flag),
    .io_wb_2_bits_robIdx_value(eg_io_wb_2_bits_robIdx_value),
    .io_wb_2_bits_hasException(eg_io_wb_2_bits_hasException),
    .io_wb_2_bits_exceptionVec_2(eg_io_wb_2_bits_exceptionVec_2),
    .io_wb_3_bits_robIdx_flag(eg_io_wb_3_bits_robIdx_flag),
    .io_wb_3_bits_robIdx_value(eg_io_wb_3_bits_robIdx_value),
    .io_wb_4_bits_robIdx_flag(eg_io_wb_4_bits_robIdx_flag),
    .io_wb_4_bits_robIdx_value(eg_io_wb_4_bits_robIdx_value),
    .io_wb_5_bits_robIdx_flag(eg_io_wb_5_bits_robIdx_flag),
    .io_wb_5_bits_robIdx_value(eg_io_wb_5_bits_robIdx_value),
    .io_wb_6_valid(eg_io_wb_6_valid),
    .io_wb_6_bits_robIdx_flag(eg_io_wb_6_bits_robIdx_flag),
    .io_wb_6_bits_robIdx_value(eg_io_wb_6_bits_robIdx_value),
    .io_wb_6_bits_hasException(eg_io_wb_6_bits_hasException),
    .io_wb_6_bits_exceptionVec_0(eg_io_wb_6_bits_exceptionVec_0),
    .io_wb_6_bits_exceptionVec_1(eg_io_wb_6_bits_exceptionVec_1),
    .io_wb_6_bits_exceptionVec_2(eg_io_wb_6_bits_exceptionVec_2),
    .io_wb_6_bits_exceptionVec_3(eg_io_wb_6_bits_exceptionVec_3),
    .io_wb_6_bits_exceptionVec_4(eg_io_wb_6_bits_exceptionVec_4),
    .io_wb_6_bits_exceptionVec_5(eg_io_wb_6_bits_exceptionVec_5),
    .io_wb_6_bits_exceptionVec_6(eg_io_wb_6_bits_exceptionVec_6),
    .io_wb_6_bits_exceptionVec_7(eg_io_wb_6_bits_exceptionVec_7),
    .io_wb_6_bits_exceptionVec_8(eg_io_wb_6_bits_exceptionVec_8),
    .io_wb_6_bits_exceptionVec_9(eg_io_wb_6_bits_exceptionVec_9),
    .io_wb_6_bits_exceptionVec_10(eg_io_wb_6_bits_exceptionVec_10),
    .io_wb_6_bits_exceptionVec_11(eg_io_wb_6_bits_exceptionVec_11),
    .io_wb_6_bits_exceptionVec_12(eg_io_wb_6_bits_exceptionVec_12),
    .io_wb_6_bits_exceptionVec_13(eg_io_wb_6_bits_exceptionVec_13),
    .io_wb_6_bits_exceptionVec_14(eg_io_wb_6_bits_exceptionVec_14),
    .io_wb_6_bits_exceptionVec_15(eg_io_wb_6_bits_exceptionVec_15),
    .io_wb_6_bits_exceptionVec_16(eg_io_wb_6_bits_exceptionVec_16),
    .io_wb_6_bits_exceptionVec_17(eg_io_wb_6_bits_exceptionVec_17),
    .io_wb_6_bits_exceptionVec_18(eg_io_wb_6_bits_exceptionVec_18),
    .io_wb_6_bits_exceptionVec_19(eg_io_wb_6_bits_exceptionVec_19),
    .io_wb_6_bits_exceptionVec_20(eg_io_wb_6_bits_exceptionVec_20),
    .io_wb_6_bits_exceptionVec_21(eg_io_wb_6_bits_exceptionVec_21),
    .io_wb_6_bits_exceptionVec_22(eg_io_wb_6_bits_exceptionVec_22),
    .io_wb_6_bits_exceptionVec_23(eg_io_wb_6_bits_exceptionVec_23),
    .io_wb_6_bits_flushPipe(eg_io_wb_6_bits_flushPipe),
    .io_wb_6_bits_trigger(eg_io_wb_6_bits_trigger),
    .io_wb_7_valid(eg_io_wb_7_valid),
    .io_wb_7_bits_robIdx_flag(eg_io_wb_7_bits_robIdx_flag),
    .io_wb_7_bits_robIdx_value(eg_io_wb_7_bits_robIdx_value),
    .io_wb_7_bits_hasException(eg_io_wb_7_bits_hasException),
    .io_wb_7_bits_exceptionVec_0(eg_io_wb_7_bits_exceptionVec_0),
    .io_wb_7_bits_exceptionVec_1(eg_io_wb_7_bits_exceptionVec_1),
    .io_wb_7_bits_exceptionVec_2(eg_io_wb_7_bits_exceptionVec_2),
    .io_wb_7_bits_exceptionVec_3(eg_io_wb_7_bits_exceptionVec_3),
    .io_wb_7_bits_exceptionVec_4(eg_io_wb_7_bits_exceptionVec_4),
    .io_wb_7_bits_exceptionVec_5(eg_io_wb_7_bits_exceptionVec_5),
    .io_wb_7_bits_exceptionVec_6(eg_io_wb_7_bits_exceptionVec_6),
    .io_wb_7_bits_exceptionVec_7(eg_io_wb_7_bits_exceptionVec_7),
    .io_wb_7_bits_exceptionVec_8(eg_io_wb_7_bits_exceptionVec_8),
    .io_wb_7_bits_exceptionVec_9(eg_io_wb_7_bits_exceptionVec_9),
    .io_wb_7_bits_exceptionVec_10(eg_io_wb_7_bits_exceptionVec_10),
    .io_wb_7_bits_exceptionVec_11(eg_io_wb_7_bits_exceptionVec_11),
    .io_wb_7_bits_exceptionVec_12(eg_io_wb_7_bits_exceptionVec_12),
    .io_wb_7_bits_exceptionVec_13(eg_io_wb_7_bits_exceptionVec_13),
    .io_wb_7_bits_exceptionVec_14(eg_io_wb_7_bits_exceptionVec_14),
    .io_wb_7_bits_exceptionVec_15(eg_io_wb_7_bits_exceptionVec_15),
    .io_wb_7_bits_exceptionVec_16(eg_io_wb_7_bits_exceptionVec_16),
    .io_wb_7_bits_exceptionVec_17(eg_io_wb_7_bits_exceptionVec_17),
    .io_wb_7_bits_exceptionVec_18(eg_io_wb_7_bits_exceptionVec_18),
    .io_wb_7_bits_exceptionVec_19(eg_io_wb_7_bits_exceptionVec_19),
    .io_wb_7_bits_exceptionVec_20(eg_io_wb_7_bits_exceptionVec_20),
    .io_wb_7_bits_exceptionVec_21(eg_io_wb_7_bits_exceptionVec_21),
    .io_wb_7_bits_exceptionVec_22(eg_io_wb_7_bits_exceptionVec_22),
    .io_wb_7_bits_exceptionVec_23(eg_io_wb_7_bits_exceptionVec_23),
    .io_wb_7_bits_flushPipe(eg_io_wb_7_bits_flushPipe),
    .io_wb_7_bits_trigger(eg_io_wb_7_bits_trigger),
    .io_wb_8_valid(eg_io_wb_8_valid),
    .io_wb_8_bits_robIdx_flag(eg_io_wb_8_bits_robIdx_flag),
    .io_wb_8_bits_robIdx_value(eg_io_wb_8_bits_robIdx_value),
    .io_wb_8_bits_hasException(eg_io_wb_8_bits_hasException),
    .io_wb_8_bits_exceptionVec_0(eg_io_wb_8_bits_exceptionVec_0),
    .io_wb_8_bits_exceptionVec_1(eg_io_wb_8_bits_exceptionVec_1),
    .io_wb_8_bits_exceptionVec_2(eg_io_wb_8_bits_exceptionVec_2),
    .io_wb_8_bits_exceptionVec_3(eg_io_wb_8_bits_exceptionVec_3),
    .io_wb_8_bits_exceptionVec_4(eg_io_wb_8_bits_exceptionVec_4),
    .io_wb_8_bits_exceptionVec_5(eg_io_wb_8_bits_exceptionVec_5),
    .io_wb_8_bits_exceptionVec_6(eg_io_wb_8_bits_exceptionVec_6),
    .io_wb_8_bits_exceptionVec_7(eg_io_wb_8_bits_exceptionVec_7),
    .io_wb_8_bits_exceptionVec_8(eg_io_wb_8_bits_exceptionVec_8),
    .io_wb_8_bits_exceptionVec_9(eg_io_wb_8_bits_exceptionVec_9),
    .io_wb_8_bits_exceptionVec_10(eg_io_wb_8_bits_exceptionVec_10),
    .io_wb_8_bits_exceptionVec_11(eg_io_wb_8_bits_exceptionVec_11),
    .io_wb_8_bits_exceptionVec_12(eg_io_wb_8_bits_exceptionVec_12),
    .io_wb_8_bits_exceptionVec_13(eg_io_wb_8_bits_exceptionVec_13),
    .io_wb_8_bits_exceptionVec_14(eg_io_wb_8_bits_exceptionVec_14),
    .io_wb_8_bits_exceptionVec_15(eg_io_wb_8_bits_exceptionVec_15),
    .io_wb_8_bits_exceptionVec_16(eg_io_wb_8_bits_exceptionVec_16),
    .io_wb_8_bits_exceptionVec_17(eg_io_wb_8_bits_exceptionVec_17),
    .io_wb_8_bits_exceptionVec_18(eg_io_wb_8_bits_exceptionVec_18),
    .io_wb_8_bits_exceptionVec_19(eg_io_wb_8_bits_exceptionVec_19),
    .io_wb_8_bits_exceptionVec_20(eg_io_wb_8_bits_exceptionVec_20),
    .io_wb_8_bits_exceptionVec_21(eg_io_wb_8_bits_exceptionVec_21),
    .io_wb_8_bits_exceptionVec_22(eg_io_wb_8_bits_exceptionVec_22),
    .io_wb_8_bits_exceptionVec_23(eg_io_wb_8_bits_exceptionVec_23),
    .io_wb_8_bits_flushPipe(eg_io_wb_8_bits_flushPipe),
    .io_wb_8_bits_replayInst(eg_io_wb_8_bits_replayInst),
    .io_wb_8_bits_trigger(eg_io_wb_8_bits_trigger),
    .io_wb_9_valid(eg_io_wb_9_valid),
    .io_wb_9_bits_robIdx_flag(eg_io_wb_9_bits_robIdx_flag),
    .io_wb_9_bits_robIdx_value(eg_io_wb_9_bits_robIdx_value),
    .io_wb_9_bits_hasException(eg_io_wb_9_bits_hasException),
    .io_wb_9_bits_exceptionVec_0(eg_io_wb_9_bits_exceptionVec_0),
    .io_wb_9_bits_exceptionVec_1(eg_io_wb_9_bits_exceptionVec_1),
    .io_wb_9_bits_exceptionVec_2(eg_io_wb_9_bits_exceptionVec_2),
    .io_wb_9_bits_exceptionVec_3(eg_io_wb_9_bits_exceptionVec_3),
    .io_wb_9_bits_exceptionVec_4(eg_io_wb_9_bits_exceptionVec_4),
    .io_wb_9_bits_exceptionVec_5(eg_io_wb_9_bits_exceptionVec_5),
    .io_wb_9_bits_exceptionVec_6(eg_io_wb_9_bits_exceptionVec_6),
    .io_wb_9_bits_exceptionVec_7(eg_io_wb_9_bits_exceptionVec_7),
    .io_wb_9_bits_exceptionVec_8(eg_io_wb_9_bits_exceptionVec_8),
    .io_wb_9_bits_exceptionVec_9(eg_io_wb_9_bits_exceptionVec_9),
    .io_wb_9_bits_exceptionVec_10(eg_io_wb_9_bits_exceptionVec_10),
    .io_wb_9_bits_exceptionVec_11(eg_io_wb_9_bits_exceptionVec_11),
    .io_wb_9_bits_exceptionVec_12(eg_io_wb_9_bits_exceptionVec_12),
    .io_wb_9_bits_exceptionVec_13(eg_io_wb_9_bits_exceptionVec_13),
    .io_wb_9_bits_exceptionVec_14(eg_io_wb_9_bits_exceptionVec_14),
    .io_wb_9_bits_exceptionVec_15(eg_io_wb_9_bits_exceptionVec_15),
    .io_wb_9_bits_exceptionVec_16(eg_io_wb_9_bits_exceptionVec_16),
    .io_wb_9_bits_exceptionVec_17(eg_io_wb_9_bits_exceptionVec_17),
    .io_wb_9_bits_exceptionVec_18(eg_io_wb_9_bits_exceptionVec_18),
    .io_wb_9_bits_exceptionVec_19(eg_io_wb_9_bits_exceptionVec_19),
    .io_wb_9_bits_exceptionVec_20(eg_io_wb_9_bits_exceptionVec_20),
    .io_wb_9_bits_exceptionVec_21(eg_io_wb_9_bits_exceptionVec_21),
    .io_wb_9_bits_exceptionVec_22(eg_io_wb_9_bits_exceptionVec_22),
    .io_wb_9_bits_exceptionVec_23(eg_io_wb_9_bits_exceptionVec_23),
    .io_wb_9_bits_flushPipe(eg_io_wb_9_bits_flushPipe),
    .io_wb_9_bits_replayInst(eg_io_wb_9_bits_replayInst),
    .io_wb_9_bits_trigger(eg_io_wb_9_bits_trigger),
    .io_wb_10_valid(eg_io_wb_10_valid),
    .io_wb_10_bits_robIdx_flag(eg_io_wb_10_bits_robIdx_flag),
    .io_wb_10_bits_robIdx_value(eg_io_wb_10_bits_robIdx_value),
    .io_wb_10_bits_hasException(eg_io_wb_10_bits_hasException),
    .io_wb_10_bits_exceptionVec_0(eg_io_wb_10_bits_exceptionVec_0),
    .io_wb_10_bits_exceptionVec_1(eg_io_wb_10_bits_exceptionVec_1),
    .io_wb_10_bits_exceptionVec_2(eg_io_wb_10_bits_exceptionVec_2),
    .io_wb_10_bits_exceptionVec_3(eg_io_wb_10_bits_exceptionVec_3),
    .io_wb_10_bits_exceptionVec_4(eg_io_wb_10_bits_exceptionVec_4),
    .io_wb_10_bits_exceptionVec_5(eg_io_wb_10_bits_exceptionVec_5),
    .io_wb_10_bits_exceptionVec_6(eg_io_wb_10_bits_exceptionVec_6),
    .io_wb_10_bits_exceptionVec_7(eg_io_wb_10_bits_exceptionVec_7),
    .io_wb_10_bits_exceptionVec_8(eg_io_wb_10_bits_exceptionVec_8),
    .io_wb_10_bits_exceptionVec_9(eg_io_wb_10_bits_exceptionVec_9),
    .io_wb_10_bits_exceptionVec_10(eg_io_wb_10_bits_exceptionVec_10),
    .io_wb_10_bits_exceptionVec_11(eg_io_wb_10_bits_exceptionVec_11),
    .io_wb_10_bits_exceptionVec_12(eg_io_wb_10_bits_exceptionVec_12),
    .io_wb_10_bits_exceptionVec_13(eg_io_wb_10_bits_exceptionVec_13),
    .io_wb_10_bits_exceptionVec_14(eg_io_wb_10_bits_exceptionVec_14),
    .io_wb_10_bits_exceptionVec_15(eg_io_wb_10_bits_exceptionVec_15),
    .io_wb_10_bits_exceptionVec_16(eg_io_wb_10_bits_exceptionVec_16),
    .io_wb_10_bits_exceptionVec_17(eg_io_wb_10_bits_exceptionVec_17),
    .io_wb_10_bits_exceptionVec_18(eg_io_wb_10_bits_exceptionVec_18),
    .io_wb_10_bits_exceptionVec_19(eg_io_wb_10_bits_exceptionVec_19),
    .io_wb_10_bits_exceptionVec_20(eg_io_wb_10_bits_exceptionVec_20),
    .io_wb_10_bits_exceptionVec_21(eg_io_wb_10_bits_exceptionVec_21),
    .io_wb_10_bits_exceptionVec_22(eg_io_wb_10_bits_exceptionVec_22),
    .io_wb_10_bits_exceptionVec_23(eg_io_wb_10_bits_exceptionVec_23),
    .io_wb_10_bits_flushPipe(eg_io_wb_10_bits_flushPipe),
    .io_wb_10_bits_replayInst(eg_io_wb_10_bits_replayInst),
    .io_wb_10_bits_trigger(eg_io_wb_10_bits_trigger),
    .io_wb_11_valid(eg_io_wb_11_valid),
    .io_wb_11_bits_robIdx_flag(eg_io_wb_11_bits_robIdx_flag),
    .io_wb_11_bits_robIdx_value(eg_io_wb_11_bits_robIdx_value),
    .io_wb_11_bits_hasException(eg_io_wb_11_bits_hasException),
    .io_wb_11_bits_exceptionVec_0(eg_io_wb_11_bits_exceptionVec_0),
    .io_wb_11_bits_exceptionVec_1(eg_io_wb_11_bits_exceptionVec_1),
    .io_wb_11_bits_exceptionVec_2(eg_io_wb_11_bits_exceptionVec_2),
    .io_wb_11_bits_exceptionVec_3(eg_io_wb_11_bits_exceptionVec_3),
    .io_wb_11_bits_exceptionVec_4(eg_io_wb_11_bits_exceptionVec_4),
    .io_wb_11_bits_exceptionVec_5(eg_io_wb_11_bits_exceptionVec_5),
    .io_wb_11_bits_exceptionVec_6(eg_io_wb_11_bits_exceptionVec_6),
    .io_wb_11_bits_exceptionVec_7(eg_io_wb_11_bits_exceptionVec_7),
    .io_wb_11_bits_exceptionVec_8(eg_io_wb_11_bits_exceptionVec_8),
    .io_wb_11_bits_exceptionVec_9(eg_io_wb_11_bits_exceptionVec_9),
    .io_wb_11_bits_exceptionVec_10(eg_io_wb_11_bits_exceptionVec_10),
    .io_wb_11_bits_exceptionVec_11(eg_io_wb_11_bits_exceptionVec_11),
    .io_wb_11_bits_exceptionVec_12(eg_io_wb_11_bits_exceptionVec_12),
    .io_wb_11_bits_exceptionVec_13(eg_io_wb_11_bits_exceptionVec_13),
    .io_wb_11_bits_exceptionVec_14(eg_io_wb_11_bits_exceptionVec_14),
    .io_wb_11_bits_exceptionVec_15(eg_io_wb_11_bits_exceptionVec_15),
    .io_wb_11_bits_exceptionVec_16(eg_io_wb_11_bits_exceptionVec_16),
    .io_wb_11_bits_exceptionVec_17(eg_io_wb_11_bits_exceptionVec_17),
    .io_wb_11_bits_exceptionVec_18(eg_io_wb_11_bits_exceptionVec_18),
    .io_wb_11_bits_exceptionVec_19(eg_io_wb_11_bits_exceptionVec_19),
    .io_wb_11_bits_exceptionVec_20(eg_io_wb_11_bits_exceptionVec_20),
    .io_wb_11_bits_exceptionVec_21(eg_io_wb_11_bits_exceptionVec_21),
    .io_wb_11_bits_exceptionVec_22(eg_io_wb_11_bits_exceptionVec_22),
    .io_wb_11_bits_exceptionVec_23(eg_io_wb_11_bits_exceptionVec_23),
    .io_wb_11_bits_flushPipe(eg_io_wb_11_bits_flushPipe),
    .io_wb_11_bits_replayInst(eg_io_wb_11_bits_replayInst),
    .io_wb_11_bits_trigger(eg_io_wb_11_bits_trigger),
    .io_wb_11_bits_vstartEn(eg_io_wb_11_bits_vstartEn),
    .io_wb_11_bits_vstart(eg_io_wb_11_bits_vstart),
    .io_wb_11_bits_vuopIdx(eg_io_wb_11_bits_vuopIdx),
    .io_wb_11_bits_isVecLoad(eg_io_wb_11_bits_isVecLoad),
    .io_wb_11_bits_isVlm(eg_io_wb_11_bits_isVlm),
    .io_wb_11_bits_isStrided(eg_io_wb_11_bits_isStrided),
    .io_wb_11_bits_isIndexed(eg_io_wb_11_bits_isIndexed),
    .io_wb_11_bits_isWhole(eg_io_wb_11_bits_isWhole),
    .io_wb_11_bits_nf(eg_io_wb_11_bits_nf),
    .io_wb_11_bits_vsew(eg_io_wb_11_bits_vsew),
    .io_wb_11_bits_veew(eg_io_wb_11_bits_veew),
    .io_wb_11_bits_vlmul(eg_io_wb_11_bits_vlmul),
    .io_wb_12_valid(eg_io_wb_12_valid),
    .io_wb_12_bits_robIdx_flag(eg_io_wb_12_bits_robIdx_flag),
    .io_wb_12_bits_robIdx_value(eg_io_wb_12_bits_robIdx_value),
    .io_wb_12_bits_hasException(eg_io_wb_12_bits_hasException),
    .io_wb_12_bits_exceptionVec_0(eg_io_wb_12_bits_exceptionVec_0),
    .io_wb_12_bits_exceptionVec_1(eg_io_wb_12_bits_exceptionVec_1),
    .io_wb_12_bits_exceptionVec_2(eg_io_wb_12_bits_exceptionVec_2),
    .io_wb_12_bits_exceptionVec_3(eg_io_wb_12_bits_exceptionVec_3),
    .io_wb_12_bits_exceptionVec_4(eg_io_wb_12_bits_exceptionVec_4),
    .io_wb_12_bits_exceptionVec_5(eg_io_wb_12_bits_exceptionVec_5),
    .io_wb_12_bits_exceptionVec_6(eg_io_wb_12_bits_exceptionVec_6),
    .io_wb_12_bits_exceptionVec_7(eg_io_wb_12_bits_exceptionVec_7),
    .io_wb_12_bits_exceptionVec_8(eg_io_wb_12_bits_exceptionVec_8),
    .io_wb_12_bits_exceptionVec_9(eg_io_wb_12_bits_exceptionVec_9),
    .io_wb_12_bits_exceptionVec_10(eg_io_wb_12_bits_exceptionVec_10),
    .io_wb_12_bits_exceptionVec_11(eg_io_wb_12_bits_exceptionVec_11),
    .io_wb_12_bits_exceptionVec_12(eg_io_wb_12_bits_exceptionVec_12),
    .io_wb_12_bits_exceptionVec_13(eg_io_wb_12_bits_exceptionVec_13),
    .io_wb_12_bits_exceptionVec_14(eg_io_wb_12_bits_exceptionVec_14),
    .io_wb_12_bits_exceptionVec_15(eg_io_wb_12_bits_exceptionVec_15),
    .io_wb_12_bits_exceptionVec_16(eg_io_wb_12_bits_exceptionVec_16),
    .io_wb_12_bits_exceptionVec_17(eg_io_wb_12_bits_exceptionVec_17),
    .io_wb_12_bits_exceptionVec_18(eg_io_wb_12_bits_exceptionVec_18),
    .io_wb_12_bits_exceptionVec_19(eg_io_wb_12_bits_exceptionVec_19),
    .io_wb_12_bits_exceptionVec_20(eg_io_wb_12_bits_exceptionVec_20),
    .io_wb_12_bits_exceptionVec_21(eg_io_wb_12_bits_exceptionVec_21),
    .io_wb_12_bits_exceptionVec_22(eg_io_wb_12_bits_exceptionVec_22),
    .io_wb_12_bits_exceptionVec_23(eg_io_wb_12_bits_exceptionVec_23),
    .io_wb_12_bits_flushPipe(eg_io_wb_12_bits_flushPipe),
    .io_wb_12_bits_replayInst(eg_io_wb_12_bits_replayInst),
    .io_wb_12_bits_trigger(eg_io_wb_12_bits_trigger),
    .io_wb_12_bits_vstartEn(eg_io_wb_12_bits_vstartEn),
    .io_wb_12_bits_vstart(eg_io_wb_12_bits_vstart),
    .io_wb_12_bits_vuopIdx(eg_io_wb_12_bits_vuopIdx),
    .io_wb_12_bits_isVecLoad(eg_io_wb_12_bits_isVecLoad),
    .io_wb_12_bits_isVlm(eg_io_wb_12_bits_isVlm),
    .io_wb_12_bits_isStrided(eg_io_wb_12_bits_isStrided),
    .io_wb_12_bits_isIndexed(eg_io_wb_12_bits_isIndexed),
    .io_wb_12_bits_isWhole(eg_io_wb_12_bits_isWhole),
    .io_wb_12_bits_nf(eg_io_wb_12_bits_nf),
    .io_wb_12_bits_vsew(eg_io_wb_12_bits_vsew),
    .io_wb_12_bits_veew(eg_io_wb_12_bits_veew),
    .io_wb_12_bits_vlmul(eg_io_wb_12_bits_vlmul),
    .io_state_valid(eg_g_io_state_valid),
    .io_state_bits_robIdx_flag(eg_g_io_state_bits_robIdx_flag),
    .io_state_bits_robIdx_value(eg_g_io_state_bits_robIdx_value),
    .io_state_bits_ftqPtr_value(eg_g_io_state_bits_ftqPtr_value),
    .io_state_bits_ftqOffset(eg_g_io_state_bits_ftqOffset),
    .io_state_bits_hasException(eg_g_io_state_bits_hasException),
    .io_state_bits_isEnqExcp(eg_g_io_state_bits_isEnqExcp),
    .io_state_bits_exceptionVec_0(eg_g_io_state_bits_exceptionVec_0),
    .io_state_bits_exceptionVec_1(eg_g_io_state_bits_exceptionVec_1),
    .io_state_bits_exceptionVec_2(eg_g_io_state_bits_exceptionVec_2),
    .io_state_bits_exceptionVec_3(eg_g_io_state_bits_exceptionVec_3),
    .io_state_bits_exceptionVec_4(eg_g_io_state_bits_exceptionVec_4),
    .io_state_bits_exceptionVec_5(eg_g_io_state_bits_exceptionVec_5),
    .io_state_bits_exceptionVec_6(eg_g_io_state_bits_exceptionVec_6),
    .io_state_bits_exceptionVec_7(eg_g_io_state_bits_exceptionVec_7),
    .io_state_bits_exceptionVec_8(eg_g_io_state_bits_exceptionVec_8),
    .io_state_bits_exceptionVec_9(eg_g_io_state_bits_exceptionVec_9),
    .io_state_bits_exceptionVec_10(eg_g_io_state_bits_exceptionVec_10),
    .io_state_bits_exceptionVec_11(eg_g_io_state_bits_exceptionVec_11),
    .io_state_bits_exceptionVec_12(eg_g_io_state_bits_exceptionVec_12),
    .io_state_bits_exceptionVec_13(eg_g_io_state_bits_exceptionVec_13),
    .io_state_bits_exceptionVec_14(eg_g_io_state_bits_exceptionVec_14),
    .io_state_bits_exceptionVec_15(eg_g_io_state_bits_exceptionVec_15),
    .io_state_bits_exceptionVec_16(eg_g_io_state_bits_exceptionVec_16),
    .io_state_bits_exceptionVec_17(eg_g_io_state_bits_exceptionVec_17),
    .io_state_bits_exceptionVec_18(eg_g_io_state_bits_exceptionVec_18),
    .io_state_bits_exceptionVec_19(eg_g_io_state_bits_exceptionVec_19),
    .io_state_bits_exceptionVec_20(eg_g_io_state_bits_exceptionVec_20),
    .io_state_bits_exceptionVec_21(eg_g_io_state_bits_exceptionVec_21),
    .io_state_bits_exceptionVec_22(eg_g_io_state_bits_exceptionVec_22),
    .io_state_bits_exceptionVec_23(eg_g_io_state_bits_exceptionVec_23),
    .io_state_bits_isFetchMalAddr(eg_g_io_state_bits_isFetchMalAddr),
    .io_state_bits_satpFlushFirstFetchFault(eg_g_io_state_bits_satpFlushFirstFetchFault),
    .io_state_bits_flushPipe(eg_g_io_state_bits_flushPipe),
    .io_state_bits_satpFlushPipe(eg_g_io_state_bits_satpFlushPipe),
    .io_state_bits_isVset(eg_g_io_state_bits_isVset),
    .io_state_bits_replayInst(eg_g_io_state_bits_replayInst),
    .io_state_bits_singleStep(eg_g_io_state_bits_singleStep),
    .io_state_bits_crossPageIPFFix(eg_g_io_state_bits_crossPageIPFFix),
    .io_state_bits_trigger(eg_g_io_state_bits_trigger),
    .io_state_bits_vstartEn(eg_g_io_state_bits_vstartEn),
    .io_state_bits_vstart(eg_g_io_state_bits_vstart),
    .io_state_bits_isVecLoad(eg_g_io_state_bits_isVecLoad),
    .io_state_bits_isVlm(eg_g_io_state_bits_isVlm),
    .io_state_bits_isStrided(eg_g_io_state_bits_isStrided),
    .io_state_bits_isIndexed(eg_g_io_state_bits_isIndexed),
    .io_state_bits_isWhole(eg_g_io_state_bits_isWhole),
    .io_state_bits_nf(eg_g_io_state_bits_nf),
    .io_state_bits_vsew(eg_g_io_state_bits_vsew),
    .io_state_bits_veew(eg_g_io_state_bits_veew),
    .io_state_bits_vlmul(eg_g_io_state_bits_vlmul)
  );
  ExceptionGen_xs eg_u_impl (
    .clock(clk),
    .reset(eg_reset),
    .io_redirect_valid(eg_io_redirect_valid),
    .io_redirect_bits_robIdx_flag(eg_io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value(eg_io_redirect_bits_robIdx_value),
    .io_redirect_bits_level(eg_io_redirect_bits_level),
    .io_flush(eg_io_flush),
    .io_enq_0_valid(eg_io_enq_0_valid),
    .io_enq_0_bits_robIdx_flag(eg_io_enq_0_bits_robIdx_flag),
    .io_enq_0_bits_robIdx_value(eg_io_enq_0_bits_robIdx_value),
    .io_enq_0_bits_ftqPtr_value(eg_io_enq_0_bits_ftqPtr_value),
    .io_enq_0_bits_ftqOffset(eg_io_enq_0_bits_ftqOffset),
    .io_enq_0_bits_hasException(eg_io_enq_0_bits_hasException),
    .io_enq_0_bits_exceptionVec_0(eg_io_enq_0_bits_exceptionVec_0),
    .io_enq_0_bits_exceptionVec_1(eg_io_enq_0_bits_exceptionVec_1),
    .io_enq_0_bits_exceptionVec_2(eg_io_enq_0_bits_exceptionVec_2),
    .io_enq_0_bits_exceptionVec_3(eg_io_enq_0_bits_exceptionVec_3),
    .io_enq_0_bits_exceptionVec_12(eg_io_enq_0_bits_exceptionVec_12),
    .io_enq_0_bits_exceptionVec_20(eg_io_enq_0_bits_exceptionVec_20),
    .io_enq_0_bits_exceptionVec_22(eg_io_enq_0_bits_exceptionVec_22),
    .io_enq_0_bits_isFetchMalAddr(eg_io_enq_0_bits_isFetchMalAddr),
    .io_enq_0_bits_satpFlushFirstFetchFault(eg_io_enq_0_bits_satpFlushFirstFetchFault),
    .io_enq_0_bits_flushPipe(eg_io_enq_0_bits_flushPipe),
    .io_enq_0_bits_isVset(eg_io_enq_0_bits_isVset),
    .io_enq_0_bits_singleStep(eg_io_enq_0_bits_singleStep),
    .io_enq_0_bits_crossPageIPFFix(eg_io_enq_0_bits_crossPageIPFFix),
    .io_enq_0_bits_trigger(eg_io_enq_0_bits_trigger),
    .io_enq_1_valid(eg_io_enq_1_valid),
    .io_enq_1_bits_robIdx_flag(eg_io_enq_1_bits_robIdx_flag),
    .io_enq_1_bits_robIdx_value(eg_io_enq_1_bits_robIdx_value),
    .io_enq_1_bits_ftqPtr_value(eg_io_enq_1_bits_ftqPtr_value),
    .io_enq_1_bits_ftqOffset(eg_io_enq_1_bits_ftqOffset),
    .io_enq_1_bits_hasException(eg_io_enq_1_bits_hasException),
    .io_enq_1_bits_exceptionVec_0(eg_io_enq_1_bits_exceptionVec_0),
    .io_enq_1_bits_exceptionVec_1(eg_io_enq_1_bits_exceptionVec_1),
    .io_enq_1_bits_exceptionVec_2(eg_io_enq_1_bits_exceptionVec_2),
    .io_enq_1_bits_exceptionVec_3(eg_io_enq_1_bits_exceptionVec_3),
    .io_enq_1_bits_exceptionVec_12(eg_io_enq_1_bits_exceptionVec_12),
    .io_enq_1_bits_exceptionVec_20(eg_io_enq_1_bits_exceptionVec_20),
    .io_enq_1_bits_exceptionVec_22(eg_io_enq_1_bits_exceptionVec_22),
    .io_enq_1_bits_isFetchMalAddr(eg_io_enq_1_bits_isFetchMalAddr),
    .io_enq_1_bits_satpFlushFirstFetchFault(eg_io_enq_1_bits_satpFlushFirstFetchFault),
    .io_enq_1_bits_flushPipe(eg_io_enq_1_bits_flushPipe),
    .io_enq_1_bits_isVset(eg_io_enq_1_bits_isVset),
    .io_enq_1_bits_singleStep(eg_io_enq_1_bits_singleStep),
    .io_enq_1_bits_crossPageIPFFix(eg_io_enq_1_bits_crossPageIPFFix),
    .io_enq_1_bits_trigger(eg_io_enq_1_bits_trigger),
    .io_enq_2_valid(eg_io_enq_2_valid),
    .io_enq_2_bits_robIdx_flag(eg_io_enq_2_bits_robIdx_flag),
    .io_enq_2_bits_robIdx_value(eg_io_enq_2_bits_robIdx_value),
    .io_enq_2_bits_ftqPtr_value(eg_io_enq_2_bits_ftqPtr_value),
    .io_enq_2_bits_ftqOffset(eg_io_enq_2_bits_ftqOffset),
    .io_enq_2_bits_hasException(eg_io_enq_2_bits_hasException),
    .io_enq_2_bits_exceptionVec_0(eg_io_enq_2_bits_exceptionVec_0),
    .io_enq_2_bits_exceptionVec_1(eg_io_enq_2_bits_exceptionVec_1),
    .io_enq_2_bits_exceptionVec_2(eg_io_enq_2_bits_exceptionVec_2),
    .io_enq_2_bits_exceptionVec_3(eg_io_enq_2_bits_exceptionVec_3),
    .io_enq_2_bits_exceptionVec_12(eg_io_enq_2_bits_exceptionVec_12),
    .io_enq_2_bits_exceptionVec_20(eg_io_enq_2_bits_exceptionVec_20),
    .io_enq_2_bits_exceptionVec_22(eg_io_enq_2_bits_exceptionVec_22),
    .io_enq_2_bits_isFetchMalAddr(eg_io_enq_2_bits_isFetchMalAddr),
    .io_enq_2_bits_satpFlushFirstFetchFault(eg_io_enq_2_bits_satpFlushFirstFetchFault),
    .io_enq_2_bits_flushPipe(eg_io_enq_2_bits_flushPipe),
    .io_enq_2_bits_isVset(eg_io_enq_2_bits_isVset),
    .io_enq_2_bits_singleStep(eg_io_enq_2_bits_singleStep),
    .io_enq_2_bits_crossPageIPFFix(eg_io_enq_2_bits_crossPageIPFFix),
    .io_enq_2_bits_trigger(eg_io_enq_2_bits_trigger),
    .io_enq_3_valid(eg_io_enq_3_valid),
    .io_enq_3_bits_robIdx_flag(eg_io_enq_3_bits_robIdx_flag),
    .io_enq_3_bits_robIdx_value(eg_io_enq_3_bits_robIdx_value),
    .io_enq_3_bits_ftqPtr_value(eg_io_enq_3_bits_ftqPtr_value),
    .io_enq_3_bits_ftqOffset(eg_io_enq_3_bits_ftqOffset),
    .io_enq_3_bits_hasException(eg_io_enq_3_bits_hasException),
    .io_enq_3_bits_exceptionVec_0(eg_io_enq_3_bits_exceptionVec_0),
    .io_enq_3_bits_exceptionVec_1(eg_io_enq_3_bits_exceptionVec_1),
    .io_enq_3_bits_exceptionVec_2(eg_io_enq_3_bits_exceptionVec_2),
    .io_enq_3_bits_exceptionVec_3(eg_io_enq_3_bits_exceptionVec_3),
    .io_enq_3_bits_exceptionVec_12(eg_io_enq_3_bits_exceptionVec_12),
    .io_enq_3_bits_exceptionVec_20(eg_io_enq_3_bits_exceptionVec_20),
    .io_enq_3_bits_exceptionVec_22(eg_io_enq_3_bits_exceptionVec_22),
    .io_enq_3_bits_isFetchMalAddr(eg_io_enq_3_bits_isFetchMalAddr),
    .io_enq_3_bits_satpFlushFirstFetchFault(eg_io_enq_3_bits_satpFlushFirstFetchFault),
    .io_enq_3_bits_flushPipe(eg_io_enq_3_bits_flushPipe),
    .io_enq_3_bits_isVset(eg_io_enq_3_bits_isVset),
    .io_enq_3_bits_singleStep(eg_io_enq_3_bits_singleStep),
    .io_enq_3_bits_crossPageIPFFix(eg_io_enq_3_bits_crossPageIPFFix),
    .io_enq_3_bits_trigger(eg_io_enq_3_bits_trigger),
    .io_enq_4_valid(eg_io_enq_4_valid),
    .io_enq_4_bits_robIdx_flag(eg_io_enq_4_bits_robIdx_flag),
    .io_enq_4_bits_robIdx_value(eg_io_enq_4_bits_robIdx_value),
    .io_enq_4_bits_ftqPtr_value(eg_io_enq_4_bits_ftqPtr_value),
    .io_enq_4_bits_ftqOffset(eg_io_enq_4_bits_ftqOffset),
    .io_enq_4_bits_hasException(eg_io_enq_4_bits_hasException),
    .io_enq_4_bits_exceptionVec_0(eg_io_enq_4_bits_exceptionVec_0),
    .io_enq_4_bits_exceptionVec_1(eg_io_enq_4_bits_exceptionVec_1),
    .io_enq_4_bits_exceptionVec_2(eg_io_enq_4_bits_exceptionVec_2),
    .io_enq_4_bits_exceptionVec_3(eg_io_enq_4_bits_exceptionVec_3),
    .io_enq_4_bits_exceptionVec_12(eg_io_enq_4_bits_exceptionVec_12),
    .io_enq_4_bits_exceptionVec_20(eg_io_enq_4_bits_exceptionVec_20),
    .io_enq_4_bits_exceptionVec_22(eg_io_enq_4_bits_exceptionVec_22),
    .io_enq_4_bits_isFetchMalAddr(eg_io_enq_4_bits_isFetchMalAddr),
    .io_enq_4_bits_satpFlushFirstFetchFault(eg_io_enq_4_bits_satpFlushFirstFetchFault),
    .io_enq_4_bits_flushPipe(eg_io_enq_4_bits_flushPipe),
    .io_enq_4_bits_isVset(eg_io_enq_4_bits_isVset),
    .io_enq_4_bits_singleStep(eg_io_enq_4_bits_singleStep),
    .io_enq_4_bits_crossPageIPFFix(eg_io_enq_4_bits_crossPageIPFFix),
    .io_enq_4_bits_trigger(eg_io_enq_4_bits_trigger),
    .io_enq_5_valid(eg_io_enq_5_valid),
    .io_enq_5_bits_robIdx_flag(eg_io_enq_5_bits_robIdx_flag),
    .io_enq_5_bits_robIdx_value(eg_io_enq_5_bits_robIdx_value),
    .io_enq_5_bits_ftqPtr_value(eg_io_enq_5_bits_ftqPtr_value),
    .io_enq_5_bits_ftqOffset(eg_io_enq_5_bits_ftqOffset),
    .io_enq_5_bits_hasException(eg_io_enq_5_bits_hasException),
    .io_enq_5_bits_exceptionVec_0(eg_io_enq_5_bits_exceptionVec_0),
    .io_enq_5_bits_exceptionVec_1(eg_io_enq_5_bits_exceptionVec_1),
    .io_enq_5_bits_exceptionVec_2(eg_io_enq_5_bits_exceptionVec_2),
    .io_enq_5_bits_exceptionVec_3(eg_io_enq_5_bits_exceptionVec_3),
    .io_enq_5_bits_exceptionVec_12(eg_io_enq_5_bits_exceptionVec_12),
    .io_enq_5_bits_exceptionVec_20(eg_io_enq_5_bits_exceptionVec_20),
    .io_enq_5_bits_exceptionVec_22(eg_io_enq_5_bits_exceptionVec_22),
    .io_enq_5_bits_isFetchMalAddr(eg_io_enq_5_bits_isFetchMalAddr),
    .io_enq_5_bits_satpFlushFirstFetchFault(eg_io_enq_5_bits_satpFlushFirstFetchFault),
    .io_enq_5_bits_flushPipe(eg_io_enq_5_bits_flushPipe),
    .io_enq_5_bits_isVset(eg_io_enq_5_bits_isVset),
    .io_enq_5_bits_singleStep(eg_io_enq_5_bits_singleStep),
    .io_enq_5_bits_crossPageIPFFix(eg_io_enq_5_bits_crossPageIPFFix),
    .io_enq_5_bits_trigger(eg_io_enq_5_bits_trigger),
    .io_wb_0_valid(eg_io_wb_0_valid),
    .io_wb_0_bits_robIdx_flag(eg_io_wb_0_bits_robIdx_flag),
    .io_wb_0_bits_robIdx_value(eg_io_wb_0_bits_robIdx_value),
    .io_wb_0_bits_hasException(eg_io_wb_0_bits_hasException),
    .io_wb_0_bits_exceptionVec_2(eg_io_wb_0_bits_exceptionVec_2),
    .io_wb_0_bits_exceptionVec_3(eg_io_wb_0_bits_exceptionVec_3),
    .io_wb_0_bits_exceptionVec_8(eg_io_wb_0_bits_exceptionVec_8),
    .io_wb_0_bits_exceptionVec_9(eg_io_wb_0_bits_exceptionVec_9),
    .io_wb_0_bits_exceptionVec_10(eg_io_wb_0_bits_exceptionVec_10),
    .io_wb_0_bits_exceptionVec_11(eg_io_wb_0_bits_exceptionVec_11),
    .io_wb_0_bits_exceptionVec_22(eg_io_wb_0_bits_exceptionVec_22),
    .io_wb_0_bits_flushPipe(eg_io_wb_0_bits_flushPipe),
    .io_wb_0_bits_satpFlushPipe(eg_io_wb_0_bits_satpFlushPipe),
    .io_wb_1_valid(eg_io_wb_1_valid),
    .io_wb_1_bits_robIdx_flag(eg_io_wb_1_bits_robIdx_flag),
    .io_wb_1_bits_robIdx_value(eg_io_wb_1_bits_robIdx_value),
    .io_wb_1_bits_hasException(eg_io_wb_1_bits_hasException),
    .io_wb_1_bits_exceptionVec_2(eg_io_wb_1_bits_exceptionVec_2),
    .io_wb_2_valid(eg_io_wb_2_valid),
    .io_wb_2_bits_robIdx_flag(eg_io_wb_2_bits_robIdx_flag),
    .io_wb_2_bits_robIdx_value(eg_io_wb_2_bits_robIdx_value),
    .io_wb_2_bits_hasException(eg_io_wb_2_bits_hasException),
    .io_wb_2_bits_exceptionVec_2(eg_io_wb_2_bits_exceptionVec_2),
    .io_wb_3_bits_robIdx_flag(eg_io_wb_3_bits_robIdx_flag),
    .io_wb_3_bits_robIdx_value(eg_io_wb_3_bits_robIdx_value),
    .io_wb_4_bits_robIdx_flag(eg_io_wb_4_bits_robIdx_flag),
    .io_wb_4_bits_robIdx_value(eg_io_wb_4_bits_robIdx_value),
    .io_wb_5_bits_robIdx_flag(eg_io_wb_5_bits_robIdx_flag),
    .io_wb_5_bits_robIdx_value(eg_io_wb_5_bits_robIdx_value),
    .io_wb_6_valid(eg_io_wb_6_valid),
    .io_wb_6_bits_robIdx_flag(eg_io_wb_6_bits_robIdx_flag),
    .io_wb_6_bits_robIdx_value(eg_io_wb_6_bits_robIdx_value),
    .io_wb_6_bits_hasException(eg_io_wb_6_bits_hasException),
    .io_wb_6_bits_exceptionVec_0(eg_io_wb_6_bits_exceptionVec_0),
    .io_wb_6_bits_exceptionVec_1(eg_io_wb_6_bits_exceptionVec_1),
    .io_wb_6_bits_exceptionVec_2(eg_io_wb_6_bits_exceptionVec_2),
    .io_wb_6_bits_exceptionVec_3(eg_io_wb_6_bits_exceptionVec_3),
    .io_wb_6_bits_exceptionVec_4(eg_io_wb_6_bits_exceptionVec_4),
    .io_wb_6_bits_exceptionVec_5(eg_io_wb_6_bits_exceptionVec_5),
    .io_wb_6_bits_exceptionVec_6(eg_io_wb_6_bits_exceptionVec_6),
    .io_wb_6_bits_exceptionVec_7(eg_io_wb_6_bits_exceptionVec_7),
    .io_wb_6_bits_exceptionVec_8(eg_io_wb_6_bits_exceptionVec_8),
    .io_wb_6_bits_exceptionVec_9(eg_io_wb_6_bits_exceptionVec_9),
    .io_wb_6_bits_exceptionVec_10(eg_io_wb_6_bits_exceptionVec_10),
    .io_wb_6_bits_exceptionVec_11(eg_io_wb_6_bits_exceptionVec_11),
    .io_wb_6_bits_exceptionVec_12(eg_io_wb_6_bits_exceptionVec_12),
    .io_wb_6_bits_exceptionVec_13(eg_io_wb_6_bits_exceptionVec_13),
    .io_wb_6_bits_exceptionVec_14(eg_io_wb_6_bits_exceptionVec_14),
    .io_wb_6_bits_exceptionVec_15(eg_io_wb_6_bits_exceptionVec_15),
    .io_wb_6_bits_exceptionVec_16(eg_io_wb_6_bits_exceptionVec_16),
    .io_wb_6_bits_exceptionVec_17(eg_io_wb_6_bits_exceptionVec_17),
    .io_wb_6_bits_exceptionVec_18(eg_io_wb_6_bits_exceptionVec_18),
    .io_wb_6_bits_exceptionVec_19(eg_io_wb_6_bits_exceptionVec_19),
    .io_wb_6_bits_exceptionVec_20(eg_io_wb_6_bits_exceptionVec_20),
    .io_wb_6_bits_exceptionVec_21(eg_io_wb_6_bits_exceptionVec_21),
    .io_wb_6_bits_exceptionVec_22(eg_io_wb_6_bits_exceptionVec_22),
    .io_wb_6_bits_exceptionVec_23(eg_io_wb_6_bits_exceptionVec_23),
    .io_wb_6_bits_flushPipe(eg_io_wb_6_bits_flushPipe),
    .io_wb_6_bits_trigger(eg_io_wb_6_bits_trigger),
    .io_wb_7_valid(eg_io_wb_7_valid),
    .io_wb_7_bits_robIdx_flag(eg_io_wb_7_bits_robIdx_flag),
    .io_wb_7_bits_robIdx_value(eg_io_wb_7_bits_robIdx_value),
    .io_wb_7_bits_hasException(eg_io_wb_7_bits_hasException),
    .io_wb_7_bits_exceptionVec_0(eg_io_wb_7_bits_exceptionVec_0),
    .io_wb_7_bits_exceptionVec_1(eg_io_wb_7_bits_exceptionVec_1),
    .io_wb_7_bits_exceptionVec_2(eg_io_wb_7_bits_exceptionVec_2),
    .io_wb_7_bits_exceptionVec_3(eg_io_wb_7_bits_exceptionVec_3),
    .io_wb_7_bits_exceptionVec_4(eg_io_wb_7_bits_exceptionVec_4),
    .io_wb_7_bits_exceptionVec_5(eg_io_wb_7_bits_exceptionVec_5),
    .io_wb_7_bits_exceptionVec_6(eg_io_wb_7_bits_exceptionVec_6),
    .io_wb_7_bits_exceptionVec_7(eg_io_wb_7_bits_exceptionVec_7),
    .io_wb_7_bits_exceptionVec_8(eg_io_wb_7_bits_exceptionVec_8),
    .io_wb_7_bits_exceptionVec_9(eg_io_wb_7_bits_exceptionVec_9),
    .io_wb_7_bits_exceptionVec_10(eg_io_wb_7_bits_exceptionVec_10),
    .io_wb_7_bits_exceptionVec_11(eg_io_wb_7_bits_exceptionVec_11),
    .io_wb_7_bits_exceptionVec_12(eg_io_wb_7_bits_exceptionVec_12),
    .io_wb_7_bits_exceptionVec_13(eg_io_wb_7_bits_exceptionVec_13),
    .io_wb_7_bits_exceptionVec_14(eg_io_wb_7_bits_exceptionVec_14),
    .io_wb_7_bits_exceptionVec_15(eg_io_wb_7_bits_exceptionVec_15),
    .io_wb_7_bits_exceptionVec_16(eg_io_wb_7_bits_exceptionVec_16),
    .io_wb_7_bits_exceptionVec_17(eg_io_wb_7_bits_exceptionVec_17),
    .io_wb_7_bits_exceptionVec_18(eg_io_wb_7_bits_exceptionVec_18),
    .io_wb_7_bits_exceptionVec_19(eg_io_wb_7_bits_exceptionVec_19),
    .io_wb_7_bits_exceptionVec_20(eg_io_wb_7_bits_exceptionVec_20),
    .io_wb_7_bits_exceptionVec_21(eg_io_wb_7_bits_exceptionVec_21),
    .io_wb_7_bits_exceptionVec_22(eg_io_wb_7_bits_exceptionVec_22),
    .io_wb_7_bits_exceptionVec_23(eg_io_wb_7_bits_exceptionVec_23),
    .io_wb_7_bits_flushPipe(eg_io_wb_7_bits_flushPipe),
    .io_wb_7_bits_trigger(eg_io_wb_7_bits_trigger),
    .io_wb_8_valid(eg_io_wb_8_valid),
    .io_wb_8_bits_robIdx_flag(eg_io_wb_8_bits_robIdx_flag),
    .io_wb_8_bits_robIdx_value(eg_io_wb_8_bits_robIdx_value),
    .io_wb_8_bits_hasException(eg_io_wb_8_bits_hasException),
    .io_wb_8_bits_exceptionVec_0(eg_io_wb_8_bits_exceptionVec_0),
    .io_wb_8_bits_exceptionVec_1(eg_io_wb_8_bits_exceptionVec_1),
    .io_wb_8_bits_exceptionVec_2(eg_io_wb_8_bits_exceptionVec_2),
    .io_wb_8_bits_exceptionVec_3(eg_io_wb_8_bits_exceptionVec_3),
    .io_wb_8_bits_exceptionVec_4(eg_io_wb_8_bits_exceptionVec_4),
    .io_wb_8_bits_exceptionVec_5(eg_io_wb_8_bits_exceptionVec_5),
    .io_wb_8_bits_exceptionVec_6(eg_io_wb_8_bits_exceptionVec_6),
    .io_wb_8_bits_exceptionVec_7(eg_io_wb_8_bits_exceptionVec_7),
    .io_wb_8_bits_exceptionVec_8(eg_io_wb_8_bits_exceptionVec_8),
    .io_wb_8_bits_exceptionVec_9(eg_io_wb_8_bits_exceptionVec_9),
    .io_wb_8_bits_exceptionVec_10(eg_io_wb_8_bits_exceptionVec_10),
    .io_wb_8_bits_exceptionVec_11(eg_io_wb_8_bits_exceptionVec_11),
    .io_wb_8_bits_exceptionVec_12(eg_io_wb_8_bits_exceptionVec_12),
    .io_wb_8_bits_exceptionVec_13(eg_io_wb_8_bits_exceptionVec_13),
    .io_wb_8_bits_exceptionVec_14(eg_io_wb_8_bits_exceptionVec_14),
    .io_wb_8_bits_exceptionVec_15(eg_io_wb_8_bits_exceptionVec_15),
    .io_wb_8_bits_exceptionVec_16(eg_io_wb_8_bits_exceptionVec_16),
    .io_wb_8_bits_exceptionVec_17(eg_io_wb_8_bits_exceptionVec_17),
    .io_wb_8_bits_exceptionVec_18(eg_io_wb_8_bits_exceptionVec_18),
    .io_wb_8_bits_exceptionVec_19(eg_io_wb_8_bits_exceptionVec_19),
    .io_wb_8_bits_exceptionVec_20(eg_io_wb_8_bits_exceptionVec_20),
    .io_wb_8_bits_exceptionVec_21(eg_io_wb_8_bits_exceptionVec_21),
    .io_wb_8_bits_exceptionVec_22(eg_io_wb_8_bits_exceptionVec_22),
    .io_wb_8_bits_exceptionVec_23(eg_io_wb_8_bits_exceptionVec_23),
    .io_wb_8_bits_flushPipe(eg_io_wb_8_bits_flushPipe),
    .io_wb_8_bits_replayInst(eg_io_wb_8_bits_replayInst),
    .io_wb_8_bits_trigger(eg_io_wb_8_bits_trigger),
    .io_wb_9_valid(eg_io_wb_9_valid),
    .io_wb_9_bits_robIdx_flag(eg_io_wb_9_bits_robIdx_flag),
    .io_wb_9_bits_robIdx_value(eg_io_wb_9_bits_robIdx_value),
    .io_wb_9_bits_hasException(eg_io_wb_9_bits_hasException),
    .io_wb_9_bits_exceptionVec_0(eg_io_wb_9_bits_exceptionVec_0),
    .io_wb_9_bits_exceptionVec_1(eg_io_wb_9_bits_exceptionVec_1),
    .io_wb_9_bits_exceptionVec_2(eg_io_wb_9_bits_exceptionVec_2),
    .io_wb_9_bits_exceptionVec_3(eg_io_wb_9_bits_exceptionVec_3),
    .io_wb_9_bits_exceptionVec_4(eg_io_wb_9_bits_exceptionVec_4),
    .io_wb_9_bits_exceptionVec_5(eg_io_wb_9_bits_exceptionVec_5),
    .io_wb_9_bits_exceptionVec_6(eg_io_wb_9_bits_exceptionVec_6),
    .io_wb_9_bits_exceptionVec_7(eg_io_wb_9_bits_exceptionVec_7),
    .io_wb_9_bits_exceptionVec_8(eg_io_wb_9_bits_exceptionVec_8),
    .io_wb_9_bits_exceptionVec_9(eg_io_wb_9_bits_exceptionVec_9),
    .io_wb_9_bits_exceptionVec_10(eg_io_wb_9_bits_exceptionVec_10),
    .io_wb_9_bits_exceptionVec_11(eg_io_wb_9_bits_exceptionVec_11),
    .io_wb_9_bits_exceptionVec_12(eg_io_wb_9_bits_exceptionVec_12),
    .io_wb_9_bits_exceptionVec_13(eg_io_wb_9_bits_exceptionVec_13),
    .io_wb_9_bits_exceptionVec_14(eg_io_wb_9_bits_exceptionVec_14),
    .io_wb_9_bits_exceptionVec_15(eg_io_wb_9_bits_exceptionVec_15),
    .io_wb_9_bits_exceptionVec_16(eg_io_wb_9_bits_exceptionVec_16),
    .io_wb_9_bits_exceptionVec_17(eg_io_wb_9_bits_exceptionVec_17),
    .io_wb_9_bits_exceptionVec_18(eg_io_wb_9_bits_exceptionVec_18),
    .io_wb_9_bits_exceptionVec_19(eg_io_wb_9_bits_exceptionVec_19),
    .io_wb_9_bits_exceptionVec_20(eg_io_wb_9_bits_exceptionVec_20),
    .io_wb_9_bits_exceptionVec_21(eg_io_wb_9_bits_exceptionVec_21),
    .io_wb_9_bits_exceptionVec_22(eg_io_wb_9_bits_exceptionVec_22),
    .io_wb_9_bits_exceptionVec_23(eg_io_wb_9_bits_exceptionVec_23),
    .io_wb_9_bits_flushPipe(eg_io_wb_9_bits_flushPipe),
    .io_wb_9_bits_replayInst(eg_io_wb_9_bits_replayInst),
    .io_wb_9_bits_trigger(eg_io_wb_9_bits_trigger),
    .io_wb_10_valid(eg_io_wb_10_valid),
    .io_wb_10_bits_robIdx_flag(eg_io_wb_10_bits_robIdx_flag),
    .io_wb_10_bits_robIdx_value(eg_io_wb_10_bits_robIdx_value),
    .io_wb_10_bits_hasException(eg_io_wb_10_bits_hasException),
    .io_wb_10_bits_exceptionVec_0(eg_io_wb_10_bits_exceptionVec_0),
    .io_wb_10_bits_exceptionVec_1(eg_io_wb_10_bits_exceptionVec_1),
    .io_wb_10_bits_exceptionVec_2(eg_io_wb_10_bits_exceptionVec_2),
    .io_wb_10_bits_exceptionVec_3(eg_io_wb_10_bits_exceptionVec_3),
    .io_wb_10_bits_exceptionVec_4(eg_io_wb_10_bits_exceptionVec_4),
    .io_wb_10_bits_exceptionVec_5(eg_io_wb_10_bits_exceptionVec_5),
    .io_wb_10_bits_exceptionVec_6(eg_io_wb_10_bits_exceptionVec_6),
    .io_wb_10_bits_exceptionVec_7(eg_io_wb_10_bits_exceptionVec_7),
    .io_wb_10_bits_exceptionVec_8(eg_io_wb_10_bits_exceptionVec_8),
    .io_wb_10_bits_exceptionVec_9(eg_io_wb_10_bits_exceptionVec_9),
    .io_wb_10_bits_exceptionVec_10(eg_io_wb_10_bits_exceptionVec_10),
    .io_wb_10_bits_exceptionVec_11(eg_io_wb_10_bits_exceptionVec_11),
    .io_wb_10_bits_exceptionVec_12(eg_io_wb_10_bits_exceptionVec_12),
    .io_wb_10_bits_exceptionVec_13(eg_io_wb_10_bits_exceptionVec_13),
    .io_wb_10_bits_exceptionVec_14(eg_io_wb_10_bits_exceptionVec_14),
    .io_wb_10_bits_exceptionVec_15(eg_io_wb_10_bits_exceptionVec_15),
    .io_wb_10_bits_exceptionVec_16(eg_io_wb_10_bits_exceptionVec_16),
    .io_wb_10_bits_exceptionVec_17(eg_io_wb_10_bits_exceptionVec_17),
    .io_wb_10_bits_exceptionVec_18(eg_io_wb_10_bits_exceptionVec_18),
    .io_wb_10_bits_exceptionVec_19(eg_io_wb_10_bits_exceptionVec_19),
    .io_wb_10_bits_exceptionVec_20(eg_io_wb_10_bits_exceptionVec_20),
    .io_wb_10_bits_exceptionVec_21(eg_io_wb_10_bits_exceptionVec_21),
    .io_wb_10_bits_exceptionVec_22(eg_io_wb_10_bits_exceptionVec_22),
    .io_wb_10_bits_exceptionVec_23(eg_io_wb_10_bits_exceptionVec_23),
    .io_wb_10_bits_flushPipe(eg_io_wb_10_bits_flushPipe),
    .io_wb_10_bits_replayInst(eg_io_wb_10_bits_replayInst),
    .io_wb_10_bits_trigger(eg_io_wb_10_bits_trigger),
    .io_wb_11_valid(eg_io_wb_11_valid),
    .io_wb_11_bits_robIdx_flag(eg_io_wb_11_bits_robIdx_flag),
    .io_wb_11_bits_robIdx_value(eg_io_wb_11_bits_robIdx_value),
    .io_wb_11_bits_hasException(eg_io_wb_11_bits_hasException),
    .io_wb_11_bits_exceptionVec_0(eg_io_wb_11_bits_exceptionVec_0),
    .io_wb_11_bits_exceptionVec_1(eg_io_wb_11_bits_exceptionVec_1),
    .io_wb_11_bits_exceptionVec_2(eg_io_wb_11_bits_exceptionVec_2),
    .io_wb_11_bits_exceptionVec_3(eg_io_wb_11_bits_exceptionVec_3),
    .io_wb_11_bits_exceptionVec_4(eg_io_wb_11_bits_exceptionVec_4),
    .io_wb_11_bits_exceptionVec_5(eg_io_wb_11_bits_exceptionVec_5),
    .io_wb_11_bits_exceptionVec_6(eg_io_wb_11_bits_exceptionVec_6),
    .io_wb_11_bits_exceptionVec_7(eg_io_wb_11_bits_exceptionVec_7),
    .io_wb_11_bits_exceptionVec_8(eg_io_wb_11_bits_exceptionVec_8),
    .io_wb_11_bits_exceptionVec_9(eg_io_wb_11_bits_exceptionVec_9),
    .io_wb_11_bits_exceptionVec_10(eg_io_wb_11_bits_exceptionVec_10),
    .io_wb_11_bits_exceptionVec_11(eg_io_wb_11_bits_exceptionVec_11),
    .io_wb_11_bits_exceptionVec_12(eg_io_wb_11_bits_exceptionVec_12),
    .io_wb_11_bits_exceptionVec_13(eg_io_wb_11_bits_exceptionVec_13),
    .io_wb_11_bits_exceptionVec_14(eg_io_wb_11_bits_exceptionVec_14),
    .io_wb_11_bits_exceptionVec_15(eg_io_wb_11_bits_exceptionVec_15),
    .io_wb_11_bits_exceptionVec_16(eg_io_wb_11_bits_exceptionVec_16),
    .io_wb_11_bits_exceptionVec_17(eg_io_wb_11_bits_exceptionVec_17),
    .io_wb_11_bits_exceptionVec_18(eg_io_wb_11_bits_exceptionVec_18),
    .io_wb_11_bits_exceptionVec_19(eg_io_wb_11_bits_exceptionVec_19),
    .io_wb_11_bits_exceptionVec_20(eg_io_wb_11_bits_exceptionVec_20),
    .io_wb_11_bits_exceptionVec_21(eg_io_wb_11_bits_exceptionVec_21),
    .io_wb_11_bits_exceptionVec_22(eg_io_wb_11_bits_exceptionVec_22),
    .io_wb_11_bits_exceptionVec_23(eg_io_wb_11_bits_exceptionVec_23),
    .io_wb_11_bits_flushPipe(eg_io_wb_11_bits_flushPipe),
    .io_wb_11_bits_replayInst(eg_io_wb_11_bits_replayInst),
    .io_wb_11_bits_trigger(eg_io_wb_11_bits_trigger),
    .io_wb_11_bits_vstartEn(eg_io_wb_11_bits_vstartEn),
    .io_wb_11_bits_vstart(eg_io_wb_11_bits_vstart),
    .io_wb_11_bits_vuopIdx(eg_io_wb_11_bits_vuopIdx),
    .io_wb_11_bits_isVecLoad(eg_io_wb_11_bits_isVecLoad),
    .io_wb_11_bits_isVlm(eg_io_wb_11_bits_isVlm),
    .io_wb_11_bits_isStrided(eg_io_wb_11_bits_isStrided),
    .io_wb_11_bits_isIndexed(eg_io_wb_11_bits_isIndexed),
    .io_wb_11_bits_isWhole(eg_io_wb_11_bits_isWhole),
    .io_wb_11_bits_nf(eg_io_wb_11_bits_nf),
    .io_wb_11_bits_vsew(eg_io_wb_11_bits_vsew),
    .io_wb_11_bits_veew(eg_io_wb_11_bits_veew),
    .io_wb_11_bits_vlmul(eg_io_wb_11_bits_vlmul),
    .io_wb_12_valid(eg_io_wb_12_valid),
    .io_wb_12_bits_robIdx_flag(eg_io_wb_12_bits_robIdx_flag),
    .io_wb_12_bits_robIdx_value(eg_io_wb_12_bits_robIdx_value),
    .io_wb_12_bits_hasException(eg_io_wb_12_bits_hasException),
    .io_wb_12_bits_exceptionVec_0(eg_io_wb_12_bits_exceptionVec_0),
    .io_wb_12_bits_exceptionVec_1(eg_io_wb_12_bits_exceptionVec_1),
    .io_wb_12_bits_exceptionVec_2(eg_io_wb_12_bits_exceptionVec_2),
    .io_wb_12_bits_exceptionVec_3(eg_io_wb_12_bits_exceptionVec_3),
    .io_wb_12_bits_exceptionVec_4(eg_io_wb_12_bits_exceptionVec_4),
    .io_wb_12_bits_exceptionVec_5(eg_io_wb_12_bits_exceptionVec_5),
    .io_wb_12_bits_exceptionVec_6(eg_io_wb_12_bits_exceptionVec_6),
    .io_wb_12_bits_exceptionVec_7(eg_io_wb_12_bits_exceptionVec_7),
    .io_wb_12_bits_exceptionVec_8(eg_io_wb_12_bits_exceptionVec_8),
    .io_wb_12_bits_exceptionVec_9(eg_io_wb_12_bits_exceptionVec_9),
    .io_wb_12_bits_exceptionVec_10(eg_io_wb_12_bits_exceptionVec_10),
    .io_wb_12_bits_exceptionVec_11(eg_io_wb_12_bits_exceptionVec_11),
    .io_wb_12_bits_exceptionVec_12(eg_io_wb_12_bits_exceptionVec_12),
    .io_wb_12_bits_exceptionVec_13(eg_io_wb_12_bits_exceptionVec_13),
    .io_wb_12_bits_exceptionVec_14(eg_io_wb_12_bits_exceptionVec_14),
    .io_wb_12_bits_exceptionVec_15(eg_io_wb_12_bits_exceptionVec_15),
    .io_wb_12_bits_exceptionVec_16(eg_io_wb_12_bits_exceptionVec_16),
    .io_wb_12_bits_exceptionVec_17(eg_io_wb_12_bits_exceptionVec_17),
    .io_wb_12_bits_exceptionVec_18(eg_io_wb_12_bits_exceptionVec_18),
    .io_wb_12_bits_exceptionVec_19(eg_io_wb_12_bits_exceptionVec_19),
    .io_wb_12_bits_exceptionVec_20(eg_io_wb_12_bits_exceptionVec_20),
    .io_wb_12_bits_exceptionVec_21(eg_io_wb_12_bits_exceptionVec_21),
    .io_wb_12_bits_exceptionVec_22(eg_io_wb_12_bits_exceptionVec_22),
    .io_wb_12_bits_exceptionVec_23(eg_io_wb_12_bits_exceptionVec_23),
    .io_wb_12_bits_flushPipe(eg_io_wb_12_bits_flushPipe),
    .io_wb_12_bits_replayInst(eg_io_wb_12_bits_replayInst),
    .io_wb_12_bits_trigger(eg_io_wb_12_bits_trigger),
    .io_wb_12_bits_vstartEn(eg_io_wb_12_bits_vstartEn),
    .io_wb_12_bits_vstart(eg_io_wb_12_bits_vstart),
    .io_wb_12_bits_vuopIdx(eg_io_wb_12_bits_vuopIdx),
    .io_wb_12_bits_isVecLoad(eg_io_wb_12_bits_isVecLoad),
    .io_wb_12_bits_isVlm(eg_io_wb_12_bits_isVlm),
    .io_wb_12_bits_isStrided(eg_io_wb_12_bits_isStrided),
    .io_wb_12_bits_isIndexed(eg_io_wb_12_bits_isIndexed),
    .io_wb_12_bits_isWhole(eg_io_wb_12_bits_isWhole),
    .io_wb_12_bits_nf(eg_io_wb_12_bits_nf),
    .io_wb_12_bits_vsew(eg_io_wb_12_bits_vsew),
    .io_wb_12_bits_veew(eg_io_wb_12_bits_veew),
    .io_wb_12_bits_vlmul(eg_io_wb_12_bits_vlmul),
    .io_state_valid(eg_i_io_state_valid),
    .io_state_bits_robIdx_flag(eg_i_io_state_bits_robIdx_flag),
    .io_state_bits_robIdx_value(eg_i_io_state_bits_robIdx_value),
    .io_state_bits_ftqPtr_value(eg_i_io_state_bits_ftqPtr_value),
    .io_state_bits_ftqOffset(eg_i_io_state_bits_ftqOffset),
    .io_state_bits_hasException(eg_i_io_state_bits_hasException),
    .io_state_bits_isEnqExcp(eg_i_io_state_bits_isEnqExcp),
    .io_state_bits_exceptionVec_0(eg_i_io_state_bits_exceptionVec_0),
    .io_state_bits_exceptionVec_1(eg_i_io_state_bits_exceptionVec_1),
    .io_state_bits_exceptionVec_2(eg_i_io_state_bits_exceptionVec_2),
    .io_state_bits_exceptionVec_3(eg_i_io_state_bits_exceptionVec_3),
    .io_state_bits_exceptionVec_4(eg_i_io_state_bits_exceptionVec_4),
    .io_state_bits_exceptionVec_5(eg_i_io_state_bits_exceptionVec_5),
    .io_state_bits_exceptionVec_6(eg_i_io_state_bits_exceptionVec_6),
    .io_state_bits_exceptionVec_7(eg_i_io_state_bits_exceptionVec_7),
    .io_state_bits_exceptionVec_8(eg_i_io_state_bits_exceptionVec_8),
    .io_state_bits_exceptionVec_9(eg_i_io_state_bits_exceptionVec_9),
    .io_state_bits_exceptionVec_10(eg_i_io_state_bits_exceptionVec_10),
    .io_state_bits_exceptionVec_11(eg_i_io_state_bits_exceptionVec_11),
    .io_state_bits_exceptionVec_12(eg_i_io_state_bits_exceptionVec_12),
    .io_state_bits_exceptionVec_13(eg_i_io_state_bits_exceptionVec_13),
    .io_state_bits_exceptionVec_14(eg_i_io_state_bits_exceptionVec_14),
    .io_state_bits_exceptionVec_15(eg_i_io_state_bits_exceptionVec_15),
    .io_state_bits_exceptionVec_16(eg_i_io_state_bits_exceptionVec_16),
    .io_state_bits_exceptionVec_17(eg_i_io_state_bits_exceptionVec_17),
    .io_state_bits_exceptionVec_18(eg_i_io_state_bits_exceptionVec_18),
    .io_state_bits_exceptionVec_19(eg_i_io_state_bits_exceptionVec_19),
    .io_state_bits_exceptionVec_20(eg_i_io_state_bits_exceptionVec_20),
    .io_state_bits_exceptionVec_21(eg_i_io_state_bits_exceptionVec_21),
    .io_state_bits_exceptionVec_22(eg_i_io_state_bits_exceptionVec_22),
    .io_state_bits_exceptionVec_23(eg_i_io_state_bits_exceptionVec_23),
    .io_state_bits_isFetchMalAddr(eg_i_io_state_bits_isFetchMalAddr),
    .io_state_bits_satpFlushFirstFetchFault(eg_i_io_state_bits_satpFlushFirstFetchFault),
    .io_state_bits_flushPipe(eg_i_io_state_bits_flushPipe),
    .io_state_bits_satpFlushPipe(eg_i_io_state_bits_satpFlushPipe),
    .io_state_bits_isVset(eg_i_io_state_bits_isVset),
    .io_state_bits_replayInst(eg_i_io_state_bits_replayInst),
    .io_state_bits_singleStep(eg_i_io_state_bits_singleStep),
    .io_state_bits_crossPageIPFFix(eg_i_io_state_bits_crossPageIPFFix),
    .io_state_bits_trigger(eg_i_io_state_bits_trigger),
    .io_state_bits_vstartEn(eg_i_io_state_bits_vstartEn),
    .io_state_bits_vstart(eg_i_io_state_bits_vstart),
    .io_state_bits_isVecLoad(eg_i_io_state_bits_isVecLoad),
    .io_state_bits_isVlm(eg_i_io_state_bits_isVlm),
    .io_state_bits_isStrided(eg_i_io_state_bits_isStrided),
    .io_state_bits_isIndexed(eg_i_io_state_bits_isIndexed),
    .io_state_bits_isWhole(eg_i_io_state_bits_isWhole),
    .io_state_bits_nf(eg_i_io_state_bits_nf),
    .io_state_bits_vsew(eg_i_io_state_bits_vsew),
    .io_state_bits_veew(eg_i_io_state_bits_veew),
    .io_state_bits_vlmul(eg_i_io_state_bits_vlmul)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) eg_mode = $urandom_range(0, 15);
      eg_io_redirect_valid = 1'($urandom);
      eg_io_redirect_bits_robIdx_flag = 1'($urandom);
      eg_io_redirect_bits_robIdx_value = 8'($urandom);
      eg_io_redirect_bits_level = 1'($urandom);
      eg_io_flush = 1'($urandom);
      eg_io_enq_0_valid = 1'($urandom);
      eg_io_enq_0_bits_robIdx_flag = 1'($urandom);
      eg_io_enq_0_bits_robIdx_value = 8'($urandom);
      eg_io_enq_0_bits_ftqPtr_value = 6'($urandom);
      eg_io_enq_0_bits_ftqOffset = 4'($urandom);
      eg_io_enq_0_bits_hasException = 1'($urandom);
      eg_io_enq_0_bits_exceptionVec_0 = 1'($urandom);
      eg_io_enq_0_bits_exceptionVec_1 = 1'($urandom);
      eg_io_enq_0_bits_exceptionVec_2 = 1'($urandom);
      eg_io_enq_0_bits_exceptionVec_3 = 1'($urandom);
      eg_io_enq_0_bits_exceptionVec_12 = 1'($urandom);
      eg_io_enq_0_bits_exceptionVec_20 = 1'($urandom);
      eg_io_enq_0_bits_exceptionVec_22 = 1'($urandom);
      eg_io_enq_0_bits_isFetchMalAddr = 1'($urandom);
      eg_io_enq_0_bits_satpFlushFirstFetchFault = 1'($urandom);
      eg_io_enq_0_bits_flushPipe = 1'($urandom);
      eg_io_enq_0_bits_isVset = 1'($urandom);
      eg_io_enq_0_bits_singleStep = 1'($urandom);
      eg_io_enq_0_bits_crossPageIPFFix = 1'($urandom);
      eg_io_enq_0_bits_trigger = 4'($urandom);
      eg_io_enq_1_valid = 1'($urandom);
      eg_io_enq_1_bits_robIdx_flag = 1'($urandom);
      eg_io_enq_1_bits_robIdx_value = 8'($urandom);
      eg_io_enq_1_bits_ftqPtr_value = 6'($urandom);
      eg_io_enq_1_bits_ftqOffset = 4'($urandom);
      eg_io_enq_1_bits_hasException = 1'($urandom);
      eg_io_enq_1_bits_exceptionVec_0 = 1'($urandom);
      eg_io_enq_1_bits_exceptionVec_1 = 1'($urandom);
      eg_io_enq_1_bits_exceptionVec_2 = 1'($urandom);
      eg_io_enq_1_bits_exceptionVec_3 = 1'($urandom);
      eg_io_enq_1_bits_exceptionVec_12 = 1'($urandom);
      eg_io_enq_1_bits_exceptionVec_20 = 1'($urandom);
      eg_io_enq_1_bits_exceptionVec_22 = 1'($urandom);
      eg_io_enq_1_bits_isFetchMalAddr = 1'($urandom);
      eg_io_enq_1_bits_satpFlushFirstFetchFault = 1'($urandom);
      eg_io_enq_1_bits_flushPipe = 1'($urandom);
      eg_io_enq_1_bits_isVset = 1'($urandom);
      eg_io_enq_1_bits_singleStep = 1'($urandom);
      eg_io_enq_1_bits_crossPageIPFFix = 1'($urandom);
      eg_io_enq_1_bits_trigger = 4'($urandom);
      eg_io_enq_2_valid = 1'($urandom);
      eg_io_enq_2_bits_robIdx_flag = 1'($urandom);
      eg_io_enq_2_bits_robIdx_value = 8'($urandom);
      eg_io_enq_2_bits_ftqPtr_value = 6'($urandom);
      eg_io_enq_2_bits_ftqOffset = 4'($urandom);
      eg_io_enq_2_bits_hasException = 1'($urandom);
      eg_io_enq_2_bits_exceptionVec_0 = 1'($urandom);
      eg_io_enq_2_bits_exceptionVec_1 = 1'($urandom);
      eg_io_enq_2_bits_exceptionVec_2 = 1'($urandom);
      eg_io_enq_2_bits_exceptionVec_3 = 1'($urandom);
      eg_io_enq_2_bits_exceptionVec_12 = 1'($urandom);
      eg_io_enq_2_bits_exceptionVec_20 = 1'($urandom);
      eg_io_enq_2_bits_exceptionVec_22 = 1'($urandom);
      eg_io_enq_2_bits_isFetchMalAddr = 1'($urandom);
      eg_io_enq_2_bits_satpFlushFirstFetchFault = 1'($urandom);
      eg_io_enq_2_bits_flushPipe = 1'($urandom);
      eg_io_enq_2_bits_isVset = 1'($urandom);
      eg_io_enq_2_bits_singleStep = 1'($urandom);
      eg_io_enq_2_bits_crossPageIPFFix = 1'($urandom);
      eg_io_enq_2_bits_trigger = 4'($urandom);
      eg_io_enq_3_valid = 1'($urandom);
      eg_io_enq_3_bits_robIdx_flag = 1'($urandom);
      eg_io_enq_3_bits_robIdx_value = 8'($urandom);
      eg_io_enq_3_bits_ftqPtr_value = 6'($urandom);
      eg_io_enq_3_bits_ftqOffset = 4'($urandom);
      eg_io_enq_3_bits_hasException = 1'($urandom);
      eg_io_enq_3_bits_exceptionVec_0 = 1'($urandom);
      eg_io_enq_3_bits_exceptionVec_1 = 1'($urandom);
      eg_io_enq_3_bits_exceptionVec_2 = 1'($urandom);
      eg_io_enq_3_bits_exceptionVec_3 = 1'($urandom);
      eg_io_enq_3_bits_exceptionVec_12 = 1'($urandom);
      eg_io_enq_3_bits_exceptionVec_20 = 1'($urandom);
      eg_io_enq_3_bits_exceptionVec_22 = 1'($urandom);
      eg_io_enq_3_bits_isFetchMalAddr = 1'($urandom);
      eg_io_enq_3_bits_satpFlushFirstFetchFault = 1'($urandom);
      eg_io_enq_3_bits_flushPipe = 1'($urandom);
      eg_io_enq_3_bits_isVset = 1'($urandom);
      eg_io_enq_3_bits_singleStep = 1'($urandom);
      eg_io_enq_3_bits_crossPageIPFFix = 1'($urandom);
      eg_io_enq_3_bits_trigger = 4'($urandom);
      eg_io_enq_4_valid = 1'($urandom);
      eg_io_enq_4_bits_robIdx_flag = 1'($urandom);
      eg_io_enq_4_bits_robIdx_value = 8'($urandom);
      eg_io_enq_4_bits_ftqPtr_value = 6'($urandom);
      eg_io_enq_4_bits_ftqOffset = 4'($urandom);
      eg_io_enq_4_bits_hasException = 1'($urandom);
      eg_io_enq_4_bits_exceptionVec_0 = 1'($urandom);
      eg_io_enq_4_bits_exceptionVec_1 = 1'($urandom);
      eg_io_enq_4_bits_exceptionVec_2 = 1'($urandom);
      eg_io_enq_4_bits_exceptionVec_3 = 1'($urandom);
      eg_io_enq_4_bits_exceptionVec_12 = 1'($urandom);
      eg_io_enq_4_bits_exceptionVec_20 = 1'($urandom);
      eg_io_enq_4_bits_exceptionVec_22 = 1'($urandom);
      eg_io_enq_4_bits_isFetchMalAddr = 1'($urandom);
      eg_io_enq_4_bits_satpFlushFirstFetchFault = 1'($urandom);
      eg_io_enq_4_bits_flushPipe = 1'($urandom);
      eg_io_enq_4_bits_isVset = 1'($urandom);
      eg_io_enq_4_bits_singleStep = 1'($urandom);
      eg_io_enq_4_bits_crossPageIPFFix = 1'($urandom);
      eg_io_enq_4_bits_trigger = 4'($urandom);
      eg_io_enq_5_valid = 1'($urandom);
      eg_io_enq_5_bits_robIdx_flag = 1'($urandom);
      eg_io_enq_5_bits_robIdx_value = 8'($urandom);
      eg_io_enq_5_bits_ftqPtr_value = 6'($urandom);
      eg_io_enq_5_bits_ftqOffset = 4'($urandom);
      eg_io_enq_5_bits_hasException = 1'($urandom);
      eg_io_enq_5_bits_exceptionVec_0 = 1'($urandom);
      eg_io_enq_5_bits_exceptionVec_1 = 1'($urandom);
      eg_io_enq_5_bits_exceptionVec_2 = 1'($urandom);
      eg_io_enq_5_bits_exceptionVec_3 = 1'($urandom);
      eg_io_enq_5_bits_exceptionVec_12 = 1'($urandom);
      eg_io_enq_5_bits_exceptionVec_20 = 1'($urandom);
      eg_io_enq_5_bits_exceptionVec_22 = 1'($urandom);
      eg_io_enq_5_bits_isFetchMalAddr = 1'($urandom);
      eg_io_enq_5_bits_satpFlushFirstFetchFault = 1'($urandom);
      eg_io_enq_5_bits_flushPipe = 1'($urandom);
      eg_io_enq_5_bits_isVset = 1'($urandom);
      eg_io_enq_5_bits_singleStep = 1'($urandom);
      eg_io_enq_5_bits_crossPageIPFFix = 1'($urandom);
      eg_io_enq_5_bits_trigger = 4'($urandom);
      eg_io_wb_0_valid = 1'($urandom);
      eg_io_wb_0_bits_robIdx_flag = 1'($urandom);
      eg_io_wb_0_bits_robIdx_value = 8'($urandom);
      eg_io_wb_0_bits_hasException = 1'($urandom);
      eg_io_wb_0_bits_exceptionVec_2 = 1'($urandom);
      eg_io_wb_0_bits_exceptionVec_3 = 1'($urandom);
      eg_io_wb_0_bits_exceptionVec_8 = 1'($urandom);
      eg_io_wb_0_bits_exceptionVec_9 = 1'($urandom);
      eg_io_wb_0_bits_exceptionVec_10 = 1'($urandom);
      eg_io_wb_0_bits_exceptionVec_11 = 1'($urandom);
      eg_io_wb_0_bits_exceptionVec_22 = 1'($urandom);
      eg_io_wb_0_bits_flushPipe = 1'($urandom);
      eg_io_wb_0_bits_satpFlushPipe = 1'($urandom);
      eg_io_wb_1_valid = 1'($urandom);
      eg_io_wb_1_bits_robIdx_flag = 1'($urandom);
      eg_io_wb_1_bits_robIdx_value = 8'($urandom);
      eg_io_wb_1_bits_hasException = 1'($urandom);
      eg_io_wb_1_bits_exceptionVec_2 = 1'($urandom);
      eg_io_wb_2_valid = 1'($urandom);
      eg_io_wb_2_bits_robIdx_flag = 1'($urandom);
      eg_io_wb_2_bits_robIdx_value = 8'($urandom);
      eg_io_wb_2_bits_hasException = 1'($urandom);
      eg_io_wb_2_bits_exceptionVec_2 = 1'($urandom);
      eg_io_wb_3_bits_robIdx_flag = 1'($urandom);
      eg_io_wb_3_bits_robIdx_value = 8'($urandom);
      eg_io_wb_4_bits_robIdx_flag = 1'($urandom);
      eg_io_wb_4_bits_robIdx_value = 8'($urandom);
      eg_io_wb_5_bits_robIdx_flag = 1'($urandom);
      eg_io_wb_5_bits_robIdx_value = 8'($urandom);
      eg_io_wb_6_valid = 1'($urandom);
      eg_io_wb_6_bits_robIdx_flag = 1'($urandom);
      eg_io_wb_6_bits_robIdx_value = 8'($urandom);
      eg_io_wb_6_bits_hasException = 1'($urandom);
      eg_io_wb_6_bits_exceptionVec_0 = 1'($urandom);
      eg_io_wb_6_bits_exceptionVec_1 = 1'($urandom);
      eg_io_wb_6_bits_exceptionVec_2 = 1'($urandom);
      eg_io_wb_6_bits_exceptionVec_3 = 1'($urandom);
      eg_io_wb_6_bits_exceptionVec_4 = 1'($urandom);
      eg_io_wb_6_bits_exceptionVec_5 = 1'($urandom);
      eg_io_wb_6_bits_exceptionVec_6 = 1'($urandom);
      eg_io_wb_6_bits_exceptionVec_7 = 1'($urandom);
      eg_io_wb_6_bits_exceptionVec_8 = 1'($urandom);
      eg_io_wb_6_bits_exceptionVec_9 = 1'($urandom);
      eg_io_wb_6_bits_exceptionVec_10 = 1'($urandom);
      eg_io_wb_6_bits_exceptionVec_11 = 1'($urandom);
      eg_io_wb_6_bits_exceptionVec_12 = 1'($urandom);
      eg_io_wb_6_bits_exceptionVec_13 = 1'($urandom);
      eg_io_wb_6_bits_exceptionVec_14 = 1'($urandom);
      eg_io_wb_6_bits_exceptionVec_15 = 1'($urandom);
      eg_io_wb_6_bits_exceptionVec_16 = 1'($urandom);
      eg_io_wb_6_bits_exceptionVec_17 = 1'($urandom);
      eg_io_wb_6_bits_exceptionVec_18 = 1'($urandom);
      eg_io_wb_6_bits_exceptionVec_19 = 1'($urandom);
      eg_io_wb_6_bits_exceptionVec_20 = 1'($urandom);
      eg_io_wb_6_bits_exceptionVec_21 = 1'($urandom);
      eg_io_wb_6_bits_exceptionVec_22 = 1'($urandom);
      eg_io_wb_6_bits_exceptionVec_23 = 1'($urandom);
      eg_io_wb_6_bits_flushPipe = 1'($urandom);
      eg_io_wb_6_bits_trigger = 4'($urandom);
      eg_io_wb_7_valid = 1'($urandom);
      eg_io_wb_7_bits_robIdx_flag = 1'($urandom);
      eg_io_wb_7_bits_robIdx_value = 8'($urandom);
      eg_io_wb_7_bits_hasException = 1'($urandom);
      eg_io_wb_7_bits_exceptionVec_0 = 1'($urandom);
      eg_io_wb_7_bits_exceptionVec_1 = 1'($urandom);
      eg_io_wb_7_bits_exceptionVec_2 = 1'($urandom);
      eg_io_wb_7_bits_exceptionVec_3 = 1'($urandom);
      eg_io_wb_7_bits_exceptionVec_4 = 1'($urandom);
      eg_io_wb_7_bits_exceptionVec_5 = 1'($urandom);
      eg_io_wb_7_bits_exceptionVec_6 = 1'($urandom);
      eg_io_wb_7_bits_exceptionVec_7 = 1'($urandom);
      eg_io_wb_7_bits_exceptionVec_8 = 1'($urandom);
      eg_io_wb_7_bits_exceptionVec_9 = 1'($urandom);
      eg_io_wb_7_bits_exceptionVec_10 = 1'($urandom);
      eg_io_wb_7_bits_exceptionVec_11 = 1'($urandom);
      eg_io_wb_7_bits_exceptionVec_12 = 1'($urandom);
      eg_io_wb_7_bits_exceptionVec_13 = 1'($urandom);
      eg_io_wb_7_bits_exceptionVec_14 = 1'($urandom);
      eg_io_wb_7_bits_exceptionVec_15 = 1'($urandom);
      eg_io_wb_7_bits_exceptionVec_16 = 1'($urandom);
      eg_io_wb_7_bits_exceptionVec_17 = 1'($urandom);
      eg_io_wb_7_bits_exceptionVec_18 = 1'($urandom);
      eg_io_wb_7_bits_exceptionVec_19 = 1'($urandom);
      eg_io_wb_7_bits_exceptionVec_20 = 1'($urandom);
      eg_io_wb_7_bits_exceptionVec_21 = 1'($urandom);
      eg_io_wb_7_bits_exceptionVec_22 = 1'($urandom);
      eg_io_wb_7_bits_exceptionVec_23 = 1'($urandom);
      eg_io_wb_7_bits_flushPipe = 1'($urandom);
      eg_io_wb_7_bits_trigger = 4'($urandom);
      eg_io_wb_8_valid = 1'($urandom);
      eg_io_wb_8_bits_robIdx_flag = 1'($urandom);
      eg_io_wb_8_bits_robIdx_value = 8'($urandom);
      eg_io_wb_8_bits_hasException = 1'($urandom);
      eg_io_wb_8_bits_exceptionVec_0 = 1'($urandom);
      eg_io_wb_8_bits_exceptionVec_1 = 1'($urandom);
      eg_io_wb_8_bits_exceptionVec_2 = 1'($urandom);
      eg_io_wb_8_bits_exceptionVec_3 = 1'($urandom);
      eg_io_wb_8_bits_exceptionVec_4 = 1'($urandom);
      eg_io_wb_8_bits_exceptionVec_5 = 1'($urandom);
      eg_io_wb_8_bits_exceptionVec_6 = 1'($urandom);
      eg_io_wb_8_bits_exceptionVec_7 = 1'($urandom);
      eg_io_wb_8_bits_exceptionVec_8 = 1'($urandom);
      eg_io_wb_8_bits_exceptionVec_9 = 1'($urandom);
      eg_io_wb_8_bits_exceptionVec_10 = 1'($urandom);
      eg_io_wb_8_bits_exceptionVec_11 = 1'($urandom);
      eg_io_wb_8_bits_exceptionVec_12 = 1'($urandom);
      eg_io_wb_8_bits_exceptionVec_13 = 1'($urandom);
      eg_io_wb_8_bits_exceptionVec_14 = 1'($urandom);
      eg_io_wb_8_bits_exceptionVec_15 = 1'($urandom);
      eg_io_wb_8_bits_exceptionVec_16 = 1'($urandom);
      eg_io_wb_8_bits_exceptionVec_17 = 1'($urandom);
      eg_io_wb_8_bits_exceptionVec_18 = 1'($urandom);
      eg_io_wb_8_bits_exceptionVec_19 = 1'($urandom);
      eg_io_wb_8_bits_exceptionVec_20 = 1'($urandom);
      eg_io_wb_8_bits_exceptionVec_21 = 1'($urandom);
      eg_io_wb_8_bits_exceptionVec_22 = 1'($urandom);
      eg_io_wb_8_bits_exceptionVec_23 = 1'($urandom);
      eg_io_wb_8_bits_flushPipe = 1'($urandom);
      eg_io_wb_8_bits_replayInst = 1'($urandom);
      eg_io_wb_8_bits_trigger = 4'($urandom);
      eg_io_wb_9_valid = 1'($urandom);
      eg_io_wb_9_bits_robIdx_flag = 1'($urandom);
      eg_io_wb_9_bits_robIdx_value = 8'($urandom);
      eg_io_wb_9_bits_hasException = 1'($urandom);
      eg_io_wb_9_bits_exceptionVec_0 = 1'($urandom);
      eg_io_wb_9_bits_exceptionVec_1 = 1'($urandom);
      eg_io_wb_9_bits_exceptionVec_2 = 1'($urandom);
      eg_io_wb_9_bits_exceptionVec_3 = 1'($urandom);
      eg_io_wb_9_bits_exceptionVec_4 = 1'($urandom);
      eg_io_wb_9_bits_exceptionVec_5 = 1'($urandom);
      eg_io_wb_9_bits_exceptionVec_6 = 1'($urandom);
      eg_io_wb_9_bits_exceptionVec_7 = 1'($urandom);
      eg_io_wb_9_bits_exceptionVec_8 = 1'($urandom);
      eg_io_wb_9_bits_exceptionVec_9 = 1'($urandom);
      eg_io_wb_9_bits_exceptionVec_10 = 1'($urandom);
      eg_io_wb_9_bits_exceptionVec_11 = 1'($urandom);
      eg_io_wb_9_bits_exceptionVec_12 = 1'($urandom);
      eg_io_wb_9_bits_exceptionVec_13 = 1'($urandom);
      eg_io_wb_9_bits_exceptionVec_14 = 1'($urandom);
      eg_io_wb_9_bits_exceptionVec_15 = 1'($urandom);
      eg_io_wb_9_bits_exceptionVec_16 = 1'($urandom);
      eg_io_wb_9_bits_exceptionVec_17 = 1'($urandom);
      eg_io_wb_9_bits_exceptionVec_18 = 1'($urandom);
      eg_io_wb_9_bits_exceptionVec_19 = 1'($urandom);
      eg_io_wb_9_bits_exceptionVec_20 = 1'($urandom);
      eg_io_wb_9_bits_exceptionVec_21 = 1'($urandom);
      eg_io_wb_9_bits_exceptionVec_22 = 1'($urandom);
      eg_io_wb_9_bits_exceptionVec_23 = 1'($urandom);
      eg_io_wb_9_bits_flushPipe = 1'($urandom);
      eg_io_wb_9_bits_replayInst = 1'($urandom);
      eg_io_wb_9_bits_trigger = 4'($urandom);
      eg_io_wb_10_valid = 1'($urandom);
      eg_io_wb_10_bits_robIdx_flag = 1'($urandom);
      eg_io_wb_10_bits_robIdx_value = 8'($urandom);
      eg_io_wb_10_bits_hasException = 1'($urandom);
      eg_io_wb_10_bits_exceptionVec_0 = 1'($urandom);
      eg_io_wb_10_bits_exceptionVec_1 = 1'($urandom);
      eg_io_wb_10_bits_exceptionVec_2 = 1'($urandom);
      eg_io_wb_10_bits_exceptionVec_3 = 1'($urandom);
      eg_io_wb_10_bits_exceptionVec_4 = 1'($urandom);
      eg_io_wb_10_bits_exceptionVec_5 = 1'($urandom);
      eg_io_wb_10_bits_exceptionVec_6 = 1'($urandom);
      eg_io_wb_10_bits_exceptionVec_7 = 1'($urandom);
      eg_io_wb_10_bits_exceptionVec_8 = 1'($urandom);
      eg_io_wb_10_bits_exceptionVec_9 = 1'($urandom);
      eg_io_wb_10_bits_exceptionVec_10 = 1'($urandom);
      eg_io_wb_10_bits_exceptionVec_11 = 1'($urandom);
      eg_io_wb_10_bits_exceptionVec_12 = 1'($urandom);
      eg_io_wb_10_bits_exceptionVec_13 = 1'($urandom);
      eg_io_wb_10_bits_exceptionVec_14 = 1'($urandom);
      eg_io_wb_10_bits_exceptionVec_15 = 1'($urandom);
      eg_io_wb_10_bits_exceptionVec_16 = 1'($urandom);
      eg_io_wb_10_bits_exceptionVec_17 = 1'($urandom);
      eg_io_wb_10_bits_exceptionVec_18 = 1'($urandom);
      eg_io_wb_10_bits_exceptionVec_19 = 1'($urandom);
      eg_io_wb_10_bits_exceptionVec_20 = 1'($urandom);
      eg_io_wb_10_bits_exceptionVec_21 = 1'($urandom);
      eg_io_wb_10_bits_exceptionVec_22 = 1'($urandom);
      eg_io_wb_10_bits_exceptionVec_23 = 1'($urandom);
      eg_io_wb_10_bits_flushPipe = 1'($urandom);
      eg_io_wb_10_bits_replayInst = 1'($urandom);
      eg_io_wb_10_bits_trigger = 4'($urandom);
      eg_io_wb_11_valid = 1'($urandom);
      eg_io_wb_11_bits_robIdx_flag = 1'($urandom);
      eg_io_wb_11_bits_robIdx_value = 8'($urandom);
      eg_io_wb_11_bits_hasException = 1'($urandom);
      eg_io_wb_11_bits_exceptionVec_0 = 1'($urandom);
      eg_io_wb_11_bits_exceptionVec_1 = 1'($urandom);
      eg_io_wb_11_bits_exceptionVec_2 = 1'($urandom);
      eg_io_wb_11_bits_exceptionVec_3 = 1'($urandom);
      eg_io_wb_11_bits_exceptionVec_4 = 1'($urandom);
      eg_io_wb_11_bits_exceptionVec_5 = 1'($urandom);
      eg_io_wb_11_bits_exceptionVec_6 = 1'($urandom);
      eg_io_wb_11_bits_exceptionVec_7 = 1'($urandom);
      eg_io_wb_11_bits_exceptionVec_8 = 1'($urandom);
      eg_io_wb_11_bits_exceptionVec_9 = 1'($urandom);
      eg_io_wb_11_bits_exceptionVec_10 = 1'($urandom);
      eg_io_wb_11_bits_exceptionVec_11 = 1'($urandom);
      eg_io_wb_11_bits_exceptionVec_12 = 1'($urandom);
      eg_io_wb_11_bits_exceptionVec_13 = 1'($urandom);
      eg_io_wb_11_bits_exceptionVec_14 = 1'($urandom);
      eg_io_wb_11_bits_exceptionVec_15 = 1'($urandom);
      eg_io_wb_11_bits_exceptionVec_16 = 1'($urandom);
      eg_io_wb_11_bits_exceptionVec_17 = 1'($urandom);
      eg_io_wb_11_bits_exceptionVec_18 = 1'($urandom);
      eg_io_wb_11_bits_exceptionVec_19 = 1'($urandom);
      eg_io_wb_11_bits_exceptionVec_20 = 1'($urandom);
      eg_io_wb_11_bits_exceptionVec_21 = 1'($urandom);
      eg_io_wb_11_bits_exceptionVec_22 = 1'($urandom);
      eg_io_wb_11_bits_exceptionVec_23 = 1'($urandom);
      eg_io_wb_11_bits_flushPipe = 1'($urandom);
      eg_io_wb_11_bits_replayInst = 1'($urandom);
      eg_io_wb_11_bits_trigger = 4'($urandom);
      eg_io_wb_11_bits_vstartEn = 1'($urandom);
      eg_io_wb_11_bits_vstart = 64'({$urandom, $urandom});
      eg_io_wb_11_bits_vuopIdx = 7'($urandom);
      eg_io_wb_11_bits_isVecLoad = 1'($urandom);
      eg_io_wb_11_bits_isVlm = 1'($urandom);
      eg_io_wb_11_bits_isStrided = 1'($urandom);
      eg_io_wb_11_bits_isIndexed = 1'($urandom);
      eg_io_wb_11_bits_isWhole = 1'($urandom);
      eg_io_wb_11_bits_nf = 3'($urandom);
      eg_io_wb_11_bits_vsew = 2'($urandom);
      eg_io_wb_11_bits_veew = 2'($urandom);
      eg_io_wb_11_bits_vlmul = 3'($urandom);
      eg_io_wb_12_valid = 1'($urandom);
      eg_io_wb_12_bits_robIdx_flag = 1'($urandom);
      eg_io_wb_12_bits_robIdx_value = 8'($urandom);
      eg_io_wb_12_bits_hasException = 1'($urandom);
      eg_io_wb_12_bits_exceptionVec_0 = 1'($urandom);
      eg_io_wb_12_bits_exceptionVec_1 = 1'($urandom);
      eg_io_wb_12_bits_exceptionVec_2 = 1'($urandom);
      eg_io_wb_12_bits_exceptionVec_3 = 1'($urandom);
      eg_io_wb_12_bits_exceptionVec_4 = 1'($urandom);
      eg_io_wb_12_bits_exceptionVec_5 = 1'($urandom);
      eg_io_wb_12_bits_exceptionVec_6 = 1'($urandom);
      eg_io_wb_12_bits_exceptionVec_7 = 1'($urandom);
      eg_io_wb_12_bits_exceptionVec_8 = 1'($urandom);
      eg_io_wb_12_bits_exceptionVec_9 = 1'($urandom);
      eg_io_wb_12_bits_exceptionVec_10 = 1'($urandom);
      eg_io_wb_12_bits_exceptionVec_11 = 1'($urandom);
      eg_io_wb_12_bits_exceptionVec_12 = 1'($urandom);
      eg_io_wb_12_bits_exceptionVec_13 = 1'($urandom);
      eg_io_wb_12_bits_exceptionVec_14 = 1'($urandom);
      eg_io_wb_12_bits_exceptionVec_15 = 1'($urandom);
      eg_io_wb_12_bits_exceptionVec_16 = 1'($urandom);
      eg_io_wb_12_bits_exceptionVec_17 = 1'($urandom);
      eg_io_wb_12_bits_exceptionVec_18 = 1'($urandom);
      eg_io_wb_12_bits_exceptionVec_19 = 1'($urandom);
      eg_io_wb_12_bits_exceptionVec_20 = 1'($urandom);
      eg_io_wb_12_bits_exceptionVec_21 = 1'($urandom);
      eg_io_wb_12_bits_exceptionVec_22 = 1'($urandom);
      eg_io_wb_12_bits_exceptionVec_23 = 1'($urandom);
      eg_io_wb_12_bits_flushPipe = 1'($urandom);
      eg_io_wb_12_bits_replayInst = 1'($urandom);
      eg_io_wb_12_bits_trigger = 4'($urandom);
      eg_io_wb_12_bits_vstartEn = 1'($urandom);
      eg_io_wb_12_bits_vstart = 64'({$urandom, $urandom});
      eg_io_wb_12_bits_vuopIdx = 7'($urandom);
      eg_io_wb_12_bits_isVecLoad = 1'($urandom);
      eg_io_wb_12_bits_isVlm = 1'($urandom);
      eg_io_wb_12_bits_isStrided = 1'($urandom);
      eg_io_wb_12_bits_isIndexed = 1'($urandom);
      eg_io_wb_12_bits_isWhole = 1'($urandom);
      eg_io_wb_12_bits_nf = 3'($urandom);
      eg_io_wb_12_bits_vsew = 2'($urandom);
      eg_io_wb_12_bits_veew = 2'($urandom);
      eg_io_wb_12_bits_vlmul = 3'($urandom);
      eg_reset = (cyc < RESET_CYC) || ($urandom_range(0, 19999) == 0);
      begin : stim_eg
        if ($urandom_range(0, 999) == 0) begin eg_win_flag = $urandom; eg_win_base = $urandom; end
        eg_io_flush = (cyc < RESET_CYC + 3) || ($urandom_range(0, 63) == 0);
        eg_io_redirect_valid = ($urandom_range(0, 7) == 0);
        {eg_io_redirect_bits_robIdx_flag, eg_io_redirect_bits_robIdx_value} = eg_rob();
        eg_io_enq_0_valid = ($urandom_range(0, 2) == 0);
        {eg_io_enq_0_bits_robIdx_flag, eg_io_enq_0_bits_robIdx_value} = eg_rob();
        eg_io_enq_0_bits_hasException = ($urandom_range(0, 2) == 0);
        eg_io_enq_0_bits_exceptionVec_0 = ($urandom_range(0, 3) == 0);
        eg_io_enq_0_bits_exceptionVec_1 = ($urandom_range(0, 3) == 0);
        eg_io_enq_0_bits_exceptionVec_2 = ($urandom_range(0, 3) == 0);
        eg_io_enq_0_bits_exceptionVec_3 = ($urandom_range(0, 3) == 0);
        eg_io_enq_0_bits_exceptionVec_12 = ($urandom_range(0, 3) == 0);
        eg_io_enq_0_bits_exceptionVec_20 = ($urandom_range(0, 3) == 0);
        eg_io_enq_0_bits_exceptionVec_22 = ($urandom_range(0, 3) == 0);
        eg_io_enq_0_bits_flushPipe = ($urandom_range(0, 7) == 0);
        eg_io_enq_0_bits_singleStep = ($urandom_range(0, 7) == 0);
        eg_io_enq_0_bits_trigger = ($urandom_range(0, 7) == 0) ? 4'h1 : 4'($urandom);
        eg_io_enq_1_valid = ($urandom_range(0, 2) == 0);
        {eg_io_enq_1_bits_robIdx_flag, eg_io_enq_1_bits_robIdx_value} = eg_rob();
        eg_io_enq_1_bits_hasException = ($urandom_range(0, 2) == 0);
        eg_io_enq_1_bits_exceptionVec_0 = ($urandom_range(0, 3) == 0);
        eg_io_enq_1_bits_exceptionVec_1 = ($urandom_range(0, 3) == 0);
        eg_io_enq_1_bits_exceptionVec_2 = ($urandom_range(0, 3) == 0);
        eg_io_enq_1_bits_exceptionVec_3 = ($urandom_range(0, 3) == 0);
        eg_io_enq_1_bits_exceptionVec_12 = ($urandom_range(0, 3) == 0);
        eg_io_enq_1_bits_exceptionVec_20 = ($urandom_range(0, 3) == 0);
        eg_io_enq_1_bits_exceptionVec_22 = ($urandom_range(0, 3) == 0);
        eg_io_enq_1_bits_flushPipe = ($urandom_range(0, 7) == 0);
        eg_io_enq_1_bits_singleStep = ($urandom_range(0, 7) == 0);
        eg_io_enq_1_bits_trigger = ($urandom_range(0, 7) == 0) ? 4'h1 : 4'($urandom);
        eg_io_enq_2_valid = ($urandom_range(0, 2) == 0);
        {eg_io_enq_2_bits_robIdx_flag, eg_io_enq_2_bits_robIdx_value} = eg_rob();
        eg_io_enq_2_bits_hasException = ($urandom_range(0, 2) == 0);
        eg_io_enq_2_bits_exceptionVec_0 = ($urandom_range(0, 3) == 0);
        eg_io_enq_2_bits_exceptionVec_1 = ($urandom_range(0, 3) == 0);
        eg_io_enq_2_bits_exceptionVec_2 = ($urandom_range(0, 3) == 0);
        eg_io_enq_2_bits_exceptionVec_3 = ($urandom_range(0, 3) == 0);
        eg_io_enq_2_bits_exceptionVec_12 = ($urandom_range(0, 3) == 0);
        eg_io_enq_2_bits_exceptionVec_20 = ($urandom_range(0, 3) == 0);
        eg_io_enq_2_bits_exceptionVec_22 = ($urandom_range(0, 3) == 0);
        eg_io_enq_2_bits_flushPipe = ($urandom_range(0, 7) == 0);
        eg_io_enq_2_bits_singleStep = ($urandom_range(0, 7) == 0);
        eg_io_enq_2_bits_trigger = ($urandom_range(0, 7) == 0) ? 4'h1 : 4'($urandom);
        eg_io_enq_3_valid = ($urandom_range(0, 2) == 0);
        {eg_io_enq_3_bits_robIdx_flag, eg_io_enq_3_bits_robIdx_value} = eg_rob();
        eg_io_enq_3_bits_hasException = ($urandom_range(0, 2) == 0);
        eg_io_enq_3_bits_exceptionVec_0 = ($urandom_range(0, 3) == 0);
        eg_io_enq_3_bits_exceptionVec_1 = ($urandom_range(0, 3) == 0);
        eg_io_enq_3_bits_exceptionVec_2 = ($urandom_range(0, 3) == 0);
        eg_io_enq_3_bits_exceptionVec_3 = ($urandom_range(0, 3) == 0);
        eg_io_enq_3_bits_exceptionVec_12 = ($urandom_range(0, 3) == 0);
        eg_io_enq_3_bits_exceptionVec_20 = ($urandom_range(0, 3) == 0);
        eg_io_enq_3_bits_exceptionVec_22 = ($urandom_range(0, 3) == 0);
        eg_io_enq_3_bits_flushPipe = ($urandom_range(0, 7) == 0);
        eg_io_enq_3_bits_singleStep = ($urandom_range(0, 7) == 0);
        eg_io_enq_3_bits_trigger = ($urandom_range(0, 7) == 0) ? 4'h1 : 4'($urandom);
        eg_io_enq_4_valid = ($urandom_range(0, 2) == 0);
        {eg_io_enq_4_bits_robIdx_flag, eg_io_enq_4_bits_robIdx_value} = eg_rob();
        eg_io_enq_4_bits_hasException = ($urandom_range(0, 2) == 0);
        eg_io_enq_4_bits_exceptionVec_0 = ($urandom_range(0, 3) == 0);
        eg_io_enq_4_bits_exceptionVec_1 = ($urandom_range(0, 3) == 0);
        eg_io_enq_4_bits_exceptionVec_2 = ($urandom_range(0, 3) == 0);
        eg_io_enq_4_bits_exceptionVec_3 = ($urandom_range(0, 3) == 0);
        eg_io_enq_4_bits_exceptionVec_12 = ($urandom_range(0, 3) == 0);
        eg_io_enq_4_bits_exceptionVec_20 = ($urandom_range(0, 3) == 0);
        eg_io_enq_4_bits_exceptionVec_22 = ($urandom_range(0, 3) == 0);
        eg_io_enq_4_bits_flushPipe = ($urandom_range(0, 7) == 0);
        eg_io_enq_4_bits_singleStep = ($urandom_range(0, 7) == 0);
        eg_io_enq_4_bits_trigger = ($urandom_range(0, 7) == 0) ? 4'h1 : 4'($urandom);
        eg_io_enq_5_valid = ($urandom_range(0, 2) == 0);
        {eg_io_enq_5_bits_robIdx_flag, eg_io_enq_5_bits_robIdx_value} = eg_rob();
        eg_io_enq_5_bits_hasException = ($urandom_range(0, 2) == 0);
        eg_io_enq_5_bits_exceptionVec_0 = ($urandom_range(0, 3) == 0);
        eg_io_enq_5_bits_exceptionVec_1 = ($urandom_range(0, 3) == 0);
        eg_io_enq_5_bits_exceptionVec_2 = ($urandom_range(0, 3) == 0);
        eg_io_enq_5_bits_exceptionVec_3 = ($urandom_range(0, 3) == 0);
        eg_io_enq_5_bits_exceptionVec_12 = ($urandom_range(0, 3) == 0);
        eg_io_enq_5_bits_exceptionVec_20 = ($urandom_range(0, 3) == 0);
        eg_io_enq_5_bits_exceptionVec_22 = ($urandom_range(0, 3) == 0);
        eg_io_enq_5_bits_flushPipe = ($urandom_range(0, 7) == 0);
        eg_io_enq_5_bits_singleStep = ($urandom_range(0, 7) == 0);
        eg_io_enq_5_bits_trigger = ($urandom_range(0, 7) == 0) ? 4'h1 : 4'($urandom);
        eg_io_wb_0_valid = ($urandom_range(0, 2) == 0);
        {eg_io_wb_0_bits_robIdx_flag, eg_io_wb_0_bits_robIdx_value} = eg_rob();
        eg_io_wb_0_bits_hasException = ($urandom_range(0, 2) == 0);
        eg_io_wb_0_bits_exceptionVec_2 = ($urandom_range(0, 3) == 0);
        eg_io_wb_0_bits_exceptionVec_3 = ($urandom_range(0, 3) == 0);
        eg_io_wb_0_bits_exceptionVec_8 = ($urandom_range(0, 3) == 0);
        eg_io_wb_0_bits_exceptionVec_9 = ($urandom_range(0, 3) == 0);
        eg_io_wb_0_bits_exceptionVec_10 = ($urandom_range(0, 3) == 0);
        eg_io_wb_0_bits_exceptionVec_11 = ($urandom_range(0, 3) == 0);
        eg_io_wb_0_bits_exceptionVec_22 = ($urandom_range(0, 3) == 0);
        eg_io_wb_0_bits_flushPipe = ($urandom_range(0, 7) == 0);
        eg_io_wb_0_bits_satpFlushPipe = ($urandom_range(0, 7) == 0);
        eg_io_wb_1_valid = ($urandom_range(0, 2) == 0);
        {eg_io_wb_1_bits_robIdx_flag, eg_io_wb_1_bits_robIdx_value} = eg_rob();
        eg_io_wb_1_bits_hasException = ($urandom_range(0, 2) == 0);
        eg_io_wb_1_bits_exceptionVec_2 = ($urandom_range(0, 3) == 0);
        eg_io_wb_2_valid = ($urandom_range(0, 2) == 0);
        {eg_io_wb_2_bits_robIdx_flag, eg_io_wb_2_bits_robIdx_value} = eg_rob();
        eg_io_wb_2_bits_hasException = ($urandom_range(0, 2) == 0);
        eg_io_wb_2_bits_exceptionVec_2 = ($urandom_range(0, 3) == 0);
        {eg_io_wb_3_bits_robIdx_flag, eg_io_wb_3_bits_robIdx_value} = eg_rob();
        {eg_io_wb_4_bits_robIdx_flag, eg_io_wb_4_bits_robIdx_value} = eg_rob();
        {eg_io_wb_5_bits_robIdx_flag, eg_io_wb_5_bits_robIdx_value} = eg_rob();
        eg_io_wb_6_valid = ($urandom_range(0, 2) == 0);
        {eg_io_wb_6_bits_robIdx_flag, eg_io_wb_6_bits_robIdx_value} = eg_rob();
        eg_io_wb_6_bits_hasException = ($urandom_range(0, 2) == 0);
        eg_io_wb_6_bits_exceptionVec_0 = ($urandom_range(0, 3) == 0);
        eg_io_wb_6_bits_exceptionVec_1 = ($urandom_range(0, 3) == 0);
        eg_io_wb_6_bits_exceptionVec_2 = ($urandom_range(0, 3) == 0);
        eg_io_wb_6_bits_exceptionVec_3 = ($urandom_range(0, 3) == 0);
        eg_io_wb_6_bits_exceptionVec_4 = ($urandom_range(0, 3) == 0);
        eg_io_wb_6_bits_exceptionVec_5 = ($urandom_range(0, 3) == 0);
        eg_io_wb_6_bits_exceptionVec_6 = ($urandom_range(0, 3) == 0);
        eg_io_wb_6_bits_exceptionVec_7 = ($urandom_range(0, 3) == 0);
        eg_io_wb_6_bits_exceptionVec_8 = ($urandom_range(0, 3) == 0);
        eg_io_wb_6_bits_exceptionVec_9 = ($urandom_range(0, 3) == 0);
        eg_io_wb_6_bits_exceptionVec_10 = ($urandom_range(0, 3) == 0);
        eg_io_wb_6_bits_exceptionVec_11 = ($urandom_range(0, 3) == 0);
        eg_io_wb_6_bits_exceptionVec_12 = ($urandom_range(0, 3) == 0);
        eg_io_wb_6_bits_exceptionVec_13 = ($urandom_range(0, 3) == 0);
        eg_io_wb_6_bits_exceptionVec_14 = ($urandom_range(0, 3) == 0);
        eg_io_wb_6_bits_exceptionVec_15 = ($urandom_range(0, 3) == 0);
        eg_io_wb_6_bits_exceptionVec_16 = ($urandom_range(0, 3) == 0);
        eg_io_wb_6_bits_exceptionVec_17 = ($urandom_range(0, 3) == 0);
        eg_io_wb_6_bits_exceptionVec_18 = ($urandom_range(0, 3) == 0);
        eg_io_wb_6_bits_exceptionVec_19 = ($urandom_range(0, 3) == 0);
        eg_io_wb_6_bits_exceptionVec_20 = ($urandom_range(0, 3) == 0);
        eg_io_wb_6_bits_exceptionVec_21 = ($urandom_range(0, 3) == 0);
        eg_io_wb_6_bits_exceptionVec_22 = ($urandom_range(0, 3) == 0);
        eg_io_wb_6_bits_exceptionVec_23 = ($urandom_range(0, 3) == 0);
        eg_io_wb_6_bits_flushPipe = ($urandom_range(0, 7) == 0);
        eg_io_wb_6_bits_trigger = ($urandom_range(0, 7) == 0) ? 4'h1 : 4'($urandom);
        eg_io_wb_7_valid = ($urandom_range(0, 2) == 0);
        {eg_io_wb_7_bits_robIdx_flag, eg_io_wb_7_bits_robIdx_value} = eg_rob();
        eg_io_wb_7_bits_hasException = ($urandom_range(0, 2) == 0);
        eg_io_wb_7_bits_exceptionVec_0 = ($urandom_range(0, 3) == 0);
        eg_io_wb_7_bits_exceptionVec_1 = ($urandom_range(0, 3) == 0);
        eg_io_wb_7_bits_exceptionVec_2 = ($urandom_range(0, 3) == 0);
        eg_io_wb_7_bits_exceptionVec_3 = ($urandom_range(0, 3) == 0);
        eg_io_wb_7_bits_exceptionVec_4 = ($urandom_range(0, 3) == 0);
        eg_io_wb_7_bits_exceptionVec_5 = ($urandom_range(0, 3) == 0);
        eg_io_wb_7_bits_exceptionVec_6 = ($urandom_range(0, 3) == 0);
        eg_io_wb_7_bits_exceptionVec_7 = ($urandom_range(0, 3) == 0);
        eg_io_wb_7_bits_exceptionVec_8 = ($urandom_range(0, 3) == 0);
        eg_io_wb_7_bits_exceptionVec_9 = ($urandom_range(0, 3) == 0);
        eg_io_wb_7_bits_exceptionVec_10 = ($urandom_range(0, 3) == 0);
        eg_io_wb_7_bits_exceptionVec_11 = ($urandom_range(0, 3) == 0);
        eg_io_wb_7_bits_exceptionVec_12 = ($urandom_range(0, 3) == 0);
        eg_io_wb_7_bits_exceptionVec_13 = ($urandom_range(0, 3) == 0);
        eg_io_wb_7_bits_exceptionVec_14 = ($urandom_range(0, 3) == 0);
        eg_io_wb_7_bits_exceptionVec_15 = ($urandom_range(0, 3) == 0);
        eg_io_wb_7_bits_exceptionVec_16 = ($urandom_range(0, 3) == 0);
        eg_io_wb_7_bits_exceptionVec_17 = ($urandom_range(0, 3) == 0);
        eg_io_wb_7_bits_exceptionVec_18 = ($urandom_range(0, 3) == 0);
        eg_io_wb_7_bits_exceptionVec_19 = ($urandom_range(0, 3) == 0);
        eg_io_wb_7_bits_exceptionVec_20 = ($urandom_range(0, 3) == 0);
        eg_io_wb_7_bits_exceptionVec_21 = ($urandom_range(0, 3) == 0);
        eg_io_wb_7_bits_exceptionVec_22 = ($urandom_range(0, 3) == 0);
        eg_io_wb_7_bits_exceptionVec_23 = ($urandom_range(0, 3) == 0);
        eg_io_wb_7_bits_flushPipe = ($urandom_range(0, 7) == 0);
        eg_io_wb_7_bits_trigger = ($urandom_range(0, 7) == 0) ? 4'h1 : 4'($urandom);
        eg_io_wb_8_valid = ($urandom_range(0, 2) == 0);
        {eg_io_wb_8_bits_robIdx_flag, eg_io_wb_8_bits_robIdx_value} = eg_rob();
        eg_io_wb_8_bits_hasException = ($urandom_range(0, 2) == 0);
        eg_io_wb_8_bits_exceptionVec_0 = ($urandom_range(0, 3) == 0);
        eg_io_wb_8_bits_exceptionVec_1 = ($urandom_range(0, 3) == 0);
        eg_io_wb_8_bits_exceptionVec_2 = ($urandom_range(0, 3) == 0);
        eg_io_wb_8_bits_exceptionVec_3 = ($urandom_range(0, 3) == 0);
        eg_io_wb_8_bits_exceptionVec_4 = ($urandom_range(0, 3) == 0);
        eg_io_wb_8_bits_exceptionVec_5 = ($urandom_range(0, 3) == 0);
        eg_io_wb_8_bits_exceptionVec_6 = ($urandom_range(0, 3) == 0);
        eg_io_wb_8_bits_exceptionVec_7 = ($urandom_range(0, 3) == 0);
        eg_io_wb_8_bits_exceptionVec_8 = ($urandom_range(0, 3) == 0);
        eg_io_wb_8_bits_exceptionVec_9 = ($urandom_range(0, 3) == 0);
        eg_io_wb_8_bits_exceptionVec_10 = ($urandom_range(0, 3) == 0);
        eg_io_wb_8_bits_exceptionVec_11 = ($urandom_range(0, 3) == 0);
        eg_io_wb_8_bits_exceptionVec_12 = ($urandom_range(0, 3) == 0);
        eg_io_wb_8_bits_exceptionVec_13 = ($urandom_range(0, 3) == 0);
        eg_io_wb_8_bits_exceptionVec_14 = ($urandom_range(0, 3) == 0);
        eg_io_wb_8_bits_exceptionVec_15 = ($urandom_range(0, 3) == 0);
        eg_io_wb_8_bits_exceptionVec_16 = ($urandom_range(0, 3) == 0);
        eg_io_wb_8_bits_exceptionVec_17 = ($urandom_range(0, 3) == 0);
        eg_io_wb_8_bits_exceptionVec_18 = ($urandom_range(0, 3) == 0);
        eg_io_wb_8_bits_exceptionVec_19 = ($urandom_range(0, 3) == 0);
        eg_io_wb_8_bits_exceptionVec_20 = ($urandom_range(0, 3) == 0);
        eg_io_wb_8_bits_exceptionVec_21 = ($urandom_range(0, 3) == 0);
        eg_io_wb_8_bits_exceptionVec_22 = ($urandom_range(0, 3) == 0);
        eg_io_wb_8_bits_exceptionVec_23 = ($urandom_range(0, 3) == 0);
        eg_io_wb_8_bits_flushPipe = ($urandom_range(0, 7) == 0);
        eg_io_wb_8_bits_replayInst = ($urandom_range(0, 7) == 0);
        eg_io_wb_8_bits_trigger = ($urandom_range(0, 7) == 0) ? 4'h1 : 4'($urandom);
        eg_io_wb_9_valid = ($urandom_range(0, 2) == 0);
        {eg_io_wb_9_bits_robIdx_flag, eg_io_wb_9_bits_robIdx_value} = eg_rob();
        eg_io_wb_9_bits_hasException = ($urandom_range(0, 2) == 0);
        eg_io_wb_9_bits_exceptionVec_0 = ($urandom_range(0, 3) == 0);
        eg_io_wb_9_bits_exceptionVec_1 = ($urandom_range(0, 3) == 0);
        eg_io_wb_9_bits_exceptionVec_2 = ($urandom_range(0, 3) == 0);
        eg_io_wb_9_bits_exceptionVec_3 = ($urandom_range(0, 3) == 0);
        eg_io_wb_9_bits_exceptionVec_4 = ($urandom_range(0, 3) == 0);
        eg_io_wb_9_bits_exceptionVec_5 = ($urandom_range(0, 3) == 0);
        eg_io_wb_9_bits_exceptionVec_6 = ($urandom_range(0, 3) == 0);
        eg_io_wb_9_bits_exceptionVec_7 = ($urandom_range(0, 3) == 0);
        eg_io_wb_9_bits_exceptionVec_8 = ($urandom_range(0, 3) == 0);
        eg_io_wb_9_bits_exceptionVec_9 = ($urandom_range(0, 3) == 0);
        eg_io_wb_9_bits_exceptionVec_10 = ($urandom_range(0, 3) == 0);
        eg_io_wb_9_bits_exceptionVec_11 = ($urandom_range(0, 3) == 0);
        eg_io_wb_9_bits_exceptionVec_12 = ($urandom_range(0, 3) == 0);
        eg_io_wb_9_bits_exceptionVec_13 = ($urandom_range(0, 3) == 0);
        eg_io_wb_9_bits_exceptionVec_14 = ($urandom_range(0, 3) == 0);
        eg_io_wb_9_bits_exceptionVec_15 = ($urandom_range(0, 3) == 0);
        eg_io_wb_9_bits_exceptionVec_16 = ($urandom_range(0, 3) == 0);
        eg_io_wb_9_bits_exceptionVec_17 = ($urandom_range(0, 3) == 0);
        eg_io_wb_9_bits_exceptionVec_18 = ($urandom_range(0, 3) == 0);
        eg_io_wb_9_bits_exceptionVec_19 = ($urandom_range(0, 3) == 0);
        eg_io_wb_9_bits_exceptionVec_20 = ($urandom_range(0, 3) == 0);
        eg_io_wb_9_bits_exceptionVec_21 = ($urandom_range(0, 3) == 0);
        eg_io_wb_9_bits_exceptionVec_22 = ($urandom_range(0, 3) == 0);
        eg_io_wb_9_bits_exceptionVec_23 = ($urandom_range(0, 3) == 0);
        eg_io_wb_9_bits_flushPipe = ($urandom_range(0, 7) == 0);
        eg_io_wb_9_bits_replayInst = ($urandom_range(0, 7) == 0);
        eg_io_wb_9_bits_trigger = ($urandom_range(0, 7) == 0) ? 4'h1 : 4'($urandom);
        eg_io_wb_10_valid = ($urandom_range(0, 2) == 0);
        {eg_io_wb_10_bits_robIdx_flag, eg_io_wb_10_bits_robIdx_value} = eg_rob();
        eg_io_wb_10_bits_hasException = ($urandom_range(0, 2) == 0);
        eg_io_wb_10_bits_exceptionVec_0 = ($urandom_range(0, 3) == 0);
        eg_io_wb_10_bits_exceptionVec_1 = ($urandom_range(0, 3) == 0);
        eg_io_wb_10_bits_exceptionVec_2 = ($urandom_range(0, 3) == 0);
        eg_io_wb_10_bits_exceptionVec_3 = ($urandom_range(0, 3) == 0);
        eg_io_wb_10_bits_exceptionVec_4 = ($urandom_range(0, 3) == 0);
        eg_io_wb_10_bits_exceptionVec_5 = ($urandom_range(0, 3) == 0);
        eg_io_wb_10_bits_exceptionVec_6 = ($urandom_range(0, 3) == 0);
        eg_io_wb_10_bits_exceptionVec_7 = ($urandom_range(0, 3) == 0);
        eg_io_wb_10_bits_exceptionVec_8 = ($urandom_range(0, 3) == 0);
        eg_io_wb_10_bits_exceptionVec_9 = ($urandom_range(0, 3) == 0);
        eg_io_wb_10_bits_exceptionVec_10 = ($urandom_range(0, 3) == 0);
        eg_io_wb_10_bits_exceptionVec_11 = ($urandom_range(0, 3) == 0);
        eg_io_wb_10_bits_exceptionVec_12 = ($urandom_range(0, 3) == 0);
        eg_io_wb_10_bits_exceptionVec_13 = ($urandom_range(0, 3) == 0);
        eg_io_wb_10_bits_exceptionVec_14 = ($urandom_range(0, 3) == 0);
        eg_io_wb_10_bits_exceptionVec_15 = ($urandom_range(0, 3) == 0);
        eg_io_wb_10_bits_exceptionVec_16 = ($urandom_range(0, 3) == 0);
        eg_io_wb_10_bits_exceptionVec_17 = ($urandom_range(0, 3) == 0);
        eg_io_wb_10_bits_exceptionVec_18 = ($urandom_range(0, 3) == 0);
        eg_io_wb_10_bits_exceptionVec_19 = ($urandom_range(0, 3) == 0);
        eg_io_wb_10_bits_exceptionVec_20 = ($urandom_range(0, 3) == 0);
        eg_io_wb_10_bits_exceptionVec_21 = ($urandom_range(0, 3) == 0);
        eg_io_wb_10_bits_exceptionVec_22 = ($urandom_range(0, 3) == 0);
        eg_io_wb_10_bits_exceptionVec_23 = ($urandom_range(0, 3) == 0);
        eg_io_wb_10_bits_flushPipe = ($urandom_range(0, 7) == 0);
        eg_io_wb_10_bits_replayInst = ($urandom_range(0, 7) == 0);
        eg_io_wb_10_bits_trigger = ($urandom_range(0, 7) == 0) ? 4'h1 : 4'($urandom);
        eg_io_wb_11_valid = ($urandom_range(0, 2) == 0);
        {eg_io_wb_11_bits_robIdx_flag, eg_io_wb_11_bits_robIdx_value} = eg_rob();
        eg_io_wb_11_bits_hasException = ($urandom_range(0, 2) == 0);
        eg_io_wb_11_bits_exceptionVec_0 = ($urandom_range(0, 3) == 0);
        eg_io_wb_11_bits_exceptionVec_1 = ($urandom_range(0, 3) == 0);
        eg_io_wb_11_bits_exceptionVec_2 = ($urandom_range(0, 3) == 0);
        eg_io_wb_11_bits_exceptionVec_3 = ($urandom_range(0, 3) == 0);
        eg_io_wb_11_bits_exceptionVec_4 = ($urandom_range(0, 3) == 0);
        eg_io_wb_11_bits_exceptionVec_5 = ($urandom_range(0, 3) == 0);
        eg_io_wb_11_bits_exceptionVec_6 = ($urandom_range(0, 3) == 0);
        eg_io_wb_11_bits_exceptionVec_7 = ($urandom_range(0, 3) == 0);
        eg_io_wb_11_bits_exceptionVec_8 = ($urandom_range(0, 3) == 0);
        eg_io_wb_11_bits_exceptionVec_9 = ($urandom_range(0, 3) == 0);
        eg_io_wb_11_bits_exceptionVec_10 = ($urandom_range(0, 3) == 0);
        eg_io_wb_11_bits_exceptionVec_11 = ($urandom_range(0, 3) == 0);
        eg_io_wb_11_bits_exceptionVec_12 = ($urandom_range(0, 3) == 0);
        eg_io_wb_11_bits_exceptionVec_13 = ($urandom_range(0, 3) == 0);
        eg_io_wb_11_bits_exceptionVec_14 = ($urandom_range(0, 3) == 0);
        eg_io_wb_11_bits_exceptionVec_15 = ($urandom_range(0, 3) == 0);
        eg_io_wb_11_bits_exceptionVec_16 = ($urandom_range(0, 3) == 0);
        eg_io_wb_11_bits_exceptionVec_17 = ($urandom_range(0, 3) == 0);
        eg_io_wb_11_bits_exceptionVec_18 = ($urandom_range(0, 3) == 0);
        eg_io_wb_11_bits_exceptionVec_19 = ($urandom_range(0, 3) == 0);
        eg_io_wb_11_bits_exceptionVec_20 = ($urandom_range(0, 3) == 0);
        eg_io_wb_11_bits_exceptionVec_21 = ($urandom_range(0, 3) == 0);
        eg_io_wb_11_bits_exceptionVec_22 = ($urandom_range(0, 3) == 0);
        eg_io_wb_11_bits_exceptionVec_23 = ($urandom_range(0, 3) == 0);
        eg_io_wb_11_bits_flushPipe = ($urandom_range(0, 7) == 0);
        eg_io_wb_11_bits_replayInst = ($urandom_range(0, 7) == 0);
        eg_io_wb_11_bits_trigger = ($urandom_range(0, 7) == 0) ? 4'h1 : 4'($urandom);
        eg_io_wb_11_bits_vstart = ($urandom_range(0, 3) == 0) ? {$urandom, $urandom} : 64'($urandom_range(0, 7));
        eg_io_wb_11_bits_vuopIdx = ($urandom_range(0, 3) == 0) ? 7'($urandom) : 7'($urandom_range(0, 3));
        eg_io_wb_12_valid = ($urandom_range(0, 2) == 0);
        {eg_io_wb_12_bits_robIdx_flag, eg_io_wb_12_bits_robIdx_value} = eg_rob();
        eg_io_wb_12_bits_hasException = ($urandom_range(0, 2) == 0);
        eg_io_wb_12_bits_exceptionVec_0 = ($urandom_range(0, 3) == 0);
        eg_io_wb_12_bits_exceptionVec_1 = ($urandom_range(0, 3) == 0);
        eg_io_wb_12_bits_exceptionVec_2 = ($urandom_range(0, 3) == 0);
        eg_io_wb_12_bits_exceptionVec_3 = ($urandom_range(0, 3) == 0);
        eg_io_wb_12_bits_exceptionVec_4 = ($urandom_range(0, 3) == 0);
        eg_io_wb_12_bits_exceptionVec_5 = ($urandom_range(0, 3) == 0);
        eg_io_wb_12_bits_exceptionVec_6 = ($urandom_range(0, 3) == 0);
        eg_io_wb_12_bits_exceptionVec_7 = ($urandom_range(0, 3) == 0);
        eg_io_wb_12_bits_exceptionVec_8 = ($urandom_range(0, 3) == 0);
        eg_io_wb_12_bits_exceptionVec_9 = ($urandom_range(0, 3) == 0);
        eg_io_wb_12_bits_exceptionVec_10 = ($urandom_range(0, 3) == 0);
        eg_io_wb_12_bits_exceptionVec_11 = ($urandom_range(0, 3) == 0);
        eg_io_wb_12_bits_exceptionVec_12 = ($urandom_range(0, 3) == 0);
        eg_io_wb_12_bits_exceptionVec_13 = ($urandom_range(0, 3) == 0);
        eg_io_wb_12_bits_exceptionVec_14 = ($urandom_range(0, 3) == 0);
        eg_io_wb_12_bits_exceptionVec_15 = ($urandom_range(0, 3) == 0);
        eg_io_wb_12_bits_exceptionVec_16 = ($urandom_range(0, 3) == 0);
        eg_io_wb_12_bits_exceptionVec_17 = ($urandom_range(0, 3) == 0);
        eg_io_wb_12_bits_exceptionVec_18 = ($urandom_range(0, 3) == 0);
        eg_io_wb_12_bits_exceptionVec_19 = ($urandom_range(0, 3) == 0);
        eg_io_wb_12_bits_exceptionVec_20 = ($urandom_range(0, 3) == 0);
        eg_io_wb_12_bits_exceptionVec_21 = ($urandom_range(0, 3) == 0);
        eg_io_wb_12_bits_exceptionVec_22 = ($urandom_range(0, 3) == 0);
        eg_io_wb_12_bits_exceptionVec_23 = ($urandom_range(0, 3) == 0);
        eg_io_wb_12_bits_flushPipe = ($urandom_range(0, 7) == 0);
        eg_io_wb_12_bits_replayInst = ($urandom_range(0, 7) == 0);
        eg_io_wb_12_bits_trigger = ($urandom_range(0, 7) == 0) ? 4'h1 : 4'($urandom);
        eg_io_wb_12_bits_vstart = ($urandom_range(0, 3) == 0) ? {$urandom, $urandom} : 64'($urandom_range(0, 7));
        eg_io_wb_12_bits_vuopIdx = ($urandom_range(0, 3) == 0) ? 7'($urandom) : 7'($urandom_range(0, 3));
      end
      #4;
      if (cyc >= RESET_CYC + 0 && (&eg_armed)) begin
        checks++;
        if (eg_g_io_state_valid !== eg_i_io_state_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_valid g=%h i=%h", cyc, eg_g_io_state_valid, eg_i_io_state_valid);
        end
        eg_s1_io_state_valid |= eg_g_io_state_valid;
        eg_s0_io_state_valid |= ~eg_g_io_state_valid;
        checks++;
        if (eg_g_io_state_bits_robIdx_flag !== eg_i_io_state_bits_robIdx_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_robIdx_flag g=%h i=%h", cyc, eg_g_io_state_bits_robIdx_flag, eg_i_io_state_bits_robIdx_flag);
        end
        eg_s1_io_state_bits_robIdx_flag |= eg_g_io_state_bits_robIdx_flag;
        eg_s0_io_state_bits_robIdx_flag |= ~eg_g_io_state_bits_robIdx_flag;
        checks++;
        if (eg_g_io_state_bits_robIdx_value !== eg_i_io_state_bits_robIdx_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_robIdx_value g=%h i=%h", cyc, eg_g_io_state_bits_robIdx_value, eg_i_io_state_bits_robIdx_value);
        end
        eg_s1_io_state_bits_robIdx_value |= eg_g_io_state_bits_robIdx_value;
        eg_s0_io_state_bits_robIdx_value |= ~eg_g_io_state_bits_robIdx_value;
        checks++;
        if (eg_g_io_state_bits_ftqPtr_value !== eg_i_io_state_bits_ftqPtr_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_ftqPtr_value g=%h i=%h", cyc, eg_g_io_state_bits_ftqPtr_value, eg_i_io_state_bits_ftqPtr_value);
        end
        eg_s1_io_state_bits_ftqPtr_value |= eg_g_io_state_bits_ftqPtr_value;
        eg_s0_io_state_bits_ftqPtr_value |= ~eg_g_io_state_bits_ftqPtr_value;
        checks++;
        if (eg_g_io_state_bits_ftqOffset !== eg_i_io_state_bits_ftqOffset) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_ftqOffset g=%h i=%h", cyc, eg_g_io_state_bits_ftqOffset, eg_i_io_state_bits_ftqOffset);
        end
        eg_s1_io_state_bits_ftqOffset |= eg_g_io_state_bits_ftqOffset;
        eg_s0_io_state_bits_ftqOffset |= ~eg_g_io_state_bits_ftqOffset;
        checks++;
        if (eg_g_io_state_bits_hasException !== eg_i_io_state_bits_hasException) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_hasException g=%h i=%h", cyc, eg_g_io_state_bits_hasException, eg_i_io_state_bits_hasException);
        end
        eg_s1_io_state_bits_hasException |= eg_g_io_state_bits_hasException;
        eg_s0_io_state_bits_hasException |= ~eg_g_io_state_bits_hasException;
        checks++;
        if (eg_g_io_state_bits_isEnqExcp !== eg_i_io_state_bits_isEnqExcp) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_isEnqExcp g=%h i=%h", cyc, eg_g_io_state_bits_isEnqExcp, eg_i_io_state_bits_isEnqExcp);
        end
        eg_s1_io_state_bits_isEnqExcp |= eg_g_io_state_bits_isEnqExcp;
        eg_s0_io_state_bits_isEnqExcp |= ~eg_g_io_state_bits_isEnqExcp;
        checks++;
        if (eg_g_io_state_bits_exceptionVec_0 !== eg_i_io_state_bits_exceptionVec_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_exceptionVec_0 g=%h i=%h", cyc, eg_g_io_state_bits_exceptionVec_0, eg_i_io_state_bits_exceptionVec_0);
        end
        eg_s1_io_state_bits_exceptionVec_0 |= eg_g_io_state_bits_exceptionVec_0;
        eg_s0_io_state_bits_exceptionVec_0 |= ~eg_g_io_state_bits_exceptionVec_0;
        checks++;
        if (eg_g_io_state_bits_exceptionVec_1 !== eg_i_io_state_bits_exceptionVec_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_exceptionVec_1 g=%h i=%h", cyc, eg_g_io_state_bits_exceptionVec_1, eg_i_io_state_bits_exceptionVec_1);
        end
        eg_s1_io_state_bits_exceptionVec_1 |= eg_g_io_state_bits_exceptionVec_1;
        eg_s0_io_state_bits_exceptionVec_1 |= ~eg_g_io_state_bits_exceptionVec_1;
        checks++;
        if (eg_g_io_state_bits_exceptionVec_2 !== eg_i_io_state_bits_exceptionVec_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_exceptionVec_2 g=%h i=%h", cyc, eg_g_io_state_bits_exceptionVec_2, eg_i_io_state_bits_exceptionVec_2);
        end
        eg_s1_io_state_bits_exceptionVec_2 |= eg_g_io_state_bits_exceptionVec_2;
        eg_s0_io_state_bits_exceptionVec_2 |= ~eg_g_io_state_bits_exceptionVec_2;
        checks++;
        if (eg_g_io_state_bits_exceptionVec_3 !== eg_i_io_state_bits_exceptionVec_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_exceptionVec_3 g=%h i=%h", cyc, eg_g_io_state_bits_exceptionVec_3, eg_i_io_state_bits_exceptionVec_3);
        end
        eg_s1_io_state_bits_exceptionVec_3 |= eg_g_io_state_bits_exceptionVec_3;
        eg_s0_io_state_bits_exceptionVec_3 |= ~eg_g_io_state_bits_exceptionVec_3;
        checks++;
        if (eg_g_io_state_bits_exceptionVec_4 !== eg_i_io_state_bits_exceptionVec_4) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_exceptionVec_4 g=%h i=%h", cyc, eg_g_io_state_bits_exceptionVec_4, eg_i_io_state_bits_exceptionVec_4);
        end
        eg_s1_io_state_bits_exceptionVec_4 |= eg_g_io_state_bits_exceptionVec_4;
        eg_s0_io_state_bits_exceptionVec_4 |= ~eg_g_io_state_bits_exceptionVec_4;
        checks++;
        if (eg_g_io_state_bits_exceptionVec_5 !== eg_i_io_state_bits_exceptionVec_5) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_exceptionVec_5 g=%h i=%h", cyc, eg_g_io_state_bits_exceptionVec_5, eg_i_io_state_bits_exceptionVec_5);
        end
        eg_s1_io_state_bits_exceptionVec_5 |= eg_g_io_state_bits_exceptionVec_5;
        eg_s0_io_state_bits_exceptionVec_5 |= ~eg_g_io_state_bits_exceptionVec_5;
        checks++;
        if (eg_g_io_state_bits_exceptionVec_6 !== eg_i_io_state_bits_exceptionVec_6) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_exceptionVec_6 g=%h i=%h", cyc, eg_g_io_state_bits_exceptionVec_6, eg_i_io_state_bits_exceptionVec_6);
        end
        eg_s1_io_state_bits_exceptionVec_6 |= eg_g_io_state_bits_exceptionVec_6;
        eg_s0_io_state_bits_exceptionVec_6 |= ~eg_g_io_state_bits_exceptionVec_6;
        checks++;
        if (eg_g_io_state_bits_exceptionVec_7 !== eg_i_io_state_bits_exceptionVec_7) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_exceptionVec_7 g=%h i=%h", cyc, eg_g_io_state_bits_exceptionVec_7, eg_i_io_state_bits_exceptionVec_7);
        end
        eg_s1_io_state_bits_exceptionVec_7 |= eg_g_io_state_bits_exceptionVec_7;
        eg_s0_io_state_bits_exceptionVec_7 |= ~eg_g_io_state_bits_exceptionVec_7;
        checks++;
        if (eg_g_io_state_bits_exceptionVec_8 !== eg_i_io_state_bits_exceptionVec_8) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_exceptionVec_8 g=%h i=%h", cyc, eg_g_io_state_bits_exceptionVec_8, eg_i_io_state_bits_exceptionVec_8);
        end
        eg_s1_io_state_bits_exceptionVec_8 |= eg_g_io_state_bits_exceptionVec_8;
        eg_s0_io_state_bits_exceptionVec_8 |= ~eg_g_io_state_bits_exceptionVec_8;
        checks++;
        if (eg_g_io_state_bits_exceptionVec_9 !== eg_i_io_state_bits_exceptionVec_9) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_exceptionVec_9 g=%h i=%h", cyc, eg_g_io_state_bits_exceptionVec_9, eg_i_io_state_bits_exceptionVec_9);
        end
        eg_s1_io_state_bits_exceptionVec_9 |= eg_g_io_state_bits_exceptionVec_9;
        eg_s0_io_state_bits_exceptionVec_9 |= ~eg_g_io_state_bits_exceptionVec_9;
        checks++;
        if (eg_g_io_state_bits_exceptionVec_10 !== eg_i_io_state_bits_exceptionVec_10) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_exceptionVec_10 g=%h i=%h", cyc, eg_g_io_state_bits_exceptionVec_10, eg_i_io_state_bits_exceptionVec_10);
        end
        eg_s1_io_state_bits_exceptionVec_10 |= eg_g_io_state_bits_exceptionVec_10;
        eg_s0_io_state_bits_exceptionVec_10 |= ~eg_g_io_state_bits_exceptionVec_10;
        checks++;
        if (eg_g_io_state_bits_exceptionVec_11 !== eg_i_io_state_bits_exceptionVec_11) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_exceptionVec_11 g=%h i=%h", cyc, eg_g_io_state_bits_exceptionVec_11, eg_i_io_state_bits_exceptionVec_11);
        end
        eg_s1_io_state_bits_exceptionVec_11 |= eg_g_io_state_bits_exceptionVec_11;
        eg_s0_io_state_bits_exceptionVec_11 |= ~eg_g_io_state_bits_exceptionVec_11;
        checks++;
        if (eg_g_io_state_bits_exceptionVec_12 !== eg_i_io_state_bits_exceptionVec_12) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_exceptionVec_12 g=%h i=%h", cyc, eg_g_io_state_bits_exceptionVec_12, eg_i_io_state_bits_exceptionVec_12);
        end
        eg_s1_io_state_bits_exceptionVec_12 |= eg_g_io_state_bits_exceptionVec_12;
        eg_s0_io_state_bits_exceptionVec_12 |= ~eg_g_io_state_bits_exceptionVec_12;
        checks++;
        if (eg_g_io_state_bits_exceptionVec_13 !== eg_i_io_state_bits_exceptionVec_13) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_exceptionVec_13 g=%h i=%h", cyc, eg_g_io_state_bits_exceptionVec_13, eg_i_io_state_bits_exceptionVec_13);
        end
        eg_s1_io_state_bits_exceptionVec_13 |= eg_g_io_state_bits_exceptionVec_13;
        eg_s0_io_state_bits_exceptionVec_13 |= ~eg_g_io_state_bits_exceptionVec_13;
        checks++;
        if (eg_g_io_state_bits_exceptionVec_14 !== eg_i_io_state_bits_exceptionVec_14) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_exceptionVec_14 g=%h i=%h", cyc, eg_g_io_state_bits_exceptionVec_14, eg_i_io_state_bits_exceptionVec_14);
        end
        eg_s1_io_state_bits_exceptionVec_14 |= eg_g_io_state_bits_exceptionVec_14;
        eg_s0_io_state_bits_exceptionVec_14 |= ~eg_g_io_state_bits_exceptionVec_14;
        checks++;
        if (eg_g_io_state_bits_exceptionVec_15 !== eg_i_io_state_bits_exceptionVec_15) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_exceptionVec_15 g=%h i=%h", cyc, eg_g_io_state_bits_exceptionVec_15, eg_i_io_state_bits_exceptionVec_15);
        end
        eg_s1_io_state_bits_exceptionVec_15 |= eg_g_io_state_bits_exceptionVec_15;
        eg_s0_io_state_bits_exceptionVec_15 |= ~eg_g_io_state_bits_exceptionVec_15;
        checks++;
        if (eg_g_io_state_bits_exceptionVec_16 !== eg_i_io_state_bits_exceptionVec_16) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_exceptionVec_16 g=%h i=%h", cyc, eg_g_io_state_bits_exceptionVec_16, eg_i_io_state_bits_exceptionVec_16);
        end
        eg_s1_io_state_bits_exceptionVec_16 |= eg_g_io_state_bits_exceptionVec_16;
        eg_s0_io_state_bits_exceptionVec_16 |= ~eg_g_io_state_bits_exceptionVec_16;
        checks++;
        if (eg_g_io_state_bits_exceptionVec_17 !== eg_i_io_state_bits_exceptionVec_17) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_exceptionVec_17 g=%h i=%h", cyc, eg_g_io_state_bits_exceptionVec_17, eg_i_io_state_bits_exceptionVec_17);
        end
        eg_s1_io_state_bits_exceptionVec_17 |= eg_g_io_state_bits_exceptionVec_17;
        eg_s0_io_state_bits_exceptionVec_17 |= ~eg_g_io_state_bits_exceptionVec_17;
        checks++;
        if (eg_g_io_state_bits_exceptionVec_18 !== eg_i_io_state_bits_exceptionVec_18) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_exceptionVec_18 g=%h i=%h", cyc, eg_g_io_state_bits_exceptionVec_18, eg_i_io_state_bits_exceptionVec_18);
        end
        eg_s1_io_state_bits_exceptionVec_18 |= eg_g_io_state_bits_exceptionVec_18;
        eg_s0_io_state_bits_exceptionVec_18 |= ~eg_g_io_state_bits_exceptionVec_18;
        checks++;
        if (eg_g_io_state_bits_exceptionVec_19 !== eg_i_io_state_bits_exceptionVec_19) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_exceptionVec_19 g=%h i=%h", cyc, eg_g_io_state_bits_exceptionVec_19, eg_i_io_state_bits_exceptionVec_19);
        end
        eg_s1_io_state_bits_exceptionVec_19 |= eg_g_io_state_bits_exceptionVec_19;
        eg_s0_io_state_bits_exceptionVec_19 |= ~eg_g_io_state_bits_exceptionVec_19;
        checks++;
        if (eg_g_io_state_bits_exceptionVec_20 !== eg_i_io_state_bits_exceptionVec_20) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_exceptionVec_20 g=%h i=%h", cyc, eg_g_io_state_bits_exceptionVec_20, eg_i_io_state_bits_exceptionVec_20);
        end
        eg_s1_io_state_bits_exceptionVec_20 |= eg_g_io_state_bits_exceptionVec_20;
        eg_s0_io_state_bits_exceptionVec_20 |= ~eg_g_io_state_bits_exceptionVec_20;
        checks++;
        if (eg_g_io_state_bits_exceptionVec_21 !== eg_i_io_state_bits_exceptionVec_21) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_exceptionVec_21 g=%h i=%h", cyc, eg_g_io_state_bits_exceptionVec_21, eg_i_io_state_bits_exceptionVec_21);
        end
        eg_s1_io_state_bits_exceptionVec_21 |= eg_g_io_state_bits_exceptionVec_21;
        eg_s0_io_state_bits_exceptionVec_21 |= ~eg_g_io_state_bits_exceptionVec_21;
        checks++;
        if (eg_g_io_state_bits_exceptionVec_22 !== eg_i_io_state_bits_exceptionVec_22) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_exceptionVec_22 g=%h i=%h", cyc, eg_g_io_state_bits_exceptionVec_22, eg_i_io_state_bits_exceptionVec_22);
        end
        eg_s1_io_state_bits_exceptionVec_22 |= eg_g_io_state_bits_exceptionVec_22;
        eg_s0_io_state_bits_exceptionVec_22 |= ~eg_g_io_state_bits_exceptionVec_22;
        checks++;
        if (eg_g_io_state_bits_exceptionVec_23 !== eg_i_io_state_bits_exceptionVec_23) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_exceptionVec_23 g=%h i=%h", cyc, eg_g_io_state_bits_exceptionVec_23, eg_i_io_state_bits_exceptionVec_23);
        end
        eg_s1_io_state_bits_exceptionVec_23 |= eg_g_io_state_bits_exceptionVec_23;
        eg_s0_io_state_bits_exceptionVec_23 |= ~eg_g_io_state_bits_exceptionVec_23;
        checks++;
        if (eg_g_io_state_bits_isFetchMalAddr !== eg_i_io_state_bits_isFetchMalAddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_isFetchMalAddr g=%h i=%h", cyc, eg_g_io_state_bits_isFetchMalAddr, eg_i_io_state_bits_isFetchMalAddr);
        end
        eg_s1_io_state_bits_isFetchMalAddr |= eg_g_io_state_bits_isFetchMalAddr;
        eg_s0_io_state_bits_isFetchMalAddr |= ~eg_g_io_state_bits_isFetchMalAddr;
        checks++;
        if (eg_g_io_state_bits_satpFlushFirstFetchFault !== eg_i_io_state_bits_satpFlushFirstFetchFault) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_satpFlushFirstFetchFault g=%h i=%h", cyc, eg_g_io_state_bits_satpFlushFirstFetchFault, eg_i_io_state_bits_satpFlushFirstFetchFault);
        end
        eg_s1_io_state_bits_satpFlushFirstFetchFault |= eg_g_io_state_bits_satpFlushFirstFetchFault;
        eg_s0_io_state_bits_satpFlushFirstFetchFault |= ~eg_g_io_state_bits_satpFlushFirstFetchFault;
        checks++;
        if (eg_g_io_state_bits_flushPipe !== eg_i_io_state_bits_flushPipe) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_flushPipe g=%h i=%h", cyc, eg_g_io_state_bits_flushPipe, eg_i_io_state_bits_flushPipe);
        end
        eg_s1_io_state_bits_flushPipe |= eg_g_io_state_bits_flushPipe;
        eg_s0_io_state_bits_flushPipe |= ~eg_g_io_state_bits_flushPipe;
        checks++;
        if (eg_g_io_state_bits_satpFlushPipe !== eg_i_io_state_bits_satpFlushPipe) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_satpFlushPipe g=%h i=%h", cyc, eg_g_io_state_bits_satpFlushPipe, eg_i_io_state_bits_satpFlushPipe);
        end
        eg_s1_io_state_bits_satpFlushPipe |= eg_g_io_state_bits_satpFlushPipe;
        eg_s0_io_state_bits_satpFlushPipe |= ~eg_g_io_state_bits_satpFlushPipe;
        checks++;
        if (eg_g_io_state_bits_isVset !== eg_i_io_state_bits_isVset) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_isVset g=%h i=%h", cyc, eg_g_io_state_bits_isVset, eg_i_io_state_bits_isVset);
        end
        eg_s1_io_state_bits_isVset |= eg_g_io_state_bits_isVset;
        eg_s0_io_state_bits_isVset |= ~eg_g_io_state_bits_isVset;
        checks++;
        if (eg_g_io_state_bits_replayInst !== eg_i_io_state_bits_replayInst) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_replayInst g=%h i=%h", cyc, eg_g_io_state_bits_replayInst, eg_i_io_state_bits_replayInst);
        end
        eg_s1_io_state_bits_replayInst |= eg_g_io_state_bits_replayInst;
        eg_s0_io_state_bits_replayInst |= ~eg_g_io_state_bits_replayInst;
        checks++;
        if (eg_g_io_state_bits_singleStep !== eg_i_io_state_bits_singleStep) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_singleStep g=%h i=%h", cyc, eg_g_io_state_bits_singleStep, eg_i_io_state_bits_singleStep);
        end
        eg_s1_io_state_bits_singleStep |= eg_g_io_state_bits_singleStep;
        eg_s0_io_state_bits_singleStep |= ~eg_g_io_state_bits_singleStep;
        checks++;
        if (eg_g_io_state_bits_crossPageIPFFix !== eg_i_io_state_bits_crossPageIPFFix) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_crossPageIPFFix g=%h i=%h", cyc, eg_g_io_state_bits_crossPageIPFFix, eg_i_io_state_bits_crossPageIPFFix);
        end
        eg_s1_io_state_bits_crossPageIPFFix |= eg_g_io_state_bits_crossPageIPFFix;
        eg_s0_io_state_bits_crossPageIPFFix |= ~eg_g_io_state_bits_crossPageIPFFix;
        checks++;
        if (eg_g_io_state_bits_trigger !== eg_i_io_state_bits_trigger) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_trigger g=%h i=%h", cyc, eg_g_io_state_bits_trigger, eg_i_io_state_bits_trigger);
        end
        eg_s1_io_state_bits_trigger |= eg_g_io_state_bits_trigger;
        eg_s0_io_state_bits_trigger |= ~eg_g_io_state_bits_trigger;
        checks++;
        if (eg_g_io_state_bits_vstartEn !== eg_i_io_state_bits_vstartEn) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_vstartEn g=%h i=%h", cyc, eg_g_io_state_bits_vstartEn, eg_i_io_state_bits_vstartEn);
        end
        eg_s1_io_state_bits_vstartEn |= eg_g_io_state_bits_vstartEn;
        eg_s0_io_state_bits_vstartEn |= ~eg_g_io_state_bits_vstartEn;
        checks++;
        if (eg_g_io_state_bits_vstart !== eg_i_io_state_bits_vstart) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_vstart g=%h i=%h", cyc, eg_g_io_state_bits_vstart, eg_i_io_state_bits_vstart);
        end
        eg_s1_io_state_bits_vstart |= eg_g_io_state_bits_vstart;
        eg_s0_io_state_bits_vstart |= ~eg_g_io_state_bits_vstart;
        checks++;
        if (eg_g_io_state_bits_isVecLoad !== eg_i_io_state_bits_isVecLoad) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_isVecLoad g=%h i=%h", cyc, eg_g_io_state_bits_isVecLoad, eg_i_io_state_bits_isVecLoad);
        end
        eg_s1_io_state_bits_isVecLoad |= eg_g_io_state_bits_isVecLoad;
        eg_s0_io_state_bits_isVecLoad |= ~eg_g_io_state_bits_isVecLoad;
        checks++;
        if (eg_g_io_state_bits_isVlm !== eg_i_io_state_bits_isVlm) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_isVlm g=%h i=%h", cyc, eg_g_io_state_bits_isVlm, eg_i_io_state_bits_isVlm);
        end
        eg_s1_io_state_bits_isVlm |= eg_g_io_state_bits_isVlm;
        eg_s0_io_state_bits_isVlm |= ~eg_g_io_state_bits_isVlm;
        checks++;
        if (eg_g_io_state_bits_isStrided !== eg_i_io_state_bits_isStrided) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_isStrided g=%h i=%h", cyc, eg_g_io_state_bits_isStrided, eg_i_io_state_bits_isStrided);
        end
        eg_s1_io_state_bits_isStrided |= eg_g_io_state_bits_isStrided;
        eg_s0_io_state_bits_isStrided |= ~eg_g_io_state_bits_isStrided;
        checks++;
        if (eg_g_io_state_bits_isIndexed !== eg_i_io_state_bits_isIndexed) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_isIndexed g=%h i=%h", cyc, eg_g_io_state_bits_isIndexed, eg_i_io_state_bits_isIndexed);
        end
        eg_s1_io_state_bits_isIndexed |= eg_g_io_state_bits_isIndexed;
        eg_s0_io_state_bits_isIndexed |= ~eg_g_io_state_bits_isIndexed;
        checks++;
        if (eg_g_io_state_bits_isWhole !== eg_i_io_state_bits_isWhole) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_isWhole g=%h i=%h", cyc, eg_g_io_state_bits_isWhole, eg_i_io_state_bits_isWhole);
        end
        eg_s1_io_state_bits_isWhole |= eg_g_io_state_bits_isWhole;
        eg_s0_io_state_bits_isWhole |= ~eg_g_io_state_bits_isWhole;
        checks++;
        if (eg_g_io_state_bits_nf !== eg_i_io_state_bits_nf) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_nf g=%h i=%h", cyc, eg_g_io_state_bits_nf, eg_i_io_state_bits_nf);
        end
        eg_s1_io_state_bits_nf |= eg_g_io_state_bits_nf;
        eg_s0_io_state_bits_nf |= ~eg_g_io_state_bits_nf;
        checks++;
        if (eg_g_io_state_bits_vsew !== eg_i_io_state_bits_vsew) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_vsew g=%h i=%h", cyc, eg_g_io_state_bits_vsew, eg_i_io_state_bits_vsew);
        end
        eg_s1_io_state_bits_vsew |= eg_g_io_state_bits_vsew;
        eg_s0_io_state_bits_vsew |= ~eg_g_io_state_bits_vsew;
        checks++;
        if (eg_g_io_state_bits_veew !== eg_i_io_state_bits_veew) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_veew g=%h i=%h", cyc, eg_g_io_state_bits_veew, eg_i_io_state_bits_veew);
        end
        eg_s1_io_state_bits_veew |= eg_g_io_state_bits_veew;
        eg_s0_io_state_bits_veew |= ~eg_g_io_state_bits_veew;
        checks++;
        if (eg_g_io_state_bits_vlmul !== eg_i_io_state_bits_vlmul) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d ExceptionGen.io_state_bits_vlmul g=%h i=%h", cyc, eg_g_io_state_bits_vlmul, eg_i_io_state_bits_vlmul);
        end
        eg_s1_io_state_bits_vlmul |= eg_g_io_state_bits_vlmul;
        eg_s0_io_state_bits_vlmul |= ~eg_g_io_state_bits_vlmul;
        if (eg_u_gold.currentValid & eg_u_gold._GEN_2) eg_cov_s1_older_replace++;
        if (eg_u_gold.currentValid & eg_u_gold._GEN & eg_u_gold._GEN_3) eg_cov_s1_same_merge++;
        if (~eg_u_gold.currentValid & ~eg_u_gold._GEN & eg_u_gold._GEN_0) eg_cov_enq_into_empty++;
        if (eg_u_gold.currentValid & eg_io_redirect_valid) eg_cov_current_flushed++;
      end
      if (eg_g_io_state_valid) eg_armed[0] = 1'b1;
      if (eg_armed_at < 0 && (&eg_armed)) eg_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(eg_s0_io_state_valid && eg_s1_io_state_valid)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_valid 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_robIdx_flag && eg_s1_io_state_bits_robIdx_flag)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_robIdx_flag 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_robIdx_value[0] && eg_s1_io_state_bits_robIdx_value[0])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_robIdx_value[0] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_robIdx_value[1] && eg_s1_io_state_bits_robIdx_value[1])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_robIdx_value[1] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_robIdx_value[2] && eg_s1_io_state_bits_robIdx_value[2])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_robIdx_value[2] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_robIdx_value[3] && eg_s1_io_state_bits_robIdx_value[3])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_robIdx_value[3] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_robIdx_value[4] && eg_s1_io_state_bits_robIdx_value[4])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_robIdx_value[4] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_robIdx_value[5] && eg_s1_io_state_bits_robIdx_value[5])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_robIdx_value[5] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_robIdx_value[6] && eg_s1_io_state_bits_robIdx_value[6])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_robIdx_value[6] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_robIdx_value[7] && eg_s1_io_state_bits_robIdx_value[7])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_robIdx_value[7] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_ftqPtr_value[0] && eg_s1_io_state_bits_ftqPtr_value[0])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_ftqPtr_value[0] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_ftqPtr_value[1] && eg_s1_io_state_bits_ftqPtr_value[1])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_ftqPtr_value[1] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_ftqPtr_value[2] && eg_s1_io_state_bits_ftqPtr_value[2])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_ftqPtr_value[2] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_ftqPtr_value[3] && eg_s1_io_state_bits_ftqPtr_value[3])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_ftqPtr_value[3] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_ftqPtr_value[4] && eg_s1_io_state_bits_ftqPtr_value[4])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_ftqPtr_value[4] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_ftqPtr_value[5] && eg_s1_io_state_bits_ftqPtr_value[5])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_ftqPtr_value[5] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_ftqOffset[0] && eg_s1_io_state_bits_ftqOffset[0])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_ftqOffset[0] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_ftqOffset[1] && eg_s1_io_state_bits_ftqOffset[1])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_ftqOffset[1] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_ftqOffset[2] && eg_s1_io_state_bits_ftqOffset[2])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_ftqOffset[2] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_ftqOffset[3] && eg_s1_io_state_bits_ftqOffset[3])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_ftqOffset[3] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_hasException && eg_s1_io_state_bits_hasException)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_hasException 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_isEnqExcp && eg_s1_io_state_bits_isEnqExcp)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_isEnqExcp 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_exceptionVec_0 && eg_s1_io_state_bits_exceptionVec_0)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_exceptionVec_0 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_exceptionVec_1 && eg_s1_io_state_bits_exceptionVec_1)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_exceptionVec_1 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_exceptionVec_2 && eg_s1_io_state_bits_exceptionVec_2)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_exceptionVec_2 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_exceptionVec_3 && eg_s1_io_state_bits_exceptionVec_3)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_exceptionVec_3 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_exceptionVec_4 && eg_s1_io_state_bits_exceptionVec_4)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_exceptionVec_4 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_exceptionVec_5 && eg_s1_io_state_bits_exceptionVec_5)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_exceptionVec_5 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_exceptionVec_6 && eg_s1_io_state_bits_exceptionVec_6)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_exceptionVec_6 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_exceptionVec_7 && eg_s1_io_state_bits_exceptionVec_7)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_exceptionVec_7 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_exceptionVec_8 && eg_s1_io_state_bits_exceptionVec_8)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_exceptionVec_8 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_exceptionVec_9 && eg_s1_io_state_bits_exceptionVec_9)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_exceptionVec_9 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_exceptionVec_10 && eg_s1_io_state_bits_exceptionVec_10)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_exceptionVec_10 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_exceptionVec_11 && eg_s1_io_state_bits_exceptionVec_11)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_exceptionVec_11 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_exceptionVec_12 && eg_s1_io_state_bits_exceptionVec_12)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_exceptionVec_12 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_exceptionVec_13 && eg_s1_io_state_bits_exceptionVec_13)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_exceptionVec_13 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_exceptionVec_14 && eg_s1_io_state_bits_exceptionVec_14)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_exceptionVec_14 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_exceptionVec_15 && eg_s1_io_state_bits_exceptionVec_15)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_exceptionVec_15 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_exceptionVec_16 && eg_s1_io_state_bits_exceptionVec_16)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_exceptionVec_16 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_exceptionVec_17 && eg_s1_io_state_bits_exceptionVec_17)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_exceptionVec_17 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_exceptionVec_18 && eg_s1_io_state_bits_exceptionVec_18)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_exceptionVec_18 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_exceptionVec_19 && eg_s1_io_state_bits_exceptionVec_19)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_exceptionVec_19 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_exceptionVec_20 && eg_s1_io_state_bits_exceptionVec_20)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_exceptionVec_20 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_exceptionVec_21 && eg_s1_io_state_bits_exceptionVec_21)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_exceptionVec_21 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_exceptionVec_22 && eg_s1_io_state_bits_exceptionVec_22)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_exceptionVec_22 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_exceptionVec_23 && eg_s1_io_state_bits_exceptionVec_23)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_exceptionVec_23 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_isFetchMalAddr && eg_s1_io_state_bits_isFetchMalAddr)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_isFetchMalAddr 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_satpFlushFirstFetchFault && eg_s1_io_state_bits_satpFlushFirstFetchFault)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_satpFlushFirstFetchFault 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_flushPipe && eg_s1_io_state_bits_flushPipe)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_flushPipe 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_satpFlushPipe && eg_s1_io_state_bits_satpFlushPipe)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_satpFlushPipe 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_isVset && eg_s1_io_state_bits_isVset)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_isVset 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_replayInst && eg_s1_io_state_bits_replayInst)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_replayInst 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_singleStep && eg_s1_io_state_bits_singleStep)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_singleStep 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_crossPageIPFFix && eg_s1_io_state_bits_crossPageIPFFix)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_crossPageIPFFix 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_trigger[0] && eg_s1_io_state_bits_trigger[0])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_trigger[0] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_trigger[1] && eg_s1_io_state_bits_trigger[1])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_trigger[1] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_trigger[2] && eg_s1_io_state_bits_trigger[2])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_trigger[2] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_trigger[3] && eg_s1_io_state_bits_trigger[3])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_trigger[3] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstartEn && eg_s1_io_state_bits_vstartEn)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstartEn 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[0] && eg_s1_io_state_bits_vstart[0])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[0] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[1] && eg_s1_io_state_bits_vstart[1])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[1] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[2] && eg_s1_io_state_bits_vstart[2])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[2] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[3] && eg_s1_io_state_bits_vstart[3])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[3] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[4] && eg_s1_io_state_bits_vstart[4])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[4] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[5] && eg_s1_io_state_bits_vstart[5])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[5] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[6] && eg_s1_io_state_bits_vstart[6])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[6] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[7] && eg_s1_io_state_bits_vstart[7])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[7] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[8] && eg_s1_io_state_bits_vstart[8])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[8] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[9] && eg_s1_io_state_bits_vstart[9])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[9] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[10] && eg_s1_io_state_bits_vstart[10])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[10] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[11] && eg_s1_io_state_bits_vstart[11])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[11] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[12] && eg_s1_io_state_bits_vstart[12])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[12] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[13] && eg_s1_io_state_bits_vstart[13])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[13] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[14] && eg_s1_io_state_bits_vstart[14])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[14] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[15] && eg_s1_io_state_bits_vstart[15])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[15] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[16] && eg_s1_io_state_bits_vstart[16])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[16] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[17] && eg_s1_io_state_bits_vstart[17])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[17] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[18] && eg_s1_io_state_bits_vstart[18])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[18] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[19] && eg_s1_io_state_bits_vstart[19])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[19] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[20] && eg_s1_io_state_bits_vstart[20])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[20] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[21] && eg_s1_io_state_bits_vstart[21])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[21] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[22] && eg_s1_io_state_bits_vstart[22])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[22] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[23] && eg_s1_io_state_bits_vstart[23])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[23] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[24] && eg_s1_io_state_bits_vstart[24])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[24] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[25] && eg_s1_io_state_bits_vstart[25])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[25] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[26] && eg_s1_io_state_bits_vstart[26])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[26] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[27] && eg_s1_io_state_bits_vstart[27])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[27] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[28] && eg_s1_io_state_bits_vstart[28])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[28] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[29] && eg_s1_io_state_bits_vstart[29])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[29] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[30] && eg_s1_io_state_bits_vstart[30])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[30] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[31] && eg_s1_io_state_bits_vstart[31])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[31] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[32] && eg_s1_io_state_bits_vstart[32])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[32] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[33] && eg_s1_io_state_bits_vstart[33])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[33] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[34] && eg_s1_io_state_bits_vstart[34])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[34] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[35] && eg_s1_io_state_bits_vstart[35])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[35] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[36] && eg_s1_io_state_bits_vstart[36])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[36] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[37] && eg_s1_io_state_bits_vstart[37])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[37] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[38] && eg_s1_io_state_bits_vstart[38])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[38] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[39] && eg_s1_io_state_bits_vstart[39])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[39] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[40] && eg_s1_io_state_bits_vstart[40])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[40] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[41] && eg_s1_io_state_bits_vstart[41])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[41] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[42] && eg_s1_io_state_bits_vstart[42])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[42] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[43] && eg_s1_io_state_bits_vstart[43])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[43] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[44] && eg_s1_io_state_bits_vstart[44])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[44] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[45] && eg_s1_io_state_bits_vstart[45])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[45] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[46] && eg_s1_io_state_bits_vstart[46])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[46] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[47] && eg_s1_io_state_bits_vstart[47])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[47] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[48] && eg_s1_io_state_bits_vstart[48])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[48] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[49] && eg_s1_io_state_bits_vstart[49])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[49] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[50] && eg_s1_io_state_bits_vstart[50])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[50] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[51] && eg_s1_io_state_bits_vstart[51])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[51] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[52] && eg_s1_io_state_bits_vstart[52])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[52] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[53] && eg_s1_io_state_bits_vstart[53])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[53] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[54] && eg_s1_io_state_bits_vstart[54])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[54] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[55] && eg_s1_io_state_bits_vstart[55])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[55] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[56] && eg_s1_io_state_bits_vstart[56])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[56] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[57] && eg_s1_io_state_bits_vstart[57])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[57] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[58] && eg_s1_io_state_bits_vstart[58])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[58] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[59] && eg_s1_io_state_bits_vstart[59])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[59] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[60] && eg_s1_io_state_bits_vstart[60])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[60] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[61] && eg_s1_io_state_bits_vstart[61])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[61] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[62] && eg_s1_io_state_bits_vstart[62])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[62] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vstart[63] && eg_s1_io_state_bits_vstart[63])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vstart[63] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_isVecLoad && eg_s1_io_state_bits_isVecLoad)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_isVecLoad 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_isVlm && eg_s1_io_state_bits_isVlm)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_isVlm 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_isStrided && eg_s1_io_state_bits_isStrided)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_isStrided 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_isIndexed && eg_s1_io_state_bits_isIndexed)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_isIndexed 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_isWhole && eg_s1_io_state_bits_isWhole)) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_isWhole 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_nf[0] && eg_s1_io_state_bits_nf[0])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_nf[0] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_nf[1] && eg_s1_io_state_bits_nf[1])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_nf[1] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_nf[2] && eg_s1_io_state_bits_nf[2])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_nf[2] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vsew[0] && eg_s1_io_state_bits_vsew[0])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vsew[0] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vsew[1] && eg_s1_io_state_bits_vsew[1])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vsew[1] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_veew[0] && eg_s1_io_state_bits_veew[0])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_veew[0] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_veew[1] && eg_s1_io_state_bits_veew[1])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_veew[1] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vlmul[0] && eg_s1_io_state_bits_vlmul[0])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vlmul[0] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vlmul[1] && eg_s1_io_state_bits_vlmul[1])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vlmul[1] 未见过 0 和 1"); end
    if (!(eg_s0_io_state_bits_vlmul[2] && eg_s1_io_state_bits_vlmul[2])) begin cov_fail++; $display("[COV] ExceptionGen.io_state_bits_vlmul[2] 未见过 0 和 1"); end
    $display("[ARM] ExceptionGen armed_at=%0d", eg_armed_at);
    if (eg_armed_at < 0) begin cov_fail++; $display("[ARM] ExceptionGen 从未 arm"); end
    $display("[COV] ExceptionGen.s1_older_replace = %0d", eg_cov_s1_older_replace);
    if (eg_cov_s1_older_replace < 200) begin cov_fail++; $display("[COV] ExceptionGen.s1_older_replace < 200"); end
    $display("[COV] ExceptionGen.s1_same_merge = %0d", eg_cov_s1_same_merge);
    if (eg_cov_s1_same_merge < 200) begin cov_fail++; $display("[COV] ExceptionGen.s1_same_merge < 200"); end
    $display("[COV] ExceptionGen.enq_into_empty = %0d", eg_cov_enq_into_empty);
    if (eg_cov_enq_into_empty < 200) begin cov_fail++; $display("[COV] ExceptionGen.enq_into_empty < 200"); end
    $display("[COV] ExceptionGen.current_flushed = %0d", eg_cov_current_flushed);
    if (eg_cov_current_flushed < 200) begin cov_fail++; $display("[COV] ExceptionGen.current_flushed < 200"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
