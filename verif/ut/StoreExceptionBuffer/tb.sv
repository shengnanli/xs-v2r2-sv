// 自动生成：scripts/gen_storeexceptionbuffer.py —— 勿手改
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
  logic io_storeAddrIn_0_valid;
  logic io_storeAddrIn_0_bits_uop_exceptionVec_3;
  logic io_storeAddrIn_0_bits_uop_exceptionVec_6;
  logic io_storeAddrIn_0_bits_uop_exceptionVec_7;
  logic io_storeAddrIn_0_bits_uop_exceptionVec_15;
  logic io_storeAddrIn_0_bits_uop_exceptionVec_19;
  logic io_storeAddrIn_0_bits_uop_exceptionVec_23;
  logic [6:0] io_storeAddrIn_0_bits_uop_uopIdx;
  logic io_storeAddrIn_0_bits_uop_robIdx_flag;
  logic [7:0] io_storeAddrIn_0_bits_uop_robIdx_value;
  logic [63:0] io_storeAddrIn_0_bits_fullva;
  logic io_storeAddrIn_0_bits_vaNeedExt;
  logic [63:0] io_storeAddrIn_0_bits_gpaddr;
  logic io_storeAddrIn_0_bits_isHyper;
  logic io_storeAddrIn_0_bits_isForVSnonLeafPTE;
  logic io_storeAddrIn_1_valid;
  logic io_storeAddrIn_1_bits_uop_exceptionVec_3;
  logic io_storeAddrIn_1_bits_uop_exceptionVec_6;
  logic io_storeAddrIn_1_bits_uop_exceptionVec_7;
  logic io_storeAddrIn_1_bits_uop_exceptionVec_15;
  logic io_storeAddrIn_1_bits_uop_exceptionVec_19;
  logic io_storeAddrIn_1_bits_uop_exceptionVec_23;
  logic [6:0] io_storeAddrIn_1_bits_uop_uopIdx;
  logic io_storeAddrIn_1_bits_uop_robIdx_flag;
  logic [7:0] io_storeAddrIn_1_bits_uop_robIdx_value;
  logic [63:0] io_storeAddrIn_1_bits_fullva;
  logic io_storeAddrIn_1_bits_vaNeedExt;
  logic [63:0] io_storeAddrIn_1_bits_gpaddr;
  logic io_storeAddrIn_1_bits_isHyper;
  logic io_storeAddrIn_1_bits_isForVSnonLeafPTE;
  logic io_storeAddrIn_2_valid;
  logic io_storeAddrIn_2_bits_uop_exceptionVec_3;
  logic io_storeAddrIn_2_bits_uop_exceptionVec_6;
  logic io_storeAddrIn_2_bits_uop_exceptionVec_7;
  logic io_storeAddrIn_2_bits_uop_exceptionVec_15;
  logic io_storeAddrIn_2_bits_uop_exceptionVec_19;
  logic io_storeAddrIn_2_bits_uop_exceptionVec_23;
  logic [6:0] io_storeAddrIn_2_bits_uop_uopIdx;
  logic io_storeAddrIn_2_bits_uop_robIdx_flag;
  logic [7:0] io_storeAddrIn_2_bits_uop_robIdx_value;
  logic [63:0] io_storeAddrIn_2_bits_fullva;
  logic io_storeAddrIn_2_bits_vaNeedExt;
  logic [63:0] io_storeAddrIn_2_bits_gpaddr;
  logic io_storeAddrIn_2_bits_isHyper;
  logic io_storeAddrIn_2_bits_isForVSnonLeafPTE;
  logic io_storeAddrIn_3_valid;
  logic io_storeAddrIn_3_bits_uop_exceptionVec_3;
  logic io_storeAddrIn_3_bits_uop_exceptionVec_6;
  logic io_storeAddrIn_3_bits_uop_exceptionVec_7;
  logic io_storeAddrIn_3_bits_uop_exceptionVec_15;
  logic io_storeAddrIn_3_bits_uop_exceptionVec_19;
  logic io_storeAddrIn_3_bits_uop_exceptionVec_23;
  logic [6:0] io_storeAddrIn_3_bits_uop_uopIdx;
  logic io_storeAddrIn_3_bits_uop_robIdx_flag;
  logic [7:0] io_storeAddrIn_3_bits_uop_robIdx_value;
  logic [63:0] io_storeAddrIn_3_bits_fullva;
  logic io_storeAddrIn_3_bits_vaNeedExt;
  logic [63:0] io_storeAddrIn_3_bits_gpaddr;
  logic io_storeAddrIn_3_bits_isHyper;
  logic io_storeAddrIn_3_bits_isForVSnonLeafPTE;
  logic io_storeAddrIn_4_valid;
  logic io_storeAddrIn_4_bits_uop_exceptionVec_3;
  logic io_storeAddrIn_4_bits_uop_exceptionVec_6;
  logic io_storeAddrIn_4_bits_uop_exceptionVec_7;
  logic io_storeAddrIn_4_bits_uop_exceptionVec_15;
  logic io_storeAddrIn_4_bits_uop_exceptionVec_19;
  logic io_storeAddrIn_4_bits_uop_exceptionVec_23;
  logic [6:0] io_storeAddrIn_4_bits_uop_uopIdx;
  logic io_storeAddrIn_4_bits_uop_robIdx_flag;
  logic [7:0] io_storeAddrIn_4_bits_uop_robIdx_value;
  logic [63:0] io_storeAddrIn_4_bits_fullva;
  logic io_storeAddrIn_4_bits_vaNeedExt;
  logic [63:0] io_storeAddrIn_4_bits_gpaddr;
  logic io_storeAddrIn_4_bits_isForVSnonLeafPTE;
  logic io_storeAddrIn_5_valid;
  logic io_storeAddrIn_5_bits_uop_exceptionVec_3;
  logic io_storeAddrIn_5_bits_uop_exceptionVec_6;
  logic io_storeAddrIn_5_bits_uop_exceptionVec_7;
  logic io_storeAddrIn_5_bits_uop_exceptionVec_15;
  logic io_storeAddrIn_5_bits_uop_exceptionVec_19;
  logic io_storeAddrIn_5_bits_uop_exceptionVec_23;
  logic [6:0] io_storeAddrIn_5_bits_uop_uopIdx;
  logic io_storeAddrIn_5_bits_uop_robIdx_flag;
  logic [7:0] io_storeAddrIn_5_bits_uop_robIdx_value;
  logic [63:0] io_storeAddrIn_5_bits_fullva;
  logic io_storeAddrIn_5_bits_vaNeedExt;
  logic [63:0] io_storeAddrIn_5_bits_gpaddr;
  logic io_storeAddrIn_5_bits_isForVSnonLeafPTE;
  logic io_storeAddrIn_6_valid;
  logic io_storeAddrIn_6_bits_uop_exceptionVec_19;
  logic [6:0] io_storeAddrIn_6_bits_uop_uopIdx;
  logic io_storeAddrIn_6_bits_uop_robIdx_flag;
  logic [7:0] io_storeAddrIn_6_bits_uop_robIdx_value;
  logic [63:0] io_storeAddrIn_6_bits_fullva;

  wire [63:0] g_io_exceptionAddr_vaddr;
  wire [63:0] i_io_exceptionAddr_vaddr;
  wire g_io_exceptionAddr_vaNeedExt;
  wire i_io_exceptionAddr_vaNeedExt;
  wire g_io_exceptionAddr_isHyper;
  wire i_io_exceptionAddr_isHyper;
  wire [63:0] g_io_exceptionAddr_gpaddr;
  wire [63:0] i_io_exceptionAddr_gpaddr;
  wire g_io_exceptionAddr_isForVSnonLeafPTE;
  wire i_io_exceptionAddr_isForVSnonLeafPTE;

  StoreExceptionBuffer u_g (
    .clock(clk),
    .reset(rst),
    .io_redirect_valid(io_redirect_valid),
    .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value),
    .io_redirect_bits_level(io_redirect_bits_level),
    .io_storeAddrIn_0_valid(io_storeAddrIn_0_valid),
    .io_storeAddrIn_0_bits_uop_exceptionVec_3(io_storeAddrIn_0_bits_uop_exceptionVec_3),
    .io_storeAddrIn_0_bits_uop_exceptionVec_6(io_storeAddrIn_0_bits_uop_exceptionVec_6),
    .io_storeAddrIn_0_bits_uop_exceptionVec_7(io_storeAddrIn_0_bits_uop_exceptionVec_7),
    .io_storeAddrIn_0_bits_uop_exceptionVec_15(io_storeAddrIn_0_bits_uop_exceptionVec_15),
    .io_storeAddrIn_0_bits_uop_exceptionVec_19(io_storeAddrIn_0_bits_uop_exceptionVec_19),
    .io_storeAddrIn_0_bits_uop_exceptionVec_23(io_storeAddrIn_0_bits_uop_exceptionVec_23),
    .io_storeAddrIn_0_bits_uop_uopIdx(io_storeAddrIn_0_bits_uop_uopIdx),
    .io_storeAddrIn_0_bits_uop_robIdx_flag(io_storeAddrIn_0_bits_uop_robIdx_flag),
    .io_storeAddrIn_0_bits_uop_robIdx_value(io_storeAddrIn_0_bits_uop_robIdx_value),
    .io_storeAddrIn_0_bits_fullva(io_storeAddrIn_0_bits_fullva),
    .io_storeAddrIn_0_bits_vaNeedExt(io_storeAddrIn_0_bits_vaNeedExt),
    .io_storeAddrIn_0_bits_gpaddr(io_storeAddrIn_0_bits_gpaddr),
    .io_storeAddrIn_0_bits_isHyper(io_storeAddrIn_0_bits_isHyper),
    .io_storeAddrIn_0_bits_isForVSnonLeafPTE(io_storeAddrIn_0_bits_isForVSnonLeafPTE),
    .io_storeAddrIn_1_valid(io_storeAddrIn_1_valid),
    .io_storeAddrIn_1_bits_uop_exceptionVec_3(io_storeAddrIn_1_bits_uop_exceptionVec_3),
    .io_storeAddrIn_1_bits_uop_exceptionVec_6(io_storeAddrIn_1_bits_uop_exceptionVec_6),
    .io_storeAddrIn_1_bits_uop_exceptionVec_7(io_storeAddrIn_1_bits_uop_exceptionVec_7),
    .io_storeAddrIn_1_bits_uop_exceptionVec_15(io_storeAddrIn_1_bits_uop_exceptionVec_15),
    .io_storeAddrIn_1_bits_uop_exceptionVec_19(io_storeAddrIn_1_bits_uop_exceptionVec_19),
    .io_storeAddrIn_1_bits_uop_exceptionVec_23(io_storeAddrIn_1_bits_uop_exceptionVec_23),
    .io_storeAddrIn_1_bits_uop_uopIdx(io_storeAddrIn_1_bits_uop_uopIdx),
    .io_storeAddrIn_1_bits_uop_robIdx_flag(io_storeAddrIn_1_bits_uop_robIdx_flag),
    .io_storeAddrIn_1_bits_uop_robIdx_value(io_storeAddrIn_1_bits_uop_robIdx_value),
    .io_storeAddrIn_1_bits_fullva(io_storeAddrIn_1_bits_fullva),
    .io_storeAddrIn_1_bits_vaNeedExt(io_storeAddrIn_1_bits_vaNeedExt),
    .io_storeAddrIn_1_bits_gpaddr(io_storeAddrIn_1_bits_gpaddr),
    .io_storeAddrIn_1_bits_isHyper(io_storeAddrIn_1_bits_isHyper),
    .io_storeAddrIn_1_bits_isForVSnonLeafPTE(io_storeAddrIn_1_bits_isForVSnonLeafPTE),
    .io_storeAddrIn_2_valid(io_storeAddrIn_2_valid),
    .io_storeAddrIn_2_bits_uop_exceptionVec_3(io_storeAddrIn_2_bits_uop_exceptionVec_3),
    .io_storeAddrIn_2_bits_uop_exceptionVec_6(io_storeAddrIn_2_bits_uop_exceptionVec_6),
    .io_storeAddrIn_2_bits_uop_exceptionVec_7(io_storeAddrIn_2_bits_uop_exceptionVec_7),
    .io_storeAddrIn_2_bits_uop_exceptionVec_15(io_storeAddrIn_2_bits_uop_exceptionVec_15),
    .io_storeAddrIn_2_bits_uop_exceptionVec_19(io_storeAddrIn_2_bits_uop_exceptionVec_19),
    .io_storeAddrIn_2_bits_uop_exceptionVec_23(io_storeAddrIn_2_bits_uop_exceptionVec_23),
    .io_storeAddrIn_2_bits_uop_uopIdx(io_storeAddrIn_2_bits_uop_uopIdx),
    .io_storeAddrIn_2_bits_uop_robIdx_flag(io_storeAddrIn_2_bits_uop_robIdx_flag),
    .io_storeAddrIn_2_bits_uop_robIdx_value(io_storeAddrIn_2_bits_uop_robIdx_value),
    .io_storeAddrIn_2_bits_fullva(io_storeAddrIn_2_bits_fullva),
    .io_storeAddrIn_2_bits_vaNeedExt(io_storeAddrIn_2_bits_vaNeedExt),
    .io_storeAddrIn_2_bits_gpaddr(io_storeAddrIn_2_bits_gpaddr),
    .io_storeAddrIn_2_bits_isHyper(io_storeAddrIn_2_bits_isHyper),
    .io_storeAddrIn_2_bits_isForVSnonLeafPTE(io_storeAddrIn_2_bits_isForVSnonLeafPTE),
    .io_storeAddrIn_3_valid(io_storeAddrIn_3_valid),
    .io_storeAddrIn_3_bits_uop_exceptionVec_3(io_storeAddrIn_3_bits_uop_exceptionVec_3),
    .io_storeAddrIn_3_bits_uop_exceptionVec_6(io_storeAddrIn_3_bits_uop_exceptionVec_6),
    .io_storeAddrIn_3_bits_uop_exceptionVec_7(io_storeAddrIn_3_bits_uop_exceptionVec_7),
    .io_storeAddrIn_3_bits_uop_exceptionVec_15(io_storeAddrIn_3_bits_uop_exceptionVec_15),
    .io_storeAddrIn_3_bits_uop_exceptionVec_19(io_storeAddrIn_3_bits_uop_exceptionVec_19),
    .io_storeAddrIn_3_bits_uop_exceptionVec_23(io_storeAddrIn_3_bits_uop_exceptionVec_23),
    .io_storeAddrIn_3_bits_uop_uopIdx(io_storeAddrIn_3_bits_uop_uopIdx),
    .io_storeAddrIn_3_bits_uop_robIdx_flag(io_storeAddrIn_3_bits_uop_robIdx_flag),
    .io_storeAddrIn_3_bits_uop_robIdx_value(io_storeAddrIn_3_bits_uop_robIdx_value),
    .io_storeAddrIn_3_bits_fullva(io_storeAddrIn_3_bits_fullva),
    .io_storeAddrIn_3_bits_vaNeedExt(io_storeAddrIn_3_bits_vaNeedExt),
    .io_storeAddrIn_3_bits_gpaddr(io_storeAddrIn_3_bits_gpaddr),
    .io_storeAddrIn_3_bits_isHyper(io_storeAddrIn_3_bits_isHyper),
    .io_storeAddrIn_3_bits_isForVSnonLeafPTE(io_storeAddrIn_3_bits_isForVSnonLeafPTE),
    .io_storeAddrIn_4_valid(io_storeAddrIn_4_valid),
    .io_storeAddrIn_4_bits_uop_exceptionVec_3(io_storeAddrIn_4_bits_uop_exceptionVec_3),
    .io_storeAddrIn_4_bits_uop_exceptionVec_6(io_storeAddrIn_4_bits_uop_exceptionVec_6),
    .io_storeAddrIn_4_bits_uop_exceptionVec_7(io_storeAddrIn_4_bits_uop_exceptionVec_7),
    .io_storeAddrIn_4_bits_uop_exceptionVec_15(io_storeAddrIn_4_bits_uop_exceptionVec_15),
    .io_storeAddrIn_4_bits_uop_exceptionVec_19(io_storeAddrIn_4_bits_uop_exceptionVec_19),
    .io_storeAddrIn_4_bits_uop_exceptionVec_23(io_storeAddrIn_4_bits_uop_exceptionVec_23),
    .io_storeAddrIn_4_bits_uop_uopIdx(io_storeAddrIn_4_bits_uop_uopIdx),
    .io_storeAddrIn_4_bits_uop_robIdx_flag(io_storeAddrIn_4_bits_uop_robIdx_flag),
    .io_storeAddrIn_4_bits_uop_robIdx_value(io_storeAddrIn_4_bits_uop_robIdx_value),
    .io_storeAddrIn_4_bits_fullva(io_storeAddrIn_4_bits_fullva),
    .io_storeAddrIn_4_bits_vaNeedExt(io_storeAddrIn_4_bits_vaNeedExt),
    .io_storeAddrIn_4_bits_gpaddr(io_storeAddrIn_4_bits_gpaddr),
    .io_storeAddrIn_4_bits_isForVSnonLeafPTE(io_storeAddrIn_4_bits_isForVSnonLeafPTE),
    .io_storeAddrIn_5_valid(io_storeAddrIn_5_valid),
    .io_storeAddrIn_5_bits_uop_exceptionVec_3(io_storeAddrIn_5_bits_uop_exceptionVec_3),
    .io_storeAddrIn_5_bits_uop_exceptionVec_6(io_storeAddrIn_5_bits_uop_exceptionVec_6),
    .io_storeAddrIn_5_bits_uop_exceptionVec_7(io_storeAddrIn_5_bits_uop_exceptionVec_7),
    .io_storeAddrIn_5_bits_uop_exceptionVec_15(io_storeAddrIn_5_bits_uop_exceptionVec_15),
    .io_storeAddrIn_5_bits_uop_exceptionVec_19(io_storeAddrIn_5_bits_uop_exceptionVec_19),
    .io_storeAddrIn_5_bits_uop_exceptionVec_23(io_storeAddrIn_5_bits_uop_exceptionVec_23),
    .io_storeAddrIn_5_bits_uop_uopIdx(io_storeAddrIn_5_bits_uop_uopIdx),
    .io_storeAddrIn_5_bits_uop_robIdx_flag(io_storeAddrIn_5_bits_uop_robIdx_flag),
    .io_storeAddrIn_5_bits_uop_robIdx_value(io_storeAddrIn_5_bits_uop_robIdx_value),
    .io_storeAddrIn_5_bits_fullva(io_storeAddrIn_5_bits_fullva),
    .io_storeAddrIn_5_bits_vaNeedExt(io_storeAddrIn_5_bits_vaNeedExt),
    .io_storeAddrIn_5_bits_gpaddr(io_storeAddrIn_5_bits_gpaddr),
    .io_storeAddrIn_5_bits_isForVSnonLeafPTE(io_storeAddrIn_5_bits_isForVSnonLeafPTE),
    .io_storeAddrIn_6_valid(io_storeAddrIn_6_valid),
    .io_storeAddrIn_6_bits_uop_exceptionVec_19(io_storeAddrIn_6_bits_uop_exceptionVec_19),
    .io_storeAddrIn_6_bits_uop_uopIdx(io_storeAddrIn_6_bits_uop_uopIdx),
    .io_storeAddrIn_6_bits_uop_robIdx_flag(io_storeAddrIn_6_bits_uop_robIdx_flag),
    .io_storeAddrIn_6_bits_uop_robIdx_value(io_storeAddrIn_6_bits_uop_robIdx_value),
    .io_storeAddrIn_6_bits_fullva(io_storeAddrIn_6_bits_fullva),
    .io_exceptionAddr_vaddr(g_io_exceptionAddr_vaddr),
    .io_exceptionAddr_vaNeedExt(g_io_exceptionAddr_vaNeedExt),
    .io_exceptionAddr_isHyper(g_io_exceptionAddr_isHyper),
    .io_exceptionAddr_gpaddr(g_io_exceptionAddr_gpaddr),
    .io_exceptionAddr_isForVSnonLeafPTE(g_io_exceptionAddr_isForVSnonLeafPTE)
  );
  StoreExceptionBuffer_xs u_i (
    .clock(clk),
    .reset(rst),
    .io_redirect_valid(io_redirect_valid),
    .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value),
    .io_redirect_bits_level(io_redirect_bits_level),
    .io_storeAddrIn_0_valid(io_storeAddrIn_0_valid),
    .io_storeAddrIn_0_bits_uop_exceptionVec_3(io_storeAddrIn_0_bits_uop_exceptionVec_3),
    .io_storeAddrIn_0_bits_uop_exceptionVec_6(io_storeAddrIn_0_bits_uop_exceptionVec_6),
    .io_storeAddrIn_0_bits_uop_exceptionVec_7(io_storeAddrIn_0_bits_uop_exceptionVec_7),
    .io_storeAddrIn_0_bits_uop_exceptionVec_15(io_storeAddrIn_0_bits_uop_exceptionVec_15),
    .io_storeAddrIn_0_bits_uop_exceptionVec_19(io_storeAddrIn_0_bits_uop_exceptionVec_19),
    .io_storeAddrIn_0_bits_uop_exceptionVec_23(io_storeAddrIn_0_bits_uop_exceptionVec_23),
    .io_storeAddrIn_0_bits_uop_uopIdx(io_storeAddrIn_0_bits_uop_uopIdx),
    .io_storeAddrIn_0_bits_uop_robIdx_flag(io_storeAddrIn_0_bits_uop_robIdx_flag),
    .io_storeAddrIn_0_bits_uop_robIdx_value(io_storeAddrIn_0_bits_uop_robIdx_value),
    .io_storeAddrIn_0_bits_fullva(io_storeAddrIn_0_bits_fullva),
    .io_storeAddrIn_0_bits_vaNeedExt(io_storeAddrIn_0_bits_vaNeedExt),
    .io_storeAddrIn_0_bits_gpaddr(io_storeAddrIn_0_bits_gpaddr),
    .io_storeAddrIn_0_bits_isHyper(io_storeAddrIn_0_bits_isHyper),
    .io_storeAddrIn_0_bits_isForVSnonLeafPTE(io_storeAddrIn_0_bits_isForVSnonLeafPTE),
    .io_storeAddrIn_1_valid(io_storeAddrIn_1_valid),
    .io_storeAddrIn_1_bits_uop_exceptionVec_3(io_storeAddrIn_1_bits_uop_exceptionVec_3),
    .io_storeAddrIn_1_bits_uop_exceptionVec_6(io_storeAddrIn_1_bits_uop_exceptionVec_6),
    .io_storeAddrIn_1_bits_uop_exceptionVec_7(io_storeAddrIn_1_bits_uop_exceptionVec_7),
    .io_storeAddrIn_1_bits_uop_exceptionVec_15(io_storeAddrIn_1_bits_uop_exceptionVec_15),
    .io_storeAddrIn_1_bits_uop_exceptionVec_19(io_storeAddrIn_1_bits_uop_exceptionVec_19),
    .io_storeAddrIn_1_bits_uop_exceptionVec_23(io_storeAddrIn_1_bits_uop_exceptionVec_23),
    .io_storeAddrIn_1_bits_uop_uopIdx(io_storeAddrIn_1_bits_uop_uopIdx),
    .io_storeAddrIn_1_bits_uop_robIdx_flag(io_storeAddrIn_1_bits_uop_robIdx_flag),
    .io_storeAddrIn_1_bits_uop_robIdx_value(io_storeAddrIn_1_bits_uop_robIdx_value),
    .io_storeAddrIn_1_bits_fullva(io_storeAddrIn_1_bits_fullva),
    .io_storeAddrIn_1_bits_vaNeedExt(io_storeAddrIn_1_bits_vaNeedExt),
    .io_storeAddrIn_1_bits_gpaddr(io_storeAddrIn_1_bits_gpaddr),
    .io_storeAddrIn_1_bits_isHyper(io_storeAddrIn_1_bits_isHyper),
    .io_storeAddrIn_1_bits_isForVSnonLeafPTE(io_storeAddrIn_1_bits_isForVSnonLeafPTE),
    .io_storeAddrIn_2_valid(io_storeAddrIn_2_valid),
    .io_storeAddrIn_2_bits_uop_exceptionVec_3(io_storeAddrIn_2_bits_uop_exceptionVec_3),
    .io_storeAddrIn_2_bits_uop_exceptionVec_6(io_storeAddrIn_2_bits_uop_exceptionVec_6),
    .io_storeAddrIn_2_bits_uop_exceptionVec_7(io_storeAddrIn_2_bits_uop_exceptionVec_7),
    .io_storeAddrIn_2_bits_uop_exceptionVec_15(io_storeAddrIn_2_bits_uop_exceptionVec_15),
    .io_storeAddrIn_2_bits_uop_exceptionVec_19(io_storeAddrIn_2_bits_uop_exceptionVec_19),
    .io_storeAddrIn_2_bits_uop_exceptionVec_23(io_storeAddrIn_2_bits_uop_exceptionVec_23),
    .io_storeAddrIn_2_bits_uop_uopIdx(io_storeAddrIn_2_bits_uop_uopIdx),
    .io_storeAddrIn_2_bits_uop_robIdx_flag(io_storeAddrIn_2_bits_uop_robIdx_flag),
    .io_storeAddrIn_2_bits_uop_robIdx_value(io_storeAddrIn_2_bits_uop_robIdx_value),
    .io_storeAddrIn_2_bits_fullva(io_storeAddrIn_2_bits_fullva),
    .io_storeAddrIn_2_bits_vaNeedExt(io_storeAddrIn_2_bits_vaNeedExt),
    .io_storeAddrIn_2_bits_gpaddr(io_storeAddrIn_2_bits_gpaddr),
    .io_storeAddrIn_2_bits_isHyper(io_storeAddrIn_2_bits_isHyper),
    .io_storeAddrIn_2_bits_isForVSnonLeafPTE(io_storeAddrIn_2_bits_isForVSnonLeafPTE),
    .io_storeAddrIn_3_valid(io_storeAddrIn_3_valid),
    .io_storeAddrIn_3_bits_uop_exceptionVec_3(io_storeAddrIn_3_bits_uop_exceptionVec_3),
    .io_storeAddrIn_3_bits_uop_exceptionVec_6(io_storeAddrIn_3_bits_uop_exceptionVec_6),
    .io_storeAddrIn_3_bits_uop_exceptionVec_7(io_storeAddrIn_3_bits_uop_exceptionVec_7),
    .io_storeAddrIn_3_bits_uop_exceptionVec_15(io_storeAddrIn_3_bits_uop_exceptionVec_15),
    .io_storeAddrIn_3_bits_uop_exceptionVec_19(io_storeAddrIn_3_bits_uop_exceptionVec_19),
    .io_storeAddrIn_3_bits_uop_exceptionVec_23(io_storeAddrIn_3_bits_uop_exceptionVec_23),
    .io_storeAddrIn_3_bits_uop_uopIdx(io_storeAddrIn_3_bits_uop_uopIdx),
    .io_storeAddrIn_3_bits_uop_robIdx_flag(io_storeAddrIn_3_bits_uop_robIdx_flag),
    .io_storeAddrIn_3_bits_uop_robIdx_value(io_storeAddrIn_3_bits_uop_robIdx_value),
    .io_storeAddrIn_3_bits_fullva(io_storeAddrIn_3_bits_fullva),
    .io_storeAddrIn_3_bits_vaNeedExt(io_storeAddrIn_3_bits_vaNeedExt),
    .io_storeAddrIn_3_bits_gpaddr(io_storeAddrIn_3_bits_gpaddr),
    .io_storeAddrIn_3_bits_isHyper(io_storeAddrIn_3_bits_isHyper),
    .io_storeAddrIn_3_bits_isForVSnonLeafPTE(io_storeAddrIn_3_bits_isForVSnonLeafPTE),
    .io_storeAddrIn_4_valid(io_storeAddrIn_4_valid),
    .io_storeAddrIn_4_bits_uop_exceptionVec_3(io_storeAddrIn_4_bits_uop_exceptionVec_3),
    .io_storeAddrIn_4_bits_uop_exceptionVec_6(io_storeAddrIn_4_bits_uop_exceptionVec_6),
    .io_storeAddrIn_4_bits_uop_exceptionVec_7(io_storeAddrIn_4_bits_uop_exceptionVec_7),
    .io_storeAddrIn_4_bits_uop_exceptionVec_15(io_storeAddrIn_4_bits_uop_exceptionVec_15),
    .io_storeAddrIn_4_bits_uop_exceptionVec_19(io_storeAddrIn_4_bits_uop_exceptionVec_19),
    .io_storeAddrIn_4_bits_uop_exceptionVec_23(io_storeAddrIn_4_bits_uop_exceptionVec_23),
    .io_storeAddrIn_4_bits_uop_uopIdx(io_storeAddrIn_4_bits_uop_uopIdx),
    .io_storeAddrIn_4_bits_uop_robIdx_flag(io_storeAddrIn_4_bits_uop_robIdx_flag),
    .io_storeAddrIn_4_bits_uop_robIdx_value(io_storeAddrIn_4_bits_uop_robIdx_value),
    .io_storeAddrIn_4_bits_fullva(io_storeAddrIn_4_bits_fullva),
    .io_storeAddrIn_4_bits_vaNeedExt(io_storeAddrIn_4_bits_vaNeedExt),
    .io_storeAddrIn_4_bits_gpaddr(io_storeAddrIn_4_bits_gpaddr),
    .io_storeAddrIn_4_bits_isForVSnonLeafPTE(io_storeAddrIn_4_bits_isForVSnonLeafPTE),
    .io_storeAddrIn_5_valid(io_storeAddrIn_5_valid),
    .io_storeAddrIn_5_bits_uop_exceptionVec_3(io_storeAddrIn_5_bits_uop_exceptionVec_3),
    .io_storeAddrIn_5_bits_uop_exceptionVec_6(io_storeAddrIn_5_bits_uop_exceptionVec_6),
    .io_storeAddrIn_5_bits_uop_exceptionVec_7(io_storeAddrIn_5_bits_uop_exceptionVec_7),
    .io_storeAddrIn_5_bits_uop_exceptionVec_15(io_storeAddrIn_5_bits_uop_exceptionVec_15),
    .io_storeAddrIn_5_bits_uop_exceptionVec_19(io_storeAddrIn_5_bits_uop_exceptionVec_19),
    .io_storeAddrIn_5_bits_uop_exceptionVec_23(io_storeAddrIn_5_bits_uop_exceptionVec_23),
    .io_storeAddrIn_5_bits_uop_uopIdx(io_storeAddrIn_5_bits_uop_uopIdx),
    .io_storeAddrIn_5_bits_uop_robIdx_flag(io_storeAddrIn_5_bits_uop_robIdx_flag),
    .io_storeAddrIn_5_bits_uop_robIdx_value(io_storeAddrIn_5_bits_uop_robIdx_value),
    .io_storeAddrIn_5_bits_fullva(io_storeAddrIn_5_bits_fullva),
    .io_storeAddrIn_5_bits_vaNeedExt(io_storeAddrIn_5_bits_vaNeedExt),
    .io_storeAddrIn_5_bits_gpaddr(io_storeAddrIn_5_bits_gpaddr),
    .io_storeAddrIn_5_bits_isForVSnonLeafPTE(io_storeAddrIn_5_bits_isForVSnonLeafPTE),
    .io_storeAddrIn_6_valid(io_storeAddrIn_6_valid),
    .io_storeAddrIn_6_bits_uop_exceptionVec_19(io_storeAddrIn_6_bits_uop_exceptionVec_19),
    .io_storeAddrIn_6_bits_uop_uopIdx(io_storeAddrIn_6_bits_uop_uopIdx),
    .io_storeAddrIn_6_bits_uop_robIdx_flag(io_storeAddrIn_6_bits_uop_robIdx_flag),
    .io_storeAddrIn_6_bits_uop_robIdx_value(io_storeAddrIn_6_bits_uop_robIdx_value),
    .io_storeAddrIn_6_bits_fullva(io_storeAddrIn_6_bits_fullva),
    .io_exceptionAddr_vaddr(i_io_exceptionAddr_vaddr),
    .io_exceptionAddr_vaNeedExt(i_io_exceptionAddr_vaNeedExt),
    .io_exceptionAddr_isHyper(i_io_exceptionAddr_isHyper),
    .io_exceptionAddr_gpaddr(i_io_exceptionAddr_gpaddr),
    .io_exceptionAddr_isForVSnonLeafPTE(i_io_exceptionAddr_isForVSnonLeafPTE)
  );

  task automatic drive();
    io_redirect_valid = ($urandom_range(0,15)==0);
    io_redirect_bits_robIdx_flag = $urandom;
    io_redirect_bits_robIdx_value = $urandom_range(0,40);
    io_redirect_bits_level = $urandom;
    io_storeAddrIn_0_valid = ($urandom_range(0,2)!=0);
    io_storeAddrIn_0_bits_uop_exceptionVec_3 = ($urandom_range(0,2)==0);
    io_storeAddrIn_0_bits_uop_exceptionVec_6 = ($urandom_range(0,2)==0);
    io_storeAddrIn_0_bits_uop_exceptionVec_7 = ($urandom_range(0,2)==0);
    io_storeAddrIn_0_bits_uop_exceptionVec_15 = ($urandom_range(0,2)==0);
    io_storeAddrIn_0_bits_uop_exceptionVec_19 = ($urandom_range(0,2)==0);
    io_storeAddrIn_0_bits_uop_exceptionVec_23 = ($urandom_range(0,2)==0);
    io_storeAddrIn_0_bits_uop_uopIdx = $urandom_range(0,20);
    io_storeAddrIn_0_bits_uop_robIdx_flag = $urandom;
    io_storeAddrIn_0_bits_uop_robIdx_value = $urandom_range(0,40);
    io_storeAddrIn_0_bits_fullva = {$urandom,$urandom};
    io_storeAddrIn_0_bits_vaNeedExt = $urandom;
    io_storeAddrIn_0_bits_gpaddr = {$urandom,$urandom};
    io_storeAddrIn_0_bits_isHyper = $urandom;
    io_storeAddrIn_0_bits_isForVSnonLeafPTE = $urandom;
    io_storeAddrIn_1_valid = ($urandom_range(0,2)!=0);
    io_storeAddrIn_1_bits_uop_exceptionVec_3 = ($urandom_range(0,2)==0);
    io_storeAddrIn_1_bits_uop_exceptionVec_6 = ($urandom_range(0,2)==0);
    io_storeAddrIn_1_bits_uop_exceptionVec_7 = ($urandom_range(0,2)==0);
    io_storeAddrIn_1_bits_uop_exceptionVec_15 = ($urandom_range(0,2)==0);
    io_storeAddrIn_1_bits_uop_exceptionVec_19 = ($urandom_range(0,2)==0);
    io_storeAddrIn_1_bits_uop_exceptionVec_23 = ($urandom_range(0,2)==0);
    io_storeAddrIn_1_bits_uop_uopIdx = $urandom_range(0,20);
    io_storeAddrIn_1_bits_uop_robIdx_flag = $urandom;
    io_storeAddrIn_1_bits_uop_robIdx_value = $urandom_range(0,40);
    io_storeAddrIn_1_bits_fullva = {$urandom,$urandom};
    io_storeAddrIn_1_bits_vaNeedExt = $urandom;
    io_storeAddrIn_1_bits_gpaddr = {$urandom,$urandom};
    io_storeAddrIn_1_bits_isHyper = $urandom;
    io_storeAddrIn_1_bits_isForVSnonLeafPTE = $urandom;
    io_storeAddrIn_2_valid = ($urandom_range(0,2)!=0);
    io_storeAddrIn_2_bits_uop_exceptionVec_3 = ($urandom_range(0,2)==0);
    io_storeAddrIn_2_bits_uop_exceptionVec_6 = ($urandom_range(0,2)==0);
    io_storeAddrIn_2_bits_uop_exceptionVec_7 = ($urandom_range(0,2)==0);
    io_storeAddrIn_2_bits_uop_exceptionVec_15 = ($urandom_range(0,2)==0);
    io_storeAddrIn_2_bits_uop_exceptionVec_19 = ($urandom_range(0,2)==0);
    io_storeAddrIn_2_bits_uop_exceptionVec_23 = ($urandom_range(0,2)==0);
    io_storeAddrIn_2_bits_uop_uopIdx = $urandom_range(0,20);
    io_storeAddrIn_2_bits_uop_robIdx_flag = $urandom;
    io_storeAddrIn_2_bits_uop_robIdx_value = $urandom_range(0,40);
    io_storeAddrIn_2_bits_fullva = {$urandom,$urandom};
    io_storeAddrIn_2_bits_vaNeedExt = $urandom;
    io_storeAddrIn_2_bits_gpaddr = {$urandom,$urandom};
    io_storeAddrIn_2_bits_isHyper = $urandom;
    io_storeAddrIn_2_bits_isForVSnonLeafPTE = $urandom;
    io_storeAddrIn_3_valid = ($urandom_range(0,2)!=0);
    io_storeAddrIn_3_bits_uop_exceptionVec_3 = ($urandom_range(0,2)==0);
    io_storeAddrIn_3_bits_uop_exceptionVec_6 = ($urandom_range(0,2)==0);
    io_storeAddrIn_3_bits_uop_exceptionVec_7 = ($urandom_range(0,2)==0);
    io_storeAddrIn_3_bits_uop_exceptionVec_15 = ($urandom_range(0,2)==0);
    io_storeAddrIn_3_bits_uop_exceptionVec_19 = ($urandom_range(0,2)==0);
    io_storeAddrIn_3_bits_uop_exceptionVec_23 = ($urandom_range(0,2)==0);
    io_storeAddrIn_3_bits_uop_uopIdx = $urandom_range(0,20);
    io_storeAddrIn_3_bits_uop_robIdx_flag = $urandom;
    io_storeAddrIn_3_bits_uop_robIdx_value = $urandom_range(0,40);
    io_storeAddrIn_3_bits_fullva = {$urandom,$urandom};
    io_storeAddrIn_3_bits_vaNeedExt = $urandom;
    io_storeAddrIn_3_bits_gpaddr = {$urandom,$urandom};
    io_storeAddrIn_3_bits_isHyper = $urandom;
    io_storeAddrIn_3_bits_isForVSnonLeafPTE = $urandom;
    io_storeAddrIn_4_valid = ($urandom_range(0,2)!=0);
    io_storeAddrIn_4_bits_uop_exceptionVec_3 = ($urandom_range(0,2)==0);
    io_storeAddrIn_4_bits_uop_exceptionVec_6 = ($urandom_range(0,2)==0);
    io_storeAddrIn_4_bits_uop_exceptionVec_7 = ($urandom_range(0,2)==0);
    io_storeAddrIn_4_bits_uop_exceptionVec_15 = ($urandom_range(0,2)==0);
    io_storeAddrIn_4_bits_uop_exceptionVec_19 = ($urandom_range(0,2)==0);
    io_storeAddrIn_4_bits_uop_exceptionVec_23 = ($urandom_range(0,2)==0);
    io_storeAddrIn_4_bits_uop_uopIdx = $urandom_range(0,20);
    io_storeAddrIn_4_bits_uop_robIdx_flag = $urandom;
    io_storeAddrIn_4_bits_uop_robIdx_value = $urandom_range(0,40);
    io_storeAddrIn_4_bits_fullva = {$urandom,$urandom};
    io_storeAddrIn_4_bits_vaNeedExt = $urandom;
    io_storeAddrIn_4_bits_gpaddr = {$urandom,$urandom};
    io_storeAddrIn_4_bits_isForVSnonLeafPTE = $urandom;
    io_storeAddrIn_5_valid = ($urandom_range(0,2)!=0);
    io_storeAddrIn_5_bits_uop_exceptionVec_3 = ($urandom_range(0,2)==0);
    io_storeAddrIn_5_bits_uop_exceptionVec_6 = ($urandom_range(0,2)==0);
    io_storeAddrIn_5_bits_uop_exceptionVec_7 = ($urandom_range(0,2)==0);
    io_storeAddrIn_5_bits_uop_exceptionVec_15 = ($urandom_range(0,2)==0);
    io_storeAddrIn_5_bits_uop_exceptionVec_19 = ($urandom_range(0,2)==0);
    io_storeAddrIn_5_bits_uop_exceptionVec_23 = ($urandom_range(0,2)==0);
    io_storeAddrIn_5_bits_uop_uopIdx = $urandom_range(0,20);
    io_storeAddrIn_5_bits_uop_robIdx_flag = $urandom;
    io_storeAddrIn_5_bits_uop_robIdx_value = $urandom_range(0,40);
    io_storeAddrIn_5_bits_fullva = {$urandom,$urandom};
    io_storeAddrIn_5_bits_vaNeedExt = $urandom;
    io_storeAddrIn_5_bits_gpaddr = {$urandom,$urandom};
    io_storeAddrIn_5_bits_isForVSnonLeafPTE = $urandom;
    io_storeAddrIn_6_valid = ($urandom_range(0,2)!=0);
    io_storeAddrIn_6_bits_uop_exceptionVec_19 = ($urandom_range(0,2)==0);
    io_storeAddrIn_6_bits_uop_uopIdx = $urandom_range(0,20);
    io_storeAddrIn_6_bits_uop_robIdx_flag = $urandom;
    io_storeAddrIn_6_bits_uop_robIdx_value = $urandom_range(0,40);
    io_storeAddrIn_6_bits_fullva = {$urandom,$urandom};
  endtask

  int warmup = 4;
  always @(posedge clk) if (!rst) begin
    if (warmup > 0) warmup--; else begin
    checks++;
    if (!$isunknown(g_io_exceptionAddr_vaddr) && g_io_exceptionAddr_vaddr !== i_io_exceptionAddr_vaddr) begin errors++;
      if(errors<=60) $display("[%0t] io_exceptionAddr_vaddr g=%h i=%h", $time, g_io_exceptionAddr_vaddr, i_io_exceptionAddr_vaddr); end
    if (!$isunknown(g_io_exceptionAddr_vaNeedExt) && g_io_exceptionAddr_vaNeedExt !== i_io_exceptionAddr_vaNeedExt) begin errors++;
      if(errors<=60) $display("[%0t] io_exceptionAddr_vaNeedExt g=%h i=%h", $time, g_io_exceptionAddr_vaNeedExt, i_io_exceptionAddr_vaNeedExt); end
    if (!$isunknown(g_io_exceptionAddr_isHyper) && g_io_exceptionAddr_isHyper !== i_io_exceptionAddr_isHyper) begin errors++;
      if(errors<=60) $display("[%0t] io_exceptionAddr_isHyper g=%h i=%h", $time, g_io_exceptionAddr_isHyper, i_io_exceptionAddr_isHyper); end
    if (!$isunknown(g_io_exceptionAddr_gpaddr) && g_io_exceptionAddr_gpaddr !== i_io_exceptionAddr_gpaddr) begin errors++;
      if(errors<=60) $display("[%0t] io_exceptionAddr_gpaddr g=%h i=%h", $time, g_io_exceptionAddr_gpaddr, i_io_exceptionAddr_gpaddr); end
    if (!$isunknown(g_io_exceptionAddr_isForVSnonLeafPTE) && g_io_exceptionAddr_isForVSnonLeafPTE !== i_io_exceptionAddr_isForVSnonLeafPTE) begin errors++;
      if(errors<=60) $display("[%0t] io_exceptionAddr_isForVSnonLeafPTE g=%h i=%h", $time, g_io_exceptionAddr_isForVSnonLeafPTE, i_io_exceptionAddr_isForVSnonLeafPTE); end
    end
  end

  // FM 证伪探针：FM 因 golden 的逐字段标量 req 寄存器 + 每端口复制 valid 寄存器与
  // 可读核 struct/vector 寄存器边界不同而对少量 req 比对点判 inconclusive；
  // 这里逐拍直接比对内部 req 寄存器，证明数值恒等。
  // 证伪探针独立用较大的预热窗口（跳过复位释放后 req 寄存器首次装载的瞬态），
  // 之后逐拍证明内部 req 寄存器与 golden 数值恒等。
  int probe_mm = 0, pwarm = 16;
  always @(posedge clk) if (!rst) begin
    if (pwarm > 0) pwarm--; else
    if (u_g.req_valid && u_i.u_core.req_valid_r) begin
      // 与输出检查同样跳过 golden 端 X（未写过的字段在 +SYNTHESIS 下保持 X，属 don't-care）
      if (!$isunknown(u_g.req_fullva) && u_g.req_fullva  !== u_i.u_core.req_r.fullva)  probe_mm++;
      if (!$isunknown(u_g.req_gpaddr) && u_g.req_gpaddr  !== u_i.u_core.req_r.gpaddr)  probe_mm++;
      if (!$isunknown(u_g.req_uop_robIdx_value) && u_g.req_uop_robIdx_value !== u_i.u_core.req_r.robIdx.value) probe_mm++;
      if (!$isunknown(u_g.req_uop_uopIdx)       && u_g.req_uop_uopIdx       !== u_i.u_core.req_r.uopIdx)       probe_mm++;
    end
  end

  initial begin
    rst = 1; drive();
    repeat (8) @(posedge clk);
    rst = 0;
    repeat (NCYCLES) begin @(negedge clk); drive(); end
    $display("checks=%0d errors=%0d probe_mm=%0d", checks, errors, probe_mm);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
