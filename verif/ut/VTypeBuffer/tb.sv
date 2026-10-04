// 自动生成：verif/ut/VTypeBuffer/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
// VTypeBuffer 双例化逐拍比对：golden VTypeBuffer vs 重写 VTypeBuffer_xs，全部输出逐位 !==。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= VTypeBuffer =================
  int unsigned vb_mode = 0;
  logic [63:0] vb_wmask = '0;
  always @(posedge clk) begin
    if (vb_u_gold.vtypeBuffer.io_wen_0) vb_wmask[vb_u_gold.vtypeBuffer.io_waddr_0] <= 1'b1;
    if (vb_u_gold.vtypeBuffer.io_wen_1) vb_wmask[vb_u_gold.vtypeBuffer.io_waddr_1] <= 1'b1;
    if (vb_u_gold.vtypeBuffer.io_wen_2) vb_wmask[vb_u_gold.vtypeBuffer.io_waddr_2] <= 1'b1;
    if (vb_u_gold.vtypeBuffer.io_wen_3) vb_wmask[vb_u_gold.vtypeBuffer.io_waddr_3] <= 1'b1;
    if (vb_u_gold.vtypeBuffer.io_wen_4) vb_wmask[vb_u_gold.vtypeBuffer.io_waddr_4] <= 1'b1;
    if (vb_u_gold.vtypeBuffer.io_wen_5) vb_wmask[vb_u_gold.vtypeBuffer.io_waddr_5] <= 1'b1;
  end
  logic vb_reset;
  logic vb_io_redirect_valid;
  logic vb_io_req_0_valid;
  logic [8:0] vb_io_req_0_bits_fuOpType;
  logic vb_io_req_0_bits_vpu_vill;
  logic vb_io_req_0_bits_vpu_vma;
  logic vb_io_req_0_bits_vpu_vta;
  logic [1:0] vb_io_req_0_bits_vpu_vsew;
  logic [2:0] vb_io_req_0_bits_vpu_vlmul;
  logic vb_io_req_0_bits_vpu_specVill;
  logic vb_io_req_0_bits_vpu_specVma;
  logic vb_io_req_0_bits_vpu_specVta;
  logic [1:0] vb_io_req_0_bits_vpu_specVsew;
  logic [2:0] vb_io_req_0_bits_vpu_specVlmul;
  logic vb_io_req_0_bits_isVset;
  logic vb_io_req_0_bits_lastUop;
  logic vb_io_req_1_valid;
  logic [8:0] vb_io_req_1_bits_fuOpType;
  logic vb_io_req_1_bits_vpu_vill;
  logic vb_io_req_1_bits_vpu_vma;
  logic vb_io_req_1_bits_vpu_vta;
  logic [1:0] vb_io_req_1_bits_vpu_vsew;
  logic [2:0] vb_io_req_1_bits_vpu_vlmul;
  logic vb_io_req_1_bits_vpu_specVill;
  logic vb_io_req_1_bits_vpu_specVma;
  logic vb_io_req_1_bits_vpu_specVta;
  logic [1:0] vb_io_req_1_bits_vpu_specVsew;
  logic [2:0] vb_io_req_1_bits_vpu_specVlmul;
  logic vb_io_req_1_bits_isVset;
  logic vb_io_req_1_bits_lastUop;
  logic vb_io_req_2_valid;
  logic [8:0] vb_io_req_2_bits_fuOpType;
  logic vb_io_req_2_bits_vpu_vill;
  logic vb_io_req_2_bits_vpu_vma;
  logic vb_io_req_2_bits_vpu_vta;
  logic [1:0] vb_io_req_2_bits_vpu_vsew;
  logic [2:0] vb_io_req_2_bits_vpu_vlmul;
  logic vb_io_req_2_bits_vpu_specVill;
  logic vb_io_req_2_bits_vpu_specVma;
  logic vb_io_req_2_bits_vpu_specVta;
  logic [1:0] vb_io_req_2_bits_vpu_specVsew;
  logic [2:0] vb_io_req_2_bits_vpu_specVlmul;
  logic vb_io_req_2_bits_isVset;
  logic vb_io_req_2_bits_lastUop;
  logic vb_io_req_3_valid;
  logic [8:0] vb_io_req_3_bits_fuOpType;
  logic vb_io_req_3_bits_vpu_vill;
  logic vb_io_req_3_bits_vpu_vma;
  logic vb_io_req_3_bits_vpu_vta;
  logic [1:0] vb_io_req_3_bits_vpu_vsew;
  logic [2:0] vb_io_req_3_bits_vpu_vlmul;
  logic vb_io_req_3_bits_vpu_specVill;
  logic vb_io_req_3_bits_vpu_specVma;
  logic vb_io_req_3_bits_vpu_specVta;
  logic [1:0] vb_io_req_3_bits_vpu_specVsew;
  logic [2:0] vb_io_req_3_bits_vpu_specVlmul;
  logic vb_io_req_3_bits_isVset;
  logic vb_io_req_3_bits_lastUop;
  logic vb_io_req_4_valid;
  logic [8:0] vb_io_req_4_bits_fuOpType;
  logic vb_io_req_4_bits_vpu_vill;
  logic vb_io_req_4_bits_vpu_vma;
  logic vb_io_req_4_bits_vpu_vta;
  logic [1:0] vb_io_req_4_bits_vpu_vsew;
  logic [2:0] vb_io_req_4_bits_vpu_vlmul;
  logic vb_io_req_4_bits_vpu_specVill;
  logic vb_io_req_4_bits_vpu_specVma;
  logic vb_io_req_4_bits_vpu_specVta;
  logic [1:0] vb_io_req_4_bits_vpu_specVsew;
  logic [2:0] vb_io_req_4_bits_vpu_specVlmul;
  logic vb_io_req_4_bits_isVset;
  logic vb_io_req_4_bits_lastUop;
  logic vb_io_req_5_valid;
  logic [8:0] vb_io_req_5_bits_fuOpType;
  logic vb_io_req_5_bits_vpu_vill;
  logic vb_io_req_5_bits_vpu_vma;
  logic vb_io_req_5_bits_vpu_vta;
  logic [1:0] vb_io_req_5_bits_vpu_vsew;
  logic [2:0] vb_io_req_5_bits_vpu_vlmul;
  logic vb_io_req_5_bits_vpu_specVill;
  logic vb_io_req_5_bits_vpu_specVma;
  logic vb_io_req_5_bits_vpu_specVta;
  logic [1:0] vb_io_req_5_bits_vpu_specVsew;
  logic [2:0] vb_io_req_5_bits_vpu_specVlmul;
  logic vb_io_req_5_bits_isVset;
  logic vb_io_req_5_bits_lastUop;
  logic [5:0] vb_io_fromRob_walkSize;
  logic vb_io_fromRob_walkEnd;
  logic [5:0] vb_io_fromRob_commitSize;
  logic vb_io_snpt_snptEnq;
  logic vb_io_snpt_snptDeq;
  logic vb_io_snpt_useSnpt;
  logic [1:0] vb_io_snpt_snptSelect;
  logic vb_io_snpt_flushVec_0;
  logic vb_io_snpt_flushVec_1;
  logic vb_io_snpt_flushVec_2;
  logic vb_io_snpt_flushVec_3;
  wire  vb_g_io_canEnq, vb_i_io_canEnq;
  logic vb_s0_io_canEnq = '0, vb_s1_io_canEnq = '0;
  wire  vb_g_io_canEnqForDispatch, vb_i_io_canEnqForDispatch;
  logic vb_s0_io_canEnqForDispatch = '0, vb_s1_io_canEnqForDispatch = '0;
  wire  vb_g_io_toDecode_isResumeVType, vb_i_io_toDecode_isResumeVType;
  logic vb_s0_io_toDecode_isResumeVType = '0, vb_s1_io_toDecode_isResumeVType = '0;
  wire  vb_g_io_toDecode_walkToArchVType, vb_i_io_toDecode_walkToArchVType;
  logic vb_s0_io_toDecode_walkToArchVType = '0, vb_s1_io_toDecode_walkToArchVType = '0;
  wire  vb_g_io_toDecode_walkVType_valid, vb_i_io_toDecode_walkVType_valid;
  logic vb_s0_io_toDecode_walkVType_valid = '0, vb_s1_io_toDecode_walkVType_valid = '0;
  wire  vb_g_io_toDecode_walkVType_bits_illegal, vb_i_io_toDecode_walkVType_bits_illegal;
  logic vb_s0_io_toDecode_walkVType_bits_illegal = '0, vb_s1_io_toDecode_walkVType_bits_illegal = '0;
  wire  vb_g_io_toDecode_walkVType_bits_vma, vb_i_io_toDecode_walkVType_bits_vma;
  logic vb_s0_io_toDecode_walkVType_bits_vma = '0, vb_s1_io_toDecode_walkVType_bits_vma = '0;
  wire  vb_g_io_toDecode_walkVType_bits_vta, vb_i_io_toDecode_walkVType_bits_vta;
  logic vb_s0_io_toDecode_walkVType_bits_vta = '0, vb_s1_io_toDecode_walkVType_bits_vta = '0;
  wire  [1:0] vb_g_io_toDecode_walkVType_bits_vsew, vb_i_io_toDecode_walkVType_bits_vsew;
  logic [1:0] vb_s0_io_toDecode_walkVType_bits_vsew = '0, vb_s1_io_toDecode_walkVType_bits_vsew = '0;
  wire  [2:0] vb_g_io_toDecode_walkVType_bits_vlmul, vb_i_io_toDecode_walkVType_bits_vlmul;
  logic [2:0] vb_s0_io_toDecode_walkVType_bits_vlmul = '0, vb_s1_io_toDecode_walkVType_bits_vlmul = '0;
  wire  vb_g_io_toDecode_commitVType_vtype_valid, vb_i_io_toDecode_commitVType_vtype_valid;
  logic vb_s0_io_toDecode_commitVType_vtype_valid = '0, vb_s1_io_toDecode_commitVType_vtype_valid = '0;
  wire  vb_g_io_toDecode_commitVType_vtype_bits_illegal, vb_i_io_toDecode_commitVType_vtype_bits_illegal;
  logic vb_s0_io_toDecode_commitVType_vtype_bits_illegal = '0, vb_s1_io_toDecode_commitVType_vtype_bits_illegal = '0;
  wire  vb_g_io_toDecode_commitVType_vtype_bits_vma, vb_i_io_toDecode_commitVType_vtype_bits_vma;
  logic vb_s0_io_toDecode_commitVType_vtype_bits_vma = '0, vb_s1_io_toDecode_commitVType_vtype_bits_vma = '0;
  wire  vb_g_io_toDecode_commitVType_vtype_bits_vta, vb_i_io_toDecode_commitVType_vtype_bits_vta;
  logic vb_s0_io_toDecode_commitVType_vtype_bits_vta = '0, vb_s1_io_toDecode_commitVType_vtype_bits_vta = '0;
  wire  [1:0] vb_g_io_toDecode_commitVType_vtype_bits_vsew, vb_i_io_toDecode_commitVType_vtype_bits_vsew;
  logic [1:0] vb_s0_io_toDecode_commitVType_vtype_bits_vsew = '0, vb_s1_io_toDecode_commitVType_vtype_bits_vsew = '0;
  wire  [2:0] vb_g_io_toDecode_commitVType_vtype_bits_vlmul, vb_i_io_toDecode_commitVType_vtype_bits_vlmul;
  logic [2:0] vb_s0_io_toDecode_commitVType_vtype_bits_vlmul = '0, vb_s1_io_toDecode_commitVType_vtype_bits_vlmul = '0;
  wire  vb_g_io_toDecode_commitVType_hasVsetvl, vb_i_io_toDecode_commitVType_hasVsetvl;
  logic vb_s0_io_toDecode_commitVType_hasVsetvl = '0, vb_s1_io_toDecode_commitVType_hasVsetvl = '0;
  wire  vb_g_io_status_walkEnd, vb_i_io_status_walkEnd;
  logic vb_s0_io_status_walkEnd = '0, vb_s1_io_status_walkEnd = '0;
  int vb_cov_st_spcl = 0;
  int vb_cov_st_walk = 0;
  int vb_cov_spcl_to_walk = 0;
  int vb_cov_walk_to_idle = 0;
  int vb_cov_use_snapshot = 0;
  int vb_cov_walk_to_arch = 0;
  int vb_cov_walk_vtype = 0;
  int vb_cov_commit_vtype = 0;
  int vb_cov_has_vsetvl = 0;
  int vb_cov_full_canenq = 0;
  int vb_cov_full_dispatch = 0;
  int vb_cov_enq_wrap = 0;
  logic [4:0] vb_armed = '0;
  int vb_armed_at = -1;
  VTypeBuffer vb_u_gold (
    .clock(clk),
    .reset(vb_reset),
    .io_redirect_valid(vb_io_redirect_valid),
    .io_req_0_valid(vb_io_req_0_valid),
    .io_req_0_bits_fuOpType(vb_io_req_0_bits_fuOpType),
    .io_req_0_bits_vpu_vill(vb_io_req_0_bits_vpu_vill),
    .io_req_0_bits_vpu_vma(vb_io_req_0_bits_vpu_vma),
    .io_req_0_bits_vpu_vta(vb_io_req_0_bits_vpu_vta),
    .io_req_0_bits_vpu_vsew(vb_io_req_0_bits_vpu_vsew),
    .io_req_0_bits_vpu_vlmul(vb_io_req_0_bits_vpu_vlmul),
    .io_req_0_bits_vpu_specVill(vb_io_req_0_bits_vpu_specVill),
    .io_req_0_bits_vpu_specVma(vb_io_req_0_bits_vpu_specVma),
    .io_req_0_bits_vpu_specVta(vb_io_req_0_bits_vpu_specVta),
    .io_req_0_bits_vpu_specVsew(vb_io_req_0_bits_vpu_specVsew),
    .io_req_0_bits_vpu_specVlmul(vb_io_req_0_bits_vpu_specVlmul),
    .io_req_0_bits_isVset(vb_io_req_0_bits_isVset),
    .io_req_0_bits_lastUop(vb_io_req_0_bits_lastUop),
    .io_req_1_valid(vb_io_req_1_valid),
    .io_req_1_bits_fuOpType(vb_io_req_1_bits_fuOpType),
    .io_req_1_bits_vpu_vill(vb_io_req_1_bits_vpu_vill),
    .io_req_1_bits_vpu_vma(vb_io_req_1_bits_vpu_vma),
    .io_req_1_bits_vpu_vta(vb_io_req_1_bits_vpu_vta),
    .io_req_1_bits_vpu_vsew(vb_io_req_1_bits_vpu_vsew),
    .io_req_1_bits_vpu_vlmul(vb_io_req_1_bits_vpu_vlmul),
    .io_req_1_bits_vpu_specVill(vb_io_req_1_bits_vpu_specVill),
    .io_req_1_bits_vpu_specVma(vb_io_req_1_bits_vpu_specVma),
    .io_req_1_bits_vpu_specVta(vb_io_req_1_bits_vpu_specVta),
    .io_req_1_bits_vpu_specVsew(vb_io_req_1_bits_vpu_specVsew),
    .io_req_1_bits_vpu_specVlmul(vb_io_req_1_bits_vpu_specVlmul),
    .io_req_1_bits_isVset(vb_io_req_1_bits_isVset),
    .io_req_1_bits_lastUop(vb_io_req_1_bits_lastUop),
    .io_req_2_valid(vb_io_req_2_valid),
    .io_req_2_bits_fuOpType(vb_io_req_2_bits_fuOpType),
    .io_req_2_bits_vpu_vill(vb_io_req_2_bits_vpu_vill),
    .io_req_2_bits_vpu_vma(vb_io_req_2_bits_vpu_vma),
    .io_req_2_bits_vpu_vta(vb_io_req_2_bits_vpu_vta),
    .io_req_2_bits_vpu_vsew(vb_io_req_2_bits_vpu_vsew),
    .io_req_2_bits_vpu_vlmul(vb_io_req_2_bits_vpu_vlmul),
    .io_req_2_bits_vpu_specVill(vb_io_req_2_bits_vpu_specVill),
    .io_req_2_bits_vpu_specVma(vb_io_req_2_bits_vpu_specVma),
    .io_req_2_bits_vpu_specVta(vb_io_req_2_bits_vpu_specVta),
    .io_req_2_bits_vpu_specVsew(vb_io_req_2_bits_vpu_specVsew),
    .io_req_2_bits_vpu_specVlmul(vb_io_req_2_bits_vpu_specVlmul),
    .io_req_2_bits_isVset(vb_io_req_2_bits_isVset),
    .io_req_2_bits_lastUop(vb_io_req_2_bits_lastUop),
    .io_req_3_valid(vb_io_req_3_valid),
    .io_req_3_bits_fuOpType(vb_io_req_3_bits_fuOpType),
    .io_req_3_bits_vpu_vill(vb_io_req_3_bits_vpu_vill),
    .io_req_3_bits_vpu_vma(vb_io_req_3_bits_vpu_vma),
    .io_req_3_bits_vpu_vta(vb_io_req_3_bits_vpu_vta),
    .io_req_3_bits_vpu_vsew(vb_io_req_3_bits_vpu_vsew),
    .io_req_3_bits_vpu_vlmul(vb_io_req_3_bits_vpu_vlmul),
    .io_req_3_bits_vpu_specVill(vb_io_req_3_bits_vpu_specVill),
    .io_req_3_bits_vpu_specVma(vb_io_req_3_bits_vpu_specVma),
    .io_req_3_bits_vpu_specVta(vb_io_req_3_bits_vpu_specVta),
    .io_req_3_bits_vpu_specVsew(vb_io_req_3_bits_vpu_specVsew),
    .io_req_3_bits_vpu_specVlmul(vb_io_req_3_bits_vpu_specVlmul),
    .io_req_3_bits_isVset(vb_io_req_3_bits_isVset),
    .io_req_3_bits_lastUop(vb_io_req_3_bits_lastUop),
    .io_req_4_valid(vb_io_req_4_valid),
    .io_req_4_bits_fuOpType(vb_io_req_4_bits_fuOpType),
    .io_req_4_bits_vpu_vill(vb_io_req_4_bits_vpu_vill),
    .io_req_4_bits_vpu_vma(vb_io_req_4_bits_vpu_vma),
    .io_req_4_bits_vpu_vta(vb_io_req_4_bits_vpu_vta),
    .io_req_4_bits_vpu_vsew(vb_io_req_4_bits_vpu_vsew),
    .io_req_4_bits_vpu_vlmul(vb_io_req_4_bits_vpu_vlmul),
    .io_req_4_bits_vpu_specVill(vb_io_req_4_bits_vpu_specVill),
    .io_req_4_bits_vpu_specVma(vb_io_req_4_bits_vpu_specVma),
    .io_req_4_bits_vpu_specVta(vb_io_req_4_bits_vpu_specVta),
    .io_req_4_bits_vpu_specVsew(vb_io_req_4_bits_vpu_specVsew),
    .io_req_4_bits_vpu_specVlmul(vb_io_req_4_bits_vpu_specVlmul),
    .io_req_4_bits_isVset(vb_io_req_4_bits_isVset),
    .io_req_4_bits_lastUop(vb_io_req_4_bits_lastUop),
    .io_req_5_valid(vb_io_req_5_valid),
    .io_req_5_bits_fuOpType(vb_io_req_5_bits_fuOpType),
    .io_req_5_bits_vpu_vill(vb_io_req_5_bits_vpu_vill),
    .io_req_5_bits_vpu_vma(vb_io_req_5_bits_vpu_vma),
    .io_req_5_bits_vpu_vta(vb_io_req_5_bits_vpu_vta),
    .io_req_5_bits_vpu_vsew(vb_io_req_5_bits_vpu_vsew),
    .io_req_5_bits_vpu_vlmul(vb_io_req_5_bits_vpu_vlmul),
    .io_req_5_bits_vpu_specVill(vb_io_req_5_bits_vpu_specVill),
    .io_req_5_bits_vpu_specVma(vb_io_req_5_bits_vpu_specVma),
    .io_req_5_bits_vpu_specVta(vb_io_req_5_bits_vpu_specVta),
    .io_req_5_bits_vpu_specVsew(vb_io_req_5_bits_vpu_specVsew),
    .io_req_5_bits_vpu_specVlmul(vb_io_req_5_bits_vpu_specVlmul),
    .io_req_5_bits_isVset(vb_io_req_5_bits_isVset),
    .io_req_5_bits_lastUop(vb_io_req_5_bits_lastUop),
    .io_fromRob_walkSize(vb_io_fromRob_walkSize),
    .io_fromRob_walkEnd(vb_io_fromRob_walkEnd),
    .io_fromRob_commitSize(vb_io_fromRob_commitSize),
    .io_snpt_snptEnq(vb_io_snpt_snptEnq),
    .io_snpt_snptDeq(vb_io_snpt_snptDeq),
    .io_snpt_useSnpt(vb_io_snpt_useSnpt),
    .io_snpt_snptSelect(vb_io_snpt_snptSelect),
    .io_snpt_flushVec_0(vb_io_snpt_flushVec_0),
    .io_snpt_flushVec_1(vb_io_snpt_flushVec_1),
    .io_snpt_flushVec_2(vb_io_snpt_flushVec_2),
    .io_snpt_flushVec_3(vb_io_snpt_flushVec_3),
    .io_canEnq(vb_g_io_canEnq),
    .io_canEnqForDispatch(vb_g_io_canEnqForDispatch),
    .io_toDecode_isResumeVType(vb_g_io_toDecode_isResumeVType),
    .io_toDecode_walkToArchVType(vb_g_io_toDecode_walkToArchVType),
    .io_toDecode_walkVType_valid(vb_g_io_toDecode_walkVType_valid),
    .io_toDecode_walkVType_bits_illegal(vb_g_io_toDecode_walkVType_bits_illegal),
    .io_toDecode_walkVType_bits_vma(vb_g_io_toDecode_walkVType_bits_vma),
    .io_toDecode_walkVType_bits_vta(vb_g_io_toDecode_walkVType_bits_vta),
    .io_toDecode_walkVType_bits_vsew(vb_g_io_toDecode_walkVType_bits_vsew),
    .io_toDecode_walkVType_bits_vlmul(vb_g_io_toDecode_walkVType_bits_vlmul),
    .io_toDecode_commitVType_vtype_valid(vb_g_io_toDecode_commitVType_vtype_valid),
    .io_toDecode_commitVType_vtype_bits_illegal(vb_g_io_toDecode_commitVType_vtype_bits_illegal),
    .io_toDecode_commitVType_vtype_bits_vma(vb_g_io_toDecode_commitVType_vtype_bits_vma),
    .io_toDecode_commitVType_vtype_bits_vta(vb_g_io_toDecode_commitVType_vtype_bits_vta),
    .io_toDecode_commitVType_vtype_bits_vsew(vb_g_io_toDecode_commitVType_vtype_bits_vsew),
    .io_toDecode_commitVType_vtype_bits_vlmul(vb_g_io_toDecode_commitVType_vtype_bits_vlmul),
    .io_toDecode_commitVType_hasVsetvl(vb_g_io_toDecode_commitVType_hasVsetvl),
    .io_status_walkEnd(vb_g_io_status_walkEnd)
  );
  VTypeBuffer_xs vb_u_impl (
    .clock(clk),
    .reset(vb_reset),
    .io_redirect_valid(vb_io_redirect_valid),
    .io_req_0_valid(vb_io_req_0_valid),
    .io_req_0_bits_fuOpType(vb_io_req_0_bits_fuOpType),
    .io_req_0_bits_vpu_vill(vb_io_req_0_bits_vpu_vill),
    .io_req_0_bits_vpu_vma(vb_io_req_0_bits_vpu_vma),
    .io_req_0_bits_vpu_vta(vb_io_req_0_bits_vpu_vta),
    .io_req_0_bits_vpu_vsew(vb_io_req_0_bits_vpu_vsew),
    .io_req_0_bits_vpu_vlmul(vb_io_req_0_bits_vpu_vlmul),
    .io_req_0_bits_vpu_specVill(vb_io_req_0_bits_vpu_specVill),
    .io_req_0_bits_vpu_specVma(vb_io_req_0_bits_vpu_specVma),
    .io_req_0_bits_vpu_specVta(vb_io_req_0_bits_vpu_specVta),
    .io_req_0_bits_vpu_specVsew(vb_io_req_0_bits_vpu_specVsew),
    .io_req_0_bits_vpu_specVlmul(vb_io_req_0_bits_vpu_specVlmul),
    .io_req_0_bits_isVset(vb_io_req_0_bits_isVset),
    .io_req_0_bits_lastUop(vb_io_req_0_bits_lastUop),
    .io_req_1_valid(vb_io_req_1_valid),
    .io_req_1_bits_fuOpType(vb_io_req_1_bits_fuOpType),
    .io_req_1_bits_vpu_vill(vb_io_req_1_bits_vpu_vill),
    .io_req_1_bits_vpu_vma(vb_io_req_1_bits_vpu_vma),
    .io_req_1_bits_vpu_vta(vb_io_req_1_bits_vpu_vta),
    .io_req_1_bits_vpu_vsew(vb_io_req_1_bits_vpu_vsew),
    .io_req_1_bits_vpu_vlmul(vb_io_req_1_bits_vpu_vlmul),
    .io_req_1_bits_vpu_specVill(vb_io_req_1_bits_vpu_specVill),
    .io_req_1_bits_vpu_specVma(vb_io_req_1_bits_vpu_specVma),
    .io_req_1_bits_vpu_specVta(vb_io_req_1_bits_vpu_specVta),
    .io_req_1_bits_vpu_specVsew(vb_io_req_1_bits_vpu_specVsew),
    .io_req_1_bits_vpu_specVlmul(vb_io_req_1_bits_vpu_specVlmul),
    .io_req_1_bits_isVset(vb_io_req_1_bits_isVset),
    .io_req_1_bits_lastUop(vb_io_req_1_bits_lastUop),
    .io_req_2_valid(vb_io_req_2_valid),
    .io_req_2_bits_fuOpType(vb_io_req_2_bits_fuOpType),
    .io_req_2_bits_vpu_vill(vb_io_req_2_bits_vpu_vill),
    .io_req_2_bits_vpu_vma(vb_io_req_2_bits_vpu_vma),
    .io_req_2_bits_vpu_vta(vb_io_req_2_bits_vpu_vta),
    .io_req_2_bits_vpu_vsew(vb_io_req_2_bits_vpu_vsew),
    .io_req_2_bits_vpu_vlmul(vb_io_req_2_bits_vpu_vlmul),
    .io_req_2_bits_vpu_specVill(vb_io_req_2_bits_vpu_specVill),
    .io_req_2_bits_vpu_specVma(vb_io_req_2_bits_vpu_specVma),
    .io_req_2_bits_vpu_specVta(vb_io_req_2_bits_vpu_specVta),
    .io_req_2_bits_vpu_specVsew(vb_io_req_2_bits_vpu_specVsew),
    .io_req_2_bits_vpu_specVlmul(vb_io_req_2_bits_vpu_specVlmul),
    .io_req_2_bits_isVset(vb_io_req_2_bits_isVset),
    .io_req_2_bits_lastUop(vb_io_req_2_bits_lastUop),
    .io_req_3_valid(vb_io_req_3_valid),
    .io_req_3_bits_fuOpType(vb_io_req_3_bits_fuOpType),
    .io_req_3_bits_vpu_vill(vb_io_req_3_bits_vpu_vill),
    .io_req_3_bits_vpu_vma(vb_io_req_3_bits_vpu_vma),
    .io_req_3_bits_vpu_vta(vb_io_req_3_bits_vpu_vta),
    .io_req_3_bits_vpu_vsew(vb_io_req_3_bits_vpu_vsew),
    .io_req_3_bits_vpu_vlmul(vb_io_req_3_bits_vpu_vlmul),
    .io_req_3_bits_vpu_specVill(vb_io_req_3_bits_vpu_specVill),
    .io_req_3_bits_vpu_specVma(vb_io_req_3_bits_vpu_specVma),
    .io_req_3_bits_vpu_specVta(vb_io_req_3_bits_vpu_specVta),
    .io_req_3_bits_vpu_specVsew(vb_io_req_3_bits_vpu_specVsew),
    .io_req_3_bits_vpu_specVlmul(vb_io_req_3_bits_vpu_specVlmul),
    .io_req_3_bits_isVset(vb_io_req_3_bits_isVset),
    .io_req_3_bits_lastUop(vb_io_req_3_bits_lastUop),
    .io_req_4_valid(vb_io_req_4_valid),
    .io_req_4_bits_fuOpType(vb_io_req_4_bits_fuOpType),
    .io_req_4_bits_vpu_vill(vb_io_req_4_bits_vpu_vill),
    .io_req_4_bits_vpu_vma(vb_io_req_4_bits_vpu_vma),
    .io_req_4_bits_vpu_vta(vb_io_req_4_bits_vpu_vta),
    .io_req_4_bits_vpu_vsew(vb_io_req_4_bits_vpu_vsew),
    .io_req_4_bits_vpu_vlmul(vb_io_req_4_bits_vpu_vlmul),
    .io_req_4_bits_vpu_specVill(vb_io_req_4_bits_vpu_specVill),
    .io_req_4_bits_vpu_specVma(vb_io_req_4_bits_vpu_specVma),
    .io_req_4_bits_vpu_specVta(vb_io_req_4_bits_vpu_specVta),
    .io_req_4_bits_vpu_specVsew(vb_io_req_4_bits_vpu_specVsew),
    .io_req_4_bits_vpu_specVlmul(vb_io_req_4_bits_vpu_specVlmul),
    .io_req_4_bits_isVset(vb_io_req_4_bits_isVset),
    .io_req_4_bits_lastUop(vb_io_req_4_bits_lastUop),
    .io_req_5_valid(vb_io_req_5_valid),
    .io_req_5_bits_fuOpType(vb_io_req_5_bits_fuOpType),
    .io_req_5_bits_vpu_vill(vb_io_req_5_bits_vpu_vill),
    .io_req_5_bits_vpu_vma(vb_io_req_5_bits_vpu_vma),
    .io_req_5_bits_vpu_vta(vb_io_req_5_bits_vpu_vta),
    .io_req_5_bits_vpu_vsew(vb_io_req_5_bits_vpu_vsew),
    .io_req_5_bits_vpu_vlmul(vb_io_req_5_bits_vpu_vlmul),
    .io_req_5_bits_vpu_specVill(vb_io_req_5_bits_vpu_specVill),
    .io_req_5_bits_vpu_specVma(vb_io_req_5_bits_vpu_specVma),
    .io_req_5_bits_vpu_specVta(vb_io_req_5_bits_vpu_specVta),
    .io_req_5_bits_vpu_specVsew(vb_io_req_5_bits_vpu_specVsew),
    .io_req_5_bits_vpu_specVlmul(vb_io_req_5_bits_vpu_specVlmul),
    .io_req_5_bits_isVset(vb_io_req_5_bits_isVset),
    .io_req_5_bits_lastUop(vb_io_req_5_bits_lastUop),
    .io_fromRob_walkSize(vb_io_fromRob_walkSize),
    .io_fromRob_walkEnd(vb_io_fromRob_walkEnd),
    .io_fromRob_commitSize(vb_io_fromRob_commitSize),
    .io_snpt_snptEnq(vb_io_snpt_snptEnq),
    .io_snpt_snptDeq(vb_io_snpt_snptDeq),
    .io_snpt_useSnpt(vb_io_snpt_useSnpt),
    .io_snpt_snptSelect(vb_io_snpt_snptSelect),
    .io_snpt_flushVec_0(vb_io_snpt_flushVec_0),
    .io_snpt_flushVec_1(vb_io_snpt_flushVec_1),
    .io_snpt_flushVec_2(vb_io_snpt_flushVec_2),
    .io_snpt_flushVec_3(vb_io_snpt_flushVec_3),
    .io_canEnq(vb_i_io_canEnq),
    .io_canEnqForDispatch(vb_i_io_canEnqForDispatch),
    .io_toDecode_isResumeVType(vb_i_io_toDecode_isResumeVType),
    .io_toDecode_walkToArchVType(vb_i_io_toDecode_walkToArchVType),
    .io_toDecode_walkVType_valid(vb_i_io_toDecode_walkVType_valid),
    .io_toDecode_walkVType_bits_illegal(vb_i_io_toDecode_walkVType_bits_illegal),
    .io_toDecode_walkVType_bits_vma(vb_i_io_toDecode_walkVType_bits_vma),
    .io_toDecode_walkVType_bits_vta(vb_i_io_toDecode_walkVType_bits_vta),
    .io_toDecode_walkVType_bits_vsew(vb_i_io_toDecode_walkVType_bits_vsew),
    .io_toDecode_walkVType_bits_vlmul(vb_i_io_toDecode_walkVType_bits_vlmul),
    .io_toDecode_commitVType_vtype_valid(vb_i_io_toDecode_commitVType_vtype_valid),
    .io_toDecode_commitVType_vtype_bits_illegal(vb_i_io_toDecode_commitVType_vtype_bits_illegal),
    .io_toDecode_commitVType_vtype_bits_vma(vb_i_io_toDecode_commitVType_vtype_bits_vma),
    .io_toDecode_commitVType_vtype_bits_vta(vb_i_io_toDecode_commitVType_vtype_bits_vta),
    .io_toDecode_commitVType_vtype_bits_vsew(vb_i_io_toDecode_commitVType_vtype_bits_vsew),
    .io_toDecode_commitVType_vtype_bits_vlmul(vb_i_io_toDecode_commitVType_vtype_bits_vlmul),
    .io_toDecode_commitVType_hasVsetvl(vb_i_io_toDecode_commitVType_hasVsetvl),
    .io_status_walkEnd(vb_i_io_status_walkEnd)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 400 == 0) vb_mode = $urandom_range(0, 15);
      vb_io_redirect_valid = 1'($urandom);
      vb_io_req_0_valid = 1'($urandom);
      vb_io_req_0_bits_fuOpType = 9'($urandom);
      vb_io_req_0_bits_vpu_vill = 1'($urandom);
      vb_io_req_0_bits_vpu_vma = 1'($urandom);
      vb_io_req_0_bits_vpu_vta = 1'($urandom);
      vb_io_req_0_bits_vpu_vsew = 2'($urandom);
      vb_io_req_0_bits_vpu_vlmul = 3'($urandom);
      vb_io_req_0_bits_vpu_specVill = 1'($urandom);
      vb_io_req_0_bits_vpu_specVma = 1'($urandom);
      vb_io_req_0_bits_vpu_specVta = 1'($urandom);
      vb_io_req_0_bits_vpu_specVsew = 2'($urandom);
      vb_io_req_0_bits_vpu_specVlmul = 3'($urandom);
      vb_io_req_0_bits_isVset = 1'($urandom);
      vb_io_req_0_bits_lastUop = 1'($urandom);
      vb_io_req_1_valid = 1'($urandom);
      vb_io_req_1_bits_fuOpType = 9'($urandom);
      vb_io_req_1_bits_vpu_vill = 1'($urandom);
      vb_io_req_1_bits_vpu_vma = 1'($urandom);
      vb_io_req_1_bits_vpu_vta = 1'($urandom);
      vb_io_req_1_bits_vpu_vsew = 2'($urandom);
      vb_io_req_1_bits_vpu_vlmul = 3'($urandom);
      vb_io_req_1_bits_vpu_specVill = 1'($urandom);
      vb_io_req_1_bits_vpu_specVma = 1'($urandom);
      vb_io_req_1_bits_vpu_specVta = 1'($urandom);
      vb_io_req_1_bits_vpu_specVsew = 2'($urandom);
      vb_io_req_1_bits_vpu_specVlmul = 3'($urandom);
      vb_io_req_1_bits_isVset = 1'($urandom);
      vb_io_req_1_bits_lastUop = 1'($urandom);
      vb_io_req_2_valid = 1'($urandom);
      vb_io_req_2_bits_fuOpType = 9'($urandom);
      vb_io_req_2_bits_vpu_vill = 1'($urandom);
      vb_io_req_2_bits_vpu_vma = 1'($urandom);
      vb_io_req_2_bits_vpu_vta = 1'($urandom);
      vb_io_req_2_bits_vpu_vsew = 2'($urandom);
      vb_io_req_2_bits_vpu_vlmul = 3'($urandom);
      vb_io_req_2_bits_vpu_specVill = 1'($urandom);
      vb_io_req_2_bits_vpu_specVma = 1'($urandom);
      vb_io_req_2_bits_vpu_specVta = 1'($urandom);
      vb_io_req_2_bits_vpu_specVsew = 2'($urandom);
      vb_io_req_2_bits_vpu_specVlmul = 3'($urandom);
      vb_io_req_2_bits_isVset = 1'($urandom);
      vb_io_req_2_bits_lastUop = 1'($urandom);
      vb_io_req_3_valid = 1'($urandom);
      vb_io_req_3_bits_fuOpType = 9'($urandom);
      vb_io_req_3_bits_vpu_vill = 1'($urandom);
      vb_io_req_3_bits_vpu_vma = 1'($urandom);
      vb_io_req_3_bits_vpu_vta = 1'($urandom);
      vb_io_req_3_bits_vpu_vsew = 2'($urandom);
      vb_io_req_3_bits_vpu_vlmul = 3'($urandom);
      vb_io_req_3_bits_vpu_specVill = 1'($urandom);
      vb_io_req_3_bits_vpu_specVma = 1'($urandom);
      vb_io_req_3_bits_vpu_specVta = 1'($urandom);
      vb_io_req_3_bits_vpu_specVsew = 2'($urandom);
      vb_io_req_3_bits_vpu_specVlmul = 3'($urandom);
      vb_io_req_3_bits_isVset = 1'($urandom);
      vb_io_req_3_bits_lastUop = 1'($urandom);
      vb_io_req_4_valid = 1'($urandom);
      vb_io_req_4_bits_fuOpType = 9'($urandom);
      vb_io_req_4_bits_vpu_vill = 1'($urandom);
      vb_io_req_4_bits_vpu_vma = 1'($urandom);
      vb_io_req_4_bits_vpu_vta = 1'($urandom);
      vb_io_req_4_bits_vpu_vsew = 2'($urandom);
      vb_io_req_4_bits_vpu_vlmul = 3'($urandom);
      vb_io_req_4_bits_vpu_specVill = 1'($urandom);
      vb_io_req_4_bits_vpu_specVma = 1'($urandom);
      vb_io_req_4_bits_vpu_specVta = 1'($urandom);
      vb_io_req_4_bits_vpu_specVsew = 2'($urandom);
      vb_io_req_4_bits_vpu_specVlmul = 3'($urandom);
      vb_io_req_4_bits_isVset = 1'($urandom);
      vb_io_req_4_bits_lastUop = 1'($urandom);
      vb_io_req_5_valid = 1'($urandom);
      vb_io_req_5_bits_fuOpType = 9'($urandom);
      vb_io_req_5_bits_vpu_vill = 1'($urandom);
      vb_io_req_5_bits_vpu_vma = 1'($urandom);
      vb_io_req_5_bits_vpu_vta = 1'($urandom);
      vb_io_req_5_bits_vpu_vsew = 2'($urandom);
      vb_io_req_5_bits_vpu_vlmul = 3'($urandom);
      vb_io_req_5_bits_vpu_specVill = 1'($urandom);
      vb_io_req_5_bits_vpu_specVma = 1'($urandom);
      vb_io_req_5_bits_vpu_specVta = 1'($urandom);
      vb_io_req_5_bits_vpu_specVsew = 2'($urandom);
      vb_io_req_5_bits_vpu_specVlmul = 3'($urandom);
      vb_io_req_5_bits_isVset = 1'($urandom);
      vb_io_req_5_bits_lastUop = 1'($urandom);
      vb_io_fromRob_walkSize = 6'($urandom);
      vb_io_fromRob_walkEnd = 1'($urandom);
      vb_io_fromRob_commitSize = 6'($urandom);
      vb_io_snpt_snptEnq = 1'($urandom);
      vb_io_snpt_snptDeq = 1'($urandom);
      vb_io_snpt_useSnpt = 1'($urandom);
      vb_io_snpt_snptSelect = 2'($urandom);
      vb_io_snpt_flushVec_0 = 1'($urandom);
      vb_io_snpt_flushVec_1 = 1'($urandom);
      vb_io_snpt_flushVec_2 = 1'($urandom);
      vb_io_snpt_flushVec_3 = 1'($urandom);
      vb_reset = (cyc < RESET_CYC) || ($urandom_range(0, 59999) == 0);
      begin : stim_vb
        vb_io_redirect_valid = ($urandom_range(0, 47) == 0);
        vb_io_fromRob_walkEnd = ($urandom_range(0, 5) == 0);
        vb_io_fromRob_walkSize = ($urandom_range(0, 3) == 0) ? 6'($urandom) : 6'($urandom_range(0, 6));
        vb_io_snpt_snptEnq = ($urandom_range(0, 7) == 0);
        vb_io_snpt_snptDeq = ($urandom_range(0, 7) == 0);
        case (vb_mode % 4)
          0: begin  // FILL
            vb_io_fromRob_commitSize = 6'd0;
            vb_io_req_0_bits_isVset = 1'b1; vb_io_req_0_bits_lastUop = 1'b1;
            vb_io_req_3_bits_isVset = 1'b1; vb_io_req_3_bits_lastUop = 1'b1;
          end
          1: begin  // DRAIN
            vb_io_fromRob_commitSize = 6'($urandom_range(0, 8));
            {vb_io_req_5_valid, vb_io_req_4_valid, vb_io_req_3_valid, vb_io_req_2_valid, vb_io_req_1_valid, vb_io_req_0_valid} = 6'd0;
          end
          2: begin  // CHURN
            vb_io_fromRob_commitSize = 6'($urandom_range(0, 3));
          end
          default: ;
        endcase
      end
      #4;
      if (cyc >= RESET_CYC + 0 && (&vb_armed)) begin
        checks++;
        if (vb_g_io_canEnq !== vb_i_io_canEnq) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VTypeBuffer.io_canEnq g=%h i=%h", cyc, vb_g_io_canEnq, vb_i_io_canEnq);
        end
        vb_s1_io_canEnq |= vb_g_io_canEnq;
        vb_s0_io_canEnq |= ~vb_g_io_canEnq;
        checks++;
        if (vb_g_io_canEnqForDispatch !== vb_i_io_canEnqForDispatch) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VTypeBuffer.io_canEnqForDispatch g=%h i=%h", cyc, vb_g_io_canEnqForDispatch, vb_i_io_canEnqForDispatch);
        end
        vb_s1_io_canEnqForDispatch |= vb_g_io_canEnqForDispatch;
        vb_s0_io_canEnqForDispatch |= ~vb_g_io_canEnqForDispatch;
        checks++;
        if (vb_g_io_toDecode_isResumeVType !== vb_i_io_toDecode_isResumeVType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VTypeBuffer.io_toDecode_isResumeVType g=%h i=%h", cyc, vb_g_io_toDecode_isResumeVType, vb_i_io_toDecode_isResumeVType);
        end
        vb_s1_io_toDecode_isResumeVType |= vb_g_io_toDecode_isResumeVType;
        vb_s0_io_toDecode_isResumeVType |= ~vb_g_io_toDecode_isResumeVType;
        checks++;
        if (vb_g_io_toDecode_walkToArchVType !== vb_i_io_toDecode_walkToArchVType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VTypeBuffer.io_toDecode_walkToArchVType g=%h i=%h", cyc, vb_g_io_toDecode_walkToArchVType, vb_i_io_toDecode_walkToArchVType);
        end
        vb_s1_io_toDecode_walkToArchVType |= vb_g_io_toDecode_walkToArchVType;
        vb_s0_io_toDecode_walkToArchVType |= ~vb_g_io_toDecode_walkToArchVType;
        checks++;
        if (vb_g_io_toDecode_walkVType_valid !== vb_i_io_toDecode_walkVType_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VTypeBuffer.io_toDecode_walkVType_valid g=%h i=%h", cyc, vb_g_io_toDecode_walkVType_valid, vb_i_io_toDecode_walkVType_valid);
        end
        vb_s1_io_toDecode_walkVType_valid |= vb_g_io_toDecode_walkVType_valid;
        vb_s0_io_toDecode_walkVType_valid |= ~vb_g_io_toDecode_walkVType_valid;
        checks++;
        if (vb_g_io_toDecode_walkVType_bits_illegal !== vb_i_io_toDecode_walkVType_bits_illegal) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VTypeBuffer.io_toDecode_walkVType_bits_illegal g=%h i=%h", cyc, vb_g_io_toDecode_walkVType_bits_illegal, vb_i_io_toDecode_walkVType_bits_illegal);
        end
        vb_s1_io_toDecode_walkVType_bits_illegal |= vb_g_io_toDecode_walkVType_bits_illegal;
        vb_s0_io_toDecode_walkVType_bits_illegal |= ~vb_g_io_toDecode_walkVType_bits_illegal;
        checks++;
        if (vb_g_io_toDecode_walkVType_bits_vma !== vb_i_io_toDecode_walkVType_bits_vma) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VTypeBuffer.io_toDecode_walkVType_bits_vma g=%h i=%h", cyc, vb_g_io_toDecode_walkVType_bits_vma, vb_i_io_toDecode_walkVType_bits_vma);
        end
        vb_s1_io_toDecode_walkVType_bits_vma |= vb_g_io_toDecode_walkVType_bits_vma;
        vb_s0_io_toDecode_walkVType_bits_vma |= ~vb_g_io_toDecode_walkVType_bits_vma;
        checks++;
        if (vb_g_io_toDecode_walkVType_bits_vta !== vb_i_io_toDecode_walkVType_bits_vta) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VTypeBuffer.io_toDecode_walkVType_bits_vta g=%h i=%h", cyc, vb_g_io_toDecode_walkVType_bits_vta, vb_i_io_toDecode_walkVType_bits_vta);
        end
        vb_s1_io_toDecode_walkVType_bits_vta |= vb_g_io_toDecode_walkVType_bits_vta;
        vb_s0_io_toDecode_walkVType_bits_vta |= ~vb_g_io_toDecode_walkVType_bits_vta;
        checks++;
        if (vb_g_io_toDecode_walkVType_bits_vsew !== vb_i_io_toDecode_walkVType_bits_vsew) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VTypeBuffer.io_toDecode_walkVType_bits_vsew g=%h i=%h", cyc, vb_g_io_toDecode_walkVType_bits_vsew, vb_i_io_toDecode_walkVType_bits_vsew);
        end
        vb_s1_io_toDecode_walkVType_bits_vsew |= vb_g_io_toDecode_walkVType_bits_vsew;
        vb_s0_io_toDecode_walkVType_bits_vsew |= ~vb_g_io_toDecode_walkVType_bits_vsew;
        checks++;
        if (vb_g_io_toDecode_walkVType_bits_vlmul !== vb_i_io_toDecode_walkVType_bits_vlmul) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VTypeBuffer.io_toDecode_walkVType_bits_vlmul g=%h i=%h", cyc, vb_g_io_toDecode_walkVType_bits_vlmul, vb_i_io_toDecode_walkVType_bits_vlmul);
        end
        vb_s1_io_toDecode_walkVType_bits_vlmul |= vb_g_io_toDecode_walkVType_bits_vlmul;
        vb_s0_io_toDecode_walkVType_bits_vlmul |= ~vb_g_io_toDecode_walkVType_bits_vlmul;
        checks++;
        if (vb_g_io_toDecode_commitVType_vtype_valid !== vb_i_io_toDecode_commitVType_vtype_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VTypeBuffer.io_toDecode_commitVType_vtype_valid g=%h i=%h", cyc, vb_g_io_toDecode_commitVType_vtype_valid, vb_i_io_toDecode_commitVType_vtype_valid);
        end
        vb_s1_io_toDecode_commitVType_vtype_valid |= vb_g_io_toDecode_commitVType_vtype_valid;
        vb_s0_io_toDecode_commitVType_vtype_valid |= ~vb_g_io_toDecode_commitVType_vtype_valid;
        checks++;
        if (vb_g_io_toDecode_commitVType_vtype_bits_illegal !== vb_i_io_toDecode_commitVType_vtype_bits_illegal) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VTypeBuffer.io_toDecode_commitVType_vtype_bits_illegal g=%h i=%h", cyc, vb_g_io_toDecode_commitVType_vtype_bits_illegal, vb_i_io_toDecode_commitVType_vtype_bits_illegal);
        end
        vb_s1_io_toDecode_commitVType_vtype_bits_illegal |= vb_g_io_toDecode_commitVType_vtype_bits_illegal;
        vb_s0_io_toDecode_commitVType_vtype_bits_illegal |= ~vb_g_io_toDecode_commitVType_vtype_bits_illegal;
        checks++;
        if (vb_g_io_toDecode_commitVType_vtype_bits_vma !== vb_i_io_toDecode_commitVType_vtype_bits_vma) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VTypeBuffer.io_toDecode_commitVType_vtype_bits_vma g=%h i=%h", cyc, vb_g_io_toDecode_commitVType_vtype_bits_vma, vb_i_io_toDecode_commitVType_vtype_bits_vma);
        end
        vb_s1_io_toDecode_commitVType_vtype_bits_vma |= vb_g_io_toDecode_commitVType_vtype_bits_vma;
        vb_s0_io_toDecode_commitVType_vtype_bits_vma |= ~vb_g_io_toDecode_commitVType_vtype_bits_vma;
        checks++;
        if (vb_g_io_toDecode_commitVType_vtype_bits_vta !== vb_i_io_toDecode_commitVType_vtype_bits_vta) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VTypeBuffer.io_toDecode_commitVType_vtype_bits_vta g=%h i=%h", cyc, vb_g_io_toDecode_commitVType_vtype_bits_vta, vb_i_io_toDecode_commitVType_vtype_bits_vta);
        end
        vb_s1_io_toDecode_commitVType_vtype_bits_vta |= vb_g_io_toDecode_commitVType_vtype_bits_vta;
        vb_s0_io_toDecode_commitVType_vtype_bits_vta |= ~vb_g_io_toDecode_commitVType_vtype_bits_vta;
        checks++;
        if (vb_g_io_toDecode_commitVType_vtype_bits_vsew !== vb_i_io_toDecode_commitVType_vtype_bits_vsew) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VTypeBuffer.io_toDecode_commitVType_vtype_bits_vsew g=%h i=%h", cyc, vb_g_io_toDecode_commitVType_vtype_bits_vsew, vb_i_io_toDecode_commitVType_vtype_bits_vsew);
        end
        vb_s1_io_toDecode_commitVType_vtype_bits_vsew |= vb_g_io_toDecode_commitVType_vtype_bits_vsew;
        vb_s0_io_toDecode_commitVType_vtype_bits_vsew |= ~vb_g_io_toDecode_commitVType_vtype_bits_vsew;
        checks++;
        if (vb_g_io_toDecode_commitVType_vtype_bits_vlmul !== vb_i_io_toDecode_commitVType_vtype_bits_vlmul) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VTypeBuffer.io_toDecode_commitVType_vtype_bits_vlmul g=%h i=%h", cyc, vb_g_io_toDecode_commitVType_vtype_bits_vlmul, vb_i_io_toDecode_commitVType_vtype_bits_vlmul);
        end
        vb_s1_io_toDecode_commitVType_vtype_bits_vlmul |= vb_g_io_toDecode_commitVType_vtype_bits_vlmul;
        vb_s0_io_toDecode_commitVType_vtype_bits_vlmul |= ~vb_g_io_toDecode_commitVType_vtype_bits_vlmul;
        checks++;
        if (vb_g_io_toDecode_commitVType_hasVsetvl !== vb_i_io_toDecode_commitVType_hasVsetvl) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VTypeBuffer.io_toDecode_commitVType_hasVsetvl g=%h i=%h", cyc, vb_g_io_toDecode_commitVType_hasVsetvl, vb_i_io_toDecode_commitVType_hasVsetvl);
        end
        vb_s1_io_toDecode_commitVType_hasVsetvl |= vb_g_io_toDecode_commitVType_hasVsetvl;
        vb_s0_io_toDecode_commitVType_hasVsetvl |= ~vb_g_io_toDecode_commitVType_hasVsetvl;
        checks++;
        if (vb_g_io_status_walkEnd !== vb_i_io_status_walkEnd) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d VTypeBuffer.io_status_walkEnd g=%h i=%h", cyc, vb_g_io_status_walkEnd, vb_i_io_status_walkEnd);
        end
        vb_s1_io_status_walkEnd |= vb_g_io_status_walkEnd;
        vb_s0_io_status_walkEnd |= ~vb_g_io_status_walkEnd;
        if (vb_u_gold.state == 2'd1) vb_cov_st_spcl++;
        if (vb_u_gold.state == 2'd2) vb_cov_st_walk++;
        if (vb_u_gold.state == 2'd1 && vb_u_gold.stateNext == 2'd2) vb_cov_spcl_to_walk++;
        if (vb_u_gold.state == 2'd2 && vb_u_gold.stateNext == 2'd0) vb_cov_walk_to_idle++;
        if (vb_u_gold.useSnapshot) vb_cov_use_snapshot++;
        if (vb_g_io_toDecode_walkToArchVType) vb_cov_walk_to_arch++;
        if (vb_g_io_toDecode_walkVType_valid) vb_cov_walk_vtype++;
        if (vb_g_io_toDecode_commitVType_vtype_valid) vb_cov_commit_vtype++;
        if (vb_g_io_toDecode_commitVType_hasVsetvl) vb_cov_has_vsetvl++;
        if (!vb_g_io_canEnq && vb_u_gold.state == 2'd0) vb_cov_full_canenq++;
        if (!vb_g_io_canEnqForDispatch && vb_g_io_canEnq) vb_cov_full_dispatch++;
        if (vb_u_gold.enqPtrVec_0_flag) vb_cov_enq_wrap++;
      end
      if (&vb_wmask) vb_armed[0] = 1'b1;
      if (vb_u_gold.walkPtrSnapshots_snapshotGen._GEN_0) vb_armed[1] = 1'b1;
      if (vb_u_gold.walkPtrSnapshots_snapshotGen._GEN_1) vb_armed[2] = 1'b1;
      if (vb_u_gold.walkPtrSnapshots_snapshotGen._GEN_2) vb_armed[3] = 1'b1;
      if (vb_u_gold.walkPtrSnapshots_snapshotGen._GEN_3) vb_armed[4] = 1'b1;
      if (vb_armed_at < 0 && (&vb_armed)) vb_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(vb_s0_io_canEnq && vb_s1_io_canEnq)) begin cov_fail++; $display("[COV] VTypeBuffer.io_canEnq 未见过 0 和 1"); end
    if (!(vb_s0_io_canEnqForDispatch && vb_s1_io_canEnqForDispatch)) begin cov_fail++; $display("[COV] VTypeBuffer.io_canEnqForDispatch 未见过 0 和 1"); end
    if (!(vb_s0_io_toDecode_isResumeVType && vb_s1_io_toDecode_isResumeVType)) begin cov_fail++; $display("[COV] VTypeBuffer.io_toDecode_isResumeVType 未见过 0 和 1"); end
    if (!(vb_s0_io_toDecode_walkToArchVType && vb_s1_io_toDecode_walkToArchVType)) begin cov_fail++; $display("[COV] VTypeBuffer.io_toDecode_walkToArchVType 未见过 0 和 1"); end
    if (!(vb_s0_io_toDecode_walkVType_valid && vb_s1_io_toDecode_walkVType_valid)) begin cov_fail++; $display("[COV] VTypeBuffer.io_toDecode_walkVType_valid 未见过 0 和 1"); end
    if (!(vb_s0_io_toDecode_walkVType_bits_illegal && vb_s1_io_toDecode_walkVType_bits_illegal)) begin cov_fail++; $display("[COV] VTypeBuffer.io_toDecode_walkVType_bits_illegal 未见过 0 和 1"); end
    if (!(vb_s0_io_toDecode_walkVType_bits_vma && vb_s1_io_toDecode_walkVType_bits_vma)) begin cov_fail++; $display("[COV] VTypeBuffer.io_toDecode_walkVType_bits_vma 未见过 0 和 1"); end
    if (!(vb_s0_io_toDecode_walkVType_bits_vta && vb_s1_io_toDecode_walkVType_bits_vta)) begin cov_fail++; $display("[COV] VTypeBuffer.io_toDecode_walkVType_bits_vta 未见过 0 和 1"); end
    if (!(vb_s0_io_toDecode_walkVType_bits_vsew[0] && vb_s1_io_toDecode_walkVType_bits_vsew[0])) begin cov_fail++; $display("[COV] VTypeBuffer.io_toDecode_walkVType_bits_vsew[0] 未见过 0 和 1"); end
    if (!(vb_s0_io_toDecode_walkVType_bits_vsew[1] && vb_s1_io_toDecode_walkVType_bits_vsew[1])) begin cov_fail++; $display("[COV] VTypeBuffer.io_toDecode_walkVType_bits_vsew[1] 未见过 0 和 1"); end
    if (!(vb_s0_io_toDecode_walkVType_bits_vlmul[0] && vb_s1_io_toDecode_walkVType_bits_vlmul[0])) begin cov_fail++; $display("[COV] VTypeBuffer.io_toDecode_walkVType_bits_vlmul[0] 未见过 0 和 1"); end
    if (!(vb_s0_io_toDecode_walkVType_bits_vlmul[1] && vb_s1_io_toDecode_walkVType_bits_vlmul[1])) begin cov_fail++; $display("[COV] VTypeBuffer.io_toDecode_walkVType_bits_vlmul[1] 未见过 0 和 1"); end
    if (!(vb_s0_io_toDecode_walkVType_bits_vlmul[2] && vb_s1_io_toDecode_walkVType_bits_vlmul[2])) begin cov_fail++; $display("[COV] VTypeBuffer.io_toDecode_walkVType_bits_vlmul[2] 未见过 0 和 1"); end
    if (!(vb_s0_io_toDecode_commitVType_vtype_valid && vb_s1_io_toDecode_commitVType_vtype_valid)) begin cov_fail++; $display("[COV] VTypeBuffer.io_toDecode_commitVType_vtype_valid 未见过 0 和 1"); end
    if (!(vb_s0_io_toDecode_commitVType_vtype_bits_illegal && vb_s1_io_toDecode_commitVType_vtype_bits_illegal)) begin cov_fail++; $display("[COV] VTypeBuffer.io_toDecode_commitVType_vtype_bits_illegal 未见过 0 和 1"); end
    if (!(vb_s0_io_toDecode_commitVType_vtype_bits_vma && vb_s1_io_toDecode_commitVType_vtype_bits_vma)) begin cov_fail++; $display("[COV] VTypeBuffer.io_toDecode_commitVType_vtype_bits_vma 未见过 0 和 1"); end
    if (!(vb_s0_io_toDecode_commitVType_vtype_bits_vta && vb_s1_io_toDecode_commitVType_vtype_bits_vta)) begin cov_fail++; $display("[COV] VTypeBuffer.io_toDecode_commitVType_vtype_bits_vta 未见过 0 和 1"); end
    if (!(vb_s0_io_toDecode_commitVType_vtype_bits_vsew[0] && vb_s1_io_toDecode_commitVType_vtype_bits_vsew[0])) begin cov_fail++; $display("[COV] VTypeBuffer.io_toDecode_commitVType_vtype_bits_vsew[0] 未见过 0 和 1"); end
    if (!(vb_s0_io_toDecode_commitVType_vtype_bits_vsew[1] && vb_s1_io_toDecode_commitVType_vtype_bits_vsew[1])) begin cov_fail++; $display("[COV] VTypeBuffer.io_toDecode_commitVType_vtype_bits_vsew[1] 未见过 0 和 1"); end
    if (!(vb_s0_io_toDecode_commitVType_vtype_bits_vlmul[0] && vb_s1_io_toDecode_commitVType_vtype_bits_vlmul[0])) begin cov_fail++; $display("[COV] VTypeBuffer.io_toDecode_commitVType_vtype_bits_vlmul[0] 未见过 0 和 1"); end
    if (!(vb_s0_io_toDecode_commitVType_vtype_bits_vlmul[1] && vb_s1_io_toDecode_commitVType_vtype_bits_vlmul[1])) begin cov_fail++; $display("[COV] VTypeBuffer.io_toDecode_commitVType_vtype_bits_vlmul[1] 未见过 0 和 1"); end
    if (!(vb_s0_io_toDecode_commitVType_vtype_bits_vlmul[2] && vb_s1_io_toDecode_commitVType_vtype_bits_vlmul[2])) begin cov_fail++; $display("[COV] VTypeBuffer.io_toDecode_commitVType_vtype_bits_vlmul[2] 未见过 0 和 1"); end
    if (!(vb_s0_io_toDecode_commitVType_hasVsetvl && vb_s1_io_toDecode_commitVType_hasVsetvl)) begin cov_fail++; $display("[COV] VTypeBuffer.io_toDecode_commitVType_hasVsetvl 未见过 0 和 1"); end
    if (!(vb_s0_io_status_walkEnd && vb_s1_io_status_walkEnd)) begin cov_fail++; $display("[COV] VTypeBuffer.io_status_walkEnd 未见过 0 和 1"); end
    $display("[ARM] VTypeBuffer armed_at=%0d", vb_armed_at);
    if (vb_armed_at < 0) begin cov_fail++; $display("[ARM] VTypeBuffer 从未 arm"); end
    $display("[COV] VTypeBuffer.st_spcl = %0d", vb_cov_st_spcl);
    if (vb_cov_st_spcl < 100) begin cov_fail++; $display("[COV] VTypeBuffer.st_spcl < 100"); end
    $display("[COV] VTypeBuffer.st_walk = %0d", vb_cov_st_walk);
    if (vb_cov_st_walk < 100) begin cov_fail++; $display("[COV] VTypeBuffer.st_walk < 100"); end
    $display("[COV] VTypeBuffer.spcl_to_walk = %0d", vb_cov_spcl_to_walk);
    if (vb_cov_spcl_to_walk < 100) begin cov_fail++; $display("[COV] VTypeBuffer.spcl_to_walk < 100"); end
    $display("[COV] VTypeBuffer.walk_to_idle = %0d", vb_cov_walk_to_idle);
    if (vb_cov_walk_to_idle < 100) begin cov_fail++; $display("[COV] VTypeBuffer.walk_to_idle < 100"); end
    $display("[COV] VTypeBuffer.use_snapshot = %0d", vb_cov_use_snapshot);
    if (vb_cov_use_snapshot < 100) begin cov_fail++; $display("[COV] VTypeBuffer.use_snapshot < 100"); end
    $display("[COV] VTypeBuffer.walk_to_arch = %0d", vb_cov_walk_to_arch);
    if (vb_cov_walk_to_arch < 100) begin cov_fail++; $display("[COV] VTypeBuffer.walk_to_arch < 100"); end
    $display("[COV] VTypeBuffer.walk_vtype = %0d", vb_cov_walk_vtype);
    if (vb_cov_walk_vtype < 100) begin cov_fail++; $display("[COV] VTypeBuffer.walk_vtype < 100"); end
    $display("[COV] VTypeBuffer.commit_vtype = %0d", vb_cov_commit_vtype);
    if (vb_cov_commit_vtype < 100) begin cov_fail++; $display("[COV] VTypeBuffer.commit_vtype < 100"); end
    $display("[COV] VTypeBuffer.has_vsetvl = %0d", vb_cov_has_vsetvl);
    if (vb_cov_has_vsetvl < 100) begin cov_fail++; $display("[COV] VTypeBuffer.has_vsetvl < 100"); end
    $display("[COV] VTypeBuffer.full_canenq = %0d", vb_cov_full_canenq);
    if (vb_cov_full_canenq < 100) begin cov_fail++; $display("[COV] VTypeBuffer.full_canenq < 100"); end
    $display("[COV] VTypeBuffer.full_dispatch = %0d", vb_cov_full_dispatch);
    if (vb_cov_full_dispatch < 100) begin cov_fail++; $display("[COV] VTypeBuffer.full_dispatch < 100"); end
    $display("[COV] VTypeBuffer.enq_wrap = %0d", vb_cov_enq_wrap);
    if (vb_cov_enq_wrap < 100) begin cov_fail++; $display("[COV] VTypeBuffer.enq_wrap < 100"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
