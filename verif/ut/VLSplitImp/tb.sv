// =============================================================================
// VLSplitImp UT —— golden VLSplitImp 对重写 VLSplitImp_xs 双例化，同激励逐拍比全部 237 根输出。
// 本文件由 scripts/gen_vsplit.py 生成（端口连接 / 随机驱动 / 逐根比较是机械部分，
// 激励整形与覆盖判据是生成器里 TB_* 的手写部分）。勿手改。
//
// 激励要点：入口 uop 的整形同拆分流水（见 shape_uop）；out_ready 3/4；
//   store：非对齐缓冲空闲 / 标量发射 / SQ 队头向量各随机；load：三个 load 流水写回各 1/4。
// 本 tb 两侧都是整棵子树（golden 壳 + golden 子模块 对 重写壳 + 重写子模块）。
// 不复位寄存器：非常量 initreg 档两个实例各摇各的，先跑 +warmup 拍再开始比。
// 覆盖判据（读重写件内部信号，逐项有下限，不达标本轮不作数）：见 cov_names。
// =============================================================================
`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 0;
  int      errors = 0;
  longint  checks = 0;

  logic clock = 0;
  logic reset;
  always #5 clock = ~clock;

  // ---- 输入（两侧共用）----
  logic          io_redirect_valid;
  logic          io_redirect_bits_robIdx_flag;
  logic [7:0]    io_redirect_bits_robIdx_value;
  logic          io_redirect_bits_level;
  logic          io_in_valid;
  logic [49:0]   io_in_bits_uop_pc;
  logic          io_in_bits_uop_ftqPtr_flag;
  logic [5:0]    io_in_bits_uop_ftqPtr_value;
  logic [3:0]    io_in_bits_uop_ftqOffset;
  logic [34:0]   io_in_bits_uop_fuType;
  logic [8:0]    io_in_bits_uop_fuOpType;
  logic          io_in_bits_uop_vecWen;
  logic          io_in_bits_uop_v0Wen;
  logic          io_in_bits_uop_vlWen;
  logic          io_in_bits_uop_vpu_vill;
  logic          io_in_bits_uop_vpu_vma;
  logic          io_in_bits_uop_vpu_vta;
  logic [1:0]    io_in_bits_uop_vpu_vsew;
  logic [2:0]    io_in_bits_uop_vpu_vlmul;
  logic          io_in_bits_uop_vpu_specVill;
  logic          io_in_bits_uop_vpu_specVma;
  logic          io_in_bits_uop_vpu_specVta;
  logic [1:0]    io_in_bits_uop_vpu_specVsew;
  logic [2:0]    io_in_bits_uop_vpu_specVlmul;
  logic          io_in_bits_uop_vpu_vm;
  logic [7:0]    io_in_bits_uop_vpu_vstart;
  logic [2:0]    io_in_bits_uop_vpu_frm;
  logic          io_in_bits_uop_vpu_fpu_isFpToVecInst;
  logic          io_in_bits_uop_vpu_fpu_isFP32Instr;
  logic          io_in_bits_uop_vpu_fpu_isFP64Instr;
  logic          io_in_bits_uop_vpu_fpu_isReduction;
  logic          io_in_bits_uop_vpu_fpu_isFoldTo1_2;
  logic          io_in_bits_uop_vpu_fpu_isFoldTo1_4;
  logic          io_in_bits_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0]    io_in_bits_uop_vpu_vxrm;
  logic [6:0]    io_in_bits_uop_vpu_vuopIdx;
  logic          io_in_bits_uop_vpu_lastUop;
  logic [127:0]  io_in_bits_uop_vpu_vmask;
  logic [2:0]    io_in_bits_uop_vpu_nf;
  logic [1:0]    io_in_bits_uop_vpu_veew;
  logic          io_in_bits_uop_vpu_isReverse;
  logic          io_in_bits_uop_vpu_isExt;
  logic          io_in_bits_uop_vpu_isNarrow;
  logic          io_in_bits_uop_vpu_isDstMask;
  logic          io_in_bits_uop_vpu_isOpMask;
  logic          io_in_bits_uop_vpu_isMove;
  logic          io_in_bits_uop_vpu_isDependOldVd;
  logic          io_in_bits_uop_vpu_isWritePartVd;
  logic          io_in_bits_uop_vpu_isVleff;
  logic [7:0]    io_in_bits_uop_pdest;
  logic          io_in_bits_uop_robIdx_flag;
  logic [7:0]    io_in_bits_uop_robIdx_value;
  logic          io_in_bits_uop_debugInfo_eliminatedMove;
  logic [63:0]   io_in_bits_uop_debugInfo_renameTime;
  logic [63:0]   io_in_bits_uop_debugInfo_dispatchTime;
  logic [63:0]   io_in_bits_uop_debugInfo_enqRsTime;
  logic [63:0]   io_in_bits_uop_debugInfo_selectTime;
  logic [63:0]   io_in_bits_uop_debugInfo_issueTime;
  logic [63:0]   io_in_bits_uop_debugInfo_writebackTime;
  logic [63:0]   io_in_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]   io_in_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]   io_in_bits_uop_debugInfo_tlbRespTime;
  logic [55:0]   io_in_bits_uop_debug_seqNum_seqNum;
  logic [7:0]    io_in_bits_uop_debug_seqNum_uopIdx;
  logic          io_in_bits_uop_lqIdx_flag;
  logic [6:0]    io_in_bits_uop_lqIdx_value;
  logic          io_in_bits_uop_sqIdx_flag;
  logic [5:0]    io_in_bits_uop_sqIdx_value;
  logic [4:0]    io_in_bits_uop_numLsElem;
  logic [127:0]  io_in_bits_src_0;
  logic [127:0]  io_in_bits_src_1;
  logic [127:0]  io_in_bits_src_2;
  logic [127:0]  io_in_bits_src_3;
  logic [127:0]  io_in_bits_src_4;
  logic [4:0]    io_in_bits_flowNum;
  logic          io_in_bits_isVecPartReplay;
  logic [15:0]   io_in_bits_vecReplayMask;
  logic [3:0]    io_in_bits_vecReplayMbIdx;
  logic          io_toMergeBuffer_req_ready;
  logic          io_toMergeBuffer_resp_valid;
  logic [3:0]    io_toMergeBuffer_resp_bits_mBIndex;
  logic          io_out_ready;
  logic          io_threshold_valid;
  logic          io_threshold_bits_robIdx_flag;
  logic [7:0]    io_threshold_bits_robIdx_value;
  logic [6:0]    io_threshold_bits_uopIdx;
  logic          io_fromPipeline_0_valid;
  logic [3:0]    io_fromPipeline_0_bits_mBIndex;
  logic          io_fromPipeline_1_valid;
  logic [3:0]    io_fromPipeline_1_bits_mBIndex;
  logic          io_fromPipeline_2_valid;
  logic [3:0]    io_fromPipeline_2_bits_mBIndex;
  // ---- 输出：g_ = golden，x_ = 重写 ----
  wire               g_io_in_ready, x_io_in_ready;
  wire               g_io_toMergeBuffer_req_valid, x_io_toMergeBuffer_req_valid;
  wire [15:0]        g_io_toMergeBuffer_req_bits_mask, x_io_toMergeBuffer_req_bits_mask;
  wire [49:0]        g_io_toMergeBuffer_req_bits_vaddr, x_io_toMergeBuffer_req_bits_vaddr;
  wire [4:0]         g_io_toMergeBuffer_req_bits_flowNum, x_io_toMergeBuffer_req_bits_flowNum;
  wire [8:0]         g_io_toMergeBuffer_req_bits_uop_fuOpType, x_io_toMergeBuffer_req_bits_uop_fuOpType;
  wire               g_io_toMergeBuffer_req_bits_uop_vecWen, x_io_toMergeBuffer_req_bits_uop_vecWen;
  wire               g_io_toMergeBuffer_req_bits_uop_v0Wen, x_io_toMergeBuffer_req_bits_uop_v0Wen;
  wire               g_io_toMergeBuffer_req_bits_uop_vlWen, x_io_toMergeBuffer_req_bits_uop_vlWen;
  wire               g_io_toMergeBuffer_req_bits_uop_vpu_vill, x_io_toMergeBuffer_req_bits_uop_vpu_vill;
  wire               g_io_toMergeBuffer_req_bits_uop_vpu_vma, x_io_toMergeBuffer_req_bits_uop_vpu_vma;
  wire               g_io_toMergeBuffer_req_bits_uop_vpu_vta, x_io_toMergeBuffer_req_bits_uop_vpu_vta;
  wire [1:0]         g_io_toMergeBuffer_req_bits_uop_vpu_vsew, x_io_toMergeBuffer_req_bits_uop_vpu_vsew;
  wire [2:0]         g_io_toMergeBuffer_req_bits_uop_vpu_vlmul, x_io_toMergeBuffer_req_bits_uop_vpu_vlmul;
  wire               g_io_toMergeBuffer_req_bits_uop_vpu_specVill, x_io_toMergeBuffer_req_bits_uop_vpu_specVill;
  wire               g_io_toMergeBuffer_req_bits_uop_vpu_specVma, x_io_toMergeBuffer_req_bits_uop_vpu_specVma;
  wire               g_io_toMergeBuffer_req_bits_uop_vpu_specVta, x_io_toMergeBuffer_req_bits_uop_vpu_specVta;
  wire [1:0]         g_io_toMergeBuffer_req_bits_uop_vpu_specVsew, x_io_toMergeBuffer_req_bits_uop_vpu_specVsew;
  wire [2:0]         g_io_toMergeBuffer_req_bits_uop_vpu_specVlmul, x_io_toMergeBuffer_req_bits_uop_vpu_specVlmul;
  wire               g_io_toMergeBuffer_req_bits_uop_vpu_vm, x_io_toMergeBuffer_req_bits_uop_vpu_vm;
  wire [2:0]         g_io_toMergeBuffer_req_bits_uop_vpu_frm, x_io_toMergeBuffer_req_bits_uop_vpu_frm;
  wire               g_io_toMergeBuffer_req_bits_uop_vpu_fpu_isFpToVecInst, x_io_toMergeBuffer_req_bits_uop_vpu_fpu_isFpToVecInst;
  wire               g_io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP32Instr, x_io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP32Instr;
  wire               g_io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP64Instr, x_io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP64Instr;
  wire               g_io_toMergeBuffer_req_bits_uop_vpu_fpu_isReduction, x_io_toMergeBuffer_req_bits_uop_vpu_fpu_isReduction;
  wire               g_io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_2, x_io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_2;
  wire               g_io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_4, x_io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_4;
  wire               g_io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_8, x_io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_8;
  wire [1:0]         g_io_toMergeBuffer_req_bits_uop_vpu_vxrm, x_io_toMergeBuffer_req_bits_uop_vpu_vxrm;
  wire [6:0]         g_io_toMergeBuffer_req_bits_uop_vpu_vuopIdx, x_io_toMergeBuffer_req_bits_uop_vpu_vuopIdx;
  wire               g_io_toMergeBuffer_req_bits_uop_vpu_lastUop, x_io_toMergeBuffer_req_bits_uop_vpu_lastUop;
  wire [7:0]         g_io_toMergeBuffer_req_bits_uop_vpu_vl, x_io_toMergeBuffer_req_bits_uop_vpu_vl;
  wire [2:0]         g_io_toMergeBuffer_req_bits_uop_vpu_nf, x_io_toMergeBuffer_req_bits_uop_vpu_nf;
  wire [1:0]         g_io_toMergeBuffer_req_bits_uop_vpu_veew, x_io_toMergeBuffer_req_bits_uop_vpu_veew;
  wire               g_io_toMergeBuffer_req_bits_uop_vpu_isReverse, x_io_toMergeBuffer_req_bits_uop_vpu_isReverse;
  wire               g_io_toMergeBuffer_req_bits_uop_vpu_isExt, x_io_toMergeBuffer_req_bits_uop_vpu_isExt;
  wire               g_io_toMergeBuffer_req_bits_uop_vpu_isNarrow, x_io_toMergeBuffer_req_bits_uop_vpu_isNarrow;
  wire               g_io_toMergeBuffer_req_bits_uop_vpu_isDstMask, x_io_toMergeBuffer_req_bits_uop_vpu_isDstMask;
  wire               g_io_toMergeBuffer_req_bits_uop_vpu_isOpMask, x_io_toMergeBuffer_req_bits_uop_vpu_isOpMask;
  wire               g_io_toMergeBuffer_req_bits_uop_vpu_isMove, x_io_toMergeBuffer_req_bits_uop_vpu_isMove;
  wire               g_io_toMergeBuffer_req_bits_uop_vpu_isDependOldVd, x_io_toMergeBuffer_req_bits_uop_vpu_isDependOldVd;
  wire               g_io_toMergeBuffer_req_bits_uop_vpu_isWritePartVd, x_io_toMergeBuffer_req_bits_uop_vpu_isWritePartVd;
  wire               g_io_toMergeBuffer_req_bits_uop_vpu_isVleff, x_io_toMergeBuffer_req_bits_uop_vpu_isVleff;
  wire [6:0]         g_io_toMergeBuffer_req_bits_uop_uopIdx, x_io_toMergeBuffer_req_bits_uop_uopIdx;
  wire [7:0]         g_io_toMergeBuffer_req_bits_uop_pdest, x_io_toMergeBuffer_req_bits_uop_pdest;
  wire               g_io_toMergeBuffer_req_bits_uop_robIdx_flag, x_io_toMergeBuffer_req_bits_uop_robIdx_flag;
  wire [7:0]         g_io_toMergeBuffer_req_bits_uop_robIdx_value, x_io_toMergeBuffer_req_bits_uop_robIdx_value;
  wire               g_io_toMergeBuffer_req_bits_uop_debugInfo_eliminatedMove, x_io_toMergeBuffer_req_bits_uop_debugInfo_eliminatedMove;
  wire [63:0]        g_io_toMergeBuffer_req_bits_uop_debugInfo_renameTime, x_io_toMergeBuffer_req_bits_uop_debugInfo_renameTime;
  wire [63:0]        g_io_toMergeBuffer_req_bits_uop_debugInfo_dispatchTime, x_io_toMergeBuffer_req_bits_uop_debugInfo_dispatchTime;
  wire [63:0]        g_io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime, x_io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime;
  wire [63:0]        g_io_toMergeBuffer_req_bits_uop_debugInfo_selectTime, x_io_toMergeBuffer_req_bits_uop_debugInfo_selectTime;
  wire [63:0]        g_io_toMergeBuffer_req_bits_uop_debugInfo_issueTime, x_io_toMergeBuffer_req_bits_uop_debugInfo_issueTime;
  wire [63:0]        g_io_toMergeBuffer_req_bits_uop_debugInfo_writebackTime, x_io_toMergeBuffer_req_bits_uop_debugInfo_writebackTime;
  wire [63:0]        g_io_toMergeBuffer_req_bits_uop_debugInfo_runahead_checkpoint_id, x_io_toMergeBuffer_req_bits_uop_debugInfo_runahead_checkpoint_id;
  wire [63:0]        g_io_toMergeBuffer_req_bits_uop_debugInfo_tlbFirstReqTime, x_io_toMergeBuffer_req_bits_uop_debugInfo_tlbFirstReqTime;
  wire [63:0]        g_io_toMergeBuffer_req_bits_uop_debugInfo_tlbRespTime, x_io_toMergeBuffer_req_bits_uop_debugInfo_tlbRespTime;
  wire [55:0]        g_io_toMergeBuffer_req_bits_uop_debug_seqNum_seqNum, x_io_toMergeBuffer_req_bits_uop_debug_seqNum_seqNum;
  wire [7:0]         g_io_toMergeBuffer_req_bits_uop_debug_seqNum_uopIdx, x_io_toMergeBuffer_req_bits_uop_debug_seqNum_uopIdx;
  wire               g_io_toMergeBuffer_req_bits_uop_lqIdx_flag, x_io_toMergeBuffer_req_bits_uop_lqIdx_flag;
  wire [6:0]         g_io_toMergeBuffer_req_bits_uop_lqIdx_value, x_io_toMergeBuffer_req_bits_uop_lqIdx_value;
  wire               g_io_toMergeBuffer_req_bits_uop_sqIdx_flag, x_io_toMergeBuffer_req_bits_uop_sqIdx_flag;
  wire [5:0]         g_io_toMergeBuffer_req_bits_uop_sqIdx_value, x_io_toMergeBuffer_req_bits_uop_sqIdx_value;
  wire [127:0]       g_io_toMergeBuffer_req_bits_data, x_io_toMergeBuffer_req_bits_data;
  wire [2:0]         g_io_toMergeBuffer_req_bits_vdIdx, x_io_toMergeBuffer_req_bits_vdIdx;
  wire               g_io_toMergeBuffer_req_bits_fof, x_io_toMergeBuffer_req_bits_fof;
  wire [7:0]         g_io_toMergeBuffer_req_bits_vlmax, x_io_toMergeBuffer_req_bits_vlmax;
  wire               g_io_out_valid, x_io_out_valid;
  wire [63:0]        g_io_out_bits_vaddr, x_io_out_bits_vaddr;
  wire [49:0]        g_io_out_bits_basevaddr, x_io_out_bits_basevaddr;
  wire [15:0]        g_io_out_bits_mask, x_io_out_bits_mask;
  wire [3:0]         g_io_out_bits_reg_offset, x_io_out_bits_reg_offset;
  wire [2:0]         g_io_out_bits_alignedType, x_io_out_bits_alignedType;
  wire               g_io_out_bits_vecActive, x_io_out_bits_vecActive;
  wire               g_io_out_bits_vecIsFirstActiveElement, x_io_out_bits_vecIsFirstActiveElement;
  wire [31:0]        g_io_out_bits_uop_instr, x_io_out_bits_uop_instr;
  wire [49:0]        g_io_out_bits_uop_pc, x_io_out_bits_uop_pc;
  wire [9:0]         g_io_out_bits_uop_foldpc, x_io_out_bits_uop_foldpc;
  wire               g_io_out_bits_uop_exceptionVec_4, x_io_out_bits_uop_exceptionVec_4;
  wire               g_io_out_bits_uop_exceptionVec_5, x_io_out_bits_uop_exceptionVec_5;
  wire               g_io_out_bits_uop_exceptionVec_13, x_io_out_bits_uop_exceptionVec_13;
  wire               g_io_out_bits_uop_exceptionVec_19, x_io_out_bits_uop_exceptionVec_19;
  wire               g_io_out_bits_uop_exceptionVec_21, x_io_out_bits_uop_exceptionVec_21;
  wire               g_io_out_bits_uop_isFetchMalAddr, x_io_out_bits_uop_isFetchMalAddr;
  wire               g_io_out_bits_uop_hasException, x_io_out_bits_uop_hasException;
  wire [3:0]         g_io_out_bits_uop_trigger, x_io_out_bits_uop_trigger;
  wire               g_io_out_bits_uop_preDecodeInfo_valid, x_io_out_bits_uop_preDecodeInfo_valid;
  wire               g_io_out_bits_uop_preDecodeInfo_isRVC, x_io_out_bits_uop_preDecodeInfo_isRVC;
  wire [1:0]         g_io_out_bits_uop_preDecodeInfo_brType, x_io_out_bits_uop_preDecodeInfo_brType;
  wire               g_io_out_bits_uop_preDecodeInfo_isCall, x_io_out_bits_uop_preDecodeInfo_isCall;
  wire               g_io_out_bits_uop_preDecodeInfo_isRet, x_io_out_bits_uop_preDecodeInfo_isRet;
  wire               g_io_out_bits_uop_pred_taken, x_io_out_bits_uop_pred_taken;
  wire               g_io_out_bits_uop_crossPageIPFFix, x_io_out_bits_uop_crossPageIPFFix;
  wire               g_io_out_bits_uop_ftqPtr_flag, x_io_out_bits_uop_ftqPtr_flag;
  wire [5:0]         g_io_out_bits_uop_ftqPtr_value, x_io_out_bits_uop_ftqPtr_value;
  wire [3:0]         g_io_out_bits_uop_ftqOffset, x_io_out_bits_uop_ftqOffset;
  wire               g_io_out_bits_uop_satpFlushFirstFetchFault, x_io_out_bits_uop_satpFlushFirstFetchFault;
  wire [3:0]         g_io_out_bits_uop_srcType_0, x_io_out_bits_uop_srcType_0;
  wire [3:0]         g_io_out_bits_uop_srcType_1, x_io_out_bits_uop_srcType_1;
  wire [3:0]         g_io_out_bits_uop_srcType_2, x_io_out_bits_uop_srcType_2;
  wire [3:0]         g_io_out_bits_uop_srcType_3, x_io_out_bits_uop_srcType_3;
  wire [3:0]         g_io_out_bits_uop_srcType_4, x_io_out_bits_uop_srcType_4;
  wire [5:0]         g_io_out_bits_uop_ldest, x_io_out_bits_uop_ldest;
  wire [8:0]         g_io_out_bits_uop_fuOpType, x_io_out_bits_uop_fuOpType;
  wire               g_io_out_bits_uop_rfWen, x_io_out_bits_uop_rfWen;
  wire               g_io_out_bits_uop_fpWen, x_io_out_bits_uop_fpWen;
  wire               g_io_out_bits_uop_vecWen, x_io_out_bits_uop_vecWen;
  wire               g_io_out_bits_uop_v0Wen, x_io_out_bits_uop_v0Wen;
  wire               g_io_out_bits_uop_vlWen, x_io_out_bits_uop_vlWen;
  wire               g_io_out_bits_uop_isXSTrap, x_io_out_bits_uop_isXSTrap;
  wire               g_io_out_bits_uop_waitForward, x_io_out_bits_uop_waitForward;
  wire               g_io_out_bits_uop_blockBackward, x_io_out_bits_uop_blockBackward;
  wire               g_io_out_bits_uop_canRobCompress, x_io_out_bits_uop_canRobCompress;
  wire [3:0]         g_io_out_bits_uop_selImm, x_io_out_bits_uop_selImm;
  wire [1:0]         g_io_out_bits_uop_fpu_typeTagOut, x_io_out_bits_uop_fpu_typeTagOut;
  wire               g_io_out_bits_uop_fpu_wflags, x_io_out_bits_uop_fpu_wflags;
  wire [1:0]         g_io_out_bits_uop_fpu_typ, x_io_out_bits_uop_fpu_typ;
  wire [1:0]         g_io_out_bits_uop_fpu_fmt, x_io_out_bits_uop_fpu_fmt;
  wire [2:0]         g_io_out_bits_uop_fpu_rm, x_io_out_bits_uop_fpu_rm;
  wire               g_io_out_bits_uop_vpu_vill, x_io_out_bits_uop_vpu_vill;
  wire               g_io_out_bits_uop_vpu_vma, x_io_out_bits_uop_vpu_vma;
  wire               g_io_out_bits_uop_vpu_vta, x_io_out_bits_uop_vpu_vta;
  wire [1:0]         g_io_out_bits_uop_vpu_vsew, x_io_out_bits_uop_vpu_vsew;
  wire [2:0]         g_io_out_bits_uop_vpu_vlmul, x_io_out_bits_uop_vpu_vlmul;
  wire               g_io_out_bits_uop_vpu_specVill, x_io_out_bits_uop_vpu_specVill;
  wire               g_io_out_bits_uop_vpu_specVma, x_io_out_bits_uop_vpu_specVma;
  wire               g_io_out_bits_uop_vpu_specVta, x_io_out_bits_uop_vpu_specVta;
  wire [1:0]         g_io_out_bits_uop_vpu_specVsew, x_io_out_bits_uop_vpu_specVsew;
  wire [2:0]         g_io_out_bits_uop_vpu_specVlmul, x_io_out_bits_uop_vpu_specVlmul;
  wire               g_io_out_bits_uop_vpu_vm, x_io_out_bits_uop_vpu_vm;
  wire [7:0]         g_io_out_bits_uop_vpu_vstart, x_io_out_bits_uop_vpu_vstart;
  wire [2:0]         g_io_out_bits_uop_vpu_frm, x_io_out_bits_uop_vpu_frm;
  wire               g_io_out_bits_uop_vpu_fpu_isFpToVecInst, x_io_out_bits_uop_vpu_fpu_isFpToVecInst;
  wire               g_io_out_bits_uop_vpu_fpu_isFP32Instr, x_io_out_bits_uop_vpu_fpu_isFP32Instr;
  wire               g_io_out_bits_uop_vpu_fpu_isFP64Instr, x_io_out_bits_uop_vpu_fpu_isFP64Instr;
  wire               g_io_out_bits_uop_vpu_fpu_isReduction, x_io_out_bits_uop_vpu_fpu_isReduction;
  wire               g_io_out_bits_uop_vpu_fpu_isFoldTo1_2, x_io_out_bits_uop_vpu_fpu_isFoldTo1_2;
  wire               g_io_out_bits_uop_vpu_fpu_isFoldTo1_4, x_io_out_bits_uop_vpu_fpu_isFoldTo1_4;
  wire               g_io_out_bits_uop_vpu_fpu_isFoldTo1_8, x_io_out_bits_uop_vpu_fpu_isFoldTo1_8;
  wire [1:0]         g_io_out_bits_uop_vpu_vxrm, x_io_out_bits_uop_vpu_vxrm;
  wire [6:0]         g_io_out_bits_uop_vpu_vuopIdx, x_io_out_bits_uop_vpu_vuopIdx;
  wire               g_io_out_bits_uop_vpu_lastUop, x_io_out_bits_uop_vpu_lastUop;
  wire [127:0]       g_io_out_bits_uop_vpu_vmask, x_io_out_bits_uop_vpu_vmask;
  wire [7:0]         g_io_out_bits_uop_vpu_vl, x_io_out_bits_uop_vpu_vl;
  wire [2:0]         g_io_out_bits_uop_vpu_nf, x_io_out_bits_uop_vpu_nf;
  wire [1:0]         g_io_out_bits_uop_vpu_veew, x_io_out_bits_uop_vpu_veew;
  wire               g_io_out_bits_uop_vpu_isReverse, x_io_out_bits_uop_vpu_isReverse;
  wire               g_io_out_bits_uop_vpu_isExt, x_io_out_bits_uop_vpu_isExt;
  wire               g_io_out_bits_uop_vpu_isNarrow, x_io_out_bits_uop_vpu_isNarrow;
  wire               g_io_out_bits_uop_vpu_isDstMask, x_io_out_bits_uop_vpu_isDstMask;
  wire               g_io_out_bits_uop_vpu_isOpMask, x_io_out_bits_uop_vpu_isOpMask;
  wire               g_io_out_bits_uop_vpu_isMove, x_io_out_bits_uop_vpu_isMove;
  wire               g_io_out_bits_uop_vpu_isDependOldVd, x_io_out_bits_uop_vpu_isDependOldVd;
  wire               g_io_out_bits_uop_vpu_isWritePartVd, x_io_out_bits_uop_vpu_isWritePartVd;
  wire               g_io_out_bits_uop_vpu_isVleff, x_io_out_bits_uop_vpu_isVleff;
  wire               g_io_out_bits_uop_vlsInstr, x_io_out_bits_uop_vlsInstr;
  wire               g_io_out_bits_uop_wfflags, x_io_out_bits_uop_wfflags;
  wire               g_io_out_bits_uop_isMove, x_io_out_bits_uop_isMove;
  wire               g_io_out_bits_uop_isDropAmocasSta, x_io_out_bits_uop_isDropAmocasSta;
  wire [6:0]         g_io_out_bits_uop_uopIdx, x_io_out_bits_uop_uopIdx;
  wire               g_io_out_bits_uop_isVset, x_io_out_bits_uop_isVset;
  wire               g_io_out_bits_uop_firstUop, x_io_out_bits_uop_firstUop;
  wire               g_io_out_bits_uop_lastUop, x_io_out_bits_uop_lastUop;
  wire [6:0]         g_io_out_bits_uop_numUops, x_io_out_bits_uop_numUops;
  wire [6:0]         g_io_out_bits_uop_numWB, x_io_out_bits_uop_numWB;
  wire [2:0]         g_io_out_bits_uop_commitType, x_io_out_bits_uop_commitType;
  wire               g_io_out_bits_uop_srcState_0, x_io_out_bits_uop_srcState_0;
  wire               g_io_out_bits_uop_srcState_1, x_io_out_bits_uop_srcState_1;
  wire               g_io_out_bits_uop_srcState_2, x_io_out_bits_uop_srcState_2;
  wire               g_io_out_bits_uop_srcState_3, x_io_out_bits_uop_srcState_3;
  wire               g_io_out_bits_uop_srcState_4, x_io_out_bits_uop_srcState_4;
  wire [1:0]         g_io_out_bits_uop_srcLoadDependency_0_0, x_io_out_bits_uop_srcLoadDependency_0_0;
  wire [1:0]         g_io_out_bits_uop_srcLoadDependency_0_1, x_io_out_bits_uop_srcLoadDependency_0_1;
  wire [1:0]         g_io_out_bits_uop_srcLoadDependency_0_2, x_io_out_bits_uop_srcLoadDependency_0_2;
  wire [1:0]         g_io_out_bits_uop_srcLoadDependency_1_0, x_io_out_bits_uop_srcLoadDependency_1_0;
  wire [1:0]         g_io_out_bits_uop_srcLoadDependency_1_1, x_io_out_bits_uop_srcLoadDependency_1_1;
  wire [1:0]         g_io_out_bits_uop_srcLoadDependency_1_2, x_io_out_bits_uop_srcLoadDependency_1_2;
  wire [1:0]         g_io_out_bits_uop_srcLoadDependency_2_0, x_io_out_bits_uop_srcLoadDependency_2_0;
  wire [1:0]         g_io_out_bits_uop_srcLoadDependency_2_1, x_io_out_bits_uop_srcLoadDependency_2_1;
  wire [1:0]         g_io_out_bits_uop_srcLoadDependency_2_2, x_io_out_bits_uop_srcLoadDependency_2_2;
  wire [1:0]         g_io_out_bits_uop_srcLoadDependency_3_0, x_io_out_bits_uop_srcLoadDependency_3_0;
  wire [1:0]         g_io_out_bits_uop_srcLoadDependency_3_1, x_io_out_bits_uop_srcLoadDependency_3_1;
  wire [1:0]         g_io_out_bits_uop_srcLoadDependency_3_2, x_io_out_bits_uop_srcLoadDependency_3_2;
  wire [1:0]         g_io_out_bits_uop_srcLoadDependency_4_0, x_io_out_bits_uop_srcLoadDependency_4_0;
  wire [1:0]         g_io_out_bits_uop_srcLoadDependency_4_1, x_io_out_bits_uop_srcLoadDependency_4_1;
  wire [1:0]         g_io_out_bits_uop_srcLoadDependency_4_2, x_io_out_bits_uop_srcLoadDependency_4_2;
  wire [7:0]         g_io_out_bits_uop_psrc_0, x_io_out_bits_uop_psrc_0;
  wire [7:0]         g_io_out_bits_uop_psrc_1, x_io_out_bits_uop_psrc_1;
  wire [7:0]         g_io_out_bits_uop_psrc_2, x_io_out_bits_uop_psrc_2;
  wire [7:0]         g_io_out_bits_uop_psrc_3, x_io_out_bits_uop_psrc_3;
  wire [7:0]         g_io_out_bits_uop_psrc_4, x_io_out_bits_uop_psrc_4;
  wire [7:0]         g_io_out_bits_uop_pdest, x_io_out_bits_uop_pdest;
  wire               g_io_out_bits_uop_useRegCache_0, x_io_out_bits_uop_useRegCache_0;
  wire               g_io_out_bits_uop_useRegCache_1, x_io_out_bits_uop_useRegCache_1;
  wire [4:0]         g_io_out_bits_uop_regCacheIdx_0, x_io_out_bits_uop_regCacheIdx_0;
  wire [4:0]         g_io_out_bits_uop_regCacheIdx_1, x_io_out_bits_uop_regCacheIdx_1;
  wire               g_io_out_bits_uop_robIdx_flag, x_io_out_bits_uop_robIdx_flag;
  wire [7:0]         g_io_out_bits_uop_robIdx_value, x_io_out_bits_uop_robIdx_value;
  wire [2:0]         g_io_out_bits_uop_instrSize, x_io_out_bits_uop_instrSize;
  wire               g_io_out_bits_uop_dirtyFs, x_io_out_bits_uop_dirtyFs;
  wire               g_io_out_bits_uop_dirtyVs, x_io_out_bits_uop_dirtyVs;
  wire [3:0]         g_io_out_bits_uop_traceBlockInPipe_itype, x_io_out_bits_uop_traceBlockInPipe_itype;
  wire [3:0]         g_io_out_bits_uop_traceBlockInPipe_iretire, x_io_out_bits_uop_traceBlockInPipe_iretire;
  wire               g_io_out_bits_uop_traceBlockInPipe_ilastsize, x_io_out_bits_uop_traceBlockInPipe_ilastsize;
  wire               g_io_out_bits_uop_eliminatedMove, x_io_out_bits_uop_eliminatedMove;
  wire               g_io_out_bits_uop_snapshot, x_io_out_bits_uop_snapshot;
  wire               g_io_out_bits_uop_debugInfo_eliminatedMove, x_io_out_bits_uop_debugInfo_eliminatedMove;
  wire [63:0]        g_io_out_bits_uop_debugInfo_renameTime, x_io_out_bits_uop_debugInfo_renameTime;
  wire [63:0]        g_io_out_bits_uop_debugInfo_dispatchTime, x_io_out_bits_uop_debugInfo_dispatchTime;
  wire [63:0]        g_io_out_bits_uop_debugInfo_enqRsTime, x_io_out_bits_uop_debugInfo_enqRsTime;
  wire [63:0]        g_io_out_bits_uop_debugInfo_selectTime, x_io_out_bits_uop_debugInfo_selectTime;
  wire [63:0]        g_io_out_bits_uop_debugInfo_issueTime, x_io_out_bits_uop_debugInfo_issueTime;
  wire [63:0]        g_io_out_bits_uop_debugInfo_writebackTime, x_io_out_bits_uop_debugInfo_writebackTime;
  wire [63:0]        g_io_out_bits_uop_debugInfo_runahead_checkpoint_id, x_io_out_bits_uop_debugInfo_runahead_checkpoint_id;
  wire [63:0]        g_io_out_bits_uop_debugInfo_tlbFirstReqTime, x_io_out_bits_uop_debugInfo_tlbFirstReqTime;
  wire [63:0]        g_io_out_bits_uop_debugInfo_tlbRespTime, x_io_out_bits_uop_debugInfo_tlbRespTime;
  wire [55:0]        g_io_out_bits_uop_debug_seqNum_seqNum, x_io_out_bits_uop_debug_seqNum_seqNum;
  wire [7:0]         g_io_out_bits_uop_debug_seqNum_uopIdx, x_io_out_bits_uop_debug_seqNum_uopIdx;
  wire               g_io_out_bits_uop_storeSetHit, x_io_out_bits_uop_storeSetHit;
  wire               g_io_out_bits_uop_waitForRobIdx_flag, x_io_out_bits_uop_waitForRobIdx_flag;
  wire [7:0]         g_io_out_bits_uop_waitForRobIdx_value, x_io_out_bits_uop_waitForRobIdx_value;
  wire               g_io_out_bits_uop_loadWaitBit, x_io_out_bits_uop_loadWaitBit;
  wire               g_io_out_bits_uop_loadWaitStrict, x_io_out_bits_uop_loadWaitStrict;
  wire [4:0]         g_io_out_bits_uop_ssid, x_io_out_bits_uop_ssid;
  wire               g_io_out_bits_uop_lqIdx_flag, x_io_out_bits_uop_lqIdx_flag;
  wire [6:0]         g_io_out_bits_uop_lqIdx_value, x_io_out_bits_uop_lqIdx_value;
  wire               g_io_out_bits_uop_sqIdx_flag, x_io_out_bits_uop_sqIdx_flag;
  wire [5:0]         g_io_out_bits_uop_sqIdx_value, x_io_out_bits_uop_sqIdx_value;
  wire               g_io_out_bits_uop_singleStep, x_io_out_bits_uop_singleStep;
  wire               g_io_out_bits_uop_replayInst, x_io_out_bits_uop_replayInst;
  wire [34:0]        g_io_out_bits_uop_debug_fuType, x_io_out_bits_uop_debug_fuType;
  wire               g_io_out_bits_uop_debug_sim_trig, x_io_out_bits_uop_debug_sim_trig;
  wire [4:0]         g_io_out_bits_uop_numLsElem, x_io_out_bits_uop_numLsElem;
  wire [3:0]         g_io_out_bits_mBIndex, x_io_out_bits_mBIndex;
  wire [7:0]         g_io_out_bits_elemIdx, x_io_out_bits_elemIdx;
  wire [7:0]         g_io_out_bits_elemIdxInsideVd, x_io_out_bits_elemIdxInsideVd;
  wire [4:0]         g_io_out_bits_splitIndex, x_io_out_bits_splitIndex;

  VLSplitImp u_golden (
    .clock (clock),
    .reset (reset),
    .io_redirect_valid (io_redirect_valid),
    .io_redirect_bits_robIdx_flag (io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value (io_redirect_bits_robIdx_value),
    .io_redirect_bits_level (io_redirect_bits_level),
    .io_in_ready (g_io_in_ready),
    .io_in_valid (io_in_valid),
    .io_in_bits_uop_pc (io_in_bits_uop_pc),
    .io_in_bits_uop_ftqPtr_flag (io_in_bits_uop_ftqPtr_flag),
    .io_in_bits_uop_ftqPtr_value (io_in_bits_uop_ftqPtr_value),
    .io_in_bits_uop_ftqOffset (io_in_bits_uop_ftqOffset),
    .io_in_bits_uop_fuType (io_in_bits_uop_fuType),
    .io_in_bits_uop_fuOpType (io_in_bits_uop_fuOpType),
    .io_in_bits_uop_vecWen (io_in_bits_uop_vecWen),
    .io_in_bits_uop_v0Wen (io_in_bits_uop_v0Wen),
    .io_in_bits_uop_vlWen (io_in_bits_uop_vlWen),
    .io_in_bits_uop_vpu_vill (io_in_bits_uop_vpu_vill),
    .io_in_bits_uop_vpu_vma (io_in_bits_uop_vpu_vma),
    .io_in_bits_uop_vpu_vta (io_in_bits_uop_vpu_vta),
    .io_in_bits_uop_vpu_vsew (io_in_bits_uop_vpu_vsew),
    .io_in_bits_uop_vpu_vlmul (io_in_bits_uop_vpu_vlmul),
    .io_in_bits_uop_vpu_specVill (io_in_bits_uop_vpu_specVill),
    .io_in_bits_uop_vpu_specVma (io_in_bits_uop_vpu_specVma),
    .io_in_bits_uop_vpu_specVta (io_in_bits_uop_vpu_specVta),
    .io_in_bits_uop_vpu_specVsew (io_in_bits_uop_vpu_specVsew),
    .io_in_bits_uop_vpu_specVlmul (io_in_bits_uop_vpu_specVlmul),
    .io_in_bits_uop_vpu_vm (io_in_bits_uop_vpu_vm),
    .io_in_bits_uop_vpu_vstart (io_in_bits_uop_vpu_vstart),
    .io_in_bits_uop_vpu_frm (io_in_bits_uop_vpu_frm),
    .io_in_bits_uop_vpu_fpu_isFpToVecInst (io_in_bits_uop_vpu_fpu_isFpToVecInst),
    .io_in_bits_uop_vpu_fpu_isFP32Instr (io_in_bits_uop_vpu_fpu_isFP32Instr),
    .io_in_bits_uop_vpu_fpu_isFP64Instr (io_in_bits_uop_vpu_fpu_isFP64Instr),
    .io_in_bits_uop_vpu_fpu_isReduction (io_in_bits_uop_vpu_fpu_isReduction),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_2 (io_in_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_4 (io_in_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_8 (io_in_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_in_bits_uop_vpu_vxrm (io_in_bits_uop_vpu_vxrm),
    .io_in_bits_uop_vpu_vuopIdx (io_in_bits_uop_vpu_vuopIdx),
    .io_in_bits_uop_vpu_lastUop (io_in_bits_uop_vpu_lastUop),
    .io_in_bits_uop_vpu_vmask (io_in_bits_uop_vpu_vmask),
    .io_in_bits_uop_vpu_nf (io_in_bits_uop_vpu_nf),
    .io_in_bits_uop_vpu_veew (io_in_bits_uop_vpu_veew),
    .io_in_bits_uop_vpu_isReverse (io_in_bits_uop_vpu_isReverse),
    .io_in_bits_uop_vpu_isExt (io_in_bits_uop_vpu_isExt),
    .io_in_bits_uop_vpu_isNarrow (io_in_bits_uop_vpu_isNarrow),
    .io_in_bits_uop_vpu_isDstMask (io_in_bits_uop_vpu_isDstMask),
    .io_in_bits_uop_vpu_isOpMask (io_in_bits_uop_vpu_isOpMask),
    .io_in_bits_uop_vpu_isMove (io_in_bits_uop_vpu_isMove),
    .io_in_bits_uop_vpu_isDependOldVd (io_in_bits_uop_vpu_isDependOldVd),
    .io_in_bits_uop_vpu_isWritePartVd (io_in_bits_uop_vpu_isWritePartVd),
    .io_in_bits_uop_vpu_isVleff (io_in_bits_uop_vpu_isVleff),
    .io_in_bits_uop_pdest (io_in_bits_uop_pdest),
    .io_in_bits_uop_robIdx_flag (io_in_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value (io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_debugInfo_eliminatedMove (io_in_bits_uop_debugInfo_eliminatedMove),
    .io_in_bits_uop_debugInfo_renameTime (io_in_bits_uop_debugInfo_renameTime),
    .io_in_bits_uop_debugInfo_dispatchTime (io_in_bits_uop_debugInfo_dispatchTime),
    .io_in_bits_uop_debugInfo_enqRsTime (io_in_bits_uop_debugInfo_enqRsTime),
    .io_in_bits_uop_debugInfo_selectTime (io_in_bits_uop_debugInfo_selectTime),
    .io_in_bits_uop_debugInfo_issueTime (io_in_bits_uop_debugInfo_issueTime),
    .io_in_bits_uop_debugInfo_writebackTime (io_in_bits_uop_debugInfo_writebackTime),
    .io_in_bits_uop_debugInfo_runahead_checkpoint_id (io_in_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_in_bits_uop_debugInfo_tlbFirstReqTime (io_in_bits_uop_debugInfo_tlbFirstReqTime),
    .io_in_bits_uop_debugInfo_tlbRespTime (io_in_bits_uop_debugInfo_tlbRespTime),
    .io_in_bits_uop_debug_seqNum_seqNum (io_in_bits_uop_debug_seqNum_seqNum),
    .io_in_bits_uop_debug_seqNum_uopIdx (io_in_bits_uop_debug_seqNum_uopIdx),
    .io_in_bits_uop_lqIdx_flag (io_in_bits_uop_lqIdx_flag),
    .io_in_bits_uop_lqIdx_value (io_in_bits_uop_lqIdx_value),
    .io_in_bits_uop_sqIdx_flag (io_in_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value (io_in_bits_uop_sqIdx_value),
    .io_in_bits_uop_numLsElem (io_in_bits_uop_numLsElem),
    .io_in_bits_src_0 (io_in_bits_src_0),
    .io_in_bits_src_1 (io_in_bits_src_1),
    .io_in_bits_src_2 (io_in_bits_src_2),
    .io_in_bits_src_3 (io_in_bits_src_3),
    .io_in_bits_src_4 (io_in_bits_src_4),
    .io_in_bits_flowNum (io_in_bits_flowNum),
    .io_in_bits_isVecPartReplay (io_in_bits_isVecPartReplay),
    .io_in_bits_vecReplayMask (io_in_bits_vecReplayMask),
    .io_in_bits_vecReplayMbIdx (io_in_bits_vecReplayMbIdx),
    .io_toMergeBuffer_req_ready (io_toMergeBuffer_req_ready),
    .io_toMergeBuffer_req_valid (g_io_toMergeBuffer_req_valid),
    .io_toMergeBuffer_req_bits_mask (g_io_toMergeBuffer_req_bits_mask),
    .io_toMergeBuffer_req_bits_vaddr (g_io_toMergeBuffer_req_bits_vaddr),
    .io_toMergeBuffer_req_bits_flowNum (g_io_toMergeBuffer_req_bits_flowNum),
    .io_toMergeBuffer_req_bits_uop_fuOpType (g_io_toMergeBuffer_req_bits_uop_fuOpType),
    .io_toMergeBuffer_req_bits_uop_vecWen (g_io_toMergeBuffer_req_bits_uop_vecWen),
    .io_toMergeBuffer_req_bits_uop_v0Wen (g_io_toMergeBuffer_req_bits_uop_v0Wen),
    .io_toMergeBuffer_req_bits_uop_vlWen (g_io_toMergeBuffer_req_bits_uop_vlWen),
    .io_toMergeBuffer_req_bits_uop_vpu_vill (g_io_toMergeBuffer_req_bits_uop_vpu_vill),
    .io_toMergeBuffer_req_bits_uop_vpu_vma (g_io_toMergeBuffer_req_bits_uop_vpu_vma),
    .io_toMergeBuffer_req_bits_uop_vpu_vta (g_io_toMergeBuffer_req_bits_uop_vpu_vta),
    .io_toMergeBuffer_req_bits_uop_vpu_vsew (g_io_toMergeBuffer_req_bits_uop_vpu_vsew),
    .io_toMergeBuffer_req_bits_uop_vpu_vlmul (g_io_toMergeBuffer_req_bits_uop_vpu_vlmul),
    .io_toMergeBuffer_req_bits_uop_vpu_specVill (g_io_toMergeBuffer_req_bits_uop_vpu_specVill),
    .io_toMergeBuffer_req_bits_uop_vpu_specVma (g_io_toMergeBuffer_req_bits_uop_vpu_specVma),
    .io_toMergeBuffer_req_bits_uop_vpu_specVta (g_io_toMergeBuffer_req_bits_uop_vpu_specVta),
    .io_toMergeBuffer_req_bits_uop_vpu_specVsew (g_io_toMergeBuffer_req_bits_uop_vpu_specVsew),
    .io_toMergeBuffer_req_bits_uop_vpu_specVlmul (g_io_toMergeBuffer_req_bits_uop_vpu_specVlmul),
    .io_toMergeBuffer_req_bits_uop_vpu_vm (g_io_toMergeBuffer_req_bits_uop_vpu_vm),
    .io_toMergeBuffer_req_bits_uop_vpu_frm (g_io_toMergeBuffer_req_bits_uop_vpu_frm),
    .io_toMergeBuffer_req_bits_uop_vpu_fpu_isFpToVecInst (g_io_toMergeBuffer_req_bits_uop_vpu_fpu_isFpToVecInst),
    .io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP32Instr (g_io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP32Instr),
    .io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP64Instr (g_io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP64Instr),
    .io_toMergeBuffer_req_bits_uop_vpu_fpu_isReduction (g_io_toMergeBuffer_req_bits_uop_vpu_fpu_isReduction),
    .io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_2 (g_io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_4 (g_io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_8 (g_io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_toMergeBuffer_req_bits_uop_vpu_vxrm (g_io_toMergeBuffer_req_bits_uop_vpu_vxrm),
    .io_toMergeBuffer_req_bits_uop_vpu_vuopIdx (g_io_toMergeBuffer_req_bits_uop_vpu_vuopIdx),
    .io_toMergeBuffer_req_bits_uop_vpu_lastUop (g_io_toMergeBuffer_req_bits_uop_vpu_lastUop),
    .io_toMergeBuffer_req_bits_uop_vpu_vl (g_io_toMergeBuffer_req_bits_uop_vpu_vl),
    .io_toMergeBuffer_req_bits_uop_vpu_nf (g_io_toMergeBuffer_req_bits_uop_vpu_nf),
    .io_toMergeBuffer_req_bits_uop_vpu_veew (g_io_toMergeBuffer_req_bits_uop_vpu_veew),
    .io_toMergeBuffer_req_bits_uop_vpu_isReverse (g_io_toMergeBuffer_req_bits_uop_vpu_isReverse),
    .io_toMergeBuffer_req_bits_uop_vpu_isExt (g_io_toMergeBuffer_req_bits_uop_vpu_isExt),
    .io_toMergeBuffer_req_bits_uop_vpu_isNarrow (g_io_toMergeBuffer_req_bits_uop_vpu_isNarrow),
    .io_toMergeBuffer_req_bits_uop_vpu_isDstMask (g_io_toMergeBuffer_req_bits_uop_vpu_isDstMask),
    .io_toMergeBuffer_req_bits_uop_vpu_isOpMask (g_io_toMergeBuffer_req_bits_uop_vpu_isOpMask),
    .io_toMergeBuffer_req_bits_uop_vpu_isMove (g_io_toMergeBuffer_req_bits_uop_vpu_isMove),
    .io_toMergeBuffer_req_bits_uop_vpu_isDependOldVd (g_io_toMergeBuffer_req_bits_uop_vpu_isDependOldVd),
    .io_toMergeBuffer_req_bits_uop_vpu_isWritePartVd (g_io_toMergeBuffer_req_bits_uop_vpu_isWritePartVd),
    .io_toMergeBuffer_req_bits_uop_vpu_isVleff (g_io_toMergeBuffer_req_bits_uop_vpu_isVleff),
    .io_toMergeBuffer_req_bits_uop_uopIdx (g_io_toMergeBuffer_req_bits_uop_uopIdx),
    .io_toMergeBuffer_req_bits_uop_pdest (g_io_toMergeBuffer_req_bits_uop_pdest),
    .io_toMergeBuffer_req_bits_uop_robIdx_flag (g_io_toMergeBuffer_req_bits_uop_robIdx_flag),
    .io_toMergeBuffer_req_bits_uop_robIdx_value (g_io_toMergeBuffer_req_bits_uop_robIdx_value),
    .io_toMergeBuffer_req_bits_uop_debugInfo_eliminatedMove (g_io_toMergeBuffer_req_bits_uop_debugInfo_eliminatedMove),
    .io_toMergeBuffer_req_bits_uop_debugInfo_renameTime (g_io_toMergeBuffer_req_bits_uop_debugInfo_renameTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_dispatchTime (g_io_toMergeBuffer_req_bits_uop_debugInfo_dispatchTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime (g_io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_selectTime (g_io_toMergeBuffer_req_bits_uop_debugInfo_selectTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_issueTime (g_io_toMergeBuffer_req_bits_uop_debugInfo_issueTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_writebackTime (g_io_toMergeBuffer_req_bits_uop_debugInfo_writebackTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_runahead_checkpoint_id (g_io_toMergeBuffer_req_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_toMergeBuffer_req_bits_uop_debugInfo_tlbFirstReqTime (g_io_toMergeBuffer_req_bits_uop_debugInfo_tlbFirstReqTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_tlbRespTime (g_io_toMergeBuffer_req_bits_uop_debugInfo_tlbRespTime),
    .io_toMergeBuffer_req_bits_uop_debug_seqNum_seqNum (g_io_toMergeBuffer_req_bits_uop_debug_seqNum_seqNum),
    .io_toMergeBuffer_req_bits_uop_debug_seqNum_uopIdx (g_io_toMergeBuffer_req_bits_uop_debug_seqNum_uopIdx),
    .io_toMergeBuffer_req_bits_uop_lqIdx_flag (g_io_toMergeBuffer_req_bits_uop_lqIdx_flag),
    .io_toMergeBuffer_req_bits_uop_lqIdx_value (g_io_toMergeBuffer_req_bits_uop_lqIdx_value),
    .io_toMergeBuffer_req_bits_uop_sqIdx_flag (g_io_toMergeBuffer_req_bits_uop_sqIdx_flag),
    .io_toMergeBuffer_req_bits_uop_sqIdx_value (g_io_toMergeBuffer_req_bits_uop_sqIdx_value),
    .io_toMergeBuffer_req_bits_data (g_io_toMergeBuffer_req_bits_data),
    .io_toMergeBuffer_req_bits_vdIdx (g_io_toMergeBuffer_req_bits_vdIdx),
    .io_toMergeBuffer_req_bits_fof (g_io_toMergeBuffer_req_bits_fof),
    .io_toMergeBuffer_req_bits_vlmax (g_io_toMergeBuffer_req_bits_vlmax),
    .io_toMergeBuffer_resp_valid (io_toMergeBuffer_resp_valid),
    .io_toMergeBuffer_resp_bits_mBIndex (io_toMergeBuffer_resp_bits_mBIndex),
    .io_out_ready (io_out_ready),
    .io_out_valid (g_io_out_valid),
    .io_out_bits_vaddr (g_io_out_bits_vaddr),
    .io_out_bits_basevaddr (g_io_out_bits_basevaddr),
    .io_out_bits_mask (g_io_out_bits_mask),
    .io_out_bits_reg_offset (g_io_out_bits_reg_offset),
    .io_out_bits_alignedType (g_io_out_bits_alignedType),
    .io_out_bits_vecActive (g_io_out_bits_vecActive),
    .io_out_bits_vecIsFirstActiveElement (g_io_out_bits_vecIsFirstActiveElement),
    .io_out_bits_uop_instr (g_io_out_bits_uop_instr),
    .io_out_bits_uop_pc (g_io_out_bits_uop_pc),
    .io_out_bits_uop_foldpc (g_io_out_bits_uop_foldpc),
    .io_out_bits_uop_exceptionVec_4 (g_io_out_bits_uop_exceptionVec_4),
    .io_out_bits_uop_exceptionVec_5 (g_io_out_bits_uop_exceptionVec_5),
    .io_out_bits_uop_exceptionVec_13 (g_io_out_bits_uop_exceptionVec_13),
    .io_out_bits_uop_exceptionVec_19 (g_io_out_bits_uop_exceptionVec_19),
    .io_out_bits_uop_exceptionVec_21 (g_io_out_bits_uop_exceptionVec_21),
    .io_out_bits_uop_isFetchMalAddr (g_io_out_bits_uop_isFetchMalAddr),
    .io_out_bits_uop_hasException (g_io_out_bits_uop_hasException),
    .io_out_bits_uop_trigger (g_io_out_bits_uop_trigger),
    .io_out_bits_uop_preDecodeInfo_valid (g_io_out_bits_uop_preDecodeInfo_valid),
    .io_out_bits_uop_preDecodeInfo_isRVC (g_io_out_bits_uop_preDecodeInfo_isRVC),
    .io_out_bits_uop_preDecodeInfo_brType (g_io_out_bits_uop_preDecodeInfo_brType),
    .io_out_bits_uop_preDecodeInfo_isCall (g_io_out_bits_uop_preDecodeInfo_isCall),
    .io_out_bits_uop_preDecodeInfo_isRet (g_io_out_bits_uop_preDecodeInfo_isRet),
    .io_out_bits_uop_pred_taken (g_io_out_bits_uop_pred_taken),
    .io_out_bits_uop_crossPageIPFFix (g_io_out_bits_uop_crossPageIPFFix),
    .io_out_bits_uop_ftqPtr_flag (g_io_out_bits_uop_ftqPtr_flag),
    .io_out_bits_uop_ftqPtr_value (g_io_out_bits_uop_ftqPtr_value),
    .io_out_bits_uop_ftqOffset (g_io_out_bits_uop_ftqOffset),
    .io_out_bits_uop_satpFlushFirstFetchFault (g_io_out_bits_uop_satpFlushFirstFetchFault),
    .io_out_bits_uop_srcType_0 (g_io_out_bits_uop_srcType_0),
    .io_out_bits_uop_srcType_1 (g_io_out_bits_uop_srcType_1),
    .io_out_bits_uop_srcType_2 (g_io_out_bits_uop_srcType_2),
    .io_out_bits_uop_srcType_3 (g_io_out_bits_uop_srcType_3),
    .io_out_bits_uop_srcType_4 (g_io_out_bits_uop_srcType_4),
    .io_out_bits_uop_ldest (g_io_out_bits_uop_ldest),
    .io_out_bits_uop_fuOpType (g_io_out_bits_uop_fuOpType),
    .io_out_bits_uop_rfWen (g_io_out_bits_uop_rfWen),
    .io_out_bits_uop_fpWen (g_io_out_bits_uop_fpWen),
    .io_out_bits_uop_vecWen (g_io_out_bits_uop_vecWen),
    .io_out_bits_uop_v0Wen (g_io_out_bits_uop_v0Wen),
    .io_out_bits_uop_vlWen (g_io_out_bits_uop_vlWen),
    .io_out_bits_uop_isXSTrap (g_io_out_bits_uop_isXSTrap),
    .io_out_bits_uop_waitForward (g_io_out_bits_uop_waitForward),
    .io_out_bits_uop_blockBackward (g_io_out_bits_uop_blockBackward),
    .io_out_bits_uop_canRobCompress (g_io_out_bits_uop_canRobCompress),
    .io_out_bits_uop_selImm (g_io_out_bits_uop_selImm),
    .io_out_bits_uop_fpu_typeTagOut (g_io_out_bits_uop_fpu_typeTagOut),
    .io_out_bits_uop_fpu_wflags (g_io_out_bits_uop_fpu_wflags),
    .io_out_bits_uop_fpu_typ (g_io_out_bits_uop_fpu_typ),
    .io_out_bits_uop_fpu_fmt (g_io_out_bits_uop_fpu_fmt),
    .io_out_bits_uop_fpu_rm (g_io_out_bits_uop_fpu_rm),
    .io_out_bits_uop_vpu_vill (g_io_out_bits_uop_vpu_vill),
    .io_out_bits_uop_vpu_vma (g_io_out_bits_uop_vpu_vma),
    .io_out_bits_uop_vpu_vta (g_io_out_bits_uop_vpu_vta),
    .io_out_bits_uop_vpu_vsew (g_io_out_bits_uop_vpu_vsew),
    .io_out_bits_uop_vpu_vlmul (g_io_out_bits_uop_vpu_vlmul),
    .io_out_bits_uop_vpu_specVill (g_io_out_bits_uop_vpu_specVill),
    .io_out_bits_uop_vpu_specVma (g_io_out_bits_uop_vpu_specVma),
    .io_out_bits_uop_vpu_specVta (g_io_out_bits_uop_vpu_specVta),
    .io_out_bits_uop_vpu_specVsew (g_io_out_bits_uop_vpu_specVsew),
    .io_out_bits_uop_vpu_specVlmul (g_io_out_bits_uop_vpu_specVlmul),
    .io_out_bits_uop_vpu_vm (g_io_out_bits_uop_vpu_vm),
    .io_out_bits_uop_vpu_vstart (g_io_out_bits_uop_vpu_vstart),
    .io_out_bits_uop_vpu_frm (g_io_out_bits_uop_vpu_frm),
    .io_out_bits_uop_vpu_fpu_isFpToVecInst (g_io_out_bits_uop_vpu_fpu_isFpToVecInst),
    .io_out_bits_uop_vpu_fpu_isFP32Instr (g_io_out_bits_uop_vpu_fpu_isFP32Instr),
    .io_out_bits_uop_vpu_fpu_isFP64Instr (g_io_out_bits_uop_vpu_fpu_isFP64Instr),
    .io_out_bits_uop_vpu_fpu_isReduction (g_io_out_bits_uop_vpu_fpu_isReduction),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_2 (g_io_out_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_4 (g_io_out_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_8 (g_io_out_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_out_bits_uop_vpu_vxrm (g_io_out_bits_uop_vpu_vxrm),
    .io_out_bits_uop_vpu_vuopIdx (g_io_out_bits_uop_vpu_vuopIdx),
    .io_out_bits_uop_vpu_lastUop (g_io_out_bits_uop_vpu_lastUop),
    .io_out_bits_uop_vpu_vmask (g_io_out_bits_uop_vpu_vmask),
    .io_out_bits_uop_vpu_vl (g_io_out_bits_uop_vpu_vl),
    .io_out_bits_uop_vpu_nf (g_io_out_bits_uop_vpu_nf),
    .io_out_bits_uop_vpu_veew (g_io_out_bits_uop_vpu_veew),
    .io_out_bits_uop_vpu_isReverse (g_io_out_bits_uop_vpu_isReverse),
    .io_out_bits_uop_vpu_isExt (g_io_out_bits_uop_vpu_isExt),
    .io_out_bits_uop_vpu_isNarrow (g_io_out_bits_uop_vpu_isNarrow),
    .io_out_bits_uop_vpu_isDstMask (g_io_out_bits_uop_vpu_isDstMask),
    .io_out_bits_uop_vpu_isOpMask (g_io_out_bits_uop_vpu_isOpMask),
    .io_out_bits_uop_vpu_isMove (g_io_out_bits_uop_vpu_isMove),
    .io_out_bits_uop_vpu_isDependOldVd (g_io_out_bits_uop_vpu_isDependOldVd),
    .io_out_bits_uop_vpu_isWritePartVd (g_io_out_bits_uop_vpu_isWritePartVd),
    .io_out_bits_uop_vpu_isVleff (g_io_out_bits_uop_vpu_isVleff),
    .io_out_bits_uop_vlsInstr (g_io_out_bits_uop_vlsInstr),
    .io_out_bits_uop_wfflags (g_io_out_bits_uop_wfflags),
    .io_out_bits_uop_isMove (g_io_out_bits_uop_isMove),
    .io_out_bits_uop_isDropAmocasSta (g_io_out_bits_uop_isDropAmocasSta),
    .io_out_bits_uop_uopIdx (g_io_out_bits_uop_uopIdx),
    .io_out_bits_uop_isVset (g_io_out_bits_uop_isVset),
    .io_out_bits_uop_firstUop (g_io_out_bits_uop_firstUop),
    .io_out_bits_uop_lastUop (g_io_out_bits_uop_lastUop),
    .io_out_bits_uop_numUops (g_io_out_bits_uop_numUops),
    .io_out_bits_uop_numWB (g_io_out_bits_uop_numWB),
    .io_out_bits_uop_commitType (g_io_out_bits_uop_commitType),
    .io_out_bits_uop_srcState_0 (g_io_out_bits_uop_srcState_0),
    .io_out_bits_uop_srcState_1 (g_io_out_bits_uop_srcState_1),
    .io_out_bits_uop_srcState_2 (g_io_out_bits_uop_srcState_2),
    .io_out_bits_uop_srcState_3 (g_io_out_bits_uop_srcState_3),
    .io_out_bits_uop_srcState_4 (g_io_out_bits_uop_srcState_4),
    .io_out_bits_uop_srcLoadDependency_0_0 (g_io_out_bits_uop_srcLoadDependency_0_0),
    .io_out_bits_uop_srcLoadDependency_0_1 (g_io_out_bits_uop_srcLoadDependency_0_1),
    .io_out_bits_uop_srcLoadDependency_0_2 (g_io_out_bits_uop_srcLoadDependency_0_2),
    .io_out_bits_uop_srcLoadDependency_1_0 (g_io_out_bits_uop_srcLoadDependency_1_0),
    .io_out_bits_uop_srcLoadDependency_1_1 (g_io_out_bits_uop_srcLoadDependency_1_1),
    .io_out_bits_uop_srcLoadDependency_1_2 (g_io_out_bits_uop_srcLoadDependency_1_2),
    .io_out_bits_uop_srcLoadDependency_2_0 (g_io_out_bits_uop_srcLoadDependency_2_0),
    .io_out_bits_uop_srcLoadDependency_2_1 (g_io_out_bits_uop_srcLoadDependency_2_1),
    .io_out_bits_uop_srcLoadDependency_2_2 (g_io_out_bits_uop_srcLoadDependency_2_2),
    .io_out_bits_uop_srcLoadDependency_3_0 (g_io_out_bits_uop_srcLoadDependency_3_0),
    .io_out_bits_uop_srcLoadDependency_3_1 (g_io_out_bits_uop_srcLoadDependency_3_1),
    .io_out_bits_uop_srcLoadDependency_3_2 (g_io_out_bits_uop_srcLoadDependency_3_2),
    .io_out_bits_uop_srcLoadDependency_4_0 (g_io_out_bits_uop_srcLoadDependency_4_0),
    .io_out_bits_uop_srcLoadDependency_4_1 (g_io_out_bits_uop_srcLoadDependency_4_1),
    .io_out_bits_uop_srcLoadDependency_4_2 (g_io_out_bits_uop_srcLoadDependency_4_2),
    .io_out_bits_uop_psrc_0 (g_io_out_bits_uop_psrc_0),
    .io_out_bits_uop_psrc_1 (g_io_out_bits_uop_psrc_1),
    .io_out_bits_uop_psrc_2 (g_io_out_bits_uop_psrc_2),
    .io_out_bits_uop_psrc_3 (g_io_out_bits_uop_psrc_3),
    .io_out_bits_uop_psrc_4 (g_io_out_bits_uop_psrc_4),
    .io_out_bits_uop_pdest (g_io_out_bits_uop_pdest),
    .io_out_bits_uop_useRegCache_0 (g_io_out_bits_uop_useRegCache_0),
    .io_out_bits_uop_useRegCache_1 (g_io_out_bits_uop_useRegCache_1),
    .io_out_bits_uop_regCacheIdx_0 (g_io_out_bits_uop_regCacheIdx_0),
    .io_out_bits_uop_regCacheIdx_1 (g_io_out_bits_uop_regCacheIdx_1),
    .io_out_bits_uop_robIdx_flag (g_io_out_bits_uop_robIdx_flag),
    .io_out_bits_uop_robIdx_value (g_io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_instrSize (g_io_out_bits_uop_instrSize),
    .io_out_bits_uop_dirtyFs (g_io_out_bits_uop_dirtyFs),
    .io_out_bits_uop_dirtyVs (g_io_out_bits_uop_dirtyVs),
    .io_out_bits_uop_traceBlockInPipe_itype (g_io_out_bits_uop_traceBlockInPipe_itype),
    .io_out_bits_uop_traceBlockInPipe_iretire (g_io_out_bits_uop_traceBlockInPipe_iretire),
    .io_out_bits_uop_traceBlockInPipe_ilastsize (g_io_out_bits_uop_traceBlockInPipe_ilastsize),
    .io_out_bits_uop_eliminatedMove (g_io_out_bits_uop_eliminatedMove),
    .io_out_bits_uop_snapshot (g_io_out_bits_uop_snapshot),
    .io_out_bits_uop_debugInfo_eliminatedMove (g_io_out_bits_uop_debugInfo_eliminatedMove),
    .io_out_bits_uop_debugInfo_renameTime (g_io_out_bits_uop_debugInfo_renameTime),
    .io_out_bits_uop_debugInfo_dispatchTime (g_io_out_bits_uop_debugInfo_dispatchTime),
    .io_out_bits_uop_debugInfo_enqRsTime (g_io_out_bits_uop_debugInfo_enqRsTime),
    .io_out_bits_uop_debugInfo_selectTime (g_io_out_bits_uop_debugInfo_selectTime),
    .io_out_bits_uop_debugInfo_issueTime (g_io_out_bits_uop_debugInfo_issueTime),
    .io_out_bits_uop_debugInfo_writebackTime (g_io_out_bits_uop_debugInfo_writebackTime),
    .io_out_bits_uop_debugInfo_runahead_checkpoint_id (g_io_out_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_out_bits_uop_debugInfo_tlbFirstReqTime (g_io_out_bits_uop_debugInfo_tlbFirstReqTime),
    .io_out_bits_uop_debugInfo_tlbRespTime (g_io_out_bits_uop_debugInfo_tlbRespTime),
    .io_out_bits_uop_debug_seqNum_seqNum (g_io_out_bits_uop_debug_seqNum_seqNum),
    .io_out_bits_uop_debug_seqNum_uopIdx (g_io_out_bits_uop_debug_seqNum_uopIdx),
    .io_out_bits_uop_storeSetHit (g_io_out_bits_uop_storeSetHit),
    .io_out_bits_uop_waitForRobIdx_flag (g_io_out_bits_uop_waitForRobIdx_flag),
    .io_out_bits_uop_waitForRobIdx_value (g_io_out_bits_uop_waitForRobIdx_value),
    .io_out_bits_uop_loadWaitBit (g_io_out_bits_uop_loadWaitBit),
    .io_out_bits_uop_loadWaitStrict (g_io_out_bits_uop_loadWaitStrict),
    .io_out_bits_uop_ssid (g_io_out_bits_uop_ssid),
    .io_out_bits_uop_lqIdx_flag (g_io_out_bits_uop_lqIdx_flag),
    .io_out_bits_uop_lqIdx_value (g_io_out_bits_uop_lqIdx_value),
    .io_out_bits_uop_sqIdx_flag (g_io_out_bits_uop_sqIdx_flag),
    .io_out_bits_uop_sqIdx_value (g_io_out_bits_uop_sqIdx_value),
    .io_out_bits_uop_singleStep (g_io_out_bits_uop_singleStep),
    .io_out_bits_uop_replayInst (g_io_out_bits_uop_replayInst),
    .io_out_bits_uop_debug_fuType (g_io_out_bits_uop_debug_fuType),
    .io_out_bits_uop_debug_sim_trig (g_io_out_bits_uop_debug_sim_trig),
    .io_out_bits_uop_numLsElem (g_io_out_bits_uop_numLsElem),
    .io_out_bits_mBIndex (g_io_out_bits_mBIndex),
    .io_out_bits_elemIdx (g_io_out_bits_elemIdx),
    .io_out_bits_elemIdxInsideVd (g_io_out_bits_elemIdxInsideVd),
    .io_out_bits_splitIndex (g_io_out_bits_splitIndex),
    .io_threshold_valid (io_threshold_valid),
    .io_threshold_bits_robIdx_flag (io_threshold_bits_robIdx_flag),
    .io_threshold_bits_robIdx_value (io_threshold_bits_robIdx_value),
    .io_threshold_bits_uopIdx (io_threshold_bits_uopIdx),
    .io_fromPipeline_0_valid (io_fromPipeline_0_valid),
    .io_fromPipeline_0_bits_mBIndex (io_fromPipeline_0_bits_mBIndex),
    .io_fromPipeline_1_valid (io_fromPipeline_1_valid),
    .io_fromPipeline_1_bits_mBIndex (io_fromPipeline_1_bits_mBIndex),
    .io_fromPipeline_2_valid (io_fromPipeline_2_valid),
    .io_fromPipeline_2_bits_mBIndex (io_fromPipeline_2_bits_mBIndex)
  );

  VLSplitImp_xs u_impl (
    .clock (clock),
    .reset (reset),
    .io_redirect_valid (io_redirect_valid),
    .io_redirect_bits_robIdx_flag (io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value (io_redirect_bits_robIdx_value),
    .io_redirect_bits_level (io_redirect_bits_level),
    .io_in_ready (x_io_in_ready),
    .io_in_valid (io_in_valid),
    .io_in_bits_uop_pc (io_in_bits_uop_pc),
    .io_in_bits_uop_ftqPtr_flag (io_in_bits_uop_ftqPtr_flag),
    .io_in_bits_uop_ftqPtr_value (io_in_bits_uop_ftqPtr_value),
    .io_in_bits_uop_ftqOffset (io_in_bits_uop_ftqOffset),
    .io_in_bits_uop_fuType (io_in_bits_uop_fuType),
    .io_in_bits_uop_fuOpType (io_in_bits_uop_fuOpType),
    .io_in_bits_uop_vecWen (io_in_bits_uop_vecWen),
    .io_in_bits_uop_v0Wen (io_in_bits_uop_v0Wen),
    .io_in_bits_uop_vlWen (io_in_bits_uop_vlWen),
    .io_in_bits_uop_vpu_vill (io_in_bits_uop_vpu_vill),
    .io_in_bits_uop_vpu_vma (io_in_bits_uop_vpu_vma),
    .io_in_bits_uop_vpu_vta (io_in_bits_uop_vpu_vta),
    .io_in_bits_uop_vpu_vsew (io_in_bits_uop_vpu_vsew),
    .io_in_bits_uop_vpu_vlmul (io_in_bits_uop_vpu_vlmul),
    .io_in_bits_uop_vpu_specVill (io_in_bits_uop_vpu_specVill),
    .io_in_bits_uop_vpu_specVma (io_in_bits_uop_vpu_specVma),
    .io_in_bits_uop_vpu_specVta (io_in_bits_uop_vpu_specVta),
    .io_in_bits_uop_vpu_specVsew (io_in_bits_uop_vpu_specVsew),
    .io_in_bits_uop_vpu_specVlmul (io_in_bits_uop_vpu_specVlmul),
    .io_in_bits_uop_vpu_vm (io_in_bits_uop_vpu_vm),
    .io_in_bits_uop_vpu_vstart (io_in_bits_uop_vpu_vstart),
    .io_in_bits_uop_vpu_frm (io_in_bits_uop_vpu_frm),
    .io_in_bits_uop_vpu_fpu_isFpToVecInst (io_in_bits_uop_vpu_fpu_isFpToVecInst),
    .io_in_bits_uop_vpu_fpu_isFP32Instr (io_in_bits_uop_vpu_fpu_isFP32Instr),
    .io_in_bits_uop_vpu_fpu_isFP64Instr (io_in_bits_uop_vpu_fpu_isFP64Instr),
    .io_in_bits_uop_vpu_fpu_isReduction (io_in_bits_uop_vpu_fpu_isReduction),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_2 (io_in_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_4 (io_in_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_8 (io_in_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_in_bits_uop_vpu_vxrm (io_in_bits_uop_vpu_vxrm),
    .io_in_bits_uop_vpu_vuopIdx (io_in_bits_uop_vpu_vuopIdx),
    .io_in_bits_uop_vpu_lastUop (io_in_bits_uop_vpu_lastUop),
    .io_in_bits_uop_vpu_vmask (io_in_bits_uop_vpu_vmask),
    .io_in_bits_uop_vpu_nf (io_in_bits_uop_vpu_nf),
    .io_in_bits_uop_vpu_veew (io_in_bits_uop_vpu_veew),
    .io_in_bits_uop_vpu_isReverse (io_in_bits_uop_vpu_isReverse),
    .io_in_bits_uop_vpu_isExt (io_in_bits_uop_vpu_isExt),
    .io_in_bits_uop_vpu_isNarrow (io_in_bits_uop_vpu_isNarrow),
    .io_in_bits_uop_vpu_isDstMask (io_in_bits_uop_vpu_isDstMask),
    .io_in_bits_uop_vpu_isOpMask (io_in_bits_uop_vpu_isOpMask),
    .io_in_bits_uop_vpu_isMove (io_in_bits_uop_vpu_isMove),
    .io_in_bits_uop_vpu_isDependOldVd (io_in_bits_uop_vpu_isDependOldVd),
    .io_in_bits_uop_vpu_isWritePartVd (io_in_bits_uop_vpu_isWritePartVd),
    .io_in_bits_uop_vpu_isVleff (io_in_bits_uop_vpu_isVleff),
    .io_in_bits_uop_pdest (io_in_bits_uop_pdest),
    .io_in_bits_uop_robIdx_flag (io_in_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value (io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_debugInfo_eliminatedMove (io_in_bits_uop_debugInfo_eliminatedMove),
    .io_in_bits_uop_debugInfo_renameTime (io_in_bits_uop_debugInfo_renameTime),
    .io_in_bits_uop_debugInfo_dispatchTime (io_in_bits_uop_debugInfo_dispatchTime),
    .io_in_bits_uop_debugInfo_enqRsTime (io_in_bits_uop_debugInfo_enqRsTime),
    .io_in_bits_uop_debugInfo_selectTime (io_in_bits_uop_debugInfo_selectTime),
    .io_in_bits_uop_debugInfo_issueTime (io_in_bits_uop_debugInfo_issueTime),
    .io_in_bits_uop_debugInfo_writebackTime (io_in_bits_uop_debugInfo_writebackTime),
    .io_in_bits_uop_debugInfo_runahead_checkpoint_id (io_in_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_in_bits_uop_debugInfo_tlbFirstReqTime (io_in_bits_uop_debugInfo_tlbFirstReqTime),
    .io_in_bits_uop_debugInfo_tlbRespTime (io_in_bits_uop_debugInfo_tlbRespTime),
    .io_in_bits_uop_debug_seqNum_seqNum (io_in_bits_uop_debug_seqNum_seqNum),
    .io_in_bits_uop_debug_seqNum_uopIdx (io_in_bits_uop_debug_seqNum_uopIdx),
    .io_in_bits_uop_lqIdx_flag (io_in_bits_uop_lqIdx_flag),
    .io_in_bits_uop_lqIdx_value (io_in_bits_uop_lqIdx_value),
    .io_in_bits_uop_sqIdx_flag (io_in_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value (io_in_bits_uop_sqIdx_value),
    .io_in_bits_uop_numLsElem (io_in_bits_uop_numLsElem),
    .io_in_bits_src_0 (io_in_bits_src_0),
    .io_in_bits_src_1 (io_in_bits_src_1),
    .io_in_bits_src_2 (io_in_bits_src_2),
    .io_in_bits_src_3 (io_in_bits_src_3),
    .io_in_bits_src_4 (io_in_bits_src_4),
    .io_in_bits_flowNum (io_in_bits_flowNum),
    .io_in_bits_isVecPartReplay (io_in_bits_isVecPartReplay),
    .io_in_bits_vecReplayMask (io_in_bits_vecReplayMask),
    .io_in_bits_vecReplayMbIdx (io_in_bits_vecReplayMbIdx),
    .io_toMergeBuffer_req_ready (io_toMergeBuffer_req_ready),
    .io_toMergeBuffer_req_valid (x_io_toMergeBuffer_req_valid),
    .io_toMergeBuffer_req_bits_mask (x_io_toMergeBuffer_req_bits_mask),
    .io_toMergeBuffer_req_bits_vaddr (x_io_toMergeBuffer_req_bits_vaddr),
    .io_toMergeBuffer_req_bits_flowNum (x_io_toMergeBuffer_req_bits_flowNum),
    .io_toMergeBuffer_req_bits_uop_fuOpType (x_io_toMergeBuffer_req_bits_uop_fuOpType),
    .io_toMergeBuffer_req_bits_uop_vecWen (x_io_toMergeBuffer_req_bits_uop_vecWen),
    .io_toMergeBuffer_req_bits_uop_v0Wen (x_io_toMergeBuffer_req_bits_uop_v0Wen),
    .io_toMergeBuffer_req_bits_uop_vlWen (x_io_toMergeBuffer_req_bits_uop_vlWen),
    .io_toMergeBuffer_req_bits_uop_vpu_vill (x_io_toMergeBuffer_req_bits_uop_vpu_vill),
    .io_toMergeBuffer_req_bits_uop_vpu_vma (x_io_toMergeBuffer_req_bits_uop_vpu_vma),
    .io_toMergeBuffer_req_bits_uop_vpu_vta (x_io_toMergeBuffer_req_bits_uop_vpu_vta),
    .io_toMergeBuffer_req_bits_uop_vpu_vsew (x_io_toMergeBuffer_req_bits_uop_vpu_vsew),
    .io_toMergeBuffer_req_bits_uop_vpu_vlmul (x_io_toMergeBuffer_req_bits_uop_vpu_vlmul),
    .io_toMergeBuffer_req_bits_uop_vpu_specVill (x_io_toMergeBuffer_req_bits_uop_vpu_specVill),
    .io_toMergeBuffer_req_bits_uop_vpu_specVma (x_io_toMergeBuffer_req_bits_uop_vpu_specVma),
    .io_toMergeBuffer_req_bits_uop_vpu_specVta (x_io_toMergeBuffer_req_bits_uop_vpu_specVta),
    .io_toMergeBuffer_req_bits_uop_vpu_specVsew (x_io_toMergeBuffer_req_bits_uop_vpu_specVsew),
    .io_toMergeBuffer_req_bits_uop_vpu_specVlmul (x_io_toMergeBuffer_req_bits_uop_vpu_specVlmul),
    .io_toMergeBuffer_req_bits_uop_vpu_vm (x_io_toMergeBuffer_req_bits_uop_vpu_vm),
    .io_toMergeBuffer_req_bits_uop_vpu_frm (x_io_toMergeBuffer_req_bits_uop_vpu_frm),
    .io_toMergeBuffer_req_bits_uop_vpu_fpu_isFpToVecInst (x_io_toMergeBuffer_req_bits_uop_vpu_fpu_isFpToVecInst),
    .io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP32Instr (x_io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP32Instr),
    .io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP64Instr (x_io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP64Instr),
    .io_toMergeBuffer_req_bits_uop_vpu_fpu_isReduction (x_io_toMergeBuffer_req_bits_uop_vpu_fpu_isReduction),
    .io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_2 (x_io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_4 (x_io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_8 (x_io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_toMergeBuffer_req_bits_uop_vpu_vxrm (x_io_toMergeBuffer_req_bits_uop_vpu_vxrm),
    .io_toMergeBuffer_req_bits_uop_vpu_vuopIdx (x_io_toMergeBuffer_req_bits_uop_vpu_vuopIdx),
    .io_toMergeBuffer_req_bits_uop_vpu_lastUop (x_io_toMergeBuffer_req_bits_uop_vpu_lastUop),
    .io_toMergeBuffer_req_bits_uop_vpu_vl (x_io_toMergeBuffer_req_bits_uop_vpu_vl),
    .io_toMergeBuffer_req_bits_uop_vpu_nf (x_io_toMergeBuffer_req_bits_uop_vpu_nf),
    .io_toMergeBuffer_req_bits_uop_vpu_veew (x_io_toMergeBuffer_req_bits_uop_vpu_veew),
    .io_toMergeBuffer_req_bits_uop_vpu_isReverse (x_io_toMergeBuffer_req_bits_uop_vpu_isReverse),
    .io_toMergeBuffer_req_bits_uop_vpu_isExt (x_io_toMergeBuffer_req_bits_uop_vpu_isExt),
    .io_toMergeBuffer_req_bits_uop_vpu_isNarrow (x_io_toMergeBuffer_req_bits_uop_vpu_isNarrow),
    .io_toMergeBuffer_req_bits_uop_vpu_isDstMask (x_io_toMergeBuffer_req_bits_uop_vpu_isDstMask),
    .io_toMergeBuffer_req_bits_uop_vpu_isOpMask (x_io_toMergeBuffer_req_bits_uop_vpu_isOpMask),
    .io_toMergeBuffer_req_bits_uop_vpu_isMove (x_io_toMergeBuffer_req_bits_uop_vpu_isMove),
    .io_toMergeBuffer_req_bits_uop_vpu_isDependOldVd (x_io_toMergeBuffer_req_bits_uop_vpu_isDependOldVd),
    .io_toMergeBuffer_req_bits_uop_vpu_isWritePartVd (x_io_toMergeBuffer_req_bits_uop_vpu_isWritePartVd),
    .io_toMergeBuffer_req_bits_uop_vpu_isVleff (x_io_toMergeBuffer_req_bits_uop_vpu_isVleff),
    .io_toMergeBuffer_req_bits_uop_uopIdx (x_io_toMergeBuffer_req_bits_uop_uopIdx),
    .io_toMergeBuffer_req_bits_uop_pdest (x_io_toMergeBuffer_req_bits_uop_pdest),
    .io_toMergeBuffer_req_bits_uop_robIdx_flag (x_io_toMergeBuffer_req_bits_uop_robIdx_flag),
    .io_toMergeBuffer_req_bits_uop_robIdx_value (x_io_toMergeBuffer_req_bits_uop_robIdx_value),
    .io_toMergeBuffer_req_bits_uop_debugInfo_eliminatedMove (x_io_toMergeBuffer_req_bits_uop_debugInfo_eliminatedMove),
    .io_toMergeBuffer_req_bits_uop_debugInfo_renameTime (x_io_toMergeBuffer_req_bits_uop_debugInfo_renameTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_dispatchTime (x_io_toMergeBuffer_req_bits_uop_debugInfo_dispatchTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime (x_io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_selectTime (x_io_toMergeBuffer_req_bits_uop_debugInfo_selectTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_issueTime (x_io_toMergeBuffer_req_bits_uop_debugInfo_issueTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_writebackTime (x_io_toMergeBuffer_req_bits_uop_debugInfo_writebackTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_runahead_checkpoint_id (x_io_toMergeBuffer_req_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_toMergeBuffer_req_bits_uop_debugInfo_tlbFirstReqTime (x_io_toMergeBuffer_req_bits_uop_debugInfo_tlbFirstReqTime),
    .io_toMergeBuffer_req_bits_uop_debugInfo_tlbRespTime (x_io_toMergeBuffer_req_bits_uop_debugInfo_tlbRespTime),
    .io_toMergeBuffer_req_bits_uop_debug_seqNum_seqNum (x_io_toMergeBuffer_req_bits_uop_debug_seqNum_seqNum),
    .io_toMergeBuffer_req_bits_uop_debug_seqNum_uopIdx (x_io_toMergeBuffer_req_bits_uop_debug_seqNum_uopIdx),
    .io_toMergeBuffer_req_bits_uop_lqIdx_flag (x_io_toMergeBuffer_req_bits_uop_lqIdx_flag),
    .io_toMergeBuffer_req_bits_uop_lqIdx_value (x_io_toMergeBuffer_req_bits_uop_lqIdx_value),
    .io_toMergeBuffer_req_bits_uop_sqIdx_flag (x_io_toMergeBuffer_req_bits_uop_sqIdx_flag),
    .io_toMergeBuffer_req_bits_uop_sqIdx_value (x_io_toMergeBuffer_req_bits_uop_sqIdx_value),
    .io_toMergeBuffer_req_bits_data (x_io_toMergeBuffer_req_bits_data),
    .io_toMergeBuffer_req_bits_vdIdx (x_io_toMergeBuffer_req_bits_vdIdx),
    .io_toMergeBuffer_req_bits_fof (x_io_toMergeBuffer_req_bits_fof),
    .io_toMergeBuffer_req_bits_vlmax (x_io_toMergeBuffer_req_bits_vlmax),
    .io_toMergeBuffer_resp_valid (io_toMergeBuffer_resp_valid),
    .io_toMergeBuffer_resp_bits_mBIndex (io_toMergeBuffer_resp_bits_mBIndex),
    .io_out_ready (io_out_ready),
    .io_out_valid (x_io_out_valid),
    .io_out_bits_vaddr (x_io_out_bits_vaddr),
    .io_out_bits_basevaddr (x_io_out_bits_basevaddr),
    .io_out_bits_mask (x_io_out_bits_mask),
    .io_out_bits_reg_offset (x_io_out_bits_reg_offset),
    .io_out_bits_alignedType (x_io_out_bits_alignedType),
    .io_out_bits_vecActive (x_io_out_bits_vecActive),
    .io_out_bits_vecIsFirstActiveElement (x_io_out_bits_vecIsFirstActiveElement),
    .io_out_bits_uop_instr (x_io_out_bits_uop_instr),
    .io_out_bits_uop_pc (x_io_out_bits_uop_pc),
    .io_out_bits_uop_foldpc (x_io_out_bits_uop_foldpc),
    .io_out_bits_uop_exceptionVec_4 (x_io_out_bits_uop_exceptionVec_4),
    .io_out_bits_uop_exceptionVec_5 (x_io_out_bits_uop_exceptionVec_5),
    .io_out_bits_uop_exceptionVec_13 (x_io_out_bits_uop_exceptionVec_13),
    .io_out_bits_uop_exceptionVec_19 (x_io_out_bits_uop_exceptionVec_19),
    .io_out_bits_uop_exceptionVec_21 (x_io_out_bits_uop_exceptionVec_21),
    .io_out_bits_uop_isFetchMalAddr (x_io_out_bits_uop_isFetchMalAddr),
    .io_out_bits_uop_hasException (x_io_out_bits_uop_hasException),
    .io_out_bits_uop_trigger (x_io_out_bits_uop_trigger),
    .io_out_bits_uop_preDecodeInfo_valid (x_io_out_bits_uop_preDecodeInfo_valid),
    .io_out_bits_uop_preDecodeInfo_isRVC (x_io_out_bits_uop_preDecodeInfo_isRVC),
    .io_out_bits_uop_preDecodeInfo_brType (x_io_out_bits_uop_preDecodeInfo_brType),
    .io_out_bits_uop_preDecodeInfo_isCall (x_io_out_bits_uop_preDecodeInfo_isCall),
    .io_out_bits_uop_preDecodeInfo_isRet (x_io_out_bits_uop_preDecodeInfo_isRet),
    .io_out_bits_uop_pred_taken (x_io_out_bits_uop_pred_taken),
    .io_out_bits_uop_crossPageIPFFix (x_io_out_bits_uop_crossPageIPFFix),
    .io_out_bits_uop_ftqPtr_flag (x_io_out_bits_uop_ftqPtr_flag),
    .io_out_bits_uop_ftqPtr_value (x_io_out_bits_uop_ftqPtr_value),
    .io_out_bits_uop_ftqOffset (x_io_out_bits_uop_ftqOffset),
    .io_out_bits_uop_satpFlushFirstFetchFault (x_io_out_bits_uop_satpFlushFirstFetchFault),
    .io_out_bits_uop_srcType_0 (x_io_out_bits_uop_srcType_0),
    .io_out_bits_uop_srcType_1 (x_io_out_bits_uop_srcType_1),
    .io_out_bits_uop_srcType_2 (x_io_out_bits_uop_srcType_2),
    .io_out_bits_uop_srcType_3 (x_io_out_bits_uop_srcType_3),
    .io_out_bits_uop_srcType_4 (x_io_out_bits_uop_srcType_4),
    .io_out_bits_uop_ldest (x_io_out_bits_uop_ldest),
    .io_out_bits_uop_fuOpType (x_io_out_bits_uop_fuOpType),
    .io_out_bits_uop_rfWen (x_io_out_bits_uop_rfWen),
    .io_out_bits_uop_fpWen (x_io_out_bits_uop_fpWen),
    .io_out_bits_uop_vecWen (x_io_out_bits_uop_vecWen),
    .io_out_bits_uop_v0Wen (x_io_out_bits_uop_v0Wen),
    .io_out_bits_uop_vlWen (x_io_out_bits_uop_vlWen),
    .io_out_bits_uop_isXSTrap (x_io_out_bits_uop_isXSTrap),
    .io_out_bits_uop_waitForward (x_io_out_bits_uop_waitForward),
    .io_out_bits_uop_blockBackward (x_io_out_bits_uop_blockBackward),
    .io_out_bits_uop_canRobCompress (x_io_out_bits_uop_canRobCompress),
    .io_out_bits_uop_selImm (x_io_out_bits_uop_selImm),
    .io_out_bits_uop_fpu_typeTagOut (x_io_out_bits_uop_fpu_typeTagOut),
    .io_out_bits_uop_fpu_wflags (x_io_out_bits_uop_fpu_wflags),
    .io_out_bits_uop_fpu_typ (x_io_out_bits_uop_fpu_typ),
    .io_out_bits_uop_fpu_fmt (x_io_out_bits_uop_fpu_fmt),
    .io_out_bits_uop_fpu_rm (x_io_out_bits_uop_fpu_rm),
    .io_out_bits_uop_vpu_vill (x_io_out_bits_uop_vpu_vill),
    .io_out_bits_uop_vpu_vma (x_io_out_bits_uop_vpu_vma),
    .io_out_bits_uop_vpu_vta (x_io_out_bits_uop_vpu_vta),
    .io_out_bits_uop_vpu_vsew (x_io_out_bits_uop_vpu_vsew),
    .io_out_bits_uop_vpu_vlmul (x_io_out_bits_uop_vpu_vlmul),
    .io_out_bits_uop_vpu_specVill (x_io_out_bits_uop_vpu_specVill),
    .io_out_bits_uop_vpu_specVma (x_io_out_bits_uop_vpu_specVma),
    .io_out_bits_uop_vpu_specVta (x_io_out_bits_uop_vpu_specVta),
    .io_out_bits_uop_vpu_specVsew (x_io_out_bits_uop_vpu_specVsew),
    .io_out_bits_uop_vpu_specVlmul (x_io_out_bits_uop_vpu_specVlmul),
    .io_out_bits_uop_vpu_vm (x_io_out_bits_uop_vpu_vm),
    .io_out_bits_uop_vpu_vstart (x_io_out_bits_uop_vpu_vstart),
    .io_out_bits_uop_vpu_frm (x_io_out_bits_uop_vpu_frm),
    .io_out_bits_uop_vpu_fpu_isFpToVecInst (x_io_out_bits_uop_vpu_fpu_isFpToVecInst),
    .io_out_bits_uop_vpu_fpu_isFP32Instr (x_io_out_bits_uop_vpu_fpu_isFP32Instr),
    .io_out_bits_uop_vpu_fpu_isFP64Instr (x_io_out_bits_uop_vpu_fpu_isFP64Instr),
    .io_out_bits_uop_vpu_fpu_isReduction (x_io_out_bits_uop_vpu_fpu_isReduction),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_2 (x_io_out_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_4 (x_io_out_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_8 (x_io_out_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_out_bits_uop_vpu_vxrm (x_io_out_bits_uop_vpu_vxrm),
    .io_out_bits_uop_vpu_vuopIdx (x_io_out_bits_uop_vpu_vuopIdx),
    .io_out_bits_uop_vpu_lastUop (x_io_out_bits_uop_vpu_lastUop),
    .io_out_bits_uop_vpu_vmask (x_io_out_bits_uop_vpu_vmask),
    .io_out_bits_uop_vpu_vl (x_io_out_bits_uop_vpu_vl),
    .io_out_bits_uop_vpu_nf (x_io_out_bits_uop_vpu_nf),
    .io_out_bits_uop_vpu_veew (x_io_out_bits_uop_vpu_veew),
    .io_out_bits_uop_vpu_isReverse (x_io_out_bits_uop_vpu_isReverse),
    .io_out_bits_uop_vpu_isExt (x_io_out_bits_uop_vpu_isExt),
    .io_out_bits_uop_vpu_isNarrow (x_io_out_bits_uop_vpu_isNarrow),
    .io_out_bits_uop_vpu_isDstMask (x_io_out_bits_uop_vpu_isDstMask),
    .io_out_bits_uop_vpu_isOpMask (x_io_out_bits_uop_vpu_isOpMask),
    .io_out_bits_uop_vpu_isMove (x_io_out_bits_uop_vpu_isMove),
    .io_out_bits_uop_vpu_isDependOldVd (x_io_out_bits_uop_vpu_isDependOldVd),
    .io_out_bits_uop_vpu_isWritePartVd (x_io_out_bits_uop_vpu_isWritePartVd),
    .io_out_bits_uop_vpu_isVleff (x_io_out_bits_uop_vpu_isVleff),
    .io_out_bits_uop_vlsInstr (x_io_out_bits_uop_vlsInstr),
    .io_out_bits_uop_wfflags (x_io_out_bits_uop_wfflags),
    .io_out_bits_uop_isMove (x_io_out_bits_uop_isMove),
    .io_out_bits_uop_isDropAmocasSta (x_io_out_bits_uop_isDropAmocasSta),
    .io_out_bits_uop_uopIdx (x_io_out_bits_uop_uopIdx),
    .io_out_bits_uop_isVset (x_io_out_bits_uop_isVset),
    .io_out_bits_uop_firstUop (x_io_out_bits_uop_firstUop),
    .io_out_bits_uop_lastUop (x_io_out_bits_uop_lastUop),
    .io_out_bits_uop_numUops (x_io_out_bits_uop_numUops),
    .io_out_bits_uop_numWB (x_io_out_bits_uop_numWB),
    .io_out_bits_uop_commitType (x_io_out_bits_uop_commitType),
    .io_out_bits_uop_srcState_0 (x_io_out_bits_uop_srcState_0),
    .io_out_bits_uop_srcState_1 (x_io_out_bits_uop_srcState_1),
    .io_out_bits_uop_srcState_2 (x_io_out_bits_uop_srcState_2),
    .io_out_bits_uop_srcState_3 (x_io_out_bits_uop_srcState_3),
    .io_out_bits_uop_srcState_4 (x_io_out_bits_uop_srcState_4),
    .io_out_bits_uop_srcLoadDependency_0_0 (x_io_out_bits_uop_srcLoadDependency_0_0),
    .io_out_bits_uop_srcLoadDependency_0_1 (x_io_out_bits_uop_srcLoadDependency_0_1),
    .io_out_bits_uop_srcLoadDependency_0_2 (x_io_out_bits_uop_srcLoadDependency_0_2),
    .io_out_bits_uop_srcLoadDependency_1_0 (x_io_out_bits_uop_srcLoadDependency_1_0),
    .io_out_bits_uop_srcLoadDependency_1_1 (x_io_out_bits_uop_srcLoadDependency_1_1),
    .io_out_bits_uop_srcLoadDependency_1_2 (x_io_out_bits_uop_srcLoadDependency_1_2),
    .io_out_bits_uop_srcLoadDependency_2_0 (x_io_out_bits_uop_srcLoadDependency_2_0),
    .io_out_bits_uop_srcLoadDependency_2_1 (x_io_out_bits_uop_srcLoadDependency_2_1),
    .io_out_bits_uop_srcLoadDependency_2_2 (x_io_out_bits_uop_srcLoadDependency_2_2),
    .io_out_bits_uop_srcLoadDependency_3_0 (x_io_out_bits_uop_srcLoadDependency_3_0),
    .io_out_bits_uop_srcLoadDependency_3_1 (x_io_out_bits_uop_srcLoadDependency_3_1),
    .io_out_bits_uop_srcLoadDependency_3_2 (x_io_out_bits_uop_srcLoadDependency_3_2),
    .io_out_bits_uop_srcLoadDependency_4_0 (x_io_out_bits_uop_srcLoadDependency_4_0),
    .io_out_bits_uop_srcLoadDependency_4_1 (x_io_out_bits_uop_srcLoadDependency_4_1),
    .io_out_bits_uop_srcLoadDependency_4_2 (x_io_out_bits_uop_srcLoadDependency_4_2),
    .io_out_bits_uop_psrc_0 (x_io_out_bits_uop_psrc_0),
    .io_out_bits_uop_psrc_1 (x_io_out_bits_uop_psrc_1),
    .io_out_bits_uop_psrc_2 (x_io_out_bits_uop_psrc_2),
    .io_out_bits_uop_psrc_3 (x_io_out_bits_uop_psrc_3),
    .io_out_bits_uop_psrc_4 (x_io_out_bits_uop_psrc_4),
    .io_out_bits_uop_pdest (x_io_out_bits_uop_pdest),
    .io_out_bits_uop_useRegCache_0 (x_io_out_bits_uop_useRegCache_0),
    .io_out_bits_uop_useRegCache_1 (x_io_out_bits_uop_useRegCache_1),
    .io_out_bits_uop_regCacheIdx_0 (x_io_out_bits_uop_regCacheIdx_0),
    .io_out_bits_uop_regCacheIdx_1 (x_io_out_bits_uop_regCacheIdx_1),
    .io_out_bits_uop_robIdx_flag (x_io_out_bits_uop_robIdx_flag),
    .io_out_bits_uop_robIdx_value (x_io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_instrSize (x_io_out_bits_uop_instrSize),
    .io_out_bits_uop_dirtyFs (x_io_out_bits_uop_dirtyFs),
    .io_out_bits_uop_dirtyVs (x_io_out_bits_uop_dirtyVs),
    .io_out_bits_uop_traceBlockInPipe_itype (x_io_out_bits_uop_traceBlockInPipe_itype),
    .io_out_bits_uop_traceBlockInPipe_iretire (x_io_out_bits_uop_traceBlockInPipe_iretire),
    .io_out_bits_uop_traceBlockInPipe_ilastsize (x_io_out_bits_uop_traceBlockInPipe_ilastsize),
    .io_out_bits_uop_eliminatedMove (x_io_out_bits_uop_eliminatedMove),
    .io_out_bits_uop_snapshot (x_io_out_bits_uop_snapshot),
    .io_out_bits_uop_debugInfo_eliminatedMove (x_io_out_bits_uop_debugInfo_eliminatedMove),
    .io_out_bits_uop_debugInfo_renameTime (x_io_out_bits_uop_debugInfo_renameTime),
    .io_out_bits_uop_debugInfo_dispatchTime (x_io_out_bits_uop_debugInfo_dispatchTime),
    .io_out_bits_uop_debugInfo_enqRsTime (x_io_out_bits_uop_debugInfo_enqRsTime),
    .io_out_bits_uop_debugInfo_selectTime (x_io_out_bits_uop_debugInfo_selectTime),
    .io_out_bits_uop_debugInfo_issueTime (x_io_out_bits_uop_debugInfo_issueTime),
    .io_out_bits_uop_debugInfo_writebackTime (x_io_out_bits_uop_debugInfo_writebackTime),
    .io_out_bits_uop_debugInfo_runahead_checkpoint_id (x_io_out_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_out_bits_uop_debugInfo_tlbFirstReqTime (x_io_out_bits_uop_debugInfo_tlbFirstReqTime),
    .io_out_bits_uop_debugInfo_tlbRespTime (x_io_out_bits_uop_debugInfo_tlbRespTime),
    .io_out_bits_uop_debug_seqNum_seqNum (x_io_out_bits_uop_debug_seqNum_seqNum),
    .io_out_bits_uop_debug_seqNum_uopIdx (x_io_out_bits_uop_debug_seqNum_uopIdx),
    .io_out_bits_uop_storeSetHit (x_io_out_bits_uop_storeSetHit),
    .io_out_bits_uop_waitForRobIdx_flag (x_io_out_bits_uop_waitForRobIdx_flag),
    .io_out_bits_uop_waitForRobIdx_value (x_io_out_bits_uop_waitForRobIdx_value),
    .io_out_bits_uop_loadWaitBit (x_io_out_bits_uop_loadWaitBit),
    .io_out_bits_uop_loadWaitStrict (x_io_out_bits_uop_loadWaitStrict),
    .io_out_bits_uop_ssid (x_io_out_bits_uop_ssid),
    .io_out_bits_uop_lqIdx_flag (x_io_out_bits_uop_lqIdx_flag),
    .io_out_bits_uop_lqIdx_value (x_io_out_bits_uop_lqIdx_value),
    .io_out_bits_uop_sqIdx_flag (x_io_out_bits_uop_sqIdx_flag),
    .io_out_bits_uop_sqIdx_value (x_io_out_bits_uop_sqIdx_value),
    .io_out_bits_uop_singleStep (x_io_out_bits_uop_singleStep),
    .io_out_bits_uop_replayInst (x_io_out_bits_uop_replayInst),
    .io_out_bits_uop_debug_fuType (x_io_out_bits_uop_debug_fuType),
    .io_out_bits_uop_debug_sim_trig (x_io_out_bits_uop_debug_sim_trig),
    .io_out_bits_uop_numLsElem (x_io_out_bits_uop_numLsElem),
    .io_out_bits_mBIndex (x_io_out_bits_mBIndex),
    .io_out_bits_elemIdx (x_io_out_bits_elemIdx),
    .io_out_bits_elemIdxInsideVd (x_io_out_bits_elemIdxInsideVd),
    .io_out_bits_splitIndex (x_io_out_bits_splitIndex),
    .io_threshold_valid (io_threshold_valid),
    .io_threshold_bits_robIdx_flag (io_threshold_bits_robIdx_flag),
    .io_threshold_bits_robIdx_value (io_threshold_bits_robIdx_value),
    .io_threshold_bits_uopIdx (io_threshold_bits_uopIdx),
    .io_fromPipeline_0_valid (io_fromPipeline_0_valid),
    .io_fromPipeline_0_bits_mBIndex (io_fromPipeline_0_bits_mBIndex),
    .io_fromPipeline_1_valid (io_fromPipeline_1_valid),
    .io_fromPipeline_1_bits_mBIndex (io_fromPipeline_1_bits_mBIndex),
    .io_fromPipeline_2_valid (io_fromPipeline_2_valid),
    .io_fromPipeline_2_bits_mBIndex (io_fromPipeline_2_bits_mBIndex)
  );

  // ---- 所有输入整体随机（整形在 drive 里）----
  task automatic drive_random();
    io_redirect_valid = 1'($urandom);
    io_redirect_bits_robIdx_flag = 1'($urandom);
    io_redirect_bits_robIdx_value = 8'($urandom);
    io_redirect_bits_level = 1'($urandom);
    io_in_valid = 1'($urandom);
    io_in_bits_uop_pc = 50'({$urandom, $urandom});
    io_in_bits_uop_ftqPtr_flag = 1'($urandom);
    io_in_bits_uop_ftqPtr_value = 6'($urandom);
    io_in_bits_uop_ftqOffset = 4'($urandom);
    io_in_bits_uop_fuType = 35'({$urandom, $urandom});
    io_in_bits_uop_fuOpType = 9'($urandom);
    io_in_bits_uop_vecWen = 1'($urandom);
    io_in_bits_uop_v0Wen = 1'($urandom);
    io_in_bits_uop_vlWen = 1'($urandom);
    io_in_bits_uop_vpu_vill = 1'($urandom);
    io_in_bits_uop_vpu_vma = 1'($urandom);
    io_in_bits_uop_vpu_vta = 1'($urandom);
    io_in_bits_uop_vpu_vsew = 2'($urandom);
    io_in_bits_uop_vpu_vlmul = 3'($urandom);
    io_in_bits_uop_vpu_specVill = 1'($urandom);
    io_in_bits_uop_vpu_specVma = 1'($urandom);
    io_in_bits_uop_vpu_specVta = 1'($urandom);
    io_in_bits_uop_vpu_specVsew = 2'($urandom);
    io_in_bits_uop_vpu_specVlmul = 3'($urandom);
    io_in_bits_uop_vpu_vm = 1'($urandom);
    io_in_bits_uop_vpu_vstart = 8'($urandom);
    io_in_bits_uop_vpu_frm = 3'($urandom);
    io_in_bits_uop_vpu_fpu_isFpToVecInst = 1'($urandom);
    io_in_bits_uop_vpu_fpu_isFP32Instr = 1'($urandom);
    io_in_bits_uop_vpu_fpu_isFP64Instr = 1'($urandom);
    io_in_bits_uop_vpu_fpu_isReduction = 1'($urandom);
    io_in_bits_uop_vpu_fpu_isFoldTo1_2 = 1'($urandom);
    io_in_bits_uop_vpu_fpu_isFoldTo1_4 = 1'($urandom);
    io_in_bits_uop_vpu_fpu_isFoldTo1_8 = 1'($urandom);
    io_in_bits_uop_vpu_vxrm = 2'($urandom);
    io_in_bits_uop_vpu_vuopIdx = 7'($urandom);
    io_in_bits_uop_vpu_lastUop = 1'($urandom);
    io_in_bits_uop_vpu_vmask = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_bits_uop_vpu_nf = 3'($urandom);
    io_in_bits_uop_vpu_veew = 2'($urandom);
    io_in_bits_uop_vpu_isReverse = 1'($urandom);
    io_in_bits_uop_vpu_isExt = 1'($urandom);
    io_in_bits_uop_vpu_isNarrow = 1'($urandom);
    io_in_bits_uop_vpu_isDstMask = 1'($urandom);
    io_in_bits_uop_vpu_isOpMask = 1'($urandom);
    io_in_bits_uop_vpu_isMove = 1'($urandom);
    io_in_bits_uop_vpu_isDependOldVd = 1'($urandom);
    io_in_bits_uop_vpu_isWritePartVd = 1'($urandom);
    io_in_bits_uop_vpu_isVleff = 1'($urandom);
    io_in_bits_uop_pdest = 8'($urandom);
    io_in_bits_uop_robIdx_flag = 1'($urandom);
    io_in_bits_uop_robIdx_value = 8'($urandom);
    io_in_bits_uop_debugInfo_eliminatedMove = 1'($urandom);
    io_in_bits_uop_debugInfo_renameTime = 64'({$urandom, $urandom});
    io_in_bits_uop_debugInfo_dispatchTime = 64'({$urandom, $urandom});
    io_in_bits_uop_debugInfo_enqRsTime = 64'({$urandom, $urandom});
    io_in_bits_uop_debugInfo_selectTime = 64'({$urandom, $urandom});
    io_in_bits_uop_debugInfo_issueTime = 64'({$urandom, $urandom});
    io_in_bits_uop_debugInfo_writebackTime = 64'({$urandom, $urandom});
    io_in_bits_uop_debugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
    io_in_bits_uop_debugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
    io_in_bits_uop_debugInfo_tlbRespTime = 64'({$urandom, $urandom});
    io_in_bits_uop_debug_seqNum_seqNum = 56'({$urandom, $urandom});
    io_in_bits_uop_debug_seqNum_uopIdx = 8'($urandom);
    io_in_bits_uop_lqIdx_flag = 1'($urandom);
    io_in_bits_uop_lqIdx_value = 7'($urandom);
    io_in_bits_uop_sqIdx_flag = 1'($urandom);
    io_in_bits_uop_sqIdx_value = 6'($urandom);
    io_in_bits_uop_numLsElem = 5'($urandom);
    io_in_bits_src_0 = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_bits_src_1 = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_bits_src_2 = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_bits_src_3 = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_bits_src_4 = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_bits_flowNum = 5'($urandom);
    io_in_bits_isVecPartReplay = 1'($urandom);
    io_in_bits_vecReplayMask = 16'($urandom);
    io_in_bits_vecReplayMbIdx = 4'($urandom);
    io_toMergeBuffer_req_ready = 1'($urandom);
    io_toMergeBuffer_resp_valid = 1'($urandom);
    io_toMergeBuffer_resp_bits_mBIndex = 4'($urandom);
    io_out_ready = 1'($urandom);
    io_threshold_valid = 1'($urandom);
    io_threshold_bits_robIdx_flag = 1'($urandom);
    io_threshold_bits_robIdx_value = 8'($urandom);
    io_threshold_bits_uopIdx = 7'($urandom);
    io_fromPipeline_0_valid = 1'($urandom);
    io_fromPipeline_0_bits_mBIndex = 4'($urandom);
    io_fromPipeline_1_valid = 1'($urandom);
    io_fromPipeline_1_bits_mBIndex = 4'($urandom);
    io_fromPipeline_2_valid = 1'($urandom);
    io_fromPipeline_2_bits_mBIndex = 4'($urandom);
  endtask

  // ---- 逐根比较 ----
`define CMP(SIG) \
    if (g_``SIG !== x_``SIG) begin \
      errors++; \
      if (errors < 30) $display("MISMATCH @%0d %s g=%h x=%h", checks, `"SIG`", g_``SIG, x_``SIG); \
    end
  task automatic compare();
    checks++;
    `CMP(io_in_ready)
    `CMP(io_toMergeBuffer_req_valid)
    `CMP(io_toMergeBuffer_req_bits_mask)
    `CMP(io_toMergeBuffer_req_bits_vaddr)
    `CMP(io_toMergeBuffer_req_bits_flowNum)
    `CMP(io_toMergeBuffer_req_bits_uop_fuOpType)
    `CMP(io_toMergeBuffer_req_bits_uop_vecWen)
    `CMP(io_toMergeBuffer_req_bits_uop_v0Wen)
    `CMP(io_toMergeBuffer_req_bits_uop_vlWen)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_vill)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_vma)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_vta)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_vsew)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_vlmul)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_specVill)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_specVma)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_specVta)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_specVsew)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_specVlmul)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_vm)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_frm)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_fpu_isFpToVecInst)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP32Instr)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_fpu_isFP64Instr)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_fpu_isReduction)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_2)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_4)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_fpu_isFoldTo1_8)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_vxrm)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_vuopIdx)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_lastUop)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_vl)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_nf)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_veew)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_isReverse)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_isExt)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_isNarrow)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_isDstMask)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_isOpMask)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_isMove)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_isDependOldVd)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_isWritePartVd)
    `CMP(io_toMergeBuffer_req_bits_uop_vpu_isVleff)
    `CMP(io_toMergeBuffer_req_bits_uop_uopIdx)
    `CMP(io_toMergeBuffer_req_bits_uop_pdest)
    `CMP(io_toMergeBuffer_req_bits_uop_robIdx_flag)
    `CMP(io_toMergeBuffer_req_bits_uop_robIdx_value)
    `CMP(io_toMergeBuffer_req_bits_uop_debugInfo_eliminatedMove)
    `CMP(io_toMergeBuffer_req_bits_uop_debugInfo_renameTime)
    `CMP(io_toMergeBuffer_req_bits_uop_debugInfo_dispatchTime)
    `CMP(io_toMergeBuffer_req_bits_uop_debugInfo_enqRsTime)
    `CMP(io_toMergeBuffer_req_bits_uop_debugInfo_selectTime)
    `CMP(io_toMergeBuffer_req_bits_uop_debugInfo_issueTime)
    `CMP(io_toMergeBuffer_req_bits_uop_debugInfo_writebackTime)
    `CMP(io_toMergeBuffer_req_bits_uop_debugInfo_runahead_checkpoint_id)
    `CMP(io_toMergeBuffer_req_bits_uop_debugInfo_tlbFirstReqTime)
    `CMP(io_toMergeBuffer_req_bits_uop_debugInfo_tlbRespTime)
    `CMP(io_toMergeBuffer_req_bits_uop_debug_seqNum_seqNum)
    `CMP(io_toMergeBuffer_req_bits_uop_debug_seqNum_uopIdx)
    `CMP(io_toMergeBuffer_req_bits_uop_lqIdx_flag)
    `CMP(io_toMergeBuffer_req_bits_uop_lqIdx_value)
    `CMP(io_toMergeBuffer_req_bits_uop_sqIdx_flag)
    `CMP(io_toMergeBuffer_req_bits_uop_sqIdx_value)
    `CMP(io_toMergeBuffer_req_bits_data)
    `CMP(io_toMergeBuffer_req_bits_vdIdx)
    `CMP(io_toMergeBuffer_req_bits_fof)
    `CMP(io_toMergeBuffer_req_bits_vlmax)
    `CMP(io_out_valid)
    `CMP(io_out_bits_vaddr)
    `CMP(io_out_bits_basevaddr)
    `CMP(io_out_bits_mask)
    `CMP(io_out_bits_reg_offset)
    `CMP(io_out_bits_alignedType)
    `CMP(io_out_bits_vecActive)
    `CMP(io_out_bits_vecIsFirstActiveElement)
    `CMP(io_out_bits_uop_instr)
    `CMP(io_out_bits_uop_pc)
    `CMP(io_out_bits_uop_foldpc)
    `CMP(io_out_bits_uop_exceptionVec_4)
    `CMP(io_out_bits_uop_exceptionVec_5)
    `CMP(io_out_bits_uop_exceptionVec_13)
    `CMP(io_out_bits_uop_exceptionVec_19)
    `CMP(io_out_bits_uop_exceptionVec_21)
    `CMP(io_out_bits_uop_isFetchMalAddr)
    `CMP(io_out_bits_uop_hasException)
    `CMP(io_out_bits_uop_trigger)
    `CMP(io_out_bits_uop_preDecodeInfo_valid)
    `CMP(io_out_bits_uop_preDecodeInfo_isRVC)
    `CMP(io_out_bits_uop_preDecodeInfo_brType)
    `CMP(io_out_bits_uop_preDecodeInfo_isCall)
    `CMP(io_out_bits_uop_preDecodeInfo_isRet)
    `CMP(io_out_bits_uop_pred_taken)
    `CMP(io_out_bits_uop_crossPageIPFFix)
    `CMP(io_out_bits_uop_ftqPtr_flag)
    `CMP(io_out_bits_uop_ftqPtr_value)
    `CMP(io_out_bits_uop_ftqOffset)
    `CMP(io_out_bits_uop_satpFlushFirstFetchFault)
    `CMP(io_out_bits_uop_srcType_0)
    `CMP(io_out_bits_uop_srcType_1)
    `CMP(io_out_bits_uop_srcType_2)
    `CMP(io_out_bits_uop_srcType_3)
    `CMP(io_out_bits_uop_srcType_4)
    `CMP(io_out_bits_uop_ldest)
    `CMP(io_out_bits_uop_fuOpType)
    `CMP(io_out_bits_uop_rfWen)
    `CMP(io_out_bits_uop_fpWen)
    `CMP(io_out_bits_uop_vecWen)
    `CMP(io_out_bits_uop_v0Wen)
    `CMP(io_out_bits_uop_vlWen)
    `CMP(io_out_bits_uop_isXSTrap)
    `CMP(io_out_bits_uop_waitForward)
    `CMP(io_out_bits_uop_blockBackward)
    `CMP(io_out_bits_uop_canRobCompress)
    `CMP(io_out_bits_uop_selImm)
    `CMP(io_out_bits_uop_fpu_typeTagOut)
    `CMP(io_out_bits_uop_fpu_wflags)
    `CMP(io_out_bits_uop_fpu_typ)
    `CMP(io_out_bits_uop_fpu_fmt)
    `CMP(io_out_bits_uop_fpu_rm)
    `CMP(io_out_bits_uop_vpu_vill)
    `CMP(io_out_bits_uop_vpu_vma)
    `CMP(io_out_bits_uop_vpu_vta)
    `CMP(io_out_bits_uop_vpu_vsew)
    `CMP(io_out_bits_uop_vpu_vlmul)
    `CMP(io_out_bits_uop_vpu_specVill)
    `CMP(io_out_bits_uop_vpu_specVma)
    `CMP(io_out_bits_uop_vpu_specVta)
    `CMP(io_out_bits_uop_vpu_specVsew)
    `CMP(io_out_bits_uop_vpu_specVlmul)
    `CMP(io_out_bits_uop_vpu_vm)
    `CMP(io_out_bits_uop_vpu_vstart)
    `CMP(io_out_bits_uop_vpu_frm)
    `CMP(io_out_bits_uop_vpu_fpu_isFpToVecInst)
    `CMP(io_out_bits_uop_vpu_fpu_isFP32Instr)
    `CMP(io_out_bits_uop_vpu_fpu_isFP64Instr)
    `CMP(io_out_bits_uop_vpu_fpu_isReduction)
    `CMP(io_out_bits_uop_vpu_fpu_isFoldTo1_2)
    `CMP(io_out_bits_uop_vpu_fpu_isFoldTo1_4)
    `CMP(io_out_bits_uop_vpu_fpu_isFoldTo1_8)
    `CMP(io_out_bits_uop_vpu_vxrm)
    `CMP(io_out_bits_uop_vpu_vuopIdx)
    `CMP(io_out_bits_uop_vpu_lastUop)
    `CMP(io_out_bits_uop_vpu_vmask)
    `CMP(io_out_bits_uop_vpu_vl)
    `CMP(io_out_bits_uop_vpu_nf)
    `CMP(io_out_bits_uop_vpu_veew)
    `CMP(io_out_bits_uop_vpu_isReverse)
    `CMP(io_out_bits_uop_vpu_isExt)
    `CMP(io_out_bits_uop_vpu_isNarrow)
    `CMP(io_out_bits_uop_vpu_isDstMask)
    `CMP(io_out_bits_uop_vpu_isOpMask)
    `CMP(io_out_bits_uop_vpu_isMove)
    `CMP(io_out_bits_uop_vpu_isDependOldVd)
    `CMP(io_out_bits_uop_vpu_isWritePartVd)
    `CMP(io_out_bits_uop_vpu_isVleff)
    `CMP(io_out_bits_uop_vlsInstr)
    `CMP(io_out_bits_uop_wfflags)
    `CMP(io_out_bits_uop_isMove)
    `CMP(io_out_bits_uop_isDropAmocasSta)
    `CMP(io_out_bits_uop_uopIdx)
    `CMP(io_out_bits_uop_isVset)
    `CMP(io_out_bits_uop_firstUop)
    `CMP(io_out_bits_uop_lastUop)
    `CMP(io_out_bits_uop_numUops)
    `CMP(io_out_bits_uop_numWB)
    `CMP(io_out_bits_uop_commitType)
    `CMP(io_out_bits_uop_srcState_0)
    `CMP(io_out_bits_uop_srcState_1)
    `CMP(io_out_bits_uop_srcState_2)
    `CMP(io_out_bits_uop_srcState_3)
    `CMP(io_out_bits_uop_srcState_4)
    `CMP(io_out_bits_uop_srcLoadDependency_0_0)
    `CMP(io_out_bits_uop_srcLoadDependency_0_1)
    `CMP(io_out_bits_uop_srcLoadDependency_0_2)
    `CMP(io_out_bits_uop_srcLoadDependency_1_0)
    `CMP(io_out_bits_uop_srcLoadDependency_1_1)
    `CMP(io_out_bits_uop_srcLoadDependency_1_2)
    `CMP(io_out_bits_uop_srcLoadDependency_2_0)
    `CMP(io_out_bits_uop_srcLoadDependency_2_1)
    `CMP(io_out_bits_uop_srcLoadDependency_2_2)
    `CMP(io_out_bits_uop_srcLoadDependency_3_0)
    `CMP(io_out_bits_uop_srcLoadDependency_3_1)
    `CMP(io_out_bits_uop_srcLoadDependency_3_2)
    `CMP(io_out_bits_uop_srcLoadDependency_4_0)
    `CMP(io_out_bits_uop_srcLoadDependency_4_1)
    `CMP(io_out_bits_uop_srcLoadDependency_4_2)
    `CMP(io_out_bits_uop_psrc_0)
    `CMP(io_out_bits_uop_psrc_1)
    `CMP(io_out_bits_uop_psrc_2)
    `CMP(io_out_bits_uop_psrc_3)
    `CMP(io_out_bits_uop_psrc_4)
    `CMP(io_out_bits_uop_pdest)
    `CMP(io_out_bits_uop_useRegCache_0)
    `CMP(io_out_bits_uop_useRegCache_1)
    `CMP(io_out_bits_uop_regCacheIdx_0)
    `CMP(io_out_bits_uop_regCacheIdx_1)
    `CMP(io_out_bits_uop_robIdx_flag)
    `CMP(io_out_bits_uop_robIdx_value)
    `CMP(io_out_bits_uop_instrSize)
    `CMP(io_out_bits_uop_dirtyFs)
    `CMP(io_out_bits_uop_dirtyVs)
    `CMP(io_out_bits_uop_traceBlockInPipe_itype)
    `CMP(io_out_bits_uop_traceBlockInPipe_iretire)
    `CMP(io_out_bits_uop_traceBlockInPipe_ilastsize)
    `CMP(io_out_bits_uop_eliminatedMove)
    `CMP(io_out_bits_uop_snapshot)
    `CMP(io_out_bits_uop_debugInfo_eliminatedMove)
    `CMP(io_out_bits_uop_debugInfo_renameTime)
    `CMP(io_out_bits_uop_debugInfo_dispatchTime)
    `CMP(io_out_bits_uop_debugInfo_enqRsTime)
    `CMP(io_out_bits_uop_debugInfo_selectTime)
    `CMP(io_out_bits_uop_debugInfo_issueTime)
    `CMP(io_out_bits_uop_debugInfo_writebackTime)
    `CMP(io_out_bits_uop_debugInfo_runahead_checkpoint_id)
    `CMP(io_out_bits_uop_debugInfo_tlbFirstReqTime)
    `CMP(io_out_bits_uop_debugInfo_tlbRespTime)
    `CMP(io_out_bits_uop_debug_seqNum_seqNum)
    `CMP(io_out_bits_uop_debug_seqNum_uopIdx)
    `CMP(io_out_bits_uop_storeSetHit)
    `CMP(io_out_bits_uop_waitForRobIdx_flag)
    `CMP(io_out_bits_uop_waitForRobIdx_value)
    `CMP(io_out_bits_uop_loadWaitBit)
    `CMP(io_out_bits_uop_loadWaitStrict)
    `CMP(io_out_bits_uop_ssid)
    `CMP(io_out_bits_uop_lqIdx_flag)
    `CMP(io_out_bits_uop_lqIdx_value)
    `CMP(io_out_bits_uop_sqIdx_flag)
    `CMP(io_out_bits_uop_sqIdx_value)
    `CMP(io_out_bits_uop_singleStep)
    `CMP(io_out_bits_uop_replayInst)
    `CMP(io_out_bits_uop_debug_fuType)
    `CMP(io_out_bits_uop_debug_sim_trig)
    `CMP(io_out_bits_uop_numLsElem)
    `CMP(io_out_bits_mBIndex)
    `CMP(io_out_bits_elemIdx)
    `CMP(io_out_bits_elemIdxInsideVd)
    `CMP(io_out_bits_splitIndex)
  endtask

  // 一条向量访存 uop 的整形：操作码按 mop 与三种特殊 unit-stride 分桶；倍数 / 宽度 / nf / uopIdx 取
  // 合法范围为主、偶尔全随机（非法编码两侧也必须一致）；vl / vstart 取小值让掩码区间落在可见范围。
  task automatic shape_uop();
    logic [1:0] mop;
    logic [4:0] low5;
    mop = 2'($urandom);
    case ($urandom_range(0, 9))
      0, 1:    low5 = 5'h08;                 // whole-register
      2:       low5 = 5'h0B;                 // mask 型
      3:       low5 = 5'h10;                 // fault-only-first（load）
      4:       low5 = 5'($urandom);
      default: low5 = 5'h00;
    endcase
    io_in_bits_uop_fuOpType  = {(0 ? 2'b10 : 2'b01), mop, low5};
    if ($urandom_range(0, 15) == 0) io_in_bits_uop_fuOpType = 9'($urandom);
    if ($urandom_range(0, 7) != 0) io_in_bits_uop_vpu_vlmul = 3'($urandom_range(5, 11));   // 5,6,7,0,1,2,3
    case ($urandom_range(0, 7))
      0, 1, 2, 3: io_in_bits_uop_vpu_nf = 3'd0;
      4:          io_in_bits_uop_vpu_nf = 3'd1;
      5:          io_in_bits_uop_vpu_nf = 3'd3;
      6:          io_in_bits_uop_vpu_nf = 3'd7;
      default:    io_in_bits_uop_vpu_nf = 3'($urandom);
    endcase
    if ($urandom_range(0, 3) != 0) io_in_bits_uop_vpu_vuopIdx = 7'($urandom_range(0, 7));
    io_in_bits_src_4 = 128'($urandom_range(0, 3) == 0 ? $urandom_range(0, 255) : $urandom_range(0, 40));
    io_in_bits_uop_vpu_vstart = ($urandom_range(0, 3) == 0) ? 8'($urandom_range(0, 20)) : 8'h0;
    io_in_bits_isVecPartReplay = ($urandom_range(0, 7) == 0);
    io_in_bits_flowNum = ($urandom_range(0, 7) == 0) ? 5'($urandom) : 5'($urandom_range(1, 8));
    io_in_valid        = ($urandom_range(0, 3) != 0);
    io_redirect_valid  = ($urandom_range(0, 15) == 0);
    io_threshold_valid = ($urandom_range(0, 3) == 0);
    if ($urandom_range(0, 1)) begin
      io_threshold_bits_robIdx_flag  = io_in_bits_uop_robIdx_flag;
      io_threshold_bits_robIdx_value = io_in_bits_uop_robIdx_value;
      if ($urandom_range(0, 3) != 0) io_threshold_bits_uopIdx = io_in_bits_uop_vpu_vuopIdx;
    end
    io_toMergeBuffer_req_ready  = ($urandom_range(0, 3) != 0);
    io_toMergeBuffer_resp_valid = ($urandom_range(0, 3) != 0);
  endtask

  task automatic drive();
    drive_random();
    shape_uop();
    io_out_ready = ($urandom_range(0, 3) != 0);
    io_redirect_valid = ($urandom_range(0, 31) == 0);
    io_fromPipeline_0_valid = ($urandom_range(0, 3) == 0);
    io_fromPipeline_1_valid = ($urandom_range(0, 3) == 0);
    io_fromPipeline_2_valid = ($urandom_range(0, 3) == 0);
    if ($urandom_range(0, 1)) io_fromPipeline_0_bits_mBIndex = u_golden.splitBuffer.uopq_mBIndex;
  endtask
  task automatic quiesce();
    io_in_valid = 0;
  endtask

`define P u_impl.splitPipeline.u_core
`define B u_impl.splitBuffer.u_core
`define K u_impl.VSSplitSkidBuffer.u_core

  localparam int NCOV = 13;
  longint cov [NCOV];
  string  cov_names [NCOV] = '{"pipeline_s0_fire", "pipeline_out_fire", "skid_capture", "skid_state", "skid_flush_passthru", "skid_flush_buffered", "buffer_enqueue", "buffer_active_issue", "buffer_inactive_skip", "buffer_split_finish", "buffer_need_cancel", "out_blocked", "load_stop_wait"};
  int     cov_min   [NCOV] = '{1000, 1000, 200, 200, 10, 5, 1000, 1000, 200, 500, 50, 200, 20};
  task automatic collect_cov();
    if (`P.s0_fire) cov[0]++;
    if (`P.out_valid & `P.out_ready) cov[1]++;
    if (`K.capture) cov[2]++;
    if (`K.state) cov[3]++;
    if (`K.flush & ~`K.state & `K.in_valid) cov[4]++;
    if (`K.flush & `K.state) cov[5]++;
    if (`B.doEnqueue) cov[6]++;
    if (`B.activeIssue) cov[7]++;
    if (`B.inActiveIssue) cov[8]++;
    if (`B.splitFinish & `B.issuedThisCycle) cov[9]++;
    if (`B.needCancel) cov[10]++;
    if (`B.out_valid & ~io_out_ready) cov[11]++;
    if (`B.issueValid & `B.vecActive & ~`B.splitCanGo) cov[12]++;
  endtask

  initial begin
    int bad = 0;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    if (!$value$plusargs("warmup=%d", WARMUP))   WARMUP  = 0;
    for (int i = 0; i < NCOV; i++) cov[i] = 0;
    reset = 1'b1;
    drive();
    quiesce();
    repeat (5) @(negedge clock);
    reset = 1'b0;
    for (int c = 0; c < NCYCLES + WARMUP; c++) begin
      drive();
      #4;
      if (c >= WARMUP) begin
        compare();
        collect_cov();
      end
      @(negedge clock);
    end
    for (int i = 0; i < NCOV; i++) begin
      $display("  cov %-24s = %0d (min %0d)%s", cov_names[i], cov[i], cov_min[i],
               (cov[i] < cov_min[i]) ? "  <-- LOW" : "");
      if (cov[i] < cov_min[i]) bad++;
    end
    $display("=== COVERAGE (VLSplitImp) === checks=%0d uncovered=%0d", checks, bad);
    if (bad != 0) begin $display("COVERAGE INSUFFICIENT"); errors++; end
    $display("VLSplitImp UT: checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED (checks=%0d)", checks);
    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);
    $finish;
  end
endmodule
