// VSMergeBufferImp.sv — 向量 store 合并缓冲（VMergeBuffer 家族的 store 变体，golden 同名 wrapper）
//
// 本变体参数与规模：16 条目 / 1 个入队口 / 1 个流水写回口 / 1 个出队口，toSplit.threshold 在
// 空闲条目 <= 3 时拉高；槽位表是 FreeList_1（16 项 / 1 分配口）；异常集合是 store 的
// exceptionOut {3,6,7,15,19,23}。golden 模块体 8,007 行、191 个端口。
//
// 与 load 变体（VLMergeBufferImp）的差别全部由核参数 IS_VSTORE=1 表达：
//   · 流水写回不打拍：异常/计数写回直接用当拍的 fromPipeline（load 版要多等一拍合并数据）；
//   · 没有数据合并，写回的 data / vdIdx 恒 0，vmask / vl 用入队 uop 自带的；
//   · flow 没命中（hit=0）会累计 replayFlowNum / replayFlowMask，出队时只反馈"部分重放"、
//     不释放条目（load 版流水的 hit 恒 1，这条路径不存在）；
//   · 流水的 sourceType 恒为 1（端口被 firtool 常量传播删掉，wrapper 补常量）。
// 核体见 rtl/memblock/VLMergeBufferImp.sv（xs_VMergeBuffer_core），本文件只有端口展平；
// wrapper 由 scripts/gen_vmergebuf.py 从 G1 golden 端口表生成，勿手改。

// BEGIN GENERATED(wrapper_VSMergeBufferImp)
module VSMergeBufferImp
  import vmergebuffer_pkg::*;
