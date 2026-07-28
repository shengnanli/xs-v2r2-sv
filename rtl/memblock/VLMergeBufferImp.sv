// xs_VLMergeBufferImp_core —— 向量 load 16 条目 merge buffer 可读核。
// 手写重写(结构阵列化), bug-for-bug 对齐 golden VLMergeBufferImp.sv(8604 行)。
// 16 条目 → struct 数组 entries[16]; allocated/uopFinish/needRSReplay → 位向量;
// 3 端口字节级数据合并/碰撞矩阵/双 select(oldest/youngest)忠实保留。
// 子模块 FreeList + NewPipelineConnectPipe_27×2 由核直接例化(两侧 elaborate)。
// 依赖 xs_vlmergebuffer_pkg(编译列表 RTL_SRCS 先行编译)。

module xs_VLMergeBufferImp_core
  import xs_vlmergebuffer_pkg::*;
(
  input           clock,
  input           reset,
  input           io_redirect_valid,
  input           io_redirect_bits_robIdx_flag,
  input [7:0]     io_redirect_bits_robIdx_value,
  input           io_redirect_bits_level,
  input           io_fromPipeline_0_valid,
  input [3:0]     io_fromPipeline_0_bits_mBIndex,
  input [3:0]     io_fromPipeline_0_bits_trigger,
  input           io_fromPipeline_0_bits_exceptionVec_3,
  input           io_fromPipeline_0_bits_exceptionVec_4,
  input           io_fromPipeline_0_bits_exceptionVec_5,
  input           io_fromPipeline_0_bits_exceptionVec_13,
  input           io_fromPipeline_0_bits_exceptionVec_19,
  input           io_fromPipeline_0_bits_exceptionVec_21,
  input           io_fromPipeline_0_bits_hasException,
  input [63:0]    io_fromPipeline_0_bits_vaddr,
  input           io_fromPipeline_0_bits_vaNeedExt,
  input [63:0]    io_fromPipeline_0_bits_gpaddr,
  input [7:0]     io_fromPipeline_0_bits_vstart,
  input [15:0]    io_fromPipeline_0_bits_vecTriggerMask,
  input [7:0]     io_fromPipeline_0_bits_elemIdx,
  input [15:0]    io_fromPipeline_0_bits_mask,
  input [2:0]     io_fromPipeline_0_bits_alignedType,
  input [3:0]     io_fromPipeline_0_bits_reg_offset,
  input [7:0]     io_fromPipeline_0_bits_elemIdxInsideVd,
  input [127:0]   io_fromPipeline_0_bits_vecdata,
  input           io_fromPipeline_1_valid,
  input [3:0]     io_fromPipeline_1_bits_mBIndex,
  input [3:0]     io_fromPipeline_1_bits_trigger,
  input           io_fromPipeline_1_bits_exceptionVec_3,
  input           io_fromPipeline_1_bits_exceptionVec_4,
  input           io_fromPipeline_1_bits_exceptionVec_5,
  input           io_fromPipeline_1_bits_exceptionVec_13,
  input           io_fromPipeline_1_bits_exceptionVec_19,
  input           io_fromPipeline_1_bits_exceptionVec_21,
  input           io_fromPipeline_1_bits_hasException,
  input [63:0]    io_fromPipeline_1_bits_vaddr,
  input           io_fromPipeline_1_bits_vaNeedExt,
  input [63:0]    io_fromPipeline_1_bits_gpaddr,
  input [7:0]     io_fromPipeline_1_bits_vstart,
  input [15:0]    io_fromPipeline_1_bits_vecTriggerMask,
  input [7:0]     io_fromPipeline_1_bits_elemIdx,
  input [15:0]    io_fromPipeline_1_bits_mask,
  input [2:0]     io_fromPipeline_1_bits_alignedType,
  input [3:0]     io_fromPipeline_1_bits_reg_offset,
  input [7:0]     io_fromPipeline_1_bits_elemIdxInsideVd,
  input [127:0]   io_fromPipeline_1_bits_vecdata,
  input           io_fromPipeline_2_valid,
  input [3:0]     io_fromPipeline_2_bits_mBIndex,
  input [3:0]     io_fromPipeline_2_bits_trigger,
  input           io_fromPipeline_2_bits_exceptionVec_3,
  input           io_fromPipeline_2_bits_exceptionVec_4,
  input           io_fromPipeline_2_bits_exceptionVec_5,
  input           io_fromPipeline_2_bits_exceptionVec_13,
  input           io_fromPipeline_2_bits_exceptionVec_19,
  input           io_fromPipeline_2_bits_exceptionVec_21,
  input           io_fromPipeline_2_bits_hasException,
  input [63:0]    io_fromPipeline_2_bits_vaddr,
  input           io_fromPipeline_2_bits_vaNeedExt,
  input [63:0]    io_fromPipeline_2_bits_gpaddr,
  input [7:0]     io_fromPipeline_2_bits_vstart,
  input [15:0]    io_fromPipeline_2_bits_vecTriggerMask,
  input [7:0]     io_fromPipeline_2_bits_elemIdx,
  input [15:0]    io_fromPipeline_2_bits_mask,
  input [2:0]     io_fromPipeline_2_bits_alignedType,
  input [3:0]     io_fromPipeline_2_bits_reg_offset,
  input [7:0]     io_fromPipeline_2_bits_elemIdxInsideVd,
  input [127:0]   io_fromPipeline_2_bits_vecdata,
  output           io_fromSplit_0_req_ready,
  input           io_fromSplit_0_req_valid,
  input [15:0]    io_fromSplit_0_req_bits_mask,
  input [49:0]    io_fromSplit_0_req_bits_vaddr,
  input [4:0]     io_fromSplit_0_req_bits_flowNum,
  input [8:0]     io_fromSplit_0_req_bits_uop_fuOpType,
  input           io_fromSplit_0_req_bits_uop_vecWen,
  input           io_fromSplit_0_req_bits_uop_v0Wen,
  input           io_fromSplit_0_req_bits_uop_vlWen,
  input           io_fromSplit_0_req_bits_uop_vpu_vma,
  input           io_fromSplit_0_req_bits_uop_vpu_vta,
  input [1:0]     io_fromSplit_0_req_bits_uop_vpu_vsew,
  input [2:0]     io_fromSplit_0_req_bits_uop_vpu_vlmul,
  input           io_fromSplit_0_req_bits_uop_vpu_vm,
  input [6:0]     io_fromSplit_0_req_bits_uop_vpu_vuopIdx,
  input [7:0]     io_fromSplit_0_req_bits_uop_vpu_vl,
  input [2:0]     io_fromSplit_0_req_bits_uop_vpu_nf,
  input [1:0]     io_fromSplit_0_req_bits_uop_vpu_veew,
  input [6:0]     io_fromSplit_0_req_bits_uop_uopIdx,
  input [7:0]     io_fromSplit_0_req_bits_uop_pdest,
  input           io_fromSplit_0_req_bits_uop_robIdx_flag,
  input [7:0]     io_fromSplit_0_req_bits_uop_robIdx_value,
  input [63:0]    io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime,
  input [63:0]    io_fromSplit_0_req_bits_uop_debugInfo_selectTime,
  input [63:0]    io_fromSplit_0_req_bits_uop_debugInfo_issueTime,
  input [127:0]   io_fromSplit_0_req_bits_data,
  input [2:0]     io_fromSplit_0_req_bits_vdIdx,
  input           io_fromSplit_0_req_bits_fof,
  input [7:0]     io_fromSplit_0_req_bits_vlmax,
  output           io_fromSplit_0_resp_valid,
  output [3:0]     io_fromSplit_0_resp_bits_mBIndex,
  output           io_fromSplit_1_req_ready,
  input           io_fromSplit_1_req_valid,
  input [15:0]    io_fromSplit_1_req_bits_mask,
  input [49:0]    io_fromSplit_1_req_bits_vaddr,
  input [4:0]     io_fromSplit_1_req_bits_flowNum,
  input [8:0]     io_fromSplit_1_req_bits_uop_fuOpType,
  input           io_fromSplit_1_req_bits_uop_vecWen,
  input           io_fromSplit_1_req_bits_uop_v0Wen,
  input           io_fromSplit_1_req_bits_uop_vlWen,
  input           io_fromSplit_1_req_bits_uop_vpu_vma,
  input           io_fromSplit_1_req_bits_uop_vpu_vta,
  input [1:0]     io_fromSplit_1_req_bits_uop_vpu_vsew,
  input [2:0]     io_fromSplit_1_req_bits_uop_vpu_vlmul,
  input           io_fromSplit_1_req_bits_uop_vpu_vm,
  input [6:0]     io_fromSplit_1_req_bits_uop_vpu_vuopIdx,
  input [7:0]     io_fromSplit_1_req_bits_uop_vpu_vl,
  input [2:0]     io_fromSplit_1_req_bits_uop_vpu_nf,
  input [1:0]     io_fromSplit_1_req_bits_uop_vpu_veew,
  input [6:0]     io_fromSplit_1_req_bits_uop_uopIdx,
  input [7:0]     io_fromSplit_1_req_bits_uop_pdest,
  input           io_fromSplit_1_req_bits_uop_robIdx_flag,
  input [7:0]     io_fromSplit_1_req_bits_uop_robIdx_value,
  input [63:0]    io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime,
  input [63:0]    io_fromSplit_1_req_bits_uop_debugInfo_selectTime,
  input [63:0]    io_fromSplit_1_req_bits_uop_debugInfo_issueTime,
  input [127:0]   io_fromSplit_1_req_bits_data,
  input [2:0]     io_fromSplit_1_req_bits_vdIdx,
  input           io_fromSplit_1_req_bits_fof,
  input [7:0]     io_fromSplit_1_req_bits_vlmax,
  output           io_fromSplit_1_resp_valid,
  output [3:0]     io_fromSplit_1_resp_bits_mBIndex,
  input           io_uopWriteback_0_ready,
  output           io_uopWriteback_0_valid,
  output           io_uopWriteback_0_bits_uop_exceptionVec_3,
  output           io_uopWriteback_0_bits_uop_exceptionVec_4,
  output           io_uopWriteback_0_bits_uop_exceptionVec_5,
  output           io_uopWriteback_0_bits_uop_exceptionVec_13,
  output           io_uopWriteback_0_bits_uop_exceptionVec_19,
  output           io_uopWriteback_0_bits_uop_exceptionVec_21,
  output [3:0]     io_uopWriteback_0_bits_uop_trigger,
  output [8:0]     io_uopWriteback_0_bits_uop_fuOpType,
  output           io_uopWriteback_0_bits_uop_vecWen,
  output           io_uopWriteback_0_bits_uop_v0Wen,
  output           io_uopWriteback_0_bits_uop_vlWen,
  output           io_uopWriteback_0_bits_uop_flushPipe,
  output           io_uopWriteback_0_bits_uop_vpu_vma,
  output           io_uopWriteback_0_bits_uop_vpu_vta,
  output [1:0]     io_uopWriteback_0_bits_uop_vpu_vsew,
  output [2:0]     io_uopWriteback_0_bits_uop_vpu_vlmul,
  output           io_uopWriteback_0_bits_uop_vpu_vm,
  output [7:0]     io_uopWriteback_0_bits_uop_vpu_vstart,
  output [6:0]     io_uopWriteback_0_bits_uop_vpu_vuopIdx,
  output [127:0]   io_uopWriteback_0_bits_uop_vpu_vmask,
  output [7:0]     io_uopWriteback_0_bits_uop_vpu_vl,
  output [2:0]     io_uopWriteback_0_bits_uop_vpu_nf,
  output [1:0]     io_uopWriteback_0_bits_uop_vpu_veew,
  output [7:0]     io_uopWriteback_0_bits_uop_pdest,
  output           io_uopWriteback_0_bits_uop_robIdx_flag,
  output [7:0]     io_uopWriteback_0_bits_uop_robIdx_value,
  output [63:0]    io_uopWriteback_0_bits_uop_debugInfo_enqRsTime,
  output [63:0]    io_uopWriteback_0_bits_uop_debugInfo_selectTime,
  output [63:0]    io_uopWriteback_0_bits_uop_debugInfo_issueTime,
  output           io_uopWriteback_0_bits_uop_replayInst,
  output [127:0]   io_uopWriteback_0_bits_data,
  output [2:0]     io_uopWriteback_0_bits_vdIdx,
  output [2:0]     io_uopWriteback_0_bits_vdIdxInField,
  input           io_uopWriteback_1_ready,
  output           io_uopWriteback_1_valid,
  output           io_uopWriteback_1_bits_uop_exceptionVec_3,
  output           io_uopWriteback_1_bits_uop_exceptionVec_4,
  output           io_uopWriteback_1_bits_uop_exceptionVec_5,
  output           io_uopWriteback_1_bits_uop_exceptionVec_13,
  output           io_uopWriteback_1_bits_uop_exceptionVec_19,
  output           io_uopWriteback_1_bits_uop_exceptionVec_21,
  output [3:0]     io_uopWriteback_1_bits_uop_trigger,
  output [8:0]     io_uopWriteback_1_bits_uop_fuOpType,
  output           io_uopWriteback_1_bits_uop_vecWen,
  output           io_uopWriteback_1_bits_uop_v0Wen,
  output           io_uopWriteback_1_bits_uop_vlWen,
  output           io_uopWriteback_1_bits_uop_flushPipe,
  output           io_uopWriteback_1_bits_uop_vpu_vma,
  output           io_uopWriteback_1_bits_uop_vpu_vta,
  output [1:0]     io_uopWriteback_1_bits_uop_vpu_vsew,
  output [2:0]     io_uopWriteback_1_bits_uop_vpu_vlmul,
  output           io_uopWriteback_1_bits_uop_vpu_vm,
  output [7:0]     io_uopWriteback_1_bits_uop_vpu_vstart,
  output [6:0]     io_uopWriteback_1_bits_uop_vpu_vuopIdx,
  output [127:0]   io_uopWriteback_1_bits_uop_vpu_vmask,
  output [7:0]     io_uopWriteback_1_bits_uop_vpu_vl,
  output [2:0]     io_uopWriteback_1_bits_uop_vpu_nf,
  output [1:0]     io_uopWriteback_1_bits_uop_vpu_veew,
  output [7:0]     io_uopWriteback_1_bits_uop_pdest,
  output           io_uopWriteback_1_bits_uop_robIdx_flag,
  output [7:0]     io_uopWriteback_1_bits_uop_robIdx_value,
  output [63:0]    io_uopWriteback_1_bits_uop_debugInfo_enqRsTime,
  output [63:0]    io_uopWriteback_1_bits_uop_debugInfo_selectTime,
  output [63:0]    io_uopWriteback_1_bits_uop_debugInfo_issueTime,
  output           io_uopWriteback_1_bits_uop_replayInst,
  output [127:0]   io_uopWriteback_1_bits_data,
  output [2:0]     io_uopWriteback_1_bits_vdIdx,
  output [2:0]     io_uopWriteback_1_bits_vdIdxInField,
  output           io_toSplit_threshold,
  output           io_toLsq_0_valid,
  output           io_toLsq_0_bits_robidx_flag,
  output [7:0]     io_toLsq_0_bits_robidx_value,
  output [6:0]     io_toLsq_0_bits_uopidx,
  output [63:0]    io_toLsq_0_bits_vaddr,
  output           io_toLsq_0_bits_vaNeedExt,
  output [49:0]    io_toLsq_0_bits_gpaddr,
  output           io_toLsq_0_bits_feedback_0,
  output           io_toLsq_0_bits_feedback_1,
  output           io_toLsq_0_bits_exceptionVec_3,
  output           io_toLsq_0_bits_exceptionVec_4,
  output           io_toLsq_0_bits_exceptionVec_5,
  output           io_toLsq_0_bits_exceptionVec_13,
  output           io_toLsq_0_bits_exceptionVec_19,
  output           io_toLsq_0_bits_exceptionVec_21,
  output           io_toLsq_1_valid,
  output           io_toLsq_1_bits_robidx_flag,
  output [7:0]     io_toLsq_1_bits_robidx_value,
  output [6:0]     io_toLsq_1_bits_uopidx,
  output [63:0]    io_toLsq_1_bits_vaddr,
  output           io_toLsq_1_bits_vaNeedExt,
  output [49:0]    io_toLsq_1_bits_gpaddr,
  output           io_toLsq_1_bits_feedback_0,
  output           io_toLsq_1_bits_feedback_1,
  output           io_toLsq_1_bits_exceptionVec_3,
  output           io_toLsq_1_bits_exceptionVec_4,
  output           io_toLsq_1_bits_exceptionVec_5,
  output           io_toLsq_1_bits_exceptionVec_13,
  output           io_toLsq_1_bits_exceptionVec_19,
  output           io_toLsq_1_bits_exceptionVec_21
);

  wire               _probe;
  wire               freeMaskVec_15;
  wire               freeMaskVec_14;
  wire               freeMaskVec_13;
  wire               freeMaskVec_12;
  wire               freeMaskVec_11;
  wire               freeMaskVec_10;
  wire               freeMaskVec_9;
  wire               freeMaskVec_8;
  wire               freeMaskVec_7;
  wire               freeMaskVec_6;
  wire               freeMaskVec_5;
  wire               freeMaskVec_4;
  wire               freeMaskVec_3;
  wire               freeMaskVec_2;
  wire               freeMaskVec_1;
  wire               freeMaskVec_0;
  wire               _VMergebufferPipelineConnect1_io_in_ready;
  wire               _VMergebufferPipelineConnect1_io_out_valid;
  wire               _VMergebufferPipelineConnect1_io_out_bits_uop_robIdx_flag;
  wire [7:0]         _VMergebufferPipelineConnect1_io_out_bits_uop_robIdx_value;
  wire               _VMergebufferPipelineConnect0_io_in_ready;
  wire               _VMergebufferPipelineConnect0_io_out_valid;
  wire               _VMergebufferPipelineConnect0_io_out_bits_uop_robIdx_flag;
  wire [7:0]         _VMergebufferPipelineConnect0_io_out_bits_uop_robIdx_value;
  wire [3:0]         _freeCount_freeList_io_allocateSlot_0;
  wire [3:0]         _freeCount_freeList_io_allocateSlot_1;
  wire [4:0]         _freeCount_freeList_io_validCount;
  // 16 条目状态(struct 数组, 替代 golden entries_N_* 平坦寄存器)
  vlmb_entry_t entries [16];
  logic [15:0] allocated;
  logic [15:0] uopFinish;
  logic [15:0] needRSReplay;
  wire [8:0]         _flushItself_T_14 =
    {io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value};
  wire               needEnqueue_0 =
    io_fromSplit_0_req_valid
    & ~(io_redirect_valid
        & (io_redirect_bits_level
           & {io_fromSplit_0_req_bits_uop_robIdx_flag,
              io_fromSplit_0_req_bits_uop_robIdx_value} == _flushItself_T_14
           | io_fromSplit_0_req_bits_uop_robIdx_flag ^ io_redirect_bits_robIdx_flag
           ^ io_fromSplit_0_req_bits_uop_robIdx_value > io_redirect_bits_robIdx_value));
  wire [4:0]         _freeCount_T = 5'(5'h10 - _freeCount_freeList_io_validCount);
  wire               _GEN = needEnqueue_0 & (|_freeCount_T);
  wire               _GEN_0 = _GEN & _freeCount_freeList_io_allocateSlot_0 == 4'h0;
  wire               _GEN_1 = _GEN & _freeCount_freeList_io_allocateSlot_0 == 4'h1;
  wire               _GEN_2 = _GEN & _freeCount_freeList_io_allocateSlot_0 == 4'h2;
  wire               _GEN_3 = _GEN & _freeCount_freeList_io_allocateSlot_0 == 4'h3;
  wire               _GEN_4 = _GEN & _freeCount_freeList_io_allocateSlot_0 == 4'h4;
  wire               _GEN_5 = _GEN & _freeCount_freeList_io_allocateSlot_0 == 4'h5;
  wire               _GEN_6 = _GEN & _freeCount_freeList_io_allocateSlot_0 == 4'h6;
  wire               _GEN_7 = _GEN & _freeCount_freeList_io_allocateSlot_0 == 4'h7;
  wire               _GEN_8 = _GEN & _freeCount_freeList_io_allocateSlot_0 == 4'h8;
  wire               _GEN_9 = _GEN & _freeCount_freeList_io_allocateSlot_0 == 4'h9;
  wire               _GEN_10 = _GEN & _freeCount_freeList_io_allocateSlot_0 == 4'hA;
  wire               _GEN_11 = _GEN & _freeCount_freeList_io_allocateSlot_0 == 4'hB;
  wire               _GEN_12 = _GEN & _freeCount_freeList_io_allocateSlot_0 == 4'hC;
  wire               _GEN_13 = _GEN & _freeCount_freeList_io_allocateSlot_0 == 4'hD;
  wire               _GEN_14 = _GEN & _freeCount_freeList_io_allocateSlot_0 == 4'hE;
  wire               _GEN_15 = _GEN & (&_freeCount_freeList_io_allocateSlot_0);
  wire               _GEN_16 =
    io_fromSplit_1_req_valid
    & ~(io_redirect_valid
        & (io_redirect_bits_level
           & {io_fromSplit_1_req_bits_uop_robIdx_flag,
              io_fromSplit_1_req_bits_uop_robIdx_value} == _flushItself_T_14
           | io_fromSplit_1_req_bits_uop_robIdx_flag ^ io_redirect_bits_robIdx_flag
           ^ io_fromSplit_1_req_bits_uop_robIdx_value > io_redirect_bits_robIdx_value))
    & (|(_freeCount_T[4:1]));
  wire [3:0]         io_fromSplit_1_resp_bits_mBIndex_0 =
    needEnqueue_0
      ? _freeCount_freeList_io_allocateSlot_1
      : _freeCount_freeList_io_allocateSlot_0;
  wire               _GEN_17 = io_fromSplit_1_resp_bits_mBIndex_0 == 4'h0;
  wire               _GEN_18 = _GEN_17 | _GEN_0;
  wire               _GEN_19 = io_fromSplit_1_resp_bits_mBIndex_0 == 4'h1;
  wire               _GEN_20 = _GEN_19 | _GEN_1;
  wire               _GEN_21 = io_fromSplit_1_resp_bits_mBIndex_0 == 4'h2;
  wire               _GEN_22 = _GEN_21 | _GEN_2;
  wire               _GEN_23 = io_fromSplit_1_resp_bits_mBIndex_0 == 4'h3;
  wire               _GEN_24 = _GEN_23 | _GEN_3;
  wire               _GEN_25 = io_fromSplit_1_resp_bits_mBIndex_0 == 4'h4;
  wire               _GEN_26 = _GEN_25 | _GEN_4;
  wire               _GEN_27 = io_fromSplit_1_resp_bits_mBIndex_0 == 4'h5;
  wire               _GEN_28 = _GEN_27 | _GEN_5;
  wire               _GEN_29 = io_fromSplit_1_resp_bits_mBIndex_0 == 4'h6;
  wire               _GEN_30 = _GEN_29 | _GEN_6;
  wire               _GEN_31 = io_fromSplit_1_resp_bits_mBIndex_0 == 4'h7;
  wire               _GEN_32 = _GEN_31 | _GEN_7;
  wire               _GEN_33 = io_fromSplit_1_resp_bits_mBIndex_0 == 4'h8;
  wire               _GEN_34 = _GEN_33 | _GEN_8;
  wire               _GEN_35 = io_fromSplit_1_resp_bits_mBIndex_0 == 4'h9;
  wire               _GEN_36 = _GEN_35 | _GEN_9;
  wire               _GEN_37 = io_fromSplit_1_resp_bits_mBIndex_0 == 4'hA;
  wire               _GEN_38 = _GEN_37 | _GEN_10;
  wire               _GEN_39 = io_fromSplit_1_resp_bits_mBIndex_0 == 4'hB;
  wire               _GEN_40 = _GEN_39 | _GEN_11;
  wire               _GEN_41 = io_fromSplit_1_resp_bits_mBIndex_0 == 4'hC;
  wire               _GEN_42 = _GEN_41 | _GEN_12;
  wire               _GEN_43 = io_fromSplit_1_resp_bits_mBIndex_0 == 4'hD;
  wire               _GEN_44 = _GEN_43 | _GEN_13;
  wire               _GEN_45 = io_fromSplit_1_resp_bits_mBIndex_0 == 4'hE;
  wire               _GEN_46 = _GEN_45 | _GEN_14;
  wire               _GEN_47 = (&io_fromSplit_1_resp_bits_mBIndex_0) | _GEN_15;
  wire               needCancel_0 =
    io_redirect_valid
    & (io_redirect_bits_level
       & {entries[0].uop_robIdx_flag, entries[0].uop_robIdx_value} == _flushItself_T_14
       | entries[0].uop_robIdx_flag ^ io_redirect_bits_robIdx_flag
       ^ entries[0].uop_robIdx_value > io_redirect_bits_robIdx_value) & allocated[0];
  wire               needCancel_1 =
    io_redirect_valid
    & (io_redirect_bits_level
       & {entries[1].uop_robIdx_flag, entries[1].uop_robIdx_value} == _flushItself_T_14
       | entries[1].uop_robIdx_flag ^ io_redirect_bits_robIdx_flag
       ^ entries[1].uop_robIdx_value > io_redirect_bits_robIdx_value) & allocated[1];
  wire               needCancel_2 =
    io_redirect_valid
    & (io_redirect_bits_level
       & {entries[2].uop_robIdx_flag, entries[2].uop_robIdx_value} == _flushItself_T_14
       | entries[2].uop_robIdx_flag ^ io_redirect_bits_robIdx_flag
       ^ entries[2].uop_robIdx_value > io_redirect_bits_robIdx_value) & allocated[2];
  wire               needCancel_3 =
    io_redirect_valid
    & (io_redirect_bits_level
       & {entries[3].uop_robIdx_flag, entries[3].uop_robIdx_value} == _flushItself_T_14
       | entries[3].uop_robIdx_flag ^ io_redirect_bits_robIdx_flag
       ^ entries[3].uop_robIdx_value > io_redirect_bits_robIdx_value) & allocated[3];
  wire               needCancel_4 =
    io_redirect_valid
    & (io_redirect_bits_level
       & {entries[4].uop_robIdx_flag, entries[4].uop_robIdx_value} == _flushItself_T_14
       | entries[4].uop_robIdx_flag ^ io_redirect_bits_robIdx_flag
       ^ entries[4].uop_robIdx_value > io_redirect_bits_robIdx_value) & allocated[4];
  wire               needCancel_5 =
    io_redirect_valid
    & (io_redirect_bits_level
       & {entries[5].uop_robIdx_flag, entries[5].uop_robIdx_value} == _flushItself_T_14
       | entries[5].uop_robIdx_flag ^ io_redirect_bits_robIdx_flag
       ^ entries[5].uop_robIdx_value > io_redirect_bits_robIdx_value) & allocated[5];
  wire               needCancel_6 =
    io_redirect_valid
    & (io_redirect_bits_level
       & {entries[6].uop_robIdx_flag, entries[6].uop_robIdx_value} == _flushItself_T_14
       | entries[6].uop_robIdx_flag ^ io_redirect_bits_robIdx_flag
       ^ entries[6].uop_robIdx_value > io_redirect_bits_robIdx_value) & allocated[6];
  wire               needCancel_7 =
    io_redirect_valid
    & (io_redirect_bits_level
       & {entries[7].uop_robIdx_flag, entries[7].uop_robIdx_value} == _flushItself_T_14
       | entries[7].uop_robIdx_flag ^ io_redirect_bits_robIdx_flag
       ^ entries[7].uop_robIdx_value > io_redirect_bits_robIdx_value) & allocated[7];
  wire               needCancel_8 =
    io_redirect_valid
    & (io_redirect_bits_level
       & {entries[8].uop_robIdx_flag, entries[8].uop_robIdx_value} == _flushItself_T_14
       | entries[8].uop_robIdx_flag ^ io_redirect_bits_robIdx_flag
       ^ entries[8].uop_robIdx_value > io_redirect_bits_robIdx_value) & allocated[8];
  wire               needCancel_9 =
    io_redirect_valid
    & (io_redirect_bits_level
       & {entries[9].uop_robIdx_flag, entries[9].uop_robIdx_value} == _flushItself_T_14
       | entries[9].uop_robIdx_flag ^ io_redirect_bits_robIdx_flag
       ^ entries[9].uop_robIdx_value > io_redirect_bits_robIdx_value) & allocated[9];
  wire               needCancel_10 =
    io_redirect_valid
    & (io_redirect_bits_level
       & {entries[10].uop_robIdx_flag, entries[10].uop_robIdx_value} == _flushItself_T_14
       | entries[10].uop_robIdx_flag ^ io_redirect_bits_robIdx_flag
       ^ entries[10].uop_robIdx_value > io_redirect_bits_robIdx_value) & allocated[10];
  wire               needCancel_11 =
    io_redirect_valid
    & (io_redirect_bits_level
       & {entries[11].uop_robIdx_flag, entries[11].uop_robIdx_value} == _flushItself_T_14
       | entries[11].uop_robIdx_flag ^ io_redirect_bits_robIdx_flag
       ^ entries[11].uop_robIdx_value > io_redirect_bits_robIdx_value) & allocated[11];
  wire               needCancel_12 =
    io_redirect_valid
    & (io_redirect_bits_level
       & {entries[12].uop_robIdx_flag, entries[12].uop_robIdx_value} == _flushItself_T_14
       | entries[12].uop_robIdx_flag ^ io_redirect_bits_robIdx_flag
       ^ entries[12].uop_robIdx_value > io_redirect_bits_robIdx_value) & allocated[12];
  wire               needCancel_13 =
    io_redirect_valid
    & (io_redirect_bits_level
       & {entries[13].uop_robIdx_flag, entries[13].uop_robIdx_value} == _flushItself_T_14
       | entries[13].uop_robIdx_flag ^ io_redirect_bits_robIdx_flag
       ^ entries[13].uop_robIdx_value > io_redirect_bits_robIdx_value) & allocated[13];
  wire               needCancel_14 =
    io_redirect_valid
    & (io_redirect_bits_level
       & {entries[14].uop_robIdx_flag, entries[14].uop_robIdx_value} == _flushItself_T_14
       | entries[14].uop_robIdx_flag ^ io_redirect_bits_robIdx_flag
       ^ entries[14].uop_robIdx_value > io_redirect_bits_robIdx_value) & allocated[14];
  wire               needCancel_15 =
    io_redirect_valid
    & (io_redirect_bits_level
       & {entries[15].uop_robIdx_flag, entries[15].uop_robIdx_value} == _flushItself_T_14
       | entries[15].uop_robIdx_flag ^ io_redirect_bits_robIdx_flag
       ^ entries[15].uop_robIdx_value > io_redirect_bits_robIdx_value) & allocated[15];
  reg                mergePortMatrixHasExcpWrap_0_0;
  reg                mergePortMatrixHasExcpWrap_0_1;
  reg                mergePortMatrixHasExcpWrap_0_2;
  reg                mergePortMatrixHasExcpWrap_1_1;
  reg                mergePortMatrixHasExcpWrap_1_2;
  reg                portHasExcp_2;
  reg                mergedByPrevPortVecWrap_1;
  reg                mergedByPrevPortVecWrap_2;
  reg                pipeValidReg_0;
  reg                pipeValidReg_1;
  reg                pipeValidReg_2;
  reg  [3:0]         pipeBitsReg_0_mBIndex;
  reg  [3:0]         pipeBitsReg_0_trigger;
  reg                pipeBitsReg_0_exceptionVec_3;
  reg                pipeBitsReg_0_exceptionVec_4;
  reg                pipeBitsReg_0_exceptionVec_5;
  reg                pipeBitsReg_0_exceptionVec_13;
  reg                pipeBitsReg_0_exceptionVec_19;
  reg                pipeBitsReg_0_exceptionVec_21;
  reg  [63:0]        pipeBitsReg_0_vaddr;
  reg                pipeBitsReg_0_vaNeedExt;
  reg  [63:0]        pipeBitsReg_0_gpaddr;
  reg  [7:0]         pipeBitsReg_0_vstart;
  reg  [7:0]         pipeBitsReg_0_elemIdx;
  reg  [15:0]        pipeBitsReg_0_mask;
  reg  [3:0]         pipeBitsReg_1_mBIndex;
  reg  [3:0]         pipeBitsReg_1_trigger;
  reg                pipeBitsReg_1_exceptionVec_3;
  reg                pipeBitsReg_1_exceptionVec_4;
  reg                pipeBitsReg_1_exceptionVec_5;
  reg                pipeBitsReg_1_exceptionVec_13;
  reg                pipeBitsReg_1_exceptionVec_19;
  reg                pipeBitsReg_1_exceptionVec_21;
  reg  [63:0]        pipeBitsReg_1_vaddr;
  reg                pipeBitsReg_1_vaNeedExt;
  reg  [63:0]        pipeBitsReg_1_gpaddr;
  reg  [7:0]         pipeBitsReg_1_vstart;
  reg  [7:0]         pipeBitsReg_1_elemIdx;
  reg  [15:0]        pipeBitsReg_1_mask;
  reg  [3:0]         pipeBitsReg_2_mBIndex;
  reg  [3:0]         pipeBitsReg_2_trigger;
  reg                pipeBitsReg_2_exceptionVec_3;
  reg                pipeBitsReg_2_exceptionVec_4;
  reg                pipeBitsReg_2_exceptionVec_5;
  reg                pipeBitsReg_2_exceptionVec_13;
  reg                pipeBitsReg_2_exceptionVec_19;
  reg                pipeBitsReg_2_exceptionVec_21;
  reg  [63:0]        pipeBitsReg_2_vaddr;
  reg                pipeBitsReg_2_vaNeedExt;
  reg  [63:0]        pipeBitsReg_2_gpaddr;
  reg  [7:0]         pipeBitsReg_2_vstart;
  reg  [7:0]         pipeBitsReg_2_elemIdx;
  reg  [15:0]        pipeBitsReg_2_mask;
  wire [15:0][127:0] _GEN_48 =
    {{entries[15].data},
     {entries[14].data},
     {entries[13].data},
     {entries[12].data},
     {entries[11].data},
     {entries[10].data},
     {entries[9].data},
     {entries[8].data},
     {entries[7].data},
     {entries[6].data},
     {entries[5].data},
     {entries[4].data},
     {entries[3].data},
     {entries[2].data},
     {entries[1].data},
     {entries[0].data}};
  reg  [7:0]         wbElemIdxInField_0;
  reg  [7:0]         wbElemIdxInField_1;
  reg  [7:0]         wbElemIdxInField_2;
  wire [15:0][15:0]  _GEN_49 =
    {{entries[15].mask},
     {entries[14].mask},
     {entries[13].mask},
     {entries[12].mask},
     {entries[11].mask},
     {entries[10].mask},
     {entries[9].mask},
     {entries[8].mask},
     {entries[7].mask},
     {entries[6].mask},
     {entries[5].mask},
     {entries[4].mask},
     {entries[3].mask},
     {entries[2].mask},
     {entries[1].mask},
     {entries[0].mask}};
  wire [15:0]        _GEN_50 =
    {{entries[15].exceptionVec_3},
     {entries[14].exceptionVec_3},
     {entries[13].exceptionVec_3},
     {entries[12].exceptionVec_3},
     {entries[11].exceptionVec_3},
     {entries[10].exceptionVec_3},
     {entries[9].exceptionVec_3},
     {entries[8].exceptionVec_3},
     {entries[7].exceptionVec_3},
     {entries[6].exceptionVec_3},
     {entries[5].exceptionVec_3},
     {entries[4].exceptionVec_3},
     {entries[3].exceptionVec_3},
     {entries[2].exceptionVec_3},
     {entries[1].exceptionVec_3},
     {entries[0].exceptionVec_3}};
  wire [15:0]        _GEN_51 =
    {{entries[15].exceptionVec_4},
     {entries[14].exceptionVec_4},
     {entries[13].exceptionVec_4},
     {entries[12].exceptionVec_4},
     {entries[11].exceptionVec_4},
     {entries[10].exceptionVec_4},
     {entries[9].exceptionVec_4},
     {entries[8].exceptionVec_4},
     {entries[7].exceptionVec_4},
     {entries[6].exceptionVec_4},
     {entries[5].exceptionVec_4},
     {entries[4].exceptionVec_4},
     {entries[3].exceptionVec_4},
     {entries[2].exceptionVec_4},
     {entries[1].exceptionVec_4},
     {entries[0].exceptionVec_4}};
  wire [15:0]        _GEN_52 =
    {{entries[15].exceptionVec_5},
     {entries[14].exceptionVec_5},
     {entries[13].exceptionVec_5},
     {entries[12].exceptionVec_5},
     {entries[11].exceptionVec_5},
     {entries[10].exceptionVec_5},
     {entries[9].exceptionVec_5},
     {entries[8].exceptionVec_5},
     {entries[7].exceptionVec_5},
     {entries[6].exceptionVec_5},
     {entries[5].exceptionVec_5},
     {entries[4].exceptionVec_5},
     {entries[3].exceptionVec_5},
     {entries[2].exceptionVec_5},
     {entries[1].exceptionVec_5},
     {entries[0].exceptionVec_5}};
  wire [15:0]        _GEN_53 =
    {{entries[15].exceptionVec_13},
     {entries[14].exceptionVec_13},
     {entries[13].exceptionVec_13},
     {entries[12].exceptionVec_13},
     {entries[11].exceptionVec_13},
     {entries[10].exceptionVec_13},
     {entries[9].exceptionVec_13},
     {entries[8].exceptionVec_13},
     {entries[7].exceptionVec_13},
     {entries[6].exceptionVec_13},
     {entries[5].exceptionVec_13},
     {entries[4].exceptionVec_13},
     {entries[3].exceptionVec_13},
     {entries[2].exceptionVec_13},
     {entries[1].exceptionVec_13},
     {entries[0].exceptionVec_13}};
  wire [15:0]        _GEN_54 =
    {{entries[15].exceptionVec_19},
     {entries[14].exceptionVec_19},
     {entries[13].exceptionVec_19},
     {entries[12].exceptionVec_19},
     {entries[11].exceptionVec_19},
     {entries[10].exceptionVec_19},
     {entries[9].exceptionVec_19},
     {entries[8].exceptionVec_19},
     {entries[7].exceptionVec_19},
     {entries[6].exceptionVec_19},
     {entries[5].exceptionVec_19},
     {entries[4].exceptionVec_19},
     {entries[3].exceptionVec_19},
     {entries[2].exceptionVec_19},
     {entries[1].exceptionVec_19},
     {entries[0].exceptionVec_19}};
  wire [15:0]        _GEN_55 =
    {{entries[15].exceptionVec_21},
     {entries[14].exceptionVec_21},
     {entries[13].exceptionVec_21},
     {entries[12].exceptionVec_21},
     {entries[11].exceptionVec_21},
     {entries[10].exceptionVec_21},
     {entries[9].exceptionVec_21},
     {entries[8].exceptionVec_21},
     {entries[7].exceptionVec_21},
     {entries[6].exceptionVec_21},
     {entries[5].exceptionVec_21},
     {entries[4].exceptionVec_21},
     {entries[3].exceptionVec_21},
     {entries[2].exceptionVec_21},
     {entries[1].exceptionVec_21},
     {entries[0].exceptionVec_21}};
  wire [15:0][3:0]   _GEN_56 =
    {{entries[15].uop_trigger},
     {entries[14].uop_trigger},
     {entries[13].uop_trigger},
     {entries[12].uop_trigger},
     {entries[11].uop_trigger},
     {entries[10].uop_trigger},
     {entries[9].uop_trigger},
     {entries[8].uop_trigger},
     {entries[7].uop_trigger},
     {entries[6].uop_trigger},
     {entries[5].uop_trigger},
     {entries[4].uop_trigger},
     {entries[3].uop_trigger},
     {entries[2].uop_trigger},
     {entries[1].uop_trigger},
     {entries[0].uop_trigger}};
  wire [15:0][8:0]   _GEN_57 =
    {{entries[15].uop_fuOpType},
     {entries[14].uop_fuOpType},
     {entries[13].uop_fuOpType},
     {entries[12].uop_fuOpType},
     {entries[11].uop_fuOpType},
     {entries[10].uop_fuOpType},
     {entries[9].uop_fuOpType},
     {entries[8].uop_fuOpType},
     {entries[7].uop_fuOpType},
     {entries[6].uop_fuOpType},
     {entries[5].uop_fuOpType},
     {entries[4].uop_fuOpType},
     {entries[3].uop_fuOpType},
     {entries[2].uop_fuOpType},
     {entries[1].uop_fuOpType},
     {entries[0].uop_fuOpType}};
  wire [15:0][7:0]   _GEN_58 =
    {{entries[15].vl},
     {entries[14].vl},
     {entries[13].vl},
     {entries[12].vl},
     {entries[11].vl},
     {entries[10].vl},
     {entries[9].vl},
     {entries[8].vl},
     {entries[7].vl},
     {entries[6].vl},
     {entries[5].vl},
     {entries[4].vl},
     {entries[3].vl},
     {entries[2].vl},
     {entries[1].vl},
     {entries[0].vl}};
  reg                latchWbValid;
  reg  [3:0]         latchWbIndex;
  reg  [1:0]         latchFlowNum;
  wire [15:0][4:0]   _GEN_59 =
    {{entries[15].flowNum},
     {entries[14].flowNum},
     {entries[13].flowNum},
     {entries[12].flowNum},
     {entries[11].flowNum},
     {entries[10].flowNum},
     {entries[9].flowNum},
     {entries[8].flowNum},
     {entries[7].flowNum},
     {entries[6].flowNum},
     {entries[5].flowNum},
     {entries[4].flowNum},
     {entries[3].flowNum},
     {entries[2].flowNum},
     {entries[1].flowNum},
     {entries[0].flowNum}};
  wire [4:0]         _GEN_60 = _GEN_59[latchWbIndex];
  wire [4:0]         _GEN_61 = {3'h0, latchFlowNum};
  wire               _GEN_62 = 5'(_GEN_60 - _GEN_61) > _GEN_60 & latchWbValid;
  wire [15:0]        _GEN_63 =
    {{allocated[15]},
     {allocated[14]},
     {allocated[13]},
     {allocated[12]},
     {allocated[11]},
     {allocated[10]},
     {allocated[9]},
     {allocated[8]},
     {allocated[7]},
     {allocated[6]},
     {allocated[5]},
     {allocated[4]},
     {allocated[3]},
     {allocated[2]},
     {allocated[1]},
     {allocated[0]}};
  wire               _GEN_64 = ~_GEN_63[latchWbIndex] & latchWbValid;
  reg                latchWbValid_1;
  reg  [3:0]         latchWbIndex_1;
  reg  [1:0]         latchFlowNum_1;
  reg                latchMergeByPre_1;
  wire [4:0]         _GEN_65 = _GEN_59[latchWbIndex_1];
  wire [4:0]         _GEN_66 = {3'h0, latchFlowNum_1};
  wire               _GEN_67 =
    5'(_GEN_65 - _GEN_66) > _GEN_65 & latchWbValid_1 & ~latchMergeByPre_1;
  wire               _GEN_68 = ~_GEN_63[latchWbIndex_1] & latchWbValid_1;
  reg                latchWbValid_2;
  reg  [3:0]         latchWbIndex_2;
  reg                latchMergeByPre_2;
  wire [4:0]         _GEN_69 = _GEN_59[latchWbIndex_2];
  wire               _GEN_70 =
    5'(_GEN_69 - 5'h1) > _GEN_69 & latchWbValid_2 & ~latchMergeByPre_2;
  wire               _GEN_71 = ~_GEN_63[latchWbIndex_2] & latchWbValid_2;
  `ifndef SYNTHESIS
    always @(posedge clock) begin
      if (_GEN_62 & ~reset) begin
        if (`ASSERT_VERBOSE_COND_)
          $fwrite(32'h80000002, "Assertion failed\n    at LogUtils.scala:126 assert(false.B) //assert at current module for better error location\n");
        if (`STOP_COND_)
          xs_assert_v2(`__FILE__, `__LINE__);
      end
      if (_GEN_64 & ~reset) begin
        if (`ASSERT_VERBOSE_COND_)
          $fwrite(32'h80000002, "Assertion failed\n    at LogUtils.scala:126 assert(false.B) //assert at current module for better error location\n");
        if (`STOP_COND_)
          xs_assert_v2(`__FILE__, `__LINE__);
      end
      if (_GEN_67 & ~reset) begin
        if (`ASSERT_VERBOSE_COND_)
          $fwrite(32'h80000002, "Assertion failed\n    at LogUtils.scala:126 assert(false.B) //assert at current module for better error location\n");
        if (`STOP_COND_)
          xs_assert_v2(`__FILE__, `__LINE__);
      end
      if (_GEN_68 & ~reset) begin
        if (`ASSERT_VERBOSE_COND_)
          $fwrite(32'h80000002, "Assertion failed\n    at LogUtils.scala:126 assert(false.B) //assert at current module for better error location\n");
        if (`STOP_COND_)
          xs_assert_v2(`__FILE__, `__LINE__);
      end
      if (_GEN_70 & ~reset) begin
        if (`ASSERT_VERBOSE_COND_)
          $fwrite(32'h80000002, "Assertion failed\n    at LogUtils.scala:126 assert(false.B) //assert at current module for better error location\n");
        if (`STOP_COND_)
          xs_assert_v2(`__FILE__, `__LINE__);
      end
      if (_GEN_71 & ~reset) begin
        if (`ASSERT_VERBOSE_COND_)
          $fwrite(32'h80000002, "Assertion failed\n    at LogUtils.scala:126 assert(false.B) //assert at current module for better error location\n");
        if (`STOP_COND_)
          xs_assert_v2(`__FILE__, `__LINE__);
      end
    end // always @(posedge)
  `endif // not def SYNTHESIS
  wire               selOHVec_9 =
    uopFinish[9]
    & {uopFinish[0],
       uopFinish[1],
       uopFinish[2],
       uopFinish[3],
       uopFinish[4],
       uopFinish[5],
       uopFinish[6],
       uopFinish[7],
       uopFinish[8]} == 9'h0;
  wire               selOHVec_10 =
    uopFinish[10]
    & {uopFinish[0],
       uopFinish[1],
       uopFinish[2],
       uopFinish[3],
       uopFinish[4],
       uopFinish[5],
       uopFinish[6],
       uopFinish[7],
       uopFinish[8],
       uopFinish[9]} == 10'h0;
  wire               selOHVec_11 =
    uopFinish[11]
    & {uopFinish[0],
       uopFinish[1],
       uopFinish[2],
       uopFinish[3],
       uopFinish[4],
       uopFinish[5],
       uopFinish[6],
       uopFinish[7],
       uopFinish[8],
       uopFinish[9],
       uopFinish[10]} == 11'h0;
  wire               selOHVec_12 =
    uopFinish[12]
    & {uopFinish[0],
       uopFinish[1],
       uopFinish[2],
       uopFinish[3],
       uopFinish[4],
       uopFinish[5],
       uopFinish[6],
       uopFinish[7],
       uopFinish[8],
       uopFinish[9],
       uopFinish[10],
       uopFinish[11]} == 12'h0;
  wire               selOHVec_13 =
    uopFinish[13]
    & {uopFinish[0],
       uopFinish[1],
       uopFinish[2],
       uopFinish[3],
       uopFinish[4],
       uopFinish[5],
       uopFinish[6],
       uopFinish[7],
       uopFinish[8],
       uopFinish[9],
       uopFinish[10],
       uopFinish[11],
       uopFinish[12]} == 13'h0;
  wire               selOHVec_14 =
    uopFinish[14]
    & {uopFinish[0],
       uopFinish[1],
       uopFinish[2],
       uopFinish[3],
       uopFinish[4],
       uopFinish[5],
       uopFinish[6],
       uopFinish[7],
       uopFinish[8],
       uopFinish[9],
       uopFinish[10],
       uopFinish[11],
       uopFinish[12],
       uopFinish[13]} == 14'h0;
  wire               selOHVec_15 =
    uopFinish[15]
    & {uopFinish[0],
       uopFinish[1],
       uopFinish[2],
       uopFinish[3],
       uopFinish[4],
       uopFinish[5],
       uopFinish[6],
       uopFinish[7],
       uopFinish[8],
       uopFinish[9],
       uopFinish[10],
       uopFinish[11],
       uopFinish[12],
       uopFinish[13],
       uopFinish[14]} == 15'h0;
  wire [6:0]         _entryIdx_T_2 =
    {selOHVec_15,
     selOHVec_14,
     selOHVec_13,
     selOHVec_12,
     selOHVec_11,
     selOHVec_10,
     selOHVec_9}
    | {uopFinish[7]
         & {uopFinish[0],
            uopFinish[1],
            uopFinish[2],
            uopFinish[3],
            uopFinish[4],
            uopFinish[5],
            uopFinish[6]} == 7'h0,
       uopFinish[6]
         & {uopFinish[0],
            uopFinish[1],
            uopFinish[2],
            uopFinish[3],
            uopFinish[4],
            uopFinish[5]} == 6'h0,
       uopFinish[5]
         & {uopFinish[0], uopFinish[1], uopFinish[2], uopFinish[3], uopFinish[4]} == 5'h0,
       uopFinish[4] & {uopFinish[0], uopFinish[1], uopFinish[2], uopFinish[3]} == 4'h0,
       uopFinish[3] & {uopFinish[0], uopFinish[1], uopFinish[2]} == 3'h0,
       uopFinish[2] & {uopFinish[0], uopFinish[1]} == 2'h0,
       uopFinish[1] & ~uopFinish[0]};
  wire [2:0]         _entryIdx_T_4 = _entryIdx_T_2[6:4] | _entryIdx_T_2[2:0];
  wire [3:0]         entryIdx =
    {|{selOHVec_15,
       selOHVec_14,
       selOHVec_13,
       selOHVec_12,
       selOHVec_11,
       selOHVec_10,
       selOHVec_9,
       uopFinish[8]
         & {uopFinish[0],
            uopFinish[1],
            uopFinish[2],
            uopFinish[3],
            uopFinish[4],
            uopFinish[5],
            uopFinish[6],
            uopFinish[7]} == 8'h0},
     |(_entryIdx_T_2[6:3]),
     |(_entryIdx_T_4[2:1]),
     _entryIdx_T_4[2] | _entryIdx_T_4[0]};
  wire               selFire =
    (|{uopFinish[15],
       uopFinish[14],
       uopFinish[13],
       uopFinish[12],
       uopFinish[11],
       uopFinish[10],
       uopFinish[9],
       uopFinish[8],
       uopFinish[7],
       uopFinish[6],
       uopFinish[5],
       uopFinish[4],
       uopFinish[3],
       uopFinish[2],
       uopFinish[1],
       uopFinish[0]}) & _VMergebufferPipelineConnect0_io_in_ready;
  wire               _GEN_72 = entryIdx == 4'h0;
  wire               _GEN_73 = selFire & _GEN_72;
  wire               _GEN_74 = entryIdx == 4'h1;
  wire               _GEN_75 = selFire & _GEN_74;
  wire               _GEN_76 = entryIdx == 4'h2;
  wire               _GEN_77 = selFire & _GEN_76;
  wire               _GEN_78 = entryIdx == 4'h3;
  wire               _GEN_79 = selFire & _GEN_78;
  wire               _GEN_80 = entryIdx == 4'h4;
  wire               _GEN_81 = selFire & _GEN_80;
  wire               _GEN_82 = entryIdx == 4'h5;
  wire               _GEN_83 = selFire & _GEN_82;
  wire               _GEN_84 = entryIdx == 4'h6;
  wire               _GEN_85 = selFire & _GEN_84;
  wire               _GEN_86 = entryIdx == 4'h7;
  wire               _GEN_87 = selFire & _GEN_86;
  wire               _GEN_88 = entryIdx == 4'h8;
  wire               _GEN_89 = selFire & _GEN_88;
  wire               _GEN_90 = entryIdx == 4'h9;
  wire               _GEN_91 = selFire & _GEN_90;
  wire               _GEN_92 = entryIdx == 4'hA;
  wire               _GEN_93 = selFire & _GEN_92;
  wire               _GEN_94 = entryIdx == 4'hB;
  wire               _GEN_95 = selFire & _GEN_94;
  wire               _GEN_96 = entryIdx == 4'hC;
  wire               _GEN_97 = selFire & _GEN_96;
  wire               _GEN_98 = entryIdx == 4'hD;
  wire               _GEN_99 = selFire & _GEN_98;
  wire               _GEN_100 = entryIdx == 4'hE;
  wire               _GEN_101 = selFire & _GEN_100;
  wire               _GEN_102 = selFire & (&entryIdx);
  wire               feedbackValid = selFire & _GEN_63[entryIdx];
  wire [15:0]        _GEN_103 =
    {{needRSReplay[15]},
     {needRSReplay[14]},
     {needRSReplay[13]},
     {needRSReplay[12]},
     {needRSReplay[11]},
     {needRSReplay[10]},
     {needRSReplay[9]},
     {needRSReplay[8]},
     {needRSReplay[7]},
     {needRSReplay[6]},
     {needRSReplay[5]},
     {needRSReplay[4]},
     {needRSReplay[3]},
     {needRSReplay[2]},
     {needRSReplay[1]},
     {needRSReplay[0]}};
  wire [15:0]        _GEN_104 =
    {{entries[15].uop_vecWen},
     {entries[14].uop_vecWen},
     {entries[13].uop_vecWen},
     {entries[12].uop_vecWen},
     {entries[11].uop_vecWen},
     {entries[10].uop_vecWen},
     {entries[9].uop_vecWen},
     {entries[8].uop_vecWen},
     {entries[7].uop_vecWen},
     {entries[6].uop_vecWen},
     {entries[5].uop_vecWen},
     {entries[4].uop_vecWen},
     {entries[3].uop_vecWen},
     {entries[2].uop_vecWen},
     {entries[1].uop_vecWen},
     {entries[0].uop_vecWen}};
  wire [15:0]        _GEN_105 =
    {{entries[15].uop_v0Wen},
     {entries[14].uop_v0Wen},
     {entries[13].uop_v0Wen},
     {entries[12].uop_v0Wen},
     {entries[11].uop_v0Wen},
     {entries[10].uop_v0Wen},
     {entries[9].uop_v0Wen},
     {entries[8].uop_v0Wen},
     {entries[7].uop_v0Wen},
     {entries[6].uop_v0Wen},
     {entries[5].uop_v0Wen},
     {entries[4].uop_v0Wen},
     {entries[3].uop_v0Wen},
     {entries[2].uop_v0Wen},
     {entries[1].uop_v0Wen},
     {entries[0].uop_v0Wen}};
  wire [15:0]        _GEN_106 =
    {{entries[15].uop_vlWen},
     {entries[14].uop_vlWen},
     {entries[13].uop_vlWen},
     {entries[12].uop_vlWen},
     {entries[11].uop_vlWen},
     {entries[10].uop_vlWen},
     {entries[9].uop_vlWen},
     {entries[8].uop_vlWen},
     {entries[7].uop_vlWen},
     {entries[6].uop_vlWen},
     {entries[5].uop_vlWen},
     {entries[4].uop_vlWen},
     {entries[3].uop_vlWen},
     {entries[2].uop_vlWen},
     {entries[1].uop_vlWen},
     {entries[0].uop_vlWen}};
  wire [15:0]        _GEN_107 =
    {{entries[15].uop_flushPipe},
     {entries[14].uop_flushPipe},
     {entries[13].uop_flushPipe},
     {entries[12].uop_flushPipe},
     {entries[11].uop_flushPipe},
     {entries[10].uop_flushPipe},
     {entries[9].uop_flushPipe},
     {entries[8].uop_flushPipe},
     {entries[7].uop_flushPipe},
     {entries[6].uop_flushPipe},
     {entries[5].uop_flushPipe},
     {entries[4].uop_flushPipe},
     {entries[3].uop_flushPipe},
     {entries[2].uop_flushPipe},
     {entries[1].uop_flushPipe},
     {entries[0].uop_flushPipe}};
  wire [15:0]        _GEN_108 =
    {{entries[15].uop_vpu_vma},
     {entries[14].uop_vpu_vma},
     {entries[13].uop_vpu_vma},
     {entries[12].uop_vpu_vma},
     {entries[11].uop_vpu_vma},
     {entries[10].uop_vpu_vma},
     {entries[9].uop_vpu_vma},
     {entries[8].uop_vpu_vma},
     {entries[7].uop_vpu_vma},
     {entries[6].uop_vpu_vma},
     {entries[5].uop_vpu_vma},
     {entries[4].uop_vpu_vma},
     {entries[3].uop_vpu_vma},
     {entries[2].uop_vpu_vma},
     {entries[1].uop_vpu_vma},
     {entries[0].uop_vpu_vma}};
  wire [15:0]        _GEN_109 =
    {{entries[15].uop_vpu_vta},
     {entries[14].uop_vpu_vta},
     {entries[13].uop_vpu_vta},
     {entries[12].uop_vpu_vta},
     {entries[11].uop_vpu_vta},
     {entries[10].uop_vpu_vta},
     {entries[9].uop_vpu_vta},
     {entries[8].uop_vpu_vta},
     {entries[7].uop_vpu_vta},
     {entries[6].uop_vpu_vta},
     {entries[5].uop_vpu_vta},
     {entries[4].uop_vpu_vta},
     {entries[3].uop_vpu_vta},
     {entries[2].uop_vpu_vta},
     {entries[1].uop_vpu_vta},
     {entries[0].uop_vpu_vta}};
  wire [15:0][1:0]   _GEN_110 =
    {{entries[15].uop_vpu_vsew},
     {entries[14].uop_vpu_vsew},
     {entries[13].uop_vpu_vsew},
     {entries[12].uop_vpu_vsew},
     {entries[11].uop_vpu_vsew},
     {entries[10].uop_vpu_vsew},
     {entries[9].uop_vpu_vsew},
     {entries[8].uop_vpu_vsew},
     {entries[7].uop_vpu_vsew},
     {entries[6].uop_vpu_vsew},
     {entries[5].uop_vpu_vsew},
     {entries[4].uop_vpu_vsew},
     {entries[3].uop_vpu_vsew},
     {entries[2].uop_vpu_vsew},
     {entries[1].uop_vpu_vsew},
     {entries[0].uop_vpu_vsew}};
  wire [15:0][2:0]   _GEN_111 =
    {{entries[15].uop_vpu_vlmul},
     {entries[14].uop_vpu_vlmul},
     {entries[13].uop_vpu_vlmul},
     {entries[12].uop_vpu_vlmul},
     {entries[11].uop_vpu_vlmul},
     {entries[10].uop_vpu_vlmul},
     {entries[9].uop_vpu_vlmul},
     {entries[8].uop_vpu_vlmul},
     {entries[7].uop_vpu_vlmul},
     {entries[6].uop_vpu_vlmul},
     {entries[5].uop_vpu_vlmul},
     {entries[4].uop_vpu_vlmul},
     {entries[3].uop_vpu_vlmul},
     {entries[2].uop_vpu_vlmul},
     {entries[1].uop_vpu_vlmul},
     {entries[0].uop_vpu_vlmul}};
  wire [15:0]        _GEN_112 =
    {{entries[15].uop_vpu_vm},
     {entries[14].uop_vpu_vm},
     {entries[13].uop_vpu_vm},
     {entries[12].uop_vpu_vm},
     {entries[11].uop_vpu_vm},
     {entries[10].uop_vpu_vm},
     {entries[9].uop_vpu_vm},
     {entries[8].uop_vpu_vm},
     {entries[7].uop_vpu_vm},
     {entries[6].uop_vpu_vm},
     {entries[5].uop_vpu_vm},
     {entries[4].uop_vpu_vm},
     {entries[3].uop_vpu_vm},
     {entries[2].uop_vpu_vm},
     {entries[1].uop_vpu_vm},
     {entries[0].uop_vpu_vm}};
  wire [15:0][6:0]   _GEN_113 =
    {{entries[15].uop_vpu_vuopIdx},
     {entries[14].uop_vpu_vuopIdx},
     {entries[13].uop_vpu_vuopIdx},
     {entries[12].uop_vpu_vuopIdx},
     {entries[11].uop_vpu_vuopIdx},
     {entries[10].uop_vpu_vuopIdx},
     {entries[9].uop_vpu_vuopIdx},
     {entries[8].uop_vpu_vuopIdx},
     {entries[7].uop_vpu_vuopIdx},
     {entries[6].uop_vpu_vuopIdx},
     {entries[5].uop_vpu_vuopIdx},
     {entries[4].uop_vpu_vuopIdx},
     {entries[3].uop_vpu_vuopIdx},
     {entries[2].uop_vpu_vuopIdx},
     {entries[1].uop_vpu_vuopIdx},
     {entries[0].uop_vpu_vuopIdx}};
  wire [15:0][2:0]   _GEN_114 =
    {{entries[15].uop_vpu_nf},
     {entries[14].uop_vpu_nf},
     {entries[13].uop_vpu_nf},
     {entries[12].uop_vpu_nf},
     {entries[11].uop_vpu_nf},
     {entries[10].uop_vpu_nf},
     {entries[9].uop_vpu_nf},
     {entries[8].uop_vpu_nf},
     {entries[7].uop_vpu_nf},
     {entries[6].uop_vpu_nf},
     {entries[5].uop_vpu_nf},
     {entries[4].uop_vpu_nf},
     {entries[3].uop_vpu_nf},
     {entries[2].uop_vpu_nf},
     {entries[1].uop_vpu_nf},
     {entries[0].uop_vpu_nf}};
  wire [15:0][1:0]   _GEN_115 =
    {{entries[15].uop_vpu_veew},
     {entries[14].uop_vpu_veew},
     {entries[13].uop_vpu_veew},
     {entries[12].uop_vpu_veew},
     {entries[11].uop_vpu_veew},
     {entries[10].uop_vpu_veew},
     {entries[9].uop_vpu_veew},
     {entries[8].uop_vpu_veew},
     {entries[7].uop_vpu_veew},
     {entries[6].uop_vpu_veew},
     {entries[5].uop_vpu_veew},
     {entries[4].uop_vpu_veew},
     {entries[3].uop_vpu_veew},
     {entries[2].uop_vpu_veew},
     {entries[1].uop_vpu_veew},
     {entries[0].uop_vpu_veew}};
  wire [15:0][6:0]   _GEN_116 =
    {{entries[15].uop_uopIdx},
     {entries[14].uop_uopIdx},
     {entries[13].uop_uopIdx},
     {entries[12].uop_uopIdx},
     {entries[11].uop_uopIdx},
     {entries[10].uop_uopIdx},
     {entries[9].uop_uopIdx},
     {entries[8].uop_uopIdx},
     {entries[7].uop_uopIdx},
     {entries[6].uop_uopIdx},
     {entries[5].uop_uopIdx},
     {entries[4].uop_uopIdx},
     {entries[3].uop_uopIdx},
     {entries[2].uop_uopIdx},
     {entries[1].uop_uopIdx},
     {entries[0].uop_uopIdx}};
  wire [15:0][7:0]   _GEN_117 =
    {{entries[15].uop_pdest},
     {entries[14].uop_pdest},
     {entries[13].uop_pdest},
     {entries[12].uop_pdest},
     {entries[11].uop_pdest},
     {entries[10].uop_pdest},
     {entries[9].uop_pdest},
     {entries[8].uop_pdest},
     {entries[7].uop_pdest},
     {entries[6].uop_pdest},
     {entries[5].uop_pdest},
     {entries[4].uop_pdest},
     {entries[3].uop_pdest},
     {entries[2].uop_pdest},
     {entries[1].uop_pdest},
     {entries[0].uop_pdest}};
  wire [15:0]        _GEN_118 =
    {{entries[15].uop_robIdx_flag},
     {entries[14].uop_robIdx_flag},
     {entries[13].uop_robIdx_flag},
     {entries[12].uop_robIdx_flag},
     {entries[11].uop_robIdx_flag},
     {entries[10].uop_robIdx_flag},
     {entries[9].uop_robIdx_flag},
     {entries[8].uop_robIdx_flag},
     {entries[7].uop_robIdx_flag},
     {entries[6].uop_robIdx_flag},
     {entries[5].uop_robIdx_flag},
     {entries[4].uop_robIdx_flag},
     {entries[3].uop_robIdx_flag},
     {entries[2].uop_robIdx_flag},
     {entries[1].uop_robIdx_flag},
     {entries[0].uop_robIdx_flag}};
  wire [15:0][7:0]   _GEN_119 =
    {{entries[15].uop_robIdx_value},
     {entries[14].uop_robIdx_value},
     {entries[13].uop_robIdx_value},
     {entries[12].uop_robIdx_value},
     {entries[11].uop_robIdx_value},
     {entries[10].uop_robIdx_value},
     {entries[9].uop_robIdx_value},
     {entries[8].uop_robIdx_value},
     {entries[7].uop_robIdx_value},
     {entries[6].uop_robIdx_value},
     {entries[5].uop_robIdx_value},
     {entries[4].uop_robIdx_value},
     {entries[3].uop_robIdx_value},
     {entries[2].uop_robIdx_value},
     {entries[1].uop_robIdx_value},
     {entries[0].uop_robIdx_value}};
  wire [15:0][63:0]  _GEN_120 =
    {{entries[15].uop_debugInfo_enqRsTime},
     {entries[14].uop_debugInfo_enqRsTime},
     {entries[13].uop_debugInfo_enqRsTime},
     {entries[12].uop_debugInfo_enqRsTime},
     {entries[11].uop_debugInfo_enqRsTime},
     {entries[10].uop_debugInfo_enqRsTime},
     {entries[9].uop_debugInfo_enqRsTime},
     {entries[8].uop_debugInfo_enqRsTime},
     {entries[7].uop_debugInfo_enqRsTime},
     {entries[6].uop_debugInfo_enqRsTime},
     {entries[5].uop_debugInfo_enqRsTime},
     {entries[4].uop_debugInfo_enqRsTime},
     {entries[3].uop_debugInfo_enqRsTime},
     {entries[2].uop_debugInfo_enqRsTime},
     {entries[1].uop_debugInfo_enqRsTime},
     {entries[0].uop_debugInfo_enqRsTime}};
  wire [15:0][63:0]  _GEN_121 =
    {{entries[15].uop_debugInfo_selectTime},
     {entries[14].uop_debugInfo_selectTime},
     {entries[13].uop_debugInfo_selectTime},
     {entries[12].uop_debugInfo_selectTime},
     {entries[11].uop_debugInfo_selectTime},
     {entries[10].uop_debugInfo_selectTime},
     {entries[9].uop_debugInfo_selectTime},
     {entries[8].uop_debugInfo_selectTime},
     {entries[7].uop_debugInfo_selectTime},
     {entries[6].uop_debugInfo_selectTime},
     {entries[5].uop_debugInfo_selectTime},
     {entries[4].uop_debugInfo_selectTime},
     {entries[3].uop_debugInfo_selectTime},
     {entries[2].uop_debugInfo_selectTime},
     {entries[1].uop_debugInfo_selectTime},
     {entries[0].uop_debugInfo_selectTime}};
  wire [15:0][63:0]  _GEN_122 =
    {{entries[15].uop_debugInfo_issueTime},
     {entries[14].uop_debugInfo_issueTime},
     {entries[13].uop_debugInfo_issueTime},
     {entries[12].uop_debugInfo_issueTime},
     {entries[11].uop_debugInfo_issueTime},
     {entries[10].uop_debugInfo_issueTime},
     {entries[9].uop_debugInfo_issueTime},
     {entries[8].uop_debugInfo_issueTime},
     {entries[7].uop_debugInfo_issueTime},
     {entries[6].uop_debugInfo_issueTime},
     {entries[5].uop_debugInfo_issueTime},
     {entries[4].uop_debugInfo_issueTime},
     {entries[3].uop_debugInfo_issueTime},
     {entries[2].uop_debugInfo_issueTime},
     {entries[1].uop_debugInfo_issueTime},
     {entries[0].uop_debugInfo_issueTime}};
  wire [15:0]        _GEN_123 =
    {{entries[15].uop_replayInst},
     {entries[14].uop_replayInst},
     {entries[13].uop_replayInst},
     {entries[12].uop_replayInst},
     {entries[11].uop_replayInst},
     {entries[10].uop_replayInst},
     {entries[9].uop_replayInst},
     {entries[8].uop_replayInst},
     {entries[7].uop_replayInst},
     {entries[6].uop_replayInst},
     {entries[5].uop_replayInst},
     {entries[4].uop_replayInst},
     {entries[3].uop_replayInst},
     {entries[2].uop_replayInst},
     {entries[1].uop_replayInst},
     {entries[0].uop_replayInst}};
  wire [15:0][2:0]   _GEN_124 =
    {{entries[15].vdIdx},
     {entries[14].vdIdx},
     {entries[13].vdIdx},
     {entries[12].vdIdx},
     {entries[11].vdIdx},
     {entries[10].vdIdx},
     {entries[9].vdIdx},
     {entries[8].vdIdx},
     {entries[7].vdIdx},
     {entries[6].vdIdx},
     {entries[5].vdIdx},
     {entries[4].vdIdx},
     {entries[3].vdIdx},
     {entries[2].vdIdx},
     {entries[1].vdIdx},
     {entries[0].vdIdx}};
  wire [15:0][7:0]   _GEN_125 =
    {{entries[15].vstart},
     {entries[14].vstart},
     {entries[13].vstart},
     {entries[12].vstart},
     {entries[11].vstart},
     {entries[10].vstart},
     {entries[9].vstart},
     {entries[8].vstart},
     {entries[7].vstart},
     {entries[6].vstart},
     {entries[5].vstart},
     {entries[4].vstart},
     {entries[3].vstart},
     {entries[2].vstart},
     {entries[1].vstart},
     {entries[0].vstart}};
  wire [15:0]        _GEN_126 =
    {{entries[15].vaNeedExt},
     {entries[14].vaNeedExt},
     {entries[13].vaNeedExt},
     {entries[12].vaNeedExt},
     {entries[11].vaNeedExt},
     {entries[10].vaNeedExt},
     {entries[9].vaNeedExt},
     {entries[8].vaNeedExt},
     {entries[7].vaNeedExt},
     {entries[6].vaNeedExt},
     {entries[5].vaNeedExt},
     {entries[4].vaNeedExt},
     {entries[3].vaNeedExt},
     {entries[2].vaNeedExt},
     {entries[1].vaNeedExt},
     {entries[0].vaNeedExt}};
  wire [15:0][63:0]  _GEN_127 =
    {{entries[15].vaddr},
     {entries[14].vaddr},
     {entries[13].vaddr},
     {entries[12].vaddr},
     {entries[11].vaddr},
     {entries[10].vaddr},
     {entries[9].vaddr},
     {entries[8].vaddr},
     {entries[7].vaddr},
     {entries[6].vaddr},
     {entries[5].vaddr},
     {entries[4].vaddr},
     {entries[3].vaddr},
     {entries[2].vaddr},
     {entries[1].vaddr},
     {entries[0].vaddr}};
  wire [15:0][49:0]  _GEN_128 =
    {{entries[15].gpaddr},
     {entries[14].gpaddr},
     {entries[13].gpaddr},
     {entries[12].gpaddr},
     {entries[11].gpaddr},
     {entries[10].gpaddr},
     {entries[9].gpaddr},
     {entries[8].gpaddr},
     {entries[7].gpaddr},
     {entries[6].gpaddr},
     {entries[5].gpaddr},
     {entries[4].gpaddr},
     {entries[3].gpaddr},
     {entries[2].gpaddr},
     {entries[1].gpaddr},
     {entries[0].gpaddr}};
  wire [8:0]         _flushItself_T_1 = {_GEN_118[entryIdx], _GEN_119[entryIdx]};
  wire               differentFlag = _GEN_118[entryIdx] ^ io_redirect_bits_robIdx_flag;
  wire               compare = _GEN_119[entryIdx] > io_redirect_bits_robIdx_value;
  wire               pipelineOut_0_valid =
    feedbackValid & ~_GEN_103[entryIdx]
    & ~(io_redirect_valid
        & (io_redirect_bits_level & _flushItself_T_1 == _flushItself_T_14 | differentFlag
           ^ compare));
  wire [5:0]         _GEN_129 =
    {_GEN_55[entryIdx],
     _GEN_54[entryIdx],
     _GEN_53[entryIdx],
     _GEN_52[entryIdx],
     _GEN_51[entryIdx],
     _GEN_50[entryIdx]};
  wire               sel_1 = uopFinish[14] & ~uopFinish[15];
  wire               sel_2 = uopFinish[13] & {uopFinish[15], uopFinish[14]} == 2'h0;
  wire               sel_3 =
    uopFinish[12] & {uopFinish[15], uopFinish[14], uopFinish[13]} == 3'h0;
  wire               sel_4 =
    uopFinish[11] & {uopFinish[15], uopFinish[14], uopFinish[13], uopFinish[12]} == 4'h0;
  wire               sel_5 =
    uopFinish[10]
    & {uopFinish[15], uopFinish[14], uopFinish[13], uopFinish[12], uopFinish[11]} == 5'h0;
  wire               sel_6 =
    uopFinish[9]
    & {uopFinish[15],
       uopFinish[14],
       uopFinish[13],
       uopFinish[12],
       uopFinish[11],
       uopFinish[10]} == 6'h0;
  wire [6:0]         _entryIdx_T_12 =
    {uopFinish[15], sel_1, sel_2, sel_3, sel_4, sel_5, sel_6}
    | {uopFinish[7]
         & {uopFinish[15],
            uopFinish[14],
            uopFinish[13],
            uopFinish[12],
            uopFinish[11],
            uopFinish[10],
            uopFinish[9],
            uopFinish[8]} == 8'h0,
       uopFinish[6]
         & {uopFinish[15],
            uopFinish[14],
            uopFinish[13],
            uopFinish[12],
            uopFinish[11],
            uopFinish[10],
            uopFinish[9],
            uopFinish[8],
            uopFinish[7]} == 9'h0,
       uopFinish[5]
         & {uopFinish[15],
            uopFinish[14],
            uopFinish[13],
            uopFinish[12],
            uopFinish[11],
            uopFinish[10],
            uopFinish[9],
            uopFinish[8],
            uopFinish[7],
            uopFinish[6]} == 10'h0,
       uopFinish[4]
         & {uopFinish[15],
            uopFinish[14],
            uopFinish[13],
            uopFinish[12],
            uopFinish[11],
            uopFinish[10],
            uopFinish[9],
            uopFinish[8],
            uopFinish[7],
            uopFinish[6],
            uopFinish[5]} == 11'h0,
       uopFinish[3]
         & {uopFinish[15],
            uopFinish[14],
            uopFinish[13],
            uopFinish[12],
            uopFinish[11],
            uopFinish[10],
            uopFinish[9],
            uopFinish[8],
            uopFinish[7],
            uopFinish[6],
            uopFinish[5],
            uopFinish[4]} == 12'h0,
       uopFinish[2]
         & {uopFinish[15],
            uopFinish[14],
            uopFinish[13],
            uopFinish[12],
            uopFinish[11],
            uopFinish[10],
            uopFinish[9],
            uopFinish[8],
            uopFinish[7],
            uopFinish[6],
            uopFinish[5],
            uopFinish[4],
            uopFinish[3]} == 13'h0,
       uopFinish[1]
         & {uopFinish[15],
            uopFinish[14],
            uopFinish[13],
            uopFinish[12],
            uopFinish[11],
            uopFinish[10],
            uopFinish[9],
            uopFinish[8],
            uopFinish[7],
            uopFinish[6],
            uopFinish[5],
            uopFinish[4],
            uopFinish[3],
            uopFinish[2]} == 14'h0};
  wire [2:0]         _entryIdx_T_14 = _entryIdx_T_12[6:4] | _entryIdx_T_12[2:0];
  wire [3:0]         entryIdx_1 =
    {|{uopFinish[15],
       sel_1,
       sel_2,
       sel_3,
       sel_4,
       sel_5,
       sel_6,
       uopFinish[8]
         & {uopFinish[15],
            uopFinish[14],
            uopFinish[13],
            uopFinish[12],
            uopFinish[11],
            uopFinish[10],
            uopFinish[9]} == 7'h0},
     |(_entryIdx_T_12[6:3]),
     |(_entryIdx_T_14[2:1]),
     _entryIdx_T_14[2] | _entryIdx_T_14[0]};
  wire               selFire_1 =
    (uopFinish[0]
     & (|{uopFinish[15],
          uopFinish[14],
          uopFinish[13],
          uopFinish[12],
          uopFinish[11],
          uopFinish[10],
          uopFinish[9],
          uopFinish[8],
          uopFinish[7],
          uopFinish[6],
          uopFinish[5],
          uopFinish[4],
          uopFinish[3],
          uopFinish[2],
          uopFinish[1]}) | uopFinish[1]
     & (|{uopFinish[15],
          uopFinish[14],
          uopFinish[13],
          uopFinish[12],
          uopFinish[11],
          uopFinish[10],
          uopFinish[9],
          uopFinish[8],
          uopFinish[7],
          uopFinish[6],
          uopFinish[5],
          uopFinish[4],
          uopFinish[3],
          uopFinish[2]}) | uopFinish[2]
     & (|{uopFinish[15],
          uopFinish[14],
          uopFinish[13],
          uopFinish[12],
          uopFinish[11],
          uopFinish[10],
          uopFinish[9],
          uopFinish[8],
          uopFinish[7],
          uopFinish[6],
          uopFinish[5],
          uopFinish[4],
          uopFinish[3]}) | uopFinish[3]
     & (|{uopFinish[15],
          uopFinish[14],
          uopFinish[13],
          uopFinish[12],
          uopFinish[11],
          uopFinish[10],
          uopFinish[9],
          uopFinish[8],
          uopFinish[7],
          uopFinish[6],
          uopFinish[5],
          uopFinish[4]}) | uopFinish[4]
     & (|{uopFinish[15],
          uopFinish[14],
          uopFinish[13],
          uopFinish[12],
          uopFinish[11],
          uopFinish[10],
          uopFinish[9],
          uopFinish[8],
          uopFinish[7],
          uopFinish[6],
          uopFinish[5]}) | uopFinish[5]
     & (|{uopFinish[15],
          uopFinish[14],
          uopFinish[13],
          uopFinish[12],
          uopFinish[11],
          uopFinish[10],
          uopFinish[9],
          uopFinish[8],
          uopFinish[7],
          uopFinish[6]}) | uopFinish[6]
     & (|{uopFinish[15],
          uopFinish[14],
          uopFinish[13],
          uopFinish[12],
          uopFinish[11],
          uopFinish[10],
          uopFinish[9],
          uopFinish[8],
          uopFinish[7]}) | uopFinish[7]
     & (|{uopFinish[15],
          uopFinish[14],
          uopFinish[13],
          uopFinish[12],
          uopFinish[11],
          uopFinish[10],
          uopFinish[9],
          uopFinish[8]}) | uopFinish[8]
     & (|{uopFinish[15],
          uopFinish[14],
          uopFinish[13],
          uopFinish[12],
          uopFinish[11],
          uopFinish[10],
          uopFinish[9]}) | uopFinish[9]
     & (|{uopFinish[15],
          uopFinish[14],
          uopFinish[13],
          uopFinish[12],
          uopFinish[11],
          uopFinish[10]}) | uopFinish[10]
     & (|{uopFinish[15], uopFinish[14], uopFinish[13], uopFinish[12], uopFinish[11]})
     | uopFinish[11] & (|{uopFinish[15], uopFinish[14], uopFinish[13], uopFinish[12]})
     | uopFinish[12] & (|{uopFinish[15], uopFinish[14], uopFinish[13]}) | uopFinish[13]
     & (|{uopFinish[15], uopFinish[14]}) | uopFinish[14] & uopFinish[15])
    & _VMergebufferPipelineConnect1_io_in_ready;
  wire               _GEN_130 = entryIdx_1 == 4'h0;
  wire               _GEN_131 = selFire_1 & _GEN_130;
  assign freeMaskVec_0 =
    _GEN_131 ? _GEN_63[entryIdx_1] : _GEN_73 ? _GEN_63[entryIdx] : needCancel_0;
  wire               _GEN_132 = entryIdx_1 == 4'h1;
  wire               _GEN_133 = selFire_1 & _GEN_132;
  assign freeMaskVec_1 =
    _GEN_133 ? _GEN_63[entryIdx_1] : _GEN_75 ? _GEN_63[entryIdx] : needCancel_1;
  wire               _GEN_134 = entryIdx_1 == 4'h2;
  wire               _GEN_135 = selFire_1 & _GEN_134;
  assign freeMaskVec_2 =
    _GEN_135 ? _GEN_63[entryIdx_1] : _GEN_77 ? _GEN_63[entryIdx] : needCancel_2;
  wire               _GEN_136 = entryIdx_1 == 4'h3;
  wire               _GEN_137 = selFire_1 & _GEN_136;
  assign freeMaskVec_3 =
    _GEN_137 ? _GEN_63[entryIdx_1] : _GEN_79 ? _GEN_63[entryIdx] : needCancel_3;
  wire               _GEN_138 = entryIdx_1 == 4'h4;
  wire               _GEN_139 = selFire_1 & _GEN_138;
  assign freeMaskVec_4 =
    _GEN_139 ? _GEN_63[entryIdx_1] : _GEN_81 ? _GEN_63[entryIdx] : needCancel_4;
  wire               _GEN_140 = entryIdx_1 == 4'h5;
  wire               _GEN_141 = selFire_1 & _GEN_140;
  assign freeMaskVec_5 =
    _GEN_141 ? _GEN_63[entryIdx_1] : _GEN_83 ? _GEN_63[entryIdx] : needCancel_5;
  wire               _GEN_142 = entryIdx_1 == 4'h6;
  wire               _GEN_143 = selFire_1 & _GEN_142;
  assign freeMaskVec_6 =
    _GEN_143 ? _GEN_63[entryIdx_1] : _GEN_85 ? _GEN_63[entryIdx] : needCancel_6;
  wire               _GEN_144 = entryIdx_1 == 4'h7;
  wire               _GEN_145 = selFire_1 & _GEN_144;
  assign freeMaskVec_7 =
    _GEN_145 ? _GEN_63[entryIdx_1] : _GEN_87 ? _GEN_63[entryIdx] : needCancel_7;
  wire               _GEN_146 = entryIdx_1 == 4'h8;
  wire               _GEN_147 = selFire_1 & _GEN_146;
  assign freeMaskVec_8 =
    _GEN_147 ? _GEN_63[entryIdx_1] : _GEN_89 ? _GEN_63[entryIdx] : needCancel_8;
  wire               _GEN_148 = entryIdx_1 == 4'h9;
  wire               _GEN_149 = selFire_1 & _GEN_148;
  assign freeMaskVec_9 =
    _GEN_149 ? _GEN_63[entryIdx_1] : _GEN_91 ? _GEN_63[entryIdx] : needCancel_9;
  wire               _GEN_150 = entryIdx_1 == 4'hA;
  wire               _GEN_151 = selFire_1 & _GEN_150;
  assign freeMaskVec_10 =
    _GEN_151 ? _GEN_63[entryIdx_1] : _GEN_93 ? _GEN_63[entryIdx] : needCancel_10;
  wire               _GEN_152 = entryIdx_1 == 4'hB;
  wire               _GEN_153 = selFire_1 & _GEN_152;
  assign freeMaskVec_11 =
    _GEN_153 ? _GEN_63[entryIdx_1] : _GEN_95 ? _GEN_63[entryIdx] : needCancel_11;
  wire               _GEN_154 = entryIdx_1 == 4'hC;
  wire               _GEN_155 = selFire_1 & _GEN_154;
  assign freeMaskVec_12 =
    _GEN_155 ? _GEN_63[entryIdx_1] : _GEN_97 ? _GEN_63[entryIdx] : needCancel_12;
  wire               _GEN_156 = entryIdx_1 == 4'hD;
  wire               _GEN_157 = selFire_1 & _GEN_156;
  assign freeMaskVec_13 =
    _GEN_157 ? _GEN_63[entryIdx_1] : _GEN_99 ? _GEN_63[entryIdx] : needCancel_13;
  wire               _GEN_158 = entryIdx_1 == 4'hE;
  wire               _GEN_159 = selFire_1 & _GEN_158;
  assign freeMaskVec_14 =
    _GEN_159 ? _GEN_63[entryIdx_1] : _GEN_101 ? _GEN_63[entryIdx] : needCancel_14;
  wire               _GEN_160 = selFire_1 & (&entryIdx_1);
  assign freeMaskVec_15 =
    _GEN_160 ? _GEN_63[entryIdx_1] : _GEN_102 ? _GEN_63[entryIdx] : needCancel_15;
  wire               feedbackValid_1 = selFire_1 & _GEN_63[entryIdx_1];
  wire [8:0]         _flushItself_T_9 = {_GEN_118[entryIdx_1], _GEN_119[entryIdx_1]};
  wire               differentFlag_2 =
    _GEN_118[entryIdx_1] ^ io_redirect_bits_robIdx_flag;
  wire               compare_2 = _GEN_119[entryIdx_1] > io_redirect_bits_robIdx_value;
  wire               pipelineOut_1_valid =
    feedbackValid_1 & ~_GEN_103[entryIdx_1]
    & ~(io_redirect_valid
        & (io_redirect_bits_level & _flushItself_T_9 == _flushItself_T_14
           | differentFlag_2 ^ compare_2));
  wire [5:0]         _GEN_161 =
    {_GEN_55[entryIdx_1],
     _GEN_54[entryIdx_1],
     _GEN_53[entryIdx_1],
     _GEN_52[entryIdx_1],
     _GEN_51[entryIdx_1],
     _GEN_50[entryIdx_1]};
  wire               empty = _freeCount_freeList_io_validCount == 5'h0;
  wire               empty_probe;
  assign empty_probe = empty;
  wire               empty_probe_0;
  assign empty_probe_0 = empty;
  wire               exHalf_probe = _freeCount_freeList_io_validCount > 5'h8;
  reg                pipewbValidReg_0_REG;
  reg  [3:0]         wbIndexReg_0_r;
  reg  [127:0]       mergeDataReg_0_r;
  reg  [255:0]       brodenMergeDataReg;
  reg  [31:0]        brodenMergeMaskReg;
  reg  [3:0]         regOffsetReg;
  reg                isusMerge;
  reg                pipewbValidReg_1_REG;
  reg  [3:0]         wbIndexReg_1_r;
  reg  [127:0]       mergeDataReg_1_r;
  reg  [255:0]       brodenMergeDataReg_1;
  reg  [31:0]        brodenMergeMaskReg_1;
  reg                mergedByPrevPortReg_1;
  reg  [3:0]         regOffsetReg_1;
  reg                isusMerge_1;
  reg                pipewbValidReg_2_REG;
  reg  [3:0]         wbIndexReg_2_r;
  reg  [127:0]       mergeDataReg_2_r;
  reg  [255:0]       brodenMergeDataReg_2;
  reg  [31:0]        brodenMergeMaskReg_2;
  reg                mergedByPrevPortReg_2;
  reg  [3:0]         regOffsetReg_2;
  reg                isusMerge_2;
  wire [127:0]       oldData =
    pipewbValidReg_0_REG & wbIndexReg_0_r == io_fromPipeline_0_bits_mBIndex
      ? mergeDataReg_0_r
      : pipewbValidReg_1_REG & wbIndexReg_1_r == io_fromPipeline_0_bits_mBIndex
          ? mergeDataReg_1_r
          : pipewbValidReg_2_REG & wbIndexReg_2_r == io_fromPipeline_0_bits_mBIndex
              ? mergeDataReg_2_r
              : _GEN_48[io_fromPipeline_0_bits_mBIndex];
  wire [255:0]       selDataMatrix_0_0 = {128'h0, io_fromPipeline_0_bits_vecdata};
  wire [255:0]       selDataMatrix_0_1 = {io_fromPipeline_0_bits_vecdata, 128'h0};
  wire               _selMask_T = io_fromPipeline_0_bits_elemIdxInsideVd == 8'h0;
  wire [3:0][255:0]  _GEN_162 =
    {{selDataMatrix_0_1},
     {{io_fromPipeline_0_bits_vecdata, io_fromPipeline_2_bits_vecdata}},
     {{io_fromPipeline_0_bits_vecdata, io_fromPipeline_1_bits_vecdata}},
     {selDataMatrix_0_1}};
  wire [3:0][255:0]  _GEN_163 =
    {{selDataMatrix_0_0},
     {{io_fromPipeline_2_bits_vecdata, io_fromPipeline_0_bits_vecdata}},
     {{io_fromPipeline_1_bits_vecdata, io_fromPipeline_0_bits_vecdata}},
     {selDataMatrix_0_0}};
  wire [127:0]       oldData_1 =
    pipewbValidReg_0_REG & wbIndexReg_0_r == io_fromPipeline_1_bits_mBIndex
      ? mergeDataReg_0_r
      : pipewbValidReg_1_REG & wbIndexReg_1_r == io_fromPipeline_1_bits_mBIndex
          ? mergeDataReg_1_r
          : pipewbValidReg_2_REG & wbIndexReg_2_r == io_fromPipeline_1_bits_mBIndex
              ? mergeDataReg_2_r
              : _GEN_48[io_fromPipeline_1_bits_mBIndex];
  wire               _selMask_T_1 = io_fromPipeline_1_bits_elemIdxInsideVd == 8'h0;
  wire [127:0]       oldData_2 =
    pipewbValidReg_0_REG & wbIndexReg_0_r == io_fromPipeline_2_bits_mBIndex
      ? mergeDataReg_0_r
      : pipewbValidReg_1_REG & wbIndexReg_1_r == io_fromPipeline_2_bits_mBIndex
          ? mergeDataReg_1_r
          : pipewbValidReg_2_REG & wbIndexReg_2_r == io_fromPipeline_2_bits_mBIndex
              ? mergeDataReg_2_r
              : _GEN_48[io_fromPipeline_2_bits_mBIndex];
  wire               _selMask_T_2 = io_fromPipeline_2_bits_elemIdxInsideVd == 8'h0;
  wire [63:0]        _GEN_164 = {14'h0, io_fromSplit_0_req_bits_vaddr};
  wire               _GEN_165 = _GEN_16 & _GEN_17;
  wire               _GEN_166 = _GEN_16 & _GEN_19;
  wire               _GEN_167 = _GEN_16 & _GEN_21;
  wire               _GEN_168 = _GEN_16 & _GEN_23;
  wire               _GEN_169 = _GEN_16 & _GEN_25;
  wire               _GEN_170 = _GEN_16 & _GEN_27;
  wire               _GEN_171 = _GEN_16 & _GEN_29;
  wire               _GEN_172 = _GEN_16 & _GEN_31;
  wire               _GEN_173 = _GEN_16 & _GEN_33;
  wire               _GEN_174 = _GEN_16 & _GEN_35;
  wire               _GEN_175 = _GEN_16 & _GEN_37;
  wire               _GEN_176 = _GEN_16 & _GEN_39;
  wire               _GEN_177 = _GEN_16 & _GEN_41;
  wire               _GEN_178 = _GEN_16 & _GEN_43;
  wire               _GEN_179 = _GEN_16 & _GEN_45;
  wire               _GEN_180 = _GEN_16 & (&io_fromSplit_1_resp_bits_mBIndex_0);
  wire               _GEN_181 = _GEN_16 & _GEN_17 | _GEN_0;
  wire               _GEN_182 = _GEN_16 & _GEN_19 | _GEN_1;
  wire               _GEN_183 = _GEN_16 & _GEN_21 | _GEN_2;
  wire               _GEN_184 = _GEN_16 & _GEN_23 | _GEN_3;
  wire               _GEN_185 = _GEN_16 & _GEN_25 | _GEN_4;
  wire               _GEN_186 = _GEN_16 & _GEN_27 | _GEN_5;
  wire               _GEN_187 = _GEN_16 & _GEN_29 | _GEN_6;
  wire               _GEN_188 = _GEN_16 & _GEN_31 | _GEN_7;
  wire               _GEN_189 = _GEN_16 & _GEN_33 | _GEN_8;
  wire               _GEN_190 = _GEN_16 & _GEN_35 | _GEN_9;
  wire               _GEN_191 = _GEN_16 & _GEN_37 | _GEN_10;
  wire               _GEN_192 = _GEN_16 & _GEN_39 | _GEN_11;
  wire               _GEN_193 = _GEN_16 & _GEN_41 | _GEN_12;
  wire               _GEN_194 = _GEN_16 & _GEN_43 | _GEN_13;
  wire               _GEN_195 = _GEN_16 & _GEN_45 | _GEN_14;
  wire               _GEN_196 = _GEN_16 & (&io_fromSplit_1_resp_bits_mBIndex_0) | _GEN_15;
  wire [63:0]        _GEN_197 = {14'h0, io_fromSplit_1_req_bits_vaddr};
  wire               _maskWithexceptionMask_T_1 = io_fromPipeline_0_bits_trigger == 4'h1;
  wire               mergePortValid_1 =
    io_fromPipeline_1_bits_mBIndex == io_fromPipeline_0_bits_mBIndex
    & io_fromPipeline_1_valid;
  wire               _maskWithexceptionMask_T_10 = io_fromPipeline_1_bits_trigger == 4'h1;
  wire               mergePortValid_2 =
    io_fromPipeline_2_bits_mBIndex == io_fromPipeline_0_bits_mBIndex
    & io_fromPipeline_2_valid;
  wire               _maskWithexceptionMask_T_19 = io_fromPipeline_2_bits_trigger == 4'h1;
  wire               selIdx_1 =
    io_fromPipeline_2_bits_mBIndex == io_fromPipeline_1_bits_mBIndex
    & io_fromPipeline_2_valid;
  wire               mergedByPrevPortVec_1 =
    io_fromPipeline_0_bits_mBIndex == io_fromPipeline_1_bits_mBIndex
    & io_fromPipeline_0_valid;
  wire [1:0]         _mergedByPrevPortVec_2_T_4 =
    {io_fromPipeline_0_bits_mBIndex == io_fromPipeline_2_bits_mBIndex
       & io_fromPipeline_0_valid,
     io_fromPipeline_1_bits_mBIndex == io_fromPipeline_2_bits_mBIndex
       & io_fromPipeline_1_valid};
  wire [15:0][7:0]   _GEN_198 =
    {{entries[15].vlmax},
     {entries[14].vlmax},
     {entries[13].vlmax},
     {entries[12].vlmax},
     {entries[11].vlmax},
     {entries[10].vlmax},
     {entries[9].vlmax},
     {entries[8].vlmax},
     {entries[7].vlmax},
     {entries[6].vlmax},
     {entries[5].vlmax},
     {entries[4].vlmax},
     {entries[3].vlmax},
     {entries[2].vlmax},
     {entries[1].vlmax},
     {entries[0].vlmax}};
  wire               portHasExcp_0 =
    mergePortMatrixHasExcpWrap_0_0 | mergePortMatrixHasExcpWrap_0_1
    | mergePortMatrixHasExcpWrap_0_2;
  wire               portHasExcp_1 =
    mergePortMatrixHasExcpWrap_1_1 | mergePortMatrixHasExcpWrap_1_2;
  wire [8:0]         _GEN_199 = _GEN_57[pipeBitsReg_0_mBIndex];
  wire [15:0][7:0]   _GEN_200 =
    {{entries[15].elemIdx},
     {entries[14].elemIdx},
     {entries[13].elemIdx},
     {entries[12].elemIdx},
     {entries[11].elemIdx},
     {entries[10].elemIdx},
     {entries[9].elemIdx},
     {entries[8].elemIdx},
     {entries[7].elemIdx},
     {entries[6].elemIdx},
     {entries[5].elemIdx},
     {entries[4].elemIdx},
     {entries[3].elemIdx},
     {entries[2].elemIdx},
     {entries[1].elemIdx},
     {entries[0].elemIdx}};
  wire [7:0]         _GEN_201 = _GEN_58[pipeBitsReg_0_mBIndex];
  wire [15:0]        _GEN_202 =
    {{entries[15].fof},
     {entries[14].fof},
     {entries[13].fof},
     {entries[12].fof},
     {entries[11].fof},
     {entries[10].fof},
     {entries[9].fof},
     {entries[8].fof},
     {entries[7].fof},
     {entries[6].fof},
     {entries[5].fof},
     {entries[4].fof},
     {entries[3].fof},
     {entries[2].fof},
     {entries[1].fof},
     {entries[0].fof}};
  wire               entryIsUS = _GEN_199[6:5] == 2'h0 & (_GEN_199[8] ^ _GEN_199[7]);
  wire               entryExcp =
    ((|{_GEN_55[pipeBitsReg_0_mBIndex],
        _GEN_54[pipeBitsReg_0_mBIndex],
        _GEN_53[pipeBitsReg_0_mBIndex],
        _GEN_52[pipeBitsReg_0_mBIndex],
        _GEN_51[pipeBitsReg_0_mBIndex],
        _GEN_50[pipeBitsReg_0_mBIndex]}) | _GEN_56[pipeBitsReg_0_mBIndex] == 4'h1)
    & (|_GEN_49[pipeBitsReg_0_mBIndex]);
  wire               _sel_right_oldidx_T =
    mergePortMatrixHasExcpWrap_0_1 & mergePortMatrixHasExcpWrap_0_2;
  wire               _sel_right_oldidx_T_13 = wbElemIdxInField_1 < wbElemIdxInField_2;
  wire               _GEN_203 =
    _sel_right_oldidx_T
      ? _sel_right_oldidx_T_13
      : mergePortMatrixHasExcpWrap_0_1 & ~mergePortMatrixHasExcpWrap_0_2;
  wire               sel_right_oldest_valid =
    _GEN_203 ? mergePortMatrixHasExcpWrap_0_1 : mergePortMatrixHasExcpWrap_0_2;
  wire               _GEN_204 =
    mergePortMatrixHasExcpWrap_0_0 & sel_right_oldest_valid
      ? wbElemIdxInField_0 < ((_sel_right_oldidx_T
                                 ? _sel_right_oldidx_T_13
                                 : mergePortMatrixHasExcpWrap_0_1
                                   & ~mergePortMatrixHasExcpWrap_0_2)
                                ? wbElemIdxInField_1
                                : wbElemIdxInField_2)
      : mergePortMatrixHasExcpWrap_0_0 & ~sel_right_oldest_valid;
  wire [3:0]         sel_oldest_bits_trigger =
    _GEN_204
      ? pipeBitsReg_0_trigger
      : _GEN_203 ? pipeBitsReg_1_trigger : pipeBitsReg_2_trigger;
  wire               new_vec_2_3 =
    _GEN_204
      ? pipeBitsReg_0_exceptionVec_3
      : _GEN_203 ? pipeBitsReg_1_exceptionVec_3 : pipeBitsReg_2_exceptionVec_3;
  wire               new_vec_2_4 =
    _GEN_204
      ? pipeBitsReg_0_exceptionVec_4
      : _GEN_203 ? pipeBitsReg_1_exceptionVec_4 : pipeBitsReg_2_exceptionVec_4;
  wire               new_vec_2_5 =
    _GEN_204
      ? pipeBitsReg_0_exceptionVec_5
      : _GEN_203 ? pipeBitsReg_1_exceptionVec_5 : pipeBitsReg_2_exceptionVec_5;
  wire               new_vec_2_13 =
    _GEN_204
      ? pipeBitsReg_0_exceptionVec_13
      : _GEN_203 ? pipeBitsReg_1_exceptionVec_13 : pipeBitsReg_2_exceptionVec_13;
  wire               new_vec_2_19 =
    _GEN_204
      ? pipeBitsReg_0_exceptionVec_19
      : _GEN_203 ? pipeBitsReg_1_exceptionVec_19 : pipeBitsReg_2_exceptionVec_19;
  wire               new_vec_2_21 =
    _GEN_204
      ? pipeBitsReg_0_exceptionVec_21
      : _GEN_203 ? pipeBitsReg_1_exceptionVec_21 : pipeBitsReg_2_exceptionVec_21;
  wire               sel_oldest_bits_vaNeedExt =
    _GEN_204
      ? pipeBitsReg_0_vaNeedExt
      : _GEN_203 ? pipeBitsReg_1_vaNeedExt : pipeBitsReg_2_vaNeedExt;
  wire [49:0]        sel_oldest_bits_gpaddr =
    _GEN_204
      ? pipeBitsReg_0_gpaddr[49:0]
      : _GEN_203 ? pipeBitsReg_1_gpaddr[49:0] : pipeBitsReg_2_gpaddr[49:0];
  wire [7:0]         sel_oldest_bits_elemIdx =
    _GEN_204
      ? pipeBitsReg_0_elemIdx
      : _GEN_203 ? pipeBitsReg_1_elemIdx : pipeBitsReg_2_elemIdx;
  wire [15:0]        sel_oldest_bits_mask =
    _GEN_204 ? pipeBitsReg_0_mask : _GEN_203 ? pipeBitsReg_1_mask : pipeBitsReg_2_mask;
  wire [63:0]        _vaddr_T =
    64'((_GEN_204
           ? pipeBitsReg_0_vaddr
           : _GEN_203 ? pipeBitsReg_1_vaddr : pipeBitsReg_2_vaddr)
        + {60'h0,
           ~entryIsUS | sel_oldest_bits_mask[0]
             ? 4'h0
             : sel_oldest_bits_mask[1]
                 ? 4'h1
                 : sel_oldest_bits_mask[2]
                     ? 4'h2
                     : sel_oldest_bits_mask[3]
                         ? 4'h3
                         : sel_oldest_bits_mask[4]
                             ? 4'h4
                             : sel_oldest_bits_mask[5]
                                 ? 4'h5
                                 : sel_oldest_bits_mask[6]
                                     ? 4'h6
                                     : sel_oldest_bits_mask[7]
                                         ? 4'h7
                                         : sel_oldest_bits_mask[8]
                                             ? 4'h8
                                             : sel_oldest_bits_mask[9]
                                                 ? 4'h9
                                                 : sel_oldest_bits_mask[10]
                                                     ? 4'hA
                                                     : sel_oldest_bits_mask[11]
                                                         ? 4'hB
                                                         : sel_oldest_bits_mask[12]
                                                             ? 4'hC
                                                             : sel_oldest_bits_mask[13]
                                                                 ? 4'hD
                                                                 : sel_oldest_bits_mask[14]
                                                                     ? 4'hE
                                                                     : {4{sel_oldest_bits_mask[15]}}});
  wire [7:0]         vstart =
    entryIsUS
      ? (_GEN_204
           ? pipeBitsReg_0_vstart
           : _GEN_203 ? pipeBitsReg_1_vstart : pipeBitsReg_2_vstart)
      : sel_oldest_bits_elemIdx & 8'(_GEN_198[pipeBitsReg_0_mBIndex] - 8'h1);
  wire               _GEN_205 =
    (_GEN_200[pipeBitsReg_0_mBIndex] >= sel_oldest_bits_elemIdx & entryExcp
     & portHasExcp_0 | ~entryExcp & portHasExcp_0) & pipeValidReg_0;
  wire               _GEN_206 = pipeBitsReg_0_mBIndex == 4'h0;
  wire               _GEN_207 = pipeBitsReg_0_mBIndex == 4'h1;
  wire               _GEN_208 = pipeBitsReg_0_mBIndex == 4'h2;
  wire               _GEN_209 = pipeBitsReg_0_mBIndex == 4'h3;
  wire               _GEN_210 = pipeBitsReg_0_mBIndex == 4'h4;
  wire               _GEN_211 = pipeBitsReg_0_mBIndex == 4'h5;
  wire               _GEN_212 = pipeBitsReg_0_mBIndex == 4'h6;
  wire               _GEN_213 = pipeBitsReg_0_mBIndex == 4'h7;
  wire               _GEN_214 = pipeBitsReg_0_mBIndex == 4'h8;
  wire               _GEN_215 = pipeBitsReg_0_mBIndex == 4'h9;
  wire               _GEN_216 = pipeBitsReg_0_mBIndex == 4'hA;
  wire               _GEN_217 = pipeBitsReg_0_mBIndex == 4'hB;
  wire               _GEN_218 = pipeBitsReg_0_mBIndex == 4'hC;
  wire               _GEN_219 = pipeBitsReg_0_mBIndex == 4'hD;
  wire               _GEN_220 = pipeBitsReg_0_mBIndex == 4'hE;
  wire               _GEN_221 = ~_GEN_202[pipeBitsReg_0_mBIndex] | vstart == 8'h0;
  wire               _GEN_222 = ~_GEN_205 | _GEN_221 | ~_GEN_206;
  wire               _GEN_223 = ~_GEN_205 | _GEN_221 | ~_GEN_207;
  wire               _GEN_224 = ~_GEN_205 | _GEN_221 | ~_GEN_208;
  wire               _GEN_225 = ~_GEN_205 | _GEN_221 | ~_GEN_209;
  wire               _GEN_226 = ~_GEN_205 | _GEN_221 | ~_GEN_210;
  wire               _GEN_227 = ~_GEN_205 | _GEN_221 | ~_GEN_211;
  wire               _GEN_228 = ~_GEN_205 | _GEN_221 | ~_GEN_212;
  wire               _GEN_229 = ~_GEN_205 | _GEN_221 | ~_GEN_213;
  wire               _GEN_230 = ~_GEN_205 | _GEN_221 | ~_GEN_214;
  wire               _GEN_231 = ~_GEN_205 | _GEN_221 | ~_GEN_215;
  wire               _GEN_232 = ~_GEN_205 | _GEN_221 | ~_GEN_216;
  wire               _GEN_233 = ~_GEN_205 | _GEN_221 | ~_GEN_217;
  wire               _GEN_234 = ~_GEN_205 | _GEN_221 | ~_GEN_218;
  wire               _GEN_235 = ~_GEN_205 | _GEN_221 | ~_GEN_219;
  wire               _GEN_236 = ~_GEN_205 | _GEN_221 | ~_GEN_220;
  wire               _GEN_237 = ~_GEN_205 | _GEN_221 | ~(&pipeBitsReg_0_mBIndex);
  wire               _entries_vl_T = _GEN_201 < vstart;
  wire [8:0]         _GEN_238 = _GEN_57[pipeBitsReg_1_mBIndex];
  wire [7:0]         _GEN_239 = _GEN_58[pipeBitsReg_1_mBIndex];
  wire               entryIsUS_1 = _GEN_238[6:5] == 2'h0 & (_GEN_238[8] ^ _GEN_238[7]);
  wire               entryExcp_1 =
    ((|{_GEN_55[pipeBitsReg_1_mBIndex],
        _GEN_54[pipeBitsReg_1_mBIndex],
        _GEN_53[pipeBitsReg_1_mBIndex],
        _GEN_52[pipeBitsReg_1_mBIndex],
        _GEN_51[pipeBitsReg_1_mBIndex],
        _GEN_50[pipeBitsReg_1_mBIndex]}) | _GEN_56[pipeBitsReg_1_mBIndex] == 4'h1)
    & (|_GEN_49[pipeBitsReg_1_mBIndex]);
  wire               _GEN_240 =
    mergePortMatrixHasExcpWrap_1_1 & mergePortMatrixHasExcpWrap_1_2
      ? _sel_right_oldidx_T_13
      : mergePortMatrixHasExcpWrap_1_1 & ~mergePortMatrixHasExcpWrap_1_2;
  wire [3:0]         sel_oldest_1_bits_trigger =
    _GEN_240 ? pipeBitsReg_1_trigger : pipeBitsReg_2_trigger;
  wire               new_vec_3_3 =
    _GEN_240 ? pipeBitsReg_1_exceptionVec_3 : pipeBitsReg_2_exceptionVec_3;
  wire               new_vec_3_4 =
    _GEN_240 ? pipeBitsReg_1_exceptionVec_4 : pipeBitsReg_2_exceptionVec_4;
  wire               new_vec_3_5 =
    _GEN_240 ? pipeBitsReg_1_exceptionVec_5 : pipeBitsReg_2_exceptionVec_5;
  wire               new_vec_3_13 =
    _GEN_240 ? pipeBitsReg_1_exceptionVec_13 : pipeBitsReg_2_exceptionVec_13;
  wire               new_vec_3_19 =
    _GEN_240 ? pipeBitsReg_1_exceptionVec_19 : pipeBitsReg_2_exceptionVec_19;
  wire               new_vec_3_21 =
    _GEN_240 ? pipeBitsReg_1_exceptionVec_21 : pipeBitsReg_2_exceptionVec_21;
  wire               sel_oldest_1_bits_vaNeedExt =
    _GEN_240 ? pipeBitsReg_1_vaNeedExt : pipeBitsReg_2_vaNeedExt;
  wire [49:0]        sel_oldest_1_bits_gpaddr =
    _GEN_240 ? pipeBitsReg_1_gpaddr[49:0] : pipeBitsReg_2_gpaddr[49:0];
  wire [7:0]         sel_oldest_1_bits_elemIdx =
    _GEN_240 ? pipeBitsReg_1_elemIdx : pipeBitsReg_2_elemIdx;
  wire [15:0]        sel_oldest_1_bits_mask =
    _GEN_240 ? pipeBitsReg_1_mask : pipeBitsReg_2_mask;
  wire [63:0]        _vaddr_T_1 =
    64'((_GEN_240 ? pipeBitsReg_1_vaddr : pipeBitsReg_2_vaddr)
        + {60'h0,
           ~entryIsUS_1 | sel_oldest_1_bits_mask[0]
             ? 4'h0
             : sel_oldest_1_bits_mask[1]
                 ? 4'h1
                 : sel_oldest_1_bits_mask[2]
                     ? 4'h2
                     : sel_oldest_1_bits_mask[3]
                         ? 4'h3
                         : sel_oldest_1_bits_mask[4]
                             ? 4'h4
                             : sel_oldest_1_bits_mask[5]
                                 ? 4'h5
                                 : sel_oldest_1_bits_mask[6]
                                     ? 4'h6
                                     : sel_oldest_1_bits_mask[7]
                                         ? 4'h7
                                         : sel_oldest_1_bits_mask[8]
                                             ? 4'h8
                                             : sel_oldest_1_bits_mask[9]
                                                 ? 4'h9
                                                 : sel_oldest_1_bits_mask[10]
                                                     ? 4'hA
                                                     : sel_oldest_1_bits_mask[11]
                                                         ? 4'hB
                                                         : sel_oldest_1_bits_mask[12]
                                                             ? 4'hC
                                                             : sel_oldest_1_bits_mask[13]
                                                                 ? 4'hD
                                                                 : sel_oldest_1_bits_mask[14]
                                                                     ? 4'hE
                                                                     : {4{sel_oldest_1_bits_mask[15]}}});
  wire [7:0]         vstart_1 =
    entryIsUS_1
      ? (_GEN_240 ? pipeBitsReg_1_vstart : pipeBitsReg_2_vstart)
      : sel_oldest_1_bits_elemIdx & 8'(_GEN_198[pipeBitsReg_1_mBIndex] - 8'h1);
  wire               _GEN_241 =
    (_GEN_200[pipeBitsReg_1_mBIndex] >= sel_oldest_1_bits_elemIdx & entryExcp_1
     & portHasExcp_1 | ~entryExcp_1 & portHasExcp_1) & pipeValidReg_1
    & ~mergedByPrevPortVecWrap_1;
  wire               _GEN_242 = pipeBitsReg_1_mBIndex == 4'h0;
  wire               _GEN_243 = pipeBitsReg_1_mBIndex == 4'h1;
  wire               _GEN_244 = pipeBitsReg_1_mBIndex == 4'h2;
  wire               _GEN_245 = pipeBitsReg_1_mBIndex == 4'h3;
  wire               _GEN_246 = pipeBitsReg_1_mBIndex == 4'h4;
  wire               _GEN_247 = pipeBitsReg_1_mBIndex == 4'h5;
  wire               _GEN_248 = pipeBitsReg_1_mBIndex == 4'h6;
  wire               _GEN_249 = pipeBitsReg_1_mBIndex == 4'h7;
  wire               _GEN_250 = pipeBitsReg_1_mBIndex == 4'h8;
  wire               _GEN_251 = pipeBitsReg_1_mBIndex == 4'h9;
  wire               _GEN_252 = pipeBitsReg_1_mBIndex == 4'hA;
  wire               _GEN_253 = pipeBitsReg_1_mBIndex == 4'hB;
  wire               _GEN_254 = pipeBitsReg_1_mBIndex == 4'hC;
  wire               _GEN_255 = pipeBitsReg_1_mBIndex == 4'hD;
  wire               _GEN_256 = pipeBitsReg_1_mBIndex == 4'hE;
  wire               _GEN_257 = ~_GEN_202[pipeBitsReg_1_mBIndex] | vstart_1 == 8'h0;
  wire               _GEN_258 = ~_GEN_241 | _GEN_257 | ~_GEN_242;
  wire               _GEN_259 = ~_GEN_241 | _GEN_257 | ~_GEN_243;
  wire               _GEN_260 = ~_GEN_241 | _GEN_257 | ~_GEN_244;
  wire               _GEN_261 = ~_GEN_241 | _GEN_257 | ~_GEN_245;
  wire               _GEN_262 = ~_GEN_241 | _GEN_257 | ~_GEN_246;
  wire               _GEN_263 = ~_GEN_241 | _GEN_257 | ~_GEN_247;
  wire               _GEN_264 = ~_GEN_241 | _GEN_257 | ~_GEN_248;
  wire               _GEN_265 = ~_GEN_241 | _GEN_257 | ~_GEN_249;
  wire               _GEN_266 = ~_GEN_241 | _GEN_257 | ~_GEN_250;
  wire               _GEN_267 = ~_GEN_241 | _GEN_257 | ~_GEN_251;
  wire               _GEN_268 = ~_GEN_241 | _GEN_257 | ~_GEN_252;
  wire               _GEN_269 = ~_GEN_241 | _GEN_257 | ~_GEN_253;
  wire               _GEN_270 = ~_GEN_241 | _GEN_257 | ~_GEN_254;
  wire               _GEN_271 = ~_GEN_241 | _GEN_257 | ~_GEN_255;
  wire               _GEN_272 = ~_GEN_241 | _GEN_257 | ~_GEN_256;
  wire               _GEN_273 = ~_GEN_241 | _GEN_257 | ~(&pipeBitsReg_1_mBIndex);
  wire               _entries_vl_T_2 = _GEN_239 < vstart_1;
  wire [8:0]         _GEN_274 = _GEN_57[pipeBitsReg_2_mBIndex];
  wire [7:0]         _GEN_275 = _GEN_58[pipeBitsReg_2_mBIndex];
  wire               entryIsUS_2 = _GEN_274[6:5] == 2'h0 & (_GEN_274[8] ^ _GEN_274[7]);
  wire               entryExcp_2 =
    ((|{_GEN_55[pipeBitsReg_2_mBIndex],
        _GEN_54[pipeBitsReg_2_mBIndex],
        _GEN_53[pipeBitsReg_2_mBIndex],
        _GEN_52[pipeBitsReg_2_mBIndex],
        _GEN_51[pipeBitsReg_2_mBIndex],
        _GEN_50[pipeBitsReg_2_mBIndex]}) | _GEN_56[pipeBitsReg_2_mBIndex] == 4'h1)
    & (|_GEN_49[pipeBitsReg_2_mBIndex]);
  wire [63:0]        _vaddr_T_2 =
    64'(pipeBitsReg_2_vaddr
        + {60'h0,
           ~entryIsUS_2 | pipeBitsReg_2_mask[0]
             ? 4'h0
             : pipeBitsReg_2_mask[1]
                 ? 4'h1
                 : pipeBitsReg_2_mask[2]
                     ? 4'h2
                     : pipeBitsReg_2_mask[3]
                         ? 4'h3
                         : pipeBitsReg_2_mask[4]
                             ? 4'h4
                             : pipeBitsReg_2_mask[5]
                                 ? 4'h5
                                 : pipeBitsReg_2_mask[6]
                                     ? 4'h6
                                     : pipeBitsReg_2_mask[7]
                                         ? 4'h7
                                         : pipeBitsReg_2_mask[8]
                                             ? 4'h8
                                             : pipeBitsReg_2_mask[9]
                                                 ? 4'h9
                                                 : pipeBitsReg_2_mask[10]
                                                     ? 4'hA
                                                     : pipeBitsReg_2_mask[11]
                                                         ? 4'hB
                                                         : pipeBitsReg_2_mask[12]
                                                             ? 4'hC
                                                             : pipeBitsReg_2_mask[13]
                                                                 ? 4'hD
                                                                 : pipeBitsReg_2_mask[14]
                                                                     ? 4'hE
                                                                     : {4{pipeBitsReg_2_mask[15]}}});
  wire [7:0]         vstart_2 =
    entryIsUS_2
      ? pipeBitsReg_2_vstart
      : pipeBitsReg_2_elemIdx & 8'(_GEN_198[pipeBitsReg_2_mBIndex] - 8'h1);
  wire               _GEN_276 =
    (_GEN_200[pipeBitsReg_2_mBIndex] >= pipeBitsReg_2_elemIdx & entryExcp_2
     & portHasExcp_2 | ~entryExcp_2 & portHasExcp_2) & pipeValidReg_2
    & ~mergedByPrevPortVecWrap_2;
  wire               _GEN_277 = pipeBitsReg_2_mBIndex == 4'h0;
  wire               _GEN_278 = pipeBitsReg_2_mBIndex == 4'h1;
  wire               _GEN_279 = pipeBitsReg_2_mBIndex == 4'h2;
  wire               _GEN_280 = pipeBitsReg_2_mBIndex == 4'h3;
  wire               _GEN_281 = pipeBitsReg_2_mBIndex == 4'h4;
  wire               _GEN_282 = pipeBitsReg_2_mBIndex == 4'h5;
  wire               _GEN_283 = pipeBitsReg_2_mBIndex == 4'h6;
  wire               _GEN_284 = pipeBitsReg_2_mBIndex == 4'h7;
  wire               _GEN_285 = pipeBitsReg_2_mBIndex == 4'h8;
  wire               _GEN_286 = pipeBitsReg_2_mBIndex == 4'h9;
  wire               _GEN_287 = pipeBitsReg_2_mBIndex == 4'hA;
  wire               _GEN_288 = pipeBitsReg_2_mBIndex == 4'hB;
  wire               _GEN_289 = pipeBitsReg_2_mBIndex == 4'hC;
  wire               _GEN_290 = pipeBitsReg_2_mBIndex == 4'hD;
  wire               _GEN_291 = pipeBitsReg_2_mBIndex == 4'hE;
  wire               _GEN_292 = ~_GEN_202[pipeBitsReg_2_mBIndex] | vstart_2 == 8'h0;
  wire               _GEN_293 = ~_GEN_276 | _GEN_292 | ~_GEN_277;
  wire               _GEN_294 = ~_GEN_276 | _GEN_292 | ~_GEN_278;
  wire               _GEN_295 = ~_GEN_276 | _GEN_292 | ~_GEN_279;
  wire               _GEN_296 = ~_GEN_276 | _GEN_292 | ~_GEN_280;
  wire               _GEN_297 = ~_GEN_276 | _GEN_292 | ~_GEN_281;
  wire               _GEN_298 = ~_GEN_276 | _GEN_292 | ~_GEN_282;
  wire               _GEN_299 = ~_GEN_276 | _GEN_292 | ~_GEN_283;
  wire               _GEN_300 = ~_GEN_276 | _GEN_292 | ~_GEN_284;
  wire               _GEN_301 = ~_GEN_276 | _GEN_292 | ~_GEN_285;
  wire               _GEN_302 = ~_GEN_276 | _GEN_292 | ~_GEN_286;
  wire               _GEN_303 = ~_GEN_276 | _GEN_292 | ~_GEN_287;
  wire               _GEN_304 = ~_GEN_276 | _GEN_292 | ~_GEN_288;
  wire               _GEN_305 = ~_GEN_276 | _GEN_292 | ~_GEN_289;
  wire               _GEN_306 = ~_GEN_276 | _GEN_292 | ~_GEN_290;
  wire               _GEN_307 = ~_GEN_276 | _GEN_292 | ~_GEN_291;
  wire               _GEN_308 = ~_GEN_276 | _GEN_292 | ~(&pipeBitsReg_2_mBIndex);
  wire               _entries_vl_T_4 = _GEN_275 < vstart_2;
  wire [4:0]         _entries_flowNum_T = 5'(_GEN_60 - _GEN_61);
  wire               _GEN_309 = latchWbValid_1 & ~latchMergeByPre_1;
  wire [4:0]         _entries_flowNum_T_2 = 5'(_GEN_65 - _GEN_66);
  wire               _GEN_310 = latchWbValid_2 & ~latchMergeByPre_2;
  wire [4:0]         _entries_flowNum_T_4 = 5'(_GEN_69 - 5'h1);
  wire [15:0]        maskWithexceptionMask_1 =
    (io_fromPipeline_1_bits_trigger == 4'h0 | _maskWithexceptionMask_T_10
       ? ~io_fromPipeline_1_bits_vecTriggerMask
       : {16{{io_fromPipeline_1_bits_exceptionVec_21,
              io_fromPipeline_1_bits_exceptionVec_19,
              io_fromPipeline_1_bits_exceptionVec_13,
              io_fromPipeline_1_bits_exceptionVec_5,
              io_fromPipeline_1_bits_exceptionVec_4} == 5'h0}})
    & io_fromPipeline_1_bits_mask;
  wire [15:0]        maskWithexceptionMask_2 =
    (io_fromPipeline_2_bits_trigger == 4'h0 | _maskWithexceptionMask_T_19
       ? ~io_fromPipeline_2_bits_vecTriggerMask
       : {16{{io_fromPipeline_2_bits_exceptionVec_21,
              io_fromPipeline_2_bits_exceptionVec_19,
              io_fromPipeline_2_bits_exceptionVec_13,
              io_fromPipeline_2_bits_exceptionVec_5,
              io_fromPipeline_2_bits_exceptionVec_4} == 5'h0}})
    & io_fromPipeline_2_bits_mask;
  wire [127:0]       usSelData =
    (regOffsetReg == 4'h0 ? brodenMergeDataReg[127:0] : 128'h0)
    | (regOffsetReg == 4'h1 ? brodenMergeDataReg[135:8] : 128'h0)
    | (regOffsetReg == 4'h2 ? brodenMergeDataReg[143:16] : 128'h0)
    | (regOffsetReg == 4'h3 ? brodenMergeDataReg[151:24] : 128'h0)
    | (regOffsetReg == 4'h4 ? brodenMergeDataReg[159:32] : 128'h0)
    | (regOffsetReg == 4'h5 ? brodenMergeDataReg[167:40] : 128'h0)
    | (regOffsetReg == 4'h6 ? brodenMergeDataReg[175:48] : 128'h0)
    | (regOffsetReg == 4'h7 ? brodenMergeDataReg[183:56] : 128'h0)
    | (regOffsetReg == 4'h8 ? brodenMergeDataReg[191:64] : 128'h0)
    | (regOffsetReg == 4'h9 ? brodenMergeDataReg[199:72] : 128'h0)
    | (regOffsetReg == 4'hA ? brodenMergeDataReg[207:80] : 128'h0)
    | (regOffsetReg == 4'hB ? brodenMergeDataReg[215:88] : 128'h0)
    | (regOffsetReg == 4'hC ? brodenMergeDataReg[223:96] : 128'h0)
    | (regOffsetReg == 4'hD ? brodenMergeDataReg[231:104] : 128'h0)
    | (regOffsetReg == 4'hE ? brodenMergeDataReg[239:112] : 128'h0)
    | ((&regOffsetReg) ? brodenMergeDataReg[247:120] : 128'h0);
  wire [15:0]        usSelMask =
    (regOffsetReg == 4'h0 ? brodenMergeMaskReg[15:0] : 16'h0)
    | (regOffsetReg == 4'h1 ? brodenMergeMaskReg[16:1] : 16'h0)
    | (regOffsetReg == 4'h2 ? brodenMergeMaskReg[17:2] : 16'h0)
    | (regOffsetReg == 4'h3 ? brodenMergeMaskReg[18:3] : 16'h0)
    | (regOffsetReg == 4'h4 ? brodenMergeMaskReg[19:4] : 16'h0)
    | (regOffsetReg == 4'h5 ? brodenMergeMaskReg[20:5] : 16'h0)
    | (regOffsetReg == 4'h6 ? brodenMergeMaskReg[21:6] : 16'h0)
    | (regOffsetReg == 4'h7 ? brodenMergeMaskReg[22:7] : 16'h0)
    | (regOffsetReg == 4'h8 ? brodenMergeMaskReg[23:8] : 16'h0)
    | (regOffsetReg == 4'h9 ? brodenMergeMaskReg[24:9] : 16'h0)
    | (regOffsetReg == 4'hA ? brodenMergeMaskReg[25:10] : 16'h0)
    | (regOffsetReg == 4'hB ? brodenMergeMaskReg[26:11] : 16'h0)
    | (regOffsetReg == 4'hC ? brodenMergeMaskReg[27:12] : 16'h0)
    | (regOffsetReg == 4'hD ? brodenMergeMaskReg[28:13] : 16'h0)
    | (regOffsetReg == 4'hE ? brodenMergeMaskReg[29:14] : 16'h0)
    | ((&regOffsetReg) ? brodenMergeMaskReg[30:15] : 16'h0);
  wire [127:0]       _GEN_311 = _GEN_48[wbIndexReg_0_r];
  wire [127:0]       usMergeData =
    {usSelMask[15] ? usSelData[127:120] : _GEN_311[127:120],
     usSelMask[14] ? usSelData[119:112] : _GEN_311[119:112],
     usSelMask[13] ? usSelData[111:104] : _GEN_311[111:104],
     usSelMask[12] ? usSelData[103:96] : _GEN_311[103:96],
     usSelMask[11] ? usSelData[95:88] : _GEN_311[95:88],
     usSelMask[10] ? usSelData[87:80] : _GEN_311[87:80],
     usSelMask[9] ? usSelData[79:72] : _GEN_311[79:72],
     usSelMask[8] ? usSelData[71:64] : _GEN_311[71:64],
     usSelMask[7] ? usSelData[63:56] : _GEN_311[63:56],
     usSelMask[6] ? usSelData[55:48] : _GEN_311[55:48],
     usSelMask[5] ? usSelData[47:40] : _GEN_311[47:40],
     usSelMask[4] ? usSelData[39:32] : _GEN_311[39:32],
     usSelMask[3] ? usSelData[31:24] : _GEN_311[31:24],
     usSelMask[2] ? usSelData[23:16] : _GEN_311[23:16],
     usSelMask[1] ? usSelData[15:8] : _GEN_311[15:8],
     usSelMask[0] ? usSelData[7:0] : _GEN_311[7:0]};
  wire [127:0]       usSelData_1 =
    (regOffsetReg_1 == 4'h0 ? brodenMergeDataReg_1[127:0] : 128'h0)
    | (regOffsetReg_1 == 4'h1 ? brodenMergeDataReg_1[135:8] : 128'h0)
    | (regOffsetReg_1 == 4'h2 ? brodenMergeDataReg_1[143:16] : 128'h0)
    | (regOffsetReg_1 == 4'h3 ? brodenMergeDataReg_1[151:24] : 128'h0)
    | (regOffsetReg_1 == 4'h4 ? brodenMergeDataReg_1[159:32] : 128'h0)
    | (regOffsetReg_1 == 4'h5 ? brodenMergeDataReg_1[167:40] : 128'h0)
    | (regOffsetReg_1 == 4'h6 ? brodenMergeDataReg_1[175:48] : 128'h0)
    | (regOffsetReg_1 == 4'h7 ? brodenMergeDataReg_1[183:56] : 128'h0)
    | (regOffsetReg_1 == 4'h8 ? brodenMergeDataReg_1[191:64] : 128'h0)
    | (regOffsetReg_1 == 4'h9 ? brodenMergeDataReg_1[199:72] : 128'h0)
    | (regOffsetReg_1 == 4'hA ? brodenMergeDataReg_1[207:80] : 128'h0)
    | (regOffsetReg_1 == 4'hB ? brodenMergeDataReg_1[215:88] : 128'h0)
    | (regOffsetReg_1 == 4'hC ? brodenMergeDataReg_1[223:96] : 128'h0)
    | (regOffsetReg_1 == 4'hD ? brodenMergeDataReg_1[231:104] : 128'h0)
    | (regOffsetReg_1 == 4'hE ? brodenMergeDataReg_1[239:112] : 128'h0)
    | ((&regOffsetReg_1) ? brodenMergeDataReg_1[247:120] : 128'h0);
  wire [15:0]        usSelMask_1 =
    (regOffsetReg_1 == 4'h0 ? brodenMergeMaskReg_1[15:0] : 16'h0)
    | (regOffsetReg_1 == 4'h1 ? brodenMergeMaskReg_1[16:1] : 16'h0)
    | (regOffsetReg_1 == 4'h2 ? brodenMergeMaskReg_1[17:2] : 16'h0)
    | (regOffsetReg_1 == 4'h3 ? brodenMergeMaskReg_1[18:3] : 16'h0)
    | (regOffsetReg_1 == 4'h4 ? brodenMergeMaskReg_1[19:4] : 16'h0)
    | (regOffsetReg_1 == 4'h5 ? brodenMergeMaskReg_1[20:5] : 16'h0)
    | (regOffsetReg_1 == 4'h6 ? brodenMergeMaskReg_1[21:6] : 16'h0)
    | (regOffsetReg_1 == 4'h7 ? brodenMergeMaskReg_1[22:7] : 16'h0)
    | (regOffsetReg_1 == 4'h8 ? brodenMergeMaskReg_1[23:8] : 16'h0)
    | (regOffsetReg_1 == 4'h9 ? brodenMergeMaskReg_1[24:9] : 16'h0)
    | (regOffsetReg_1 == 4'hA ? brodenMergeMaskReg_1[25:10] : 16'h0)
    | (regOffsetReg_1 == 4'hB ? brodenMergeMaskReg_1[26:11] : 16'h0)
    | (regOffsetReg_1 == 4'hC ? brodenMergeMaskReg_1[27:12] : 16'h0)
    | (regOffsetReg_1 == 4'hD ? brodenMergeMaskReg_1[28:13] : 16'h0)
    | (regOffsetReg_1 == 4'hE ? brodenMergeMaskReg_1[29:14] : 16'h0)
    | ((&regOffsetReg_1) ? brodenMergeMaskReg_1[30:15] : 16'h0);
  wire [127:0]       _GEN_312 = _GEN_48[wbIndexReg_1_r];
  wire [127:0]       usMergeData_1 =
    {usSelMask_1[15] ? usSelData_1[127:120] : _GEN_312[127:120],
     usSelMask_1[14] ? usSelData_1[119:112] : _GEN_312[119:112],
     usSelMask_1[13] ? usSelData_1[111:104] : _GEN_312[111:104],
     usSelMask_1[12] ? usSelData_1[103:96] : _GEN_312[103:96],
     usSelMask_1[11] ? usSelData_1[95:88] : _GEN_312[95:88],
     usSelMask_1[10] ? usSelData_1[87:80] : _GEN_312[87:80],
     usSelMask_1[9] ? usSelData_1[79:72] : _GEN_312[79:72],
     usSelMask_1[8] ? usSelData_1[71:64] : _GEN_312[71:64],
     usSelMask_1[7] ? usSelData_1[63:56] : _GEN_312[63:56],
     usSelMask_1[6] ? usSelData_1[55:48] : _GEN_312[55:48],
     usSelMask_1[5] ? usSelData_1[47:40] : _GEN_312[47:40],
     usSelMask_1[4] ? usSelData_1[39:32] : _GEN_312[39:32],
     usSelMask_1[3] ? usSelData_1[31:24] : _GEN_312[31:24],
     usSelMask_1[2] ? usSelData_1[23:16] : _GEN_312[23:16],
     usSelMask_1[1] ? usSelData_1[15:8] : _GEN_312[15:8],
     usSelMask_1[0] ? usSelData_1[7:0] : _GEN_312[7:0]};
  wire               _GEN_313 = pipewbValidReg_1_REG & ~mergedByPrevPortReg_1;
  wire [127:0]       usSelData_2 =
    (regOffsetReg_2 == 4'h0 ? brodenMergeDataReg_2[127:0] : 128'h0)
    | (regOffsetReg_2 == 4'h1 ? brodenMergeDataReg_2[135:8] : 128'h0)
    | (regOffsetReg_2 == 4'h2 ? brodenMergeDataReg_2[143:16] : 128'h0)
    | (regOffsetReg_2 == 4'h3 ? brodenMergeDataReg_2[151:24] : 128'h0)
    | (regOffsetReg_2 == 4'h4 ? brodenMergeDataReg_2[159:32] : 128'h0)
    | (regOffsetReg_2 == 4'h5 ? brodenMergeDataReg_2[167:40] : 128'h0)
    | (regOffsetReg_2 == 4'h6 ? brodenMergeDataReg_2[175:48] : 128'h0)
    | (regOffsetReg_2 == 4'h7 ? brodenMergeDataReg_2[183:56] : 128'h0)
    | (regOffsetReg_2 == 4'h8 ? brodenMergeDataReg_2[191:64] : 128'h0)
    | (regOffsetReg_2 == 4'h9 ? brodenMergeDataReg_2[199:72] : 128'h0)
    | (regOffsetReg_2 == 4'hA ? brodenMergeDataReg_2[207:80] : 128'h0)
    | (regOffsetReg_2 == 4'hB ? brodenMergeDataReg_2[215:88] : 128'h0)
    | (regOffsetReg_2 == 4'hC ? brodenMergeDataReg_2[223:96] : 128'h0)
    | (regOffsetReg_2 == 4'hD ? brodenMergeDataReg_2[231:104] : 128'h0)
    | (regOffsetReg_2 == 4'hE ? brodenMergeDataReg_2[239:112] : 128'h0)
    | ((&regOffsetReg_2) ? brodenMergeDataReg_2[247:120] : 128'h0);
  wire [15:0]        usSelMask_2 =
    (regOffsetReg_2 == 4'h0 ? brodenMergeMaskReg_2[15:0] : 16'h0)
    | (regOffsetReg_2 == 4'h1 ? brodenMergeMaskReg_2[16:1] : 16'h0)
    | (regOffsetReg_2 == 4'h2 ? brodenMergeMaskReg_2[17:2] : 16'h0)
    | (regOffsetReg_2 == 4'h3 ? brodenMergeMaskReg_2[18:3] : 16'h0)
    | (regOffsetReg_2 == 4'h4 ? brodenMergeMaskReg_2[19:4] : 16'h0)
    | (regOffsetReg_2 == 4'h5 ? brodenMergeMaskReg_2[20:5] : 16'h0)
    | (regOffsetReg_2 == 4'h6 ? brodenMergeMaskReg_2[21:6] : 16'h0)
    | (regOffsetReg_2 == 4'h7 ? brodenMergeMaskReg_2[22:7] : 16'h0)
    | (regOffsetReg_2 == 4'h8 ? brodenMergeMaskReg_2[23:8] : 16'h0)
    | (regOffsetReg_2 == 4'h9 ? brodenMergeMaskReg_2[24:9] : 16'h0)
    | (regOffsetReg_2 == 4'hA ? brodenMergeMaskReg_2[25:10] : 16'h0)
    | (regOffsetReg_2 == 4'hB ? brodenMergeMaskReg_2[26:11] : 16'h0)
    | (regOffsetReg_2 == 4'hC ? brodenMergeMaskReg_2[27:12] : 16'h0)
    | (regOffsetReg_2 == 4'hD ? brodenMergeMaskReg_2[28:13] : 16'h0)
    | (regOffsetReg_2 == 4'hE ? brodenMergeMaskReg_2[29:14] : 16'h0)
    | ((&regOffsetReg_2) ? brodenMergeMaskReg_2[30:15] : 16'h0);
  wire [127:0]       _GEN_314 = _GEN_48[wbIndexReg_2_r];
  wire [127:0]       usMergeData_2 =
    {usSelMask_2[15] ? usSelData_2[127:120] : _GEN_314[127:120],
     usSelMask_2[14] ? usSelData_2[119:112] : _GEN_314[119:112],
     usSelMask_2[13] ? usSelData_2[111:104] : _GEN_314[111:104],
     usSelMask_2[12] ? usSelData_2[103:96] : _GEN_314[103:96],
     usSelMask_2[11] ? usSelData_2[95:88] : _GEN_314[95:88],
     usSelMask_2[10] ? usSelData_2[87:80] : _GEN_314[87:80],
     usSelMask_2[9] ? usSelData_2[79:72] : _GEN_314[79:72],
     usSelMask_2[8] ? usSelData_2[71:64] : _GEN_314[71:64],
     usSelMask_2[7] ? usSelData_2[63:56] : _GEN_314[63:56],
     usSelMask_2[6] ? usSelData_2[55:48] : _GEN_314[55:48],
     usSelMask_2[5] ? usSelData_2[47:40] : _GEN_314[47:40],
     usSelMask_2[4] ? usSelData_2[39:32] : _GEN_314[39:32],
     usSelMask_2[3] ? usSelData_2[31:24] : _GEN_314[31:24],
     usSelMask_2[2] ? usSelData_2[23:16] : _GEN_314[23:16],
     usSelMask_2[1] ? usSelData_2[15:8] : _GEN_314[15:8],
     usSelMask_2[0] ? usSelData_2[7:0] : _GEN_314[7:0]};
  wire               _GEN_315 = pipewbValidReg_2_REG & ~mergedByPrevPortReg_2;
  wire [1:0]         _GEN_316 = {1'h0, mergePortValid_1};
  wire [15:0]        maskWithexceptionMask_0 =
    (io_fromPipeline_0_bits_trigger == 4'h0 | _maskWithexceptionMask_T_1
       ? ~io_fromPipeline_0_bits_vecTriggerMask
       : {16{{io_fromPipeline_0_bits_exceptionVec_21,
              io_fromPipeline_0_bits_exceptionVec_19,
              io_fromPipeline_0_bits_exceptionVec_13,
              io_fromPipeline_0_bits_exceptionVec_5,
              io_fromPipeline_0_bits_exceptionVec_4} == 5'h0}})
    & io_fromPipeline_0_bits_mask;
  wire               _mergedData_T_57 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h0 & mergePortValid_2;
  wire               _mergedData_T_70 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h1 & mergePortValid_2;
  wire               _mergedData_T_83 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h2 & mergePortValid_2;
  wire               _mergedData_T_96 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h3 & mergePortValid_2;
  wire               _mergedData_T_109 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h4 & mergePortValid_2;
  wire               _mergedData_T_122 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h5 & mergePortValid_2;
  wire               _mergedData_T_135 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h6 & mergePortValid_2;
  wire               _mergedData_T_148 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h7 & mergePortValid_2;
  wire               _mergedData_T_161 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h8 & mergePortValid_2;
  wire               _mergedData_T_174 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h9 & mergePortValid_2;
  wire               _mergedData_T_187 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'hA & mergePortValid_2;
  wire               _mergedData_T_200 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'hB & mergePortValid_2;
  wire               _mergedData_T_213 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'hC & mergePortValid_2;
  wire               _mergedData_T_226 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'hD & mergePortValid_2;
  wire               _mergedData_T_239 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'hE & mergePortValid_2;
  wire               _mergedData_T_252 =
    (&(io_fromPipeline_2_bits_elemIdxInsideVd[3:0])) & mergePortValid_2;
  wire               _mergedData_T_296 =
    io_fromPipeline_2_bits_elemIdxInsideVd[2:0] == 3'h0 & mergePortValid_2;
  wire               _mergedData_T_309 =
    io_fromPipeline_2_bits_elemIdxInsideVd[2:0] == 3'h1 & mergePortValid_2;
  wire               _mergedData_T_322 =
    io_fromPipeline_2_bits_elemIdxInsideVd[2:0] == 3'h2 & mergePortValid_2;
  wire               _mergedData_T_335 =
    io_fromPipeline_2_bits_elemIdxInsideVd[2:0] == 3'h3 & mergePortValid_2;
  wire               _mergedData_T_348 =
    io_fromPipeline_2_bits_elemIdxInsideVd[2:0] == 3'h4 & mergePortValid_2;
  wire               _mergedData_T_361 =
    io_fromPipeline_2_bits_elemIdxInsideVd[2:0] == 3'h5 & mergePortValid_2;
  wire               _mergedData_T_374 =
    io_fromPipeline_2_bits_elemIdxInsideVd[2:0] == 3'h6 & mergePortValid_2;
  wire               _mergedData_T_387 =
    (&(io_fromPipeline_2_bits_elemIdxInsideVd[2:0])) & mergePortValid_2;
  wire               _mergedData_T_419 =
    io_fromPipeline_2_bits_elemIdxInsideVd[1:0] == 2'h0 & mergePortValid_2;
  wire               _mergedData_T_432 =
    io_fromPipeline_2_bits_elemIdxInsideVd[1:0] == 2'h1 & mergePortValid_2;
  wire               _mergedData_T_445 =
    io_fromPipeline_2_bits_elemIdxInsideVd[1:0] == 2'h2 & mergePortValid_2;
  wire               _mergedData_T_458 =
    (&(io_fromPipeline_2_bits_elemIdxInsideVd[1:0])) & mergePortValid_2;
  wire               _mergedData_T_484 =
    ~(io_fromPipeline_2_bits_elemIdxInsideVd[0]) & mergePortValid_2;
  wire               _mergedData_T_497 =
    io_fromPipeline_2_bits_elemIdxInsideVd[0] & mergePortValid_2;
  wire [31:0]        selMaskMatrix_0_0 = {16'h0, maskWithexceptionMask_0};
  wire [31:0]        selMaskMatrix_0_1 = {maskWithexceptionMask_0, 16'h0};
  wire [1:0]         selIdx = mergePortValid_2 ? 2'h2 : _GEN_316;
  wire [127:0]       _GEN_317 =
    (io_fromPipeline_0_bits_alignedType[1:0] == 2'h0
       ? {(&(io_fromPipeline_1_bits_elemIdxInsideVd[3:0])) & mergePortValid_1
          | _mergedData_T_252
            ? (_mergedData_T_252
                 ? io_fromPipeline_2_bits_vecdata[7:0]
                 : io_fromPipeline_1_bits_vecdata[7:0])
            : (&(io_fromPipeline_0_bits_elemIdxInsideVd[3:0]))
                ? io_fromPipeline_0_bits_vecdata[7:0]
                : oldData[127:120],
          io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'hE & mergePortValid_1
          | _mergedData_T_239
            ? (_mergedData_T_239
                 ? io_fromPipeline_2_bits_vecdata[7:0]
                 : io_fromPipeline_1_bits_vecdata[7:0])
            : io_fromPipeline_0_bits_elemIdxInsideVd[3:0] == 4'hE
                ? io_fromPipeline_0_bits_vecdata[7:0]
                : oldData[119:112],
          io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'hD & mergePortValid_1
          | _mergedData_T_226
            ? (_mergedData_T_226
                 ? io_fromPipeline_2_bits_vecdata[7:0]
                 : io_fromPipeline_1_bits_vecdata[7:0])
            : io_fromPipeline_0_bits_elemIdxInsideVd[3:0] == 4'hD
                ? io_fromPipeline_0_bits_vecdata[7:0]
                : oldData[111:104],
          io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'hC & mergePortValid_1
          | _mergedData_T_213
            ? (_mergedData_T_213
                 ? io_fromPipeline_2_bits_vecdata[7:0]
                 : io_fromPipeline_1_bits_vecdata[7:0])
            : io_fromPipeline_0_bits_elemIdxInsideVd[3:0] == 4'hC
                ? io_fromPipeline_0_bits_vecdata[7:0]
                : oldData[103:96],
          io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'hB & mergePortValid_1
          | _mergedData_T_200
            ? (_mergedData_T_200
                 ? io_fromPipeline_2_bits_vecdata[7:0]
                 : io_fromPipeline_1_bits_vecdata[7:0])
            : io_fromPipeline_0_bits_elemIdxInsideVd[3:0] == 4'hB
                ? io_fromPipeline_0_bits_vecdata[7:0]
                : oldData[95:88],
          io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'hA & mergePortValid_1
          | _mergedData_T_187
            ? (_mergedData_T_187
                 ? io_fromPipeline_2_bits_vecdata[7:0]
                 : io_fromPipeline_1_bits_vecdata[7:0])
            : io_fromPipeline_0_bits_elemIdxInsideVd[3:0] == 4'hA
                ? io_fromPipeline_0_bits_vecdata[7:0]
                : oldData[87:80],
          io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'h9 & mergePortValid_1
          | _mergedData_T_174
            ? (_mergedData_T_174
                 ? io_fromPipeline_2_bits_vecdata[7:0]
                 : io_fromPipeline_1_bits_vecdata[7:0])
            : io_fromPipeline_0_bits_elemIdxInsideVd[3:0] == 4'h9
                ? io_fromPipeline_0_bits_vecdata[7:0]
                : oldData[79:72],
          io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'h8 & mergePortValid_1
          | _mergedData_T_161
            ? (_mergedData_T_161
                 ? io_fromPipeline_2_bits_vecdata[7:0]
                 : io_fromPipeline_1_bits_vecdata[7:0])
            : io_fromPipeline_0_bits_elemIdxInsideVd[3:0] == 4'h8
                ? io_fromPipeline_0_bits_vecdata[7:0]
                : oldData[71:64],
          io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'h7 & mergePortValid_1
          | _mergedData_T_148
            ? (_mergedData_T_148
                 ? io_fromPipeline_2_bits_vecdata[7:0]
                 : io_fromPipeline_1_bits_vecdata[7:0])
            : io_fromPipeline_0_bits_elemIdxInsideVd[3:0] == 4'h7
                ? io_fromPipeline_0_bits_vecdata[7:0]
                : oldData[63:56],
          io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'h6 & mergePortValid_1
          | _mergedData_T_135
            ? (_mergedData_T_135
                 ? io_fromPipeline_2_bits_vecdata[7:0]
                 : io_fromPipeline_1_bits_vecdata[7:0])
            : io_fromPipeline_0_bits_elemIdxInsideVd[3:0] == 4'h6
                ? io_fromPipeline_0_bits_vecdata[7:0]
                : oldData[55:48],
          io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'h5 & mergePortValid_1
          | _mergedData_T_122
            ? (_mergedData_T_122
                 ? io_fromPipeline_2_bits_vecdata[7:0]
                 : io_fromPipeline_1_bits_vecdata[7:0])
            : io_fromPipeline_0_bits_elemIdxInsideVd[3:0] == 4'h5
                ? io_fromPipeline_0_bits_vecdata[7:0]
                : oldData[47:40],
          io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'h4 & mergePortValid_1
          | _mergedData_T_109
            ? (_mergedData_T_109
                 ? io_fromPipeline_2_bits_vecdata[7:0]
                 : io_fromPipeline_1_bits_vecdata[7:0])
            : io_fromPipeline_0_bits_elemIdxInsideVd[3:0] == 4'h4
                ? io_fromPipeline_0_bits_vecdata[7:0]
                : oldData[39:32],
          io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'h3 & mergePortValid_1
          | _mergedData_T_96
            ? (_mergedData_T_96
                 ? io_fromPipeline_2_bits_vecdata[7:0]
                 : io_fromPipeline_1_bits_vecdata[7:0])
            : io_fromPipeline_0_bits_elemIdxInsideVd[3:0] == 4'h3
                ? io_fromPipeline_0_bits_vecdata[7:0]
                : oldData[31:24],
          io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'h2 & mergePortValid_1
          | _mergedData_T_83
            ? (_mergedData_T_83
                 ? io_fromPipeline_2_bits_vecdata[7:0]
                 : io_fromPipeline_1_bits_vecdata[7:0])
            : io_fromPipeline_0_bits_elemIdxInsideVd[3:0] == 4'h2
                ? io_fromPipeline_0_bits_vecdata[7:0]
                : oldData[23:16],
          io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'h1 & mergePortValid_1
          | _mergedData_T_70
            ? (_mergedData_T_70
                 ? io_fromPipeline_2_bits_vecdata[7:0]
                 : io_fromPipeline_1_bits_vecdata[7:0])
            : io_fromPipeline_0_bits_elemIdxInsideVd[3:0] == 4'h1
                ? io_fromPipeline_0_bits_vecdata[7:0]
                : oldData[15:8],
          io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'h0 & mergePortValid_1
          | _mergedData_T_57
            ? (_mergedData_T_57
                 ? io_fromPipeline_2_bits_vecdata[7:0]
                 : io_fromPipeline_1_bits_vecdata[7:0])
            : io_fromPipeline_0_bits_elemIdxInsideVd[3:0] == 4'h0
                ? io_fromPipeline_0_bits_vecdata[7:0]
                : oldData[7:0]}
       : 128'h0)
    | (io_fromPipeline_0_bits_alignedType[1:0] == 2'h1
         ? {(&(io_fromPipeline_1_bits_elemIdxInsideVd[2:0])) & mergePortValid_1
            | _mergedData_T_387
              ? (_mergedData_T_387
                   ? io_fromPipeline_2_bits_vecdata[15:0]
                   : io_fromPipeline_1_bits_vecdata[15:0])
              : (&(io_fromPipeline_0_bits_elemIdxInsideVd[2:0]))
                  ? io_fromPipeline_0_bits_vecdata[15:0]
                  : oldData[127:112],
            io_fromPipeline_1_bits_elemIdxInsideVd[2:0] == 3'h6 & mergePortValid_1
            | _mergedData_T_374
              ? (_mergedData_T_374
                   ? io_fromPipeline_2_bits_vecdata[15:0]
                   : io_fromPipeline_1_bits_vecdata[15:0])
              : io_fromPipeline_0_bits_elemIdxInsideVd[2:0] == 3'h6
                  ? io_fromPipeline_0_bits_vecdata[15:0]
                  : oldData[111:96],
            io_fromPipeline_1_bits_elemIdxInsideVd[2:0] == 3'h5 & mergePortValid_1
            | _mergedData_T_361
              ? (_mergedData_T_361
                   ? io_fromPipeline_2_bits_vecdata[15:0]
                   : io_fromPipeline_1_bits_vecdata[15:0])
              : io_fromPipeline_0_bits_elemIdxInsideVd[2:0] == 3'h5
                  ? io_fromPipeline_0_bits_vecdata[15:0]
                  : oldData[95:80],
            io_fromPipeline_1_bits_elemIdxInsideVd[2:0] == 3'h4 & mergePortValid_1
            | _mergedData_T_348
              ? (_mergedData_T_348
                   ? io_fromPipeline_2_bits_vecdata[15:0]
                   : io_fromPipeline_1_bits_vecdata[15:0])
              : io_fromPipeline_0_bits_elemIdxInsideVd[2:0] == 3'h4
                  ? io_fromPipeline_0_bits_vecdata[15:0]
                  : oldData[79:64],
            io_fromPipeline_1_bits_elemIdxInsideVd[2:0] == 3'h3 & mergePortValid_1
            | _mergedData_T_335
              ? (_mergedData_T_335
                   ? io_fromPipeline_2_bits_vecdata[15:0]
                   : io_fromPipeline_1_bits_vecdata[15:0])
              : io_fromPipeline_0_bits_elemIdxInsideVd[2:0] == 3'h3
                  ? io_fromPipeline_0_bits_vecdata[15:0]
                  : oldData[63:48],
            io_fromPipeline_1_bits_elemIdxInsideVd[2:0] == 3'h2 & mergePortValid_1
            | _mergedData_T_322
              ? (_mergedData_T_322
                   ? io_fromPipeline_2_bits_vecdata[15:0]
                   : io_fromPipeline_1_bits_vecdata[15:0])
              : io_fromPipeline_0_bits_elemIdxInsideVd[2:0] == 3'h2
                  ? io_fromPipeline_0_bits_vecdata[15:0]
                  : oldData[47:32],
            io_fromPipeline_1_bits_elemIdxInsideVd[2:0] == 3'h1 & mergePortValid_1
            | _mergedData_T_309
              ? (_mergedData_T_309
                   ? io_fromPipeline_2_bits_vecdata[15:0]
                   : io_fromPipeline_1_bits_vecdata[15:0])
              : io_fromPipeline_0_bits_elemIdxInsideVd[2:0] == 3'h1
                  ? io_fromPipeline_0_bits_vecdata[15:0]
                  : oldData[31:16],
            io_fromPipeline_1_bits_elemIdxInsideVd[2:0] == 3'h0 & mergePortValid_1
            | _mergedData_T_296
              ? (_mergedData_T_296
                   ? io_fromPipeline_2_bits_vecdata[15:0]
                   : io_fromPipeline_1_bits_vecdata[15:0])
              : io_fromPipeline_0_bits_elemIdxInsideVd[2:0] == 3'h0
                  ? io_fromPipeline_0_bits_vecdata[15:0]
                  : oldData[15:0]}
         : 128'h0);
  wire [3:0][31:0]   _GEN_318 =
    {{selMaskMatrix_0_1},
     {{maskWithexceptionMask_0, maskWithexceptionMask_2}},
     {{maskWithexceptionMask_0, maskWithexceptionMask_1}},
     {selMaskMatrix_0_1}};
  wire [3:0][31:0]   _GEN_319 =
    {{selMaskMatrix_0_0},
     {{maskWithexceptionMask_2, maskWithexceptionMask_0}},
     {{maskWithexceptionMask_1, maskWithexceptionMask_0}},
     {selMaskMatrix_0_0}};
  wire               _mergedData_T_577 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h0 & selIdx_1;
  wire               _mergedData_T_590 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h1 & selIdx_1;
  wire               _mergedData_T_603 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h2 & selIdx_1;
  wire               _mergedData_T_616 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h3 & selIdx_1;
  wire               _mergedData_T_629 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h4 & selIdx_1;
  wire               _mergedData_T_642 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h5 & selIdx_1;
  wire               _mergedData_T_655 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h6 & selIdx_1;
  wire               _mergedData_T_668 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h7 & selIdx_1;
  wire               _mergedData_T_681 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h8 & selIdx_1;
  wire               _mergedData_T_694 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h9 & selIdx_1;
  wire               _mergedData_T_707 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'hA & selIdx_1;
  wire               _mergedData_T_720 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'hB & selIdx_1;
  wire               _mergedData_T_733 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'hC & selIdx_1;
  wire               _mergedData_T_746 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'hD & selIdx_1;
  wire               _mergedData_T_759 =
    io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'hE & selIdx_1;
  wire               _mergedData_T_772 =
    (&(io_fromPipeline_2_bits_elemIdxInsideVd[3:0])) & selIdx_1;
  wire               _mergedData_T_816 =
    io_fromPipeline_2_bits_elemIdxInsideVd[2:0] == 3'h0 & selIdx_1;
  wire               _mergedData_T_829 =
    io_fromPipeline_2_bits_elemIdxInsideVd[2:0] == 3'h1 & selIdx_1;
  wire               _mergedData_T_842 =
    io_fromPipeline_2_bits_elemIdxInsideVd[2:0] == 3'h2 & selIdx_1;
  wire               _mergedData_T_855 =
    io_fromPipeline_2_bits_elemIdxInsideVd[2:0] == 3'h3 & selIdx_1;
  wire               _mergedData_T_868 =
    io_fromPipeline_2_bits_elemIdxInsideVd[2:0] == 3'h4 & selIdx_1;
  wire               _mergedData_T_881 =
    io_fromPipeline_2_bits_elemIdxInsideVd[2:0] == 3'h5 & selIdx_1;
  wire               _mergedData_T_894 =
    io_fromPipeline_2_bits_elemIdxInsideVd[2:0] == 3'h6 & selIdx_1;
  wire               _mergedData_T_907 =
    (&(io_fromPipeline_2_bits_elemIdxInsideVd[2:0])) & selIdx_1;
  wire               _mergedData_T_939 =
    io_fromPipeline_2_bits_elemIdxInsideVd[1:0] == 2'h0 & selIdx_1;
  wire               _mergedData_T_952 =
    io_fromPipeline_2_bits_elemIdxInsideVd[1:0] == 2'h1 & selIdx_1;
  wire               _mergedData_T_965 =
    io_fromPipeline_2_bits_elemIdxInsideVd[1:0] == 2'h2 & selIdx_1;
  wire               _mergedData_T_978 =
    (&(io_fromPipeline_2_bits_elemIdxInsideVd[1:0])) & selIdx_1;
  wire               _mergedData_T_1004 =
    ~(io_fromPipeline_2_bits_elemIdxInsideVd[0]) & selIdx_1;
  wire               _mergedData_T_1017 =
    io_fromPipeline_2_bits_elemIdxInsideVd[0] & selIdx_1;
  wire [127:0]       _GEN_320 = selIdx_1 ? io_fromPipeline_2_bits_vecdata : 128'h0;
  wire [15:0]        _GEN_321 = selIdx_1 ? maskWithexceptionMask_2 : 16'h0;
  always @(posedge clock) begin
    if (_GEN_315 & wbIndexReg_2_r == 4'h0) begin
      if (isusMerge_2)
        entries[0].data <= usMergeData_2;
      else
        entries[0].data <= mergeDataReg_2_r;
    end
    else if (_GEN_313 & wbIndexReg_1_r == 4'h0) begin
      if (isusMerge_1)
        entries[0].data <= usMergeData_1;
      else
        entries[0].data <= mergeDataReg_1_r;
    end
    else if (pipewbValidReg_0_REG & wbIndexReg_0_r == 4'h0) begin
      if (isusMerge)
        entries[0].data <= usMergeData;
      else
        entries[0].data <= mergeDataReg_0_r;
    end
    else if (_GEN_165)
      entries[0].data <= io_fromSplit_1_req_bits_data;
    else if (_GEN_0)
      entries[0].data <= io_fromSplit_0_req_bits_data;
    if (_GEN_165) begin
      entries[0].mask <= io_fromSplit_1_req_bits_mask;
      entries[0].uop_fuOpType <= io_fromSplit_1_req_bits_uop_fuOpType;
      entries[0].uop_vecWen <= io_fromSplit_1_req_bits_uop_vecWen;
      entries[0].uop_v0Wen <= io_fromSplit_1_req_bits_uop_v0Wen;
      entries[0].uop_vlWen <= io_fromSplit_1_req_bits_uop_vlWen;
      entries[0].uop_vpu_vma <= io_fromSplit_1_req_bits_uop_vpu_vma;
      entries[0].uop_vpu_vsew <= io_fromSplit_1_req_bits_uop_vpu_vsew;
      entries[0].uop_vpu_vlmul <= io_fromSplit_1_req_bits_uop_vpu_vlmul;
      entries[0].uop_vpu_vm <= io_fromSplit_1_req_bits_uop_vpu_vm;
      entries[0].uop_vpu_vuopIdx <= io_fromSplit_1_req_bits_uop_vpu_vuopIdx;
      entries[0].uop_vpu_nf <= io_fromSplit_1_req_bits_uop_vpu_nf;
      entries[0].uop_vpu_veew <= io_fromSplit_1_req_bits_uop_vpu_veew;
      entries[0].uop_uopIdx <= io_fromSplit_1_req_bits_uop_uopIdx;
      entries[0].uop_pdest <= io_fromSplit_1_req_bits_uop_pdest;
      entries[0].uop_robIdx_flag <= io_fromSplit_1_req_bits_uop_robIdx_flag;
      entries[0].uop_robIdx_value <= io_fromSplit_1_req_bits_uop_robIdx_value;
      entries[0].uop_debugInfo_enqRsTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime;
      entries[0].uop_debugInfo_selectTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_selectTime;
      entries[0].uop_debugInfo_issueTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_issueTime;
      entries[0].vdIdx <= io_fromSplit_1_req_bits_vdIdx;
      entries[0].fof <= io_fromSplit_1_req_bits_fof;
      entries[0].vlmax <= io_fromSplit_1_req_bits_vlmax;
    end
    else if (_GEN_0) begin
      entries[0].mask <= io_fromSplit_0_req_bits_mask;
      entries[0].uop_fuOpType <= io_fromSplit_0_req_bits_uop_fuOpType;
      entries[0].uop_vecWen <= io_fromSplit_0_req_bits_uop_vecWen;
      entries[0].uop_v0Wen <= io_fromSplit_0_req_bits_uop_v0Wen;
      entries[0].uop_vlWen <= io_fromSplit_0_req_bits_uop_vlWen;
      entries[0].uop_vpu_vma <= io_fromSplit_0_req_bits_uop_vpu_vma;
      entries[0].uop_vpu_vsew <= io_fromSplit_0_req_bits_uop_vpu_vsew;
      entries[0].uop_vpu_vlmul <= io_fromSplit_0_req_bits_uop_vpu_vlmul;
      entries[0].uop_vpu_vm <= io_fromSplit_0_req_bits_uop_vpu_vm;
      entries[0].uop_vpu_vuopIdx <= io_fromSplit_0_req_bits_uop_vpu_vuopIdx;
      entries[0].uop_vpu_nf <= io_fromSplit_0_req_bits_uop_vpu_nf;
      entries[0].uop_vpu_veew <= io_fromSplit_0_req_bits_uop_vpu_veew;
      entries[0].uop_uopIdx <= io_fromSplit_0_req_bits_uop_uopIdx;
      entries[0].uop_pdest <= io_fromSplit_0_req_bits_uop_pdest;
      entries[0].uop_robIdx_flag <= io_fromSplit_0_req_bits_uop_robIdx_flag;
      entries[0].uop_robIdx_value <= io_fromSplit_0_req_bits_uop_robIdx_value;
      entries[0].uop_debugInfo_enqRsTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime;
      entries[0].uop_debugInfo_selectTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_selectTime;
      entries[0].uop_debugInfo_issueTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_issueTime;
      entries[0].vdIdx <= io_fromSplit_0_req_bits_vdIdx;
      entries[0].fof <= io_fromSplit_0_req_bits_fof;
      entries[0].vlmax <= io_fromSplit_0_req_bits_vlmax;
    end
    if (_GEN_310 & latchWbIndex_2 == 4'h0)
      entries[0].flowNum <= _entries_flowNum_T_4;
    else if (_GEN_309 & latchWbIndex_1 == 4'h0)
      entries[0].flowNum <= _entries_flowNum_T_2;
    else if (latchWbValid & latchWbIndex == 4'h0)
      entries[0].flowNum <= _entries_flowNum_T;
    else if (_GEN_165)
      entries[0].flowNum <= io_fromSplit_1_req_bits_flowNum;
    else if (_GEN_0)
      entries[0].flowNum <= io_fromSplit_0_req_bits_flowNum;
    if (_GEN_276 & _GEN_292 & _GEN_277) begin
      entries[0].exceptionVec_3 <= pipeBitsReg_2_exceptionVec_3;
      entries[0].exceptionVec_4 <= pipeBitsReg_2_exceptionVec_4;
      entries[0].exceptionVec_5 <= pipeBitsReg_2_exceptionVec_5;
      entries[0].exceptionVec_13 <= pipeBitsReg_2_exceptionVec_13;
      entries[0].exceptionVec_19 <= pipeBitsReg_2_exceptionVec_19;
      entries[0].exceptionVec_21 <= pipeBitsReg_2_exceptionVec_21;
      entries[0].uop_trigger <= pipeBitsReg_2_trigger;
      entries[0].vstart <= vstart_2;
      entries[0].vaNeedExt <= pipeBitsReg_2_vaNeedExt;
      entries[0].vaddr <= _vaddr_T_2;
      entries[0].gpaddr <= pipeBitsReg_2_gpaddr[49:0];
    end
    else if (_GEN_241 & _GEN_257 & _GEN_242) begin
      entries[0].exceptionVec_3 <= new_vec_3_3;
      entries[0].exceptionVec_4 <= new_vec_3_4;
      entries[0].exceptionVec_5 <= new_vec_3_5;
      entries[0].exceptionVec_13 <= new_vec_3_13;
      entries[0].exceptionVec_19 <= new_vec_3_19;
      entries[0].exceptionVec_21 <= new_vec_3_21;
      entries[0].uop_trigger <= sel_oldest_1_bits_trigger;
      entries[0].vstart <= vstart_1;
      entries[0].vaNeedExt <= sel_oldest_1_bits_vaNeedExt;
      entries[0].vaddr <= _vaddr_T_1;
      entries[0].gpaddr <= sel_oldest_1_bits_gpaddr;
    end
    else if (_GEN_205 & _GEN_221 & _GEN_206) begin
      entries[0].exceptionVec_3 <= new_vec_2_3;
      entries[0].exceptionVec_4 <= new_vec_2_4;
      entries[0].exceptionVec_5 <= new_vec_2_5;
      entries[0].exceptionVec_13 <= new_vec_2_13;
      entries[0].exceptionVec_19 <= new_vec_2_19;
      entries[0].exceptionVec_21 <= new_vec_2_21;
      entries[0].uop_trigger <= sel_oldest_bits_trigger;
      entries[0].vstart <= vstart;
      entries[0].vaNeedExt <= sel_oldest_bits_vaNeedExt;
      entries[0].vaddr <= _vaddr_T;
      entries[0].gpaddr <= sel_oldest_bits_gpaddr;
    end
    else begin
      if (_GEN_16) begin
        entries[0].exceptionVec_3 <= ~_GEN_18 & entries[0].exceptionVec_3;
        entries[0].exceptionVec_4 <= ~_GEN_18 & entries[0].exceptionVec_4;
        entries[0].exceptionVec_5 <= ~_GEN_18 & entries[0].exceptionVec_5;
        entries[0].exceptionVec_13 <= ~_GEN_18 & entries[0].exceptionVec_13;
        entries[0].exceptionVec_19 <= ~_GEN_18 & entries[0].exceptionVec_19;
        entries[0].exceptionVec_21 <= ~_GEN_18 & entries[0].exceptionVec_21;
      end
      else begin
        entries[0].exceptionVec_3 <= ~_GEN_0 & entries[0].exceptionVec_3;
        entries[0].exceptionVec_4 <= ~_GEN_0 & entries[0].exceptionVec_4;
        entries[0].exceptionVec_5 <= ~_GEN_0 & entries[0].exceptionVec_5;
        entries[0].exceptionVec_13 <= ~_GEN_0 & entries[0].exceptionVec_13;
        entries[0].exceptionVec_19 <= ~_GEN_0 & entries[0].exceptionVec_19;
        entries[0].exceptionVec_21 <= ~_GEN_0 & entries[0].exceptionVec_21;
      end
      if (_GEN_165 | _GEN_0)
        entries[0].uop_trigger <= 4'h0;
      if (_GEN_181)
        entries[0].vstart <= 8'h0;
      if (_GEN_165)
        entries[0].vaddr <= _GEN_197;
      else if (_GEN_0)
        entries[0].vaddr <= _GEN_164;
    end
    entries[0].uop_flushPipe <= ~_GEN_165 & ~_GEN_0 & entries[0].uop_flushPipe;
    entries[0].uop_vpu_vta <=
      _GEN_293 & _GEN_258 & _GEN_222
      & (_GEN_165
           ? io_fromSplit_1_req_bits_uop_vpu_vta
           : _GEN_0 ? io_fromSplit_0_req_bits_uop_vpu_vta : entries[0].uop_vpu_vta);
    entries[0].uop_replayInst <= ~_GEN_165 & ~_GEN_0 & entries[0].uop_replayInst;
    if (_GEN_276 & _GEN_277)
      entries[0].elemIdx <= pipeBitsReg_2_elemIdx;
    else if (_GEN_241 & _GEN_242)
      entries[0].elemIdx <= sel_oldest_1_bits_elemIdx;
    else if (_GEN_205 & _GEN_206)
      entries[0].elemIdx <= sel_oldest_bits_elemIdx;
    else if (_GEN_181)
      entries[0].elemIdx <= 8'hFF;
    if (_GEN_293) begin
      if (_GEN_258) begin
        if (_GEN_222) begin
          if (_GEN_165)
            entries[0].vl <= io_fromSplit_1_req_bits_uop_vpu_vl;
          else if (_GEN_0)
            entries[0].vl <= io_fromSplit_0_req_bits_uop_vpu_vl;
        end
        else if (_entries_vl_T)
          entries[0].vl <= _GEN_201;
        else
          entries[0].vl <= vstart;
      end
      else if (_entries_vl_T_2)
        entries[0].vl <= _GEN_239;
      else
        entries[0].vl <= vstart_1;
    end
    else if (_entries_vl_T_4)
      entries[0].vl <= _GEN_275;
    else
      entries[0].vl <= vstart_2;
    if (_GEN_315 & wbIndexReg_2_r == 4'h1) begin
      if (isusMerge_2)
        entries[1].data <= usMergeData_2;
      else
        entries[1].data <= mergeDataReg_2_r;
    end
    else if (_GEN_313 & wbIndexReg_1_r == 4'h1) begin
      if (isusMerge_1)
        entries[1].data <= usMergeData_1;
      else
        entries[1].data <= mergeDataReg_1_r;
    end
    else if (pipewbValidReg_0_REG & wbIndexReg_0_r == 4'h1) begin
      if (isusMerge)
        entries[1].data <= usMergeData;
      else
        entries[1].data <= mergeDataReg_0_r;
    end
    else if (_GEN_166)
      entries[1].data <= io_fromSplit_1_req_bits_data;
    else if (_GEN_1)
      entries[1].data <= io_fromSplit_0_req_bits_data;
    if (_GEN_166) begin
      entries[1].mask <= io_fromSplit_1_req_bits_mask;
      entries[1].uop_fuOpType <= io_fromSplit_1_req_bits_uop_fuOpType;
      entries[1].uop_vecWen <= io_fromSplit_1_req_bits_uop_vecWen;
      entries[1].uop_v0Wen <= io_fromSplit_1_req_bits_uop_v0Wen;
      entries[1].uop_vlWen <= io_fromSplit_1_req_bits_uop_vlWen;
      entries[1].uop_vpu_vma <= io_fromSplit_1_req_bits_uop_vpu_vma;
      entries[1].uop_vpu_vsew <= io_fromSplit_1_req_bits_uop_vpu_vsew;
      entries[1].uop_vpu_vlmul <= io_fromSplit_1_req_bits_uop_vpu_vlmul;
      entries[1].uop_vpu_vm <= io_fromSplit_1_req_bits_uop_vpu_vm;
      entries[1].uop_vpu_vuopIdx <= io_fromSplit_1_req_bits_uop_vpu_vuopIdx;
      entries[1].uop_vpu_nf <= io_fromSplit_1_req_bits_uop_vpu_nf;
      entries[1].uop_vpu_veew <= io_fromSplit_1_req_bits_uop_vpu_veew;
      entries[1].uop_uopIdx <= io_fromSplit_1_req_bits_uop_uopIdx;
      entries[1].uop_pdest <= io_fromSplit_1_req_bits_uop_pdest;
      entries[1].uop_robIdx_flag <= io_fromSplit_1_req_bits_uop_robIdx_flag;
      entries[1].uop_robIdx_value <= io_fromSplit_1_req_bits_uop_robIdx_value;
      entries[1].uop_debugInfo_enqRsTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime;
      entries[1].uop_debugInfo_selectTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_selectTime;
      entries[1].uop_debugInfo_issueTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_issueTime;
      entries[1].vdIdx <= io_fromSplit_1_req_bits_vdIdx;
      entries[1].fof <= io_fromSplit_1_req_bits_fof;
      entries[1].vlmax <= io_fromSplit_1_req_bits_vlmax;
    end
    else if (_GEN_1) begin
      entries[1].mask <= io_fromSplit_0_req_bits_mask;
      entries[1].uop_fuOpType <= io_fromSplit_0_req_bits_uop_fuOpType;
      entries[1].uop_vecWen <= io_fromSplit_0_req_bits_uop_vecWen;
      entries[1].uop_v0Wen <= io_fromSplit_0_req_bits_uop_v0Wen;
      entries[1].uop_vlWen <= io_fromSplit_0_req_bits_uop_vlWen;
      entries[1].uop_vpu_vma <= io_fromSplit_0_req_bits_uop_vpu_vma;
      entries[1].uop_vpu_vsew <= io_fromSplit_0_req_bits_uop_vpu_vsew;
      entries[1].uop_vpu_vlmul <= io_fromSplit_0_req_bits_uop_vpu_vlmul;
      entries[1].uop_vpu_vm <= io_fromSplit_0_req_bits_uop_vpu_vm;
      entries[1].uop_vpu_vuopIdx <= io_fromSplit_0_req_bits_uop_vpu_vuopIdx;
      entries[1].uop_vpu_nf <= io_fromSplit_0_req_bits_uop_vpu_nf;
      entries[1].uop_vpu_veew <= io_fromSplit_0_req_bits_uop_vpu_veew;
      entries[1].uop_uopIdx <= io_fromSplit_0_req_bits_uop_uopIdx;
      entries[1].uop_pdest <= io_fromSplit_0_req_bits_uop_pdest;
      entries[1].uop_robIdx_flag <= io_fromSplit_0_req_bits_uop_robIdx_flag;
      entries[1].uop_robIdx_value <= io_fromSplit_0_req_bits_uop_robIdx_value;
      entries[1].uop_debugInfo_enqRsTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime;
      entries[1].uop_debugInfo_selectTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_selectTime;
      entries[1].uop_debugInfo_issueTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_issueTime;
      entries[1].vdIdx <= io_fromSplit_0_req_bits_vdIdx;
      entries[1].fof <= io_fromSplit_0_req_bits_fof;
      entries[1].vlmax <= io_fromSplit_0_req_bits_vlmax;
    end
    if (_GEN_310 & latchWbIndex_2 == 4'h1)
      entries[1].flowNum <= _entries_flowNum_T_4;
    else if (_GEN_309 & latchWbIndex_1 == 4'h1)
      entries[1].flowNum <= _entries_flowNum_T_2;
    else if (latchWbValid & latchWbIndex == 4'h1)
      entries[1].flowNum <= _entries_flowNum_T;
    else if (_GEN_166)
      entries[1].flowNum <= io_fromSplit_1_req_bits_flowNum;
    else if (_GEN_1)
      entries[1].flowNum <= io_fromSplit_0_req_bits_flowNum;
    if (_GEN_276 & _GEN_292 & _GEN_278) begin
      entries[1].exceptionVec_3 <= pipeBitsReg_2_exceptionVec_3;
      entries[1].exceptionVec_4 <= pipeBitsReg_2_exceptionVec_4;
      entries[1].exceptionVec_5 <= pipeBitsReg_2_exceptionVec_5;
      entries[1].exceptionVec_13 <= pipeBitsReg_2_exceptionVec_13;
      entries[1].exceptionVec_19 <= pipeBitsReg_2_exceptionVec_19;
      entries[1].exceptionVec_21 <= pipeBitsReg_2_exceptionVec_21;
      entries[1].uop_trigger <= pipeBitsReg_2_trigger;
      entries[1].vstart <= vstart_2;
      entries[1].vaNeedExt <= pipeBitsReg_2_vaNeedExt;
      entries[1].vaddr <= _vaddr_T_2;
      entries[1].gpaddr <= pipeBitsReg_2_gpaddr[49:0];
    end
    else if (_GEN_241 & _GEN_257 & _GEN_243) begin
      entries[1].exceptionVec_3 <= new_vec_3_3;
      entries[1].exceptionVec_4 <= new_vec_3_4;
      entries[1].exceptionVec_5 <= new_vec_3_5;
      entries[1].exceptionVec_13 <= new_vec_3_13;
      entries[1].exceptionVec_19 <= new_vec_3_19;
      entries[1].exceptionVec_21 <= new_vec_3_21;
      entries[1].uop_trigger <= sel_oldest_1_bits_trigger;
      entries[1].vstart <= vstart_1;
      entries[1].vaNeedExt <= sel_oldest_1_bits_vaNeedExt;
      entries[1].vaddr <= _vaddr_T_1;
      entries[1].gpaddr <= sel_oldest_1_bits_gpaddr;
    end
    else if (_GEN_205 & _GEN_221 & _GEN_207) begin
      entries[1].exceptionVec_3 <= new_vec_2_3;
      entries[1].exceptionVec_4 <= new_vec_2_4;
      entries[1].exceptionVec_5 <= new_vec_2_5;
      entries[1].exceptionVec_13 <= new_vec_2_13;
      entries[1].exceptionVec_19 <= new_vec_2_19;
      entries[1].exceptionVec_21 <= new_vec_2_21;
      entries[1].uop_trigger <= sel_oldest_bits_trigger;
      entries[1].vstart <= vstart;
      entries[1].vaNeedExt <= sel_oldest_bits_vaNeedExt;
      entries[1].vaddr <= _vaddr_T;
      entries[1].gpaddr <= sel_oldest_bits_gpaddr;
    end
    else begin
      if (_GEN_16) begin
        entries[1].exceptionVec_3 <= ~_GEN_20 & entries[1].exceptionVec_3;
        entries[1].exceptionVec_4 <= ~_GEN_20 & entries[1].exceptionVec_4;
        entries[1].exceptionVec_5 <= ~_GEN_20 & entries[1].exceptionVec_5;
        entries[1].exceptionVec_13 <= ~_GEN_20 & entries[1].exceptionVec_13;
        entries[1].exceptionVec_19 <= ~_GEN_20 & entries[1].exceptionVec_19;
        entries[1].exceptionVec_21 <= ~_GEN_20 & entries[1].exceptionVec_21;
      end
      else begin
        entries[1].exceptionVec_3 <= ~_GEN_1 & entries[1].exceptionVec_3;
        entries[1].exceptionVec_4 <= ~_GEN_1 & entries[1].exceptionVec_4;
        entries[1].exceptionVec_5 <= ~_GEN_1 & entries[1].exceptionVec_5;
        entries[1].exceptionVec_13 <= ~_GEN_1 & entries[1].exceptionVec_13;
        entries[1].exceptionVec_19 <= ~_GEN_1 & entries[1].exceptionVec_19;
        entries[1].exceptionVec_21 <= ~_GEN_1 & entries[1].exceptionVec_21;
      end
      if (_GEN_166 | _GEN_1)
        entries[1].uop_trigger <= 4'h0;
      if (_GEN_182)
        entries[1].vstart <= 8'h0;
      if (_GEN_166)
        entries[1].vaddr <= _GEN_197;
      else if (_GEN_1)
        entries[1].vaddr <= _GEN_164;
    end
    entries[1].uop_flushPipe <= ~_GEN_166 & ~_GEN_1 & entries[1].uop_flushPipe;
    entries[1].uop_vpu_vta <=
      _GEN_294 & _GEN_259 & _GEN_223
      & (_GEN_166
           ? io_fromSplit_1_req_bits_uop_vpu_vta
           : _GEN_1 ? io_fromSplit_0_req_bits_uop_vpu_vta : entries[1].uop_vpu_vta);
    entries[1].uop_replayInst <= ~_GEN_166 & ~_GEN_1 & entries[1].uop_replayInst;
    if (_GEN_276 & _GEN_278)
      entries[1].elemIdx <= pipeBitsReg_2_elemIdx;
    else if (_GEN_241 & _GEN_243)
      entries[1].elemIdx <= sel_oldest_1_bits_elemIdx;
    else if (_GEN_205 & _GEN_207)
      entries[1].elemIdx <= sel_oldest_bits_elemIdx;
    else if (_GEN_182)
      entries[1].elemIdx <= 8'hFF;
    if (_GEN_294) begin
      if (_GEN_259) begin
        if (_GEN_223) begin
          if (_GEN_166)
            entries[1].vl <= io_fromSplit_1_req_bits_uop_vpu_vl;
          else if (_GEN_1)
            entries[1].vl <= io_fromSplit_0_req_bits_uop_vpu_vl;
        end
        else if (_entries_vl_T)
          entries[1].vl <= _GEN_201;
        else
          entries[1].vl <= vstart;
      end
      else if (_entries_vl_T_2)
        entries[1].vl <= _GEN_239;
      else
        entries[1].vl <= vstart_1;
    end
    else if (_entries_vl_T_4)
      entries[1].vl <= _GEN_275;
    else
      entries[1].vl <= vstart_2;
    if (_GEN_315 & wbIndexReg_2_r == 4'h2) begin
      if (isusMerge_2)
        entries[2].data <= usMergeData_2;
      else
        entries[2].data <= mergeDataReg_2_r;
    end
    else if (_GEN_313 & wbIndexReg_1_r == 4'h2) begin
      if (isusMerge_1)
        entries[2].data <= usMergeData_1;
      else
        entries[2].data <= mergeDataReg_1_r;
    end
    else if (pipewbValidReg_0_REG & wbIndexReg_0_r == 4'h2) begin
      if (isusMerge)
        entries[2].data <= usMergeData;
      else
        entries[2].data <= mergeDataReg_0_r;
    end
    else if (_GEN_167)
      entries[2].data <= io_fromSplit_1_req_bits_data;
    else if (_GEN_2)
      entries[2].data <= io_fromSplit_0_req_bits_data;
    if (_GEN_167) begin
      entries[2].mask <= io_fromSplit_1_req_bits_mask;
      entries[2].uop_fuOpType <= io_fromSplit_1_req_bits_uop_fuOpType;
      entries[2].uop_vecWen <= io_fromSplit_1_req_bits_uop_vecWen;
      entries[2].uop_v0Wen <= io_fromSplit_1_req_bits_uop_v0Wen;
      entries[2].uop_vlWen <= io_fromSplit_1_req_bits_uop_vlWen;
      entries[2].uop_vpu_vma <= io_fromSplit_1_req_bits_uop_vpu_vma;
      entries[2].uop_vpu_vsew <= io_fromSplit_1_req_bits_uop_vpu_vsew;
      entries[2].uop_vpu_vlmul <= io_fromSplit_1_req_bits_uop_vpu_vlmul;
      entries[2].uop_vpu_vm <= io_fromSplit_1_req_bits_uop_vpu_vm;
      entries[2].uop_vpu_vuopIdx <= io_fromSplit_1_req_bits_uop_vpu_vuopIdx;
      entries[2].uop_vpu_nf <= io_fromSplit_1_req_bits_uop_vpu_nf;
      entries[2].uop_vpu_veew <= io_fromSplit_1_req_bits_uop_vpu_veew;
      entries[2].uop_uopIdx <= io_fromSplit_1_req_bits_uop_uopIdx;
      entries[2].uop_pdest <= io_fromSplit_1_req_bits_uop_pdest;
      entries[2].uop_robIdx_flag <= io_fromSplit_1_req_bits_uop_robIdx_flag;
      entries[2].uop_robIdx_value <= io_fromSplit_1_req_bits_uop_robIdx_value;
      entries[2].uop_debugInfo_enqRsTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime;
      entries[2].uop_debugInfo_selectTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_selectTime;
      entries[2].uop_debugInfo_issueTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_issueTime;
      entries[2].vdIdx <= io_fromSplit_1_req_bits_vdIdx;
      entries[2].fof <= io_fromSplit_1_req_bits_fof;
      entries[2].vlmax <= io_fromSplit_1_req_bits_vlmax;
    end
    else if (_GEN_2) begin
      entries[2].mask <= io_fromSplit_0_req_bits_mask;
      entries[2].uop_fuOpType <= io_fromSplit_0_req_bits_uop_fuOpType;
      entries[2].uop_vecWen <= io_fromSplit_0_req_bits_uop_vecWen;
      entries[2].uop_v0Wen <= io_fromSplit_0_req_bits_uop_v0Wen;
      entries[2].uop_vlWen <= io_fromSplit_0_req_bits_uop_vlWen;
      entries[2].uop_vpu_vma <= io_fromSplit_0_req_bits_uop_vpu_vma;
      entries[2].uop_vpu_vsew <= io_fromSplit_0_req_bits_uop_vpu_vsew;
      entries[2].uop_vpu_vlmul <= io_fromSplit_0_req_bits_uop_vpu_vlmul;
      entries[2].uop_vpu_vm <= io_fromSplit_0_req_bits_uop_vpu_vm;
      entries[2].uop_vpu_vuopIdx <= io_fromSplit_0_req_bits_uop_vpu_vuopIdx;
      entries[2].uop_vpu_nf <= io_fromSplit_0_req_bits_uop_vpu_nf;
      entries[2].uop_vpu_veew <= io_fromSplit_0_req_bits_uop_vpu_veew;
      entries[2].uop_uopIdx <= io_fromSplit_0_req_bits_uop_uopIdx;
      entries[2].uop_pdest <= io_fromSplit_0_req_bits_uop_pdest;
      entries[2].uop_robIdx_flag <= io_fromSplit_0_req_bits_uop_robIdx_flag;
      entries[2].uop_robIdx_value <= io_fromSplit_0_req_bits_uop_robIdx_value;
      entries[2].uop_debugInfo_enqRsTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime;
      entries[2].uop_debugInfo_selectTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_selectTime;
      entries[2].uop_debugInfo_issueTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_issueTime;
      entries[2].vdIdx <= io_fromSplit_0_req_bits_vdIdx;
      entries[2].fof <= io_fromSplit_0_req_bits_fof;
      entries[2].vlmax <= io_fromSplit_0_req_bits_vlmax;
    end
    if (_GEN_310 & latchWbIndex_2 == 4'h2)
      entries[2].flowNum <= _entries_flowNum_T_4;
    else if (_GEN_309 & latchWbIndex_1 == 4'h2)
      entries[2].flowNum <= _entries_flowNum_T_2;
    else if (latchWbValid & latchWbIndex == 4'h2)
      entries[2].flowNum <= _entries_flowNum_T;
    else if (_GEN_167)
      entries[2].flowNum <= io_fromSplit_1_req_bits_flowNum;
    else if (_GEN_2)
      entries[2].flowNum <= io_fromSplit_0_req_bits_flowNum;
    if (_GEN_276 & _GEN_292 & _GEN_279) begin
      entries[2].exceptionVec_3 <= pipeBitsReg_2_exceptionVec_3;
      entries[2].exceptionVec_4 <= pipeBitsReg_2_exceptionVec_4;
      entries[2].exceptionVec_5 <= pipeBitsReg_2_exceptionVec_5;
      entries[2].exceptionVec_13 <= pipeBitsReg_2_exceptionVec_13;
      entries[2].exceptionVec_19 <= pipeBitsReg_2_exceptionVec_19;
      entries[2].exceptionVec_21 <= pipeBitsReg_2_exceptionVec_21;
      entries[2].uop_trigger <= pipeBitsReg_2_trigger;
      entries[2].vstart <= vstart_2;
      entries[2].vaNeedExt <= pipeBitsReg_2_vaNeedExt;
      entries[2].vaddr <= _vaddr_T_2;
      entries[2].gpaddr <= pipeBitsReg_2_gpaddr[49:0];
    end
    else if (_GEN_241 & _GEN_257 & _GEN_244) begin
      entries[2].exceptionVec_3 <= new_vec_3_3;
      entries[2].exceptionVec_4 <= new_vec_3_4;
      entries[2].exceptionVec_5 <= new_vec_3_5;
      entries[2].exceptionVec_13 <= new_vec_3_13;
      entries[2].exceptionVec_19 <= new_vec_3_19;
      entries[2].exceptionVec_21 <= new_vec_3_21;
      entries[2].uop_trigger <= sel_oldest_1_bits_trigger;
      entries[2].vstart <= vstart_1;
      entries[2].vaNeedExt <= sel_oldest_1_bits_vaNeedExt;
      entries[2].vaddr <= _vaddr_T_1;
      entries[2].gpaddr <= sel_oldest_1_bits_gpaddr;
    end
    else if (_GEN_205 & _GEN_221 & _GEN_208) begin
      entries[2].exceptionVec_3 <= new_vec_2_3;
      entries[2].exceptionVec_4 <= new_vec_2_4;
      entries[2].exceptionVec_5 <= new_vec_2_5;
      entries[2].exceptionVec_13 <= new_vec_2_13;
      entries[2].exceptionVec_19 <= new_vec_2_19;
      entries[2].exceptionVec_21 <= new_vec_2_21;
      entries[2].uop_trigger <= sel_oldest_bits_trigger;
      entries[2].vstart <= vstart;
      entries[2].vaNeedExt <= sel_oldest_bits_vaNeedExt;
      entries[2].vaddr <= _vaddr_T;
      entries[2].gpaddr <= sel_oldest_bits_gpaddr;
    end
    else begin
      if (_GEN_16) begin
        entries[2].exceptionVec_3 <= ~_GEN_22 & entries[2].exceptionVec_3;
        entries[2].exceptionVec_4 <= ~_GEN_22 & entries[2].exceptionVec_4;
        entries[2].exceptionVec_5 <= ~_GEN_22 & entries[2].exceptionVec_5;
        entries[2].exceptionVec_13 <= ~_GEN_22 & entries[2].exceptionVec_13;
        entries[2].exceptionVec_19 <= ~_GEN_22 & entries[2].exceptionVec_19;
        entries[2].exceptionVec_21 <= ~_GEN_22 & entries[2].exceptionVec_21;
      end
      else begin
        entries[2].exceptionVec_3 <= ~_GEN_2 & entries[2].exceptionVec_3;
        entries[2].exceptionVec_4 <= ~_GEN_2 & entries[2].exceptionVec_4;
        entries[2].exceptionVec_5 <= ~_GEN_2 & entries[2].exceptionVec_5;
        entries[2].exceptionVec_13 <= ~_GEN_2 & entries[2].exceptionVec_13;
        entries[2].exceptionVec_19 <= ~_GEN_2 & entries[2].exceptionVec_19;
        entries[2].exceptionVec_21 <= ~_GEN_2 & entries[2].exceptionVec_21;
      end
      if (_GEN_167 | _GEN_2)
        entries[2].uop_trigger <= 4'h0;
      if (_GEN_183)
        entries[2].vstart <= 8'h0;
      if (_GEN_167)
        entries[2].vaddr <= _GEN_197;
      else if (_GEN_2)
        entries[2].vaddr <= _GEN_164;
    end
    entries[2].uop_flushPipe <= ~_GEN_167 & ~_GEN_2 & entries[2].uop_flushPipe;
    entries[2].uop_vpu_vta <=
      _GEN_295 & _GEN_260 & _GEN_224
      & (_GEN_167
           ? io_fromSplit_1_req_bits_uop_vpu_vta
           : _GEN_2 ? io_fromSplit_0_req_bits_uop_vpu_vta : entries[2].uop_vpu_vta);
    entries[2].uop_replayInst <= ~_GEN_167 & ~_GEN_2 & entries[2].uop_replayInst;
    if (_GEN_276 & _GEN_279)
      entries[2].elemIdx <= pipeBitsReg_2_elemIdx;
    else if (_GEN_241 & _GEN_244)
      entries[2].elemIdx <= sel_oldest_1_bits_elemIdx;
    else if (_GEN_205 & _GEN_208)
      entries[2].elemIdx <= sel_oldest_bits_elemIdx;
    else if (_GEN_183)
      entries[2].elemIdx <= 8'hFF;
    if (_GEN_295) begin
      if (_GEN_260) begin
        if (_GEN_224) begin
          if (_GEN_167)
            entries[2].vl <= io_fromSplit_1_req_bits_uop_vpu_vl;
          else if (_GEN_2)
            entries[2].vl <= io_fromSplit_0_req_bits_uop_vpu_vl;
        end
        else if (_entries_vl_T)
          entries[2].vl <= _GEN_201;
        else
          entries[2].vl <= vstart;
      end
      else if (_entries_vl_T_2)
        entries[2].vl <= _GEN_239;
      else
        entries[2].vl <= vstart_1;
    end
    else if (_entries_vl_T_4)
      entries[2].vl <= _GEN_275;
    else
      entries[2].vl <= vstart_2;
    if (_GEN_315 & wbIndexReg_2_r == 4'h3) begin
      if (isusMerge_2)
        entries[3].data <= usMergeData_2;
      else
        entries[3].data <= mergeDataReg_2_r;
    end
    else if (_GEN_313 & wbIndexReg_1_r == 4'h3) begin
      if (isusMerge_1)
        entries[3].data <= usMergeData_1;
      else
        entries[3].data <= mergeDataReg_1_r;
    end
    else if (pipewbValidReg_0_REG & wbIndexReg_0_r == 4'h3) begin
      if (isusMerge)
        entries[3].data <= usMergeData;
      else
        entries[3].data <= mergeDataReg_0_r;
    end
    else if (_GEN_168)
      entries[3].data <= io_fromSplit_1_req_bits_data;
    else if (_GEN_3)
      entries[3].data <= io_fromSplit_0_req_bits_data;
    if (_GEN_168) begin
      entries[3].mask <= io_fromSplit_1_req_bits_mask;
      entries[3].uop_fuOpType <= io_fromSplit_1_req_bits_uop_fuOpType;
      entries[3].uop_vecWen <= io_fromSplit_1_req_bits_uop_vecWen;
      entries[3].uop_v0Wen <= io_fromSplit_1_req_bits_uop_v0Wen;
      entries[3].uop_vlWen <= io_fromSplit_1_req_bits_uop_vlWen;
      entries[3].uop_vpu_vma <= io_fromSplit_1_req_bits_uop_vpu_vma;
      entries[3].uop_vpu_vsew <= io_fromSplit_1_req_bits_uop_vpu_vsew;
      entries[3].uop_vpu_vlmul <= io_fromSplit_1_req_bits_uop_vpu_vlmul;
      entries[3].uop_vpu_vm <= io_fromSplit_1_req_bits_uop_vpu_vm;
      entries[3].uop_vpu_vuopIdx <= io_fromSplit_1_req_bits_uop_vpu_vuopIdx;
      entries[3].uop_vpu_nf <= io_fromSplit_1_req_bits_uop_vpu_nf;
      entries[3].uop_vpu_veew <= io_fromSplit_1_req_bits_uop_vpu_veew;
      entries[3].uop_uopIdx <= io_fromSplit_1_req_bits_uop_uopIdx;
      entries[3].uop_pdest <= io_fromSplit_1_req_bits_uop_pdest;
      entries[3].uop_robIdx_flag <= io_fromSplit_1_req_bits_uop_robIdx_flag;
      entries[3].uop_robIdx_value <= io_fromSplit_1_req_bits_uop_robIdx_value;
      entries[3].uop_debugInfo_enqRsTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime;
      entries[3].uop_debugInfo_selectTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_selectTime;
      entries[3].uop_debugInfo_issueTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_issueTime;
      entries[3].vdIdx <= io_fromSplit_1_req_bits_vdIdx;
      entries[3].fof <= io_fromSplit_1_req_bits_fof;
      entries[3].vlmax <= io_fromSplit_1_req_bits_vlmax;
    end
    else if (_GEN_3) begin
      entries[3].mask <= io_fromSplit_0_req_bits_mask;
      entries[3].uop_fuOpType <= io_fromSplit_0_req_bits_uop_fuOpType;
      entries[3].uop_vecWen <= io_fromSplit_0_req_bits_uop_vecWen;
      entries[3].uop_v0Wen <= io_fromSplit_0_req_bits_uop_v0Wen;
      entries[3].uop_vlWen <= io_fromSplit_0_req_bits_uop_vlWen;
      entries[3].uop_vpu_vma <= io_fromSplit_0_req_bits_uop_vpu_vma;
      entries[3].uop_vpu_vsew <= io_fromSplit_0_req_bits_uop_vpu_vsew;
      entries[3].uop_vpu_vlmul <= io_fromSplit_0_req_bits_uop_vpu_vlmul;
      entries[3].uop_vpu_vm <= io_fromSplit_0_req_bits_uop_vpu_vm;
      entries[3].uop_vpu_vuopIdx <= io_fromSplit_0_req_bits_uop_vpu_vuopIdx;
      entries[3].uop_vpu_nf <= io_fromSplit_0_req_bits_uop_vpu_nf;
      entries[3].uop_vpu_veew <= io_fromSplit_0_req_bits_uop_vpu_veew;
      entries[3].uop_uopIdx <= io_fromSplit_0_req_bits_uop_uopIdx;
      entries[3].uop_pdest <= io_fromSplit_0_req_bits_uop_pdest;
      entries[3].uop_robIdx_flag <= io_fromSplit_0_req_bits_uop_robIdx_flag;
      entries[3].uop_robIdx_value <= io_fromSplit_0_req_bits_uop_robIdx_value;
      entries[3].uop_debugInfo_enqRsTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime;
      entries[3].uop_debugInfo_selectTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_selectTime;
      entries[3].uop_debugInfo_issueTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_issueTime;
      entries[3].vdIdx <= io_fromSplit_0_req_bits_vdIdx;
      entries[3].fof <= io_fromSplit_0_req_bits_fof;
      entries[3].vlmax <= io_fromSplit_0_req_bits_vlmax;
    end
    if (_GEN_310 & latchWbIndex_2 == 4'h3)
      entries[3].flowNum <= _entries_flowNum_T_4;
    else if (_GEN_309 & latchWbIndex_1 == 4'h3)
      entries[3].flowNum <= _entries_flowNum_T_2;
    else if (latchWbValid & latchWbIndex == 4'h3)
      entries[3].flowNum <= _entries_flowNum_T;
    else if (_GEN_168)
      entries[3].flowNum <= io_fromSplit_1_req_bits_flowNum;
    else if (_GEN_3)
      entries[3].flowNum <= io_fromSplit_0_req_bits_flowNum;
    if (_GEN_276 & _GEN_292 & _GEN_280) begin
      entries[3].exceptionVec_3 <= pipeBitsReg_2_exceptionVec_3;
      entries[3].exceptionVec_4 <= pipeBitsReg_2_exceptionVec_4;
      entries[3].exceptionVec_5 <= pipeBitsReg_2_exceptionVec_5;
      entries[3].exceptionVec_13 <= pipeBitsReg_2_exceptionVec_13;
      entries[3].exceptionVec_19 <= pipeBitsReg_2_exceptionVec_19;
      entries[3].exceptionVec_21 <= pipeBitsReg_2_exceptionVec_21;
      entries[3].uop_trigger <= pipeBitsReg_2_trigger;
      entries[3].vstart <= vstart_2;
      entries[3].vaNeedExt <= pipeBitsReg_2_vaNeedExt;
      entries[3].vaddr <= _vaddr_T_2;
      entries[3].gpaddr <= pipeBitsReg_2_gpaddr[49:0];
    end
    else if (_GEN_241 & _GEN_257 & _GEN_245) begin
      entries[3].exceptionVec_3 <= new_vec_3_3;
      entries[3].exceptionVec_4 <= new_vec_3_4;
      entries[3].exceptionVec_5 <= new_vec_3_5;
      entries[3].exceptionVec_13 <= new_vec_3_13;
      entries[3].exceptionVec_19 <= new_vec_3_19;
      entries[3].exceptionVec_21 <= new_vec_3_21;
      entries[3].uop_trigger <= sel_oldest_1_bits_trigger;
      entries[3].vstart <= vstart_1;
      entries[3].vaNeedExt <= sel_oldest_1_bits_vaNeedExt;
      entries[3].vaddr <= _vaddr_T_1;
      entries[3].gpaddr <= sel_oldest_1_bits_gpaddr;
    end
    else if (_GEN_205 & _GEN_221 & _GEN_209) begin
      entries[3].exceptionVec_3 <= new_vec_2_3;
      entries[3].exceptionVec_4 <= new_vec_2_4;
      entries[3].exceptionVec_5 <= new_vec_2_5;
      entries[3].exceptionVec_13 <= new_vec_2_13;
      entries[3].exceptionVec_19 <= new_vec_2_19;
      entries[3].exceptionVec_21 <= new_vec_2_21;
      entries[3].uop_trigger <= sel_oldest_bits_trigger;
      entries[3].vstart <= vstart;
      entries[3].vaNeedExt <= sel_oldest_bits_vaNeedExt;
      entries[3].vaddr <= _vaddr_T;
      entries[3].gpaddr <= sel_oldest_bits_gpaddr;
    end
    else begin
      if (_GEN_16) begin
        entries[3].exceptionVec_3 <= ~_GEN_24 & entries[3].exceptionVec_3;
        entries[3].exceptionVec_4 <= ~_GEN_24 & entries[3].exceptionVec_4;
        entries[3].exceptionVec_5 <= ~_GEN_24 & entries[3].exceptionVec_5;
        entries[3].exceptionVec_13 <= ~_GEN_24 & entries[3].exceptionVec_13;
        entries[3].exceptionVec_19 <= ~_GEN_24 & entries[3].exceptionVec_19;
        entries[3].exceptionVec_21 <= ~_GEN_24 & entries[3].exceptionVec_21;
      end
      else begin
        entries[3].exceptionVec_3 <= ~_GEN_3 & entries[3].exceptionVec_3;
        entries[3].exceptionVec_4 <= ~_GEN_3 & entries[3].exceptionVec_4;
        entries[3].exceptionVec_5 <= ~_GEN_3 & entries[3].exceptionVec_5;
        entries[3].exceptionVec_13 <= ~_GEN_3 & entries[3].exceptionVec_13;
        entries[3].exceptionVec_19 <= ~_GEN_3 & entries[3].exceptionVec_19;
        entries[3].exceptionVec_21 <= ~_GEN_3 & entries[3].exceptionVec_21;
      end
      if (_GEN_168 | _GEN_3)
        entries[3].uop_trigger <= 4'h0;
      if (_GEN_184)
        entries[3].vstart <= 8'h0;
      if (_GEN_168)
        entries[3].vaddr <= _GEN_197;
      else if (_GEN_3)
        entries[3].vaddr <= _GEN_164;
    end
    entries[3].uop_flushPipe <= ~_GEN_168 & ~_GEN_3 & entries[3].uop_flushPipe;
    entries[3].uop_vpu_vta <=
      _GEN_296 & _GEN_261 & _GEN_225
      & (_GEN_168
           ? io_fromSplit_1_req_bits_uop_vpu_vta
           : _GEN_3 ? io_fromSplit_0_req_bits_uop_vpu_vta : entries[3].uop_vpu_vta);
    entries[3].uop_replayInst <= ~_GEN_168 & ~_GEN_3 & entries[3].uop_replayInst;
    if (_GEN_276 & _GEN_280)
      entries[3].elemIdx <= pipeBitsReg_2_elemIdx;
    else if (_GEN_241 & _GEN_245)
      entries[3].elemIdx <= sel_oldest_1_bits_elemIdx;
    else if (_GEN_205 & _GEN_209)
      entries[3].elemIdx <= sel_oldest_bits_elemIdx;
    else if (_GEN_184)
      entries[3].elemIdx <= 8'hFF;
    if (_GEN_296) begin
      if (_GEN_261) begin
        if (_GEN_225) begin
          if (_GEN_168)
            entries[3].vl <= io_fromSplit_1_req_bits_uop_vpu_vl;
          else if (_GEN_3)
            entries[3].vl <= io_fromSplit_0_req_bits_uop_vpu_vl;
        end
        else if (_entries_vl_T)
          entries[3].vl <= _GEN_201;
        else
          entries[3].vl <= vstart;
      end
      else if (_entries_vl_T_2)
        entries[3].vl <= _GEN_239;
      else
        entries[3].vl <= vstart_1;
    end
    else if (_entries_vl_T_4)
      entries[3].vl <= _GEN_275;
    else
      entries[3].vl <= vstart_2;
    if (_GEN_315 & wbIndexReg_2_r == 4'h4) begin
      if (isusMerge_2)
        entries[4].data <= usMergeData_2;
      else
        entries[4].data <= mergeDataReg_2_r;
    end
    else if (_GEN_313 & wbIndexReg_1_r == 4'h4) begin
      if (isusMerge_1)
        entries[4].data <= usMergeData_1;
      else
        entries[4].data <= mergeDataReg_1_r;
    end
    else if (pipewbValidReg_0_REG & wbIndexReg_0_r == 4'h4) begin
      if (isusMerge)
        entries[4].data <= usMergeData;
      else
        entries[4].data <= mergeDataReg_0_r;
    end
    else if (_GEN_169)
      entries[4].data <= io_fromSplit_1_req_bits_data;
    else if (_GEN_4)
      entries[4].data <= io_fromSplit_0_req_bits_data;
    if (_GEN_169) begin
      entries[4].mask <= io_fromSplit_1_req_bits_mask;
      entries[4].uop_fuOpType <= io_fromSplit_1_req_bits_uop_fuOpType;
      entries[4].uop_vecWen <= io_fromSplit_1_req_bits_uop_vecWen;
      entries[4].uop_v0Wen <= io_fromSplit_1_req_bits_uop_v0Wen;
      entries[4].uop_vlWen <= io_fromSplit_1_req_bits_uop_vlWen;
      entries[4].uop_vpu_vma <= io_fromSplit_1_req_bits_uop_vpu_vma;
      entries[4].uop_vpu_vsew <= io_fromSplit_1_req_bits_uop_vpu_vsew;
      entries[4].uop_vpu_vlmul <= io_fromSplit_1_req_bits_uop_vpu_vlmul;
      entries[4].uop_vpu_vm <= io_fromSplit_1_req_bits_uop_vpu_vm;
      entries[4].uop_vpu_vuopIdx <= io_fromSplit_1_req_bits_uop_vpu_vuopIdx;
      entries[4].uop_vpu_nf <= io_fromSplit_1_req_bits_uop_vpu_nf;
      entries[4].uop_vpu_veew <= io_fromSplit_1_req_bits_uop_vpu_veew;
      entries[4].uop_uopIdx <= io_fromSplit_1_req_bits_uop_uopIdx;
      entries[4].uop_pdest <= io_fromSplit_1_req_bits_uop_pdest;
      entries[4].uop_robIdx_flag <= io_fromSplit_1_req_bits_uop_robIdx_flag;
      entries[4].uop_robIdx_value <= io_fromSplit_1_req_bits_uop_robIdx_value;
      entries[4].uop_debugInfo_enqRsTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime;
      entries[4].uop_debugInfo_selectTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_selectTime;
      entries[4].uop_debugInfo_issueTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_issueTime;
      entries[4].vdIdx <= io_fromSplit_1_req_bits_vdIdx;
      entries[4].fof <= io_fromSplit_1_req_bits_fof;
      entries[4].vlmax <= io_fromSplit_1_req_bits_vlmax;
    end
    else if (_GEN_4) begin
      entries[4].mask <= io_fromSplit_0_req_bits_mask;
      entries[4].uop_fuOpType <= io_fromSplit_0_req_bits_uop_fuOpType;
      entries[4].uop_vecWen <= io_fromSplit_0_req_bits_uop_vecWen;
      entries[4].uop_v0Wen <= io_fromSplit_0_req_bits_uop_v0Wen;
      entries[4].uop_vlWen <= io_fromSplit_0_req_bits_uop_vlWen;
      entries[4].uop_vpu_vma <= io_fromSplit_0_req_bits_uop_vpu_vma;
      entries[4].uop_vpu_vsew <= io_fromSplit_0_req_bits_uop_vpu_vsew;
      entries[4].uop_vpu_vlmul <= io_fromSplit_0_req_bits_uop_vpu_vlmul;
      entries[4].uop_vpu_vm <= io_fromSplit_0_req_bits_uop_vpu_vm;
      entries[4].uop_vpu_vuopIdx <= io_fromSplit_0_req_bits_uop_vpu_vuopIdx;
      entries[4].uop_vpu_nf <= io_fromSplit_0_req_bits_uop_vpu_nf;
      entries[4].uop_vpu_veew <= io_fromSplit_0_req_bits_uop_vpu_veew;
      entries[4].uop_uopIdx <= io_fromSplit_0_req_bits_uop_uopIdx;
      entries[4].uop_pdest <= io_fromSplit_0_req_bits_uop_pdest;
      entries[4].uop_robIdx_flag <= io_fromSplit_0_req_bits_uop_robIdx_flag;
      entries[4].uop_robIdx_value <= io_fromSplit_0_req_bits_uop_robIdx_value;
      entries[4].uop_debugInfo_enqRsTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime;
      entries[4].uop_debugInfo_selectTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_selectTime;
      entries[4].uop_debugInfo_issueTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_issueTime;
      entries[4].vdIdx <= io_fromSplit_0_req_bits_vdIdx;
      entries[4].fof <= io_fromSplit_0_req_bits_fof;
      entries[4].vlmax <= io_fromSplit_0_req_bits_vlmax;
    end
    if (_GEN_310 & latchWbIndex_2 == 4'h4)
      entries[4].flowNum <= _entries_flowNum_T_4;
    else if (_GEN_309 & latchWbIndex_1 == 4'h4)
      entries[4].flowNum <= _entries_flowNum_T_2;
    else if (latchWbValid & latchWbIndex == 4'h4)
      entries[4].flowNum <= _entries_flowNum_T;
    else if (_GEN_169)
      entries[4].flowNum <= io_fromSplit_1_req_bits_flowNum;
    else if (_GEN_4)
      entries[4].flowNum <= io_fromSplit_0_req_bits_flowNum;
    if (_GEN_276 & _GEN_292 & _GEN_281) begin
      entries[4].exceptionVec_3 <= pipeBitsReg_2_exceptionVec_3;
      entries[4].exceptionVec_4 <= pipeBitsReg_2_exceptionVec_4;
      entries[4].exceptionVec_5 <= pipeBitsReg_2_exceptionVec_5;
      entries[4].exceptionVec_13 <= pipeBitsReg_2_exceptionVec_13;
      entries[4].exceptionVec_19 <= pipeBitsReg_2_exceptionVec_19;
      entries[4].exceptionVec_21 <= pipeBitsReg_2_exceptionVec_21;
      entries[4].uop_trigger <= pipeBitsReg_2_trigger;
      entries[4].vstart <= vstart_2;
      entries[4].vaNeedExt <= pipeBitsReg_2_vaNeedExt;
      entries[4].vaddr <= _vaddr_T_2;
      entries[4].gpaddr <= pipeBitsReg_2_gpaddr[49:0];
    end
    else if (_GEN_241 & _GEN_257 & _GEN_246) begin
      entries[4].exceptionVec_3 <= new_vec_3_3;
      entries[4].exceptionVec_4 <= new_vec_3_4;
      entries[4].exceptionVec_5 <= new_vec_3_5;
      entries[4].exceptionVec_13 <= new_vec_3_13;
      entries[4].exceptionVec_19 <= new_vec_3_19;
      entries[4].exceptionVec_21 <= new_vec_3_21;
      entries[4].uop_trigger <= sel_oldest_1_bits_trigger;
      entries[4].vstart <= vstart_1;
      entries[4].vaNeedExt <= sel_oldest_1_bits_vaNeedExt;
      entries[4].vaddr <= _vaddr_T_1;
      entries[4].gpaddr <= sel_oldest_1_bits_gpaddr;
    end
    else if (_GEN_205 & _GEN_221 & _GEN_210) begin
      entries[4].exceptionVec_3 <= new_vec_2_3;
      entries[4].exceptionVec_4 <= new_vec_2_4;
      entries[4].exceptionVec_5 <= new_vec_2_5;
      entries[4].exceptionVec_13 <= new_vec_2_13;
      entries[4].exceptionVec_19 <= new_vec_2_19;
      entries[4].exceptionVec_21 <= new_vec_2_21;
      entries[4].uop_trigger <= sel_oldest_bits_trigger;
      entries[4].vstart <= vstart;
      entries[4].vaNeedExt <= sel_oldest_bits_vaNeedExt;
      entries[4].vaddr <= _vaddr_T;
      entries[4].gpaddr <= sel_oldest_bits_gpaddr;
    end
    else begin
      if (_GEN_16) begin
        entries[4].exceptionVec_3 <= ~_GEN_26 & entries[4].exceptionVec_3;
        entries[4].exceptionVec_4 <= ~_GEN_26 & entries[4].exceptionVec_4;
        entries[4].exceptionVec_5 <= ~_GEN_26 & entries[4].exceptionVec_5;
        entries[4].exceptionVec_13 <= ~_GEN_26 & entries[4].exceptionVec_13;
        entries[4].exceptionVec_19 <= ~_GEN_26 & entries[4].exceptionVec_19;
        entries[4].exceptionVec_21 <= ~_GEN_26 & entries[4].exceptionVec_21;
      end
      else begin
        entries[4].exceptionVec_3 <= ~_GEN_4 & entries[4].exceptionVec_3;
        entries[4].exceptionVec_4 <= ~_GEN_4 & entries[4].exceptionVec_4;
        entries[4].exceptionVec_5 <= ~_GEN_4 & entries[4].exceptionVec_5;
        entries[4].exceptionVec_13 <= ~_GEN_4 & entries[4].exceptionVec_13;
        entries[4].exceptionVec_19 <= ~_GEN_4 & entries[4].exceptionVec_19;
        entries[4].exceptionVec_21 <= ~_GEN_4 & entries[4].exceptionVec_21;
      end
      if (_GEN_169 | _GEN_4)
        entries[4].uop_trigger <= 4'h0;
      if (_GEN_185)
        entries[4].vstart <= 8'h0;
      if (_GEN_169)
        entries[4].vaddr <= _GEN_197;
      else if (_GEN_4)
        entries[4].vaddr <= _GEN_164;
    end
    entries[4].uop_flushPipe <= ~_GEN_169 & ~_GEN_4 & entries[4].uop_flushPipe;
    entries[4].uop_vpu_vta <=
      _GEN_297 & _GEN_262 & _GEN_226
      & (_GEN_169
           ? io_fromSplit_1_req_bits_uop_vpu_vta
           : _GEN_4 ? io_fromSplit_0_req_bits_uop_vpu_vta : entries[4].uop_vpu_vta);
    entries[4].uop_replayInst <= ~_GEN_169 & ~_GEN_4 & entries[4].uop_replayInst;
    if (_GEN_276 & _GEN_281)
      entries[4].elemIdx <= pipeBitsReg_2_elemIdx;
    else if (_GEN_241 & _GEN_246)
      entries[4].elemIdx <= sel_oldest_1_bits_elemIdx;
    else if (_GEN_205 & _GEN_210)
      entries[4].elemIdx <= sel_oldest_bits_elemIdx;
    else if (_GEN_185)
      entries[4].elemIdx <= 8'hFF;
    if (_GEN_297) begin
      if (_GEN_262) begin
        if (_GEN_226) begin
          if (_GEN_169)
            entries[4].vl <= io_fromSplit_1_req_bits_uop_vpu_vl;
          else if (_GEN_4)
            entries[4].vl <= io_fromSplit_0_req_bits_uop_vpu_vl;
        end
        else if (_entries_vl_T)
          entries[4].vl <= _GEN_201;
        else
          entries[4].vl <= vstart;
      end
      else if (_entries_vl_T_2)
        entries[4].vl <= _GEN_239;
      else
        entries[4].vl <= vstart_1;
    end
    else if (_entries_vl_T_4)
      entries[4].vl <= _GEN_275;
    else
      entries[4].vl <= vstart_2;
    if (_GEN_315 & wbIndexReg_2_r == 4'h5) begin
      if (isusMerge_2)
        entries[5].data <= usMergeData_2;
      else
        entries[5].data <= mergeDataReg_2_r;
    end
    else if (_GEN_313 & wbIndexReg_1_r == 4'h5) begin
      if (isusMerge_1)
        entries[5].data <= usMergeData_1;
      else
        entries[5].data <= mergeDataReg_1_r;
    end
    else if (pipewbValidReg_0_REG & wbIndexReg_0_r == 4'h5) begin
      if (isusMerge)
        entries[5].data <= usMergeData;
      else
        entries[5].data <= mergeDataReg_0_r;
    end
    else if (_GEN_170)
      entries[5].data <= io_fromSplit_1_req_bits_data;
    else if (_GEN_5)
      entries[5].data <= io_fromSplit_0_req_bits_data;
    if (_GEN_170) begin
      entries[5].mask <= io_fromSplit_1_req_bits_mask;
      entries[5].uop_fuOpType <= io_fromSplit_1_req_bits_uop_fuOpType;
      entries[5].uop_vecWen <= io_fromSplit_1_req_bits_uop_vecWen;
      entries[5].uop_v0Wen <= io_fromSplit_1_req_bits_uop_v0Wen;
      entries[5].uop_vlWen <= io_fromSplit_1_req_bits_uop_vlWen;
      entries[5].uop_vpu_vma <= io_fromSplit_1_req_bits_uop_vpu_vma;
      entries[5].uop_vpu_vsew <= io_fromSplit_1_req_bits_uop_vpu_vsew;
      entries[5].uop_vpu_vlmul <= io_fromSplit_1_req_bits_uop_vpu_vlmul;
      entries[5].uop_vpu_vm <= io_fromSplit_1_req_bits_uop_vpu_vm;
      entries[5].uop_vpu_vuopIdx <= io_fromSplit_1_req_bits_uop_vpu_vuopIdx;
      entries[5].uop_vpu_nf <= io_fromSplit_1_req_bits_uop_vpu_nf;
      entries[5].uop_vpu_veew <= io_fromSplit_1_req_bits_uop_vpu_veew;
      entries[5].uop_uopIdx <= io_fromSplit_1_req_bits_uop_uopIdx;
      entries[5].uop_pdest <= io_fromSplit_1_req_bits_uop_pdest;
      entries[5].uop_robIdx_flag <= io_fromSplit_1_req_bits_uop_robIdx_flag;
      entries[5].uop_robIdx_value <= io_fromSplit_1_req_bits_uop_robIdx_value;
      entries[5].uop_debugInfo_enqRsTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime;
      entries[5].uop_debugInfo_selectTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_selectTime;
      entries[5].uop_debugInfo_issueTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_issueTime;
      entries[5].vdIdx <= io_fromSplit_1_req_bits_vdIdx;
      entries[5].fof <= io_fromSplit_1_req_bits_fof;
      entries[5].vlmax <= io_fromSplit_1_req_bits_vlmax;
    end
    else if (_GEN_5) begin
      entries[5].mask <= io_fromSplit_0_req_bits_mask;
      entries[5].uop_fuOpType <= io_fromSplit_0_req_bits_uop_fuOpType;
      entries[5].uop_vecWen <= io_fromSplit_0_req_bits_uop_vecWen;
      entries[5].uop_v0Wen <= io_fromSplit_0_req_bits_uop_v0Wen;
      entries[5].uop_vlWen <= io_fromSplit_0_req_bits_uop_vlWen;
      entries[5].uop_vpu_vma <= io_fromSplit_0_req_bits_uop_vpu_vma;
      entries[5].uop_vpu_vsew <= io_fromSplit_0_req_bits_uop_vpu_vsew;
      entries[5].uop_vpu_vlmul <= io_fromSplit_0_req_bits_uop_vpu_vlmul;
      entries[5].uop_vpu_vm <= io_fromSplit_0_req_bits_uop_vpu_vm;
      entries[5].uop_vpu_vuopIdx <= io_fromSplit_0_req_bits_uop_vpu_vuopIdx;
      entries[5].uop_vpu_nf <= io_fromSplit_0_req_bits_uop_vpu_nf;
      entries[5].uop_vpu_veew <= io_fromSplit_0_req_bits_uop_vpu_veew;
      entries[5].uop_uopIdx <= io_fromSplit_0_req_bits_uop_uopIdx;
      entries[5].uop_pdest <= io_fromSplit_0_req_bits_uop_pdest;
      entries[5].uop_robIdx_flag <= io_fromSplit_0_req_bits_uop_robIdx_flag;
      entries[5].uop_robIdx_value <= io_fromSplit_0_req_bits_uop_robIdx_value;
      entries[5].uop_debugInfo_enqRsTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime;
      entries[5].uop_debugInfo_selectTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_selectTime;
      entries[5].uop_debugInfo_issueTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_issueTime;
      entries[5].vdIdx <= io_fromSplit_0_req_bits_vdIdx;
      entries[5].fof <= io_fromSplit_0_req_bits_fof;
      entries[5].vlmax <= io_fromSplit_0_req_bits_vlmax;
    end
    if (_GEN_310 & latchWbIndex_2 == 4'h5)
      entries[5].flowNum <= _entries_flowNum_T_4;
    else if (_GEN_309 & latchWbIndex_1 == 4'h5)
      entries[5].flowNum <= _entries_flowNum_T_2;
    else if (latchWbValid & latchWbIndex == 4'h5)
      entries[5].flowNum <= _entries_flowNum_T;
    else if (_GEN_170)
      entries[5].flowNum <= io_fromSplit_1_req_bits_flowNum;
    else if (_GEN_5)
      entries[5].flowNum <= io_fromSplit_0_req_bits_flowNum;
    if (_GEN_276 & _GEN_292 & _GEN_282) begin
      entries[5].exceptionVec_3 <= pipeBitsReg_2_exceptionVec_3;
      entries[5].exceptionVec_4 <= pipeBitsReg_2_exceptionVec_4;
      entries[5].exceptionVec_5 <= pipeBitsReg_2_exceptionVec_5;
      entries[5].exceptionVec_13 <= pipeBitsReg_2_exceptionVec_13;
      entries[5].exceptionVec_19 <= pipeBitsReg_2_exceptionVec_19;
      entries[5].exceptionVec_21 <= pipeBitsReg_2_exceptionVec_21;
      entries[5].uop_trigger <= pipeBitsReg_2_trigger;
      entries[5].vstart <= vstart_2;
      entries[5].vaNeedExt <= pipeBitsReg_2_vaNeedExt;
      entries[5].vaddr <= _vaddr_T_2;
      entries[5].gpaddr <= pipeBitsReg_2_gpaddr[49:0];
    end
    else if (_GEN_241 & _GEN_257 & _GEN_247) begin
      entries[5].exceptionVec_3 <= new_vec_3_3;
      entries[5].exceptionVec_4 <= new_vec_3_4;
      entries[5].exceptionVec_5 <= new_vec_3_5;
      entries[5].exceptionVec_13 <= new_vec_3_13;
      entries[5].exceptionVec_19 <= new_vec_3_19;
      entries[5].exceptionVec_21 <= new_vec_3_21;
      entries[5].uop_trigger <= sel_oldest_1_bits_trigger;
      entries[5].vstart <= vstart_1;
      entries[5].vaNeedExt <= sel_oldest_1_bits_vaNeedExt;
      entries[5].vaddr <= _vaddr_T_1;
      entries[5].gpaddr <= sel_oldest_1_bits_gpaddr;
    end
    else if (_GEN_205 & _GEN_221 & _GEN_211) begin
      entries[5].exceptionVec_3 <= new_vec_2_3;
      entries[5].exceptionVec_4 <= new_vec_2_4;
      entries[5].exceptionVec_5 <= new_vec_2_5;
      entries[5].exceptionVec_13 <= new_vec_2_13;
      entries[5].exceptionVec_19 <= new_vec_2_19;
      entries[5].exceptionVec_21 <= new_vec_2_21;
      entries[5].uop_trigger <= sel_oldest_bits_trigger;
      entries[5].vstart <= vstart;
      entries[5].vaNeedExt <= sel_oldest_bits_vaNeedExt;
      entries[5].vaddr <= _vaddr_T;
      entries[5].gpaddr <= sel_oldest_bits_gpaddr;
    end
    else begin
      if (_GEN_16) begin
        entries[5].exceptionVec_3 <= ~_GEN_28 & entries[5].exceptionVec_3;
        entries[5].exceptionVec_4 <= ~_GEN_28 & entries[5].exceptionVec_4;
        entries[5].exceptionVec_5 <= ~_GEN_28 & entries[5].exceptionVec_5;
        entries[5].exceptionVec_13 <= ~_GEN_28 & entries[5].exceptionVec_13;
        entries[5].exceptionVec_19 <= ~_GEN_28 & entries[5].exceptionVec_19;
        entries[5].exceptionVec_21 <= ~_GEN_28 & entries[5].exceptionVec_21;
      end
      else begin
        entries[5].exceptionVec_3 <= ~_GEN_5 & entries[5].exceptionVec_3;
        entries[5].exceptionVec_4 <= ~_GEN_5 & entries[5].exceptionVec_4;
        entries[5].exceptionVec_5 <= ~_GEN_5 & entries[5].exceptionVec_5;
        entries[5].exceptionVec_13 <= ~_GEN_5 & entries[5].exceptionVec_13;
        entries[5].exceptionVec_19 <= ~_GEN_5 & entries[5].exceptionVec_19;
        entries[5].exceptionVec_21 <= ~_GEN_5 & entries[5].exceptionVec_21;
      end
      if (_GEN_170 | _GEN_5)
        entries[5].uop_trigger <= 4'h0;
      if (_GEN_186)
        entries[5].vstart <= 8'h0;
      if (_GEN_170)
        entries[5].vaddr <= _GEN_197;
      else if (_GEN_5)
        entries[5].vaddr <= _GEN_164;
    end
    entries[5].uop_flushPipe <= ~_GEN_170 & ~_GEN_5 & entries[5].uop_flushPipe;
    entries[5].uop_vpu_vta <=
      _GEN_298 & _GEN_263 & _GEN_227
      & (_GEN_170
           ? io_fromSplit_1_req_bits_uop_vpu_vta
           : _GEN_5 ? io_fromSplit_0_req_bits_uop_vpu_vta : entries[5].uop_vpu_vta);
    entries[5].uop_replayInst <= ~_GEN_170 & ~_GEN_5 & entries[5].uop_replayInst;
    if (_GEN_276 & _GEN_282)
      entries[5].elemIdx <= pipeBitsReg_2_elemIdx;
    else if (_GEN_241 & _GEN_247)
      entries[5].elemIdx <= sel_oldest_1_bits_elemIdx;
    else if (_GEN_205 & _GEN_211)
      entries[5].elemIdx <= sel_oldest_bits_elemIdx;
    else if (_GEN_186)
      entries[5].elemIdx <= 8'hFF;
    if (_GEN_298) begin
      if (_GEN_263) begin
        if (_GEN_227) begin
          if (_GEN_170)
            entries[5].vl <= io_fromSplit_1_req_bits_uop_vpu_vl;
          else if (_GEN_5)
            entries[5].vl <= io_fromSplit_0_req_bits_uop_vpu_vl;
        end
        else if (_entries_vl_T)
          entries[5].vl <= _GEN_201;
        else
          entries[5].vl <= vstart;
      end
      else if (_entries_vl_T_2)
        entries[5].vl <= _GEN_239;
      else
        entries[5].vl <= vstart_1;
    end
    else if (_entries_vl_T_4)
      entries[5].vl <= _GEN_275;
    else
      entries[5].vl <= vstart_2;
    if (_GEN_315 & wbIndexReg_2_r == 4'h6) begin
      if (isusMerge_2)
        entries[6].data <= usMergeData_2;
      else
        entries[6].data <= mergeDataReg_2_r;
    end
    else if (_GEN_313 & wbIndexReg_1_r == 4'h6) begin
      if (isusMerge_1)
        entries[6].data <= usMergeData_1;
      else
        entries[6].data <= mergeDataReg_1_r;
    end
    else if (pipewbValidReg_0_REG & wbIndexReg_0_r == 4'h6) begin
      if (isusMerge)
        entries[6].data <= usMergeData;
      else
        entries[6].data <= mergeDataReg_0_r;
    end
    else if (_GEN_171)
      entries[6].data <= io_fromSplit_1_req_bits_data;
    else if (_GEN_6)
      entries[6].data <= io_fromSplit_0_req_bits_data;
    if (_GEN_171) begin
      entries[6].mask <= io_fromSplit_1_req_bits_mask;
      entries[6].uop_fuOpType <= io_fromSplit_1_req_bits_uop_fuOpType;
      entries[6].uop_vecWen <= io_fromSplit_1_req_bits_uop_vecWen;
      entries[6].uop_v0Wen <= io_fromSplit_1_req_bits_uop_v0Wen;
      entries[6].uop_vlWen <= io_fromSplit_1_req_bits_uop_vlWen;
      entries[6].uop_vpu_vma <= io_fromSplit_1_req_bits_uop_vpu_vma;
      entries[6].uop_vpu_vsew <= io_fromSplit_1_req_bits_uop_vpu_vsew;
      entries[6].uop_vpu_vlmul <= io_fromSplit_1_req_bits_uop_vpu_vlmul;
      entries[6].uop_vpu_vm <= io_fromSplit_1_req_bits_uop_vpu_vm;
      entries[6].uop_vpu_vuopIdx <= io_fromSplit_1_req_bits_uop_vpu_vuopIdx;
      entries[6].uop_vpu_nf <= io_fromSplit_1_req_bits_uop_vpu_nf;
      entries[6].uop_vpu_veew <= io_fromSplit_1_req_bits_uop_vpu_veew;
      entries[6].uop_uopIdx <= io_fromSplit_1_req_bits_uop_uopIdx;
      entries[6].uop_pdest <= io_fromSplit_1_req_bits_uop_pdest;
      entries[6].uop_robIdx_flag <= io_fromSplit_1_req_bits_uop_robIdx_flag;
      entries[6].uop_robIdx_value <= io_fromSplit_1_req_bits_uop_robIdx_value;
      entries[6].uop_debugInfo_enqRsTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime;
      entries[6].uop_debugInfo_selectTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_selectTime;
      entries[6].uop_debugInfo_issueTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_issueTime;
      entries[6].vdIdx <= io_fromSplit_1_req_bits_vdIdx;
      entries[6].fof <= io_fromSplit_1_req_bits_fof;
      entries[6].vlmax <= io_fromSplit_1_req_bits_vlmax;
    end
    else if (_GEN_6) begin
      entries[6].mask <= io_fromSplit_0_req_bits_mask;
      entries[6].uop_fuOpType <= io_fromSplit_0_req_bits_uop_fuOpType;
      entries[6].uop_vecWen <= io_fromSplit_0_req_bits_uop_vecWen;
      entries[6].uop_v0Wen <= io_fromSplit_0_req_bits_uop_v0Wen;
      entries[6].uop_vlWen <= io_fromSplit_0_req_bits_uop_vlWen;
      entries[6].uop_vpu_vma <= io_fromSplit_0_req_bits_uop_vpu_vma;
      entries[6].uop_vpu_vsew <= io_fromSplit_0_req_bits_uop_vpu_vsew;
      entries[6].uop_vpu_vlmul <= io_fromSplit_0_req_bits_uop_vpu_vlmul;
      entries[6].uop_vpu_vm <= io_fromSplit_0_req_bits_uop_vpu_vm;
      entries[6].uop_vpu_vuopIdx <= io_fromSplit_0_req_bits_uop_vpu_vuopIdx;
      entries[6].uop_vpu_nf <= io_fromSplit_0_req_bits_uop_vpu_nf;
      entries[6].uop_vpu_veew <= io_fromSplit_0_req_bits_uop_vpu_veew;
      entries[6].uop_uopIdx <= io_fromSplit_0_req_bits_uop_uopIdx;
      entries[6].uop_pdest <= io_fromSplit_0_req_bits_uop_pdest;
      entries[6].uop_robIdx_flag <= io_fromSplit_0_req_bits_uop_robIdx_flag;
      entries[6].uop_robIdx_value <= io_fromSplit_0_req_bits_uop_robIdx_value;
      entries[6].uop_debugInfo_enqRsTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime;
      entries[6].uop_debugInfo_selectTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_selectTime;
      entries[6].uop_debugInfo_issueTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_issueTime;
      entries[6].vdIdx <= io_fromSplit_0_req_bits_vdIdx;
      entries[6].fof <= io_fromSplit_0_req_bits_fof;
      entries[6].vlmax <= io_fromSplit_0_req_bits_vlmax;
    end
    if (_GEN_310 & latchWbIndex_2 == 4'h6)
      entries[6].flowNum <= _entries_flowNum_T_4;
    else if (_GEN_309 & latchWbIndex_1 == 4'h6)
      entries[6].flowNum <= _entries_flowNum_T_2;
    else if (latchWbValid & latchWbIndex == 4'h6)
      entries[6].flowNum <= _entries_flowNum_T;
    else if (_GEN_171)
      entries[6].flowNum <= io_fromSplit_1_req_bits_flowNum;
    else if (_GEN_6)
      entries[6].flowNum <= io_fromSplit_0_req_bits_flowNum;
    if (_GEN_276 & _GEN_292 & _GEN_283) begin
      entries[6].exceptionVec_3 <= pipeBitsReg_2_exceptionVec_3;
      entries[6].exceptionVec_4 <= pipeBitsReg_2_exceptionVec_4;
      entries[6].exceptionVec_5 <= pipeBitsReg_2_exceptionVec_5;
      entries[6].exceptionVec_13 <= pipeBitsReg_2_exceptionVec_13;
      entries[6].exceptionVec_19 <= pipeBitsReg_2_exceptionVec_19;
      entries[6].exceptionVec_21 <= pipeBitsReg_2_exceptionVec_21;
      entries[6].uop_trigger <= pipeBitsReg_2_trigger;
      entries[6].vstart <= vstart_2;
      entries[6].vaNeedExt <= pipeBitsReg_2_vaNeedExt;
      entries[6].vaddr <= _vaddr_T_2;
      entries[6].gpaddr <= pipeBitsReg_2_gpaddr[49:0];
    end
    else if (_GEN_241 & _GEN_257 & _GEN_248) begin
      entries[6].exceptionVec_3 <= new_vec_3_3;
      entries[6].exceptionVec_4 <= new_vec_3_4;
      entries[6].exceptionVec_5 <= new_vec_3_5;
      entries[6].exceptionVec_13 <= new_vec_3_13;
      entries[6].exceptionVec_19 <= new_vec_3_19;
      entries[6].exceptionVec_21 <= new_vec_3_21;
      entries[6].uop_trigger <= sel_oldest_1_bits_trigger;
      entries[6].vstart <= vstart_1;
      entries[6].vaNeedExt <= sel_oldest_1_bits_vaNeedExt;
      entries[6].vaddr <= _vaddr_T_1;
      entries[6].gpaddr <= sel_oldest_1_bits_gpaddr;
    end
    else if (_GEN_205 & _GEN_221 & _GEN_212) begin
      entries[6].exceptionVec_3 <= new_vec_2_3;
      entries[6].exceptionVec_4 <= new_vec_2_4;
      entries[6].exceptionVec_5 <= new_vec_2_5;
      entries[6].exceptionVec_13 <= new_vec_2_13;
      entries[6].exceptionVec_19 <= new_vec_2_19;
      entries[6].exceptionVec_21 <= new_vec_2_21;
      entries[6].uop_trigger <= sel_oldest_bits_trigger;
      entries[6].vstart <= vstart;
      entries[6].vaNeedExt <= sel_oldest_bits_vaNeedExt;
      entries[6].vaddr <= _vaddr_T;
      entries[6].gpaddr <= sel_oldest_bits_gpaddr;
    end
    else begin
      if (_GEN_16) begin
        entries[6].exceptionVec_3 <= ~_GEN_30 & entries[6].exceptionVec_3;
        entries[6].exceptionVec_4 <= ~_GEN_30 & entries[6].exceptionVec_4;
        entries[6].exceptionVec_5 <= ~_GEN_30 & entries[6].exceptionVec_5;
        entries[6].exceptionVec_13 <= ~_GEN_30 & entries[6].exceptionVec_13;
        entries[6].exceptionVec_19 <= ~_GEN_30 & entries[6].exceptionVec_19;
        entries[6].exceptionVec_21 <= ~_GEN_30 & entries[6].exceptionVec_21;
      end
      else begin
        entries[6].exceptionVec_3 <= ~_GEN_6 & entries[6].exceptionVec_3;
        entries[6].exceptionVec_4 <= ~_GEN_6 & entries[6].exceptionVec_4;
        entries[6].exceptionVec_5 <= ~_GEN_6 & entries[6].exceptionVec_5;
        entries[6].exceptionVec_13 <= ~_GEN_6 & entries[6].exceptionVec_13;
        entries[6].exceptionVec_19 <= ~_GEN_6 & entries[6].exceptionVec_19;
        entries[6].exceptionVec_21 <= ~_GEN_6 & entries[6].exceptionVec_21;
      end
      if (_GEN_171 | _GEN_6)
        entries[6].uop_trigger <= 4'h0;
      if (_GEN_187)
        entries[6].vstart <= 8'h0;
      if (_GEN_171)
        entries[6].vaddr <= _GEN_197;
      else if (_GEN_6)
        entries[6].vaddr <= _GEN_164;
    end
    entries[6].uop_flushPipe <= ~_GEN_171 & ~_GEN_6 & entries[6].uop_flushPipe;
    entries[6].uop_vpu_vta <=
      _GEN_299 & _GEN_264 & _GEN_228
      & (_GEN_171
           ? io_fromSplit_1_req_bits_uop_vpu_vta
           : _GEN_6 ? io_fromSplit_0_req_bits_uop_vpu_vta : entries[6].uop_vpu_vta);
    entries[6].uop_replayInst <= ~_GEN_171 & ~_GEN_6 & entries[6].uop_replayInst;
    if (_GEN_276 & _GEN_283)
      entries[6].elemIdx <= pipeBitsReg_2_elemIdx;
    else if (_GEN_241 & _GEN_248)
      entries[6].elemIdx <= sel_oldest_1_bits_elemIdx;
    else if (_GEN_205 & _GEN_212)
      entries[6].elemIdx <= sel_oldest_bits_elemIdx;
    else if (_GEN_187)
      entries[6].elemIdx <= 8'hFF;
    if (_GEN_299) begin
      if (_GEN_264) begin
        if (_GEN_228) begin
          if (_GEN_171)
            entries[6].vl <= io_fromSplit_1_req_bits_uop_vpu_vl;
          else if (_GEN_6)
            entries[6].vl <= io_fromSplit_0_req_bits_uop_vpu_vl;
        end
        else if (_entries_vl_T)
          entries[6].vl <= _GEN_201;
        else
          entries[6].vl <= vstart;
      end
      else if (_entries_vl_T_2)
        entries[6].vl <= _GEN_239;
      else
        entries[6].vl <= vstart_1;
    end
    else if (_entries_vl_T_4)
      entries[6].vl <= _GEN_275;
    else
      entries[6].vl <= vstart_2;
    if (_GEN_315 & wbIndexReg_2_r == 4'h7) begin
      if (isusMerge_2)
        entries[7].data <= usMergeData_2;
      else
        entries[7].data <= mergeDataReg_2_r;
    end
    else if (_GEN_313 & wbIndexReg_1_r == 4'h7) begin
      if (isusMerge_1)
        entries[7].data <= usMergeData_1;
      else
        entries[7].data <= mergeDataReg_1_r;
    end
    else if (pipewbValidReg_0_REG & wbIndexReg_0_r == 4'h7) begin
      if (isusMerge)
        entries[7].data <= usMergeData;
      else
        entries[7].data <= mergeDataReg_0_r;
    end
    else if (_GEN_172)
      entries[7].data <= io_fromSplit_1_req_bits_data;
    else if (_GEN_7)
      entries[7].data <= io_fromSplit_0_req_bits_data;
    if (_GEN_172) begin
      entries[7].mask <= io_fromSplit_1_req_bits_mask;
      entries[7].uop_fuOpType <= io_fromSplit_1_req_bits_uop_fuOpType;
      entries[7].uop_vecWen <= io_fromSplit_1_req_bits_uop_vecWen;
      entries[7].uop_v0Wen <= io_fromSplit_1_req_bits_uop_v0Wen;
      entries[7].uop_vlWen <= io_fromSplit_1_req_bits_uop_vlWen;
      entries[7].uop_vpu_vma <= io_fromSplit_1_req_bits_uop_vpu_vma;
      entries[7].uop_vpu_vsew <= io_fromSplit_1_req_bits_uop_vpu_vsew;
      entries[7].uop_vpu_vlmul <= io_fromSplit_1_req_bits_uop_vpu_vlmul;
      entries[7].uop_vpu_vm <= io_fromSplit_1_req_bits_uop_vpu_vm;
      entries[7].uop_vpu_vuopIdx <= io_fromSplit_1_req_bits_uop_vpu_vuopIdx;
      entries[7].uop_vpu_nf <= io_fromSplit_1_req_bits_uop_vpu_nf;
      entries[7].uop_vpu_veew <= io_fromSplit_1_req_bits_uop_vpu_veew;
      entries[7].uop_uopIdx <= io_fromSplit_1_req_bits_uop_uopIdx;
      entries[7].uop_pdest <= io_fromSplit_1_req_bits_uop_pdest;
      entries[7].uop_robIdx_flag <= io_fromSplit_1_req_bits_uop_robIdx_flag;
      entries[7].uop_robIdx_value <= io_fromSplit_1_req_bits_uop_robIdx_value;
      entries[7].uop_debugInfo_enqRsTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime;
      entries[7].uop_debugInfo_selectTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_selectTime;
      entries[7].uop_debugInfo_issueTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_issueTime;
      entries[7].vdIdx <= io_fromSplit_1_req_bits_vdIdx;
      entries[7].fof <= io_fromSplit_1_req_bits_fof;
      entries[7].vlmax <= io_fromSplit_1_req_bits_vlmax;
    end
    else if (_GEN_7) begin
      entries[7].mask <= io_fromSplit_0_req_bits_mask;
      entries[7].uop_fuOpType <= io_fromSplit_0_req_bits_uop_fuOpType;
      entries[7].uop_vecWen <= io_fromSplit_0_req_bits_uop_vecWen;
      entries[7].uop_v0Wen <= io_fromSplit_0_req_bits_uop_v0Wen;
      entries[7].uop_vlWen <= io_fromSplit_0_req_bits_uop_vlWen;
      entries[7].uop_vpu_vma <= io_fromSplit_0_req_bits_uop_vpu_vma;
      entries[7].uop_vpu_vsew <= io_fromSplit_0_req_bits_uop_vpu_vsew;
      entries[7].uop_vpu_vlmul <= io_fromSplit_0_req_bits_uop_vpu_vlmul;
      entries[7].uop_vpu_vm <= io_fromSplit_0_req_bits_uop_vpu_vm;
      entries[7].uop_vpu_vuopIdx <= io_fromSplit_0_req_bits_uop_vpu_vuopIdx;
      entries[7].uop_vpu_nf <= io_fromSplit_0_req_bits_uop_vpu_nf;
      entries[7].uop_vpu_veew <= io_fromSplit_0_req_bits_uop_vpu_veew;
      entries[7].uop_uopIdx <= io_fromSplit_0_req_bits_uop_uopIdx;
      entries[7].uop_pdest <= io_fromSplit_0_req_bits_uop_pdest;
      entries[7].uop_robIdx_flag <= io_fromSplit_0_req_bits_uop_robIdx_flag;
      entries[7].uop_robIdx_value <= io_fromSplit_0_req_bits_uop_robIdx_value;
      entries[7].uop_debugInfo_enqRsTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime;
      entries[7].uop_debugInfo_selectTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_selectTime;
      entries[7].uop_debugInfo_issueTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_issueTime;
      entries[7].vdIdx <= io_fromSplit_0_req_bits_vdIdx;
      entries[7].fof <= io_fromSplit_0_req_bits_fof;
      entries[7].vlmax <= io_fromSplit_0_req_bits_vlmax;
    end
    if (_GEN_310 & latchWbIndex_2 == 4'h7)
      entries[7].flowNum <= _entries_flowNum_T_4;
    else if (_GEN_309 & latchWbIndex_1 == 4'h7)
      entries[7].flowNum <= _entries_flowNum_T_2;
    else if (latchWbValid & latchWbIndex == 4'h7)
      entries[7].flowNum <= _entries_flowNum_T;
    else if (_GEN_172)
      entries[7].flowNum <= io_fromSplit_1_req_bits_flowNum;
    else if (_GEN_7)
      entries[7].flowNum <= io_fromSplit_0_req_bits_flowNum;
    if (_GEN_276 & _GEN_292 & _GEN_284) begin
      entries[7].exceptionVec_3 <= pipeBitsReg_2_exceptionVec_3;
      entries[7].exceptionVec_4 <= pipeBitsReg_2_exceptionVec_4;
      entries[7].exceptionVec_5 <= pipeBitsReg_2_exceptionVec_5;
      entries[7].exceptionVec_13 <= pipeBitsReg_2_exceptionVec_13;
      entries[7].exceptionVec_19 <= pipeBitsReg_2_exceptionVec_19;
      entries[7].exceptionVec_21 <= pipeBitsReg_2_exceptionVec_21;
      entries[7].uop_trigger <= pipeBitsReg_2_trigger;
      entries[7].vstart <= vstart_2;
      entries[7].vaNeedExt <= pipeBitsReg_2_vaNeedExt;
      entries[7].vaddr <= _vaddr_T_2;
      entries[7].gpaddr <= pipeBitsReg_2_gpaddr[49:0];
    end
    else if (_GEN_241 & _GEN_257 & _GEN_249) begin
      entries[7].exceptionVec_3 <= new_vec_3_3;
      entries[7].exceptionVec_4 <= new_vec_3_4;
      entries[7].exceptionVec_5 <= new_vec_3_5;
      entries[7].exceptionVec_13 <= new_vec_3_13;
      entries[7].exceptionVec_19 <= new_vec_3_19;
      entries[7].exceptionVec_21 <= new_vec_3_21;
      entries[7].uop_trigger <= sel_oldest_1_bits_trigger;
      entries[7].vstart <= vstart_1;
      entries[7].vaNeedExt <= sel_oldest_1_bits_vaNeedExt;
      entries[7].vaddr <= _vaddr_T_1;
      entries[7].gpaddr <= sel_oldest_1_bits_gpaddr;
    end
    else if (_GEN_205 & _GEN_221 & _GEN_213) begin
      entries[7].exceptionVec_3 <= new_vec_2_3;
      entries[7].exceptionVec_4 <= new_vec_2_4;
      entries[7].exceptionVec_5 <= new_vec_2_5;
      entries[7].exceptionVec_13 <= new_vec_2_13;
      entries[7].exceptionVec_19 <= new_vec_2_19;
      entries[7].exceptionVec_21 <= new_vec_2_21;
      entries[7].uop_trigger <= sel_oldest_bits_trigger;
      entries[7].vstart <= vstart;
      entries[7].vaNeedExt <= sel_oldest_bits_vaNeedExt;
      entries[7].vaddr <= _vaddr_T;
      entries[7].gpaddr <= sel_oldest_bits_gpaddr;
    end
    else begin
      if (_GEN_16) begin
        entries[7].exceptionVec_3 <= ~_GEN_32 & entries[7].exceptionVec_3;
        entries[7].exceptionVec_4 <= ~_GEN_32 & entries[7].exceptionVec_4;
        entries[7].exceptionVec_5 <= ~_GEN_32 & entries[7].exceptionVec_5;
        entries[7].exceptionVec_13 <= ~_GEN_32 & entries[7].exceptionVec_13;
        entries[7].exceptionVec_19 <= ~_GEN_32 & entries[7].exceptionVec_19;
        entries[7].exceptionVec_21 <= ~_GEN_32 & entries[7].exceptionVec_21;
      end
      else begin
        entries[7].exceptionVec_3 <= ~_GEN_7 & entries[7].exceptionVec_3;
        entries[7].exceptionVec_4 <= ~_GEN_7 & entries[7].exceptionVec_4;
        entries[7].exceptionVec_5 <= ~_GEN_7 & entries[7].exceptionVec_5;
        entries[7].exceptionVec_13 <= ~_GEN_7 & entries[7].exceptionVec_13;
        entries[7].exceptionVec_19 <= ~_GEN_7 & entries[7].exceptionVec_19;
        entries[7].exceptionVec_21 <= ~_GEN_7 & entries[7].exceptionVec_21;
      end
      if (_GEN_172 | _GEN_7)
        entries[7].uop_trigger <= 4'h0;
      if (_GEN_188)
        entries[7].vstart <= 8'h0;
      if (_GEN_172)
        entries[7].vaddr <= _GEN_197;
      else if (_GEN_7)
        entries[7].vaddr <= _GEN_164;
    end
    entries[7].uop_flushPipe <= ~_GEN_172 & ~_GEN_7 & entries[7].uop_flushPipe;
    entries[7].uop_vpu_vta <=
      _GEN_300 & _GEN_265 & _GEN_229
      & (_GEN_172
           ? io_fromSplit_1_req_bits_uop_vpu_vta
           : _GEN_7 ? io_fromSplit_0_req_bits_uop_vpu_vta : entries[7].uop_vpu_vta);
    entries[7].uop_replayInst <= ~_GEN_172 & ~_GEN_7 & entries[7].uop_replayInst;
    if (_GEN_276 & _GEN_284)
      entries[7].elemIdx <= pipeBitsReg_2_elemIdx;
    else if (_GEN_241 & _GEN_249)
      entries[7].elemIdx <= sel_oldest_1_bits_elemIdx;
    else if (_GEN_205 & _GEN_213)
      entries[7].elemIdx <= sel_oldest_bits_elemIdx;
    else if (_GEN_188)
      entries[7].elemIdx <= 8'hFF;
    if (_GEN_300) begin
      if (_GEN_265) begin
        if (_GEN_229) begin
          if (_GEN_172)
            entries[7].vl <= io_fromSplit_1_req_bits_uop_vpu_vl;
          else if (_GEN_7)
            entries[7].vl <= io_fromSplit_0_req_bits_uop_vpu_vl;
        end
        else if (_entries_vl_T)
          entries[7].vl <= _GEN_201;
        else
          entries[7].vl <= vstart;
      end
      else if (_entries_vl_T_2)
        entries[7].vl <= _GEN_239;
      else
        entries[7].vl <= vstart_1;
    end
    else if (_entries_vl_T_4)
      entries[7].vl <= _GEN_275;
    else
      entries[7].vl <= vstart_2;
    if (_GEN_315 & wbIndexReg_2_r == 4'h8) begin
      if (isusMerge_2)
        entries[8].data <= usMergeData_2;
      else
        entries[8].data <= mergeDataReg_2_r;
    end
    else if (_GEN_313 & wbIndexReg_1_r == 4'h8) begin
      if (isusMerge_1)
        entries[8].data <= usMergeData_1;
      else
        entries[8].data <= mergeDataReg_1_r;
    end
    else if (pipewbValidReg_0_REG & wbIndexReg_0_r == 4'h8) begin
      if (isusMerge)
        entries[8].data <= usMergeData;
      else
        entries[8].data <= mergeDataReg_0_r;
    end
    else if (_GEN_173)
      entries[8].data <= io_fromSplit_1_req_bits_data;
    else if (_GEN_8)
      entries[8].data <= io_fromSplit_0_req_bits_data;
    if (_GEN_173) begin
      entries[8].mask <= io_fromSplit_1_req_bits_mask;
      entries[8].uop_fuOpType <= io_fromSplit_1_req_bits_uop_fuOpType;
      entries[8].uop_vecWen <= io_fromSplit_1_req_bits_uop_vecWen;
      entries[8].uop_v0Wen <= io_fromSplit_1_req_bits_uop_v0Wen;
      entries[8].uop_vlWen <= io_fromSplit_1_req_bits_uop_vlWen;
      entries[8].uop_vpu_vma <= io_fromSplit_1_req_bits_uop_vpu_vma;
      entries[8].uop_vpu_vsew <= io_fromSplit_1_req_bits_uop_vpu_vsew;
      entries[8].uop_vpu_vlmul <= io_fromSplit_1_req_bits_uop_vpu_vlmul;
      entries[8].uop_vpu_vm <= io_fromSplit_1_req_bits_uop_vpu_vm;
      entries[8].uop_vpu_vuopIdx <= io_fromSplit_1_req_bits_uop_vpu_vuopIdx;
      entries[8].uop_vpu_nf <= io_fromSplit_1_req_bits_uop_vpu_nf;
      entries[8].uop_vpu_veew <= io_fromSplit_1_req_bits_uop_vpu_veew;
      entries[8].uop_uopIdx <= io_fromSplit_1_req_bits_uop_uopIdx;
      entries[8].uop_pdest <= io_fromSplit_1_req_bits_uop_pdest;
      entries[8].uop_robIdx_flag <= io_fromSplit_1_req_bits_uop_robIdx_flag;
      entries[8].uop_robIdx_value <= io_fromSplit_1_req_bits_uop_robIdx_value;
      entries[8].uop_debugInfo_enqRsTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime;
      entries[8].uop_debugInfo_selectTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_selectTime;
      entries[8].uop_debugInfo_issueTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_issueTime;
      entries[8].vdIdx <= io_fromSplit_1_req_bits_vdIdx;
      entries[8].fof <= io_fromSplit_1_req_bits_fof;
      entries[8].vlmax <= io_fromSplit_1_req_bits_vlmax;
    end
    else if (_GEN_8) begin
      entries[8].mask <= io_fromSplit_0_req_bits_mask;
      entries[8].uop_fuOpType <= io_fromSplit_0_req_bits_uop_fuOpType;
      entries[8].uop_vecWen <= io_fromSplit_0_req_bits_uop_vecWen;
      entries[8].uop_v0Wen <= io_fromSplit_0_req_bits_uop_v0Wen;
      entries[8].uop_vlWen <= io_fromSplit_0_req_bits_uop_vlWen;
      entries[8].uop_vpu_vma <= io_fromSplit_0_req_bits_uop_vpu_vma;
      entries[8].uop_vpu_vsew <= io_fromSplit_0_req_bits_uop_vpu_vsew;
      entries[8].uop_vpu_vlmul <= io_fromSplit_0_req_bits_uop_vpu_vlmul;
      entries[8].uop_vpu_vm <= io_fromSplit_0_req_bits_uop_vpu_vm;
      entries[8].uop_vpu_vuopIdx <= io_fromSplit_0_req_bits_uop_vpu_vuopIdx;
      entries[8].uop_vpu_nf <= io_fromSplit_0_req_bits_uop_vpu_nf;
      entries[8].uop_vpu_veew <= io_fromSplit_0_req_bits_uop_vpu_veew;
      entries[8].uop_uopIdx <= io_fromSplit_0_req_bits_uop_uopIdx;
      entries[8].uop_pdest <= io_fromSplit_0_req_bits_uop_pdest;
      entries[8].uop_robIdx_flag <= io_fromSplit_0_req_bits_uop_robIdx_flag;
      entries[8].uop_robIdx_value <= io_fromSplit_0_req_bits_uop_robIdx_value;
      entries[8].uop_debugInfo_enqRsTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime;
      entries[8].uop_debugInfo_selectTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_selectTime;
      entries[8].uop_debugInfo_issueTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_issueTime;
      entries[8].vdIdx <= io_fromSplit_0_req_bits_vdIdx;
      entries[8].fof <= io_fromSplit_0_req_bits_fof;
      entries[8].vlmax <= io_fromSplit_0_req_bits_vlmax;
    end
    if (_GEN_310 & latchWbIndex_2 == 4'h8)
      entries[8].flowNum <= _entries_flowNum_T_4;
    else if (_GEN_309 & latchWbIndex_1 == 4'h8)
      entries[8].flowNum <= _entries_flowNum_T_2;
    else if (latchWbValid & latchWbIndex == 4'h8)
      entries[8].flowNum <= _entries_flowNum_T;
    else if (_GEN_173)
      entries[8].flowNum <= io_fromSplit_1_req_bits_flowNum;
    else if (_GEN_8)
      entries[8].flowNum <= io_fromSplit_0_req_bits_flowNum;
    if (_GEN_276 & _GEN_292 & _GEN_285) begin
      entries[8].exceptionVec_3 <= pipeBitsReg_2_exceptionVec_3;
      entries[8].exceptionVec_4 <= pipeBitsReg_2_exceptionVec_4;
      entries[8].exceptionVec_5 <= pipeBitsReg_2_exceptionVec_5;
      entries[8].exceptionVec_13 <= pipeBitsReg_2_exceptionVec_13;
      entries[8].exceptionVec_19 <= pipeBitsReg_2_exceptionVec_19;
      entries[8].exceptionVec_21 <= pipeBitsReg_2_exceptionVec_21;
      entries[8].uop_trigger <= pipeBitsReg_2_trigger;
      entries[8].vstart <= vstart_2;
      entries[8].vaNeedExt <= pipeBitsReg_2_vaNeedExt;
      entries[8].vaddr <= _vaddr_T_2;
      entries[8].gpaddr <= pipeBitsReg_2_gpaddr[49:0];
    end
    else if (_GEN_241 & _GEN_257 & _GEN_250) begin
      entries[8].exceptionVec_3 <= new_vec_3_3;
      entries[8].exceptionVec_4 <= new_vec_3_4;
      entries[8].exceptionVec_5 <= new_vec_3_5;
      entries[8].exceptionVec_13 <= new_vec_3_13;
      entries[8].exceptionVec_19 <= new_vec_3_19;
      entries[8].exceptionVec_21 <= new_vec_3_21;
      entries[8].uop_trigger <= sel_oldest_1_bits_trigger;
      entries[8].vstart <= vstart_1;
      entries[8].vaNeedExt <= sel_oldest_1_bits_vaNeedExt;
      entries[8].vaddr <= _vaddr_T_1;
      entries[8].gpaddr <= sel_oldest_1_bits_gpaddr;
    end
    else if (_GEN_205 & _GEN_221 & _GEN_214) begin
      entries[8].exceptionVec_3 <= new_vec_2_3;
      entries[8].exceptionVec_4 <= new_vec_2_4;
      entries[8].exceptionVec_5 <= new_vec_2_5;
      entries[8].exceptionVec_13 <= new_vec_2_13;
      entries[8].exceptionVec_19 <= new_vec_2_19;
      entries[8].exceptionVec_21 <= new_vec_2_21;
      entries[8].uop_trigger <= sel_oldest_bits_trigger;
      entries[8].vstart <= vstart;
      entries[8].vaNeedExt <= sel_oldest_bits_vaNeedExt;
      entries[8].vaddr <= _vaddr_T;
      entries[8].gpaddr <= sel_oldest_bits_gpaddr;
    end
    else begin
      if (_GEN_16) begin
        entries[8].exceptionVec_3 <= ~_GEN_34 & entries[8].exceptionVec_3;
        entries[8].exceptionVec_4 <= ~_GEN_34 & entries[8].exceptionVec_4;
        entries[8].exceptionVec_5 <= ~_GEN_34 & entries[8].exceptionVec_5;
        entries[8].exceptionVec_13 <= ~_GEN_34 & entries[8].exceptionVec_13;
        entries[8].exceptionVec_19 <= ~_GEN_34 & entries[8].exceptionVec_19;
        entries[8].exceptionVec_21 <= ~_GEN_34 & entries[8].exceptionVec_21;
      end
      else begin
        entries[8].exceptionVec_3 <= ~_GEN_8 & entries[8].exceptionVec_3;
        entries[8].exceptionVec_4 <= ~_GEN_8 & entries[8].exceptionVec_4;
        entries[8].exceptionVec_5 <= ~_GEN_8 & entries[8].exceptionVec_5;
        entries[8].exceptionVec_13 <= ~_GEN_8 & entries[8].exceptionVec_13;
        entries[8].exceptionVec_19 <= ~_GEN_8 & entries[8].exceptionVec_19;
        entries[8].exceptionVec_21 <= ~_GEN_8 & entries[8].exceptionVec_21;
      end
      if (_GEN_173 | _GEN_8)
        entries[8].uop_trigger <= 4'h0;
      if (_GEN_189)
        entries[8].vstart <= 8'h0;
      if (_GEN_173)
        entries[8].vaddr <= _GEN_197;
      else if (_GEN_8)
        entries[8].vaddr <= _GEN_164;
    end
    entries[8].uop_flushPipe <= ~_GEN_173 & ~_GEN_8 & entries[8].uop_flushPipe;
    entries[8].uop_vpu_vta <=
      _GEN_301 & _GEN_266 & _GEN_230
      & (_GEN_173
           ? io_fromSplit_1_req_bits_uop_vpu_vta
           : _GEN_8 ? io_fromSplit_0_req_bits_uop_vpu_vta : entries[8].uop_vpu_vta);
    entries[8].uop_replayInst <= ~_GEN_173 & ~_GEN_8 & entries[8].uop_replayInst;
    if (_GEN_276 & _GEN_285)
      entries[8].elemIdx <= pipeBitsReg_2_elemIdx;
    else if (_GEN_241 & _GEN_250)
      entries[8].elemIdx <= sel_oldest_1_bits_elemIdx;
    else if (_GEN_205 & _GEN_214)
      entries[8].elemIdx <= sel_oldest_bits_elemIdx;
    else if (_GEN_189)
      entries[8].elemIdx <= 8'hFF;
    if (_GEN_301) begin
      if (_GEN_266) begin
        if (_GEN_230) begin
          if (_GEN_173)
            entries[8].vl <= io_fromSplit_1_req_bits_uop_vpu_vl;
          else if (_GEN_8)
            entries[8].vl <= io_fromSplit_0_req_bits_uop_vpu_vl;
        end
        else if (_entries_vl_T)
          entries[8].vl <= _GEN_201;
        else
          entries[8].vl <= vstart;
      end
      else if (_entries_vl_T_2)
        entries[8].vl <= _GEN_239;
      else
        entries[8].vl <= vstart_1;
    end
    else if (_entries_vl_T_4)
      entries[8].vl <= _GEN_275;
    else
      entries[8].vl <= vstart_2;
    if (_GEN_315 & wbIndexReg_2_r == 4'h9) begin
      if (isusMerge_2)
        entries[9].data <= usMergeData_2;
      else
        entries[9].data <= mergeDataReg_2_r;
    end
    else if (_GEN_313 & wbIndexReg_1_r == 4'h9) begin
      if (isusMerge_1)
        entries[9].data <= usMergeData_1;
      else
        entries[9].data <= mergeDataReg_1_r;
    end
    else if (pipewbValidReg_0_REG & wbIndexReg_0_r == 4'h9) begin
      if (isusMerge)
        entries[9].data <= usMergeData;
      else
        entries[9].data <= mergeDataReg_0_r;
    end
    else if (_GEN_174)
      entries[9].data <= io_fromSplit_1_req_bits_data;
    else if (_GEN_9)
      entries[9].data <= io_fromSplit_0_req_bits_data;
    if (_GEN_174) begin
      entries[9].mask <= io_fromSplit_1_req_bits_mask;
      entries[9].uop_fuOpType <= io_fromSplit_1_req_bits_uop_fuOpType;
      entries[9].uop_vecWen <= io_fromSplit_1_req_bits_uop_vecWen;
      entries[9].uop_v0Wen <= io_fromSplit_1_req_bits_uop_v0Wen;
      entries[9].uop_vlWen <= io_fromSplit_1_req_bits_uop_vlWen;
      entries[9].uop_vpu_vma <= io_fromSplit_1_req_bits_uop_vpu_vma;
      entries[9].uop_vpu_vsew <= io_fromSplit_1_req_bits_uop_vpu_vsew;
      entries[9].uop_vpu_vlmul <= io_fromSplit_1_req_bits_uop_vpu_vlmul;
      entries[9].uop_vpu_vm <= io_fromSplit_1_req_bits_uop_vpu_vm;
      entries[9].uop_vpu_vuopIdx <= io_fromSplit_1_req_bits_uop_vpu_vuopIdx;
      entries[9].uop_vpu_nf <= io_fromSplit_1_req_bits_uop_vpu_nf;
      entries[9].uop_vpu_veew <= io_fromSplit_1_req_bits_uop_vpu_veew;
      entries[9].uop_uopIdx <= io_fromSplit_1_req_bits_uop_uopIdx;
      entries[9].uop_pdest <= io_fromSplit_1_req_bits_uop_pdest;
      entries[9].uop_robIdx_flag <= io_fromSplit_1_req_bits_uop_robIdx_flag;
      entries[9].uop_robIdx_value <= io_fromSplit_1_req_bits_uop_robIdx_value;
      entries[9].uop_debugInfo_enqRsTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime;
      entries[9].uop_debugInfo_selectTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_selectTime;
      entries[9].uop_debugInfo_issueTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_issueTime;
      entries[9].vdIdx <= io_fromSplit_1_req_bits_vdIdx;
      entries[9].fof <= io_fromSplit_1_req_bits_fof;
      entries[9].vlmax <= io_fromSplit_1_req_bits_vlmax;
    end
    else if (_GEN_9) begin
      entries[9].mask <= io_fromSplit_0_req_bits_mask;
      entries[9].uop_fuOpType <= io_fromSplit_0_req_bits_uop_fuOpType;
      entries[9].uop_vecWen <= io_fromSplit_0_req_bits_uop_vecWen;
      entries[9].uop_v0Wen <= io_fromSplit_0_req_bits_uop_v0Wen;
      entries[9].uop_vlWen <= io_fromSplit_0_req_bits_uop_vlWen;
      entries[9].uop_vpu_vma <= io_fromSplit_0_req_bits_uop_vpu_vma;
      entries[9].uop_vpu_vsew <= io_fromSplit_0_req_bits_uop_vpu_vsew;
      entries[9].uop_vpu_vlmul <= io_fromSplit_0_req_bits_uop_vpu_vlmul;
      entries[9].uop_vpu_vm <= io_fromSplit_0_req_bits_uop_vpu_vm;
      entries[9].uop_vpu_vuopIdx <= io_fromSplit_0_req_bits_uop_vpu_vuopIdx;
      entries[9].uop_vpu_nf <= io_fromSplit_0_req_bits_uop_vpu_nf;
      entries[9].uop_vpu_veew <= io_fromSplit_0_req_bits_uop_vpu_veew;
      entries[9].uop_uopIdx <= io_fromSplit_0_req_bits_uop_uopIdx;
      entries[9].uop_pdest <= io_fromSplit_0_req_bits_uop_pdest;
      entries[9].uop_robIdx_flag <= io_fromSplit_0_req_bits_uop_robIdx_flag;
      entries[9].uop_robIdx_value <= io_fromSplit_0_req_bits_uop_robIdx_value;
      entries[9].uop_debugInfo_enqRsTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime;
      entries[9].uop_debugInfo_selectTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_selectTime;
      entries[9].uop_debugInfo_issueTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_issueTime;
      entries[9].vdIdx <= io_fromSplit_0_req_bits_vdIdx;
      entries[9].fof <= io_fromSplit_0_req_bits_fof;
      entries[9].vlmax <= io_fromSplit_0_req_bits_vlmax;
    end
    if (_GEN_310 & latchWbIndex_2 == 4'h9)
      entries[9].flowNum <= _entries_flowNum_T_4;
    else if (_GEN_309 & latchWbIndex_1 == 4'h9)
      entries[9].flowNum <= _entries_flowNum_T_2;
    else if (latchWbValid & latchWbIndex == 4'h9)
      entries[9].flowNum <= _entries_flowNum_T;
    else if (_GEN_174)
      entries[9].flowNum <= io_fromSplit_1_req_bits_flowNum;
    else if (_GEN_9)
      entries[9].flowNum <= io_fromSplit_0_req_bits_flowNum;
    if (_GEN_276 & _GEN_292 & _GEN_286) begin
      entries[9].exceptionVec_3 <= pipeBitsReg_2_exceptionVec_3;
      entries[9].exceptionVec_4 <= pipeBitsReg_2_exceptionVec_4;
      entries[9].exceptionVec_5 <= pipeBitsReg_2_exceptionVec_5;
      entries[9].exceptionVec_13 <= pipeBitsReg_2_exceptionVec_13;
      entries[9].exceptionVec_19 <= pipeBitsReg_2_exceptionVec_19;
      entries[9].exceptionVec_21 <= pipeBitsReg_2_exceptionVec_21;
      entries[9].uop_trigger <= pipeBitsReg_2_trigger;
      entries[9].vstart <= vstart_2;
      entries[9].vaNeedExt <= pipeBitsReg_2_vaNeedExt;
      entries[9].vaddr <= _vaddr_T_2;
      entries[9].gpaddr <= pipeBitsReg_2_gpaddr[49:0];
    end
    else if (_GEN_241 & _GEN_257 & _GEN_251) begin
      entries[9].exceptionVec_3 <= new_vec_3_3;
      entries[9].exceptionVec_4 <= new_vec_3_4;
      entries[9].exceptionVec_5 <= new_vec_3_5;
      entries[9].exceptionVec_13 <= new_vec_3_13;
      entries[9].exceptionVec_19 <= new_vec_3_19;
      entries[9].exceptionVec_21 <= new_vec_3_21;
      entries[9].uop_trigger <= sel_oldest_1_bits_trigger;
      entries[9].vstart <= vstart_1;
      entries[9].vaNeedExt <= sel_oldest_1_bits_vaNeedExt;
      entries[9].vaddr <= _vaddr_T_1;
      entries[9].gpaddr <= sel_oldest_1_bits_gpaddr;
    end
    else if (_GEN_205 & _GEN_221 & _GEN_215) begin
      entries[9].exceptionVec_3 <= new_vec_2_3;
      entries[9].exceptionVec_4 <= new_vec_2_4;
      entries[9].exceptionVec_5 <= new_vec_2_5;
      entries[9].exceptionVec_13 <= new_vec_2_13;
      entries[9].exceptionVec_19 <= new_vec_2_19;
      entries[9].exceptionVec_21 <= new_vec_2_21;
      entries[9].uop_trigger <= sel_oldest_bits_trigger;
      entries[9].vstart <= vstart;
      entries[9].vaNeedExt <= sel_oldest_bits_vaNeedExt;
      entries[9].vaddr <= _vaddr_T;
      entries[9].gpaddr <= sel_oldest_bits_gpaddr;
    end
    else begin
      if (_GEN_16) begin
        entries[9].exceptionVec_3 <= ~_GEN_36 & entries[9].exceptionVec_3;
        entries[9].exceptionVec_4 <= ~_GEN_36 & entries[9].exceptionVec_4;
        entries[9].exceptionVec_5 <= ~_GEN_36 & entries[9].exceptionVec_5;
        entries[9].exceptionVec_13 <= ~_GEN_36 & entries[9].exceptionVec_13;
        entries[9].exceptionVec_19 <= ~_GEN_36 & entries[9].exceptionVec_19;
        entries[9].exceptionVec_21 <= ~_GEN_36 & entries[9].exceptionVec_21;
      end
      else begin
        entries[9].exceptionVec_3 <= ~_GEN_9 & entries[9].exceptionVec_3;
        entries[9].exceptionVec_4 <= ~_GEN_9 & entries[9].exceptionVec_4;
        entries[9].exceptionVec_5 <= ~_GEN_9 & entries[9].exceptionVec_5;
        entries[9].exceptionVec_13 <= ~_GEN_9 & entries[9].exceptionVec_13;
        entries[9].exceptionVec_19 <= ~_GEN_9 & entries[9].exceptionVec_19;
        entries[9].exceptionVec_21 <= ~_GEN_9 & entries[9].exceptionVec_21;
      end
      if (_GEN_174 | _GEN_9)
        entries[9].uop_trigger <= 4'h0;
      if (_GEN_190)
        entries[9].vstart <= 8'h0;
      if (_GEN_174)
        entries[9].vaddr <= _GEN_197;
      else if (_GEN_9)
        entries[9].vaddr <= _GEN_164;
    end
    entries[9].uop_flushPipe <= ~_GEN_174 & ~_GEN_9 & entries[9].uop_flushPipe;
    entries[9].uop_vpu_vta <=
      _GEN_302 & _GEN_267 & _GEN_231
      & (_GEN_174
           ? io_fromSplit_1_req_bits_uop_vpu_vta
           : _GEN_9 ? io_fromSplit_0_req_bits_uop_vpu_vta : entries[9].uop_vpu_vta);
    entries[9].uop_replayInst <= ~_GEN_174 & ~_GEN_9 & entries[9].uop_replayInst;
    if (_GEN_276 & _GEN_286)
      entries[9].elemIdx <= pipeBitsReg_2_elemIdx;
    else if (_GEN_241 & _GEN_251)
      entries[9].elemIdx <= sel_oldest_1_bits_elemIdx;
    else if (_GEN_205 & _GEN_215)
      entries[9].elemIdx <= sel_oldest_bits_elemIdx;
    else if (_GEN_190)
      entries[9].elemIdx <= 8'hFF;
    if (_GEN_302) begin
      if (_GEN_267) begin
        if (_GEN_231) begin
          if (_GEN_174)
            entries[9].vl <= io_fromSplit_1_req_bits_uop_vpu_vl;
          else if (_GEN_9)
            entries[9].vl <= io_fromSplit_0_req_bits_uop_vpu_vl;
        end
        else if (_entries_vl_T)
          entries[9].vl <= _GEN_201;
        else
          entries[9].vl <= vstart;
      end
      else if (_entries_vl_T_2)
        entries[9].vl <= _GEN_239;
      else
        entries[9].vl <= vstart_1;
    end
    else if (_entries_vl_T_4)
      entries[9].vl <= _GEN_275;
    else
      entries[9].vl <= vstart_2;
    if (_GEN_315 & wbIndexReg_2_r == 4'hA) begin
      if (isusMerge_2)
        entries[10].data <= usMergeData_2;
      else
        entries[10].data <= mergeDataReg_2_r;
    end
    else if (_GEN_313 & wbIndexReg_1_r == 4'hA) begin
      if (isusMerge_1)
        entries[10].data <= usMergeData_1;
      else
        entries[10].data <= mergeDataReg_1_r;
    end
    else if (pipewbValidReg_0_REG & wbIndexReg_0_r == 4'hA) begin
      if (isusMerge)
        entries[10].data <= usMergeData;
      else
        entries[10].data <= mergeDataReg_0_r;
    end
    else if (_GEN_175)
      entries[10].data <= io_fromSplit_1_req_bits_data;
    else if (_GEN_10)
      entries[10].data <= io_fromSplit_0_req_bits_data;
    if (_GEN_175) begin
      entries[10].mask <= io_fromSplit_1_req_bits_mask;
      entries[10].uop_fuOpType <= io_fromSplit_1_req_bits_uop_fuOpType;
      entries[10].uop_vecWen <= io_fromSplit_1_req_bits_uop_vecWen;
      entries[10].uop_v0Wen <= io_fromSplit_1_req_bits_uop_v0Wen;
      entries[10].uop_vlWen <= io_fromSplit_1_req_bits_uop_vlWen;
      entries[10].uop_vpu_vma <= io_fromSplit_1_req_bits_uop_vpu_vma;
      entries[10].uop_vpu_vsew <= io_fromSplit_1_req_bits_uop_vpu_vsew;
      entries[10].uop_vpu_vlmul <= io_fromSplit_1_req_bits_uop_vpu_vlmul;
      entries[10].uop_vpu_vm <= io_fromSplit_1_req_bits_uop_vpu_vm;
      entries[10].uop_vpu_vuopIdx <= io_fromSplit_1_req_bits_uop_vpu_vuopIdx;
      entries[10].uop_vpu_nf <= io_fromSplit_1_req_bits_uop_vpu_nf;
      entries[10].uop_vpu_veew <= io_fromSplit_1_req_bits_uop_vpu_veew;
      entries[10].uop_uopIdx <= io_fromSplit_1_req_bits_uop_uopIdx;
      entries[10].uop_pdest <= io_fromSplit_1_req_bits_uop_pdest;
      entries[10].uop_robIdx_flag <= io_fromSplit_1_req_bits_uop_robIdx_flag;
      entries[10].uop_robIdx_value <= io_fromSplit_1_req_bits_uop_robIdx_value;
      entries[10].uop_debugInfo_enqRsTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime;
      entries[10].uop_debugInfo_selectTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_selectTime;
      entries[10].uop_debugInfo_issueTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_issueTime;
      entries[10].vdIdx <= io_fromSplit_1_req_bits_vdIdx;
      entries[10].fof <= io_fromSplit_1_req_bits_fof;
      entries[10].vlmax <= io_fromSplit_1_req_bits_vlmax;
    end
    else if (_GEN_10) begin
      entries[10].mask <= io_fromSplit_0_req_bits_mask;
      entries[10].uop_fuOpType <= io_fromSplit_0_req_bits_uop_fuOpType;
      entries[10].uop_vecWen <= io_fromSplit_0_req_bits_uop_vecWen;
      entries[10].uop_v0Wen <= io_fromSplit_0_req_bits_uop_v0Wen;
      entries[10].uop_vlWen <= io_fromSplit_0_req_bits_uop_vlWen;
      entries[10].uop_vpu_vma <= io_fromSplit_0_req_bits_uop_vpu_vma;
      entries[10].uop_vpu_vsew <= io_fromSplit_0_req_bits_uop_vpu_vsew;
      entries[10].uop_vpu_vlmul <= io_fromSplit_0_req_bits_uop_vpu_vlmul;
      entries[10].uop_vpu_vm <= io_fromSplit_0_req_bits_uop_vpu_vm;
      entries[10].uop_vpu_vuopIdx <= io_fromSplit_0_req_bits_uop_vpu_vuopIdx;
      entries[10].uop_vpu_nf <= io_fromSplit_0_req_bits_uop_vpu_nf;
      entries[10].uop_vpu_veew <= io_fromSplit_0_req_bits_uop_vpu_veew;
      entries[10].uop_uopIdx <= io_fromSplit_0_req_bits_uop_uopIdx;
      entries[10].uop_pdest <= io_fromSplit_0_req_bits_uop_pdest;
      entries[10].uop_robIdx_flag <= io_fromSplit_0_req_bits_uop_robIdx_flag;
      entries[10].uop_robIdx_value <= io_fromSplit_0_req_bits_uop_robIdx_value;
      entries[10].uop_debugInfo_enqRsTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime;
      entries[10].uop_debugInfo_selectTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_selectTime;
      entries[10].uop_debugInfo_issueTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_issueTime;
      entries[10].vdIdx <= io_fromSplit_0_req_bits_vdIdx;
      entries[10].fof <= io_fromSplit_0_req_bits_fof;
      entries[10].vlmax <= io_fromSplit_0_req_bits_vlmax;
    end
    if (_GEN_310 & latchWbIndex_2 == 4'hA)
      entries[10].flowNum <= _entries_flowNum_T_4;
    else if (_GEN_309 & latchWbIndex_1 == 4'hA)
      entries[10].flowNum <= _entries_flowNum_T_2;
    else if (latchWbValid & latchWbIndex == 4'hA)
      entries[10].flowNum <= _entries_flowNum_T;
    else if (_GEN_175)
      entries[10].flowNum <= io_fromSplit_1_req_bits_flowNum;
    else if (_GEN_10)
      entries[10].flowNum <= io_fromSplit_0_req_bits_flowNum;
    if (_GEN_276 & _GEN_292 & _GEN_287) begin
      entries[10].exceptionVec_3 <= pipeBitsReg_2_exceptionVec_3;
      entries[10].exceptionVec_4 <= pipeBitsReg_2_exceptionVec_4;
      entries[10].exceptionVec_5 <= pipeBitsReg_2_exceptionVec_5;
      entries[10].exceptionVec_13 <= pipeBitsReg_2_exceptionVec_13;
      entries[10].exceptionVec_19 <= pipeBitsReg_2_exceptionVec_19;
      entries[10].exceptionVec_21 <= pipeBitsReg_2_exceptionVec_21;
      entries[10].uop_trigger <= pipeBitsReg_2_trigger;
      entries[10].vstart <= vstart_2;
      entries[10].vaNeedExt <= pipeBitsReg_2_vaNeedExt;
      entries[10].vaddr <= _vaddr_T_2;
      entries[10].gpaddr <= pipeBitsReg_2_gpaddr[49:0];
    end
    else if (_GEN_241 & _GEN_257 & _GEN_252) begin
      entries[10].exceptionVec_3 <= new_vec_3_3;
      entries[10].exceptionVec_4 <= new_vec_3_4;
      entries[10].exceptionVec_5 <= new_vec_3_5;
      entries[10].exceptionVec_13 <= new_vec_3_13;
      entries[10].exceptionVec_19 <= new_vec_3_19;
      entries[10].exceptionVec_21 <= new_vec_3_21;
      entries[10].uop_trigger <= sel_oldest_1_bits_trigger;
      entries[10].vstart <= vstart_1;
      entries[10].vaNeedExt <= sel_oldest_1_bits_vaNeedExt;
      entries[10].vaddr <= _vaddr_T_1;
      entries[10].gpaddr <= sel_oldest_1_bits_gpaddr;
    end
    else if (_GEN_205 & _GEN_221 & _GEN_216) begin
      entries[10].exceptionVec_3 <= new_vec_2_3;
      entries[10].exceptionVec_4 <= new_vec_2_4;
      entries[10].exceptionVec_5 <= new_vec_2_5;
      entries[10].exceptionVec_13 <= new_vec_2_13;
      entries[10].exceptionVec_19 <= new_vec_2_19;
      entries[10].exceptionVec_21 <= new_vec_2_21;
      entries[10].uop_trigger <= sel_oldest_bits_trigger;
      entries[10].vstart <= vstart;
      entries[10].vaNeedExt <= sel_oldest_bits_vaNeedExt;
      entries[10].vaddr <= _vaddr_T;
      entries[10].gpaddr <= sel_oldest_bits_gpaddr;
    end
    else begin
      if (_GEN_16) begin
        entries[10].exceptionVec_3 <= ~_GEN_38 & entries[10].exceptionVec_3;
        entries[10].exceptionVec_4 <= ~_GEN_38 & entries[10].exceptionVec_4;
        entries[10].exceptionVec_5 <= ~_GEN_38 & entries[10].exceptionVec_5;
        entries[10].exceptionVec_13 <= ~_GEN_38 & entries[10].exceptionVec_13;
        entries[10].exceptionVec_19 <= ~_GEN_38 & entries[10].exceptionVec_19;
        entries[10].exceptionVec_21 <= ~_GEN_38 & entries[10].exceptionVec_21;
      end
      else begin
        entries[10].exceptionVec_3 <= ~_GEN_10 & entries[10].exceptionVec_3;
        entries[10].exceptionVec_4 <= ~_GEN_10 & entries[10].exceptionVec_4;
        entries[10].exceptionVec_5 <= ~_GEN_10 & entries[10].exceptionVec_5;
        entries[10].exceptionVec_13 <= ~_GEN_10 & entries[10].exceptionVec_13;
        entries[10].exceptionVec_19 <= ~_GEN_10 & entries[10].exceptionVec_19;
        entries[10].exceptionVec_21 <= ~_GEN_10 & entries[10].exceptionVec_21;
      end
      if (_GEN_175 | _GEN_10)
        entries[10].uop_trigger <= 4'h0;
      if (_GEN_191)
        entries[10].vstart <= 8'h0;
      if (_GEN_175)
        entries[10].vaddr <= _GEN_197;
      else if (_GEN_10)
        entries[10].vaddr <= _GEN_164;
    end
    entries[10].uop_flushPipe <= ~_GEN_175 & ~_GEN_10 & entries[10].uop_flushPipe;
    entries[10].uop_vpu_vta <=
      _GEN_303 & _GEN_268 & _GEN_232
      & (_GEN_175
           ? io_fromSplit_1_req_bits_uop_vpu_vta
           : _GEN_10 ? io_fromSplit_0_req_bits_uop_vpu_vta : entries[10].uop_vpu_vta);
    entries[10].uop_replayInst <= ~_GEN_175 & ~_GEN_10 & entries[10].uop_replayInst;
    if (_GEN_276 & _GEN_287)
      entries[10].elemIdx <= pipeBitsReg_2_elemIdx;
    else if (_GEN_241 & _GEN_252)
      entries[10].elemIdx <= sel_oldest_1_bits_elemIdx;
    else if (_GEN_205 & _GEN_216)
      entries[10].elemIdx <= sel_oldest_bits_elemIdx;
    else if (_GEN_191)
      entries[10].elemIdx <= 8'hFF;
    if (_GEN_303) begin
      if (_GEN_268) begin
        if (_GEN_232) begin
          if (_GEN_175)
            entries[10].vl <= io_fromSplit_1_req_bits_uop_vpu_vl;
          else if (_GEN_10)
            entries[10].vl <= io_fromSplit_0_req_bits_uop_vpu_vl;
        end
        else if (_entries_vl_T)
          entries[10].vl <= _GEN_201;
        else
          entries[10].vl <= vstart;
      end
      else if (_entries_vl_T_2)
        entries[10].vl <= _GEN_239;
      else
        entries[10].vl <= vstart_1;
    end
    else if (_entries_vl_T_4)
      entries[10].vl <= _GEN_275;
    else
      entries[10].vl <= vstart_2;
    if (_GEN_315 & wbIndexReg_2_r == 4'hB) begin
      if (isusMerge_2)
        entries[11].data <= usMergeData_2;
      else
        entries[11].data <= mergeDataReg_2_r;
    end
    else if (_GEN_313 & wbIndexReg_1_r == 4'hB) begin
      if (isusMerge_1)
        entries[11].data <= usMergeData_1;
      else
        entries[11].data <= mergeDataReg_1_r;
    end
    else if (pipewbValidReg_0_REG & wbIndexReg_0_r == 4'hB) begin
      if (isusMerge)
        entries[11].data <= usMergeData;
      else
        entries[11].data <= mergeDataReg_0_r;
    end
    else if (_GEN_176)
      entries[11].data <= io_fromSplit_1_req_bits_data;
    else if (_GEN_11)
      entries[11].data <= io_fromSplit_0_req_bits_data;
    if (_GEN_176) begin
      entries[11].mask <= io_fromSplit_1_req_bits_mask;
      entries[11].uop_fuOpType <= io_fromSplit_1_req_bits_uop_fuOpType;
      entries[11].uop_vecWen <= io_fromSplit_1_req_bits_uop_vecWen;
      entries[11].uop_v0Wen <= io_fromSplit_1_req_bits_uop_v0Wen;
      entries[11].uop_vlWen <= io_fromSplit_1_req_bits_uop_vlWen;
      entries[11].uop_vpu_vma <= io_fromSplit_1_req_bits_uop_vpu_vma;
      entries[11].uop_vpu_vsew <= io_fromSplit_1_req_bits_uop_vpu_vsew;
      entries[11].uop_vpu_vlmul <= io_fromSplit_1_req_bits_uop_vpu_vlmul;
      entries[11].uop_vpu_vm <= io_fromSplit_1_req_bits_uop_vpu_vm;
      entries[11].uop_vpu_vuopIdx <= io_fromSplit_1_req_bits_uop_vpu_vuopIdx;
      entries[11].uop_vpu_nf <= io_fromSplit_1_req_bits_uop_vpu_nf;
      entries[11].uop_vpu_veew <= io_fromSplit_1_req_bits_uop_vpu_veew;
      entries[11].uop_uopIdx <= io_fromSplit_1_req_bits_uop_uopIdx;
      entries[11].uop_pdest <= io_fromSplit_1_req_bits_uop_pdest;
      entries[11].uop_robIdx_flag <= io_fromSplit_1_req_bits_uop_robIdx_flag;
      entries[11].uop_robIdx_value <= io_fromSplit_1_req_bits_uop_robIdx_value;
      entries[11].uop_debugInfo_enqRsTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime;
      entries[11].uop_debugInfo_selectTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_selectTime;
      entries[11].uop_debugInfo_issueTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_issueTime;
      entries[11].vdIdx <= io_fromSplit_1_req_bits_vdIdx;
      entries[11].fof <= io_fromSplit_1_req_bits_fof;
      entries[11].vlmax <= io_fromSplit_1_req_bits_vlmax;
    end
    else if (_GEN_11) begin
      entries[11].mask <= io_fromSplit_0_req_bits_mask;
      entries[11].uop_fuOpType <= io_fromSplit_0_req_bits_uop_fuOpType;
      entries[11].uop_vecWen <= io_fromSplit_0_req_bits_uop_vecWen;
      entries[11].uop_v0Wen <= io_fromSplit_0_req_bits_uop_v0Wen;
      entries[11].uop_vlWen <= io_fromSplit_0_req_bits_uop_vlWen;
      entries[11].uop_vpu_vma <= io_fromSplit_0_req_bits_uop_vpu_vma;
      entries[11].uop_vpu_vsew <= io_fromSplit_0_req_bits_uop_vpu_vsew;
      entries[11].uop_vpu_vlmul <= io_fromSplit_0_req_bits_uop_vpu_vlmul;
      entries[11].uop_vpu_vm <= io_fromSplit_0_req_bits_uop_vpu_vm;
      entries[11].uop_vpu_vuopIdx <= io_fromSplit_0_req_bits_uop_vpu_vuopIdx;
      entries[11].uop_vpu_nf <= io_fromSplit_0_req_bits_uop_vpu_nf;
      entries[11].uop_vpu_veew <= io_fromSplit_0_req_bits_uop_vpu_veew;
      entries[11].uop_uopIdx <= io_fromSplit_0_req_bits_uop_uopIdx;
      entries[11].uop_pdest <= io_fromSplit_0_req_bits_uop_pdest;
      entries[11].uop_robIdx_flag <= io_fromSplit_0_req_bits_uop_robIdx_flag;
      entries[11].uop_robIdx_value <= io_fromSplit_0_req_bits_uop_robIdx_value;
      entries[11].uop_debugInfo_enqRsTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime;
      entries[11].uop_debugInfo_selectTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_selectTime;
      entries[11].uop_debugInfo_issueTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_issueTime;
      entries[11].vdIdx <= io_fromSplit_0_req_bits_vdIdx;
      entries[11].fof <= io_fromSplit_0_req_bits_fof;
      entries[11].vlmax <= io_fromSplit_0_req_bits_vlmax;
    end
    if (_GEN_310 & latchWbIndex_2 == 4'hB)
      entries[11].flowNum <= _entries_flowNum_T_4;
    else if (_GEN_309 & latchWbIndex_1 == 4'hB)
      entries[11].flowNum <= _entries_flowNum_T_2;
    else if (latchWbValid & latchWbIndex == 4'hB)
      entries[11].flowNum <= _entries_flowNum_T;
    else if (_GEN_176)
      entries[11].flowNum <= io_fromSplit_1_req_bits_flowNum;
    else if (_GEN_11)
      entries[11].flowNum <= io_fromSplit_0_req_bits_flowNum;
    if (_GEN_276 & _GEN_292 & _GEN_288) begin
      entries[11].exceptionVec_3 <= pipeBitsReg_2_exceptionVec_3;
      entries[11].exceptionVec_4 <= pipeBitsReg_2_exceptionVec_4;
      entries[11].exceptionVec_5 <= pipeBitsReg_2_exceptionVec_5;
      entries[11].exceptionVec_13 <= pipeBitsReg_2_exceptionVec_13;
      entries[11].exceptionVec_19 <= pipeBitsReg_2_exceptionVec_19;
      entries[11].exceptionVec_21 <= pipeBitsReg_2_exceptionVec_21;
      entries[11].uop_trigger <= pipeBitsReg_2_trigger;
      entries[11].vstart <= vstart_2;
      entries[11].vaNeedExt <= pipeBitsReg_2_vaNeedExt;
      entries[11].vaddr <= _vaddr_T_2;
      entries[11].gpaddr <= pipeBitsReg_2_gpaddr[49:0];
    end
    else if (_GEN_241 & _GEN_257 & _GEN_253) begin
      entries[11].exceptionVec_3 <= new_vec_3_3;
      entries[11].exceptionVec_4 <= new_vec_3_4;
      entries[11].exceptionVec_5 <= new_vec_3_5;
      entries[11].exceptionVec_13 <= new_vec_3_13;
      entries[11].exceptionVec_19 <= new_vec_3_19;
      entries[11].exceptionVec_21 <= new_vec_3_21;
      entries[11].uop_trigger <= sel_oldest_1_bits_trigger;
      entries[11].vstart <= vstart_1;
      entries[11].vaNeedExt <= sel_oldest_1_bits_vaNeedExt;
      entries[11].vaddr <= _vaddr_T_1;
      entries[11].gpaddr <= sel_oldest_1_bits_gpaddr;
    end
    else if (_GEN_205 & _GEN_221 & _GEN_217) begin
      entries[11].exceptionVec_3 <= new_vec_2_3;
      entries[11].exceptionVec_4 <= new_vec_2_4;
      entries[11].exceptionVec_5 <= new_vec_2_5;
      entries[11].exceptionVec_13 <= new_vec_2_13;
      entries[11].exceptionVec_19 <= new_vec_2_19;
      entries[11].exceptionVec_21 <= new_vec_2_21;
      entries[11].uop_trigger <= sel_oldest_bits_trigger;
      entries[11].vstart <= vstart;
      entries[11].vaNeedExt <= sel_oldest_bits_vaNeedExt;
      entries[11].vaddr <= _vaddr_T;
      entries[11].gpaddr <= sel_oldest_bits_gpaddr;
    end
    else begin
      if (_GEN_16) begin
        entries[11].exceptionVec_3 <= ~_GEN_40 & entries[11].exceptionVec_3;
        entries[11].exceptionVec_4 <= ~_GEN_40 & entries[11].exceptionVec_4;
        entries[11].exceptionVec_5 <= ~_GEN_40 & entries[11].exceptionVec_5;
        entries[11].exceptionVec_13 <= ~_GEN_40 & entries[11].exceptionVec_13;
        entries[11].exceptionVec_19 <= ~_GEN_40 & entries[11].exceptionVec_19;
        entries[11].exceptionVec_21 <= ~_GEN_40 & entries[11].exceptionVec_21;
      end
      else begin
        entries[11].exceptionVec_3 <= ~_GEN_11 & entries[11].exceptionVec_3;
        entries[11].exceptionVec_4 <= ~_GEN_11 & entries[11].exceptionVec_4;
        entries[11].exceptionVec_5 <= ~_GEN_11 & entries[11].exceptionVec_5;
        entries[11].exceptionVec_13 <= ~_GEN_11 & entries[11].exceptionVec_13;
        entries[11].exceptionVec_19 <= ~_GEN_11 & entries[11].exceptionVec_19;
        entries[11].exceptionVec_21 <= ~_GEN_11 & entries[11].exceptionVec_21;
      end
      if (_GEN_176 | _GEN_11)
        entries[11].uop_trigger <= 4'h0;
      if (_GEN_192)
        entries[11].vstart <= 8'h0;
      if (_GEN_176)
        entries[11].vaddr <= _GEN_197;
      else if (_GEN_11)
        entries[11].vaddr <= _GEN_164;
    end
    entries[11].uop_flushPipe <= ~_GEN_176 & ~_GEN_11 & entries[11].uop_flushPipe;
    entries[11].uop_vpu_vta <=
      _GEN_304 & _GEN_269 & _GEN_233
      & (_GEN_176
           ? io_fromSplit_1_req_bits_uop_vpu_vta
           : _GEN_11 ? io_fromSplit_0_req_bits_uop_vpu_vta : entries[11].uop_vpu_vta);
    entries[11].uop_replayInst <= ~_GEN_176 & ~_GEN_11 & entries[11].uop_replayInst;
    if (_GEN_276 & _GEN_288)
      entries[11].elemIdx <= pipeBitsReg_2_elemIdx;
    else if (_GEN_241 & _GEN_253)
      entries[11].elemIdx <= sel_oldest_1_bits_elemIdx;
    else if (_GEN_205 & _GEN_217)
      entries[11].elemIdx <= sel_oldest_bits_elemIdx;
    else if (_GEN_192)
      entries[11].elemIdx <= 8'hFF;
    if (_GEN_304) begin
      if (_GEN_269) begin
        if (_GEN_233) begin
          if (_GEN_176)
            entries[11].vl <= io_fromSplit_1_req_bits_uop_vpu_vl;
          else if (_GEN_11)
            entries[11].vl <= io_fromSplit_0_req_bits_uop_vpu_vl;
        end
        else if (_entries_vl_T)
          entries[11].vl <= _GEN_201;
        else
          entries[11].vl <= vstart;
      end
      else if (_entries_vl_T_2)
        entries[11].vl <= _GEN_239;
      else
        entries[11].vl <= vstart_1;
    end
    else if (_entries_vl_T_4)
      entries[11].vl <= _GEN_275;
    else
      entries[11].vl <= vstart_2;
    if (_GEN_315 & wbIndexReg_2_r == 4'hC) begin
      if (isusMerge_2)
        entries[12].data <= usMergeData_2;
      else
        entries[12].data <= mergeDataReg_2_r;
    end
    else if (_GEN_313 & wbIndexReg_1_r == 4'hC) begin
      if (isusMerge_1)
        entries[12].data <= usMergeData_1;
      else
        entries[12].data <= mergeDataReg_1_r;
    end
    else if (pipewbValidReg_0_REG & wbIndexReg_0_r == 4'hC) begin
      if (isusMerge)
        entries[12].data <= usMergeData;
      else
        entries[12].data <= mergeDataReg_0_r;
    end
    else if (_GEN_177)
      entries[12].data <= io_fromSplit_1_req_bits_data;
    else if (_GEN_12)
      entries[12].data <= io_fromSplit_0_req_bits_data;
    if (_GEN_177) begin
      entries[12].mask <= io_fromSplit_1_req_bits_mask;
      entries[12].uop_fuOpType <= io_fromSplit_1_req_bits_uop_fuOpType;
      entries[12].uop_vecWen <= io_fromSplit_1_req_bits_uop_vecWen;
      entries[12].uop_v0Wen <= io_fromSplit_1_req_bits_uop_v0Wen;
      entries[12].uop_vlWen <= io_fromSplit_1_req_bits_uop_vlWen;
      entries[12].uop_vpu_vma <= io_fromSplit_1_req_bits_uop_vpu_vma;
      entries[12].uop_vpu_vsew <= io_fromSplit_1_req_bits_uop_vpu_vsew;
      entries[12].uop_vpu_vlmul <= io_fromSplit_1_req_bits_uop_vpu_vlmul;
      entries[12].uop_vpu_vm <= io_fromSplit_1_req_bits_uop_vpu_vm;
      entries[12].uop_vpu_vuopIdx <= io_fromSplit_1_req_bits_uop_vpu_vuopIdx;
      entries[12].uop_vpu_nf <= io_fromSplit_1_req_bits_uop_vpu_nf;
      entries[12].uop_vpu_veew <= io_fromSplit_1_req_bits_uop_vpu_veew;
      entries[12].uop_uopIdx <= io_fromSplit_1_req_bits_uop_uopIdx;
      entries[12].uop_pdest <= io_fromSplit_1_req_bits_uop_pdest;
      entries[12].uop_robIdx_flag <= io_fromSplit_1_req_bits_uop_robIdx_flag;
      entries[12].uop_robIdx_value <= io_fromSplit_1_req_bits_uop_robIdx_value;
      entries[12].uop_debugInfo_enqRsTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime;
      entries[12].uop_debugInfo_selectTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_selectTime;
      entries[12].uop_debugInfo_issueTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_issueTime;
      entries[12].vdIdx <= io_fromSplit_1_req_bits_vdIdx;
      entries[12].fof <= io_fromSplit_1_req_bits_fof;
      entries[12].vlmax <= io_fromSplit_1_req_bits_vlmax;
    end
    else if (_GEN_12) begin
      entries[12].mask <= io_fromSplit_0_req_bits_mask;
      entries[12].uop_fuOpType <= io_fromSplit_0_req_bits_uop_fuOpType;
      entries[12].uop_vecWen <= io_fromSplit_0_req_bits_uop_vecWen;
      entries[12].uop_v0Wen <= io_fromSplit_0_req_bits_uop_v0Wen;
      entries[12].uop_vlWen <= io_fromSplit_0_req_bits_uop_vlWen;
      entries[12].uop_vpu_vma <= io_fromSplit_0_req_bits_uop_vpu_vma;
      entries[12].uop_vpu_vsew <= io_fromSplit_0_req_bits_uop_vpu_vsew;
      entries[12].uop_vpu_vlmul <= io_fromSplit_0_req_bits_uop_vpu_vlmul;
      entries[12].uop_vpu_vm <= io_fromSplit_0_req_bits_uop_vpu_vm;
      entries[12].uop_vpu_vuopIdx <= io_fromSplit_0_req_bits_uop_vpu_vuopIdx;
      entries[12].uop_vpu_nf <= io_fromSplit_0_req_bits_uop_vpu_nf;
      entries[12].uop_vpu_veew <= io_fromSplit_0_req_bits_uop_vpu_veew;
      entries[12].uop_uopIdx <= io_fromSplit_0_req_bits_uop_uopIdx;
      entries[12].uop_pdest <= io_fromSplit_0_req_bits_uop_pdest;
      entries[12].uop_robIdx_flag <= io_fromSplit_0_req_bits_uop_robIdx_flag;
      entries[12].uop_robIdx_value <= io_fromSplit_0_req_bits_uop_robIdx_value;
      entries[12].uop_debugInfo_enqRsTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime;
      entries[12].uop_debugInfo_selectTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_selectTime;
      entries[12].uop_debugInfo_issueTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_issueTime;
      entries[12].vdIdx <= io_fromSplit_0_req_bits_vdIdx;
      entries[12].fof <= io_fromSplit_0_req_bits_fof;
      entries[12].vlmax <= io_fromSplit_0_req_bits_vlmax;
    end
    if (_GEN_310 & latchWbIndex_2 == 4'hC)
      entries[12].flowNum <= _entries_flowNum_T_4;
    else if (_GEN_309 & latchWbIndex_1 == 4'hC)
      entries[12].flowNum <= _entries_flowNum_T_2;
    else if (latchWbValid & latchWbIndex == 4'hC)
      entries[12].flowNum <= _entries_flowNum_T;
    else if (_GEN_177)
      entries[12].flowNum <= io_fromSplit_1_req_bits_flowNum;
    else if (_GEN_12)
      entries[12].flowNum <= io_fromSplit_0_req_bits_flowNum;
    if (_GEN_276 & _GEN_292 & _GEN_289) begin
      entries[12].exceptionVec_3 <= pipeBitsReg_2_exceptionVec_3;
      entries[12].exceptionVec_4 <= pipeBitsReg_2_exceptionVec_4;
      entries[12].exceptionVec_5 <= pipeBitsReg_2_exceptionVec_5;
      entries[12].exceptionVec_13 <= pipeBitsReg_2_exceptionVec_13;
      entries[12].exceptionVec_19 <= pipeBitsReg_2_exceptionVec_19;
      entries[12].exceptionVec_21 <= pipeBitsReg_2_exceptionVec_21;
      entries[12].uop_trigger <= pipeBitsReg_2_trigger;
      entries[12].vstart <= vstart_2;
      entries[12].vaNeedExt <= pipeBitsReg_2_vaNeedExt;
      entries[12].vaddr <= _vaddr_T_2;
      entries[12].gpaddr <= pipeBitsReg_2_gpaddr[49:0];
    end
    else if (_GEN_241 & _GEN_257 & _GEN_254) begin
      entries[12].exceptionVec_3 <= new_vec_3_3;
      entries[12].exceptionVec_4 <= new_vec_3_4;
      entries[12].exceptionVec_5 <= new_vec_3_5;
      entries[12].exceptionVec_13 <= new_vec_3_13;
      entries[12].exceptionVec_19 <= new_vec_3_19;
      entries[12].exceptionVec_21 <= new_vec_3_21;
      entries[12].uop_trigger <= sel_oldest_1_bits_trigger;
      entries[12].vstart <= vstart_1;
      entries[12].vaNeedExt <= sel_oldest_1_bits_vaNeedExt;
      entries[12].vaddr <= _vaddr_T_1;
      entries[12].gpaddr <= sel_oldest_1_bits_gpaddr;
    end
    else if (_GEN_205 & _GEN_221 & _GEN_218) begin
      entries[12].exceptionVec_3 <= new_vec_2_3;
      entries[12].exceptionVec_4 <= new_vec_2_4;
      entries[12].exceptionVec_5 <= new_vec_2_5;
      entries[12].exceptionVec_13 <= new_vec_2_13;
      entries[12].exceptionVec_19 <= new_vec_2_19;
      entries[12].exceptionVec_21 <= new_vec_2_21;
      entries[12].uop_trigger <= sel_oldest_bits_trigger;
      entries[12].vstart <= vstart;
      entries[12].vaNeedExt <= sel_oldest_bits_vaNeedExt;
      entries[12].vaddr <= _vaddr_T;
      entries[12].gpaddr <= sel_oldest_bits_gpaddr;
    end
    else begin
      if (_GEN_16) begin
        entries[12].exceptionVec_3 <= ~_GEN_42 & entries[12].exceptionVec_3;
        entries[12].exceptionVec_4 <= ~_GEN_42 & entries[12].exceptionVec_4;
        entries[12].exceptionVec_5 <= ~_GEN_42 & entries[12].exceptionVec_5;
        entries[12].exceptionVec_13 <= ~_GEN_42 & entries[12].exceptionVec_13;
        entries[12].exceptionVec_19 <= ~_GEN_42 & entries[12].exceptionVec_19;
        entries[12].exceptionVec_21 <= ~_GEN_42 & entries[12].exceptionVec_21;
      end
      else begin
        entries[12].exceptionVec_3 <= ~_GEN_12 & entries[12].exceptionVec_3;
        entries[12].exceptionVec_4 <= ~_GEN_12 & entries[12].exceptionVec_4;
        entries[12].exceptionVec_5 <= ~_GEN_12 & entries[12].exceptionVec_5;
        entries[12].exceptionVec_13 <= ~_GEN_12 & entries[12].exceptionVec_13;
        entries[12].exceptionVec_19 <= ~_GEN_12 & entries[12].exceptionVec_19;
        entries[12].exceptionVec_21 <= ~_GEN_12 & entries[12].exceptionVec_21;
      end
      if (_GEN_177 | _GEN_12)
        entries[12].uop_trigger <= 4'h0;
      if (_GEN_193)
        entries[12].vstart <= 8'h0;
      if (_GEN_177)
        entries[12].vaddr <= _GEN_197;
      else if (_GEN_12)
        entries[12].vaddr <= _GEN_164;
    end
    entries[12].uop_flushPipe <= ~_GEN_177 & ~_GEN_12 & entries[12].uop_flushPipe;
    entries[12].uop_vpu_vta <=
      _GEN_305 & _GEN_270 & _GEN_234
      & (_GEN_177
           ? io_fromSplit_1_req_bits_uop_vpu_vta
           : _GEN_12 ? io_fromSplit_0_req_bits_uop_vpu_vta : entries[12].uop_vpu_vta);
    entries[12].uop_replayInst <= ~_GEN_177 & ~_GEN_12 & entries[12].uop_replayInst;
    if (_GEN_276 & _GEN_289)
      entries[12].elemIdx <= pipeBitsReg_2_elemIdx;
    else if (_GEN_241 & _GEN_254)
      entries[12].elemIdx <= sel_oldest_1_bits_elemIdx;
    else if (_GEN_205 & _GEN_218)
      entries[12].elemIdx <= sel_oldest_bits_elemIdx;
    else if (_GEN_193)
      entries[12].elemIdx <= 8'hFF;
    if (_GEN_305) begin
      if (_GEN_270) begin
        if (_GEN_234) begin
          if (_GEN_177)
            entries[12].vl <= io_fromSplit_1_req_bits_uop_vpu_vl;
          else if (_GEN_12)
            entries[12].vl <= io_fromSplit_0_req_bits_uop_vpu_vl;
        end
        else if (_entries_vl_T)
          entries[12].vl <= _GEN_201;
        else
          entries[12].vl <= vstart;
      end
      else if (_entries_vl_T_2)
        entries[12].vl <= _GEN_239;
      else
        entries[12].vl <= vstart_1;
    end
    else if (_entries_vl_T_4)
      entries[12].vl <= _GEN_275;
    else
      entries[12].vl <= vstart_2;
    if (_GEN_315 & wbIndexReg_2_r == 4'hD) begin
      if (isusMerge_2)
        entries[13].data <= usMergeData_2;
      else
        entries[13].data <= mergeDataReg_2_r;
    end
    else if (_GEN_313 & wbIndexReg_1_r == 4'hD) begin
      if (isusMerge_1)
        entries[13].data <= usMergeData_1;
      else
        entries[13].data <= mergeDataReg_1_r;
    end
    else if (pipewbValidReg_0_REG & wbIndexReg_0_r == 4'hD) begin
      if (isusMerge)
        entries[13].data <= usMergeData;
      else
        entries[13].data <= mergeDataReg_0_r;
    end
    else if (_GEN_178)
      entries[13].data <= io_fromSplit_1_req_bits_data;
    else if (_GEN_13)
      entries[13].data <= io_fromSplit_0_req_bits_data;
    if (_GEN_178) begin
      entries[13].mask <= io_fromSplit_1_req_bits_mask;
      entries[13].uop_fuOpType <= io_fromSplit_1_req_bits_uop_fuOpType;
      entries[13].uop_vecWen <= io_fromSplit_1_req_bits_uop_vecWen;
      entries[13].uop_v0Wen <= io_fromSplit_1_req_bits_uop_v0Wen;
      entries[13].uop_vlWen <= io_fromSplit_1_req_bits_uop_vlWen;
      entries[13].uop_vpu_vma <= io_fromSplit_1_req_bits_uop_vpu_vma;
      entries[13].uop_vpu_vsew <= io_fromSplit_1_req_bits_uop_vpu_vsew;
      entries[13].uop_vpu_vlmul <= io_fromSplit_1_req_bits_uop_vpu_vlmul;
      entries[13].uop_vpu_vm <= io_fromSplit_1_req_bits_uop_vpu_vm;
      entries[13].uop_vpu_vuopIdx <= io_fromSplit_1_req_bits_uop_vpu_vuopIdx;
      entries[13].uop_vpu_nf <= io_fromSplit_1_req_bits_uop_vpu_nf;
      entries[13].uop_vpu_veew <= io_fromSplit_1_req_bits_uop_vpu_veew;
      entries[13].uop_uopIdx <= io_fromSplit_1_req_bits_uop_uopIdx;
      entries[13].uop_pdest <= io_fromSplit_1_req_bits_uop_pdest;
      entries[13].uop_robIdx_flag <= io_fromSplit_1_req_bits_uop_robIdx_flag;
      entries[13].uop_robIdx_value <= io_fromSplit_1_req_bits_uop_robIdx_value;
      entries[13].uop_debugInfo_enqRsTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime;
      entries[13].uop_debugInfo_selectTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_selectTime;
      entries[13].uop_debugInfo_issueTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_issueTime;
      entries[13].vdIdx <= io_fromSplit_1_req_bits_vdIdx;
      entries[13].fof <= io_fromSplit_1_req_bits_fof;
      entries[13].vlmax <= io_fromSplit_1_req_bits_vlmax;
    end
    else if (_GEN_13) begin
      entries[13].mask <= io_fromSplit_0_req_bits_mask;
      entries[13].uop_fuOpType <= io_fromSplit_0_req_bits_uop_fuOpType;
      entries[13].uop_vecWen <= io_fromSplit_0_req_bits_uop_vecWen;
      entries[13].uop_v0Wen <= io_fromSplit_0_req_bits_uop_v0Wen;
      entries[13].uop_vlWen <= io_fromSplit_0_req_bits_uop_vlWen;
      entries[13].uop_vpu_vma <= io_fromSplit_0_req_bits_uop_vpu_vma;
      entries[13].uop_vpu_vsew <= io_fromSplit_0_req_bits_uop_vpu_vsew;
      entries[13].uop_vpu_vlmul <= io_fromSplit_0_req_bits_uop_vpu_vlmul;
      entries[13].uop_vpu_vm <= io_fromSplit_0_req_bits_uop_vpu_vm;
      entries[13].uop_vpu_vuopIdx <= io_fromSplit_0_req_bits_uop_vpu_vuopIdx;
      entries[13].uop_vpu_nf <= io_fromSplit_0_req_bits_uop_vpu_nf;
      entries[13].uop_vpu_veew <= io_fromSplit_0_req_bits_uop_vpu_veew;
      entries[13].uop_uopIdx <= io_fromSplit_0_req_bits_uop_uopIdx;
      entries[13].uop_pdest <= io_fromSplit_0_req_bits_uop_pdest;
      entries[13].uop_robIdx_flag <= io_fromSplit_0_req_bits_uop_robIdx_flag;
      entries[13].uop_robIdx_value <= io_fromSplit_0_req_bits_uop_robIdx_value;
      entries[13].uop_debugInfo_enqRsTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime;
      entries[13].uop_debugInfo_selectTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_selectTime;
      entries[13].uop_debugInfo_issueTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_issueTime;
      entries[13].vdIdx <= io_fromSplit_0_req_bits_vdIdx;
      entries[13].fof <= io_fromSplit_0_req_bits_fof;
      entries[13].vlmax <= io_fromSplit_0_req_bits_vlmax;
    end
    if (_GEN_310 & latchWbIndex_2 == 4'hD)
      entries[13].flowNum <= _entries_flowNum_T_4;
    else if (_GEN_309 & latchWbIndex_1 == 4'hD)
      entries[13].flowNum <= _entries_flowNum_T_2;
    else if (latchWbValid & latchWbIndex == 4'hD)
      entries[13].flowNum <= _entries_flowNum_T;
    else if (_GEN_178)
      entries[13].flowNum <= io_fromSplit_1_req_bits_flowNum;
    else if (_GEN_13)
      entries[13].flowNum <= io_fromSplit_0_req_bits_flowNum;
    if (_GEN_276 & _GEN_292 & _GEN_290) begin
      entries[13].exceptionVec_3 <= pipeBitsReg_2_exceptionVec_3;
      entries[13].exceptionVec_4 <= pipeBitsReg_2_exceptionVec_4;
      entries[13].exceptionVec_5 <= pipeBitsReg_2_exceptionVec_5;
      entries[13].exceptionVec_13 <= pipeBitsReg_2_exceptionVec_13;
      entries[13].exceptionVec_19 <= pipeBitsReg_2_exceptionVec_19;
      entries[13].exceptionVec_21 <= pipeBitsReg_2_exceptionVec_21;
      entries[13].uop_trigger <= pipeBitsReg_2_trigger;
      entries[13].vstart <= vstart_2;
      entries[13].vaNeedExt <= pipeBitsReg_2_vaNeedExt;
      entries[13].vaddr <= _vaddr_T_2;
      entries[13].gpaddr <= pipeBitsReg_2_gpaddr[49:0];
    end
    else if (_GEN_241 & _GEN_257 & _GEN_255) begin
      entries[13].exceptionVec_3 <= new_vec_3_3;
      entries[13].exceptionVec_4 <= new_vec_3_4;
      entries[13].exceptionVec_5 <= new_vec_3_5;
      entries[13].exceptionVec_13 <= new_vec_3_13;
      entries[13].exceptionVec_19 <= new_vec_3_19;
      entries[13].exceptionVec_21 <= new_vec_3_21;
      entries[13].uop_trigger <= sel_oldest_1_bits_trigger;
      entries[13].vstart <= vstart_1;
      entries[13].vaNeedExt <= sel_oldest_1_bits_vaNeedExt;
      entries[13].vaddr <= _vaddr_T_1;
      entries[13].gpaddr <= sel_oldest_1_bits_gpaddr;
    end
    else if (_GEN_205 & _GEN_221 & _GEN_219) begin
      entries[13].exceptionVec_3 <= new_vec_2_3;
      entries[13].exceptionVec_4 <= new_vec_2_4;
      entries[13].exceptionVec_5 <= new_vec_2_5;
      entries[13].exceptionVec_13 <= new_vec_2_13;
      entries[13].exceptionVec_19 <= new_vec_2_19;
      entries[13].exceptionVec_21 <= new_vec_2_21;
      entries[13].uop_trigger <= sel_oldest_bits_trigger;
      entries[13].vstart <= vstart;
      entries[13].vaNeedExt <= sel_oldest_bits_vaNeedExt;
      entries[13].vaddr <= _vaddr_T;
      entries[13].gpaddr <= sel_oldest_bits_gpaddr;
    end
    else begin
      if (_GEN_16) begin
        entries[13].exceptionVec_3 <= ~_GEN_44 & entries[13].exceptionVec_3;
        entries[13].exceptionVec_4 <= ~_GEN_44 & entries[13].exceptionVec_4;
        entries[13].exceptionVec_5 <= ~_GEN_44 & entries[13].exceptionVec_5;
        entries[13].exceptionVec_13 <= ~_GEN_44 & entries[13].exceptionVec_13;
        entries[13].exceptionVec_19 <= ~_GEN_44 & entries[13].exceptionVec_19;
        entries[13].exceptionVec_21 <= ~_GEN_44 & entries[13].exceptionVec_21;
      end
      else begin
        entries[13].exceptionVec_3 <= ~_GEN_13 & entries[13].exceptionVec_3;
        entries[13].exceptionVec_4 <= ~_GEN_13 & entries[13].exceptionVec_4;
        entries[13].exceptionVec_5 <= ~_GEN_13 & entries[13].exceptionVec_5;
        entries[13].exceptionVec_13 <= ~_GEN_13 & entries[13].exceptionVec_13;
        entries[13].exceptionVec_19 <= ~_GEN_13 & entries[13].exceptionVec_19;
        entries[13].exceptionVec_21 <= ~_GEN_13 & entries[13].exceptionVec_21;
      end
      if (_GEN_178 | _GEN_13)
        entries[13].uop_trigger <= 4'h0;
      if (_GEN_194)
        entries[13].vstart <= 8'h0;
      if (_GEN_178)
        entries[13].vaddr <= _GEN_197;
      else if (_GEN_13)
        entries[13].vaddr <= _GEN_164;
    end
    entries[13].uop_flushPipe <= ~_GEN_178 & ~_GEN_13 & entries[13].uop_flushPipe;
    entries[13].uop_vpu_vta <=
      _GEN_306 & _GEN_271 & _GEN_235
      & (_GEN_178
           ? io_fromSplit_1_req_bits_uop_vpu_vta
           : _GEN_13 ? io_fromSplit_0_req_bits_uop_vpu_vta : entries[13].uop_vpu_vta);
    entries[13].uop_replayInst <= ~_GEN_178 & ~_GEN_13 & entries[13].uop_replayInst;
    if (_GEN_276 & _GEN_290)
      entries[13].elemIdx <= pipeBitsReg_2_elemIdx;
    else if (_GEN_241 & _GEN_255)
      entries[13].elemIdx <= sel_oldest_1_bits_elemIdx;
    else if (_GEN_205 & _GEN_219)
      entries[13].elemIdx <= sel_oldest_bits_elemIdx;
    else if (_GEN_194)
      entries[13].elemIdx <= 8'hFF;
    if (_GEN_306) begin
      if (_GEN_271) begin
        if (_GEN_235) begin
          if (_GEN_178)
            entries[13].vl <= io_fromSplit_1_req_bits_uop_vpu_vl;
          else if (_GEN_13)
            entries[13].vl <= io_fromSplit_0_req_bits_uop_vpu_vl;
        end
        else if (_entries_vl_T)
          entries[13].vl <= _GEN_201;
        else
          entries[13].vl <= vstart;
      end
      else if (_entries_vl_T_2)
        entries[13].vl <= _GEN_239;
      else
        entries[13].vl <= vstart_1;
    end
    else if (_entries_vl_T_4)
      entries[13].vl <= _GEN_275;
    else
      entries[13].vl <= vstart_2;
    if (_GEN_315 & wbIndexReg_2_r == 4'hE) begin
      if (isusMerge_2)
        entries[14].data <= usMergeData_2;
      else
        entries[14].data <= mergeDataReg_2_r;
    end
    else if (_GEN_313 & wbIndexReg_1_r == 4'hE) begin
      if (isusMerge_1)
        entries[14].data <= usMergeData_1;
      else
        entries[14].data <= mergeDataReg_1_r;
    end
    else if (pipewbValidReg_0_REG & wbIndexReg_0_r == 4'hE) begin
      if (isusMerge)
        entries[14].data <= usMergeData;
      else
        entries[14].data <= mergeDataReg_0_r;
    end
    else if (_GEN_179)
      entries[14].data <= io_fromSplit_1_req_bits_data;
    else if (_GEN_14)
      entries[14].data <= io_fromSplit_0_req_bits_data;
    if (_GEN_179) begin
      entries[14].mask <= io_fromSplit_1_req_bits_mask;
      entries[14].uop_fuOpType <= io_fromSplit_1_req_bits_uop_fuOpType;
      entries[14].uop_vecWen <= io_fromSplit_1_req_bits_uop_vecWen;
      entries[14].uop_v0Wen <= io_fromSplit_1_req_bits_uop_v0Wen;
      entries[14].uop_vlWen <= io_fromSplit_1_req_bits_uop_vlWen;
      entries[14].uop_vpu_vma <= io_fromSplit_1_req_bits_uop_vpu_vma;
      entries[14].uop_vpu_vsew <= io_fromSplit_1_req_bits_uop_vpu_vsew;
      entries[14].uop_vpu_vlmul <= io_fromSplit_1_req_bits_uop_vpu_vlmul;
      entries[14].uop_vpu_vm <= io_fromSplit_1_req_bits_uop_vpu_vm;
      entries[14].uop_vpu_vuopIdx <= io_fromSplit_1_req_bits_uop_vpu_vuopIdx;
      entries[14].uop_vpu_nf <= io_fromSplit_1_req_bits_uop_vpu_nf;
      entries[14].uop_vpu_veew <= io_fromSplit_1_req_bits_uop_vpu_veew;
      entries[14].uop_uopIdx <= io_fromSplit_1_req_bits_uop_uopIdx;
      entries[14].uop_pdest <= io_fromSplit_1_req_bits_uop_pdest;
      entries[14].uop_robIdx_flag <= io_fromSplit_1_req_bits_uop_robIdx_flag;
      entries[14].uop_robIdx_value <= io_fromSplit_1_req_bits_uop_robIdx_value;
      entries[14].uop_debugInfo_enqRsTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime;
      entries[14].uop_debugInfo_selectTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_selectTime;
      entries[14].uop_debugInfo_issueTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_issueTime;
      entries[14].vdIdx <= io_fromSplit_1_req_bits_vdIdx;
      entries[14].fof <= io_fromSplit_1_req_bits_fof;
      entries[14].vlmax <= io_fromSplit_1_req_bits_vlmax;
    end
    else if (_GEN_14) begin
      entries[14].mask <= io_fromSplit_0_req_bits_mask;
      entries[14].uop_fuOpType <= io_fromSplit_0_req_bits_uop_fuOpType;
      entries[14].uop_vecWen <= io_fromSplit_0_req_bits_uop_vecWen;
      entries[14].uop_v0Wen <= io_fromSplit_0_req_bits_uop_v0Wen;
      entries[14].uop_vlWen <= io_fromSplit_0_req_bits_uop_vlWen;
      entries[14].uop_vpu_vma <= io_fromSplit_0_req_bits_uop_vpu_vma;
      entries[14].uop_vpu_vsew <= io_fromSplit_0_req_bits_uop_vpu_vsew;
      entries[14].uop_vpu_vlmul <= io_fromSplit_0_req_bits_uop_vpu_vlmul;
      entries[14].uop_vpu_vm <= io_fromSplit_0_req_bits_uop_vpu_vm;
      entries[14].uop_vpu_vuopIdx <= io_fromSplit_0_req_bits_uop_vpu_vuopIdx;
      entries[14].uop_vpu_nf <= io_fromSplit_0_req_bits_uop_vpu_nf;
      entries[14].uop_vpu_veew <= io_fromSplit_0_req_bits_uop_vpu_veew;
      entries[14].uop_uopIdx <= io_fromSplit_0_req_bits_uop_uopIdx;
      entries[14].uop_pdest <= io_fromSplit_0_req_bits_uop_pdest;
      entries[14].uop_robIdx_flag <= io_fromSplit_0_req_bits_uop_robIdx_flag;
      entries[14].uop_robIdx_value <= io_fromSplit_0_req_bits_uop_robIdx_value;
      entries[14].uop_debugInfo_enqRsTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime;
      entries[14].uop_debugInfo_selectTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_selectTime;
      entries[14].uop_debugInfo_issueTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_issueTime;
      entries[14].vdIdx <= io_fromSplit_0_req_bits_vdIdx;
      entries[14].fof <= io_fromSplit_0_req_bits_fof;
      entries[14].vlmax <= io_fromSplit_0_req_bits_vlmax;
    end
    if (_GEN_310 & latchWbIndex_2 == 4'hE)
      entries[14].flowNum <= _entries_flowNum_T_4;
    else if (_GEN_309 & latchWbIndex_1 == 4'hE)
      entries[14].flowNum <= _entries_flowNum_T_2;
    else if (latchWbValid & latchWbIndex == 4'hE)
      entries[14].flowNum <= _entries_flowNum_T;
    else if (_GEN_179)
      entries[14].flowNum <= io_fromSplit_1_req_bits_flowNum;
    else if (_GEN_14)
      entries[14].flowNum <= io_fromSplit_0_req_bits_flowNum;
    if (_GEN_276 & _GEN_292 & _GEN_291) begin
      entries[14].exceptionVec_3 <= pipeBitsReg_2_exceptionVec_3;
      entries[14].exceptionVec_4 <= pipeBitsReg_2_exceptionVec_4;
      entries[14].exceptionVec_5 <= pipeBitsReg_2_exceptionVec_5;
      entries[14].exceptionVec_13 <= pipeBitsReg_2_exceptionVec_13;
      entries[14].exceptionVec_19 <= pipeBitsReg_2_exceptionVec_19;
      entries[14].exceptionVec_21 <= pipeBitsReg_2_exceptionVec_21;
      entries[14].uop_trigger <= pipeBitsReg_2_trigger;
      entries[14].vstart <= vstart_2;
      entries[14].vaNeedExt <= pipeBitsReg_2_vaNeedExt;
      entries[14].vaddr <= _vaddr_T_2;
      entries[14].gpaddr <= pipeBitsReg_2_gpaddr[49:0];
    end
    else if (_GEN_241 & _GEN_257 & _GEN_256) begin
      entries[14].exceptionVec_3 <= new_vec_3_3;
      entries[14].exceptionVec_4 <= new_vec_3_4;
      entries[14].exceptionVec_5 <= new_vec_3_5;
      entries[14].exceptionVec_13 <= new_vec_3_13;
      entries[14].exceptionVec_19 <= new_vec_3_19;
      entries[14].exceptionVec_21 <= new_vec_3_21;
      entries[14].uop_trigger <= sel_oldest_1_bits_trigger;
      entries[14].vstart <= vstart_1;
      entries[14].vaNeedExt <= sel_oldest_1_bits_vaNeedExt;
      entries[14].vaddr <= _vaddr_T_1;
      entries[14].gpaddr <= sel_oldest_1_bits_gpaddr;
    end
    else if (_GEN_205 & _GEN_221 & _GEN_220) begin
      entries[14].exceptionVec_3 <= new_vec_2_3;
      entries[14].exceptionVec_4 <= new_vec_2_4;
      entries[14].exceptionVec_5 <= new_vec_2_5;
      entries[14].exceptionVec_13 <= new_vec_2_13;
      entries[14].exceptionVec_19 <= new_vec_2_19;
      entries[14].exceptionVec_21 <= new_vec_2_21;
      entries[14].uop_trigger <= sel_oldest_bits_trigger;
      entries[14].vstart <= vstart;
      entries[14].vaNeedExt <= sel_oldest_bits_vaNeedExt;
      entries[14].vaddr <= _vaddr_T;
      entries[14].gpaddr <= sel_oldest_bits_gpaddr;
    end
    else begin
      if (_GEN_16) begin
        entries[14].exceptionVec_3 <= ~_GEN_46 & entries[14].exceptionVec_3;
        entries[14].exceptionVec_4 <= ~_GEN_46 & entries[14].exceptionVec_4;
        entries[14].exceptionVec_5 <= ~_GEN_46 & entries[14].exceptionVec_5;
        entries[14].exceptionVec_13 <= ~_GEN_46 & entries[14].exceptionVec_13;
        entries[14].exceptionVec_19 <= ~_GEN_46 & entries[14].exceptionVec_19;
        entries[14].exceptionVec_21 <= ~_GEN_46 & entries[14].exceptionVec_21;
      end
      else begin
        entries[14].exceptionVec_3 <= ~_GEN_14 & entries[14].exceptionVec_3;
        entries[14].exceptionVec_4 <= ~_GEN_14 & entries[14].exceptionVec_4;
        entries[14].exceptionVec_5 <= ~_GEN_14 & entries[14].exceptionVec_5;
        entries[14].exceptionVec_13 <= ~_GEN_14 & entries[14].exceptionVec_13;
        entries[14].exceptionVec_19 <= ~_GEN_14 & entries[14].exceptionVec_19;
        entries[14].exceptionVec_21 <= ~_GEN_14 & entries[14].exceptionVec_21;
      end
      if (_GEN_179 | _GEN_14)
        entries[14].uop_trigger <= 4'h0;
      if (_GEN_195)
        entries[14].vstart <= 8'h0;
      if (_GEN_179)
        entries[14].vaddr <= _GEN_197;
      else if (_GEN_14)
        entries[14].vaddr <= _GEN_164;
    end
    entries[14].uop_flushPipe <= ~_GEN_179 & ~_GEN_14 & entries[14].uop_flushPipe;
    entries[14].uop_vpu_vta <=
      _GEN_307 & _GEN_272 & _GEN_236
      & (_GEN_179
           ? io_fromSplit_1_req_bits_uop_vpu_vta
           : _GEN_14 ? io_fromSplit_0_req_bits_uop_vpu_vta : entries[14].uop_vpu_vta);
    entries[14].uop_replayInst <= ~_GEN_179 & ~_GEN_14 & entries[14].uop_replayInst;
    if (_GEN_276 & _GEN_291)
      entries[14].elemIdx <= pipeBitsReg_2_elemIdx;
    else if (_GEN_241 & _GEN_256)
      entries[14].elemIdx <= sel_oldest_1_bits_elemIdx;
    else if (_GEN_205 & _GEN_220)
      entries[14].elemIdx <= sel_oldest_bits_elemIdx;
    else if (_GEN_195)
      entries[14].elemIdx <= 8'hFF;
    if (_GEN_307) begin
      if (_GEN_272) begin
        if (_GEN_236) begin
          if (_GEN_179)
            entries[14].vl <= io_fromSplit_1_req_bits_uop_vpu_vl;
          else if (_GEN_14)
            entries[14].vl <= io_fromSplit_0_req_bits_uop_vpu_vl;
        end
        else if (_entries_vl_T)
          entries[14].vl <= _GEN_201;
        else
          entries[14].vl <= vstart;
      end
      else if (_entries_vl_T_2)
        entries[14].vl <= _GEN_239;
      else
        entries[14].vl <= vstart_1;
    end
    else if (_entries_vl_T_4)
      entries[14].vl <= _GEN_275;
    else
      entries[14].vl <= vstart_2;
    if (_GEN_315 & (&wbIndexReg_2_r)) begin
      if (isusMerge_2)
        entries[15].data <= usMergeData_2;
      else
        entries[15].data <= mergeDataReg_2_r;
    end
    else if (_GEN_313 & (&wbIndexReg_1_r)) begin
      if (isusMerge_1)
        entries[15].data <= usMergeData_1;
      else
        entries[15].data <= mergeDataReg_1_r;
    end
    else if (pipewbValidReg_0_REG & (&wbIndexReg_0_r)) begin
      if (isusMerge)
        entries[15].data <= usMergeData;
      else
        entries[15].data <= mergeDataReg_0_r;
    end
    else if (_GEN_180)
      entries[15].data <= io_fromSplit_1_req_bits_data;
    else if (_GEN_15)
      entries[15].data <= io_fromSplit_0_req_bits_data;
    if (_GEN_180) begin
      entries[15].mask <= io_fromSplit_1_req_bits_mask;
      entries[15].uop_fuOpType <= io_fromSplit_1_req_bits_uop_fuOpType;
      entries[15].uop_vecWen <= io_fromSplit_1_req_bits_uop_vecWen;
      entries[15].uop_v0Wen <= io_fromSplit_1_req_bits_uop_v0Wen;
      entries[15].uop_vlWen <= io_fromSplit_1_req_bits_uop_vlWen;
      entries[15].uop_vpu_vma <= io_fromSplit_1_req_bits_uop_vpu_vma;
      entries[15].uop_vpu_vsew <= io_fromSplit_1_req_bits_uop_vpu_vsew;
      entries[15].uop_vpu_vlmul <= io_fromSplit_1_req_bits_uop_vpu_vlmul;
      entries[15].uop_vpu_vm <= io_fromSplit_1_req_bits_uop_vpu_vm;
      entries[15].uop_vpu_vuopIdx <= io_fromSplit_1_req_bits_uop_vpu_vuopIdx;
      entries[15].uop_vpu_nf <= io_fromSplit_1_req_bits_uop_vpu_nf;
      entries[15].uop_vpu_veew <= io_fromSplit_1_req_bits_uop_vpu_veew;
      entries[15].uop_uopIdx <= io_fromSplit_1_req_bits_uop_uopIdx;
      entries[15].uop_pdest <= io_fromSplit_1_req_bits_uop_pdest;
      entries[15].uop_robIdx_flag <= io_fromSplit_1_req_bits_uop_robIdx_flag;
      entries[15].uop_robIdx_value <= io_fromSplit_1_req_bits_uop_robIdx_value;
      entries[15].uop_debugInfo_enqRsTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_enqRsTime;
      entries[15].uop_debugInfo_selectTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_selectTime;
      entries[15].uop_debugInfo_issueTime <=
        io_fromSplit_1_req_bits_uop_debugInfo_issueTime;
      entries[15].vdIdx <= io_fromSplit_1_req_bits_vdIdx;
      entries[15].fof <= io_fromSplit_1_req_bits_fof;
      entries[15].vlmax <= io_fromSplit_1_req_bits_vlmax;
    end
    else if (_GEN_15) begin
      entries[15].mask <= io_fromSplit_0_req_bits_mask;
      entries[15].uop_fuOpType <= io_fromSplit_0_req_bits_uop_fuOpType;
      entries[15].uop_vecWen <= io_fromSplit_0_req_bits_uop_vecWen;
      entries[15].uop_v0Wen <= io_fromSplit_0_req_bits_uop_v0Wen;
      entries[15].uop_vlWen <= io_fromSplit_0_req_bits_uop_vlWen;
      entries[15].uop_vpu_vma <= io_fromSplit_0_req_bits_uop_vpu_vma;
      entries[15].uop_vpu_vsew <= io_fromSplit_0_req_bits_uop_vpu_vsew;
      entries[15].uop_vpu_vlmul <= io_fromSplit_0_req_bits_uop_vpu_vlmul;
      entries[15].uop_vpu_vm <= io_fromSplit_0_req_bits_uop_vpu_vm;
      entries[15].uop_vpu_vuopIdx <= io_fromSplit_0_req_bits_uop_vpu_vuopIdx;
      entries[15].uop_vpu_nf <= io_fromSplit_0_req_bits_uop_vpu_nf;
      entries[15].uop_vpu_veew <= io_fromSplit_0_req_bits_uop_vpu_veew;
      entries[15].uop_uopIdx <= io_fromSplit_0_req_bits_uop_uopIdx;
      entries[15].uop_pdest <= io_fromSplit_0_req_bits_uop_pdest;
      entries[15].uop_robIdx_flag <= io_fromSplit_0_req_bits_uop_robIdx_flag;
      entries[15].uop_robIdx_value <= io_fromSplit_0_req_bits_uop_robIdx_value;
      entries[15].uop_debugInfo_enqRsTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_enqRsTime;
      entries[15].uop_debugInfo_selectTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_selectTime;
      entries[15].uop_debugInfo_issueTime <=
        io_fromSplit_0_req_bits_uop_debugInfo_issueTime;
      entries[15].vdIdx <= io_fromSplit_0_req_bits_vdIdx;
      entries[15].fof <= io_fromSplit_0_req_bits_fof;
      entries[15].vlmax <= io_fromSplit_0_req_bits_vlmax;
    end
    if (_GEN_310 & (&latchWbIndex_2))
      entries[15].flowNum <= _entries_flowNum_T_4;
    else if (_GEN_309 & (&latchWbIndex_1))
      entries[15].flowNum <= _entries_flowNum_T_2;
    else if (latchWbValid & (&latchWbIndex))
      entries[15].flowNum <= _entries_flowNum_T;
    else if (_GEN_180)
      entries[15].flowNum <= io_fromSplit_1_req_bits_flowNum;
    else if (_GEN_15)
      entries[15].flowNum <= io_fromSplit_0_req_bits_flowNum;
    if (_GEN_276 & _GEN_292 & (&pipeBitsReg_2_mBIndex)) begin
      entries[15].exceptionVec_3 <= pipeBitsReg_2_exceptionVec_3;
      entries[15].exceptionVec_4 <= pipeBitsReg_2_exceptionVec_4;
      entries[15].exceptionVec_5 <= pipeBitsReg_2_exceptionVec_5;
      entries[15].exceptionVec_13 <= pipeBitsReg_2_exceptionVec_13;
      entries[15].exceptionVec_19 <= pipeBitsReg_2_exceptionVec_19;
      entries[15].exceptionVec_21 <= pipeBitsReg_2_exceptionVec_21;
      entries[15].uop_trigger <= pipeBitsReg_2_trigger;
      entries[15].vstart <= vstart_2;
      entries[15].vaNeedExt <= pipeBitsReg_2_vaNeedExt;
      entries[15].vaddr <= _vaddr_T_2;
      entries[15].gpaddr <= pipeBitsReg_2_gpaddr[49:0];
    end
    else if (_GEN_241 & _GEN_257 & (&pipeBitsReg_1_mBIndex)) begin
      entries[15].exceptionVec_3 <= new_vec_3_3;
      entries[15].exceptionVec_4 <= new_vec_3_4;
      entries[15].exceptionVec_5 <= new_vec_3_5;
      entries[15].exceptionVec_13 <= new_vec_3_13;
      entries[15].exceptionVec_19 <= new_vec_3_19;
      entries[15].exceptionVec_21 <= new_vec_3_21;
      entries[15].uop_trigger <= sel_oldest_1_bits_trigger;
      entries[15].vstart <= vstart_1;
      entries[15].vaNeedExt <= sel_oldest_1_bits_vaNeedExt;
      entries[15].vaddr <= _vaddr_T_1;
      entries[15].gpaddr <= sel_oldest_1_bits_gpaddr;
    end
    else if (_GEN_205 & _GEN_221 & (&pipeBitsReg_0_mBIndex)) begin
      entries[15].exceptionVec_3 <= new_vec_2_3;
      entries[15].exceptionVec_4 <= new_vec_2_4;
      entries[15].exceptionVec_5 <= new_vec_2_5;
      entries[15].exceptionVec_13 <= new_vec_2_13;
      entries[15].exceptionVec_19 <= new_vec_2_19;
      entries[15].exceptionVec_21 <= new_vec_2_21;
      entries[15].uop_trigger <= sel_oldest_bits_trigger;
      entries[15].vstart <= vstart;
      entries[15].vaNeedExt <= sel_oldest_bits_vaNeedExt;
      entries[15].vaddr <= _vaddr_T;
      entries[15].gpaddr <= sel_oldest_bits_gpaddr;
    end
    else begin
      if (_GEN_16) begin
        entries[15].exceptionVec_3 <= ~_GEN_47 & entries[15].exceptionVec_3;
        entries[15].exceptionVec_4 <= ~_GEN_47 & entries[15].exceptionVec_4;
        entries[15].exceptionVec_5 <= ~_GEN_47 & entries[15].exceptionVec_5;
        entries[15].exceptionVec_13 <= ~_GEN_47 & entries[15].exceptionVec_13;
        entries[15].exceptionVec_19 <= ~_GEN_47 & entries[15].exceptionVec_19;
        entries[15].exceptionVec_21 <= ~_GEN_47 & entries[15].exceptionVec_21;
      end
      else begin
        entries[15].exceptionVec_3 <= ~_GEN_15 & entries[15].exceptionVec_3;
        entries[15].exceptionVec_4 <= ~_GEN_15 & entries[15].exceptionVec_4;
        entries[15].exceptionVec_5 <= ~_GEN_15 & entries[15].exceptionVec_5;
        entries[15].exceptionVec_13 <= ~_GEN_15 & entries[15].exceptionVec_13;
        entries[15].exceptionVec_19 <= ~_GEN_15 & entries[15].exceptionVec_19;
        entries[15].exceptionVec_21 <= ~_GEN_15 & entries[15].exceptionVec_21;
      end
      if (_GEN_180 | _GEN_15)
        entries[15].uop_trigger <= 4'h0;
      if (_GEN_196)
        entries[15].vstart <= 8'h0;
      if (_GEN_180)
        entries[15].vaddr <= _GEN_197;
      else if (_GEN_15)
        entries[15].vaddr <= _GEN_164;
    end
    entries[15].uop_flushPipe <= ~_GEN_180 & ~_GEN_15 & entries[15].uop_flushPipe;
    entries[15].uop_vpu_vta <=
      _GEN_308 & _GEN_273 & _GEN_237
      & (_GEN_180
           ? io_fromSplit_1_req_bits_uop_vpu_vta
           : _GEN_15 ? io_fromSplit_0_req_bits_uop_vpu_vta : entries[15].uop_vpu_vta);
    entries[15].uop_replayInst <= ~_GEN_180 & ~_GEN_15 & entries[15].uop_replayInst;
    if (_GEN_276 & (&pipeBitsReg_2_mBIndex))
      entries[15].elemIdx <= pipeBitsReg_2_elemIdx;
    else if (_GEN_241 & (&pipeBitsReg_1_mBIndex))
      entries[15].elemIdx <= sel_oldest_1_bits_elemIdx;
    else if (_GEN_205 & (&pipeBitsReg_0_mBIndex))
      entries[15].elemIdx <= sel_oldest_bits_elemIdx;
    else if (_GEN_196)
      entries[15].elemIdx <= 8'hFF;
    if (_GEN_308) begin
      if (_GEN_273) begin
        if (_GEN_237) begin
          if (_GEN_180)
            entries[15].vl <= io_fromSplit_1_req_bits_uop_vpu_vl;
          else if (_GEN_15)
            entries[15].vl <= io_fromSplit_0_req_bits_uop_vpu_vl;
        end
        else if (_entries_vl_T)
          entries[15].vl <= _GEN_201;
        else
          entries[15].vl <= vstart;
      end
      else if (_entries_vl_T_2)
        entries[15].vl <= _GEN_239;
      else
        entries[15].vl <= vstart_1;
    end
    else if (_entries_vl_T_4)
      entries[15].vl <= _GEN_275;
    else
      entries[15].vl <= vstart_2;
    mergePortMatrixHasExcpWrap_0_0 <=
      io_fromPipeline_0_bits_hasException | _maskWithexceptionMask_T_1;
    mergePortMatrixHasExcpWrap_0_1 <=
      mergePortValid_1
      & (io_fromPipeline_1_bits_hasException | _maskWithexceptionMask_T_10);
    mergePortMatrixHasExcpWrap_0_2 <=
      mergePortValid_2
      & (io_fromPipeline_2_bits_hasException | _maskWithexceptionMask_T_19);
    mergePortMatrixHasExcpWrap_1_1 <=
      io_fromPipeline_1_bits_hasException | _maskWithexceptionMask_T_10;
    mergePortMatrixHasExcpWrap_1_2 <=
      selIdx_1 & (io_fromPipeline_2_bits_hasException | _maskWithexceptionMask_T_19);
    portHasExcp_2 <= io_fromPipeline_2_bits_hasException | _maskWithexceptionMask_T_19;
    mergedByPrevPortVecWrap_1 <= mergedByPrevPortVec_1;
    mergedByPrevPortVecWrap_2 <= |_mergedByPrevPortVec_2_T_4;
    pipeValidReg_0 <= io_fromPipeline_0_valid;
    pipeValidReg_1 <= io_fromPipeline_1_valid;
    pipeValidReg_2 <= io_fromPipeline_2_valid;
    if (io_fromPipeline_0_valid) begin
      pipeBitsReg_0_mBIndex <= io_fromPipeline_0_bits_mBIndex;
      pipeBitsReg_0_trigger <= io_fromPipeline_0_bits_trigger;
      pipeBitsReg_0_exceptionVec_3 <= io_fromPipeline_0_bits_exceptionVec_3;
      pipeBitsReg_0_exceptionVec_4 <= io_fromPipeline_0_bits_exceptionVec_4;
      pipeBitsReg_0_exceptionVec_5 <= io_fromPipeline_0_bits_exceptionVec_5;
      pipeBitsReg_0_exceptionVec_13 <= io_fromPipeline_0_bits_exceptionVec_13;
      pipeBitsReg_0_exceptionVec_19 <= io_fromPipeline_0_bits_exceptionVec_19;
      pipeBitsReg_0_exceptionVec_21 <= io_fromPipeline_0_bits_exceptionVec_21;
      pipeBitsReg_0_vaddr <= io_fromPipeline_0_bits_vaddr;
      pipeBitsReg_0_vaNeedExt <= io_fromPipeline_0_bits_vaNeedExt;
      pipeBitsReg_0_gpaddr <= io_fromPipeline_0_bits_gpaddr;
      pipeBitsReg_0_vstart <= io_fromPipeline_0_bits_vstart;
      pipeBitsReg_0_elemIdx <= io_fromPipeline_0_bits_elemIdx;
      pipeBitsReg_0_mask <= io_fromPipeline_0_bits_mask;
      latchWbIndex <= io_fromPipeline_0_bits_mBIndex;
      latchFlowNum <= 2'(_GEN_316 + 2'({1'h0, mergePortValid_2} + 2'h1));
      wbIndexReg_0_r <= io_fromPipeline_0_bits_mBIndex;
      mergeDataReg_0_r <=
        _GEN_317
        | (io_fromPipeline_0_bits_alignedType[1:0] == 2'h2
             ? {(&(io_fromPipeline_1_bits_elemIdxInsideVd[1:0])) & mergePortValid_1
                | _mergedData_T_458
                  ? (_mergedData_T_458
                       ? io_fromPipeline_2_bits_vecdata[31:0]
                       : io_fromPipeline_1_bits_vecdata[31:0])
                  : (&(io_fromPipeline_0_bits_elemIdxInsideVd[1:0]))
                      ? io_fromPipeline_0_bits_vecdata[31:0]
                      : oldData[127:96],
                io_fromPipeline_1_bits_elemIdxInsideVd[1:0] == 2'h2 & mergePortValid_1
                | _mergedData_T_445
                  ? (_mergedData_T_445
                       ? io_fromPipeline_2_bits_vecdata[31:0]
                       : io_fromPipeline_1_bits_vecdata[31:0])
                  : io_fromPipeline_0_bits_elemIdxInsideVd[1:0] == 2'h2
                      ? io_fromPipeline_0_bits_vecdata[31:0]
                      : oldData[95:64],
                io_fromPipeline_1_bits_elemIdxInsideVd[1:0] == 2'h1 & mergePortValid_1
                | _mergedData_T_432
                  ? (_mergedData_T_432
                       ? io_fromPipeline_2_bits_vecdata[31:0]
                       : io_fromPipeline_1_bits_vecdata[31:0])
                  : io_fromPipeline_0_bits_elemIdxInsideVd[1:0] == 2'h1
                      ? io_fromPipeline_0_bits_vecdata[31:0]
                      : oldData[63:32],
                io_fromPipeline_1_bits_elemIdxInsideVd[1:0] == 2'h0 & mergePortValid_1
                | _mergedData_T_419
                  ? (_mergedData_T_419
                       ? io_fromPipeline_2_bits_vecdata[31:0]
                       : io_fromPipeline_1_bits_vecdata[31:0])
                  : io_fromPipeline_0_bits_elemIdxInsideVd[1:0] == 2'h0
                      ? io_fromPipeline_0_bits_vecdata[31:0]
                      : oldData[31:0]}
             : 128'h0)
        | ((&(io_fromPipeline_0_bits_alignedType[1:0]))
             ? {io_fromPipeline_1_bits_elemIdxInsideVd[0] & mergePortValid_1
                | _mergedData_T_497
                  ? (_mergedData_T_497
                       ? io_fromPipeline_2_bits_vecdata[63:0]
                       : io_fromPipeline_1_bits_vecdata[63:0])
                  : io_fromPipeline_0_bits_elemIdxInsideVd[0]
                      ? io_fromPipeline_0_bits_vecdata[63:0]
                      : oldData[127:64],
                ~(io_fromPipeline_1_bits_elemIdxInsideVd[0]) & mergePortValid_1
                | _mergedData_T_484
                  ? (_mergedData_T_484
                       ? io_fromPipeline_2_bits_vecdata[63:0]
                       : io_fromPipeline_1_bits_vecdata[63:0])
                  : io_fromPipeline_0_bits_elemIdxInsideVd[0]
                      ? oldData[63:0]
                      : io_fromPipeline_0_bits_vecdata[63:0]}
             : 128'h0);
      brodenMergeDataReg <= _selMask_T ? _GEN_163[selIdx] : _GEN_162[selIdx];
      brodenMergeMaskReg <= _selMask_T ? _GEN_319[selIdx] : _GEN_318[selIdx];
      regOffsetReg <= io_fromPipeline_0_bits_reg_offset;
      isusMerge <= io_fromPipeline_0_bits_alignedType[2];
    end
    if (io_fromPipeline_1_valid) begin
      pipeBitsReg_1_mBIndex <= io_fromPipeline_1_bits_mBIndex;
      pipeBitsReg_1_trigger <= io_fromPipeline_1_bits_trigger;
      pipeBitsReg_1_exceptionVec_3 <= io_fromPipeline_1_bits_exceptionVec_3;
      pipeBitsReg_1_exceptionVec_4 <= io_fromPipeline_1_bits_exceptionVec_4;
      pipeBitsReg_1_exceptionVec_5 <= io_fromPipeline_1_bits_exceptionVec_5;
      pipeBitsReg_1_exceptionVec_13 <= io_fromPipeline_1_bits_exceptionVec_13;
      pipeBitsReg_1_exceptionVec_19 <= io_fromPipeline_1_bits_exceptionVec_19;
      pipeBitsReg_1_exceptionVec_21 <= io_fromPipeline_1_bits_exceptionVec_21;
      pipeBitsReg_1_vaddr <= io_fromPipeline_1_bits_vaddr;
      pipeBitsReg_1_vaNeedExt <= io_fromPipeline_1_bits_vaNeedExt;
      pipeBitsReg_1_gpaddr <= io_fromPipeline_1_bits_gpaddr;
      pipeBitsReg_1_vstart <= io_fromPipeline_1_bits_vstart;
      pipeBitsReg_1_elemIdx <= io_fromPipeline_1_bits_elemIdx;
      pipeBitsReg_1_mask <= io_fromPipeline_1_bits_mask;
      latchWbIndex_1 <= io_fromPipeline_1_bits_mBIndex;
      latchFlowNum_1 <= 2'({1'h0, selIdx_1} + 2'h1);
      latchMergeByPre_1 <= mergedByPrevPortVec_1;
      wbIndexReg_1_r <= io_fromPipeline_1_bits_mBIndex;
      mergeDataReg_1_r <=
        (io_fromPipeline_1_bits_alignedType[1:0] == 2'h0
           ? {(&(io_fromPipeline_1_bits_elemIdxInsideVd[3:0])) | _mergedData_T_772
                ? (_mergedData_T_772
                     ? io_fromPipeline_2_bits_vecdata[7:0]
                     : io_fromPipeline_1_bits_vecdata[7:0])
                : oldData_1[127:120],
              io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'hE | _mergedData_T_759
                ? (_mergedData_T_759
                     ? io_fromPipeline_2_bits_vecdata[7:0]
                     : io_fromPipeline_1_bits_vecdata[7:0])
                : oldData_1[119:112],
              io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'hD | _mergedData_T_746
                ? (_mergedData_T_746
                     ? io_fromPipeline_2_bits_vecdata[7:0]
                     : io_fromPipeline_1_bits_vecdata[7:0])
                : oldData_1[111:104],
              io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'hC | _mergedData_T_733
                ? (_mergedData_T_733
                     ? io_fromPipeline_2_bits_vecdata[7:0]
                     : io_fromPipeline_1_bits_vecdata[7:0])
                : oldData_1[103:96],
              io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'hB | _mergedData_T_720
                ? (_mergedData_T_720
                     ? io_fromPipeline_2_bits_vecdata[7:0]
                     : io_fromPipeline_1_bits_vecdata[7:0])
                : oldData_1[95:88],
              io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'hA | _mergedData_T_707
                ? (_mergedData_T_707
                     ? io_fromPipeline_2_bits_vecdata[7:0]
                     : io_fromPipeline_1_bits_vecdata[7:0])
                : oldData_1[87:80],
              io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'h9 | _mergedData_T_694
                ? (_mergedData_T_694
                     ? io_fromPipeline_2_bits_vecdata[7:0]
                     : io_fromPipeline_1_bits_vecdata[7:0])
                : oldData_1[79:72],
              io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'h8 | _mergedData_T_681
                ? (_mergedData_T_681
                     ? io_fromPipeline_2_bits_vecdata[7:0]
                     : io_fromPipeline_1_bits_vecdata[7:0])
                : oldData_1[71:64],
              io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'h7 | _mergedData_T_668
                ? (_mergedData_T_668
                     ? io_fromPipeline_2_bits_vecdata[7:0]
                     : io_fromPipeline_1_bits_vecdata[7:0])
                : oldData_1[63:56],
              io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'h6 | _mergedData_T_655
                ? (_mergedData_T_655
                     ? io_fromPipeline_2_bits_vecdata[7:0]
                     : io_fromPipeline_1_bits_vecdata[7:0])
                : oldData_1[55:48],
              io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'h5 | _mergedData_T_642
                ? (_mergedData_T_642
                     ? io_fromPipeline_2_bits_vecdata[7:0]
                     : io_fromPipeline_1_bits_vecdata[7:0])
                : oldData_1[47:40],
              io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'h4 | _mergedData_T_629
                ? (_mergedData_T_629
                     ? io_fromPipeline_2_bits_vecdata[7:0]
                     : io_fromPipeline_1_bits_vecdata[7:0])
                : oldData_1[39:32],
              io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'h3 | _mergedData_T_616
                ? (_mergedData_T_616
                     ? io_fromPipeline_2_bits_vecdata[7:0]
                     : io_fromPipeline_1_bits_vecdata[7:0])
                : oldData_1[31:24],
              io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'h2 | _mergedData_T_603
                ? (_mergedData_T_603
                     ? io_fromPipeline_2_bits_vecdata[7:0]
                     : io_fromPipeline_1_bits_vecdata[7:0])
                : oldData_1[23:16],
              io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'h1 | _mergedData_T_590
                ? (_mergedData_T_590
                     ? io_fromPipeline_2_bits_vecdata[7:0]
                     : io_fromPipeline_1_bits_vecdata[7:0])
                : oldData_1[15:8],
              io_fromPipeline_1_bits_elemIdxInsideVd[3:0] == 4'h0 | _mergedData_T_577
                ? (_mergedData_T_577
                     ? io_fromPipeline_2_bits_vecdata[7:0]
                     : io_fromPipeline_1_bits_vecdata[7:0])
                : oldData_1[7:0]}
           : 128'h0)
        | (io_fromPipeline_1_bits_alignedType[1:0] == 2'h1
             ? {(&(io_fromPipeline_1_bits_elemIdxInsideVd[2:0])) | _mergedData_T_907
                  ? (_mergedData_T_907
                       ? io_fromPipeline_2_bits_vecdata[15:0]
                       : io_fromPipeline_1_bits_vecdata[15:0])
                  : oldData_1[127:112],
                io_fromPipeline_1_bits_elemIdxInsideVd[2:0] == 3'h6 | _mergedData_T_894
                  ? (_mergedData_T_894
                       ? io_fromPipeline_2_bits_vecdata[15:0]
                       : io_fromPipeline_1_bits_vecdata[15:0])
                  : oldData_1[111:96],
                io_fromPipeline_1_bits_elemIdxInsideVd[2:0] == 3'h5 | _mergedData_T_881
                  ? (_mergedData_T_881
                       ? io_fromPipeline_2_bits_vecdata[15:0]
                       : io_fromPipeline_1_bits_vecdata[15:0])
                  : oldData_1[95:80],
                io_fromPipeline_1_bits_elemIdxInsideVd[2:0] == 3'h4 | _mergedData_T_868
                  ? (_mergedData_T_868
                       ? io_fromPipeline_2_bits_vecdata[15:0]
                       : io_fromPipeline_1_bits_vecdata[15:0])
                  : oldData_1[79:64],
                io_fromPipeline_1_bits_elemIdxInsideVd[2:0] == 3'h3 | _mergedData_T_855
                  ? (_mergedData_T_855
                       ? io_fromPipeline_2_bits_vecdata[15:0]
                       : io_fromPipeline_1_bits_vecdata[15:0])
                  : oldData_1[63:48],
                io_fromPipeline_1_bits_elemIdxInsideVd[2:0] == 3'h2 | _mergedData_T_842
                  ? (_mergedData_T_842
                       ? io_fromPipeline_2_bits_vecdata[15:0]
                       : io_fromPipeline_1_bits_vecdata[15:0])
                  : oldData_1[47:32],
                io_fromPipeline_1_bits_elemIdxInsideVd[2:0] == 3'h1 | _mergedData_T_829
                  ? (_mergedData_T_829
                       ? io_fromPipeline_2_bits_vecdata[15:0]
                       : io_fromPipeline_1_bits_vecdata[15:0])
                  : oldData_1[31:16],
                io_fromPipeline_1_bits_elemIdxInsideVd[2:0] == 3'h0 | _mergedData_T_816
                  ? (_mergedData_T_816
                       ? io_fromPipeline_2_bits_vecdata[15:0]
                       : io_fromPipeline_1_bits_vecdata[15:0])
                  : oldData_1[15:0]}
             : 128'h0)
        | (io_fromPipeline_1_bits_alignedType[1:0] == 2'h2
             ? {(&(io_fromPipeline_1_bits_elemIdxInsideVd[1:0])) | _mergedData_T_978
                  ? (_mergedData_T_978
                       ? io_fromPipeline_2_bits_vecdata[31:0]
                       : io_fromPipeline_1_bits_vecdata[31:0])
                  : oldData_1[127:96],
                io_fromPipeline_1_bits_elemIdxInsideVd[1:0] == 2'h2 | _mergedData_T_965
                  ? (_mergedData_T_965
                       ? io_fromPipeline_2_bits_vecdata[31:0]
                       : io_fromPipeline_1_bits_vecdata[31:0])
                  : oldData_1[95:64],
                io_fromPipeline_1_bits_elemIdxInsideVd[1:0] == 2'h1 | _mergedData_T_952
                  ? (_mergedData_T_952
                       ? io_fromPipeline_2_bits_vecdata[31:0]
                       : io_fromPipeline_1_bits_vecdata[31:0])
                  : oldData_1[63:32],
                io_fromPipeline_1_bits_elemIdxInsideVd[1:0] == 2'h0 | _mergedData_T_939
                  ? (_mergedData_T_939
                       ? io_fromPipeline_2_bits_vecdata[31:0]
                       : io_fromPipeline_1_bits_vecdata[31:0])
                  : oldData_1[31:0]}
             : 128'h0)
        | ((&(io_fromPipeline_1_bits_alignedType[1:0]))
             ? {io_fromPipeline_1_bits_elemIdxInsideVd[0] | _mergedData_T_1017
                  ? (_mergedData_T_1017
                       ? io_fromPipeline_2_bits_vecdata[63:0]
                       : io_fromPipeline_1_bits_vecdata[63:0])
                  : oldData_1[127:64],
                ~(io_fromPipeline_1_bits_elemIdxInsideVd[0]) | _mergedData_T_1004
                  ? (_mergedData_T_1004
                       ? io_fromPipeline_2_bits_vecdata[63:0]
                       : io_fromPipeline_1_bits_vecdata[63:0])
                  : oldData_1[63:0]}
             : 128'h0);
      brodenMergeDataReg_1 <=
        _selMask_T_1
          ? {_GEN_320, io_fromPipeline_1_bits_vecdata}
          : {io_fromPipeline_1_bits_vecdata, _GEN_320};
      brodenMergeMaskReg_1 <=
        _selMask_T_1
          ? {_GEN_321, maskWithexceptionMask_1}
          : {maskWithexceptionMask_1, _GEN_321};
      mergedByPrevPortReg_1 <= mergedByPrevPortVec_1;
      regOffsetReg_1 <= io_fromPipeline_1_bits_reg_offset;
      isusMerge_1 <= io_fromPipeline_1_bits_alignedType[2];
    end
    if (io_fromPipeline_2_valid) begin
      pipeBitsReg_2_mBIndex <= io_fromPipeline_2_bits_mBIndex;
      pipeBitsReg_2_trigger <= io_fromPipeline_2_bits_trigger;
      pipeBitsReg_2_exceptionVec_3 <= io_fromPipeline_2_bits_exceptionVec_3;
      pipeBitsReg_2_exceptionVec_4 <= io_fromPipeline_2_bits_exceptionVec_4;
      pipeBitsReg_2_exceptionVec_5 <= io_fromPipeline_2_bits_exceptionVec_5;
      pipeBitsReg_2_exceptionVec_13 <= io_fromPipeline_2_bits_exceptionVec_13;
      pipeBitsReg_2_exceptionVec_19 <= io_fromPipeline_2_bits_exceptionVec_19;
      pipeBitsReg_2_exceptionVec_21 <= io_fromPipeline_2_bits_exceptionVec_21;
      pipeBitsReg_2_vaddr <= io_fromPipeline_2_bits_vaddr;
      pipeBitsReg_2_vaNeedExt <= io_fromPipeline_2_bits_vaNeedExt;
      pipeBitsReg_2_gpaddr <= io_fromPipeline_2_bits_gpaddr;
      pipeBitsReg_2_vstart <= io_fromPipeline_2_bits_vstart;
      pipeBitsReg_2_elemIdx <= io_fromPipeline_2_bits_elemIdx;
      pipeBitsReg_2_mask <= io_fromPipeline_2_bits_mask;
      latchWbIndex_2 <= io_fromPipeline_2_bits_mBIndex;
      latchMergeByPre_2 <= |_mergedByPrevPortVec_2_T_4;
      wbIndexReg_2_r <= io_fromPipeline_2_bits_mBIndex;
      mergeDataReg_2_r <=
        (io_fromPipeline_2_bits_alignedType[1:0] == 2'h0
           ? {(&(io_fromPipeline_2_bits_elemIdxInsideVd[3:0]))
                ? io_fromPipeline_2_bits_vecdata[7:0]
                : oldData_2[127:120],
              io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'hE
                ? io_fromPipeline_2_bits_vecdata[7:0]
                : oldData_2[119:112],
              io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'hD
                ? io_fromPipeline_2_bits_vecdata[7:0]
                : oldData_2[111:104],
              io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'hC
                ? io_fromPipeline_2_bits_vecdata[7:0]
                : oldData_2[103:96],
              io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'hB
                ? io_fromPipeline_2_bits_vecdata[7:0]
                : oldData_2[95:88],
              io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'hA
                ? io_fromPipeline_2_bits_vecdata[7:0]
                : oldData_2[87:80],
              io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h9
                ? io_fromPipeline_2_bits_vecdata[7:0]
                : oldData_2[79:72],
              io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h8
                ? io_fromPipeline_2_bits_vecdata[7:0]
                : oldData_2[71:64],
              io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h7
                ? io_fromPipeline_2_bits_vecdata[7:0]
                : oldData_2[63:56],
              io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h6
                ? io_fromPipeline_2_bits_vecdata[7:0]
                : oldData_2[55:48],
              io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h5
                ? io_fromPipeline_2_bits_vecdata[7:0]
                : oldData_2[47:40],
              io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h4
                ? io_fromPipeline_2_bits_vecdata[7:0]
                : oldData_2[39:32],
              io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h3
                ? io_fromPipeline_2_bits_vecdata[7:0]
                : oldData_2[31:24],
              io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h2
                ? io_fromPipeline_2_bits_vecdata[7:0]
                : oldData_2[23:16],
              io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h1
                ? io_fromPipeline_2_bits_vecdata[7:0]
                : oldData_2[15:8],
              io_fromPipeline_2_bits_elemIdxInsideVd[3:0] == 4'h0
                ? io_fromPipeline_2_bits_vecdata[7:0]
                : oldData_2[7:0]}
           : 128'h0)
        | (io_fromPipeline_2_bits_alignedType[1:0] == 2'h1
             ? {(&(io_fromPipeline_2_bits_elemIdxInsideVd[2:0]))
                  ? io_fromPipeline_2_bits_vecdata[15:0]
                  : oldData_2[127:112],
                io_fromPipeline_2_bits_elemIdxInsideVd[2:0] == 3'h6
                  ? io_fromPipeline_2_bits_vecdata[15:0]
                  : oldData_2[111:96],
                io_fromPipeline_2_bits_elemIdxInsideVd[2:0] == 3'h5
                  ? io_fromPipeline_2_bits_vecdata[15:0]
                  : oldData_2[95:80],
                io_fromPipeline_2_bits_elemIdxInsideVd[2:0] == 3'h4
                  ? io_fromPipeline_2_bits_vecdata[15:0]
                  : oldData_2[79:64],
                io_fromPipeline_2_bits_elemIdxInsideVd[2:0] == 3'h3
                  ? io_fromPipeline_2_bits_vecdata[15:0]
                  : oldData_2[63:48],
                io_fromPipeline_2_bits_elemIdxInsideVd[2:0] == 3'h2
                  ? io_fromPipeline_2_bits_vecdata[15:0]
                  : oldData_2[47:32],
                io_fromPipeline_2_bits_elemIdxInsideVd[2:0] == 3'h1
                  ? io_fromPipeline_2_bits_vecdata[15:0]
                  : oldData_2[31:16],
                io_fromPipeline_2_bits_elemIdxInsideVd[2:0] == 3'h0
                  ? io_fromPipeline_2_bits_vecdata[15:0]
                  : oldData_2[15:0]}
             : 128'h0)
        | (io_fromPipeline_2_bits_alignedType[1:0] == 2'h2
             ? {(&(io_fromPipeline_2_bits_elemIdxInsideVd[1:0]))
                  ? io_fromPipeline_2_bits_vecdata[31:0]
                  : oldData_2[127:96],
                io_fromPipeline_2_bits_elemIdxInsideVd[1:0] == 2'h2
                  ? io_fromPipeline_2_bits_vecdata[31:0]
                  : oldData_2[95:64],
                io_fromPipeline_2_bits_elemIdxInsideVd[1:0] == 2'h1
                  ? io_fromPipeline_2_bits_vecdata[31:0]
                  : oldData_2[63:32],
                io_fromPipeline_2_bits_elemIdxInsideVd[1:0] == 2'h0
                  ? io_fromPipeline_2_bits_vecdata[31:0]
                  : oldData_2[31:0]}
             : 128'h0)
        | ((&(io_fromPipeline_2_bits_alignedType[1:0]))
             ? {io_fromPipeline_2_bits_elemIdxInsideVd[0]
                  ? io_fromPipeline_2_bits_vecdata[63:0]
                  : oldData_2[127:64],
                io_fromPipeline_2_bits_elemIdxInsideVd[0]
                  ? oldData_2[63:0]
                  : io_fromPipeline_2_bits_vecdata[63:0]}
             : 128'h0);
      brodenMergeDataReg_2 <=
        _selMask_T_2
          ? {128'h0, io_fromPipeline_2_bits_vecdata}
          : {io_fromPipeline_2_bits_vecdata, 128'h0};
      brodenMergeMaskReg_2 <=
        _selMask_T_2
          ? {16'h0, maskWithexceptionMask_2}
          : {maskWithexceptionMask_2, 16'h0};
      mergedByPrevPortReg_2 <= |_mergedByPrevPortVec_2_T_4;
      regOffsetReg_2 <= io_fromPipeline_2_bits_reg_offset;
      isusMerge_2 <= io_fromPipeline_2_bits_alignedType[2];
    end
    wbElemIdxInField_0 <=
      io_fromPipeline_0_bits_elemIdx
      & 8'(_GEN_198[io_fromPipeline_0_bits_mBIndex] - 8'h1);
    wbElemIdxInField_1 <=
      io_fromPipeline_1_bits_elemIdx
      & 8'(_GEN_198[io_fromPipeline_1_bits_mBIndex] - 8'h1);
    wbElemIdxInField_2 <=
      io_fromPipeline_2_bits_elemIdx
      & 8'(_GEN_198[io_fromPipeline_2_bits_mBIndex] - 8'h1);
    latchWbValid <= io_fromPipeline_0_valid;
    latchWbValid_1 <= io_fromPipeline_1_valid;
    latchWbValid_2 <= io_fromPipeline_2_valid;
    pipewbValidReg_0_REG <= io_fromPipeline_0_valid;
    pipewbValidReg_1_REG <= io_fromPipeline_1_valid;
    pipewbValidReg_2_REG <= io_fromPipeline_2_valid;
  end // always @(posedge)
  wire               _GEN_322 = _GEN_130 | _GEN_73;
  wire               _GEN_323 = _GEN_132 | _GEN_75;
  wire               _GEN_324 = _GEN_134 | _GEN_77;
  wire               _GEN_325 = _GEN_136 | _GEN_79;
  wire               _GEN_326 = _GEN_138 | _GEN_81;
  wire               _GEN_327 = _GEN_140 | _GEN_83;
  wire               _GEN_328 = _GEN_142 | _GEN_85;
  wire               _GEN_329 = _GEN_144 | _GEN_87;
  wire               _GEN_330 = _GEN_146 | _GEN_89;
  wire               _GEN_331 = _GEN_148 | _GEN_91;
  wire               _GEN_332 = _GEN_150 | _GEN_93;
  wire               _GEN_333 = _GEN_152 | _GEN_95;
  wire               _GEN_334 = _GEN_154 | _GEN_97;
  wire               _GEN_335 = _GEN_156 | _GEN_99;
  wire               _GEN_336 = _GEN_158 | _GEN_101;
  wire               _GEN_337 = (&entryIdx_1) | _GEN_102;
  wire               _GEN_338 = _GEN_16 ? _GEN_18 | allocated[0] : _GEN_0 | allocated[0];
  wire               _GEN_339 = _GEN_16 ? _GEN_20 | allocated[1] : _GEN_1 | allocated[1];
  wire               _GEN_340 = _GEN_16 ? _GEN_22 | allocated[2] : _GEN_2 | allocated[2];
  wire               _GEN_341 = _GEN_16 ? _GEN_24 | allocated[3] : _GEN_3 | allocated[3];
  wire               _GEN_342 = _GEN_16 ? _GEN_26 | allocated[4] : _GEN_4 | allocated[4];
  wire               _GEN_343 = _GEN_16 ? _GEN_28 | allocated[5] : _GEN_5 | allocated[5];
  wire               _GEN_344 = _GEN_16 ? _GEN_30 | allocated[6] : _GEN_6 | allocated[6];
  wire               _GEN_345 = _GEN_16 ? _GEN_32 | allocated[7] : _GEN_7 | allocated[7];
  wire               _GEN_346 = _GEN_16 ? _GEN_34 | allocated[8] : _GEN_8 | allocated[8];
  wire               _GEN_347 = _GEN_16 ? _GEN_36 | allocated[9] : _GEN_9 | allocated[9];
  wire               _GEN_348 = _GEN_16 ? _GEN_38 | allocated[10] : _GEN_10 | allocated[10];
  wire               _GEN_349 = _GEN_16 ? _GEN_40 | allocated[11] : _GEN_11 | allocated[11];
  wire               _GEN_350 = _GEN_16 ? _GEN_42 | allocated[12] : _GEN_12 | allocated[12];
  wire               _GEN_351 = _GEN_16 ? _GEN_44 | allocated[13] : _GEN_13 | allocated[13];
  wire               _GEN_352 = _GEN_16 ? _GEN_46 | allocated[14] : _GEN_14 | allocated[14];
  wire               _GEN_353 = _GEN_16 ? _GEN_47 | allocated[15] : _GEN_15 | allocated[15];
  wire               _GEN_354 =
    _GEN_16 ? ~_GEN_18 & needRSReplay[0] : ~_GEN_0 & needRSReplay[0];
  wire               _GEN_355 =
    _GEN_16 ? ~_GEN_20 & needRSReplay[1] : ~_GEN_1 & needRSReplay[1];
  wire               _GEN_356 =
    _GEN_16 ? ~_GEN_22 & needRSReplay[2] : ~_GEN_2 & needRSReplay[2];
  wire               _GEN_357 =
    _GEN_16 ? ~_GEN_24 & needRSReplay[3] : ~_GEN_3 & needRSReplay[3];
  wire               _GEN_358 =
    _GEN_16 ? ~_GEN_26 & needRSReplay[4] : ~_GEN_4 & needRSReplay[4];
  wire               _GEN_359 =
    _GEN_16 ? ~_GEN_28 & needRSReplay[5] : ~_GEN_5 & needRSReplay[5];
  wire               _GEN_360 =
    _GEN_16 ? ~_GEN_30 & needRSReplay[6] : ~_GEN_6 & needRSReplay[6];
  wire               _GEN_361 =
    _GEN_16 ? ~_GEN_32 & needRSReplay[7] : ~_GEN_7 & needRSReplay[7];
  wire               _GEN_362 =
    _GEN_16 ? ~_GEN_34 & needRSReplay[8] : ~_GEN_8 & needRSReplay[8];
  wire               _GEN_363 =
    _GEN_16 ? ~_GEN_36 & needRSReplay[9] : ~_GEN_9 & needRSReplay[9];
  wire               _GEN_364 =
    _GEN_16 ? ~_GEN_38 & needRSReplay[10] : ~_GEN_10 & needRSReplay[10];
  wire               _GEN_365 =
    _GEN_16 ? ~_GEN_40 & needRSReplay[11] : ~_GEN_11 & needRSReplay[11];
  wire               _GEN_366 =
    _GEN_16 ? ~_GEN_42 & needRSReplay[12] : ~_GEN_12 & needRSReplay[12];
  wire               _GEN_367 =
    _GEN_16 ? ~_GEN_44 & needRSReplay[13] : ~_GEN_13 & needRSReplay[13];
  wire               _GEN_368 =
    _GEN_16 ? ~_GEN_46 & needRSReplay[14] : ~_GEN_14 & needRSReplay[14];
  wire               _GEN_369 =
    _GEN_16 ? ~_GEN_47 & needRSReplay[15] : ~_GEN_15 & needRSReplay[15];
  wire               _GEN_370 =
    allocated[0] & entries[0].flowNum == 5'h0 & ~needCancel_0 | ~needCancel_0
    & (_GEN_16 ? ~_GEN_18 & uopFinish[0] : ~_GEN_0 & uopFinish[0]);
  wire               _GEN_371 =
    allocated[1] & entries[1].flowNum == 5'h0 & ~needCancel_1 | ~needCancel_1
    & (_GEN_16 ? ~_GEN_20 & uopFinish[1] : ~_GEN_1 & uopFinish[1]);
  wire               _GEN_372 =
    allocated[2] & entries[2].flowNum == 5'h0 & ~needCancel_2 | ~needCancel_2
    & (_GEN_16 ? ~_GEN_22 & uopFinish[2] : ~_GEN_2 & uopFinish[2]);
  wire               _GEN_373 =
    allocated[3] & entries[3].flowNum == 5'h0 & ~needCancel_3 | ~needCancel_3
    & (_GEN_16 ? ~_GEN_24 & uopFinish[3] : ~_GEN_3 & uopFinish[3]);
  wire               _GEN_374 =
    allocated[4] & entries[4].flowNum == 5'h0 & ~needCancel_4 | ~needCancel_4
    & (_GEN_16 ? ~_GEN_26 & uopFinish[4] : ~_GEN_4 & uopFinish[4]);
  wire               _GEN_375 =
    allocated[5] & entries[5].flowNum == 5'h0 & ~needCancel_5 | ~needCancel_5
    & (_GEN_16 ? ~_GEN_28 & uopFinish[5] : ~_GEN_5 & uopFinish[5]);
  wire               _GEN_376 =
    allocated[6] & entries[6].flowNum == 5'h0 & ~needCancel_6 | ~needCancel_6
    & (_GEN_16 ? ~_GEN_30 & uopFinish[6] : ~_GEN_6 & uopFinish[6]);
  wire               _GEN_377 =
    allocated[7] & entries[7].flowNum == 5'h0 & ~needCancel_7 | ~needCancel_7
    & (_GEN_16 ? ~_GEN_32 & uopFinish[7] : ~_GEN_7 & uopFinish[7]);
  wire               _GEN_378 =
    allocated[8] & entries[8].flowNum == 5'h0 & ~needCancel_8 | ~needCancel_8
    & (_GEN_16 ? ~_GEN_34 & uopFinish[8] : ~_GEN_8 & uopFinish[8]);
  wire               _GEN_379 =
    allocated[9] & entries[9].flowNum == 5'h0 & ~needCancel_9 | ~needCancel_9
    & (_GEN_16 ? ~_GEN_36 & uopFinish[9] : ~_GEN_9 & uopFinish[9]);
  wire               _GEN_380 =
    allocated[10] & entries[10].flowNum == 5'h0 & ~needCancel_10 | ~needCancel_10
    & (_GEN_16 ? ~_GEN_38 & uopFinish[10] : ~_GEN_10 & uopFinish[10]);
  wire               _GEN_381 =
    allocated[11] & entries[11].flowNum == 5'h0 & ~needCancel_11 | ~needCancel_11
    & (_GEN_16 ? ~_GEN_40 & uopFinish[11] : ~_GEN_11 & uopFinish[11]);
  wire               _GEN_382 =
    allocated[12] & entries[12].flowNum == 5'h0 & ~needCancel_12 | ~needCancel_12
    & (_GEN_16 ? ~_GEN_42 & uopFinish[12] : ~_GEN_12 & uopFinish[12]);
  wire               _GEN_383 =
    allocated[13] & entries[13].flowNum == 5'h0 & ~needCancel_13 | ~needCancel_13
    & (_GEN_16 ? ~_GEN_44 & uopFinish[13] : ~_GEN_13 & uopFinish[13]);
  wire               _GEN_384 =
    allocated[14] & entries[14].flowNum == 5'h0 & ~needCancel_14 | ~needCancel_14
    & (_GEN_16 ? ~_GEN_46 & uopFinish[14] : ~_GEN_14 & uopFinish[14]);
  wire               _GEN_385 =
    allocated[15] & entries[15].flowNum == 5'h0 & ~needCancel_15 | ~needCancel_15
    & (_GEN_16 ? ~_GEN_47 & uopFinish[15] : ~_GEN_15 & uopFinish[15]);
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      allocated[0] <= 1'h0;
      allocated[1] <= 1'h0;
      allocated[2] <= 1'h0;
      allocated[3] <= 1'h0;
      allocated[4] <= 1'h0;
      allocated[5] <= 1'h0;
      allocated[6] <= 1'h0;
      allocated[7] <= 1'h0;
      allocated[8] <= 1'h0;
      allocated[9] <= 1'h0;
      allocated[10] <= 1'h0;
      allocated[11] <= 1'h0;
      allocated[12] <= 1'h0;
      allocated[13] <= 1'h0;
      allocated[14] <= 1'h0;
      allocated[15] <= 1'h0;
      uopFinish[0] <= 1'h0;
      uopFinish[1] <= 1'h0;
      uopFinish[2] <= 1'h0;
      uopFinish[3] <= 1'h0;
      uopFinish[4] <= 1'h0;
      uopFinish[5] <= 1'h0;
      uopFinish[6] <= 1'h0;
      uopFinish[7] <= 1'h0;
      uopFinish[8] <= 1'h0;
      uopFinish[9] <= 1'h0;
      uopFinish[10] <= 1'h0;
      uopFinish[11] <= 1'h0;
      uopFinish[12] <= 1'h0;
      uopFinish[13] <= 1'h0;
      uopFinish[14] <= 1'h0;
      uopFinish[15] <= 1'h0;
      needRSReplay[0] <= 1'h0;
      needRSReplay[1] <= 1'h0;
      needRSReplay[2] <= 1'h0;
      needRSReplay[3] <= 1'h0;
      needRSReplay[4] <= 1'h0;
      needRSReplay[5] <= 1'h0;
      needRSReplay[6] <= 1'h0;
      needRSReplay[7] <= 1'h0;
      needRSReplay[8] <= 1'h0;
      needRSReplay[9] <= 1'h0;
      needRSReplay[10] <= 1'h0;
      needRSReplay[11] <= 1'h0;
      needRSReplay[12] <= 1'h0;
      needRSReplay[13] <= 1'h0;
      needRSReplay[14] <= 1'h0;
      needRSReplay[15] <= 1'h0;
    end
    else begin
      allocated[0] <=
        ~_GEN_131
        & (selFire ? ~(_GEN_72 | needCancel_0) & _GEN_338 : ~needCancel_0 & _GEN_338);
      allocated[1] <=
        ~_GEN_133
        & (selFire ? ~(_GEN_74 | needCancel_1) & _GEN_339 : ~needCancel_1 & _GEN_339);
      allocated[2] <=
        ~_GEN_135
        & (selFire ? ~(_GEN_76 | needCancel_2) & _GEN_340 : ~needCancel_2 & _GEN_340);
      allocated[3] <=
        ~_GEN_137
        & (selFire ? ~(_GEN_78 | needCancel_3) & _GEN_341 : ~needCancel_3 & _GEN_341);
      allocated[4] <=
        ~_GEN_139
        & (selFire ? ~(_GEN_80 | needCancel_4) & _GEN_342 : ~needCancel_4 & _GEN_342);
      allocated[5] <=
        ~_GEN_141
        & (selFire ? ~(_GEN_82 | needCancel_5) & _GEN_343 : ~needCancel_5 & _GEN_343);
      allocated[6] <=
        ~_GEN_143
        & (selFire ? ~(_GEN_84 | needCancel_6) & _GEN_344 : ~needCancel_6 & _GEN_344);
      allocated[7] <=
        ~_GEN_145
        & (selFire ? ~(_GEN_86 | needCancel_7) & _GEN_345 : ~needCancel_7 & _GEN_345);
      allocated[8] <=
        ~_GEN_147
        & (selFire ? ~(_GEN_88 | needCancel_8) & _GEN_346 : ~needCancel_8 & _GEN_346);
      allocated[9] <=
        ~_GEN_149
        & (selFire ? ~(_GEN_90 | needCancel_9) & _GEN_347 : ~needCancel_9 & _GEN_347);
      allocated[10] <=
        ~_GEN_151
        & (selFire ? ~(_GEN_92 | needCancel_10) & _GEN_348 : ~needCancel_10 & _GEN_348);
      allocated[11] <=
        ~_GEN_153
        & (selFire ? ~(_GEN_94 | needCancel_11) & _GEN_349 : ~needCancel_11 & _GEN_349);
      allocated[12] <=
        ~_GEN_155
        & (selFire ? ~(_GEN_96 | needCancel_12) & _GEN_350 : ~needCancel_12 & _GEN_350);
      allocated[13] <=
        ~_GEN_157
        & (selFire ? ~(_GEN_98 | needCancel_13) & _GEN_351 : ~needCancel_13 & _GEN_351);
      allocated[14] <=
        ~_GEN_159
        & (selFire ? ~(_GEN_100 | needCancel_14) & _GEN_352 : ~needCancel_14 & _GEN_352);
      allocated[15] <=
        ~_GEN_160
        & (selFire
             ? ~((&entryIdx) | needCancel_15) & _GEN_353
             : ~needCancel_15 & _GEN_353);
      if (selFire_1) begin
        uopFinish[0] <= ~_GEN_322 & _GEN_370;
        uopFinish[1] <= ~_GEN_323 & _GEN_371;
        uopFinish[2] <= ~_GEN_324 & _GEN_372;
        uopFinish[3] <= ~_GEN_325 & _GEN_373;
        uopFinish[4] <= ~_GEN_326 & _GEN_374;
        uopFinish[5] <= ~_GEN_327 & _GEN_375;
        uopFinish[6] <= ~_GEN_328 & _GEN_376;
        uopFinish[7] <= ~_GEN_329 & _GEN_377;
        uopFinish[8] <= ~_GEN_330 & _GEN_378;
        uopFinish[9] <= ~_GEN_331 & _GEN_379;
        uopFinish[10] <= ~_GEN_332 & _GEN_380;
        uopFinish[11] <= ~_GEN_333 & _GEN_381;
        uopFinish[12] <= ~_GEN_334 & _GEN_382;
        uopFinish[13] <= ~_GEN_335 & _GEN_383;
        uopFinish[14] <= ~_GEN_336 & _GEN_384;
        uopFinish[15] <= ~_GEN_337 & _GEN_385;
        needRSReplay[0] <= ~(_GEN_322 | needCancel_0) & _GEN_354;
        needRSReplay[1] <= ~(_GEN_323 | needCancel_1) & _GEN_355;
        needRSReplay[2] <= ~(_GEN_324 | needCancel_2) & _GEN_356;
        needRSReplay[3] <= ~(_GEN_325 | needCancel_3) & _GEN_357;
        needRSReplay[4] <= ~(_GEN_326 | needCancel_4) & _GEN_358;
        needRSReplay[5] <= ~(_GEN_327 | needCancel_5) & _GEN_359;
        needRSReplay[6] <= ~(_GEN_328 | needCancel_6) & _GEN_360;
        needRSReplay[7] <= ~(_GEN_329 | needCancel_7) & _GEN_361;
        needRSReplay[8] <= ~(_GEN_330 | needCancel_8) & _GEN_362;
        needRSReplay[9] <= ~(_GEN_331 | needCancel_9) & _GEN_363;
        needRSReplay[10] <= ~(_GEN_332 | needCancel_10) & _GEN_364;
        needRSReplay[11] <= ~(_GEN_333 | needCancel_11) & _GEN_365;
        needRSReplay[12] <= ~(_GEN_334 | needCancel_12) & _GEN_366;
        needRSReplay[13] <= ~(_GEN_335 | needCancel_13) & _GEN_367;
        needRSReplay[14] <= ~(_GEN_336 | needCancel_14) & _GEN_368;
        needRSReplay[15] <= ~(_GEN_337 | needCancel_15) & _GEN_369;
      end
      else begin
        uopFinish[0] <= ~_GEN_73 & _GEN_370;
        uopFinish[1] <= ~_GEN_75 & _GEN_371;
        uopFinish[2] <= ~_GEN_77 & _GEN_372;
        uopFinish[3] <= ~_GEN_79 & _GEN_373;
        uopFinish[4] <= ~_GEN_81 & _GEN_374;
        uopFinish[5] <= ~_GEN_83 & _GEN_375;
        uopFinish[6] <= ~_GEN_85 & _GEN_376;
        uopFinish[7] <= ~_GEN_87 & _GEN_377;
        uopFinish[8] <= ~_GEN_89 & _GEN_378;
        uopFinish[9] <= ~_GEN_91 & _GEN_379;
        uopFinish[10] <= ~_GEN_93 & _GEN_380;
        uopFinish[11] <= ~_GEN_95 & _GEN_381;
        uopFinish[12] <= ~_GEN_97 & _GEN_382;
        uopFinish[13] <= ~_GEN_99 & _GEN_383;
        uopFinish[14] <= ~_GEN_101 & _GEN_384;
        uopFinish[15] <= ~_GEN_102 & _GEN_385;
        needRSReplay[0] <= ~(_GEN_73 | needCancel_0) & _GEN_354;
        needRSReplay[1] <= ~(_GEN_75 | needCancel_1) & _GEN_355;
        needRSReplay[2] <= ~(_GEN_77 | needCancel_2) & _GEN_356;
        needRSReplay[3] <= ~(_GEN_79 | needCancel_3) & _GEN_357;
        needRSReplay[4] <= ~(_GEN_81 | needCancel_4) & _GEN_358;
        needRSReplay[5] <= ~(_GEN_83 | needCancel_5) & _GEN_359;
        needRSReplay[6] <= ~(_GEN_85 | needCancel_6) & _GEN_360;
        needRSReplay[7] <= ~(_GEN_87 | needCancel_7) & _GEN_361;
        needRSReplay[8] <= ~(_GEN_89 | needCancel_8) & _GEN_362;
        needRSReplay[9] <= ~(_GEN_91 | needCancel_9) & _GEN_363;
        needRSReplay[10] <= ~(_GEN_93 | needCancel_10) & _GEN_364;
        needRSReplay[11] <= ~(_GEN_95 | needCancel_11) & _GEN_365;
        needRSReplay[12] <= ~(_GEN_97 | needCancel_12) & _GEN_366;
        needRSReplay[13] <= ~(_GEN_99 | needCancel_13) & _GEN_367;
        needRSReplay[14] <= ~(_GEN_101 | needCancel_14) & _GEN_368;
        needRSReplay[15] <= ~(_GEN_102 | needCancel_15) & _GEN_369;
      end
    end
  end // always @(posedge, posedge)
  FreeList freeCount_freeList (
    .clock             (clock),
    .reset             (reset),
    .io_allocateSlot_0 (_freeCount_freeList_io_allocateSlot_0),
    .io_allocateSlot_1 (_freeCount_freeList_io_allocateSlot_1),
    .io_doAllocate_0   (_GEN),
    .io_doAllocate_1   (_GEN_16),
    .io_free
      ({freeMaskVec_15,
        freeMaskVec_14,
        freeMaskVec_13,
        freeMaskVec_12,
        freeMaskVec_11,
        freeMaskVec_10,
        freeMaskVec_9,
        freeMaskVec_8,
        freeMaskVec_7,
        freeMaskVec_6,
        freeMaskVec_5,
        freeMaskVec_4,
        freeMaskVec_3,
        freeMaskVec_2,
        freeMaskVec_1,
        freeMaskVec_0}),
    .io_validCount     (_freeCount_freeList_io_validCount),
    .io_empty          (_probe)
  );
  wire [4:0]         _probe_0;
  assign _probe_0 = _freeCount_freeList_io_validCount;
  NewPipelineConnectPipe_27 VMergebufferPipelineConnect0 (
    .clock                                (clock),
    .reset                                (reset),
    .io_in_ready                          (_VMergebufferPipelineConnect0_io_in_ready),
    .io_in_valid                          (pipelineOut_0_valid),
    .io_in_bits_uop_exceptionVec_3        (_GEN_50[entryIdx]),
    .io_in_bits_uop_exceptionVec_4        (_GEN_51[entryIdx]),
    .io_in_bits_uop_exceptionVec_5        (_GEN_52[entryIdx]),
    .io_in_bits_uop_exceptionVec_6        (1'h0),
    .io_in_bits_uop_exceptionVec_7        (1'h0),
    .io_in_bits_uop_exceptionVec_13       (_GEN_53[entryIdx]),
    .io_in_bits_uop_exceptionVec_15       (1'h0),
    .io_in_bits_uop_exceptionVec_19       (_GEN_54[entryIdx]),
    .io_in_bits_uop_exceptionVec_21       (_GEN_55[entryIdx]),
    .io_in_bits_uop_exceptionVec_23       (1'h0),
    .io_in_bits_uop_trigger               (_GEN_56[entryIdx]),
    .io_in_bits_uop_fuOpType              (_GEN_57[entryIdx]),
    .io_in_bits_uop_vecWen                (_GEN_104[entryIdx]),
    .io_in_bits_uop_v0Wen                 (_GEN_105[entryIdx]),
    .io_in_bits_uop_vlWen                 (_GEN_106[entryIdx]),
    .io_in_bits_uop_flushPipe             (_GEN_107[entryIdx]),
    .io_in_bits_uop_vpu_vma               (_GEN_108[entryIdx]),
    .io_in_bits_uop_vpu_vta               (_GEN_109[entryIdx]),
    .io_in_bits_uop_vpu_vsew              (_GEN_110[entryIdx]),
    .io_in_bits_uop_vpu_vlmul             (_GEN_111[entryIdx]),
    .io_in_bits_uop_vpu_vm                (_GEN_112[entryIdx]),
    .io_in_bits_uop_vpu_vstart            (_GEN_125[entryIdx]),
    .io_in_bits_uop_vpu_vuopIdx           (_GEN_113[entryIdx]),
    .io_in_bits_uop_vpu_vmask             ({112'h0, _GEN_49[entryIdx]}),
    .io_in_bits_uop_vpu_vl                (_GEN_58[entryIdx]),
    .io_in_bits_uop_vpu_nf                (_GEN_114[entryIdx]),
    .io_in_bits_uop_vpu_veew              (_GEN_115[entryIdx]),
    .io_in_bits_uop_pdest                 (_GEN_117[entryIdx]),
    .io_in_bits_uop_robIdx_flag           (_GEN_118[entryIdx]),
    .io_in_bits_uop_robIdx_value          (_GEN_119[entryIdx]),
    .io_in_bits_uop_debugInfo_enqRsTime   (_GEN_120[entryIdx]),
    .io_in_bits_uop_debugInfo_selectTime  (_GEN_121[entryIdx]),
    .io_in_bits_uop_debugInfo_issueTime   (_GEN_122[entryIdx]),
    .io_in_bits_uop_replayInst            (_GEN_123[entryIdx]),
    .io_in_bits_data                      (_GEN_48[entryIdx]),
    .io_in_bits_vdIdx                     (_GEN_124[entryIdx]),
    .io_in_bits_vdIdxInField              (_GEN_124[entryIdx]),
    .io_out_ready                         (io_uopWriteback_0_ready),
    .io_out_valid                         (_VMergebufferPipelineConnect0_io_out_valid),
    .io_out_bits_uop_exceptionVec_3       (io_uopWriteback_0_bits_uop_exceptionVec_3),
    .io_out_bits_uop_exceptionVec_4       (io_uopWriteback_0_bits_uop_exceptionVec_4),
    .io_out_bits_uop_exceptionVec_5       (io_uopWriteback_0_bits_uop_exceptionVec_5),
    .io_out_bits_uop_exceptionVec_6       (/* unused */),
    .io_out_bits_uop_exceptionVec_7       (/* unused */),
    .io_out_bits_uop_exceptionVec_13      (io_uopWriteback_0_bits_uop_exceptionVec_13),
    .io_out_bits_uop_exceptionVec_15      (/* unused */),
    .io_out_bits_uop_exceptionVec_19      (io_uopWriteback_0_bits_uop_exceptionVec_19),
    .io_out_bits_uop_exceptionVec_21      (io_uopWriteback_0_bits_uop_exceptionVec_21),
    .io_out_bits_uop_exceptionVec_23      (/* unused */),
    .io_out_bits_uop_trigger              (io_uopWriteback_0_bits_uop_trigger),
    .io_out_bits_uop_fuOpType             (io_uopWriteback_0_bits_uop_fuOpType),
    .io_out_bits_uop_vecWen               (io_uopWriteback_0_bits_uop_vecWen),
    .io_out_bits_uop_v0Wen                (io_uopWriteback_0_bits_uop_v0Wen),
    .io_out_bits_uop_vlWen                (io_uopWriteback_0_bits_uop_vlWen),
    .io_out_bits_uop_flushPipe            (io_uopWriteback_0_bits_uop_flushPipe),
    .io_out_bits_uop_vpu_vma              (io_uopWriteback_0_bits_uop_vpu_vma),
    .io_out_bits_uop_vpu_vta              (io_uopWriteback_0_bits_uop_vpu_vta),
    .io_out_bits_uop_vpu_vsew             (io_uopWriteback_0_bits_uop_vpu_vsew),
    .io_out_bits_uop_vpu_vlmul            (io_uopWriteback_0_bits_uop_vpu_vlmul),
    .io_out_bits_uop_vpu_vm               (io_uopWriteback_0_bits_uop_vpu_vm),
    .io_out_bits_uop_vpu_vstart           (io_uopWriteback_0_bits_uop_vpu_vstart),
    .io_out_bits_uop_vpu_vuopIdx          (io_uopWriteback_0_bits_uop_vpu_vuopIdx),
    .io_out_bits_uop_vpu_vmask            (io_uopWriteback_0_bits_uop_vpu_vmask),
    .io_out_bits_uop_vpu_vl               (io_uopWriteback_0_bits_uop_vpu_vl),
    .io_out_bits_uop_vpu_nf               (io_uopWriteback_0_bits_uop_vpu_nf),
    .io_out_bits_uop_vpu_veew             (io_uopWriteback_0_bits_uop_vpu_veew),
    .io_out_bits_uop_pdest                (io_uopWriteback_0_bits_uop_pdest),
    .io_out_bits_uop_robIdx_flag
      (_VMergebufferPipelineConnect0_io_out_bits_uop_robIdx_flag),
    .io_out_bits_uop_robIdx_value
      (_VMergebufferPipelineConnect0_io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_debugInfo_enqRsTime
      (io_uopWriteback_0_bits_uop_debugInfo_enqRsTime),
    .io_out_bits_uop_debugInfo_selectTime
      (io_uopWriteback_0_bits_uop_debugInfo_selectTime),
    .io_out_bits_uop_debugInfo_issueTime
      (io_uopWriteback_0_bits_uop_debugInfo_issueTime),
    .io_out_bits_uop_replayInst           (io_uopWriteback_0_bits_uop_replayInst),
    .io_out_bits_data                     (io_uopWriteback_0_bits_data),
    .io_out_bits_vdIdx                    (io_uopWriteback_0_bits_vdIdx),
    .io_out_bits_vdIdxInField             (io_uopWriteback_0_bits_vdIdxInField),
    .io_rightOutFire
      (io_uopWriteback_0_ready & _VMergebufferPipelineConnect0_io_out_valid),
    .io_isFlush
      (_VMergebufferPipelineConnect0_io_in_ready & pipelineOut_0_valid
         ? io_redirect_valid
           & (io_redirect_bits_level & _flushItself_T_1 == _flushItself_T_14
              | differentFlag ^ compare)
         : io_redirect_valid
           & (io_redirect_bits_level
              & {_VMergebufferPipelineConnect0_io_out_bits_uop_robIdx_flag,
                 _VMergebufferPipelineConnect0_io_out_bits_uop_robIdx_value} == _flushItself_T_14
              | _VMergebufferPipelineConnect0_io_out_bits_uop_robIdx_flag
              ^ io_redirect_bits_robIdx_flag
              ^ _VMergebufferPipelineConnect0_io_out_bits_uop_robIdx_value > io_redirect_bits_robIdx_value))
  );
  NewPipelineConnectPipe_27 VMergebufferPipelineConnect1 (
    .clock                                (clock),
    .reset                                (reset),
    .io_in_ready                          (_VMergebufferPipelineConnect1_io_in_ready),
    .io_in_valid                          (pipelineOut_1_valid),
    .io_in_bits_uop_exceptionVec_3        (_GEN_50[entryIdx_1]),
    .io_in_bits_uop_exceptionVec_4        (_GEN_51[entryIdx_1]),
    .io_in_bits_uop_exceptionVec_5        (_GEN_52[entryIdx_1]),
    .io_in_bits_uop_exceptionVec_6        (1'h0),
    .io_in_bits_uop_exceptionVec_7        (1'h0),
    .io_in_bits_uop_exceptionVec_13       (_GEN_53[entryIdx_1]),
    .io_in_bits_uop_exceptionVec_15       (1'h0),
    .io_in_bits_uop_exceptionVec_19       (_GEN_54[entryIdx_1]),
    .io_in_bits_uop_exceptionVec_21       (_GEN_55[entryIdx_1]),
    .io_in_bits_uop_exceptionVec_23       (1'h0),
    .io_in_bits_uop_trigger               (_GEN_56[entryIdx_1]),
    .io_in_bits_uop_fuOpType              (_GEN_57[entryIdx_1]),
    .io_in_bits_uop_vecWen                (_GEN_104[entryIdx_1]),
    .io_in_bits_uop_v0Wen                 (_GEN_105[entryIdx_1]),
    .io_in_bits_uop_vlWen                 (_GEN_106[entryIdx_1]),
    .io_in_bits_uop_flushPipe             (_GEN_107[entryIdx_1]),
    .io_in_bits_uop_vpu_vma               (_GEN_108[entryIdx_1]),
    .io_in_bits_uop_vpu_vta               (_GEN_109[entryIdx_1]),
    .io_in_bits_uop_vpu_vsew              (_GEN_110[entryIdx_1]),
    .io_in_bits_uop_vpu_vlmul             (_GEN_111[entryIdx_1]),
    .io_in_bits_uop_vpu_vm                (_GEN_112[entryIdx_1]),
    .io_in_bits_uop_vpu_vstart            (_GEN_125[entryIdx_1]),
    .io_in_bits_uop_vpu_vuopIdx           (_GEN_113[entryIdx_1]),
    .io_in_bits_uop_vpu_vmask             ({112'h0, _GEN_49[entryIdx_1]}),
    .io_in_bits_uop_vpu_vl                (_GEN_58[entryIdx_1]),
    .io_in_bits_uop_vpu_nf                (_GEN_114[entryIdx_1]),
    .io_in_bits_uop_vpu_veew              (_GEN_115[entryIdx_1]),
    .io_in_bits_uop_pdest                 (_GEN_117[entryIdx_1]),
    .io_in_bits_uop_robIdx_flag           (_GEN_118[entryIdx_1]),
    .io_in_bits_uop_robIdx_value          (_GEN_119[entryIdx_1]),
    .io_in_bits_uop_debugInfo_enqRsTime   (_GEN_120[entryIdx_1]),
    .io_in_bits_uop_debugInfo_selectTime  (_GEN_121[entryIdx_1]),
    .io_in_bits_uop_debugInfo_issueTime   (_GEN_122[entryIdx_1]),
    .io_in_bits_uop_replayInst            (_GEN_123[entryIdx_1]),
    .io_in_bits_data                      (_GEN_48[entryIdx_1]),
    .io_in_bits_vdIdx                     (_GEN_124[entryIdx_1]),
    .io_in_bits_vdIdxInField              (_GEN_124[entryIdx_1]),
    .io_out_ready                         (io_uopWriteback_1_ready),
    .io_out_valid                         (_VMergebufferPipelineConnect1_io_out_valid),
    .io_out_bits_uop_exceptionVec_3       (io_uopWriteback_1_bits_uop_exceptionVec_3),
    .io_out_bits_uop_exceptionVec_4       (io_uopWriteback_1_bits_uop_exceptionVec_4),
    .io_out_bits_uop_exceptionVec_5       (io_uopWriteback_1_bits_uop_exceptionVec_5),
    .io_out_bits_uop_exceptionVec_6       (/* unused */),
    .io_out_bits_uop_exceptionVec_7       (/* unused */),
    .io_out_bits_uop_exceptionVec_13      (io_uopWriteback_1_bits_uop_exceptionVec_13),
    .io_out_bits_uop_exceptionVec_15      (/* unused */),
    .io_out_bits_uop_exceptionVec_19      (io_uopWriteback_1_bits_uop_exceptionVec_19),
    .io_out_bits_uop_exceptionVec_21      (io_uopWriteback_1_bits_uop_exceptionVec_21),
    .io_out_bits_uop_exceptionVec_23      (/* unused */),
    .io_out_bits_uop_trigger              (io_uopWriteback_1_bits_uop_trigger),
    .io_out_bits_uop_fuOpType             (io_uopWriteback_1_bits_uop_fuOpType),
    .io_out_bits_uop_vecWen               (io_uopWriteback_1_bits_uop_vecWen),
    .io_out_bits_uop_v0Wen                (io_uopWriteback_1_bits_uop_v0Wen),
    .io_out_bits_uop_vlWen                (io_uopWriteback_1_bits_uop_vlWen),
    .io_out_bits_uop_flushPipe            (io_uopWriteback_1_bits_uop_flushPipe),
    .io_out_bits_uop_vpu_vma              (io_uopWriteback_1_bits_uop_vpu_vma),
    .io_out_bits_uop_vpu_vta              (io_uopWriteback_1_bits_uop_vpu_vta),
    .io_out_bits_uop_vpu_vsew             (io_uopWriteback_1_bits_uop_vpu_vsew),
    .io_out_bits_uop_vpu_vlmul            (io_uopWriteback_1_bits_uop_vpu_vlmul),
    .io_out_bits_uop_vpu_vm               (io_uopWriteback_1_bits_uop_vpu_vm),
    .io_out_bits_uop_vpu_vstart           (io_uopWriteback_1_bits_uop_vpu_vstart),
    .io_out_bits_uop_vpu_vuopIdx          (io_uopWriteback_1_bits_uop_vpu_vuopIdx),
    .io_out_bits_uop_vpu_vmask            (io_uopWriteback_1_bits_uop_vpu_vmask),
    .io_out_bits_uop_vpu_vl               (io_uopWriteback_1_bits_uop_vpu_vl),
    .io_out_bits_uop_vpu_nf               (io_uopWriteback_1_bits_uop_vpu_nf),
    .io_out_bits_uop_vpu_veew             (io_uopWriteback_1_bits_uop_vpu_veew),
    .io_out_bits_uop_pdest                (io_uopWriteback_1_bits_uop_pdest),
    .io_out_bits_uop_robIdx_flag
      (_VMergebufferPipelineConnect1_io_out_bits_uop_robIdx_flag),
    .io_out_bits_uop_robIdx_value
      (_VMergebufferPipelineConnect1_io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_debugInfo_enqRsTime
      (io_uopWriteback_1_bits_uop_debugInfo_enqRsTime),
    .io_out_bits_uop_debugInfo_selectTime
      (io_uopWriteback_1_bits_uop_debugInfo_selectTime),
    .io_out_bits_uop_debugInfo_issueTime
      (io_uopWriteback_1_bits_uop_debugInfo_issueTime),
    .io_out_bits_uop_replayInst           (io_uopWriteback_1_bits_uop_replayInst),
    .io_out_bits_data                     (io_uopWriteback_1_bits_data),
    .io_out_bits_vdIdx                    (io_uopWriteback_1_bits_vdIdx),
    .io_out_bits_vdIdxInField             (io_uopWriteback_1_bits_vdIdxInField),
    .io_rightOutFire
      (io_uopWriteback_1_ready & _VMergebufferPipelineConnect1_io_out_valid),
    .io_isFlush
      (_VMergebufferPipelineConnect1_io_in_ready & pipelineOut_1_valid
         ? io_redirect_valid
           & (io_redirect_bits_level & _flushItself_T_9 == _flushItself_T_14
              | differentFlag_2 ^ compare_2)
         : io_redirect_valid
           & (io_redirect_bits_level
              & {_VMergebufferPipelineConnect1_io_out_bits_uop_robIdx_flag,
                 _VMergebufferPipelineConnect1_io_out_bits_uop_robIdx_value} == _flushItself_T_14
              | _VMergebufferPipelineConnect1_io_out_bits_uop_robIdx_flag
              ^ io_redirect_bits_robIdx_flag
              ^ _VMergebufferPipelineConnect1_io_out_bits_uop_robIdx_value > io_redirect_bits_robIdx_value))
  );
  assign io_fromSplit_0_req_ready = |_freeCount_T;
  assign io_fromSplit_0_resp_valid = |_freeCount_T;
  assign io_fromSplit_0_resp_bits_mBIndex = _freeCount_freeList_io_allocateSlot_0;
  assign io_fromSplit_1_req_ready = |(_freeCount_T[4:1]);
  assign io_fromSplit_1_resp_valid = |(_freeCount_T[4:1]);
  assign io_fromSplit_1_resp_bits_mBIndex = io_fromSplit_1_resp_bits_mBIndex_0;
  assign io_uopWriteback_0_valid = _VMergebufferPipelineConnect0_io_out_valid;
  assign io_uopWriteback_0_bits_uop_robIdx_flag =
    _VMergebufferPipelineConnect0_io_out_bits_uop_robIdx_flag;
  assign io_uopWriteback_0_bits_uop_robIdx_value =
    _VMergebufferPipelineConnect0_io_out_bits_uop_robIdx_value;
  assign io_uopWriteback_1_valid = _VMergebufferPipelineConnect1_io_out_valid;
  assign io_uopWriteback_1_bits_uop_robIdx_flag =
    _VMergebufferPipelineConnect1_io_out_bits_uop_robIdx_flag;
  assign io_uopWriteback_1_bits_uop_robIdx_value =
    _VMergebufferPipelineConnect1_io_out_bits_uop_robIdx_value;
  assign io_toSplit_threshold = _freeCount_T < 5'h7;
  assign io_toLsq_0_valid = feedbackValid & ~_GEN_103[entryIdx];
  assign io_toLsq_0_bits_robidx_flag = _GEN_118[entryIdx];
  assign io_toLsq_0_bits_robidx_value = _GEN_119[entryIdx];
  assign io_toLsq_0_bits_uopidx = _GEN_116[entryIdx];
  assign io_toLsq_0_bits_vaddr = _GEN_127[entryIdx];
  assign io_toLsq_0_bits_vaNeedExt = _GEN_126[entryIdx];
  assign io_toLsq_0_bits_gpaddr = _GEN_128[entryIdx];
  assign io_toLsq_0_bits_feedback_0 = |_GEN_129;
  assign io_toLsq_0_bits_feedback_1 = ~(|_GEN_129);
  assign io_toLsq_0_bits_exceptionVec_3 = _GEN_50[entryIdx];
  assign io_toLsq_0_bits_exceptionVec_4 = _GEN_51[entryIdx];
  assign io_toLsq_0_bits_exceptionVec_5 = _GEN_52[entryIdx];
  assign io_toLsq_0_bits_exceptionVec_13 = _GEN_53[entryIdx];
  assign io_toLsq_0_bits_exceptionVec_19 = _GEN_54[entryIdx];
  assign io_toLsq_0_bits_exceptionVec_21 = _GEN_55[entryIdx];
  assign io_toLsq_1_valid = feedbackValid_1 & ~_GEN_103[entryIdx_1];
  assign io_toLsq_1_bits_robidx_flag = _GEN_118[entryIdx_1];
  assign io_toLsq_1_bits_robidx_value = _GEN_119[entryIdx_1];
  assign io_toLsq_1_bits_uopidx = _GEN_116[entryIdx_1];
  assign io_toLsq_1_bits_vaddr = _GEN_127[entryIdx_1];
  assign io_toLsq_1_bits_vaNeedExt = _GEN_126[entryIdx_1];
  assign io_toLsq_1_bits_gpaddr = _GEN_128[entryIdx_1];
  assign io_toLsq_1_bits_feedback_0 = |_GEN_161;
  assign io_toLsq_1_bits_feedback_1 = ~(|_GEN_161);
  assign io_toLsq_1_bits_exceptionVec_3 = _GEN_50[entryIdx_1];
  assign io_toLsq_1_bits_exceptionVec_4 = _GEN_51[entryIdx_1];
  assign io_toLsq_1_bits_exceptionVec_5 = _GEN_52[entryIdx_1];
  assign io_toLsq_1_bits_exceptionVec_13 = _GEN_53[entryIdx_1];
  assign io_toLsq_1_bits_exceptionVec_19 = _GEN_54[entryIdx_1];
  assign io_toLsq_1_bits_exceptionVec_21 = _GEN_55[entryIdx_1];
endmodule
