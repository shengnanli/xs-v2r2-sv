// =============================================================================
// VSSplitBufferImp UT —— golden VSSplitBufferImp 对重写 VSSplitBufferImp_xs 双例化，同激励逐拍比全部 178 根输出。
// 本文件由 scripts/gen_vsplit.py 生成（端口连接 / 随机驱动 / 逐根比较是机械部分，
// 激励整形与覆盖判据是生成器里 TB_* 的手写部分）。勿手改。
//
// 激励要点：入队 valid 1/2；flowNum 逐元素拆时 1..16、unit-stride 时 2；usMask 一半时间高半为 0
//   （一次访问就够）；indexVlMaxInVd 取 2^k-1；部分重放 1/8；out_ready 3/4；redirect 1/32。
//   store：非对齐缓冲空闲 / 标量发射 / SQ 队头向量各随机；
//   load ：三个 load 流水写回 valid 各 1/4，mBIndex 一半时间对准缓冲里这条 uop。
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
  logic [15:0]   io_in_bits_flowMask;
  logic [127:0]  io_in_bits_data;
  logic [63:0]   io_in_bits_baseAddr;
  logic [63:0]   io_in_bits_uopAddr;
  logic [127:0]  io_in_bits_stride;
  logic [4:0]    io_in_bits_flowNum;
  logic [1:0]    io_in_bits_eew;
  logic [2:0]    io_in_bits_sew;
  logic [2:0]    io_in_bits_emul;
  logic [2:0]    io_in_bits_lmul;
  logic [2:0]    io_in_bits_instType;
  logic [4:0]    io_in_bits_indexedSplitOffset;
  logic [31:0]   io_in_bits_uop_instr;
  logic [49:0]   io_in_bits_uop_pc;
  logic [9:0]    io_in_bits_uop_foldpc;
  logic          io_in_bits_uop_exceptionVec_7;
  logic          io_in_bits_uop_exceptionVec_15;
  logic          io_in_bits_uop_exceptionVec_19;
  logic          io_in_bits_uop_exceptionVec_23;
  logic          io_in_bits_uop_isFetchMalAddr;
  logic          io_in_bits_uop_hasException;
  logic [3:0]    io_in_bits_uop_trigger;
  logic          io_in_bits_uop_preDecodeInfo_valid;
  logic          io_in_bits_uop_preDecodeInfo_isRVC;
  logic [1:0]    io_in_bits_uop_preDecodeInfo_brType;
  logic          io_in_bits_uop_preDecodeInfo_isCall;
  logic          io_in_bits_uop_preDecodeInfo_isRet;
  logic          io_in_bits_uop_pred_taken;
  logic          io_in_bits_uop_crossPageIPFFix;
  logic          io_in_bits_uop_ftqPtr_flag;
  logic [5:0]    io_in_bits_uop_ftqPtr_value;
  logic [3:0]    io_in_bits_uop_ftqOffset;
  logic          io_in_bits_uop_satpFlushFirstFetchFault;
  logic [3:0]    io_in_bits_uop_srcType_0;
  logic [3:0]    io_in_bits_uop_srcType_1;
  logic [3:0]    io_in_bits_uop_srcType_2;
  logic [3:0]    io_in_bits_uop_srcType_3;
  logic [3:0]    io_in_bits_uop_srcType_4;
  logic [5:0]    io_in_bits_uop_ldest;
  logic [34:0]   io_in_bits_uop_fuType;
  logic [8:0]    io_in_bits_uop_fuOpType;
  logic          io_in_bits_uop_rfWen;
  logic          io_in_bits_uop_fpWen;
  logic          io_in_bits_uop_vecWen;
  logic          io_in_bits_uop_v0Wen;
  logic          io_in_bits_uop_vlWen;
  logic          io_in_bits_uop_isXSTrap;
  logic          io_in_bits_uop_waitForward;
  logic          io_in_bits_uop_blockBackward;
  logic          io_in_bits_uop_canRobCompress;
  logic [3:0]    io_in_bits_uop_selImm;
  logic [1:0]    io_in_bits_uop_fpu_typeTagOut;
  logic          io_in_bits_uop_fpu_wflags;
  logic [1:0]    io_in_bits_uop_fpu_typ;
  logic [1:0]    io_in_bits_uop_fpu_fmt;
  logic [2:0]    io_in_bits_uop_fpu_rm;
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
  logic [7:0]    io_in_bits_uop_vpu_vl;
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
  logic          io_in_bits_uop_vlsInstr;
  logic          io_in_bits_uop_wfflags;
  logic          io_in_bits_uop_isMove;
  logic          io_in_bits_uop_isDropAmocasSta;
  logic [6:0]    io_in_bits_uop_uopIdx;
  logic          io_in_bits_uop_isVset;
  logic          io_in_bits_uop_firstUop;
  logic          io_in_bits_uop_lastUop;
  logic [6:0]    io_in_bits_uop_numUops;
  logic [6:0]    io_in_bits_uop_numWB;
  logic [2:0]    io_in_bits_uop_commitType;
  logic          io_in_bits_uop_srcState_0;
  logic          io_in_bits_uop_srcState_1;
  logic          io_in_bits_uop_srcState_2;
  logic          io_in_bits_uop_srcState_3;
  logic          io_in_bits_uop_srcState_4;
  logic [1:0]    io_in_bits_uop_srcLoadDependency_0_0;
  logic [1:0]    io_in_bits_uop_srcLoadDependency_0_1;
  logic [1:0]    io_in_bits_uop_srcLoadDependency_0_2;
  logic [1:0]    io_in_bits_uop_srcLoadDependency_1_0;
  logic [1:0]    io_in_bits_uop_srcLoadDependency_1_1;
  logic [1:0]    io_in_bits_uop_srcLoadDependency_1_2;
  logic [1:0]    io_in_bits_uop_srcLoadDependency_2_0;
  logic [1:0]    io_in_bits_uop_srcLoadDependency_2_1;
  logic [1:0]    io_in_bits_uop_srcLoadDependency_2_2;
  logic [1:0]    io_in_bits_uop_srcLoadDependency_3_0;
  logic [1:0]    io_in_bits_uop_srcLoadDependency_3_1;
  logic [1:0]    io_in_bits_uop_srcLoadDependency_3_2;
  logic [1:0]    io_in_bits_uop_srcLoadDependency_4_0;
  logic [1:0]    io_in_bits_uop_srcLoadDependency_4_1;
  logic [1:0]    io_in_bits_uop_srcLoadDependency_4_2;
  logic [7:0]    io_in_bits_uop_psrc_0;
  logic [7:0]    io_in_bits_uop_psrc_1;
  logic [7:0]    io_in_bits_uop_psrc_2;
  logic [7:0]    io_in_bits_uop_psrc_3;
  logic [7:0]    io_in_bits_uop_psrc_4;
  logic [7:0]    io_in_bits_uop_pdest;
  logic          io_in_bits_uop_useRegCache_0;
  logic          io_in_bits_uop_useRegCache_1;
  logic [4:0]    io_in_bits_uop_regCacheIdx_0;
  logic [4:0]    io_in_bits_uop_regCacheIdx_1;
  logic          io_in_bits_uop_robIdx_flag;
  logic [7:0]    io_in_bits_uop_robIdx_value;
  logic [2:0]    io_in_bits_uop_instrSize;
  logic          io_in_bits_uop_dirtyFs;
  logic          io_in_bits_uop_dirtyVs;
  logic [3:0]    io_in_bits_uop_traceBlockInPipe_itype;
  logic [3:0]    io_in_bits_uop_traceBlockInPipe_iretire;
  logic          io_in_bits_uop_traceBlockInPipe_ilastsize;
  logic          io_in_bits_uop_eliminatedMove;
  logic          io_in_bits_uop_snapshot;
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
  logic          io_in_bits_uop_storeSetHit;
  logic          io_in_bits_uop_waitForRobIdx_flag;
  logic [7:0]    io_in_bits_uop_waitForRobIdx_value;
  logic          io_in_bits_uop_loadWaitBit;
  logic          io_in_bits_uop_loadWaitStrict;
  logic [4:0]    io_in_bits_uop_ssid;
  logic          io_in_bits_uop_lqIdx_flag;
  logic [6:0]    io_in_bits_uop_lqIdx_value;
  logic          io_in_bits_uop_sqIdx_flag;
  logic [5:0]    io_in_bits_uop_sqIdx_value;
  logic          io_in_bits_uop_singleStep;
  logic          io_in_bits_uop_replayInst;
  logic [34:0]   io_in_bits_uop_debug_fuType;
  logic          io_in_bits_uop_debug_sim_trig;
  logic [4:0]    io_in_bits_uop_numLsElem;
  logic          io_in_bits_preIsSplit;
  logic [3:0]    io_in_bits_mBIndex;
  logic [2:0]    io_in_bits_alignedType;
  logic [7:0]    io_in_bits_indexVlMaxInVd;
  logic [3:0]    io_in_bits_usLowBitsAddr;
  logic          io_in_bits_usAligned128;
  logic [31:0]   io_in_bits_usMask;
  logic          io_in_bits_isVecPartReplay;
  logic [15:0]   io_in_bits_vecReplayFlowMask;
  logic          io_out_ready;
  logic          io_vstdMisalign_storeMisalignBufferEmpty;
  logic          io_vstdMisalign_scalaIssueValid;
  logic          io_vstdMisalign_scalaIssueRobIdx_flag;
  logic [7:0]    io_vstdMisalign_scalaIssueRobIdx_value;
  logic          io_vstdMisalign_sqDeqIsVec;
  // ---- 输出：g_ = golden，x_ = 重写 ----
  wire               g_io_in_ready, x_io_in_ready;
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
  wire               g_io_out_bits_uop_exceptionVec_6, x_io_out_bits_uop_exceptionVec_6;
  wire               g_io_out_bits_uop_exceptionVec_7, x_io_out_bits_uop_exceptionVec_7;
  wire               g_io_out_bits_uop_exceptionVec_15, x_io_out_bits_uop_exceptionVec_15;
  wire               g_io_out_bits_uop_exceptionVec_19, x_io_out_bits_uop_exceptionVec_19;
  wire               g_io_out_bits_uop_exceptionVec_23, x_io_out_bits_uop_exceptionVec_23;
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
  wire [34:0]        g_io_out_bits_uop_fuType, x_io_out_bits_uop_fuType;
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
  wire               g_io_vstd_valid, x_io_vstd_valid;
  wire [8:0]         g_io_vstd_bits_uop_fuOpType, x_io_vstd_bits_uop_fuOpType;
  wire               g_io_vstd_bits_uop_sqIdx_flag, x_io_vstd_bits_uop_sqIdx_flag;
  wire [5:0]         g_io_vstd_bits_uop_sqIdx_value, x_io_vstd_bits_uop_sqIdx_value;
  wire [127:0]       g_io_vstd_bits_data, x_io_vstd_bits_data;
  wire [5:0]         g_io_vstd_bits_vecDebug_offset, x_io_vstd_bits_vecDebug_offset;

  VSSplitBufferImp u_golden (
    .clock (clock),
    .reset (reset),
    .io_redirect_valid (io_redirect_valid),
    .io_redirect_bits_robIdx_flag (io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value (io_redirect_bits_robIdx_value),
    .io_redirect_bits_level (io_redirect_bits_level),
    .io_in_ready (g_io_in_ready),
    .io_in_valid (io_in_valid),
    .io_in_bits_flowMask (io_in_bits_flowMask),
    .io_in_bits_data (io_in_bits_data),
    .io_in_bits_baseAddr (io_in_bits_baseAddr),
    .io_in_bits_uopAddr (io_in_bits_uopAddr),
    .io_in_bits_stride (io_in_bits_stride),
    .io_in_bits_flowNum (io_in_bits_flowNum),
    .io_in_bits_eew (io_in_bits_eew),
    .io_in_bits_sew (io_in_bits_sew),
    .io_in_bits_emul (io_in_bits_emul),
    .io_in_bits_lmul (io_in_bits_lmul),
    .io_in_bits_instType (io_in_bits_instType),
    .io_in_bits_indexedSplitOffset (io_in_bits_indexedSplitOffset),
    .io_in_bits_uop_instr (io_in_bits_uop_instr),
    .io_in_bits_uop_pc (io_in_bits_uop_pc),
    .io_in_bits_uop_foldpc (io_in_bits_uop_foldpc),
    .io_in_bits_uop_exceptionVec_7 (io_in_bits_uop_exceptionVec_7),
    .io_in_bits_uop_exceptionVec_15 (io_in_bits_uop_exceptionVec_15),
    .io_in_bits_uop_exceptionVec_19 (io_in_bits_uop_exceptionVec_19),
    .io_in_bits_uop_exceptionVec_23 (io_in_bits_uop_exceptionVec_23),
    .io_in_bits_uop_isFetchMalAddr (io_in_bits_uop_isFetchMalAddr),
    .io_in_bits_uop_hasException (io_in_bits_uop_hasException),
    .io_in_bits_uop_trigger (io_in_bits_uop_trigger),
    .io_in_bits_uop_preDecodeInfo_valid (io_in_bits_uop_preDecodeInfo_valid),
    .io_in_bits_uop_preDecodeInfo_isRVC (io_in_bits_uop_preDecodeInfo_isRVC),
    .io_in_bits_uop_preDecodeInfo_brType (io_in_bits_uop_preDecodeInfo_brType),
    .io_in_bits_uop_preDecodeInfo_isCall (io_in_bits_uop_preDecodeInfo_isCall),
    .io_in_bits_uop_preDecodeInfo_isRet (io_in_bits_uop_preDecodeInfo_isRet),
    .io_in_bits_uop_pred_taken (io_in_bits_uop_pred_taken),
    .io_in_bits_uop_crossPageIPFFix (io_in_bits_uop_crossPageIPFFix),
    .io_in_bits_uop_ftqPtr_flag (io_in_bits_uop_ftqPtr_flag),
    .io_in_bits_uop_ftqPtr_value (io_in_bits_uop_ftqPtr_value),
    .io_in_bits_uop_ftqOffset (io_in_bits_uop_ftqOffset),
    .io_in_bits_uop_satpFlushFirstFetchFault (io_in_bits_uop_satpFlushFirstFetchFault),
    .io_in_bits_uop_srcType_0 (io_in_bits_uop_srcType_0),
    .io_in_bits_uop_srcType_1 (io_in_bits_uop_srcType_1),
    .io_in_bits_uop_srcType_2 (io_in_bits_uop_srcType_2),
    .io_in_bits_uop_srcType_3 (io_in_bits_uop_srcType_3),
    .io_in_bits_uop_srcType_4 (io_in_bits_uop_srcType_4),
    .io_in_bits_uop_ldest (io_in_bits_uop_ldest),
    .io_in_bits_uop_fuType (io_in_bits_uop_fuType),
    .io_in_bits_uop_fuOpType (io_in_bits_uop_fuOpType),
    .io_in_bits_uop_rfWen (io_in_bits_uop_rfWen),
    .io_in_bits_uop_fpWen (io_in_bits_uop_fpWen),
    .io_in_bits_uop_vecWen (io_in_bits_uop_vecWen),
    .io_in_bits_uop_v0Wen (io_in_bits_uop_v0Wen),
    .io_in_bits_uop_vlWen (io_in_bits_uop_vlWen),
    .io_in_bits_uop_isXSTrap (io_in_bits_uop_isXSTrap),
    .io_in_bits_uop_waitForward (io_in_bits_uop_waitForward),
    .io_in_bits_uop_blockBackward (io_in_bits_uop_blockBackward),
    .io_in_bits_uop_canRobCompress (io_in_bits_uop_canRobCompress),
    .io_in_bits_uop_selImm (io_in_bits_uop_selImm),
    .io_in_bits_uop_fpu_typeTagOut (io_in_bits_uop_fpu_typeTagOut),
    .io_in_bits_uop_fpu_wflags (io_in_bits_uop_fpu_wflags),
    .io_in_bits_uop_fpu_typ (io_in_bits_uop_fpu_typ),
    .io_in_bits_uop_fpu_fmt (io_in_bits_uop_fpu_fmt),
    .io_in_bits_uop_fpu_rm (io_in_bits_uop_fpu_rm),
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
    .io_in_bits_uop_vpu_vl (io_in_bits_uop_vpu_vl),
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
    .io_in_bits_uop_vlsInstr (io_in_bits_uop_vlsInstr),
    .io_in_bits_uop_wfflags (io_in_bits_uop_wfflags),
    .io_in_bits_uop_isMove (io_in_bits_uop_isMove),
    .io_in_bits_uop_isDropAmocasSta (io_in_bits_uop_isDropAmocasSta),
    .io_in_bits_uop_uopIdx (io_in_bits_uop_uopIdx),
    .io_in_bits_uop_isVset (io_in_bits_uop_isVset),
    .io_in_bits_uop_firstUop (io_in_bits_uop_firstUop),
    .io_in_bits_uop_lastUop (io_in_bits_uop_lastUop),
    .io_in_bits_uop_numUops (io_in_bits_uop_numUops),
    .io_in_bits_uop_numWB (io_in_bits_uop_numWB),
    .io_in_bits_uop_commitType (io_in_bits_uop_commitType),
    .io_in_bits_uop_srcState_0 (io_in_bits_uop_srcState_0),
    .io_in_bits_uop_srcState_1 (io_in_bits_uop_srcState_1),
    .io_in_bits_uop_srcState_2 (io_in_bits_uop_srcState_2),
    .io_in_bits_uop_srcState_3 (io_in_bits_uop_srcState_3),
    .io_in_bits_uop_srcState_4 (io_in_bits_uop_srcState_4),
    .io_in_bits_uop_srcLoadDependency_0_0 (io_in_bits_uop_srcLoadDependency_0_0),
    .io_in_bits_uop_srcLoadDependency_0_1 (io_in_bits_uop_srcLoadDependency_0_1),
    .io_in_bits_uop_srcLoadDependency_0_2 (io_in_bits_uop_srcLoadDependency_0_2),
    .io_in_bits_uop_srcLoadDependency_1_0 (io_in_bits_uop_srcLoadDependency_1_0),
    .io_in_bits_uop_srcLoadDependency_1_1 (io_in_bits_uop_srcLoadDependency_1_1),
    .io_in_bits_uop_srcLoadDependency_1_2 (io_in_bits_uop_srcLoadDependency_1_2),
    .io_in_bits_uop_srcLoadDependency_2_0 (io_in_bits_uop_srcLoadDependency_2_0),
    .io_in_bits_uop_srcLoadDependency_2_1 (io_in_bits_uop_srcLoadDependency_2_1),
    .io_in_bits_uop_srcLoadDependency_2_2 (io_in_bits_uop_srcLoadDependency_2_2),
    .io_in_bits_uop_srcLoadDependency_3_0 (io_in_bits_uop_srcLoadDependency_3_0),
    .io_in_bits_uop_srcLoadDependency_3_1 (io_in_bits_uop_srcLoadDependency_3_1),
    .io_in_bits_uop_srcLoadDependency_3_2 (io_in_bits_uop_srcLoadDependency_3_2),
    .io_in_bits_uop_srcLoadDependency_4_0 (io_in_bits_uop_srcLoadDependency_4_0),
    .io_in_bits_uop_srcLoadDependency_4_1 (io_in_bits_uop_srcLoadDependency_4_1),
    .io_in_bits_uop_srcLoadDependency_4_2 (io_in_bits_uop_srcLoadDependency_4_2),
    .io_in_bits_uop_psrc_0 (io_in_bits_uop_psrc_0),
    .io_in_bits_uop_psrc_1 (io_in_bits_uop_psrc_1),
    .io_in_bits_uop_psrc_2 (io_in_bits_uop_psrc_2),
    .io_in_bits_uop_psrc_3 (io_in_bits_uop_psrc_3),
    .io_in_bits_uop_psrc_4 (io_in_bits_uop_psrc_4),
    .io_in_bits_uop_pdest (io_in_bits_uop_pdest),
    .io_in_bits_uop_useRegCache_0 (io_in_bits_uop_useRegCache_0),
    .io_in_bits_uop_useRegCache_1 (io_in_bits_uop_useRegCache_1),
    .io_in_bits_uop_regCacheIdx_0 (io_in_bits_uop_regCacheIdx_0),
    .io_in_bits_uop_regCacheIdx_1 (io_in_bits_uop_regCacheIdx_1),
    .io_in_bits_uop_robIdx_flag (io_in_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value (io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_instrSize (io_in_bits_uop_instrSize),
    .io_in_bits_uop_dirtyFs (io_in_bits_uop_dirtyFs),
    .io_in_bits_uop_dirtyVs (io_in_bits_uop_dirtyVs),
    .io_in_bits_uop_traceBlockInPipe_itype (io_in_bits_uop_traceBlockInPipe_itype),
    .io_in_bits_uop_traceBlockInPipe_iretire (io_in_bits_uop_traceBlockInPipe_iretire),
    .io_in_bits_uop_traceBlockInPipe_ilastsize (io_in_bits_uop_traceBlockInPipe_ilastsize),
    .io_in_bits_uop_eliminatedMove (io_in_bits_uop_eliminatedMove),
    .io_in_bits_uop_snapshot (io_in_bits_uop_snapshot),
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
    .io_in_bits_uop_storeSetHit (io_in_bits_uop_storeSetHit),
    .io_in_bits_uop_waitForRobIdx_flag (io_in_bits_uop_waitForRobIdx_flag),
    .io_in_bits_uop_waitForRobIdx_value (io_in_bits_uop_waitForRobIdx_value),
    .io_in_bits_uop_loadWaitBit (io_in_bits_uop_loadWaitBit),
    .io_in_bits_uop_loadWaitStrict (io_in_bits_uop_loadWaitStrict),
    .io_in_bits_uop_ssid (io_in_bits_uop_ssid),
    .io_in_bits_uop_lqIdx_flag (io_in_bits_uop_lqIdx_flag),
    .io_in_bits_uop_lqIdx_value (io_in_bits_uop_lqIdx_value),
    .io_in_bits_uop_sqIdx_flag (io_in_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value (io_in_bits_uop_sqIdx_value),
    .io_in_bits_uop_singleStep (io_in_bits_uop_singleStep),
    .io_in_bits_uop_replayInst (io_in_bits_uop_replayInst),
    .io_in_bits_uop_debug_fuType (io_in_bits_uop_debug_fuType),
    .io_in_bits_uop_debug_sim_trig (io_in_bits_uop_debug_sim_trig),
    .io_in_bits_uop_numLsElem (io_in_bits_uop_numLsElem),
    .io_in_bits_preIsSplit (io_in_bits_preIsSplit),
    .io_in_bits_mBIndex (io_in_bits_mBIndex),
    .io_in_bits_alignedType (io_in_bits_alignedType),
    .io_in_bits_indexVlMaxInVd (io_in_bits_indexVlMaxInVd),
    .io_in_bits_usLowBitsAddr (io_in_bits_usLowBitsAddr),
    .io_in_bits_usAligned128 (io_in_bits_usAligned128),
    .io_in_bits_usMask (io_in_bits_usMask),
    .io_in_bits_isVecPartReplay (io_in_bits_isVecPartReplay),
    .io_in_bits_vecReplayFlowMask (io_in_bits_vecReplayFlowMask),
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
    .io_out_bits_uop_exceptionVec_6 (g_io_out_bits_uop_exceptionVec_6),
    .io_out_bits_uop_exceptionVec_7 (g_io_out_bits_uop_exceptionVec_7),
    .io_out_bits_uop_exceptionVec_15 (g_io_out_bits_uop_exceptionVec_15),
    .io_out_bits_uop_exceptionVec_19 (g_io_out_bits_uop_exceptionVec_19),
    .io_out_bits_uop_exceptionVec_23 (g_io_out_bits_uop_exceptionVec_23),
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
    .io_out_bits_uop_fuType (g_io_out_bits_uop_fuType),
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
    .io_vstd_valid (g_io_vstd_valid),
    .io_vstd_bits_uop_fuOpType (g_io_vstd_bits_uop_fuOpType),
    .io_vstd_bits_uop_sqIdx_flag (g_io_vstd_bits_uop_sqIdx_flag),
    .io_vstd_bits_uop_sqIdx_value (g_io_vstd_bits_uop_sqIdx_value),
    .io_vstd_bits_data (g_io_vstd_bits_data),
    .io_vstd_bits_vecDebug_offset (g_io_vstd_bits_vecDebug_offset),
    .io_vstdMisalign_storeMisalignBufferEmpty (io_vstdMisalign_storeMisalignBufferEmpty),
    .io_vstdMisalign_scalaIssueValid (io_vstdMisalign_scalaIssueValid),
    .io_vstdMisalign_scalaIssueRobIdx_flag (io_vstdMisalign_scalaIssueRobIdx_flag),
    .io_vstdMisalign_scalaIssueRobIdx_value (io_vstdMisalign_scalaIssueRobIdx_value),
    .io_vstdMisalign_sqDeqIsVec (io_vstdMisalign_sqDeqIsVec)
  );

  VSSplitBufferImp_xs u_impl (
    .clock (clock),
    .reset (reset),
    .io_redirect_valid (io_redirect_valid),
    .io_redirect_bits_robIdx_flag (io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value (io_redirect_bits_robIdx_value),
    .io_redirect_bits_level (io_redirect_bits_level),
    .io_in_ready (x_io_in_ready),
    .io_in_valid (io_in_valid),
    .io_in_bits_flowMask (io_in_bits_flowMask),
    .io_in_bits_data (io_in_bits_data),
    .io_in_bits_baseAddr (io_in_bits_baseAddr),
    .io_in_bits_uopAddr (io_in_bits_uopAddr),
    .io_in_bits_stride (io_in_bits_stride),
    .io_in_bits_flowNum (io_in_bits_flowNum),
    .io_in_bits_eew (io_in_bits_eew),
    .io_in_bits_sew (io_in_bits_sew),
    .io_in_bits_emul (io_in_bits_emul),
    .io_in_bits_lmul (io_in_bits_lmul),
    .io_in_bits_instType (io_in_bits_instType),
    .io_in_bits_indexedSplitOffset (io_in_bits_indexedSplitOffset),
    .io_in_bits_uop_instr (io_in_bits_uop_instr),
    .io_in_bits_uop_pc (io_in_bits_uop_pc),
    .io_in_bits_uop_foldpc (io_in_bits_uop_foldpc),
    .io_in_bits_uop_exceptionVec_7 (io_in_bits_uop_exceptionVec_7),
    .io_in_bits_uop_exceptionVec_15 (io_in_bits_uop_exceptionVec_15),
    .io_in_bits_uop_exceptionVec_19 (io_in_bits_uop_exceptionVec_19),
    .io_in_bits_uop_exceptionVec_23 (io_in_bits_uop_exceptionVec_23),
    .io_in_bits_uop_isFetchMalAddr (io_in_bits_uop_isFetchMalAddr),
    .io_in_bits_uop_hasException (io_in_bits_uop_hasException),
    .io_in_bits_uop_trigger (io_in_bits_uop_trigger),
    .io_in_bits_uop_preDecodeInfo_valid (io_in_bits_uop_preDecodeInfo_valid),
    .io_in_bits_uop_preDecodeInfo_isRVC (io_in_bits_uop_preDecodeInfo_isRVC),
    .io_in_bits_uop_preDecodeInfo_brType (io_in_bits_uop_preDecodeInfo_brType),
    .io_in_bits_uop_preDecodeInfo_isCall (io_in_bits_uop_preDecodeInfo_isCall),
    .io_in_bits_uop_preDecodeInfo_isRet (io_in_bits_uop_preDecodeInfo_isRet),
    .io_in_bits_uop_pred_taken (io_in_bits_uop_pred_taken),
    .io_in_bits_uop_crossPageIPFFix (io_in_bits_uop_crossPageIPFFix),
    .io_in_bits_uop_ftqPtr_flag (io_in_bits_uop_ftqPtr_flag),
    .io_in_bits_uop_ftqPtr_value (io_in_bits_uop_ftqPtr_value),
    .io_in_bits_uop_ftqOffset (io_in_bits_uop_ftqOffset),
    .io_in_bits_uop_satpFlushFirstFetchFault (io_in_bits_uop_satpFlushFirstFetchFault),
    .io_in_bits_uop_srcType_0 (io_in_bits_uop_srcType_0),
    .io_in_bits_uop_srcType_1 (io_in_bits_uop_srcType_1),
    .io_in_bits_uop_srcType_2 (io_in_bits_uop_srcType_2),
    .io_in_bits_uop_srcType_3 (io_in_bits_uop_srcType_3),
    .io_in_bits_uop_srcType_4 (io_in_bits_uop_srcType_4),
    .io_in_bits_uop_ldest (io_in_bits_uop_ldest),
    .io_in_bits_uop_fuType (io_in_bits_uop_fuType),
    .io_in_bits_uop_fuOpType (io_in_bits_uop_fuOpType),
    .io_in_bits_uop_rfWen (io_in_bits_uop_rfWen),
    .io_in_bits_uop_fpWen (io_in_bits_uop_fpWen),
    .io_in_bits_uop_vecWen (io_in_bits_uop_vecWen),
    .io_in_bits_uop_v0Wen (io_in_bits_uop_v0Wen),
    .io_in_bits_uop_vlWen (io_in_bits_uop_vlWen),
    .io_in_bits_uop_isXSTrap (io_in_bits_uop_isXSTrap),
    .io_in_bits_uop_waitForward (io_in_bits_uop_waitForward),
    .io_in_bits_uop_blockBackward (io_in_bits_uop_blockBackward),
    .io_in_bits_uop_canRobCompress (io_in_bits_uop_canRobCompress),
    .io_in_bits_uop_selImm (io_in_bits_uop_selImm),
    .io_in_bits_uop_fpu_typeTagOut (io_in_bits_uop_fpu_typeTagOut),
    .io_in_bits_uop_fpu_wflags (io_in_bits_uop_fpu_wflags),
    .io_in_bits_uop_fpu_typ (io_in_bits_uop_fpu_typ),
    .io_in_bits_uop_fpu_fmt (io_in_bits_uop_fpu_fmt),
    .io_in_bits_uop_fpu_rm (io_in_bits_uop_fpu_rm),
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
    .io_in_bits_uop_vpu_vl (io_in_bits_uop_vpu_vl),
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
    .io_in_bits_uop_vlsInstr (io_in_bits_uop_vlsInstr),
    .io_in_bits_uop_wfflags (io_in_bits_uop_wfflags),
    .io_in_bits_uop_isMove (io_in_bits_uop_isMove),
    .io_in_bits_uop_isDropAmocasSta (io_in_bits_uop_isDropAmocasSta),
    .io_in_bits_uop_uopIdx (io_in_bits_uop_uopIdx),
    .io_in_bits_uop_isVset (io_in_bits_uop_isVset),
    .io_in_bits_uop_firstUop (io_in_bits_uop_firstUop),
    .io_in_bits_uop_lastUop (io_in_bits_uop_lastUop),
    .io_in_bits_uop_numUops (io_in_bits_uop_numUops),
    .io_in_bits_uop_numWB (io_in_bits_uop_numWB),
    .io_in_bits_uop_commitType (io_in_bits_uop_commitType),
    .io_in_bits_uop_srcState_0 (io_in_bits_uop_srcState_0),
    .io_in_bits_uop_srcState_1 (io_in_bits_uop_srcState_1),
    .io_in_bits_uop_srcState_2 (io_in_bits_uop_srcState_2),
    .io_in_bits_uop_srcState_3 (io_in_bits_uop_srcState_3),
    .io_in_bits_uop_srcState_4 (io_in_bits_uop_srcState_4),
    .io_in_bits_uop_srcLoadDependency_0_0 (io_in_bits_uop_srcLoadDependency_0_0),
    .io_in_bits_uop_srcLoadDependency_0_1 (io_in_bits_uop_srcLoadDependency_0_1),
    .io_in_bits_uop_srcLoadDependency_0_2 (io_in_bits_uop_srcLoadDependency_0_2),
    .io_in_bits_uop_srcLoadDependency_1_0 (io_in_bits_uop_srcLoadDependency_1_0),
    .io_in_bits_uop_srcLoadDependency_1_1 (io_in_bits_uop_srcLoadDependency_1_1),
    .io_in_bits_uop_srcLoadDependency_1_2 (io_in_bits_uop_srcLoadDependency_1_2),
    .io_in_bits_uop_srcLoadDependency_2_0 (io_in_bits_uop_srcLoadDependency_2_0),
    .io_in_bits_uop_srcLoadDependency_2_1 (io_in_bits_uop_srcLoadDependency_2_1),
    .io_in_bits_uop_srcLoadDependency_2_2 (io_in_bits_uop_srcLoadDependency_2_2),
    .io_in_bits_uop_srcLoadDependency_3_0 (io_in_bits_uop_srcLoadDependency_3_0),
    .io_in_bits_uop_srcLoadDependency_3_1 (io_in_bits_uop_srcLoadDependency_3_1),
    .io_in_bits_uop_srcLoadDependency_3_2 (io_in_bits_uop_srcLoadDependency_3_2),
    .io_in_bits_uop_srcLoadDependency_4_0 (io_in_bits_uop_srcLoadDependency_4_0),
    .io_in_bits_uop_srcLoadDependency_4_1 (io_in_bits_uop_srcLoadDependency_4_1),
    .io_in_bits_uop_srcLoadDependency_4_2 (io_in_bits_uop_srcLoadDependency_4_2),
    .io_in_bits_uop_psrc_0 (io_in_bits_uop_psrc_0),
    .io_in_bits_uop_psrc_1 (io_in_bits_uop_psrc_1),
    .io_in_bits_uop_psrc_2 (io_in_bits_uop_psrc_2),
    .io_in_bits_uop_psrc_3 (io_in_bits_uop_psrc_3),
    .io_in_bits_uop_psrc_4 (io_in_bits_uop_psrc_4),
    .io_in_bits_uop_pdest (io_in_bits_uop_pdest),
    .io_in_bits_uop_useRegCache_0 (io_in_bits_uop_useRegCache_0),
    .io_in_bits_uop_useRegCache_1 (io_in_bits_uop_useRegCache_1),
    .io_in_bits_uop_regCacheIdx_0 (io_in_bits_uop_regCacheIdx_0),
    .io_in_bits_uop_regCacheIdx_1 (io_in_bits_uop_regCacheIdx_1),
    .io_in_bits_uop_robIdx_flag (io_in_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value (io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_instrSize (io_in_bits_uop_instrSize),
    .io_in_bits_uop_dirtyFs (io_in_bits_uop_dirtyFs),
    .io_in_bits_uop_dirtyVs (io_in_bits_uop_dirtyVs),
    .io_in_bits_uop_traceBlockInPipe_itype (io_in_bits_uop_traceBlockInPipe_itype),
    .io_in_bits_uop_traceBlockInPipe_iretire (io_in_bits_uop_traceBlockInPipe_iretire),
    .io_in_bits_uop_traceBlockInPipe_ilastsize (io_in_bits_uop_traceBlockInPipe_ilastsize),
    .io_in_bits_uop_eliminatedMove (io_in_bits_uop_eliminatedMove),
    .io_in_bits_uop_snapshot (io_in_bits_uop_snapshot),
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
    .io_in_bits_uop_storeSetHit (io_in_bits_uop_storeSetHit),
    .io_in_bits_uop_waitForRobIdx_flag (io_in_bits_uop_waitForRobIdx_flag),
    .io_in_bits_uop_waitForRobIdx_value (io_in_bits_uop_waitForRobIdx_value),
    .io_in_bits_uop_loadWaitBit (io_in_bits_uop_loadWaitBit),
    .io_in_bits_uop_loadWaitStrict (io_in_bits_uop_loadWaitStrict),
    .io_in_bits_uop_ssid (io_in_bits_uop_ssid),
    .io_in_bits_uop_lqIdx_flag (io_in_bits_uop_lqIdx_flag),
    .io_in_bits_uop_lqIdx_value (io_in_bits_uop_lqIdx_value),
    .io_in_bits_uop_sqIdx_flag (io_in_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value (io_in_bits_uop_sqIdx_value),
    .io_in_bits_uop_singleStep (io_in_bits_uop_singleStep),
    .io_in_bits_uop_replayInst (io_in_bits_uop_replayInst),
    .io_in_bits_uop_debug_fuType (io_in_bits_uop_debug_fuType),
    .io_in_bits_uop_debug_sim_trig (io_in_bits_uop_debug_sim_trig),
    .io_in_bits_uop_numLsElem (io_in_bits_uop_numLsElem),
    .io_in_bits_preIsSplit (io_in_bits_preIsSplit),
    .io_in_bits_mBIndex (io_in_bits_mBIndex),
    .io_in_bits_alignedType (io_in_bits_alignedType),
    .io_in_bits_indexVlMaxInVd (io_in_bits_indexVlMaxInVd),
    .io_in_bits_usLowBitsAddr (io_in_bits_usLowBitsAddr),
    .io_in_bits_usAligned128 (io_in_bits_usAligned128),
    .io_in_bits_usMask (io_in_bits_usMask),
    .io_in_bits_isVecPartReplay (io_in_bits_isVecPartReplay),
    .io_in_bits_vecReplayFlowMask (io_in_bits_vecReplayFlowMask),
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
    .io_out_bits_uop_exceptionVec_6 (x_io_out_bits_uop_exceptionVec_6),
    .io_out_bits_uop_exceptionVec_7 (x_io_out_bits_uop_exceptionVec_7),
    .io_out_bits_uop_exceptionVec_15 (x_io_out_bits_uop_exceptionVec_15),
    .io_out_bits_uop_exceptionVec_19 (x_io_out_bits_uop_exceptionVec_19),
    .io_out_bits_uop_exceptionVec_23 (x_io_out_bits_uop_exceptionVec_23),
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
    .io_out_bits_uop_fuType (x_io_out_bits_uop_fuType),
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
    .io_vstd_valid (x_io_vstd_valid),
    .io_vstd_bits_uop_fuOpType (x_io_vstd_bits_uop_fuOpType),
    .io_vstd_bits_uop_sqIdx_flag (x_io_vstd_bits_uop_sqIdx_flag),
    .io_vstd_bits_uop_sqIdx_value (x_io_vstd_bits_uop_sqIdx_value),
    .io_vstd_bits_data (x_io_vstd_bits_data),
    .io_vstd_bits_vecDebug_offset (x_io_vstd_bits_vecDebug_offset),
    .io_vstdMisalign_storeMisalignBufferEmpty (io_vstdMisalign_storeMisalignBufferEmpty),
    .io_vstdMisalign_scalaIssueValid (io_vstdMisalign_scalaIssueValid),
    .io_vstdMisalign_scalaIssueRobIdx_flag (io_vstdMisalign_scalaIssueRobIdx_flag),
    .io_vstdMisalign_scalaIssueRobIdx_value (io_vstdMisalign_scalaIssueRobIdx_value),
    .io_vstdMisalign_sqDeqIsVec (io_vstdMisalign_sqDeqIsVec)
  );

  // ---- 所有输入整体随机（整形在 drive 里）----
  task automatic drive_random();
    io_redirect_valid = 1'($urandom);
    io_redirect_bits_robIdx_flag = 1'($urandom);
    io_redirect_bits_robIdx_value = 8'($urandom);
    io_redirect_bits_level = 1'($urandom);
    io_in_valid = 1'($urandom);
    io_in_bits_flowMask = 16'($urandom);
    io_in_bits_data = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_bits_baseAddr = 64'({$urandom, $urandom});
    io_in_bits_uopAddr = 64'({$urandom, $urandom});
    io_in_bits_stride = 128'({$urandom, $urandom, $urandom, $urandom});
    io_in_bits_flowNum = 5'($urandom);
    io_in_bits_eew = 2'($urandom);
    io_in_bits_sew = 3'($urandom);
    io_in_bits_emul = 3'($urandom);
    io_in_bits_lmul = 3'($urandom);
    io_in_bits_instType = 3'($urandom);
    io_in_bits_indexedSplitOffset = 5'($urandom);
    io_in_bits_uop_instr = 32'($urandom);
    io_in_bits_uop_pc = 50'({$urandom, $urandom});
    io_in_bits_uop_foldpc = 10'($urandom);
    io_in_bits_uop_exceptionVec_7 = ($urandom_range(0, 7) == 0);
    io_in_bits_uop_exceptionVec_15 = ($urandom_range(0, 7) == 0);
    io_in_bits_uop_exceptionVec_19 = ($urandom_range(0, 7) == 0);
    io_in_bits_uop_exceptionVec_23 = ($urandom_range(0, 7) == 0);
    io_in_bits_uop_isFetchMalAddr = 1'($urandom);
    io_in_bits_uop_hasException = 1'($urandom);
    io_in_bits_uop_trigger = 4'($urandom);
    io_in_bits_uop_preDecodeInfo_valid = 1'($urandom);
    io_in_bits_uop_preDecodeInfo_isRVC = 1'($urandom);
    io_in_bits_uop_preDecodeInfo_brType = 2'($urandom);
    io_in_bits_uop_preDecodeInfo_isCall = 1'($urandom);
    io_in_bits_uop_preDecodeInfo_isRet = 1'($urandom);
    io_in_bits_uop_pred_taken = 1'($urandom);
    io_in_bits_uop_crossPageIPFFix = 1'($urandom);
    io_in_bits_uop_ftqPtr_flag = 1'($urandom);
    io_in_bits_uop_ftqPtr_value = 6'($urandom);
    io_in_bits_uop_ftqOffset = 4'($urandom);
    io_in_bits_uop_satpFlushFirstFetchFault = 1'($urandom);
    io_in_bits_uop_srcType_0 = 4'($urandom);
    io_in_bits_uop_srcType_1 = 4'($urandom);
    io_in_bits_uop_srcType_2 = 4'($urandom);
    io_in_bits_uop_srcType_3 = 4'($urandom);
    io_in_bits_uop_srcType_4 = 4'($urandom);
    io_in_bits_uop_ldest = 6'($urandom);
    io_in_bits_uop_fuType = 35'({$urandom, $urandom});
    io_in_bits_uop_fuOpType = 9'($urandom);
    io_in_bits_uop_rfWen = 1'($urandom);
    io_in_bits_uop_fpWen = 1'($urandom);
    io_in_bits_uop_vecWen = 1'($urandom);
    io_in_bits_uop_v0Wen = 1'($urandom);
    io_in_bits_uop_vlWen = 1'($urandom);
    io_in_bits_uop_isXSTrap = 1'($urandom);
    io_in_bits_uop_waitForward = 1'($urandom);
    io_in_bits_uop_blockBackward = 1'($urandom);
    io_in_bits_uop_canRobCompress = 1'($urandom);
    io_in_bits_uop_selImm = 4'($urandom);
    io_in_bits_uop_fpu_typeTagOut = 2'($urandom);
    io_in_bits_uop_fpu_wflags = 1'($urandom);
    io_in_bits_uop_fpu_typ = 2'($urandom);
    io_in_bits_uop_fpu_fmt = 2'($urandom);
    io_in_bits_uop_fpu_rm = 3'($urandom);
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
    io_in_bits_uop_vpu_vl = 8'($urandom);
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
    io_in_bits_uop_vlsInstr = 1'($urandom);
    io_in_bits_uop_wfflags = 1'($urandom);
    io_in_bits_uop_isMove = 1'($urandom);
    io_in_bits_uop_isDropAmocasSta = 1'($urandom);
    io_in_bits_uop_uopIdx = 7'($urandom);
    io_in_bits_uop_isVset = 1'($urandom);
    io_in_bits_uop_firstUop = 1'($urandom);
    io_in_bits_uop_lastUop = 1'($urandom);
    io_in_bits_uop_numUops = 7'($urandom);
    io_in_bits_uop_numWB = 7'($urandom);
    io_in_bits_uop_commitType = 3'($urandom);
    io_in_bits_uop_srcState_0 = 1'($urandom);
    io_in_bits_uop_srcState_1 = 1'($urandom);
    io_in_bits_uop_srcState_2 = 1'($urandom);
    io_in_bits_uop_srcState_3 = 1'($urandom);
    io_in_bits_uop_srcState_4 = 1'($urandom);
    io_in_bits_uop_srcLoadDependency_0_0 = 2'($urandom);
    io_in_bits_uop_srcLoadDependency_0_1 = 2'($urandom);
    io_in_bits_uop_srcLoadDependency_0_2 = 2'($urandom);
    io_in_bits_uop_srcLoadDependency_1_0 = 2'($urandom);
    io_in_bits_uop_srcLoadDependency_1_1 = 2'($urandom);
    io_in_bits_uop_srcLoadDependency_1_2 = 2'($urandom);
    io_in_bits_uop_srcLoadDependency_2_0 = 2'($urandom);
    io_in_bits_uop_srcLoadDependency_2_1 = 2'($urandom);
    io_in_bits_uop_srcLoadDependency_2_2 = 2'($urandom);
    io_in_bits_uop_srcLoadDependency_3_0 = 2'($urandom);
    io_in_bits_uop_srcLoadDependency_3_1 = 2'($urandom);
    io_in_bits_uop_srcLoadDependency_3_2 = 2'($urandom);
    io_in_bits_uop_srcLoadDependency_4_0 = 2'($urandom);
    io_in_bits_uop_srcLoadDependency_4_1 = 2'($urandom);
    io_in_bits_uop_srcLoadDependency_4_2 = 2'($urandom);
    io_in_bits_uop_psrc_0 = 8'($urandom);
    io_in_bits_uop_psrc_1 = 8'($urandom);
    io_in_bits_uop_psrc_2 = 8'($urandom);
    io_in_bits_uop_psrc_3 = 8'($urandom);
    io_in_bits_uop_psrc_4 = 8'($urandom);
    io_in_bits_uop_pdest = 8'($urandom);
    io_in_bits_uop_useRegCache_0 = 1'($urandom);
    io_in_bits_uop_useRegCache_1 = 1'($urandom);
    io_in_bits_uop_regCacheIdx_0 = 5'($urandom);
    io_in_bits_uop_regCacheIdx_1 = 5'($urandom);
    io_in_bits_uop_robIdx_flag = 1'($urandom);
    io_in_bits_uop_robIdx_value = 8'($urandom);
    io_in_bits_uop_instrSize = 3'($urandom);
    io_in_bits_uop_dirtyFs = 1'($urandom);
    io_in_bits_uop_dirtyVs = 1'($urandom);
    io_in_bits_uop_traceBlockInPipe_itype = 4'($urandom);
    io_in_bits_uop_traceBlockInPipe_iretire = 4'($urandom);
    io_in_bits_uop_traceBlockInPipe_ilastsize = 1'($urandom);
    io_in_bits_uop_eliminatedMove = 1'($urandom);
    io_in_bits_uop_snapshot = 1'($urandom);
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
    io_in_bits_uop_storeSetHit = 1'($urandom);
    io_in_bits_uop_waitForRobIdx_flag = 1'($urandom);
    io_in_bits_uop_waitForRobIdx_value = 8'($urandom);
    io_in_bits_uop_loadWaitBit = 1'($urandom);
    io_in_bits_uop_loadWaitStrict = 1'($urandom);
    io_in_bits_uop_ssid = 5'($urandom);
    io_in_bits_uop_lqIdx_flag = 1'($urandom);
    io_in_bits_uop_lqIdx_value = 7'($urandom);
    io_in_bits_uop_sqIdx_flag = 1'($urandom);
    io_in_bits_uop_sqIdx_value = 6'($urandom);
    io_in_bits_uop_singleStep = 1'($urandom);
    io_in_bits_uop_replayInst = 1'($urandom);
    io_in_bits_uop_debug_fuType = 35'({$urandom, $urandom});
    io_in_bits_uop_debug_sim_trig = 1'($urandom);
    io_in_bits_uop_numLsElem = 5'($urandom);
    io_in_bits_preIsSplit = 1'($urandom);
    io_in_bits_mBIndex = 4'($urandom);
    io_in_bits_alignedType = 3'($urandom);
    io_in_bits_indexVlMaxInVd = 8'($urandom);
    io_in_bits_usLowBitsAddr = 4'($urandom);
    io_in_bits_usAligned128 = 1'($urandom);
    io_in_bits_usMask = 32'($urandom);
    io_in_bits_isVecPartReplay = 1'($urandom);
    io_in_bits_vecReplayFlowMask = 16'($urandom);
    io_out_ready = 1'($urandom);
    io_vstdMisalign_storeMisalignBufferEmpty = 1'($urandom);
    io_vstdMisalign_scalaIssueValid = 1'($urandom);
    io_vstdMisalign_scalaIssueRobIdx_flag = 1'($urandom);
    io_vstdMisalign_scalaIssueRobIdx_value = 8'($urandom);
    io_vstdMisalign_sqDeqIsVec = 1'($urandom);
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
    `CMP(io_out_bits_uop_exceptionVec_6)
    `CMP(io_out_bits_uop_exceptionVec_7)
    `CMP(io_out_bits_uop_exceptionVec_15)
    `CMP(io_out_bits_uop_exceptionVec_19)
    `CMP(io_out_bits_uop_exceptionVec_23)
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
    `CMP(io_out_bits_uop_fuType)
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
    `CMP(io_vstd_valid)
    `CMP(io_vstd_bits_uop_fuOpType)
    `CMP(io_vstd_bits_uop_sqIdx_flag)
    `CMP(io_vstd_bits_uop_sqIdx_value)
    `CMP(io_vstd_bits_data)
    `CMP(io_vstd_bits_vecDebug_offset)
  endtask

  task automatic drive();
    drive_random();
    io_redirect_valid = ($urandom_range(0, 31) == 0);
    io_in_valid       = ($urandom_range(0, 1) == 0);
    io_out_ready      = ($urandom_range(0, 3) != 0);
    io_in_bits_preIsSplit = ($urandom_range(0, 2) != 0);
    io_in_bits_flowNum    = io_in_bits_preIsSplit ? 5'($urandom_range(1, 16)) : 5'd2;
    if ($urandom_range(0, 15) == 0) io_in_bits_flowNum = 5'($urandom);
    if ($urandom_range(0, 1)) io_in_bits_usMask[31:16] = 16'h0;
    if ($urandom_range(0, 3) == 0) io_in_bits_flowMask = 16'hFFFF;
    case ($urandom_range(0, 5))
      0: io_in_bits_indexVlMaxInVd = 8'h00;
      1: io_in_bits_indexVlMaxInVd = 8'h01;
      2: io_in_bits_indexVlMaxInVd = 8'h03;
      3: io_in_bits_indexVlMaxInVd = 8'h07;
      4: io_in_bits_indexVlMaxInVd = 8'h0F;
      default: ;
    endcase
    if ($urandom_range(0, 3) != 0) io_in_bits_alignedType = io_in_bits_preIsSplit ? 3'($urandom_range(0, 3)) : 3'd4;
    if ($urandom_range(0, 3) != 0) io_in_bits_sew = 3'($urandom_range(0, 3));
    io_in_bits_isVecPartReplay = ($urandom_range(0, 7) == 0);
    io_vstdMisalign_storeMisalignBufferEmpty = ($urandom_range(0, 3) != 0);
    io_vstdMisalign_scalaIssueValid          = ($urandom_range(0, 1) == 0);
    io_vstdMisalign_sqDeqIsVec               = ($urandom_range(0, 3) == 0);
  endtask
  task automatic quiesce();
    io_in_valid = 0;
  endtask

`define C u_impl.u_core

  localparam int NCOV = 20;
  longint cov [NCOV];
  string  cov_names [NCOV] = '{"enqueue", "enqueue_while_busy", "enqueue_cancelled", "active_issue", "inactive_skip", "split_finish", "need_cancel", "us_no_split", "us_second_flow", "issue_indexed", "issue_strided", "stride_accumulated", "part_replay_issue", "first_active", "blocked_by_out", "queue_ptr_wrap", "vstd_valid", "vstd_already_issued", "misalign_blocked", "misalign_go"};
  int     cov_min   [NCOV] = '{1000, 100, 20, 1000, 1000, 1000, 100, 100, 100, 500, 500, 500, 100, 500, 200, 100, 1000, 100, 100, 100};
  task automatic collect_cov();
    if (`C.doEnqueue) cov[0]++;
    if (`C.doEnqueue & `C.allocated) cov[1]++;
    if (io_in_valid & `C.canAccept & `C.cancelEnq) cov[2]++;
    if (`C.activeIssue) cov[3]++;
    if (`C.inActiveIssue) cov[4]++;
    if (`C.splitFinish & `C.issuedThisCycle) cov[5]++;
    if (`C.needCancel) cov[6]++;
    if (`C.activeIssue & `C.usNoSplit) cov[7]++;
    if (`C.activeIssue & ~`C.uopq.preIsSplit & (`C.splitIdx == 5'd1)) cov[8]++;
    if (`C.activeIssue & `C.uopq.preIsSplit & `C.isIndexed) cov[9]++;
    if (`C.activeIssue & `C.uopq.preIsSplit & ~`C.isIndexed) cov[10]++;
    if (`C.activeIssue & `C.uopq.preIsSplit & ~`C.isIndexed & (|`C.strideOffsetReg)) cov[11]++;
    if (`C.activeIssue & `C.uopq.isVecPartReplay) cov[12]++;
    if (`C.out_fire & `C.isFirstActive) cov[13]++;
    if (`C.out_valid & ~io_out_ready) cov[14]++;
    if (`C.activeIssue & `C.ptrWrap) cov[15]++;
    if (`C.vstd_valid) cov[16]++;
    if (`C.issueValid & `C.vecActive & `C.g_vstore.dataIssued) cov[17]++;
    if (`C.issueValid & `C.vecActive & ~`C.addrAligned & ~`C.misalignedCanGo) cov[18]++;
    if (`C.activeIssue & ~`C.addrAligned) cov[19]++;
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
    $display("=== COVERAGE (VSSplitBufferImp) === checks=%0d uncovered=%0d", checks, bad);
    if (bad != 0) begin $display("COVERAGE INSUFFICIENT"); errors++; end
    $display("VSSplitBufferImp UT: checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED (checks=%0d)", checks);
    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);
    $finish;
  end
endmodule
