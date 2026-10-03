// =====================================================================
// VSSplitPipelineImp.sv —— 向量 store 的"拆分流水"（VSplitPipeline 家族的 store 变体薄文件）
// ---------------------------------------------------------------------
// 核 xs_VSplitPipeline_core 在 VLSplitPipelineImp.sv（机制讲解在那里），类型在 vlsu_pkg.sv。
// 本变体（IS_VSTORE=1）与 load 变体的差别：
//   · 特殊 unit-stride 操作码是 vs<nf>r（整寄存器 store，0x108）与 vsm（mask store，0x10B）；
//     store 没有 fault-only-first；
//   · 有序 indexed store 不需要"被合并缓冲点名才接收"那条限制（store 的顺序由 SQ 保证）；
//   · 交给合并缓冲的请求里没有 data / vdIdx / fof，但多带 uop.vpu.vmask；
//   · s1 入口寄存器组 s1_in_r_* 共 90 个字段（golden 现数；load 变体多 fof、vdIdxInField 两个）。
// 规模：243 个端口；寄存器 = 本文件生成段里的 s1_in_r_*（无复位）+ 核里的 s1_valid（异步复位）。
// =====================================================================

// BEGIN GENERATED(wrapper_VSSplitPipelineImp) —— scripts/gen_vsplit.py 生成，勿手改
module VSSplitPipelineImp
  import vlsu_pkg::*;
