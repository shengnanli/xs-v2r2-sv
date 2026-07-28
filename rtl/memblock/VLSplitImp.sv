// xs_VLSplitImp_core —— 向量 load split 装配壳(纯组合 glue)。
// 手写可读重写, 结构 bug-for-bug 对齐 golden VLSplitImp.sv。
// 例化 3 个 golden 子模块(两侧同 elaborate 黑盒, FM 只验本层 glue):
//   splitPipeline(VLSplitPipelineImp) → VSSplitSkidBuffer(skidBufferConnect)
//   → splitBuffer(VLSplitBufferImp)
// 顶层 glue: io_in_ready(带 lqIdx threshold 门控) /
//   io_out_valid(splitBuffer.out.valid) / skidBuffer.io_flush(流动 uop robIdx 判重定向)。
module xs_VLSplitImp_core
  import xs_vlsplitimp_pkg::*;
(
  input           clock,
  input           reset,
  input           io_redirect_valid,
  input           io_redirect_bits_robIdx_flag,
  input [7:0]     io_redirect_bits_robIdx_value,
  input           io_redirect_bits_level,
  output           io_in_ready,
  input           io_in_valid,
  input           io_in_bits_uop_ftqPtr_flag,
  input [5:0]     io_in_bits_uop_ftqPtr_value,
  input [3:0]     io_in_bits_uop_ftqOffset,
  input [8:0]     io_in_bits_uop_fuOpType,
  input           io_in_bits_uop_vecWen,
  input           io_in_bits_uop_v0Wen,
  input           io_in_bits_uop_vlWen,
  input           io_in_bits_uop_vpu_vma,
  input           io_in_bits_uop_vpu_vta,
  input [1:0]     io_in_bits_uop_vpu_vsew,
  input [2:0]     io_in_bits_uop_vpu_vlmul,
  input           io_in_bits_uop_vpu_vm,
  input [7:0]     io_in_bits_uop_vpu_vstart,
  input [6:0]     io_in_bits_uop_vpu_vuopIdx,
  input [2:0]     io_in_bits_uop_vpu_nf,
  input [1:0]     io_in_bits_uop_vpu_veew,
  input [7:0]     io_in_bits_uop_pdest,
  input           io_in_bits_uop_robIdx_flag,
  input [7:0]     io_in_bits_uop_robIdx_value,
  input [63:0]    io_in_bits_uop_debugInfo_enqRsTime,
  input [63:0]    io_in_bits_uop_debugInfo_selectTime,
  input [63:0]    io_in_bits_uop_debugInfo_issueTime,
  input           io_in_bits_uop_lqIdx_flag,
  input [6:0]     io_in_bits_uop_lqIdx_value,
  input           io_in_bits_uop_sqIdx_flag,
  input [5:0]     io_in_bits_uop_sqIdx_value,
  input [127:0]   io_in_bits_src_0,
  input [127:0]   io_in_bits_src_1,
  input [127:0]   io_in_bits_src_2,
  input [127:0]   io_in_bits_src_3,
  input [127:0]   io_in_bits_src_4,
  input [4:0]     io_in_bits_flowNum,
  input           io_toMergeBuffer_req_ready,
  output           io_toMergeBuffer_req_valid,
  output [15:0]    io_toMergeBuffer_req_bits_mask,
  output [49:0]    io_toMergeBuffer_req_bits_vaddr,
  output [4:0]     io_toMergeBuffer_req_bits_flowNum,
  output [8:0]     io_toMergeBuffer_req_bits_uop_fuOpType,
  output           io_toMergeBuffer_req_bits_uop_vecWen,
  output           io_toMergeBuffer_req_bits_uop_v0Wen,
  output           io_toMergeBuffer_req_bits_uop_vlWen,
  output           io_toMergeBuffer_req_bits_uop_vpu_vma,
  output           io_toMergeBuffer_req_bits_uop_vpu_vta,
  output [1:0]     io_toMergeBuffer_req_bits_uop_vpu_vsew,
  output [2:0]     io_toMergeBuffer_req_bits_uop_vpu_vlmul,
  output           io_toMergeBuffer_req_bits_uop_vpu_vm,
  output [6:0]     io_toMergeBuffer_req_bits_uop_vpu_vuopIdx,
  output [7:0]     io_toMergeBuffer_req_bits_uop_vpu_vl,
  output [2:0]     io_toMergeBuffer_req_bits_uop_vpu_nf,
  output [1:0]     io_toMergeBuffer_req_bits_uop_vpu_veew,
  output [6:0]     io_toMergeBuffer_req_bits_uop_uopIdx,
  output [7:0]     io_toMergeBuffer_req_bits_uop_pdest,
  output           io_toMergeBuffer_req_bits_uop_robIdx_flag,
  output [7:0]     io_toMergeBuffer_req_bits_uop_robIdx_value,
  output [63:0]    io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime,
  output [63:0]    io_toMergeBuffer_req_bits_uop_debugInfo_selectTime,
  output [63:0]    io_toMergeBuffer_req_bits_uop_debugInfo_issueTime,
  output [127:0]   io_toMergeBuffer_req_bits_data,
  output [2:0]     io_toMergeBuffer_req_bits_vdIdx,
  output           io_toMergeBuffer_req_bits_fof,
  output [7:0]     io_toMergeBuffer_req_bits_vlmax,
  input           io_toMergeBuffer_resp_valid,
  input [3:0]     io_toMergeBuffer_resp_bits_mBIndex,
  input           io_out_ready,
  output           io_out_valid,
  output [63:0]    io_out_bits_vaddr,
  output [49:0]    io_out_bits_basevaddr,
  output [15:0]    io_out_bits_mask,
  output [3:0]     io_out_bits_reg_offset,
  output [2:0]     io_out_bits_alignedType,
  output           io_out_bits_vecActive,
  output           io_out_bits_uop_exceptionVec_4,
  output           io_out_bits_uop_exceptionVec_5,
  output           io_out_bits_uop_exceptionVec_13,
  output           io_out_bits_uop_exceptionVec_19,
  output           io_out_bits_uop_exceptionVec_21,
  output [3:0]     io_out_bits_uop_trigger,
  output           io_out_bits_uop_preDecodeInfo_isRVC,
  output           io_out_bits_uop_ftqPtr_flag,
  output [5:0]     io_out_bits_uop_ftqPtr_value,
  output [3:0]     io_out_bits_uop_ftqOffset,
  output [8:0]     io_out_bits_uop_fuOpType,
  output           io_out_bits_uop_rfWen,
  output           io_out_bits_uop_fpWen,
  output [7:0]     io_out_bits_uop_vpu_vstart,
  output [1:0]     io_out_bits_uop_vpu_veew,
  output [6:0]     io_out_bits_uop_uopIdx,
  output [7:0]     io_out_bits_uop_pdest,
  output           io_out_bits_uop_robIdx_flag,
  output [7:0]     io_out_bits_uop_robIdx_value,
  output [63:0]    io_out_bits_uop_debugInfo_enqRsTime,
  output [63:0]    io_out_bits_uop_debugInfo_selectTime,
  output [63:0]    io_out_bits_uop_debugInfo_issueTime,
  output           io_out_bits_uop_storeSetHit,
  output           io_out_bits_uop_waitForRobIdx_flag,
  output [7:0]     io_out_bits_uop_waitForRobIdx_value,
  output           io_out_bits_uop_loadWaitBit,
  output           io_out_bits_uop_loadWaitStrict,
  output           io_out_bits_uop_lqIdx_flag,
  output [6:0]     io_out_bits_uop_lqIdx_value,
  output           io_out_bits_uop_sqIdx_flag,
  output [5:0]     io_out_bits_uop_sqIdx_value,
  output [3:0]     io_out_bits_mBIndex,
  output [7:0]     io_out_bits_elemIdx,
  output [7:0]     io_out_bits_elemIdxInsideVd,
  input           io_threshold_valid,
  input           io_threshold_bits_flag,
  input [6:0]     io_threshold_bits_value
);

  wire         _VSSplitSkidBuffer_io_in_ready;
  wire         _VSSplitSkidBuffer_io_out_valid;
  wire [15:0]  _VSSplitSkidBuffer_io_out_bits_flowMask;
  wire [63:0]  _VSSplitSkidBuffer_io_out_bits_baseAddr;
  wire [63:0]  _VSSplitSkidBuffer_io_out_bits_uopAddr;
  wire [127:0] _VSSplitSkidBuffer_io_out_bits_stride;
  wire [4:0]   _VSSplitSkidBuffer_io_out_bits_flowNum;
  wire [1:0]   _VSSplitSkidBuffer_io_out_bits_eew;
  wire [2:0]   _VSSplitSkidBuffer_io_out_bits_sew;
  wire [2:0]   _VSSplitSkidBuffer_io_out_bits_emul;
  wire [2:0]   _VSSplitSkidBuffer_io_out_bits_lmul;
  wire [2:0]   _VSSplitSkidBuffer_io_out_bits_instType;
  wire [4:0]   _VSSplitSkidBuffer_io_out_bits_indexedSplitOffset;
  wire         _VSSplitSkidBuffer_io_out_bits_uop_exceptionVec_5;
  wire         _VSSplitSkidBuffer_io_out_bits_uop_exceptionVec_13;
  wire         _VSSplitSkidBuffer_io_out_bits_uop_exceptionVec_19;
  wire         _VSSplitSkidBuffer_io_out_bits_uop_exceptionVec_21;
  wire [3:0]   _VSSplitSkidBuffer_io_out_bits_uop_trigger;
  wire         _VSSplitSkidBuffer_io_out_bits_uop_preDecodeInfo_isRVC;
  wire         _VSSplitSkidBuffer_io_out_bits_uop_ftqPtr_flag;
  wire [5:0]   _VSSplitSkidBuffer_io_out_bits_uop_ftqPtr_value;
  wire [3:0]   _VSSplitSkidBuffer_io_out_bits_uop_ftqOffset;
  wire [8:0]   _VSSplitSkidBuffer_io_out_bits_uop_fuOpType;
  wire         _VSSplitSkidBuffer_io_out_bits_uop_rfWen;
  wire         _VSSplitSkidBuffer_io_out_bits_uop_fpWen;
  wire [7:0]   _VSSplitSkidBuffer_io_out_bits_uop_vpu_vstart;
  wire [6:0]   _VSSplitSkidBuffer_io_out_bits_uop_vpu_vuopIdx;
  wire [1:0]   _VSSplitSkidBuffer_io_out_bits_uop_vpu_veew;
  wire [6:0]   _VSSplitSkidBuffer_io_out_bits_uop_uopIdx;
  wire [7:0]   _VSSplitSkidBuffer_io_out_bits_uop_pdest;
  wire         _VSSplitSkidBuffer_io_out_bits_uop_robIdx_flag;
  wire [7:0]   _VSSplitSkidBuffer_io_out_bits_uop_robIdx_value;
  wire [63:0]  _VSSplitSkidBuffer_io_out_bits_uop_debugInfo_enqRsTime;
  wire [63:0]  _VSSplitSkidBuffer_io_out_bits_uop_debugInfo_selectTime;
  wire [63:0]  _VSSplitSkidBuffer_io_out_bits_uop_debugInfo_issueTime;
  wire         _VSSplitSkidBuffer_io_out_bits_uop_storeSetHit;
  wire         _VSSplitSkidBuffer_io_out_bits_uop_waitForRobIdx_flag;
  wire [7:0]   _VSSplitSkidBuffer_io_out_bits_uop_waitForRobIdx_value;
  wire         _VSSplitSkidBuffer_io_out_bits_uop_loadWaitBit;
  wire         _VSSplitSkidBuffer_io_out_bits_uop_loadWaitStrict;
  wire         _VSSplitSkidBuffer_io_out_bits_uop_lqIdx_flag;
  wire [6:0]   _VSSplitSkidBuffer_io_out_bits_uop_lqIdx_value;
  wire         _VSSplitSkidBuffer_io_out_bits_uop_sqIdx_flag;
  wire [5:0]   _VSSplitSkidBuffer_io_out_bits_uop_sqIdx_value;
  wire         _VSSplitSkidBuffer_io_out_bits_preIsSplit;
  wire [3:0]   _VSSplitSkidBuffer_io_out_bits_mBIndex;
  wire [2:0]   _VSSplitSkidBuffer_io_out_bits_alignedType;
  wire [7:0]   _VSSplitSkidBuffer_io_out_bits_indexVlMaxInVd;
  wire [3:0]   _VSSplitSkidBuffer_io_out_bits_usLowBitsAddr;
  wire         _VSSplitSkidBuffer_io_out_bits_usAligned128;
  wire [31:0]  _VSSplitSkidBuffer_io_out_bits_usMask;
  wire         _splitBuffer_io_in_ready;
  wire         _splitBuffer_io_out_valid;
  wire         _splitPipeline_io_in_ready;
  wire         _splitPipeline_io_out_valid;
  wire [15:0]  _splitPipeline_io_out_bits_flowMask;
  wire [127:0] _splitPipeline_io_out_bits_data;
  wire [63:0]  _splitPipeline_io_out_bits_baseAddr;
  wire [63:0]  _splitPipeline_io_out_bits_uopAddr;
  wire [127:0] _splitPipeline_io_out_bits_stride;
  wire [4:0]   _splitPipeline_io_out_bits_flowNum;
  wire [1:0]   _splitPipeline_io_out_bits_eew;
  wire [2:0]   _splitPipeline_io_out_bits_sew;
  wire [2:0]   _splitPipeline_io_out_bits_emul;
  wire [2:0]   _splitPipeline_io_out_bits_lmul;
  wire [2:0]   _splitPipeline_io_out_bits_instType;
  wire [4:0]   _splitPipeline_io_out_bits_indexedSplitOffset;
  wire         _splitPipeline_io_out_bits_uop_ftqPtr_flag;
  wire [5:0]   _splitPipeline_io_out_bits_uop_ftqPtr_value;
  wire [3:0]   _splitPipeline_io_out_bits_uop_ftqOffset;
  wire [8:0]   _splitPipeline_io_out_bits_uop_fuOpType;
  wire [7:0]   _splitPipeline_io_out_bits_uop_vpu_vstart;
  wire [6:0]   _splitPipeline_io_out_bits_uop_vpu_vuopIdx;
  wire [1:0]   _splitPipeline_io_out_bits_uop_vpu_veew;
  wire [6:0]   _splitPipeline_io_out_bits_uop_uopIdx;
  wire [7:0]   _splitPipeline_io_out_bits_uop_pdest;
  wire         _splitPipeline_io_out_bits_uop_robIdx_flag;
  wire [7:0]   _splitPipeline_io_out_bits_uop_robIdx_value;
  wire [63:0]  _splitPipeline_io_out_bits_uop_debugInfo_enqRsTime;
  wire [63:0]  _splitPipeline_io_out_bits_uop_debugInfo_selectTime;
  wire [63:0]  _splitPipeline_io_out_bits_uop_debugInfo_issueTime;
  wire         _splitPipeline_io_out_bits_uop_lqIdx_flag;
  wire [6:0]   _splitPipeline_io_out_bits_uop_lqIdx_value;
  wire         _splitPipeline_io_out_bits_uop_sqIdx_flag;
  wire [5:0]   _splitPipeline_io_out_bits_uop_sqIdx_value;
  wire         _splitPipeline_io_out_bits_preIsSplit;
  wire [3:0]   _splitPipeline_io_out_bits_mBIndex;
  wire [2:0]   _splitPipeline_io_out_bits_alignedType;
  wire [7:0]   _splitPipeline_io_out_bits_indexVlMaxInVd;
  wire [3:0]   _splitPipeline_io_out_bits_usLowBitsAddr;
  wire         _splitPipeline_io_out_bits_usAligned128;
  wire [31:0]  _splitPipeline_io_out_bits_usMask;
  wire [8:0]   redirRobIdx =
    {io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value};
  VLSplitPipelineImp splitPipeline (
    .clock                                              (clock),
    .reset                                              (reset),
    .io_redirect_valid                                  (io_redirect_valid),
    .io_redirect_bits_robIdx_flag                       (io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value                      (io_redirect_bits_robIdx_value),
    .io_redirect_bits_level                             (io_redirect_bits_level),
    .io_in_ready                                        (_splitPipeline_io_in_ready),
    .io_in_valid                                        (io_in_valid),
    .io_in_bits_uop_ftqPtr_flag                         (io_in_bits_uop_ftqPtr_flag),
    .io_in_bits_uop_ftqPtr_value                        (io_in_bits_uop_ftqPtr_value),
    .io_in_bits_uop_ftqOffset                           (io_in_bits_uop_ftqOffset),
    .io_in_bits_uop_fuOpType                            (io_in_bits_uop_fuOpType),
    .io_in_bits_uop_vecWen                              (io_in_bits_uop_vecWen),
    .io_in_bits_uop_v0Wen                               (io_in_bits_uop_v0Wen),
    .io_in_bits_uop_vlWen                               (io_in_bits_uop_vlWen),
    .io_in_bits_uop_vpu_vma                             (io_in_bits_uop_vpu_vma),
    .io_in_bits_uop_vpu_vta                             (io_in_bits_uop_vpu_vta),
    .io_in_bits_uop_vpu_vsew                            (io_in_bits_uop_vpu_vsew),
    .io_in_bits_uop_vpu_vlmul                           (io_in_bits_uop_vpu_vlmul),
    .io_in_bits_uop_vpu_vm                              (io_in_bits_uop_vpu_vm),
    .io_in_bits_uop_vpu_vstart                          (io_in_bits_uop_vpu_vstart),
    .io_in_bits_uop_vpu_vuopIdx                         (io_in_bits_uop_vpu_vuopIdx),
    .io_in_bits_uop_vpu_nf                              (io_in_bits_uop_vpu_nf),
    .io_in_bits_uop_vpu_veew                            (io_in_bits_uop_vpu_veew),
    .io_in_bits_uop_pdest                               (io_in_bits_uop_pdest),
    .io_in_bits_uop_robIdx_flag                         (io_in_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value                        (io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_debugInfo_enqRsTime
      (io_in_bits_uop_debugInfo_enqRsTime),
    .io_in_bits_uop_debugInfo_selectTime
      (io_in_bits_uop_debugInfo_selectTime),
    .io_in_bits_uop_debugInfo_issueTime
      (io_in_bits_uop_debugInfo_issueTime),
    .io_in_bits_uop_lqIdx_flag                          (io_in_bits_uop_lqIdx_flag),
    .io_in_bits_uop_lqIdx_value                         (io_in_bits_uop_lqIdx_value),
    .io_in_bits_uop_sqIdx_flag                          (io_in_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value                         (io_in_bits_uop_sqIdx_value),
    .io_in_bits_src_0                                   (io_in_bits_src_0),
    .io_in_bits_src_1                                   (io_in_bits_src_1),
    .io_in_bits_src_2                                   (io_in_bits_src_2),
    .io_in_bits_src_3                                   (io_in_bits_src_3),
    .io_in_bits_src_4                                   (io_in_bits_src_4),
    .io_in_bits_flowNum                                 (io_in_bits_flowNum),
    .io_toMergeBuffer_req_ready                         (io_toMergeBuffer_req_ready),
    .io_toMergeBuffer_req_valid                         (io_toMergeBuffer_req_valid),
    .io_toMergeBuffer_req_bits_mask                     (io_toMergeBuffer_req_bits_mask),
    .io_toMergeBuffer_req_bits_vaddr                    (io_toMergeBuffer_req_bits_vaddr),
    .io_toMergeBuffer_req_bits_flowNum
      (io_toMergeBuffer_req_bits_flowNum),
    .io_toMergeBuffer_req_bits_uop_fuOpType
      (io_toMergeBuffer_req_bits_uop_fuOpType),
    .io_toMergeBuffer_req_bits_uop_vecWen
      (io_toMergeBuffer_req_bits_uop_vecWen),
    .io_toMergeBuffer_req_bits_uop_v0Wen
      (io_toMergeBuffer_req_bits_uop_v0Wen),
    .io_toMergeBuffer_req_bits_uop_vlWen
      (io_toMergeBuffer_req_bits_uop_vlWen),
    .io_toMergeBuffer_req_bits_uop_vpu_vma
      (io_toMergeBuffer_req_bits_uop_vpu_vma),
    .io_toMergeBuffer_req_bits_uop_vpu_vta
      (io_toMergeBuffer_req_bits_uop_vpu_vta),
    .io_toMergeBuffer_req_bits_uop_vpu_vsew
      (io_toMergeBuffer_req_bits_uop_vpu_vsew),
    .io_toMergeBuffer_req_bits_uop_vpu_vlmul
      (io_toMergeBuffer_req_bits_uop_vpu_vlmul),
    .io_toMergeBuffer_req_bits_uop_vpu_vm
      (io_toMergeBuffer_req_bits_uop_vpu_vm),
    .io_toMergeBuffer_req_bits_uop_vpu_vuopIdx
      (io_toMergeBuffer_req_bits_uop_vpu_vuopIdx),
    .io_toMergeBuffer_req_bits_uop_vpu_vl
      (io_toMergeBuffer_req_bits_uop_vpu_vl),
    .io_toMergeBuffer_req_bits_uop_vpu_nf
      (io_toMergeBuffer_req_bits_uop_vpu_nf),
    .io_toMergeBuffer_req_bits_uop_vpu_veew
      (io_toMergeBuffer_req_bits_uop_vpu_veew),
    .io_toMergeBuffer_req_bits_uop_uopIdx
      (io_toMergeBuffer_req_bits_uop_uopIdx),
    .io_toMergeBuffer_req_bits_uop_pdest
      (io_toMergeBuffer_req_bits_uop_pdest),
    .io_toMergeBuffer_req_bits_uop_robIdx_flag
      (io_toMergeBuffer_req_bits_uop_robIdx_flag),
    .io_toMergeBuffer_req_bits_uop_robIdx_value
      (io_toMergeBuffer_req_bits_uop_robIdx_value),
    .io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime
      (io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_selectTime
      (io_toMergeBuffer_req_bits_uop_debugInfo_selectTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_issueTime
      (io_toMergeBuffer_req_bits_uop_debugInfo_issueTime),
    .io_toMergeBuffer_req_bits_data                     (io_toMergeBuffer_req_bits_data),
    .io_toMergeBuffer_req_bits_vdIdx                    (io_toMergeBuffer_req_bits_vdIdx),
    .io_toMergeBuffer_req_bits_fof                      (io_toMergeBuffer_req_bits_fof),
    .io_toMergeBuffer_req_bits_vlmax                    (io_toMergeBuffer_req_bits_vlmax),
    .io_toMergeBuffer_resp_valid                        (io_toMergeBuffer_resp_valid),
    .io_toMergeBuffer_resp_bits_mBIndex
      (io_toMergeBuffer_resp_bits_mBIndex),
    .io_out_ready                                       (_VSSplitSkidBuffer_io_in_ready),
    .io_out_valid                                       (_splitPipeline_io_out_valid),
    .io_out_bits_flowMask
      (_splitPipeline_io_out_bits_flowMask),
    .io_out_bits_data                                   (_splitPipeline_io_out_bits_data),
    .io_out_bits_baseAddr
      (_splitPipeline_io_out_bits_baseAddr),
    .io_out_bits_uopAddr
      (_splitPipeline_io_out_bits_uopAddr),
    .io_out_bits_stride
      (_splitPipeline_io_out_bits_stride),
    .io_out_bits_flowNum
      (_splitPipeline_io_out_bits_flowNum),
    .io_out_bits_eew                                    (_splitPipeline_io_out_bits_eew),
    .io_out_bits_sew                                    (_splitPipeline_io_out_bits_sew),
    .io_out_bits_emul                                   (_splitPipeline_io_out_bits_emul),
    .io_out_bits_lmul                                   (_splitPipeline_io_out_bits_lmul),
    .io_out_bits_instType
      (_splitPipeline_io_out_bits_instType),
    .io_out_bits_indexedSplitOffset
      (_splitPipeline_io_out_bits_indexedSplitOffset),
    .io_out_bits_uop_ftqPtr_flag
      (_splitPipeline_io_out_bits_uop_ftqPtr_flag),
    .io_out_bits_uop_ftqPtr_value
      (_splitPipeline_io_out_bits_uop_ftqPtr_value),
    .io_out_bits_uop_ftqOffset
      (_splitPipeline_io_out_bits_uop_ftqOffset),
    .io_out_bits_uop_fuOpType
      (_splitPipeline_io_out_bits_uop_fuOpType),
    .io_out_bits_uop_vpu_vstart
      (_splitPipeline_io_out_bits_uop_vpu_vstart),
    .io_out_bits_uop_vpu_vuopIdx
      (_splitPipeline_io_out_bits_uop_vpu_vuopIdx),
    .io_out_bits_uop_vpu_veew
      (_splitPipeline_io_out_bits_uop_vpu_veew),
    .io_out_bits_uop_uopIdx
      (_splitPipeline_io_out_bits_uop_uopIdx),
    .io_out_bits_uop_pdest
      (_splitPipeline_io_out_bits_uop_pdest),
    .io_out_bits_uop_robIdx_flag
      (_splitPipeline_io_out_bits_uop_robIdx_flag),
    .io_out_bits_uop_robIdx_value
      (_splitPipeline_io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_debugInfo_enqRsTime
      (_splitPipeline_io_out_bits_uop_debugInfo_enqRsTime),
    .io_out_bits_uop_debugInfo_selectTime
      (_splitPipeline_io_out_bits_uop_debugInfo_selectTime),
    .io_out_bits_uop_debugInfo_issueTime
      (_splitPipeline_io_out_bits_uop_debugInfo_issueTime),
    .io_out_bits_uop_lqIdx_flag
      (_splitPipeline_io_out_bits_uop_lqIdx_flag),
    .io_out_bits_uop_lqIdx_value
      (_splitPipeline_io_out_bits_uop_lqIdx_value),
    .io_out_bits_uop_sqIdx_flag
      (_splitPipeline_io_out_bits_uop_sqIdx_flag),
    .io_out_bits_uop_sqIdx_value
      (_splitPipeline_io_out_bits_uop_sqIdx_value),
    .io_out_bits_preIsSplit
      (_splitPipeline_io_out_bits_preIsSplit),
    .io_out_bits_mBIndex
      (_splitPipeline_io_out_bits_mBIndex),
    .io_out_bits_alignedType
      (_splitPipeline_io_out_bits_alignedType),
    .io_out_bits_indexVlMaxInVd
      (_splitPipeline_io_out_bits_indexVlMaxInVd),
    .io_out_bits_usLowBitsAddr
      (_splitPipeline_io_out_bits_usLowBitsAddr),
    .io_out_bits_usAligned128
      (_splitPipeline_io_out_bits_usAligned128),
    .io_out_bits_usMask
      (_splitPipeline_io_out_bits_usMask)
  );
  VLSplitBufferImp splitBuffer (
    .clock                                (clock),
    .reset                                (reset),
    .io_redirect_valid                    (io_redirect_valid),
    .io_redirect_bits_robIdx_flag         (io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value        (io_redirect_bits_robIdx_value),
    .io_redirect_bits_level               (io_redirect_bits_level),
    .io_in_ready                          (_splitBuffer_io_in_ready),
    .io_in_valid                          (_VSSplitSkidBuffer_io_out_valid),
    .io_in_bits_flowMask                  (_VSSplitSkidBuffer_io_out_bits_flowMask),
    .io_in_bits_baseAddr                  (_VSSplitSkidBuffer_io_out_bits_baseAddr),
    .io_in_bits_uopAddr                   (_VSSplitSkidBuffer_io_out_bits_uopAddr),
    .io_in_bits_stride                    (_VSSplitSkidBuffer_io_out_bits_stride),
    .io_in_bits_flowNum                   (_VSSplitSkidBuffer_io_out_bits_flowNum),
    .io_in_bits_eew                       (_VSSplitSkidBuffer_io_out_bits_eew),
    .io_in_bits_sew                       (_VSSplitSkidBuffer_io_out_bits_sew),
    .io_in_bits_emul                      (_VSSplitSkidBuffer_io_out_bits_emul),
    .io_in_bits_lmul                      (_VSSplitSkidBuffer_io_out_bits_lmul),
    .io_in_bits_instType                  (_VSSplitSkidBuffer_io_out_bits_instType),
    .io_in_bits_indexedSplitOffset
      (_VSSplitSkidBuffer_io_out_bits_indexedSplitOffset),
    .io_in_bits_uop_exceptionVec_5
      (_VSSplitSkidBuffer_io_out_bits_uop_exceptionVec_5),
    .io_in_bits_uop_exceptionVec_13
      (_VSSplitSkidBuffer_io_out_bits_uop_exceptionVec_13),
    .io_in_bits_uop_exceptionVec_19
      (_VSSplitSkidBuffer_io_out_bits_uop_exceptionVec_19),
    .io_in_bits_uop_exceptionVec_21
      (_VSSplitSkidBuffer_io_out_bits_uop_exceptionVec_21),
    .io_in_bits_uop_trigger               (_VSSplitSkidBuffer_io_out_bits_uop_trigger),
    .io_in_bits_uop_preDecodeInfo_isRVC
      (_VSSplitSkidBuffer_io_out_bits_uop_preDecodeInfo_isRVC),
    .io_in_bits_uop_ftqPtr_flag
      (_VSSplitSkidBuffer_io_out_bits_uop_ftqPtr_flag),
    .io_in_bits_uop_ftqPtr_value
      (_VSSplitSkidBuffer_io_out_bits_uop_ftqPtr_value),
    .io_in_bits_uop_ftqOffset             (_VSSplitSkidBuffer_io_out_bits_uop_ftqOffset),
    .io_in_bits_uop_fuOpType              (_VSSplitSkidBuffer_io_out_bits_uop_fuOpType),
    .io_in_bits_uop_rfWen                 (_VSSplitSkidBuffer_io_out_bits_uop_rfWen),
    .io_in_bits_uop_fpWen                 (_VSSplitSkidBuffer_io_out_bits_uop_fpWen),
    .io_in_bits_uop_vpu_vstart            (_VSSplitSkidBuffer_io_out_bits_uop_vpu_vstart),
    .io_in_bits_uop_vpu_vuopIdx
      (_VSSplitSkidBuffer_io_out_bits_uop_vpu_vuopIdx),
    .io_in_bits_uop_vpu_veew              (_VSSplitSkidBuffer_io_out_bits_uop_vpu_veew),
    .io_in_bits_uop_uopIdx                (_VSSplitSkidBuffer_io_out_bits_uop_uopIdx),
    .io_in_bits_uop_pdest                 (_VSSplitSkidBuffer_io_out_bits_uop_pdest),
    .io_in_bits_uop_robIdx_flag
      (_VSSplitSkidBuffer_io_out_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value
      (_VSSplitSkidBuffer_io_out_bits_uop_robIdx_value),
    .io_in_bits_uop_debugInfo_enqRsTime
      (_VSSplitSkidBuffer_io_out_bits_uop_debugInfo_enqRsTime),
    .io_in_bits_uop_debugInfo_selectTime
      (_VSSplitSkidBuffer_io_out_bits_uop_debugInfo_selectTime),
    .io_in_bits_uop_debugInfo_issueTime
      (_VSSplitSkidBuffer_io_out_bits_uop_debugInfo_issueTime),
    .io_in_bits_uop_storeSetHit
      (_VSSplitSkidBuffer_io_out_bits_uop_storeSetHit),
    .io_in_bits_uop_waitForRobIdx_flag
      (_VSSplitSkidBuffer_io_out_bits_uop_waitForRobIdx_flag),
    .io_in_bits_uop_waitForRobIdx_value
      (_VSSplitSkidBuffer_io_out_bits_uop_waitForRobIdx_value),
    .io_in_bits_uop_loadWaitBit
      (_VSSplitSkidBuffer_io_out_bits_uop_loadWaitBit),
    .io_in_bits_uop_loadWaitStrict
      (_VSSplitSkidBuffer_io_out_bits_uop_loadWaitStrict),
    .io_in_bits_uop_lqIdx_flag            (_VSSplitSkidBuffer_io_out_bits_uop_lqIdx_flag),
    .io_in_bits_uop_lqIdx_value
      (_VSSplitSkidBuffer_io_out_bits_uop_lqIdx_value),
    .io_in_bits_uop_sqIdx_flag            (_VSSplitSkidBuffer_io_out_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value
      (_VSSplitSkidBuffer_io_out_bits_uop_sqIdx_value),
    .io_in_bits_preIsSplit                (_VSSplitSkidBuffer_io_out_bits_preIsSplit),
    .io_in_bits_mBIndex                   (_VSSplitSkidBuffer_io_out_bits_mBIndex),
    .io_in_bits_alignedType               (_VSSplitSkidBuffer_io_out_bits_alignedType),
    .io_in_bits_indexVlMaxInVd            (_VSSplitSkidBuffer_io_out_bits_indexVlMaxInVd),
    .io_in_bits_usLowBitsAddr             (_VSSplitSkidBuffer_io_out_bits_usLowBitsAddr),
    .io_in_bits_usAligned128              (_VSSplitSkidBuffer_io_out_bits_usAligned128),
    .io_in_bits_usMask                    (_VSSplitSkidBuffer_io_out_bits_usMask),
    .io_out_ready                         (io_out_ready),
    .io_out_valid                         (_splitBuffer_io_out_valid),
    .io_out_bits_vaddr                    (io_out_bits_vaddr),
    .io_out_bits_basevaddr                (io_out_bits_basevaddr),
    .io_out_bits_mask                     (io_out_bits_mask),
    .io_out_bits_reg_offset               (io_out_bits_reg_offset),
    .io_out_bits_alignedType              (io_out_bits_alignedType),
    .io_out_bits_vecActive                (io_out_bits_vecActive),
    .io_out_bits_uop_exceptionVec_4       (io_out_bits_uop_exceptionVec_4),
    .io_out_bits_uop_exceptionVec_5       (io_out_bits_uop_exceptionVec_5),
    .io_out_bits_uop_exceptionVec_13      (io_out_bits_uop_exceptionVec_13),
    .io_out_bits_uop_exceptionVec_19      (io_out_bits_uop_exceptionVec_19),
    .io_out_bits_uop_exceptionVec_21      (io_out_bits_uop_exceptionVec_21),
    .io_out_bits_uop_trigger              (io_out_bits_uop_trigger),
    .io_out_bits_uop_preDecodeInfo_isRVC  (io_out_bits_uop_preDecodeInfo_isRVC),
    .io_out_bits_uop_ftqPtr_flag          (io_out_bits_uop_ftqPtr_flag),
    .io_out_bits_uop_ftqPtr_value         (io_out_bits_uop_ftqPtr_value),
    .io_out_bits_uop_ftqOffset            (io_out_bits_uop_ftqOffset),
    .io_out_bits_uop_fuOpType             (io_out_bits_uop_fuOpType),
    .io_out_bits_uop_rfWen                (io_out_bits_uop_rfWen),
    .io_out_bits_uop_fpWen                (io_out_bits_uop_fpWen),
    .io_out_bits_uop_vpu_vstart           (io_out_bits_uop_vpu_vstart),
    .io_out_bits_uop_vpu_veew             (io_out_bits_uop_vpu_veew),
    .io_out_bits_uop_uopIdx               (io_out_bits_uop_uopIdx),
    .io_out_bits_uop_pdest                (io_out_bits_uop_pdest),
    .io_out_bits_uop_robIdx_flag          (io_out_bits_uop_robIdx_flag),
    .io_out_bits_uop_robIdx_value         (io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_debugInfo_enqRsTime  (io_out_bits_uop_debugInfo_enqRsTime),
    .io_out_bits_uop_debugInfo_selectTime (io_out_bits_uop_debugInfo_selectTime),
    .io_out_bits_uop_debugInfo_issueTime  (io_out_bits_uop_debugInfo_issueTime),
    .io_out_bits_uop_storeSetHit          (io_out_bits_uop_storeSetHit),
    .io_out_bits_uop_waitForRobIdx_flag   (io_out_bits_uop_waitForRobIdx_flag),
    .io_out_bits_uop_waitForRobIdx_value  (io_out_bits_uop_waitForRobIdx_value),
    .io_out_bits_uop_loadWaitBit          (io_out_bits_uop_loadWaitBit),
    .io_out_bits_uop_loadWaitStrict       (io_out_bits_uop_loadWaitStrict),
    .io_out_bits_uop_lqIdx_flag           (io_out_bits_uop_lqIdx_flag),
    .io_out_bits_uop_lqIdx_value          (io_out_bits_uop_lqIdx_value),
    .io_out_bits_uop_sqIdx_flag           (io_out_bits_uop_sqIdx_flag),
    .io_out_bits_uop_sqIdx_value          (io_out_bits_uop_sqIdx_value),
    .io_out_bits_mBIndex                  (io_out_bits_mBIndex),
    .io_out_bits_elemIdx                  (io_out_bits_elemIdx),
    .io_out_bits_elemIdxInsideVd          (io_out_bits_elemIdxInsideVd)
  );
  wire         _probe;
  assign _probe = _splitBuffer_io_out_valid;
  skidBufferConnect VSSplitSkidBuffer (
    .clock                                (clock),
    .reset                                (reset),
    .io_in_ready                          (_VSSplitSkidBuffer_io_in_ready),
    .io_in_valid                          (_splitPipeline_io_out_valid),
    .io_in_bits_flowMask                  (_splitPipeline_io_out_bits_flowMask),
    .io_in_bits_data                      (_splitPipeline_io_out_bits_data),
    .io_in_bits_baseAddr                  (_splitPipeline_io_out_bits_baseAddr),
    .io_in_bits_uopAddr                   (_splitPipeline_io_out_bits_uopAddr),
    .io_in_bits_stride                    (_splitPipeline_io_out_bits_stride),
    .io_in_bits_flowNum                   (_splitPipeline_io_out_bits_flowNum),
    .io_in_bits_eew                       (_splitPipeline_io_out_bits_eew),
    .io_in_bits_sew                       (_splitPipeline_io_out_bits_sew),
    .io_in_bits_emul                      (_splitPipeline_io_out_bits_emul),
    .io_in_bits_lmul                      (_splitPipeline_io_out_bits_lmul),
    .io_in_bits_instType                  (_splitPipeline_io_out_bits_instType),
    .io_in_bits_indexedSplitOffset        (_splitPipeline_io_out_bits_indexedSplitOffset),
    .io_in_bits_uop_ftqPtr_flag           (_splitPipeline_io_out_bits_uop_ftqPtr_flag),
    .io_in_bits_uop_ftqPtr_value          (_splitPipeline_io_out_bits_uop_ftqPtr_value),
    .io_in_bits_uop_ftqOffset             (_splitPipeline_io_out_bits_uop_ftqOffset),
    .io_in_bits_uop_fuOpType              (_splitPipeline_io_out_bits_uop_fuOpType),
    .io_in_bits_uop_vpu_vstart            (_splitPipeline_io_out_bits_uop_vpu_vstart),
    .io_in_bits_uop_vpu_vuopIdx           (_splitPipeline_io_out_bits_uop_vpu_vuopIdx),
    .io_in_bits_uop_vpu_veew              (_splitPipeline_io_out_bits_uop_vpu_veew),
    .io_in_bits_uop_uopIdx                (_splitPipeline_io_out_bits_uop_uopIdx),
    .io_in_bits_uop_pdest                 (_splitPipeline_io_out_bits_uop_pdest),
    .io_in_bits_uop_robIdx_flag           (_splitPipeline_io_out_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value          (_splitPipeline_io_out_bits_uop_robIdx_value),
    .io_in_bits_uop_debugInfo_enqRsTime
      (_splitPipeline_io_out_bits_uop_debugInfo_enqRsTime),
    .io_in_bits_uop_debugInfo_selectTime
      (_splitPipeline_io_out_bits_uop_debugInfo_selectTime),
    .io_in_bits_uop_debugInfo_issueTime
      (_splitPipeline_io_out_bits_uop_debugInfo_issueTime),
    .io_in_bits_uop_lqIdx_flag            (_splitPipeline_io_out_bits_uop_lqIdx_flag),
    .io_in_bits_uop_lqIdx_value           (_splitPipeline_io_out_bits_uop_lqIdx_value),
    .io_in_bits_uop_sqIdx_flag            (_splitPipeline_io_out_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value           (_splitPipeline_io_out_bits_uop_sqIdx_value),
    .io_in_bits_preIsSplit                (_splitPipeline_io_out_bits_preIsSplit),
    .io_in_bits_mBIndex                   (_splitPipeline_io_out_bits_mBIndex),
    .io_in_bits_alignedType               (_splitPipeline_io_out_bits_alignedType),
    .io_in_bits_indexVlMaxInVd            (_splitPipeline_io_out_bits_indexVlMaxInVd),
    .io_in_bits_usLowBitsAddr             (_splitPipeline_io_out_bits_usLowBitsAddr),
    .io_in_bits_usAligned128              (_splitPipeline_io_out_bits_usAligned128),
    .io_in_bits_usMask                    (_splitPipeline_io_out_bits_usMask),
    .io_flush
      (_VSSplitSkidBuffer_io_in_ready & _splitPipeline_io_out_valid
         ? io_redirect_valid
           & (io_redirect_bits_level
              & {_splitPipeline_io_out_bits_uop_robIdx_flag,
                 _splitPipeline_io_out_bits_uop_robIdx_value} == redirRobIdx
              | _splitPipeline_io_out_bits_uop_robIdx_flag ^ io_redirect_bits_robIdx_flag
              ^ _splitPipeline_io_out_bits_uop_robIdx_value > io_redirect_bits_robIdx_value)
         : io_redirect_valid
           & (io_redirect_bits_level
              & {_VSSplitSkidBuffer_io_out_bits_uop_robIdx_flag,
                 _VSSplitSkidBuffer_io_out_bits_uop_robIdx_value} == redirRobIdx
              | _VSSplitSkidBuffer_io_out_bits_uop_robIdx_flag
              ^ io_redirect_bits_robIdx_flag
              ^ _VSSplitSkidBuffer_io_out_bits_uop_robIdx_value > io_redirect_bits_robIdx_value)),
    .io_out_ready                         (_splitBuffer_io_in_ready),
    .io_out_valid                         (_VSSplitSkidBuffer_io_out_valid),
    .io_out_bits_flowMask                 (_VSSplitSkidBuffer_io_out_bits_flowMask),
    .io_out_bits_data                     (/* unused */),
    .io_out_bits_baseAddr                 (_VSSplitSkidBuffer_io_out_bits_baseAddr),
    .io_out_bits_uopAddr                  (_VSSplitSkidBuffer_io_out_bits_uopAddr),
    .io_out_bits_stride                   (_VSSplitSkidBuffer_io_out_bits_stride),
    .io_out_bits_flowNum                  (_VSSplitSkidBuffer_io_out_bits_flowNum),
    .io_out_bits_eew                      (_VSSplitSkidBuffer_io_out_bits_eew),
    .io_out_bits_sew                      (_VSSplitSkidBuffer_io_out_bits_sew),
    .io_out_bits_emul                     (_VSSplitSkidBuffer_io_out_bits_emul),
    .io_out_bits_lmul                     (_VSSplitSkidBuffer_io_out_bits_lmul),
    .io_out_bits_instType                 (_VSSplitSkidBuffer_io_out_bits_instType),
    .io_out_bits_indexedSplitOffset
      (_VSSplitSkidBuffer_io_out_bits_indexedSplitOffset),
    .io_out_bits_uop_exceptionVec_5
      (_VSSplitSkidBuffer_io_out_bits_uop_exceptionVec_5),
    .io_out_bits_uop_exceptionVec_7       (/* unused */),
    .io_out_bits_uop_exceptionVec_13
      (_VSSplitSkidBuffer_io_out_bits_uop_exceptionVec_13),
    .io_out_bits_uop_exceptionVec_15      (/* unused */),
    .io_out_bits_uop_exceptionVec_19
      (_VSSplitSkidBuffer_io_out_bits_uop_exceptionVec_19),
    .io_out_bits_uop_exceptionVec_21
      (_VSSplitSkidBuffer_io_out_bits_uop_exceptionVec_21),
    .io_out_bits_uop_exceptionVec_23      (/* unused */),
    .io_out_bits_uop_trigger              (_VSSplitSkidBuffer_io_out_bits_uop_trigger),
    .io_out_bits_uop_preDecodeInfo_isRVC
      (_VSSplitSkidBuffer_io_out_bits_uop_preDecodeInfo_isRVC),
    .io_out_bits_uop_ftqPtr_flag
      (_VSSplitSkidBuffer_io_out_bits_uop_ftqPtr_flag),
    .io_out_bits_uop_ftqPtr_value
      (_VSSplitSkidBuffer_io_out_bits_uop_ftqPtr_value),
    .io_out_bits_uop_ftqOffset            (_VSSplitSkidBuffer_io_out_bits_uop_ftqOffset),
    .io_out_bits_uop_fuOpType             (_VSSplitSkidBuffer_io_out_bits_uop_fuOpType),
    .io_out_bits_uop_rfWen                (_VSSplitSkidBuffer_io_out_bits_uop_rfWen),
    .io_out_bits_uop_fpWen                (_VSSplitSkidBuffer_io_out_bits_uop_fpWen),
    .io_out_bits_uop_vpu_vstart           (_VSSplitSkidBuffer_io_out_bits_uop_vpu_vstart),
    .io_out_bits_uop_vpu_vuopIdx
      (_VSSplitSkidBuffer_io_out_bits_uop_vpu_vuopIdx),
    .io_out_bits_uop_vpu_veew             (_VSSplitSkidBuffer_io_out_bits_uop_vpu_veew),
    .io_out_bits_uop_uopIdx               (_VSSplitSkidBuffer_io_out_bits_uop_uopIdx),
    .io_out_bits_uop_pdest                (_VSSplitSkidBuffer_io_out_bits_uop_pdest),
    .io_out_bits_uop_robIdx_flag
      (_VSSplitSkidBuffer_io_out_bits_uop_robIdx_flag),
    .io_out_bits_uop_robIdx_value
      (_VSSplitSkidBuffer_io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_debugInfo_enqRsTime
      (_VSSplitSkidBuffer_io_out_bits_uop_debugInfo_enqRsTime),
    .io_out_bits_uop_debugInfo_selectTime
      (_VSSplitSkidBuffer_io_out_bits_uop_debugInfo_selectTime),
    .io_out_bits_uop_debugInfo_issueTime
      (_VSSplitSkidBuffer_io_out_bits_uop_debugInfo_issueTime),
    .io_out_bits_uop_storeSetHit
      (_VSSplitSkidBuffer_io_out_bits_uop_storeSetHit),
    .io_out_bits_uop_waitForRobIdx_flag
      (_VSSplitSkidBuffer_io_out_bits_uop_waitForRobIdx_flag),
    .io_out_bits_uop_waitForRobIdx_value
      (_VSSplitSkidBuffer_io_out_bits_uop_waitForRobIdx_value),
    .io_out_bits_uop_loadWaitBit
      (_VSSplitSkidBuffer_io_out_bits_uop_loadWaitBit),
    .io_out_bits_uop_loadWaitStrict
      (_VSSplitSkidBuffer_io_out_bits_uop_loadWaitStrict),
    .io_out_bits_uop_lqIdx_flag           (_VSSplitSkidBuffer_io_out_bits_uop_lqIdx_flag),
    .io_out_bits_uop_lqIdx_value
      (_VSSplitSkidBuffer_io_out_bits_uop_lqIdx_value),
    .io_out_bits_uop_sqIdx_flag           (_VSSplitSkidBuffer_io_out_bits_uop_sqIdx_flag),
    .io_out_bits_uop_sqIdx_value
      (_VSSplitSkidBuffer_io_out_bits_uop_sqIdx_value),
    .io_out_bits_preIsSplit               (_VSSplitSkidBuffer_io_out_bits_preIsSplit),
    .io_out_bits_mBIndex                  (_VSSplitSkidBuffer_io_out_bits_mBIndex),
    .io_out_bits_alignedType              (_VSSplitSkidBuffer_io_out_bits_alignedType),
    .io_out_bits_indexVlMaxInVd           (_VSSplitSkidBuffer_io_out_bits_indexVlMaxInVd),
    .io_out_bits_usLowBitsAddr            (_VSSplitSkidBuffer_io_out_bits_usLowBitsAddr),
    .io_out_bits_usAligned128             (_VSSplitSkidBuffer_io_out_bits_usAligned128),
    .io_out_bits_usMask                   (_VSSplitSkidBuffer_io_out_bits_usMask)
  );
  assign io_in_ready =
    _splitPipeline_io_in_ready
    & ~(io_threshold_valid
        & {io_threshold_bits_flag,
           io_threshold_bits_value} != {io_in_bits_uop_lqIdx_flag,
                                        io_in_bits_uop_lqIdx_value});
  assign io_out_valid = _splitBuffer_io_out_valid;
endmodule
