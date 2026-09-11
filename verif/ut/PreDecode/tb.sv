// 自动生成：scripts/gen_predecode.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NVEC = 200000;
  int errors = 0, checks = 0;

  logic io_in_valid;
  logic [15:0] io_in_bits_data_0;
  logic [15:0] io_in_bits_data_1;
  logic [15:0] io_in_bits_data_2;
  logic [15:0] io_in_bits_data_3;
  logic [15:0] io_in_bits_data_4;
  logic [15:0] io_in_bits_data_5;
  logic [15:0] io_in_bits_data_6;
  logic [15:0] io_in_bits_data_7;
  logic [15:0] io_in_bits_data_8;
  logic [15:0] io_in_bits_data_9;
  logic [15:0] io_in_bits_data_10;
  logic [15:0] io_in_bits_data_11;
  logic [15:0] io_in_bits_data_12;
  logic [15:0] io_in_bits_data_13;
  logic [15:0] io_in_bits_data_14;
  logic [15:0] io_in_bits_data_15;
  logic [15:0] io_in_bits_data_16;
  wire g_io_out_pd_0_isRVC;
  wire i_io_out_pd_0_isRVC;
  wire [1:0] g_io_out_pd_0_brType;
  wire [1:0] i_io_out_pd_0_brType;
  wire g_io_out_pd_0_isCall;
  wire i_io_out_pd_0_isCall;
  wire g_io_out_pd_0_isRet;
  wire i_io_out_pd_0_isRet;
  wire g_io_out_pd_1_valid;
  wire i_io_out_pd_1_valid;
  wire g_io_out_pd_1_isRVC;
  wire i_io_out_pd_1_isRVC;
  wire [1:0] g_io_out_pd_1_brType;
  wire [1:0] i_io_out_pd_1_brType;
  wire g_io_out_pd_1_isCall;
  wire i_io_out_pd_1_isCall;
  wire g_io_out_pd_1_isRet;
  wire i_io_out_pd_1_isRet;
  wire g_io_out_pd_2_valid;
  wire i_io_out_pd_2_valid;
  wire g_io_out_pd_2_isRVC;
  wire i_io_out_pd_2_isRVC;
  wire [1:0] g_io_out_pd_2_brType;
  wire [1:0] i_io_out_pd_2_brType;
  wire g_io_out_pd_2_isCall;
  wire i_io_out_pd_2_isCall;
  wire g_io_out_pd_2_isRet;
  wire i_io_out_pd_2_isRet;
  wire g_io_out_pd_3_valid;
  wire i_io_out_pd_3_valid;
  wire g_io_out_pd_3_isRVC;
  wire i_io_out_pd_3_isRVC;
  wire [1:0] g_io_out_pd_3_brType;
  wire [1:0] i_io_out_pd_3_brType;
  wire g_io_out_pd_3_isCall;
  wire i_io_out_pd_3_isCall;
  wire g_io_out_pd_3_isRet;
  wire i_io_out_pd_3_isRet;
  wire g_io_out_pd_4_valid;
  wire i_io_out_pd_4_valid;
  wire g_io_out_pd_4_isRVC;
  wire i_io_out_pd_4_isRVC;
  wire [1:0] g_io_out_pd_4_brType;
  wire [1:0] i_io_out_pd_4_brType;
  wire g_io_out_pd_4_isCall;
  wire i_io_out_pd_4_isCall;
  wire g_io_out_pd_4_isRet;
  wire i_io_out_pd_4_isRet;
  wire g_io_out_pd_5_valid;
  wire i_io_out_pd_5_valid;
  wire g_io_out_pd_5_isRVC;
  wire i_io_out_pd_5_isRVC;
  wire [1:0] g_io_out_pd_5_brType;
  wire [1:0] i_io_out_pd_5_brType;
  wire g_io_out_pd_5_isCall;
  wire i_io_out_pd_5_isCall;
  wire g_io_out_pd_5_isRet;
  wire i_io_out_pd_5_isRet;
  wire g_io_out_pd_6_valid;
  wire i_io_out_pd_6_valid;
  wire g_io_out_pd_6_isRVC;
  wire i_io_out_pd_6_isRVC;
  wire [1:0] g_io_out_pd_6_brType;
  wire [1:0] i_io_out_pd_6_brType;
  wire g_io_out_pd_6_isCall;
  wire i_io_out_pd_6_isCall;
  wire g_io_out_pd_6_isRet;
  wire i_io_out_pd_6_isRet;
  wire g_io_out_pd_7_valid;
  wire i_io_out_pd_7_valid;
  wire g_io_out_pd_7_isRVC;
  wire i_io_out_pd_7_isRVC;
  wire [1:0] g_io_out_pd_7_brType;
  wire [1:0] i_io_out_pd_7_brType;
  wire g_io_out_pd_7_isCall;
  wire i_io_out_pd_7_isCall;
  wire g_io_out_pd_7_isRet;
  wire i_io_out_pd_7_isRet;
  wire g_io_out_pd_8_valid;
  wire i_io_out_pd_8_valid;
  wire g_io_out_pd_8_isRVC;
  wire i_io_out_pd_8_isRVC;
  wire [1:0] g_io_out_pd_8_brType;
  wire [1:0] i_io_out_pd_8_brType;
  wire g_io_out_pd_8_isCall;
  wire i_io_out_pd_8_isCall;
  wire g_io_out_pd_8_isRet;
  wire i_io_out_pd_8_isRet;
  wire g_io_out_pd_9_valid;
  wire i_io_out_pd_9_valid;
  wire g_io_out_pd_9_isRVC;
  wire i_io_out_pd_9_isRVC;
  wire [1:0] g_io_out_pd_9_brType;
  wire [1:0] i_io_out_pd_9_brType;
  wire g_io_out_pd_9_isCall;
  wire i_io_out_pd_9_isCall;
  wire g_io_out_pd_9_isRet;
  wire i_io_out_pd_9_isRet;
  wire g_io_out_pd_10_valid;
  wire i_io_out_pd_10_valid;
  wire g_io_out_pd_10_isRVC;
  wire i_io_out_pd_10_isRVC;
  wire [1:0] g_io_out_pd_10_brType;
  wire [1:0] i_io_out_pd_10_brType;
  wire g_io_out_pd_10_isCall;
  wire i_io_out_pd_10_isCall;
  wire g_io_out_pd_10_isRet;
  wire i_io_out_pd_10_isRet;
  wire g_io_out_pd_11_valid;
  wire i_io_out_pd_11_valid;
  wire g_io_out_pd_11_isRVC;
  wire i_io_out_pd_11_isRVC;
  wire [1:0] g_io_out_pd_11_brType;
  wire [1:0] i_io_out_pd_11_brType;
  wire g_io_out_pd_11_isCall;
  wire i_io_out_pd_11_isCall;
  wire g_io_out_pd_11_isRet;
  wire i_io_out_pd_11_isRet;
  wire g_io_out_pd_12_valid;
  wire i_io_out_pd_12_valid;
  wire g_io_out_pd_12_isRVC;
  wire i_io_out_pd_12_isRVC;
  wire [1:0] g_io_out_pd_12_brType;
  wire [1:0] i_io_out_pd_12_brType;
  wire g_io_out_pd_12_isCall;
  wire i_io_out_pd_12_isCall;
  wire g_io_out_pd_12_isRet;
  wire i_io_out_pd_12_isRet;
  wire g_io_out_pd_13_valid;
  wire i_io_out_pd_13_valid;
  wire g_io_out_pd_13_isRVC;
  wire i_io_out_pd_13_isRVC;
  wire [1:0] g_io_out_pd_13_brType;
  wire [1:0] i_io_out_pd_13_brType;
  wire g_io_out_pd_13_isCall;
  wire i_io_out_pd_13_isCall;
  wire g_io_out_pd_13_isRet;
  wire i_io_out_pd_13_isRet;
  wire g_io_out_pd_14_valid;
  wire i_io_out_pd_14_valid;
  wire g_io_out_pd_14_isRVC;
  wire i_io_out_pd_14_isRVC;
  wire [1:0] g_io_out_pd_14_brType;
  wire [1:0] i_io_out_pd_14_brType;
  wire g_io_out_pd_14_isCall;
  wire i_io_out_pd_14_isCall;
  wire g_io_out_pd_14_isRet;
  wire i_io_out_pd_14_isRet;
  wire g_io_out_pd_15_valid;
  wire i_io_out_pd_15_valid;
  wire g_io_out_pd_15_isRVC;
  wire i_io_out_pd_15_isRVC;
  wire [1:0] g_io_out_pd_15_brType;
  wire [1:0] i_io_out_pd_15_brType;
  wire g_io_out_pd_15_isCall;
  wire i_io_out_pd_15_isCall;
  wire g_io_out_pd_15_isRet;
  wire i_io_out_pd_15_isRet;
  wire g_io_out_hasHalfValid_2;
  wire i_io_out_hasHalfValid_2;
  wire g_io_out_hasHalfValid_3;
  wire i_io_out_hasHalfValid_3;
  wire g_io_out_hasHalfValid_4;
  wire i_io_out_hasHalfValid_4;
  wire g_io_out_hasHalfValid_5;
  wire i_io_out_hasHalfValid_5;
  wire g_io_out_hasHalfValid_6;
  wire i_io_out_hasHalfValid_6;
  wire g_io_out_hasHalfValid_7;
  wire i_io_out_hasHalfValid_7;
  wire g_io_out_hasHalfValid_8;
  wire i_io_out_hasHalfValid_8;
  wire g_io_out_hasHalfValid_9;
  wire i_io_out_hasHalfValid_9;
  wire g_io_out_hasHalfValid_10;
  wire i_io_out_hasHalfValid_10;
  wire g_io_out_hasHalfValid_11;
  wire i_io_out_hasHalfValid_11;
  wire g_io_out_hasHalfValid_12;
  wire i_io_out_hasHalfValid_12;
  wire g_io_out_hasHalfValid_13;
  wire i_io_out_hasHalfValid_13;
  wire g_io_out_hasHalfValid_14;
  wire i_io_out_hasHalfValid_14;
  wire g_io_out_hasHalfValid_15;
  wire i_io_out_hasHalfValid_15;
  wire [31:0] g_io_out_instr_0;
  wire [31:0] i_io_out_instr_0;
  wire [31:0] g_io_out_instr_1;
  wire [31:0] i_io_out_instr_1;
  wire [31:0] g_io_out_instr_2;
  wire [31:0] i_io_out_instr_2;
  wire [31:0] g_io_out_instr_3;
  wire [31:0] i_io_out_instr_3;
  wire [31:0] g_io_out_instr_4;
  wire [31:0] i_io_out_instr_4;
  wire [31:0] g_io_out_instr_5;
  wire [31:0] i_io_out_instr_5;
  wire [31:0] g_io_out_instr_6;
  wire [31:0] i_io_out_instr_6;
  wire [31:0] g_io_out_instr_7;
  wire [31:0] i_io_out_instr_7;
  wire [31:0] g_io_out_instr_8;
  wire [31:0] i_io_out_instr_8;
  wire [31:0] g_io_out_instr_9;
  wire [31:0] i_io_out_instr_9;
  wire [31:0] g_io_out_instr_10;
  wire [31:0] i_io_out_instr_10;
  wire [31:0] g_io_out_instr_11;
  wire [31:0] i_io_out_instr_11;
  wire [31:0] g_io_out_instr_12;
  wire [31:0] i_io_out_instr_12;
  wire [31:0] g_io_out_instr_13;
  wire [31:0] i_io_out_instr_13;
  wire [31:0] g_io_out_instr_14;
  wire [31:0] i_io_out_instr_14;
  wire [31:0] g_io_out_instr_15;
  wire [31:0] i_io_out_instr_15;
  wire [63:0] g_io_out_jumpOffset_0;
  wire [63:0] i_io_out_jumpOffset_0;
  wire [63:0] g_io_out_jumpOffset_1;
  wire [63:0] i_io_out_jumpOffset_1;
  wire [63:0] g_io_out_jumpOffset_2;
  wire [63:0] i_io_out_jumpOffset_2;
  wire [63:0] g_io_out_jumpOffset_3;
  wire [63:0] i_io_out_jumpOffset_3;
  wire [63:0] g_io_out_jumpOffset_4;
  wire [63:0] i_io_out_jumpOffset_4;
  wire [63:0] g_io_out_jumpOffset_5;
  wire [63:0] i_io_out_jumpOffset_5;
  wire [63:0] g_io_out_jumpOffset_6;
  wire [63:0] i_io_out_jumpOffset_6;
  wire [63:0] g_io_out_jumpOffset_7;
  wire [63:0] i_io_out_jumpOffset_7;
  wire [63:0] g_io_out_jumpOffset_8;
  wire [63:0] i_io_out_jumpOffset_8;
  wire [63:0] g_io_out_jumpOffset_9;
  wire [63:0] i_io_out_jumpOffset_9;
  wire [63:0] g_io_out_jumpOffset_10;
  wire [63:0] i_io_out_jumpOffset_10;
  wire [63:0] g_io_out_jumpOffset_11;
  wire [63:0] i_io_out_jumpOffset_11;
  wire [63:0] g_io_out_jumpOffset_12;
  wire [63:0] i_io_out_jumpOffset_12;
  wire [63:0] g_io_out_jumpOffset_13;
  wire [63:0] i_io_out_jumpOffset_13;
  wire [63:0] g_io_out_jumpOffset_14;
  wire [63:0] i_io_out_jumpOffset_14;
  wire [63:0] g_io_out_jumpOffset_15;
  wire [63:0] i_io_out_jumpOffset_15;
  PreDecode    u_g (.io_in_valid(io_in_valid), .io_in_bits_data_0(io_in_bits_data_0), .io_in_bits_data_1(io_in_bits_data_1), .io_in_bits_data_2(io_in_bits_data_2), .io_in_bits_data_3(io_in_bits_data_3), .io_in_bits_data_4(io_in_bits_data_4), .io_in_bits_data_5(io_in_bits_data_5), .io_in_bits_data_6(io_in_bits_data_6), .io_in_bits_data_7(io_in_bits_data_7), .io_in_bits_data_8(io_in_bits_data_8), .io_in_bits_data_9(io_in_bits_data_9), .io_in_bits_data_10(io_in_bits_data_10), .io_in_bits_data_11(io_in_bits_data_11), .io_in_bits_data_12(io_in_bits_data_12), .io_in_bits_data_13(io_in_bits_data_13), .io_in_bits_data_14(io_in_bits_data_14), .io_in_bits_data_15(io_in_bits_data_15), .io_in_bits_data_16(io_in_bits_data_16), .clock(1'b0), .reset(1'b0), .io_out_pd_0_isRVC(g_io_out_pd_0_isRVC), .io_out_pd_0_brType(g_io_out_pd_0_brType), .io_out_pd_0_isCall(g_io_out_pd_0_isCall), .io_out_pd_0_isRet(g_io_out_pd_0_isRet), .io_out_pd_1_valid(g_io_out_pd_1_valid), .io_out_pd_1_isRVC(g_io_out_pd_1_isRVC), .io_out_pd_1_brType(g_io_out_pd_1_brType), .io_out_pd_1_isCall(g_io_out_pd_1_isCall), .io_out_pd_1_isRet(g_io_out_pd_1_isRet), .io_out_pd_2_valid(g_io_out_pd_2_valid), .io_out_pd_2_isRVC(g_io_out_pd_2_isRVC), .io_out_pd_2_brType(g_io_out_pd_2_brType), .io_out_pd_2_isCall(g_io_out_pd_2_isCall), .io_out_pd_2_isRet(g_io_out_pd_2_isRet), .io_out_pd_3_valid(g_io_out_pd_3_valid), .io_out_pd_3_isRVC(g_io_out_pd_3_isRVC), .io_out_pd_3_brType(g_io_out_pd_3_brType), .io_out_pd_3_isCall(g_io_out_pd_3_isCall), .io_out_pd_3_isRet(g_io_out_pd_3_isRet), .io_out_pd_4_valid(g_io_out_pd_4_valid), .io_out_pd_4_isRVC(g_io_out_pd_4_isRVC), .io_out_pd_4_brType(g_io_out_pd_4_brType), .io_out_pd_4_isCall(g_io_out_pd_4_isCall), .io_out_pd_4_isRet(g_io_out_pd_4_isRet), .io_out_pd_5_valid(g_io_out_pd_5_valid), .io_out_pd_5_isRVC(g_io_out_pd_5_isRVC), .io_out_pd_5_brType(g_io_out_pd_5_brType), .io_out_pd_5_isCall(g_io_out_pd_5_isCall), .io_out_pd_5_isRet(g_io_out_pd_5_isRet), .io_out_pd_6_valid(g_io_out_pd_6_valid), .io_out_pd_6_isRVC(g_io_out_pd_6_isRVC), .io_out_pd_6_brType(g_io_out_pd_6_brType), .io_out_pd_6_isCall(g_io_out_pd_6_isCall), .io_out_pd_6_isRet(g_io_out_pd_6_isRet), .io_out_pd_7_valid(g_io_out_pd_7_valid), .io_out_pd_7_isRVC(g_io_out_pd_7_isRVC), .io_out_pd_7_brType(g_io_out_pd_7_brType), .io_out_pd_7_isCall(g_io_out_pd_7_isCall), .io_out_pd_7_isRet(g_io_out_pd_7_isRet), .io_out_pd_8_valid(g_io_out_pd_8_valid), .io_out_pd_8_isRVC(g_io_out_pd_8_isRVC), .io_out_pd_8_brType(g_io_out_pd_8_brType), .io_out_pd_8_isCall(g_io_out_pd_8_isCall), .io_out_pd_8_isRet(g_io_out_pd_8_isRet), .io_out_pd_9_valid(g_io_out_pd_9_valid), .io_out_pd_9_isRVC(g_io_out_pd_9_isRVC), .io_out_pd_9_brType(g_io_out_pd_9_brType), .io_out_pd_9_isCall(g_io_out_pd_9_isCall), .io_out_pd_9_isRet(g_io_out_pd_9_isRet), .io_out_pd_10_valid(g_io_out_pd_10_valid), .io_out_pd_10_isRVC(g_io_out_pd_10_isRVC), .io_out_pd_10_brType(g_io_out_pd_10_brType), .io_out_pd_10_isCall(g_io_out_pd_10_isCall), .io_out_pd_10_isRet(g_io_out_pd_10_isRet), .io_out_pd_11_valid(g_io_out_pd_11_valid), .io_out_pd_11_isRVC(g_io_out_pd_11_isRVC), .io_out_pd_11_brType(g_io_out_pd_11_brType), .io_out_pd_11_isCall(g_io_out_pd_11_isCall), .io_out_pd_11_isRet(g_io_out_pd_11_isRet), .io_out_pd_12_valid(g_io_out_pd_12_valid), .io_out_pd_12_isRVC(g_io_out_pd_12_isRVC), .io_out_pd_12_brType(g_io_out_pd_12_brType), .io_out_pd_12_isCall(g_io_out_pd_12_isCall), .io_out_pd_12_isRet(g_io_out_pd_12_isRet), .io_out_pd_13_valid(g_io_out_pd_13_valid), .io_out_pd_13_isRVC(g_io_out_pd_13_isRVC), .io_out_pd_13_brType(g_io_out_pd_13_brType), .io_out_pd_13_isCall(g_io_out_pd_13_isCall), .io_out_pd_13_isRet(g_io_out_pd_13_isRet), .io_out_pd_14_valid(g_io_out_pd_14_valid), .io_out_pd_14_isRVC(g_io_out_pd_14_isRVC), .io_out_pd_14_brType(g_io_out_pd_14_brType), .io_out_pd_14_isCall(g_io_out_pd_14_isCall), .io_out_pd_14_isRet(g_io_out_pd_14_isRet), .io_out_pd_15_valid(g_io_out_pd_15_valid), .io_out_pd_15_isRVC(g_io_out_pd_15_isRVC), .io_out_pd_15_brType(g_io_out_pd_15_brType), .io_out_pd_15_isCall(g_io_out_pd_15_isCall), .io_out_pd_15_isRet(g_io_out_pd_15_isRet), .io_out_hasHalfValid_2(g_io_out_hasHalfValid_2), .io_out_hasHalfValid_3(g_io_out_hasHalfValid_3), .io_out_hasHalfValid_4(g_io_out_hasHalfValid_4), .io_out_hasHalfValid_5(g_io_out_hasHalfValid_5), .io_out_hasHalfValid_6(g_io_out_hasHalfValid_6), .io_out_hasHalfValid_7(g_io_out_hasHalfValid_7), .io_out_hasHalfValid_8(g_io_out_hasHalfValid_8), .io_out_hasHalfValid_9(g_io_out_hasHalfValid_9), .io_out_hasHalfValid_10(g_io_out_hasHalfValid_10), .io_out_hasHalfValid_11(g_io_out_hasHalfValid_11), .io_out_hasHalfValid_12(g_io_out_hasHalfValid_12), .io_out_hasHalfValid_13(g_io_out_hasHalfValid_13), .io_out_hasHalfValid_14(g_io_out_hasHalfValid_14), .io_out_hasHalfValid_15(g_io_out_hasHalfValid_15), .io_out_instr_0(g_io_out_instr_0), .io_out_instr_1(g_io_out_instr_1), .io_out_instr_2(g_io_out_instr_2), .io_out_instr_3(g_io_out_instr_3), .io_out_instr_4(g_io_out_instr_4), .io_out_instr_5(g_io_out_instr_5), .io_out_instr_6(g_io_out_instr_6), .io_out_instr_7(g_io_out_instr_7), .io_out_instr_8(g_io_out_instr_8), .io_out_instr_9(g_io_out_instr_9), .io_out_instr_10(g_io_out_instr_10), .io_out_instr_11(g_io_out_instr_11), .io_out_instr_12(g_io_out_instr_12), .io_out_instr_13(g_io_out_instr_13), .io_out_instr_14(g_io_out_instr_14), .io_out_instr_15(g_io_out_instr_15), .io_out_jumpOffset_0(g_io_out_jumpOffset_0), .io_out_jumpOffset_1(g_io_out_jumpOffset_1), .io_out_jumpOffset_2(g_io_out_jumpOffset_2), .io_out_jumpOffset_3(g_io_out_jumpOffset_3), .io_out_jumpOffset_4(g_io_out_jumpOffset_4), .io_out_jumpOffset_5(g_io_out_jumpOffset_5), .io_out_jumpOffset_6(g_io_out_jumpOffset_6), .io_out_jumpOffset_7(g_io_out_jumpOffset_7), .io_out_jumpOffset_8(g_io_out_jumpOffset_8), .io_out_jumpOffset_9(g_io_out_jumpOffset_9), .io_out_jumpOffset_10(g_io_out_jumpOffset_10), .io_out_jumpOffset_11(g_io_out_jumpOffset_11), .io_out_jumpOffset_12(g_io_out_jumpOffset_12), .io_out_jumpOffset_13(g_io_out_jumpOffset_13), .io_out_jumpOffset_14(g_io_out_jumpOffset_14), .io_out_jumpOffset_15(g_io_out_jumpOffset_15));
  PreDecode_xs u_i (.io_in_valid(io_in_valid), .io_in_bits_data_0(io_in_bits_data_0), .io_in_bits_data_1(io_in_bits_data_1), .io_in_bits_data_2(io_in_bits_data_2), .io_in_bits_data_3(io_in_bits_data_3), .io_in_bits_data_4(io_in_bits_data_4), .io_in_bits_data_5(io_in_bits_data_5), .io_in_bits_data_6(io_in_bits_data_6), .io_in_bits_data_7(io_in_bits_data_7), .io_in_bits_data_8(io_in_bits_data_8), .io_in_bits_data_9(io_in_bits_data_9), .io_in_bits_data_10(io_in_bits_data_10), .io_in_bits_data_11(io_in_bits_data_11), .io_in_bits_data_12(io_in_bits_data_12), .io_in_bits_data_13(io_in_bits_data_13), .io_in_bits_data_14(io_in_bits_data_14), .io_in_bits_data_15(io_in_bits_data_15), .io_in_bits_data_16(io_in_bits_data_16), .clock(1'b0), .reset(1'b0), .io_out_pd_0_isRVC(i_io_out_pd_0_isRVC), .io_out_pd_0_brType(i_io_out_pd_0_brType), .io_out_pd_0_isCall(i_io_out_pd_0_isCall), .io_out_pd_0_isRet(i_io_out_pd_0_isRet), .io_out_pd_1_valid(i_io_out_pd_1_valid), .io_out_pd_1_isRVC(i_io_out_pd_1_isRVC), .io_out_pd_1_brType(i_io_out_pd_1_brType), .io_out_pd_1_isCall(i_io_out_pd_1_isCall), .io_out_pd_1_isRet(i_io_out_pd_1_isRet), .io_out_pd_2_valid(i_io_out_pd_2_valid), .io_out_pd_2_isRVC(i_io_out_pd_2_isRVC), .io_out_pd_2_brType(i_io_out_pd_2_brType), .io_out_pd_2_isCall(i_io_out_pd_2_isCall), .io_out_pd_2_isRet(i_io_out_pd_2_isRet), .io_out_pd_3_valid(i_io_out_pd_3_valid), .io_out_pd_3_isRVC(i_io_out_pd_3_isRVC), .io_out_pd_3_brType(i_io_out_pd_3_brType), .io_out_pd_3_isCall(i_io_out_pd_3_isCall), .io_out_pd_3_isRet(i_io_out_pd_3_isRet), .io_out_pd_4_valid(i_io_out_pd_4_valid), .io_out_pd_4_isRVC(i_io_out_pd_4_isRVC), .io_out_pd_4_brType(i_io_out_pd_4_brType), .io_out_pd_4_isCall(i_io_out_pd_4_isCall), .io_out_pd_4_isRet(i_io_out_pd_4_isRet), .io_out_pd_5_valid(i_io_out_pd_5_valid), .io_out_pd_5_isRVC(i_io_out_pd_5_isRVC), .io_out_pd_5_brType(i_io_out_pd_5_brType), .io_out_pd_5_isCall(i_io_out_pd_5_isCall), .io_out_pd_5_isRet(i_io_out_pd_5_isRet), .io_out_pd_6_valid(i_io_out_pd_6_valid), .io_out_pd_6_isRVC(i_io_out_pd_6_isRVC), .io_out_pd_6_brType(i_io_out_pd_6_brType), .io_out_pd_6_isCall(i_io_out_pd_6_isCall), .io_out_pd_6_isRet(i_io_out_pd_6_isRet), .io_out_pd_7_valid(i_io_out_pd_7_valid), .io_out_pd_7_isRVC(i_io_out_pd_7_isRVC), .io_out_pd_7_brType(i_io_out_pd_7_brType), .io_out_pd_7_isCall(i_io_out_pd_7_isCall), .io_out_pd_7_isRet(i_io_out_pd_7_isRet), .io_out_pd_8_valid(i_io_out_pd_8_valid), .io_out_pd_8_isRVC(i_io_out_pd_8_isRVC), .io_out_pd_8_brType(i_io_out_pd_8_brType), .io_out_pd_8_isCall(i_io_out_pd_8_isCall), .io_out_pd_8_isRet(i_io_out_pd_8_isRet), .io_out_pd_9_valid(i_io_out_pd_9_valid), .io_out_pd_9_isRVC(i_io_out_pd_9_isRVC), .io_out_pd_9_brType(i_io_out_pd_9_brType), .io_out_pd_9_isCall(i_io_out_pd_9_isCall), .io_out_pd_9_isRet(i_io_out_pd_9_isRet), .io_out_pd_10_valid(i_io_out_pd_10_valid), .io_out_pd_10_isRVC(i_io_out_pd_10_isRVC), .io_out_pd_10_brType(i_io_out_pd_10_brType), .io_out_pd_10_isCall(i_io_out_pd_10_isCall), .io_out_pd_10_isRet(i_io_out_pd_10_isRet), .io_out_pd_11_valid(i_io_out_pd_11_valid), .io_out_pd_11_isRVC(i_io_out_pd_11_isRVC), .io_out_pd_11_brType(i_io_out_pd_11_brType), .io_out_pd_11_isCall(i_io_out_pd_11_isCall), .io_out_pd_11_isRet(i_io_out_pd_11_isRet), .io_out_pd_12_valid(i_io_out_pd_12_valid), .io_out_pd_12_isRVC(i_io_out_pd_12_isRVC), .io_out_pd_12_brType(i_io_out_pd_12_brType), .io_out_pd_12_isCall(i_io_out_pd_12_isCall), .io_out_pd_12_isRet(i_io_out_pd_12_isRet), .io_out_pd_13_valid(i_io_out_pd_13_valid), .io_out_pd_13_isRVC(i_io_out_pd_13_isRVC), .io_out_pd_13_brType(i_io_out_pd_13_brType), .io_out_pd_13_isCall(i_io_out_pd_13_isCall), .io_out_pd_13_isRet(i_io_out_pd_13_isRet), .io_out_pd_14_valid(i_io_out_pd_14_valid), .io_out_pd_14_isRVC(i_io_out_pd_14_isRVC), .io_out_pd_14_brType(i_io_out_pd_14_brType), .io_out_pd_14_isCall(i_io_out_pd_14_isCall), .io_out_pd_14_isRet(i_io_out_pd_14_isRet), .io_out_pd_15_valid(i_io_out_pd_15_valid), .io_out_pd_15_isRVC(i_io_out_pd_15_isRVC), .io_out_pd_15_brType(i_io_out_pd_15_brType), .io_out_pd_15_isCall(i_io_out_pd_15_isCall), .io_out_pd_15_isRet(i_io_out_pd_15_isRet), .io_out_hasHalfValid_2(i_io_out_hasHalfValid_2), .io_out_hasHalfValid_3(i_io_out_hasHalfValid_3), .io_out_hasHalfValid_4(i_io_out_hasHalfValid_4), .io_out_hasHalfValid_5(i_io_out_hasHalfValid_5), .io_out_hasHalfValid_6(i_io_out_hasHalfValid_6), .io_out_hasHalfValid_7(i_io_out_hasHalfValid_7), .io_out_hasHalfValid_8(i_io_out_hasHalfValid_8), .io_out_hasHalfValid_9(i_io_out_hasHalfValid_9), .io_out_hasHalfValid_10(i_io_out_hasHalfValid_10), .io_out_hasHalfValid_11(i_io_out_hasHalfValid_11), .io_out_hasHalfValid_12(i_io_out_hasHalfValid_12), .io_out_hasHalfValid_13(i_io_out_hasHalfValid_13), .io_out_hasHalfValid_14(i_io_out_hasHalfValid_14), .io_out_hasHalfValid_15(i_io_out_hasHalfValid_15), .io_out_instr_0(i_io_out_instr_0), .io_out_instr_1(i_io_out_instr_1), .io_out_instr_2(i_io_out_instr_2), .io_out_instr_3(i_io_out_instr_3), .io_out_instr_4(i_io_out_instr_4), .io_out_instr_5(i_io_out_instr_5), .io_out_instr_6(i_io_out_instr_6), .io_out_instr_7(i_io_out_instr_7), .io_out_instr_8(i_io_out_instr_8), .io_out_instr_9(i_io_out_instr_9), .io_out_instr_10(i_io_out_instr_10), .io_out_instr_11(i_io_out_instr_11), .io_out_instr_12(i_io_out_instr_12), .io_out_instr_13(i_io_out_instr_13), .io_out_instr_14(i_io_out_instr_14), .io_out_instr_15(i_io_out_instr_15), .io_out_jumpOffset_0(i_io_out_jumpOffset_0), .io_out_jumpOffset_1(i_io_out_jumpOffset_1), .io_out_jumpOffset_2(i_io_out_jumpOffset_2), .io_out_jumpOffset_3(i_io_out_jumpOffset_3), .io_out_jumpOffset_4(i_io_out_jumpOffset_4), .io_out_jumpOffset_5(i_io_out_jumpOffset_5), .io_out_jumpOffset_6(i_io_out_jumpOffset_6), .io_out_jumpOffset_7(i_io_out_jumpOffset_7), .io_out_jumpOffset_8(i_io_out_jumpOffset_8), .io_out_jumpOffset_9(i_io_out_jumpOffset_9), .io_out_jumpOffset_10(i_io_out_jumpOffset_10), .io_out_jumpOffset_11(i_io_out_jumpOffset_11), .io_out_jumpOffset_12(i_io_out_jumpOffset_12), .io_out_jumpOffset_13(i_io_out_jumpOffset_13), .io_out_jumpOffset_14(i_io_out_jumpOffset_14), .io_out_jumpOffset_15(i_io_out_jumpOffset_15));
  initial begin
    for (int t = 0; t < NVEC; t++) begin
      io_in_valid = 1'($urandom);
      io_in_bits_data_0 = 16'($urandom);
      io_in_bits_data_1 = 16'($urandom);
      io_in_bits_data_2 = 16'($urandom);
      io_in_bits_data_3 = 16'($urandom);
      io_in_bits_data_4 = 16'($urandom);
      io_in_bits_data_5 = 16'($urandom);
      io_in_bits_data_6 = 16'($urandom);
      io_in_bits_data_7 = 16'($urandom);
      io_in_bits_data_8 = 16'($urandom);
      io_in_bits_data_9 = 16'($urandom);
      io_in_bits_data_10 = 16'($urandom);
      io_in_bits_data_11 = 16'($urandom);
      io_in_bits_data_12 = 16'($urandom);
      io_in_bits_data_13 = 16'($urandom);
      io_in_bits_data_14 = 16'($urandom);
      io_in_bits_data_15 = 16'($urandom);
      io_in_bits_data_16 = 16'($urandom);
      #1; checks++;
      if (g_io_out_pd_0_isRVC !== i_io_out_pd_0_isRVC) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_0_isRVC: g=%h i=%h", t, g_io_out_pd_0_isRVC, i_io_out_pd_0_isRVC); end
      if (g_io_out_pd_0_brType !== i_io_out_pd_0_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_0_brType: g=%h i=%h", t, g_io_out_pd_0_brType, i_io_out_pd_0_brType); end
      if (g_io_out_pd_0_isCall !== i_io_out_pd_0_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_0_isCall: g=%h i=%h", t, g_io_out_pd_0_isCall, i_io_out_pd_0_isCall); end
      if (g_io_out_pd_0_isRet !== i_io_out_pd_0_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_0_isRet: g=%h i=%h", t, g_io_out_pd_0_isRet, i_io_out_pd_0_isRet); end
      if (g_io_out_pd_1_valid !== i_io_out_pd_1_valid) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_1_valid: g=%h i=%h", t, g_io_out_pd_1_valid, i_io_out_pd_1_valid); end
      if (g_io_out_pd_1_isRVC !== i_io_out_pd_1_isRVC) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_1_isRVC: g=%h i=%h", t, g_io_out_pd_1_isRVC, i_io_out_pd_1_isRVC); end
      if (g_io_out_pd_1_brType !== i_io_out_pd_1_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_1_brType: g=%h i=%h", t, g_io_out_pd_1_brType, i_io_out_pd_1_brType); end
      if (g_io_out_pd_1_isCall !== i_io_out_pd_1_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_1_isCall: g=%h i=%h", t, g_io_out_pd_1_isCall, i_io_out_pd_1_isCall); end
      if (g_io_out_pd_1_isRet !== i_io_out_pd_1_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_1_isRet: g=%h i=%h", t, g_io_out_pd_1_isRet, i_io_out_pd_1_isRet); end
      if (g_io_out_pd_2_valid !== i_io_out_pd_2_valid) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_2_valid: g=%h i=%h", t, g_io_out_pd_2_valid, i_io_out_pd_2_valid); end
      if (g_io_out_pd_2_isRVC !== i_io_out_pd_2_isRVC) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_2_isRVC: g=%h i=%h", t, g_io_out_pd_2_isRVC, i_io_out_pd_2_isRVC); end
      if (g_io_out_pd_2_brType !== i_io_out_pd_2_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_2_brType: g=%h i=%h", t, g_io_out_pd_2_brType, i_io_out_pd_2_brType); end
      if (g_io_out_pd_2_isCall !== i_io_out_pd_2_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_2_isCall: g=%h i=%h", t, g_io_out_pd_2_isCall, i_io_out_pd_2_isCall); end
      if (g_io_out_pd_2_isRet !== i_io_out_pd_2_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_2_isRet: g=%h i=%h", t, g_io_out_pd_2_isRet, i_io_out_pd_2_isRet); end
      if (g_io_out_pd_3_valid !== i_io_out_pd_3_valid) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_3_valid: g=%h i=%h", t, g_io_out_pd_3_valid, i_io_out_pd_3_valid); end
      if (g_io_out_pd_3_isRVC !== i_io_out_pd_3_isRVC) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_3_isRVC: g=%h i=%h", t, g_io_out_pd_3_isRVC, i_io_out_pd_3_isRVC); end
      if (g_io_out_pd_3_brType !== i_io_out_pd_3_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_3_brType: g=%h i=%h", t, g_io_out_pd_3_brType, i_io_out_pd_3_brType); end
      if (g_io_out_pd_3_isCall !== i_io_out_pd_3_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_3_isCall: g=%h i=%h", t, g_io_out_pd_3_isCall, i_io_out_pd_3_isCall); end
      if (g_io_out_pd_3_isRet !== i_io_out_pd_3_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_3_isRet: g=%h i=%h", t, g_io_out_pd_3_isRet, i_io_out_pd_3_isRet); end
      if (g_io_out_pd_4_valid !== i_io_out_pd_4_valid) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_4_valid: g=%h i=%h", t, g_io_out_pd_4_valid, i_io_out_pd_4_valid); end
      if (g_io_out_pd_4_isRVC !== i_io_out_pd_4_isRVC) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_4_isRVC: g=%h i=%h", t, g_io_out_pd_4_isRVC, i_io_out_pd_4_isRVC); end
      if (g_io_out_pd_4_brType !== i_io_out_pd_4_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_4_brType: g=%h i=%h", t, g_io_out_pd_4_brType, i_io_out_pd_4_brType); end
      if (g_io_out_pd_4_isCall !== i_io_out_pd_4_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_4_isCall: g=%h i=%h", t, g_io_out_pd_4_isCall, i_io_out_pd_4_isCall); end
      if (g_io_out_pd_4_isRet !== i_io_out_pd_4_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_4_isRet: g=%h i=%h", t, g_io_out_pd_4_isRet, i_io_out_pd_4_isRet); end
      if (g_io_out_pd_5_valid !== i_io_out_pd_5_valid) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_5_valid: g=%h i=%h", t, g_io_out_pd_5_valid, i_io_out_pd_5_valid); end
      if (g_io_out_pd_5_isRVC !== i_io_out_pd_5_isRVC) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_5_isRVC: g=%h i=%h", t, g_io_out_pd_5_isRVC, i_io_out_pd_5_isRVC); end
      if (g_io_out_pd_5_brType !== i_io_out_pd_5_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_5_brType: g=%h i=%h", t, g_io_out_pd_5_brType, i_io_out_pd_5_brType); end
      if (g_io_out_pd_5_isCall !== i_io_out_pd_5_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_5_isCall: g=%h i=%h", t, g_io_out_pd_5_isCall, i_io_out_pd_5_isCall); end
      if (g_io_out_pd_5_isRet !== i_io_out_pd_5_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_5_isRet: g=%h i=%h", t, g_io_out_pd_5_isRet, i_io_out_pd_5_isRet); end
      if (g_io_out_pd_6_valid !== i_io_out_pd_6_valid) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_6_valid: g=%h i=%h", t, g_io_out_pd_6_valid, i_io_out_pd_6_valid); end
      if (g_io_out_pd_6_isRVC !== i_io_out_pd_6_isRVC) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_6_isRVC: g=%h i=%h", t, g_io_out_pd_6_isRVC, i_io_out_pd_6_isRVC); end
      if (g_io_out_pd_6_brType !== i_io_out_pd_6_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_6_brType: g=%h i=%h", t, g_io_out_pd_6_brType, i_io_out_pd_6_brType); end
      if (g_io_out_pd_6_isCall !== i_io_out_pd_6_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_6_isCall: g=%h i=%h", t, g_io_out_pd_6_isCall, i_io_out_pd_6_isCall); end
      if (g_io_out_pd_6_isRet !== i_io_out_pd_6_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_6_isRet: g=%h i=%h", t, g_io_out_pd_6_isRet, i_io_out_pd_6_isRet); end
      if (g_io_out_pd_7_valid !== i_io_out_pd_7_valid) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_7_valid: g=%h i=%h", t, g_io_out_pd_7_valid, i_io_out_pd_7_valid); end
      if (g_io_out_pd_7_isRVC !== i_io_out_pd_7_isRVC) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_7_isRVC: g=%h i=%h", t, g_io_out_pd_7_isRVC, i_io_out_pd_7_isRVC); end
      if (g_io_out_pd_7_brType !== i_io_out_pd_7_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_7_brType: g=%h i=%h", t, g_io_out_pd_7_brType, i_io_out_pd_7_brType); end
      if (g_io_out_pd_7_isCall !== i_io_out_pd_7_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_7_isCall: g=%h i=%h", t, g_io_out_pd_7_isCall, i_io_out_pd_7_isCall); end
      if (g_io_out_pd_7_isRet !== i_io_out_pd_7_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_7_isRet: g=%h i=%h", t, g_io_out_pd_7_isRet, i_io_out_pd_7_isRet); end
      if (g_io_out_pd_8_valid !== i_io_out_pd_8_valid) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_8_valid: g=%h i=%h", t, g_io_out_pd_8_valid, i_io_out_pd_8_valid); end
      if (g_io_out_pd_8_isRVC !== i_io_out_pd_8_isRVC) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_8_isRVC: g=%h i=%h", t, g_io_out_pd_8_isRVC, i_io_out_pd_8_isRVC); end
      if (g_io_out_pd_8_brType !== i_io_out_pd_8_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_8_brType: g=%h i=%h", t, g_io_out_pd_8_brType, i_io_out_pd_8_brType); end
      if (g_io_out_pd_8_isCall !== i_io_out_pd_8_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_8_isCall: g=%h i=%h", t, g_io_out_pd_8_isCall, i_io_out_pd_8_isCall); end
      if (g_io_out_pd_8_isRet !== i_io_out_pd_8_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_8_isRet: g=%h i=%h", t, g_io_out_pd_8_isRet, i_io_out_pd_8_isRet); end
      if (g_io_out_pd_9_valid !== i_io_out_pd_9_valid) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_9_valid: g=%h i=%h", t, g_io_out_pd_9_valid, i_io_out_pd_9_valid); end
      if (g_io_out_pd_9_isRVC !== i_io_out_pd_9_isRVC) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_9_isRVC: g=%h i=%h", t, g_io_out_pd_9_isRVC, i_io_out_pd_9_isRVC); end
      if (g_io_out_pd_9_brType !== i_io_out_pd_9_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_9_brType: g=%h i=%h", t, g_io_out_pd_9_brType, i_io_out_pd_9_brType); end
      if (g_io_out_pd_9_isCall !== i_io_out_pd_9_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_9_isCall: g=%h i=%h", t, g_io_out_pd_9_isCall, i_io_out_pd_9_isCall); end
      if (g_io_out_pd_9_isRet !== i_io_out_pd_9_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_9_isRet: g=%h i=%h", t, g_io_out_pd_9_isRet, i_io_out_pd_9_isRet); end
      if (g_io_out_pd_10_valid !== i_io_out_pd_10_valid) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_10_valid: g=%h i=%h", t, g_io_out_pd_10_valid, i_io_out_pd_10_valid); end
      if (g_io_out_pd_10_isRVC !== i_io_out_pd_10_isRVC) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_10_isRVC: g=%h i=%h", t, g_io_out_pd_10_isRVC, i_io_out_pd_10_isRVC); end
      if (g_io_out_pd_10_brType !== i_io_out_pd_10_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_10_brType: g=%h i=%h", t, g_io_out_pd_10_brType, i_io_out_pd_10_brType); end
      if (g_io_out_pd_10_isCall !== i_io_out_pd_10_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_10_isCall: g=%h i=%h", t, g_io_out_pd_10_isCall, i_io_out_pd_10_isCall); end
      if (g_io_out_pd_10_isRet !== i_io_out_pd_10_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_10_isRet: g=%h i=%h", t, g_io_out_pd_10_isRet, i_io_out_pd_10_isRet); end
      if (g_io_out_pd_11_valid !== i_io_out_pd_11_valid) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_11_valid: g=%h i=%h", t, g_io_out_pd_11_valid, i_io_out_pd_11_valid); end
      if (g_io_out_pd_11_isRVC !== i_io_out_pd_11_isRVC) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_11_isRVC: g=%h i=%h", t, g_io_out_pd_11_isRVC, i_io_out_pd_11_isRVC); end
      if (g_io_out_pd_11_brType !== i_io_out_pd_11_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_11_brType: g=%h i=%h", t, g_io_out_pd_11_brType, i_io_out_pd_11_brType); end
      if (g_io_out_pd_11_isCall !== i_io_out_pd_11_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_11_isCall: g=%h i=%h", t, g_io_out_pd_11_isCall, i_io_out_pd_11_isCall); end
      if (g_io_out_pd_11_isRet !== i_io_out_pd_11_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_11_isRet: g=%h i=%h", t, g_io_out_pd_11_isRet, i_io_out_pd_11_isRet); end
      if (g_io_out_pd_12_valid !== i_io_out_pd_12_valid) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_12_valid: g=%h i=%h", t, g_io_out_pd_12_valid, i_io_out_pd_12_valid); end
      if (g_io_out_pd_12_isRVC !== i_io_out_pd_12_isRVC) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_12_isRVC: g=%h i=%h", t, g_io_out_pd_12_isRVC, i_io_out_pd_12_isRVC); end
      if (g_io_out_pd_12_brType !== i_io_out_pd_12_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_12_brType: g=%h i=%h", t, g_io_out_pd_12_brType, i_io_out_pd_12_brType); end
      if (g_io_out_pd_12_isCall !== i_io_out_pd_12_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_12_isCall: g=%h i=%h", t, g_io_out_pd_12_isCall, i_io_out_pd_12_isCall); end
      if (g_io_out_pd_12_isRet !== i_io_out_pd_12_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_12_isRet: g=%h i=%h", t, g_io_out_pd_12_isRet, i_io_out_pd_12_isRet); end
      if (g_io_out_pd_13_valid !== i_io_out_pd_13_valid) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_13_valid: g=%h i=%h", t, g_io_out_pd_13_valid, i_io_out_pd_13_valid); end
      if (g_io_out_pd_13_isRVC !== i_io_out_pd_13_isRVC) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_13_isRVC: g=%h i=%h", t, g_io_out_pd_13_isRVC, i_io_out_pd_13_isRVC); end
      if (g_io_out_pd_13_brType !== i_io_out_pd_13_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_13_brType: g=%h i=%h", t, g_io_out_pd_13_brType, i_io_out_pd_13_brType); end
      if (g_io_out_pd_13_isCall !== i_io_out_pd_13_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_13_isCall: g=%h i=%h", t, g_io_out_pd_13_isCall, i_io_out_pd_13_isCall); end
      if (g_io_out_pd_13_isRet !== i_io_out_pd_13_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_13_isRet: g=%h i=%h", t, g_io_out_pd_13_isRet, i_io_out_pd_13_isRet); end
      if (g_io_out_pd_14_valid !== i_io_out_pd_14_valid) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_14_valid: g=%h i=%h", t, g_io_out_pd_14_valid, i_io_out_pd_14_valid); end
      if (g_io_out_pd_14_isRVC !== i_io_out_pd_14_isRVC) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_14_isRVC: g=%h i=%h", t, g_io_out_pd_14_isRVC, i_io_out_pd_14_isRVC); end
      if (g_io_out_pd_14_brType !== i_io_out_pd_14_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_14_brType: g=%h i=%h", t, g_io_out_pd_14_brType, i_io_out_pd_14_brType); end
      if (g_io_out_pd_14_isCall !== i_io_out_pd_14_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_14_isCall: g=%h i=%h", t, g_io_out_pd_14_isCall, i_io_out_pd_14_isCall); end
      if (g_io_out_pd_14_isRet !== i_io_out_pd_14_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_14_isRet: g=%h i=%h", t, g_io_out_pd_14_isRet, i_io_out_pd_14_isRet); end
      if (g_io_out_pd_15_valid !== i_io_out_pd_15_valid) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_15_valid: g=%h i=%h", t, g_io_out_pd_15_valid, i_io_out_pd_15_valid); end
      if (g_io_out_pd_15_isRVC !== i_io_out_pd_15_isRVC) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_15_isRVC: g=%h i=%h", t, g_io_out_pd_15_isRVC, i_io_out_pd_15_isRVC); end
      if (g_io_out_pd_15_brType !== i_io_out_pd_15_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_15_brType: g=%h i=%h", t, g_io_out_pd_15_brType, i_io_out_pd_15_brType); end
      if (g_io_out_pd_15_isCall !== i_io_out_pd_15_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_15_isCall: g=%h i=%h", t, g_io_out_pd_15_isCall, i_io_out_pd_15_isCall); end
      if (g_io_out_pd_15_isRet !== i_io_out_pd_15_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_15_isRet: g=%h i=%h", t, g_io_out_pd_15_isRet, i_io_out_pd_15_isRet); end
      if (g_io_out_hasHalfValid_2 !== i_io_out_hasHalfValid_2) begin errors++;
        if (errors<=20) $display("vec %0d io_out_hasHalfValid_2: g=%h i=%h", t, g_io_out_hasHalfValid_2, i_io_out_hasHalfValid_2); end
      if (g_io_out_hasHalfValid_3 !== i_io_out_hasHalfValid_3) begin errors++;
        if (errors<=20) $display("vec %0d io_out_hasHalfValid_3: g=%h i=%h", t, g_io_out_hasHalfValid_3, i_io_out_hasHalfValid_3); end
      if (g_io_out_hasHalfValid_4 !== i_io_out_hasHalfValid_4) begin errors++;
        if (errors<=20) $display("vec %0d io_out_hasHalfValid_4: g=%h i=%h", t, g_io_out_hasHalfValid_4, i_io_out_hasHalfValid_4); end
      if (g_io_out_hasHalfValid_5 !== i_io_out_hasHalfValid_5) begin errors++;
        if (errors<=20) $display("vec %0d io_out_hasHalfValid_5: g=%h i=%h", t, g_io_out_hasHalfValid_5, i_io_out_hasHalfValid_5); end
      if (g_io_out_hasHalfValid_6 !== i_io_out_hasHalfValid_6) begin errors++;
        if (errors<=20) $display("vec %0d io_out_hasHalfValid_6: g=%h i=%h", t, g_io_out_hasHalfValid_6, i_io_out_hasHalfValid_6); end
      if (g_io_out_hasHalfValid_7 !== i_io_out_hasHalfValid_7) begin errors++;
        if (errors<=20) $display("vec %0d io_out_hasHalfValid_7: g=%h i=%h", t, g_io_out_hasHalfValid_7, i_io_out_hasHalfValid_7); end
      if (g_io_out_hasHalfValid_8 !== i_io_out_hasHalfValid_8) begin errors++;
        if (errors<=20) $display("vec %0d io_out_hasHalfValid_8: g=%h i=%h", t, g_io_out_hasHalfValid_8, i_io_out_hasHalfValid_8); end
      if (g_io_out_hasHalfValid_9 !== i_io_out_hasHalfValid_9) begin errors++;
        if (errors<=20) $display("vec %0d io_out_hasHalfValid_9: g=%h i=%h", t, g_io_out_hasHalfValid_9, i_io_out_hasHalfValid_9); end
      if (g_io_out_hasHalfValid_10 !== i_io_out_hasHalfValid_10) begin errors++;
        if (errors<=20) $display("vec %0d io_out_hasHalfValid_10: g=%h i=%h", t, g_io_out_hasHalfValid_10, i_io_out_hasHalfValid_10); end
      if (g_io_out_hasHalfValid_11 !== i_io_out_hasHalfValid_11) begin errors++;
        if (errors<=20) $display("vec %0d io_out_hasHalfValid_11: g=%h i=%h", t, g_io_out_hasHalfValid_11, i_io_out_hasHalfValid_11); end
      if (g_io_out_hasHalfValid_12 !== i_io_out_hasHalfValid_12) begin errors++;
        if (errors<=20) $display("vec %0d io_out_hasHalfValid_12: g=%h i=%h", t, g_io_out_hasHalfValid_12, i_io_out_hasHalfValid_12); end
      if (g_io_out_hasHalfValid_13 !== i_io_out_hasHalfValid_13) begin errors++;
        if (errors<=20) $display("vec %0d io_out_hasHalfValid_13: g=%h i=%h", t, g_io_out_hasHalfValid_13, i_io_out_hasHalfValid_13); end
      if (g_io_out_hasHalfValid_14 !== i_io_out_hasHalfValid_14) begin errors++;
        if (errors<=20) $display("vec %0d io_out_hasHalfValid_14: g=%h i=%h", t, g_io_out_hasHalfValid_14, i_io_out_hasHalfValid_14); end
      if (g_io_out_hasHalfValid_15 !== i_io_out_hasHalfValid_15) begin errors++;
        if (errors<=20) $display("vec %0d io_out_hasHalfValid_15: g=%h i=%h", t, g_io_out_hasHalfValid_15, i_io_out_hasHalfValid_15); end
      if (g_io_out_instr_0 !== i_io_out_instr_0) begin errors++;
        if (errors<=20) $display("vec %0d io_out_instr_0: g=%h i=%h", t, g_io_out_instr_0, i_io_out_instr_0); end
      if (g_io_out_instr_1 !== i_io_out_instr_1) begin errors++;
        if (errors<=20) $display("vec %0d io_out_instr_1: g=%h i=%h", t, g_io_out_instr_1, i_io_out_instr_1); end
      if (g_io_out_instr_2 !== i_io_out_instr_2) begin errors++;
        if (errors<=20) $display("vec %0d io_out_instr_2: g=%h i=%h", t, g_io_out_instr_2, i_io_out_instr_2); end
      if (g_io_out_instr_3 !== i_io_out_instr_3) begin errors++;
        if (errors<=20) $display("vec %0d io_out_instr_3: g=%h i=%h", t, g_io_out_instr_3, i_io_out_instr_3); end
      if (g_io_out_instr_4 !== i_io_out_instr_4) begin errors++;
        if (errors<=20) $display("vec %0d io_out_instr_4: g=%h i=%h", t, g_io_out_instr_4, i_io_out_instr_4); end
      if (g_io_out_instr_5 !== i_io_out_instr_5) begin errors++;
        if (errors<=20) $display("vec %0d io_out_instr_5: g=%h i=%h", t, g_io_out_instr_5, i_io_out_instr_5); end
      if (g_io_out_instr_6 !== i_io_out_instr_6) begin errors++;
        if (errors<=20) $display("vec %0d io_out_instr_6: g=%h i=%h", t, g_io_out_instr_6, i_io_out_instr_6); end
      if (g_io_out_instr_7 !== i_io_out_instr_7) begin errors++;
        if (errors<=20) $display("vec %0d io_out_instr_7: g=%h i=%h", t, g_io_out_instr_7, i_io_out_instr_7); end
      if (g_io_out_instr_8 !== i_io_out_instr_8) begin errors++;
        if (errors<=20) $display("vec %0d io_out_instr_8: g=%h i=%h", t, g_io_out_instr_8, i_io_out_instr_8); end
      if (g_io_out_instr_9 !== i_io_out_instr_9) begin errors++;
        if (errors<=20) $display("vec %0d io_out_instr_9: g=%h i=%h", t, g_io_out_instr_9, i_io_out_instr_9); end
      if (g_io_out_instr_10 !== i_io_out_instr_10) begin errors++;
        if (errors<=20) $display("vec %0d io_out_instr_10: g=%h i=%h", t, g_io_out_instr_10, i_io_out_instr_10); end
      if (g_io_out_instr_11 !== i_io_out_instr_11) begin errors++;
        if (errors<=20) $display("vec %0d io_out_instr_11: g=%h i=%h", t, g_io_out_instr_11, i_io_out_instr_11); end
      if (g_io_out_instr_12 !== i_io_out_instr_12) begin errors++;
        if (errors<=20) $display("vec %0d io_out_instr_12: g=%h i=%h", t, g_io_out_instr_12, i_io_out_instr_12); end
      if (g_io_out_instr_13 !== i_io_out_instr_13) begin errors++;
        if (errors<=20) $display("vec %0d io_out_instr_13: g=%h i=%h", t, g_io_out_instr_13, i_io_out_instr_13); end
      if (g_io_out_instr_14 !== i_io_out_instr_14) begin errors++;
        if (errors<=20) $display("vec %0d io_out_instr_14: g=%h i=%h", t, g_io_out_instr_14, i_io_out_instr_14); end
      if (g_io_out_instr_15 !== i_io_out_instr_15) begin errors++;
        if (errors<=20) $display("vec %0d io_out_instr_15: g=%h i=%h", t, g_io_out_instr_15, i_io_out_instr_15); end
      if (g_io_out_jumpOffset_0 !== i_io_out_jumpOffset_0) begin errors++;
        if (errors<=20) $display("vec %0d io_out_jumpOffset_0: g=%h i=%h", t, g_io_out_jumpOffset_0, i_io_out_jumpOffset_0); end
      if (g_io_out_jumpOffset_1 !== i_io_out_jumpOffset_1) begin errors++;
        if (errors<=20) $display("vec %0d io_out_jumpOffset_1: g=%h i=%h", t, g_io_out_jumpOffset_1, i_io_out_jumpOffset_1); end
      if (g_io_out_jumpOffset_2 !== i_io_out_jumpOffset_2) begin errors++;
        if (errors<=20) $display("vec %0d io_out_jumpOffset_2: g=%h i=%h", t, g_io_out_jumpOffset_2, i_io_out_jumpOffset_2); end
      if (g_io_out_jumpOffset_3 !== i_io_out_jumpOffset_3) begin errors++;
        if (errors<=20) $display("vec %0d io_out_jumpOffset_3: g=%h i=%h", t, g_io_out_jumpOffset_3, i_io_out_jumpOffset_3); end
      if (g_io_out_jumpOffset_4 !== i_io_out_jumpOffset_4) begin errors++;
        if (errors<=20) $display("vec %0d io_out_jumpOffset_4: g=%h i=%h", t, g_io_out_jumpOffset_4, i_io_out_jumpOffset_4); end
      if (g_io_out_jumpOffset_5 !== i_io_out_jumpOffset_5) begin errors++;
        if (errors<=20) $display("vec %0d io_out_jumpOffset_5: g=%h i=%h", t, g_io_out_jumpOffset_5, i_io_out_jumpOffset_5); end
      if (g_io_out_jumpOffset_6 !== i_io_out_jumpOffset_6) begin errors++;
        if (errors<=20) $display("vec %0d io_out_jumpOffset_6: g=%h i=%h", t, g_io_out_jumpOffset_6, i_io_out_jumpOffset_6); end
      if (g_io_out_jumpOffset_7 !== i_io_out_jumpOffset_7) begin errors++;
        if (errors<=20) $display("vec %0d io_out_jumpOffset_7: g=%h i=%h", t, g_io_out_jumpOffset_7, i_io_out_jumpOffset_7); end
      if (g_io_out_jumpOffset_8 !== i_io_out_jumpOffset_8) begin errors++;
        if (errors<=20) $display("vec %0d io_out_jumpOffset_8: g=%h i=%h", t, g_io_out_jumpOffset_8, i_io_out_jumpOffset_8); end
      if (g_io_out_jumpOffset_9 !== i_io_out_jumpOffset_9) begin errors++;
        if (errors<=20) $display("vec %0d io_out_jumpOffset_9: g=%h i=%h", t, g_io_out_jumpOffset_9, i_io_out_jumpOffset_9); end
      if (g_io_out_jumpOffset_10 !== i_io_out_jumpOffset_10) begin errors++;
        if (errors<=20) $display("vec %0d io_out_jumpOffset_10: g=%h i=%h", t, g_io_out_jumpOffset_10, i_io_out_jumpOffset_10); end
      if (g_io_out_jumpOffset_11 !== i_io_out_jumpOffset_11) begin errors++;
        if (errors<=20) $display("vec %0d io_out_jumpOffset_11: g=%h i=%h", t, g_io_out_jumpOffset_11, i_io_out_jumpOffset_11); end
      if (g_io_out_jumpOffset_12 !== i_io_out_jumpOffset_12) begin errors++;
        if (errors<=20) $display("vec %0d io_out_jumpOffset_12: g=%h i=%h", t, g_io_out_jumpOffset_12, i_io_out_jumpOffset_12); end
      if (g_io_out_jumpOffset_13 !== i_io_out_jumpOffset_13) begin errors++;
        if (errors<=20) $display("vec %0d io_out_jumpOffset_13: g=%h i=%h", t, g_io_out_jumpOffset_13, i_io_out_jumpOffset_13); end
      if (g_io_out_jumpOffset_14 !== i_io_out_jumpOffset_14) begin errors++;
        if (errors<=20) $display("vec %0d io_out_jumpOffset_14: g=%h i=%h", t, g_io_out_jumpOffset_14, i_io_out_jumpOffset_14); end
      if (g_io_out_jumpOffset_15 !== i_io_out_jumpOffset_15) begin errors++;
        if (errors<=20) $display("vec %0d io_out_jumpOffset_15: g=%h i=%h", t, g_io_out_jumpOffset_15, i_io_out_jumpOffset_15); end
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
