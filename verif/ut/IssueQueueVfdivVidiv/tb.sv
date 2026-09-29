// IssueQueueVfdivVidiv UT —— golden IssueQueueVfdivVidiv 与重写 IssueQueueVfdivVidiv_xs 双例化，逐拍比对全部 93 个输出。
// 激励与比对口径见 verif/ut/IssueQueue_common/gen_tb.py 文件头。
// 自动生成：verif/ut/IssueQueue_common/gen_tb.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  bit reset = 1;
  bit cmp_all = 0;
  always #5 clock = ~clock;
  longint checks = 0;
  longint errors = 0;
  logic [8:0] rob_cursor = 0;

  logic io_flush_valid;
  logic io_flush_bits_robIdx_flag;
  logic [7:0] io_flush_bits_robIdx_value;
  logic io_flush_bits_level;
  logic io_enq_0_valid;
  logic [31:0] io_enq_0_bits_instr;
  logic [49:0] io_enq_0_bits_pc;
  logic [9:0] io_enq_0_bits_foldpc;
  logic io_enq_0_bits_exceptionVec_0;
  logic io_enq_0_bits_exceptionVec_1;
  logic io_enq_0_bits_exceptionVec_2;
  logic io_enq_0_bits_exceptionVec_3;
  logic io_enq_0_bits_exceptionVec_4;
  logic io_enq_0_bits_exceptionVec_5;
  logic io_enq_0_bits_exceptionVec_6;
  logic io_enq_0_bits_exceptionVec_7;
  logic io_enq_0_bits_exceptionVec_8;
  logic io_enq_0_bits_exceptionVec_9;
  logic io_enq_0_bits_exceptionVec_10;
  logic io_enq_0_bits_exceptionVec_11;
  logic io_enq_0_bits_exceptionVec_12;
  logic io_enq_0_bits_exceptionVec_13;
  logic io_enq_0_bits_exceptionVec_14;
  logic io_enq_0_bits_exceptionVec_15;
  logic io_enq_0_bits_exceptionVec_16;
  logic io_enq_0_bits_exceptionVec_17;
  logic io_enq_0_bits_exceptionVec_18;
  logic io_enq_0_bits_exceptionVec_19;
  logic io_enq_0_bits_exceptionVec_20;
  logic io_enq_0_bits_exceptionVec_21;
  logic io_enq_0_bits_exceptionVec_22;
  logic io_enq_0_bits_exceptionVec_23;
  logic io_enq_0_bits_isFetchMalAddr;
  logic io_enq_0_bits_hasException;
  logic [3:0] io_enq_0_bits_trigger;
  logic io_enq_0_bits_preDecodeInfo_valid;
  logic io_enq_0_bits_preDecodeInfo_isRVC;
  logic [1:0] io_enq_0_bits_preDecodeInfo_brType;
  logic io_enq_0_bits_preDecodeInfo_isCall;
  logic io_enq_0_bits_preDecodeInfo_isRet;
  logic io_enq_0_bits_pred_taken;
  logic io_enq_0_bits_crossPageIPFFix;
  logic io_enq_0_bits_ftqPtr_flag;
  logic [5:0] io_enq_0_bits_ftqPtr_value;
  logic [3:0] io_enq_0_bits_ftqOffset;
  logic io_enq_0_bits_satpFlushFirstFetchFault;
  logic [3:0] io_enq_0_bits_srcType_0;
  logic [3:0] io_enq_0_bits_srcType_1;
  logic [3:0] io_enq_0_bits_srcType_2;
  logic [3:0] io_enq_0_bits_srcType_3;
  logic [3:0] io_enq_0_bits_srcType_4;
  logic [5:0] io_enq_0_bits_ldest;
  logic [34:0] io_enq_0_bits_fuType;
  logic [8:0] io_enq_0_bits_fuOpType;
  logic io_enq_0_bits_rfWen;
  logic io_enq_0_bits_fpWen;
  logic io_enq_0_bits_vecWen;
  logic io_enq_0_bits_v0Wen;
  logic io_enq_0_bits_vlWen;
  logic io_enq_0_bits_isXSTrap;
  logic io_enq_0_bits_waitForward;
  logic io_enq_0_bits_blockBackward;
  logic io_enq_0_bits_flushPipe;
  logic io_enq_0_bits_canRobCompress;
  logic [3:0] io_enq_0_bits_selImm;
  logic [31:0] io_enq_0_bits_imm;
  logic [1:0] io_enq_0_bits_fpu_typeTagOut;
  logic io_enq_0_bits_fpu_wflags;
  logic [1:0] io_enq_0_bits_fpu_typ;
  logic [1:0] io_enq_0_bits_fpu_fmt;
  logic [2:0] io_enq_0_bits_fpu_rm;
  logic io_enq_0_bits_vpu_vill;
  logic io_enq_0_bits_vpu_vma;
  logic io_enq_0_bits_vpu_vta;
  logic [1:0] io_enq_0_bits_vpu_vsew;
  logic [2:0] io_enq_0_bits_vpu_vlmul;
  logic io_enq_0_bits_vpu_specVill;
  logic io_enq_0_bits_vpu_specVma;
  logic io_enq_0_bits_vpu_specVta;
  logic [1:0] io_enq_0_bits_vpu_specVsew;
  logic [2:0] io_enq_0_bits_vpu_specVlmul;
  logic io_enq_0_bits_vpu_vm;
  logic [7:0] io_enq_0_bits_vpu_vstart;
  logic [2:0] io_enq_0_bits_vpu_frm;
  logic io_enq_0_bits_vpu_fpu_isFpToVecInst;
  logic io_enq_0_bits_vpu_fpu_isFP32Instr;
  logic io_enq_0_bits_vpu_fpu_isFP64Instr;
  logic io_enq_0_bits_vpu_fpu_isReduction;
  logic io_enq_0_bits_vpu_fpu_isFoldTo1_2;
  logic io_enq_0_bits_vpu_fpu_isFoldTo1_4;
  logic io_enq_0_bits_vpu_fpu_isFoldTo1_8;
  logic [1:0] io_enq_0_bits_vpu_vxrm;
  logic [6:0] io_enq_0_bits_vpu_vuopIdx;
  logic io_enq_0_bits_vpu_lastUop;
  logic [127:0] io_enq_0_bits_vpu_vmask;
  logic [7:0] io_enq_0_bits_vpu_vl;
  logic [2:0] io_enq_0_bits_vpu_nf;
  logic [1:0] io_enq_0_bits_vpu_veew;
  logic io_enq_0_bits_vpu_isReverse;
  logic io_enq_0_bits_vpu_isExt;
  logic io_enq_0_bits_vpu_isNarrow;
  logic io_enq_0_bits_vpu_isDstMask;
  logic io_enq_0_bits_vpu_isOpMask;
  logic io_enq_0_bits_vpu_isMove;
  logic io_enq_0_bits_vpu_isDependOldVd;
  logic io_enq_0_bits_vpu_isWritePartVd;
  logic io_enq_0_bits_vpu_isVleff;
  logic io_enq_0_bits_vlsInstr;
  logic io_enq_0_bits_wfflags;
  logic io_enq_0_bits_isMove;
  logic io_enq_0_bits_isDropAmocasSta;
  logic [6:0] io_enq_0_bits_uopIdx;
  logic io_enq_0_bits_isVset;
  logic io_enq_0_bits_firstUop;
  logic io_enq_0_bits_lastUop;
  logic [6:0] io_enq_0_bits_numUops;
  logic [6:0] io_enq_0_bits_numWB;
  logic [2:0] io_enq_0_bits_commitType;
  logic io_enq_0_bits_srcState_0;
  logic io_enq_0_bits_srcState_1;
  logic io_enq_0_bits_srcState_2;
  logic io_enq_0_bits_srcState_3;
  logic io_enq_0_bits_srcState_4;
  logic [7:0] io_enq_0_bits_psrc_0;
  logic [7:0] io_enq_0_bits_psrc_1;
  logic [7:0] io_enq_0_bits_psrc_2;
  logic [7:0] io_enq_0_bits_psrc_3;
  logic [7:0] io_enq_0_bits_psrc_4;
  logic [7:0] io_enq_0_bits_pdest;
  logic io_enq_0_bits_useRegCache_0;
  logic io_enq_0_bits_useRegCache_1;
  logic [4:0] io_enq_0_bits_regCacheIdx_0;
  logic [4:0] io_enq_0_bits_regCacheIdx_1;
  logic io_enq_0_bits_robIdx_flag;
  logic [7:0] io_enq_0_bits_robIdx_value;
  logic [2:0] io_enq_0_bits_instrSize;
  logic io_enq_0_bits_dirtyFs;
  logic io_enq_0_bits_dirtyVs;
  logic [3:0] io_enq_0_bits_traceBlockInPipe_itype;
  logic [3:0] io_enq_0_bits_traceBlockInPipe_iretire;
  logic io_enq_0_bits_traceBlockInPipe_ilastsize;
  logic io_enq_0_bits_eliminatedMove;
  logic io_enq_0_bits_snapshot;
  logic io_enq_0_bits_debugInfo_eliminatedMove;
  logic [63:0] io_enq_0_bits_debugInfo_renameTime;
  logic [63:0] io_enq_0_bits_debugInfo_dispatchTime;
  logic [63:0] io_enq_0_bits_debugInfo_enqRsTime;
  logic [63:0] io_enq_0_bits_debugInfo_selectTime;
  logic [63:0] io_enq_0_bits_debugInfo_issueTime;
  logic [63:0] io_enq_0_bits_debugInfo_writebackTime;
  logic [63:0] io_enq_0_bits_debugInfo_runahead_checkpoint_id;
  logic [63:0] io_enq_0_bits_debugInfo_tlbFirstReqTime;
  logic [63:0] io_enq_0_bits_debugInfo_tlbRespTime;
  logic [55:0] io_enq_0_bits_debug_seqNum_seqNum;
  logic [7:0] io_enq_0_bits_debug_seqNum_uopIdx;
  logic io_enq_0_bits_storeSetHit;
  logic io_enq_0_bits_waitForRobIdx_flag;
  logic [7:0] io_enq_0_bits_waitForRobIdx_value;
  logic io_enq_0_bits_loadWaitBit;
  logic io_enq_0_bits_loadWaitStrict;
  logic [4:0] io_enq_0_bits_ssid;
  logic io_enq_0_bits_lqIdx_flag;
  logic [6:0] io_enq_0_bits_lqIdx_value;
  logic io_enq_0_bits_sqIdx_flag;
  logic [5:0] io_enq_0_bits_sqIdx_value;
  logic io_enq_0_bits_singleStep;
  logic io_enq_0_bits_replayInst;
  logic [34:0] io_enq_0_bits_debug_fuType;
  logic io_enq_0_bits_debug_sim_trig;
  logic [4:0] io_enq_0_bits_numLsElem;
  logic io_enq_1_valid;
  logic [31:0] io_enq_1_bits_instr;
  logic [49:0] io_enq_1_bits_pc;
  logic [9:0] io_enq_1_bits_foldpc;
  logic io_enq_1_bits_exceptionVec_0;
  logic io_enq_1_bits_exceptionVec_1;
  logic io_enq_1_bits_exceptionVec_2;
  logic io_enq_1_bits_exceptionVec_3;
  logic io_enq_1_bits_exceptionVec_4;
  logic io_enq_1_bits_exceptionVec_5;
  logic io_enq_1_bits_exceptionVec_6;
  logic io_enq_1_bits_exceptionVec_7;
  logic io_enq_1_bits_exceptionVec_8;
  logic io_enq_1_bits_exceptionVec_9;
  logic io_enq_1_bits_exceptionVec_10;
  logic io_enq_1_bits_exceptionVec_11;
  logic io_enq_1_bits_exceptionVec_12;
  logic io_enq_1_bits_exceptionVec_13;
  logic io_enq_1_bits_exceptionVec_14;
  logic io_enq_1_bits_exceptionVec_15;
  logic io_enq_1_bits_exceptionVec_16;
  logic io_enq_1_bits_exceptionVec_17;
  logic io_enq_1_bits_exceptionVec_18;
  logic io_enq_1_bits_exceptionVec_19;
  logic io_enq_1_bits_exceptionVec_20;
  logic io_enq_1_bits_exceptionVec_21;
  logic io_enq_1_bits_exceptionVec_22;
  logic io_enq_1_bits_exceptionVec_23;
  logic io_enq_1_bits_isFetchMalAddr;
  logic io_enq_1_bits_hasException;
  logic [3:0] io_enq_1_bits_trigger;
  logic io_enq_1_bits_preDecodeInfo_valid;
  logic io_enq_1_bits_preDecodeInfo_isRVC;
  logic [1:0] io_enq_1_bits_preDecodeInfo_brType;
  logic io_enq_1_bits_preDecodeInfo_isCall;
  logic io_enq_1_bits_preDecodeInfo_isRet;
  logic io_enq_1_bits_pred_taken;
  logic io_enq_1_bits_crossPageIPFFix;
  logic io_enq_1_bits_ftqPtr_flag;
  logic [5:0] io_enq_1_bits_ftqPtr_value;
  logic [3:0] io_enq_1_bits_ftqOffset;
  logic io_enq_1_bits_satpFlushFirstFetchFault;
  logic [3:0] io_enq_1_bits_srcType_0;
  logic [3:0] io_enq_1_bits_srcType_1;
  logic [3:0] io_enq_1_bits_srcType_2;
  logic [3:0] io_enq_1_bits_srcType_3;
  logic [3:0] io_enq_1_bits_srcType_4;
  logic [5:0] io_enq_1_bits_ldest;
  logic [34:0] io_enq_1_bits_fuType;
  logic [8:0] io_enq_1_bits_fuOpType;
  logic io_enq_1_bits_rfWen;
  logic io_enq_1_bits_fpWen;
  logic io_enq_1_bits_vecWen;
  logic io_enq_1_bits_v0Wen;
  logic io_enq_1_bits_vlWen;
  logic io_enq_1_bits_isXSTrap;
  logic io_enq_1_bits_waitForward;
  logic io_enq_1_bits_blockBackward;
  logic io_enq_1_bits_flushPipe;
  logic io_enq_1_bits_canRobCompress;
  logic [3:0] io_enq_1_bits_selImm;
  logic [31:0] io_enq_1_bits_imm;
  logic [1:0] io_enq_1_bits_fpu_typeTagOut;
  logic io_enq_1_bits_fpu_wflags;
  logic [1:0] io_enq_1_bits_fpu_typ;
  logic [1:0] io_enq_1_bits_fpu_fmt;
  logic [2:0] io_enq_1_bits_fpu_rm;
  logic io_enq_1_bits_vpu_vill;
  logic io_enq_1_bits_vpu_vma;
  logic io_enq_1_bits_vpu_vta;
  logic [1:0] io_enq_1_bits_vpu_vsew;
  logic [2:0] io_enq_1_bits_vpu_vlmul;
  logic io_enq_1_bits_vpu_specVill;
  logic io_enq_1_bits_vpu_specVma;
  logic io_enq_1_bits_vpu_specVta;
  logic [1:0] io_enq_1_bits_vpu_specVsew;
  logic [2:0] io_enq_1_bits_vpu_specVlmul;
  logic io_enq_1_bits_vpu_vm;
  logic [7:0] io_enq_1_bits_vpu_vstart;
  logic [2:0] io_enq_1_bits_vpu_frm;
  logic io_enq_1_bits_vpu_fpu_isFpToVecInst;
  logic io_enq_1_bits_vpu_fpu_isFP32Instr;
  logic io_enq_1_bits_vpu_fpu_isFP64Instr;
  logic io_enq_1_bits_vpu_fpu_isReduction;
  logic io_enq_1_bits_vpu_fpu_isFoldTo1_2;
  logic io_enq_1_bits_vpu_fpu_isFoldTo1_4;
  logic io_enq_1_bits_vpu_fpu_isFoldTo1_8;
  logic [1:0] io_enq_1_bits_vpu_vxrm;
  logic [6:0] io_enq_1_bits_vpu_vuopIdx;
  logic io_enq_1_bits_vpu_lastUop;
  logic [127:0] io_enq_1_bits_vpu_vmask;
  logic [7:0] io_enq_1_bits_vpu_vl;
  logic [2:0] io_enq_1_bits_vpu_nf;
  logic [1:0] io_enq_1_bits_vpu_veew;
  logic io_enq_1_bits_vpu_isReverse;
  logic io_enq_1_bits_vpu_isExt;
  logic io_enq_1_bits_vpu_isNarrow;
  logic io_enq_1_bits_vpu_isDstMask;
  logic io_enq_1_bits_vpu_isOpMask;
  logic io_enq_1_bits_vpu_isMove;
  logic io_enq_1_bits_vpu_isDependOldVd;
  logic io_enq_1_bits_vpu_isWritePartVd;
  logic io_enq_1_bits_vpu_isVleff;
  logic io_enq_1_bits_vlsInstr;
  logic io_enq_1_bits_wfflags;
  logic io_enq_1_bits_isMove;
  logic io_enq_1_bits_isDropAmocasSta;
  logic [6:0] io_enq_1_bits_uopIdx;
  logic io_enq_1_bits_isVset;
  logic io_enq_1_bits_firstUop;
  logic io_enq_1_bits_lastUop;
  logic [6:0] io_enq_1_bits_numUops;
  logic [6:0] io_enq_1_bits_numWB;
  logic [2:0] io_enq_1_bits_commitType;
  logic io_enq_1_bits_srcState_0;
  logic io_enq_1_bits_srcState_1;
  logic io_enq_1_bits_srcState_2;
  logic io_enq_1_bits_srcState_3;
  logic io_enq_1_bits_srcState_4;
  logic [7:0] io_enq_1_bits_psrc_0;
  logic [7:0] io_enq_1_bits_psrc_1;
  logic [7:0] io_enq_1_bits_psrc_2;
  logic [7:0] io_enq_1_bits_psrc_3;
  logic [7:0] io_enq_1_bits_psrc_4;
  logic [7:0] io_enq_1_bits_pdest;
  logic io_enq_1_bits_useRegCache_0;
  logic io_enq_1_bits_useRegCache_1;
  logic [4:0] io_enq_1_bits_regCacheIdx_0;
  logic [4:0] io_enq_1_bits_regCacheIdx_1;
  logic io_enq_1_bits_robIdx_flag;
  logic [7:0] io_enq_1_bits_robIdx_value;
  logic [2:0] io_enq_1_bits_instrSize;
  logic io_enq_1_bits_dirtyFs;
  logic io_enq_1_bits_dirtyVs;
  logic [3:0] io_enq_1_bits_traceBlockInPipe_itype;
  logic [3:0] io_enq_1_bits_traceBlockInPipe_iretire;
  logic io_enq_1_bits_traceBlockInPipe_ilastsize;
  logic io_enq_1_bits_eliminatedMove;
  logic io_enq_1_bits_snapshot;
  logic io_enq_1_bits_debugInfo_eliminatedMove;
  logic [63:0] io_enq_1_bits_debugInfo_renameTime;
  logic [63:0] io_enq_1_bits_debugInfo_dispatchTime;
  logic [63:0] io_enq_1_bits_debugInfo_enqRsTime;
  logic [63:0] io_enq_1_bits_debugInfo_selectTime;
  logic [63:0] io_enq_1_bits_debugInfo_issueTime;
  logic [63:0] io_enq_1_bits_debugInfo_writebackTime;
  logic [63:0] io_enq_1_bits_debugInfo_runahead_checkpoint_id;
  logic [63:0] io_enq_1_bits_debugInfo_tlbFirstReqTime;
  logic [63:0] io_enq_1_bits_debugInfo_tlbRespTime;
  logic [55:0] io_enq_1_bits_debug_seqNum_seqNum;
  logic [7:0] io_enq_1_bits_debug_seqNum_uopIdx;
  logic io_enq_1_bits_storeSetHit;
  logic io_enq_1_bits_waitForRobIdx_flag;
  logic [7:0] io_enq_1_bits_waitForRobIdx_value;
  logic io_enq_1_bits_loadWaitBit;
  logic io_enq_1_bits_loadWaitStrict;
  logic [4:0] io_enq_1_bits_ssid;
  logic io_enq_1_bits_lqIdx_flag;
  logic [6:0] io_enq_1_bits_lqIdx_value;
  logic io_enq_1_bits_sqIdx_flag;
  logic [5:0] io_enq_1_bits_sqIdx_value;
  logic io_enq_1_bits_singleStep;
  logic io_enq_1_bits_replayInst;
  logic [34:0] io_enq_1_bits_debug_fuType;
  logic io_enq_1_bits_debug_sim_trig;
  logic [4:0] io_enq_1_bits_numLsElem;
  logic io_og0Resp_0_valid;
  logic io_og1Resp_0_valid;
  logic io_og2Resp_0_valid;
  logic [1:0] io_og2Resp_0_bits_resp;
  logic io_wakeupFromWB_15_valid;
  logic io_wakeupFromWB_15_bits_vlWen;
  logic [7:0] io_wakeupFromWB_15_bits_pdest;
  logic io_wakeupFromWB_14_valid;
  logic io_wakeupFromWB_14_bits_vlWen;
  logic [7:0] io_wakeupFromWB_14_bits_pdest;
  logic io_wakeupFromWB_13_valid;
  logic io_wakeupFromWB_13_bits_vlWen;
  logic [7:0] io_wakeupFromWB_13_bits_pdest;
  logic io_wakeupFromWB_12_valid;
  logic io_wakeupFromWB_12_bits_vlWen;
  logic [7:0] io_wakeupFromWB_12_bits_pdest;
  logic io_wakeupFromWB_11_valid;
  logic io_wakeupFromWB_11_bits_v0Wen;
  logic [7:0] io_wakeupFromWB_11_bits_pdest;
  logic io_wakeupFromWB_10_valid;
  logic io_wakeupFromWB_10_bits_v0Wen;
  logic [7:0] io_wakeupFromWB_10_bits_pdest;
  logic io_wakeupFromWB_9_valid;
  logic io_wakeupFromWB_9_bits_v0Wen;
  logic [7:0] io_wakeupFromWB_9_bits_pdest;
  logic io_wakeupFromWB_8_valid;
  logic io_wakeupFromWB_8_bits_v0Wen;
  logic [7:0] io_wakeupFromWB_8_bits_pdest;
  logic io_wakeupFromWB_7_valid;
  logic io_wakeupFromWB_7_bits_v0Wen;
  logic [7:0] io_wakeupFromWB_7_bits_pdest;
  logic io_wakeupFromWB_6_valid;
  logic io_wakeupFromWB_6_bits_v0Wen;
  logic [7:0] io_wakeupFromWB_6_bits_pdest;
  logic io_wakeupFromWB_5_valid;
  logic io_wakeupFromWB_5_bits_vecWen;
  logic [7:0] io_wakeupFromWB_5_bits_pdest;
  logic io_wakeupFromWB_4_valid;
  logic io_wakeupFromWB_4_bits_vecWen;
  logic [7:0] io_wakeupFromWB_4_bits_pdest;
  logic io_wakeupFromWB_3_valid;
  logic io_wakeupFromWB_3_bits_vecWen;
  logic [7:0] io_wakeupFromWB_3_bits_pdest;
  logic io_wakeupFromWB_2_valid;
  logic io_wakeupFromWB_2_bits_vecWen;
  logic [7:0] io_wakeupFromWB_2_bits_pdest;
  logic io_wakeupFromWB_1_valid;
  logic io_wakeupFromWB_1_bits_vecWen;
  logic [7:0] io_wakeupFromWB_1_bits_pdest;
  logic io_wakeupFromWB_0_valid;
  logic io_wakeupFromWB_0_bits_vecWen;
  logic [7:0] io_wakeupFromWB_0_bits_pdest;
  logic io_wakeupFromWBDelayed_15_valid;
  logic io_wakeupFromWBDelayed_15_bits_vlWen;
  logic [7:0] io_wakeupFromWBDelayed_15_bits_pdest;
  logic io_wakeupFromWBDelayed_14_valid;
  logic io_wakeupFromWBDelayed_14_bits_vlWen;
  logic [7:0] io_wakeupFromWBDelayed_14_bits_pdest;
  logic io_wakeupFromWBDelayed_13_valid;
  logic io_wakeupFromWBDelayed_13_bits_vlWen;
  logic [7:0] io_wakeupFromWBDelayed_13_bits_pdest;
  logic io_wakeupFromWBDelayed_12_valid;
  logic io_wakeupFromWBDelayed_12_bits_vlWen;
  logic [7:0] io_wakeupFromWBDelayed_12_bits_pdest;
  logic io_wakeupFromWBDelayed_11_valid;
  logic io_wakeupFromWBDelayed_11_bits_v0Wen;
  logic [7:0] io_wakeupFromWBDelayed_11_bits_pdest;
  logic io_wakeupFromWBDelayed_10_valid;
  logic io_wakeupFromWBDelayed_10_bits_v0Wen;
  logic [7:0] io_wakeupFromWBDelayed_10_bits_pdest;
  logic io_wakeupFromWBDelayed_9_valid;
  logic io_wakeupFromWBDelayed_9_bits_v0Wen;
  logic [7:0] io_wakeupFromWBDelayed_9_bits_pdest;
  logic io_wakeupFromWBDelayed_8_valid;
  logic io_wakeupFromWBDelayed_8_bits_v0Wen;
  logic [7:0] io_wakeupFromWBDelayed_8_bits_pdest;
  logic io_wakeupFromWBDelayed_7_valid;
  logic io_wakeupFromWBDelayed_7_bits_v0Wen;
  logic [7:0] io_wakeupFromWBDelayed_7_bits_pdest;
  logic io_wakeupFromWBDelayed_6_valid;
  logic io_wakeupFromWBDelayed_6_bits_v0Wen;
  logic [7:0] io_wakeupFromWBDelayed_6_bits_pdest;
  logic io_wakeupFromWBDelayed_5_valid;
  logic io_wakeupFromWBDelayed_5_bits_vecWen;
  logic [7:0] io_wakeupFromWBDelayed_5_bits_pdest;
  logic io_wakeupFromWBDelayed_4_valid;
  logic io_wakeupFromWBDelayed_4_bits_vecWen;
  logic [7:0] io_wakeupFromWBDelayed_4_bits_pdest;
  logic io_wakeupFromWBDelayed_3_valid;
  logic io_wakeupFromWBDelayed_3_bits_vecWen;
  logic [7:0] io_wakeupFromWBDelayed_3_bits_pdest;
  logic io_wakeupFromWBDelayed_2_valid;
  logic io_wakeupFromWBDelayed_2_bits_vecWen;
  logic [7:0] io_wakeupFromWBDelayed_2_bits_pdest;
  logic io_wakeupFromWBDelayed_1_valid;
  logic io_wakeupFromWBDelayed_1_bits_vecWen;
  logic [7:0] io_wakeupFromWBDelayed_1_bits_pdest;
  logic io_wakeupFromWBDelayed_0_valid;
  logic io_wakeupFromWBDelayed_0_bits_vecWen;
  logic [7:0] io_wakeupFromWBDelayed_0_bits_pdest;
  logic io_vlFromIntIsZero;
  logic io_vlFromIntIsVlmax;
  logic io_vlFromVfIsZero;
  logic io_vlFromVfIsVlmax;
  logic io_deqDelay_0_ready;
  wire g_io_enq_0_ready, i_io_enq_0_ready;
  wire g_io_enq_1_ready, i_io_enq_1_ready;
  wire g_io_deqDelay_0_valid, i_io_deqDelay_0_valid;
  wire [6:0] g_io_deqDelay_0_bits_rf_4_0_addr, i_io_deqDelay_0_bits_rf_4_0_addr;
  wire [2:0] g_io_deqDelay_0_bits_rf_4_0_srcType, i_io_deqDelay_0_bits_rf_4_0_srcType;
  wire [6:0] g_io_deqDelay_0_bits_rf_3_0_addr, i_io_deqDelay_0_bits_rf_3_0_addr;
  wire [2:0] g_io_deqDelay_0_bits_rf_3_0_srcType, i_io_deqDelay_0_bits_rf_3_0_srcType;
  wire [6:0] g_io_deqDelay_0_bits_rf_2_0_addr, i_io_deqDelay_0_bits_rf_2_0_addr;
  wire [2:0] g_io_deqDelay_0_bits_rf_2_0_srcType, i_io_deqDelay_0_bits_rf_2_0_srcType;
  wire [6:0] g_io_deqDelay_0_bits_rf_1_0_addr, i_io_deqDelay_0_bits_rf_1_0_addr;
  wire [2:0] g_io_deqDelay_0_bits_rf_1_0_srcType, i_io_deqDelay_0_bits_rf_1_0_srcType;
  wire [6:0] g_io_deqDelay_0_bits_rf_0_0_addr, i_io_deqDelay_0_bits_rf_0_0_addr;
  wire [2:0] g_io_deqDelay_0_bits_rf_0_0_srcType, i_io_deqDelay_0_bits_rf_0_0_srcType;
  wire [3:0] g_io_deqDelay_0_bits_srcType_0, i_io_deqDelay_0_bits_srcType_0;
  wire [3:0] g_io_deqDelay_0_bits_srcType_1, i_io_deqDelay_0_bits_srcType_1;
  wire [3:0] g_io_deqDelay_0_bits_srcType_2, i_io_deqDelay_0_bits_srcType_2;
  wire [3:0] g_io_deqDelay_0_bits_srcType_3, i_io_deqDelay_0_bits_srcType_3;
  wire [3:0] g_io_deqDelay_0_bits_srcType_4, i_io_deqDelay_0_bits_srcType_4;
  wire [3:0] g_io_deqDelay_0_bits_immType, i_io_deqDelay_0_bits_immType;
  wire [34:0] g_io_deqDelay_0_bits_common_fuType, i_io_deqDelay_0_bits_common_fuType;
  wire [8:0] g_io_deqDelay_0_bits_common_fuOpType, i_io_deqDelay_0_bits_common_fuOpType;
  wire [127:0] g_io_deqDelay_0_bits_common_src_0, i_io_deqDelay_0_bits_common_src_0;
  wire [127:0] g_io_deqDelay_0_bits_common_src_1, i_io_deqDelay_0_bits_common_src_1;
  wire [127:0] g_io_deqDelay_0_bits_common_src_2, i_io_deqDelay_0_bits_common_src_2;
  wire [127:0] g_io_deqDelay_0_bits_common_src_3, i_io_deqDelay_0_bits_common_src_3;
  wire [127:0] g_io_deqDelay_0_bits_common_src_4, i_io_deqDelay_0_bits_common_src_4;
  wire [63:0] g_io_deqDelay_0_bits_common_imm, i_io_deqDelay_0_bits_common_imm;
  wire g_io_deqDelay_0_bits_common_robIdx_flag, i_io_deqDelay_0_bits_common_robIdx_flag;
  wire [7:0] g_io_deqDelay_0_bits_common_robIdx_value, i_io_deqDelay_0_bits_common_robIdx_value;
  wire [3:0] g_io_deqDelay_0_bits_common_iqIdx, i_io_deqDelay_0_bits_common_iqIdx;
  wire g_io_deqDelay_0_bits_common_isFirstIssue, i_io_deqDelay_0_bits_common_isFirstIssue;
  wire [6:0] g_io_deqDelay_0_bits_common_pdest, i_io_deqDelay_0_bits_common_pdest;
  wire g_io_deqDelay_0_bits_common_vecWen, i_io_deqDelay_0_bits_common_vecWen;
  wire g_io_deqDelay_0_bits_common_v0Wen, i_io_deqDelay_0_bits_common_v0Wen;
  wire [1:0] g_io_deqDelay_0_bits_common_fpu_typeTagOut, i_io_deqDelay_0_bits_common_fpu_typeTagOut;
  wire g_io_deqDelay_0_bits_common_fpu_wflags, i_io_deqDelay_0_bits_common_fpu_wflags;
  wire [1:0] g_io_deqDelay_0_bits_common_fpu_typ, i_io_deqDelay_0_bits_common_fpu_typ;
  wire [1:0] g_io_deqDelay_0_bits_common_fpu_fmt, i_io_deqDelay_0_bits_common_fpu_fmt;
  wire [2:0] g_io_deqDelay_0_bits_common_fpu_rm, i_io_deqDelay_0_bits_common_fpu_rm;
  wire g_io_deqDelay_0_bits_common_vpu_vill, i_io_deqDelay_0_bits_common_vpu_vill;
  wire g_io_deqDelay_0_bits_common_vpu_vma, i_io_deqDelay_0_bits_common_vpu_vma;
  wire g_io_deqDelay_0_bits_common_vpu_vta, i_io_deqDelay_0_bits_common_vpu_vta;
  wire [1:0] g_io_deqDelay_0_bits_common_vpu_vsew, i_io_deqDelay_0_bits_common_vpu_vsew;
  wire [2:0] g_io_deqDelay_0_bits_common_vpu_vlmul, i_io_deqDelay_0_bits_common_vpu_vlmul;
  wire g_io_deqDelay_0_bits_common_vpu_specVill, i_io_deqDelay_0_bits_common_vpu_specVill;
  wire g_io_deqDelay_0_bits_common_vpu_specVma, i_io_deqDelay_0_bits_common_vpu_specVma;
  wire g_io_deqDelay_0_bits_common_vpu_specVta, i_io_deqDelay_0_bits_common_vpu_specVta;
  wire [1:0] g_io_deqDelay_0_bits_common_vpu_specVsew, i_io_deqDelay_0_bits_common_vpu_specVsew;
  wire [2:0] g_io_deqDelay_0_bits_common_vpu_specVlmul, i_io_deqDelay_0_bits_common_vpu_specVlmul;
  wire g_io_deqDelay_0_bits_common_vpu_vm, i_io_deqDelay_0_bits_common_vpu_vm;
  wire [7:0] g_io_deqDelay_0_bits_common_vpu_vstart, i_io_deqDelay_0_bits_common_vpu_vstart;
  wire [2:0] g_io_deqDelay_0_bits_common_vpu_frm, i_io_deqDelay_0_bits_common_vpu_frm;
  wire g_io_deqDelay_0_bits_common_vpu_fpu_isFpToVecInst, i_io_deqDelay_0_bits_common_vpu_fpu_isFpToVecInst;
  wire g_io_deqDelay_0_bits_common_vpu_fpu_isFP32Instr, i_io_deqDelay_0_bits_common_vpu_fpu_isFP32Instr;
  wire g_io_deqDelay_0_bits_common_vpu_fpu_isFP64Instr, i_io_deqDelay_0_bits_common_vpu_fpu_isFP64Instr;
  wire g_io_deqDelay_0_bits_common_vpu_fpu_isReduction, i_io_deqDelay_0_bits_common_vpu_fpu_isReduction;
  wire g_io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_2, i_io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_2;
  wire g_io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_4, i_io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_4;
  wire g_io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_8, i_io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_8;
  wire [1:0] g_io_deqDelay_0_bits_common_vpu_vxrm, i_io_deqDelay_0_bits_common_vpu_vxrm;
  wire [6:0] g_io_deqDelay_0_bits_common_vpu_vuopIdx, i_io_deqDelay_0_bits_common_vpu_vuopIdx;
  wire g_io_deqDelay_0_bits_common_vpu_lastUop, i_io_deqDelay_0_bits_common_vpu_lastUop;
  wire [127:0] g_io_deqDelay_0_bits_common_vpu_vmask, i_io_deqDelay_0_bits_common_vpu_vmask;
  wire [7:0] g_io_deqDelay_0_bits_common_vpu_vl, i_io_deqDelay_0_bits_common_vpu_vl;
  wire [2:0] g_io_deqDelay_0_bits_common_vpu_nf, i_io_deqDelay_0_bits_common_vpu_nf;
  wire [1:0] g_io_deqDelay_0_bits_common_vpu_veew, i_io_deqDelay_0_bits_common_vpu_veew;
  wire g_io_deqDelay_0_bits_common_vpu_isReverse, i_io_deqDelay_0_bits_common_vpu_isReverse;
  wire g_io_deqDelay_0_bits_common_vpu_isExt, i_io_deqDelay_0_bits_common_vpu_isExt;
  wire g_io_deqDelay_0_bits_common_vpu_isNarrow, i_io_deqDelay_0_bits_common_vpu_isNarrow;
  wire g_io_deqDelay_0_bits_common_vpu_isDstMask, i_io_deqDelay_0_bits_common_vpu_isDstMask;
  wire g_io_deqDelay_0_bits_common_vpu_isOpMask, i_io_deqDelay_0_bits_common_vpu_isOpMask;
  wire g_io_deqDelay_0_bits_common_vpu_isMove, i_io_deqDelay_0_bits_common_vpu_isMove;
  wire g_io_deqDelay_0_bits_common_vpu_isDependOldVd, i_io_deqDelay_0_bits_common_vpu_isDependOldVd;
  wire g_io_deqDelay_0_bits_common_vpu_isWritePartVd, i_io_deqDelay_0_bits_common_vpu_isWritePartVd;
  wire g_io_deqDelay_0_bits_common_vpu_isVleff, i_io_deqDelay_0_bits_common_vpu_isVleff;
  wire [3:0] g_io_deqDelay_0_bits_common_dataSources_0_value, i_io_deqDelay_0_bits_common_dataSources_0_value;
  wire [3:0] g_io_deqDelay_0_bits_common_dataSources_1_value, i_io_deqDelay_0_bits_common_dataSources_1_value;
  wire [3:0] g_io_deqDelay_0_bits_common_dataSources_2_value, i_io_deqDelay_0_bits_common_dataSources_2_value;
  wire [3:0] g_io_deqDelay_0_bits_common_dataSources_3_value, i_io_deqDelay_0_bits_common_dataSources_3_value;
  wire [3:0] g_io_deqDelay_0_bits_common_dataSources_4_value, i_io_deqDelay_0_bits_common_dataSources_4_value;
  wire g_io_deqDelay_0_bits_common_perfDebugInfo_eliminatedMove, i_io_deqDelay_0_bits_common_perfDebugInfo_eliminatedMove;
  wire [63:0] g_io_deqDelay_0_bits_common_perfDebugInfo_renameTime, i_io_deqDelay_0_bits_common_perfDebugInfo_renameTime;
  wire [63:0] g_io_deqDelay_0_bits_common_perfDebugInfo_dispatchTime, i_io_deqDelay_0_bits_common_perfDebugInfo_dispatchTime;
  wire [63:0] g_io_deqDelay_0_bits_common_perfDebugInfo_enqRsTime, i_io_deqDelay_0_bits_common_perfDebugInfo_enqRsTime;
  wire [63:0] g_io_deqDelay_0_bits_common_perfDebugInfo_selectTime, i_io_deqDelay_0_bits_common_perfDebugInfo_selectTime;
  wire [63:0] g_io_deqDelay_0_bits_common_perfDebugInfo_issueTime, i_io_deqDelay_0_bits_common_perfDebugInfo_issueTime;
  wire [63:0] g_io_deqDelay_0_bits_common_perfDebugInfo_writebackTime, i_io_deqDelay_0_bits_common_perfDebugInfo_writebackTime;
  wire [63:0] g_io_deqDelay_0_bits_common_perfDebugInfo_runahead_checkpoint_id, i_io_deqDelay_0_bits_common_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] g_io_deqDelay_0_bits_common_perfDebugInfo_tlbFirstReqTime, i_io_deqDelay_0_bits_common_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] g_io_deqDelay_0_bits_common_perfDebugInfo_tlbRespTime, i_io_deqDelay_0_bits_common_perfDebugInfo_tlbRespTime;
  wire [55:0] g_io_deqDelay_0_bits_common_debug_seqNum_seqNum, i_io_deqDelay_0_bits_common_debug_seqNum_seqNum;
  wire [7:0] g_io_deqDelay_0_bits_common_debug_seqNum_uopIdx, i_io_deqDelay_0_bits_common_debug_seqNum_uopIdx;
  wire [9:0] g_io_deqDelay_0_bits_addrOH, i_io_deqDelay_0_bits_addrOH;

  IssueQueueVfdivVidiv u_g (
    .clock(clock),
    .reset(reset),
    .io_flush_valid(io_flush_valid),
    .io_flush_bits_robIdx_flag(io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value(io_flush_bits_robIdx_value),
    .io_flush_bits_level(io_flush_bits_level),
    .io_enq_0_valid(io_enq_0_valid),
    .io_enq_0_bits_instr(io_enq_0_bits_instr),
    .io_enq_0_bits_pc(io_enq_0_bits_pc),
    .io_enq_0_bits_foldpc(io_enq_0_bits_foldpc),
    .io_enq_0_bits_exceptionVec_0(io_enq_0_bits_exceptionVec_0),
    .io_enq_0_bits_exceptionVec_1(io_enq_0_bits_exceptionVec_1),
    .io_enq_0_bits_exceptionVec_2(io_enq_0_bits_exceptionVec_2),
    .io_enq_0_bits_exceptionVec_3(io_enq_0_bits_exceptionVec_3),
    .io_enq_0_bits_exceptionVec_4(io_enq_0_bits_exceptionVec_4),
    .io_enq_0_bits_exceptionVec_5(io_enq_0_bits_exceptionVec_5),
    .io_enq_0_bits_exceptionVec_6(io_enq_0_bits_exceptionVec_6),
    .io_enq_0_bits_exceptionVec_7(io_enq_0_bits_exceptionVec_7),
    .io_enq_0_bits_exceptionVec_8(io_enq_0_bits_exceptionVec_8),
    .io_enq_0_bits_exceptionVec_9(io_enq_0_bits_exceptionVec_9),
    .io_enq_0_bits_exceptionVec_10(io_enq_0_bits_exceptionVec_10),
    .io_enq_0_bits_exceptionVec_11(io_enq_0_bits_exceptionVec_11),
    .io_enq_0_bits_exceptionVec_12(io_enq_0_bits_exceptionVec_12),
    .io_enq_0_bits_exceptionVec_13(io_enq_0_bits_exceptionVec_13),
    .io_enq_0_bits_exceptionVec_14(io_enq_0_bits_exceptionVec_14),
    .io_enq_0_bits_exceptionVec_15(io_enq_0_bits_exceptionVec_15),
    .io_enq_0_bits_exceptionVec_16(io_enq_0_bits_exceptionVec_16),
    .io_enq_0_bits_exceptionVec_17(io_enq_0_bits_exceptionVec_17),
    .io_enq_0_bits_exceptionVec_18(io_enq_0_bits_exceptionVec_18),
    .io_enq_0_bits_exceptionVec_19(io_enq_0_bits_exceptionVec_19),
    .io_enq_0_bits_exceptionVec_20(io_enq_0_bits_exceptionVec_20),
    .io_enq_0_bits_exceptionVec_21(io_enq_0_bits_exceptionVec_21),
    .io_enq_0_bits_exceptionVec_22(io_enq_0_bits_exceptionVec_22),
    .io_enq_0_bits_exceptionVec_23(io_enq_0_bits_exceptionVec_23),
    .io_enq_0_bits_isFetchMalAddr(io_enq_0_bits_isFetchMalAddr),
    .io_enq_0_bits_hasException(io_enq_0_bits_hasException),
    .io_enq_0_bits_trigger(io_enq_0_bits_trigger),
    .io_enq_0_bits_preDecodeInfo_valid(io_enq_0_bits_preDecodeInfo_valid),
    .io_enq_0_bits_preDecodeInfo_isRVC(io_enq_0_bits_preDecodeInfo_isRVC),
    .io_enq_0_bits_preDecodeInfo_brType(io_enq_0_bits_preDecodeInfo_brType),
    .io_enq_0_bits_preDecodeInfo_isCall(io_enq_0_bits_preDecodeInfo_isCall),
    .io_enq_0_bits_preDecodeInfo_isRet(io_enq_0_bits_preDecodeInfo_isRet),
    .io_enq_0_bits_pred_taken(io_enq_0_bits_pred_taken),
    .io_enq_0_bits_crossPageIPFFix(io_enq_0_bits_crossPageIPFFix),
    .io_enq_0_bits_ftqPtr_flag(io_enq_0_bits_ftqPtr_flag),
    .io_enq_0_bits_ftqPtr_value(io_enq_0_bits_ftqPtr_value),
    .io_enq_0_bits_ftqOffset(io_enq_0_bits_ftqOffset),
    .io_enq_0_bits_satpFlushFirstFetchFault(io_enq_0_bits_satpFlushFirstFetchFault),
    .io_enq_0_bits_srcType_0(io_enq_0_bits_srcType_0),
    .io_enq_0_bits_srcType_1(io_enq_0_bits_srcType_1),
    .io_enq_0_bits_srcType_2(io_enq_0_bits_srcType_2),
    .io_enq_0_bits_srcType_3(io_enq_0_bits_srcType_3),
    .io_enq_0_bits_srcType_4(io_enq_0_bits_srcType_4),
    .io_enq_0_bits_ldest(io_enq_0_bits_ldest),
    .io_enq_0_bits_fuType(io_enq_0_bits_fuType),
    .io_enq_0_bits_fuOpType(io_enq_0_bits_fuOpType),
    .io_enq_0_bits_rfWen(io_enq_0_bits_rfWen),
    .io_enq_0_bits_fpWen(io_enq_0_bits_fpWen),
    .io_enq_0_bits_vecWen(io_enq_0_bits_vecWen),
    .io_enq_0_bits_v0Wen(io_enq_0_bits_v0Wen),
    .io_enq_0_bits_vlWen(io_enq_0_bits_vlWen),
    .io_enq_0_bits_isXSTrap(io_enq_0_bits_isXSTrap),
    .io_enq_0_bits_waitForward(io_enq_0_bits_waitForward),
    .io_enq_0_bits_blockBackward(io_enq_0_bits_blockBackward),
    .io_enq_0_bits_flushPipe(io_enq_0_bits_flushPipe),
    .io_enq_0_bits_canRobCompress(io_enq_0_bits_canRobCompress),
    .io_enq_0_bits_selImm(io_enq_0_bits_selImm),
    .io_enq_0_bits_imm(io_enq_0_bits_imm),
    .io_enq_0_bits_fpu_typeTagOut(io_enq_0_bits_fpu_typeTagOut),
    .io_enq_0_bits_fpu_wflags(io_enq_0_bits_fpu_wflags),
    .io_enq_0_bits_fpu_typ(io_enq_0_bits_fpu_typ),
    .io_enq_0_bits_fpu_fmt(io_enq_0_bits_fpu_fmt),
    .io_enq_0_bits_fpu_rm(io_enq_0_bits_fpu_rm),
    .io_enq_0_bits_vpu_vill(io_enq_0_bits_vpu_vill),
    .io_enq_0_bits_vpu_vma(io_enq_0_bits_vpu_vma),
    .io_enq_0_bits_vpu_vta(io_enq_0_bits_vpu_vta),
    .io_enq_0_bits_vpu_vsew(io_enq_0_bits_vpu_vsew),
    .io_enq_0_bits_vpu_vlmul(io_enq_0_bits_vpu_vlmul),
    .io_enq_0_bits_vpu_specVill(io_enq_0_bits_vpu_specVill),
    .io_enq_0_bits_vpu_specVma(io_enq_0_bits_vpu_specVma),
    .io_enq_0_bits_vpu_specVta(io_enq_0_bits_vpu_specVta),
    .io_enq_0_bits_vpu_specVsew(io_enq_0_bits_vpu_specVsew),
    .io_enq_0_bits_vpu_specVlmul(io_enq_0_bits_vpu_specVlmul),
    .io_enq_0_bits_vpu_vm(io_enq_0_bits_vpu_vm),
    .io_enq_0_bits_vpu_vstart(io_enq_0_bits_vpu_vstart),
    .io_enq_0_bits_vpu_frm(io_enq_0_bits_vpu_frm),
    .io_enq_0_bits_vpu_fpu_isFpToVecInst(io_enq_0_bits_vpu_fpu_isFpToVecInst),
    .io_enq_0_bits_vpu_fpu_isFP32Instr(io_enq_0_bits_vpu_fpu_isFP32Instr),
    .io_enq_0_bits_vpu_fpu_isFP64Instr(io_enq_0_bits_vpu_fpu_isFP64Instr),
    .io_enq_0_bits_vpu_fpu_isReduction(io_enq_0_bits_vpu_fpu_isReduction),
    .io_enq_0_bits_vpu_fpu_isFoldTo1_2(io_enq_0_bits_vpu_fpu_isFoldTo1_2),
    .io_enq_0_bits_vpu_fpu_isFoldTo1_4(io_enq_0_bits_vpu_fpu_isFoldTo1_4),
    .io_enq_0_bits_vpu_fpu_isFoldTo1_8(io_enq_0_bits_vpu_fpu_isFoldTo1_8),
    .io_enq_0_bits_vpu_vxrm(io_enq_0_bits_vpu_vxrm),
    .io_enq_0_bits_vpu_vuopIdx(io_enq_0_bits_vpu_vuopIdx),
    .io_enq_0_bits_vpu_lastUop(io_enq_0_bits_vpu_lastUop),
    .io_enq_0_bits_vpu_vmask(io_enq_0_bits_vpu_vmask),
    .io_enq_0_bits_vpu_vl(io_enq_0_bits_vpu_vl),
    .io_enq_0_bits_vpu_nf(io_enq_0_bits_vpu_nf),
    .io_enq_0_bits_vpu_veew(io_enq_0_bits_vpu_veew),
    .io_enq_0_bits_vpu_isReverse(io_enq_0_bits_vpu_isReverse),
    .io_enq_0_bits_vpu_isExt(io_enq_0_bits_vpu_isExt),
    .io_enq_0_bits_vpu_isNarrow(io_enq_0_bits_vpu_isNarrow),
    .io_enq_0_bits_vpu_isDstMask(io_enq_0_bits_vpu_isDstMask),
    .io_enq_0_bits_vpu_isOpMask(io_enq_0_bits_vpu_isOpMask),
    .io_enq_0_bits_vpu_isMove(io_enq_0_bits_vpu_isMove),
    .io_enq_0_bits_vpu_isDependOldVd(io_enq_0_bits_vpu_isDependOldVd),
    .io_enq_0_bits_vpu_isWritePartVd(io_enq_0_bits_vpu_isWritePartVd),
    .io_enq_0_bits_vpu_isVleff(io_enq_0_bits_vpu_isVleff),
    .io_enq_0_bits_vlsInstr(io_enq_0_bits_vlsInstr),
    .io_enq_0_bits_wfflags(io_enq_0_bits_wfflags),
    .io_enq_0_bits_isMove(io_enq_0_bits_isMove),
    .io_enq_0_bits_isDropAmocasSta(io_enq_0_bits_isDropAmocasSta),
    .io_enq_0_bits_uopIdx(io_enq_0_bits_uopIdx),
    .io_enq_0_bits_isVset(io_enq_0_bits_isVset),
    .io_enq_0_bits_firstUop(io_enq_0_bits_firstUop),
    .io_enq_0_bits_lastUop(io_enq_0_bits_lastUop),
    .io_enq_0_bits_numUops(io_enq_0_bits_numUops),
    .io_enq_0_bits_numWB(io_enq_0_bits_numWB),
    .io_enq_0_bits_commitType(io_enq_0_bits_commitType),
    .io_enq_0_bits_srcState_0(io_enq_0_bits_srcState_0),
    .io_enq_0_bits_srcState_1(io_enq_0_bits_srcState_1),
    .io_enq_0_bits_srcState_2(io_enq_0_bits_srcState_2),
    .io_enq_0_bits_srcState_3(io_enq_0_bits_srcState_3),
    .io_enq_0_bits_srcState_4(io_enq_0_bits_srcState_4),
    .io_enq_0_bits_psrc_0(io_enq_0_bits_psrc_0),
    .io_enq_0_bits_psrc_1(io_enq_0_bits_psrc_1),
    .io_enq_0_bits_psrc_2(io_enq_0_bits_psrc_2),
    .io_enq_0_bits_psrc_3(io_enq_0_bits_psrc_3),
    .io_enq_0_bits_psrc_4(io_enq_0_bits_psrc_4),
    .io_enq_0_bits_pdest(io_enq_0_bits_pdest),
    .io_enq_0_bits_useRegCache_0(io_enq_0_bits_useRegCache_0),
    .io_enq_0_bits_useRegCache_1(io_enq_0_bits_useRegCache_1),
    .io_enq_0_bits_regCacheIdx_0(io_enq_0_bits_regCacheIdx_0),
    .io_enq_0_bits_regCacheIdx_1(io_enq_0_bits_regCacheIdx_1),
    .io_enq_0_bits_robIdx_flag(io_enq_0_bits_robIdx_flag),
    .io_enq_0_bits_robIdx_value(io_enq_0_bits_robIdx_value),
    .io_enq_0_bits_instrSize(io_enq_0_bits_instrSize),
    .io_enq_0_bits_dirtyFs(io_enq_0_bits_dirtyFs),
    .io_enq_0_bits_dirtyVs(io_enq_0_bits_dirtyVs),
    .io_enq_0_bits_traceBlockInPipe_itype(io_enq_0_bits_traceBlockInPipe_itype),
    .io_enq_0_bits_traceBlockInPipe_iretire(io_enq_0_bits_traceBlockInPipe_iretire),
    .io_enq_0_bits_traceBlockInPipe_ilastsize(io_enq_0_bits_traceBlockInPipe_ilastsize),
    .io_enq_0_bits_eliminatedMove(io_enq_0_bits_eliminatedMove),
    .io_enq_0_bits_snapshot(io_enq_0_bits_snapshot),
    .io_enq_0_bits_debugInfo_eliminatedMove(io_enq_0_bits_debugInfo_eliminatedMove),
    .io_enq_0_bits_debugInfo_renameTime(io_enq_0_bits_debugInfo_renameTime),
    .io_enq_0_bits_debugInfo_dispatchTime(io_enq_0_bits_debugInfo_dispatchTime),
    .io_enq_0_bits_debugInfo_enqRsTime(io_enq_0_bits_debugInfo_enqRsTime),
    .io_enq_0_bits_debugInfo_selectTime(io_enq_0_bits_debugInfo_selectTime),
    .io_enq_0_bits_debugInfo_issueTime(io_enq_0_bits_debugInfo_issueTime),
    .io_enq_0_bits_debugInfo_writebackTime(io_enq_0_bits_debugInfo_writebackTime),
    .io_enq_0_bits_debugInfo_runahead_checkpoint_id(io_enq_0_bits_debugInfo_runahead_checkpoint_id),
    .io_enq_0_bits_debugInfo_tlbFirstReqTime(io_enq_0_bits_debugInfo_tlbFirstReqTime),
    .io_enq_0_bits_debugInfo_tlbRespTime(io_enq_0_bits_debugInfo_tlbRespTime),
    .io_enq_0_bits_debug_seqNum_seqNum(io_enq_0_bits_debug_seqNum_seqNum),
    .io_enq_0_bits_debug_seqNum_uopIdx(io_enq_0_bits_debug_seqNum_uopIdx),
    .io_enq_0_bits_storeSetHit(io_enq_0_bits_storeSetHit),
    .io_enq_0_bits_waitForRobIdx_flag(io_enq_0_bits_waitForRobIdx_flag),
    .io_enq_0_bits_waitForRobIdx_value(io_enq_0_bits_waitForRobIdx_value),
    .io_enq_0_bits_loadWaitBit(io_enq_0_bits_loadWaitBit),
    .io_enq_0_bits_loadWaitStrict(io_enq_0_bits_loadWaitStrict),
    .io_enq_0_bits_ssid(io_enq_0_bits_ssid),
    .io_enq_0_bits_lqIdx_flag(io_enq_0_bits_lqIdx_flag),
    .io_enq_0_bits_lqIdx_value(io_enq_0_bits_lqIdx_value),
    .io_enq_0_bits_sqIdx_flag(io_enq_0_bits_sqIdx_flag),
    .io_enq_0_bits_sqIdx_value(io_enq_0_bits_sqIdx_value),
    .io_enq_0_bits_singleStep(io_enq_0_bits_singleStep),
    .io_enq_0_bits_replayInst(io_enq_0_bits_replayInst),
    .io_enq_0_bits_debug_fuType(io_enq_0_bits_debug_fuType),
    .io_enq_0_bits_debug_sim_trig(io_enq_0_bits_debug_sim_trig),
    .io_enq_0_bits_numLsElem(io_enq_0_bits_numLsElem),
    .io_enq_1_valid(io_enq_1_valid),
    .io_enq_1_bits_instr(io_enq_1_bits_instr),
    .io_enq_1_bits_pc(io_enq_1_bits_pc),
    .io_enq_1_bits_foldpc(io_enq_1_bits_foldpc),
    .io_enq_1_bits_exceptionVec_0(io_enq_1_bits_exceptionVec_0),
    .io_enq_1_bits_exceptionVec_1(io_enq_1_bits_exceptionVec_1),
    .io_enq_1_bits_exceptionVec_2(io_enq_1_bits_exceptionVec_2),
    .io_enq_1_bits_exceptionVec_3(io_enq_1_bits_exceptionVec_3),
    .io_enq_1_bits_exceptionVec_4(io_enq_1_bits_exceptionVec_4),
    .io_enq_1_bits_exceptionVec_5(io_enq_1_bits_exceptionVec_5),
    .io_enq_1_bits_exceptionVec_6(io_enq_1_bits_exceptionVec_6),
    .io_enq_1_bits_exceptionVec_7(io_enq_1_bits_exceptionVec_7),
    .io_enq_1_bits_exceptionVec_8(io_enq_1_bits_exceptionVec_8),
    .io_enq_1_bits_exceptionVec_9(io_enq_1_bits_exceptionVec_9),
    .io_enq_1_bits_exceptionVec_10(io_enq_1_bits_exceptionVec_10),
    .io_enq_1_bits_exceptionVec_11(io_enq_1_bits_exceptionVec_11),
    .io_enq_1_bits_exceptionVec_12(io_enq_1_bits_exceptionVec_12),
    .io_enq_1_bits_exceptionVec_13(io_enq_1_bits_exceptionVec_13),
    .io_enq_1_bits_exceptionVec_14(io_enq_1_bits_exceptionVec_14),
    .io_enq_1_bits_exceptionVec_15(io_enq_1_bits_exceptionVec_15),
    .io_enq_1_bits_exceptionVec_16(io_enq_1_bits_exceptionVec_16),
    .io_enq_1_bits_exceptionVec_17(io_enq_1_bits_exceptionVec_17),
    .io_enq_1_bits_exceptionVec_18(io_enq_1_bits_exceptionVec_18),
    .io_enq_1_bits_exceptionVec_19(io_enq_1_bits_exceptionVec_19),
    .io_enq_1_bits_exceptionVec_20(io_enq_1_bits_exceptionVec_20),
    .io_enq_1_bits_exceptionVec_21(io_enq_1_bits_exceptionVec_21),
    .io_enq_1_bits_exceptionVec_22(io_enq_1_bits_exceptionVec_22),
    .io_enq_1_bits_exceptionVec_23(io_enq_1_bits_exceptionVec_23),
    .io_enq_1_bits_isFetchMalAddr(io_enq_1_bits_isFetchMalAddr),
    .io_enq_1_bits_hasException(io_enq_1_bits_hasException),
    .io_enq_1_bits_trigger(io_enq_1_bits_trigger),
    .io_enq_1_bits_preDecodeInfo_valid(io_enq_1_bits_preDecodeInfo_valid),
    .io_enq_1_bits_preDecodeInfo_isRVC(io_enq_1_bits_preDecodeInfo_isRVC),
    .io_enq_1_bits_preDecodeInfo_brType(io_enq_1_bits_preDecodeInfo_brType),
    .io_enq_1_bits_preDecodeInfo_isCall(io_enq_1_bits_preDecodeInfo_isCall),
    .io_enq_1_bits_preDecodeInfo_isRet(io_enq_1_bits_preDecodeInfo_isRet),
    .io_enq_1_bits_pred_taken(io_enq_1_bits_pred_taken),
    .io_enq_1_bits_crossPageIPFFix(io_enq_1_bits_crossPageIPFFix),
    .io_enq_1_bits_ftqPtr_flag(io_enq_1_bits_ftqPtr_flag),
    .io_enq_1_bits_ftqPtr_value(io_enq_1_bits_ftqPtr_value),
    .io_enq_1_bits_ftqOffset(io_enq_1_bits_ftqOffset),
    .io_enq_1_bits_satpFlushFirstFetchFault(io_enq_1_bits_satpFlushFirstFetchFault),
    .io_enq_1_bits_srcType_0(io_enq_1_bits_srcType_0),
    .io_enq_1_bits_srcType_1(io_enq_1_bits_srcType_1),
    .io_enq_1_bits_srcType_2(io_enq_1_bits_srcType_2),
    .io_enq_1_bits_srcType_3(io_enq_1_bits_srcType_3),
    .io_enq_1_bits_srcType_4(io_enq_1_bits_srcType_4),
    .io_enq_1_bits_ldest(io_enq_1_bits_ldest),
    .io_enq_1_bits_fuType(io_enq_1_bits_fuType),
    .io_enq_1_bits_fuOpType(io_enq_1_bits_fuOpType),
    .io_enq_1_bits_rfWen(io_enq_1_bits_rfWen),
    .io_enq_1_bits_fpWen(io_enq_1_bits_fpWen),
    .io_enq_1_bits_vecWen(io_enq_1_bits_vecWen),
    .io_enq_1_bits_v0Wen(io_enq_1_bits_v0Wen),
    .io_enq_1_bits_vlWen(io_enq_1_bits_vlWen),
    .io_enq_1_bits_isXSTrap(io_enq_1_bits_isXSTrap),
    .io_enq_1_bits_waitForward(io_enq_1_bits_waitForward),
    .io_enq_1_bits_blockBackward(io_enq_1_bits_blockBackward),
    .io_enq_1_bits_flushPipe(io_enq_1_bits_flushPipe),
    .io_enq_1_bits_canRobCompress(io_enq_1_bits_canRobCompress),
    .io_enq_1_bits_selImm(io_enq_1_bits_selImm),
    .io_enq_1_bits_imm(io_enq_1_bits_imm),
    .io_enq_1_bits_fpu_typeTagOut(io_enq_1_bits_fpu_typeTagOut),
    .io_enq_1_bits_fpu_wflags(io_enq_1_bits_fpu_wflags),
    .io_enq_1_bits_fpu_typ(io_enq_1_bits_fpu_typ),
    .io_enq_1_bits_fpu_fmt(io_enq_1_bits_fpu_fmt),
    .io_enq_1_bits_fpu_rm(io_enq_1_bits_fpu_rm),
    .io_enq_1_bits_vpu_vill(io_enq_1_bits_vpu_vill),
    .io_enq_1_bits_vpu_vma(io_enq_1_bits_vpu_vma),
    .io_enq_1_bits_vpu_vta(io_enq_1_bits_vpu_vta),
    .io_enq_1_bits_vpu_vsew(io_enq_1_bits_vpu_vsew),
    .io_enq_1_bits_vpu_vlmul(io_enq_1_bits_vpu_vlmul),
    .io_enq_1_bits_vpu_specVill(io_enq_1_bits_vpu_specVill),
    .io_enq_1_bits_vpu_specVma(io_enq_1_bits_vpu_specVma),
    .io_enq_1_bits_vpu_specVta(io_enq_1_bits_vpu_specVta),
    .io_enq_1_bits_vpu_specVsew(io_enq_1_bits_vpu_specVsew),
    .io_enq_1_bits_vpu_specVlmul(io_enq_1_bits_vpu_specVlmul),
    .io_enq_1_bits_vpu_vm(io_enq_1_bits_vpu_vm),
    .io_enq_1_bits_vpu_vstart(io_enq_1_bits_vpu_vstart),
    .io_enq_1_bits_vpu_frm(io_enq_1_bits_vpu_frm),
    .io_enq_1_bits_vpu_fpu_isFpToVecInst(io_enq_1_bits_vpu_fpu_isFpToVecInst),
    .io_enq_1_bits_vpu_fpu_isFP32Instr(io_enq_1_bits_vpu_fpu_isFP32Instr),
    .io_enq_1_bits_vpu_fpu_isFP64Instr(io_enq_1_bits_vpu_fpu_isFP64Instr),
    .io_enq_1_bits_vpu_fpu_isReduction(io_enq_1_bits_vpu_fpu_isReduction),
    .io_enq_1_bits_vpu_fpu_isFoldTo1_2(io_enq_1_bits_vpu_fpu_isFoldTo1_2),
    .io_enq_1_bits_vpu_fpu_isFoldTo1_4(io_enq_1_bits_vpu_fpu_isFoldTo1_4),
    .io_enq_1_bits_vpu_fpu_isFoldTo1_8(io_enq_1_bits_vpu_fpu_isFoldTo1_8),
    .io_enq_1_bits_vpu_vxrm(io_enq_1_bits_vpu_vxrm),
    .io_enq_1_bits_vpu_vuopIdx(io_enq_1_bits_vpu_vuopIdx),
    .io_enq_1_bits_vpu_lastUop(io_enq_1_bits_vpu_lastUop),
    .io_enq_1_bits_vpu_vmask(io_enq_1_bits_vpu_vmask),
    .io_enq_1_bits_vpu_vl(io_enq_1_bits_vpu_vl),
    .io_enq_1_bits_vpu_nf(io_enq_1_bits_vpu_nf),
    .io_enq_1_bits_vpu_veew(io_enq_1_bits_vpu_veew),
    .io_enq_1_bits_vpu_isReverse(io_enq_1_bits_vpu_isReverse),
    .io_enq_1_bits_vpu_isExt(io_enq_1_bits_vpu_isExt),
    .io_enq_1_bits_vpu_isNarrow(io_enq_1_bits_vpu_isNarrow),
    .io_enq_1_bits_vpu_isDstMask(io_enq_1_bits_vpu_isDstMask),
    .io_enq_1_bits_vpu_isOpMask(io_enq_1_bits_vpu_isOpMask),
    .io_enq_1_bits_vpu_isMove(io_enq_1_bits_vpu_isMove),
    .io_enq_1_bits_vpu_isDependOldVd(io_enq_1_bits_vpu_isDependOldVd),
    .io_enq_1_bits_vpu_isWritePartVd(io_enq_1_bits_vpu_isWritePartVd),
    .io_enq_1_bits_vpu_isVleff(io_enq_1_bits_vpu_isVleff),
    .io_enq_1_bits_vlsInstr(io_enq_1_bits_vlsInstr),
    .io_enq_1_bits_wfflags(io_enq_1_bits_wfflags),
    .io_enq_1_bits_isMove(io_enq_1_bits_isMove),
    .io_enq_1_bits_isDropAmocasSta(io_enq_1_bits_isDropAmocasSta),
    .io_enq_1_bits_uopIdx(io_enq_1_bits_uopIdx),
    .io_enq_1_bits_isVset(io_enq_1_bits_isVset),
    .io_enq_1_bits_firstUop(io_enq_1_bits_firstUop),
    .io_enq_1_bits_lastUop(io_enq_1_bits_lastUop),
    .io_enq_1_bits_numUops(io_enq_1_bits_numUops),
    .io_enq_1_bits_numWB(io_enq_1_bits_numWB),
    .io_enq_1_bits_commitType(io_enq_1_bits_commitType),
    .io_enq_1_bits_srcState_0(io_enq_1_bits_srcState_0),
    .io_enq_1_bits_srcState_1(io_enq_1_bits_srcState_1),
    .io_enq_1_bits_srcState_2(io_enq_1_bits_srcState_2),
    .io_enq_1_bits_srcState_3(io_enq_1_bits_srcState_3),
    .io_enq_1_bits_srcState_4(io_enq_1_bits_srcState_4),
    .io_enq_1_bits_psrc_0(io_enq_1_bits_psrc_0),
    .io_enq_1_bits_psrc_1(io_enq_1_bits_psrc_1),
    .io_enq_1_bits_psrc_2(io_enq_1_bits_psrc_2),
    .io_enq_1_bits_psrc_3(io_enq_1_bits_psrc_3),
    .io_enq_1_bits_psrc_4(io_enq_1_bits_psrc_4),
    .io_enq_1_bits_pdest(io_enq_1_bits_pdest),
    .io_enq_1_bits_useRegCache_0(io_enq_1_bits_useRegCache_0),
    .io_enq_1_bits_useRegCache_1(io_enq_1_bits_useRegCache_1),
    .io_enq_1_bits_regCacheIdx_0(io_enq_1_bits_regCacheIdx_0),
    .io_enq_1_bits_regCacheIdx_1(io_enq_1_bits_regCacheIdx_1),
    .io_enq_1_bits_robIdx_flag(io_enq_1_bits_robIdx_flag),
    .io_enq_1_bits_robIdx_value(io_enq_1_bits_robIdx_value),
    .io_enq_1_bits_instrSize(io_enq_1_bits_instrSize),
    .io_enq_1_bits_dirtyFs(io_enq_1_bits_dirtyFs),
    .io_enq_1_bits_dirtyVs(io_enq_1_bits_dirtyVs),
    .io_enq_1_bits_traceBlockInPipe_itype(io_enq_1_bits_traceBlockInPipe_itype),
    .io_enq_1_bits_traceBlockInPipe_iretire(io_enq_1_bits_traceBlockInPipe_iretire),
    .io_enq_1_bits_traceBlockInPipe_ilastsize(io_enq_1_bits_traceBlockInPipe_ilastsize),
    .io_enq_1_bits_eliminatedMove(io_enq_1_bits_eliminatedMove),
    .io_enq_1_bits_snapshot(io_enq_1_bits_snapshot),
    .io_enq_1_bits_debugInfo_eliminatedMove(io_enq_1_bits_debugInfo_eliminatedMove),
    .io_enq_1_bits_debugInfo_renameTime(io_enq_1_bits_debugInfo_renameTime),
    .io_enq_1_bits_debugInfo_dispatchTime(io_enq_1_bits_debugInfo_dispatchTime),
    .io_enq_1_bits_debugInfo_enqRsTime(io_enq_1_bits_debugInfo_enqRsTime),
    .io_enq_1_bits_debugInfo_selectTime(io_enq_1_bits_debugInfo_selectTime),
    .io_enq_1_bits_debugInfo_issueTime(io_enq_1_bits_debugInfo_issueTime),
    .io_enq_1_bits_debugInfo_writebackTime(io_enq_1_bits_debugInfo_writebackTime),
    .io_enq_1_bits_debugInfo_runahead_checkpoint_id(io_enq_1_bits_debugInfo_runahead_checkpoint_id),
    .io_enq_1_bits_debugInfo_tlbFirstReqTime(io_enq_1_bits_debugInfo_tlbFirstReqTime),
    .io_enq_1_bits_debugInfo_tlbRespTime(io_enq_1_bits_debugInfo_tlbRespTime),
    .io_enq_1_bits_debug_seqNum_seqNum(io_enq_1_bits_debug_seqNum_seqNum),
    .io_enq_1_bits_debug_seqNum_uopIdx(io_enq_1_bits_debug_seqNum_uopIdx),
    .io_enq_1_bits_storeSetHit(io_enq_1_bits_storeSetHit),
    .io_enq_1_bits_waitForRobIdx_flag(io_enq_1_bits_waitForRobIdx_flag),
    .io_enq_1_bits_waitForRobIdx_value(io_enq_1_bits_waitForRobIdx_value),
    .io_enq_1_bits_loadWaitBit(io_enq_1_bits_loadWaitBit),
    .io_enq_1_bits_loadWaitStrict(io_enq_1_bits_loadWaitStrict),
    .io_enq_1_bits_ssid(io_enq_1_bits_ssid),
    .io_enq_1_bits_lqIdx_flag(io_enq_1_bits_lqIdx_flag),
    .io_enq_1_bits_lqIdx_value(io_enq_1_bits_lqIdx_value),
    .io_enq_1_bits_sqIdx_flag(io_enq_1_bits_sqIdx_flag),
    .io_enq_1_bits_sqIdx_value(io_enq_1_bits_sqIdx_value),
    .io_enq_1_bits_singleStep(io_enq_1_bits_singleStep),
    .io_enq_1_bits_replayInst(io_enq_1_bits_replayInst),
    .io_enq_1_bits_debug_fuType(io_enq_1_bits_debug_fuType),
    .io_enq_1_bits_debug_sim_trig(io_enq_1_bits_debug_sim_trig),
    .io_enq_1_bits_numLsElem(io_enq_1_bits_numLsElem),
    .io_og0Resp_0_valid(io_og0Resp_0_valid),
    .io_og1Resp_0_valid(io_og1Resp_0_valid),
    .io_og2Resp_0_valid(io_og2Resp_0_valid),
    .io_og2Resp_0_bits_resp(io_og2Resp_0_bits_resp),
    .io_wakeupFromWB_15_valid(io_wakeupFromWB_15_valid),
    .io_wakeupFromWB_15_bits_vlWen(io_wakeupFromWB_15_bits_vlWen),
    .io_wakeupFromWB_15_bits_pdest(io_wakeupFromWB_15_bits_pdest),
    .io_wakeupFromWB_14_valid(io_wakeupFromWB_14_valid),
    .io_wakeupFromWB_14_bits_vlWen(io_wakeupFromWB_14_bits_vlWen),
    .io_wakeupFromWB_14_bits_pdest(io_wakeupFromWB_14_bits_pdest),
    .io_wakeupFromWB_13_valid(io_wakeupFromWB_13_valid),
    .io_wakeupFromWB_13_bits_vlWen(io_wakeupFromWB_13_bits_vlWen),
    .io_wakeupFromWB_13_bits_pdest(io_wakeupFromWB_13_bits_pdest),
    .io_wakeupFromWB_12_valid(io_wakeupFromWB_12_valid),
    .io_wakeupFromWB_12_bits_vlWen(io_wakeupFromWB_12_bits_vlWen),
    .io_wakeupFromWB_12_bits_pdest(io_wakeupFromWB_12_bits_pdest),
    .io_wakeupFromWB_11_valid(io_wakeupFromWB_11_valid),
    .io_wakeupFromWB_11_bits_v0Wen(io_wakeupFromWB_11_bits_v0Wen),
    .io_wakeupFromWB_11_bits_pdest(io_wakeupFromWB_11_bits_pdest),
    .io_wakeupFromWB_10_valid(io_wakeupFromWB_10_valid),
    .io_wakeupFromWB_10_bits_v0Wen(io_wakeupFromWB_10_bits_v0Wen),
    .io_wakeupFromWB_10_bits_pdest(io_wakeupFromWB_10_bits_pdest),
    .io_wakeupFromWB_9_valid(io_wakeupFromWB_9_valid),
    .io_wakeupFromWB_9_bits_v0Wen(io_wakeupFromWB_9_bits_v0Wen),
    .io_wakeupFromWB_9_bits_pdest(io_wakeupFromWB_9_bits_pdest),
    .io_wakeupFromWB_8_valid(io_wakeupFromWB_8_valid),
    .io_wakeupFromWB_8_bits_v0Wen(io_wakeupFromWB_8_bits_v0Wen),
    .io_wakeupFromWB_8_bits_pdest(io_wakeupFromWB_8_bits_pdest),
    .io_wakeupFromWB_7_valid(io_wakeupFromWB_7_valid),
    .io_wakeupFromWB_7_bits_v0Wen(io_wakeupFromWB_7_bits_v0Wen),
    .io_wakeupFromWB_7_bits_pdest(io_wakeupFromWB_7_bits_pdest),
    .io_wakeupFromWB_6_valid(io_wakeupFromWB_6_valid),
    .io_wakeupFromWB_6_bits_v0Wen(io_wakeupFromWB_6_bits_v0Wen),
    .io_wakeupFromWB_6_bits_pdest(io_wakeupFromWB_6_bits_pdest),
    .io_wakeupFromWB_5_valid(io_wakeupFromWB_5_valid),
    .io_wakeupFromWB_5_bits_vecWen(io_wakeupFromWB_5_bits_vecWen),
    .io_wakeupFromWB_5_bits_pdest(io_wakeupFromWB_5_bits_pdest),
    .io_wakeupFromWB_4_valid(io_wakeupFromWB_4_valid),
    .io_wakeupFromWB_4_bits_vecWen(io_wakeupFromWB_4_bits_vecWen),
    .io_wakeupFromWB_4_bits_pdest(io_wakeupFromWB_4_bits_pdest),
    .io_wakeupFromWB_3_valid(io_wakeupFromWB_3_valid),
    .io_wakeupFromWB_3_bits_vecWen(io_wakeupFromWB_3_bits_vecWen),
    .io_wakeupFromWB_3_bits_pdest(io_wakeupFromWB_3_bits_pdest),
    .io_wakeupFromWB_2_valid(io_wakeupFromWB_2_valid),
    .io_wakeupFromWB_2_bits_vecWen(io_wakeupFromWB_2_bits_vecWen),
    .io_wakeupFromWB_2_bits_pdest(io_wakeupFromWB_2_bits_pdest),
    .io_wakeupFromWB_1_valid(io_wakeupFromWB_1_valid),
    .io_wakeupFromWB_1_bits_vecWen(io_wakeupFromWB_1_bits_vecWen),
    .io_wakeupFromWB_1_bits_pdest(io_wakeupFromWB_1_bits_pdest),
    .io_wakeupFromWB_0_valid(io_wakeupFromWB_0_valid),
    .io_wakeupFromWB_0_bits_vecWen(io_wakeupFromWB_0_bits_vecWen),
    .io_wakeupFromWB_0_bits_pdest(io_wakeupFromWB_0_bits_pdest),
    .io_wakeupFromWBDelayed_15_valid(io_wakeupFromWBDelayed_15_valid),
    .io_wakeupFromWBDelayed_15_bits_vlWen(io_wakeupFromWBDelayed_15_bits_vlWen),
    .io_wakeupFromWBDelayed_15_bits_pdest(io_wakeupFromWBDelayed_15_bits_pdest),
    .io_wakeupFromWBDelayed_14_valid(io_wakeupFromWBDelayed_14_valid),
    .io_wakeupFromWBDelayed_14_bits_vlWen(io_wakeupFromWBDelayed_14_bits_vlWen),
    .io_wakeupFromWBDelayed_14_bits_pdest(io_wakeupFromWBDelayed_14_bits_pdest),
    .io_wakeupFromWBDelayed_13_valid(io_wakeupFromWBDelayed_13_valid),
    .io_wakeupFromWBDelayed_13_bits_vlWen(io_wakeupFromWBDelayed_13_bits_vlWen),
    .io_wakeupFromWBDelayed_13_bits_pdest(io_wakeupFromWBDelayed_13_bits_pdest),
    .io_wakeupFromWBDelayed_12_valid(io_wakeupFromWBDelayed_12_valid),
    .io_wakeupFromWBDelayed_12_bits_vlWen(io_wakeupFromWBDelayed_12_bits_vlWen),
    .io_wakeupFromWBDelayed_12_bits_pdest(io_wakeupFromWBDelayed_12_bits_pdest),
    .io_wakeupFromWBDelayed_11_valid(io_wakeupFromWBDelayed_11_valid),
    .io_wakeupFromWBDelayed_11_bits_v0Wen(io_wakeupFromWBDelayed_11_bits_v0Wen),
    .io_wakeupFromWBDelayed_11_bits_pdest(io_wakeupFromWBDelayed_11_bits_pdest),
    .io_wakeupFromWBDelayed_10_valid(io_wakeupFromWBDelayed_10_valid),
    .io_wakeupFromWBDelayed_10_bits_v0Wen(io_wakeupFromWBDelayed_10_bits_v0Wen),
    .io_wakeupFromWBDelayed_10_bits_pdest(io_wakeupFromWBDelayed_10_bits_pdest),
    .io_wakeupFromWBDelayed_9_valid(io_wakeupFromWBDelayed_9_valid),
    .io_wakeupFromWBDelayed_9_bits_v0Wen(io_wakeupFromWBDelayed_9_bits_v0Wen),
    .io_wakeupFromWBDelayed_9_bits_pdest(io_wakeupFromWBDelayed_9_bits_pdest),
    .io_wakeupFromWBDelayed_8_valid(io_wakeupFromWBDelayed_8_valid),
    .io_wakeupFromWBDelayed_8_bits_v0Wen(io_wakeupFromWBDelayed_8_bits_v0Wen),
    .io_wakeupFromWBDelayed_8_bits_pdest(io_wakeupFromWBDelayed_8_bits_pdest),
    .io_wakeupFromWBDelayed_7_valid(io_wakeupFromWBDelayed_7_valid),
    .io_wakeupFromWBDelayed_7_bits_v0Wen(io_wakeupFromWBDelayed_7_bits_v0Wen),
    .io_wakeupFromWBDelayed_7_bits_pdest(io_wakeupFromWBDelayed_7_bits_pdest),
    .io_wakeupFromWBDelayed_6_valid(io_wakeupFromWBDelayed_6_valid),
    .io_wakeupFromWBDelayed_6_bits_v0Wen(io_wakeupFromWBDelayed_6_bits_v0Wen),
    .io_wakeupFromWBDelayed_6_bits_pdest(io_wakeupFromWBDelayed_6_bits_pdest),
    .io_wakeupFromWBDelayed_5_valid(io_wakeupFromWBDelayed_5_valid),
    .io_wakeupFromWBDelayed_5_bits_vecWen(io_wakeupFromWBDelayed_5_bits_vecWen),
    .io_wakeupFromWBDelayed_5_bits_pdest(io_wakeupFromWBDelayed_5_bits_pdest),
    .io_wakeupFromWBDelayed_4_valid(io_wakeupFromWBDelayed_4_valid),
    .io_wakeupFromWBDelayed_4_bits_vecWen(io_wakeupFromWBDelayed_4_bits_vecWen),
    .io_wakeupFromWBDelayed_4_bits_pdest(io_wakeupFromWBDelayed_4_bits_pdest),
    .io_wakeupFromWBDelayed_3_valid(io_wakeupFromWBDelayed_3_valid),
    .io_wakeupFromWBDelayed_3_bits_vecWen(io_wakeupFromWBDelayed_3_bits_vecWen),
    .io_wakeupFromWBDelayed_3_bits_pdest(io_wakeupFromWBDelayed_3_bits_pdest),
    .io_wakeupFromWBDelayed_2_valid(io_wakeupFromWBDelayed_2_valid),
    .io_wakeupFromWBDelayed_2_bits_vecWen(io_wakeupFromWBDelayed_2_bits_vecWen),
    .io_wakeupFromWBDelayed_2_bits_pdest(io_wakeupFromWBDelayed_2_bits_pdest),
    .io_wakeupFromWBDelayed_1_valid(io_wakeupFromWBDelayed_1_valid),
    .io_wakeupFromWBDelayed_1_bits_vecWen(io_wakeupFromWBDelayed_1_bits_vecWen),
    .io_wakeupFromWBDelayed_1_bits_pdest(io_wakeupFromWBDelayed_1_bits_pdest),
    .io_wakeupFromWBDelayed_0_valid(io_wakeupFromWBDelayed_0_valid),
    .io_wakeupFromWBDelayed_0_bits_vecWen(io_wakeupFromWBDelayed_0_bits_vecWen),
    .io_wakeupFromWBDelayed_0_bits_pdest(io_wakeupFromWBDelayed_0_bits_pdest),
    .io_vlFromIntIsZero(io_vlFromIntIsZero),
    .io_vlFromIntIsVlmax(io_vlFromIntIsVlmax),
    .io_vlFromVfIsZero(io_vlFromVfIsZero),
    .io_vlFromVfIsVlmax(io_vlFromVfIsVlmax),
    .io_deqDelay_0_ready(io_deqDelay_0_ready),
    .io_enq_0_ready(g_io_enq_0_ready),
    .io_enq_1_ready(g_io_enq_1_ready),
    .io_deqDelay_0_valid(g_io_deqDelay_0_valid),
    .io_deqDelay_0_bits_rf_4_0_addr(g_io_deqDelay_0_bits_rf_4_0_addr),
    .io_deqDelay_0_bits_rf_4_0_srcType(g_io_deqDelay_0_bits_rf_4_0_srcType),
    .io_deqDelay_0_bits_rf_3_0_addr(g_io_deqDelay_0_bits_rf_3_0_addr),
    .io_deqDelay_0_bits_rf_3_0_srcType(g_io_deqDelay_0_bits_rf_3_0_srcType),
    .io_deqDelay_0_bits_rf_2_0_addr(g_io_deqDelay_0_bits_rf_2_0_addr),
    .io_deqDelay_0_bits_rf_2_0_srcType(g_io_deqDelay_0_bits_rf_2_0_srcType),
    .io_deqDelay_0_bits_rf_1_0_addr(g_io_deqDelay_0_bits_rf_1_0_addr),
    .io_deqDelay_0_bits_rf_1_0_srcType(g_io_deqDelay_0_bits_rf_1_0_srcType),
    .io_deqDelay_0_bits_rf_0_0_addr(g_io_deqDelay_0_bits_rf_0_0_addr),
    .io_deqDelay_0_bits_rf_0_0_srcType(g_io_deqDelay_0_bits_rf_0_0_srcType),
    .io_deqDelay_0_bits_srcType_0(g_io_deqDelay_0_bits_srcType_0),
    .io_deqDelay_0_bits_srcType_1(g_io_deqDelay_0_bits_srcType_1),
    .io_deqDelay_0_bits_srcType_2(g_io_deqDelay_0_bits_srcType_2),
    .io_deqDelay_0_bits_srcType_3(g_io_deqDelay_0_bits_srcType_3),
    .io_deqDelay_0_bits_srcType_4(g_io_deqDelay_0_bits_srcType_4),
    .io_deqDelay_0_bits_immType(g_io_deqDelay_0_bits_immType),
    .io_deqDelay_0_bits_common_fuType(g_io_deqDelay_0_bits_common_fuType),
    .io_deqDelay_0_bits_common_fuOpType(g_io_deqDelay_0_bits_common_fuOpType),
    .io_deqDelay_0_bits_common_src_0(g_io_deqDelay_0_bits_common_src_0),
    .io_deqDelay_0_bits_common_src_1(g_io_deqDelay_0_bits_common_src_1),
    .io_deqDelay_0_bits_common_src_2(g_io_deqDelay_0_bits_common_src_2),
    .io_deqDelay_0_bits_common_src_3(g_io_deqDelay_0_bits_common_src_3),
    .io_deqDelay_0_bits_common_src_4(g_io_deqDelay_0_bits_common_src_4),
    .io_deqDelay_0_bits_common_imm(g_io_deqDelay_0_bits_common_imm),
    .io_deqDelay_0_bits_common_robIdx_flag(g_io_deqDelay_0_bits_common_robIdx_flag),
    .io_deqDelay_0_bits_common_robIdx_value(g_io_deqDelay_0_bits_common_robIdx_value),
    .io_deqDelay_0_bits_common_iqIdx(g_io_deqDelay_0_bits_common_iqIdx),
    .io_deqDelay_0_bits_common_isFirstIssue(g_io_deqDelay_0_bits_common_isFirstIssue),
    .io_deqDelay_0_bits_common_pdest(g_io_deqDelay_0_bits_common_pdest),
    .io_deqDelay_0_bits_common_vecWen(g_io_deqDelay_0_bits_common_vecWen),
    .io_deqDelay_0_bits_common_v0Wen(g_io_deqDelay_0_bits_common_v0Wen),
    .io_deqDelay_0_bits_common_fpu_typeTagOut(g_io_deqDelay_0_bits_common_fpu_typeTagOut),
    .io_deqDelay_0_bits_common_fpu_wflags(g_io_deqDelay_0_bits_common_fpu_wflags),
    .io_deqDelay_0_bits_common_fpu_typ(g_io_deqDelay_0_bits_common_fpu_typ),
    .io_deqDelay_0_bits_common_fpu_fmt(g_io_deqDelay_0_bits_common_fpu_fmt),
    .io_deqDelay_0_bits_common_fpu_rm(g_io_deqDelay_0_bits_common_fpu_rm),
    .io_deqDelay_0_bits_common_vpu_vill(g_io_deqDelay_0_bits_common_vpu_vill),
    .io_deqDelay_0_bits_common_vpu_vma(g_io_deqDelay_0_bits_common_vpu_vma),
    .io_deqDelay_0_bits_common_vpu_vta(g_io_deqDelay_0_bits_common_vpu_vta),
    .io_deqDelay_0_bits_common_vpu_vsew(g_io_deqDelay_0_bits_common_vpu_vsew),
    .io_deqDelay_0_bits_common_vpu_vlmul(g_io_deqDelay_0_bits_common_vpu_vlmul),
    .io_deqDelay_0_bits_common_vpu_specVill(g_io_deqDelay_0_bits_common_vpu_specVill),
    .io_deqDelay_0_bits_common_vpu_specVma(g_io_deqDelay_0_bits_common_vpu_specVma),
    .io_deqDelay_0_bits_common_vpu_specVta(g_io_deqDelay_0_bits_common_vpu_specVta),
    .io_deqDelay_0_bits_common_vpu_specVsew(g_io_deqDelay_0_bits_common_vpu_specVsew),
    .io_deqDelay_0_bits_common_vpu_specVlmul(g_io_deqDelay_0_bits_common_vpu_specVlmul),
    .io_deqDelay_0_bits_common_vpu_vm(g_io_deqDelay_0_bits_common_vpu_vm),
    .io_deqDelay_0_bits_common_vpu_vstart(g_io_deqDelay_0_bits_common_vpu_vstart),
    .io_deqDelay_0_bits_common_vpu_frm(g_io_deqDelay_0_bits_common_vpu_frm),
    .io_deqDelay_0_bits_common_vpu_fpu_isFpToVecInst(g_io_deqDelay_0_bits_common_vpu_fpu_isFpToVecInst),
    .io_deqDelay_0_bits_common_vpu_fpu_isFP32Instr(g_io_deqDelay_0_bits_common_vpu_fpu_isFP32Instr),
    .io_deqDelay_0_bits_common_vpu_fpu_isFP64Instr(g_io_deqDelay_0_bits_common_vpu_fpu_isFP64Instr),
    .io_deqDelay_0_bits_common_vpu_fpu_isReduction(g_io_deqDelay_0_bits_common_vpu_fpu_isReduction),
    .io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_2(g_io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_2),
    .io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_4(g_io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_4),
    .io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_8(g_io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_8),
    .io_deqDelay_0_bits_common_vpu_vxrm(g_io_deqDelay_0_bits_common_vpu_vxrm),
    .io_deqDelay_0_bits_common_vpu_vuopIdx(g_io_deqDelay_0_bits_common_vpu_vuopIdx),
    .io_deqDelay_0_bits_common_vpu_lastUop(g_io_deqDelay_0_bits_common_vpu_lastUop),
    .io_deqDelay_0_bits_common_vpu_vmask(g_io_deqDelay_0_bits_common_vpu_vmask),
    .io_deqDelay_0_bits_common_vpu_vl(g_io_deqDelay_0_bits_common_vpu_vl),
    .io_deqDelay_0_bits_common_vpu_nf(g_io_deqDelay_0_bits_common_vpu_nf),
    .io_deqDelay_0_bits_common_vpu_veew(g_io_deqDelay_0_bits_common_vpu_veew),
    .io_deqDelay_0_bits_common_vpu_isReverse(g_io_deqDelay_0_bits_common_vpu_isReverse),
    .io_deqDelay_0_bits_common_vpu_isExt(g_io_deqDelay_0_bits_common_vpu_isExt),
    .io_deqDelay_0_bits_common_vpu_isNarrow(g_io_deqDelay_0_bits_common_vpu_isNarrow),
    .io_deqDelay_0_bits_common_vpu_isDstMask(g_io_deqDelay_0_bits_common_vpu_isDstMask),
    .io_deqDelay_0_bits_common_vpu_isOpMask(g_io_deqDelay_0_bits_common_vpu_isOpMask),
    .io_deqDelay_0_bits_common_vpu_isMove(g_io_deqDelay_0_bits_common_vpu_isMove),
    .io_deqDelay_0_bits_common_vpu_isDependOldVd(g_io_deqDelay_0_bits_common_vpu_isDependOldVd),
    .io_deqDelay_0_bits_common_vpu_isWritePartVd(g_io_deqDelay_0_bits_common_vpu_isWritePartVd),
    .io_deqDelay_0_bits_common_vpu_isVleff(g_io_deqDelay_0_bits_common_vpu_isVleff),
    .io_deqDelay_0_bits_common_dataSources_0_value(g_io_deqDelay_0_bits_common_dataSources_0_value),
    .io_deqDelay_0_bits_common_dataSources_1_value(g_io_deqDelay_0_bits_common_dataSources_1_value),
    .io_deqDelay_0_bits_common_dataSources_2_value(g_io_deqDelay_0_bits_common_dataSources_2_value),
    .io_deqDelay_0_bits_common_dataSources_3_value(g_io_deqDelay_0_bits_common_dataSources_3_value),
    .io_deqDelay_0_bits_common_dataSources_4_value(g_io_deqDelay_0_bits_common_dataSources_4_value),
    .io_deqDelay_0_bits_common_perfDebugInfo_eliminatedMove(g_io_deqDelay_0_bits_common_perfDebugInfo_eliminatedMove),
    .io_deqDelay_0_bits_common_perfDebugInfo_renameTime(g_io_deqDelay_0_bits_common_perfDebugInfo_renameTime),
    .io_deqDelay_0_bits_common_perfDebugInfo_dispatchTime(g_io_deqDelay_0_bits_common_perfDebugInfo_dispatchTime),
    .io_deqDelay_0_bits_common_perfDebugInfo_enqRsTime(g_io_deqDelay_0_bits_common_perfDebugInfo_enqRsTime),
    .io_deqDelay_0_bits_common_perfDebugInfo_selectTime(g_io_deqDelay_0_bits_common_perfDebugInfo_selectTime),
    .io_deqDelay_0_bits_common_perfDebugInfo_issueTime(g_io_deqDelay_0_bits_common_perfDebugInfo_issueTime),
    .io_deqDelay_0_bits_common_perfDebugInfo_writebackTime(g_io_deqDelay_0_bits_common_perfDebugInfo_writebackTime),
    .io_deqDelay_0_bits_common_perfDebugInfo_runahead_checkpoint_id(g_io_deqDelay_0_bits_common_perfDebugInfo_runahead_checkpoint_id),
    .io_deqDelay_0_bits_common_perfDebugInfo_tlbFirstReqTime(g_io_deqDelay_0_bits_common_perfDebugInfo_tlbFirstReqTime),
    .io_deqDelay_0_bits_common_perfDebugInfo_tlbRespTime(g_io_deqDelay_0_bits_common_perfDebugInfo_tlbRespTime),
    .io_deqDelay_0_bits_common_debug_seqNum_seqNum(g_io_deqDelay_0_bits_common_debug_seqNum_seqNum),
    .io_deqDelay_0_bits_common_debug_seqNum_uopIdx(g_io_deqDelay_0_bits_common_debug_seqNum_uopIdx),
    .io_deqDelay_0_bits_addrOH(g_io_deqDelay_0_bits_addrOH)
  );
  IssueQueueVfdivVidiv_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_flush_valid(io_flush_valid),
    .io_flush_bits_robIdx_flag(io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value(io_flush_bits_robIdx_value),
    .io_flush_bits_level(io_flush_bits_level),
    .io_enq_0_valid(io_enq_0_valid),
    .io_enq_0_bits_instr(io_enq_0_bits_instr),
    .io_enq_0_bits_pc(io_enq_0_bits_pc),
    .io_enq_0_bits_foldpc(io_enq_0_bits_foldpc),
    .io_enq_0_bits_exceptionVec_0(io_enq_0_bits_exceptionVec_0),
    .io_enq_0_bits_exceptionVec_1(io_enq_0_bits_exceptionVec_1),
    .io_enq_0_bits_exceptionVec_2(io_enq_0_bits_exceptionVec_2),
    .io_enq_0_bits_exceptionVec_3(io_enq_0_bits_exceptionVec_3),
    .io_enq_0_bits_exceptionVec_4(io_enq_0_bits_exceptionVec_4),
    .io_enq_0_bits_exceptionVec_5(io_enq_0_bits_exceptionVec_5),
    .io_enq_0_bits_exceptionVec_6(io_enq_0_bits_exceptionVec_6),
    .io_enq_0_bits_exceptionVec_7(io_enq_0_bits_exceptionVec_7),
    .io_enq_0_bits_exceptionVec_8(io_enq_0_bits_exceptionVec_8),
    .io_enq_0_bits_exceptionVec_9(io_enq_0_bits_exceptionVec_9),
    .io_enq_0_bits_exceptionVec_10(io_enq_0_bits_exceptionVec_10),
    .io_enq_0_bits_exceptionVec_11(io_enq_0_bits_exceptionVec_11),
    .io_enq_0_bits_exceptionVec_12(io_enq_0_bits_exceptionVec_12),
    .io_enq_0_bits_exceptionVec_13(io_enq_0_bits_exceptionVec_13),
    .io_enq_0_bits_exceptionVec_14(io_enq_0_bits_exceptionVec_14),
    .io_enq_0_bits_exceptionVec_15(io_enq_0_bits_exceptionVec_15),
    .io_enq_0_bits_exceptionVec_16(io_enq_0_bits_exceptionVec_16),
    .io_enq_0_bits_exceptionVec_17(io_enq_0_bits_exceptionVec_17),
    .io_enq_0_bits_exceptionVec_18(io_enq_0_bits_exceptionVec_18),
    .io_enq_0_bits_exceptionVec_19(io_enq_0_bits_exceptionVec_19),
    .io_enq_0_bits_exceptionVec_20(io_enq_0_bits_exceptionVec_20),
    .io_enq_0_bits_exceptionVec_21(io_enq_0_bits_exceptionVec_21),
    .io_enq_0_bits_exceptionVec_22(io_enq_0_bits_exceptionVec_22),
    .io_enq_0_bits_exceptionVec_23(io_enq_0_bits_exceptionVec_23),
    .io_enq_0_bits_isFetchMalAddr(io_enq_0_bits_isFetchMalAddr),
    .io_enq_0_bits_hasException(io_enq_0_bits_hasException),
    .io_enq_0_bits_trigger(io_enq_0_bits_trigger),
    .io_enq_0_bits_preDecodeInfo_valid(io_enq_0_bits_preDecodeInfo_valid),
    .io_enq_0_bits_preDecodeInfo_isRVC(io_enq_0_bits_preDecodeInfo_isRVC),
    .io_enq_0_bits_preDecodeInfo_brType(io_enq_0_bits_preDecodeInfo_brType),
    .io_enq_0_bits_preDecodeInfo_isCall(io_enq_0_bits_preDecodeInfo_isCall),
    .io_enq_0_bits_preDecodeInfo_isRet(io_enq_0_bits_preDecodeInfo_isRet),
    .io_enq_0_bits_pred_taken(io_enq_0_bits_pred_taken),
    .io_enq_0_bits_crossPageIPFFix(io_enq_0_bits_crossPageIPFFix),
    .io_enq_0_bits_ftqPtr_flag(io_enq_0_bits_ftqPtr_flag),
    .io_enq_0_bits_ftqPtr_value(io_enq_0_bits_ftqPtr_value),
    .io_enq_0_bits_ftqOffset(io_enq_0_bits_ftqOffset),
    .io_enq_0_bits_satpFlushFirstFetchFault(io_enq_0_bits_satpFlushFirstFetchFault),
    .io_enq_0_bits_srcType_0(io_enq_0_bits_srcType_0),
    .io_enq_0_bits_srcType_1(io_enq_0_bits_srcType_1),
    .io_enq_0_bits_srcType_2(io_enq_0_bits_srcType_2),
    .io_enq_0_bits_srcType_3(io_enq_0_bits_srcType_3),
    .io_enq_0_bits_srcType_4(io_enq_0_bits_srcType_4),
    .io_enq_0_bits_ldest(io_enq_0_bits_ldest),
    .io_enq_0_bits_fuType(io_enq_0_bits_fuType),
    .io_enq_0_bits_fuOpType(io_enq_0_bits_fuOpType),
    .io_enq_0_bits_rfWen(io_enq_0_bits_rfWen),
    .io_enq_0_bits_fpWen(io_enq_0_bits_fpWen),
    .io_enq_0_bits_vecWen(io_enq_0_bits_vecWen),
    .io_enq_0_bits_v0Wen(io_enq_0_bits_v0Wen),
    .io_enq_0_bits_vlWen(io_enq_0_bits_vlWen),
    .io_enq_0_bits_isXSTrap(io_enq_0_bits_isXSTrap),
    .io_enq_0_bits_waitForward(io_enq_0_bits_waitForward),
    .io_enq_0_bits_blockBackward(io_enq_0_bits_blockBackward),
    .io_enq_0_bits_flushPipe(io_enq_0_bits_flushPipe),
    .io_enq_0_bits_canRobCompress(io_enq_0_bits_canRobCompress),
    .io_enq_0_bits_selImm(io_enq_0_bits_selImm),
    .io_enq_0_bits_imm(io_enq_0_bits_imm),
    .io_enq_0_bits_fpu_typeTagOut(io_enq_0_bits_fpu_typeTagOut),
    .io_enq_0_bits_fpu_wflags(io_enq_0_bits_fpu_wflags),
    .io_enq_0_bits_fpu_typ(io_enq_0_bits_fpu_typ),
    .io_enq_0_bits_fpu_fmt(io_enq_0_bits_fpu_fmt),
    .io_enq_0_bits_fpu_rm(io_enq_0_bits_fpu_rm),
    .io_enq_0_bits_vpu_vill(io_enq_0_bits_vpu_vill),
    .io_enq_0_bits_vpu_vma(io_enq_0_bits_vpu_vma),
    .io_enq_0_bits_vpu_vta(io_enq_0_bits_vpu_vta),
    .io_enq_0_bits_vpu_vsew(io_enq_0_bits_vpu_vsew),
    .io_enq_0_bits_vpu_vlmul(io_enq_0_bits_vpu_vlmul),
    .io_enq_0_bits_vpu_specVill(io_enq_0_bits_vpu_specVill),
    .io_enq_0_bits_vpu_specVma(io_enq_0_bits_vpu_specVma),
    .io_enq_0_bits_vpu_specVta(io_enq_0_bits_vpu_specVta),
    .io_enq_0_bits_vpu_specVsew(io_enq_0_bits_vpu_specVsew),
    .io_enq_0_bits_vpu_specVlmul(io_enq_0_bits_vpu_specVlmul),
    .io_enq_0_bits_vpu_vm(io_enq_0_bits_vpu_vm),
    .io_enq_0_bits_vpu_vstart(io_enq_0_bits_vpu_vstart),
    .io_enq_0_bits_vpu_frm(io_enq_0_bits_vpu_frm),
    .io_enq_0_bits_vpu_fpu_isFpToVecInst(io_enq_0_bits_vpu_fpu_isFpToVecInst),
    .io_enq_0_bits_vpu_fpu_isFP32Instr(io_enq_0_bits_vpu_fpu_isFP32Instr),
    .io_enq_0_bits_vpu_fpu_isFP64Instr(io_enq_0_bits_vpu_fpu_isFP64Instr),
    .io_enq_0_bits_vpu_fpu_isReduction(io_enq_0_bits_vpu_fpu_isReduction),
    .io_enq_0_bits_vpu_fpu_isFoldTo1_2(io_enq_0_bits_vpu_fpu_isFoldTo1_2),
    .io_enq_0_bits_vpu_fpu_isFoldTo1_4(io_enq_0_bits_vpu_fpu_isFoldTo1_4),
    .io_enq_0_bits_vpu_fpu_isFoldTo1_8(io_enq_0_bits_vpu_fpu_isFoldTo1_8),
    .io_enq_0_bits_vpu_vxrm(io_enq_0_bits_vpu_vxrm),
    .io_enq_0_bits_vpu_vuopIdx(io_enq_0_bits_vpu_vuopIdx),
    .io_enq_0_bits_vpu_lastUop(io_enq_0_bits_vpu_lastUop),
    .io_enq_0_bits_vpu_vmask(io_enq_0_bits_vpu_vmask),
    .io_enq_0_bits_vpu_vl(io_enq_0_bits_vpu_vl),
    .io_enq_0_bits_vpu_nf(io_enq_0_bits_vpu_nf),
    .io_enq_0_bits_vpu_veew(io_enq_0_bits_vpu_veew),
    .io_enq_0_bits_vpu_isReverse(io_enq_0_bits_vpu_isReverse),
    .io_enq_0_bits_vpu_isExt(io_enq_0_bits_vpu_isExt),
    .io_enq_0_bits_vpu_isNarrow(io_enq_0_bits_vpu_isNarrow),
    .io_enq_0_bits_vpu_isDstMask(io_enq_0_bits_vpu_isDstMask),
    .io_enq_0_bits_vpu_isOpMask(io_enq_0_bits_vpu_isOpMask),
    .io_enq_0_bits_vpu_isMove(io_enq_0_bits_vpu_isMove),
    .io_enq_0_bits_vpu_isDependOldVd(io_enq_0_bits_vpu_isDependOldVd),
    .io_enq_0_bits_vpu_isWritePartVd(io_enq_0_bits_vpu_isWritePartVd),
    .io_enq_0_bits_vpu_isVleff(io_enq_0_bits_vpu_isVleff),
    .io_enq_0_bits_vlsInstr(io_enq_0_bits_vlsInstr),
    .io_enq_0_bits_wfflags(io_enq_0_bits_wfflags),
    .io_enq_0_bits_isMove(io_enq_0_bits_isMove),
    .io_enq_0_bits_isDropAmocasSta(io_enq_0_bits_isDropAmocasSta),
    .io_enq_0_bits_uopIdx(io_enq_0_bits_uopIdx),
    .io_enq_0_bits_isVset(io_enq_0_bits_isVset),
    .io_enq_0_bits_firstUop(io_enq_0_bits_firstUop),
    .io_enq_0_bits_lastUop(io_enq_0_bits_lastUop),
    .io_enq_0_bits_numUops(io_enq_0_bits_numUops),
    .io_enq_0_bits_numWB(io_enq_0_bits_numWB),
    .io_enq_0_bits_commitType(io_enq_0_bits_commitType),
    .io_enq_0_bits_srcState_0(io_enq_0_bits_srcState_0),
    .io_enq_0_bits_srcState_1(io_enq_0_bits_srcState_1),
    .io_enq_0_bits_srcState_2(io_enq_0_bits_srcState_2),
    .io_enq_0_bits_srcState_3(io_enq_0_bits_srcState_3),
    .io_enq_0_bits_srcState_4(io_enq_0_bits_srcState_4),
    .io_enq_0_bits_psrc_0(io_enq_0_bits_psrc_0),
    .io_enq_0_bits_psrc_1(io_enq_0_bits_psrc_1),
    .io_enq_0_bits_psrc_2(io_enq_0_bits_psrc_2),
    .io_enq_0_bits_psrc_3(io_enq_0_bits_psrc_3),
    .io_enq_0_bits_psrc_4(io_enq_0_bits_psrc_4),
    .io_enq_0_bits_pdest(io_enq_0_bits_pdest),
    .io_enq_0_bits_useRegCache_0(io_enq_0_bits_useRegCache_0),
    .io_enq_0_bits_useRegCache_1(io_enq_0_bits_useRegCache_1),
    .io_enq_0_bits_regCacheIdx_0(io_enq_0_bits_regCacheIdx_0),
    .io_enq_0_bits_regCacheIdx_1(io_enq_0_bits_regCacheIdx_1),
    .io_enq_0_bits_robIdx_flag(io_enq_0_bits_robIdx_flag),
    .io_enq_0_bits_robIdx_value(io_enq_0_bits_robIdx_value),
    .io_enq_0_bits_instrSize(io_enq_0_bits_instrSize),
    .io_enq_0_bits_dirtyFs(io_enq_0_bits_dirtyFs),
    .io_enq_0_bits_dirtyVs(io_enq_0_bits_dirtyVs),
    .io_enq_0_bits_traceBlockInPipe_itype(io_enq_0_bits_traceBlockInPipe_itype),
    .io_enq_0_bits_traceBlockInPipe_iretire(io_enq_0_bits_traceBlockInPipe_iretire),
    .io_enq_0_bits_traceBlockInPipe_ilastsize(io_enq_0_bits_traceBlockInPipe_ilastsize),
    .io_enq_0_bits_eliminatedMove(io_enq_0_bits_eliminatedMove),
    .io_enq_0_bits_snapshot(io_enq_0_bits_snapshot),
    .io_enq_0_bits_debugInfo_eliminatedMove(io_enq_0_bits_debugInfo_eliminatedMove),
    .io_enq_0_bits_debugInfo_renameTime(io_enq_0_bits_debugInfo_renameTime),
    .io_enq_0_bits_debugInfo_dispatchTime(io_enq_0_bits_debugInfo_dispatchTime),
    .io_enq_0_bits_debugInfo_enqRsTime(io_enq_0_bits_debugInfo_enqRsTime),
    .io_enq_0_bits_debugInfo_selectTime(io_enq_0_bits_debugInfo_selectTime),
    .io_enq_0_bits_debugInfo_issueTime(io_enq_0_bits_debugInfo_issueTime),
    .io_enq_0_bits_debugInfo_writebackTime(io_enq_0_bits_debugInfo_writebackTime),
    .io_enq_0_bits_debugInfo_runahead_checkpoint_id(io_enq_0_bits_debugInfo_runahead_checkpoint_id),
    .io_enq_0_bits_debugInfo_tlbFirstReqTime(io_enq_0_bits_debugInfo_tlbFirstReqTime),
    .io_enq_0_bits_debugInfo_tlbRespTime(io_enq_0_bits_debugInfo_tlbRespTime),
    .io_enq_0_bits_debug_seqNum_seqNum(io_enq_0_bits_debug_seqNum_seqNum),
    .io_enq_0_bits_debug_seqNum_uopIdx(io_enq_0_bits_debug_seqNum_uopIdx),
    .io_enq_0_bits_storeSetHit(io_enq_0_bits_storeSetHit),
    .io_enq_0_bits_waitForRobIdx_flag(io_enq_0_bits_waitForRobIdx_flag),
    .io_enq_0_bits_waitForRobIdx_value(io_enq_0_bits_waitForRobIdx_value),
    .io_enq_0_bits_loadWaitBit(io_enq_0_bits_loadWaitBit),
    .io_enq_0_bits_loadWaitStrict(io_enq_0_bits_loadWaitStrict),
    .io_enq_0_bits_ssid(io_enq_0_bits_ssid),
    .io_enq_0_bits_lqIdx_flag(io_enq_0_bits_lqIdx_flag),
    .io_enq_0_bits_lqIdx_value(io_enq_0_bits_lqIdx_value),
    .io_enq_0_bits_sqIdx_flag(io_enq_0_bits_sqIdx_flag),
    .io_enq_0_bits_sqIdx_value(io_enq_0_bits_sqIdx_value),
    .io_enq_0_bits_singleStep(io_enq_0_bits_singleStep),
    .io_enq_0_bits_replayInst(io_enq_0_bits_replayInst),
    .io_enq_0_bits_debug_fuType(io_enq_0_bits_debug_fuType),
    .io_enq_0_bits_debug_sim_trig(io_enq_0_bits_debug_sim_trig),
    .io_enq_0_bits_numLsElem(io_enq_0_bits_numLsElem),
    .io_enq_1_valid(io_enq_1_valid),
    .io_enq_1_bits_instr(io_enq_1_bits_instr),
    .io_enq_1_bits_pc(io_enq_1_bits_pc),
    .io_enq_1_bits_foldpc(io_enq_1_bits_foldpc),
    .io_enq_1_bits_exceptionVec_0(io_enq_1_bits_exceptionVec_0),
    .io_enq_1_bits_exceptionVec_1(io_enq_1_bits_exceptionVec_1),
    .io_enq_1_bits_exceptionVec_2(io_enq_1_bits_exceptionVec_2),
    .io_enq_1_bits_exceptionVec_3(io_enq_1_bits_exceptionVec_3),
    .io_enq_1_bits_exceptionVec_4(io_enq_1_bits_exceptionVec_4),
    .io_enq_1_bits_exceptionVec_5(io_enq_1_bits_exceptionVec_5),
    .io_enq_1_bits_exceptionVec_6(io_enq_1_bits_exceptionVec_6),
    .io_enq_1_bits_exceptionVec_7(io_enq_1_bits_exceptionVec_7),
    .io_enq_1_bits_exceptionVec_8(io_enq_1_bits_exceptionVec_8),
    .io_enq_1_bits_exceptionVec_9(io_enq_1_bits_exceptionVec_9),
    .io_enq_1_bits_exceptionVec_10(io_enq_1_bits_exceptionVec_10),
    .io_enq_1_bits_exceptionVec_11(io_enq_1_bits_exceptionVec_11),
    .io_enq_1_bits_exceptionVec_12(io_enq_1_bits_exceptionVec_12),
    .io_enq_1_bits_exceptionVec_13(io_enq_1_bits_exceptionVec_13),
    .io_enq_1_bits_exceptionVec_14(io_enq_1_bits_exceptionVec_14),
    .io_enq_1_bits_exceptionVec_15(io_enq_1_bits_exceptionVec_15),
    .io_enq_1_bits_exceptionVec_16(io_enq_1_bits_exceptionVec_16),
    .io_enq_1_bits_exceptionVec_17(io_enq_1_bits_exceptionVec_17),
    .io_enq_1_bits_exceptionVec_18(io_enq_1_bits_exceptionVec_18),
    .io_enq_1_bits_exceptionVec_19(io_enq_1_bits_exceptionVec_19),
    .io_enq_1_bits_exceptionVec_20(io_enq_1_bits_exceptionVec_20),
    .io_enq_1_bits_exceptionVec_21(io_enq_1_bits_exceptionVec_21),
    .io_enq_1_bits_exceptionVec_22(io_enq_1_bits_exceptionVec_22),
    .io_enq_1_bits_exceptionVec_23(io_enq_1_bits_exceptionVec_23),
    .io_enq_1_bits_isFetchMalAddr(io_enq_1_bits_isFetchMalAddr),
    .io_enq_1_bits_hasException(io_enq_1_bits_hasException),
    .io_enq_1_bits_trigger(io_enq_1_bits_trigger),
    .io_enq_1_bits_preDecodeInfo_valid(io_enq_1_bits_preDecodeInfo_valid),
    .io_enq_1_bits_preDecodeInfo_isRVC(io_enq_1_bits_preDecodeInfo_isRVC),
    .io_enq_1_bits_preDecodeInfo_brType(io_enq_1_bits_preDecodeInfo_brType),
    .io_enq_1_bits_preDecodeInfo_isCall(io_enq_1_bits_preDecodeInfo_isCall),
    .io_enq_1_bits_preDecodeInfo_isRet(io_enq_1_bits_preDecodeInfo_isRet),
    .io_enq_1_bits_pred_taken(io_enq_1_bits_pred_taken),
    .io_enq_1_bits_crossPageIPFFix(io_enq_1_bits_crossPageIPFFix),
    .io_enq_1_bits_ftqPtr_flag(io_enq_1_bits_ftqPtr_flag),
    .io_enq_1_bits_ftqPtr_value(io_enq_1_bits_ftqPtr_value),
    .io_enq_1_bits_ftqOffset(io_enq_1_bits_ftqOffset),
    .io_enq_1_bits_satpFlushFirstFetchFault(io_enq_1_bits_satpFlushFirstFetchFault),
    .io_enq_1_bits_srcType_0(io_enq_1_bits_srcType_0),
    .io_enq_1_bits_srcType_1(io_enq_1_bits_srcType_1),
    .io_enq_1_bits_srcType_2(io_enq_1_bits_srcType_2),
    .io_enq_1_bits_srcType_3(io_enq_1_bits_srcType_3),
    .io_enq_1_bits_srcType_4(io_enq_1_bits_srcType_4),
    .io_enq_1_bits_ldest(io_enq_1_bits_ldest),
    .io_enq_1_bits_fuType(io_enq_1_bits_fuType),
    .io_enq_1_bits_fuOpType(io_enq_1_bits_fuOpType),
    .io_enq_1_bits_rfWen(io_enq_1_bits_rfWen),
    .io_enq_1_bits_fpWen(io_enq_1_bits_fpWen),
    .io_enq_1_bits_vecWen(io_enq_1_bits_vecWen),
    .io_enq_1_bits_v0Wen(io_enq_1_bits_v0Wen),
    .io_enq_1_bits_vlWen(io_enq_1_bits_vlWen),
    .io_enq_1_bits_isXSTrap(io_enq_1_bits_isXSTrap),
    .io_enq_1_bits_waitForward(io_enq_1_bits_waitForward),
    .io_enq_1_bits_blockBackward(io_enq_1_bits_blockBackward),
    .io_enq_1_bits_flushPipe(io_enq_1_bits_flushPipe),
    .io_enq_1_bits_canRobCompress(io_enq_1_bits_canRobCompress),
    .io_enq_1_bits_selImm(io_enq_1_bits_selImm),
    .io_enq_1_bits_imm(io_enq_1_bits_imm),
    .io_enq_1_bits_fpu_typeTagOut(io_enq_1_bits_fpu_typeTagOut),
    .io_enq_1_bits_fpu_wflags(io_enq_1_bits_fpu_wflags),
    .io_enq_1_bits_fpu_typ(io_enq_1_bits_fpu_typ),
    .io_enq_1_bits_fpu_fmt(io_enq_1_bits_fpu_fmt),
    .io_enq_1_bits_fpu_rm(io_enq_1_bits_fpu_rm),
    .io_enq_1_bits_vpu_vill(io_enq_1_bits_vpu_vill),
    .io_enq_1_bits_vpu_vma(io_enq_1_bits_vpu_vma),
    .io_enq_1_bits_vpu_vta(io_enq_1_bits_vpu_vta),
    .io_enq_1_bits_vpu_vsew(io_enq_1_bits_vpu_vsew),
    .io_enq_1_bits_vpu_vlmul(io_enq_1_bits_vpu_vlmul),
    .io_enq_1_bits_vpu_specVill(io_enq_1_bits_vpu_specVill),
    .io_enq_1_bits_vpu_specVma(io_enq_1_bits_vpu_specVma),
    .io_enq_1_bits_vpu_specVta(io_enq_1_bits_vpu_specVta),
    .io_enq_1_bits_vpu_specVsew(io_enq_1_bits_vpu_specVsew),
    .io_enq_1_bits_vpu_specVlmul(io_enq_1_bits_vpu_specVlmul),
    .io_enq_1_bits_vpu_vm(io_enq_1_bits_vpu_vm),
    .io_enq_1_bits_vpu_vstart(io_enq_1_bits_vpu_vstart),
    .io_enq_1_bits_vpu_frm(io_enq_1_bits_vpu_frm),
    .io_enq_1_bits_vpu_fpu_isFpToVecInst(io_enq_1_bits_vpu_fpu_isFpToVecInst),
    .io_enq_1_bits_vpu_fpu_isFP32Instr(io_enq_1_bits_vpu_fpu_isFP32Instr),
    .io_enq_1_bits_vpu_fpu_isFP64Instr(io_enq_1_bits_vpu_fpu_isFP64Instr),
    .io_enq_1_bits_vpu_fpu_isReduction(io_enq_1_bits_vpu_fpu_isReduction),
    .io_enq_1_bits_vpu_fpu_isFoldTo1_2(io_enq_1_bits_vpu_fpu_isFoldTo1_2),
    .io_enq_1_bits_vpu_fpu_isFoldTo1_4(io_enq_1_bits_vpu_fpu_isFoldTo1_4),
    .io_enq_1_bits_vpu_fpu_isFoldTo1_8(io_enq_1_bits_vpu_fpu_isFoldTo1_8),
    .io_enq_1_bits_vpu_vxrm(io_enq_1_bits_vpu_vxrm),
    .io_enq_1_bits_vpu_vuopIdx(io_enq_1_bits_vpu_vuopIdx),
    .io_enq_1_bits_vpu_lastUop(io_enq_1_bits_vpu_lastUop),
    .io_enq_1_bits_vpu_vmask(io_enq_1_bits_vpu_vmask),
    .io_enq_1_bits_vpu_vl(io_enq_1_bits_vpu_vl),
    .io_enq_1_bits_vpu_nf(io_enq_1_bits_vpu_nf),
    .io_enq_1_bits_vpu_veew(io_enq_1_bits_vpu_veew),
    .io_enq_1_bits_vpu_isReverse(io_enq_1_bits_vpu_isReverse),
    .io_enq_1_bits_vpu_isExt(io_enq_1_bits_vpu_isExt),
    .io_enq_1_bits_vpu_isNarrow(io_enq_1_bits_vpu_isNarrow),
    .io_enq_1_bits_vpu_isDstMask(io_enq_1_bits_vpu_isDstMask),
    .io_enq_1_bits_vpu_isOpMask(io_enq_1_bits_vpu_isOpMask),
    .io_enq_1_bits_vpu_isMove(io_enq_1_bits_vpu_isMove),
    .io_enq_1_bits_vpu_isDependOldVd(io_enq_1_bits_vpu_isDependOldVd),
    .io_enq_1_bits_vpu_isWritePartVd(io_enq_1_bits_vpu_isWritePartVd),
    .io_enq_1_bits_vpu_isVleff(io_enq_1_bits_vpu_isVleff),
    .io_enq_1_bits_vlsInstr(io_enq_1_bits_vlsInstr),
    .io_enq_1_bits_wfflags(io_enq_1_bits_wfflags),
    .io_enq_1_bits_isMove(io_enq_1_bits_isMove),
    .io_enq_1_bits_isDropAmocasSta(io_enq_1_bits_isDropAmocasSta),
    .io_enq_1_bits_uopIdx(io_enq_1_bits_uopIdx),
    .io_enq_1_bits_isVset(io_enq_1_bits_isVset),
    .io_enq_1_bits_firstUop(io_enq_1_bits_firstUop),
    .io_enq_1_bits_lastUop(io_enq_1_bits_lastUop),
    .io_enq_1_bits_numUops(io_enq_1_bits_numUops),
    .io_enq_1_bits_numWB(io_enq_1_bits_numWB),
    .io_enq_1_bits_commitType(io_enq_1_bits_commitType),
    .io_enq_1_bits_srcState_0(io_enq_1_bits_srcState_0),
    .io_enq_1_bits_srcState_1(io_enq_1_bits_srcState_1),
    .io_enq_1_bits_srcState_2(io_enq_1_bits_srcState_2),
    .io_enq_1_bits_srcState_3(io_enq_1_bits_srcState_3),
    .io_enq_1_bits_srcState_4(io_enq_1_bits_srcState_4),
    .io_enq_1_bits_psrc_0(io_enq_1_bits_psrc_0),
    .io_enq_1_bits_psrc_1(io_enq_1_bits_psrc_1),
    .io_enq_1_bits_psrc_2(io_enq_1_bits_psrc_2),
    .io_enq_1_bits_psrc_3(io_enq_1_bits_psrc_3),
    .io_enq_1_bits_psrc_4(io_enq_1_bits_psrc_4),
    .io_enq_1_bits_pdest(io_enq_1_bits_pdest),
    .io_enq_1_bits_useRegCache_0(io_enq_1_bits_useRegCache_0),
    .io_enq_1_bits_useRegCache_1(io_enq_1_bits_useRegCache_1),
    .io_enq_1_bits_regCacheIdx_0(io_enq_1_bits_regCacheIdx_0),
    .io_enq_1_bits_regCacheIdx_1(io_enq_1_bits_regCacheIdx_1),
    .io_enq_1_bits_robIdx_flag(io_enq_1_bits_robIdx_flag),
    .io_enq_1_bits_robIdx_value(io_enq_1_bits_robIdx_value),
    .io_enq_1_bits_instrSize(io_enq_1_bits_instrSize),
    .io_enq_1_bits_dirtyFs(io_enq_1_bits_dirtyFs),
    .io_enq_1_bits_dirtyVs(io_enq_1_bits_dirtyVs),
    .io_enq_1_bits_traceBlockInPipe_itype(io_enq_1_bits_traceBlockInPipe_itype),
    .io_enq_1_bits_traceBlockInPipe_iretire(io_enq_1_bits_traceBlockInPipe_iretire),
    .io_enq_1_bits_traceBlockInPipe_ilastsize(io_enq_1_bits_traceBlockInPipe_ilastsize),
    .io_enq_1_bits_eliminatedMove(io_enq_1_bits_eliminatedMove),
    .io_enq_1_bits_snapshot(io_enq_1_bits_snapshot),
    .io_enq_1_bits_debugInfo_eliminatedMove(io_enq_1_bits_debugInfo_eliminatedMove),
    .io_enq_1_bits_debugInfo_renameTime(io_enq_1_bits_debugInfo_renameTime),
    .io_enq_1_bits_debugInfo_dispatchTime(io_enq_1_bits_debugInfo_dispatchTime),
    .io_enq_1_bits_debugInfo_enqRsTime(io_enq_1_bits_debugInfo_enqRsTime),
    .io_enq_1_bits_debugInfo_selectTime(io_enq_1_bits_debugInfo_selectTime),
    .io_enq_1_bits_debugInfo_issueTime(io_enq_1_bits_debugInfo_issueTime),
    .io_enq_1_bits_debugInfo_writebackTime(io_enq_1_bits_debugInfo_writebackTime),
    .io_enq_1_bits_debugInfo_runahead_checkpoint_id(io_enq_1_bits_debugInfo_runahead_checkpoint_id),
    .io_enq_1_bits_debugInfo_tlbFirstReqTime(io_enq_1_bits_debugInfo_tlbFirstReqTime),
    .io_enq_1_bits_debugInfo_tlbRespTime(io_enq_1_bits_debugInfo_tlbRespTime),
    .io_enq_1_bits_debug_seqNum_seqNum(io_enq_1_bits_debug_seqNum_seqNum),
    .io_enq_1_bits_debug_seqNum_uopIdx(io_enq_1_bits_debug_seqNum_uopIdx),
    .io_enq_1_bits_storeSetHit(io_enq_1_bits_storeSetHit),
    .io_enq_1_bits_waitForRobIdx_flag(io_enq_1_bits_waitForRobIdx_flag),
    .io_enq_1_bits_waitForRobIdx_value(io_enq_1_bits_waitForRobIdx_value),
    .io_enq_1_bits_loadWaitBit(io_enq_1_bits_loadWaitBit),
    .io_enq_1_bits_loadWaitStrict(io_enq_1_bits_loadWaitStrict),
    .io_enq_1_bits_ssid(io_enq_1_bits_ssid),
    .io_enq_1_bits_lqIdx_flag(io_enq_1_bits_lqIdx_flag),
    .io_enq_1_bits_lqIdx_value(io_enq_1_bits_lqIdx_value),
    .io_enq_1_bits_sqIdx_flag(io_enq_1_bits_sqIdx_flag),
    .io_enq_1_bits_sqIdx_value(io_enq_1_bits_sqIdx_value),
    .io_enq_1_bits_singleStep(io_enq_1_bits_singleStep),
    .io_enq_1_bits_replayInst(io_enq_1_bits_replayInst),
    .io_enq_1_bits_debug_fuType(io_enq_1_bits_debug_fuType),
    .io_enq_1_bits_debug_sim_trig(io_enq_1_bits_debug_sim_trig),
    .io_enq_1_bits_numLsElem(io_enq_1_bits_numLsElem),
    .io_og0Resp_0_valid(io_og0Resp_0_valid),
    .io_og1Resp_0_valid(io_og1Resp_0_valid),
    .io_og2Resp_0_valid(io_og2Resp_0_valid),
    .io_og2Resp_0_bits_resp(io_og2Resp_0_bits_resp),
    .io_wakeupFromWB_15_valid(io_wakeupFromWB_15_valid),
    .io_wakeupFromWB_15_bits_vlWen(io_wakeupFromWB_15_bits_vlWen),
    .io_wakeupFromWB_15_bits_pdest(io_wakeupFromWB_15_bits_pdest),
    .io_wakeupFromWB_14_valid(io_wakeupFromWB_14_valid),
    .io_wakeupFromWB_14_bits_vlWen(io_wakeupFromWB_14_bits_vlWen),
    .io_wakeupFromWB_14_bits_pdest(io_wakeupFromWB_14_bits_pdest),
    .io_wakeupFromWB_13_valid(io_wakeupFromWB_13_valid),
    .io_wakeupFromWB_13_bits_vlWen(io_wakeupFromWB_13_bits_vlWen),
    .io_wakeupFromWB_13_bits_pdest(io_wakeupFromWB_13_bits_pdest),
    .io_wakeupFromWB_12_valid(io_wakeupFromWB_12_valid),
    .io_wakeupFromWB_12_bits_vlWen(io_wakeupFromWB_12_bits_vlWen),
    .io_wakeupFromWB_12_bits_pdest(io_wakeupFromWB_12_bits_pdest),
    .io_wakeupFromWB_11_valid(io_wakeupFromWB_11_valid),
    .io_wakeupFromWB_11_bits_v0Wen(io_wakeupFromWB_11_bits_v0Wen),
    .io_wakeupFromWB_11_bits_pdest(io_wakeupFromWB_11_bits_pdest),
    .io_wakeupFromWB_10_valid(io_wakeupFromWB_10_valid),
    .io_wakeupFromWB_10_bits_v0Wen(io_wakeupFromWB_10_bits_v0Wen),
    .io_wakeupFromWB_10_bits_pdest(io_wakeupFromWB_10_bits_pdest),
    .io_wakeupFromWB_9_valid(io_wakeupFromWB_9_valid),
    .io_wakeupFromWB_9_bits_v0Wen(io_wakeupFromWB_9_bits_v0Wen),
    .io_wakeupFromWB_9_bits_pdest(io_wakeupFromWB_9_bits_pdest),
    .io_wakeupFromWB_8_valid(io_wakeupFromWB_8_valid),
    .io_wakeupFromWB_8_bits_v0Wen(io_wakeupFromWB_8_bits_v0Wen),
    .io_wakeupFromWB_8_bits_pdest(io_wakeupFromWB_8_bits_pdest),
    .io_wakeupFromWB_7_valid(io_wakeupFromWB_7_valid),
    .io_wakeupFromWB_7_bits_v0Wen(io_wakeupFromWB_7_bits_v0Wen),
    .io_wakeupFromWB_7_bits_pdest(io_wakeupFromWB_7_bits_pdest),
    .io_wakeupFromWB_6_valid(io_wakeupFromWB_6_valid),
    .io_wakeupFromWB_6_bits_v0Wen(io_wakeupFromWB_6_bits_v0Wen),
    .io_wakeupFromWB_6_bits_pdest(io_wakeupFromWB_6_bits_pdest),
    .io_wakeupFromWB_5_valid(io_wakeupFromWB_5_valid),
    .io_wakeupFromWB_5_bits_vecWen(io_wakeupFromWB_5_bits_vecWen),
    .io_wakeupFromWB_5_bits_pdest(io_wakeupFromWB_5_bits_pdest),
    .io_wakeupFromWB_4_valid(io_wakeupFromWB_4_valid),
    .io_wakeupFromWB_4_bits_vecWen(io_wakeupFromWB_4_bits_vecWen),
    .io_wakeupFromWB_4_bits_pdest(io_wakeupFromWB_4_bits_pdest),
    .io_wakeupFromWB_3_valid(io_wakeupFromWB_3_valid),
    .io_wakeupFromWB_3_bits_vecWen(io_wakeupFromWB_3_bits_vecWen),
    .io_wakeupFromWB_3_bits_pdest(io_wakeupFromWB_3_bits_pdest),
    .io_wakeupFromWB_2_valid(io_wakeupFromWB_2_valid),
    .io_wakeupFromWB_2_bits_vecWen(io_wakeupFromWB_2_bits_vecWen),
    .io_wakeupFromWB_2_bits_pdest(io_wakeupFromWB_2_bits_pdest),
    .io_wakeupFromWB_1_valid(io_wakeupFromWB_1_valid),
    .io_wakeupFromWB_1_bits_vecWen(io_wakeupFromWB_1_bits_vecWen),
    .io_wakeupFromWB_1_bits_pdest(io_wakeupFromWB_1_bits_pdest),
    .io_wakeupFromWB_0_valid(io_wakeupFromWB_0_valid),
    .io_wakeupFromWB_0_bits_vecWen(io_wakeupFromWB_0_bits_vecWen),
    .io_wakeupFromWB_0_bits_pdest(io_wakeupFromWB_0_bits_pdest),
    .io_wakeupFromWBDelayed_15_valid(io_wakeupFromWBDelayed_15_valid),
    .io_wakeupFromWBDelayed_15_bits_vlWen(io_wakeupFromWBDelayed_15_bits_vlWen),
    .io_wakeupFromWBDelayed_15_bits_pdest(io_wakeupFromWBDelayed_15_bits_pdest),
    .io_wakeupFromWBDelayed_14_valid(io_wakeupFromWBDelayed_14_valid),
    .io_wakeupFromWBDelayed_14_bits_vlWen(io_wakeupFromWBDelayed_14_bits_vlWen),
    .io_wakeupFromWBDelayed_14_bits_pdest(io_wakeupFromWBDelayed_14_bits_pdest),
    .io_wakeupFromWBDelayed_13_valid(io_wakeupFromWBDelayed_13_valid),
    .io_wakeupFromWBDelayed_13_bits_vlWen(io_wakeupFromWBDelayed_13_bits_vlWen),
    .io_wakeupFromWBDelayed_13_bits_pdest(io_wakeupFromWBDelayed_13_bits_pdest),
    .io_wakeupFromWBDelayed_12_valid(io_wakeupFromWBDelayed_12_valid),
    .io_wakeupFromWBDelayed_12_bits_vlWen(io_wakeupFromWBDelayed_12_bits_vlWen),
    .io_wakeupFromWBDelayed_12_bits_pdest(io_wakeupFromWBDelayed_12_bits_pdest),
    .io_wakeupFromWBDelayed_11_valid(io_wakeupFromWBDelayed_11_valid),
    .io_wakeupFromWBDelayed_11_bits_v0Wen(io_wakeupFromWBDelayed_11_bits_v0Wen),
    .io_wakeupFromWBDelayed_11_bits_pdest(io_wakeupFromWBDelayed_11_bits_pdest),
    .io_wakeupFromWBDelayed_10_valid(io_wakeupFromWBDelayed_10_valid),
    .io_wakeupFromWBDelayed_10_bits_v0Wen(io_wakeupFromWBDelayed_10_bits_v0Wen),
    .io_wakeupFromWBDelayed_10_bits_pdest(io_wakeupFromWBDelayed_10_bits_pdest),
    .io_wakeupFromWBDelayed_9_valid(io_wakeupFromWBDelayed_9_valid),
    .io_wakeupFromWBDelayed_9_bits_v0Wen(io_wakeupFromWBDelayed_9_bits_v0Wen),
    .io_wakeupFromWBDelayed_9_bits_pdest(io_wakeupFromWBDelayed_9_bits_pdest),
    .io_wakeupFromWBDelayed_8_valid(io_wakeupFromWBDelayed_8_valid),
    .io_wakeupFromWBDelayed_8_bits_v0Wen(io_wakeupFromWBDelayed_8_bits_v0Wen),
    .io_wakeupFromWBDelayed_8_bits_pdest(io_wakeupFromWBDelayed_8_bits_pdest),
    .io_wakeupFromWBDelayed_7_valid(io_wakeupFromWBDelayed_7_valid),
    .io_wakeupFromWBDelayed_7_bits_v0Wen(io_wakeupFromWBDelayed_7_bits_v0Wen),
    .io_wakeupFromWBDelayed_7_bits_pdest(io_wakeupFromWBDelayed_7_bits_pdest),
    .io_wakeupFromWBDelayed_6_valid(io_wakeupFromWBDelayed_6_valid),
    .io_wakeupFromWBDelayed_6_bits_v0Wen(io_wakeupFromWBDelayed_6_bits_v0Wen),
    .io_wakeupFromWBDelayed_6_bits_pdest(io_wakeupFromWBDelayed_6_bits_pdest),
    .io_wakeupFromWBDelayed_5_valid(io_wakeupFromWBDelayed_5_valid),
    .io_wakeupFromWBDelayed_5_bits_vecWen(io_wakeupFromWBDelayed_5_bits_vecWen),
    .io_wakeupFromWBDelayed_5_bits_pdest(io_wakeupFromWBDelayed_5_bits_pdest),
    .io_wakeupFromWBDelayed_4_valid(io_wakeupFromWBDelayed_4_valid),
    .io_wakeupFromWBDelayed_4_bits_vecWen(io_wakeupFromWBDelayed_4_bits_vecWen),
    .io_wakeupFromWBDelayed_4_bits_pdest(io_wakeupFromWBDelayed_4_bits_pdest),
    .io_wakeupFromWBDelayed_3_valid(io_wakeupFromWBDelayed_3_valid),
    .io_wakeupFromWBDelayed_3_bits_vecWen(io_wakeupFromWBDelayed_3_bits_vecWen),
    .io_wakeupFromWBDelayed_3_bits_pdest(io_wakeupFromWBDelayed_3_bits_pdest),
    .io_wakeupFromWBDelayed_2_valid(io_wakeupFromWBDelayed_2_valid),
    .io_wakeupFromWBDelayed_2_bits_vecWen(io_wakeupFromWBDelayed_2_bits_vecWen),
    .io_wakeupFromWBDelayed_2_bits_pdest(io_wakeupFromWBDelayed_2_bits_pdest),
    .io_wakeupFromWBDelayed_1_valid(io_wakeupFromWBDelayed_1_valid),
    .io_wakeupFromWBDelayed_1_bits_vecWen(io_wakeupFromWBDelayed_1_bits_vecWen),
    .io_wakeupFromWBDelayed_1_bits_pdest(io_wakeupFromWBDelayed_1_bits_pdest),
    .io_wakeupFromWBDelayed_0_valid(io_wakeupFromWBDelayed_0_valid),
    .io_wakeupFromWBDelayed_0_bits_vecWen(io_wakeupFromWBDelayed_0_bits_vecWen),
    .io_wakeupFromWBDelayed_0_bits_pdest(io_wakeupFromWBDelayed_0_bits_pdest),
    .io_vlFromIntIsZero(io_vlFromIntIsZero),
    .io_vlFromIntIsVlmax(io_vlFromIntIsVlmax),
    .io_vlFromVfIsZero(io_vlFromVfIsZero),
    .io_vlFromVfIsVlmax(io_vlFromVfIsVlmax),
    .io_deqDelay_0_ready(io_deqDelay_0_ready),
    .io_enq_0_ready(i_io_enq_0_ready),
    .io_enq_1_ready(i_io_enq_1_ready),
    .io_deqDelay_0_valid(i_io_deqDelay_0_valid),
    .io_deqDelay_0_bits_rf_4_0_addr(i_io_deqDelay_0_bits_rf_4_0_addr),
    .io_deqDelay_0_bits_rf_4_0_srcType(i_io_deqDelay_0_bits_rf_4_0_srcType),
    .io_deqDelay_0_bits_rf_3_0_addr(i_io_deqDelay_0_bits_rf_3_0_addr),
    .io_deqDelay_0_bits_rf_3_0_srcType(i_io_deqDelay_0_bits_rf_3_0_srcType),
    .io_deqDelay_0_bits_rf_2_0_addr(i_io_deqDelay_0_bits_rf_2_0_addr),
    .io_deqDelay_0_bits_rf_2_0_srcType(i_io_deqDelay_0_bits_rf_2_0_srcType),
    .io_deqDelay_0_bits_rf_1_0_addr(i_io_deqDelay_0_bits_rf_1_0_addr),
    .io_deqDelay_0_bits_rf_1_0_srcType(i_io_deqDelay_0_bits_rf_1_0_srcType),
    .io_deqDelay_0_bits_rf_0_0_addr(i_io_deqDelay_0_bits_rf_0_0_addr),
    .io_deqDelay_0_bits_rf_0_0_srcType(i_io_deqDelay_0_bits_rf_0_0_srcType),
    .io_deqDelay_0_bits_srcType_0(i_io_deqDelay_0_bits_srcType_0),
    .io_deqDelay_0_bits_srcType_1(i_io_deqDelay_0_bits_srcType_1),
    .io_deqDelay_0_bits_srcType_2(i_io_deqDelay_0_bits_srcType_2),
    .io_deqDelay_0_bits_srcType_3(i_io_deqDelay_0_bits_srcType_3),
    .io_deqDelay_0_bits_srcType_4(i_io_deqDelay_0_bits_srcType_4),
    .io_deqDelay_0_bits_immType(i_io_deqDelay_0_bits_immType),
    .io_deqDelay_0_bits_common_fuType(i_io_deqDelay_0_bits_common_fuType),
    .io_deqDelay_0_bits_common_fuOpType(i_io_deqDelay_0_bits_common_fuOpType),
    .io_deqDelay_0_bits_common_src_0(i_io_deqDelay_0_bits_common_src_0),
    .io_deqDelay_0_bits_common_src_1(i_io_deqDelay_0_bits_common_src_1),
    .io_deqDelay_0_bits_common_src_2(i_io_deqDelay_0_bits_common_src_2),
    .io_deqDelay_0_bits_common_src_3(i_io_deqDelay_0_bits_common_src_3),
    .io_deqDelay_0_bits_common_src_4(i_io_deqDelay_0_bits_common_src_4),
    .io_deqDelay_0_bits_common_imm(i_io_deqDelay_0_bits_common_imm),
    .io_deqDelay_0_bits_common_robIdx_flag(i_io_deqDelay_0_bits_common_robIdx_flag),
    .io_deqDelay_0_bits_common_robIdx_value(i_io_deqDelay_0_bits_common_robIdx_value),
    .io_deqDelay_0_bits_common_iqIdx(i_io_deqDelay_0_bits_common_iqIdx),
    .io_deqDelay_0_bits_common_isFirstIssue(i_io_deqDelay_0_bits_common_isFirstIssue),
    .io_deqDelay_0_bits_common_pdest(i_io_deqDelay_0_bits_common_pdest),
    .io_deqDelay_0_bits_common_vecWen(i_io_deqDelay_0_bits_common_vecWen),
    .io_deqDelay_0_bits_common_v0Wen(i_io_deqDelay_0_bits_common_v0Wen),
    .io_deqDelay_0_bits_common_fpu_typeTagOut(i_io_deqDelay_0_bits_common_fpu_typeTagOut),
    .io_deqDelay_0_bits_common_fpu_wflags(i_io_deqDelay_0_bits_common_fpu_wflags),
    .io_deqDelay_0_bits_common_fpu_typ(i_io_deqDelay_0_bits_common_fpu_typ),
    .io_deqDelay_0_bits_common_fpu_fmt(i_io_deqDelay_0_bits_common_fpu_fmt),
    .io_deqDelay_0_bits_common_fpu_rm(i_io_deqDelay_0_bits_common_fpu_rm),
    .io_deqDelay_0_bits_common_vpu_vill(i_io_deqDelay_0_bits_common_vpu_vill),
    .io_deqDelay_0_bits_common_vpu_vma(i_io_deqDelay_0_bits_common_vpu_vma),
    .io_deqDelay_0_bits_common_vpu_vta(i_io_deqDelay_0_bits_common_vpu_vta),
    .io_deqDelay_0_bits_common_vpu_vsew(i_io_deqDelay_0_bits_common_vpu_vsew),
    .io_deqDelay_0_bits_common_vpu_vlmul(i_io_deqDelay_0_bits_common_vpu_vlmul),
    .io_deqDelay_0_bits_common_vpu_specVill(i_io_deqDelay_0_bits_common_vpu_specVill),
    .io_deqDelay_0_bits_common_vpu_specVma(i_io_deqDelay_0_bits_common_vpu_specVma),
    .io_deqDelay_0_bits_common_vpu_specVta(i_io_deqDelay_0_bits_common_vpu_specVta),
    .io_deqDelay_0_bits_common_vpu_specVsew(i_io_deqDelay_0_bits_common_vpu_specVsew),
    .io_deqDelay_0_bits_common_vpu_specVlmul(i_io_deqDelay_0_bits_common_vpu_specVlmul),
    .io_deqDelay_0_bits_common_vpu_vm(i_io_deqDelay_0_bits_common_vpu_vm),
    .io_deqDelay_0_bits_common_vpu_vstart(i_io_deqDelay_0_bits_common_vpu_vstart),
    .io_deqDelay_0_bits_common_vpu_frm(i_io_deqDelay_0_bits_common_vpu_frm),
    .io_deqDelay_0_bits_common_vpu_fpu_isFpToVecInst(i_io_deqDelay_0_bits_common_vpu_fpu_isFpToVecInst),
    .io_deqDelay_0_bits_common_vpu_fpu_isFP32Instr(i_io_deqDelay_0_bits_common_vpu_fpu_isFP32Instr),
    .io_deqDelay_0_bits_common_vpu_fpu_isFP64Instr(i_io_deqDelay_0_bits_common_vpu_fpu_isFP64Instr),
    .io_deqDelay_0_bits_common_vpu_fpu_isReduction(i_io_deqDelay_0_bits_common_vpu_fpu_isReduction),
    .io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_2(i_io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_2),
    .io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_4(i_io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_4),
    .io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_8(i_io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_8),
    .io_deqDelay_0_bits_common_vpu_vxrm(i_io_deqDelay_0_bits_common_vpu_vxrm),
    .io_deqDelay_0_bits_common_vpu_vuopIdx(i_io_deqDelay_0_bits_common_vpu_vuopIdx),
    .io_deqDelay_0_bits_common_vpu_lastUop(i_io_deqDelay_0_bits_common_vpu_lastUop),
    .io_deqDelay_0_bits_common_vpu_vmask(i_io_deqDelay_0_bits_common_vpu_vmask),
    .io_deqDelay_0_bits_common_vpu_vl(i_io_deqDelay_0_bits_common_vpu_vl),
    .io_deqDelay_0_bits_common_vpu_nf(i_io_deqDelay_0_bits_common_vpu_nf),
    .io_deqDelay_0_bits_common_vpu_veew(i_io_deqDelay_0_bits_common_vpu_veew),
    .io_deqDelay_0_bits_common_vpu_isReverse(i_io_deqDelay_0_bits_common_vpu_isReverse),
    .io_deqDelay_0_bits_common_vpu_isExt(i_io_deqDelay_0_bits_common_vpu_isExt),
    .io_deqDelay_0_bits_common_vpu_isNarrow(i_io_deqDelay_0_bits_common_vpu_isNarrow),
    .io_deqDelay_0_bits_common_vpu_isDstMask(i_io_deqDelay_0_bits_common_vpu_isDstMask),
    .io_deqDelay_0_bits_common_vpu_isOpMask(i_io_deqDelay_0_bits_common_vpu_isOpMask),
    .io_deqDelay_0_bits_common_vpu_isMove(i_io_deqDelay_0_bits_common_vpu_isMove),
    .io_deqDelay_0_bits_common_vpu_isDependOldVd(i_io_deqDelay_0_bits_common_vpu_isDependOldVd),
    .io_deqDelay_0_bits_common_vpu_isWritePartVd(i_io_deqDelay_0_bits_common_vpu_isWritePartVd),
    .io_deqDelay_0_bits_common_vpu_isVleff(i_io_deqDelay_0_bits_common_vpu_isVleff),
    .io_deqDelay_0_bits_common_dataSources_0_value(i_io_deqDelay_0_bits_common_dataSources_0_value),
    .io_deqDelay_0_bits_common_dataSources_1_value(i_io_deqDelay_0_bits_common_dataSources_1_value),
    .io_deqDelay_0_bits_common_dataSources_2_value(i_io_deqDelay_0_bits_common_dataSources_2_value),
    .io_deqDelay_0_bits_common_dataSources_3_value(i_io_deqDelay_0_bits_common_dataSources_3_value),
    .io_deqDelay_0_bits_common_dataSources_4_value(i_io_deqDelay_0_bits_common_dataSources_4_value),
    .io_deqDelay_0_bits_common_perfDebugInfo_eliminatedMove(i_io_deqDelay_0_bits_common_perfDebugInfo_eliminatedMove),
    .io_deqDelay_0_bits_common_perfDebugInfo_renameTime(i_io_deqDelay_0_bits_common_perfDebugInfo_renameTime),
    .io_deqDelay_0_bits_common_perfDebugInfo_dispatchTime(i_io_deqDelay_0_bits_common_perfDebugInfo_dispatchTime),
    .io_deqDelay_0_bits_common_perfDebugInfo_enqRsTime(i_io_deqDelay_0_bits_common_perfDebugInfo_enqRsTime),
    .io_deqDelay_0_bits_common_perfDebugInfo_selectTime(i_io_deqDelay_0_bits_common_perfDebugInfo_selectTime),
    .io_deqDelay_0_bits_common_perfDebugInfo_issueTime(i_io_deqDelay_0_bits_common_perfDebugInfo_issueTime),
    .io_deqDelay_0_bits_common_perfDebugInfo_writebackTime(i_io_deqDelay_0_bits_common_perfDebugInfo_writebackTime),
    .io_deqDelay_0_bits_common_perfDebugInfo_runahead_checkpoint_id(i_io_deqDelay_0_bits_common_perfDebugInfo_runahead_checkpoint_id),
    .io_deqDelay_0_bits_common_perfDebugInfo_tlbFirstReqTime(i_io_deqDelay_0_bits_common_perfDebugInfo_tlbFirstReqTime),
    .io_deqDelay_0_bits_common_perfDebugInfo_tlbRespTime(i_io_deqDelay_0_bits_common_perfDebugInfo_tlbRespTime),
    .io_deqDelay_0_bits_common_debug_seqNum_seqNum(i_io_deqDelay_0_bits_common_debug_seqNum_seqNum),
    .io_deqDelay_0_bits_common_debug_seqNum_uopIdx(i_io_deqDelay_0_bits_common_debug_seqNum_uopIdx),
    .io_deqDelay_0_bits_addrOH(i_io_deqDelay_0_bits_addrOH)
  );

  function automatic logic pct(int p); return $urandom_range(0, 99) < p; endfunction
  // 物理寄存器号小池：85% 取 0..7（唤醒才打得中），15% 取 0x80..0x83（最高位为 1：检验 psrc==0 按端口全宽判）
  function automatic logic [7:0] pick_preg();
    return pct(85) ? 8'($urandom_range(0, 7)) : 8'($urandom_range(128, 131));
  endfunction
  function automatic logic [3:0] pick_src_type();
    int r = $urandom_range(0, 9);
    case (r) 0: return 4'h0; 1, 2, 3: return 4'h1; 4: return 4'h2; 5: return 4'h4;
      6: return 4'h8; default: return 4'($urandom); endcase
  endfunction
  function automatic logic [34:0] enq_fu_type();
    int keep [2] = '{22, 26};
    if (pct(90)) return 35'h1 << keep[$urandom_range(0, 1)];
    return {3'($urandom), $urandom};
  endfunction

  // ---- 激励：下降沿给 ----
  always @(negedge clock) begin
    if (pct(25)) rob_cursor = rob_cursor + 1;
    io_flush_valid = pct(2);
    io_flush_bits_robIdx_flag = 1'($urandom);
    io_flush_bits_robIdx_value = 8'(rob_cursor + $urandom_range(0, 12));
    io_flush_bits_level = 1'($urandom);
    io_enq_0_valid = pct(60);
    io_enq_0_bits_instr = 32'($urandom);
    io_enq_0_bits_pc = {$urandom, $urandom};
    io_enq_0_bits_foldpc = 10'($urandom);
    io_enq_0_bits_exceptionVec_0 = 1'($urandom);
    io_enq_0_bits_exceptionVec_1 = 1'($urandom);
    io_enq_0_bits_exceptionVec_2 = 1'($urandom);
    io_enq_0_bits_exceptionVec_3 = 1'($urandom);
    io_enq_0_bits_exceptionVec_4 = 1'($urandom);
    io_enq_0_bits_exceptionVec_5 = 1'($urandom);
    io_enq_0_bits_exceptionVec_6 = 1'($urandom);
    io_enq_0_bits_exceptionVec_7 = 1'($urandom);
    io_enq_0_bits_exceptionVec_8 = 1'($urandom);
    io_enq_0_bits_exceptionVec_9 = 1'($urandom);
    io_enq_0_bits_exceptionVec_10 = 1'($urandom);
    io_enq_0_bits_exceptionVec_11 = 1'($urandom);
    io_enq_0_bits_exceptionVec_12 = 1'($urandom);
    io_enq_0_bits_exceptionVec_13 = 1'($urandom);
    io_enq_0_bits_exceptionVec_14 = 1'($urandom);
    io_enq_0_bits_exceptionVec_15 = 1'($urandom);
    io_enq_0_bits_exceptionVec_16 = 1'($urandom);
    io_enq_0_bits_exceptionVec_17 = 1'($urandom);
    io_enq_0_bits_exceptionVec_18 = 1'($urandom);
    io_enq_0_bits_exceptionVec_19 = 1'($urandom);
    io_enq_0_bits_exceptionVec_20 = 1'($urandom);
    io_enq_0_bits_exceptionVec_21 = 1'($urandom);
    io_enq_0_bits_exceptionVec_22 = 1'($urandom);
    io_enq_0_bits_exceptionVec_23 = 1'($urandom);
    io_enq_0_bits_isFetchMalAddr = 1'($urandom);
    io_enq_0_bits_hasException = 1'($urandom);
    io_enq_0_bits_trigger = 4'($urandom);
    io_enq_0_bits_preDecodeInfo_valid = 1'($urandom);
    io_enq_0_bits_preDecodeInfo_isRVC = 1'($urandom);
    io_enq_0_bits_preDecodeInfo_brType = 2'($urandom);
    io_enq_0_bits_preDecodeInfo_isCall = 1'($urandom);
    io_enq_0_bits_preDecodeInfo_isRet = 1'($urandom);
    io_enq_0_bits_pred_taken = 1'($urandom);
    io_enq_0_bits_crossPageIPFFix = 1'($urandom);
    io_enq_0_bits_ftqPtr_flag = 1'($urandom);
    io_enq_0_bits_ftqPtr_value = 6'($urandom);
    io_enq_0_bits_ftqOffset = 4'($urandom);
    io_enq_0_bits_satpFlushFirstFetchFault = 1'($urandom);
    io_enq_0_bits_srcType_0 = pick_src_type();
    io_enq_0_bits_srcType_1 = pick_src_type();
    io_enq_0_bits_srcType_2 = pick_src_type();
    io_enq_0_bits_srcType_3 = pick_src_type();
    io_enq_0_bits_srcType_4 = pick_src_type();
    io_enq_0_bits_ldest = 6'($urandom);
    io_enq_0_bits_fuType = enq_fu_type();
    io_enq_0_bits_fuOpType = 9'($urandom);
    io_enq_0_bits_rfWen = 1'($urandom);
    io_enq_0_bits_fpWen = 1'($urandom);
    io_enq_0_bits_vecWen = 1'($urandom);
    io_enq_0_bits_v0Wen = 1'($urandom);
    io_enq_0_bits_vlWen = 1'($urandom);
    io_enq_0_bits_isXSTrap = 1'($urandom);
    io_enq_0_bits_waitForward = 1'($urandom);
    io_enq_0_bits_blockBackward = 1'($urandom);
    io_enq_0_bits_flushPipe = 1'($urandom);
    io_enq_0_bits_canRobCompress = 1'($urandom);
    io_enq_0_bits_selImm = 4'($urandom);
    io_enq_0_bits_imm = 32'($urandom);
    io_enq_0_bits_fpu_typeTagOut = 2'($urandom);
    io_enq_0_bits_fpu_wflags = 1'($urandom);
    io_enq_0_bits_fpu_typ = 2'($urandom);
    io_enq_0_bits_fpu_fmt = 2'($urandom);
    io_enq_0_bits_fpu_rm = 3'($urandom);
    io_enq_0_bits_vpu_vill = 1'($urandom);
    io_enq_0_bits_vpu_vma = 1'($urandom);
    io_enq_0_bits_vpu_vta = 1'($urandom);
    io_enq_0_bits_vpu_vsew = 2'($urandom);
    io_enq_0_bits_vpu_vlmul = 3'($urandom);
    io_enq_0_bits_vpu_specVill = 1'($urandom);
    io_enq_0_bits_vpu_specVma = 1'($urandom);
    io_enq_0_bits_vpu_specVta = 1'($urandom);
    io_enq_0_bits_vpu_specVsew = 2'($urandom);
    io_enq_0_bits_vpu_specVlmul = 3'($urandom);
    io_enq_0_bits_vpu_vm = 1'($urandom);
    io_enq_0_bits_vpu_vstart = 8'($urandom);
    io_enq_0_bits_vpu_frm = 3'($urandom);
    io_enq_0_bits_vpu_fpu_isFpToVecInst = 1'($urandom);
    io_enq_0_bits_vpu_fpu_isFP32Instr = 1'($urandom);
    io_enq_0_bits_vpu_fpu_isFP64Instr = 1'($urandom);
    io_enq_0_bits_vpu_fpu_isReduction = 1'($urandom);
    io_enq_0_bits_vpu_fpu_isFoldTo1_2 = 1'($urandom);
    io_enq_0_bits_vpu_fpu_isFoldTo1_4 = 1'($urandom);
    io_enq_0_bits_vpu_fpu_isFoldTo1_8 = 1'($urandom);
    io_enq_0_bits_vpu_vxrm = 2'($urandom);
    io_enq_0_bits_vpu_vuopIdx = 7'($urandom);
    io_enq_0_bits_vpu_lastUop = 1'($urandom);
    io_enq_0_bits_vpu_vmask = {$urandom, $urandom, $urandom, $urandom};
    io_enq_0_bits_vpu_vl = 8'($urandom);
    io_enq_0_bits_vpu_nf = 3'($urandom);
    io_enq_0_bits_vpu_veew = 2'($urandom);
    io_enq_0_bits_vpu_isReverse = 1'($urandom);
    io_enq_0_bits_vpu_isExt = 1'($urandom);
    io_enq_0_bits_vpu_isNarrow = 1'($urandom);
    io_enq_0_bits_vpu_isDstMask = 1'($urandom);
    io_enq_0_bits_vpu_isOpMask = 1'($urandom);
    io_enq_0_bits_vpu_isMove = 1'($urandom);
    io_enq_0_bits_vpu_isDependOldVd = 1'($urandom);
    io_enq_0_bits_vpu_isWritePartVd = 1'($urandom);
    io_enq_0_bits_vpu_isVleff = 1'($urandom);
    io_enq_0_bits_vlsInstr = 1'($urandom);
    io_enq_0_bits_wfflags = 1'($urandom);
    io_enq_0_bits_isMove = 1'($urandom);
    io_enq_0_bits_isDropAmocasSta = 1'($urandom);
    io_enq_0_bits_uopIdx = 7'($urandom);
    io_enq_0_bits_isVset = 1'($urandom);
    io_enq_0_bits_firstUop = 1'($urandom);
    io_enq_0_bits_lastUop = 1'($urandom);
    io_enq_0_bits_numUops = 7'($urandom);
    io_enq_0_bits_numWB = 7'($urandom);
    io_enq_0_bits_commitType = 3'($urandom);
    io_enq_0_bits_srcState_0 = pct(80);
    io_enq_0_bits_srcState_1 = pct(80);
    io_enq_0_bits_srcState_2 = pct(80);
    io_enq_0_bits_srcState_3 = pct(80);
    io_enq_0_bits_srcState_4 = pct(80);
    io_enq_0_bits_psrc_0 = 8'(pick_preg());
    io_enq_0_bits_psrc_1 = 8'(pick_preg());
    io_enq_0_bits_psrc_2 = 8'(pick_preg());
    io_enq_0_bits_psrc_3 = 8'(pick_preg());
    io_enq_0_bits_psrc_4 = 8'(pick_preg());
    io_enq_0_bits_pdest = 8'(pick_preg());
    io_enq_0_bits_useRegCache_0 = 1'($urandom);
    io_enq_0_bits_useRegCache_1 = 1'($urandom);
    io_enq_0_bits_regCacheIdx_0 = 5'($urandom);
    io_enq_0_bits_regCacheIdx_1 = 5'($urandom);
    io_enq_0_bits_robIdx_flag = 1'($urandom);
    io_enq_0_bits_robIdx_value = 8'(rob_cursor + $urandom_range(0, 12));
    io_enq_0_bits_instrSize = 3'($urandom);
    io_enq_0_bits_dirtyFs = 1'($urandom);
    io_enq_0_bits_dirtyVs = 1'($urandom);
    io_enq_0_bits_traceBlockInPipe_itype = 4'($urandom);
    io_enq_0_bits_traceBlockInPipe_iretire = 4'($urandom);
    io_enq_0_bits_traceBlockInPipe_ilastsize = 1'($urandom);
    io_enq_0_bits_eliminatedMove = 1'($urandom);
    io_enq_0_bits_snapshot = 1'($urandom);
    io_enq_0_bits_debugInfo_eliminatedMove = 1'($urandom);
    io_enq_0_bits_debugInfo_renameTime = {$urandom, $urandom};
    io_enq_0_bits_debugInfo_dispatchTime = {$urandom, $urandom};
    io_enq_0_bits_debugInfo_enqRsTime = {$urandom, $urandom};
    io_enq_0_bits_debugInfo_selectTime = {$urandom, $urandom};
    io_enq_0_bits_debugInfo_issueTime = {$urandom, $urandom};
    io_enq_0_bits_debugInfo_writebackTime = {$urandom, $urandom};
    io_enq_0_bits_debugInfo_runahead_checkpoint_id = {$urandom, $urandom};
    io_enq_0_bits_debugInfo_tlbFirstReqTime = {$urandom, $urandom};
    io_enq_0_bits_debugInfo_tlbRespTime = {$urandom, $urandom};
    io_enq_0_bits_debug_seqNum_seqNum = {$urandom, $urandom};
    io_enq_0_bits_debug_seqNum_uopIdx = 8'($urandom);
    io_enq_0_bits_storeSetHit = 1'($urandom);
    io_enq_0_bits_waitForRobIdx_flag = 1'($urandom);
    io_enq_0_bits_waitForRobIdx_value = 8'($urandom);
    io_enq_0_bits_loadWaitBit = 1'($urandom);
    io_enq_0_bits_loadWaitStrict = 1'($urandom);
    io_enq_0_bits_ssid = 5'($urandom);
    io_enq_0_bits_lqIdx_flag = 1'($urandom);
    io_enq_0_bits_lqIdx_value = 7'($urandom);
    io_enq_0_bits_sqIdx_flag = 1'($urandom);
    io_enq_0_bits_sqIdx_value = 6'($urandom);
    io_enq_0_bits_singleStep = 1'($urandom);
    io_enq_0_bits_replayInst = 1'($urandom);
    io_enq_0_bits_debug_fuType = {$urandom, $urandom};
    io_enq_0_bits_debug_sim_trig = 1'($urandom);
    io_enq_0_bits_numLsElem = 5'($urandom);
    io_enq_1_valid = pct(60);
    io_enq_1_bits_instr = 32'($urandom);
    io_enq_1_bits_pc = {$urandom, $urandom};
    io_enq_1_bits_foldpc = 10'($urandom);
    io_enq_1_bits_exceptionVec_0 = 1'($urandom);
    io_enq_1_bits_exceptionVec_1 = 1'($urandom);
    io_enq_1_bits_exceptionVec_2 = 1'($urandom);
    io_enq_1_bits_exceptionVec_3 = 1'($urandom);
    io_enq_1_bits_exceptionVec_4 = 1'($urandom);
    io_enq_1_bits_exceptionVec_5 = 1'($urandom);
    io_enq_1_bits_exceptionVec_6 = 1'($urandom);
    io_enq_1_bits_exceptionVec_7 = 1'($urandom);
    io_enq_1_bits_exceptionVec_8 = 1'($urandom);
    io_enq_1_bits_exceptionVec_9 = 1'($urandom);
    io_enq_1_bits_exceptionVec_10 = 1'($urandom);
    io_enq_1_bits_exceptionVec_11 = 1'($urandom);
    io_enq_1_bits_exceptionVec_12 = 1'($urandom);
    io_enq_1_bits_exceptionVec_13 = 1'($urandom);
    io_enq_1_bits_exceptionVec_14 = 1'($urandom);
    io_enq_1_bits_exceptionVec_15 = 1'($urandom);
    io_enq_1_bits_exceptionVec_16 = 1'($urandom);
    io_enq_1_bits_exceptionVec_17 = 1'($urandom);
    io_enq_1_bits_exceptionVec_18 = 1'($urandom);
    io_enq_1_bits_exceptionVec_19 = 1'($urandom);
    io_enq_1_bits_exceptionVec_20 = 1'($urandom);
    io_enq_1_bits_exceptionVec_21 = 1'($urandom);
    io_enq_1_bits_exceptionVec_22 = 1'($urandom);
    io_enq_1_bits_exceptionVec_23 = 1'($urandom);
    io_enq_1_bits_isFetchMalAddr = 1'($urandom);
    io_enq_1_bits_hasException = 1'($urandom);
    io_enq_1_bits_trigger = 4'($urandom);
    io_enq_1_bits_preDecodeInfo_valid = 1'($urandom);
    io_enq_1_bits_preDecodeInfo_isRVC = 1'($urandom);
    io_enq_1_bits_preDecodeInfo_brType = 2'($urandom);
    io_enq_1_bits_preDecodeInfo_isCall = 1'($urandom);
    io_enq_1_bits_preDecodeInfo_isRet = 1'($urandom);
    io_enq_1_bits_pred_taken = 1'($urandom);
    io_enq_1_bits_crossPageIPFFix = 1'($urandom);
    io_enq_1_bits_ftqPtr_flag = 1'($urandom);
    io_enq_1_bits_ftqPtr_value = 6'($urandom);
    io_enq_1_bits_ftqOffset = 4'($urandom);
    io_enq_1_bits_satpFlushFirstFetchFault = 1'($urandom);
    io_enq_1_bits_srcType_0 = pick_src_type();
    io_enq_1_bits_srcType_1 = pick_src_type();
    io_enq_1_bits_srcType_2 = pick_src_type();
    io_enq_1_bits_srcType_3 = pick_src_type();
    io_enq_1_bits_srcType_4 = pick_src_type();
    io_enq_1_bits_ldest = 6'($urandom);
    io_enq_1_bits_fuType = enq_fu_type();
    io_enq_1_bits_fuOpType = 9'($urandom);
    io_enq_1_bits_rfWen = 1'($urandom);
    io_enq_1_bits_fpWen = 1'($urandom);
    io_enq_1_bits_vecWen = 1'($urandom);
    io_enq_1_bits_v0Wen = 1'($urandom);
    io_enq_1_bits_vlWen = 1'($urandom);
    io_enq_1_bits_isXSTrap = 1'($urandom);
    io_enq_1_bits_waitForward = 1'($urandom);
    io_enq_1_bits_blockBackward = 1'($urandom);
    io_enq_1_bits_flushPipe = 1'($urandom);
    io_enq_1_bits_canRobCompress = 1'($urandom);
    io_enq_1_bits_selImm = 4'($urandom);
    io_enq_1_bits_imm = 32'($urandom);
    io_enq_1_bits_fpu_typeTagOut = 2'($urandom);
    io_enq_1_bits_fpu_wflags = 1'($urandom);
    io_enq_1_bits_fpu_typ = 2'($urandom);
    io_enq_1_bits_fpu_fmt = 2'($urandom);
    io_enq_1_bits_fpu_rm = 3'($urandom);
    io_enq_1_bits_vpu_vill = 1'($urandom);
    io_enq_1_bits_vpu_vma = 1'($urandom);
    io_enq_1_bits_vpu_vta = 1'($urandom);
    io_enq_1_bits_vpu_vsew = 2'($urandom);
    io_enq_1_bits_vpu_vlmul = 3'($urandom);
    io_enq_1_bits_vpu_specVill = 1'($urandom);
    io_enq_1_bits_vpu_specVma = 1'($urandom);
    io_enq_1_bits_vpu_specVta = 1'($urandom);
    io_enq_1_bits_vpu_specVsew = 2'($urandom);
    io_enq_1_bits_vpu_specVlmul = 3'($urandom);
    io_enq_1_bits_vpu_vm = 1'($urandom);
    io_enq_1_bits_vpu_vstart = 8'($urandom);
    io_enq_1_bits_vpu_frm = 3'($urandom);
    io_enq_1_bits_vpu_fpu_isFpToVecInst = 1'($urandom);
    io_enq_1_bits_vpu_fpu_isFP32Instr = 1'($urandom);
    io_enq_1_bits_vpu_fpu_isFP64Instr = 1'($urandom);
    io_enq_1_bits_vpu_fpu_isReduction = 1'($urandom);
    io_enq_1_bits_vpu_fpu_isFoldTo1_2 = 1'($urandom);
    io_enq_1_bits_vpu_fpu_isFoldTo1_4 = 1'($urandom);
    io_enq_1_bits_vpu_fpu_isFoldTo1_8 = 1'($urandom);
    io_enq_1_bits_vpu_vxrm = 2'($urandom);
    io_enq_1_bits_vpu_vuopIdx = 7'($urandom);
    io_enq_1_bits_vpu_lastUop = 1'($urandom);
    io_enq_1_bits_vpu_vmask = {$urandom, $urandom, $urandom, $urandom};
    io_enq_1_bits_vpu_vl = 8'($urandom);
    io_enq_1_bits_vpu_nf = 3'($urandom);
    io_enq_1_bits_vpu_veew = 2'($urandom);
    io_enq_1_bits_vpu_isReverse = 1'($urandom);
    io_enq_1_bits_vpu_isExt = 1'($urandom);
    io_enq_1_bits_vpu_isNarrow = 1'($urandom);
    io_enq_1_bits_vpu_isDstMask = 1'($urandom);
    io_enq_1_bits_vpu_isOpMask = 1'($urandom);
    io_enq_1_bits_vpu_isMove = 1'($urandom);
    io_enq_1_bits_vpu_isDependOldVd = 1'($urandom);
    io_enq_1_bits_vpu_isWritePartVd = 1'($urandom);
    io_enq_1_bits_vpu_isVleff = 1'($urandom);
    io_enq_1_bits_vlsInstr = 1'($urandom);
    io_enq_1_bits_wfflags = 1'($urandom);
    io_enq_1_bits_isMove = 1'($urandom);
    io_enq_1_bits_isDropAmocasSta = 1'($urandom);
    io_enq_1_bits_uopIdx = 7'($urandom);
    io_enq_1_bits_isVset = 1'($urandom);
    io_enq_1_bits_firstUop = 1'($urandom);
    io_enq_1_bits_lastUop = 1'($urandom);
    io_enq_1_bits_numUops = 7'($urandom);
    io_enq_1_bits_numWB = 7'($urandom);
    io_enq_1_bits_commitType = 3'($urandom);
    io_enq_1_bits_srcState_0 = pct(80);
    io_enq_1_bits_srcState_1 = pct(80);
    io_enq_1_bits_srcState_2 = pct(80);
    io_enq_1_bits_srcState_3 = pct(80);
    io_enq_1_bits_srcState_4 = pct(80);
    io_enq_1_bits_psrc_0 = 8'(pick_preg());
    io_enq_1_bits_psrc_1 = 8'(pick_preg());
    io_enq_1_bits_psrc_2 = 8'(pick_preg());
    io_enq_1_bits_psrc_3 = 8'(pick_preg());
    io_enq_1_bits_psrc_4 = 8'(pick_preg());
    io_enq_1_bits_pdest = 8'(pick_preg());
    io_enq_1_bits_useRegCache_0 = 1'($urandom);
    io_enq_1_bits_useRegCache_1 = 1'($urandom);
    io_enq_1_bits_regCacheIdx_0 = 5'($urandom);
    io_enq_1_bits_regCacheIdx_1 = 5'($urandom);
    io_enq_1_bits_robIdx_flag = 1'($urandom);
    io_enq_1_bits_robIdx_value = 8'(rob_cursor + $urandom_range(0, 12));
    io_enq_1_bits_instrSize = 3'($urandom);
    io_enq_1_bits_dirtyFs = 1'($urandom);
    io_enq_1_bits_dirtyVs = 1'($urandom);
    io_enq_1_bits_traceBlockInPipe_itype = 4'($urandom);
    io_enq_1_bits_traceBlockInPipe_iretire = 4'($urandom);
    io_enq_1_bits_traceBlockInPipe_ilastsize = 1'($urandom);
    io_enq_1_bits_eliminatedMove = 1'($urandom);
    io_enq_1_bits_snapshot = 1'($urandom);
    io_enq_1_bits_debugInfo_eliminatedMove = 1'($urandom);
    io_enq_1_bits_debugInfo_renameTime = {$urandom, $urandom};
    io_enq_1_bits_debugInfo_dispatchTime = {$urandom, $urandom};
    io_enq_1_bits_debugInfo_enqRsTime = {$urandom, $urandom};
    io_enq_1_bits_debugInfo_selectTime = {$urandom, $urandom};
    io_enq_1_bits_debugInfo_issueTime = {$urandom, $urandom};
    io_enq_1_bits_debugInfo_writebackTime = {$urandom, $urandom};
    io_enq_1_bits_debugInfo_runahead_checkpoint_id = {$urandom, $urandom};
    io_enq_1_bits_debugInfo_tlbFirstReqTime = {$urandom, $urandom};
    io_enq_1_bits_debugInfo_tlbRespTime = {$urandom, $urandom};
    io_enq_1_bits_debug_seqNum_seqNum = {$urandom, $urandom};
    io_enq_1_bits_debug_seqNum_uopIdx = 8'($urandom);
    io_enq_1_bits_storeSetHit = 1'($urandom);
    io_enq_1_bits_waitForRobIdx_flag = 1'($urandom);
    io_enq_1_bits_waitForRobIdx_value = 8'($urandom);
    io_enq_1_bits_loadWaitBit = 1'($urandom);
    io_enq_1_bits_loadWaitStrict = 1'($urandom);
    io_enq_1_bits_ssid = 5'($urandom);
    io_enq_1_bits_lqIdx_flag = 1'($urandom);
    io_enq_1_bits_lqIdx_value = 7'($urandom);
    io_enq_1_bits_sqIdx_flag = 1'($urandom);
    io_enq_1_bits_sqIdx_value = 6'($urandom);
    io_enq_1_bits_singleStep = 1'($urandom);
    io_enq_1_bits_replayInst = 1'($urandom);
    io_enq_1_bits_debug_fuType = {$urandom, $urandom};
    io_enq_1_bits_debug_sim_trig = 1'($urandom);
    io_enq_1_bits_numLsElem = 5'($urandom);
    io_og0Resp_0_valid = pct(40);
    io_og1Resp_0_valid = pct(40);
    io_og2Resp_0_valid = pct(40);
    io_og2Resp_0_bits_resp = 2'($urandom);
    io_wakeupFromWB_15_valid = pct(35);
    io_wakeupFromWB_15_bits_vlWen = 1'($urandom);
    io_wakeupFromWB_15_bits_pdest = 8'(pick_preg());
    io_wakeupFromWB_14_valid = pct(35);
    io_wakeupFromWB_14_bits_vlWen = 1'($urandom);
    io_wakeupFromWB_14_bits_pdest = 8'(pick_preg());
    io_wakeupFromWB_13_valid = pct(35);
    io_wakeupFromWB_13_bits_vlWen = 1'($urandom);
    io_wakeupFromWB_13_bits_pdest = 8'(pick_preg());
    io_wakeupFromWB_12_valid = pct(35);
    io_wakeupFromWB_12_bits_vlWen = 1'($urandom);
    io_wakeupFromWB_12_bits_pdest = 8'(pick_preg());
    io_wakeupFromWB_11_valid = pct(35);
    io_wakeupFromWB_11_bits_v0Wen = 1'($urandom);
    io_wakeupFromWB_11_bits_pdest = 8'(pick_preg());
    io_wakeupFromWB_10_valid = pct(35);
    io_wakeupFromWB_10_bits_v0Wen = 1'($urandom);
    io_wakeupFromWB_10_bits_pdest = 8'(pick_preg());
    io_wakeupFromWB_9_valid = pct(35);
    io_wakeupFromWB_9_bits_v0Wen = 1'($urandom);
    io_wakeupFromWB_9_bits_pdest = 8'(pick_preg());
    io_wakeupFromWB_8_valid = pct(35);
    io_wakeupFromWB_8_bits_v0Wen = 1'($urandom);
    io_wakeupFromWB_8_bits_pdest = 8'(pick_preg());
    io_wakeupFromWB_7_valid = pct(35);
    io_wakeupFromWB_7_bits_v0Wen = 1'($urandom);
    io_wakeupFromWB_7_bits_pdest = 8'(pick_preg());
    io_wakeupFromWB_6_valid = pct(35);
    io_wakeupFromWB_6_bits_v0Wen = 1'($urandom);
    io_wakeupFromWB_6_bits_pdest = 8'(pick_preg());
    io_wakeupFromWB_5_valid = pct(35);
    io_wakeupFromWB_5_bits_vecWen = 1'($urandom);
    io_wakeupFromWB_5_bits_pdest = 8'(pick_preg());
    io_wakeupFromWB_4_valid = pct(35);
    io_wakeupFromWB_4_bits_vecWen = 1'($urandom);
    io_wakeupFromWB_4_bits_pdest = 8'(pick_preg());
    io_wakeupFromWB_3_valid = pct(35);
    io_wakeupFromWB_3_bits_vecWen = 1'($urandom);
    io_wakeupFromWB_3_bits_pdest = 8'(pick_preg());
    io_wakeupFromWB_2_valid = pct(35);
    io_wakeupFromWB_2_bits_vecWen = 1'($urandom);
    io_wakeupFromWB_2_bits_pdest = 8'(pick_preg());
    io_wakeupFromWB_1_valid = pct(35);
    io_wakeupFromWB_1_bits_vecWen = 1'($urandom);
    io_wakeupFromWB_1_bits_pdest = 8'(pick_preg());
    io_wakeupFromWB_0_valid = pct(35);
    io_wakeupFromWB_0_bits_vecWen = 1'($urandom);
    io_wakeupFromWB_0_bits_pdest = 8'(pick_preg());
    io_wakeupFromWBDelayed_15_valid = pct(35);
    io_wakeupFromWBDelayed_15_bits_vlWen = 1'($urandom);
    io_wakeupFromWBDelayed_15_bits_pdest = 8'(pick_preg());
    io_wakeupFromWBDelayed_14_valid = pct(35);
    io_wakeupFromWBDelayed_14_bits_vlWen = 1'($urandom);
    io_wakeupFromWBDelayed_14_bits_pdest = 8'(pick_preg());
    io_wakeupFromWBDelayed_13_valid = pct(35);
    io_wakeupFromWBDelayed_13_bits_vlWen = 1'($urandom);
    io_wakeupFromWBDelayed_13_bits_pdest = 8'(pick_preg());
    io_wakeupFromWBDelayed_12_valid = pct(35);
    io_wakeupFromWBDelayed_12_bits_vlWen = 1'($urandom);
    io_wakeupFromWBDelayed_12_bits_pdest = 8'(pick_preg());
    io_wakeupFromWBDelayed_11_valid = pct(35);
    io_wakeupFromWBDelayed_11_bits_v0Wen = 1'($urandom);
    io_wakeupFromWBDelayed_11_bits_pdest = 8'(pick_preg());
    io_wakeupFromWBDelayed_10_valid = pct(35);
    io_wakeupFromWBDelayed_10_bits_v0Wen = 1'($urandom);
    io_wakeupFromWBDelayed_10_bits_pdest = 8'(pick_preg());
    io_wakeupFromWBDelayed_9_valid = pct(35);
    io_wakeupFromWBDelayed_9_bits_v0Wen = 1'($urandom);
    io_wakeupFromWBDelayed_9_bits_pdest = 8'(pick_preg());
    io_wakeupFromWBDelayed_8_valid = pct(35);
    io_wakeupFromWBDelayed_8_bits_v0Wen = 1'($urandom);
    io_wakeupFromWBDelayed_8_bits_pdest = 8'(pick_preg());
    io_wakeupFromWBDelayed_7_valid = pct(35);
    io_wakeupFromWBDelayed_7_bits_v0Wen = 1'($urandom);
    io_wakeupFromWBDelayed_7_bits_pdest = 8'(pick_preg());
    io_wakeupFromWBDelayed_6_valid = pct(35);
    io_wakeupFromWBDelayed_6_bits_v0Wen = 1'($urandom);
    io_wakeupFromWBDelayed_6_bits_pdest = 8'(pick_preg());
    io_wakeupFromWBDelayed_5_valid = pct(35);
    io_wakeupFromWBDelayed_5_bits_vecWen = 1'($urandom);
    io_wakeupFromWBDelayed_5_bits_pdest = 8'(pick_preg());
    io_wakeupFromWBDelayed_4_valid = pct(35);
    io_wakeupFromWBDelayed_4_bits_vecWen = 1'($urandom);
    io_wakeupFromWBDelayed_4_bits_pdest = 8'(pick_preg());
    io_wakeupFromWBDelayed_3_valid = pct(35);
    io_wakeupFromWBDelayed_3_bits_vecWen = 1'($urandom);
    io_wakeupFromWBDelayed_3_bits_pdest = 8'(pick_preg());
    io_wakeupFromWBDelayed_2_valid = pct(35);
    io_wakeupFromWBDelayed_2_bits_vecWen = 1'($urandom);
    io_wakeupFromWBDelayed_2_bits_pdest = 8'(pick_preg());
    io_wakeupFromWBDelayed_1_valid = pct(35);
    io_wakeupFromWBDelayed_1_bits_vecWen = 1'($urandom);
    io_wakeupFromWBDelayed_1_bits_pdest = 8'(pick_preg());
    io_wakeupFromWBDelayed_0_valid = pct(35);
    io_wakeupFromWBDelayed_0_bits_vecWen = 1'($urandom);
    io_wakeupFromWBDelayed_0_bits_pdest = 8'(pick_preg());
    io_vlFromIntIsZero = 1'($urandom);
    io_vlFromIntIsVlmax = 1'($urandom);
    io_vlFromVfIsZero = 1'($urandom);
    io_vlFromVfIsVlmax = 1'($urandom);
    io_deqDelay_0_ready = pct(85);
  end

  bit [9:0] ever_valid = 0;
  bit warm = 0;
  task automatic chk(string nm, logic [1023:0] g, logic [1023:0] i, bit gate);
    if (!gate) return;
    checks++;
    if (g !== i) begin
      errors++;
      if (errors <= 40) $display("[ERR] t=%0t %s golden=%h impl=%h", $time, nm, g, i);
    end
  endtask
  longint cov_enq_fire = 0;
  longint cov_flush = 0;
  longint cov_sel_comp = 0;
  longint cov_sel_simp = 0;
  longint cov_sel_enq = 0;
  longint cov_dly_not_ready = 0;
  longint cov_deq0 = 0;
  always @(posedge clock) begin
    #4;
    if (!reset) begin
      ever_valid |= u_g._entries_io_valid;
      if (&ever_valid) warm = 1;
      chk("io_enq_0_ready", g_io_enq_0_ready, i_io_enq_0_ready, cmp_all || warm);
      chk("io_enq_1_ready", g_io_enq_1_ready, i_io_enq_1_ready, cmp_all || warm);
      chk("io_deqDelay_0_valid", g_io_deqDelay_0_valid, i_io_deqDelay_0_valid, cmp_all || warm);
      chk("io_deqDelay_0_bits_rf_4_0_addr", g_io_deqDelay_0_bits_rf_4_0_addr, i_io_deqDelay_0_bits_rf_4_0_addr, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_rf_4_0_srcType", g_io_deqDelay_0_bits_rf_4_0_srcType, i_io_deqDelay_0_bits_rf_4_0_srcType, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_rf_3_0_addr", g_io_deqDelay_0_bits_rf_3_0_addr, i_io_deqDelay_0_bits_rf_3_0_addr, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_rf_3_0_srcType", g_io_deqDelay_0_bits_rf_3_0_srcType, i_io_deqDelay_0_bits_rf_3_0_srcType, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_rf_2_0_addr", g_io_deqDelay_0_bits_rf_2_0_addr, i_io_deqDelay_0_bits_rf_2_0_addr, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_rf_2_0_srcType", g_io_deqDelay_0_bits_rf_2_0_srcType, i_io_deqDelay_0_bits_rf_2_0_srcType, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_rf_1_0_addr", g_io_deqDelay_0_bits_rf_1_0_addr, i_io_deqDelay_0_bits_rf_1_0_addr, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_rf_1_0_srcType", g_io_deqDelay_0_bits_rf_1_0_srcType, i_io_deqDelay_0_bits_rf_1_0_srcType, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_rf_0_0_addr", g_io_deqDelay_0_bits_rf_0_0_addr, i_io_deqDelay_0_bits_rf_0_0_addr, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_rf_0_0_srcType", g_io_deqDelay_0_bits_rf_0_0_srcType, i_io_deqDelay_0_bits_rf_0_0_srcType, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_srcType_0", g_io_deqDelay_0_bits_srcType_0, i_io_deqDelay_0_bits_srcType_0, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_srcType_1", g_io_deqDelay_0_bits_srcType_1, i_io_deqDelay_0_bits_srcType_1, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_srcType_2", g_io_deqDelay_0_bits_srcType_2, i_io_deqDelay_0_bits_srcType_2, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_srcType_3", g_io_deqDelay_0_bits_srcType_3, i_io_deqDelay_0_bits_srcType_3, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_srcType_4", g_io_deqDelay_0_bits_srcType_4, i_io_deqDelay_0_bits_srcType_4, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_immType", g_io_deqDelay_0_bits_immType, i_io_deqDelay_0_bits_immType, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_fuType", g_io_deqDelay_0_bits_common_fuType, i_io_deqDelay_0_bits_common_fuType, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_fuOpType", g_io_deqDelay_0_bits_common_fuOpType, i_io_deqDelay_0_bits_common_fuOpType, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_src_0", g_io_deqDelay_0_bits_common_src_0, i_io_deqDelay_0_bits_common_src_0, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_src_1", g_io_deqDelay_0_bits_common_src_1, i_io_deqDelay_0_bits_common_src_1, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_src_2", g_io_deqDelay_0_bits_common_src_2, i_io_deqDelay_0_bits_common_src_2, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_src_3", g_io_deqDelay_0_bits_common_src_3, i_io_deqDelay_0_bits_common_src_3, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_src_4", g_io_deqDelay_0_bits_common_src_4, i_io_deqDelay_0_bits_common_src_4, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_imm", g_io_deqDelay_0_bits_common_imm, i_io_deqDelay_0_bits_common_imm, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_robIdx_flag", g_io_deqDelay_0_bits_common_robIdx_flag, i_io_deqDelay_0_bits_common_robIdx_flag, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_robIdx_value", g_io_deqDelay_0_bits_common_robIdx_value, i_io_deqDelay_0_bits_common_robIdx_value, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_iqIdx", g_io_deqDelay_0_bits_common_iqIdx, i_io_deqDelay_0_bits_common_iqIdx, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_isFirstIssue", g_io_deqDelay_0_bits_common_isFirstIssue, i_io_deqDelay_0_bits_common_isFirstIssue, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_pdest", g_io_deqDelay_0_bits_common_pdest, i_io_deqDelay_0_bits_common_pdest, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vecWen", g_io_deqDelay_0_bits_common_vecWen, i_io_deqDelay_0_bits_common_vecWen, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_v0Wen", g_io_deqDelay_0_bits_common_v0Wen, i_io_deqDelay_0_bits_common_v0Wen, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_fpu_typeTagOut", g_io_deqDelay_0_bits_common_fpu_typeTagOut, i_io_deqDelay_0_bits_common_fpu_typeTagOut, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_fpu_wflags", g_io_deqDelay_0_bits_common_fpu_wflags, i_io_deqDelay_0_bits_common_fpu_wflags, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_fpu_typ", g_io_deqDelay_0_bits_common_fpu_typ, i_io_deqDelay_0_bits_common_fpu_typ, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_fpu_fmt", g_io_deqDelay_0_bits_common_fpu_fmt, i_io_deqDelay_0_bits_common_fpu_fmt, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_fpu_rm", g_io_deqDelay_0_bits_common_fpu_rm, i_io_deqDelay_0_bits_common_fpu_rm, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_vill", g_io_deqDelay_0_bits_common_vpu_vill, i_io_deqDelay_0_bits_common_vpu_vill, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_vma", g_io_deqDelay_0_bits_common_vpu_vma, i_io_deqDelay_0_bits_common_vpu_vma, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_vta", g_io_deqDelay_0_bits_common_vpu_vta, i_io_deqDelay_0_bits_common_vpu_vta, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_vsew", g_io_deqDelay_0_bits_common_vpu_vsew, i_io_deqDelay_0_bits_common_vpu_vsew, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_vlmul", g_io_deqDelay_0_bits_common_vpu_vlmul, i_io_deqDelay_0_bits_common_vpu_vlmul, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_specVill", g_io_deqDelay_0_bits_common_vpu_specVill, i_io_deqDelay_0_bits_common_vpu_specVill, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_specVma", g_io_deqDelay_0_bits_common_vpu_specVma, i_io_deqDelay_0_bits_common_vpu_specVma, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_specVta", g_io_deqDelay_0_bits_common_vpu_specVta, i_io_deqDelay_0_bits_common_vpu_specVta, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_specVsew", g_io_deqDelay_0_bits_common_vpu_specVsew, i_io_deqDelay_0_bits_common_vpu_specVsew, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_specVlmul", g_io_deqDelay_0_bits_common_vpu_specVlmul, i_io_deqDelay_0_bits_common_vpu_specVlmul, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_vm", g_io_deqDelay_0_bits_common_vpu_vm, i_io_deqDelay_0_bits_common_vpu_vm, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_vstart", g_io_deqDelay_0_bits_common_vpu_vstart, i_io_deqDelay_0_bits_common_vpu_vstart, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_frm", g_io_deqDelay_0_bits_common_vpu_frm, i_io_deqDelay_0_bits_common_vpu_frm, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_fpu_isFpToVecInst", g_io_deqDelay_0_bits_common_vpu_fpu_isFpToVecInst, i_io_deqDelay_0_bits_common_vpu_fpu_isFpToVecInst, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_fpu_isFP32Instr", g_io_deqDelay_0_bits_common_vpu_fpu_isFP32Instr, i_io_deqDelay_0_bits_common_vpu_fpu_isFP32Instr, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_fpu_isFP64Instr", g_io_deqDelay_0_bits_common_vpu_fpu_isFP64Instr, i_io_deqDelay_0_bits_common_vpu_fpu_isFP64Instr, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_fpu_isReduction", g_io_deqDelay_0_bits_common_vpu_fpu_isReduction, i_io_deqDelay_0_bits_common_vpu_fpu_isReduction, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_2", g_io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_2, i_io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_2, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_4", g_io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_4, i_io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_4, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_8", g_io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_8, i_io_deqDelay_0_bits_common_vpu_fpu_isFoldTo1_8, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_vxrm", g_io_deqDelay_0_bits_common_vpu_vxrm, i_io_deqDelay_0_bits_common_vpu_vxrm, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_vuopIdx", g_io_deqDelay_0_bits_common_vpu_vuopIdx, i_io_deqDelay_0_bits_common_vpu_vuopIdx, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_lastUop", g_io_deqDelay_0_bits_common_vpu_lastUop, i_io_deqDelay_0_bits_common_vpu_lastUop, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_vmask", g_io_deqDelay_0_bits_common_vpu_vmask, i_io_deqDelay_0_bits_common_vpu_vmask, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_vl", g_io_deqDelay_0_bits_common_vpu_vl, i_io_deqDelay_0_bits_common_vpu_vl, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_nf", g_io_deqDelay_0_bits_common_vpu_nf, i_io_deqDelay_0_bits_common_vpu_nf, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_veew", g_io_deqDelay_0_bits_common_vpu_veew, i_io_deqDelay_0_bits_common_vpu_veew, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_isReverse", g_io_deqDelay_0_bits_common_vpu_isReverse, i_io_deqDelay_0_bits_common_vpu_isReverse, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_isExt", g_io_deqDelay_0_bits_common_vpu_isExt, i_io_deqDelay_0_bits_common_vpu_isExt, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_isNarrow", g_io_deqDelay_0_bits_common_vpu_isNarrow, i_io_deqDelay_0_bits_common_vpu_isNarrow, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_isDstMask", g_io_deqDelay_0_bits_common_vpu_isDstMask, i_io_deqDelay_0_bits_common_vpu_isDstMask, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_isOpMask", g_io_deqDelay_0_bits_common_vpu_isOpMask, i_io_deqDelay_0_bits_common_vpu_isOpMask, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_isMove", g_io_deqDelay_0_bits_common_vpu_isMove, i_io_deqDelay_0_bits_common_vpu_isMove, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_isDependOldVd", g_io_deqDelay_0_bits_common_vpu_isDependOldVd, i_io_deqDelay_0_bits_common_vpu_isDependOldVd, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_isWritePartVd", g_io_deqDelay_0_bits_common_vpu_isWritePartVd, i_io_deqDelay_0_bits_common_vpu_isWritePartVd, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_vpu_isVleff", g_io_deqDelay_0_bits_common_vpu_isVleff, i_io_deqDelay_0_bits_common_vpu_isVleff, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_dataSources_0_value", g_io_deqDelay_0_bits_common_dataSources_0_value, i_io_deqDelay_0_bits_common_dataSources_0_value, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_dataSources_1_value", g_io_deqDelay_0_bits_common_dataSources_1_value, i_io_deqDelay_0_bits_common_dataSources_1_value, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_dataSources_2_value", g_io_deqDelay_0_bits_common_dataSources_2_value, i_io_deqDelay_0_bits_common_dataSources_2_value, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_dataSources_3_value", g_io_deqDelay_0_bits_common_dataSources_3_value, i_io_deqDelay_0_bits_common_dataSources_3_value, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_dataSources_4_value", g_io_deqDelay_0_bits_common_dataSources_4_value, i_io_deqDelay_0_bits_common_dataSources_4_value, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_perfDebugInfo_eliminatedMove", g_io_deqDelay_0_bits_common_perfDebugInfo_eliminatedMove, i_io_deqDelay_0_bits_common_perfDebugInfo_eliminatedMove, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_perfDebugInfo_renameTime", g_io_deqDelay_0_bits_common_perfDebugInfo_renameTime, i_io_deqDelay_0_bits_common_perfDebugInfo_renameTime, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_perfDebugInfo_dispatchTime", g_io_deqDelay_0_bits_common_perfDebugInfo_dispatchTime, i_io_deqDelay_0_bits_common_perfDebugInfo_dispatchTime, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_perfDebugInfo_enqRsTime", g_io_deqDelay_0_bits_common_perfDebugInfo_enqRsTime, i_io_deqDelay_0_bits_common_perfDebugInfo_enqRsTime, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_perfDebugInfo_selectTime", g_io_deqDelay_0_bits_common_perfDebugInfo_selectTime, i_io_deqDelay_0_bits_common_perfDebugInfo_selectTime, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_perfDebugInfo_issueTime", g_io_deqDelay_0_bits_common_perfDebugInfo_issueTime, i_io_deqDelay_0_bits_common_perfDebugInfo_issueTime, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_perfDebugInfo_writebackTime", g_io_deqDelay_0_bits_common_perfDebugInfo_writebackTime, i_io_deqDelay_0_bits_common_perfDebugInfo_writebackTime, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_perfDebugInfo_runahead_checkpoint_id", g_io_deqDelay_0_bits_common_perfDebugInfo_runahead_checkpoint_id, i_io_deqDelay_0_bits_common_perfDebugInfo_runahead_checkpoint_id, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_perfDebugInfo_tlbFirstReqTime", g_io_deqDelay_0_bits_common_perfDebugInfo_tlbFirstReqTime, i_io_deqDelay_0_bits_common_perfDebugInfo_tlbFirstReqTime, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_perfDebugInfo_tlbRespTime", g_io_deqDelay_0_bits_common_perfDebugInfo_tlbRespTime, i_io_deqDelay_0_bits_common_perfDebugInfo_tlbRespTime, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_debug_seqNum_seqNum", g_io_deqDelay_0_bits_common_debug_seqNum_seqNum, i_io_deqDelay_0_bits_common_debug_seqNum_seqNum, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_common_debug_seqNum_uopIdx", g_io_deqDelay_0_bits_common_debug_seqNum_uopIdx, i_io_deqDelay_0_bits_common_debug_seqNum_uopIdx, cmp_all || (warm && g_io_deqDelay_0_valid));
      chk("io_deqDelay_0_bits_addrOH", g_io_deqDelay_0_bits_addrOH, i_io_deqDelay_0_bits_addrOH, cmp_all || (warm && g_io_deqDelay_0_valid));
      if ((io_enq_0_valid && g_io_enq_0_ready) || (io_enq_1_valid && g_io_enq_1_ready)) cov_enq_fire++;
      if (io_flush_valid) cov_flush++;
      if (u_g.deqBeforeDly_0_valid) begin
        cov_deq0++;
        if (|u_g.deqBeforeDly_0_bits_addrOH[9:4]) cov_sel_comp++;
        else if (|u_g.deqBeforeDly_0_bits_addrOH[3:2]) cov_sel_simp++;
        else cov_sel_enq++;
      end
      if (g_io_deqDelay_0_valid && !io_deqDelay_0_ready) cov_dly_not_ready++;
    end
  end

  initial begin
    int bad;
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    if ($test$plusargs("cmp_all")) cmp_all = 1;
    reset = 1; repeat (5) @(posedge clock); @(negedge clock); reset = 0;
    repeat (NCYCLES) @(posedge clock);
    bad = (errors != 0);
    if (!warm && !cmp_all) begin bad = 1; $display("*** 条目阵列没有全部被写过，随机初值档无法比对"); end
    $display("  cov %-14s = %0d", "enq_fire", cov_enq_fire);
    if (cov_enq_fire == 0) begin bad = 1; $display("  *** COVERAGE HOLE: enq_fire"); end
    $display("  cov %-14s = %0d", "flush", cov_flush);
    if (cov_flush == 0) begin bad = 1; $display("  *** COVERAGE HOLE: flush"); end
    $display("  cov %-14s = %0d", "sel_comp", cov_sel_comp);
    if (cov_sel_comp == 0) begin bad = 1; $display("  *** COVERAGE HOLE: sel_comp"); end
    $display("  cov %-14s = %0d", "sel_simp", cov_sel_simp);
    if (cov_sel_simp == 0) begin bad = 1; $display("  *** COVERAGE HOLE: sel_simp"); end
    $display("  cov %-14s = %0d", "sel_enq", cov_sel_enq);
    if (cov_sel_enq == 0) begin bad = 1; $display("  *** COVERAGE HOLE: sel_enq"); end
    $display("  cov %-14s = %0d", "dly_not_ready", cov_dly_not_ready);
    if (cov_dly_not_ready == 0) begin bad = 1; $display("  *** COVERAGE HOLE: dly_not_ready"); end
    $display("  cov %-14s = %0d", "deq0", cov_deq0);
    if (cov_deq0 == 0) begin bad = 1; $display("  *** COVERAGE HOLE: deq0"); end
    $display("cmp_all=%0d warm=%0d", cmp_all, warm);
    $display("checks=%0d errors=%0d", checks, errors);
    if (!bad) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
