// 自动生成：scripts/gen_f3predecoder.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NVEC = 200000;
  int errors = 0, checks = 0;

  logic [31:0] io_in_instr_0;
  logic [31:0] io_in_instr_1;
  logic [31:0] io_in_instr_2;
  logic [31:0] io_in_instr_3;
  logic [31:0] io_in_instr_4;
  logic [31:0] io_in_instr_5;
  logic [31:0] io_in_instr_6;
  logic [31:0] io_in_instr_7;
  logic [31:0] io_in_instr_8;
  logic [31:0] io_in_instr_9;
  logic [31:0] io_in_instr_10;
  logic [31:0] io_in_instr_11;
  logic [31:0] io_in_instr_12;
  logic [31:0] io_in_instr_13;
  logic [31:0] io_in_instr_14;
  logic [31:0] io_in_instr_15;
  wire [1:0] g_io_out_pd_0_brType;
  wire [1:0] i_io_out_pd_0_brType;
  wire g_io_out_pd_0_isCall;
  wire i_io_out_pd_0_isCall;
  wire g_io_out_pd_0_isRet;
  wire i_io_out_pd_0_isRet;
  wire [1:0] g_io_out_pd_1_brType;
  wire [1:0] i_io_out_pd_1_brType;
  wire g_io_out_pd_1_isCall;
  wire i_io_out_pd_1_isCall;
  wire g_io_out_pd_1_isRet;
  wire i_io_out_pd_1_isRet;
  wire [1:0] g_io_out_pd_2_brType;
  wire [1:0] i_io_out_pd_2_brType;
  wire g_io_out_pd_2_isCall;
  wire i_io_out_pd_2_isCall;
  wire g_io_out_pd_2_isRet;
  wire i_io_out_pd_2_isRet;
  wire [1:0] g_io_out_pd_3_brType;
  wire [1:0] i_io_out_pd_3_brType;
  wire g_io_out_pd_3_isCall;
  wire i_io_out_pd_3_isCall;
  wire g_io_out_pd_3_isRet;
  wire i_io_out_pd_3_isRet;
  wire [1:0] g_io_out_pd_4_brType;
  wire [1:0] i_io_out_pd_4_brType;
  wire g_io_out_pd_4_isCall;
  wire i_io_out_pd_4_isCall;
  wire g_io_out_pd_4_isRet;
  wire i_io_out_pd_4_isRet;
  wire [1:0] g_io_out_pd_5_brType;
  wire [1:0] i_io_out_pd_5_brType;
  wire g_io_out_pd_5_isCall;
  wire i_io_out_pd_5_isCall;
  wire g_io_out_pd_5_isRet;
  wire i_io_out_pd_5_isRet;
  wire [1:0] g_io_out_pd_6_brType;
  wire [1:0] i_io_out_pd_6_brType;
  wire g_io_out_pd_6_isCall;
  wire i_io_out_pd_6_isCall;
  wire g_io_out_pd_6_isRet;
  wire i_io_out_pd_6_isRet;
  wire [1:0] g_io_out_pd_7_brType;
  wire [1:0] i_io_out_pd_7_brType;
  wire g_io_out_pd_7_isCall;
  wire i_io_out_pd_7_isCall;
  wire g_io_out_pd_7_isRet;
  wire i_io_out_pd_7_isRet;
  wire [1:0] g_io_out_pd_8_brType;
  wire [1:0] i_io_out_pd_8_brType;
  wire g_io_out_pd_8_isCall;
  wire i_io_out_pd_8_isCall;
  wire g_io_out_pd_8_isRet;
  wire i_io_out_pd_8_isRet;
  wire [1:0] g_io_out_pd_9_brType;
  wire [1:0] i_io_out_pd_9_brType;
  wire g_io_out_pd_9_isCall;
  wire i_io_out_pd_9_isCall;
  wire g_io_out_pd_9_isRet;
  wire i_io_out_pd_9_isRet;
  wire [1:0] g_io_out_pd_10_brType;
  wire [1:0] i_io_out_pd_10_brType;
  wire g_io_out_pd_10_isCall;
  wire i_io_out_pd_10_isCall;
  wire g_io_out_pd_10_isRet;
  wire i_io_out_pd_10_isRet;
  wire [1:0] g_io_out_pd_11_brType;
  wire [1:0] i_io_out_pd_11_brType;
  wire g_io_out_pd_11_isCall;
  wire i_io_out_pd_11_isCall;
  wire g_io_out_pd_11_isRet;
  wire i_io_out_pd_11_isRet;
  wire [1:0] g_io_out_pd_12_brType;
  wire [1:0] i_io_out_pd_12_brType;
  wire g_io_out_pd_12_isCall;
  wire i_io_out_pd_12_isCall;
  wire g_io_out_pd_12_isRet;
  wire i_io_out_pd_12_isRet;
  wire [1:0] g_io_out_pd_13_brType;
  wire [1:0] i_io_out_pd_13_brType;
  wire g_io_out_pd_13_isCall;
  wire i_io_out_pd_13_isCall;
  wire g_io_out_pd_13_isRet;
  wire i_io_out_pd_13_isRet;
  wire [1:0] g_io_out_pd_14_brType;
  wire [1:0] i_io_out_pd_14_brType;
  wire g_io_out_pd_14_isCall;
  wire i_io_out_pd_14_isCall;
  wire g_io_out_pd_14_isRet;
  wire i_io_out_pd_14_isRet;
  wire [1:0] g_io_out_pd_15_brType;
  wire [1:0] i_io_out_pd_15_brType;
  wire g_io_out_pd_15_isCall;
  wire i_io_out_pd_15_isCall;
  wire g_io_out_pd_15_isRet;
  wire i_io_out_pd_15_isRet;
  F3Predecoder    u_g (.io_in_instr_0(io_in_instr_0), .io_in_instr_1(io_in_instr_1), .io_in_instr_2(io_in_instr_2), .io_in_instr_3(io_in_instr_3), .io_in_instr_4(io_in_instr_4), .io_in_instr_5(io_in_instr_5), .io_in_instr_6(io_in_instr_6), .io_in_instr_7(io_in_instr_7), .io_in_instr_8(io_in_instr_8), .io_in_instr_9(io_in_instr_9), .io_in_instr_10(io_in_instr_10), .io_in_instr_11(io_in_instr_11), .io_in_instr_12(io_in_instr_12), .io_in_instr_13(io_in_instr_13), .io_in_instr_14(io_in_instr_14), .io_in_instr_15(io_in_instr_15), .io_out_pd_0_brType(g_io_out_pd_0_brType), .io_out_pd_0_isCall(g_io_out_pd_0_isCall), .io_out_pd_0_isRet(g_io_out_pd_0_isRet), .io_out_pd_1_brType(g_io_out_pd_1_brType), .io_out_pd_1_isCall(g_io_out_pd_1_isCall), .io_out_pd_1_isRet(g_io_out_pd_1_isRet), .io_out_pd_2_brType(g_io_out_pd_2_brType), .io_out_pd_2_isCall(g_io_out_pd_2_isCall), .io_out_pd_2_isRet(g_io_out_pd_2_isRet), .io_out_pd_3_brType(g_io_out_pd_3_brType), .io_out_pd_3_isCall(g_io_out_pd_3_isCall), .io_out_pd_3_isRet(g_io_out_pd_3_isRet), .io_out_pd_4_brType(g_io_out_pd_4_brType), .io_out_pd_4_isCall(g_io_out_pd_4_isCall), .io_out_pd_4_isRet(g_io_out_pd_4_isRet), .io_out_pd_5_brType(g_io_out_pd_5_brType), .io_out_pd_5_isCall(g_io_out_pd_5_isCall), .io_out_pd_5_isRet(g_io_out_pd_5_isRet), .io_out_pd_6_brType(g_io_out_pd_6_brType), .io_out_pd_6_isCall(g_io_out_pd_6_isCall), .io_out_pd_6_isRet(g_io_out_pd_6_isRet), .io_out_pd_7_brType(g_io_out_pd_7_brType), .io_out_pd_7_isCall(g_io_out_pd_7_isCall), .io_out_pd_7_isRet(g_io_out_pd_7_isRet), .io_out_pd_8_brType(g_io_out_pd_8_brType), .io_out_pd_8_isCall(g_io_out_pd_8_isCall), .io_out_pd_8_isRet(g_io_out_pd_8_isRet), .io_out_pd_9_brType(g_io_out_pd_9_brType), .io_out_pd_9_isCall(g_io_out_pd_9_isCall), .io_out_pd_9_isRet(g_io_out_pd_9_isRet), .io_out_pd_10_brType(g_io_out_pd_10_brType), .io_out_pd_10_isCall(g_io_out_pd_10_isCall), .io_out_pd_10_isRet(g_io_out_pd_10_isRet), .io_out_pd_11_brType(g_io_out_pd_11_brType), .io_out_pd_11_isCall(g_io_out_pd_11_isCall), .io_out_pd_11_isRet(g_io_out_pd_11_isRet), .io_out_pd_12_brType(g_io_out_pd_12_brType), .io_out_pd_12_isCall(g_io_out_pd_12_isCall), .io_out_pd_12_isRet(g_io_out_pd_12_isRet), .io_out_pd_13_brType(g_io_out_pd_13_brType), .io_out_pd_13_isCall(g_io_out_pd_13_isCall), .io_out_pd_13_isRet(g_io_out_pd_13_isRet), .io_out_pd_14_brType(g_io_out_pd_14_brType), .io_out_pd_14_isCall(g_io_out_pd_14_isCall), .io_out_pd_14_isRet(g_io_out_pd_14_isRet), .io_out_pd_15_brType(g_io_out_pd_15_brType), .io_out_pd_15_isCall(g_io_out_pd_15_isCall), .io_out_pd_15_isRet(g_io_out_pd_15_isRet));
  F3Predecoder_xs u_i (.io_in_instr_0(io_in_instr_0), .io_in_instr_1(io_in_instr_1), .io_in_instr_2(io_in_instr_2), .io_in_instr_3(io_in_instr_3), .io_in_instr_4(io_in_instr_4), .io_in_instr_5(io_in_instr_5), .io_in_instr_6(io_in_instr_6), .io_in_instr_7(io_in_instr_7), .io_in_instr_8(io_in_instr_8), .io_in_instr_9(io_in_instr_9), .io_in_instr_10(io_in_instr_10), .io_in_instr_11(io_in_instr_11), .io_in_instr_12(io_in_instr_12), .io_in_instr_13(io_in_instr_13), .io_in_instr_14(io_in_instr_14), .io_in_instr_15(io_in_instr_15), .io_out_pd_0_brType(i_io_out_pd_0_brType), .io_out_pd_0_isCall(i_io_out_pd_0_isCall), .io_out_pd_0_isRet(i_io_out_pd_0_isRet), .io_out_pd_1_brType(i_io_out_pd_1_brType), .io_out_pd_1_isCall(i_io_out_pd_1_isCall), .io_out_pd_1_isRet(i_io_out_pd_1_isRet), .io_out_pd_2_brType(i_io_out_pd_2_brType), .io_out_pd_2_isCall(i_io_out_pd_2_isCall), .io_out_pd_2_isRet(i_io_out_pd_2_isRet), .io_out_pd_3_brType(i_io_out_pd_3_brType), .io_out_pd_3_isCall(i_io_out_pd_3_isCall), .io_out_pd_3_isRet(i_io_out_pd_3_isRet), .io_out_pd_4_brType(i_io_out_pd_4_brType), .io_out_pd_4_isCall(i_io_out_pd_4_isCall), .io_out_pd_4_isRet(i_io_out_pd_4_isRet), .io_out_pd_5_brType(i_io_out_pd_5_brType), .io_out_pd_5_isCall(i_io_out_pd_5_isCall), .io_out_pd_5_isRet(i_io_out_pd_5_isRet), .io_out_pd_6_brType(i_io_out_pd_6_brType), .io_out_pd_6_isCall(i_io_out_pd_6_isCall), .io_out_pd_6_isRet(i_io_out_pd_6_isRet), .io_out_pd_7_brType(i_io_out_pd_7_brType), .io_out_pd_7_isCall(i_io_out_pd_7_isCall), .io_out_pd_7_isRet(i_io_out_pd_7_isRet), .io_out_pd_8_brType(i_io_out_pd_8_brType), .io_out_pd_8_isCall(i_io_out_pd_8_isCall), .io_out_pd_8_isRet(i_io_out_pd_8_isRet), .io_out_pd_9_brType(i_io_out_pd_9_brType), .io_out_pd_9_isCall(i_io_out_pd_9_isCall), .io_out_pd_9_isRet(i_io_out_pd_9_isRet), .io_out_pd_10_brType(i_io_out_pd_10_brType), .io_out_pd_10_isCall(i_io_out_pd_10_isCall), .io_out_pd_10_isRet(i_io_out_pd_10_isRet), .io_out_pd_11_brType(i_io_out_pd_11_brType), .io_out_pd_11_isCall(i_io_out_pd_11_isCall), .io_out_pd_11_isRet(i_io_out_pd_11_isRet), .io_out_pd_12_brType(i_io_out_pd_12_brType), .io_out_pd_12_isCall(i_io_out_pd_12_isCall), .io_out_pd_12_isRet(i_io_out_pd_12_isRet), .io_out_pd_13_brType(i_io_out_pd_13_brType), .io_out_pd_13_isCall(i_io_out_pd_13_isCall), .io_out_pd_13_isRet(i_io_out_pd_13_isRet), .io_out_pd_14_brType(i_io_out_pd_14_brType), .io_out_pd_14_isCall(i_io_out_pd_14_isCall), .io_out_pd_14_isRet(i_io_out_pd_14_isRet), .io_out_pd_15_brType(i_io_out_pd_15_brType), .io_out_pd_15_isCall(i_io_out_pd_15_isCall), .io_out_pd_15_isRet(i_io_out_pd_15_isRet));
  initial begin
    for (int t = 0; t < NVEC; t++) begin
      io_in_instr_0 = 32'($urandom);
      io_in_instr_1 = 32'($urandom);
      io_in_instr_2 = 32'($urandom);
      io_in_instr_3 = 32'($urandom);
      io_in_instr_4 = 32'($urandom);
      io_in_instr_5 = 32'($urandom);
      io_in_instr_6 = 32'($urandom);
      io_in_instr_7 = 32'($urandom);
      io_in_instr_8 = 32'($urandom);
      io_in_instr_9 = 32'($urandom);
      io_in_instr_10 = 32'($urandom);
      io_in_instr_11 = 32'($urandom);
      io_in_instr_12 = 32'($urandom);
      io_in_instr_13 = 32'($urandom);
      io_in_instr_14 = 32'($urandom);
      io_in_instr_15 = 32'($urandom);
      #1; checks++;
      if (g_io_out_pd_0_brType !== i_io_out_pd_0_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_0_brType: g=%h i=%h", t, g_io_out_pd_0_brType, i_io_out_pd_0_brType); end
      if (g_io_out_pd_0_isCall !== i_io_out_pd_0_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_0_isCall: g=%h i=%h", t, g_io_out_pd_0_isCall, i_io_out_pd_0_isCall); end
      if (g_io_out_pd_0_isRet !== i_io_out_pd_0_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_0_isRet: g=%h i=%h", t, g_io_out_pd_0_isRet, i_io_out_pd_0_isRet); end
      if (g_io_out_pd_1_brType !== i_io_out_pd_1_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_1_brType: g=%h i=%h", t, g_io_out_pd_1_brType, i_io_out_pd_1_brType); end
      if (g_io_out_pd_1_isCall !== i_io_out_pd_1_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_1_isCall: g=%h i=%h", t, g_io_out_pd_1_isCall, i_io_out_pd_1_isCall); end
      if (g_io_out_pd_1_isRet !== i_io_out_pd_1_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_1_isRet: g=%h i=%h", t, g_io_out_pd_1_isRet, i_io_out_pd_1_isRet); end
      if (g_io_out_pd_2_brType !== i_io_out_pd_2_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_2_brType: g=%h i=%h", t, g_io_out_pd_2_brType, i_io_out_pd_2_brType); end
      if (g_io_out_pd_2_isCall !== i_io_out_pd_2_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_2_isCall: g=%h i=%h", t, g_io_out_pd_2_isCall, i_io_out_pd_2_isCall); end
      if (g_io_out_pd_2_isRet !== i_io_out_pd_2_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_2_isRet: g=%h i=%h", t, g_io_out_pd_2_isRet, i_io_out_pd_2_isRet); end
      if (g_io_out_pd_3_brType !== i_io_out_pd_3_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_3_brType: g=%h i=%h", t, g_io_out_pd_3_brType, i_io_out_pd_3_brType); end
      if (g_io_out_pd_3_isCall !== i_io_out_pd_3_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_3_isCall: g=%h i=%h", t, g_io_out_pd_3_isCall, i_io_out_pd_3_isCall); end
      if (g_io_out_pd_3_isRet !== i_io_out_pd_3_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_3_isRet: g=%h i=%h", t, g_io_out_pd_3_isRet, i_io_out_pd_3_isRet); end
      if (g_io_out_pd_4_brType !== i_io_out_pd_4_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_4_brType: g=%h i=%h", t, g_io_out_pd_4_brType, i_io_out_pd_4_brType); end
      if (g_io_out_pd_4_isCall !== i_io_out_pd_4_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_4_isCall: g=%h i=%h", t, g_io_out_pd_4_isCall, i_io_out_pd_4_isCall); end
      if (g_io_out_pd_4_isRet !== i_io_out_pd_4_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_4_isRet: g=%h i=%h", t, g_io_out_pd_4_isRet, i_io_out_pd_4_isRet); end
      if (g_io_out_pd_5_brType !== i_io_out_pd_5_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_5_brType: g=%h i=%h", t, g_io_out_pd_5_brType, i_io_out_pd_5_brType); end
      if (g_io_out_pd_5_isCall !== i_io_out_pd_5_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_5_isCall: g=%h i=%h", t, g_io_out_pd_5_isCall, i_io_out_pd_5_isCall); end
      if (g_io_out_pd_5_isRet !== i_io_out_pd_5_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_5_isRet: g=%h i=%h", t, g_io_out_pd_5_isRet, i_io_out_pd_5_isRet); end
      if (g_io_out_pd_6_brType !== i_io_out_pd_6_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_6_brType: g=%h i=%h", t, g_io_out_pd_6_brType, i_io_out_pd_6_brType); end
      if (g_io_out_pd_6_isCall !== i_io_out_pd_6_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_6_isCall: g=%h i=%h", t, g_io_out_pd_6_isCall, i_io_out_pd_6_isCall); end
      if (g_io_out_pd_6_isRet !== i_io_out_pd_6_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_6_isRet: g=%h i=%h", t, g_io_out_pd_6_isRet, i_io_out_pd_6_isRet); end
      if (g_io_out_pd_7_brType !== i_io_out_pd_7_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_7_brType: g=%h i=%h", t, g_io_out_pd_7_brType, i_io_out_pd_7_brType); end
      if (g_io_out_pd_7_isCall !== i_io_out_pd_7_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_7_isCall: g=%h i=%h", t, g_io_out_pd_7_isCall, i_io_out_pd_7_isCall); end
      if (g_io_out_pd_7_isRet !== i_io_out_pd_7_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_7_isRet: g=%h i=%h", t, g_io_out_pd_7_isRet, i_io_out_pd_7_isRet); end
      if (g_io_out_pd_8_brType !== i_io_out_pd_8_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_8_brType: g=%h i=%h", t, g_io_out_pd_8_brType, i_io_out_pd_8_brType); end
      if (g_io_out_pd_8_isCall !== i_io_out_pd_8_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_8_isCall: g=%h i=%h", t, g_io_out_pd_8_isCall, i_io_out_pd_8_isCall); end
      if (g_io_out_pd_8_isRet !== i_io_out_pd_8_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_8_isRet: g=%h i=%h", t, g_io_out_pd_8_isRet, i_io_out_pd_8_isRet); end
      if (g_io_out_pd_9_brType !== i_io_out_pd_9_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_9_brType: g=%h i=%h", t, g_io_out_pd_9_brType, i_io_out_pd_9_brType); end
      if (g_io_out_pd_9_isCall !== i_io_out_pd_9_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_9_isCall: g=%h i=%h", t, g_io_out_pd_9_isCall, i_io_out_pd_9_isCall); end
      if (g_io_out_pd_9_isRet !== i_io_out_pd_9_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_9_isRet: g=%h i=%h", t, g_io_out_pd_9_isRet, i_io_out_pd_9_isRet); end
      if (g_io_out_pd_10_brType !== i_io_out_pd_10_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_10_brType: g=%h i=%h", t, g_io_out_pd_10_brType, i_io_out_pd_10_brType); end
      if (g_io_out_pd_10_isCall !== i_io_out_pd_10_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_10_isCall: g=%h i=%h", t, g_io_out_pd_10_isCall, i_io_out_pd_10_isCall); end
      if (g_io_out_pd_10_isRet !== i_io_out_pd_10_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_10_isRet: g=%h i=%h", t, g_io_out_pd_10_isRet, i_io_out_pd_10_isRet); end
      if (g_io_out_pd_11_brType !== i_io_out_pd_11_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_11_brType: g=%h i=%h", t, g_io_out_pd_11_brType, i_io_out_pd_11_brType); end
      if (g_io_out_pd_11_isCall !== i_io_out_pd_11_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_11_isCall: g=%h i=%h", t, g_io_out_pd_11_isCall, i_io_out_pd_11_isCall); end
      if (g_io_out_pd_11_isRet !== i_io_out_pd_11_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_11_isRet: g=%h i=%h", t, g_io_out_pd_11_isRet, i_io_out_pd_11_isRet); end
      if (g_io_out_pd_12_brType !== i_io_out_pd_12_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_12_brType: g=%h i=%h", t, g_io_out_pd_12_brType, i_io_out_pd_12_brType); end
      if (g_io_out_pd_12_isCall !== i_io_out_pd_12_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_12_isCall: g=%h i=%h", t, g_io_out_pd_12_isCall, i_io_out_pd_12_isCall); end
      if (g_io_out_pd_12_isRet !== i_io_out_pd_12_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_12_isRet: g=%h i=%h", t, g_io_out_pd_12_isRet, i_io_out_pd_12_isRet); end
      if (g_io_out_pd_13_brType !== i_io_out_pd_13_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_13_brType: g=%h i=%h", t, g_io_out_pd_13_brType, i_io_out_pd_13_brType); end
      if (g_io_out_pd_13_isCall !== i_io_out_pd_13_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_13_isCall: g=%h i=%h", t, g_io_out_pd_13_isCall, i_io_out_pd_13_isCall); end
      if (g_io_out_pd_13_isRet !== i_io_out_pd_13_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_13_isRet: g=%h i=%h", t, g_io_out_pd_13_isRet, i_io_out_pd_13_isRet); end
      if (g_io_out_pd_14_brType !== i_io_out_pd_14_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_14_brType: g=%h i=%h", t, g_io_out_pd_14_brType, i_io_out_pd_14_brType); end
      if (g_io_out_pd_14_isCall !== i_io_out_pd_14_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_14_isCall: g=%h i=%h", t, g_io_out_pd_14_isCall, i_io_out_pd_14_isCall); end
      if (g_io_out_pd_14_isRet !== i_io_out_pd_14_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_14_isRet: g=%h i=%h", t, g_io_out_pd_14_isRet, i_io_out_pd_14_isRet); end
      if (g_io_out_pd_15_brType !== i_io_out_pd_15_brType) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_15_brType: g=%h i=%h", t, g_io_out_pd_15_brType, i_io_out_pd_15_brType); end
      if (g_io_out_pd_15_isCall !== i_io_out_pd_15_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_15_isCall: g=%h i=%h", t, g_io_out_pd_15_isCall, i_io_out_pd_15_isCall); end
      if (g_io_out_pd_15_isRet !== i_io_out_pd_15_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_out_pd_15_isRet: g=%h i=%h", t, g_io_out_pd_15_isRet, i_io_out_pd_15_isRet); end
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
