// 自动生成: VTypeBuffer UT: golden(+真子模块) vs 可读核 _xs 逐拍逐输出比对。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic reset;
  logic io_redirect_valid;
  logic io_req_0_valid;
  logic [8:0] io_req_0_bits_fuOpType;
  logic io_req_0_bits_vpu_vill;
  logic io_req_0_bits_vpu_vma;
  logic io_req_0_bits_vpu_vta;
  logic [1:0] io_req_0_bits_vpu_vsew;
  logic [2:0] io_req_0_bits_vpu_vlmul;
  logic io_req_0_bits_vpu_specVill;
  logic io_req_0_bits_vpu_specVma;
  logic io_req_0_bits_vpu_specVta;
  logic [1:0] io_req_0_bits_vpu_specVsew;
  logic [2:0] io_req_0_bits_vpu_specVlmul;
  logic io_req_0_bits_isVset;
  logic io_req_0_bits_lastUop;
  logic io_req_1_valid;
  logic [8:0] io_req_1_bits_fuOpType;
  logic io_req_1_bits_vpu_vill;
  logic io_req_1_bits_vpu_vma;
  logic io_req_1_bits_vpu_vta;
  logic [1:0] io_req_1_bits_vpu_vsew;
  logic [2:0] io_req_1_bits_vpu_vlmul;
  logic io_req_1_bits_vpu_specVill;
  logic io_req_1_bits_vpu_specVma;
  logic io_req_1_bits_vpu_specVta;
  logic [1:0] io_req_1_bits_vpu_specVsew;
  logic [2:0] io_req_1_bits_vpu_specVlmul;
  logic io_req_1_bits_isVset;
  logic io_req_1_bits_lastUop;
  logic io_req_2_valid;
  logic [8:0] io_req_2_bits_fuOpType;
  logic io_req_2_bits_vpu_vill;
  logic io_req_2_bits_vpu_vma;
  logic io_req_2_bits_vpu_vta;
  logic [1:0] io_req_2_bits_vpu_vsew;
  logic [2:0] io_req_2_bits_vpu_vlmul;
  logic io_req_2_bits_vpu_specVill;
  logic io_req_2_bits_vpu_specVma;
  logic io_req_2_bits_vpu_specVta;
  logic [1:0] io_req_2_bits_vpu_specVsew;
  logic [2:0] io_req_2_bits_vpu_specVlmul;
  logic io_req_2_bits_isVset;
  logic io_req_2_bits_lastUop;
  logic io_req_3_valid;
  logic [8:0] io_req_3_bits_fuOpType;
  logic io_req_3_bits_vpu_vill;
  logic io_req_3_bits_vpu_vma;
  logic io_req_3_bits_vpu_vta;
  logic [1:0] io_req_3_bits_vpu_vsew;
  logic [2:0] io_req_3_bits_vpu_vlmul;
  logic io_req_3_bits_vpu_specVill;
  logic io_req_3_bits_vpu_specVma;
  logic io_req_3_bits_vpu_specVta;
  logic [1:0] io_req_3_bits_vpu_specVsew;
  logic [2:0] io_req_3_bits_vpu_specVlmul;
  logic io_req_3_bits_isVset;
  logic io_req_3_bits_lastUop;
  logic io_req_4_valid;
  logic [8:0] io_req_4_bits_fuOpType;
  logic io_req_4_bits_vpu_vill;
  logic io_req_4_bits_vpu_vma;
  logic io_req_4_bits_vpu_vta;
  logic [1:0] io_req_4_bits_vpu_vsew;
  logic [2:0] io_req_4_bits_vpu_vlmul;
  logic io_req_4_bits_vpu_specVill;
  logic io_req_4_bits_vpu_specVma;
  logic io_req_4_bits_vpu_specVta;
  logic [1:0] io_req_4_bits_vpu_specVsew;
  logic [2:0] io_req_4_bits_vpu_specVlmul;
  logic io_req_4_bits_isVset;
  logic io_req_4_bits_lastUop;
  logic io_req_5_valid;
  logic [8:0] io_req_5_bits_fuOpType;
  logic io_req_5_bits_vpu_vill;
  logic io_req_5_bits_vpu_vma;
  logic io_req_5_bits_vpu_vta;
  logic [1:0] io_req_5_bits_vpu_vsew;
  logic [2:0] io_req_5_bits_vpu_vlmul;
  logic io_req_5_bits_vpu_specVill;
  logic io_req_5_bits_vpu_specVma;
  logic io_req_5_bits_vpu_specVta;
  logic [1:0] io_req_5_bits_vpu_specVsew;
  logic [2:0] io_req_5_bits_vpu_specVlmul;
  logic io_req_5_bits_isVset;
  logic io_req_5_bits_lastUop;
  logic [5:0] io_fromRob_walkSize;
  logic io_fromRob_walkEnd;
  logic [5:0] io_fromRob_commitSize;
  logic io_snpt_snptEnq;
  logic io_snpt_snptDeq;
  logic io_snpt_useSnpt;
  logic [1:0] io_snpt_snptSelect;
  logic io_snpt_flushVec_0;
  logic io_snpt_flushVec_1;
  logic io_snpt_flushVec_2;
  logic io_snpt_flushVec_3;

  logic g_io_canEnq;
  logic g_io_canEnqForDispatch;
  logic g_io_toDecode_isResumeVType;
  logic g_io_toDecode_walkToArchVType;
  logic g_io_toDecode_walkVType_valid;
  logic g_io_toDecode_walkVType_bits_illegal;
  logic g_io_toDecode_walkVType_bits_vma;
  logic g_io_toDecode_walkVType_bits_vta;
  logic [1:0] g_io_toDecode_walkVType_bits_vsew;
  logic [2:0] g_io_toDecode_walkVType_bits_vlmul;
  logic g_io_toDecode_commitVType_vtype_valid;
  logic g_io_toDecode_commitVType_vtype_bits_illegal;
  logic g_io_toDecode_commitVType_vtype_bits_vma;
  logic g_io_toDecode_commitVType_vtype_bits_vta;
  logic [1:0] g_io_toDecode_commitVType_vtype_bits_vsew;
  logic [2:0] g_io_toDecode_commitVType_vtype_bits_vlmul;
  logic g_io_toDecode_commitVType_hasVsetvl;
  logic g_io_status_walkEnd;

  logic i_io_canEnq;
  logic i_io_canEnqForDispatch;
  logic i_io_toDecode_isResumeVType;
  logic i_io_toDecode_walkToArchVType;
  logic i_io_toDecode_walkVType_valid;
  logic i_io_toDecode_walkVType_bits_illegal;
  logic i_io_toDecode_walkVType_bits_vma;
  logic i_io_toDecode_walkVType_bits_vta;
  logic [1:0] i_io_toDecode_walkVType_bits_vsew;
  logic [2:0] i_io_toDecode_walkVType_bits_vlmul;
  logic i_io_toDecode_commitVType_vtype_valid;
  logic i_io_toDecode_commitVType_vtype_bits_illegal;
  logic i_io_toDecode_commitVType_vtype_bits_vma;
  logic i_io_toDecode_commitVType_vtype_bits_vta;
  logic [1:0] i_io_toDecode_commitVType_vtype_bits_vsew;
  logic [2:0] i_io_toDecode_commitVType_vtype_bits_vlmul;
  logic i_io_toDecode_commitVType_hasVsetvl;
  logic i_io_status_walkEnd;

  VTypeBuffer u_g (
    .clock(clk),
    .reset(reset),
    .io_redirect_valid(io_redirect_valid),
    .io_req_0_valid(io_req_0_valid),
    .io_req_0_bits_fuOpType(io_req_0_bits_fuOpType),
    .io_req_0_bits_vpu_vill(io_req_0_bits_vpu_vill),
    .io_req_0_bits_vpu_vma(io_req_0_bits_vpu_vma),
    .io_req_0_bits_vpu_vta(io_req_0_bits_vpu_vta),
    .io_req_0_bits_vpu_vsew(io_req_0_bits_vpu_vsew),
    .io_req_0_bits_vpu_vlmul(io_req_0_bits_vpu_vlmul),
    .io_req_0_bits_vpu_specVill(io_req_0_bits_vpu_specVill),
    .io_req_0_bits_vpu_specVma(io_req_0_bits_vpu_specVma),
    .io_req_0_bits_vpu_specVta(io_req_0_bits_vpu_specVta),
    .io_req_0_bits_vpu_specVsew(io_req_0_bits_vpu_specVsew),
    .io_req_0_bits_vpu_specVlmul(io_req_0_bits_vpu_specVlmul),
    .io_req_0_bits_isVset(io_req_0_bits_isVset),
    .io_req_0_bits_lastUop(io_req_0_bits_lastUop),
    .io_req_1_valid(io_req_1_valid),
    .io_req_1_bits_fuOpType(io_req_1_bits_fuOpType),
    .io_req_1_bits_vpu_vill(io_req_1_bits_vpu_vill),
    .io_req_1_bits_vpu_vma(io_req_1_bits_vpu_vma),
    .io_req_1_bits_vpu_vta(io_req_1_bits_vpu_vta),
    .io_req_1_bits_vpu_vsew(io_req_1_bits_vpu_vsew),
    .io_req_1_bits_vpu_vlmul(io_req_1_bits_vpu_vlmul),
    .io_req_1_bits_vpu_specVill(io_req_1_bits_vpu_specVill),
    .io_req_1_bits_vpu_specVma(io_req_1_bits_vpu_specVma),
    .io_req_1_bits_vpu_specVta(io_req_1_bits_vpu_specVta),
    .io_req_1_bits_vpu_specVsew(io_req_1_bits_vpu_specVsew),
    .io_req_1_bits_vpu_specVlmul(io_req_1_bits_vpu_specVlmul),
    .io_req_1_bits_isVset(io_req_1_bits_isVset),
    .io_req_1_bits_lastUop(io_req_1_bits_lastUop),
    .io_req_2_valid(io_req_2_valid),
    .io_req_2_bits_fuOpType(io_req_2_bits_fuOpType),
    .io_req_2_bits_vpu_vill(io_req_2_bits_vpu_vill),
    .io_req_2_bits_vpu_vma(io_req_2_bits_vpu_vma),
    .io_req_2_bits_vpu_vta(io_req_2_bits_vpu_vta),
    .io_req_2_bits_vpu_vsew(io_req_2_bits_vpu_vsew),
    .io_req_2_bits_vpu_vlmul(io_req_2_bits_vpu_vlmul),
    .io_req_2_bits_vpu_specVill(io_req_2_bits_vpu_specVill),
    .io_req_2_bits_vpu_specVma(io_req_2_bits_vpu_specVma),
    .io_req_2_bits_vpu_specVta(io_req_2_bits_vpu_specVta),
    .io_req_2_bits_vpu_specVsew(io_req_2_bits_vpu_specVsew),
    .io_req_2_bits_vpu_specVlmul(io_req_2_bits_vpu_specVlmul),
    .io_req_2_bits_isVset(io_req_2_bits_isVset),
    .io_req_2_bits_lastUop(io_req_2_bits_lastUop),
    .io_req_3_valid(io_req_3_valid),
    .io_req_3_bits_fuOpType(io_req_3_bits_fuOpType),
    .io_req_3_bits_vpu_vill(io_req_3_bits_vpu_vill),
    .io_req_3_bits_vpu_vma(io_req_3_bits_vpu_vma),
    .io_req_3_bits_vpu_vta(io_req_3_bits_vpu_vta),
    .io_req_3_bits_vpu_vsew(io_req_3_bits_vpu_vsew),
    .io_req_3_bits_vpu_vlmul(io_req_3_bits_vpu_vlmul),
    .io_req_3_bits_vpu_specVill(io_req_3_bits_vpu_specVill),
    .io_req_3_bits_vpu_specVma(io_req_3_bits_vpu_specVma),
    .io_req_3_bits_vpu_specVta(io_req_3_bits_vpu_specVta),
    .io_req_3_bits_vpu_specVsew(io_req_3_bits_vpu_specVsew),
    .io_req_3_bits_vpu_specVlmul(io_req_3_bits_vpu_specVlmul),
    .io_req_3_bits_isVset(io_req_3_bits_isVset),
    .io_req_3_bits_lastUop(io_req_3_bits_lastUop),
    .io_req_4_valid(io_req_4_valid),
    .io_req_4_bits_fuOpType(io_req_4_bits_fuOpType),
    .io_req_4_bits_vpu_vill(io_req_4_bits_vpu_vill),
    .io_req_4_bits_vpu_vma(io_req_4_bits_vpu_vma),
    .io_req_4_bits_vpu_vta(io_req_4_bits_vpu_vta),
    .io_req_4_bits_vpu_vsew(io_req_4_bits_vpu_vsew),
    .io_req_4_bits_vpu_vlmul(io_req_4_bits_vpu_vlmul),
    .io_req_4_bits_vpu_specVill(io_req_4_bits_vpu_specVill),
    .io_req_4_bits_vpu_specVma(io_req_4_bits_vpu_specVma),
    .io_req_4_bits_vpu_specVta(io_req_4_bits_vpu_specVta),
    .io_req_4_bits_vpu_specVsew(io_req_4_bits_vpu_specVsew),
    .io_req_4_bits_vpu_specVlmul(io_req_4_bits_vpu_specVlmul),
    .io_req_4_bits_isVset(io_req_4_bits_isVset),
    .io_req_4_bits_lastUop(io_req_4_bits_lastUop),
    .io_req_5_valid(io_req_5_valid),
    .io_req_5_bits_fuOpType(io_req_5_bits_fuOpType),
    .io_req_5_bits_vpu_vill(io_req_5_bits_vpu_vill),
    .io_req_5_bits_vpu_vma(io_req_5_bits_vpu_vma),
    .io_req_5_bits_vpu_vta(io_req_5_bits_vpu_vta),
    .io_req_5_bits_vpu_vsew(io_req_5_bits_vpu_vsew),
    .io_req_5_bits_vpu_vlmul(io_req_5_bits_vpu_vlmul),
    .io_req_5_bits_vpu_specVill(io_req_5_bits_vpu_specVill),
    .io_req_5_bits_vpu_specVma(io_req_5_bits_vpu_specVma),
    .io_req_5_bits_vpu_specVta(io_req_5_bits_vpu_specVta),
    .io_req_5_bits_vpu_specVsew(io_req_5_bits_vpu_specVsew),
    .io_req_5_bits_vpu_specVlmul(io_req_5_bits_vpu_specVlmul),
    .io_req_5_bits_isVset(io_req_5_bits_isVset),
    .io_req_5_bits_lastUop(io_req_5_bits_lastUop),
    .io_fromRob_walkSize(io_fromRob_walkSize),
    .io_fromRob_walkEnd(io_fromRob_walkEnd),
    .io_fromRob_commitSize(io_fromRob_commitSize),
    .io_snpt_snptEnq(io_snpt_snptEnq),
    .io_snpt_snptDeq(io_snpt_snptDeq),
    .io_snpt_useSnpt(io_snpt_useSnpt),
    .io_snpt_snptSelect(io_snpt_snptSelect),
    .io_snpt_flushVec_0(io_snpt_flushVec_0),
    .io_snpt_flushVec_1(io_snpt_flushVec_1),
    .io_snpt_flushVec_2(io_snpt_flushVec_2),
    .io_snpt_flushVec_3(io_snpt_flushVec_3),
    .io_canEnq(g_io_canEnq),
    .io_canEnqForDispatch(g_io_canEnqForDispatch),
    .io_toDecode_isResumeVType(g_io_toDecode_isResumeVType),
    .io_toDecode_walkToArchVType(g_io_toDecode_walkToArchVType),
    .io_toDecode_walkVType_valid(g_io_toDecode_walkVType_valid),
    .io_toDecode_walkVType_bits_illegal(g_io_toDecode_walkVType_bits_illegal),
    .io_toDecode_walkVType_bits_vma(g_io_toDecode_walkVType_bits_vma),
    .io_toDecode_walkVType_bits_vta(g_io_toDecode_walkVType_bits_vta),
    .io_toDecode_walkVType_bits_vsew(g_io_toDecode_walkVType_bits_vsew),
    .io_toDecode_walkVType_bits_vlmul(g_io_toDecode_walkVType_bits_vlmul),
    .io_toDecode_commitVType_vtype_valid(g_io_toDecode_commitVType_vtype_valid),
    .io_toDecode_commitVType_vtype_bits_illegal(g_io_toDecode_commitVType_vtype_bits_illegal),
    .io_toDecode_commitVType_vtype_bits_vma(g_io_toDecode_commitVType_vtype_bits_vma),
    .io_toDecode_commitVType_vtype_bits_vta(g_io_toDecode_commitVType_vtype_bits_vta),
    .io_toDecode_commitVType_vtype_bits_vsew(g_io_toDecode_commitVType_vtype_bits_vsew),
    .io_toDecode_commitVType_vtype_bits_vlmul(g_io_toDecode_commitVType_vtype_bits_vlmul),
    .io_toDecode_commitVType_hasVsetvl(g_io_toDecode_commitVType_hasVsetvl),
    .io_status_walkEnd(g_io_status_walkEnd)
  );
  VTypeBuffer_xs u_i (
    .clock(clk),
    .reset(reset),
    .io_redirect_valid(io_redirect_valid),
    .io_req_0_valid(io_req_0_valid),
    .io_req_0_bits_fuOpType(io_req_0_bits_fuOpType),
    .io_req_0_bits_vpu_vill(io_req_0_bits_vpu_vill),
    .io_req_0_bits_vpu_vma(io_req_0_bits_vpu_vma),
    .io_req_0_bits_vpu_vta(io_req_0_bits_vpu_vta),
    .io_req_0_bits_vpu_vsew(io_req_0_bits_vpu_vsew),
    .io_req_0_bits_vpu_vlmul(io_req_0_bits_vpu_vlmul),
    .io_req_0_bits_vpu_specVill(io_req_0_bits_vpu_specVill),
    .io_req_0_bits_vpu_specVma(io_req_0_bits_vpu_specVma),
    .io_req_0_bits_vpu_specVta(io_req_0_bits_vpu_specVta),
    .io_req_0_bits_vpu_specVsew(io_req_0_bits_vpu_specVsew),
    .io_req_0_bits_vpu_specVlmul(io_req_0_bits_vpu_specVlmul),
    .io_req_0_bits_isVset(io_req_0_bits_isVset),
    .io_req_0_bits_lastUop(io_req_0_bits_lastUop),
    .io_req_1_valid(io_req_1_valid),
    .io_req_1_bits_fuOpType(io_req_1_bits_fuOpType),
    .io_req_1_bits_vpu_vill(io_req_1_bits_vpu_vill),
    .io_req_1_bits_vpu_vma(io_req_1_bits_vpu_vma),
    .io_req_1_bits_vpu_vta(io_req_1_bits_vpu_vta),
    .io_req_1_bits_vpu_vsew(io_req_1_bits_vpu_vsew),
    .io_req_1_bits_vpu_vlmul(io_req_1_bits_vpu_vlmul),
    .io_req_1_bits_vpu_specVill(io_req_1_bits_vpu_specVill),
    .io_req_1_bits_vpu_specVma(io_req_1_bits_vpu_specVma),
    .io_req_1_bits_vpu_specVta(io_req_1_bits_vpu_specVta),
    .io_req_1_bits_vpu_specVsew(io_req_1_bits_vpu_specVsew),
    .io_req_1_bits_vpu_specVlmul(io_req_1_bits_vpu_specVlmul),
    .io_req_1_bits_isVset(io_req_1_bits_isVset),
    .io_req_1_bits_lastUop(io_req_1_bits_lastUop),
    .io_req_2_valid(io_req_2_valid),
    .io_req_2_bits_fuOpType(io_req_2_bits_fuOpType),
    .io_req_2_bits_vpu_vill(io_req_2_bits_vpu_vill),
    .io_req_2_bits_vpu_vma(io_req_2_bits_vpu_vma),
    .io_req_2_bits_vpu_vta(io_req_2_bits_vpu_vta),
    .io_req_2_bits_vpu_vsew(io_req_2_bits_vpu_vsew),
    .io_req_2_bits_vpu_vlmul(io_req_2_bits_vpu_vlmul),
    .io_req_2_bits_vpu_specVill(io_req_2_bits_vpu_specVill),
    .io_req_2_bits_vpu_specVma(io_req_2_bits_vpu_specVma),
    .io_req_2_bits_vpu_specVta(io_req_2_bits_vpu_specVta),
    .io_req_2_bits_vpu_specVsew(io_req_2_bits_vpu_specVsew),
    .io_req_2_bits_vpu_specVlmul(io_req_2_bits_vpu_specVlmul),
    .io_req_2_bits_isVset(io_req_2_bits_isVset),
    .io_req_2_bits_lastUop(io_req_2_bits_lastUop),
    .io_req_3_valid(io_req_3_valid),
    .io_req_3_bits_fuOpType(io_req_3_bits_fuOpType),
    .io_req_3_bits_vpu_vill(io_req_3_bits_vpu_vill),
    .io_req_3_bits_vpu_vma(io_req_3_bits_vpu_vma),
    .io_req_3_bits_vpu_vta(io_req_3_bits_vpu_vta),
    .io_req_3_bits_vpu_vsew(io_req_3_bits_vpu_vsew),
    .io_req_3_bits_vpu_vlmul(io_req_3_bits_vpu_vlmul),
    .io_req_3_bits_vpu_specVill(io_req_3_bits_vpu_specVill),
    .io_req_3_bits_vpu_specVma(io_req_3_bits_vpu_specVma),
    .io_req_3_bits_vpu_specVta(io_req_3_bits_vpu_specVta),
    .io_req_3_bits_vpu_specVsew(io_req_3_bits_vpu_specVsew),
    .io_req_3_bits_vpu_specVlmul(io_req_3_bits_vpu_specVlmul),
    .io_req_3_bits_isVset(io_req_3_bits_isVset),
    .io_req_3_bits_lastUop(io_req_3_bits_lastUop),
    .io_req_4_valid(io_req_4_valid),
    .io_req_4_bits_fuOpType(io_req_4_bits_fuOpType),
    .io_req_4_bits_vpu_vill(io_req_4_bits_vpu_vill),
    .io_req_4_bits_vpu_vma(io_req_4_bits_vpu_vma),
    .io_req_4_bits_vpu_vta(io_req_4_bits_vpu_vta),
    .io_req_4_bits_vpu_vsew(io_req_4_bits_vpu_vsew),
    .io_req_4_bits_vpu_vlmul(io_req_4_bits_vpu_vlmul),
    .io_req_4_bits_vpu_specVill(io_req_4_bits_vpu_specVill),
    .io_req_4_bits_vpu_specVma(io_req_4_bits_vpu_specVma),
    .io_req_4_bits_vpu_specVta(io_req_4_bits_vpu_specVta),
    .io_req_4_bits_vpu_specVsew(io_req_4_bits_vpu_specVsew),
    .io_req_4_bits_vpu_specVlmul(io_req_4_bits_vpu_specVlmul),
    .io_req_4_bits_isVset(io_req_4_bits_isVset),
    .io_req_4_bits_lastUop(io_req_4_bits_lastUop),
    .io_req_5_valid(io_req_5_valid),
    .io_req_5_bits_fuOpType(io_req_5_bits_fuOpType),
    .io_req_5_bits_vpu_vill(io_req_5_bits_vpu_vill),
    .io_req_5_bits_vpu_vma(io_req_5_bits_vpu_vma),
    .io_req_5_bits_vpu_vta(io_req_5_bits_vpu_vta),
    .io_req_5_bits_vpu_vsew(io_req_5_bits_vpu_vsew),
    .io_req_5_bits_vpu_vlmul(io_req_5_bits_vpu_vlmul),
    .io_req_5_bits_vpu_specVill(io_req_5_bits_vpu_specVill),
    .io_req_5_bits_vpu_specVma(io_req_5_bits_vpu_specVma),
    .io_req_5_bits_vpu_specVta(io_req_5_bits_vpu_specVta),
    .io_req_5_bits_vpu_specVsew(io_req_5_bits_vpu_specVsew),
    .io_req_5_bits_vpu_specVlmul(io_req_5_bits_vpu_specVlmul),
    .io_req_5_bits_isVset(io_req_5_bits_isVset),
    .io_req_5_bits_lastUop(io_req_5_bits_lastUop),
    .io_fromRob_walkSize(io_fromRob_walkSize),
    .io_fromRob_walkEnd(io_fromRob_walkEnd),
    .io_fromRob_commitSize(io_fromRob_commitSize),
    .io_snpt_snptEnq(io_snpt_snptEnq),
    .io_snpt_snptDeq(io_snpt_snptDeq),
    .io_snpt_useSnpt(io_snpt_useSnpt),
    .io_snpt_snptSelect(io_snpt_snptSelect),
    .io_snpt_flushVec_0(io_snpt_flushVec_0),
    .io_snpt_flushVec_1(io_snpt_flushVec_1),
    .io_snpt_flushVec_2(io_snpt_flushVec_2),
    .io_snpt_flushVec_3(io_snpt_flushVec_3),
    .io_canEnq(i_io_canEnq),
    .io_canEnqForDispatch(i_io_canEnqForDispatch),
    .io_toDecode_isResumeVType(i_io_toDecode_isResumeVType),
    .io_toDecode_walkToArchVType(i_io_toDecode_walkToArchVType),
    .io_toDecode_walkVType_valid(i_io_toDecode_walkVType_valid),
    .io_toDecode_walkVType_bits_illegal(i_io_toDecode_walkVType_bits_illegal),
    .io_toDecode_walkVType_bits_vma(i_io_toDecode_walkVType_bits_vma),
    .io_toDecode_walkVType_bits_vta(i_io_toDecode_walkVType_bits_vta),
    .io_toDecode_walkVType_bits_vsew(i_io_toDecode_walkVType_bits_vsew),
    .io_toDecode_walkVType_bits_vlmul(i_io_toDecode_walkVType_bits_vlmul),
    .io_toDecode_commitVType_vtype_valid(i_io_toDecode_commitVType_vtype_valid),
    .io_toDecode_commitVType_vtype_bits_illegal(i_io_toDecode_commitVType_vtype_bits_illegal),
    .io_toDecode_commitVType_vtype_bits_vma(i_io_toDecode_commitVType_vtype_bits_vma),
    .io_toDecode_commitVType_vtype_bits_vta(i_io_toDecode_commitVType_vtype_bits_vta),
    .io_toDecode_commitVType_vtype_bits_vsew(i_io_toDecode_commitVType_vtype_bits_vsew),
    .io_toDecode_commitVType_vtype_bits_vlmul(i_io_toDecode_commitVType_vtype_bits_vlmul),
    .io_toDecode_commitVType_hasVsetvl(i_io_toDecode_commitVType_hasVsetvl),
    .io_status_walkEnd(i_io_status_walkEnd)
  );

  task automatic drive_inputs();
    reset = ($urandom_range(0,99) < 3);
    io_redirect_valid = $urandom;
    io_req_0_valid = $urandom;
    io_req_0_bits_fuOpType = $urandom;
    io_req_0_bits_vpu_vill = $urandom;
    io_req_0_bits_vpu_vma = $urandom;
    io_req_0_bits_vpu_vta = $urandom;
    io_req_0_bits_vpu_vsew = $urandom;
    io_req_0_bits_vpu_vlmul = $urandom;
    io_req_0_bits_vpu_specVill = $urandom;
    io_req_0_bits_vpu_specVma = $urandom;
    io_req_0_bits_vpu_specVta = $urandom;
    io_req_0_bits_vpu_specVsew = $urandom;
    io_req_0_bits_vpu_specVlmul = $urandom;
    io_req_0_bits_isVset = $urandom;
    io_req_0_bits_lastUop = $urandom;
    io_req_1_valid = $urandom;
    io_req_1_bits_fuOpType = $urandom;
    io_req_1_bits_vpu_vill = $urandom;
    io_req_1_bits_vpu_vma = $urandom;
    io_req_1_bits_vpu_vta = $urandom;
    io_req_1_bits_vpu_vsew = $urandom;
    io_req_1_bits_vpu_vlmul = $urandom;
    io_req_1_bits_vpu_specVill = $urandom;
    io_req_1_bits_vpu_specVma = $urandom;
    io_req_1_bits_vpu_specVta = $urandom;
    io_req_1_bits_vpu_specVsew = $urandom;
    io_req_1_bits_vpu_specVlmul = $urandom;
    io_req_1_bits_isVset = $urandom;
    io_req_1_bits_lastUop = $urandom;
    io_req_2_valid = $urandom;
    io_req_2_bits_fuOpType = $urandom;
    io_req_2_bits_vpu_vill = $urandom;
    io_req_2_bits_vpu_vma = $urandom;
    io_req_2_bits_vpu_vta = $urandom;
    io_req_2_bits_vpu_vsew = $urandom;
    io_req_2_bits_vpu_vlmul = $urandom;
    io_req_2_bits_vpu_specVill = $urandom;
    io_req_2_bits_vpu_specVma = $urandom;
    io_req_2_bits_vpu_specVta = $urandom;
    io_req_2_bits_vpu_specVsew = $urandom;
    io_req_2_bits_vpu_specVlmul = $urandom;
    io_req_2_bits_isVset = $urandom;
    io_req_2_bits_lastUop = $urandom;
    io_req_3_valid = $urandom;
    io_req_3_bits_fuOpType = $urandom;
    io_req_3_bits_vpu_vill = $urandom;
    io_req_3_bits_vpu_vma = $urandom;
    io_req_3_bits_vpu_vta = $urandom;
    io_req_3_bits_vpu_vsew = $urandom;
    io_req_3_bits_vpu_vlmul = $urandom;
    io_req_3_bits_vpu_specVill = $urandom;
    io_req_3_bits_vpu_specVma = $urandom;
    io_req_3_bits_vpu_specVta = $urandom;
    io_req_3_bits_vpu_specVsew = $urandom;
    io_req_3_bits_vpu_specVlmul = $urandom;
    io_req_3_bits_isVset = $urandom;
    io_req_3_bits_lastUop = $urandom;
    io_req_4_valid = $urandom;
    io_req_4_bits_fuOpType = $urandom;
    io_req_4_bits_vpu_vill = $urandom;
    io_req_4_bits_vpu_vma = $urandom;
    io_req_4_bits_vpu_vta = $urandom;
    io_req_4_bits_vpu_vsew = $urandom;
    io_req_4_bits_vpu_vlmul = $urandom;
    io_req_4_bits_vpu_specVill = $urandom;
    io_req_4_bits_vpu_specVma = $urandom;
    io_req_4_bits_vpu_specVta = $urandom;
    io_req_4_bits_vpu_specVsew = $urandom;
    io_req_4_bits_vpu_specVlmul = $urandom;
    io_req_4_bits_isVset = $urandom;
    io_req_4_bits_lastUop = $urandom;
    io_req_5_valid = $urandom;
    io_req_5_bits_fuOpType = $urandom;
    io_req_5_bits_vpu_vill = $urandom;
    io_req_5_bits_vpu_vma = $urandom;
    io_req_5_bits_vpu_vta = $urandom;
    io_req_5_bits_vpu_vsew = $urandom;
    io_req_5_bits_vpu_vlmul = $urandom;
    io_req_5_bits_vpu_specVill = $urandom;
    io_req_5_bits_vpu_specVma = $urandom;
    io_req_5_bits_vpu_specVta = $urandom;
    io_req_5_bits_vpu_specVsew = $urandom;
    io_req_5_bits_vpu_specVlmul = $urandom;
    io_req_5_bits_isVset = $urandom;
    io_req_5_bits_lastUop = $urandom;
    io_fromRob_walkSize = $urandom;
    io_fromRob_walkEnd = $urandom;
    io_fromRob_commitSize = $urandom;
    io_snpt_snptEnq = $urandom;
    io_snpt_snptDeq = $urandom;
    io_snpt_useSnpt = $urandom;
    io_snpt_snptSelect = $urandom;
    io_snpt_flushVec_0 = $urandom;
    io_snpt_flushVec_1 = $urandom;
    io_snpt_flushVec_2 = $urandom;
    io_snpt_flushVec_3 = $urandom;
  endtask
  task automatic check_outputs();
    if (!$isunknown(g_io_canEnq) && (g_io_canEnq) !== (i_io_canEnq)) begin errors++; if (errors<=60) $display("[%0t] io_canEnq g=%h i=%h",$time,g_io_canEnq,i_io_canEnq); end checks++;
    if (!$isunknown(g_io_canEnqForDispatch) && (g_io_canEnqForDispatch) !== (i_io_canEnqForDispatch)) begin errors++; if (errors<=60) $display("[%0t] io_canEnqForDispatch g=%h i=%h",$time,g_io_canEnqForDispatch,i_io_canEnqForDispatch); end checks++;
    if (!$isunknown(g_io_toDecode_isResumeVType) && (g_io_toDecode_isResumeVType) !== (i_io_toDecode_isResumeVType)) begin errors++; if (errors<=60) $display("[%0t] io_toDecode_isResumeVType g=%h i=%h",$time,g_io_toDecode_isResumeVType,i_io_toDecode_isResumeVType); end checks++;
    if (!$isunknown(g_io_toDecode_walkToArchVType) && (g_io_toDecode_walkToArchVType) !== (i_io_toDecode_walkToArchVType)) begin errors++; if (errors<=60) $display("[%0t] io_toDecode_walkToArchVType g=%h i=%h",$time,g_io_toDecode_walkToArchVType,i_io_toDecode_walkToArchVType); end checks++;
    if (!$isunknown(g_io_toDecode_walkVType_valid) && (g_io_toDecode_walkVType_valid) !== (i_io_toDecode_walkVType_valid)) begin errors++; if (errors<=60) $display("[%0t] io_toDecode_walkVType_valid g=%h i=%h",$time,g_io_toDecode_walkVType_valid,i_io_toDecode_walkVType_valid); end checks++;
    if (!$isunknown(g_io_toDecode_walkVType_bits_illegal) && (g_io_toDecode_walkVType_bits_illegal) !== (i_io_toDecode_walkVType_bits_illegal)) begin errors++; if (errors<=60) $display("[%0t] io_toDecode_walkVType_bits_illegal g=%h i=%h",$time,g_io_toDecode_walkVType_bits_illegal,i_io_toDecode_walkVType_bits_illegal); end checks++;
    if (!$isunknown(g_io_toDecode_walkVType_bits_vma) && (g_io_toDecode_walkVType_bits_vma) !== (i_io_toDecode_walkVType_bits_vma)) begin errors++; if (errors<=60) $display("[%0t] io_toDecode_walkVType_bits_vma g=%h i=%h",$time,g_io_toDecode_walkVType_bits_vma,i_io_toDecode_walkVType_bits_vma); end checks++;
    if (!$isunknown(g_io_toDecode_walkVType_bits_vta) && (g_io_toDecode_walkVType_bits_vta) !== (i_io_toDecode_walkVType_bits_vta)) begin errors++; if (errors<=60) $display("[%0t] io_toDecode_walkVType_bits_vta g=%h i=%h",$time,g_io_toDecode_walkVType_bits_vta,i_io_toDecode_walkVType_bits_vta); end checks++;
    if (!$isunknown(g_io_toDecode_walkVType_bits_vsew) && (g_io_toDecode_walkVType_bits_vsew) !== (i_io_toDecode_walkVType_bits_vsew)) begin errors++; if (errors<=60) $display("[%0t] io_toDecode_walkVType_bits_vsew g=%h i=%h",$time,g_io_toDecode_walkVType_bits_vsew,i_io_toDecode_walkVType_bits_vsew); end checks++;
    if (!$isunknown(g_io_toDecode_walkVType_bits_vlmul) && (g_io_toDecode_walkVType_bits_vlmul) !== (i_io_toDecode_walkVType_bits_vlmul)) begin errors++; if (errors<=60) $display("[%0t] io_toDecode_walkVType_bits_vlmul g=%h i=%h",$time,g_io_toDecode_walkVType_bits_vlmul,i_io_toDecode_walkVType_bits_vlmul); end checks++;
    if (!$isunknown(g_io_toDecode_commitVType_vtype_valid) && (g_io_toDecode_commitVType_vtype_valid) !== (i_io_toDecode_commitVType_vtype_valid)) begin errors++; if (errors<=60) $display("[%0t] io_toDecode_commitVType_vtype_valid g=%h i=%h",$time,g_io_toDecode_commitVType_vtype_valid,i_io_toDecode_commitVType_vtype_valid); end checks++;
    if (!$isunknown(g_io_toDecode_commitVType_vtype_bits_illegal) && (g_io_toDecode_commitVType_vtype_bits_illegal) !== (i_io_toDecode_commitVType_vtype_bits_illegal)) begin errors++; if (errors<=60) $display("[%0t] io_toDecode_commitVType_vtype_bits_illegal g=%h i=%h",$time,g_io_toDecode_commitVType_vtype_bits_illegal,i_io_toDecode_commitVType_vtype_bits_illegal); end checks++;
    if (!$isunknown(g_io_toDecode_commitVType_vtype_bits_vma) && (g_io_toDecode_commitVType_vtype_bits_vma) !== (i_io_toDecode_commitVType_vtype_bits_vma)) begin errors++; if (errors<=60) $display("[%0t] io_toDecode_commitVType_vtype_bits_vma g=%h i=%h",$time,g_io_toDecode_commitVType_vtype_bits_vma,i_io_toDecode_commitVType_vtype_bits_vma); end checks++;
    if (!$isunknown(g_io_toDecode_commitVType_vtype_bits_vta) && (g_io_toDecode_commitVType_vtype_bits_vta) !== (i_io_toDecode_commitVType_vtype_bits_vta)) begin errors++; if (errors<=60) $display("[%0t] io_toDecode_commitVType_vtype_bits_vta g=%h i=%h",$time,g_io_toDecode_commitVType_vtype_bits_vta,i_io_toDecode_commitVType_vtype_bits_vta); end checks++;
    if (!$isunknown(g_io_toDecode_commitVType_vtype_bits_vsew) && (g_io_toDecode_commitVType_vtype_bits_vsew) !== (i_io_toDecode_commitVType_vtype_bits_vsew)) begin errors++; if (errors<=60) $display("[%0t] io_toDecode_commitVType_vtype_bits_vsew g=%h i=%h",$time,g_io_toDecode_commitVType_vtype_bits_vsew,i_io_toDecode_commitVType_vtype_bits_vsew); end checks++;
    if (!$isunknown(g_io_toDecode_commitVType_vtype_bits_vlmul) && (g_io_toDecode_commitVType_vtype_bits_vlmul) !== (i_io_toDecode_commitVType_vtype_bits_vlmul)) begin errors++; if (errors<=60) $display("[%0t] io_toDecode_commitVType_vtype_bits_vlmul g=%h i=%h",$time,g_io_toDecode_commitVType_vtype_bits_vlmul,i_io_toDecode_commitVType_vtype_bits_vlmul); end checks++;
    if (!$isunknown(g_io_toDecode_commitVType_hasVsetvl) && (g_io_toDecode_commitVType_hasVsetvl) !== (i_io_toDecode_commitVType_hasVsetvl)) begin errors++; if (errors<=60) $display("[%0t] io_toDecode_commitVType_hasVsetvl g=%h i=%h",$time,g_io_toDecode_commitVType_hasVsetvl,i_io_toDecode_commitVType_hasVsetvl); end checks++;
    if (!$isunknown(g_io_status_walkEnd) && (g_io_status_walkEnd) !== (i_io_status_walkEnd)) begin errors++; if (errors<=60) $display("[%0t] io_status_walkEnd g=%h i=%h",$time,g_io_status_walkEnd,i_io_status_walkEnd); end checks++;
  endtask

  initial begin
    drive_inputs(); reset = 1;
    repeat (5) @(negedge clk);
    repeat (NCYCLES) begin
      drive_inputs();
      @(posedge clk);
      #1 check_outputs();
      @(negedge clk);
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
