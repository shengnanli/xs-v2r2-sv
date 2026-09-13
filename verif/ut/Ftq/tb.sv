// tb.sv —— Ftq UT：golden `Ftq` 与重写 `Ftq_xs` 双例化，同激励逐拍比全部 196 个输出。
//
// 激励不是均匀随机：Ftq 是 64 项环形取指目标队列，端口间有强协议约束
// （s2/s3 预测覆盖必须带 s1 分配到的 ftqIdx、pdWb 只对已发过取指的块有效、
//  rob 提交要把某一块的 16 个槽都标掉 commPtr 才推进）。纯随机会让队列永远
//  在“刚入队就被冲刷”的状态里空转 —— errors=0 但什么都没测到。
// 因此本 tb：
//   · s2/s3 的 ftqIdx 取自 golden 的 io_toBpu_enq_ptr（= bpuPtr）延迟 1/2 拍，
//     还原真实 BPU 三级流水的“同一块”语义；
//   · pdWb 的 ftqIdx 跟着 io_toIfu_req 发出的块走（延迟若干拍模拟 IFU 预解码）；
//   · rob 提交用一个缓慢推进的 commit_anchor 逐块逐槽扫，保证 commPtr 真能前进；
//   · 后端 redirect 稀疏（~2%），其中约 1/3 带 satpFlush（G1 新增通路）。
// 末尾有覆盖闸：任一关键事件计数为 0 直接判 FAIL —— 防“激励打不到的假绿”。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  longint errors = 0, checks = 0;
  always #5 clk = ~clk;

  // ---- 输入信号 ----
  logic io_fromBpu_resp_valid;
  logic [49:0] io_fromBpu_resp_bits_s1_pc_3;
  logic [63:0] io_fromBpu_resp_bits_s1_full_pred_0_predCycle;
  logic io_fromBpu_resp_bits_s1_full_pred_3_br_taken_mask_0;
  logic io_fromBpu_resp_bits_s1_full_pred_3_br_taken_mask_1;
  logic io_fromBpu_resp_bits_s1_full_pred_3_slot_valids_0;
  logic io_fromBpu_resp_bits_s1_full_pred_3_slot_valids_1;
  logic [49:0] io_fromBpu_resp_bits_s1_full_pred_3_targets_0;
  logic [49:0] io_fromBpu_resp_bits_s1_full_pred_3_targets_1;
  logic [3:0] io_fromBpu_resp_bits_s1_full_pred_3_offsets_0;
  logic [3:0] io_fromBpu_resp_bits_s1_full_pred_3_offsets_1;
  logic [49:0] io_fromBpu_resp_bits_s1_full_pred_3_fallThroughAddr;
  logic io_fromBpu_resp_bits_s1_full_pred_3_fallThroughErr;
  logic io_fromBpu_resp_bits_s1_full_pred_3_is_br_sharing;
  logic io_fromBpu_resp_bits_s1_full_pred_3_hit;
  logic [49:0] io_fromBpu_resp_bits_s2_pc_3;
  logic io_fromBpu_resp_bits_s2_valid_3;
  logic io_fromBpu_resp_bits_s2_hasRedirect_3;
  logic io_fromBpu_resp_bits_s2_ftq_idx_flag;
  logic [5:0] io_fromBpu_resp_bits_s2_ftq_idx_value;
  logic [63:0] io_fromBpu_resp_bits_s2_full_pred_0_predCycle;
  logic io_fromBpu_resp_bits_s2_full_pred_3_br_taken_mask_0;
  logic io_fromBpu_resp_bits_s2_full_pred_3_br_taken_mask_1;
  logic io_fromBpu_resp_bits_s2_full_pred_3_slot_valids_0;
  logic io_fromBpu_resp_bits_s2_full_pred_3_slot_valids_1;
  logic [49:0] io_fromBpu_resp_bits_s2_full_pred_3_targets_0;
  logic [49:0] io_fromBpu_resp_bits_s2_full_pred_3_targets_1;
  logic [3:0] io_fromBpu_resp_bits_s2_full_pred_3_offsets_0;
  logic [3:0] io_fromBpu_resp_bits_s2_full_pred_3_offsets_1;
  logic [49:0] io_fromBpu_resp_bits_s2_full_pred_3_fallThroughAddr;
  logic io_fromBpu_resp_bits_s2_full_pred_3_fallThroughErr;
  logic io_fromBpu_resp_bits_s2_full_pred_3_is_br_sharing;
  logic io_fromBpu_resp_bits_s2_full_pred_3_hit;
  logic [49:0] io_fromBpu_resp_bits_s3_pc_0;
  logic [49:0] io_fromBpu_resp_bits_s3_pc_3;
  logic io_fromBpu_resp_bits_s3_valid_3;
  logic io_fromBpu_resp_bits_s3_hasRedirect_3;
  logic io_fromBpu_resp_bits_s3_ftq_idx_flag;
  logic [5:0] io_fromBpu_resp_bits_s3_ftq_idx_value;
  logic [63:0] io_fromBpu_resp_bits_s3_full_pred_0_predCycle;
  logic io_fromBpu_resp_bits_s3_full_pred_3_br_taken_mask_0;
  logic io_fromBpu_resp_bits_s3_full_pred_3_br_taken_mask_1;
  logic io_fromBpu_resp_bits_s3_full_pred_3_slot_valids_0;
  logic io_fromBpu_resp_bits_s3_full_pred_3_slot_valids_1;
  logic [49:0] io_fromBpu_resp_bits_s3_full_pred_3_targets_0;
  logic [49:0] io_fromBpu_resp_bits_s3_full_pred_3_targets_1;
  logic [3:0] io_fromBpu_resp_bits_s3_full_pred_3_offsets_0;
  logic [3:0] io_fromBpu_resp_bits_s3_full_pred_3_offsets_1;
  logic [49:0] io_fromBpu_resp_bits_s3_full_pred_3_fallThroughAddr;
  logic io_fromBpu_resp_bits_s3_full_pred_3_fallThroughErr;
  logic io_fromBpu_resp_bits_s3_full_pred_3_is_br_sharing;
  logic io_fromBpu_resp_bits_s3_full_pred_3_hit;
  logic [515:0] io_fromBpu_resp_bits_last_stage_meta;
  logic io_fromBpu_resp_bits_last_stage_spec_info_histPtr_flag;
  logic [7:0] io_fromBpu_resp_bits_last_stage_spec_info_histPtr_value;
  logic [3:0] io_fromBpu_resp_bits_last_stage_spec_info_ssp;
  logic [2:0] io_fromBpu_resp_bits_last_stage_spec_info_sctr;
  logic io_fromBpu_resp_bits_last_stage_spec_info_TOSW_flag;
  logic [4:0] io_fromBpu_resp_bits_last_stage_spec_info_TOSW_value;
  logic io_fromBpu_resp_bits_last_stage_spec_info_TOSR_flag;
  logic [4:0] io_fromBpu_resp_bits_last_stage_spec_info_TOSR_value;
  logic io_fromBpu_resp_bits_last_stage_spec_info_NOS_flag;
  logic [4:0] io_fromBpu_resp_bits_last_stage_spec_info_NOS_value;
  logic [49:0] io_fromBpu_resp_bits_last_stage_spec_info_topAddr;
  logic io_fromBpu_resp_bits_last_stage_spec_info_sc_disagree_0;
  logic io_fromBpu_resp_bits_last_stage_spec_info_sc_disagree_1;
  logic io_fromBpu_resp_bits_last_stage_ftb_entry_isCall;
  logic io_fromBpu_resp_bits_last_stage_ftb_entry_isRet;
  logic io_fromBpu_resp_bits_last_stage_ftb_entry_isJalr;
  logic io_fromBpu_resp_bits_last_stage_ftb_entry_valid;
  logic [3:0] io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_offset;
  logic io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_sharing;
  logic io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_valid;
  logic [11:0] io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_lower;
  logic [1:0] io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat;
  logic [3:0] io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_offset;
  logic io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_sharing;
  logic io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_valid;
  logic [19:0] io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_lower;
  logic [1:0] io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_tarStat;
  logic [3:0] io_fromBpu_resp_bits_last_stage_ftb_entry_pftAddr;
  logic io_fromBpu_resp_bits_last_stage_ftb_entry_carry;
  logic io_fromBpu_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call;
  logic io_fromBpu_resp_bits_last_stage_ftb_entry_strong_bias_0;
  logic io_fromBpu_resp_bits_last_stage_ftb_entry_strong_bias_1;
  logic io_fromBpu_resp_bits_topdown_info_reasons_1;
  logic io_fromBpu_resp_bits_topdown_info_reasons_2;
  logic io_fromBpu_resp_bits_topdown_info_reasons_3;
  logic io_fromBpu_resp_bits_topdown_info_reasons_4;
  logic io_fromBpu_resp_bits_topdown_info_reasons_5;
  logic io_fromBpu_resp_bits_topdown_info_reasons_6;
  logic io_fromBpu_resp_bits_topdown_info_reasons_7;
  logic io_fromBpu_resp_bits_topdown_info_reasons_8;
  logic io_fromBpu_resp_bits_topdown_info_reasons_9;
  logic io_fromBpu_resp_bits_topdown_info_reasons_12;
  logic io_fromIfu_pdWb_valid;
  logic [49:0] io_fromIfu_pdWb_bits_pc_0;
  logic [49:0] io_fromIfu_pdWb_bits_pc_1;
  logic [49:0] io_fromIfu_pdWb_bits_pc_2;
  logic [49:0] io_fromIfu_pdWb_bits_pc_3;
  logic [49:0] io_fromIfu_pdWb_bits_pc_4;
  logic [49:0] io_fromIfu_pdWb_bits_pc_5;
  logic [49:0] io_fromIfu_pdWb_bits_pc_6;
  logic [49:0] io_fromIfu_pdWb_bits_pc_7;
  logic [49:0] io_fromIfu_pdWb_bits_pc_8;
  logic [49:0] io_fromIfu_pdWb_bits_pc_9;
  logic [49:0] io_fromIfu_pdWb_bits_pc_10;
  logic [49:0] io_fromIfu_pdWb_bits_pc_11;
  logic [49:0] io_fromIfu_pdWb_bits_pc_12;
  logic [49:0] io_fromIfu_pdWb_bits_pc_13;
  logic [49:0] io_fromIfu_pdWb_bits_pc_14;
  logic [49:0] io_fromIfu_pdWb_bits_pc_15;
  logic io_fromIfu_pdWb_bits_pd_0_valid;
  logic io_fromIfu_pdWb_bits_pd_0_isRVC;
  logic [1:0] io_fromIfu_pdWb_bits_pd_0_brType;
  logic io_fromIfu_pdWb_bits_pd_0_isCall;
  logic io_fromIfu_pdWb_bits_pd_0_isRet;
  logic io_fromIfu_pdWb_bits_pd_1_valid;
  logic io_fromIfu_pdWb_bits_pd_1_isRVC;
  logic [1:0] io_fromIfu_pdWb_bits_pd_1_brType;
  logic io_fromIfu_pdWb_bits_pd_1_isCall;
  logic io_fromIfu_pdWb_bits_pd_1_isRet;
  logic io_fromIfu_pdWb_bits_pd_2_valid;
  logic io_fromIfu_pdWb_bits_pd_2_isRVC;
  logic [1:0] io_fromIfu_pdWb_bits_pd_2_brType;
  logic io_fromIfu_pdWb_bits_pd_2_isCall;
  logic io_fromIfu_pdWb_bits_pd_2_isRet;
  logic io_fromIfu_pdWb_bits_pd_3_valid;
  logic io_fromIfu_pdWb_bits_pd_3_isRVC;
  logic [1:0] io_fromIfu_pdWb_bits_pd_3_brType;
  logic io_fromIfu_pdWb_bits_pd_3_isCall;
  logic io_fromIfu_pdWb_bits_pd_3_isRet;
  logic io_fromIfu_pdWb_bits_pd_4_valid;
  logic io_fromIfu_pdWb_bits_pd_4_isRVC;
  logic [1:0] io_fromIfu_pdWb_bits_pd_4_brType;
  logic io_fromIfu_pdWb_bits_pd_4_isCall;
  logic io_fromIfu_pdWb_bits_pd_4_isRet;
  logic io_fromIfu_pdWb_bits_pd_5_valid;
  logic io_fromIfu_pdWb_bits_pd_5_isRVC;
  logic [1:0] io_fromIfu_pdWb_bits_pd_5_brType;
  logic io_fromIfu_pdWb_bits_pd_5_isCall;
  logic io_fromIfu_pdWb_bits_pd_5_isRet;
  logic io_fromIfu_pdWb_bits_pd_6_valid;
  logic io_fromIfu_pdWb_bits_pd_6_isRVC;
  logic [1:0] io_fromIfu_pdWb_bits_pd_6_brType;
  logic io_fromIfu_pdWb_bits_pd_6_isCall;
  logic io_fromIfu_pdWb_bits_pd_6_isRet;
  logic io_fromIfu_pdWb_bits_pd_7_valid;
  logic io_fromIfu_pdWb_bits_pd_7_isRVC;
  logic [1:0] io_fromIfu_pdWb_bits_pd_7_brType;
  logic io_fromIfu_pdWb_bits_pd_7_isCall;
  logic io_fromIfu_pdWb_bits_pd_7_isRet;
  logic io_fromIfu_pdWb_bits_pd_8_valid;
  logic io_fromIfu_pdWb_bits_pd_8_isRVC;
  logic [1:0] io_fromIfu_pdWb_bits_pd_8_brType;
  logic io_fromIfu_pdWb_bits_pd_8_isCall;
  logic io_fromIfu_pdWb_bits_pd_8_isRet;
  logic io_fromIfu_pdWb_bits_pd_9_valid;
  logic io_fromIfu_pdWb_bits_pd_9_isRVC;
  logic [1:0] io_fromIfu_pdWb_bits_pd_9_brType;
  logic io_fromIfu_pdWb_bits_pd_9_isCall;
  logic io_fromIfu_pdWb_bits_pd_9_isRet;
  logic io_fromIfu_pdWb_bits_pd_10_valid;
  logic io_fromIfu_pdWb_bits_pd_10_isRVC;
  logic [1:0] io_fromIfu_pdWb_bits_pd_10_brType;
  logic io_fromIfu_pdWb_bits_pd_10_isCall;
  logic io_fromIfu_pdWb_bits_pd_10_isRet;
  logic io_fromIfu_pdWb_bits_pd_11_valid;
  logic io_fromIfu_pdWb_bits_pd_11_isRVC;
  logic [1:0] io_fromIfu_pdWb_bits_pd_11_brType;
  logic io_fromIfu_pdWb_bits_pd_11_isCall;
  logic io_fromIfu_pdWb_bits_pd_11_isRet;
  logic io_fromIfu_pdWb_bits_pd_12_valid;
  logic io_fromIfu_pdWb_bits_pd_12_isRVC;
  logic [1:0] io_fromIfu_pdWb_bits_pd_12_brType;
  logic io_fromIfu_pdWb_bits_pd_12_isCall;
  logic io_fromIfu_pdWb_bits_pd_12_isRet;
  logic io_fromIfu_pdWb_bits_pd_13_valid;
  logic io_fromIfu_pdWb_bits_pd_13_isRVC;
  logic [1:0] io_fromIfu_pdWb_bits_pd_13_brType;
  logic io_fromIfu_pdWb_bits_pd_13_isCall;
  logic io_fromIfu_pdWb_bits_pd_13_isRet;
  logic io_fromIfu_pdWb_bits_pd_14_valid;
  logic io_fromIfu_pdWb_bits_pd_14_isRVC;
  logic [1:0] io_fromIfu_pdWb_bits_pd_14_brType;
  logic io_fromIfu_pdWb_bits_pd_14_isCall;
  logic io_fromIfu_pdWb_bits_pd_14_isRet;
  logic io_fromIfu_pdWb_bits_pd_15_valid;
  logic io_fromIfu_pdWb_bits_pd_15_isRVC;
  logic [1:0] io_fromIfu_pdWb_bits_pd_15_brType;
  logic io_fromIfu_pdWb_bits_pd_15_isCall;
  logic io_fromIfu_pdWb_bits_pd_15_isRet;
  logic io_fromIfu_pdWb_bits_ftqIdx_flag;
  logic [5:0] io_fromIfu_pdWb_bits_ftqIdx_value;
  logic io_fromIfu_pdWb_bits_misOffset_valid;
  logic [3:0] io_fromIfu_pdWb_bits_misOffset_bits;
  logic io_fromIfu_pdWb_bits_cfiOffset_valid;
  logic [49:0] io_fromIfu_pdWb_bits_target;
  logic [49:0] io_fromIfu_pdWb_bits_jalTarget;
  logic io_fromIfu_pdWb_bits_instrRange_0;
  logic io_fromIfu_pdWb_bits_instrRange_1;
  logic io_fromIfu_pdWb_bits_instrRange_2;
  logic io_fromIfu_pdWb_bits_instrRange_3;
  logic io_fromIfu_pdWb_bits_instrRange_4;
  logic io_fromIfu_pdWb_bits_instrRange_5;
  logic io_fromIfu_pdWb_bits_instrRange_6;
  logic io_fromIfu_pdWb_bits_instrRange_7;
  logic io_fromIfu_pdWb_bits_instrRange_8;
  logic io_fromIfu_pdWb_bits_instrRange_9;
  logic io_fromIfu_pdWb_bits_instrRange_10;
  logic io_fromIfu_pdWb_bits_instrRange_11;
  logic io_fromIfu_pdWb_bits_instrRange_12;
  logic io_fromIfu_pdWb_bits_instrRange_13;
  logic io_fromIfu_pdWb_bits_instrRange_14;
  logic io_fromIfu_pdWb_bits_instrRange_15;
  logic io_fromBackend_rob_commits_0_valid;
  logic [2:0] io_fromBackend_rob_commits_0_bits_commitType;
  logic io_fromBackend_rob_commits_0_bits_ftqIdx_flag;
  logic [5:0] io_fromBackend_rob_commits_0_bits_ftqIdx_value;
  logic [3:0] io_fromBackend_rob_commits_0_bits_ftqOffset;
  logic io_fromBackend_rob_commits_1_valid;
  logic [2:0] io_fromBackend_rob_commits_1_bits_commitType;
  logic io_fromBackend_rob_commits_1_bits_ftqIdx_flag;
  logic [5:0] io_fromBackend_rob_commits_1_bits_ftqIdx_value;
  logic [3:0] io_fromBackend_rob_commits_1_bits_ftqOffset;
  logic io_fromBackend_rob_commits_2_valid;
  logic [2:0] io_fromBackend_rob_commits_2_bits_commitType;
  logic io_fromBackend_rob_commits_2_bits_ftqIdx_flag;
  logic [5:0] io_fromBackend_rob_commits_2_bits_ftqIdx_value;
  logic [3:0] io_fromBackend_rob_commits_2_bits_ftqOffset;
  logic io_fromBackend_rob_commits_3_valid;
  logic [2:0] io_fromBackend_rob_commits_3_bits_commitType;
  logic io_fromBackend_rob_commits_3_bits_ftqIdx_flag;
  logic [5:0] io_fromBackend_rob_commits_3_bits_ftqIdx_value;
  logic [3:0] io_fromBackend_rob_commits_3_bits_ftqOffset;
  logic io_fromBackend_rob_commits_4_valid;
  logic [2:0] io_fromBackend_rob_commits_4_bits_commitType;
  logic io_fromBackend_rob_commits_4_bits_ftqIdx_flag;
  logic [5:0] io_fromBackend_rob_commits_4_bits_ftqIdx_value;
  logic [3:0] io_fromBackend_rob_commits_4_bits_ftqOffset;
  logic io_fromBackend_rob_commits_5_valid;
  logic [2:0] io_fromBackend_rob_commits_5_bits_commitType;
  logic io_fromBackend_rob_commits_5_bits_ftqIdx_flag;
  logic [5:0] io_fromBackend_rob_commits_5_bits_ftqIdx_value;
  logic [3:0] io_fromBackend_rob_commits_5_bits_ftqOffset;
  logic io_fromBackend_rob_commits_6_valid;
  logic [2:0] io_fromBackend_rob_commits_6_bits_commitType;
  logic io_fromBackend_rob_commits_6_bits_ftqIdx_flag;
  logic [5:0] io_fromBackend_rob_commits_6_bits_ftqIdx_value;
  logic [3:0] io_fromBackend_rob_commits_6_bits_ftqOffset;
  logic io_fromBackend_rob_commits_7_valid;
  logic [2:0] io_fromBackend_rob_commits_7_bits_commitType;
  logic io_fromBackend_rob_commits_7_bits_ftqIdx_flag;
  logic [5:0] io_fromBackend_rob_commits_7_bits_ftqIdx_value;
  logic [3:0] io_fromBackend_rob_commits_7_bits_ftqOffset;
  logic io_fromBackend_redirect_valid;
  logic io_fromBackend_redirect_bits_ftqIdx_flag;
  logic [5:0] io_fromBackend_redirect_bits_ftqIdx_value;
  logic [3:0] io_fromBackend_redirect_bits_ftqOffset;
  logic io_fromBackend_redirect_bits_level;
  logic [49:0] io_fromBackend_redirect_bits_cfiUpdate_pc;
  logic [49:0] io_fromBackend_redirect_bits_cfiUpdate_target;
  logic io_fromBackend_redirect_bits_cfiUpdate_taken;
  logic io_fromBackend_redirect_bits_cfiUpdate_isMisPred;
  logic io_fromBackend_redirect_bits_cfiUpdate_backendIGPF;
  logic io_fromBackend_redirect_bits_cfiUpdate_backendIPF;
  logic io_fromBackend_redirect_bits_cfiUpdate_backendIAF;
  logic io_fromBackend_redirect_bits_satpFlush;
  logic io_fromBackend_redirect_bits_debugIsCtrl;
  logic io_fromBackend_redirect_bits_debugIsMemVio;
  logic io_fromBackend_ftqIdxAhead_0_valid;
  logic [5:0] io_fromBackend_ftqIdxAhead_0_bits_value;
  logic [2:0] io_fromBackend_ftqIdxSelOH_bits;
  logic io_toIfu_req_ready;
  logic io_toPrefetch_req_ready;
  logic io_mmioCommitRead_valid;
  logic io_mmioCommitRead_mmioFtqPtr_flag;
  logic [5:0] io_mmioCommitRead_mmioFtqPtr_value;

  // ---- 输出：g_=golden, i_=impl ----
  wire g_io_fromBpu_resp_ready;
  wire i_io_fromBpu_resp_ready;
  wire g_io_toBpu_redirect_valid;
  wire i_io_toBpu_redirect_valid;
  wire g_io_toBpu_redirect_bits_level;
  wire i_io_toBpu_redirect_bits_level;
  wire [49:0] g_io_toBpu_redirect_bits_cfiUpdate_pc;
  wire [49:0] i_io_toBpu_redirect_bits_cfiUpdate_pc;
  wire g_io_toBpu_redirect_bits_cfiUpdate_pd_valid;
  wire i_io_toBpu_redirect_bits_cfiUpdate_pd_valid;
  wire g_io_toBpu_redirect_bits_cfiUpdate_pd_isRVC;
  wire i_io_toBpu_redirect_bits_cfiUpdate_pd_isRVC;
  wire g_io_toBpu_redirect_bits_cfiUpdate_pd_isCall;
  wire i_io_toBpu_redirect_bits_cfiUpdate_pd_isCall;
  wire g_io_toBpu_redirect_bits_cfiUpdate_pd_isRet;
  wire i_io_toBpu_redirect_bits_cfiUpdate_pd_isRet;
  wire [3:0] g_io_toBpu_redirect_bits_cfiUpdate_ssp;
  wire [3:0] i_io_toBpu_redirect_bits_cfiUpdate_ssp;
  wire [2:0] g_io_toBpu_redirect_bits_cfiUpdate_sctr;
  wire [2:0] i_io_toBpu_redirect_bits_cfiUpdate_sctr;
  wire g_io_toBpu_redirect_bits_cfiUpdate_TOSW_flag;
  wire i_io_toBpu_redirect_bits_cfiUpdate_TOSW_flag;
  wire [4:0] g_io_toBpu_redirect_bits_cfiUpdate_TOSW_value;
  wire [4:0] i_io_toBpu_redirect_bits_cfiUpdate_TOSW_value;
  wire g_io_toBpu_redirect_bits_cfiUpdate_TOSR_flag;
  wire i_io_toBpu_redirect_bits_cfiUpdate_TOSR_flag;
  wire [4:0] g_io_toBpu_redirect_bits_cfiUpdate_TOSR_value;
  wire [4:0] i_io_toBpu_redirect_bits_cfiUpdate_TOSR_value;
  wire g_io_toBpu_redirect_bits_cfiUpdate_NOS_flag;
  wire i_io_toBpu_redirect_bits_cfiUpdate_NOS_flag;
  wire [4:0] g_io_toBpu_redirect_bits_cfiUpdate_NOS_value;
  wire [4:0] i_io_toBpu_redirect_bits_cfiUpdate_NOS_value;
  wire g_io_toBpu_redirect_bits_cfiUpdate_histPtr_flag;
  wire i_io_toBpu_redirect_bits_cfiUpdate_histPtr_flag;
  wire [7:0] g_io_toBpu_redirect_bits_cfiUpdate_histPtr_value;
  wire [7:0] i_io_toBpu_redirect_bits_cfiUpdate_histPtr_value;
  wire g_io_toBpu_redirect_bits_cfiUpdate_br_hit;
  wire i_io_toBpu_redirect_bits_cfiUpdate_br_hit;
  wire g_io_toBpu_redirect_bits_cfiUpdate_jr_hit;
  wire i_io_toBpu_redirect_bits_cfiUpdate_jr_hit;
  wire g_io_toBpu_redirect_bits_cfiUpdate_sc_hit;
  wire i_io_toBpu_redirect_bits_cfiUpdate_sc_hit;
  wire [49:0] g_io_toBpu_redirect_bits_cfiUpdate_target;
  wire [49:0] i_io_toBpu_redirect_bits_cfiUpdate_target;
  wire g_io_toBpu_redirect_bits_cfiUpdate_taken;
  wire i_io_toBpu_redirect_bits_cfiUpdate_taken;
  wire [1:0] g_io_toBpu_redirect_bits_cfiUpdate_shift;
  wire [1:0] i_io_toBpu_redirect_bits_cfiUpdate_shift;
  wire g_io_toBpu_redirect_bits_cfiUpdate_addIntoHist;
  wire i_io_toBpu_redirect_bits_cfiUpdate_addIntoHist;
  wire g_io_toBpu_redirect_bits_debugIsCtrl;
  wire i_io_toBpu_redirect_bits_debugIsCtrl;
  wire g_io_toBpu_redirect_bits_debugIsMemVio;
  wire i_io_toBpu_redirect_bits_debugIsMemVio;
  wire g_io_toBpu_redirect_bits_BTBMissBubble;
  wire i_io_toBpu_redirect_bits_BTBMissBubble;
  wire g_io_toBpu_update_valid;
  wire i_io_toBpu_update_valid;
  wire [49:0] g_io_toBpu_update_bits_pc;
  wire [49:0] i_io_toBpu_update_bits_pc;
  wire [7:0] g_io_toBpu_update_bits_spec_info_histPtr_value;
  wire [7:0] i_io_toBpu_update_bits_spec_info_histPtr_value;
  wire g_io_toBpu_update_bits_ftb_entry_isCall;
  wire i_io_toBpu_update_bits_ftb_entry_isCall;
  wire g_io_toBpu_update_bits_ftb_entry_isRet;
  wire i_io_toBpu_update_bits_ftb_entry_isRet;
  wire g_io_toBpu_update_bits_ftb_entry_isJalr;
  wire i_io_toBpu_update_bits_ftb_entry_isJalr;
  wire g_io_toBpu_update_bits_ftb_entry_valid;
  wire i_io_toBpu_update_bits_ftb_entry_valid;
  wire [3:0] g_io_toBpu_update_bits_ftb_entry_brSlots_0_offset;
  wire [3:0] i_io_toBpu_update_bits_ftb_entry_brSlots_0_offset;
  wire g_io_toBpu_update_bits_ftb_entry_brSlots_0_sharing;
  wire i_io_toBpu_update_bits_ftb_entry_brSlots_0_sharing;
  wire g_io_toBpu_update_bits_ftb_entry_brSlots_0_valid;
  wire i_io_toBpu_update_bits_ftb_entry_brSlots_0_valid;
  wire [11:0] g_io_toBpu_update_bits_ftb_entry_brSlots_0_lower;
  wire [11:0] i_io_toBpu_update_bits_ftb_entry_brSlots_0_lower;
  wire [1:0] g_io_toBpu_update_bits_ftb_entry_brSlots_0_tarStat;
  wire [1:0] i_io_toBpu_update_bits_ftb_entry_brSlots_0_tarStat;
  wire [3:0] g_io_toBpu_update_bits_ftb_entry_tailSlot_offset;
  wire [3:0] i_io_toBpu_update_bits_ftb_entry_tailSlot_offset;
  wire g_io_toBpu_update_bits_ftb_entry_tailSlot_sharing;
  wire i_io_toBpu_update_bits_ftb_entry_tailSlot_sharing;
  wire g_io_toBpu_update_bits_ftb_entry_tailSlot_valid;
  wire i_io_toBpu_update_bits_ftb_entry_tailSlot_valid;
  wire [19:0] g_io_toBpu_update_bits_ftb_entry_tailSlot_lower;
  wire [19:0] i_io_toBpu_update_bits_ftb_entry_tailSlot_lower;
  wire [1:0] g_io_toBpu_update_bits_ftb_entry_tailSlot_tarStat;
  wire [1:0] i_io_toBpu_update_bits_ftb_entry_tailSlot_tarStat;
  wire [3:0] g_io_toBpu_update_bits_ftb_entry_pftAddr;
  wire [3:0] i_io_toBpu_update_bits_ftb_entry_pftAddr;
  wire g_io_toBpu_update_bits_ftb_entry_carry;
  wire i_io_toBpu_update_bits_ftb_entry_carry;
  wire g_io_toBpu_update_bits_ftb_entry_last_may_be_rvi_call;
  wire i_io_toBpu_update_bits_ftb_entry_last_may_be_rvi_call;
  wire g_io_toBpu_update_bits_ftb_entry_strong_bias_0;
  wire i_io_toBpu_update_bits_ftb_entry_strong_bias_0;
  wire g_io_toBpu_update_bits_ftb_entry_strong_bias_1;
  wire i_io_toBpu_update_bits_ftb_entry_strong_bias_1;
  wire g_io_toBpu_update_bits_cfi_idx_valid;
  wire i_io_toBpu_update_bits_cfi_idx_valid;
  wire [3:0] g_io_toBpu_update_bits_cfi_idx_bits;
  wire [3:0] i_io_toBpu_update_bits_cfi_idx_bits;
  wire g_io_toBpu_update_bits_br_taken_mask_0;
  wire i_io_toBpu_update_bits_br_taken_mask_0;
  wire g_io_toBpu_update_bits_br_taken_mask_1;
  wire i_io_toBpu_update_bits_br_taken_mask_1;
  wire g_io_toBpu_update_bits_jmp_taken;
  wire i_io_toBpu_update_bits_jmp_taken;
  wire g_io_toBpu_update_bits_mispred_mask_0;
  wire i_io_toBpu_update_bits_mispred_mask_0;
  wire g_io_toBpu_update_bits_mispred_mask_1;
  wire i_io_toBpu_update_bits_mispred_mask_1;
  wire g_io_toBpu_update_bits_mispred_mask_2;
  wire i_io_toBpu_update_bits_mispred_mask_2;
  wire g_io_toBpu_update_bits_false_hit;
  wire i_io_toBpu_update_bits_false_hit;
  wire g_io_toBpu_update_bits_old_entry;
  wire i_io_toBpu_update_bits_old_entry;
  wire [515:0] g_io_toBpu_update_bits_meta;
  wire [515:0] i_io_toBpu_update_bits_meta;
  wire [49:0] g_io_toBpu_update_bits_full_target;
  wire [49:0] i_io_toBpu_update_bits_full_target;
  wire g_io_toBpu_enq_ptr_flag;
  wire i_io_toBpu_enq_ptr_flag;
  wire [5:0] g_io_toBpu_enq_ptr_value;
  wire [5:0] i_io_toBpu_enq_ptr_value;
  wire g_io_toBpu_redirctFromIFU;
  wire i_io_toBpu_redirctFromIFU;
  wire g_io_toIfu_req_valid;
  wire i_io_toIfu_req_valid;
  wire [49:0] g_io_toIfu_req_bits_startAddr;
  wire [49:0] i_io_toIfu_req_bits_startAddr;
  wire [49:0] g_io_toIfu_req_bits_nextlineStart;
  wire [49:0] i_io_toIfu_req_bits_nextlineStart;
  wire [49:0] g_io_toIfu_req_bits_nextStartAddr;
  wire [49:0] i_io_toIfu_req_bits_nextStartAddr;
  wire g_io_toIfu_req_bits_ftqIdx_flag;
  wire i_io_toIfu_req_bits_ftqIdx_flag;
  wire [5:0] g_io_toIfu_req_bits_ftqIdx_value;
  wire [5:0] i_io_toIfu_req_bits_ftqIdx_value;
  wire g_io_toIfu_req_bits_ftqOffset_valid;
  wire i_io_toIfu_req_bits_ftqOffset_valid;
  wire [3:0] g_io_toIfu_req_bits_ftqOffset_bits;
  wire [3:0] i_io_toIfu_req_bits_ftqOffset_bits;
  wire g_io_toIfu_req_bits_topdown_info_reasons_0;
  wire i_io_toIfu_req_bits_topdown_info_reasons_0;
  wire g_io_toIfu_req_bits_topdown_info_reasons_1;
  wire i_io_toIfu_req_bits_topdown_info_reasons_1;
  wire g_io_toIfu_req_bits_topdown_info_reasons_2;
  wire i_io_toIfu_req_bits_topdown_info_reasons_2;
  wire g_io_toIfu_req_bits_topdown_info_reasons_3;
  wire i_io_toIfu_req_bits_topdown_info_reasons_3;
  wire g_io_toIfu_req_bits_topdown_info_reasons_4;
  wire i_io_toIfu_req_bits_topdown_info_reasons_4;
  wire g_io_toIfu_req_bits_topdown_info_reasons_5;
  wire i_io_toIfu_req_bits_topdown_info_reasons_5;
  wire g_io_toIfu_req_bits_topdown_info_reasons_6;
  wire i_io_toIfu_req_bits_topdown_info_reasons_6;
  wire g_io_toIfu_req_bits_topdown_info_reasons_7;
  wire i_io_toIfu_req_bits_topdown_info_reasons_7;
  wire g_io_toIfu_req_bits_topdown_info_reasons_8;
  wire i_io_toIfu_req_bits_topdown_info_reasons_8;
  wire g_io_toIfu_req_bits_topdown_info_reasons_9;
  wire i_io_toIfu_req_bits_topdown_info_reasons_9;
  wire g_io_toIfu_req_bits_topdown_info_reasons_10;
  wire i_io_toIfu_req_bits_topdown_info_reasons_10;
  wire g_io_toIfu_req_bits_topdown_info_reasons_11;
  wire i_io_toIfu_req_bits_topdown_info_reasons_11;
  wire g_io_toIfu_req_bits_topdown_info_reasons_12;
  wire i_io_toIfu_req_bits_topdown_info_reasons_12;
  wire g_io_toIfu_req_bits_topdown_info_reasons_13;
  wire i_io_toIfu_req_bits_topdown_info_reasons_13;
  wire g_io_toIfu_req_bits_topdown_info_reasons_14;
  wire i_io_toIfu_req_bits_topdown_info_reasons_14;
  wire g_io_toIfu_req_bits_topdown_info_reasons_15;
  wire i_io_toIfu_req_bits_topdown_info_reasons_15;
  wire g_io_toIfu_req_bits_topdown_info_reasons_16;
  wire i_io_toIfu_req_bits_topdown_info_reasons_16;
  wire g_io_toIfu_req_bits_topdown_info_reasons_17;
  wire i_io_toIfu_req_bits_topdown_info_reasons_17;
  wire g_io_toIfu_req_bits_topdown_info_reasons_18;
  wire i_io_toIfu_req_bits_topdown_info_reasons_18;
  wire g_io_toIfu_req_bits_topdown_info_reasons_19;
  wire i_io_toIfu_req_bits_topdown_info_reasons_19;
  wire g_io_toIfu_req_bits_topdown_info_reasons_20;
  wire i_io_toIfu_req_bits_topdown_info_reasons_20;
  wire g_io_toIfu_req_bits_topdown_info_reasons_21;
  wire i_io_toIfu_req_bits_topdown_info_reasons_21;
  wire g_io_toIfu_req_bits_topdown_info_reasons_22;
  wire i_io_toIfu_req_bits_topdown_info_reasons_22;
  wire g_io_toIfu_req_bits_topdown_info_reasons_23;
  wire i_io_toIfu_req_bits_topdown_info_reasons_23;
  wire g_io_toIfu_req_bits_topdown_info_reasons_24;
  wire i_io_toIfu_req_bits_topdown_info_reasons_24;
  wire g_io_toIfu_req_bits_topdown_info_reasons_25;
  wire i_io_toIfu_req_bits_topdown_info_reasons_25;
  wire g_io_toIfu_req_bits_topdown_info_reasons_26;
  wire i_io_toIfu_req_bits_topdown_info_reasons_26;
  wire g_io_toIfu_req_bits_topdown_info_reasons_27;
  wire i_io_toIfu_req_bits_topdown_info_reasons_27;
  wire g_io_toIfu_req_bits_topdown_info_reasons_28;
  wire i_io_toIfu_req_bits_topdown_info_reasons_28;
  wire g_io_toIfu_req_bits_topdown_info_reasons_29;
  wire i_io_toIfu_req_bits_topdown_info_reasons_29;
  wire g_io_toIfu_req_bits_topdown_info_reasons_30;
  wire i_io_toIfu_req_bits_topdown_info_reasons_30;
  wire g_io_toIfu_req_bits_topdown_info_reasons_31;
  wire i_io_toIfu_req_bits_topdown_info_reasons_31;
  wire g_io_toIfu_req_bits_topdown_info_reasons_32;
  wire i_io_toIfu_req_bits_topdown_info_reasons_32;
  wire g_io_toIfu_req_bits_topdown_info_reasons_33;
  wire i_io_toIfu_req_bits_topdown_info_reasons_33;
  wire g_io_toIfu_req_bits_topdown_info_reasons_34;
  wire i_io_toIfu_req_bits_topdown_info_reasons_34;
  wire g_io_toIfu_req_bits_topdown_info_reasons_35;
  wire i_io_toIfu_req_bits_topdown_info_reasons_35;
  wire g_io_toIfu_req_bits_topdown_info_reasons_36;
  wire i_io_toIfu_req_bits_topdown_info_reasons_36;
  wire g_io_toIfu_req_bits_topdown_info_reasons_37;
  wire i_io_toIfu_req_bits_topdown_info_reasons_37;
  wire g_io_toIfu_redirect_valid;
  wire i_io_toIfu_redirect_valid;
  wire g_io_toIfu_redirect_bits_ftqIdx_flag;
  wire i_io_toIfu_redirect_bits_ftqIdx_flag;
  wire [5:0] g_io_toIfu_redirect_bits_ftqIdx_value;
  wire [5:0] i_io_toIfu_redirect_bits_ftqIdx_value;
  wire [3:0] g_io_toIfu_redirect_bits_ftqOffset;
  wire [3:0] i_io_toIfu_redirect_bits_ftqOffset;
  wire g_io_toIfu_redirect_bits_level;
  wire i_io_toIfu_redirect_bits_level;
  wire g_io_toIfu_topdown_redirect_valid;
  wire i_io_toIfu_topdown_redirect_valid;
  wire g_io_toIfu_topdown_redirect_bits_cfiUpdate_pd_isRet;
  wire i_io_toIfu_topdown_redirect_bits_cfiUpdate_pd_isRet;
  wire g_io_toIfu_topdown_redirect_bits_cfiUpdate_br_hit;
  wire i_io_toIfu_topdown_redirect_bits_cfiUpdate_br_hit;
  wire g_io_toIfu_topdown_redirect_bits_cfiUpdate_jr_hit;
  wire i_io_toIfu_topdown_redirect_bits_cfiUpdate_jr_hit;
  wire g_io_toIfu_topdown_redirect_bits_cfiUpdate_sc_hit;
  wire i_io_toIfu_topdown_redirect_bits_cfiUpdate_sc_hit;
  wire g_io_toIfu_topdown_redirect_bits_debugIsCtrl;
  wire i_io_toIfu_topdown_redirect_bits_debugIsCtrl;
  wire g_io_toIfu_topdown_redirect_bits_debugIsMemVio;
  wire i_io_toIfu_topdown_redirect_bits_debugIsMemVio;
  wire g_io_toIfu_flushFromBpu_s2_valid;
  wire i_io_toIfu_flushFromBpu_s2_valid;
  wire g_io_toIfu_flushFromBpu_s2_bits_flag;
  wire i_io_toIfu_flushFromBpu_s2_bits_flag;
  wire [5:0] g_io_toIfu_flushFromBpu_s2_bits_value;
  wire [5:0] i_io_toIfu_flushFromBpu_s2_bits_value;
  wire g_io_toIfu_flushFromBpu_s3_valid;
  wire i_io_toIfu_flushFromBpu_s3_valid;
  wire g_io_toIfu_flushFromBpu_s3_bits_flag;
  wire i_io_toIfu_flushFromBpu_s3_bits_flag;
  wire [5:0] g_io_toIfu_flushFromBpu_s3_bits_value;
  wire [5:0] i_io_toIfu_flushFromBpu_s3_bits_value;
  wire g_io_toICache_req_valid;
  wire i_io_toICache_req_valid;
  wire [49:0] g_io_toICache_req_bits_pcMemRead_0_startAddr;
  wire [49:0] i_io_toICache_req_bits_pcMemRead_0_startAddr;
  wire [49:0] g_io_toICache_req_bits_pcMemRead_0_nextlineStart;
  wire [49:0] i_io_toICache_req_bits_pcMemRead_0_nextlineStart;
  wire [49:0] g_io_toICache_req_bits_pcMemRead_1_startAddr;
  wire [49:0] i_io_toICache_req_bits_pcMemRead_1_startAddr;
  wire [49:0] g_io_toICache_req_bits_pcMemRead_1_nextlineStart;
  wire [49:0] i_io_toICache_req_bits_pcMemRead_1_nextlineStart;
  wire [49:0] g_io_toICache_req_bits_pcMemRead_2_startAddr;
  wire [49:0] i_io_toICache_req_bits_pcMemRead_2_startAddr;
  wire [49:0] g_io_toICache_req_bits_pcMemRead_2_nextlineStart;
  wire [49:0] i_io_toICache_req_bits_pcMemRead_2_nextlineStart;
  wire [49:0] g_io_toICache_req_bits_pcMemRead_3_startAddr;
  wire [49:0] i_io_toICache_req_bits_pcMemRead_3_startAddr;
  wire [49:0] g_io_toICache_req_bits_pcMemRead_3_nextlineStart;
  wire [49:0] i_io_toICache_req_bits_pcMemRead_3_nextlineStart;
  wire [49:0] g_io_toICache_req_bits_pcMemRead_4_startAddr;
  wire [49:0] i_io_toICache_req_bits_pcMemRead_4_startAddr;
  wire [49:0] g_io_toICache_req_bits_pcMemRead_4_nextlineStart;
  wire [49:0] i_io_toICache_req_bits_pcMemRead_4_nextlineStart;
  wire g_io_toICache_req_bits_readValid_0;
  wire i_io_toICache_req_bits_readValid_0;
  wire g_io_toICache_req_bits_readValid_1;
  wire i_io_toICache_req_bits_readValid_1;
  wire g_io_toICache_req_bits_readValid_2;
  wire i_io_toICache_req_bits_readValid_2;
  wire g_io_toICache_req_bits_readValid_3;
  wire i_io_toICache_req_bits_readValid_3;
  wire g_io_toICache_req_bits_readValid_4;
  wire i_io_toICache_req_bits_readValid_4;
  wire g_io_toICache_req_bits_backendException;
  wire i_io_toICache_req_bits_backendException;
  wire g_io_toICache_req_bits_hasSatpFlush;
  wire i_io_toICache_req_bits_hasSatpFlush;
  wire g_io_toBackend_pc_mem_wen;
  wire i_io_toBackend_pc_mem_wen;
  wire [5:0] g_io_toBackend_pc_mem_waddr;
  wire [5:0] i_io_toBackend_pc_mem_waddr;
  wire [49:0] g_io_toBackend_pc_mem_wdata_startAddr;
  wire [49:0] i_io_toBackend_pc_mem_wdata_startAddr;
  wire g_io_toBackend_newest_entry_en;
  wire i_io_toBackend_newest_entry_en;
  wire [49:0] g_io_toBackend_newest_entry_target;
  wire [49:0] i_io_toBackend_newest_entry_target;
  wire [5:0] g_io_toBackend_newest_entry_ptr_value;
  wire [5:0] i_io_toBackend_newest_entry_ptr_value;
  wire g_io_toPrefetch_req_valid;
  wire i_io_toPrefetch_req_valid;
  wire [49:0] g_io_toPrefetch_req_bits_startAddr;
  wire [49:0] i_io_toPrefetch_req_bits_startAddr;
  wire [49:0] g_io_toPrefetch_req_bits_nextlineStart;
  wire [49:0] i_io_toPrefetch_req_bits_nextlineStart;
  wire g_io_toPrefetch_req_bits_ftqIdx_flag;
  wire i_io_toPrefetch_req_bits_ftqIdx_flag;
  wire [5:0] g_io_toPrefetch_req_bits_ftqIdx_value;
  wire [5:0] i_io_toPrefetch_req_bits_ftqIdx_value;
  wire g_io_toPrefetch_flushFromBpu_s2_valid;
  wire i_io_toPrefetch_flushFromBpu_s2_valid;
  wire g_io_toPrefetch_flushFromBpu_s2_bits_flag;
  wire i_io_toPrefetch_flushFromBpu_s2_bits_flag;
  wire [5:0] g_io_toPrefetch_flushFromBpu_s2_bits_value;
  wire [5:0] i_io_toPrefetch_flushFromBpu_s2_bits_value;
  wire g_io_toPrefetch_flushFromBpu_s3_valid;
  wire i_io_toPrefetch_flushFromBpu_s3_valid;
  wire g_io_toPrefetch_flushFromBpu_s3_bits_flag;
  wire i_io_toPrefetch_flushFromBpu_s3_bits_flag;
  wire [5:0] g_io_toPrefetch_flushFromBpu_s3_bits_value;
  wire [5:0] i_io_toPrefetch_flushFromBpu_s3_bits_value;
  wire [1:0] g_io_toPrefetch_backendException;
  wire [1:0] i_io_toPrefetch_backendException;
  wire g_io_icacheFlush;
  wire i_io_icacheFlush;
  wire g_io_mmioCommitRead_mmioLastCommit;
  wire i_io_mmioCommitRead_mmioLastCommit;
  wire g_io_ControlBTBMissBubble;
  wire i_io_ControlBTBMissBubble;
  wire g_io_TAGEMissBubble;
  wire i_io_TAGEMissBubble;
  wire g_io_SCMissBubble;
  wire i_io_SCMissBubble;
  wire g_io_ITTAGEMissBubble;
  wire i_io_ITTAGEMissBubble;
  wire g_io_RASMissBubble;
  wire i_io_RASMissBubble;
  wire [5:0] g_io_perf_0_value;
  wire [5:0] i_io_perf_0_value;
  wire [5:0] g_io_perf_1_value;
  wire [5:0] i_io_perf_1_value;
  wire [5:0] g_io_perf_2_value;
  wire [5:0] i_io_perf_2_value;
  wire [5:0] g_io_perf_3_value;
  wire [5:0] i_io_perf_3_value;
  wire [5:0] g_io_perf_4_value;
  wire [5:0] i_io_perf_4_value;
  wire [5:0] g_io_perf_5_value;
  wire [5:0] i_io_perf_5_value;
  wire [5:0] g_io_perf_6_value;
  wire [5:0] i_io_perf_6_value;
  wire [5:0] g_io_perf_7_value;
  wire [5:0] i_io_perf_7_value;
  wire [5:0] g_io_perf_8_value;
  wire [5:0] i_io_perf_8_value;
  wire [5:0] g_io_perf_9_value;
  wire [5:0] i_io_perf_9_value;
  wire [5:0] g_io_perf_10_value;
  wire [5:0] i_io_perf_10_value;
  wire [5:0] g_io_perf_11_value;
  wire [5:0] i_io_perf_11_value;
  wire [5:0] g_io_perf_12_value;
  wire [5:0] i_io_perf_12_value;
  wire [5:0] g_io_perf_13_value;
  wire [5:0] i_io_perf_13_value;
  wire [5:0] g_io_perf_14_value;
  wire [5:0] i_io_perf_14_value;
  wire [5:0] g_io_perf_15_value;
  wire [5:0] i_io_perf_15_value;
  wire [5:0] g_io_perf_16_value;
  wire [5:0] i_io_perf_16_value;
  wire [5:0] g_io_perf_17_value;
  wire [5:0] i_io_perf_17_value;
  wire [5:0] g_io_perf_18_value;
  wire [5:0] i_io_perf_18_value;
  wire [5:0] g_io_perf_19_value;
  wire [5:0] i_io_perf_19_value;
  wire [5:0] g_io_perf_20_value;
  wire [5:0] i_io_perf_20_value;
  wire [5:0] g_io_perf_21_value;
  wire [5:0] i_io_perf_21_value;
  wire [5:0] g_io_perf_22_value;
  wire [5:0] i_io_perf_22_value;
  wire [5:0] g_io_perf_23_value;
  wire [5:0] i_io_perf_23_value;

  Ftq dut_g (
    .clock(clk), .reset(rst),
    .io_fromBpu_resp_valid(io_fromBpu_resp_valid),
    .io_fromBpu_resp_bits_s1_pc_3(io_fromBpu_resp_bits_s1_pc_3),
    .io_fromBpu_resp_bits_s1_full_pred_0_predCycle(io_fromBpu_resp_bits_s1_full_pred_0_predCycle),
    .io_fromBpu_resp_bits_s1_full_pred_3_br_taken_mask_0(io_fromBpu_resp_bits_s1_full_pred_3_br_taken_mask_0),
    .io_fromBpu_resp_bits_s1_full_pred_3_br_taken_mask_1(io_fromBpu_resp_bits_s1_full_pred_3_br_taken_mask_1),
    .io_fromBpu_resp_bits_s1_full_pred_3_slot_valids_0(io_fromBpu_resp_bits_s1_full_pred_3_slot_valids_0),
    .io_fromBpu_resp_bits_s1_full_pred_3_slot_valids_1(io_fromBpu_resp_bits_s1_full_pred_3_slot_valids_1),
    .io_fromBpu_resp_bits_s1_full_pred_3_targets_0(io_fromBpu_resp_bits_s1_full_pred_3_targets_0),
    .io_fromBpu_resp_bits_s1_full_pred_3_targets_1(io_fromBpu_resp_bits_s1_full_pred_3_targets_1),
    .io_fromBpu_resp_bits_s1_full_pred_3_offsets_0(io_fromBpu_resp_bits_s1_full_pred_3_offsets_0),
    .io_fromBpu_resp_bits_s1_full_pred_3_offsets_1(io_fromBpu_resp_bits_s1_full_pred_3_offsets_1),
    .io_fromBpu_resp_bits_s1_full_pred_3_fallThroughAddr(io_fromBpu_resp_bits_s1_full_pred_3_fallThroughAddr),
    .io_fromBpu_resp_bits_s1_full_pred_3_fallThroughErr(io_fromBpu_resp_bits_s1_full_pred_3_fallThroughErr),
    .io_fromBpu_resp_bits_s1_full_pred_3_is_br_sharing(io_fromBpu_resp_bits_s1_full_pred_3_is_br_sharing),
    .io_fromBpu_resp_bits_s1_full_pred_3_hit(io_fromBpu_resp_bits_s1_full_pred_3_hit),
    .io_fromBpu_resp_bits_s2_pc_3(io_fromBpu_resp_bits_s2_pc_3),
    .io_fromBpu_resp_bits_s2_valid_3(io_fromBpu_resp_bits_s2_valid_3),
    .io_fromBpu_resp_bits_s2_hasRedirect_3(io_fromBpu_resp_bits_s2_hasRedirect_3),
    .io_fromBpu_resp_bits_s2_ftq_idx_flag(io_fromBpu_resp_bits_s2_ftq_idx_flag),
    .io_fromBpu_resp_bits_s2_ftq_idx_value(io_fromBpu_resp_bits_s2_ftq_idx_value),
    .io_fromBpu_resp_bits_s2_full_pred_0_predCycle(io_fromBpu_resp_bits_s2_full_pred_0_predCycle),
    .io_fromBpu_resp_bits_s2_full_pred_3_br_taken_mask_0(io_fromBpu_resp_bits_s2_full_pred_3_br_taken_mask_0),
    .io_fromBpu_resp_bits_s2_full_pred_3_br_taken_mask_1(io_fromBpu_resp_bits_s2_full_pred_3_br_taken_mask_1),
    .io_fromBpu_resp_bits_s2_full_pred_3_slot_valids_0(io_fromBpu_resp_bits_s2_full_pred_3_slot_valids_0),
    .io_fromBpu_resp_bits_s2_full_pred_3_slot_valids_1(io_fromBpu_resp_bits_s2_full_pred_3_slot_valids_1),
    .io_fromBpu_resp_bits_s2_full_pred_3_targets_0(io_fromBpu_resp_bits_s2_full_pred_3_targets_0),
    .io_fromBpu_resp_bits_s2_full_pred_3_targets_1(io_fromBpu_resp_bits_s2_full_pred_3_targets_1),
    .io_fromBpu_resp_bits_s2_full_pred_3_offsets_0(io_fromBpu_resp_bits_s2_full_pred_3_offsets_0),
    .io_fromBpu_resp_bits_s2_full_pred_3_offsets_1(io_fromBpu_resp_bits_s2_full_pred_3_offsets_1),
    .io_fromBpu_resp_bits_s2_full_pred_3_fallThroughAddr(io_fromBpu_resp_bits_s2_full_pred_3_fallThroughAddr),
    .io_fromBpu_resp_bits_s2_full_pred_3_fallThroughErr(io_fromBpu_resp_bits_s2_full_pred_3_fallThroughErr),
    .io_fromBpu_resp_bits_s2_full_pred_3_is_br_sharing(io_fromBpu_resp_bits_s2_full_pred_3_is_br_sharing),
    .io_fromBpu_resp_bits_s2_full_pred_3_hit(io_fromBpu_resp_bits_s2_full_pred_3_hit),
    .io_fromBpu_resp_bits_s3_pc_0(io_fromBpu_resp_bits_s3_pc_0),
    .io_fromBpu_resp_bits_s3_pc_3(io_fromBpu_resp_bits_s3_pc_3),
    .io_fromBpu_resp_bits_s3_valid_3(io_fromBpu_resp_bits_s3_valid_3),
    .io_fromBpu_resp_bits_s3_hasRedirect_3(io_fromBpu_resp_bits_s3_hasRedirect_3),
    .io_fromBpu_resp_bits_s3_ftq_idx_flag(io_fromBpu_resp_bits_s3_ftq_idx_flag),
    .io_fromBpu_resp_bits_s3_ftq_idx_value(io_fromBpu_resp_bits_s3_ftq_idx_value),
    .io_fromBpu_resp_bits_s3_full_pred_0_predCycle(io_fromBpu_resp_bits_s3_full_pred_0_predCycle),
    .io_fromBpu_resp_bits_s3_full_pred_3_br_taken_mask_0(io_fromBpu_resp_bits_s3_full_pred_3_br_taken_mask_0),
    .io_fromBpu_resp_bits_s3_full_pred_3_br_taken_mask_1(io_fromBpu_resp_bits_s3_full_pred_3_br_taken_mask_1),
    .io_fromBpu_resp_bits_s3_full_pred_3_slot_valids_0(io_fromBpu_resp_bits_s3_full_pred_3_slot_valids_0),
    .io_fromBpu_resp_bits_s3_full_pred_3_slot_valids_1(io_fromBpu_resp_bits_s3_full_pred_3_slot_valids_1),
    .io_fromBpu_resp_bits_s3_full_pred_3_targets_0(io_fromBpu_resp_bits_s3_full_pred_3_targets_0),
    .io_fromBpu_resp_bits_s3_full_pred_3_targets_1(io_fromBpu_resp_bits_s3_full_pred_3_targets_1),
    .io_fromBpu_resp_bits_s3_full_pred_3_offsets_0(io_fromBpu_resp_bits_s3_full_pred_3_offsets_0),
    .io_fromBpu_resp_bits_s3_full_pred_3_offsets_1(io_fromBpu_resp_bits_s3_full_pred_3_offsets_1),
    .io_fromBpu_resp_bits_s3_full_pred_3_fallThroughAddr(io_fromBpu_resp_bits_s3_full_pred_3_fallThroughAddr),
    .io_fromBpu_resp_bits_s3_full_pred_3_fallThroughErr(io_fromBpu_resp_bits_s3_full_pred_3_fallThroughErr),
    .io_fromBpu_resp_bits_s3_full_pred_3_is_br_sharing(io_fromBpu_resp_bits_s3_full_pred_3_is_br_sharing),
    .io_fromBpu_resp_bits_s3_full_pred_3_hit(io_fromBpu_resp_bits_s3_full_pred_3_hit),
    .io_fromBpu_resp_bits_last_stage_meta(io_fromBpu_resp_bits_last_stage_meta),
    .io_fromBpu_resp_bits_last_stage_spec_info_histPtr_flag(io_fromBpu_resp_bits_last_stage_spec_info_histPtr_flag),
    .io_fromBpu_resp_bits_last_stage_spec_info_histPtr_value(io_fromBpu_resp_bits_last_stage_spec_info_histPtr_value),
    .io_fromBpu_resp_bits_last_stage_spec_info_ssp(io_fromBpu_resp_bits_last_stage_spec_info_ssp),
    .io_fromBpu_resp_bits_last_stage_spec_info_sctr(io_fromBpu_resp_bits_last_stage_spec_info_sctr),
    .io_fromBpu_resp_bits_last_stage_spec_info_TOSW_flag(io_fromBpu_resp_bits_last_stage_spec_info_TOSW_flag),
    .io_fromBpu_resp_bits_last_stage_spec_info_TOSW_value(io_fromBpu_resp_bits_last_stage_spec_info_TOSW_value),
    .io_fromBpu_resp_bits_last_stage_spec_info_TOSR_flag(io_fromBpu_resp_bits_last_stage_spec_info_TOSR_flag),
    .io_fromBpu_resp_bits_last_stage_spec_info_TOSR_value(io_fromBpu_resp_bits_last_stage_spec_info_TOSR_value),
    .io_fromBpu_resp_bits_last_stage_spec_info_NOS_flag(io_fromBpu_resp_bits_last_stage_spec_info_NOS_flag),
    .io_fromBpu_resp_bits_last_stage_spec_info_NOS_value(io_fromBpu_resp_bits_last_stage_spec_info_NOS_value),
    .io_fromBpu_resp_bits_last_stage_spec_info_topAddr(io_fromBpu_resp_bits_last_stage_spec_info_topAddr),
    .io_fromBpu_resp_bits_last_stage_spec_info_sc_disagree_0(io_fromBpu_resp_bits_last_stage_spec_info_sc_disagree_0),
    .io_fromBpu_resp_bits_last_stage_spec_info_sc_disagree_1(io_fromBpu_resp_bits_last_stage_spec_info_sc_disagree_1),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_isCall(io_fromBpu_resp_bits_last_stage_ftb_entry_isCall),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_isRet(io_fromBpu_resp_bits_last_stage_ftb_entry_isRet),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_isJalr(io_fromBpu_resp_bits_last_stage_ftb_entry_isJalr),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_valid(io_fromBpu_resp_bits_last_stage_ftb_entry_valid),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_offset(io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_offset),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_sharing(io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_sharing),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_valid(io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_valid),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_lower(io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_lower),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat(io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_offset(io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_offset),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_sharing(io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_sharing),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_valid(io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_valid),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_lower(io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_lower),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_tarStat(io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_tarStat),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_pftAddr(io_fromBpu_resp_bits_last_stage_ftb_entry_pftAddr),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_carry(io_fromBpu_resp_bits_last_stage_ftb_entry_carry),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call(io_fromBpu_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_strong_bias_0(io_fromBpu_resp_bits_last_stage_ftb_entry_strong_bias_0),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_strong_bias_1(io_fromBpu_resp_bits_last_stage_ftb_entry_strong_bias_1),
    .io_fromBpu_resp_bits_topdown_info_reasons_1(io_fromBpu_resp_bits_topdown_info_reasons_1),
    .io_fromBpu_resp_bits_topdown_info_reasons_2(io_fromBpu_resp_bits_topdown_info_reasons_2),
    .io_fromBpu_resp_bits_topdown_info_reasons_3(io_fromBpu_resp_bits_topdown_info_reasons_3),
    .io_fromBpu_resp_bits_topdown_info_reasons_4(io_fromBpu_resp_bits_topdown_info_reasons_4),
    .io_fromBpu_resp_bits_topdown_info_reasons_5(io_fromBpu_resp_bits_topdown_info_reasons_5),
    .io_fromBpu_resp_bits_topdown_info_reasons_6(io_fromBpu_resp_bits_topdown_info_reasons_6),
    .io_fromBpu_resp_bits_topdown_info_reasons_7(io_fromBpu_resp_bits_topdown_info_reasons_7),
    .io_fromBpu_resp_bits_topdown_info_reasons_8(io_fromBpu_resp_bits_topdown_info_reasons_8),
    .io_fromBpu_resp_bits_topdown_info_reasons_9(io_fromBpu_resp_bits_topdown_info_reasons_9),
    .io_fromBpu_resp_bits_topdown_info_reasons_12(io_fromBpu_resp_bits_topdown_info_reasons_12),
    .io_fromIfu_pdWb_valid(io_fromIfu_pdWb_valid),
    .io_fromIfu_pdWb_bits_pc_0(io_fromIfu_pdWb_bits_pc_0),
    .io_fromIfu_pdWb_bits_pc_1(io_fromIfu_pdWb_bits_pc_1),
    .io_fromIfu_pdWb_bits_pc_2(io_fromIfu_pdWb_bits_pc_2),
    .io_fromIfu_pdWb_bits_pc_3(io_fromIfu_pdWb_bits_pc_3),
    .io_fromIfu_pdWb_bits_pc_4(io_fromIfu_pdWb_bits_pc_4),
    .io_fromIfu_pdWb_bits_pc_5(io_fromIfu_pdWb_bits_pc_5),
    .io_fromIfu_pdWb_bits_pc_6(io_fromIfu_pdWb_bits_pc_6),
    .io_fromIfu_pdWb_bits_pc_7(io_fromIfu_pdWb_bits_pc_7),
    .io_fromIfu_pdWb_bits_pc_8(io_fromIfu_pdWb_bits_pc_8),
    .io_fromIfu_pdWb_bits_pc_9(io_fromIfu_pdWb_bits_pc_9),
    .io_fromIfu_pdWb_bits_pc_10(io_fromIfu_pdWb_bits_pc_10),
    .io_fromIfu_pdWb_bits_pc_11(io_fromIfu_pdWb_bits_pc_11),
    .io_fromIfu_pdWb_bits_pc_12(io_fromIfu_pdWb_bits_pc_12),
    .io_fromIfu_pdWb_bits_pc_13(io_fromIfu_pdWb_bits_pc_13),
    .io_fromIfu_pdWb_bits_pc_14(io_fromIfu_pdWb_bits_pc_14),
    .io_fromIfu_pdWb_bits_pc_15(io_fromIfu_pdWb_bits_pc_15),
    .io_fromIfu_pdWb_bits_pd_0_valid(io_fromIfu_pdWb_bits_pd_0_valid),
    .io_fromIfu_pdWb_bits_pd_0_isRVC(io_fromIfu_pdWb_bits_pd_0_isRVC),
    .io_fromIfu_pdWb_bits_pd_0_brType(io_fromIfu_pdWb_bits_pd_0_brType),
    .io_fromIfu_pdWb_bits_pd_0_isCall(io_fromIfu_pdWb_bits_pd_0_isCall),
    .io_fromIfu_pdWb_bits_pd_0_isRet(io_fromIfu_pdWb_bits_pd_0_isRet),
    .io_fromIfu_pdWb_bits_pd_1_valid(io_fromIfu_pdWb_bits_pd_1_valid),
    .io_fromIfu_pdWb_bits_pd_1_isRVC(io_fromIfu_pdWb_bits_pd_1_isRVC),
    .io_fromIfu_pdWb_bits_pd_1_brType(io_fromIfu_pdWb_bits_pd_1_brType),
    .io_fromIfu_pdWb_bits_pd_1_isCall(io_fromIfu_pdWb_bits_pd_1_isCall),
    .io_fromIfu_pdWb_bits_pd_1_isRet(io_fromIfu_pdWb_bits_pd_1_isRet),
    .io_fromIfu_pdWb_bits_pd_2_valid(io_fromIfu_pdWb_bits_pd_2_valid),
    .io_fromIfu_pdWb_bits_pd_2_isRVC(io_fromIfu_pdWb_bits_pd_2_isRVC),
    .io_fromIfu_pdWb_bits_pd_2_brType(io_fromIfu_pdWb_bits_pd_2_brType),
    .io_fromIfu_pdWb_bits_pd_2_isCall(io_fromIfu_pdWb_bits_pd_2_isCall),
    .io_fromIfu_pdWb_bits_pd_2_isRet(io_fromIfu_pdWb_bits_pd_2_isRet),
    .io_fromIfu_pdWb_bits_pd_3_valid(io_fromIfu_pdWb_bits_pd_3_valid),
    .io_fromIfu_pdWb_bits_pd_3_isRVC(io_fromIfu_pdWb_bits_pd_3_isRVC),
    .io_fromIfu_pdWb_bits_pd_3_brType(io_fromIfu_pdWb_bits_pd_3_brType),
    .io_fromIfu_pdWb_bits_pd_3_isCall(io_fromIfu_pdWb_bits_pd_3_isCall),
    .io_fromIfu_pdWb_bits_pd_3_isRet(io_fromIfu_pdWb_bits_pd_3_isRet),
    .io_fromIfu_pdWb_bits_pd_4_valid(io_fromIfu_pdWb_bits_pd_4_valid),
    .io_fromIfu_pdWb_bits_pd_4_isRVC(io_fromIfu_pdWb_bits_pd_4_isRVC),
    .io_fromIfu_pdWb_bits_pd_4_brType(io_fromIfu_pdWb_bits_pd_4_brType),
    .io_fromIfu_pdWb_bits_pd_4_isCall(io_fromIfu_pdWb_bits_pd_4_isCall),
    .io_fromIfu_pdWb_bits_pd_4_isRet(io_fromIfu_pdWb_bits_pd_4_isRet),
    .io_fromIfu_pdWb_bits_pd_5_valid(io_fromIfu_pdWb_bits_pd_5_valid),
    .io_fromIfu_pdWb_bits_pd_5_isRVC(io_fromIfu_pdWb_bits_pd_5_isRVC),
    .io_fromIfu_pdWb_bits_pd_5_brType(io_fromIfu_pdWb_bits_pd_5_brType),
    .io_fromIfu_pdWb_bits_pd_5_isCall(io_fromIfu_pdWb_bits_pd_5_isCall),
    .io_fromIfu_pdWb_bits_pd_5_isRet(io_fromIfu_pdWb_bits_pd_5_isRet),
    .io_fromIfu_pdWb_bits_pd_6_valid(io_fromIfu_pdWb_bits_pd_6_valid),
    .io_fromIfu_pdWb_bits_pd_6_isRVC(io_fromIfu_pdWb_bits_pd_6_isRVC),
    .io_fromIfu_pdWb_bits_pd_6_brType(io_fromIfu_pdWb_bits_pd_6_brType),
    .io_fromIfu_pdWb_bits_pd_6_isCall(io_fromIfu_pdWb_bits_pd_6_isCall),
    .io_fromIfu_pdWb_bits_pd_6_isRet(io_fromIfu_pdWb_bits_pd_6_isRet),
    .io_fromIfu_pdWb_bits_pd_7_valid(io_fromIfu_pdWb_bits_pd_7_valid),
    .io_fromIfu_pdWb_bits_pd_7_isRVC(io_fromIfu_pdWb_bits_pd_7_isRVC),
    .io_fromIfu_pdWb_bits_pd_7_brType(io_fromIfu_pdWb_bits_pd_7_brType),
    .io_fromIfu_pdWb_bits_pd_7_isCall(io_fromIfu_pdWb_bits_pd_7_isCall),
    .io_fromIfu_pdWb_bits_pd_7_isRet(io_fromIfu_pdWb_bits_pd_7_isRet),
    .io_fromIfu_pdWb_bits_pd_8_valid(io_fromIfu_pdWb_bits_pd_8_valid),
    .io_fromIfu_pdWb_bits_pd_8_isRVC(io_fromIfu_pdWb_bits_pd_8_isRVC),
    .io_fromIfu_pdWb_bits_pd_8_brType(io_fromIfu_pdWb_bits_pd_8_brType),
    .io_fromIfu_pdWb_bits_pd_8_isCall(io_fromIfu_pdWb_bits_pd_8_isCall),
    .io_fromIfu_pdWb_bits_pd_8_isRet(io_fromIfu_pdWb_bits_pd_8_isRet),
    .io_fromIfu_pdWb_bits_pd_9_valid(io_fromIfu_pdWb_bits_pd_9_valid),
    .io_fromIfu_pdWb_bits_pd_9_isRVC(io_fromIfu_pdWb_bits_pd_9_isRVC),
    .io_fromIfu_pdWb_bits_pd_9_brType(io_fromIfu_pdWb_bits_pd_9_brType),
    .io_fromIfu_pdWb_bits_pd_9_isCall(io_fromIfu_pdWb_bits_pd_9_isCall),
    .io_fromIfu_pdWb_bits_pd_9_isRet(io_fromIfu_pdWb_bits_pd_9_isRet),
    .io_fromIfu_pdWb_bits_pd_10_valid(io_fromIfu_pdWb_bits_pd_10_valid),
    .io_fromIfu_pdWb_bits_pd_10_isRVC(io_fromIfu_pdWb_bits_pd_10_isRVC),
    .io_fromIfu_pdWb_bits_pd_10_brType(io_fromIfu_pdWb_bits_pd_10_brType),
    .io_fromIfu_pdWb_bits_pd_10_isCall(io_fromIfu_pdWb_bits_pd_10_isCall),
    .io_fromIfu_pdWb_bits_pd_10_isRet(io_fromIfu_pdWb_bits_pd_10_isRet),
    .io_fromIfu_pdWb_bits_pd_11_valid(io_fromIfu_pdWb_bits_pd_11_valid),
    .io_fromIfu_pdWb_bits_pd_11_isRVC(io_fromIfu_pdWb_bits_pd_11_isRVC),
    .io_fromIfu_pdWb_bits_pd_11_brType(io_fromIfu_pdWb_bits_pd_11_brType),
    .io_fromIfu_pdWb_bits_pd_11_isCall(io_fromIfu_pdWb_bits_pd_11_isCall),
    .io_fromIfu_pdWb_bits_pd_11_isRet(io_fromIfu_pdWb_bits_pd_11_isRet),
    .io_fromIfu_pdWb_bits_pd_12_valid(io_fromIfu_pdWb_bits_pd_12_valid),
    .io_fromIfu_pdWb_bits_pd_12_isRVC(io_fromIfu_pdWb_bits_pd_12_isRVC),
    .io_fromIfu_pdWb_bits_pd_12_brType(io_fromIfu_pdWb_bits_pd_12_brType),
    .io_fromIfu_pdWb_bits_pd_12_isCall(io_fromIfu_pdWb_bits_pd_12_isCall),
    .io_fromIfu_pdWb_bits_pd_12_isRet(io_fromIfu_pdWb_bits_pd_12_isRet),
    .io_fromIfu_pdWb_bits_pd_13_valid(io_fromIfu_pdWb_bits_pd_13_valid),
    .io_fromIfu_pdWb_bits_pd_13_isRVC(io_fromIfu_pdWb_bits_pd_13_isRVC),
    .io_fromIfu_pdWb_bits_pd_13_brType(io_fromIfu_pdWb_bits_pd_13_brType),
    .io_fromIfu_pdWb_bits_pd_13_isCall(io_fromIfu_pdWb_bits_pd_13_isCall),
    .io_fromIfu_pdWb_bits_pd_13_isRet(io_fromIfu_pdWb_bits_pd_13_isRet),
    .io_fromIfu_pdWb_bits_pd_14_valid(io_fromIfu_pdWb_bits_pd_14_valid),
    .io_fromIfu_pdWb_bits_pd_14_isRVC(io_fromIfu_pdWb_bits_pd_14_isRVC),
    .io_fromIfu_pdWb_bits_pd_14_brType(io_fromIfu_pdWb_bits_pd_14_brType),
    .io_fromIfu_pdWb_bits_pd_14_isCall(io_fromIfu_pdWb_bits_pd_14_isCall),
    .io_fromIfu_pdWb_bits_pd_14_isRet(io_fromIfu_pdWb_bits_pd_14_isRet),
    .io_fromIfu_pdWb_bits_pd_15_valid(io_fromIfu_pdWb_bits_pd_15_valid),
    .io_fromIfu_pdWb_bits_pd_15_isRVC(io_fromIfu_pdWb_bits_pd_15_isRVC),
    .io_fromIfu_pdWb_bits_pd_15_brType(io_fromIfu_pdWb_bits_pd_15_brType),
    .io_fromIfu_pdWb_bits_pd_15_isCall(io_fromIfu_pdWb_bits_pd_15_isCall),
    .io_fromIfu_pdWb_bits_pd_15_isRet(io_fromIfu_pdWb_bits_pd_15_isRet),
    .io_fromIfu_pdWb_bits_ftqIdx_flag(io_fromIfu_pdWb_bits_ftqIdx_flag),
    .io_fromIfu_pdWb_bits_ftqIdx_value(io_fromIfu_pdWb_bits_ftqIdx_value),
    .io_fromIfu_pdWb_bits_misOffset_valid(io_fromIfu_pdWb_bits_misOffset_valid),
    .io_fromIfu_pdWb_bits_misOffset_bits(io_fromIfu_pdWb_bits_misOffset_bits),
    .io_fromIfu_pdWb_bits_cfiOffset_valid(io_fromIfu_pdWb_bits_cfiOffset_valid),
    .io_fromIfu_pdWb_bits_target(io_fromIfu_pdWb_bits_target),
    .io_fromIfu_pdWb_bits_jalTarget(io_fromIfu_pdWb_bits_jalTarget),
    .io_fromIfu_pdWb_bits_instrRange_0(io_fromIfu_pdWb_bits_instrRange_0),
    .io_fromIfu_pdWb_bits_instrRange_1(io_fromIfu_pdWb_bits_instrRange_1),
    .io_fromIfu_pdWb_bits_instrRange_2(io_fromIfu_pdWb_bits_instrRange_2),
    .io_fromIfu_pdWb_bits_instrRange_3(io_fromIfu_pdWb_bits_instrRange_3),
    .io_fromIfu_pdWb_bits_instrRange_4(io_fromIfu_pdWb_bits_instrRange_4),
    .io_fromIfu_pdWb_bits_instrRange_5(io_fromIfu_pdWb_bits_instrRange_5),
    .io_fromIfu_pdWb_bits_instrRange_6(io_fromIfu_pdWb_bits_instrRange_6),
    .io_fromIfu_pdWb_bits_instrRange_7(io_fromIfu_pdWb_bits_instrRange_7),
    .io_fromIfu_pdWb_bits_instrRange_8(io_fromIfu_pdWb_bits_instrRange_8),
    .io_fromIfu_pdWb_bits_instrRange_9(io_fromIfu_pdWb_bits_instrRange_9),
    .io_fromIfu_pdWb_bits_instrRange_10(io_fromIfu_pdWb_bits_instrRange_10),
    .io_fromIfu_pdWb_bits_instrRange_11(io_fromIfu_pdWb_bits_instrRange_11),
    .io_fromIfu_pdWb_bits_instrRange_12(io_fromIfu_pdWb_bits_instrRange_12),
    .io_fromIfu_pdWb_bits_instrRange_13(io_fromIfu_pdWb_bits_instrRange_13),
    .io_fromIfu_pdWb_bits_instrRange_14(io_fromIfu_pdWb_bits_instrRange_14),
    .io_fromIfu_pdWb_bits_instrRange_15(io_fromIfu_pdWb_bits_instrRange_15),
    .io_fromBackend_rob_commits_0_valid(io_fromBackend_rob_commits_0_valid),
    .io_fromBackend_rob_commits_0_bits_commitType(io_fromBackend_rob_commits_0_bits_commitType),
    .io_fromBackend_rob_commits_0_bits_ftqIdx_flag(io_fromBackend_rob_commits_0_bits_ftqIdx_flag),
    .io_fromBackend_rob_commits_0_bits_ftqIdx_value(io_fromBackend_rob_commits_0_bits_ftqIdx_value),
    .io_fromBackend_rob_commits_0_bits_ftqOffset(io_fromBackend_rob_commits_0_bits_ftqOffset),
    .io_fromBackend_rob_commits_1_valid(io_fromBackend_rob_commits_1_valid),
    .io_fromBackend_rob_commits_1_bits_commitType(io_fromBackend_rob_commits_1_bits_commitType),
    .io_fromBackend_rob_commits_1_bits_ftqIdx_flag(io_fromBackend_rob_commits_1_bits_ftqIdx_flag),
    .io_fromBackend_rob_commits_1_bits_ftqIdx_value(io_fromBackend_rob_commits_1_bits_ftqIdx_value),
    .io_fromBackend_rob_commits_1_bits_ftqOffset(io_fromBackend_rob_commits_1_bits_ftqOffset),
    .io_fromBackend_rob_commits_2_valid(io_fromBackend_rob_commits_2_valid),
    .io_fromBackend_rob_commits_2_bits_commitType(io_fromBackend_rob_commits_2_bits_commitType),
    .io_fromBackend_rob_commits_2_bits_ftqIdx_flag(io_fromBackend_rob_commits_2_bits_ftqIdx_flag),
    .io_fromBackend_rob_commits_2_bits_ftqIdx_value(io_fromBackend_rob_commits_2_bits_ftqIdx_value),
    .io_fromBackend_rob_commits_2_bits_ftqOffset(io_fromBackend_rob_commits_2_bits_ftqOffset),
    .io_fromBackend_rob_commits_3_valid(io_fromBackend_rob_commits_3_valid),
    .io_fromBackend_rob_commits_3_bits_commitType(io_fromBackend_rob_commits_3_bits_commitType),
    .io_fromBackend_rob_commits_3_bits_ftqIdx_flag(io_fromBackend_rob_commits_3_bits_ftqIdx_flag),
    .io_fromBackend_rob_commits_3_bits_ftqIdx_value(io_fromBackend_rob_commits_3_bits_ftqIdx_value),
    .io_fromBackend_rob_commits_3_bits_ftqOffset(io_fromBackend_rob_commits_3_bits_ftqOffset),
    .io_fromBackend_rob_commits_4_valid(io_fromBackend_rob_commits_4_valid),
    .io_fromBackend_rob_commits_4_bits_commitType(io_fromBackend_rob_commits_4_bits_commitType),
    .io_fromBackend_rob_commits_4_bits_ftqIdx_flag(io_fromBackend_rob_commits_4_bits_ftqIdx_flag),
    .io_fromBackend_rob_commits_4_bits_ftqIdx_value(io_fromBackend_rob_commits_4_bits_ftqIdx_value),
    .io_fromBackend_rob_commits_4_bits_ftqOffset(io_fromBackend_rob_commits_4_bits_ftqOffset),
    .io_fromBackend_rob_commits_5_valid(io_fromBackend_rob_commits_5_valid),
    .io_fromBackend_rob_commits_5_bits_commitType(io_fromBackend_rob_commits_5_bits_commitType),
    .io_fromBackend_rob_commits_5_bits_ftqIdx_flag(io_fromBackend_rob_commits_5_bits_ftqIdx_flag),
    .io_fromBackend_rob_commits_5_bits_ftqIdx_value(io_fromBackend_rob_commits_5_bits_ftqIdx_value),
    .io_fromBackend_rob_commits_5_bits_ftqOffset(io_fromBackend_rob_commits_5_bits_ftqOffset),
    .io_fromBackend_rob_commits_6_valid(io_fromBackend_rob_commits_6_valid),
    .io_fromBackend_rob_commits_6_bits_commitType(io_fromBackend_rob_commits_6_bits_commitType),
    .io_fromBackend_rob_commits_6_bits_ftqIdx_flag(io_fromBackend_rob_commits_6_bits_ftqIdx_flag),
    .io_fromBackend_rob_commits_6_bits_ftqIdx_value(io_fromBackend_rob_commits_6_bits_ftqIdx_value),
    .io_fromBackend_rob_commits_6_bits_ftqOffset(io_fromBackend_rob_commits_6_bits_ftqOffset),
    .io_fromBackend_rob_commits_7_valid(io_fromBackend_rob_commits_7_valid),
    .io_fromBackend_rob_commits_7_bits_commitType(io_fromBackend_rob_commits_7_bits_commitType),
    .io_fromBackend_rob_commits_7_bits_ftqIdx_flag(io_fromBackend_rob_commits_7_bits_ftqIdx_flag),
    .io_fromBackend_rob_commits_7_bits_ftqIdx_value(io_fromBackend_rob_commits_7_bits_ftqIdx_value),
    .io_fromBackend_rob_commits_7_bits_ftqOffset(io_fromBackend_rob_commits_7_bits_ftqOffset),
    .io_fromBackend_redirect_valid(io_fromBackend_redirect_valid),
    .io_fromBackend_redirect_bits_ftqIdx_flag(io_fromBackend_redirect_bits_ftqIdx_flag),
    .io_fromBackend_redirect_bits_ftqIdx_value(io_fromBackend_redirect_bits_ftqIdx_value),
    .io_fromBackend_redirect_bits_ftqOffset(io_fromBackend_redirect_bits_ftqOffset),
    .io_fromBackend_redirect_bits_level(io_fromBackend_redirect_bits_level),
    .io_fromBackend_redirect_bits_cfiUpdate_pc(io_fromBackend_redirect_bits_cfiUpdate_pc),
    .io_fromBackend_redirect_bits_cfiUpdate_target(io_fromBackend_redirect_bits_cfiUpdate_target),
    .io_fromBackend_redirect_bits_cfiUpdate_taken(io_fromBackend_redirect_bits_cfiUpdate_taken),
    .io_fromBackend_redirect_bits_cfiUpdate_isMisPred(io_fromBackend_redirect_bits_cfiUpdate_isMisPred),
    .io_fromBackend_redirect_bits_cfiUpdate_backendIGPF(io_fromBackend_redirect_bits_cfiUpdate_backendIGPF),
    .io_fromBackend_redirect_bits_cfiUpdate_backendIPF(io_fromBackend_redirect_bits_cfiUpdate_backendIPF),
    .io_fromBackend_redirect_bits_cfiUpdate_backendIAF(io_fromBackend_redirect_bits_cfiUpdate_backendIAF),
    .io_fromBackend_redirect_bits_satpFlush(io_fromBackend_redirect_bits_satpFlush),
    .io_fromBackend_redirect_bits_debugIsCtrl(io_fromBackend_redirect_bits_debugIsCtrl),
    .io_fromBackend_redirect_bits_debugIsMemVio(io_fromBackend_redirect_bits_debugIsMemVio),
    .io_fromBackend_ftqIdxAhead_0_valid(io_fromBackend_ftqIdxAhead_0_valid),
    .io_fromBackend_ftqIdxAhead_0_bits_value(io_fromBackend_ftqIdxAhead_0_bits_value),
    .io_fromBackend_ftqIdxSelOH_bits(io_fromBackend_ftqIdxSelOH_bits),
    .io_toIfu_req_ready(io_toIfu_req_ready),
    .io_toPrefetch_req_ready(io_toPrefetch_req_ready),
    .io_mmioCommitRead_valid(io_mmioCommitRead_valid),
    .io_mmioCommitRead_mmioFtqPtr_flag(io_mmioCommitRead_mmioFtqPtr_flag),
    .io_mmioCommitRead_mmioFtqPtr_value(io_mmioCommitRead_mmioFtqPtr_value),
    .io_fromBpu_resp_ready(g_io_fromBpu_resp_ready),
    .io_toBpu_redirect_valid(g_io_toBpu_redirect_valid),
    .io_toBpu_redirect_bits_level(g_io_toBpu_redirect_bits_level),
    .io_toBpu_redirect_bits_cfiUpdate_pc(g_io_toBpu_redirect_bits_cfiUpdate_pc),
    .io_toBpu_redirect_bits_cfiUpdate_pd_valid(g_io_toBpu_redirect_bits_cfiUpdate_pd_valid),
    .io_toBpu_redirect_bits_cfiUpdate_pd_isRVC(g_io_toBpu_redirect_bits_cfiUpdate_pd_isRVC),
    .io_toBpu_redirect_bits_cfiUpdate_pd_isCall(g_io_toBpu_redirect_bits_cfiUpdate_pd_isCall),
    .io_toBpu_redirect_bits_cfiUpdate_pd_isRet(g_io_toBpu_redirect_bits_cfiUpdate_pd_isRet),
    .io_toBpu_redirect_bits_cfiUpdate_ssp(g_io_toBpu_redirect_bits_cfiUpdate_ssp),
    .io_toBpu_redirect_bits_cfiUpdate_sctr(g_io_toBpu_redirect_bits_cfiUpdate_sctr),
    .io_toBpu_redirect_bits_cfiUpdate_TOSW_flag(g_io_toBpu_redirect_bits_cfiUpdate_TOSW_flag),
    .io_toBpu_redirect_bits_cfiUpdate_TOSW_value(g_io_toBpu_redirect_bits_cfiUpdate_TOSW_value),
    .io_toBpu_redirect_bits_cfiUpdate_TOSR_flag(g_io_toBpu_redirect_bits_cfiUpdate_TOSR_flag),
    .io_toBpu_redirect_bits_cfiUpdate_TOSR_value(g_io_toBpu_redirect_bits_cfiUpdate_TOSR_value),
    .io_toBpu_redirect_bits_cfiUpdate_NOS_flag(g_io_toBpu_redirect_bits_cfiUpdate_NOS_flag),
    .io_toBpu_redirect_bits_cfiUpdate_NOS_value(g_io_toBpu_redirect_bits_cfiUpdate_NOS_value),
    .io_toBpu_redirect_bits_cfiUpdate_histPtr_flag(g_io_toBpu_redirect_bits_cfiUpdate_histPtr_flag),
    .io_toBpu_redirect_bits_cfiUpdate_histPtr_value(g_io_toBpu_redirect_bits_cfiUpdate_histPtr_value),
    .io_toBpu_redirect_bits_cfiUpdate_br_hit(g_io_toBpu_redirect_bits_cfiUpdate_br_hit),
    .io_toBpu_redirect_bits_cfiUpdate_jr_hit(g_io_toBpu_redirect_bits_cfiUpdate_jr_hit),
    .io_toBpu_redirect_bits_cfiUpdate_sc_hit(g_io_toBpu_redirect_bits_cfiUpdate_sc_hit),
    .io_toBpu_redirect_bits_cfiUpdate_target(g_io_toBpu_redirect_bits_cfiUpdate_target),
    .io_toBpu_redirect_bits_cfiUpdate_taken(g_io_toBpu_redirect_bits_cfiUpdate_taken),
    .io_toBpu_redirect_bits_cfiUpdate_shift(g_io_toBpu_redirect_bits_cfiUpdate_shift),
    .io_toBpu_redirect_bits_cfiUpdate_addIntoHist(g_io_toBpu_redirect_bits_cfiUpdate_addIntoHist),
    .io_toBpu_redirect_bits_debugIsCtrl(g_io_toBpu_redirect_bits_debugIsCtrl),
    .io_toBpu_redirect_bits_debugIsMemVio(g_io_toBpu_redirect_bits_debugIsMemVio),
    .io_toBpu_redirect_bits_BTBMissBubble(g_io_toBpu_redirect_bits_BTBMissBubble),
    .io_toBpu_update_valid(g_io_toBpu_update_valid),
    .io_toBpu_update_bits_pc(g_io_toBpu_update_bits_pc),
    .io_toBpu_update_bits_spec_info_histPtr_value(g_io_toBpu_update_bits_spec_info_histPtr_value),
    .io_toBpu_update_bits_ftb_entry_isCall(g_io_toBpu_update_bits_ftb_entry_isCall),
    .io_toBpu_update_bits_ftb_entry_isRet(g_io_toBpu_update_bits_ftb_entry_isRet),
    .io_toBpu_update_bits_ftb_entry_isJalr(g_io_toBpu_update_bits_ftb_entry_isJalr),
    .io_toBpu_update_bits_ftb_entry_valid(g_io_toBpu_update_bits_ftb_entry_valid),
    .io_toBpu_update_bits_ftb_entry_brSlots_0_offset(g_io_toBpu_update_bits_ftb_entry_brSlots_0_offset),
    .io_toBpu_update_bits_ftb_entry_brSlots_0_sharing(g_io_toBpu_update_bits_ftb_entry_brSlots_0_sharing),
    .io_toBpu_update_bits_ftb_entry_brSlots_0_valid(g_io_toBpu_update_bits_ftb_entry_brSlots_0_valid),
    .io_toBpu_update_bits_ftb_entry_brSlots_0_lower(g_io_toBpu_update_bits_ftb_entry_brSlots_0_lower),
    .io_toBpu_update_bits_ftb_entry_brSlots_0_tarStat(g_io_toBpu_update_bits_ftb_entry_brSlots_0_tarStat),
    .io_toBpu_update_bits_ftb_entry_tailSlot_offset(g_io_toBpu_update_bits_ftb_entry_tailSlot_offset),
    .io_toBpu_update_bits_ftb_entry_tailSlot_sharing(g_io_toBpu_update_bits_ftb_entry_tailSlot_sharing),
    .io_toBpu_update_bits_ftb_entry_tailSlot_valid(g_io_toBpu_update_bits_ftb_entry_tailSlot_valid),
    .io_toBpu_update_bits_ftb_entry_tailSlot_lower(g_io_toBpu_update_bits_ftb_entry_tailSlot_lower),
    .io_toBpu_update_bits_ftb_entry_tailSlot_tarStat(g_io_toBpu_update_bits_ftb_entry_tailSlot_tarStat),
    .io_toBpu_update_bits_ftb_entry_pftAddr(g_io_toBpu_update_bits_ftb_entry_pftAddr),
    .io_toBpu_update_bits_ftb_entry_carry(g_io_toBpu_update_bits_ftb_entry_carry),
    .io_toBpu_update_bits_ftb_entry_last_may_be_rvi_call(g_io_toBpu_update_bits_ftb_entry_last_may_be_rvi_call),
    .io_toBpu_update_bits_ftb_entry_strong_bias_0(g_io_toBpu_update_bits_ftb_entry_strong_bias_0),
    .io_toBpu_update_bits_ftb_entry_strong_bias_1(g_io_toBpu_update_bits_ftb_entry_strong_bias_1),
    .io_toBpu_update_bits_cfi_idx_valid(g_io_toBpu_update_bits_cfi_idx_valid),
    .io_toBpu_update_bits_cfi_idx_bits(g_io_toBpu_update_bits_cfi_idx_bits),
    .io_toBpu_update_bits_br_taken_mask_0(g_io_toBpu_update_bits_br_taken_mask_0),
    .io_toBpu_update_bits_br_taken_mask_1(g_io_toBpu_update_bits_br_taken_mask_1),
    .io_toBpu_update_bits_jmp_taken(g_io_toBpu_update_bits_jmp_taken),
    .io_toBpu_update_bits_mispred_mask_0(g_io_toBpu_update_bits_mispred_mask_0),
    .io_toBpu_update_bits_mispred_mask_1(g_io_toBpu_update_bits_mispred_mask_1),
    .io_toBpu_update_bits_mispred_mask_2(g_io_toBpu_update_bits_mispred_mask_2),
    .io_toBpu_update_bits_false_hit(g_io_toBpu_update_bits_false_hit),
    .io_toBpu_update_bits_old_entry(g_io_toBpu_update_bits_old_entry),
    .io_toBpu_update_bits_meta(g_io_toBpu_update_bits_meta),
    .io_toBpu_update_bits_full_target(g_io_toBpu_update_bits_full_target),
    .io_toBpu_enq_ptr_flag(g_io_toBpu_enq_ptr_flag),
    .io_toBpu_enq_ptr_value(g_io_toBpu_enq_ptr_value),
    .io_toBpu_redirctFromIFU(g_io_toBpu_redirctFromIFU),
    .io_toIfu_req_valid(g_io_toIfu_req_valid),
    .io_toIfu_req_bits_startAddr(g_io_toIfu_req_bits_startAddr),
    .io_toIfu_req_bits_nextlineStart(g_io_toIfu_req_bits_nextlineStart),
    .io_toIfu_req_bits_nextStartAddr(g_io_toIfu_req_bits_nextStartAddr),
    .io_toIfu_req_bits_ftqIdx_flag(g_io_toIfu_req_bits_ftqIdx_flag),
    .io_toIfu_req_bits_ftqIdx_value(g_io_toIfu_req_bits_ftqIdx_value),
    .io_toIfu_req_bits_ftqOffset_valid(g_io_toIfu_req_bits_ftqOffset_valid),
    .io_toIfu_req_bits_ftqOffset_bits(g_io_toIfu_req_bits_ftqOffset_bits),
    .io_toIfu_req_bits_topdown_info_reasons_0(g_io_toIfu_req_bits_topdown_info_reasons_0),
    .io_toIfu_req_bits_topdown_info_reasons_1(g_io_toIfu_req_bits_topdown_info_reasons_1),
    .io_toIfu_req_bits_topdown_info_reasons_2(g_io_toIfu_req_bits_topdown_info_reasons_2),
    .io_toIfu_req_bits_topdown_info_reasons_3(g_io_toIfu_req_bits_topdown_info_reasons_3),
    .io_toIfu_req_bits_topdown_info_reasons_4(g_io_toIfu_req_bits_topdown_info_reasons_4),
    .io_toIfu_req_bits_topdown_info_reasons_5(g_io_toIfu_req_bits_topdown_info_reasons_5),
    .io_toIfu_req_bits_topdown_info_reasons_6(g_io_toIfu_req_bits_topdown_info_reasons_6),
    .io_toIfu_req_bits_topdown_info_reasons_7(g_io_toIfu_req_bits_topdown_info_reasons_7),
    .io_toIfu_req_bits_topdown_info_reasons_8(g_io_toIfu_req_bits_topdown_info_reasons_8),
    .io_toIfu_req_bits_topdown_info_reasons_9(g_io_toIfu_req_bits_topdown_info_reasons_9),
    .io_toIfu_req_bits_topdown_info_reasons_10(g_io_toIfu_req_bits_topdown_info_reasons_10),
    .io_toIfu_req_bits_topdown_info_reasons_11(g_io_toIfu_req_bits_topdown_info_reasons_11),
    .io_toIfu_req_bits_topdown_info_reasons_12(g_io_toIfu_req_bits_topdown_info_reasons_12),
    .io_toIfu_req_bits_topdown_info_reasons_13(g_io_toIfu_req_bits_topdown_info_reasons_13),
    .io_toIfu_req_bits_topdown_info_reasons_14(g_io_toIfu_req_bits_topdown_info_reasons_14),
    .io_toIfu_req_bits_topdown_info_reasons_15(g_io_toIfu_req_bits_topdown_info_reasons_15),
    .io_toIfu_req_bits_topdown_info_reasons_16(g_io_toIfu_req_bits_topdown_info_reasons_16),
    .io_toIfu_req_bits_topdown_info_reasons_17(g_io_toIfu_req_bits_topdown_info_reasons_17),
    .io_toIfu_req_bits_topdown_info_reasons_18(g_io_toIfu_req_bits_topdown_info_reasons_18),
    .io_toIfu_req_bits_topdown_info_reasons_19(g_io_toIfu_req_bits_topdown_info_reasons_19),
    .io_toIfu_req_bits_topdown_info_reasons_20(g_io_toIfu_req_bits_topdown_info_reasons_20),
    .io_toIfu_req_bits_topdown_info_reasons_21(g_io_toIfu_req_bits_topdown_info_reasons_21),
    .io_toIfu_req_bits_topdown_info_reasons_22(g_io_toIfu_req_bits_topdown_info_reasons_22),
    .io_toIfu_req_bits_topdown_info_reasons_23(g_io_toIfu_req_bits_topdown_info_reasons_23),
    .io_toIfu_req_bits_topdown_info_reasons_24(g_io_toIfu_req_bits_topdown_info_reasons_24),
    .io_toIfu_req_bits_topdown_info_reasons_25(g_io_toIfu_req_bits_topdown_info_reasons_25),
    .io_toIfu_req_bits_topdown_info_reasons_26(g_io_toIfu_req_bits_topdown_info_reasons_26),
    .io_toIfu_req_bits_topdown_info_reasons_27(g_io_toIfu_req_bits_topdown_info_reasons_27),
    .io_toIfu_req_bits_topdown_info_reasons_28(g_io_toIfu_req_bits_topdown_info_reasons_28),
    .io_toIfu_req_bits_topdown_info_reasons_29(g_io_toIfu_req_bits_topdown_info_reasons_29),
    .io_toIfu_req_bits_topdown_info_reasons_30(g_io_toIfu_req_bits_topdown_info_reasons_30),
    .io_toIfu_req_bits_topdown_info_reasons_31(g_io_toIfu_req_bits_topdown_info_reasons_31),
    .io_toIfu_req_bits_topdown_info_reasons_32(g_io_toIfu_req_bits_topdown_info_reasons_32),
    .io_toIfu_req_bits_topdown_info_reasons_33(g_io_toIfu_req_bits_topdown_info_reasons_33),
    .io_toIfu_req_bits_topdown_info_reasons_34(g_io_toIfu_req_bits_topdown_info_reasons_34),
    .io_toIfu_req_bits_topdown_info_reasons_35(g_io_toIfu_req_bits_topdown_info_reasons_35),
    .io_toIfu_req_bits_topdown_info_reasons_36(g_io_toIfu_req_bits_topdown_info_reasons_36),
    .io_toIfu_req_bits_topdown_info_reasons_37(g_io_toIfu_req_bits_topdown_info_reasons_37),
    .io_toIfu_redirect_valid(g_io_toIfu_redirect_valid),
    .io_toIfu_redirect_bits_ftqIdx_flag(g_io_toIfu_redirect_bits_ftqIdx_flag),
    .io_toIfu_redirect_bits_ftqIdx_value(g_io_toIfu_redirect_bits_ftqIdx_value),
    .io_toIfu_redirect_bits_ftqOffset(g_io_toIfu_redirect_bits_ftqOffset),
    .io_toIfu_redirect_bits_level(g_io_toIfu_redirect_bits_level),
    .io_toIfu_topdown_redirect_valid(g_io_toIfu_topdown_redirect_valid),
    .io_toIfu_topdown_redirect_bits_cfiUpdate_pd_isRet(g_io_toIfu_topdown_redirect_bits_cfiUpdate_pd_isRet),
    .io_toIfu_topdown_redirect_bits_cfiUpdate_br_hit(g_io_toIfu_topdown_redirect_bits_cfiUpdate_br_hit),
    .io_toIfu_topdown_redirect_bits_cfiUpdate_jr_hit(g_io_toIfu_topdown_redirect_bits_cfiUpdate_jr_hit),
    .io_toIfu_topdown_redirect_bits_cfiUpdate_sc_hit(g_io_toIfu_topdown_redirect_bits_cfiUpdate_sc_hit),
    .io_toIfu_topdown_redirect_bits_debugIsCtrl(g_io_toIfu_topdown_redirect_bits_debugIsCtrl),
    .io_toIfu_topdown_redirect_bits_debugIsMemVio(g_io_toIfu_topdown_redirect_bits_debugIsMemVio),
    .io_toIfu_flushFromBpu_s2_valid(g_io_toIfu_flushFromBpu_s2_valid),
    .io_toIfu_flushFromBpu_s2_bits_flag(g_io_toIfu_flushFromBpu_s2_bits_flag),
    .io_toIfu_flushFromBpu_s2_bits_value(g_io_toIfu_flushFromBpu_s2_bits_value),
    .io_toIfu_flushFromBpu_s3_valid(g_io_toIfu_flushFromBpu_s3_valid),
    .io_toIfu_flushFromBpu_s3_bits_flag(g_io_toIfu_flushFromBpu_s3_bits_flag),
    .io_toIfu_flushFromBpu_s3_bits_value(g_io_toIfu_flushFromBpu_s3_bits_value),
    .io_toICache_req_valid(g_io_toICache_req_valid),
    .io_toICache_req_bits_pcMemRead_0_startAddr(g_io_toICache_req_bits_pcMemRead_0_startAddr),
    .io_toICache_req_bits_pcMemRead_0_nextlineStart(g_io_toICache_req_bits_pcMemRead_0_nextlineStart),
    .io_toICache_req_bits_pcMemRead_1_startAddr(g_io_toICache_req_bits_pcMemRead_1_startAddr),
    .io_toICache_req_bits_pcMemRead_1_nextlineStart(g_io_toICache_req_bits_pcMemRead_1_nextlineStart),
    .io_toICache_req_bits_pcMemRead_2_startAddr(g_io_toICache_req_bits_pcMemRead_2_startAddr),
    .io_toICache_req_bits_pcMemRead_2_nextlineStart(g_io_toICache_req_bits_pcMemRead_2_nextlineStart),
    .io_toICache_req_bits_pcMemRead_3_startAddr(g_io_toICache_req_bits_pcMemRead_3_startAddr),
    .io_toICache_req_bits_pcMemRead_3_nextlineStart(g_io_toICache_req_bits_pcMemRead_3_nextlineStart),
    .io_toICache_req_bits_pcMemRead_4_startAddr(g_io_toICache_req_bits_pcMemRead_4_startAddr),
    .io_toICache_req_bits_pcMemRead_4_nextlineStart(g_io_toICache_req_bits_pcMemRead_4_nextlineStart),
    .io_toICache_req_bits_readValid_0(g_io_toICache_req_bits_readValid_0),
    .io_toICache_req_bits_readValid_1(g_io_toICache_req_bits_readValid_1),
    .io_toICache_req_bits_readValid_2(g_io_toICache_req_bits_readValid_2),
    .io_toICache_req_bits_readValid_3(g_io_toICache_req_bits_readValid_3),
    .io_toICache_req_bits_readValid_4(g_io_toICache_req_bits_readValid_4),
    .io_toICache_req_bits_backendException(g_io_toICache_req_bits_backendException),
    .io_toICache_req_bits_hasSatpFlush(g_io_toICache_req_bits_hasSatpFlush),
    .io_toBackend_pc_mem_wen(g_io_toBackend_pc_mem_wen),
    .io_toBackend_pc_mem_waddr(g_io_toBackend_pc_mem_waddr),
    .io_toBackend_pc_mem_wdata_startAddr(g_io_toBackend_pc_mem_wdata_startAddr),
    .io_toBackend_newest_entry_en(g_io_toBackend_newest_entry_en),
    .io_toBackend_newest_entry_target(g_io_toBackend_newest_entry_target),
    .io_toBackend_newest_entry_ptr_value(g_io_toBackend_newest_entry_ptr_value),
    .io_toPrefetch_req_valid(g_io_toPrefetch_req_valid),
    .io_toPrefetch_req_bits_startAddr(g_io_toPrefetch_req_bits_startAddr),
    .io_toPrefetch_req_bits_nextlineStart(g_io_toPrefetch_req_bits_nextlineStart),
    .io_toPrefetch_req_bits_ftqIdx_flag(g_io_toPrefetch_req_bits_ftqIdx_flag),
    .io_toPrefetch_req_bits_ftqIdx_value(g_io_toPrefetch_req_bits_ftqIdx_value),
    .io_toPrefetch_flushFromBpu_s2_valid(g_io_toPrefetch_flushFromBpu_s2_valid),
    .io_toPrefetch_flushFromBpu_s2_bits_flag(g_io_toPrefetch_flushFromBpu_s2_bits_flag),
    .io_toPrefetch_flushFromBpu_s2_bits_value(g_io_toPrefetch_flushFromBpu_s2_bits_value),
    .io_toPrefetch_flushFromBpu_s3_valid(g_io_toPrefetch_flushFromBpu_s3_valid),
    .io_toPrefetch_flushFromBpu_s3_bits_flag(g_io_toPrefetch_flushFromBpu_s3_bits_flag),
    .io_toPrefetch_flushFromBpu_s3_bits_value(g_io_toPrefetch_flushFromBpu_s3_bits_value),
    .io_toPrefetch_backendException(g_io_toPrefetch_backendException),
    .io_icacheFlush(g_io_icacheFlush),
    .io_mmioCommitRead_mmioLastCommit(g_io_mmioCommitRead_mmioLastCommit),
    .io_ControlBTBMissBubble(g_io_ControlBTBMissBubble),
    .io_TAGEMissBubble(g_io_TAGEMissBubble),
    .io_SCMissBubble(g_io_SCMissBubble),
    .io_ITTAGEMissBubble(g_io_ITTAGEMissBubble),
    .io_RASMissBubble(g_io_RASMissBubble),
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
    .io_perf_12_value(g_io_perf_12_value),
    .io_perf_13_value(g_io_perf_13_value),
    .io_perf_14_value(g_io_perf_14_value),
    .io_perf_15_value(g_io_perf_15_value),
    .io_perf_16_value(g_io_perf_16_value),
    .io_perf_17_value(g_io_perf_17_value),
    .io_perf_18_value(g_io_perf_18_value),
    .io_perf_19_value(g_io_perf_19_value),
    .io_perf_20_value(g_io_perf_20_value),
    .io_perf_21_value(g_io_perf_21_value),
    .io_perf_22_value(g_io_perf_22_value),
    .io_perf_23_value(g_io_perf_23_value)
  );
  Ftq_xs dut_i (
    .clock(clk), .reset(rst),
    .io_fromBpu_resp_valid(io_fromBpu_resp_valid),
    .io_fromBpu_resp_bits_s1_pc_3(io_fromBpu_resp_bits_s1_pc_3),
    .io_fromBpu_resp_bits_s1_full_pred_0_predCycle(io_fromBpu_resp_bits_s1_full_pred_0_predCycle),
    .io_fromBpu_resp_bits_s1_full_pred_3_br_taken_mask_0(io_fromBpu_resp_bits_s1_full_pred_3_br_taken_mask_0),
    .io_fromBpu_resp_bits_s1_full_pred_3_br_taken_mask_1(io_fromBpu_resp_bits_s1_full_pred_3_br_taken_mask_1),
    .io_fromBpu_resp_bits_s1_full_pred_3_slot_valids_0(io_fromBpu_resp_bits_s1_full_pred_3_slot_valids_0),
    .io_fromBpu_resp_bits_s1_full_pred_3_slot_valids_1(io_fromBpu_resp_bits_s1_full_pred_3_slot_valids_1),
    .io_fromBpu_resp_bits_s1_full_pred_3_targets_0(io_fromBpu_resp_bits_s1_full_pred_3_targets_0),
    .io_fromBpu_resp_bits_s1_full_pred_3_targets_1(io_fromBpu_resp_bits_s1_full_pred_3_targets_1),
    .io_fromBpu_resp_bits_s1_full_pred_3_offsets_0(io_fromBpu_resp_bits_s1_full_pred_3_offsets_0),
    .io_fromBpu_resp_bits_s1_full_pred_3_offsets_1(io_fromBpu_resp_bits_s1_full_pred_3_offsets_1),
    .io_fromBpu_resp_bits_s1_full_pred_3_fallThroughAddr(io_fromBpu_resp_bits_s1_full_pred_3_fallThroughAddr),
    .io_fromBpu_resp_bits_s1_full_pred_3_fallThroughErr(io_fromBpu_resp_bits_s1_full_pred_3_fallThroughErr),
    .io_fromBpu_resp_bits_s1_full_pred_3_is_br_sharing(io_fromBpu_resp_bits_s1_full_pred_3_is_br_sharing),
    .io_fromBpu_resp_bits_s1_full_pred_3_hit(io_fromBpu_resp_bits_s1_full_pred_3_hit),
    .io_fromBpu_resp_bits_s2_pc_3(io_fromBpu_resp_bits_s2_pc_3),
    .io_fromBpu_resp_bits_s2_valid_3(io_fromBpu_resp_bits_s2_valid_3),
    .io_fromBpu_resp_bits_s2_hasRedirect_3(io_fromBpu_resp_bits_s2_hasRedirect_3),
    .io_fromBpu_resp_bits_s2_ftq_idx_flag(io_fromBpu_resp_bits_s2_ftq_idx_flag),
    .io_fromBpu_resp_bits_s2_ftq_idx_value(io_fromBpu_resp_bits_s2_ftq_idx_value),
    .io_fromBpu_resp_bits_s2_full_pred_0_predCycle(io_fromBpu_resp_bits_s2_full_pred_0_predCycle),
    .io_fromBpu_resp_bits_s2_full_pred_3_br_taken_mask_0(io_fromBpu_resp_bits_s2_full_pred_3_br_taken_mask_0),
    .io_fromBpu_resp_bits_s2_full_pred_3_br_taken_mask_1(io_fromBpu_resp_bits_s2_full_pred_3_br_taken_mask_1),
    .io_fromBpu_resp_bits_s2_full_pred_3_slot_valids_0(io_fromBpu_resp_bits_s2_full_pred_3_slot_valids_0),
    .io_fromBpu_resp_bits_s2_full_pred_3_slot_valids_1(io_fromBpu_resp_bits_s2_full_pred_3_slot_valids_1),
    .io_fromBpu_resp_bits_s2_full_pred_3_targets_0(io_fromBpu_resp_bits_s2_full_pred_3_targets_0),
    .io_fromBpu_resp_bits_s2_full_pred_3_targets_1(io_fromBpu_resp_bits_s2_full_pred_3_targets_1),
    .io_fromBpu_resp_bits_s2_full_pred_3_offsets_0(io_fromBpu_resp_bits_s2_full_pred_3_offsets_0),
    .io_fromBpu_resp_bits_s2_full_pred_3_offsets_1(io_fromBpu_resp_bits_s2_full_pred_3_offsets_1),
    .io_fromBpu_resp_bits_s2_full_pred_3_fallThroughAddr(io_fromBpu_resp_bits_s2_full_pred_3_fallThroughAddr),
    .io_fromBpu_resp_bits_s2_full_pred_3_fallThroughErr(io_fromBpu_resp_bits_s2_full_pred_3_fallThroughErr),
    .io_fromBpu_resp_bits_s2_full_pred_3_is_br_sharing(io_fromBpu_resp_bits_s2_full_pred_3_is_br_sharing),
    .io_fromBpu_resp_bits_s2_full_pred_3_hit(io_fromBpu_resp_bits_s2_full_pred_3_hit),
    .io_fromBpu_resp_bits_s3_pc_0(io_fromBpu_resp_bits_s3_pc_0),
    .io_fromBpu_resp_bits_s3_pc_3(io_fromBpu_resp_bits_s3_pc_3),
    .io_fromBpu_resp_bits_s3_valid_3(io_fromBpu_resp_bits_s3_valid_3),
    .io_fromBpu_resp_bits_s3_hasRedirect_3(io_fromBpu_resp_bits_s3_hasRedirect_3),
    .io_fromBpu_resp_bits_s3_ftq_idx_flag(io_fromBpu_resp_bits_s3_ftq_idx_flag),
    .io_fromBpu_resp_bits_s3_ftq_idx_value(io_fromBpu_resp_bits_s3_ftq_idx_value),
    .io_fromBpu_resp_bits_s3_full_pred_0_predCycle(io_fromBpu_resp_bits_s3_full_pred_0_predCycle),
    .io_fromBpu_resp_bits_s3_full_pred_3_br_taken_mask_0(io_fromBpu_resp_bits_s3_full_pred_3_br_taken_mask_0),
    .io_fromBpu_resp_bits_s3_full_pred_3_br_taken_mask_1(io_fromBpu_resp_bits_s3_full_pred_3_br_taken_mask_1),
    .io_fromBpu_resp_bits_s3_full_pred_3_slot_valids_0(io_fromBpu_resp_bits_s3_full_pred_3_slot_valids_0),
    .io_fromBpu_resp_bits_s3_full_pred_3_slot_valids_1(io_fromBpu_resp_bits_s3_full_pred_3_slot_valids_1),
    .io_fromBpu_resp_bits_s3_full_pred_3_targets_0(io_fromBpu_resp_bits_s3_full_pred_3_targets_0),
    .io_fromBpu_resp_bits_s3_full_pred_3_targets_1(io_fromBpu_resp_bits_s3_full_pred_3_targets_1),
    .io_fromBpu_resp_bits_s3_full_pred_3_offsets_0(io_fromBpu_resp_bits_s3_full_pred_3_offsets_0),
    .io_fromBpu_resp_bits_s3_full_pred_3_offsets_1(io_fromBpu_resp_bits_s3_full_pred_3_offsets_1),
    .io_fromBpu_resp_bits_s3_full_pred_3_fallThroughAddr(io_fromBpu_resp_bits_s3_full_pred_3_fallThroughAddr),
    .io_fromBpu_resp_bits_s3_full_pred_3_fallThroughErr(io_fromBpu_resp_bits_s3_full_pred_3_fallThroughErr),
    .io_fromBpu_resp_bits_s3_full_pred_3_is_br_sharing(io_fromBpu_resp_bits_s3_full_pred_3_is_br_sharing),
    .io_fromBpu_resp_bits_s3_full_pred_3_hit(io_fromBpu_resp_bits_s3_full_pred_3_hit),
    .io_fromBpu_resp_bits_last_stage_meta(io_fromBpu_resp_bits_last_stage_meta),
    .io_fromBpu_resp_bits_last_stage_spec_info_histPtr_flag(io_fromBpu_resp_bits_last_stage_spec_info_histPtr_flag),
    .io_fromBpu_resp_bits_last_stage_spec_info_histPtr_value(io_fromBpu_resp_bits_last_stage_spec_info_histPtr_value),
    .io_fromBpu_resp_bits_last_stage_spec_info_ssp(io_fromBpu_resp_bits_last_stage_spec_info_ssp),
    .io_fromBpu_resp_bits_last_stage_spec_info_sctr(io_fromBpu_resp_bits_last_stage_spec_info_sctr),
    .io_fromBpu_resp_bits_last_stage_spec_info_TOSW_flag(io_fromBpu_resp_bits_last_stage_spec_info_TOSW_flag),
    .io_fromBpu_resp_bits_last_stage_spec_info_TOSW_value(io_fromBpu_resp_bits_last_stage_spec_info_TOSW_value),
    .io_fromBpu_resp_bits_last_stage_spec_info_TOSR_flag(io_fromBpu_resp_bits_last_stage_spec_info_TOSR_flag),
    .io_fromBpu_resp_bits_last_stage_spec_info_TOSR_value(io_fromBpu_resp_bits_last_stage_spec_info_TOSR_value),
    .io_fromBpu_resp_bits_last_stage_spec_info_NOS_flag(io_fromBpu_resp_bits_last_stage_spec_info_NOS_flag),
    .io_fromBpu_resp_bits_last_stage_spec_info_NOS_value(io_fromBpu_resp_bits_last_stage_spec_info_NOS_value),
    .io_fromBpu_resp_bits_last_stage_spec_info_topAddr(io_fromBpu_resp_bits_last_stage_spec_info_topAddr),
    .io_fromBpu_resp_bits_last_stage_spec_info_sc_disagree_0(io_fromBpu_resp_bits_last_stage_spec_info_sc_disagree_0),
    .io_fromBpu_resp_bits_last_stage_spec_info_sc_disagree_1(io_fromBpu_resp_bits_last_stage_spec_info_sc_disagree_1),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_isCall(io_fromBpu_resp_bits_last_stage_ftb_entry_isCall),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_isRet(io_fromBpu_resp_bits_last_stage_ftb_entry_isRet),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_isJalr(io_fromBpu_resp_bits_last_stage_ftb_entry_isJalr),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_valid(io_fromBpu_resp_bits_last_stage_ftb_entry_valid),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_offset(io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_offset),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_sharing(io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_sharing),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_valid(io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_valid),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_lower(io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_lower),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat(io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_offset(io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_offset),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_sharing(io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_sharing),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_valid(io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_valid),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_lower(io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_lower),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_tarStat(io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_tarStat),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_pftAddr(io_fromBpu_resp_bits_last_stage_ftb_entry_pftAddr),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_carry(io_fromBpu_resp_bits_last_stage_ftb_entry_carry),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call(io_fromBpu_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_strong_bias_0(io_fromBpu_resp_bits_last_stage_ftb_entry_strong_bias_0),
    .io_fromBpu_resp_bits_last_stage_ftb_entry_strong_bias_1(io_fromBpu_resp_bits_last_stage_ftb_entry_strong_bias_1),
    .io_fromBpu_resp_bits_topdown_info_reasons_1(io_fromBpu_resp_bits_topdown_info_reasons_1),
    .io_fromBpu_resp_bits_topdown_info_reasons_2(io_fromBpu_resp_bits_topdown_info_reasons_2),
    .io_fromBpu_resp_bits_topdown_info_reasons_3(io_fromBpu_resp_bits_topdown_info_reasons_3),
    .io_fromBpu_resp_bits_topdown_info_reasons_4(io_fromBpu_resp_bits_topdown_info_reasons_4),
    .io_fromBpu_resp_bits_topdown_info_reasons_5(io_fromBpu_resp_bits_topdown_info_reasons_5),
    .io_fromBpu_resp_bits_topdown_info_reasons_6(io_fromBpu_resp_bits_topdown_info_reasons_6),
    .io_fromBpu_resp_bits_topdown_info_reasons_7(io_fromBpu_resp_bits_topdown_info_reasons_7),
    .io_fromBpu_resp_bits_topdown_info_reasons_8(io_fromBpu_resp_bits_topdown_info_reasons_8),
    .io_fromBpu_resp_bits_topdown_info_reasons_9(io_fromBpu_resp_bits_topdown_info_reasons_9),
    .io_fromBpu_resp_bits_topdown_info_reasons_12(io_fromBpu_resp_bits_topdown_info_reasons_12),
    .io_fromIfu_pdWb_valid(io_fromIfu_pdWb_valid),
    .io_fromIfu_pdWb_bits_pc_0(io_fromIfu_pdWb_bits_pc_0),
    .io_fromIfu_pdWb_bits_pc_1(io_fromIfu_pdWb_bits_pc_1),
    .io_fromIfu_pdWb_bits_pc_2(io_fromIfu_pdWb_bits_pc_2),
    .io_fromIfu_pdWb_bits_pc_3(io_fromIfu_pdWb_bits_pc_3),
    .io_fromIfu_pdWb_bits_pc_4(io_fromIfu_pdWb_bits_pc_4),
    .io_fromIfu_pdWb_bits_pc_5(io_fromIfu_pdWb_bits_pc_5),
    .io_fromIfu_pdWb_bits_pc_6(io_fromIfu_pdWb_bits_pc_6),
    .io_fromIfu_pdWb_bits_pc_7(io_fromIfu_pdWb_bits_pc_7),
    .io_fromIfu_pdWb_bits_pc_8(io_fromIfu_pdWb_bits_pc_8),
    .io_fromIfu_pdWb_bits_pc_9(io_fromIfu_pdWb_bits_pc_9),
    .io_fromIfu_pdWb_bits_pc_10(io_fromIfu_pdWb_bits_pc_10),
    .io_fromIfu_pdWb_bits_pc_11(io_fromIfu_pdWb_bits_pc_11),
    .io_fromIfu_pdWb_bits_pc_12(io_fromIfu_pdWb_bits_pc_12),
    .io_fromIfu_pdWb_bits_pc_13(io_fromIfu_pdWb_bits_pc_13),
    .io_fromIfu_pdWb_bits_pc_14(io_fromIfu_pdWb_bits_pc_14),
    .io_fromIfu_pdWb_bits_pc_15(io_fromIfu_pdWb_bits_pc_15),
    .io_fromIfu_pdWb_bits_pd_0_valid(io_fromIfu_pdWb_bits_pd_0_valid),
    .io_fromIfu_pdWb_bits_pd_0_isRVC(io_fromIfu_pdWb_bits_pd_0_isRVC),
    .io_fromIfu_pdWb_bits_pd_0_brType(io_fromIfu_pdWb_bits_pd_0_brType),
    .io_fromIfu_pdWb_bits_pd_0_isCall(io_fromIfu_pdWb_bits_pd_0_isCall),
    .io_fromIfu_pdWb_bits_pd_0_isRet(io_fromIfu_pdWb_bits_pd_0_isRet),
    .io_fromIfu_pdWb_bits_pd_1_valid(io_fromIfu_pdWb_bits_pd_1_valid),
    .io_fromIfu_pdWb_bits_pd_1_isRVC(io_fromIfu_pdWb_bits_pd_1_isRVC),
    .io_fromIfu_pdWb_bits_pd_1_brType(io_fromIfu_pdWb_bits_pd_1_brType),
    .io_fromIfu_pdWb_bits_pd_1_isCall(io_fromIfu_pdWb_bits_pd_1_isCall),
    .io_fromIfu_pdWb_bits_pd_1_isRet(io_fromIfu_pdWb_bits_pd_1_isRet),
    .io_fromIfu_pdWb_bits_pd_2_valid(io_fromIfu_pdWb_bits_pd_2_valid),
    .io_fromIfu_pdWb_bits_pd_2_isRVC(io_fromIfu_pdWb_bits_pd_2_isRVC),
    .io_fromIfu_pdWb_bits_pd_2_brType(io_fromIfu_pdWb_bits_pd_2_brType),
    .io_fromIfu_pdWb_bits_pd_2_isCall(io_fromIfu_pdWb_bits_pd_2_isCall),
    .io_fromIfu_pdWb_bits_pd_2_isRet(io_fromIfu_pdWb_bits_pd_2_isRet),
    .io_fromIfu_pdWb_bits_pd_3_valid(io_fromIfu_pdWb_bits_pd_3_valid),
    .io_fromIfu_pdWb_bits_pd_3_isRVC(io_fromIfu_pdWb_bits_pd_3_isRVC),
    .io_fromIfu_pdWb_bits_pd_3_brType(io_fromIfu_pdWb_bits_pd_3_brType),
    .io_fromIfu_pdWb_bits_pd_3_isCall(io_fromIfu_pdWb_bits_pd_3_isCall),
    .io_fromIfu_pdWb_bits_pd_3_isRet(io_fromIfu_pdWb_bits_pd_3_isRet),
    .io_fromIfu_pdWb_bits_pd_4_valid(io_fromIfu_pdWb_bits_pd_4_valid),
    .io_fromIfu_pdWb_bits_pd_4_isRVC(io_fromIfu_pdWb_bits_pd_4_isRVC),
    .io_fromIfu_pdWb_bits_pd_4_brType(io_fromIfu_pdWb_bits_pd_4_brType),
    .io_fromIfu_pdWb_bits_pd_4_isCall(io_fromIfu_pdWb_bits_pd_4_isCall),
    .io_fromIfu_pdWb_bits_pd_4_isRet(io_fromIfu_pdWb_bits_pd_4_isRet),
    .io_fromIfu_pdWb_bits_pd_5_valid(io_fromIfu_pdWb_bits_pd_5_valid),
    .io_fromIfu_pdWb_bits_pd_5_isRVC(io_fromIfu_pdWb_bits_pd_5_isRVC),
    .io_fromIfu_pdWb_bits_pd_5_brType(io_fromIfu_pdWb_bits_pd_5_brType),
    .io_fromIfu_pdWb_bits_pd_5_isCall(io_fromIfu_pdWb_bits_pd_5_isCall),
    .io_fromIfu_pdWb_bits_pd_5_isRet(io_fromIfu_pdWb_bits_pd_5_isRet),
    .io_fromIfu_pdWb_bits_pd_6_valid(io_fromIfu_pdWb_bits_pd_6_valid),
    .io_fromIfu_pdWb_bits_pd_6_isRVC(io_fromIfu_pdWb_bits_pd_6_isRVC),
    .io_fromIfu_pdWb_bits_pd_6_brType(io_fromIfu_pdWb_bits_pd_6_brType),
    .io_fromIfu_pdWb_bits_pd_6_isCall(io_fromIfu_pdWb_bits_pd_6_isCall),
    .io_fromIfu_pdWb_bits_pd_6_isRet(io_fromIfu_pdWb_bits_pd_6_isRet),
    .io_fromIfu_pdWb_bits_pd_7_valid(io_fromIfu_pdWb_bits_pd_7_valid),
    .io_fromIfu_pdWb_bits_pd_7_isRVC(io_fromIfu_pdWb_bits_pd_7_isRVC),
    .io_fromIfu_pdWb_bits_pd_7_brType(io_fromIfu_pdWb_bits_pd_7_brType),
    .io_fromIfu_pdWb_bits_pd_7_isCall(io_fromIfu_pdWb_bits_pd_7_isCall),
    .io_fromIfu_pdWb_bits_pd_7_isRet(io_fromIfu_pdWb_bits_pd_7_isRet),
    .io_fromIfu_pdWb_bits_pd_8_valid(io_fromIfu_pdWb_bits_pd_8_valid),
    .io_fromIfu_pdWb_bits_pd_8_isRVC(io_fromIfu_pdWb_bits_pd_8_isRVC),
    .io_fromIfu_pdWb_bits_pd_8_brType(io_fromIfu_pdWb_bits_pd_8_brType),
    .io_fromIfu_pdWb_bits_pd_8_isCall(io_fromIfu_pdWb_bits_pd_8_isCall),
    .io_fromIfu_pdWb_bits_pd_8_isRet(io_fromIfu_pdWb_bits_pd_8_isRet),
    .io_fromIfu_pdWb_bits_pd_9_valid(io_fromIfu_pdWb_bits_pd_9_valid),
    .io_fromIfu_pdWb_bits_pd_9_isRVC(io_fromIfu_pdWb_bits_pd_9_isRVC),
    .io_fromIfu_pdWb_bits_pd_9_brType(io_fromIfu_pdWb_bits_pd_9_brType),
    .io_fromIfu_pdWb_bits_pd_9_isCall(io_fromIfu_pdWb_bits_pd_9_isCall),
    .io_fromIfu_pdWb_bits_pd_9_isRet(io_fromIfu_pdWb_bits_pd_9_isRet),
    .io_fromIfu_pdWb_bits_pd_10_valid(io_fromIfu_pdWb_bits_pd_10_valid),
    .io_fromIfu_pdWb_bits_pd_10_isRVC(io_fromIfu_pdWb_bits_pd_10_isRVC),
    .io_fromIfu_pdWb_bits_pd_10_brType(io_fromIfu_pdWb_bits_pd_10_brType),
    .io_fromIfu_pdWb_bits_pd_10_isCall(io_fromIfu_pdWb_bits_pd_10_isCall),
    .io_fromIfu_pdWb_bits_pd_10_isRet(io_fromIfu_pdWb_bits_pd_10_isRet),
    .io_fromIfu_pdWb_bits_pd_11_valid(io_fromIfu_pdWb_bits_pd_11_valid),
    .io_fromIfu_pdWb_bits_pd_11_isRVC(io_fromIfu_pdWb_bits_pd_11_isRVC),
    .io_fromIfu_pdWb_bits_pd_11_brType(io_fromIfu_pdWb_bits_pd_11_brType),
    .io_fromIfu_pdWb_bits_pd_11_isCall(io_fromIfu_pdWb_bits_pd_11_isCall),
    .io_fromIfu_pdWb_bits_pd_11_isRet(io_fromIfu_pdWb_bits_pd_11_isRet),
    .io_fromIfu_pdWb_bits_pd_12_valid(io_fromIfu_pdWb_bits_pd_12_valid),
    .io_fromIfu_pdWb_bits_pd_12_isRVC(io_fromIfu_pdWb_bits_pd_12_isRVC),
    .io_fromIfu_pdWb_bits_pd_12_brType(io_fromIfu_pdWb_bits_pd_12_brType),
    .io_fromIfu_pdWb_bits_pd_12_isCall(io_fromIfu_pdWb_bits_pd_12_isCall),
    .io_fromIfu_pdWb_bits_pd_12_isRet(io_fromIfu_pdWb_bits_pd_12_isRet),
    .io_fromIfu_pdWb_bits_pd_13_valid(io_fromIfu_pdWb_bits_pd_13_valid),
    .io_fromIfu_pdWb_bits_pd_13_isRVC(io_fromIfu_pdWb_bits_pd_13_isRVC),
    .io_fromIfu_pdWb_bits_pd_13_brType(io_fromIfu_pdWb_bits_pd_13_brType),
    .io_fromIfu_pdWb_bits_pd_13_isCall(io_fromIfu_pdWb_bits_pd_13_isCall),
    .io_fromIfu_pdWb_bits_pd_13_isRet(io_fromIfu_pdWb_bits_pd_13_isRet),
    .io_fromIfu_pdWb_bits_pd_14_valid(io_fromIfu_pdWb_bits_pd_14_valid),
    .io_fromIfu_pdWb_bits_pd_14_isRVC(io_fromIfu_pdWb_bits_pd_14_isRVC),
    .io_fromIfu_pdWb_bits_pd_14_brType(io_fromIfu_pdWb_bits_pd_14_brType),
    .io_fromIfu_pdWb_bits_pd_14_isCall(io_fromIfu_pdWb_bits_pd_14_isCall),
    .io_fromIfu_pdWb_bits_pd_14_isRet(io_fromIfu_pdWb_bits_pd_14_isRet),
    .io_fromIfu_pdWb_bits_pd_15_valid(io_fromIfu_pdWb_bits_pd_15_valid),
    .io_fromIfu_pdWb_bits_pd_15_isRVC(io_fromIfu_pdWb_bits_pd_15_isRVC),
    .io_fromIfu_pdWb_bits_pd_15_brType(io_fromIfu_pdWb_bits_pd_15_brType),
    .io_fromIfu_pdWb_bits_pd_15_isCall(io_fromIfu_pdWb_bits_pd_15_isCall),
    .io_fromIfu_pdWb_bits_pd_15_isRet(io_fromIfu_pdWb_bits_pd_15_isRet),
    .io_fromIfu_pdWb_bits_ftqIdx_flag(io_fromIfu_pdWb_bits_ftqIdx_flag),
    .io_fromIfu_pdWb_bits_ftqIdx_value(io_fromIfu_pdWb_bits_ftqIdx_value),
    .io_fromIfu_pdWb_bits_misOffset_valid(io_fromIfu_pdWb_bits_misOffset_valid),
    .io_fromIfu_pdWb_bits_misOffset_bits(io_fromIfu_pdWb_bits_misOffset_bits),
    .io_fromIfu_pdWb_bits_cfiOffset_valid(io_fromIfu_pdWb_bits_cfiOffset_valid),
    .io_fromIfu_pdWb_bits_target(io_fromIfu_pdWb_bits_target),
    .io_fromIfu_pdWb_bits_jalTarget(io_fromIfu_pdWb_bits_jalTarget),
    .io_fromIfu_pdWb_bits_instrRange_0(io_fromIfu_pdWb_bits_instrRange_0),
    .io_fromIfu_pdWb_bits_instrRange_1(io_fromIfu_pdWb_bits_instrRange_1),
    .io_fromIfu_pdWb_bits_instrRange_2(io_fromIfu_pdWb_bits_instrRange_2),
    .io_fromIfu_pdWb_bits_instrRange_3(io_fromIfu_pdWb_bits_instrRange_3),
    .io_fromIfu_pdWb_bits_instrRange_4(io_fromIfu_pdWb_bits_instrRange_4),
    .io_fromIfu_pdWb_bits_instrRange_5(io_fromIfu_pdWb_bits_instrRange_5),
    .io_fromIfu_pdWb_bits_instrRange_6(io_fromIfu_pdWb_bits_instrRange_6),
    .io_fromIfu_pdWb_bits_instrRange_7(io_fromIfu_pdWb_bits_instrRange_7),
    .io_fromIfu_pdWb_bits_instrRange_8(io_fromIfu_pdWb_bits_instrRange_8),
    .io_fromIfu_pdWb_bits_instrRange_9(io_fromIfu_pdWb_bits_instrRange_9),
    .io_fromIfu_pdWb_bits_instrRange_10(io_fromIfu_pdWb_bits_instrRange_10),
    .io_fromIfu_pdWb_bits_instrRange_11(io_fromIfu_pdWb_bits_instrRange_11),
    .io_fromIfu_pdWb_bits_instrRange_12(io_fromIfu_pdWb_bits_instrRange_12),
    .io_fromIfu_pdWb_bits_instrRange_13(io_fromIfu_pdWb_bits_instrRange_13),
    .io_fromIfu_pdWb_bits_instrRange_14(io_fromIfu_pdWb_bits_instrRange_14),
    .io_fromIfu_pdWb_bits_instrRange_15(io_fromIfu_pdWb_bits_instrRange_15),
    .io_fromBackend_rob_commits_0_valid(io_fromBackend_rob_commits_0_valid),
    .io_fromBackend_rob_commits_0_bits_commitType(io_fromBackend_rob_commits_0_bits_commitType),
    .io_fromBackend_rob_commits_0_bits_ftqIdx_flag(io_fromBackend_rob_commits_0_bits_ftqIdx_flag),
    .io_fromBackend_rob_commits_0_bits_ftqIdx_value(io_fromBackend_rob_commits_0_bits_ftqIdx_value),
    .io_fromBackend_rob_commits_0_bits_ftqOffset(io_fromBackend_rob_commits_0_bits_ftqOffset),
    .io_fromBackend_rob_commits_1_valid(io_fromBackend_rob_commits_1_valid),
    .io_fromBackend_rob_commits_1_bits_commitType(io_fromBackend_rob_commits_1_bits_commitType),
    .io_fromBackend_rob_commits_1_bits_ftqIdx_flag(io_fromBackend_rob_commits_1_bits_ftqIdx_flag),
    .io_fromBackend_rob_commits_1_bits_ftqIdx_value(io_fromBackend_rob_commits_1_bits_ftqIdx_value),
    .io_fromBackend_rob_commits_1_bits_ftqOffset(io_fromBackend_rob_commits_1_bits_ftqOffset),
    .io_fromBackend_rob_commits_2_valid(io_fromBackend_rob_commits_2_valid),
    .io_fromBackend_rob_commits_2_bits_commitType(io_fromBackend_rob_commits_2_bits_commitType),
    .io_fromBackend_rob_commits_2_bits_ftqIdx_flag(io_fromBackend_rob_commits_2_bits_ftqIdx_flag),
    .io_fromBackend_rob_commits_2_bits_ftqIdx_value(io_fromBackend_rob_commits_2_bits_ftqIdx_value),
    .io_fromBackend_rob_commits_2_bits_ftqOffset(io_fromBackend_rob_commits_2_bits_ftqOffset),
    .io_fromBackend_rob_commits_3_valid(io_fromBackend_rob_commits_3_valid),
    .io_fromBackend_rob_commits_3_bits_commitType(io_fromBackend_rob_commits_3_bits_commitType),
    .io_fromBackend_rob_commits_3_bits_ftqIdx_flag(io_fromBackend_rob_commits_3_bits_ftqIdx_flag),
    .io_fromBackend_rob_commits_3_bits_ftqIdx_value(io_fromBackend_rob_commits_3_bits_ftqIdx_value),
    .io_fromBackend_rob_commits_3_bits_ftqOffset(io_fromBackend_rob_commits_3_bits_ftqOffset),
    .io_fromBackend_rob_commits_4_valid(io_fromBackend_rob_commits_4_valid),
    .io_fromBackend_rob_commits_4_bits_commitType(io_fromBackend_rob_commits_4_bits_commitType),
    .io_fromBackend_rob_commits_4_bits_ftqIdx_flag(io_fromBackend_rob_commits_4_bits_ftqIdx_flag),
    .io_fromBackend_rob_commits_4_bits_ftqIdx_value(io_fromBackend_rob_commits_4_bits_ftqIdx_value),
    .io_fromBackend_rob_commits_4_bits_ftqOffset(io_fromBackend_rob_commits_4_bits_ftqOffset),
    .io_fromBackend_rob_commits_5_valid(io_fromBackend_rob_commits_5_valid),
    .io_fromBackend_rob_commits_5_bits_commitType(io_fromBackend_rob_commits_5_bits_commitType),
    .io_fromBackend_rob_commits_5_bits_ftqIdx_flag(io_fromBackend_rob_commits_5_bits_ftqIdx_flag),
    .io_fromBackend_rob_commits_5_bits_ftqIdx_value(io_fromBackend_rob_commits_5_bits_ftqIdx_value),
    .io_fromBackend_rob_commits_5_bits_ftqOffset(io_fromBackend_rob_commits_5_bits_ftqOffset),
    .io_fromBackend_rob_commits_6_valid(io_fromBackend_rob_commits_6_valid),
    .io_fromBackend_rob_commits_6_bits_commitType(io_fromBackend_rob_commits_6_bits_commitType),
    .io_fromBackend_rob_commits_6_bits_ftqIdx_flag(io_fromBackend_rob_commits_6_bits_ftqIdx_flag),
    .io_fromBackend_rob_commits_6_bits_ftqIdx_value(io_fromBackend_rob_commits_6_bits_ftqIdx_value),
    .io_fromBackend_rob_commits_6_bits_ftqOffset(io_fromBackend_rob_commits_6_bits_ftqOffset),
    .io_fromBackend_rob_commits_7_valid(io_fromBackend_rob_commits_7_valid),
    .io_fromBackend_rob_commits_7_bits_commitType(io_fromBackend_rob_commits_7_bits_commitType),
    .io_fromBackend_rob_commits_7_bits_ftqIdx_flag(io_fromBackend_rob_commits_7_bits_ftqIdx_flag),
    .io_fromBackend_rob_commits_7_bits_ftqIdx_value(io_fromBackend_rob_commits_7_bits_ftqIdx_value),
    .io_fromBackend_rob_commits_7_bits_ftqOffset(io_fromBackend_rob_commits_7_bits_ftqOffset),
    .io_fromBackend_redirect_valid(io_fromBackend_redirect_valid),
    .io_fromBackend_redirect_bits_ftqIdx_flag(io_fromBackend_redirect_bits_ftqIdx_flag),
    .io_fromBackend_redirect_bits_ftqIdx_value(io_fromBackend_redirect_bits_ftqIdx_value),
    .io_fromBackend_redirect_bits_ftqOffset(io_fromBackend_redirect_bits_ftqOffset),
    .io_fromBackend_redirect_bits_level(io_fromBackend_redirect_bits_level),
    .io_fromBackend_redirect_bits_cfiUpdate_pc(io_fromBackend_redirect_bits_cfiUpdate_pc),
    .io_fromBackend_redirect_bits_cfiUpdate_target(io_fromBackend_redirect_bits_cfiUpdate_target),
    .io_fromBackend_redirect_bits_cfiUpdate_taken(io_fromBackend_redirect_bits_cfiUpdate_taken),
    .io_fromBackend_redirect_bits_cfiUpdate_isMisPred(io_fromBackend_redirect_bits_cfiUpdate_isMisPred),
    .io_fromBackend_redirect_bits_cfiUpdate_backendIGPF(io_fromBackend_redirect_bits_cfiUpdate_backendIGPF),
    .io_fromBackend_redirect_bits_cfiUpdate_backendIPF(io_fromBackend_redirect_bits_cfiUpdate_backendIPF),
    .io_fromBackend_redirect_bits_cfiUpdate_backendIAF(io_fromBackend_redirect_bits_cfiUpdate_backendIAF),
    .io_fromBackend_redirect_bits_satpFlush(io_fromBackend_redirect_bits_satpFlush),
    .io_fromBackend_redirect_bits_debugIsCtrl(io_fromBackend_redirect_bits_debugIsCtrl),
    .io_fromBackend_redirect_bits_debugIsMemVio(io_fromBackend_redirect_bits_debugIsMemVio),
    .io_fromBackend_ftqIdxAhead_0_valid(io_fromBackend_ftqIdxAhead_0_valid),
    .io_fromBackend_ftqIdxAhead_0_bits_value(io_fromBackend_ftqIdxAhead_0_bits_value),
    .io_fromBackend_ftqIdxSelOH_bits(io_fromBackend_ftqIdxSelOH_bits),
    .io_toIfu_req_ready(io_toIfu_req_ready),
    .io_toPrefetch_req_ready(io_toPrefetch_req_ready),
    .io_mmioCommitRead_valid(io_mmioCommitRead_valid),
    .io_mmioCommitRead_mmioFtqPtr_flag(io_mmioCommitRead_mmioFtqPtr_flag),
    .io_mmioCommitRead_mmioFtqPtr_value(io_mmioCommitRead_mmioFtqPtr_value),
    .io_fromBpu_resp_ready(i_io_fromBpu_resp_ready),
    .io_toBpu_redirect_valid(i_io_toBpu_redirect_valid),
    .io_toBpu_redirect_bits_level(i_io_toBpu_redirect_bits_level),
    .io_toBpu_redirect_bits_cfiUpdate_pc(i_io_toBpu_redirect_bits_cfiUpdate_pc),
    .io_toBpu_redirect_bits_cfiUpdate_pd_valid(i_io_toBpu_redirect_bits_cfiUpdate_pd_valid),
    .io_toBpu_redirect_bits_cfiUpdate_pd_isRVC(i_io_toBpu_redirect_bits_cfiUpdate_pd_isRVC),
    .io_toBpu_redirect_bits_cfiUpdate_pd_isCall(i_io_toBpu_redirect_bits_cfiUpdate_pd_isCall),
    .io_toBpu_redirect_bits_cfiUpdate_pd_isRet(i_io_toBpu_redirect_bits_cfiUpdate_pd_isRet),
    .io_toBpu_redirect_bits_cfiUpdate_ssp(i_io_toBpu_redirect_bits_cfiUpdate_ssp),
    .io_toBpu_redirect_bits_cfiUpdate_sctr(i_io_toBpu_redirect_bits_cfiUpdate_sctr),
    .io_toBpu_redirect_bits_cfiUpdate_TOSW_flag(i_io_toBpu_redirect_bits_cfiUpdate_TOSW_flag),
    .io_toBpu_redirect_bits_cfiUpdate_TOSW_value(i_io_toBpu_redirect_bits_cfiUpdate_TOSW_value),
    .io_toBpu_redirect_bits_cfiUpdate_TOSR_flag(i_io_toBpu_redirect_bits_cfiUpdate_TOSR_flag),
    .io_toBpu_redirect_bits_cfiUpdate_TOSR_value(i_io_toBpu_redirect_bits_cfiUpdate_TOSR_value),
    .io_toBpu_redirect_bits_cfiUpdate_NOS_flag(i_io_toBpu_redirect_bits_cfiUpdate_NOS_flag),
    .io_toBpu_redirect_bits_cfiUpdate_NOS_value(i_io_toBpu_redirect_bits_cfiUpdate_NOS_value),
    .io_toBpu_redirect_bits_cfiUpdate_histPtr_flag(i_io_toBpu_redirect_bits_cfiUpdate_histPtr_flag),
    .io_toBpu_redirect_bits_cfiUpdate_histPtr_value(i_io_toBpu_redirect_bits_cfiUpdate_histPtr_value),
    .io_toBpu_redirect_bits_cfiUpdate_br_hit(i_io_toBpu_redirect_bits_cfiUpdate_br_hit),
    .io_toBpu_redirect_bits_cfiUpdate_jr_hit(i_io_toBpu_redirect_bits_cfiUpdate_jr_hit),
    .io_toBpu_redirect_bits_cfiUpdate_sc_hit(i_io_toBpu_redirect_bits_cfiUpdate_sc_hit),
    .io_toBpu_redirect_bits_cfiUpdate_target(i_io_toBpu_redirect_bits_cfiUpdate_target),
    .io_toBpu_redirect_bits_cfiUpdate_taken(i_io_toBpu_redirect_bits_cfiUpdate_taken),
    .io_toBpu_redirect_bits_cfiUpdate_shift(i_io_toBpu_redirect_bits_cfiUpdate_shift),
    .io_toBpu_redirect_bits_cfiUpdate_addIntoHist(i_io_toBpu_redirect_bits_cfiUpdate_addIntoHist),
    .io_toBpu_redirect_bits_debugIsCtrl(i_io_toBpu_redirect_bits_debugIsCtrl),
    .io_toBpu_redirect_bits_debugIsMemVio(i_io_toBpu_redirect_bits_debugIsMemVio),
    .io_toBpu_redirect_bits_BTBMissBubble(i_io_toBpu_redirect_bits_BTBMissBubble),
    .io_toBpu_update_valid(i_io_toBpu_update_valid),
    .io_toBpu_update_bits_pc(i_io_toBpu_update_bits_pc),
    .io_toBpu_update_bits_spec_info_histPtr_value(i_io_toBpu_update_bits_spec_info_histPtr_value),
    .io_toBpu_update_bits_ftb_entry_isCall(i_io_toBpu_update_bits_ftb_entry_isCall),
    .io_toBpu_update_bits_ftb_entry_isRet(i_io_toBpu_update_bits_ftb_entry_isRet),
    .io_toBpu_update_bits_ftb_entry_isJalr(i_io_toBpu_update_bits_ftb_entry_isJalr),
    .io_toBpu_update_bits_ftb_entry_valid(i_io_toBpu_update_bits_ftb_entry_valid),
    .io_toBpu_update_bits_ftb_entry_brSlots_0_offset(i_io_toBpu_update_bits_ftb_entry_brSlots_0_offset),
    .io_toBpu_update_bits_ftb_entry_brSlots_0_sharing(i_io_toBpu_update_bits_ftb_entry_brSlots_0_sharing),
    .io_toBpu_update_bits_ftb_entry_brSlots_0_valid(i_io_toBpu_update_bits_ftb_entry_brSlots_0_valid),
    .io_toBpu_update_bits_ftb_entry_brSlots_0_lower(i_io_toBpu_update_bits_ftb_entry_brSlots_0_lower),
    .io_toBpu_update_bits_ftb_entry_brSlots_0_tarStat(i_io_toBpu_update_bits_ftb_entry_brSlots_0_tarStat),
    .io_toBpu_update_bits_ftb_entry_tailSlot_offset(i_io_toBpu_update_bits_ftb_entry_tailSlot_offset),
    .io_toBpu_update_bits_ftb_entry_tailSlot_sharing(i_io_toBpu_update_bits_ftb_entry_tailSlot_sharing),
    .io_toBpu_update_bits_ftb_entry_tailSlot_valid(i_io_toBpu_update_bits_ftb_entry_tailSlot_valid),
    .io_toBpu_update_bits_ftb_entry_tailSlot_lower(i_io_toBpu_update_bits_ftb_entry_tailSlot_lower),
    .io_toBpu_update_bits_ftb_entry_tailSlot_tarStat(i_io_toBpu_update_bits_ftb_entry_tailSlot_tarStat),
    .io_toBpu_update_bits_ftb_entry_pftAddr(i_io_toBpu_update_bits_ftb_entry_pftAddr),
    .io_toBpu_update_bits_ftb_entry_carry(i_io_toBpu_update_bits_ftb_entry_carry),
    .io_toBpu_update_bits_ftb_entry_last_may_be_rvi_call(i_io_toBpu_update_bits_ftb_entry_last_may_be_rvi_call),
    .io_toBpu_update_bits_ftb_entry_strong_bias_0(i_io_toBpu_update_bits_ftb_entry_strong_bias_0),
    .io_toBpu_update_bits_ftb_entry_strong_bias_1(i_io_toBpu_update_bits_ftb_entry_strong_bias_1),
    .io_toBpu_update_bits_cfi_idx_valid(i_io_toBpu_update_bits_cfi_idx_valid),
    .io_toBpu_update_bits_cfi_idx_bits(i_io_toBpu_update_bits_cfi_idx_bits),
    .io_toBpu_update_bits_br_taken_mask_0(i_io_toBpu_update_bits_br_taken_mask_0),
    .io_toBpu_update_bits_br_taken_mask_1(i_io_toBpu_update_bits_br_taken_mask_1),
    .io_toBpu_update_bits_jmp_taken(i_io_toBpu_update_bits_jmp_taken),
    .io_toBpu_update_bits_mispred_mask_0(i_io_toBpu_update_bits_mispred_mask_0),
    .io_toBpu_update_bits_mispred_mask_1(i_io_toBpu_update_bits_mispred_mask_1),
    .io_toBpu_update_bits_mispred_mask_2(i_io_toBpu_update_bits_mispred_mask_2),
    .io_toBpu_update_bits_false_hit(i_io_toBpu_update_bits_false_hit),
    .io_toBpu_update_bits_old_entry(i_io_toBpu_update_bits_old_entry),
    .io_toBpu_update_bits_meta(i_io_toBpu_update_bits_meta),
    .io_toBpu_update_bits_full_target(i_io_toBpu_update_bits_full_target),
    .io_toBpu_enq_ptr_flag(i_io_toBpu_enq_ptr_flag),
    .io_toBpu_enq_ptr_value(i_io_toBpu_enq_ptr_value),
    .io_toBpu_redirctFromIFU(i_io_toBpu_redirctFromIFU),
    .io_toIfu_req_valid(i_io_toIfu_req_valid),
    .io_toIfu_req_bits_startAddr(i_io_toIfu_req_bits_startAddr),
    .io_toIfu_req_bits_nextlineStart(i_io_toIfu_req_bits_nextlineStart),
    .io_toIfu_req_bits_nextStartAddr(i_io_toIfu_req_bits_nextStartAddr),
    .io_toIfu_req_bits_ftqIdx_flag(i_io_toIfu_req_bits_ftqIdx_flag),
    .io_toIfu_req_bits_ftqIdx_value(i_io_toIfu_req_bits_ftqIdx_value),
    .io_toIfu_req_bits_ftqOffset_valid(i_io_toIfu_req_bits_ftqOffset_valid),
    .io_toIfu_req_bits_ftqOffset_bits(i_io_toIfu_req_bits_ftqOffset_bits),
    .io_toIfu_req_bits_topdown_info_reasons_0(i_io_toIfu_req_bits_topdown_info_reasons_0),
    .io_toIfu_req_bits_topdown_info_reasons_1(i_io_toIfu_req_bits_topdown_info_reasons_1),
    .io_toIfu_req_bits_topdown_info_reasons_2(i_io_toIfu_req_bits_topdown_info_reasons_2),
    .io_toIfu_req_bits_topdown_info_reasons_3(i_io_toIfu_req_bits_topdown_info_reasons_3),
    .io_toIfu_req_bits_topdown_info_reasons_4(i_io_toIfu_req_bits_topdown_info_reasons_4),
    .io_toIfu_req_bits_topdown_info_reasons_5(i_io_toIfu_req_bits_topdown_info_reasons_5),
    .io_toIfu_req_bits_topdown_info_reasons_6(i_io_toIfu_req_bits_topdown_info_reasons_6),
    .io_toIfu_req_bits_topdown_info_reasons_7(i_io_toIfu_req_bits_topdown_info_reasons_7),
    .io_toIfu_req_bits_topdown_info_reasons_8(i_io_toIfu_req_bits_topdown_info_reasons_8),
    .io_toIfu_req_bits_topdown_info_reasons_9(i_io_toIfu_req_bits_topdown_info_reasons_9),
    .io_toIfu_req_bits_topdown_info_reasons_10(i_io_toIfu_req_bits_topdown_info_reasons_10),
    .io_toIfu_req_bits_topdown_info_reasons_11(i_io_toIfu_req_bits_topdown_info_reasons_11),
    .io_toIfu_req_bits_topdown_info_reasons_12(i_io_toIfu_req_bits_topdown_info_reasons_12),
    .io_toIfu_req_bits_topdown_info_reasons_13(i_io_toIfu_req_bits_topdown_info_reasons_13),
    .io_toIfu_req_bits_topdown_info_reasons_14(i_io_toIfu_req_bits_topdown_info_reasons_14),
    .io_toIfu_req_bits_topdown_info_reasons_15(i_io_toIfu_req_bits_topdown_info_reasons_15),
    .io_toIfu_req_bits_topdown_info_reasons_16(i_io_toIfu_req_bits_topdown_info_reasons_16),
    .io_toIfu_req_bits_topdown_info_reasons_17(i_io_toIfu_req_bits_topdown_info_reasons_17),
    .io_toIfu_req_bits_topdown_info_reasons_18(i_io_toIfu_req_bits_topdown_info_reasons_18),
    .io_toIfu_req_bits_topdown_info_reasons_19(i_io_toIfu_req_bits_topdown_info_reasons_19),
    .io_toIfu_req_bits_topdown_info_reasons_20(i_io_toIfu_req_bits_topdown_info_reasons_20),
    .io_toIfu_req_bits_topdown_info_reasons_21(i_io_toIfu_req_bits_topdown_info_reasons_21),
    .io_toIfu_req_bits_topdown_info_reasons_22(i_io_toIfu_req_bits_topdown_info_reasons_22),
    .io_toIfu_req_bits_topdown_info_reasons_23(i_io_toIfu_req_bits_topdown_info_reasons_23),
    .io_toIfu_req_bits_topdown_info_reasons_24(i_io_toIfu_req_bits_topdown_info_reasons_24),
    .io_toIfu_req_bits_topdown_info_reasons_25(i_io_toIfu_req_bits_topdown_info_reasons_25),
    .io_toIfu_req_bits_topdown_info_reasons_26(i_io_toIfu_req_bits_topdown_info_reasons_26),
    .io_toIfu_req_bits_topdown_info_reasons_27(i_io_toIfu_req_bits_topdown_info_reasons_27),
    .io_toIfu_req_bits_topdown_info_reasons_28(i_io_toIfu_req_bits_topdown_info_reasons_28),
    .io_toIfu_req_bits_topdown_info_reasons_29(i_io_toIfu_req_bits_topdown_info_reasons_29),
    .io_toIfu_req_bits_topdown_info_reasons_30(i_io_toIfu_req_bits_topdown_info_reasons_30),
    .io_toIfu_req_bits_topdown_info_reasons_31(i_io_toIfu_req_bits_topdown_info_reasons_31),
    .io_toIfu_req_bits_topdown_info_reasons_32(i_io_toIfu_req_bits_topdown_info_reasons_32),
    .io_toIfu_req_bits_topdown_info_reasons_33(i_io_toIfu_req_bits_topdown_info_reasons_33),
    .io_toIfu_req_bits_topdown_info_reasons_34(i_io_toIfu_req_bits_topdown_info_reasons_34),
    .io_toIfu_req_bits_topdown_info_reasons_35(i_io_toIfu_req_bits_topdown_info_reasons_35),
    .io_toIfu_req_bits_topdown_info_reasons_36(i_io_toIfu_req_bits_topdown_info_reasons_36),
    .io_toIfu_req_bits_topdown_info_reasons_37(i_io_toIfu_req_bits_topdown_info_reasons_37),
    .io_toIfu_redirect_valid(i_io_toIfu_redirect_valid),
    .io_toIfu_redirect_bits_ftqIdx_flag(i_io_toIfu_redirect_bits_ftqIdx_flag),
    .io_toIfu_redirect_bits_ftqIdx_value(i_io_toIfu_redirect_bits_ftqIdx_value),
    .io_toIfu_redirect_bits_ftqOffset(i_io_toIfu_redirect_bits_ftqOffset),
    .io_toIfu_redirect_bits_level(i_io_toIfu_redirect_bits_level),
    .io_toIfu_topdown_redirect_valid(i_io_toIfu_topdown_redirect_valid),
    .io_toIfu_topdown_redirect_bits_cfiUpdate_pd_isRet(i_io_toIfu_topdown_redirect_bits_cfiUpdate_pd_isRet),
    .io_toIfu_topdown_redirect_bits_cfiUpdate_br_hit(i_io_toIfu_topdown_redirect_bits_cfiUpdate_br_hit),
    .io_toIfu_topdown_redirect_bits_cfiUpdate_jr_hit(i_io_toIfu_topdown_redirect_bits_cfiUpdate_jr_hit),
    .io_toIfu_topdown_redirect_bits_cfiUpdate_sc_hit(i_io_toIfu_topdown_redirect_bits_cfiUpdate_sc_hit),
    .io_toIfu_topdown_redirect_bits_debugIsCtrl(i_io_toIfu_topdown_redirect_bits_debugIsCtrl),
    .io_toIfu_topdown_redirect_bits_debugIsMemVio(i_io_toIfu_topdown_redirect_bits_debugIsMemVio),
    .io_toIfu_flushFromBpu_s2_valid(i_io_toIfu_flushFromBpu_s2_valid),
    .io_toIfu_flushFromBpu_s2_bits_flag(i_io_toIfu_flushFromBpu_s2_bits_flag),
    .io_toIfu_flushFromBpu_s2_bits_value(i_io_toIfu_flushFromBpu_s2_bits_value),
    .io_toIfu_flushFromBpu_s3_valid(i_io_toIfu_flushFromBpu_s3_valid),
    .io_toIfu_flushFromBpu_s3_bits_flag(i_io_toIfu_flushFromBpu_s3_bits_flag),
    .io_toIfu_flushFromBpu_s3_bits_value(i_io_toIfu_flushFromBpu_s3_bits_value),
    .io_toICache_req_valid(i_io_toICache_req_valid),
    .io_toICache_req_bits_pcMemRead_0_startAddr(i_io_toICache_req_bits_pcMemRead_0_startAddr),
    .io_toICache_req_bits_pcMemRead_0_nextlineStart(i_io_toICache_req_bits_pcMemRead_0_nextlineStart),
    .io_toICache_req_bits_pcMemRead_1_startAddr(i_io_toICache_req_bits_pcMemRead_1_startAddr),
    .io_toICache_req_bits_pcMemRead_1_nextlineStart(i_io_toICache_req_bits_pcMemRead_1_nextlineStart),
    .io_toICache_req_bits_pcMemRead_2_startAddr(i_io_toICache_req_bits_pcMemRead_2_startAddr),
    .io_toICache_req_bits_pcMemRead_2_nextlineStart(i_io_toICache_req_bits_pcMemRead_2_nextlineStart),
    .io_toICache_req_bits_pcMemRead_3_startAddr(i_io_toICache_req_bits_pcMemRead_3_startAddr),
    .io_toICache_req_bits_pcMemRead_3_nextlineStart(i_io_toICache_req_bits_pcMemRead_3_nextlineStart),
    .io_toICache_req_bits_pcMemRead_4_startAddr(i_io_toICache_req_bits_pcMemRead_4_startAddr),
    .io_toICache_req_bits_pcMemRead_4_nextlineStart(i_io_toICache_req_bits_pcMemRead_4_nextlineStart),
    .io_toICache_req_bits_readValid_0(i_io_toICache_req_bits_readValid_0),
    .io_toICache_req_bits_readValid_1(i_io_toICache_req_bits_readValid_1),
    .io_toICache_req_bits_readValid_2(i_io_toICache_req_bits_readValid_2),
    .io_toICache_req_bits_readValid_3(i_io_toICache_req_bits_readValid_3),
    .io_toICache_req_bits_readValid_4(i_io_toICache_req_bits_readValid_4),
    .io_toICache_req_bits_backendException(i_io_toICache_req_bits_backendException),
    .io_toICache_req_bits_hasSatpFlush(i_io_toICache_req_bits_hasSatpFlush),
    .io_toBackend_pc_mem_wen(i_io_toBackend_pc_mem_wen),
    .io_toBackend_pc_mem_waddr(i_io_toBackend_pc_mem_waddr),
    .io_toBackend_pc_mem_wdata_startAddr(i_io_toBackend_pc_mem_wdata_startAddr),
    .io_toBackend_newest_entry_en(i_io_toBackend_newest_entry_en),
    .io_toBackend_newest_entry_target(i_io_toBackend_newest_entry_target),
    .io_toBackend_newest_entry_ptr_value(i_io_toBackend_newest_entry_ptr_value),
    .io_toPrefetch_req_valid(i_io_toPrefetch_req_valid),
    .io_toPrefetch_req_bits_startAddr(i_io_toPrefetch_req_bits_startAddr),
    .io_toPrefetch_req_bits_nextlineStart(i_io_toPrefetch_req_bits_nextlineStart),
    .io_toPrefetch_req_bits_ftqIdx_flag(i_io_toPrefetch_req_bits_ftqIdx_flag),
    .io_toPrefetch_req_bits_ftqIdx_value(i_io_toPrefetch_req_bits_ftqIdx_value),
    .io_toPrefetch_flushFromBpu_s2_valid(i_io_toPrefetch_flushFromBpu_s2_valid),
    .io_toPrefetch_flushFromBpu_s2_bits_flag(i_io_toPrefetch_flushFromBpu_s2_bits_flag),
    .io_toPrefetch_flushFromBpu_s2_bits_value(i_io_toPrefetch_flushFromBpu_s2_bits_value),
    .io_toPrefetch_flushFromBpu_s3_valid(i_io_toPrefetch_flushFromBpu_s3_valid),
    .io_toPrefetch_flushFromBpu_s3_bits_flag(i_io_toPrefetch_flushFromBpu_s3_bits_flag),
    .io_toPrefetch_flushFromBpu_s3_bits_value(i_io_toPrefetch_flushFromBpu_s3_bits_value),
    .io_toPrefetch_backendException(i_io_toPrefetch_backendException),
    .io_icacheFlush(i_io_icacheFlush),
    .io_mmioCommitRead_mmioLastCommit(i_io_mmioCommitRead_mmioLastCommit),
    .io_ControlBTBMissBubble(i_io_ControlBTBMissBubble),
    .io_TAGEMissBubble(i_io_TAGEMissBubble),
    .io_SCMissBubble(i_io_SCMissBubble),
    .io_ITTAGEMissBubble(i_io_ITTAGEMissBubble),
    .io_RASMissBubble(i_io_RASMissBubble),
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
    .io_perf_12_value(i_io_perf_12_value),
    .io_perf_13_value(i_io_perf_13_value),
    .io_perf_14_value(i_io_perf_14_value),
    .io_perf_15_value(i_io_perf_15_value),
    .io_perf_16_value(i_io_perf_16_value),
    .io_perf_17_value(i_io_perf_17_value),
    .io_perf_18_value(i_io_perf_18_value),
    .io_perf_19_value(i_io_perf_19_value),
    .io_perf_20_value(i_io_perf_20_value),
    .io_perf_21_value(i_io_perf_21_value),
    .io_perf_22_value(i_io_perf_22_value),
    .io_perf_23_value(i_io_perf_23_value)
  );

  // =========================================================================
  // 激励生成
  // =========================================================================
  // bpuPtr 延迟链：BPU s1 在 bpuPtr 处分配块，s2 下一拍、s3 再下一拍带着同一 idx 回来
  logic       enq_flag_d1, enq_flag_d2;
  logic [5:0] enq_val_d1,  enq_val_d2;
  // ifuPtr 延迟链：IFU 取完指再做预解码写回，延迟 4 拍近似
  logic       ifu_flag_d [0:3];
  logic [5:0] ifu_val_d  [0:3];
  // 提交扫描锚点：保证某一块的 16 个槽都被标掉，commPtr 才会真的推进
  logic [5:0] commit_idx;
  logic [3:0] commit_off;
  logic [5:0] mmio_idx;
  int unsigned tick;

  // 本拍的“事件抽签”结果，drive() 要用，故声明在前
  bit s2_fire, s3_fire, be_redir, ahead_v;
  logic [2:0] ahead_sel;

  function automatic bit chance(int unsigned pct);
    return ($urandom_range(0, 99) < pct);
  endfunction

  // ---- 覆盖计数（关键事件；为 0 即判失败）----
  longint cov_bpu_enq_fire   = 0;   // BPU 预测块入队握手
  longint cov_s2_redirect    = 0;   // s2 覆盖 s1（bpuPtr 回退）
  longint cov_s3_redirect    = 0;   // s3 覆盖（bpuPtr 回退）
  longint cov_ifu_req_fire   = 0;   // 向 IFU 发出取指请求握手
  longint cov_pf_req_fire    = 0;   // 向 Prefetch 发出请求握手
  longint cov_pdwb           = 0;   // IFU 预解码写回
  longint cov_be_redirect    = 0;   // 后端重定向
  longint cov_be_redir_ahead = 0;   // 后端重定向走 ftqIdxAhead 提前路径
  longint cov_satp_redirect  = 0;   // ★后端重定向带 satpFlush（G1 新增）
  longint cov_satp_out       = 0;   // ★io_toICache_req_bits_hasSatpFlush 拉高
  longint cov_backend_exc    = 0;   // io_toICache_req_bits_backendException 拉高
  longint cov_rob_commit     = 0;   // rob 提交
  longint cov_bpu_update     = 0;   // 向 BPU 回送 update（出队训练）
  longint cov_ifu_redirect   = 0;   // FTQ 向 IFU 发重定向
  longint cov_icache_flush   = 0;   // icacheFlush
  longint cov_mmio_read      = 0;   // mmioCommitRead.valid（G1 新增门控输入）
  longint cov_mmio_lastcmt   = 0;   // mmioLastCommit 拉高
  longint cov_bpu_stall      = 0;   // FTQ 反压 BPU（resp_ready=0）

  always @(posedge clk) begin
    if (rst) begin
      enq_flag_d1 <= 0; enq_val_d1 <= 0; enq_flag_d2 <= 0; enq_val_d2 <= 0;
      for (int k = 0; k < 4; k++) begin ifu_flag_d[k] <= 0; ifu_val_d[k] <= 0; end
      commit_idx <= 0; commit_off <= 0; mmio_idx <= 0; tick <= 0;
    end else begin
      enq_flag_d1 <= g_io_toBpu_enq_ptr_flag;  enq_val_d1 <= g_io_toBpu_enq_ptr_value;
      enq_flag_d2 <= enq_flag_d1;              enq_val_d2 <= enq_val_d1;
      ifu_flag_d[0] <= g_io_toIfu_req_bits_ftqIdx_flag;
      ifu_val_d[0]  <= g_io_toIfu_req_bits_ftqIdx_value;
      for (int k = 1; k < 4; k++) begin
        ifu_flag_d[k] <= ifu_flag_d[k-1]; ifu_val_d[k] <= ifu_val_d[k-1];
      end
      tick <= tick + 1;
      // 提交锚点：每拍扫一个槽，扫满 16 槽换下一块 —— 这样 commPtr 一定能推进
      if (commit_off == 4'hF) begin commit_off <= 0; commit_idx <= commit_idx + 1; end
      else commit_off <= commit_off + 1;
      if (tick[4:0] == 0) mmio_idx <= mmio_idx + 1;
    end
  end

  task automatic drive();
    // ---- 纯随机字段（payload：pc/target/meta/ftb_entry/pd 等）----
    io_fromBpu_resp_bits_s1_pc_3 = 50'({$urandom(), $urandom()});
    io_fromBpu_resp_bits_s1_full_pred_0_predCycle = 64'({$urandom(), $urandom()});
    io_fromBpu_resp_bits_s1_full_pred_3_br_taken_mask_0 = $urandom_range(0,1);
    io_fromBpu_resp_bits_s1_full_pred_3_br_taken_mask_1 = $urandom_range(0,1);
    io_fromBpu_resp_bits_s1_full_pred_3_slot_valids_0 = $urandom_range(0,1);
    io_fromBpu_resp_bits_s1_full_pred_3_slot_valids_1 = $urandom_range(0,1);
    io_fromBpu_resp_bits_s1_full_pred_3_targets_0 = 50'({$urandom(), $urandom()});
    io_fromBpu_resp_bits_s1_full_pred_3_targets_1 = 50'({$urandom(), $urandom()});
    io_fromBpu_resp_bits_s1_full_pred_3_offsets_0 = 4'($urandom());
    io_fromBpu_resp_bits_s1_full_pred_3_offsets_1 = 4'($urandom());
    io_fromBpu_resp_bits_s1_full_pred_3_fallThroughAddr = 50'({$urandom(), $urandom()});
    io_fromBpu_resp_bits_s1_full_pred_3_fallThroughErr = $urandom_range(0,1);
    io_fromBpu_resp_bits_s1_full_pred_3_is_br_sharing = $urandom_range(0,1);
    io_fromBpu_resp_bits_s1_full_pred_3_hit = $urandom_range(0,1);
    io_fromBpu_resp_bits_s2_pc_3 = 50'({$urandom(), $urandom()});
    io_fromBpu_resp_bits_s2_hasRedirect_3 = $urandom_range(0,1);
    io_fromBpu_resp_bits_s2_full_pred_0_predCycle = 64'({$urandom(), $urandom()});
    io_fromBpu_resp_bits_s2_full_pred_3_br_taken_mask_0 = $urandom_range(0,1);
    io_fromBpu_resp_bits_s2_full_pred_3_br_taken_mask_1 = $urandom_range(0,1);
    io_fromBpu_resp_bits_s2_full_pred_3_slot_valids_0 = $urandom_range(0,1);
    io_fromBpu_resp_bits_s2_full_pred_3_slot_valids_1 = $urandom_range(0,1);
    io_fromBpu_resp_bits_s2_full_pred_3_targets_0 = 50'({$urandom(), $urandom()});
    io_fromBpu_resp_bits_s2_full_pred_3_targets_1 = 50'({$urandom(), $urandom()});
    io_fromBpu_resp_bits_s2_full_pred_3_offsets_0 = 4'($urandom());
    io_fromBpu_resp_bits_s2_full_pred_3_offsets_1 = 4'($urandom());
    io_fromBpu_resp_bits_s2_full_pred_3_fallThroughAddr = 50'({$urandom(), $urandom()});
    io_fromBpu_resp_bits_s2_full_pred_3_fallThroughErr = $urandom_range(0,1);
    io_fromBpu_resp_bits_s2_full_pred_3_is_br_sharing = $urandom_range(0,1);
    io_fromBpu_resp_bits_s2_full_pred_3_hit = $urandom_range(0,1);
    io_fromBpu_resp_bits_s3_pc_0 = 50'({$urandom(), $urandom()});
    io_fromBpu_resp_bits_s3_pc_3 = 50'({$urandom(), $urandom()});
    io_fromBpu_resp_bits_s3_hasRedirect_3 = $urandom_range(0,1);
    io_fromBpu_resp_bits_s3_full_pred_0_predCycle = 64'({$urandom(), $urandom()});
    io_fromBpu_resp_bits_s3_full_pred_3_br_taken_mask_0 = $urandom_range(0,1);
    io_fromBpu_resp_bits_s3_full_pred_3_br_taken_mask_1 = $urandom_range(0,1);
    io_fromBpu_resp_bits_s3_full_pred_3_slot_valids_0 = $urandom_range(0,1);
    io_fromBpu_resp_bits_s3_full_pred_3_slot_valids_1 = $urandom_range(0,1);
    io_fromBpu_resp_bits_s3_full_pred_3_targets_0 = 50'({$urandom(), $urandom()});
    io_fromBpu_resp_bits_s3_full_pred_3_targets_1 = 50'({$urandom(), $urandom()});
    io_fromBpu_resp_bits_s3_full_pred_3_offsets_0 = 4'($urandom());
    io_fromBpu_resp_bits_s3_full_pred_3_offsets_1 = 4'($urandom());
    io_fromBpu_resp_bits_s3_full_pred_3_fallThroughAddr = 50'({$urandom(), $urandom()});
    io_fromBpu_resp_bits_s3_full_pred_3_fallThroughErr = $urandom_range(0,1);
    io_fromBpu_resp_bits_s3_full_pred_3_is_br_sharing = $urandom_range(0,1);
    io_fromBpu_resp_bits_s3_full_pred_3_hit = $urandom_range(0,1);
    io_fromBpu_resp_bits_last_stage_meta = 516'({$urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom(), $urandom()});
    io_fromBpu_resp_bits_last_stage_spec_info_histPtr_flag = $urandom_range(0,1);
    io_fromBpu_resp_bits_last_stage_spec_info_histPtr_value = 8'($urandom());
    io_fromBpu_resp_bits_last_stage_spec_info_ssp = 4'($urandom());
    io_fromBpu_resp_bits_last_stage_spec_info_sctr = 3'($urandom());
    io_fromBpu_resp_bits_last_stage_spec_info_TOSW_flag = $urandom_range(0,1);
    io_fromBpu_resp_bits_last_stage_spec_info_TOSW_value = 5'($urandom());
    io_fromBpu_resp_bits_last_stage_spec_info_TOSR_flag = $urandom_range(0,1);
    io_fromBpu_resp_bits_last_stage_spec_info_TOSR_value = 5'($urandom());
    io_fromBpu_resp_bits_last_stage_spec_info_NOS_flag = $urandom_range(0,1);
    io_fromBpu_resp_bits_last_stage_spec_info_NOS_value = 5'($urandom());
    io_fromBpu_resp_bits_last_stage_spec_info_topAddr = 50'({$urandom(), $urandom()});
    io_fromBpu_resp_bits_last_stage_spec_info_sc_disagree_0 = $urandom_range(0,1);
    io_fromBpu_resp_bits_last_stage_spec_info_sc_disagree_1 = $urandom_range(0,1);
    io_fromBpu_resp_bits_last_stage_ftb_entry_isCall = $urandom_range(0,1);
    io_fromBpu_resp_bits_last_stage_ftb_entry_isRet = $urandom_range(0,1);
    io_fromBpu_resp_bits_last_stage_ftb_entry_isJalr = $urandom_range(0,1);
    io_fromBpu_resp_bits_last_stage_ftb_entry_valid = $urandom_range(0,1);
    io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_offset = 4'($urandom());
    io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_sharing = $urandom_range(0,1);
    io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_valid = $urandom_range(0,1);
    io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_lower = 12'($urandom());
    io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat = 2'($urandom());
    io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_offset = 4'($urandom());
    io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_sharing = $urandom_range(0,1);
    io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_valid = $urandom_range(0,1);
    io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_lower = 20'($urandom());
    io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_tarStat = 2'($urandom());
    io_fromBpu_resp_bits_last_stage_ftb_entry_pftAddr = 4'($urandom());
    io_fromBpu_resp_bits_last_stage_ftb_entry_carry = $urandom_range(0,1);
    io_fromBpu_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call = $urandom_range(0,1);
    io_fromBpu_resp_bits_last_stage_ftb_entry_strong_bias_0 = $urandom_range(0,1);
    io_fromBpu_resp_bits_last_stage_ftb_entry_strong_bias_1 = $urandom_range(0,1);
    io_fromBpu_resp_bits_topdown_info_reasons_1 = $urandom_range(0,1);
    io_fromBpu_resp_bits_topdown_info_reasons_2 = $urandom_range(0,1);
    io_fromBpu_resp_bits_topdown_info_reasons_3 = $urandom_range(0,1);
    io_fromBpu_resp_bits_topdown_info_reasons_4 = $urandom_range(0,1);
    io_fromBpu_resp_bits_topdown_info_reasons_5 = $urandom_range(0,1);
    io_fromBpu_resp_bits_topdown_info_reasons_6 = $urandom_range(0,1);
    io_fromBpu_resp_bits_topdown_info_reasons_7 = $urandom_range(0,1);
    io_fromBpu_resp_bits_topdown_info_reasons_8 = $urandom_range(0,1);
    io_fromBpu_resp_bits_topdown_info_reasons_9 = $urandom_range(0,1);
    io_fromBpu_resp_bits_topdown_info_reasons_12 = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pc_0 = 50'({$urandom(), $urandom()});
    io_fromIfu_pdWb_bits_pc_1 = 50'({$urandom(), $urandom()});
    io_fromIfu_pdWb_bits_pc_2 = 50'({$urandom(), $urandom()});
    io_fromIfu_pdWb_bits_pc_3 = 50'({$urandom(), $urandom()});
    io_fromIfu_pdWb_bits_pc_4 = 50'({$urandom(), $urandom()});
    io_fromIfu_pdWb_bits_pc_5 = 50'({$urandom(), $urandom()});
    io_fromIfu_pdWb_bits_pc_6 = 50'({$urandom(), $urandom()});
    io_fromIfu_pdWb_bits_pc_7 = 50'({$urandom(), $urandom()});
    io_fromIfu_pdWb_bits_pc_8 = 50'({$urandom(), $urandom()});
    io_fromIfu_pdWb_bits_pc_9 = 50'({$urandom(), $urandom()});
    io_fromIfu_pdWb_bits_pc_10 = 50'({$urandom(), $urandom()});
    io_fromIfu_pdWb_bits_pc_11 = 50'({$urandom(), $urandom()});
    io_fromIfu_pdWb_bits_pc_12 = 50'({$urandom(), $urandom()});
    io_fromIfu_pdWb_bits_pc_13 = 50'({$urandom(), $urandom()});
    io_fromIfu_pdWb_bits_pc_14 = 50'({$urandom(), $urandom()});
    io_fromIfu_pdWb_bits_pc_15 = 50'({$urandom(), $urandom()});
    io_fromIfu_pdWb_bits_pd_0_valid = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_0_isRVC = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_0_brType = 2'($urandom());
    io_fromIfu_pdWb_bits_pd_0_isCall = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_0_isRet = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_1_valid = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_1_isRVC = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_1_brType = 2'($urandom());
    io_fromIfu_pdWb_bits_pd_1_isCall = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_1_isRet = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_2_valid = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_2_isRVC = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_2_brType = 2'($urandom());
    io_fromIfu_pdWb_bits_pd_2_isCall = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_2_isRet = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_3_valid = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_3_isRVC = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_3_brType = 2'($urandom());
    io_fromIfu_pdWb_bits_pd_3_isCall = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_3_isRet = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_4_valid = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_4_isRVC = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_4_brType = 2'($urandom());
    io_fromIfu_pdWb_bits_pd_4_isCall = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_4_isRet = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_5_valid = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_5_isRVC = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_5_brType = 2'($urandom());
    io_fromIfu_pdWb_bits_pd_5_isCall = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_5_isRet = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_6_valid = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_6_isRVC = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_6_brType = 2'($urandom());
    io_fromIfu_pdWb_bits_pd_6_isCall = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_6_isRet = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_7_valid = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_7_isRVC = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_7_brType = 2'($urandom());
    io_fromIfu_pdWb_bits_pd_7_isCall = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_7_isRet = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_8_valid = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_8_isRVC = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_8_brType = 2'($urandom());
    io_fromIfu_pdWb_bits_pd_8_isCall = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_8_isRet = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_9_valid = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_9_isRVC = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_9_brType = 2'($urandom());
    io_fromIfu_pdWb_bits_pd_9_isCall = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_9_isRet = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_10_valid = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_10_isRVC = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_10_brType = 2'($urandom());
    io_fromIfu_pdWb_bits_pd_10_isCall = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_10_isRet = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_11_valid = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_11_isRVC = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_11_brType = 2'($urandom());
    io_fromIfu_pdWb_bits_pd_11_isCall = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_11_isRet = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_12_valid = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_12_isRVC = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_12_brType = 2'($urandom());
    io_fromIfu_pdWb_bits_pd_12_isCall = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_12_isRet = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_13_valid = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_13_isRVC = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_13_brType = 2'($urandom());
    io_fromIfu_pdWb_bits_pd_13_isCall = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_13_isRet = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_14_valid = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_14_isRVC = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_14_brType = 2'($urandom());
    io_fromIfu_pdWb_bits_pd_14_isCall = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_14_isRet = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_15_valid = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_15_isRVC = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_15_brType = 2'($urandom());
    io_fromIfu_pdWb_bits_pd_15_isCall = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_pd_15_isRet = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_misOffset_valid = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_misOffset_bits = 4'($urandom());
    io_fromIfu_pdWb_bits_cfiOffset_valid = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_target = 50'({$urandom(), $urandom()});
    io_fromIfu_pdWb_bits_jalTarget = 50'({$urandom(), $urandom()});
    io_fromIfu_pdWb_bits_instrRange_0 = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_instrRange_1 = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_instrRange_2 = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_instrRange_3 = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_instrRange_4 = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_instrRange_5 = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_instrRange_6 = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_instrRange_7 = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_instrRange_8 = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_instrRange_9 = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_instrRange_10 = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_instrRange_11 = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_instrRange_12 = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_instrRange_13 = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_instrRange_14 = $urandom_range(0,1);
    io_fromIfu_pdWb_bits_instrRange_15 = $urandom_range(0,1);
    io_fromBackend_rob_commits_0_bits_commitType = 3'($urandom());
    io_fromBackend_rob_commits_1_bits_commitType = 3'($urandom());
    io_fromBackend_rob_commits_2_bits_commitType = 3'($urandom());
    io_fromBackend_rob_commits_3_bits_commitType = 3'($urandom());
    io_fromBackend_rob_commits_4_bits_commitType = 3'($urandom());
    io_fromBackend_rob_commits_5_bits_commitType = 3'($urandom());
    io_fromBackend_rob_commits_6_bits_commitType = 3'($urandom());
    io_fromBackend_rob_commits_7_bits_commitType = 3'($urandom());
    io_fromBackend_redirect_bits_ftqOffset = 4'($urandom());
    io_fromBackend_redirect_bits_level = $urandom_range(0,1);
    io_fromBackend_redirect_bits_cfiUpdate_pc = 50'({$urandom(), $urandom()});
    io_fromBackend_redirect_bits_cfiUpdate_target = 50'({$urandom(), $urandom()});
    io_fromBackend_redirect_bits_cfiUpdate_taken = $urandom_range(0,1);
    io_fromBackend_redirect_bits_cfiUpdate_isMisPred = $urandom_range(0,1);
    io_fromBackend_redirect_bits_cfiUpdate_backendIGPF = $urandom_range(0,1);
    io_fromBackend_redirect_bits_cfiUpdate_backendIPF = $urandom_range(0,1);
    io_fromBackend_redirect_bits_cfiUpdate_backendIAF = $urandom_range(0,1);
    io_fromBackend_redirect_bits_debugIsCtrl = $urandom_range(0,1);
    io_fromBackend_redirect_bits_debugIsMemVio = $urandom_range(0,1);

    // ---- BPU 三级预测流水 ----
    io_fromBpu_resp_valid = chance(75);
    io_fromBpu_resp_bits_s2_valid_3 = s2_fire;
    io_fromBpu_resp_bits_s3_valid_3 = s3_fire;
    // s2/s3 覆盖必须带 s1 当初分配到的 ftqIdx，否则 FTQ 认不出是同一块
    io_fromBpu_resp_bits_s2_ftq_idx_flag  = enq_flag_d1;
    io_fromBpu_resp_bits_s2_ftq_idx_value = enq_val_d1;
    io_fromBpu_resp_bits_s3_ftq_idx_flag  = enq_flag_d2;
    io_fromBpu_resp_bits_s3_ftq_idx_value = enq_val_d2;

    // ---- IFU / Prefetch 背压 ----
    io_toIfu_req_ready      = chance(85);
    io_toPrefetch_req_ready = chance(85);

    // ---- IFU 预解码写回：跟着已发出去的取指块走 ----
    io_fromIfu_pdWb_valid          = chance(30);
    io_fromIfu_pdWb_bits_ftqIdx_flag  = ifu_flag_d[3];
    io_fromIfu_pdWb_bits_ftqIdx_value = ifu_val_d[3];

    // ---- 后端重定向（稀疏）；ahead 路径与普通路径各占一半 ----
    io_fromBackend_redirect_valid = be_redir;
    io_fromBackend_redirect_bits_ftqIdx_flag  = ifu_flag_d[1];
    io_fromBackend_redirect_bits_ftqIdx_value = ifu_val_d[1];
    // ★G1 新增：satpFlush —— 只在真有重定向时才可能置 1（后端语义）
    io_fromBackend_redirect_bits_satpFlush = be_redir & chance(35);
    io_fromBackend_ftqIdxAhead_0_valid     = ahead_v;
    io_fromBackend_ftqIdxAhead_0_bits_value= ifu_val_d[1];
    io_fromBackend_ftqIdxSelOH_bits        = ahead_sel;

    // ---- rob 提交：锚点逐槽扫 + 少量随机散点 ----
    io_fromBackend_rob_commits_0_valid = chance(45);
    io_fromBackend_rob_commits_0_bits_ftqIdx_flag  = 1'b0;
    io_fromBackend_rob_commits_0_bits_ftqIdx_value = chance(80) ? commit_idx
                                                     : 6'($urandom());
    io_fromBackend_rob_commits_0_bits_ftqOffset = chance(80) ? commit_off
                                                  : 4'($urandom());
    io_fromBackend_rob_commits_1_valid = chance(45);
    io_fromBackend_rob_commits_1_bits_ftqIdx_flag  = 1'b0;
    io_fromBackend_rob_commits_1_bits_ftqIdx_value = chance(80) ? commit_idx
                                                     : 6'($urandom());
    io_fromBackend_rob_commits_1_bits_ftqOffset = chance(80) ? commit_off
                                                  : 4'($urandom());
    io_fromBackend_rob_commits_2_valid = chance(45);
    io_fromBackend_rob_commits_2_bits_ftqIdx_flag  = 1'b0;
    io_fromBackend_rob_commits_2_bits_ftqIdx_value = chance(80) ? commit_idx
                                                     : 6'($urandom());
    io_fromBackend_rob_commits_2_bits_ftqOffset = chance(80) ? commit_off
                                                  : 4'($urandom());
    io_fromBackend_rob_commits_3_valid = chance(45);
    io_fromBackend_rob_commits_3_bits_ftqIdx_flag  = 1'b0;
    io_fromBackend_rob_commits_3_bits_ftqIdx_value = chance(80) ? commit_idx
                                                     : 6'($urandom());
    io_fromBackend_rob_commits_3_bits_ftqOffset = chance(80) ? commit_off
                                                  : 4'($urandom());
    io_fromBackend_rob_commits_4_valid = chance(45);
    io_fromBackend_rob_commits_4_bits_ftqIdx_flag  = 1'b0;
    io_fromBackend_rob_commits_4_bits_ftqIdx_value = chance(80) ? commit_idx
                                                     : 6'($urandom());
    io_fromBackend_rob_commits_4_bits_ftqOffset = chance(80) ? commit_off
                                                  : 4'($urandom());
    io_fromBackend_rob_commits_5_valid = chance(45);
    io_fromBackend_rob_commits_5_bits_ftqIdx_flag  = 1'b0;
    io_fromBackend_rob_commits_5_bits_ftqIdx_value = chance(80) ? commit_idx
                                                     : 6'($urandom());
    io_fromBackend_rob_commits_5_bits_ftqOffset = chance(80) ? commit_off
                                                  : 4'($urandom());
    io_fromBackend_rob_commits_6_valid = chance(45);
    io_fromBackend_rob_commits_6_bits_ftqIdx_flag  = 1'b0;
    io_fromBackend_rob_commits_6_bits_ftqIdx_value = chance(80) ? commit_idx
                                                     : 6'($urandom());
    io_fromBackend_rob_commits_6_bits_ftqOffset = chance(80) ? commit_off
                                                  : 4'($urandom());
    io_fromBackend_rob_commits_7_valid = chance(45);
    io_fromBackend_rob_commits_7_bits_ftqIdx_flag  = 1'b0;
    io_fromBackend_rob_commits_7_bits_ftqIdx_value = chance(80) ? commit_idx
                                                     : 6'($urandom());
    io_fromBackend_rob_commits_7_bits_ftqOffset = chance(80) ? commit_off
                                                  : 4'($urandom());

    // ---- mmio 提交读（G1 新增 valid 门控）----
    io_mmioCommitRead_valid = chance(25);
    io_mmioCommitRead_mmioFtqPtr_flag  = 1'b0;
    io_mmioCommitRead_mmioFtqPtr_value = chance(70) ? commit_idx : mmio_idx;
  endtask

  always @(negedge clk) begin
    s2_fire   = chance(20);
    s3_fire   = chance(15);
    be_redir  = chance(3);
    ahead_v   = chance(4);
    ahead_sel = chance(60) ? 3'b001 : 3'($urandom());
    drive();
  end

  // =========================================================================
  // 逐拍比对全部 196 个输出
  // =========================================================================
  // drive() 在 negedge 打激励，这里在 posedge 采样 —— 不同事件，无竞争；
  // 采到的是上一拍激励作用下已完全稳定的输出。
  always @(posedge clk) if (!rst) begin
    if (!$isunknown(g_io_fromBpu_resp_ready)) begin checks++;
      if (g_io_fromBpu_resp_ready !== i_io_fromBpu_resp_ready) begin errors++;
        if (errors<=60) $display("[%0t] io_fromBpu_resp_ready g=%h i=%h", $time, g_io_fromBpu_resp_ready, i_io_fromBpu_resp_ready); end end
    if (!$isunknown(g_io_toBpu_redirect_valid)) begin checks++;
      if (g_io_toBpu_redirect_valid !== i_io_toBpu_redirect_valid) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_valid g=%h i=%h", $time, g_io_toBpu_redirect_valid, i_io_toBpu_redirect_valid); end end
    if (!$isunknown(g_io_toBpu_redirect_bits_level)) begin checks++;
      if (g_io_toBpu_redirect_bits_level !== i_io_toBpu_redirect_bits_level) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_bits_level g=%h i=%h", $time, g_io_toBpu_redirect_bits_level, i_io_toBpu_redirect_bits_level); end end
    if (!$isunknown(g_io_toBpu_redirect_bits_cfiUpdate_pc)) begin checks++;
      if (g_io_toBpu_redirect_bits_cfiUpdate_pc !== i_io_toBpu_redirect_bits_cfiUpdate_pc) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_bits_cfiUpdate_pc g=%h i=%h", $time, g_io_toBpu_redirect_bits_cfiUpdate_pc, i_io_toBpu_redirect_bits_cfiUpdate_pc); end end
    if (!$isunknown(g_io_toBpu_redirect_bits_cfiUpdate_pd_valid)) begin checks++;
      if (g_io_toBpu_redirect_bits_cfiUpdate_pd_valid !== i_io_toBpu_redirect_bits_cfiUpdate_pd_valid) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_bits_cfiUpdate_pd_valid g=%h i=%h", $time, g_io_toBpu_redirect_bits_cfiUpdate_pd_valid, i_io_toBpu_redirect_bits_cfiUpdate_pd_valid); end end
    if (!$isunknown(g_io_toBpu_redirect_bits_cfiUpdate_pd_isRVC)) begin checks++;
      if (g_io_toBpu_redirect_bits_cfiUpdate_pd_isRVC !== i_io_toBpu_redirect_bits_cfiUpdate_pd_isRVC) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_bits_cfiUpdate_pd_isRVC g=%h i=%h", $time, g_io_toBpu_redirect_bits_cfiUpdate_pd_isRVC, i_io_toBpu_redirect_bits_cfiUpdate_pd_isRVC); end end
    if (!$isunknown(g_io_toBpu_redirect_bits_cfiUpdate_pd_isCall)) begin checks++;
      if (g_io_toBpu_redirect_bits_cfiUpdate_pd_isCall !== i_io_toBpu_redirect_bits_cfiUpdate_pd_isCall) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_bits_cfiUpdate_pd_isCall g=%h i=%h", $time, g_io_toBpu_redirect_bits_cfiUpdate_pd_isCall, i_io_toBpu_redirect_bits_cfiUpdate_pd_isCall); end end
    if (!$isunknown(g_io_toBpu_redirect_bits_cfiUpdate_pd_isRet)) begin checks++;
      if (g_io_toBpu_redirect_bits_cfiUpdate_pd_isRet !== i_io_toBpu_redirect_bits_cfiUpdate_pd_isRet) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_bits_cfiUpdate_pd_isRet g=%h i=%h", $time, g_io_toBpu_redirect_bits_cfiUpdate_pd_isRet, i_io_toBpu_redirect_bits_cfiUpdate_pd_isRet); end end
    if (!$isunknown(g_io_toBpu_redirect_bits_cfiUpdate_ssp)) begin checks++;
      if (g_io_toBpu_redirect_bits_cfiUpdate_ssp !== i_io_toBpu_redirect_bits_cfiUpdate_ssp) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_bits_cfiUpdate_ssp g=%h i=%h", $time, g_io_toBpu_redirect_bits_cfiUpdate_ssp, i_io_toBpu_redirect_bits_cfiUpdate_ssp); end end
    if (!$isunknown(g_io_toBpu_redirect_bits_cfiUpdate_sctr)) begin checks++;
      if (g_io_toBpu_redirect_bits_cfiUpdate_sctr !== i_io_toBpu_redirect_bits_cfiUpdate_sctr) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_bits_cfiUpdate_sctr g=%h i=%h", $time, g_io_toBpu_redirect_bits_cfiUpdate_sctr, i_io_toBpu_redirect_bits_cfiUpdate_sctr); end end
    if (!$isunknown(g_io_toBpu_redirect_bits_cfiUpdate_TOSW_flag)) begin checks++;
      if (g_io_toBpu_redirect_bits_cfiUpdate_TOSW_flag !== i_io_toBpu_redirect_bits_cfiUpdate_TOSW_flag) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_bits_cfiUpdate_TOSW_flag g=%h i=%h", $time, g_io_toBpu_redirect_bits_cfiUpdate_TOSW_flag, i_io_toBpu_redirect_bits_cfiUpdate_TOSW_flag); end end
    if (!$isunknown(g_io_toBpu_redirect_bits_cfiUpdate_TOSW_value)) begin checks++;
      if (g_io_toBpu_redirect_bits_cfiUpdate_TOSW_value !== i_io_toBpu_redirect_bits_cfiUpdate_TOSW_value) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_bits_cfiUpdate_TOSW_value g=%h i=%h", $time, g_io_toBpu_redirect_bits_cfiUpdate_TOSW_value, i_io_toBpu_redirect_bits_cfiUpdate_TOSW_value); end end
    if (!$isunknown(g_io_toBpu_redirect_bits_cfiUpdate_TOSR_flag)) begin checks++;
      if (g_io_toBpu_redirect_bits_cfiUpdate_TOSR_flag !== i_io_toBpu_redirect_bits_cfiUpdate_TOSR_flag) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_bits_cfiUpdate_TOSR_flag g=%h i=%h", $time, g_io_toBpu_redirect_bits_cfiUpdate_TOSR_flag, i_io_toBpu_redirect_bits_cfiUpdate_TOSR_flag); end end
    if (!$isunknown(g_io_toBpu_redirect_bits_cfiUpdate_TOSR_value)) begin checks++;
      if (g_io_toBpu_redirect_bits_cfiUpdate_TOSR_value !== i_io_toBpu_redirect_bits_cfiUpdate_TOSR_value) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_bits_cfiUpdate_TOSR_value g=%h i=%h", $time, g_io_toBpu_redirect_bits_cfiUpdate_TOSR_value, i_io_toBpu_redirect_bits_cfiUpdate_TOSR_value); end end
    if (!$isunknown(g_io_toBpu_redirect_bits_cfiUpdate_NOS_flag)) begin checks++;
      if (g_io_toBpu_redirect_bits_cfiUpdate_NOS_flag !== i_io_toBpu_redirect_bits_cfiUpdate_NOS_flag) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_bits_cfiUpdate_NOS_flag g=%h i=%h", $time, g_io_toBpu_redirect_bits_cfiUpdate_NOS_flag, i_io_toBpu_redirect_bits_cfiUpdate_NOS_flag); end end
    if (!$isunknown(g_io_toBpu_redirect_bits_cfiUpdate_NOS_value)) begin checks++;
      if (g_io_toBpu_redirect_bits_cfiUpdate_NOS_value !== i_io_toBpu_redirect_bits_cfiUpdate_NOS_value) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_bits_cfiUpdate_NOS_value g=%h i=%h", $time, g_io_toBpu_redirect_bits_cfiUpdate_NOS_value, i_io_toBpu_redirect_bits_cfiUpdate_NOS_value); end end
    if (!$isunknown(g_io_toBpu_redirect_bits_cfiUpdate_histPtr_flag)) begin checks++;
      if (g_io_toBpu_redirect_bits_cfiUpdate_histPtr_flag !== i_io_toBpu_redirect_bits_cfiUpdate_histPtr_flag) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_bits_cfiUpdate_histPtr_flag g=%h i=%h", $time, g_io_toBpu_redirect_bits_cfiUpdate_histPtr_flag, i_io_toBpu_redirect_bits_cfiUpdate_histPtr_flag); end end
    if (!$isunknown(g_io_toBpu_redirect_bits_cfiUpdate_histPtr_value)) begin checks++;
      if (g_io_toBpu_redirect_bits_cfiUpdate_histPtr_value !== i_io_toBpu_redirect_bits_cfiUpdate_histPtr_value) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_bits_cfiUpdate_histPtr_value g=%h i=%h", $time, g_io_toBpu_redirect_bits_cfiUpdate_histPtr_value, i_io_toBpu_redirect_bits_cfiUpdate_histPtr_value); end end
    if (!$isunknown(g_io_toBpu_redirect_bits_cfiUpdate_br_hit)) begin checks++;
      if (g_io_toBpu_redirect_bits_cfiUpdate_br_hit !== i_io_toBpu_redirect_bits_cfiUpdate_br_hit) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_bits_cfiUpdate_br_hit g=%h i=%h", $time, g_io_toBpu_redirect_bits_cfiUpdate_br_hit, i_io_toBpu_redirect_bits_cfiUpdate_br_hit); end end
    if (!$isunknown(g_io_toBpu_redirect_bits_cfiUpdate_jr_hit)) begin checks++;
      if (g_io_toBpu_redirect_bits_cfiUpdate_jr_hit !== i_io_toBpu_redirect_bits_cfiUpdate_jr_hit) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_bits_cfiUpdate_jr_hit g=%h i=%h", $time, g_io_toBpu_redirect_bits_cfiUpdate_jr_hit, i_io_toBpu_redirect_bits_cfiUpdate_jr_hit); end end
    if (!$isunknown(g_io_toBpu_redirect_bits_cfiUpdate_sc_hit)) begin checks++;
      if (g_io_toBpu_redirect_bits_cfiUpdate_sc_hit !== i_io_toBpu_redirect_bits_cfiUpdate_sc_hit) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_bits_cfiUpdate_sc_hit g=%h i=%h", $time, g_io_toBpu_redirect_bits_cfiUpdate_sc_hit, i_io_toBpu_redirect_bits_cfiUpdate_sc_hit); end end
    if (!$isunknown(g_io_toBpu_redirect_bits_cfiUpdate_target)) begin checks++;
      if (g_io_toBpu_redirect_bits_cfiUpdate_target !== i_io_toBpu_redirect_bits_cfiUpdate_target) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_bits_cfiUpdate_target g=%h i=%h", $time, g_io_toBpu_redirect_bits_cfiUpdate_target, i_io_toBpu_redirect_bits_cfiUpdate_target); end end
    if (!$isunknown(g_io_toBpu_redirect_bits_cfiUpdate_taken)) begin checks++;
      if (g_io_toBpu_redirect_bits_cfiUpdate_taken !== i_io_toBpu_redirect_bits_cfiUpdate_taken) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_bits_cfiUpdate_taken g=%h i=%h", $time, g_io_toBpu_redirect_bits_cfiUpdate_taken, i_io_toBpu_redirect_bits_cfiUpdate_taken); end end
    if (!$isunknown(g_io_toBpu_redirect_bits_cfiUpdate_shift)) begin checks++;
      if (g_io_toBpu_redirect_bits_cfiUpdate_shift !== i_io_toBpu_redirect_bits_cfiUpdate_shift) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_bits_cfiUpdate_shift g=%h i=%h", $time, g_io_toBpu_redirect_bits_cfiUpdate_shift, i_io_toBpu_redirect_bits_cfiUpdate_shift); end end
    if (!$isunknown(g_io_toBpu_redirect_bits_cfiUpdate_addIntoHist)) begin checks++;
      if (g_io_toBpu_redirect_bits_cfiUpdate_addIntoHist !== i_io_toBpu_redirect_bits_cfiUpdate_addIntoHist) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_bits_cfiUpdate_addIntoHist g=%h i=%h", $time, g_io_toBpu_redirect_bits_cfiUpdate_addIntoHist, i_io_toBpu_redirect_bits_cfiUpdate_addIntoHist); end end
    if (!$isunknown(g_io_toBpu_redirect_bits_debugIsCtrl)) begin checks++;
      if (g_io_toBpu_redirect_bits_debugIsCtrl !== i_io_toBpu_redirect_bits_debugIsCtrl) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_bits_debugIsCtrl g=%h i=%h", $time, g_io_toBpu_redirect_bits_debugIsCtrl, i_io_toBpu_redirect_bits_debugIsCtrl); end end
    if (!$isunknown(g_io_toBpu_redirect_bits_debugIsMemVio)) begin checks++;
      if (g_io_toBpu_redirect_bits_debugIsMemVio !== i_io_toBpu_redirect_bits_debugIsMemVio) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_bits_debugIsMemVio g=%h i=%h", $time, g_io_toBpu_redirect_bits_debugIsMemVio, i_io_toBpu_redirect_bits_debugIsMemVio); end end
    if (!$isunknown(g_io_toBpu_redirect_bits_BTBMissBubble)) begin checks++;
      if (g_io_toBpu_redirect_bits_BTBMissBubble !== i_io_toBpu_redirect_bits_BTBMissBubble) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirect_bits_BTBMissBubble g=%h i=%h", $time, g_io_toBpu_redirect_bits_BTBMissBubble, i_io_toBpu_redirect_bits_BTBMissBubble); end end
    if (!$isunknown(g_io_toBpu_update_valid)) begin checks++;
      if (g_io_toBpu_update_valid !== i_io_toBpu_update_valid) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_valid g=%h i=%h", $time, g_io_toBpu_update_valid, i_io_toBpu_update_valid); end end
    if (!$isunknown(g_io_toBpu_update_bits_pc)) begin checks++;
      if (g_io_toBpu_update_bits_pc !== i_io_toBpu_update_bits_pc) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_pc g=%h i=%h", $time, g_io_toBpu_update_bits_pc, i_io_toBpu_update_bits_pc); end end
    if (!$isunknown(g_io_toBpu_update_bits_spec_info_histPtr_value)) begin checks++;
      if (g_io_toBpu_update_bits_spec_info_histPtr_value !== i_io_toBpu_update_bits_spec_info_histPtr_value) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_spec_info_histPtr_value g=%h i=%h", $time, g_io_toBpu_update_bits_spec_info_histPtr_value, i_io_toBpu_update_bits_spec_info_histPtr_value); end end
    if (!$isunknown(g_io_toBpu_update_bits_ftb_entry_isCall)) begin checks++;
      if (g_io_toBpu_update_bits_ftb_entry_isCall !== i_io_toBpu_update_bits_ftb_entry_isCall) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_ftb_entry_isCall g=%h i=%h", $time, g_io_toBpu_update_bits_ftb_entry_isCall, i_io_toBpu_update_bits_ftb_entry_isCall); end end
    if (!$isunknown(g_io_toBpu_update_bits_ftb_entry_isRet)) begin checks++;
      if (g_io_toBpu_update_bits_ftb_entry_isRet !== i_io_toBpu_update_bits_ftb_entry_isRet) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_ftb_entry_isRet g=%h i=%h", $time, g_io_toBpu_update_bits_ftb_entry_isRet, i_io_toBpu_update_bits_ftb_entry_isRet); end end
    if (!$isunknown(g_io_toBpu_update_bits_ftb_entry_isJalr)) begin checks++;
      if (g_io_toBpu_update_bits_ftb_entry_isJalr !== i_io_toBpu_update_bits_ftb_entry_isJalr) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_ftb_entry_isJalr g=%h i=%h", $time, g_io_toBpu_update_bits_ftb_entry_isJalr, i_io_toBpu_update_bits_ftb_entry_isJalr); end end
    if (!$isunknown(g_io_toBpu_update_bits_ftb_entry_valid)) begin checks++;
      if (g_io_toBpu_update_bits_ftb_entry_valid !== i_io_toBpu_update_bits_ftb_entry_valid) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_ftb_entry_valid g=%h i=%h", $time, g_io_toBpu_update_bits_ftb_entry_valid, i_io_toBpu_update_bits_ftb_entry_valid); end end
    if (!$isunknown(g_io_toBpu_update_bits_ftb_entry_brSlots_0_offset)) begin checks++;
      if (g_io_toBpu_update_bits_ftb_entry_brSlots_0_offset !== i_io_toBpu_update_bits_ftb_entry_brSlots_0_offset) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_ftb_entry_brSlots_0_offset g=%h i=%h", $time, g_io_toBpu_update_bits_ftb_entry_brSlots_0_offset, i_io_toBpu_update_bits_ftb_entry_brSlots_0_offset); end end
    if (!$isunknown(g_io_toBpu_update_bits_ftb_entry_brSlots_0_sharing)) begin checks++;
      if (g_io_toBpu_update_bits_ftb_entry_brSlots_0_sharing !== i_io_toBpu_update_bits_ftb_entry_brSlots_0_sharing) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_ftb_entry_brSlots_0_sharing g=%h i=%h", $time, g_io_toBpu_update_bits_ftb_entry_brSlots_0_sharing, i_io_toBpu_update_bits_ftb_entry_brSlots_0_sharing); end end
    if (!$isunknown(g_io_toBpu_update_bits_ftb_entry_brSlots_0_valid)) begin checks++;
      if (g_io_toBpu_update_bits_ftb_entry_brSlots_0_valid !== i_io_toBpu_update_bits_ftb_entry_brSlots_0_valid) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_ftb_entry_brSlots_0_valid g=%h i=%h", $time, g_io_toBpu_update_bits_ftb_entry_brSlots_0_valid, i_io_toBpu_update_bits_ftb_entry_brSlots_0_valid); end end
    if (!$isunknown(g_io_toBpu_update_bits_ftb_entry_brSlots_0_lower)) begin checks++;
      if (g_io_toBpu_update_bits_ftb_entry_brSlots_0_lower !== i_io_toBpu_update_bits_ftb_entry_brSlots_0_lower) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_ftb_entry_brSlots_0_lower g=%h i=%h", $time, g_io_toBpu_update_bits_ftb_entry_brSlots_0_lower, i_io_toBpu_update_bits_ftb_entry_brSlots_0_lower); end end
    if (!$isunknown(g_io_toBpu_update_bits_ftb_entry_brSlots_0_tarStat)) begin checks++;
      if (g_io_toBpu_update_bits_ftb_entry_brSlots_0_tarStat !== i_io_toBpu_update_bits_ftb_entry_brSlots_0_tarStat) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_ftb_entry_brSlots_0_tarStat g=%h i=%h", $time, g_io_toBpu_update_bits_ftb_entry_brSlots_0_tarStat, i_io_toBpu_update_bits_ftb_entry_brSlots_0_tarStat); end end
    if (!$isunknown(g_io_toBpu_update_bits_ftb_entry_tailSlot_offset)) begin checks++;
      if (g_io_toBpu_update_bits_ftb_entry_tailSlot_offset !== i_io_toBpu_update_bits_ftb_entry_tailSlot_offset) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_ftb_entry_tailSlot_offset g=%h i=%h", $time, g_io_toBpu_update_bits_ftb_entry_tailSlot_offset, i_io_toBpu_update_bits_ftb_entry_tailSlot_offset); end end
    if (!$isunknown(g_io_toBpu_update_bits_ftb_entry_tailSlot_sharing)) begin checks++;
      if (g_io_toBpu_update_bits_ftb_entry_tailSlot_sharing !== i_io_toBpu_update_bits_ftb_entry_tailSlot_sharing) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_ftb_entry_tailSlot_sharing g=%h i=%h", $time, g_io_toBpu_update_bits_ftb_entry_tailSlot_sharing, i_io_toBpu_update_bits_ftb_entry_tailSlot_sharing); end end
    if (!$isunknown(g_io_toBpu_update_bits_ftb_entry_tailSlot_valid)) begin checks++;
      if (g_io_toBpu_update_bits_ftb_entry_tailSlot_valid !== i_io_toBpu_update_bits_ftb_entry_tailSlot_valid) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_ftb_entry_tailSlot_valid g=%h i=%h", $time, g_io_toBpu_update_bits_ftb_entry_tailSlot_valid, i_io_toBpu_update_bits_ftb_entry_tailSlot_valid); end end
    if (!$isunknown(g_io_toBpu_update_bits_ftb_entry_tailSlot_lower)) begin checks++;
      if (g_io_toBpu_update_bits_ftb_entry_tailSlot_lower !== i_io_toBpu_update_bits_ftb_entry_tailSlot_lower) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_ftb_entry_tailSlot_lower g=%h i=%h", $time, g_io_toBpu_update_bits_ftb_entry_tailSlot_lower, i_io_toBpu_update_bits_ftb_entry_tailSlot_lower); end end
    if (!$isunknown(g_io_toBpu_update_bits_ftb_entry_tailSlot_tarStat)) begin checks++;
      if (g_io_toBpu_update_bits_ftb_entry_tailSlot_tarStat !== i_io_toBpu_update_bits_ftb_entry_tailSlot_tarStat) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_ftb_entry_tailSlot_tarStat g=%h i=%h", $time, g_io_toBpu_update_bits_ftb_entry_tailSlot_tarStat, i_io_toBpu_update_bits_ftb_entry_tailSlot_tarStat); end end
    if (!$isunknown(g_io_toBpu_update_bits_ftb_entry_pftAddr)) begin checks++;
      if (g_io_toBpu_update_bits_ftb_entry_pftAddr !== i_io_toBpu_update_bits_ftb_entry_pftAddr) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_ftb_entry_pftAddr g=%h i=%h", $time, g_io_toBpu_update_bits_ftb_entry_pftAddr, i_io_toBpu_update_bits_ftb_entry_pftAddr); end end
    if (!$isunknown(g_io_toBpu_update_bits_ftb_entry_carry)) begin checks++;
      if (g_io_toBpu_update_bits_ftb_entry_carry !== i_io_toBpu_update_bits_ftb_entry_carry) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_ftb_entry_carry g=%h i=%h", $time, g_io_toBpu_update_bits_ftb_entry_carry, i_io_toBpu_update_bits_ftb_entry_carry); end end
    if (!$isunknown(g_io_toBpu_update_bits_ftb_entry_last_may_be_rvi_call)) begin checks++;
      if (g_io_toBpu_update_bits_ftb_entry_last_may_be_rvi_call !== i_io_toBpu_update_bits_ftb_entry_last_may_be_rvi_call) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_ftb_entry_last_may_be_rvi_call g=%h i=%h", $time, g_io_toBpu_update_bits_ftb_entry_last_may_be_rvi_call, i_io_toBpu_update_bits_ftb_entry_last_may_be_rvi_call); end end
    if (!$isunknown(g_io_toBpu_update_bits_ftb_entry_strong_bias_0)) begin checks++;
      if (g_io_toBpu_update_bits_ftb_entry_strong_bias_0 !== i_io_toBpu_update_bits_ftb_entry_strong_bias_0) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_ftb_entry_strong_bias_0 g=%h i=%h", $time, g_io_toBpu_update_bits_ftb_entry_strong_bias_0, i_io_toBpu_update_bits_ftb_entry_strong_bias_0); end end
    if (!$isunknown(g_io_toBpu_update_bits_ftb_entry_strong_bias_1)) begin checks++;
      if (g_io_toBpu_update_bits_ftb_entry_strong_bias_1 !== i_io_toBpu_update_bits_ftb_entry_strong_bias_1) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_ftb_entry_strong_bias_1 g=%h i=%h", $time, g_io_toBpu_update_bits_ftb_entry_strong_bias_1, i_io_toBpu_update_bits_ftb_entry_strong_bias_1); end end
    if (!$isunknown(g_io_toBpu_update_bits_cfi_idx_valid)) begin checks++;
      if (g_io_toBpu_update_bits_cfi_idx_valid !== i_io_toBpu_update_bits_cfi_idx_valid) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_cfi_idx_valid g=%h i=%h", $time, g_io_toBpu_update_bits_cfi_idx_valid, i_io_toBpu_update_bits_cfi_idx_valid); end end
    if (!$isunknown(g_io_toBpu_update_bits_cfi_idx_bits)) begin checks++;
      if (g_io_toBpu_update_bits_cfi_idx_bits !== i_io_toBpu_update_bits_cfi_idx_bits) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_cfi_idx_bits g=%h i=%h", $time, g_io_toBpu_update_bits_cfi_idx_bits, i_io_toBpu_update_bits_cfi_idx_bits); end end
    if (!$isunknown(g_io_toBpu_update_bits_br_taken_mask_0)) begin checks++;
      if (g_io_toBpu_update_bits_br_taken_mask_0 !== i_io_toBpu_update_bits_br_taken_mask_0) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_br_taken_mask_0 g=%h i=%h", $time, g_io_toBpu_update_bits_br_taken_mask_0, i_io_toBpu_update_bits_br_taken_mask_0); end end
    if (!$isunknown(g_io_toBpu_update_bits_br_taken_mask_1)) begin checks++;
      if (g_io_toBpu_update_bits_br_taken_mask_1 !== i_io_toBpu_update_bits_br_taken_mask_1) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_br_taken_mask_1 g=%h i=%h", $time, g_io_toBpu_update_bits_br_taken_mask_1, i_io_toBpu_update_bits_br_taken_mask_1); end end
    if (!$isunknown(g_io_toBpu_update_bits_jmp_taken)) begin checks++;
      if (g_io_toBpu_update_bits_jmp_taken !== i_io_toBpu_update_bits_jmp_taken) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_jmp_taken g=%h i=%h", $time, g_io_toBpu_update_bits_jmp_taken, i_io_toBpu_update_bits_jmp_taken); end end
    if (!$isunknown(g_io_toBpu_update_bits_mispred_mask_0)) begin checks++;
      if (g_io_toBpu_update_bits_mispred_mask_0 !== i_io_toBpu_update_bits_mispred_mask_0) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_mispred_mask_0 g=%h i=%h", $time, g_io_toBpu_update_bits_mispred_mask_0, i_io_toBpu_update_bits_mispred_mask_0); end end
    if (!$isunknown(g_io_toBpu_update_bits_mispred_mask_1)) begin checks++;
      if (g_io_toBpu_update_bits_mispred_mask_1 !== i_io_toBpu_update_bits_mispred_mask_1) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_mispred_mask_1 g=%h i=%h", $time, g_io_toBpu_update_bits_mispred_mask_1, i_io_toBpu_update_bits_mispred_mask_1); end end
    if (!$isunknown(g_io_toBpu_update_bits_mispred_mask_2)) begin checks++;
      if (g_io_toBpu_update_bits_mispred_mask_2 !== i_io_toBpu_update_bits_mispred_mask_2) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_mispred_mask_2 g=%h i=%h", $time, g_io_toBpu_update_bits_mispred_mask_2, i_io_toBpu_update_bits_mispred_mask_2); end end
    if (!$isunknown(g_io_toBpu_update_bits_false_hit)) begin checks++;
      if (g_io_toBpu_update_bits_false_hit !== i_io_toBpu_update_bits_false_hit) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_false_hit g=%h i=%h", $time, g_io_toBpu_update_bits_false_hit, i_io_toBpu_update_bits_false_hit); end end
    if (!$isunknown(g_io_toBpu_update_bits_old_entry)) begin checks++;
      if (g_io_toBpu_update_bits_old_entry !== i_io_toBpu_update_bits_old_entry) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_old_entry g=%h i=%h", $time, g_io_toBpu_update_bits_old_entry, i_io_toBpu_update_bits_old_entry); end end
    if (!$isunknown(g_io_toBpu_update_bits_meta)) begin checks++;
      if (g_io_toBpu_update_bits_meta !== i_io_toBpu_update_bits_meta) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_meta g=%h i=%h", $time, g_io_toBpu_update_bits_meta, i_io_toBpu_update_bits_meta); end end
    if (!$isunknown(g_io_toBpu_update_bits_full_target)) begin checks++;
      if (g_io_toBpu_update_bits_full_target !== i_io_toBpu_update_bits_full_target) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_update_bits_full_target g=%h i=%h", $time, g_io_toBpu_update_bits_full_target, i_io_toBpu_update_bits_full_target); end end
    if (!$isunknown(g_io_toBpu_enq_ptr_flag)) begin checks++;
      if (g_io_toBpu_enq_ptr_flag !== i_io_toBpu_enq_ptr_flag) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_enq_ptr_flag g=%h i=%h", $time, g_io_toBpu_enq_ptr_flag, i_io_toBpu_enq_ptr_flag); end end
    if (!$isunknown(g_io_toBpu_enq_ptr_value)) begin checks++;
      if (g_io_toBpu_enq_ptr_value !== i_io_toBpu_enq_ptr_value) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_enq_ptr_value g=%h i=%h", $time, g_io_toBpu_enq_ptr_value, i_io_toBpu_enq_ptr_value); end end
    if (!$isunknown(g_io_toBpu_redirctFromIFU)) begin checks++;
      if (g_io_toBpu_redirctFromIFU !== i_io_toBpu_redirctFromIFU) begin errors++;
        if (errors<=60) $display("[%0t] io_toBpu_redirctFromIFU g=%h i=%h", $time, g_io_toBpu_redirctFromIFU, i_io_toBpu_redirctFromIFU); end end
    if (!$isunknown(g_io_toIfu_req_valid)) begin checks++;
      if (g_io_toIfu_req_valid !== i_io_toIfu_req_valid) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_valid g=%h i=%h", $time, g_io_toIfu_req_valid, i_io_toIfu_req_valid); end end
    if (!$isunknown(g_io_toIfu_req_bits_startAddr)) begin checks++;
      if (g_io_toIfu_req_bits_startAddr !== i_io_toIfu_req_bits_startAddr) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_startAddr g=%h i=%h", $time, g_io_toIfu_req_bits_startAddr, i_io_toIfu_req_bits_startAddr); end end
    if (!$isunknown(g_io_toIfu_req_bits_nextlineStart)) begin checks++;
      if (g_io_toIfu_req_bits_nextlineStart !== i_io_toIfu_req_bits_nextlineStart) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_nextlineStart g=%h i=%h", $time, g_io_toIfu_req_bits_nextlineStart, i_io_toIfu_req_bits_nextlineStart); end end
    if (!$isunknown(g_io_toIfu_req_bits_nextStartAddr)) begin checks++;
      if (g_io_toIfu_req_bits_nextStartAddr !== i_io_toIfu_req_bits_nextStartAddr) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_nextStartAddr g=%h i=%h", $time, g_io_toIfu_req_bits_nextStartAddr, i_io_toIfu_req_bits_nextStartAddr); end end
    if (!$isunknown(g_io_toIfu_req_bits_ftqIdx_flag)) begin checks++;
      if (g_io_toIfu_req_bits_ftqIdx_flag !== i_io_toIfu_req_bits_ftqIdx_flag) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_ftqIdx_flag g=%h i=%h", $time, g_io_toIfu_req_bits_ftqIdx_flag, i_io_toIfu_req_bits_ftqIdx_flag); end end
    if (!$isunknown(g_io_toIfu_req_bits_ftqIdx_value)) begin checks++;
      if (g_io_toIfu_req_bits_ftqIdx_value !== i_io_toIfu_req_bits_ftqIdx_value) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_ftqIdx_value g=%h i=%h", $time, g_io_toIfu_req_bits_ftqIdx_value, i_io_toIfu_req_bits_ftqIdx_value); end end
    if (!$isunknown(g_io_toIfu_req_bits_ftqOffset_valid)) begin checks++;
      if (g_io_toIfu_req_bits_ftqOffset_valid !== i_io_toIfu_req_bits_ftqOffset_valid) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_ftqOffset_valid g=%h i=%h", $time, g_io_toIfu_req_bits_ftqOffset_valid, i_io_toIfu_req_bits_ftqOffset_valid); end end
    if (!$isunknown(g_io_toIfu_req_bits_ftqOffset_bits)) begin checks++;
      if (g_io_toIfu_req_bits_ftqOffset_bits !== i_io_toIfu_req_bits_ftqOffset_bits) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_ftqOffset_bits g=%h i=%h", $time, g_io_toIfu_req_bits_ftqOffset_bits, i_io_toIfu_req_bits_ftqOffset_bits); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_0)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_0 !== i_io_toIfu_req_bits_topdown_info_reasons_0) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_0 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_0, i_io_toIfu_req_bits_topdown_info_reasons_0); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_1)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_1 !== i_io_toIfu_req_bits_topdown_info_reasons_1) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_1 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_1, i_io_toIfu_req_bits_topdown_info_reasons_1); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_2)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_2 !== i_io_toIfu_req_bits_topdown_info_reasons_2) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_2 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_2, i_io_toIfu_req_bits_topdown_info_reasons_2); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_3)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_3 !== i_io_toIfu_req_bits_topdown_info_reasons_3) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_3 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_3, i_io_toIfu_req_bits_topdown_info_reasons_3); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_4)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_4 !== i_io_toIfu_req_bits_topdown_info_reasons_4) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_4 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_4, i_io_toIfu_req_bits_topdown_info_reasons_4); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_5)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_5 !== i_io_toIfu_req_bits_topdown_info_reasons_5) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_5 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_5, i_io_toIfu_req_bits_topdown_info_reasons_5); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_6)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_6 !== i_io_toIfu_req_bits_topdown_info_reasons_6) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_6 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_6, i_io_toIfu_req_bits_topdown_info_reasons_6); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_7)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_7 !== i_io_toIfu_req_bits_topdown_info_reasons_7) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_7 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_7, i_io_toIfu_req_bits_topdown_info_reasons_7); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_8)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_8 !== i_io_toIfu_req_bits_topdown_info_reasons_8) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_8 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_8, i_io_toIfu_req_bits_topdown_info_reasons_8); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_9)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_9 !== i_io_toIfu_req_bits_topdown_info_reasons_9) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_9 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_9, i_io_toIfu_req_bits_topdown_info_reasons_9); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_10)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_10 !== i_io_toIfu_req_bits_topdown_info_reasons_10) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_10 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_10, i_io_toIfu_req_bits_topdown_info_reasons_10); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_11)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_11 !== i_io_toIfu_req_bits_topdown_info_reasons_11) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_11 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_11, i_io_toIfu_req_bits_topdown_info_reasons_11); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_12)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_12 !== i_io_toIfu_req_bits_topdown_info_reasons_12) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_12 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_12, i_io_toIfu_req_bits_topdown_info_reasons_12); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_13)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_13 !== i_io_toIfu_req_bits_topdown_info_reasons_13) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_13 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_13, i_io_toIfu_req_bits_topdown_info_reasons_13); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_14)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_14 !== i_io_toIfu_req_bits_topdown_info_reasons_14) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_14 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_14, i_io_toIfu_req_bits_topdown_info_reasons_14); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_15)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_15 !== i_io_toIfu_req_bits_topdown_info_reasons_15) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_15 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_15, i_io_toIfu_req_bits_topdown_info_reasons_15); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_16)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_16 !== i_io_toIfu_req_bits_topdown_info_reasons_16) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_16 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_16, i_io_toIfu_req_bits_topdown_info_reasons_16); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_17)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_17 !== i_io_toIfu_req_bits_topdown_info_reasons_17) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_17 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_17, i_io_toIfu_req_bits_topdown_info_reasons_17); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_18)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_18 !== i_io_toIfu_req_bits_topdown_info_reasons_18) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_18 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_18, i_io_toIfu_req_bits_topdown_info_reasons_18); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_19)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_19 !== i_io_toIfu_req_bits_topdown_info_reasons_19) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_19 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_19, i_io_toIfu_req_bits_topdown_info_reasons_19); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_20)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_20 !== i_io_toIfu_req_bits_topdown_info_reasons_20) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_20 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_20, i_io_toIfu_req_bits_topdown_info_reasons_20); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_21)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_21 !== i_io_toIfu_req_bits_topdown_info_reasons_21) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_21 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_21, i_io_toIfu_req_bits_topdown_info_reasons_21); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_22)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_22 !== i_io_toIfu_req_bits_topdown_info_reasons_22) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_22 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_22, i_io_toIfu_req_bits_topdown_info_reasons_22); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_23)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_23 !== i_io_toIfu_req_bits_topdown_info_reasons_23) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_23 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_23, i_io_toIfu_req_bits_topdown_info_reasons_23); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_24)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_24 !== i_io_toIfu_req_bits_topdown_info_reasons_24) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_24 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_24, i_io_toIfu_req_bits_topdown_info_reasons_24); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_25)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_25 !== i_io_toIfu_req_bits_topdown_info_reasons_25) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_25 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_25, i_io_toIfu_req_bits_topdown_info_reasons_25); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_26)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_26 !== i_io_toIfu_req_bits_topdown_info_reasons_26) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_26 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_26, i_io_toIfu_req_bits_topdown_info_reasons_26); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_27)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_27 !== i_io_toIfu_req_bits_topdown_info_reasons_27) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_27 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_27, i_io_toIfu_req_bits_topdown_info_reasons_27); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_28)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_28 !== i_io_toIfu_req_bits_topdown_info_reasons_28) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_28 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_28, i_io_toIfu_req_bits_topdown_info_reasons_28); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_29)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_29 !== i_io_toIfu_req_bits_topdown_info_reasons_29) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_29 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_29, i_io_toIfu_req_bits_topdown_info_reasons_29); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_30)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_30 !== i_io_toIfu_req_bits_topdown_info_reasons_30) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_30 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_30, i_io_toIfu_req_bits_topdown_info_reasons_30); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_31)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_31 !== i_io_toIfu_req_bits_topdown_info_reasons_31) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_31 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_31, i_io_toIfu_req_bits_topdown_info_reasons_31); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_32)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_32 !== i_io_toIfu_req_bits_topdown_info_reasons_32) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_32 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_32, i_io_toIfu_req_bits_topdown_info_reasons_32); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_33)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_33 !== i_io_toIfu_req_bits_topdown_info_reasons_33) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_33 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_33, i_io_toIfu_req_bits_topdown_info_reasons_33); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_34)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_34 !== i_io_toIfu_req_bits_topdown_info_reasons_34) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_34 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_34, i_io_toIfu_req_bits_topdown_info_reasons_34); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_35)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_35 !== i_io_toIfu_req_bits_topdown_info_reasons_35) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_35 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_35, i_io_toIfu_req_bits_topdown_info_reasons_35); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_36)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_36 !== i_io_toIfu_req_bits_topdown_info_reasons_36) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_36 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_36, i_io_toIfu_req_bits_topdown_info_reasons_36); end end
    if (!$isunknown(g_io_toIfu_req_bits_topdown_info_reasons_37)) begin checks++;
      if (g_io_toIfu_req_bits_topdown_info_reasons_37 !== i_io_toIfu_req_bits_topdown_info_reasons_37) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_req_bits_topdown_info_reasons_37 g=%h i=%h", $time, g_io_toIfu_req_bits_topdown_info_reasons_37, i_io_toIfu_req_bits_topdown_info_reasons_37); end end
    if (!$isunknown(g_io_toIfu_redirect_valid)) begin checks++;
      if (g_io_toIfu_redirect_valid !== i_io_toIfu_redirect_valid) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_redirect_valid g=%h i=%h", $time, g_io_toIfu_redirect_valid, i_io_toIfu_redirect_valid); end end
    if (!$isunknown(g_io_toIfu_redirect_bits_ftqIdx_flag)) begin checks++;
      if (g_io_toIfu_redirect_bits_ftqIdx_flag !== i_io_toIfu_redirect_bits_ftqIdx_flag) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_redirect_bits_ftqIdx_flag g=%h i=%h", $time, g_io_toIfu_redirect_bits_ftqIdx_flag, i_io_toIfu_redirect_bits_ftqIdx_flag); end end
    if (!$isunknown(g_io_toIfu_redirect_bits_ftqIdx_value)) begin checks++;
      if (g_io_toIfu_redirect_bits_ftqIdx_value !== i_io_toIfu_redirect_bits_ftqIdx_value) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_redirect_bits_ftqIdx_value g=%h i=%h", $time, g_io_toIfu_redirect_bits_ftqIdx_value, i_io_toIfu_redirect_bits_ftqIdx_value); end end
    if (!$isunknown(g_io_toIfu_redirect_bits_ftqOffset)) begin checks++;
      if (g_io_toIfu_redirect_bits_ftqOffset !== i_io_toIfu_redirect_bits_ftqOffset) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_redirect_bits_ftqOffset g=%h i=%h", $time, g_io_toIfu_redirect_bits_ftqOffset, i_io_toIfu_redirect_bits_ftqOffset); end end
    if (!$isunknown(g_io_toIfu_redirect_bits_level)) begin checks++;
      if (g_io_toIfu_redirect_bits_level !== i_io_toIfu_redirect_bits_level) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_redirect_bits_level g=%h i=%h", $time, g_io_toIfu_redirect_bits_level, i_io_toIfu_redirect_bits_level); end end
    if (!$isunknown(g_io_toIfu_topdown_redirect_valid)) begin checks++;
      if (g_io_toIfu_topdown_redirect_valid !== i_io_toIfu_topdown_redirect_valid) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_topdown_redirect_valid g=%h i=%h", $time, g_io_toIfu_topdown_redirect_valid, i_io_toIfu_topdown_redirect_valid); end end
    if (!$isunknown(g_io_toIfu_topdown_redirect_bits_cfiUpdate_pd_isRet)) begin checks++;
      if (g_io_toIfu_topdown_redirect_bits_cfiUpdate_pd_isRet !== i_io_toIfu_topdown_redirect_bits_cfiUpdate_pd_isRet) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_topdown_redirect_bits_cfiUpdate_pd_isRet g=%h i=%h", $time, g_io_toIfu_topdown_redirect_bits_cfiUpdate_pd_isRet, i_io_toIfu_topdown_redirect_bits_cfiUpdate_pd_isRet); end end
    if (!$isunknown(g_io_toIfu_topdown_redirect_bits_cfiUpdate_br_hit)) begin checks++;
      if (g_io_toIfu_topdown_redirect_bits_cfiUpdate_br_hit !== i_io_toIfu_topdown_redirect_bits_cfiUpdate_br_hit) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_topdown_redirect_bits_cfiUpdate_br_hit g=%h i=%h", $time, g_io_toIfu_topdown_redirect_bits_cfiUpdate_br_hit, i_io_toIfu_topdown_redirect_bits_cfiUpdate_br_hit); end end
    if (!$isunknown(g_io_toIfu_topdown_redirect_bits_cfiUpdate_jr_hit)) begin checks++;
      if (g_io_toIfu_topdown_redirect_bits_cfiUpdate_jr_hit !== i_io_toIfu_topdown_redirect_bits_cfiUpdate_jr_hit) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_topdown_redirect_bits_cfiUpdate_jr_hit g=%h i=%h", $time, g_io_toIfu_topdown_redirect_bits_cfiUpdate_jr_hit, i_io_toIfu_topdown_redirect_bits_cfiUpdate_jr_hit); end end
    if (!$isunknown(g_io_toIfu_topdown_redirect_bits_cfiUpdate_sc_hit)) begin checks++;
      if (g_io_toIfu_topdown_redirect_bits_cfiUpdate_sc_hit !== i_io_toIfu_topdown_redirect_bits_cfiUpdate_sc_hit) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_topdown_redirect_bits_cfiUpdate_sc_hit g=%h i=%h", $time, g_io_toIfu_topdown_redirect_bits_cfiUpdate_sc_hit, i_io_toIfu_topdown_redirect_bits_cfiUpdate_sc_hit); end end
    if (!$isunknown(g_io_toIfu_topdown_redirect_bits_debugIsCtrl)) begin checks++;
      if (g_io_toIfu_topdown_redirect_bits_debugIsCtrl !== i_io_toIfu_topdown_redirect_bits_debugIsCtrl) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_topdown_redirect_bits_debugIsCtrl g=%h i=%h", $time, g_io_toIfu_topdown_redirect_bits_debugIsCtrl, i_io_toIfu_topdown_redirect_bits_debugIsCtrl); end end
    if (!$isunknown(g_io_toIfu_topdown_redirect_bits_debugIsMemVio)) begin checks++;
      if (g_io_toIfu_topdown_redirect_bits_debugIsMemVio !== i_io_toIfu_topdown_redirect_bits_debugIsMemVio) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_topdown_redirect_bits_debugIsMemVio g=%h i=%h", $time, g_io_toIfu_topdown_redirect_bits_debugIsMemVio, i_io_toIfu_topdown_redirect_bits_debugIsMemVio); end end
    if (!$isunknown(g_io_toIfu_flushFromBpu_s2_valid)) begin checks++;
      if (g_io_toIfu_flushFromBpu_s2_valid !== i_io_toIfu_flushFromBpu_s2_valid) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_flushFromBpu_s2_valid g=%h i=%h", $time, g_io_toIfu_flushFromBpu_s2_valid, i_io_toIfu_flushFromBpu_s2_valid); end end
    if (!$isunknown(g_io_toIfu_flushFromBpu_s2_bits_flag)) begin checks++;
      if (g_io_toIfu_flushFromBpu_s2_bits_flag !== i_io_toIfu_flushFromBpu_s2_bits_flag) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_flushFromBpu_s2_bits_flag g=%h i=%h", $time, g_io_toIfu_flushFromBpu_s2_bits_flag, i_io_toIfu_flushFromBpu_s2_bits_flag); end end
    if (!$isunknown(g_io_toIfu_flushFromBpu_s2_bits_value)) begin checks++;
      if (g_io_toIfu_flushFromBpu_s2_bits_value !== i_io_toIfu_flushFromBpu_s2_bits_value) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_flushFromBpu_s2_bits_value g=%h i=%h", $time, g_io_toIfu_flushFromBpu_s2_bits_value, i_io_toIfu_flushFromBpu_s2_bits_value); end end
    if (!$isunknown(g_io_toIfu_flushFromBpu_s3_valid)) begin checks++;
      if (g_io_toIfu_flushFromBpu_s3_valid !== i_io_toIfu_flushFromBpu_s3_valid) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_flushFromBpu_s3_valid g=%h i=%h", $time, g_io_toIfu_flushFromBpu_s3_valid, i_io_toIfu_flushFromBpu_s3_valid); end end
    if (!$isunknown(g_io_toIfu_flushFromBpu_s3_bits_flag)) begin checks++;
      if (g_io_toIfu_flushFromBpu_s3_bits_flag !== i_io_toIfu_flushFromBpu_s3_bits_flag) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_flushFromBpu_s3_bits_flag g=%h i=%h", $time, g_io_toIfu_flushFromBpu_s3_bits_flag, i_io_toIfu_flushFromBpu_s3_bits_flag); end end
    if (!$isunknown(g_io_toIfu_flushFromBpu_s3_bits_value)) begin checks++;
      if (g_io_toIfu_flushFromBpu_s3_bits_value !== i_io_toIfu_flushFromBpu_s3_bits_value) begin errors++;
        if (errors<=60) $display("[%0t] io_toIfu_flushFromBpu_s3_bits_value g=%h i=%h", $time, g_io_toIfu_flushFromBpu_s3_bits_value, i_io_toIfu_flushFromBpu_s3_bits_value); end end
    if (!$isunknown(g_io_toICache_req_valid)) begin checks++;
      if (g_io_toICache_req_valid !== i_io_toICache_req_valid) begin errors++;
        if (errors<=60) $display("[%0t] io_toICache_req_valid g=%h i=%h", $time, g_io_toICache_req_valid, i_io_toICache_req_valid); end end
    if (!$isunknown(g_io_toICache_req_bits_pcMemRead_0_startAddr)) begin checks++;
      if (g_io_toICache_req_bits_pcMemRead_0_startAddr !== i_io_toICache_req_bits_pcMemRead_0_startAddr) begin errors++;
        if (errors<=60) $display("[%0t] io_toICache_req_bits_pcMemRead_0_startAddr g=%h i=%h", $time, g_io_toICache_req_bits_pcMemRead_0_startAddr, i_io_toICache_req_bits_pcMemRead_0_startAddr); end end
    if (!$isunknown(g_io_toICache_req_bits_pcMemRead_0_nextlineStart)) begin checks++;
      if (g_io_toICache_req_bits_pcMemRead_0_nextlineStart !== i_io_toICache_req_bits_pcMemRead_0_nextlineStart) begin errors++;
        if (errors<=60) $display("[%0t] io_toICache_req_bits_pcMemRead_0_nextlineStart g=%h i=%h", $time, g_io_toICache_req_bits_pcMemRead_0_nextlineStart, i_io_toICache_req_bits_pcMemRead_0_nextlineStart); end end
    if (!$isunknown(g_io_toICache_req_bits_pcMemRead_1_startAddr)) begin checks++;
      if (g_io_toICache_req_bits_pcMemRead_1_startAddr !== i_io_toICache_req_bits_pcMemRead_1_startAddr) begin errors++;
        if (errors<=60) $display("[%0t] io_toICache_req_bits_pcMemRead_1_startAddr g=%h i=%h", $time, g_io_toICache_req_bits_pcMemRead_1_startAddr, i_io_toICache_req_bits_pcMemRead_1_startAddr); end end
    if (!$isunknown(g_io_toICache_req_bits_pcMemRead_1_nextlineStart)) begin checks++;
      if (g_io_toICache_req_bits_pcMemRead_1_nextlineStart !== i_io_toICache_req_bits_pcMemRead_1_nextlineStart) begin errors++;
        if (errors<=60) $display("[%0t] io_toICache_req_bits_pcMemRead_1_nextlineStart g=%h i=%h", $time, g_io_toICache_req_bits_pcMemRead_1_nextlineStart, i_io_toICache_req_bits_pcMemRead_1_nextlineStart); end end
    if (!$isunknown(g_io_toICache_req_bits_pcMemRead_2_startAddr)) begin checks++;
      if (g_io_toICache_req_bits_pcMemRead_2_startAddr !== i_io_toICache_req_bits_pcMemRead_2_startAddr) begin errors++;
        if (errors<=60) $display("[%0t] io_toICache_req_bits_pcMemRead_2_startAddr g=%h i=%h", $time, g_io_toICache_req_bits_pcMemRead_2_startAddr, i_io_toICache_req_bits_pcMemRead_2_startAddr); end end
    if (!$isunknown(g_io_toICache_req_bits_pcMemRead_2_nextlineStart)) begin checks++;
      if (g_io_toICache_req_bits_pcMemRead_2_nextlineStart !== i_io_toICache_req_bits_pcMemRead_2_nextlineStart) begin errors++;
        if (errors<=60) $display("[%0t] io_toICache_req_bits_pcMemRead_2_nextlineStart g=%h i=%h", $time, g_io_toICache_req_bits_pcMemRead_2_nextlineStart, i_io_toICache_req_bits_pcMemRead_2_nextlineStart); end end
    if (!$isunknown(g_io_toICache_req_bits_pcMemRead_3_startAddr)) begin checks++;
      if (g_io_toICache_req_bits_pcMemRead_3_startAddr !== i_io_toICache_req_bits_pcMemRead_3_startAddr) begin errors++;
        if (errors<=60) $display("[%0t] io_toICache_req_bits_pcMemRead_3_startAddr g=%h i=%h", $time, g_io_toICache_req_bits_pcMemRead_3_startAddr, i_io_toICache_req_bits_pcMemRead_3_startAddr); end end
    if (!$isunknown(g_io_toICache_req_bits_pcMemRead_3_nextlineStart)) begin checks++;
      if (g_io_toICache_req_bits_pcMemRead_3_nextlineStart !== i_io_toICache_req_bits_pcMemRead_3_nextlineStart) begin errors++;
        if (errors<=60) $display("[%0t] io_toICache_req_bits_pcMemRead_3_nextlineStart g=%h i=%h", $time, g_io_toICache_req_bits_pcMemRead_3_nextlineStart, i_io_toICache_req_bits_pcMemRead_3_nextlineStart); end end
    if (!$isunknown(g_io_toICache_req_bits_pcMemRead_4_startAddr)) begin checks++;
      if (g_io_toICache_req_bits_pcMemRead_4_startAddr !== i_io_toICache_req_bits_pcMemRead_4_startAddr) begin errors++;
        if (errors<=60) $display("[%0t] io_toICache_req_bits_pcMemRead_4_startAddr g=%h i=%h", $time, g_io_toICache_req_bits_pcMemRead_4_startAddr, i_io_toICache_req_bits_pcMemRead_4_startAddr); end end
    if (!$isunknown(g_io_toICache_req_bits_pcMemRead_4_nextlineStart)) begin checks++;
      if (g_io_toICache_req_bits_pcMemRead_4_nextlineStart !== i_io_toICache_req_bits_pcMemRead_4_nextlineStart) begin errors++;
        if (errors<=60) $display("[%0t] io_toICache_req_bits_pcMemRead_4_nextlineStart g=%h i=%h", $time, g_io_toICache_req_bits_pcMemRead_4_nextlineStart, i_io_toICache_req_bits_pcMemRead_4_nextlineStart); end end
    if (!$isunknown(g_io_toICache_req_bits_readValid_0)) begin checks++;
      if (g_io_toICache_req_bits_readValid_0 !== i_io_toICache_req_bits_readValid_0) begin errors++;
        if (errors<=60) $display("[%0t] io_toICache_req_bits_readValid_0 g=%h i=%h", $time, g_io_toICache_req_bits_readValid_0, i_io_toICache_req_bits_readValid_0); end end
    if (!$isunknown(g_io_toICache_req_bits_readValid_1)) begin checks++;
      if (g_io_toICache_req_bits_readValid_1 !== i_io_toICache_req_bits_readValid_1) begin errors++;
        if (errors<=60) $display("[%0t] io_toICache_req_bits_readValid_1 g=%h i=%h", $time, g_io_toICache_req_bits_readValid_1, i_io_toICache_req_bits_readValid_1); end end
    if (!$isunknown(g_io_toICache_req_bits_readValid_2)) begin checks++;
      if (g_io_toICache_req_bits_readValid_2 !== i_io_toICache_req_bits_readValid_2) begin errors++;
        if (errors<=60) $display("[%0t] io_toICache_req_bits_readValid_2 g=%h i=%h", $time, g_io_toICache_req_bits_readValid_2, i_io_toICache_req_bits_readValid_2); end end
    if (!$isunknown(g_io_toICache_req_bits_readValid_3)) begin checks++;
      if (g_io_toICache_req_bits_readValid_3 !== i_io_toICache_req_bits_readValid_3) begin errors++;
        if (errors<=60) $display("[%0t] io_toICache_req_bits_readValid_3 g=%h i=%h", $time, g_io_toICache_req_bits_readValid_3, i_io_toICache_req_bits_readValid_3); end end
    if (!$isunknown(g_io_toICache_req_bits_readValid_4)) begin checks++;
      if (g_io_toICache_req_bits_readValid_4 !== i_io_toICache_req_bits_readValid_4) begin errors++;
        if (errors<=60) $display("[%0t] io_toICache_req_bits_readValid_4 g=%h i=%h", $time, g_io_toICache_req_bits_readValid_4, i_io_toICache_req_bits_readValid_4); end end
    if (!$isunknown(g_io_toICache_req_bits_backendException)) begin checks++;
      if (g_io_toICache_req_bits_backendException !== i_io_toICache_req_bits_backendException) begin errors++;
        if (errors<=60) $display("[%0t] io_toICache_req_bits_backendException g=%h i=%h", $time, g_io_toICache_req_bits_backendException, i_io_toICache_req_bits_backendException); end end
    if (!$isunknown(g_io_toICache_req_bits_hasSatpFlush)) begin checks++;
      if (g_io_toICache_req_bits_hasSatpFlush !== i_io_toICache_req_bits_hasSatpFlush) begin errors++;
        if (errors<=60) $display("[%0t] io_toICache_req_bits_hasSatpFlush g=%h i=%h", $time, g_io_toICache_req_bits_hasSatpFlush, i_io_toICache_req_bits_hasSatpFlush); end end
    if (!$isunknown(g_io_toBackend_pc_mem_wen)) begin checks++;
      if (g_io_toBackend_pc_mem_wen !== i_io_toBackend_pc_mem_wen) begin errors++;
        if (errors<=60) $display("[%0t] io_toBackend_pc_mem_wen g=%h i=%h", $time, g_io_toBackend_pc_mem_wen, i_io_toBackend_pc_mem_wen); end end
    if (!$isunknown(g_io_toBackend_pc_mem_waddr)) begin checks++;
      if (g_io_toBackend_pc_mem_waddr !== i_io_toBackend_pc_mem_waddr) begin errors++;
        if (errors<=60) $display("[%0t] io_toBackend_pc_mem_waddr g=%h i=%h", $time, g_io_toBackend_pc_mem_waddr, i_io_toBackend_pc_mem_waddr); end end
    if (!$isunknown(g_io_toBackend_pc_mem_wdata_startAddr)) begin checks++;
      if (g_io_toBackend_pc_mem_wdata_startAddr !== i_io_toBackend_pc_mem_wdata_startAddr) begin errors++;
        if (errors<=60) $display("[%0t] io_toBackend_pc_mem_wdata_startAddr g=%h i=%h", $time, g_io_toBackend_pc_mem_wdata_startAddr, i_io_toBackend_pc_mem_wdata_startAddr); end end
    if (!$isunknown(g_io_toBackend_newest_entry_en)) begin checks++;
      if (g_io_toBackend_newest_entry_en !== i_io_toBackend_newest_entry_en) begin errors++;
        if (errors<=60) $display("[%0t] io_toBackend_newest_entry_en g=%h i=%h", $time, g_io_toBackend_newest_entry_en, i_io_toBackend_newest_entry_en); end end
    if (!$isunknown(g_io_toBackend_newest_entry_target)) begin checks++;
      if (g_io_toBackend_newest_entry_target !== i_io_toBackend_newest_entry_target) begin errors++;
        if (errors<=60) $display("[%0t] io_toBackend_newest_entry_target g=%h i=%h", $time, g_io_toBackend_newest_entry_target, i_io_toBackend_newest_entry_target); end end
    if (!$isunknown(g_io_toBackend_newest_entry_ptr_value)) begin checks++;
      if (g_io_toBackend_newest_entry_ptr_value !== i_io_toBackend_newest_entry_ptr_value) begin errors++;
        if (errors<=60) $display("[%0t] io_toBackend_newest_entry_ptr_value g=%h i=%h", $time, g_io_toBackend_newest_entry_ptr_value, i_io_toBackend_newest_entry_ptr_value); end end
    if (!$isunknown(g_io_toPrefetch_req_valid)) begin checks++;
      if (g_io_toPrefetch_req_valid !== i_io_toPrefetch_req_valid) begin errors++;
        if (errors<=60) $display("[%0t] io_toPrefetch_req_valid g=%h i=%h", $time, g_io_toPrefetch_req_valid, i_io_toPrefetch_req_valid); end end
    if (!$isunknown(g_io_toPrefetch_req_bits_startAddr)) begin checks++;
      if (g_io_toPrefetch_req_bits_startAddr !== i_io_toPrefetch_req_bits_startAddr) begin errors++;
        if (errors<=60) $display("[%0t] io_toPrefetch_req_bits_startAddr g=%h i=%h", $time, g_io_toPrefetch_req_bits_startAddr, i_io_toPrefetch_req_bits_startAddr); end end
    if (!$isunknown(g_io_toPrefetch_req_bits_nextlineStart)) begin checks++;
      if (g_io_toPrefetch_req_bits_nextlineStart !== i_io_toPrefetch_req_bits_nextlineStart) begin errors++;
        if (errors<=60) $display("[%0t] io_toPrefetch_req_bits_nextlineStart g=%h i=%h", $time, g_io_toPrefetch_req_bits_nextlineStart, i_io_toPrefetch_req_bits_nextlineStart); end end
    if (!$isunknown(g_io_toPrefetch_req_bits_ftqIdx_flag)) begin checks++;
      if (g_io_toPrefetch_req_bits_ftqIdx_flag !== i_io_toPrefetch_req_bits_ftqIdx_flag) begin errors++;
        if (errors<=60) $display("[%0t] io_toPrefetch_req_bits_ftqIdx_flag g=%h i=%h", $time, g_io_toPrefetch_req_bits_ftqIdx_flag, i_io_toPrefetch_req_bits_ftqIdx_flag); end end
    if (!$isunknown(g_io_toPrefetch_req_bits_ftqIdx_value)) begin checks++;
      if (g_io_toPrefetch_req_bits_ftqIdx_value !== i_io_toPrefetch_req_bits_ftqIdx_value) begin errors++;
        if (errors<=60) $display("[%0t] io_toPrefetch_req_bits_ftqIdx_value g=%h i=%h", $time, g_io_toPrefetch_req_bits_ftqIdx_value, i_io_toPrefetch_req_bits_ftqIdx_value); end end
    if (!$isunknown(g_io_toPrefetch_flushFromBpu_s2_valid)) begin checks++;
      if (g_io_toPrefetch_flushFromBpu_s2_valid !== i_io_toPrefetch_flushFromBpu_s2_valid) begin errors++;
        if (errors<=60) $display("[%0t] io_toPrefetch_flushFromBpu_s2_valid g=%h i=%h", $time, g_io_toPrefetch_flushFromBpu_s2_valid, i_io_toPrefetch_flushFromBpu_s2_valid); end end
    if (!$isunknown(g_io_toPrefetch_flushFromBpu_s2_bits_flag)) begin checks++;
      if (g_io_toPrefetch_flushFromBpu_s2_bits_flag !== i_io_toPrefetch_flushFromBpu_s2_bits_flag) begin errors++;
        if (errors<=60) $display("[%0t] io_toPrefetch_flushFromBpu_s2_bits_flag g=%h i=%h", $time, g_io_toPrefetch_flushFromBpu_s2_bits_flag, i_io_toPrefetch_flushFromBpu_s2_bits_flag); end end
    if (!$isunknown(g_io_toPrefetch_flushFromBpu_s2_bits_value)) begin checks++;
      if (g_io_toPrefetch_flushFromBpu_s2_bits_value !== i_io_toPrefetch_flushFromBpu_s2_bits_value) begin errors++;
        if (errors<=60) $display("[%0t] io_toPrefetch_flushFromBpu_s2_bits_value g=%h i=%h", $time, g_io_toPrefetch_flushFromBpu_s2_bits_value, i_io_toPrefetch_flushFromBpu_s2_bits_value); end end
    if (!$isunknown(g_io_toPrefetch_flushFromBpu_s3_valid)) begin checks++;
      if (g_io_toPrefetch_flushFromBpu_s3_valid !== i_io_toPrefetch_flushFromBpu_s3_valid) begin errors++;
        if (errors<=60) $display("[%0t] io_toPrefetch_flushFromBpu_s3_valid g=%h i=%h", $time, g_io_toPrefetch_flushFromBpu_s3_valid, i_io_toPrefetch_flushFromBpu_s3_valid); end end
    if (!$isunknown(g_io_toPrefetch_flushFromBpu_s3_bits_flag)) begin checks++;
      if (g_io_toPrefetch_flushFromBpu_s3_bits_flag !== i_io_toPrefetch_flushFromBpu_s3_bits_flag) begin errors++;
        if (errors<=60) $display("[%0t] io_toPrefetch_flushFromBpu_s3_bits_flag g=%h i=%h", $time, g_io_toPrefetch_flushFromBpu_s3_bits_flag, i_io_toPrefetch_flushFromBpu_s3_bits_flag); end end
    if (!$isunknown(g_io_toPrefetch_flushFromBpu_s3_bits_value)) begin checks++;
      if (g_io_toPrefetch_flushFromBpu_s3_bits_value !== i_io_toPrefetch_flushFromBpu_s3_bits_value) begin errors++;
        if (errors<=60) $display("[%0t] io_toPrefetch_flushFromBpu_s3_bits_value g=%h i=%h", $time, g_io_toPrefetch_flushFromBpu_s3_bits_value, i_io_toPrefetch_flushFromBpu_s3_bits_value); end end
    if (!$isunknown(g_io_toPrefetch_backendException)) begin checks++;
      if (g_io_toPrefetch_backendException !== i_io_toPrefetch_backendException) begin errors++;
        if (errors<=60) $display("[%0t] io_toPrefetch_backendException g=%h i=%h", $time, g_io_toPrefetch_backendException, i_io_toPrefetch_backendException); end end
    if (!$isunknown(g_io_icacheFlush)) begin checks++;
      if (g_io_icacheFlush !== i_io_icacheFlush) begin errors++;
        if (errors<=60) $display("[%0t] io_icacheFlush g=%h i=%h", $time, g_io_icacheFlush, i_io_icacheFlush); end end
    if (!$isunknown(g_io_mmioCommitRead_mmioLastCommit)) begin checks++;
      if (g_io_mmioCommitRead_mmioLastCommit !== i_io_mmioCommitRead_mmioLastCommit) begin errors++;
        if (errors<=60) $display("[%0t] io_mmioCommitRead_mmioLastCommit g=%h i=%h", $time, g_io_mmioCommitRead_mmioLastCommit, i_io_mmioCommitRead_mmioLastCommit); end end
    if (!$isunknown(g_io_ControlBTBMissBubble)) begin checks++;
      if (g_io_ControlBTBMissBubble !== i_io_ControlBTBMissBubble) begin errors++;
        if (errors<=60) $display("[%0t] io_ControlBTBMissBubble g=%h i=%h", $time, g_io_ControlBTBMissBubble, i_io_ControlBTBMissBubble); end end
    if (!$isunknown(g_io_TAGEMissBubble)) begin checks++;
      if (g_io_TAGEMissBubble !== i_io_TAGEMissBubble) begin errors++;
        if (errors<=60) $display("[%0t] io_TAGEMissBubble g=%h i=%h", $time, g_io_TAGEMissBubble, i_io_TAGEMissBubble); end end
    if (!$isunknown(g_io_SCMissBubble)) begin checks++;
      if (g_io_SCMissBubble !== i_io_SCMissBubble) begin errors++;
        if (errors<=60) $display("[%0t] io_SCMissBubble g=%h i=%h", $time, g_io_SCMissBubble, i_io_SCMissBubble); end end
    if (!$isunknown(g_io_ITTAGEMissBubble)) begin checks++;
      if (g_io_ITTAGEMissBubble !== i_io_ITTAGEMissBubble) begin errors++;
        if (errors<=60) $display("[%0t] io_ITTAGEMissBubble g=%h i=%h", $time, g_io_ITTAGEMissBubble, i_io_ITTAGEMissBubble); end end
    if (!$isunknown(g_io_RASMissBubble)) begin checks++;
      if (g_io_RASMissBubble !== i_io_RASMissBubble) begin errors++;
        if (errors<=60) $display("[%0t] io_RASMissBubble g=%h i=%h", $time, g_io_RASMissBubble, i_io_RASMissBubble); end end
    if (!$isunknown(g_io_perf_0_value)) begin checks++;
      if (g_io_perf_0_value !== i_io_perf_0_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_0_value g=%h i=%h", $time, g_io_perf_0_value, i_io_perf_0_value); end end
    if (!$isunknown(g_io_perf_1_value)) begin checks++;
      if (g_io_perf_1_value !== i_io_perf_1_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_1_value g=%h i=%h", $time, g_io_perf_1_value, i_io_perf_1_value); end end
    if (!$isunknown(g_io_perf_2_value)) begin checks++;
      if (g_io_perf_2_value !== i_io_perf_2_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_2_value g=%h i=%h", $time, g_io_perf_2_value, i_io_perf_2_value); end end
    if (!$isunknown(g_io_perf_3_value)) begin checks++;
      if (g_io_perf_3_value !== i_io_perf_3_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_3_value g=%h i=%h", $time, g_io_perf_3_value, i_io_perf_3_value); end end
    if (!$isunknown(g_io_perf_4_value)) begin checks++;
      if (g_io_perf_4_value !== i_io_perf_4_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_4_value g=%h i=%h", $time, g_io_perf_4_value, i_io_perf_4_value); end end
    if (!$isunknown(g_io_perf_5_value)) begin checks++;
      if (g_io_perf_5_value !== i_io_perf_5_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_5_value g=%h i=%h", $time, g_io_perf_5_value, i_io_perf_5_value); end end
    if (!$isunknown(g_io_perf_6_value)) begin checks++;
      if (g_io_perf_6_value !== i_io_perf_6_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_6_value g=%h i=%h", $time, g_io_perf_6_value, i_io_perf_6_value); end end
    if (!$isunknown(g_io_perf_7_value)) begin checks++;
      if (g_io_perf_7_value !== i_io_perf_7_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_7_value g=%h i=%h", $time, g_io_perf_7_value, i_io_perf_7_value); end end
    if (!$isunknown(g_io_perf_8_value)) begin checks++;
      if (g_io_perf_8_value !== i_io_perf_8_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_8_value g=%h i=%h", $time, g_io_perf_8_value, i_io_perf_8_value); end end
    if (!$isunknown(g_io_perf_9_value)) begin checks++;
      if (g_io_perf_9_value !== i_io_perf_9_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_9_value g=%h i=%h", $time, g_io_perf_9_value, i_io_perf_9_value); end end
    if (!$isunknown(g_io_perf_10_value)) begin checks++;
      if (g_io_perf_10_value !== i_io_perf_10_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_10_value g=%h i=%h", $time, g_io_perf_10_value, i_io_perf_10_value); end end
    if (!$isunknown(g_io_perf_11_value)) begin checks++;
      if (g_io_perf_11_value !== i_io_perf_11_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_11_value g=%h i=%h", $time, g_io_perf_11_value, i_io_perf_11_value); end end
    if (!$isunknown(g_io_perf_12_value)) begin checks++;
      if (g_io_perf_12_value !== i_io_perf_12_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_12_value g=%h i=%h", $time, g_io_perf_12_value, i_io_perf_12_value); end end
    if (!$isunknown(g_io_perf_13_value)) begin checks++;
      if (g_io_perf_13_value !== i_io_perf_13_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_13_value g=%h i=%h", $time, g_io_perf_13_value, i_io_perf_13_value); end end
    if (!$isunknown(g_io_perf_14_value)) begin checks++;
      if (g_io_perf_14_value !== i_io_perf_14_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_14_value g=%h i=%h", $time, g_io_perf_14_value, i_io_perf_14_value); end end
    if (!$isunknown(g_io_perf_15_value)) begin checks++;
      if (g_io_perf_15_value !== i_io_perf_15_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_15_value g=%h i=%h", $time, g_io_perf_15_value, i_io_perf_15_value); end end
    if (!$isunknown(g_io_perf_16_value)) begin checks++;
      if (g_io_perf_16_value !== i_io_perf_16_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_16_value g=%h i=%h", $time, g_io_perf_16_value, i_io_perf_16_value); end end
    if (!$isunknown(g_io_perf_17_value)) begin checks++;
      if (g_io_perf_17_value !== i_io_perf_17_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_17_value g=%h i=%h", $time, g_io_perf_17_value, i_io_perf_17_value); end end
    if (!$isunknown(g_io_perf_18_value)) begin checks++;
      if (g_io_perf_18_value !== i_io_perf_18_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_18_value g=%h i=%h", $time, g_io_perf_18_value, i_io_perf_18_value); end end
    if (!$isunknown(g_io_perf_19_value)) begin checks++;
      if (g_io_perf_19_value !== i_io_perf_19_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_19_value g=%h i=%h", $time, g_io_perf_19_value, i_io_perf_19_value); end end
    if (!$isunknown(g_io_perf_20_value)) begin checks++;
      if (g_io_perf_20_value !== i_io_perf_20_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_20_value g=%h i=%h", $time, g_io_perf_20_value, i_io_perf_20_value); end end
    if (!$isunknown(g_io_perf_21_value)) begin checks++;
      if (g_io_perf_21_value !== i_io_perf_21_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_21_value g=%h i=%h", $time, g_io_perf_21_value, i_io_perf_21_value); end end
    if (!$isunknown(g_io_perf_22_value)) begin checks++;
      if (g_io_perf_22_value !== i_io_perf_22_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_22_value g=%h i=%h", $time, g_io_perf_22_value, i_io_perf_22_value); end end
    if (!$isunknown(g_io_perf_23_value)) begin checks++;
      if (g_io_perf_23_value !== i_io_perf_23_value) begin errors++;
        if (errors<=60) $display("[%0t] io_perf_23_value g=%h i=%h", $time, g_io_perf_23_value, i_io_perf_23_value); end end
  end

  // ---- 覆盖统计 ----
  always @(posedge clk) if (!rst) begin
    if (io_fromBpu_resp_valid & g_io_fromBpu_resp_ready)   cov_bpu_enq_fire++;
    if (io_fromBpu_resp_valid & ~g_io_fromBpu_resp_ready)  cov_bpu_stall++;
    if (g_io_toIfu_flushFromBpu_s2_valid)                  cov_s2_redirect++;
    if (g_io_toIfu_flushFromBpu_s3_valid)                  cov_s3_redirect++;
    if (g_io_toIfu_req_valid & io_toIfu_req_ready)         cov_ifu_req_fire++;
    if (g_io_toPrefetch_req_valid & io_toPrefetch_req_ready) cov_pf_req_fire++;
    if (io_fromIfu_pdWb_valid)                             cov_pdwb++;
    if (io_fromBackend_redirect_valid)                     cov_be_redirect++;
    if (io_fromBackend_redirect_valid & io_fromBackend_ftqIdxAhead_0_valid)
                                                           cov_be_redir_ahead++;
    if (io_fromBackend_redirect_valid & io_fromBackend_redirect_bits_satpFlush)
                                                           cov_satp_redirect++;
    if (g_io_toICache_req_bits_hasSatpFlush === 1'b1)       cov_satp_out++;
    if (g_io_toICache_req_bits_backendException === 1'b1)   cov_backend_exc++;
    if (|{io_fromBackend_rob_commits_0_valid, io_fromBackend_rob_commits_1_valid,
          io_fromBackend_rob_commits_2_valid, io_fromBackend_rob_commits_3_valid,
          io_fromBackend_rob_commits_4_valid, io_fromBackend_rob_commits_5_valid,
          io_fromBackend_rob_commits_6_valid, io_fromBackend_rob_commits_7_valid})
                                                           cov_rob_commit++;
    if (g_io_toBpu_update_valid === 1'b1)                   cov_bpu_update++;
    if (g_io_toIfu_redirect_valid === 1'b1)                 cov_ifu_redirect++;
    if (g_io_icacheFlush === 1'b1)                          cov_icache_flush++;
    if (io_mmioCommitRead_valid)                           cov_mmio_read++;
    if (g_io_mmioCommitRead_mmioLastCommit === 1'b1)        cov_mmio_lastcmt++;
  end

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));   // ut_common.mk 统一下发 200000
    rst = 1; repeat (20) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    $display("--- coverage ---");
    $display("  cov_bpu_enq_fire     = %0d", cov_bpu_enq_fire);
    $display("  cov_bpu_stall        = %0d", cov_bpu_stall);
    $display("  cov_s2_redirect      = %0d", cov_s2_redirect);
    $display("  cov_s3_redirect      = %0d", cov_s3_redirect);
    $display("  cov_ifu_req_fire     = %0d", cov_ifu_req_fire);
    $display("  cov_pf_req_fire      = %0d", cov_pf_req_fire);
    $display("  cov_pdwb             = %0d", cov_pdwb);
    $display("  cov_be_redirect      = %0d", cov_be_redirect);
    $display("  cov_be_redir_ahead   = %0d", cov_be_redir_ahead);
    $display("  cov_satp_redirect    = %0d", cov_satp_redirect);
    $display("  cov_satp_out         = %0d", cov_satp_out);
    $display("  cov_backend_exc      = %0d", cov_backend_exc);
    $display("  cov_rob_commit       = %0d", cov_rob_commit);
    $display("  cov_bpu_update       = %0d", cov_bpu_update);
    $display("  cov_ifu_redirect     = %0d", cov_ifu_redirect);
    $display("  cov_icache_flush     = %0d", cov_icache_flush);
    $display("  cov_mmio_read        = %0d", cov_mmio_read);
    $display("  cov_mmio_lastcmt     = %0d", cov_mmio_lastcmt);
    begin
      int unsigned zero_cov = 0;
      if (cov_bpu_enq_fire == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_bpu_enq_fire 从未发生"); end
      if (cov_bpu_stall == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_bpu_stall 从未发生"); end
      if (cov_s2_redirect == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_s2_redirect 从未发生"); end
      if (cov_s3_redirect == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_s3_redirect 从未发生"); end
      if (cov_ifu_req_fire == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_ifu_req_fire 从未发生"); end
      if (cov_pf_req_fire == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_pf_req_fire 从未发生"); end
      if (cov_pdwb == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_pdwb 从未发生"); end
      if (cov_be_redirect == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_be_redirect 从未发生"); end
      if (cov_be_redir_ahead == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_be_redir_ahead 从未发生"); end
      if (cov_satp_redirect == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_satp_redirect 从未发生"); end
      if (cov_satp_out == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_satp_out 从未发生"); end
      if (cov_backend_exc == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_backend_exc 从未发生"); end
      if (cov_rob_commit == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_rob_commit 从未发生"); end
      if (cov_bpu_update == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_bpu_update 从未发生"); end
      if (cov_ifu_redirect == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_ifu_redirect 从未发生"); end
      if (cov_icache_flush == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_icache_flush 从未发生"); end
      if (cov_mmio_read == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_mmio_read 从未发生"); end
      if (cov_mmio_lastcmt == 0) begin zero_cov++; $display("  [COVERAGE FAIL] cov_mmio_lastcmt 从未发生"); end
      if (errors == 0 && checks > 1000000 && zero_cov == 0) $display("TEST PASSED");
      else begin
        if (zero_cov != 0) $display("=== 覆盖闸不过：%0d 个关键事件计数为 0 ===", zero_cov);
        if (checks <= 1000000) $display("=== checks=%0d 过少，激励没打进去 ===", checks);
        $display("TEST FAILED");
      end
    end
    $finish;
  end
endmodule
