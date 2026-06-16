// 自动生成：scripts/gen_loadqueuereplay.py —— 勿手改
module LoadQueueReplay_xs(
  input clock,
  input reset,
  input io_redirect_valid,
  input io_redirect_bits_robIdx_flag,
  input [7:0] io_redirect_bits_robIdx_value,
  input io_redirect_bits_level,
  input io_vecFeedback_0_valid,
  input io_vecFeedback_0_bits_robidx_flag,
  input [7:0] io_vecFeedback_0_bits_robidx_value,
  input [6:0] io_vecFeedback_0_bits_uopidx,
  input io_vecFeedback_0_bits_feedback_0,
  input io_vecFeedback_0_bits_feedback_1,
  input io_vecFeedback_1_valid,
  input io_vecFeedback_1_bits_robidx_flag,
  input [7:0] io_vecFeedback_1_bits_robidx_value,
  input [6:0] io_vecFeedback_1_bits_uopidx,
  input io_vecFeedback_1_bits_feedback_0,
  input io_vecFeedback_1_bits_feedback_1,
  input io_enq_0_valid,
  input io_enq_0_bits_uop_exceptionVec_0,
  input io_enq_0_bits_uop_exceptionVec_1,
  input io_enq_0_bits_uop_exceptionVec_2,
  input io_enq_0_bits_uop_exceptionVec_3,
  input io_enq_0_bits_uop_exceptionVec_4,
  input io_enq_0_bits_uop_exceptionVec_5,
  input io_enq_0_bits_uop_exceptionVec_6,
  input io_enq_0_bits_uop_exceptionVec_7,
  input io_enq_0_bits_uop_exceptionVec_8,
  input io_enq_0_bits_uop_exceptionVec_9,
  input io_enq_0_bits_uop_exceptionVec_10,
  input io_enq_0_bits_uop_exceptionVec_11,
  input io_enq_0_bits_uop_exceptionVec_12,
  input io_enq_0_bits_uop_exceptionVec_13,
  input io_enq_0_bits_uop_exceptionVec_14,
  input io_enq_0_bits_uop_exceptionVec_15,
  input io_enq_0_bits_uop_exceptionVec_16,
  input io_enq_0_bits_uop_exceptionVec_17,
  input io_enq_0_bits_uop_exceptionVec_18,
  input io_enq_0_bits_uop_exceptionVec_19,
  input io_enq_0_bits_uop_exceptionVec_20,
  input io_enq_0_bits_uop_exceptionVec_21,
  input io_enq_0_bits_uop_exceptionVec_22,
  input io_enq_0_bits_uop_exceptionVec_23,
  input io_enq_0_bits_uop_preDecodeInfo_isRVC,
  input io_enq_0_bits_uop_ftqPtr_flag,
  input [5:0] io_enq_0_bits_uop_ftqPtr_value,
  input [3:0] io_enq_0_bits_uop_ftqOffset,
  input [8:0] io_enq_0_bits_uop_fuOpType,
  input io_enq_0_bits_uop_rfWen,
  input io_enq_0_bits_uop_fpWen,
  input [7:0] io_enq_0_bits_uop_vpu_vstart,
  input [1:0] io_enq_0_bits_uop_vpu_veew,
  input [6:0] io_enq_0_bits_uop_uopIdx,
  input [7:0] io_enq_0_bits_uop_pdest,
  input io_enq_0_bits_uop_robIdx_flag,
  input [7:0] io_enq_0_bits_uop_robIdx_value,
  input [63:0] io_enq_0_bits_uop_debugInfo_enqRsTime,
  input [63:0] io_enq_0_bits_uop_debugInfo_selectTime,
  input [63:0] io_enq_0_bits_uop_debugInfo_issueTime,
  input io_enq_0_bits_uop_storeSetHit,
  input io_enq_0_bits_uop_waitForRobIdx_flag,
  input [7:0] io_enq_0_bits_uop_waitForRobIdx_value,
  input io_enq_0_bits_uop_loadWaitBit,
  input io_enq_0_bits_uop_loadWaitStrict,
  input io_enq_0_bits_uop_lqIdx_flag,
  input [6:0] io_enq_0_bits_uop_lqIdx_value,
  input io_enq_0_bits_uop_sqIdx_flag,
  input [5:0] io_enq_0_bits_uop_sqIdx_value,
  input [49:0] io_enq_0_bits_vaddr,
  input [15:0] io_enq_0_bits_mask,
  input io_enq_0_bits_tlbMiss,
  input io_enq_0_bits_isvec,
  input io_enq_0_bits_is128bit,
  input [7:0] io_enq_0_bits_elemIdx,
  input [2:0] io_enq_0_bits_alignedType,
  input [3:0] io_enq_0_bits_mbIndex,
  input [3:0] io_enq_0_bits_reg_offset,
  input [7:0] io_enq_0_bits_elemIdxInsideVd,
  input io_enq_0_bits_vecActive,
  input io_enq_0_bits_isLoadReplay,
  input io_enq_0_bits_handledByMSHR,
  input [6:0] io_enq_0_bits_schedIndex,
  input [3:0] io_enq_0_bits_rep_info_mshr_id,
  input io_enq_0_bits_rep_info_full_fwd,
  input io_enq_0_bits_rep_info_data_inv_sq_idx_flag,
  input [5:0] io_enq_0_bits_rep_info_data_inv_sq_idx_value,
  input io_enq_0_bits_rep_info_addr_inv_sq_idx_flag,
  input [5:0] io_enq_0_bits_rep_info_addr_inv_sq_idx_value,
  input io_enq_0_bits_rep_info_last_beat,
  input io_enq_0_bits_rep_info_cause_0,
  input io_enq_0_bits_rep_info_cause_1,
  input io_enq_0_bits_rep_info_cause_2,
  input io_enq_0_bits_rep_info_cause_3,
  input io_enq_0_bits_rep_info_cause_4,
  input io_enq_0_bits_rep_info_cause_5,
  input io_enq_0_bits_rep_info_cause_6,
  input io_enq_0_bits_rep_info_cause_7,
  input io_enq_0_bits_rep_info_cause_8,
  input io_enq_0_bits_rep_info_cause_9,
  input io_enq_0_bits_rep_info_cause_10,
  input [3:0] io_enq_0_bits_rep_info_tlb_id,
  input io_enq_0_bits_rep_info_tlb_full,
  input io_enq_1_valid,
  input io_enq_1_bits_uop_exceptionVec_0,
  input io_enq_1_bits_uop_exceptionVec_1,
  input io_enq_1_bits_uop_exceptionVec_2,
  input io_enq_1_bits_uop_exceptionVec_3,
  input io_enq_1_bits_uop_exceptionVec_4,
  input io_enq_1_bits_uop_exceptionVec_5,
  input io_enq_1_bits_uop_exceptionVec_6,
  input io_enq_1_bits_uop_exceptionVec_7,
  input io_enq_1_bits_uop_exceptionVec_8,
  input io_enq_1_bits_uop_exceptionVec_9,
  input io_enq_1_bits_uop_exceptionVec_10,
  input io_enq_1_bits_uop_exceptionVec_11,
  input io_enq_1_bits_uop_exceptionVec_12,
  input io_enq_1_bits_uop_exceptionVec_13,
  input io_enq_1_bits_uop_exceptionVec_14,
  input io_enq_1_bits_uop_exceptionVec_15,
  input io_enq_1_bits_uop_exceptionVec_16,
  input io_enq_1_bits_uop_exceptionVec_17,
  input io_enq_1_bits_uop_exceptionVec_18,
  input io_enq_1_bits_uop_exceptionVec_19,
  input io_enq_1_bits_uop_exceptionVec_20,
  input io_enq_1_bits_uop_exceptionVec_21,
  input io_enq_1_bits_uop_exceptionVec_22,
  input io_enq_1_bits_uop_exceptionVec_23,
  input io_enq_1_bits_uop_preDecodeInfo_isRVC,
  input io_enq_1_bits_uop_ftqPtr_flag,
  input [5:0] io_enq_1_bits_uop_ftqPtr_value,
  input [3:0] io_enq_1_bits_uop_ftqOffset,
  input [8:0] io_enq_1_bits_uop_fuOpType,
  input io_enq_1_bits_uop_rfWen,
  input io_enq_1_bits_uop_fpWen,
  input [7:0] io_enq_1_bits_uop_vpu_vstart,
  input [1:0] io_enq_1_bits_uop_vpu_veew,
  input [6:0] io_enq_1_bits_uop_uopIdx,
  input [7:0] io_enq_1_bits_uop_pdest,
  input io_enq_1_bits_uop_robIdx_flag,
  input [7:0] io_enq_1_bits_uop_robIdx_value,
  input [63:0] io_enq_1_bits_uop_debugInfo_enqRsTime,
  input [63:0] io_enq_1_bits_uop_debugInfo_selectTime,
  input [63:0] io_enq_1_bits_uop_debugInfo_issueTime,
  input io_enq_1_bits_uop_storeSetHit,
  input io_enq_1_bits_uop_waitForRobIdx_flag,
  input [7:0] io_enq_1_bits_uop_waitForRobIdx_value,
  input io_enq_1_bits_uop_loadWaitBit,
  input io_enq_1_bits_uop_loadWaitStrict,
  input io_enq_1_bits_uop_lqIdx_flag,
  input [6:0] io_enq_1_bits_uop_lqIdx_value,
  input io_enq_1_bits_uop_sqIdx_flag,
  input [5:0] io_enq_1_bits_uop_sqIdx_value,
  input [49:0] io_enq_1_bits_vaddr,
  input [15:0] io_enq_1_bits_mask,
  input io_enq_1_bits_tlbMiss,
  input io_enq_1_bits_isvec,
  input io_enq_1_bits_is128bit,
  input [7:0] io_enq_1_bits_elemIdx,
  input [2:0] io_enq_1_bits_alignedType,
  input [3:0] io_enq_1_bits_mbIndex,
  input [3:0] io_enq_1_bits_reg_offset,
  input [7:0] io_enq_1_bits_elemIdxInsideVd,
  input io_enq_1_bits_vecActive,
  input io_enq_1_bits_isLoadReplay,
  input io_enq_1_bits_handledByMSHR,
  input [6:0] io_enq_1_bits_schedIndex,
  input [3:0] io_enq_1_bits_rep_info_mshr_id,
  input io_enq_1_bits_rep_info_full_fwd,
  input io_enq_1_bits_rep_info_data_inv_sq_idx_flag,
  input [5:0] io_enq_1_bits_rep_info_data_inv_sq_idx_value,
  input io_enq_1_bits_rep_info_addr_inv_sq_idx_flag,
  input [5:0] io_enq_1_bits_rep_info_addr_inv_sq_idx_value,
  input io_enq_1_bits_rep_info_last_beat,
  input io_enq_1_bits_rep_info_cause_0,
  input io_enq_1_bits_rep_info_cause_1,
  input io_enq_1_bits_rep_info_cause_2,
  input io_enq_1_bits_rep_info_cause_3,
  input io_enq_1_bits_rep_info_cause_4,
  input io_enq_1_bits_rep_info_cause_5,
  input io_enq_1_bits_rep_info_cause_6,
  input io_enq_1_bits_rep_info_cause_7,
  input io_enq_1_bits_rep_info_cause_8,
  input io_enq_1_bits_rep_info_cause_9,
  input io_enq_1_bits_rep_info_cause_10,
  input [3:0] io_enq_1_bits_rep_info_tlb_id,
  input io_enq_1_bits_rep_info_tlb_full,
  input io_enq_2_valid,
  input io_enq_2_bits_uop_exceptionVec_0,
  input io_enq_2_bits_uop_exceptionVec_1,
  input io_enq_2_bits_uop_exceptionVec_2,
  input io_enq_2_bits_uop_exceptionVec_3,
  input io_enq_2_bits_uop_exceptionVec_4,
  input io_enq_2_bits_uop_exceptionVec_5,
  input io_enq_2_bits_uop_exceptionVec_6,
  input io_enq_2_bits_uop_exceptionVec_7,
  input io_enq_2_bits_uop_exceptionVec_8,
  input io_enq_2_bits_uop_exceptionVec_9,
  input io_enq_2_bits_uop_exceptionVec_10,
  input io_enq_2_bits_uop_exceptionVec_11,
  input io_enq_2_bits_uop_exceptionVec_12,
  input io_enq_2_bits_uop_exceptionVec_13,
  input io_enq_2_bits_uop_exceptionVec_14,
  input io_enq_2_bits_uop_exceptionVec_15,
  input io_enq_2_bits_uop_exceptionVec_16,
  input io_enq_2_bits_uop_exceptionVec_17,
  input io_enq_2_bits_uop_exceptionVec_18,
  input io_enq_2_bits_uop_exceptionVec_19,
  input io_enq_2_bits_uop_exceptionVec_20,
  input io_enq_2_bits_uop_exceptionVec_21,
  input io_enq_2_bits_uop_exceptionVec_22,
  input io_enq_2_bits_uop_exceptionVec_23,
  input io_enq_2_bits_uop_preDecodeInfo_isRVC,
  input io_enq_2_bits_uop_ftqPtr_flag,
  input [5:0] io_enq_2_bits_uop_ftqPtr_value,
  input [3:0] io_enq_2_bits_uop_ftqOffset,
  input [8:0] io_enq_2_bits_uop_fuOpType,
  input io_enq_2_bits_uop_rfWen,
  input io_enq_2_bits_uop_fpWen,
  input [7:0] io_enq_2_bits_uop_vpu_vstart,
  input [1:0] io_enq_2_bits_uop_vpu_veew,
  input [6:0] io_enq_2_bits_uop_uopIdx,
  input [7:0] io_enq_2_bits_uop_pdest,
  input io_enq_2_bits_uop_robIdx_flag,
  input [7:0] io_enq_2_bits_uop_robIdx_value,
  input [63:0] io_enq_2_bits_uop_debugInfo_enqRsTime,
  input [63:0] io_enq_2_bits_uop_debugInfo_selectTime,
  input [63:0] io_enq_2_bits_uop_debugInfo_issueTime,
  input io_enq_2_bits_uop_storeSetHit,
  input io_enq_2_bits_uop_waitForRobIdx_flag,
  input [7:0] io_enq_2_bits_uop_waitForRobIdx_value,
  input io_enq_2_bits_uop_loadWaitBit,
  input io_enq_2_bits_uop_loadWaitStrict,
  input io_enq_2_bits_uop_lqIdx_flag,
  input [6:0] io_enq_2_bits_uop_lqIdx_value,
  input io_enq_2_bits_uop_sqIdx_flag,
  input [5:0] io_enq_2_bits_uop_sqIdx_value,
  input [49:0] io_enq_2_bits_vaddr,
  input [15:0] io_enq_2_bits_mask,
  input io_enq_2_bits_tlbMiss,
  input io_enq_2_bits_isvec,
  input io_enq_2_bits_is128bit,
  input [7:0] io_enq_2_bits_elemIdx,
  input [2:0] io_enq_2_bits_alignedType,
  input [3:0] io_enq_2_bits_mbIndex,
  input [3:0] io_enq_2_bits_reg_offset,
  input [7:0] io_enq_2_bits_elemIdxInsideVd,
  input io_enq_2_bits_vecActive,
  input io_enq_2_bits_isLoadReplay,
  input io_enq_2_bits_handledByMSHR,
  input [6:0] io_enq_2_bits_schedIndex,
  input [3:0] io_enq_2_bits_rep_info_mshr_id,
  input io_enq_2_bits_rep_info_full_fwd,
  input io_enq_2_bits_rep_info_data_inv_sq_idx_flag,
  input [5:0] io_enq_2_bits_rep_info_data_inv_sq_idx_value,
  input io_enq_2_bits_rep_info_addr_inv_sq_idx_flag,
  input [5:0] io_enq_2_bits_rep_info_addr_inv_sq_idx_value,
  input io_enq_2_bits_rep_info_last_beat,
  input io_enq_2_bits_rep_info_cause_0,
  input io_enq_2_bits_rep_info_cause_1,
  input io_enq_2_bits_rep_info_cause_2,
  input io_enq_2_bits_rep_info_cause_3,
  input io_enq_2_bits_rep_info_cause_4,
  input io_enq_2_bits_rep_info_cause_5,
  input io_enq_2_bits_rep_info_cause_6,
  input io_enq_2_bits_rep_info_cause_7,
  input io_enq_2_bits_rep_info_cause_8,
  input io_enq_2_bits_rep_info_cause_9,
  input io_enq_2_bits_rep_info_cause_10,
  input [3:0] io_enq_2_bits_rep_info_tlb_id,
  input io_enq_2_bits_rep_info_tlb_full,
  input io_storeAddrIn_0_valid,
  input io_storeAddrIn_0_bits_uop_sqIdx_flag,
  input [5:0] io_storeAddrIn_0_bits_uop_sqIdx_value,
  input io_storeAddrIn_0_bits_miss,
  input io_storeAddrIn_1_valid,
  input io_storeAddrIn_1_bits_uop_sqIdx_flag,
  input [5:0] io_storeAddrIn_1_bits_uop_sqIdx_value,
  input io_storeAddrIn_1_bits_miss,
  input io_storeDataIn_0_valid,
  input io_storeDataIn_0_bits_uop_sqIdx_flag,
  input [5:0] io_storeDataIn_0_bits_uop_sqIdx_value,
  input io_storeDataIn_1_valid,
  input io_storeDataIn_1_bits_uop_sqIdx_flag,
  input [5:0] io_storeDataIn_1_bits_uop_sqIdx_value,
  input io_replay_0_ready,
  output io_replay_0_valid,
  output io_replay_0_bits_uop_exceptionVec_0,
  output io_replay_0_bits_uop_exceptionVec_1,
  output io_replay_0_bits_uop_exceptionVec_2,
  output io_replay_0_bits_uop_exceptionVec_6,
  output io_replay_0_bits_uop_exceptionVec_7,
  output io_replay_0_bits_uop_exceptionVec_8,
  output io_replay_0_bits_uop_exceptionVec_9,
  output io_replay_0_bits_uop_exceptionVec_10,
  output io_replay_0_bits_uop_exceptionVec_11,
  output io_replay_0_bits_uop_exceptionVec_12,
  output io_replay_0_bits_uop_exceptionVec_14,
  output io_replay_0_bits_uop_exceptionVec_15,
  output io_replay_0_bits_uop_exceptionVec_16,
  output io_replay_0_bits_uop_exceptionVec_17,
  output io_replay_0_bits_uop_exceptionVec_18,
  output io_replay_0_bits_uop_exceptionVec_19,
  output io_replay_0_bits_uop_exceptionVec_20,
  output io_replay_0_bits_uop_exceptionVec_22,
  output io_replay_0_bits_uop_exceptionVec_23,
  output io_replay_0_bits_uop_preDecodeInfo_isRVC,
  output io_replay_0_bits_uop_ftqPtr_flag,
  output [5:0] io_replay_0_bits_uop_ftqPtr_value,
  output [3:0] io_replay_0_bits_uop_ftqOffset,
  output [8:0] io_replay_0_bits_uop_fuOpType,
  output io_replay_0_bits_uop_rfWen,
  output io_replay_0_bits_uop_fpWen,
  output [7:0] io_replay_0_bits_uop_vpu_vstart,
  output [1:0] io_replay_0_bits_uop_vpu_veew,
  output [6:0] io_replay_0_bits_uop_uopIdx,
  output [7:0] io_replay_0_bits_uop_pdest,
  output io_replay_0_bits_uop_robIdx_flag,
  output [7:0] io_replay_0_bits_uop_robIdx_value,
  output [63:0] io_replay_0_bits_uop_debugInfo_enqRsTime,
  output [63:0] io_replay_0_bits_uop_debugInfo_selectTime,
  output [63:0] io_replay_0_bits_uop_debugInfo_issueTime,
  output io_replay_0_bits_uop_storeSetHit,
  output io_replay_0_bits_uop_waitForRobIdx_flag,
  output [7:0] io_replay_0_bits_uop_waitForRobIdx_value,
  output io_replay_0_bits_uop_loadWaitBit,
  output io_replay_0_bits_uop_lqIdx_flag,
  output [6:0] io_replay_0_bits_uop_lqIdx_value,
  output io_replay_0_bits_uop_sqIdx_flag,
  output [5:0] io_replay_0_bits_uop_sqIdx_value,
  output [49:0] io_replay_0_bits_vaddr,
  output [15:0] io_replay_0_bits_mask,
  output io_replay_0_bits_isvec,
  output io_replay_0_bits_is128bit,
  output [7:0] io_replay_0_bits_elemIdx,
  output [2:0] io_replay_0_bits_alignedType,
  output [3:0] io_replay_0_bits_mbIndex,
  output [3:0] io_replay_0_bits_reg_offset,
  output [7:0] io_replay_0_bits_elemIdxInsideVd,
  output io_replay_0_bits_vecActive,
  output [3:0] io_replay_0_bits_mshrid,
  output io_replay_0_bits_forward_tlDchannel,
  output [6:0] io_replay_0_bits_schedIndex,
  input io_replay_1_ready,
  output io_replay_1_valid,
  output io_replay_1_bits_uop_exceptionVec_0,
  output io_replay_1_bits_uop_exceptionVec_1,
  output io_replay_1_bits_uop_exceptionVec_2,
  output io_replay_1_bits_uop_exceptionVec_6,
  output io_replay_1_bits_uop_exceptionVec_7,
  output io_replay_1_bits_uop_exceptionVec_8,
  output io_replay_1_bits_uop_exceptionVec_9,
  output io_replay_1_bits_uop_exceptionVec_10,
  output io_replay_1_bits_uop_exceptionVec_11,
  output io_replay_1_bits_uop_exceptionVec_12,
  output io_replay_1_bits_uop_exceptionVec_14,
  output io_replay_1_bits_uop_exceptionVec_15,
  output io_replay_1_bits_uop_exceptionVec_16,
  output io_replay_1_bits_uop_exceptionVec_17,
  output io_replay_1_bits_uop_exceptionVec_18,
  output io_replay_1_bits_uop_exceptionVec_19,
  output io_replay_1_bits_uop_exceptionVec_20,
  output io_replay_1_bits_uop_exceptionVec_22,
  output io_replay_1_bits_uop_exceptionVec_23,
  output io_replay_1_bits_uop_preDecodeInfo_isRVC,
  output io_replay_1_bits_uop_ftqPtr_flag,
  output [5:0] io_replay_1_bits_uop_ftqPtr_value,
  output [3:0] io_replay_1_bits_uop_ftqOffset,
  output [8:0] io_replay_1_bits_uop_fuOpType,
  output io_replay_1_bits_uop_rfWen,
  output io_replay_1_bits_uop_fpWen,
  output [7:0] io_replay_1_bits_uop_vpu_vstart,
  output [1:0] io_replay_1_bits_uop_vpu_veew,
  output [6:0] io_replay_1_bits_uop_uopIdx,
  output [7:0] io_replay_1_bits_uop_pdest,
  output io_replay_1_bits_uop_robIdx_flag,
  output [7:0] io_replay_1_bits_uop_robIdx_value,
  output [63:0] io_replay_1_bits_uop_debugInfo_enqRsTime,
  output [63:0] io_replay_1_bits_uop_debugInfo_selectTime,
  output [63:0] io_replay_1_bits_uop_debugInfo_issueTime,
  output io_replay_1_bits_uop_storeSetHit,
  output io_replay_1_bits_uop_waitForRobIdx_flag,
  output [7:0] io_replay_1_bits_uop_waitForRobIdx_value,
  output io_replay_1_bits_uop_loadWaitBit,
  output io_replay_1_bits_uop_lqIdx_flag,
  output [6:0] io_replay_1_bits_uop_lqIdx_value,
  output io_replay_1_bits_uop_sqIdx_flag,
  output [5:0] io_replay_1_bits_uop_sqIdx_value,
  output [49:0] io_replay_1_bits_vaddr,
  output [15:0] io_replay_1_bits_mask,
  output io_replay_1_bits_isvec,
  output io_replay_1_bits_is128bit,
  output [7:0] io_replay_1_bits_elemIdx,
  output [2:0] io_replay_1_bits_alignedType,
  output [3:0] io_replay_1_bits_mbIndex,
  output [3:0] io_replay_1_bits_reg_offset,
  output [7:0] io_replay_1_bits_elemIdxInsideVd,
  output io_replay_1_bits_vecActive,
  output [3:0] io_replay_1_bits_mshrid,
  output io_replay_1_bits_forward_tlDchannel,
  output [6:0] io_replay_1_bits_schedIndex,
  input io_replay_2_ready,
  output io_replay_2_valid,
  output io_replay_2_bits_uop_exceptionVec_0,
  output io_replay_2_bits_uop_exceptionVec_1,
  output io_replay_2_bits_uop_exceptionVec_2,
  output io_replay_2_bits_uop_exceptionVec_6,
  output io_replay_2_bits_uop_exceptionVec_7,
  output io_replay_2_bits_uop_exceptionVec_8,
  output io_replay_2_bits_uop_exceptionVec_9,
  output io_replay_2_bits_uop_exceptionVec_10,
  output io_replay_2_bits_uop_exceptionVec_11,
  output io_replay_2_bits_uop_exceptionVec_12,
  output io_replay_2_bits_uop_exceptionVec_14,
  output io_replay_2_bits_uop_exceptionVec_15,
  output io_replay_2_bits_uop_exceptionVec_16,
  output io_replay_2_bits_uop_exceptionVec_17,
  output io_replay_2_bits_uop_exceptionVec_18,
  output io_replay_2_bits_uop_exceptionVec_19,
  output io_replay_2_bits_uop_exceptionVec_20,
  output io_replay_2_bits_uop_exceptionVec_22,
  output io_replay_2_bits_uop_exceptionVec_23,
  output io_replay_2_bits_uop_preDecodeInfo_isRVC,
  output io_replay_2_bits_uop_ftqPtr_flag,
  output [5:0] io_replay_2_bits_uop_ftqPtr_value,
  output [3:0] io_replay_2_bits_uop_ftqOffset,
  output [8:0] io_replay_2_bits_uop_fuOpType,
  output io_replay_2_bits_uop_rfWen,
  output io_replay_2_bits_uop_fpWen,
  output [7:0] io_replay_2_bits_uop_vpu_vstart,
  output [1:0] io_replay_2_bits_uop_vpu_veew,
  output [6:0] io_replay_2_bits_uop_uopIdx,
  output [7:0] io_replay_2_bits_uop_pdest,
  output io_replay_2_bits_uop_robIdx_flag,
  output [7:0] io_replay_2_bits_uop_robIdx_value,
  output [63:0] io_replay_2_bits_uop_debugInfo_enqRsTime,
  output [63:0] io_replay_2_bits_uop_debugInfo_selectTime,
  output [63:0] io_replay_2_bits_uop_debugInfo_issueTime,
  output io_replay_2_bits_uop_storeSetHit,
  output io_replay_2_bits_uop_waitForRobIdx_flag,
  output [7:0] io_replay_2_bits_uop_waitForRobIdx_value,
  output io_replay_2_bits_uop_loadWaitBit,
  output io_replay_2_bits_uop_lqIdx_flag,
  output [6:0] io_replay_2_bits_uop_lqIdx_value,
  output io_replay_2_bits_uop_sqIdx_flag,
  output [5:0] io_replay_2_bits_uop_sqIdx_value,
  output [49:0] io_replay_2_bits_vaddr,
  output [15:0] io_replay_2_bits_mask,
  output io_replay_2_bits_isvec,
  output io_replay_2_bits_is128bit,
  output [7:0] io_replay_2_bits_elemIdx,
  output [2:0] io_replay_2_bits_alignedType,
  output [3:0] io_replay_2_bits_mbIndex,
  output [3:0] io_replay_2_bits_reg_offset,
  output [7:0] io_replay_2_bits_elemIdxInsideVd,
  output io_replay_2_bits_vecActive,
  output [3:0] io_replay_2_bits_mshrid,
  output io_replay_2_bits_forward_tlDchannel,
  output [6:0] io_replay_2_bits_schedIndex,
  input io_tl_d_channel_valid,
  input [3:0] io_tl_d_channel_mshrid,
  input io_stAddrReadySqPtr_flag,
  input [5:0] io_stAddrReadySqPtr_value,
  input io_stAddrReadyVec_0,
  input io_stAddrReadyVec_1,
  input io_stAddrReadyVec_2,
  input io_stAddrReadyVec_3,
  input io_stAddrReadyVec_4,
  input io_stAddrReadyVec_5,
  input io_stAddrReadyVec_6,
  input io_stAddrReadyVec_7,
  input io_stAddrReadyVec_8,
  input io_stAddrReadyVec_9,
  input io_stAddrReadyVec_10,
  input io_stAddrReadyVec_11,
  input io_stAddrReadyVec_12,
  input io_stAddrReadyVec_13,
  input io_stAddrReadyVec_14,
  input io_stAddrReadyVec_15,
  input io_stAddrReadyVec_16,
  input io_stAddrReadyVec_17,
  input io_stAddrReadyVec_18,
  input io_stAddrReadyVec_19,
  input io_stAddrReadyVec_20,
  input io_stAddrReadyVec_21,
  input io_stAddrReadyVec_22,
  input io_stAddrReadyVec_23,
  input io_stAddrReadyVec_24,
  input io_stAddrReadyVec_25,
  input io_stAddrReadyVec_26,
  input io_stAddrReadyVec_27,
  input io_stAddrReadyVec_28,
  input io_stAddrReadyVec_29,
  input io_stAddrReadyVec_30,
  input io_stAddrReadyVec_31,
  input io_stAddrReadyVec_32,
  input io_stAddrReadyVec_33,
  input io_stAddrReadyVec_34,
  input io_stAddrReadyVec_35,
  input io_stAddrReadyVec_36,
  input io_stAddrReadyVec_37,
  input io_stAddrReadyVec_38,
  input io_stAddrReadyVec_39,
  input io_stAddrReadyVec_40,
  input io_stAddrReadyVec_41,
  input io_stAddrReadyVec_42,
  input io_stAddrReadyVec_43,
  input io_stAddrReadyVec_44,
  input io_stAddrReadyVec_45,
  input io_stAddrReadyVec_46,
  input io_stAddrReadyVec_47,
  input io_stAddrReadyVec_48,
  input io_stAddrReadyVec_49,
  input io_stAddrReadyVec_50,
  input io_stAddrReadyVec_51,
  input io_stAddrReadyVec_52,
  input io_stAddrReadyVec_53,
  input io_stAddrReadyVec_54,
  input io_stAddrReadyVec_55,
  input io_stDataReadySqPtr_flag,
  input [5:0] io_stDataReadySqPtr_value,
  input io_stDataReadyVec_0,
  input io_stDataReadyVec_1,
  input io_stDataReadyVec_2,
  input io_stDataReadyVec_3,
  input io_stDataReadyVec_4,
  input io_stDataReadyVec_5,
  input io_stDataReadyVec_6,
  input io_stDataReadyVec_7,
  input io_stDataReadyVec_8,
  input io_stDataReadyVec_9,
  input io_stDataReadyVec_10,
  input io_stDataReadyVec_11,
  input io_stDataReadyVec_12,
  input io_stDataReadyVec_13,
  input io_stDataReadyVec_14,
  input io_stDataReadyVec_15,
  input io_stDataReadyVec_16,
  input io_stDataReadyVec_17,
  input io_stDataReadyVec_18,
  input io_stDataReadyVec_19,
  input io_stDataReadyVec_20,
  input io_stDataReadyVec_21,
  input io_stDataReadyVec_22,
  input io_stDataReadyVec_23,
  input io_stDataReadyVec_24,
  input io_stDataReadyVec_25,
  input io_stDataReadyVec_26,
  input io_stDataReadyVec_27,
  input io_stDataReadyVec_28,
  input io_stDataReadyVec_29,
  input io_stDataReadyVec_30,
  input io_stDataReadyVec_31,
  input io_stDataReadyVec_32,
  input io_stDataReadyVec_33,
  input io_stDataReadyVec_34,
  input io_stDataReadyVec_35,
  input io_stDataReadyVec_36,
  input io_stDataReadyVec_37,
  input io_stDataReadyVec_38,
  input io_stDataReadyVec_39,
  input io_stDataReadyVec_40,
  input io_stDataReadyVec_41,
  input io_stDataReadyVec_42,
  input io_stDataReadyVec_43,
  input io_stDataReadyVec_44,
  input io_stDataReadyVec_45,
  input io_stDataReadyVec_46,
  input io_stDataReadyVec_47,
  input io_stDataReadyVec_48,
  input io_stDataReadyVec_49,
  input io_stDataReadyVec_50,
  input io_stDataReadyVec_51,
  input io_stDataReadyVec_52,
  input io_stDataReadyVec_53,
  input io_stDataReadyVec_54,
  input io_stDataReadyVec_55,
  input io_sqEmpty,
  output io_lqFull,
  input io_ldWbPtr_flag,
  input [6:0] io_ldWbPtr_value,
  input io_rarFull,
  input io_rawFull,
  input io_loadMisalignFull,
  input io_misalignAllowSpec,
  input io_l2_hint_valid,
  input [3:0] io_l2_hint_bits_sourceId,
  input io_l2_hint_bits_isKeyword,
  input io_tlb_hint_resp_valid,
  input [3:0] io_tlb_hint_resp_bits_id,
  input io_tlb_hint_resp_bits_replay_all,
  input io_debugTopDown_robHeadVaddr_valid,
  input [49:0] io_debugTopDown_robHeadVaddr_bits,
  output io_debugTopDown_robHeadTlbReplay,
  output io_debugTopDown_robHeadTlbMiss,
  output io_debugTopDown_robHeadLoadVio,
  output io_debugTopDown_robHeadLoadMSHR,
  input io_debugTopDown_robHeadMissInDTlb,
  output [5:0] io_perf_0_value,
  output [5:0] io_perf_1_value,
  output [5:0] io_perf_2_value,
  output [5:0] io_perf_3_value,
  output [5:0] io_perf_4_value,
  output [5:0] io_perf_5_value,
  output [5:0] io_perf_6_value,
  output [5:0] io_perf_7_value,
  output [5:0] io_perf_8_value,
  output [5:0] io_perf_9_value,
  output [5:0] io_perf_10_value,
  output [5:0] io_perf_11_value,
  output [5:0] io_perf_12_value
);
  import loadqueuereplay_pkg::*;
  // ---- 输入侧打包 ----
  rob_ptr_t vfb0_rob; assign vfb0_rob = '{flag:io_vecFeedback_0_bits_robidx_flag, value:io_vecFeedback_0_bits_robidx_value};
  rob_ptr_t vfb1_rob; assign vfb1_rob = '{flag:io_vecFeedback_1_bits_robidx_flag, value:io_vecFeedback_1_bits_robidx_value};
  lqr_uop_t enq0_uop;
  lqr_vec_t enq0_vec;
  logic [10:0] enq0_cause;
  sq_ptr_t enq0_data_inv, enq0_addr_inv;
  lqr_uop_t enq1_uop;
  lqr_vec_t enq1_vec;
  logic [10:0] enq1_cause;
  sq_ptr_t enq1_data_inv, enq1_addr_inv;
  lqr_uop_t enq2_uop;
  lqr_vec_t enq2_vec;
  logic [10:0] enq2_cause;
  sq_ptr_t enq2_data_inv, enq2_addr_inv;

  assign enq0_uop = '{
    exceptionVec:{io_enq_0_bits_uop_exceptionVec_23, io_enq_0_bits_uop_exceptionVec_22, io_enq_0_bits_uop_exceptionVec_21, io_enq_0_bits_uop_exceptionVec_20, io_enq_0_bits_uop_exceptionVec_19, io_enq_0_bits_uop_exceptionVec_18, io_enq_0_bits_uop_exceptionVec_17, io_enq_0_bits_uop_exceptionVec_16, io_enq_0_bits_uop_exceptionVec_15, io_enq_0_bits_uop_exceptionVec_14, io_enq_0_bits_uop_exceptionVec_13, io_enq_0_bits_uop_exceptionVec_12, io_enq_0_bits_uop_exceptionVec_11, io_enq_0_bits_uop_exceptionVec_10, io_enq_0_bits_uop_exceptionVec_9, io_enq_0_bits_uop_exceptionVec_8, io_enq_0_bits_uop_exceptionVec_7, io_enq_0_bits_uop_exceptionVec_6, io_enq_0_bits_uop_exceptionVec_5, io_enq_0_bits_uop_exceptionVec_4, io_enq_0_bits_uop_exceptionVec_3, io_enq_0_bits_uop_exceptionVec_2, io_enq_0_bits_uop_exceptionVec_1, io_enq_0_bits_uop_exceptionVec_0},
    preDecodeInfo_isRVC:io_enq_0_bits_uop_preDecodeInfo_isRVC,
    ftqPtr_flag:io_enq_0_bits_uop_ftqPtr_flag, ftqPtr_value:io_enq_0_bits_uop_ftqPtr_value,
    ftqOffset:io_enq_0_bits_uop_ftqOffset, fuOpType:io_enq_0_bits_uop_fuOpType,
    rfWen:io_enq_0_bits_uop_rfWen, fpWen:io_enq_0_bits_uop_fpWen,
    vpu_vstart:io_enq_0_bits_uop_vpu_vstart, vpu_veew:io_enq_0_bits_uop_vpu_veew,
    uopIdx:io_enq_0_bits_uop_uopIdx, pdest:io_enq_0_bits_uop_pdest,
    robIdx:'{flag:io_enq_0_bits_uop_robIdx_flag, value:io_enq_0_bits_uop_robIdx_value},
    dbg_enqRsTime:io_enq_0_bits_uop_debugInfo_enqRsTime,
    dbg_selectTime:io_enq_0_bits_uop_debugInfo_selectTime,
    dbg_issueTime:io_enq_0_bits_uop_debugInfo_issueTime,
    storeSetHit:io_enq_0_bits_uop_storeSetHit,
    waitForRobIdx_flag:io_enq_0_bits_uop_waitForRobIdx_flag, waitForRobIdx_value:io_enq_0_bits_uop_waitForRobIdx_value,
    loadWaitBit:io_enq_0_bits_uop_loadWaitBit, loadWaitStrict:io_enq_0_bits_uop_loadWaitStrict,
    lqIdx:'{flag:io_enq_0_bits_uop_lqIdx_flag, value:io_enq_0_bits_uop_lqIdx_value},
    sqIdx:'{flag:io_enq_0_bits_uop_sqIdx_flag, value:io_enq_0_bits_uop_sqIdx_value}};
  assign enq0_vec = '{
    isvec:io_enq_0_bits_isvec, isLastElem:1'b0, is128bit:io_enq_0_bits_is128bit,
    uop_unit_stride_fof:1'b0, usSecondInv:1'b0,
    elemIdx:io_enq_0_bits_elemIdx, alignedType:io_enq_0_bits_alignedType,
    mbIndex:io_enq_0_bits_mbIndex, elemIdxInsideVd:io_enq_0_bits_elemIdxInsideVd,
    reg_offset:io_enq_0_bits_reg_offset, vecActive:io_enq_0_bits_vecActive,
    is_first_ele:1'b0, mask:io_enq_0_bits_mask};
  assign enq0_cause = {io_enq_0_bits_rep_info_cause_10, io_enq_0_bits_rep_info_cause_9, io_enq_0_bits_rep_info_cause_8, io_enq_0_bits_rep_info_cause_7, io_enq_0_bits_rep_info_cause_6, io_enq_0_bits_rep_info_cause_5, io_enq_0_bits_rep_info_cause_4, io_enq_0_bits_rep_info_cause_3, io_enq_0_bits_rep_info_cause_2, io_enq_0_bits_rep_info_cause_1, io_enq_0_bits_rep_info_cause_0};
  assign enq0_data_inv = '{flag:io_enq_0_bits_rep_info_data_inv_sq_idx_flag, value:io_enq_0_bits_rep_info_data_inv_sq_idx_value};
  assign enq0_addr_inv = '{flag:io_enq_0_bits_rep_info_addr_inv_sq_idx_flag, value:io_enq_0_bits_rep_info_addr_inv_sq_idx_value};
  assign enq1_uop = '{
    exceptionVec:{io_enq_1_bits_uop_exceptionVec_23, io_enq_1_bits_uop_exceptionVec_22, io_enq_1_bits_uop_exceptionVec_21, io_enq_1_bits_uop_exceptionVec_20, io_enq_1_bits_uop_exceptionVec_19, io_enq_1_bits_uop_exceptionVec_18, io_enq_1_bits_uop_exceptionVec_17, io_enq_1_bits_uop_exceptionVec_16, io_enq_1_bits_uop_exceptionVec_15, io_enq_1_bits_uop_exceptionVec_14, io_enq_1_bits_uop_exceptionVec_13, io_enq_1_bits_uop_exceptionVec_12, io_enq_1_bits_uop_exceptionVec_11, io_enq_1_bits_uop_exceptionVec_10, io_enq_1_bits_uop_exceptionVec_9, io_enq_1_bits_uop_exceptionVec_8, io_enq_1_bits_uop_exceptionVec_7, io_enq_1_bits_uop_exceptionVec_6, io_enq_1_bits_uop_exceptionVec_5, io_enq_1_bits_uop_exceptionVec_4, io_enq_1_bits_uop_exceptionVec_3, io_enq_1_bits_uop_exceptionVec_2, io_enq_1_bits_uop_exceptionVec_1, io_enq_1_bits_uop_exceptionVec_0},
    preDecodeInfo_isRVC:io_enq_1_bits_uop_preDecodeInfo_isRVC,
    ftqPtr_flag:io_enq_1_bits_uop_ftqPtr_flag, ftqPtr_value:io_enq_1_bits_uop_ftqPtr_value,
    ftqOffset:io_enq_1_bits_uop_ftqOffset, fuOpType:io_enq_1_bits_uop_fuOpType,
    rfWen:io_enq_1_bits_uop_rfWen, fpWen:io_enq_1_bits_uop_fpWen,
    vpu_vstart:io_enq_1_bits_uop_vpu_vstart, vpu_veew:io_enq_1_bits_uop_vpu_veew,
    uopIdx:io_enq_1_bits_uop_uopIdx, pdest:io_enq_1_bits_uop_pdest,
    robIdx:'{flag:io_enq_1_bits_uop_robIdx_flag, value:io_enq_1_bits_uop_robIdx_value},
    dbg_enqRsTime:io_enq_1_bits_uop_debugInfo_enqRsTime,
    dbg_selectTime:io_enq_1_bits_uop_debugInfo_selectTime,
    dbg_issueTime:io_enq_1_bits_uop_debugInfo_issueTime,
    storeSetHit:io_enq_1_bits_uop_storeSetHit,
    waitForRobIdx_flag:io_enq_1_bits_uop_waitForRobIdx_flag, waitForRobIdx_value:io_enq_1_bits_uop_waitForRobIdx_value,
    loadWaitBit:io_enq_1_bits_uop_loadWaitBit, loadWaitStrict:io_enq_1_bits_uop_loadWaitStrict,
    lqIdx:'{flag:io_enq_1_bits_uop_lqIdx_flag, value:io_enq_1_bits_uop_lqIdx_value},
    sqIdx:'{flag:io_enq_1_bits_uop_sqIdx_flag, value:io_enq_1_bits_uop_sqIdx_value}};
  assign enq1_vec = '{
    isvec:io_enq_1_bits_isvec, isLastElem:1'b0, is128bit:io_enq_1_bits_is128bit,
    uop_unit_stride_fof:1'b0, usSecondInv:1'b0,
    elemIdx:io_enq_1_bits_elemIdx, alignedType:io_enq_1_bits_alignedType,
    mbIndex:io_enq_1_bits_mbIndex, elemIdxInsideVd:io_enq_1_bits_elemIdxInsideVd,
    reg_offset:io_enq_1_bits_reg_offset, vecActive:io_enq_1_bits_vecActive,
    is_first_ele:1'b0, mask:io_enq_1_bits_mask};
  assign enq1_cause = {io_enq_1_bits_rep_info_cause_10, io_enq_1_bits_rep_info_cause_9, io_enq_1_bits_rep_info_cause_8, io_enq_1_bits_rep_info_cause_7, io_enq_1_bits_rep_info_cause_6, io_enq_1_bits_rep_info_cause_5, io_enq_1_bits_rep_info_cause_4, io_enq_1_bits_rep_info_cause_3, io_enq_1_bits_rep_info_cause_2, io_enq_1_bits_rep_info_cause_1, io_enq_1_bits_rep_info_cause_0};
  assign enq1_data_inv = '{flag:io_enq_1_bits_rep_info_data_inv_sq_idx_flag, value:io_enq_1_bits_rep_info_data_inv_sq_idx_value};
  assign enq1_addr_inv = '{flag:io_enq_1_bits_rep_info_addr_inv_sq_idx_flag, value:io_enq_1_bits_rep_info_addr_inv_sq_idx_value};
  assign enq2_uop = '{
    exceptionVec:{io_enq_2_bits_uop_exceptionVec_23, io_enq_2_bits_uop_exceptionVec_22, io_enq_2_bits_uop_exceptionVec_21, io_enq_2_bits_uop_exceptionVec_20, io_enq_2_bits_uop_exceptionVec_19, io_enq_2_bits_uop_exceptionVec_18, io_enq_2_bits_uop_exceptionVec_17, io_enq_2_bits_uop_exceptionVec_16, io_enq_2_bits_uop_exceptionVec_15, io_enq_2_bits_uop_exceptionVec_14, io_enq_2_bits_uop_exceptionVec_13, io_enq_2_bits_uop_exceptionVec_12, io_enq_2_bits_uop_exceptionVec_11, io_enq_2_bits_uop_exceptionVec_10, io_enq_2_bits_uop_exceptionVec_9, io_enq_2_bits_uop_exceptionVec_8, io_enq_2_bits_uop_exceptionVec_7, io_enq_2_bits_uop_exceptionVec_6, io_enq_2_bits_uop_exceptionVec_5, io_enq_2_bits_uop_exceptionVec_4, io_enq_2_bits_uop_exceptionVec_3, io_enq_2_bits_uop_exceptionVec_2, io_enq_2_bits_uop_exceptionVec_1, io_enq_2_bits_uop_exceptionVec_0},
    preDecodeInfo_isRVC:io_enq_2_bits_uop_preDecodeInfo_isRVC,
    ftqPtr_flag:io_enq_2_bits_uop_ftqPtr_flag, ftqPtr_value:io_enq_2_bits_uop_ftqPtr_value,
    ftqOffset:io_enq_2_bits_uop_ftqOffset, fuOpType:io_enq_2_bits_uop_fuOpType,
    rfWen:io_enq_2_bits_uop_rfWen, fpWen:io_enq_2_bits_uop_fpWen,
    vpu_vstart:io_enq_2_bits_uop_vpu_vstart, vpu_veew:io_enq_2_bits_uop_vpu_veew,
    uopIdx:io_enq_2_bits_uop_uopIdx, pdest:io_enq_2_bits_uop_pdest,
    robIdx:'{flag:io_enq_2_bits_uop_robIdx_flag, value:io_enq_2_bits_uop_robIdx_value},
    dbg_enqRsTime:io_enq_2_bits_uop_debugInfo_enqRsTime,
    dbg_selectTime:io_enq_2_bits_uop_debugInfo_selectTime,
    dbg_issueTime:io_enq_2_bits_uop_debugInfo_issueTime,
    storeSetHit:io_enq_2_bits_uop_storeSetHit,
    waitForRobIdx_flag:io_enq_2_bits_uop_waitForRobIdx_flag, waitForRobIdx_value:io_enq_2_bits_uop_waitForRobIdx_value,
    loadWaitBit:io_enq_2_bits_uop_loadWaitBit, loadWaitStrict:io_enq_2_bits_uop_loadWaitStrict,
    lqIdx:'{flag:io_enq_2_bits_uop_lqIdx_flag, value:io_enq_2_bits_uop_lqIdx_value},
    sqIdx:'{flag:io_enq_2_bits_uop_sqIdx_flag, value:io_enq_2_bits_uop_sqIdx_value}};
  assign enq2_vec = '{
    isvec:io_enq_2_bits_isvec, isLastElem:1'b0, is128bit:io_enq_2_bits_is128bit,
    uop_unit_stride_fof:1'b0, usSecondInv:1'b0,
    elemIdx:io_enq_2_bits_elemIdx, alignedType:io_enq_2_bits_alignedType,
    mbIndex:io_enq_2_bits_mbIndex, elemIdxInsideVd:io_enq_2_bits_elemIdxInsideVd,
    reg_offset:io_enq_2_bits_reg_offset, vecActive:io_enq_2_bits_vecActive,
    is_first_ele:1'b0, mask:io_enq_2_bits_mask};
  assign enq2_cause = {io_enq_2_bits_rep_info_cause_10, io_enq_2_bits_rep_info_cause_9, io_enq_2_bits_rep_info_cause_8, io_enq_2_bits_rep_info_cause_7, io_enq_2_bits_rep_info_cause_6, io_enq_2_bits_rep_info_cause_5, io_enq_2_bits_rep_info_cause_4, io_enq_2_bits_rep_info_cause_3, io_enq_2_bits_rep_info_cause_2, io_enq_2_bits_rep_info_cause_1, io_enq_2_bits_rep_info_cause_0};
  assign enq2_data_inv = '{flag:io_enq_2_bits_rep_info_data_inv_sq_idx_flag, value:io_enq_2_bits_rep_info_data_inv_sq_idx_value};
  assign enq2_addr_inv = '{flag:io_enq_2_bits_rep_info_addr_inv_sq_idx_flag, value:io_enq_2_bits_rep_info_addr_inv_sq_idx_value};
  sq_ptr_t sta0_sq; assign sta0_sq = '{flag:io_storeAddrIn_0_bits_uop_sqIdx_flag, value:io_storeAddrIn_0_bits_uop_sqIdx_value};
  sq_ptr_t std0_sq; assign std0_sq = '{flag:io_storeDataIn_0_bits_uop_sqIdx_flag, value:io_storeDataIn_0_bits_uop_sqIdx_value};
  sq_ptr_t sta1_sq; assign sta1_sq = '{flag:io_storeAddrIn_1_bits_uop_sqIdx_flag, value:io_storeAddrIn_1_bits_uop_sqIdx_value};
  sq_ptr_t std1_sq; assign std1_sq = '{flag:io_storeDataIn_1_bits_uop_sqIdx_flag, value:io_storeDataIn_1_bits_uop_sqIdx_value};

  // ---- 输出侧解包 ----
  logic [2:0] rep_valid;
  lqr_uop_t   rep_uop [3];
  lqr_vec_t   rep_vec [3];
  logic [5:0] perf_value [13];
  assign io_replay_0_valid = rep_valid[0];
  assign io_replay_0_bits_uop_exceptionVec_0 = rep_uop[0].exceptionVec[0];
  assign io_replay_0_bits_uop_exceptionVec_1 = rep_uop[0].exceptionVec[1];
  assign io_replay_0_bits_uop_exceptionVec_2 = rep_uop[0].exceptionVec[2];
  assign io_replay_0_bits_uop_exceptionVec_6 = rep_uop[0].exceptionVec[6];
  assign io_replay_0_bits_uop_exceptionVec_7 = rep_uop[0].exceptionVec[7];
  assign io_replay_0_bits_uop_exceptionVec_8 = rep_uop[0].exceptionVec[8];
  assign io_replay_0_bits_uop_exceptionVec_9 = rep_uop[0].exceptionVec[9];
  assign io_replay_0_bits_uop_exceptionVec_10 = rep_uop[0].exceptionVec[10];
  assign io_replay_0_bits_uop_exceptionVec_11 = rep_uop[0].exceptionVec[11];
  assign io_replay_0_bits_uop_exceptionVec_12 = rep_uop[0].exceptionVec[12];
  assign io_replay_0_bits_uop_exceptionVec_14 = rep_uop[0].exceptionVec[14];
  assign io_replay_0_bits_uop_exceptionVec_15 = rep_uop[0].exceptionVec[15];
  assign io_replay_0_bits_uop_exceptionVec_16 = rep_uop[0].exceptionVec[16];
  assign io_replay_0_bits_uop_exceptionVec_17 = rep_uop[0].exceptionVec[17];
  assign io_replay_0_bits_uop_exceptionVec_18 = rep_uop[0].exceptionVec[18];
  assign io_replay_0_bits_uop_exceptionVec_19 = rep_uop[0].exceptionVec[19];
  assign io_replay_0_bits_uop_exceptionVec_20 = rep_uop[0].exceptionVec[20];
  assign io_replay_0_bits_uop_exceptionVec_22 = rep_uop[0].exceptionVec[22];
  assign io_replay_0_bits_uop_exceptionVec_23 = rep_uop[0].exceptionVec[23];
  assign io_replay_0_bits_uop_preDecodeInfo_isRVC = rep_uop[0].preDecodeInfo_isRVC;
  assign io_replay_0_bits_uop_ftqPtr_flag = rep_uop[0].ftqPtr_flag;
  assign io_replay_0_bits_uop_ftqPtr_value = rep_uop[0].ftqPtr_value;
  assign io_replay_0_bits_uop_ftqOffset = rep_uop[0].ftqOffset;
  assign io_replay_0_bits_uop_fuOpType = rep_uop[0].fuOpType;
  assign io_replay_0_bits_uop_rfWen = rep_uop[0].rfWen;
  assign io_replay_0_bits_uop_fpWen = rep_uop[0].fpWen;
  assign io_replay_0_bits_uop_vpu_vstart = rep_uop[0].vpu_vstart;
  assign io_replay_0_bits_uop_vpu_veew = rep_uop[0].vpu_veew;
  assign io_replay_0_bits_uop_uopIdx = rep_uop[0].uopIdx;
  assign io_replay_0_bits_uop_pdest = rep_uop[0].pdest;
  assign io_replay_0_bits_uop_robIdx_flag = rep_uop[0].robIdx.flag;
  assign io_replay_0_bits_uop_robIdx_value = rep_uop[0].robIdx.value;
  assign io_replay_0_bits_uop_debugInfo_enqRsTime = rep_uop[0].dbg_enqRsTime;
  assign io_replay_0_bits_uop_debugInfo_selectTime = rep_uop[0].dbg_selectTime;
  assign io_replay_0_bits_uop_debugInfo_issueTime = rep_uop[0].dbg_issueTime;
  assign io_replay_0_bits_uop_storeSetHit = rep_uop[0].storeSetHit;
  assign io_replay_0_bits_uop_waitForRobIdx_flag = rep_uop[0].waitForRobIdx_flag;
  assign io_replay_0_bits_uop_waitForRobIdx_value = rep_uop[0].waitForRobIdx_value;
  assign io_replay_0_bits_uop_loadWaitBit = rep_uop[0].loadWaitBit;
  assign io_replay_0_bits_uop_lqIdx_flag = rep_uop[0].lqIdx.flag;
  assign io_replay_0_bits_uop_lqIdx_value = rep_uop[0].lqIdx.value;
  assign io_replay_0_bits_uop_sqIdx_flag = rep_uop[0].sqIdx.flag;
  assign io_replay_0_bits_uop_sqIdx_value = rep_uop[0].sqIdx.value;
  assign io_replay_0_bits_mask = rep_vec[0].mask;
  assign io_replay_0_bits_isvec = rep_vec[0].isvec;
  assign io_replay_0_bits_is128bit = rep_vec[0].is128bit;
  assign io_replay_0_bits_elemIdx = rep_vec[0].elemIdx;
  assign io_replay_0_bits_alignedType = rep_vec[0].alignedType;
  assign io_replay_0_bits_mbIndex = rep_vec[0].mbIndex;
  assign io_replay_0_bits_reg_offset = rep_vec[0].reg_offset;
  assign io_replay_0_bits_elemIdxInsideVd = rep_vec[0].elemIdxInsideVd;
  assign io_replay_0_bits_vecActive = rep_vec[0].vecActive;
  assign io_replay_1_valid = rep_valid[1];
  assign io_replay_1_bits_uop_exceptionVec_0 = rep_uop[1].exceptionVec[0];
  assign io_replay_1_bits_uop_exceptionVec_1 = rep_uop[1].exceptionVec[1];
  assign io_replay_1_bits_uop_exceptionVec_2 = rep_uop[1].exceptionVec[2];
  assign io_replay_1_bits_uop_exceptionVec_6 = rep_uop[1].exceptionVec[6];
  assign io_replay_1_bits_uop_exceptionVec_7 = rep_uop[1].exceptionVec[7];
  assign io_replay_1_bits_uop_exceptionVec_8 = rep_uop[1].exceptionVec[8];
  assign io_replay_1_bits_uop_exceptionVec_9 = rep_uop[1].exceptionVec[9];
  assign io_replay_1_bits_uop_exceptionVec_10 = rep_uop[1].exceptionVec[10];
  assign io_replay_1_bits_uop_exceptionVec_11 = rep_uop[1].exceptionVec[11];
  assign io_replay_1_bits_uop_exceptionVec_12 = rep_uop[1].exceptionVec[12];
  assign io_replay_1_bits_uop_exceptionVec_14 = rep_uop[1].exceptionVec[14];
  assign io_replay_1_bits_uop_exceptionVec_15 = rep_uop[1].exceptionVec[15];
  assign io_replay_1_bits_uop_exceptionVec_16 = rep_uop[1].exceptionVec[16];
  assign io_replay_1_bits_uop_exceptionVec_17 = rep_uop[1].exceptionVec[17];
  assign io_replay_1_bits_uop_exceptionVec_18 = rep_uop[1].exceptionVec[18];
  assign io_replay_1_bits_uop_exceptionVec_19 = rep_uop[1].exceptionVec[19];
  assign io_replay_1_bits_uop_exceptionVec_20 = rep_uop[1].exceptionVec[20];
  assign io_replay_1_bits_uop_exceptionVec_22 = rep_uop[1].exceptionVec[22];
  assign io_replay_1_bits_uop_exceptionVec_23 = rep_uop[1].exceptionVec[23];
  assign io_replay_1_bits_uop_preDecodeInfo_isRVC = rep_uop[1].preDecodeInfo_isRVC;
  assign io_replay_1_bits_uop_ftqPtr_flag = rep_uop[1].ftqPtr_flag;
  assign io_replay_1_bits_uop_ftqPtr_value = rep_uop[1].ftqPtr_value;
  assign io_replay_1_bits_uop_ftqOffset = rep_uop[1].ftqOffset;
  assign io_replay_1_bits_uop_fuOpType = rep_uop[1].fuOpType;
  assign io_replay_1_bits_uop_rfWen = rep_uop[1].rfWen;
  assign io_replay_1_bits_uop_fpWen = rep_uop[1].fpWen;
  assign io_replay_1_bits_uop_vpu_vstart = rep_uop[1].vpu_vstart;
  assign io_replay_1_bits_uop_vpu_veew = rep_uop[1].vpu_veew;
  assign io_replay_1_bits_uop_uopIdx = rep_uop[1].uopIdx;
  assign io_replay_1_bits_uop_pdest = rep_uop[1].pdest;
  assign io_replay_1_bits_uop_robIdx_flag = rep_uop[1].robIdx.flag;
  assign io_replay_1_bits_uop_robIdx_value = rep_uop[1].robIdx.value;
  assign io_replay_1_bits_uop_debugInfo_enqRsTime = rep_uop[1].dbg_enqRsTime;
  assign io_replay_1_bits_uop_debugInfo_selectTime = rep_uop[1].dbg_selectTime;
  assign io_replay_1_bits_uop_debugInfo_issueTime = rep_uop[1].dbg_issueTime;
  assign io_replay_1_bits_uop_storeSetHit = rep_uop[1].storeSetHit;
  assign io_replay_1_bits_uop_waitForRobIdx_flag = rep_uop[1].waitForRobIdx_flag;
  assign io_replay_1_bits_uop_waitForRobIdx_value = rep_uop[1].waitForRobIdx_value;
  assign io_replay_1_bits_uop_loadWaitBit = rep_uop[1].loadWaitBit;
  assign io_replay_1_bits_uop_lqIdx_flag = rep_uop[1].lqIdx.flag;
  assign io_replay_1_bits_uop_lqIdx_value = rep_uop[1].lqIdx.value;
  assign io_replay_1_bits_uop_sqIdx_flag = rep_uop[1].sqIdx.flag;
  assign io_replay_1_bits_uop_sqIdx_value = rep_uop[1].sqIdx.value;
  assign io_replay_1_bits_mask = rep_vec[1].mask;
  assign io_replay_1_bits_isvec = rep_vec[1].isvec;
  assign io_replay_1_bits_is128bit = rep_vec[1].is128bit;
  assign io_replay_1_bits_elemIdx = rep_vec[1].elemIdx;
  assign io_replay_1_bits_alignedType = rep_vec[1].alignedType;
  assign io_replay_1_bits_mbIndex = rep_vec[1].mbIndex;
  assign io_replay_1_bits_reg_offset = rep_vec[1].reg_offset;
  assign io_replay_1_bits_elemIdxInsideVd = rep_vec[1].elemIdxInsideVd;
  assign io_replay_1_bits_vecActive = rep_vec[1].vecActive;
  assign io_replay_2_valid = rep_valid[2];
  assign io_replay_2_bits_uop_exceptionVec_0 = rep_uop[2].exceptionVec[0];
  assign io_replay_2_bits_uop_exceptionVec_1 = rep_uop[2].exceptionVec[1];
  assign io_replay_2_bits_uop_exceptionVec_2 = rep_uop[2].exceptionVec[2];
  assign io_replay_2_bits_uop_exceptionVec_6 = rep_uop[2].exceptionVec[6];
  assign io_replay_2_bits_uop_exceptionVec_7 = rep_uop[2].exceptionVec[7];
  assign io_replay_2_bits_uop_exceptionVec_8 = rep_uop[2].exceptionVec[8];
  assign io_replay_2_bits_uop_exceptionVec_9 = rep_uop[2].exceptionVec[9];
  assign io_replay_2_bits_uop_exceptionVec_10 = rep_uop[2].exceptionVec[10];
  assign io_replay_2_bits_uop_exceptionVec_11 = rep_uop[2].exceptionVec[11];
  assign io_replay_2_bits_uop_exceptionVec_12 = rep_uop[2].exceptionVec[12];
  assign io_replay_2_bits_uop_exceptionVec_14 = rep_uop[2].exceptionVec[14];
  assign io_replay_2_bits_uop_exceptionVec_15 = rep_uop[2].exceptionVec[15];
  assign io_replay_2_bits_uop_exceptionVec_16 = rep_uop[2].exceptionVec[16];
  assign io_replay_2_bits_uop_exceptionVec_17 = rep_uop[2].exceptionVec[17];
  assign io_replay_2_bits_uop_exceptionVec_18 = rep_uop[2].exceptionVec[18];
  assign io_replay_2_bits_uop_exceptionVec_19 = rep_uop[2].exceptionVec[19];
  assign io_replay_2_bits_uop_exceptionVec_20 = rep_uop[2].exceptionVec[20];
  assign io_replay_2_bits_uop_exceptionVec_22 = rep_uop[2].exceptionVec[22];
  assign io_replay_2_bits_uop_exceptionVec_23 = rep_uop[2].exceptionVec[23];
  assign io_replay_2_bits_uop_preDecodeInfo_isRVC = rep_uop[2].preDecodeInfo_isRVC;
  assign io_replay_2_bits_uop_ftqPtr_flag = rep_uop[2].ftqPtr_flag;
  assign io_replay_2_bits_uop_ftqPtr_value = rep_uop[2].ftqPtr_value;
  assign io_replay_2_bits_uop_ftqOffset = rep_uop[2].ftqOffset;
  assign io_replay_2_bits_uop_fuOpType = rep_uop[2].fuOpType;
  assign io_replay_2_bits_uop_rfWen = rep_uop[2].rfWen;
  assign io_replay_2_bits_uop_fpWen = rep_uop[2].fpWen;
  assign io_replay_2_bits_uop_vpu_vstart = rep_uop[2].vpu_vstart;
  assign io_replay_2_bits_uop_vpu_veew = rep_uop[2].vpu_veew;
  assign io_replay_2_bits_uop_uopIdx = rep_uop[2].uopIdx;
  assign io_replay_2_bits_uop_pdest = rep_uop[2].pdest;
  assign io_replay_2_bits_uop_robIdx_flag = rep_uop[2].robIdx.flag;
  assign io_replay_2_bits_uop_robIdx_value = rep_uop[2].robIdx.value;
  assign io_replay_2_bits_uop_debugInfo_enqRsTime = rep_uop[2].dbg_enqRsTime;
  assign io_replay_2_bits_uop_debugInfo_selectTime = rep_uop[2].dbg_selectTime;
  assign io_replay_2_bits_uop_debugInfo_issueTime = rep_uop[2].dbg_issueTime;
  assign io_replay_2_bits_uop_storeSetHit = rep_uop[2].storeSetHit;
  assign io_replay_2_bits_uop_waitForRobIdx_flag = rep_uop[2].waitForRobIdx_flag;
  assign io_replay_2_bits_uop_waitForRobIdx_value = rep_uop[2].waitForRobIdx_value;
  assign io_replay_2_bits_uop_loadWaitBit = rep_uop[2].loadWaitBit;
  assign io_replay_2_bits_uop_lqIdx_flag = rep_uop[2].lqIdx.flag;
  assign io_replay_2_bits_uop_lqIdx_value = rep_uop[2].lqIdx.value;
  assign io_replay_2_bits_uop_sqIdx_flag = rep_uop[2].sqIdx.flag;
  assign io_replay_2_bits_uop_sqIdx_value = rep_uop[2].sqIdx.value;
  assign io_replay_2_bits_mask = rep_vec[2].mask;
  assign io_replay_2_bits_isvec = rep_vec[2].isvec;
  assign io_replay_2_bits_is128bit = rep_vec[2].is128bit;
  assign io_replay_2_bits_elemIdx = rep_vec[2].elemIdx;
  assign io_replay_2_bits_alignedType = rep_vec[2].alignedType;
  assign io_replay_2_bits_mbIndex = rep_vec[2].mbIndex;
  assign io_replay_2_bits_reg_offset = rep_vec[2].reg_offset;
  assign io_replay_2_bits_elemIdxInsideVd = rep_vec[2].elemIdxInsideVd;
  assign io_replay_2_bits_vecActive = rep_vec[2].vecActive;
  assign io_perf_0_value = perf_value[0];
  assign io_perf_1_value = perf_value[1];
  assign io_perf_2_value = perf_value[2];
  assign io_perf_3_value = perf_value[3];
  assign io_perf_4_value = perf_value[4];
  assign io_perf_5_value = perf_value[5];
  assign io_perf_6_value = perf_value[6];
  assign io_perf_7_value = perf_value[7];
  assign io_perf_8_value = perf_value[8];
  assign io_perf_9_value = perf_value[9];
  assign io_perf_10_value = perf_value[10];
  assign io_perf_11_value = perf_value[11];
  assign io_perf_12_value = perf_value[12];
  xs_LoadQueueReplay_core u_core (
    .clock(clock), .reset(reset),
    .redirect_valid(io_redirect_valid),
    .redirect_robIdx('{flag:io_redirect_bits_robIdx_flag, value:io_redirect_bits_robIdx_value}),
    .redirect_level(io_redirect_bits_level),
    .vecFb_valid({io_vecFeedback_1_valid, io_vecFeedback_0_valid}),
    .vecFb_robIdx({vfb1_rob, vfb0_rob}),
    .vecFb_uopIdx({io_vecFeedback_1_bits_uopidx, io_vecFeedback_0_bits_uopidx}),
    .vecFb_isCommit({io_vecFeedback_1_bits_feedback_0, io_vecFeedback_0_bits_feedback_0}),
    .vecFb_isFlush({io_vecFeedback_1_bits_feedback_1, io_vecFeedback_0_bits_feedback_1}),
    .enq_valid({io_enq_2_valid, io_enq_1_valid, io_enq_0_valid}),
    .enq_uop({enq2_uop, enq1_uop, enq0_uop}),
    .enq_vec({enq2_vec, enq1_vec, enq0_vec}),
    .enq_vaddr({io_enq_2_bits_vaddr, io_enq_1_bits_vaddr, io_enq_0_bits_vaddr}),
    .enq_tlbMiss({io_enq_2_bits_tlbMiss, io_enq_1_bits_tlbMiss, io_enq_0_bits_tlbMiss}),
    .enq_isLoadReplay({io_enq_2_bits_isLoadReplay, io_enq_1_bits_isLoadReplay, io_enq_0_bits_isLoadReplay}),
    .enq_handledByMSHR({io_enq_2_bits_handledByMSHR, io_enq_1_bits_handledByMSHR, io_enq_0_bits_handledByMSHR}),
    .enq_schedIndex({io_enq_2_bits_schedIndex, io_enq_1_bits_schedIndex, io_enq_0_bits_schedIndex}),
    .enq_cause({enq2_cause, enq1_cause, enq0_cause}),
    .enq_mshr_id({io_enq_2_bits_rep_info_mshr_id, io_enq_1_bits_rep_info_mshr_id, io_enq_0_bits_rep_info_mshr_id}),
    .enq_full_fwd({io_enq_2_bits_rep_info_full_fwd, io_enq_1_bits_rep_info_full_fwd, io_enq_0_bits_rep_info_full_fwd}),
    .enq_data_inv_sq_idx({enq2_data_inv, enq1_data_inv, enq0_data_inv}),
    .enq_addr_inv_sq_idx({enq2_addr_inv, enq1_addr_inv, enq0_addr_inv}),
    .enq_last_beat({io_enq_2_bits_rep_info_last_beat, io_enq_1_bits_rep_info_last_beat, io_enq_0_bits_rep_info_last_beat}),
    .enq_tlb_id({io_enq_2_bits_rep_info_tlb_id, io_enq_1_bits_rep_info_tlb_id, io_enq_0_bits_rep_info_tlb_id}),
    .enq_tlb_full({io_enq_2_bits_rep_info_tlb_full, io_enq_1_bits_rep_info_tlb_full, io_enq_0_bits_rep_info_tlb_full}),
    .staIn_valid({io_storeAddrIn_1_valid, io_storeAddrIn_0_valid}),
    .staIn_sqIdx({sta1_sq, sta0_sq}),
    .staIn_miss({io_storeAddrIn_1_bits_miss, io_storeAddrIn_0_bits_miss}),
    .stdIn_valid({io_storeDataIn_1_valid, io_storeDataIn_0_valid}),
    .stdIn_sqIdx({std1_sq, std0_sq}),
    .stAddrReadySqPtr('{flag:io_stAddrReadySqPtr_flag, value:io_stAddrReadySqPtr_value}),
    .stAddrReadyVec({io_stAddrReadyVec_55, io_stAddrReadyVec_54, io_stAddrReadyVec_53, io_stAddrReadyVec_52, io_stAddrReadyVec_51, io_stAddrReadyVec_50, io_stAddrReadyVec_49, io_stAddrReadyVec_48, io_stAddrReadyVec_47, io_stAddrReadyVec_46, io_stAddrReadyVec_45, io_stAddrReadyVec_44, io_stAddrReadyVec_43, io_stAddrReadyVec_42, io_stAddrReadyVec_41, io_stAddrReadyVec_40, io_stAddrReadyVec_39, io_stAddrReadyVec_38, io_stAddrReadyVec_37, io_stAddrReadyVec_36, io_stAddrReadyVec_35, io_stAddrReadyVec_34, io_stAddrReadyVec_33, io_stAddrReadyVec_32, io_stAddrReadyVec_31, io_stAddrReadyVec_30, io_stAddrReadyVec_29, io_stAddrReadyVec_28, io_stAddrReadyVec_27, io_stAddrReadyVec_26, io_stAddrReadyVec_25, io_stAddrReadyVec_24, io_stAddrReadyVec_23, io_stAddrReadyVec_22, io_stAddrReadyVec_21, io_stAddrReadyVec_20, io_stAddrReadyVec_19, io_stAddrReadyVec_18, io_stAddrReadyVec_17, io_stAddrReadyVec_16, io_stAddrReadyVec_15, io_stAddrReadyVec_14, io_stAddrReadyVec_13, io_stAddrReadyVec_12, io_stAddrReadyVec_11, io_stAddrReadyVec_10, io_stAddrReadyVec_9, io_stAddrReadyVec_8, io_stAddrReadyVec_7, io_stAddrReadyVec_6, io_stAddrReadyVec_5, io_stAddrReadyVec_4, io_stAddrReadyVec_3, io_stAddrReadyVec_2, io_stAddrReadyVec_1, io_stAddrReadyVec_0}),
    .stDataReadySqPtr('{flag:io_stDataReadySqPtr_flag, value:io_stDataReadySqPtr_value}),
    .stDataReadyVec({io_stDataReadyVec_55, io_stDataReadyVec_54, io_stDataReadyVec_53, io_stDataReadyVec_52, io_stDataReadyVec_51, io_stDataReadyVec_50, io_stDataReadyVec_49, io_stDataReadyVec_48, io_stDataReadyVec_47, io_stDataReadyVec_46, io_stDataReadyVec_45, io_stDataReadyVec_44, io_stDataReadyVec_43, io_stDataReadyVec_42, io_stDataReadyVec_41, io_stDataReadyVec_40, io_stDataReadyVec_39, io_stDataReadyVec_38, io_stDataReadyVec_37, io_stDataReadyVec_36, io_stDataReadyVec_35, io_stDataReadyVec_34, io_stDataReadyVec_33, io_stDataReadyVec_32, io_stDataReadyVec_31, io_stDataReadyVec_30, io_stDataReadyVec_29, io_stDataReadyVec_28, io_stDataReadyVec_27, io_stDataReadyVec_26, io_stDataReadyVec_25, io_stDataReadyVec_24, io_stDataReadyVec_23, io_stDataReadyVec_22, io_stDataReadyVec_21, io_stDataReadyVec_20, io_stDataReadyVec_19, io_stDataReadyVec_18, io_stDataReadyVec_17, io_stDataReadyVec_16, io_stDataReadyVec_15, io_stDataReadyVec_14, io_stDataReadyVec_13, io_stDataReadyVec_12, io_stDataReadyVec_11, io_stDataReadyVec_10, io_stDataReadyVec_9, io_stDataReadyVec_8, io_stDataReadyVec_7, io_stDataReadyVec_6, io_stDataReadyVec_5, io_stDataReadyVec_4, io_stDataReadyVec_3, io_stDataReadyVec_2, io_stDataReadyVec_1, io_stDataReadyVec_0}),
    .tl_d_valid(io_tl_d_channel_valid), .tl_d_mshrid(io_tl_d_channel_mshrid),
    .sqEmpty(io_sqEmpty),
    .ldWbPtr('{flag:io_ldWbPtr_flag, value:io_ldWbPtr_value}),
    .rarFull(io_rarFull), .rawFull(io_rawFull),
    .loadMisalignFull(io_loadMisalignFull), .misalignAllowSpec(io_misalignAllowSpec),
    .l2_hint_valid(io_l2_hint_valid), .l2_hint_sourceId(io_l2_hint_bits_sourceId),
    .l2_hint_isKeyword(io_l2_hint_bits_isKeyword),
    .tlb_hint_valid(io_tlb_hint_resp_valid), .tlb_hint_id(io_tlb_hint_resp_bits_id),
    .tlb_hint_replay_all(io_tlb_hint_resp_bits_replay_all),
    .dtd_robHeadVaddr_valid(io_debugTopDown_robHeadVaddr_valid),
    .dtd_robHeadVaddr_bits(io_debugTopDown_robHeadVaddr_bits),
    .dtd_robHeadMissInDTlb(io_debugTopDown_robHeadMissInDTlb),
    .dtd_robHeadTlbReplay(io_debugTopDown_robHeadTlbReplay),
    .dtd_robHeadTlbMiss(io_debugTopDown_robHeadTlbMiss),
    .dtd_robHeadLoadVio(io_debugTopDown_robHeadLoadVio),
    .dtd_robHeadLoadMSHR(io_debugTopDown_robHeadLoadMSHR),
    .replay_valid({rep_valid[2], rep_valid[1], rep_valid[0]}),
    .replay_ready({io_replay_2_ready, io_replay_1_ready, io_replay_0_ready}),
    .replay_uop({rep_uop[2], rep_uop[1], rep_uop[0]}),
    .replay_vaddr({io_replay_2_bits_vaddr, io_replay_1_bits_vaddr, io_replay_0_bits_vaddr}),
    .replay_vec({rep_vec[2], rep_vec[1], rep_vec[0]}),
    .replay_mshrid({io_replay_2_bits_mshrid, io_replay_1_bits_mshrid, io_replay_0_bits_mshrid}),
    .replay_forward_tlDchannel({io_replay_2_bits_forward_tlDchannel, io_replay_1_bits_forward_tlDchannel, io_replay_0_bits_forward_tlDchannel}),
    .replay_schedIndex({io_replay_2_bits_schedIndex, io_replay_1_bits_schedIndex, io_replay_0_bits_schedIndex}),
    .lqFull(io_lqFull),
    .perf_value(perf_value)
  );
endmodule
