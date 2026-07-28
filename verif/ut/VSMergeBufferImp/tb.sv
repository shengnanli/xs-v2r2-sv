// 自动生成 gen_vsmerge.py —— 勿手改。双例化 golden VSMergeBufferImp vs VSMergeBufferImp_xs 逐拍比对。
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
  logic io_fromPipeline_0_valid;
  logic [3:0] io_fromPipeline_0_bits_mBIndex;
  logic io_fromPipeline_0_bits_hit;
  logic [3:0] io_fromPipeline_0_bits_trigger;
  logic io_fromPipeline_0_bits_exceptionVec_3;
  logic io_fromPipeline_0_bits_exceptionVec_6;
  logic io_fromPipeline_0_bits_exceptionVec_7;
  logic io_fromPipeline_0_bits_exceptionVec_15;
  logic io_fromPipeline_0_bits_exceptionVec_19;
  logic io_fromPipeline_0_bits_exceptionVec_23;
  logic io_fromPipeline_0_bits_hasException;
  logic [63:0] io_fromPipeline_0_bits_vaddr;
  logic io_fromPipeline_0_bits_vaNeedExt;
  logic [63:0] io_fromPipeline_0_bits_gpaddr;
  logic io_fromPipeline_0_bits_isForVSnonLeafPTE;
  logic [7:0] io_fromPipeline_0_bits_vstart;
  logic [7:0] io_fromPipeline_0_bits_elemIdx;
  logic [15:0] io_fromPipeline_0_bits_mask;
  logic io_fromSplit_0_req_valid;
  logic [15:0] io_fromSplit_0_req_bits_mask;
  logic [49:0] io_fromSplit_0_req_bits_vaddr;
  logic [4:0] io_fromSplit_0_req_bits_flowNum;
  logic [8:0] io_fromSplit_0_req_bits_uop_fuOpType;
  logic io_fromSplit_0_req_bits_uop_vecWen;
  logic io_fromSplit_0_req_bits_uop_v0Wen;
  logic io_fromSplit_0_req_bits_uop_vlWen;
  logic io_fromSplit_0_req_bits_uop_vpu_vma;
  logic io_fromSplit_0_req_bits_uop_vpu_vta;
  logic [1:0] io_fromSplit_0_req_bits_uop_vpu_vsew;
  logic [2:0] io_fromSplit_0_req_bits_uop_vpu_vlmul;
  logic io_fromSplit_0_req_bits_uop_vpu_vm;
  logic [6:0] io_fromSplit_0_req_bits_uop_vpu_vuopIdx;
  logic [127:0] io_fromSplit_0_req_bits_uop_vpu_vmask;
  logic [7:0] io_fromSplit_0_req_bits_uop_vpu_vl;
  logic [2:0] io_fromSplit_0_req_bits_uop_vpu_nf;
  logic [1:0] io_fromSplit_0_req_bits_uop_vpu_veew;
  logic [6:0] io_fromSplit_0_req_bits_uop_uopIdx;
  logic [7:0] io_fromSplit_0_req_bits_uop_pdest;
  logic io_fromSplit_0_req_bits_uop_robIdx_flag;
  logic [7:0] io_fromSplit_0_req_bits_uop_robIdx_value;
  logic [63:0] io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime;
  logic [63:0] io_fromSplit_0_req_bits_uop_debugInfo_selectTime;
  logic [63:0] io_fromSplit_0_req_bits_uop_debugInfo_issueTime;
  logic io_fromSplit_0_req_bits_uop_lqIdx_flag;
  logic [6:0] io_fromSplit_0_req_bits_uop_lqIdx_value;
  logic io_fromSplit_0_req_bits_uop_sqIdx_flag;
  logic [5:0] io_fromSplit_0_req_bits_uop_sqIdx_value;
  logic [7:0] io_fromSplit_0_req_bits_vlmax;
  logic io_uopWriteback_0_ready;
  logic [3:0] io_fromMisalignBuffer_mbIndex;
  logic io_fromMisalignBuffer_flush;
  logic g_io_fromSplit_0_req_ready;
  logic i_io_fromSplit_0_req_ready;
  logic g_io_fromSplit_0_resp_valid;
  logic i_io_fromSplit_0_resp_valid;
  logic [3:0] g_io_fromSplit_0_resp_bits_mBIndex;
  logic [3:0] i_io_fromSplit_0_resp_bits_mBIndex;
  logic g_io_uopWriteback_0_valid;
  logic i_io_uopWriteback_0_valid;
  logic g_io_uopWriteback_0_bits_uop_exceptionVec_3;
  logic i_io_uopWriteback_0_bits_uop_exceptionVec_3;
  logic g_io_uopWriteback_0_bits_uop_exceptionVec_6;
  logic i_io_uopWriteback_0_bits_uop_exceptionVec_6;
  logic g_io_uopWriteback_0_bits_uop_exceptionVec_7;
  logic i_io_uopWriteback_0_bits_uop_exceptionVec_7;
  logic g_io_uopWriteback_0_bits_uop_exceptionVec_15;
  logic i_io_uopWriteback_0_bits_uop_exceptionVec_15;
  logic g_io_uopWriteback_0_bits_uop_exceptionVec_19;
  logic i_io_uopWriteback_0_bits_uop_exceptionVec_19;
  logic g_io_uopWriteback_0_bits_uop_exceptionVec_23;
  logic i_io_uopWriteback_0_bits_uop_exceptionVec_23;
  logic [3:0] g_io_uopWriteback_0_bits_uop_trigger;
  logic [3:0] i_io_uopWriteback_0_bits_uop_trigger;
  logic [8:0] g_io_uopWriteback_0_bits_uop_fuOpType;
  logic [8:0] i_io_uopWriteback_0_bits_uop_fuOpType;
  logic g_io_uopWriteback_0_bits_uop_vecWen;
  logic i_io_uopWriteback_0_bits_uop_vecWen;
  logic g_io_uopWriteback_0_bits_uop_v0Wen;
  logic i_io_uopWriteback_0_bits_uop_v0Wen;
  logic g_io_uopWriteback_0_bits_uop_vlWen;
  logic i_io_uopWriteback_0_bits_uop_vlWen;
  logic g_io_uopWriteback_0_bits_uop_flushPipe;
  logic i_io_uopWriteback_0_bits_uop_flushPipe;
  logic g_io_uopWriteback_0_bits_uop_vpu_vma;
  logic i_io_uopWriteback_0_bits_uop_vpu_vma;
  logic g_io_uopWriteback_0_bits_uop_vpu_vta;
  logic i_io_uopWriteback_0_bits_uop_vpu_vta;
  logic [1:0] g_io_uopWriteback_0_bits_uop_vpu_vsew;
  logic [1:0] i_io_uopWriteback_0_bits_uop_vpu_vsew;
  logic [2:0] g_io_uopWriteback_0_bits_uop_vpu_vlmul;
  logic [2:0] i_io_uopWriteback_0_bits_uop_vpu_vlmul;
  logic g_io_uopWriteback_0_bits_uop_vpu_vm;
  logic i_io_uopWriteback_0_bits_uop_vpu_vm;
  logic [7:0] g_io_uopWriteback_0_bits_uop_vpu_vstart;
  logic [7:0] i_io_uopWriteback_0_bits_uop_vpu_vstart;
  logic [6:0] g_io_uopWriteback_0_bits_uop_vpu_vuopIdx;
  logic [6:0] i_io_uopWriteback_0_bits_uop_vpu_vuopIdx;
  logic [127:0] g_io_uopWriteback_0_bits_uop_vpu_vmask;
  logic [127:0] i_io_uopWriteback_0_bits_uop_vpu_vmask;
  logic [7:0] g_io_uopWriteback_0_bits_uop_vpu_vl;
  logic [7:0] i_io_uopWriteback_0_bits_uop_vpu_vl;
  logic [2:0] g_io_uopWriteback_0_bits_uop_vpu_nf;
  logic [2:0] i_io_uopWriteback_0_bits_uop_vpu_nf;
  logic [1:0] g_io_uopWriteback_0_bits_uop_vpu_veew;
  logic [1:0] i_io_uopWriteback_0_bits_uop_vpu_veew;
  logic [7:0] g_io_uopWriteback_0_bits_uop_pdest;
  logic [7:0] i_io_uopWriteback_0_bits_uop_pdest;
  logic g_io_uopWriteback_0_bits_uop_robIdx_flag;
  logic i_io_uopWriteback_0_bits_uop_robIdx_flag;
  logic [7:0] g_io_uopWriteback_0_bits_uop_robIdx_value;
  logic [7:0] i_io_uopWriteback_0_bits_uop_robIdx_value;
  logic [63:0] g_io_uopWriteback_0_bits_uop_debugInfo_enqRsTime;
  logic [63:0] i_io_uopWriteback_0_bits_uop_debugInfo_enqRsTime;
  logic [63:0] g_io_uopWriteback_0_bits_uop_debugInfo_selectTime;
  logic [63:0] i_io_uopWriteback_0_bits_uop_debugInfo_selectTime;
  logic [63:0] g_io_uopWriteback_0_bits_uop_debugInfo_issueTime;
  logic [63:0] i_io_uopWriteback_0_bits_uop_debugInfo_issueTime;
  logic g_io_uopWriteback_0_bits_uop_replayInst;
  logic i_io_uopWriteback_0_bits_uop_replayInst;
  logic [127:0] g_io_uopWriteback_0_bits_data;
  logic [127:0] i_io_uopWriteback_0_bits_data;
  logic [2:0] g_io_uopWriteback_0_bits_vdIdx;
  logic [2:0] i_io_uopWriteback_0_bits_vdIdx;
  logic [2:0] g_io_uopWriteback_0_bits_vdIdxInField;
  logic [2:0] i_io_uopWriteback_0_bits_vdIdxInField;
  logic g_io_toLsq_0_valid;
  logic i_io_toLsq_0_valid;
  logic g_io_toLsq_0_bits_robidx_flag;
  logic i_io_toLsq_0_bits_robidx_flag;
  logic [7:0] g_io_toLsq_0_bits_robidx_value;
  logic [7:0] i_io_toLsq_0_bits_robidx_value;
  logic [6:0] g_io_toLsq_0_bits_uopidx;
  logic [6:0] i_io_toLsq_0_bits_uopidx;
  logic [63:0] g_io_toLsq_0_bits_vaddr;
  logic [63:0] i_io_toLsq_0_bits_vaddr;
  logic g_io_toLsq_0_bits_vaNeedExt;
  logic i_io_toLsq_0_bits_vaNeedExt;
  logic [49:0] g_io_toLsq_0_bits_gpaddr;
  logic [49:0] i_io_toLsq_0_bits_gpaddr;
  logic g_io_toLsq_0_bits_isForVSnonLeafPTE;
  logic i_io_toLsq_0_bits_isForVSnonLeafPTE;
  logic g_io_toLsq_0_bits_feedback_0;
  logic i_io_toLsq_0_bits_feedback_0;
  logic g_io_toLsq_0_bits_feedback_1;
  logic i_io_toLsq_0_bits_feedback_1;
  logic g_io_toLsq_0_bits_exceptionVec_3;
  logic i_io_toLsq_0_bits_exceptionVec_3;
  logic g_io_toLsq_0_bits_exceptionVec_6;
  logic i_io_toLsq_0_bits_exceptionVec_6;
  logic g_io_toLsq_0_bits_exceptionVec_7;
  logic i_io_toLsq_0_bits_exceptionVec_7;
  logic g_io_toLsq_0_bits_exceptionVec_15;
  logic i_io_toLsq_0_bits_exceptionVec_15;
  logic g_io_toLsq_0_bits_exceptionVec_19;
  logic i_io_toLsq_0_bits_exceptionVec_19;
  logic g_io_toLsq_0_bits_exceptionVec_23;
  logic i_io_toLsq_0_bits_exceptionVec_23;
  logic g_io_feedback_0_valid;
  logic i_io_feedback_0_valid;
  logic g_io_feedback_0_bits_hit;
  logic i_io_feedback_0_bits_hit;
  logic g_io_feedback_0_bits_sqIdx_flag;
  logic i_io_feedback_0_bits_sqIdx_flag;
  logic [5:0] g_io_feedback_0_bits_sqIdx_value;
  logic [5:0] i_io_feedback_0_bits_sqIdx_value;
  logic g_io_feedback_0_bits_lqIdx_flag;
  logic i_io_feedback_0_bits_lqIdx_flag;
  logic [6:0] g_io_feedback_0_bits_lqIdx_value;
  logic [6:0] i_io_feedback_0_bits_lqIdx_value;

  VSMergeBufferImp u_g (
    .clock(clk), .reset(rst),
    .io_redirect_valid(io_redirect_valid),
    .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value),
    .io_redirect_bits_level(io_redirect_bits_level),
    .io_fromPipeline_0_valid(io_fromPipeline_0_valid),
    .io_fromPipeline_0_bits_mBIndex(io_fromPipeline_0_bits_mBIndex),
    .io_fromPipeline_0_bits_hit(io_fromPipeline_0_bits_hit),
    .io_fromPipeline_0_bits_trigger(io_fromPipeline_0_bits_trigger),
    .io_fromPipeline_0_bits_exceptionVec_3(io_fromPipeline_0_bits_exceptionVec_3),
    .io_fromPipeline_0_bits_exceptionVec_6(io_fromPipeline_0_bits_exceptionVec_6),
    .io_fromPipeline_0_bits_exceptionVec_7(io_fromPipeline_0_bits_exceptionVec_7),
    .io_fromPipeline_0_bits_exceptionVec_15(io_fromPipeline_0_bits_exceptionVec_15),
    .io_fromPipeline_0_bits_exceptionVec_19(io_fromPipeline_0_bits_exceptionVec_19),
    .io_fromPipeline_0_bits_exceptionVec_23(io_fromPipeline_0_bits_exceptionVec_23),
    .io_fromPipeline_0_bits_hasException(io_fromPipeline_0_bits_hasException),
    .io_fromPipeline_0_bits_vaddr(io_fromPipeline_0_bits_vaddr),
    .io_fromPipeline_0_bits_vaNeedExt(io_fromPipeline_0_bits_vaNeedExt),
    .io_fromPipeline_0_bits_gpaddr(io_fromPipeline_0_bits_gpaddr),
    .io_fromPipeline_0_bits_isForVSnonLeafPTE(io_fromPipeline_0_bits_isForVSnonLeafPTE),
    .io_fromPipeline_0_bits_vstart(io_fromPipeline_0_bits_vstart),
    .io_fromPipeline_0_bits_elemIdx(io_fromPipeline_0_bits_elemIdx),
    .io_fromPipeline_0_bits_mask(io_fromPipeline_0_bits_mask),
    .io_fromSplit_0_req_valid(io_fromSplit_0_req_valid),
    .io_fromSplit_0_req_bits_mask(io_fromSplit_0_req_bits_mask),
    .io_fromSplit_0_req_bits_vaddr(io_fromSplit_0_req_bits_vaddr),
    .io_fromSplit_0_req_bits_flowNum(io_fromSplit_0_req_bits_flowNum),
    .io_fromSplit_0_req_bits_uop_fuOpType(io_fromSplit_0_req_bits_uop_fuOpType),
    .io_fromSplit_0_req_bits_uop_vecWen(io_fromSplit_0_req_bits_uop_vecWen),
    .io_fromSplit_0_req_bits_uop_v0Wen(io_fromSplit_0_req_bits_uop_v0Wen),
    .io_fromSplit_0_req_bits_uop_vlWen(io_fromSplit_0_req_bits_uop_vlWen),
    .io_fromSplit_0_req_bits_uop_vpu_vma(io_fromSplit_0_req_bits_uop_vpu_vma),
    .io_fromSplit_0_req_bits_uop_vpu_vta(io_fromSplit_0_req_bits_uop_vpu_vta),
    .io_fromSplit_0_req_bits_uop_vpu_vsew(io_fromSplit_0_req_bits_uop_vpu_vsew),
    .io_fromSplit_0_req_bits_uop_vpu_vlmul(io_fromSplit_0_req_bits_uop_vpu_vlmul),
    .io_fromSplit_0_req_bits_uop_vpu_vm(io_fromSplit_0_req_bits_uop_vpu_vm),
    .io_fromSplit_0_req_bits_uop_vpu_vuopIdx(io_fromSplit_0_req_bits_uop_vpu_vuopIdx),
    .io_fromSplit_0_req_bits_uop_vpu_vmask(io_fromSplit_0_req_bits_uop_vpu_vmask),
    .io_fromSplit_0_req_bits_uop_vpu_vl(io_fromSplit_0_req_bits_uop_vpu_vl),
    .io_fromSplit_0_req_bits_uop_vpu_nf(io_fromSplit_0_req_bits_uop_vpu_nf),
    .io_fromSplit_0_req_bits_uop_vpu_veew(io_fromSplit_0_req_bits_uop_vpu_veew),
    .io_fromSplit_0_req_bits_uop_uopIdx(io_fromSplit_0_req_bits_uop_uopIdx),
    .io_fromSplit_0_req_bits_uop_pdest(io_fromSplit_0_req_bits_uop_pdest),
    .io_fromSplit_0_req_bits_uop_robIdx_flag(io_fromSplit_0_req_bits_uop_robIdx_flag),
    .io_fromSplit_0_req_bits_uop_robIdx_value(io_fromSplit_0_req_bits_uop_robIdx_value),
    .io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime(io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_selectTime(io_fromSplit_0_req_bits_uop_debugInfo_selectTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_issueTime(io_fromSplit_0_req_bits_uop_debugInfo_issueTime),
    .io_fromSplit_0_req_bits_uop_lqIdx_flag(io_fromSplit_0_req_bits_uop_lqIdx_flag),
    .io_fromSplit_0_req_bits_uop_lqIdx_value(io_fromSplit_0_req_bits_uop_lqIdx_value),
    .io_fromSplit_0_req_bits_uop_sqIdx_flag(io_fromSplit_0_req_bits_uop_sqIdx_flag),
    .io_fromSplit_0_req_bits_uop_sqIdx_value(io_fromSplit_0_req_bits_uop_sqIdx_value),
    .io_fromSplit_0_req_bits_vlmax(io_fromSplit_0_req_bits_vlmax),
    .io_uopWriteback_0_ready(io_uopWriteback_0_ready),
    .io_fromMisalignBuffer_mbIndex(io_fromMisalignBuffer_mbIndex),
    .io_fromMisalignBuffer_flush(io_fromMisalignBuffer_flush),
    .io_fromSplit_0_req_ready(g_io_fromSplit_0_req_ready),
    .io_fromSplit_0_resp_valid(g_io_fromSplit_0_resp_valid),
    .io_fromSplit_0_resp_bits_mBIndex(g_io_fromSplit_0_resp_bits_mBIndex),
    .io_uopWriteback_0_valid(g_io_uopWriteback_0_valid),
    .io_uopWriteback_0_bits_uop_exceptionVec_3(g_io_uopWriteback_0_bits_uop_exceptionVec_3),
    .io_uopWriteback_0_bits_uop_exceptionVec_6(g_io_uopWriteback_0_bits_uop_exceptionVec_6),
    .io_uopWriteback_0_bits_uop_exceptionVec_7(g_io_uopWriteback_0_bits_uop_exceptionVec_7),
    .io_uopWriteback_0_bits_uop_exceptionVec_15(g_io_uopWriteback_0_bits_uop_exceptionVec_15),
    .io_uopWriteback_0_bits_uop_exceptionVec_19(g_io_uopWriteback_0_bits_uop_exceptionVec_19),
    .io_uopWriteback_0_bits_uop_exceptionVec_23(g_io_uopWriteback_0_bits_uop_exceptionVec_23),
    .io_uopWriteback_0_bits_uop_trigger(g_io_uopWriteback_0_bits_uop_trigger),
    .io_uopWriteback_0_bits_uop_fuOpType(g_io_uopWriteback_0_bits_uop_fuOpType),
    .io_uopWriteback_0_bits_uop_vecWen(g_io_uopWriteback_0_bits_uop_vecWen),
    .io_uopWriteback_0_bits_uop_v0Wen(g_io_uopWriteback_0_bits_uop_v0Wen),
    .io_uopWriteback_0_bits_uop_vlWen(g_io_uopWriteback_0_bits_uop_vlWen),
    .io_uopWriteback_0_bits_uop_flushPipe(g_io_uopWriteback_0_bits_uop_flushPipe),
    .io_uopWriteback_0_bits_uop_vpu_vma(g_io_uopWriteback_0_bits_uop_vpu_vma),
    .io_uopWriteback_0_bits_uop_vpu_vta(g_io_uopWriteback_0_bits_uop_vpu_vta),
    .io_uopWriteback_0_bits_uop_vpu_vsew(g_io_uopWriteback_0_bits_uop_vpu_vsew),
    .io_uopWriteback_0_bits_uop_vpu_vlmul(g_io_uopWriteback_0_bits_uop_vpu_vlmul),
    .io_uopWriteback_0_bits_uop_vpu_vm(g_io_uopWriteback_0_bits_uop_vpu_vm),
    .io_uopWriteback_0_bits_uop_vpu_vstart(g_io_uopWriteback_0_bits_uop_vpu_vstart),
    .io_uopWriteback_0_bits_uop_vpu_vuopIdx(g_io_uopWriteback_0_bits_uop_vpu_vuopIdx),
    .io_uopWriteback_0_bits_uop_vpu_vmask(g_io_uopWriteback_0_bits_uop_vpu_vmask),
    .io_uopWriteback_0_bits_uop_vpu_vl(g_io_uopWriteback_0_bits_uop_vpu_vl),
    .io_uopWriteback_0_bits_uop_vpu_nf(g_io_uopWriteback_0_bits_uop_vpu_nf),
    .io_uopWriteback_0_bits_uop_vpu_veew(g_io_uopWriteback_0_bits_uop_vpu_veew),
    .io_uopWriteback_0_bits_uop_pdest(g_io_uopWriteback_0_bits_uop_pdest),
    .io_uopWriteback_0_bits_uop_robIdx_flag(g_io_uopWriteback_0_bits_uop_robIdx_flag),
    .io_uopWriteback_0_bits_uop_robIdx_value(g_io_uopWriteback_0_bits_uop_robIdx_value),
    .io_uopWriteback_0_bits_uop_debugInfo_enqRsTime(g_io_uopWriteback_0_bits_uop_debugInfo_enqRsTime),
    .io_uopWriteback_0_bits_uop_debugInfo_selectTime(g_io_uopWriteback_0_bits_uop_debugInfo_selectTime),
    .io_uopWriteback_0_bits_uop_debugInfo_issueTime(g_io_uopWriteback_0_bits_uop_debugInfo_issueTime),
    .io_uopWriteback_0_bits_uop_replayInst(g_io_uopWriteback_0_bits_uop_replayInst),
    .io_uopWriteback_0_bits_data(g_io_uopWriteback_0_bits_data),
    .io_uopWriteback_0_bits_vdIdx(g_io_uopWriteback_0_bits_vdIdx),
    .io_uopWriteback_0_bits_vdIdxInField(g_io_uopWriteback_0_bits_vdIdxInField),
    .io_toLsq_0_valid(g_io_toLsq_0_valid),
    .io_toLsq_0_bits_robidx_flag(g_io_toLsq_0_bits_robidx_flag),
    .io_toLsq_0_bits_robidx_value(g_io_toLsq_0_bits_robidx_value),
    .io_toLsq_0_bits_uopidx(g_io_toLsq_0_bits_uopidx),
    .io_toLsq_0_bits_vaddr(g_io_toLsq_0_bits_vaddr),
    .io_toLsq_0_bits_vaNeedExt(g_io_toLsq_0_bits_vaNeedExt),
    .io_toLsq_0_bits_gpaddr(g_io_toLsq_0_bits_gpaddr),
    .io_toLsq_0_bits_isForVSnonLeafPTE(g_io_toLsq_0_bits_isForVSnonLeafPTE),
    .io_toLsq_0_bits_feedback_0(g_io_toLsq_0_bits_feedback_0),
    .io_toLsq_0_bits_feedback_1(g_io_toLsq_0_bits_feedback_1),
    .io_toLsq_0_bits_exceptionVec_3(g_io_toLsq_0_bits_exceptionVec_3),
    .io_toLsq_0_bits_exceptionVec_6(g_io_toLsq_0_bits_exceptionVec_6),
    .io_toLsq_0_bits_exceptionVec_7(g_io_toLsq_0_bits_exceptionVec_7),
    .io_toLsq_0_bits_exceptionVec_15(g_io_toLsq_0_bits_exceptionVec_15),
    .io_toLsq_0_bits_exceptionVec_19(g_io_toLsq_0_bits_exceptionVec_19),
    .io_toLsq_0_bits_exceptionVec_23(g_io_toLsq_0_bits_exceptionVec_23),
    .io_feedback_0_valid(g_io_feedback_0_valid),
    .io_feedback_0_bits_hit(g_io_feedback_0_bits_hit),
    .io_feedback_0_bits_sqIdx_flag(g_io_feedback_0_bits_sqIdx_flag),
    .io_feedback_0_bits_sqIdx_value(g_io_feedback_0_bits_sqIdx_value),
    .io_feedback_0_bits_lqIdx_flag(g_io_feedback_0_bits_lqIdx_flag),
    .io_feedback_0_bits_lqIdx_value(g_io_feedback_0_bits_lqIdx_value)
  );
  VSMergeBufferImp_xs u_i (
    .clock(clk), .reset(rst),
    .io_redirect_valid(io_redirect_valid),
    .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value),
    .io_redirect_bits_level(io_redirect_bits_level),
    .io_fromPipeline_0_valid(io_fromPipeline_0_valid),
    .io_fromPipeline_0_bits_mBIndex(io_fromPipeline_0_bits_mBIndex),
    .io_fromPipeline_0_bits_hit(io_fromPipeline_0_bits_hit),
    .io_fromPipeline_0_bits_trigger(io_fromPipeline_0_bits_trigger),
    .io_fromPipeline_0_bits_exceptionVec_3(io_fromPipeline_0_bits_exceptionVec_3),
    .io_fromPipeline_0_bits_exceptionVec_6(io_fromPipeline_0_bits_exceptionVec_6),
    .io_fromPipeline_0_bits_exceptionVec_7(io_fromPipeline_0_bits_exceptionVec_7),
    .io_fromPipeline_0_bits_exceptionVec_15(io_fromPipeline_0_bits_exceptionVec_15),
    .io_fromPipeline_0_bits_exceptionVec_19(io_fromPipeline_0_bits_exceptionVec_19),
    .io_fromPipeline_0_bits_exceptionVec_23(io_fromPipeline_0_bits_exceptionVec_23),
    .io_fromPipeline_0_bits_hasException(io_fromPipeline_0_bits_hasException),
    .io_fromPipeline_0_bits_vaddr(io_fromPipeline_0_bits_vaddr),
    .io_fromPipeline_0_bits_vaNeedExt(io_fromPipeline_0_bits_vaNeedExt),
    .io_fromPipeline_0_bits_gpaddr(io_fromPipeline_0_bits_gpaddr),
    .io_fromPipeline_0_bits_isForVSnonLeafPTE(io_fromPipeline_0_bits_isForVSnonLeafPTE),
    .io_fromPipeline_0_bits_vstart(io_fromPipeline_0_bits_vstart),
    .io_fromPipeline_0_bits_elemIdx(io_fromPipeline_0_bits_elemIdx),
    .io_fromPipeline_0_bits_mask(io_fromPipeline_0_bits_mask),
    .io_fromSplit_0_req_valid(io_fromSplit_0_req_valid),
    .io_fromSplit_0_req_bits_mask(io_fromSplit_0_req_bits_mask),
    .io_fromSplit_0_req_bits_vaddr(io_fromSplit_0_req_bits_vaddr),
    .io_fromSplit_0_req_bits_flowNum(io_fromSplit_0_req_bits_flowNum),
    .io_fromSplit_0_req_bits_uop_fuOpType(io_fromSplit_0_req_bits_uop_fuOpType),
    .io_fromSplit_0_req_bits_uop_vecWen(io_fromSplit_0_req_bits_uop_vecWen),
    .io_fromSplit_0_req_bits_uop_v0Wen(io_fromSplit_0_req_bits_uop_v0Wen),
    .io_fromSplit_0_req_bits_uop_vlWen(io_fromSplit_0_req_bits_uop_vlWen),
    .io_fromSplit_0_req_bits_uop_vpu_vma(io_fromSplit_0_req_bits_uop_vpu_vma),
    .io_fromSplit_0_req_bits_uop_vpu_vta(io_fromSplit_0_req_bits_uop_vpu_vta),
    .io_fromSplit_0_req_bits_uop_vpu_vsew(io_fromSplit_0_req_bits_uop_vpu_vsew),
    .io_fromSplit_0_req_bits_uop_vpu_vlmul(io_fromSplit_0_req_bits_uop_vpu_vlmul),
    .io_fromSplit_0_req_bits_uop_vpu_vm(io_fromSplit_0_req_bits_uop_vpu_vm),
    .io_fromSplit_0_req_bits_uop_vpu_vuopIdx(io_fromSplit_0_req_bits_uop_vpu_vuopIdx),
    .io_fromSplit_0_req_bits_uop_vpu_vmask(io_fromSplit_0_req_bits_uop_vpu_vmask),
    .io_fromSplit_0_req_bits_uop_vpu_vl(io_fromSplit_0_req_bits_uop_vpu_vl),
    .io_fromSplit_0_req_bits_uop_vpu_nf(io_fromSplit_0_req_bits_uop_vpu_nf),
    .io_fromSplit_0_req_bits_uop_vpu_veew(io_fromSplit_0_req_bits_uop_vpu_veew),
    .io_fromSplit_0_req_bits_uop_uopIdx(io_fromSplit_0_req_bits_uop_uopIdx),
    .io_fromSplit_0_req_bits_uop_pdest(io_fromSplit_0_req_bits_uop_pdest),
    .io_fromSplit_0_req_bits_uop_robIdx_flag(io_fromSplit_0_req_bits_uop_robIdx_flag),
    .io_fromSplit_0_req_bits_uop_robIdx_value(io_fromSplit_0_req_bits_uop_robIdx_value),
    .io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime(io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_selectTime(io_fromSplit_0_req_bits_uop_debugInfo_selectTime),
    .io_fromSplit_0_req_bits_uop_debugInfo_issueTime(io_fromSplit_0_req_bits_uop_debugInfo_issueTime),
    .io_fromSplit_0_req_bits_uop_lqIdx_flag(io_fromSplit_0_req_bits_uop_lqIdx_flag),
    .io_fromSplit_0_req_bits_uop_lqIdx_value(io_fromSplit_0_req_bits_uop_lqIdx_value),
    .io_fromSplit_0_req_bits_uop_sqIdx_flag(io_fromSplit_0_req_bits_uop_sqIdx_flag),
    .io_fromSplit_0_req_bits_uop_sqIdx_value(io_fromSplit_0_req_bits_uop_sqIdx_value),
    .io_fromSplit_0_req_bits_vlmax(io_fromSplit_0_req_bits_vlmax),
    .io_uopWriteback_0_ready(io_uopWriteback_0_ready),
    .io_fromMisalignBuffer_mbIndex(io_fromMisalignBuffer_mbIndex),
    .io_fromMisalignBuffer_flush(io_fromMisalignBuffer_flush),
    .io_fromSplit_0_req_ready(i_io_fromSplit_0_req_ready),
    .io_fromSplit_0_resp_valid(i_io_fromSplit_0_resp_valid),
    .io_fromSplit_0_resp_bits_mBIndex(i_io_fromSplit_0_resp_bits_mBIndex),
    .io_uopWriteback_0_valid(i_io_uopWriteback_0_valid),
    .io_uopWriteback_0_bits_uop_exceptionVec_3(i_io_uopWriteback_0_bits_uop_exceptionVec_3),
    .io_uopWriteback_0_bits_uop_exceptionVec_6(i_io_uopWriteback_0_bits_uop_exceptionVec_6),
    .io_uopWriteback_0_bits_uop_exceptionVec_7(i_io_uopWriteback_0_bits_uop_exceptionVec_7),
    .io_uopWriteback_0_bits_uop_exceptionVec_15(i_io_uopWriteback_0_bits_uop_exceptionVec_15),
    .io_uopWriteback_0_bits_uop_exceptionVec_19(i_io_uopWriteback_0_bits_uop_exceptionVec_19),
    .io_uopWriteback_0_bits_uop_exceptionVec_23(i_io_uopWriteback_0_bits_uop_exceptionVec_23),
    .io_uopWriteback_0_bits_uop_trigger(i_io_uopWriteback_0_bits_uop_trigger),
    .io_uopWriteback_0_bits_uop_fuOpType(i_io_uopWriteback_0_bits_uop_fuOpType),
    .io_uopWriteback_0_bits_uop_vecWen(i_io_uopWriteback_0_bits_uop_vecWen),
    .io_uopWriteback_0_bits_uop_v0Wen(i_io_uopWriteback_0_bits_uop_v0Wen),
    .io_uopWriteback_0_bits_uop_vlWen(i_io_uopWriteback_0_bits_uop_vlWen),
    .io_uopWriteback_0_bits_uop_flushPipe(i_io_uopWriteback_0_bits_uop_flushPipe),
    .io_uopWriteback_0_bits_uop_vpu_vma(i_io_uopWriteback_0_bits_uop_vpu_vma),
    .io_uopWriteback_0_bits_uop_vpu_vta(i_io_uopWriteback_0_bits_uop_vpu_vta),
    .io_uopWriteback_0_bits_uop_vpu_vsew(i_io_uopWriteback_0_bits_uop_vpu_vsew),
    .io_uopWriteback_0_bits_uop_vpu_vlmul(i_io_uopWriteback_0_bits_uop_vpu_vlmul),
    .io_uopWriteback_0_bits_uop_vpu_vm(i_io_uopWriteback_0_bits_uop_vpu_vm),
    .io_uopWriteback_0_bits_uop_vpu_vstart(i_io_uopWriteback_0_bits_uop_vpu_vstart),
    .io_uopWriteback_0_bits_uop_vpu_vuopIdx(i_io_uopWriteback_0_bits_uop_vpu_vuopIdx),
    .io_uopWriteback_0_bits_uop_vpu_vmask(i_io_uopWriteback_0_bits_uop_vpu_vmask),
    .io_uopWriteback_0_bits_uop_vpu_vl(i_io_uopWriteback_0_bits_uop_vpu_vl),
    .io_uopWriteback_0_bits_uop_vpu_nf(i_io_uopWriteback_0_bits_uop_vpu_nf),
    .io_uopWriteback_0_bits_uop_vpu_veew(i_io_uopWriteback_0_bits_uop_vpu_veew),
    .io_uopWriteback_0_bits_uop_pdest(i_io_uopWriteback_0_bits_uop_pdest),
    .io_uopWriteback_0_bits_uop_robIdx_flag(i_io_uopWriteback_0_bits_uop_robIdx_flag),
    .io_uopWriteback_0_bits_uop_robIdx_value(i_io_uopWriteback_0_bits_uop_robIdx_value),
    .io_uopWriteback_0_bits_uop_debugInfo_enqRsTime(i_io_uopWriteback_0_bits_uop_debugInfo_enqRsTime),
    .io_uopWriteback_0_bits_uop_debugInfo_selectTime(i_io_uopWriteback_0_bits_uop_debugInfo_selectTime),
    .io_uopWriteback_0_bits_uop_debugInfo_issueTime(i_io_uopWriteback_0_bits_uop_debugInfo_issueTime),
    .io_uopWriteback_0_bits_uop_replayInst(i_io_uopWriteback_0_bits_uop_replayInst),
    .io_uopWriteback_0_bits_data(i_io_uopWriteback_0_bits_data),
    .io_uopWriteback_0_bits_vdIdx(i_io_uopWriteback_0_bits_vdIdx),
    .io_uopWriteback_0_bits_vdIdxInField(i_io_uopWriteback_0_bits_vdIdxInField),
    .io_toLsq_0_valid(i_io_toLsq_0_valid),
    .io_toLsq_0_bits_robidx_flag(i_io_toLsq_0_bits_robidx_flag),
    .io_toLsq_0_bits_robidx_value(i_io_toLsq_0_bits_robidx_value),
    .io_toLsq_0_bits_uopidx(i_io_toLsq_0_bits_uopidx),
    .io_toLsq_0_bits_vaddr(i_io_toLsq_0_bits_vaddr),
    .io_toLsq_0_bits_vaNeedExt(i_io_toLsq_0_bits_vaNeedExt),
    .io_toLsq_0_bits_gpaddr(i_io_toLsq_0_bits_gpaddr),
    .io_toLsq_0_bits_isForVSnonLeafPTE(i_io_toLsq_0_bits_isForVSnonLeafPTE),
    .io_toLsq_0_bits_feedback_0(i_io_toLsq_0_bits_feedback_0),
    .io_toLsq_0_bits_feedback_1(i_io_toLsq_0_bits_feedback_1),
    .io_toLsq_0_bits_exceptionVec_3(i_io_toLsq_0_bits_exceptionVec_3),
    .io_toLsq_0_bits_exceptionVec_6(i_io_toLsq_0_bits_exceptionVec_6),
    .io_toLsq_0_bits_exceptionVec_7(i_io_toLsq_0_bits_exceptionVec_7),
    .io_toLsq_0_bits_exceptionVec_15(i_io_toLsq_0_bits_exceptionVec_15),
    .io_toLsq_0_bits_exceptionVec_19(i_io_toLsq_0_bits_exceptionVec_19),
    .io_toLsq_0_bits_exceptionVec_23(i_io_toLsq_0_bits_exceptionVec_23),
    .io_feedback_0_valid(i_io_feedback_0_valid),
    .io_feedback_0_bits_hit(i_io_feedback_0_bits_hit),
    .io_feedback_0_bits_sqIdx_flag(i_io_feedback_0_bits_sqIdx_flag),
    .io_feedback_0_bits_sqIdx_value(i_io_feedback_0_bits_sqIdx_value),
    .io_feedback_0_bits_lqIdx_flag(i_io_feedback_0_bits_lqIdx_flag),
    .io_feedback_0_bits_lqIdx_value(i_io_feedback_0_bits_lqIdx_value)
  );

  initial begin
    rst = 1;
    io_redirect_valid = 0;
    io_redirect_bits_robIdx_flag = 0;
    io_redirect_bits_robIdx_value = 0;
    io_redirect_bits_level = 0;
    io_fromPipeline_0_valid = 0;
    io_fromPipeline_0_bits_mBIndex = 0;
    io_fromPipeline_0_bits_hit = 0;
    io_fromPipeline_0_bits_trigger = 0;
    io_fromPipeline_0_bits_exceptionVec_3 = 0;
    io_fromPipeline_0_bits_exceptionVec_6 = 0;
    io_fromPipeline_0_bits_exceptionVec_7 = 0;
    io_fromPipeline_0_bits_exceptionVec_15 = 0;
    io_fromPipeline_0_bits_exceptionVec_19 = 0;
    io_fromPipeline_0_bits_exceptionVec_23 = 0;
    io_fromPipeline_0_bits_hasException = 0;
    io_fromPipeline_0_bits_vaddr = 0;
    io_fromPipeline_0_bits_vaNeedExt = 0;
    io_fromPipeline_0_bits_gpaddr = 0;
    io_fromPipeline_0_bits_isForVSnonLeafPTE = 0;
    io_fromPipeline_0_bits_vstart = 0;
    io_fromPipeline_0_bits_elemIdx = 0;
    io_fromPipeline_0_bits_mask = 0;
    io_fromSplit_0_req_valid = 0;
    io_fromSplit_0_req_bits_mask = 0;
    io_fromSplit_0_req_bits_vaddr = 0;
    io_fromSplit_0_req_bits_flowNum = 0;
    io_fromSplit_0_req_bits_uop_fuOpType = 0;
    io_fromSplit_0_req_bits_uop_vecWen = 0;
    io_fromSplit_0_req_bits_uop_v0Wen = 0;
    io_fromSplit_0_req_bits_uop_vlWen = 0;
    io_fromSplit_0_req_bits_uop_vpu_vma = 0;
    io_fromSplit_0_req_bits_uop_vpu_vta = 0;
    io_fromSplit_0_req_bits_uop_vpu_vsew = 0;
    io_fromSplit_0_req_bits_uop_vpu_vlmul = 0;
    io_fromSplit_0_req_bits_uop_vpu_vm = 0;
    io_fromSplit_0_req_bits_uop_vpu_vuopIdx = 0;
    io_fromSplit_0_req_bits_uop_vpu_vmask = 0;
    io_fromSplit_0_req_bits_uop_vpu_vl = 0;
    io_fromSplit_0_req_bits_uop_vpu_nf = 0;
    io_fromSplit_0_req_bits_uop_vpu_veew = 0;
    io_fromSplit_0_req_bits_uop_uopIdx = 0;
    io_fromSplit_0_req_bits_uop_pdest = 0;
    io_fromSplit_0_req_bits_uop_robIdx_flag = 0;
    io_fromSplit_0_req_bits_uop_robIdx_value = 0;
    io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime = 0;
    io_fromSplit_0_req_bits_uop_debugInfo_selectTime = 0;
    io_fromSplit_0_req_bits_uop_debugInfo_issueTime = 0;
    io_fromSplit_0_req_bits_uop_lqIdx_flag = 0;
    io_fromSplit_0_req_bits_uop_lqIdx_value = 0;
    io_fromSplit_0_req_bits_uop_sqIdx_flag = 0;
    io_fromSplit_0_req_bits_uop_sqIdx_value = 0;
    io_fromSplit_0_req_bits_vlmax = 0;
    io_uopWriteback_0_ready = 0;
    io_fromMisalignBuffer_mbIndex = 0;
    io_fromMisalignBuffer_flush = 0;
    repeat (WARMUP) @(posedge clk);
    rst = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      io_redirect_valid <= $random;
      io_redirect_bits_robIdx_flag <= $random;
      io_redirect_bits_robIdx_value <= $random;
      io_redirect_bits_level <= $random;
      io_fromPipeline_0_valid <= $random;
      io_fromPipeline_0_bits_mBIndex <= $random;
      io_fromPipeline_0_bits_hit <= $random;
      io_fromPipeline_0_bits_trigger <= $random;
      io_fromPipeline_0_bits_exceptionVec_3 <= $random;
      io_fromPipeline_0_bits_exceptionVec_6 <= $random;
      io_fromPipeline_0_bits_exceptionVec_7 <= $random;
      io_fromPipeline_0_bits_exceptionVec_15 <= $random;
      io_fromPipeline_0_bits_exceptionVec_19 <= $random;
      io_fromPipeline_0_bits_exceptionVec_23 <= $random;
      io_fromPipeline_0_bits_hasException <= $random;
      io_fromPipeline_0_bits_vaddr <= {$random, $random};
      io_fromPipeline_0_bits_vaNeedExt <= $random;
      io_fromPipeline_0_bits_gpaddr <= {$random, $random};
      io_fromPipeline_0_bits_isForVSnonLeafPTE <= $random;
      io_fromPipeline_0_bits_vstart <= $random;
      io_fromPipeline_0_bits_elemIdx <= $random;
      io_fromPipeline_0_bits_mask <= $random;
      io_fromSplit_0_req_valid <= $random;
      io_fromSplit_0_req_bits_mask <= $random;
      io_fromSplit_0_req_bits_vaddr <= {$random, $random};
      io_fromSplit_0_req_bits_flowNum <= $random;
      io_fromSplit_0_req_bits_uop_fuOpType <= $random;
      io_fromSplit_0_req_bits_uop_vecWen <= $random;
      io_fromSplit_0_req_bits_uop_v0Wen <= $random;
      io_fromSplit_0_req_bits_uop_vlWen <= $random;
      io_fromSplit_0_req_bits_uop_vpu_vma <= $random;
      io_fromSplit_0_req_bits_uop_vpu_vta <= $random;
      io_fromSplit_0_req_bits_uop_vpu_vsew <= $random;
      io_fromSplit_0_req_bits_uop_vpu_vlmul <= $random;
      io_fromSplit_0_req_bits_uop_vpu_vm <= $random;
      io_fromSplit_0_req_bits_uop_vpu_vuopIdx <= $random;
      io_fromSplit_0_req_bits_uop_vpu_vmask <= {$random, $random, $random, $random};
      io_fromSplit_0_req_bits_uop_vpu_vl <= $random;
      io_fromSplit_0_req_bits_uop_vpu_nf <= $random;
      io_fromSplit_0_req_bits_uop_vpu_veew <= $random;
      io_fromSplit_0_req_bits_uop_uopIdx <= $random;
      io_fromSplit_0_req_bits_uop_pdest <= $random;
      io_fromSplit_0_req_bits_uop_robIdx_flag <= $random;
      io_fromSplit_0_req_bits_uop_robIdx_value <= $random;
      io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime <= {$random, $random};
      io_fromSplit_0_req_bits_uop_debugInfo_selectTime <= {$random, $random};
      io_fromSplit_0_req_bits_uop_debugInfo_issueTime <= {$random, $random};
      io_fromSplit_0_req_bits_uop_lqIdx_flag <= $random;
      io_fromSplit_0_req_bits_uop_lqIdx_value <= $random;
      io_fromSplit_0_req_bits_uop_sqIdx_flag <= $random;
      io_fromSplit_0_req_bits_uop_sqIdx_value <= $random;
      io_fromSplit_0_req_bits_vlmax <= $random;
      io_uopWriteback_0_ready <= $random;
      io_fromMisalignBuffer_mbIndex <= $random;
      io_fromMisalignBuffer_flush <= $random;
      @(posedge clk);
      #1;
      if (cyc > 2) begin
        checks++;
      if (g_io_fromSplit_0_req_ready !== i_io_fromSplit_0_req_ready) begin errors++; if (errors<20) $display("MISMATCH io_fromSplit_0_req_ready @%0d g=%h i=%h", cyc, g_io_fromSplit_0_req_ready, i_io_fromSplit_0_req_ready); end
      if (g_io_fromSplit_0_resp_valid !== i_io_fromSplit_0_resp_valid) begin errors++; if (errors<20) $display("MISMATCH io_fromSplit_0_resp_valid @%0d g=%h i=%h", cyc, g_io_fromSplit_0_resp_valid, i_io_fromSplit_0_resp_valid); end
      if (g_io_fromSplit_0_resp_bits_mBIndex !== i_io_fromSplit_0_resp_bits_mBIndex) begin errors++; if (errors<20) $display("MISMATCH io_fromSplit_0_resp_bits_mBIndex @%0d g=%h i=%h", cyc, g_io_fromSplit_0_resp_bits_mBIndex, i_io_fromSplit_0_resp_bits_mBIndex); end
      if (g_io_uopWriteback_0_valid !== i_io_uopWriteback_0_valid) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_valid @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_valid, i_io_uopWriteback_0_valid); end
      if (g_io_uopWriteback_0_bits_uop_exceptionVec_3 !== i_io_uopWriteback_0_bits_uop_exceptionVec_3) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_exceptionVec_3 @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_exceptionVec_3, i_io_uopWriteback_0_bits_uop_exceptionVec_3); end
      if (g_io_uopWriteback_0_bits_uop_exceptionVec_6 !== i_io_uopWriteback_0_bits_uop_exceptionVec_6) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_exceptionVec_6 @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_exceptionVec_6, i_io_uopWriteback_0_bits_uop_exceptionVec_6); end
      if (g_io_uopWriteback_0_bits_uop_exceptionVec_7 !== i_io_uopWriteback_0_bits_uop_exceptionVec_7) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_exceptionVec_7 @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_exceptionVec_7, i_io_uopWriteback_0_bits_uop_exceptionVec_7); end
      if (g_io_uopWriteback_0_bits_uop_exceptionVec_15 !== i_io_uopWriteback_0_bits_uop_exceptionVec_15) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_exceptionVec_15 @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_exceptionVec_15, i_io_uopWriteback_0_bits_uop_exceptionVec_15); end
      if (g_io_uopWriteback_0_bits_uop_exceptionVec_19 !== i_io_uopWriteback_0_bits_uop_exceptionVec_19) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_exceptionVec_19 @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_exceptionVec_19, i_io_uopWriteback_0_bits_uop_exceptionVec_19); end
      if (g_io_uopWriteback_0_bits_uop_exceptionVec_23 !== i_io_uopWriteback_0_bits_uop_exceptionVec_23) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_exceptionVec_23 @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_exceptionVec_23, i_io_uopWriteback_0_bits_uop_exceptionVec_23); end
      if (g_io_uopWriteback_0_bits_uop_trigger !== i_io_uopWriteback_0_bits_uop_trigger) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_trigger @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_trigger, i_io_uopWriteback_0_bits_uop_trigger); end
      if (g_io_uopWriteback_0_bits_uop_fuOpType !== i_io_uopWriteback_0_bits_uop_fuOpType) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_fuOpType @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_fuOpType, i_io_uopWriteback_0_bits_uop_fuOpType); end
      if (g_io_uopWriteback_0_bits_uop_vecWen !== i_io_uopWriteback_0_bits_uop_vecWen) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_vecWen @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_vecWen, i_io_uopWriteback_0_bits_uop_vecWen); end
      if (g_io_uopWriteback_0_bits_uop_v0Wen !== i_io_uopWriteback_0_bits_uop_v0Wen) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_v0Wen @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_v0Wen, i_io_uopWriteback_0_bits_uop_v0Wen); end
      if (g_io_uopWriteback_0_bits_uop_vlWen !== i_io_uopWriteback_0_bits_uop_vlWen) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_vlWen @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_vlWen, i_io_uopWriteback_0_bits_uop_vlWen); end
      if (g_io_uopWriteback_0_bits_uop_flushPipe !== i_io_uopWriteback_0_bits_uop_flushPipe) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_flushPipe @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_flushPipe, i_io_uopWriteback_0_bits_uop_flushPipe); end
      if (g_io_uopWriteback_0_bits_uop_vpu_vma !== i_io_uopWriteback_0_bits_uop_vpu_vma) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_vpu_vma @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_vpu_vma, i_io_uopWriteback_0_bits_uop_vpu_vma); end
      if (g_io_uopWriteback_0_bits_uop_vpu_vta !== i_io_uopWriteback_0_bits_uop_vpu_vta) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_vpu_vta @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_vpu_vta, i_io_uopWriteback_0_bits_uop_vpu_vta); end
      if (g_io_uopWriteback_0_bits_uop_vpu_vsew !== i_io_uopWriteback_0_bits_uop_vpu_vsew) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_vpu_vsew @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_vpu_vsew, i_io_uopWriteback_0_bits_uop_vpu_vsew); end
      if (g_io_uopWriteback_0_bits_uop_vpu_vlmul !== i_io_uopWriteback_0_bits_uop_vpu_vlmul) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_vpu_vlmul @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_vpu_vlmul, i_io_uopWriteback_0_bits_uop_vpu_vlmul); end
      if (g_io_uopWriteback_0_bits_uop_vpu_vm !== i_io_uopWriteback_0_bits_uop_vpu_vm) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_vpu_vm @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_vpu_vm, i_io_uopWriteback_0_bits_uop_vpu_vm); end
      if (g_io_uopWriteback_0_bits_uop_vpu_vstart !== i_io_uopWriteback_0_bits_uop_vpu_vstart) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_vpu_vstart @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_vpu_vstart, i_io_uopWriteback_0_bits_uop_vpu_vstart); end
      if (g_io_uopWriteback_0_bits_uop_vpu_vuopIdx !== i_io_uopWriteback_0_bits_uop_vpu_vuopIdx) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_vpu_vuopIdx @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_vpu_vuopIdx, i_io_uopWriteback_0_bits_uop_vpu_vuopIdx); end
      if (g_io_uopWriteback_0_bits_uop_vpu_vmask !== i_io_uopWriteback_0_bits_uop_vpu_vmask) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_vpu_vmask @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_vpu_vmask, i_io_uopWriteback_0_bits_uop_vpu_vmask); end
      if (g_io_uopWriteback_0_bits_uop_vpu_vl !== i_io_uopWriteback_0_bits_uop_vpu_vl) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_vpu_vl @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_vpu_vl, i_io_uopWriteback_0_bits_uop_vpu_vl); end
      if (g_io_uopWriteback_0_bits_uop_vpu_nf !== i_io_uopWriteback_0_bits_uop_vpu_nf) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_vpu_nf @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_vpu_nf, i_io_uopWriteback_0_bits_uop_vpu_nf); end
      if (g_io_uopWriteback_0_bits_uop_vpu_veew !== i_io_uopWriteback_0_bits_uop_vpu_veew) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_vpu_veew @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_vpu_veew, i_io_uopWriteback_0_bits_uop_vpu_veew); end
      if (g_io_uopWriteback_0_bits_uop_pdest !== i_io_uopWriteback_0_bits_uop_pdest) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_pdest @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_pdest, i_io_uopWriteback_0_bits_uop_pdest); end
      if (g_io_uopWriteback_0_bits_uop_robIdx_flag !== i_io_uopWriteback_0_bits_uop_robIdx_flag) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_robIdx_flag @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_robIdx_flag, i_io_uopWriteback_0_bits_uop_robIdx_flag); end
      if (g_io_uopWriteback_0_bits_uop_robIdx_value !== i_io_uopWriteback_0_bits_uop_robIdx_value) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_robIdx_value @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_robIdx_value, i_io_uopWriteback_0_bits_uop_robIdx_value); end
      if (g_io_uopWriteback_0_bits_uop_debugInfo_enqRsTime !== i_io_uopWriteback_0_bits_uop_debugInfo_enqRsTime) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_debugInfo_enqRsTime @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_debugInfo_enqRsTime, i_io_uopWriteback_0_bits_uop_debugInfo_enqRsTime); end
      if (g_io_uopWriteback_0_bits_uop_debugInfo_selectTime !== i_io_uopWriteback_0_bits_uop_debugInfo_selectTime) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_debugInfo_selectTime @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_debugInfo_selectTime, i_io_uopWriteback_0_bits_uop_debugInfo_selectTime); end
      if (g_io_uopWriteback_0_bits_uop_debugInfo_issueTime !== i_io_uopWriteback_0_bits_uop_debugInfo_issueTime) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_debugInfo_issueTime @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_debugInfo_issueTime, i_io_uopWriteback_0_bits_uop_debugInfo_issueTime); end
      if (g_io_uopWriteback_0_bits_uop_replayInst !== i_io_uopWriteback_0_bits_uop_replayInst) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_uop_replayInst @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_uop_replayInst, i_io_uopWriteback_0_bits_uop_replayInst); end
      if (g_io_uopWriteback_0_bits_data !== i_io_uopWriteback_0_bits_data) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_data @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_data, i_io_uopWriteback_0_bits_data); end
      if (g_io_uopWriteback_0_bits_vdIdx !== i_io_uopWriteback_0_bits_vdIdx) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_vdIdx @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_vdIdx, i_io_uopWriteback_0_bits_vdIdx); end
      if (g_io_uopWriteback_0_bits_vdIdxInField !== i_io_uopWriteback_0_bits_vdIdxInField) begin errors++; if (errors<20) $display("MISMATCH io_uopWriteback_0_bits_vdIdxInField @%0d g=%h i=%h", cyc, g_io_uopWriteback_0_bits_vdIdxInField, i_io_uopWriteback_0_bits_vdIdxInField); end
      if (g_io_toLsq_0_valid !== i_io_toLsq_0_valid) begin errors++; if (errors<20) $display("MISMATCH io_toLsq_0_valid @%0d g=%h i=%h", cyc, g_io_toLsq_0_valid, i_io_toLsq_0_valid); end
      if (g_io_toLsq_0_bits_robidx_flag !== i_io_toLsq_0_bits_robidx_flag) begin errors++; if (errors<20) $display("MISMATCH io_toLsq_0_bits_robidx_flag @%0d g=%h i=%h", cyc, g_io_toLsq_0_bits_robidx_flag, i_io_toLsq_0_bits_robidx_flag); end
      if (g_io_toLsq_0_bits_robidx_value !== i_io_toLsq_0_bits_robidx_value) begin errors++; if (errors<20) $display("MISMATCH io_toLsq_0_bits_robidx_value @%0d g=%h i=%h", cyc, g_io_toLsq_0_bits_robidx_value, i_io_toLsq_0_bits_robidx_value); end
      if (g_io_toLsq_0_bits_uopidx !== i_io_toLsq_0_bits_uopidx) begin errors++; if (errors<20) $display("MISMATCH io_toLsq_0_bits_uopidx @%0d g=%h i=%h", cyc, g_io_toLsq_0_bits_uopidx, i_io_toLsq_0_bits_uopidx); end
      if (g_io_toLsq_0_bits_vaddr !== i_io_toLsq_0_bits_vaddr) begin errors++; if (errors<20) $display("MISMATCH io_toLsq_0_bits_vaddr @%0d g=%h i=%h", cyc, g_io_toLsq_0_bits_vaddr, i_io_toLsq_0_bits_vaddr); end
      if (g_io_toLsq_0_bits_vaNeedExt !== i_io_toLsq_0_bits_vaNeedExt) begin errors++; if (errors<20) $display("MISMATCH io_toLsq_0_bits_vaNeedExt @%0d g=%h i=%h", cyc, g_io_toLsq_0_bits_vaNeedExt, i_io_toLsq_0_bits_vaNeedExt); end
      if (g_io_toLsq_0_bits_gpaddr !== i_io_toLsq_0_bits_gpaddr) begin errors++; if (errors<20) $display("MISMATCH io_toLsq_0_bits_gpaddr @%0d g=%h i=%h", cyc, g_io_toLsq_0_bits_gpaddr, i_io_toLsq_0_bits_gpaddr); end
      if (g_io_toLsq_0_bits_isForVSnonLeafPTE !== i_io_toLsq_0_bits_isForVSnonLeafPTE) begin errors++; if (errors<20) $display("MISMATCH io_toLsq_0_bits_isForVSnonLeafPTE @%0d g=%h i=%h", cyc, g_io_toLsq_0_bits_isForVSnonLeafPTE, i_io_toLsq_0_bits_isForVSnonLeafPTE); end
      if (g_io_toLsq_0_bits_feedback_0 !== i_io_toLsq_0_bits_feedback_0) begin errors++; if (errors<20) $display("MISMATCH io_toLsq_0_bits_feedback_0 @%0d g=%h i=%h", cyc, g_io_toLsq_0_bits_feedback_0, i_io_toLsq_0_bits_feedback_0); end
      if (g_io_toLsq_0_bits_feedback_1 !== i_io_toLsq_0_bits_feedback_1) begin errors++; if (errors<20) $display("MISMATCH io_toLsq_0_bits_feedback_1 @%0d g=%h i=%h", cyc, g_io_toLsq_0_bits_feedback_1, i_io_toLsq_0_bits_feedback_1); end
      if (g_io_toLsq_0_bits_exceptionVec_3 !== i_io_toLsq_0_bits_exceptionVec_3) begin errors++; if (errors<20) $display("MISMATCH io_toLsq_0_bits_exceptionVec_3 @%0d g=%h i=%h", cyc, g_io_toLsq_0_bits_exceptionVec_3, i_io_toLsq_0_bits_exceptionVec_3); end
      if (g_io_toLsq_0_bits_exceptionVec_6 !== i_io_toLsq_0_bits_exceptionVec_6) begin errors++; if (errors<20) $display("MISMATCH io_toLsq_0_bits_exceptionVec_6 @%0d g=%h i=%h", cyc, g_io_toLsq_0_bits_exceptionVec_6, i_io_toLsq_0_bits_exceptionVec_6); end
      if (g_io_toLsq_0_bits_exceptionVec_7 !== i_io_toLsq_0_bits_exceptionVec_7) begin errors++; if (errors<20) $display("MISMATCH io_toLsq_0_bits_exceptionVec_7 @%0d g=%h i=%h", cyc, g_io_toLsq_0_bits_exceptionVec_7, i_io_toLsq_0_bits_exceptionVec_7); end
      if (g_io_toLsq_0_bits_exceptionVec_15 !== i_io_toLsq_0_bits_exceptionVec_15) begin errors++; if (errors<20) $display("MISMATCH io_toLsq_0_bits_exceptionVec_15 @%0d g=%h i=%h", cyc, g_io_toLsq_0_bits_exceptionVec_15, i_io_toLsq_0_bits_exceptionVec_15); end
      if (g_io_toLsq_0_bits_exceptionVec_19 !== i_io_toLsq_0_bits_exceptionVec_19) begin errors++; if (errors<20) $display("MISMATCH io_toLsq_0_bits_exceptionVec_19 @%0d g=%h i=%h", cyc, g_io_toLsq_0_bits_exceptionVec_19, i_io_toLsq_0_bits_exceptionVec_19); end
      if (g_io_toLsq_0_bits_exceptionVec_23 !== i_io_toLsq_0_bits_exceptionVec_23) begin errors++; if (errors<20) $display("MISMATCH io_toLsq_0_bits_exceptionVec_23 @%0d g=%h i=%h", cyc, g_io_toLsq_0_bits_exceptionVec_23, i_io_toLsq_0_bits_exceptionVec_23); end
      if (g_io_feedback_0_valid !== i_io_feedback_0_valid) begin errors++; if (errors<20) $display("MISMATCH io_feedback_0_valid @%0d g=%h i=%h", cyc, g_io_feedback_0_valid, i_io_feedback_0_valid); end
      if (g_io_feedback_0_bits_hit !== i_io_feedback_0_bits_hit) begin errors++; if (errors<20) $display("MISMATCH io_feedback_0_bits_hit @%0d g=%h i=%h", cyc, g_io_feedback_0_bits_hit, i_io_feedback_0_bits_hit); end
      if (g_io_feedback_0_bits_sqIdx_flag !== i_io_feedback_0_bits_sqIdx_flag) begin errors++; if (errors<20) $display("MISMATCH io_feedback_0_bits_sqIdx_flag @%0d g=%h i=%h", cyc, g_io_feedback_0_bits_sqIdx_flag, i_io_feedback_0_bits_sqIdx_flag); end
      if (g_io_feedback_0_bits_sqIdx_value !== i_io_feedback_0_bits_sqIdx_value) begin errors++; if (errors<20) $display("MISMATCH io_feedback_0_bits_sqIdx_value @%0d g=%h i=%h", cyc, g_io_feedback_0_bits_sqIdx_value, i_io_feedback_0_bits_sqIdx_value); end
      if (g_io_feedback_0_bits_lqIdx_flag !== i_io_feedback_0_bits_lqIdx_flag) begin errors++; if (errors<20) $display("MISMATCH io_feedback_0_bits_lqIdx_flag @%0d g=%h i=%h", cyc, g_io_feedback_0_bits_lqIdx_flag, i_io_feedback_0_bits_lqIdx_flag); end
      if (g_io_feedback_0_bits_lqIdx_value !== i_io_feedback_0_bits_lqIdx_value) begin errors++; if (errors<20) $display("MISMATCH io_feedback_0_bits_lqIdx_value @%0d g=%h i=%h", cyc, g_io_feedback_0_bits_lqIdx_value, i_io_feedback_0_bits_lqIdx_value); end
      end
    end
    if (errors == 0) $display("TEST PASSED checks=%0d errors=0", checks);
    else             $display("TEST FAILED checks=%0d errors=%0d", checks, errors);
    $finish;
  end
endmodule
