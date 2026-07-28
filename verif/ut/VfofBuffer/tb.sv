// 自动生成 gen_vfofbuffer.py —— 勿手改。双例化 golden VfofBuffer vs VfofBuffer_xs 逐拍比对。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 8;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic io_redirect_valid;
  logic io_redirect_bits_robIdx_flag;
  logic [7:0] io_redirect_bits_robIdx_value;
  logic io_redirect_bits_level;
  logic io_in_0_valid;
  logic [8:0] io_in_0_bits_uop_fuOpType;
  logic io_in_0_bits_uop_vecWen;
  logic io_in_0_bits_uop_v0Wen;
  logic io_in_0_bits_uop_vlWen;
  logic io_in_0_bits_uop_vpu_vma;
  logic io_in_0_bits_uop_vpu_vta;
  logic [1:0] io_in_0_bits_uop_vpu_vsew;
  logic [2:0] io_in_0_bits_uop_vpu_vlmul;
  logic io_in_0_bits_uop_vpu_vm;
  logic [7:0] io_in_0_bits_uop_vpu_vstart;
  logic [6:0] io_in_0_bits_uop_vpu_vuopIdx;
  logic io_in_0_bits_uop_vpu_lastUop;
  logic [2:0] io_in_0_bits_uop_vpu_nf;
  logic [1:0] io_in_0_bits_uop_vpu_veew;
  logic io_in_0_bits_uop_vpu_isVleff;
  logic [7:0] io_in_0_bits_uop_pdest;
  logic io_in_0_bits_uop_robIdx_flag;
  logic [7:0] io_in_0_bits_uop_robIdx_value;
  logic [63:0] io_in_0_bits_uop_debugInfo_enqRsTime;
  logic [63:0] io_in_0_bits_uop_debugInfo_selectTime;
  logic [63:0] io_in_0_bits_uop_debugInfo_issueTime;
  logic [127:0] io_in_0_bits_src_4;
  logic io_in_1_valid;
  logic [8:0] io_in_1_bits_uop_fuOpType;
  logic io_in_1_bits_uop_vecWen;
  logic io_in_1_bits_uop_v0Wen;
  logic io_in_1_bits_uop_vlWen;
  logic io_in_1_bits_uop_vpu_vma;
  logic io_in_1_bits_uop_vpu_vta;
  logic [1:0] io_in_1_bits_uop_vpu_vsew;
  logic [2:0] io_in_1_bits_uop_vpu_vlmul;
  logic io_in_1_bits_uop_vpu_vm;
  logic [7:0] io_in_1_bits_uop_vpu_vstart;
  logic [6:0] io_in_1_bits_uop_vpu_vuopIdx;
  logic io_in_1_bits_uop_vpu_lastUop;
  logic [2:0] io_in_1_bits_uop_vpu_nf;
  logic [1:0] io_in_1_bits_uop_vpu_veew;
  logic io_in_1_bits_uop_vpu_isVleff;
  logic [7:0] io_in_1_bits_uop_pdest;
  logic io_in_1_bits_uop_robIdx_flag;
  logic [7:0] io_in_1_bits_uop_robIdx_value;
  logic [63:0] io_in_1_bits_uop_debugInfo_enqRsTime;
  logic [63:0] io_in_1_bits_uop_debugInfo_selectTime;
  logic [63:0] io_in_1_bits_uop_debugInfo_issueTime;
  logic [127:0] io_in_1_bits_src_4;
  logic io_mergeUopWriteback_0_valid;
  logic io_mergeUopWriteback_0_bits_uop_exceptionVec_3;
  logic io_mergeUopWriteback_0_bits_uop_exceptionVec_4;
  logic io_mergeUopWriteback_0_bits_uop_exceptionVec_5;
  logic io_mergeUopWriteback_0_bits_uop_exceptionVec_13;
  logic io_mergeUopWriteback_0_bits_uop_exceptionVec_19;
  logic io_mergeUopWriteback_0_bits_uop_exceptionVec_21;
  logic [7:0] io_mergeUopWriteback_0_bits_uop_vpu_vl;
  logic io_mergeUopWriteback_0_bits_uop_robIdx_flag;
  logic [7:0] io_mergeUopWriteback_0_bits_uop_robIdx_value;
  logic io_mergeUopWriteback_1_valid;
  logic io_mergeUopWriteback_1_bits_uop_exceptionVec_3;
  logic io_mergeUopWriteback_1_bits_uop_exceptionVec_4;
  logic io_mergeUopWriteback_1_bits_uop_exceptionVec_5;
  logic io_mergeUopWriteback_1_bits_uop_exceptionVec_13;
  logic io_mergeUopWriteback_1_bits_uop_exceptionVec_19;
  logic io_mergeUopWriteback_1_bits_uop_exceptionVec_21;
  logic [7:0] io_mergeUopWriteback_1_bits_uop_vpu_vl;
  logic io_mergeUopWriteback_1_bits_uop_robIdx_flag;
  logic [7:0] io_mergeUopWriteback_1_bits_uop_robIdx_value;
  logic g_io_uopWriteback_valid;
  logic i_io_uopWriteback_valid;
  logic [8:0] g_io_uopWriteback_bits_uop_fuOpType;
  logic [8:0] i_io_uopWriteback_bits_uop_fuOpType;
  logic g_io_uopWriteback_bits_uop_vecWen;
  logic i_io_uopWriteback_bits_uop_vecWen;
  logic g_io_uopWriteback_bits_uop_v0Wen;
  logic i_io_uopWriteback_bits_uop_v0Wen;
  logic g_io_uopWriteback_bits_uop_vlWen;
  logic i_io_uopWriteback_bits_uop_vlWen;
  logic g_io_uopWriteback_bits_uop_vpu_vma;
  logic i_io_uopWriteback_bits_uop_vpu_vma;
  logic g_io_uopWriteback_bits_uop_vpu_vta;
  logic i_io_uopWriteback_bits_uop_vpu_vta;
  logic [1:0] g_io_uopWriteback_bits_uop_vpu_vsew;
  logic [1:0] i_io_uopWriteback_bits_uop_vpu_vsew;
  logic [2:0] g_io_uopWriteback_bits_uop_vpu_vlmul;
  logic [2:0] i_io_uopWriteback_bits_uop_vpu_vlmul;
  logic g_io_uopWriteback_bits_uop_vpu_vm;
  logic i_io_uopWriteback_bits_uop_vpu_vm;
  logic [7:0] g_io_uopWriteback_bits_uop_vpu_vstart;
  logic [7:0] i_io_uopWriteback_bits_uop_vpu_vstart;
  logic [6:0] g_io_uopWriteback_bits_uop_vpu_vuopIdx;
  logic [6:0] i_io_uopWriteback_bits_uop_vpu_vuopIdx;
  logic [7:0] g_io_uopWriteback_bits_uop_vpu_vl;
  logic [7:0] i_io_uopWriteback_bits_uop_vpu_vl;
  logic [2:0] g_io_uopWriteback_bits_uop_vpu_nf;
  logic [2:0] i_io_uopWriteback_bits_uop_vpu_nf;
  logic [1:0] g_io_uopWriteback_bits_uop_vpu_veew;
  logic [1:0] i_io_uopWriteback_bits_uop_vpu_veew;
  logic [7:0] g_io_uopWriteback_bits_uop_pdest;
  logic [7:0] i_io_uopWriteback_bits_uop_pdest;
  logic g_io_uopWriteback_bits_uop_robIdx_flag;
  logic i_io_uopWriteback_bits_uop_robIdx_flag;
  logic [7:0] g_io_uopWriteback_bits_uop_robIdx_value;
  logic [7:0] i_io_uopWriteback_bits_uop_robIdx_value;
  logic [63:0] g_io_uopWriteback_bits_uop_debugInfo_enqRsTime;
  logic [63:0] i_io_uopWriteback_bits_uop_debugInfo_enqRsTime;
  logic [63:0] g_io_uopWriteback_bits_uop_debugInfo_selectTime;
  logic [63:0] i_io_uopWriteback_bits_uop_debugInfo_selectTime;
  logic [63:0] g_io_uopWriteback_bits_uop_debugInfo_issueTime;
  logic [63:0] i_io_uopWriteback_bits_uop_debugInfo_issueTime;
  logic [127:0] g_io_uopWriteback_bits_data;
  logic [127:0] i_io_uopWriteback_bits_data;

  VfofBuffer u_g (
    .clock(clk), .reset(rst),
    .io_redirect_valid(io_redirect_valid),
    .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value),
    .io_redirect_bits_level(io_redirect_bits_level),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_uop_fuOpType(io_in_0_bits_uop_fuOpType),
    .io_in_0_bits_uop_vecWen(io_in_0_bits_uop_vecWen),
    .io_in_0_bits_uop_v0Wen(io_in_0_bits_uop_v0Wen),
    .io_in_0_bits_uop_vlWen(io_in_0_bits_uop_vlWen),
    .io_in_0_bits_uop_vpu_vma(io_in_0_bits_uop_vpu_vma),
    .io_in_0_bits_uop_vpu_vta(io_in_0_bits_uop_vpu_vta),
    .io_in_0_bits_uop_vpu_vsew(io_in_0_bits_uop_vpu_vsew),
    .io_in_0_bits_uop_vpu_vlmul(io_in_0_bits_uop_vpu_vlmul),
    .io_in_0_bits_uop_vpu_vm(io_in_0_bits_uop_vpu_vm),
    .io_in_0_bits_uop_vpu_vstart(io_in_0_bits_uop_vpu_vstart),
    .io_in_0_bits_uop_vpu_vuopIdx(io_in_0_bits_uop_vpu_vuopIdx),
    .io_in_0_bits_uop_vpu_lastUop(io_in_0_bits_uop_vpu_lastUop),
    .io_in_0_bits_uop_vpu_nf(io_in_0_bits_uop_vpu_nf),
    .io_in_0_bits_uop_vpu_veew(io_in_0_bits_uop_vpu_veew),
    .io_in_0_bits_uop_vpu_isVleff(io_in_0_bits_uop_vpu_isVleff),
    .io_in_0_bits_uop_pdest(io_in_0_bits_uop_pdest),
    .io_in_0_bits_uop_robIdx_flag(io_in_0_bits_uop_robIdx_flag),
    .io_in_0_bits_uop_robIdx_value(io_in_0_bits_uop_robIdx_value),
    .io_in_0_bits_uop_debugInfo_enqRsTime(io_in_0_bits_uop_debugInfo_enqRsTime),
    .io_in_0_bits_uop_debugInfo_selectTime(io_in_0_bits_uop_debugInfo_selectTime),
    .io_in_0_bits_uop_debugInfo_issueTime(io_in_0_bits_uop_debugInfo_issueTime),
    .io_in_0_bits_src_4(io_in_0_bits_src_4),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_uop_fuOpType(io_in_1_bits_uop_fuOpType),
    .io_in_1_bits_uop_vecWen(io_in_1_bits_uop_vecWen),
    .io_in_1_bits_uop_v0Wen(io_in_1_bits_uop_v0Wen),
    .io_in_1_bits_uop_vlWen(io_in_1_bits_uop_vlWen),
    .io_in_1_bits_uop_vpu_vma(io_in_1_bits_uop_vpu_vma),
    .io_in_1_bits_uop_vpu_vta(io_in_1_bits_uop_vpu_vta),
    .io_in_1_bits_uop_vpu_vsew(io_in_1_bits_uop_vpu_vsew),
    .io_in_1_bits_uop_vpu_vlmul(io_in_1_bits_uop_vpu_vlmul),
    .io_in_1_bits_uop_vpu_vm(io_in_1_bits_uop_vpu_vm),
    .io_in_1_bits_uop_vpu_vstart(io_in_1_bits_uop_vpu_vstart),
    .io_in_1_bits_uop_vpu_vuopIdx(io_in_1_bits_uop_vpu_vuopIdx),
    .io_in_1_bits_uop_vpu_lastUop(io_in_1_bits_uop_vpu_lastUop),
    .io_in_1_bits_uop_vpu_nf(io_in_1_bits_uop_vpu_nf),
    .io_in_1_bits_uop_vpu_veew(io_in_1_bits_uop_vpu_veew),
    .io_in_1_bits_uop_vpu_isVleff(io_in_1_bits_uop_vpu_isVleff),
    .io_in_1_bits_uop_pdest(io_in_1_bits_uop_pdest),
    .io_in_1_bits_uop_robIdx_flag(io_in_1_bits_uop_robIdx_flag),
    .io_in_1_bits_uop_robIdx_value(io_in_1_bits_uop_robIdx_value),
    .io_in_1_bits_uop_debugInfo_enqRsTime(io_in_1_bits_uop_debugInfo_enqRsTime),
    .io_in_1_bits_uop_debugInfo_selectTime(io_in_1_bits_uop_debugInfo_selectTime),
    .io_in_1_bits_uop_debugInfo_issueTime(io_in_1_bits_uop_debugInfo_issueTime),
    .io_in_1_bits_src_4(io_in_1_bits_src_4),
    .io_mergeUopWriteback_0_valid(io_mergeUopWriteback_0_valid),
    .io_mergeUopWriteback_0_bits_uop_exceptionVec_3(io_mergeUopWriteback_0_bits_uop_exceptionVec_3),
    .io_mergeUopWriteback_0_bits_uop_exceptionVec_4(io_mergeUopWriteback_0_bits_uop_exceptionVec_4),
    .io_mergeUopWriteback_0_bits_uop_exceptionVec_5(io_mergeUopWriteback_0_bits_uop_exceptionVec_5),
    .io_mergeUopWriteback_0_bits_uop_exceptionVec_13(io_mergeUopWriteback_0_bits_uop_exceptionVec_13),
    .io_mergeUopWriteback_0_bits_uop_exceptionVec_19(io_mergeUopWriteback_0_bits_uop_exceptionVec_19),
    .io_mergeUopWriteback_0_bits_uop_exceptionVec_21(io_mergeUopWriteback_0_bits_uop_exceptionVec_21),
    .io_mergeUopWriteback_0_bits_uop_vpu_vl(io_mergeUopWriteback_0_bits_uop_vpu_vl),
    .io_mergeUopWriteback_0_bits_uop_robIdx_flag(io_mergeUopWriteback_0_bits_uop_robIdx_flag),
    .io_mergeUopWriteback_0_bits_uop_robIdx_value(io_mergeUopWriteback_0_bits_uop_robIdx_value),
    .io_mergeUopWriteback_1_valid(io_mergeUopWriteback_1_valid),
    .io_mergeUopWriteback_1_bits_uop_exceptionVec_3(io_mergeUopWriteback_1_bits_uop_exceptionVec_3),
    .io_mergeUopWriteback_1_bits_uop_exceptionVec_4(io_mergeUopWriteback_1_bits_uop_exceptionVec_4),
    .io_mergeUopWriteback_1_bits_uop_exceptionVec_5(io_mergeUopWriteback_1_bits_uop_exceptionVec_5),
    .io_mergeUopWriteback_1_bits_uop_exceptionVec_13(io_mergeUopWriteback_1_bits_uop_exceptionVec_13),
    .io_mergeUopWriteback_1_bits_uop_exceptionVec_19(io_mergeUopWriteback_1_bits_uop_exceptionVec_19),
    .io_mergeUopWriteback_1_bits_uop_exceptionVec_21(io_mergeUopWriteback_1_bits_uop_exceptionVec_21),
    .io_mergeUopWriteback_1_bits_uop_vpu_vl(io_mergeUopWriteback_1_bits_uop_vpu_vl),
    .io_mergeUopWriteback_1_bits_uop_robIdx_flag(io_mergeUopWriteback_1_bits_uop_robIdx_flag),
    .io_mergeUopWriteback_1_bits_uop_robIdx_value(io_mergeUopWriteback_1_bits_uop_robIdx_value),
    .io_uopWriteback_valid(g_io_uopWriteback_valid),
    .io_uopWriteback_bits_uop_fuOpType(g_io_uopWriteback_bits_uop_fuOpType),
    .io_uopWriteback_bits_uop_vecWen(g_io_uopWriteback_bits_uop_vecWen),
    .io_uopWriteback_bits_uop_v0Wen(g_io_uopWriteback_bits_uop_v0Wen),
    .io_uopWriteback_bits_uop_vlWen(g_io_uopWriteback_bits_uop_vlWen),
    .io_uopWriteback_bits_uop_vpu_vma(g_io_uopWriteback_bits_uop_vpu_vma),
    .io_uopWriteback_bits_uop_vpu_vta(g_io_uopWriteback_bits_uop_vpu_vta),
    .io_uopWriteback_bits_uop_vpu_vsew(g_io_uopWriteback_bits_uop_vpu_vsew),
    .io_uopWriteback_bits_uop_vpu_vlmul(g_io_uopWriteback_bits_uop_vpu_vlmul),
    .io_uopWriteback_bits_uop_vpu_vm(g_io_uopWriteback_bits_uop_vpu_vm),
    .io_uopWriteback_bits_uop_vpu_vstart(g_io_uopWriteback_bits_uop_vpu_vstart),
    .io_uopWriteback_bits_uop_vpu_vuopIdx(g_io_uopWriteback_bits_uop_vpu_vuopIdx),
    .io_uopWriteback_bits_uop_vpu_vl(g_io_uopWriteback_bits_uop_vpu_vl),
    .io_uopWriteback_bits_uop_vpu_nf(g_io_uopWriteback_bits_uop_vpu_nf),
    .io_uopWriteback_bits_uop_vpu_veew(g_io_uopWriteback_bits_uop_vpu_veew),
    .io_uopWriteback_bits_uop_pdest(g_io_uopWriteback_bits_uop_pdest),
    .io_uopWriteback_bits_uop_robIdx_flag(g_io_uopWriteback_bits_uop_robIdx_flag),
    .io_uopWriteback_bits_uop_robIdx_value(g_io_uopWriteback_bits_uop_robIdx_value),
    .io_uopWriteback_bits_uop_debugInfo_enqRsTime(g_io_uopWriteback_bits_uop_debugInfo_enqRsTime),
    .io_uopWriteback_bits_uop_debugInfo_selectTime(g_io_uopWriteback_bits_uop_debugInfo_selectTime),
    .io_uopWriteback_bits_uop_debugInfo_issueTime(g_io_uopWriteback_bits_uop_debugInfo_issueTime),
    .io_uopWriteback_bits_data(g_io_uopWriteback_bits_data)
  );
  VfofBuffer_xs u_i (
    .clock(clk), .reset(rst),
    .io_redirect_valid(io_redirect_valid),
    .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value),
    .io_redirect_bits_level(io_redirect_bits_level),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_uop_fuOpType(io_in_0_bits_uop_fuOpType),
    .io_in_0_bits_uop_vecWen(io_in_0_bits_uop_vecWen),
    .io_in_0_bits_uop_v0Wen(io_in_0_bits_uop_v0Wen),
    .io_in_0_bits_uop_vlWen(io_in_0_bits_uop_vlWen),
    .io_in_0_bits_uop_vpu_vma(io_in_0_bits_uop_vpu_vma),
    .io_in_0_bits_uop_vpu_vta(io_in_0_bits_uop_vpu_vta),
    .io_in_0_bits_uop_vpu_vsew(io_in_0_bits_uop_vpu_vsew),
    .io_in_0_bits_uop_vpu_vlmul(io_in_0_bits_uop_vpu_vlmul),
    .io_in_0_bits_uop_vpu_vm(io_in_0_bits_uop_vpu_vm),
    .io_in_0_bits_uop_vpu_vstart(io_in_0_bits_uop_vpu_vstart),
    .io_in_0_bits_uop_vpu_vuopIdx(io_in_0_bits_uop_vpu_vuopIdx),
    .io_in_0_bits_uop_vpu_lastUop(io_in_0_bits_uop_vpu_lastUop),
    .io_in_0_bits_uop_vpu_nf(io_in_0_bits_uop_vpu_nf),
    .io_in_0_bits_uop_vpu_veew(io_in_0_bits_uop_vpu_veew),
    .io_in_0_bits_uop_vpu_isVleff(io_in_0_bits_uop_vpu_isVleff),
    .io_in_0_bits_uop_pdest(io_in_0_bits_uop_pdest),
    .io_in_0_bits_uop_robIdx_flag(io_in_0_bits_uop_robIdx_flag),
    .io_in_0_bits_uop_robIdx_value(io_in_0_bits_uop_robIdx_value),
    .io_in_0_bits_uop_debugInfo_enqRsTime(io_in_0_bits_uop_debugInfo_enqRsTime),
    .io_in_0_bits_uop_debugInfo_selectTime(io_in_0_bits_uop_debugInfo_selectTime),
    .io_in_0_bits_uop_debugInfo_issueTime(io_in_0_bits_uop_debugInfo_issueTime),
    .io_in_0_bits_src_4(io_in_0_bits_src_4),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_uop_fuOpType(io_in_1_bits_uop_fuOpType),
    .io_in_1_bits_uop_vecWen(io_in_1_bits_uop_vecWen),
    .io_in_1_bits_uop_v0Wen(io_in_1_bits_uop_v0Wen),
    .io_in_1_bits_uop_vlWen(io_in_1_bits_uop_vlWen),
    .io_in_1_bits_uop_vpu_vma(io_in_1_bits_uop_vpu_vma),
    .io_in_1_bits_uop_vpu_vta(io_in_1_bits_uop_vpu_vta),
    .io_in_1_bits_uop_vpu_vsew(io_in_1_bits_uop_vpu_vsew),
    .io_in_1_bits_uop_vpu_vlmul(io_in_1_bits_uop_vpu_vlmul),
    .io_in_1_bits_uop_vpu_vm(io_in_1_bits_uop_vpu_vm),
    .io_in_1_bits_uop_vpu_vstart(io_in_1_bits_uop_vpu_vstart),
    .io_in_1_bits_uop_vpu_vuopIdx(io_in_1_bits_uop_vpu_vuopIdx),
    .io_in_1_bits_uop_vpu_lastUop(io_in_1_bits_uop_vpu_lastUop),
    .io_in_1_bits_uop_vpu_nf(io_in_1_bits_uop_vpu_nf),
    .io_in_1_bits_uop_vpu_veew(io_in_1_bits_uop_vpu_veew),
    .io_in_1_bits_uop_vpu_isVleff(io_in_1_bits_uop_vpu_isVleff),
    .io_in_1_bits_uop_pdest(io_in_1_bits_uop_pdest),
    .io_in_1_bits_uop_robIdx_flag(io_in_1_bits_uop_robIdx_flag),
    .io_in_1_bits_uop_robIdx_value(io_in_1_bits_uop_robIdx_value),
    .io_in_1_bits_uop_debugInfo_enqRsTime(io_in_1_bits_uop_debugInfo_enqRsTime),
    .io_in_1_bits_uop_debugInfo_selectTime(io_in_1_bits_uop_debugInfo_selectTime),
    .io_in_1_bits_uop_debugInfo_issueTime(io_in_1_bits_uop_debugInfo_issueTime),
    .io_in_1_bits_src_4(io_in_1_bits_src_4),
    .io_mergeUopWriteback_0_valid(io_mergeUopWriteback_0_valid),
    .io_mergeUopWriteback_0_bits_uop_exceptionVec_3(io_mergeUopWriteback_0_bits_uop_exceptionVec_3),
    .io_mergeUopWriteback_0_bits_uop_exceptionVec_4(io_mergeUopWriteback_0_bits_uop_exceptionVec_4),
    .io_mergeUopWriteback_0_bits_uop_exceptionVec_5(io_mergeUopWriteback_0_bits_uop_exceptionVec_5),
    .io_mergeUopWriteback_0_bits_uop_exceptionVec_13(io_mergeUopWriteback_0_bits_uop_exceptionVec_13),
    .io_mergeUopWriteback_0_bits_uop_exceptionVec_19(io_mergeUopWriteback_0_bits_uop_exceptionVec_19),
    .io_mergeUopWriteback_0_bits_uop_exceptionVec_21(io_mergeUopWriteback_0_bits_uop_exceptionVec_21),
    .io_mergeUopWriteback_0_bits_uop_vpu_vl(io_mergeUopWriteback_0_bits_uop_vpu_vl),
    .io_mergeUopWriteback_0_bits_uop_robIdx_flag(io_mergeUopWriteback_0_bits_uop_robIdx_flag),
    .io_mergeUopWriteback_0_bits_uop_robIdx_value(io_mergeUopWriteback_0_bits_uop_robIdx_value),
    .io_mergeUopWriteback_1_valid(io_mergeUopWriteback_1_valid),
    .io_mergeUopWriteback_1_bits_uop_exceptionVec_3(io_mergeUopWriteback_1_bits_uop_exceptionVec_3),
    .io_mergeUopWriteback_1_bits_uop_exceptionVec_4(io_mergeUopWriteback_1_bits_uop_exceptionVec_4),
    .io_mergeUopWriteback_1_bits_uop_exceptionVec_5(io_mergeUopWriteback_1_bits_uop_exceptionVec_5),
    .io_mergeUopWriteback_1_bits_uop_exceptionVec_13(io_mergeUopWriteback_1_bits_uop_exceptionVec_13),
    .io_mergeUopWriteback_1_bits_uop_exceptionVec_19(io_mergeUopWriteback_1_bits_uop_exceptionVec_19),
    .io_mergeUopWriteback_1_bits_uop_exceptionVec_21(io_mergeUopWriteback_1_bits_uop_exceptionVec_21),
    .io_mergeUopWriteback_1_bits_uop_vpu_vl(io_mergeUopWriteback_1_bits_uop_vpu_vl),
    .io_mergeUopWriteback_1_bits_uop_robIdx_flag(io_mergeUopWriteback_1_bits_uop_robIdx_flag),
    .io_mergeUopWriteback_1_bits_uop_robIdx_value(io_mergeUopWriteback_1_bits_uop_robIdx_value),
    .io_uopWriteback_valid(i_io_uopWriteback_valid),
    .io_uopWriteback_bits_uop_fuOpType(i_io_uopWriteback_bits_uop_fuOpType),
    .io_uopWriteback_bits_uop_vecWen(i_io_uopWriteback_bits_uop_vecWen),
    .io_uopWriteback_bits_uop_v0Wen(i_io_uopWriteback_bits_uop_v0Wen),
    .io_uopWriteback_bits_uop_vlWen(i_io_uopWriteback_bits_uop_vlWen),
    .io_uopWriteback_bits_uop_vpu_vma(i_io_uopWriteback_bits_uop_vpu_vma),
    .io_uopWriteback_bits_uop_vpu_vta(i_io_uopWriteback_bits_uop_vpu_vta),
    .io_uopWriteback_bits_uop_vpu_vsew(i_io_uopWriteback_bits_uop_vpu_vsew),
    .io_uopWriteback_bits_uop_vpu_vlmul(i_io_uopWriteback_bits_uop_vpu_vlmul),
    .io_uopWriteback_bits_uop_vpu_vm(i_io_uopWriteback_bits_uop_vpu_vm),
    .io_uopWriteback_bits_uop_vpu_vstart(i_io_uopWriteback_bits_uop_vpu_vstart),
    .io_uopWriteback_bits_uop_vpu_vuopIdx(i_io_uopWriteback_bits_uop_vpu_vuopIdx),
    .io_uopWriteback_bits_uop_vpu_vl(i_io_uopWriteback_bits_uop_vpu_vl),
    .io_uopWriteback_bits_uop_vpu_nf(i_io_uopWriteback_bits_uop_vpu_nf),
    .io_uopWriteback_bits_uop_vpu_veew(i_io_uopWriteback_bits_uop_vpu_veew),
    .io_uopWriteback_bits_uop_pdest(i_io_uopWriteback_bits_uop_pdest),
    .io_uopWriteback_bits_uop_robIdx_flag(i_io_uopWriteback_bits_uop_robIdx_flag),
    .io_uopWriteback_bits_uop_robIdx_value(i_io_uopWriteback_bits_uop_robIdx_value),
    .io_uopWriteback_bits_uop_debugInfo_enqRsTime(i_io_uopWriteback_bits_uop_debugInfo_enqRsTime),
    .io_uopWriteback_bits_uop_debugInfo_selectTime(i_io_uopWriteback_bits_uop_debugInfo_selectTime),
    .io_uopWriteback_bits_uop_debugInfo_issueTime(i_io_uopWriteback_bits_uop_debugInfo_issueTime),
    .io_uopWriteback_bits_data(i_io_uopWriteback_bits_data)
  );

  initial begin
    rst = 1;
    // 初值
    io_redirect_valid = 0;
    io_redirect_bits_robIdx_flag = 0;
    io_redirect_bits_robIdx_value = 0;
    io_redirect_bits_level = 0;
    io_in_0_valid = 0;
    io_in_0_bits_uop_fuOpType = 0;
    io_in_0_bits_uop_vecWen = 0;
    io_in_0_bits_uop_v0Wen = 0;
    io_in_0_bits_uop_vlWen = 0;
    io_in_0_bits_uop_vpu_vma = 0;
    io_in_0_bits_uop_vpu_vta = 0;
    io_in_0_bits_uop_vpu_vsew = 0;
    io_in_0_bits_uop_vpu_vlmul = 0;
    io_in_0_bits_uop_vpu_vm = 0;
    io_in_0_bits_uop_vpu_vstart = 0;
    io_in_0_bits_uop_vpu_vuopIdx = 0;
    io_in_0_bits_uop_vpu_lastUop = 0;
    io_in_0_bits_uop_vpu_nf = 0;
    io_in_0_bits_uop_vpu_veew = 0;
    io_in_0_bits_uop_vpu_isVleff = 0;
    io_in_0_bits_uop_pdest = 0;
    io_in_0_bits_uop_robIdx_flag = 0;
    io_in_0_bits_uop_robIdx_value = 0;
    io_in_0_bits_uop_debugInfo_enqRsTime = 0;
    io_in_0_bits_uop_debugInfo_selectTime = 0;
    io_in_0_bits_uop_debugInfo_issueTime = 0;
    io_in_0_bits_src_4 = 0;
    io_in_1_valid = 0;
    io_in_1_bits_uop_fuOpType = 0;
    io_in_1_bits_uop_vecWen = 0;
    io_in_1_bits_uop_v0Wen = 0;
    io_in_1_bits_uop_vlWen = 0;
    io_in_1_bits_uop_vpu_vma = 0;
    io_in_1_bits_uop_vpu_vta = 0;
    io_in_1_bits_uop_vpu_vsew = 0;
    io_in_1_bits_uop_vpu_vlmul = 0;
    io_in_1_bits_uop_vpu_vm = 0;
    io_in_1_bits_uop_vpu_vstart = 0;
    io_in_1_bits_uop_vpu_vuopIdx = 0;
    io_in_1_bits_uop_vpu_lastUop = 0;
    io_in_1_bits_uop_vpu_nf = 0;
    io_in_1_bits_uop_vpu_veew = 0;
    io_in_1_bits_uop_vpu_isVleff = 0;
    io_in_1_bits_uop_pdest = 0;
    io_in_1_bits_uop_robIdx_flag = 0;
    io_in_1_bits_uop_robIdx_value = 0;
    io_in_1_bits_uop_debugInfo_enqRsTime = 0;
    io_in_1_bits_uop_debugInfo_selectTime = 0;
    io_in_1_bits_uop_debugInfo_issueTime = 0;
    io_in_1_bits_src_4 = 0;
    io_mergeUopWriteback_0_valid = 0;
    io_mergeUopWriteback_0_bits_uop_exceptionVec_3 = 0;
    io_mergeUopWriteback_0_bits_uop_exceptionVec_4 = 0;
    io_mergeUopWriteback_0_bits_uop_exceptionVec_5 = 0;
    io_mergeUopWriteback_0_bits_uop_exceptionVec_13 = 0;
    io_mergeUopWriteback_0_bits_uop_exceptionVec_19 = 0;
    io_mergeUopWriteback_0_bits_uop_exceptionVec_21 = 0;
    io_mergeUopWriteback_0_bits_uop_vpu_vl = 0;
    io_mergeUopWriteback_0_bits_uop_robIdx_flag = 0;
    io_mergeUopWriteback_0_bits_uop_robIdx_value = 0;
    io_mergeUopWriteback_1_valid = 0;
    io_mergeUopWriteback_1_bits_uop_exceptionVec_3 = 0;
    io_mergeUopWriteback_1_bits_uop_exceptionVec_4 = 0;
    io_mergeUopWriteback_1_bits_uop_exceptionVec_5 = 0;
    io_mergeUopWriteback_1_bits_uop_exceptionVec_13 = 0;
    io_mergeUopWriteback_1_bits_uop_exceptionVec_19 = 0;
    io_mergeUopWriteback_1_bits_uop_exceptionVec_21 = 0;
    io_mergeUopWriteback_1_bits_uop_vpu_vl = 0;
    io_mergeUopWriteback_1_bits_uop_robIdx_flag = 0;
    io_mergeUopWriteback_1_bits_uop_robIdx_value = 0;
    repeat (WARMUP) @(posedge clk);
    rst = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      io_redirect_valid <= $random;
      io_redirect_bits_robIdx_flag <= $random;
      io_redirect_bits_robIdx_value <= $random;
      io_redirect_bits_level <= $random;
      io_in_0_valid <= $random;
      io_in_0_bits_uop_fuOpType <= $random;
      io_in_0_bits_uop_vecWen <= $random;
      io_in_0_bits_uop_v0Wen <= $random;
      io_in_0_bits_uop_vlWen <= $random;
      io_in_0_bits_uop_vpu_vma <= $random;
      io_in_0_bits_uop_vpu_vta <= $random;
      io_in_0_bits_uop_vpu_vsew <= $random;
      io_in_0_bits_uop_vpu_vlmul <= $random;
      io_in_0_bits_uop_vpu_vm <= $random;
      io_in_0_bits_uop_vpu_vstart <= $random;
      io_in_0_bits_uop_vpu_vuopIdx <= $random;
      io_in_0_bits_uop_vpu_lastUop <= $random;
      io_in_0_bits_uop_vpu_nf <= $random;
      io_in_0_bits_uop_vpu_veew <= $random;
      io_in_0_bits_uop_vpu_isVleff <= $random;
      io_in_0_bits_uop_pdest <= $random;
      io_in_0_bits_uop_robIdx_flag <= $random;
      io_in_0_bits_uop_robIdx_value <= $random;
      io_in_0_bits_uop_debugInfo_enqRsTime <= {$random, $random};
      io_in_0_bits_uop_debugInfo_selectTime <= {$random, $random};
      io_in_0_bits_uop_debugInfo_issueTime <= {$random, $random};
      io_in_0_bits_src_4 <= {$random, $random, $random, $random};
      io_in_1_valid <= $random;
      io_in_1_bits_uop_fuOpType <= $random;
      io_in_1_bits_uop_vecWen <= $random;
      io_in_1_bits_uop_v0Wen <= $random;
      io_in_1_bits_uop_vlWen <= $random;
      io_in_1_bits_uop_vpu_vma <= $random;
      io_in_1_bits_uop_vpu_vta <= $random;
      io_in_1_bits_uop_vpu_vsew <= $random;
      io_in_1_bits_uop_vpu_vlmul <= $random;
      io_in_1_bits_uop_vpu_vm <= $random;
      io_in_1_bits_uop_vpu_vstart <= $random;
      io_in_1_bits_uop_vpu_vuopIdx <= $random;
      io_in_1_bits_uop_vpu_lastUop <= $random;
      io_in_1_bits_uop_vpu_nf <= $random;
      io_in_1_bits_uop_vpu_veew <= $random;
      io_in_1_bits_uop_vpu_isVleff <= $random;
      io_in_1_bits_uop_pdest <= $random;
      io_in_1_bits_uop_robIdx_flag <= $random;
      io_in_1_bits_uop_robIdx_value <= $random;
      io_in_1_bits_uop_debugInfo_enqRsTime <= {$random, $random};
      io_in_1_bits_uop_debugInfo_selectTime <= {$random, $random};
      io_in_1_bits_uop_debugInfo_issueTime <= {$random, $random};
      io_in_1_bits_src_4 <= {$random, $random, $random, $random};
      io_mergeUopWriteback_0_valid <= $random;
      io_mergeUopWriteback_0_bits_uop_exceptionVec_3 <= $random;
      io_mergeUopWriteback_0_bits_uop_exceptionVec_4 <= $random;
      io_mergeUopWriteback_0_bits_uop_exceptionVec_5 <= $random;
      io_mergeUopWriteback_0_bits_uop_exceptionVec_13 <= $random;
      io_mergeUopWriteback_0_bits_uop_exceptionVec_19 <= $random;
      io_mergeUopWriteback_0_bits_uop_exceptionVec_21 <= $random;
      io_mergeUopWriteback_0_bits_uop_vpu_vl <= $random;
      io_mergeUopWriteback_0_bits_uop_robIdx_flag <= $random;
      io_mergeUopWriteback_0_bits_uop_robIdx_value <= $random;
      io_mergeUopWriteback_1_valid <= $random;
      io_mergeUopWriteback_1_bits_uop_exceptionVec_3 <= $random;
      io_mergeUopWriteback_1_bits_uop_exceptionVec_4 <= $random;
      io_mergeUopWriteback_1_bits_uop_exceptionVec_5 <= $random;
      io_mergeUopWriteback_1_bits_uop_exceptionVec_13 <= $random;
      io_mergeUopWriteback_1_bits_uop_exceptionVec_19 <= $random;
      io_mergeUopWriteback_1_bits_uop_exceptionVec_21 <= $random;
      io_mergeUopWriteback_1_bits_uop_vpu_vl <= $random;
      io_mergeUopWriteback_1_bits_uop_robIdx_flag <= $random;
      io_mergeUopWriteback_1_bits_uop_robIdx_value <= $random;
      @(posedge clk);
      #1;
      if (cyc > 2) begin
        checks++;
      if (g_io_uopWriteback_valid !== i_io_uopWriteback_valid) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_valid @%0d g=%h i=%h", cyc, g_io_uopWriteback_valid, i_io_uopWriteback_valid); end
      if (g_io_uopWriteback_bits_uop_fuOpType !== i_io_uopWriteback_bits_uop_fuOpType) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_bits_uop_fuOpType @%0d g=%h i=%h", cyc, g_io_uopWriteback_bits_uop_fuOpType, i_io_uopWriteback_bits_uop_fuOpType); end
      if (g_io_uopWriteback_bits_uop_vecWen !== i_io_uopWriteback_bits_uop_vecWen) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_bits_uop_vecWen @%0d g=%h i=%h", cyc, g_io_uopWriteback_bits_uop_vecWen, i_io_uopWriteback_bits_uop_vecWen); end
      if (g_io_uopWriteback_bits_uop_v0Wen !== i_io_uopWriteback_bits_uop_v0Wen) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_bits_uop_v0Wen @%0d g=%h i=%h", cyc, g_io_uopWriteback_bits_uop_v0Wen, i_io_uopWriteback_bits_uop_v0Wen); end
      if (g_io_uopWriteback_bits_uop_vlWen !== i_io_uopWriteback_bits_uop_vlWen) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_bits_uop_vlWen @%0d g=%h i=%h", cyc, g_io_uopWriteback_bits_uop_vlWen, i_io_uopWriteback_bits_uop_vlWen); end
      if (g_io_uopWriteback_bits_uop_vpu_vma !== i_io_uopWriteback_bits_uop_vpu_vma) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_bits_uop_vpu_vma @%0d g=%h i=%h", cyc, g_io_uopWriteback_bits_uop_vpu_vma, i_io_uopWriteback_bits_uop_vpu_vma); end
      if (g_io_uopWriteback_bits_uop_vpu_vta !== i_io_uopWriteback_bits_uop_vpu_vta) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_bits_uop_vpu_vta @%0d g=%h i=%h", cyc, g_io_uopWriteback_bits_uop_vpu_vta, i_io_uopWriteback_bits_uop_vpu_vta); end
      if (g_io_uopWriteback_bits_uop_vpu_vsew !== i_io_uopWriteback_bits_uop_vpu_vsew) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_bits_uop_vpu_vsew @%0d g=%h i=%h", cyc, g_io_uopWriteback_bits_uop_vpu_vsew, i_io_uopWriteback_bits_uop_vpu_vsew); end
      if (g_io_uopWriteback_bits_uop_vpu_vlmul !== i_io_uopWriteback_bits_uop_vpu_vlmul) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_bits_uop_vpu_vlmul @%0d g=%h i=%h", cyc, g_io_uopWriteback_bits_uop_vpu_vlmul, i_io_uopWriteback_bits_uop_vpu_vlmul); end
      if (g_io_uopWriteback_bits_uop_vpu_vm !== i_io_uopWriteback_bits_uop_vpu_vm) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_bits_uop_vpu_vm @%0d g=%h i=%h", cyc, g_io_uopWriteback_bits_uop_vpu_vm, i_io_uopWriteback_bits_uop_vpu_vm); end
      if (g_io_uopWriteback_bits_uop_vpu_vstart !== i_io_uopWriteback_bits_uop_vpu_vstart) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_bits_uop_vpu_vstart @%0d g=%h i=%h", cyc, g_io_uopWriteback_bits_uop_vpu_vstart, i_io_uopWriteback_bits_uop_vpu_vstart); end
      if (g_io_uopWriteback_bits_uop_vpu_vuopIdx !== i_io_uopWriteback_bits_uop_vpu_vuopIdx) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_bits_uop_vpu_vuopIdx @%0d g=%h i=%h", cyc, g_io_uopWriteback_bits_uop_vpu_vuopIdx, i_io_uopWriteback_bits_uop_vpu_vuopIdx); end
      if (g_io_uopWriteback_bits_uop_vpu_vl !== i_io_uopWriteback_bits_uop_vpu_vl) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_bits_uop_vpu_vl @%0d g=%h i=%h", cyc, g_io_uopWriteback_bits_uop_vpu_vl, i_io_uopWriteback_bits_uop_vpu_vl); end
      if (g_io_uopWriteback_bits_uop_vpu_nf !== i_io_uopWriteback_bits_uop_vpu_nf) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_bits_uop_vpu_nf @%0d g=%h i=%h", cyc, g_io_uopWriteback_bits_uop_vpu_nf, i_io_uopWriteback_bits_uop_vpu_nf); end
      if (g_io_uopWriteback_bits_uop_vpu_veew !== i_io_uopWriteback_bits_uop_vpu_veew) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_bits_uop_vpu_veew @%0d g=%h i=%h", cyc, g_io_uopWriteback_bits_uop_vpu_veew, i_io_uopWriteback_bits_uop_vpu_veew); end
      if (g_io_uopWriteback_bits_uop_pdest !== i_io_uopWriteback_bits_uop_pdest) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_bits_uop_pdest @%0d g=%h i=%h", cyc, g_io_uopWriteback_bits_uop_pdest, i_io_uopWriteback_bits_uop_pdest); end
      if (g_io_uopWriteback_bits_uop_robIdx_flag !== i_io_uopWriteback_bits_uop_robIdx_flag) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_bits_uop_robIdx_flag @%0d g=%h i=%h", cyc, g_io_uopWriteback_bits_uop_robIdx_flag, i_io_uopWriteback_bits_uop_robIdx_flag); end
      if (g_io_uopWriteback_bits_uop_robIdx_value !== i_io_uopWriteback_bits_uop_robIdx_value) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_bits_uop_robIdx_value @%0d g=%h i=%h", cyc, g_io_uopWriteback_bits_uop_robIdx_value, i_io_uopWriteback_bits_uop_robIdx_value); end
      if (g_io_uopWriteback_bits_uop_debugInfo_enqRsTime !== i_io_uopWriteback_bits_uop_debugInfo_enqRsTime) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_bits_uop_debugInfo_enqRsTime @%0d g=%h i=%h", cyc, g_io_uopWriteback_bits_uop_debugInfo_enqRsTime, i_io_uopWriteback_bits_uop_debugInfo_enqRsTime); end
      if (g_io_uopWriteback_bits_uop_debugInfo_selectTime !== i_io_uopWriteback_bits_uop_debugInfo_selectTime) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_bits_uop_debugInfo_selectTime @%0d g=%h i=%h", cyc, g_io_uopWriteback_bits_uop_debugInfo_selectTime, i_io_uopWriteback_bits_uop_debugInfo_selectTime); end
      if (g_io_uopWriteback_bits_uop_debugInfo_issueTime !== i_io_uopWriteback_bits_uop_debugInfo_issueTime) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_bits_uop_debugInfo_issueTime @%0d g=%h i=%h", cyc, g_io_uopWriteback_bits_uop_debugInfo_issueTime, i_io_uopWriteback_bits_uop_debugInfo_issueTime); end
      if (g_io_uopWriteback_bits_data !== i_io_uopWriteback_bits_data) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_bits_data @%0d g=%h i=%h", cyc, g_io_uopWriteback_bits_data, i_io_uopWriteback_bits_data); end
      end
    end
    if (errors == 0) $display("TEST PASSED checks=%0d errors=0", checks);
    else             $display("TEST FAILED checks=%0d errors=%0d", checks, errors);
    $finish;
  end
endmodule