(
  input  logic               clock,
  input  logic               reset,
  input  logic               io_redirect_valid,
  input  logic               io_redirect_bits_robIdx_flag,
  input  logic [7:0]         io_redirect_bits_robIdx_value,
  input  logic               io_redirect_bits_level,
  input  logic               io_fromPipeline_0_valid,
  input  logic [3:0]         io_fromPipeline_0_bits_mBIndex,
  input  logic               io_fromPipeline_0_bits_hit,
  input  logic [3:0]         io_fromPipeline_0_bits_trigger,
  input  logic               io_fromPipeline_0_bits_exceptionVec_3,
  input  logic               io_fromPipeline_0_bits_exceptionVec_6,
  input  logic               io_fromPipeline_0_bits_exceptionVec_7,
  input  logic               io_fromPipeline_0_bits_exceptionVec_15,
  input  logic               io_fromPipeline_0_bits_exceptionVec_19,
  input  logic               io_fromPipeline_0_bits_exceptionVec_23,
  input  logic               io_fromPipeline_0_bits_hasException,
  input  logic [63:0]        io_fromPipeline_0_bits_vaddr,
  input  logic               io_fromPipeline_0_bits_vaNeedExt,
  input  logic [63:0]        io_fromPipeline_0_bits_gpaddr,
  input  logic               io_fromPipeline_0_bits_isForVSnonLeafPTE,
  input  logic [7:0]         io_fromPipeline_0_bits_vstart,
  input  logic [7:0]         io_fromPipeline_0_bits_elemIdx,
  input  logic [15:0]        io_fromPipeline_0_bits_mask,
  input  logic [4:0]         io_fromPipeline_0_bits_splitIndex,
  output logic               io_fromSplit_0_req_ready,
  input  logic               io_fromSplit_0_req_valid,
  input  logic [15:0]        io_fromSplit_0_req_bits_mask,
  input  logic [49:0]        io_fromSplit_0_req_bits_vaddr,
  input  logic [4:0]         io_fromSplit_0_req_bits_flowNum,
  input  logic [8:0]         io_fromSplit_0_req_bits_uop_fuOpType,
  input  logic               io_fromSplit_0_req_bits_uop_vecWen,
  input  logic               io_fromSplit_0_req_bits_uop_v0Wen,
  input  logic               io_fromSplit_0_req_bits_uop_vlWen,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_vill,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_vma,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_vta,
  input  logic [1:0]         io_fromSplit_0_req_bits_uop_vpu_vsew,
  input  logic [2:0]         io_fromSplit_0_req_bits_uop_vpu_vlmul,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_specVill,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_specVma,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_specVta,
  input  logic [1:0]         io_fromSplit_0_req_bits_uop_vpu_specVsew,
  input  logic [2:0]         io_fromSplit_0_req_bits_uop_vpu_specVlmul,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_vm,
  input  logic [2:0]         io_fromSplit_0_req_bits_uop_vpu_frm,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_fpu_isFpToVecInst,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_fpu_isFP32Instr,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_fpu_isFP64Instr,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_fpu_isReduction,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_2,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_4,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_8,
  input  logic [1:0]         io_fromSplit_0_req_bits_uop_vpu_vxrm,
  input  logic [6:0]         io_fromSplit_0_req_bits_uop_vpu_vuopIdx,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_lastUop,
  input  logic [127:0]       io_fromSplit_0_req_bits_uop_vpu_vmask,
  input  logic [7:0]         io_fromSplit_0_req_bits_uop_vpu_vl,
  input  logic [2:0]         io_fromSplit_0_req_bits_uop_vpu_nf,
  input  logic [1:0]         io_fromSplit_0_req_bits_uop_vpu_veew,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_isReverse,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_isExt,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_isNarrow,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_isDstMask,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_isOpMask,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_isMove,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_isDependOldVd,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_isWritePartVd,
  input  logic               io_fromSplit_0_req_bits_uop_vpu_isVleff,
  input  logic [6:0]         io_fromSplit_0_req_bits_uop_uopIdx,
  input  logic [7:0]         io_fromSplit_0_req_bits_uop_pdest,
  input  logic               io_fromSplit_0_req_bits_uop_robIdx_flag,
  input  logic [7:0]         io_fromSplit_0_req_bits_uop_robIdx_value,
  input  logic               io_fromSplit_0_req_bits_uop_debugInfo_eliminatedMove,
  input  logic [63:0]        io_fromSplit_0_req_bits_uop_debugInfo_renameTime,
  input  logic [63:0]        io_fromSplit_0_req_bits_uop_debugInfo_dispatchTime,
  input  logic [63:0]        io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime,
  input  logic [63:0]        io_fromSplit_0_req_bits_uop_debugInfo_selectTime,
  input  logic [63:0]        io_fromSplit_0_req_bits_uop_debugInfo_issueTime,
  input  logic [63:0]        io_fromSplit_0_req_bits_uop_debugInfo_writebackTime,
  input  logic [63:0]        io_fromSplit_0_req_bits_uop_debugInfo_runahead_checkpoint_id,
  input  logic [63:0]        io_fromSplit_0_req_bits_uop_debugInfo_tlbFirstReqTime,
  input  logic [63:0]        io_fromSplit_0_req_bits_uop_debugInfo_tlbRespTime,
  input  logic [55:0]        io_fromSplit_0_req_bits_uop_debug_seqNum_seqNum,
  input  logic [7:0]         io_fromSplit_0_req_bits_uop_debug_seqNum_uopIdx,
  input  logic               io_fromSplit_0_req_bits_uop_lqIdx_flag,
  input  logic [6:0]         io_fromSplit_0_req_bits_uop_lqIdx_value,
  input  logic               io_fromSplit_0_req_bits_uop_sqIdx_flag,
  input  logic [5:0]         io_fromSplit_0_req_bits_uop_sqIdx_value,
  input  logic [7:0]         io_fromSplit_0_req_bits_vlmax,
  output logic               io_fromSplit_0_resp_valid,
  output logic [3:0]         io_fromSplit_0_resp_bits_mBIndex,
  input  logic               io_uopWriteback_0_ready,
  output logic               io_uopWriteback_0_valid,
  output logic               io_uopWriteback_0_bits_uop_exceptionVec_3,
  output logic               io_uopWriteback_0_bits_uop_exceptionVec_6,
  output logic               io_uopWriteback_0_bits_uop_exceptionVec_7,
  output logic               io_uopWriteback_0_bits_uop_exceptionVec_15,
  output logic               io_uopWriteback_0_bits_uop_exceptionVec_19,
  output logic               io_uopWriteback_0_bits_uop_exceptionVec_23,
  output logic [3:0]         io_uopWriteback_0_bits_uop_trigger,
  output logic [8:0]         io_uopWriteback_0_bits_uop_fuOpType,
  output logic               io_uopWriteback_0_bits_uop_vecWen,
  output logic               io_uopWriteback_0_bits_uop_v0Wen,
  output logic               io_uopWriteback_0_bits_uop_vlWen,
  output logic               io_uopWriteback_0_bits_uop_flushPipe,
  output logic               io_uopWriteback_0_bits_uop_vpu_vill,
  output logic               io_uopWriteback_0_bits_uop_vpu_vma,
  output logic               io_uopWriteback_0_bits_uop_vpu_vta,
  output logic [1:0]         io_uopWriteback_0_bits_uop_vpu_vsew,
  output logic [2:0]         io_uopWriteback_0_bits_uop_vpu_vlmul,
  output logic               io_uopWriteback_0_bits_uop_vpu_specVill,
  output logic               io_uopWriteback_0_bits_uop_vpu_specVma,
  output logic               io_uopWriteback_0_bits_uop_vpu_specVta,
  output logic [1:0]         io_uopWriteback_0_bits_uop_vpu_specVsew,
  output logic [2:0]         io_uopWriteback_0_bits_uop_vpu_specVlmul,
  output logic               io_uopWriteback_0_bits_uop_vpu_vm,
  output logic [7:0]         io_uopWriteback_0_bits_uop_vpu_vstart,
  output logic [2:0]         io_uopWriteback_0_bits_uop_vpu_frm,
  output logic               io_uopWriteback_0_bits_uop_vpu_fpu_isFpToVecInst,
  output logic               io_uopWriteback_0_bits_uop_vpu_fpu_isFP32Instr,
  output logic               io_uopWriteback_0_bits_uop_vpu_fpu_isFP64Instr,
  output logic               io_uopWriteback_0_bits_uop_vpu_fpu_isReduction,
  output logic               io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_2,
  output logic               io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_4,
  output logic               io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_8,
  output logic [1:0]         io_uopWriteback_0_bits_uop_vpu_vxrm,
  output logic [6:0]         io_uopWriteback_0_bits_uop_vpu_vuopIdx,
  output logic               io_uopWriteback_0_bits_uop_vpu_lastUop,
  output logic [127:0]       io_uopWriteback_0_bits_uop_vpu_vmask,
  output logic [7:0]         io_uopWriteback_0_bits_uop_vpu_vl,
  output logic [2:0]         io_uopWriteback_0_bits_uop_vpu_nf,
  output logic [1:0]         io_uopWriteback_0_bits_uop_vpu_veew,
  output logic               io_uopWriteback_0_bits_uop_vpu_isReverse,
  output logic               io_uopWriteback_0_bits_uop_vpu_isExt,
  output logic               io_uopWriteback_0_bits_uop_vpu_isNarrow,
  output logic               io_uopWriteback_0_bits_uop_vpu_isDstMask,
  output logic               io_uopWriteback_0_bits_uop_vpu_isOpMask,
  output logic               io_uopWriteback_0_bits_uop_vpu_isMove,
  output logic               io_uopWriteback_0_bits_uop_vpu_isDependOldVd,
  output logic               io_uopWriteback_0_bits_uop_vpu_isWritePartVd,
  output logic               io_uopWriteback_0_bits_uop_vpu_isVleff,
  output logic [7:0]         io_uopWriteback_0_bits_uop_psrc_2,
  output logic [7:0]         io_uopWriteback_0_bits_uop_pdest,
  output logic               io_uopWriteback_0_bits_uop_robIdx_flag,
  output logic [7:0]         io_uopWriteback_0_bits_uop_robIdx_value,
  output logic               io_uopWriteback_0_bits_uop_debugInfo_eliminatedMove,
  output logic [63:0]        io_uopWriteback_0_bits_uop_debugInfo_renameTime,
  output logic [63:0]        io_uopWriteback_0_bits_uop_debugInfo_dispatchTime,
  output logic [63:0]        io_uopWriteback_0_bits_uop_debugInfo_enqRsTime,
  output logic [63:0]        io_uopWriteback_0_bits_uop_debugInfo_selectTime,
  output logic [63:0]        io_uopWriteback_0_bits_uop_debugInfo_issueTime,
  output logic [63:0]        io_uopWriteback_0_bits_uop_debugInfo_writebackTime,
  output logic [63:0]        io_uopWriteback_0_bits_uop_debugInfo_runahead_checkpoint_id,
  output logic [63:0]        io_uopWriteback_0_bits_uop_debugInfo_tlbFirstReqTime,
  output logic [63:0]        io_uopWriteback_0_bits_uop_debugInfo_tlbRespTime,
  output logic [55:0]        io_uopWriteback_0_bits_uop_debug_seqNum_seqNum,
  output logic [7:0]         io_uopWriteback_0_bits_uop_debug_seqNum_uopIdx,
  output logic               io_uopWriteback_0_bits_uop_replayInst,
  output logic [127:0]       io_uopWriteback_0_bits_data,
  output logic [2:0]         io_uopWriteback_0_bits_vdIdx,
  output logic [2:0]         io_uopWriteback_0_bits_vdIdxInField,
  output logic               io_toSplit_threshold,
  output logic               io_toLsq_0_valid,
  output logic               io_toLsq_0_bits_robidx_flag,
  output logic [7:0]         io_toLsq_0_bits_robidx_value,
  output logic [6:0]         io_toLsq_0_bits_uopidx,
  output logic [63:0]        io_toLsq_0_bits_vaddr,
  output logic               io_toLsq_0_bits_vaNeedExt,
  output logic [63:0]        io_toLsq_0_bits_gpaddr,
  output logic               io_toLsq_0_bits_isForVSnonLeafPTE,
  output logic               io_toLsq_0_bits_feedback_0,
  output logic               io_toLsq_0_bits_feedback_1,
  output logic               io_toLsq_0_bits_exceptionVec_3,
  output logic               io_toLsq_0_bits_exceptionVec_6,
  output logic               io_toLsq_0_bits_exceptionVec_7,
  output logic               io_toLsq_0_bits_exceptionVec_15,
  output logic               io_toLsq_0_bits_exceptionVec_19,
  output logic               io_toLsq_0_bits_exceptionVec_23,
  output logic               io_feedback_0_valid,
  output logic               io_feedback_0_bits_robIdx_flag,
  output logic [7:0]         io_feedback_0_bits_robIdx_value,
  output logic               io_feedback_0_bits_hit,
  output logic [3:0]         io_feedback_0_bits_sourceType,
  output logic               io_feedback_0_bits_sqIdx_flag,
  output logic [5:0]         io_feedback_0_bits_sqIdx_value,
  output logic               io_feedback_0_bits_lqIdx_flag,
  output logic [6:0]         io_feedback_0_bits_lqIdx_value,
  output logic               io_feedback_0_bits_isVecPartReplay,
  output logic [15:0]        io_feedback_0_bits_vecReplayMask,
  output logic [3:0]         io_feedback_0_bits_vecReplayMbIdx
);

  mb_redirect_t        redirect;
  mb_enq_req_t         enq_req          [1];
  logic                enq_ready        [1];
  logic                enq_resp_valid   [1];
  logic [3:0]          enq_resp_mBIndex [1];
  mb_pipe_t            pipe             [1];
  logic                wb_ready         [1];
  mb_wb_t              wb               [1];
  logic                threshold;
  mb_lsq_t             lsq              [1];
  mb_fb_t              fb               [1];

  // 输入：先整体清零（端口被 firtool 删掉、上游恒送 0 的字段就停在 0），再逐个接端口
  always_comb begin
    redirect = '0;
    enq_req[0] = '0;
    pipe[0] = '0;
    redirect.valid                                  = io_redirect_valid;
    redirect.robIdx_flag                            = io_redirect_bits_robIdx_flag;
    redirect.robIdx_value                           = io_redirect_bits_robIdx_value;
    redirect.level                                  = io_redirect_bits_level;
    pipe[0].valid                                   = io_fromPipeline_0_valid;
    pipe[0].mBIndex                                 = io_fromPipeline_0_bits_mBIndex;
    pipe[0].hit                                     = io_fromPipeline_0_bits_hit;
    pipe[0].trigger                                 = io_fromPipeline_0_bits_trigger;
    pipe[0].exceptionVec[3]                         = io_fromPipeline_0_bits_exceptionVec_3;
    pipe[0].exceptionVec[6]                         = io_fromPipeline_0_bits_exceptionVec_6;
    pipe[0].exceptionVec[7]                         = io_fromPipeline_0_bits_exceptionVec_7;
    pipe[0].exceptionVec[15]                        = io_fromPipeline_0_bits_exceptionVec_15;
    pipe[0].exceptionVec[19]                        = io_fromPipeline_0_bits_exceptionVec_19;
    pipe[0].exceptionVec[23]                        = io_fromPipeline_0_bits_exceptionVec_23;
    pipe[0].hasException                            = io_fromPipeline_0_bits_hasException;
    pipe[0].vaddr                                   = io_fromPipeline_0_bits_vaddr;
    pipe[0].vaNeedExt                               = io_fromPipeline_0_bits_vaNeedExt;
    pipe[0].gpaddr                                  = io_fromPipeline_0_bits_gpaddr;
    pipe[0].isForVSnonLeafPTE                       = io_fromPipeline_0_bits_isForVSnonLeafPTE;
    pipe[0].vstart                                  = io_fromPipeline_0_bits_vstart;
    pipe[0].elemIdx                                 = io_fromPipeline_0_bits_elemIdx;
    pipe[0].mask                                    = io_fromPipeline_0_bits_mask;
    pipe[0].splitIndex                              = io_fromPipeline_0_bits_splitIndex;
    enq_req[0].valid                                = io_fromSplit_0_req_valid;
    enq_req[0].mask                                 = io_fromSplit_0_req_bits_mask;
    enq_req[0].vaddr                                = io_fromSplit_0_req_bits_vaddr;
    enq_req[0].flowNum                              = io_fromSplit_0_req_bits_flowNum;
    enq_req[0].uop.fuOpType                         = io_fromSplit_0_req_bits_uop_fuOpType;
    enq_req[0].uop.vecWen                           = io_fromSplit_0_req_bits_uop_vecWen;
    enq_req[0].uop.v0Wen                            = io_fromSplit_0_req_bits_uop_v0Wen;
    enq_req[0].uop.vlWen                            = io_fromSplit_0_req_bits_uop_vlWen;
    enq_req[0].uop.vpu_vill                         = io_fromSplit_0_req_bits_uop_vpu_vill;
    enq_req[0].uop.vpu_vma                          = io_fromSplit_0_req_bits_uop_vpu_vma;
    enq_req[0].uop.vpu_vta                          = io_fromSplit_0_req_bits_uop_vpu_vta;
    enq_req[0].uop.vpu_vsew                         = io_fromSplit_0_req_bits_uop_vpu_vsew;
    enq_req[0].uop.vpu_vlmul                        = io_fromSplit_0_req_bits_uop_vpu_vlmul;
    enq_req[0].uop.vpu_specVill                     = io_fromSplit_0_req_bits_uop_vpu_specVill;
    enq_req[0].uop.vpu_specVma                      = io_fromSplit_0_req_bits_uop_vpu_specVma;
    enq_req[0].uop.vpu_specVta                      = io_fromSplit_0_req_bits_uop_vpu_specVta;
    enq_req[0].uop.vpu_specVsew                     = io_fromSplit_0_req_bits_uop_vpu_specVsew;
    enq_req[0].uop.vpu_specVlmul                    = io_fromSplit_0_req_bits_uop_vpu_specVlmul;
    enq_req[0].uop.vpu_vm                           = io_fromSplit_0_req_bits_uop_vpu_vm;
    enq_req[0].uop.vpu_frm                          = io_fromSplit_0_req_bits_uop_vpu_frm;
    enq_req[0].uop.vpu_fpu_isFpToVecInst            = io_fromSplit_0_req_bits_uop_vpu_fpu_isFpToVecInst;
    enq_req[0].uop.vpu_fpu_isFP32Instr              = io_fromSplit_0_req_bits_uop_vpu_fpu_isFP32Instr;
    enq_req[0].uop.vpu_fpu_isFP64Instr              = io_fromSplit_0_req_bits_uop_vpu_fpu_isFP64Instr;
    enq_req[0].uop.vpu_fpu_isReduction              = io_fromSplit_0_req_bits_uop_vpu_fpu_isReduction;
    enq_req[0].uop.vpu_fpu_isFoldTo1_2              = io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_2;
    enq_req[0].uop.vpu_fpu_isFoldTo1_4              = io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_4;
    enq_req[0].uop.vpu_fpu_isFoldTo1_8              = io_fromSplit_0_req_bits_uop_vpu_fpu_isFoldTo1_8;
    enq_req[0].uop.vpu_vxrm                         = io_fromSplit_0_req_bits_uop_vpu_vxrm;
    enq_req[0].uop.vpu_vuopIdx                      = io_fromSplit_0_req_bits_uop_vpu_vuopIdx;
    enq_req[0].uop.vpu_lastUop                      = io_fromSplit_0_req_bits_uop_vpu_lastUop;
    enq_req[0].uop.vpu_vmask                        = io_fromSplit_0_req_bits_uop_vpu_vmask;
    enq_req[0].uop.vpu_vl                           = io_fromSplit_0_req_bits_uop_vpu_vl;
    enq_req[0].uop.vpu_nf                           = io_fromSplit_0_req_bits_uop_vpu_nf;
    enq_req[0].uop.vpu_veew                         = io_fromSplit_0_req_bits_uop_vpu_veew;
    enq_req[0].uop.vpu_isReverse                    = io_fromSplit_0_req_bits_uop_vpu_isReverse;
    enq_req[0].uop.vpu_isExt                        = io_fromSplit_0_req_bits_uop_vpu_isExt;
    enq_req[0].uop.vpu_isNarrow                     = io_fromSplit_0_req_bits_uop_vpu_isNarrow;
    enq_req[0].uop.vpu_isDstMask                    = io_fromSplit_0_req_bits_uop_vpu_isDstMask;
    enq_req[0].uop.vpu_isOpMask                     = io_fromSplit_0_req_bits_uop_vpu_isOpMask;
    enq_req[0].uop.vpu_isMove                       = io_fromSplit_0_req_bits_uop_vpu_isMove;
    enq_req[0].uop.vpu_isDependOldVd                = io_fromSplit_0_req_bits_uop_vpu_isDependOldVd;
    enq_req[0].uop.vpu_isWritePartVd                = io_fromSplit_0_req_bits_uop_vpu_isWritePartVd;
    enq_req[0].uop.vpu_isVleff                      = io_fromSplit_0_req_bits_uop_vpu_isVleff;
    enq_req[0].uop.uopIdx                           = io_fromSplit_0_req_bits_uop_uopIdx;
    enq_req[0].uop.pdest                            = io_fromSplit_0_req_bits_uop_pdest;
    enq_req[0].uop.robIdx_flag                      = io_fromSplit_0_req_bits_uop_robIdx_flag;
    enq_req[0].uop.robIdx_value                     = io_fromSplit_0_req_bits_uop_robIdx_value;
    enq_req[0].uop.debugInfo_eliminatedMove         = io_fromSplit_0_req_bits_uop_debugInfo_eliminatedMove;
    enq_req[0].uop.debugInfo_renameTime             = io_fromSplit_0_req_bits_uop_debugInfo_renameTime;
    enq_req[0].uop.debugInfo_dispatchTime           = io_fromSplit_0_req_bits_uop_debugInfo_dispatchTime;
    enq_req[0].uop.debugInfo_enqRsTime              = io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime;
    enq_req[0].uop.debugInfo_selectTime             = io_fromSplit_0_req_bits_uop_debugInfo_selectTime;
    enq_req[0].uop.debugInfo_issueTime              = io_fromSplit_0_req_bits_uop_debugInfo_issueTime;
    enq_req[0].uop.debugInfo_writebackTime          = io_fromSplit_0_req_bits_uop_debugInfo_writebackTime;
    enq_req[0].uop.debugInfo_runahead_checkpoint_id = io_fromSplit_0_req_bits_uop_debugInfo_runahead_checkpoint_id;
    enq_req[0].uop.debugInfo_tlbFirstReqTime        = io_fromSplit_0_req_bits_uop_debugInfo_tlbFirstReqTime;
    enq_req[0].uop.debugInfo_tlbRespTime            = io_fromSplit_0_req_bits_uop_debugInfo_tlbRespTime;
    enq_req[0].uop.debug_seqNum_seqNum              = io_fromSplit_0_req_bits_uop_debug_seqNum_seqNum;
    enq_req[0].uop.debug_seqNum_uopIdx              = io_fromSplit_0_req_bits_uop_debug_seqNum_uopIdx;
    enq_req[0].uop.lqIdx_flag                       = io_fromSplit_0_req_bits_uop_lqIdx_flag;
    enq_req[0].uop.lqIdx_value                      = io_fromSplit_0_req_bits_uop_lqIdx_value;
    enq_req[0].uop.sqIdx_flag                       = io_fromSplit_0_req_bits_uop_sqIdx_flag;
    enq_req[0].uop.sqIdx_value                      = io_fromSplit_0_req_bits_uop_sqIdx_value;
    enq_req[0].vlmax                                = io_fromSplit_0_req_bits_vlmax;
    wb_ready[0]                                     = io_uopWriteback_0_ready;
    pipe[0].sourceType = 3'h1;  // 无端口：上游恒送 3'h1
    pipe[0].flushState = 1'b0;  // 无端口：上游恒送 1'b0
  end

  xs_VMergeBuffer_core #(
    .IS_VSTORE (1'b1),
    .ENQ_W     (1),
    .PIPE_W    (1),
    .DEQ_W     (1),
    .THRESHOLD (3),
    .EXC_SEL   (VSTU_EXC_SEL)
  ) u_core (
    .clock                     (clock),
    .reset                     (reset),
    .io_redirect               (redirect),
    .io_fromSplit_req          (enq_req),
    .io_fromSplit_req_ready    (enq_ready),
    .io_fromSplit_resp_valid   (enq_resp_valid),
    .io_fromSplit_resp_mBIndex (enq_resp_mBIndex),
    .io_fromPipeline           (pipe),
    .io_uopWriteback_ready     (wb_ready),
    .io_uopWriteback           (wb),
    .io_toSplit_threshold      (threshold),
    .io_toLsq                  (lsq),
    .io_feedback               (fb)
  );

  // 输出
  assign io_fromSplit_0_req_ready                                    = enq_ready[0];
  assign io_fromSplit_0_resp_valid                                   = enq_resp_valid[0];
  assign io_fromSplit_0_resp_bits_mBIndex                            = enq_resp_mBIndex[0];
  assign io_uopWriteback_0_valid                                     = wb[0].valid;
  assign io_uopWriteback_0_bits_uop_exceptionVec_3                   = wb[0].uop.exceptionVec[3];
  assign io_uopWriteback_0_bits_uop_exceptionVec_6                   = wb[0].uop.exceptionVec[6];
  assign io_uopWriteback_0_bits_uop_exceptionVec_7                   = wb[0].uop.exceptionVec[7];
  assign io_uopWriteback_0_bits_uop_exceptionVec_15                  = wb[0].uop.exceptionVec[15];
  assign io_uopWriteback_0_bits_uop_exceptionVec_19                  = wb[0].uop.exceptionVec[19];
  assign io_uopWriteback_0_bits_uop_exceptionVec_23                  = wb[0].uop.exceptionVec[23];
  assign io_uopWriteback_0_bits_uop_trigger                          = wb[0].uop.trigger;
  assign io_uopWriteback_0_bits_uop_fuOpType                         = wb[0].uop.fuOpType;
  assign io_uopWriteback_0_bits_uop_vecWen                           = wb[0].uop.vecWen;
  assign io_uopWriteback_0_bits_uop_v0Wen                            = wb[0].uop.v0Wen;
  assign io_uopWriteback_0_bits_uop_vlWen                            = wb[0].uop.vlWen;
  assign io_uopWriteback_0_bits_uop_flushPipe                        = wb[0].uop.flushPipe;
  assign io_uopWriteback_0_bits_uop_vpu_vill                         = wb[0].uop.vpu_vill;
  assign io_uopWriteback_0_bits_uop_vpu_vma                          = wb[0].uop.vpu_vma;
  assign io_uopWriteback_0_bits_uop_vpu_vta                          = wb[0].uop.vpu_vta;
  assign io_uopWriteback_0_bits_uop_vpu_vsew                         = wb[0].uop.vpu_vsew;
  assign io_uopWriteback_0_bits_uop_vpu_vlmul                        = wb[0].uop.vpu_vlmul;
  assign io_uopWriteback_0_bits_uop_vpu_specVill                     = wb[0].uop.vpu_specVill;
  assign io_uopWriteback_0_bits_uop_vpu_specVma                      = wb[0].uop.vpu_specVma;
  assign io_uopWriteback_0_bits_uop_vpu_specVta                      = wb[0].uop.vpu_specVta;
  assign io_uopWriteback_0_bits_uop_vpu_specVsew                     = wb[0].uop.vpu_specVsew;
  assign io_uopWriteback_0_bits_uop_vpu_specVlmul                    = wb[0].uop.vpu_specVlmul;
  assign io_uopWriteback_0_bits_uop_vpu_vm                           = wb[0].uop.vpu_vm;
  assign io_uopWriteback_0_bits_uop_vpu_vstart                       = wb[0].uop.vpu_vstart;
  assign io_uopWriteback_0_bits_uop_vpu_frm                          = wb[0].uop.vpu_frm;
  assign io_uopWriteback_0_bits_uop_vpu_fpu_isFpToVecInst            = wb[0].uop.vpu_fpu_isFpToVecInst;
  assign io_uopWriteback_0_bits_uop_vpu_fpu_isFP32Instr              = wb[0].uop.vpu_fpu_isFP32Instr;
  assign io_uopWriteback_0_bits_uop_vpu_fpu_isFP64Instr              = wb[0].uop.vpu_fpu_isFP64Instr;
  assign io_uopWriteback_0_bits_uop_vpu_fpu_isReduction              = wb[0].uop.vpu_fpu_isReduction;
  assign io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_2              = wb[0].uop.vpu_fpu_isFoldTo1_2;
  assign io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_4              = wb[0].uop.vpu_fpu_isFoldTo1_4;
  assign io_uopWriteback_0_bits_uop_vpu_fpu_isFoldTo1_8              = wb[0].uop.vpu_fpu_isFoldTo1_8;
  assign io_uopWriteback_0_bits_uop_vpu_vxrm                         = wb[0].uop.vpu_vxrm;
  assign io_uopWriteback_0_bits_uop_vpu_vuopIdx                      = wb[0].uop.vpu_vuopIdx;
  assign io_uopWriteback_0_bits_uop_vpu_lastUop                      = wb[0].uop.vpu_lastUop;
  assign io_uopWriteback_0_bits_uop_vpu_vmask                        = wb[0].uop.vpu_vmask;
  assign io_uopWriteback_0_bits_uop_vpu_vl                           = wb[0].uop.vpu_vl;
  assign io_uopWriteback_0_bits_uop_vpu_nf                           = wb[0].uop.vpu_nf;
  assign io_uopWriteback_0_bits_uop_vpu_veew                         = wb[0].uop.vpu_veew;
  assign io_uopWriteback_0_bits_uop_vpu_isReverse                    = wb[0].uop.vpu_isReverse;
  assign io_uopWriteback_0_bits_uop_vpu_isExt                        = wb[0].uop.vpu_isExt;
  assign io_uopWriteback_0_bits_uop_vpu_isNarrow                     = wb[0].uop.vpu_isNarrow;
  assign io_uopWriteback_0_bits_uop_vpu_isDstMask                    = wb[0].uop.vpu_isDstMask;
  assign io_uopWriteback_0_bits_uop_vpu_isOpMask                     = wb[0].uop.vpu_isOpMask;
  assign io_uopWriteback_0_bits_uop_vpu_isMove                       = wb[0].uop.vpu_isMove;
  assign io_uopWriteback_0_bits_uop_vpu_isDependOldVd                = wb[0].uop.vpu_isDependOldVd;
  assign io_uopWriteback_0_bits_uop_vpu_isWritePartVd                = wb[0].uop.vpu_isWritePartVd;
  assign io_uopWriteback_0_bits_uop_vpu_isVleff                      = wb[0].uop.vpu_isVleff;
  assign io_uopWriteback_0_bits_uop_psrc_2                           = wb[0].uop.psrc_2;
  assign io_uopWriteback_0_bits_uop_pdest                            = wb[0].uop.pdest;
  assign io_uopWriteback_0_bits_uop_robIdx_flag                      = wb[0].uop.robIdx_flag;
  assign io_uopWriteback_0_bits_uop_robIdx_value                     = wb[0].uop.robIdx_value;
  assign io_uopWriteback_0_bits_uop_debugInfo_eliminatedMove         = wb[0].uop.debugInfo_eliminatedMove;
  assign io_uopWriteback_0_bits_uop_debugInfo_renameTime             = wb[0].uop.debugInfo_renameTime;
  assign io_uopWriteback_0_bits_uop_debugInfo_dispatchTime           = wb[0].uop.debugInfo_dispatchTime;
  assign io_uopWriteback_0_bits_uop_debugInfo_enqRsTime              = wb[0].uop.debugInfo_enqRsTime;
  assign io_uopWriteback_0_bits_uop_debugInfo_selectTime             = wb[0].uop.debugInfo_selectTime;
  assign io_uopWriteback_0_bits_uop_debugInfo_issueTime              = wb[0].uop.debugInfo_issueTime;
  assign io_uopWriteback_0_bits_uop_debugInfo_writebackTime          = wb[0].uop.debugInfo_writebackTime;
  assign io_uopWriteback_0_bits_uop_debugInfo_runahead_checkpoint_id = wb[0].uop.debugInfo_runahead_checkpoint_id;
  assign io_uopWriteback_0_bits_uop_debugInfo_tlbFirstReqTime        = wb[0].uop.debugInfo_tlbFirstReqTime;
  assign io_uopWriteback_0_bits_uop_debugInfo_tlbRespTime            = wb[0].uop.debugInfo_tlbRespTime;
  assign io_uopWriteback_0_bits_uop_debug_seqNum_seqNum              = wb[0].uop.debug_seqNum_seqNum;
  assign io_uopWriteback_0_bits_uop_debug_seqNum_uopIdx              = wb[0].uop.debug_seqNum_uopIdx;
  assign io_uopWriteback_0_bits_uop_replayInst                       = wb[0].uop.replayInst;
  assign io_uopWriteback_0_bits_data                                 = wb[0].data;
  assign io_uopWriteback_0_bits_vdIdx                                = wb[0].vdIdx;
  assign io_uopWriteback_0_bits_vdIdxInField                         = wb[0].vdIdxInField;
  assign io_toSplit_threshold                                        = threshold;
  assign io_toLsq_0_valid                                            = lsq[0].valid;
  assign io_toLsq_0_bits_robidx_flag                                 = lsq[0].robidx_flag;
  assign io_toLsq_0_bits_robidx_value                                = lsq[0].robidx_value;
  assign io_toLsq_0_bits_uopidx                                      = lsq[0].uopidx;
  assign io_toLsq_0_bits_vaddr                                       = lsq[0].vaddr;
  assign io_toLsq_0_bits_vaNeedExt                                   = lsq[0].vaNeedExt;
  assign io_toLsq_0_bits_gpaddr                                      = lsq[0].gpaddr;
  assign io_toLsq_0_bits_isForVSnonLeafPTE                           = lsq[0].isForVSnonLeafPTE;
  assign io_toLsq_0_bits_feedback_0                                  = lsq[0].feedback[0];
  assign io_toLsq_0_bits_feedback_1                                  = lsq[0].feedback[1];
  assign io_toLsq_0_bits_exceptionVec_3                              = lsq[0].exceptionVec[3];
  assign io_toLsq_0_bits_exceptionVec_6                              = lsq[0].exceptionVec[6];
  assign io_toLsq_0_bits_exceptionVec_7                              = lsq[0].exceptionVec[7];
  assign io_toLsq_0_bits_exceptionVec_15                             = lsq[0].exceptionVec[15];
  assign io_toLsq_0_bits_exceptionVec_19                             = lsq[0].exceptionVec[19];
  assign io_toLsq_0_bits_exceptionVec_23                             = lsq[0].exceptionVec[23];
  assign io_feedback_0_valid                                         = fb[0].valid;
  assign io_feedback_0_bits_robIdx_flag                              = fb[0].robIdx_flag;
  assign io_feedback_0_bits_robIdx_value                             = fb[0].robIdx_value;
  assign io_feedback_0_bits_hit                                      = fb[0].hit;
  assign io_feedback_0_bits_sourceType                               = fb[0].sourceType;
  assign io_feedback_0_bits_sqIdx_flag                               = fb[0].sqIdx_flag;
  assign io_feedback_0_bits_sqIdx_value                              = fb[0].sqIdx_value;
  assign io_feedback_0_bits_lqIdx_flag                               = fb[0].lqIdx_flag;
  assign io_feedback_0_bits_lqIdx_value                              = fb[0].lqIdx_value;
  assign io_feedback_0_bits_isVecPartReplay                          = fb[0].isVecPartReplay;
  assign io_feedback_0_bits_vecReplayMask                            = fb[0].vecReplayMask;
  assign io_feedback_0_bits_vecReplayMbIdx                           = fb[0].vecReplayMbIdx;

endmodule
// END GENERATED
