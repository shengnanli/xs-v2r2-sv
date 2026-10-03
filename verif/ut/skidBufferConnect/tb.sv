// skidBufferConnect 双例化 UT（由 gen.py 生成，勿手改）
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= skidBufferConnect =================
  int unsigned s_mode = 0;
  initial begin
    #1;
    force s_u_impl.u_core.dataBuffer = {s_u_gold.dataBuffer_flowMask, s_u_gold.dataBuffer_data, s_u_gold.dataBuffer_baseAddr, s_u_gold.dataBuffer_uopAddr, s_u_gold.dataBuffer_stride, s_u_gold.dataBuffer_flowNum, s_u_gold.dataBuffer_eew, s_u_gold.dataBuffer_sew, s_u_gold.dataBuffer_emul, s_u_gold.dataBuffer_lmul, s_u_gold.dataBuffer_instType, s_u_gold.dataBuffer_indexedSplitOffset, s_u_gold.dataBuffer_uop_instr, s_u_gold.dataBuffer_uop_pc, s_u_gold.dataBuffer_uop_foldpc, s_u_gold.dataBuffer_uop_exceptionVec_5, s_u_gold.dataBuffer_uop_exceptionVec_7, s_u_gold.dataBuffer_uop_exceptionVec_13, s_u_gold.dataBuffer_uop_exceptionVec_15, s_u_gold.dataBuffer_uop_exceptionVec_19, s_u_gold.dataBuffer_uop_exceptionVec_21, s_u_gold.dataBuffer_uop_exceptionVec_23, s_u_gold.dataBuffer_uop_isFetchMalAddr, s_u_gold.dataBuffer_uop_hasException, s_u_gold.dataBuffer_uop_trigger, s_u_gold.dataBuffer_uop_preDecodeInfo_valid, s_u_gold.dataBuffer_uop_preDecodeInfo_isRVC, s_u_gold.dataBuffer_uop_preDecodeInfo_brType, s_u_gold.dataBuffer_uop_preDecodeInfo_isCall, s_u_gold.dataBuffer_uop_preDecodeInfo_isRet, s_u_gold.dataBuffer_uop_pred_taken, s_u_gold.dataBuffer_uop_crossPageIPFFix, s_u_gold.dataBuffer_uop_ftqPtr_flag, s_u_gold.dataBuffer_uop_ftqPtr_value, s_u_gold.dataBuffer_uop_ftqOffset, s_u_gold.dataBuffer_uop_satpFlushFirstFetchFault, s_u_gold.dataBuffer_uop_srcType_0, s_u_gold.dataBuffer_uop_srcType_1, s_u_gold.dataBuffer_uop_srcType_2, s_u_gold.dataBuffer_uop_srcType_3, s_u_gold.dataBuffer_uop_srcType_4, s_u_gold.dataBuffer_uop_ldest, s_u_gold.dataBuffer_uop_fuType, s_u_gold.dataBuffer_uop_fuOpType, s_u_gold.dataBuffer_uop_rfWen, s_u_gold.dataBuffer_uop_fpWen, s_u_gold.dataBuffer_uop_vecWen, s_u_gold.dataBuffer_uop_v0Wen, s_u_gold.dataBuffer_uop_vlWen, s_u_gold.dataBuffer_uop_isXSTrap, s_u_gold.dataBuffer_uop_waitForward, s_u_gold.dataBuffer_uop_blockBackward, s_u_gold.dataBuffer_uop_canRobCompress, s_u_gold.dataBuffer_uop_selImm, s_u_gold.dataBuffer_uop_fpu_typeTagOut, s_u_gold.dataBuffer_uop_fpu_wflags, s_u_gold.dataBuffer_uop_fpu_typ, s_u_gold.dataBuffer_uop_fpu_fmt, s_u_gold.dataBuffer_uop_fpu_rm, s_u_gold.dataBuffer_uop_vpu_vill, s_u_gold.dataBuffer_uop_vpu_vma, s_u_gold.dataBuffer_uop_vpu_vta, s_u_gold.dataBuffer_uop_vpu_vsew, s_u_gold.dataBuffer_uop_vpu_vlmul, s_u_gold.dataBuffer_uop_vpu_specVill, s_u_gold.dataBuffer_uop_vpu_specVma, s_u_gold.dataBuffer_uop_vpu_specVta, s_u_gold.dataBuffer_uop_vpu_specVsew, s_u_gold.dataBuffer_uop_vpu_specVlmul, s_u_gold.dataBuffer_uop_vpu_vm, s_u_gold.dataBuffer_uop_vpu_vstart, s_u_gold.dataBuffer_uop_vpu_frm, s_u_gold.dataBuffer_uop_vpu_fpu_isFpToVecInst, s_u_gold.dataBuffer_uop_vpu_fpu_isFP32Instr, s_u_gold.dataBuffer_uop_vpu_fpu_isFP64Instr, s_u_gold.dataBuffer_uop_vpu_fpu_isReduction, s_u_gold.dataBuffer_uop_vpu_fpu_isFoldTo1_2, s_u_gold.dataBuffer_uop_vpu_fpu_isFoldTo1_4, s_u_gold.dataBuffer_uop_vpu_fpu_isFoldTo1_8, s_u_gold.dataBuffer_uop_vpu_vxrm, s_u_gold.dataBuffer_uop_vpu_vuopIdx, s_u_gold.dataBuffer_uop_vpu_lastUop, s_u_gold.dataBuffer_uop_vpu_vmask, s_u_gold.dataBuffer_uop_vpu_vl, s_u_gold.dataBuffer_uop_vpu_nf, s_u_gold.dataBuffer_uop_vpu_veew, s_u_gold.dataBuffer_uop_vpu_isReverse, s_u_gold.dataBuffer_uop_vpu_isExt, s_u_gold.dataBuffer_uop_vpu_isNarrow, s_u_gold.dataBuffer_uop_vpu_isDstMask, s_u_gold.dataBuffer_uop_vpu_isOpMask, s_u_gold.dataBuffer_uop_vpu_isMove, s_u_gold.dataBuffer_uop_vpu_isDependOldVd, s_u_gold.dataBuffer_uop_vpu_isWritePartVd, s_u_gold.dataBuffer_uop_vpu_isVleff, s_u_gold.dataBuffer_uop_vlsInstr, s_u_gold.dataBuffer_uop_wfflags, s_u_gold.dataBuffer_uop_isMove, s_u_gold.dataBuffer_uop_isDropAmocasSta, s_u_gold.dataBuffer_uop_uopIdx, s_u_gold.dataBuffer_uop_isVset, s_u_gold.dataBuffer_uop_firstUop, s_u_gold.dataBuffer_uop_lastUop, s_u_gold.dataBuffer_uop_numUops, s_u_gold.dataBuffer_uop_numWB, s_u_gold.dataBuffer_uop_commitType, s_u_gold.dataBuffer_uop_srcState_0, s_u_gold.dataBuffer_uop_srcState_1, s_u_gold.dataBuffer_uop_srcState_2, s_u_gold.dataBuffer_uop_srcState_3, s_u_gold.dataBuffer_uop_srcState_4, s_u_gold.dataBuffer_uop_srcLoadDependency_0_0, s_u_gold.dataBuffer_uop_srcLoadDependency_0_1, s_u_gold.dataBuffer_uop_srcLoadDependency_0_2, s_u_gold.dataBuffer_uop_srcLoadDependency_1_0, s_u_gold.dataBuffer_uop_srcLoadDependency_1_1, s_u_gold.dataBuffer_uop_srcLoadDependency_1_2, s_u_gold.dataBuffer_uop_srcLoadDependency_2_0, s_u_gold.dataBuffer_uop_srcLoadDependency_2_1, s_u_gold.dataBuffer_uop_srcLoadDependency_2_2, s_u_gold.dataBuffer_uop_srcLoadDependency_3_0, s_u_gold.dataBuffer_uop_srcLoadDependency_3_1, s_u_gold.dataBuffer_uop_srcLoadDependency_3_2, s_u_gold.dataBuffer_uop_srcLoadDependency_4_0, s_u_gold.dataBuffer_uop_srcLoadDependency_4_1, s_u_gold.dataBuffer_uop_srcLoadDependency_4_2, s_u_gold.dataBuffer_uop_psrc_0, s_u_gold.dataBuffer_uop_psrc_1, s_u_gold.dataBuffer_uop_psrc_2, s_u_gold.dataBuffer_uop_psrc_3, s_u_gold.dataBuffer_uop_psrc_4, s_u_gold.dataBuffer_uop_pdest, s_u_gold.dataBuffer_uop_useRegCache_0, s_u_gold.dataBuffer_uop_useRegCache_1, s_u_gold.dataBuffer_uop_regCacheIdx_0, s_u_gold.dataBuffer_uop_regCacheIdx_1, s_u_gold.dataBuffer_uop_robIdx_flag, s_u_gold.dataBuffer_uop_robIdx_value, s_u_gold.dataBuffer_uop_instrSize, s_u_gold.dataBuffer_uop_dirtyFs, s_u_gold.dataBuffer_uop_dirtyVs, s_u_gold.dataBuffer_uop_traceBlockInPipe_itype, s_u_gold.dataBuffer_uop_traceBlockInPipe_iretire, s_u_gold.dataBuffer_uop_traceBlockInPipe_ilastsize, s_u_gold.dataBuffer_uop_eliminatedMove, s_u_gold.dataBuffer_uop_snapshot, s_u_gold.dataBuffer_uop_debugInfo_eliminatedMove, s_u_gold.dataBuffer_uop_debugInfo_renameTime, s_u_gold.dataBuffer_uop_debugInfo_dispatchTime, s_u_gold.dataBuffer_uop_debugInfo_enqRsTime, s_u_gold.dataBuffer_uop_debugInfo_selectTime, s_u_gold.dataBuffer_uop_debugInfo_issueTime, s_u_gold.dataBuffer_uop_debugInfo_writebackTime, s_u_gold.dataBuffer_uop_debugInfo_runahead_checkpoint_id, s_u_gold.dataBuffer_uop_debugInfo_tlbFirstReqTime, s_u_gold.dataBuffer_uop_debugInfo_tlbRespTime, s_u_gold.dataBuffer_uop_debug_seqNum_seqNum, s_u_gold.dataBuffer_uop_debug_seqNum_uopIdx, s_u_gold.dataBuffer_uop_storeSetHit, s_u_gold.dataBuffer_uop_waitForRobIdx_flag, s_u_gold.dataBuffer_uop_waitForRobIdx_value, s_u_gold.dataBuffer_uop_loadWaitBit, s_u_gold.dataBuffer_uop_loadWaitStrict, s_u_gold.dataBuffer_uop_ssid, s_u_gold.dataBuffer_uop_lqIdx_flag, s_u_gold.dataBuffer_uop_lqIdx_value, s_u_gold.dataBuffer_uop_sqIdx_flag, s_u_gold.dataBuffer_uop_sqIdx_value, s_u_gold.dataBuffer_uop_singleStep, s_u_gold.dataBuffer_uop_replayInst, s_u_gold.dataBuffer_uop_debug_fuType, s_u_gold.dataBuffer_uop_debug_sim_trig, s_u_gold.dataBuffer_uop_numLsElem, s_u_gold.dataBuffer_preIsSplit, s_u_gold.dataBuffer_mBIndex, s_u_gold.dataBuffer_alignedType, s_u_gold.dataBuffer_indexVlMaxInVd, s_u_gold.dataBuffer_usLowBitsAddr, s_u_gold.dataBuffer_usAligned128, s_u_gold.dataBuffer_usMask, s_u_gold.dataBuffer_isVecPartReplay, s_u_gold.dataBuffer_vecReplayFlowMask};
    force s_u_impl.u_core.state = s_u_gold.state;
    #0;
    release s_u_impl.u_core.dataBuffer;
    release s_u_impl.u_core.state;
  end
  logic s_reset;
  wire  s_g_io_in_ready, s_i_io_in_ready;
  logic s_s0_io_in_ready = '0, s_s1_io_in_ready = '0;
  logic s_io_in_valid;
  logic [15:0] s_io_in_bits_flowMask;
  logic [127:0] s_io_in_bits_data;
  logic [63:0] s_io_in_bits_baseAddr;
  logic [63:0] s_io_in_bits_uopAddr;
  logic [127:0] s_io_in_bits_stride;
  logic [4:0] s_io_in_bits_flowNum;
  logic [1:0] s_io_in_bits_eew;
  logic [2:0] s_io_in_bits_sew;
  logic [2:0] s_io_in_bits_emul;
  logic [2:0] s_io_in_bits_lmul;
  logic [2:0] s_io_in_bits_instType;
  logic [4:0] s_io_in_bits_indexedSplitOffset;
  logic [49:0] s_io_in_bits_uop_pc;
  logic s_io_in_bits_uop_ftqPtr_flag;
  logic [5:0] s_io_in_bits_uop_ftqPtr_value;
  logic [3:0] s_io_in_bits_uop_ftqOffset;
  logic [34:0] s_io_in_bits_uop_fuType;
  logic [8:0] s_io_in_bits_uop_fuOpType;
  logic s_io_in_bits_uop_vecWen;
  logic s_io_in_bits_uop_v0Wen;
  logic s_io_in_bits_uop_vlWen;
  logic s_io_in_bits_uop_vpu_vill;
  logic s_io_in_bits_uop_vpu_vma;
  logic s_io_in_bits_uop_vpu_vta;
  logic [1:0] s_io_in_bits_uop_vpu_vsew;
  logic [2:0] s_io_in_bits_uop_vpu_vlmul;
  logic s_io_in_bits_uop_vpu_specVill;
  logic s_io_in_bits_uop_vpu_specVma;
  logic s_io_in_bits_uop_vpu_specVta;
  logic [1:0] s_io_in_bits_uop_vpu_specVsew;
  logic [2:0] s_io_in_bits_uop_vpu_specVlmul;
  logic s_io_in_bits_uop_vpu_vm;
  logic [7:0] s_io_in_bits_uop_vpu_vstart;
  logic [2:0] s_io_in_bits_uop_vpu_frm;
  logic s_io_in_bits_uop_vpu_fpu_isFpToVecInst;
  logic s_io_in_bits_uop_vpu_fpu_isFP32Instr;
  logic s_io_in_bits_uop_vpu_fpu_isFP64Instr;
  logic s_io_in_bits_uop_vpu_fpu_isReduction;
  logic s_io_in_bits_uop_vpu_fpu_isFoldTo1_2;
  logic s_io_in_bits_uop_vpu_fpu_isFoldTo1_4;
  logic s_io_in_bits_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0] s_io_in_bits_uop_vpu_vxrm;
  logic [6:0] s_io_in_bits_uop_vpu_vuopIdx;
  logic s_io_in_bits_uop_vpu_lastUop;
  logic [127:0] s_io_in_bits_uop_vpu_vmask;
  logic [7:0] s_io_in_bits_uop_vpu_vl;
  logic [2:0] s_io_in_bits_uop_vpu_nf;
  logic [1:0] s_io_in_bits_uop_vpu_veew;
  logic s_io_in_bits_uop_vpu_isReverse;
  logic s_io_in_bits_uop_vpu_isExt;
  logic s_io_in_bits_uop_vpu_isNarrow;
  logic s_io_in_bits_uop_vpu_isDstMask;
  logic s_io_in_bits_uop_vpu_isOpMask;
  logic s_io_in_bits_uop_vpu_isMove;
  logic s_io_in_bits_uop_vpu_isDependOldVd;
  logic s_io_in_bits_uop_vpu_isWritePartVd;
  logic s_io_in_bits_uop_vpu_isVleff;
  logic [6:0] s_io_in_bits_uop_uopIdx;
  logic s_io_in_bits_uop_lastUop;
  logic [6:0] s_io_in_bits_uop_numUops;
  logic [7:0] s_io_in_bits_uop_pdest;
  logic s_io_in_bits_uop_robIdx_flag;
  logic [7:0] s_io_in_bits_uop_robIdx_value;
  logic s_io_in_bits_uop_debugInfo_eliminatedMove;
  logic [63:0] s_io_in_bits_uop_debugInfo_renameTime;
  logic [63:0] s_io_in_bits_uop_debugInfo_dispatchTime;
  logic [63:0] s_io_in_bits_uop_debugInfo_enqRsTime;
  logic [63:0] s_io_in_bits_uop_debugInfo_selectTime;
  logic [63:0] s_io_in_bits_uop_debugInfo_issueTime;
  logic [63:0] s_io_in_bits_uop_debugInfo_writebackTime;
  logic [63:0] s_io_in_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0] s_io_in_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0] s_io_in_bits_uop_debugInfo_tlbRespTime;
  logic [55:0] s_io_in_bits_uop_debug_seqNum_seqNum;
  logic [7:0] s_io_in_bits_uop_debug_seqNum_uopIdx;
  logic s_io_in_bits_uop_lqIdx_flag;
  logic [6:0] s_io_in_bits_uop_lqIdx_value;
  logic s_io_in_bits_uop_sqIdx_flag;
  logic [5:0] s_io_in_bits_uop_sqIdx_value;
  logic [4:0] s_io_in_bits_uop_numLsElem;
  logic s_io_in_bits_preIsSplit;
  logic [3:0] s_io_in_bits_mBIndex;
  logic [2:0] s_io_in_bits_alignedType;
  logic [7:0] s_io_in_bits_indexVlMaxInVd;
  logic [3:0] s_io_in_bits_usLowBitsAddr;
  logic s_io_in_bits_usAligned128;
  logic [31:0] s_io_in_bits_usMask;
  logic s_io_in_bits_isVecPartReplay;
  logic [15:0] s_io_in_bits_vecReplayFlowMask;
  logic s_io_flush;
  logic s_io_out_ready;
  wire  s_g_io_out_valid, s_i_io_out_valid;
  logic s_s0_io_out_valid = '0, s_s1_io_out_valid = '0;
  wire  [15:0] s_g_io_out_bits_flowMask, s_i_io_out_bits_flowMask;
  logic [15:0] s_s0_io_out_bits_flowMask = '0, s_s1_io_out_bits_flowMask = '0;
  wire  [127:0] s_g_io_out_bits_data, s_i_io_out_bits_data;
  logic [127:0] s_s0_io_out_bits_data = '0, s_s1_io_out_bits_data = '0;
  wire  [63:0] s_g_io_out_bits_baseAddr, s_i_io_out_bits_baseAddr;
  logic [63:0] s_s0_io_out_bits_baseAddr = '0, s_s1_io_out_bits_baseAddr = '0;
  wire  [63:0] s_g_io_out_bits_uopAddr, s_i_io_out_bits_uopAddr;
  logic [63:0] s_s0_io_out_bits_uopAddr = '0, s_s1_io_out_bits_uopAddr = '0;
  wire  [127:0] s_g_io_out_bits_stride, s_i_io_out_bits_stride;
  logic [127:0] s_s0_io_out_bits_stride = '0, s_s1_io_out_bits_stride = '0;
  wire  [4:0] s_g_io_out_bits_flowNum, s_i_io_out_bits_flowNum;
  logic [4:0] s_s0_io_out_bits_flowNum = '0, s_s1_io_out_bits_flowNum = '0;
  wire  [1:0] s_g_io_out_bits_eew, s_i_io_out_bits_eew;
  logic [1:0] s_s0_io_out_bits_eew = '0, s_s1_io_out_bits_eew = '0;
  wire  [2:0] s_g_io_out_bits_sew, s_i_io_out_bits_sew;
  logic [2:0] s_s0_io_out_bits_sew = '0, s_s1_io_out_bits_sew = '0;
  wire  [2:0] s_g_io_out_bits_emul, s_i_io_out_bits_emul;
  logic [2:0] s_s0_io_out_bits_emul = '0, s_s1_io_out_bits_emul = '0;
  wire  [2:0] s_g_io_out_bits_lmul, s_i_io_out_bits_lmul;
  logic [2:0] s_s0_io_out_bits_lmul = '0, s_s1_io_out_bits_lmul = '0;
  wire  [2:0] s_g_io_out_bits_instType, s_i_io_out_bits_instType;
  logic [2:0] s_s0_io_out_bits_instType = '0, s_s1_io_out_bits_instType = '0;
  wire  [4:0] s_g_io_out_bits_indexedSplitOffset, s_i_io_out_bits_indexedSplitOffset;
  logic [4:0] s_s0_io_out_bits_indexedSplitOffset = '0, s_s1_io_out_bits_indexedSplitOffset = '0;
  wire  [31:0] s_g_io_out_bits_uop_instr, s_i_io_out_bits_uop_instr;
  logic [31:0] s_s0_io_out_bits_uop_instr = '0, s_s1_io_out_bits_uop_instr = '0;
  wire  [49:0] s_g_io_out_bits_uop_pc, s_i_io_out_bits_uop_pc;
  logic [49:0] s_s0_io_out_bits_uop_pc = '0, s_s1_io_out_bits_uop_pc = '0;
  wire  [9:0] s_g_io_out_bits_uop_foldpc, s_i_io_out_bits_uop_foldpc;
  logic [9:0] s_s0_io_out_bits_uop_foldpc = '0, s_s1_io_out_bits_uop_foldpc = '0;
  wire  s_g_io_out_bits_uop_exceptionVec_5, s_i_io_out_bits_uop_exceptionVec_5;
  logic s_s0_io_out_bits_uop_exceptionVec_5 = '0, s_s1_io_out_bits_uop_exceptionVec_5 = '0;
  wire  s_g_io_out_bits_uop_exceptionVec_7, s_i_io_out_bits_uop_exceptionVec_7;
  logic s_s0_io_out_bits_uop_exceptionVec_7 = '0, s_s1_io_out_bits_uop_exceptionVec_7 = '0;
  wire  s_g_io_out_bits_uop_exceptionVec_13, s_i_io_out_bits_uop_exceptionVec_13;
  logic s_s0_io_out_bits_uop_exceptionVec_13 = '0, s_s1_io_out_bits_uop_exceptionVec_13 = '0;
  wire  s_g_io_out_bits_uop_exceptionVec_15, s_i_io_out_bits_uop_exceptionVec_15;
  logic s_s0_io_out_bits_uop_exceptionVec_15 = '0, s_s1_io_out_bits_uop_exceptionVec_15 = '0;
  wire  s_g_io_out_bits_uop_exceptionVec_19, s_i_io_out_bits_uop_exceptionVec_19;
  logic s_s0_io_out_bits_uop_exceptionVec_19 = '0, s_s1_io_out_bits_uop_exceptionVec_19 = '0;
  wire  s_g_io_out_bits_uop_exceptionVec_21, s_i_io_out_bits_uop_exceptionVec_21;
  logic s_s0_io_out_bits_uop_exceptionVec_21 = '0, s_s1_io_out_bits_uop_exceptionVec_21 = '0;
  wire  s_g_io_out_bits_uop_exceptionVec_23, s_i_io_out_bits_uop_exceptionVec_23;
  logic s_s0_io_out_bits_uop_exceptionVec_23 = '0, s_s1_io_out_bits_uop_exceptionVec_23 = '0;
  wire  s_g_io_out_bits_uop_isFetchMalAddr, s_i_io_out_bits_uop_isFetchMalAddr;
  logic s_s0_io_out_bits_uop_isFetchMalAddr = '0, s_s1_io_out_bits_uop_isFetchMalAddr = '0;
  wire  s_g_io_out_bits_uop_hasException, s_i_io_out_bits_uop_hasException;
  logic s_s0_io_out_bits_uop_hasException = '0, s_s1_io_out_bits_uop_hasException = '0;
  wire  [3:0] s_g_io_out_bits_uop_trigger, s_i_io_out_bits_uop_trigger;
  logic [3:0] s_s0_io_out_bits_uop_trigger = '0, s_s1_io_out_bits_uop_trigger = '0;
  wire  s_g_io_out_bits_uop_preDecodeInfo_valid, s_i_io_out_bits_uop_preDecodeInfo_valid;
  logic s_s0_io_out_bits_uop_preDecodeInfo_valid = '0, s_s1_io_out_bits_uop_preDecodeInfo_valid = '0;
  wire  s_g_io_out_bits_uop_preDecodeInfo_isRVC, s_i_io_out_bits_uop_preDecodeInfo_isRVC;
  logic s_s0_io_out_bits_uop_preDecodeInfo_isRVC = '0, s_s1_io_out_bits_uop_preDecodeInfo_isRVC = '0;
  wire  [1:0] s_g_io_out_bits_uop_preDecodeInfo_brType, s_i_io_out_bits_uop_preDecodeInfo_brType;
  logic [1:0] s_s0_io_out_bits_uop_preDecodeInfo_brType = '0, s_s1_io_out_bits_uop_preDecodeInfo_brType = '0;
  wire  s_g_io_out_bits_uop_preDecodeInfo_isCall, s_i_io_out_bits_uop_preDecodeInfo_isCall;
  logic s_s0_io_out_bits_uop_preDecodeInfo_isCall = '0, s_s1_io_out_bits_uop_preDecodeInfo_isCall = '0;
  wire  s_g_io_out_bits_uop_preDecodeInfo_isRet, s_i_io_out_bits_uop_preDecodeInfo_isRet;
  logic s_s0_io_out_bits_uop_preDecodeInfo_isRet = '0, s_s1_io_out_bits_uop_preDecodeInfo_isRet = '0;
  wire  s_g_io_out_bits_uop_pred_taken, s_i_io_out_bits_uop_pred_taken;
  logic s_s0_io_out_bits_uop_pred_taken = '0, s_s1_io_out_bits_uop_pred_taken = '0;
  wire  s_g_io_out_bits_uop_crossPageIPFFix, s_i_io_out_bits_uop_crossPageIPFFix;
  logic s_s0_io_out_bits_uop_crossPageIPFFix = '0, s_s1_io_out_bits_uop_crossPageIPFFix = '0;
  wire  s_g_io_out_bits_uop_ftqPtr_flag, s_i_io_out_bits_uop_ftqPtr_flag;
  logic s_s0_io_out_bits_uop_ftqPtr_flag = '0, s_s1_io_out_bits_uop_ftqPtr_flag = '0;
  wire  [5:0] s_g_io_out_bits_uop_ftqPtr_value, s_i_io_out_bits_uop_ftqPtr_value;
  logic [5:0] s_s0_io_out_bits_uop_ftqPtr_value = '0, s_s1_io_out_bits_uop_ftqPtr_value = '0;
  wire  [3:0] s_g_io_out_bits_uop_ftqOffset, s_i_io_out_bits_uop_ftqOffset;
  logic [3:0] s_s0_io_out_bits_uop_ftqOffset = '0, s_s1_io_out_bits_uop_ftqOffset = '0;
  wire  s_g_io_out_bits_uop_satpFlushFirstFetchFault, s_i_io_out_bits_uop_satpFlushFirstFetchFault;
  logic s_s0_io_out_bits_uop_satpFlushFirstFetchFault = '0, s_s1_io_out_bits_uop_satpFlushFirstFetchFault = '0;
  wire  [3:0] s_g_io_out_bits_uop_srcType_0, s_i_io_out_bits_uop_srcType_0;
  logic [3:0] s_s0_io_out_bits_uop_srcType_0 = '0, s_s1_io_out_bits_uop_srcType_0 = '0;
  wire  [3:0] s_g_io_out_bits_uop_srcType_1, s_i_io_out_bits_uop_srcType_1;
  logic [3:0] s_s0_io_out_bits_uop_srcType_1 = '0, s_s1_io_out_bits_uop_srcType_1 = '0;
  wire  [3:0] s_g_io_out_bits_uop_srcType_2, s_i_io_out_bits_uop_srcType_2;
  logic [3:0] s_s0_io_out_bits_uop_srcType_2 = '0, s_s1_io_out_bits_uop_srcType_2 = '0;
  wire  [3:0] s_g_io_out_bits_uop_srcType_3, s_i_io_out_bits_uop_srcType_3;
  logic [3:0] s_s0_io_out_bits_uop_srcType_3 = '0, s_s1_io_out_bits_uop_srcType_3 = '0;
  wire  [3:0] s_g_io_out_bits_uop_srcType_4, s_i_io_out_bits_uop_srcType_4;
  logic [3:0] s_s0_io_out_bits_uop_srcType_4 = '0, s_s1_io_out_bits_uop_srcType_4 = '0;
  wire  [5:0] s_g_io_out_bits_uop_ldest, s_i_io_out_bits_uop_ldest;
  logic [5:0] s_s0_io_out_bits_uop_ldest = '0, s_s1_io_out_bits_uop_ldest = '0;
  wire  [34:0] s_g_io_out_bits_uop_fuType, s_i_io_out_bits_uop_fuType;
  logic [34:0] s_s0_io_out_bits_uop_fuType = '0, s_s1_io_out_bits_uop_fuType = '0;
  wire  [8:0] s_g_io_out_bits_uop_fuOpType, s_i_io_out_bits_uop_fuOpType;
  logic [8:0] s_s0_io_out_bits_uop_fuOpType = '0, s_s1_io_out_bits_uop_fuOpType = '0;
  wire  s_g_io_out_bits_uop_rfWen, s_i_io_out_bits_uop_rfWen;
  logic s_s0_io_out_bits_uop_rfWen = '0, s_s1_io_out_bits_uop_rfWen = '0;
  wire  s_g_io_out_bits_uop_fpWen, s_i_io_out_bits_uop_fpWen;
  logic s_s0_io_out_bits_uop_fpWen = '0, s_s1_io_out_bits_uop_fpWen = '0;
  wire  s_g_io_out_bits_uop_vecWen, s_i_io_out_bits_uop_vecWen;
  logic s_s0_io_out_bits_uop_vecWen = '0, s_s1_io_out_bits_uop_vecWen = '0;
  wire  s_g_io_out_bits_uop_v0Wen, s_i_io_out_bits_uop_v0Wen;
  logic s_s0_io_out_bits_uop_v0Wen = '0, s_s1_io_out_bits_uop_v0Wen = '0;
  wire  s_g_io_out_bits_uop_vlWen, s_i_io_out_bits_uop_vlWen;
  logic s_s0_io_out_bits_uop_vlWen = '0, s_s1_io_out_bits_uop_vlWen = '0;
  wire  s_g_io_out_bits_uop_isXSTrap, s_i_io_out_bits_uop_isXSTrap;
  logic s_s0_io_out_bits_uop_isXSTrap = '0, s_s1_io_out_bits_uop_isXSTrap = '0;
  wire  s_g_io_out_bits_uop_waitForward, s_i_io_out_bits_uop_waitForward;
  logic s_s0_io_out_bits_uop_waitForward = '0, s_s1_io_out_bits_uop_waitForward = '0;
  wire  s_g_io_out_bits_uop_blockBackward, s_i_io_out_bits_uop_blockBackward;
  logic s_s0_io_out_bits_uop_blockBackward = '0, s_s1_io_out_bits_uop_blockBackward = '0;
  wire  s_g_io_out_bits_uop_canRobCompress, s_i_io_out_bits_uop_canRobCompress;
  logic s_s0_io_out_bits_uop_canRobCompress = '0, s_s1_io_out_bits_uop_canRobCompress = '0;
  wire  [3:0] s_g_io_out_bits_uop_selImm, s_i_io_out_bits_uop_selImm;
  logic [3:0] s_s0_io_out_bits_uop_selImm = '0, s_s1_io_out_bits_uop_selImm = '0;
  wire  [1:0] s_g_io_out_bits_uop_fpu_typeTagOut, s_i_io_out_bits_uop_fpu_typeTagOut;
  logic [1:0] s_s0_io_out_bits_uop_fpu_typeTagOut = '0, s_s1_io_out_bits_uop_fpu_typeTagOut = '0;
  wire  s_g_io_out_bits_uop_fpu_wflags, s_i_io_out_bits_uop_fpu_wflags;
  logic s_s0_io_out_bits_uop_fpu_wflags = '0, s_s1_io_out_bits_uop_fpu_wflags = '0;
  wire  [1:0] s_g_io_out_bits_uop_fpu_typ, s_i_io_out_bits_uop_fpu_typ;
  logic [1:0] s_s0_io_out_bits_uop_fpu_typ = '0, s_s1_io_out_bits_uop_fpu_typ = '0;
  wire  [1:0] s_g_io_out_bits_uop_fpu_fmt, s_i_io_out_bits_uop_fpu_fmt;
  logic [1:0] s_s0_io_out_bits_uop_fpu_fmt = '0, s_s1_io_out_bits_uop_fpu_fmt = '0;
  wire  [2:0] s_g_io_out_bits_uop_fpu_rm, s_i_io_out_bits_uop_fpu_rm;
  logic [2:0] s_s0_io_out_bits_uop_fpu_rm = '0, s_s1_io_out_bits_uop_fpu_rm = '0;
  wire  s_g_io_out_bits_uop_vpu_vill, s_i_io_out_bits_uop_vpu_vill;
  logic s_s0_io_out_bits_uop_vpu_vill = '0, s_s1_io_out_bits_uop_vpu_vill = '0;
  wire  s_g_io_out_bits_uop_vpu_vma, s_i_io_out_bits_uop_vpu_vma;
  logic s_s0_io_out_bits_uop_vpu_vma = '0, s_s1_io_out_bits_uop_vpu_vma = '0;
  wire  s_g_io_out_bits_uop_vpu_vta, s_i_io_out_bits_uop_vpu_vta;
  logic s_s0_io_out_bits_uop_vpu_vta = '0, s_s1_io_out_bits_uop_vpu_vta = '0;
  wire  [1:0] s_g_io_out_bits_uop_vpu_vsew, s_i_io_out_bits_uop_vpu_vsew;
  logic [1:0] s_s0_io_out_bits_uop_vpu_vsew = '0, s_s1_io_out_bits_uop_vpu_vsew = '0;
  wire  [2:0] s_g_io_out_bits_uop_vpu_vlmul, s_i_io_out_bits_uop_vpu_vlmul;
  logic [2:0] s_s0_io_out_bits_uop_vpu_vlmul = '0, s_s1_io_out_bits_uop_vpu_vlmul = '0;
  wire  s_g_io_out_bits_uop_vpu_specVill, s_i_io_out_bits_uop_vpu_specVill;
  logic s_s0_io_out_bits_uop_vpu_specVill = '0, s_s1_io_out_bits_uop_vpu_specVill = '0;
  wire  s_g_io_out_bits_uop_vpu_specVma, s_i_io_out_bits_uop_vpu_specVma;
  logic s_s0_io_out_bits_uop_vpu_specVma = '0, s_s1_io_out_bits_uop_vpu_specVma = '0;
  wire  s_g_io_out_bits_uop_vpu_specVta, s_i_io_out_bits_uop_vpu_specVta;
  logic s_s0_io_out_bits_uop_vpu_specVta = '0, s_s1_io_out_bits_uop_vpu_specVta = '0;
  wire  [1:0] s_g_io_out_bits_uop_vpu_specVsew, s_i_io_out_bits_uop_vpu_specVsew;
  logic [1:0] s_s0_io_out_bits_uop_vpu_specVsew = '0, s_s1_io_out_bits_uop_vpu_specVsew = '0;
  wire  [2:0] s_g_io_out_bits_uop_vpu_specVlmul, s_i_io_out_bits_uop_vpu_specVlmul;
  logic [2:0] s_s0_io_out_bits_uop_vpu_specVlmul = '0, s_s1_io_out_bits_uop_vpu_specVlmul = '0;
  wire  s_g_io_out_bits_uop_vpu_vm, s_i_io_out_bits_uop_vpu_vm;
  logic s_s0_io_out_bits_uop_vpu_vm = '0, s_s1_io_out_bits_uop_vpu_vm = '0;
  wire  [7:0] s_g_io_out_bits_uop_vpu_vstart, s_i_io_out_bits_uop_vpu_vstart;
  logic [7:0] s_s0_io_out_bits_uop_vpu_vstart = '0, s_s1_io_out_bits_uop_vpu_vstart = '0;
  wire  [2:0] s_g_io_out_bits_uop_vpu_frm, s_i_io_out_bits_uop_vpu_frm;
  logic [2:0] s_s0_io_out_bits_uop_vpu_frm = '0, s_s1_io_out_bits_uop_vpu_frm = '0;
  wire  s_g_io_out_bits_uop_vpu_fpu_isFpToVecInst, s_i_io_out_bits_uop_vpu_fpu_isFpToVecInst;
  logic s_s0_io_out_bits_uop_vpu_fpu_isFpToVecInst = '0, s_s1_io_out_bits_uop_vpu_fpu_isFpToVecInst = '0;
  wire  s_g_io_out_bits_uop_vpu_fpu_isFP32Instr, s_i_io_out_bits_uop_vpu_fpu_isFP32Instr;
  logic s_s0_io_out_bits_uop_vpu_fpu_isFP32Instr = '0, s_s1_io_out_bits_uop_vpu_fpu_isFP32Instr = '0;
  wire  s_g_io_out_bits_uop_vpu_fpu_isFP64Instr, s_i_io_out_bits_uop_vpu_fpu_isFP64Instr;
  logic s_s0_io_out_bits_uop_vpu_fpu_isFP64Instr = '0, s_s1_io_out_bits_uop_vpu_fpu_isFP64Instr = '0;
  wire  s_g_io_out_bits_uop_vpu_fpu_isReduction, s_i_io_out_bits_uop_vpu_fpu_isReduction;
  logic s_s0_io_out_bits_uop_vpu_fpu_isReduction = '0, s_s1_io_out_bits_uop_vpu_fpu_isReduction = '0;
  wire  s_g_io_out_bits_uop_vpu_fpu_isFoldTo1_2, s_i_io_out_bits_uop_vpu_fpu_isFoldTo1_2;
  logic s_s0_io_out_bits_uop_vpu_fpu_isFoldTo1_2 = '0, s_s1_io_out_bits_uop_vpu_fpu_isFoldTo1_2 = '0;
  wire  s_g_io_out_bits_uop_vpu_fpu_isFoldTo1_4, s_i_io_out_bits_uop_vpu_fpu_isFoldTo1_4;
  logic s_s0_io_out_bits_uop_vpu_fpu_isFoldTo1_4 = '0, s_s1_io_out_bits_uop_vpu_fpu_isFoldTo1_4 = '0;
  wire  s_g_io_out_bits_uop_vpu_fpu_isFoldTo1_8, s_i_io_out_bits_uop_vpu_fpu_isFoldTo1_8;
  logic s_s0_io_out_bits_uop_vpu_fpu_isFoldTo1_8 = '0, s_s1_io_out_bits_uop_vpu_fpu_isFoldTo1_8 = '0;
  wire  [1:0] s_g_io_out_bits_uop_vpu_vxrm, s_i_io_out_bits_uop_vpu_vxrm;
  logic [1:0] s_s0_io_out_bits_uop_vpu_vxrm = '0, s_s1_io_out_bits_uop_vpu_vxrm = '0;
  wire  [6:0] s_g_io_out_bits_uop_vpu_vuopIdx, s_i_io_out_bits_uop_vpu_vuopIdx;
  logic [6:0] s_s0_io_out_bits_uop_vpu_vuopIdx = '0, s_s1_io_out_bits_uop_vpu_vuopIdx = '0;
  wire  s_g_io_out_bits_uop_vpu_lastUop, s_i_io_out_bits_uop_vpu_lastUop;
  logic s_s0_io_out_bits_uop_vpu_lastUop = '0, s_s1_io_out_bits_uop_vpu_lastUop = '0;
  wire  [127:0] s_g_io_out_bits_uop_vpu_vmask, s_i_io_out_bits_uop_vpu_vmask;
  logic [127:0] s_s0_io_out_bits_uop_vpu_vmask = '0, s_s1_io_out_bits_uop_vpu_vmask = '0;
  wire  [7:0] s_g_io_out_bits_uop_vpu_vl, s_i_io_out_bits_uop_vpu_vl;
  logic [7:0] s_s0_io_out_bits_uop_vpu_vl = '0, s_s1_io_out_bits_uop_vpu_vl = '0;
  wire  [2:0] s_g_io_out_bits_uop_vpu_nf, s_i_io_out_bits_uop_vpu_nf;
  logic [2:0] s_s0_io_out_bits_uop_vpu_nf = '0, s_s1_io_out_bits_uop_vpu_nf = '0;
  wire  [1:0] s_g_io_out_bits_uop_vpu_veew, s_i_io_out_bits_uop_vpu_veew;
  logic [1:0] s_s0_io_out_bits_uop_vpu_veew = '0, s_s1_io_out_bits_uop_vpu_veew = '0;
  wire  s_g_io_out_bits_uop_vpu_isReverse, s_i_io_out_bits_uop_vpu_isReverse;
  logic s_s0_io_out_bits_uop_vpu_isReverse = '0, s_s1_io_out_bits_uop_vpu_isReverse = '0;
  wire  s_g_io_out_bits_uop_vpu_isExt, s_i_io_out_bits_uop_vpu_isExt;
  logic s_s0_io_out_bits_uop_vpu_isExt = '0, s_s1_io_out_bits_uop_vpu_isExt = '0;
  wire  s_g_io_out_bits_uop_vpu_isNarrow, s_i_io_out_bits_uop_vpu_isNarrow;
  logic s_s0_io_out_bits_uop_vpu_isNarrow = '0, s_s1_io_out_bits_uop_vpu_isNarrow = '0;
  wire  s_g_io_out_bits_uop_vpu_isDstMask, s_i_io_out_bits_uop_vpu_isDstMask;
  logic s_s0_io_out_bits_uop_vpu_isDstMask = '0, s_s1_io_out_bits_uop_vpu_isDstMask = '0;
  wire  s_g_io_out_bits_uop_vpu_isOpMask, s_i_io_out_bits_uop_vpu_isOpMask;
  logic s_s0_io_out_bits_uop_vpu_isOpMask = '0, s_s1_io_out_bits_uop_vpu_isOpMask = '0;
  wire  s_g_io_out_bits_uop_vpu_isMove, s_i_io_out_bits_uop_vpu_isMove;
  logic s_s0_io_out_bits_uop_vpu_isMove = '0, s_s1_io_out_bits_uop_vpu_isMove = '0;
  wire  s_g_io_out_bits_uop_vpu_isDependOldVd, s_i_io_out_bits_uop_vpu_isDependOldVd;
  logic s_s0_io_out_bits_uop_vpu_isDependOldVd = '0, s_s1_io_out_bits_uop_vpu_isDependOldVd = '0;
  wire  s_g_io_out_bits_uop_vpu_isWritePartVd, s_i_io_out_bits_uop_vpu_isWritePartVd;
  logic s_s0_io_out_bits_uop_vpu_isWritePartVd = '0, s_s1_io_out_bits_uop_vpu_isWritePartVd = '0;
  wire  s_g_io_out_bits_uop_vpu_isVleff, s_i_io_out_bits_uop_vpu_isVleff;
  logic s_s0_io_out_bits_uop_vpu_isVleff = '0, s_s1_io_out_bits_uop_vpu_isVleff = '0;
  wire  s_g_io_out_bits_uop_vlsInstr, s_i_io_out_bits_uop_vlsInstr;
  logic s_s0_io_out_bits_uop_vlsInstr = '0, s_s1_io_out_bits_uop_vlsInstr = '0;
  wire  s_g_io_out_bits_uop_wfflags, s_i_io_out_bits_uop_wfflags;
  logic s_s0_io_out_bits_uop_wfflags = '0, s_s1_io_out_bits_uop_wfflags = '0;
  wire  s_g_io_out_bits_uop_isMove, s_i_io_out_bits_uop_isMove;
  logic s_s0_io_out_bits_uop_isMove = '0, s_s1_io_out_bits_uop_isMove = '0;
  wire  s_g_io_out_bits_uop_isDropAmocasSta, s_i_io_out_bits_uop_isDropAmocasSta;
  logic s_s0_io_out_bits_uop_isDropAmocasSta = '0, s_s1_io_out_bits_uop_isDropAmocasSta = '0;
  wire  [6:0] s_g_io_out_bits_uop_uopIdx, s_i_io_out_bits_uop_uopIdx;
  logic [6:0] s_s0_io_out_bits_uop_uopIdx = '0, s_s1_io_out_bits_uop_uopIdx = '0;
  wire  s_g_io_out_bits_uop_isVset, s_i_io_out_bits_uop_isVset;
  logic s_s0_io_out_bits_uop_isVset = '0, s_s1_io_out_bits_uop_isVset = '0;
  wire  s_g_io_out_bits_uop_firstUop, s_i_io_out_bits_uop_firstUop;
  logic s_s0_io_out_bits_uop_firstUop = '0, s_s1_io_out_bits_uop_firstUop = '0;
  wire  s_g_io_out_bits_uop_lastUop, s_i_io_out_bits_uop_lastUop;
  logic s_s0_io_out_bits_uop_lastUop = '0, s_s1_io_out_bits_uop_lastUop = '0;
  wire  [6:0] s_g_io_out_bits_uop_numUops, s_i_io_out_bits_uop_numUops;
  logic [6:0] s_s0_io_out_bits_uop_numUops = '0, s_s1_io_out_bits_uop_numUops = '0;
  wire  [6:0] s_g_io_out_bits_uop_numWB, s_i_io_out_bits_uop_numWB;
  logic [6:0] s_s0_io_out_bits_uop_numWB = '0, s_s1_io_out_bits_uop_numWB = '0;
  wire  [2:0] s_g_io_out_bits_uop_commitType, s_i_io_out_bits_uop_commitType;
  logic [2:0] s_s0_io_out_bits_uop_commitType = '0, s_s1_io_out_bits_uop_commitType = '0;
  wire  s_g_io_out_bits_uop_srcState_0, s_i_io_out_bits_uop_srcState_0;
  logic s_s0_io_out_bits_uop_srcState_0 = '0, s_s1_io_out_bits_uop_srcState_0 = '0;
  wire  s_g_io_out_bits_uop_srcState_1, s_i_io_out_bits_uop_srcState_1;
  logic s_s0_io_out_bits_uop_srcState_1 = '0, s_s1_io_out_bits_uop_srcState_1 = '0;
  wire  s_g_io_out_bits_uop_srcState_2, s_i_io_out_bits_uop_srcState_2;
  logic s_s0_io_out_bits_uop_srcState_2 = '0, s_s1_io_out_bits_uop_srcState_2 = '0;
  wire  s_g_io_out_bits_uop_srcState_3, s_i_io_out_bits_uop_srcState_3;
  logic s_s0_io_out_bits_uop_srcState_3 = '0, s_s1_io_out_bits_uop_srcState_3 = '0;
  wire  s_g_io_out_bits_uop_srcState_4, s_i_io_out_bits_uop_srcState_4;
  logic s_s0_io_out_bits_uop_srcState_4 = '0, s_s1_io_out_bits_uop_srcState_4 = '0;
  wire  [1:0] s_g_io_out_bits_uop_srcLoadDependency_0_0, s_i_io_out_bits_uop_srcLoadDependency_0_0;
  logic [1:0] s_s0_io_out_bits_uop_srcLoadDependency_0_0 = '0, s_s1_io_out_bits_uop_srcLoadDependency_0_0 = '0;
  wire  [1:0] s_g_io_out_bits_uop_srcLoadDependency_0_1, s_i_io_out_bits_uop_srcLoadDependency_0_1;
  logic [1:0] s_s0_io_out_bits_uop_srcLoadDependency_0_1 = '0, s_s1_io_out_bits_uop_srcLoadDependency_0_1 = '0;
  wire  [1:0] s_g_io_out_bits_uop_srcLoadDependency_0_2, s_i_io_out_bits_uop_srcLoadDependency_0_2;
  logic [1:0] s_s0_io_out_bits_uop_srcLoadDependency_0_2 = '0, s_s1_io_out_bits_uop_srcLoadDependency_0_2 = '0;
  wire  [1:0] s_g_io_out_bits_uop_srcLoadDependency_1_0, s_i_io_out_bits_uop_srcLoadDependency_1_0;
  logic [1:0] s_s0_io_out_bits_uop_srcLoadDependency_1_0 = '0, s_s1_io_out_bits_uop_srcLoadDependency_1_0 = '0;
  wire  [1:0] s_g_io_out_bits_uop_srcLoadDependency_1_1, s_i_io_out_bits_uop_srcLoadDependency_1_1;
  logic [1:0] s_s0_io_out_bits_uop_srcLoadDependency_1_1 = '0, s_s1_io_out_bits_uop_srcLoadDependency_1_1 = '0;
  wire  [1:0] s_g_io_out_bits_uop_srcLoadDependency_1_2, s_i_io_out_bits_uop_srcLoadDependency_1_2;
  logic [1:0] s_s0_io_out_bits_uop_srcLoadDependency_1_2 = '0, s_s1_io_out_bits_uop_srcLoadDependency_1_2 = '0;
  wire  [1:0] s_g_io_out_bits_uop_srcLoadDependency_2_0, s_i_io_out_bits_uop_srcLoadDependency_2_0;
  logic [1:0] s_s0_io_out_bits_uop_srcLoadDependency_2_0 = '0, s_s1_io_out_bits_uop_srcLoadDependency_2_0 = '0;
  wire  [1:0] s_g_io_out_bits_uop_srcLoadDependency_2_1, s_i_io_out_bits_uop_srcLoadDependency_2_1;
  logic [1:0] s_s0_io_out_bits_uop_srcLoadDependency_2_1 = '0, s_s1_io_out_bits_uop_srcLoadDependency_2_1 = '0;
  wire  [1:0] s_g_io_out_bits_uop_srcLoadDependency_2_2, s_i_io_out_bits_uop_srcLoadDependency_2_2;
  logic [1:0] s_s0_io_out_bits_uop_srcLoadDependency_2_2 = '0, s_s1_io_out_bits_uop_srcLoadDependency_2_2 = '0;
  wire  [1:0] s_g_io_out_bits_uop_srcLoadDependency_3_0, s_i_io_out_bits_uop_srcLoadDependency_3_0;
  logic [1:0] s_s0_io_out_bits_uop_srcLoadDependency_3_0 = '0, s_s1_io_out_bits_uop_srcLoadDependency_3_0 = '0;
  wire  [1:0] s_g_io_out_bits_uop_srcLoadDependency_3_1, s_i_io_out_bits_uop_srcLoadDependency_3_1;
  logic [1:0] s_s0_io_out_bits_uop_srcLoadDependency_3_1 = '0, s_s1_io_out_bits_uop_srcLoadDependency_3_1 = '0;
  wire  [1:0] s_g_io_out_bits_uop_srcLoadDependency_3_2, s_i_io_out_bits_uop_srcLoadDependency_3_2;
  logic [1:0] s_s0_io_out_bits_uop_srcLoadDependency_3_2 = '0, s_s1_io_out_bits_uop_srcLoadDependency_3_2 = '0;
  wire  [1:0] s_g_io_out_bits_uop_srcLoadDependency_4_0, s_i_io_out_bits_uop_srcLoadDependency_4_0;
  logic [1:0] s_s0_io_out_bits_uop_srcLoadDependency_4_0 = '0, s_s1_io_out_bits_uop_srcLoadDependency_4_0 = '0;
  wire  [1:0] s_g_io_out_bits_uop_srcLoadDependency_4_1, s_i_io_out_bits_uop_srcLoadDependency_4_1;
  logic [1:0] s_s0_io_out_bits_uop_srcLoadDependency_4_1 = '0, s_s1_io_out_bits_uop_srcLoadDependency_4_1 = '0;
  wire  [1:0] s_g_io_out_bits_uop_srcLoadDependency_4_2, s_i_io_out_bits_uop_srcLoadDependency_4_2;
  logic [1:0] s_s0_io_out_bits_uop_srcLoadDependency_4_2 = '0, s_s1_io_out_bits_uop_srcLoadDependency_4_2 = '0;
  wire  [7:0] s_g_io_out_bits_uop_psrc_0, s_i_io_out_bits_uop_psrc_0;
  logic [7:0] s_s0_io_out_bits_uop_psrc_0 = '0, s_s1_io_out_bits_uop_psrc_0 = '0;
  wire  [7:0] s_g_io_out_bits_uop_psrc_1, s_i_io_out_bits_uop_psrc_1;
  logic [7:0] s_s0_io_out_bits_uop_psrc_1 = '0, s_s1_io_out_bits_uop_psrc_1 = '0;
  wire  [7:0] s_g_io_out_bits_uop_psrc_2, s_i_io_out_bits_uop_psrc_2;
  logic [7:0] s_s0_io_out_bits_uop_psrc_2 = '0, s_s1_io_out_bits_uop_psrc_2 = '0;
  wire  [7:0] s_g_io_out_bits_uop_psrc_3, s_i_io_out_bits_uop_psrc_3;
  logic [7:0] s_s0_io_out_bits_uop_psrc_3 = '0, s_s1_io_out_bits_uop_psrc_3 = '0;
  wire  [7:0] s_g_io_out_bits_uop_psrc_4, s_i_io_out_bits_uop_psrc_4;
  logic [7:0] s_s0_io_out_bits_uop_psrc_4 = '0, s_s1_io_out_bits_uop_psrc_4 = '0;
  wire  [7:0] s_g_io_out_bits_uop_pdest, s_i_io_out_bits_uop_pdest;
  logic [7:0] s_s0_io_out_bits_uop_pdest = '0, s_s1_io_out_bits_uop_pdest = '0;
  wire  s_g_io_out_bits_uop_useRegCache_0, s_i_io_out_bits_uop_useRegCache_0;
  logic s_s0_io_out_bits_uop_useRegCache_0 = '0, s_s1_io_out_bits_uop_useRegCache_0 = '0;
  wire  s_g_io_out_bits_uop_useRegCache_1, s_i_io_out_bits_uop_useRegCache_1;
  logic s_s0_io_out_bits_uop_useRegCache_1 = '0, s_s1_io_out_bits_uop_useRegCache_1 = '0;
  wire  [4:0] s_g_io_out_bits_uop_regCacheIdx_0, s_i_io_out_bits_uop_regCacheIdx_0;
  logic [4:0] s_s0_io_out_bits_uop_regCacheIdx_0 = '0, s_s1_io_out_bits_uop_regCacheIdx_0 = '0;
  wire  [4:0] s_g_io_out_bits_uop_regCacheIdx_1, s_i_io_out_bits_uop_regCacheIdx_1;
  logic [4:0] s_s0_io_out_bits_uop_regCacheIdx_1 = '0, s_s1_io_out_bits_uop_regCacheIdx_1 = '0;
  wire  s_g_io_out_bits_uop_robIdx_flag, s_i_io_out_bits_uop_robIdx_flag;
  logic s_s0_io_out_bits_uop_robIdx_flag = '0, s_s1_io_out_bits_uop_robIdx_flag = '0;
  wire  [7:0] s_g_io_out_bits_uop_robIdx_value, s_i_io_out_bits_uop_robIdx_value;
  logic [7:0] s_s0_io_out_bits_uop_robIdx_value = '0, s_s1_io_out_bits_uop_robIdx_value = '0;
  wire  [2:0] s_g_io_out_bits_uop_instrSize, s_i_io_out_bits_uop_instrSize;
  logic [2:0] s_s0_io_out_bits_uop_instrSize = '0, s_s1_io_out_bits_uop_instrSize = '0;
  wire  s_g_io_out_bits_uop_dirtyFs, s_i_io_out_bits_uop_dirtyFs;
  logic s_s0_io_out_bits_uop_dirtyFs = '0, s_s1_io_out_bits_uop_dirtyFs = '0;
  wire  s_g_io_out_bits_uop_dirtyVs, s_i_io_out_bits_uop_dirtyVs;
  logic s_s0_io_out_bits_uop_dirtyVs = '0, s_s1_io_out_bits_uop_dirtyVs = '0;
  wire  [3:0] s_g_io_out_bits_uop_traceBlockInPipe_itype, s_i_io_out_bits_uop_traceBlockInPipe_itype;
  logic [3:0] s_s0_io_out_bits_uop_traceBlockInPipe_itype = '0, s_s1_io_out_bits_uop_traceBlockInPipe_itype = '0;
  wire  [3:0] s_g_io_out_bits_uop_traceBlockInPipe_iretire, s_i_io_out_bits_uop_traceBlockInPipe_iretire;
  logic [3:0] s_s0_io_out_bits_uop_traceBlockInPipe_iretire = '0, s_s1_io_out_bits_uop_traceBlockInPipe_iretire = '0;
  wire  s_g_io_out_bits_uop_traceBlockInPipe_ilastsize, s_i_io_out_bits_uop_traceBlockInPipe_ilastsize;
  logic s_s0_io_out_bits_uop_traceBlockInPipe_ilastsize = '0, s_s1_io_out_bits_uop_traceBlockInPipe_ilastsize = '0;
  wire  s_g_io_out_bits_uop_eliminatedMove, s_i_io_out_bits_uop_eliminatedMove;
  logic s_s0_io_out_bits_uop_eliminatedMove = '0, s_s1_io_out_bits_uop_eliminatedMove = '0;
  wire  s_g_io_out_bits_uop_snapshot, s_i_io_out_bits_uop_snapshot;
  logic s_s0_io_out_bits_uop_snapshot = '0, s_s1_io_out_bits_uop_snapshot = '0;
  wire  s_g_io_out_bits_uop_debugInfo_eliminatedMove, s_i_io_out_bits_uop_debugInfo_eliminatedMove;
  logic s_s0_io_out_bits_uop_debugInfo_eliminatedMove = '0, s_s1_io_out_bits_uop_debugInfo_eliminatedMove = '0;
  wire  [63:0] s_g_io_out_bits_uop_debugInfo_renameTime, s_i_io_out_bits_uop_debugInfo_renameTime;
  logic [63:0] s_s0_io_out_bits_uop_debugInfo_renameTime = '0, s_s1_io_out_bits_uop_debugInfo_renameTime = '0;
  wire  [63:0] s_g_io_out_bits_uop_debugInfo_dispatchTime, s_i_io_out_bits_uop_debugInfo_dispatchTime;
  logic [63:0] s_s0_io_out_bits_uop_debugInfo_dispatchTime = '0, s_s1_io_out_bits_uop_debugInfo_dispatchTime = '0;
  wire  [63:0] s_g_io_out_bits_uop_debugInfo_enqRsTime, s_i_io_out_bits_uop_debugInfo_enqRsTime;
  logic [63:0] s_s0_io_out_bits_uop_debugInfo_enqRsTime = '0, s_s1_io_out_bits_uop_debugInfo_enqRsTime = '0;
  wire  [63:0] s_g_io_out_bits_uop_debugInfo_selectTime, s_i_io_out_bits_uop_debugInfo_selectTime;
  logic [63:0] s_s0_io_out_bits_uop_debugInfo_selectTime = '0, s_s1_io_out_bits_uop_debugInfo_selectTime = '0;
  wire  [63:0] s_g_io_out_bits_uop_debugInfo_issueTime, s_i_io_out_bits_uop_debugInfo_issueTime;
  logic [63:0] s_s0_io_out_bits_uop_debugInfo_issueTime = '0, s_s1_io_out_bits_uop_debugInfo_issueTime = '0;
  wire  [63:0] s_g_io_out_bits_uop_debugInfo_writebackTime, s_i_io_out_bits_uop_debugInfo_writebackTime;
  logic [63:0] s_s0_io_out_bits_uop_debugInfo_writebackTime = '0, s_s1_io_out_bits_uop_debugInfo_writebackTime = '0;
  wire  [63:0] s_g_io_out_bits_uop_debugInfo_runahead_checkpoint_id, s_i_io_out_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0] s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id = '0, s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id = '0;
  wire  [63:0] s_g_io_out_bits_uop_debugInfo_tlbFirstReqTime, s_i_io_out_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0] s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime = '0, s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime = '0;
  wire  [63:0] s_g_io_out_bits_uop_debugInfo_tlbRespTime, s_i_io_out_bits_uop_debugInfo_tlbRespTime;
  logic [63:0] s_s0_io_out_bits_uop_debugInfo_tlbRespTime = '0, s_s1_io_out_bits_uop_debugInfo_tlbRespTime = '0;
  wire  [55:0] s_g_io_out_bits_uop_debug_seqNum_seqNum, s_i_io_out_bits_uop_debug_seqNum_seqNum;
  logic [55:0] s_s0_io_out_bits_uop_debug_seqNum_seqNum = '0, s_s1_io_out_bits_uop_debug_seqNum_seqNum = '0;
  wire  [7:0] s_g_io_out_bits_uop_debug_seqNum_uopIdx, s_i_io_out_bits_uop_debug_seqNum_uopIdx;
  logic [7:0] s_s0_io_out_bits_uop_debug_seqNum_uopIdx = '0, s_s1_io_out_bits_uop_debug_seqNum_uopIdx = '0;
  wire  s_g_io_out_bits_uop_storeSetHit, s_i_io_out_bits_uop_storeSetHit;
  logic s_s0_io_out_bits_uop_storeSetHit = '0, s_s1_io_out_bits_uop_storeSetHit = '0;
  wire  s_g_io_out_bits_uop_waitForRobIdx_flag, s_i_io_out_bits_uop_waitForRobIdx_flag;
  logic s_s0_io_out_bits_uop_waitForRobIdx_flag = '0, s_s1_io_out_bits_uop_waitForRobIdx_flag = '0;
  wire  [7:0] s_g_io_out_bits_uop_waitForRobIdx_value, s_i_io_out_bits_uop_waitForRobIdx_value;
  logic [7:0] s_s0_io_out_bits_uop_waitForRobIdx_value = '0, s_s1_io_out_bits_uop_waitForRobIdx_value = '0;
  wire  s_g_io_out_bits_uop_loadWaitBit, s_i_io_out_bits_uop_loadWaitBit;
  logic s_s0_io_out_bits_uop_loadWaitBit = '0, s_s1_io_out_bits_uop_loadWaitBit = '0;
  wire  s_g_io_out_bits_uop_loadWaitStrict, s_i_io_out_bits_uop_loadWaitStrict;
  logic s_s0_io_out_bits_uop_loadWaitStrict = '0, s_s1_io_out_bits_uop_loadWaitStrict = '0;
  wire  [4:0] s_g_io_out_bits_uop_ssid, s_i_io_out_bits_uop_ssid;
  logic [4:0] s_s0_io_out_bits_uop_ssid = '0, s_s1_io_out_bits_uop_ssid = '0;
  wire  s_g_io_out_bits_uop_lqIdx_flag, s_i_io_out_bits_uop_lqIdx_flag;
  logic s_s0_io_out_bits_uop_lqIdx_flag = '0, s_s1_io_out_bits_uop_lqIdx_flag = '0;
  wire  [6:0] s_g_io_out_bits_uop_lqIdx_value, s_i_io_out_bits_uop_lqIdx_value;
  logic [6:0] s_s0_io_out_bits_uop_lqIdx_value = '0, s_s1_io_out_bits_uop_lqIdx_value = '0;
  wire  s_g_io_out_bits_uop_sqIdx_flag, s_i_io_out_bits_uop_sqIdx_flag;
  logic s_s0_io_out_bits_uop_sqIdx_flag = '0, s_s1_io_out_bits_uop_sqIdx_flag = '0;
  wire  [5:0] s_g_io_out_bits_uop_sqIdx_value, s_i_io_out_bits_uop_sqIdx_value;
  logic [5:0] s_s0_io_out_bits_uop_sqIdx_value = '0, s_s1_io_out_bits_uop_sqIdx_value = '0;
  wire  s_g_io_out_bits_uop_singleStep, s_i_io_out_bits_uop_singleStep;
  logic s_s0_io_out_bits_uop_singleStep = '0, s_s1_io_out_bits_uop_singleStep = '0;
  wire  s_g_io_out_bits_uop_replayInst, s_i_io_out_bits_uop_replayInst;
  logic s_s0_io_out_bits_uop_replayInst = '0, s_s1_io_out_bits_uop_replayInst = '0;
  wire  [34:0] s_g_io_out_bits_uop_debug_fuType, s_i_io_out_bits_uop_debug_fuType;
  logic [34:0] s_s0_io_out_bits_uop_debug_fuType = '0, s_s1_io_out_bits_uop_debug_fuType = '0;
  wire  s_g_io_out_bits_uop_debug_sim_trig, s_i_io_out_bits_uop_debug_sim_trig;
  logic s_s0_io_out_bits_uop_debug_sim_trig = '0, s_s1_io_out_bits_uop_debug_sim_trig = '0;
  wire  [4:0] s_g_io_out_bits_uop_numLsElem, s_i_io_out_bits_uop_numLsElem;
  logic [4:0] s_s0_io_out_bits_uop_numLsElem = '0, s_s1_io_out_bits_uop_numLsElem = '0;
  wire  s_g_io_out_bits_preIsSplit, s_i_io_out_bits_preIsSplit;
  logic s_s0_io_out_bits_preIsSplit = '0, s_s1_io_out_bits_preIsSplit = '0;
  wire  [3:0] s_g_io_out_bits_mBIndex, s_i_io_out_bits_mBIndex;
  logic [3:0] s_s0_io_out_bits_mBIndex = '0, s_s1_io_out_bits_mBIndex = '0;
  wire  [2:0] s_g_io_out_bits_alignedType, s_i_io_out_bits_alignedType;
  logic [2:0] s_s0_io_out_bits_alignedType = '0, s_s1_io_out_bits_alignedType = '0;
  wire  [7:0] s_g_io_out_bits_indexVlMaxInVd, s_i_io_out_bits_indexVlMaxInVd;
  logic [7:0] s_s0_io_out_bits_indexVlMaxInVd = '0, s_s1_io_out_bits_indexVlMaxInVd = '0;
  wire  [3:0] s_g_io_out_bits_usLowBitsAddr, s_i_io_out_bits_usLowBitsAddr;
  logic [3:0] s_s0_io_out_bits_usLowBitsAddr = '0, s_s1_io_out_bits_usLowBitsAddr = '0;
  wire  s_g_io_out_bits_usAligned128, s_i_io_out_bits_usAligned128;
  logic s_s0_io_out_bits_usAligned128 = '0, s_s1_io_out_bits_usAligned128 = '0;
  wire  [31:0] s_g_io_out_bits_usMask, s_i_io_out_bits_usMask;
  logic [31:0] s_s0_io_out_bits_usMask = '0, s_s1_io_out_bits_usMask = '0;
  wire  s_g_io_out_bits_isVecPartReplay, s_i_io_out_bits_isVecPartReplay;
  logic s_s0_io_out_bits_isVecPartReplay = '0, s_s1_io_out_bits_isVecPartReplay = '0;
  wire  [15:0] s_g_io_out_bits_vecReplayFlowMask, s_i_io_out_bits_vecReplayFlowMask;
  logic [15:0] s_s0_io_out_bits_vecReplayFlowMask = '0, s_s1_io_out_bits_vecReplayFlowMask = '0;
  int s_cov_capture = 0;
  int s_cov_skid = 0;
  int s_cov_drain = 0;
  int s_cov_flush_skid = 0;
  int s_cov_flush_cap = 0;
  int s_cov_pass = 0;
  logic [0:0] s_armed = '0;
  int s_armed_at = -1;
  skidBufferConnect s_u_gold (
    .clock(clk),
    .reset(s_reset),
    .io_in_ready(s_g_io_in_ready),
    .io_in_valid(s_io_in_valid),
    .io_in_bits_flowMask(s_io_in_bits_flowMask),
    .io_in_bits_data(s_io_in_bits_data),
    .io_in_bits_baseAddr(s_io_in_bits_baseAddr),
    .io_in_bits_uopAddr(s_io_in_bits_uopAddr),
    .io_in_bits_stride(s_io_in_bits_stride),
    .io_in_bits_flowNum(s_io_in_bits_flowNum),
    .io_in_bits_eew(s_io_in_bits_eew),
    .io_in_bits_sew(s_io_in_bits_sew),
    .io_in_bits_emul(s_io_in_bits_emul),
    .io_in_bits_lmul(s_io_in_bits_lmul),
    .io_in_bits_instType(s_io_in_bits_instType),
    .io_in_bits_indexedSplitOffset(s_io_in_bits_indexedSplitOffset),
    .io_in_bits_uop_pc(s_io_in_bits_uop_pc),
    .io_in_bits_uop_ftqPtr_flag(s_io_in_bits_uop_ftqPtr_flag),
    .io_in_bits_uop_ftqPtr_value(s_io_in_bits_uop_ftqPtr_value),
    .io_in_bits_uop_ftqOffset(s_io_in_bits_uop_ftqOffset),
    .io_in_bits_uop_fuType(s_io_in_bits_uop_fuType),
    .io_in_bits_uop_fuOpType(s_io_in_bits_uop_fuOpType),
    .io_in_bits_uop_vecWen(s_io_in_bits_uop_vecWen),
    .io_in_bits_uop_v0Wen(s_io_in_bits_uop_v0Wen),
    .io_in_bits_uop_vlWen(s_io_in_bits_uop_vlWen),
    .io_in_bits_uop_vpu_vill(s_io_in_bits_uop_vpu_vill),
    .io_in_bits_uop_vpu_vma(s_io_in_bits_uop_vpu_vma),
    .io_in_bits_uop_vpu_vta(s_io_in_bits_uop_vpu_vta),
    .io_in_bits_uop_vpu_vsew(s_io_in_bits_uop_vpu_vsew),
    .io_in_bits_uop_vpu_vlmul(s_io_in_bits_uop_vpu_vlmul),
    .io_in_bits_uop_vpu_specVill(s_io_in_bits_uop_vpu_specVill),
    .io_in_bits_uop_vpu_specVma(s_io_in_bits_uop_vpu_specVma),
    .io_in_bits_uop_vpu_specVta(s_io_in_bits_uop_vpu_specVta),
    .io_in_bits_uop_vpu_specVsew(s_io_in_bits_uop_vpu_specVsew),
    .io_in_bits_uop_vpu_specVlmul(s_io_in_bits_uop_vpu_specVlmul),
    .io_in_bits_uop_vpu_vm(s_io_in_bits_uop_vpu_vm),
    .io_in_bits_uop_vpu_vstart(s_io_in_bits_uop_vpu_vstart),
    .io_in_bits_uop_vpu_frm(s_io_in_bits_uop_vpu_frm),
    .io_in_bits_uop_vpu_fpu_isFpToVecInst(s_io_in_bits_uop_vpu_fpu_isFpToVecInst),
    .io_in_bits_uop_vpu_fpu_isFP32Instr(s_io_in_bits_uop_vpu_fpu_isFP32Instr),
    .io_in_bits_uop_vpu_fpu_isFP64Instr(s_io_in_bits_uop_vpu_fpu_isFP64Instr),
    .io_in_bits_uop_vpu_fpu_isReduction(s_io_in_bits_uop_vpu_fpu_isReduction),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_2(s_io_in_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_4(s_io_in_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_8(s_io_in_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_in_bits_uop_vpu_vxrm(s_io_in_bits_uop_vpu_vxrm),
    .io_in_bits_uop_vpu_vuopIdx(s_io_in_bits_uop_vpu_vuopIdx),
    .io_in_bits_uop_vpu_lastUop(s_io_in_bits_uop_vpu_lastUop),
    .io_in_bits_uop_vpu_vmask(s_io_in_bits_uop_vpu_vmask),
    .io_in_bits_uop_vpu_vl(s_io_in_bits_uop_vpu_vl),
    .io_in_bits_uop_vpu_nf(s_io_in_bits_uop_vpu_nf),
    .io_in_bits_uop_vpu_veew(s_io_in_bits_uop_vpu_veew),
    .io_in_bits_uop_vpu_isReverse(s_io_in_bits_uop_vpu_isReverse),
    .io_in_bits_uop_vpu_isExt(s_io_in_bits_uop_vpu_isExt),
    .io_in_bits_uop_vpu_isNarrow(s_io_in_bits_uop_vpu_isNarrow),
    .io_in_bits_uop_vpu_isDstMask(s_io_in_bits_uop_vpu_isDstMask),
    .io_in_bits_uop_vpu_isOpMask(s_io_in_bits_uop_vpu_isOpMask),
    .io_in_bits_uop_vpu_isMove(s_io_in_bits_uop_vpu_isMove),
    .io_in_bits_uop_vpu_isDependOldVd(s_io_in_bits_uop_vpu_isDependOldVd),
    .io_in_bits_uop_vpu_isWritePartVd(s_io_in_bits_uop_vpu_isWritePartVd),
    .io_in_bits_uop_vpu_isVleff(s_io_in_bits_uop_vpu_isVleff),
    .io_in_bits_uop_uopIdx(s_io_in_bits_uop_uopIdx),
    .io_in_bits_uop_lastUop(s_io_in_bits_uop_lastUop),
    .io_in_bits_uop_numUops(s_io_in_bits_uop_numUops),
    .io_in_bits_uop_pdest(s_io_in_bits_uop_pdest),
    .io_in_bits_uop_robIdx_flag(s_io_in_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value(s_io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_debugInfo_eliminatedMove(s_io_in_bits_uop_debugInfo_eliminatedMove),
    .io_in_bits_uop_debugInfo_renameTime(s_io_in_bits_uop_debugInfo_renameTime),
    .io_in_bits_uop_debugInfo_dispatchTime(s_io_in_bits_uop_debugInfo_dispatchTime),
    .io_in_bits_uop_debugInfo_enqRsTime(s_io_in_bits_uop_debugInfo_enqRsTime),
    .io_in_bits_uop_debugInfo_selectTime(s_io_in_bits_uop_debugInfo_selectTime),
    .io_in_bits_uop_debugInfo_issueTime(s_io_in_bits_uop_debugInfo_issueTime),
    .io_in_bits_uop_debugInfo_writebackTime(s_io_in_bits_uop_debugInfo_writebackTime),
    .io_in_bits_uop_debugInfo_runahead_checkpoint_id(s_io_in_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_in_bits_uop_debugInfo_tlbFirstReqTime(s_io_in_bits_uop_debugInfo_tlbFirstReqTime),
    .io_in_bits_uop_debugInfo_tlbRespTime(s_io_in_bits_uop_debugInfo_tlbRespTime),
    .io_in_bits_uop_debug_seqNum_seqNum(s_io_in_bits_uop_debug_seqNum_seqNum),
    .io_in_bits_uop_debug_seqNum_uopIdx(s_io_in_bits_uop_debug_seqNum_uopIdx),
    .io_in_bits_uop_lqIdx_flag(s_io_in_bits_uop_lqIdx_flag),
    .io_in_bits_uop_lqIdx_value(s_io_in_bits_uop_lqIdx_value),
    .io_in_bits_uop_sqIdx_flag(s_io_in_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value(s_io_in_bits_uop_sqIdx_value),
    .io_in_bits_uop_numLsElem(s_io_in_bits_uop_numLsElem),
    .io_in_bits_preIsSplit(s_io_in_bits_preIsSplit),
    .io_in_bits_mBIndex(s_io_in_bits_mBIndex),
    .io_in_bits_alignedType(s_io_in_bits_alignedType),
    .io_in_bits_indexVlMaxInVd(s_io_in_bits_indexVlMaxInVd),
    .io_in_bits_usLowBitsAddr(s_io_in_bits_usLowBitsAddr),
    .io_in_bits_usAligned128(s_io_in_bits_usAligned128),
    .io_in_bits_usMask(s_io_in_bits_usMask),
    .io_in_bits_isVecPartReplay(s_io_in_bits_isVecPartReplay),
    .io_in_bits_vecReplayFlowMask(s_io_in_bits_vecReplayFlowMask),
    .io_flush(s_io_flush),
    .io_out_ready(s_io_out_ready),
    .io_out_valid(s_g_io_out_valid),
    .io_out_bits_flowMask(s_g_io_out_bits_flowMask),
    .io_out_bits_data(s_g_io_out_bits_data),
    .io_out_bits_baseAddr(s_g_io_out_bits_baseAddr),
    .io_out_bits_uopAddr(s_g_io_out_bits_uopAddr),
    .io_out_bits_stride(s_g_io_out_bits_stride),
    .io_out_bits_flowNum(s_g_io_out_bits_flowNum),
    .io_out_bits_eew(s_g_io_out_bits_eew),
    .io_out_bits_sew(s_g_io_out_bits_sew),
    .io_out_bits_emul(s_g_io_out_bits_emul),
    .io_out_bits_lmul(s_g_io_out_bits_lmul),
    .io_out_bits_instType(s_g_io_out_bits_instType),
    .io_out_bits_indexedSplitOffset(s_g_io_out_bits_indexedSplitOffset),
    .io_out_bits_uop_instr(s_g_io_out_bits_uop_instr),
    .io_out_bits_uop_pc(s_g_io_out_bits_uop_pc),
    .io_out_bits_uop_foldpc(s_g_io_out_bits_uop_foldpc),
    .io_out_bits_uop_exceptionVec_5(s_g_io_out_bits_uop_exceptionVec_5),
    .io_out_bits_uop_exceptionVec_7(s_g_io_out_bits_uop_exceptionVec_7),
    .io_out_bits_uop_exceptionVec_13(s_g_io_out_bits_uop_exceptionVec_13),
    .io_out_bits_uop_exceptionVec_15(s_g_io_out_bits_uop_exceptionVec_15),
    .io_out_bits_uop_exceptionVec_19(s_g_io_out_bits_uop_exceptionVec_19),
    .io_out_bits_uop_exceptionVec_21(s_g_io_out_bits_uop_exceptionVec_21),
    .io_out_bits_uop_exceptionVec_23(s_g_io_out_bits_uop_exceptionVec_23),
    .io_out_bits_uop_isFetchMalAddr(s_g_io_out_bits_uop_isFetchMalAddr),
    .io_out_bits_uop_hasException(s_g_io_out_bits_uop_hasException),
    .io_out_bits_uop_trigger(s_g_io_out_bits_uop_trigger),
    .io_out_bits_uop_preDecodeInfo_valid(s_g_io_out_bits_uop_preDecodeInfo_valid),
    .io_out_bits_uop_preDecodeInfo_isRVC(s_g_io_out_bits_uop_preDecodeInfo_isRVC),
    .io_out_bits_uop_preDecodeInfo_brType(s_g_io_out_bits_uop_preDecodeInfo_brType),
    .io_out_bits_uop_preDecodeInfo_isCall(s_g_io_out_bits_uop_preDecodeInfo_isCall),
    .io_out_bits_uop_preDecodeInfo_isRet(s_g_io_out_bits_uop_preDecodeInfo_isRet),
    .io_out_bits_uop_pred_taken(s_g_io_out_bits_uop_pred_taken),
    .io_out_bits_uop_crossPageIPFFix(s_g_io_out_bits_uop_crossPageIPFFix),
    .io_out_bits_uop_ftqPtr_flag(s_g_io_out_bits_uop_ftqPtr_flag),
    .io_out_bits_uop_ftqPtr_value(s_g_io_out_bits_uop_ftqPtr_value),
    .io_out_bits_uop_ftqOffset(s_g_io_out_bits_uop_ftqOffset),
    .io_out_bits_uop_satpFlushFirstFetchFault(s_g_io_out_bits_uop_satpFlushFirstFetchFault),
    .io_out_bits_uop_srcType_0(s_g_io_out_bits_uop_srcType_0),
    .io_out_bits_uop_srcType_1(s_g_io_out_bits_uop_srcType_1),
    .io_out_bits_uop_srcType_2(s_g_io_out_bits_uop_srcType_2),
    .io_out_bits_uop_srcType_3(s_g_io_out_bits_uop_srcType_3),
    .io_out_bits_uop_srcType_4(s_g_io_out_bits_uop_srcType_4),
    .io_out_bits_uop_ldest(s_g_io_out_bits_uop_ldest),
    .io_out_bits_uop_fuType(s_g_io_out_bits_uop_fuType),
    .io_out_bits_uop_fuOpType(s_g_io_out_bits_uop_fuOpType),
    .io_out_bits_uop_rfWen(s_g_io_out_bits_uop_rfWen),
    .io_out_bits_uop_fpWen(s_g_io_out_bits_uop_fpWen),
    .io_out_bits_uop_vecWen(s_g_io_out_bits_uop_vecWen),
    .io_out_bits_uop_v0Wen(s_g_io_out_bits_uop_v0Wen),
    .io_out_bits_uop_vlWen(s_g_io_out_bits_uop_vlWen),
    .io_out_bits_uop_isXSTrap(s_g_io_out_bits_uop_isXSTrap),
    .io_out_bits_uop_waitForward(s_g_io_out_bits_uop_waitForward),
    .io_out_bits_uop_blockBackward(s_g_io_out_bits_uop_blockBackward),
    .io_out_bits_uop_canRobCompress(s_g_io_out_bits_uop_canRobCompress),
    .io_out_bits_uop_selImm(s_g_io_out_bits_uop_selImm),
    .io_out_bits_uop_fpu_typeTagOut(s_g_io_out_bits_uop_fpu_typeTagOut),
    .io_out_bits_uop_fpu_wflags(s_g_io_out_bits_uop_fpu_wflags),
    .io_out_bits_uop_fpu_typ(s_g_io_out_bits_uop_fpu_typ),
    .io_out_bits_uop_fpu_fmt(s_g_io_out_bits_uop_fpu_fmt),
    .io_out_bits_uop_fpu_rm(s_g_io_out_bits_uop_fpu_rm),
    .io_out_bits_uop_vpu_vill(s_g_io_out_bits_uop_vpu_vill),
    .io_out_bits_uop_vpu_vma(s_g_io_out_bits_uop_vpu_vma),
    .io_out_bits_uop_vpu_vta(s_g_io_out_bits_uop_vpu_vta),
    .io_out_bits_uop_vpu_vsew(s_g_io_out_bits_uop_vpu_vsew),
    .io_out_bits_uop_vpu_vlmul(s_g_io_out_bits_uop_vpu_vlmul),
    .io_out_bits_uop_vpu_specVill(s_g_io_out_bits_uop_vpu_specVill),
    .io_out_bits_uop_vpu_specVma(s_g_io_out_bits_uop_vpu_specVma),
    .io_out_bits_uop_vpu_specVta(s_g_io_out_bits_uop_vpu_specVta),
    .io_out_bits_uop_vpu_specVsew(s_g_io_out_bits_uop_vpu_specVsew),
    .io_out_bits_uop_vpu_specVlmul(s_g_io_out_bits_uop_vpu_specVlmul),
    .io_out_bits_uop_vpu_vm(s_g_io_out_bits_uop_vpu_vm),
    .io_out_bits_uop_vpu_vstart(s_g_io_out_bits_uop_vpu_vstart),
    .io_out_bits_uop_vpu_frm(s_g_io_out_bits_uop_vpu_frm),
    .io_out_bits_uop_vpu_fpu_isFpToVecInst(s_g_io_out_bits_uop_vpu_fpu_isFpToVecInst),
    .io_out_bits_uop_vpu_fpu_isFP32Instr(s_g_io_out_bits_uop_vpu_fpu_isFP32Instr),
    .io_out_bits_uop_vpu_fpu_isFP64Instr(s_g_io_out_bits_uop_vpu_fpu_isFP64Instr),
    .io_out_bits_uop_vpu_fpu_isReduction(s_g_io_out_bits_uop_vpu_fpu_isReduction),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_2(s_g_io_out_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_4(s_g_io_out_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_8(s_g_io_out_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_out_bits_uop_vpu_vxrm(s_g_io_out_bits_uop_vpu_vxrm),
    .io_out_bits_uop_vpu_vuopIdx(s_g_io_out_bits_uop_vpu_vuopIdx),
    .io_out_bits_uop_vpu_lastUop(s_g_io_out_bits_uop_vpu_lastUop),
    .io_out_bits_uop_vpu_vmask(s_g_io_out_bits_uop_vpu_vmask),
    .io_out_bits_uop_vpu_vl(s_g_io_out_bits_uop_vpu_vl),
    .io_out_bits_uop_vpu_nf(s_g_io_out_bits_uop_vpu_nf),
    .io_out_bits_uop_vpu_veew(s_g_io_out_bits_uop_vpu_veew),
    .io_out_bits_uop_vpu_isReverse(s_g_io_out_bits_uop_vpu_isReverse),
    .io_out_bits_uop_vpu_isExt(s_g_io_out_bits_uop_vpu_isExt),
    .io_out_bits_uop_vpu_isNarrow(s_g_io_out_bits_uop_vpu_isNarrow),
    .io_out_bits_uop_vpu_isDstMask(s_g_io_out_bits_uop_vpu_isDstMask),
    .io_out_bits_uop_vpu_isOpMask(s_g_io_out_bits_uop_vpu_isOpMask),
    .io_out_bits_uop_vpu_isMove(s_g_io_out_bits_uop_vpu_isMove),
    .io_out_bits_uop_vpu_isDependOldVd(s_g_io_out_bits_uop_vpu_isDependOldVd),
    .io_out_bits_uop_vpu_isWritePartVd(s_g_io_out_bits_uop_vpu_isWritePartVd),
    .io_out_bits_uop_vpu_isVleff(s_g_io_out_bits_uop_vpu_isVleff),
    .io_out_bits_uop_vlsInstr(s_g_io_out_bits_uop_vlsInstr),
    .io_out_bits_uop_wfflags(s_g_io_out_bits_uop_wfflags),
    .io_out_bits_uop_isMove(s_g_io_out_bits_uop_isMove),
    .io_out_bits_uop_isDropAmocasSta(s_g_io_out_bits_uop_isDropAmocasSta),
    .io_out_bits_uop_uopIdx(s_g_io_out_bits_uop_uopIdx),
    .io_out_bits_uop_isVset(s_g_io_out_bits_uop_isVset),
    .io_out_bits_uop_firstUop(s_g_io_out_bits_uop_firstUop),
    .io_out_bits_uop_lastUop(s_g_io_out_bits_uop_lastUop),
    .io_out_bits_uop_numUops(s_g_io_out_bits_uop_numUops),
    .io_out_bits_uop_numWB(s_g_io_out_bits_uop_numWB),
    .io_out_bits_uop_commitType(s_g_io_out_bits_uop_commitType),
    .io_out_bits_uop_srcState_0(s_g_io_out_bits_uop_srcState_0),
    .io_out_bits_uop_srcState_1(s_g_io_out_bits_uop_srcState_1),
    .io_out_bits_uop_srcState_2(s_g_io_out_bits_uop_srcState_2),
    .io_out_bits_uop_srcState_3(s_g_io_out_bits_uop_srcState_3),
    .io_out_bits_uop_srcState_4(s_g_io_out_bits_uop_srcState_4),
    .io_out_bits_uop_srcLoadDependency_0_0(s_g_io_out_bits_uop_srcLoadDependency_0_0),
    .io_out_bits_uop_srcLoadDependency_0_1(s_g_io_out_bits_uop_srcLoadDependency_0_1),
    .io_out_bits_uop_srcLoadDependency_0_2(s_g_io_out_bits_uop_srcLoadDependency_0_2),
    .io_out_bits_uop_srcLoadDependency_1_0(s_g_io_out_bits_uop_srcLoadDependency_1_0),
    .io_out_bits_uop_srcLoadDependency_1_1(s_g_io_out_bits_uop_srcLoadDependency_1_1),
    .io_out_bits_uop_srcLoadDependency_1_2(s_g_io_out_bits_uop_srcLoadDependency_1_2),
    .io_out_bits_uop_srcLoadDependency_2_0(s_g_io_out_bits_uop_srcLoadDependency_2_0),
    .io_out_bits_uop_srcLoadDependency_2_1(s_g_io_out_bits_uop_srcLoadDependency_2_1),
    .io_out_bits_uop_srcLoadDependency_2_2(s_g_io_out_bits_uop_srcLoadDependency_2_2),
    .io_out_bits_uop_srcLoadDependency_3_0(s_g_io_out_bits_uop_srcLoadDependency_3_0),
    .io_out_bits_uop_srcLoadDependency_3_1(s_g_io_out_bits_uop_srcLoadDependency_3_1),
    .io_out_bits_uop_srcLoadDependency_3_2(s_g_io_out_bits_uop_srcLoadDependency_3_2),
    .io_out_bits_uop_srcLoadDependency_4_0(s_g_io_out_bits_uop_srcLoadDependency_4_0),
    .io_out_bits_uop_srcLoadDependency_4_1(s_g_io_out_bits_uop_srcLoadDependency_4_1),
    .io_out_bits_uop_srcLoadDependency_4_2(s_g_io_out_bits_uop_srcLoadDependency_4_2),
    .io_out_bits_uop_psrc_0(s_g_io_out_bits_uop_psrc_0),
    .io_out_bits_uop_psrc_1(s_g_io_out_bits_uop_psrc_1),
    .io_out_bits_uop_psrc_2(s_g_io_out_bits_uop_psrc_2),
    .io_out_bits_uop_psrc_3(s_g_io_out_bits_uop_psrc_3),
    .io_out_bits_uop_psrc_4(s_g_io_out_bits_uop_psrc_4),
    .io_out_bits_uop_pdest(s_g_io_out_bits_uop_pdest),
    .io_out_bits_uop_useRegCache_0(s_g_io_out_bits_uop_useRegCache_0),
    .io_out_bits_uop_useRegCache_1(s_g_io_out_bits_uop_useRegCache_1),
    .io_out_bits_uop_regCacheIdx_0(s_g_io_out_bits_uop_regCacheIdx_0),
    .io_out_bits_uop_regCacheIdx_1(s_g_io_out_bits_uop_regCacheIdx_1),
    .io_out_bits_uop_robIdx_flag(s_g_io_out_bits_uop_robIdx_flag),
    .io_out_bits_uop_robIdx_value(s_g_io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_instrSize(s_g_io_out_bits_uop_instrSize),
    .io_out_bits_uop_dirtyFs(s_g_io_out_bits_uop_dirtyFs),
    .io_out_bits_uop_dirtyVs(s_g_io_out_bits_uop_dirtyVs),
    .io_out_bits_uop_traceBlockInPipe_itype(s_g_io_out_bits_uop_traceBlockInPipe_itype),
    .io_out_bits_uop_traceBlockInPipe_iretire(s_g_io_out_bits_uop_traceBlockInPipe_iretire),
    .io_out_bits_uop_traceBlockInPipe_ilastsize(s_g_io_out_bits_uop_traceBlockInPipe_ilastsize),
    .io_out_bits_uop_eliminatedMove(s_g_io_out_bits_uop_eliminatedMove),
    .io_out_bits_uop_snapshot(s_g_io_out_bits_uop_snapshot),
    .io_out_bits_uop_debugInfo_eliminatedMove(s_g_io_out_bits_uop_debugInfo_eliminatedMove),
    .io_out_bits_uop_debugInfo_renameTime(s_g_io_out_bits_uop_debugInfo_renameTime),
    .io_out_bits_uop_debugInfo_dispatchTime(s_g_io_out_bits_uop_debugInfo_dispatchTime),
    .io_out_bits_uop_debugInfo_enqRsTime(s_g_io_out_bits_uop_debugInfo_enqRsTime),
    .io_out_bits_uop_debugInfo_selectTime(s_g_io_out_bits_uop_debugInfo_selectTime),
    .io_out_bits_uop_debugInfo_issueTime(s_g_io_out_bits_uop_debugInfo_issueTime),
    .io_out_bits_uop_debugInfo_writebackTime(s_g_io_out_bits_uop_debugInfo_writebackTime),
    .io_out_bits_uop_debugInfo_runahead_checkpoint_id(s_g_io_out_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_out_bits_uop_debugInfo_tlbFirstReqTime(s_g_io_out_bits_uop_debugInfo_tlbFirstReqTime),
    .io_out_bits_uop_debugInfo_tlbRespTime(s_g_io_out_bits_uop_debugInfo_tlbRespTime),
    .io_out_bits_uop_debug_seqNum_seqNum(s_g_io_out_bits_uop_debug_seqNum_seqNum),
    .io_out_bits_uop_debug_seqNum_uopIdx(s_g_io_out_bits_uop_debug_seqNum_uopIdx),
    .io_out_bits_uop_storeSetHit(s_g_io_out_bits_uop_storeSetHit),
    .io_out_bits_uop_waitForRobIdx_flag(s_g_io_out_bits_uop_waitForRobIdx_flag),
    .io_out_bits_uop_waitForRobIdx_value(s_g_io_out_bits_uop_waitForRobIdx_value),
    .io_out_bits_uop_loadWaitBit(s_g_io_out_bits_uop_loadWaitBit),
    .io_out_bits_uop_loadWaitStrict(s_g_io_out_bits_uop_loadWaitStrict),
    .io_out_bits_uop_ssid(s_g_io_out_bits_uop_ssid),
    .io_out_bits_uop_lqIdx_flag(s_g_io_out_bits_uop_lqIdx_flag),
    .io_out_bits_uop_lqIdx_value(s_g_io_out_bits_uop_lqIdx_value),
    .io_out_bits_uop_sqIdx_flag(s_g_io_out_bits_uop_sqIdx_flag),
    .io_out_bits_uop_sqIdx_value(s_g_io_out_bits_uop_sqIdx_value),
    .io_out_bits_uop_singleStep(s_g_io_out_bits_uop_singleStep),
    .io_out_bits_uop_replayInst(s_g_io_out_bits_uop_replayInst),
    .io_out_bits_uop_debug_fuType(s_g_io_out_bits_uop_debug_fuType),
    .io_out_bits_uop_debug_sim_trig(s_g_io_out_bits_uop_debug_sim_trig),
    .io_out_bits_uop_numLsElem(s_g_io_out_bits_uop_numLsElem),
    .io_out_bits_preIsSplit(s_g_io_out_bits_preIsSplit),
    .io_out_bits_mBIndex(s_g_io_out_bits_mBIndex),
    .io_out_bits_alignedType(s_g_io_out_bits_alignedType),
    .io_out_bits_indexVlMaxInVd(s_g_io_out_bits_indexVlMaxInVd),
    .io_out_bits_usLowBitsAddr(s_g_io_out_bits_usLowBitsAddr),
    .io_out_bits_usAligned128(s_g_io_out_bits_usAligned128),
    .io_out_bits_usMask(s_g_io_out_bits_usMask),
    .io_out_bits_isVecPartReplay(s_g_io_out_bits_isVecPartReplay),
    .io_out_bits_vecReplayFlowMask(s_g_io_out_bits_vecReplayFlowMask)
  );
  skidBufferConnect_xs s_u_impl (
    .clock(clk),
    .reset(s_reset),
    .io_in_ready(s_i_io_in_ready),
    .io_in_valid(s_io_in_valid),
    .io_in_bits_flowMask(s_io_in_bits_flowMask),
    .io_in_bits_data(s_io_in_bits_data),
    .io_in_bits_baseAddr(s_io_in_bits_baseAddr),
    .io_in_bits_uopAddr(s_io_in_bits_uopAddr),
    .io_in_bits_stride(s_io_in_bits_stride),
    .io_in_bits_flowNum(s_io_in_bits_flowNum),
    .io_in_bits_eew(s_io_in_bits_eew),
    .io_in_bits_sew(s_io_in_bits_sew),
    .io_in_bits_emul(s_io_in_bits_emul),
    .io_in_bits_lmul(s_io_in_bits_lmul),
    .io_in_bits_instType(s_io_in_bits_instType),
    .io_in_bits_indexedSplitOffset(s_io_in_bits_indexedSplitOffset),
    .io_in_bits_uop_pc(s_io_in_bits_uop_pc),
    .io_in_bits_uop_ftqPtr_flag(s_io_in_bits_uop_ftqPtr_flag),
    .io_in_bits_uop_ftqPtr_value(s_io_in_bits_uop_ftqPtr_value),
    .io_in_bits_uop_ftqOffset(s_io_in_bits_uop_ftqOffset),
    .io_in_bits_uop_fuType(s_io_in_bits_uop_fuType),
    .io_in_bits_uop_fuOpType(s_io_in_bits_uop_fuOpType),
    .io_in_bits_uop_vecWen(s_io_in_bits_uop_vecWen),
    .io_in_bits_uop_v0Wen(s_io_in_bits_uop_v0Wen),
    .io_in_bits_uop_vlWen(s_io_in_bits_uop_vlWen),
    .io_in_bits_uop_vpu_vill(s_io_in_bits_uop_vpu_vill),
    .io_in_bits_uop_vpu_vma(s_io_in_bits_uop_vpu_vma),
    .io_in_bits_uop_vpu_vta(s_io_in_bits_uop_vpu_vta),
    .io_in_bits_uop_vpu_vsew(s_io_in_bits_uop_vpu_vsew),
    .io_in_bits_uop_vpu_vlmul(s_io_in_bits_uop_vpu_vlmul),
    .io_in_bits_uop_vpu_specVill(s_io_in_bits_uop_vpu_specVill),
    .io_in_bits_uop_vpu_specVma(s_io_in_bits_uop_vpu_specVma),
    .io_in_bits_uop_vpu_specVta(s_io_in_bits_uop_vpu_specVta),
    .io_in_bits_uop_vpu_specVsew(s_io_in_bits_uop_vpu_specVsew),
    .io_in_bits_uop_vpu_specVlmul(s_io_in_bits_uop_vpu_specVlmul),
    .io_in_bits_uop_vpu_vm(s_io_in_bits_uop_vpu_vm),
    .io_in_bits_uop_vpu_vstart(s_io_in_bits_uop_vpu_vstart),
    .io_in_bits_uop_vpu_frm(s_io_in_bits_uop_vpu_frm),
    .io_in_bits_uop_vpu_fpu_isFpToVecInst(s_io_in_bits_uop_vpu_fpu_isFpToVecInst),
    .io_in_bits_uop_vpu_fpu_isFP32Instr(s_io_in_bits_uop_vpu_fpu_isFP32Instr),
    .io_in_bits_uop_vpu_fpu_isFP64Instr(s_io_in_bits_uop_vpu_fpu_isFP64Instr),
    .io_in_bits_uop_vpu_fpu_isReduction(s_io_in_bits_uop_vpu_fpu_isReduction),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_2(s_io_in_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_4(s_io_in_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_in_bits_uop_vpu_fpu_isFoldTo1_8(s_io_in_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_in_bits_uop_vpu_vxrm(s_io_in_bits_uop_vpu_vxrm),
    .io_in_bits_uop_vpu_vuopIdx(s_io_in_bits_uop_vpu_vuopIdx),
    .io_in_bits_uop_vpu_lastUop(s_io_in_bits_uop_vpu_lastUop),
    .io_in_bits_uop_vpu_vmask(s_io_in_bits_uop_vpu_vmask),
    .io_in_bits_uop_vpu_vl(s_io_in_bits_uop_vpu_vl),
    .io_in_bits_uop_vpu_nf(s_io_in_bits_uop_vpu_nf),
    .io_in_bits_uop_vpu_veew(s_io_in_bits_uop_vpu_veew),
    .io_in_bits_uop_vpu_isReverse(s_io_in_bits_uop_vpu_isReverse),
    .io_in_bits_uop_vpu_isExt(s_io_in_bits_uop_vpu_isExt),
    .io_in_bits_uop_vpu_isNarrow(s_io_in_bits_uop_vpu_isNarrow),
    .io_in_bits_uop_vpu_isDstMask(s_io_in_bits_uop_vpu_isDstMask),
    .io_in_bits_uop_vpu_isOpMask(s_io_in_bits_uop_vpu_isOpMask),
    .io_in_bits_uop_vpu_isMove(s_io_in_bits_uop_vpu_isMove),
    .io_in_bits_uop_vpu_isDependOldVd(s_io_in_bits_uop_vpu_isDependOldVd),
    .io_in_bits_uop_vpu_isWritePartVd(s_io_in_bits_uop_vpu_isWritePartVd),
    .io_in_bits_uop_vpu_isVleff(s_io_in_bits_uop_vpu_isVleff),
    .io_in_bits_uop_uopIdx(s_io_in_bits_uop_uopIdx),
    .io_in_bits_uop_lastUop(s_io_in_bits_uop_lastUop),
    .io_in_bits_uop_numUops(s_io_in_bits_uop_numUops),
    .io_in_bits_uop_pdest(s_io_in_bits_uop_pdest),
    .io_in_bits_uop_robIdx_flag(s_io_in_bits_uop_robIdx_flag),
    .io_in_bits_uop_robIdx_value(s_io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_debugInfo_eliminatedMove(s_io_in_bits_uop_debugInfo_eliminatedMove),
    .io_in_bits_uop_debugInfo_renameTime(s_io_in_bits_uop_debugInfo_renameTime),
    .io_in_bits_uop_debugInfo_dispatchTime(s_io_in_bits_uop_debugInfo_dispatchTime),
    .io_in_bits_uop_debugInfo_enqRsTime(s_io_in_bits_uop_debugInfo_enqRsTime),
    .io_in_bits_uop_debugInfo_selectTime(s_io_in_bits_uop_debugInfo_selectTime),
    .io_in_bits_uop_debugInfo_issueTime(s_io_in_bits_uop_debugInfo_issueTime),
    .io_in_bits_uop_debugInfo_writebackTime(s_io_in_bits_uop_debugInfo_writebackTime),
    .io_in_bits_uop_debugInfo_runahead_checkpoint_id(s_io_in_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_in_bits_uop_debugInfo_tlbFirstReqTime(s_io_in_bits_uop_debugInfo_tlbFirstReqTime),
    .io_in_bits_uop_debugInfo_tlbRespTime(s_io_in_bits_uop_debugInfo_tlbRespTime),
    .io_in_bits_uop_debug_seqNum_seqNum(s_io_in_bits_uop_debug_seqNum_seqNum),
    .io_in_bits_uop_debug_seqNum_uopIdx(s_io_in_bits_uop_debug_seqNum_uopIdx),
    .io_in_bits_uop_lqIdx_flag(s_io_in_bits_uop_lqIdx_flag),
    .io_in_bits_uop_lqIdx_value(s_io_in_bits_uop_lqIdx_value),
    .io_in_bits_uop_sqIdx_flag(s_io_in_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value(s_io_in_bits_uop_sqIdx_value),
    .io_in_bits_uop_numLsElem(s_io_in_bits_uop_numLsElem),
    .io_in_bits_preIsSplit(s_io_in_bits_preIsSplit),
    .io_in_bits_mBIndex(s_io_in_bits_mBIndex),
    .io_in_bits_alignedType(s_io_in_bits_alignedType),
    .io_in_bits_indexVlMaxInVd(s_io_in_bits_indexVlMaxInVd),
    .io_in_bits_usLowBitsAddr(s_io_in_bits_usLowBitsAddr),
    .io_in_bits_usAligned128(s_io_in_bits_usAligned128),
    .io_in_bits_usMask(s_io_in_bits_usMask),
    .io_in_bits_isVecPartReplay(s_io_in_bits_isVecPartReplay),
    .io_in_bits_vecReplayFlowMask(s_io_in_bits_vecReplayFlowMask),
    .io_flush(s_io_flush),
    .io_out_ready(s_io_out_ready),
    .io_out_valid(s_i_io_out_valid),
    .io_out_bits_flowMask(s_i_io_out_bits_flowMask),
    .io_out_bits_data(s_i_io_out_bits_data),
    .io_out_bits_baseAddr(s_i_io_out_bits_baseAddr),
    .io_out_bits_uopAddr(s_i_io_out_bits_uopAddr),
    .io_out_bits_stride(s_i_io_out_bits_stride),
    .io_out_bits_flowNum(s_i_io_out_bits_flowNum),
    .io_out_bits_eew(s_i_io_out_bits_eew),
    .io_out_bits_sew(s_i_io_out_bits_sew),
    .io_out_bits_emul(s_i_io_out_bits_emul),
    .io_out_bits_lmul(s_i_io_out_bits_lmul),
    .io_out_bits_instType(s_i_io_out_bits_instType),
    .io_out_bits_indexedSplitOffset(s_i_io_out_bits_indexedSplitOffset),
    .io_out_bits_uop_instr(s_i_io_out_bits_uop_instr),
    .io_out_bits_uop_pc(s_i_io_out_bits_uop_pc),
    .io_out_bits_uop_foldpc(s_i_io_out_bits_uop_foldpc),
    .io_out_bits_uop_exceptionVec_5(s_i_io_out_bits_uop_exceptionVec_5),
    .io_out_bits_uop_exceptionVec_7(s_i_io_out_bits_uop_exceptionVec_7),
    .io_out_bits_uop_exceptionVec_13(s_i_io_out_bits_uop_exceptionVec_13),
    .io_out_bits_uop_exceptionVec_15(s_i_io_out_bits_uop_exceptionVec_15),
    .io_out_bits_uop_exceptionVec_19(s_i_io_out_bits_uop_exceptionVec_19),
    .io_out_bits_uop_exceptionVec_21(s_i_io_out_bits_uop_exceptionVec_21),
    .io_out_bits_uop_exceptionVec_23(s_i_io_out_bits_uop_exceptionVec_23),
    .io_out_bits_uop_isFetchMalAddr(s_i_io_out_bits_uop_isFetchMalAddr),
    .io_out_bits_uop_hasException(s_i_io_out_bits_uop_hasException),
    .io_out_bits_uop_trigger(s_i_io_out_bits_uop_trigger),
    .io_out_bits_uop_preDecodeInfo_valid(s_i_io_out_bits_uop_preDecodeInfo_valid),
    .io_out_bits_uop_preDecodeInfo_isRVC(s_i_io_out_bits_uop_preDecodeInfo_isRVC),
    .io_out_bits_uop_preDecodeInfo_brType(s_i_io_out_bits_uop_preDecodeInfo_brType),
    .io_out_bits_uop_preDecodeInfo_isCall(s_i_io_out_bits_uop_preDecodeInfo_isCall),
    .io_out_bits_uop_preDecodeInfo_isRet(s_i_io_out_bits_uop_preDecodeInfo_isRet),
    .io_out_bits_uop_pred_taken(s_i_io_out_bits_uop_pred_taken),
    .io_out_bits_uop_crossPageIPFFix(s_i_io_out_bits_uop_crossPageIPFFix),
    .io_out_bits_uop_ftqPtr_flag(s_i_io_out_bits_uop_ftqPtr_flag),
    .io_out_bits_uop_ftqPtr_value(s_i_io_out_bits_uop_ftqPtr_value),
    .io_out_bits_uop_ftqOffset(s_i_io_out_bits_uop_ftqOffset),
    .io_out_bits_uop_satpFlushFirstFetchFault(s_i_io_out_bits_uop_satpFlushFirstFetchFault),
    .io_out_bits_uop_srcType_0(s_i_io_out_bits_uop_srcType_0),
    .io_out_bits_uop_srcType_1(s_i_io_out_bits_uop_srcType_1),
    .io_out_bits_uop_srcType_2(s_i_io_out_bits_uop_srcType_2),
    .io_out_bits_uop_srcType_3(s_i_io_out_bits_uop_srcType_3),
    .io_out_bits_uop_srcType_4(s_i_io_out_bits_uop_srcType_4),
    .io_out_bits_uop_ldest(s_i_io_out_bits_uop_ldest),
    .io_out_bits_uop_fuType(s_i_io_out_bits_uop_fuType),
    .io_out_bits_uop_fuOpType(s_i_io_out_bits_uop_fuOpType),
    .io_out_bits_uop_rfWen(s_i_io_out_bits_uop_rfWen),
    .io_out_bits_uop_fpWen(s_i_io_out_bits_uop_fpWen),
    .io_out_bits_uop_vecWen(s_i_io_out_bits_uop_vecWen),
    .io_out_bits_uop_v0Wen(s_i_io_out_bits_uop_v0Wen),
    .io_out_bits_uop_vlWen(s_i_io_out_bits_uop_vlWen),
    .io_out_bits_uop_isXSTrap(s_i_io_out_bits_uop_isXSTrap),
    .io_out_bits_uop_waitForward(s_i_io_out_bits_uop_waitForward),
    .io_out_bits_uop_blockBackward(s_i_io_out_bits_uop_blockBackward),
    .io_out_bits_uop_canRobCompress(s_i_io_out_bits_uop_canRobCompress),
    .io_out_bits_uop_selImm(s_i_io_out_bits_uop_selImm),
    .io_out_bits_uop_fpu_typeTagOut(s_i_io_out_bits_uop_fpu_typeTagOut),
    .io_out_bits_uop_fpu_wflags(s_i_io_out_bits_uop_fpu_wflags),
    .io_out_bits_uop_fpu_typ(s_i_io_out_bits_uop_fpu_typ),
    .io_out_bits_uop_fpu_fmt(s_i_io_out_bits_uop_fpu_fmt),
    .io_out_bits_uop_fpu_rm(s_i_io_out_bits_uop_fpu_rm),
    .io_out_bits_uop_vpu_vill(s_i_io_out_bits_uop_vpu_vill),
    .io_out_bits_uop_vpu_vma(s_i_io_out_bits_uop_vpu_vma),
    .io_out_bits_uop_vpu_vta(s_i_io_out_bits_uop_vpu_vta),
    .io_out_bits_uop_vpu_vsew(s_i_io_out_bits_uop_vpu_vsew),
    .io_out_bits_uop_vpu_vlmul(s_i_io_out_bits_uop_vpu_vlmul),
    .io_out_bits_uop_vpu_specVill(s_i_io_out_bits_uop_vpu_specVill),
    .io_out_bits_uop_vpu_specVma(s_i_io_out_bits_uop_vpu_specVma),
    .io_out_bits_uop_vpu_specVta(s_i_io_out_bits_uop_vpu_specVta),
    .io_out_bits_uop_vpu_specVsew(s_i_io_out_bits_uop_vpu_specVsew),
    .io_out_bits_uop_vpu_specVlmul(s_i_io_out_bits_uop_vpu_specVlmul),
    .io_out_bits_uop_vpu_vm(s_i_io_out_bits_uop_vpu_vm),
    .io_out_bits_uop_vpu_vstart(s_i_io_out_bits_uop_vpu_vstart),
    .io_out_bits_uop_vpu_frm(s_i_io_out_bits_uop_vpu_frm),
    .io_out_bits_uop_vpu_fpu_isFpToVecInst(s_i_io_out_bits_uop_vpu_fpu_isFpToVecInst),
    .io_out_bits_uop_vpu_fpu_isFP32Instr(s_i_io_out_bits_uop_vpu_fpu_isFP32Instr),
    .io_out_bits_uop_vpu_fpu_isFP64Instr(s_i_io_out_bits_uop_vpu_fpu_isFP64Instr),
    .io_out_bits_uop_vpu_fpu_isReduction(s_i_io_out_bits_uop_vpu_fpu_isReduction),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_2(s_i_io_out_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_4(s_i_io_out_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_out_bits_uop_vpu_fpu_isFoldTo1_8(s_i_io_out_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_out_bits_uop_vpu_vxrm(s_i_io_out_bits_uop_vpu_vxrm),
    .io_out_bits_uop_vpu_vuopIdx(s_i_io_out_bits_uop_vpu_vuopIdx),
    .io_out_bits_uop_vpu_lastUop(s_i_io_out_bits_uop_vpu_lastUop),
    .io_out_bits_uop_vpu_vmask(s_i_io_out_bits_uop_vpu_vmask),
    .io_out_bits_uop_vpu_vl(s_i_io_out_bits_uop_vpu_vl),
    .io_out_bits_uop_vpu_nf(s_i_io_out_bits_uop_vpu_nf),
    .io_out_bits_uop_vpu_veew(s_i_io_out_bits_uop_vpu_veew),
    .io_out_bits_uop_vpu_isReverse(s_i_io_out_bits_uop_vpu_isReverse),
    .io_out_bits_uop_vpu_isExt(s_i_io_out_bits_uop_vpu_isExt),
    .io_out_bits_uop_vpu_isNarrow(s_i_io_out_bits_uop_vpu_isNarrow),
    .io_out_bits_uop_vpu_isDstMask(s_i_io_out_bits_uop_vpu_isDstMask),
    .io_out_bits_uop_vpu_isOpMask(s_i_io_out_bits_uop_vpu_isOpMask),
    .io_out_bits_uop_vpu_isMove(s_i_io_out_bits_uop_vpu_isMove),
    .io_out_bits_uop_vpu_isDependOldVd(s_i_io_out_bits_uop_vpu_isDependOldVd),
    .io_out_bits_uop_vpu_isWritePartVd(s_i_io_out_bits_uop_vpu_isWritePartVd),
    .io_out_bits_uop_vpu_isVleff(s_i_io_out_bits_uop_vpu_isVleff),
    .io_out_bits_uop_vlsInstr(s_i_io_out_bits_uop_vlsInstr),
    .io_out_bits_uop_wfflags(s_i_io_out_bits_uop_wfflags),
    .io_out_bits_uop_isMove(s_i_io_out_bits_uop_isMove),
    .io_out_bits_uop_isDropAmocasSta(s_i_io_out_bits_uop_isDropAmocasSta),
    .io_out_bits_uop_uopIdx(s_i_io_out_bits_uop_uopIdx),
    .io_out_bits_uop_isVset(s_i_io_out_bits_uop_isVset),
    .io_out_bits_uop_firstUop(s_i_io_out_bits_uop_firstUop),
    .io_out_bits_uop_lastUop(s_i_io_out_bits_uop_lastUop),
    .io_out_bits_uop_numUops(s_i_io_out_bits_uop_numUops),
    .io_out_bits_uop_numWB(s_i_io_out_bits_uop_numWB),
    .io_out_bits_uop_commitType(s_i_io_out_bits_uop_commitType),
    .io_out_bits_uop_srcState_0(s_i_io_out_bits_uop_srcState_0),
    .io_out_bits_uop_srcState_1(s_i_io_out_bits_uop_srcState_1),
    .io_out_bits_uop_srcState_2(s_i_io_out_bits_uop_srcState_2),
    .io_out_bits_uop_srcState_3(s_i_io_out_bits_uop_srcState_3),
    .io_out_bits_uop_srcState_4(s_i_io_out_bits_uop_srcState_4),
    .io_out_bits_uop_srcLoadDependency_0_0(s_i_io_out_bits_uop_srcLoadDependency_0_0),
    .io_out_bits_uop_srcLoadDependency_0_1(s_i_io_out_bits_uop_srcLoadDependency_0_1),
    .io_out_bits_uop_srcLoadDependency_0_2(s_i_io_out_bits_uop_srcLoadDependency_0_2),
    .io_out_bits_uop_srcLoadDependency_1_0(s_i_io_out_bits_uop_srcLoadDependency_1_0),
    .io_out_bits_uop_srcLoadDependency_1_1(s_i_io_out_bits_uop_srcLoadDependency_1_1),
    .io_out_bits_uop_srcLoadDependency_1_2(s_i_io_out_bits_uop_srcLoadDependency_1_2),
    .io_out_bits_uop_srcLoadDependency_2_0(s_i_io_out_bits_uop_srcLoadDependency_2_0),
    .io_out_bits_uop_srcLoadDependency_2_1(s_i_io_out_bits_uop_srcLoadDependency_2_1),
    .io_out_bits_uop_srcLoadDependency_2_2(s_i_io_out_bits_uop_srcLoadDependency_2_2),
    .io_out_bits_uop_srcLoadDependency_3_0(s_i_io_out_bits_uop_srcLoadDependency_3_0),
    .io_out_bits_uop_srcLoadDependency_3_1(s_i_io_out_bits_uop_srcLoadDependency_3_1),
    .io_out_bits_uop_srcLoadDependency_3_2(s_i_io_out_bits_uop_srcLoadDependency_3_2),
    .io_out_bits_uop_srcLoadDependency_4_0(s_i_io_out_bits_uop_srcLoadDependency_4_0),
    .io_out_bits_uop_srcLoadDependency_4_1(s_i_io_out_bits_uop_srcLoadDependency_4_1),
    .io_out_bits_uop_srcLoadDependency_4_2(s_i_io_out_bits_uop_srcLoadDependency_4_2),
    .io_out_bits_uop_psrc_0(s_i_io_out_bits_uop_psrc_0),
    .io_out_bits_uop_psrc_1(s_i_io_out_bits_uop_psrc_1),
    .io_out_bits_uop_psrc_2(s_i_io_out_bits_uop_psrc_2),
    .io_out_bits_uop_psrc_3(s_i_io_out_bits_uop_psrc_3),
    .io_out_bits_uop_psrc_4(s_i_io_out_bits_uop_psrc_4),
    .io_out_bits_uop_pdest(s_i_io_out_bits_uop_pdest),
    .io_out_bits_uop_useRegCache_0(s_i_io_out_bits_uop_useRegCache_0),
    .io_out_bits_uop_useRegCache_1(s_i_io_out_bits_uop_useRegCache_1),
    .io_out_bits_uop_regCacheIdx_0(s_i_io_out_bits_uop_regCacheIdx_0),
    .io_out_bits_uop_regCacheIdx_1(s_i_io_out_bits_uop_regCacheIdx_1),
    .io_out_bits_uop_robIdx_flag(s_i_io_out_bits_uop_robIdx_flag),
    .io_out_bits_uop_robIdx_value(s_i_io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_instrSize(s_i_io_out_bits_uop_instrSize),
    .io_out_bits_uop_dirtyFs(s_i_io_out_bits_uop_dirtyFs),
    .io_out_bits_uop_dirtyVs(s_i_io_out_bits_uop_dirtyVs),
    .io_out_bits_uop_traceBlockInPipe_itype(s_i_io_out_bits_uop_traceBlockInPipe_itype),
    .io_out_bits_uop_traceBlockInPipe_iretire(s_i_io_out_bits_uop_traceBlockInPipe_iretire),
    .io_out_bits_uop_traceBlockInPipe_ilastsize(s_i_io_out_bits_uop_traceBlockInPipe_ilastsize),
    .io_out_bits_uop_eliminatedMove(s_i_io_out_bits_uop_eliminatedMove),
    .io_out_bits_uop_snapshot(s_i_io_out_bits_uop_snapshot),
    .io_out_bits_uop_debugInfo_eliminatedMove(s_i_io_out_bits_uop_debugInfo_eliminatedMove),
    .io_out_bits_uop_debugInfo_renameTime(s_i_io_out_bits_uop_debugInfo_renameTime),
    .io_out_bits_uop_debugInfo_dispatchTime(s_i_io_out_bits_uop_debugInfo_dispatchTime),
    .io_out_bits_uop_debugInfo_enqRsTime(s_i_io_out_bits_uop_debugInfo_enqRsTime),
    .io_out_bits_uop_debugInfo_selectTime(s_i_io_out_bits_uop_debugInfo_selectTime),
    .io_out_bits_uop_debugInfo_issueTime(s_i_io_out_bits_uop_debugInfo_issueTime),
    .io_out_bits_uop_debugInfo_writebackTime(s_i_io_out_bits_uop_debugInfo_writebackTime),
    .io_out_bits_uop_debugInfo_runahead_checkpoint_id(s_i_io_out_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_out_bits_uop_debugInfo_tlbFirstReqTime(s_i_io_out_bits_uop_debugInfo_tlbFirstReqTime),
    .io_out_bits_uop_debugInfo_tlbRespTime(s_i_io_out_bits_uop_debugInfo_tlbRespTime),
    .io_out_bits_uop_debug_seqNum_seqNum(s_i_io_out_bits_uop_debug_seqNum_seqNum),
    .io_out_bits_uop_debug_seqNum_uopIdx(s_i_io_out_bits_uop_debug_seqNum_uopIdx),
    .io_out_bits_uop_storeSetHit(s_i_io_out_bits_uop_storeSetHit),
    .io_out_bits_uop_waitForRobIdx_flag(s_i_io_out_bits_uop_waitForRobIdx_flag),
    .io_out_bits_uop_waitForRobIdx_value(s_i_io_out_bits_uop_waitForRobIdx_value),
    .io_out_bits_uop_loadWaitBit(s_i_io_out_bits_uop_loadWaitBit),
    .io_out_bits_uop_loadWaitStrict(s_i_io_out_bits_uop_loadWaitStrict),
    .io_out_bits_uop_ssid(s_i_io_out_bits_uop_ssid),
    .io_out_bits_uop_lqIdx_flag(s_i_io_out_bits_uop_lqIdx_flag),
    .io_out_bits_uop_lqIdx_value(s_i_io_out_bits_uop_lqIdx_value),
    .io_out_bits_uop_sqIdx_flag(s_i_io_out_bits_uop_sqIdx_flag),
    .io_out_bits_uop_sqIdx_value(s_i_io_out_bits_uop_sqIdx_value),
    .io_out_bits_uop_singleStep(s_i_io_out_bits_uop_singleStep),
    .io_out_bits_uop_replayInst(s_i_io_out_bits_uop_replayInst),
    .io_out_bits_uop_debug_fuType(s_i_io_out_bits_uop_debug_fuType),
    .io_out_bits_uop_debug_sim_trig(s_i_io_out_bits_uop_debug_sim_trig),
    .io_out_bits_uop_numLsElem(s_i_io_out_bits_uop_numLsElem),
    .io_out_bits_preIsSplit(s_i_io_out_bits_preIsSplit),
    .io_out_bits_mBIndex(s_i_io_out_bits_mBIndex),
    .io_out_bits_alignedType(s_i_io_out_bits_alignedType),
    .io_out_bits_indexVlMaxInVd(s_i_io_out_bits_indexVlMaxInVd),
    .io_out_bits_usLowBitsAddr(s_i_io_out_bits_usLowBitsAddr),
    .io_out_bits_usAligned128(s_i_io_out_bits_usAligned128),
    .io_out_bits_usMask(s_i_io_out_bits_usMask),
    .io_out_bits_isVecPartReplay(s_i_io_out_bits_isVecPartReplay),
    .io_out_bits_vecReplayFlowMask(s_i_io_out_bits_vecReplayFlowMask)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) s_mode = $urandom_range(0, 15);
      s_io_in_valid = 1'($urandom);
      s_io_in_bits_flowMask = 16'($urandom);
      s_io_in_bits_data = 128'({$urandom, $urandom, $urandom, $urandom});
      s_io_in_bits_baseAddr = 64'({$urandom, $urandom});
      s_io_in_bits_uopAddr = 64'({$urandom, $urandom});
      s_io_in_bits_stride = 128'({$urandom, $urandom, $urandom, $urandom});
      s_io_in_bits_flowNum = 5'($urandom);
      s_io_in_bits_eew = 2'($urandom);
      s_io_in_bits_sew = 3'($urandom);
      s_io_in_bits_emul = 3'($urandom);
      s_io_in_bits_lmul = 3'($urandom);
      s_io_in_bits_instType = 3'($urandom);
      s_io_in_bits_indexedSplitOffset = 5'($urandom);
      s_io_in_bits_uop_pc = 50'({$urandom, $urandom});
      s_io_in_bits_uop_ftqPtr_flag = 1'($urandom);
      s_io_in_bits_uop_ftqPtr_value = 6'($urandom);
      s_io_in_bits_uop_ftqOffset = 4'($urandom);
      s_io_in_bits_uop_fuType = 35'({$urandom, $urandom});
      s_io_in_bits_uop_fuOpType = 9'($urandom);
      s_io_in_bits_uop_vecWen = 1'($urandom);
      s_io_in_bits_uop_v0Wen = 1'($urandom);
      s_io_in_bits_uop_vlWen = 1'($urandom);
      s_io_in_bits_uop_vpu_vill = 1'($urandom);
      s_io_in_bits_uop_vpu_vma = 1'($urandom);
      s_io_in_bits_uop_vpu_vta = 1'($urandom);
      s_io_in_bits_uop_vpu_vsew = 2'($urandom);
      s_io_in_bits_uop_vpu_vlmul = 3'($urandom);
      s_io_in_bits_uop_vpu_specVill = 1'($urandom);
      s_io_in_bits_uop_vpu_specVma = 1'($urandom);
      s_io_in_bits_uop_vpu_specVta = 1'($urandom);
      s_io_in_bits_uop_vpu_specVsew = 2'($urandom);
      s_io_in_bits_uop_vpu_specVlmul = 3'($urandom);
      s_io_in_bits_uop_vpu_vm = 1'($urandom);
      s_io_in_bits_uop_vpu_vstart = 8'($urandom);
      s_io_in_bits_uop_vpu_frm = 3'($urandom);
      s_io_in_bits_uop_vpu_fpu_isFpToVecInst = 1'($urandom);
      s_io_in_bits_uop_vpu_fpu_isFP32Instr = 1'($urandom);
      s_io_in_bits_uop_vpu_fpu_isFP64Instr = 1'($urandom);
      s_io_in_bits_uop_vpu_fpu_isReduction = 1'($urandom);
      s_io_in_bits_uop_vpu_fpu_isFoldTo1_2 = 1'($urandom);
      s_io_in_bits_uop_vpu_fpu_isFoldTo1_4 = 1'($urandom);
      s_io_in_bits_uop_vpu_fpu_isFoldTo1_8 = 1'($urandom);
      s_io_in_bits_uop_vpu_vxrm = 2'($urandom);
      s_io_in_bits_uop_vpu_vuopIdx = 7'($urandom);
      s_io_in_bits_uop_vpu_lastUop = 1'($urandom);
      s_io_in_bits_uop_vpu_vmask = 128'({$urandom, $urandom, $urandom, $urandom});
      s_io_in_bits_uop_vpu_vl = 8'($urandom);
      s_io_in_bits_uop_vpu_nf = 3'($urandom);
      s_io_in_bits_uop_vpu_veew = 2'($urandom);
      s_io_in_bits_uop_vpu_isReverse = 1'($urandom);
      s_io_in_bits_uop_vpu_isExt = 1'($urandom);
      s_io_in_bits_uop_vpu_isNarrow = 1'($urandom);
      s_io_in_bits_uop_vpu_isDstMask = 1'($urandom);
      s_io_in_bits_uop_vpu_isOpMask = 1'($urandom);
      s_io_in_bits_uop_vpu_isMove = 1'($urandom);
      s_io_in_bits_uop_vpu_isDependOldVd = 1'($urandom);
      s_io_in_bits_uop_vpu_isWritePartVd = 1'($urandom);
      s_io_in_bits_uop_vpu_isVleff = 1'($urandom);
      s_io_in_bits_uop_uopIdx = 7'($urandom);
      s_io_in_bits_uop_lastUop = 1'($urandom);
      s_io_in_bits_uop_numUops = 7'($urandom);
      s_io_in_bits_uop_pdest = 8'($urandom);
      s_io_in_bits_uop_robIdx_flag = 1'($urandom);
      s_io_in_bits_uop_robIdx_value = 8'($urandom);
      s_io_in_bits_uop_debugInfo_eliminatedMove = 1'($urandom);
      s_io_in_bits_uop_debugInfo_renameTime = 64'({$urandom, $urandom});
      s_io_in_bits_uop_debugInfo_dispatchTime = 64'({$urandom, $urandom});
      s_io_in_bits_uop_debugInfo_enqRsTime = 64'({$urandom, $urandom});
      s_io_in_bits_uop_debugInfo_selectTime = 64'({$urandom, $urandom});
      s_io_in_bits_uop_debugInfo_issueTime = 64'({$urandom, $urandom});
      s_io_in_bits_uop_debugInfo_writebackTime = 64'({$urandom, $urandom});
      s_io_in_bits_uop_debugInfo_runahead_checkpoint_id = 64'({$urandom, $urandom});
      s_io_in_bits_uop_debugInfo_tlbFirstReqTime = 64'({$urandom, $urandom});
      s_io_in_bits_uop_debugInfo_tlbRespTime = 64'({$urandom, $urandom});
      s_io_in_bits_uop_debug_seqNum_seqNum = 56'({$urandom, $urandom});
      s_io_in_bits_uop_debug_seqNum_uopIdx = 8'($urandom);
      s_io_in_bits_uop_lqIdx_flag = 1'($urandom);
      s_io_in_bits_uop_lqIdx_value = 7'($urandom);
      s_io_in_bits_uop_sqIdx_flag = 1'($urandom);
      s_io_in_bits_uop_sqIdx_value = 6'($urandom);
      s_io_in_bits_uop_numLsElem = 5'($urandom);
      s_io_in_bits_preIsSplit = 1'($urandom);
      s_io_in_bits_mBIndex = 4'($urandom);
      s_io_in_bits_alignedType = 3'($urandom);
      s_io_in_bits_indexVlMaxInVd = 8'($urandom);
      s_io_in_bits_usLowBitsAddr = 4'($urandom);
      s_io_in_bits_usAligned128 = 1'($urandom);
      s_io_in_bits_usMask = 32'($urandom);
      s_io_in_bits_isVecPartReplay = 1'($urandom);
      s_io_in_bits_vecReplayFlowMask = 16'($urandom);
      s_io_flush = 1'($urandom);
      s_io_out_ready = 1'($urandom);
      s_reset = (cyc < RESET_CYC) || ($urandom_range(0, 19999) == 0);
      begin : stim_s
        s_io_flush     = ($urandom_range(0, 31) == 0);
        s_io_out_ready = (s_mode >= 8) ? ($urandom_range(0, 3) != 0) : ($urandom_range(0, 3) == 0);
      end
      #4;
      s_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&s_armed)) begin
        checks++;
        if (s_g_io_in_ready !== s_i_io_in_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_in_ready g=%h i=%h", cyc, s_g_io_in_ready, s_i_io_in_ready);
        end
        s_s1_io_in_ready |= s_g_io_in_ready;
        s_s0_io_in_ready |= ~s_g_io_in_ready;
        checks++;
        if (s_g_io_out_valid !== s_i_io_out_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_valid g=%h i=%h", cyc, s_g_io_out_valid, s_i_io_out_valid);
        end
        s_s1_io_out_valid |= s_g_io_out_valid;
        s_s0_io_out_valid |= ~s_g_io_out_valid;
        checks++;
        if (s_g_io_out_bits_flowMask !== s_i_io_out_bits_flowMask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_flowMask g=%h i=%h", cyc, s_g_io_out_bits_flowMask, s_i_io_out_bits_flowMask);
        end
        s_s1_io_out_bits_flowMask |= s_g_io_out_bits_flowMask;
        s_s0_io_out_bits_flowMask |= ~s_g_io_out_bits_flowMask;
        checks++;
        if (s_g_io_out_bits_data !== s_i_io_out_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_data g=%h i=%h", cyc, s_g_io_out_bits_data, s_i_io_out_bits_data);
        end
        s_s1_io_out_bits_data |= s_g_io_out_bits_data;
        s_s0_io_out_bits_data |= ~s_g_io_out_bits_data;
        checks++;
        if (s_g_io_out_bits_baseAddr !== s_i_io_out_bits_baseAddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_baseAddr g=%h i=%h", cyc, s_g_io_out_bits_baseAddr, s_i_io_out_bits_baseAddr);
        end
        s_s1_io_out_bits_baseAddr |= s_g_io_out_bits_baseAddr;
        s_s0_io_out_bits_baseAddr |= ~s_g_io_out_bits_baseAddr;
        checks++;
        if (s_g_io_out_bits_uopAddr !== s_i_io_out_bits_uopAddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uopAddr g=%h i=%h", cyc, s_g_io_out_bits_uopAddr, s_i_io_out_bits_uopAddr);
        end
        s_s1_io_out_bits_uopAddr |= s_g_io_out_bits_uopAddr;
        s_s0_io_out_bits_uopAddr |= ~s_g_io_out_bits_uopAddr;
        checks++;
        if (s_g_io_out_bits_stride !== s_i_io_out_bits_stride) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_stride g=%h i=%h", cyc, s_g_io_out_bits_stride, s_i_io_out_bits_stride);
        end
        s_s1_io_out_bits_stride |= s_g_io_out_bits_stride;
        s_s0_io_out_bits_stride |= ~s_g_io_out_bits_stride;
        checks++;
        if (s_g_io_out_bits_flowNum !== s_i_io_out_bits_flowNum) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_flowNum g=%h i=%h", cyc, s_g_io_out_bits_flowNum, s_i_io_out_bits_flowNum);
        end
        s_s1_io_out_bits_flowNum |= s_g_io_out_bits_flowNum;
        s_s0_io_out_bits_flowNum |= ~s_g_io_out_bits_flowNum;
        checks++;
        if (s_g_io_out_bits_eew !== s_i_io_out_bits_eew) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_eew g=%h i=%h", cyc, s_g_io_out_bits_eew, s_i_io_out_bits_eew);
        end
        s_s1_io_out_bits_eew |= s_g_io_out_bits_eew;
        s_s0_io_out_bits_eew |= ~s_g_io_out_bits_eew;
        checks++;
        if (s_g_io_out_bits_sew !== s_i_io_out_bits_sew) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_sew g=%h i=%h", cyc, s_g_io_out_bits_sew, s_i_io_out_bits_sew);
        end
        s_s1_io_out_bits_sew |= s_g_io_out_bits_sew;
        s_s0_io_out_bits_sew |= ~s_g_io_out_bits_sew;
        checks++;
        if (s_g_io_out_bits_emul !== s_i_io_out_bits_emul) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_emul g=%h i=%h", cyc, s_g_io_out_bits_emul, s_i_io_out_bits_emul);
        end
        s_s1_io_out_bits_emul |= s_g_io_out_bits_emul;
        s_s0_io_out_bits_emul |= ~s_g_io_out_bits_emul;
        checks++;
        if (s_g_io_out_bits_lmul !== s_i_io_out_bits_lmul) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_lmul g=%h i=%h", cyc, s_g_io_out_bits_lmul, s_i_io_out_bits_lmul);
        end
        s_s1_io_out_bits_lmul |= s_g_io_out_bits_lmul;
        s_s0_io_out_bits_lmul |= ~s_g_io_out_bits_lmul;
        checks++;
        if (s_g_io_out_bits_instType !== s_i_io_out_bits_instType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_instType g=%h i=%h", cyc, s_g_io_out_bits_instType, s_i_io_out_bits_instType);
        end
        s_s1_io_out_bits_instType |= s_g_io_out_bits_instType;
        s_s0_io_out_bits_instType |= ~s_g_io_out_bits_instType;
        checks++;
        if (s_g_io_out_bits_indexedSplitOffset !== s_i_io_out_bits_indexedSplitOffset) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_indexedSplitOffset g=%h i=%h", cyc, s_g_io_out_bits_indexedSplitOffset, s_i_io_out_bits_indexedSplitOffset);
        end
        s_s1_io_out_bits_indexedSplitOffset |= s_g_io_out_bits_indexedSplitOffset;
        s_s0_io_out_bits_indexedSplitOffset |= ~s_g_io_out_bits_indexedSplitOffset;
        checks++;
        if (s_g_io_out_bits_uop_instr !== s_i_io_out_bits_uop_instr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_instr g=%h i=%h", cyc, s_g_io_out_bits_uop_instr, s_i_io_out_bits_uop_instr);
        end
        s_s1_io_out_bits_uop_instr |= s_g_io_out_bits_uop_instr;
        s_s0_io_out_bits_uop_instr |= ~s_g_io_out_bits_uop_instr;
        checks++;
        if (s_g_io_out_bits_uop_pc !== s_i_io_out_bits_uop_pc) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_pc g=%h i=%h", cyc, s_g_io_out_bits_uop_pc, s_i_io_out_bits_uop_pc);
        end
        s_s1_io_out_bits_uop_pc |= s_g_io_out_bits_uop_pc;
        s_s0_io_out_bits_uop_pc |= ~s_g_io_out_bits_uop_pc;
        checks++;
        if (s_g_io_out_bits_uop_foldpc !== s_i_io_out_bits_uop_foldpc) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_foldpc g=%h i=%h", cyc, s_g_io_out_bits_uop_foldpc, s_i_io_out_bits_uop_foldpc);
        end
        s_s1_io_out_bits_uop_foldpc |= s_g_io_out_bits_uop_foldpc;
        s_s0_io_out_bits_uop_foldpc |= ~s_g_io_out_bits_uop_foldpc;
        checks++;
        if (s_g_io_out_bits_uop_exceptionVec_5 !== s_i_io_out_bits_uop_exceptionVec_5) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_exceptionVec_5 g=%h i=%h", cyc, s_g_io_out_bits_uop_exceptionVec_5, s_i_io_out_bits_uop_exceptionVec_5);
        end
        s_s1_io_out_bits_uop_exceptionVec_5 |= s_g_io_out_bits_uop_exceptionVec_5;
        s_s0_io_out_bits_uop_exceptionVec_5 |= ~s_g_io_out_bits_uop_exceptionVec_5;
        checks++;
        if (s_g_io_out_bits_uop_exceptionVec_7 !== s_i_io_out_bits_uop_exceptionVec_7) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_exceptionVec_7 g=%h i=%h", cyc, s_g_io_out_bits_uop_exceptionVec_7, s_i_io_out_bits_uop_exceptionVec_7);
        end
        s_s1_io_out_bits_uop_exceptionVec_7 |= s_g_io_out_bits_uop_exceptionVec_7;
        s_s0_io_out_bits_uop_exceptionVec_7 |= ~s_g_io_out_bits_uop_exceptionVec_7;
        checks++;
        if (s_g_io_out_bits_uop_exceptionVec_13 !== s_i_io_out_bits_uop_exceptionVec_13) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_exceptionVec_13 g=%h i=%h", cyc, s_g_io_out_bits_uop_exceptionVec_13, s_i_io_out_bits_uop_exceptionVec_13);
        end
        s_s1_io_out_bits_uop_exceptionVec_13 |= s_g_io_out_bits_uop_exceptionVec_13;
        s_s0_io_out_bits_uop_exceptionVec_13 |= ~s_g_io_out_bits_uop_exceptionVec_13;
        checks++;
        if (s_g_io_out_bits_uop_exceptionVec_15 !== s_i_io_out_bits_uop_exceptionVec_15) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_exceptionVec_15 g=%h i=%h", cyc, s_g_io_out_bits_uop_exceptionVec_15, s_i_io_out_bits_uop_exceptionVec_15);
        end
        s_s1_io_out_bits_uop_exceptionVec_15 |= s_g_io_out_bits_uop_exceptionVec_15;
        s_s0_io_out_bits_uop_exceptionVec_15 |= ~s_g_io_out_bits_uop_exceptionVec_15;
        checks++;
        if (s_g_io_out_bits_uop_exceptionVec_19 !== s_i_io_out_bits_uop_exceptionVec_19) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_exceptionVec_19 g=%h i=%h", cyc, s_g_io_out_bits_uop_exceptionVec_19, s_i_io_out_bits_uop_exceptionVec_19);
        end
        s_s1_io_out_bits_uop_exceptionVec_19 |= s_g_io_out_bits_uop_exceptionVec_19;
        s_s0_io_out_bits_uop_exceptionVec_19 |= ~s_g_io_out_bits_uop_exceptionVec_19;
        checks++;
        if (s_g_io_out_bits_uop_exceptionVec_21 !== s_i_io_out_bits_uop_exceptionVec_21) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_exceptionVec_21 g=%h i=%h", cyc, s_g_io_out_bits_uop_exceptionVec_21, s_i_io_out_bits_uop_exceptionVec_21);
        end
        s_s1_io_out_bits_uop_exceptionVec_21 |= s_g_io_out_bits_uop_exceptionVec_21;
        s_s0_io_out_bits_uop_exceptionVec_21 |= ~s_g_io_out_bits_uop_exceptionVec_21;
        checks++;
        if (s_g_io_out_bits_uop_exceptionVec_23 !== s_i_io_out_bits_uop_exceptionVec_23) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_exceptionVec_23 g=%h i=%h", cyc, s_g_io_out_bits_uop_exceptionVec_23, s_i_io_out_bits_uop_exceptionVec_23);
        end
        s_s1_io_out_bits_uop_exceptionVec_23 |= s_g_io_out_bits_uop_exceptionVec_23;
        s_s0_io_out_bits_uop_exceptionVec_23 |= ~s_g_io_out_bits_uop_exceptionVec_23;
        checks++;
        if (s_g_io_out_bits_uop_isFetchMalAddr !== s_i_io_out_bits_uop_isFetchMalAddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_isFetchMalAddr g=%h i=%h", cyc, s_g_io_out_bits_uop_isFetchMalAddr, s_i_io_out_bits_uop_isFetchMalAddr);
        end
        s_s1_io_out_bits_uop_isFetchMalAddr |= s_g_io_out_bits_uop_isFetchMalAddr;
        s_s0_io_out_bits_uop_isFetchMalAddr |= ~s_g_io_out_bits_uop_isFetchMalAddr;
        checks++;
        if (s_g_io_out_bits_uop_hasException !== s_i_io_out_bits_uop_hasException) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_hasException g=%h i=%h", cyc, s_g_io_out_bits_uop_hasException, s_i_io_out_bits_uop_hasException);
        end
        s_s1_io_out_bits_uop_hasException |= s_g_io_out_bits_uop_hasException;
        s_s0_io_out_bits_uop_hasException |= ~s_g_io_out_bits_uop_hasException;
        checks++;
        if (s_g_io_out_bits_uop_trigger !== s_i_io_out_bits_uop_trigger) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_trigger g=%h i=%h", cyc, s_g_io_out_bits_uop_trigger, s_i_io_out_bits_uop_trigger);
        end
        s_s1_io_out_bits_uop_trigger |= s_g_io_out_bits_uop_trigger;
        s_s0_io_out_bits_uop_trigger |= ~s_g_io_out_bits_uop_trigger;
        checks++;
        if (s_g_io_out_bits_uop_preDecodeInfo_valid !== s_i_io_out_bits_uop_preDecodeInfo_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_preDecodeInfo_valid g=%h i=%h", cyc, s_g_io_out_bits_uop_preDecodeInfo_valid, s_i_io_out_bits_uop_preDecodeInfo_valid);
        end
        s_s1_io_out_bits_uop_preDecodeInfo_valid |= s_g_io_out_bits_uop_preDecodeInfo_valid;
        s_s0_io_out_bits_uop_preDecodeInfo_valid |= ~s_g_io_out_bits_uop_preDecodeInfo_valid;
        checks++;
        if (s_g_io_out_bits_uop_preDecodeInfo_isRVC !== s_i_io_out_bits_uop_preDecodeInfo_isRVC) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_preDecodeInfo_isRVC g=%h i=%h", cyc, s_g_io_out_bits_uop_preDecodeInfo_isRVC, s_i_io_out_bits_uop_preDecodeInfo_isRVC);
        end
        s_s1_io_out_bits_uop_preDecodeInfo_isRVC |= s_g_io_out_bits_uop_preDecodeInfo_isRVC;
        s_s0_io_out_bits_uop_preDecodeInfo_isRVC |= ~s_g_io_out_bits_uop_preDecodeInfo_isRVC;
        checks++;
        if (s_g_io_out_bits_uop_preDecodeInfo_brType !== s_i_io_out_bits_uop_preDecodeInfo_brType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_preDecodeInfo_brType g=%h i=%h", cyc, s_g_io_out_bits_uop_preDecodeInfo_brType, s_i_io_out_bits_uop_preDecodeInfo_brType);
        end
        s_s1_io_out_bits_uop_preDecodeInfo_brType |= s_g_io_out_bits_uop_preDecodeInfo_brType;
        s_s0_io_out_bits_uop_preDecodeInfo_brType |= ~s_g_io_out_bits_uop_preDecodeInfo_brType;
        checks++;
        if (s_g_io_out_bits_uop_preDecodeInfo_isCall !== s_i_io_out_bits_uop_preDecodeInfo_isCall) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_preDecodeInfo_isCall g=%h i=%h", cyc, s_g_io_out_bits_uop_preDecodeInfo_isCall, s_i_io_out_bits_uop_preDecodeInfo_isCall);
        end
        s_s1_io_out_bits_uop_preDecodeInfo_isCall |= s_g_io_out_bits_uop_preDecodeInfo_isCall;
        s_s0_io_out_bits_uop_preDecodeInfo_isCall |= ~s_g_io_out_bits_uop_preDecodeInfo_isCall;
        checks++;
        if (s_g_io_out_bits_uop_preDecodeInfo_isRet !== s_i_io_out_bits_uop_preDecodeInfo_isRet) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_preDecodeInfo_isRet g=%h i=%h", cyc, s_g_io_out_bits_uop_preDecodeInfo_isRet, s_i_io_out_bits_uop_preDecodeInfo_isRet);
        end
        s_s1_io_out_bits_uop_preDecodeInfo_isRet |= s_g_io_out_bits_uop_preDecodeInfo_isRet;
        s_s0_io_out_bits_uop_preDecodeInfo_isRet |= ~s_g_io_out_bits_uop_preDecodeInfo_isRet;
        checks++;
        if (s_g_io_out_bits_uop_pred_taken !== s_i_io_out_bits_uop_pred_taken) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_pred_taken g=%h i=%h", cyc, s_g_io_out_bits_uop_pred_taken, s_i_io_out_bits_uop_pred_taken);
        end
        s_s1_io_out_bits_uop_pred_taken |= s_g_io_out_bits_uop_pred_taken;
        s_s0_io_out_bits_uop_pred_taken |= ~s_g_io_out_bits_uop_pred_taken;
        checks++;
        if (s_g_io_out_bits_uop_crossPageIPFFix !== s_i_io_out_bits_uop_crossPageIPFFix) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_crossPageIPFFix g=%h i=%h", cyc, s_g_io_out_bits_uop_crossPageIPFFix, s_i_io_out_bits_uop_crossPageIPFFix);
        end
        s_s1_io_out_bits_uop_crossPageIPFFix |= s_g_io_out_bits_uop_crossPageIPFFix;
        s_s0_io_out_bits_uop_crossPageIPFFix |= ~s_g_io_out_bits_uop_crossPageIPFFix;
        checks++;
        if (s_g_io_out_bits_uop_ftqPtr_flag !== s_i_io_out_bits_uop_ftqPtr_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_ftqPtr_flag g=%h i=%h", cyc, s_g_io_out_bits_uop_ftqPtr_flag, s_i_io_out_bits_uop_ftqPtr_flag);
        end
        s_s1_io_out_bits_uop_ftqPtr_flag |= s_g_io_out_bits_uop_ftqPtr_flag;
        s_s0_io_out_bits_uop_ftqPtr_flag |= ~s_g_io_out_bits_uop_ftqPtr_flag;
        checks++;
        if (s_g_io_out_bits_uop_ftqPtr_value !== s_i_io_out_bits_uop_ftqPtr_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_ftqPtr_value g=%h i=%h", cyc, s_g_io_out_bits_uop_ftqPtr_value, s_i_io_out_bits_uop_ftqPtr_value);
        end
        s_s1_io_out_bits_uop_ftqPtr_value |= s_g_io_out_bits_uop_ftqPtr_value;
        s_s0_io_out_bits_uop_ftqPtr_value |= ~s_g_io_out_bits_uop_ftqPtr_value;
        checks++;
        if (s_g_io_out_bits_uop_ftqOffset !== s_i_io_out_bits_uop_ftqOffset) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_ftqOffset g=%h i=%h", cyc, s_g_io_out_bits_uop_ftqOffset, s_i_io_out_bits_uop_ftqOffset);
        end
        s_s1_io_out_bits_uop_ftqOffset |= s_g_io_out_bits_uop_ftqOffset;
        s_s0_io_out_bits_uop_ftqOffset |= ~s_g_io_out_bits_uop_ftqOffset;
        checks++;
        if (s_g_io_out_bits_uop_satpFlushFirstFetchFault !== s_i_io_out_bits_uop_satpFlushFirstFetchFault) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_satpFlushFirstFetchFault g=%h i=%h", cyc, s_g_io_out_bits_uop_satpFlushFirstFetchFault, s_i_io_out_bits_uop_satpFlushFirstFetchFault);
        end
        s_s1_io_out_bits_uop_satpFlushFirstFetchFault |= s_g_io_out_bits_uop_satpFlushFirstFetchFault;
        s_s0_io_out_bits_uop_satpFlushFirstFetchFault |= ~s_g_io_out_bits_uop_satpFlushFirstFetchFault;
        checks++;
        if (s_g_io_out_bits_uop_srcType_0 !== s_i_io_out_bits_uop_srcType_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_srcType_0 g=%h i=%h", cyc, s_g_io_out_bits_uop_srcType_0, s_i_io_out_bits_uop_srcType_0);
        end
        s_s1_io_out_bits_uop_srcType_0 |= s_g_io_out_bits_uop_srcType_0;
        s_s0_io_out_bits_uop_srcType_0 |= ~s_g_io_out_bits_uop_srcType_0;
        checks++;
        if (s_g_io_out_bits_uop_srcType_1 !== s_i_io_out_bits_uop_srcType_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_srcType_1 g=%h i=%h", cyc, s_g_io_out_bits_uop_srcType_1, s_i_io_out_bits_uop_srcType_1);
        end
        s_s1_io_out_bits_uop_srcType_1 |= s_g_io_out_bits_uop_srcType_1;
        s_s0_io_out_bits_uop_srcType_1 |= ~s_g_io_out_bits_uop_srcType_1;
        checks++;
        if (s_g_io_out_bits_uop_srcType_2 !== s_i_io_out_bits_uop_srcType_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_srcType_2 g=%h i=%h", cyc, s_g_io_out_bits_uop_srcType_2, s_i_io_out_bits_uop_srcType_2);
        end
        s_s1_io_out_bits_uop_srcType_2 |= s_g_io_out_bits_uop_srcType_2;
        s_s0_io_out_bits_uop_srcType_2 |= ~s_g_io_out_bits_uop_srcType_2;
        checks++;
        if (s_g_io_out_bits_uop_srcType_3 !== s_i_io_out_bits_uop_srcType_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_srcType_3 g=%h i=%h", cyc, s_g_io_out_bits_uop_srcType_3, s_i_io_out_bits_uop_srcType_3);
        end
        s_s1_io_out_bits_uop_srcType_3 |= s_g_io_out_bits_uop_srcType_3;
        s_s0_io_out_bits_uop_srcType_3 |= ~s_g_io_out_bits_uop_srcType_3;
        checks++;
        if (s_g_io_out_bits_uop_srcType_4 !== s_i_io_out_bits_uop_srcType_4) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_srcType_4 g=%h i=%h", cyc, s_g_io_out_bits_uop_srcType_4, s_i_io_out_bits_uop_srcType_4);
        end
        s_s1_io_out_bits_uop_srcType_4 |= s_g_io_out_bits_uop_srcType_4;
        s_s0_io_out_bits_uop_srcType_4 |= ~s_g_io_out_bits_uop_srcType_4;
        checks++;
        if (s_g_io_out_bits_uop_ldest !== s_i_io_out_bits_uop_ldest) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_ldest g=%h i=%h", cyc, s_g_io_out_bits_uop_ldest, s_i_io_out_bits_uop_ldest);
        end
        s_s1_io_out_bits_uop_ldest |= s_g_io_out_bits_uop_ldest;
        s_s0_io_out_bits_uop_ldest |= ~s_g_io_out_bits_uop_ldest;
        checks++;
        if (s_g_io_out_bits_uop_fuType !== s_i_io_out_bits_uop_fuType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_fuType g=%h i=%h", cyc, s_g_io_out_bits_uop_fuType, s_i_io_out_bits_uop_fuType);
        end
        s_s1_io_out_bits_uop_fuType |= s_g_io_out_bits_uop_fuType;
        s_s0_io_out_bits_uop_fuType |= ~s_g_io_out_bits_uop_fuType;
        checks++;
        if (s_g_io_out_bits_uop_fuOpType !== s_i_io_out_bits_uop_fuOpType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_fuOpType g=%h i=%h", cyc, s_g_io_out_bits_uop_fuOpType, s_i_io_out_bits_uop_fuOpType);
        end
        s_s1_io_out_bits_uop_fuOpType |= s_g_io_out_bits_uop_fuOpType;
        s_s0_io_out_bits_uop_fuOpType |= ~s_g_io_out_bits_uop_fuOpType;
        checks++;
        if (s_g_io_out_bits_uop_rfWen !== s_i_io_out_bits_uop_rfWen) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_rfWen g=%h i=%h", cyc, s_g_io_out_bits_uop_rfWen, s_i_io_out_bits_uop_rfWen);
        end
        s_s1_io_out_bits_uop_rfWen |= s_g_io_out_bits_uop_rfWen;
        s_s0_io_out_bits_uop_rfWen |= ~s_g_io_out_bits_uop_rfWen;
        checks++;
        if (s_g_io_out_bits_uop_fpWen !== s_i_io_out_bits_uop_fpWen) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_fpWen g=%h i=%h", cyc, s_g_io_out_bits_uop_fpWen, s_i_io_out_bits_uop_fpWen);
        end
        s_s1_io_out_bits_uop_fpWen |= s_g_io_out_bits_uop_fpWen;
        s_s0_io_out_bits_uop_fpWen |= ~s_g_io_out_bits_uop_fpWen;
        checks++;
        if (s_g_io_out_bits_uop_vecWen !== s_i_io_out_bits_uop_vecWen) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vecWen g=%h i=%h", cyc, s_g_io_out_bits_uop_vecWen, s_i_io_out_bits_uop_vecWen);
        end
        s_s1_io_out_bits_uop_vecWen |= s_g_io_out_bits_uop_vecWen;
        s_s0_io_out_bits_uop_vecWen |= ~s_g_io_out_bits_uop_vecWen;
        checks++;
        if (s_g_io_out_bits_uop_v0Wen !== s_i_io_out_bits_uop_v0Wen) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_v0Wen g=%h i=%h", cyc, s_g_io_out_bits_uop_v0Wen, s_i_io_out_bits_uop_v0Wen);
        end
        s_s1_io_out_bits_uop_v0Wen |= s_g_io_out_bits_uop_v0Wen;
        s_s0_io_out_bits_uop_v0Wen |= ~s_g_io_out_bits_uop_v0Wen;
        checks++;
        if (s_g_io_out_bits_uop_vlWen !== s_i_io_out_bits_uop_vlWen) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vlWen g=%h i=%h", cyc, s_g_io_out_bits_uop_vlWen, s_i_io_out_bits_uop_vlWen);
        end
        s_s1_io_out_bits_uop_vlWen |= s_g_io_out_bits_uop_vlWen;
        s_s0_io_out_bits_uop_vlWen |= ~s_g_io_out_bits_uop_vlWen;
        checks++;
        if (s_g_io_out_bits_uop_isXSTrap !== s_i_io_out_bits_uop_isXSTrap) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_isXSTrap g=%h i=%h", cyc, s_g_io_out_bits_uop_isXSTrap, s_i_io_out_bits_uop_isXSTrap);
        end
        s_s1_io_out_bits_uop_isXSTrap |= s_g_io_out_bits_uop_isXSTrap;
        s_s0_io_out_bits_uop_isXSTrap |= ~s_g_io_out_bits_uop_isXSTrap;
        checks++;
        if (s_g_io_out_bits_uop_waitForward !== s_i_io_out_bits_uop_waitForward) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_waitForward g=%h i=%h", cyc, s_g_io_out_bits_uop_waitForward, s_i_io_out_bits_uop_waitForward);
        end
        s_s1_io_out_bits_uop_waitForward |= s_g_io_out_bits_uop_waitForward;
        s_s0_io_out_bits_uop_waitForward |= ~s_g_io_out_bits_uop_waitForward;
        checks++;
        if (s_g_io_out_bits_uop_blockBackward !== s_i_io_out_bits_uop_blockBackward) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_blockBackward g=%h i=%h", cyc, s_g_io_out_bits_uop_blockBackward, s_i_io_out_bits_uop_blockBackward);
        end
        s_s1_io_out_bits_uop_blockBackward |= s_g_io_out_bits_uop_blockBackward;
        s_s0_io_out_bits_uop_blockBackward |= ~s_g_io_out_bits_uop_blockBackward;
        checks++;
        if (s_g_io_out_bits_uop_canRobCompress !== s_i_io_out_bits_uop_canRobCompress) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_canRobCompress g=%h i=%h", cyc, s_g_io_out_bits_uop_canRobCompress, s_i_io_out_bits_uop_canRobCompress);
        end
        s_s1_io_out_bits_uop_canRobCompress |= s_g_io_out_bits_uop_canRobCompress;
        s_s0_io_out_bits_uop_canRobCompress |= ~s_g_io_out_bits_uop_canRobCompress;
        checks++;
        if (s_g_io_out_bits_uop_selImm !== s_i_io_out_bits_uop_selImm) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_selImm g=%h i=%h", cyc, s_g_io_out_bits_uop_selImm, s_i_io_out_bits_uop_selImm);
        end
        s_s1_io_out_bits_uop_selImm |= s_g_io_out_bits_uop_selImm;
        s_s0_io_out_bits_uop_selImm |= ~s_g_io_out_bits_uop_selImm;
        checks++;
        if (s_g_io_out_bits_uop_fpu_typeTagOut !== s_i_io_out_bits_uop_fpu_typeTagOut) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_fpu_typeTagOut g=%h i=%h", cyc, s_g_io_out_bits_uop_fpu_typeTagOut, s_i_io_out_bits_uop_fpu_typeTagOut);
        end
        s_s1_io_out_bits_uop_fpu_typeTagOut |= s_g_io_out_bits_uop_fpu_typeTagOut;
        s_s0_io_out_bits_uop_fpu_typeTagOut |= ~s_g_io_out_bits_uop_fpu_typeTagOut;
        checks++;
        if (s_g_io_out_bits_uop_fpu_wflags !== s_i_io_out_bits_uop_fpu_wflags) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_fpu_wflags g=%h i=%h", cyc, s_g_io_out_bits_uop_fpu_wflags, s_i_io_out_bits_uop_fpu_wflags);
        end
        s_s1_io_out_bits_uop_fpu_wflags |= s_g_io_out_bits_uop_fpu_wflags;
        s_s0_io_out_bits_uop_fpu_wflags |= ~s_g_io_out_bits_uop_fpu_wflags;
        checks++;
        if (s_g_io_out_bits_uop_fpu_typ !== s_i_io_out_bits_uop_fpu_typ) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_fpu_typ g=%h i=%h", cyc, s_g_io_out_bits_uop_fpu_typ, s_i_io_out_bits_uop_fpu_typ);
        end
        s_s1_io_out_bits_uop_fpu_typ |= s_g_io_out_bits_uop_fpu_typ;
        s_s0_io_out_bits_uop_fpu_typ |= ~s_g_io_out_bits_uop_fpu_typ;
        checks++;
        if (s_g_io_out_bits_uop_fpu_fmt !== s_i_io_out_bits_uop_fpu_fmt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_fpu_fmt g=%h i=%h", cyc, s_g_io_out_bits_uop_fpu_fmt, s_i_io_out_bits_uop_fpu_fmt);
        end
        s_s1_io_out_bits_uop_fpu_fmt |= s_g_io_out_bits_uop_fpu_fmt;
        s_s0_io_out_bits_uop_fpu_fmt |= ~s_g_io_out_bits_uop_fpu_fmt;
        checks++;
        if (s_g_io_out_bits_uop_fpu_rm !== s_i_io_out_bits_uop_fpu_rm) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_fpu_rm g=%h i=%h", cyc, s_g_io_out_bits_uop_fpu_rm, s_i_io_out_bits_uop_fpu_rm);
        end
        s_s1_io_out_bits_uop_fpu_rm |= s_g_io_out_bits_uop_fpu_rm;
        s_s0_io_out_bits_uop_fpu_rm |= ~s_g_io_out_bits_uop_fpu_rm;
        checks++;
        if (s_g_io_out_bits_uop_vpu_vill !== s_i_io_out_bits_uop_vpu_vill) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_vill g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_vill, s_i_io_out_bits_uop_vpu_vill);
        end
        s_s1_io_out_bits_uop_vpu_vill |= s_g_io_out_bits_uop_vpu_vill;
        s_s0_io_out_bits_uop_vpu_vill |= ~s_g_io_out_bits_uop_vpu_vill;
        checks++;
        if (s_g_io_out_bits_uop_vpu_vma !== s_i_io_out_bits_uop_vpu_vma) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_vma g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_vma, s_i_io_out_bits_uop_vpu_vma);
        end
        s_s1_io_out_bits_uop_vpu_vma |= s_g_io_out_bits_uop_vpu_vma;
        s_s0_io_out_bits_uop_vpu_vma |= ~s_g_io_out_bits_uop_vpu_vma;
        checks++;
        if (s_g_io_out_bits_uop_vpu_vta !== s_i_io_out_bits_uop_vpu_vta) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_vta g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_vta, s_i_io_out_bits_uop_vpu_vta);
        end
        s_s1_io_out_bits_uop_vpu_vta |= s_g_io_out_bits_uop_vpu_vta;
        s_s0_io_out_bits_uop_vpu_vta |= ~s_g_io_out_bits_uop_vpu_vta;
        checks++;
        if (s_g_io_out_bits_uop_vpu_vsew !== s_i_io_out_bits_uop_vpu_vsew) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_vsew g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_vsew, s_i_io_out_bits_uop_vpu_vsew);
        end
        s_s1_io_out_bits_uop_vpu_vsew |= s_g_io_out_bits_uop_vpu_vsew;
        s_s0_io_out_bits_uop_vpu_vsew |= ~s_g_io_out_bits_uop_vpu_vsew;
        checks++;
        if (s_g_io_out_bits_uop_vpu_vlmul !== s_i_io_out_bits_uop_vpu_vlmul) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_vlmul g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_vlmul, s_i_io_out_bits_uop_vpu_vlmul);
        end
        s_s1_io_out_bits_uop_vpu_vlmul |= s_g_io_out_bits_uop_vpu_vlmul;
        s_s0_io_out_bits_uop_vpu_vlmul |= ~s_g_io_out_bits_uop_vpu_vlmul;
        checks++;
        if (s_g_io_out_bits_uop_vpu_specVill !== s_i_io_out_bits_uop_vpu_specVill) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_specVill g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_specVill, s_i_io_out_bits_uop_vpu_specVill);
        end
        s_s1_io_out_bits_uop_vpu_specVill |= s_g_io_out_bits_uop_vpu_specVill;
        s_s0_io_out_bits_uop_vpu_specVill |= ~s_g_io_out_bits_uop_vpu_specVill;
        checks++;
        if (s_g_io_out_bits_uop_vpu_specVma !== s_i_io_out_bits_uop_vpu_specVma) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_specVma g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_specVma, s_i_io_out_bits_uop_vpu_specVma);
        end
        s_s1_io_out_bits_uop_vpu_specVma |= s_g_io_out_bits_uop_vpu_specVma;
        s_s0_io_out_bits_uop_vpu_specVma |= ~s_g_io_out_bits_uop_vpu_specVma;
        checks++;
        if (s_g_io_out_bits_uop_vpu_specVta !== s_i_io_out_bits_uop_vpu_specVta) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_specVta g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_specVta, s_i_io_out_bits_uop_vpu_specVta);
        end
        s_s1_io_out_bits_uop_vpu_specVta |= s_g_io_out_bits_uop_vpu_specVta;
        s_s0_io_out_bits_uop_vpu_specVta |= ~s_g_io_out_bits_uop_vpu_specVta;
        checks++;
        if (s_g_io_out_bits_uop_vpu_specVsew !== s_i_io_out_bits_uop_vpu_specVsew) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_specVsew g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_specVsew, s_i_io_out_bits_uop_vpu_specVsew);
        end
        s_s1_io_out_bits_uop_vpu_specVsew |= s_g_io_out_bits_uop_vpu_specVsew;
        s_s0_io_out_bits_uop_vpu_specVsew |= ~s_g_io_out_bits_uop_vpu_specVsew;
        checks++;
        if (s_g_io_out_bits_uop_vpu_specVlmul !== s_i_io_out_bits_uop_vpu_specVlmul) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_specVlmul g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_specVlmul, s_i_io_out_bits_uop_vpu_specVlmul);
        end
        s_s1_io_out_bits_uop_vpu_specVlmul |= s_g_io_out_bits_uop_vpu_specVlmul;
        s_s0_io_out_bits_uop_vpu_specVlmul |= ~s_g_io_out_bits_uop_vpu_specVlmul;
        checks++;
        if (s_g_io_out_bits_uop_vpu_vm !== s_i_io_out_bits_uop_vpu_vm) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_vm g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_vm, s_i_io_out_bits_uop_vpu_vm);
        end
        s_s1_io_out_bits_uop_vpu_vm |= s_g_io_out_bits_uop_vpu_vm;
        s_s0_io_out_bits_uop_vpu_vm |= ~s_g_io_out_bits_uop_vpu_vm;
        checks++;
        if (s_g_io_out_bits_uop_vpu_vstart !== s_i_io_out_bits_uop_vpu_vstart) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_vstart g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_vstart, s_i_io_out_bits_uop_vpu_vstart);
        end
        s_s1_io_out_bits_uop_vpu_vstart |= s_g_io_out_bits_uop_vpu_vstart;
        s_s0_io_out_bits_uop_vpu_vstart |= ~s_g_io_out_bits_uop_vpu_vstart;
        checks++;
        if (s_g_io_out_bits_uop_vpu_frm !== s_i_io_out_bits_uop_vpu_frm) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_frm g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_frm, s_i_io_out_bits_uop_vpu_frm);
        end
        s_s1_io_out_bits_uop_vpu_frm |= s_g_io_out_bits_uop_vpu_frm;
        s_s0_io_out_bits_uop_vpu_frm |= ~s_g_io_out_bits_uop_vpu_frm;
        checks++;
        if (s_g_io_out_bits_uop_vpu_fpu_isFpToVecInst !== s_i_io_out_bits_uop_vpu_fpu_isFpToVecInst) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_fpu_isFpToVecInst g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_fpu_isFpToVecInst, s_i_io_out_bits_uop_vpu_fpu_isFpToVecInst);
        end
        s_s1_io_out_bits_uop_vpu_fpu_isFpToVecInst |= s_g_io_out_bits_uop_vpu_fpu_isFpToVecInst;
        s_s0_io_out_bits_uop_vpu_fpu_isFpToVecInst |= ~s_g_io_out_bits_uop_vpu_fpu_isFpToVecInst;
        checks++;
        if (s_g_io_out_bits_uop_vpu_fpu_isFP32Instr !== s_i_io_out_bits_uop_vpu_fpu_isFP32Instr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_fpu_isFP32Instr g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_fpu_isFP32Instr, s_i_io_out_bits_uop_vpu_fpu_isFP32Instr);
        end
        s_s1_io_out_bits_uop_vpu_fpu_isFP32Instr |= s_g_io_out_bits_uop_vpu_fpu_isFP32Instr;
        s_s0_io_out_bits_uop_vpu_fpu_isFP32Instr |= ~s_g_io_out_bits_uop_vpu_fpu_isFP32Instr;
        checks++;
        if (s_g_io_out_bits_uop_vpu_fpu_isFP64Instr !== s_i_io_out_bits_uop_vpu_fpu_isFP64Instr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_fpu_isFP64Instr g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_fpu_isFP64Instr, s_i_io_out_bits_uop_vpu_fpu_isFP64Instr);
        end
        s_s1_io_out_bits_uop_vpu_fpu_isFP64Instr |= s_g_io_out_bits_uop_vpu_fpu_isFP64Instr;
        s_s0_io_out_bits_uop_vpu_fpu_isFP64Instr |= ~s_g_io_out_bits_uop_vpu_fpu_isFP64Instr;
        checks++;
        if (s_g_io_out_bits_uop_vpu_fpu_isReduction !== s_i_io_out_bits_uop_vpu_fpu_isReduction) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_fpu_isReduction g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_fpu_isReduction, s_i_io_out_bits_uop_vpu_fpu_isReduction);
        end
        s_s1_io_out_bits_uop_vpu_fpu_isReduction |= s_g_io_out_bits_uop_vpu_fpu_isReduction;
        s_s0_io_out_bits_uop_vpu_fpu_isReduction |= ~s_g_io_out_bits_uop_vpu_fpu_isReduction;
        checks++;
        if (s_g_io_out_bits_uop_vpu_fpu_isFoldTo1_2 !== s_i_io_out_bits_uop_vpu_fpu_isFoldTo1_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_fpu_isFoldTo1_2 g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_fpu_isFoldTo1_2, s_i_io_out_bits_uop_vpu_fpu_isFoldTo1_2);
        end
        s_s1_io_out_bits_uop_vpu_fpu_isFoldTo1_2 |= s_g_io_out_bits_uop_vpu_fpu_isFoldTo1_2;
        s_s0_io_out_bits_uop_vpu_fpu_isFoldTo1_2 |= ~s_g_io_out_bits_uop_vpu_fpu_isFoldTo1_2;
        checks++;
        if (s_g_io_out_bits_uop_vpu_fpu_isFoldTo1_4 !== s_i_io_out_bits_uop_vpu_fpu_isFoldTo1_4) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_fpu_isFoldTo1_4 g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_fpu_isFoldTo1_4, s_i_io_out_bits_uop_vpu_fpu_isFoldTo1_4);
        end
        s_s1_io_out_bits_uop_vpu_fpu_isFoldTo1_4 |= s_g_io_out_bits_uop_vpu_fpu_isFoldTo1_4;
        s_s0_io_out_bits_uop_vpu_fpu_isFoldTo1_4 |= ~s_g_io_out_bits_uop_vpu_fpu_isFoldTo1_4;
        checks++;
        if (s_g_io_out_bits_uop_vpu_fpu_isFoldTo1_8 !== s_i_io_out_bits_uop_vpu_fpu_isFoldTo1_8) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_fpu_isFoldTo1_8 g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_fpu_isFoldTo1_8, s_i_io_out_bits_uop_vpu_fpu_isFoldTo1_8);
        end
        s_s1_io_out_bits_uop_vpu_fpu_isFoldTo1_8 |= s_g_io_out_bits_uop_vpu_fpu_isFoldTo1_8;
        s_s0_io_out_bits_uop_vpu_fpu_isFoldTo1_8 |= ~s_g_io_out_bits_uop_vpu_fpu_isFoldTo1_8;
        checks++;
        if (s_g_io_out_bits_uop_vpu_vxrm !== s_i_io_out_bits_uop_vpu_vxrm) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_vxrm g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_vxrm, s_i_io_out_bits_uop_vpu_vxrm);
        end
        s_s1_io_out_bits_uop_vpu_vxrm |= s_g_io_out_bits_uop_vpu_vxrm;
        s_s0_io_out_bits_uop_vpu_vxrm |= ~s_g_io_out_bits_uop_vpu_vxrm;
        checks++;
        if (s_g_io_out_bits_uop_vpu_vuopIdx !== s_i_io_out_bits_uop_vpu_vuopIdx) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_vuopIdx g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_vuopIdx, s_i_io_out_bits_uop_vpu_vuopIdx);
        end
        s_s1_io_out_bits_uop_vpu_vuopIdx |= s_g_io_out_bits_uop_vpu_vuopIdx;
        s_s0_io_out_bits_uop_vpu_vuopIdx |= ~s_g_io_out_bits_uop_vpu_vuopIdx;
        checks++;
        if (s_g_io_out_bits_uop_vpu_lastUop !== s_i_io_out_bits_uop_vpu_lastUop) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_lastUop g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_lastUop, s_i_io_out_bits_uop_vpu_lastUop);
        end
        s_s1_io_out_bits_uop_vpu_lastUop |= s_g_io_out_bits_uop_vpu_lastUop;
        s_s0_io_out_bits_uop_vpu_lastUop |= ~s_g_io_out_bits_uop_vpu_lastUop;
        checks++;
        if (s_g_io_out_bits_uop_vpu_vmask !== s_i_io_out_bits_uop_vpu_vmask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_vmask g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_vmask, s_i_io_out_bits_uop_vpu_vmask);
        end
        s_s1_io_out_bits_uop_vpu_vmask |= s_g_io_out_bits_uop_vpu_vmask;
        s_s0_io_out_bits_uop_vpu_vmask |= ~s_g_io_out_bits_uop_vpu_vmask;
        checks++;
        if (s_g_io_out_bits_uop_vpu_vl !== s_i_io_out_bits_uop_vpu_vl) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_vl g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_vl, s_i_io_out_bits_uop_vpu_vl);
        end
        s_s1_io_out_bits_uop_vpu_vl |= s_g_io_out_bits_uop_vpu_vl;
        s_s0_io_out_bits_uop_vpu_vl |= ~s_g_io_out_bits_uop_vpu_vl;
        checks++;
        if (s_g_io_out_bits_uop_vpu_nf !== s_i_io_out_bits_uop_vpu_nf) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_nf g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_nf, s_i_io_out_bits_uop_vpu_nf);
        end
        s_s1_io_out_bits_uop_vpu_nf |= s_g_io_out_bits_uop_vpu_nf;
        s_s0_io_out_bits_uop_vpu_nf |= ~s_g_io_out_bits_uop_vpu_nf;
        checks++;
        if (s_g_io_out_bits_uop_vpu_veew !== s_i_io_out_bits_uop_vpu_veew) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_veew g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_veew, s_i_io_out_bits_uop_vpu_veew);
        end
        s_s1_io_out_bits_uop_vpu_veew |= s_g_io_out_bits_uop_vpu_veew;
        s_s0_io_out_bits_uop_vpu_veew |= ~s_g_io_out_bits_uop_vpu_veew;
        checks++;
        if (s_g_io_out_bits_uop_vpu_isReverse !== s_i_io_out_bits_uop_vpu_isReverse) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_isReverse g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_isReverse, s_i_io_out_bits_uop_vpu_isReverse);
        end
        s_s1_io_out_bits_uop_vpu_isReverse |= s_g_io_out_bits_uop_vpu_isReverse;
        s_s0_io_out_bits_uop_vpu_isReverse |= ~s_g_io_out_bits_uop_vpu_isReverse;
        checks++;
        if (s_g_io_out_bits_uop_vpu_isExt !== s_i_io_out_bits_uop_vpu_isExt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_isExt g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_isExt, s_i_io_out_bits_uop_vpu_isExt);
        end
        s_s1_io_out_bits_uop_vpu_isExt |= s_g_io_out_bits_uop_vpu_isExt;
        s_s0_io_out_bits_uop_vpu_isExt |= ~s_g_io_out_bits_uop_vpu_isExt;
        checks++;
        if (s_g_io_out_bits_uop_vpu_isNarrow !== s_i_io_out_bits_uop_vpu_isNarrow) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_isNarrow g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_isNarrow, s_i_io_out_bits_uop_vpu_isNarrow);
        end
        s_s1_io_out_bits_uop_vpu_isNarrow |= s_g_io_out_bits_uop_vpu_isNarrow;
        s_s0_io_out_bits_uop_vpu_isNarrow |= ~s_g_io_out_bits_uop_vpu_isNarrow;
        checks++;
        if (s_g_io_out_bits_uop_vpu_isDstMask !== s_i_io_out_bits_uop_vpu_isDstMask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_isDstMask g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_isDstMask, s_i_io_out_bits_uop_vpu_isDstMask);
        end
        s_s1_io_out_bits_uop_vpu_isDstMask |= s_g_io_out_bits_uop_vpu_isDstMask;
        s_s0_io_out_bits_uop_vpu_isDstMask |= ~s_g_io_out_bits_uop_vpu_isDstMask;
        checks++;
        if (s_g_io_out_bits_uop_vpu_isOpMask !== s_i_io_out_bits_uop_vpu_isOpMask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_isOpMask g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_isOpMask, s_i_io_out_bits_uop_vpu_isOpMask);
        end
        s_s1_io_out_bits_uop_vpu_isOpMask |= s_g_io_out_bits_uop_vpu_isOpMask;
        s_s0_io_out_bits_uop_vpu_isOpMask |= ~s_g_io_out_bits_uop_vpu_isOpMask;
        checks++;
        if (s_g_io_out_bits_uop_vpu_isMove !== s_i_io_out_bits_uop_vpu_isMove) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_isMove g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_isMove, s_i_io_out_bits_uop_vpu_isMove);
        end
        s_s1_io_out_bits_uop_vpu_isMove |= s_g_io_out_bits_uop_vpu_isMove;
        s_s0_io_out_bits_uop_vpu_isMove |= ~s_g_io_out_bits_uop_vpu_isMove;
        checks++;
        if (s_g_io_out_bits_uop_vpu_isDependOldVd !== s_i_io_out_bits_uop_vpu_isDependOldVd) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_isDependOldVd g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_isDependOldVd, s_i_io_out_bits_uop_vpu_isDependOldVd);
        end
        s_s1_io_out_bits_uop_vpu_isDependOldVd |= s_g_io_out_bits_uop_vpu_isDependOldVd;
        s_s0_io_out_bits_uop_vpu_isDependOldVd |= ~s_g_io_out_bits_uop_vpu_isDependOldVd;
        checks++;
        if (s_g_io_out_bits_uop_vpu_isWritePartVd !== s_i_io_out_bits_uop_vpu_isWritePartVd) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_isWritePartVd g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_isWritePartVd, s_i_io_out_bits_uop_vpu_isWritePartVd);
        end
        s_s1_io_out_bits_uop_vpu_isWritePartVd |= s_g_io_out_bits_uop_vpu_isWritePartVd;
        s_s0_io_out_bits_uop_vpu_isWritePartVd |= ~s_g_io_out_bits_uop_vpu_isWritePartVd;
        checks++;
        if (s_g_io_out_bits_uop_vpu_isVleff !== s_i_io_out_bits_uop_vpu_isVleff) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vpu_isVleff g=%h i=%h", cyc, s_g_io_out_bits_uop_vpu_isVleff, s_i_io_out_bits_uop_vpu_isVleff);
        end
        s_s1_io_out_bits_uop_vpu_isVleff |= s_g_io_out_bits_uop_vpu_isVleff;
        s_s0_io_out_bits_uop_vpu_isVleff |= ~s_g_io_out_bits_uop_vpu_isVleff;
        checks++;
        if (s_g_io_out_bits_uop_vlsInstr !== s_i_io_out_bits_uop_vlsInstr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_vlsInstr g=%h i=%h", cyc, s_g_io_out_bits_uop_vlsInstr, s_i_io_out_bits_uop_vlsInstr);
        end
        s_s1_io_out_bits_uop_vlsInstr |= s_g_io_out_bits_uop_vlsInstr;
        s_s0_io_out_bits_uop_vlsInstr |= ~s_g_io_out_bits_uop_vlsInstr;
        checks++;
        if (s_g_io_out_bits_uop_wfflags !== s_i_io_out_bits_uop_wfflags) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_wfflags g=%h i=%h", cyc, s_g_io_out_bits_uop_wfflags, s_i_io_out_bits_uop_wfflags);
        end
        s_s1_io_out_bits_uop_wfflags |= s_g_io_out_bits_uop_wfflags;
        s_s0_io_out_bits_uop_wfflags |= ~s_g_io_out_bits_uop_wfflags;
        checks++;
        if (s_g_io_out_bits_uop_isMove !== s_i_io_out_bits_uop_isMove) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_isMove g=%h i=%h", cyc, s_g_io_out_bits_uop_isMove, s_i_io_out_bits_uop_isMove);
        end
        s_s1_io_out_bits_uop_isMove |= s_g_io_out_bits_uop_isMove;
        s_s0_io_out_bits_uop_isMove |= ~s_g_io_out_bits_uop_isMove;
        checks++;
        if (s_g_io_out_bits_uop_isDropAmocasSta !== s_i_io_out_bits_uop_isDropAmocasSta) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_isDropAmocasSta g=%h i=%h", cyc, s_g_io_out_bits_uop_isDropAmocasSta, s_i_io_out_bits_uop_isDropAmocasSta);
        end
        s_s1_io_out_bits_uop_isDropAmocasSta |= s_g_io_out_bits_uop_isDropAmocasSta;
        s_s0_io_out_bits_uop_isDropAmocasSta |= ~s_g_io_out_bits_uop_isDropAmocasSta;
        checks++;
        if (s_g_io_out_bits_uop_uopIdx !== s_i_io_out_bits_uop_uopIdx) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_uopIdx g=%h i=%h", cyc, s_g_io_out_bits_uop_uopIdx, s_i_io_out_bits_uop_uopIdx);
        end
        s_s1_io_out_bits_uop_uopIdx |= s_g_io_out_bits_uop_uopIdx;
        s_s0_io_out_bits_uop_uopIdx |= ~s_g_io_out_bits_uop_uopIdx;
        checks++;
        if (s_g_io_out_bits_uop_isVset !== s_i_io_out_bits_uop_isVset) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_isVset g=%h i=%h", cyc, s_g_io_out_bits_uop_isVset, s_i_io_out_bits_uop_isVset);
        end
        s_s1_io_out_bits_uop_isVset |= s_g_io_out_bits_uop_isVset;
        s_s0_io_out_bits_uop_isVset |= ~s_g_io_out_bits_uop_isVset;
        checks++;
        if (s_g_io_out_bits_uop_firstUop !== s_i_io_out_bits_uop_firstUop) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_firstUop g=%h i=%h", cyc, s_g_io_out_bits_uop_firstUop, s_i_io_out_bits_uop_firstUop);
        end
        s_s1_io_out_bits_uop_firstUop |= s_g_io_out_bits_uop_firstUop;
        s_s0_io_out_bits_uop_firstUop |= ~s_g_io_out_bits_uop_firstUop;
        checks++;
        if (s_g_io_out_bits_uop_lastUop !== s_i_io_out_bits_uop_lastUop) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_lastUop g=%h i=%h", cyc, s_g_io_out_bits_uop_lastUop, s_i_io_out_bits_uop_lastUop);
        end
        s_s1_io_out_bits_uop_lastUop |= s_g_io_out_bits_uop_lastUop;
        s_s0_io_out_bits_uop_lastUop |= ~s_g_io_out_bits_uop_lastUop;
        checks++;
        if (s_g_io_out_bits_uop_numUops !== s_i_io_out_bits_uop_numUops) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_numUops g=%h i=%h", cyc, s_g_io_out_bits_uop_numUops, s_i_io_out_bits_uop_numUops);
        end
        s_s1_io_out_bits_uop_numUops |= s_g_io_out_bits_uop_numUops;
        s_s0_io_out_bits_uop_numUops |= ~s_g_io_out_bits_uop_numUops;
        checks++;
        if (s_g_io_out_bits_uop_numWB !== s_i_io_out_bits_uop_numWB) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_numWB g=%h i=%h", cyc, s_g_io_out_bits_uop_numWB, s_i_io_out_bits_uop_numWB);
        end
        s_s1_io_out_bits_uop_numWB |= s_g_io_out_bits_uop_numWB;
        s_s0_io_out_bits_uop_numWB |= ~s_g_io_out_bits_uop_numWB;
        checks++;
        if (s_g_io_out_bits_uop_commitType !== s_i_io_out_bits_uop_commitType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_commitType g=%h i=%h", cyc, s_g_io_out_bits_uop_commitType, s_i_io_out_bits_uop_commitType);
        end
        s_s1_io_out_bits_uop_commitType |= s_g_io_out_bits_uop_commitType;
        s_s0_io_out_bits_uop_commitType |= ~s_g_io_out_bits_uop_commitType;
        checks++;
        if (s_g_io_out_bits_uop_srcState_0 !== s_i_io_out_bits_uop_srcState_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_srcState_0 g=%h i=%h", cyc, s_g_io_out_bits_uop_srcState_0, s_i_io_out_bits_uop_srcState_0);
        end
        s_s1_io_out_bits_uop_srcState_0 |= s_g_io_out_bits_uop_srcState_0;
        s_s0_io_out_bits_uop_srcState_0 |= ~s_g_io_out_bits_uop_srcState_0;
        checks++;
        if (s_g_io_out_bits_uop_srcState_1 !== s_i_io_out_bits_uop_srcState_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_srcState_1 g=%h i=%h", cyc, s_g_io_out_bits_uop_srcState_1, s_i_io_out_bits_uop_srcState_1);
        end
        s_s1_io_out_bits_uop_srcState_1 |= s_g_io_out_bits_uop_srcState_1;
        s_s0_io_out_bits_uop_srcState_1 |= ~s_g_io_out_bits_uop_srcState_1;
        checks++;
        if (s_g_io_out_bits_uop_srcState_2 !== s_i_io_out_bits_uop_srcState_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_srcState_2 g=%h i=%h", cyc, s_g_io_out_bits_uop_srcState_2, s_i_io_out_bits_uop_srcState_2);
        end
        s_s1_io_out_bits_uop_srcState_2 |= s_g_io_out_bits_uop_srcState_2;
        s_s0_io_out_bits_uop_srcState_2 |= ~s_g_io_out_bits_uop_srcState_2;
        checks++;
        if (s_g_io_out_bits_uop_srcState_3 !== s_i_io_out_bits_uop_srcState_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_srcState_3 g=%h i=%h", cyc, s_g_io_out_bits_uop_srcState_3, s_i_io_out_bits_uop_srcState_3);
        end
        s_s1_io_out_bits_uop_srcState_3 |= s_g_io_out_bits_uop_srcState_3;
        s_s0_io_out_bits_uop_srcState_3 |= ~s_g_io_out_bits_uop_srcState_3;
        checks++;
        if (s_g_io_out_bits_uop_srcState_4 !== s_i_io_out_bits_uop_srcState_4) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_srcState_4 g=%h i=%h", cyc, s_g_io_out_bits_uop_srcState_4, s_i_io_out_bits_uop_srcState_4);
        end
        s_s1_io_out_bits_uop_srcState_4 |= s_g_io_out_bits_uop_srcState_4;
        s_s0_io_out_bits_uop_srcState_4 |= ~s_g_io_out_bits_uop_srcState_4;
        checks++;
        if (s_g_io_out_bits_uop_srcLoadDependency_0_0 !== s_i_io_out_bits_uop_srcLoadDependency_0_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_srcLoadDependency_0_0 g=%h i=%h", cyc, s_g_io_out_bits_uop_srcLoadDependency_0_0, s_i_io_out_bits_uop_srcLoadDependency_0_0);
        end
        s_s1_io_out_bits_uop_srcLoadDependency_0_0 |= s_g_io_out_bits_uop_srcLoadDependency_0_0;
        s_s0_io_out_bits_uop_srcLoadDependency_0_0 |= ~s_g_io_out_bits_uop_srcLoadDependency_0_0;
        checks++;
        if (s_g_io_out_bits_uop_srcLoadDependency_0_1 !== s_i_io_out_bits_uop_srcLoadDependency_0_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_srcLoadDependency_0_1 g=%h i=%h", cyc, s_g_io_out_bits_uop_srcLoadDependency_0_1, s_i_io_out_bits_uop_srcLoadDependency_0_1);
        end
        s_s1_io_out_bits_uop_srcLoadDependency_0_1 |= s_g_io_out_bits_uop_srcLoadDependency_0_1;
        s_s0_io_out_bits_uop_srcLoadDependency_0_1 |= ~s_g_io_out_bits_uop_srcLoadDependency_0_1;
        checks++;
        if (s_g_io_out_bits_uop_srcLoadDependency_0_2 !== s_i_io_out_bits_uop_srcLoadDependency_0_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_srcLoadDependency_0_2 g=%h i=%h", cyc, s_g_io_out_bits_uop_srcLoadDependency_0_2, s_i_io_out_bits_uop_srcLoadDependency_0_2);
        end
        s_s1_io_out_bits_uop_srcLoadDependency_0_2 |= s_g_io_out_bits_uop_srcLoadDependency_0_2;
        s_s0_io_out_bits_uop_srcLoadDependency_0_2 |= ~s_g_io_out_bits_uop_srcLoadDependency_0_2;
        checks++;
        if (s_g_io_out_bits_uop_srcLoadDependency_1_0 !== s_i_io_out_bits_uop_srcLoadDependency_1_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_srcLoadDependency_1_0 g=%h i=%h", cyc, s_g_io_out_bits_uop_srcLoadDependency_1_0, s_i_io_out_bits_uop_srcLoadDependency_1_0);
        end
        s_s1_io_out_bits_uop_srcLoadDependency_1_0 |= s_g_io_out_bits_uop_srcLoadDependency_1_0;
        s_s0_io_out_bits_uop_srcLoadDependency_1_0 |= ~s_g_io_out_bits_uop_srcLoadDependency_1_0;
        checks++;
        if (s_g_io_out_bits_uop_srcLoadDependency_1_1 !== s_i_io_out_bits_uop_srcLoadDependency_1_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_srcLoadDependency_1_1 g=%h i=%h", cyc, s_g_io_out_bits_uop_srcLoadDependency_1_1, s_i_io_out_bits_uop_srcLoadDependency_1_1);
        end
        s_s1_io_out_bits_uop_srcLoadDependency_1_1 |= s_g_io_out_bits_uop_srcLoadDependency_1_1;
        s_s0_io_out_bits_uop_srcLoadDependency_1_1 |= ~s_g_io_out_bits_uop_srcLoadDependency_1_1;
        checks++;
        if (s_g_io_out_bits_uop_srcLoadDependency_1_2 !== s_i_io_out_bits_uop_srcLoadDependency_1_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_srcLoadDependency_1_2 g=%h i=%h", cyc, s_g_io_out_bits_uop_srcLoadDependency_1_2, s_i_io_out_bits_uop_srcLoadDependency_1_2);
        end
        s_s1_io_out_bits_uop_srcLoadDependency_1_2 |= s_g_io_out_bits_uop_srcLoadDependency_1_2;
        s_s0_io_out_bits_uop_srcLoadDependency_1_2 |= ~s_g_io_out_bits_uop_srcLoadDependency_1_2;
        checks++;
        if (s_g_io_out_bits_uop_srcLoadDependency_2_0 !== s_i_io_out_bits_uop_srcLoadDependency_2_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_srcLoadDependency_2_0 g=%h i=%h", cyc, s_g_io_out_bits_uop_srcLoadDependency_2_0, s_i_io_out_bits_uop_srcLoadDependency_2_0);
        end
        s_s1_io_out_bits_uop_srcLoadDependency_2_0 |= s_g_io_out_bits_uop_srcLoadDependency_2_0;
        s_s0_io_out_bits_uop_srcLoadDependency_2_0 |= ~s_g_io_out_bits_uop_srcLoadDependency_2_0;
        checks++;
        if (s_g_io_out_bits_uop_srcLoadDependency_2_1 !== s_i_io_out_bits_uop_srcLoadDependency_2_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_srcLoadDependency_2_1 g=%h i=%h", cyc, s_g_io_out_bits_uop_srcLoadDependency_2_1, s_i_io_out_bits_uop_srcLoadDependency_2_1);
        end
        s_s1_io_out_bits_uop_srcLoadDependency_2_1 |= s_g_io_out_bits_uop_srcLoadDependency_2_1;
        s_s0_io_out_bits_uop_srcLoadDependency_2_1 |= ~s_g_io_out_bits_uop_srcLoadDependency_2_1;
        checks++;
        if (s_g_io_out_bits_uop_srcLoadDependency_2_2 !== s_i_io_out_bits_uop_srcLoadDependency_2_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_srcLoadDependency_2_2 g=%h i=%h", cyc, s_g_io_out_bits_uop_srcLoadDependency_2_2, s_i_io_out_bits_uop_srcLoadDependency_2_2);
        end
        s_s1_io_out_bits_uop_srcLoadDependency_2_2 |= s_g_io_out_bits_uop_srcLoadDependency_2_2;
        s_s0_io_out_bits_uop_srcLoadDependency_2_2 |= ~s_g_io_out_bits_uop_srcLoadDependency_2_2;
        checks++;
        if (s_g_io_out_bits_uop_srcLoadDependency_3_0 !== s_i_io_out_bits_uop_srcLoadDependency_3_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_srcLoadDependency_3_0 g=%h i=%h", cyc, s_g_io_out_bits_uop_srcLoadDependency_3_0, s_i_io_out_bits_uop_srcLoadDependency_3_0);
        end
        s_s1_io_out_bits_uop_srcLoadDependency_3_0 |= s_g_io_out_bits_uop_srcLoadDependency_3_0;
        s_s0_io_out_bits_uop_srcLoadDependency_3_0 |= ~s_g_io_out_bits_uop_srcLoadDependency_3_0;
        checks++;
        if (s_g_io_out_bits_uop_srcLoadDependency_3_1 !== s_i_io_out_bits_uop_srcLoadDependency_3_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_srcLoadDependency_3_1 g=%h i=%h", cyc, s_g_io_out_bits_uop_srcLoadDependency_3_1, s_i_io_out_bits_uop_srcLoadDependency_3_1);
        end
        s_s1_io_out_bits_uop_srcLoadDependency_3_1 |= s_g_io_out_bits_uop_srcLoadDependency_3_1;
        s_s0_io_out_bits_uop_srcLoadDependency_3_1 |= ~s_g_io_out_bits_uop_srcLoadDependency_3_1;
        checks++;
        if (s_g_io_out_bits_uop_srcLoadDependency_3_2 !== s_i_io_out_bits_uop_srcLoadDependency_3_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_srcLoadDependency_3_2 g=%h i=%h", cyc, s_g_io_out_bits_uop_srcLoadDependency_3_2, s_i_io_out_bits_uop_srcLoadDependency_3_2);
        end
        s_s1_io_out_bits_uop_srcLoadDependency_3_2 |= s_g_io_out_bits_uop_srcLoadDependency_3_2;
        s_s0_io_out_bits_uop_srcLoadDependency_3_2 |= ~s_g_io_out_bits_uop_srcLoadDependency_3_2;
        checks++;
        if (s_g_io_out_bits_uop_srcLoadDependency_4_0 !== s_i_io_out_bits_uop_srcLoadDependency_4_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_srcLoadDependency_4_0 g=%h i=%h", cyc, s_g_io_out_bits_uop_srcLoadDependency_4_0, s_i_io_out_bits_uop_srcLoadDependency_4_0);
        end
        s_s1_io_out_bits_uop_srcLoadDependency_4_0 |= s_g_io_out_bits_uop_srcLoadDependency_4_0;
        s_s0_io_out_bits_uop_srcLoadDependency_4_0 |= ~s_g_io_out_bits_uop_srcLoadDependency_4_0;
        checks++;
        if (s_g_io_out_bits_uop_srcLoadDependency_4_1 !== s_i_io_out_bits_uop_srcLoadDependency_4_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_srcLoadDependency_4_1 g=%h i=%h", cyc, s_g_io_out_bits_uop_srcLoadDependency_4_1, s_i_io_out_bits_uop_srcLoadDependency_4_1);
        end
        s_s1_io_out_bits_uop_srcLoadDependency_4_1 |= s_g_io_out_bits_uop_srcLoadDependency_4_1;
        s_s0_io_out_bits_uop_srcLoadDependency_4_1 |= ~s_g_io_out_bits_uop_srcLoadDependency_4_1;
        checks++;
        if (s_g_io_out_bits_uop_srcLoadDependency_4_2 !== s_i_io_out_bits_uop_srcLoadDependency_4_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_srcLoadDependency_4_2 g=%h i=%h", cyc, s_g_io_out_bits_uop_srcLoadDependency_4_2, s_i_io_out_bits_uop_srcLoadDependency_4_2);
        end
        s_s1_io_out_bits_uop_srcLoadDependency_4_2 |= s_g_io_out_bits_uop_srcLoadDependency_4_2;
        s_s0_io_out_bits_uop_srcLoadDependency_4_2 |= ~s_g_io_out_bits_uop_srcLoadDependency_4_2;
        checks++;
        if (s_g_io_out_bits_uop_psrc_0 !== s_i_io_out_bits_uop_psrc_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_psrc_0 g=%h i=%h", cyc, s_g_io_out_bits_uop_psrc_0, s_i_io_out_bits_uop_psrc_0);
        end
        s_s1_io_out_bits_uop_psrc_0 |= s_g_io_out_bits_uop_psrc_0;
        s_s0_io_out_bits_uop_psrc_0 |= ~s_g_io_out_bits_uop_psrc_0;
        checks++;
        if (s_g_io_out_bits_uop_psrc_1 !== s_i_io_out_bits_uop_psrc_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_psrc_1 g=%h i=%h", cyc, s_g_io_out_bits_uop_psrc_1, s_i_io_out_bits_uop_psrc_1);
        end
        s_s1_io_out_bits_uop_psrc_1 |= s_g_io_out_bits_uop_psrc_1;
        s_s0_io_out_bits_uop_psrc_1 |= ~s_g_io_out_bits_uop_psrc_1;
        checks++;
        if (s_g_io_out_bits_uop_psrc_2 !== s_i_io_out_bits_uop_psrc_2) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_psrc_2 g=%h i=%h", cyc, s_g_io_out_bits_uop_psrc_2, s_i_io_out_bits_uop_psrc_2);
        end
        s_s1_io_out_bits_uop_psrc_2 |= s_g_io_out_bits_uop_psrc_2;
        s_s0_io_out_bits_uop_psrc_2 |= ~s_g_io_out_bits_uop_psrc_2;
        checks++;
        if (s_g_io_out_bits_uop_psrc_3 !== s_i_io_out_bits_uop_psrc_3) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_psrc_3 g=%h i=%h", cyc, s_g_io_out_bits_uop_psrc_3, s_i_io_out_bits_uop_psrc_3);
        end
        s_s1_io_out_bits_uop_psrc_3 |= s_g_io_out_bits_uop_psrc_3;
        s_s0_io_out_bits_uop_psrc_3 |= ~s_g_io_out_bits_uop_psrc_3;
        checks++;
        if (s_g_io_out_bits_uop_psrc_4 !== s_i_io_out_bits_uop_psrc_4) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_psrc_4 g=%h i=%h", cyc, s_g_io_out_bits_uop_psrc_4, s_i_io_out_bits_uop_psrc_4);
        end
        s_s1_io_out_bits_uop_psrc_4 |= s_g_io_out_bits_uop_psrc_4;
        s_s0_io_out_bits_uop_psrc_4 |= ~s_g_io_out_bits_uop_psrc_4;
        checks++;
        if (s_g_io_out_bits_uop_pdest !== s_i_io_out_bits_uop_pdest) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_pdest g=%h i=%h", cyc, s_g_io_out_bits_uop_pdest, s_i_io_out_bits_uop_pdest);
        end
        s_s1_io_out_bits_uop_pdest |= s_g_io_out_bits_uop_pdest;
        s_s0_io_out_bits_uop_pdest |= ~s_g_io_out_bits_uop_pdest;
        checks++;
        if (s_g_io_out_bits_uop_useRegCache_0 !== s_i_io_out_bits_uop_useRegCache_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_useRegCache_0 g=%h i=%h", cyc, s_g_io_out_bits_uop_useRegCache_0, s_i_io_out_bits_uop_useRegCache_0);
        end
        s_s1_io_out_bits_uop_useRegCache_0 |= s_g_io_out_bits_uop_useRegCache_0;
        s_s0_io_out_bits_uop_useRegCache_0 |= ~s_g_io_out_bits_uop_useRegCache_0;
        checks++;
        if (s_g_io_out_bits_uop_useRegCache_1 !== s_i_io_out_bits_uop_useRegCache_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_useRegCache_1 g=%h i=%h", cyc, s_g_io_out_bits_uop_useRegCache_1, s_i_io_out_bits_uop_useRegCache_1);
        end
        s_s1_io_out_bits_uop_useRegCache_1 |= s_g_io_out_bits_uop_useRegCache_1;
        s_s0_io_out_bits_uop_useRegCache_1 |= ~s_g_io_out_bits_uop_useRegCache_1;
        checks++;
        if (s_g_io_out_bits_uop_regCacheIdx_0 !== s_i_io_out_bits_uop_regCacheIdx_0) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_regCacheIdx_0 g=%h i=%h", cyc, s_g_io_out_bits_uop_regCacheIdx_0, s_i_io_out_bits_uop_regCacheIdx_0);
        end
        s_s1_io_out_bits_uop_regCacheIdx_0 |= s_g_io_out_bits_uop_regCacheIdx_0;
        s_s0_io_out_bits_uop_regCacheIdx_0 |= ~s_g_io_out_bits_uop_regCacheIdx_0;
        checks++;
        if (s_g_io_out_bits_uop_regCacheIdx_1 !== s_i_io_out_bits_uop_regCacheIdx_1) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_regCacheIdx_1 g=%h i=%h", cyc, s_g_io_out_bits_uop_regCacheIdx_1, s_i_io_out_bits_uop_regCacheIdx_1);
        end
        s_s1_io_out_bits_uop_regCacheIdx_1 |= s_g_io_out_bits_uop_regCacheIdx_1;
        s_s0_io_out_bits_uop_regCacheIdx_1 |= ~s_g_io_out_bits_uop_regCacheIdx_1;
        checks++;
        if (s_g_io_out_bits_uop_robIdx_flag !== s_i_io_out_bits_uop_robIdx_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_robIdx_flag g=%h i=%h", cyc, s_g_io_out_bits_uop_robIdx_flag, s_i_io_out_bits_uop_robIdx_flag);
        end
        s_s1_io_out_bits_uop_robIdx_flag |= s_g_io_out_bits_uop_robIdx_flag;
        s_s0_io_out_bits_uop_robIdx_flag |= ~s_g_io_out_bits_uop_robIdx_flag;
        checks++;
        if (s_g_io_out_bits_uop_robIdx_value !== s_i_io_out_bits_uop_robIdx_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_robIdx_value g=%h i=%h", cyc, s_g_io_out_bits_uop_robIdx_value, s_i_io_out_bits_uop_robIdx_value);
        end
        s_s1_io_out_bits_uop_robIdx_value |= s_g_io_out_bits_uop_robIdx_value;
        s_s0_io_out_bits_uop_robIdx_value |= ~s_g_io_out_bits_uop_robIdx_value;
        checks++;
        if (s_g_io_out_bits_uop_instrSize !== s_i_io_out_bits_uop_instrSize) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_instrSize g=%h i=%h", cyc, s_g_io_out_bits_uop_instrSize, s_i_io_out_bits_uop_instrSize);
        end
        s_s1_io_out_bits_uop_instrSize |= s_g_io_out_bits_uop_instrSize;
        s_s0_io_out_bits_uop_instrSize |= ~s_g_io_out_bits_uop_instrSize;
        checks++;
        if (s_g_io_out_bits_uop_dirtyFs !== s_i_io_out_bits_uop_dirtyFs) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_dirtyFs g=%h i=%h", cyc, s_g_io_out_bits_uop_dirtyFs, s_i_io_out_bits_uop_dirtyFs);
        end
        s_s1_io_out_bits_uop_dirtyFs |= s_g_io_out_bits_uop_dirtyFs;
        s_s0_io_out_bits_uop_dirtyFs |= ~s_g_io_out_bits_uop_dirtyFs;
        checks++;
        if (s_g_io_out_bits_uop_dirtyVs !== s_i_io_out_bits_uop_dirtyVs) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_dirtyVs g=%h i=%h", cyc, s_g_io_out_bits_uop_dirtyVs, s_i_io_out_bits_uop_dirtyVs);
        end
        s_s1_io_out_bits_uop_dirtyVs |= s_g_io_out_bits_uop_dirtyVs;
        s_s0_io_out_bits_uop_dirtyVs |= ~s_g_io_out_bits_uop_dirtyVs;
        checks++;
        if (s_g_io_out_bits_uop_traceBlockInPipe_itype !== s_i_io_out_bits_uop_traceBlockInPipe_itype) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_traceBlockInPipe_itype g=%h i=%h", cyc, s_g_io_out_bits_uop_traceBlockInPipe_itype, s_i_io_out_bits_uop_traceBlockInPipe_itype);
        end
        s_s1_io_out_bits_uop_traceBlockInPipe_itype |= s_g_io_out_bits_uop_traceBlockInPipe_itype;
        s_s0_io_out_bits_uop_traceBlockInPipe_itype |= ~s_g_io_out_bits_uop_traceBlockInPipe_itype;
        checks++;
        if (s_g_io_out_bits_uop_traceBlockInPipe_iretire !== s_i_io_out_bits_uop_traceBlockInPipe_iretire) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_traceBlockInPipe_iretire g=%h i=%h", cyc, s_g_io_out_bits_uop_traceBlockInPipe_iretire, s_i_io_out_bits_uop_traceBlockInPipe_iretire);
        end
        s_s1_io_out_bits_uop_traceBlockInPipe_iretire |= s_g_io_out_bits_uop_traceBlockInPipe_iretire;
        s_s0_io_out_bits_uop_traceBlockInPipe_iretire |= ~s_g_io_out_bits_uop_traceBlockInPipe_iretire;
        checks++;
        if (s_g_io_out_bits_uop_traceBlockInPipe_ilastsize !== s_i_io_out_bits_uop_traceBlockInPipe_ilastsize) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_traceBlockInPipe_ilastsize g=%h i=%h", cyc, s_g_io_out_bits_uop_traceBlockInPipe_ilastsize, s_i_io_out_bits_uop_traceBlockInPipe_ilastsize);
        end
        s_s1_io_out_bits_uop_traceBlockInPipe_ilastsize |= s_g_io_out_bits_uop_traceBlockInPipe_ilastsize;
        s_s0_io_out_bits_uop_traceBlockInPipe_ilastsize |= ~s_g_io_out_bits_uop_traceBlockInPipe_ilastsize;
        checks++;
        if (s_g_io_out_bits_uop_eliminatedMove !== s_i_io_out_bits_uop_eliminatedMove) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_eliminatedMove g=%h i=%h", cyc, s_g_io_out_bits_uop_eliminatedMove, s_i_io_out_bits_uop_eliminatedMove);
        end
        s_s1_io_out_bits_uop_eliminatedMove |= s_g_io_out_bits_uop_eliminatedMove;
        s_s0_io_out_bits_uop_eliminatedMove |= ~s_g_io_out_bits_uop_eliminatedMove;
        checks++;
        if (s_g_io_out_bits_uop_snapshot !== s_i_io_out_bits_uop_snapshot) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_snapshot g=%h i=%h", cyc, s_g_io_out_bits_uop_snapshot, s_i_io_out_bits_uop_snapshot);
        end
        s_s1_io_out_bits_uop_snapshot |= s_g_io_out_bits_uop_snapshot;
        s_s0_io_out_bits_uop_snapshot |= ~s_g_io_out_bits_uop_snapshot;
        checks++;
        if (s_g_io_out_bits_uop_debugInfo_eliminatedMove !== s_i_io_out_bits_uop_debugInfo_eliminatedMove) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_debugInfo_eliminatedMove g=%h i=%h", cyc, s_g_io_out_bits_uop_debugInfo_eliminatedMove, s_i_io_out_bits_uop_debugInfo_eliminatedMove);
        end
        s_s1_io_out_bits_uop_debugInfo_eliminatedMove |= s_g_io_out_bits_uop_debugInfo_eliminatedMove;
        s_s0_io_out_bits_uop_debugInfo_eliminatedMove |= ~s_g_io_out_bits_uop_debugInfo_eliminatedMove;
        checks++;
        if (s_g_io_out_bits_uop_debugInfo_renameTime !== s_i_io_out_bits_uop_debugInfo_renameTime) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_debugInfo_renameTime g=%h i=%h", cyc, s_g_io_out_bits_uop_debugInfo_renameTime, s_i_io_out_bits_uop_debugInfo_renameTime);
        end
        s_s1_io_out_bits_uop_debugInfo_renameTime |= s_g_io_out_bits_uop_debugInfo_renameTime;
        s_s0_io_out_bits_uop_debugInfo_renameTime |= ~s_g_io_out_bits_uop_debugInfo_renameTime;
        checks++;
        if (s_g_io_out_bits_uop_debugInfo_dispatchTime !== s_i_io_out_bits_uop_debugInfo_dispatchTime) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime g=%h i=%h", cyc, s_g_io_out_bits_uop_debugInfo_dispatchTime, s_i_io_out_bits_uop_debugInfo_dispatchTime);
        end
        s_s1_io_out_bits_uop_debugInfo_dispatchTime |= s_g_io_out_bits_uop_debugInfo_dispatchTime;
        s_s0_io_out_bits_uop_debugInfo_dispatchTime |= ~s_g_io_out_bits_uop_debugInfo_dispatchTime;
        checks++;
        if (s_g_io_out_bits_uop_debugInfo_enqRsTime !== s_i_io_out_bits_uop_debugInfo_enqRsTime) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime g=%h i=%h", cyc, s_g_io_out_bits_uop_debugInfo_enqRsTime, s_i_io_out_bits_uop_debugInfo_enqRsTime);
        end
        s_s1_io_out_bits_uop_debugInfo_enqRsTime |= s_g_io_out_bits_uop_debugInfo_enqRsTime;
        s_s0_io_out_bits_uop_debugInfo_enqRsTime |= ~s_g_io_out_bits_uop_debugInfo_enqRsTime;
        checks++;
        if (s_g_io_out_bits_uop_debugInfo_selectTime !== s_i_io_out_bits_uop_debugInfo_selectTime) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_debugInfo_selectTime g=%h i=%h", cyc, s_g_io_out_bits_uop_debugInfo_selectTime, s_i_io_out_bits_uop_debugInfo_selectTime);
        end
        s_s1_io_out_bits_uop_debugInfo_selectTime |= s_g_io_out_bits_uop_debugInfo_selectTime;
        s_s0_io_out_bits_uop_debugInfo_selectTime |= ~s_g_io_out_bits_uop_debugInfo_selectTime;
        checks++;
        if (s_g_io_out_bits_uop_debugInfo_issueTime !== s_i_io_out_bits_uop_debugInfo_issueTime) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_debugInfo_issueTime g=%h i=%h", cyc, s_g_io_out_bits_uop_debugInfo_issueTime, s_i_io_out_bits_uop_debugInfo_issueTime);
        end
        s_s1_io_out_bits_uop_debugInfo_issueTime |= s_g_io_out_bits_uop_debugInfo_issueTime;
        s_s0_io_out_bits_uop_debugInfo_issueTime |= ~s_g_io_out_bits_uop_debugInfo_issueTime;
        checks++;
        if (s_g_io_out_bits_uop_debugInfo_writebackTime !== s_i_io_out_bits_uop_debugInfo_writebackTime) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime g=%h i=%h", cyc, s_g_io_out_bits_uop_debugInfo_writebackTime, s_i_io_out_bits_uop_debugInfo_writebackTime);
        end
        s_s1_io_out_bits_uop_debugInfo_writebackTime |= s_g_io_out_bits_uop_debugInfo_writebackTime;
        s_s0_io_out_bits_uop_debugInfo_writebackTime |= ~s_g_io_out_bits_uop_debugInfo_writebackTime;
        checks++;
        if (s_g_io_out_bits_uop_debugInfo_runahead_checkpoint_id !== s_i_io_out_bits_uop_debugInfo_runahead_checkpoint_id) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id g=%h i=%h", cyc, s_g_io_out_bits_uop_debugInfo_runahead_checkpoint_id, s_i_io_out_bits_uop_debugInfo_runahead_checkpoint_id);
        end
        s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id |= s_g_io_out_bits_uop_debugInfo_runahead_checkpoint_id;
        s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id |= ~s_g_io_out_bits_uop_debugInfo_runahead_checkpoint_id;
        checks++;
        if (s_g_io_out_bits_uop_debugInfo_tlbFirstReqTime !== s_i_io_out_bits_uop_debugInfo_tlbFirstReqTime) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime g=%h i=%h", cyc, s_g_io_out_bits_uop_debugInfo_tlbFirstReqTime, s_i_io_out_bits_uop_debugInfo_tlbFirstReqTime);
        end
        s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime |= s_g_io_out_bits_uop_debugInfo_tlbFirstReqTime;
        s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime |= ~s_g_io_out_bits_uop_debugInfo_tlbFirstReqTime;
        checks++;
        if (s_g_io_out_bits_uop_debugInfo_tlbRespTime !== s_i_io_out_bits_uop_debugInfo_tlbRespTime) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime g=%h i=%h", cyc, s_g_io_out_bits_uop_debugInfo_tlbRespTime, s_i_io_out_bits_uop_debugInfo_tlbRespTime);
        end
        s_s1_io_out_bits_uop_debugInfo_tlbRespTime |= s_g_io_out_bits_uop_debugInfo_tlbRespTime;
        s_s0_io_out_bits_uop_debugInfo_tlbRespTime |= ~s_g_io_out_bits_uop_debugInfo_tlbRespTime;
        checks++;
        if (s_g_io_out_bits_uop_debug_seqNum_seqNum !== s_i_io_out_bits_uop_debug_seqNum_seqNum) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum g=%h i=%h", cyc, s_g_io_out_bits_uop_debug_seqNum_seqNum, s_i_io_out_bits_uop_debug_seqNum_seqNum);
        end
        s_s1_io_out_bits_uop_debug_seqNum_seqNum |= s_g_io_out_bits_uop_debug_seqNum_seqNum;
        s_s0_io_out_bits_uop_debug_seqNum_seqNum |= ~s_g_io_out_bits_uop_debug_seqNum_seqNum;
        checks++;
        if (s_g_io_out_bits_uop_debug_seqNum_uopIdx !== s_i_io_out_bits_uop_debug_seqNum_uopIdx) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_debug_seqNum_uopIdx g=%h i=%h", cyc, s_g_io_out_bits_uop_debug_seqNum_uopIdx, s_i_io_out_bits_uop_debug_seqNum_uopIdx);
        end
        s_s1_io_out_bits_uop_debug_seqNum_uopIdx |= s_g_io_out_bits_uop_debug_seqNum_uopIdx;
        s_s0_io_out_bits_uop_debug_seqNum_uopIdx |= ~s_g_io_out_bits_uop_debug_seqNum_uopIdx;
        checks++;
        if (s_g_io_out_bits_uop_storeSetHit !== s_i_io_out_bits_uop_storeSetHit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_storeSetHit g=%h i=%h", cyc, s_g_io_out_bits_uop_storeSetHit, s_i_io_out_bits_uop_storeSetHit);
        end
        s_s1_io_out_bits_uop_storeSetHit |= s_g_io_out_bits_uop_storeSetHit;
        s_s0_io_out_bits_uop_storeSetHit |= ~s_g_io_out_bits_uop_storeSetHit;
        checks++;
        if (s_g_io_out_bits_uop_waitForRobIdx_flag !== s_i_io_out_bits_uop_waitForRobIdx_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_waitForRobIdx_flag g=%h i=%h", cyc, s_g_io_out_bits_uop_waitForRobIdx_flag, s_i_io_out_bits_uop_waitForRobIdx_flag);
        end
        s_s1_io_out_bits_uop_waitForRobIdx_flag |= s_g_io_out_bits_uop_waitForRobIdx_flag;
        s_s0_io_out_bits_uop_waitForRobIdx_flag |= ~s_g_io_out_bits_uop_waitForRobIdx_flag;
        checks++;
        if (s_g_io_out_bits_uop_waitForRobIdx_value !== s_i_io_out_bits_uop_waitForRobIdx_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_waitForRobIdx_value g=%h i=%h", cyc, s_g_io_out_bits_uop_waitForRobIdx_value, s_i_io_out_bits_uop_waitForRobIdx_value);
        end
        s_s1_io_out_bits_uop_waitForRobIdx_value |= s_g_io_out_bits_uop_waitForRobIdx_value;
        s_s0_io_out_bits_uop_waitForRobIdx_value |= ~s_g_io_out_bits_uop_waitForRobIdx_value;
        checks++;
        if (s_g_io_out_bits_uop_loadWaitBit !== s_i_io_out_bits_uop_loadWaitBit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_loadWaitBit g=%h i=%h", cyc, s_g_io_out_bits_uop_loadWaitBit, s_i_io_out_bits_uop_loadWaitBit);
        end
        s_s1_io_out_bits_uop_loadWaitBit |= s_g_io_out_bits_uop_loadWaitBit;
        s_s0_io_out_bits_uop_loadWaitBit |= ~s_g_io_out_bits_uop_loadWaitBit;
        checks++;
        if (s_g_io_out_bits_uop_loadWaitStrict !== s_i_io_out_bits_uop_loadWaitStrict) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_loadWaitStrict g=%h i=%h", cyc, s_g_io_out_bits_uop_loadWaitStrict, s_i_io_out_bits_uop_loadWaitStrict);
        end
        s_s1_io_out_bits_uop_loadWaitStrict |= s_g_io_out_bits_uop_loadWaitStrict;
        s_s0_io_out_bits_uop_loadWaitStrict |= ~s_g_io_out_bits_uop_loadWaitStrict;
        checks++;
        if (s_g_io_out_bits_uop_ssid !== s_i_io_out_bits_uop_ssid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_ssid g=%h i=%h", cyc, s_g_io_out_bits_uop_ssid, s_i_io_out_bits_uop_ssid);
        end
        s_s1_io_out_bits_uop_ssid |= s_g_io_out_bits_uop_ssid;
        s_s0_io_out_bits_uop_ssid |= ~s_g_io_out_bits_uop_ssid;
        checks++;
        if (s_g_io_out_bits_uop_lqIdx_flag !== s_i_io_out_bits_uop_lqIdx_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_lqIdx_flag g=%h i=%h", cyc, s_g_io_out_bits_uop_lqIdx_flag, s_i_io_out_bits_uop_lqIdx_flag);
        end
        s_s1_io_out_bits_uop_lqIdx_flag |= s_g_io_out_bits_uop_lqIdx_flag;
        s_s0_io_out_bits_uop_lqIdx_flag |= ~s_g_io_out_bits_uop_lqIdx_flag;
        checks++;
        if (s_g_io_out_bits_uop_lqIdx_value !== s_i_io_out_bits_uop_lqIdx_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_lqIdx_value g=%h i=%h", cyc, s_g_io_out_bits_uop_lqIdx_value, s_i_io_out_bits_uop_lqIdx_value);
        end
        s_s1_io_out_bits_uop_lqIdx_value |= s_g_io_out_bits_uop_lqIdx_value;
        s_s0_io_out_bits_uop_lqIdx_value |= ~s_g_io_out_bits_uop_lqIdx_value;
        checks++;
        if (s_g_io_out_bits_uop_sqIdx_flag !== s_i_io_out_bits_uop_sqIdx_flag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_sqIdx_flag g=%h i=%h", cyc, s_g_io_out_bits_uop_sqIdx_flag, s_i_io_out_bits_uop_sqIdx_flag);
        end
        s_s1_io_out_bits_uop_sqIdx_flag |= s_g_io_out_bits_uop_sqIdx_flag;
        s_s0_io_out_bits_uop_sqIdx_flag |= ~s_g_io_out_bits_uop_sqIdx_flag;
        checks++;
        if (s_g_io_out_bits_uop_sqIdx_value !== s_i_io_out_bits_uop_sqIdx_value) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_sqIdx_value g=%h i=%h", cyc, s_g_io_out_bits_uop_sqIdx_value, s_i_io_out_bits_uop_sqIdx_value);
        end
        s_s1_io_out_bits_uop_sqIdx_value |= s_g_io_out_bits_uop_sqIdx_value;
        s_s0_io_out_bits_uop_sqIdx_value |= ~s_g_io_out_bits_uop_sqIdx_value;
        checks++;
        if (s_g_io_out_bits_uop_singleStep !== s_i_io_out_bits_uop_singleStep) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_singleStep g=%h i=%h", cyc, s_g_io_out_bits_uop_singleStep, s_i_io_out_bits_uop_singleStep);
        end
        s_s1_io_out_bits_uop_singleStep |= s_g_io_out_bits_uop_singleStep;
        s_s0_io_out_bits_uop_singleStep |= ~s_g_io_out_bits_uop_singleStep;
        checks++;
        if (s_g_io_out_bits_uop_replayInst !== s_i_io_out_bits_uop_replayInst) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_replayInst g=%h i=%h", cyc, s_g_io_out_bits_uop_replayInst, s_i_io_out_bits_uop_replayInst);
        end
        s_s1_io_out_bits_uop_replayInst |= s_g_io_out_bits_uop_replayInst;
        s_s0_io_out_bits_uop_replayInst |= ~s_g_io_out_bits_uop_replayInst;
        checks++;
        if (s_g_io_out_bits_uop_debug_fuType !== s_i_io_out_bits_uop_debug_fuType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_debug_fuType g=%h i=%h", cyc, s_g_io_out_bits_uop_debug_fuType, s_i_io_out_bits_uop_debug_fuType);
        end
        s_s1_io_out_bits_uop_debug_fuType |= s_g_io_out_bits_uop_debug_fuType;
        s_s0_io_out_bits_uop_debug_fuType |= ~s_g_io_out_bits_uop_debug_fuType;
        checks++;
        if (s_g_io_out_bits_uop_debug_sim_trig !== s_i_io_out_bits_uop_debug_sim_trig) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_debug_sim_trig g=%h i=%h", cyc, s_g_io_out_bits_uop_debug_sim_trig, s_i_io_out_bits_uop_debug_sim_trig);
        end
        s_s1_io_out_bits_uop_debug_sim_trig |= s_g_io_out_bits_uop_debug_sim_trig;
        s_s0_io_out_bits_uop_debug_sim_trig |= ~s_g_io_out_bits_uop_debug_sim_trig;
        checks++;
        if (s_g_io_out_bits_uop_numLsElem !== s_i_io_out_bits_uop_numLsElem) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_uop_numLsElem g=%h i=%h", cyc, s_g_io_out_bits_uop_numLsElem, s_i_io_out_bits_uop_numLsElem);
        end
        s_s1_io_out_bits_uop_numLsElem |= s_g_io_out_bits_uop_numLsElem;
        s_s0_io_out_bits_uop_numLsElem |= ~s_g_io_out_bits_uop_numLsElem;
        checks++;
        if (s_g_io_out_bits_preIsSplit !== s_i_io_out_bits_preIsSplit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_preIsSplit g=%h i=%h", cyc, s_g_io_out_bits_preIsSplit, s_i_io_out_bits_preIsSplit);
        end
        s_s1_io_out_bits_preIsSplit |= s_g_io_out_bits_preIsSplit;
        s_s0_io_out_bits_preIsSplit |= ~s_g_io_out_bits_preIsSplit;
        checks++;
        if (s_g_io_out_bits_mBIndex !== s_i_io_out_bits_mBIndex) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_mBIndex g=%h i=%h", cyc, s_g_io_out_bits_mBIndex, s_i_io_out_bits_mBIndex);
        end
        s_s1_io_out_bits_mBIndex |= s_g_io_out_bits_mBIndex;
        s_s0_io_out_bits_mBIndex |= ~s_g_io_out_bits_mBIndex;
        checks++;
        if (s_g_io_out_bits_alignedType !== s_i_io_out_bits_alignedType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_alignedType g=%h i=%h", cyc, s_g_io_out_bits_alignedType, s_i_io_out_bits_alignedType);
        end
        s_s1_io_out_bits_alignedType |= s_g_io_out_bits_alignedType;
        s_s0_io_out_bits_alignedType |= ~s_g_io_out_bits_alignedType;
        checks++;
        if (s_g_io_out_bits_indexVlMaxInVd !== s_i_io_out_bits_indexVlMaxInVd) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_indexVlMaxInVd g=%h i=%h", cyc, s_g_io_out_bits_indexVlMaxInVd, s_i_io_out_bits_indexVlMaxInVd);
        end
        s_s1_io_out_bits_indexVlMaxInVd |= s_g_io_out_bits_indexVlMaxInVd;
        s_s0_io_out_bits_indexVlMaxInVd |= ~s_g_io_out_bits_indexVlMaxInVd;
        checks++;
        if (s_g_io_out_bits_usLowBitsAddr !== s_i_io_out_bits_usLowBitsAddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_usLowBitsAddr g=%h i=%h", cyc, s_g_io_out_bits_usLowBitsAddr, s_i_io_out_bits_usLowBitsAddr);
        end
        s_s1_io_out_bits_usLowBitsAddr |= s_g_io_out_bits_usLowBitsAddr;
        s_s0_io_out_bits_usLowBitsAddr |= ~s_g_io_out_bits_usLowBitsAddr;
        checks++;
        if (s_g_io_out_bits_usAligned128 !== s_i_io_out_bits_usAligned128) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_usAligned128 g=%h i=%h", cyc, s_g_io_out_bits_usAligned128, s_i_io_out_bits_usAligned128);
        end
        s_s1_io_out_bits_usAligned128 |= s_g_io_out_bits_usAligned128;
        s_s0_io_out_bits_usAligned128 |= ~s_g_io_out_bits_usAligned128;
        checks++;
        if (s_g_io_out_bits_usMask !== s_i_io_out_bits_usMask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_usMask g=%h i=%h", cyc, s_g_io_out_bits_usMask, s_i_io_out_bits_usMask);
        end
        s_s1_io_out_bits_usMask |= s_g_io_out_bits_usMask;
        s_s0_io_out_bits_usMask |= ~s_g_io_out_bits_usMask;
        checks++;
        if (s_g_io_out_bits_isVecPartReplay !== s_i_io_out_bits_isVecPartReplay) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_isVecPartReplay g=%h i=%h", cyc, s_g_io_out_bits_isVecPartReplay, s_i_io_out_bits_isVecPartReplay);
        end
        s_s1_io_out_bits_isVecPartReplay |= s_g_io_out_bits_isVecPartReplay;
        s_s0_io_out_bits_isVecPartReplay |= ~s_g_io_out_bits_isVecPartReplay;
        checks++;
        if (s_g_io_out_bits_vecReplayFlowMask !== s_i_io_out_bits_vecReplayFlowMask) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d skidBufferConnect.io_out_bits_vecReplayFlowMask g=%h i=%h", cyc, s_g_io_out_bits_vecReplayFlowMask, s_i_io_out_bits_vecReplayFlowMask);
        end
        s_s1_io_out_bits_vecReplayFlowMask |= s_g_io_out_bits_vecReplayFlowMask;
        s_s0_io_out_bits_vecReplayFlowMask |= ~s_g_io_out_bits_vecReplayFlowMask;
        if (s_io_in_valid && s_g_io_in_ready && !s_io_out_ready) s_cov_capture++;
        if (!s_g_io_in_ready) s_cov_skid++;
        if (!s_g_io_in_ready && s_io_out_ready) s_cov_drain++;
        if (!s_g_io_in_ready && s_io_flush && !s_io_out_ready) s_cov_flush_skid++;
        if (s_io_in_valid && s_g_io_in_ready && !s_io_out_ready && s_io_flush) s_cov_flush_cap++;
        if (s_io_in_valid && s_g_io_in_ready && s_io_out_ready) s_cov_pass++;
      end
      if (s_armed_at < 0 && (&s_armed)) s_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(s_s0_io_in_ready && s_s1_io_in_ready)) begin cov_fail++; $display("[COV] skidBufferConnect.io_in_ready 未见过 0 和 1"); end
    if (!(s_s0_io_out_valid && s_s1_io_out_valid)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_valid 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_flowMask[0] && s_s1_io_out_bits_flowMask[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_flowMask[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_flowMask[1] && s_s1_io_out_bits_flowMask[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_flowMask[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_flowMask[2] && s_s1_io_out_bits_flowMask[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_flowMask[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_flowMask[3] && s_s1_io_out_bits_flowMask[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_flowMask[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_flowMask[4] && s_s1_io_out_bits_flowMask[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_flowMask[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_flowMask[5] && s_s1_io_out_bits_flowMask[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_flowMask[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_flowMask[6] && s_s1_io_out_bits_flowMask[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_flowMask[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_flowMask[7] && s_s1_io_out_bits_flowMask[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_flowMask[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_flowMask[8] && s_s1_io_out_bits_flowMask[8])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_flowMask[8] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_flowMask[9] && s_s1_io_out_bits_flowMask[9])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_flowMask[9] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_flowMask[10] && s_s1_io_out_bits_flowMask[10])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_flowMask[10] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_flowMask[11] && s_s1_io_out_bits_flowMask[11])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_flowMask[11] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_flowMask[12] && s_s1_io_out_bits_flowMask[12])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_flowMask[12] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_flowMask[13] && s_s1_io_out_bits_flowMask[13])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_flowMask[13] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_flowMask[14] && s_s1_io_out_bits_flowMask[14])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_flowMask[14] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_flowMask[15] && s_s1_io_out_bits_flowMask[15])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_flowMask[15] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[0] && s_s1_io_out_bits_data[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[1] && s_s1_io_out_bits_data[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[2] && s_s1_io_out_bits_data[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[3] && s_s1_io_out_bits_data[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[4] && s_s1_io_out_bits_data[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[5] && s_s1_io_out_bits_data[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[6] && s_s1_io_out_bits_data[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[7] && s_s1_io_out_bits_data[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[8] && s_s1_io_out_bits_data[8])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[8] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[9] && s_s1_io_out_bits_data[9])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[9] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[10] && s_s1_io_out_bits_data[10])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[10] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[11] && s_s1_io_out_bits_data[11])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[11] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[12] && s_s1_io_out_bits_data[12])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[12] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[13] && s_s1_io_out_bits_data[13])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[13] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[14] && s_s1_io_out_bits_data[14])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[14] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[15] && s_s1_io_out_bits_data[15])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[15] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[16] && s_s1_io_out_bits_data[16])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[16] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[17] && s_s1_io_out_bits_data[17])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[17] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[18] && s_s1_io_out_bits_data[18])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[18] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[19] && s_s1_io_out_bits_data[19])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[19] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[20] && s_s1_io_out_bits_data[20])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[20] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[21] && s_s1_io_out_bits_data[21])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[21] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[22] && s_s1_io_out_bits_data[22])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[22] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[23] && s_s1_io_out_bits_data[23])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[23] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[24] && s_s1_io_out_bits_data[24])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[24] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[25] && s_s1_io_out_bits_data[25])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[25] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[26] && s_s1_io_out_bits_data[26])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[26] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[27] && s_s1_io_out_bits_data[27])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[27] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[28] && s_s1_io_out_bits_data[28])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[28] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[29] && s_s1_io_out_bits_data[29])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[29] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[30] && s_s1_io_out_bits_data[30])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[30] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[31] && s_s1_io_out_bits_data[31])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[31] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[32] && s_s1_io_out_bits_data[32])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[32] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[33] && s_s1_io_out_bits_data[33])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[33] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[34] && s_s1_io_out_bits_data[34])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[34] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[35] && s_s1_io_out_bits_data[35])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[35] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[36] && s_s1_io_out_bits_data[36])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[36] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[37] && s_s1_io_out_bits_data[37])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[37] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[38] && s_s1_io_out_bits_data[38])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[38] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[39] && s_s1_io_out_bits_data[39])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[39] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[40] && s_s1_io_out_bits_data[40])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[40] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[41] && s_s1_io_out_bits_data[41])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[41] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[42] && s_s1_io_out_bits_data[42])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[42] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[43] && s_s1_io_out_bits_data[43])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[43] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[44] && s_s1_io_out_bits_data[44])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[44] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[45] && s_s1_io_out_bits_data[45])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[45] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[46] && s_s1_io_out_bits_data[46])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[46] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[47] && s_s1_io_out_bits_data[47])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[47] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[48] && s_s1_io_out_bits_data[48])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[48] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[49] && s_s1_io_out_bits_data[49])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[49] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[50] && s_s1_io_out_bits_data[50])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[50] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[51] && s_s1_io_out_bits_data[51])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[51] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[52] && s_s1_io_out_bits_data[52])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[52] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[53] && s_s1_io_out_bits_data[53])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[53] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[54] && s_s1_io_out_bits_data[54])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[54] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[55] && s_s1_io_out_bits_data[55])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[55] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[56] && s_s1_io_out_bits_data[56])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[56] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[57] && s_s1_io_out_bits_data[57])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[57] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[58] && s_s1_io_out_bits_data[58])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[58] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[59] && s_s1_io_out_bits_data[59])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[59] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[60] && s_s1_io_out_bits_data[60])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[60] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[61] && s_s1_io_out_bits_data[61])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[61] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[62] && s_s1_io_out_bits_data[62])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[62] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[63] && s_s1_io_out_bits_data[63])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[63] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[64] && s_s1_io_out_bits_data[64])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[64] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[65] && s_s1_io_out_bits_data[65])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[65] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[66] && s_s1_io_out_bits_data[66])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[66] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[67] && s_s1_io_out_bits_data[67])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[67] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[68] && s_s1_io_out_bits_data[68])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[68] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[69] && s_s1_io_out_bits_data[69])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[69] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[70] && s_s1_io_out_bits_data[70])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[70] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[71] && s_s1_io_out_bits_data[71])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[71] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[72] && s_s1_io_out_bits_data[72])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[72] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[73] && s_s1_io_out_bits_data[73])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[73] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[74] && s_s1_io_out_bits_data[74])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[74] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[75] && s_s1_io_out_bits_data[75])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[75] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[76] && s_s1_io_out_bits_data[76])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[76] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[77] && s_s1_io_out_bits_data[77])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[77] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[78] && s_s1_io_out_bits_data[78])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[78] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[79] && s_s1_io_out_bits_data[79])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[79] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[80] && s_s1_io_out_bits_data[80])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[80] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[81] && s_s1_io_out_bits_data[81])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[81] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[82] && s_s1_io_out_bits_data[82])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[82] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[83] && s_s1_io_out_bits_data[83])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[83] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[84] && s_s1_io_out_bits_data[84])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[84] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[85] && s_s1_io_out_bits_data[85])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[85] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[86] && s_s1_io_out_bits_data[86])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[86] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[87] && s_s1_io_out_bits_data[87])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[87] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[88] && s_s1_io_out_bits_data[88])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[88] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[89] && s_s1_io_out_bits_data[89])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[89] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[90] && s_s1_io_out_bits_data[90])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[90] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[91] && s_s1_io_out_bits_data[91])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[91] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[92] && s_s1_io_out_bits_data[92])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[92] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[93] && s_s1_io_out_bits_data[93])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[93] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[94] && s_s1_io_out_bits_data[94])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[94] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[95] && s_s1_io_out_bits_data[95])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[95] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[96] && s_s1_io_out_bits_data[96])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[96] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[97] && s_s1_io_out_bits_data[97])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[97] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[98] && s_s1_io_out_bits_data[98])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[98] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[99] && s_s1_io_out_bits_data[99])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[99] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[100] && s_s1_io_out_bits_data[100])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[100] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[101] && s_s1_io_out_bits_data[101])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[101] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[102] && s_s1_io_out_bits_data[102])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[102] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[103] && s_s1_io_out_bits_data[103])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[103] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[104] && s_s1_io_out_bits_data[104])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[104] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[105] && s_s1_io_out_bits_data[105])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[105] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[106] && s_s1_io_out_bits_data[106])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[106] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[107] && s_s1_io_out_bits_data[107])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[107] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[108] && s_s1_io_out_bits_data[108])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[108] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[109] && s_s1_io_out_bits_data[109])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[109] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[110] && s_s1_io_out_bits_data[110])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[110] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[111] && s_s1_io_out_bits_data[111])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[111] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[112] && s_s1_io_out_bits_data[112])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[112] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[113] && s_s1_io_out_bits_data[113])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[113] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[114] && s_s1_io_out_bits_data[114])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[114] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[115] && s_s1_io_out_bits_data[115])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[115] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[116] && s_s1_io_out_bits_data[116])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[116] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[117] && s_s1_io_out_bits_data[117])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[117] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[118] && s_s1_io_out_bits_data[118])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[118] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[119] && s_s1_io_out_bits_data[119])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[119] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[120] && s_s1_io_out_bits_data[120])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[120] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[121] && s_s1_io_out_bits_data[121])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[121] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[122] && s_s1_io_out_bits_data[122])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[122] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[123] && s_s1_io_out_bits_data[123])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[123] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[124] && s_s1_io_out_bits_data[124])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[124] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[125] && s_s1_io_out_bits_data[125])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[125] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[126] && s_s1_io_out_bits_data[126])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[126] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_data[127] && s_s1_io_out_bits_data[127])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_data[127] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[0] && s_s1_io_out_bits_baseAddr[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[1] && s_s1_io_out_bits_baseAddr[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[2] && s_s1_io_out_bits_baseAddr[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[3] && s_s1_io_out_bits_baseAddr[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[4] && s_s1_io_out_bits_baseAddr[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[5] && s_s1_io_out_bits_baseAddr[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[6] && s_s1_io_out_bits_baseAddr[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[7] && s_s1_io_out_bits_baseAddr[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[8] && s_s1_io_out_bits_baseAddr[8])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[8] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[9] && s_s1_io_out_bits_baseAddr[9])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[9] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[10] && s_s1_io_out_bits_baseAddr[10])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[10] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[11] && s_s1_io_out_bits_baseAddr[11])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[11] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[12] && s_s1_io_out_bits_baseAddr[12])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[12] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[13] && s_s1_io_out_bits_baseAddr[13])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[13] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[14] && s_s1_io_out_bits_baseAddr[14])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[14] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[15] && s_s1_io_out_bits_baseAddr[15])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[15] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[16] && s_s1_io_out_bits_baseAddr[16])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[16] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[17] && s_s1_io_out_bits_baseAddr[17])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[17] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[18] && s_s1_io_out_bits_baseAddr[18])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[18] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[19] && s_s1_io_out_bits_baseAddr[19])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[19] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[20] && s_s1_io_out_bits_baseAddr[20])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[20] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[21] && s_s1_io_out_bits_baseAddr[21])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[21] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[22] && s_s1_io_out_bits_baseAddr[22])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[22] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[23] && s_s1_io_out_bits_baseAddr[23])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[23] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[24] && s_s1_io_out_bits_baseAddr[24])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[24] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[25] && s_s1_io_out_bits_baseAddr[25])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[25] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[26] && s_s1_io_out_bits_baseAddr[26])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[26] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[27] && s_s1_io_out_bits_baseAddr[27])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[27] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[28] && s_s1_io_out_bits_baseAddr[28])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[28] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[29] && s_s1_io_out_bits_baseAddr[29])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[29] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[30] && s_s1_io_out_bits_baseAddr[30])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[30] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[31] && s_s1_io_out_bits_baseAddr[31])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[31] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[32] && s_s1_io_out_bits_baseAddr[32])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[32] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[33] && s_s1_io_out_bits_baseAddr[33])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[33] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[34] && s_s1_io_out_bits_baseAddr[34])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[34] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[35] && s_s1_io_out_bits_baseAddr[35])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[35] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[36] && s_s1_io_out_bits_baseAddr[36])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[36] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[37] && s_s1_io_out_bits_baseAddr[37])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[37] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[38] && s_s1_io_out_bits_baseAddr[38])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[38] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[39] && s_s1_io_out_bits_baseAddr[39])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[39] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[40] && s_s1_io_out_bits_baseAddr[40])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[40] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[41] && s_s1_io_out_bits_baseAddr[41])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[41] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[42] && s_s1_io_out_bits_baseAddr[42])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[42] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[43] && s_s1_io_out_bits_baseAddr[43])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[43] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[44] && s_s1_io_out_bits_baseAddr[44])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[44] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[45] && s_s1_io_out_bits_baseAddr[45])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[45] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[46] && s_s1_io_out_bits_baseAddr[46])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[46] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[47] && s_s1_io_out_bits_baseAddr[47])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[47] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[48] && s_s1_io_out_bits_baseAddr[48])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[48] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[49] && s_s1_io_out_bits_baseAddr[49])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[49] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[50] && s_s1_io_out_bits_baseAddr[50])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[50] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[51] && s_s1_io_out_bits_baseAddr[51])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[51] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[52] && s_s1_io_out_bits_baseAddr[52])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[52] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[53] && s_s1_io_out_bits_baseAddr[53])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[53] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[54] && s_s1_io_out_bits_baseAddr[54])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[54] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[55] && s_s1_io_out_bits_baseAddr[55])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[55] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[56] && s_s1_io_out_bits_baseAddr[56])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[56] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[57] && s_s1_io_out_bits_baseAddr[57])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[57] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[58] && s_s1_io_out_bits_baseAddr[58])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[58] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[59] && s_s1_io_out_bits_baseAddr[59])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[59] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[60] && s_s1_io_out_bits_baseAddr[60])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[60] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[61] && s_s1_io_out_bits_baseAddr[61])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[61] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[62] && s_s1_io_out_bits_baseAddr[62])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[62] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_baseAddr[63] && s_s1_io_out_bits_baseAddr[63])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_baseAddr[63] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[0] && s_s1_io_out_bits_uopAddr[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[1] && s_s1_io_out_bits_uopAddr[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[2] && s_s1_io_out_bits_uopAddr[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[3] && s_s1_io_out_bits_uopAddr[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[4] && s_s1_io_out_bits_uopAddr[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[5] && s_s1_io_out_bits_uopAddr[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[6] && s_s1_io_out_bits_uopAddr[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[7] && s_s1_io_out_bits_uopAddr[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[8] && s_s1_io_out_bits_uopAddr[8])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[8] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[9] && s_s1_io_out_bits_uopAddr[9])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[9] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[10] && s_s1_io_out_bits_uopAddr[10])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[10] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[11] && s_s1_io_out_bits_uopAddr[11])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[11] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[12] && s_s1_io_out_bits_uopAddr[12])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[12] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[13] && s_s1_io_out_bits_uopAddr[13])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[13] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[14] && s_s1_io_out_bits_uopAddr[14])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[14] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[15] && s_s1_io_out_bits_uopAddr[15])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[15] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[16] && s_s1_io_out_bits_uopAddr[16])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[16] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[17] && s_s1_io_out_bits_uopAddr[17])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[17] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[18] && s_s1_io_out_bits_uopAddr[18])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[18] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[19] && s_s1_io_out_bits_uopAddr[19])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[19] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[20] && s_s1_io_out_bits_uopAddr[20])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[20] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[21] && s_s1_io_out_bits_uopAddr[21])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[21] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[22] && s_s1_io_out_bits_uopAddr[22])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[22] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[23] && s_s1_io_out_bits_uopAddr[23])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[23] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[24] && s_s1_io_out_bits_uopAddr[24])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[24] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[25] && s_s1_io_out_bits_uopAddr[25])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[25] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[26] && s_s1_io_out_bits_uopAddr[26])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[26] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[27] && s_s1_io_out_bits_uopAddr[27])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[27] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[28] && s_s1_io_out_bits_uopAddr[28])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[28] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[29] && s_s1_io_out_bits_uopAddr[29])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[29] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[30] && s_s1_io_out_bits_uopAddr[30])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[30] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[31] && s_s1_io_out_bits_uopAddr[31])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[31] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[32] && s_s1_io_out_bits_uopAddr[32])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[32] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[33] && s_s1_io_out_bits_uopAddr[33])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[33] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[34] && s_s1_io_out_bits_uopAddr[34])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[34] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[35] && s_s1_io_out_bits_uopAddr[35])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[35] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[36] && s_s1_io_out_bits_uopAddr[36])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[36] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[37] && s_s1_io_out_bits_uopAddr[37])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[37] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[38] && s_s1_io_out_bits_uopAddr[38])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[38] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[39] && s_s1_io_out_bits_uopAddr[39])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[39] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[40] && s_s1_io_out_bits_uopAddr[40])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[40] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[41] && s_s1_io_out_bits_uopAddr[41])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[41] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[42] && s_s1_io_out_bits_uopAddr[42])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[42] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[43] && s_s1_io_out_bits_uopAddr[43])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[43] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[44] && s_s1_io_out_bits_uopAddr[44])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[44] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[45] && s_s1_io_out_bits_uopAddr[45])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[45] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[46] && s_s1_io_out_bits_uopAddr[46])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[46] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[47] && s_s1_io_out_bits_uopAddr[47])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[47] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[48] && s_s1_io_out_bits_uopAddr[48])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[48] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[49] && s_s1_io_out_bits_uopAddr[49])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[49] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[50] && s_s1_io_out_bits_uopAddr[50])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[50] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[51] && s_s1_io_out_bits_uopAddr[51])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[51] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[52] && s_s1_io_out_bits_uopAddr[52])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[52] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[53] && s_s1_io_out_bits_uopAddr[53])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[53] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[54] && s_s1_io_out_bits_uopAddr[54])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[54] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[55] && s_s1_io_out_bits_uopAddr[55])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[55] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[56] && s_s1_io_out_bits_uopAddr[56])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[56] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[57] && s_s1_io_out_bits_uopAddr[57])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[57] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[58] && s_s1_io_out_bits_uopAddr[58])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[58] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[59] && s_s1_io_out_bits_uopAddr[59])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[59] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[60] && s_s1_io_out_bits_uopAddr[60])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[60] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[61] && s_s1_io_out_bits_uopAddr[61])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[61] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[62] && s_s1_io_out_bits_uopAddr[62])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[62] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uopAddr[63] && s_s1_io_out_bits_uopAddr[63])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uopAddr[63] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[0] && s_s1_io_out_bits_stride[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[1] && s_s1_io_out_bits_stride[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[2] && s_s1_io_out_bits_stride[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[3] && s_s1_io_out_bits_stride[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[4] && s_s1_io_out_bits_stride[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[5] && s_s1_io_out_bits_stride[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[6] && s_s1_io_out_bits_stride[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[7] && s_s1_io_out_bits_stride[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[8] && s_s1_io_out_bits_stride[8])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[8] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[9] && s_s1_io_out_bits_stride[9])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[9] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[10] && s_s1_io_out_bits_stride[10])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[10] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[11] && s_s1_io_out_bits_stride[11])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[11] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[12] && s_s1_io_out_bits_stride[12])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[12] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[13] && s_s1_io_out_bits_stride[13])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[13] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[14] && s_s1_io_out_bits_stride[14])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[14] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[15] && s_s1_io_out_bits_stride[15])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[15] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[16] && s_s1_io_out_bits_stride[16])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[16] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[17] && s_s1_io_out_bits_stride[17])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[17] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[18] && s_s1_io_out_bits_stride[18])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[18] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[19] && s_s1_io_out_bits_stride[19])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[19] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[20] && s_s1_io_out_bits_stride[20])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[20] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[21] && s_s1_io_out_bits_stride[21])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[21] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[22] && s_s1_io_out_bits_stride[22])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[22] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[23] && s_s1_io_out_bits_stride[23])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[23] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[24] && s_s1_io_out_bits_stride[24])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[24] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[25] && s_s1_io_out_bits_stride[25])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[25] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[26] && s_s1_io_out_bits_stride[26])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[26] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[27] && s_s1_io_out_bits_stride[27])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[27] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[28] && s_s1_io_out_bits_stride[28])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[28] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[29] && s_s1_io_out_bits_stride[29])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[29] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[30] && s_s1_io_out_bits_stride[30])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[30] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[31] && s_s1_io_out_bits_stride[31])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[31] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[32] && s_s1_io_out_bits_stride[32])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[32] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[33] && s_s1_io_out_bits_stride[33])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[33] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[34] && s_s1_io_out_bits_stride[34])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[34] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[35] && s_s1_io_out_bits_stride[35])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[35] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[36] && s_s1_io_out_bits_stride[36])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[36] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[37] && s_s1_io_out_bits_stride[37])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[37] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[38] && s_s1_io_out_bits_stride[38])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[38] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[39] && s_s1_io_out_bits_stride[39])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[39] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[40] && s_s1_io_out_bits_stride[40])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[40] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[41] && s_s1_io_out_bits_stride[41])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[41] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[42] && s_s1_io_out_bits_stride[42])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[42] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[43] && s_s1_io_out_bits_stride[43])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[43] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[44] && s_s1_io_out_bits_stride[44])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[44] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[45] && s_s1_io_out_bits_stride[45])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[45] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[46] && s_s1_io_out_bits_stride[46])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[46] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[47] && s_s1_io_out_bits_stride[47])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[47] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[48] && s_s1_io_out_bits_stride[48])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[48] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[49] && s_s1_io_out_bits_stride[49])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[49] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[50] && s_s1_io_out_bits_stride[50])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[50] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[51] && s_s1_io_out_bits_stride[51])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[51] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[52] && s_s1_io_out_bits_stride[52])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[52] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[53] && s_s1_io_out_bits_stride[53])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[53] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[54] && s_s1_io_out_bits_stride[54])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[54] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[55] && s_s1_io_out_bits_stride[55])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[55] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[56] && s_s1_io_out_bits_stride[56])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[56] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[57] && s_s1_io_out_bits_stride[57])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[57] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[58] && s_s1_io_out_bits_stride[58])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[58] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[59] && s_s1_io_out_bits_stride[59])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[59] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[60] && s_s1_io_out_bits_stride[60])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[60] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[61] && s_s1_io_out_bits_stride[61])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[61] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[62] && s_s1_io_out_bits_stride[62])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[62] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[63] && s_s1_io_out_bits_stride[63])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[63] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[64] && s_s1_io_out_bits_stride[64])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[64] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[65] && s_s1_io_out_bits_stride[65])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[65] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[66] && s_s1_io_out_bits_stride[66])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[66] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[67] && s_s1_io_out_bits_stride[67])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[67] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[68] && s_s1_io_out_bits_stride[68])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[68] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[69] && s_s1_io_out_bits_stride[69])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[69] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[70] && s_s1_io_out_bits_stride[70])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[70] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[71] && s_s1_io_out_bits_stride[71])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[71] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[72] && s_s1_io_out_bits_stride[72])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[72] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[73] && s_s1_io_out_bits_stride[73])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[73] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[74] && s_s1_io_out_bits_stride[74])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[74] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[75] && s_s1_io_out_bits_stride[75])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[75] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[76] && s_s1_io_out_bits_stride[76])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[76] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[77] && s_s1_io_out_bits_stride[77])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[77] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[78] && s_s1_io_out_bits_stride[78])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[78] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[79] && s_s1_io_out_bits_stride[79])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[79] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[80] && s_s1_io_out_bits_stride[80])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[80] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[81] && s_s1_io_out_bits_stride[81])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[81] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[82] && s_s1_io_out_bits_stride[82])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[82] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[83] && s_s1_io_out_bits_stride[83])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[83] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[84] && s_s1_io_out_bits_stride[84])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[84] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[85] && s_s1_io_out_bits_stride[85])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[85] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[86] && s_s1_io_out_bits_stride[86])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[86] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[87] && s_s1_io_out_bits_stride[87])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[87] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[88] && s_s1_io_out_bits_stride[88])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[88] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[89] && s_s1_io_out_bits_stride[89])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[89] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[90] && s_s1_io_out_bits_stride[90])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[90] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[91] && s_s1_io_out_bits_stride[91])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[91] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[92] && s_s1_io_out_bits_stride[92])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[92] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[93] && s_s1_io_out_bits_stride[93])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[93] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[94] && s_s1_io_out_bits_stride[94])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[94] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[95] && s_s1_io_out_bits_stride[95])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[95] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[96] && s_s1_io_out_bits_stride[96])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[96] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[97] && s_s1_io_out_bits_stride[97])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[97] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[98] && s_s1_io_out_bits_stride[98])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[98] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[99] && s_s1_io_out_bits_stride[99])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[99] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[100] && s_s1_io_out_bits_stride[100])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[100] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[101] && s_s1_io_out_bits_stride[101])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[101] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[102] && s_s1_io_out_bits_stride[102])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[102] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[103] && s_s1_io_out_bits_stride[103])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[103] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[104] && s_s1_io_out_bits_stride[104])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[104] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[105] && s_s1_io_out_bits_stride[105])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[105] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[106] && s_s1_io_out_bits_stride[106])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[106] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[107] && s_s1_io_out_bits_stride[107])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[107] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[108] && s_s1_io_out_bits_stride[108])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[108] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[109] && s_s1_io_out_bits_stride[109])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[109] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[110] && s_s1_io_out_bits_stride[110])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[110] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[111] && s_s1_io_out_bits_stride[111])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[111] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[112] && s_s1_io_out_bits_stride[112])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[112] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[113] && s_s1_io_out_bits_stride[113])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[113] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[114] && s_s1_io_out_bits_stride[114])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[114] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[115] && s_s1_io_out_bits_stride[115])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[115] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[116] && s_s1_io_out_bits_stride[116])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[116] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[117] && s_s1_io_out_bits_stride[117])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[117] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[118] && s_s1_io_out_bits_stride[118])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[118] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[119] && s_s1_io_out_bits_stride[119])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[119] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[120] && s_s1_io_out_bits_stride[120])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[120] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[121] && s_s1_io_out_bits_stride[121])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[121] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[122] && s_s1_io_out_bits_stride[122])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[122] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[123] && s_s1_io_out_bits_stride[123])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[123] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[124] && s_s1_io_out_bits_stride[124])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[124] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[125] && s_s1_io_out_bits_stride[125])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[125] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[126] && s_s1_io_out_bits_stride[126])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[126] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_stride[127] && s_s1_io_out_bits_stride[127])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_stride[127] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_flowNum[0] && s_s1_io_out_bits_flowNum[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_flowNum[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_flowNum[1] && s_s1_io_out_bits_flowNum[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_flowNum[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_flowNum[2] && s_s1_io_out_bits_flowNum[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_flowNum[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_flowNum[3] && s_s1_io_out_bits_flowNum[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_flowNum[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_flowNum[4] && s_s1_io_out_bits_flowNum[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_flowNum[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_eew[0] && s_s1_io_out_bits_eew[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_eew[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_eew[1] && s_s1_io_out_bits_eew[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_eew[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_sew[0] && s_s1_io_out_bits_sew[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_sew[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_sew[1] && s_s1_io_out_bits_sew[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_sew[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_sew[2] && s_s1_io_out_bits_sew[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_sew[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_emul[0] && s_s1_io_out_bits_emul[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_emul[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_emul[1] && s_s1_io_out_bits_emul[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_emul[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_emul[2] && s_s1_io_out_bits_emul[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_emul[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_lmul[0] && s_s1_io_out_bits_lmul[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_lmul[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_lmul[1] && s_s1_io_out_bits_lmul[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_lmul[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_lmul[2] && s_s1_io_out_bits_lmul[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_lmul[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_instType[0] && s_s1_io_out_bits_instType[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_instType[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_instType[1] && s_s1_io_out_bits_instType[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_instType[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_instType[2] && s_s1_io_out_bits_instType[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_instType[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_indexedSplitOffset[0] && s_s1_io_out_bits_indexedSplitOffset[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_indexedSplitOffset[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_indexedSplitOffset[1] && s_s1_io_out_bits_indexedSplitOffset[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_indexedSplitOffset[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_indexedSplitOffset[2] && s_s1_io_out_bits_indexedSplitOffset[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_indexedSplitOffset[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_indexedSplitOffset[3] && s_s1_io_out_bits_indexedSplitOffset[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_indexedSplitOffset[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_indexedSplitOffset[4] && s_s1_io_out_bits_indexedSplitOffset[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_indexedSplitOffset[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[0] && s_s1_io_out_bits_uop_pc[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[1] && s_s1_io_out_bits_uop_pc[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[2] && s_s1_io_out_bits_uop_pc[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[3] && s_s1_io_out_bits_uop_pc[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[4] && s_s1_io_out_bits_uop_pc[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[5] && s_s1_io_out_bits_uop_pc[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[6] && s_s1_io_out_bits_uop_pc[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[7] && s_s1_io_out_bits_uop_pc[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[8] && s_s1_io_out_bits_uop_pc[8])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[8] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[9] && s_s1_io_out_bits_uop_pc[9])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[9] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[10] && s_s1_io_out_bits_uop_pc[10])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[10] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[11] && s_s1_io_out_bits_uop_pc[11])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[11] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[12] && s_s1_io_out_bits_uop_pc[12])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[12] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[13] && s_s1_io_out_bits_uop_pc[13])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[13] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[14] && s_s1_io_out_bits_uop_pc[14])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[14] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[15] && s_s1_io_out_bits_uop_pc[15])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[15] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[16] && s_s1_io_out_bits_uop_pc[16])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[16] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[17] && s_s1_io_out_bits_uop_pc[17])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[17] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[18] && s_s1_io_out_bits_uop_pc[18])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[18] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[19] && s_s1_io_out_bits_uop_pc[19])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[19] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[20] && s_s1_io_out_bits_uop_pc[20])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[20] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[21] && s_s1_io_out_bits_uop_pc[21])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[21] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[22] && s_s1_io_out_bits_uop_pc[22])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[22] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[23] && s_s1_io_out_bits_uop_pc[23])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[23] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[24] && s_s1_io_out_bits_uop_pc[24])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[24] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[25] && s_s1_io_out_bits_uop_pc[25])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[25] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[26] && s_s1_io_out_bits_uop_pc[26])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[26] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[27] && s_s1_io_out_bits_uop_pc[27])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[27] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[28] && s_s1_io_out_bits_uop_pc[28])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[28] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[29] && s_s1_io_out_bits_uop_pc[29])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[29] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[30] && s_s1_io_out_bits_uop_pc[30])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[30] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[31] && s_s1_io_out_bits_uop_pc[31])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[31] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[32] && s_s1_io_out_bits_uop_pc[32])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[32] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[33] && s_s1_io_out_bits_uop_pc[33])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[33] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[34] && s_s1_io_out_bits_uop_pc[34])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[34] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[35] && s_s1_io_out_bits_uop_pc[35])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[35] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[36] && s_s1_io_out_bits_uop_pc[36])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[36] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[37] && s_s1_io_out_bits_uop_pc[37])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[37] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[38] && s_s1_io_out_bits_uop_pc[38])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[38] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[39] && s_s1_io_out_bits_uop_pc[39])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[39] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[40] && s_s1_io_out_bits_uop_pc[40])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[40] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[41] && s_s1_io_out_bits_uop_pc[41])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[41] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[42] && s_s1_io_out_bits_uop_pc[42])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[42] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[43] && s_s1_io_out_bits_uop_pc[43])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[43] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[44] && s_s1_io_out_bits_uop_pc[44])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[44] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[45] && s_s1_io_out_bits_uop_pc[45])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[45] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[46] && s_s1_io_out_bits_uop_pc[46])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[46] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[47] && s_s1_io_out_bits_uop_pc[47])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[47] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[48] && s_s1_io_out_bits_uop_pc[48])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[48] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pc[49] && s_s1_io_out_bits_uop_pc[49])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pc[49] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_ftqPtr_flag && s_s1_io_out_bits_uop_ftqPtr_flag)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_ftqPtr_flag 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_ftqPtr_value[0] && s_s1_io_out_bits_uop_ftqPtr_value[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_ftqPtr_value[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_ftqPtr_value[1] && s_s1_io_out_bits_uop_ftqPtr_value[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_ftqPtr_value[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_ftqPtr_value[2] && s_s1_io_out_bits_uop_ftqPtr_value[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_ftqPtr_value[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_ftqPtr_value[3] && s_s1_io_out_bits_uop_ftqPtr_value[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_ftqPtr_value[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_ftqPtr_value[4] && s_s1_io_out_bits_uop_ftqPtr_value[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_ftqPtr_value[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_ftqPtr_value[5] && s_s1_io_out_bits_uop_ftqPtr_value[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_ftqPtr_value[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_ftqOffset[0] && s_s1_io_out_bits_uop_ftqOffset[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_ftqOffset[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_ftqOffset[1] && s_s1_io_out_bits_uop_ftqOffset[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_ftqOffset[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_ftqOffset[2] && s_s1_io_out_bits_uop_ftqOffset[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_ftqOffset[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_ftqOffset[3] && s_s1_io_out_bits_uop_ftqOffset[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_ftqOffset[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[0] && s_s1_io_out_bits_uop_fuType[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[1] && s_s1_io_out_bits_uop_fuType[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[2] && s_s1_io_out_bits_uop_fuType[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[3] && s_s1_io_out_bits_uop_fuType[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[4] && s_s1_io_out_bits_uop_fuType[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[5] && s_s1_io_out_bits_uop_fuType[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[6] && s_s1_io_out_bits_uop_fuType[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[7] && s_s1_io_out_bits_uop_fuType[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[8] && s_s1_io_out_bits_uop_fuType[8])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[8] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[9] && s_s1_io_out_bits_uop_fuType[9])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[9] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[10] && s_s1_io_out_bits_uop_fuType[10])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[10] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[11] && s_s1_io_out_bits_uop_fuType[11])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[11] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[12] && s_s1_io_out_bits_uop_fuType[12])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[12] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[13] && s_s1_io_out_bits_uop_fuType[13])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[13] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[14] && s_s1_io_out_bits_uop_fuType[14])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[14] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[15] && s_s1_io_out_bits_uop_fuType[15])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[15] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[16] && s_s1_io_out_bits_uop_fuType[16])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[16] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[17] && s_s1_io_out_bits_uop_fuType[17])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[17] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[18] && s_s1_io_out_bits_uop_fuType[18])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[18] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[19] && s_s1_io_out_bits_uop_fuType[19])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[19] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[20] && s_s1_io_out_bits_uop_fuType[20])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[20] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[21] && s_s1_io_out_bits_uop_fuType[21])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[21] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[22] && s_s1_io_out_bits_uop_fuType[22])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[22] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[23] && s_s1_io_out_bits_uop_fuType[23])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[23] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[24] && s_s1_io_out_bits_uop_fuType[24])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[24] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[25] && s_s1_io_out_bits_uop_fuType[25])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[25] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[26] && s_s1_io_out_bits_uop_fuType[26])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[26] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[27] && s_s1_io_out_bits_uop_fuType[27])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[27] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[28] && s_s1_io_out_bits_uop_fuType[28])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[28] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[29] && s_s1_io_out_bits_uop_fuType[29])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[29] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[30] && s_s1_io_out_bits_uop_fuType[30])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[30] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[31] && s_s1_io_out_bits_uop_fuType[31])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[31] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[32] && s_s1_io_out_bits_uop_fuType[32])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[32] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[33] && s_s1_io_out_bits_uop_fuType[33])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[33] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuType[34] && s_s1_io_out_bits_uop_fuType[34])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuType[34] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuOpType[0] && s_s1_io_out_bits_uop_fuOpType[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuOpType[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuOpType[1] && s_s1_io_out_bits_uop_fuOpType[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuOpType[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuOpType[2] && s_s1_io_out_bits_uop_fuOpType[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuOpType[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuOpType[3] && s_s1_io_out_bits_uop_fuOpType[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuOpType[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuOpType[4] && s_s1_io_out_bits_uop_fuOpType[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuOpType[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuOpType[5] && s_s1_io_out_bits_uop_fuOpType[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuOpType[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuOpType[6] && s_s1_io_out_bits_uop_fuOpType[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuOpType[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuOpType[7] && s_s1_io_out_bits_uop_fuOpType[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuOpType[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_fuOpType[8] && s_s1_io_out_bits_uop_fuOpType[8])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_fuOpType[8] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vecWen && s_s1_io_out_bits_uop_vecWen)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vecWen 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_v0Wen && s_s1_io_out_bits_uop_v0Wen)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_v0Wen 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vlWen && s_s1_io_out_bits_uop_vlWen)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vlWen 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vill && s_s1_io_out_bits_uop_vpu_vill)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vill 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vma && s_s1_io_out_bits_uop_vpu_vma)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vma 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vta && s_s1_io_out_bits_uop_vpu_vta)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vta 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vsew[0] && s_s1_io_out_bits_uop_vpu_vsew[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vsew[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vsew[1] && s_s1_io_out_bits_uop_vpu_vsew[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vsew[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vlmul[0] && s_s1_io_out_bits_uop_vpu_vlmul[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vlmul[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vlmul[1] && s_s1_io_out_bits_uop_vpu_vlmul[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vlmul[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vlmul[2] && s_s1_io_out_bits_uop_vpu_vlmul[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vlmul[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_specVill && s_s1_io_out_bits_uop_vpu_specVill)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_specVill 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_specVma && s_s1_io_out_bits_uop_vpu_specVma)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_specVma 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_specVta && s_s1_io_out_bits_uop_vpu_specVta)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_specVta 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_specVsew[0] && s_s1_io_out_bits_uop_vpu_specVsew[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_specVsew[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_specVsew[1] && s_s1_io_out_bits_uop_vpu_specVsew[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_specVsew[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_specVlmul[0] && s_s1_io_out_bits_uop_vpu_specVlmul[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_specVlmul[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_specVlmul[1] && s_s1_io_out_bits_uop_vpu_specVlmul[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_specVlmul[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_specVlmul[2] && s_s1_io_out_bits_uop_vpu_specVlmul[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_specVlmul[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vm && s_s1_io_out_bits_uop_vpu_vm)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vm 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vstart[0] && s_s1_io_out_bits_uop_vpu_vstart[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vstart[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vstart[1] && s_s1_io_out_bits_uop_vpu_vstart[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vstart[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vstart[2] && s_s1_io_out_bits_uop_vpu_vstart[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vstart[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vstart[3] && s_s1_io_out_bits_uop_vpu_vstart[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vstart[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vstart[4] && s_s1_io_out_bits_uop_vpu_vstart[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vstart[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vstart[5] && s_s1_io_out_bits_uop_vpu_vstart[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vstart[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vstart[6] && s_s1_io_out_bits_uop_vpu_vstart[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vstart[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vstart[7] && s_s1_io_out_bits_uop_vpu_vstart[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vstart[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_frm[0] && s_s1_io_out_bits_uop_vpu_frm[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_frm[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_frm[1] && s_s1_io_out_bits_uop_vpu_frm[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_frm[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_frm[2] && s_s1_io_out_bits_uop_vpu_frm[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_frm[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_fpu_isFpToVecInst && s_s1_io_out_bits_uop_vpu_fpu_isFpToVecInst)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_fpu_isFpToVecInst 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_fpu_isFP32Instr && s_s1_io_out_bits_uop_vpu_fpu_isFP32Instr)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_fpu_isFP32Instr 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_fpu_isFP64Instr && s_s1_io_out_bits_uop_vpu_fpu_isFP64Instr)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_fpu_isFP64Instr 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_fpu_isReduction && s_s1_io_out_bits_uop_vpu_fpu_isReduction)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_fpu_isReduction 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_fpu_isFoldTo1_2 && s_s1_io_out_bits_uop_vpu_fpu_isFoldTo1_2)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_fpu_isFoldTo1_2 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_fpu_isFoldTo1_4 && s_s1_io_out_bits_uop_vpu_fpu_isFoldTo1_4)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_fpu_isFoldTo1_4 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_fpu_isFoldTo1_8 && s_s1_io_out_bits_uop_vpu_fpu_isFoldTo1_8)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_fpu_isFoldTo1_8 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vxrm[0] && s_s1_io_out_bits_uop_vpu_vxrm[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vxrm[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vxrm[1] && s_s1_io_out_bits_uop_vpu_vxrm[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vxrm[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vuopIdx[0] && s_s1_io_out_bits_uop_vpu_vuopIdx[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vuopIdx[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vuopIdx[1] && s_s1_io_out_bits_uop_vpu_vuopIdx[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vuopIdx[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vuopIdx[2] && s_s1_io_out_bits_uop_vpu_vuopIdx[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vuopIdx[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vuopIdx[3] && s_s1_io_out_bits_uop_vpu_vuopIdx[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vuopIdx[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vuopIdx[4] && s_s1_io_out_bits_uop_vpu_vuopIdx[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vuopIdx[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vuopIdx[5] && s_s1_io_out_bits_uop_vpu_vuopIdx[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vuopIdx[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vuopIdx[6] && s_s1_io_out_bits_uop_vpu_vuopIdx[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vuopIdx[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_lastUop && s_s1_io_out_bits_uop_vpu_lastUop)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_lastUop 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[0] && s_s1_io_out_bits_uop_vpu_vmask[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[1] && s_s1_io_out_bits_uop_vpu_vmask[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[2] && s_s1_io_out_bits_uop_vpu_vmask[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[3] && s_s1_io_out_bits_uop_vpu_vmask[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[4] && s_s1_io_out_bits_uop_vpu_vmask[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[5] && s_s1_io_out_bits_uop_vpu_vmask[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[6] && s_s1_io_out_bits_uop_vpu_vmask[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[7] && s_s1_io_out_bits_uop_vpu_vmask[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[8] && s_s1_io_out_bits_uop_vpu_vmask[8])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[8] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[9] && s_s1_io_out_bits_uop_vpu_vmask[9])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[9] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[10] && s_s1_io_out_bits_uop_vpu_vmask[10])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[10] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[11] && s_s1_io_out_bits_uop_vpu_vmask[11])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[11] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[12] && s_s1_io_out_bits_uop_vpu_vmask[12])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[12] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[13] && s_s1_io_out_bits_uop_vpu_vmask[13])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[13] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[14] && s_s1_io_out_bits_uop_vpu_vmask[14])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[14] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[15] && s_s1_io_out_bits_uop_vpu_vmask[15])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[15] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[16] && s_s1_io_out_bits_uop_vpu_vmask[16])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[16] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[17] && s_s1_io_out_bits_uop_vpu_vmask[17])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[17] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[18] && s_s1_io_out_bits_uop_vpu_vmask[18])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[18] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[19] && s_s1_io_out_bits_uop_vpu_vmask[19])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[19] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[20] && s_s1_io_out_bits_uop_vpu_vmask[20])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[20] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[21] && s_s1_io_out_bits_uop_vpu_vmask[21])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[21] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[22] && s_s1_io_out_bits_uop_vpu_vmask[22])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[22] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[23] && s_s1_io_out_bits_uop_vpu_vmask[23])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[23] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[24] && s_s1_io_out_bits_uop_vpu_vmask[24])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[24] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[25] && s_s1_io_out_bits_uop_vpu_vmask[25])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[25] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[26] && s_s1_io_out_bits_uop_vpu_vmask[26])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[26] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[27] && s_s1_io_out_bits_uop_vpu_vmask[27])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[27] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[28] && s_s1_io_out_bits_uop_vpu_vmask[28])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[28] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[29] && s_s1_io_out_bits_uop_vpu_vmask[29])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[29] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[30] && s_s1_io_out_bits_uop_vpu_vmask[30])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[30] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[31] && s_s1_io_out_bits_uop_vpu_vmask[31])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[31] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[32] && s_s1_io_out_bits_uop_vpu_vmask[32])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[32] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[33] && s_s1_io_out_bits_uop_vpu_vmask[33])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[33] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[34] && s_s1_io_out_bits_uop_vpu_vmask[34])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[34] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[35] && s_s1_io_out_bits_uop_vpu_vmask[35])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[35] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[36] && s_s1_io_out_bits_uop_vpu_vmask[36])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[36] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[37] && s_s1_io_out_bits_uop_vpu_vmask[37])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[37] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[38] && s_s1_io_out_bits_uop_vpu_vmask[38])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[38] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[39] && s_s1_io_out_bits_uop_vpu_vmask[39])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[39] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[40] && s_s1_io_out_bits_uop_vpu_vmask[40])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[40] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[41] && s_s1_io_out_bits_uop_vpu_vmask[41])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[41] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[42] && s_s1_io_out_bits_uop_vpu_vmask[42])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[42] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[43] && s_s1_io_out_bits_uop_vpu_vmask[43])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[43] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[44] && s_s1_io_out_bits_uop_vpu_vmask[44])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[44] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[45] && s_s1_io_out_bits_uop_vpu_vmask[45])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[45] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[46] && s_s1_io_out_bits_uop_vpu_vmask[46])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[46] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[47] && s_s1_io_out_bits_uop_vpu_vmask[47])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[47] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[48] && s_s1_io_out_bits_uop_vpu_vmask[48])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[48] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[49] && s_s1_io_out_bits_uop_vpu_vmask[49])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[49] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[50] && s_s1_io_out_bits_uop_vpu_vmask[50])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[50] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[51] && s_s1_io_out_bits_uop_vpu_vmask[51])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[51] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[52] && s_s1_io_out_bits_uop_vpu_vmask[52])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[52] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[53] && s_s1_io_out_bits_uop_vpu_vmask[53])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[53] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[54] && s_s1_io_out_bits_uop_vpu_vmask[54])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[54] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[55] && s_s1_io_out_bits_uop_vpu_vmask[55])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[55] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[56] && s_s1_io_out_bits_uop_vpu_vmask[56])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[56] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[57] && s_s1_io_out_bits_uop_vpu_vmask[57])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[57] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[58] && s_s1_io_out_bits_uop_vpu_vmask[58])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[58] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[59] && s_s1_io_out_bits_uop_vpu_vmask[59])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[59] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[60] && s_s1_io_out_bits_uop_vpu_vmask[60])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[60] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[61] && s_s1_io_out_bits_uop_vpu_vmask[61])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[61] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[62] && s_s1_io_out_bits_uop_vpu_vmask[62])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[62] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[63] && s_s1_io_out_bits_uop_vpu_vmask[63])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[63] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[64] && s_s1_io_out_bits_uop_vpu_vmask[64])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[64] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[65] && s_s1_io_out_bits_uop_vpu_vmask[65])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[65] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[66] && s_s1_io_out_bits_uop_vpu_vmask[66])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[66] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[67] && s_s1_io_out_bits_uop_vpu_vmask[67])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[67] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[68] && s_s1_io_out_bits_uop_vpu_vmask[68])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[68] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[69] && s_s1_io_out_bits_uop_vpu_vmask[69])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[69] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[70] && s_s1_io_out_bits_uop_vpu_vmask[70])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[70] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[71] && s_s1_io_out_bits_uop_vpu_vmask[71])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[71] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[72] && s_s1_io_out_bits_uop_vpu_vmask[72])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[72] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[73] && s_s1_io_out_bits_uop_vpu_vmask[73])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[73] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[74] && s_s1_io_out_bits_uop_vpu_vmask[74])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[74] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[75] && s_s1_io_out_bits_uop_vpu_vmask[75])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[75] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[76] && s_s1_io_out_bits_uop_vpu_vmask[76])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[76] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[77] && s_s1_io_out_bits_uop_vpu_vmask[77])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[77] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[78] && s_s1_io_out_bits_uop_vpu_vmask[78])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[78] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[79] && s_s1_io_out_bits_uop_vpu_vmask[79])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[79] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[80] && s_s1_io_out_bits_uop_vpu_vmask[80])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[80] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[81] && s_s1_io_out_bits_uop_vpu_vmask[81])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[81] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[82] && s_s1_io_out_bits_uop_vpu_vmask[82])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[82] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[83] && s_s1_io_out_bits_uop_vpu_vmask[83])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[83] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[84] && s_s1_io_out_bits_uop_vpu_vmask[84])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[84] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[85] && s_s1_io_out_bits_uop_vpu_vmask[85])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[85] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[86] && s_s1_io_out_bits_uop_vpu_vmask[86])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[86] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[87] && s_s1_io_out_bits_uop_vpu_vmask[87])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[87] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[88] && s_s1_io_out_bits_uop_vpu_vmask[88])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[88] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[89] && s_s1_io_out_bits_uop_vpu_vmask[89])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[89] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[90] && s_s1_io_out_bits_uop_vpu_vmask[90])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[90] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[91] && s_s1_io_out_bits_uop_vpu_vmask[91])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[91] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[92] && s_s1_io_out_bits_uop_vpu_vmask[92])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[92] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[93] && s_s1_io_out_bits_uop_vpu_vmask[93])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[93] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[94] && s_s1_io_out_bits_uop_vpu_vmask[94])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[94] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[95] && s_s1_io_out_bits_uop_vpu_vmask[95])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[95] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[96] && s_s1_io_out_bits_uop_vpu_vmask[96])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[96] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[97] && s_s1_io_out_bits_uop_vpu_vmask[97])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[97] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[98] && s_s1_io_out_bits_uop_vpu_vmask[98])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[98] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[99] && s_s1_io_out_bits_uop_vpu_vmask[99])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[99] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[100] && s_s1_io_out_bits_uop_vpu_vmask[100])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[100] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[101] && s_s1_io_out_bits_uop_vpu_vmask[101])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[101] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[102] && s_s1_io_out_bits_uop_vpu_vmask[102])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[102] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[103] && s_s1_io_out_bits_uop_vpu_vmask[103])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[103] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[104] && s_s1_io_out_bits_uop_vpu_vmask[104])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[104] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[105] && s_s1_io_out_bits_uop_vpu_vmask[105])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[105] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[106] && s_s1_io_out_bits_uop_vpu_vmask[106])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[106] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[107] && s_s1_io_out_bits_uop_vpu_vmask[107])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[107] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[108] && s_s1_io_out_bits_uop_vpu_vmask[108])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[108] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[109] && s_s1_io_out_bits_uop_vpu_vmask[109])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[109] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[110] && s_s1_io_out_bits_uop_vpu_vmask[110])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[110] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[111] && s_s1_io_out_bits_uop_vpu_vmask[111])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[111] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[112] && s_s1_io_out_bits_uop_vpu_vmask[112])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[112] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[113] && s_s1_io_out_bits_uop_vpu_vmask[113])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[113] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[114] && s_s1_io_out_bits_uop_vpu_vmask[114])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[114] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[115] && s_s1_io_out_bits_uop_vpu_vmask[115])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[115] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[116] && s_s1_io_out_bits_uop_vpu_vmask[116])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[116] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[117] && s_s1_io_out_bits_uop_vpu_vmask[117])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[117] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[118] && s_s1_io_out_bits_uop_vpu_vmask[118])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[118] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[119] && s_s1_io_out_bits_uop_vpu_vmask[119])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[119] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[120] && s_s1_io_out_bits_uop_vpu_vmask[120])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[120] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[121] && s_s1_io_out_bits_uop_vpu_vmask[121])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[121] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[122] && s_s1_io_out_bits_uop_vpu_vmask[122])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[122] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[123] && s_s1_io_out_bits_uop_vpu_vmask[123])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[123] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[124] && s_s1_io_out_bits_uop_vpu_vmask[124])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[124] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[125] && s_s1_io_out_bits_uop_vpu_vmask[125])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[125] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[126] && s_s1_io_out_bits_uop_vpu_vmask[126])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[126] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vmask[127] && s_s1_io_out_bits_uop_vpu_vmask[127])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vmask[127] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vl[0] && s_s1_io_out_bits_uop_vpu_vl[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vl[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vl[1] && s_s1_io_out_bits_uop_vpu_vl[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vl[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vl[2] && s_s1_io_out_bits_uop_vpu_vl[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vl[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vl[3] && s_s1_io_out_bits_uop_vpu_vl[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vl[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vl[4] && s_s1_io_out_bits_uop_vpu_vl[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vl[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vl[5] && s_s1_io_out_bits_uop_vpu_vl[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vl[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vl[6] && s_s1_io_out_bits_uop_vpu_vl[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vl[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_vl[7] && s_s1_io_out_bits_uop_vpu_vl[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_vl[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_nf[0] && s_s1_io_out_bits_uop_vpu_nf[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_nf[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_nf[1] && s_s1_io_out_bits_uop_vpu_nf[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_nf[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_nf[2] && s_s1_io_out_bits_uop_vpu_nf[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_nf[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_veew[0] && s_s1_io_out_bits_uop_vpu_veew[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_veew[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_veew[1] && s_s1_io_out_bits_uop_vpu_veew[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_veew[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_isReverse && s_s1_io_out_bits_uop_vpu_isReverse)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_isReverse 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_isExt && s_s1_io_out_bits_uop_vpu_isExt)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_isExt 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_isNarrow && s_s1_io_out_bits_uop_vpu_isNarrow)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_isNarrow 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_isDstMask && s_s1_io_out_bits_uop_vpu_isDstMask)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_isDstMask 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_isOpMask && s_s1_io_out_bits_uop_vpu_isOpMask)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_isOpMask 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_isMove && s_s1_io_out_bits_uop_vpu_isMove)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_isMove 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_isDependOldVd && s_s1_io_out_bits_uop_vpu_isDependOldVd)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_isDependOldVd 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_isWritePartVd && s_s1_io_out_bits_uop_vpu_isWritePartVd)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_isWritePartVd 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_vpu_isVleff && s_s1_io_out_bits_uop_vpu_isVleff)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_vpu_isVleff 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_uopIdx[0] && s_s1_io_out_bits_uop_uopIdx[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_uopIdx[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_uopIdx[1] && s_s1_io_out_bits_uop_uopIdx[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_uopIdx[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_uopIdx[2] && s_s1_io_out_bits_uop_uopIdx[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_uopIdx[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_uopIdx[3] && s_s1_io_out_bits_uop_uopIdx[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_uopIdx[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_uopIdx[4] && s_s1_io_out_bits_uop_uopIdx[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_uopIdx[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_uopIdx[5] && s_s1_io_out_bits_uop_uopIdx[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_uopIdx[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_uopIdx[6] && s_s1_io_out_bits_uop_uopIdx[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_uopIdx[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_lastUop && s_s1_io_out_bits_uop_lastUop)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_lastUop 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_numUops[0] && s_s1_io_out_bits_uop_numUops[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_numUops[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_numUops[1] && s_s1_io_out_bits_uop_numUops[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_numUops[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_numUops[2] && s_s1_io_out_bits_uop_numUops[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_numUops[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_numUops[3] && s_s1_io_out_bits_uop_numUops[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_numUops[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_numUops[4] && s_s1_io_out_bits_uop_numUops[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_numUops[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_numUops[5] && s_s1_io_out_bits_uop_numUops[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_numUops[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_numUops[6] && s_s1_io_out_bits_uop_numUops[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_numUops[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pdest[0] && s_s1_io_out_bits_uop_pdest[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pdest[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pdest[1] && s_s1_io_out_bits_uop_pdest[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pdest[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pdest[2] && s_s1_io_out_bits_uop_pdest[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pdest[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pdest[3] && s_s1_io_out_bits_uop_pdest[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pdest[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pdest[4] && s_s1_io_out_bits_uop_pdest[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pdest[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pdest[5] && s_s1_io_out_bits_uop_pdest[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pdest[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pdest[6] && s_s1_io_out_bits_uop_pdest[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pdest[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_pdest[7] && s_s1_io_out_bits_uop_pdest[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_pdest[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_robIdx_flag && s_s1_io_out_bits_uop_robIdx_flag)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_robIdx_flag 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_robIdx_value[0] && s_s1_io_out_bits_uop_robIdx_value[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_robIdx_value[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_robIdx_value[1] && s_s1_io_out_bits_uop_robIdx_value[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_robIdx_value[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_robIdx_value[2] && s_s1_io_out_bits_uop_robIdx_value[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_robIdx_value[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_robIdx_value[3] && s_s1_io_out_bits_uop_robIdx_value[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_robIdx_value[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_robIdx_value[4] && s_s1_io_out_bits_uop_robIdx_value[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_robIdx_value[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_robIdx_value[5] && s_s1_io_out_bits_uop_robIdx_value[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_robIdx_value[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_robIdx_value[6] && s_s1_io_out_bits_uop_robIdx_value[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_robIdx_value[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_robIdx_value[7] && s_s1_io_out_bits_uop_robIdx_value[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_robIdx_value[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_eliminatedMove && s_s1_io_out_bits_uop_debugInfo_eliminatedMove)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_eliminatedMove 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[0] && s_s1_io_out_bits_uop_debugInfo_renameTime[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[1] && s_s1_io_out_bits_uop_debugInfo_renameTime[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[2] && s_s1_io_out_bits_uop_debugInfo_renameTime[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[3] && s_s1_io_out_bits_uop_debugInfo_renameTime[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[4] && s_s1_io_out_bits_uop_debugInfo_renameTime[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[5] && s_s1_io_out_bits_uop_debugInfo_renameTime[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[6] && s_s1_io_out_bits_uop_debugInfo_renameTime[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[7] && s_s1_io_out_bits_uop_debugInfo_renameTime[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[8] && s_s1_io_out_bits_uop_debugInfo_renameTime[8])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[8] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[9] && s_s1_io_out_bits_uop_debugInfo_renameTime[9])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[9] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[10] && s_s1_io_out_bits_uop_debugInfo_renameTime[10])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[10] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[11] && s_s1_io_out_bits_uop_debugInfo_renameTime[11])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[11] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[12] && s_s1_io_out_bits_uop_debugInfo_renameTime[12])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[12] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[13] && s_s1_io_out_bits_uop_debugInfo_renameTime[13])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[13] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[14] && s_s1_io_out_bits_uop_debugInfo_renameTime[14])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[14] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[15] && s_s1_io_out_bits_uop_debugInfo_renameTime[15])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[15] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[16] && s_s1_io_out_bits_uop_debugInfo_renameTime[16])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[16] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[17] && s_s1_io_out_bits_uop_debugInfo_renameTime[17])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[17] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[18] && s_s1_io_out_bits_uop_debugInfo_renameTime[18])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[18] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[19] && s_s1_io_out_bits_uop_debugInfo_renameTime[19])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[19] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[20] && s_s1_io_out_bits_uop_debugInfo_renameTime[20])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[20] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[21] && s_s1_io_out_bits_uop_debugInfo_renameTime[21])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[21] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[22] && s_s1_io_out_bits_uop_debugInfo_renameTime[22])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[22] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[23] && s_s1_io_out_bits_uop_debugInfo_renameTime[23])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[23] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[24] && s_s1_io_out_bits_uop_debugInfo_renameTime[24])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[24] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[25] && s_s1_io_out_bits_uop_debugInfo_renameTime[25])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[25] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[26] && s_s1_io_out_bits_uop_debugInfo_renameTime[26])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[26] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[27] && s_s1_io_out_bits_uop_debugInfo_renameTime[27])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[27] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[28] && s_s1_io_out_bits_uop_debugInfo_renameTime[28])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[28] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[29] && s_s1_io_out_bits_uop_debugInfo_renameTime[29])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[29] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[30] && s_s1_io_out_bits_uop_debugInfo_renameTime[30])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[30] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[31] && s_s1_io_out_bits_uop_debugInfo_renameTime[31])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[31] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[32] && s_s1_io_out_bits_uop_debugInfo_renameTime[32])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[32] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[33] && s_s1_io_out_bits_uop_debugInfo_renameTime[33])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[33] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[34] && s_s1_io_out_bits_uop_debugInfo_renameTime[34])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[34] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[35] && s_s1_io_out_bits_uop_debugInfo_renameTime[35])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[35] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[36] && s_s1_io_out_bits_uop_debugInfo_renameTime[36])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[36] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[37] && s_s1_io_out_bits_uop_debugInfo_renameTime[37])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[37] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[38] && s_s1_io_out_bits_uop_debugInfo_renameTime[38])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[38] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[39] && s_s1_io_out_bits_uop_debugInfo_renameTime[39])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[39] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[40] && s_s1_io_out_bits_uop_debugInfo_renameTime[40])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[40] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[41] && s_s1_io_out_bits_uop_debugInfo_renameTime[41])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[41] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[42] && s_s1_io_out_bits_uop_debugInfo_renameTime[42])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[42] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[43] && s_s1_io_out_bits_uop_debugInfo_renameTime[43])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[43] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[44] && s_s1_io_out_bits_uop_debugInfo_renameTime[44])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[44] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[45] && s_s1_io_out_bits_uop_debugInfo_renameTime[45])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[45] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[46] && s_s1_io_out_bits_uop_debugInfo_renameTime[46])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[46] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[47] && s_s1_io_out_bits_uop_debugInfo_renameTime[47])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[47] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[48] && s_s1_io_out_bits_uop_debugInfo_renameTime[48])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[48] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[49] && s_s1_io_out_bits_uop_debugInfo_renameTime[49])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[49] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[50] && s_s1_io_out_bits_uop_debugInfo_renameTime[50])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[50] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[51] && s_s1_io_out_bits_uop_debugInfo_renameTime[51])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[51] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[52] && s_s1_io_out_bits_uop_debugInfo_renameTime[52])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[52] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[53] && s_s1_io_out_bits_uop_debugInfo_renameTime[53])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[53] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[54] && s_s1_io_out_bits_uop_debugInfo_renameTime[54])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[54] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[55] && s_s1_io_out_bits_uop_debugInfo_renameTime[55])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[55] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[56] && s_s1_io_out_bits_uop_debugInfo_renameTime[56])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[56] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[57] && s_s1_io_out_bits_uop_debugInfo_renameTime[57])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[57] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[58] && s_s1_io_out_bits_uop_debugInfo_renameTime[58])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[58] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[59] && s_s1_io_out_bits_uop_debugInfo_renameTime[59])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[59] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[60] && s_s1_io_out_bits_uop_debugInfo_renameTime[60])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[60] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[61] && s_s1_io_out_bits_uop_debugInfo_renameTime[61])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[61] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[62] && s_s1_io_out_bits_uop_debugInfo_renameTime[62])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[62] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_renameTime[63] && s_s1_io_out_bits_uop_debugInfo_renameTime[63])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_renameTime[63] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[0] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[1] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[2] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[3] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[4] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[5] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[6] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[7] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[8] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[8])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[8] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[9] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[9])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[9] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[10] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[10])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[10] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[11] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[11])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[11] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[12] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[12])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[12] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[13] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[13])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[13] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[14] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[14])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[14] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[15] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[15])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[15] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[16] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[16])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[16] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[17] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[17])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[17] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[18] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[18])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[18] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[19] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[19])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[19] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[20] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[20])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[20] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[21] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[21])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[21] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[22] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[22])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[22] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[23] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[23])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[23] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[24] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[24])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[24] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[25] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[25])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[25] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[26] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[26])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[26] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[27] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[27])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[27] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[28] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[28])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[28] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[29] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[29])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[29] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[30] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[30])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[30] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[31] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[31])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[31] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[32] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[32])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[32] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[33] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[33])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[33] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[34] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[34])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[34] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[35] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[35])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[35] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[36] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[36])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[36] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[37] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[37])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[37] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[38] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[38])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[38] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[39] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[39])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[39] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[40] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[40])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[40] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[41] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[41])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[41] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[42] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[42])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[42] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[43] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[43])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[43] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[44] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[44])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[44] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[45] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[45])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[45] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[46] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[46])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[46] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[47] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[47])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[47] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[48] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[48])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[48] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[49] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[49])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[49] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[50] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[50])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[50] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[51] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[51])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[51] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[52] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[52])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[52] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[53] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[53])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[53] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[54] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[54])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[54] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[55] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[55])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[55] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[56] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[56])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[56] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[57] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[57])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[57] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[58] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[58])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[58] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[59] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[59])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[59] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[60] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[60])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[60] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[61] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[61])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[61] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[62] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[62])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[62] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_dispatchTime[63] && s_s1_io_out_bits_uop_debugInfo_dispatchTime[63])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_dispatchTime[63] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[0] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[1] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[2] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[3] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[4] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[5] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[6] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[7] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[8] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[8])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[8] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[9] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[9])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[9] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[10] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[10])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[10] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[11] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[11])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[11] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[12] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[12])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[12] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[13] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[13])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[13] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[14] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[14])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[14] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[15] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[15])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[15] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[16] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[16])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[16] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[17] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[17])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[17] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[18] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[18])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[18] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[19] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[19])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[19] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[20] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[20])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[20] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[21] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[21])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[21] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[22] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[22])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[22] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[23] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[23])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[23] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[24] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[24])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[24] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[25] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[25])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[25] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[26] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[26])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[26] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[27] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[27])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[27] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[28] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[28])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[28] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[29] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[29])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[29] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[30] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[30])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[30] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[31] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[31])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[31] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[32] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[32])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[32] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[33] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[33])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[33] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[34] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[34])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[34] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[35] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[35])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[35] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[36] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[36])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[36] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[37] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[37])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[37] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[38] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[38])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[38] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[39] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[39])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[39] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[40] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[40])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[40] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[41] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[41])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[41] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[42] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[42])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[42] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[43] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[43])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[43] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[44] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[44])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[44] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[45] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[45])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[45] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[46] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[46])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[46] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[47] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[47])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[47] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[48] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[48])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[48] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[49] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[49])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[49] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[50] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[50])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[50] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[51] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[51])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[51] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[52] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[52])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[52] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[53] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[53])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[53] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[54] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[54])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[54] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[55] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[55])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[55] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[56] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[56])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[56] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[57] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[57])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[57] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[58] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[58])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[58] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[59] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[59])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[59] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[60] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[60])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[60] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[61] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[61])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[61] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[62] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[62])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[62] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_enqRsTime[63] && s_s1_io_out_bits_uop_debugInfo_enqRsTime[63])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_enqRsTime[63] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[0] && s_s1_io_out_bits_uop_debugInfo_selectTime[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[1] && s_s1_io_out_bits_uop_debugInfo_selectTime[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[2] && s_s1_io_out_bits_uop_debugInfo_selectTime[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[3] && s_s1_io_out_bits_uop_debugInfo_selectTime[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[4] && s_s1_io_out_bits_uop_debugInfo_selectTime[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[5] && s_s1_io_out_bits_uop_debugInfo_selectTime[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[6] && s_s1_io_out_bits_uop_debugInfo_selectTime[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[7] && s_s1_io_out_bits_uop_debugInfo_selectTime[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[8] && s_s1_io_out_bits_uop_debugInfo_selectTime[8])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[8] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[9] && s_s1_io_out_bits_uop_debugInfo_selectTime[9])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[9] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[10] && s_s1_io_out_bits_uop_debugInfo_selectTime[10])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[10] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[11] && s_s1_io_out_bits_uop_debugInfo_selectTime[11])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[11] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[12] && s_s1_io_out_bits_uop_debugInfo_selectTime[12])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[12] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[13] && s_s1_io_out_bits_uop_debugInfo_selectTime[13])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[13] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[14] && s_s1_io_out_bits_uop_debugInfo_selectTime[14])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[14] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[15] && s_s1_io_out_bits_uop_debugInfo_selectTime[15])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[15] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[16] && s_s1_io_out_bits_uop_debugInfo_selectTime[16])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[16] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[17] && s_s1_io_out_bits_uop_debugInfo_selectTime[17])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[17] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[18] && s_s1_io_out_bits_uop_debugInfo_selectTime[18])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[18] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[19] && s_s1_io_out_bits_uop_debugInfo_selectTime[19])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[19] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[20] && s_s1_io_out_bits_uop_debugInfo_selectTime[20])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[20] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[21] && s_s1_io_out_bits_uop_debugInfo_selectTime[21])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[21] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[22] && s_s1_io_out_bits_uop_debugInfo_selectTime[22])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[22] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[23] && s_s1_io_out_bits_uop_debugInfo_selectTime[23])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[23] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[24] && s_s1_io_out_bits_uop_debugInfo_selectTime[24])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[24] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[25] && s_s1_io_out_bits_uop_debugInfo_selectTime[25])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[25] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[26] && s_s1_io_out_bits_uop_debugInfo_selectTime[26])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[26] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[27] && s_s1_io_out_bits_uop_debugInfo_selectTime[27])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[27] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[28] && s_s1_io_out_bits_uop_debugInfo_selectTime[28])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[28] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[29] && s_s1_io_out_bits_uop_debugInfo_selectTime[29])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[29] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[30] && s_s1_io_out_bits_uop_debugInfo_selectTime[30])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[30] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[31] && s_s1_io_out_bits_uop_debugInfo_selectTime[31])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[31] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[32] && s_s1_io_out_bits_uop_debugInfo_selectTime[32])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[32] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[33] && s_s1_io_out_bits_uop_debugInfo_selectTime[33])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[33] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[34] && s_s1_io_out_bits_uop_debugInfo_selectTime[34])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[34] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[35] && s_s1_io_out_bits_uop_debugInfo_selectTime[35])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[35] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[36] && s_s1_io_out_bits_uop_debugInfo_selectTime[36])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[36] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[37] && s_s1_io_out_bits_uop_debugInfo_selectTime[37])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[37] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[38] && s_s1_io_out_bits_uop_debugInfo_selectTime[38])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[38] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[39] && s_s1_io_out_bits_uop_debugInfo_selectTime[39])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[39] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[40] && s_s1_io_out_bits_uop_debugInfo_selectTime[40])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[40] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[41] && s_s1_io_out_bits_uop_debugInfo_selectTime[41])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[41] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[42] && s_s1_io_out_bits_uop_debugInfo_selectTime[42])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[42] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[43] && s_s1_io_out_bits_uop_debugInfo_selectTime[43])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[43] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[44] && s_s1_io_out_bits_uop_debugInfo_selectTime[44])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[44] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[45] && s_s1_io_out_bits_uop_debugInfo_selectTime[45])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[45] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[46] && s_s1_io_out_bits_uop_debugInfo_selectTime[46])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[46] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[47] && s_s1_io_out_bits_uop_debugInfo_selectTime[47])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[47] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[48] && s_s1_io_out_bits_uop_debugInfo_selectTime[48])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[48] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[49] && s_s1_io_out_bits_uop_debugInfo_selectTime[49])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[49] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[50] && s_s1_io_out_bits_uop_debugInfo_selectTime[50])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[50] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[51] && s_s1_io_out_bits_uop_debugInfo_selectTime[51])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[51] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[52] && s_s1_io_out_bits_uop_debugInfo_selectTime[52])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[52] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[53] && s_s1_io_out_bits_uop_debugInfo_selectTime[53])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[53] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[54] && s_s1_io_out_bits_uop_debugInfo_selectTime[54])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[54] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[55] && s_s1_io_out_bits_uop_debugInfo_selectTime[55])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[55] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[56] && s_s1_io_out_bits_uop_debugInfo_selectTime[56])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[56] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[57] && s_s1_io_out_bits_uop_debugInfo_selectTime[57])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[57] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[58] && s_s1_io_out_bits_uop_debugInfo_selectTime[58])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[58] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[59] && s_s1_io_out_bits_uop_debugInfo_selectTime[59])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[59] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[60] && s_s1_io_out_bits_uop_debugInfo_selectTime[60])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[60] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[61] && s_s1_io_out_bits_uop_debugInfo_selectTime[61])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[61] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[62] && s_s1_io_out_bits_uop_debugInfo_selectTime[62])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[62] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_selectTime[63] && s_s1_io_out_bits_uop_debugInfo_selectTime[63])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_selectTime[63] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[0] && s_s1_io_out_bits_uop_debugInfo_issueTime[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[1] && s_s1_io_out_bits_uop_debugInfo_issueTime[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[2] && s_s1_io_out_bits_uop_debugInfo_issueTime[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[3] && s_s1_io_out_bits_uop_debugInfo_issueTime[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[4] && s_s1_io_out_bits_uop_debugInfo_issueTime[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[5] && s_s1_io_out_bits_uop_debugInfo_issueTime[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[6] && s_s1_io_out_bits_uop_debugInfo_issueTime[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[7] && s_s1_io_out_bits_uop_debugInfo_issueTime[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[8] && s_s1_io_out_bits_uop_debugInfo_issueTime[8])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[8] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[9] && s_s1_io_out_bits_uop_debugInfo_issueTime[9])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[9] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[10] && s_s1_io_out_bits_uop_debugInfo_issueTime[10])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[10] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[11] && s_s1_io_out_bits_uop_debugInfo_issueTime[11])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[11] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[12] && s_s1_io_out_bits_uop_debugInfo_issueTime[12])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[12] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[13] && s_s1_io_out_bits_uop_debugInfo_issueTime[13])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[13] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[14] && s_s1_io_out_bits_uop_debugInfo_issueTime[14])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[14] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[15] && s_s1_io_out_bits_uop_debugInfo_issueTime[15])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[15] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[16] && s_s1_io_out_bits_uop_debugInfo_issueTime[16])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[16] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[17] && s_s1_io_out_bits_uop_debugInfo_issueTime[17])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[17] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[18] && s_s1_io_out_bits_uop_debugInfo_issueTime[18])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[18] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[19] && s_s1_io_out_bits_uop_debugInfo_issueTime[19])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[19] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[20] && s_s1_io_out_bits_uop_debugInfo_issueTime[20])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[20] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[21] && s_s1_io_out_bits_uop_debugInfo_issueTime[21])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[21] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[22] && s_s1_io_out_bits_uop_debugInfo_issueTime[22])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[22] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[23] && s_s1_io_out_bits_uop_debugInfo_issueTime[23])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[23] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[24] && s_s1_io_out_bits_uop_debugInfo_issueTime[24])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[24] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[25] && s_s1_io_out_bits_uop_debugInfo_issueTime[25])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[25] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[26] && s_s1_io_out_bits_uop_debugInfo_issueTime[26])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[26] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[27] && s_s1_io_out_bits_uop_debugInfo_issueTime[27])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[27] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[28] && s_s1_io_out_bits_uop_debugInfo_issueTime[28])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[28] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[29] && s_s1_io_out_bits_uop_debugInfo_issueTime[29])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[29] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[30] && s_s1_io_out_bits_uop_debugInfo_issueTime[30])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[30] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[31] && s_s1_io_out_bits_uop_debugInfo_issueTime[31])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[31] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[32] && s_s1_io_out_bits_uop_debugInfo_issueTime[32])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[32] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[33] && s_s1_io_out_bits_uop_debugInfo_issueTime[33])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[33] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[34] && s_s1_io_out_bits_uop_debugInfo_issueTime[34])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[34] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[35] && s_s1_io_out_bits_uop_debugInfo_issueTime[35])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[35] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[36] && s_s1_io_out_bits_uop_debugInfo_issueTime[36])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[36] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[37] && s_s1_io_out_bits_uop_debugInfo_issueTime[37])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[37] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[38] && s_s1_io_out_bits_uop_debugInfo_issueTime[38])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[38] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[39] && s_s1_io_out_bits_uop_debugInfo_issueTime[39])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[39] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[40] && s_s1_io_out_bits_uop_debugInfo_issueTime[40])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[40] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[41] && s_s1_io_out_bits_uop_debugInfo_issueTime[41])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[41] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[42] && s_s1_io_out_bits_uop_debugInfo_issueTime[42])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[42] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[43] && s_s1_io_out_bits_uop_debugInfo_issueTime[43])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[43] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[44] && s_s1_io_out_bits_uop_debugInfo_issueTime[44])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[44] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[45] && s_s1_io_out_bits_uop_debugInfo_issueTime[45])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[45] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[46] && s_s1_io_out_bits_uop_debugInfo_issueTime[46])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[46] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[47] && s_s1_io_out_bits_uop_debugInfo_issueTime[47])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[47] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[48] && s_s1_io_out_bits_uop_debugInfo_issueTime[48])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[48] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[49] && s_s1_io_out_bits_uop_debugInfo_issueTime[49])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[49] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[50] && s_s1_io_out_bits_uop_debugInfo_issueTime[50])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[50] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[51] && s_s1_io_out_bits_uop_debugInfo_issueTime[51])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[51] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[52] && s_s1_io_out_bits_uop_debugInfo_issueTime[52])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[52] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[53] && s_s1_io_out_bits_uop_debugInfo_issueTime[53])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[53] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[54] && s_s1_io_out_bits_uop_debugInfo_issueTime[54])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[54] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[55] && s_s1_io_out_bits_uop_debugInfo_issueTime[55])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[55] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[56] && s_s1_io_out_bits_uop_debugInfo_issueTime[56])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[56] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[57] && s_s1_io_out_bits_uop_debugInfo_issueTime[57])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[57] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[58] && s_s1_io_out_bits_uop_debugInfo_issueTime[58])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[58] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[59] && s_s1_io_out_bits_uop_debugInfo_issueTime[59])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[59] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[60] && s_s1_io_out_bits_uop_debugInfo_issueTime[60])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[60] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[61] && s_s1_io_out_bits_uop_debugInfo_issueTime[61])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[61] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[62] && s_s1_io_out_bits_uop_debugInfo_issueTime[62])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[62] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_issueTime[63] && s_s1_io_out_bits_uop_debugInfo_issueTime[63])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_issueTime[63] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[0] && s_s1_io_out_bits_uop_debugInfo_writebackTime[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[1] && s_s1_io_out_bits_uop_debugInfo_writebackTime[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[2] && s_s1_io_out_bits_uop_debugInfo_writebackTime[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[3] && s_s1_io_out_bits_uop_debugInfo_writebackTime[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[4] && s_s1_io_out_bits_uop_debugInfo_writebackTime[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[5] && s_s1_io_out_bits_uop_debugInfo_writebackTime[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[6] && s_s1_io_out_bits_uop_debugInfo_writebackTime[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[7] && s_s1_io_out_bits_uop_debugInfo_writebackTime[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[8] && s_s1_io_out_bits_uop_debugInfo_writebackTime[8])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[8] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[9] && s_s1_io_out_bits_uop_debugInfo_writebackTime[9])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[9] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[10] && s_s1_io_out_bits_uop_debugInfo_writebackTime[10])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[10] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[11] && s_s1_io_out_bits_uop_debugInfo_writebackTime[11])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[11] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[12] && s_s1_io_out_bits_uop_debugInfo_writebackTime[12])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[12] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[13] && s_s1_io_out_bits_uop_debugInfo_writebackTime[13])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[13] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[14] && s_s1_io_out_bits_uop_debugInfo_writebackTime[14])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[14] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[15] && s_s1_io_out_bits_uop_debugInfo_writebackTime[15])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[15] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[16] && s_s1_io_out_bits_uop_debugInfo_writebackTime[16])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[16] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[17] && s_s1_io_out_bits_uop_debugInfo_writebackTime[17])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[17] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[18] && s_s1_io_out_bits_uop_debugInfo_writebackTime[18])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[18] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[19] && s_s1_io_out_bits_uop_debugInfo_writebackTime[19])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[19] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[20] && s_s1_io_out_bits_uop_debugInfo_writebackTime[20])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[20] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[21] && s_s1_io_out_bits_uop_debugInfo_writebackTime[21])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[21] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[22] && s_s1_io_out_bits_uop_debugInfo_writebackTime[22])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[22] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[23] && s_s1_io_out_bits_uop_debugInfo_writebackTime[23])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[23] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[24] && s_s1_io_out_bits_uop_debugInfo_writebackTime[24])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[24] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[25] && s_s1_io_out_bits_uop_debugInfo_writebackTime[25])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[25] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[26] && s_s1_io_out_bits_uop_debugInfo_writebackTime[26])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[26] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[27] && s_s1_io_out_bits_uop_debugInfo_writebackTime[27])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[27] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[28] && s_s1_io_out_bits_uop_debugInfo_writebackTime[28])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[28] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[29] && s_s1_io_out_bits_uop_debugInfo_writebackTime[29])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[29] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[30] && s_s1_io_out_bits_uop_debugInfo_writebackTime[30])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[30] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[31] && s_s1_io_out_bits_uop_debugInfo_writebackTime[31])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[31] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[32] && s_s1_io_out_bits_uop_debugInfo_writebackTime[32])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[32] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[33] && s_s1_io_out_bits_uop_debugInfo_writebackTime[33])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[33] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[34] && s_s1_io_out_bits_uop_debugInfo_writebackTime[34])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[34] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[35] && s_s1_io_out_bits_uop_debugInfo_writebackTime[35])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[35] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[36] && s_s1_io_out_bits_uop_debugInfo_writebackTime[36])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[36] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[37] && s_s1_io_out_bits_uop_debugInfo_writebackTime[37])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[37] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[38] && s_s1_io_out_bits_uop_debugInfo_writebackTime[38])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[38] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[39] && s_s1_io_out_bits_uop_debugInfo_writebackTime[39])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[39] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[40] && s_s1_io_out_bits_uop_debugInfo_writebackTime[40])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[40] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[41] && s_s1_io_out_bits_uop_debugInfo_writebackTime[41])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[41] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[42] && s_s1_io_out_bits_uop_debugInfo_writebackTime[42])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[42] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[43] && s_s1_io_out_bits_uop_debugInfo_writebackTime[43])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[43] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[44] && s_s1_io_out_bits_uop_debugInfo_writebackTime[44])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[44] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[45] && s_s1_io_out_bits_uop_debugInfo_writebackTime[45])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[45] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[46] && s_s1_io_out_bits_uop_debugInfo_writebackTime[46])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[46] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[47] && s_s1_io_out_bits_uop_debugInfo_writebackTime[47])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[47] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[48] && s_s1_io_out_bits_uop_debugInfo_writebackTime[48])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[48] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[49] && s_s1_io_out_bits_uop_debugInfo_writebackTime[49])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[49] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[50] && s_s1_io_out_bits_uop_debugInfo_writebackTime[50])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[50] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[51] && s_s1_io_out_bits_uop_debugInfo_writebackTime[51])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[51] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[52] && s_s1_io_out_bits_uop_debugInfo_writebackTime[52])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[52] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[53] && s_s1_io_out_bits_uop_debugInfo_writebackTime[53])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[53] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[54] && s_s1_io_out_bits_uop_debugInfo_writebackTime[54])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[54] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[55] && s_s1_io_out_bits_uop_debugInfo_writebackTime[55])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[55] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[56] && s_s1_io_out_bits_uop_debugInfo_writebackTime[56])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[56] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[57] && s_s1_io_out_bits_uop_debugInfo_writebackTime[57])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[57] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[58] && s_s1_io_out_bits_uop_debugInfo_writebackTime[58])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[58] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[59] && s_s1_io_out_bits_uop_debugInfo_writebackTime[59])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[59] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[60] && s_s1_io_out_bits_uop_debugInfo_writebackTime[60])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[60] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[61] && s_s1_io_out_bits_uop_debugInfo_writebackTime[61])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[61] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[62] && s_s1_io_out_bits_uop_debugInfo_writebackTime[62])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[62] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_writebackTime[63] && s_s1_io_out_bits_uop_debugInfo_writebackTime[63])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_writebackTime[63] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[0] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[1] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[2] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[3] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[4] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[5] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[6] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[7] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[8] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[8])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[8] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[9] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[9])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[9] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[10] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[10])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[10] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[11] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[11])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[11] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[12] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[12])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[12] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[13] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[13])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[13] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[14] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[14])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[14] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[15] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[15])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[15] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[16] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[16])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[16] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[17] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[17])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[17] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[18] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[18])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[18] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[19] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[19])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[19] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[20] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[20])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[20] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[21] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[21])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[21] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[22] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[22])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[22] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[23] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[23])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[23] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[24] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[24])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[24] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[25] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[25])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[25] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[26] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[26])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[26] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[27] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[27])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[27] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[28] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[28])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[28] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[29] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[29])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[29] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[30] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[30])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[30] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[31] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[31])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[31] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[32] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[32])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[32] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[33] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[33])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[33] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[34] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[34])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[34] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[35] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[35])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[35] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[36] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[36])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[36] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[37] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[37])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[37] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[38] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[38])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[38] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[39] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[39])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[39] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[40] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[40])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[40] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[41] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[41])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[41] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[42] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[42])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[42] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[43] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[43])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[43] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[44] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[44])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[44] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[45] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[45])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[45] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[46] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[46])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[46] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[47] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[47])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[47] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[48] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[48])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[48] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[49] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[49])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[49] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[50] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[50])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[50] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[51] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[51])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[51] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[52] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[52])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[52] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[53] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[53])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[53] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[54] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[54])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[54] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[55] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[55])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[55] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[56] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[56])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[56] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[57] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[57])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[57] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[58] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[58])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[58] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[59] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[59])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[59] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[60] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[60])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[60] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[61] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[61])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[61] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[62] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[62])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[62] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_runahead_checkpoint_id[63] && s_s1_io_out_bits_uop_debugInfo_runahead_checkpoint_id[63])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_runahead_checkpoint_id[63] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[0] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[1] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[2] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[3] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[4] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[5] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[6] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[7] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[8] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[8])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[8] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[9] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[9])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[9] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[10] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[10])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[10] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[11] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[11])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[11] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[12] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[12])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[12] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[13] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[13])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[13] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[14] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[14])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[14] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[15] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[15])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[15] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[16] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[16])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[16] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[17] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[17])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[17] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[18] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[18])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[18] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[19] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[19])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[19] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[20] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[20])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[20] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[21] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[21])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[21] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[22] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[22])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[22] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[23] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[23])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[23] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[24] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[24])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[24] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[25] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[25])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[25] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[26] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[26])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[26] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[27] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[27])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[27] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[28] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[28])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[28] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[29] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[29])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[29] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[30] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[30])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[30] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[31] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[31])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[31] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[32] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[32])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[32] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[33] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[33])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[33] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[34] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[34])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[34] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[35] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[35])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[35] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[36] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[36])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[36] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[37] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[37])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[37] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[38] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[38])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[38] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[39] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[39])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[39] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[40] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[40])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[40] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[41] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[41])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[41] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[42] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[42])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[42] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[43] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[43])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[43] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[44] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[44])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[44] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[45] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[45])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[45] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[46] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[46])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[46] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[47] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[47])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[47] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[48] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[48])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[48] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[49] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[49])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[49] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[50] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[50])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[50] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[51] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[51])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[51] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[52] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[52])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[52] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[53] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[53])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[53] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[54] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[54])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[54] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[55] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[55])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[55] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[56] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[56])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[56] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[57] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[57])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[57] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[58] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[58])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[58] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[59] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[59])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[59] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[60] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[60])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[60] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[61] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[61])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[61] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[62] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[62])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[62] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbFirstReqTime[63] && s_s1_io_out_bits_uop_debugInfo_tlbFirstReqTime[63])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbFirstReqTime[63] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[0] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[1] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[2] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[3] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[4] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[5] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[6] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[7] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[8] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[8])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[8] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[9] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[9])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[9] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[10] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[10])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[10] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[11] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[11])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[11] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[12] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[12])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[12] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[13] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[13])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[13] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[14] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[14])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[14] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[15] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[15])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[15] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[16] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[16])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[16] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[17] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[17])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[17] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[18] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[18])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[18] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[19] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[19])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[19] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[20] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[20])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[20] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[21] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[21])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[21] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[22] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[22])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[22] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[23] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[23])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[23] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[24] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[24])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[24] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[25] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[25])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[25] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[26] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[26])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[26] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[27] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[27])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[27] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[28] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[28])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[28] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[29] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[29])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[29] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[30] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[30])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[30] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[31] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[31])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[31] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[32] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[32])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[32] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[33] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[33])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[33] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[34] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[34])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[34] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[35] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[35])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[35] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[36] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[36])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[36] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[37] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[37])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[37] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[38] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[38])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[38] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[39] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[39])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[39] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[40] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[40])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[40] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[41] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[41])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[41] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[42] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[42])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[42] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[43] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[43])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[43] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[44] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[44])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[44] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[45] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[45])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[45] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[46] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[46])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[46] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[47] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[47])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[47] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[48] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[48])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[48] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[49] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[49])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[49] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[50] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[50])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[50] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[51] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[51])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[51] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[52] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[52])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[52] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[53] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[53])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[53] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[54] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[54])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[54] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[55] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[55])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[55] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[56] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[56])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[56] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[57] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[57])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[57] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[58] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[58])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[58] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[59] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[59])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[59] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[60] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[60])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[60] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[61] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[61])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[61] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[62] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[62])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[62] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debugInfo_tlbRespTime[63] && s_s1_io_out_bits_uop_debugInfo_tlbRespTime[63])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debugInfo_tlbRespTime[63] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[0] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[1] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[2] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[3] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[4] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[5] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[6] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[7] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[8] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[8])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[8] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[9] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[9])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[9] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[10] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[10])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[10] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[11] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[11])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[11] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[12] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[12])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[12] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[13] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[13])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[13] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[14] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[14])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[14] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[15] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[15])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[15] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[16] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[16])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[16] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[17] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[17])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[17] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[18] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[18])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[18] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[19] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[19])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[19] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[20] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[20])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[20] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[21] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[21])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[21] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[22] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[22])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[22] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[23] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[23])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[23] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[24] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[24])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[24] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[25] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[25])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[25] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[26] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[26])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[26] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[27] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[27])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[27] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[28] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[28])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[28] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[29] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[29])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[29] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[30] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[30])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[30] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[31] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[31])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[31] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[32] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[32])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[32] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[33] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[33])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[33] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[34] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[34])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[34] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[35] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[35])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[35] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[36] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[36])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[36] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[37] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[37])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[37] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[38] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[38])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[38] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[39] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[39])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[39] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[40] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[40])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[40] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[41] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[41])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[41] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[42] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[42])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[42] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[43] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[43])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[43] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[44] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[44])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[44] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[45] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[45])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[45] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[46] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[46])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[46] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[47] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[47])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[47] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[48] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[48])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[48] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[49] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[49])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[49] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[50] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[50])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[50] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[51] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[51])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[51] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[52] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[52])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[52] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[53] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[53])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[53] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[54] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[54])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[54] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_seqNum[55] && s_s1_io_out_bits_uop_debug_seqNum_seqNum[55])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_seqNum[55] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_uopIdx[0] && s_s1_io_out_bits_uop_debug_seqNum_uopIdx[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_uopIdx[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_uopIdx[1] && s_s1_io_out_bits_uop_debug_seqNum_uopIdx[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_uopIdx[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_uopIdx[2] && s_s1_io_out_bits_uop_debug_seqNum_uopIdx[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_uopIdx[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_uopIdx[3] && s_s1_io_out_bits_uop_debug_seqNum_uopIdx[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_uopIdx[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_uopIdx[4] && s_s1_io_out_bits_uop_debug_seqNum_uopIdx[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_uopIdx[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_uopIdx[5] && s_s1_io_out_bits_uop_debug_seqNum_uopIdx[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_uopIdx[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_uopIdx[6] && s_s1_io_out_bits_uop_debug_seqNum_uopIdx[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_uopIdx[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_debug_seqNum_uopIdx[7] && s_s1_io_out_bits_uop_debug_seqNum_uopIdx[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_debug_seqNum_uopIdx[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_lqIdx_flag && s_s1_io_out_bits_uop_lqIdx_flag)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_lqIdx_flag 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_lqIdx_value[0] && s_s1_io_out_bits_uop_lqIdx_value[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_lqIdx_value[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_lqIdx_value[1] && s_s1_io_out_bits_uop_lqIdx_value[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_lqIdx_value[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_lqIdx_value[2] && s_s1_io_out_bits_uop_lqIdx_value[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_lqIdx_value[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_lqIdx_value[3] && s_s1_io_out_bits_uop_lqIdx_value[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_lqIdx_value[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_lqIdx_value[4] && s_s1_io_out_bits_uop_lqIdx_value[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_lqIdx_value[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_lqIdx_value[5] && s_s1_io_out_bits_uop_lqIdx_value[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_lqIdx_value[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_lqIdx_value[6] && s_s1_io_out_bits_uop_lqIdx_value[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_lqIdx_value[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_sqIdx_flag && s_s1_io_out_bits_uop_sqIdx_flag)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_sqIdx_flag 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_sqIdx_value[0] && s_s1_io_out_bits_uop_sqIdx_value[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_sqIdx_value[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_sqIdx_value[1] && s_s1_io_out_bits_uop_sqIdx_value[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_sqIdx_value[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_sqIdx_value[2] && s_s1_io_out_bits_uop_sqIdx_value[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_sqIdx_value[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_sqIdx_value[3] && s_s1_io_out_bits_uop_sqIdx_value[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_sqIdx_value[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_sqIdx_value[4] && s_s1_io_out_bits_uop_sqIdx_value[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_sqIdx_value[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_sqIdx_value[5] && s_s1_io_out_bits_uop_sqIdx_value[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_sqIdx_value[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_numLsElem[0] && s_s1_io_out_bits_uop_numLsElem[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_numLsElem[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_numLsElem[1] && s_s1_io_out_bits_uop_numLsElem[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_numLsElem[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_numLsElem[2] && s_s1_io_out_bits_uop_numLsElem[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_numLsElem[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_numLsElem[3] && s_s1_io_out_bits_uop_numLsElem[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_numLsElem[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_uop_numLsElem[4] && s_s1_io_out_bits_uop_numLsElem[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_uop_numLsElem[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_preIsSplit && s_s1_io_out_bits_preIsSplit)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_preIsSplit 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_mBIndex[0] && s_s1_io_out_bits_mBIndex[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_mBIndex[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_mBIndex[1] && s_s1_io_out_bits_mBIndex[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_mBIndex[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_mBIndex[2] && s_s1_io_out_bits_mBIndex[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_mBIndex[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_mBIndex[3] && s_s1_io_out_bits_mBIndex[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_mBIndex[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_alignedType[0] && s_s1_io_out_bits_alignedType[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_alignedType[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_alignedType[1] && s_s1_io_out_bits_alignedType[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_alignedType[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_alignedType[2] && s_s1_io_out_bits_alignedType[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_alignedType[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_indexVlMaxInVd[0] && s_s1_io_out_bits_indexVlMaxInVd[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_indexVlMaxInVd[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_indexVlMaxInVd[1] && s_s1_io_out_bits_indexVlMaxInVd[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_indexVlMaxInVd[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_indexVlMaxInVd[2] && s_s1_io_out_bits_indexVlMaxInVd[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_indexVlMaxInVd[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_indexVlMaxInVd[3] && s_s1_io_out_bits_indexVlMaxInVd[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_indexVlMaxInVd[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_indexVlMaxInVd[4] && s_s1_io_out_bits_indexVlMaxInVd[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_indexVlMaxInVd[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_indexVlMaxInVd[5] && s_s1_io_out_bits_indexVlMaxInVd[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_indexVlMaxInVd[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_indexVlMaxInVd[6] && s_s1_io_out_bits_indexVlMaxInVd[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_indexVlMaxInVd[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_indexVlMaxInVd[7] && s_s1_io_out_bits_indexVlMaxInVd[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_indexVlMaxInVd[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usLowBitsAddr[0] && s_s1_io_out_bits_usLowBitsAddr[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usLowBitsAddr[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usLowBitsAddr[1] && s_s1_io_out_bits_usLowBitsAddr[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usLowBitsAddr[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usLowBitsAddr[2] && s_s1_io_out_bits_usLowBitsAddr[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usLowBitsAddr[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usLowBitsAddr[3] && s_s1_io_out_bits_usLowBitsAddr[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usLowBitsAddr[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usAligned128 && s_s1_io_out_bits_usAligned128)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usAligned128 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[0] && s_s1_io_out_bits_usMask[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[1] && s_s1_io_out_bits_usMask[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[2] && s_s1_io_out_bits_usMask[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[3] && s_s1_io_out_bits_usMask[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[4] && s_s1_io_out_bits_usMask[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[5] && s_s1_io_out_bits_usMask[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[6] && s_s1_io_out_bits_usMask[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[7] && s_s1_io_out_bits_usMask[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[8] && s_s1_io_out_bits_usMask[8])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[8] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[9] && s_s1_io_out_bits_usMask[9])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[9] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[10] && s_s1_io_out_bits_usMask[10])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[10] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[11] && s_s1_io_out_bits_usMask[11])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[11] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[12] && s_s1_io_out_bits_usMask[12])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[12] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[13] && s_s1_io_out_bits_usMask[13])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[13] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[14] && s_s1_io_out_bits_usMask[14])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[14] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[15] && s_s1_io_out_bits_usMask[15])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[15] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[16] && s_s1_io_out_bits_usMask[16])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[16] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[17] && s_s1_io_out_bits_usMask[17])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[17] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[18] && s_s1_io_out_bits_usMask[18])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[18] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[19] && s_s1_io_out_bits_usMask[19])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[19] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[20] && s_s1_io_out_bits_usMask[20])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[20] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[21] && s_s1_io_out_bits_usMask[21])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[21] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[22] && s_s1_io_out_bits_usMask[22])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[22] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[23] && s_s1_io_out_bits_usMask[23])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[23] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[24] && s_s1_io_out_bits_usMask[24])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[24] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[25] && s_s1_io_out_bits_usMask[25])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[25] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[26] && s_s1_io_out_bits_usMask[26])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[26] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[27] && s_s1_io_out_bits_usMask[27])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[27] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[28] && s_s1_io_out_bits_usMask[28])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[28] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[29] && s_s1_io_out_bits_usMask[29])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[29] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[30] && s_s1_io_out_bits_usMask[30])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[30] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_usMask[31] && s_s1_io_out_bits_usMask[31])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_usMask[31] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_isVecPartReplay && s_s1_io_out_bits_isVecPartReplay)) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_isVecPartReplay 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_vecReplayFlowMask[0] && s_s1_io_out_bits_vecReplayFlowMask[0])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_vecReplayFlowMask[0] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_vecReplayFlowMask[1] && s_s1_io_out_bits_vecReplayFlowMask[1])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_vecReplayFlowMask[1] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_vecReplayFlowMask[2] && s_s1_io_out_bits_vecReplayFlowMask[2])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_vecReplayFlowMask[2] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_vecReplayFlowMask[3] && s_s1_io_out_bits_vecReplayFlowMask[3])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_vecReplayFlowMask[3] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_vecReplayFlowMask[4] && s_s1_io_out_bits_vecReplayFlowMask[4])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_vecReplayFlowMask[4] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_vecReplayFlowMask[5] && s_s1_io_out_bits_vecReplayFlowMask[5])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_vecReplayFlowMask[5] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_vecReplayFlowMask[6] && s_s1_io_out_bits_vecReplayFlowMask[6])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_vecReplayFlowMask[6] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_vecReplayFlowMask[7] && s_s1_io_out_bits_vecReplayFlowMask[7])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_vecReplayFlowMask[7] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_vecReplayFlowMask[8] && s_s1_io_out_bits_vecReplayFlowMask[8])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_vecReplayFlowMask[8] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_vecReplayFlowMask[9] && s_s1_io_out_bits_vecReplayFlowMask[9])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_vecReplayFlowMask[9] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_vecReplayFlowMask[10] && s_s1_io_out_bits_vecReplayFlowMask[10])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_vecReplayFlowMask[10] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_vecReplayFlowMask[11] && s_s1_io_out_bits_vecReplayFlowMask[11])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_vecReplayFlowMask[11] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_vecReplayFlowMask[12] && s_s1_io_out_bits_vecReplayFlowMask[12])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_vecReplayFlowMask[12] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_vecReplayFlowMask[13] && s_s1_io_out_bits_vecReplayFlowMask[13])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_vecReplayFlowMask[13] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_vecReplayFlowMask[14] && s_s1_io_out_bits_vecReplayFlowMask[14])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_vecReplayFlowMask[14] 未见过 0 和 1"); end
    if (!(s_s0_io_out_bits_vecReplayFlowMask[15] && s_s1_io_out_bits_vecReplayFlowMask[15])) begin cov_fail++; $display("[COV] skidBufferConnect.io_out_bits_vecReplayFlowMask[15] 未见过 0 和 1"); end
    $display("[ARM] skidBufferConnect armed_at=%0d", s_armed_at);
    if (s_armed_at < 0) begin cov_fail++; $display("[ARM] skidBufferConnect 从未 arm"); end
    $display("[COV] skidBufferConnect.capture = %0d", s_cov_capture);
    if (s_cov_capture < 200) begin cov_fail++; $display("[COV] skidBufferConnect.capture < 200"); end
    $display("[COV] skidBufferConnect.skid = %0d", s_cov_skid);
    if (s_cov_skid < 200) begin cov_fail++; $display("[COV] skidBufferConnect.skid < 200"); end
    $display("[COV] skidBufferConnect.drain = %0d", s_cov_drain);
    if (s_cov_drain < 200) begin cov_fail++; $display("[COV] skidBufferConnect.drain < 200"); end
    $display("[COV] skidBufferConnect.flush_skid = %0d", s_cov_flush_skid);
    if (s_cov_flush_skid < 200) begin cov_fail++; $display("[COV] skidBufferConnect.flush_skid < 200"); end
    $display("[COV] skidBufferConnect.flush_cap = %0d", s_cov_flush_cap);
    if (s_cov_flush_cap < 200) begin cov_fail++; $display("[COV] skidBufferConnect.flush_cap < 200"); end
    $display("[COV] skidBufferConnect.pass = %0d", s_cov_pass);
    if (s_cov_pass < 200) begin cov_fail++; $display("[COV] skidBufferConnect.pass < 200"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
