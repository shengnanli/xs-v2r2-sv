// 自动生成：scripts/gen_virtualloadqueue.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic io_redirect_valid;
  logic io_redirect_bits_robIdx_flag;
  logic [7:0] io_redirect_bits_robIdx_value;
  logic io_redirect_bits_level;
  logic io_vecCommit_0_valid;
  logic io_vecCommit_0_bits_robidx_flag;
  logic [7:0] io_vecCommit_0_bits_robidx_value;
  logic [6:0] io_vecCommit_0_bits_uopidx;
  logic io_vecCommit_1_valid;
  logic io_vecCommit_1_bits_robidx_flag;
  logic [7:0] io_vecCommit_1_bits_robidx_value;
  logic [6:0] io_vecCommit_1_bits_uopidx;
  logic io_enq_sqCanAccept;
  logic io_enq_needAlloc_0;
  logic io_enq_needAlloc_1;
  logic io_enq_needAlloc_2;
  logic io_enq_needAlloc_3;
  logic io_enq_needAlloc_4;
  logic io_enq_req_0_valid;
  logic [34:0] io_enq_req_0_bits_fuType;
  logic [6:0] io_enq_req_0_bits_uopIdx;
  logic io_enq_req_0_bits_robIdx_flag;
  logic [7:0] io_enq_req_0_bits_robIdx_value;
  logic io_enq_req_0_bits_lqIdx_flag;
  logic [6:0] io_enq_req_0_bits_lqIdx_value;
  logic [4:0] io_enq_req_0_bits_numLsElem;
  logic io_enq_req_1_valid;
  logic [34:0] io_enq_req_1_bits_fuType;
  logic [6:0] io_enq_req_1_bits_uopIdx;
  logic io_enq_req_1_bits_robIdx_flag;
  logic [7:0] io_enq_req_1_bits_robIdx_value;
  logic io_enq_req_1_bits_lqIdx_flag;
  logic [6:0] io_enq_req_1_bits_lqIdx_value;
  logic [4:0] io_enq_req_1_bits_numLsElem;
  logic io_enq_req_2_valid;
  logic [34:0] io_enq_req_2_bits_fuType;
  logic [6:0] io_enq_req_2_bits_uopIdx;
  logic io_enq_req_2_bits_robIdx_flag;
  logic [7:0] io_enq_req_2_bits_robIdx_value;
  logic io_enq_req_2_bits_lqIdx_flag;
  logic [6:0] io_enq_req_2_bits_lqIdx_value;
  logic [4:0] io_enq_req_2_bits_numLsElem;
  logic io_enq_req_3_valid;
  logic [34:0] io_enq_req_3_bits_fuType;
  logic [6:0] io_enq_req_3_bits_uopIdx;
  logic io_enq_req_3_bits_robIdx_flag;
  logic [7:0] io_enq_req_3_bits_robIdx_value;
  logic io_enq_req_3_bits_lqIdx_flag;
  logic [6:0] io_enq_req_3_bits_lqIdx_value;
  logic [4:0] io_enq_req_3_bits_numLsElem;
  logic io_enq_req_4_valid;
  logic [34:0] io_enq_req_4_bits_fuType;
  logic [6:0] io_enq_req_4_bits_uopIdx;
  logic io_enq_req_4_bits_robIdx_flag;
  logic [7:0] io_enq_req_4_bits_robIdx_value;
  logic io_enq_req_4_bits_lqIdx_flag;
  logic [6:0] io_enq_req_4_bits_lqIdx_value;
  logic [4:0] io_enq_req_4_bits_numLsElem;
  logic io_enq_req_5_valid;
  logic [34:0] io_enq_req_5_bits_fuType;
  logic [6:0] io_enq_req_5_bits_uopIdx;
  logic io_enq_req_5_bits_robIdx_flag;
  logic [7:0] io_enq_req_5_bits_robIdx_value;
  logic io_enq_req_5_bits_lqIdx_flag;
  logic [6:0] io_enq_req_5_bits_lqIdx_value;
  logic [4:0] io_enq_req_5_bits_numLsElem;
  logic io_ldin_0_valid;
  logic [6:0] io_ldin_0_bits_uop_lqIdx_value;
  logic io_ldin_0_bits_isvec;
  logic io_ldin_0_bits_updateAddrValid;
  logic io_ldin_0_bits_rep_info_cause_0;
  logic io_ldin_0_bits_rep_info_cause_1;
  logic io_ldin_0_bits_rep_info_cause_2;
  logic io_ldin_0_bits_rep_info_cause_3;
  logic io_ldin_0_bits_rep_info_cause_4;
  logic io_ldin_0_bits_rep_info_cause_5;
  logic io_ldin_0_bits_rep_info_cause_6;
  logic io_ldin_0_bits_rep_info_cause_7;
  logic io_ldin_0_bits_rep_info_cause_8;
  logic io_ldin_0_bits_rep_info_cause_9;
  logic io_ldin_0_bits_rep_info_cause_10;
  logic io_ldin_1_valid;
  logic [6:0] io_ldin_1_bits_uop_lqIdx_value;
  logic io_ldin_1_bits_isvec;
  logic io_ldin_1_bits_updateAddrValid;
  logic io_ldin_1_bits_rep_info_cause_0;
  logic io_ldin_1_bits_rep_info_cause_1;
  logic io_ldin_1_bits_rep_info_cause_2;
  logic io_ldin_1_bits_rep_info_cause_3;
  logic io_ldin_1_bits_rep_info_cause_4;
  logic io_ldin_1_bits_rep_info_cause_5;
  logic io_ldin_1_bits_rep_info_cause_6;
  logic io_ldin_1_bits_rep_info_cause_7;
  logic io_ldin_1_bits_rep_info_cause_8;
  logic io_ldin_1_bits_rep_info_cause_9;
  logic io_ldin_1_bits_rep_info_cause_10;
  logic io_ldin_2_valid;
  logic [6:0] io_ldin_2_bits_uop_lqIdx_value;
  logic io_ldin_2_bits_isvec;
  logic io_ldin_2_bits_updateAddrValid;
  logic io_ldin_2_bits_rep_info_cause_0;
  logic io_ldin_2_bits_rep_info_cause_1;
  logic io_ldin_2_bits_rep_info_cause_2;
  logic io_ldin_2_bits_rep_info_cause_3;
  logic io_ldin_2_bits_rep_info_cause_4;
  logic io_ldin_2_bits_rep_info_cause_5;
  logic io_ldin_2_bits_rep_info_cause_6;
  logic io_ldin_2_bits_rep_info_cause_7;
  logic io_ldin_2_bits_rep_info_cause_8;
  logic io_ldin_2_bits_rep_info_cause_9;
  logic io_ldin_2_bits_rep_info_cause_10;
  logic io_noUopsIssued;
  wire g_io_enq_canAccept;
  wire i_io_enq_canAccept;
  wire g_io_ldWbPtr_flag;
  wire i_io_ldWbPtr_flag;
  wire [6:0] g_io_ldWbPtr_value;
  wire [6:0] i_io_ldWbPtr_value;
  wire g_io_lqEmpty;
  wire i_io_lqEmpty;
  wire [3:0] g_io_lqDeq;
  wire [3:0] i_io_lqDeq;
  wire [6:0] g_io_lqCancelCnt;
  wire [6:0] i_io_lqCancelCnt;
  wire [5:0] g_io_perf_0_value;
  wire [5:0] i_io_perf_0_value;
  VirtualLoadQueue    u_g (.clock(clk), .reset(rst), .io_redirect_valid(io_redirect_valid), .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag), .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value), .io_redirect_bits_level(io_redirect_bits_level), .io_vecCommit_0_valid(io_vecCommit_0_valid), .io_vecCommit_0_bits_robidx_flag(io_vecCommit_0_bits_robidx_flag), .io_vecCommit_0_bits_robidx_value(io_vecCommit_0_bits_robidx_value), .io_vecCommit_0_bits_uopidx(io_vecCommit_0_bits_uopidx), .io_vecCommit_1_valid(io_vecCommit_1_valid), .io_vecCommit_1_bits_robidx_flag(io_vecCommit_1_bits_robidx_flag), .io_vecCommit_1_bits_robidx_value(io_vecCommit_1_bits_robidx_value), .io_vecCommit_1_bits_uopidx(io_vecCommit_1_bits_uopidx), .io_enq_sqCanAccept(io_enq_sqCanAccept), .io_enq_needAlloc_0(io_enq_needAlloc_0), .io_enq_needAlloc_1(io_enq_needAlloc_1), .io_enq_needAlloc_2(io_enq_needAlloc_2), .io_enq_needAlloc_3(io_enq_needAlloc_3), .io_enq_needAlloc_4(io_enq_needAlloc_4), .io_enq_req_0_valid(io_enq_req_0_valid), .io_enq_req_0_bits_fuType(io_enq_req_0_bits_fuType), .io_enq_req_0_bits_uopIdx(io_enq_req_0_bits_uopIdx), .io_enq_req_0_bits_robIdx_flag(io_enq_req_0_bits_robIdx_flag), .io_enq_req_0_bits_robIdx_value(io_enq_req_0_bits_robIdx_value), .io_enq_req_0_bits_lqIdx_flag(io_enq_req_0_bits_lqIdx_flag), .io_enq_req_0_bits_lqIdx_value(io_enq_req_0_bits_lqIdx_value), .io_enq_req_0_bits_numLsElem(io_enq_req_0_bits_numLsElem), .io_enq_req_1_valid(io_enq_req_1_valid), .io_enq_req_1_bits_fuType(io_enq_req_1_bits_fuType), .io_enq_req_1_bits_uopIdx(io_enq_req_1_bits_uopIdx), .io_enq_req_1_bits_robIdx_flag(io_enq_req_1_bits_robIdx_flag), .io_enq_req_1_bits_robIdx_value(io_enq_req_1_bits_robIdx_value), .io_enq_req_1_bits_lqIdx_flag(io_enq_req_1_bits_lqIdx_flag), .io_enq_req_1_bits_lqIdx_value(io_enq_req_1_bits_lqIdx_value), .io_enq_req_1_bits_numLsElem(io_enq_req_1_bits_numLsElem), .io_enq_req_2_valid(io_enq_req_2_valid), .io_enq_req_2_bits_fuType(io_enq_req_2_bits_fuType), .io_enq_req_2_bits_uopIdx(io_enq_req_2_bits_uopIdx), .io_enq_req_2_bits_robIdx_flag(io_enq_req_2_bits_robIdx_flag), .io_enq_req_2_bits_robIdx_value(io_enq_req_2_bits_robIdx_value), .io_enq_req_2_bits_lqIdx_flag(io_enq_req_2_bits_lqIdx_flag), .io_enq_req_2_bits_lqIdx_value(io_enq_req_2_bits_lqIdx_value), .io_enq_req_2_bits_numLsElem(io_enq_req_2_bits_numLsElem), .io_enq_req_3_valid(io_enq_req_3_valid), .io_enq_req_3_bits_fuType(io_enq_req_3_bits_fuType), .io_enq_req_3_bits_uopIdx(io_enq_req_3_bits_uopIdx), .io_enq_req_3_bits_robIdx_flag(io_enq_req_3_bits_robIdx_flag), .io_enq_req_3_bits_robIdx_value(io_enq_req_3_bits_robIdx_value), .io_enq_req_3_bits_lqIdx_flag(io_enq_req_3_bits_lqIdx_flag), .io_enq_req_3_bits_lqIdx_value(io_enq_req_3_bits_lqIdx_value), .io_enq_req_3_bits_numLsElem(io_enq_req_3_bits_numLsElem), .io_enq_req_4_valid(io_enq_req_4_valid), .io_enq_req_4_bits_fuType(io_enq_req_4_bits_fuType), .io_enq_req_4_bits_uopIdx(io_enq_req_4_bits_uopIdx), .io_enq_req_4_bits_robIdx_flag(io_enq_req_4_bits_robIdx_flag), .io_enq_req_4_bits_robIdx_value(io_enq_req_4_bits_robIdx_value), .io_enq_req_4_bits_lqIdx_flag(io_enq_req_4_bits_lqIdx_flag), .io_enq_req_4_bits_lqIdx_value(io_enq_req_4_bits_lqIdx_value), .io_enq_req_4_bits_numLsElem(io_enq_req_4_bits_numLsElem), .io_enq_req_5_valid(io_enq_req_5_valid), .io_enq_req_5_bits_fuType(io_enq_req_5_bits_fuType), .io_enq_req_5_bits_uopIdx(io_enq_req_5_bits_uopIdx), .io_enq_req_5_bits_robIdx_flag(io_enq_req_5_bits_robIdx_flag), .io_enq_req_5_bits_robIdx_value(io_enq_req_5_bits_robIdx_value), .io_enq_req_5_bits_lqIdx_flag(io_enq_req_5_bits_lqIdx_flag), .io_enq_req_5_bits_lqIdx_value(io_enq_req_5_bits_lqIdx_value), .io_enq_req_5_bits_numLsElem(io_enq_req_5_bits_numLsElem), .io_ldin_0_valid(io_ldin_0_valid), .io_ldin_0_bits_uop_lqIdx_value(io_ldin_0_bits_uop_lqIdx_value), .io_ldin_0_bits_isvec(io_ldin_0_bits_isvec), .io_ldin_0_bits_updateAddrValid(io_ldin_0_bits_updateAddrValid), .io_ldin_0_bits_rep_info_cause_0(io_ldin_0_bits_rep_info_cause_0), .io_ldin_0_bits_rep_info_cause_1(io_ldin_0_bits_rep_info_cause_1), .io_ldin_0_bits_rep_info_cause_2(io_ldin_0_bits_rep_info_cause_2), .io_ldin_0_bits_rep_info_cause_3(io_ldin_0_bits_rep_info_cause_3), .io_ldin_0_bits_rep_info_cause_4(io_ldin_0_bits_rep_info_cause_4), .io_ldin_0_bits_rep_info_cause_5(io_ldin_0_bits_rep_info_cause_5), .io_ldin_0_bits_rep_info_cause_6(io_ldin_0_bits_rep_info_cause_6), .io_ldin_0_bits_rep_info_cause_7(io_ldin_0_bits_rep_info_cause_7), .io_ldin_0_bits_rep_info_cause_8(io_ldin_0_bits_rep_info_cause_8), .io_ldin_0_bits_rep_info_cause_9(io_ldin_0_bits_rep_info_cause_9), .io_ldin_0_bits_rep_info_cause_10(io_ldin_0_bits_rep_info_cause_10), .io_ldin_1_valid(io_ldin_1_valid), .io_ldin_1_bits_uop_lqIdx_value(io_ldin_1_bits_uop_lqIdx_value), .io_ldin_1_bits_isvec(io_ldin_1_bits_isvec), .io_ldin_1_bits_updateAddrValid(io_ldin_1_bits_updateAddrValid), .io_ldin_1_bits_rep_info_cause_0(io_ldin_1_bits_rep_info_cause_0), .io_ldin_1_bits_rep_info_cause_1(io_ldin_1_bits_rep_info_cause_1), .io_ldin_1_bits_rep_info_cause_2(io_ldin_1_bits_rep_info_cause_2), .io_ldin_1_bits_rep_info_cause_3(io_ldin_1_bits_rep_info_cause_3), .io_ldin_1_bits_rep_info_cause_4(io_ldin_1_bits_rep_info_cause_4), .io_ldin_1_bits_rep_info_cause_5(io_ldin_1_bits_rep_info_cause_5), .io_ldin_1_bits_rep_info_cause_6(io_ldin_1_bits_rep_info_cause_6), .io_ldin_1_bits_rep_info_cause_7(io_ldin_1_bits_rep_info_cause_7), .io_ldin_1_bits_rep_info_cause_8(io_ldin_1_bits_rep_info_cause_8), .io_ldin_1_bits_rep_info_cause_9(io_ldin_1_bits_rep_info_cause_9), .io_ldin_1_bits_rep_info_cause_10(io_ldin_1_bits_rep_info_cause_10), .io_ldin_2_valid(io_ldin_2_valid), .io_ldin_2_bits_uop_lqIdx_value(io_ldin_2_bits_uop_lqIdx_value), .io_ldin_2_bits_isvec(io_ldin_2_bits_isvec), .io_ldin_2_bits_updateAddrValid(io_ldin_2_bits_updateAddrValid), .io_ldin_2_bits_rep_info_cause_0(io_ldin_2_bits_rep_info_cause_0), .io_ldin_2_bits_rep_info_cause_1(io_ldin_2_bits_rep_info_cause_1), .io_ldin_2_bits_rep_info_cause_2(io_ldin_2_bits_rep_info_cause_2), .io_ldin_2_bits_rep_info_cause_3(io_ldin_2_bits_rep_info_cause_3), .io_ldin_2_bits_rep_info_cause_4(io_ldin_2_bits_rep_info_cause_4), .io_ldin_2_bits_rep_info_cause_5(io_ldin_2_bits_rep_info_cause_5), .io_ldin_2_bits_rep_info_cause_6(io_ldin_2_bits_rep_info_cause_6), .io_ldin_2_bits_rep_info_cause_7(io_ldin_2_bits_rep_info_cause_7), .io_ldin_2_bits_rep_info_cause_8(io_ldin_2_bits_rep_info_cause_8), .io_ldin_2_bits_rep_info_cause_9(io_ldin_2_bits_rep_info_cause_9), .io_ldin_2_bits_rep_info_cause_10(io_ldin_2_bits_rep_info_cause_10), .io_noUopsIssued(io_noUopsIssued), .io_enq_canAccept(g_io_enq_canAccept), .io_ldWbPtr_flag(g_io_ldWbPtr_flag), .io_ldWbPtr_value(g_io_ldWbPtr_value), .io_lqEmpty(g_io_lqEmpty), .io_lqDeq(g_io_lqDeq), .io_lqCancelCnt(g_io_lqCancelCnt), .io_perf_0_value(g_io_perf_0_value));
  VirtualLoadQueue_xs u_i (.clock(clk), .reset(rst), .io_redirect_valid(io_redirect_valid), .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag), .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value), .io_redirect_bits_level(io_redirect_bits_level), .io_vecCommit_0_valid(io_vecCommit_0_valid), .io_vecCommit_0_bits_robidx_flag(io_vecCommit_0_bits_robidx_flag), .io_vecCommit_0_bits_robidx_value(io_vecCommit_0_bits_robidx_value), .io_vecCommit_0_bits_uopidx(io_vecCommit_0_bits_uopidx), .io_vecCommit_1_valid(io_vecCommit_1_valid), .io_vecCommit_1_bits_robidx_flag(io_vecCommit_1_bits_robidx_flag), .io_vecCommit_1_bits_robidx_value(io_vecCommit_1_bits_robidx_value), .io_vecCommit_1_bits_uopidx(io_vecCommit_1_bits_uopidx), .io_enq_sqCanAccept(io_enq_sqCanAccept), .io_enq_needAlloc_0(io_enq_needAlloc_0), .io_enq_needAlloc_1(io_enq_needAlloc_1), .io_enq_needAlloc_2(io_enq_needAlloc_2), .io_enq_needAlloc_3(io_enq_needAlloc_3), .io_enq_needAlloc_4(io_enq_needAlloc_4), .io_enq_req_0_valid(io_enq_req_0_valid), .io_enq_req_0_bits_fuType(io_enq_req_0_bits_fuType), .io_enq_req_0_bits_uopIdx(io_enq_req_0_bits_uopIdx), .io_enq_req_0_bits_robIdx_flag(io_enq_req_0_bits_robIdx_flag), .io_enq_req_0_bits_robIdx_value(io_enq_req_0_bits_robIdx_value), .io_enq_req_0_bits_lqIdx_flag(io_enq_req_0_bits_lqIdx_flag), .io_enq_req_0_bits_lqIdx_value(io_enq_req_0_bits_lqIdx_value), .io_enq_req_0_bits_numLsElem(io_enq_req_0_bits_numLsElem), .io_enq_req_1_valid(io_enq_req_1_valid), .io_enq_req_1_bits_fuType(io_enq_req_1_bits_fuType), .io_enq_req_1_bits_uopIdx(io_enq_req_1_bits_uopIdx), .io_enq_req_1_bits_robIdx_flag(io_enq_req_1_bits_robIdx_flag), .io_enq_req_1_bits_robIdx_value(io_enq_req_1_bits_robIdx_value), .io_enq_req_1_bits_lqIdx_flag(io_enq_req_1_bits_lqIdx_flag), .io_enq_req_1_bits_lqIdx_value(io_enq_req_1_bits_lqIdx_value), .io_enq_req_1_bits_numLsElem(io_enq_req_1_bits_numLsElem), .io_enq_req_2_valid(io_enq_req_2_valid), .io_enq_req_2_bits_fuType(io_enq_req_2_bits_fuType), .io_enq_req_2_bits_uopIdx(io_enq_req_2_bits_uopIdx), .io_enq_req_2_bits_robIdx_flag(io_enq_req_2_bits_robIdx_flag), .io_enq_req_2_bits_robIdx_value(io_enq_req_2_bits_robIdx_value), .io_enq_req_2_bits_lqIdx_flag(io_enq_req_2_bits_lqIdx_flag), .io_enq_req_2_bits_lqIdx_value(io_enq_req_2_bits_lqIdx_value), .io_enq_req_2_bits_numLsElem(io_enq_req_2_bits_numLsElem), .io_enq_req_3_valid(io_enq_req_3_valid), .io_enq_req_3_bits_fuType(io_enq_req_3_bits_fuType), .io_enq_req_3_bits_uopIdx(io_enq_req_3_bits_uopIdx), .io_enq_req_3_bits_robIdx_flag(io_enq_req_3_bits_robIdx_flag), .io_enq_req_3_bits_robIdx_value(io_enq_req_3_bits_robIdx_value), .io_enq_req_3_bits_lqIdx_flag(io_enq_req_3_bits_lqIdx_flag), .io_enq_req_3_bits_lqIdx_value(io_enq_req_3_bits_lqIdx_value), .io_enq_req_3_bits_numLsElem(io_enq_req_3_bits_numLsElem), .io_enq_req_4_valid(io_enq_req_4_valid), .io_enq_req_4_bits_fuType(io_enq_req_4_bits_fuType), .io_enq_req_4_bits_uopIdx(io_enq_req_4_bits_uopIdx), .io_enq_req_4_bits_robIdx_flag(io_enq_req_4_bits_robIdx_flag), .io_enq_req_4_bits_robIdx_value(io_enq_req_4_bits_robIdx_value), .io_enq_req_4_bits_lqIdx_flag(io_enq_req_4_bits_lqIdx_flag), .io_enq_req_4_bits_lqIdx_value(io_enq_req_4_bits_lqIdx_value), .io_enq_req_4_bits_numLsElem(io_enq_req_4_bits_numLsElem), .io_enq_req_5_valid(io_enq_req_5_valid), .io_enq_req_5_bits_fuType(io_enq_req_5_bits_fuType), .io_enq_req_5_bits_uopIdx(io_enq_req_5_bits_uopIdx), .io_enq_req_5_bits_robIdx_flag(io_enq_req_5_bits_robIdx_flag), .io_enq_req_5_bits_robIdx_value(io_enq_req_5_bits_robIdx_value), .io_enq_req_5_bits_lqIdx_flag(io_enq_req_5_bits_lqIdx_flag), .io_enq_req_5_bits_lqIdx_value(io_enq_req_5_bits_lqIdx_value), .io_enq_req_5_bits_numLsElem(io_enq_req_5_bits_numLsElem), .io_ldin_0_valid(io_ldin_0_valid), .io_ldin_0_bits_uop_lqIdx_value(io_ldin_0_bits_uop_lqIdx_value), .io_ldin_0_bits_isvec(io_ldin_0_bits_isvec), .io_ldin_0_bits_updateAddrValid(io_ldin_0_bits_updateAddrValid), .io_ldin_0_bits_rep_info_cause_0(io_ldin_0_bits_rep_info_cause_0), .io_ldin_0_bits_rep_info_cause_1(io_ldin_0_bits_rep_info_cause_1), .io_ldin_0_bits_rep_info_cause_2(io_ldin_0_bits_rep_info_cause_2), .io_ldin_0_bits_rep_info_cause_3(io_ldin_0_bits_rep_info_cause_3), .io_ldin_0_bits_rep_info_cause_4(io_ldin_0_bits_rep_info_cause_4), .io_ldin_0_bits_rep_info_cause_5(io_ldin_0_bits_rep_info_cause_5), .io_ldin_0_bits_rep_info_cause_6(io_ldin_0_bits_rep_info_cause_6), .io_ldin_0_bits_rep_info_cause_7(io_ldin_0_bits_rep_info_cause_7), .io_ldin_0_bits_rep_info_cause_8(io_ldin_0_bits_rep_info_cause_8), .io_ldin_0_bits_rep_info_cause_9(io_ldin_0_bits_rep_info_cause_9), .io_ldin_0_bits_rep_info_cause_10(io_ldin_0_bits_rep_info_cause_10), .io_ldin_1_valid(io_ldin_1_valid), .io_ldin_1_bits_uop_lqIdx_value(io_ldin_1_bits_uop_lqIdx_value), .io_ldin_1_bits_isvec(io_ldin_1_bits_isvec), .io_ldin_1_bits_updateAddrValid(io_ldin_1_bits_updateAddrValid), .io_ldin_1_bits_rep_info_cause_0(io_ldin_1_bits_rep_info_cause_0), .io_ldin_1_bits_rep_info_cause_1(io_ldin_1_bits_rep_info_cause_1), .io_ldin_1_bits_rep_info_cause_2(io_ldin_1_bits_rep_info_cause_2), .io_ldin_1_bits_rep_info_cause_3(io_ldin_1_bits_rep_info_cause_3), .io_ldin_1_bits_rep_info_cause_4(io_ldin_1_bits_rep_info_cause_4), .io_ldin_1_bits_rep_info_cause_5(io_ldin_1_bits_rep_info_cause_5), .io_ldin_1_bits_rep_info_cause_6(io_ldin_1_bits_rep_info_cause_6), .io_ldin_1_bits_rep_info_cause_7(io_ldin_1_bits_rep_info_cause_7), .io_ldin_1_bits_rep_info_cause_8(io_ldin_1_bits_rep_info_cause_8), .io_ldin_1_bits_rep_info_cause_9(io_ldin_1_bits_rep_info_cause_9), .io_ldin_1_bits_rep_info_cause_10(io_ldin_1_bits_rep_info_cause_10), .io_ldin_2_valid(io_ldin_2_valid), .io_ldin_2_bits_uop_lqIdx_value(io_ldin_2_bits_uop_lqIdx_value), .io_ldin_2_bits_isvec(io_ldin_2_bits_isvec), .io_ldin_2_bits_updateAddrValid(io_ldin_2_bits_updateAddrValid), .io_ldin_2_bits_rep_info_cause_0(io_ldin_2_bits_rep_info_cause_0), .io_ldin_2_bits_rep_info_cause_1(io_ldin_2_bits_rep_info_cause_1), .io_ldin_2_bits_rep_info_cause_2(io_ldin_2_bits_rep_info_cause_2), .io_ldin_2_bits_rep_info_cause_3(io_ldin_2_bits_rep_info_cause_3), .io_ldin_2_bits_rep_info_cause_4(io_ldin_2_bits_rep_info_cause_4), .io_ldin_2_bits_rep_info_cause_5(io_ldin_2_bits_rep_info_cause_5), .io_ldin_2_bits_rep_info_cause_6(io_ldin_2_bits_rep_info_cause_6), .io_ldin_2_bits_rep_info_cause_7(io_ldin_2_bits_rep_info_cause_7), .io_ldin_2_bits_rep_info_cause_8(io_ldin_2_bits_rep_info_cause_8), .io_ldin_2_bits_rep_info_cause_9(io_ldin_2_bits_rep_info_cause_9), .io_ldin_2_bits_rep_info_cause_10(io_ldin_2_bits_rep_info_cause_10), .io_noUopsIssued(io_noUopsIssued), .io_enq_canAccept(i_io_enq_canAccept), .io_ldWbPtr_flag(i_io_ldWbPtr_flag), .io_ldWbPtr_value(i_io_ldWbPtr_value), .io_lqEmpty(i_io_lqEmpty), .io_lqDeq(i_io_lqDeq), .io_lqCancelCnt(i_io_lqCancelCnt), .io_perf_0_value(i_io_perf_0_value));

  // ---- 入队指针模型（与 VirtualLoadQueue 入队协议一致，保证 lqIdx 合法）----
  localparam int SIZE = 72;
  localparam int ENQW = 6;
  int enq_flag, enq_val;                 // enqPtrExt(0) 模型
  int deq_flag, deq_val;                 // deqPtr 模型（近似：跟 golden 输出 ldWbPtr）
  // 本拍各请求口的 numLsElem/needAlloc/valid 决策（先决定再驱动信号）
  int  nls   [ENQW];
  bit  nalloc[ENQW];
  bit  vld   [ENQW];
  bit  rdir;
  int  i;
  int  used;                             // 已分配 flow 累计
  int  base_val, base_flag;

  always @(negedge clk) begin
    if (rst) begin
      enq_flag<=0; enq_val<=0;
      io_redirect_valid <= 1'b0;
      io_enq_req_0_valid <= 1'b0;
      io_enq_req_1_valid <= 1'b0;
      io_enq_req_2_valid <= 1'b0;
      io_enq_req_3_valid <= 1'b0;
      io_enq_req_4_valid <= 1'b0;
      io_enq_req_5_valid <= 1'b0;
      io_ldin_0_valid <= 1'b0;
      io_ldin_1_valid <= 1'b0;
      io_ldin_2_valid <= 1'b0;
      io_vecCommit_0_valid <= 1'b0;
      io_vecCommit_1_valid <= 1'b0;
    end else begin
      rdir = ($urandom_range(0,31)==0);
      io_redirect_valid <= rdir;
      io_redirect_bits_robIdx_flag  <= $urandom_range(0,1);
      io_redirect_bits_robIdx_value <= {4'h0, 4'($urandom)};
      io_redirect_bits_level        <= $urandom_range(0,1);

      // 计算每口决策：valid（随机）、numLsElem（1..2）、needAlloc=valid
      used = 0;
      base_val  = enq_val;
      base_flag = enq_flag;
      for (i=0;i<ENQW;i++) begin
        vld[i]    = ($urandom_range(0,1)) && !rdir;  // redirect 拍不入队（贴近 assert）
        nls[i]    = $urandom_range(1,2);
        nalloc[i] = vld[i];
      end
      // 驱动 enq 请求信号：lqIdx = enqPtr(0) + (前面口的 flow 累计)
      for (i=0;i<ENQW;i++) begin
        int lq_v, lq_f, s;
        s = (base_val + used) % SIZE;
        lq_f = base_flag ^ ((base_val + used) >= SIZE);
        lq_v = s;
        io_enq_req_valid_set(i, vld[i]);
        io_enq_req_lqidx_set(i, lq_f, lq_v);
        io_enq_req_nls_set(i, nls[i]);
        if (i < 5) io_enq_needalloc_set(i, nalloc[i]);
        if (vld[i]) used = used + nls[i];
      end
      io_enq_sqCanAccept <= 1'b1;
      // 更新 enqPtr 模型（仅在非 redirect 恢复期近似推进；DUT 自身精确，tb 只需给合法 lqIdx）
      enq_val  = (base_val + used) % SIZE;
      enq_flag = base_flag ^ ((base_val + used) >= SIZE);

      io_ldin_0_valid <= $urandom_range(0,1);
      io_ldin_0_bits_uop_lqIdx_value <= $urandom_range(0,71);
      io_ldin_0_bits_isvec <= ($urandom_range(0,3)==0);
      io_ldin_0_bits_updateAddrValid <= ($urandom_range(0,3)!=0);
      io_ldin_0_bits_rep_info_cause_0 <= ($urandom_range(0,15)==0);
      io_ldin_0_bits_rep_info_cause_1 <= ($urandom_range(0,15)==0);
      io_ldin_0_bits_rep_info_cause_2 <= ($urandom_range(0,15)==0);
      io_ldin_0_bits_rep_info_cause_3 <= ($urandom_range(0,15)==0);
      io_ldin_0_bits_rep_info_cause_4 <= ($urandom_range(0,15)==0);
      io_ldin_0_bits_rep_info_cause_5 <= ($urandom_range(0,15)==0);
      io_ldin_0_bits_rep_info_cause_6 <= ($urandom_range(0,15)==0);
      io_ldin_0_bits_rep_info_cause_7 <= ($urandom_range(0,15)==0);
      io_ldin_0_bits_rep_info_cause_8 <= ($urandom_range(0,15)==0);
      io_ldin_0_bits_rep_info_cause_9 <= ($urandom_range(0,15)==0);
      io_ldin_0_bits_rep_info_cause_10 <= ($urandom_range(0,15)==0);
      io_ldin_1_valid <= $urandom_range(0,1);
      io_ldin_1_bits_uop_lqIdx_value <= $urandom_range(0,71);
      io_ldin_1_bits_isvec <= ($urandom_range(0,3)==0);
      io_ldin_1_bits_updateAddrValid <= ($urandom_range(0,3)!=0);
      io_ldin_1_bits_rep_info_cause_0 <= ($urandom_range(0,15)==0);
      io_ldin_1_bits_rep_info_cause_1 <= ($urandom_range(0,15)==0);
      io_ldin_1_bits_rep_info_cause_2 <= ($urandom_range(0,15)==0);
      io_ldin_1_bits_rep_info_cause_3 <= ($urandom_range(0,15)==0);
      io_ldin_1_bits_rep_info_cause_4 <= ($urandom_range(0,15)==0);
      io_ldin_1_bits_rep_info_cause_5 <= ($urandom_range(0,15)==0);
      io_ldin_1_bits_rep_info_cause_6 <= ($urandom_range(0,15)==0);
      io_ldin_1_bits_rep_info_cause_7 <= ($urandom_range(0,15)==0);
      io_ldin_1_bits_rep_info_cause_8 <= ($urandom_range(0,15)==0);
      io_ldin_1_bits_rep_info_cause_9 <= ($urandom_range(0,15)==0);
      io_ldin_1_bits_rep_info_cause_10 <= ($urandom_range(0,15)==0);
      io_ldin_2_valid <= $urandom_range(0,1);
      io_ldin_2_bits_uop_lqIdx_value <= $urandom_range(0,71);
      io_ldin_2_bits_isvec <= ($urandom_range(0,3)==0);
      io_ldin_2_bits_updateAddrValid <= ($urandom_range(0,3)!=0);
      io_ldin_2_bits_rep_info_cause_0 <= ($urandom_range(0,15)==0);
      io_ldin_2_bits_rep_info_cause_1 <= ($urandom_range(0,15)==0);
      io_ldin_2_bits_rep_info_cause_2 <= ($urandom_range(0,15)==0);
      io_ldin_2_bits_rep_info_cause_3 <= ($urandom_range(0,15)==0);
      io_ldin_2_bits_rep_info_cause_4 <= ($urandom_range(0,15)==0);
      io_ldin_2_bits_rep_info_cause_5 <= ($urandom_range(0,15)==0);
      io_ldin_2_bits_rep_info_cause_6 <= ($urandom_range(0,15)==0);
      io_ldin_2_bits_rep_info_cause_7 <= ($urandom_range(0,15)==0);
      io_ldin_2_bits_rep_info_cause_8 <= ($urandom_range(0,15)==0);
      io_ldin_2_bits_rep_info_cause_9 <= ($urandom_range(0,15)==0);
      io_ldin_2_bits_rep_info_cause_10 <= ($urandom_range(0,15)==0);
      io_vecCommit_0_valid <= $urandom_range(0,1);
      io_vecCommit_0_bits_robidx_flag <= $urandom_range(0,1);
      io_vecCommit_0_bits_robidx_value <= {4'h0, 4'($urandom)};
      io_vecCommit_0_bits_uopidx <= 7'($urandom);
      io_vecCommit_1_valid <= $urandom_range(0,1);
      io_vecCommit_1_bits_robidx_flag <= $urandom_range(0,1);
      io_vecCommit_1_bits_robidx_value <= {4'h0, 4'($urandom)};
      io_vecCommit_1_bits_uopidx <= 7'($urandom);
      io_enq_req_0_bits_fuType <= 35'($urandom);
      io_enq_req_0_bits_uopIdx <= 7'($urandom);
      io_enq_req_0_bits_robIdx_flag <= $urandom_range(0,1);
      io_enq_req_0_bits_robIdx_value <= {4'h0, 4'($urandom)};
      io_enq_req_1_bits_fuType <= 35'($urandom);
      io_enq_req_1_bits_uopIdx <= 7'($urandom);
      io_enq_req_1_bits_robIdx_flag <= $urandom_range(0,1);
      io_enq_req_1_bits_robIdx_value <= {4'h0, 4'($urandom)};
      io_enq_req_2_bits_fuType <= 35'($urandom);
      io_enq_req_2_bits_uopIdx <= 7'($urandom);
      io_enq_req_2_bits_robIdx_flag <= $urandom_range(0,1);
      io_enq_req_2_bits_robIdx_value <= {4'h0, 4'($urandom)};
      io_enq_req_3_bits_fuType <= 35'($urandom);
      io_enq_req_3_bits_uopIdx <= 7'($urandom);
      io_enq_req_3_bits_robIdx_flag <= $urandom_range(0,1);
      io_enq_req_3_bits_robIdx_value <= {4'h0, 4'($urandom)};
      io_enq_req_4_bits_fuType <= 35'($urandom);
      io_enq_req_4_bits_uopIdx <= 7'($urandom);
      io_enq_req_4_bits_robIdx_flag <= $urandom_range(0,1);
      io_enq_req_4_bits_robIdx_value <= {4'h0, 4'($urandom)};
      io_enq_req_5_bits_fuType <= 35'($urandom);
      io_enq_req_5_bits_uopIdx <= 7'($urandom);
      io_enq_req_5_bits_robIdx_flag <= $urandom_range(0,1);
      io_enq_req_5_bits_robIdx_value <= {4'h0, 4'($urandom)};
      io_noUopsIssued <= $urandom_range(0,1);
    end
  end

  // 把数组下标 i 映射到各扁平 enq 端口
  task io_enq_req_valid_set(int i, bit v);
    case(i)
      0: io_enq_req_0_valid <= v; 1: io_enq_req_1_valid <= v; 2: io_enq_req_2_valid <= v;
      3: io_enq_req_3_valid <= v; 4: io_enq_req_4_valid <= v; 5: io_enq_req_5_valid <= v;
    endcase
  endtask
  task io_enq_req_lqidx_set(int i, bit f, int v);
    case(i)
      0: begin io_enq_req_0_bits_lqIdx_flag<=f; io_enq_req_0_bits_lqIdx_value<=v[6:0]; end
      1: begin io_enq_req_1_bits_lqIdx_flag<=f; io_enq_req_1_bits_lqIdx_value<=v[6:0]; end
      2: begin io_enq_req_2_bits_lqIdx_flag<=f; io_enq_req_2_bits_lqIdx_value<=v[6:0]; end
      3: begin io_enq_req_3_bits_lqIdx_flag<=f; io_enq_req_3_bits_lqIdx_value<=v[6:0]; end
      4: begin io_enq_req_4_bits_lqIdx_flag<=f; io_enq_req_4_bits_lqIdx_value<=v[6:0]; end
      5: begin io_enq_req_5_bits_lqIdx_flag<=f; io_enq_req_5_bits_lqIdx_value<=v[6:0]; end
    endcase
  endtask
  task io_enq_req_nls_set(int i, int n);
    case(i)
      0: io_enq_req_0_bits_numLsElem <= n[4:0]; 1: io_enq_req_1_bits_numLsElem <= n[4:0];
      2: io_enq_req_2_bits_numLsElem <= n[4:0]; 3: io_enq_req_3_bits_numLsElem <= n[4:0];
      4: io_enq_req_4_bits_numLsElem <= n[4:0]; 5: io_enq_req_5_bits_numLsElem <= n[4:0];
    endcase
  endtask
  task io_enq_needalloc_set(int i, bit a);
    case(i)
      0: io_enq_needAlloc_0 <= a; 1: io_enq_needAlloc_1 <= a; 2: io_enq_needAlloc_2 <= a;
      3: io_enq_needAlloc_3 <= a; 4: io_enq_needAlloc_4 <= a;
    endcase
  endtask

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_io_enq_canAccept) && g_io_enq_canAccept !== i_io_enq_canAccept) begin errors++;
      if(errors<=60) $display("[%0t] io_enq_canAccept g=%h i=%h", $time, g_io_enq_canAccept, i_io_enq_canAccept); end
    if (!$isunknown(g_io_ldWbPtr_flag) && g_io_ldWbPtr_flag !== i_io_ldWbPtr_flag) begin errors++;
      if(errors<=60) $display("[%0t] io_ldWbPtr_flag g=%h i=%h", $time, g_io_ldWbPtr_flag, i_io_ldWbPtr_flag); end
    if (!$isunknown(g_io_ldWbPtr_value) && g_io_ldWbPtr_value !== i_io_ldWbPtr_value) begin errors++;
      if(errors<=60) $display("[%0t] io_ldWbPtr_value g=%h i=%h", $time, g_io_ldWbPtr_value, i_io_ldWbPtr_value); end
    if (!$isunknown(g_io_lqEmpty) && g_io_lqEmpty !== i_io_lqEmpty) begin errors++;
      if(errors<=60) $display("[%0t] io_lqEmpty g=%h i=%h", $time, g_io_lqEmpty, i_io_lqEmpty); end
    if (!$isunknown(g_io_lqDeq) && g_io_lqDeq !== i_io_lqDeq) begin errors++;
      if(errors<=60) $display("[%0t] io_lqDeq g=%h i=%h", $time, g_io_lqDeq, i_io_lqDeq); end
    if (!$isunknown(g_io_lqCancelCnt) && g_io_lqCancelCnt !== i_io_lqCancelCnt) begin errors++;
      if(errors<=60) $display("[%0t] io_lqCancelCnt g=%h i=%h", $time, g_io_lqCancelCnt, i_io_lqCancelCnt); end
    if (!$isunknown(g_io_perf_0_value) && g_io_perf_0_value !== i_io_perf_0_value) begin errors++;
      if(errors<=60) $display("[%0t] io_perf_0_value g=%h i=%h", $time, g_io_perf_0_value, i_io_perf_0_value); end
  end
  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
