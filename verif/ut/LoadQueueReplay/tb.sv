// LoadQueueReplay UT —— golden 与重写件双例化，逐拍比对**全部 589 个输出端口**。
//
// 本文件由 scripts/gen_lqreplay_ut.py 生成（接线部分机械，激励模型是脚本里的手写常量块）。
// 手改这里会被下一次跑生成器覆盖 —— 要改激励请改生成器。
`timescale 1ns/1ps
module tb;
  bit clk = 0, rst;
  always #5 clk = ~clk;

  // ---- 输入信号（两侧共用一套激励）----
  logic            io_redirect_valid;
  logic            io_redirect_bits_robIdx_flag;
  logic [7:0]      io_redirect_bits_robIdx_value;
  logic            io_redirect_bits_level;
  logic            io_vecFeedback_0_valid;
  logic            io_vecFeedback_0_bits_robidx_flag;
  logic [7:0]      io_vecFeedback_0_bits_robidx_value;
  logic [6:0]      io_vecFeedback_0_bits_uopidx;
  logic            io_vecFeedback_0_bits_feedback_0;
  logic            io_vecFeedback_0_bits_feedback_1;
  logic            io_vecFeedback_1_valid;
  logic            io_vecFeedback_1_bits_robidx_flag;
  logic [7:0]      io_vecFeedback_1_bits_robidx_value;
  logic [6:0]      io_vecFeedback_1_bits_uopidx;
  logic            io_vecFeedback_1_bits_feedback_0;
  logic            io_vecFeedback_1_bits_feedback_1;
  logic            io_enq_0_valid;
  logic [31:0]     io_enq_0_bits_uop_instr;
  logic [49:0]     io_enq_0_bits_uop_pc;
  logic [9:0]      io_enq_0_bits_uop_foldpc;
  logic            io_enq_0_bits_uop_exceptionVec_0;
  logic            io_enq_0_bits_uop_exceptionVec_1;
  logic            io_enq_0_bits_uop_exceptionVec_2;
  logic            io_enq_0_bits_uop_exceptionVec_3;
  logic            io_enq_0_bits_uop_exceptionVec_5;
  logic            io_enq_0_bits_uop_exceptionVec_6;
  logic            io_enq_0_bits_uop_exceptionVec_7;
  logic            io_enq_0_bits_uop_exceptionVec_8;
  logic            io_enq_0_bits_uop_exceptionVec_9;
  logic            io_enq_0_bits_uop_exceptionVec_10;
  logic            io_enq_0_bits_uop_exceptionVec_11;
  logic            io_enq_0_bits_uop_exceptionVec_12;
  logic            io_enq_0_bits_uop_exceptionVec_13;
  logic            io_enq_0_bits_uop_exceptionVec_14;
  logic            io_enq_0_bits_uop_exceptionVec_15;
  logic            io_enq_0_bits_uop_exceptionVec_16;
  logic            io_enq_0_bits_uop_exceptionVec_17;
  logic            io_enq_0_bits_uop_exceptionVec_18;
  logic            io_enq_0_bits_uop_exceptionVec_19;
  logic            io_enq_0_bits_uop_exceptionVec_20;
  logic            io_enq_0_bits_uop_exceptionVec_21;
  logic            io_enq_0_bits_uop_exceptionVec_22;
  logic            io_enq_0_bits_uop_exceptionVec_23;
  logic            io_enq_0_bits_uop_isFetchMalAddr;
  logic            io_enq_0_bits_uop_hasException;
  logic [3:0]      io_enq_0_bits_uop_trigger;
  logic            io_enq_0_bits_uop_preDecodeInfo_valid;
  logic            io_enq_0_bits_uop_preDecodeInfo_isRVC;
  logic [1:0]      io_enq_0_bits_uop_preDecodeInfo_brType;
  logic            io_enq_0_bits_uop_preDecodeInfo_isCall;
  logic            io_enq_0_bits_uop_preDecodeInfo_isRet;
  logic            io_enq_0_bits_uop_pred_taken;
  logic            io_enq_0_bits_uop_crossPageIPFFix;
  logic            io_enq_0_bits_uop_ftqPtr_flag;
  logic [5:0]      io_enq_0_bits_uop_ftqPtr_value;
  logic [3:0]      io_enq_0_bits_uop_ftqOffset;
  logic            io_enq_0_bits_uop_satpFlushFirstFetchFault;
  logic [3:0]      io_enq_0_bits_uop_srcType_0;
  logic [3:0]      io_enq_0_bits_uop_srcType_1;
  logic [3:0]      io_enq_0_bits_uop_srcType_2;
  logic [3:0]      io_enq_0_bits_uop_srcType_3;
  logic [3:0]      io_enq_0_bits_uop_srcType_4;
  logic [5:0]      io_enq_0_bits_uop_ldest;
  logic [34:0]     io_enq_0_bits_uop_fuType;
  logic [8:0]      io_enq_0_bits_uop_fuOpType;
  logic            io_enq_0_bits_uop_rfWen;
  logic            io_enq_0_bits_uop_fpWen;
  logic            io_enq_0_bits_uop_vecWen;
  logic            io_enq_0_bits_uop_v0Wen;
  logic            io_enq_0_bits_uop_vlWen;
  logic            io_enq_0_bits_uop_isXSTrap;
  logic            io_enq_0_bits_uop_waitForward;
  logic            io_enq_0_bits_uop_blockBackward;
  logic            io_enq_0_bits_uop_canRobCompress;
  logic [3:0]      io_enq_0_bits_uop_selImm;
  logic [31:0]     io_enq_0_bits_uop_imm;
  logic [1:0]      io_enq_0_bits_uop_fpu_typeTagOut;
  logic            io_enq_0_bits_uop_fpu_wflags;
  logic [1:0]      io_enq_0_bits_uop_fpu_typ;
  logic [1:0]      io_enq_0_bits_uop_fpu_fmt;
  logic [2:0]      io_enq_0_bits_uop_fpu_rm;
  logic            io_enq_0_bits_uop_vpu_vill;
  logic            io_enq_0_bits_uop_vpu_vma;
  logic            io_enq_0_bits_uop_vpu_vta;
  logic [1:0]      io_enq_0_bits_uop_vpu_vsew;
  logic [2:0]      io_enq_0_bits_uop_vpu_vlmul;
  logic            io_enq_0_bits_uop_vpu_specVill;
  logic            io_enq_0_bits_uop_vpu_specVma;
  logic            io_enq_0_bits_uop_vpu_specVta;
  logic [1:0]      io_enq_0_bits_uop_vpu_specVsew;
  logic [2:0]      io_enq_0_bits_uop_vpu_specVlmul;
  logic            io_enq_0_bits_uop_vpu_vm;
  logic [7:0]      io_enq_0_bits_uop_vpu_vstart;
  logic [2:0]      io_enq_0_bits_uop_vpu_frm;
  logic            io_enq_0_bits_uop_vpu_fpu_isFpToVecInst;
  logic            io_enq_0_bits_uop_vpu_fpu_isFP32Instr;
  logic            io_enq_0_bits_uop_vpu_fpu_isFP64Instr;
  logic            io_enq_0_bits_uop_vpu_fpu_isReduction;
  logic            io_enq_0_bits_uop_vpu_fpu_isFoldTo1_2;
  logic            io_enq_0_bits_uop_vpu_fpu_isFoldTo1_4;
  logic            io_enq_0_bits_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0]      io_enq_0_bits_uop_vpu_vxrm;
  logic [6:0]      io_enq_0_bits_uop_vpu_vuopIdx;
  logic            io_enq_0_bits_uop_vpu_lastUop;
  logic [127:0]    io_enq_0_bits_uop_vpu_vmask;
  logic [7:0]      io_enq_0_bits_uop_vpu_vl;
  logic [2:0]      io_enq_0_bits_uop_vpu_nf;
  logic [1:0]      io_enq_0_bits_uop_vpu_veew;
  logic            io_enq_0_bits_uop_vpu_isReverse;
  logic            io_enq_0_bits_uop_vpu_isExt;
  logic            io_enq_0_bits_uop_vpu_isNarrow;
  logic            io_enq_0_bits_uop_vpu_isDstMask;
  logic            io_enq_0_bits_uop_vpu_isOpMask;
  logic            io_enq_0_bits_uop_vpu_isMove;
  logic            io_enq_0_bits_uop_vpu_isDependOldVd;
  logic            io_enq_0_bits_uop_vpu_isWritePartVd;
  logic            io_enq_0_bits_uop_vpu_isVleff;
  logic            io_enq_0_bits_uop_vlsInstr;
  logic            io_enq_0_bits_uop_wfflags;
  logic            io_enq_0_bits_uop_isMove;
  logic            io_enq_0_bits_uop_isDropAmocasSta;
  logic [6:0]      io_enq_0_bits_uop_uopIdx;
  logic            io_enq_0_bits_uop_isVset;
  logic            io_enq_0_bits_uop_firstUop;
  logic            io_enq_0_bits_uop_lastUop;
  logic [6:0]      io_enq_0_bits_uop_numUops;
  logic [6:0]      io_enq_0_bits_uop_numWB;
  logic [2:0]      io_enq_0_bits_uop_commitType;
  logic            io_enq_0_bits_uop_srcState_0;
  logic            io_enq_0_bits_uop_srcState_1;
  logic            io_enq_0_bits_uop_srcState_2;
  logic            io_enq_0_bits_uop_srcState_3;
  logic            io_enq_0_bits_uop_srcState_4;
  logic [1:0]      io_enq_0_bits_uop_srcLoadDependency_0_0;
  logic [1:0]      io_enq_0_bits_uop_srcLoadDependency_0_1;
  logic [1:0]      io_enq_0_bits_uop_srcLoadDependency_0_2;
  logic [1:0]      io_enq_0_bits_uop_srcLoadDependency_1_0;
  logic [1:0]      io_enq_0_bits_uop_srcLoadDependency_1_1;
  logic [1:0]      io_enq_0_bits_uop_srcLoadDependency_1_2;
  logic [1:0]      io_enq_0_bits_uop_srcLoadDependency_2_0;
  logic [1:0]      io_enq_0_bits_uop_srcLoadDependency_2_1;
  logic [1:0]      io_enq_0_bits_uop_srcLoadDependency_2_2;
  logic [1:0]      io_enq_0_bits_uop_srcLoadDependency_3_0;
  logic [1:0]      io_enq_0_bits_uop_srcLoadDependency_3_1;
  logic [1:0]      io_enq_0_bits_uop_srcLoadDependency_3_2;
  logic [1:0]      io_enq_0_bits_uop_srcLoadDependency_4_0;
  logic [1:0]      io_enq_0_bits_uop_srcLoadDependency_4_1;
  logic [1:0]      io_enq_0_bits_uop_srcLoadDependency_4_2;
  logic [7:0]      io_enq_0_bits_uop_psrc_0;
  logic [7:0]      io_enq_0_bits_uop_psrc_1;
  logic [7:0]      io_enq_0_bits_uop_psrc_2;
  logic [7:0]      io_enq_0_bits_uop_psrc_3;
  logic [7:0]      io_enq_0_bits_uop_psrc_4;
  logic [7:0]      io_enq_0_bits_uop_pdest;
  logic            io_enq_0_bits_uop_useRegCache_0;
  logic            io_enq_0_bits_uop_useRegCache_1;
  logic [4:0]      io_enq_0_bits_uop_regCacheIdx_0;
  logic [4:0]      io_enq_0_bits_uop_regCacheIdx_1;
  logic            io_enq_0_bits_uop_robIdx_flag;
  logic [7:0]      io_enq_0_bits_uop_robIdx_value;
  logic [2:0]      io_enq_0_bits_uop_instrSize;
  logic            io_enq_0_bits_uop_dirtyFs;
  logic            io_enq_0_bits_uop_dirtyVs;
  logic [3:0]      io_enq_0_bits_uop_traceBlockInPipe_itype;
  logic [3:0]      io_enq_0_bits_uop_traceBlockInPipe_iretire;
  logic            io_enq_0_bits_uop_traceBlockInPipe_ilastsize;
  logic            io_enq_0_bits_uop_eliminatedMove;
  logic            io_enq_0_bits_uop_snapshot;
  logic            io_enq_0_bits_uop_debugInfo_eliminatedMove;
  logic [63:0]     io_enq_0_bits_uop_debugInfo_renameTime;
  logic [63:0]     io_enq_0_bits_uop_debugInfo_dispatchTime;
  logic [63:0]     io_enq_0_bits_uop_debugInfo_enqRsTime;
  logic [63:0]     io_enq_0_bits_uop_debugInfo_selectTime;
  logic [63:0]     io_enq_0_bits_uop_debugInfo_issueTime;
  logic [63:0]     io_enq_0_bits_uop_debugInfo_writebackTime;
  logic [63:0]     io_enq_0_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]     io_enq_0_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]     io_enq_0_bits_uop_debugInfo_tlbRespTime;
  logic [55:0]     io_enq_0_bits_uop_debug_seqNum_seqNum;
  logic [7:0]      io_enq_0_bits_uop_debug_seqNum_uopIdx;
  logic            io_enq_0_bits_uop_storeSetHit;
  logic            io_enq_0_bits_uop_waitForRobIdx_flag;
  logic [7:0]      io_enq_0_bits_uop_waitForRobIdx_value;
  logic            io_enq_0_bits_uop_loadWaitBit;
  logic            io_enq_0_bits_uop_loadWaitStrict;
  logic [4:0]      io_enq_0_bits_uop_ssid;
  logic            io_enq_0_bits_uop_lqIdx_flag;
  logic [6:0]      io_enq_0_bits_uop_lqIdx_value;
  logic            io_enq_0_bits_uop_sqIdx_flag;
  logic [5:0]      io_enq_0_bits_uop_sqIdx_value;
  logic            io_enq_0_bits_uop_singleStep;
  logic [34:0]     io_enq_0_bits_uop_debug_fuType;
  logic            io_enq_0_bits_uop_debug_sim_trig;
  logic [4:0]      io_enq_0_bits_uop_numLsElem;
  logic [49:0]     io_enq_0_bits_vaddr;
  logic [15:0]     io_enq_0_bits_mask;
  logic            io_enq_0_bits_isvec;
  logic            io_enq_0_bits_is128bit;
  logic [7:0]      io_enq_0_bits_elemIdx;
  logic [2:0]      io_enq_0_bits_alignedType;
  logic [3:0]      io_enq_0_bits_mbIndex;
  logic [3:0]      io_enq_0_bits_reg_offset;
  logic [7:0]      io_enq_0_bits_elemIdxInsideVd;
  logic            io_enq_0_bits_vecActive;
  logic            io_enq_0_bits_isLoadReplay;
  logic            io_enq_0_bits_handledByMSHR;
  logic [6:0]      io_enq_0_bits_schedIndex;
  logic [3:0]      io_enq_0_bits_rep_info_mshr_id;
  logic            io_enq_0_bits_rep_info_full_fwd;
  logic            io_enq_0_bits_rep_info_data_inv_sq_idx_flag;
  logic [5:0]      io_enq_0_bits_rep_info_data_inv_sq_idx_value;
  logic            io_enq_0_bits_rep_info_addr_inv_sq_idx_flag;
  logic [5:0]      io_enq_0_bits_rep_info_addr_inv_sq_idx_value;
  logic            io_enq_0_bits_rep_info_last_beat;
  logic            io_enq_0_bits_rep_info_cause_0;
  logic            io_enq_0_bits_rep_info_cause_1;
  logic            io_enq_0_bits_rep_info_cause_2;
  logic            io_enq_0_bits_rep_info_cause_3;
  logic            io_enq_0_bits_rep_info_cause_4;
  logic            io_enq_0_bits_rep_info_cause_5;
  logic            io_enq_0_bits_rep_info_cause_6;
  logic            io_enq_0_bits_rep_info_cause_7;
  logic            io_enq_0_bits_rep_info_cause_8;
  logic            io_enq_0_bits_rep_info_cause_9;
  logic            io_enq_0_bits_rep_info_cause_10;
  logic [3:0]      io_enq_0_bits_rep_info_tlb_id;
  logic            io_enq_0_bits_rep_info_tlb_full;
  logic            io_enq_1_valid;
  logic [31:0]     io_enq_1_bits_uop_instr;
  logic [49:0]     io_enq_1_bits_uop_pc;
  logic [9:0]      io_enq_1_bits_uop_foldpc;
  logic            io_enq_1_bits_uop_exceptionVec_0;
  logic            io_enq_1_bits_uop_exceptionVec_1;
  logic            io_enq_1_bits_uop_exceptionVec_2;
  logic            io_enq_1_bits_uop_exceptionVec_3;
  logic            io_enq_1_bits_uop_exceptionVec_5;
  logic            io_enq_1_bits_uop_exceptionVec_6;
  logic            io_enq_1_bits_uop_exceptionVec_7;
  logic            io_enq_1_bits_uop_exceptionVec_8;
  logic            io_enq_1_bits_uop_exceptionVec_9;
  logic            io_enq_1_bits_uop_exceptionVec_10;
  logic            io_enq_1_bits_uop_exceptionVec_11;
  logic            io_enq_1_bits_uop_exceptionVec_12;
  logic            io_enq_1_bits_uop_exceptionVec_13;
  logic            io_enq_1_bits_uop_exceptionVec_14;
  logic            io_enq_1_bits_uop_exceptionVec_15;
  logic            io_enq_1_bits_uop_exceptionVec_16;
  logic            io_enq_1_bits_uop_exceptionVec_17;
  logic            io_enq_1_bits_uop_exceptionVec_18;
  logic            io_enq_1_bits_uop_exceptionVec_19;
  logic            io_enq_1_bits_uop_exceptionVec_20;
  logic            io_enq_1_bits_uop_exceptionVec_21;
  logic            io_enq_1_bits_uop_exceptionVec_22;
  logic            io_enq_1_bits_uop_exceptionVec_23;
  logic            io_enq_1_bits_uop_isFetchMalAddr;
  logic            io_enq_1_bits_uop_hasException;
  logic [3:0]      io_enq_1_bits_uop_trigger;
  logic            io_enq_1_bits_uop_preDecodeInfo_valid;
  logic            io_enq_1_bits_uop_preDecodeInfo_isRVC;
  logic [1:0]      io_enq_1_bits_uop_preDecodeInfo_brType;
  logic            io_enq_1_bits_uop_preDecodeInfo_isCall;
  logic            io_enq_1_bits_uop_preDecodeInfo_isRet;
  logic            io_enq_1_bits_uop_pred_taken;
  logic            io_enq_1_bits_uop_crossPageIPFFix;
  logic            io_enq_1_bits_uop_ftqPtr_flag;
  logic [5:0]      io_enq_1_bits_uop_ftqPtr_value;
  logic [3:0]      io_enq_1_bits_uop_ftqOffset;
  logic            io_enq_1_bits_uop_satpFlushFirstFetchFault;
  logic [3:0]      io_enq_1_bits_uop_srcType_0;
  logic [3:0]      io_enq_1_bits_uop_srcType_1;
  logic [3:0]      io_enq_1_bits_uop_srcType_2;
  logic [3:0]      io_enq_1_bits_uop_srcType_3;
  logic [3:0]      io_enq_1_bits_uop_srcType_4;
  logic [5:0]      io_enq_1_bits_uop_ldest;
  logic [34:0]     io_enq_1_bits_uop_fuType;
  logic [8:0]      io_enq_1_bits_uop_fuOpType;
  logic            io_enq_1_bits_uop_rfWen;
  logic            io_enq_1_bits_uop_fpWen;
  logic            io_enq_1_bits_uop_vecWen;
  logic            io_enq_1_bits_uop_v0Wen;
  logic            io_enq_1_bits_uop_vlWen;
  logic            io_enq_1_bits_uop_isXSTrap;
  logic            io_enq_1_bits_uop_waitForward;
  logic            io_enq_1_bits_uop_blockBackward;
  logic            io_enq_1_bits_uop_canRobCompress;
  logic [3:0]      io_enq_1_bits_uop_selImm;
  logic [31:0]     io_enq_1_bits_uop_imm;
  logic [1:0]      io_enq_1_bits_uop_fpu_typeTagOut;
  logic            io_enq_1_bits_uop_fpu_wflags;
  logic [1:0]      io_enq_1_bits_uop_fpu_typ;
  logic [1:0]      io_enq_1_bits_uop_fpu_fmt;
  logic [2:0]      io_enq_1_bits_uop_fpu_rm;
  logic            io_enq_1_bits_uop_vpu_vill;
  logic            io_enq_1_bits_uop_vpu_vma;
  logic            io_enq_1_bits_uop_vpu_vta;
  logic [1:0]      io_enq_1_bits_uop_vpu_vsew;
  logic [2:0]      io_enq_1_bits_uop_vpu_vlmul;
  logic            io_enq_1_bits_uop_vpu_specVill;
  logic            io_enq_1_bits_uop_vpu_specVma;
  logic            io_enq_1_bits_uop_vpu_specVta;
  logic [1:0]      io_enq_1_bits_uop_vpu_specVsew;
  logic [2:0]      io_enq_1_bits_uop_vpu_specVlmul;
  logic            io_enq_1_bits_uop_vpu_vm;
  logic [7:0]      io_enq_1_bits_uop_vpu_vstart;
  logic [2:0]      io_enq_1_bits_uop_vpu_frm;
  logic            io_enq_1_bits_uop_vpu_fpu_isFpToVecInst;
  logic            io_enq_1_bits_uop_vpu_fpu_isFP32Instr;
  logic            io_enq_1_bits_uop_vpu_fpu_isFP64Instr;
  logic            io_enq_1_bits_uop_vpu_fpu_isReduction;
  logic            io_enq_1_bits_uop_vpu_fpu_isFoldTo1_2;
  logic            io_enq_1_bits_uop_vpu_fpu_isFoldTo1_4;
  logic            io_enq_1_bits_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0]      io_enq_1_bits_uop_vpu_vxrm;
  logic [6:0]      io_enq_1_bits_uop_vpu_vuopIdx;
  logic            io_enq_1_bits_uop_vpu_lastUop;
  logic [127:0]    io_enq_1_bits_uop_vpu_vmask;
  logic [7:0]      io_enq_1_bits_uop_vpu_vl;
  logic [2:0]      io_enq_1_bits_uop_vpu_nf;
  logic [1:0]      io_enq_1_bits_uop_vpu_veew;
  logic            io_enq_1_bits_uop_vpu_isReverse;
  logic            io_enq_1_bits_uop_vpu_isExt;
  logic            io_enq_1_bits_uop_vpu_isNarrow;
  logic            io_enq_1_bits_uop_vpu_isDstMask;
  logic            io_enq_1_bits_uop_vpu_isOpMask;
  logic            io_enq_1_bits_uop_vpu_isMove;
  logic            io_enq_1_bits_uop_vpu_isDependOldVd;
  logic            io_enq_1_bits_uop_vpu_isWritePartVd;
  logic            io_enq_1_bits_uop_vpu_isVleff;
  logic            io_enq_1_bits_uop_vlsInstr;
  logic            io_enq_1_bits_uop_wfflags;
  logic            io_enq_1_bits_uop_isMove;
  logic            io_enq_1_bits_uop_isDropAmocasSta;
  logic [6:0]      io_enq_1_bits_uop_uopIdx;
  logic            io_enq_1_bits_uop_isVset;
  logic            io_enq_1_bits_uop_firstUop;
  logic            io_enq_1_bits_uop_lastUop;
  logic [6:0]      io_enq_1_bits_uop_numUops;
  logic [6:0]      io_enq_1_bits_uop_numWB;
  logic [2:0]      io_enq_1_bits_uop_commitType;
  logic            io_enq_1_bits_uop_srcState_0;
  logic            io_enq_1_bits_uop_srcState_1;
  logic            io_enq_1_bits_uop_srcState_2;
  logic            io_enq_1_bits_uop_srcState_3;
  logic            io_enq_1_bits_uop_srcState_4;
  logic [1:0]      io_enq_1_bits_uop_srcLoadDependency_0_0;
  logic [1:0]      io_enq_1_bits_uop_srcLoadDependency_0_1;
  logic [1:0]      io_enq_1_bits_uop_srcLoadDependency_0_2;
  logic [1:0]      io_enq_1_bits_uop_srcLoadDependency_1_0;
  logic [1:0]      io_enq_1_bits_uop_srcLoadDependency_1_1;
  logic [1:0]      io_enq_1_bits_uop_srcLoadDependency_1_2;
  logic [1:0]      io_enq_1_bits_uop_srcLoadDependency_2_0;
  logic [1:0]      io_enq_1_bits_uop_srcLoadDependency_2_1;
  logic [1:0]      io_enq_1_bits_uop_srcLoadDependency_2_2;
  logic [1:0]      io_enq_1_bits_uop_srcLoadDependency_3_0;
  logic [1:0]      io_enq_1_bits_uop_srcLoadDependency_3_1;
  logic [1:0]      io_enq_1_bits_uop_srcLoadDependency_3_2;
  logic [1:0]      io_enq_1_bits_uop_srcLoadDependency_4_0;
  logic [1:0]      io_enq_1_bits_uop_srcLoadDependency_4_1;
  logic [1:0]      io_enq_1_bits_uop_srcLoadDependency_4_2;
  logic [7:0]      io_enq_1_bits_uop_psrc_0;
  logic [7:0]      io_enq_1_bits_uop_psrc_1;
  logic [7:0]      io_enq_1_bits_uop_psrc_2;
  logic [7:0]      io_enq_1_bits_uop_psrc_3;
  logic [7:0]      io_enq_1_bits_uop_psrc_4;
  logic [7:0]      io_enq_1_bits_uop_pdest;
  logic            io_enq_1_bits_uop_useRegCache_0;
  logic            io_enq_1_bits_uop_useRegCache_1;
  logic [4:0]      io_enq_1_bits_uop_regCacheIdx_0;
  logic [4:0]      io_enq_1_bits_uop_regCacheIdx_1;
  logic            io_enq_1_bits_uop_robIdx_flag;
  logic [7:0]      io_enq_1_bits_uop_robIdx_value;
  logic [2:0]      io_enq_1_bits_uop_instrSize;
  logic            io_enq_1_bits_uop_dirtyFs;
  logic            io_enq_1_bits_uop_dirtyVs;
  logic [3:0]      io_enq_1_bits_uop_traceBlockInPipe_itype;
  logic [3:0]      io_enq_1_bits_uop_traceBlockInPipe_iretire;
  logic            io_enq_1_bits_uop_traceBlockInPipe_ilastsize;
  logic            io_enq_1_bits_uop_eliminatedMove;
  logic            io_enq_1_bits_uop_snapshot;
  logic            io_enq_1_bits_uop_debugInfo_eliminatedMove;
  logic [63:0]     io_enq_1_bits_uop_debugInfo_renameTime;
  logic [63:0]     io_enq_1_bits_uop_debugInfo_dispatchTime;
  logic [63:0]     io_enq_1_bits_uop_debugInfo_enqRsTime;
  logic [63:0]     io_enq_1_bits_uop_debugInfo_selectTime;
  logic [63:0]     io_enq_1_bits_uop_debugInfo_issueTime;
  logic [63:0]     io_enq_1_bits_uop_debugInfo_writebackTime;
  logic [63:0]     io_enq_1_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]     io_enq_1_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]     io_enq_1_bits_uop_debugInfo_tlbRespTime;
  logic [55:0]     io_enq_1_bits_uop_debug_seqNum_seqNum;
  logic [7:0]      io_enq_1_bits_uop_debug_seqNum_uopIdx;
  logic            io_enq_1_bits_uop_storeSetHit;
  logic            io_enq_1_bits_uop_waitForRobIdx_flag;
  logic [7:0]      io_enq_1_bits_uop_waitForRobIdx_value;
  logic            io_enq_1_bits_uop_loadWaitBit;
  logic            io_enq_1_bits_uop_loadWaitStrict;
  logic [4:0]      io_enq_1_bits_uop_ssid;
  logic            io_enq_1_bits_uop_lqIdx_flag;
  logic [6:0]      io_enq_1_bits_uop_lqIdx_value;
  logic            io_enq_1_bits_uop_sqIdx_flag;
  logic [5:0]      io_enq_1_bits_uop_sqIdx_value;
  logic            io_enq_1_bits_uop_singleStep;
  logic [34:0]     io_enq_1_bits_uop_debug_fuType;
  logic            io_enq_1_bits_uop_debug_sim_trig;
  logic [4:0]      io_enq_1_bits_uop_numLsElem;
  logic [49:0]     io_enq_1_bits_vaddr;
  logic [15:0]     io_enq_1_bits_mask;
  logic            io_enq_1_bits_isvec;
  logic            io_enq_1_bits_is128bit;
  logic [7:0]      io_enq_1_bits_elemIdx;
  logic [2:0]      io_enq_1_bits_alignedType;
  logic [3:0]      io_enq_1_bits_mbIndex;
  logic [3:0]      io_enq_1_bits_reg_offset;
  logic [7:0]      io_enq_1_bits_elemIdxInsideVd;
  logic            io_enq_1_bits_vecActive;
  logic            io_enq_1_bits_isLoadReplay;
  logic            io_enq_1_bits_handledByMSHR;
  logic [6:0]      io_enq_1_bits_schedIndex;
  logic [3:0]      io_enq_1_bits_rep_info_mshr_id;
  logic            io_enq_1_bits_rep_info_full_fwd;
  logic            io_enq_1_bits_rep_info_data_inv_sq_idx_flag;
  logic [5:0]      io_enq_1_bits_rep_info_data_inv_sq_idx_value;
  logic            io_enq_1_bits_rep_info_addr_inv_sq_idx_flag;
  logic [5:0]      io_enq_1_bits_rep_info_addr_inv_sq_idx_value;
  logic            io_enq_1_bits_rep_info_last_beat;
  logic            io_enq_1_bits_rep_info_cause_0;
  logic            io_enq_1_bits_rep_info_cause_1;
  logic            io_enq_1_bits_rep_info_cause_2;
  logic            io_enq_1_bits_rep_info_cause_3;
  logic            io_enq_1_bits_rep_info_cause_4;
  logic            io_enq_1_bits_rep_info_cause_5;
  logic            io_enq_1_bits_rep_info_cause_6;
  logic            io_enq_1_bits_rep_info_cause_7;
  logic            io_enq_1_bits_rep_info_cause_8;
  logic            io_enq_1_bits_rep_info_cause_9;
  logic            io_enq_1_bits_rep_info_cause_10;
  logic [3:0]      io_enq_1_bits_rep_info_tlb_id;
  logic            io_enq_1_bits_rep_info_tlb_full;
  logic            io_enq_2_valid;
  logic [31:0]     io_enq_2_bits_uop_instr;
  logic [49:0]     io_enq_2_bits_uop_pc;
  logic [9:0]      io_enq_2_bits_uop_foldpc;
  logic            io_enq_2_bits_uop_exceptionVec_0;
  logic            io_enq_2_bits_uop_exceptionVec_1;
  logic            io_enq_2_bits_uop_exceptionVec_2;
  logic            io_enq_2_bits_uop_exceptionVec_3;
  logic            io_enq_2_bits_uop_exceptionVec_5;
  logic            io_enq_2_bits_uop_exceptionVec_6;
  logic            io_enq_2_bits_uop_exceptionVec_7;
  logic            io_enq_2_bits_uop_exceptionVec_8;
  logic            io_enq_2_bits_uop_exceptionVec_9;
  logic            io_enq_2_bits_uop_exceptionVec_10;
  logic            io_enq_2_bits_uop_exceptionVec_11;
  logic            io_enq_2_bits_uop_exceptionVec_12;
  logic            io_enq_2_bits_uop_exceptionVec_13;
  logic            io_enq_2_bits_uop_exceptionVec_14;
  logic            io_enq_2_bits_uop_exceptionVec_15;
  logic            io_enq_2_bits_uop_exceptionVec_16;
  logic            io_enq_2_bits_uop_exceptionVec_17;
  logic            io_enq_2_bits_uop_exceptionVec_18;
  logic            io_enq_2_bits_uop_exceptionVec_19;
  logic            io_enq_2_bits_uop_exceptionVec_20;
  logic            io_enq_2_bits_uop_exceptionVec_21;
  logic            io_enq_2_bits_uop_exceptionVec_22;
  logic            io_enq_2_bits_uop_exceptionVec_23;
  logic            io_enq_2_bits_uop_isFetchMalAddr;
  logic            io_enq_2_bits_uop_hasException;
  logic [3:0]      io_enq_2_bits_uop_trigger;
  logic            io_enq_2_bits_uop_preDecodeInfo_valid;
  logic            io_enq_2_bits_uop_preDecodeInfo_isRVC;
  logic [1:0]      io_enq_2_bits_uop_preDecodeInfo_brType;
  logic            io_enq_2_bits_uop_preDecodeInfo_isCall;
  logic            io_enq_2_bits_uop_preDecodeInfo_isRet;
  logic            io_enq_2_bits_uop_pred_taken;
  logic            io_enq_2_bits_uop_crossPageIPFFix;
  logic            io_enq_2_bits_uop_ftqPtr_flag;
  logic [5:0]      io_enq_2_bits_uop_ftqPtr_value;
  logic [3:0]      io_enq_2_bits_uop_ftqOffset;
  logic            io_enq_2_bits_uop_satpFlushFirstFetchFault;
  logic [3:0]      io_enq_2_bits_uop_srcType_0;
  logic [3:0]      io_enq_2_bits_uop_srcType_1;
  logic [3:0]      io_enq_2_bits_uop_srcType_2;
  logic [3:0]      io_enq_2_bits_uop_srcType_3;
  logic [3:0]      io_enq_2_bits_uop_srcType_4;
  logic [5:0]      io_enq_2_bits_uop_ldest;
  logic [34:0]     io_enq_2_bits_uop_fuType;
  logic [8:0]      io_enq_2_bits_uop_fuOpType;
  logic            io_enq_2_bits_uop_rfWen;
  logic            io_enq_2_bits_uop_fpWen;
  logic            io_enq_2_bits_uop_vecWen;
  logic            io_enq_2_bits_uop_v0Wen;
  logic            io_enq_2_bits_uop_vlWen;
  logic            io_enq_2_bits_uop_isXSTrap;
  logic            io_enq_2_bits_uop_waitForward;
  logic            io_enq_2_bits_uop_blockBackward;
  logic            io_enq_2_bits_uop_canRobCompress;
  logic [3:0]      io_enq_2_bits_uop_selImm;
  logic [31:0]     io_enq_2_bits_uop_imm;
  logic [1:0]      io_enq_2_bits_uop_fpu_typeTagOut;
  logic            io_enq_2_bits_uop_fpu_wflags;
  logic [1:0]      io_enq_2_bits_uop_fpu_typ;
  logic [1:0]      io_enq_2_bits_uop_fpu_fmt;
  logic [2:0]      io_enq_2_bits_uop_fpu_rm;
  logic            io_enq_2_bits_uop_vpu_vill;
  logic            io_enq_2_bits_uop_vpu_vma;
  logic            io_enq_2_bits_uop_vpu_vta;
  logic [1:0]      io_enq_2_bits_uop_vpu_vsew;
  logic [2:0]      io_enq_2_bits_uop_vpu_vlmul;
  logic            io_enq_2_bits_uop_vpu_specVill;
  logic            io_enq_2_bits_uop_vpu_specVma;
  logic            io_enq_2_bits_uop_vpu_specVta;
  logic [1:0]      io_enq_2_bits_uop_vpu_specVsew;
  logic [2:0]      io_enq_2_bits_uop_vpu_specVlmul;
  logic            io_enq_2_bits_uop_vpu_vm;
  logic [7:0]      io_enq_2_bits_uop_vpu_vstart;
  logic [2:0]      io_enq_2_bits_uop_vpu_frm;
  logic            io_enq_2_bits_uop_vpu_fpu_isFpToVecInst;
  logic            io_enq_2_bits_uop_vpu_fpu_isFP32Instr;
  logic            io_enq_2_bits_uop_vpu_fpu_isFP64Instr;
  logic            io_enq_2_bits_uop_vpu_fpu_isReduction;
  logic            io_enq_2_bits_uop_vpu_fpu_isFoldTo1_2;
  logic            io_enq_2_bits_uop_vpu_fpu_isFoldTo1_4;
  logic            io_enq_2_bits_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0]      io_enq_2_bits_uop_vpu_vxrm;
  logic [6:0]      io_enq_2_bits_uop_vpu_vuopIdx;
  logic            io_enq_2_bits_uop_vpu_lastUop;
  logic [127:0]    io_enq_2_bits_uop_vpu_vmask;
  logic [7:0]      io_enq_2_bits_uop_vpu_vl;
  logic [2:0]      io_enq_2_bits_uop_vpu_nf;
  logic [1:0]      io_enq_2_bits_uop_vpu_veew;
  logic            io_enq_2_bits_uop_vpu_isReverse;
  logic            io_enq_2_bits_uop_vpu_isExt;
  logic            io_enq_2_bits_uop_vpu_isNarrow;
  logic            io_enq_2_bits_uop_vpu_isDstMask;
  logic            io_enq_2_bits_uop_vpu_isOpMask;
  logic            io_enq_2_bits_uop_vpu_isMove;
  logic            io_enq_2_bits_uop_vpu_isDependOldVd;
  logic            io_enq_2_bits_uop_vpu_isWritePartVd;
  logic            io_enq_2_bits_uop_vpu_isVleff;
  logic            io_enq_2_bits_uop_vlsInstr;
  logic            io_enq_2_bits_uop_wfflags;
  logic            io_enq_2_bits_uop_isMove;
  logic            io_enq_2_bits_uop_isDropAmocasSta;
  logic [6:0]      io_enq_2_bits_uop_uopIdx;
  logic            io_enq_2_bits_uop_isVset;
  logic            io_enq_2_bits_uop_firstUop;
  logic            io_enq_2_bits_uop_lastUop;
  logic [6:0]      io_enq_2_bits_uop_numUops;
  logic [6:0]      io_enq_2_bits_uop_numWB;
  logic [2:0]      io_enq_2_bits_uop_commitType;
  logic            io_enq_2_bits_uop_srcState_0;
  logic            io_enq_2_bits_uop_srcState_1;
  logic            io_enq_2_bits_uop_srcState_2;
  logic            io_enq_2_bits_uop_srcState_3;
  logic            io_enq_2_bits_uop_srcState_4;
  logic [1:0]      io_enq_2_bits_uop_srcLoadDependency_0_0;
  logic [1:0]      io_enq_2_bits_uop_srcLoadDependency_0_1;
  logic [1:0]      io_enq_2_bits_uop_srcLoadDependency_0_2;
  logic [1:0]      io_enq_2_bits_uop_srcLoadDependency_1_0;
  logic [1:0]      io_enq_2_bits_uop_srcLoadDependency_1_1;
  logic [1:0]      io_enq_2_bits_uop_srcLoadDependency_1_2;
  logic [1:0]      io_enq_2_bits_uop_srcLoadDependency_2_0;
  logic [1:0]      io_enq_2_bits_uop_srcLoadDependency_2_1;
  logic [1:0]      io_enq_2_bits_uop_srcLoadDependency_2_2;
  logic [1:0]      io_enq_2_bits_uop_srcLoadDependency_3_0;
  logic [1:0]      io_enq_2_bits_uop_srcLoadDependency_3_1;
  logic [1:0]      io_enq_2_bits_uop_srcLoadDependency_3_2;
  logic [1:0]      io_enq_2_bits_uop_srcLoadDependency_4_0;
  logic [1:0]      io_enq_2_bits_uop_srcLoadDependency_4_1;
  logic [1:0]      io_enq_2_bits_uop_srcLoadDependency_4_2;
  logic [7:0]      io_enq_2_bits_uop_psrc_0;
  logic [7:0]      io_enq_2_bits_uop_psrc_1;
  logic [7:0]      io_enq_2_bits_uop_psrc_2;
  logic [7:0]      io_enq_2_bits_uop_psrc_3;
  logic [7:0]      io_enq_2_bits_uop_psrc_4;
  logic [7:0]      io_enq_2_bits_uop_pdest;
  logic            io_enq_2_bits_uop_useRegCache_0;
  logic            io_enq_2_bits_uop_useRegCache_1;
  logic [4:0]      io_enq_2_bits_uop_regCacheIdx_0;
  logic [4:0]      io_enq_2_bits_uop_regCacheIdx_1;
  logic            io_enq_2_bits_uop_robIdx_flag;
  logic [7:0]      io_enq_2_bits_uop_robIdx_value;
  logic [2:0]      io_enq_2_bits_uop_instrSize;
  logic            io_enq_2_bits_uop_dirtyFs;
  logic            io_enq_2_bits_uop_dirtyVs;
  logic [3:0]      io_enq_2_bits_uop_traceBlockInPipe_itype;
  logic [3:0]      io_enq_2_bits_uop_traceBlockInPipe_iretire;
  logic            io_enq_2_bits_uop_traceBlockInPipe_ilastsize;
  logic            io_enq_2_bits_uop_eliminatedMove;
  logic            io_enq_2_bits_uop_snapshot;
  logic            io_enq_2_bits_uop_debugInfo_eliminatedMove;
  logic [63:0]     io_enq_2_bits_uop_debugInfo_renameTime;
  logic [63:0]     io_enq_2_bits_uop_debugInfo_dispatchTime;
  logic [63:0]     io_enq_2_bits_uop_debugInfo_enqRsTime;
  logic [63:0]     io_enq_2_bits_uop_debugInfo_selectTime;
  logic [63:0]     io_enq_2_bits_uop_debugInfo_issueTime;
  logic [63:0]     io_enq_2_bits_uop_debugInfo_writebackTime;
  logic [63:0]     io_enq_2_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]     io_enq_2_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]     io_enq_2_bits_uop_debugInfo_tlbRespTime;
  logic [55:0]     io_enq_2_bits_uop_debug_seqNum_seqNum;
  logic [7:0]      io_enq_2_bits_uop_debug_seqNum_uopIdx;
  logic            io_enq_2_bits_uop_storeSetHit;
  logic            io_enq_2_bits_uop_waitForRobIdx_flag;
  logic [7:0]      io_enq_2_bits_uop_waitForRobIdx_value;
  logic            io_enq_2_bits_uop_loadWaitBit;
  logic            io_enq_2_bits_uop_loadWaitStrict;
  logic [4:0]      io_enq_2_bits_uop_ssid;
  logic            io_enq_2_bits_uop_lqIdx_flag;
  logic [6:0]      io_enq_2_bits_uop_lqIdx_value;
  logic            io_enq_2_bits_uop_sqIdx_flag;
  logic [5:0]      io_enq_2_bits_uop_sqIdx_value;
  logic            io_enq_2_bits_uop_singleStep;
  logic [34:0]     io_enq_2_bits_uop_debug_fuType;
  logic            io_enq_2_bits_uop_debug_sim_trig;
  logic [4:0]      io_enq_2_bits_uop_numLsElem;
  logic [49:0]     io_enq_2_bits_vaddr;
  logic [15:0]     io_enq_2_bits_mask;
  logic            io_enq_2_bits_isvec;
  logic            io_enq_2_bits_is128bit;
  logic [7:0]      io_enq_2_bits_elemIdx;
  logic [2:0]      io_enq_2_bits_alignedType;
  logic [3:0]      io_enq_2_bits_mbIndex;
  logic [3:0]      io_enq_2_bits_reg_offset;
  logic [7:0]      io_enq_2_bits_elemIdxInsideVd;
  logic            io_enq_2_bits_vecActive;
  logic            io_enq_2_bits_isLoadReplay;
  logic            io_enq_2_bits_handledByMSHR;
  logic [6:0]      io_enq_2_bits_schedIndex;
  logic [3:0]      io_enq_2_bits_rep_info_mshr_id;
  logic            io_enq_2_bits_rep_info_full_fwd;
  logic            io_enq_2_bits_rep_info_data_inv_sq_idx_flag;
  logic [5:0]      io_enq_2_bits_rep_info_data_inv_sq_idx_value;
  logic            io_enq_2_bits_rep_info_addr_inv_sq_idx_flag;
  logic [5:0]      io_enq_2_bits_rep_info_addr_inv_sq_idx_value;
  logic            io_enq_2_bits_rep_info_last_beat;
  logic            io_enq_2_bits_rep_info_cause_0;
  logic            io_enq_2_bits_rep_info_cause_1;
  logic            io_enq_2_bits_rep_info_cause_2;
  logic            io_enq_2_bits_rep_info_cause_3;
  logic            io_enq_2_bits_rep_info_cause_4;
  logic            io_enq_2_bits_rep_info_cause_5;
  logic            io_enq_2_bits_rep_info_cause_6;
  logic            io_enq_2_bits_rep_info_cause_7;
  logic            io_enq_2_bits_rep_info_cause_8;
  logic            io_enq_2_bits_rep_info_cause_9;
  logic            io_enq_2_bits_rep_info_cause_10;
  logic [3:0]      io_enq_2_bits_rep_info_tlb_id;
  logic            io_enq_2_bits_rep_info_tlb_full;
  logic            io_storeAddrIn_0_valid;
  logic            io_storeAddrIn_0_bits_uop_sqIdx_flag;
  logic [5:0]      io_storeAddrIn_0_bits_uop_sqIdx_value;
  logic            io_storeAddrIn_0_bits_miss;
  logic            io_storeAddrIn_1_valid;
  logic            io_storeAddrIn_1_bits_uop_sqIdx_flag;
  logic [5:0]      io_storeAddrIn_1_bits_uop_sqIdx_value;
  logic            io_storeAddrIn_1_bits_miss;
  logic            io_storeDataIn_0_valid;
  logic            io_storeDataIn_0_bits_uop_sqIdx_flag;
  logic [5:0]      io_storeDataIn_0_bits_uop_sqIdx_value;
  logic            io_storeDataIn_1_valid;
  logic            io_storeDataIn_1_bits_uop_sqIdx_flag;
  logic [5:0]      io_storeDataIn_1_bits_uop_sqIdx_value;
  logic            io_replay_0_ready;
  logic            io_replay_1_ready;
  logic            io_replay_2_ready;
  logic            io_tl_d_channel_valid;
  logic [3:0]      io_tl_d_channel_mshrid;
  logic            io_stAddrReadySqPtr_flag;
  logic [5:0]      io_stAddrReadySqPtr_value;
  logic            io_stAddrReadyVec_0;
  logic            io_stAddrReadyVec_1;
  logic            io_stAddrReadyVec_2;
  logic            io_stAddrReadyVec_3;
  logic            io_stAddrReadyVec_4;
  logic            io_stAddrReadyVec_5;
  logic            io_stAddrReadyVec_6;
  logic            io_stAddrReadyVec_7;
  logic            io_stAddrReadyVec_8;
  logic            io_stAddrReadyVec_9;
  logic            io_stAddrReadyVec_10;
  logic            io_stAddrReadyVec_11;
  logic            io_stAddrReadyVec_12;
  logic            io_stAddrReadyVec_13;
  logic            io_stAddrReadyVec_14;
  logic            io_stAddrReadyVec_15;
  logic            io_stAddrReadyVec_16;
  logic            io_stAddrReadyVec_17;
  logic            io_stAddrReadyVec_18;
  logic            io_stAddrReadyVec_19;
  logic            io_stAddrReadyVec_20;
  logic            io_stAddrReadyVec_21;
  logic            io_stAddrReadyVec_22;
  logic            io_stAddrReadyVec_23;
  logic            io_stAddrReadyVec_24;
  logic            io_stAddrReadyVec_25;
  logic            io_stAddrReadyVec_26;
  logic            io_stAddrReadyVec_27;
  logic            io_stAddrReadyVec_28;
  logic            io_stAddrReadyVec_29;
  logic            io_stAddrReadyVec_30;
  logic            io_stAddrReadyVec_31;
  logic            io_stAddrReadyVec_32;
  logic            io_stAddrReadyVec_33;
  logic            io_stAddrReadyVec_34;
  logic            io_stAddrReadyVec_35;
  logic            io_stAddrReadyVec_36;
  logic            io_stAddrReadyVec_37;
  logic            io_stAddrReadyVec_38;
  logic            io_stAddrReadyVec_39;
  logic            io_stAddrReadyVec_40;
  logic            io_stAddrReadyVec_41;
  logic            io_stAddrReadyVec_42;
  logic            io_stAddrReadyVec_43;
  logic            io_stAddrReadyVec_44;
  logic            io_stAddrReadyVec_45;
  logic            io_stAddrReadyVec_46;
  logic            io_stAddrReadyVec_47;
  logic            io_stAddrReadyVec_48;
  logic            io_stAddrReadyVec_49;
  logic            io_stAddrReadyVec_50;
  logic            io_stAddrReadyVec_51;
  logic            io_stAddrReadyVec_52;
  logic            io_stAddrReadyVec_53;
  logic            io_stAddrReadyVec_54;
  logic            io_stAddrReadyVec_55;
  logic            io_stDataReadySqPtr_flag;
  logic [5:0]      io_stDataReadySqPtr_value;
  logic            io_stDataReadyVec_0;
  logic            io_stDataReadyVec_1;
  logic            io_stDataReadyVec_2;
  logic            io_stDataReadyVec_3;
  logic            io_stDataReadyVec_4;
  logic            io_stDataReadyVec_5;
  logic            io_stDataReadyVec_6;
  logic            io_stDataReadyVec_7;
  logic            io_stDataReadyVec_8;
  logic            io_stDataReadyVec_9;
  logic            io_stDataReadyVec_10;
  logic            io_stDataReadyVec_11;
  logic            io_stDataReadyVec_12;
  logic            io_stDataReadyVec_13;
  logic            io_stDataReadyVec_14;
  logic            io_stDataReadyVec_15;
  logic            io_stDataReadyVec_16;
  logic            io_stDataReadyVec_17;
  logic            io_stDataReadyVec_18;
  logic            io_stDataReadyVec_19;
  logic            io_stDataReadyVec_20;
  logic            io_stDataReadyVec_21;
  logic            io_stDataReadyVec_22;
  logic            io_stDataReadyVec_23;
  logic            io_stDataReadyVec_24;
  logic            io_stDataReadyVec_25;
  logic            io_stDataReadyVec_26;
  logic            io_stDataReadyVec_27;
  logic            io_stDataReadyVec_28;
  logic            io_stDataReadyVec_29;
  logic            io_stDataReadyVec_30;
  logic            io_stDataReadyVec_31;
  logic            io_stDataReadyVec_32;
  logic            io_stDataReadyVec_33;
  logic            io_stDataReadyVec_34;
  logic            io_stDataReadyVec_35;
  logic            io_stDataReadyVec_36;
  logic            io_stDataReadyVec_37;
  logic            io_stDataReadyVec_38;
  logic            io_stDataReadyVec_39;
  logic            io_stDataReadyVec_40;
  logic            io_stDataReadyVec_41;
  logic            io_stDataReadyVec_42;
  logic            io_stDataReadyVec_43;
  logic            io_stDataReadyVec_44;
  logic            io_stDataReadyVec_45;
  logic            io_stDataReadyVec_46;
  logic            io_stDataReadyVec_47;
  logic            io_stDataReadyVec_48;
  logic            io_stDataReadyVec_49;
  logic            io_stDataReadyVec_50;
  logic            io_stDataReadyVec_51;
  logic            io_stDataReadyVec_52;
  logic            io_stDataReadyVec_53;
  logic            io_stDataReadyVec_54;
  logic            io_stDataReadyVec_55;
  logic            io_sqEmpty;
  logic            io_ldWbPtr_flag;
  logic [6:0]      io_ldWbPtr_value;
  logic            io_robDeqPtr_flag;
  logic [7:0]      io_robDeqPtr_value;
  logic            io_rarFull;
  logic            io_rawFull;
  logic            io_l2_hint_valid;
  logic [3:0]      io_l2_hint_bits_sourceId;
  logic            io_l2_hint_bits_isKeyword;
  logic            io_tlb_hint_resp_valid;
  logic [3:0]      io_tlb_hint_resp_bits_id;
  logic            io_tlb_hint_resp_bits_replay_all;
  logic            io_debugTopDown_robHeadVaddr_valid;
  logic [49:0]     io_debugTopDown_robHeadVaddr_bits;
  logic            io_debugTopDown_robHeadMissInDTlb;

  // ---- 便于按数组驱动的中间量（下面 assign 散到扁平端口）----
  logic [55:0] st_addr_rdy, st_data_rdy;
  logic [1:0]  sta_v, sta_f, sta_m, std_v, std_f;
  logic [1:0][5:0] sta_i, std_i;
  logic [1:0]  vfb_v, vfb_f, vfb_c, vfb_l;
  logic [1:0][7:0] vfb_r;
  logic [1:0][6:0] vfb_u;
  logic [2:0]  rep_rdy;
  assign io_stAddrReadyVec_0 = st_addr_rdy[0];
  assign io_stDataReadyVec_0 = st_data_rdy[0];
  assign io_stAddrReadyVec_1 = st_addr_rdy[1];
  assign io_stDataReadyVec_1 = st_data_rdy[1];
  assign io_stAddrReadyVec_2 = st_addr_rdy[2];
  assign io_stDataReadyVec_2 = st_data_rdy[2];
  assign io_stAddrReadyVec_3 = st_addr_rdy[3];
  assign io_stDataReadyVec_3 = st_data_rdy[3];
  assign io_stAddrReadyVec_4 = st_addr_rdy[4];
  assign io_stDataReadyVec_4 = st_data_rdy[4];
  assign io_stAddrReadyVec_5 = st_addr_rdy[5];
  assign io_stDataReadyVec_5 = st_data_rdy[5];
  assign io_stAddrReadyVec_6 = st_addr_rdy[6];
  assign io_stDataReadyVec_6 = st_data_rdy[6];
  assign io_stAddrReadyVec_7 = st_addr_rdy[7];
  assign io_stDataReadyVec_7 = st_data_rdy[7];
  assign io_stAddrReadyVec_8 = st_addr_rdy[8];
  assign io_stDataReadyVec_8 = st_data_rdy[8];
  assign io_stAddrReadyVec_9 = st_addr_rdy[9];
  assign io_stDataReadyVec_9 = st_data_rdy[9];
  assign io_stAddrReadyVec_10 = st_addr_rdy[10];
  assign io_stDataReadyVec_10 = st_data_rdy[10];
  assign io_stAddrReadyVec_11 = st_addr_rdy[11];
  assign io_stDataReadyVec_11 = st_data_rdy[11];
  assign io_stAddrReadyVec_12 = st_addr_rdy[12];
  assign io_stDataReadyVec_12 = st_data_rdy[12];
  assign io_stAddrReadyVec_13 = st_addr_rdy[13];
  assign io_stDataReadyVec_13 = st_data_rdy[13];
  assign io_stAddrReadyVec_14 = st_addr_rdy[14];
  assign io_stDataReadyVec_14 = st_data_rdy[14];
  assign io_stAddrReadyVec_15 = st_addr_rdy[15];
  assign io_stDataReadyVec_15 = st_data_rdy[15];
  assign io_stAddrReadyVec_16 = st_addr_rdy[16];
  assign io_stDataReadyVec_16 = st_data_rdy[16];
  assign io_stAddrReadyVec_17 = st_addr_rdy[17];
  assign io_stDataReadyVec_17 = st_data_rdy[17];
  assign io_stAddrReadyVec_18 = st_addr_rdy[18];
  assign io_stDataReadyVec_18 = st_data_rdy[18];
  assign io_stAddrReadyVec_19 = st_addr_rdy[19];
  assign io_stDataReadyVec_19 = st_data_rdy[19];
  assign io_stAddrReadyVec_20 = st_addr_rdy[20];
  assign io_stDataReadyVec_20 = st_data_rdy[20];
  assign io_stAddrReadyVec_21 = st_addr_rdy[21];
  assign io_stDataReadyVec_21 = st_data_rdy[21];
  assign io_stAddrReadyVec_22 = st_addr_rdy[22];
  assign io_stDataReadyVec_22 = st_data_rdy[22];
  assign io_stAddrReadyVec_23 = st_addr_rdy[23];
  assign io_stDataReadyVec_23 = st_data_rdy[23];
  assign io_stAddrReadyVec_24 = st_addr_rdy[24];
  assign io_stDataReadyVec_24 = st_data_rdy[24];
  assign io_stAddrReadyVec_25 = st_addr_rdy[25];
  assign io_stDataReadyVec_25 = st_data_rdy[25];
  assign io_stAddrReadyVec_26 = st_addr_rdy[26];
  assign io_stDataReadyVec_26 = st_data_rdy[26];
  assign io_stAddrReadyVec_27 = st_addr_rdy[27];
  assign io_stDataReadyVec_27 = st_data_rdy[27];
  assign io_stAddrReadyVec_28 = st_addr_rdy[28];
  assign io_stDataReadyVec_28 = st_data_rdy[28];
  assign io_stAddrReadyVec_29 = st_addr_rdy[29];
  assign io_stDataReadyVec_29 = st_data_rdy[29];
  assign io_stAddrReadyVec_30 = st_addr_rdy[30];
  assign io_stDataReadyVec_30 = st_data_rdy[30];
  assign io_stAddrReadyVec_31 = st_addr_rdy[31];
  assign io_stDataReadyVec_31 = st_data_rdy[31];
  assign io_stAddrReadyVec_32 = st_addr_rdy[32];
  assign io_stDataReadyVec_32 = st_data_rdy[32];
  assign io_stAddrReadyVec_33 = st_addr_rdy[33];
  assign io_stDataReadyVec_33 = st_data_rdy[33];
  assign io_stAddrReadyVec_34 = st_addr_rdy[34];
  assign io_stDataReadyVec_34 = st_data_rdy[34];
  assign io_stAddrReadyVec_35 = st_addr_rdy[35];
  assign io_stDataReadyVec_35 = st_data_rdy[35];
  assign io_stAddrReadyVec_36 = st_addr_rdy[36];
  assign io_stDataReadyVec_36 = st_data_rdy[36];
  assign io_stAddrReadyVec_37 = st_addr_rdy[37];
  assign io_stDataReadyVec_37 = st_data_rdy[37];
  assign io_stAddrReadyVec_38 = st_addr_rdy[38];
  assign io_stDataReadyVec_38 = st_data_rdy[38];
  assign io_stAddrReadyVec_39 = st_addr_rdy[39];
  assign io_stDataReadyVec_39 = st_data_rdy[39];
  assign io_stAddrReadyVec_40 = st_addr_rdy[40];
  assign io_stDataReadyVec_40 = st_data_rdy[40];
  assign io_stAddrReadyVec_41 = st_addr_rdy[41];
  assign io_stDataReadyVec_41 = st_data_rdy[41];
  assign io_stAddrReadyVec_42 = st_addr_rdy[42];
  assign io_stDataReadyVec_42 = st_data_rdy[42];
  assign io_stAddrReadyVec_43 = st_addr_rdy[43];
  assign io_stDataReadyVec_43 = st_data_rdy[43];
  assign io_stAddrReadyVec_44 = st_addr_rdy[44];
  assign io_stDataReadyVec_44 = st_data_rdy[44];
  assign io_stAddrReadyVec_45 = st_addr_rdy[45];
  assign io_stDataReadyVec_45 = st_data_rdy[45];
  assign io_stAddrReadyVec_46 = st_addr_rdy[46];
  assign io_stDataReadyVec_46 = st_data_rdy[46];
  assign io_stAddrReadyVec_47 = st_addr_rdy[47];
  assign io_stDataReadyVec_47 = st_data_rdy[47];
  assign io_stAddrReadyVec_48 = st_addr_rdy[48];
  assign io_stDataReadyVec_48 = st_data_rdy[48];
  assign io_stAddrReadyVec_49 = st_addr_rdy[49];
  assign io_stDataReadyVec_49 = st_data_rdy[49];
  assign io_stAddrReadyVec_50 = st_addr_rdy[50];
  assign io_stDataReadyVec_50 = st_data_rdy[50];
  assign io_stAddrReadyVec_51 = st_addr_rdy[51];
  assign io_stDataReadyVec_51 = st_data_rdy[51];
  assign io_stAddrReadyVec_52 = st_addr_rdy[52];
  assign io_stDataReadyVec_52 = st_data_rdy[52];
  assign io_stAddrReadyVec_53 = st_addr_rdy[53];
  assign io_stDataReadyVec_53 = st_data_rdy[53];
  assign io_stAddrReadyVec_54 = st_addr_rdy[54];
  assign io_stDataReadyVec_54 = st_data_rdy[54];
  assign io_stAddrReadyVec_55 = st_addr_rdy[55];
  assign io_stDataReadyVec_55 = st_data_rdy[55];
  assign io_storeAddrIn_0_valid = sta_v[0];
  assign io_storeAddrIn_0_bits_uop_sqIdx_flag = sta_f[0];
  assign io_storeAddrIn_0_bits_uop_sqIdx_value = sta_i[0];
  assign io_storeAddrIn_0_bits_miss = sta_m[0];
  assign io_storeDataIn_0_valid = std_v[0];
  assign io_storeDataIn_0_bits_uop_sqIdx_flag = std_f[0];
  assign io_storeDataIn_0_bits_uop_sqIdx_value = std_i[0];
  assign io_vecFeedback_0_valid = vfb_v[0];
  assign io_vecFeedback_0_bits_robidx_flag = vfb_f[0];
  assign io_vecFeedback_0_bits_robidx_value = vfb_r[0];
  assign io_vecFeedback_0_bits_uopidx = vfb_u[0];
  assign io_vecFeedback_0_bits_feedback_0 = vfb_c[0];
  assign io_vecFeedback_0_bits_feedback_1 = vfb_l[0];
  assign io_storeAddrIn_1_valid = sta_v[1];
  assign io_storeAddrIn_1_bits_uop_sqIdx_flag = sta_f[1];
  assign io_storeAddrIn_1_bits_uop_sqIdx_value = sta_i[1];
  assign io_storeAddrIn_1_bits_miss = sta_m[1];
  assign io_storeDataIn_1_valid = std_v[1];
  assign io_storeDataIn_1_bits_uop_sqIdx_flag = std_f[1];
  assign io_storeDataIn_1_bits_uop_sqIdx_value = std_i[1];
  assign io_vecFeedback_1_valid = vfb_v[1];
  assign io_vecFeedback_1_bits_robidx_flag = vfb_f[1];
  assign io_vecFeedback_1_bits_robidx_value = vfb_r[1];
  assign io_vecFeedback_1_bits_uopidx = vfb_u[1];
  assign io_vecFeedback_1_bits_feedback_0 = vfb_c[1];
  assign io_vecFeedback_1_bits_feedback_1 = vfb_l[1];
  assign io_replay_0_ready = rep_rdy[0];
  assign io_replay_1_ready = rep_rdy[1];
  assign io_replay_2_ready = rep_rdy[2];

  // ---- 输出信号：g_=golden, i_=重写件 ----
  logic            g_io_replay_0_valid, i_io_replay_0_valid;
  logic [31:0]     g_io_replay_0_bits_uop_instr, i_io_replay_0_bits_uop_instr;
  logic [49:0]     g_io_replay_0_bits_uop_pc, i_io_replay_0_bits_uop_pc;
  logic [9:0]      g_io_replay_0_bits_uop_foldpc, i_io_replay_0_bits_uop_foldpc;
  logic            g_io_replay_0_bits_uop_exceptionVec_0, i_io_replay_0_bits_uop_exceptionVec_0;
  logic            g_io_replay_0_bits_uop_exceptionVec_1, i_io_replay_0_bits_uop_exceptionVec_1;
  logic            g_io_replay_0_bits_uop_exceptionVec_2, i_io_replay_0_bits_uop_exceptionVec_2;
  logic            g_io_replay_0_bits_uop_exceptionVec_3, i_io_replay_0_bits_uop_exceptionVec_3;
  logic            g_io_replay_0_bits_uop_exceptionVec_5, i_io_replay_0_bits_uop_exceptionVec_5;
  logic            g_io_replay_0_bits_uop_exceptionVec_6, i_io_replay_0_bits_uop_exceptionVec_6;
  logic            g_io_replay_0_bits_uop_exceptionVec_7, i_io_replay_0_bits_uop_exceptionVec_7;
  logic            g_io_replay_0_bits_uop_exceptionVec_8, i_io_replay_0_bits_uop_exceptionVec_8;
  logic            g_io_replay_0_bits_uop_exceptionVec_9, i_io_replay_0_bits_uop_exceptionVec_9;
  logic            g_io_replay_0_bits_uop_exceptionVec_10, i_io_replay_0_bits_uop_exceptionVec_10;
  logic            g_io_replay_0_bits_uop_exceptionVec_11, i_io_replay_0_bits_uop_exceptionVec_11;
  logic            g_io_replay_0_bits_uop_exceptionVec_12, i_io_replay_0_bits_uop_exceptionVec_12;
  logic            g_io_replay_0_bits_uop_exceptionVec_13, i_io_replay_0_bits_uop_exceptionVec_13;
  logic            g_io_replay_0_bits_uop_exceptionVec_14, i_io_replay_0_bits_uop_exceptionVec_14;
  logic            g_io_replay_0_bits_uop_exceptionVec_15, i_io_replay_0_bits_uop_exceptionVec_15;
  logic            g_io_replay_0_bits_uop_exceptionVec_16, i_io_replay_0_bits_uop_exceptionVec_16;
  logic            g_io_replay_0_bits_uop_exceptionVec_17, i_io_replay_0_bits_uop_exceptionVec_17;
  logic            g_io_replay_0_bits_uop_exceptionVec_18, i_io_replay_0_bits_uop_exceptionVec_18;
  logic            g_io_replay_0_bits_uop_exceptionVec_19, i_io_replay_0_bits_uop_exceptionVec_19;
  logic            g_io_replay_0_bits_uop_exceptionVec_20, i_io_replay_0_bits_uop_exceptionVec_20;
  logic            g_io_replay_0_bits_uop_exceptionVec_21, i_io_replay_0_bits_uop_exceptionVec_21;
  logic            g_io_replay_0_bits_uop_exceptionVec_22, i_io_replay_0_bits_uop_exceptionVec_22;
  logic            g_io_replay_0_bits_uop_exceptionVec_23, i_io_replay_0_bits_uop_exceptionVec_23;
  logic            g_io_replay_0_bits_uop_isFetchMalAddr, i_io_replay_0_bits_uop_isFetchMalAddr;
  logic            g_io_replay_0_bits_uop_hasException, i_io_replay_0_bits_uop_hasException;
  logic [3:0]      g_io_replay_0_bits_uop_trigger, i_io_replay_0_bits_uop_trigger;
  logic            g_io_replay_0_bits_uop_preDecodeInfo_valid, i_io_replay_0_bits_uop_preDecodeInfo_valid;
  logic            g_io_replay_0_bits_uop_preDecodeInfo_isRVC, i_io_replay_0_bits_uop_preDecodeInfo_isRVC;
  logic [1:0]      g_io_replay_0_bits_uop_preDecodeInfo_brType, i_io_replay_0_bits_uop_preDecodeInfo_brType;
  logic            g_io_replay_0_bits_uop_preDecodeInfo_isCall, i_io_replay_0_bits_uop_preDecodeInfo_isCall;
  logic            g_io_replay_0_bits_uop_preDecodeInfo_isRet, i_io_replay_0_bits_uop_preDecodeInfo_isRet;
  logic            g_io_replay_0_bits_uop_pred_taken, i_io_replay_0_bits_uop_pred_taken;
  logic            g_io_replay_0_bits_uop_crossPageIPFFix, i_io_replay_0_bits_uop_crossPageIPFFix;
  logic            g_io_replay_0_bits_uop_ftqPtr_flag, i_io_replay_0_bits_uop_ftqPtr_flag;
  logic [5:0]      g_io_replay_0_bits_uop_ftqPtr_value, i_io_replay_0_bits_uop_ftqPtr_value;
  logic [3:0]      g_io_replay_0_bits_uop_ftqOffset, i_io_replay_0_bits_uop_ftqOffset;
  logic            g_io_replay_0_bits_uop_satpFlushFirstFetchFault, i_io_replay_0_bits_uop_satpFlushFirstFetchFault;
  logic [3:0]      g_io_replay_0_bits_uop_srcType_0, i_io_replay_0_bits_uop_srcType_0;
  logic [3:0]      g_io_replay_0_bits_uop_srcType_1, i_io_replay_0_bits_uop_srcType_1;
  logic [3:0]      g_io_replay_0_bits_uop_srcType_2, i_io_replay_0_bits_uop_srcType_2;
  logic [3:0]      g_io_replay_0_bits_uop_srcType_3, i_io_replay_0_bits_uop_srcType_3;
  logic [3:0]      g_io_replay_0_bits_uop_srcType_4, i_io_replay_0_bits_uop_srcType_4;
  logic [5:0]      g_io_replay_0_bits_uop_ldest, i_io_replay_0_bits_uop_ldest;
  logic [34:0]     g_io_replay_0_bits_uop_fuType, i_io_replay_0_bits_uop_fuType;
  logic [8:0]      g_io_replay_0_bits_uop_fuOpType, i_io_replay_0_bits_uop_fuOpType;
  logic            g_io_replay_0_bits_uop_rfWen, i_io_replay_0_bits_uop_rfWen;
  logic            g_io_replay_0_bits_uop_fpWen, i_io_replay_0_bits_uop_fpWen;
  logic            g_io_replay_0_bits_uop_vecWen, i_io_replay_0_bits_uop_vecWen;
  logic            g_io_replay_0_bits_uop_v0Wen, i_io_replay_0_bits_uop_v0Wen;
  logic            g_io_replay_0_bits_uop_vlWen, i_io_replay_0_bits_uop_vlWen;
  logic            g_io_replay_0_bits_uop_isXSTrap, i_io_replay_0_bits_uop_isXSTrap;
  logic            g_io_replay_0_bits_uop_waitForward, i_io_replay_0_bits_uop_waitForward;
  logic            g_io_replay_0_bits_uop_blockBackward, i_io_replay_0_bits_uop_blockBackward;
  logic            g_io_replay_0_bits_uop_canRobCompress, i_io_replay_0_bits_uop_canRobCompress;
  logic [3:0]      g_io_replay_0_bits_uop_selImm, i_io_replay_0_bits_uop_selImm;
  logic [31:0]     g_io_replay_0_bits_uop_imm, i_io_replay_0_bits_uop_imm;
  logic [1:0]      g_io_replay_0_bits_uop_fpu_typeTagOut, i_io_replay_0_bits_uop_fpu_typeTagOut;
  logic            g_io_replay_0_bits_uop_fpu_wflags, i_io_replay_0_bits_uop_fpu_wflags;
  logic [1:0]      g_io_replay_0_bits_uop_fpu_typ, i_io_replay_0_bits_uop_fpu_typ;
  logic [1:0]      g_io_replay_0_bits_uop_fpu_fmt, i_io_replay_0_bits_uop_fpu_fmt;
  logic [2:0]      g_io_replay_0_bits_uop_fpu_rm, i_io_replay_0_bits_uop_fpu_rm;
  logic            g_io_replay_0_bits_uop_vpu_vill, i_io_replay_0_bits_uop_vpu_vill;
  logic            g_io_replay_0_bits_uop_vpu_vma, i_io_replay_0_bits_uop_vpu_vma;
  logic            g_io_replay_0_bits_uop_vpu_vta, i_io_replay_0_bits_uop_vpu_vta;
  logic [1:0]      g_io_replay_0_bits_uop_vpu_vsew, i_io_replay_0_bits_uop_vpu_vsew;
  logic [2:0]      g_io_replay_0_bits_uop_vpu_vlmul, i_io_replay_0_bits_uop_vpu_vlmul;
  logic            g_io_replay_0_bits_uop_vpu_specVill, i_io_replay_0_bits_uop_vpu_specVill;
  logic            g_io_replay_0_bits_uop_vpu_specVma, i_io_replay_0_bits_uop_vpu_specVma;
  logic            g_io_replay_0_bits_uop_vpu_specVta, i_io_replay_0_bits_uop_vpu_specVta;
  logic [1:0]      g_io_replay_0_bits_uop_vpu_specVsew, i_io_replay_0_bits_uop_vpu_specVsew;
  logic [2:0]      g_io_replay_0_bits_uop_vpu_specVlmul, i_io_replay_0_bits_uop_vpu_specVlmul;
  logic            g_io_replay_0_bits_uop_vpu_vm, i_io_replay_0_bits_uop_vpu_vm;
  logic [7:0]      g_io_replay_0_bits_uop_vpu_vstart, i_io_replay_0_bits_uop_vpu_vstart;
  logic [2:0]      g_io_replay_0_bits_uop_vpu_frm, i_io_replay_0_bits_uop_vpu_frm;
  logic            g_io_replay_0_bits_uop_vpu_fpu_isFpToVecInst, i_io_replay_0_bits_uop_vpu_fpu_isFpToVecInst;
  logic            g_io_replay_0_bits_uop_vpu_fpu_isFP32Instr, i_io_replay_0_bits_uop_vpu_fpu_isFP32Instr;
  logic            g_io_replay_0_bits_uop_vpu_fpu_isFP64Instr, i_io_replay_0_bits_uop_vpu_fpu_isFP64Instr;
  logic            g_io_replay_0_bits_uop_vpu_fpu_isReduction, i_io_replay_0_bits_uop_vpu_fpu_isReduction;
  logic            g_io_replay_0_bits_uop_vpu_fpu_isFoldTo1_2, i_io_replay_0_bits_uop_vpu_fpu_isFoldTo1_2;
  logic            g_io_replay_0_bits_uop_vpu_fpu_isFoldTo1_4, i_io_replay_0_bits_uop_vpu_fpu_isFoldTo1_4;
  logic            g_io_replay_0_bits_uop_vpu_fpu_isFoldTo1_8, i_io_replay_0_bits_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0]      g_io_replay_0_bits_uop_vpu_vxrm, i_io_replay_0_bits_uop_vpu_vxrm;
  logic [6:0]      g_io_replay_0_bits_uop_vpu_vuopIdx, i_io_replay_0_bits_uop_vpu_vuopIdx;
  logic            g_io_replay_0_bits_uop_vpu_lastUop, i_io_replay_0_bits_uop_vpu_lastUop;
  logic [127:0]    g_io_replay_0_bits_uop_vpu_vmask, i_io_replay_0_bits_uop_vpu_vmask;
  logic [7:0]      g_io_replay_0_bits_uop_vpu_vl, i_io_replay_0_bits_uop_vpu_vl;
  logic [2:0]      g_io_replay_0_bits_uop_vpu_nf, i_io_replay_0_bits_uop_vpu_nf;
  logic [1:0]      g_io_replay_0_bits_uop_vpu_veew, i_io_replay_0_bits_uop_vpu_veew;
  logic            g_io_replay_0_bits_uop_vpu_isReverse, i_io_replay_0_bits_uop_vpu_isReverse;
  logic            g_io_replay_0_bits_uop_vpu_isExt, i_io_replay_0_bits_uop_vpu_isExt;
  logic            g_io_replay_0_bits_uop_vpu_isNarrow, i_io_replay_0_bits_uop_vpu_isNarrow;
  logic            g_io_replay_0_bits_uop_vpu_isDstMask, i_io_replay_0_bits_uop_vpu_isDstMask;
  logic            g_io_replay_0_bits_uop_vpu_isOpMask, i_io_replay_0_bits_uop_vpu_isOpMask;
  logic            g_io_replay_0_bits_uop_vpu_isMove, i_io_replay_0_bits_uop_vpu_isMove;
  logic            g_io_replay_0_bits_uop_vpu_isDependOldVd, i_io_replay_0_bits_uop_vpu_isDependOldVd;
  logic            g_io_replay_0_bits_uop_vpu_isWritePartVd, i_io_replay_0_bits_uop_vpu_isWritePartVd;
  logic            g_io_replay_0_bits_uop_vpu_isVleff, i_io_replay_0_bits_uop_vpu_isVleff;
  logic            g_io_replay_0_bits_uop_vlsInstr, i_io_replay_0_bits_uop_vlsInstr;
  logic            g_io_replay_0_bits_uop_wfflags, i_io_replay_0_bits_uop_wfflags;
  logic            g_io_replay_0_bits_uop_isMove, i_io_replay_0_bits_uop_isMove;
  logic            g_io_replay_0_bits_uop_isDropAmocasSta, i_io_replay_0_bits_uop_isDropAmocasSta;
  logic [6:0]      g_io_replay_0_bits_uop_uopIdx, i_io_replay_0_bits_uop_uopIdx;
  logic            g_io_replay_0_bits_uop_isVset, i_io_replay_0_bits_uop_isVset;
  logic            g_io_replay_0_bits_uop_firstUop, i_io_replay_0_bits_uop_firstUop;
  logic            g_io_replay_0_bits_uop_lastUop, i_io_replay_0_bits_uop_lastUop;
  logic [6:0]      g_io_replay_0_bits_uop_numUops, i_io_replay_0_bits_uop_numUops;
  logic [6:0]      g_io_replay_0_bits_uop_numWB, i_io_replay_0_bits_uop_numWB;
  logic [2:0]      g_io_replay_0_bits_uop_commitType, i_io_replay_0_bits_uop_commitType;
  logic            g_io_replay_0_bits_uop_srcState_0, i_io_replay_0_bits_uop_srcState_0;
  logic            g_io_replay_0_bits_uop_srcState_1, i_io_replay_0_bits_uop_srcState_1;
  logic            g_io_replay_0_bits_uop_srcState_2, i_io_replay_0_bits_uop_srcState_2;
  logic            g_io_replay_0_bits_uop_srcState_3, i_io_replay_0_bits_uop_srcState_3;
  logic            g_io_replay_0_bits_uop_srcState_4, i_io_replay_0_bits_uop_srcState_4;
  logic [1:0]      g_io_replay_0_bits_uop_srcLoadDependency_0_0, i_io_replay_0_bits_uop_srcLoadDependency_0_0;
  logic [1:0]      g_io_replay_0_bits_uop_srcLoadDependency_0_1, i_io_replay_0_bits_uop_srcLoadDependency_0_1;
  logic [1:0]      g_io_replay_0_bits_uop_srcLoadDependency_0_2, i_io_replay_0_bits_uop_srcLoadDependency_0_2;
  logic [1:0]      g_io_replay_0_bits_uop_srcLoadDependency_1_0, i_io_replay_0_bits_uop_srcLoadDependency_1_0;
  logic [1:0]      g_io_replay_0_bits_uop_srcLoadDependency_1_1, i_io_replay_0_bits_uop_srcLoadDependency_1_1;
  logic [1:0]      g_io_replay_0_bits_uop_srcLoadDependency_1_2, i_io_replay_0_bits_uop_srcLoadDependency_1_2;
  logic [1:0]      g_io_replay_0_bits_uop_srcLoadDependency_2_0, i_io_replay_0_bits_uop_srcLoadDependency_2_0;
  logic [1:0]      g_io_replay_0_bits_uop_srcLoadDependency_2_1, i_io_replay_0_bits_uop_srcLoadDependency_2_1;
  logic [1:0]      g_io_replay_0_bits_uop_srcLoadDependency_2_2, i_io_replay_0_bits_uop_srcLoadDependency_2_2;
  logic [1:0]      g_io_replay_0_bits_uop_srcLoadDependency_3_0, i_io_replay_0_bits_uop_srcLoadDependency_3_0;
  logic [1:0]      g_io_replay_0_bits_uop_srcLoadDependency_3_1, i_io_replay_0_bits_uop_srcLoadDependency_3_1;
  logic [1:0]      g_io_replay_0_bits_uop_srcLoadDependency_3_2, i_io_replay_0_bits_uop_srcLoadDependency_3_2;
  logic [1:0]      g_io_replay_0_bits_uop_srcLoadDependency_4_0, i_io_replay_0_bits_uop_srcLoadDependency_4_0;
  logic [1:0]      g_io_replay_0_bits_uop_srcLoadDependency_4_1, i_io_replay_0_bits_uop_srcLoadDependency_4_1;
  logic [1:0]      g_io_replay_0_bits_uop_srcLoadDependency_4_2, i_io_replay_0_bits_uop_srcLoadDependency_4_2;
  logic [7:0]      g_io_replay_0_bits_uop_psrc_0, i_io_replay_0_bits_uop_psrc_0;
  logic [7:0]      g_io_replay_0_bits_uop_psrc_1, i_io_replay_0_bits_uop_psrc_1;
  logic [7:0]      g_io_replay_0_bits_uop_psrc_2, i_io_replay_0_bits_uop_psrc_2;
  logic [7:0]      g_io_replay_0_bits_uop_psrc_3, i_io_replay_0_bits_uop_psrc_3;
  logic [7:0]      g_io_replay_0_bits_uop_psrc_4, i_io_replay_0_bits_uop_psrc_4;
  logic [7:0]      g_io_replay_0_bits_uop_pdest, i_io_replay_0_bits_uop_pdest;
  logic            g_io_replay_0_bits_uop_useRegCache_0, i_io_replay_0_bits_uop_useRegCache_0;
  logic            g_io_replay_0_bits_uop_useRegCache_1, i_io_replay_0_bits_uop_useRegCache_1;
  logic [4:0]      g_io_replay_0_bits_uop_regCacheIdx_0, i_io_replay_0_bits_uop_regCacheIdx_0;
  logic [4:0]      g_io_replay_0_bits_uop_regCacheIdx_1, i_io_replay_0_bits_uop_regCacheIdx_1;
  logic            g_io_replay_0_bits_uop_robIdx_flag, i_io_replay_0_bits_uop_robIdx_flag;
  logic [7:0]      g_io_replay_0_bits_uop_robIdx_value, i_io_replay_0_bits_uop_robIdx_value;
  logic [2:0]      g_io_replay_0_bits_uop_instrSize, i_io_replay_0_bits_uop_instrSize;
  logic            g_io_replay_0_bits_uop_dirtyFs, i_io_replay_0_bits_uop_dirtyFs;
  logic            g_io_replay_0_bits_uop_dirtyVs, i_io_replay_0_bits_uop_dirtyVs;
  logic [3:0]      g_io_replay_0_bits_uop_traceBlockInPipe_itype, i_io_replay_0_bits_uop_traceBlockInPipe_itype;
  logic [3:0]      g_io_replay_0_bits_uop_traceBlockInPipe_iretire, i_io_replay_0_bits_uop_traceBlockInPipe_iretire;
  logic            g_io_replay_0_bits_uop_traceBlockInPipe_ilastsize, i_io_replay_0_bits_uop_traceBlockInPipe_ilastsize;
  logic            g_io_replay_0_bits_uop_eliminatedMove, i_io_replay_0_bits_uop_eliminatedMove;
  logic            g_io_replay_0_bits_uop_snapshot, i_io_replay_0_bits_uop_snapshot;
  logic            g_io_replay_0_bits_uop_debugInfo_eliminatedMove, i_io_replay_0_bits_uop_debugInfo_eliminatedMove;
  logic [63:0]     g_io_replay_0_bits_uop_debugInfo_renameTime, i_io_replay_0_bits_uop_debugInfo_renameTime;
  logic [63:0]     g_io_replay_0_bits_uop_debugInfo_dispatchTime, i_io_replay_0_bits_uop_debugInfo_dispatchTime;
  logic [63:0]     g_io_replay_0_bits_uop_debugInfo_enqRsTime, i_io_replay_0_bits_uop_debugInfo_enqRsTime;
  logic [63:0]     g_io_replay_0_bits_uop_debugInfo_selectTime, i_io_replay_0_bits_uop_debugInfo_selectTime;
  logic [63:0]     g_io_replay_0_bits_uop_debugInfo_issueTime, i_io_replay_0_bits_uop_debugInfo_issueTime;
  logic [63:0]     g_io_replay_0_bits_uop_debugInfo_writebackTime, i_io_replay_0_bits_uop_debugInfo_writebackTime;
  logic [63:0]     g_io_replay_0_bits_uop_debugInfo_runahead_checkpoint_id, i_io_replay_0_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]     g_io_replay_0_bits_uop_debugInfo_tlbFirstReqTime, i_io_replay_0_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]     g_io_replay_0_bits_uop_debugInfo_tlbRespTime, i_io_replay_0_bits_uop_debugInfo_tlbRespTime;
  logic [55:0]     g_io_replay_0_bits_uop_debug_seqNum_seqNum, i_io_replay_0_bits_uop_debug_seqNum_seqNum;
  logic [7:0]      g_io_replay_0_bits_uop_debug_seqNum_uopIdx, i_io_replay_0_bits_uop_debug_seqNum_uopIdx;
  logic            g_io_replay_0_bits_uop_storeSetHit, i_io_replay_0_bits_uop_storeSetHit;
  logic            g_io_replay_0_bits_uop_waitForRobIdx_flag, i_io_replay_0_bits_uop_waitForRobIdx_flag;
  logic [7:0]      g_io_replay_0_bits_uop_waitForRobIdx_value, i_io_replay_0_bits_uop_waitForRobIdx_value;
  logic            g_io_replay_0_bits_uop_loadWaitBit, i_io_replay_0_bits_uop_loadWaitBit;
  logic [4:0]      g_io_replay_0_bits_uop_ssid, i_io_replay_0_bits_uop_ssid;
  logic            g_io_replay_0_bits_uop_lqIdx_flag, i_io_replay_0_bits_uop_lqIdx_flag;
  logic [6:0]      g_io_replay_0_bits_uop_lqIdx_value, i_io_replay_0_bits_uop_lqIdx_value;
  logic            g_io_replay_0_bits_uop_sqIdx_flag, i_io_replay_0_bits_uop_sqIdx_flag;
  logic [5:0]      g_io_replay_0_bits_uop_sqIdx_value, i_io_replay_0_bits_uop_sqIdx_value;
  logic            g_io_replay_0_bits_uop_singleStep, i_io_replay_0_bits_uop_singleStep;
  logic [34:0]     g_io_replay_0_bits_uop_debug_fuType, i_io_replay_0_bits_uop_debug_fuType;
  logic            g_io_replay_0_bits_uop_debug_sim_trig, i_io_replay_0_bits_uop_debug_sim_trig;
  logic [4:0]      g_io_replay_0_bits_uop_numLsElem, i_io_replay_0_bits_uop_numLsElem;
  logic [49:0]     g_io_replay_0_bits_vaddr, i_io_replay_0_bits_vaddr;
  logic [15:0]     g_io_replay_0_bits_mask, i_io_replay_0_bits_mask;
  logic            g_io_replay_0_bits_isvec, i_io_replay_0_bits_isvec;
  logic            g_io_replay_0_bits_is128bit, i_io_replay_0_bits_is128bit;
  logic [7:0]      g_io_replay_0_bits_elemIdx, i_io_replay_0_bits_elemIdx;
  logic [2:0]      g_io_replay_0_bits_alignedType, i_io_replay_0_bits_alignedType;
  logic [3:0]      g_io_replay_0_bits_mbIndex, i_io_replay_0_bits_mbIndex;
  logic [3:0]      g_io_replay_0_bits_reg_offset, i_io_replay_0_bits_reg_offset;
  logic [7:0]      g_io_replay_0_bits_elemIdxInsideVd, i_io_replay_0_bits_elemIdxInsideVd;
  logic            g_io_replay_0_bits_vecActive, i_io_replay_0_bits_vecActive;
  logic [3:0]      g_io_replay_0_bits_mshrid, i_io_replay_0_bits_mshrid;
  logic            g_io_replay_0_bits_forward_tlDchannel, i_io_replay_0_bits_forward_tlDchannel;
  logic [6:0]      g_io_replay_0_bits_schedIndex, i_io_replay_0_bits_schedIndex;
  logic            g_io_replay_1_valid, i_io_replay_1_valid;
  logic [31:0]     g_io_replay_1_bits_uop_instr, i_io_replay_1_bits_uop_instr;
  logic [49:0]     g_io_replay_1_bits_uop_pc, i_io_replay_1_bits_uop_pc;
  logic [9:0]      g_io_replay_1_bits_uop_foldpc, i_io_replay_1_bits_uop_foldpc;
  logic            g_io_replay_1_bits_uop_exceptionVec_0, i_io_replay_1_bits_uop_exceptionVec_0;
  logic            g_io_replay_1_bits_uop_exceptionVec_1, i_io_replay_1_bits_uop_exceptionVec_1;
  logic            g_io_replay_1_bits_uop_exceptionVec_2, i_io_replay_1_bits_uop_exceptionVec_2;
  logic            g_io_replay_1_bits_uop_exceptionVec_3, i_io_replay_1_bits_uop_exceptionVec_3;
  logic            g_io_replay_1_bits_uop_exceptionVec_5, i_io_replay_1_bits_uop_exceptionVec_5;
  logic            g_io_replay_1_bits_uop_exceptionVec_6, i_io_replay_1_bits_uop_exceptionVec_6;
  logic            g_io_replay_1_bits_uop_exceptionVec_7, i_io_replay_1_bits_uop_exceptionVec_7;
  logic            g_io_replay_1_bits_uop_exceptionVec_8, i_io_replay_1_bits_uop_exceptionVec_8;
  logic            g_io_replay_1_bits_uop_exceptionVec_9, i_io_replay_1_bits_uop_exceptionVec_9;
  logic            g_io_replay_1_bits_uop_exceptionVec_10, i_io_replay_1_bits_uop_exceptionVec_10;
  logic            g_io_replay_1_bits_uop_exceptionVec_11, i_io_replay_1_bits_uop_exceptionVec_11;
  logic            g_io_replay_1_bits_uop_exceptionVec_12, i_io_replay_1_bits_uop_exceptionVec_12;
  logic            g_io_replay_1_bits_uop_exceptionVec_13, i_io_replay_1_bits_uop_exceptionVec_13;
  logic            g_io_replay_1_bits_uop_exceptionVec_14, i_io_replay_1_bits_uop_exceptionVec_14;
  logic            g_io_replay_1_bits_uop_exceptionVec_15, i_io_replay_1_bits_uop_exceptionVec_15;
  logic            g_io_replay_1_bits_uop_exceptionVec_16, i_io_replay_1_bits_uop_exceptionVec_16;
  logic            g_io_replay_1_bits_uop_exceptionVec_17, i_io_replay_1_bits_uop_exceptionVec_17;
  logic            g_io_replay_1_bits_uop_exceptionVec_18, i_io_replay_1_bits_uop_exceptionVec_18;
  logic            g_io_replay_1_bits_uop_exceptionVec_19, i_io_replay_1_bits_uop_exceptionVec_19;
  logic            g_io_replay_1_bits_uop_exceptionVec_20, i_io_replay_1_bits_uop_exceptionVec_20;
  logic            g_io_replay_1_bits_uop_exceptionVec_21, i_io_replay_1_bits_uop_exceptionVec_21;
  logic            g_io_replay_1_bits_uop_exceptionVec_22, i_io_replay_1_bits_uop_exceptionVec_22;
  logic            g_io_replay_1_bits_uop_exceptionVec_23, i_io_replay_1_bits_uop_exceptionVec_23;
  logic            g_io_replay_1_bits_uop_isFetchMalAddr, i_io_replay_1_bits_uop_isFetchMalAddr;
  logic            g_io_replay_1_bits_uop_hasException, i_io_replay_1_bits_uop_hasException;
  logic [3:0]      g_io_replay_1_bits_uop_trigger, i_io_replay_1_bits_uop_trigger;
  logic            g_io_replay_1_bits_uop_preDecodeInfo_valid, i_io_replay_1_bits_uop_preDecodeInfo_valid;
  logic            g_io_replay_1_bits_uop_preDecodeInfo_isRVC, i_io_replay_1_bits_uop_preDecodeInfo_isRVC;
  logic [1:0]      g_io_replay_1_bits_uop_preDecodeInfo_brType, i_io_replay_1_bits_uop_preDecodeInfo_brType;
  logic            g_io_replay_1_bits_uop_preDecodeInfo_isCall, i_io_replay_1_bits_uop_preDecodeInfo_isCall;
  logic            g_io_replay_1_bits_uop_preDecodeInfo_isRet, i_io_replay_1_bits_uop_preDecodeInfo_isRet;
  logic            g_io_replay_1_bits_uop_pred_taken, i_io_replay_1_bits_uop_pred_taken;
  logic            g_io_replay_1_bits_uop_crossPageIPFFix, i_io_replay_1_bits_uop_crossPageIPFFix;
  logic            g_io_replay_1_bits_uop_ftqPtr_flag, i_io_replay_1_bits_uop_ftqPtr_flag;
  logic [5:0]      g_io_replay_1_bits_uop_ftqPtr_value, i_io_replay_1_bits_uop_ftqPtr_value;
  logic [3:0]      g_io_replay_1_bits_uop_ftqOffset, i_io_replay_1_bits_uop_ftqOffset;
  logic            g_io_replay_1_bits_uop_satpFlushFirstFetchFault, i_io_replay_1_bits_uop_satpFlushFirstFetchFault;
  logic [3:0]      g_io_replay_1_bits_uop_srcType_0, i_io_replay_1_bits_uop_srcType_0;
  logic [3:0]      g_io_replay_1_bits_uop_srcType_1, i_io_replay_1_bits_uop_srcType_1;
  logic [3:0]      g_io_replay_1_bits_uop_srcType_2, i_io_replay_1_bits_uop_srcType_2;
  logic [3:0]      g_io_replay_1_bits_uop_srcType_3, i_io_replay_1_bits_uop_srcType_3;
  logic [3:0]      g_io_replay_1_bits_uop_srcType_4, i_io_replay_1_bits_uop_srcType_4;
  logic [5:0]      g_io_replay_1_bits_uop_ldest, i_io_replay_1_bits_uop_ldest;
  logic [34:0]     g_io_replay_1_bits_uop_fuType, i_io_replay_1_bits_uop_fuType;
  logic [8:0]      g_io_replay_1_bits_uop_fuOpType, i_io_replay_1_bits_uop_fuOpType;
  logic            g_io_replay_1_bits_uop_rfWen, i_io_replay_1_bits_uop_rfWen;
  logic            g_io_replay_1_bits_uop_fpWen, i_io_replay_1_bits_uop_fpWen;
  logic            g_io_replay_1_bits_uop_vecWen, i_io_replay_1_bits_uop_vecWen;
  logic            g_io_replay_1_bits_uop_v0Wen, i_io_replay_1_bits_uop_v0Wen;
  logic            g_io_replay_1_bits_uop_vlWen, i_io_replay_1_bits_uop_vlWen;
  logic            g_io_replay_1_bits_uop_isXSTrap, i_io_replay_1_bits_uop_isXSTrap;
  logic            g_io_replay_1_bits_uop_waitForward, i_io_replay_1_bits_uop_waitForward;
  logic            g_io_replay_1_bits_uop_blockBackward, i_io_replay_1_bits_uop_blockBackward;
  logic            g_io_replay_1_bits_uop_canRobCompress, i_io_replay_1_bits_uop_canRobCompress;
  logic [3:0]      g_io_replay_1_bits_uop_selImm, i_io_replay_1_bits_uop_selImm;
  logic [31:0]     g_io_replay_1_bits_uop_imm, i_io_replay_1_bits_uop_imm;
  logic [1:0]      g_io_replay_1_bits_uop_fpu_typeTagOut, i_io_replay_1_bits_uop_fpu_typeTagOut;
  logic            g_io_replay_1_bits_uop_fpu_wflags, i_io_replay_1_bits_uop_fpu_wflags;
  logic [1:0]      g_io_replay_1_bits_uop_fpu_typ, i_io_replay_1_bits_uop_fpu_typ;
  logic [1:0]      g_io_replay_1_bits_uop_fpu_fmt, i_io_replay_1_bits_uop_fpu_fmt;
  logic [2:0]      g_io_replay_1_bits_uop_fpu_rm, i_io_replay_1_bits_uop_fpu_rm;
  logic            g_io_replay_1_bits_uop_vpu_vill, i_io_replay_1_bits_uop_vpu_vill;
  logic            g_io_replay_1_bits_uop_vpu_vma, i_io_replay_1_bits_uop_vpu_vma;
  logic            g_io_replay_1_bits_uop_vpu_vta, i_io_replay_1_bits_uop_vpu_vta;
  logic [1:0]      g_io_replay_1_bits_uop_vpu_vsew, i_io_replay_1_bits_uop_vpu_vsew;
  logic [2:0]      g_io_replay_1_bits_uop_vpu_vlmul, i_io_replay_1_bits_uop_vpu_vlmul;
  logic            g_io_replay_1_bits_uop_vpu_specVill, i_io_replay_1_bits_uop_vpu_specVill;
  logic            g_io_replay_1_bits_uop_vpu_specVma, i_io_replay_1_bits_uop_vpu_specVma;
  logic            g_io_replay_1_bits_uop_vpu_specVta, i_io_replay_1_bits_uop_vpu_specVta;
  logic [1:0]      g_io_replay_1_bits_uop_vpu_specVsew, i_io_replay_1_bits_uop_vpu_specVsew;
  logic [2:0]      g_io_replay_1_bits_uop_vpu_specVlmul, i_io_replay_1_bits_uop_vpu_specVlmul;
  logic            g_io_replay_1_bits_uop_vpu_vm, i_io_replay_1_bits_uop_vpu_vm;
  logic [7:0]      g_io_replay_1_bits_uop_vpu_vstart, i_io_replay_1_bits_uop_vpu_vstart;
  logic [2:0]      g_io_replay_1_bits_uop_vpu_frm, i_io_replay_1_bits_uop_vpu_frm;
  logic            g_io_replay_1_bits_uop_vpu_fpu_isFpToVecInst, i_io_replay_1_bits_uop_vpu_fpu_isFpToVecInst;
  logic            g_io_replay_1_bits_uop_vpu_fpu_isFP32Instr, i_io_replay_1_bits_uop_vpu_fpu_isFP32Instr;
  logic            g_io_replay_1_bits_uop_vpu_fpu_isFP64Instr, i_io_replay_1_bits_uop_vpu_fpu_isFP64Instr;
  logic            g_io_replay_1_bits_uop_vpu_fpu_isReduction, i_io_replay_1_bits_uop_vpu_fpu_isReduction;
  logic            g_io_replay_1_bits_uop_vpu_fpu_isFoldTo1_2, i_io_replay_1_bits_uop_vpu_fpu_isFoldTo1_2;
  logic            g_io_replay_1_bits_uop_vpu_fpu_isFoldTo1_4, i_io_replay_1_bits_uop_vpu_fpu_isFoldTo1_4;
  logic            g_io_replay_1_bits_uop_vpu_fpu_isFoldTo1_8, i_io_replay_1_bits_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0]      g_io_replay_1_bits_uop_vpu_vxrm, i_io_replay_1_bits_uop_vpu_vxrm;
  logic [6:0]      g_io_replay_1_bits_uop_vpu_vuopIdx, i_io_replay_1_bits_uop_vpu_vuopIdx;
  logic            g_io_replay_1_bits_uop_vpu_lastUop, i_io_replay_1_bits_uop_vpu_lastUop;
  logic [127:0]    g_io_replay_1_bits_uop_vpu_vmask, i_io_replay_1_bits_uop_vpu_vmask;
  logic [7:0]      g_io_replay_1_bits_uop_vpu_vl, i_io_replay_1_bits_uop_vpu_vl;
  logic [2:0]      g_io_replay_1_bits_uop_vpu_nf, i_io_replay_1_bits_uop_vpu_nf;
  logic [1:0]      g_io_replay_1_bits_uop_vpu_veew, i_io_replay_1_bits_uop_vpu_veew;
  logic            g_io_replay_1_bits_uop_vpu_isReverse, i_io_replay_1_bits_uop_vpu_isReverse;
  logic            g_io_replay_1_bits_uop_vpu_isExt, i_io_replay_1_bits_uop_vpu_isExt;
  logic            g_io_replay_1_bits_uop_vpu_isNarrow, i_io_replay_1_bits_uop_vpu_isNarrow;
  logic            g_io_replay_1_bits_uop_vpu_isDstMask, i_io_replay_1_bits_uop_vpu_isDstMask;
  logic            g_io_replay_1_bits_uop_vpu_isOpMask, i_io_replay_1_bits_uop_vpu_isOpMask;
  logic            g_io_replay_1_bits_uop_vpu_isMove, i_io_replay_1_bits_uop_vpu_isMove;
  logic            g_io_replay_1_bits_uop_vpu_isDependOldVd, i_io_replay_1_bits_uop_vpu_isDependOldVd;
  logic            g_io_replay_1_bits_uop_vpu_isWritePartVd, i_io_replay_1_bits_uop_vpu_isWritePartVd;
  logic            g_io_replay_1_bits_uop_vpu_isVleff, i_io_replay_1_bits_uop_vpu_isVleff;
  logic            g_io_replay_1_bits_uop_vlsInstr, i_io_replay_1_bits_uop_vlsInstr;
  logic            g_io_replay_1_bits_uop_wfflags, i_io_replay_1_bits_uop_wfflags;
  logic            g_io_replay_1_bits_uop_isMove, i_io_replay_1_bits_uop_isMove;
  logic            g_io_replay_1_bits_uop_isDropAmocasSta, i_io_replay_1_bits_uop_isDropAmocasSta;
  logic [6:0]      g_io_replay_1_bits_uop_uopIdx, i_io_replay_1_bits_uop_uopIdx;
  logic            g_io_replay_1_bits_uop_isVset, i_io_replay_1_bits_uop_isVset;
  logic            g_io_replay_1_bits_uop_firstUop, i_io_replay_1_bits_uop_firstUop;
  logic            g_io_replay_1_bits_uop_lastUop, i_io_replay_1_bits_uop_lastUop;
  logic [6:0]      g_io_replay_1_bits_uop_numUops, i_io_replay_1_bits_uop_numUops;
  logic [6:0]      g_io_replay_1_bits_uop_numWB, i_io_replay_1_bits_uop_numWB;
  logic [2:0]      g_io_replay_1_bits_uop_commitType, i_io_replay_1_bits_uop_commitType;
  logic            g_io_replay_1_bits_uop_srcState_0, i_io_replay_1_bits_uop_srcState_0;
  logic            g_io_replay_1_bits_uop_srcState_1, i_io_replay_1_bits_uop_srcState_1;
  logic            g_io_replay_1_bits_uop_srcState_2, i_io_replay_1_bits_uop_srcState_2;
  logic            g_io_replay_1_bits_uop_srcState_3, i_io_replay_1_bits_uop_srcState_3;
  logic            g_io_replay_1_bits_uop_srcState_4, i_io_replay_1_bits_uop_srcState_4;
  logic [1:0]      g_io_replay_1_bits_uop_srcLoadDependency_0_0, i_io_replay_1_bits_uop_srcLoadDependency_0_0;
  logic [1:0]      g_io_replay_1_bits_uop_srcLoadDependency_0_1, i_io_replay_1_bits_uop_srcLoadDependency_0_1;
  logic [1:0]      g_io_replay_1_bits_uop_srcLoadDependency_0_2, i_io_replay_1_bits_uop_srcLoadDependency_0_2;
  logic [1:0]      g_io_replay_1_bits_uop_srcLoadDependency_1_0, i_io_replay_1_bits_uop_srcLoadDependency_1_0;
  logic [1:0]      g_io_replay_1_bits_uop_srcLoadDependency_1_1, i_io_replay_1_bits_uop_srcLoadDependency_1_1;
  logic [1:0]      g_io_replay_1_bits_uop_srcLoadDependency_1_2, i_io_replay_1_bits_uop_srcLoadDependency_1_2;
  logic [1:0]      g_io_replay_1_bits_uop_srcLoadDependency_2_0, i_io_replay_1_bits_uop_srcLoadDependency_2_0;
  logic [1:0]      g_io_replay_1_bits_uop_srcLoadDependency_2_1, i_io_replay_1_bits_uop_srcLoadDependency_2_1;
  logic [1:0]      g_io_replay_1_bits_uop_srcLoadDependency_2_2, i_io_replay_1_bits_uop_srcLoadDependency_2_2;
  logic [1:0]      g_io_replay_1_bits_uop_srcLoadDependency_3_0, i_io_replay_1_bits_uop_srcLoadDependency_3_0;
  logic [1:0]      g_io_replay_1_bits_uop_srcLoadDependency_3_1, i_io_replay_1_bits_uop_srcLoadDependency_3_1;
  logic [1:0]      g_io_replay_1_bits_uop_srcLoadDependency_3_2, i_io_replay_1_bits_uop_srcLoadDependency_3_2;
  logic [1:0]      g_io_replay_1_bits_uop_srcLoadDependency_4_0, i_io_replay_1_bits_uop_srcLoadDependency_4_0;
  logic [1:0]      g_io_replay_1_bits_uop_srcLoadDependency_4_1, i_io_replay_1_bits_uop_srcLoadDependency_4_1;
  logic [1:0]      g_io_replay_1_bits_uop_srcLoadDependency_4_2, i_io_replay_1_bits_uop_srcLoadDependency_4_2;
  logic [7:0]      g_io_replay_1_bits_uop_psrc_0, i_io_replay_1_bits_uop_psrc_0;
  logic [7:0]      g_io_replay_1_bits_uop_psrc_1, i_io_replay_1_bits_uop_psrc_1;
  logic [7:0]      g_io_replay_1_bits_uop_psrc_2, i_io_replay_1_bits_uop_psrc_2;
  logic [7:0]      g_io_replay_1_bits_uop_psrc_3, i_io_replay_1_bits_uop_psrc_3;
  logic [7:0]      g_io_replay_1_bits_uop_psrc_4, i_io_replay_1_bits_uop_psrc_4;
  logic [7:0]      g_io_replay_1_bits_uop_pdest, i_io_replay_1_bits_uop_pdest;
  logic            g_io_replay_1_bits_uop_useRegCache_0, i_io_replay_1_bits_uop_useRegCache_0;
  logic            g_io_replay_1_bits_uop_useRegCache_1, i_io_replay_1_bits_uop_useRegCache_1;
  logic [4:0]      g_io_replay_1_bits_uop_regCacheIdx_0, i_io_replay_1_bits_uop_regCacheIdx_0;
  logic [4:0]      g_io_replay_1_bits_uop_regCacheIdx_1, i_io_replay_1_bits_uop_regCacheIdx_1;
  logic            g_io_replay_1_bits_uop_robIdx_flag, i_io_replay_1_bits_uop_robIdx_flag;
  logic [7:0]      g_io_replay_1_bits_uop_robIdx_value, i_io_replay_1_bits_uop_robIdx_value;
  logic [2:0]      g_io_replay_1_bits_uop_instrSize, i_io_replay_1_bits_uop_instrSize;
  logic            g_io_replay_1_bits_uop_dirtyFs, i_io_replay_1_bits_uop_dirtyFs;
  logic            g_io_replay_1_bits_uop_dirtyVs, i_io_replay_1_bits_uop_dirtyVs;
  logic [3:0]      g_io_replay_1_bits_uop_traceBlockInPipe_itype, i_io_replay_1_bits_uop_traceBlockInPipe_itype;
  logic [3:0]      g_io_replay_1_bits_uop_traceBlockInPipe_iretire, i_io_replay_1_bits_uop_traceBlockInPipe_iretire;
  logic            g_io_replay_1_bits_uop_traceBlockInPipe_ilastsize, i_io_replay_1_bits_uop_traceBlockInPipe_ilastsize;
  logic            g_io_replay_1_bits_uop_eliminatedMove, i_io_replay_1_bits_uop_eliminatedMove;
  logic            g_io_replay_1_bits_uop_snapshot, i_io_replay_1_bits_uop_snapshot;
  logic            g_io_replay_1_bits_uop_debugInfo_eliminatedMove, i_io_replay_1_bits_uop_debugInfo_eliminatedMove;
  logic [63:0]     g_io_replay_1_bits_uop_debugInfo_renameTime, i_io_replay_1_bits_uop_debugInfo_renameTime;
  logic [63:0]     g_io_replay_1_bits_uop_debugInfo_dispatchTime, i_io_replay_1_bits_uop_debugInfo_dispatchTime;
  logic [63:0]     g_io_replay_1_bits_uop_debugInfo_enqRsTime, i_io_replay_1_bits_uop_debugInfo_enqRsTime;
  logic [63:0]     g_io_replay_1_bits_uop_debugInfo_selectTime, i_io_replay_1_bits_uop_debugInfo_selectTime;
  logic [63:0]     g_io_replay_1_bits_uop_debugInfo_issueTime, i_io_replay_1_bits_uop_debugInfo_issueTime;
  logic [63:0]     g_io_replay_1_bits_uop_debugInfo_writebackTime, i_io_replay_1_bits_uop_debugInfo_writebackTime;
  logic [63:0]     g_io_replay_1_bits_uop_debugInfo_runahead_checkpoint_id, i_io_replay_1_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]     g_io_replay_1_bits_uop_debugInfo_tlbFirstReqTime, i_io_replay_1_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]     g_io_replay_1_bits_uop_debugInfo_tlbRespTime, i_io_replay_1_bits_uop_debugInfo_tlbRespTime;
  logic [55:0]     g_io_replay_1_bits_uop_debug_seqNum_seqNum, i_io_replay_1_bits_uop_debug_seqNum_seqNum;
  logic [7:0]      g_io_replay_1_bits_uop_debug_seqNum_uopIdx, i_io_replay_1_bits_uop_debug_seqNum_uopIdx;
  logic            g_io_replay_1_bits_uop_storeSetHit, i_io_replay_1_bits_uop_storeSetHit;
  logic            g_io_replay_1_bits_uop_waitForRobIdx_flag, i_io_replay_1_bits_uop_waitForRobIdx_flag;
  logic [7:0]      g_io_replay_1_bits_uop_waitForRobIdx_value, i_io_replay_1_bits_uop_waitForRobIdx_value;
  logic            g_io_replay_1_bits_uop_loadWaitBit, i_io_replay_1_bits_uop_loadWaitBit;
  logic [4:0]      g_io_replay_1_bits_uop_ssid, i_io_replay_1_bits_uop_ssid;
  logic            g_io_replay_1_bits_uop_lqIdx_flag, i_io_replay_1_bits_uop_lqIdx_flag;
  logic [6:0]      g_io_replay_1_bits_uop_lqIdx_value, i_io_replay_1_bits_uop_lqIdx_value;
  logic            g_io_replay_1_bits_uop_sqIdx_flag, i_io_replay_1_bits_uop_sqIdx_flag;
  logic [5:0]      g_io_replay_1_bits_uop_sqIdx_value, i_io_replay_1_bits_uop_sqIdx_value;
  logic            g_io_replay_1_bits_uop_singleStep, i_io_replay_1_bits_uop_singleStep;
  logic [34:0]     g_io_replay_1_bits_uop_debug_fuType, i_io_replay_1_bits_uop_debug_fuType;
  logic            g_io_replay_1_bits_uop_debug_sim_trig, i_io_replay_1_bits_uop_debug_sim_trig;
  logic [4:0]      g_io_replay_1_bits_uop_numLsElem, i_io_replay_1_bits_uop_numLsElem;
  logic [49:0]     g_io_replay_1_bits_vaddr, i_io_replay_1_bits_vaddr;
  logic [15:0]     g_io_replay_1_bits_mask, i_io_replay_1_bits_mask;
  logic            g_io_replay_1_bits_isvec, i_io_replay_1_bits_isvec;
  logic            g_io_replay_1_bits_is128bit, i_io_replay_1_bits_is128bit;
  logic [7:0]      g_io_replay_1_bits_elemIdx, i_io_replay_1_bits_elemIdx;
  logic [2:0]      g_io_replay_1_bits_alignedType, i_io_replay_1_bits_alignedType;
  logic [3:0]      g_io_replay_1_bits_mbIndex, i_io_replay_1_bits_mbIndex;
  logic [3:0]      g_io_replay_1_bits_reg_offset, i_io_replay_1_bits_reg_offset;
  logic [7:0]      g_io_replay_1_bits_elemIdxInsideVd, i_io_replay_1_bits_elemIdxInsideVd;
  logic            g_io_replay_1_bits_vecActive, i_io_replay_1_bits_vecActive;
  logic [3:0]      g_io_replay_1_bits_mshrid, i_io_replay_1_bits_mshrid;
  logic            g_io_replay_1_bits_forward_tlDchannel, i_io_replay_1_bits_forward_tlDchannel;
  logic [6:0]      g_io_replay_1_bits_schedIndex, i_io_replay_1_bits_schedIndex;
  logic            g_io_replay_2_valid, i_io_replay_2_valid;
  logic [31:0]     g_io_replay_2_bits_uop_instr, i_io_replay_2_bits_uop_instr;
  logic [49:0]     g_io_replay_2_bits_uop_pc, i_io_replay_2_bits_uop_pc;
  logic [9:0]      g_io_replay_2_bits_uop_foldpc, i_io_replay_2_bits_uop_foldpc;
  logic            g_io_replay_2_bits_uop_exceptionVec_0, i_io_replay_2_bits_uop_exceptionVec_0;
  logic            g_io_replay_2_bits_uop_exceptionVec_1, i_io_replay_2_bits_uop_exceptionVec_1;
  logic            g_io_replay_2_bits_uop_exceptionVec_2, i_io_replay_2_bits_uop_exceptionVec_2;
  logic            g_io_replay_2_bits_uop_exceptionVec_3, i_io_replay_2_bits_uop_exceptionVec_3;
  logic            g_io_replay_2_bits_uop_exceptionVec_5, i_io_replay_2_bits_uop_exceptionVec_5;
  logic            g_io_replay_2_bits_uop_exceptionVec_6, i_io_replay_2_bits_uop_exceptionVec_6;
  logic            g_io_replay_2_bits_uop_exceptionVec_7, i_io_replay_2_bits_uop_exceptionVec_7;
  logic            g_io_replay_2_bits_uop_exceptionVec_8, i_io_replay_2_bits_uop_exceptionVec_8;
  logic            g_io_replay_2_bits_uop_exceptionVec_9, i_io_replay_2_bits_uop_exceptionVec_9;
  logic            g_io_replay_2_bits_uop_exceptionVec_10, i_io_replay_2_bits_uop_exceptionVec_10;
  logic            g_io_replay_2_bits_uop_exceptionVec_11, i_io_replay_2_bits_uop_exceptionVec_11;
  logic            g_io_replay_2_bits_uop_exceptionVec_12, i_io_replay_2_bits_uop_exceptionVec_12;
  logic            g_io_replay_2_bits_uop_exceptionVec_13, i_io_replay_2_bits_uop_exceptionVec_13;
  logic            g_io_replay_2_bits_uop_exceptionVec_14, i_io_replay_2_bits_uop_exceptionVec_14;
  logic            g_io_replay_2_bits_uop_exceptionVec_15, i_io_replay_2_bits_uop_exceptionVec_15;
  logic            g_io_replay_2_bits_uop_exceptionVec_16, i_io_replay_2_bits_uop_exceptionVec_16;
  logic            g_io_replay_2_bits_uop_exceptionVec_17, i_io_replay_2_bits_uop_exceptionVec_17;
  logic            g_io_replay_2_bits_uop_exceptionVec_18, i_io_replay_2_bits_uop_exceptionVec_18;
  logic            g_io_replay_2_bits_uop_exceptionVec_19, i_io_replay_2_bits_uop_exceptionVec_19;
  logic            g_io_replay_2_bits_uop_exceptionVec_20, i_io_replay_2_bits_uop_exceptionVec_20;
  logic            g_io_replay_2_bits_uop_exceptionVec_21, i_io_replay_2_bits_uop_exceptionVec_21;
  logic            g_io_replay_2_bits_uop_exceptionVec_22, i_io_replay_2_bits_uop_exceptionVec_22;
  logic            g_io_replay_2_bits_uop_exceptionVec_23, i_io_replay_2_bits_uop_exceptionVec_23;
  logic            g_io_replay_2_bits_uop_isFetchMalAddr, i_io_replay_2_bits_uop_isFetchMalAddr;
  logic            g_io_replay_2_bits_uop_hasException, i_io_replay_2_bits_uop_hasException;
  logic [3:0]      g_io_replay_2_bits_uop_trigger, i_io_replay_2_bits_uop_trigger;
  logic            g_io_replay_2_bits_uop_preDecodeInfo_valid, i_io_replay_2_bits_uop_preDecodeInfo_valid;
  logic            g_io_replay_2_bits_uop_preDecodeInfo_isRVC, i_io_replay_2_bits_uop_preDecodeInfo_isRVC;
  logic [1:0]      g_io_replay_2_bits_uop_preDecodeInfo_brType, i_io_replay_2_bits_uop_preDecodeInfo_brType;
  logic            g_io_replay_2_bits_uop_preDecodeInfo_isCall, i_io_replay_2_bits_uop_preDecodeInfo_isCall;
  logic            g_io_replay_2_bits_uop_preDecodeInfo_isRet, i_io_replay_2_bits_uop_preDecodeInfo_isRet;
  logic            g_io_replay_2_bits_uop_pred_taken, i_io_replay_2_bits_uop_pred_taken;
  logic            g_io_replay_2_bits_uop_crossPageIPFFix, i_io_replay_2_bits_uop_crossPageIPFFix;
  logic            g_io_replay_2_bits_uop_ftqPtr_flag, i_io_replay_2_bits_uop_ftqPtr_flag;
  logic [5:0]      g_io_replay_2_bits_uop_ftqPtr_value, i_io_replay_2_bits_uop_ftqPtr_value;
  logic [3:0]      g_io_replay_2_bits_uop_ftqOffset, i_io_replay_2_bits_uop_ftqOffset;
  logic            g_io_replay_2_bits_uop_satpFlushFirstFetchFault, i_io_replay_2_bits_uop_satpFlushFirstFetchFault;
  logic [3:0]      g_io_replay_2_bits_uop_srcType_0, i_io_replay_2_bits_uop_srcType_0;
  logic [3:0]      g_io_replay_2_bits_uop_srcType_1, i_io_replay_2_bits_uop_srcType_1;
  logic [3:0]      g_io_replay_2_bits_uop_srcType_2, i_io_replay_2_bits_uop_srcType_2;
  logic [3:0]      g_io_replay_2_bits_uop_srcType_3, i_io_replay_2_bits_uop_srcType_3;
  logic [3:0]      g_io_replay_2_bits_uop_srcType_4, i_io_replay_2_bits_uop_srcType_4;
  logic [5:0]      g_io_replay_2_bits_uop_ldest, i_io_replay_2_bits_uop_ldest;
  logic [34:0]     g_io_replay_2_bits_uop_fuType, i_io_replay_2_bits_uop_fuType;
  logic [8:0]      g_io_replay_2_bits_uop_fuOpType, i_io_replay_2_bits_uop_fuOpType;
  logic            g_io_replay_2_bits_uop_rfWen, i_io_replay_2_bits_uop_rfWen;
  logic            g_io_replay_2_bits_uop_fpWen, i_io_replay_2_bits_uop_fpWen;
  logic            g_io_replay_2_bits_uop_vecWen, i_io_replay_2_bits_uop_vecWen;
  logic            g_io_replay_2_bits_uop_v0Wen, i_io_replay_2_bits_uop_v0Wen;
  logic            g_io_replay_2_bits_uop_vlWen, i_io_replay_2_bits_uop_vlWen;
  logic            g_io_replay_2_bits_uop_isXSTrap, i_io_replay_2_bits_uop_isXSTrap;
  logic            g_io_replay_2_bits_uop_waitForward, i_io_replay_2_bits_uop_waitForward;
  logic            g_io_replay_2_bits_uop_blockBackward, i_io_replay_2_bits_uop_blockBackward;
  logic            g_io_replay_2_bits_uop_canRobCompress, i_io_replay_2_bits_uop_canRobCompress;
  logic [3:0]      g_io_replay_2_bits_uop_selImm, i_io_replay_2_bits_uop_selImm;
  logic [31:0]     g_io_replay_2_bits_uop_imm, i_io_replay_2_bits_uop_imm;
  logic [1:0]      g_io_replay_2_bits_uop_fpu_typeTagOut, i_io_replay_2_bits_uop_fpu_typeTagOut;
  logic            g_io_replay_2_bits_uop_fpu_wflags, i_io_replay_2_bits_uop_fpu_wflags;
  logic [1:0]      g_io_replay_2_bits_uop_fpu_typ, i_io_replay_2_bits_uop_fpu_typ;
  logic [1:0]      g_io_replay_2_bits_uop_fpu_fmt, i_io_replay_2_bits_uop_fpu_fmt;
  logic [2:0]      g_io_replay_2_bits_uop_fpu_rm, i_io_replay_2_bits_uop_fpu_rm;
  logic            g_io_replay_2_bits_uop_vpu_vill, i_io_replay_2_bits_uop_vpu_vill;
  logic            g_io_replay_2_bits_uop_vpu_vma, i_io_replay_2_bits_uop_vpu_vma;
  logic            g_io_replay_2_bits_uop_vpu_vta, i_io_replay_2_bits_uop_vpu_vta;
  logic [1:0]      g_io_replay_2_bits_uop_vpu_vsew, i_io_replay_2_bits_uop_vpu_vsew;
  logic [2:0]      g_io_replay_2_bits_uop_vpu_vlmul, i_io_replay_2_bits_uop_vpu_vlmul;
  logic            g_io_replay_2_bits_uop_vpu_specVill, i_io_replay_2_bits_uop_vpu_specVill;
  logic            g_io_replay_2_bits_uop_vpu_specVma, i_io_replay_2_bits_uop_vpu_specVma;
  logic            g_io_replay_2_bits_uop_vpu_specVta, i_io_replay_2_bits_uop_vpu_specVta;
  logic [1:0]      g_io_replay_2_bits_uop_vpu_specVsew, i_io_replay_2_bits_uop_vpu_specVsew;
  logic [2:0]      g_io_replay_2_bits_uop_vpu_specVlmul, i_io_replay_2_bits_uop_vpu_specVlmul;
  logic            g_io_replay_2_bits_uop_vpu_vm, i_io_replay_2_bits_uop_vpu_vm;
  logic [7:0]      g_io_replay_2_bits_uop_vpu_vstart, i_io_replay_2_bits_uop_vpu_vstart;
  logic [2:0]      g_io_replay_2_bits_uop_vpu_frm, i_io_replay_2_bits_uop_vpu_frm;
  logic            g_io_replay_2_bits_uop_vpu_fpu_isFpToVecInst, i_io_replay_2_bits_uop_vpu_fpu_isFpToVecInst;
  logic            g_io_replay_2_bits_uop_vpu_fpu_isFP32Instr, i_io_replay_2_bits_uop_vpu_fpu_isFP32Instr;
  logic            g_io_replay_2_bits_uop_vpu_fpu_isFP64Instr, i_io_replay_2_bits_uop_vpu_fpu_isFP64Instr;
  logic            g_io_replay_2_bits_uop_vpu_fpu_isReduction, i_io_replay_2_bits_uop_vpu_fpu_isReduction;
  logic            g_io_replay_2_bits_uop_vpu_fpu_isFoldTo1_2, i_io_replay_2_bits_uop_vpu_fpu_isFoldTo1_2;
  logic            g_io_replay_2_bits_uop_vpu_fpu_isFoldTo1_4, i_io_replay_2_bits_uop_vpu_fpu_isFoldTo1_4;
  logic            g_io_replay_2_bits_uop_vpu_fpu_isFoldTo1_8, i_io_replay_2_bits_uop_vpu_fpu_isFoldTo1_8;
  logic [1:0]      g_io_replay_2_bits_uop_vpu_vxrm, i_io_replay_2_bits_uop_vpu_vxrm;
  logic [6:0]      g_io_replay_2_bits_uop_vpu_vuopIdx, i_io_replay_2_bits_uop_vpu_vuopIdx;
  logic            g_io_replay_2_bits_uop_vpu_lastUop, i_io_replay_2_bits_uop_vpu_lastUop;
  logic [127:0]    g_io_replay_2_bits_uop_vpu_vmask, i_io_replay_2_bits_uop_vpu_vmask;
  logic [7:0]      g_io_replay_2_bits_uop_vpu_vl, i_io_replay_2_bits_uop_vpu_vl;
  logic [2:0]      g_io_replay_2_bits_uop_vpu_nf, i_io_replay_2_bits_uop_vpu_nf;
  logic [1:0]      g_io_replay_2_bits_uop_vpu_veew, i_io_replay_2_bits_uop_vpu_veew;
  logic            g_io_replay_2_bits_uop_vpu_isReverse, i_io_replay_2_bits_uop_vpu_isReverse;
  logic            g_io_replay_2_bits_uop_vpu_isExt, i_io_replay_2_bits_uop_vpu_isExt;
  logic            g_io_replay_2_bits_uop_vpu_isNarrow, i_io_replay_2_bits_uop_vpu_isNarrow;
  logic            g_io_replay_2_bits_uop_vpu_isDstMask, i_io_replay_2_bits_uop_vpu_isDstMask;
  logic            g_io_replay_2_bits_uop_vpu_isOpMask, i_io_replay_2_bits_uop_vpu_isOpMask;
  logic            g_io_replay_2_bits_uop_vpu_isMove, i_io_replay_2_bits_uop_vpu_isMove;
  logic            g_io_replay_2_bits_uop_vpu_isDependOldVd, i_io_replay_2_bits_uop_vpu_isDependOldVd;
  logic            g_io_replay_2_bits_uop_vpu_isWritePartVd, i_io_replay_2_bits_uop_vpu_isWritePartVd;
  logic            g_io_replay_2_bits_uop_vpu_isVleff, i_io_replay_2_bits_uop_vpu_isVleff;
  logic            g_io_replay_2_bits_uop_vlsInstr, i_io_replay_2_bits_uop_vlsInstr;
  logic            g_io_replay_2_bits_uop_wfflags, i_io_replay_2_bits_uop_wfflags;
  logic            g_io_replay_2_bits_uop_isMove, i_io_replay_2_bits_uop_isMove;
  logic            g_io_replay_2_bits_uop_isDropAmocasSta, i_io_replay_2_bits_uop_isDropAmocasSta;
  logic [6:0]      g_io_replay_2_bits_uop_uopIdx, i_io_replay_2_bits_uop_uopIdx;
  logic            g_io_replay_2_bits_uop_isVset, i_io_replay_2_bits_uop_isVset;
  logic            g_io_replay_2_bits_uop_firstUop, i_io_replay_2_bits_uop_firstUop;
  logic            g_io_replay_2_bits_uop_lastUop, i_io_replay_2_bits_uop_lastUop;
  logic [6:0]      g_io_replay_2_bits_uop_numUops, i_io_replay_2_bits_uop_numUops;
  logic [6:0]      g_io_replay_2_bits_uop_numWB, i_io_replay_2_bits_uop_numWB;
  logic [2:0]      g_io_replay_2_bits_uop_commitType, i_io_replay_2_bits_uop_commitType;
  logic            g_io_replay_2_bits_uop_srcState_0, i_io_replay_2_bits_uop_srcState_0;
  logic            g_io_replay_2_bits_uop_srcState_1, i_io_replay_2_bits_uop_srcState_1;
  logic            g_io_replay_2_bits_uop_srcState_2, i_io_replay_2_bits_uop_srcState_2;
  logic            g_io_replay_2_bits_uop_srcState_3, i_io_replay_2_bits_uop_srcState_3;
  logic            g_io_replay_2_bits_uop_srcState_4, i_io_replay_2_bits_uop_srcState_4;
  logic [1:0]      g_io_replay_2_bits_uop_srcLoadDependency_0_0, i_io_replay_2_bits_uop_srcLoadDependency_0_0;
  logic [1:0]      g_io_replay_2_bits_uop_srcLoadDependency_0_1, i_io_replay_2_bits_uop_srcLoadDependency_0_1;
  logic [1:0]      g_io_replay_2_bits_uop_srcLoadDependency_0_2, i_io_replay_2_bits_uop_srcLoadDependency_0_2;
  logic [1:0]      g_io_replay_2_bits_uop_srcLoadDependency_1_0, i_io_replay_2_bits_uop_srcLoadDependency_1_0;
  logic [1:0]      g_io_replay_2_bits_uop_srcLoadDependency_1_1, i_io_replay_2_bits_uop_srcLoadDependency_1_1;
  logic [1:0]      g_io_replay_2_bits_uop_srcLoadDependency_1_2, i_io_replay_2_bits_uop_srcLoadDependency_1_2;
  logic [1:0]      g_io_replay_2_bits_uop_srcLoadDependency_2_0, i_io_replay_2_bits_uop_srcLoadDependency_2_0;
  logic [1:0]      g_io_replay_2_bits_uop_srcLoadDependency_2_1, i_io_replay_2_bits_uop_srcLoadDependency_2_1;
  logic [1:0]      g_io_replay_2_bits_uop_srcLoadDependency_2_2, i_io_replay_2_bits_uop_srcLoadDependency_2_2;
  logic [1:0]      g_io_replay_2_bits_uop_srcLoadDependency_3_0, i_io_replay_2_bits_uop_srcLoadDependency_3_0;
  logic [1:0]      g_io_replay_2_bits_uop_srcLoadDependency_3_1, i_io_replay_2_bits_uop_srcLoadDependency_3_1;
  logic [1:0]      g_io_replay_2_bits_uop_srcLoadDependency_3_2, i_io_replay_2_bits_uop_srcLoadDependency_3_2;
  logic [1:0]      g_io_replay_2_bits_uop_srcLoadDependency_4_0, i_io_replay_2_bits_uop_srcLoadDependency_4_0;
  logic [1:0]      g_io_replay_2_bits_uop_srcLoadDependency_4_1, i_io_replay_2_bits_uop_srcLoadDependency_4_1;
  logic [1:0]      g_io_replay_2_bits_uop_srcLoadDependency_4_2, i_io_replay_2_bits_uop_srcLoadDependency_4_2;
  logic [7:0]      g_io_replay_2_bits_uop_psrc_0, i_io_replay_2_bits_uop_psrc_0;
  logic [7:0]      g_io_replay_2_bits_uop_psrc_1, i_io_replay_2_bits_uop_psrc_1;
  logic [7:0]      g_io_replay_2_bits_uop_psrc_2, i_io_replay_2_bits_uop_psrc_2;
  logic [7:0]      g_io_replay_2_bits_uop_psrc_3, i_io_replay_2_bits_uop_psrc_3;
  logic [7:0]      g_io_replay_2_bits_uop_psrc_4, i_io_replay_2_bits_uop_psrc_4;
  logic [7:0]      g_io_replay_2_bits_uop_pdest, i_io_replay_2_bits_uop_pdest;
  logic            g_io_replay_2_bits_uop_useRegCache_0, i_io_replay_2_bits_uop_useRegCache_0;
  logic            g_io_replay_2_bits_uop_useRegCache_1, i_io_replay_2_bits_uop_useRegCache_1;
  logic [4:0]      g_io_replay_2_bits_uop_regCacheIdx_0, i_io_replay_2_bits_uop_regCacheIdx_0;
  logic [4:0]      g_io_replay_2_bits_uop_regCacheIdx_1, i_io_replay_2_bits_uop_regCacheIdx_1;
  logic            g_io_replay_2_bits_uop_robIdx_flag, i_io_replay_2_bits_uop_robIdx_flag;
  logic [7:0]      g_io_replay_2_bits_uop_robIdx_value, i_io_replay_2_bits_uop_robIdx_value;
  logic [2:0]      g_io_replay_2_bits_uop_instrSize, i_io_replay_2_bits_uop_instrSize;
  logic            g_io_replay_2_bits_uop_dirtyFs, i_io_replay_2_bits_uop_dirtyFs;
  logic            g_io_replay_2_bits_uop_dirtyVs, i_io_replay_2_bits_uop_dirtyVs;
  logic [3:0]      g_io_replay_2_bits_uop_traceBlockInPipe_itype, i_io_replay_2_bits_uop_traceBlockInPipe_itype;
  logic [3:0]      g_io_replay_2_bits_uop_traceBlockInPipe_iretire, i_io_replay_2_bits_uop_traceBlockInPipe_iretire;
  logic            g_io_replay_2_bits_uop_traceBlockInPipe_ilastsize, i_io_replay_2_bits_uop_traceBlockInPipe_ilastsize;
  logic            g_io_replay_2_bits_uop_eliminatedMove, i_io_replay_2_bits_uop_eliminatedMove;
  logic            g_io_replay_2_bits_uop_snapshot, i_io_replay_2_bits_uop_snapshot;
  logic            g_io_replay_2_bits_uop_debugInfo_eliminatedMove, i_io_replay_2_bits_uop_debugInfo_eliminatedMove;
  logic [63:0]     g_io_replay_2_bits_uop_debugInfo_renameTime, i_io_replay_2_bits_uop_debugInfo_renameTime;
  logic [63:0]     g_io_replay_2_bits_uop_debugInfo_dispatchTime, i_io_replay_2_bits_uop_debugInfo_dispatchTime;
  logic [63:0]     g_io_replay_2_bits_uop_debugInfo_enqRsTime, i_io_replay_2_bits_uop_debugInfo_enqRsTime;
  logic [63:0]     g_io_replay_2_bits_uop_debugInfo_selectTime, i_io_replay_2_bits_uop_debugInfo_selectTime;
  logic [63:0]     g_io_replay_2_bits_uop_debugInfo_issueTime, i_io_replay_2_bits_uop_debugInfo_issueTime;
  logic [63:0]     g_io_replay_2_bits_uop_debugInfo_writebackTime, i_io_replay_2_bits_uop_debugInfo_writebackTime;
  logic [63:0]     g_io_replay_2_bits_uop_debugInfo_runahead_checkpoint_id, i_io_replay_2_bits_uop_debugInfo_runahead_checkpoint_id;
  logic [63:0]     g_io_replay_2_bits_uop_debugInfo_tlbFirstReqTime, i_io_replay_2_bits_uop_debugInfo_tlbFirstReqTime;
  logic [63:0]     g_io_replay_2_bits_uop_debugInfo_tlbRespTime, i_io_replay_2_bits_uop_debugInfo_tlbRespTime;
  logic [55:0]     g_io_replay_2_bits_uop_debug_seqNum_seqNum, i_io_replay_2_bits_uop_debug_seqNum_seqNum;
  logic [7:0]      g_io_replay_2_bits_uop_debug_seqNum_uopIdx, i_io_replay_2_bits_uop_debug_seqNum_uopIdx;
  logic            g_io_replay_2_bits_uop_storeSetHit, i_io_replay_2_bits_uop_storeSetHit;
  logic            g_io_replay_2_bits_uop_waitForRobIdx_flag, i_io_replay_2_bits_uop_waitForRobIdx_flag;
  logic [7:0]      g_io_replay_2_bits_uop_waitForRobIdx_value, i_io_replay_2_bits_uop_waitForRobIdx_value;
  logic            g_io_replay_2_bits_uop_loadWaitBit, i_io_replay_2_bits_uop_loadWaitBit;
  logic [4:0]      g_io_replay_2_bits_uop_ssid, i_io_replay_2_bits_uop_ssid;
  logic            g_io_replay_2_bits_uop_lqIdx_flag, i_io_replay_2_bits_uop_lqIdx_flag;
  logic [6:0]      g_io_replay_2_bits_uop_lqIdx_value, i_io_replay_2_bits_uop_lqIdx_value;
  logic            g_io_replay_2_bits_uop_sqIdx_flag, i_io_replay_2_bits_uop_sqIdx_flag;
  logic [5:0]      g_io_replay_2_bits_uop_sqIdx_value, i_io_replay_2_bits_uop_sqIdx_value;
  logic            g_io_replay_2_bits_uop_singleStep, i_io_replay_2_bits_uop_singleStep;
  logic [34:0]     g_io_replay_2_bits_uop_debug_fuType, i_io_replay_2_bits_uop_debug_fuType;
  logic            g_io_replay_2_bits_uop_debug_sim_trig, i_io_replay_2_bits_uop_debug_sim_trig;
  logic [4:0]      g_io_replay_2_bits_uop_numLsElem, i_io_replay_2_bits_uop_numLsElem;
  logic [49:0]     g_io_replay_2_bits_vaddr, i_io_replay_2_bits_vaddr;
  logic [15:0]     g_io_replay_2_bits_mask, i_io_replay_2_bits_mask;
  logic            g_io_replay_2_bits_isvec, i_io_replay_2_bits_isvec;
  logic            g_io_replay_2_bits_is128bit, i_io_replay_2_bits_is128bit;
  logic [7:0]      g_io_replay_2_bits_elemIdx, i_io_replay_2_bits_elemIdx;
  logic [2:0]      g_io_replay_2_bits_alignedType, i_io_replay_2_bits_alignedType;
  logic [3:0]      g_io_replay_2_bits_mbIndex, i_io_replay_2_bits_mbIndex;
  logic [3:0]      g_io_replay_2_bits_reg_offset, i_io_replay_2_bits_reg_offset;
  logic [7:0]      g_io_replay_2_bits_elemIdxInsideVd, i_io_replay_2_bits_elemIdxInsideVd;
  logic            g_io_replay_2_bits_vecActive, i_io_replay_2_bits_vecActive;
  logic [3:0]      g_io_replay_2_bits_mshrid, i_io_replay_2_bits_mshrid;
  logic            g_io_replay_2_bits_forward_tlDchannel, i_io_replay_2_bits_forward_tlDchannel;
  logic [6:0]      g_io_replay_2_bits_schedIndex, i_io_replay_2_bits_schedIndex;
  logic            g_io_lqFull, i_io_lqFull;
  logic            g_io_debugTopDown_robHeadTlbReplay, i_io_debugTopDown_robHeadTlbReplay;
  logic            g_io_debugTopDown_robHeadTlbMiss, i_io_debugTopDown_robHeadTlbMiss;
  logic            g_io_debugTopDown_robHeadLoadVio, i_io_debugTopDown_robHeadLoadVio;
  logic            g_io_debugTopDown_robHeadLoadMSHR, i_io_debugTopDown_robHeadLoadMSHR;
  logic            g_io_replayAllocate, i_io_replayAllocate;
  logic [5:0]      g_io_perf_0_value, i_io_perf_0_value;
  logic [5:0]      g_io_perf_1_value, i_io_perf_1_value;
  logic [5:0]      g_io_perf_2_value, i_io_perf_2_value;
  logic [5:0]      g_io_perf_3_value, i_io_perf_3_value;
  logic [5:0]      g_io_perf_4_value, i_io_perf_4_value;
  logic [5:0]      g_io_perf_5_value, i_io_perf_5_value;
  logic [5:0]      g_io_perf_6_value, i_io_perf_6_value;
  logic [5:0]      g_io_perf_7_value, i_io_perf_7_value;
  logic [5:0]      g_io_perf_8_value, i_io_perf_8_value;
  logic [5:0]      g_io_perf_9_value, i_io_perf_9_value;
  logic [5:0]      g_io_perf_10_value, i_io_perf_10_value;
  logic [5:0]      g_io_perf_11_value, i_io_perf_11_value;
  logic [5:0]      g_io_perf_12_value, i_io_perf_12_value;

  LoadQueueReplay g_dut (
    .clock(clk), .reset(rst),
    .io_redirect_valid(io_redirect_valid),
    .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value),
    .io_redirect_bits_level(io_redirect_bits_level),
    .io_vecFeedback_0_valid(io_vecFeedback_0_valid),
    .io_vecFeedback_0_bits_robidx_flag(io_vecFeedback_0_bits_robidx_flag),
    .io_vecFeedback_0_bits_robidx_value(io_vecFeedback_0_bits_robidx_value),
    .io_vecFeedback_0_bits_uopidx(io_vecFeedback_0_bits_uopidx),
    .io_vecFeedback_0_bits_feedback_0(io_vecFeedback_0_bits_feedback_0),
    .io_vecFeedback_0_bits_feedback_1(io_vecFeedback_0_bits_feedback_1),
    .io_vecFeedback_1_valid(io_vecFeedback_1_valid),
    .io_vecFeedback_1_bits_robidx_flag(io_vecFeedback_1_bits_robidx_flag),
    .io_vecFeedback_1_bits_robidx_value(io_vecFeedback_1_bits_robidx_value),
    .io_vecFeedback_1_bits_uopidx(io_vecFeedback_1_bits_uopidx),
    .io_vecFeedback_1_bits_feedback_0(io_vecFeedback_1_bits_feedback_0),
    .io_vecFeedback_1_bits_feedback_1(io_vecFeedback_1_bits_feedback_1),
    .io_enq_0_valid(io_enq_0_valid),
    .io_enq_0_bits_uop_instr(io_enq_0_bits_uop_instr),
    .io_enq_0_bits_uop_pc(io_enq_0_bits_uop_pc),
    .io_enq_0_bits_uop_foldpc(io_enq_0_bits_uop_foldpc),
    .io_enq_0_bits_uop_exceptionVec_0(io_enq_0_bits_uop_exceptionVec_0),
    .io_enq_0_bits_uop_exceptionVec_1(io_enq_0_bits_uop_exceptionVec_1),
    .io_enq_0_bits_uop_exceptionVec_2(io_enq_0_bits_uop_exceptionVec_2),
    .io_enq_0_bits_uop_exceptionVec_3(io_enq_0_bits_uop_exceptionVec_3),
    .io_enq_0_bits_uop_exceptionVec_5(io_enq_0_bits_uop_exceptionVec_5),
    .io_enq_0_bits_uop_exceptionVec_6(io_enq_0_bits_uop_exceptionVec_6),
    .io_enq_0_bits_uop_exceptionVec_7(io_enq_0_bits_uop_exceptionVec_7),
    .io_enq_0_bits_uop_exceptionVec_8(io_enq_0_bits_uop_exceptionVec_8),
    .io_enq_0_bits_uop_exceptionVec_9(io_enq_0_bits_uop_exceptionVec_9),
    .io_enq_0_bits_uop_exceptionVec_10(io_enq_0_bits_uop_exceptionVec_10),
    .io_enq_0_bits_uop_exceptionVec_11(io_enq_0_bits_uop_exceptionVec_11),
    .io_enq_0_bits_uop_exceptionVec_12(io_enq_0_bits_uop_exceptionVec_12),
    .io_enq_0_bits_uop_exceptionVec_13(io_enq_0_bits_uop_exceptionVec_13),
    .io_enq_0_bits_uop_exceptionVec_14(io_enq_0_bits_uop_exceptionVec_14),
    .io_enq_0_bits_uop_exceptionVec_15(io_enq_0_bits_uop_exceptionVec_15),
    .io_enq_0_bits_uop_exceptionVec_16(io_enq_0_bits_uop_exceptionVec_16),
    .io_enq_0_bits_uop_exceptionVec_17(io_enq_0_bits_uop_exceptionVec_17),
    .io_enq_0_bits_uop_exceptionVec_18(io_enq_0_bits_uop_exceptionVec_18),
    .io_enq_0_bits_uop_exceptionVec_19(io_enq_0_bits_uop_exceptionVec_19),
    .io_enq_0_bits_uop_exceptionVec_20(io_enq_0_bits_uop_exceptionVec_20),
    .io_enq_0_bits_uop_exceptionVec_21(io_enq_0_bits_uop_exceptionVec_21),
    .io_enq_0_bits_uop_exceptionVec_22(io_enq_0_bits_uop_exceptionVec_22),
    .io_enq_0_bits_uop_exceptionVec_23(io_enq_0_bits_uop_exceptionVec_23),
    .io_enq_0_bits_uop_isFetchMalAddr(io_enq_0_bits_uop_isFetchMalAddr),
    .io_enq_0_bits_uop_hasException(io_enq_0_bits_uop_hasException),
    .io_enq_0_bits_uop_trigger(io_enq_0_bits_uop_trigger),
    .io_enq_0_bits_uop_preDecodeInfo_valid(io_enq_0_bits_uop_preDecodeInfo_valid),
    .io_enq_0_bits_uop_preDecodeInfo_isRVC(io_enq_0_bits_uop_preDecodeInfo_isRVC),
    .io_enq_0_bits_uop_preDecodeInfo_brType(io_enq_0_bits_uop_preDecodeInfo_brType),
    .io_enq_0_bits_uop_preDecodeInfo_isCall(io_enq_0_bits_uop_preDecodeInfo_isCall),
    .io_enq_0_bits_uop_preDecodeInfo_isRet(io_enq_0_bits_uop_preDecodeInfo_isRet),
    .io_enq_0_bits_uop_pred_taken(io_enq_0_bits_uop_pred_taken),
    .io_enq_0_bits_uop_crossPageIPFFix(io_enq_0_bits_uop_crossPageIPFFix),
    .io_enq_0_bits_uop_ftqPtr_flag(io_enq_0_bits_uop_ftqPtr_flag),
    .io_enq_0_bits_uop_ftqPtr_value(io_enq_0_bits_uop_ftqPtr_value),
    .io_enq_0_bits_uop_ftqOffset(io_enq_0_bits_uop_ftqOffset),
    .io_enq_0_bits_uop_satpFlushFirstFetchFault(io_enq_0_bits_uop_satpFlushFirstFetchFault),
    .io_enq_0_bits_uop_srcType_0(io_enq_0_bits_uop_srcType_0),
    .io_enq_0_bits_uop_srcType_1(io_enq_0_bits_uop_srcType_1),
    .io_enq_0_bits_uop_srcType_2(io_enq_0_bits_uop_srcType_2),
    .io_enq_0_bits_uop_srcType_3(io_enq_0_bits_uop_srcType_3),
    .io_enq_0_bits_uop_srcType_4(io_enq_0_bits_uop_srcType_4),
    .io_enq_0_bits_uop_ldest(io_enq_0_bits_uop_ldest),
    .io_enq_0_bits_uop_fuType(io_enq_0_bits_uop_fuType),
    .io_enq_0_bits_uop_fuOpType(io_enq_0_bits_uop_fuOpType),
    .io_enq_0_bits_uop_rfWen(io_enq_0_bits_uop_rfWen),
    .io_enq_0_bits_uop_fpWen(io_enq_0_bits_uop_fpWen),
    .io_enq_0_bits_uop_vecWen(io_enq_0_bits_uop_vecWen),
    .io_enq_0_bits_uop_v0Wen(io_enq_0_bits_uop_v0Wen),
    .io_enq_0_bits_uop_vlWen(io_enq_0_bits_uop_vlWen),
    .io_enq_0_bits_uop_isXSTrap(io_enq_0_bits_uop_isXSTrap),
    .io_enq_0_bits_uop_waitForward(io_enq_0_bits_uop_waitForward),
    .io_enq_0_bits_uop_blockBackward(io_enq_0_bits_uop_blockBackward),
    .io_enq_0_bits_uop_canRobCompress(io_enq_0_bits_uop_canRobCompress),
    .io_enq_0_bits_uop_selImm(io_enq_0_bits_uop_selImm),
    .io_enq_0_bits_uop_imm(io_enq_0_bits_uop_imm),
    .io_enq_0_bits_uop_fpu_typeTagOut(io_enq_0_bits_uop_fpu_typeTagOut),
    .io_enq_0_bits_uop_fpu_wflags(io_enq_0_bits_uop_fpu_wflags),
    .io_enq_0_bits_uop_fpu_typ(io_enq_0_bits_uop_fpu_typ),
    .io_enq_0_bits_uop_fpu_fmt(io_enq_0_bits_uop_fpu_fmt),
    .io_enq_0_bits_uop_fpu_rm(io_enq_0_bits_uop_fpu_rm),
    .io_enq_0_bits_uop_vpu_vill(io_enq_0_bits_uop_vpu_vill),
    .io_enq_0_bits_uop_vpu_vma(io_enq_0_bits_uop_vpu_vma),
    .io_enq_0_bits_uop_vpu_vta(io_enq_0_bits_uop_vpu_vta),
    .io_enq_0_bits_uop_vpu_vsew(io_enq_0_bits_uop_vpu_vsew),
    .io_enq_0_bits_uop_vpu_vlmul(io_enq_0_bits_uop_vpu_vlmul),
    .io_enq_0_bits_uop_vpu_specVill(io_enq_0_bits_uop_vpu_specVill),
    .io_enq_0_bits_uop_vpu_specVma(io_enq_0_bits_uop_vpu_specVma),
    .io_enq_0_bits_uop_vpu_specVta(io_enq_0_bits_uop_vpu_specVta),
    .io_enq_0_bits_uop_vpu_specVsew(io_enq_0_bits_uop_vpu_specVsew),
    .io_enq_0_bits_uop_vpu_specVlmul(io_enq_0_bits_uop_vpu_specVlmul),
    .io_enq_0_bits_uop_vpu_vm(io_enq_0_bits_uop_vpu_vm),
    .io_enq_0_bits_uop_vpu_vstart(io_enq_0_bits_uop_vpu_vstart),
    .io_enq_0_bits_uop_vpu_frm(io_enq_0_bits_uop_vpu_frm),
    .io_enq_0_bits_uop_vpu_fpu_isFpToVecInst(io_enq_0_bits_uop_vpu_fpu_isFpToVecInst),
    .io_enq_0_bits_uop_vpu_fpu_isFP32Instr(io_enq_0_bits_uop_vpu_fpu_isFP32Instr),
    .io_enq_0_bits_uop_vpu_fpu_isFP64Instr(io_enq_0_bits_uop_vpu_fpu_isFP64Instr),
    .io_enq_0_bits_uop_vpu_fpu_isReduction(io_enq_0_bits_uop_vpu_fpu_isReduction),
    .io_enq_0_bits_uop_vpu_fpu_isFoldTo1_2(io_enq_0_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_enq_0_bits_uop_vpu_fpu_isFoldTo1_4(io_enq_0_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_enq_0_bits_uop_vpu_fpu_isFoldTo1_8(io_enq_0_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_enq_0_bits_uop_vpu_vxrm(io_enq_0_bits_uop_vpu_vxrm),
    .io_enq_0_bits_uop_vpu_vuopIdx(io_enq_0_bits_uop_vpu_vuopIdx),
    .io_enq_0_bits_uop_vpu_lastUop(io_enq_0_bits_uop_vpu_lastUop),
    .io_enq_0_bits_uop_vpu_vmask(io_enq_0_bits_uop_vpu_vmask),
    .io_enq_0_bits_uop_vpu_vl(io_enq_0_bits_uop_vpu_vl),
    .io_enq_0_bits_uop_vpu_nf(io_enq_0_bits_uop_vpu_nf),
    .io_enq_0_bits_uop_vpu_veew(io_enq_0_bits_uop_vpu_veew),
    .io_enq_0_bits_uop_vpu_isReverse(io_enq_0_bits_uop_vpu_isReverse),
    .io_enq_0_bits_uop_vpu_isExt(io_enq_0_bits_uop_vpu_isExt),
    .io_enq_0_bits_uop_vpu_isNarrow(io_enq_0_bits_uop_vpu_isNarrow),
    .io_enq_0_bits_uop_vpu_isDstMask(io_enq_0_bits_uop_vpu_isDstMask),
    .io_enq_0_bits_uop_vpu_isOpMask(io_enq_0_bits_uop_vpu_isOpMask),
    .io_enq_0_bits_uop_vpu_isMove(io_enq_0_bits_uop_vpu_isMove),
    .io_enq_0_bits_uop_vpu_isDependOldVd(io_enq_0_bits_uop_vpu_isDependOldVd),
    .io_enq_0_bits_uop_vpu_isWritePartVd(io_enq_0_bits_uop_vpu_isWritePartVd),
    .io_enq_0_bits_uop_vpu_isVleff(io_enq_0_bits_uop_vpu_isVleff),
    .io_enq_0_bits_uop_vlsInstr(io_enq_0_bits_uop_vlsInstr),
    .io_enq_0_bits_uop_wfflags(io_enq_0_bits_uop_wfflags),
    .io_enq_0_bits_uop_isMove(io_enq_0_bits_uop_isMove),
    .io_enq_0_bits_uop_isDropAmocasSta(io_enq_0_bits_uop_isDropAmocasSta),
    .io_enq_0_bits_uop_uopIdx(io_enq_0_bits_uop_uopIdx),
    .io_enq_0_bits_uop_isVset(io_enq_0_bits_uop_isVset),
    .io_enq_0_bits_uop_firstUop(io_enq_0_bits_uop_firstUop),
    .io_enq_0_bits_uop_lastUop(io_enq_0_bits_uop_lastUop),
    .io_enq_0_bits_uop_numUops(io_enq_0_bits_uop_numUops),
    .io_enq_0_bits_uop_numWB(io_enq_0_bits_uop_numWB),
    .io_enq_0_bits_uop_commitType(io_enq_0_bits_uop_commitType),
    .io_enq_0_bits_uop_srcState_0(io_enq_0_bits_uop_srcState_0),
    .io_enq_0_bits_uop_srcState_1(io_enq_0_bits_uop_srcState_1),
    .io_enq_0_bits_uop_srcState_2(io_enq_0_bits_uop_srcState_2),
    .io_enq_0_bits_uop_srcState_3(io_enq_0_bits_uop_srcState_3),
    .io_enq_0_bits_uop_srcState_4(io_enq_0_bits_uop_srcState_4),
    .io_enq_0_bits_uop_srcLoadDependency_0_0(io_enq_0_bits_uop_srcLoadDependency_0_0),
    .io_enq_0_bits_uop_srcLoadDependency_0_1(io_enq_0_bits_uop_srcLoadDependency_0_1),
    .io_enq_0_bits_uop_srcLoadDependency_0_2(io_enq_0_bits_uop_srcLoadDependency_0_2),
    .io_enq_0_bits_uop_srcLoadDependency_1_0(io_enq_0_bits_uop_srcLoadDependency_1_0),
    .io_enq_0_bits_uop_srcLoadDependency_1_1(io_enq_0_bits_uop_srcLoadDependency_1_1),
    .io_enq_0_bits_uop_srcLoadDependency_1_2(io_enq_0_bits_uop_srcLoadDependency_1_2),
    .io_enq_0_bits_uop_srcLoadDependency_2_0(io_enq_0_bits_uop_srcLoadDependency_2_0),
    .io_enq_0_bits_uop_srcLoadDependency_2_1(io_enq_0_bits_uop_srcLoadDependency_2_1),
    .io_enq_0_bits_uop_srcLoadDependency_2_2(io_enq_0_bits_uop_srcLoadDependency_2_2),
    .io_enq_0_bits_uop_srcLoadDependency_3_0(io_enq_0_bits_uop_srcLoadDependency_3_0),
    .io_enq_0_bits_uop_srcLoadDependency_3_1(io_enq_0_bits_uop_srcLoadDependency_3_1),
    .io_enq_0_bits_uop_srcLoadDependency_3_2(io_enq_0_bits_uop_srcLoadDependency_3_2),
    .io_enq_0_bits_uop_srcLoadDependency_4_0(io_enq_0_bits_uop_srcLoadDependency_4_0),
    .io_enq_0_bits_uop_srcLoadDependency_4_1(io_enq_0_bits_uop_srcLoadDependency_4_1),
    .io_enq_0_bits_uop_srcLoadDependency_4_2(io_enq_0_bits_uop_srcLoadDependency_4_2),
    .io_enq_0_bits_uop_psrc_0(io_enq_0_bits_uop_psrc_0),
    .io_enq_0_bits_uop_psrc_1(io_enq_0_bits_uop_psrc_1),
    .io_enq_0_bits_uop_psrc_2(io_enq_0_bits_uop_psrc_2),
    .io_enq_0_bits_uop_psrc_3(io_enq_0_bits_uop_psrc_3),
    .io_enq_0_bits_uop_psrc_4(io_enq_0_bits_uop_psrc_4),
    .io_enq_0_bits_uop_pdest(io_enq_0_bits_uop_pdest),
    .io_enq_0_bits_uop_useRegCache_0(io_enq_0_bits_uop_useRegCache_0),
    .io_enq_0_bits_uop_useRegCache_1(io_enq_0_bits_uop_useRegCache_1),
    .io_enq_0_bits_uop_regCacheIdx_0(io_enq_0_bits_uop_regCacheIdx_0),
    .io_enq_0_bits_uop_regCacheIdx_1(io_enq_0_bits_uop_regCacheIdx_1),
    .io_enq_0_bits_uop_robIdx_flag(io_enq_0_bits_uop_robIdx_flag),
    .io_enq_0_bits_uop_robIdx_value(io_enq_0_bits_uop_robIdx_value),
    .io_enq_0_bits_uop_instrSize(io_enq_0_bits_uop_instrSize),
    .io_enq_0_bits_uop_dirtyFs(io_enq_0_bits_uop_dirtyFs),
    .io_enq_0_bits_uop_dirtyVs(io_enq_0_bits_uop_dirtyVs),
    .io_enq_0_bits_uop_traceBlockInPipe_itype(io_enq_0_bits_uop_traceBlockInPipe_itype),
    .io_enq_0_bits_uop_traceBlockInPipe_iretire(io_enq_0_bits_uop_traceBlockInPipe_iretire),
    .io_enq_0_bits_uop_traceBlockInPipe_ilastsize(io_enq_0_bits_uop_traceBlockInPipe_ilastsize),
    .io_enq_0_bits_uop_eliminatedMove(io_enq_0_bits_uop_eliminatedMove),
    .io_enq_0_bits_uop_snapshot(io_enq_0_bits_uop_snapshot),
    .io_enq_0_bits_uop_debugInfo_eliminatedMove(io_enq_0_bits_uop_debugInfo_eliminatedMove),
    .io_enq_0_bits_uop_debugInfo_renameTime(io_enq_0_bits_uop_debugInfo_renameTime),
    .io_enq_0_bits_uop_debugInfo_dispatchTime(io_enq_0_bits_uop_debugInfo_dispatchTime),
    .io_enq_0_bits_uop_debugInfo_enqRsTime(io_enq_0_bits_uop_debugInfo_enqRsTime),
    .io_enq_0_bits_uop_debugInfo_selectTime(io_enq_0_bits_uop_debugInfo_selectTime),
    .io_enq_0_bits_uop_debugInfo_issueTime(io_enq_0_bits_uop_debugInfo_issueTime),
    .io_enq_0_bits_uop_debugInfo_writebackTime(io_enq_0_bits_uop_debugInfo_writebackTime),
    .io_enq_0_bits_uop_debugInfo_runahead_checkpoint_id(io_enq_0_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_enq_0_bits_uop_debugInfo_tlbFirstReqTime(io_enq_0_bits_uop_debugInfo_tlbFirstReqTime),
    .io_enq_0_bits_uop_debugInfo_tlbRespTime(io_enq_0_bits_uop_debugInfo_tlbRespTime),
    .io_enq_0_bits_uop_debug_seqNum_seqNum(io_enq_0_bits_uop_debug_seqNum_seqNum),
    .io_enq_0_bits_uop_debug_seqNum_uopIdx(io_enq_0_bits_uop_debug_seqNum_uopIdx),
    .io_enq_0_bits_uop_storeSetHit(io_enq_0_bits_uop_storeSetHit),
    .io_enq_0_bits_uop_waitForRobIdx_flag(io_enq_0_bits_uop_waitForRobIdx_flag),
    .io_enq_0_bits_uop_waitForRobIdx_value(io_enq_0_bits_uop_waitForRobIdx_value),
    .io_enq_0_bits_uop_loadWaitBit(io_enq_0_bits_uop_loadWaitBit),
    .io_enq_0_bits_uop_loadWaitStrict(io_enq_0_bits_uop_loadWaitStrict),
    .io_enq_0_bits_uop_ssid(io_enq_0_bits_uop_ssid),
    .io_enq_0_bits_uop_lqIdx_flag(io_enq_0_bits_uop_lqIdx_flag),
    .io_enq_0_bits_uop_lqIdx_value(io_enq_0_bits_uop_lqIdx_value),
    .io_enq_0_bits_uop_sqIdx_flag(io_enq_0_bits_uop_sqIdx_flag),
    .io_enq_0_bits_uop_sqIdx_value(io_enq_0_bits_uop_sqIdx_value),
    .io_enq_0_bits_uop_singleStep(io_enq_0_bits_uop_singleStep),
    .io_enq_0_bits_uop_debug_fuType(io_enq_0_bits_uop_debug_fuType),
    .io_enq_0_bits_uop_debug_sim_trig(io_enq_0_bits_uop_debug_sim_trig),
    .io_enq_0_bits_uop_numLsElem(io_enq_0_bits_uop_numLsElem),
    .io_enq_0_bits_vaddr(io_enq_0_bits_vaddr),
    .io_enq_0_bits_mask(io_enq_0_bits_mask),
    .io_enq_0_bits_isvec(io_enq_0_bits_isvec),
    .io_enq_0_bits_is128bit(io_enq_0_bits_is128bit),
    .io_enq_0_bits_elemIdx(io_enq_0_bits_elemIdx),
    .io_enq_0_bits_alignedType(io_enq_0_bits_alignedType),
    .io_enq_0_bits_mbIndex(io_enq_0_bits_mbIndex),
    .io_enq_0_bits_reg_offset(io_enq_0_bits_reg_offset),
    .io_enq_0_bits_elemIdxInsideVd(io_enq_0_bits_elemIdxInsideVd),
    .io_enq_0_bits_vecActive(io_enq_0_bits_vecActive),
    .io_enq_0_bits_isLoadReplay(io_enq_0_bits_isLoadReplay),
    .io_enq_0_bits_handledByMSHR(io_enq_0_bits_handledByMSHR),
    .io_enq_0_bits_schedIndex(io_enq_0_bits_schedIndex),
    .io_enq_0_bits_rep_info_mshr_id(io_enq_0_bits_rep_info_mshr_id),
    .io_enq_0_bits_rep_info_full_fwd(io_enq_0_bits_rep_info_full_fwd),
    .io_enq_0_bits_rep_info_data_inv_sq_idx_flag(io_enq_0_bits_rep_info_data_inv_sq_idx_flag),
    .io_enq_0_bits_rep_info_data_inv_sq_idx_value(io_enq_0_bits_rep_info_data_inv_sq_idx_value),
    .io_enq_0_bits_rep_info_addr_inv_sq_idx_flag(io_enq_0_bits_rep_info_addr_inv_sq_idx_flag),
    .io_enq_0_bits_rep_info_addr_inv_sq_idx_value(io_enq_0_bits_rep_info_addr_inv_sq_idx_value),
    .io_enq_0_bits_rep_info_last_beat(io_enq_0_bits_rep_info_last_beat),
    .io_enq_0_bits_rep_info_cause_0(io_enq_0_bits_rep_info_cause_0),
    .io_enq_0_bits_rep_info_cause_1(io_enq_0_bits_rep_info_cause_1),
    .io_enq_0_bits_rep_info_cause_2(io_enq_0_bits_rep_info_cause_2),
    .io_enq_0_bits_rep_info_cause_3(io_enq_0_bits_rep_info_cause_3),
    .io_enq_0_bits_rep_info_cause_4(io_enq_0_bits_rep_info_cause_4),
    .io_enq_0_bits_rep_info_cause_5(io_enq_0_bits_rep_info_cause_5),
    .io_enq_0_bits_rep_info_cause_6(io_enq_0_bits_rep_info_cause_6),
    .io_enq_0_bits_rep_info_cause_7(io_enq_0_bits_rep_info_cause_7),
    .io_enq_0_bits_rep_info_cause_8(io_enq_0_bits_rep_info_cause_8),
    .io_enq_0_bits_rep_info_cause_9(io_enq_0_bits_rep_info_cause_9),
    .io_enq_0_bits_rep_info_cause_10(io_enq_0_bits_rep_info_cause_10),
    .io_enq_0_bits_rep_info_tlb_id(io_enq_0_bits_rep_info_tlb_id),
    .io_enq_0_bits_rep_info_tlb_full(io_enq_0_bits_rep_info_tlb_full),
    .io_enq_1_valid(io_enq_1_valid),
    .io_enq_1_bits_uop_instr(io_enq_1_bits_uop_instr),
    .io_enq_1_bits_uop_pc(io_enq_1_bits_uop_pc),
    .io_enq_1_bits_uop_foldpc(io_enq_1_bits_uop_foldpc),
    .io_enq_1_bits_uop_exceptionVec_0(io_enq_1_bits_uop_exceptionVec_0),
    .io_enq_1_bits_uop_exceptionVec_1(io_enq_1_bits_uop_exceptionVec_1),
    .io_enq_1_bits_uop_exceptionVec_2(io_enq_1_bits_uop_exceptionVec_2),
    .io_enq_1_bits_uop_exceptionVec_3(io_enq_1_bits_uop_exceptionVec_3),
    .io_enq_1_bits_uop_exceptionVec_5(io_enq_1_bits_uop_exceptionVec_5),
    .io_enq_1_bits_uop_exceptionVec_6(io_enq_1_bits_uop_exceptionVec_6),
    .io_enq_1_bits_uop_exceptionVec_7(io_enq_1_bits_uop_exceptionVec_7),
    .io_enq_1_bits_uop_exceptionVec_8(io_enq_1_bits_uop_exceptionVec_8),
    .io_enq_1_bits_uop_exceptionVec_9(io_enq_1_bits_uop_exceptionVec_9),
    .io_enq_1_bits_uop_exceptionVec_10(io_enq_1_bits_uop_exceptionVec_10),
    .io_enq_1_bits_uop_exceptionVec_11(io_enq_1_bits_uop_exceptionVec_11),
    .io_enq_1_bits_uop_exceptionVec_12(io_enq_1_bits_uop_exceptionVec_12),
    .io_enq_1_bits_uop_exceptionVec_13(io_enq_1_bits_uop_exceptionVec_13),
    .io_enq_1_bits_uop_exceptionVec_14(io_enq_1_bits_uop_exceptionVec_14),
    .io_enq_1_bits_uop_exceptionVec_15(io_enq_1_bits_uop_exceptionVec_15),
    .io_enq_1_bits_uop_exceptionVec_16(io_enq_1_bits_uop_exceptionVec_16),
    .io_enq_1_bits_uop_exceptionVec_17(io_enq_1_bits_uop_exceptionVec_17),
    .io_enq_1_bits_uop_exceptionVec_18(io_enq_1_bits_uop_exceptionVec_18),
    .io_enq_1_bits_uop_exceptionVec_19(io_enq_1_bits_uop_exceptionVec_19),
    .io_enq_1_bits_uop_exceptionVec_20(io_enq_1_bits_uop_exceptionVec_20),
    .io_enq_1_bits_uop_exceptionVec_21(io_enq_1_bits_uop_exceptionVec_21),
    .io_enq_1_bits_uop_exceptionVec_22(io_enq_1_bits_uop_exceptionVec_22),
    .io_enq_1_bits_uop_exceptionVec_23(io_enq_1_bits_uop_exceptionVec_23),
    .io_enq_1_bits_uop_isFetchMalAddr(io_enq_1_bits_uop_isFetchMalAddr),
    .io_enq_1_bits_uop_hasException(io_enq_1_bits_uop_hasException),
    .io_enq_1_bits_uop_trigger(io_enq_1_bits_uop_trigger),
    .io_enq_1_bits_uop_preDecodeInfo_valid(io_enq_1_bits_uop_preDecodeInfo_valid),
    .io_enq_1_bits_uop_preDecodeInfo_isRVC(io_enq_1_bits_uop_preDecodeInfo_isRVC),
    .io_enq_1_bits_uop_preDecodeInfo_brType(io_enq_1_bits_uop_preDecodeInfo_brType),
    .io_enq_1_bits_uop_preDecodeInfo_isCall(io_enq_1_bits_uop_preDecodeInfo_isCall),
    .io_enq_1_bits_uop_preDecodeInfo_isRet(io_enq_1_bits_uop_preDecodeInfo_isRet),
    .io_enq_1_bits_uop_pred_taken(io_enq_1_bits_uop_pred_taken),
    .io_enq_1_bits_uop_crossPageIPFFix(io_enq_1_bits_uop_crossPageIPFFix),
    .io_enq_1_bits_uop_ftqPtr_flag(io_enq_1_bits_uop_ftqPtr_flag),
    .io_enq_1_bits_uop_ftqPtr_value(io_enq_1_bits_uop_ftqPtr_value),
    .io_enq_1_bits_uop_ftqOffset(io_enq_1_bits_uop_ftqOffset),
    .io_enq_1_bits_uop_satpFlushFirstFetchFault(io_enq_1_bits_uop_satpFlushFirstFetchFault),
    .io_enq_1_bits_uop_srcType_0(io_enq_1_bits_uop_srcType_0),
    .io_enq_1_bits_uop_srcType_1(io_enq_1_bits_uop_srcType_1),
    .io_enq_1_bits_uop_srcType_2(io_enq_1_bits_uop_srcType_2),
    .io_enq_1_bits_uop_srcType_3(io_enq_1_bits_uop_srcType_3),
    .io_enq_1_bits_uop_srcType_4(io_enq_1_bits_uop_srcType_4),
    .io_enq_1_bits_uop_ldest(io_enq_1_bits_uop_ldest),
    .io_enq_1_bits_uop_fuType(io_enq_1_bits_uop_fuType),
    .io_enq_1_bits_uop_fuOpType(io_enq_1_bits_uop_fuOpType),
    .io_enq_1_bits_uop_rfWen(io_enq_1_bits_uop_rfWen),
    .io_enq_1_bits_uop_fpWen(io_enq_1_bits_uop_fpWen),
    .io_enq_1_bits_uop_vecWen(io_enq_1_bits_uop_vecWen),
    .io_enq_1_bits_uop_v0Wen(io_enq_1_bits_uop_v0Wen),
    .io_enq_1_bits_uop_vlWen(io_enq_1_bits_uop_vlWen),
    .io_enq_1_bits_uop_isXSTrap(io_enq_1_bits_uop_isXSTrap),
    .io_enq_1_bits_uop_waitForward(io_enq_1_bits_uop_waitForward),
    .io_enq_1_bits_uop_blockBackward(io_enq_1_bits_uop_blockBackward),
    .io_enq_1_bits_uop_canRobCompress(io_enq_1_bits_uop_canRobCompress),
    .io_enq_1_bits_uop_selImm(io_enq_1_bits_uop_selImm),
    .io_enq_1_bits_uop_imm(io_enq_1_bits_uop_imm),
    .io_enq_1_bits_uop_fpu_typeTagOut(io_enq_1_bits_uop_fpu_typeTagOut),
    .io_enq_1_bits_uop_fpu_wflags(io_enq_1_bits_uop_fpu_wflags),
    .io_enq_1_bits_uop_fpu_typ(io_enq_1_bits_uop_fpu_typ),
    .io_enq_1_bits_uop_fpu_fmt(io_enq_1_bits_uop_fpu_fmt),
    .io_enq_1_bits_uop_fpu_rm(io_enq_1_bits_uop_fpu_rm),
    .io_enq_1_bits_uop_vpu_vill(io_enq_1_bits_uop_vpu_vill),
    .io_enq_1_bits_uop_vpu_vma(io_enq_1_bits_uop_vpu_vma),
    .io_enq_1_bits_uop_vpu_vta(io_enq_1_bits_uop_vpu_vta),
    .io_enq_1_bits_uop_vpu_vsew(io_enq_1_bits_uop_vpu_vsew),
    .io_enq_1_bits_uop_vpu_vlmul(io_enq_1_bits_uop_vpu_vlmul),
    .io_enq_1_bits_uop_vpu_specVill(io_enq_1_bits_uop_vpu_specVill),
    .io_enq_1_bits_uop_vpu_specVma(io_enq_1_bits_uop_vpu_specVma),
    .io_enq_1_bits_uop_vpu_specVta(io_enq_1_bits_uop_vpu_specVta),
    .io_enq_1_bits_uop_vpu_specVsew(io_enq_1_bits_uop_vpu_specVsew),
    .io_enq_1_bits_uop_vpu_specVlmul(io_enq_1_bits_uop_vpu_specVlmul),
    .io_enq_1_bits_uop_vpu_vm(io_enq_1_bits_uop_vpu_vm),
    .io_enq_1_bits_uop_vpu_vstart(io_enq_1_bits_uop_vpu_vstart),
    .io_enq_1_bits_uop_vpu_frm(io_enq_1_bits_uop_vpu_frm),
    .io_enq_1_bits_uop_vpu_fpu_isFpToVecInst(io_enq_1_bits_uop_vpu_fpu_isFpToVecInst),
    .io_enq_1_bits_uop_vpu_fpu_isFP32Instr(io_enq_1_bits_uop_vpu_fpu_isFP32Instr),
    .io_enq_1_bits_uop_vpu_fpu_isFP64Instr(io_enq_1_bits_uop_vpu_fpu_isFP64Instr),
    .io_enq_1_bits_uop_vpu_fpu_isReduction(io_enq_1_bits_uop_vpu_fpu_isReduction),
    .io_enq_1_bits_uop_vpu_fpu_isFoldTo1_2(io_enq_1_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_enq_1_bits_uop_vpu_fpu_isFoldTo1_4(io_enq_1_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_enq_1_bits_uop_vpu_fpu_isFoldTo1_8(io_enq_1_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_enq_1_bits_uop_vpu_vxrm(io_enq_1_bits_uop_vpu_vxrm),
    .io_enq_1_bits_uop_vpu_vuopIdx(io_enq_1_bits_uop_vpu_vuopIdx),
    .io_enq_1_bits_uop_vpu_lastUop(io_enq_1_bits_uop_vpu_lastUop),
    .io_enq_1_bits_uop_vpu_vmask(io_enq_1_bits_uop_vpu_vmask),
    .io_enq_1_bits_uop_vpu_vl(io_enq_1_bits_uop_vpu_vl),
    .io_enq_1_bits_uop_vpu_nf(io_enq_1_bits_uop_vpu_nf),
    .io_enq_1_bits_uop_vpu_veew(io_enq_1_bits_uop_vpu_veew),
    .io_enq_1_bits_uop_vpu_isReverse(io_enq_1_bits_uop_vpu_isReverse),
    .io_enq_1_bits_uop_vpu_isExt(io_enq_1_bits_uop_vpu_isExt),
    .io_enq_1_bits_uop_vpu_isNarrow(io_enq_1_bits_uop_vpu_isNarrow),
    .io_enq_1_bits_uop_vpu_isDstMask(io_enq_1_bits_uop_vpu_isDstMask),
    .io_enq_1_bits_uop_vpu_isOpMask(io_enq_1_bits_uop_vpu_isOpMask),
    .io_enq_1_bits_uop_vpu_isMove(io_enq_1_bits_uop_vpu_isMove),
    .io_enq_1_bits_uop_vpu_isDependOldVd(io_enq_1_bits_uop_vpu_isDependOldVd),
    .io_enq_1_bits_uop_vpu_isWritePartVd(io_enq_1_bits_uop_vpu_isWritePartVd),
    .io_enq_1_bits_uop_vpu_isVleff(io_enq_1_bits_uop_vpu_isVleff),
    .io_enq_1_bits_uop_vlsInstr(io_enq_1_bits_uop_vlsInstr),
    .io_enq_1_bits_uop_wfflags(io_enq_1_bits_uop_wfflags),
    .io_enq_1_bits_uop_isMove(io_enq_1_bits_uop_isMove),
    .io_enq_1_bits_uop_isDropAmocasSta(io_enq_1_bits_uop_isDropAmocasSta),
    .io_enq_1_bits_uop_uopIdx(io_enq_1_bits_uop_uopIdx),
    .io_enq_1_bits_uop_isVset(io_enq_1_bits_uop_isVset),
    .io_enq_1_bits_uop_firstUop(io_enq_1_bits_uop_firstUop),
    .io_enq_1_bits_uop_lastUop(io_enq_1_bits_uop_lastUop),
    .io_enq_1_bits_uop_numUops(io_enq_1_bits_uop_numUops),
    .io_enq_1_bits_uop_numWB(io_enq_1_bits_uop_numWB),
    .io_enq_1_bits_uop_commitType(io_enq_1_bits_uop_commitType),
    .io_enq_1_bits_uop_srcState_0(io_enq_1_bits_uop_srcState_0),
    .io_enq_1_bits_uop_srcState_1(io_enq_1_bits_uop_srcState_1),
    .io_enq_1_bits_uop_srcState_2(io_enq_1_bits_uop_srcState_2),
    .io_enq_1_bits_uop_srcState_3(io_enq_1_bits_uop_srcState_3),
    .io_enq_1_bits_uop_srcState_4(io_enq_1_bits_uop_srcState_4),
    .io_enq_1_bits_uop_srcLoadDependency_0_0(io_enq_1_bits_uop_srcLoadDependency_0_0),
    .io_enq_1_bits_uop_srcLoadDependency_0_1(io_enq_1_bits_uop_srcLoadDependency_0_1),
    .io_enq_1_bits_uop_srcLoadDependency_0_2(io_enq_1_bits_uop_srcLoadDependency_0_2),
    .io_enq_1_bits_uop_srcLoadDependency_1_0(io_enq_1_bits_uop_srcLoadDependency_1_0),
    .io_enq_1_bits_uop_srcLoadDependency_1_1(io_enq_1_bits_uop_srcLoadDependency_1_1),
    .io_enq_1_bits_uop_srcLoadDependency_1_2(io_enq_1_bits_uop_srcLoadDependency_1_2),
    .io_enq_1_bits_uop_srcLoadDependency_2_0(io_enq_1_bits_uop_srcLoadDependency_2_0),
    .io_enq_1_bits_uop_srcLoadDependency_2_1(io_enq_1_bits_uop_srcLoadDependency_2_1),
    .io_enq_1_bits_uop_srcLoadDependency_2_2(io_enq_1_bits_uop_srcLoadDependency_2_2),
    .io_enq_1_bits_uop_srcLoadDependency_3_0(io_enq_1_bits_uop_srcLoadDependency_3_0),
    .io_enq_1_bits_uop_srcLoadDependency_3_1(io_enq_1_bits_uop_srcLoadDependency_3_1),
    .io_enq_1_bits_uop_srcLoadDependency_3_2(io_enq_1_bits_uop_srcLoadDependency_3_2),
    .io_enq_1_bits_uop_srcLoadDependency_4_0(io_enq_1_bits_uop_srcLoadDependency_4_0),
    .io_enq_1_bits_uop_srcLoadDependency_4_1(io_enq_1_bits_uop_srcLoadDependency_4_1),
    .io_enq_1_bits_uop_srcLoadDependency_4_2(io_enq_1_bits_uop_srcLoadDependency_4_2),
    .io_enq_1_bits_uop_psrc_0(io_enq_1_bits_uop_psrc_0),
    .io_enq_1_bits_uop_psrc_1(io_enq_1_bits_uop_psrc_1),
    .io_enq_1_bits_uop_psrc_2(io_enq_1_bits_uop_psrc_2),
    .io_enq_1_bits_uop_psrc_3(io_enq_1_bits_uop_psrc_3),
    .io_enq_1_bits_uop_psrc_4(io_enq_1_bits_uop_psrc_4),
    .io_enq_1_bits_uop_pdest(io_enq_1_bits_uop_pdest),
    .io_enq_1_bits_uop_useRegCache_0(io_enq_1_bits_uop_useRegCache_0),
    .io_enq_1_bits_uop_useRegCache_1(io_enq_1_bits_uop_useRegCache_1),
    .io_enq_1_bits_uop_regCacheIdx_0(io_enq_1_bits_uop_regCacheIdx_0),
    .io_enq_1_bits_uop_regCacheIdx_1(io_enq_1_bits_uop_regCacheIdx_1),
    .io_enq_1_bits_uop_robIdx_flag(io_enq_1_bits_uop_robIdx_flag),
    .io_enq_1_bits_uop_robIdx_value(io_enq_1_bits_uop_robIdx_value),
    .io_enq_1_bits_uop_instrSize(io_enq_1_bits_uop_instrSize),
    .io_enq_1_bits_uop_dirtyFs(io_enq_1_bits_uop_dirtyFs),
    .io_enq_1_bits_uop_dirtyVs(io_enq_1_bits_uop_dirtyVs),
    .io_enq_1_bits_uop_traceBlockInPipe_itype(io_enq_1_bits_uop_traceBlockInPipe_itype),
    .io_enq_1_bits_uop_traceBlockInPipe_iretire(io_enq_1_bits_uop_traceBlockInPipe_iretire),
    .io_enq_1_bits_uop_traceBlockInPipe_ilastsize(io_enq_1_bits_uop_traceBlockInPipe_ilastsize),
    .io_enq_1_bits_uop_eliminatedMove(io_enq_1_bits_uop_eliminatedMove),
    .io_enq_1_bits_uop_snapshot(io_enq_1_bits_uop_snapshot),
    .io_enq_1_bits_uop_debugInfo_eliminatedMove(io_enq_1_bits_uop_debugInfo_eliminatedMove),
    .io_enq_1_bits_uop_debugInfo_renameTime(io_enq_1_bits_uop_debugInfo_renameTime),
    .io_enq_1_bits_uop_debugInfo_dispatchTime(io_enq_1_bits_uop_debugInfo_dispatchTime),
    .io_enq_1_bits_uop_debugInfo_enqRsTime(io_enq_1_bits_uop_debugInfo_enqRsTime),
    .io_enq_1_bits_uop_debugInfo_selectTime(io_enq_1_bits_uop_debugInfo_selectTime),
    .io_enq_1_bits_uop_debugInfo_issueTime(io_enq_1_bits_uop_debugInfo_issueTime),
    .io_enq_1_bits_uop_debugInfo_writebackTime(io_enq_1_bits_uop_debugInfo_writebackTime),
    .io_enq_1_bits_uop_debugInfo_runahead_checkpoint_id(io_enq_1_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_enq_1_bits_uop_debugInfo_tlbFirstReqTime(io_enq_1_bits_uop_debugInfo_tlbFirstReqTime),
    .io_enq_1_bits_uop_debugInfo_tlbRespTime(io_enq_1_bits_uop_debugInfo_tlbRespTime),
    .io_enq_1_bits_uop_debug_seqNum_seqNum(io_enq_1_bits_uop_debug_seqNum_seqNum),
    .io_enq_1_bits_uop_debug_seqNum_uopIdx(io_enq_1_bits_uop_debug_seqNum_uopIdx),
    .io_enq_1_bits_uop_storeSetHit(io_enq_1_bits_uop_storeSetHit),
    .io_enq_1_bits_uop_waitForRobIdx_flag(io_enq_1_bits_uop_waitForRobIdx_flag),
    .io_enq_1_bits_uop_waitForRobIdx_value(io_enq_1_bits_uop_waitForRobIdx_value),
    .io_enq_1_bits_uop_loadWaitBit(io_enq_1_bits_uop_loadWaitBit),
    .io_enq_1_bits_uop_loadWaitStrict(io_enq_1_bits_uop_loadWaitStrict),
    .io_enq_1_bits_uop_ssid(io_enq_1_bits_uop_ssid),
    .io_enq_1_bits_uop_lqIdx_flag(io_enq_1_bits_uop_lqIdx_flag),
    .io_enq_1_bits_uop_lqIdx_value(io_enq_1_bits_uop_lqIdx_value),
    .io_enq_1_bits_uop_sqIdx_flag(io_enq_1_bits_uop_sqIdx_flag),
    .io_enq_1_bits_uop_sqIdx_value(io_enq_1_bits_uop_sqIdx_value),
    .io_enq_1_bits_uop_singleStep(io_enq_1_bits_uop_singleStep),
    .io_enq_1_bits_uop_debug_fuType(io_enq_1_bits_uop_debug_fuType),
    .io_enq_1_bits_uop_debug_sim_trig(io_enq_1_bits_uop_debug_sim_trig),
    .io_enq_1_bits_uop_numLsElem(io_enq_1_bits_uop_numLsElem),
    .io_enq_1_bits_vaddr(io_enq_1_bits_vaddr),
    .io_enq_1_bits_mask(io_enq_1_bits_mask),
    .io_enq_1_bits_isvec(io_enq_1_bits_isvec),
    .io_enq_1_bits_is128bit(io_enq_1_bits_is128bit),
    .io_enq_1_bits_elemIdx(io_enq_1_bits_elemIdx),
    .io_enq_1_bits_alignedType(io_enq_1_bits_alignedType),
    .io_enq_1_bits_mbIndex(io_enq_1_bits_mbIndex),
    .io_enq_1_bits_reg_offset(io_enq_1_bits_reg_offset),
    .io_enq_1_bits_elemIdxInsideVd(io_enq_1_bits_elemIdxInsideVd),
    .io_enq_1_bits_vecActive(io_enq_1_bits_vecActive),
    .io_enq_1_bits_isLoadReplay(io_enq_1_bits_isLoadReplay),
    .io_enq_1_bits_handledByMSHR(io_enq_1_bits_handledByMSHR),
    .io_enq_1_bits_schedIndex(io_enq_1_bits_schedIndex),
    .io_enq_1_bits_rep_info_mshr_id(io_enq_1_bits_rep_info_mshr_id),
    .io_enq_1_bits_rep_info_full_fwd(io_enq_1_bits_rep_info_full_fwd),
    .io_enq_1_bits_rep_info_data_inv_sq_idx_flag(io_enq_1_bits_rep_info_data_inv_sq_idx_flag),
    .io_enq_1_bits_rep_info_data_inv_sq_idx_value(io_enq_1_bits_rep_info_data_inv_sq_idx_value),
    .io_enq_1_bits_rep_info_addr_inv_sq_idx_flag(io_enq_1_bits_rep_info_addr_inv_sq_idx_flag),
    .io_enq_1_bits_rep_info_addr_inv_sq_idx_value(io_enq_1_bits_rep_info_addr_inv_sq_idx_value),
    .io_enq_1_bits_rep_info_last_beat(io_enq_1_bits_rep_info_last_beat),
    .io_enq_1_bits_rep_info_cause_0(io_enq_1_bits_rep_info_cause_0),
    .io_enq_1_bits_rep_info_cause_1(io_enq_1_bits_rep_info_cause_1),
    .io_enq_1_bits_rep_info_cause_2(io_enq_1_bits_rep_info_cause_2),
    .io_enq_1_bits_rep_info_cause_3(io_enq_1_bits_rep_info_cause_3),
    .io_enq_1_bits_rep_info_cause_4(io_enq_1_bits_rep_info_cause_4),
    .io_enq_1_bits_rep_info_cause_5(io_enq_1_bits_rep_info_cause_5),
    .io_enq_1_bits_rep_info_cause_6(io_enq_1_bits_rep_info_cause_6),
    .io_enq_1_bits_rep_info_cause_7(io_enq_1_bits_rep_info_cause_7),
    .io_enq_1_bits_rep_info_cause_8(io_enq_1_bits_rep_info_cause_8),
    .io_enq_1_bits_rep_info_cause_9(io_enq_1_bits_rep_info_cause_9),
    .io_enq_1_bits_rep_info_cause_10(io_enq_1_bits_rep_info_cause_10),
    .io_enq_1_bits_rep_info_tlb_id(io_enq_1_bits_rep_info_tlb_id),
    .io_enq_1_bits_rep_info_tlb_full(io_enq_1_bits_rep_info_tlb_full),
    .io_enq_2_valid(io_enq_2_valid),
    .io_enq_2_bits_uop_instr(io_enq_2_bits_uop_instr),
    .io_enq_2_bits_uop_pc(io_enq_2_bits_uop_pc),
    .io_enq_2_bits_uop_foldpc(io_enq_2_bits_uop_foldpc),
    .io_enq_2_bits_uop_exceptionVec_0(io_enq_2_bits_uop_exceptionVec_0),
    .io_enq_2_bits_uop_exceptionVec_1(io_enq_2_bits_uop_exceptionVec_1),
    .io_enq_2_bits_uop_exceptionVec_2(io_enq_2_bits_uop_exceptionVec_2),
    .io_enq_2_bits_uop_exceptionVec_3(io_enq_2_bits_uop_exceptionVec_3),
    .io_enq_2_bits_uop_exceptionVec_5(io_enq_2_bits_uop_exceptionVec_5),
    .io_enq_2_bits_uop_exceptionVec_6(io_enq_2_bits_uop_exceptionVec_6),
    .io_enq_2_bits_uop_exceptionVec_7(io_enq_2_bits_uop_exceptionVec_7),
    .io_enq_2_bits_uop_exceptionVec_8(io_enq_2_bits_uop_exceptionVec_8),
    .io_enq_2_bits_uop_exceptionVec_9(io_enq_2_bits_uop_exceptionVec_9),
    .io_enq_2_bits_uop_exceptionVec_10(io_enq_2_bits_uop_exceptionVec_10),
    .io_enq_2_bits_uop_exceptionVec_11(io_enq_2_bits_uop_exceptionVec_11),
    .io_enq_2_bits_uop_exceptionVec_12(io_enq_2_bits_uop_exceptionVec_12),
    .io_enq_2_bits_uop_exceptionVec_13(io_enq_2_bits_uop_exceptionVec_13),
    .io_enq_2_bits_uop_exceptionVec_14(io_enq_2_bits_uop_exceptionVec_14),
    .io_enq_2_bits_uop_exceptionVec_15(io_enq_2_bits_uop_exceptionVec_15),
    .io_enq_2_bits_uop_exceptionVec_16(io_enq_2_bits_uop_exceptionVec_16),
    .io_enq_2_bits_uop_exceptionVec_17(io_enq_2_bits_uop_exceptionVec_17),
    .io_enq_2_bits_uop_exceptionVec_18(io_enq_2_bits_uop_exceptionVec_18),
    .io_enq_2_bits_uop_exceptionVec_19(io_enq_2_bits_uop_exceptionVec_19),
    .io_enq_2_bits_uop_exceptionVec_20(io_enq_2_bits_uop_exceptionVec_20),
    .io_enq_2_bits_uop_exceptionVec_21(io_enq_2_bits_uop_exceptionVec_21),
    .io_enq_2_bits_uop_exceptionVec_22(io_enq_2_bits_uop_exceptionVec_22),
    .io_enq_2_bits_uop_exceptionVec_23(io_enq_2_bits_uop_exceptionVec_23),
    .io_enq_2_bits_uop_isFetchMalAddr(io_enq_2_bits_uop_isFetchMalAddr),
    .io_enq_2_bits_uop_hasException(io_enq_2_bits_uop_hasException),
    .io_enq_2_bits_uop_trigger(io_enq_2_bits_uop_trigger),
    .io_enq_2_bits_uop_preDecodeInfo_valid(io_enq_2_bits_uop_preDecodeInfo_valid),
    .io_enq_2_bits_uop_preDecodeInfo_isRVC(io_enq_2_bits_uop_preDecodeInfo_isRVC),
    .io_enq_2_bits_uop_preDecodeInfo_brType(io_enq_2_bits_uop_preDecodeInfo_brType),
    .io_enq_2_bits_uop_preDecodeInfo_isCall(io_enq_2_bits_uop_preDecodeInfo_isCall),
    .io_enq_2_bits_uop_preDecodeInfo_isRet(io_enq_2_bits_uop_preDecodeInfo_isRet),
    .io_enq_2_bits_uop_pred_taken(io_enq_2_bits_uop_pred_taken),
    .io_enq_2_bits_uop_crossPageIPFFix(io_enq_2_bits_uop_crossPageIPFFix),
    .io_enq_2_bits_uop_ftqPtr_flag(io_enq_2_bits_uop_ftqPtr_flag),
    .io_enq_2_bits_uop_ftqPtr_value(io_enq_2_bits_uop_ftqPtr_value),
    .io_enq_2_bits_uop_ftqOffset(io_enq_2_bits_uop_ftqOffset),
    .io_enq_2_bits_uop_satpFlushFirstFetchFault(io_enq_2_bits_uop_satpFlushFirstFetchFault),
    .io_enq_2_bits_uop_srcType_0(io_enq_2_bits_uop_srcType_0),
    .io_enq_2_bits_uop_srcType_1(io_enq_2_bits_uop_srcType_1),
    .io_enq_2_bits_uop_srcType_2(io_enq_2_bits_uop_srcType_2),
    .io_enq_2_bits_uop_srcType_3(io_enq_2_bits_uop_srcType_3),
    .io_enq_2_bits_uop_srcType_4(io_enq_2_bits_uop_srcType_4),
    .io_enq_2_bits_uop_ldest(io_enq_2_bits_uop_ldest),
    .io_enq_2_bits_uop_fuType(io_enq_2_bits_uop_fuType),
    .io_enq_2_bits_uop_fuOpType(io_enq_2_bits_uop_fuOpType),
    .io_enq_2_bits_uop_rfWen(io_enq_2_bits_uop_rfWen),
    .io_enq_2_bits_uop_fpWen(io_enq_2_bits_uop_fpWen),
    .io_enq_2_bits_uop_vecWen(io_enq_2_bits_uop_vecWen),
    .io_enq_2_bits_uop_v0Wen(io_enq_2_bits_uop_v0Wen),
    .io_enq_2_bits_uop_vlWen(io_enq_2_bits_uop_vlWen),
    .io_enq_2_bits_uop_isXSTrap(io_enq_2_bits_uop_isXSTrap),
    .io_enq_2_bits_uop_waitForward(io_enq_2_bits_uop_waitForward),
    .io_enq_2_bits_uop_blockBackward(io_enq_2_bits_uop_blockBackward),
    .io_enq_2_bits_uop_canRobCompress(io_enq_2_bits_uop_canRobCompress),
    .io_enq_2_bits_uop_selImm(io_enq_2_bits_uop_selImm),
    .io_enq_2_bits_uop_imm(io_enq_2_bits_uop_imm),
    .io_enq_2_bits_uop_fpu_typeTagOut(io_enq_2_bits_uop_fpu_typeTagOut),
    .io_enq_2_bits_uop_fpu_wflags(io_enq_2_bits_uop_fpu_wflags),
    .io_enq_2_bits_uop_fpu_typ(io_enq_2_bits_uop_fpu_typ),
    .io_enq_2_bits_uop_fpu_fmt(io_enq_2_bits_uop_fpu_fmt),
    .io_enq_2_bits_uop_fpu_rm(io_enq_2_bits_uop_fpu_rm),
    .io_enq_2_bits_uop_vpu_vill(io_enq_2_bits_uop_vpu_vill),
    .io_enq_2_bits_uop_vpu_vma(io_enq_2_bits_uop_vpu_vma),
    .io_enq_2_bits_uop_vpu_vta(io_enq_2_bits_uop_vpu_vta),
    .io_enq_2_bits_uop_vpu_vsew(io_enq_2_bits_uop_vpu_vsew),
    .io_enq_2_bits_uop_vpu_vlmul(io_enq_2_bits_uop_vpu_vlmul),
    .io_enq_2_bits_uop_vpu_specVill(io_enq_2_bits_uop_vpu_specVill),
    .io_enq_2_bits_uop_vpu_specVma(io_enq_2_bits_uop_vpu_specVma),
    .io_enq_2_bits_uop_vpu_specVta(io_enq_2_bits_uop_vpu_specVta),
    .io_enq_2_bits_uop_vpu_specVsew(io_enq_2_bits_uop_vpu_specVsew),
    .io_enq_2_bits_uop_vpu_specVlmul(io_enq_2_bits_uop_vpu_specVlmul),
    .io_enq_2_bits_uop_vpu_vm(io_enq_2_bits_uop_vpu_vm),
    .io_enq_2_bits_uop_vpu_vstart(io_enq_2_bits_uop_vpu_vstart),
    .io_enq_2_bits_uop_vpu_frm(io_enq_2_bits_uop_vpu_frm),
    .io_enq_2_bits_uop_vpu_fpu_isFpToVecInst(io_enq_2_bits_uop_vpu_fpu_isFpToVecInst),
    .io_enq_2_bits_uop_vpu_fpu_isFP32Instr(io_enq_2_bits_uop_vpu_fpu_isFP32Instr),
    .io_enq_2_bits_uop_vpu_fpu_isFP64Instr(io_enq_2_bits_uop_vpu_fpu_isFP64Instr),
    .io_enq_2_bits_uop_vpu_fpu_isReduction(io_enq_2_bits_uop_vpu_fpu_isReduction),
    .io_enq_2_bits_uop_vpu_fpu_isFoldTo1_2(io_enq_2_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_enq_2_bits_uop_vpu_fpu_isFoldTo1_4(io_enq_2_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_enq_2_bits_uop_vpu_fpu_isFoldTo1_8(io_enq_2_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_enq_2_bits_uop_vpu_vxrm(io_enq_2_bits_uop_vpu_vxrm),
    .io_enq_2_bits_uop_vpu_vuopIdx(io_enq_2_bits_uop_vpu_vuopIdx),
    .io_enq_2_bits_uop_vpu_lastUop(io_enq_2_bits_uop_vpu_lastUop),
    .io_enq_2_bits_uop_vpu_vmask(io_enq_2_bits_uop_vpu_vmask),
    .io_enq_2_bits_uop_vpu_vl(io_enq_2_bits_uop_vpu_vl),
    .io_enq_2_bits_uop_vpu_nf(io_enq_2_bits_uop_vpu_nf),
    .io_enq_2_bits_uop_vpu_veew(io_enq_2_bits_uop_vpu_veew),
    .io_enq_2_bits_uop_vpu_isReverse(io_enq_2_bits_uop_vpu_isReverse),
    .io_enq_2_bits_uop_vpu_isExt(io_enq_2_bits_uop_vpu_isExt),
    .io_enq_2_bits_uop_vpu_isNarrow(io_enq_2_bits_uop_vpu_isNarrow),
    .io_enq_2_bits_uop_vpu_isDstMask(io_enq_2_bits_uop_vpu_isDstMask),
    .io_enq_2_bits_uop_vpu_isOpMask(io_enq_2_bits_uop_vpu_isOpMask),
    .io_enq_2_bits_uop_vpu_isMove(io_enq_2_bits_uop_vpu_isMove),
    .io_enq_2_bits_uop_vpu_isDependOldVd(io_enq_2_bits_uop_vpu_isDependOldVd),
    .io_enq_2_bits_uop_vpu_isWritePartVd(io_enq_2_bits_uop_vpu_isWritePartVd),
    .io_enq_2_bits_uop_vpu_isVleff(io_enq_2_bits_uop_vpu_isVleff),
    .io_enq_2_bits_uop_vlsInstr(io_enq_2_bits_uop_vlsInstr),
    .io_enq_2_bits_uop_wfflags(io_enq_2_bits_uop_wfflags),
    .io_enq_2_bits_uop_isMove(io_enq_2_bits_uop_isMove),
    .io_enq_2_bits_uop_isDropAmocasSta(io_enq_2_bits_uop_isDropAmocasSta),
    .io_enq_2_bits_uop_uopIdx(io_enq_2_bits_uop_uopIdx),
    .io_enq_2_bits_uop_isVset(io_enq_2_bits_uop_isVset),
    .io_enq_2_bits_uop_firstUop(io_enq_2_bits_uop_firstUop),
    .io_enq_2_bits_uop_lastUop(io_enq_2_bits_uop_lastUop),
    .io_enq_2_bits_uop_numUops(io_enq_2_bits_uop_numUops),
    .io_enq_2_bits_uop_numWB(io_enq_2_bits_uop_numWB),
    .io_enq_2_bits_uop_commitType(io_enq_2_bits_uop_commitType),
    .io_enq_2_bits_uop_srcState_0(io_enq_2_bits_uop_srcState_0),
    .io_enq_2_bits_uop_srcState_1(io_enq_2_bits_uop_srcState_1),
    .io_enq_2_bits_uop_srcState_2(io_enq_2_bits_uop_srcState_2),
    .io_enq_2_bits_uop_srcState_3(io_enq_2_bits_uop_srcState_3),
    .io_enq_2_bits_uop_srcState_4(io_enq_2_bits_uop_srcState_4),
    .io_enq_2_bits_uop_srcLoadDependency_0_0(io_enq_2_bits_uop_srcLoadDependency_0_0),
    .io_enq_2_bits_uop_srcLoadDependency_0_1(io_enq_2_bits_uop_srcLoadDependency_0_1),
    .io_enq_2_bits_uop_srcLoadDependency_0_2(io_enq_2_bits_uop_srcLoadDependency_0_2),
    .io_enq_2_bits_uop_srcLoadDependency_1_0(io_enq_2_bits_uop_srcLoadDependency_1_0),
    .io_enq_2_bits_uop_srcLoadDependency_1_1(io_enq_2_bits_uop_srcLoadDependency_1_1),
    .io_enq_2_bits_uop_srcLoadDependency_1_2(io_enq_2_bits_uop_srcLoadDependency_1_2),
    .io_enq_2_bits_uop_srcLoadDependency_2_0(io_enq_2_bits_uop_srcLoadDependency_2_0),
    .io_enq_2_bits_uop_srcLoadDependency_2_1(io_enq_2_bits_uop_srcLoadDependency_2_1),
    .io_enq_2_bits_uop_srcLoadDependency_2_2(io_enq_2_bits_uop_srcLoadDependency_2_2),
    .io_enq_2_bits_uop_srcLoadDependency_3_0(io_enq_2_bits_uop_srcLoadDependency_3_0),
    .io_enq_2_bits_uop_srcLoadDependency_3_1(io_enq_2_bits_uop_srcLoadDependency_3_1),
    .io_enq_2_bits_uop_srcLoadDependency_3_2(io_enq_2_bits_uop_srcLoadDependency_3_2),
    .io_enq_2_bits_uop_srcLoadDependency_4_0(io_enq_2_bits_uop_srcLoadDependency_4_0),
    .io_enq_2_bits_uop_srcLoadDependency_4_1(io_enq_2_bits_uop_srcLoadDependency_4_1),
    .io_enq_2_bits_uop_srcLoadDependency_4_2(io_enq_2_bits_uop_srcLoadDependency_4_2),
    .io_enq_2_bits_uop_psrc_0(io_enq_2_bits_uop_psrc_0),
    .io_enq_2_bits_uop_psrc_1(io_enq_2_bits_uop_psrc_1),
    .io_enq_2_bits_uop_psrc_2(io_enq_2_bits_uop_psrc_2),
    .io_enq_2_bits_uop_psrc_3(io_enq_2_bits_uop_psrc_3),
    .io_enq_2_bits_uop_psrc_4(io_enq_2_bits_uop_psrc_4),
    .io_enq_2_bits_uop_pdest(io_enq_2_bits_uop_pdest),
    .io_enq_2_bits_uop_useRegCache_0(io_enq_2_bits_uop_useRegCache_0),
    .io_enq_2_bits_uop_useRegCache_1(io_enq_2_bits_uop_useRegCache_1),
    .io_enq_2_bits_uop_regCacheIdx_0(io_enq_2_bits_uop_regCacheIdx_0),
    .io_enq_2_bits_uop_regCacheIdx_1(io_enq_2_bits_uop_regCacheIdx_1),
    .io_enq_2_bits_uop_robIdx_flag(io_enq_2_bits_uop_robIdx_flag),
    .io_enq_2_bits_uop_robIdx_value(io_enq_2_bits_uop_robIdx_value),
    .io_enq_2_bits_uop_instrSize(io_enq_2_bits_uop_instrSize),
    .io_enq_2_bits_uop_dirtyFs(io_enq_2_bits_uop_dirtyFs),
    .io_enq_2_bits_uop_dirtyVs(io_enq_2_bits_uop_dirtyVs),
    .io_enq_2_bits_uop_traceBlockInPipe_itype(io_enq_2_bits_uop_traceBlockInPipe_itype),
    .io_enq_2_bits_uop_traceBlockInPipe_iretire(io_enq_2_bits_uop_traceBlockInPipe_iretire),
    .io_enq_2_bits_uop_traceBlockInPipe_ilastsize(io_enq_2_bits_uop_traceBlockInPipe_ilastsize),
    .io_enq_2_bits_uop_eliminatedMove(io_enq_2_bits_uop_eliminatedMove),
    .io_enq_2_bits_uop_snapshot(io_enq_2_bits_uop_snapshot),
    .io_enq_2_bits_uop_debugInfo_eliminatedMove(io_enq_2_bits_uop_debugInfo_eliminatedMove),
    .io_enq_2_bits_uop_debugInfo_renameTime(io_enq_2_bits_uop_debugInfo_renameTime),
    .io_enq_2_bits_uop_debugInfo_dispatchTime(io_enq_2_bits_uop_debugInfo_dispatchTime),
    .io_enq_2_bits_uop_debugInfo_enqRsTime(io_enq_2_bits_uop_debugInfo_enqRsTime),
    .io_enq_2_bits_uop_debugInfo_selectTime(io_enq_2_bits_uop_debugInfo_selectTime),
    .io_enq_2_bits_uop_debugInfo_issueTime(io_enq_2_bits_uop_debugInfo_issueTime),
    .io_enq_2_bits_uop_debugInfo_writebackTime(io_enq_2_bits_uop_debugInfo_writebackTime),
    .io_enq_2_bits_uop_debugInfo_runahead_checkpoint_id(io_enq_2_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_enq_2_bits_uop_debugInfo_tlbFirstReqTime(io_enq_2_bits_uop_debugInfo_tlbFirstReqTime),
    .io_enq_2_bits_uop_debugInfo_tlbRespTime(io_enq_2_bits_uop_debugInfo_tlbRespTime),
    .io_enq_2_bits_uop_debug_seqNum_seqNum(io_enq_2_bits_uop_debug_seqNum_seqNum),
    .io_enq_2_bits_uop_debug_seqNum_uopIdx(io_enq_2_bits_uop_debug_seqNum_uopIdx),
    .io_enq_2_bits_uop_storeSetHit(io_enq_2_bits_uop_storeSetHit),
    .io_enq_2_bits_uop_waitForRobIdx_flag(io_enq_2_bits_uop_waitForRobIdx_flag),
    .io_enq_2_bits_uop_waitForRobIdx_value(io_enq_2_bits_uop_waitForRobIdx_value),
    .io_enq_2_bits_uop_loadWaitBit(io_enq_2_bits_uop_loadWaitBit),
    .io_enq_2_bits_uop_loadWaitStrict(io_enq_2_bits_uop_loadWaitStrict),
    .io_enq_2_bits_uop_ssid(io_enq_2_bits_uop_ssid),
    .io_enq_2_bits_uop_lqIdx_flag(io_enq_2_bits_uop_lqIdx_flag),
    .io_enq_2_bits_uop_lqIdx_value(io_enq_2_bits_uop_lqIdx_value),
    .io_enq_2_bits_uop_sqIdx_flag(io_enq_2_bits_uop_sqIdx_flag),
    .io_enq_2_bits_uop_sqIdx_value(io_enq_2_bits_uop_sqIdx_value),
    .io_enq_2_bits_uop_singleStep(io_enq_2_bits_uop_singleStep),
    .io_enq_2_bits_uop_debug_fuType(io_enq_2_bits_uop_debug_fuType),
    .io_enq_2_bits_uop_debug_sim_trig(io_enq_2_bits_uop_debug_sim_trig),
    .io_enq_2_bits_uop_numLsElem(io_enq_2_bits_uop_numLsElem),
    .io_enq_2_bits_vaddr(io_enq_2_bits_vaddr),
    .io_enq_2_bits_mask(io_enq_2_bits_mask),
    .io_enq_2_bits_isvec(io_enq_2_bits_isvec),
    .io_enq_2_bits_is128bit(io_enq_2_bits_is128bit),
    .io_enq_2_bits_elemIdx(io_enq_2_bits_elemIdx),
    .io_enq_2_bits_alignedType(io_enq_2_bits_alignedType),
    .io_enq_2_bits_mbIndex(io_enq_2_bits_mbIndex),
    .io_enq_2_bits_reg_offset(io_enq_2_bits_reg_offset),
    .io_enq_2_bits_elemIdxInsideVd(io_enq_2_bits_elemIdxInsideVd),
    .io_enq_2_bits_vecActive(io_enq_2_bits_vecActive),
    .io_enq_2_bits_isLoadReplay(io_enq_2_bits_isLoadReplay),
    .io_enq_2_bits_handledByMSHR(io_enq_2_bits_handledByMSHR),
    .io_enq_2_bits_schedIndex(io_enq_2_bits_schedIndex),
    .io_enq_2_bits_rep_info_mshr_id(io_enq_2_bits_rep_info_mshr_id),
    .io_enq_2_bits_rep_info_full_fwd(io_enq_2_bits_rep_info_full_fwd),
    .io_enq_2_bits_rep_info_data_inv_sq_idx_flag(io_enq_2_bits_rep_info_data_inv_sq_idx_flag),
    .io_enq_2_bits_rep_info_data_inv_sq_idx_value(io_enq_2_bits_rep_info_data_inv_sq_idx_value),
    .io_enq_2_bits_rep_info_addr_inv_sq_idx_flag(io_enq_2_bits_rep_info_addr_inv_sq_idx_flag),
    .io_enq_2_bits_rep_info_addr_inv_sq_idx_value(io_enq_2_bits_rep_info_addr_inv_sq_idx_value),
    .io_enq_2_bits_rep_info_last_beat(io_enq_2_bits_rep_info_last_beat),
    .io_enq_2_bits_rep_info_cause_0(io_enq_2_bits_rep_info_cause_0),
    .io_enq_2_bits_rep_info_cause_1(io_enq_2_bits_rep_info_cause_1),
    .io_enq_2_bits_rep_info_cause_2(io_enq_2_bits_rep_info_cause_2),
    .io_enq_2_bits_rep_info_cause_3(io_enq_2_bits_rep_info_cause_3),
    .io_enq_2_bits_rep_info_cause_4(io_enq_2_bits_rep_info_cause_4),
    .io_enq_2_bits_rep_info_cause_5(io_enq_2_bits_rep_info_cause_5),
    .io_enq_2_bits_rep_info_cause_6(io_enq_2_bits_rep_info_cause_6),
    .io_enq_2_bits_rep_info_cause_7(io_enq_2_bits_rep_info_cause_7),
    .io_enq_2_bits_rep_info_cause_8(io_enq_2_bits_rep_info_cause_8),
    .io_enq_2_bits_rep_info_cause_9(io_enq_2_bits_rep_info_cause_9),
    .io_enq_2_bits_rep_info_cause_10(io_enq_2_bits_rep_info_cause_10),
    .io_enq_2_bits_rep_info_tlb_id(io_enq_2_bits_rep_info_tlb_id),
    .io_enq_2_bits_rep_info_tlb_full(io_enq_2_bits_rep_info_tlb_full),
    .io_storeAddrIn_0_valid(io_storeAddrIn_0_valid),
    .io_storeAddrIn_0_bits_uop_sqIdx_flag(io_storeAddrIn_0_bits_uop_sqIdx_flag),
    .io_storeAddrIn_0_bits_uop_sqIdx_value(io_storeAddrIn_0_bits_uop_sqIdx_value),
    .io_storeAddrIn_0_bits_miss(io_storeAddrIn_0_bits_miss),
    .io_storeAddrIn_1_valid(io_storeAddrIn_1_valid),
    .io_storeAddrIn_1_bits_uop_sqIdx_flag(io_storeAddrIn_1_bits_uop_sqIdx_flag),
    .io_storeAddrIn_1_bits_uop_sqIdx_value(io_storeAddrIn_1_bits_uop_sqIdx_value),
    .io_storeAddrIn_1_bits_miss(io_storeAddrIn_1_bits_miss),
    .io_storeDataIn_0_valid(io_storeDataIn_0_valid),
    .io_storeDataIn_0_bits_uop_sqIdx_flag(io_storeDataIn_0_bits_uop_sqIdx_flag),
    .io_storeDataIn_0_bits_uop_sqIdx_value(io_storeDataIn_0_bits_uop_sqIdx_value),
    .io_storeDataIn_1_valid(io_storeDataIn_1_valid),
    .io_storeDataIn_1_bits_uop_sqIdx_flag(io_storeDataIn_1_bits_uop_sqIdx_flag),
    .io_storeDataIn_1_bits_uop_sqIdx_value(io_storeDataIn_1_bits_uop_sqIdx_value),
    .io_replay_0_ready(io_replay_0_ready),
    .io_replay_1_ready(io_replay_1_ready),
    .io_replay_2_ready(io_replay_2_ready),
    .io_tl_d_channel_valid(io_tl_d_channel_valid),
    .io_tl_d_channel_mshrid(io_tl_d_channel_mshrid),
    .io_stAddrReadySqPtr_flag(io_stAddrReadySqPtr_flag),
    .io_stAddrReadySqPtr_value(io_stAddrReadySqPtr_value),
    .io_stAddrReadyVec_0(io_stAddrReadyVec_0),
    .io_stAddrReadyVec_1(io_stAddrReadyVec_1),
    .io_stAddrReadyVec_2(io_stAddrReadyVec_2),
    .io_stAddrReadyVec_3(io_stAddrReadyVec_3),
    .io_stAddrReadyVec_4(io_stAddrReadyVec_4),
    .io_stAddrReadyVec_5(io_stAddrReadyVec_5),
    .io_stAddrReadyVec_6(io_stAddrReadyVec_6),
    .io_stAddrReadyVec_7(io_stAddrReadyVec_7),
    .io_stAddrReadyVec_8(io_stAddrReadyVec_8),
    .io_stAddrReadyVec_9(io_stAddrReadyVec_9),
    .io_stAddrReadyVec_10(io_stAddrReadyVec_10),
    .io_stAddrReadyVec_11(io_stAddrReadyVec_11),
    .io_stAddrReadyVec_12(io_stAddrReadyVec_12),
    .io_stAddrReadyVec_13(io_stAddrReadyVec_13),
    .io_stAddrReadyVec_14(io_stAddrReadyVec_14),
    .io_stAddrReadyVec_15(io_stAddrReadyVec_15),
    .io_stAddrReadyVec_16(io_stAddrReadyVec_16),
    .io_stAddrReadyVec_17(io_stAddrReadyVec_17),
    .io_stAddrReadyVec_18(io_stAddrReadyVec_18),
    .io_stAddrReadyVec_19(io_stAddrReadyVec_19),
    .io_stAddrReadyVec_20(io_stAddrReadyVec_20),
    .io_stAddrReadyVec_21(io_stAddrReadyVec_21),
    .io_stAddrReadyVec_22(io_stAddrReadyVec_22),
    .io_stAddrReadyVec_23(io_stAddrReadyVec_23),
    .io_stAddrReadyVec_24(io_stAddrReadyVec_24),
    .io_stAddrReadyVec_25(io_stAddrReadyVec_25),
    .io_stAddrReadyVec_26(io_stAddrReadyVec_26),
    .io_stAddrReadyVec_27(io_stAddrReadyVec_27),
    .io_stAddrReadyVec_28(io_stAddrReadyVec_28),
    .io_stAddrReadyVec_29(io_stAddrReadyVec_29),
    .io_stAddrReadyVec_30(io_stAddrReadyVec_30),
    .io_stAddrReadyVec_31(io_stAddrReadyVec_31),
    .io_stAddrReadyVec_32(io_stAddrReadyVec_32),
    .io_stAddrReadyVec_33(io_stAddrReadyVec_33),
    .io_stAddrReadyVec_34(io_stAddrReadyVec_34),
    .io_stAddrReadyVec_35(io_stAddrReadyVec_35),
    .io_stAddrReadyVec_36(io_stAddrReadyVec_36),
    .io_stAddrReadyVec_37(io_stAddrReadyVec_37),
    .io_stAddrReadyVec_38(io_stAddrReadyVec_38),
    .io_stAddrReadyVec_39(io_stAddrReadyVec_39),
    .io_stAddrReadyVec_40(io_stAddrReadyVec_40),
    .io_stAddrReadyVec_41(io_stAddrReadyVec_41),
    .io_stAddrReadyVec_42(io_stAddrReadyVec_42),
    .io_stAddrReadyVec_43(io_stAddrReadyVec_43),
    .io_stAddrReadyVec_44(io_stAddrReadyVec_44),
    .io_stAddrReadyVec_45(io_stAddrReadyVec_45),
    .io_stAddrReadyVec_46(io_stAddrReadyVec_46),
    .io_stAddrReadyVec_47(io_stAddrReadyVec_47),
    .io_stAddrReadyVec_48(io_stAddrReadyVec_48),
    .io_stAddrReadyVec_49(io_stAddrReadyVec_49),
    .io_stAddrReadyVec_50(io_stAddrReadyVec_50),
    .io_stAddrReadyVec_51(io_stAddrReadyVec_51),
    .io_stAddrReadyVec_52(io_stAddrReadyVec_52),
    .io_stAddrReadyVec_53(io_stAddrReadyVec_53),
    .io_stAddrReadyVec_54(io_stAddrReadyVec_54),
    .io_stAddrReadyVec_55(io_stAddrReadyVec_55),
    .io_stDataReadySqPtr_flag(io_stDataReadySqPtr_flag),
    .io_stDataReadySqPtr_value(io_stDataReadySqPtr_value),
    .io_stDataReadyVec_0(io_stDataReadyVec_0),
    .io_stDataReadyVec_1(io_stDataReadyVec_1),
    .io_stDataReadyVec_2(io_stDataReadyVec_2),
    .io_stDataReadyVec_3(io_stDataReadyVec_3),
    .io_stDataReadyVec_4(io_stDataReadyVec_4),
    .io_stDataReadyVec_5(io_stDataReadyVec_5),
    .io_stDataReadyVec_6(io_stDataReadyVec_6),
    .io_stDataReadyVec_7(io_stDataReadyVec_7),
    .io_stDataReadyVec_8(io_stDataReadyVec_8),
    .io_stDataReadyVec_9(io_stDataReadyVec_9),
    .io_stDataReadyVec_10(io_stDataReadyVec_10),
    .io_stDataReadyVec_11(io_stDataReadyVec_11),
    .io_stDataReadyVec_12(io_stDataReadyVec_12),
    .io_stDataReadyVec_13(io_stDataReadyVec_13),
    .io_stDataReadyVec_14(io_stDataReadyVec_14),
    .io_stDataReadyVec_15(io_stDataReadyVec_15),
    .io_stDataReadyVec_16(io_stDataReadyVec_16),
    .io_stDataReadyVec_17(io_stDataReadyVec_17),
    .io_stDataReadyVec_18(io_stDataReadyVec_18),
    .io_stDataReadyVec_19(io_stDataReadyVec_19),
    .io_stDataReadyVec_20(io_stDataReadyVec_20),
    .io_stDataReadyVec_21(io_stDataReadyVec_21),
    .io_stDataReadyVec_22(io_stDataReadyVec_22),
    .io_stDataReadyVec_23(io_stDataReadyVec_23),
    .io_stDataReadyVec_24(io_stDataReadyVec_24),
    .io_stDataReadyVec_25(io_stDataReadyVec_25),
    .io_stDataReadyVec_26(io_stDataReadyVec_26),
    .io_stDataReadyVec_27(io_stDataReadyVec_27),
    .io_stDataReadyVec_28(io_stDataReadyVec_28),
    .io_stDataReadyVec_29(io_stDataReadyVec_29),
    .io_stDataReadyVec_30(io_stDataReadyVec_30),
    .io_stDataReadyVec_31(io_stDataReadyVec_31),
    .io_stDataReadyVec_32(io_stDataReadyVec_32),
    .io_stDataReadyVec_33(io_stDataReadyVec_33),
    .io_stDataReadyVec_34(io_stDataReadyVec_34),
    .io_stDataReadyVec_35(io_stDataReadyVec_35),
    .io_stDataReadyVec_36(io_stDataReadyVec_36),
    .io_stDataReadyVec_37(io_stDataReadyVec_37),
    .io_stDataReadyVec_38(io_stDataReadyVec_38),
    .io_stDataReadyVec_39(io_stDataReadyVec_39),
    .io_stDataReadyVec_40(io_stDataReadyVec_40),
    .io_stDataReadyVec_41(io_stDataReadyVec_41),
    .io_stDataReadyVec_42(io_stDataReadyVec_42),
    .io_stDataReadyVec_43(io_stDataReadyVec_43),
    .io_stDataReadyVec_44(io_stDataReadyVec_44),
    .io_stDataReadyVec_45(io_stDataReadyVec_45),
    .io_stDataReadyVec_46(io_stDataReadyVec_46),
    .io_stDataReadyVec_47(io_stDataReadyVec_47),
    .io_stDataReadyVec_48(io_stDataReadyVec_48),
    .io_stDataReadyVec_49(io_stDataReadyVec_49),
    .io_stDataReadyVec_50(io_stDataReadyVec_50),
    .io_stDataReadyVec_51(io_stDataReadyVec_51),
    .io_stDataReadyVec_52(io_stDataReadyVec_52),
    .io_stDataReadyVec_53(io_stDataReadyVec_53),
    .io_stDataReadyVec_54(io_stDataReadyVec_54),
    .io_stDataReadyVec_55(io_stDataReadyVec_55),
    .io_sqEmpty(io_sqEmpty),
    .io_ldWbPtr_flag(io_ldWbPtr_flag),
    .io_ldWbPtr_value(io_ldWbPtr_value),
    .io_robDeqPtr_flag(io_robDeqPtr_flag),
    .io_robDeqPtr_value(io_robDeqPtr_value),
    .io_rarFull(io_rarFull),
    .io_rawFull(io_rawFull),
    .io_l2_hint_valid(io_l2_hint_valid),
    .io_l2_hint_bits_sourceId(io_l2_hint_bits_sourceId),
    .io_l2_hint_bits_isKeyword(io_l2_hint_bits_isKeyword),
    .io_tlb_hint_resp_valid(io_tlb_hint_resp_valid),
    .io_tlb_hint_resp_bits_id(io_tlb_hint_resp_bits_id),
    .io_tlb_hint_resp_bits_replay_all(io_tlb_hint_resp_bits_replay_all),
    .io_debugTopDown_robHeadVaddr_valid(io_debugTopDown_robHeadVaddr_valid),
    .io_debugTopDown_robHeadVaddr_bits(io_debugTopDown_robHeadVaddr_bits),
    .io_debugTopDown_robHeadMissInDTlb(io_debugTopDown_robHeadMissInDTlb),
    .io_replay_0_valid(g_io_replay_0_valid),
    .io_replay_0_bits_uop_instr(g_io_replay_0_bits_uop_instr),
    .io_replay_0_bits_uop_pc(g_io_replay_0_bits_uop_pc),
    .io_replay_0_bits_uop_foldpc(g_io_replay_0_bits_uop_foldpc),
    .io_replay_0_bits_uop_exceptionVec_0(g_io_replay_0_bits_uop_exceptionVec_0),
    .io_replay_0_bits_uop_exceptionVec_1(g_io_replay_0_bits_uop_exceptionVec_1),
    .io_replay_0_bits_uop_exceptionVec_2(g_io_replay_0_bits_uop_exceptionVec_2),
    .io_replay_0_bits_uop_exceptionVec_3(g_io_replay_0_bits_uop_exceptionVec_3),
    .io_replay_0_bits_uop_exceptionVec_5(g_io_replay_0_bits_uop_exceptionVec_5),
    .io_replay_0_bits_uop_exceptionVec_6(g_io_replay_0_bits_uop_exceptionVec_6),
    .io_replay_0_bits_uop_exceptionVec_7(g_io_replay_0_bits_uop_exceptionVec_7),
    .io_replay_0_bits_uop_exceptionVec_8(g_io_replay_0_bits_uop_exceptionVec_8),
    .io_replay_0_bits_uop_exceptionVec_9(g_io_replay_0_bits_uop_exceptionVec_9),
    .io_replay_0_bits_uop_exceptionVec_10(g_io_replay_0_bits_uop_exceptionVec_10),
    .io_replay_0_bits_uop_exceptionVec_11(g_io_replay_0_bits_uop_exceptionVec_11),
    .io_replay_0_bits_uop_exceptionVec_12(g_io_replay_0_bits_uop_exceptionVec_12),
    .io_replay_0_bits_uop_exceptionVec_13(g_io_replay_0_bits_uop_exceptionVec_13),
    .io_replay_0_bits_uop_exceptionVec_14(g_io_replay_0_bits_uop_exceptionVec_14),
    .io_replay_0_bits_uop_exceptionVec_15(g_io_replay_0_bits_uop_exceptionVec_15),
    .io_replay_0_bits_uop_exceptionVec_16(g_io_replay_0_bits_uop_exceptionVec_16),
    .io_replay_0_bits_uop_exceptionVec_17(g_io_replay_0_bits_uop_exceptionVec_17),
    .io_replay_0_bits_uop_exceptionVec_18(g_io_replay_0_bits_uop_exceptionVec_18),
    .io_replay_0_bits_uop_exceptionVec_19(g_io_replay_0_bits_uop_exceptionVec_19),
    .io_replay_0_bits_uop_exceptionVec_20(g_io_replay_0_bits_uop_exceptionVec_20),
    .io_replay_0_bits_uop_exceptionVec_21(g_io_replay_0_bits_uop_exceptionVec_21),
    .io_replay_0_bits_uop_exceptionVec_22(g_io_replay_0_bits_uop_exceptionVec_22),
    .io_replay_0_bits_uop_exceptionVec_23(g_io_replay_0_bits_uop_exceptionVec_23),
    .io_replay_0_bits_uop_isFetchMalAddr(g_io_replay_0_bits_uop_isFetchMalAddr),
    .io_replay_0_bits_uop_hasException(g_io_replay_0_bits_uop_hasException),
    .io_replay_0_bits_uop_trigger(g_io_replay_0_bits_uop_trigger),
    .io_replay_0_bits_uop_preDecodeInfo_valid(g_io_replay_0_bits_uop_preDecodeInfo_valid),
    .io_replay_0_bits_uop_preDecodeInfo_isRVC(g_io_replay_0_bits_uop_preDecodeInfo_isRVC),
    .io_replay_0_bits_uop_preDecodeInfo_brType(g_io_replay_0_bits_uop_preDecodeInfo_brType),
    .io_replay_0_bits_uop_preDecodeInfo_isCall(g_io_replay_0_bits_uop_preDecodeInfo_isCall),
    .io_replay_0_bits_uop_preDecodeInfo_isRet(g_io_replay_0_bits_uop_preDecodeInfo_isRet),
    .io_replay_0_bits_uop_pred_taken(g_io_replay_0_bits_uop_pred_taken),
    .io_replay_0_bits_uop_crossPageIPFFix(g_io_replay_0_bits_uop_crossPageIPFFix),
    .io_replay_0_bits_uop_ftqPtr_flag(g_io_replay_0_bits_uop_ftqPtr_flag),
    .io_replay_0_bits_uop_ftqPtr_value(g_io_replay_0_bits_uop_ftqPtr_value),
    .io_replay_0_bits_uop_ftqOffset(g_io_replay_0_bits_uop_ftqOffset),
    .io_replay_0_bits_uop_satpFlushFirstFetchFault(g_io_replay_0_bits_uop_satpFlushFirstFetchFault),
    .io_replay_0_bits_uop_srcType_0(g_io_replay_0_bits_uop_srcType_0),
    .io_replay_0_bits_uop_srcType_1(g_io_replay_0_bits_uop_srcType_1),
    .io_replay_0_bits_uop_srcType_2(g_io_replay_0_bits_uop_srcType_2),
    .io_replay_0_bits_uop_srcType_3(g_io_replay_0_bits_uop_srcType_3),
    .io_replay_0_bits_uop_srcType_4(g_io_replay_0_bits_uop_srcType_4),
    .io_replay_0_bits_uop_ldest(g_io_replay_0_bits_uop_ldest),
    .io_replay_0_bits_uop_fuType(g_io_replay_0_bits_uop_fuType),
    .io_replay_0_bits_uop_fuOpType(g_io_replay_0_bits_uop_fuOpType),
    .io_replay_0_bits_uop_rfWen(g_io_replay_0_bits_uop_rfWen),
    .io_replay_0_bits_uop_fpWen(g_io_replay_0_bits_uop_fpWen),
    .io_replay_0_bits_uop_vecWen(g_io_replay_0_bits_uop_vecWen),
    .io_replay_0_bits_uop_v0Wen(g_io_replay_0_bits_uop_v0Wen),
    .io_replay_0_bits_uop_vlWen(g_io_replay_0_bits_uop_vlWen),
    .io_replay_0_bits_uop_isXSTrap(g_io_replay_0_bits_uop_isXSTrap),
    .io_replay_0_bits_uop_waitForward(g_io_replay_0_bits_uop_waitForward),
    .io_replay_0_bits_uop_blockBackward(g_io_replay_0_bits_uop_blockBackward),
    .io_replay_0_bits_uop_canRobCompress(g_io_replay_0_bits_uop_canRobCompress),
    .io_replay_0_bits_uop_selImm(g_io_replay_0_bits_uop_selImm),
    .io_replay_0_bits_uop_imm(g_io_replay_0_bits_uop_imm),
    .io_replay_0_bits_uop_fpu_typeTagOut(g_io_replay_0_bits_uop_fpu_typeTagOut),
    .io_replay_0_bits_uop_fpu_wflags(g_io_replay_0_bits_uop_fpu_wflags),
    .io_replay_0_bits_uop_fpu_typ(g_io_replay_0_bits_uop_fpu_typ),
    .io_replay_0_bits_uop_fpu_fmt(g_io_replay_0_bits_uop_fpu_fmt),
    .io_replay_0_bits_uop_fpu_rm(g_io_replay_0_bits_uop_fpu_rm),
    .io_replay_0_bits_uop_vpu_vill(g_io_replay_0_bits_uop_vpu_vill),
    .io_replay_0_bits_uop_vpu_vma(g_io_replay_0_bits_uop_vpu_vma),
    .io_replay_0_bits_uop_vpu_vta(g_io_replay_0_bits_uop_vpu_vta),
    .io_replay_0_bits_uop_vpu_vsew(g_io_replay_0_bits_uop_vpu_vsew),
    .io_replay_0_bits_uop_vpu_vlmul(g_io_replay_0_bits_uop_vpu_vlmul),
    .io_replay_0_bits_uop_vpu_specVill(g_io_replay_0_bits_uop_vpu_specVill),
    .io_replay_0_bits_uop_vpu_specVma(g_io_replay_0_bits_uop_vpu_specVma),
    .io_replay_0_bits_uop_vpu_specVta(g_io_replay_0_bits_uop_vpu_specVta),
    .io_replay_0_bits_uop_vpu_specVsew(g_io_replay_0_bits_uop_vpu_specVsew),
    .io_replay_0_bits_uop_vpu_specVlmul(g_io_replay_0_bits_uop_vpu_specVlmul),
    .io_replay_0_bits_uop_vpu_vm(g_io_replay_0_bits_uop_vpu_vm),
    .io_replay_0_bits_uop_vpu_vstart(g_io_replay_0_bits_uop_vpu_vstart),
    .io_replay_0_bits_uop_vpu_frm(g_io_replay_0_bits_uop_vpu_frm),
    .io_replay_0_bits_uop_vpu_fpu_isFpToVecInst(g_io_replay_0_bits_uop_vpu_fpu_isFpToVecInst),
    .io_replay_0_bits_uop_vpu_fpu_isFP32Instr(g_io_replay_0_bits_uop_vpu_fpu_isFP32Instr),
    .io_replay_0_bits_uop_vpu_fpu_isFP64Instr(g_io_replay_0_bits_uop_vpu_fpu_isFP64Instr),
    .io_replay_0_bits_uop_vpu_fpu_isReduction(g_io_replay_0_bits_uop_vpu_fpu_isReduction),
    .io_replay_0_bits_uop_vpu_fpu_isFoldTo1_2(g_io_replay_0_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_replay_0_bits_uop_vpu_fpu_isFoldTo1_4(g_io_replay_0_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_replay_0_bits_uop_vpu_fpu_isFoldTo1_8(g_io_replay_0_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_replay_0_bits_uop_vpu_vxrm(g_io_replay_0_bits_uop_vpu_vxrm),
    .io_replay_0_bits_uop_vpu_vuopIdx(g_io_replay_0_bits_uop_vpu_vuopIdx),
    .io_replay_0_bits_uop_vpu_lastUop(g_io_replay_0_bits_uop_vpu_lastUop),
    .io_replay_0_bits_uop_vpu_vmask(g_io_replay_0_bits_uop_vpu_vmask),
    .io_replay_0_bits_uop_vpu_vl(g_io_replay_0_bits_uop_vpu_vl),
    .io_replay_0_bits_uop_vpu_nf(g_io_replay_0_bits_uop_vpu_nf),
    .io_replay_0_bits_uop_vpu_veew(g_io_replay_0_bits_uop_vpu_veew),
    .io_replay_0_bits_uop_vpu_isReverse(g_io_replay_0_bits_uop_vpu_isReverse),
    .io_replay_0_bits_uop_vpu_isExt(g_io_replay_0_bits_uop_vpu_isExt),
    .io_replay_0_bits_uop_vpu_isNarrow(g_io_replay_0_bits_uop_vpu_isNarrow),
    .io_replay_0_bits_uop_vpu_isDstMask(g_io_replay_0_bits_uop_vpu_isDstMask),
    .io_replay_0_bits_uop_vpu_isOpMask(g_io_replay_0_bits_uop_vpu_isOpMask),
    .io_replay_0_bits_uop_vpu_isMove(g_io_replay_0_bits_uop_vpu_isMove),
    .io_replay_0_bits_uop_vpu_isDependOldVd(g_io_replay_0_bits_uop_vpu_isDependOldVd),
    .io_replay_0_bits_uop_vpu_isWritePartVd(g_io_replay_0_bits_uop_vpu_isWritePartVd),
    .io_replay_0_bits_uop_vpu_isVleff(g_io_replay_0_bits_uop_vpu_isVleff),
    .io_replay_0_bits_uop_vlsInstr(g_io_replay_0_bits_uop_vlsInstr),
    .io_replay_0_bits_uop_wfflags(g_io_replay_0_bits_uop_wfflags),
    .io_replay_0_bits_uop_isMove(g_io_replay_0_bits_uop_isMove),
    .io_replay_0_bits_uop_isDropAmocasSta(g_io_replay_0_bits_uop_isDropAmocasSta),
    .io_replay_0_bits_uop_uopIdx(g_io_replay_0_bits_uop_uopIdx),
    .io_replay_0_bits_uop_isVset(g_io_replay_0_bits_uop_isVset),
    .io_replay_0_bits_uop_firstUop(g_io_replay_0_bits_uop_firstUop),
    .io_replay_0_bits_uop_lastUop(g_io_replay_0_bits_uop_lastUop),
    .io_replay_0_bits_uop_numUops(g_io_replay_0_bits_uop_numUops),
    .io_replay_0_bits_uop_numWB(g_io_replay_0_bits_uop_numWB),
    .io_replay_0_bits_uop_commitType(g_io_replay_0_bits_uop_commitType),
    .io_replay_0_bits_uop_srcState_0(g_io_replay_0_bits_uop_srcState_0),
    .io_replay_0_bits_uop_srcState_1(g_io_replay_0_bits_uop_srcState_1),
    .io_replay_0_bits_uop_srcState_2(g_io_replay_0_bits_uop_srcState_2),
    .io_replay_0_bits_uop_srcState_3(g_io_replay_0_bits_uop_srcState_3),
    .io_replay_0_bits_uop_srcState_4(g_io_replay_0_bits_uop_srcState_4),
    .io_replay_0_bits_uop_srcLoadDependency_0_0(g_io_replay_0_bits_uop_srcLoadDependency_0_0),
    .io_replay_0_bits_uop_srcLoadDependency_0_1(g_io_replay_0_bits_uop_srcLoadDependency_0_1),
    .io_replay_0_bits_uop_srcLoadDependency_0_2(g_io_replay_0_bits_uop_srcLoadDependency_0_2),
    .io_replay_0_bits_uop_srcLoadDependency_1_0(g_io_replay_0_bits_uop_srcLoadDependency_1_0),
    .io_replay_0_bits_uop_srcLoadDependency_1_1(g_io_replay_0_bits_uop_srcLoadDependency_1_1),
    .io_replay_0_bits_uop_srcLoadDependency_1_2(g_io_replay_0_bits_uop_srcLoadDependency_1_2),
    .io_replay_0_bits_uop_srcLoadDependency_2_0(g_io_replay_0_bits_uop_srcLoadDependency_2_0),
    .io_replay_0_bits_uop_srcLoadDependency_2_1(g_io_replay_0_bits_uop_srcLoadDependency_2_1),
    .io_replay_0_bits_uop_srcLoadDependency_2_2(g_io_replay_0_bits_uop_srcLoadDependency_2_2),
    .io_replay_0_bits_uop_srcLoadDependency_3_0(g_io_replay_0_bits_uop_srcLoadDependency_3_0),
    .io_replay_0_bits_uop_srcLoadDependency_3_1(g_io_replay_0_bits_uop_srcLoadDependency_3_1),
    .io_replay_0_bits_uop_srcLoadDependency_3_2(g_io_replay_0_bits_uop_srcLoadDependency_3_2),
    .io_replay_0_bits_uop_srcLoadDependency_4_0(g_io_replay_0_bits_uop_srcLoadDependency_4_0),
    .io_replay_0_bits_uop_srcLoadDependency_4_1(g_io_replay_0_bits_uop_srcLoadDependency_4_1),
    .io_replay_0_bits_uop_srcLoadDependency_4_2(g_io_replay_0_bits_uop_srcLoadDependency_4_2),
    .io_replay_0_bits_uop_psrc_0(g_io_replay_0_bits_uop_psrc_0),
    .io_replay_0_bits_uop_psrc_1(g_io_replay_0_bits_uop_psrc_1),
    .io_replay_0_bits_uop_psrc_2(g_io_replay_0_bits_uop_psrc_2),
    .io_replay_0_bits_uop_psrc_3(g_io_replay_0_bits_uop_psrc_3),
    .io_replay_0_bits_uop_psrc_4(g_io_replay_0_bits_uop_psrc_4),
    .io_replay_0_bits_uop_pdest(g_io_replay_0_bits_uop_pdest),
    .io_replay_0_bits_uop_useRegCache_0(g_io_replay_0_bits_uop_useRegCache_0),
    .io_replay_0_bits_uop_useRegCache_1(g_io_replay_0_bits_uop_useRegCache_1),
    .io_replay_0_bits_uop_regCacheIdx_0(g_io_replay_0_bits_uop_regCacheIdx_0),
    .io_replay_0_bits_uop_regCacheIdx_1(g_io_replay_0_bits_uop_regCacheIdx_1),
    .io_replay_0_bits_uop_robIdx_flag(g_io_replay_0_bits_uop_robIdx_flag),
    .io_replay_0_bits_uop_robIdx_value(g_io_replay_0_bits_uop_robIdx_value),
    .io_replay_0_bits_uop_instrSize(g_io_replay_0_bits_uop_instrSize),
    .io_replay_0_bits_uop_dirtyFs(g_io_replay_0_bits_uop_dirtyFs),
    .io_replay_0_bits_uop_dirtyVs(g_io_replay_0_bits_uop_dirtyVs),
    .io_replay_0_bits_uop_traceBlockInPipe_itype(g_io_replay_0_bits_uop_traceBlockInPipe_itype),
    .io_replay_0_bits_uop_traceBlockInPipe_iretire(g_io_replay_0_bits_uop_traceBlockInPipe_iretire),
    .io_replay_0_bits_uop_traceBlockInPipe_ilastsize(g_io_replay_0_bits_uop_traceBlockInPipe_ilastsize),
    .io_replay_0_bits_uop_eliminatedMove(g_io_replay_0_bits_uop_eliminatedMove),
    .io_replay_0_bits_uop_snapshot(g_io_replay_0_bits_uop_snapshot),
    .io_replay_0_bits_uop_debugInfo_eliminatedMove(g_io_replay_0_bits_uop_debugInfo_eliminatedMove),
    .io_replay_0_bits_uop_debugInfo_renameTime(g_io_replay_0_bits_uop_debugInfo_renameTime),
    .io_replay_0_bits_uop_debugInfo_dispatchTime(g_io_replay_0_bits_uop_debugInfo_dispatchTime),
    .io_replay_0_bits_uop_debugInfo_enqRsTime(g_io_replay_0_bits_uop_debugInfo_enqRsTime),
    .io_replay_0_bits_uop_debugInfo_selectTime(g_io_replay_0_bits_uop_debugInfo_selectTime),
    .io_replay_0_bits_uop_debugInfo_issueTime(g_io_replay_0_bits_uop_debugInfo_issueTime),
    .io_replay_0_bits_uop_debugInfo_writebackTime(g_io_replay_0_bits_uop_debugInfo_writebackTime),
    .io_replay_0_bits_uop_debugInfo_runahead_checkpoint_id(g_io_replay_0_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_replay_0_bits_uop_debugInfo_tlbFirstReqTime(g_io_replay_0_bits_uop_debugInfo_tlbFirstReqTime),
    .io_replay_0_bits_uop_debugInfo_tlbRespTime(g_io_replay_0_bits_uop_debugInfo_tlbRespTime),
    .io_replay_0_bits_uop_debug_seqNum_seqNum(g_io_replay_0_bits_uop_debug_seqNum_seqNum),
    .io_replay_0_bits_uop_debug_seqNum_uopIdx(g_io_replay_0_bits_uop_debug_seqNum_uopIdx),
    .io_replay_0_bits_uop_storeSetHit(g_io_replay_0_bits_uop_storeSetHit),
    .io_replay_0_bits_uop_waitForRobIdx_flag(g_io_replay_0_bits_uop_waitForRobIdx_flag),
    .io_replay_0_bits_uop_waitForRobIdx_value(g_io_replay_0_bits_uop_waitForRobIdx_value),
    .io_replay_0_bits_uop_loadWaitBit(g_io_replay_0_bits_uop_loadWaitBit),
    .io_replay_0_bits_uop_ssid(g_io_replay_0_bits_uop_ssid),
    .io_replay_0_bits_uop_lqIdx_flag(g_io_replay_0_bits_uop_lqIdx_flag),
    .io_replay_0_bits_uop_lqIdx_value(g_io_replay_0_bits_uop_lqIdx_value),
    .io_replay_0_bits_uop_sqIdx_flag(g_io_replay_0_bits_uop_sqIdx_flag),
    .io_replay_0_bits_uop_sqIdx_value(g_io_replay_0_bits_uop_sqIdx_value),
    .io_replay_0_bits_uop_singleStep(g_io_replay_0_bits_uop_singleStep),
    .io_replay_0_bits_uop_debug_fuType(g_io_replay_0_bits_uop_debug_fuType),
    .io_replay_0_bits_uop_debug_sim_trig(g_io_replay_0_bits_uop_debug_sim_trig),
    .io_replay_0_bits_uop_numLsElem(g_io_replay_0_bits_uop_numLsElem),
    .io_replay_0_bits_vaddr(g_io_replay_0_bits_vaddr),
    .io_replay_0_bits_mask(g_io_replay_0_bits_mask),
    .io_replay_0_bits_isvec(g_io_replay_0_bits_isvec),
    .io_replay_0_bits_is128bit(g_io_replay_0_bits_is128bit),
    .io_replay_0_bits_elemIdx(g_io_replay_0_bits_elemIdx),
    .io_replay_0_bits_alignedType(g_io_replay_0_bits_alignedType),
    .io_replay_0_bits_mbIndex(g_io_replay_0_bits_mbIndex),
    .io_replay_0_bits_reg_offset(g_io_replay_0_bits_reg_offset),
    .io_replay_0_bits_elemIdxInsideVd(g_io_replay_0_bits_elemIdxInsideVd),
    .io_replay_0_bits_vecActive(g_io_replay_0_bits_vecActive),
    .io_replay_0_bits_mshrid(g_io_replay_0_bits_mshrid),
    .io_replay_0_bits_forward_tlDchannel(g_io_replay_0_bits_forward_tlDchannel),
    .io_replay_0_bits_schedIndex(g_io_replay_0_bits_schedIndex),
    .io_replay_1_valid(g_io_replay_1_valid),
    .io_replay_1_bits_uop_instr(g_io_replay_1_bits_uop_instr),
    .io_replay_1_bits_uop_pc(g_io_replay_1_bits_uop_pc),
    .io_replay_1_bits_uop_foldpc(g_io_replay_1_bits_uop_foldpc),
    .io_replay_1_bits_uop_exceptionVec_0(g_io_replay_1_bits_uop_exceptionVec_0),
    .io_replay_1_bits_uop_exceptionVec_1(g_io_replay_1_bits_uop_exceptionVec_1),
    .io_replay_1_bits_uop_exceptionVec_2(g_io_replay_1_bits_uop_exceptionVec_2),
    .io_replay_1_bits_uop_exceptionVec_3(g_io_replay_1_bits_uop_exceptionVec_3),
    .io_replay_1_bits_uop_exceptionVec_5(g_io_replay_1_bits_uop_exceptionVec_5),
    .io_replay_1_bits_uop_exceptionVec_6(g_io_replay_1_bits_uop_exceptionVec_6),
    .io_replay_1_bits_uop_exceptionVec_7(g_io_replay_1_bits_uop_exceptionVec_7),
    .io_replay_1_bits_uop_exceptionVec_8(g_io_replay_1_bits_uop_exceptionVec_8),
    .io_replay_1_bits_uop_exceptionVec_9(g_io_replay_1_bits_uop_exceptionVec_9),
    .io_replay_1_bits_uop_exceptionVec_10(g_io_replay_1_bits_uop_exceptionVec_10),
    .io_replay_1_bits_uop_exceptionVec_11(g_io_replay_1_bits_uop_exceptionVec_11),
    .io_replay_1_bits_uop_exceptionVec_12(g_io_replay_1_bits_uop_exceptionVec_12),
    .io_replay_1_bits_uop_exceptionVec_13(g_io_replay_1_bits_uop_exceptionVec_13),
    .io_replay_1_bits_uop_exceptionVec_14(g_io_replay_1_bits_uop_exceptionVec_14),
    .io_replay_1_bits_uop_exceptionVec_15(g_io_replay_1_bits_uop_exceptionVec_15),
    .io_replay_1_bits_uop_exceptionVec_16(g_io_replay_1_bits_uop_exceptionVec_16),
    .io_replay_1_bits_uop_exceptionVec_17(g_io_replay_1_bits_uop_exceptionVec_17),
    .io_replay_1_bits_uop_exceptionVec_18(g_io_replay_1_bits_uop_exceptionVec_18),
    .io_replay_1_bits_uop_exceptionVec_19(g_io_replay_1_bits_uop_exceptionVec_19),
    .io_replay_1_bits_uop_exceptionVec_20(g_io_replay_1_bits_uop_exceptionVec_20),
    .io_replay_1_bits_uop_exceptionVec_21(g_io_replay_1_bits_uop_exceptionVec_21),
    .io_replay_1_bits_uop_exceptionVec_22(g_io_replay_1_bits_uop_exceptionVec_22),
    .io_replay_1_bits_uop_exceptionVec_23(g_io_replay_1_bits_uop_exceptionVec_23),
    .io_replay_1_bits_uop_isFetchMalAddr(g_io_replay_1_bits_uop_isFetchMalAddr),
    .io_replay_1_bits_uop_hasException(g_io_replay_1_bits_uop_hasException),
    .io_replay_1_bits_uop_trigger(g_io_replay_1_bits_uop_trigger),
    .io_replay_1_bits_uop_preDecodeInfo_valid(g_io_replay_1_bits_uop_preDecodeInfo_valid),
    .io_replay_1_bits_uop_preDecodeInfo_isRVC(g_io_replay_1_bits_uop_preDecodeInfo_isRVC),
    .io_replay_1_bits_uop_preDecodeInfo_brType(g_io_replay_1_bits_uop_preDecodeInfo_brType),
    .io_replay_1_bits_uop_preDecodeInfo_isCall(g_io_replay_1_bits_uop_preDecodeInfo_isCall),
    .io_replay_1_bits_uop_preDecodeInfo_isRet(g_io_replay_1_bits_uop_preDecodeInfo_isRet),
    .io_replay_1_bits_uop_pred_taken(g_io_replay_1_bits_uop_pred_taken),
    .io_replay_1_bits_uop_crossPageIPFFix(g_io_replay_1_bits_uop_crossPageIPFFix),
    .io_replay_1_bits_uop_ftqPtr_flag(g_io_replay_1_bits_uop_ftqPtr_flag),
    .io_replay_1_bits_uop_ftqPtr_value(g_io_replay_1_bits_uop_ftqPtr_value),
    .io_replay_1_bits_uop_ftqOffset(g_io_replay_1_bits_uop_ftqOffset),
    .io_replay_1_bits_uop_satpFlushFirstFetchFault(g_io_replay_1_bits_uop_satpFlushFirstFetchFault),
    .io_replay_1_bits_uop_srcType_0(g_io_replay_1_bits_uop_srcType_0),
    .io_replay_1_bits_uop_srcType_1(g_io_replay_1_bits_uop_srcType_1),
    .io_replay_1_bits_uop_srcType_2(g_io_replay_1_bits_uop_srcType_2),
    .io_replay_1_bits_uop_srcType_3(g_io_replay_1_bits_uop_srcType_3),
    .io_replay_1_bits_uop_srcType_4(g_io_replay_1_bits_uop_srcType_4),
    .io_replay_1_bits_uop_ldest(g_io_replay_1_bits_uop_ldest),
    .io_replay_1_bits_uop_fuType(g_io_replay_1_bits_uop_fuType),
    .io_replay_1_bits_uop_fuOpType(g_io_replay_1_bits_uop_fuOpType),
    .io_replay_1_bits_uop_rfWen(g_io_replay_1_bits_uop_rfWen),
    .io_replay_1_bits_uop_fpWen(g_io_replay_1_bits_uop_fpWen),
    .io_replay_1_bits_uop_vecWen(g_io_replay_1_bits_uop_vecWen),
    .io_replay_1_bits_uop_v0Wen(g_io_replay_1_bits_uop_v0Wen),
    .io_replay_1_bits_uop_vlWen(g_io_replay_1_bits_uop_vlWen),
    .io_replay_1_bits_uop_isXSTrap(g_io_replay_1_bits_uop_isXSTrap),
    .io_replay_1_bits_uop_waitForward(g_io_replay_1_bits_uop_waitForward),
    .io_replay_1_bits_uop_blockBackward(g_io_replay_1_bits_uop_blockBackward),
    .io_replay_1_bits_uop_canRobCompress(g_io_replay_1_bits_uop_canRobCompress),
    .io_replay_1_bits_uop_selImm(g_io_replay_1_bits_uop_selImm),
    .io_replay_1_bits_uop_imm(g_io_replay_1_bits_uop_imm),
    .io_replay_1_bits_uop_fpu_typeTagOut(g_io_replay_1_bits_uop_fpu_typeTagOut),
    .io_replay_1_bits_uop_fpu_wflags(g_io_replay_1_bits_uop_fpu_wflags),
    .io_replay_1_bits_uop_fpu_typ(g_io_replay_1_bits_uop_fpu_typ),
    .io_replay_1_bits_uop_fpu_fmt(g_io_replay_1_bits_uop_fpu_fmt),
    .io_replay_1_bits_uop_fpu_rm(g_io_replay_1_bits_uop_fpu_rm),
    .io_replay_1_bits_uop_vpu_vill(g_io_replay_1_bits_uop_vpu_vill),
    .io_replay_1_bits_uop_vpu_vma(g_io_replay_1_bits_uop_vpu_vma),
    .io_replay_1_bits_uop_vpu_vta(g_io_replay_1_bits_uop_vpu_vta),
    .io_replay_1_bits_uop_vpu_vsew(g_io_replay_1_bits_uop_vpu_vsew),
    .io_replay_1_bits_uop_vpu_vlmul(g_io_replay_1_bits_uop_vpu_vlmul),
    .io_replay_1_bits_uop_vpu_specVill(g_io_replay_1_bits_uop_vpu_specVill),
    .io_replay_1_bits_uop_vpu_specVma(g_io_replay_1_bits_uop_vpu_specVma),
    .io_replay_1_bits_uop_vpu_specVta(g_io_replay_1_bits_uop_vpu_specVta),
    .io_replay_1_bits_uop_vpu_specVsew(g_io_replay_1_bits_uop_vpu_specVsew),
    .io_replay_1_bits_uop_vpu_specVlmul(g_io_replay_1_bits_uop_vpu_specVlmul),
    .io_replay_1_bits_uop_vpu_vm(g_io_replay_1_bits_uop_vpu_vm),
    .io_replay_1_bits_uop_vpu_vstart(g_io_replay_1_bits_uop_vpu_vstart),
    .io_replay_1_bits_uop_vpu_frm(g_io_replay_1_bits_uop_vpu_frm),
    .io_replay_1_bits_uop_vpu_fpu_isFpToVecInst(g_io_replay_1_bits_uop_vpu_fpu_isFpToVecInst),
    .io_replay_1_bits_uop_vpu_fpu_isFP32Instr(g_io_replay_1_bits_uop_vpu_fpu_isFP32Instr),
    .io_replay_1_bits_uop_vpu_fpu_isFP64Instr(g_io_replay_1_bits_uop_vpu_fpu_isFP64Instr),
    .io_replay_1_bits_uop_vpu_fpu_isReduction(g_io_replay_1_bits_uop_vpu_fpu_isReduction),
    .io_replay_1_bits_uop_vpu_fpu_isFoldTo1_2(g_io_replay_1_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_replay_1_bits_uop_vpu_fpu_isFoldTo1_4(g_io_replay_1_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_replay_1_bits_uop_vpu_fpu_isFoldTo1_8(g_io_replay_1_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_replay_1_bits_uop_vpu_vxrm(g_io_replay_1_bits_uop_vpu_vxrm),
    .io_replay_1_bits_uop_vpu_vuopIdx(g_io_replay_1_bits_uop_vpu_vuopIdx),
    .io_replay_1_bits_uop_vpu_lastUop(g_io_replay_1_bits_uop_vpu_lastUop),
    .io_replay_1_bits_uop_vpu_vmask(g_io_replay_1_bits_uop_vpu_vmask),
    .io_replay_1_bits_uop_vpu_vl(g_io_replay_1_bits_uop_vpu_vl),
    .io_replay_1_bits_uop_vpu_nf(g_io_replay_1_bits_uop_vpu_nf),
    .io_replay_1_bits_uop_vpu_veew(g_io_replay_1_bits_uop_vpu_veew),
    .io_replay_1_bits_uop_vpu_isReverse(g_io_replay_1_bits_uop_vpu_isReverse),
    .io_replay_1_bits_uop_vpu_isExt(g_io_replay_1_bits_uop_vpu_isExt),
    .io_replay_1_bits_uop_vpu_isNarrow(g_io_replay_1_bits_uop_vpu_isNarrow),
    .io_replay_1_bits_uop_vpu_isDstMask(g_io_replay_1_bits_uop_vpu_isDstMask),
    .io_replay_1_bits_uop_vpu_isOpMask(g_io_replay_1_bits_uop_vpu_isOpMask),
    .io_replay_1_bits_uop_vpu_isMove(g_io_replay_1_bits_uop_vpu_isMove),
    .io_replay_1_bits_uop_vpu_isDependOldVd(g_io_replay_1_bits_uop_vpu_isDependOldVd),
    .io_replay_1_bits_uop_vpu_isWritePartVd(g_io_replay_1_bits_uop_vpu_isWritePartVd),
    .io_replay_1_bits_uop_vpu_isVleff(g_io_replay_1_bits_uop_vpu_isVleff),
    .io_replay_1_bits_uop_vlsInstr(g_io_replay_1_bits_uop_vlsInstr),
    .io_replay_1_bits_uop_wfflags(g_io_replay_1_bits_uop_wfflags),
    .io_replay_1_bits_uop_isMove(g_io_replay_1_bits_uop_isMove),
    .io_replay_1_bits_uop_isDropAmocasSta(g_io_replay_1_bits_uop_isDropAmocasSta),
    .io_replay_1_bits_uop_uopIdx(g_io_replay_1_bits_uop_uopIdx),
    .io_replay_1_bits_uop_isVset(g_io_replay_1_bits_uop_isVset),
    .io_replay_1_bits_uop_firstUop(g_io_replay_1_bits_uop_firstUop),
    .io_replay_1_bits_uop_lastUop(g_io_replay_1_bits_uop_lastUop),
    .io_replay_1_bits_uop_numUops(g_io_replay_1_bits_uop_numUops),
    .io_replay_1_bits_uop_numWB(g_io_replay_1_bits_uop_numWB),
    .io_replay_1_bits_uop_commitType(g_io_replay_1_bits_uop_commitType),
    .io_replay_1_bits_uop_srcState_0(g_io_replay_1_bits_uop_srcState_0),
    .io_replay_1_bits_uop_srcState_1(g_io_replay_1_bits_uop_srcState_1),
    .io_replay_1_bits_uop_srcState_2(g_io_replay_1_bits_uop_srcState_2),
    .io_replay_1_bits_uop_srcState_3(g_io_replay_1_bits_uop_srcState_3),
    .io_replay_1_bits_uop_srcState_4(g_io_replay_1_bits_uop_srcState_4),
    .io_replay_1_bits_uop_srcLoadDependency_0_0(g_io_replay_1_bits_uop_srcLoadDependency_0_0),
    .io_replay_1_bits_uop_srcLoadDependency_0_1(g_io_replay_1_bits_uop_srcLoadDependency_0_1),
    .io_replay_1_bits_uop_srcLoadDependency_0_2(g_io_replay_1_bits_uop_srcLoadDependency_0_2),
    .io_replay_1_bits_uop_srcLoadDependency_1_0(g_io_replay_1_bits_uop_srcLoadDependency_1_0),
    .io_replay_1_bits_uop_srcLoadDependency_1_1(g_io_replay_1_bits_uop_srcLoadDependency_1_1),
    .io_replay_1_bits_uop_srcLoadDependency_1_2(g_io_replay_1_bits_uop_srcLoadDependency_1_2),
    .io_replay_1_bits_uop_srcLoadDependency_2_0(g_io_replay_1_bits_uop_srcLoadDependency_2_0),
    .io_replay_1_bits_uop_srcLoadDependency_2_1(g_io_replay_1_bits_uop_srcLoadDependency_2_1),
    .io_replay_1_bits_uop_srcLoadDependency_2_2(g_io_replay_1_bits_uop_srcLoadDependency_2_2),
    .io_replay_1_bits_uop_srcLoadDependency_3_0(g_io_replay_1_bits_uop_srcLoadDependency_3_0),
    .io_replay_1_bits_uop_srcLoadDependency_3_1(g_io_replay_1_bits_uop_srcLoadDependency_3_1),
    .io_replay_1_bits_uop_srcLoadDependency_3_2(g_io_replay_1_bits_uop_srcLoadDependency_3_2),
    .io_replay_1_bits_uop_srcLoadDependency_4_0(g_io_replay_1_bits_uop_srcLoadDependency_4_0),
    .io_replay_1_bits_uop_srcLoadDependency_4_1(g_io_replay_1_bits_uop_srcLoadDependency_4_1),
    .io_replay_1_bits_uop_srcLoadDependency_4_2(g_io_replay_1_bits_uop_srcLoadDependency_4_2),
    .io_replay_1_bits_uop_psrc_0(g_io_replay_1_bits_uop_psrc_0),
    .io_replay_1_bits_uop_psrc_1(g_io_replay_1_bits_uop_psrc_1),
    .io_replay_1_bits_uop_psrc_2(g_io_replay_1_bits_uop_psrc_2),
    .io_replay_1_bits_uop_psrc_3(g_io_replay_1_bits_uop_psrc_3),
    .io_replay_1_bits_uop_psrc_4(g_io_replay_1_bits_uop_psrc_4),
    .io_replay_1_bits_uop_pdest(g_io_replay_1_bits_uop_pdest),
    .io_replay_1_bits_uop_useRegCache_0(g_io_replay_1_bits_uop_useRegCache_0),
    .io_replay_1_bits_uop_useRegCache_1(g_io_replay_1_bits_uop_useRegCache_1),
    .io_replay_1_bits_uop_regCacheIdx_0(g_io_replay_1_bits_uop_regCacheIdx_0),
    .io_replay_1_bits_uop_regCacheIdx_1(g_io_replay_1_bits_uop_regCacheIdx_1),
    .io_replay_1_bits_uop_robIdx_flag(g_io_replay_1_bits_uop_robIdx_flag),
    .io_replay_1_bits_uop_robIdx_value(g_io_replay_1_bits_uop_robIdx_value),
    .io_replay_1_bits_uop_instrSize(g_io_replay_1_bits_uop_instrSize),
    .io_replay_1_bits_uop_dirtyFs(g_io_replay_1_bits_uop_dirtyFs),
    .io_replay_1_bits_uop_dirtyVs(g_io_replay_1_bits_uop_dirtyVs),
    .io_replay_1_bits_uop_traceBlockInPipe_itype(g_io_replay_1_bits_uop_traceBlockInPipe_itype),
    .io_replay_1_bits_uop_traceBlockInPipe_iretire(g_io_replay_1_bits_uop_traceBlockInPipe_iretire),
    .io_replay_1_bits_uop_traceBlockInPipe_ilastsize(g_io_replay_1_bits_uop_traceBlockInPipe_ilastsize),
    .io_replay_1_bits_uop_eliminatedMove(g_io_replay_1_bits_uop_eliminatedMove),
    .io_replay_1_bits_uop_snapshot(g_io_replay_1_bits_uop_snapshot),
    .io_replay_1_bits_uop_debugInfo_eliminatedMove(g_io_replay_1_bits_uop_debugInfo_eliminatedMove),
    .io_replay_1_bits_uop_debugInfo_renameTime(g_io_replay_1_bits_uop_debugInfo_renameTime),
    .io_replay_1_bits_uop_debugInfo_dispatchTime(g_io_replay_1_bits_uop_debugInfo_dispatchTime),
    .io_replay_1_bits_uop_debugInfo_enqRsTime(g_io_replay_1_bits_uop_debugInfo_enqRsTime),
    .io_replay_1_bits_uop_debugInfo_selectTime(g_io_replay_1_bits_uop_debugInfo_selectTime),
    .io_replay_1_bits_uop_debugInfo_issueTime(g_io_replay_1_bits_uop_debugInfo_issueTime),
    .io_replay_1_bits_uop_debugInfo_writebackTime(g_io_replay_1_bits_uop_debugInfo_writebackTime),
    .io_replay_1_bits_uop_debugInfo_runahead_checkpoint_id(g_io_replay_1_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_replay_1_bits_uop_debugInfo_tlbFirstReqTime(g_io_replay_1_bits_uop_debugInfo_tlbFirstReqTime),
    .io_replay_1_bits_uop_debugInfo_tlbRespTime(g_io_replay_1_bits_uop_debugInfo_tlbRespTime),
    .io_replay_1_bits_uop_debug_seqNum_seqNum(g_io_replay_1_bits_uop_debug_seqNum_seqNum),
    .io_replay_1_bits_uop_debug_seqNum_uopIdx(g_io_replay_1_bits_uop_debug_seqNum_uopIdx),
    .io_replay_1_bits_uop_storeSetHit(g_io_replay_1_bits_uop_storeSetHit),
    .io_replay_1_bits_uop_waitForRobIdx_flag(g_io_replay_1_bits_uop_waitForRobIdx_flag),
    .io_replay_1_bits_uop_waitForRobIdx_value(g_io_replay_1_bits_uop_waitForRobIdx_value),
    .io_replay_1_bits_uop_loadWaitBit(g_io_replay_1_bits_uop_loadWaitBit),
    .io_replay_1_bits_uop_ssid(g_io_replay_1_bits_uop_ssid),
    .io_replay_1_bits_uop_lqIdx_flag(g_io_replay_1_bits_uop_lqIdx_flag),
    .io_replay_1_bits_uop_lqIdx_value(g_io_replay_1_bits_uop_lqIdx_value),
    .io_replay_1_bits_uop_sqIdx_flag(g_io_replay_1_bits_uop_sqIdx_flag),
    .io_replay_1_bits_uop_sqIdx_value(g_io_replay_1_bits_uop_sqIdx_value),
    .io_replay_1_bits_uop_singleStep(g_io_replay_1_bits_uop_singleStep),
    .io_replay_1_bits_uop_debug_fuType(g_io_replay_1_bits_uop_debug_fuType),
    .io_replay_1_bits_uop_debug_sim_trig(g_io_replay_1_bits_uop_debug_sim_trig),
    .io_replay_1_bits_uop_numLsElem(g_io_replay_1_bits_uop_numLsElem),
    .io_replay_1_bits_vaddr(g_io_replay_1_bits_vaddr),
    .io_replay_1_bits_mask(g_io_replay_1_bits_mask),
    .io_replay_1_bits_isvec(g_io_replay_1_bits_isvec),
    .io_replay_1_bits_is128bit(g_io_replay_1_bits_is128bit),
    .io_replay_1_bits_elemIdx(g_io_replay_1_bits_elemIdx),
    .io_replay_1_bits_alignedType(g_io_replay_1_bits_alignedType),
    .io_replay_1_bits_mbIndex(g_io_replay_1_bits_mbIndex),
    .io_replay_1_bits_reg_offset(g_io_replay_1_bits_reg_offset),
    .io_replay_1_bits_elemIdxInsideVd(g_io_replay_1_bits_elemIdxInsideVd),
    .io_replay_1_bits_vecActive(g_io_replay_1_bits_vecActive),
    .io_replay_1_bits_mshrid(g_io_replay_1_bits_mshrid),
    .io_replay_1_bits_forward_tlDchannel(g_io_replay_1_bits_forward_tlDchannel),
    .io_replay_1_bits_schedIndex(g_io_replay_1_bits_schedIndex),
    .io_replay_2_valid(g_io_replay_2_valid),
    .io_replay_2_bits_uop_instr(g_io_replay_2_bits_uop_instr),
    .io_replay_2_bits_uop_pc(g_io_replay_2_bits_uop_pc),
    .io_replay_2_bits_uop_foldpc(g_io_replay_2_bits_uop_foldpc),
    .io_replay_2_bits_uop_exceptionVec_0(g_io_replay_2_bits_uop_exceptionVec_0),
    .io_replay_2_bits_uop_exceptionVec_1(g_io_replay_2_bits_uop_exceptionVec_1),
    .io_replay_2_bits_uop_exceptionVec_2(g_io_replay_2_bits_uop_exceptionVec_2),
    .io_replay_2_bits_uop_exceptionVec_3(g_io_replay_2_bits_uop_exceptionVec_3),
    .io_replay_2_bits_uop_exceptionVec_5(g_io_replay_2_bits_uop_exceptionVec_5),
    .io_replay_2_bits_uop_exceptionVec_6(g_io_replay_2_bits_uop_exceptionVec_6),
    .io_replay_2_bits_uop_exceptionVec_7(g_io_replay_2_bits_uop_exceptionVec_7),
    .io_replay_2_bits_uop_exceptionVec_8(g_io_replay_2_bits_uop_exceptionVec_8),
    .io_replay_2_bits_uop_exceptionVec_9(g_io_replay_2_bits_uop_exceptionVec_9),
    .io_replay_2_bits_uop_exceptionVec_10(g_io_replay_2_bits_uop_exceptionVec_10),
    .io_replay_2_bits_uop_exceptionVec_11(g_io_replay_2_bits_uop_exceptionVec_11),
    .io_replay_2_bits_uop_exceptionVec_12(g_io_replay_2_bits_uop_exceptionVec_12),
    .io_replay_2_bits_uop_exceptionVec_13(g_io_replay_2_bits_uop_exceptionVec_13),
    .io_replay_2_bits_uop_exceptionVec_14(g_io_replay_2_bits_uop_exceptionVec_14),
    .io_replay_2_bits_uop_exceptionVec_15(g_io_replay_2_bits_uop_exceptionVec_15),
    .io_replay_2_bits_uop_exceptionVec_16(g_io_replay_2_bits_uop_exceptionVec_16),
    .io_replay_2_bits_uop_exceptionVec_17(g_io_replay_2_bits_uop_exceptionVec_17),
    .io_replay_2_bits_uop_exceptionVec_18(g_io_replay_2_bits_uop_exceptionVec_18),
    .io_replay_2_bits_uop_exceptionVec_19(g_io_replay_2_bits_uop_exceptionVec_19),
    .io_replay_2_bits_uop_exceptionVec_20(g_io_replay_2_bits_uop_exceptionVec_20),
    .io_replay_2_bits_uop_exceptionVec_21(g_io_replay_2_bits_uop_exceptionVec_21),
    .io_replay_2_bits_uop_exceptionVec_22(g_io_replay_2_bits_uop_exceptionVec_22),
    .io_replay_2_bits_uop_exceptionVec_23(g_io_replay_2_bits_uop_exceptionVec_23),
    .io_replay_2_bits_uop_isFetchMalAddr(g_io_replay_2_bits_uop_isFetchMalAddr),
    .io_replay_2_bits_uop_hasException(g_io_replay_2_bits_uop_hasException),
    .io_replay_2_bits_uop_trigger(g_io_replay_2_bits_uop_trigger),
    .io_replay_2_bits_uop_preDecodeInfo_valid(g_io_replay_2_bits_uop_preDecodeInfo_valid),
    .io_replay_2_bits_uop_preDecodeInfo_isRVC(g_io_replay_2_bits_uop_preDecodeInfo_isRVC),
    .io_replay_2_bits_uop_preDecodeInfo_brType(g_io_replay_2_bits_uop_preDecodeInfo_brType),
    .io_replay_2_bits_uop_preDecodeInfo_isCall(g_io_replay_2_bits_uop_preDecodeInfo_isCall),
    .io_replay_2_bits_uop_preDecodeInfo_isRet(g_io_replay_2_bits_uop_preDecodeInfo_isRet),
    .io_replay_2_bits_uop_pred_taken(g_io_replay_2_bits_uop_pred_taken),
    .io_replay_2_bits_uop_crossPageIPFFix(g_io_replay_2_bits_uop_crossPageIPFFix),
    .io_replay_2_bits_uop_ftqPtr_flag(g_io_replay_2_bits_uop_ftqPtr_flag),
    .io_replay_2_bits_uop_ftqPtr_value(g_io_replay_2_bits_uop_ftqPtr_value),
    .io_replay_2_bits_uop_ftqOffset(g_io_replay_2_bits_uop_ftqOffset),
    .io_replay_2_bits_uop_satpFlushFirstFetchFault(g_io_replay_2_bits_uop_satpFlushFirstFetchFault),
    .io_replay_2_bits_uop_srcType_0(g_io_replay_2_bits_uop_srcType_0),
    .io_replay_2_bits_uop_srcType_1(g_io_replay_2_bits_uop_srcType_1),
    .io_replay_2_bits_uop_srcType_2(g_io_replay_2_bits_uop_srcType_2),
    .io_replay_2_bits_uop_srcType_3(g_io_replay_2_bits_uop_srcType_3),
    .io_replay_2_bits_uop_srcType_4(g_io_replay_2_bits_uop_srcType_4),
    .io_replay_2_bits_uop_ldest(g_io_replay_2_bits_uop_ldest),
    .io_replay_2_bits_uop_fuType(g_io_replay_2_bits_uop_fuType),
    .io_replay_2_bits_uop_fuOpType(g_io_replay_2_bits_uop_fuOpType),
    .io_replay_2_bits_uop_rfWen(g_io_replay_2_bits_uop_rfWen),
    .io_replay_2_bits_uop_fpWen(g_io_replay_2_bits_uop_fpWen),
    .io_replay_2_bits_uop_vecWen(g_io_replay_2_bits_uop_vecWen),
    .io_replay_2_bits_uop_v0Wen(g_io_replay_2_bits_uop_v0Wen),
    .io_replay_2_bits_uop_vlWen(g_io_replay_2_bits_uop_vlWen),
    .io_replay_2_bits_uop_isXSTrap(g_io_replay_2_bits_uop_isXSTrap),
    .io_replay_2_bits_uop_waitForward(g_io_replay_2_bits_uop_waitForward),
    .io_replay_2_bits_uop_blockBackward(g_io_replay_2_bits_uop_blockBackward),
    .io_replay_2_bits_uop_canRobCompress(g_io_replay_2_bits_uop_canRobCompress),
    .io_replay_2_bits_uop_selImm(g_io_replay_2_bits_uop_selImm),
    .io_replay_2_bits_uop_imm(g_io_replay_2_bits_uop_imm),
    .io_replay_2_bits_uop_fpu_typeTagOut(g_io_replay_2_bits_uop_fpu_typeTagOut),
    .io_replay_2_bits_uop_fpu_wflags(g_io_replay_2_bits_uop_fpu_wflags),
    .io_replay_2_bits_uop_fpu_typ(g_io_replay_2_bits_uop_fpu_typ),
    .io_replay_2_bits_uop_fpu_fmt(g_io_replay_2_bits_uop_fpu_fmt),
    .io_replay_2_bits_uop_fpu_rm(g_io_replay_2_bits_uop_fpu_rm),
    .io_replay_2_bits_uop_vpu_vill(g_io_replay_2_bits_uop_vpu_vill),
    .io_replay_2_bits_uop_vpu_vma(g_io_replay_2_bits_uop_vpu_vma),
    .io_replay_2_bits_uop_vpu_vta(g_io_replay_2_bits_uop_vpu_vta),
    .io_replay_2_bits_uop_vpu_vsew(g_io_replay_2_bits_uop_vpu_vsew),
    .io_replay_2_bits_uop_vpu_vlmul(g_io_replay_2_bits_uop_vpu_vlmul),
    .io_replay_2_bits_uop_vpu_specVill(g_io_replay_2_bits_uop_vpu_specVill),
    .io_replay_2_bits_uop_vpu_specVma(g_io_replay_2_bits_uop_vpu_specVma),
    .io_replay_2_bits_uop_vpu_specVta(g_io_replay_2_bits_uop_vpu_specVta),
    .io_replay_2_bits_uop_vpu_specVsew(g_io_replay_2_bits_uop_vpu_specVsew),
    .io_replay_2_bits_uop_vpu_specVlmul(g_io_replay_2_bits_uop_vpu_specVlmul),
    .io_replay_2_bits_uop_vpu_vm(g_io_replay_2_bits_uop_vpu_vm),
    .io_replay_2_bits_uop_vpu_vstart(g_io_replay_2_bits_uop_vpu_vstart),
    .io_replay_2_bits_uop_vpu_frm(g_io_replay_2_bits_uop_vpu_frm),
    .io_replay_2_bits_uop_vpu_fpu_isFpToVecInst(g_io_replay_2_bits_uop_vpu_fpu_isFpToVecInst),
    .io_replay_2_bits_uop_vpu_fpu_isFP32Instr(g_io_replay_2_bits_uop_vpu_fpu_isFP32Instr),
    .io_replay_2_bits_uop_vpu_fpu_isFP64Instr(g_io_replay_2_bits_uop_vpu_fpu_isFP64Instr),
    .io_replay_2_bits_uop_vpu_fpu_isReduction(g_io_replay_2_bits_uop_vpu_fpu_isReduction),
    .io_replay_2_bits_uop_vpu_fpu_isFoldTo1_2(g_io_replay_2_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_replay_2_bits_uop_vpu_fpu_isFoldTo1_4(g_io_replay_2_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_replay_2_bits_uop_vpu_fpu_isFoldTo1_8(g_io_replay_2_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_replay_2_bits_uop_vpu_vxrm(g_io_replay_2_bits_uop_vpu_vxrm),
    .io_replay_2_bits_uop_vpu_vuopIdx(g_io_replay_2_bits_uop_vpu_vuopIdx),
    .io_replay_2_bits_uop_vpu_lastUop(g_io_replay_2_bits_uop_vpu_lastUop),
    .io_replay_2_bits_uop_vpu_vmask(g_io_replay_2_bits_uop_vpu_vmask),
    .io_replay_2_bits_uop_vpu_vl(g_io_replay_2_bits_uop_vpu_vl),
    .io_replay_2_bits_uop_vpu_nf(g_io_replay_2_bits_uop_vpu_nf),
    .io_replay_2_bits_uop_vpu_veew(g_io_replay_2_bits_uop_vpu_veew),
    .io_replay_2_bits_uop_vpu_isReverse(g_io_replay_2_bits_uop_vpu_isReverse),
    .io_replay_2_bits_uop_vpu_isExt(g_io_replay_2_bits_uop_vpu_isExt),
    .io_replay_2_bits_uop_vpu_isNarrow(g_io_replay_2_bits_uop_vpu_isNarrow),
    .io_replay_2_bits_uop_vpu_isDstMask(g_io_replay_2_bits_uop_vpu_isDstMask),
    .io_replay_2_bits_uop_vpu_isOpMask(g_io_replay_2_bits_uop_vpu_isOpMask),
    .io_replay_2_bits_uop_vpu_isMove(g_io_replay_2_bits_uop_vpu_isMove),
    .io_replay_2_bits_uop_vpu_isDependOldVd(g_io_replay_2_bits_uop_vpu_isDependOldVd),
    .io_replay_2_bits_uop_vpu_isWritePartVd(g_io_replay_2_bits_uop_vpu_isWritePartVd),
    .io_replay_2_bits_uop_vpu_isVleff(g_io_replay_2_bits_uop_vpu_isVleff),
    .io_replay_2_bits_uop_vlsInstr(g_io_replay_2_bits_uop_vlsInstr),
    .io_replay_2_bits_uop_wfflags(g_io_replay_2_bits_uop_wfflags),
    .io_replay_2_bits_uop_isMove(g_io_replay_2_bits_uop_isMove),
    .io_replay_2_bits_uop_isDropAmocasSta(g_io_replay_2_bits_uop_isDropAmocasSta),
    .io_replay_2_bits_uop_uopIdx(g_io_replay_2_bits_uop_uopIdx),
    .io_replay_2_bits_uop_isVset(g_io_replay_2_bits_uop_isVset),
    .io_replay_2_bits_uop_firstUop(g_io_replay_2_bits_uop_firstUop),
    .io_replay_2_bits_uop_lastUop(g_io_replay_2_bits_uop_lastUop),
    .io_replay_2_bits_uop_numUops(g_io_replay_2_bits_uop_numUops),
    .io_replay_2_bits_uop_numWB(g_io_replay_2_bits_uop_numWB),
    .io_replay_2_bits_uop_commitType(g_io_replay_2_bits_uop_commitType),
    .io_replay_2_bits_uop_srcState_0(g_io_replay_2_bits_uop_srcState_0),
    .io_replay_2_bits_uop_srcState_1(g_io_replay_2_bits_uop_srcState_1),
    .io_replay_2_bits_uop_srcState_2(g_io_replay_2_bits_uop_srcState_2),
    .io_replay_2_bits_uop_srcState_3(g_io_replay_2_bits_uop_srcState_3),
    .io_replay_2_bits_uop_srcState_4(g_io_replay_2_bits_uop_srcState_4),
    .io_replay_2_bits_uop_srcLoadDependency_0_0(g_io_replay_2_bits_uop_srcLoadDependency_0_0),
    .io_replay_2_bits_uop_srcLoadDependency_0_1(g_io_replay_2_bits_uop_srcLoadDependency_0_1),
    .io_replay_2_bits_uop_srcLoadDependency_0_2(g_io_replay_2_bits_uop_srcLoadDependency_0_2),
    .io_replay_2_bits_uop_srcLoadDependency_1_0(g_io_replay_2_bits_uop_srcLoadDependency_1_0),
    .io_replay_2_bits_uop_srcLoadDependency_1_1(g_io_replay_2_bits_uop_srcLoadDependency_1_1),
    .io_replay_2_bits_uop_srcLoadDependency_1_2(g_io_replay_2_bits_uop_srcLoadDependency_1_2),
    .io_replay_2_bits_uop_srcLoadDependency_2_0(g_io_replay_2_bits_uop_srcLoadDependency_2_0),
    .io_replay_2_bits_uop_srcLoadDependency_2_1(g_io_replay_2_bits_uop_srcLoadDependency_2_1),
    .io_replay_2_bits_uop_srcLoadDependency_2_2(g_io_replay_2_bits_uop_srcLoadDependency_2_2),
    .io_replay_2_bits_uop_srcLoadDependency_3_0(g_io_replay_2_bits_uop_srcLoadDependency_3_0),
    .io_replay_2_bits_uop_srcLoadDependency_3_1(g_io_replay_2_bits_uop_srcLoadDependency_3_1),
    .io_replay_2_bits_uop_srcLoadDependency_3_2(g_io_replay_2_bits_uop_srcLoadDependency_3_2),
    .io_replay_2_bits_uop_srcLoadDependency_4_0(g_io_replay_2_bits_uop_srcLoadDependency_4_0),
    .io_replay_2_bits_uop_srcLoadDependency_4_1(g_io_replay_2_bits_uop_srcLoadDependency_4_1),
    .io_replay_2_bits_uop_srcLoadDependency_4_2(g_io_replay_2_bits_uop_srcLoadDependency_4_2),
    .io_replay_2_bits_uop_psrc_0(g_io_replay_2_bits_uop_psrc_0),
    .io_replay_2_bits_uop_psrc_1(g_io_replay_2_bits_uop_psrc_1),
    .io_replay_2_bits_uop_psrc_2(g_io_replay_2_bits_uop_psrc_2),
    .io_replay_2_bits_uop_psrc_3(g_io_replay_2_bits_uop_psrc_3),
    .io_replay_2_bits_uop_psrc_4(g_io_replay_2_bits_uop_psrc_4),
    .io_replay_2_bits_uop_pdest(g_io_replay_2_bits_uop_pdest),
    .io_replay_2_bits_uop_useRegCache_0(g_io_replay_2_bits_uop_useRegCache_0),
    .io_replay_2_bits_uop_useRegCache_1(g_io_replay_2_bits_uop_useRegCache_1),
    .io_replay_2_bits_uop_regCacheIdx_0(g_io_replay_2_bits_uop_regCacheIdx_0),
    .io_replay_2_bits_uop_regCacheIdx_1(g_io_replay_2_bits_uop_regCacheIdx_1),
    .io_replay_2_bits_uop_robIdx_flag(g_io_replay_2_bits_uop_robIdx_flag),
    .io_replay_2_bits_uop_robIdx_value(g_io_replay_2_bits_uop_robIdx_value),
    .io_replay_2_bits_uop_instrSize(g_io_replay_2_bits_uop_instrSize),
    .io_replay_2_bits_uop_dirtyFs(g_io_replay_2_bits_uop_dirtyFs),
    .io_replay_2_bits_uop_dirtyVs(g_io_replay_2_bits_uop_dirtyVs),
    .io_replay_2_bits_uop_traceBlockInPipe_itype(g_io_replay_2_bits_uop_traceBlockInPipe_itype),
    .io_replay_2_bits_uop_traceBlockInPipe_iretire(g_io_replay_2_bits_uop_traceBlockInPipe_iretire),
    .io_replay_2_bits_uop_traceBlockInPipe_ilastsize(g_io_replay_2_bits_uop_traceBlockInPipe_ilastsize),
    .io_replay_2_bits_uop_eliminatedMove(g_io_replay_2_bits_uop_eliminatedMove),
    .io_replay_2_bits_uop_snapshot(g_io_replay_2_bits_uop_snapshot),
    .io_replay_2_bits_uop_debugInfo_eliminatedMove(g_io_replay_2_bits_uop_debugInfo_eliminatedMove),
    .io_replay_2_bits_uop_debugInfo_renameTime(g_io_replay_2_bits_uop_debugInfo_renameTime),
    .io_replay_2_bits_uop_debugInfo_dispatchTime(g_io_replay_2_bits_uop_debugInfo_dispatchTime),
    .io_replay_2_bits_uop_debugInfo_enqRsTime(g_io_replay_2_bits_uop_debugInfo_enqRsTime),
    .io_replay_2_bits_uop_debugInfo_selectTime(g_io_replay_2_bits_uop_debugInfo_selectTime),
    .io_replay_2_bits_uop_debugInfo_issueTime(g_io_replay_2_bits_uop_debugInfo_issueTime),
    .io_replay_2_bits_uop_debugInfo_writebackTime(g_io_replay_2_bits_uop_debugInfo_writebackTime),
    .io_replay_2_bits_uop_debugInfo_runahead_checkpoint_id(g_io_replay_2_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_replay_2_bits_uop_debugInfo_tlbFirstReqTime(g_io_replay_2_bits_uop_debugInfo_tlbFirstReqTime),
    .io_replay_2_bits_uop_debugInfo_tlbRespTime(g_io_replay_2_bits_uop_debugInfo_tlbRespTime),
    .io_replay_2_bits_uop_debug_seqNum_seqNum(g_io_replay_2_bits_uop_debug_seqNum_seqNum),
    .io_replay_2_bits_uop_debug_seqNum_uopIdx(g_io_replay_2_bits_uop_debug_seqNum_uopIdx),
    .io_replay_2_bits_uop_storeSetHit(g_io_replay_2_bits_uop_storeSetHit),
    .io_replay_2_bits_uop_waitForRobIdx_flag(g_io_replay_2_bits_uop_waitForRobIdx_flag),
    .io_replay_2_bits_uop_waitForRobIdx_value(g_io_replay_2_bits_uop_waitForRobIdx_value),
    .io_replay_2_bits_uop_loadWaitBit(g_io_replay_2_bits_uop_loadWaitBit),
    .io_replay_2_bits_uop_ssid(g_io_replay_2_bits_uop_ssid),
    .io_replay_2_bits_uop_lqIdx_flag(g_io_replay_2_bits_uop_lqIdx_flag),
    .io_replay_2_bits_uop_lqIdx_value(g_io_replay_2_bits_uop_lqIdx_value),
    .io_replay_2_bits_uop_sqIdx_flag(g_io_replay_2_bits_uop_sqIdx_flag),
    .io_replay_2_bits_uop_sqIdx_value(g_io_replay_2_bits_uop_sqIdx_value),
    .io_replay_2_bits_uop_singleStep(g_io_replay_2_bits_uop_singleStep),
    .io_replay_2_bits_uop_debug_fuType(g_io_replay_2_bits_uop_debug_fuType),
    .io_replay_2_bits_uop_debug_sim_trig(g_io_replay_2_bits_uop_debug_sim_trig),
    .io_replay_2_bits_uop_numLsElem(g_io_replay_2_bits_uop_numLsElem),
    .io_replay_2_bits_vaddr(g_io_replay_2_bits_vaddr),
    .io_replay_2_bits_mask(g_io_replay_2_bits_mask),
    .io_replay_2_bits_isvec(g_io_replay_2_bits_isvec),
    .io_replay_2_bits_is128bit(g_io_replay_2_bits_is128bit),
    .io_replay_2_bits_elemIdx(g_io_replay_2_bits_elemIdx),
    .io_replay_2_bits_alignedType(g_io_replay_2_bits_alignedType),
    .io_replay_2_bits_mbIndex(g_io_replay_2_bits_mbIndex),
    .io_replay_2_bits_reg_offset(g_io_replay_2_bits_reg_offset),
    .io_replay_2_bits_elemIdxInsideVd(g_io_replay_2_bits_elemIdxInsideVd),
    .io_replay_2_bits_vecActive(g_io_replay_2_bits_vecActive),
    .io_replay_2_bits_mshrid(g_io_replay_2_bits_mshrid),
    .io_replay_2_bits_forward_tlDchannel(g_io_replay_2_bits_forward_tlDchannel),
    .io_replay_2_bits_schedIndex(g_io_replay_2_bits_schedIndex),
    .io_lqFull(g_io_lqFull),
    .io_debugTopDown_robHeadTlbReplay(g_io_debugTopDown_robHeadTlbReplay),
    .io_debugTopDown_robHeadTlbMiss(g_io_debugTopDown_robHeadTlbMiss),
    .io_debugTopDown_robHeadLoadVio(g_io_debugTopDown_robHeadLoadVio),
    .io_debugTopDown_robHeadLoadMSHR(g_io_debugTopDown_robHeadLoadMSHR),
    .io_replayAllocate(g_io_replayAllocate),
    .io_perf_0_value(g_io_perf_0_value),
    .io_perf_1_value(g_io_perf_1_value),
    .io_perf_2_value(g_io_perf_2_value),
    .io_perf_3_value(g_io_perf_3_value),
    .io_perf_4_value(g_io_perf_4_value),
    .io_perf_5_value(g_io_perf_5_value),
    .io_perf_6_value(g_io_perf_6_value),
    .io_perf_7_value(g_io_perf_7_value),
    .io_perf_8_value(g_io_perf_8_value),
    .io_perf_9_value(g_io_perf_9_value),
    .io_perf_10_value(g_io_perf_10_value),
    .io_perf_11_value(g_io_perf_11_value),
    .io_perf_12_value(g_io_perf_12_value)
  );

  LoadQueueReplay_xs i_dut (
    .clock(clk), .reset(rst),
    .io_redirect_valid(io_redirect_valid),
    .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag),
    .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value),
    .io_redirect_bits_level(io_redirect_bits_level),
    .io_vecFeedback_0_valid(io_vecFeedback_0_valid),
    .io_vecFeedback_0_bits_robidx_flag(io_vecFeedback_0_bits_robidx_flag),
    .io_vecFeedback_0_bits_robidx_value(io_vecFeedback_0_bits_robidx_value),
    .io_vecFeedback_0_bits_uopidx(io_vecFeedback_0_bits_uopidx),
    .io_vecFeedback_0_bits_feedback_0(io_vecFeedback_0_bits_feedback_0),
    .io_vecFeedback_0_bits_feedback_1(io_vecFeedback_0_bits_feedback_1),
    .io_vecFeedback_1_valid(io_vecFeedback_1_valid),
    .io_vecFeedback_1_bits_robidx_flag(io_vecFeedback_1_bits_robidx_flag),
    .io_vecFeedback_1_bits_robidx_value(io_vecFeedback_1_bits_robidx_value),
    .io_vecFeedback_1_bits_uopidx(io_vecFeedback_1_bits_uopidx),
    .io_vecFeedback_1_bits_feedback_0(io_vecFeedback_1_bits_feedback_0),
    .io_vecFeedback_1_bits_feedback_1(io_vecFeedback_1_bits_feedback_1),
    .io_enq_0_valid(io_enq_0_valid),
    .io_enq_0_bits_uop_instr(io_enq_0_bits_uop_instr),
    .io_enq_0_bits_uop_pc(io_enq_0_bits_uop_pc),
    .io_enq_0_bits_uop_foldpc(io_enq_0_bits_uop_foldpc),
    .io_enq_0_bits_uop_exceptionVec_0(io_enq_0_bits_uop_exceptionVec_0),
    .io_enq_0_bits_uop_exceptionVec_1(io_enq_0_bits_uop_exceptionVec_1),
    .io_enq_0_bits_uop_exceptionVec_2(io_enq_0_bits_uop_exceptionVec_2),
    .io_enq_0_bits_uop_exceptionVec_3(io_enq_0_bits_uop_exceptionVec_3),
    .io_enq_0_bits_uop_exceptionVec_5(io_enq_0_bits_uop_exceptionVec_5),
    .io_enq_0_bits_uop_exceptionVec_6(io_enq_0_bits_uop_exceptionVec_6),
    .io_enq_0_bits_uop_exceptionVec_7(io_enq_0_bits_uop_exceptionVec_7),
    .io_enq_0_bits_uop_exceptionVec_8(io_enq_0_bits_uop_exceptionVec_8),
    .io_enq_0_bits_uop_exceptionVec_9(io_enq_0_bits_uop_exceptionVec_9),
    .io_enq_0_bits_uop_exceptionVec_10(io_enq_0_bits_uop_exceptionVec_10),
    .io_enq_0_bits_uop_exceptionVec_11(io_enq_0_bits_uop_exceptionVec_11),
    .io_enq_0_bits_uop_exceptionVec_12(io_enq_0_bits_uop_exceptionVec_12),
    .io_enq_0_bits_uop_exceptionVec_13(io_enq_0_bits_uop_exceptionVec_13),
    .io_enq_0_bits_uop_exceptionVec_14(io_enq_0_bits_uop_exceptionVec_14),
    .io_enq_0_bits_uop_exceptionVec_15(io_enq_0_bits_uop_exceptionVec_15),
    .io_enq_0_bits_uop_exceptionVec_16(io_enq_0_bits_uop_exceptionVec_16),
    .io_enq_0_bits_uop_exceptionVec_17(io_enq_0_bits_uop_exceptionVec_17),
    .io_enq_0_bits_uop_exceptionVec_18(io_enq_0_bits_uop_exceptionVec_18),
    .io_enq_0_bits_uop_exceptionVec_19(io_enq_0_bits_uop_exceptionVec_19),
    .io_enq_0_bits_uop_exceptionVec_20(io_enq_0_bits_uop_exceptionVec_20),
    .io_enq_0_bits_uop_exceptionVec_21(io_enq_0_bits_uop_exceptionVec_21),
    .io_enq_0_bits_uop_exceptionVec_22(io_enq_0_bits_uop_exceptionVec_22),
    .io_enq_0_bits_uop_exceptionVec_23(io_enq_0_bits_uop_exceptionVec_23),
    .io_enq_0_bits_uop_isFetchMalAddr(io_enq_0_bits_uop_isFetchMalAddr),
    .io_enq_0_bits_uop_hasException(io_enq_0_bits_uop_hasException),
    .io_enq_0_bits_uop_trigger(io_enq_0_bits_uop_trigger),
    .io_enq_0_bits_uop_preDecodeInfo_valid(io_enq_0_bits_uop_preDecodeInfo_valid),
    .io_enq_0_bits_uop_preDecodeInfo_isRVC(io_enq_0_bits_uop_preDecodeInfo_isRVC),
    .io_enq_0_bits_uop_preDecodeInfo_brType(io_enq_0_bits_uop_preDecodeInfo_brType),
    .io_enq_0_bits_uop_preDecodeInfo_isCall(io_enq_0_bits_uop_preDecodeInfo_isCall),
    .io_enq_0_bits_uop_preDecodeInfo_isRet(io_enq_0_bits_uop_preDecodeInfo_isRet),
    .io_enq_0_bits_uop_pred_taken(io_enq_0_bits_uop_pred_taken),
    .io_enq_0_bits_uop_crossPageIPFFix(io_enq_0_bits_uop_crossPageIPFFix),
    .io_enq_0_bits_uop_ftqPtr_flag(io_enq_0_bits_uop_ftqPtr_flag),
    .io_enq_0_bits_uop_ftqPtr_value(io_enq_0_bits_uop_ftqPtr_value),
    .io_enq_0_bits_uop_ftqOffset(io_enq_0_bits_uop_ftqOffset),
    .io_enq_0_bits_uop_satpFlushFirstFetchFault(io_enq_0_bits_uop_satpFlushFirstFetchFault),
    .io_enq_0_bits_uop_srcType_0(io_enq_0_bits_uop_srcType_0),
    .io_enq_0_bits_uop_srcType_1(io_enq_0_bits_uop_srcType_1),
    .io_enq_0_bits_uop_srcType_2(io_enq_0_bits_uop_srcType_2),
    .io_enq_0_bits_uop_srcType_3(io_enq_0_bits_uop_srcType_3),
    .io_enq_0_bits_uop_srcType_4(io_enq_0_bits_uop_srcType_4),
    .io_enq_0_bits_uop_ldest(io_enq_0_bits_uop_ldest),
    .io_enq_0_bits_uop_fuType(io_enq_0_bits_uop_fuType),
    .io_enq_0_bits_uop_fuOpType(io_enq_0_bits_uop_fuOpType),
    .io_enq_0_bits_uop_rfWen(io_enq_0_bits_uop_rfWen),
    .io_enq_0_bits_uop_fpWen(io_enq_0_bits_uop_fpWen),
    .io_enq_0_bits_uop_vecWen(io_enq_0_bits_uop_vecWen),
    .io_enq_0_bits_uop_v0Wen(io_enq_0_bits_uop_v0Wen),
    .io_enq_0_bits_uop_vlWen(io_enq_0_bits_uop_vlWen),
    .io_enq_0_bits_uop_isXSTrap(io_enq_0_bits_uop_isXSTrap),
    .io_enq_0_bits_uop_waitForward(io_enq_0_bits_uop_waitForward),
    .io_enq_0_bits_uop_blockBackward(io_enq_0_bits_uop_blockBackward),
    .io_enq_0_bits_uop_canRobCompress(io_enq_0_bits_uop_canRobCompress),
    .io_enq_0_bits_uop_selImm(io_enq_0_bits_uop_selImm),
    .io_enq_0_bits_uop_imm(io_enq_0_bits_uop_imm),
    .io_enq_0_bits_uop_fpu_typeTagOut(io_enq_0_bits_uop_fpu_typeTagOut),
    .io_enq_0_bits_uop_fpu_wflags(io_enq_0_bits_uop_fpu_wflags),
    .io_enq_0_bits_uop_fpu_typ(io_enq_0_bits_uop_fpu_typ),
    .io_enq_0_bits_uop_fpu_fmt(io_enq_0_bits_uop_fpu_fmt),
    .io_enq_0_bits_uop_fpu_rm(io_enq_0_bits_uop_fpu_rm),
    .io_enq_0_bits_uop_vpu_vill(io_enq_0_bits_uop_vpu_vill),
    .io_enq_0_bits_uop_vpu_vma(io_enq_0_bits_uop_vpu_vma),
    .io_enq_0_bits_uop_vpu_vta(io_enq_0_bits_uop_vpu_vta),
    .io_enq_0_bits_uop_vpu_vsew(io_enq_0_bits_uop_vpu_vsew),
    .io_enq_0_bits_uop_vpu_vlmul(io_enq_0_bits_uop_vpu_vlmul),
    .io_enq_0_bits_uop_vpu_specVill(io_enq_0_bits_uop_vpu_specVill),
    .io_enq_0_bits_uop_vpu_specVma(io_enq_0_bits_uop_vpu_specVma),
    .io_enq_0_bits_uop_vpu_specVta(io_enq_0_bits_uop_vpu_specVta),
    .io_enq_0_bits_uop_vpu_specVsew(io_enq_0_bits_uop_vpu_specVsew),
    .io_enq_0_bits_uop_vpu_specVlmul(io_enq_0_bits_uop_vpu_specVlmul),
    .io_enq_0_bits_uop_vpu_vm(io_enq_0_bits_uop_vpu_vm),
    .io_enq_0_bits_uop_vpu_vstart(io_enq_0_bits_uop_vpu_vstart),
    .io_enq_0_bits_uop_vpu_frm(io_enq_0_bits_uop_vpu_frm),
    .io_enq_0_bits_uop_vpu_fpu_isFpToVecInst(io_enq_0_bits_uop_vpu_fpu_isFpToVecInst),
    .io_enq_0_bits_uop_vpu_fpu_isFP32Instr(io_enq_0_bits_uop_vpu_fpu_isFP32Instr),
    .io_enq_0_bits_uop_vpu_fpu_isFP64Instr(io_enq_0_bits_uop_vpu_fpu_isFP64Instr),
    .io_enq_0_bits_uop_vpu_fpu_isReduction(io_enq_0_bits_uop_vpu_fpu_isReduction),
    .io_enq_0_bits_uop_vpu_fpu_isFoldTo1_2(io_enq_0_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_enq_0_bits_uop_vpu_fpu_isFoldTo1_4(io_enq_0_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_enq_0_bits_uop_vpu_fpu_isFoldTo1_8(io_enq_0_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_enq_0_bits_uop_vpu_vxrm(io_enq_0_bits_uop_vpu_vxrm),
    .io_enq_0_bits_uop_vpu_vuopIdx(io_enq_0_bits_uop_vpu_vuopIdx),
    .io_enq_0_bits_uop_vpu_lastUop(io_enq_0_bits_uop_vpu_lastUop),
    .io_enq_0_bits_uop_vpu_vmask(io_enq_0_bits_uop_vpu_vmask),
    .io_enq_0_bits_uop_vpu_vl(io_enq_0_bits_uop_vpu_vl),
    .io_enq_0_bits_uop_vpu_nf(io_enq_0_bits_uop_vpu_nf),
    .io_enq_0_bits_uop_vpu_veew(io_enq_0_bits_uop_vpu_veew),
    .io_enq_0_bits_uop_vpu_isReverse(io_enq_0_bits_uop_vpu_isReverse),
    .io_enq_0_bits_uop_vpu_isExt(io_enq_0_bits_uop_vpu_isExt),
    .io_enq_0_bits_uop_vpu_isNarrow(io_enq_0_bits_uop_vpu_isNarrow),
    .io_enq_0_bits_uop_vpu_isDstMask(io_enq_0_bits_uop_vpu_isDstMask),
    .io_enq_0_bits_uop_vpu_isOpMask(io_enq_0_bits_uop_vpu_isOpMask),
    .io_enq_0_bits_uop_vpu_isMove(io_enq_0_bits_uop_vpu_isMove),
    .io_enq_0_bits_uop_vpu_isDependOldVd(io_enq_0_bits_uop_vpu_isDependOldVd),
    .io_enq_0_bits_uop_vpu_isWritePartVd(io_enq_0_bits_uop_vpu_isWritePartVd),
    .io_enq_0_bits_uop_vpu_isVleff(io_enq_0_bits_uop_vpu_isVleff),
    .io_enq_0_bits_uop_vlsInstr(io_enq_0_bits_uop_vlsInstr),
    .io_enq_0_bits_uop_wfflags(io_enq_0_bits_uop_wfflags),
    .io_enq_0_bits_uop_isMove(io_enq_0_bits_uop_isMove),
    .io_enq_0_bits_uop_isDropAmocasSta(io_enq_0_bits_uop_isDropAmocasSta),
    .io_enq_0_bits_uop_uopIdx(io_enq_0_bits_uop_uopIdx),
    .io_enq_0_bits_uop_isVset(io_enq_0_bits_uop_isVset),
    .io_enq_0_bits_uop_firstUop(io_enq_0_bits_uop_firstUop),
    .io_enq_0_bits_uop_lastUop(io_enq_0_bits_uop_lastUop),
    .io_enq_0_bits_uop_numUops(io_enq_0_bits_uop_numUops),
    .io_enq_0_bits_uop_numWB(io_enq_0_bits_uop_numWB),
    .io_enq_0_bits_uop_commitType(io_enq_0_bits_uop_commitType),
    .io_enq_0_bits_uop_srcState_0(io_enq_0_bits_uop_srcState_0),
    .io_enq_0_bits_uop_srcState_1(io_enq_0_bits_uop_srcState_1),
    .io_enq_0_bits_uop_srcState_2(io_enq_0_bits_uop_srcState_2),
    .io_enq_0_bits_uop_srcState_3(io_enq_0_bits_uop_srcState_3),
    .io_enq_0_bits_uop_srcState_4(io_enq_0_bits_uop_srcState_4),
    .io_enq_0_bits_uop_srcLoadDependency_0_0(io_enq_0_bits_uop_srcLoadDependency_0_0),
    .io_enq_0_bits_uop_srcLoadDependency_0_1(io_enq_0_bits_uop_srcLoadDependency_0_1),
    .io_enq_0_bits_uop_srcLoadDependency_0_2(io_enq_0_bits_uop_srcLoadDependency_0_2),
    .io_enq_0_bits_uop_srcLoadDependency_1_0(io_enq_0_bits_uop_srcLoadDependency_1_0),
    .io_enq_0_bits_uop_srcLoadDependency_1_1(io_enq_0_bits_uop_srcLoadDependency_1_1),
    .io_enq_0_bits_uop_srcLoadDependency_1_2(io_enq_0_bits_uop_srcLoadDependency_1_2),
    .io_enq_0_bits_uop_srcLoadDependency_2_0(io_enq_0_bits_uop_srcLoadDependency_2_0),
    .io_enq_0_bits_uop_srcLoadDependency_2_1(io_enq_0_bits_uop_srcLoadDependency_2_1),
    .io_enq_0_bits_uop_srcLoadDependency_2_2(io_enq_0_bits_uop_srcLoadDependency_2_2),
    .io_enq_0_bits_uop_srcLoadDependency_3_0(io_enq_0_bits_uop_srcLoadDependency_3_0),
    .io_enq_0_bits_uop_srcLoadDependency_3_1(io_enq_0_bits_uop_srcLoadDependency_3_1),
    .io_enq_0_bits_uop_srcLoadDependency_3_2(io_enq_0_bits_uop_srcLoadDependency_3_2),
    .io_enq_0_bits_uop_srcLoadDependency_4_0(io_enq_0_bits_uop_srcLoadDependency_4_0),
    .io_enq_0_bits_uop_srcLoadDependency_4_1(io_enq_0_bits_uop_srcLoadDependency_4_1),
    .io_enq_0_bits_uop_srcLoadDependency_4_2(io_enq_0_bits_uop_srcLoadDependency_4_2),
    .io_enq_0_bits_uop_psrc_0(io_enq_0_bits_uop_psrc_0),
    .io_enq_0_bits_uop_psrc_1(io_enq_0_bits_uop_psrc_1),
    .io_enq_0_bits_uop_psrc_2(io_enq_0_bits_uop_psrc_2),
    .io_enq_0_bits_uop_psrc_3(io_enq_0_bits_uop_psrc_3),
    .io_enq_0_bits_uop_psrc_4(io_enq_0_bits_uop_psrc_4),
    .io_enq_0_bits_uop_pdest(io_enq_0_bits_uop_pdest),
    .io_enq_0_bits_uop_useRegCache_0(io_enq_0_bits_uop_useRegCache_0),
    .io_enq_0_bits_uop_useRegCache_1(io_enq_0_bits_uop_useRegCache_1),
    .io_enq_0_bits_uop_regCacheIdx_0(io_enq_0_bits_uop_regCacheIdx_0),
    .io_enq_0_bits_uop_regCacheIdx_1(io_enq_0_bits_uop_regCacheIdx_1),
    .io_enq_0_bits_uop_robIdx_flag(io_enq_0_bits_uop_robIdx_flag),
    .io_enq_0_bits_uop_robIdx_value(io_enq_0_bits_uop_robIdx_value),
    .io_enq_0_bits_uop_instrSize(io_enq_0_bits_uop_instrSize),
    .io_enq_0_bits_uop_dirtyFs(io_enq_0_bits_uop_dirtyFs),
    .io_enq_0_bits_uop_dirtyVs(io_enq_0_bits_uop_dirtyVs),
    .io_enq_0_bits_uop_traceBlockInPipe_itype(io_enq_0_bits_uop_traceBlockInPipe_itype),
    .io_enq_0_bits_uop_traceBlockInPipe_iretire(io_enq_0_bits_uop_traceBlockInPipe_iretire),
    .io_enq_0_bits_uop_traceBlockInPipe_ilastsize(io_enq_0_bits_uop_traceBlockInPipe_ilastsize),
    .io_enq_0_bits_uop_eliminatedMove(io_enq_0_bits_uop_eliminatedMove),
    .io_enq_0_bits_uop_snapshot(io_enq_0_bits_uop_snapshot),
    .io_enq_0_bits_uop_debugInfo_eliminatedMove(io_enq_0_bits_uop_debugInfo_eliminatedMove),
    .io_enq_0_bits_uop_debugInfo_renameTime(io_enq_0_bits_uop_debugInfo_renameTime),
    .io_enq_0_bits_uop_debugInfo_dispatchTime(io_enq_0_bits_uop_debugInfo_dispatchTime),
    .io_enq_0_bits_uop_debugInfo_enqRsTime(io_enq_0_bits_uop_debugInfo_enqRsTime),
    .io_enq_0_bits_uop_debugInfo_selectTime(io_enq_0_bits_uop_debugInfo_selectTime),
    .io_enq_0_bits_uop_debugInfo_issueTime(io_enq_0_bits_uop_debugInfo_issueTime),
    .io_enq_0_bits_uop_debugInfo_writebackTime(io_enq_0_bits_uop_debugInfo_writebackTime),
    .io_enq_0_bits_uop_debugInfo_runahead_checkpoint_id(io_enq_0_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_enq_0_bits_uop_debugInfo_tlbFirstReqTime(io_enq_0_bits_uop_debugInfo_tlbFirstReqTime),
    .io_enq_0_bits_uop_debugInfo_tlbRespTime(io_enq_0_bits_uop_debugInfo_tlbRespTime),
    .io_enq_0_bits_uop_debug_seqNum_seqNum(io_enq_0_bits_uop_debug_seqNum_seqNum),
    .io_enq_0_bits_uop_debug_seqNum_uopIdx(io_enq_0_bits_uop_debug_seqNum_uopIdx),
    .io_enq_0_bits_uop_storeSetHit(io_enq_0_bits_uop_storeSetHit),
    .io_enq_0_bits_uop_waitForRobIdx_flag(io_enq_0_bits_uop_waitForRobIdx_flag),
    .io_enq_0_bits_uop_waitForRobIdx_value(io_enq_0_bits_uop_waitForRobIdx_value),
    .io_enq_0_bits_uop_loadWaitBit(io_enq_0_bits_uop_loadWaitBit),
    .io_enq_0_bits_uop_loadWaitStrict(io_enq_0_bits_uop_loadWaitStrict),
    .io_enq_0_bits_uop_ssid(io_enq_0_bits_uop_ssid),
    .io_enq_0_bits_uop_lqIdx_flag(io_enq_0_bits_uop_lqIdx_flag),
    .io_enq_0_bits_uop_lqIdx_value(io_enq_0_bits_uop_lqIdx_value),
    .io_enq_0_bits_uop_sqIdx_flag(io_enq_0_bits_uop_sqIdx_flag),
    .io_enq_0_bits_uop_sqIdx_value(io_enq_0_bits_uop_sqIdx_value),
    .io_enq_0_bits_uop_singleStep(io_enq_0_bits_uop_singleStep),
    .io_enq_0_bits_uop_debug_fuType(io_enq_0_bits_uop_debug_fuType),
    .io_enq_0_bits_uop_debug_sim_trig(io_enq_0_bits_uop_debug_sim_trig),
    .io_enq_0_bits_uop_numLsElem(io_enq_0_bits_uop_numLsElem),
    .io_enq_0_bits_vaddr(io_enq_0_bits_vaddr),
    .io_enq_0_bits_mask(io_enq_0_bits_mask),
    .io_enq_0_bits_isvec(io_enq_0_bits_isvec),
    .io_enq_0_bits_is128bit(io_enq_0_bits_is128bit),
    .io_enq_0_bits_elemIdx(io_enq_0_bits_elemIdx),
    .io_enq_0_bits_alignedType(io_enq_0_bits_alignedType),
    .io_enq_0_bits_mbIndex(io_enq_0_bits_mbIndex),
    .io_enq_0_bits_reg_offset(io_enq_0_bits_reg_offset),
    .io_enq_0_bits_elemIdxInsideVd(io_enq_0_bits_elemIdxInsideVd),
    .io_enq_0_bits_vecActive(io_enq_0_bits_vecActive),
    .io_enq_0_bits_isLoadReplay(io_enq_0_bits_isLoadReplay),
    .io_enq_0_bits_handledByMSHR(io_enq_0_bits_handledByMSHR),
    .io_enq_0_bits_schedIndex(io_enq_0_bits_schedIndex),
    .io_enq_0_bits_rep_info_mshr_id(io_enq_0_bits_rep_info_mshr_id),
    .io_enq_0_bits_rep_info_full_fwd(io_enq_0_bits_rep_info_full_fwd),
    .io_enq_0_bits_rep_info_data_inv_sq_idx_flag(io_enq_0_bits_rep_info_data_inv_sq_idx_flag),
    .io_enq_0_bits_rep_info_data_inv_sq_idx_value(io_enq_0_bits_rep_info_data_inv_sq_idx_value),
    .io_enq_0_bits_rep_info_addr_inv_sq_idx_flag(io_enq_0_bits_rep_info_addr_inv_sq_idx_flag),
    .io_enq_0_bits_rep_info_addr_inv_sq_idx_value(io_enq_0_bits_rep_info_addr_inv_sq_idx_value),
    .io_enq_0_bits_rep_info_last_beat(io_enq_0_bits_rep_info_last_beat),
    .io_enq_0_bits_rep_info_cause_0(io_enq_0_bits_rep_info_cause_0),
    .io_enq_0_bits_rep_info_cause_1(io_enq_0_bits_rep_info_cause_1),
    .io_enq_0_bits_rep_info_cause_2(io_enq_0_bits_rep_info_cause_2),
    .io_enq_0_bits_rep_info_cause_3(io_enq_0_bits_rep_info_cause_3),
    .io_enq_0_bits_rep_info_cause_4(io_enq_0_bits_rep_info_cause_4),
    .io_enq_0_bits_rep_info_cause_5(io_enq_0_bits_rep_info_cause_5),
    .io_enq_0_bits_rep_info_cause_6(io_enq_0_bits_rep_info_cause_6),
    .io_enq_0_bits_rep_info_cause_7(io_enq_0_bits_rep_info_cause_7),
    .io_enq_0_bits_rep_info_cause_8(io_enq_0_bits_rep_info_cause_8),
    .io_enq_0_bits_rep_info_cause_9(io_enq_0_bits_rep_info_cause_9),
    .io_enq_0_bits_rep_info_cause_10(io_enq_0_bits_rep_info_cause_10),
    .io_enq_0_bits_rep_info_tlb_id(io_enq_0_bits_rep_info_tlb_id),
    .io_enq_0_bits_rep_info_tlb_full(io_enq_0_bits_rep_info_tlb_full),
    .io_enq_1_valid(io_enq_1_valid),
    .io_enq_1_bits_uop_instr(io_enq_1_bits_uop_instr),
    .io_enq_1_bits_uop_pc(io_enq_1_bits_uop_pc),
    .io_enq_1_bits_uop_foldpc(io_enq_1_bits_uop_foldpc),
    .io_enq_1_bits_uop_exceptionVec_0(io_enq_1_bits_uop_exceptionVec_0),
    .io_enq_1_bits_uop_exceptionVec_1(io_enq_1_bits_uop_exceptionVec_1),
    .io_enq_1_bits_uop_exceptionVec_2(io_enq_1_bits_uop_exceptionVec_2),
    .io_enq_1_bits_uop_exceptionVec_3(io_enq_1_bits_uop_exceptionVec_3),
    .io_enq_1_bits_uop_exceptionVec_5(io_enq_1_bits_uop_exceptionVec_5),
    .io_enq_1_bits_uop_exceptionVec_6(io_enq_1_bits_uop_exceptionVec_6),
    .io_enq_1_bits_uop_exceptionVec_7(io_enq_1_bits_uop_exceptionVec_7),
    .io_enq_1_bits_uop_exceptionVec_8(io_enq_1_bits_uop_exceptionVec_8),
    .io_enq_1_bits_uop_exceptionVec_9(io_enq_1_bits_uop_exceptionVec_9),
    .io_enq_1_bits_uop_exceptionVec_10(io_enq_1_bits_uop_exceptionVec_10),
    .io_enq_1_bits_uop_exceptionVec_11(io_enq_1_bits_uop_exceptionVec_11),
    .io_enq_1_bits_uop_exceptionVec_12(io_enq_1_bits_uop_exceptionVec_12),
    .io_enq_1_bits_uop_exceptionVec_13(io_enq_1_bits_uop_exceptionVec_13),
    .io_enq_1_bits_uop_exceptionVec_14(io_enq_1_bits_uop_exceptionVec_14),
    .io_enq_1_bits_uop_exceptionVec_15(io_enq_1_bits_uop_exceptionVec_15),
    .io_enq_1_bits_uop_exceptionVec_16(io_enq_1_bits_uop_exceptionVec_16),
    .io_enq_1_bits_uop_exceptionVec_17(io_enq_1_bits_uop_exceptionVec_17),
    .io_enq_1_bits_uop_exceptionVec_18(io_enq_1_bits_uop_exceptionVec_18),
    .io_enq_1_bits_uop_exceptionVec_19(io_enq_1_bits_uop_exceptionVec_19),
    .io_enq_1_bits_uop_exceptionVec_20(io_enq_1_bits_uop_exceptionVec_20),
    .io_enq_1_bits_uop_exceptionVec_21(io_enq_1_bits_uop_exceptionVec_21),
    .io_enq_1_bits_uop_exceptionVec_22(io_enq_1_bits_uop_exceptionVec_22),
    .io_enq_1_bits_uop_exceptionVec_23(io_enq_1_bits_uop_exceptionVec_23),
    .io_enq_1_bits_uop_isFetchMalAddr(io_enq_1_bits_uop_isFetchMalAddr),
    .io_enq_1_bits_uop_hasException(io_enq_1_bits_uop_hasException),
    .io_enq_1_bits_uop_trigger(io_enq_1_bits_uop_trigger),
    .io_enq_1_bits_uop_preDecodeInfo_valid(io_enq_1_bits_uop_preDecodeInfo_valid),
    .io_enq_1_bits_uop_preDecodeInfo_isRVC(io_enq_1_bits_uop_preDecodeInfo_isRVC),
    .io_enq_1_bits_uop_preDecodeInfo_brType(io_enq_1_bits_uop_preDecodeInfo_brType),
    .io_enq_1_bits_uop_preDecodeInfo_isCall(io_enq_1_bits_uop_preDecodeInfo_isCall),
    .io_enq_1_bits_uop_preDecodeInfo_isRet(io_enq_1_bits_uop_preDecodeInfo_isRet),
    .io_enq_1_bits_uop_pred_taken(io_enq_1_bits_uop_pred_taken),
    .io_enq_1_bits_uop_crossPageIPFFix(io_enq_1_bits_uop_crossPageIPFFix),
    .io_enq_1_bits_uop_ftqPtr_flag(io_enq_1_bits_uop_ftqPtr_flag),
    .io_enq_1_bits_uop_ftqPtr_value(io_enq_1_bits_uop_ftqPtr_value),
    .io_enq_1_bits_uop_ftqOffset(io_enq_1_bits_uop_ftqOffset),
    .io_enq_1_bits_uop_satpFlushFirstFetchFault(io_enq_1_bits_uop_satpFlushFirstFetchFault),
    .io_enq_1_bits_uop_srcType_0(io_enq_1_bits_uop_srcType_0),
    .io_enq_1_bits_uop_srcType_1(io_enq_1_bits_uop_srcType_1),
    .io_enq_1_bits_uop_srcType_2(io_enq_1_bits_uop_srcType_2),
    .io_enq_1_bits_uop_srcType_3(io_enq_1_bits_uop_srcType_3),
    .io_enq_1_bits_uop_srcType_4(io_enq_1_bits_uop_srcType_4),
    .io_enq_1_bits_uop_ldest(io_enq_1_bits_uop_ldest),
    .io_enq_1_bits_uop_fuType(io_enq_1_bits_uop_fuType),
    .io_enq_1_bits_uop_fuOpType(io_enq_1_bits_uop_fuOpType),
    .io_enq_1_bits_uop_rfWen(io_enq_1_bits_uop_rfWen),
    .io_enq_1_bits_uop_fpWen(io_enq_1_bits_uop_fpWen),
    .io_enq_1_bits_uop_vecWen(io_enq_1_bits_uop_vecWen),
    .io_enq_1_bits_uop_v0Wen(io_enq_1_bits_uop_v0Wen),
    .io_enq_1_bits_uop_vlWen(io_enq_1_bits_uop_vlWen),
    .io_enq_1_bits_uop_isXSTrap(io_enq_1_bits_uop_isXSTrap),
    .io_enq_1_bits_uop_waitForward(io_enq_1_bits_uop_waitForward),
    .io_enq_1_bits_uop_blockBackward(io_enq_1_bits_uop_blockBackward),
    .io_enq_1_bits_uop_canRobCompress(io_enq_1_bits_uop_canRobCompress),
    .io_enq_1_bits_uop_selImm(io_enq_1_bits_uop_selImm),
    .io_enq_1_bits_uop_imm(io_enq_1_bits_uop_imm),
    .io_enq_1_bits_uop_fpu_typeTagOut(io_enq_1_bits_uop_fpu_typeTagOut),
    .io_enq_1_bits_uop_fpu_wflags(io_enq_1_bits_uop_fpu_wflags),
    .io_enq_1_bits_uop_fpu_typ(io_enq_1_bits_uop_fpu_typ),
    .io_enq_1_bits_uop_fpu_fmt(io_enq_1_bits_uop_fpu_fmt),
    .io_enq_1_bits_uop_fpu_rm(io_enq_1_bits_uop_fpu_rm),
    .io_enq_1_bits_uop_vpu_vill(io_enq_1_bits_uop_vpu_vill),
    .io_enq_1_bits_uop_vpu_vma(io_enq_1_bits_uop_vpu_vma),
    .io_enq_1_bits_uop_vpu_vta(io_enq_1_bits_uop_vpu_vta),
    .io_enq_1_bits_uop_vpu_vsew(io_enq_1_bits_uop_vpu_vsew),
    .io_enq_1_bits_uop_vpu_vlmul(io_enq_1_bits_uop_vpu_vlmul),
    .io_enq_1_bits_uop_vpu_specVill(io_enq_1_bits_uop_vpu_specVill),
    .io_enq_1_bits_uop_vpu_specVma(io_enq_1_bits_uop_vpu_specVma),
    .io_enq_1_bits_uop_vpu_specVta(io_enq_1_bits_uop_vpu_specVta),
    .io_enq_1_bits_uop_vpu_specVsew(io_enq_1_bits_uop_vpu_specVsew),
    .io_enq_1_bits_uop_vpu_specVlmul(io_enq_1_bits_uop_vpu_specVlmul),
    .io_enq_1_bits_uop_vpu_vm(io_enq_1_bits_uop_vpu_vm),
    .io_enq_1_bits_uop_vpu_vstart(io_enq_1_bits_uop_vpu_vstart),
    .io_enq_1_bits_uop_vpu_frm(io_enq_1_bits_uop_vpu_frm),
    .io_enq_1_bits_uop_vpu_fpu_isFpToVecInst(io_enq_1_bits_uop_vpu_fpu_isFpToVecInst),
    .io_enq_1_bits_uop_vpu_fpu_isFP32Instr(io_enq_1_bits_uop_vpu_fpu_isFP32Instr),
    .io_enq_1_bits_uop_vpu_fpu_isFP64Instr(io_enq_1_bits_uop_vpu_fpu_isFP64Instr),
    .io_enq_1_bits_uop_vpu_fpu_isReduction(io_enq_1_bits_uop_vpu_fpu_isReduction),
    .io_enq_1_bits_uop_vpu_fpu_isFoldTo1_2(io_enq_1_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_enq_1_bits_uop_vpu_fpu_isFoldTo1_4(io_enq_1_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_enq_1_bits_uop_vpu_fpu_isFoldTo1_8(io_enq_1_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_enq_1_bits_uop_vpu_vxrm(io_enq_1_bits_uop_vpu_vxrm),
    .io_enq_1_bits_uop_vpu_vuopIdx(io_enq_1_bits_uop_vpu_vuopIdx),
    .io_enq_1_bits_uop_vpu_lastUop(io_enq_1_bits_uop_vpu_lastUop),
    .io_enq_1_bits_uop_vpu_vmask(io_enq_1_bits_uop_vpu_vmask),
    .io_enq_1_bits_uop_vpu_vl(io_enq_1_bits_uop_vpu_vl),
    .io_enq_1_bits_uop_vpu_nf(io_enq_1_bits_uop_vpu_nf),
    .io_enq_1_bits_uop_vpu_veew(io_enq_1_bits_uop_vpu_veew),
    .io_enq_1_bits_uop_vpu_isReverse(io_enq_1_bits_uop_vpu_isReverse),
    .io_enq_1_bits_uop_vpu_isExt(io_enq_1_bits_uop_vpu_isExt),
    .io_enq_1_bits_uop_vpu_isNarrow(io_enq_1_bits_uop_vpu_isNarrow),
    .io_enq_1_bits_uop_vpu_isDstMask(io_enq_1_bits_uop_vpu_isDstMask),
    .io_enq_1_bits_uop_vpu_isOpMask(io_enq_1_bits_uop_vpu_isOpMask),
    .io_enq_1_bits_uop_vpu_isMove(io_enq_1_bits_uop_vpu_isMove),
    .io_enq_1_bits_uop_vpu_isDependOldVd(io_enq_1_bits_uop_vpu_isDependOldVd),
    .io_enq_1_bits_uop_vpu_isWritePartVd(io_enq_1_bits_uop_vpu_isWritePartVd),
    .io_enq_1_bits_uop_vpu_isVleff(io_enq_1_bits_uop_vpu_isVleff),
    .io_enq_1_bits_uop_vlsInstr(io_enq_1_bits_uop_vlsInstr),
    .io_enq_1_bits_uop_wfflags(io_enq_1_bits_uop_wfflags),
    .io_enq_1_bits_uop_isMove(io_enq_1_bits_uop_isMove),
    .io_enq_1_bits_uop_isDropAmocasSta(io_enq_1_bits_uop_isDropAmocasSta),
    .io_enq_1_bits_uop_uopIdx(io_enq_1_bits_uop_uopIdx),
    .io_enq_1_bits_uop_isVset(io_enq_1_bits_uop_isVset),
    .io_enq_1_bits_uop_firstUop(io_enq_1_bits_uop_firstUop),
    .io_enq_1_bits_uop_lastUop(io_enq_1_bits_uop_lastUop),
    .io_enq_1_bits_uop_numUops(io_enq_1_bits_uop_numUops),
    .io_enq_1_bits_uop_numWB(io_enq_1_bits_uop_numWB),
    .io_enq_1_bits_uop_commitType(io_enq_1_bits_uop_commitType),
    .io_enq_1_bits_uop_srcState_0(io_enq_1_bits_uop_srcState_0),
    .io_enq_1_bits_uop_srcState_1(io_enq_1_bits_uop_srcState_1),
    .io_enq_1_bits_uop_srcState_2(io_enq_1_bits_uop_srcState_2),
    .io_enq_1_bits_uop_srcState_3(io_enq_1_bits_uop_srcState_3),
    .io_enq_1_bits_uop_srcState_4(io_enq_1_bits_uop_srcState_4),
    .io_enq_1_bits_uop_srcLoadDependency_0_0(io_enq_1_bits_uop_srcLoadDependency_0_0),
    .io_enq_1_bits_uop_srcLoadDependency_0_1(io_enq_1_bits_uop_srcLoadDependency_0_1),
    .io_enq_1_bits_uop_srcLoadDependency_0_2(io_enq_1_bits_uop_srcLoadDependency_0_2),
    .io_enq_1_bits_uop_srcLoadDependency_1_0(io_enq_1_bits_uop_srcLoadDependency_1_0),
    .io_enq_1_bits_uop_srcLoadDependency_1_1(io_enq_1_bits_uop_srcLoadDependency_1_1),
    .io_enq_1_bits_uop_srcLoadDependency_1_2(io_enq_1_bits_uop_srcLoadDependency_1_2),
    .io_enq_1_bits_uop_srcLoadDependency_2_0(io_enq_1_bits_uop_srcLoadDependency_2_0),
    .io_enq_1_bits_uop_srcLoadDependency_2_1(io_enq_1_bits_uop_srcLoadDependency_2_1),
    .io_enq_1_bits_uop_srcLoadDependency_2_2(io_enq_1_bits_uop_srcLoadDependency_2_2),
    .io_enq_1_bits_uop_srcLoadDependency_3_0(io_enq_1_bits_uop_srcLoadDependency_3_0),
    .io_enq_1_bits_uop_srcLoadDependency_3_1(io_enq_1_bits_uop_srcLoadDependency_3_1),
    .io_enq_1_bits_uop_srcLoadDependency_3_2(io_enq_1_bits_uop_srcLoadDependency_3_2),
    .io_enq_1_bits_uop_srcLoadDependency_4_0(io_enq_1_bits_uop_srcLoadDependency_4_0),
    .io_enq_1_bits_uop_srcLoadDependency_4_1(io_enq_1_bits_uop_srcLoadDependency_4_1),
    .io_enq_1_bits_uop_srcLoadDependency_4_2(io_enq_1_bits_uop_srcLoadDependency_4_2),
    .io_enq_1_bits_uop_psrc_0(io_enq_1_bits_uop_psrc_0),
    .io_enq_1_bits_uop_psrc_1(io_enq_1_bits_uop_psrc_1),
    .io_enq_1_bits_uop_psrc_2(io_enq_1_bits_uop_psrc_2),
    .io_enq_1_bits_uop_psrc_3(io_enq_1_bits_uop_psrc_3),
    .io_enq_1_bits_uop_psrc_4(io_enq_1_bits_uop_psrc_4),
    .io_enq_1_bits_uop_pdest(io_enq_1_bits_uop_pdest),
    .io_enq_1_bits_uop_useRegCache_0(io_enq_1_bits_uop_useRegCache_0),
    .io_enq_1_bits_uop_useRegCache_1(io_enq_1_bits_uop_useRegCache_1),
    .io_enq_1_bits_uop_regCacheIdx_0(io_enq_1_bits_uop_regCacheIdx_0),
    .io_enq_1_bits_uop_regCacheIdx_1(io_enq_1_bits_uop_regCacheIdx_1),
    .io_enq_1_bits_uop_robIdx_flag(io_enq_1_bits_uop_robIdx_flag),
    .io_enq_1_bits_uop_robIdx_value(io_enq_1_bits_uop_robIdx_value),
    .io_enq_1_bits_uop_instrSize(io_enq_1_bits_uop_instrSize),
    .io_enq_1_bits_uop_dirtyFs(io_enq_1_bits_uop_dirtyFs),
    .io_enq_1_bits_uop_dirtyVs(io_enq_1_bits_uop_dirtyVs),
    .io_enq_1_bits_uop_traceBlockInPipe_itype(io_enq_1_bits_uop_traceBlockInPipe_itype),
    .io_enq_1_bits_uop_traceBlockInPipe_iretire(io_enq_1_bits_uop_traceBlockInPipe_iretire),
    .io_enq_1_bits_uop_traceBlockInPipe_ilastsize(io_enq_1_bits_uop_traceBlockInPipe_ilastsize),
    .io_enq_1_bits_uop_eliminatedMove(io_enq_1_bits_uop_eliminatedMove),
    .io_enq_1_bits_uop_snapshot(io_enq_1_bits_uop_snapshot),
    .io_enq_1_bits_uop_debugInfo_eliminatedMove(io_enq_1_bits_uop_debugInfo_eliminatedMove),
    .io_enq_1_bits_uop_debugInfo_renameTime(io_enq_1_bits_uop_debugInfo_renameTime),
    .io_enq_1_bits_uop_debugInfo_dispatchTime(io_enq_1_bits_uop_debugInfo_dispatchTime),
    .io_enq_1_bits_uop_debugInfo_enqRsTime(io_enq_1_bits_uop_debugInfo_enqRsTime),
    .io_enq_1_bits_uop_debugInfo_selectTime(io_enq_1_bits_uop_debugInfo_selectTime),
    .io_enq_1_bits_uop_debugInfo_issueTime(io_enq_1_bits_uop_debugInfo_issueTime),
    .io_enq_1_bits_uop_debugInfo_writebackTime(io_enq_1_bits_uop_debugInfo_writebackTime),
    .io_enq_1_bits_uop_debugInfo_runahead_checkpoint_id(io_enq_1_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_enq_1_bits_uop_debugInfo_tlbFirstReqTime(io_enq_1_bits_uop_debugInfo_tlbFirstReqTime),
    .io_enq_1_bits_uop_debugInfo_tlbRespTime(io_enq_1_bits_uop_debugInfo_tlbRespTime),
    .io_enq_1_bits_uop_debug_seqNum_seqNum(io_enq_1_bits_uop_debug_seqNum_seqNum),
    .io_enq_1_bits_uop_debug_seqNum_uopIdx(io_enq_1_bits_uop_debug_seqNum_uopIdx),
    .io_enq_1_bits_uop_storeSetHit(io_enq_1_bits_uop_storeSetHit),
    .io_enq_1_bits_uop_waitForRobIdx_flag(io_enq_1_bits_uop_waitForRobIdx_flag),
    .io_enq_1_bits_uop_waitForRobIdx_value(io_enq_1_bits_uop_waitForRobIdx_value),
    .io_enq_1_bits_uop_loadWaitBit(io_enq_1_bits_uop_loadWaitBit),
    .io_enq_1_bits_uop_loadWaitStrict(io_enq_1_bits_uop_loadWaitStrict),
    .io_enq_1_bits_uop_ssid(io_enq_1_bits_uop_ssid),
    .io_enq_1_bits_uop_lqIdx_flag(io_enq_1_bits_uop_lqIdx_flag),
    .io_enq_1_bits_uop_lqIdx_value(io_enq_1_bits_uop_lqIdx_value),
    .io_enq_1_bits_uop_sqIdx_flag(io_enq_1_bits_uop_sqIdx_flag),
    .io_enq_1_bits_uop_sqIdx_value(io_enq_1_bits_uop_sqIdx_value),
    .io_enq_1_bits_uop_singleStep(io_enq_1_bits_uop_singleStep),
    .io_enq_1_bits_uop_debug_fuType(io_enq_1_bits_uop_debug_fuType),
    .io_enq_1_bits_uop_debug_sim_trig(io_enq_1_bits_uop_debug_sim_trig),
    .io_enq_1_bits_uop_numLsElem(io_enq_1_bits_uop_numLsElem),
    .io_enq_1_bits_vaddr(io_enq_1_bits_vaddr),
    .io_enq_1_bits_mask(io_enq_1_bits_mask),
    .io_enq_1_bits_isvec(io_enq_1_bits_isvec),
    .io_enq_1_bits_is128bit(io_enq_1_bits_is128bit),
    .io_enq_1_bits_elemIdx(io_enq_1_bits_elemIdx),
    .io_enq_1_bits_alignedType(io_enq_1_bits_alignedType),
    .io_enq_1_bits_mbIndex(io_enq_1_bits_mbIndex),
    .io_enq_1_bits_reg_offset(io_enq_1_bits_reg_offset),
    .io_enq_1_bits_elemIdxInsideVd(io_enq_1_bits_elemIdxInsideVd),
    .io_enq_1_bits_vecActive(io_enq_1_bits_vecActive),
    .io_enq_1_bits_isLoadReplay(io_enq_1_bits_isLoadReplay),
    .io_enq_1_bits_handledByMSHR(io_enq_1_bits_handledByMSHR),
    .io_enq_1_bits_schedIndex(io_enq_1_bits_schedIndex),
    .io_enq_1_bits_rep_info_mshr_id(io_enq_1_bits_rep_info_mshr_id),
    .io_enq_1_bits_rep_info_full_fwd(io_enq_1_bits_rep_info_full_fwd),
    .io_enq_1_bits_rep_info_data_inv_sq_idx_flag(io_enq_1_bits_rep_info_data_inv_sq_idx_flag),
    .io_enq_1_bits_rep_info_data_inv_sq_idx_value(io_enq_1_bits_rep_info_data_inv_sq_idx_value),
    .io_enq_1_bits_rep_info_addr_inv_sq_idx_flag(io_enq_1_bits_rep_info_addr_inv_sq_idx_flag),
    .io_enq_1_bits_rep_info_addr_inv_sq_idx_value(io_enq_1_bits_rep_info_addr_inv_sq_idx_value),
    .io_enq_1_bits_rep_info_last_beat(io_enq_1_bits_rep_info_last_beat),
    .io_enq_1_bits_rep_info_cause_0(io_enq_1_bits_rep_info_cause_0),
    .io_enq_1_bits_rep_info_cause_1(io_enq_1_bits_rep_info_cause_1),
    .io_enq_1_bits_rep_info_cause_2(io_enq_1_bits_rep_info_cause_2),
    .io_enq_1_bits_rep_info_cause_3(io_enq_1_bits_rep_info_cause_3),
    .io_enq_1_bits_rep_info_cause_4(io_enq_1_bits_rep_info_cause_4),
    .io_enq_1_bits_rep_info_cause_5(io_enq_1_bits_rep_info_cause_5),
    .io_enq_1_bits_rep_info_cause_6(io_enq_1_bits_rep_info_cause_6),
    .io_enq_1_bits_rep_info_cause_7(io_enq_1_bits_rep_info_cause_7),
    .io_enq_1_bits_rep_info_cause_8(io_enq_1_bits_rep_info_cause_8),
    .io_enq_1_bits_rep_info_cause_9(io_enq_1_bits_rep_info_cause_9),
    .io_enq_1_bits_rep_info_cause_10(io_enq_1_bits_rep_info_cause_10),
    .io_enq_1_bits_rep_info_tlb_id(io_enq_1_bits_rep_info_tlb_id),
    .io_enq_1_bits_rep_info_tlb_full(io_enq_1_bits_rep_info_tlb_full),
    .io_enq_2_valid(io_enq_2_valid),
    .io_enq_2_bits_uop_instr(io_enq_2_bits_uop_instr),
    .io_enq_2_bits_uop_pc(io_enq_2_bits_uop_pc),
    .io_enq_2_bits_uop_foldpc(io_enq_2_bits_uop_foldpc),
    .io_enq_2_bits_uop_exceptionVec_0(io_enq_2_bits_uop_exceptionVec_0),
    .io_enq_2_bits_uop_exceptionVec_1(io_enq_2_bits_uop_exceptionVec_1),
    .io_enq_2_bits_uop_exceptionVec_2(io_enq_2_bits_uop_exceptionVec_2),
    .io_enq_2_bits_uop_exceptionVec_3(io_enq_2_bits_uop_exceptionVec_3),
    .io_enq_2_bits_uop_exceptionVec_5(io_enq_2_bits_uop_exceptionVec_5),
    .io_enq_2_bits_uop_exceptionVec_6(io_enq_2_bits_uop_exceptionVec_6),
    .io_enq_2_bits_uop_exceptionVec_7(io_enq_2_bits_uop_exceptionVec_7),
    .io_enq_2_bits_uop_exceptionVec_8(io_enq_2_bits_uop_exceptionVec_8),
    .io_enq_2_bits_uop_exceptionVec_9(io_enq_2_bits_uop_exceptionVec_9),
    .io_enq_2_bits_uop_exceptionVec_10(io_enq_2_bits_uop_exceptionVec_10),
    .io_enq_2_bits_uop_exceptionVec_11(io_enq_2_bits_uop_exceptionVec_11),
    .io_enq_2_bits_uop_exceptionVec_12(io_enq_2_bits_uop_exceptionVec_12),
    .io_enq_2_bits_uop_exceptionVec_13(io_enq_2_bits_uop_exceptionVec_13),
    .io_enq_2_bits_uop_exceptionVec_14(io_enq_2_bits_uop_exceptionVec_14),
    .io_enq_2_bits_uop_exceptionVec_15(io_enq_2_bits_uop_exceptionVec_15),
    .io_enq_2_bits_uop_exceptionVec_16(io_enq_2_bits_uop_exceptionVec_16),
    .io_enq_2_bits_uop_exceptionVec_17(io_enq_2_bits_uop_exceptionVec_17),
    .io_enq_2_bits_uop_exceptionVec_18(io_enq_2_bits_uop_exceptionVec_18),
    .io_enq_2_bits_uop_exceptionVec_19(io_enq_2_bits_uop_exceptionVec_19),
    .io_enq_2_bits_uop_exceptionVec_20(io_enq_2_bits_uop_exceptionVec_20),
    .io_enq_2_bits_uop_exceptionVec_21(io_enq_2_bits_uop_exceptionVec_21),
    .io_enq_2_bits_uop_exceptionVec_22(io_enq_2_bits_uop_exceptionVec_22),
    .io_enq_2_bits_uop_exceptionVec_23(io_enq_2_bits_uop_exceptionVec_23),
    .io_enq_2_bits_uop_isFetchMalAddr(io_enq_2_bits_uop_isFetchMalAddr),
    .io_enq_2_bits_uop_hasException(io_enq_2_bits_uop_hasException),
    .io_enq_2_bits_uop_trigger(io_enq_2_bits_uop_trigger),
    .io_enq_2_bits_uop_preDecodeInfo_valid(io_enq_2_bits_uop_preDecodeInfo_valid),
    .io_enq_2_bits_uop_preDecodeInfo_isRVC(io_enq_2_bits_uop_preDecodeInfo_isRVC),
    .io_enq_2_bits_uop_preDecodeInfo_brType(io_enq_2_bits_uop_preDecodeInfo_brType),
    .io_enq_2_bits_uop_preDecodeInfo_isCall(io_enq_2_bits_uop_preDecodeInfo_isCall),
    .io_enq_2_bits_uop_preDecodeInfo_isRet(io_enq_2_bits_uop_preDecodeInfo_isRet),
    .io_enq_2_bits_uop_pred_taken(io_enq_2_bits_uop_pred_taken),
    .io_enq_2_bits_uop_crossPageIPFFix(io_enq_2_bits_uop_crossPageIPFFix),
    .io_enq_2_bits_uop_ftqPtr_flag(io_enq_2_bits_uop_ftqPtr_flag),
    .io_enq_2_bits_uop_ftqPtr_value(io_enq_2_bits_uop_ftqPtr_value),
    .io_enq_2_bits_uop_ftqOffset(io_enq_2_bits_uop_ftqOffset),
    .io_enq_2_bits_uop_satpFlushFirstFetchFault(io_enq_2_bits_uop_satpFlushFirstFetchFault),
    .io_enq_2_bits_uop_srcType_0(io_enq_2_bits_uop_srcType_0),
    .io_enq_2_bits_uop_srcType_1(io_enq_2_bits_uop_srcType_1),
    .io_enq_2_bits_uop_srcType_2(io_enq_2_bits_uop_srcType_2),
    .io_enq_2_bits_uop_srcType_3(io_enq_2_bits_uop_srcType_3),
    .io_enq_2_bits_uop_srcType_4(io_enq_2_bits_uop_srcType_4),
    .io_enq_2_bits_uop_ldest(io_enq_2_bits_uop_ldest),
    .io_enq_2_bits_uop_fuType(io_enq_2_bits_uop_fuType),
    .io_enq_2_bits_uop_fuOpType(io_enq_2_bits_uop_fuOpType),
    .io_enq_2_bits_uop_rfWen(io_enq_2_bits_uop_rfWen),
    .io_enq_2_bits_uop_fpWen(io_enq_2_bits_uop_fpWen),
    .io_enq_2_bits_uop_vecWen(io_enq_2_bits_uop_vecWen),
    .io_enq_2_bits_uop_v0Wen(io_enq_2_bits_uop_v0Wen),
    .io_enq_2_bits_uop_vlWen(io_enq_2_bits_uop_vlWen),
    .io_enq_2_bits_uop_isXSTrap(io_enq_2_bits_uop_isXSTrap),
    .io_enq_2_bits_uop_waitForward(io_enq_2_bits_uop_waitForward),
    .io_enq_2_bits_uop_blockBackward(io_enq_2_bits_uop_blockBackward),
    .io_enq_2_bits_uop_canRobCompress(io_enq_2_bits_uop_canRobCompress),
    .io_enq_2_bits_uop_selImm(io_enq_2_bits_uop_selImm),
    .io_enq_2_bits_uop_imm(io_enq_2_bits_uop_imm),
    .io_enq_2_bits_uop_fpu_typeTagOut(io_enq_2_bits_uop_fpu_typeTagOut),
    .io_enq_2_bits_uop_fpu_wflags(io_enq_2_bits_uop_fpu_wflags),
    .io_enq_2_bits_uop_fpu_typ(io_enq_2_bits_uop_fpu_typ),
    .io_enq_2_bits_uop_fpu_fmt(io_enq_2_bits_uop_fpu_fmt),
    .io_enq_2_bits_uop_fpu_rm(io_enq_2_bits_uop_fpu_rm),
    .io_enq_2_bits_uop_vpu_vill(io_enq_2_bits_uop_vpu_vill),
    .io_enq_2_bits_uop_vpu_vma(io_enq_2_bits_uop_vpu_vma),
    .io_enq_2_bits_uop_vpu_vta(io_enq_2_bits_uop_vpu_vta),
    .io_enq_2_bits_uop_vpu_vsew(io_enq_2_bits_uop_vpu_vsew),
    .io_enq_2_bits_uop_vpu_vlmul(io_enq_2_bits_uop_vpu_vlmul),
    .io_enq_2_bits_uop_vpu_specVill(io_enq_2_bits_uop_vpu_specVill),
    .io_enq_2_bits_uop_vpu_specVma(io_enq_2_bits_uop_vpu_specVma),
    .io_enq_2_bits_uop_vpu_specVta(io_enq_2_bits_uop_vpu_specVta),
    .io_enq_2_bits_uop_vpu_specVsew(io_enq_2_bits_uop_vpu_specVsew),
    .io_enq_2_bits_uop_vpu_specVlmul(io_enq_2_bits_uop_vpu_specVlmul),
    .io_enq_2_bits_uop_vpu_vm(io_enq_2_bits_uop_vpu_vm),
    .io_enq_2_bits_uop_vpu_vstart(io_enq_2_bits_uop_vpu_vstart),
    .io_enq_2_bits_uop_vpu_frm(io_enq_2_bits_uop_vpu_frm),
    .io_enq_2_bits_uop_vpu_fpu_isFpToVecInst(io_enq_2_bits_uop_vpu_fpu_isFpToVecInst),
    .io_enq_2_bits_uop_vpu_fpu_isFP32Instr(io_enq_2_bits_uop_vpu_fpu_isFP32Instr),
    .io_enq_2_bits_uop_vpu_fpu_isFP64Instr(io_enq_2_bits_uop_vpu_fpu_isFP64Instr),
    .io_enq_2_bits_uop_vpu_fpu_isReduction(io_enq_2_bits_uop_vpu_fpu_isReduction),
    .io_enq_2_bits_uop_vpu_fpu_isFoldTo1_2(io_enq_2_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_enq_2_bits_uop_vpu_fpu_isFoldTo1_4(io_enq_2_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_enq_2_bits_uop_vpu_fpu_isFoldTo1_8(io_enq_2_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_enq_2_bits_uop_vpu_vxrm(io_enq_2_bits_uop_vpu_vxrm),
    .io_enq_2_bits_uop_vpu_vuopIdx(io_enq_2_bits_uop_vpu_vuopIdx),
    .io_enq_2_bits_uop_vpu_lastUop(io_enq_2_bits_uop_vpu_lastUop),
    .io_enq_2_bits_uop_vpu_vmask(io_enq_2_bits_uop_vpu_vmask),
    .io_enq_2_bits_uop_vpu_vl(io_enq_2_bits_uop_vpu_vl),
    .io_enq_2_bits_uop_vpu_nf(io_enq_2_bits_uop_vpu_nf),
    .io_enq_2_bits_uop_vpu_veew(io_enq_2_bits_uop_vpu_veew),
    .io_enq_2_bits_uop_vpu_isReverse(io_enq_2_bits_uop_vpu_isReverse),
    .io_enq_2_bits_uop_vpu_isExt(io_enq_2_bits_uop_vpu_isExt),
    .io_enq_2_bits_uop_vpu_isNarrow(io_enq_2_bits_uop_vpu_isNarrow),
    .io_enq_2_bits_uop_vpu_isDstMask(io_enq_2_bits_uop_vpu_isDstMask),
    .io_enq_2_bits_uop_vpu_isOpMask(io_enq_2_bits_uop_vpu_isOpMask),
    .io_enq_2_bits_uop_vpu_isMove(io_enq_2_bits_uop_vpu_isMove),
    .io_enq_2_bits_uop_vpu_isDependOldVd(io_enq_2_bits_uop_vpu_isDependOldVd),
    .io_enq_2_bits_uop_vpu_isWritePartVd(io_enq_2_bits_uop_vpu_isWritePartVd),
    .io_enq_2_bits_uop_vpu_isVleff(io_enq_2_bits_uop_vpu_isVleff),
    .io_enq_2_bits_uop_vlsInstr(io_enq_2_bits_uop_vlsInstr),
    .io_enq_2_bits_uop_wfflags(io_enq_2_bits_uop_wfflags),
    .io_enq_2_bits_uop_isMove(io_enq_2_bits_uop_isMove),
    .io_enq_2_bits_uop_isDropAmocasSta(io_enq_2_bits_uop_isDropAmocasSta),
    .io_enq_2_bits_uop_uopIdx(io_enq_2_bits_uop_uopIdx),
    .io_enq_2_bits_uop_isVset(io_enq_2_bits_uop_isVset),
    .io_enq_2_bits_uop_firstUop(io_enq_2_bits_uop_firstUop),
    .io_enq_2_bits_uop_lastUop(io_enq_2_bits_uop_lastUop),
    .io_enq_2_bits_uop_numUops(io_enq_2_bits_uop_numUops),
    .io_enq_2_bits_uop_numWB(io_enq_2_bits_uop_numWB),
    .io_enq_2_bits_uop_commitType(io_enq_2_bits_uop_commitType),
    .io_enq_2_bits_uop_srcState_0(io_enq_2_bits_uop_srcState_0),
    .io_enq_2_bits_uop_srcState_1(io_enq_2_bits_uop_srcState_1),
    .io_enq_2_bits_uop_srcState_2(io_enq_2_bits_uop_srcState_2),
    .io_enq_2_bits_uop_srcState_3(io_enq_2_bits_uop_srcState_3),
    .io_enq_2_bits_uop_srcState_4(io_enq_2_bits_uop_srcState_4),
    .io_enq_2_bits_uop_srcLoadDependency_0_0(io_enq_2_bits_uop_srcLoadDependency_0_0),
    .io_enq_2_bits_uop_srcLoadDependency_0_1(io_enq_2_bits_uop_srcLoadDependency_0_1),
    .io_enq_2_bits_uop_srcLoadDependency_0_2(io_enq_2_bits_uop_srcLoadDependency_0_2),
    .io_enq_2_bits_uop_srcLoadDependency_1_0(io_enq_2_bits_uop_srcLoadDependency_1_0),
    .io_enq_2_bits_uop_srcLoadDependency_1_1(io_enq_2_bits_uop_srcLoadDependency_1_1),
    .io_enq_2_bits_uop_srcLoadDependency_1_2(io_enq_2_bits_uop_srcLoadDependency_1_2),
    .io_enq_2_bits_uop_srcLoadDependency_2_0(io_enq_2_bits_uop_srcLoadDependency_2_0),
    .io_enq_2_bits_uop_srcLoadDependency_2_1(io_enq_2_bits_uop_srcLoadDependency_2_1),
    .io_enq_2_bits_uop_srcLoadDependency_2_2(io_enq_2_bits_uop_srcLoadDependency_2_2),
    .io_enq_2_bits_uop_srcLoadDependency_3_0(io_enq_2_bits_uop_srcLoadDependency_3_0),
    .io_enq_2_bits_uop_srcLoadDependency_3_1(io_enq_2_bits_uop_srcLoadDependency_3_1),
    .io_enq_2_bits_uop_srcLoadDependency_3_2(io_enq_2_bits_uop_srcLoadDependency_3_2),
    .io_enq_2_bits_uop_srcLoadDependency_4_0(io_enq_2_bits_uop_srcLoadDependency_4_0),
    .io_enq_2_bits_uop_srcLoadDependency_4_1(io_enq_2_bits_uop_srcLoadDependency_4_1),
    .io_enq_2_bits_uop_srcLoadDependency_4_2(io_enq_2_bits_uop_srcLoadDependency_4_2),
    .io_enq_2_bits_uop_psrc_0(io_enq_2_bits_uop_psrc_0),
    .io_enq_2_bits_uop_psrc_1(io_enq_2_bits_uop_psrc_1),
    .io_enq_2_bits_uop_psrc_2(io_enq_2_bits_uop_psrc_2),
    .io_enq_2_bits_uop_psrc_3(io_enq_2_bits_uop_psrc_3),
    .io_enq_2_bits_uop_psrc_4(io_enq_2_bits_uop_psrc_4),
    .io_enq_2_bits_uop_pdest(io_enq_2_bits_uop_pdest),
    .io_enq_2_bits_uop_useRegCache_0(io_enq_2_bits_uop_useRegCache_0),
    .io_enq_2_bits_uop_useRegCache_1(io_enq_2_bits_uop_useRegCache_1),
    .io_enq_2_bits_uop_regCacheIdx_0(io_enq_2_bits_uop_regCacheIdx_0),
    .io_enq_2_bits_uop_regCacheIdx_1(io_enq_2_bits_uop_regCacheIdx_1),
    .io_enq_2_bits_uop_robIdx_flag(io_enq_2_bits_uop_robIdx_flag),
    .io_enq_2_bits_uop_robIdx_value(io_enq_2_bits_uop_robIdx_value),
    .io_enq_2_bits_uop_instrSize(io_enq_2_bits_uop_instrSize),
    .io_enq_2_bits_uop_dirtyFs(io_enq_2_bits_uop_dirtyFs),
    .io_enq_2_bits_uop_dirtyVs(io_enq_2_bits_uop_dirtyVs),
    .io_enq_2_bits_uop_traceBlockInPipe_itype(io_enq_2_bits_uop_traceBlockInPipe_itype),
    .io_enq_2_bits_uop_traceBlockInPipe_iretire(io_enq_2_bits_uop_traceBlockInPipe_iretire),
    .io_enq_2_bits_uop_traceBlockInPipe_ilastsize(io_enq_2_bits_uop_traceBlockInPipe_ilastsize),
    .io_enq_2_bits_uop_eliminatedMove(io_enq_2_bits_uop_eliminatedMove),
    .io_enq_2_bits_uop_snapshot(io_enq_2_bits_uop_snapshot),
    .io_enq_2_bits_uop_debugInfo_eliminatedMove(io_enq_2_bits_uop_debugInfo_eliminatedMove),
    .io_enq_2_bits_uop_debugInfo_renameTime(io_enq_2_bits_uop_debugInfo_renameTime),
    .io_enq_2_bits_uop_debugInfo_dispatchTime(io_enq_2_bits_uop_debugInfo_dispatchTime),
    .io_enq_2_bits_uop_debugInfo_enqRsTime(io_enq_2_bits_uop_debugInfo_enqRsTime),
    .io_enq_2_bits_uop_debugInfo_selectTime(io_enq_2_bits_uop_debugInfo_selectTime),
    .io_enq_2_bits_uop_debugInfo_issueTime(io_enq_2_bits_uop_debugInfo_issueTime),
    .io_enq_2_bits_uop_debugInfo_writebackTime(io_enq_2_bits_uop_debugInfo_writebackTime),
    .io_enq_2_bits_uop_debugInfo_runahead_checkpoint_id(io_enq_2_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_enq_2_bits_uop_debugInfo_tlbFirstReqTime(io_enq_2_bits_uop_debugInfo_tlbFirstReqTime),
    .io_enq_2_bits_uop_debugInfo_tlbRespTime(io_enq_2_bits_uop_debugInfo_tlbRespTime),
    .io_enq_2_bits_uop_debug_seqNum_seqNum(io_enq_2_bits_uop_debug_seqNum_seqNum),
    .io_enq_2_bits_uop_debug_seqNum_uopIdx(io_enq_2_bits_uop_debug_seqNum_uopIdx),
    .io_enq_2_bits_uop_storeSetHit(io_enq_2_bits_uop_storeSetHit),
    .io_enq_2_bits_uop_waitForRobIdx_flag(io_enq_2_bits_uop_waitForRobIdx_flag),
    .io_enq_2_bits_uop_waitForRobIdx_value(io_enq_2_bits_uop_waitForRobIdx_value),
    .io_enq_2_bits_uop_loadWaitBit(io_enq_2_bits_uop_loadWaitBit),
    .io_enq_2_bits_uop_loadWaitStrict(io_enq_2_bits_uop_loadWaitStrict),
    .io_enq_2_bits_uop_ssid(io_enq_2_bits_uop_ssid),
    .io_enq_2_bits_uop_lqIdx_flag(io_enq_2_bits_uop_lqIdx_flag),
    .io_enq_2_bits_uop_lqIdx_value(io_enq_2_bits_uop_lqIdx_value),
    .io_enq_2_bits_uop_sqIdx_flag(io_enq_2_bits_uop_sqIdx_flag),
    .io_enq_2_bits_uop_sqIdx_value(io_enq_2_bits_uop_sqIdx_value),
    .io_enq_2_bits_uop_singleStep(io_enq_2_bits_uop_singleStep),
    .io_enq_2_bits_uop_debug_fuType(io_enq_2_bits_uop_debug_fuType),
    .io_enq_2_bits_uop_debug_sim_trig(io_enq_2_bits_uop_debug_sim_trig),
    .io_enq_2_bits_uop_numLsElem(io_enq_2_bits_uop_numLsElem),
    .io_enq_2_bits_vaddr(io_enq_2_bits_vaddr),
    .io_enq_2_bits_mask(io_enq_2_bits_mask),
    .io_enq_2_bits_isvec(io_enq_2_bits_isvec),
    .io_enq_2_bits_is128bit(io_enq_2_bits_is128bit),
    .io_enq_2_bits_elemIdx(io_enq_2_bits_elemIdx),
    .io_enq_2_bits_alignedType(io_enq_2_bits_alignedType),
    .io_enq_2_bits_mbIndex(io_enq_2_bits_mbIndex),
    .io_enq_2_bits_reg_offset(io_enq_2_bits_reg_offset),
    .io_enq_2_bits_elemIdxInsideVd(io_enq_2_bits_elemIdxInsideVd),
    .io_enq_2_bits_vecActive(io_enq_2_bits_vecActive),
    .io_enq_2_bits_isLoadReplay(io_enq_2_bits_isLoadReplay),
    .io_enq_2_bits_handledByMSHR(io_enq_2_bits_handledByMSHR),
    .io_enq_2_bits_schedIndex(io_enq_2_bits_schedIndex),
    .io_enq_2_bits_rep_info_mshr_id(io_enq_2_bits_rep_info_mshr_id),
    .io_enq_2_bits_rep_info_full_fwd(io_enq_2_bits_rep_info_full_fwd),
    .io_enq_2_bits_rep_info_data_inv_sq_idx_flag(io_enq_2_bits_rep_info_data_inv_sq_idx_flag),
    .io_enq_2_bits_rep_info_data_inv_sq_idx_value(io_enq_2_bits_rep_info_data_inv_sq_idx_value),
    .io_enq_2_bits_rep_info_addr_inv_sq_idx_flag(io_enq_2_bits_rep_info_addr_inv_sq_idx_flag),
    .io_enq_2_bits_rep_info_addr_inv_sq_idx_value(io_enq_2_bits_rep_info_addr_inv_sq_idx_value),
    .io_enq_2_bits_rep_info_last_beat(io_enq_2_bits_rep_info_last_beat),
    .io_enq_2_bits_rep_info_cause_0(io_enq_2_bits_rep_info_cause_0),
    .io_enq_2_bits_rep_info_cause_1(io_enq_2_bits_rep_info_cause_1),
    .io_enq_2_bits_rep_info_cause_2(io_enq_2_bits_rep_info_cause_2),
    .io_enq_2_bits_rep_info_cause_3(io_enq_2_bits_rep_info_cause_3),
    .io_enq_2_bits_rep_info_cause_4(io_enq_2_bits_rep_info_cause_4),
    .io_enq_2_bits_rep_info_cause_5(io_enq_2_bits_rep_info_cause_5),
    .io_enq_2_bits_rep_info_cause_6(io_enq_2_bits_rep_info_cause_6),
    .io_enq_2_bits_rep_info_cause_7(io_enq_2_bits_rep_info_cause_7),
    .io_enq_2_bits_rep_info_cause_8(io_enq_2_bits_rep_info_cause_8),
    .io_enq_2_bits_rep_info_cause_9(io_enq_2_bits_rep_info_cause_9),
    .io_enq_2_bits_rep_info_cause_10(io_enq_2_bits_rep_info_cause_10),
    .io_enq_2_bits_rep_info_tlb_id(io_enq_2_bits_rep_info_tlb_id),
    .io_enq_2_bits_rep_info_tlb_full(io_enq_2_bits_rep_info_tlb_full),
    .io_storeAddrIn_0_valid(io_storeAddrIn_0_valid),
    .io_storeAddrIn_0_bits_uop_sqIdx_flag(io_storeAddrIn_0_bits_uop_sqIdx_flag),
    .io_storeAddrIn_0_bits_uop_sqIdx_value(io_storeAddrIn_0_bits_uop_sqIdx_value),
    .io_storeAddrIn_0_bits_miss(io_storeAddrIn_0_bits_miss),
    .io_storeAddrIn_1_valid(io_storeAddrIn_1_valid),
    .io_storeAddrIn_1_bits_uop_sqIdx_flag(io_storeAddrIn_1_bits_uop_sqIdx_flag),
    .io_storeAddrIn_1_bits_uop_sqIdx_value(io_storeAddrIn_1_bits_uop_sqIdx_value),
    .io_storeAddrIn_1_bits_miss(io_storeAddrIn_1_bits_miss),
    .io_storeDataIn_0_valid(io_storeDataIn_0_valid),
    .io_storeDataIn_0_bits_uop_sqIdx_flag(io_storeDataIn_0_bits_uop_sqIdx_flag),
    .io_storeDataIn_0_bits_uop_sqIdx_value(io_storeDataIn_0_bits_uop_sqIdx_value),
    .io_storeDataIn_1_valid(io_storeDataIn_1_valid),
    .io_storeDataIn_1_bits_uop_sqIdx_flag(io_storeDataIn_1_bits_uop_sqIdx_flag),
    .io_storeDataIn_1_bits_uop_sqIdx_value(io_storeDataIn_1_bits_uop_sqIdx_value),
    .io_replay_0_ready(io_replay_0_ready),
    .io_replay_1_ready(io_replay_1_ready),
    .io_replay_2_ready(io_replay_2_ready),
    .io_tl_d_channel_valid(io_tl_d_channel_valid),
    .io_tl_d_channel_mshrid(io_tl_d_channel_mshrid),
    .io_stAddrReadySqPtr_flag(io_stAddrReadySqPtr_flag),
    .io_stAddrReadySqPtr_value(io_stAddrReadySqPtr_value),
    .io_stAddrReadyVec_0(io_stAddrReadyVec_0),
    .io_stAddrReadyVec_1(io_stAddrReadyVec_1),
    .io_stAddrReadyVec_2(io_stAddrReadyVec_2),
    .io_stAddrReadyVec_3(io_stAddrReadyVec_3),
    .io_stAddrReadyVec_4(io_stAddrReadyVec_4),
    .io_stAddrReadyVec_5(io_stAddrReadyVec_5),
    .io_stAddrReadyVec_6(io_stAddrReadyVec_6),
    .io_stAddrReadyVec_7(io_stAddrReadyVec_7),
    .io_stAddrReadyVec_8(io_stAddrReadyVec_8),
    .io_stAddrReadyVec_9(io_stAddrReadyVec_9),
    .io_stAddrReadyVec_10(io_stAddrReadyVec_10),
    .io_stAddrReadyVec_11(io_stAddrReadyVec_11),
    .io_stAddrReadyVec_12(io_stAddrReadyVec_12),
    .io_stAddrReadyVec_13(io_stAddrReadyVec_13),
    .io_stAddrReadyVec_14(io_stAddrReadyVec_14),
    .io_stAddrReadyVec_15(io_stAddrReadyVec_15),
    .io_stAddrReadyVec_16(io_stAddrReadyVec_16),
    .io_stAddrReadyVec_17(io_stAddrReadyVec_17),
    .io_stAddrReadyVec_18(io_stAddrReadyVec_18),
    .io_stAddrReadyVec_19(io_stAddrReadyVec_19),
    .io_stAddrReadyVec_20(io_stAddrReadyVec_20),
    .io_stAddrReadyVec_21(io_stAddrReadyVec_21),
    .io_stAddrReadyVec_22(io_stAddrReadyVec_22),
    .io_stAddrReadyVec_23(io_stAddrReadyVec_23),
    .io_stAddrReadyVec_24(io_stAddrReadyVec_24),
    .io_stAddrReadyVec_25(io_stAddrReadyVec_25),
    .io_stAddrReadyVec_26(io_stAddrReadyVec_26),
    .io_stAddrReadyVec_27(io_stAddrReadyVec_27),
    .io_stAddrReadyVec_28(io_stAddrReadyVec_28),
    .io_stAddrReadyVec_29(io_stAddrReadyVec_29),
    .io_stAddrReadyVec_30(io_stAddrReadyVec_30),
    .io_stAddrReadyVec_31(io_stAddrReadyVec_31),
    .io_stAddrReadyVec_32(io_stAddrReadyVec_32),
    .io_stAddrReadyVec_33(io_stAddrReadyVec_33),
    .io_stAddrReadyVec_34(io_stAddrReadyVec_34),
    .io_stAddrReadyVec_35(io_stAddrReadyVec_35),
    .io_stAddrReadyVec_36(io_stAddrReadyVec_36),
    .io_stAddrReadyVec_37(io_stAddrReadyVec_37),
    .io_stAddrReadyVec_38(io_stAddrReadyVec_38),
    .io_stAddrReadyVec_39(io_stAddrReadyVec_39),
    .io_stAddrReadyVec_40(io_stAddrReadyVec_40),
    .io_stAddrReadyVec_41(io_stAddrReadyVec_41),
    .io_stAddrReadyVec_42(io_stAddrReadyVec_42),
    .io_stAddrReadyVec_43(io_stAddrReadyVec_43),
    .io_stAddrReadyVec_44(io_stAddrReadyVec_44),
    .io_stAddrReadyVec_45(io_stAddrReadyVec_45),
    .io_stAddrReadyVec_46(io_stAddrReadyVec_46),
    .io_stAddrReadyVec_47(io_stAddrReadyVec_47),
    .io_stAddrReadyVec_48(io_stAddrReadyVec_48),
    .io_stAddrReadyVec_49(io_stAddrReadyVec_49),
    .io_stAddrReadyVec_50(io_stAddrReadyVec_50),
    .io_stAddrReadyVec_51(io_stAddrReadyVec_51),
    .io_stAddrReadyVec_52(io_stAddrReadyVec_52),
    .io_stAddrReadyVec_53(io_stAddrReadyVec_53),
    .io_stAddrReadyVec_54(io_stAddrReadyVec_54),
    .io_stAddrReadyVec_55(io_stAddrReadyVec_55),
    .io_stDataReadySqPtr_flag(io_stDataReadySqPtr_flag),
    .io_stDataReadySqPtr_value(io_stDataReadySqPtr_value),
    .io_stDataReadyVec_0(io_stDataReadyVec_0),
    .io_stDataReadyVec_1(io_stDataReadyVec_1),
    .io_stDataReadyVec_2(io_stDataReadyVec_2),
    .io_stDataReadyVec_3(io_stDataReadyVec_3),
    .io_stDataReadyVec_4(io_stDataReadyVec_4),
    .io_stDataReadyVec_5(io_stDataReadyVec_5),
    .io_stDataReadyVec_6(io_stDataReadyVec_6),
    .io_stDataReadyVec_7(io_stDataReadyVec_7),
    .io_stDataReadyVec_8(io_stDataReadyVec_8),
    .io_stDataReadyVec_9(io_stDataReadyVec_9),
    .io_stDataReadyVec_10(io_stDataReadyVec_10),
    .io_stDataReadyVec_11(io_stDataReadyVec_11),
    .io_stDataReadyVec_12(io_stDataReadyVec_12),
    .io_stDataReadyVec_13(io_stDataReadyVec_13),
    .io_stDataReadyVec_14(io_stDataReadyVec_14),
    .io_stDataReadyVec_15(io_stDataReadyVec_15),
    .io_stDataReadyVec_16(io_stDataReadyVec_16),
    .io_stDataReadyVec_17(io_stDataReadyVec_17),
    .io_stDataReadyVec_18(io_stDataReadyVec_18),
    .io_stDataReadyVec_19(io_stDataReadyVec_19),
    .io_stDataReadyVec_20(io_stDataReadyVec_20),
    .io_stDataReadyVec_21(io_stDataReadyVec_21),
    .io_stDataReadyVec_22(io_stDataReadyVec_22),
    .io_stDataReadyVec_23(io_stDataReadyVec_23),
    .io_stDataReadyVec_24(io_stDataReadyVec_24),
    .io_stDataReadyVec_25(io_stDataReadyVec_25),
    .io_stDataReadyVec_26(io_stDataReadyVec_26),
    .io_stDataReadyVec_27(io_stDataReadyVec_27),
    .io_stDataReadyVec_28(io_stDataReadyVec_28),
    .io_stDataReadyVec_29(io_stDataReadyVec_29),
    .io_stDataReadyVec_30(io_stDataReadyVec_30),
    .io_stDataReadyVec_31(io_stDataReadyVec_31),
    .io_stDataReadyVec_32(io_stDataReadyVec_32),
    .io_stDataReadyVec_33(io_stDataReadyVec_33),
    .io_stDataReadyVec_34(io_stDataReadyVec_34),
    .io_stDataReadyVec_35(io_stDataReadyVec_35),
    .io_stDataReadyVec_36(io_stDataReadyVec_36),
    .io_stDataReadyVec_37(io_stDataReadyVec_37),
    .io_stDataReadyVec_38(io_stDataReadyVec_38),
    .io_stDataReadyVec_39(io_stDataReadyVec_39),
    .io_stDataReadyVec_40(io_stDataReadyVec_40),
    .io_stDataReadyVec_41(io_stDataReadyVec_41),
    .io_stDataReadyVec_42(io_stDataReadyVec_42),
    .io_stDataReadyVec_43(io_stDataReadyVec_43),
    .io_stDataReadyVec_44(io_stDataReadyVec_44),
    .io_stDataReadyVec_45(io_stDataReadyVec_45),
    .io_stDataReadyVec_46(io_stDataReadyVec_46),
    .io_stDataReadyVec_47(io_stDataReadyVec_47),
    .io_stDataReadyVec_48(io_stDataReadyVec_48),
    .io_stDataReadyVec_49(io_stDataReadyVec_49),
    .io_stDataReadyVec_50(io_stDataReadyVec_50),
    .io_stDataReadyVec_51(io_stDataReadyVec_51),
    .io_stDataReadyVec_52(io_stDataReadyVec_52),
    .io_stDataReadyVec_53(io_stDataReadyVec_53),
    .io_stDataReadyVec_54(io_stDataReadyVec_54),
    .io_stDataReadyVec_55(io_stDataReadyVec_55),
    .io_sqEmpty(io_sqEmpty),
    .io_ldWbPtr_flag(io_ldWbPtr_flag),
    .io_ldWbPtr_value(io_ldWbPtr_value),
    .io_robDeqPtr_flag(io_robDeqPtr_flag),
    .io_robDeqPtr_value(io_robDeqPtr_value),
    .io_rarFull(io_rarFull),
    .io_rawFull(io_rawFull),
    .io_l2_hint_valid(io_l2_hint_valid),
    .io_l2_hint_bits_sourceId(io_l2_hint_bits_sourceId),
    .io_l2_hint_bits_isKeyword(io_l2_hint_bits_isKeyword),
    .io_tlb_hint_resp_valid(io_tlb_hint_resp_valid),
    .io_tlb_hint_resp_bits_id(io_tlb_hint_resp_bits_id),
    .io_tlb_hint_resp_bits_replay_all(io_tlb_hint_resp_bits_replay_all),
    .io_debugTopDown_robHeadVaddr_valid(io_debugTopDown_robHeadVaddr_valid),
    .io_debugTopDown_robHeadVaddr_bits(io_debugTopDown_robHeadVaddr_bits),
    .io_debugTopDown_robHeadMissInDTlb(io_debugTopDown_robHeadMissInDTlb),
    .io_replay_0_valid(i_io_replay_0_valid),
    .io_replay_0_bits_uop_instr(i_io_replay_0_bits_uop_instr),
    .io_replay_0_bits_uop_pc(i_io_replay_0_bits_uop_pc),
    .io_replay_0_bits_uop_foldpc(i_io_replay_0_bits_uop_foldpc),
    .io_replay_0_bits_uop_exceptionVec_0(i_io_replay_0_bits_uop_exceptionVec_0),
    .io_replay_0_bits_uop_exceptionVec_1(i_io_replay_0_bits_uop_exceptionVec_1),
    .io_replay_0_bits_uop_exceptionVec_2(i_io_replay_0_bits_uop_exceptionVec_2),
    .io_replay_0_bits_uop_exceptionVec_3(i_io_replay_0_bits_uop_exceptionVec_3),
    .io_replay_0_bits_uop_exceptionVec_5(i_io_replay_0_bits_uop_exceptionVec_5),
    .io_replay_0_bits_uop_exceptionVec_6(i_io_replay_0_bits_uop_exceptionVec_6),
    .io_replay_0_bits_uop_exceptionVec_7(i_io_replay_0_bits_uop_exceptionVec_7),
    .io_replay_0_bits_uop_exceptionVec_8(i_io_replay_0_bits_uop_exceptionVec_8),
    .io_replay_0_bits_uop_exceptionVec_9(i_io_replay_0_bits_uop_exceptionVec_9),
    .io_replay_0_bits_uop_exceptionVec_10(i_io_replay_0_bits_uop_exceptionVec_10),
    .io_replay_0_bits_uop_exceptionVec_11(i_io_replay_0_bits_uop_exceptionVec_11),
    .io_replay_0_bits_uop_exceptionVec_12(i_io_replay_0_bits_uop_exceptionVec_12),
    .io_replay_0_bits_uop_exceptionVec_13(i_io_replay_0_bits_uop_exceptionVec_13),
    .io_replay_0_bits_uop_exceptionVec_14(i_io_replay_0_bits_uop_exceptionVec_14),
    .io_replay_0_bits_uop_exceptionVec_15(i_io_replay_0_bits_uop_exceptionVec_15),
    .io_replay_0_bits_uop_exceptionVec_16(i_io_replay_0_bits_uop_exceptionVec_16),
    .io_replay_0_bits_uop_exceptionVec_17(i_io_replay_0_bits_uop_exceptionVec_17),
    .io_replay_0_bits_uop_exceptionVec_18(i_io_replay_0_bits_uop_exceptionVec_18),
    .io_replay_0_bits_uop_exceptionVec_19(i_io_replay_0_bits_uop_exceptionVec_19),
    .io_replay_0_bits_uop_exceptionVec_20(i_io_replay_0_bits_uop_exceptionVec_20),
    .io_replay_0_bits_uop_exceptionVec_21(i_io_replay_0_bits_uop_exceptionVec_21),
    .io_replay_0_bits_uop_exceptionVec_22(i_io_replay_0_bits_uop_exceptionVec_22),
    .io_replay_0_bits_uop_exceptionVec_23(i_io_replay_0_bits_uop_exceptionVec_23),
    .io_replay_0_bits_uop_isFetchMalAddr(i_io_replay_0_bits_uop_isFetchMalAddr),
    .io_replay_0_bits_uop_hasException(i_io_replay_0_bits_uop_hasException),
    .io_replay_0_bits_uop_trigger(i_io_replay_0_bits_uop_trigger),
    .io_replay_0_bits_uop_preDecodeInfo_valid(i_io_replay_0_bits_uop_preDecodeInfo_valid),
    .io_replay_0_bits_uop_preDecodeInfo_isRVC(i_io_replay_0_bits_uop_preDecodeInfo_isRVC),
    .io_replay_0_bits_uop_preDecodeInfo_brType(i_io_replay_0_bits_uop_preDecodeInfo_brType),
    .io_replay_0_bits_uop_preDecodeInfo_isCall(i_io_replay_0_bits_uop_preDecodeInfo_isCall),
    .io_replay_0_bits_uop_preDecodeInfo_isRet(i_io_replay_0_bits_uop_preDecodeInfo_isRet),
    .io_replay_0_bits_uop_pred_taken(i_io_replay_0_bits_uop_pred_taken),
    .io_replay_0_bits_uop_crossPageIPFFix(i_io_replay_0_bits_uop_crossPageIPFFix),
    .io_replay_0_bits_uop_ftqPtr_flag(i_io_replay_0_bits_uop_ftqPtr_flag),
    .io_replay_0_bits_uop_ftqPtr_value(i_io_replay_0_bits_uop_ftqPtr_value),
    .io_replay_0_bits_uop_ftqOffset(i_io_replay_0_bits_uop_ftqOffset),
    .io_replay_0_bits_uop_satpFlushFirstFetchFault(i_io_replay_0_bits_uop_satpFlushFirstFetchFault),
    .io_replay_0_bits_uop_srcType_0(i_io_replay_0_bits_uop_srcType_0),
    .io_replay_0_bits_uop_srcType_1(i_io_replay_0_bits_uop_srcType_1),
    .io_replay_0_bits_uop_srcType_2(i_io_replay_0_bits_uop_srcType_2),
    .io_replay_0_bits_uop_srcType_3(i_io_replay_0_bits_uop_srcType_3),
    .io_replay_0_bits_uop_srcType_4(i_io_replay_0_bits_uop_srcType_4),
    .io_replay_0_bits_uop_ldest(i_io_replay_0_bits_uop_ldest),
    .io_replay_0_bits_uop_fuType(i_io_replay_0_bits_uop_fuType),
    .io_replay_0_bits_uop_fuOpType(i_io_replay_0_bits_uop_fuOpType),
    .io_replay_0_bits_uop_rfWen(i_io_replay_0_bits_uop_rfWen),
    .io_replay_0_bits_uop_fpWen(i_io_replay_0_bits_uop_fpWen),
    .io_replay_0_bits_uop_vecWen(i_io_replay_0_bits_uop_vecWen),
    .io_replay_0_bits_uop_v0Wen(i_io_replay_0_bits_uop_v0Wen),
    .io_replay_0_bits_uop_vlWen(i_io_replay_0_bits_uop_vlWen),
    .io_replay_0_bits_uop_isXSTrap(i_io_replay_0_bits_uop_isXSTrap),
    .io_replay_0_bits_uop_waitForward(i_io_replay_0_bits_uop_waitForward),
    .io_replay_0_bits_uop_blockBackward(i_io_replay_0_bits_uop_blockBackward),
    .io_replay_0_bits_uop_canRobCompress(i_io_replay_0_bits_uop_canRobCompress),
    .io_replay_0_bits_uop_selImm(i_io_replay_0_bits_uop_selImm),
    .io_replay_0_bits_uop_imm(i_io_replay_0_bits_uop_imm),
    .io_replay_0_bits_uop_fpu_typeTagOut(i_io_replay_0_bits_uop_fpu_typeTagOut),
    .io_replay_0_bits_uop_fpu_wflags(i_io_replay_0_bits_uop_fpu_wflags),
    .io_replay_0_bits_uop_fpu_typ(i_io_replay_0_bits_uop_fpu_typ),
    .io_replay_0_bits_uop_fpu_fmt(i_io_replay_0_bits_uop_fpu_fmt),
    .io_replay_0_bits_uop_fpu_rm(i_io_replay_0_bits_uop_fpu_rm),
    .io_replay_0_bits_uop_vpu_vill(i_io_replay_0_bits_uop_vpu_vill),
    .io_replay_0_bits_uop_vpu_vma(i_io_replay_0_bits_uop_vpu_vma),
    .io_replay_0_bits_uop_vpu_vta(i_io_replay_0_bits_uop_vpu_vta),
    .io_replay_0_bits_uop_vpu_vsew(i_io_replay_0_bits_uop_vpu_vsew),
    .io_replay_0_bits_uop_vpu_vlmul(i_io_replay_0_bits_uop_vpu_vlmul),
    .io_replay_0_bits_uop_vpu_specVill(i_io_replay_0_bits_uop_vpu_specVill),
    .io_replay_0_bits_uop_vpu_specVma(i_io_replay_0_bits_uop_vpu_specVma),
    .io_replay_0_bits_uop_vpu_specVta(i_io_replay_0_bits_uop_vpu_specVta),
    .io_replay_0_bits_uop_vpu_specVsew(i_io_replay_0_bits_uop_vpu_specVsew),
    .io_replay_0_bits_uop_vpu_specVlmul(i_io_replay_0_bits_uop_vpu_specVlmul),
    .io_replay_0_bits_uop_vpu_vm(i_io_replay_0_bits_uop_vpu_vm),
    .io_replay_0_bits_uop_vpu_vstart(i_io_replay_0_bits_uop_vpu_vstart),
    .io_replay_0_bits_uop_vpu_frm(i_io_replay_0_bits_uop_vpu_frm),
    .io_replay_0_bits_uop_vpu_fpu_isFpToVecInst(i_io_replay_0_bits_uop_vpu_fpu_isFpToVecInst),
    .io_replay_0_bits_uop_vpu_fpu_isFP32Instr(i_io_replay_0_bits_uop_vpu_fpu_isFP32Instr),
    .io_replay_0_bits_uop_vpu_fpu_isFP64Instr(i_io_replay_0_bits_uop_vpu_fpu_isFP64Instr),
    .io_replay_0_bits_uop_vpu_fpu_isReduction(i_io_replay_0_bits_uop_vpu_fpu_isReduction),
    .io_replay_0_bits_uop_vpu_fpu_isFoldTo1_2(i_io_replay_0_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_replay_0_bits_uop_vpu_fpu_isFoldTo1_4(i_io_replay_0_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_replay_0_bits_uop_vpu_fpu_isFoldTo1_8(i_io_replay_0_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_replay_0_bits_uop_vpu_vxrm(i_io_replay_0_bits_uop_vpu_vxrm),
    .io_replay_0_bits_uop_vpu_vuopIdx(i_io_replay_0_bits_uop_vpu_vuopIdx),
    .io_replay_0_bits_uop_vpu_lastUop(i_io_replay_0_bits_uop_vpu_lastUop),
    .io_replay_0_bits_uop_vpu_vmask(i_io_replay_0_bits_uop_vpu_vmask),
    .io_replay_0_bits_uop_vpu_vl(i_io_replay_0_bits_uop_vpu_vl),
    .io_replay_0_bits_uop_vpu_nf(i_io_replay_0_bits_uop_vpu_nf),
    .io_replay_0_bits_uop_vpu_veew(i_io_replay_0_bits_uop_vpu_veew),
    .io_replay_0_bits_uop_vpu_isReverse(i_io_replay_0_bits_uop_vpu_isReverse),
    .io_replay_0_bits_uop_vpu_isExt(i_io_replay_0_bits_uop_vpu_isExt),
    .io_replay_0_bits_uop_vpu_isNarrow(i_io_replay_0_bits_uop_vpu_isNarrow),
    .io_replay_0_bits_uop_vpu_isDstMask(i_io_replay_0_bits_uop_vpu_isDstMask),
    .io_replay_0_bits_uop_vpu_isOpMask(i_io_replay_0_bits_uop_vpu_isOpMask),
    .io_replay_0_bits_uop_vpu_isMove(i_io_replay_0_bits_uop_vpu_isMove),
    .io_replay_0_bits_uop_vpu_isDependOldVd(i_io_replay_0_bits_uop_vpu_isDependOldVd),
    .io_replay_0_bits_uop_vpu_isWritePartVd(i_io_replay_0_bits_uop_vpu_isWritePartVd),
    .io_replay_0_bits_uop_vpu_isVleff(i_io_replay_0_bits_uop_vpu_isVleff),
    .io_replay_0_bits_uop_vlsInstr(i_io_replay_0_bits_uop_vlsInstr),
    .io_replay_0_bits_uop_wfflags(i_io_replay_0_bits_uop_wfflags),
    .io_replay_0_bits_uop_isMove(i_io_replay_0_bits_uop_isMove),
    .io_replay_0_bits_uop_isDropAmocasSta(i_io_replay_0_bits_uop_isDropAmocasSta),
    .io_replay_0_bits_uop_uopIdx(i_io_replay_0_bits_uop_uopIdx),
    .io_replay_0_bits_uop_isVset(i_io_replay_0_bits_uop_isVset),
    .io_replay_0_bits_uop_firstUop(i_io_replay_0_bits_uop_firstUop),
    .io_replay_0_bits_uop_lastUop(i_io_replay_0_bits_uop_lastUop),
    .io_replay_0_bits_uop_numUops(i_io_replay_0_bits_uop_numUops),
    .io_replay_0_bits_uop_numWB(i_io_replay_0_bits_uop_numWB),
    .io_replay_0_bits_uop_commitType(i_io_replay_0_bits_uop_commitType),
    .io_replay_0_bits_uop_srcState_0(i_io_replay_0_bits_uop_srcState_0),
    .io_replay_0_bits_uop_srcState_1(i_io_replay_0_bits_uop_srcState_1),
    .io_replay_0_bits_uop_srcState_2(i_io_replay_0_bits_uop_srcState_2),
    .io_replay_0_bits_uop_srcState_3(i_io_replay_0_bits_uop_srcState_3),
    .io_replay_0_bits_uop_srcState_4(i_io_replay_0_bits_uop_srcState_4),
    .io_replay_0_bits_uop_srcLoadDependency_0_0(i_io_replay_0_bits_uop_srcLoadDependency_0_0),
    .io_replay_0_bits_uop_srcLoadDependency_0_1(i_io_replay_0_bits_uop_srcLoadDependency_0_1),
    .io_replay_0_bits_uop_srcLoadDependency_0_2(i_io_replay_0_bits_uop_srcLoadDependency_0_2),
    .io_replay_0_bits_uop_srcLoadDependency_1_0(i_io_replay_0_bits_uop_srcLoadDependency_1_0),
    .io_replay_0_bits_uop_srcLoadDependency_1_1(i_io_replay_0_bits_uop_srcLoadDependency_1_1),
    .io_replay_0_bits_uop_srcLoadDependency_1_2(i_io_replay_0_bits_uop_srcLoadDependency_1_2),
    .io_replay_0_bits_uop_srcLoadDependency_2_0(i_io_replay_0_bits_uop_srcLoadDependency_2_0),
    .io_replay_0_bits_uop_srcLoadDependency_2_1(i_io_replay_0_bits_uop_srcLoadDependency_2_1),
    .io_replay_0_bits_uop_srcLoadDependency_2_2(i_io_replay_0_bits_uop_srcLoadDependency_2_2),
    .io_replay_0_bits_uop_srcLoadDependency_3_0(i_io_replay_0_bits_uop_srcLoadDependency_3_0),
    .io_replay_0_bits_uop_srcLoadDependency_3_1(i_io_replay_0_bits_uop_srcLoadDependency_3_1),
    .io_replay_0_bits_uop_srcLoadDependency_3_2(i_io_replay_0_bits_uop_srcLoadDependency_3_2),
    .io_replay_0_bits_uop_srcLoadDependency_4_0(i_io_replay_0_bits_uop_srcLoadDependency_4_0),
    .io_replay_0_bits_uop_srcLoadDependency_4_1(i_io_replay_0_bits_uop_srcLoadDependency_4_1),
    .io_replay_0_bits_uop_srcLoadDependency_4_2(i_io_replay_0_bits_uop_srcLoadDependency_4_2),
    .io_replay_0_bits_uop_psrc_0(i_io_replay_0_bits_uop_psrc_0),
    .io_replay_0_bits_uop_psrc_1(i_io_replay_0_bits_uop_psrc_1),
    .io_replay_0_bits_uop_psrc_2(i_io_replay_0_bits_uop_psrc_2),
    .io_replay_0_bits_uop_psrc_3(i_io_replay_0_bits_uop_psrc_3),
    .io_replay_0_bits_uop_psrc_4(i_io_replay_0_bits_uop_psrc_4),
    .io_replay_0_bits_uop_pdest(i_io_replay_0_bits_uop_pdest),
    .io_replay_0_bits_uop_useRegCache_0(i_io_replay_0_bits_uop_useRegCache_0),
    .io_replay_0_bits_uop_useRegCache_1(i_io_replay_0_bits_uop_useRegCache_1),
    .io_replay_0_bits_uop_regCacheIdx_0(i_io_replay_0_bits_uop_regCacheIdx_0),
    .io_replay_0_bits_uop_regCacheIdx_1(i_io_replay_0_bits_uop_regCacheIdx_1),
    .io_replay_0_bits_uop_robIdx_flag(i_io_replay_0_bits_uop_robIdx_flag),
    .io_replay_0_bits_uop_robIdx_value(i_io_replay_0_bits_uop_robIdx_value),
    .io_replay_0_bits_uop_instrSize(i_io_replay_0_bits_uop_instrSize),
    .io_replay_0_bits_uop_dirtyFs(i_io_replay_0_bits_uop_dirtyFs),
    .io_replay_0_bits_uop_dirtyVs(i_io_replay_0_bits_uop_dirtyVs),
    .io_replay_0_bits_uop_traceBlockInPipe_itype(i_io_replay_0_bits_uop_traceBlockInPipe_itype),
    .io_replay_0_bits_uop_traceBlockInPipe_iretire(i_io_replay_0_bits_uop_traceBlockInPipe_iretire),
    .io_replay_0_bits_uop_traceBlockInPipe_ilastsize(i_io_replay_0_bits_uop_traceBlockInPipe_ilastsize),
    .io_replay_0_bits_uop_eliminatedMove(i_io_replay_0_bits_uop_eliminatedMove),
    .io_replay_0_bits_uop_snapshot(i_io_replay_0_bits_uop_snapshot),
    .io_replay_0_bits_uop_debugInfo_eliminatedMove(i_io_replay_0_bits_uop_debugInfo_eliminatedMove),
    .io_replay_0_bits_uop_debugInfo_renameTime(i_io_replay_0_bits_uop_debugInfo_renameTime),
    .io_replay_0_bits_uop_debugInfo_dispatchTime(i_io_replay_0_bits_uop_debugInfo_dispatchTime),
    .io_replay_0_bits_uop_debugInfo_enqRsTime(i_io_replay_0_bits_uop_debugInfo_enqRsTime),
    .io_replay_0_bits_uop_debugInfo_selectTime(i_io_replay_0_bits_uop_debugInfo_selectTime),
    .io_replay_0_bits_uop_debugInfo_issueTime(i_io_replay_0_bits_uop_debugInfo_issueTime),
    .io_replay_0_bits_uop_debugInfo_writebackTime(i_io_replay_0_bits_uop_debugInfo_writebackTime),
    .io_replay_0_bits_uop_debugInfo_runahead_checkpoint_id(i_io_replay_0_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_replay_0_bits_uop_debugInfo_tlbFirstReqTime(i_io_replay_0_bits_uop_debugInfo_tlbFirstReqTime),
    .io_replay_0_bits_uop_debugInfo_tlbRespTime(i_io_replay_0_bits_uop_debugInfo_tlbRespTime),
    .io_replay_0_bits_uop_debug_seqNum_seqNum(i_io_replay_0_bits_uop_debug_seqNum_seqNum),
    .io_replay_0_bits_uop_debug_seqNum_uopIdx(i_io_replay_0_bits_uop_debug_seqNum_uopIdx),
    .io_replay_0_bits_uop_storeSetHit(i_io_replay_0_bits_uop_storeSetHit),
    .io_replay_0_bits_uop_waitForRobIdx_flag(i_io_replay_0_bits_uop_waitForRobIdx_flag),
    .io_replay_0_bits_uop_waitForRobIdx_value(i_io_replay_0_bits_uop_waitForRobIdx_value),
    .io_replay_0_bits_uop_loadWaitBit(i_io_replay_0_bits_uop_loadWaitBit),
    .io_replay_0_bits_uop_ssid(i_io_replay_0_bits_uop_ssid),
    .io_replay_0_bits_uop_lqIdx_flag(i_io_replay_0_bits_uop_lqIdx_flag),
    .io_replay_0_bits_uop_lqIdx_value(i_io_replay_0_bits_uop_lqIdx_value),
    .io_replay_0_bits_uop_sqIdx_flag(i_io_replay_0_bits_uop_sqIdx_flag),
    .io_replay_0_bits_uop_sqIdx_value(i_io_replay_0_bits_uop_sqIdx_value),
    .io_replay_0_bits_uop_singleStep(i_io_replay_0_bits_uop_singleStep),
    .io_replay_0_bits_uop_debug_fuType(i_io_replay_0_bits_uop_debug_fuType),
    .io_replay_0_bits_uop_debug_sim_trig(i_io_replay_0_bits_uop_debug_sim_trig),
    .io_replay_0_bits_uop_numLsElem(i_io_replay_0_bits_uop_numLsElem),
    .io_replay_0_bits_vaddr(i_io_replay_0_bits_vaddr),
    .io_replay_0_bits_mask(i_io_replay_0_bits_mask),
    .io_replay_0_bits_isvec(i_io_replay_0_bits_isvec),
    .io_replay_0_bits_is128bit(i_io_replay_0_bits_is128bit),
    .io_replay_0_bits_elemIdx(i_io_replay_0_bits_elemIdx),
    .io_replay_0_bits_alignedType(i_io_replay_0_bits_alignedType),
    .io_replay_0_bits_mbIndex(i_io_replay_0_bits_mbIndex),
    .io_replay_0_bits_reg_offset(i_io_replay_0_bits_reg_offset),
    .io_replay_0_bits_elemIdxInsideVd(i_io_replay_0_bits_elemIdxInsideVd),
    .io_replay_0_bits_vecActive(i_io_replay_0_bits_vecActive),
    .io_replay_0_bits_mshrid(i_io_replay_0_bits_mshrid),
    .io_replay_0_bits_forward_tlDchannel(i_io_replay_0_bits_forward_tlDchannel),
    .io_replay_0_bits_schedIndex(i_io_replay_0_bits_schedIndex),
    .io_replay_1_valid(i_io_replay_1_valid),
    .io_replay_1_bits_uop_instr(i_io_replay_1_bits_uop_instr),
    .io_replay_1_bits_uop_pc(i_io_replay_1_bits_uop_pc),
    .io_replay_1_bits_uop_foldpc(i_io_replay_1_bits_uop_foldpc),
    .io_replay_1_bits_uop_exceptionVec_0(i_io_replay_1_bits_uop_exceptionVec_0),
    .io_replay_1_bits_uop_exceptionVec_1(i_io_replay_1_bits_uop_exceptionVec_1),
    .io_replay_1_bits_uop_exceptionVec_2(i_io_replay_1_bits_uop_exceptionVec_2),
    .io_replay_1_bits_uop_exceptionVec_3(i_io_replay_1_bits_uop_exceptionVec_3),
    .io_replay_1_bits_uop_exceptionVec_5(i_io_replay_1_bits_uop_exceptionVec_5),
    .io_replay_1_bits_uop_exceptionVec_6(i_io_replay_1_bits_uop_exceptionVec_6),
    .io_replay_1_bits_uop_exceptionVec_7(i_io_replay_1_bits_uop_exceptionVec_7),
    .io_replay_1_bits_uop_exceptionVec_8(i_io_replay_1_bits_uop_exceptionVec_8),
    .io_replay_1_bits_uop_exceptionVec_9(i_io_replay_1_bits_uop_exceptionVec_9),
    .io_replay_1_bits_uop_exceptionVec_10(i_io_replay_1_bits_uop_exceptionVec_10),
    .io_replay_1_bits_uop_exceptionVec_11(i_io_replay_1_bits_uop_exceptionVec_11),
    .io_replay_1_bits_uop_exceptionVec_12(i_io_replay_1_bits_uop_exceptionVec_12),
    .io_replay_1_bits_uop_exceptionVec_13(i_io_replay_1_bits_uop_exceptionVec_13),
    .io_replay_1_bits_uop_exceptionVec_14(i_io_replay_1_bits_uop_exceptionVec_14),
    .io_replay_1_bits_uop_exceptionVec_15(i_io_replay_1_bits_uop_exceptionVec_15),
    .io_replay_1_bits_uop_exceptionVec_16(i_io_replay_1_bits_uop_exceptionVec_16),
    .io_replay_1_bits_uop_exceptionVec_17(i_io_replay_1_bits_uop_exceptionVec_17),
    .io_replay_1_bits_uop_exceptionVec_18(i_io_replay_1_bits_uop_exceptionVec_18),
    .io_replay_1_bits_uop_exceptionVec_19(i_io_replay_1_bits_uop_exceptionVec_19),
    .io_replay_1_bits_uop_exceptionVec_20(i_io_replay_1_bits_uop_exceptionVec_20),
    .io_replay_1_bits_uop_exceptionVec_21(i_io_replay_1_bits_uop_exceptionVec_21),
    .io_replay_1_bits_uop_exceptionVec_22(i_io_replay_1_bits_uop_exceptionVec_22),
    .io_replay_1_bits_uop_exceptionVec_23(i_io_replay_1_bits_uop_exceptionVec_23),
    .io_replay_1_bits_uop_isFetchMalAddr(i_io_replay_1_bits_uop_isFetchMalAddr),
    .io_replay_1_bits_uop_hasException(i_io_replay_1_bits_uop_hasException),
    .io_replay_1_bits_uop_trigger(i_io_replay_1_bits_uop_trigger),
    .io_replay_1_bits_uop_preDecodeInfo_valid(i_io_replay_1_bits_uop_preDecodeInfo_valid),
    .io_replay_1_bits_uop_preDecodeInfo_isRVC(i_io_replay_1_bits_uop_preDecodeInfo_isRVC),
    .io_replay_1_bits_uop_preDecodeInfo_brType(i_io_replay_1_bits_uop_preDecodeInfo_brType),
    .io_replay_1_bits_uop_preDecodeInfo_isCall(i_io_replay_1_bits_uop_preDecodeInfo_isCall),
    .io_replay_1_bits_uop_preDecodeInfo_isRet(i_io_replay_1_bits_uop_preDecodeInfo_isRet),
    .io_replay_1_bits_uop_pred_taken(i_io_replay_1_bits_uop_pred_taken),
    .io_replay_1_bits_uop_crossPageIPFFix(i_io_replay_1_bits_uop_crossPageIPFFix),
    .io_replay_1_bits_uop_ftqPtr_flag(i_io_replay_1_bits_uop_ftqPtr_flag),
    .io_replay_1_bits_uop_ftqPtr_value(i_io_replay_1_bits_uop_ftqPtr_value),
    .io_replay_1_bits_uop_ftqOffset(i_io_replay_1_bits_uop_ftqOffset),
    .io_replay_1_bits_uop_satpFlushFirstFetchFault(i_io_replay_1_bits_uop_satpFlushFirstFetchFault),
    .io_replay_1_bits_uop_srcType_0(i_io_replay_1_bits_uop_srcType_0),
    .io_replay_1_bits_uop_srcType_1(i_io_replay_1_bits_uop_srcType_1),
    .io_replay_1_bits_uop_srcType_2(i_io_replay_1_bits_uop_srcType_2),
    .io_replay_1_bits_uop_srcType_3(i_io_replay_1_bits_uop_srcType_3),
    .io_replay_1_bits_uop_srcType_4(i_io_replay_1_bits_uop_srcType_4),
    .io_replay_1_bits_uop_ldest(i_io_replay_1_bits_uop_ldest),
    .io_replay_1_bits_uop_fuType(i_io_replay_1_bits_uop_fuType),
    .io_replay_1_bits_uop_fuOpType(i_io_replay_1_bits_uop_fuOpType),
    .io_replay_1_bits_uop_rfWen(i_io_replay_1_bits_uop_rfWen),
    .io_replay_1_bits_uop_fpWen(i_io_replay_1_bits_uop_fpWen),
    .io_replay_1_bits_uop_vecWen(i_io_replay_1_bits_uop_vecWen),
    .io_replay_1_bits_uop_v0Wen(i_io_replay_1_bits_uop_v0Wen),
    .io_replay_1_bits_uop_vlWen(i_io_replay_1_bits_uop_vlWen),
    .io_replay_1_bits_uop_isXSTrap(i_io_replay_1_bits_uop_isXSTrap),
    .io_replay_1_bits_uop_waitForward(i_io_replay_1_bits_uop_waitForward),
    .io_replay_1_bits_uop_blockBackward(i_io_replay_1_bits_uop_blockBackward),
    .io_replay_1_bits_uop_canRobCompress(i_io_replay_1_bits_uop_canRobCompress),
    .io_replay_1_bits_uop_selImm(i_io_replay_1_bits_uop_selImm),
    .io_replay_1_bits_uop_imm(i_io_replay_1_bits_uop_imm),
    .io_replay_1_bits_uop_fpu_typeTagOut(i_io_replay_1_bits_uop_fpu_typeTagOut),
    .io_replay_1_bits_uop_fpu_wflags(i_io_replay_1_bits_uop_fpu_wflags),
    .io_replay_1_bits_uop_fpu_typ(i_io_replay_1_bits_uop_fpu_typ),
    .io_replay_1_bits_uop_fpu_fmt(i_io_replay_1_bits_uop_fpu_fmt),
    .io_replay_1_bits_uop_fpu_rm(i_io_replay_1_bits_uop_fpu_rm),
    .io_replay_1_bits_uop_vpu_vill(i_io_replay_1_bits_uop_vpu_vill),
    .io_replay_1_bits_uop_vpu_vma(i_io_replay_1_bits_uop_vpu_vma),
    .io_replay_1_bits_uop_vpu_vta(i_io_replay_1_bits_uop_vpu_vta),
    .io_replay_1_bits_uop_vpu_vsew(i_io_replay_1_bits_uop_vpu_vsew),
    .io_replay_1_bits_uop_vpu_vlmul(i_io_replay_1_bits_uop_vpu_vlmul),
    .io_replay_1_bits_uop_vpu_specVill(i_io_replay_1_bits_uop_vpu_specVill),
    .io_replay_1_bits_uop_vpu_specVma(i_io_replay_1_bits_uop_vpu_specVma),
    .io_replay_1_bits_uop_vpu_specVta(i_io_replay_1_bits_uop_vpu_specVta),
    .io_replay_1_bits_uop_vpu_specVsew(i_io_replay_1_bits_uop_vpu_specVsew),
    .io_replay_1_bits_uop_vpu_specVlmul(i_io_replay_1_bits_uop_vpu_specVlmul),
    .io_replay_1_bits_uop_vpu_vm(i_io_replay_1_bits_uop_vpu_vm),
    .io_replay_1_bits_uop_vpu_vstart(i_io_replay_1_bits_uop_vpu_vstart),
    .io_replay_1_bits_uop_vpu_frm(i_io_replay_1_bits_uop_vpu_frm),
    .io_replay_1_bits_uop_vpu_fpu_isFpToVecInst(i_io_replay_1_bits_uop_vpu_fpu_isFpToVecInst),
    .io_replay_1_bits_uop_vpu_fpu_isFP32Instr(i_io_replay_1_bits_uop_vpu_fpu_isFP32Instr),
    .io_replay_1_bits_uop_vpu_fpu_isFP64Instr(i_io_replay_1_bits_uop_vpu_fpu_isFP64Instr),
    .io_replay_1_bits_uop_vpu_fpu_isReduction(i_io_replay_1_bits_uop_vpu_fpu_isReduction),
    .io_replay_1_bits_uop_vpu_fpu_isFoldTo1_2(i_io_replay_1_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_replay_1_bits_uop_vpu_fpu_isFoldTo1_4(i_io_replay_1_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_replay_1_bits_uop_vpu_fpu_isFoldTo1_8(i_io_replay_1_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_replay_1_bits_uop_vpu_vxrm(i_io_replay_1_bits_uop_vpu_vxrm),
    .io_replay_1_bits_uop_vpu_vuopIdx(i_io_replay_1_bits_uop_vpu_vuopIdx),
    .io_replay_1_bits_uop_vpu_lastUop(i_io_replay_1_bits_uop_vpu_lastUop),
    .io_replay_1_bits_uop_vpu_vmask(i_io_replay_1_bits_uop_vpu_vmask),
    .io_replay_1_bits_uop_vpu_vl(i_io_replay_1_bits_uop_vpu_vl),
    .io_replay_1_bits_uop_vpu_nf(i_io_replay_1_bits_uop_vpu_nf),
    .io_replay_1_bits_uop_vpu_veew(i_io_replay_1_bits_uop_vpu_veew),
    .io_replay_1_bits_uop_vpu_isReverse(i_io_replay_1_bits_uop_vpu_isReverse),
    .io_replay_1_bits_uop_vpu_isExt(i_io_replay_1_bits_uop_vpu_isExt),
    .io_replay_1_bits_uop_vpu_isNarrow(i_io_replay_1_bits_uop_vpu_isNarrow),
    .io_replay_1_bits_uop_vpu_isDstMask(i_io_replay_1_bits_uop_vpu_isDstMask),
    .io_replay_1_bits_uop_vpu_isOpMask(i_io_replay_1_bits_uop_vpu_isOpMask),
    .io_replay_1_bits_uop_vpu_isMove(i_io_replay_1_bits_uop_vpu_isMove),
    .io_replay_1_bits_uop_vpu_isDependOldVd(i_io_replay_1_bits_uop_vpu_isDependOldVd),
    .io_replay_1_bits_uop_vpu_isWritePartVd(i_io_replay_1_bits_uop_vpu_isWritePartVd),
    .io_replay_1_bits_uop_vpu_isVleff(i_io_replay_1_bits_uop_vpu_isVleff),
    .io_replay_1_bits_uop_vlsInstr(i_io_replay_1_bits_uop_vlsInstr),
    .io_replay_1_bits_uop_wfflags(i_io_replay_1_bits_uop_wfflags),
    .io_replay_1_bits_uop_isMove(i_io_replay_1_bits_uop_isMove),
    .io_replay_1_bits_uop_isDropAmocasSta(i_io_replay_1_bits_uop_isDropAmocasSta),
    .io_replay_1_bits_uop_uopIdx(i_io_replay_1_bits_uop_uopIdx),
    .io_replay_1_bits_uop_isVset(i_io_replay_1_bits_uop_isVset),
    .io_replay_1_bits_uop_firstUop(i_io_replay_1_bits_uop_firstUop),
    .io_replay_1_bits_uop_lastUop(i_io_replay_1_bits_uop_lastUop),
    .io_replay_1_bits_uop_numUops(i_io_replay_1_bits_uop_numUops),
    .io_replay_1_bits_uop_numWB(i_io_replay_1_bits_uop_numWB),
    .io_replay_1_bits_uop_commitType(i_io_replay_1_bits_uop_commitType),
    .io_replay_1_bits_uop_srcState_0(i_io_replay_1_bits_uop_srcState_0),
    .io_replay_1_bits_uop_srcState_1(i_io_replay_1_bits_uop_srcState_1),
    .io_replay_1_bits_uop_srcState_2(i_io_replay_1_bits_uop_srcState_2),
    .io_replay_1_bits_uop_srcState_3(i_io_replay_1_bits_uop_srcState_3),
    .io_replay_1_bits_uop_srcState_4(i_io_replay_1_bits_uop_srcState_4),
    .io_replay_1_bits_uop_srcLoadDependency_0_0(i_io_replay_1_bits_uop_srcLoadDependency_0_0),
    .io_replay_1_bits_uop_srcLoadDependency_0_1(i_io_replay_1_bits_uop_srcLoadDependency_0_1),
    .io_replay_1_bits_uop_srcLoadDependency_0_2(i_io_replay_1_bits_uop_srcLoadDependency_0_2),
    .io_replay_1_bits_uop_srcLoadDependency_1_0(i_io_replay_1_bits_uop_srcLoadDependency_1_0),
    .io_replay_1_bits_uop_srcLoadDependency_1_1(i_io_replay_1_bits_uop_srcLoadDependency_1_1),
    .io_replay_1_bits_uop_srcLoadDependency_1_2(i_io_replay_1_bits_uop_srcLoadDependency_1_2),
    .io_replay_1_bits_uop_srcLoadDependency_2_0(i_io_replay_1_bits_uop_srcLoadDependency_2_0),
    .io_replay_1_bits_uop_srcLoadDependency_2_1(i_io_replay_1_bits_uop_srcLoadDependency_2_1),
    .io_replay_1_bits_uop_srcLoadDependency_2_2(i_io_replay_1_bits_uop_srcLoadDependency_2_2),
    .io_replay_1_bits_uop_srcLoadDependency_3_0(i_io_replay_1_bits_uop_srcLoadDependency_3_0),
    .io_replay_1_bits_uop_srcLoadDependency_3_1(i_io_replay_1_bits_uop_srcLoadDependency_3_1),
    .io_replay_1_bits_uop_srcLoadDependency_3_2(i_io_replay_1_bits_uop_srcLoadDependency_3_2),
    .io_replay_1_bits_uop_srcLoadDependency_4_0(i_io_replay_1_bits_uop_srcLoadDependency_4_0),
    .io_replay_1_bits_uop_srcLoadDependency_4_1(i_io_replay_1_bits_uop_srcLoadDependency_4_1),
    .io_replay_1_bits_uop_srcLoadDependency_4_2(i_io_replay_1_bits_uop_srcLoadDependency_4_2),
    .io_replay_1_bits_uop_psrc_0(i_io_replay_1_bits_uop_psrc_0),
    .io_replay_1_bits_uop_psrc_1(i_io_replay_1_bits_uop_psrc_1),
    .io_replay_1_bits_uop_psrc_2(i_io_replay_1_bits_uop_psrc_2),
    .io_replay_1_bits_uop_psrc_3(i_io_replay_1_bits_uop_psrc_3),
    .io_replay_1_bits_uop_psrc_4(i_io_replay_1_bits_uop_psrc_4),
    .io_replay_1_bits_uop_pdest(i_io_replay_1_bits_uop_pdest),
    .io_replay_1_bits_uop_useRegCache_0(i_io_replay_1_bits_uop_useRegCache_0),
    .io_replay_1_bits_uop_useRegCache_1(i_io_replay_1_bits_uop_useRegCache_1),
    .io_replay_1_bits_uop_regCacheIdx_0(i_io_replay_1_bits_uop_regCacheIdx_0),
    .io_replay_1_bits_uop_regCacheIdx_1(i_io_replay_1_bits_uop_regCacheIdx_1),
    .io_replay_1_bits_uop_robIdx_flag(i_io_replay_1_bits_uop_robIdx_flag),
    .io_replay_1_bits_uop_robIdx_value(i_io_replay_1_bits_uop_robIdx_value),
    .io_replay_1_bits_uop_instrSize(i_io_replay_1_bits_uop_instrSize),
    .io_replay_1_bits_uop_dirtyFs(i_io_replay_1_bits_uop_dirtyFs),
    .io_replay_1_bits_uop_dirtyVs(i_io_replay_1_bits_uop_dirtyVs),
    .io_replay_1_bits_uop_traceBlockInPipe_itype(i_io_replay_1_bits_uop_traceBlockInPipe_itype),
    .io_replay_1_bits_uop_traceBlockInPipe_iretire(i_io_replay_1_bits_uop_traceBlockInPipe_iretire),
    .io_replay_1_bits_uop_traceBlockInPipe_ilastsize(i_io_replay_1_bits_uop_traceBlockInPipe_ilastsize),
    .io_replay_1_bits_uop_eliminatedMove(i_io_replay_1_bits_uop_eliminatedMove),
    .io_replay_1_bits_uop_snapshot(i_io_replay_1_bits_uop_snapshot),
    .io_replay_1_bits_uop_debugInfo_eliminatedMove(i_io_replay_1_bits_uop_debugInfo_eliminatedMove),
    .io_replay_1_bits_uop_debugInfo_renameTime(i_io_replay_1_bits_uop_debugInfo_renameTime),
    .io_replay_1_bits_uop_debugInfo_dispatchTime(i_io_replay_1_bits_uop_debugInfo_dispatchTime),
    .io_replay_1_bits_uop_debugInfo_enqRsTime(i_io_replay_1_bits_uop_debugInfo_enqRsTime),
    .io_replay_1_bits_uop_debugInfo_selectTime(i_io_replay_1_bits_uop_debugInfo_selectTime),
    .io_replay_1_bits_uop_debugInfo_issueTime(i_io_replay_1_bits_uop_debugInfo_issueTime),
    .io_replay_1_bits_uop_debugInfo_writebackTime(i_io_replay_1_bits_uop_debugInfo_writebackTime),
    .io_replay_1_bits_uop_debugInfo_runahead_checkpoint_id(i_io_replay_1_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_replay_1_bits_uop_debugInfo_tlbFirstReqTime(i_io_replay_1_bits_uop_debugInfo_tlbFirstReqTime),
    .io_replay_1_bits_uop_debugInfo_tlbRespTime(i_io_replay_1_bits_uop_debugInfo_tlbRespTime),
    .io_replay_1_bits_uop_debug_seqNum_seqNum(i_io_replay_1_bits_uop_debug_seqNum_seqNum),
    .io_replay_1_bits_uop_debug_seqNum_uopIdx(i_io_replay_1_bits_uop_debug_seqNum_uopIdx),
    .io_replay_1_bits_uop_storeSetHit(i_io_replay_1_bits_uop_storeSetHit),
    .io_replay_1_bits_uop_waitForRobIdx_flag(i_io_replay_1_bits_uop_waitForRobIdx_flag),
    .io_replay_1_bits_uop_waitForRobIdx_value(i_io_replay_1_bits_uop_waitForRobIdx_value),
    .io_replay_1_bits_uop_loadWaitBit(i_io_replay_1_bits_uop_loadWaitBit),
    .io_replay_1_bits_uop_ssid(i_io_replay_1_bits_uop_ssid),
    .io_replay_1_bits_uop_lqIdx_flag(i_io_replay_1_bits_uop_lqIdx_flag),
    .io_replay_1_bits_uop_lqIdx_value(i_io_replay_1_bits_uop_lqIdx_value),
    .io_replay_1_bits_uop_sqIdx_flag(i_io_replay_1_bits_uop_sqIdx_flag),
    .io_replay_1_bits_uop_sqIdx_value(i_io_replay_1_bits_uop_sqIdx_value),
    .io_replay_1_bits_uop_singleStep(i_io_replay_1_bits_uop_singleStep),
    .io_replay_1_bits_uop_debug_fuType(i_io_replay_1_bits_uop_debug_fuType),
    .io_replay_1_bits_uop_debug_sim_trig(i_io_replay_1_bits_uop_debug_sim_trig),
    .io_replay_1_bits_uop_numLsElem(i_io_replay_1_bits_uop_numLsElem),
    .io_replay_1_bits_vaddr(i_io_replay_1_bits_vaddr),
    .io_replay_1_bits_mask(i_io_replay_1_bits_mask),
    .io_replay_1_bits_isvec(i_io_replay_1_bits_isvec),
    .io_replay_1_bits_is128bit(i_io_replay_1_bits_is128bit),
    .io_replay_1_bits_elemIdx(i_io_replay_1_bits_elemIdx),
    .io_replay_1_bits_alignedType(i_io_replay_1_bits_alignedType),
    .io_replay_1_bits_mbIndex(i_io_replay_1_bits_mbIndex),
    .io_replay_1_bits_reg_offset(i_io_replay_1_bits_reg_offset),
    .io_replay_1_bits_elemIdxInsideVd(i_io_replay_1_bits_elemIdxInsideVd),
    .io_replay_1_bits_vecActive(i_io_replay_1_bits_vecActive),
    .io_replay_1_bits_mshrid(i_io_replay_1_bits_mshrid),
    .io_replay_1_bits_forward_tlDchannel(i_io_replay_1_bits_forward_tlDchannel),
    .io_replay_1_bits_schedIndex(i_io_replay_1_bits_schedIndex),
    .io_replay_2_valid(i_io_replay_2_valid),
    .io_replay_2_bits_uop_instr(i_io_replay_2_bits_uop_instr),
    .io_replay_2_bits_uop_pc(i_io_replay_2_bits_uop_pc),
    .io_replay_2_bits_uop_foldpc(i_io_replay_2_bits_uop_foldpc),
    .io_replay_2_bits_uop_exceptionVec_0(i_io_replay_2_bits_uop_exceptionVec_0),
    .io_replay_2_bits_uop_exceptionVec_1(i_io_replay_2_bits_uop_exceptionVec_1),
    .io_replay_2_bits_uop_exceptionVec_2(i_io_replay_2_bits_uop_exceptionVec_2),
    .io_replay_2_bits_uop_exceptionVec_3(i_io_replay_2_bits_uop_exceptionVec_3),
    .io_replay_2_bits_uop_exceptionVec_5(i_io_replay_2_bits_uop_exceptionVec_5),
    .io_replay_2_bits_uop_exceptionVec_6(i_io_replay_2_bits_uop_exceptionVec_6),
    .io_replay_2_bits_uop_exceptionVec_7(i_io_replay_2_bits_uop_exceptionVec_7),
    .io_replay_2_bits_uop_exceptionVec_8(i_io_replay_2_bits_uop_exceptionVec_8),
    .io_replay_2_bits_uop_exceptionVec_9(i_io_replay_2_bits_uop_exceptionVec_9),
    .io_replay_2_bits_uop_exceptionVec_10(i_io_replay_2_bits_uop_exceptionVec_10),
    .io_replay_2_bits_uop_exceptionVec_11(i_io_replay_2_bits_uop_exceptionVec_11),
    .io_replay_2_bits_uop_exceptionVec_12(i_io_replay_2_bits_uop_exceptionVec_12),
    .io_replay_2_bits_uop_exceptionVec_13(i_io_replay_2_bits_uop_exceptionVec_13),
    .io_replay_2_bits_uop_exceptionVec_14(i_io_replay_2_bits_uop_exceptionVec_14),
    .io_replay_2_bits_uop_exceptionVec_15(i_io_replay_2_bits_uop_exceptionVec_15),
    .io_replay_2_bits_uop_exceptionVec_16(i_io_replay_2_bits_uop_exceptionVec_16),
    .io_replay_2_bits_uop_exceptionVec_17(i_io_replay_2_bits_uop_exceptionVec_17),
    .io_replay_2_bits_uop_exceptionVec_18(i_io_replay_2_bits_uop_exceptionVec_18),
    .io_replay_2_bits_uop_exceptionVec_19(i_io_replay_2_bits_uop_exceptionVec_19),
    .io_replay_2_bits_uop_exceptionVec_20(i_io_replay_2_bits_uop_exceptionVec_20),
    .io_replay_2_bits_uop_exceptionVec_21(i_io_replay_2_bits_uop_exceptionVec_21),
    .io_replay_2_bits_uop_exceptionVec_22(i_io_replay_2_bits_uop_exceptionVec_22),
    .io_replay_2_bits_uop_exceptionVec_23(i_io_replay_2_bits_uop_exceptionVec_23),
    .io_replay_2_bits_uop_isFetchMalAddr(i_io_replay_2_bits_uop_isFetchMalAddr),
    .io_replay_2_bits_uop_hasException(i_io_replay_2_bits_uop_hasException),
    .io_replay_2_bits_uop_trigger(i_io_replay_2_bits_uop_trigger),
    .io_replay_2_bits_uop_preDecodeInfo_valid(i_io_replay_2_bits_uop_preDecodeInfo_valid),
    .io_replay_2_bits_uop_preDecodeInfo_isRVC(i_io_replay_2_bits_uop_preDecodeInfo_isRVC),
    .io_replay_2_bits_uop_preDecodeInfo_brType(i_io_replay_2_bits_uop_preDecodeInfo_brType),
    .io_replay_2_bits_uop_preDecodeInfo_isCall(i_io_replay_2_bits_uop_preDecodeInfo_isCall),
    .io_replay_2_bits_uop_preDecodeInfo_isRet(i_io_replay_2_bits_uop_preDecodeInfo_isRet),
    .io_replay_2_bits_uop_pred_taken(i_io_replay_2_bits_uop_pred_taken),
    .io_replay_2_bits_uop_crossPageIPFFix(i_io_replay_2_bits_uop_crossPageIPFFix),
    .io_replay_2_bits_uop_ftqPtr_flag(i_io_replay_2_bits_uop_ftqPtr_flag),
    .io_replay_2_bits_uop_ftqPtr_value(i_io_replay_2_bits_uop_ftqPtr_value),
    .io_replay_2_bits_uop_ftqOffset(i_io_replay_2_bits_uop_ftqOffset),
    .io_replay_2_bits_uop_satpFlushFirstFetchFault(i_io_replay_2_bits_uop_satpFlushFirstFetchFault),
    .io_replay_2_bits_uop_srcType_0(i_io_replay_2_bits_uop_srcType_0),
    .io_replay_2_bits_uop_srcType_1(i_io_replay_2_bits_uop_srcType_1),
    .io_replay_2_bits_uop_srcType_2(i_io_replay_2_bits_uop_srcType_2),
    .io_replay_2_bits_uop_srcType_3(i_io_replay_2_bits_uop_srcType_3),
    .io_replay_2_bits_uop_srcType_4(i_io_replay_2_bits_uop_srcType_4),
    .io_replay_2_bits_uop_ldest(i_io_replay_2_bits_uop_ldest),
    .io_replay_2_bits_uop_fuType(i_io_replay_2_bits_uop_fuType),
    .io_replay_2_bits_uop_fuOpType(i_io_replay_2_bits_uop_fuOpType),
    .io_replay_2_bits_uop_rfWen(i_io_replay_2_bits_uop_rfWen),
    .io_replay_2_bits_uop_fpWen(i_io_replay_2_bits_uop_fpWen),
    .io_replay_2_bits_uop_vecWen(i_io_replay_2_bits_uop_vecWen),
    .io_replay_2_bits_uop_v0Wen(i_io_replay_2_bits_uop_v0Wen),
    .io_replay_2_bits_uop_vlWen(i_io_replay_2_bits_uop_vlWen),
    .io_replay_2_bits_uop_isXSTrap(i_io_replay_2_bits_uop_isXSTrap),
    .io_replay_2_bits_uop_waitForward(i_io_replay_2_bits_uop_waitForward),
    .io_replay_2_bits_uop_blockBackward(i_io_replay_2_bits_uop_blockBackward),
    .io_replay_2_bits_uop_canRobCompress(i_io_replay_2_bits_uop_canRobCompress),
    .io_replay_2_bits_uop_selImm(i_io_replay_2_bits_uop_selImm),
    .io_replay_2_bits_uop_imm(i_io_replay_2_bits_uop_imm),
    .io_replay_2_bits_uop_fpu_typeTagOut(i_io_replay_2_bits_uop_fpu_typeTagOut),
    .io_replay_2_bits_uop_fpu_wflags(i_io_replay_2_bits_uop_fpu_wflags),
    .io_replay_2_bits_uop_fpu_typ(i_io_replay_2_bits_uop_fpu_typ),
    .io_replay_2_bits_uop_fpu_fmt(i_io_replay_2_bits_uop_fpu_fmt),
    .io_replay_2_bits_uop_fpu_rm(i_io_replay_2_bits_uop_fpu_rm),
    .io_replay_2_bits_uop_vpu_vill(i_io_replay_2_bits_uop_vpu_vill),
    .io_replay_2_bits_uop_vpu_vma(i_io_replay_2_bits_uop_vpu_vma),
    .io_replay_2_bits_uop_vpu_vta(i_io_replay_2_bits_uop_vpu_vta),
    .io_replay_2_bits_uop_vpu_vsew(i_io_replay_2_bits_uop_vpu_vsew),
    .io_replay_2_bits_uop_vpu_vlmul(i_io_replay_2_bits_uop_vpu_vlmul),
    .io_replay_2_bits_uop_vpu_specVill(i_io_replay_2_bits_uop_vpu_specVill),
    .io_replay_2_bits_uop_vpu_specVma(i_io_replay_2_bits_uop_vpu_specVma),
    .io_replay_2_bits_uop_vpu_specVta(i_io_replay_2_bits_uop_vpu_specVta),
    .io_replay_2_bits_uop_vpu_specVsew(i_io_replay_2_bits_uop_vpu_specVsew),
    .io_replay_2_bits_uop_vpu_specVlmul(i_io_replay_2_bits_uop_vpu_specVlmul),
    .io_replay_2_bits_uop_vpu_vm(i_io_replay_2_bits_uop_vpu_vm),
    .io_replay_2_bits_uop_vpu_vstart(i_io_replay_2_bits_uop_vpu_vstart),
    .io_replay_2_bits_uop_vpu_frm(i_io_replay_2_bits_uop_vpu_frm),
    .io_replay_2_bits_uop_vpu_fpu_isFpToVecInst(i_io_replay_2_bits_uop_vpu_fpu_isFpToVecInst),
    .io_replay_2_bits_uop_vpu_fpu_isFP32Instr(i_io_replay_2_bits_uop_vpu_fpu_isFP32Instr),
    .io_replay_2_bits_uop_vpu_fpu_isFP64Instr(i_io_replay_2_bits_uop_vpu_fpu_isFP64Instr),
    .io_replay_2_bits_uop_vpu_fpu_isReduction(i_io_replay_2_bits_uop_vpu_fpu_isReduction),
    .io_replay_2_bits_uop_vpu_fpu_isFoldTo1_2(i_io_replay_2_bits_uop_vpu_fpu_isFoldTo1_2),
    .io_replay_2_bits_uop_vpu_fpu_isFoldTo1_4(i_io_replay_2_bits_uop_vpu_fpu_isFoldTo1_4),
    .io_replay_2_bits_uop_vpu_fpu_isFoldTo1_8(i_io_replay_2_bits_uop_vpu_fpu_isFoldTo1_8),
    .io_replay_2_bits_uop_vpu_vxrm(i_io_replay_2_bits_uop_vpu_vxrm),
    .io_replay_2_bits_uop_vpu_vuopIdx(i_io_replay_2_bits_uop_vpu_vuopIdx),
    .io_replay_2_bits_uop_vpu_lastUop(i_io_replay_2_bits_uop_vpu_lastUop),
    .io_replay_2_bits_uop_vpu_vmask(i_io_replay_2_bits_uop_vpu_vmask),
    .io_replay_2_bits_uop_vpu_vl(i_io_replay_2_bits_uop_vpu_vl),
    .io_replay_2_bits_uop_vpu_nf(i_io_replay_2_bits_uop_vpu_nf),
    .io_replay_2_bits_uop_vpu_veew(i_io_replay_2_bits_uop_vpu_veew),
    .io_replay_2_bits_uop_vpu_isReverse(i_io_replay_2_bits_uop_vpu_isReverse),
    .io_replay_2_bits_uop_vpu_isExt(i_io_replay_2_bits_uop_vpu_isExt),
    .io_replay_2_bits_uop_vpu_isNarrow(i_io_replay_2_bits_uop_vpu_isNarrow),
    .io_replay_2_bits_uop_vpu_isDstMask(i_io_replay_2_bits_uop_vpu_isDstMask),
    .io_replay_2_bits_uop_vpu_isOpMask(i_io_replay_2_bits_uop_vpu_isOpMask),
    .io_replay_2_bits_uop_vpu_isMove(i_io_replay_2_bits_uop_vpu_isMove),
    .io_replay_2_bits_uop_vpu_isDependOldVd(i_io_replay_2_bits_uop_vpu_isDependOldVd),
    .io_replay_2_bits_uop_vpu_isWritePartVd(i_io_replay_2_bits_uop_vpu_isWritePartVd),
    .io_replay_2_bits_uop_vpu_isVleff(i_io_replay_2_bits_uop_vpu_isVleff),
    .io_replay_2_bits_uop_vlsInstr(i_io_replay_2_bits_uop_vlsInstr),
    .io_replay_2_bits_uop_wfflags(i_io_replay_2_bits_uop_wfflags),
    .io_replay_2_bits_uop_isMove(i_io_replay_2_bits_uop_isMove),
    .io_replay_2_bits_uop_isDropAmocasSta(i_io_replay_2_bits_uop_isDropAmocasSta),
    .io_replay_2_bits_uop_uopIdx(i_io_replay_2_bits_uop_uopIdx),
    .io_replay_2_bits_uop_isVset(i_io_replay_2_bits_uop_isVset),
    .io_replay_2_bits_uop_firstUop(i_io_replay_2_bits_uop_firstUop),
    .io_replay_2_bits_uop_lastUop(i_io_replay_2_bits_uop_lastUop),
    .io_replay_2_bits_uop_numUops(i_io_replay_2_bits_uop_numUops),
    .io_replay_2_bits_uop_numWB(i_io_replay_2_bits_uop_numWB),
    .io_replay_2_bits_uop_commitType(i_io_replay_2_bits_uop_commitType),
    .io_replay_2_bits_uop_srcState_0(i_io_replay_2_bits_uop_srcState_0),
    .io_replay_2_bits_uop_srcState_1(i_io_replay_2_bits_uop_srcState_1),
    .io_replay_2_bits_uop_srcState_2(i_io_replay_2_bits_uop_srcState_2),
    .io_replay_2_bits_uop_srcState_3(i_io_replay_2_bits_uop_srcState_3),
    .io_replay_2_bits_uop_srcState_4(i_io_replay_2_bits_uop_srcState_4),
    .io_replay_2_bits_uop_srcLoadDependency_0_0(i_io_replay_2_bits_uop_srcLoadDependency_0_0),
    .io_replay_2_bits_uop_srcLoadDependency_0_1(i_io_replay_2_bits_uop_srcLoadDependency_0_1),
    .io_replay_2_bits_uop_srcLoadDependency_0_2(i_io_replay_2_bits_uop_srcLoadDependency_0_2),
    .io_replay_2_bits_uop_srcLoadDependency_1_0(i_io_replay_2_bits_uop_srcLoadDependency_1_0),
    .io_replay_2_bits_uop_srcLoadDependency_1_1(i_io_replay_2_bits_uop_srcLoadDependency_1_1),
    .io_replay_2_bits_uop_srcLoadDependency_1_2(i_io_replay_2_bits_uop_srcLoadDependency_1_2),
    .io_replay_2_bits_uop_srcLoadDependency_2_0(i_io_replay_2_bits_uop_srcLoadDependency_2_0),
    .io_replay_2_bits_uop_srcLoadDependency_2_1(i_io_replay_2_bits_uop_srcLoadDependency_2_1),
    .io_replay_2_bits_uop_srcLoadDependency_2_2(i_io_replay_2_bits_uop_srcLoadDependency_2_2),
    .io_replay_2_bits_uop_srcLoadDependency_3_0(i_io_replay_2_bits_uop_srcLoadDependency_3_0),
    .io_replay_2_bits_uop_srcLoadDependency_3_1(i_io_replay_2_bits_uop_srcLoadDependency_3_1),
    .io_replay_2_bits_uop_srcLoadDependency_3_2(i_io_replay_2_bits_uop_srcLoadDependency_3_2),
    .io_replay_2_bits_uop_srcLoadDependency_4_0(i_io_replay_2_bits_uop_srcLoadDependency_4_0),
    .io_replay_2_bits_uop_srcLoadDependency_4_1(i_io_replay_2_bits_uop_srcLoadDependency_4_1),
    .io_replay_2_bits_uop_srcLoadDependency_4_2(i_io_replay_2_bits_uop_srcLoadDependency_4_2),
    .io_replay_2_bits_uop_psrc_0(i_io_replay_2_bits_uop_psrc_0),
    .io_replay_2_bits_uop_psrc_1(i_io_replay_2_bits_uop_psrc_1),
    .io_replay_2_bits_uop_psrc_2(i_io_replay_2_bits_uop_psrc_2),
    .io_replay_2_bits_uop_psrc_3(i_io_replay_2_bits_uop_psrc_3),
    .io_replay_2_bits_uop_psrc_4(i_io_replay_2_bits_uop_psrc_4),
    .io_replay_2_bits_uop_pdest(i_io_replay_2_bits_uop_pdest),
    .io_replay_2_bits_uop_useRegCache_0(i_io_replay_2_bits_uop_useRegCache_0),
    .io_replay_2_bits_uop_useRegCache_1(i_io_replay_2_bits_uop_useRegCache_1),
    .io_replay_2_bits_uop_regCacheIdx_0(i_io_replay_2_bits_uop_regCacheIdx_0),
    .io_replay_2_bits_uop_regCacheIdx_1(i_io_replay_2_bits_uop_regCacheIdx_1),
    .io_replay_2_bits_uop_robIdx_flag(i_io_replay_2_bits_uop_robIdx_flag),
    .io_replay_2_bits_uop_robIdx_value(i_io_replay_2_bits_uop_robIdx_value),
    .io_replay_2_bits_uop_instrSize(i_io_replay_2_bits_uop_instrSize),
    .io_replay_2_bits_uop_dirtyFs(i_io_replay_2_bits_uop_dirtyFs),
    .io_replay_2_bits_uop_dirtyVs(i_io_replay_2_bits_uop_dirtyVs),
    .io_replay_2_bits_uop_traceBlockInPipe_itype(i_io_replay_2_bits_uop_traceBlockInPipe_itype),
    .io_replay_2_bits_uop_traceBlockInPipe_iretire(i_io_replay_2_bits_uop_traceBlockInPipe_iretire),
    .io_replay_2_bits_uop_traceBlockInPipe_ilastsize(i_io_replay_2_bits_uop_traceBlockInPipe_ilastsize),
    .io_replay_2_bits_uop_eliminatedMove(i_io_replay_2_bits_uop_eliminatedMove),
    .io_replay_2_bits_uop_snapshot(i_io_replay_2_bits_uop_snapshot),
    .io_replay_2_bits_uop_debugInfo_eliminatedMove(i_io_replay_2_bits_uop_debugInfo_eliminatedMove),
    .io_replay_2_bits_uop_debugInfo_renameTime(i_io_replay_2_bits_uop_debugInfo_renameTime),
    .io_replay_2_bits_uop_debugInfo_dispatchTime(i_io_replay_2_bits_uop_debugInfo_dispatchTime),
    .io_replay_2_bits_uop_debugInfo_enqRsTime(i_io_replay_2_bits_uop_debugInfo_enqRsTime),
    .io_replay_2_bits_uop_debugInfo_selectTime(i_io_replay_2_bits_uop_debugInfo_selectTime),
    .io_replay_2_bits_uop_debugInfo_issueTime(i_io_replay_2_bits_uop_debugInfo_issueTime),
    .io_replay_2_bits_uop_debugInfo_writebackTime(i_io_replay_2_bits_uop_debugInfo_writebackTime),
    .io_replay_2_bits_uop_debugInfo_runahead_checkpoint_id(i_io_replay_2_bits_uop_debugInfo_runahead_checkpoint_id),
    .io_replay_2_bits_uop_debugInfo_tlbFirstReqTime(i_io_replay_2_bits_uop_debugInfo_tlbFirstReqTime),
    .io_replay_2_bits_uop_debugInfo_tlbRespTime(i_io_replay_2_bits_uop_debugInfo_tlbRespTime),
    .io_replay_2_bits_uop_debug_seqNum_seqNum(i_io_replay_2_bits_uop_debug_seqNum_seqNum),
    .io_replay_2_bits_uop_debug_seqNum_uopIdx(i_io_replay_2_bits_uop_debug_seqNum_uopIdx),
    .io_replay_2_bits_uop_storeSetHit(i_io_replay_2_bits_uop_storeSetHit),
    .io_replay_2_bits_uop_waitForRobIdx_flag(i_io_replay_2_bits_uop_waitForRobIdx_flag),
    .io_replay_2_bits_uop_waitForRobIdx_value(i_io_replay_2_bits_uop_waitForRobIdx_value),
    .io_replay_2_bits_uop_loadWaitBit(i_io_replay_2_bits_uop_loadWaitBit),
    .io_replay_2_bits_uop_ssid(i_io_replay_2_bits_uop_ssid),
    .io_replay_2_bits_uop_lqIdx_flag(i_io_replay_2_bits_uop_lqIdx_flag),
    .io_replay_2_bits_uop_lqIdx_value(i_io_replay_2_bits_uop_lqIdx_value),
    .io_replay_2_bits_uop_sqIdx_flag(i_io_replay_2_bits_uop_sqIdx_flag),
    .io_replay_2_bits_uop_sqIdx_value(i_io_replay_2_bits_uop_sqIdx_value),
    .io_replay_2_bits_uop_singleStep(i_io_replay_2_bits_uop_singleStep),
    .io_replay_2_bits_uop_debug_fuType(i_io_replay_2_bits_uop_debug_fuType),
    .io_replay_2_bits_uop_debug_sim_trig(i_io_replay_2_bits_uop_debug_sim_trig),
    .io_replay_2_bits_uop_numLsElem(i_io_replay_2_bits_uop_numLsElem),
    .io_replay_2_bits_vaddr(i_io_replay_2_bits_vaddr),
    .io_replay_2_bits_mask(i_io_replay_2_bits_mask),
    .io_replay_2_bits_isvec(i_io_replay_2_bits_isvec),
    .io_replay_2_bits_is128bit(i_io_replay_2_bits_is128bit),
    .io_replay_2_bits_elemIdx(i_io_replay_2_bits_elemIdx),
    .io_replay_2_bits_alignedType(i_io_replay_2_bits_alignedType),
    .io_replay_2_bits_mbIndex(i_io_replay_2_bits_mbIndex),
    .io_replay_2_bits_reg_offset(i_io_replay_2_bits_reg_offset),
    .io_replay_2_bits_elemIdxInsideVd(i_io_replay_2_bits_elemIdxInsideVd),
    .io_replay_2_bits_vecActive(i_io_replay_2_bits_vecActive),
    .io_replay_2_bits_mshrid(i_io_replay_2_bits_mshrid),
    .io_replay_2_bits_forward_tlDchannel(i_io_replay_2_bits_forward_tlDchannel),
    .io_replay_2_bits_schedIndex(i_io_replay_2_bits_schedIndex),
    .io_lqFull(i_io_lqFull),
    .io_debugTopDown_robHeadTlbReplay(i_io_debugTopDown_robHeadTlbReplay),
    .io_debugTopDown_robHeadTlbMiss(i_io_debugTopDown_robHeadTlbMiss),
    .io_debugTopDown_robHeadLoadVio(i_io_debugTopDown_robHeadLoadVio),
    .io_debugTopDown_robHeadLoadMSHR(i_io_debugTopDown_robHeadLoadMSHR),
    .io_replayAllocate(i_io_replayAllocate),
    .io_perf_0_value(i_io_perf_0_value),
    .io_perf_1_value(i_io_perf_1_value),
    .io_perf_2_value(i_io_perf_2_value),
    .io_perf_3_value(i_io_perf_3_value),
    .io_perf_4_value(i_io_perf_4_value),
    .io_perf_5_value(i_io_perf_5_value),
    .io_perf_6_value(i_io_perf_6_value),
    .io_perf_7_value(i_io_perf_7_value),
    .io_perf_8_value(i_io_perf_8_value),
    .io_perf_9_value(i_io_perf_9_value),
    .io_perf_10_value(i_io_perf_10_value),
    .io_perf_11_value(i_io_perf_11_value),
    .io_perf_12_value(i_io_perf_12_value)
  );


  // ===========================================================================
  //  激励模型
  // ===========================================================================
  //  ★暖机窗口（本 tb 最要紧的一处）★
  //  72 条 entry 的 uop / vecReplay / blockSqIdx 在 golden 里是**不复位**寄存器
  //  （契约靠 allocated 有效位保证：没写过就不会被选中）。两侧各自例化、各抽各的
  //  上电值，所以只要比较窗口在它们被写之前就打开，某些输出（尤其 s2 无条件按
  //  s1 下标读出来的 replay payload，valid=0 时照样往外送）必然不等 ——
  //  ★这时红的是 tb 不是 RTL★。
  //  做法：开头 WARM 拍只灌入队、不发 redirect、不回流（于是没有任何槽被释放），
  //  freelist 3 拍分 3 个槽，24 拍就把 72 个槽全部写满；比较从第 WARM 拍才开始。
  //  入队 cause 里固定带上 C_MA|C_FF，好让 blockSqIdx 这个不复位寄存器也被写到。
  //  同理 s1/s2 的下标与 payload 寄存器在暖机期内也都被写过至少一次。
  localparam int WARM = 400;

  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cyc = 0;

  // ---- 覆盖分桶（★errors=0 单独不算数：这些桶必须非零★）----
  int cov_cause [11];      // 各 cause 入队次数
  int cov_replay_fire;     // 重放发射
  int cov_replay_stall;    // valid & ~ready
  int cov_lqfull;          // freelist 空
  int cov_redirect;        // redirect 有效
  int cov_flush_hit;       // redirect 真的刷掉了队里的项（lqFull 从空->非空之外的证据）
  int cov_loadreplay;      // isLoadReplay 回流
  int cov_lr_free;         // 回流且不再需重放（释放路径）
  int cov_l2hint;          // l2 hint 唤醒
  int cov_tlbhint;         // tlb hint 回填
  int cov_tld;             // D-channel 响应
  int cov_tld_prev;        // ★G1 新增：入队时命中「上一拍」的 D-channel
  int cov_mf_block;        // C_MF 入队（robDeqPtr 解除路径）
  int cov_mf_release;      // C_MF 项的 robIdx 追上 robDeqPtr
  int cov_cold;            // 连续发射（冷却计数器爬升）
  int cov_vecfb;           // vecFeedback 有效
  int cov_topdown;         // topdown 命中
  int cov_allocate;        // replayAllocate=1

  int phase;
  // 回流用的 schedIndex 池：从重放输出里捞，保证回流的下标确实是分配过的槽
  int lr_pool [$];

  // 上一拍的 D-channel（用来构造「命中上一拍」的场景）
  bit       prev_tld_v;
  bit [3:0] prev_tld_id;

  function automatic bit [10:0] gen_cause(input int ph, input int w);
    bit [10:0] c;
    c = '0;
    case (ph)
      0: c = $urandom_range(1, 11'h7FF);            // 全随机（至少一个 cause）
      1: begin c[4] = 1'b1;                          // C_DM 为主
           if ($urandom_range(0,3) == 0) c[2] = 1'b1; end
      2: begin c[0] = 1'b1; c[2] = 1'b1; end         // C_MA + C_FF
      3: c = $urandom_range(1, 11'h7FF);
      4: begin c[1] = 1'b1; end                      // C_TM
      5: begin c[10] = 1'b1;                         // C_MF（G1 新解除条件）
           if ($urandom_range(0,2) == 0) c[8] = 1'b1; end
      6: begin c[3] = 1'b1; c[6] = 1'b1; end         // C_DR + C_BC（入队即不 block）
      7: begin c[7] = 1'b1; c[8] = 1'b1; end         // C_RAR + C_RAW
      default: c = $urandom_range(1, 11'h7FF);
    endcase
    return c;
  endfunction

  // 把一条入队请求的控制字段灌进第 w 口
  task automatic drive_enq(input int w, input bit warm);
    bit do_lr;
    bit [10:0] c;
    do_lr = 0;
    if (!warm && lr_pool.size() > 8 && $urandom_range(0, 3) == 0) do_lr = 1;
    c = warm ? 11'b000_0000_0101 : gen_cause(phase, w);   // 暖机固定 C_MA|C_FF
    case (w)
      0: begin
        io_enq_0_valid                = warm ? 1'b1 : ($urandom_range(0,3) != 0);
        io_enq_0_bits_isLoadReplay    = do_lr;
        // 回流且 cause 全 0 = 释放路径（不再需要重放）
        {io_enq_0_bits_rep_info_cause_10, io_enq_0_bits_rep_info_cause_9,
         io_enq_0_bits_rep_info_cause_8,  io_enq_0_bits_rep_info_cause_7,
         io_enq_0_bits_rep_info_cause_6,  io_enq_0_bits_rep_info_cause_5,
         io_enq_0_bits_rep_info_cause_4,  io_enq_0_bits_rep_info_cause_3,
         io_enq_0_bits_rep_info_cause_2,  io_enq_0_bits_rep_info_cause_1,
         io_enq_0_bits_rep_info_cause_0} = (do_lr && $urandom_range(0,2) == 0) ? 11'h0 : c;
        io_enq_0_bits_schedIndex      = do_lr ? lr_pool[$urandom_range(0, lr_pool.size()-1)]
                                              : $urandom_range(0, 71);
        io_enq_0_bits_handledByMSHR   = $urandom_range(0, 1);
        io_enq_0_bits_rep_info_mshr_id= $urandom_range(0, 15);
        io_enq_0_bits_rep_info_tlb_id = $urandom_range(0, 15);
        io_enq_0_bits_rep_info_tlb_full    = $urandom_range(0, 1);
        io_enq_0_bits_rep_info_full_fwd    = $urandom_range(0, 1);
        io_enq_0_bits_rep_info_last_beat   = $urandom_range(0, 1);
        io_enq_0_bits_rep_info_data_inv_sq_idx_flag  = $urandom_range(0, 1);
        io_enq_0_bits_rep_info_data_inv_sq_idx_value = $urandom_range(0, 63);
        io_enq_0_bits_rep_info_addr_inv_sq_idx_flag  = $urandom_range(0, 1);
        io_enq_0_bits_rep_info_addr_inv_sq_idx_value = $urandom_range(0, 63);
        io_enq_0_bits_vaddr           = {$urandom, $urandom} & 50'h3FFFF;  // 窄地址空间→topdown 易命中
        io_enq_0_bits_uop_robIdx_flag = $urandom_range(0, 1);
        io_enq_0_bits_uop_robIdx_value= $urandom_range(0, 255);
        io_enq_0_bits_uop_lqIdx_flag  = $urandom_range(0, 1);
        io_enq_0_bits_uop_lqIdx_value = $urandom_range(0, 71);
        io_enq_0_bits_uop_sqIdx_flag  = $urandom_range(0, 1);
        io_enq_0_bits_uop_sqIdx_value = $urandom_range(0, 63);
        io_enq_0_bits_uop_uopIdx      = $urandom_range(0, 127);
        io_enq_0_bits_uop_loadWaitStrict = $urandom_range(0, 1);
      end
      1: begin
        io_enq_1_valid                = warm ? 1'b1 : ($urandom_range(0,3) != 0);
        io_enq_1_bits_isLoadReplay    = do_lr;
        {io_enq_1_bits_rep_info_cause_10, io_enq_1_bits_rep_info_cause_9,
         io_enq_1_bits_rep_info_cause_8,  io_enq_1_bits_rep_info_cause_7,
         io_enq_1_bits_rep_info_cause_6,  io_enq_1_bits_rep_info_cause_5,
         io_enq_1_bits_rep_info_cause_4,  io_enq_1_bits_rep_info_cause_3,
         io_enq_1_bits_rep_info_cause_2,  io_enq_1_bits_rep_info_cause_1,
         io_enq_1_bits_rep_info_cause_0} = (do_lr && $urandom_range(0,2) == 0) ? 11'h0 : c;
        io_enq_1_bits_schedIndex      = do_lr ? lr_pool[$urandom_range(0, lr_pool.size()-1)]
                                              : $urandom_range(0, 71);
        io_enq_1_bits_handledByMSHR   = $urandom_range(0, 1);
        io_enq_1_bits_rep_info_mshr_id= $urandom_range(0, 15);
        io_enq_1_bits_rep_info_tlb_id = $urandom_range(0, 15);
        io_enq_1_bits_rep_info_tlb_full    = $urandom_range(0, 1);
        io_enq_1_bits_rep_info_full_fwd    = $urandom_range(0, 1);
        io_enq_1_bits_rep_info_last_beat   = $urandom_range(0, 1);
        io_enq_1_bits_rep_info_data_inv_sq_idx_flag  = $urandom_range(0, 1);
        io_enq_1_bits_rep_info_data_inv_sq_idx_value = $urandom_range(0, 63);
        io_enq_1_bits_rep_info_addr_inv_sq_idx_flag  = $urandom_range(0, 1);
        io_enq_1_bits_rep_info_addr_inv_sq_idx_value = $urandom_range(0, 63);
        io_enq_1_bits_vaddr           = {$urandom, $urandom} & 50'h3FFFF;
        io_enq_1_bits_uop_robIdx_flag = $urandom_range(0, 1);
        io_enq_1_bits_uop_robIdx_value= $urandom_range(0, 255);
        io_enq_1_bits_uop_lqIdx_flag  = $urandom_range(0, 1);
        io_enq_1_bits_uop_lqIdx_value = $urandom_range(0, 71);
        io_enq_1_bits_uop_sqIdx_flag  = $urandom_range(0, 1);
        io_enq_1_bits_uop_sqIdx_value = $urandom_range(0, 63);
        io_enq_1_bits_uop_uopIdx      = $urandom_range(0, 127);
        io_enq_1_bits_uop_loadWaitStrict = $urandom_range(0, 1);
      end
      default: begin
        io_enq_2_valid                = warm ? 1'b1 : ($urandom_range(0,3) != 0);
        io_enq_2_bits_isLoadReplay    = do_lr;
        {io_enq_2_bits_rep_info_cause_10, io_enq_2_bits_rep_info_cause_9,
         io_enq_2_bits_rep_info_cause_8,  io_enq_2_bits_rep_info_cause_7,
         io_enq_2_bits_rep_info_cause_6,  io_enq_2_bits_rep_info_cause_5,
         io_enq_2_bits_rep_info_cause_4,  io_enq_2_bits_rep_info_cause_3,
         io_enq_2_bits_rep_info_cause_2,  io_enq_2_bits_rep_info_cause_1,
         io_enq_2_bits_rep_info_cause_0} = (do_lr && $urandom_range(0,2) == 0) ? 11'h0 : c;
        io_enq_2_bits_schedIndex      = do_lr ? lr_pool[$urandom_range(0, lr_pool.size()-1)]
                                              : $urandom_range(0, 71);
        io_enq_2_bits_handledByMSHR   = $urandom_range(0, 1);
        io_enq_2_bits_rep_info_mshr_id= $urandom_range(0, 15);
        io_enq_2_bits_rep_info_tlb_id = $urandom_range(0, 15);
        io_enq_2_bits_rep_info_tlb_full    = $urandom_range(0, 1);
        io_enq_2_bits_rep_info_full_fwd    = $urandom_range(0, 1);
        io_enq_2_bits_rep_info_last_beat   = $urandom_range(0, 1);
        io_enq_2_bits_rep_info_data_inv_sq_idx_flag  = $urandom_range(0, 1);
        io_enq_2_bits_rep_info_data_inv_sq_idx_value = $urandom_range(0, 63);
        io_enq_2_bits_rep_info_addr_inv_sq_idx_flag  = $urandom_range(0, 1);
        io_enq_2_bits_rep_info_addr_inv_sq_idx_value = $urandom_range(0, 63);
        io_enq_2_bits_vaddr           = {$urandom, $urandom} & 50'h3FFFF;
        io_enq_2_bits_uop_robIdx_flag = $urandom_range(0, 1);
        io_enq_2_bits_uop_robIdx_value= $urandom_range(0, 255);
        io_enq_2_bits_uop_lqIdx_flag  = $urandom_range(0, 1);
        io_enq_2_bits_uop_lqIdx_value = $urandom_range(0, 71);
        io_enq_2_bits_uop_sqIdx_flag  = $urandom_range(0, 1);
        io_enq_2_bits_uop_sqIdx_value = $urandom_range(0, 63);
        io_enq_2_bits_uop_uopIdx      = $urandom_range(0, 127);
        io_enq_2_bits_uop_loadWaitStrict = $urandom_range(0, 1);
      end
    endcase
  endtask

  task automatic drive_env(input bit warm);
    automatic int r;
    // ---- redirect：暖机期内一律关掉（否则会释放槽，暖机就填不满 72 条）----
    if (warm) begin
      io_redirect_valid = 1'b0;
    end else begin
      io_redirect_valid = (phase == 3) ? ($urandom_range(0, 3) == 0)
                                       : ($urandom_range(0, 63) == 0);
    end
    io_redirect_bits_robIdx_flag  = $urandom_range(0, 1);
    io_redirect_bits_robIdx_value = $urandom_range(0, 255);
    io_redirect_bits_level        = $urandom_range(0, 1);

    // ---- D-channel：phase 1 里高密度，并且**刻意重复上一拍的 id**，
    //      好把 G1 新增的「命中上一拍 D-channel」那一项打出来 ----
    prev_tld_v  = io_tl_d_channel_valid;
    prev_tld_id = io_tl_d_channel_mshrid;
    io_tl_d_channel_valid  = warm ? 1'b0 : ((phase == 1) ? ($urandom_range(0,1) == 0)
                                                         : ($urandom_range(0,7) == 0));
    io_tl_d_channel_mshrid = $urandom_range(0, 15);

    // ---- l2 hint ----
    io_l2_hint_valid           = warm ? 1'b0 : ((phase == 1) ? ($urandom_range(0,3) == 0)
                                                             : ($urandom_range(0,15) == 0));
    io_l2_hint_bits_sourceId   = $urandom_range(0, 15);
    io_l2_hint_bits_isKeyword  = $urandom_range(0, 1);

    // ---- tlb hint ----
    io_tlb_hint_resp_valid            = warm ? 1'b0 : ((phase == 4) ? ($urandom_range(0,3) == 0)
                                                                    : ($urandom_range(0,15) == 0));
    io_tlb_hint_resp_bits_id          = $urandom_range(0, 15);
    io_tlb_hint_resp_bits_replay_all  = ($urandom_range(0, 7) == 0);

    // ---- StoreQueue 就绪指针/向量 ----
    io_stAddrReadySqPtr_flag  = $urandom_range(0, 1);
    io_stAddrReadySqPtr_value = $urandom_range(0, 63);
    io_stDataReadySqPtr_flag  = $urandom_range(0, 1);
    io_stDataReadySqPtr_value = $urandom_range(0, 63);
    io_sqEmpty                = ($urandom_range(0, 15) == 0);
    for (int k = 0; k < 56; k++) begin
      st_addr_rdy[k] = (phase == 2) ? $urandom_range(0,1) : ($urandom_range(0,3) != 0);
      st_data_rdy[k] = (phase == 2) ? $urandom_range(0,1) : ($urandom_range(0,3) != 0);
    end

    // ---- STA / STD ----
    for (int w = 0; w < 2; w++) begin
      sta_v[w]  = (phase == 2) ? ($urandom_range(0,1) == 0) : ($urandom_range(0,3) == 0);
      sta_f[w]  = $urandom_range(0, 1);
      sta_i[w]  = $urandom_range(0, 63);
      sta_m[w]  = ($urandom_range(0, 3) == 0);
      std_v[w]  = (phase == 2) ? ($urandom_range(0,1) == 0) : ($urandom_range(0,3) == 0);
      std_f[w]  = $urandom_range(0, 1);
      std_i[w]  = $urandom_range(0, 63);
    end

    // ---- vecFeedback（本模块解码后不使用，仍然要打满以防真的接错）----
    for (int w = 0; w < 2; w++) begin
      vfb_v[w]  = ($urandom_range(0, 7) == 0);
      vfb_f[w]  = $urandom_range(0, 1);
      vfb_r[w]  = $urandom_range(0, 255);
      vfb_u[w]  = $urandom_range(0, 127);
      vfb_c[w]  = $urandom_range(0, 1);
      vfb_l[w]  = $urandom_range(0, 1);
    end

    // ---- 指针/满标志 ----
    io_ldWbPtr_flag   = $urandom_range(0, 1);
    io_ldWbPtr_value  = $urandom_range(0, 71);
    // ★phase 5 让 robDeqPtr 扫过整个 rob 空间，把 C_MF 的解除条件真正打出来★
    if (phase == 5) begin
      io_robDeqPtr_value = cyc[7:0];
      io_robDeqPtr_flag  = cyc[8];
    end else begin
      io_robDeqPtr_flag  = $urandom_range(0, 1);
      io_robDeqPtr_value = $urandom_range(0, 255);
    end
    io_rarFull = ($urandom_range(0, 3) == 0);
    io_rawFull = ($urandom_range(0, 3) == 0);

    // ---- 重放背压：phase 6 制造连发/卡死，驱动冷却计数器 ----
    for (int w = 0; w < 3; w++)
      rep_rdy[w] = warm ? 1'b1
                        : ((phase == 6) ? ($urandom_range(0, 7) != 0) : ($urandom_range(0, 3) != 0));

    // ---- topdown ----
    io_debugTopDown_robHeadVaddr_valid = ($urandom_range(0, 1) == 0);
    io_debugTopDown_robHeadVaddr_bits  = {$urandom, $urandom} & 50'h3FFFF;
    io_debugTopDown_robHeadMissInDTlb  = $urandom_range(0, 1);
  endtask


  // ---- 每拍随机的 payload 输入（534 个，纯存-转发，不进控制通路）----
  task automatic drive_payload();
    io_enq_0_bits_uop_instr = $urandom;
    io_enq_0_bits_uop_pc = {$urandom, $urandom};
    io_enq_0_bits_uop_foldpc = $urandom;
    io_enq_0_bits_uop_exceptionVec_0 = $urandom;
    io_enq_0_bits_uop_exceptionVec_1 = $urandom;
    io_enq_0_bits_uop_exceptionVec_2 = $urandom;
    io_enq_0_bits_uop_exceptionVec_3 = $urandom;
    io_enq_0_bits_uop_exceptionVec_5 = $urandom;
    io_enq_0_bits_uop_exceptionVec_6 = $urandom;
    io_enq_0_bits_uop_exceptionVec_7 = $urandom;
    io_enq_0_bits_uop_exceptionVec_8 = $urandom;
    io_enq_0_bits_uop_exceptionVec_9 = $urandom;
    io_enq_0_bits_uop_exceptionVec_10 = $urandom;
    io_enq_0_bits_uop_exceptionVec_11 = $urandom;
    io_enq_0_bits_uop_exceptionVec_12 = $urandom;
    io_enq_0_bits_uop_exceptionVec_13 = $urandom;
    io_enq_0_bits_uop_exceptionVec_14 = $urandom;
    io_enq_0_bits_uop_exceptionVec_15 = $urandom;
    io_enq_0_bits_uop_exceptionVec_16 = $urandom;
    io_enq_0_bits_uop_exceptionVec_17 = $urandom;
    io_enq_0_bits_uop_exceptionVec_18 = $urandom;
    io_enq_0_bits_uop_exceptionVec_19 = $urandom;
    io_enq_0_bits_uop_exceptionVec_20 = $urandom;
    io_enq_0_bits_uop_exceptionVec_21 = $urandom;
    io_enq_0_bits_uop_exceptionVec_22 = $urandom;
    io_enq_0_bits_uop_exceptionVec_23 = $urandom;
    io_enq_0_bits_uop_isFetchMalAddr = $urandom;
    io_enq_0_bits_uop_hasException = $urandom;
    io_enq_0_bits_uop_trigger = $urandom;
    io_enq_0_bits_uop_preDecodeInfo_valid = $urandom;
    io_enq_0_bits_uop_preDecodeInfo_isRVC = $urandom;
    io_enq_0_bits_uop_preDecodeInfo_brType = $urandom;
    io_enq_0_bits_uop_preDecodeInfo_isCall = $urandom;
    io_enq_0_bits_uop_preDecodeInfo_isRet = $urandom;
    io_enq_0_bits_uop_pred_taken = $urandom;
    io_enq_0_bits_uop_crossPageIPFFix = $urandom;
    io_enq_0_bits_uop_ftqPtr_flag = $urandom;
    io_enq_0_bits_uop_ftqPtr_value = $urandom;
    io_enq_0_bits_uop_ftqOffset = $urandom;
    io_enq_0_bits_uop_satpFlushFirstFetchFault = $urandom;
    io_enq_0_bits_uop_srcType_0 = $urandom;
    io_enq_0_bits_uop_srcType_1 = $urandom;
    io_enq_0_bits_uop_srcType_2 = $urandom;
    io_enq_0_bits_uop_srcType_3 = $urandom;
    io_enq_0_bits_uop_srcType_4 = $urandom;
    io_enq_0_bits_uop_ldest = $urandom;
    io_enq_0_bits_uop_fuType = {$urandom, $urandom};
    io_enq_0_bits_uop_fuOpType = $urandom;
    io_enq_0_bits_uop_rfWen = $urandom;
    io_enq_0_bits_uop_fpWen = $urandom;
    io_enq_0_bits_uop_vecWen = $urandom;
    io_enq_0_bits_uop_v0Wen = $urandom;
    io_enq_0_bits_uop_vlWen = $urandom;
    io_enq_0_bits_uop_isXSTrap = $urandom;
    io_enq_0_bits_uop_waitForward = $urandom;
    io_enq_0_bits_uop_blockBackward = $urandom;
    io_enq_0_bits_uop_canRobCompress = $urandom;
    io_enq_0_bits_uop_selImm = $urandom;
    io_enq_0_bits_uop_imm = $urandom;
    io_enq_0_bits_uop_fpu_typeTagOut = $urandom;
    io_enq_0_bits_uop_fpu_wflags = $urandom;
    io_enq_0_bits_uop_fpu_typ = $urandom;
    io_enq_0_bits_uop_fpu_fmt = $urandom;
    io_enq_0_bits_uop_fpu_rm = $urandom;
    io_enq_0_bits_uop_vpu_vill = $urandom;
    io_enq_0_bits_uop_vpu_vma = $urandom;
    io_enq_0_bits_uop_vpu_vta = $urandom;
    io_enq_0_bits_uop_vpu_vsew = $urandom;
    io_enq_0_bits_uop_vpu_vlmul = $urandom;
    io_enq_0_bits_uop_vpu_specVill = $urandom;
    io_enq_0_bits_uop_vpu_specVma = $urandom;
    io_enq_0_bits_uop_vpu_specVta = $urandom;
    io_enq_0_bits_uop_vpu_specVsew = $urandom;
    io_enq_0_bits_uop_vpu_specVlmul = $urandom;
    io_enq_0_bits_uop_vpu_vm = $urandom;
    io_enq_0_bits_uop_vpu_vstart = $urandom;
    io_enq_0_bits_uop_vpu_frm = $urandom;
    io_enq_0_bits_uop_vpu_fpu_isFpToVecInst = $urandom;
    io_enq_0_bits_uop_vpu_fpu_isFP32Instr = $urandom;
    io_enq_0_bits_uop_vpu_fpu_isFP64Instr = $urandom;
    io_enq_0_bits_uop_vpu_fpu_isReduction = $urandom;
    io_enq_0_bits_uop_vpu_fpu_isFoldTo1_2 = $urandom;
    io_enq_0_bits_uop_vpu_fpu_isFoldTo1_4 = $urandom;
    io_enq_0_bits_uop_vpu_fpu_isFoldTo1_8 = $urandom;
    io_enq_0_bits_uop_vpu_vxrm = $urandom;
    io_enq_0_bits_uop_vpu_vuopIdx = $urandom;
    io_enq_0_bits_uop_vpu_lastUop = $urandom;
    io_enq_0_bits_uop_vpu_vmask = {$urandom, $urandom, $urandom, $urandom};
    io_enq_0_bits_uop_vpu_vl = $urandom;
    io_enq_0_bits_uop_vpu_nf = $urandom;
    io_enq_0_bits_uop_vpu_veew = $urandom;
    io_enq_0_bits_uop_vpu_isReverse = $urandom;
    io_enq_0_bits_uop_vpu_isExt = $urandom;
    io_enq_0_bits_uop_vpu_isNarrow = $urandom;
    io_enq_0_bits_uop_vpu_isDstMask = $urandom;
    io_enq_0_bits_uop_vpu_isOpMask = $urandom;
    io_enq_0_bits_uop_vpu_isMove = $urandom;
    io_enq_0_bits_uop_vpu_isDependOldVd = $urandom;
    io_enq_0_bits_uop_vpu_isWritePartVd = $urandom;
    io_enq_0_bits_uop_vpu_isVleff = $urandom;
    io_enq_0_bits_uop_vlsInstr = $urandom;
    io_enq_0_bits_uop_wfflags = $urandom;
    io_enq_0_bits_uop_isMove = $urandom;
    io_enq_0_bits_uop_isDropAmocasSta = $urandom;
    io_enq_0_bits_uop_isVset = $urandom;
    io_enq_0_bits_uop_firstUop = $urandom;
    io_enq_0_bits_uop_lastUop = $urandom;
    io_enq_0_bits_uop_numUops = $urandom;
    io_enq_0_bits_uop_numWB = $urandom;
    io_enq_0_bits_uop_commitType = $urandom;
    io_enq_0_bits_uop_srcState_0 = $urandom;
    io_enq_0_bits_uop_srcState_1 = $urandom;
    io_enq_0_bits_uop_srcState_2 = $urandom;
    io_enq_0_bits_uop_srcState_3 = $urandom;
    io_enq_0_bits_uop_srcState_4 = $urandom;
    io_enq_0_bits_uop_srcLoadDependency_0_0 = $urandom;
    io_enq_0_bits_uop_srcLoadDependency_0_1 = $urandom;
    io_enq_0_bits_uop_srcLoadDependency_0_2 = $urandom;
    io_enq_0_bits_uop_srcLoadDependency_1_0 = $urandom;
    io_enq_0_bits_uop_srcLoadDependency_1_1 = $urandom;
    io_enq_0_bits_uop_srcLoadDependency_1_2 = $urandom;
    io_enq_0_bits_uop_srcLoadDependency_2_0 = $urandom;
    io_enq_0_bits_uop_srcLoadDependency_2_1 = $urandom;
    io_enq_0_bits_uop_srcLoadDependency_2_2 = $urandom;
    io_enq_0_bits_uop_srcLoadDependency_3_0 = $urandom;
    io_enq_0_bits_uop_srcLoadDependency_3_1 = $urandom;
    io_enq_0_bits_uop_srcLoadDependency_3_2 = $urandom;
    io_enq_0_bits_uop_srcLoadDependency_4_0 = $urandom;
    io_enq_0_bits_uop_srcLoadDependency_4_1 = $urandom;
    io_enq_0_bits_uop_srcLoadDependency_4_2 = $urandom;
    io_enq_0_bits_uop_psrc_0 = $urandom;
    io_enq_0_bits_uop_psrc_1 = $urandom;
    io_enq_0_bits_uop_psrc_2 = $urandom;
    io_enq_0_bits_uop_psrc_3 = $urandom;
    io_enq_0_bits_uop_psrc_4 = $urandom;
    io_enq_0_bits_uop_pdest = $urandom;
    io_enq_0_bits_uop_useRegCache_0 = $urandom;
    io_enq_0_bits_uop_useRegCache_1 = $urandom;
    io_enq_0_bits_uop_regCacheIdx_0 = $urandom;
    io_enq_0_bits_uop_regCacheIdx_1 = $urandom;
    io_enq_0_bits_uop_instrSize = $urandom;
    io_enq_0_bits_uop_dirtyFs = $urandom;
    io_enq_0_bits_uop_dirtyVs = $urandom;
    io_enq_0_bits_uop_traceBlockInPipe_itype = $urandom;
    io_enq_0_bits_uop_traceBlockInPipe_iretire = $urandom;
    io_enq_0_bits_uop_traceBlockInPipe_ilastsize = $urandom;
    io_enq_0_bits_uop_eliminatedMove = $urandom;
    io_enq_0_bits_uop_snapshot = $urandom;
    io_enq_0_bits_uop_debugInfo_eliminatedMove = $urandom;
    io_enq_0_bits_uop_debugInfo_renameTime = {$urandom, $urandom};
    io_enq_0_bits_uop_debugInfo_dispatchTime = {$urandom, $urandom};
    io_enq_0_bits_uop_debugInfo_enqRsTime = {$urandom, $urandom};
    io_enq_0_bits_uop_debugInfo_selectTime = {$urandom, $urandom};
    io_enq_0_bits_uop_debugInfo_issueTime = {$urandom, $urandom};
    io_enq_0_bits_uop_debugInfo_writebackTime = {$urandom, $urandom};
    io_enq_0_bits_uop_debugInfo_runahead_checkpoint_id = {$urandom, $urandom};
    io_enq_0_bits_uop_debugInfo_tlbFirstReqTime = {$urandom, $urandom};
    io_enq_0_bits_uop_debugInfo_tlbRespTime = {$urandom, $urandom};
    io_enq_0_bits_uop_debug_seqNum_seqNum = {$urandom, $urandom};
    io_enq_0_bits_uop_debug_seqNum_uopIdx = $urandom;
    io_enq_0_bits_uop_storeSetHit = $urandom;
    io_enq_0_bits_uop_waitForRobIdx_flag = $urandom;
    io_enq_0_bits_uop_waitForRobIdx_value = $urandom;
    io_enq_0_bits_uop_loadWaitBit = $urandom;
    io_enq_0_bits_uop_ssid = $urandom;
    io_enq_0_bits_uop_singleStep = $urandom;
    io_enq_0_bits_uop_debug_fuType = {$urandom, $urandom};
    io_enq_0_bits_uop_debug_sim_trig = $urandom;
    io_enq_0_bits_uop_numLsElem = $urandom;
    io_enq_0_bits_mask = $urandom;
    io_enq_0_bits_isvec = $urandom;
    io_enq_0_bits_is128bit = $urandom;
    io_enq_0_bits_elemIdx = $urandom;
    io_enq_0_bits_alignedType = $urandom;
    io_enq_0_bits_mbIndex = $urandom;
    io_enq_0_bits_reg_offset = $urandom;
    io_enq_0_bits_elemIdxInsideVd = $urandom;
    io_enq_0_bits_vecActive = $urandom;
    io_enq_1_bits_uop_instr = $urandom;
    io_enq_1_bits_uop_pc = {$urandom, $urandom};
    io_enq_1_bits_uop_foldpc = $urandom;
    io_enq_1_bits_uop_exceptionVec_0 = $urandom;
    io_enq_1_bits_uop_exceptionVec_1 = $urandom;
    io_enq_1_bits_uop_exceptionVec_2 = $urandom;
    io_enq_1_bits_uop_exceptionVec_3 = $urandom;
    io_enq_1_bits_uop_exceptionVec_5 = $urandom;
    io_enq_1_bits_uop_exceptionVec_6 = $urandom;
    io_enq_1_bits_uop_exceptionVec_7 = $urandom;
    io_enq_1_bits_uop_exceptionVec_8 = $urandom;
    io_enq_1_bits_uop_exceptionVec_9 = $urandom;
    io_enq_1_bits_uop_exceptionVec_10 = $urandom;
    io_enq_1_bits_uop_exceptionVec_11 = $urandom;
    io_enq_1_bits_uop_exceptionVec_12 = $urandom;
    io_enq_1_bits_uop_exceptionVec_13 = $urandom;
    io_enq_1_bits_uop_exceptionVec_14 = $urandom;
    io_enq_1_bits_uop_exceptionVec_15 = $urandom;
    io_enq_1_bits_uop_exceptionVec_16 = $urandom;
    io_enq_1_bits_uop_exceptionVec_17 = $urandom;
    io_enq_1_bits_uop_exceptionVec_18 = $urandom;
    io_enq_1_bits_uop_exceptionVec_19 = $urandom;
    io_enq_1_bits_uop_exceptionVec_20 = $urandom;
    io_enq_1_bits_uop_exceptionVec_21 = $urandom;
    io_enq_1_bits_uop_exceptionVec_22 = $urandom;
    io_enq_1_bits_uop_exceptionVec_23 = $urandom;
    io_enq_1_bits_uop_isFetchMalAddr = $urandom;
    io_enq_1_bits_uop_hasException = $urandom;
    io_enq_1_bits_uop_trigger = $urandom;
    io_enq_1_bits_uop_preDecodeInfo_valid = $urandom;
    io_enq_1_bits_uop_preDecodeInfo_isRVC = $urandom;
    io_enq_1_bits_uop_preDecodeInfo_brType = $urandom;
    io_enq_1_bits_uop_preDecodeInfo_isCall = $urandom;
    io_enq_1_bits_uop_preDecodeInfo_isRet = $urandom;
    io_enq_1_bits_uop_pred_taken = $urandom;
    io_enq_1_bits_uop_crossPageIPFFix = $urandom;
    io_enq_1_bits_uop_ftqPtr_flag = $urandom;
    io_enq_1_bits_uop_ftqPtr_value = $urandom;
    io_enq_1_bits_uop_ftqOffset = $urandom;
    io_enq_1_bits_uop_satpFlushFirstFetchFault = $urandom;
    io_enq_1_bits_uop_srcType_0 = $urandom;
    io_enq_1_bits_uop_srcType_1 = $urandom;
    io_enq_1_bits_uop_srcType_2 = $urandom;
    io_enq_1_bits_uop_srcType_3 = $urandom;
    io_enq_1_bits_uop_srcType_4 = $urandom;
    io_enq_1_bits_uop_ldest = $urandom;
    io_enq_1_bits_uop_fuType = {$urandom, $urandom};
    io_enq_1_bits_uop_fuOpType = $urandom;
    io_enq_1_bits_uop_rfWen = $urandom;
    io_enq_1_bits_uop_fpWen = $urandom;
    io_enq_1_bits_uop_vecWen = $urandom;
    io_enq_1_bits_uop_v0Wen = $urandom;
    io_enq_1_bits_uop_vlWen = $urandom;
    io_enq_1_bits_uop_isXSTrap = $urandom;
    io_enq_1_bits_uop_waitForward = $urandom;
    io_enq_1_bits_uop_blockBackward = $urandom;
    io_enq_1_bits_uop_canRobCompress = $urandom;
    io_enq_1_bits_uop_selImm = $urandom;
    io_enq_1_bits_uop_imm = $urandom;
    io_enq_1_bits_uop_fpu_typeTagOut = $urandom;
    io_enq_1_bits_uop_fpu_wflags = $urandom;
    io_enq_1_bits_uop_fpu_typ = $urandom;
    io_enq_1_bits_uop_fpu_fmt = $urandom;
    io_enq_1_bits_uop_fpu_rm = $urandom;
    io_enq_1_bits_uop_vpu_vill = $urandom;
    io_enq_1_bits_uop_vpu_vma = $urandom;
    io_enq_1_bits_uop_vpu_vta = $urandom;
    io_enq_1_bits_uop_vpu_vsew = $urandom;
    io_enq_1_bits_uop_vpu_vlmul = $urandom;
    io_enq_1_bits_uop_vpu_specVill = $urandom;
    io_enq_1_bits_uop_vpu_specVma = $urandom;
    io_enq_1_bits_uop_vpu_specVta = $urandom;
    io_enq_1_bits_uop_vpu_specVsew = $urandom;
    io_enq_1_bits_uop_vpu_specVlmul = $urandom;
    io_enq_1_bits_uop_vpu_vm = $urandom;
    io_enq_1_bits_uop_vpu_vstart = $urandom;
    io_enq_1_bits_uop_vpu_frm = $urandom;
    io_enq_1_bits_uop_vpu_fpu_isFpToVecInst = $urandom;
    io_enq_1_bits_uop_vpu_fpu_isFP32Instr = $urandom;
    io_enq_1_bits_uop_vpu_fpu_isFP64Instr = $urandom;
    io_enq_1_bits_uop_vpu_fpu_isReduction = $urandom;
    io_enq_1_bits_uop_vpu_fpu_isFoldTo1_2 = $urandom;
    io_enq_1_bits_uop_vpu_fpu_isFoldTo1_4 = $urandom;
    io_enq_1_bits_uop_vpu_fpu_isFoldTo1_8 = $urandom;
    io_enq_1_bits_uop_vpu_vxrm = $urandom;
    io_enq_1_bits_uop_vpu_vuopIdx = $urandom;
    io_enq_1_bits_uop_vpu_lastUop = $urandom;
    io_enq_1_bits_uop_vpu_vmask = {$urandom, $urandom, $urandom, $urandom};
    io_enq_1_bits_uop_vpu_vl = $urandom;
    io_enq_1_bits_uop_vpu_nf = $urandom;
    io_enq_1_bits_uop_vpu_veew = $urandom;
    io_enq_1_bits_uop_vpu_isReverse = $urandom;
    io_enq_1_bits_uop_vpu_isExt = $urandom;
    io_enq_1_bits_uop_vpu_isNarrow = $urandom;
    io_enq_1_bits_uop_vpu_isDstMask = $urandom;
    io_enq_1_bits_uop_vpu_isOpMask = $urandom;
    io_enq_1_bits_uop_vpu_isMove = $urandom;
    io_enq_1_bits_uop_vpu_isDependOldVd = $urandom;
    io_enq_1_bits_uop_vpu_isWritePartVd = $urandom;
    io_enq_1_bits_uop_vpu_isVleff = $urandom;
    io_enq_1_bits_uop_vlsInstr = $urandom;
    io_enq_1_bits_uop_wfflags = $urandom;
    io_enq_1_bits_uop_isMove = $urandom;
    io_enq_1_bits_uop_isDropAmocasSta = $urandom;
    io_enq_1_bits_uop_isVset = $urandom;
    io_enq_1_bits_uop_firstUop = $urandom;
    io_enq_1_bits_uop_lastUop = $urandom;
    io_enq_1_bits_uop_numUops = $urandom;
    io_enq_1_bits_uop_numWB = $urandom;
    io_enq_1_bits_uop_commitType = $urandom;
    io_enq_1_bits_uop_srcState_0 = $urandom;
    io_enq_1_bits_uop_srcState_1 = $urandom;
    io_enq_1_bits_uop_srcState_2 = $urandom;
    io_enq_1_bits_uop_srcState_3 = $urandom;
    io_enq_1_bits_uop_srcState_4 = $urandom;
    io_enq_1_bits_uop_srcLoadDependency_0_0 = $urandom;
    io_enq_1_bits_uop_srcLoadDependency_0_1 = $urandom;
    io_enq_1_bits_uop_srcLoadDependency_0_2 = $urandom;
    io_enq_1_bits_uop_srcLoadDependency_1_0 = $urandom;
    io_enq_1_bits_uop_srcLoadDependency_1_1 = $urandom;
    io_enq_1_bits_uop_srcLoadDependency_1_2 = $urandom;
    io_enq_1_bits_uop_srcLoadDependency_2_0 = $urandom;
    io_enq_1_bits_uop_srcLoadDependency_2_1 = $urandom;
    io_enq_1_bits_uop_srcLoadDependency_2_2 = $urandom;
    io_enq_1_bits_uop_srcLoadDependency_3_0 = $urandom;
    io_enq_1_bits_uop_srcLoadDependency_3_1 = $urandom;
    io_enq_1_bits_uop_srcLoadDependency_3_2 = $urandom;
    io_enq_1_bits_uop_srcLoadDependency_4_0 = $urandom;
    io_enq_1_bits_uop_srcLoadDependency_4_1 = $urandom;
    io_enq_1_bits_uop_srcLoadDependency_4_2 = $urandom;
    io_enq_1_bits_uop_psrc_0 = $urandom;
    io_enq_1_bits_uop_psrc_1 = $urandom;
    io_enq_1_bits_uop_psrc_2 = $urandom;
    io_enq_1_bits_uop_psrc_3 = $urandom;
    io_enq_1_bits_uop_psrc_4 = $urandom;
    io_enq_1_bits_uop_pdest = $urandom;
    io_enq_1_bits_uop_useRegCache_0 = $urandom;
    io_enq_1_bits_uop_useRegCache_1 = $urandom;
    io_enq_1_bits_uop_regCacheIdx_0 = $urandom;
    io_enq_1_bits_uop_regCacheIdx_1 = $urandom;
    io_enq_1_bits_uop_instrSize = $urandom;
    io_enq_1_bits_uop_dirtyFs = $urandom;
    io_enq_1_bits_uop_dirtyVs = $urandom;
    io_enq_1_bits_uop_traceBlockInPipe_itype = $urandom;
    io_enq_1_bits_uop_traceBlockInPipe_iretire = $urandom;
    io_enq_1_bits_uop_traceBlockInPipe_ilastsize = $urandom;
    io_enq_1_bits_uop_eliminatedMove = $urandom;
    io_enq_1_bits_uop_snapshot = $urandom;
    io_enq_1_bits_uop_debugInfo_eliminatedMove = $urandom;
    io_enq_1_bits_uop_debugInfo_renameTime = {$urandom, $urandom};
    io_enq_1_bits_uop_debugInfo_dispatchTime = {$urandom, $urandom};
    io_enq_1_bits_uop_debugInfo_enqRsTime = {$urandom, $urandom};
    io_enq_1_bits_uop_debugInfo_selectTime = {$urandom, $urandom};
    io_enq_1_bits_uop_debugInfo_issueTime = {$urandom, $urandom};
    io_enq_1_bits_uop_debugInfo_writebackTime = {$urandom, $urandom};
    io_enq_1_bits_uop_debugInfo_runahead_checkpoint_id = {$urandom, $urandom};
    io_enq_1_bits_uop_debugInfo_tlbFirstReqTime = {$urandom, $urandom};
    io_enq_1_bits_uop_debugInfo_tlbRespTime = {$urandom, $urandom};
    io_enq_1_bits_uop_debug_seqNum_seqNum = {$urandom, $urandom};
    io_enq_1_bits_uop_debug_seqNum_uopIdx = $urandom;
    io_enq_1_bits_uop_storeSetHit = $urandom;
    io_enq_1_bits_uop_waitForRobIdx_flag = $urandom;
    io_enq_1_bits_uop_waitForRobIdx_value = $urandom;
    io_enq_1_bits_uop_loadWaitBit = $urandom;
    io_enq_1_bits_uop_ssid = $urandom;
    io_enq_1_bits_uop_singleStep = $urandom;
    io_enq_1_bits_uop_debug_fuType = {$urandom, $urandom};
    io_enq_1_bits_uop_debug_sim_trig = $urandom;
    io_enq_1_bits_uop_numLsElem = $urandom;
    io_enq_1_bits_mask = $urandom;
    io_enq_1_bits_isvec = $urandom;
    io_enq_1_bits_is128bit = $urandom;
    io_enq_1_bits_elemIdx = $urandom;
    io_enq_1_bits_alignedType = $urandom;
    io_enq_1_bits_mbIndex = $urandom;
    io_enq_1_bits_reg_offset = $urandom;
    io_enq_1_bits_elemIdxInsideVd = $urandom;
    io_enq_1_bits_vecActive = $urandom;
    io_enq_2_bits_uop_instr = $urandom;
    io_enq_2_bits_uop_pc = {$urandom, $urandom};
    io_enq_2_bits_uop_foldpc = $urandom;
    io_enq_2_bits_uop_exceptionVec_0 = $urandom;
    io_enq_2_bits_uop_exceptionVec_1 = $urandom;
    io_enq_2_bits_uop_exceptionVec_2 = $urandom;
    io_enq_2_bits_uop_exceptionVec_3 = $urandom;
    io_enq_2_bits_uop_exceptionVec_5 = $urandom;
    io_enq_2_bits_uop_exceptionVec_6 = $urandom;
    io_enq_2_bits_uop_exceptionVec_7 = $urandom;
    io_enq_2_bits_uop_exceptionVec_8 = $urandom;
    io_enq_2_bits_uop_exceptionVec_9 = $urandom;
    io_enq_2_bits_uop_exceptionVec_10 = $urandom;
    io_enq_2_bits_uop_exceptionVec_11 = $urandom;
    io_enq_2_bits_uop_exceptionVec_12 = $urandom;
    io_enq_2_bits_uop_exceptionVec_13 = $urandom;
    io_enq_2_bits_uop_exceptionVec_14 = $urandom;
    io_enq_2_bits_uop_exceptionVec_15 = $urandom;
    io_enq_2_bits_uop_exceptionVec_16 = $urandom;
    io_enq_2_bits_uop_exceptionVec_17 = $urandom;
    io_enq_2_bits_uop_exceptionVec_18 = $urandom;
    io_enq_2_bits_uop_exceptionVec_19 = $urandom;
    io_enq_2_bits_uop_exceptionVec_20 = $urandom;
    io_enq_2_bits_uop_exceptionVec_21 = $urandom;
    io_enq_2_bits_uop_exceptionVec_22 = $urandom;
    io_enq_2_bits_uop_exceptionVec_23 = $urandom;
    io_enq_2_bits_uop_isFetchMalAddr = $urandom;
    io_enq_2_bits_uop_hasException = $urandom;
    io_enq_2_bits_uop_trigger = $urandom;
    io_enq_2_bits_uop_preDecodeInfo_valid = $urandom;
    io_enq_2_bits_uop_preDecodeInfo_isRVC = $urandom;
    io_enq_2_bits_uop_preDecodeInfo_brType = $urandom;
    io_enq_2_bits_uop_preDecodeInfo_isCall = $urandom;
    io_enq_2_bits_uop_preDecodeInfo_isRet = $urandom;
    io_enq_2_bits_uop_pred_taken = $urandom;
    io_enq_2_bits_uop_crossPageIPFFix = $urandom;
    io_enq_2_bits_uop_ftqPtr_flag = $urandom;
    io_enq_2_bits_uop_ftqPtr_value = $urandom;
    io_enq_2_bits_uop_ftqOffset = $urandom;
    io_enq_2_bits_uop_satpFlushFirstFetchFault = $urandom;
    io_enq_2_bits_uop_srcType_0 = $urandom;
    io_enq_2_bits_uop_srcType_1 = $urandom;
    io_enq_2_bits_uop_srcType_2 = $urandom;
    io_enq_2_bits_uop_srcType_3 = $urandom;
    io_enq_2_bits_uop_srcType_4 = $urandom;
    io_enq_2_bits_uop_ldest = $urandom;
    io_enq_2_bits_uop_fuType = {$urandom, $urandom};
    io_enq_2_bits_uop_fuOpType = $urandom;
    io_enq_2_bits_uop_rfWen = $urandom;
    io_enq_2_bits_uop_fpWen = $urandom;
    io_enq_2_bits_uop_vecWen = $urandom;
    io_enq_2_bits_uop_v0Wen = $urandom;
    io_enq_2_bits_uop_vlWen = $urandom;
    io_enq_2_bits_uop_isXSTrap = $urandom;
    io_enq_2_bits_uop_waitForward = $urandom;
    io_enq_2_bits_uop_blockBackward = $urandom;
    io_enq_2_bits_uop_canRobCompress = $urandom;
    io_enq_2_bits_uop_selImm = $urandom;
    io_enq_2_bits_uop_imm = $urandom;
    io_enq_2_bits_uop_fpu_typeTagOut = $urandom;
    io_enq_2_bits_uop_fpu_wflags = $urandom;
    io_enq_2_bits_uop_fpu_typ = $urandom;
    io_enq_2_bits_uop_fpu_fmt = $urandom;
    io_enq_2_bits_uop_fpu_rm = $urandom;
    io_enq_2_bits_uop_vpu_vill = $urandom;
    io_enq_2_bits_uop_vpu_vma = $urandom;
    io_enq_2_bits_uop_vpu_vta = $urandom;
    io_enq_2_bits_uop_vpu_vsew = $urandom;
    io_enq_2_bits_uop_vpu_vlmul = $urandom;
    io_enq_2_bits_uop_vpu_specVill = $urandom;
    io_enq_2_bits_uop_vpu_specVma = $urandom;
    io_enq_2_bits_uop_vpu_specVta = $urandom;
    io_enq_2_bits_uop_vpu_specVsew = $urandom;
    io_enq_2_bits_uop_vpu_specVlmul = $urandom;
    io_enq_2_bits_uop_vpu_vm = $urandom;
    io_enq_2_bits_uop_vpu_vstart = $urandom;
    io_enq_2_bits_uop_vpu_frm = $urandom;
    io_enq_2_bits_uop_vpu_fpu_isFpToVecInst = $urandom;
    io_enq_2_bits_uop_vpu_fpu_isFP32Instr = $urandom;
    io_enq_2_bits_uop_vpu_fpu_isFP64Instr = $urandom;
    io_enq_2_bits_uop_vpu_fpu_isReduction = $urandom;
    io_enq_2_bits_uop_vpu_fpu_isFoldTo1_2 = $urandom;
    io_enq_2_bits_uop_vpu_fpu_isFoldTo1_4 = $urandom;
    io_enq_2_bits_uop_vpu_fpu_isFoldTo1_8 = $urandom;
    io_enq_2_bits_uop_vpu_vxrm = $urandom;
    io_enq_2_bits_uop_vpu_vuopIdx = $urandom;
    io_enq_2_bits_uop_vpu_lastUop = $urandom;
    io_enq_2_bits_uop_vpu_vmask = {$urandom, $urandom, $urandom, $urandom};
    io_enq_2_bits_uop_vpu_vl = $urandom;
    io_enq_2_bits_uop_vpu_nf = $urandom;
    io_enq_2_bits_uop_vpu_veew = $urandom;
    io_enq_2_bits_uop_vpu_isReverse = $urandom;
    io_enq_2_bits_uop_vpu_isExt = $urandom;
    io_enq_2_bits_uop_vpu_isNarrow = $urandom;
    io_enq_2_bits_uop_vpu_isDstMask = $urandom;
    io_enq_2_bits_uop_vpu_isOpMask = $urandom;
    io_enq_2_bits_uop_vpu_isMove = $urandom;
    io_enq_2_bits_uop_vpu_isDependOldVd = $urandom;
    io_enq_2_bits_uop_vpu_isWritePartVd = $urandom;
    io_enq_2_bits_uop_vpu_isVleff = $urandom;
    io_enq_2_bits_uop_vlsInstr = $urandom;
    io_enq_2_bits_uop_wfflags = $urandom;
    io_enq_2_bits_uop_isMove = $urandom;
    io_enq_2_bits_uop_isDropAmocasSta = $urandom;
    io_enq_2_bits_uop_isVset = $urandom;
    io_enq_2_bits_uop_firstUop = $urandom;
    io_enq_2_bits_uop_lastUop = $urandom;
    io_enq_2_bits_uop_numUops = $urandom;
    io_enq_2_bits_uop_numWB = $urandom;
    io_enq_2_bits_uop_commitType = $urandom;
    io_enq_2_bits_uop_srcState_0 = $urandom;
    io_enq_2_bits_uop_srcState_1 = $urandom;
    io_enq_2_bits_uop_srcState_2 = $urandom;
    io_enq_2_bits_uop_srcState_3 = $urandom;
    io_enq_2_bits_uop_srcState_4 = $urandom;
    io_enq_2_bits_uop_srcLoadDependency_0_0 = $urandom;
    io_enq_2_bits_uop_srcLoadDependency_0_1 = $urandom;
    io_enq_2_bits_uop_srcLoadDependency_0_2 = $urandom;
    io_enq_2_bits_uop_srcLoadDependency_1_0 = $urandom;
    io_enq_2_bits_uop_srcLoadDependency_1_1 = $urandom;
    io_enq_2_bits_uop_srcLoadDependency_1_2 = $urandom;
    io_enq_2_bits_uop_srcLoadDependency_2_0 = $urandom;
    io_enq_2_bits_uop_srcLoadDependency_2_1 = $urandom;
    io_enq_2_bits_uop_srcLoadDependency_2_2 = $urandom;
    io_enq_2_bits_uop_srcLoadDependency_3_0 = $urandom;
    io_enq_2_bits_uop_srcLoadDependency_3_1 = $urandom;
    io_enq_2_bits_uop_srcLoadDependency_3_2 = $urandom;
    io_enq_2_bits_uop_srcLoadDependency_4_0 = $urandom;
    io_enq_2_bits_uop_srcLoadDependency_4_1 = $urandom;
    io_enq_2_bits_uop_srcLoadDependency_4_2 = $urandom;
    io_enq_2_bits_uop_psrc_0 = $urandom;
    io_enq_2_bits_uop_psrc_1 = $urandom;
    io_enq_2_bits_uop_psrc_2 = $urandom;
    io_enq_2_bits_uop_psrc_3 = $urandom;
    io_enq_2_bits_uop_psrc_4 = $urandom;
    io_enq_2_bits_uop_pdest = $urandom;
    io_enq_2_bits_uop_useRegCache_0 = $urandom;
    io_enq_2_bits_uop_useRegCache_1 = $urandom;
    io_enq_2_bits_uop_regCacheIdx_0 = $urandom;
    io_enq_2_bits_uop_regCacheIdx_1 = $urandom;
    io_enq_2_bits_uop_instrSize = $urandom;
    io_enq_2_bits_uop_dirtyFs = $urandom;
    io_enq_2_bits_uop_dirtyVs = $urandom;
    io_enq_2_bits_uop_traceBlockInPipe_itype = $urandom;
    io_enq_2_bits_uop_traceBlockInPipe_iretire = $urandom;
    io_enq_2_bits_uop_traceBlockInPipe_ilastsize = $urandom;
    io_enq_2_bits_uop_eliminatedMove = $urandom;
    io_enq_2_bits_uop_snapshot = $urandom;
    io_enq_2_bits_uop_debugInfo_eliminatedMove = $urandom;
    io_enq_2_bits_uop_debugInfo_renameTime = {$urandom, $urandom};
    io_enq_2_bits_uop_debugInfo_dispatchTime = {$urandom, $urandom};
    io_enq_2_bits_uop_debugInfo_enqRsTime = {$urandom, $urandom};
    io_enq_2_bits_uop_debugInfo_selectTime = {$urandom, $urandom};
    io_enq_2_bits_uop_debugInfo_issueTime = {$urandom, $urandom};
    io_enq_2_bits_uop_debugInfo_writebackTime = {$urandom, $urandom};
    io_enq_2_bits_uop_debugInfo_runahead_checkpoint_id = {$urandom, $urandom};
    io_enq_2_bits_uop_debugInfo_tlbFirstReqTime = {$urandom, $urandom};
    io_enq_2_bits_uop_debugInfo_tlbRespTime = {$urandom, $urandom};
    io_enq_2_bits_uop_debug_seqNum_seqNum = {$urandom, $urandom};
    io_enq_2_bits_uop_debug_seqNum_uopIdx = $urandom;
    io_enq_2_bits_uop_storeSetHit = $urandom;
    io_enq_2_bits_uop_waitForRobIdx_flag = $urandom;
    io_enq_2_bits_uop_waitForRobIdx_value = $urandom;
    io_enq_2_bits_uop_loadWaitBit = $urandom;
    io_enq_2_bits_uop_ssid = $urandom;
    io_enq_2_bits_uop_singleStep = $urandom;
    io_enq_2_bits_uop_debug_fuType = {$urandom, $urandom};
    io_enq_2_bits_uop_debug_sim_trig = $urandom;
    io_enq_2_bits_uop_numLsElem = $urandom;
    io_enq_2_bits_mask = $urandom;
    io_enq_2_bits_isvec = $urandom;
    io_enq_2_bits_is128bit = $urandom;
    io_enq_2_bits_elemIdx = $urandom;
    io_enq_2_bits_alignedType = $urandom;
    io_enq_2_bits_mbIndex = $urandom;
    io_enq_2_bits_reg_offset = $urandom;
    io_enq_2_bits_elemIdxInsideVd = $urandom;
    io_enq_2_bits_vecActive = $urandom;
  endtask

  // ---- 逐拍比对全部输出 ----
  task automatic check_outputs();
    if (g_io_replay_0_valid !== i_io_replay_0_valid) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_valid: g=%h i=%h", cyc, g_io_replay_0_valid, i_io_replay_0_valid); end
    checks++;
    if (g_io_replay_0_bits_uop_instr !== i_io_replay_0_bits_uop_instr) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_instr: g=%h i=%h", cyc, g_io_replay_0_bits_uop_instr, i_io_replay_0_bits_uop_instr); end
    checks++;
    if (g_io_replay_0_bits_uop_pc !== i_io_replay_0_bits_uop_pc) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_pc: g=%h i=%h", cyc, g_io_replay_0_bits_uop_pc, i_io_replay_0_bits_uop_pc); end
    checks++;
    if (g_io_replay_0_bits_uop_foldpc !== i_io_replay_0_bits_uop_foldpc) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_foldpc: g=%h i=%h", cyc, g_io_replay_0_bits_uop_foldpc, i_io_replay_0_bits_uop_foldpc); end
    checks++;
    if (g_io_replay_0_bits_uop_exceptionVec_0 !== i_io_replay_0_bits_uop_exceptionVec_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_exceptionVec_0: g=%h i=%h", cyc, g_io_replay_0_bits_uop_exceptionVec_0, i_io_replay_0_bits_uop_exceptionVec_0); end
    checks++;
    if (g_io_replay_0_bits_uop_exceptionVec_1 !== i_io_replay_0_bits_uop_exceptionVec_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_exceptionVec_1: g=%h i=%h", cyc, g_io_replay_0_bits_uop_exceptionVec_1, i_io_replay_0_bits_uop_exceptionVec_1); end
    checks++;
    if (g_io_replay_0_bits_uop_exceptionVec_2 !== i_io_replay_0_bits_uop_exceptionVec_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_exceptionVec_2: g=%h i=%h", cyc, g_io_replay_0_bits_uop_exceptionVec_2, i_io_replay_0_bits_uop_exceptionVec_2); end
    checks++;
    if (g_io_replay_0_bits_uop_exceptionVec_3 !== i_io_replay_0_bits_uop_exceptionVec_3) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_exceptionVec_3: g=%h i=%h", cyc, g_io_replay_0_bits_uop_exceptionVec_3, i_io_replay_0_bits_uop_exceptionVec_3); end
    checks++;
    if (g_io_replay_0_bits_uop_exceptionVec_5 !== i_io_replay_0_bits_uop_exceptionVec_5) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_exceptionVec_5: g=%h i=%h", cyc, g_io_replay_0_bits_uop_exceptionVec_5, i_io_replay_0_bits_uop_exceptionVec_5); end
    checks++;
    if (g_io_replay_0_bits_uop_exceptionVec_6 !== i_io_replay_0_bits_uop_exceptionVec_6) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_exceptionVec_6: g=%h i=%h", cyc, g_io_replay_0_bits_uop_exceptionVec_6, i_io_replay_0_bits_uop_exceptionVec_6); end
    checks++;
    if (g_io_replay_0_bits_uop_exceptionVec_7 !== i_io_replay_0_bits_uop_exceptionVec_7) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_exceptionVec_7: g=%h i=%h", cyc, g_io_replay_0_bits_uop_exceptionVec_7, i_io_replay_0_bits_uop_exceptionVec_7); end
    checks++;
    if (g_io_replay_0_bits_uop_exceptionVec_8 !== i_io_replay_0_bits_uop_exceptionVec_8) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_exceptionVec_8: g=%h i=%h", cyc, g_io_replay_0_bits_uop_exceptionVec_8, i_io_replay_0_bits_uop_exceptionVec_8); end
    checks++;
    if (g_io_replay_0_bits_uop_exceptionVec_9 !== i_io_replay_0_bits_uop_exceptionVec_9) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_exceptionVec_9: g=%h i=%h", cyc, g_io_replay_0_bits_uop_exceptionVec_9, i_io_replay_0_bits_uop_exceptionVec_9); end
    checks++;
    if (g_io_replay_0_bits_uop_exceptionVec_10 !== i_io_replay_0_bits_uop_exceptionVec_10) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_exceptionVec_10: g=%h i=%h", cyc, g_io_replay_0_bits_uop_exceptionVec_10, i_io_replay_0_bits_uop_exceptionVec_10); end
    checks++;
    if (g_io_replay_0_bits_uop_exceptionVec_11 !== i_io_replay_0_bits_uop_exceptionVec_11) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_exceptionVec_11: g=%h i=%h", cyc, g_io_replay_0_bits_uop_exceptionVec_11, i_io_replay_0_bits_uop_exceptionVec_11); end
    checks++;
    if (g_io_replay_0_bits_uop_exceptionVec_12 !== i_io_replay_0_bits_uop_exceptionVec_12) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_exceptionVec_12: g=%h i=%h", cyc, g_io_replay_0_bits_uop_exceptionVec_12, i_io_replay_0_bits_uop_exceptionVec_12); end
    checks++;
    if (g_io_replay_0_bits_uop_exceptionVec_13 !== i_io_replay_0_bits_uop_exceptionVec_13) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_exceptionVec_13: g=%h i=%h", cyc, g_io_replay_0_bits_uop_exceptionVec_13, i_io_replay_0_bits_uop_exceptionVec_13); end
    checks++;
    if (g_io_replay_0_bits_uop_exceptionVec_14 !== i_io_replay_0_bits_uop_exceptionVec_14) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_exceptionVec_14: g=%h i=%h", cyc, g_io_replay_0_bits_uop_exceptionVec_14, i_io_replay_0_bits_uop_exceptionVec_14); end
    checks++;
    if (g_io_replay_0_bits_uop_exceptionVec_15 !== i_io_replay_0_bits_uop_exceptionVec_15) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_exceptionVec_15: g=%h i=%h", cyc, g_io_replay_0_bits_uop_exceptionVec_15, i_io_replay_0_bits_uop_exceptionVec_15); end
    checks++;
    if (g_io_replay_0_bits_uop_exceptionVec_16 !== i_io_replay_0_bits_uop_exceptionVec_16) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_exceptionVec_16: g=%h i=%h", cyc, g_io_replay_0_bits_uop_exceptionVec_16, i_io_replay_0_bits_uop_exceptionVec_16); end
    checks++;
    if (g_io_replay_0_bits_uop_exceptionVec_17 !== i_io_replay_0_bits_uop_exceptionVec_17) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_exceptionVec_17: g=%h i=%h", cyc, g_io_replay_0_bits_uop_exceptionVec_17, i_io_replay_0_bits_uop_exceptionVec_17); end
    checks++;
    if (g_io_replay_0_bits_uop_exceptionVec_18 !== i_io_replay_0_bits_uop_exceptionVec_18) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_exceptionVec_18: g=%h i=%h", cyc, g_io_replay_0_bits_uop_exceptionVec_18, i_io_replay_0_bits_uop_exceptionVec_18); end
    checks++;
    if (g_io_replay_0_bits_uop_exceptionVec_19 !== i_io_replay_0_bits_uop_exceptionVec_19) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_exceptionVec_19: g=%h i=%h", cyc, g_io_replay_0_bits_uop_exceptionVec_19, i_io_replay_0_bits_uop_exceptionVec_19); end
    checks++;
    if (g_io_replay_0_bits_uop_exceptionVec_20 !== i_io_replay_0_bits_uop_exceptionVec_20) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_exceptionVec_20: g=%h i=%h", cyc, g_io_replay_0_bits_uop_exceptionVec_20, i_io_replay_0_bits_uop_exceptionVec_20); end
    checks++;
    if (g_io_replay_0_bits_uop_exceptionVec_21 !== i_io_replay_0_bits_uop_exceptionVec_21) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_exceptionVec_21: g=%h i=%h", cyc, g_io_replay_0_bits_uop_exceptionVec_21, i_io_replay_0_bits_uop_exceptionVec_21); end
    checks++;
    if (g_io_replay_0_bits_uop_exceptionVec_22 !== i_io_replay_0_bits_uop_exceptionVec_22) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_exceptionVec_22: g=%h i=%h", cyc, g_io_replay_0_bits_uop_exceptionVec_22, i_io_replay_0_bits_uop_exceptionVec_22); end
    checks++;
    if (g_io_replay_0_bits_uop_exceptionVec_23 !== i_io_replay_0_bits_uop_exceptionVec_23) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_exceptionVec_23: g=%h i=%h", cyc, g_io_replay_0_bits_uop_exceptionVec_23, i_io_replay_0_bits_uop_exceptionVec_23); end
    checks++;
    if (g_io_replay_0_bits_uop_isFetchMalAddr !== i_io_replay_0_bits_uop_isFetchMalAddr) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_isFetchMalAddr: g=%h i=%h", cyc, g_io_replay_0_bits_uop_isFetchMalAddr, i_io_replay_0_bits_uop_isFetchMalAddr); end
    checks++;
    if (g_io_replay_0_bits_uop_hasException !== i_io_replay_0_bits_uop_hasException) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_hasException: g=%h i=%h", cyc, g_io_replay_0_bits_uop_hasException, i_io_replay_0_bits_uop_hasException); end
    checks++;
    if (g_io_replay_0_bits_uop_trigger !== i_io_replay_0_bits_uop_trigger) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_trigger: g=%h i=%h", cyc, g_io_replay_0_bits_uop_trigger, i_io_replay_0_bits_uop_trigger); end
    checks++;
    if (g_io_replay_0_bits_uop_preDecodeInfo_valid !== i_io_replay_0_bits_uop_preDecodeInfo_valid) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_preDecodeInfo_valid: g=%h i=%h", cyc, g_io_replay_0_bits_uop_preDecodeInfo_valid, i_io_replay_0_bits_uop_preDecodeInfo_valid); end
    checks++;
    if (g_io_replay_0_bits_uop_preDecodeInfo_isRVC !== i_io_replay_0_bits_uop_preDecodeInfo_isRVC) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_preDecodeInfo_isRVC: g=%h i=%h", cyc, g_io_replay_0_bits_uop_preDecodeInfo_isRVC, i_io_replay_0_bits_uop_preDecodeInfo_isRVC); end
    checks++;
    if (g_io_replay_0_bits_uop_preDecodeInfo_brType !== i_io_replay_0_bits_uop_preDecodeInfo_brType) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_preDecodeInfo_brType: g=%h i=%h", cyc, g_io_replay_0_bits_uop_preDecodeInfo_brType, i_io_replay_0_bits_uop_preDecodeInfo_brType); end
    checks++;
    if (g_io_replay_0_bits_uop_preDecodeInfo_isCall !== i_io_replay_0_bits_uop_preDecodeInfo_isCall) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_preDecodeInfo_isCall: g=%h i=%h", cyc, g_io_replay_0_bits_uop_preDecodeInfo_isCall, i_io_replay_0_bits_uop_preDecodeInfo_isCall); end
    checks++;
    if (g_io_replay_0_bits_uop_preDecodeInfo_isRet !== i_io_replay_0_bits_uop_preDecodeInfo_isRet) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_preDecodeInfo_isRet: g=%h i=%h", cyc, g_io_replay_0_bits_uop_preDecodeInfo_isRet, i_io_replay_0_bits_uop_preDecodeInfo_isRet); end
    checks++;
    if (g_io_replay_0_bits_uop_pred_taken !== i_io_replay_0_bits_uop_pred_taken) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_pred_taken: g=%h i=%h", cyc, g_io_replay_0_bits_uop_pred_taken, i_io_replay_0_bits_uop_pred_taken); end
    checks++;
    if (g_io_replay_0_bits_uop_crossPageIPFFix !== i_io_replay_0_bits_uop_crossPageIPFFix) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_crossPageIPFFix: g=%h i=%h", cyc, g_io_replay_0_bits_uop_crossPageIPFFix, i_io_replay_0_bits_uop_crossPageIPFFix); end
    checks++;
    if (g_io_replay_0_bits_uop_ftqPtr_flag !== i_io_replay_0_bits_uop_ftqPtr_flag) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_ftqPtr_flag: g=%h i=%h", cyc, g_io_replay_0_bits_uop_ftqPtr_flag, i_io_replay_0_bits_uop_ftqPtr_flag); end
    checks++;
    if (g_io_replay_0_bits_uop_ftqPtr_value !== i_io_replay_0_bits_uop_ftqPtr_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_ftqPtr_value: g=%h i=%h", cyc, g_io_replay_0_bits_uop_ftqPtr_value, i_io_replay_0_bits_uop_ftqPtr_value); end
    checks++;
    if (g_io_replay_0_bits_uop_ftqOffset !== i_io_replay_0_bits_uop_ftqOffset) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_ftqOffset: g=%h i=%h", cyc, g_io_replay_0_bits_uop_ftqOffset, i_io_replay_0_bits_uop_ftqOffset); end
    checks++;
    if (g_io_replay_0_bits_uop_satpFlushFirstFetchFault !== i_io_replay_0_bits_uop_satpFlushFirstFetchFault) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_satpFlushFirstFetchFault: g=%h i=%h", cyc, g_io_replay_0_bits_uop_satpFlushFirstFetchFault, i_io_replay_0_bits_uop_satpFlushFirstFetchFault); end
    checks++;
    if (g_io_replay_0_bits_uop_srcType_0 !== i_io_replay_0_bits_uop_srcType_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_srcType_0: g=%h i=%h", cyc, g_io_replay_0_bits_uop_srcType_0, i_io_replay_0_bits_uop_srcType_0); end
    checks++;
    if (g_io_replay_0_bits_uop_srcType_1 !== i_io_replay_0_bits_uop_srcType_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_srcType_1: g=%h i=%h", cyc, g_io_replay_0_bits_uop_srcType_1, i_io_replay_0_bits_uop_srcType_1); end
    checks++;
    if (g_io_replay_0_bits_uop_srcType_2 !== i_io_replay_0_bits_uop_srcType_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_srcType_2: g=%h i=%h", cyc, g_io_replay_0_bits_uop_srcType_2, i_io_replay_0_bits_uop_srcType_2); end
    checks++;
    if (g_io_replay_0_bits_uop_srcType_3 !== i_io_replay_0_bits_uop_srcType_3) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_srcType_3: g=%h i=%h", cyc, g_io_replay_0_bits_uop_srcType_3, i_io_replay_0_bits_uop_srcType_3); end
    checks++;
    if (g_io_replay_0_bits_uop_srcType_4 !== i_io_replay_0_bits_uop_srcType_4) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_srcType_4: g=%h i=%h", cyc, g_io_replay_0_bits_uop_srcType_4, i_io_replay_0_bits_uop_srcType_4); end
    checks++;
    if (g_io_replay_0_bits_uop_ldest !== i_io_replay_0_bits_uop_ldest) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_ldest: g=%h i=%h", cyc, g_io_replay_0_bits_uop_ldest, i_io_replay_0_bits_uop_ldest); end
    checks++;
    if (g_io_replay_0_bits_uop_fuType !== i_io_replay_0_bits_uop_fuType) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_fuType: g=%h i=%h", cyc, g_io_replay_0_bits_uop_fuType, i_io_replay_0_bits_uop_fuType); end
    checks++;
    if (g_io_replay_0_bits_uop_fuOpType !== i_io_replay_0_bits_uop_fuOpType) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_fuOpType: g=%h i=%h", cyc, g_io_replay_0_bits_uop_fuOpType, i_io_replay_0_bits_uop_fuOpType); end
    checks++;
    if (g_io_replay_0_bits_uop_rfWen !== i_io_replay_0_bits_uop_rfWen) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_rfWen: g=%h i=%h", cyc, g_io_replay_0_bits_uop_rfWen, i_io_replay_0_bits_uop_rfWen); end
    checks++;
    if (g_io_replay_0_bits_uop_fpWen !== i_io_replay_0_bits_uop_fpWen) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_fpWen: g=%h i=%h", cyc, g_io_replay_0_bits_uop_fpWen, i_io_replay_0_bits_uop_fpWen); end
    checks++;
    if (g_io_replay_0_bits_uop_vecWen !== i_io_replay_0_bits_uop_vecWen) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vecWen: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vecWen, i_io_replay_0_bits_uop_vecWen); end
    checks++;
    if (g_io_replay_0_bits_uop_v0Wen !== i_io_replay_0_bits_uop_v0Wen) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_v0Wen: g=%h i=%h", cyc, g_io_replay_0_bits_uop_v0Wen, i_io_replay_0_bits_uop_v0Wen); end
    checks++;
    if (g_io_replay_0_bits_uop_vlWen !== i_io_replay_0_bits_uop_vlWen) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vlWen: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vlWen, i_io_replay_0_bits_uop_vlWen); end
    checks++;
    if (g_io_replay_0_bits_uop_isXSTrap !== i_io_replay_0_bits_uop_isXSTrap) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_isXSTrap: g=%h i=%h", cyc, g_io_replay_0_bits_uop_isXSTrap, i_io_replay_0_bits_uop_isXSTrap); end
    checks++;
    if (g_io_replay_0_bits_uop_waitForward !== i_io_replay_0_bits_uop_waitForward) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_waitForward: g=%h i=%h", cyc, g_io_replay_0_bits_uop_waitForward, i_io_replay_0_bits_uop_waitForward); end
    checks++;
    if (g_io_replay_0_bits_uop_blockBackward !== i_io_replay_0_bits_uop_blockBackward) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_blockBackward: g=%h i=%h", cyc, g_io_replay_0_bits_uop_blockBackward, i_io_replay_0_bits_uop_blockBackward); end
    checks++;
    if (g_io_replay_0_bits_uop_canRobCompress !== i_io_replay_0_bits_uop_canRobCompress) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_canRobCompress: g=%h i=%h", cyc, g_io_replay_0_bits_uop_canRobCompress, i_io_replay_0_bits_uop_canRobCompress); end
    checks++;
    if (g_io_replay_0_bits_uop_selImm !== i_io_replay_0_bits_uop_selImm) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_selImm: g=%h i=%h", cyc, g_io_replay_0_bits_uop_selImm, i_io_replay_0_bits_uop_selImm); end
    checks++;
    if (g_io_replay_0_bits_uop_imm !== i_io_replay_0_bits_uop_imm) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_imm: g=%h i=%h", cyc, g_io_replay_0_bits_uop_imm, i_io_replay_0_bits_uop_imm); end
    checks++;
    if (g_io_replay_0_bits_uop_fpu_typeTagOut !== i_io_replay_0_bits_uop_fpu_typeTagOut) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_fpu_typeTagOut: g=%h i=%h", cyc, g_io_replay_0_bits_uop_fpu_typeTagOut, i_io_replay_0_bits_uop_fpu_typeTagOut); end
    checks++;
    if (g_io_replay_0_bits_uop_fpu_wflags !== i_io_replay_0_bits_uop_fpu_wflags) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_fpu_wflags: g=%h i=%h", cyc, g_io_replay_0_bits_uop_fpu_wflags, i_io_replay_0_bits_uop_fpu_wflags); end
    checks++;
    if (g_io_replay_0_bits_uop_fpu_typ !== i_io_replay_0_bits_uop_fpu_typ) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_fpu_typ: g=%h i=%h", cyc, g_io_replay_0_bits_uop_fpu_typ, i_io_replay_0_bits_uop_fpu_typ); end
    checks++;
    if (g_io_replay_0_bits_uop_fpu_fmt !== i_io_replay_0_bits_uop_fpu_fmt) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_fpu_fmt: g=%h i=%h", cyc, g_io_replay_0_bits_uop_fpu_fmt, i_io_replay_0_bits_uop_fpu_fmt); end
    checks++;
    if (g_io_replay_0_bits_uop_fpu_rm !== i_io_replay_0_bits_uop_fpu_rm) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_fpu_rm: g=%h i=%h", cyc, g_io_replay_0_bits_uop_fpu_rm, i_io_replay_0_bits_uop_fpu_rm); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_vill !== i_io_replay_0_bits_uop_vpu_vill) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_vill: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_vill, i_io_replay_0_bits_uop_vpu_vill); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_vma !== i_io_replay_0_bits_uop_vpu_vma) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_vma: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_vma, i_io_replay_0_bits_uop_vpu_vma); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_vta !== i_io_replay_0_bits_uop_vpu_vta) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_vta: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_vta, i_io_replay_0_bits_uop_vpu_vta); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_vsew !== i_io_replay_0_bits_uop_vpu_vsew) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_vsew: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_vsew, i_io_replay_0_bits_uop_vpu_vsew); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_vlmul !== i_io_replay_0_bits_uop_vpu_vlmul) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_vlmul: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_vlmul, i_io_replay_0_bits_uop_vpu_vlmul); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_specVill !== i_io_replay_0_bits_uop_vpu_specVill) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_specVill: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_specVill, i_io_replay_0_bits_uop_vpu_specVill); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_specVma !== i_io_replay_0_bits_uop_vpu_specVma) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_specVma: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_specVma, i_io_replay_0_bits_uop_vpu_specVma); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_specVta !== i_io_replay_0_bits_uop_vpu_specVta) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_specVta: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_specVta, i_io_replay_0_bits_uop_vpu_specVta); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_specVsew !== i_io_replay_0_bits_uop_vpu_specVsew) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_specVsew: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_specVsew, i_io_replay_0_bits_uop_vpu_specVsew); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_specVlmul !== i_io_replay_0_bits_uop_vpu_specVlmul) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_specVlmul: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_specVlmul, i_io_replay_0_bits_uop_vpu_specVlmul); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_vm !== i_io_replay_0_bits_uop_vpu_vm) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_vm: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_vm, i_io_replay_0_bits_uop_vpu_vm); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_vstart !== i_io_replay_0_bits_uop_vpu_vstart) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_vstart: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_vstart, i_io_replay_0_bits_uop_vpu_vstart); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_frm !== i_io_replay_0_bits_uop_vpu_frm) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_frm: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_frm, i_io_replay_0_bits_uop_vpu_frm); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_fpu_isFpToVecInst !== i_io_replay_0_bits_uop_vpu_fpu_isFpToVecInst) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_fpu_isFpToVecInst: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_fpu_isFpToVecInst, i_io_replay_0_bits_uop_vpu_fpu_isFpToVecInst); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_fpu_isFP32Instr !== i_io_replay_0_bits_uop_vpu_fpu_isFP32Instr) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_fpu_isFP32Instr: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_fpu_isFP32Instr, i_io_replay_0_bits_uop_vpu_fpu_isFP32Instr); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_fpu_isFP64Instr !== i_io_replay_0_bits_uop_vpu_fpu_isFP64Instr) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_fpu_isFP64Instr: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_fpu_isFP64Instr, i_io_replay_0_bits_uop_vpu_fpu_isFP64Instr); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_fpu_isReduction !== i_io_replay_0_bits_uop_vpu_fpu_isReduction) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_fpu_isReduction: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_fpu_isReduction, i_io_replay_0_bits_uop_vpu_fpu_isReduction); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_fpu_isFoldTo1_2 !== i_io_replay_0_bits_uop_vpu_fpu_isFoldTo1_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_fpu_isFoldTo1_2: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_fpu_isFoldTo1_2, i_io_replay_0_bits_uop_vpu_fpu_isFoldTo1_2); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_fpu_isFoldTo1_4 !== i_io_replay_0_bits_uop_vpu_fpu_isFoldTo1_4) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_fpu_isFoldTo1_4: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_fpu_isFoldTo1_4, i_io_replay_0_bits_uop_vpu_fpu_isFoldTo1_4); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_fpu_isFoldTo1_8 !== i_io_replay_0_bits_uop_vpu_fpu_isFoldTo1_8) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_fpu_isFoldTo1_8: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_fpu_isFoldTo1_8, i_io_replay_0_bits_uop_vpu_fpu_isFoldTo1_8); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_vxrm !== i_io_replay_0_bits_uop_vpu_vxrm) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_vxrm: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_vxrm, i_io_replay_0_bits_uop_vpu_vxrm); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_vuopIdx !== i_io_replay_0_bits_uop_vpu_vuopIdx) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_vuopIdx: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_vuopIdx, i_io_replay_0_bits_uop_vpu_vuopIdx); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_lastUop !== i_io_replay_0_bits_uop_vpu_lastUop) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_lastUop: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_lastUop, i_io_replay_0_bits_uop_vpu_lastUop); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_vmask !== i_io_replay_0_bits_uop_vpu_vmask) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_vmask: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_vmask, i_io_replay_0_bits_uop_vpu_vmask); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_vl !== i_io_replay_0_bits_uop_vpu_vl) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_vl: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_vl, i_io_replay_0_bits_uop_vpu_vl); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_nf !== i_io_replay_0_bits_uop_vpu_nf) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_nf: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_nf, i_io_replay_0_bits_uop_vpu_nf); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_veew !== i_io_replay_0_bits_uop_vpu_veew) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_veew: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_veew, i_io_replay_0_bits_uop_vpu_veew); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_isReverse !== i_io_replay_0_bits_uop_vpu_isReverse) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_isReverse: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_isReverse, i_io_replay_0_bits_uop_vpu_isReverse); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_isExt !== i_io_replay_0_bits_uop_vpu_isExt) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_isExt: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_isExt, i_io_replay_0_bits_uop_vpu_isExt); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_isNarrow !== i_io_replay_0_bits_uop_vpu_isNarrow) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_isNarrow: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_isNarrow, i_io_replay_0_bits_uop_vpu_isNarrow); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_isDstMask !== i_io_replay_0_bits_uop_vpu_isDstMask) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_isDstMask: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_isDstMask, i_io_replay_0_bits_uop_vpu_isDstMask); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_isOpMask !== i_io_replay_0_bits_uop_vpu_isOpMask) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_isOpMask: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_isOpMask, i_io_replay_0_bits_uop_vpu_isOpMask); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_isMove !== i_io_replay_0_bits_uop_vpu_isMove) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_isMove: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_isMove, i_io_replay_0_bits_uop_vpu_isMove); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_isDependOldVd !== i_io_replay_0_bits_uop_vpu_isDependOldVd) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_isDependOldVd: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_isDependOldVd, i_io_replay_0_bits_uop_vpu_isDependOldVd); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_isWritePartVd !== i_io_replay_0_bits_uop_vpu_isWritePartVd) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_isWritePartVd: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_isWritePartVd, i_io_replay_0_bits_uop_vpu_isWritePartVd); end
    checks++;
    if (g_io_replay_0_bits_uop_vpu_isVleff !== i_io_replay_0_bits_uop_vpu_isVleff) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vpu_isVleff: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vpu_isVleff, i_io_replay_0_bits_uop_vpu_isVleff); end
    checks++;
    if (g_io_replay_0_bits_uop_vlsInstr !== i_io_replay_0_bits_uop_vlsInstr) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_vlsInstr: g=%h i=%h", cyc, g_io_replay_0_bits_uop_vlsInstr, i_io_replay_0_bits_uop_vlsInstr); end
    checks++;
    if (g_io_replay_0_bits_uop_wfflags !== i_io_replay_0_bits_uop_wfflags) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_wfflags: g=%h i=%h", cyc, g_io_replay_0_bits_uop_wfflags, i_io_replay_0_bits_uop_wfflags); end
    checks++;
    if (g_io_replay_0_bits_uop_isMove !== i_io_replay_0_bits_uop_isMove) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_isMove: g=%h i=%h", cyc, g_io_replay_0_bits_uop_isMove, i_io_replay_0_bits_uop_isMove); end
    checks++;
    if (g_io_replay_0_bits_uop_isDropAmocasSta !== i_io_replay_0_bits_uop_isDropAmocasSta) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_isDropAmocasSta: g=%h i=%h", cyc, g_io_replay_0_bits_uop_isDropAmocasSta, i_io_replay_0_bits_uop_isDropAmocasSta); end
    checks++;
    if (g_io_replay_0_bits_uop_uopIdx !== i_io_replay_0_bits_uop_uopIdx) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_uopIdx: g=%h i=%h", cyc, g_io_replay_0_bits_uop_uopIdx, i_io_replay_0_bits_uop_uopIdx); end
    checks++;
    if (g_io_replay_0_bits_uop_isVset !== i_io_replay_0_bits_uop_isVset) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_isVset: g=%h i=%h", cyc, g_io_replay_0_bits_uop_isVset, i_io_replay_0_bits_uop_isVset); end
    checks++;
    if (g_io_replay_0_bits_uop_firstUop !== i_io_replay_0_bits_uop_firstUop) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_firstUop: g=%h i=%h", cyc, g_io_replay_0_bits_uop_firstUop, i_io_replay_0_bits_uop_firstUop); end
    checks++;
    if (g_io_replay_0_bits_uop_lastUop !== i_io_replay_0_bits_uop_lastUop) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_lastUop: g=%h i=%h", cyc, g_io_replay_0_bits_uop_lastUop, i_io_replay_0_bits_uop_lastUop); end
    checks++;
    if (g_io_replay_0_bits_uop_numUops !== i_io_replay_0_bits_uop_numUops) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_numUops: g=%h i=%h", cyc, g_io_replay_0_bits_uop_numUops, i_io_replay_0_bits_uop_numUops); end
    checks++;
    if (g_io_replay_0_bits_uop_numWB !== i_io_replay_0_bits_uop_numWB) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_numWB: g=%h i=%h", cyc, g_io_replay_0_bits_uop_numWB, i_io_replay_0_bits_uop_numWB); end
    checks++;
    if (g_io_replay_0_bits_uop_commitType !== i_io_replay_0_bits_uop_commitType) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_commitType: g=%h i=%h", cyc, g_io_replay_0_bits_uop_commitType, i_io_replay_0_bits_uop_commitType); end
    checks++;
    if (g_io_replay_0_bits_uop_srcState_0 !== i_io_replay_0_bits_uop_srcState_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_srcState_0: g=%h i=%h", cyc, g_io_replay_0_bits_uop_srcState_0, i_io_replay_0_bits_uop_srcState_0); end
    checks++;
    if (g_io_replay_0_bits_uop_srcState_1 !== i_io_replay_0_bits_uop_srcState_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_srcState_1: g=%h i=%h", cyc, g_io_replay_0_bits_uop_srcState_1, i_io_replay_0_bits_uop_srcState_1); end
    checks++;
    if (g_io_replay_0_bits_uop_srcState_2 !== i_io_replay_0_bits_uop_srcState_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_srcState_2: g=%h i=%h", cyc, g_io_replay_0_bits_uop_srcState_2, i_io_replay_0_bits_uop_srcState_2); end
    checks++;
    if (g_io_replay_0_bits_uop_srcState_3 !== i_io_replay_0_bits_uop_srcState_3) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_srcState_3: g=%h i=%h", cyc, g_io_replay_0_bits_uop_srcState_3, i_io_replay_0_bits_uop_srcState_3); end
    checks++;
    if (g_io_replay_0_bits_uop_srcState_4 !== i_io_replay_0_bits_uop_srcState_4) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_srcState_4: g=%h i=%h", cyc, g_io_replay_0_bits_uop_srcState_4, i_io_replay_0_bits_uop_srcState_4); end
    checks++;
    if (g_io_replay_0_bits_uop_srcLoadDependency_0_0 !== i_io_replay_0_bits_uop_srcLoadDependency_0_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_srcLoadDependency_0_0: g=%h i=%h", cyc, g_io_replay_0_bits_uop_srcLoadDependency_0_0, i_io_replay_0_bits_uop_srcLoadDependency_0_0); end
    checks++;
    if (g_io_replay_0_bits_uop_srcLoadDependency_0_1 !== i_io_replay_0_bits_uop_srcLoadDependency_0_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_srcLoadDependency_0_1: g=%h i=%h", cyc, g_io_replay_0_bits_uop_srcLoadDependency_0_1, i_io_replay_0_bits_uop_srcLoadDependency_0_1); end
    checks++;
    if (g_io_replay_0_bits_uop_srcLoadDependency_0_2 !== i_io_replay_0_bits_uop_srcLoadDependency_0_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_srcLoadDependency_0_2: g=%h i=%h", cyc, g_io_replay_0_bits_uop_srcLoadDependency_0_2, i_io_replay_0_bits_uop_srcLoadDependency_0_2); end
    checks++;
    if (g_io_replay_0_bits_uop_srcLoadDependency_1_0 !== i_io_replay_0_bits_uop_srcLoadDependency_1_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_srcLoadDependency_1_0: g=%h i=%h", cyc, g_io_replay_0_bits_uop_srcLoadDependency_1_0, i_io_replay_0_bits_uop_srcLoadDependency_1_0); end
    checks++;
    if (g_io_replay_0_bits_uop_srcLoadDependency_1_1 !== i_io_replay_0_bits_uop_srcLoadDependency_1_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_srcLoadDependency_1_1: g=%h i=%h", cyc, g_io_replay_0_bits_uop_srcLoadDependency_1_1, i_io_replay_0_bits_uop_srcLoadDependency_1_1); end
    checks++;
    if (g_io_replay_0_bits_uop_srcLoadDependency_1_2 !== i_io_replay_0_bits_uop_srcLoadDependency_1_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_srcLoadDependency_1_2: g=%h i=%h", cyc, g_io_replay_0_bits_uop_srcLoadDependency_1_2, i_io_replay_0_bits_uop_srcLoadDependency_1_2); end
    checks++;
    if (g_io_replay_0_bits_uop_srcLoadDependency_2_0 !== i_io_replay_0_bits_uop_srcLoadDependency_2_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_srcLoadDependency_2_0: g=%h i=%h", cyc, g_io_replay_0_bits_uop_srcLoadDependency_2_0, i_io_replay_0_bits_uop_srcLoadDependency_2_0); end
    checks++;
    if (g_io_replay_0_bits_uop_srcLoadDependency_2_1 !== i_io_replay_0_bits_uop_srcLoadDependency_2_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_srcLoadDependency_2_1: g=%h i=%h", cyc, g_io_replay_0_bits_uop_srcLoadDependency_2_1, i_io_replay_0_bits_uop_srcLoadDependency_2_1); end
    checks++;
    if (g_io_replay_0_bits_uop_srcLoadDependency_2_2 !== i_io_replay_0_bits_uop_srcLoadDependency_2_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_srcLoadDependency_2_2: g=%h i=%h", cyc, g_io_replay_0_bits_uop_srcLoadDependency_2_2, i_io_replay_0_bits_uop_srcLoadDependency_2_2); end
    checks++;
    if (g_io_replay_0_bits_uop_srcLoadDependency_3_0 !== i_io_replay_0_bits_uop_srcLoadDependency_3_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_srcLoadDependency_3_0: g=%h i=%h", cyc, g_io_replay_0_bits_uop_srcLoadDependency_3_0, i_io_replay_0_bits_uop_srcLoadDependency_3_0); end
    checks++;
    if (g_io_replay_0_bits_uop_srcLoadDependency_3_1 !== i_io_replay_0_bits_uop_srcLoadDependency_3_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_srcLoadDependency_3_1: g=%h i=%h", cyc, g_io_replay_0_bits_uop_srcLoadDependency_3_1, i_io_replay_0_bits_uop_srcLoadDependency_3_1); end
    checks++;
    if (g_io_replay_0_bits_uop_srcLoadDependency_3_2 !== i_io_replay_0_bits_uop_srcLoadDependency_3_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_srcLoadDependency_3_2: g=%h i=%h", cyc, g_io_replay_0_bits_uop_srcLoadDependency_3_2, i_io_replay_0_bits_uop_srcLoadDependency_3_2); end
    checks++;
    if (g_io_replay_0_bits_uop_srcLoadDependency_4_0 !== i_io_replay_0_bits_uop_srcLoadDependency_4_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_srcLoadDependency_4_0: g=%h i=%h", cyc, g_io_replay_0_bits_uop_srcLoadDependency_4_0, i_io_replay_0_bits_uop_srcLoadDependency_4_0); end
    checks++;
    if (g_io_replay_0_bits_uop_srcLoadDependency_4_1 !== i_io_replay_0_bits_uop_srcLoadDependency_4_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_srcLoadDependency_4_1: g=%h i=%h", cyc, g_io_replay_0_bits_uop_srcLoadDependency_4_1, i_io_replay_0_bits_uop_srcLoadDependency_4_1); end
    checks++;
    if (g_io_replay_0_bits_uop_srcLoadDependency_4_2 !== i_io_replay_0_bits_uop_srcLoadDependency_4_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_srcLoadDependency_4_2: g=%h i=%h", cyc, g_io_replay_0_bits_uop_srcLoadDependency_4_2, i_io_replay_0_bits_uop_srcLoadDependency_4_2); end
    checks++;
    if (g_io_replay_0_bits_uop_psrc_0 !== i_io_replay_0_bits_uop_psrc_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_psrc_0: g=%h i=%h", cyc, g_io_replay_0_bits_uop_psrc_0, i_io_replay_0_bits_uop_psrc_0); end
    checks++;
    if (g_io_replay_0_bits_uop_psrc_1 !== i_io_replay_0_bits_uop_psrc_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_psrc_1: g=%h i=%h", cyc, g_io_replay_0_bits_uop_psrc_1, i_io_replay_0_bits_uop_psrc_1); end
    checks++;
    if (g_io_replay_0_bits_uop_psrc_2 !== i_io_replay_0_bits_uop_psrc_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_psrc_2: g=%h i=%h", cyc, g_io_replay_0_bits_uop_psrc_2, i_io_replay_0_bits_uop_psrc_2); end
    checks++;
    if (g_io_replay_0_bits_uop_psrc_3 !== i_io_replay_0_bits_uop_psrc_3) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_psrc_3: g=%h i=%h", cyc, g_io_replay_0_bits_uop_psrc_3, i_io_replay_0_bits_uop_psrc_3); end
    checks++;
    if (g_io_replay_0_bits_uop_psrc_4 !== i_io_replay_0_bits_uop_psrc_4) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_psrc_4: g=%h i=%h", cyc, g_io_replay_0_bits_uop_psrc_4, i_io_replay_0_bits_uop_psrc_4); end
    checks++;
    if (g_io_replay_0_bits_uop_pdest !== i_io_replay_0_bits_uop_pdest) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_pdest: g=%h i=%h", cyc, g_io_replay_0_bits_uop_pdest, i_io_replay_0_bits_uop_pdest); end
    checks++;
    if (g_io_replay_0_bits_uop_useRegCache_0 !== i_io_replay_0_bits_uop_useRegCache_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_useRegCache_0: g=%h i=%h", cyc, g_io_replay_0_bits_uop_useRegCache_0, i_io_replay_0_bits_uop_useRegCache_0); end
    checks++;
    if (g_io_replay_0_bits_uop_useRegCache_1 !== i_io_replay_0_bits_uop_useRegCache_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_useRegCache_1: g=%h i=%h", cyc, g_io_replay_0_bits_uop_useRegCache_1, i_io_replay_0_bits_uop_useRegCache_1); end
    checks++;
    if (g_io_replay_0_bits_uop_regCacheIdx_0 !== i_io_replay_0_bits_uop_regCacheIdx_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_regCacheIdx_0: g=%h i=%h", cyc, g_io_replay_0_bits_uop_regCacheIdx_0, i_io_replay_0_bits_uop_regCacheIdx_0); end
    checks++;
    if (g_io_replay_0_bits_uop_regCacheIdx_1 !== i_io_replay_0_bits_uop_regCacheIdx_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_regCacheIdx_1: g=%h i=%h", cyc, g_io_replay_0_bits_uop_regCacheIdx_1, i_io_replay_0_bits_uop_regCacheIdx_1); end
    checks++;
    if (g_io_replay_0_bits_uop_robIdx_flag !== i_io_replay_0_bits_uop_robIdx_flag) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_robIdx_flag: g=%h i=%h", cyc, g_io_replay_0_bits_uop_robIdx_flag, i_io_replay_0_bits_uop_robIdx_flag); end
    checks++;
    if (g_io_replay_0_bits_uop_robIdx_value !== i_io_replay_0_bits_uop_robIdx_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_robIdx_value: g=%h i=%h", cyc, g_io_replay_0_bits_uop_robIdx_value, i_io_replay_0_bits_uop_robIdx_value); end
    checks++;
    if (g_io_replay_0_bits_uop_instrSize !== i_io_replay_0_bits_uop_instrSize) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_instrSize: g=%h i=%h", cyc, g_io_replay_0_bits_uop_instrSize, i_io_replay_0_bits_uop_instrSize); end
    checks++;
    if (g_io_replay_0_bits_uop_dirtyFs !== i_io_replay_0_bits_uop_dirtyFs) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_dirtyFs: g=%h i=%h", cyc, g_io_replay_0_bits_uop_dirtyFs, i_io_replay_0_bits_uop_dirtyFs); end
    checks++;
    if (g_io_replay_0_bits_uop_dirtyVs !== i_io_replay_0_bits_uop_dirtyVs) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_dirtyVs: g=%h i=%h", cyc, g_io_replay_0_bits_uop_dirtyVs, i_io_replay_0_bits_uop_dirtyVs); end
    checks++;
    if (g_io_replay_0_bits_uop_traceBlockInPipe_itype !== i_io_replay_0_bits_uop_traceBlockInPipe_itype) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_traceBlockInPipe_itype: g=%h i=%h", cyc, g_io_replay_0_bits_uop_traceBlockInPipe_itype, i_io_replay_0_bits_uop_traceBlockInPipe_itype); end
    checks++;
    if (g_io_replay_0_bits_uop_traceBlockInPipe_iretire !== i_io_replay_0_bits_uop_traceBlockInPipe_iretire) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_traceBlockInPipe_iretire: g=%h i=%h", cyc, g_io_replay_0_bits_uop_traceBlockInPipe_iretire, i_io_replay_0_bits_uop_traceBlockInPipe_iretire); end
    checks++;
    if (g_io_replay_0_bits_uop_traceBlockInPipe_ilastsize !== i_io_replay_0_bits_uop_traceBlockInPipe_ilastsize) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_traceBlockInPipe_ilastsize: g=%h i=%h", cyc, g_io_replay_0_bits_uop_traceBlockInPipe_ilastsize, i_io_replay_0_bits_uop_traceBlockInPipe_ilastsize); end
    checks++;
    if (g_io_replay_0_bits_uop_eliminatedMove !== i_io_replay_0_bits_uop_eliminatedMove) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_eliminatedMove: g=%h i=%h", cyc, g_io_replay_0_bits_uop_eliminatedMove, i_io_replay_0_bits_uop_eliminatedMove); end
    checks++;
    if (g_io_replay_0_bits_uop_snapshot !== i_io_replay_0_bits_uop_snapshot) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_snapshot: g=%h i=%h", cyc, g_io_replay_0_bits_uop_snapshot, i_io_replay_0_bits_uop_snapshot); end
    checks++;
    if (g_io_replay_0_bits_uop_debugInfo_eliminatedMove !== i_io_replay_0_bits_uop_debugInfo_eliminatedMove) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_debugInfo_eliminatedMove: g=%h i=%h", cyc, g_io_replay_0_bits_uop_debugInfo_eliminatedMove, i_io_replay_0_bits_uop_debugInfo_eliminatedMove); end
    checks++;
    if (g_io_replay_0_bits_uop_debugInfo_renameTime !== i_io_replay_0_bits_uop_debugInfo_renameTime) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_debugInfo_renameTime: g=%h i=%h", cyc, g_io_replay_0_bits_uop_debugInfo_renameTime, i_io_replay_0_bits_uop_debugInfo_renameTime); end
    checks++;
    if (g_io_replay_0_bits_uop_debugInfo_dispatchTime !== i_io_replay_0_bits_uop_debugInfo_dispatchTime) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_debugInfo_dispatchTime: g=%h i=%h", cyc, g_io_replay_0_bits_uop_debugInfo_dispatchTime, i_io_replay_0_bits_uop_debugInfo_dispatchTime); end
    checks++;
    if (g_io_replay_0_bits_uop_debugInfo_enqRsTime !== i_io_replay_0_bits_uop_debugInfo_enqRsTime) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_debugInfo_enqRsTime: g=%h i=%h", cyc, g_io_replay_0_bits_uop_debugInfo_enqRsTime, i_io_replay_0_bits_uop_debugInfo_enqRsTime); end
    checks++;
    if (g_io_replay_0_bits_uop_debugInfo_selectTime !== i_io_replay_0_bits_uop_debugInfo_selectTime) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_debugInfo_selectTime: g=%h i=%h", cyc, g_io_replay_0_bits_uop_debugInfo_selectTime, i_io_replay_0_bits_uop_debugInfo_selectTime); end
    checks++;
    if (g_io_replay_0_bits_uop_debugInfo_issueTime !== i_io_replay_0_bits_uop_debugInfo_issueTime) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_debugInfo_issueTime: g=%h i=%h", cyc, g_io_replay_0_bits_uop_debugInfo_issueTime, i_io_replay_0_bits_uop_debugInfo_issueTime); end
    checks++;
    if (g_io_replay_0_bits_uop_debugInfo_writebackTime !== i_io_replay_0_bits_uop_debugInfo_writebackTime) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_debugInfo_writebackTime: g=%h i=%h", cyc, g_io_replay_0_bits_uop_debugInfo_writebackTime, i_io_replay_0_bits_uop_debugInfo_writebackTime); end
    checks++;
    if (g_io_replay_0_bits_uop_debugInfo_runahead_checkpoint_id !== i_io_replay_0_bits_uop_debugInfo_runahead_checkpoint_id) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_debugInfo_runahead_checkpoint_id: g=%h i=%h", cyc, g_io_replay_0_bits_uop_debugInfo_runahead_checkpoint_id, i_io_replay_0_bits_uop_debugInfo_runahead_checkpoint_id); end
    checks++;
    if (g_io_replay_0_bits_uop_debugInfo_tlbFirstReqTime !== i_io_replay_0_bits_uop_debugInfo_tlbFirstReqTime) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_debugInfo_tlbFirstReqTime: g=%h i=%h", cyc, g_io_replay_0_bits_uop_debugInfo_tlbFirstReqTime, i_io_replay_0_bits_uop_debugInfo_tlbFirstReqTime); end
    checks++;
    if (g_io_replay_0_bits_uop_debugInfo_tlbRespTime !== i_io_replay_0_bits_uop_debugInfo_tlbRespTime) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_debugInfo_tlbRespTime: g=%h i=%h", cyc, g_io_replay_0_bits_uop_debugInfo_tlbRespTime, i_io_replay_0_bits_uop_debugInfo_tlbRespTime); end
    checks++;
    if (g_io_replay_0_bits_uop_debug_seqNum_seqNum !== i_io_replay_0_bits_uop_debug_seqNum_seqNum) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_debug_seqNum_seqNum: g=%h i=%h", cyc, g_io_replay_0_bits_uop_debug_seqNum_seqNum, i_io_replay_0_bits_uop_debug_seqNum_seqNum); end
    checks++;
    if (g_io_replay_0_bits_uop_debug_seqNum_uopIdx !== i_io_replay_0_bits_uop_debug_seqNum_uopIdx) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_debug_seqNum_uopIdx: g=%h i=%h", cyc, g_io_replay_0_bits_uop_debug_seqNum_uopIdx, i_io_replay_0_bits_uop_debug_seqNum_uopIdx); end
    checks++;
    if (g_io_replay_0_bits_uop_storeSetHit !== i_io_replay_0_bits_uop_storeSetHit) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_storeSetHit: g=%h i=%h", cyc, g_io_replay_0_bits_uop_storeSetHit, i_io_replay_0_bits_uop_storeSetHit); end
    checks++;
    if (g_io_replay_0_bits_uop_waitForRobIdx_flag !== i_io_replay_0_bits_uop_waitForRobIdx_flag) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_waitForRobIdx_flag: g=%h i=%h", cyc, g_io_replay_0_bits_uop_waitForRobIdx_flag, i_io_replay_0_bits_uop_waitForRobIdx_flag); end
    checks++;
    if (g_io_replay_0_bits_uop_waitForRobIdx_value !== i_io_replay_0_bits_uop_waitForRobIdx_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_waitForRobIdx_value: g=%h i=%h", cyc, g_io_replay_0_bits_uop_waitForRobIdx_value, i_io_replay_0_bits_uop_waitForRobIdx_value); end
    checks++;
    if (g_io_replay_0_bits_uop_loadWaitBit !== i_io_replay_0_bits_uop_loadWaitBit) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_loadWaitBit: g=%h i=%h", cyc, g_io_replay_0_bits_uop_loadWaitBit, i_io_replay_0_bits_uop_loadWaitBit); end
    checks++;
    if (g_io_replay_0_bits_uop_ssid !== i_io_replay_0_bits_uop_ssid) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_ssid: g=%h i=%h", cyc, g_io_replay_0_bits_uop_ssid, i_io_replay_0_bits_uop_ssid); end
    checks++;
    if (g_io_replay_0_bits_uop_lqIdx_flag !== i_io_replay_0_bits_uop_lqIdx_flag) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_lqIdx_flag: g=%h i=%h", cyc, g_io_replay_0_bits_uop_lqIdx_flag, i_io_replay_0_bits_uop_lqIdx_flag); end
    checks++;
    if (g_io_replay_0_bits_uop_lqIdx_value !== i_io_replay_0_bits_uop_lqIdx_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_lqIdx_value: g=%h i=%h", cyc, g_io_replay_0_bits_uop_lqIdx_value, i_io_replay_0_bits_uop_lqIdx_value); end
    checks++;
    if (g_io_replay_0_bits_uop_sqIdx_flag !== i_io_replay_0_bits_uop_sqIdx_flag) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_sqIdx_flag: g=%h i=%h", cyc, g_io_replay_0_bits_uop_sqIdx_flag, i_io_replay_0_bits_uop_sqIdx_flag); end
    checks++;
    if (g_io_replay_0_bits_uop_sqIdx_value !== i_io_replay_0_bits_uop_sqIdx_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_sqIdx_value: g=%h i=%h", cyc, g_io_replay_0_bits_uop_sqIdx_value, i_io_replay_0_bits_uop_sqIdx_value); end
    checks++;
    if (g_io_replay_0_bits_uop_singleStep !== i_io_replay_0_bits_uop_singleStep) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_singleStep: g=%h i=%h", cyc, g_io_replay_0_bits_uop_singleStep, i_io_replay_0_bits_uop_singleStep); end
    checks++;
    if (g_io_replay_0_bits_uop_debug_fuType !== i_io_replay_0_bits_uop_debug_fuType) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_debug_fuType: g=%h i=%h", cyc, g_io_replay_0_bits_uop_debug_fuType, i_io_replay_0_bits_uop_debug_fuType); end
    checks++;
    if (g_io_replay_0_bits_uop_debug_sim_trig !== i_io_replay_0_bits_uop_debug_sim_trig) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_debug_sim_trig: g=%h i=%h", cyc, g_io_replay_0_bits_uop_debug_sim_trig, i_io_replay_0_bits_uop_debug_sim_trig); end
    checks++;
    if (g_io_replay_0_bits_uop_numLsElem !== i_io_replay_0_bits_uop_numLsElem) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_uop_numLsElem: g=%h i=%h", cyc, g_io_replay_0_bits_uop_numLsElem, i_io_replay_0_bits_uop_numLsElem); end
    checks++;
    if (g_io_replay_0_bits_vaddr !== i_io_replay_0_bits_vaddr) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_vaddr: g=%h i=%h", cyc, g_io_replay_0_bits_vaddr, i_io_replay_0_bits_vaddr); end
    checks++;
    if (g_io_replay_0_bits_mask !== i_io_replay_0_bits_mask) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_mask: g=%h i=%h", cyc, g_io_replay_0_bits_mask, i_io_replay_0_bits_mask); end
    checks++;
    if (g_io_replay_0_bits_isvec !== i_io_replay_0_bits_isvec) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_isvec: g=%h i=%h", cyc, g_io_replay_0_bits_isvec, i_io_replay_0_bits_isvec); end
    checks++;
    if (g_io_replay_0_bits_is128bit !== i_io_replay_0_bits_is128bit) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_is128bit: g=%h i=%h", cyc, g_io_replay_0_bits_is128bit, i_io_replay_0_bits_is128bit); end
    checks++;
    if (g_io_replay_0_bits_elemIdx !== i_io_replay_0_bits_elemIdx) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_elemIdx: g=%h i=%h", cyc, g_io_replay_0_bits_elemIdx, i_io_replay_0_bits_elemIdx); end
    checks++;
    if (g_io_replay_0_bits_alignedType !== i_io_replay_0_bits_alignedType) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_alignedType: g=%h i=%h", cyc, g_io_replay_0_bits_alignedType, i_io_replay_0_bits_alignedType); end
    checks++;
    if (g_io_replay_0_bits_mbIndex !== i_io_replay_0_bits_mbIndex) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_mbIndex: g=%h i=%h", cyc, g_io_replay_0_bits_mbIndex, i_io_replay_0_bits_mbIndex); end
    checks++;
    if (g_io_replay_0_bits_reg_offset !== i_io_replay_0_bits_reg_offset) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_reg_offset: g=%h i=%h", cyc, g_io_replay_0_bits_reg_offset, i_io_replay_0_bits_reg_offset); end
    checks++;
    if (g_io_replay_0_bits_elemIdxInsideVd !== i_io_replay_0_bits_elemIdxInsideVd) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_elemIdxInsideVd: g=%h i=%h", cyc, g_io_replay_0_bits_elemIdxInsideVd, i_io_replay_0_bits_elemIdxInsideVd); end
    checks++;
    if (g_io_replay_0_bits_vecActive !== i_io_replay_0_bits_vecActive) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_vecActive: g=%h i=%h", cyc, g_io_replay_0_bits_vecActive, i_io_replay_0_bits_vecActive); end
    checks++;
    if (g_io_replay_0_bits_mshrid !== i_io_replay_0_bits_mshrid) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_mshrid: g=%h i=%h", cyc, g_io_replay_0_bits_mshrid, i_io_replay_0_bits_mshrid); end
    checks++;
    if (g_io_replay_0_bits_forward_tlDchannel !== i_io_replay_0_bits_forward_tlDchannel) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_forward_tlDchannel: g=%h i=%h", cyc, g_io_replay_0_bits_forward_tlDchannel, i_io_replay_0_bits_forward_tlDchannel); end
    checks++;
    if (g_io_replay_0_bits_schedIndex !== i_io_replay_0_bits_schedIndex) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_0_bits_schedIndex: g=%h i=%h", cyc, g_io_replay_0_bits_schedIndex, i_io_replay_0_bits_schedIndex); end
    checks++;
    if (g_io_replay_1_valid !== i_io_replay_1_valid) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_valid: g=%h i=%h", cyc, g_io_replay_1_valid, i_io_replay_1_valid); end
    checks++;
    if (g_io_replay_1_bits_uop_instr !== i_io_replay_1_bits_uop_instr) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_instr: g=%h i=%h", cyc, g_io_replay_1_bits_uop_instr, i_io_replay_1_bits_uop_instr); end
    checks++;
    if (g_io_replay_1_bits_uop_pc !== i_io_replay_1_bits_uop_pc) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_pc: g=%h i=%h", cyc, g_io_replay_1_bits_uop_pc, i_io_replay_1_bits_uop_pc); end
    checks++;
    if (g_io_replay_1_bits_uop_foldpc !== i_io_replay_1_bits_uop_foldpc) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_foldpc: g=%h i=%h", cyc, g_io_replay_1_bits_uop_foldpc, i_io_replay_1_bits_uop_foldpc); end
    checks++;
    if (g_io_replay_1_bits_uop_exceptionVec_0 !== i_io_replay_1_bits_uop_exceptionVec_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_exceptionVec_0: g=%h i=%h", cyc, g_io_replay_1_bits_uop_exceptionVec_0, i_io_replay_1_bits_uop_exceptionVec_0); end
    checks++;
    if (g_io_replay_1_bits_uop_exceptionVec_1 !== i_io_replay_1_bits_uop_exceptionVec_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_exceptionVec_1: g=%h i=%h", cyc, g_io_replay_1_bits_uop_exceptionVec_1, i_io_replay_1_bits_uop_exceptionVec_1); end
    checks++;
    if (g_io_replay_1_bits_uop_exceptionVec_2 !== i_io_replay_1_bits_uop_exceptionVec_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_exceptionVec_2: g=%h i=%h", cyc, g_io_replay_1_bits_uop_exceptionVec_2, i_io_replay_1_bits_uop_exceptionVec_2); end
    checks++;
    if (g_io_replay_1_bits_uop_exceptionVec_3 !== i_io_replay_1_bits_uop_exceptionVec_3) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_exceptionVec_3: g=%h i=%h", cyc, g_io_replay_1_bits_uop_exceptionVec_3, i_io_replay_1_bits_uop_exceptionVec_3); end
    checks++;
    if (g_io_replay_1_bits_uop_exceptionVec_5 !== i_io_replay_1_bits_uop_exceptionVec_5) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_exceptionVec_5: g=%h i=%h", cyc, g_io_replay_1_bits_uop_exceptionVec_5, i_io_replay_1_bits_uop_exceptionVec_5); end
    checks++;
    if (g_io_replay_1_bits_uop_exceptionVec_6 !== i_io_replay_1_bits_uop_exceptionVec_6) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_exceptionVec_6: g=%h i=%h", cyc, g_io_replay_1_bits_uop_exceptionVec_6, i_io_replay_1_bits_uop_exceptionVec_6); end
    checks++;
    if (g_io_replay_1_bits_uop_exceptionVec_7 !== i_io_replay_1_bits_uop_exceptionVec_7) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_exceptionVec_7: g=%h i=%h", cyc, g_io_replay_1_bits_uop_exceptionVec_7, i_io_replay_1_bits_uop_exceptionVec_7); end
    checks++;
    if (g_io_replay_1_bits_uop_exceptionVec_8 !== i_io_replay_1_bits_uop_exceptionVec_8) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_exceptionVec_8: g=%h i=%h", cyc, g_io_replay_1_bits_uop_exceptionVec_8, i_io_replay_1_bits_uop_exceptionVec_8); end
    checks++;
    if (g_io_replay_1_bits_uop_exceptionVec_9 !== i_io_replay_1_bits_uop_exceptionVec_9) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_exceptionVec_9: g=%h i=%h", cyc, g_io_replay_1_bits_uop_exceptionVec_9, i_io_replay_1_bits_uop_exceptionVec_9); end
    checks++;
    if (g_io_replay_1_bits_uop_exceptionVec_10 !== i_io_replay_1_bits_uop_exceptionVec_10) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_exceptionVec_10: g=%h i=%h", cyc, g_io_replay_1_bits_uop_exceptionVec_10, i_io_replay_1_bits_uop_exceptionVec_10); end
    checks++;
    if (g_io_replay_1_bits_uop_exceptionVec_11 !== i_io_replay_1_bits_uop_exceptionVec_11) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_exceptionVec_11: g=%h i=%h", cyc, g_io_replay_1_bits_uop_exceptionVec_11, i_io_replay_1_bits_uop_exceptionVec_11); end
    checks++;
    if (g_io_replay_1_bits_uop_exceptionVec_12 !== i_io_replay_1_bits_uop_exceptionVec_12) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_exceptionVec_12: g=%h i=%h", cyc, g_io_replay_1_bits_uop_exceptionVec_12, i_io_replay_1_bits_uop_exceptionVec_12); end
    checks++;
    if (g_io_replay_1_bits_uop_exceptionVec_13 !== i_io_replay_1_bits_uop_exceptionVec_13) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_exceptionVec_13: g=%h i=%h", cyc, g_io_replay_1_bits_uop_exceptionVec_13, i_io_replay_1_bits_uop_exceptionVec_13); end
    checks++;
    if (g_io_replay_1_bits_uop_exceptionVec_14 !== i_io_replay_1_bits_uop_exceptionVec_14) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_exceptionVec_14: g=%h i=%h", cyc, g_io_replay_1_bits_uop_exceptionVec_14, i_io_replay_1_bits_uop_exceptionVec_14); end
    checks++;
    if (g_io_replay_1_bits_uop_exceptionVec_15 !== i_io_replay_1_bits_uop_exceptionVec_15) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_exceptionVec_15: g=%h i=%h", cyc, g_io_replay_1_bits_uop_exceptionVec_15, i_io_replay_1_bits_uop_exceptionVec_15); end
    checks++;
    if (g_io_replay_1_bits_uop_exceptionVec_16 !== i_io_replay_1_bits_uop_exceptionVec_16) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_exceptionVec_16: g=%h i=%h", cyc, g_io_replay_1_bits_uop_exceptionVec_16, i_io_replay_1_bits_uop_exceptionVec_16); end
    checks++;
    if (g_io_replay_1_bits_uop_exceptionVec_17 !== i_io_replay_1_bits_uop_exceptionVec_17) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_exceptionVec_17: g=%h i=%h", cyc, g_io_replay_1_bits_uop_exceptionVec_17, i_io_replay_1_bits_uop_exceptionVec_17); end
    checks++;
    if (g_io_replay_1_bits_uop_exceptionVec_18 !== i_io_replay_1_bits_uop_exceptionVec_18) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_exceptionVec_18: g=%h i=%h", cyc, g_io_replay_1_bits_uop_exceptionVec_18, i_io_replay_1_bits_uop_exceptionVec_18); end
    checks++;
    if (g_io_replay_1_bits_uop_exceptionVec_19 !== i_io_replay_1_bits_uop_exceptionVec_19) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_exceptionVec_19: g=%h i=%h", cyc, g_io_replay_1_bits_uop_exceptionVec_19, i_io_replay_1_bits_uop_exceptionVec_19); end
    checks++;
    if (g_io_replay_1_bits_uop_exceptionVec_20 !== i_io_replay_1_bits_uop_exceptionVec_20) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_exceptionVec_20: g=%h i=%h", cyc, g_io_replay_1_bits_uop_exceptionVec_20, i_io_replay_1_bits_uop_exceptionVec_20); end
    checks++;
    if (g_io_replay_1_bits_uop_exceptionVec_21 !== i_io_replay_1_bits_uop_exceptionVec_21) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_exceptionVec_21: g=%h i=%h", cyc, g_io_replay_1_bits_uop_exceptionVec_21, i_io_replay_1_bits_uop_exceptionVec_21); end
    checks++;
    if (g_io_replay_1_bits_uop_exceptionVec_22 !== i_io_replay_1_bits_uop_exceptionVec_22) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_exceptionVec_22: g=%h i=%h", cyc, g_io_replay_1_bits_uop_exceptionVec_22, i_io_replay_1_bits_uop_exceptionVec_22); end
    checks++;
    if (g_io_replay_1_bits_uop_exceptionVec_23 !== i_io_replay_1_bits_uop_exceptionVec_23) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_exceptionVec_23: g=%h i=%h", cyc, g_io_replay_1_bits_uop_exceptionVec_23, i_io_replay_1_bits_uop_exceptionVec_23); end
    checks++;
    if (g_io_replay_1_bits_uop_isFetchMalAddr !== i_io_replay_1_bits_uop_isFetchMalAddr) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_isFetchMalAddr: g=%h i=%h", cyc, g_io_replay_1_bits_uop_isFetchMalAddr, i_io_replay_1_bits_uop_isFetchMalAddr); end
    checks++;
    if (g_io_replay_1_bits_uop_hasException !== i_io_replay_1_bits_uop_hasException) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_hasException: g=%h i=%h", cyc, g_io_replay_1_bits_uop_hasException, i_io_replay_1_bits_uop_hasException); end
    checks++;
    if (g_io_replay_1_bits_uop_trigger !== i_io_replay_1_bits_uop_trigger) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_trigger: g=%h i=%h", cyc, g_io_replay_1_bits_uop_trigger, i_io_replay_1_bits_uop_trigger); end
    checks++;
    if (g_io_replay_1_bits_uop_preDecodeInfo_valid !== i_io_replay_1_bits_uop_preDecodeInfo_valid) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_preDecodeInfo_valid: g=%h i=%h", cyc, g_io_replay_1_bits_uop_preDecodeInfo_valid, i_io_replay_1_bits_uop_preDecodeInfo_valid); end
    checks++;
    if (g_io_replay_1_bits_uop_preDecodeInfo_isRVC !== i_io_replay_1_bits_uop_preDecodeInfo_isRVC) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_preDecodeInfo_isRVC: g=%h i=%h", cyc, g_io_replay_1_bits_uop_preDecodeInfo_isRVC, i_io_replay_1_bits_uop_preDecodeInfo_isRVC); end
    checks++;
    if (g_io_replay_1_bits_uop_preDecodeInfo_brType !== i_io_replay_1_bits_uop_preDecodeInfo_brType) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_preDecodeInfo_brType: g=%h i=%h", cyc, g_io_replay_1_bits_uop_preDecodeInfo_brType, i_io_replay_1_bits_uop_preDecodeInfo_brType); end
    checks++;
    if (g_io_replay_1_bits_uop_preDecodeInfo_isCall !== i_io_replay_1_bits_uop_preDecodeInfo_isCall) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_preDecodeInfo_isCall: g=%h i=%h", cyc, g_io_replay_1_bits_uop_preDecodeInfo_isCall, i_io_replay_1_bits_uop_preDecodeInfo_isCall); end
    checks++;
    if (g_io_replay_1_bits_uop_preDecodeInfo_isRet !== i_io_replay_1_bits_uop_preDecodeInfo_isRet) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_preDecodeInfo_isRet: g=%h i=%h", cyc, g_io_replay_1_bits_uop_preDecodeInfo_isRet, i_io_replay_1_bits_uop_preDecodeInfo_isRet); end
    checks++;
    if (g_io_replay_1_bits_uop_pred_taken !== i_io_replay_1_bits_uop_pred_taken) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_pred_taken: g=%h i=%h", cyc, g_io_replay_1_bits_uop_pred_taken, i_io_replay_1_bits_uop_pred_taken); end
    checks++;
    if (g_io_replay_1_bits_uop_crossPageIPFFix !== i_io_replay_1_bits_uop_crossPageIPFFix) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_crossPageIPFFix: g=%h i=%h", cyc, g_io_replay_1_bits_uop_crossPageIPFFix, i_io_replay_1_bits_uop_crossPageIPFFix); end
    checks++;
    if (g_io_replay_1_bits_uop_ftqPtr_flag !== i_io_replay_1_bits_uop_ftqPtr_flag) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_ftqPtr_flag: g=%h i=%h", cyc, g_io_replay_1_bits_uop_ftqPtr_flag, i_io_replay_1_bits_uop_ftqPtr_flag); end
    checks++;
    if (g_io_replay_1_bits_uop_ftqPtr_value !== i_io_replay_1_bits_uop_ftqPtr_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_ftqPtr_value: g=%h i=%h", cyc, g_io_replay_1_bits_uop_ftqPtr_value, i_io_replay_1_bits_uop_ftqPtr_value); end
    checks++;
    if (g_io_replay_1_bits_uop_ftqOffset !== i_io_replay_1_bits_uop_ftqOffset) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_ftqOffset: g=%h i=%h", cyc, g_io_replay_1_bits_uop_ftqOffset, i_io_replay_1_bits_uop_ftqOffset); end
    checks++;
    if (g_io_replay_1_bits_uop_satpFlushFirstFetchFault !== i_io_replay_1_bits_uop_satpFlushFirstFetchFault) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_satpFlushFirstFetchFault: g=%h i=%h", cyc, g_io_replay_1_bits_uop_satpFlushFirstFetchFault, i_io_replay_1_bits_uop_satpFlushFirstFetchFault); end
    checks++;
    if (g_io_replay_1_bits_uop_srcType_0 !== i_io_replay_1_bits_uop_srcType_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_srcType_0: g=%h i=%h", cyc, g_io_replay_1_bits_uop_srcType_0, i_io_replay_1_bits_uop_srcType_0); end
    checks++;
    if (g_io_replay_1_bits_uop_srcType_1 !== i_io_replay_1_bits_uop_srcType_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_srcType_1: g=%h i=%h", cyc, g_io_replay_1_bits_uop_srcType_1, i_io_replay_1_bits_uop_srcType_1); end
    checks++;
    if (g_io_replay_1_bits_uop_srcType_2 !== i_io_replay_1_bits_uop_srcType_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_srcType_2: g=%h i=%h", cyc, g_io_replay_1_bits_uop_srcType_2, i_io_replay_1_bits_uop_srcType_2); end
    checks++;
    if (g_io_replay_1_bits_uop_srcType_3 !== i_io_replay_1_bits_uop_srcType_3) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_srcType_3: g=%h i=%h", cyc, g_io_replay_1_bits_uop_srcType_3, i_io_replay_1_bits_uop_srcType_3); end
    checks++;
    if (g_io_replay_1_bits_uop_srcType_4 !== i_io_replay_1_bits_uop_srcType_4) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_srcType_4: g=%h i=%h", cyc, g_io_replay_1_bits_uop_srcType_4, i_io_replay_1_bits_uop_srcType_4); end
    checks++;
    if (g_io_replay_1_bits_uop_ldest !== i_io_replay_1_bits_uop_ldest) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_ldest: g=%h i=%h", cyc, g_io_replay_1_bits_uop_ldest, i_io_replay_1_bits_uop_ldest); end
    checks++;
    if (g_io_replay_1_bits_uop_fuType !== i_io_replay_1_bits_uop_fuType) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_fuType: g=%h i=%h", cyc, g_io_replay_1_bits_uop_fuType, i_io_replay_1_bits_uop_fuType); end
    checks++;
    if (g_io_replay_1_bits_uop_fuOpType !== i_io_replay_1_bits_uop_fuOpType) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_fuOpType: g=%h i=%h", cyc, g_io_replay_1_bits_uop_fuOpType, i_io_replay_1_bits_uop_fuOpType); end
    checks++;
    if (g_io_replay_1_bits_uop_rfWen !== i_io_replay_1_bits_uop_rfWen) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_rfWen: g=%h i=%h", cyc, g_io_replay_1_bits_uop_rfWen, i_io_replay_1_bits_uop_rfWen); end
    checks++;
    if (g_io_replay_1_bits_uop_fpWen !== i_io_replay_1_bits_uop_fpWen) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_fpWen: g=%h i=%h", cyc, g_io_replay_1_bits_uop_fpWen, i_io_replay_1_bits_uop_fpWen); end
    checks++;
    if (g_io_replay_1_bits_uop_vecWen !== i_io_replay_1_bits_uop_vecWen) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vecWen: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vecWen, i_io_replay_1_bits_uop_vecWen); end
    checks++;
    if (g_io_replay_1_bits_uop_v0Wen !== i_io_replay_1_bits_uop_v0Wen) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_v0Wen: g=%h i=%h", cyc, g_io_replay_1_bits_uop_v0Wen, i_io_replay_1_bits_uop_v0Wen); end
    checks++;
    if (g_io_replay_1_bits_uop_vlWen !== i_io_replay_1_bits_uop_vlWen) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vlWen: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vlWen, i_io_replay_1_bits_uop_vlWen); end
    checks++;
    if (g_io_replay_1_bits_uop_isXSTrap !== i_io_replay_1_bits_uop_isXSTrap) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_isXSTrap: g=%h i=%h", cyc, g_io_replay_1_bits_uop_isXSTrap, i_io_replay_1_bits_uop_isXSTrap); end
    checks++;
    if (g_io_replay_1_bits_uop_waitForward !== i_io_replay_1_bits_uop_waitForward) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_waitForward: g=%h i=%h", cyc, g_io_replay_1_bits_uop_waitForward, i_io_replay_1_bits_uop_waitForward); end
    checks++;
    if (g_io_replay_1_bits_uop_blockBackward !== i_io_replay_1_bits_uop_blockBackward) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_blockBackward: g=%h i=%h", cyc, g_io_replay_1_bits_uop_blockBackward, i_io_replay_1_bits_uop_blockBackward); end
    checks++;
    if (g_io_replay_1_bits_uop_canRobCompress !== i_io_replay_1_bits_uop_canRobCompress) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_canRobCompress: g=%h i=%h", cyc, g_io_replay_1_bits_uop_canRobCompress, i_io_replay_1_bits_uop_canRobCompress); end
    checks++;
    if (g_io_replay_1_bits_uop_selImm !== i_io_replay_1_bits_uop_selImm) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_selImm: g=%h i=%h", cyc, g_io_replay_1_bits_uop_selImm, i_io_replay_1_bits_uop_selImm); end
    checks++;
    if (g_io_replay_1_bits_uop_imm !== i_io_replay_1_bits_uop_imm) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_imm: g=%h i=%h", cyc, g_io_replay_1_bits_uop_imm, i_io_replay_1_bits_uop_imm); end
    checks++;
    if (g_io_replay_1_bits_uop_fpu_typeTagOut !== i_io_replay_1_bits_uop_fpu_typeTagOut) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_fpu_typeTagOut: g=%h i=%h", cyc, g_io_replay_1_bits_uop_fpu_typeTagOut, i_io_replay_1_bits_uop_fpu_typeTagOut); end
    checks++;
    if (g_io_replay_1_bits_uop_fpu_wflags !== i_io_replay_1_bits_uop_fpu_wflags) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_fpu_wflags: g=%h i=%h", cyc, g_io_replay_1_bits_uop_fpu_wflags, i_io_replay_1_bits_uop_fpu_wflags); end
    checks++;
    if (g_io_replay_1_bits_uop_fpu_typ !== i_io_replay_1_bits_uop_fpu_typ) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_fpu_typ: g=%h i=%h", cyc, g_io_replay_1_bits_uop_fpu_typ, i_io_replay_1_bits_uop_fpu_typ); end
    checks++;
    if (g_io_replay_1_bits_uop_fpu_fmt !== i_io_replay_1_bits_uop_fpu_fmt) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_fpu_fmt: g=%h i=%h", cyc, g_io_replay_1_bits_uop_fpu_fmt, i_io_replay_1_bits_uop_fpu_fmt); end
    checks++;
    if (g_io_replay_1_bits_uop_fpu_rm !== i_io_replay_1_bits_uop_fpu_rm) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_fpu_rm: g=%h i=%h", cyc, g_io_replay_1_bits_uop_fpu_rm, i_io_replay_1_bits_uop_fpu_rm); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_vill !== i_io_replay_1_bits_uop_vpu_vill) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_vill: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_vill, i_io_replay_1_bits_uop_vpu_vill); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_vma !== i_io_replay_1_bits_uop_vpu_vma) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_vma: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_vma, i_io_replay_1_bits_uop_vpu_vma); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_vta !== i_io_replay_1_bits_uop_vpu_vta) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_vta: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_vta, i_io_replay_1_bits_uop_vpu_vta); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_vsew !== i_io_replay_1_bits_uop_vpu_vsew) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_vsew: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_vsew, i_io_replay_1_bits_uop_vpu_vsew); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_vlmul !== i_io_replay_1_bits_uop_vpu_vlmul) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_vlmul: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_vlmul, i_io_replay_1_bits_uop_vpu_vlmul); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_specVill !== i_io_replay_1_bits_uop_vpu_specVill) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_specVill: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_specVill, i_io_replay_1_bits_uop_vpu_specVill); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_specVma !== i_io_replay_1_bits_uop_vpu_specVma) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_specVma: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_specVma, i_io_replay_1_bits_uop_vpu_specVma); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_specVta !== i_io_replay_1_bits_uop_vpu_specVta) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_specVta: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_specVta, i_io_replay_1_bits_uop_vpu_specVta); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_specVsew !== i_io_replay_1_bits_uop_vpu_specVsew) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_specVsew: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_specVsew, i_io_replay_1_bits_uop_vpu_specVsew); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_specVlmul !== i_io_replay_1_bits_uop_vpu_specVlmul) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_specVlmul: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_specVlmul, i_io_replay_1_bits_uop_vpu_specVlmul); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_vm !== i_io_replay_1_bits_uop_vpu_vm) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_vm: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_vm, i_io_replay_1_bits_uop_vpu_vm); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_vstart !== i_io_replay_1_bits_uop_vpu_vstart) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_vstart: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_vstart, i_io_replay_1_bits_uop_vpu_vstart); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_frm !== i_io_replay_1_bits_uop_vpu_frm) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_frm: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_frm, i_io_replay_1_bits_uop_vpu_frm); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_fpu_isFpToVecInst !== i_io_replay_1_bits_uop_vpu_fpu_isFpToVecInst) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_fpu_isFpToVecInst: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_fpu_isFpToVecInst, i_io_replay_1_bits_uop_vpu_fpu_isFpToVecInst); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_fpu_isFP32Instr !== i_io_replay_1_bits_uop_vpu_fpu_isFP32Instr) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_fpu_isFP32Instr: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_fpu_isFP32Instr, i_io_replay_1_bits_uop_vpu_fpu_isFP32Instr); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_fpu_isFP64Instr !== i_io_replay_1_bits_uop_vpu_fpu_isFP64Instr) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_fpu_isFP64Instr: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_fpu_isFP64Instr, i_io_replay_1_bits_uop_vpu_fpu_isFP64Instr); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_fpu_isReduction !== i_io_replay_1_bits_uop_vpu_fpu_isReduction) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_fpu_isReduction: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_fpu_isReduction, i_io_replay_1_bits_uop_vpu_fpu_isReduction); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_fpu_isFoldTo1_2 !== i_io_replay_1_bits_uop_vpu_fpu_isFoldTo1_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_fpu_isFoldTo1_2: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_fpu_isFoldTo1_2, i_io_replay_1_bits_uop_vpu_fpu_isFoldTo1_2); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_fpu_isFoldTo1_4 !== i_io_replay_1_bits_uop_vpu_fpu_isFoldTo1_4) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_fpu_isFoldTo1_4: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_fpu_isFoldTo1_4, i_io_replay_1_bits_uop_vpu_fpu_isFoldTo1_4); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_fpu_isFoldTo1_8 !== i_io_replay_1_bits_uop_vpu_fpu_isFoldTo1_8) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_fpu_isFoldTo1_8: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_fpu_isFoldTo1_8, i_io_replay_1_bits_uop_vpu_fpu_isFoldTo1_8); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_vxrm !== i_io_replay_1_bits_uop_vpu_vxrm) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_vxrm: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_vxrm, i_io_replay_1_bits_uop_vpu_vxrm); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_vuopIdx !== i_io_replay_1_bits_uop_vpu_vuopIdx) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_vuopIdx: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_vuopIdx, i_io_replay_1_bits_uop_vpu_vuopIdx); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_lastUop !== i_io_replay_1_bits_uop_vpu_lastUop) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_lastUop: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_lastUop, i_io_replay_1_bits_uop_vpu_lastUop); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_vmask !== i_io_replay_1_bits_uop_vpu_vmask) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_vmask: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_vmask, i_io_replay_1_bits_uop_vpu_vmask); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_vl !== i_io_replay_1_bits_uop_vpu_vl) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_vl: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_vl, i_io_replay_1_bits_uop_vpu_vl); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_nf !== i_io_replay_1_bits_uop_vpu_nf) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_nf: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_nf, i_io_replay_1_bits_uop_vpu_nf); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_veew !== i_io_replay_1_bits_uop_vpu_veew) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_veew: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_veew, i_io_replay_1_bits_uop_vpu_veew); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_isReverse !== i_io_replay_1_bits_uop_vpu_isReverse) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_isReverse: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_isReverse, i_io_replay_1_bits_uop_vpu_isReverse); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_isExt !== i_io_replay_1_bits_uop_vpu_isExt) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_isExt: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_isExt, i_io_replay_1_bits_uop_vpu_isExt); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_isNarrow !== i_io_replay_1_bits_uop_vpu_isNarrow) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_isNarrow: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_isNarrow, i_io_replay_1_bits_uop_vpu_isNarrow); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_isDstMask !== i_io_replay_1_bits_uop_vpu_isDstMask) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_isDstMask: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_isDstMask, i_io_replay_1_bits_uop_vpu_isDstMask); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_isOpMask !== i_io_replay_1_bits_uop_vpu_isOpMask) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_isOpMask: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_isOpMask, i_io_replay_1_bits_uop_vpu_isOpMask); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_isMove !== i_io_replay_1_bits_uop_vpu_isMove) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_isMove: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_isMove, i_io_replay_1_bits_uop_vpu_isMove); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_isDependOldVd !== i_io_replay_1_bits_uop_vpu_isDependOldVd) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_isDependOldVd: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_isDependOldVd, i_io_replay_1_bits_uop_vpu_isDependOldVd); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_isWritePartVd !== i_io_replay_1_bits_uop_vpu_isWritePartVd) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_isWritePartVd: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_isWritePartVd, i_io_replay_1_bits_uop_vpu_isWritePartVd); end
    checks++;
    if (g_io_replay_1_bits_uop_vpu_isVleff !== i_io_replay_1_bits_uop_vpu_isVleff) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vpu_isVleff: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vpu_isVleff, i_io_replay_1_bits_uop_vpu_isVleff); end
    checks++;
    if (g_io_replay_1_bits_uop_vlsInstr !== i_io_replay_1_bits_uop_vlsInstr) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_vlsInstr: g=%h i=%h", cyc, g_io_replay_1_bits_uop_vlsInstr, i_io_replay_1_bits_uop_vlsInstr); end
    checks++;
    if (g_io_replay_1_bits_uop_wfflags !== i_io_replay_1_bits_uop_wfflags) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_wfflags: g=%h i=%h", cyc, g_io_replay_1_bits_uop_wfflags, i_io_replay_1_bits_uop_wfflags); end
    checks++;
    if (g_io_replay_1_bits_uop_isMove !== i_io_replay_1_bits_uop_isMove) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_isMove: g=%h i=%h", cyc, g_io_replay_1_bits_uop_isMove, i_io_replay_1_bits_uop_isMove); end
    checks++;
    if (g_io_replay_1_bits_uop_isDropAmocasSta !== i_io_replay_1_bits_uop_isDropAmocasSta) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_isDropAmocasSta: g=%h i=%h", cyc, g_io_replay_1_bits_uop_isDropAmocasSta, i_io_replay_1_bits_uop_isDropAmocasSta); end
    checks++;
    if (g_io_replay_1_bits_uop_uopIdx !== i_io_replay_1_bits_uop_uopIdx) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_uopIdx: g=%h i=%h", cyc, g_io_replay_1_bits_uop_uopIdx, i_io_replay_1_bits_uop_uopIdx); end
    checks++;
    if (g_io_replay_1_bits_uop_isVset !== i_io_replay_1_bits_uop_isVset) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_isVset: g=%h i=%h", cyc, g_io_replay_1_bits_uop_isVset, i_io_replay_1_bits_uop_isVset); end
    checks++;
    if (g_io_replay_1_bits_uop_firstUop !== i_io_replay_1_bits_uop_firstUop) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_firstUop: g=%h i=%h", cyc, g_io_replay_1_bits_uop_firstUop, i_io_replay_1_bits_uop_firstUop); end
    checks++;
    if (g_io_replay_1_bits_uop_lastUop !== i_io_replay_1_bits_uop_lastUop) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_lastUop: g=%h i=%h", cyc, g_io_replay_1_bits_uop_lastUop, i_io_replay_1_bits_uop_lastUop); end
    checks++;
    if (g_io_replay_1_bits_uop_numUops !== i_io_replay_1_bits_uop_numUops) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_numUops: g=%h i=%h", cyc, g_io_replay_1_bits_uop_numUops, i_io_replay_1_bits_uop_numUops); end
    checks++;
    if (g_io_replay_1_bits_uop_numWB !== i_io_replay_1_bits_uop_numWB) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_numWB: g=%h i=%h", cyc, g_io_replay_1_bits_uop_numWB, i_io_replay_1_bits_uop_numWB); end
    checks++;
    if (g_io_replay_1_bits_uop_commitType !== i_io_replay_1_bits_uop_commitType) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_commitType: g=%h i=%h", cyc, g_io_replay_1_bits_uop_commitType, i_io_replay_1_bits_uop_commitType); end
    checks++;
    if (g_io_replay_1_bits_uop_srcState_0 !== i_io_replay_1_bits_uop_srcState_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_srcState_0: g=%h i=%h", cyc, g_io_replay_1_bits_uop_srcState_0, i_io_replay_1_bits_uop_srcState_0); end
    checks++;
    if (g_io_replay_1_bits_uop_srcState_1 !== i_io_replay_1_bits_uop_srcState_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_srcState_1: g=%h i=%h", cyc, g_io_replay_1_bits_uop_srcState_1, i_io_replay_1_bits_uop_srcState_1); end
    checks++;
    if (g_io_replay_1_bits_uop_srcState_2 !== i_io_replay_1_bits_uop_srcState_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_srcState_2: g=%h i=%h", cyc, g_io_replay_1_bits_uop_srcState_2, i_io_replay_1_bits_uop_srcState_2); end
    checks++;
    if (g_io_replay_1_bits_uop_srcState_3 !== i_io_replay_1_bits_uop_srcState_3) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_srcState_3: g=%h i=%h", cyc, g_io_replay_1_bits_uop_srcState_3, i_io_replay_1_bits_uop_srcState_3); end
    checks++;
    if (g_io_replay_1_bits_uop_srcState_4 !== i_io_replay_1_bits_uop_srcState_4) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_srcState_4: g=%h i=%h", cyc, g_io_replay_1_bits_uop_srcState_4, i_io_replay_1_bits_uop_srcState_4); end
    checks++;
    if (g_io_replay_1_bits_uop_srcLoadDependency_0_0 !== i_io_replay_1_bits_uop_srcLoadDependency_0_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_srcLoadDependency_0_0: g=%h i=%h", cyc, g_io_replay_1_bits_uop_srcLoadDependency_0_0, i_io_replay_1_bits_uop_srcLoadDependency_0_0); end
    checks++;
    if (g_io_replay_1_bits_uop_srcLoadDependency_0_1 !== i_io_replay_1_bits_uop_srcLoadDependency_0_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_srcLoadDependency_0_1: g=%h i=%h", cyc, g_io_replay_1_bits_uop_srcLoadDependency_0_1, i_io_replay_1_bits_uop_srcLoadDependency_0_1); end
    checks++;
    if (g_io_replay_1_bits_uop_srcLoadDependency_0_2 !== i_io_replay_1_bits_uop_srcLoadDependency_0_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_srcLoadDependency_0_2: g=%h i=%h", cyc, g_io_replay_1_bits_uop_srcLoadDependency_0_2, i_io_replay_1_bits_uop_srcLoadDependency_0_2); end
    checks++;
    if (g_io_replay_1_bits_uop_srcLoadDependency_1_0 !== i_io_replay_1_bits_uop_srcLoadDependency_1_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_srcLoadDependency_1_0: g=%h i=%h", cyc, g_io_replay_1_bits_uop_srcLoadDependency_1_0, i_io_replay_1_bits_uop_srcLoadDependency_1_0); end
    checks++;
    if (g_io_replay_1_bits_uop_srcLoadDependency_1_1 !== i_io_replay_1_bits_uop_srcLoadDependency_1_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_srcLoadDependency_1_1: g=%h i=%h", cyc, g_io_replay_1_bits_uop_srcLoadDependency_1_1, i_io_replay_1_bits_uop_srcLoadDependency_1_1); end
    checks++;
    if (g_io_replay_1_bits_uop_srcLoadDependency_1_2 !== i_io_replay_1_bits_uop_srcLoadDependency_1_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_srcLoadDependency_1_2: g=%h i=%h", cyc, g_io_replay_1_bits_uop_srcLoadDependency_1_2, i_io_replay_1_bits_uop_srcLoadDependency_1_2); end
    checks++;
    if (g_io_replay_1_bits_uop_srcLoadDependency_2_0 !== i_io_replay_1_bits_uop_srcLoadDependency_2_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_srcLoadDependency_2_0: g=%h i=%h", cyc, g_io_replay_1_bits_uop_srcLoadDependency_2_0, i_io_replay_1_bits_uop_srcLoadDependency_2_0); end
    checks++;
    if (g_io_replay_1_bits_uop_srcLoadDependency_2_1 !== i_io_replay_1_bits_uop_srcLoadDependency_2_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_srcLoadDependency_2_1: g=%h i=%h", cyc, g_io_replay_1_bits_uop_srcLoadDependency_2_1, i_io_replay_1_bits_uop_srcLoadDependency_2_1); end
    checks++;
    if (g_io_replay_1_bits_uop_srcLoadDependency_2_2 !== i_io_replay_1_bits_uop_srcLoadDependency_2_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_srcLoadDependency_2_2: g=%h i=%h", cyc, g_io_replay_1_bits_uop_srcLoadDependency_2_2, i_io_replay_1_bits_uop_srcLoadDependency_2_2); end
    checks++;
    if (g_io_replay_1_bits_uop_srcLoadDependency_3_0 !== i_io_replay_1_bits_uop_srcLoadDependency_3_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_srcLoadDependency_3_0: g=%h i=%h", cyc, g_io_replay_1_bits_uop_srcLoadDependency_3_0, i_io_replay_1_bits_uop_srcLoadDependency_3_0); end
    checks++;
    if (g_io_replay_1_bits_uop_srcLoadDependency_3_1 !== i_io_replay_1_bits_uop_srcLoadDependency_3_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_srcLoadDependency_3_1: g=%h i=%h", cyc, g_io_replay_1_bits_uop_srcLoadDependency_3_1, i_io_replay_1_bits_uop_srcLoadDependency_3_1); end
    checks++;
    if (g_io_replay_1_bits_uop_srcLoadDependency_3_2 !== i_io_replay_1_bits_uop_srcLoadDependency_3_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_srcLoadDependency_3_2: g=%h i=%h", cyc, g_io_replay_1_bits_uop_srcLoadDependency_3_2, i_io_replay_1_bits_uop_srcLoadDependency_3_2); end
    checks++;
    if (g_io_replay_1_bits_uop_srcLoadDependency_4_0 !== i_io_replay_1_bits_uop_srcLoadDependency_4_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_srcLoadDependency_4_0: g=%h i=%h", cyc, g_io_replay_1_bits_uop_srcLoadDependency_4_0, i_io_replay_1_bits_uop_srcLoadDependency_4_0); end
    checks++;
    if (g_io_replay_1_bits_uop_srcLoadDependency_4_1 !== i_io_replay_1_bits_uop_srcLoadDependency_4_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_srcLoadDependency_4_1: g=%h i=%h", cyc, g_io_replay_1_bits_uop_srcLoadDependency_4_1, i_io_replay_1_bits_uop_srcLoadDependency_4_1); end
    checks++;
    if (g_io_replay_1_bits_uop_srcLoadDependency_4_2 !== i_io_replay_1_bits_uop_srcLoadDependency_4_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_srcLoadDependency_4_2: g=%h i=%h", cyc, g_io_replay_1_bits_uop_srcLoadDependency_4_2, i_io_replay_1_bits_uop_srcLoadDependency_4_2); end
    checks++;
    if (g_io_replay_1_bits_uop_psrc_0 !== i_io_replay_1_bits_uop_psrc_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_psrc_0: g=%h i=%h", cyc, g_io_replay_1_bits_uop_psrc_0, i_io_replay_1_bits_uop_psrc_0); end
    checks++;
    if (g_io_replay_1_bits_uop_psrc_1 !== i_io_replay_1_bits_uop_psrc_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_psrc_1: g=%h i=%h", cyc, g_io_replay_1_bits_uop_psrc_1, i_io_replay_1_bits_uop_psrc_1); end
    checks++;
    if (g_io_replay_1_bits_uop_psrc_2 !== i_io_replay_1_bits_uop_psrc_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_psrc_2: g=%h i=%h", cyc, g_io_replay_1_bits_uop_psrc_2, i_io_replay_1_bits_uop_psrc_2); end
    checks++;
    if (g_io_replay_1_bits_uop_psrc_3 !== i_io_replay_1_bits_uop_psrc_3) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_psrc_3: g=%h i=%h", cyc, g_io_replay_1_bits_uop_psrc_3, i_io_replay_1_bits_uop_psrc_3); end
    checks++;
    if (g_io_replay_1_bits_uop_psrc_4 !== i_io_replay_1_bits_uop_psrc_4) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_psrc_4: g=%h i=%h", cyc, g_io_replay_1_bits_uop_psrc_4, i_io_replay_1_bits_uop_psrc_4); end
    checks++;
    if (g_io_replay_1_bits_uop_pdest !== i_io_replay_1_bits_uop_pdest) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_pdest: g=%h i=%h", cyc, g_io_replay_1_bits_uop_pdest, i_io_replay_1_bits_uop_pdest); end
    checks++;
    if (g_io_replay_1_bits_uop_useRegCache_0 !== i_io_replay_1_bits_uop_useRegCache_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_useRegCache_0: g=%h i=%h", cyc, g_io_replay_1_bits_uop_useRegCache_0, i_io_replay_1_bits_uop_useRegCache_0); end
    checks++;
    if (g_io_replay_1_bits_uop_useRegCache_1 !== i_io_replay_1_bits_uop_useRegCache_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_useRegCache_1: g=%h i=%h", cyc, g_io_replay_1_bits_uop_useRegCache_1, i_io_replay_1_bits_uop_useRegCache_1); end
    checks++;
    if (g_io_replay_1_bits_uop_regCacheIdx_0 !== i_io_replay_1_bits_uop_regCacheIdx_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_regCacheIdx_0: g=%h i=%h", cyc, g_io_replay_1_bits_uop_regCacheIdx_0, i_io_replay_1_bits_uop_regCacheIdx_0); end
    checks++;
    if (g_io_replay_1_bits_uop_regCacheIdx_1 !== i_io_replay_1_bits_uop_regCacheIdx_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_regCacheIdx_1: g=%h i=%h", cyc, g_io_replay_1_bits_uop_regCacheIdx_1, i_io_replay_1_bits_uop_regCacheIdx_1); end
    checks++;
    if (g_io_replay_1_bits_uop_robIdx_flag !== i_io_replay_1_bits_uop_robIdx_flag) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_robIdx_flag: g=%h i=%h", cyc, g_io_replay_1_bits_uop_robIdx_flag, i_io_replay_1_bits_uop_robIdx_flag); end
    checks++;
    if (g_io_replay_1_bits_uop_robIdx_value !== i_io_replay_1_bits_uop_robIdx_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_robIdx_value: g=%h i=%h", cyc, g_io_replay_1_bits_uop_robIdx_value, i_io_replay_1_bits_uop_robIdx_value); end
    checks++;
    if (g_io_replay_1_bits_uop_instrSize !== i_io_replay_1_bits_uop_instrSize) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_instrSize: g=%h i=%h", cyc, g_io_replay_1_bits_uop_instrSize, i_io_replay_1_bits_uop_instrSize); end
    checks++;
    if (g_io_replay_1_bits_uop_dirtyFs !== i_io_replay_1_bits_uop_dirtyFs) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_dirtyFs: g=%h i=%h", cyc, g_io_replay_1_bits_uop_dirtyFs, i_io_replay_1_bits_uop_dirtyFs); end
    checks++;
    if (g_io_replay_1_bits_uop_dirtyVs !== i_io_replay_1_bits_uop_dirtyVs) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_dirtyVs: g=%h i=%h", cyc, g_io_replay_1_bits_uop_dirtyVs, i_io_replay_1_bits_uop_dirtyVs); end
    checks++;
    if (g_io_replay_1_bits_uop_traceBlockInPipe_itype !== i_io_replay_1_bits_uop_traceBlockInPipe_itype) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_traceBlockInPipe_itype: g=%h i=%h", cyc, g_io_replay_1_bits_uop_traceBlockInPipe_itype, i_io_replay_1_bits_uop_traceBlockInPipe_itype); end
    checks++;
    if (g_io_replay_1_bits_uop_traceBlockInPipe_iretire !== i_io_replay_1_bits_uop_traceBlockInPipe_iretire) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_traceBlockInPipe_iretire: g=%h i=%h", cyc, g_io_replay_1_bits_uop_traceBlockInPipe_iretire, i_io_replay_1_bits_uop_traceBlockInPipe_iretire); end
    checks++;
    if (g_io_replay_1_bits_uop_traceBlockInPipe_ilastsize !== i_io_replay_1_bits_uop_traceBlockInPipe_ilastsize) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_traceBlockInPipe_ilastsize: g=%h i=%h", cyc, g_io_replay_1_bits_uop_traceBlockInPipe_ilastsize, i_io_replay_1_bits_uop_traceBlockInPipe_ilastsize); end
    checks++;
    if (g_io_replay_1_bits_uop_eliminatedMove !== i_io_replay_1_bits_uop_eliminatedMove) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_eliminatedMove: g=%h i=%h", cyc, g_io_replay_1_bits_uop_eliminatedMove, i_io_replay_1_bits_uop_eliminatedMove); end
    checks++;
    if (g_io_replay_1_bits_uop_snapshot !== i_io_replay_1_bits_uop_snapshot) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_snapshot: g=%h i=%h", cyc, g_io_replay_1_bits_uop_snapshot, i_io_replay_1_bits_uop_snapshot); end
    checks++;
    if (g_io_replay_1_bits_uop_debugInfo_eliminatedMove !== i_io_replay_1_bits_uop_debugInfo_eliminatedMove) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_debugInfo_eliminatedMove: g=%h i=%h", cyc, g_io_replay_1_bits_uop_debugInfo_eliminatedMove, i_io_replay_1_bits_uop_debugInfo_eliminatedMove); end
    checks++;
    if (g_io_replay_1_bits_uop_debugInfo_renameTime !== i_io_replay_1_bits_uop_debugInfo_renameTime) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_debugInfo_renameTime: g=%h i=%h", cyc, g_io_replay_1_bits_uop_debugInfo_renameTime, i_io_replay_1_bits_uop_debugInfo_renameTime); end
    checks++;
    if (g_io_replay_1_bits_uop_debugInfo_dispatchTime !== i_io_replay_1_bits_uop_debugInfo_dispatchTime) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_debugInfo_dispatchTime: g=%h i=%h", cyc, g_io_replay_1_bits_uop_debugInfo_dispatchTime, i_io_replay_1_bits_uop_debugInfo_dispatchTime); end
    checks++;
    if (g_io_replay_1_bits_uop_debugInfo_enqRsTime !== i_io_replay_1_bits_uop_debugInfo_enqRsTime) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_debugInfo_enqRsTime: g=%h i=%h", cyc, g_io_replay_1_bits_uop_debugInfo_enqRsTime, i_io_replay_1_bits_uop_debugInfo_enqRsTime); end
    checks++;
    if (g_io_replay_1_bits_uop_debugInfo_selectTime !== i_io_replay_1_bits_uop_debugInfo_selectTime) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_debugInfo_selectTime: g=%h i=%h", cyc, g_io_replay_1_bits_uop_debugInfo_selectTime, i_io_replay_1_bits_uop_debugInfo_selectTime); end
    checks++;
    if (g_io_replay_1_bits_uop_debugInfo_issueTime !== i_io_replay_1_bits_uop_debugInfo_issueTime) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_debugInfo_issueTime: g=%h i=%h", cyc, g_io_replay_1_bits_uop_debugInfo_issueTime, i_io_replay_1_bits_uop_debugInfo_issueTime); end
    checks++;
    if (g_io_replay_1_bits_uop_debugInfo_writebackTime !== i_io_replay_1_bits_uop_debugInfo_writebackTime) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_debugInfo_writebackTime: g=%h i=%h", cyc, g_io_replay_1_bits_uop_debugInfo_writebackTime, i_io_replay_1_bits_uop_debugInfo_writebackTime); end
    checks++;
    if (g_io_replay_1_bits_uop_debugInfo_runahead_checkpoint_id !== i_io_replay_1_bits_uop_debugInfo_runahead_checkpoint_id) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_debugInfo_runahead_checkpoint_id: g=%h i=%h", cyc, g_io_replay_1_bits_uop_debugInfo_runahead_checkpoint_id, i_io_replay_1_bits_uop_debugInfo_runahead_checkpoint_id); end
    checks++;
    if (g_io_replay_1_bits_uop_debugInfo_tlbFirstReqTime !== i_io_replay_1_bits_uop_debugInfo_tlbFirstReqTime) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_debugInfo_tlbFirstReqTime: g=%h i=%h", cyc, g_io_replay_1_bits_uop_debugInfo_tlbFirstReqTime, i_io_replay_1_bits_uop_debugInfo_tlbFirstReqTime); end
    checks++;
    if (g_io_replay_1_bits_uop_debugInfo_tlbRespTime !== i_io_replay_1_bits_uop_debugInfo_tlbRespTime) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_debugInfo_tlbRespTime: g=%h i=%h", cyc, g_io_replay_1_bits_uop_debugInfo_tlbRespTime, i_io_replay_1_bits_uop_debugInfo_tlbRespTime); end
    checks++;
    if (g_io_replay_1_bits_uop_debug_seqNum_seqNum !== i_io_replay_1_bits_uop_debug_seqNum_seqNum) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_debug_seqNum_seqNum: g=%h i=%h", cyc, g_io_replay_1_bits_uop_debug_seqNum_seqNum, i_io_replay_1_bits_uop_debug_seqNum_seqNum); end
    checks++;
    if (g_io_replay_1_bits_uop_debug_seqNum_uopIdx !== i_io_replay_1_bits_uop_debug_seqNum_uopIdx) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_debug_seqNum_uopIdx: g=%h i=%h", cyc, g_io_replay_1_bits_uop_debug_seqNum_uopIdx, i_io_replay_1_bits_uop_debug_seqNum_uopIdx); end
    checks++;
    if (g_io_replay_1_bits_uop_storeSetHit !== i_io_replay_1_bits_uop_storeSetHit) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_storeSetHit: g=%h i=%h", cyc, g_io_replay_1_bits_uop_storeSetHit, i_io_replay_1_bits_uop_storeSetHit); end
    checks++;
    if (g_io_replay_1_bits_uop_waitForRobIdx_flag !== i_io_replay_1_bits_uop_waitForRobIdx_flag) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_waitForRobIdx_flag: g=%h i=%h", cyc, g_io_replay_1_bits_uop_waitForRobIdx_flag, i_io_replay_1_bits_uop_waitForRobIdx_flag); end
    checks++;
    if (g_io_replay_1_bits_uop_waitForRobIdx_value !== i_io_replay_1_bits_uop_waitForRobIdx_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_waitForRobIdx_value: g=%h i=%h", cyc, g_io_replay_1_bits_uop_waitForRobIdx_value, i_io_replay_1_bits_uop_waitForRobIdx_value); end
    checks++;
    if (g_io_replay_1_bits_uop_loadWaitBit !== i_io_replay_1_bits_uop_loadWaitBit) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_loadWaitBit: g=%h i=%h", cyc, g_io_replay_1_bits_uop_loadWaitBit, i_io_replay_1_bits_uop_loadWaitBit); end
    checks++;
    if (g_io_replay_1_bits_uop_ssid !== i_io_replay_1_bits_uop_ssid) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_ssid: g=%h i=%h", cyc, g_io_replay_1_bits_uop_ssid, i_io_replay_1_bits_uop_ssid); end
    checks++;
    if (g_io_replay_1_bits_uop_lqIdx_flag !== i_io_replay_1_bits_uop_lqIdx_flag) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_lqIdx_flag: g=%h i=%h", cyc, g_io_replay_1_bits_uop_lqIdx_flag, i_io_replay_1_bits_uop_lqIdx_flag); end
    checks++;
    if (g_io_replay_1_bits_uop_lqIdx_value !== i_io_replay_1_bits_uop_lqIdx_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_lqIdx_value: g=%h i=%h", cyc, g_io_replay_1_bits_uop_lqIdx_value, i_io_replay_1_bits_uop_lqIdx_value); end
    checks++;
    if (g_io_replay_1_bits_uop_sqIdx_flag !== i_io_replay_1_bits_uop_sqIdx_flag) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_sqIdx_flag: g=%h i=%h", cyc, g_io_replay_1_bits_uop_sqIdx_flag, i_io_replay_1_bits_uop_sqIdx_flag); end
    checks++;
    if (g_io_replay_1_bits_uop_sqIdx_value !== i_io_replay_1_bits_uop_sqIdx_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_sqIdx_value: g=%h i=%h", cyc, g_io_replay_1_bits_uop_sqIdx_value, i_io_replay_1_bits_uop_sqIdx_value); end
    checks++;
    if (g_io_replay_1_bits_uop_singleStep !== i_io_replay_1_bits_uop_singleStep) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_singleStep: g=%h i=%h", cyc, g_io_replay_1_bits_uop_singleStep, i_io_replay_1_bits_uop_singleStep); end
    checks++;
    if (g_io_replay_1_bits_uop_debug_fuType !== i_io_replay_1_bits_uop_debug_fuType) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_debug_fuType: g=%h i=%h", cyc, g_io_replay_1_bits_uop_debug_fuType, i_io_replay_1_bits_uop_debug_fuType); end
    checks++;
    if (g_io_replay_1_bits_uop_debug_sim_trig !== i_io_replay_1_bits_uop_debug_sim_trig) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_debug_sim_trig: g=%h i=%h", cyc, g_io_replay_1_bits_uop_debug_sim_trig, i_io_replay_1_bits_uop_debug_sim_trig); end
    checks++;
    if (g_io_replay_1_bits_uop_numLsElem !== i_io_replay_1_bits_uop_numLsElem) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_uop_numLsElem: g=%h i=%h", cyc, g_io_replay_1_bits_uop_numLsElem, i_io_replay_1_bits_uop_numLsElem); end
    checks++;
    if (g_io_replay_1_bits_vaddr !== i_io_replay_1_bits_vaddr) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_vaddr: g=%h i=%h", cyc, g_io_replay_1_bits_vaddr, i_io_replay_1_bits_vaddr); end
    checks++;
    if (g_io_replay_1_bits_mask !== i_io_replay_1_bits_mask) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_mask: g=%h i=%h", cyc, g_io_replay_1_bits_mask, i_io_replay_1_bits_mask); end
    checks++;
    if (g_io_replay_1_bits_isvec !== i_io_replay_1_bits_isvec) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_isvec: g=%h i=%h", cyc, g_io_replay_1_bits_isvec, i_io_replay_1_bits_isvec); end
    checks++;
    if (g_io_replay_1_bits_is128bit !== i_io_replay_1_bits_is128bit) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_is128bit: g=%h i=%h", cyc, g_io_replay_1_bits_is128bit, i_io_replay_1_bits_is128bit); end
    checks++;
    if (g_io_replay_1_bits_elemIdx !== i_io_replay_1_bits_elemIdx) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_elemIdx: g=%h i=%h", cyc, g_io_replay_1_bits_elemIdx, i_io_replay_1_bits_elemIdx); end
    checks++;
    if (g_io_replay_1_bits_alignedType !== i_io_replay_1_bits_alignedType) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_alignedType: g=%h i=%h", cyc, g_io_replay_1_bits_alignedType, i_io_replay_1_bits_alignedType); end
    checks++;
    if (g_io_replay_1_bits_mbIndex !== i_io_replay_1_bits_mbIndex) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_mbIndex: g=%h i=%h", cyc, g_io_replay_1_bits_mbIndex, i_io_replay_1_bits_mbIndex); end
    checks++;
    if (g_io_replay_1_bits_reg_offset !== i_io_replay_1_bits_reg_offset) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_reg_offset: g=%h i=%h", cyc, g_io_replay_1_bits_reg_offset, i_io_replay_1_bits_reg_offset); end
    checks++;
    if (g_io_replay_1_bits_elemIdxInsideVd !== i_io_replay_1_bits_elemIdxInsideVd) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_elemIdxInsideVd: g=%h i=%h", cyc, g_io_replay_1_bits_elemIdxInsideVd, i_io_replay_1_bits_elemIdxInsideVd); end
    checks++;
    if (g_io_replay_1_bits_vecActive !== i_io_replay_1_bits_vecActive) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_vecActive: g=%h i=%h", cyc, g_io_replay_1_bits_vecActive, i_io_replay_1_bits_vecActive); end
    checks++;
    if (g_io_replay_1_bits_mshrid !== i_io_replay_1_bits_mshrid) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_mshrid: g=%h i=%h", cyc, g_io_replay_1_bits_mshrid, i_io_replay_1_bits_mshrid); end
    checks++;
    if (g_io_replay_1_bits_forward_tlDchannel !== i_io_replay_1_bits_forward_tlDchannel) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_forward_tlDchannel: g=%h i=%h", cyc, g_io_replay_1_bits_forward_tlDchannel, i_io_replay_1_bits_forward_tlDchannel); end
    checks++;
    if (g_io_replay_1_bits_schedIndex !== i_io_replay_1_bits_schedIndex) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_1_bits_schedIndex: g=%h i=%h", cyc, g_io_replay_1_bits_schedIndex, i_io_replay_1_bits_schedIndex); end
    checks++;
    if (g_io_replay_2_valid !== i_io_replay_2_valid) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_valid: g=%h i=%h", cyc, g_io_replay_2_valid, i_io_replay_2_valid); end
    checks++;
    if (g_io_replay_2_bits_uop_instr !== i_io_replay_2_bits_uop_instr) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_instr: g=%h i=%h", cyc, g_io_replay_2_bits_uop_instr, i_io_replay_2_bits_uop_instr); end
    checks++;
    if (g_io_replay_2_bits_uop_pc !== i_io_replay_2_bits_uop_pc) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_pc: g=%h i=%h", cyc, g_io_replay_2_bits_uop_pc, i_io_replay_2_bits_uop_pc); end
    checks++;
    if (g_io_replay_2_bits_uop_foldpc !== i_io_replay_2_bits_uop_foldpc) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_foldpc: g=%h i=%h", cyc, g_io_replay_2_bits_uop_foldpc, i_io_replay_2_bits_uop_foldpc); end
    checks++;
    if (g_io_replay_2_bits_uop_exceptionVec_0 !== i_io_replay_2_bits_uop_exceptionVec_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_exceptionVec_0: g=%h i=%h", cyc, g_io_replay_2_bits_uop_exceptionVec_0, i_io_replay_2_bits_uop_exceptionVec_0); end
    checks++;
    if (g_io_replay_2_bits_uop_exceptionVec_1 !== i_io_replay_2_bits_uop_exceptionVec_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_exceptionVec_1: g=%h i=%h", cyc, g_io_replay_2_bits_uop_exceptionVec_1, i_io_replay_2_bits_uop_exceptionVec_1); end
    checks++;
    if (g_io_replay_2_bits_uop_exceptionVec_2 !== i_io_replay_2_bits_uop_exceptionVec_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_exceptionVec_2: g=%h i=%h", cyc, g_io_replay_2_bits_uop_exceptionVec_2, i_io_replay_2_bits_uop_exceptionVec_2); end
    checks++;
    if (g_io_replay_2_bits_uop_exceptionVec_3 !== i_io_replay_2_bits_uop_exceptionVec_3) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_exceptionVec_3: g=%h i=%h", cyc, g_io_replay_2_bits_uop_exceptionVec_3, i_io_replay_2_bits_uop_exceptionVec_3); end
    checks++;
    if (g_io_replay_2_bits_uop_exceptionVec_5 !== i_io_replay_2_bits_uop_exceptionVec_5) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_exceptionVec_5: g=%h i=%h", cyc, g_io_replay_2_bits_uop_exceptionVec_5, i_io_replay_2_bits_uop_exceptionVec_5); end
    checks++;
    if (g_io_replay_2_bits_uop_exceptionVec_6 !== i_io_replay_2_bits_uop_exceptionVec_6) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_exceptionVec_6: g=%h i=%h", cyc, g_io_replay_2_bits_uop_exceptionVec_6, i_io_replay_2_bits_uop_exceptionVec_6); end
    checks++;
    if (g_io_replay_2_bits_uop_exceptionVec_7 !== i_io_replay_2_bits_uop_exceptionVec_7) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_exceptionVec_7: g=%h i=%h", cyc, g_io_replay_2_bits_uop_exceptionVec_7, i_io_replay_2_bits_uop_exceptionVec_7); end
    checks++;
    if (g_io_replay_2_bits_uop_exceptionVec_8 !== i_io_replay_2_bits_uop_exceptionVec_8) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_exceptionVec_8: g=%h i=%h", cyc, g_io_replay_2_bits_uop_exceptionVec_8, i_io_replay_2_bits_uop_exceptionVec_8); end
    checks++;
    if (g_io_replay_2_bits_uop_exceptionVec_9 !== i_io_replay_2_bits_uop_exceptionVec_9) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_exceptionVec_9: g=%h i=%h", cyc, g_io_replay_2_bits_uop_exceptionVec_9, i_io_replay_2_bits_uop_exceptionVec_9); end
    checks++;
    if (g_io_replay_2_bits_uop_exceptionVec_10 !== i_io_replay_2_bits_uop_exceptionVec_10) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_exceptionVec_10: g=%h i=%h", cyc, g_io_replay_2_bits_uop_exceptionVec_10, i_io_replay_2_bits_uop_exceptionVec_10); end
    checks++;
    if (g_io_replay_2_bits_uop_exceptionVec_11 !== i_io_replay_2_bits_uop_exceptionVec_11) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_exceptionVec_11: g=%h i=%h", cyc, g_io_replay_2_bits_uop_exceptionVec_11, i_io_replay_2_bits_uop_exceptionVec_11); end
    checks++;
    if (g_io_replay_2_bits_uop_exceptionVec_12 !== i_io_replay_2_bits_uop_exceptionVec_12) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_exceptionVec_12: g=%h i=%h", cyc, g_io_replay_2_bits_uop_exceptionVec_12, i_io_replay_2_bits_uop_exceptionVec_12); end
    checks++;
    if (g_io_replay_2_bits_uop_exceptionVec_13 !== i_io_replay_2_bits_uop_exceptionVec_13) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_exceptionVec_13: g=%h i=%h", cyc, g_io_replay_2_bits_uop_exceptionVec_13, i_io_replay_2_bits_uop_exceptionVec_13); end
    checks++;
    if (g_io_replay_2_bits_uop_exceptionVec_14 !== i_io_replay_2_bits_uop_exceptionVec_14) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_exceptionVec_14: g=%h i=%h", cyc, g_io_replay_2_bits_uop_exceptionVec_14, i_io_replay_2_bits_uop_exceptionVec_14); end
    checks++;
    if (g_io_replay_2_bits_uop_exceptionVec_15 !== i_io_replay_2_bits_uop_exceptionVec_15) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_exceptionVec_15: g=%h i=%h", cyc, g_io_replay_2_bits_uop_exceptionVec_15, i_io_replay_2_bits_uop_exceptionVec_15); end
    checks++;
    if (g_io_replay_2_bits_uop_exceptionVec_16 !== i_io_replay_2_bits_uop_exceptionVec_16) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_exceptionVec_16: g=%h i=%h", cyc, g_io_replay_2_bits_uop_exceptionVec_16, i_io_replay_2_bits_uop_exceptionVec_16); end
    checks++;
    if (g_io_replay_2_bits_uop_exceptionVec_17 !== i_io_replay_2_bits_uop_exceptionVec_17) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_exceptionVec_17: g=%h i=%h", cyc, g_io_replay_2_bits_uop_exceptionVec_17, i_io_replay_2_bits_uop_exceptionVec_17); end
    checks++;
    if (g_io_replay_2_bits_uop_exceptionVec_18 !== i_io_replay_2_bits_uop_exceptionVec_18) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_exceptionVec_18: g=%h i=%h", cyc, g_io_replay_2_bits_uop_exceptionVec_18, i_io_replay_2_bits_uop_exceptionVec_18); end
    checks++;
    if (g_io_replay_2_bits_uop_exceptionVec_19 !== i_io_replay_2_bits_uop_exceptionVec_19) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_exceptionVec_19: g=%h i=%h", cyc, g_io_replay_2_bits_uop_exceptionVec_19, i_io_replay_2_bits_uop_exceptionVec_19); end
    checks++;
    if (g_io_replay_2_bits_uop_exceptionVec_20 !== i_io_replay_2_bits_uop_exceptionVec_20) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_exceptionVec_20: g=%h i=%h", cyc, g_io_replay_2_bits_uop_exceptionVec_20, i_io_replay_2_bits_uop_exceptionVec_20); end
    checks++;
    if (g_io_replay_2_bits_uop_exceptionVec_21 !== i_io_replay_2_bits_uop_exceptionVec_21) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_exceptionVec_21: g=%h i=%h", cyc, g_io_replay_2_bits_uop_exceptionVec_21, i_io_replay_2_bits_uop_exceptionVec_21); end
    checks++;
    if (g_io_replay_2_bits_uop_exceptionVec_22 !== i_io_replay_2_bits_uop_exceptionVec_22) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_exceptionVec_22: g=%h i=%h", cyc, g_io_replay_2_bits_uop_exceptionVec_22, i_io_replay_2_bits_uop_exceptionVec_22); end
    checks++;
    if (g_io_replay_2_bits_uop_exceptionVec_23 !== i_io_replay_2_bits_uop_exceptionVec_23) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_exceptionVec_23: g=%h i=%h", cyc, g_io_replay_2_bits_uop_exceptionVec_23, i_io_replay_2_bits_uop_exceptionVec_23); end
    checks++;
    if (g_io_replay_2_bits_uop_isFetchMalAddr !== i_io_replay_2_bits_uop_isFetchMalAddr) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_isFetchMalAddr: g=%h i=%h", cyc, g_io_replay_2_bits_uop_isFetchMalAddr, i_io_replay_2_bits_uop_isFetchMalAddr); end
    checks++;
    if (g_io_replay_2_bits_uop_hasException !== i_io_replay_2_bits_uop_hasException) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_hasException: g=%h i=%h", cyc, g_io_replay_2_bits_uop_hasException, i_io_replay_2_bits_uop_hasException); end
    checks++;
    if (g_io_replay_2_bits_uop_trigger !== i_io_replay_2_bits_uop_trigger) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_trigger: g=%h i=%h", cyc, g_io_replay_2_bits_uop_trigger, i_io_replay_2_bits_uop_trigger); end
    checks++;
    if (g_io_replay_2_bits_uop_preDecodeInfo_valid !== i_io_replay_2_bits_uop_preDecodeInfo_valid) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_preDecodeInfo_valid: g=%h i=%h", cyc, g_io_replay_2_bits_uop_preDecodeInfo_valid, i_io_replay_2_bits_uop_preDecodeInfo_valid); end
    checks++;
    if (g_io_replay_2_bits_uop_preDecodeInfo_isRVC !== i_io_replay_2_bits_uop_preDecodeInfo_isRVC) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_preDecodeInfo_isRVC: g=%h i=%h", cyc, g_io_replay_2_bits_uop_preDecodeInfo_isRVC, i_io_replay_2_bits_uop_preDecodeInfo_isRVC); end
    checks++;
    if (g_io_replay_2_bits_uop_preDecodeInfo_brType !== i_io_replay_2_bits_uop_preDecodeInfo_brType) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_preDecodeInfo_brType: g=%h i=%h", cyc, g_io_replay_2_bits_uop_preDecodeInfo_brType, i_io_replay_2_bits_uop_preDecodeInfo_brType); end
    checks++;
    if (g_io_replay_2_bits_uop_preDecodeInfo_isCall !== i_io_replay_2_bits_uop_preDecodeInfo_isCall) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_preDecodeInfo_isCall: g=%h i=%h", cyc, g_io_replay_2_bits_uop_preDecodeInfo_isCall, i_io_replay_2_bits_uop_preDecodeInfo_isCall); end
    checks++;
    if (g_io_replay_2_bits_uop_preDecodeInfo_isRet !== i_io_replay_2_bits_uop_preDecodeInfo_isRet) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_preDecodeInfo_isRet: g=%h i=%h", cyc, g_io_replay_2_bits_uop_preDecodeInfo_isRet, i_io_replay_2_bits_uop_preDecodeInfo_isRet); end
    checks++;
    if (g_io_replay_2_bits_uop_pred_taken !== i_io_replay_2_bits_uop_pred_taken) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_pred_taken: g=%h i=%h", cyc, g_io_replay_2_bits_uop_pred_taken, i_io_replay_2_bits_uop_pred_taken); end
    checks++;
    if (g_io_replay_2_bits_uop_crossPageIPFFix !== i_io_replay_2_bits_uop_crossPageIPFFix) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_crossPageIPFFix: g=%h i=%h", cyc, g_io_replay_2_bits_uop_crossPageIPFFix, i_io_replay_2_bits_uop_crossPageIPFFix); end
    checks++;
    if (g_io_replay_2_bits_uop_ftqPtr_flag !== i_io_replay_2_bits_uop_ftqPtr_flag) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_ftqPtr_flag: g=%h i=%h", cyc, g_io_replay_2_bits_uop_ftqPtr_flag, i_io_replay_2_bits_uop_ftqPtr_flag); end
    checks++;
    if (g_io_replay_2_bits_uop_ftqPtr_value !== i_io_replay_2_bits_uop_ftqPtr_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_ftqPtr_value: g=%h i=%h", cyc, g_io_replay_2_bits_uop_ftqPtr_value, i_io_replay_2_bits_uop_ftqPtr_value); end
    checks++;
    if (g_io_replay_2_bits_uop_ftqOffset !== i_io_replay_2_bits_uop_ftqOffset) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_ftqOffset: g=%h i=%h", cyc, g_io_replay_2_bits_uop_ftqOffset, i_io_replay_2_bits_uop_ftqOffset); end
    checks++;
    if (g_io_replay_2_bits_uop_satpFlushFirstFetchFault !== i_io_replay_2_bits_uop_satpFlushFirstFetchFault) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_satpFlushFirstFetchFault: g=%h i=%h", cyc, g_io_replay_2_bits_uop_satpFlushFirstFetchFault, i_io_replay_2_bits_uop_satpFlushFirstFetchFault); end
    checks++;
    if (g_io_replay_2_bits_uop_srcType_0 !== i_io_replay_2_bits_uop_srcType_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_srcType_0: g=%h i=%h", cyc, g_io_replay_2_bits_uop_srcType_0, i_io_replay_2_bits_uop_srcType_0); end
    checks++;
    if (g_io_replay_2_bits_uop_srcType_1 !== i_io_replay_2_bits_uop_srcType_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_srcType_1: g=%h i=%h", cyc, g_io_replay_2_bits_uop_srcType_1, i_io_replay_2_bits_uop_srcType_1); end
    checks++;
    if (g_io_replay_2_bits_uop_srcType_2 !== i_io_replay_2_bits_uop_srcType_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_srcType_2: g=%h i=%h", cyc, g_io_replay_2_bits_uop_srcType_2, i_io_replay_2_bits_uop_srcType_2); end
    checks++;
    if (g_io_replay_2_bits_uop_srcType_3 !== i_io_replay_2_bits_uop_srcType_3) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_srcType_3: g=%h i=%h", cyc, g_io_replay_2_bits_uop_srcType_3, i_io_replay_2_bits_uop_srcType_3); end
    checks++;
    if (g_io_replay_2_bits_uop_srcType_4 !== i_io_replay_2_bits_uop_srcType_4) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_srcType_4: g=%h i=%h", cyc, g_io_replay_2_bits_uop_srcType_4, i_io_replay_2_bits_uop_srcType_4); end
    checks++;
    if (g_io_replay_2_bits_uop_ldest !== i_io_replay_2_bits_uop_ldest) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_ldest: g=%h i=%h", cyc, g_io_replay_2_bits_uop_ldest, i_io_replay_2_bits_uop_ldest); end
    checks++;
    if (g_io_replay_2_bits_uop_fuType !== i_io_replay_2_bits_uop_fuType) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_fuType: g=%h i=%h", cyc, g_io_replay_2_bits_uop_fuType, i_io_replay_2_bits_uop_fuType); end
    checks++;
    if (g_io_replay_2_bits_uop_fuOpType !== i_io_replay_2_bits_uop_fuOpType) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_fuOpType: g=%h i=%h", cyc, g_io_replay_2_bits_uop_fuOpType, i_io_replay_2_bits_uop_fuOpType); end
    checks++;
    if (g_io_replay_2_bits_uop_rfWen !== i_io_replay_2_bits_uop_rfWen) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_rfWen: g=%h i=%h", cyc, g_io_replay_2_bits_uop_rfWen, i_io_replay_2_bits_uop_rfWen); end
    checks++;
    if (g_io_replay_2_bits_uop_fpWen !== i_io_replay_2_bits_uop_fpWen) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_fpWen: g=%h i=%h", cyc, g_io_replay_2_bits_uop_fpWen, i_io_replay_2_bits_uop_fpWen); end
    checks++;
    if (g_io_replay_2_bits_uop_vecWen !== i_io_replay_2_bits_uop_vecWen) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vecWen: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vecWen, i_io_replay_2_bits_uop_vecWen); end
    checks++;
    if (g_io_replay_2_bits_uop_v0Wen !== i_io_replay_2_bits_uop_v0Wen) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_v0Wen: g=%h i=%h", cyc, g_io_replay_2_bits_uop_v0Wen, i_io_replay_2_bits_uop_v0Wen); end
    checks++;
    if (g_io_replay_2_bits_uop_vlWen !== i_io_replay_2_bits_uop_vlWen) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vlWen: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vlWen, i_io_replay_2_bits_uop_vlWen); end
    checks++;
    if (g_io_replay_2_bits_uop_isXSTrap !== i_io_replay_2_bits_uop_isXSTrap) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_isXSTrap: g=%h i=%h", cyc, g_io_replay_2_bits_uop_isXSTrap, i_io_replay_2_bits_uop_isXSTrap); end
    checks++;
    if (g_io_replay_2_bits_uop_waitForward !== i_io_replay_2_bits_uop_waitForward) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_waitForward: g=%h i=%h", cyc, g_io_replay_2_bits_uop_waitForward, i_io_replay_2_bits_uop_waitForward); end
    checks++;
    if (g_io_replay_2_bits_uop_blockBackward !== i_io_replay_2_bits_uop_blockBackward) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_blockBackward: g=%h i=%h", cyc, g_io_replay_2_bits_uop_blockBackward, i_io_replay_2_bits_uop_blockBackward); end
    checks++;
    if (g_io_replay_2_bits_uop_canRobCompress !== i_io_replay_2_bits_uop_canRobCompress) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_canRobCompress: g=%h i=%h", cyc, g_io_replay_2_bits_uop_canRobCompress, i_io_replay_2_bits_uop_canRobCompress); end
    checks++;
    if (g_io_replay_2_bits_uop_selImm !== i_io_replay_2_bits_uop_selImm) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_selImm: g=%h i=%h", cyc, g_io_replay_2_bits_uop_selImm, i_io_replay_2_bits_uop_selImm); end
    checks++;
    if (g_io_replay_2_bits_uop_imm !== i_io_replay_2_bits_uop_imm) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_imm: g=%h i=%h", cyc, g_io_replay_2_bits_uop_imm, i_io_replay_2_bits_uop_imm); end
    checks++;
    if (g_io_replay_2_bits_uop_fpu_typeTagOut !== i_io_replay_2_bits_uop_fpu_typeTagOut) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_fpu_typeTagOut: g=%h i=%h", cyc, g_io_replay_2_bits_uop_fpu_typeTagOut, i_io_replay_2_bits_uop_fpu_typeTagOut); end
    checks++;
    if (g_io_replay_2_bits_uop_fpu_wflags !== i_io_replay_2_bits_uop_fpu_wflags) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_fpu_wflags: g=%h i=%h", cyc, g_io_replay_2_bits_uop_fpu_wflags, i_io_replay_2_bits_uop_fpu_wflags); end
    checks++;
    if (g_io_replay_2_bits_uop_fpu_typ !== i_io_replay_2_bits_uop_fpu_typ) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_fpu_typ: g=%h i=%h", cyc, g_io_replay_2_bits_uop_fpu_typ, i_io_replay_2_bits_uop_fpu_typ); end
    checks++;
    if (g_io_replay_2_bits_uop_fpu_fmt !== i_io_replay_2_bits_uop_fpu_fmt) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_fpu_fmt: g=%h i=%h", cyc, g_io_replay_2_bits_uop_fpu_fmt, i_io_replay_2_bits_uop_fpu_fmt); end
    checks++;
    if (g_io_replay_2_bits_uop_fpu_rm !== i_io_replay_2_bits_uop_fpu_rm) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_fpu_rm: g=%h i=%h", cyc, g_io_replay_2_bits_uop_fpu_rm, i_io_replay_2_bits_uop_fpu_rm); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_vill !== i_io_replay_2_bits_uop_vpu_vill) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_vill: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_vill, i_io_replay_2_bits_uop_vpu_vill); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_vma !== i_io_replay_2_bits_uop_vpu_vma) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_vma: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_vma, i_io_replay_2_bits_uop_vpu_vma); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_vta !== i_io_replay_2_bits_uop_vpu_vta) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_vta: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_vta, i_io_replay_2_bits_uop_vpu_vta); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_vsew !== i_io_replay_2_bits_uop_vpu_vsew) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_vsew: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_vsew, i_io_replay_2_bits_uop_vpu_vsew); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_vlmul !== i_io_replay_2_bits_uop_vpu_vlmul) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_vlmul: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_vlmul, i_io_replay_2_bits_uop_vpu_vlmul); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_specVill !== i_io_replay_2_bits_uop_vpu_specVill) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_specVill: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_specVill, i_io_replay_2_bits_uop_vpu_specVill); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_specVma !== i_io_replay_2_bits_uop_vpu_specVma) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_specVma: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_specVma, i_io_replay_2_bits_uop_vpu_specVma); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_specVta !== i_io_replay_2_bits_uop_vpu_specVta) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_specVta: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_specVta, i_io_replay_2_bits_uop_vpu_specVta); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_specVsew !== i_io_replay_2_bits_uop_vpu_specVsew) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_specVsew: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_specVsew, i_io_replay_2_bits_uop_vpu_specVsew); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_specVlmul !== i_io_replay_2_bits_uop_vpu_specVlmul) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_specVlmul: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_specVlmul, i_io_replay_2_bits_uop_vpu_specVlmul); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_vm !== i_io_replay_2_bits_uop_vpu_vm) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_vm: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_vm, i_io_replay_2_bits_uop_vpu_vm); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_vstart !== i_io_replay_2_bits_uop_vpu_vstart) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_vstart: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_vstart, i_io_replay_2_bits_uop_vpu_vstart); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_frm !== i_io_replay_2_bits_uop_vpu_frm) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_frm: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_frm, i_io_replay_2_bits_uop_vpu_frm); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_fpu_isFpToVecInst !== i_io_replay_2_bits_uop_vpu_fpu_isFpToVecInst) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_fpu_isFpToVecInst: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_fpu_isFpToVecInst, i_io_replay_2_bits_uop_vpu_fpu_isFpToVecInst); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_fpu_isFP32Instr !== i_io_replay_2_bits_uop_vpu_fpu_isFP32Instr) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_fpu_isFP32Instr: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_fpu_isFP32Instr, i_io_replay_2_bits_uop_vpu_fpu_isFP32Instr); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_fpu_isFP64Instr !== i_io_replay_2_bits_uop_vpu_fpu_isFP64Instr) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_fpu_isFP64Instr: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_fpu_isFP64Instr, i_io_replay_2_bits_uop_vpu_fpu_isFP64Instr); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_fpu_isReduction !== i_io_replay_2_bits_uop_vpu_fpu_isReduction) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_fpu_isReduction: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_fpu_isReduction, i_io_replay_2_bits_uop_vpu_fpu_isReduction); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_fpu_isFoldTo1_2 !== i_io_replay_2_bits_uop_vpu_fpu_isFoldTo1_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_fpu_isFoldTo1_2: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_fpu_isFoldTo1_2, i_io_replay_2_bits_uop_vpu_fpu_isFoldTo1_2); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_fpu_isFoldTo1_4 !== i_io_replay_2_bits_uop_vpu_fpu_isFoldTo1_4) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_fpu_isFoldTo1_4: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_fpu_isFoldTo1_4, i_io_replay_2_bits_uop_vpu_fpu_isFoldTo1_4); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_fpu_isFoldTo1_8 !== i_io_replay_2_bits_uop_vpu_fpu_isFoldTo1_8) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_fpu_isFoldTo1_8: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_fpu_isFoldTo1_8, i_io_replay_2_bits_uop_vpu_fpu_isFoldTo1_8); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_vxrm !== i_io_replay_2_bits_uop_vpu_vxrm) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_vxrm: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_vxrm, i_io_replay_2_bits_uop_vpu_vxrm); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_vuopIdx !== i_io_replay_2_bits_uop_vpu_vuopIdx) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_vuopIdx: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_vuopIdx, i_io_replay_2_bits_uop_vpu_vuopIdx); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_lastUop !== i_io_replay_2_bits_uop_vpu_lastUop) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_lastUop: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_lastUop, i_io_replay_2_bits_uop_vpu_lastUop); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_vmask !== i_io_replay_2_bits_uop_vpu_vmask) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_vmask: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_vmask, i_io_replay_2_bits_uop_vpu_vmask); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_vl !== i_io_replay_2_bits_uop_vpu_vl) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_vl: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_vl, i_io_replay_2_bits_uop_vpu_vl); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_nf !== i_io_replay_2_bits_uop_vpu_nf) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_nf: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_nf, i_io_replay_2_bits_uop_vpu_nf); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_veew !== i_io_replay_2_bits_uop_vpu_veew) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_veew: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_veew, i_io_replay_2_bits_uop_vpu_veew); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_isReverse !== i_io_replay_2_bits_uop_vpu_isReverse) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_isReverse: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_isReverse, i_io_replay_2_bits_uop_vpu_isReverse); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_isExt !== i_io_replay_2_bits_uop_vpu_isExt) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_isExt: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_isExt, i_io_replay_2_bits_uop_vpu_isExt); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_isNarrow !== i_io_replay_2_bits_uop_vpu_isNarrow) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_isNarrow: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_isNarrow, i_io_replay_2_bits_uop_vpu_isNarrow); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_isDstMask !== i_io_replay_2_bits_uop_vpu_isDstMask) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_isDstMask: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_isDstMask, i_io_replay_2_bits_uop_vpu_isDstMask); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_isOpMask !== i_io_replay_2_bits_uop_vpu_isOpMask) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_isOpMask: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_isOpMask, i_io_replay_2_bits_uop_vpu_isOpMask); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_isMove !== i_io_replay_2_bits_uop_vpu_isMove) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_isMove: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_isMove, i_io_replay_2_bits_uop_vpu_isMove); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_isDependOldVd !== i_io_replay_2_bits_uop_vpu_isDependOldVd) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_isDependOldVd: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_isDependOldVd, i_io_replay_2_bits_uop_vpu_isDependOldVd); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_isWritePartVd !== i_io_replay_2_bits_uop_vpu_isWritePartVd) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_isWritePartVd: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_isWritePartVd, i_io_replay_2_bits_uop_vpu_isWritePartVd); end
    checks++;
    if (g_io_replay_2_bits_uop_vpu_isVleff !== i_io_replay_2_bits_uop_vpu_isVleff) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vpu_isVleff: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vpu_isVleff, i_io_replay_2_bits_uop_vpu_isVleff); end
    checks++;
    if (g_io_replay_2_bits_uop_vlsInstr !== i_io_replay_2_bits_uop_vlsInstr) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_vlsInstr: g=%h i=%h", cyc, g_io_replay_2_bits_uop_vlsInstr, i_io_replay_2_bits_uop_vlsInstr); end
    checks++;
    if (g_io_replay_2_bits_uop_wfflags !== i_io_replay_2_bits_uop_wfflags) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_wfflags: g=%h i=%h", cyc, g_io_replay_2_bits_uop_wfflags, i_io_replay_2_bits_uop_wfflags); end
    checks++;
    if (g_io_replay_2_bits_uop_isMove !== i_io_replay_2_bits_uop_isMove) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_isMove: g=%h i=%h", cyc, g_io_replay_2_bits_uop_isMove, i_io_replay_2_bits_uop_isMove); end
    checks++;
    if (g_io_replay_2_bits_uop_isDropAmocasSta !== i_io_replay_2_bits_uop_isDropAmocasSta) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_isDropAmocasSta: g=%h i=%h", cyc, g_io_replay_2_bits_uop_isDropAmocasSta, i_io_replay_2_bits_uop_isDropAmocasSta); end
    checks++;
    if (g_io_replay_2_bits_uop_uopIdx !== i_io_replay_2_bits_uop_uopIdx) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_uopIdx: g=%h i=%h", cyc, g_io_replay_2_bits_uop_uopIdx, i_io_replay_2_bits_uop_uopIdx); end
    checks++;
    if (g_io_replay_2_bits_uop_isVset !== i_io_replay_2_bits_uop_isVset) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_isVset: g=%h i=%h", cyc, g_io_replay_2_bits_uop_isVset, i_io_replay_2_bits_uop_isVset); end
    checks++;
    if (g_io_replay_2_bits_uop_firstUop !== i_io_replay_2_bits_uop_firstUop) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_firstUop: g=%h i=%h", cyc, g_io_replay_2_bits_uop_firstUop, i_io_replay_2_bits_uop_firstUop); end
    checks++;
    if (g_io_replay_2_bits_uop_lastUop !== i_io_replay_2_bits_uop_lastUop) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_lastUop: g=%h i=%h", cyc, g_io_replay_2_bits_uop_lastUop, i_io_replay_2_bits_uop_lastUop); end
    checks++;
    if (g_io_replay_2_bits_uop_numUops !== i_io_replay_2_bits_uop_numUops) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_numUops: g=%h i=%h", cyc, g_io_replay_2_bits_uop_numUops, i_io_replay_2_bits_uop_numUops); end
    checks++;
    if (g_io_replay_2_bits_uop_numWB !== i_io_replay_2_bits_uop_numWB) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_numWB: g=%h i=%h", cyc, g_io_replay_2_bits_uop_numWB, i_io_replay_2_bits_uop_numWB); end
    checks++;
    if (g_io_replay_2_bits_uop_commitType !== i_io_replay_2_bits_uop_commitType) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_commitType: g=%h i=%h", cyc, g_io_replay_2_bits_uop_commitType, i_io_replay_2_bits_uop_commitType); end
    checks++;
    if (g_io_replay_2_bits_uop_srcState_0 !== i_io_replay_2_bits_uop_srcState_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_srcState_0: g=%h i=%h", cyc, g_io_replay_2_bits_uop_srcState_0, i_io_replay_2_bits_uop_srcState_0); end
    checks++;
    if (g_io_replay_2_bits_uop_srcState_1 !== i_io_replay_2_bits_uop_srcState_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_srcState_1: g=%h i=%h", cyc, g_io_replay_2_bits_uop_srcState_1, i_io_replay_2_bits_uop_srcState_1); end
    checks++;
    if (g_io_replay_2_bits_uop_srcState_2 !== i_io_replay_2_bits_uop_srcState_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_srcState_2: g=%h i=%h", cyc, g_io_replay_2_bits_uop_srcState_2, i_io_replay_2_bits_uop_srcState_2); end
    checks++;
    if (g_io_replay_2_bits_uop_srcState_3 !== i_io_replay_2_bits_uop_srcState_3) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_srcState_3: g=%h i=%h", cyc, g_io_replay_2_bits_uop_srcState_3, i_io_replay_2_bits_uop_srcState_3); end
    checks++;
    if (g_io_replay_2_bits_uop_srcState_4 !== i_io_replay_2_bits_uop_srcState_4) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_srcState_4: g=%h i=%h", cyc, g_io_replay_2_bits_uop_srcState_4, i_io_replay_2_bits_uop_srcState_4); end
    checks++;
    if (g_io_replay_2_bits_uop_srcLoadDependency_0_0 !== i_io_replay_2_bits_uop_srcLoadDependency_0_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_srcLoadDependency_0_0: g=%h i=%h", cyc, g_io_replay_2_bits_uop_srcLoadDependency_0_0, i_io_replay_2_bits_uop_srcLoadDependency_0_0); end
    checks++;
    if (g_io_replay_2_bits_uop_srcLoadDependency_0_1 !== i_io_replay_2_bits_uop_srcLoadDependency_0_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_srcLoadDependency_0_1: g=%h i=%h", cyc, g_io_replay_2_bits_uop_srcLoadDependency_0_1, i_io_replay_2_bits_uop_srcLoadDependency_0_1); end
    checks++;
    if (g_io_replay_2_bits_uop_srcLoadDependency_0_2 !== i_io_replay_2_bits_uop_srcLoadDependency_0_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_srcLoadDependency_0_2: g=%h i=%h", cyc, g_io_replay_2_bits_uop_srcLoadDependency_0_2, i_io_replay_2_bits_uop_srcLoadDependency_0_2); end
    checks++;
    if (g_io_replay_2_bits_uop_srcLoadDependency_1_0 !== i_io_replay_2_bits_uop_srcLoadDependency_1_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_srcLoadDependency_1_0: g=%h i=%h", cyc, g_io_replay_2_bits_uop_srcLoadDependency_1_0, i_io_replay_2_bits_uop_srcLoadDependency_1_0); end
    checks++;
    if (g_io_replay_2_bits_uop_srcLoadDependency_1_1 !== i_io_replay_2_bits_uop_srcLoadDependency_1_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_srcLoadDependency_1_1: g=%h i=%h", cyc, g_io_replay_2_bits_uop_srcLoadDependency_1_1, i_io_replay_2_bits_uop_srcLoadDependency_1_1); end
    checks++;
    if (g_io_replay_2_bits_uop_srcLoadDependency_1_2 !== i_io_replay_2_bits_uop_srcLoadDependency_1_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_srcLoadDependency_1_2: g=%h i=%h", cyc, g_io_replay_2_bits_uop_srcLoadDependency_1_2, i_io_replay_2_bits_uop_srcLoadDependency_1_2); end
    checks++;
    if (g_io_replay_2_bits_uop_srcLoadDependency_2_0 !== i_io_replay_2_bits_uop_srcLoadDependency_2_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_srcLoadDependency_2_0: g=%h i=%h", cyc, g_io_replay_2_bits_uop_srcLoadDependency_2_0, i_io_replay_2_bits_uop_srcLoadDependency_2_0); end
    checks++;
    if (g_io_replay_2_bits_uop_srcLoadDependency_2_1 !== i_io_replay_2_bits_uop_srcLoadDependency_2_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_srcLoadDependency_2_1: g=%h i=%h", cyc, g_io_replay_2_bits_uop_srcLoadDependency_2_1, i_io_replay_2_bits_uop_srcLoadDependency_2_1); end
    checks++;
    if (g_io_replay_2_bits_uop_srcLoadDependency_2_2 !== i_io_replay_2_bits_uop_srcLoadDependency_2_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_srcLoadDependency_2_2: g=%h i=%h", cyc, g_io_replay_2_bits_uop_srcLoadDependency_2_2, i_io_replay_2_bits_uop_srcLoadDependency_2_2); end
    checks++;
    if (g_io_replay_2_bits_uop_srcLoadDependency_3_0 !== i_io_replay_2_bits_uop_srcLoadDependency_3_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_srcLoadDependency_3_0: g=%h i=%h", cyc, g_io_replay_2_bits_uop_srcLoadDependency_3_0, i_io_replay_2_bits_uop_srcLoadDependency_3_0); end
    checks++;
    if (g_io_replay_2_bits_uop_srcLoadDependency_3_1 !== i_io_replay_2_bits_uop_srcLoadDependency_3_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_srcLoadDependency_3_1: g=%h i=%h", cyc, g_io_replay_2_bits_uop_srcLoadDependency_3_1, i_io_replay_2_bits_uop_srcLoadDependency_3_1); end
    checks++;
    if (g_io_replay_2_bits_uop_srcLoadDependency_3_2 !== i_io_replay_2_bits_uop_srcLoadDependency_3_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_srcLoadDependency_3_2: g=%h i=%h", cyc, g_io_replay_2_bits_uop_srcLoadDependency_3_2, i_io_replay_2_bits_uop_srcLoadDependency_3_2); end
    checks++;
    if (g_io_replay_2_bits_uop_srcLoadDependency_4_0 !== i_io_replay_2_bits_uop_srcLoadDependency_4_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_srcLoadDependency_4_0: g=%h i=%h", cyc, g_io_replay_2_bits_uop_srcLoadDependency_4_0, i_io_replay_2_bits_uop_srcLoadDependency_4_0); end
    checks++;
    if (g_io_replay_2_bits_uop_srcLoadDependency_4_1 !== i_io_replay_2_bits_uop_srcLoadDependency_4_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_srcLoadDependency_4_1: g=%h i=%h", cyc, g_io_replay_2_bits_uop_srcLoadDependency_4_1, i_io_replay_2_bits_uop_srcLoadDependency_4_1); end
    checks++;
    if (g_io_replay_2_bits_uop_srcLoadDependency_4_2 !== i_io_replay_2_bits_uop_srcLoadDependency_4_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_srcLoadDependency_4_2: g=%h i=%h", cyc, g_io_replay_2_bits_uop_srcLoadDependency_4_2, i_io_replay_2_bits_uop_srcLoadDependency_4_2); end
    checks++;
    if (g_io_replay_2_bits_uop_psrc_0 !== i_io_replay_2_bits_uop_psrc_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_psrc_0: g=%h i=%h", cyc, g_io_replay_2_bits_uop_psrc_0, i_io_replay_2_bits_uop_psrc_0); end
    checks++;
    if (g_io_replay_2_bits_uop_psrc_1 !== i_io_replay_2_bits_uop_psrc_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_psrc_1: g=%h i=%h", cyc, g_io_replay_2_bits_uop_psrc_1, i_io_replay_2_bits_uop_psrc_1); end
    checks++;
    if (g_io_replay_2_bits_uop_psrc_2 !== i_io_replay_2_bits_uop_psrc_2) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_psrc_2: g=%h i=%h", cyc, g_io_replay_2_bits_uop_psrc_2, i_io_replay_2_bits_uop_psrc_2); end
    checks++;
    if (g_io_replay_2_bits_uop_psrc_3 !== i_io_replay_2_bits_uop_psrc_3) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_psrc_3: g=%h i=%h", cyc, g_io_replay_2_bits_uop_psrc_3, i_io_replay_2_bits_uop_psrc_3); end
    checks++;
    if (g_io_replay_2_bits_uop_psrc_4 !== i_io_replay_2_bits_uop_psrc_4) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_psrc_4: g=%h i=%h", cyc, g_io_replay_2_bits_uop_psrc_4, i_io_replay_2_bits_uop_psrc_4); end
    checks++;
    if (g_io_replay_2_bits_uop_pdest !== i_io_replay_2_bits_uop_pdest) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_pdest: g=%h i=%h", cyc, g_io_replay_2_bits_uop_pdest, i_io_replay_2_bits_uop_pdest); end
    checks++;
    if (g_io_replay_2_bits_uop_useRegCache_0 !== i_io_replay_2_bits_uop_useRegCache_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_useRegCache_0: g=%h i=%h", cyc, g_io_replay_2_bits_uop_useRegCache_0, i_io_replay_2_bits_uop_useRegCache_0); end
    checks++;
    if (g_io_replay_2_bits_uop_useRegCache_1 !== i_io_replay_2_bits_uop_useRegCache_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_useRegCache_1: g=%h i=%h", cyc, g_io_replay_2_bits_uop_useRegCache_1, i_io_replay_2_bits_uop_useRegCache_1); end
    checks++;
    if (g_io_replay_2_bits_uop_regCacheIdx_0 !== i_io_replay_2_bits_uop_regCacheIdx_0) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_regCacheIdx_0: g=%h i=%h", cyc, g_io_replay_2_bits_uop_regCacheIdx_0, i_io_replay_2_bits_uop_regCacheIdx_0); end
    checks++;
    if (g_io_replay_2_bits_uop_regCacheIdx_1 !== i_io_replay_2_bits_uop_regCacheIdx_1) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_regCacheIdx_1: g=%h i=%h", cyc, g_io_replay_2_bits_uop_regCacheIdx_1, i_io_replay_2_bits_uop_regCacheIdx_1); end
    checks++;
    if (g_io_replay_2_bits_uop_robIdx_flag !== i_io_replay_2_bits_uop_robIdx_flag) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_robIdx_flag: g=%h i=%h", cyc, g_io_replay_2_bits_uop_robIdx_flag, i_io_replay_2_bits_uop_robIdx_flag); end
    checks++;
    if (g_io_replay_2_bits_uop_robIdx_value !== i_io_replay_2_bits_uop_robIdx_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_robIdx_value: g=%h i=%h", cyc, g_io_replay_2_bits_uop_robIdx_value, i_io_replay_2_bits_uop_robIdx_value); end
    checks++;
    if (g_io_replay_2_bits_uop_instrSize !== i_io_replay_2_bits_uop_instrSize) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_instrSize: g=%h i=%h", cyc, g_io_replay_2_bits_uop_instrSize, i_io_replay_2_bits_uop_instrSize); end
    checks++;
    if (g_io_replay_2_bits_uop_dirtyFs !== i_io_replay_2_bits_uop_dirtyFs) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_dirtyFs: g=%h i=%h", cyc, g_io_replay_2_bits_uop_dirtyFs, i_io_replay_2_bits_uop_dirtyFs); end
    checks++;
    if (g_io_replay_2_bits_uop_dirtyVs !== i_io_replay_2_bits_uop_dirtyVs) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_dirtyVs: g=%h i=%h", cyc, g_io_replay_2_bits_uop_dirtyVs, i_io_replay_2_bits_uop_dirtyVs); end
    checks++;
    if (g_io_replay_2_bits_uop_traceBlockInPipe_itype !== i_io_replay_2_bits_uop_traceBlockInPipe_itype) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_traceBlockInPipe_itype: g=%h i=%h", cyc, g_io_replay_2_bits_uop_traceBlockInPipe_itype, i_io_replay_2_bits_uop_traceBlockInPipe_itype); end
    checks++;
    if (g_io_replay_2_bits_uop_traceBlockInPipe_iretire !== i_io_replay_2_bits_uop_traceBlockInPipe_iretire) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_traceBlockInPipe_iretire: g=%h i=%h", cyc, g_io_replay_2_bits_uop_traceBlockInPipe_iretire, i_io_replay_2_bits_uop_traceBlockInPipe_iretire); end
    checks++;
    if (g_io_replay_2_bits_uop_traceBlockInPipe_ilastsize !== i_io_replay_2_bits_uop_traceBlockInPipe_ilastsize) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_traceBlockInPipe_ilastsize: g=%h i=%h", cyc, g_io_replay_2_bits_uop_traceBlockInPipe_ilastsize, i_io_replay_2_bits_uop_traceBlockInPipe_ilastsize); end
    checks++;
    if (g_io_replay_2_bits_uop_eliminatedMove !== i_io_replay_2_bits_uop_eliminatedMove) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_eliminatedMove: g=%h i=%h", cyc, g_io_replay_2_bits_uop_eliminatedMove, i_io_replay_2_bits_uop_eliminatedMove); end
    checks++;
    if (g_io_replay_2_bits_uop_snapshot !== i_io_replay_2_bits_uop_snapshot) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_snapshot: g=%h i=%h", cyc, g_io_replay_2_bits_uop_snapshot, i_io_replay_2_bits_uop_snapshot); end
    checks++;
    if (g_io_replay_2_bits_uop_debugInfo_eliminatedMove !== i_io_replay_2_bits_uop_debugInfo_eliminatedMove) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_debugInfo_eliminatedMove: g=%h i=%h", cyc, g_io_replay_2_bits_uop_debugInfo_eliminatedMove, i_io_replay_2_bits_uop_debugInfo_eliminatedMove); end
    checks++;
    if (g_io_replay_2_bits_uop_debugInfo_renameTime !== i_io_replay_2_bits_uop_debugInfo_renameTime) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_debugInfo_renameTime: g=%h i=%h", cyc, g_io_replay_2_bits_uop_debugInfo_renameTime, i_io_replay_2_bits_uop_debugInfo_renameTime); end
    checks++;
    if (g_io_replay_2_bits_uop_debugInfo_dispatchTime !== i_io_replay_2_bits_uop_debugInfo_dispatchTime) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_debugInfo_dispatchTime: g=%h i=%h", cyc, g_io_replay_2_bits_uop_debugInfo_dispatchTime, i_io_replay_2_bits_uop_debugInfo_dispatchTime); end
    checks++;
    if (g_io_replay_2_bits_uop_debugInfo_enqRsTime !== i_io_replay_2_bits_uop_debugInfo_enqRsTime) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_debugInfo_enqRsTime: g=%h i=%h", cyc, g_io_replay_2_bits_uop_debugInfo_enqRsTime, i_io_replay_2_bits_uop_debugInfo_enqRsTime); end
    checks++;
    if (g_io_replay_2_bits_uop_debugInfo_selectTime !== i_io_replay_2_bits_uop_debugInfo_selectTime) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_debugInfo_selectTime: g=%h i=%h", cyc, g_io_replay_2_bits_uop_debugInfo_selectTime, i_io_replay_2_bits_uop_debugInfo_selectTime); end
    checks++;
    if (g_io_replay_2_bits_uop_debugInfo_issueTime !== i_io_replay_2_bits_uop_debugInfo_issueTime) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_debugInfo_issueTime: g=%h i=%h", cyc, g_io_replay_2_bits_uop_debugInfo_issueTime, i_io_replay_2_bits_uop_debugInfo_issueTime); end
    checks++;
    if (g_io_replay_2_bits_uop_debugInfo_writebackTime !== i_io_replay_2_bits_uop_debugInfo_writebackTime) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_debugInfo_writebackTime: g=%h i=%h", cyc, g_io_replay_2_bits_uop_debugInfo_writebackTime, i_io_replay_2_bits_uop_debugInfo_writebackTime); end
    checks++;
    if (g_io_replay_2_bits_uop_debugInfo_runahead_checkpoint_id !== i_io_replay_2_bits_uop_debugInfo_runahead_checkpoint_id) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_debugInfo_runahead_checkpoint_id: g=%h i=%h", cyc, g_io_replay_2_bits_uop_debugInfo_runahead_checkpoint_id, i_io_replay_2_bits_uop_debugInfo_runahead_checkpoint_id); end
    checks++;
    if (g_io_replay_2_bits_uop_debugInfo_tlbFirstReqTime !== i_io_replay_2_bits_uop_debugInfo_tlbFirstReqTime) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_debugInfo_tlbFirstReqTime: g=%h i=%h", cyc, g_io_replay_2_bits_uop_debugInfo_tlbFirstReqTime, i_io_replay_2_bits_uop_debugInfo_tlbFirstReqTime); end
    checks++;
    if (g_io_replay_2_bits_uop_debugInfo_tlbRespTime !== i_io_replay_2_bits_uop_debugInfo_tlbRespTime) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_debugInfo_tlbRespTime: g=%h i=%h", cyc, g_io_replay_2_bits_uop_debugInfo_tlbRespTime, i_io_replay_2_bits_uop_debugInfo_tlbRespTime); end
    checks++;
    if (g_io_replay_2_bits_uop_debug_seqNum_seqNum !== i_io_replay_2_bits_uop_debug_seqNum_seqNum) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_debug_seqNum_seqNum: g=%h i=%h", cyc, g_io_replay_2_bits_uop_debug_seqNum_seqNum, i_io_replay_2_bits_uop_debug_seqNum_seqNum); end
    checks++;
    if (g_io_replay_2_bits_uop_debug_seqNum_uopIdx !== i_io_replay_2_bits_uop_debug_seqNum_uopIdx) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_debug_seqNum_uopIdx: g=%h i=%h", cyc, g_io_replay_2_bits_uop_debug_seqNum_uopIdx, i_io_replay_2_bits_uop_debug_seqNum_uopIdx); end
    checks++;
    if (g_io_replay_2_bits_uop_storeSetHit !== i_io_replay_2_bits_uop_storeSetHit) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_storeSetHit: g=%h i=%h", cyc, g_io_replay_2_bits_uop_storeSetHit, i_io_replay_2_bits_uop_storeSetHit); end
    checks++;
    if (g_io_replay_2_bits_uop_waitForRobIdx_flag !== i_io_replay_2_bits_uop_waitForRobIdx_flag) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_waitForRobIdx_flag: g=%h i=%h", cyc, g_io_replay_2_bits_uop_waitForRobIdx_flag, i_io_replay_2_bits_uop_waitForRobIdx_flag); end
    checks++;
    if (g_io_replay_2_bits_uop_waitForRobIdx_value !== i_io_replay_2_bits_uop_waitForRobIdx_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_waitForRobIdx_value: g=%h i=%h", cyc, g_io_replay_2_bits_uop_waitForRobIdx_value, i_io_replay_2_bits_uop_waitForRobIdx_value); end
    checks++;
    if (g_io_replay_2_bits_uop_loadWaitBit !== i_io_replay_2_bits_uop_loadWaitBit) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_loadWaitBit: g=%h i=%h", cyc, g_io_replay_2_bits_uop_loadWaitBit, i_io_replay_2_bits_uop_loadWaitBit); end
    checks++;
    if (g_io_replay_2_bits_uop_ssid !== i_io_replay_2_bits_uop_ssid) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_ssid: g=%h i=%h", cyc, g_io_replay_2_bits_uop_ssid, i_io_replay_2_bits_uop_ssid); end
    checks++;
    if (g_io_replay_2_bits_uop_lqIdx_flag !== i_io_replay_2_bits_uop_lqIdx_flag) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_lqIdx_flag: g=%h i=%h", cyc, g_io_replay_2_bits_uop_lqIdx_flag, i_io_replay_2_bits_uop_lqIdx_flag); end
    checks++;
    if (g_io_replay_2_bits_uop_lqIdx_value !== i_io_replay_2_bits_uop_lqIdx_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_lqIdx_value: g=%h i=%h", cyc, g_io_replay_2_bits_uop_lqIdx_value, i_io_replay_2_bits_uop_lqIdx_value); end
    checks++;
    if (g_io_replay_2_bits_uop_sqIdx_flag !== i_io_replay_2_bits_uop_sqIdx_flag) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_sqIdx_flag: g=%h i=%h", cyc, g_io_replay_2_bits_uop_sqIdx_flag, i_io_replay_2_bits_uop_sqIdx_flag); end
    checks++;
    if (g_io_replay_2_bits_uop_sqIdx_value !== i_io_replay_2_bits_uop_sqIdx_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_sqIdx_value: g=%h i=%h", cyc, g_io_replay_2_bits_uop_sqIdx_value, i_io_replay_2_bits_uop_sqIdx_value); end
    checks++;
    if (g_io_replay_2_bits_uop_singleStep !== i_io_replay_2_bits_uop_singleStep) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_singleStep: g=%h i=%h", cyc, g_io_replay_2_bits_uop_singleStep, i_io_replay_2_bits_uop_singleStep); end
    checks++;
    if (g_io_replay_2_bits_uop_debug_fuType !== i_io_replay_2_bits_uop_debug_fuType) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_debug_fuType: g=%h i=%h", cyc, g_io_replay_2_bits_uop_debug_fuType, i_io_replay_2_bits_uop_debug_fuType); end
    checks++;
    if (g_io_replay_2_bits_uop_debug_sim_trig !== i_io_replay_2_bits_uop_debug_sim_trig) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_debug_sim_trig: g=%h i=%h", cyc, g_io_replay_2_bits_uop_debug_sim_trig, i_io_replay_2_bits_uop_debug_sim_trig); end
    checks++;
    if (g_io_replay_2_bits_uop_numLsElem !== i_io_replay_2_bits_uop_numLsElem) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_uop_numLsElem: g=%h i=%h", cyc, g_io_replay_2_bits_uop_numLsElem, i_io_replay_2_bits_uop_numLsElem); end
    checks++;
    if (g_io_replay_2_bits_vaddr !== i_io_replay_2_bits_vaddr) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_vaddr: g=%h i=%h", cyc, g_io_replay_2_bits_vaddr, i_io_replay_2_bits_vaddr); end
    checks++;
    if (g_io_replay_2_bits_mask !== i_io_replay_2_bits_mask) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_mask: g=%h i=%h", cyc, g_io_replay_2_bits_mask, i_io_replay_2_bits_mask); end
    checks++;
    if (g_io_replay_2_bits_isvec !== i_io_replay_2_bits_isvec) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_isvec: g=%h i=%h", cyc, g_io_replay_2_bits_isvec, i_io_replay_2_bits_isvec); end
    checks++;
    if (g_io_replay_2_bits_is128bit !== i_io_replay_2_bits_is128bit) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_is128bit: g=%h i=%h", cyc, g_io_replay_2_bits_is128bit, i_io_replay_2_bits_is128bit); end
    checks++;
    if (g_io_replay_2_bits_elemIdx !== i_io_replay_2_bits_elemIdx) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_elemIdx: g=%h i=%h", cyc, g_io_replay_2_bits_elemIdx, i_io_replay_2_bits_elemIdx); end
    checks++;
    if (g_io_replay_2_bits_alignedType !== i_io_replay_2_bits_alignedType) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_alignedType: g=%h i=%h", cyc, g_io_replay_2_bits_alignedType, i_io_replay_2_bits_alignedType); end
    checks++;
    if (g_io_replay_2_bits_mbIndex !== i_io_replay_2_bits_mbIndex) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_mbIndex: g=%h i=%h", cyc, g_io_replay_2_bits_mbIndex, i_io_replay_2_bits_mbIndex); end
    checks++;
    if (g_io_replay_2_bits_reg_offset !== i_io_replay_2_bits_reg_offset) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_reg_offset: g=%h i=%h", cyc, g_io_replay_2_bits_reg_offset, i_io_replay_2_bits_reg_offset); end
    checks++;
    if (g_io_replay_2_bits_elemIdxInsideVd !== i_io_replay_2_bits_elemIdxInsideVd) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_elemIdxInsideVd: g=%h i=%h", cyc, g_io_replay_2_bits_elemIdxInsideVd, i_io_replay_2_bits_elemIdxInsideVd); end
    checks++;
    if (g_io_replay_2_bits_vecActive !== i_io_replay_2_bits_vecActive) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_vecActive: g=%h i=%h", cyc, g_io_replay_2_bits_vecActive, i_io_replay_2_bits_vecActive); end
    checks++;
    if (g_io_replay_2_bits_mshrid !== i_io_replay_2_bits_mshrid) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_mshrid: g=%h i=%h", cyc, g_io_replay_2_bits_mshrid, i_io_replay_2_bits_mshrid); end
    checks++;
    if (g_io_replay_2_bits_forward_tlDchannel !== i_io_replay_2_bits_forward_tlDchannel) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_forward_tlDchannel: g=%h i=%h", cyc, g_io_replay_2_bits_forward_tlDchannel, i_io_replay_2_bits_forward_tlDchannel); end
    checks++;
    if (g_io_replay_2_bits_schedIndex !== i_io_replay_2_bits_schedIndex) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replay_2_bits_schedIndex: g=%h i=%h", cyc, g_io_replay_2_bits_schedIndex, i_io_replay_2_bits_schedIndex); end
    checks++;
    if (g_io_lqFull !== i_io_lqFull) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_lqFull: g=%h i=%h", cyc, g_io_lqFull, i_io_lqFull); end
    checks++;
    if (g_io_debugTopDown_robHeadTlbReplay !== i_io_debugTopDown_robHeadTlbReplay) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_debugTopDown_robHeadTlbReplay: g=%h i=%h", cyc, g_io_debugTopDown_robHeadTlbReplay, i_io_debugTopDown_robHeadTlbReplay); end
    checks++;
    if (g_io_debugTopDown_robHeadTlbMiss !== i_io_debugTopDown_robHeadTlbMiss) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_debugTopDown_robHeadTlbMiss: g=%h i=%h", cyc, g_io_debugTopDown_robHeadTlbMiss, i_io_debugTopDown_robHeadTlbMiss); end
    checks++;
    if (g_io_debugTopDown_robHeadLoadVio !== i_io_debugTopDown_robHeadLoadVio) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_debugTopDown_robHeadLoadVio: g=%h i=%h", cyc, g_io_debugTopDown_robHeadLoadVio, i_io_debugTopDown_robHeadLoadVio); end
    checks++;
    if (g_io_debugTopDown_robHeadLoadMSHR !== i_io_debugTopDown_robHeadLoadMSHR) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_debugTopDown_robHeadLoadMSHR: g=%h i=%h", cyc, g_io_debugTopDown_robHeadLoadMSHR, i_io_debugTopDown_robHeadLoadMSHR); end
    checks++;
    if (g_io_replayAllocate !== i_io_replayAllocate) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_replayAllocate: g=%h i=%h", cyc, g_io_replayAllocate, i_io_replayAllocate); end
    checks++;
    if (g_io_perf_0_value !== i_io_perf_0_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_perf_0_value: g=%h i=%h", cyc, g_io_perf_0_value, i_io_perf_0_value); end
    checks++;
    if (g_io_perf_1_value !== i_io_perf_1_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_perf_1_value: g=%h i=%h", cyc, g_io_perf_1_value, i_io_perf_1_value); end
    checks++;
    if (g_io_perf_2_value !== i_io_perf_2_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_perf_2_value: g=%h i=%h", cyc, g_io_perf_2_value, i_io_perf_2_value); end
    checks++;
    if (g_io_perf_3_value !== i_io_perf_3_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_perf_3_value: g=%h i=%h", cyc, g_io_perf_3_value, i_io_perf_3_value); end
    checks++;
    if (g_io_perf_4_value !== i_io_perf_4_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_perf_4_value: g=%h i=%h", cyc, g_io_perf_4_value, i_io_perf_4_value); end
    checks++;
    if (g_io_perf_5_value !== i_io_perf_5_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_perf_5_value: g=%h i=%h", cyc, g_io_perf_5_value, i_io_perf_5_value); end
    checks++;
    if (g_io_perf_6_value !== i_io_perf_6_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_perf_6_value: g=%h i=%h", cyc, g_io_perf_6_value, i_io_perf_6_value); end
    checks++;
    if (g_io_perf_7_value !== i_io_perf_7_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_perf_7_value: g=%h i=%h", cyc, g_io_perf_7_value, i_io_perf_7_value); end
    checks++;
    if (g_io_perf_8_value !== i_io_perf_8_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_perf_8_value: g=%h i=%h", cyc, g_io_perf_8_value, i_io_perf_8_value); end
    checks++;
    if (g_io_perf_9_value !== i_io_perf_9_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_perf_9_value: g=%h i=%h", cyc, g_io_perf_9_value, i_io_perf_9_value); end
    checks++;
    if (g_io_perf_10_value !== i_io_perf_10_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_perf_10_value: g=%h i=%h", cyc, g_io_perf_10_value, i_io_perf_10_value); end
    checks++;
    if (g_io_perf_11_value !== i_io_perf_11_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_perf_11_value: g=%h i=%h", cyc, g_io_perf_11_value, i_io_perf_11_value); end
    checks++;
    if (g_io_perf_12_value !== i_io_perf_12_value) begin errors++;
      if (errors < 20) $display("[%0d] MISMATCH io_perf_12_value: g=%h i=%h", cyc, g_io_perf_12_value, i_io_perf_12_value); end
    checks++;
  endtask

  // ---- 覆盖统计 ----
  task automatic sample_cov();
    for (int c = 0; c < 11; c++) begin
      if (io_enq_0_valid && cause_bit(0, c)) cov_cause[c]++;
      if (io_enq_1_valid && cause_bit(1, c)) cov_cause[c]++;
      if (io_enq_2_valid && cause_bit(2, c)) cov_cause[c]++;
    end
    if (g_io_replay_0_valid && rep_rdy[0]) cov_replay_fire++;
    if (g_io_replay_1_valid && rep_rdy[1]) cov_replay_fire++;
    if (g_io_replay_2_valid && rep_rdy[2]) cov_replay_fire++;
    if (g_io_replay_0_valid && !rep_rdy[0]) cov_replay_stall++;
    if (g_io_lqFull)          cov_lqfull++;
    if (g_io_replayAllocate)  cov_allocate++;
    if (io_redirect_valid)    cov_redirect++;
    if (io_enq_0_bits_isLoadReplay && io_enq_0_valid) cov_loadreplay++;
    if (io_enq_0_bits_isLoadReplay && io_enq_0_valid && !any_cause(0)) cov_lr_free++;
    if (io_l2_hint_valid)     cov_l2hint++;
    if (io_tlb_hint_resp_valid) cov_tlbhint++;
    if (io_tl_d_channel_valid)  cov_tld++;
    if (prev_tld_v && io_enq_0_valid && io_enq_0_bits_handledByMSHR
        && cause_bit(0, 4) && prev_tld_id == io_enq_0_bits_rep_info_mshr_id) cov_tld_prev++;
    if (io_enq_0_valid && cause_bit(0, 10)) cov_mf_block++;
    if (io_enq_0_valid && cause_bit(0, 10)
        && !((io_enq_0_bits_uop_robIdx_flag ^ io_robDeqPtr_flag)
             ^ (io_enq_0_bits_uop_robIdx_value > io_robDeqPtr_value))) cov_mf_release++;
    if (vfb_v[0] || vfb_v[1]) cov_vecfb++;
    if (g_io_debugTopDown_robHeadTlbReplay || g_io_debugTopDown_robHeadTlbMiss
        || g_io_debugTopDown_robHeadLoadVio || g_io_debugTopDown_robHeadLoadMSHR) cov_topdown++;
  endtask

  function automatic bit cause_bit(input int w, input int c);
    bit [10:0] v;
    case (w)
      0: v = {io_enq_0_bits_rep_info_cause_10, io_enq_0_bits_rep_info_cause_9,
              io_enq_0_bits_rep_info_cause_8,  io_enq_0_bits_rep_info_cause_7,
              io_enq_0_bits_rep_info_cause_6,  io_enq_0_bits_rep_info_cause_5,
              io_enq_0_bits_rep_info_cause_4,  io_enq_0_bits_rep_info_cause_3,
              io_enq_0_bits_rep_info_cause_2,  io_enq_0_bits_rep_info_cause_1,
              io_enq_0_bits_rep_info_cause_0};
      1: v = {io_enq_1_bits_rep_info_cause_10, io_enq_1_bits_rep_info_cause_9,
              io_enq_1_bits_rep_info_cause_8,  io_enq_1_bits_rep_info_cause_7,
              io_enq_1_bits_rep_info_cause_6,  io_enq_1_bits_rep_info_cause_5,
              io_enq_1_bits_rep_info_cause_4,  io_enq_1_bits_rep_info_cause_3,
              io_enq_1_bits_rep_info_cause_2,  io_enq_1_bits_rep_info_cause_1,
              io_enq_1_bits_rep_info_cause_0};
      default: v = {io_enq_2_bits_rep_info_cause_10, io_enq_2_bits_rep_info_cause_9,
              io_enq_2_bits_rep_info_cause_8,  io_enq_2_bits_rep_info_cause_7,
              io_enq_2_bits_rep_info_cause_6,  io_enq_2_bits_rep_info_cause_5,
              io_enq_2_bits_rep_info_cause_4,  io_enq_2_bits_rep_info_cause_3,
              io_enq_2_bits_rep_info_cause_2,  io_enq_2_bits_rep_info_cause_1,
              io_enq_2_bits_rep_info_cause_0};
    endcase
    return v[c];
  endfunction

  function automatic bit any_cause(input int w);
    bit r;
    r = 1'b0;
    for (int c = 0; c < 11; c++) if (cause_bit(w, c)) r = 1'b1;
    return r;
  endfunction

  // ---- 主循环 ----
  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int c = 0; c < 11; c++) cov_cause[c] = 0;
    rst = 1'b1;
    phase = 0;
    drive_payload();
    drive_env(1'b1);
    for (int w = 0; w < 3; w++) drive_enq(w, 1'b1);
    repeat (6) @(posedge clk);
    rst = 1'b0;

    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      automatic bit warm;
      warm = (cyc < WARM);
      // 相位每 2000 拍轮转一次（8 个相位）
      phase = warm ? 0 : ((cyc / 2000) % 8);
      @(negedge clk);
      // 从重放输出里回收 schedIndex，供 isLoadReplay 回流用
      if (g_io_replay_0_valid && rep_rdy[0]) lr_pool.push_back(g_io_replay_0_bits_schedIndex);
      if (g_io_replay_1_valid && rep_rdy[1]) lr_pool.push_back(g_io_replay_1_bits_schedIndex);
      if (g_io_replay_2_valid && rep_rdy[2]) lr_pool.push_back(g_io_replay_2_bits_schedIndex);
      while (lr_pool.size() > 64) void'(lr_pool.pop_front());
      if (!warm) begin
        check_outputs();
        sample_cov();
      end
      drive_payload();
      drive_env(warm);
      for (int w = 0; w < 3; w++) drive_enq(w, warm);
      @(posedge clk);
    end

    $display("=== LoadQueueReplay UT: cycles=%0d checks=%0d errors=%0d ===", NCYCLES, checks, errors);
    $display("--- coverage ---");
    for (int c = 0; c < 11; c++) $display("  cov_cause[%0d]      = %0d", c, cov_cause[c]);
    $display("  cov_replay_fire   = %0d", cov_replay_fire);
    $display("  cov_replay_stall  = %0d", cov_replay_stall);
    $display("  cov_lqfull        = %0d", cov_lqfull);
    $display("  cov_allocate      = %0d", cov_allocate);
    $display("  cov_redirect      = %0d", cov_redirect);
    $display("  cov_loadreplay    = %0d", cov_loadreplay);
    $display("  cov_lr_free       = %0d", cov_lr_free);
    $display("  cov_l2hint        = %0d", cov_l2hint);
    $display("  cov_tlbhint       = %0d", cov_tlbhint);
    $display("  cov_tld           = %0d", cov_tld);
    $display("  cov_tld_prev      = %0d", cov_tld_prev);
    $display("  cov_mf_block      = %0d", cov_mf_block);
    $display("  cov_mf_release    = %0d", cov_mf_release);
    $display("  cov_vecfb         = %0d", cov_vecfb);
    $display("  cov_topdown       = %0d", cov_topdown);
    begin
      automatic bit cov_ok = 1'b1;
      for (int c = 0; c < 11; c++) if (cov_cause[c] == 0) cov_ok = 1'b0;
      if (cov_replay_fire == 0 || cov_replay_stall == 0 || cov_lqfull == 0
          || cov_redirect == 0 || cov_loadreplay == 0 || cov_lr_free == 0
          || cov_l2hint == 0 || cov_tlbhint == 0 || cov_tld == 0 || cov_tld_prev == 0
          || cov_mf_block == 0 || cov_mf_release == 0 || cov_vecfb == 0
          || cov_topdown == 0 || cov_allocate == 0) cov_ok = 1'b0;
      // ★errors=0 单独不算数：覆盖闸有任何一个桶为 0 就判 FAIL★
      if (errors == 0 && checks > 0 && cov_ok) $display("TEST PASSED");
      else $display("TEST FAILED (errors=%0d checks=%0d cov_ok=%0b)", errors, checks, cov_ok);
    end
    $finish;
  end
endmodule