(
  input          clock,
  input          reset,
  input          io_redirect_valid,
  input          io_redirect_bits_robIdx_flag,
  input  [7:0]   io_redirect_bits_robIdx_value,
  input          io_redirect_bits_level,
  output         io_in_ready,
  input          io_in_valid,
  input  [49:0]  io_in_bits_uop_pc,
  input          io_in_bits_uop_ftqPtr_flag,
  input  [5:0]   io_in_bits_uop_ftqPtr_value,
  input  [3:0]   io_in_bits_uop_ftqOffset,
  input  [34:0]  io_in_bits_uop_fuType,
  input  [8:0]   io_in_bits_uop_fuOpType,
  input          io_in_bits_uop_vecWen,
  input          io_in_bits_uop_v0Wen,
  input          io_in_bits_uop_vlWen,
  input          io_in_bits_uop_vpu_vill,
  input          io_in_bits_uop_vpu_vma,
  input          io_in_bits_uop_vpu_vta,
  input  [1:0]   io_in_bits_uop_vpu_vsew,
  input  [2:0]   io_in_bits_uop_vpu_vlmul,
  input          io_in_bits_uop_vpu_specVill,
  input          io_in_bits_uop_vpu_specVma,
  input          io_in_bits_uop_vpu_specVta,
  input  [1:0]   io_in_bits_uop_vpu_specVsew,
  input  [2:0]   io_in_bits_uop_vpu_specVlmul,
  input          io_in_bits_uop_vpu_vm,
  input  [7:0]   io_in_bits_uop_vpu_vstart,
  input  [2:0]   io_in_bits_uop_vpu_frm,
  input          io_in_bits_uop_vpu_fpu_isFpToVecInst,
  input          io_in_bits_uop_vpu_fpu_isFP32Instr,
  input          io_in_bits_uop_vpu_fpu_isFP64Instr,
  input          io_in_bits_uop_vpu_fpu_isReduction,
  input          io_in_bits_uop_vpu_fpu_isFoldTo1_2,
  input          io_in_bits_uop_vpu_fpu_isFoldTo1_4,
  input          io_in_bits_uop_vpu_fpu_isFoldTo1_8,
  input  [1:0]   io_in_bits_uop_vpu_vxrm,
  input  [6:0]   io_in_bits_uop_vpu_vuopIdx,
  input          io_in_bits_uop_vpu_lastUop,
  input  [127:0] io_in_bits_uop_vpu_vmask,
  input  [2:0]   io_in_bits_uop_vpu_nf,
  input  [1:0]   io_in_bits_uop_vpu_veew,
  input          io_in_bits_uop_vpu_isReverse,
  input          io_in_bits_uop_vpu_isExt,
  input          io_in_bits_uop_vpu_isNarrow,
  input          io_in_bits_uop_vpu_isDstMask,
  input          io_in_bits_uop_vpu_isOpMask,
  input          io_in_bits_uop_vpu_isMove,
  input          io_in_bits_uop_vpu_isDependOldVd,
  input          io_in_bits_uop_vpu_isWritePartVd,
  input          io_in_bits_uop_vpu_isVleff,
  input  [7:0]   io_in_bits_uop_pdest,
  input          io_in_bits_uop_robIdx_flag,
  input  [7:0]   io_in_bits_uop_robIdx_value,
  input          io_in_bits_uop_debugInfo_eliminatedMove,
  input  [63:0]  io_in_bits_uop_debugInfo_renameTime,
  input  [63:0]  io_in_bits_uop_debugInfo_dispatchTime,
  input  [63:0]  io_in_bits_uop_debugInfo_enqRsTime,
  input  [63:0]  io_in_bits_uop_debugInfo_selectTime,
  input  [63:0]  io_in_bits_uop_debugInfo_issueTime,
  input  [63:0]  io_in_bits_uop_debugInfo_writebackTime,
  input  [63:0]  io_in_bits_uop_debugInfo_runahead_checkpoint_id,
  input  [63:0]  io_in_bits_uop_debugInfo_tlbFirstReqTime,
  input  [63:0]  io_in_bits_uop_debugInfo_tlbRespTime,
  input  [55:0]  io_in_bits_uop_debug_seqNum_seqNum,
  input  [7:0]   io_in_bits_uop_debug_seqNum_uopIdx,
  input          io_in_bits_uop_lqIdx_flag,
  input  [6:0]   io_in_bits_uop_lqIdx_value,
  input          io_in_bits_uop_sqIdx_flag,
  input  [5:0]   io_in_bits_uop_sqIdx_value,
  input  [4:0]   io_in_bits_uop_numLsElem,
  input  [127:0] io_in_bits_src_0,
  input  [127:0] io_in_bits_src_1,
  input  [127:0] io_in_bits_src_2,
  input  [127:0] io_in_bits_src_3,
  input  [127:0] io_in_bits_src_4,
  input  [4:0]   io_in_bits_flowNum,
  input          io_in_bits_isVecPartReplay,
  input  [15:0]  io_in_bits_vecReplayMask,
  input  [3:0]   io_in_bits_vecReplayMbIdx,
  input          io_toMergeBuffer_req_ready,
  output         io_toMergeBuffer_req_valid,
  output [15:0]  io_toMergeBuffer_req_bits_mask,
  output [49:0]  io_toMergeBuffer_req_bits_vaddr,
  output [4:0]   io_toMergeBuffer_req_bits_flowNum,
  output [8:0]   io_toMergeBuffer_req_bits_uop_fuOpType,
  output         io_toMergeBuffer_req_bits_uop_vecWen,
  output         io_toMergeBuffer_req_bits_uop_v0Wen,
  output         io_toMergeBuffer_req_bits_uop_vlWen,
  output         io_toMergeBuffer_req_bits_uop_vpu_vill,
  output         io_toMergeBuffer_req_bits_uop_vpu_vma,
  output         io_toMergeBuffer_req_bits_uop_vpu_vta,
  output [1:0]   io_toMergeBuffer_req_bits_uop_vpu_vsew,
  output [2:0]   io_toMergeBuffer_req_bits_uop_vpu_vlmul,
  output         io_toMergeBuffer_req_bits_uop_vpu_specVill,
  output         io_toMergeBuffer_req_bits_uop_vpu_specVma,
  output         io_toMergeBuffer_req_bits_uop_vpu_specVta,
  output [1:0]   io_toMergeBuffer_req_bits_uop_vpu_specVsew,
  output [2:0]   io_toMergeBuffer_req_bits_uop_vpu_specVlmul,
  output         io_toMergeBuffer_req_bits_uop_vpu_vm,
  output [2:0]   io_toMergeBuffer_req_bits_uop_vpu_frm,
  output         io_toMergeBuffer_req_bits_uop_vpu_fpu_isFpToVecInst,
  output         io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP32Instr,
  output         io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP64Instr,
  output         io_toMergeBuffer_req_bits_uop_vpu_fpu_isReduction,
  output         io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_2,
  output         io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_4,
  output         io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_8,
  output [1:0]   io_toMergeBuffer_req_bits_uop_vpu_vxrm,
  output [6:0]   io_toMergeBuffer_req_bits_uop_vpu_vuopIdx,
  output         io_toMergeBuffer_req_bits_uop_vpu_lastUop,
  output [127:0] io_toMergeBuffer_req_bits_uop_vpu_vmask,
  output [7:0]   io_toMergeBuffer_req_bits_uop_vpu_vl,
  output [2:0]   io_toMergeBuffer_req_bits_uop_vpu_nf,
  output [1:0]   io_toMergeBuffer_req_bits_uop_vpu_veew,
  output         io_toMergeBuffer_req_bits_uop_vpu_isReverse,
  output         io_toMergeBuffer_req_bits_uop_vpu_isExt,
  output         io_toMergeBuffer_req_bits_uop_vpu_isNarrow,
  output         io_toMergeBuffer_req_bits_uop_vpu_isDstMask,
  output         io_toMergeBuffer_req_bits_uop_vpu_isOpMask,
  output         io_toMergeBuffer_req_bits_uop_vpu_isMove,
  output         io_toMergeBuffer_req_bits_uop_vpu_isDependOldVd,
  output         io_toMergeBuffer_req_bits_uop_vpu_isWritePartVd,
  output         io_toMergeBuffer_req_bits_uop_vpu_isVleff,
  output [6:0]   io_toMergeBuffer_req_bits_uop_uopIdx,
  output [7:0]   io_toMergeBuffer_req_bits_uop_pdest,
  output         io_toMergeBuffer_req_bits_uop_robIdx_flag,
  output [7:0]   io_toMergeBuffer_req_bits_uop_robIdx_value,
  output         io_toMergeBuffer_req_bits_uop_debugInfo_eliminatedMove,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_renameTime,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_dispatchTime,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_selectTime,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_issueTime,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_writebackTime,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_runahead_checkpoint_id,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_tlbFirstReqTime,
  output [63:0]  io_toMergeBuffer_req_bits_uop_debugInfo_tlbRespTime,
  output [55:0]  io_toMergeBuffer_req_bits_uop_debug_seqNum_seqNum,
  output [7:0]   io_toMergeBuffer_req_bits_uop_debug_seqNum_uopIdx,
  output         io_toMergeBuffer_req_bits_uop_lqIdx_flag,
  output [6:0]   io_toMergeBuffer_req_bits_uop_lqIdx_value,
  output         io_toMergeBuffer_req_bits_uop_sqIdx_flag,
  output [5:0]   io_toMergeBuffer_req_bits_uop_sqIdx_value,
  output [7:0]   io_toMergeBuffer_req_bits_vlmax,
  input          io_toMergeBuffer_resp_valid,
  input  [3:0]   io_toMergeBuffer_resp_bits_mBIndex,
  input          io_out_ready,
  output         io_out_valid,
  output [15:0]  io_out_bits_flowMask,
  output [127:0] io_out_bits_data,
  output [63:0]  io_out_bits_baseAddr,
  output [63:0]  io_out_bits_uopAddr,
  output [127:0] io_out_bits_stride,
  output [4:0]   io_out_bits_flowNum,
  output [1:0]   io_out_bits_eew,
  output [2:0]   io_out_bits_sew,
  output [2:0]   io_out_bits_emul,
  output [2:0]   io_out_bits_lmul,
  output [2:0]   io_out_bits_instType,
  output [4:0]   io_out_bits_indexedSplitOffset,
  output [49:0]  io_out_bits_uop_pc,
  output         io_out_bits_uop_ftqPtr_flag,
  output [5:0]   io_out_bits_uop_ftqPtr_value,
  output [3:0]   io_out_bits_uop_ftqOffset,
  output [34:0]  io_out_bits_uop_fuType,
  output [8:0]   io_out_bits_uop_fuOpType,
  output         io_out_bits_uop_vecWen,
  output         io_out_bits_uop_v0Wen,
  output         io_out_bits_uop_vlWen,
  output         io_out_bits_uop_vpu_vill,
  output         io_out_bits_uop_vpu_vma,
  output         io_out_bits_uop_vpu_vta,
  output [1:0]   io_out_bits_uop_vpu_vsew,
  output [2:0]   io_out_bits_uop_vpu_vlmul,
  output         io_out_bits_uop_vpu_specVill,
  output         io_out_bits_uop_vpu_specVma,
  output         io_out_bits_uop_vpu_specVta,
  output [1:0]   io_out_bits_uop_vpu_specVsew,
  output [2:0]   io_out_bits_uop_vpu_specVlmul,
  output         io_out_bits_uop_vpu_vm,
  output [7:0]   io_out_bits_uop_vpu_vstart,
  output [2:0]   io_out_bits_uop_vpu_frm,
  output         io_out_bits_uop_vpu_fpu_isFpToVecInst,
  output         io_out_bits_uop_vpu_fpu_isFP32Instr,
  output         io_out_bits_uop_vpu_fpu_isFP64Instr,
  output         io_out_bits_uop_vpu_fpu_isReduction,
  output         io_out_bits_uop_vpu_fpu_isFoldTo1_2,
  output         io_out_bits_uop_vpu_fpu_isFoldTo1_4,
  output         io_out_bits_uop_vpu_fpu_isFoldTo1_8,
  output [1:0]   io_out_bits_uop_vpu_vxrm,
  output [6:0]   io_out_bits_uop_vpu_vuopIdx,
  output         io_out_bits_uop_vpu_lastUop,
  output [127:0] io_out_bits_uop_vpu_vmask,
  output [7:0]   io_out_bits_uop_vpu_vl,
  output [2:0]   io_out_bits_uop_vpu_nf,
  output [1:0]   io_out_bits_uop_vpu_veew,
  output         io_out_bits_uop_vpu_isReverse,
  output         io_out_bits_uop_vpu_isExt,
  output         io_out_bits_uop_vpu_isNarrow,
  output         io_out_bits_uop_vpu_isDstMask,
  output         io_out_bits_uop_vpu_isOpMask,
  output         io_out_bits_uop_vpu_isMove,
  output         io_out_bits_uop_vpu_isDependOldVd,
  output         io_out_bits_uop_vpu_isWritePartVd,
  output         io_out_bits_uop_vpu_isVleff,
  output [6:0]   io_out_bits_uop_uopIdx,
  output         io_out_bits_uop_lastUop,
  output [6:0]   io_out_bits_uop_numUops,
  output [7:0]   io_out_bits_uop_pdest,
  output         io_out_bits_uop_robIdx_flag,
  output [7:0]   io_out_bits_uop_robIdx_value,
  output         io_out_bits_uop_debugInfo_eliminatedMove,
  output [63:0]  io_out_bits_uop_debugInfo_renameTime,
  output [63:0]  io_out_bits_uop_debugInfo_dispatchTime,
  output [63:0]  io_out_bits_uop_debugInfo_enqRsTime,
  output [63:0]  io_out_bits_uop_debugInfo_selectTime,
  output [63:0]  io_out_bits_uop_debugInfo_issueTime,
  output [63:0]  io_out_bits_uop_debugInfo_writebackTime,
  output [63:0]  io_out_bits_uop_debugInfo_runahead_checkpoint_id,
  output [63:0]  io_out_bits_uop_debugInfo_tlbFirstReqTime,
  output [63:0]  io_out_bits_uop_debugInfo_tlbRespTime,
  output [55:0]  io_out_bits_uop_debug_seqNum_seqNum,
  output [7:0]   io_out_bits_uop_debug_seqNum_uopIdx,
  output         io_out_bits_uop_lqIdx_flag,
  output [6:0]   io_out_bits_uop_lqIdx_value,
  output         io_out_bits_uop_sqIdx_flag,
  output [5:0]   io_out_bits_uop_sqIdx_value,
  output [4:0]   io_out_bits_uop_numLsElem,
  output         io_out_bits_preIsSplit,
  output [3:0]   io_out_bits_mBIndex,
  output [2:0]   io_out_bits_alignedType,
  output [7:0]   io_out_bits_indexVlMaxInVd,
  output [3:0]   io_out_bits_usLowBitsAddr,
  output         io_out_bits_usAligned128,
  output [31:0]  io_out_bits_usMask,
  output         io_out_bits_isVecPartReplay,
  output [15:0]  io_out_bits_vecReplayFlowMask,
  input          io_threshold_valid,
  input          io_threshold_bits_robIdx_flag,
  input  [7:0]   io_threshold_bits_robIdx_value,
  input  [6:0]   io_threshold_bits_uopIdx
);

  split_in_t     in;
  always_comb begin
    in = '0;
    in.uop.pc = io_in_bits_uop_pc;
    in.uop.ftqPtr_flag = io_in_bits_uop_ftqPtr_flag;
    in.uop.ftqPtr_value = io_in_bits_uop_ftqPtr_value;
    in.uop.ftqOffset = io_in_bits_uop_ftqOffset;
    in.uop.fuType = io_in_bits_uop_fuType;
    in.uop.fuOpType = io_in_bits_uop_fuOpType;
    in.uop.vecWen = io_in_bits_uop_vecWen;
    in.uop.v0Wen = io_in_bits_uop_v0Wen;
    in.uop.vlWen = io_in_bits_uop_vlWen;
    in.uop.vpu_vill = io_in_bits_uop_vpu_vill;
    in.uop.vpu_vma = io_in_bits_uop_vpu_vma;
    in.uop.vpu_vta = io_in_bits_uop_vpu_vta;
    in.uop.vpu_vsew = io_in_bits_uop_vpu_vsew;
    in.uop.vpu_vlmul = io_in_bits_uop_vpu_vlmul;
    in.uop.vpu_specVill = io_in_bits_uop_vpu_specVill;
    in.uop.vpu_specVma = io_in_bits_uop_vpu_specVma;
    in.uop.vpu_specVta = io_in_bits_uop_vpu_specVta;
    in.uop.vpu_specVsew = io_in_bits_uop_vpu_specVsew;
    in.uop.vpu_specVlmul = io_in_bits_uop_vpu_specVlmul;
    in.uop.vpu_vm = io_in_bits_uop_vpu_vm;
    in.uop.vpu_vstart = io_in_bits_uop_vpu_vstart;
    in.uop.vpu_frm = io_in_bits_uop_vpu_frm;
    in.uop.vpu_fpu_isFpToVecInst = io_in_bits_uop_vpu_fpu_isFpToVecInst;
    in.uop.vpu_fpu_isFP32Instr = io_in_bits_uop_vpu_fpu_isFP32Instr;
    in.uop.vpu_fpu_isFP64Instr = io_in_bits_uop_vpu_fpu_isFP64Instr;
    in.uop.vpu_fpu_isReduction = io_in_bits_uop_vpu_fpu_isReduction;
    in.uop.vpu_fpu_isFoldTo1_2 = io_in_bits_uop_vpu_fpu_isFoldTo1_2;
    in.uop.vpu_fpu_isFoldTo1_4 = io_in_bits_uop_vpu_fpu_isFoldTo1_4;
    in.uop.vpu_fpu_isFoldTo1_8 = io_in_bits_uop_vpu_fpu_isFoldTo1_8;
    in.uop.vpu_vxrm = io_in_bits_uop_vpu_vxrm;
    in.uop.vpu_vuopIdx = io_in_bits_uop_vpu_vuopIdx;
    in.uop.vpu_lastUop = io_in_bits_uop_vpu_lastUop;
    in.uop.vpu_vmask = io_in_bits_uop_vpu_vmask;
    in.uop.vpu_nf = io_in_bits_uop_vpu_nf;
    in.uop.vpu_veew = io_in_bits_uop_vpu_veew;
    in.uop.vpu_isReverse = io_in_bits_uop_vpu_isReverse;
    in.uop.vpu_isExt = io_in_bits_uop_vpu_isExt;
    in.uop.vpu_isNarrow = io_in_bits_uop_vpu_isNarrow;
    in.uop.vpu_isDstMask = io_in_bits_uop_vpu_isDstMask;
    in.uop.vpu_isOpMask = io_in_bits_uop_vpu_isOpMask;
    in.uop.vpu_isMove = io_in_bits_uop_vpu_isMove;
    in.uop.vpu_isDependOldVd = io_in_bits_uop_vpu_isDependOldVd;
    in.uop.vpu_isWritePartVd = io_in_bits_uop_vpu_isWritePartVd;
    in.uop.vpu_isVleff = io_in_bits_uop_vpu_isVleff;
    in.uop.pdest = io_in_bits_uop_pdest;
    in.uop.robIdx_flag = io_in_bits_uop_robIdx_flag;
    in.uop.robIdx_value = io_in_bits_uop_robIdx_value;
    in.uop.debugInfo_eliminatedMove = io_in_bits_uop_debugInfo_eliminatedMove;
    in.uop.debugInfo_renameTime = io_in_bits_uop_debugInfo_renameTime;
    in.uop.debugInfo_dispatchTime = io_in_bits_uop_debugInfo_dispatchTime;
    in.uop.debugInfo_enqRsTime = io_in_bits_uop_debugInfo_enqRsTime;
    in.uop.debugInfo_selectTime = io_in_bits_uop_debugInfo_selectTime;
    in.uop.debugInfo_issueTime = io_in_bits_uop_debugInfo_issueTime;
    in.uop.debugInfo_writebackTime = io_in_bits_uop_debugInfo_writebackTime;
    in.uop.debugInfo_runahead_checkpoint_id = io_in_bits_uop_debugInfo_runahead_checkpoint_id;
    in.uop.debugInfo_tlbFirstReqTime = io_in_bits_uop_debugInfo_tlbFirstReqTime;
    in.uop.debugInfo_tlbRespTime = io_in_bits_uop_debugInfo_tlbRespTime;
    in.uop.debug_seqNum_seqNum = io_in_bits_uop_debug_seqNum_seqNum;
    in.uop.debug_seqNum_uopIdx = io_in_bits_uop_debug_seqNum_uopIdx;
    in.uop.lqIdx_flag = io_in_bits_uop_lqIdx_flag;
    in.uop.lqIdx_value = io_in_bits_uop_lqIdx_value;
    in.uop.sqIdx_flag = io_in_bits_uop_sqIdx_flag;
    in.uop.sqIdx_value = io_in_bits_uop_sqIdx_value;
    in.uop.numLsElem = io_in_bits_uop_numLsElem;
    in.src_0 = io_in_bits_src_0;
    in.src_1 = io_in_bits_src_1;
    in.src_2 = io_in_bits_src_2;
    in.src_3 = io_in_bits_src_3;
    in.src_4 = io_in_bits_src_4;
    in.flowNum = io_in_bits_flowNum;
    in.isVecPartReplay = io_in_bits_isVecPartReplay;
    in.vecReplayMask = io_in_bits_vecReplayMask;
    in.vecReplayMbIdx = io_in_bits_vecReplayMbIdx;
  end

  merge_req_t    toMergeBuffer_req;
  assign io_toMergeBuffer_req_bits_mask = toMergeBuffer_req.mask;
  assign io_toMergeBuffer_req_bits_vaddr = toMergeBuffer_req.vaddr;
  assign io_toMergeBuffer_req_bits_flowNum = toMergeBuffer_req.flowNum;
  assign io_toMergeBuffer_req_bits_uop_fuOpType = toMergeBuffer_req.uop.fuOpType;
  assign io_toMergeBuffer_req_bits_uop_vecWen = toMergeBuffer_req.uop.vecWen;
  assign io_toMergeBuffer_req_bits_uop_v0Wen = toMergeBuffer_req.uop.v0Wen;
  assign io_toMergeBuffer_req_bits_uop_vlWen = toMergeBuffer_req.uop.vlWen;
  assign io_toMergeBuffer_req_bits_uop_vpu_vill = toMergeBuffer_req.uop.vpu_vill;
  assign io_toMergeBuffer_req_bits_uop_vpu_vma = toMergeBuffer_req.uop.vpu_vma;
  assign io_toMergeBuffer_req_bits_uop_vpu_vta = toMergeBuffer_req.uop.vpu_vta;
  assign io_toMergeBuffer_req_bits_uop_vpu_vsew = toMergeBuffer_req.uop.vpu_vsew;
  assign io_toMergeBuffer_req_bits_uop_vpu_vlmul = toMergeBuffer_req.uop.vpu_vlmul;
  assign io_toMergeBuffer_req_bits_uop_vpu_specVill = toMergeBuffer_req.uop.vpu_specVill;
  assign io_toMergeBuffer_req_bits_uop_vpu_specVma = toMergeBuffer_req.uop.vpu_specVma;
  assign io_toMergeBuffer_req_bits_uop_vpu_specVta = toMergeBuffer_req.uop.vpu_specVta;
  assign io_toMergeBuffer_req_bits_uop_vpu_specVsew = toMergeBuffer_req.uop.vpu_specVsew;
  assign io_toMergeBuffer_req_bits_uop_vpu_specVlmul = toMergeBuffer_req.uop.vpu_specVlmul;
  assign io_toMergeBuffer_req_bits_uop_vpu_vm = toMergeBuffer_req.uop.vpu_vm;
  assign io_toMergeBuffer_req_bits_uop_vpu_frm = toMergeBuffer_req.uop.vpu_frm;
  assign io_toMergeBuffer_req_bits_uop_vpu_fpu_isFpToVecInst = toMergeBuffer_req.uop.vpu_fpu_isFpToVecInst;
  assign io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP32Instr = toMergeBuffer_req.uop.vpu_fpu_isFP32Instr;
  assign io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP64Instr = toMergeBuffer_req.uop.vpu_fpu_isFP64Instr;
  assign io_toMergeBuffer_req_bits_uop_vpu_fpu_isReduction = toMergeBuffer_req.uop.vpu_fpu_isReduction;
  assign io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_2 = toMergeBuffer_req.uop.vpu_fpu_isFoldTo1_2;
  assign io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_4 = toMergeBuffer_req.uop.vpu_fpu_isFoldTo1_4;
  assign io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_8 = toMergeBuffer_req.uop.vpu_fpu_isFoldTo1_8;
  assign io_toMergeBuffer_req_bits_uop_vpu_vxrm = toMergeBuffer_req.uop.vpu_vxrm;
  assign io_toMergeBuffer_req_bits_uop_vpu_vuopIdx = toMergeBuffer_req.uop.vpu_vuopIdx;
  assign io_toMergeBuffer_req_bits_uop_vpu_lastUop = toMergeBuffer_req.uop.vpu_lastUop;
  assign io_toMergeBuffer_req_bits_uop_vpu_vmask = toMergeBuffer_req.uop.vpu_vmask;
  assign io_toMergeBuffer_req_bits_uop_vpu_vl = toMergeBuffer_req.uop.vpu_vl;
  assign io_toMergeBuffer_req_bits_uop_vpu_nf = toMergeBuffer_req.uop.vpu_nf;
  assign io_toMergeBuffer_req_bits_uop_vpu_veew = toMergeBuffer_req.uop.vpu_veew;
  assign io_toMergeBuffer_req_bits_uop_vpu_isReverse = toMergeBuffer_req.uop.vpu_isReverse;
  assign io_toMergeBuffer_req_bits_uop_vpu_isExt = toMergeBuffer_req.uop.vpu_isExt;
  assign io_toMergeBuffer_req_bits_uop_vpu_isNarrow = toMergeBuffer_req.uop.vpu_isNarrow;
  assign io_toMergeBuffer_req_bits_uop_vpu_isDstMask = toMergeBuffer_req.uop.vpu_isDstMask;
  assign io_toMergeBuffer_req_bits_uop_vpu_isOpMask = toMergeBuffer_req.uop.vpu_isOpMask;
  assign io_toMergeBuffer_req_bits_uop_vpu_isMove = toMergeBuffer_req.uop.vpu_isMove;
  assign io_toMergeBuffer_req_bits_uop_vpu_isDependOldVd = toMergeBuffer_req.uop.vpu_isDependOldVd;
  assign io_toMergeBuffer_req_bits_uop_vpu_isWritePartVd = toMergeBuffer_req.uop.vpu_isWritePartVd;
  assign io_toMergeBuffer_req_bits_uop_vpu_isVleff = toMergeBuffer_req.uop.vpu_isVleff;
  assign io_toMergeBuffer_req_bits_uop_uopIdx = toMergeBuffer_req.uop.uopIdx;
  assign io_toMergeBuffer_req_bits_uop_pdest = toMergeBuffer_req.uop.pdest;
  assign io_toMergeBuffer_req_bits_uop_robIdx_flag = toMergeBuffer_req.uop.robIdx_flag;
  assign io_toMergeBuffer_req_bits_uop_robIdx_value = toMergeBuffer_req.uop.robIdx_value;
  assign io_toMergeBuffer_req_bits_uop_debugInfo_eliminatedMove = toMergeBuffer_req.uop.debugInfo_eliminatedMove;
  assign io_toMergeBuffer_req_bits_uop_debugInfo_renameTime = toMergeBuffer_req.uop.debugInfo_renameTime;
  assign io_toMergeBuffer_req_bits_uop_debugInfo_dispatchTime = toMergeBuffer_req.uop.debugInfo_dispatchTime;
  assign io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime = toMergeBuffer_req.uop.debugInfo_enqRsTime;
  assign io_toMergeBuffer_req_bits_uop_debugInfo_selectTime = toMergeBuffer_req.uop.debugInfo_selectTime;
  assign io_toMergeBuffer_req_bits_uop_debugInfo_issueTime = toMergeBuffer_req.uop.debugInfo_issueTime;
  assign io_toMergeBuffer_req_bits_uop_debugInfo_writebackTime = toMergeBuffer_req.uop.debugInfo_writebackTime;
  assign io_toMergeBuffer_req_bits_uop_debugInfo_runahead_checkpoint_id = toMergeBuffer_req.uop.debugInfo_runahead_checkpoint_id;
  assign io_toMergeBuffer_req_bits_uop_debugInfo_tlbFirstReqTime = toMergeBuffer_req.uop.debugInfo_tlbFirstReqTime;
  assign io_toMergeBuffer_req_bits_uop_debugInfo_tlbRespTime = toMergeBuffer_req.uop.debugInfo_tlbRespTime;
  assign io_toMergeBuffer_req_bits_uop_debug_seqNum_seqNum = toMergeBuffer_req.uop.debug_seqNum_seqNum;
  assign io_toMergeBuffer_req_bits_uop_debug_seqNum_uopIdx = toMergeBuffer_req.uop.debug_seqNum_uopIdx;
  assign io_toMergeBuffer_req_bits_uop_lqIdx_flag = toMergeBuffer_req.uop.lqIdx_flag;
  assign io_toMergeBuffer_req_bits_uop_lqIdx_value = toMergeBuffer_req.uop.lqIdx_value;
  assign io_toMergeBuffer_req_bits_uop_sqIdx_flag = toMergeBuffer_req.uop.sqIdx_flag;
  assign io_toMergeBuffer_req_bits_uop_sqIdx_value = toMergeBuffer_req.uop.sqIdx_value;
  assign io_toMergeBuffer_req_bits_vlmax = toMergeBuffer_req.vlmax;

  vls_t          out;
  assign io_out_bits_flowMask = out.flowMask;
  assign io_out_bits_data = out.data;
  assign io_out_bits_baseAddr = out.baseAddr;
  assign io_out_bits_uopAddr = out.uopAddr;
  assign io_out_bits_stride = out.stride;
  assign io_out_bits_flowNum = out.flowNum;
  assign io_out_bits_eew = out.eew;
  assign io_out_bits_sew = out.sew;
  assign io_out_bits_emul = out.emul;
  assign io_out_bits_lmul = out.lmul;
  assign io_out_bits_instType = out.instType;
  assign io_out_bits_indexedSplitOffset = out.indexedSplitOffset;
  assign io_out_bits_uop_pc = out.uop.pc;
  assign io_out_bits_uop_ftqPtr_flag = out.uop.ftqPtr_flag;
  assign io_out_bits_uop_ftqPtr_value = out.uop.ftqPtr_value;
  assign io_out_bits_uop_ftqOffset = out.uop.ftqOffset;
  assign io_out_bits_uop_fuType = out.uop.fuType;
  assign io_out_bits_uop_fuOpType = out.uop.fuOpType;
  assign io_out_bits_uop_vecWen = out.uop.vecWen;
  assign io_out_bits_uop_v0Wen = out.uop.v0Wen;
  assign io_out_bits_uop_vlWen = out.uop.vlWen;
  assign io_out_bits_uop_vpu_vill = out.uop.vpu_vill;
  assign io_out_bits_uop_vpu_vma = out.uop.vpu_vma;
  assign io_out_bits_uop_vpu_vta = out.uop.vpu_vta;
  assign io_out_bits_uop_vpu_vsew = out.uop.vpu_vsew;
  assign io_out_bits_uop_vpu_vlmul = out.uop.vpu_vlmul;
  assign io_out_bits_uop_vpu_specVill = out.uop.vpu_specVill;
  assign io_out_bits_uop_vpu_specVma = out.uop.vpu_specVma;
  assign io_out_bits_uop_vpu_specVta = out.uop.vpu_specVta;
  assign io_out_bits_uop_vpu_specVsew = out.uop.vpu_specVsew;
  assign io_out_bits_uop_vpu_specVlmul = out.uop.vpu_specVlmul;
  assign io_out_bits_uop_vpu_vm = out.uop.vpu_vm;
  assign io_out_bits_uop_vpu_vstart = out.uop.vpu_vstart;
  assign io_out_bits_uop_vpu_frm = out.uop.vpu_frm;
  assign io_out_bits_uop_vpu_fpu_isFpToVecInst = out.uop.vpu_fpu_isFpToVecInst;
  assign io_out_bits_uop_vpu_fpu_isFP32Instr = out.uop.vpu_fpu_isFP32Instr;
  assign io_out_bits_uop_vpu_fpu_isFP64Instr = out.uop.vpu_fpu_isFP64Instr;
  assign io_out_bits_uop_vpu_fpu_isReduction = out.uop.vpu_fpu_isReduction;
  assign io_out_bits_uop_vpu_fpu_isFoldTo1_2 = out.uop.vpu_fpu_isFoldTo1_2;
  assign io_out_bits_uop_vpu_fpu_isFoldTo1_4 = out.uop.vpu_fpu_isFoldTo1_4;
  assign io_out_bits_uop_vpu_fpu_isFoldTo1_8 = out.uop.vpu_fpu_isFoldTo1_8;
  assign io_out_bits_uop_vpu_vxrm = out.uop.vpu_vxrm;
  assign io_out_bits_uop_vpu_vuopIdx = out.uop.vpu_vuopIdx;
  assign io_out_bits_uop_vpu_lastUop = out.uop.vpu_lastUop;
  assign io_out_bits_uop_vpu_vmask = out.uop.vpu_vmask;
  assign io_out_bits_uop_vpu_vl = out.uop.vpu_vl;
  assign io_out_bits_uop_vpu_nf = out.uop.vpu_nf;
  assign io_out_bits_uop_vpu_veew = out.uop.vpu_veew;
  assign io_out_bits_uop_vpu_isReverse = out.uop.vpu_isReverse;
  assign io_out_bits_uop_vpu_isExt = out.uop.vpu_isExt;
  assign io_out_bits_uop_vpu_isNarrow = out.uop.vpu_isNarrow;
  assign io_out_bits_uop_vpu_isDstMask = out.uop.vpu_isDstMask;
  assign io_out_bits_uop_vpu_isOpMask = out.uop.vpu_isOpMask;
  assign io_out_bits_uop_vpu_isMove = out.uop.vpu_isMove;
  assign io_out_bits_uop_vpu_isDependOldVd = out.uop.vpu_isDependOldVd;
  assign io_out_bits_uop_vpu_isWritePartVd = out.uop.vpu_isWritePartVd;
  assign io_out_bits_uop_vpu_isVleff = out.uop.vpu_isVleff;
  assign io_out_bits_uop_uopIdx = out.uop.uopIdx;
  assign io_out_bits_uop_lastUop = out.uop.lastUop;
  assign io_out_bits_uop_numUops = out.uop.numUops;
  assign io_out_bits_uop_pdest = out.uop.pdest;
  assign io_out_bits_uop_robIdx_flag = out.uop.robIdx_flag;
  assign io_out_bits_uop_robIdx_value = out.uop.robIdx_value;
  assign io_out_bits_uop_debugInfo_eliminatedMove = out.uop.debugInfo_eliminatedMove;
  assign io_out_bits_uop_debugInfo_renameTime = out.uop.debugInfo_renameTime;
  assign io_out_bits_uop_debugInfo_dispatchTime = out.uop.debugInfo_dispatchTime;
  assign io_out_bits_uop_debugInfo_enqRsTime = out.uop.debugInfo_enqRsTime;
  assign io_out_bits_uop_debugInfo_selectTime = out.uop.debugInfo_selectTime;
  assign io_out_bits_uop_debugInfo_issueTime = out.uop.debugInfo_issueTime;
  assign io_out_bits_uop_debugInfo_writebackTime = out.uop.debugInfo_writebackTime;
  assign io_out_bits_uop_debugInfo_runahead_checkpoint_id = out.uop.debugInfo_runahead_checkpoint_id;
  assign io_out_bits_uop_debugInfo_tlbFirstReqTime = out.uop.debugInfo_tlbFirstReqTime;
  assign io_out_bits_uop_debugInfo_tlbRespTime = out.uop.debugInfo_tlbRespTime;
  assign io_out_bits_uop_debug_seqNum_seqNum = out.uop.debug_seqNum_seqNum;
  assign io_out_bits_uop_debug_seqNum_uopIdx = out.uop.debug_seqNum_uopIdx;
  assign io_out_bits_uop_lqIdx_flag = out.uop.lqIdx_flag;
  assign io_out_bits_uop_lqIdx_value = out.uop.lqIdx_value;
  assign io_out_bits_uop_sqIdx_flag = out.uop.sqIdx_flag;
  assign io_out_bits_uop_sqIdx_value = out.uop.sqIdx_value;
  assign io_out_bits_uop_numLsElem = out.uop.numLsElem;
  assign io_out_bits_preIsSplit = out.preIsSplit;
  assign io_out_bits_mBIndex = out.mBIndex;
  assign io_out_bits_alignedType = out.alignedType;
  assign io_out_bits_indexVlMaxInVd = out.indexVlMaxInVd;
  assign io_out_bits_usLowBitsAddr = out.usLowBitsAddr;
  assign io_out_bits_usAligned128 = out.usAligned128;
  assign io_out_bits_usMask = out.usMask;
  assign io_out_bits_isVecPartReplay = out.isVecPartReplay;
  assign io_out_bits_vecReplayFlowMask = out.vecReplayFlowMask;

  // ---- 核与寄存器之间的桥 ----
  vls_t          s0_out, s1_in;
  logic          s0_fire;

  // ---- s1_in <= s0_out（s0_fire 时整包打拍，无复位）：golden 留下的 90 个字段 ----
  logic          s1_in_r_isVecPartReplay;
  logic [15:0]   s1_in_r_flowMask;
  logic [15:0]   s1_in_r_byteMask;
  logic [127:0]  s1_in_r_data;
  logic [63:0]   s1_in_r_baseAddr;
  logic [127:0]  s1_in_r_stride;
  logic [4:0]    s1_in_r_flowNum;
  logic [3:0]    s1_in_r_nfields;
  logic [1:0]    s1_in_r_eew;
  logic [2:0]    s1_in_r_sew;
  logic [2:0]    s1_in_r_emul;
  logic [2:0]    s1_in_r_lmul;
  logic [7:0]    s1_in_r_vlmax;
  logic [2:0]    s1_in_r_instType;
  logic [2:0]    s1_in_r_rawNf;
  logic [15:0]   s1_in_r_indexedSrcMask;
  logic [4:0]    s1_in_r_indexedSplitOffset;
  logic [49:0]   s1_in_r_uop_pc;
  logic          s1_in_r_uop_ftqPtr_flag;
  logic [5:0]    s1_in_r_uop_ftqPtr_value;
  logic [3:0]    s1_in_r_uop_ftqOffset;
  logic [34:0]   s1_in_r_uop_fuType;
  logic [8:0]    s1_in_r_uop_fuOpType;
  logic          s1_in_r_uop_vecWen;
  logic          s1_in_r_uop_v0Wen;
  logic          s1_in_r_uop_vlWen;
  logic          s1_in_r_uop_vpu_vill;
  logic          s1_in_r_uop_vpu_vma;
  logic          s1_in_r_uop_vpu_vta;
  logic [1:0]    s1_in_r_uop_vpu_vsew;
  logic [2:0]    s1_in_r_uop_vpu_vlmul;
  logic          s1_in_r_uop_vpu_specVill;
  logic          s1_in_r_uop_vpu_specVma;
  logic          s1_in_r_uop_vpu_specVta;
  logic [1:0]    s1_in_r_uop_vpu_specVsew;
  logic [2:0]    s1_in_r_uop_vpu_specVlmul;
  logic          s1_in_r_uop_vpu_vm;
  logic [7:0]    s1_in_r_uop_vpu_vstart;
  logic [2:0]    s1_in_r_uop_vpu_frm;
  logic          s1_in_r_uop_vpu_fpu_isFpToVecInst;
  logic          s1_in_r_uop_vpu_fpu_isFP32Instr;
  logic          s1_in_r_uop_vpu_fpu_isFP64Instr;
  logic          s1_in_r_uop_vpu_fpu_isReduction;
  logic          s1_in_r_uop_vpu_fpu_isFoldTo1_2;
  logic          s1_in_r_uop_vpu_fpu_isFoldTo1_4;
  logic          s1_in_r_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0]    s1_in_r_uop_vpu_vxrm;
  logic [6:0]    s1_in_r_uop_vpu_vuopIdx;
  logic          s1_in_r_uop_vpu_lastUop;
  logic [127:0]  s1_in_r_uop_vpu_vmask;
  logic [7:0]    s1_in_r_uop_vpu_vl;
  logic [2:0]    s1_in_r_uop_vpu_nf;
  logic [1:0]    s1_in_r_uop_vpu_veew;
  logic          s1_in_r_uop_vpu_isReverse;
  logic          s1_in_r_uop_vpu_isExt;
  logic          s1_in_r_uop_vpu_isNarrow;
  logic          s1_in_r_uop_vpu_isDstMask;
  logic          s1_in_r_uop_vpu_isOpMask;
  logic          s1_in_r_uop_vpu_isMove;
  logic          s1_in_r_uop_vpu_isDependOldVd;
  logic          s1_in_r_uop_vpu_isWritePartVd;
  logic          s1_in_r_uop_vpu_isVleff;
  logic [6:0]    s1_in_r_uop_uopIdx;
  logic          s1_in_r_uop_lastUop;
  logic [6:0]    s1_in_r_uop_numUops;
  logic [7:0]    s1_in_r_uop_pdest;
  logic          s1_in_r_uop_robIdx_flag;
  logic [7:0]    s1_in_r_uop_robIdx_value;
  logic          s1_in_r_uop_debugInfo_eliminatedMove;
  logic [63:0]   s1_in_r_uop_debugInfo_renameTime;
  logic [63:0]   s1_in_r_uop_debugInfo_dispatchTime;
  logic [63:0]   s1_in_r_uop_debugInfo_enqRsTime;
  logic [63:0]   s1_in_r_uop_debugInfo_selectTime;
  logic [63:0]   s1_in_r_uop_debugInfo_issueTime;
  logic [63:0]   s1_in_r_uop_debugInfo_writebackTime;
  logic [63:0]   s1_in_r_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]   s1_in_r_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]   s1_in_r_uop_debugInfo_tlbRespTime;
  logic [55:0]   s1_in_r_uop_debug_seqNum_seqNum;
  logic [7:0]    s1_in_r_uop_debug_seqNum_uopIdx;
  logic          s1_in_r_uop_lqIdx_flag;
  logic [6:0]    s1_in_r_uop_lqIdx_value;
  logic          s1_in_r_uop_sqIdx_flag;
  logic [5:0]    s1_in_r_uop_sqIdx_value;
  logic [4:0]    s1_in_r_uop_numLsElem;
  logic          s1_in_r_preIsSplit;
  logic [2:0]    s1_in_r_alignedType;
  logic [7:0]    s1_in_r_indexVlMaxInVd;
  logic [3:0]    s1_in_r_vecReplayMbIdx;
  logic [15:0]   s1_in_r_vecReplayFlowMask;
  always_ff @(posedge clock) begin
    if (s0_fire) begin
      s1_in_r_isVecPartReplay <= s0_out.isVecPartReplay;
      s1_in_r_flowMask <= s0_out.flowMask;
      s1_in_r_byteMask <= s0_out.byteMask;
      s1_in_r_data <= s0_out.data;
      s1_in_r_baseAddr <= s0_out.baseAddr;
      s1_in_r_stride <= s0_out.stride;
      s1_in_r_flowNum <= s0_out.flowNum;
      s1_in_r_nfields <= s0_out.nfields;
      s1_in_r_eew <= s0_out.eew;
      s1_in_r_sew <= s0_out.sew;
      s1_in_r_emul <= s0_out.emul;
      s1_in_r_lmul <= s0_out.lmul;
      s1_in_r_vlmax <= s0_out.vlmax;
      s1_in_r_instType <= s0_out.instType;
      s1_in_r_rawNf <= s0_out.rawNf;
      s1_in_r_indexedSrcMask <= s0_out.indexedSrcMask;
      s1_in_r_indexedSplitOffset <= s0_out.indexedSplitOffset;
      s1_in_r_uop_pc <= s0_out.uop.pc;
      s1_in_r_uop_ftqPtr_flag <= s0_out.uop.ftqPtr_flag;
      s1_in_r_uop_ftqPtr_value <= s0_out.uop.ftqPtr_value;
      s1_in_r_uop_ftqOffset <= s0_out.uop.ftqOffset;
      s1_in_r_uop_fuType <= s0_out.uop.fuType;
      s1_in_r_uop_fuOpType <= s0_out.uop.fuOpType;
      s1_in_r_uop_vecWen <= s0_out.uop.vecWen;
      s1_in_r_uop_v0Wen <= s0_out.uop.v0Wen;
      s1_in_r_uop_vlWen <= s0_out.uop.vlWen;
      s1_in_r_uop_vpu_vill <= s0_out.uop.vpu_vill;
      s1_in_r_uop_vpu_vma <= s0_out.uop.vpu_vma;
      s1_in_r_uop_vpu_vta <= s0_out.uop.vpu_vta;
      s1_in_r_uop_vpu_vsew <= s0_out.uop.vpu_vsew;
      s1_in_r_uop_vpu_vlmul <= s0_out.uop.vpu_vlmul;
      s1_in_r_uop_vpu_specVill <= s0_out.uop.vpu_specVill;
      s1_in_r_uop_vpu_specVma <= s0_out.uop.vpu_specVma;
      s1_in_r_uop_vpu_specVta <= s0_out.uop.vpu_specVta;
      s1_in_r_uop_vpu_specVsew <= s0_out.uop.vpu_specVsew;
      s1_in_r_uop_vpu_specVlmul <= s0_out.uop.vpu_specVlmul;
      s1_in_r_uop_vpu_vm <= s0_out.uop.vpu_vm;
      s1_in_r_uop_vpu_vstart <= s0_out.uop.vpu_vstart;
      s1_in_r_uop_vpu_frm <= s0_out.uop.vpu_frm;
      s1_in_r_uop_vpu_fpu_isFpToVecInst <= s0_out.uop.vpu_fpu_isFpToVecInst;
      s1_in_r_uop_vpu_fpu_isFP32Instr <= s0_out.uop.vpu_fpu_isFP32Instr;
      s1_in_r_uop_vpu_fpu_isFP64Instr <= s0_out.uop.vpu_fpu_isFP64Instr;
      s1_in_r_uop_vpu_fpu_isReduction <= s0_out.uop.vpu_fpu_isReduction;
      s1_in_r_uop_vpu_fpu_isFoldTo1_2 <= s0_out.uop.vpu_fpu_isFoldTo1_2;
      s1_in_r_uop_vpu_fpu_isFoldTo1_4 <= s0_out.uop.vpu_fpu_isFoldTo1_4;
      s1_in_r_uop_vpu_fpu_isFoldTo1_8 <= s0_out.uop.vpu_fpu_isFoldTo1_8;
      s1_in_r_uop_vpu_vxrm <= s0_out.uop.vpu_vxrm;
      s1_in_r_uop_vpu_vuopIdx <= s0_out.uop.vpu_vuopIdx;
      s1_in_r_uop_vpu_lastUop <= s0_out.uop.vpu_lastUop;
      s1_in_r_uop_vpu_vmask <= s0_out.uop.vpu_vmask;
      s1_in_r_uop_vpu_vl <= s0_out.uop.vpu_vl;
      s1_in_r_uop_vpu_nf <= s0_out.uop.vpu_nf;
      s1_in_r_uop_vpu_veew <= s0_out.uop.vpu_veew;
      s1_in_r_uop_vpu_isReverse <= s0_out.uop.vpu_isReverse;
      s1_in_r_uop_vpu_isExt <= s0_out.uop.vpu_isExt;
      s1_in_r_uop_vpu_isNarrow <= s0_out.uop.vpu_isNarrow;
      s1_in_r_uop_vpu_isDstMask <= s0_out.uop.vpu_isDstMask;
      s1_in_r_uop_vpu_isOpMask <= s0_out.uop.vpu_isOpMask;
      s1_in_r_uop_vpu_isMove <= s0_out.uop.vpu_isMove;
      s1_in_r_uop_vpu_isDependOldVd <= s0_out.uop.vpu_isDependOldVd;
      s1_in_r_uop_vpu_isWritePartVd <= s0_out.uop.vpu_isWritePartVd;
      s1_in_r_uop_vpu_isVleff <= s0_out.uop.vpu_isVleff;
      s1_in_r_uop_uopIdx <= s0_out.uop.uopIdx;
      s1_in_r_uop_lastUop <= s0_out.uop.lastUop;
      s1_in_r_uop_numUops <= s0_out.uop.numUops;
      s1_in_r_uop_pdest <= s0_out.uop.pdest;
      s1_in_r_uop_robIdx_flag <= s0_out.uop.robIdx_flag;
      s1_in_r_uop_robIdx_value <= s0_out.uop.robIdx_value;
      s1_in_r_uop_debugInfo_eliminatedMove <= s0_out.uop.debugInfo_eliminatedMove;
      s1_in_r_uop_debugInfo_renameTime <= s0_out.uop.debugInfo_renameTime;
      s1_in_r_uop_debugInfo_dispatchTime <= s0_out.uop.debugInfo_dispatchTime;
      s1_in_r_uop_debugInfo_enqRsTime <= s0_out.uop.debugInfo_enqRsTime;
      s1_in_r_uop_debugInfo_selectTime <= s0_out.uop.debugInfo_selectTime;
      s1_in_r_uop_debugInfo_issueTime <= s0_out.uop.debugInfo_issueTime;
      s1_in_r_uop_debugInfo_writebackTime <= s0_out.uop.debugInfo_writebackTime;
      s1_in_r_uop_debugInfo_runahead_checkpoint_id <= s0_out.uop.debugInfo_runahead_checkpoint_id;
      s1_in_r_uop_debugInfo_tlbFirstReqTime <= s0_out.uop.debugInfo_tlbFirstReqTime;
      s1_in_r_uop_debugInfo_tlbRespTime <= s0_out.uop.debugInfo_tlbRespTime;
      s1_in_r_uop_debug_seqNum_seqNum <= s0_out.uop.debug_seqNum_seqNum;
      s1_in_r_uop_debug_seqNum_uopIdx <= s0_out.uop.debug_seqNum_uopIdx;
      s1_in_r_uop_lqIdx_flag <= s0_out.uop.lqIdx_flag;
      s1_in_r_uop_lqIdx_value <= s0_out.uop.lqIdx_value;
      s1_in_r_uop_sqIdx_flag <= s0_out.uop.sqIdx_flag;
      s1_in_r_uop_sqIdx_value <= s0_out.uop.sqIdx_value;
      s1_in_r_uop_numLsElem <= s0_out.uop.numLsElem;
      s1_in_r_preIsSplit <= s0_out.preIsSplit;
      s1_in_r_alignedType <= s0_out.alignedType;
      s1_in_r_indexVlMaxInVd <= s0_out.indexVlMaxInVd;
      s1_in_r_vecReplayMbIdx <= s0_out.vecReplayMbIdx;
      s1_in_r_vecReplayFlowMask <= s0_out.vecReplayFlowMask;
    end
  end
  always_comb begin
    s1_in = '0;
    s1_in.isVecPartReplay = s1_in_r_isVecPartReplay;
    s1_in.flowMask = s1_in_r_flowMask;
    s1_in.byteMask = s1_in_r_byteMask;
    s1_in.data = s1_in_r_data;
    s1_in.baseAddr = s1_in_r_baseAddr;
    s1_in.stride = s1_in_r_stride;
    s1_in.flowNum = s1_in_r_flowNum;
    s1_in.nfields = s1_in_r_nfields;
    s1_in.eew = s1_in_r_eew;
    s1_in.sew = s1_in_r_sew;
    s1_in.emul = s1_in_r_emul;
    s1_in.lmul = s1_in_r_lmul;
    s1_in.vlmax = s1_in_r_vlmax;
    s1_in.instType = s1_in_r_instType;
    s1_in.rawNf = s1_in_r_rawNf;
    s1_in.indexedSrcMask = s1_in_r_indexedSrcMask;
    s1_in.indexedSplitOffset = s1_in_r_indexedSplitOffset;
    s1_in.uop.pc = s1_in_r_uop_pc;
    s1_in.uop.ftqPtr_flag = s1_in_r_uop_ftqPtr_flag;
    s1_in.uop.ftqPtr_value = s1_in_r_uop_ftqPtr_value;
    s1_in.uop.ftqOffset = s1_in_r_uop_ftqOffset;
    s1_in.uop.fuType = s1_in_r_uop_fuType;
    s1_in.uop.fuOpType = s1_in_r_uop_fuOpType;
    s1_in.uop.vecWen = s1_in_r_uop_vecWen;
    s1_in.uop.v0Wen = s1_in_r_uop_v0Wen;
    s1_in.uop.vlWen = s1_in_r_uop_vlWen;
    s1_in.uop.vpu_vill = s1_in_r_uop_vpu_vill;
    s1_in.uop.vpu_vma = s1_in_r_uop_vpu_vma;
    s1_in.uop.vpu_vta = s1_in_r_uop_vpu_vta;
    s1_in.uop.vpu_vsew = s1_in_r_uop_vpu_vsew;
    s1_in.uop.vpu_vlmul = s1_in_r_uop_vpu_vlmul;
    s1_in.uop.vpu_specVill = s1_in_r_uop_vpu_specVill;
    s1_in.uop.vpu_specVma = s1_in_r_uop_vpu_specVma;
    s1_in.uop.vpu_specVta = s1_in_r_uop_vpu_specVta;
    s1_in.uop.vpu_specVsew = s1_in_r_uop_vpu_specVsew;
    s1_in.uop.vpu_specVlmul = s1_in_r_uop_vpu_specVlmul;
    s1_in.uop.vpu_vm = s1_in_r_uop_vpu_vm;
    s1_in.uop.vpu_vstart = s1_in_r_uop_vpu_vstart;
    s1_in.uop.vpu_frm = s1_in_r_uop_vpu_frm;
    s1_in.uop.vpu_fpu_isFpToVecInst = s1_in_r_uop_vpu_fpu_isFpToVecInst;
    s1_in.uop.vpu_fpu_isFP32Instr = s1_in_r_uop_vpu_fpu_isFP32Instr;
    s1_in.uop.vpu_fpu_isFP64Instr = s1_in_r_uop_vpu_fpu_isFP64Instr;
    s1_in.uop.vpu_fpu_isReduction = s1_in_r_uop_vpu_fpu_isReduction;
    s1_in.uop.vpu_fpu_isFoldTo1_2 = s1_in_r_uop_vpu_fpu_isFoldTo1_2;
    s1_in.uop.vpu_fpu_isFoldTo1_4 = s1_in_r_uop_vpu_fpu_isFoldTo1_4;
    s1_in.uop.vpu_fpu_isFoldTo1_8 = s1_in_r_uop_vpu_fpu_isFoldTo1_8;
    s1_in.uop.vpu_vxrm = s1_in_r_uop_vpu_vxrm;
    s1_in.uop.vpu_vuopIdx = s1_in_r_uop_vpu_vuopIdx;
    s1_in.uop.vpu_lastUop = s1_in_r_uop_vpu_lastUop;
    s1_in.uop.vpu_vmask = s1_in_r_uop_vpu_vmask;
    s1_in.uop.vpu_vl = s1_in_r_uop_vpu_vl;
    s1_in.uop.vpu_nf = s1_in_r_uop_vpu_nf;
    s1_in.uop.vpu_veew = s1_in_r_uop_vpu_veew;
    s1_in.uop.vpu_isReverse = s1_in_r_uop_vpu_isReverse;
    s1_in.uop.vpu_isExt = s1_in_r_uop_vpu_isExt;
    s1_in.uop.vpu_isNarrow = s1_in_r_uop_vpu_isNarrow;
    s1_in.uop.vpu_isDstMask = s1_in_r_uop_vpu_isDstMask;
    s1_in.uop.vpu_isOpMask = s1_in_r_uop_vpu_isOpMask;
    s1_in.uop.vpu_isMove = s1_in_r_uop_vpu_isMove;
    s1_in.uop.vpu_isDependOldVd = s1_in_r_uop_vpu_isDependOldVd;
    s1_in.uop.vpu_isWritePartVd = s1_in_r_uop_vpu_isWritePartVd;
    s1_in.uop.vpu_isVleff = s1_in_r_uop_vpu_isVleff;
    s1_in.uop.uopIdx = s1_in_r_uop_uopIdx;
    s1_in.uop.lastUop = s1_in_r_uop_lastUop;
    s1_in.uop.numUops = s1_in_r_uop_numUops;
    s1_in.uop.pdest = s1_in_r_uop_pdest;
    s1_in.uop.robIdx_flag = s1_in_r_uop_robIdx_flag;
    s1_in.uop.robIdx_value = s1_in_r_uop_robIdx_value;
    s1_in.uop.debugInfo_eliminatedMove = s1_in_r_uop_debugInfo_eliminatedMove;
    s1_in.uop.debugInfo_renameTime = s1_in_r_uop_debugInfo_renameTime;
    s1_in.uop.debugInfo_dispatchTime = s1_in_r_uop_debugInfo_dispatchTime;
    s1_in.uop.debugInfo_enqRsTime = s1_in_r_uop_debugInfo_enqRsTime;
    s1_in.uop.debugInfo_selectTime = s1_in_r_uop_debugInfo_selectTime;
    s1_in.uop.debugInfo_issueTime = s1_in_r_uop_debugInfo_issueTime;
    s1_in.uop.debugInfo_writebackTime = s1_in_r_uop_debugInfo_writebackTime;
    s1_in.uop.debugInfo_runahead_checkpoint_id = s1_in_r_uop_debugInfo_runahead_checkpoint_id;
    s1_in.uop.debugInfo_tlbFirstReqTime = s1_in_r_uop_debugInfo_tlbFirstReqTime;
    s1_in.uop.debugInfo_tlbRespTime = s1_in_r_uop_debugInfo_tlbRespTime;
    s1_in.uop.debug_seqNum_seqNum = s1_in_r_uop_debug_seqNum_seqNum;
    s1_in.uop.debug_seqNum_uopIdx = s1_in_r_uop_debug_seqNum_uopIdx;
    s1_in.uop.lqIdx_flag = s1_in_r_uop_lqIdx_flag;
    s1_in.uop.lqIdx_value = s1_in_r_uop_lqIdx_value;
    s1_in.uop.sqIdx_flag = s1_in_r_uop_sqIdx_flag;
    s1_in.uop.sqIdx_value = s1_in_r_uop_sqIdx_value;
    s1_in.uop.numLsElem = s1_in_r_uop_numLsElem;
    s1_in.preIsSplit = s1_in_r_preIsSplit;
    s1_in.alignedType = s1_in_r_alignedType;
    s1_in.indexVlMaxInVd = s1_in_r_indexVlMaxInVd;
    s1_in.vecReplayMbIdx = s1_in_r_vecReplayMbIdx;
    s1_in.vecReplayFlowMask = s1_in_r_vecReplayFlowMask;
  end

  xs_VSplitPipeline_core #(.IS_VSTORE(1'b1)) u_core (
    .clock                                        (clock),
    .reset                                        (reset),
    .redirect_valid                               (io_redirect_valid),
    .redirect_bits_robIdx_flag                    (io_redirect_bits_robIdx_flag),
    .redirect_bits_robIdx_value                   (io_redirect_bits_robIdx_value),
    .redirect_bits_level                          (io_redirect_bits_level),
    .in_ready                                     (io_in_ready),
    .in_valid                                     (io_in_valid),
    .in                                           (in),
    .toMergeBuffer_req_ready                      (io_toMergeBuffer_req_ready),
    .toMergeBuffer_req_valid                      (io_toMergeBuffer_req_valid),
    .toMergeBuffer_req                            (toMergeBuffer_req),
    .toMergeBuffer_resp_valid                     (io_toMergeBuffer_resp_valid),
    .toMergeBuffer_resp_bits_mBIndex              (io_toMergeBuffer_resp_bits_mBIndex),
    .out_ready                                    (io_out_ready),
    .out_valid                                    (io_out_valid),
    .out                                          (out),
    .threshold_valid                              (io_threshold_valid),
    .threshold_bits_robIdx_flag                   (io_threshold_bits_robIdx_flag),
    .threshold_bits_robIdx_value                  (io_threshold_bits_robIdx_value),
    .threshold_bits_uopIdx                        (io_threshold_bits_uopIdx),
    .s0_out                                       (s0_out),
    .s0_fire                                      (s0_fire),
    .s1_in                                        (s1_in)
  );

endmodule
// END GENERATED(wrapper_VSSplitPipelineImp)
