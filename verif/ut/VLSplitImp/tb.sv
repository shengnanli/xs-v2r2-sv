// 自动生成 gen_vsplit.py —— 勿手改。双例化 golden VLSplitImp vs VLSplitImp_xs 逐拍比对。
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
  logic io_in_valid;
  logic io_in_bits_uop_ftqPtr_flag;
  logic [5:0] io_in_bits_uop_ftqPtr_value;
  logic [3:0] io_in_bits_uop_ftqOffset;
  logic [8:0] io_in_bits_uop_fuOpType;
  logic io_in_bits_uop_vecWen;
  logic io_in_bits_uop_v0Wen;
  logic io_in_bits_uop_vlWen;
  logic io_in_bits_uop_vpu_vma;
  logic io_in_bits_uop_vpu_vta;
  logic [1:0] io_in_bits_uop_vpu_vsew;
  logic [2:0] io_in_bits_uop_vpu_vlmul;
  logic io_in_bits_uop_vpu_vm;
  logic [7:0] io_in_bits_uop_vpu_vstart;
  logic [6:0] io_in_bits_uop_vpu_vuopIdx;
  logic [2:0] io_in_bits_uop_vpu_nf;
  logic [1:0] io_in_bits_uop_vpu_veew;
  logic [7:0] io_in_bits_uop_pdest;
  logic io_in_bits_uop_robIdx_flag;
  logic [7:0] io_in_bits_uop_robIdx_value;
  logic [63:0] io_in_bits_uop_debugInfo_enqRsTime;
  logic [63:0] io_in_bits_uop_debugInfo_selectTime;
  logic [63:0] io_in_bits_uop_debugInfo_issueTime;
  logic io_in_bits_uop_lqIdx_flag;
  logic [6:0] io_in_bits_uop_lqIdx_value;
  logic io_in_bits_uop_sqIdx_flag;
  logic [5:0] io_in_bits_uop_sqIdx_value;
  logic [127:0] io_in_bits_src_0;
  logic [127:0] io_in_bits_src_1;
  logic [127:0] io_in_bits_src_2;
  logic [127:0] io_in_bits_src_3;
  logic [127:0] io_in_bits_src_4;
  logic [4:0] io_in_bits_flowNum;
  logic io_toMergeBuffer_req_ready;
  logic io_toMergeBuffer_resp_valid;
  logic [3:0] io_toMergeBuffer_resp_bits_mBIndex;
  logic io_out_ready;
  logic io_threshold_valid;
  logic io_threshold_bits_flag;
  logic [6:0] io_threshold_bits_value;
  logic g_io_in_ready;
  logic i_io_in_ready;
  logic g_io_toMergeBuffer_req_valid;
  logic i_io_toMergeBuffer_req_valid;
  logic [15:0] g_io_toMergeBuffer_req_bits_mask;
  logic [15:0] i_io_toMergeBuffer_req_bits_mask;
  logic [49:0] g_io_toMergeBuffer_req_bits_vaddr;
  logic [49:0] i_io_toMergeBuffer_req_bits_vaddr;
  logic [4:0] g_io_toMergeBuffer_req_bits_flowNum;
  logic [4:0] i_io_toMergeBuffer_req_bits_flowNum;
  logic [8:0] g_io_toMergeBuffer_req_bits_uop_fuOpType;
  logic [8:0] i_io_toMergeBuffer_req_bits_uop_fuOpType;
  logic g_io_toMergeBuffer_req_bits_uop_vecWen;
  logic i_io_toMergeBuffer_req_bits_uop_vecWen;
  logic g_io_toMergeBuffer_req_bits_uop_v0Wen;
  logic i_io_toMergeBuffer_req_bits_uop_v0Wen;
  logic g_io_toMergeBuffer_req_bits_uop_vlWen;
  logic i_io_toMergeBuffer_req_bits_uop_vlWen;
  logic g_io_toMergeBuffer_req_bits_uop_vpu_vma;
  logic i_io_toMergeBuffer_req_bits_uop_vpu_vma;
  logic g_io_toMergeBuffer_req_bits_uop_vpu_vta;
  logic i_io_toMergeBuffer_req_bits_uop_vpu_vta;
  logic [1:0] g_io_toMergeBuffer_req_bits_uop_vpu_vsew;
  logic [1:0] i_io_toMergeBuffer_req_bits_uop_vpu_vsew;
  logic [2:0] g_io_toMergeBuffer_req_bits_uop_vpu_vlmul;
  logic [2:0] i_io_toMergeBuffer_req_bits_uop_vpu_vlmul;
  logic g_io_toMergeBuffer_req_bits_uop_vpu_vm;
  logic i_io_toMergeBuffer_req_bits_uop_vpu_vm;
  logic [6:0] g_io_toMergeBuffer_req_bits_uop_vpu_vuopIdx;
  logic [6:0] i_io_toMergeBuffer_req_bits_uop_vpu_vuopIdx;
  logic [7:0] g_io_toMergeBuffer_req_bits_uop_vpu_vl;
  logic [7:0] i_io_toMergeBuffer_req_bits_uop_vpu_vl;
  logic [2:0] g_io_toMergeBuffer_req_bits_uop_vpu_nf;
  logic [2:0] i_io_toMergeBuffer_req_bits_uop_vpu_nf;
  logic [1:0] g_io_toMergeBuffer_req_bits_uop_vpu_veew;
  logic [1:0] i_io_toMergeBuffer_req_bits_uop_vpu_veew;
  logic [6:0] g_io_toMergeBuffer_req_bits_uop_uopIdx;
  logic [6:0] i_io_toMergeBuffer_req_bits_uop_uopIdx;
  logic [7:0] g_io_toMergeBuffer_req_bits_uop_pdest;
  logic [7:0] i_io_toMergeBuffer_req_bits_uop_pdest;
  logic g_io_toMergeBuffer_req_bits_uop_robIdx_flag;
  logic i_io_toMergeBuffer_req_bits_uop_robIdx_flag;
  logic [7:0] g_io_toMergeBuffer_req_bits_uop_robIdx_value;
  logic [7:0] i_io_toMergeBuffer_req_bits_uop_robIdx_value;
  logic [63:0] g_io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime;
  logic [63:0] i_io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime;
  logic [63:0] g_io_toMergeBuffer_req_bits_uop_debugInfo_selectTime;
  logic [63:0] i_io_toMergeBuffer_req_bits_uop_debugInfo_selectTime;
  logic [63:0] g_io_toMergeBuffer_req_bits_uop_debugInfo_issueTime;
  logic [63:0] i_io_toMergeBuffer_req_bits_uop_debugInfo_issueTime;
  logic [127:0] g_io_toMergeBuffer_req_bits_data;
  logic [127:0] i_io_toMergeBuffer_req_bits_data;
  logic [2:0] g_io_toMergeBuffer_req_bits_vdIdx;
  logic [2:0] i_io_toMergeBuffer_req_bits_vdIdx;
  logic g_io_toMergeBuffer_req_bits_fof;
  logic i_io_toMergeBuffer_req_bits_fof;
  logic [7:0] g_io_toMergeBuffer_req_bits_vlmax;
  logic [7:0] i_io_toMergeBuffer_req_bits_vlmax;
  logic g_io_out_valid;
  logic i_io_out_valid;
  logic [63:0] g_io_out_bits_vaddr;
  logic [63:0] i_io_out_bits_vaddr;
  logic [49:0] g_io_out_bits_basevaddr;
  logic [49:0] i_io_out_bits_basevaddr;
  logic [15:0] g_io_out_bits_mask;
  logic [15:0] i_io_out_bits_mask;
  logic [3:0] g_io_out_bits_reg_offset;
  logic [3:0] i_io_out_bits_reg_offset;
  logic [2:0] g_io_out_bits_alignedType;
  logic [2:0] i_io_out_bits_alignedType;
  logic g_io_out_bits_vecActive;
  logic i_io_out_bits_vecActive;
  logic g_io_out_bits_uop_exceptionVec_4;
  logic i_io_out_bits_uop_exceptionVec_4;
  logic g_io_out_bits_uop_exceptionVec_5;
  logic i_io_out_bits_uop_exceptionVec_5;
  logic g_io_out_bits_uop_exceptionVec_13;
  logic i_io_out_bits_uop_exceptionVec_13;
  logic g_io_out_bits_uop_exceptionVec_19;
  logic i_io_out_bits_uop_exceptionVec_19;
  logic g_io_out_bits_uop_exceptionVec_21;
  logic i_io_out_bits_uop_exceptionVec_21;
  logic [3:0] g_io_out_bits_uop_trigger;
  logic [3:0] i_io_out_bits_uop_trigger;
  logic g_io_out_bits_uop_preDecodeInfo_isRVC;
  logic i_io_out_bits_uop_preDecodeInfo_isRVC;
  logic g_io_out_bits_uop_ftqPtr_flag;
  logic i_io_out_bits_uop_ftqPtr_flag;
  logic [5:0] g_io_out_bits_uop_ftqPtr_value;
  logic [5:0] i_io_out_bits_uop_ftqPtr_value;
  logic [3:0] g_io_out_bits_uop_ftqOffset;
  logic [3:0] i_io_out_bits_uop_ftqOffset;
  logic [8:0] g_io_out_bits_uop_fuOpType;
  logic [8:0] i_io_out_bits_uop_fuOpType;
  logic g_io_out_bits_uop_rfWen;
  logic i_io_out_bits_uop_rfWen;
  logic g_io_out_bits_uop_fpWen;
  logic i_io_out_bits_uop_fpWen;
  logic [7:0] g_io_out_bits_uop_vpu_vstart;
  logic [7:0] i_io_out_bits_uop_vpu_vstart;
  logic [1:0] g_io_out_bits_uop_vpu_veew;
  logic [1:0] i_io_out_bits_uop_vpu_veew;
  logic [6:0] g_io_out_bits_uop_uopIdx;
  logic [6:0] i_io_out_bits_uop_uopIdx;
  logic [7:0] g_io_out_bits_uop_pdest;
  logic [7:0] i_io_out_bits_uop_pdest;
  logic g_io_out_bits_uop_robIdx_flag;
  logic i_io_out_bits_uop_robIdx_flag;
  logic [7:0] g_io_out_bits_uop_robIdx_value;
  logic [7:0] i_io_out_bits_uop_robIdx_value;
  logic [63:0] g_io_out_bits_uop_debugInfo_enqRsTime;
  logic [63:0] i_io_out_bits_uop_debugInfo_enqRsTime;
  logic [63:0] g_io_out_bits_uop_debugInfo_selectTime;
  logic [63:0] i_io_out_bits_uop_debugInfo_selectTime;
  logic [63:0] g_io_out_bits_uop_debugInfo_issueTime;
  logic [63:0] i_io_out_bits_uop_debugInfo_issueTime;
  logic g_io_out_bits_uop_storeSetHit;
  logic i_io_out_bits_uop_storeSetHit;
  logic g_io_out_bits_uop_waitForRobIdx_flag;
  logic i_io_out_bits_uop_waitForRobIdx_flag;
  logic [7:0] g_io_out_bits_uop_waitForRobIdx_value;
  logic [7:0] i_io_out_bits_uop_waitForRobIdx_value;
  logic g_io_out_bits_uop_loadWaitBit;
  logic i_io_out_bits_uop_loadWaitBit;
  logic g_io_out_bits_uop_loadWaitStrict;
  logic i_io_out_bits_uop_loadWaitStrict;
  logic g_io_out_bits_uop_lqIdx_flag;
  logic i_io_out_bits_uop_lqIdx_flag;
  logic [6:0] g_io_out_bits_uop_lqIdx_value;
  logic [6:0] i_io_out_bits_uop_lqIdx_value;
  logic g_io_out_bits_uop_sqIdx_flag;
  logic i_io_out_bits_uop_sqIdx_flag;
  logic [5:0] g_io_out_bits_uop_sqIdx_value;
  logic [5:0] i_io_out_bits_uop_sqIdx_value;
  logic [3:0] g_io_out_bits_mBIndex;
  logic [3:0] i_io_out_bits_mBIndex;
  logic [7:0] g_io_out_bits_elemIdx;
  logic [7:0] i_io_out_bits_elemIdx;
  logic [7:0] g_io_out_bits_elemIdxInsideVd;
  logic [7:0] i_io_out_bits_elemIdxInsideVd;

  VLSplitImp u_g (
    .clock(clk), .reset(rst),
    .io_redirect_valid(io_redirect_valid),
    .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value),
    .io_redirect_bits_level(io_redirect_bits_level),
    .io_in_valid(io_in_valid),
    .io_in_bits_uop_ftqPtr_flag(io_in_bits_uop_ftqPtr_flag),
    .io_in_bits_uop_ftqPtr_value(io_in_bits_uop_ftqPtr_value),
    .io_in_bits_uop_ftqOffset(io_in_bits_uop_ftqOffset),
    .io_in_bits_uop_fuOpType(io_in_bits_uop_fuOpType),
    .io_in_bits_uop_vecWen(io_in_bits_uop_vecWen),
    .io_in_bits_uop_v0Wen(io_in_bits_uop_v0Wen),
    .io_in_bits_uop_vlWen(io_in_bits_uop_vlWen),
    .io_in_bits_uop_vpu_vma(io_in_bits_uop_vpu_vma),
    .io_in_bits_uop_vpu_vta(io_in_bits_uop_vpu_vta),
    .io_in_bits_uop_vpu_vsew(io_in_bits_uop_vpu_vsew),
    .io_in_bits_uop_vpu_vlmul(io_in_bits_uop_vpu_vlmul),
    .io_in_bits_uop_vpu_vm(io_in_bits_uop_vpu_vm),
    .io_in_bits_uop_vpu_vstart(io_in_bits_uop_vpu_vstart),
    .io_in_bits_uop_vpu_vuopIdx(io_in_bits_uop_vpu_vuopIdx),
    .io_in_bits_uop_vpu_nf(io_in_bits_uop_vpu_nf),
    .io_in_bits_uop_vpu_veew(io_in_bits_uop_vpu_veew),
    .io_in_bits_uop_pdest(io_in_bits_uop_pdest),
    .io_in_bits_uop_robIdx_flag(io_in_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value(io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_debugInfo_enqRsTime(io_in_bits_uop_debugInfo_enqRsTime),
    .io_in_bits_uop_debugInfo_selectTime(io_in_bits_uop_debugInfo_selectTime),
    .io_in_bits_uop_debugInfo_issueTime(io_in_bits_uop_debugInfo_issueTime),
    .io_in_bits_uop_lqIdx_flag(io_in_bits_uop_lqIdx_flag),
    .io_in_bits_uop_lqIdx_value(io_in_bits_uop_lqIdx_value),
    .io_in_bits_uop_sqIdx_flag(io_in_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value(io_in_bits_uop_sqIdx_value),
    .io_in_bits_src_0(io_in_bits_src_0),
    .io_in_bits_src_1(io_in_bits_src_1),
    .io_in_bits_src_2(io_in_bits_src_2),
    .io_in_bits_src_3(io_in_bits_src_3),
    .io_in_bits_src_4(io_in_bits_src_4),
    .io_in_bits_flowNum(io_in_bits_flowNum),
    .io_toMergeBuffer_req_ready(io_toMergeBuffer_req_ready),
    .io_toMergeBuffer_resp_valid(io_toMergeBuffer_resp_valid),
    .io_toMergeBuffer_resp_bits_mBIndex(io_toMergeBuffer_resp_bits_mBIndex),
    .io_out_ready(io_out_ready),
    .io_threshold_valid(io_threshold_valid),
    .io_threshold_bits_flag(io_threshold_bits_flag),
    .io_threshold_bits_value(io_threshold_bits_value),
    .io_in_ready(g_io_in_ready),
    .io_toMergeBuffer_req_valid(g_io_toMergeBuffer_req_valid),
    .io_toMergeBuffer_req_bits_mask(g_io_toMergeBuffer_req_bits_mask),
    .io_toMergeBuffer_req_bits_vaddr(g_io_toMergeBuffer_req_bits_vaddr),
    .io_toMergeBuffer_req_bits_flowNum(g_io_toMergeBuffer_req_bits_flowNum),
    .io_toMergeBuffer_req_bits_uop_fuOpType(g_io_toMergeBuffer_req_bits_uop_fuOpType),
    .io_toMergeBuffer_req_bits_uop_vecWen(g_io_toMergeBuffer_req_bits_uop_vecWen),
    .io_toMergeBuffer_req_bits_uop_v0Wen(g_io_toMergeBuffer_req_bits_uop_v0Wen),
    .io_toMergeBuffer_req_bits_uop_vlWen(g_io_toMergeBuffer_req_bits_uop_vlWen),
    .io_toMergeBuffer_req_bits_uop_vpu_vma(g_io_toMergeBuffer_req_bits_uop_vpu_vma),
    .io_toMergeBuffer_req_bits_uop_vpu_vta(g_io_toMergeBuffer_req_bits_uop_vpu_vta),
    .io_toMergeBuffer_req_bits_uop_vpu_vsew(g_io_toMergeBuffer_req_bits_uop_vpu_vsew),
    .io_toMergeBuffer_req_bits_uop_vpu_vlmul(g_io_toMergeBuffer_req_bits_uop_vpu_vlmul),
    .io_toMergeBuffer_req_bits_uop_vpu_vm(g_io_toMergeBuffer_req_bits_uop_vpu_vm),
    .io_toMergeBuffer_req_bits_uop_vpu_vuopIdx(g_io_toMergeBuffer_req_bits_uop_vpu_vuopIdx),
    .io_toMergeBuffer_req_bits_uop_vpu_vl(g_io_toMergeBuffer_req_bits_uop_vpu_vl),
    .io_toMergeBuffer_req_bits_uop_vpu_nf(g_io_toMergeBuffer_req_bits_uop_vpu_nf),
    .io_toMergeBuffer_req_bits_uop_vpu_veew(g_io_toMergeBuffer_req_bits_uop_vpu_veew),
    .io_toMergeBuffer_req_bits_uop_uopIdx(g_io_toMergeBuffer_req_bits_uop_uopIdx),
    .io_toMergeBuffer_req_bits_uop_pdest(g_io_toMergeBuffer_req_bits_uop_pdest),
    .io_toMergeBuffer_req_bits_uop_robIdx_flag(g_io_toMergeBuffer_req_bits_uop_robIdx_flag),
    .io_toMergeBuffer_req_bits_uop_robIdx_value(g_io_toMergeBuffer_req_bits_uop_robIdx_value),
    .io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime(g_io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_selectTime(g_io_toMergeBuffer_req_bits_uop_debugInfo_selectTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_issueTime(g_io_toMergeBuffer_req_bits_uop_debugInfo_issueTime),
    .io_toMergeBuffer_req_bits_data(g_io_toMergeBuffer_req_bits_data),
    .io_toMergeBuffer_req_bits_vdIdx(g_io_toMergeBuffer_req_bits_vdIdx),
    .io_toMergeBuffer_req_bits_fof(g_io_toMergeBuffer_req_bits_fof),
    .io_toMergeBuffer_req_bits_vlmax(g_io_toMergeBuffer_req_bits_vlmax),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_vaddr(g_io_out_bits_vaddr),
    .io_out_bits_basevaddr(g_io_out_bits_basevaddr),
    .io_out_bits_mask(g_io_out_bits_mask),
    .io_out_bits_reg_offset(g_io_out_bits_reg_offset),
    .io_out_bits_alignedType(g_io_out_bits_alignedType),
    .io_out_bits_vecActive(g_io_out_bits_vecActive),
    .io_out_bits_uop_exceptionVec_4(g_io_out_bits_uop_exceptionVec_4),
    .io_out_bits_uop_exceptionVec_5(g_io_out_bits_uop_exceptionVec_5),
    .io_out_bits_uop_exceptionVec_13(g_io_out_bits_uop_exceptionVec_13),
    .io_out_bits_uop_exceptionVec_19(g_io_out_bits_uop_exceptionVec_19),
    .io_out_bits_uop_exceptionVec_21(g_io_out_bits_uop_exceptionVec_21),
    .io_out_bits_uop_trigger(g_io_out_bits_uop_trigger),
    .io_out_bits_uop_preDecodeInfo_isRVC(g_io_out_bits_uop_preDecodeInfo_isRVC),
    .io_out_bits_uop_ftqPtr_flag(g_io_out_bits_uop_ftqPtr_flag),
    .io_out_bits_uop_ftqPtr_value(g_io_out_bits_uop_ftqPtr_value),
    .io_out_bits_uop_ftqOffset(g_io_out_bits_uop_ftqOffset),
    .io_out_bits_uop_fuOpType(g_io_out_bits_uop_fuOpType),
    .io_out_bits_uop_rfWen(g_io_out_bits_uop_rfWen),
    .io_out_bits_uop_fpWen(g_io_out_bits_uop_fpWen),
    .io_out_bits_uop_vpu_vstart(g_io_out_bits_uop_vpu_vstart),
    .io_out_bits_uop_vpu_veew(g_io_out_bits_uop_vpu_veew),
    .io_out_bits_uop_uopIdx(g_io_out_bits_uop_uopIdx),
    .io_out_bits_uop_pdest(g_io_out_bits_uop_pdest),
    .io_out_bits_uop_robIdx_flag(g_io_out_bits_uop_robIdx_flag),
    .io_out_bits_uop_robIdx_value(g_io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_debugInfo_enqRsTime(g_io_out_bits_uop_debugInfo_enqRsTime),
    .io_out_bits_uop_debugInfo_selectTime(g_io_out_bits_uop_debugInfo_selectTime),
    .io_out_bits_uop_debugInfo_issueTime(g_io_out_bits_uop_debugInfo_issueTime),
    .io_out_bits_uop_storeSetHit(g_io_out_bits_uop_storeSetHit),
    .io_out_bits_uop_waitForRobIdx_flag(g_io_out_bits_uop_waitForRobIdx_flag),
    .io_out_bits_uop_waitForRobIdx_value(g_io_out_bits_uop_waitForRobIdx_value),
    .io_out_bits_uop_loadWaitBit(g_io_out_bits_uop_loadWaitBit),
    .io_out_bits_uop_loadWaitStrict(g_io_out_bits_uop_loadWaitStrict),
    .io_out_bits_uop_lqIdx_flag(g_io_out_bits_uop_lqIdx_flag),
    .io_out_bits_uop_lqIdx_value(g_io_out_bits_uop_lqIdx_value),
    .io_out_bits_uop_sqIdx_flag(g_io_out_bits_uop_sqIdx_flag),
    .io_out_bits_uop_sqIdx_value(g_io_out_bits_uop_sqIdx_value),
    .io_out_bits_mBIndex(g_io_out_bits_mBIndex),
    .io_out_bits_elemIdx(g_io_out_bits_elemIdx),
    .io_out_bits_elemIdxInsideVd(g_io_out_bits_elemIdxInsideVd)
  );
  VLSplitImp_xs u_i (
    .clock(clk), .reset(rst),
    .io_redirect_valid(io_redirect_valid),
    .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value),
    .io_redirect_bits_level(io_redirect_bits_level),
    .io_in_valid(io_in_valid),
    .io_in_bits_uop_ftqPtr_flag(io_in_bits_uop_ftqPtr_flag),
    .io_in_bits_uop_ftqPtr_value(io_in_bits_uop_ftqPtr_value),
    .io_in_bits_uop_ftqOffset(io_in_bits_uop_ftqOffset),
    .io_in_bits_uop_fuOpType(io_in_bits_uop_fuOpType),
    .io_in_bits_uop_vecWen(io_in_bits_uop_vecWen),
    .io_in_bits_uop_v0Wen(io_in_bits_uop_v0Wen),
    .io_in_bits_uop_vlWen(io_in_bits_uop_vlWen),
    .io_in_bits_uop_vpu_vma(io_in_bits_uop_vpu_vma),
    .io_in_bits_uop_vpu_vta(io_in_bits_uop_vpu_vta),
    .io_in_bits_uop_vpu_vsew(io_in_bits_uop_vpu_vsew),
    .io_in_bits_uop_vpu_vlmul(io_in_bits_uop_vpu_vlmul),
    .io_in_bits_uop_vpu_vm(io_in_bits_uop_vpu_vm),
    .io_in_bits_uop_vpu_vstart(io_in_bits_uop_vpu_vstart),
    .io_in_bits_uop_vpu_vuopIdx(io_in_bits_uop_vpu_vuopIdx),
    .io_in_bits_uop_vpu_nf(io_in_bits_uop_vpu_nf),
    .io_in_bits_uop_vpu_veew(io_in_bits_uop_vpu_veew),
    .io_in_bits_uop_pdest(io_in_bits_uop_pdest),
    .io_in_bits_uop_robIdx_flag(io_in_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value(io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_debugInfo_enqRsTime(io_in_bits_uop_debugInfo_enqRsTime),
    .io_in_bits_uop_debugInfo_selectTime(io_in_bits_uop_debugInfo_selectTime),
    .io_in_bits_uop_debugInfo_issueTime(io_in_bits_uop_debugInfo_issueTime),
    .io_in_bits_uop_lqIdx_flag(io_in_bits_uop_lqIdx_flag),
    .io_in_bits_uop_lqIdx_value(io_in_bits_uop_lqIdx_value),
    .io_in_bits_uop_sqIdx_flag(io_in_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value(io_in_bits_uop_sqIdx_value),
    .io_in_bits_src_0(io_in_bits_src_0),
    .io_in_bits_src_1(io_in_bits_src_1),
    .io_in_bits_src_2(io_in_bits_src_2),
    .io_in_bits_src_3(io_in_bits_src_3),
    .io_in_bits_src_4(io_in_bits_src_4),
    .io_in_bits_flowNum(io_in_bits_flowNum),
    .io_toMergeBuffer_req_ready(io_toMergeBuffer_req_ready),
    .io_toMergeBuffer_resp_valid(io_toMergeBuffer_resp_valid),
    .io_toMergeBuffer_resp_bits_mBIndex(io_toMergeBuffer_resp_bits_mBIndex),
    .io_out_ready(io_out_ready),
    .io_threshold_valid(io_threshold_valid),
    .io_threshold_bits_flag(io_threshold_bits_flag),
    .io_threshold_bits_value(io_threshold_bits_value),
    .io_in_ready(i_io_in_ready),
    .io_toMergeBuffer_req_valid(i_io_toMergeBuffer_req_valid),
    .io_toMergeBuffer_req_bits_mask(i_io_toMergeBuffer_req_bits_mask),
    .io_toMergeBuffer_req_bits_vaddr(i_io_toMergeBuffer_req_bits_vaddr),
    .io_toMergeBuffer_req_bits_flowNum(i_io_toMergeBuffer_req_bits_flowNum),
    .io_toMergeBuffer_req_bits_uop_fuOpType(i_io_toMergeBuffer_req_bits_uop_fuOpType),
    .io_toMergeBuffer_req_bits_uop_vecWen(i_io_toMergeBuffer_req_bits_uop_vecWen),
    .io_toMergeBuffer_req_bits_uop_v0Wen(i_io_toMergeBuffer_req_bits_uop_v0Wen),
    .io_toMergeBuffer_req_bits_uop_vlWen(i_io_toMergeBuffer_req_bits_uop_vlWen),
    .io_toMergeBuffer_req_bits_uop_vpu_vma(i_io_toMergeBuffer_req_bits_uop_vpu_vma),
    .io_toMergeBuffer_req_bits_uop_vpu_vta(i_io_toMergeBuffer_req_bits_uop_vpu_vta),
    .io_toMergeBuffer_req_bits_uop_vpu_vsew(i_io_toMergeBuffer_req_bits_uop_vpu_vsew),
    .io_toMergeBuffer_req_bits_uop_vpu_vlmul(i_io_toMergeBuffer_req_bits_uop_vpu_vlmul),
    .io_toMergeBuffer_req_bits_uop_vpu_vm(i_io_toMergeBuffer_req_bits_uop_vpu_vm),
    .io_toMergeBuffer_req_bits_uop_vpu_vuopIdx(i_io_toMergeBuffer_req_bits_uop_vpu_vuopIdx),
    .io_toMergeBuffer_req_bits_uop_vpu_vl(i_io_toMergeBuffer_req_bits_uop_vpu_vl),
    .io_toMergeBuffer_req_bits_uop_vpu_nf(i_io_toMergeBuffer_req_bits_uop_vpu_nf),
    .io_toMergeBuffer_req_bits_uop_vpu_veew(i_io_toMergeBuffer_req_bits_uop_vpu_veew),
    .io_toMergeBuffer_req_bits_uop_uopIdx(i_io_toMergeBuffer_req_bits_uop_uopIdx),
    .io_toMergeBuffer_req_bits_uop_pdest(i_io_toMergeBuffer_req_bits_uop_pdest),
    .io_toMergeBuffer_req_bits_uop_robIdx_flag(i_io_toMergeBuffer_req_bits_uop_robIdx_flag),
    .io_toMergeBuffer_req_bits_uop_robIdx_value(i_io_toMergeBuffer_req_bits_uop_robIdx_value),
    .io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime(i_io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_selectTime(i_io_toMergeBuffer_req_bits_uop_debugInfo_selectTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_issueTime(i_io_toMergeBuffer_req_bits_uop_debugInfo_issueTime),
    .io_toMergeBuffer_req_bits_data(i_io_toMergeBuffer_req_bits_data),
    .io_toMergeBuffer_req_bits_vdIdx(i_io_toMergeBuffer_req_bits_vdIdx),
    .io_toMergeBuffer_req_bits_fof(i_io_toMergeBuffer_req_bits_fof),
    .io_toMergeBuffer_req_bits_vlmax(i_io_toMergeBuffer_req_bits_vlmax),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_vaddr(i_io_out_bits_vaddr),
    .io_out_bits_basevaddr(i_io_out_bits_basevaddr),
    .io_out_bits_mask(i_io_out_bits_mask),
    .io_out_bits_reg_offset(i_io_out_bits_reg_offset),
    .io_out_bits_alignedType(i_io_out_bits_alignedType),
    .io_out_bits_vecActive(i_io_out_bits_vecActive),
    .io_out_bits_uop_exceptionVec_4(i_io_out_bits_uop_exceptionVec_4),
    .io_out_bits_uop_exceptionVec_5(i_io_out_bits_uop_exceptionVec_5),
    .io_out_bits_uop_exceptionVec_13(i_io_out_bits_uop_exceptionVec_13),
    .io_out_bits_uop_exceptionVec_19(i_io_out_bits_uop_exceptionVec_19),
    .io_out_bits_uop_exceptionVec_21(i_io_out_bits_uop_exceptionVec_21),
    .io_out_bits_uop_trigger(i_io_out_bits_uop_trigger),
    .io_out_bits_uop_preDecodeInfo_isRVC(i_io_out_bits_uop_preDecodeInfo_isRVC),
    .io_out_bits_uop_ftqPtr_flag(i_io_out_bits_uop_ftqPtr_flag),
    .io_out_bits_uop_ftqPtr_value(i_io_out_bits_uop_ftqPtr_value),
    .io_out_bits_uop_ftqOffset(i_io_out_bits_uop_ftqOffset),
    .io_out_bits_uop_fuOpType(i_io_out_bits_uop_fuOpType),
    .io_out_bits_uop_rfWen(i_io_out_bits_uop_rfWen),
    .io_out_bits_uop_fpWen(i_io_out_bits_uop_fpWen),
    .io_out_bits_uop_vpu_vstart(i_io_out_bits_uop_vpu_vstart),
    .io_out_bits_uop_vpu_veew(i_io_out_bits_uop_vpu_veew),
    .io_out_bits_uop_uopIdx(i_io_out_bits_uop_uopIdx),
    .io_out_bits_uop_pdest(i_io_out_bits_uop_pdest),
    .io_out_bits_uop_robIdx_flag(i_io_out_bits_uop_robIdx_flag),
    .io_out_bits_uop_robIdx_value(i_io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_debugInfo_enqRsTime(i_io_out_bits_uop_debugInfo_enqRsTime),
    .io_out_bits_uop_debugInfo_selectTime(i_io_out_bits_uop_debugInfo_selectTime),
    .io_out_bits_uop_debugInfo_issueTime(i_io_out_bits_uop_debugInfo_issueTime),
    .io_out_bits_uop_storeSetHit(i_io_out_bits_uop_storeSetHit),
    .io_out_bits_uop_waitForRobIdx_flag(i_io_out_bits_uop_waitForRobIdx_flag),
    .io_out_bits_uop_waitForRobIdx_value(i_io_out_bits_uop_waitForRobIdx_value),
    .io_out_bits_uop_loadWaitBit(i_io_out_bits_uop_loadWaitBit),
    .io_out_bits_uop_loadWaitStrict(i_io_out_bits_uop_loadWaitStrict),
    .io_out_bits_uop_lqIdx_flag(i_io_out_bits_uop_lqIdx_flag),
    .io_out_bits_uop_lqIdx_value(i_io_out_bits_uop_lqIdx_value),
    .io_out_bits_uop_sqIdx_flag(i_io_out_bits_uop_sqIdx_flag),
    .io_out_bits_uop_sqIdx_value(i_io_out_bits_uop_sqIdx_value),
    .io_out_bits_mBIndex(i_io_out_bits_mBIndex),
    .io_out_bits_elemIdx(i_io_out_bits_elemIdx),
    .io_out_bits_elemIdxInsideVd(i_io_out_bits_elemIdxInsideVd)
  );

  initial begin
    rst = 1;
    io_redirect_valid = 0;
    io_redirect_bits_robIdx_flag = 0;
    io_redirect_bits_robIdx_value = 0;
    io_redirect_bits_level = 0;
    io_in_valid = 0;
    io_in_bits_uop_ftqPtr_flag = 0;
    io_in_bits_uop_ftqPtr_value = 0;
    io_in_bits_uop_ftqOffset = 0;
    io_in_bits_uop_fuOpType = 0;
    io_in_bits_uop_vecWen = 0;
    io_in_bits_uop_v0Wen = 0;
    io_in_bits_uop_vlWen = 0;
    io_in_bits_uop_vpu_vma = 0;
    io_in_bits_uop_vpu_vta = 0;
    io_in_bits_uop_vpu_vsew = 0;
    io_in_bits_uop_vpu_vlmul = 0;
    io_in_bits_uop_vpu_vm = 0;
    io_in_bits_uop_vpu_vstart = 0;
    io_in_bits_uop_vpu_vuopIdx = 0;
    io_in_bits_uop_vpu_nf = 0;
    io_in_bits_uop_vpu_veew = 0;
    io_in_bits_uop_pdest = 0;
    io_in_bits_uop_robIdx_flag = 0;
    io_in_bits_uop_robIdx_value = 0;
    io_in_bits_uop_debugInfo_enqRsTime = 0;
    io_in_bits_uop_debugInfo_selectTime = 0;
    io_in_bits_uop_debugInfo_issueTime = 0;
    io_in_bits_uop_lqIdx_flag = 0;
    io_in_bits_uop_lqIdx_value = 0;
    io_in_bits_uop_sqIdx_flag = 0;
    io_in_bits_uop_sqIdx_value = 0;
    io_in_bits_src_0 = 0;
    io_in_bits_src_1 = 0;
    io_in_bits_src_2 = 0;
    io_in_bits_src_3 = 0;
    io_in_bits_src_4 = 0;
    io_in_bits_flowNum = 0;
    io_toMergeBuffer_req_ready = 0;
    io_toMergeBuffer_resp_valid = 0;
    io_toMergeBuffer_resp_bits_mBIndex = 0;
    io_out_ready = 0;
    io_threshold_valid = 0;
    io_threshold_bits_flag = 0;
    io_threshold_bits_value = 0;
    repeat (WARMUP) @(posedge clk);
    rst = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      io_redirect_valid <= $random;
      io_redirect_bits_robIdx_flag <= $random;
      io_redirect_bits_robIdx_value <= $random;
      io_redirect_bits_level <= $random;
      io_in_valid <= $random;
      io_in_bits_uop_ftqPtr_flag <= $random;
      io_in_bits_uop_ftqPtr_value <= $random;
      io_in_bits_uop_ftqOffset <= $random;
      io_in_bits_uop_fuOpType <= $random;
      io_in_bits_uop_vecWen <= $random;
      io_in_bits_uop_v0Wen <= $random;
      io_in_bits_uop_vlWen <= $random;
      io_in_bits_uop_vpu_vma <= $random;
      io_in_bits_uop_vpu_vta <= $random;
      io_in_bits_uop_vpu_vsew <= $random;
      io_in_bits_uop_vpu_vlmul <= $random;
      io_in_bits_uop_vpu_vm <= $random;
      io_in_bits_uop_vpu_vstart <= $random;
      io_in_bits_uop_vpu_vuopIdx <= $random;
      io_in_bits_uop_vpu_nf <= $random;
      io_in_bits_uop_vpu_veew <= $random;
      io_in_bits_uop_pdest <= $random;
      io_in_bits_uop_robIdx_flag <= $random;
      io_in_bits_uop_robIdx_value <= $random;
      io_in_bits_uop_debugInfo_enqRsTime <= {$random, $random};
      io_in_bits_uop_debugInfo_selectTime <= {$random, $random};
      io_in_bits_uop_debugInfo_issueTime <= {$random, $random};
      io_in_bits_uop_lqIdx_flag <= $random;
      io_in_bits_uop_lqIdx_value <= $random;
      io_in_bits_uop_sqIdx_flag <= $random;
      io_in_bits_uop_sqIdx_value <= $random;
      io_in_bits_src_0 <= {$random, $random, $random, $random};
      io_in_bits_src_1 <= {$random, $random, $random, $random};
      io_in_bits_src_2 <= {$random, $random, $random, $random};
      io_in_bits_src_3 <= {$random, $random, $random, $random};
      io_in_bits_src_4 <= {$random, $random, $random, $random};
      io_in_bits_flowNum <= $random;
      io_toMergeBuffer_req_ready <= $random;
      io_toMergeBuffer_resp_valid <= $random;
      io_toMergeBuffer_resp_bits_mBIndex <= $random;
      io_out_ready <= $random;
      io_threshold_valid <= $random;
      io_threshold_bits_flag <= $random;
      io_threshold_bits_value <= $random;
      @(posedge clk);
      #1;
      if (cyc > 2) begin
        checks++;
      if (g_io_in_ready !== i_io_in_ready) begin errors++; if (errors<20) $display("MISMATCH io_in_ready @%0d g=%h i=%h", cyc, g_io_in_ready, i_io_in_ready); end
      if (g_io_toMergeBuffer_req_valid !== i_io_toMergeBuffer_req_valid) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_valid @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_valid, i_io_toMergeBuffer_req_valid); end
      if (g_io_toMergeBuffer_req_bits_mask !== i_io_toMergeBuffer_req_bits_mask) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_mask @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_mask, i_io_toMergeBuffer_req_bits_mask); end
      if (g_io_toMergeBuffer_req_bits_vaddr !== i_io_toMergeBuffer_req_bits_vaddr) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_vaddr @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_vaddr, i_io_toMergeBuffer_req_bits_vaddr); end
      if (g_io_toMergeBuffer_req_bits_flowNum !== i_io_toMergeBuffer_req_bits_flowNum) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_flowNum @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_flowNum, i_io_toMergeBuffer_req_bits_flowNum); end
      if (g_io_toMergeBuffer_req_bits_uop_fuOpType !== i_io_toMergeBuffer_req_bits_uop_fuOpType) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_uop_fuOpType @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_uop_fuOpType, i_io_toMergeBuffer_req_bits_uop_fuOpType); end
      if (g_io_toMergeBuffer_req_bits_uop_vecWen !== i_io_toMergeBuffer_req_bits_uop_vecWen) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_uop_vecWen @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_uop_vecWen, i_io_toMergeBuffer_req_bits_uop_vecWen); end
      if (g_io_toMergeBuffer_req_bits_uop_v0Wen !== i_io_toMergeBuffer_req_bits_uop_v0Wen) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_uop_v0Wen @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_uop_v0Wen, i_io_toMergeBuffer_req_bits_uop_v0Wen); end
      if (g_io_toMergeBuffer_req_bits_uop_vlWen !== i_io_toMergeBuffer_req_bits_uop_vlWen) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_uop_vlWen @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_uop_vlWen, i_io_toMergeBuffer_req_bits_uop_vlWen); end
      if (g_io_toMergeBuffer_req_bits_uop_vpu_vma !== i_io_toMergeBuffer_req_bits_uop_vpu_vma) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_uop_vpu_vma @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_uop_vpu_vma, i_io_toMergeBuffer_req_bits_uop_vpu_vma); end
      if (g_io_toMergeBuffer_req_bits_uop_vpu_vta !== i_io_toMergeBuffer_req_bits_uop_vpu_vta) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_uop_vpu_vta @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_uop_vpu_vta, i_io_toMergeBuffer_req_bits_uop_vpu_vta); end
      if (g_io_toMergeBuffer_req_bits_uop_vpu_vsew !== i_io_toMergeBuffer_req_bits_uop_vpu_vsew) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_uop_vpu_vsew @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_uop_vpu_vsew, i_io_toMergeBuffer_req_bits_uop_vpu_vsew); end
      if (g_io_toMergeBuffer_req_bits_uop_vpu_vlmul !== i_io_toMergeBuffer_req_bits_uop_vpu_vlmul) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_uop_vpu_vlmul @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_uop_vpu_vlmul, i_io_toMergeBuffer_req_bits_uop_vpu_vlmul); end
      if (g_io_toMergeBuffer_req_bits_uop_vpu_vm !== i_io_toMergeBuffer_req_bits_uop_vpu_vm) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_uop_vpu_vm @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_uop_vpu_vm, i_io_toMergeBuffer_req_bits_uop_vpu_vm); end
      if (g_io_toMergeBuffer_req_bits_uop_vpu_vuopIdx !== i_io_toMergeBuffer_req_bits_uop_vpu_vuopIdx) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_uop_vpu_vuopIdx @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_uop_vpu_vuopIdx, i_io_toMergeBuffer_req_bits_uop_vpu_vuopIdx); end
      if (g_io_toMergeBuffer_req_bits_uop_vpu_vl !== i_io_toMergeBuffer_req_bits_uop_vpu_vl) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_uop_vpu_vl @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_uop_vpu_vl, i_io_toMergeBuffer_req_bits_uop_vpu_vl); end
      if (g_io_toMergeBuffer_req_bits_uop_vpu_nf !== i_io_toMergeBuffer_req_bits_uop_vpu_nf) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_uop_vpu_nf @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_uop_vpu_nf, i_io_toMergeBuffer_req_bits_uop_vpu_nf); end
      if (g_io_toMergeBuffer_req_bits_uop_vpu_veew !== i_io_toMergeBuffer_req_bits_uop_vpu_veew) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_uop_vpu_veew @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_uop_vpu_veew, i_io_toMergeBuffer_req_bits_uop_vpu_veew); end
      if (g_io_toMergeBuffer_req_bits_uop_uopIdx !== i_io_toMergeBuffer_req_bits_uop_uopIdx) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_uop_uopIdx @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_uop_uopIdx, i_io_toMergeBuffer_req_bits_uop_uopIdx); end
      if (g_io_toMergeBuffer_req_bits_uop_pdest !== i_io_toMergeBuffer_req_bits_uop_pdest) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_uop_pdest @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_uop_pdest, i_io_toMergeBuffer_req_bits_uop_pdest); end
      if (g_io_toMergeBuffer_req_bits_uop_robIdx_flag !== i_io_toMergeBuffer_req_bits_uop_robIdx_flag) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_uop_robIdx_flag @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_uop_robIdx_flag, i_io_toMergeBuffer_req_bits_uop_robIdx_flag); end
      if (g_io_toMergeBuffer_req_bits_uop_robIdx_value !== i_io_toMergeBuffer_req_bits_uop_robIdx_value) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_uop_robIdx_value @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_uop_robIdx_value, i_io_toMergeBuffer_req_bits_uop_robIdx_value); end
      if (g_io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime !== i_io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime, i_io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime); end
      if (g_io_toMergeBuffer_req_bits_uop_debugInfo_selectTime !== i_io_toMergeBuffer_req_bits_uop_debugInfo_selectTime) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_uop_debugInfo_selectTime @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_uop_debugInfo_selectTime, i_io_toMergeBuffer_req_bits_uop_debugInfo_selectTime); end
      if (g_io_toMergeBuffer_req_bits_uop_debugInfo_issueTime !== i_io_toMergeBuffer_req_bits_uop_debugInfo_issueTime) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_uop_debugInfo_issueTime @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_uop_debugInfo_issueTime, i_io_toMergeBuffer_req_bits_uop_debugInfo_issueTime); end
      if (g_io_toMergeBuffer_req_bits_data !== i_io_toMergeBuffer_req_bits_data) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_data @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_data, i_io_toMergeBuffer_req_bits_data); end
      if (g_io_toMergeBuffer_req_bits_vdIdx !== i_io_toMergeBuffer_req_bits_vdIdx) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_vdIdx @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_vdIdx, i_io_toMergeBuffer_req_bits_vdIdx); end
      if (g_io_toMergeBuffer_req_bits_fof !== i_io_toMergeBuffer_req_bits_fof) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_fof @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_fof, i_io_toMergeBuffer_req_bits_fof); end
      if (g_io_toMergeBuffer_req_bits_vlmax !== i_io_toMergeBuffer_req_bits_vlmax) begin errors++; if (errors<20) $display("MISMATCH io_toMergeBuffer_req_bits_vlmax @%0d g=%h i=%h", cyc, g_io_toMergeBuffer_req_bits_vlmax, i_io_toMergeBuffer_req_bits_vlmax); end
      if (g_io_out_valid !== i_io_out_valid) begin errors++; if (errors<20) $display("MISMATCH io_out_valid @%0d g=%h i=%h", cyc, g_io_out_valid, i_io_out_valid); end
      if (g_io_out_bits_vaddr !== i_io_out_bits_vaddr) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_vaddr @%0d g=%h i=%h", cyc, g_io_out_bits_vaddr, i_io_out_bits_vaddr); end
      if (g_io_out_bits_basevaddr !== i_io_out_bits_basevaddr) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_basevaddr @%0d g=%h i=%h", cyc, g_io_out_bits_basevaddr, i_io_out_bits_basevaddr); end
      if (g_io_out_bits_mask !== i_io_out_bits_mask) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_mask @%0d g=%h i=%h", cyc, g_io_out_bits_mask, i_io_out_bits_mask); end
      if (g_io_out_bits_reg_offset !== i_io_out_bits_reg_offset) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_reg_offset @%0d g=%h i=%h", cyc, g_io_out_bits_reg_offset, i_io_out_bits_reg_offset); end
      if (g_io_out_bits_alignedType !== i_io_out_bits_alignedType) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_alignedType @%0d g=%h i=%h", cyc, g_io_out_bits_alignedType, i_io_out_bits_alignedType); end
      if (g_io_out_bits_vecActive !== i_io_out_bits_vecActive) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_vecActive @%0d g=%h i=%h", cyc, g_io_out_bits_vecActive, i_io_out_bits_vecActive); end
      if (g_io_out_bits_uop_exceptionVec_4 !== i_io_out_bits_uop_exceptionVec_4) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_exceptionVec_4 @%0d g=%h i=%h", cyc, g_io_out_bits_uop_exceptionVec_4, i_io_out_bits_uop_exceptionVec_4); end
      if (g_io_out_bits_uop_exceptionVec_5 !== i_io_out_bits_uop_exceptionVec_5) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_exceptionVec_5 @%0d g=%h i=%h", cyc, g_io_out_bits_uop_exceptionVec_5, i_io_out_bits_uop_exceptionVec_5); end
      if (g_io_out_bits_uop_exceptionVec_13 !== i_io_out_bits_uop_exceptionVec_13) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_exceptionVec_13 @%0d g=%h i=%h", cyc, g_io_out_bits_uop_exceptionVec_13, i_io_out_bits_uop_exceptionVec_13); end
      if (g_io_out_bits_uop_exceptionVec_19 !== i_io_out_bits_uop_exceptionVec_19) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_exceptionVec_19 @%0d g=%h i=%h", cyc, g_io_out_bits_uop_exceptionVec_19, i_io_out_bits_uop_exceptionVec_19); end
      if (g_io_out_bits_uop_exceptionVec_21 !== i_io_out_bits_uop_exceptionVec_21) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_exceptionVec_21 @%0d g=%h i=%h", cyc, g_io_out_bits_uop_exceptionVec_21, i_io_out_bits_uop_exceptionVec_21); end
      if (g_io_out_bits_uop_trigger !== i_io_out_bits_uop_trigger) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_trigger @%0d g=%h i=%h", cyc, g_io_out_bits_uop_trigger, i_io_out_bits_uop_trigger); end
      if (g_io_out_bits_uop_preDecodeInfo_isRVC !== i_io_out_bits_uop_preDecodeInfo_isRVC) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_preDecodeInfo_isRVC @%0d g=%h i=%h", cyc, g_io_out_bits_uop_preDecodeInfo_isRVC, i_io_out_bits_uop_preDecodeInfo_isRVC); end
      if (g_io_out_bits_uop_ftqPtr_flag !== i_io_out_bits_uop_ftqPtr_flag) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_ftqPtr_flag @%0d g=%h i=%h", cyc, g_io_out_bits_uop_ftqPtr_flag, i_io_out_bits_uop_ftqPtr_flag); end
      if (g_io_out_bits_uop_ftqPtr_value !== i_io_out_bits_uop_ftqPtr_value) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_ftqPtr_value @%0d g=%h i=%h", cyc, g_io_out_bits_uop_ftqPtr_value, i_io_out_bits_uop_ftqPtr_value); end
      if (g_io_out_bits_uop_ftqOffset !== i_io_out_bits_uop_ftqOffset) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_ftqOffset @%0d g=%h i=%h", cyc, g_io_out_bits_uop_ftqOffset, i_io_out_bits_uop_ftqOffset); end
      if (g_io_out_bits_uop_fuOpType !== i_io_out_bits_uop_fuOpType) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_fuOpType @%0d g=%h i=%h", cyc, g_io_out_bits_uop_fuOpType, i_io_out_bits_uop_fuOpType); end
      if (g_io_out_bits_uop_rfWen !== i_io_out_bits_uop_rfWen) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_rfWen @%0d g=%h i=%h", cyc, g_io_out_bits_uop_rfWen, i_io_out_bits_uop_rfWen); end
      if (g_io_out_bits_uop_fpWen !== i_io_out_bits_uop_fpWen) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_fpWen @%0d g=%h i=%h", cyc, g_io_out_bits_uop_fpWen, i_io_out_bits_uop_fpWen); end
      if (g_io_out_bits_uop_vpu_vstart !== i_io_out_bits_uop_vpu_vstart) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_vpu_vstart @%0d g=%h i=%h", cyc, g_io_out_bits_uop_vpu_vstart, i_io_out_bits_uop_vpu_vstart); end
      if (g_io_out_bits_uop_vpu_veew !== i_io_out_bits_uop_vpu_veew) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_vpu_veew @%0d g=%h i=%h", cyc, g_io_out_bits_uop_vpu_veew, i_io_out_bits_uop_vpu_veew); end
      if (g_io_out_bits_uop_uopIdx !== i_io_out_bits_uop_uopIdx) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_uopIdx @%0d g=%h i=%h", cyc, g_io_out_bits_uop_uopIdx, i_io_out_bits_uop_uopIdx); end
      if (g_io_out_bits_uop_pdest !== i_io_out_bits_uop_pdest) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_pdest @%0d g=%h i=%h", cyc, g_io_out_bits_uop_pdest, i_io_out_bits_uop_pdest); end
      if (g_io_out_bits_uop_robIdx_flag !== i_io_out_bits_uop_robIdx_flag) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_robIdx_flag @%0d g=%h i=%h", cyc, g_io_out_bits_uop_robIdx_flag, i_io_out_bits_uop_robIdx_flag); end
      if (g_io_out_bits_uop_robIdx_value !== i_io_out_bits_uop_robIdx_value) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_robIdx_value @%0d g=%h i=%h", cyc, g_io_out_bits_uop_robIdx_value, i_io_out_bits_uop_robIdx_value); end
      if (g_io_out_bits_uop_debugInfo_enqRsTime !== i_io_out_bits_uop_debugInfo_enqRsTime) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_debugInfo_enqRsTime @%0d g=%h i=%h", cyc, g_io_out_bits_uop_debugInfo_enqRsTime, i_io_out_bits_uop_debugInfo_enqRsTime); end
      if (g_io_out_bits_uop_debugInfo_selectTime !== i_io_out_bits_uop_debugInfo_selectTime) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_debugInfo_selectTime @%0d g=%h i=%h", cyc, g_io_out_bits_uop_debugInfo_selectTime, i_io_out_bits_uop_debugInfo_selectTime); end
      if (g_io_out_bits_uop_debugInfo_issueTime !== i_io_out_bits_uop_debugInfo_issueTime) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_debugInfo_issueTime @%0d g=%h i=%h", cyc, g_io_out_bits_uop_debugInfo_issueTime, i_io_out_bits_uop_debugInfo_issueTime); end
      if (g_io_out_bits_uop_storeSetHit !== i_io_out_bits_uop_storeSetHit) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_storeSetHit @%0d g=%h i=%h", cyc, g_io_out_bits_uop_storeSetHit, i_io_out_bits_uop_storeSetHit); end
      if (g_io_out_bits_uop_waitForRobIdx_flag !== i_io_out_bits_uop_waitForRobIdx_flag) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_waitForRobIdx_flag @%0d g=%h i=%h", cyc, g_io_out_bits_uop_waitForRobIdx_flag, i_io_out_bits_uop_waitForRobIdx_flag); end
      if (g_io_out_bits_uop_waitForRobIdx_value !== i_io_out_bits_uop_waitForRobIdx_value) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_waitForRobIdx_value @%0d g=%h i=%h", cyc, g_io_out_bits_uop_waitForRobIdx_value, i_io_out_bits_uop_waitForRobIdx_value); end
      if (g_io_out_bits_uop_loadWaitBit !== i_io_out_bits_uop_loadWaitBit) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_loadWaitBit @%0d g=%h i=%h", cyc, g_io_out_bits_uop_loadWaitBit, i_io_out_bits_uop_loadWaitBit); end
      if (g_io_out_bits_uop_loadWaitStrict !== i_io_out_bits_uop_loadWaitStrict) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_loadWaitStrict @%0d g=%h i=%h", cyc, g_io_out_bits_uop_loadWaitStrict, i_io_out_bits_uop_loadWaitStrict); end
      if (g_io_out_bits_uop_lqIdx_flag !== i_io_out_bits_uop_lqIdx_flag) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_lqIdx_flag @%0d g=%h i=%h", cyc, g_io_out_bits_uop_lqIdx_flag, i_io_out_bits_uop_lqIdx_flag); end
      if (g_io_out_bits_uop_lqIdx_value !== i_io_out_bits_uop_lqIdx_value) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_lqIdx_value @%0d g=%h i=%h", cyc, g_io_out_bits_uop_lqIdx_value, i_io_out_bits_uop_lqIdx_value); end
      if (g_io_out_bits_uop_sqIdx_flag !== i_io_out_bits_uop_sqIdx_flag) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_sqIdx_flag @%0d g=%h i=%h", cyc, g_io_out_bits_uop_sqIdx_flag, i_io_out_bits_uop_sqIdx_flag); end
      if (g_io_out_bits_uop_sqIdx_value !== i_io_out_bits_uop_sqIdx_value) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_uop_sqIdx_value @%0d g=%h i=%h", cyc, g_io_out_bits_uop_sqIdx_value, i_io_out_bits_uop_sqIdx_value); end
      if (g_io_out_bits_mBIndex !== i_io_out_bits_mBIndex) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_mBIndex @%0d g=%h i=%h", cyc, g_io_out_bits_mBIndex, i_io_out_bits_mBIndex); end
      if (g_io_out_bits_elemIdx !== i_io_out_bits_elemIdx) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_elemIdx @%0d g=%h i=%h", cyc, g_io_out_bits_elemIdx, i_io_out_bits_elemIdx); end
      if (g_io_out_bits_elemIdxInsideVd !== i_io_out_bits_elemIdxInsideVd) begin errors++; if (errors<20) $display("MISMATCH io_out_bits_elemIdxInsideVd @%0d g=%h i=%h", cyc, g_io_out_bits_elemIdxInsideVd, i_io_out_bits_elemIdxInsideVd); end
      end
    end
    if (errors == 0) $display("TEST PASSED checks=%0d errors=0", checks);
    else             $display("TEST FAILED checks=%0d errors=%0d", checks, errors);
    $finish;
  end
endmodule
