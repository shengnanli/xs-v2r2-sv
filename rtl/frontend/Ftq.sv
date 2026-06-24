// =============================================================================
// xs_Ftq_core —— Fetch Target Queue（取指目标队列），香山 V2R2 前端最核心的解耦/纠错枢纽
//
// 对应 Chisel: xiangshan.frontend.Ftq（class Ftq，见 NewFtq.scala）
//
// 【在前端中的位置】（数据流见 docs/frontend/Ftq.md）
//   BPU(分支预测) ──预测块──▶ FTQ ──取指请求──▶ IFU/ICache/Prefetch
//                              ▲  │
//          后端/IFU redirect ──┘  └──▶ 后端(pc_mem/newest_entry)
//          后端 rob_commit ─────────▶ FTQ ──update──▶ BPU(训练预测器)
//
//   FTQ 是一个 64 项的环形队列（FtqSize=64）。BPU 每拍产出一个"预测块"
//   （一段连续取指区间 + 末尾控制流去向）入队；IFU 按队列顺序逐块取出去取指；
//   预测错（IFU 预解码 / 后端执行）时冲刷队列并重取；后端提交时把真实结果回送，
//   据此生成 update 训练 BPU。
//
// 【为什么 FTQ 这么复杂】
//   它同时承载 6 类相互耦合的活动，每类都有自己的指针/时序：
//     ① enq  : BPU s1/s2/s3 三级预测结果入队（s2/s3 可覆盖 s1，触发 bpuPtr 回退）
//     ② toIfu: 按 ifuPtr 发取指请求；为切关键路径，PC 提前一拍读 + bypass 旁路
//     ③ wbIfu: IFU 预解码写回（pd 信息），检测 false-hit
//     ④ redirect: 后端/IFU 误预测 → 冲刷 ptr + commitStateQueue
//     ⑤ commit: 后端 rob 提交逐条标记 commitStateQueue，commPtr 顺序出队
//     ⑥ update: 出队块经 FTBEntryGen 生成 FTB 新条目 + 各 mask 喂回 BPU
//
// 【几大存储（多读口寄存器堆 / SRAM，golden 同名黑盒例化）】
//   - ftq_pc_mem      (FtqPcMemWrapper)          : 每块 PC 元信息（startAddr/nextLine/fallThruErr）
//   - ftq_redirect_mem (SyncDataModule 3R1W)     : 投机信息 spec_info（histPtr/RAS/SC 等）
//   - ftb_entry_mem   (SyncDataModule 2R1W)      : 预测时的 FTB 条目（供 redirect/commit 比对）
//   - ftq_pd_mem      (SyncDataModule 2R1W)      : IFU 预解码结果（brMask/jmpInfo/rvcMask）
//   - ftq_meta_1r_sram(FtqNRSRAM, SplittedSRAM)  : 预测器 meta + ftb_entry（仅 commit 读，容量大用 SRAM）
//   寄存器阵列（核内直接表达）：commitStateQueue / cfiIndex_vec / mispredict_vec /
//   entry_fetch_status / entry_hit_status / pred_stage / update_target / ifuRedirected。
//
// 【FtqPtr 环形指针】 {flag(1), value(6)}，flag 区分绕回；用纯函数做 inc/加常数/距离/先后比较。
//   指针族：bpuPtr(入队尾) / ifuPtr(取指头) / pfPtr(预取头) / ifuWbPtr(IFU 写回头) /
//          commPtr(提交头) / robCommPtr(rob 已提交位置)；外加各 +1/+2 预读指针与 5 份扇出复制。
//
// 【可读化重写说明】
//   本核与 golden 顶层端口完全同名同序（含 MBIST/bore sideband），便于 FM 与系统级替换；
//   可读性体现在模块体：按上述 6 节组织、用具名信号与 struct、用 genvar 表达 64 项阵列、
//   把 FtqPtr 运算抽成纯函数、丰富注释讲"为什么"。5 个存储 + MbistPipeFtq + FTBEntryGen
//   例化 golden 同名模块（已各自单独验证可读，此处当黑盒）。
// =============================================================================
module xs_Ftq_core(
  input  clock,
  input  reset,
  output io_fromBpu_resp_ready,
  input  io_fromBpu_resp_valid,
  input  [49:0] io_fromBpu_resp_bits_s1_pc_3,
  input  [63:0] io_fromBpu_resp_bits_s1_full_pred_0_predCycle,
  input  io_fromBpu_resp_bits_s1_full_pred_3_br_taken_mask_0,
  input  io_fromBpu_resp_bits_s1_full_pred_3_br_taken_mask_1,
  input  io_fromBpu_resp_bits_s1_full_pred_3_slot_valids_0,
  input  io_fromBpu_resp_bits_s1_full_pred_3_slot_valids_1,
  input  [49:0] io_fromBpu_resp_bits_s1_full_pred_3_targets_0,
  input  [49:0] io_fromBpu_resp_bits_s1_full_pred_3_targets_1,
  input  [3:0] io_fromBpu_resp_bits_s1_full_pred_3_offsets_0,
  input  [3:0] io_fromBpu_resp_bits_s1_full_pred_3_offsets_1,
  input  [49:0] io_fromBpu_resp_bits_s1_full_pred_3_fallThroughAddr,
  input  io_fromBpu_resp_bits_s1_full_pred_3_fallThroughErr,
  input  io_fromBpu_resp_bits_s1_full_pred_3_is_br_sharing,
  input  io_fromBpu_resp_bits_s1_full_pred_3_hit,
  input  [49:0] io_fromBpu_resp_bits_s2_pc_3,
  input  io_fromBpu_resp_bits_s2_valid_3,
  input  io_fromBpu_resp_bits_s2_hasRedirect_3,
  input  io_fromBpu_resp_bits_s2_ftq_idx_flag,
  input  [5:0] io_fromBpu_resp_bits_s2_ftq_idx_value,
  input  [63:0] io_fromBpu_resp_bits_s2_full_pred_0_predCycle,
  input  io_fromBpu_resp_bits_s2_full_pred_3_br_taken_mask_0,
  input  io_fromBpu_resp_bits_s2_full_pred_3_br_taken_mask_1,
  input  io_fromBpu_resp_bits_s2_full_pred_3_slot_valids_0,
  input  io_fromBpu_resp_bits_s2_full_pred_3_slot_valids_1,
  input  [49:0] io_fromBpu_resp_bits_s2_full_pred_3_targets_0,
  input  [49:0] io_fromBpu_resp_bits_s2_full_pred_3_targets_1,
  input  [3:0] io_fromBpu_resp_bits_s2_full_pred_3_offsets_0,
  input  [3:0] io_fromBpu_resp_bits_s2_full_pred_3_offsets_1,
  input  [49:0] io_fromBpu_resp_bits_s2_full_pred_3_fallThroughAddr,
  input  io_fromBpu_resp_bits_s2_full_pred_3_fallThroughErr,
  input  io_fromBpu_resp_bits_s2_full_pred_3_is_br_sharing,
  input  io_fromBpu_resp_bits_s2_full_pred_3_hit,
  input  [49:0] io_fromBpu_resp_bits_s3_pc_0,
  input  [49:0] io_fromBpu_resp_bits_s3_pc_3,
  input  io_fromBpu_resp_bits_s3_valid_3,
  input  io_fromBpu_resp_bits_s3_hasRedirect_3,
  input  io_fromBpu_resp_bits_s3_ftq_idx_flag,
  input  [5:0] io_fromBpu_resp_bits_s3_ftq_idx_value,
  input  [63:0] io_fromBpu_resp_bits_s3_full_pred_0_predCycle,
  input  io_fromBpu_resp_bits_s3_full_pred_3_br_taken_mask_0,
  input  io_fromBpu_resp_bits_s3_full_pred_3_br_taken_mask_1,
  input  io_fromBpu_resp_bits_s3_full_pred_3_slot_valids_0,
  input  io_fromBpu_resp_bits_s3_full_pred_3_slot_valids_1,
  input  [49:0] io_fromBpu_resp_bits_s3_full_pred_3_targets_0,
  input  [49:0] io_fromBpu_resp_bits_s3_full_pred_3_targets_1,
  input  [3:0] io_fromBpu_resp_bits_s3_full_pred_3_offsets_0,
  input  [3:0] io_fromBpu_resp_bits_s3_full_pred_3_offsets_1,
  input  [49:0] io_fromBpu_resp_bits_s3_full_pred_3_fallThroughAddr,
  input  io_fromBpu_resp_bits_s3_full_pred_3_fallThroughErr,
  input  io_fromBpu_resp_bits_s3_full_pred_3_is_br_sharing,
  input  io_fromBpu_resp_bits_s3_full_pred_3_hit,
  input  [515:0] io_fromBpu_resp_bits_last_stage_meta,
  input  io_fromBpu_resp_bits_last_stage_spec_info_histPtr_flag,
  input  [7:0] io_fromBpu_resp_bits_last_stage_spec_info_histPtr_value,
  input  [3:0] io_fromBpu_resp_bits_last_stage_spec_info_ssp,
  input  [2:0] io_fromBpu_resp_bits_last_stage_spec_info_sctr,
  input  io_fromBpu_resp_bits_last_stage_spec_info_TOSW_flag,
  input  [4:0] io_fromBpu_resp_bits_last_stage_spec_info_TOSW_value,
  input  io_fromBpu_resp_bits_last_stage_spec_info_TOSR_flag,
  input  [4:0] io_fromBpu_resp_bits_last_stage_spec_info_TOSR_value,
  input  io_fromBpu_resp_bits_last_stage_spec_info_NOS_flag,
  input  [4:0] io_fromBpu_resp_bits_last_stage_spec_info_NOS_value,
  input  [49:0] io_fromBpu_resp_bits_last_stage_spec_info_topAddr,
  input  io_fromBpu_resp_bits_last_stage_spec_info_sc_disagree_0,
  input  io_fromBpu_resp_bits_last_stage_spec_info_sc_disagree_1,
  input  io_fromBpu_resp_bits_last_stage_ftb_entry_isCall,
  input  io_fromBpu_resp_bits_last_stage_ftb_entry_isRet,
  input  io_fromBpu_resp_bits_last_stage_ftb_entry_isJalr,
  input  io_fromBpu_resp_bits_last_stage_ftb_entry_valid,
  input  [3:0] io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_offset,
  input  io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_sharing,
  input  io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_valid,
  input  [11:0] io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_lower,
  input  [1:0] io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat,
  input  [3:0] io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_offset,
  input  io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_sharing,
  input  io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_valid,
  input  [19:0] io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_lower,
  input  [1:0] io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_tarStat,
  input  [3:0] io_fromBpu_resp_bits_last_stage_ftb_entry_pftAddr,
  input  io_fromBpu_resp_bits_last_stage_ftb_entry_carry,
  input  io_fromBpu_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call,
  input  io_fromBpu_resp_bits_last_stage_ftb_entry_strong_bias_0,
  input  io_fromBpu_resp_bits_last_stage_ftb_entry_strong_bias_1,
  input  io_fromBpu_resp_bits_topdown_info_reasons_1,
  input  io_fromBpu_resp_bits_topdown_info_reasons_2,
  input  io_fromBpu_resp_bits_topdown_info_reasons_3,
  input  io_fromBpu_resp_bits_topdown_info_reasons_4,
  input  io_fromBpu_resp_bits_topdown_info_reasons_5,
  input  io_fromBpu_resp_bits_topdown_info_reasons_6,
  input  io_fromBpu_resp_bits_topdown_info_reasons_7,
  input  io_fromBpu_resp_bits_topdown_info_reasons_8,
  input  io_fromBpu_resp_bits_topdown_info_reasons_9,
  input  io_fromBpu_resp_bits_topdown_info_reasons_12,
  input  io_fromIfu_pdWb_valid,
  input  [49:0] io_fromIfu_pdWb_bits_pc_0,
  input  [49:0] io_fromIfu_pdWb_bits_pc_1,
  input  [49:0] io_fromIfu_pdWb_bits_pc_2,
  input  [49:0] io_fromIfu_pdWb_bits_pc_3,
  input  [49:0] io_fromIfu_pdWb_bits_pc_4,
  input  [49:0] io_fromIfu_pdWb_bits_pc_5,
  input  [49:0] io_fromIfu_pdWb_bits_pc_6,
  input  [49:0] io_fromIfu_pdWb_bits_pc_7,
  input  [49:0] io_fromIfu_pdWb_bits_pc_8,
  input  [49:0] io_fromIfu_pdWb_bits_pc_9,
  input  [49:0] io_fromIfu_pdWb_bits_pc_10,
  input  [49:0] io_fromIfu_pdWb_bits_pc_11,
  input  [49:0] io_fromIfu_pdWb_bits_pc_12,
  input  [49:0] io_fromIfu_pdWb_bits_pc_13,
  input  [49:0] io_fromIfu_pdWb_bits_pc_14,
  input  [49:0] io_fromIfu_pdWb_bits_pc_15,
  input  io_fromIfu_pdWb_bits_pd_0_valid,
  input  io_fromIfu_pdWb_bits_pd_0_isRVC,
  input  [1:0] io_fromIfu_pdWb_bits_pd_0_brType,
  input  io_fromIfu_pdWb_bits_pd_0_isCall,
  input  io_fromIfu_pdWb_bits_pd_0_isRet,
  input  io_fromIfu_pdWb_bits_pd_1_valid,
  input  io_fromIfu_pdWb_bits_pd_1_isRVC,
  input  [1:0] io_fromIfu_pdWb_bits_pd_1_brType,
  input  io_fromIfu_pdWb_bits_pd_1_isCall,
  input  io_fromIfu_pdWb_bits_pd_1_isRet,
  input  io_fromIfu_pdWb_bits_pd_2_valid,
  input  io_fromIfu_pdWb_bits_pd_2_isRVC,
  input  [1:0] io_fromIfu_pdWb_bits_pd_2_brType,
  input  io_fromIfu_pdWb_bits_pd_2_isCall,
  input  io_fromIfu_pdWb_bits_pd_2_isRet,
  input  io_fromIfu_pdWb_bits_pd_3_valid,
  input  io_fromIfu_pdWb_bits_pd_3_isRVC,
  input  [1:0] io_fromIfu_pdWb_bits_pd_3_brType,
  input  io_fromIfu_pdWb_bits_pd_3_isCall,
  input  io_fromIfu_pdWb_bits_pd_3_isRet,
  input  io_fromIfu_pdWb_bits_pd_4_valid,
  input  io_fromIfu_pdWb_bits_pd_4_isRVC,
  input  [1:0] io_fromIfu_pdWb_bits_pd_4_brType,
  input  io_fromIfu_pdWb_bits_pd_4_isCall,
  input  io_fromIfu_pdWb_bits_pd_4_isRet,
  input  io_fromIfu_pdWb_bits_pd_5_valid,
  input  io_fromIfu_pdWb_bits_pd_5_isRVC,
  input  [1:0] io_fromIfu_pdWb_bits_pd_5_brType,
  input  io_fromIfu_pdWb_bits_pd_5_isCall,
  input  io_fromIfu_pdWb_bits_pd_5_isRet,
  input  io_fromIfu_pdWb_bits_pd_6_valid,
  input  io_fromIfu_pdWb_bits_pd_6_isRVC,
  input  [1:0] io_fromIfu_pdWb_bits_pd_6_brType,
  input  io_fromIfu_pdWb_bits_pd_6_isCall,
  input  io_fromIfu_pdWb_bits_pd_6_isRet,
  input  io_fromIfu_pdWb_bits_pd_7_valid,
  input  io_fromIfu_pdWb_bits_pd_7_isRVC,
  input  [1:0] io_fromIfu_pdWb_bits_pd_7_brType,
  input  io_fromIfu_pdWb_bits_pd_7_isCall,
  input  io_fromIfu_pdWb_bits_pd_7_isRet,
  input  io_fromIfu_pdWb_bits_pd_8_valid,
  input  io_fromIfu_pdWb_bits_pd_8_isRVC,
  input  [1:0] io_fromIfu_pdWb_bits_pd_8_brType,
  input  io_fromIfu_pdWb_bits_pd_8_isCall,
  input  io_fromIfu_pdWb_bits_pd_8_isRet,
  input  io_fromIfu_pdWb_bits_pd_9_valid,
  input  io_fromIfu_pdWb_bits_pd_9_isRVC,
  input  [1:0] io_fromIfu_pdWb_bits_pd_9_brType,
  input  io_fromIfu_pdWb_bits_pd_9_isCall,
  input  io_fromIfu_pdWb_bits_pd_9_isRet,
  input  io_fromIfu_pdWb_bits_pd_10_valid,
  input  io_fromIfu_pdWb_bits_pd_10_isRVC,
  input  [1:0] io_fromIfu_pdWb_bits_pd_10_brType,
  input  io_fromIfu_pdWb_bits_pd_10_isCall,
  input  io_fromIfu_pdWb_bits_pd_10_isRet,
  input  io_fromIfu_pdWb_bits_pd_11_valid,
  input  io_fromIfu_pdWb_bits_pd_11_isRVC,
  input  [1:0] io_fromIfu_pdWb_bits_pd_11_brType,
  input  io_fromIfu_pdWb_bits_pd_11_isCall,
  input  io_fromIfu_pdWb_bits_pd_11_isRet,
  input  io_fromIfu_pdWb_bits_pd_12_valid,
  input  io_fromIfu_pdWb_bits_pd_12_isRVC,
  input  [1:0] io_fromIfu_pdWb_bits_pd_12_brType,
  input  io_fromIfu_pdWb_bits_pd_12_isCall,
  input  io_fromIfu_pdWb_bits_pd_12_isRet,
  input  io_fromIfu_pdWb_bits_pd_13_valid,
  input  io_fromIfu_pdWb_bits_pd_13_isRVC,
  input  [1:0] io_fromIfu_pdWb_bits_pd_13_brType,
  input  io_fromIfu_pdWb_bits_pd_13_isCall,
  input  io_fromIfu_pdWb_bits_pd_13_isRet,
  input  io_fromIfu_pdWb_bits_pd_14_valid,
  input  io_fromIfu_pdWb_bits_pd_14_isRVC,
  input  [1:0] io_fromIfu_pdWb_bits_pd_14_brType,
  input  io_fromIfu_pdWb_bits_pd_14_isCall,
  input  io_fromIfu_pdWb_bits_pd_14_isRet,
  input  io_fromIfu_pdWb_bits_pd_15_valid,
  input  io_fromIfu_pdWb_bits_pd_15_isRVC,
  input  [1:0] io_fromIfu_pdWb_bits_pd_15_brType,
  input  io_fromIfu_pdWb_bits_pd_15_isCall,
  input  io_fromIfu_pdWb_bits_pd_15_isRet,
  input  io_fromIfu_pdWb_bits_ftqIdx_flag,
  input  [5:0] io_fromIfu_pdWb_bits_ftqIdx_value,
  input  io_fromIfu_pdWb_bits_misOffset_valid,
  input  [3:0] io_fromIfu_pdWb_bits_misOffset_bits,
  input  io_fromIfu_pdWb_bits_cfiOffset_valid,
  input  [49:0] io_fromIfu_pdWb_bits_target,
  input  [49:0] io_fromIfu_pdWb_bits_jalTarget,
  input  io_fromIfu_pdWb_bits_instrRange_0,
  input  io_fromIfu_pdWb_bits_instrRange_1,
  input  io_fromIfu_pdWb_bits_instrRange_2,
  input  io_fromIfu_pdWb_bits_instrRange_3,
  input  io_fromIfu_pdWb_bits_instrRange_4,
  input  io_fromIfu_pdWb_bits_instrRange_5,
  input  io_fromIfu_pdWb_bits_instrRange_6,
  input  io_fromIfu_pdWb_bits_instrRange_7,
  input  io_fromIfu_pdWb_bits_instrRange_8,
  input  io_fromIfu_pdWb_bits_instrRange_9,
  input  io_fromIfu_pdWb_bits_instrRange_10,
  input  io_fromIfu_pdWb_bits_instrRange_11,
  input  io_fromIfu_pdWb_bits_instrRange_12,
  input  io_fromIfu_pdWb_bits_instrRange_13,
  input  io_fromIfu_pdWb_bits_instrRange_14,
  input  io_fromIfu_pdWb_bits_instrRange_15,
  input  io_fromBackend_rob_commits_0_valid,
  input  [2:0] io_fromBackend_rob_commits_0_bits_commitType,
  input  io_fromBackend_rob_commits_0_bits_ftqIdx_flag,
  input  [5:0] io_fromBackend_rob_commits_0_bits_ftqIdx_value,
  input  [3:0] io_fromBackend_rob_commits_0_bits_ftqOffset,
  input  io_fromBackend_rob_commits_1_valid,
  input  [2:0] io_fromBackend_rob_commits_1_bits_commitType,
  input  io_fromBackend_rob_commits_1_bits_ftqIdx_flag,
  input  [5:0] io_fromBackend_rob_commits_1_bits_ftqIdx_value,
  input  [3:0] io_fromBackend_rob_commits_1_bits_ftqOffset,
  input  io_fromBackend_rob_commits_2_valid,
  input  [2:0] io_fromBackend_rob_commits_2_bits_commitType,
  input  io_fromBackend_rob_commits_2_bits_ftqIdx_flag,
  input  [5:0] io_fromBackend_rob_commits_2_bits_ftqIdx_value,
  input  [3:0] io_fromBackend_rob_commits_2_bits_ftqOffset,
  input  io_fromBackend_rob_commits_3_valid,
  input  [2:0] io_fromBackend_rob_commits_3_bits_commitType,
  input  io_fromBackend_rob_commits_3_bits_ftqIdx_flag,
  input  [5:0] io_fromBackend_rob_commits_3_bits_ftqIdx_value,
  input  [3:0] io_fromBackend_rob_commits_3_bits_ftqOffset,
  input  io_fromBackend_rob_commits_4_valid,
  input  [2:0] io_fromBackend_rob_commits_4_bits_commitType,
  input  io_fromBackend_rob_commits_4_bits_ftqIdx_flag,
  input  [5:0] io_fromBackend_rob_commits_4_bits_ftqIdx_value,
  input  [3:0] io_fromBackend_rob_commits_4_bits_ftqOffset,
  input  io_fromBackend_rob_commits_5_valid,
  input  [2:0] io_fromBackend_rob_commits_5_bits_commitType,
  input  io_fromBackend_rob_commits_5_bits_ftqIdx_flag,
  input  [5:0] io_fromBackend_rob_commits_5_bits_ftqIdx_value,
  input  [3:0] io_fromBackend_rob_commits_5_bits_ftqOffset,
  input  io_fromBackend_rob_commits_6_valid,
  input  [2:0] io_fromBackend_rob_commits_6_bits_commitType,
  input  io_fromBackend_rob_commits_6_bits_ftqIdx_flag,
  input  [5:0] io_fromBackend_rob_commits_6_bits_ftqIdx_value,
  input  [3:0] io_fromBackend_rob_commits_6_bits_ftqOffset,
  input  io_fromBackend_rob_commits_7_valid,
  input  [2:0] io_fromBackend_rob_commits_7_bits_commitType,
  input  io_fromBackend_rob_commits_7_bits_ftqIdx_flag,
  input  [5:0] io_fromBackend_rob_commits_7_bits_ftqIdx_value,
  input  [3:0] io_fromBackend_rob_commits_7_bits_ftqOffset,
  input  io_fromBackend_redirect_valid,
  input  io_fromBackend_redirect_bits_ftqIdx_flag,
  input  [5:0] io_fromBackend_redirect_bits_ftqIdx_value,
  input  [3:0] io_fromBackend_redirect_bits_ftqOffset,
  input  io_fromBackend_redirect_bits_level,
  input  [49:0] io_fromBackend_redirect_bits_cfiUpdate_pc,
  input  [49:0] io_fromBackend_redirect_bits_cfiUpdate_target,
  input  io_fromBackend_redirect_bits_cfiUpdate_taken,
  input  io_fromBackend_redirect_bits_cfiUpdate_isMisPred,
  input  io_fromBackend_redirect_bits_cfiUpdate_backendIGPF,
  input  io_fromBackend_redirect_bits_cfiUpdate_backendIPF,
  input  io_fromBackend_redirect_bits_cfiUpdate_backendIAF,
  input  io_fromBackend_redirect_bits_debugIsCtrl,
  input  io_fromBackend_redirect_bits_debugIsMemVio,
  input  io_fromBackend_ftqIdxAhead_0_valid,
  input  [5:0] io_fromBackend_ftqIdxAhead_0_bits_value,
  input  [2:0] io_fromBackend_ftqIdxSelOH_bits,
  output io_toBpu_redirect_valid,
  output io_toBpu_redirect_bits_level,
  output [49:0] io_toBpu_redirect_bits_cfiUpdate_pc,
  output io_toBpu_redirect_bits_cfiUpdate_pd_valid,
  output io_toBpu_redirect_bits_cfiUpdate_pd_isRVC,
  output io_toBpu_redirect_bits_cfiUpdate_pd_isCall,
  output io_toBpu_redirect_bits_cfiUpdate_pd_isRet,
  output [3:0] io_toBpu_redirect_bits_cfiUpdate_ssp,
  output [2:0] io_toBpu_redirect_bits_cfiUpdate_sctr,
  output io_toBpu_redirect_bits_cfiUpdate_TOSW_flag,
  output [4:0] io_toBpu_redirect_bits_cfiUpdate_TOSW_value,
  output io_toBpu_redirect_bits_cfiUpdate_TOSR_flag,
  output [4:0] io_toBpu_redirect_bits_cfiUpdate_TOSR_value,
  output io_toBpu_redirect_bits_cfiUpdate_NOS_flag,
  output [4:0] io_toBpu_redirect_bits_cfiUpdate_NOS_value,
  output io_toBpu_redirect_bits_cfiUpdate_histPtr_flag,
  output [7:0] io_toBpu_redirect_bits_cfiUpdate_histPtr_value,
  output io_toBpu_redirect_bits_cfiUpdate_br_hit,
  output io_toBpu_redirect_bits_cfiUpdate_jr_hit,
  output io_toBpu_redirect_bits_cfiUpdate_sc_hit,
  output [49:0] io_toBpu_redirect_bits_cfiUpdate_target,
  output io_toBpu_redirect_bits_cfiUpdate_taken,
  output [1:0] io_toBpu_redirect_bits_cfiUpdate_shift,
  output io_toBpu_redirect_bits_cfiUpdate_addIntoHist,
  output io_toBpu_redirect_bits_debugIsCtrl,
  output io_toBpu_redirect_bits_debugIsMemVio,
  output io_toBpu_redirect_bits_BTBMissBubble,
  output io_toBpu_update_valid,
  output [49:0] io_toBpu_update_bits_pc,
  output [7:0] io_toBpu_update_bits_spec_info_histPtr_value,
  output io_toBpu_update_bits_ftb_entry_isCall,
  output io_toBpu_update_bits_ftb_entry_isRet,
  output io_toBpu_update_bits_ftb_entry_isJalr,
  output io_toBpu_update_bits_ftb_entry_valid,
  output [3:0] io_toBpu_update_bits_ftb_entry_brSlots_0_offset,
  output io_toBpu_update_bits_ftb_entry_brSlots_0_sharing,
  output io_toBpu_update_bits_ftb_entry_brSlots_0_valid,
  output [11:0] io_toBpu_update_bits_ftb_entry_brSlots_0_lower,
  output [1:0] io_toBpu_update_bits_ftb_entry_brSlots_0_tarStat,
  output [3:0] io_toBpu_update_bits_ftb_entry_tailSlot_offset,
  output io_toBpu_update_bits_ftb_entry_tailSlot_sharing,
  output io_toBpu_update_bits_ftb_entry_tailSlot_valid,
  output [19:0] io_toBpu_update_bits_ftb_entry_tailSlot_lower,
  output [1:0] io_toBpu_update_bits_ftb_entry_tailSlot_tarStat,
  output [3:0] io_toBpu_update_bits_ftb_entry_pftAddr,
  output io_toBpu_update_bits_ftb_entry_carry,
  output io_toBpu_update_bits_ftb_entry_last_may_be_rvi_call,
  output io_toBpu_update_bits_ftb_entry_strong_bias_0,
  output io_toBpu_update_bits_ftb_entry_strong_bias_1,
  output io_toBpu_update_bits_cfi_idx_valid,
  output [3:0] io_toBpu_update_bits_cfi_idx_bits,
  output io_toBpu_update_bits_br_taken_mask_0,
  output io_toBpu_update_bits_br_taken_mask_1,
  output io_toBpu_update_bits_jmp_taken,
  output io_toBpu_update_bits_mispred_mask_0,
  output io_toBpu_update_bits_mispred_mask_1,
  output io_toBpu_update_bits_mispred_mask_2,
  output io_toBpu_update_bits_false_hit,
  output io_toBpu_update_bits_old_entry,
  output [515:0] io_toBpu_update_bits_meta,
  output [49:0] io_toBpu_update_bits_full_target,
  output io_toBpu_enq_ptr_flag,
  output [5:0] io_toBpu_enq_ptr_value,
  output io_toBpu_redirctFromIFU,
  input  io_toIfu_req_ready,
  output io_toIfu_req_valid,
  output [49:0] io_toIfu_req_bits_startAddr,
  output [49:0] io_toIfu_req_bits_nextlineStart,
  output [49:0] io_toIfu_req_bits_nextStartAddr,
  output io_toIfu_req_bits_ftqIdx_flag,
  output [5:0] io_toIfu_req_bits_ftqIdx_value,
  output io_toIfu_req_bits_ftqOffset_valid,
  output [3:0] io_toIfu_req_bits_ftqOffset_bits,
  output io_toIfu_req_bits_topdown_info_reasons_0,
  output io_toIfu_req_bits_topdown_info_reasons_1,
  output io_toIfu_req_bits_topdown_info_reasons_2,
  output io_toIfu_req_bits_topdown_info_reasons_3,
  output io_toIfu_req_bits_topdown_info_reasons_4,
  output io_toIfu_req_bits_topdown_info_reasons_5,
  output io_toIfu_req_bits_topdown_info_reasons_6,
  output io_toIfu_req_bits_topdown_info_reasons_7,
  output io_toIfu_req_bits_topdown_info_reasons_8,
  output io_toIfu_req_bits_topdown_info_reasons_9,
  output io_toIfu_req_bits_topdown_info_reasons_10,
  output io_toIfu_req_bits_topdown_info_reasons_11,
  output io_toIfu_req_bits_topdown_info_reasons_12,
  output io_toIfu_req_bits_topdown_info_reasons_13,
  output io_toIfu_req_bits_topdown_info_reasons_14,
  output io_toIfu_req_bits_topdown_info_reasons_15,
  output io_toIfu_req_bits_topdown_info_reasons_16,
  output io_toIfu_req_bits_topdown_info_reasons_17,
  output io_toIfu_req_bits_topdown_info_reasons_18,
  output io_toIfu_req_bits_topdown_info_reasons_19,
  output io_toIfu_req_bits_topdown_info_reasons_20,
  output io_toIfu_req_bits_topdown_info_reasons_21,
  output io_toIfu_req_bits_topdown_info_reasons_22,
  output io_toIfu_req_bits_topdown_info_reasons_23,
  output io_toIfu_req_bits_topdown_info_reasons_24,
  output io_toIfu_req_bits_topdown_info_reasons_25,
  output io_toIfu_req_bits_topdown_info_reasons_26,
  output io_toIfu_req_bits_topdown_info_reasons_27,
  output io_toIfu_req_bits_topdown_info_reasons_28,
  output io_toIfu_req_bits_topdown_info_reasons_29,
  output io_toIfu_req_bits_topdown_info_reasons_30,
  output io_toIfu_req_bits_topdown_info_reasons_31,
  output io_toIfu_req_bits_topdown_info_reasons_32,
  output io_toIfu_req_bits_topdown_info_reasons_33,
  output io_toIfu_req_bits_topdown_info_reasons_34,
  output io_toIfu_req_bits_topdown_info_reasons_35,
  output io_toIfu_req_bits_topdown_info_reasons_36,
  output io_toIfu_req_bits_topdown_info_reasons_37,
  output io_toIfu_redirect_valid,
  output io_toIfu_redirect_bits_ftqIdx_flag,
  output [5:0] io_toIfu_redirect_bits_ftqIdx_value,
  output [3:0] io_toIfu_redirect_bits_ftqOffset,
  output io_toIfu_redirect_bits_level,
  output io_toIfu_topdown_redirect_valid,
  output io_toIfu_topdown_redirect_bits_cfiUpdate_pd_isRet,
  output io_toIfu_topdown_redirect_bits_cfiUpdate_br_hit,
  output io_toIfu_topdown_redirect_bits_cfiUpdate_jr_hit,
  output io_toIfu_topdown_redirect_bits_cfiUpdate_sc_hit,
  output io_toIfu_topdown_redirect_bits_debugIsCtrl,
  output io_toIfu_topdown_redirect_bits_debugIsMemVio,
  output io_toIfu_flushFromBpu_s2_valid,
  output io_toIfu_flushFromBpu_s2_bits_flag,
  output [5:0] io_toIfu_flushFromBpu_s2_bits_value,
  output io_toIfu_flushFromBpu_s3_valid,
  output io_toIfu_flushFromBpu_s3_bits_flag,
  output [5:0] io_toIfu_flushFromBpu_s3_bits_value,
  output io_toICache_req_valid,
  output [49:0] io_toICache_req_bits_pcMemRead_0_startAddr,
  output [49:0] io_toICache_req_bits_pcMemRead_0_nextlineStart,
  output [49:0] io_toICache_req_bits_pcMemRead_1_startAddr,
  output [49:0] io_toICache_req_bits_pcMemRead_1_nextlineStart,
  output [49:0] io_toICache_req_bits_pcMemRead_2_startAddr,
  output [49:0] io_toICache_req_bits_pcMemRead_2_nextlineStart,
  output [49:0] io_toICache_req_bits_pcMemRead_3_startAddr,
  output [49:0] io_toICache_req_bits_pcMemRead_3_nextlineStart,
  output [49:0] io_toICache_req_bits_pcMemRead_4_startAddr,
  output [49:0] io_toICache_req_bits_pcMemRead_4_nextlineStart,
  output io_toICache_req_bits_readValid_0,
  output io_toICache_req_bits_readValid_1,
  output io_toICache_req_bits_readValid_2,
  output io_toICache_req_bits_readValid_3,
  output io_toICache_req_bits_readValid_4,
  output io_toICache_req_bits_backendException,
  output io_toBackend_pc_mem_wen,
  output [5:0] io_toBackend_pc_mem_waddr,
  output [49:0] io_toBackend_pc_mem_wdata_startAddr,
  output io_toBackend_newest_entry_en,
  output [49:0] io_toBackend_newest_entry_target,
  output [5:0] io_toBackend_newest_entry_ptr_value,
  input  io_toPrefetch_req_ready,
  output io_toPrefetch_req_valid,
  output [49:0] io_toPrefetch_req_bits_startAddr,
  output [49:0] io_toPrefetch_req_bits_nextlineStart,
  output io_toPrefetch_req_bits_ftqIdx_flag,
  output [5:0] io_toPrefetch_req_bits_ftqIdx_value,
  output io_toPrefetch_flushFromBpu_s2_valid,
  output io_toPrefetch_flushFromBpu_s2_bits_flag,
  output [5:0] io_toPrefetch_flushFromBpu_s2_bits_value,
  output io_toPrefetch_flushFromBpu_s3_valid,
  output io_toPrefetch_flushFromBpu_s3_bits_flag,
  output [5:0] io_toPrefetch_flushFromBpu_s3_bits_value,
  output [1:0] io_toPrefetch_backendException,
  output io_icacheFlush,
  input  io_mmioCommitRead_mmioFtqPtr_flag,
  input  [5:0] io_mmioCommitRead_mmioFtqPtr_value,
  output io_mmioCommitRead_mmioLastCommit,
  output io_ControlBTBMissBubble,
  output io_TAGEMissBubble,
  output io_SCMissBubble,
  output io_ITTAGEMissBubble,
  output io_RASMissBubble,
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
  output [5:0] io_perf_12_value,
  output [5:0] io_perf_13_value,
  output [5:0] io_perf_14_value,
  output [5:0] io_perf_15_value,
  output [5:0] io_perf_16_value,
  output [5:0] io_perf_17_value,
  output [5:0] io_perf_18_value,
  output [5:0] io_perf_19_value,
  output [5:0] io_perf_20_value,
  output [5:0] io_perf_21_value,
  output [5:0] io_perf_22_value,
  output [5:0] io_perf_23_value,
  input  [6:0] boreChildrenBd_bore_array,
  input  boreChildrenBd_bore_all,
  input  boreChildrenBd_bore_req,
  output boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_writeen,
  input  boreChildrenBd_bore_be,
  input  [6:0] boreChildrenBd_bore_addr,
  input  [143:0] boreChildrenBd_bore_indata,
  input  boreChildrenBd_bore_readen,
  input  [6:0] boreChildrenBd_bore_addr_rd,
  output [143:0] boreChildrenBd_bore_outdata,
  input  sigFromSrams_bore_ram_hold,
  input  sigFromSrams_bore_ram_bypass,
  input  sigFromSrams_bore_ram_bp_clken,
  input  sigFromSrams_bore_ram_aux_clk,
  input  sigFromSrams_bore_ram_aux_ckbp,
  input  sigFromSrams_bore_ram_mcp_hold,
  input  sigFromSrams_bore_cgen,
  input  sigFromSrams_bore_1_ram_hold,
  input  sigFromSrams_bore_1_ram_bypass,
  input  sigFromSrams_bore_1_ram_bp_clken,
  input  sigFromSrams_bore_1_ram_aux_clk,
  input  sigFromSrams_bore_1_ram_aux_ckbp,
  input  sigFromSrams_bore_1_ram_mcp_hold,
  input  sigFromSrams_bore_1_cgen,
  input  sigFromSrams_bore_2_ram_hold,
  input  sigFromSrams_bore_2_ram_bypass,
  input  sigFromSrams_bore_2_ram_bp_clken,
  input  sigFromSrams_bore_2_ram_aux_clk,
  input  sigFromSrams_bore_2_ram_aux_ckbp,
  input  sigFromSrams_bore_2_ram_mcp_hold,
  input  sigFromSrams_bore_2_cgen,
  input  sigFromSrams_bore_3_ram_hold,
  input  sigFromSrams_bore_3_ram_bypass,
  input  sigFromSrams_bore_3_ram_bp_clken,
  input  sigFromSrams_bore_3_ram_aux_clk,
  input  sigFromSrams_bore_3_ram_aux_ckbp,
  input  sigFromSrams_bore_3_ram_mcp_hold,
  input  sigFromSrams_bore_3_cgen

);

  // ===========================================================================
  // 参数与类型
  // ===========================================================================
  localparam int FTQ_SIZE     = 64;  // 队列项数
  localparam int PTR_W        = 6;   // FtqPtr.value 位宽 = log2(64)
  localparam int PREDICT_W    = 16;  // 一个预测块最多 16 条指令槽
  localparam int OFF_W        = 4;   // 块内偏移位宽 = log2(16)
  localparam int VADDR_W      = 50;  // 虚地址位宽
  localparam int NUM_BR       = 2;   // 一个 FTB 条目最多记 2 个条件分支

  // commitStateQueue 每项状态（4 态）
  localparam logic [1:0] C_EMPTY     = 2'd0; // 未占用
  localparam logic [1:0] C_TO_COMMIT = 2'd1; // 已取指、待提交
  localparam logic [1:0] C_COMMITTED = 2'd2; // 已提交
  localparam logic [1:0] C_FLUSHED   = 2'd3; // 被冲刷
  // entry_fetch_status：是否还需发给 IFU
  localparam logic F_TO_SEND = 1'b0;
  localparam logic F_SENT    = 1'b1;
  // entry_hit_status：FTB 命中状态（3 态）
  localparam logic [1:0] H_NOT_HIT   = 2'd0;
  localparam logic [1:0] H_FALSE_HIT = 2'd1;
  localparam logic [1:0] H_HIT       = 2'd2;
  // BPU 预测级编码
  localparam logic [1:0] BP_S1 = 2'd0, BP_S2 = 2'd1, BP_S3 = 2'd2;

  // -------- FtqPtr 纯函数：环形队列指针 {flag, value} 打包成 7 位 --------
  // 编码：ptr[6]=flag, ptr[5:0]=value。加法在 7 位上做即可自然处理绕回与 flag 翻转。
  function automatic logic [PTR_W:0] mk_ptr(input logic flag, input logic [PTR_W-1:0] val);
    mk_ptr = {flag, val};
  endfunction
  function automatic logic [PTR_W:0] ptr_add(input logic [PTR_W:0] p, input logic [PTR_W:0] d);
    ptr_add = p + d;            // 7 位环形加：value 进位自动翻转 flag
  endfunction
  // 距离 distanceBetween(end, start)：环形队列里 end 在 start 之后多少项（CircularQueuePtr 语义）
  function automatic logic [PTR_W:0] ptr_dist(input logic [PTR_W:0] e, input logic [PTR_W:0] s);
    logic ef, sf; logic [PTR_W-1:0] ev, sv;
    ef = e[PTR_W]; ev = e[PTR_W-1:0]; sf = s[PTR_W]; sv = s[PTR_W-1:0];
    ptr_dist = (ef == sf) ? {1'b0, (ev - sv)}
                          : ({1'b0, ev} + 7'(FTQ_SIZE) - {1'b0, sv});
  endfunction
  // isBefore(a,b) = (a < b)；isAfter(a,b) = (a > b)。
  //   CircularQueuePtr.scala 权威定义：
  //     a < b = (a.flag ^ b.flag) ^ (a.value < b.value)
  //     a > b = (a.flag ^ b.flag) ^ (a.value > b.value)
  //   ★必须用此 XOR 展开式★。早先写法 (sameFlag? a.v<b.v : a.v>b.v) 在“异 flag 且 value 相等”
  //   处与 golden 不同：golden 视 a 比 b 整整领先/落后一圈(64)，旧式判反 → commit_done/
  //   robCommPtr 推进错相一拍(BT 实测 canCommit 失配)。
  function automatic logic ptr_before(input logic [PTR_W:0] a, input logic [PTR_W:0] b);
    ptr_before = (a[PTR_W] ^ b[PTR_W]) ^ (a[PTR_W-1:0] < b[PTR_W-1:0]);
  endfunction
  function automatic logic ptr_after(input logic [PTR_W:0] a, input logic [PTR_W:0] b);
    ptr_after = (a[PTR_W] ^ b[PTR_W]) ^ (a[PTR_W-1:0] > b[PTR_W-1:0]);
  endfunction
  // s2/s3 重定向时是否需回拉取指指针 = !isBefore(ptr, idx)。golden 展开为
  //   ptr.flag ^ idx.flag ^ (ptr.value >= idx.value)
  // （注意与 ~ptr_before 在"异 flag 且 value 相等"处不同，须照此实现，否则绕回一拍后 flag 错位）
  function automatic logic ptr_recover(input logic [PTR_W:0] p, input logic [PTR_W:0] idx);
    ptr_recover = p[PTR_W] ^ idx[PTR_W] ^ (p[PTR_W-1:0] >= idx[PTR_W-1:0]);
  endfunction
  // isFull(a,b)：环已满（a 追上 b 且 flag 不同）
  function automatic logic ptr_full(input logic [PTR_W:0] a, input logic [PTR_W:0] b);
    ptr_full = (a[PTR_W] != b[PTR_W]) && (a[PTR_W-1:0] == b[PTR_W-1:0]);
  endfunction

  // ===========================================================================
  // 输入打包：把 golden 扁平端口聚成数组/struct，便于后续按"块/槽/项"表达
  // ===========================================================================
  // 复位（同步采样，FtqPtr 等寄存器异步复位到初值）
  wire rst = reset;

  // ---- 来自 IFU 的预解码写回 pdWb（16 槽 pc/pd/instrRange）----
  logic [PREDICT_W-1:0][VADDR_W-1:0] pdwb_pc;
  logic [PREDICT_W-1:0]              pdwb_pd_valid, pdwb_pd_isRVC, pdwb_pd_isCall, pdwb_pd_isRet;
  logic [PREDICT_W-1:0][1:0]         pdwb_pd_brType;
  logic [PREDICT_W-1:0]              pdwb_instrRange;
  always_comb begin
    pdwb_pc[0]=io_fromIfu_pdWb_bits_pc_0;  pdwb_pc[1]=io_fromIfu_pdWb_bits_pc_1;
    pdwb_pc[2]=io_fromIfu_pdWb_bits_pc_2;  pdwb_pc[3]=io_fromIfu_pdWb_bits_pc_3;
    pdwb_pc[4]=io_fromIfu_pdWb_bits_pc_4;  pdwb_pc[5]=io_fromIfu_pdWb_bits_pc_5;
    pdwb_pc[6]=io_fromIfu_pdWb_bits_pc_6;  pdwb_pc[7]=io_fromIfu_pdWb_bits_pc_7;
    pdwb_pc[8]=io_fromIfu_pdWb_bits_pc_8;  pdwb_pc[9]=io_fromIfu_pdWb_bits_pc_9;
    pdwb_pc[10]=io_fromIfu_pdWb_bits_pc_10; pdwb_pc[11]=io_fromIfu_pdWb_bits_pc_11;
    pdwb_pc[12]=io_fromIfu_pdWb_bits_pc_12; pdwb_pc[13]=io_fromIfu_pdWb_bits_pc_13;
    pdwb_pc[14]=io_fromIfu_pdWb_bits_pc_14; pdwb_pc[15]=io_fromIfu_pdWb_bits_pc_15;
    pdwb_pd_valid = {io_fromIfu_pdWb_bits_pd_15_valid, io_fromIfu_pdWb_bits_pd_14_valid,
      io_fromIfu_pdWb_bits_pd_13_valid, io_fromIfu_pdWb_bits_pd_12_valid,
      io_fromIfu_pdWb_bits_pd_11_valid, io_fromIfu_pdWb_bits_pd_10_valid,
      io_fromIfu_pdWb_bits_pd_9_valid, io_fromIfu_pdWb_bits_pd_8_valid,
      io_fromIfu_pdWb_bits_pd_7_valid, io_fromIfu_pdWb_bits_pd_6_valid,
      io_fromIfu_pdWb_bits_pd_5_valid, io_fromIfu_pdWb_bits_pd_4_valid,
      io_fromIfu_pdWb_bits_pd_3_valid, io_fromIfu_pdWb_bits_pd_2_valid,
      io_fromIfu_pdWb_bits_pd_1_valid, io_fromIfu_pdWb_bits_pd_0_valid};
    pdwb_pd_isRVC = {io_fromIfu_pdWb_bits_pd_15_isRVC, io_fromIfu_pdWb_bits_pd_14_isRVC,
      io_fromIfu_pdWb_bits_pd_13_isRVC, io_fromIfu_pdWb_bits_pd_12_isRVC,
      io_fromIfu_pdWb_bits_pd_11_isRVC, io_fromIfu_pdWb_bits_pd_10_isRVC,
      io_fromIfu_pdWb_bits_pd_9_isRVC, io_fromIfu_pdWb_bits_pd_8_isRVC,
      io_fromIfu_pdWb_bits_pd_7_isRVC, io_fromIfu_pdWb_bits_pd_6_isRVC,
      io_fromIfu_pdWb_bits_pd_5_isRVC, io_fromIfu_pdWb_bits_pd_4_isRVC,
      io_fromIfu_pdWb_bits_pd_3_isRVC, io_fromIfu_pdWb_bits_pd_2_isRVC,
      io_fromIfu_pdWb_bits_pd_1_isRVC, io_fromIfu_pdWb_bits_pd_0_isRVC};
    pdwb_pd_isCall = {io_fromIfu_pdWb_bits_pd_15_isCall, io_fromIfu_pdWb_bits_pd_14_isCall,
      io_fromIfu_pdWb_bits_pd_13_isCall, io_fromIfu_pdWb_bits_pd_12_isCall,
      io_fromIfu_pdWb_bits_pd_11_isCall, io_fromIfu_pdWb_bits_pd_10_isCall,
      io_fromIfu_pdWb_bits_pd_9_isCall, io_fromIfu_pdWb_bits_pd_8_isCall,
      io_fromIfu_pdWb_bits_pd_7_isCall, io_fromIfu_pdWb_bits_pd_6_isCall,
      io_fromIfu_pdWb_bits_pd_5_isCall, io_fromIfu_pdWb_bits_pd_4_isCall,
      io_fromIfu_pdWb_bits_pd_3_isCall, io_fromIfu_pdWb_bits_pd_2_isCall,
      io_fromIfu_pdWb_bits_pd_1_isCall, io_fromIfu_pdWb_bits_pd_0_isCall};
    pdwb_pd_isRet = {io_fromIfu_pdWb_bits_pd_15_isRet, io_fromIfu_pdWb_bits_pd_14_isRet,
      io_fromIfu_pdWb_bits_pd_13_isRet, io_fromIfu_pdWb_bits_pd_12_isRet,
      io_fromIfu_pdWb_bits_pd_11_isRet, io_fromIfu_pdWb_bits_pd_10_isRet,
      io_fromIfu_pdWb_bits_pd_9_isRet, io_fromIfu_pdWb_bits_pd_8_isRet,
      io_fromIfu_pdWb_bits_pd_7_isRet, io_fromIfu_pdWb_bits_pd_6_isRet,
      io_fromIfu_pdWb_bits_pd_5_isRet, io_fromIfu_pdWb_bits_pd_4_isRet,
      io_fromIfu_pdWb_bits_pd_3_isRet, io_fromIfu_pdWb_bits_pd_2_isRet,
      io_fromIfu_pdWb_bits_pd_1_isRet, io_fromIfu_pdWb_bits_pd_0_isRet};
    pdwb_pd_brType[0]=io_fromIfu_pdWb_bits_pd_0_brType;   pdwb_pd_brType[1]=io_fromIfu_pdWb_bits_pd_1_brType;
    pdwb_pd_brType[2]=io_fromIfu_pdWb_bits_pd_2_brType;   pdwb_pd_brType[3]=io_fromIfu_pdWb_bits_pd_3_brType;
    pdwb_pd_brType[4]=io_fromIfu_pdWb_bits_pd_4_brType;   pdwb_pd_brType[5]=io_fromIfu_pdWb_bits_pd_5_brType;
    pdwb_pd_brType[6]=io_fromIfu_pdWb_bits_pd_6_brType;   pdwb_pd_brType[7]=io_fromIfu_pdWb_bits_pd_7_brType;
    pdwb_pd_brType[8]=io_fromIfu_pdWb_bits_pd_8_brType;   pdwb_pd_brType[9]=io_fromIfu_pdWb_bits_pd_9_brType;
    pdwb_pd_brType[10]=io_fromIfu_pdWb_bits_pd_10_brType; pdwb_pd_brType[11]=io_fromIfu_pdWb_bits_pd_11_brType;
    pdwb_pd_brType[12]=io_fromIfu_pdWb_bits_pd_12_brType; pdwb_pd_brType[13]=io_fromIfu_pdWb_bits_pd_13_brType;
    pdwb_pd_brType[14]=io_fromIfu_pdWb_bits_pd_14_brType; pdwb_pd_brType[15]=io_fromIfu_pdWb_bits_pd_15_brType;
    pdwb_instrRange = {io_fromIfu_pdWb_bits_instrRange_15, io_fromIfu_pdWb_bits_instrRange_14,
      io_fromIfu_pdWb_bits_instrRange_13, io_fromIfu_pdWb_bits_instrRange_12,
      io_fromIfu_pdWb_bits_instrRange_11, io_fromIfu_pdWb_bits_instrRange_10,
      io_fromIfu_pdWb_bits_instrRange_9, io_fromIfu_pdWb_bits_instrRange_8,
      io_fromIfu_pdWb_bits_instrRange_7, io_fromIfu_pdWb_bits_instrRange_6,
      io_fromIfu_pdWb_bits_instrRange_5, io_fromIfu_pdWb_bits_instrRange_4,
      io_fromIfu_pdWb_bits_instrRange_3, io_fromIfu_pdWb_bits_instrRange_2,
      io_fromIfu_pdWb_bits_instrRange_1, io_fromIfu_pdWb_bits_instrRange_0};
  end

  // ---- 来自后端的 8 路 rob commit ----
  logic [7:0]       robc_valid;
  logic [7:0][2:0]  robc_type;
  logic [7:0]       robc_idx_flag;
  logic [7:0][5:0]  robc_idx_value;
  logic [7:0][3:0]  robc_offset;
  always_comb begin
    robc_valid = {io_fromBackend_rob_commits_7_valid, io_fromBackend_rob_commits_6_valid,
      io_fromBackend_rob_commits_5_valid, io_fromBackend_rob_commits_4_valid,
      io_fromBackend_rob_commits_3_valid, io_fromBackend_rob_commits_2_valid,
      io_fromBackend_rob_commits_1_valid, io_fromBackend_rob_commits_0_valid};
    robc_type[0]=io_fromBackend_rob_commits_0_bits_commitType; robc_type[1]=io_fromBackend_rob_commits_1_bits_commitType;
    robc_type[2]=io_fromBackend_rob_commits_2_bits_commitType; robc_type[3]=io_fromBackend_rob_commits_3_bits_commitType;
    robc_type[4]=io_fromBackend_rob_commits_4_bits_commitType; robc_type[5]=io_fromBackend_rob_commits_5_bits_commitType;
    robc_type[6]=io_fromBackend_rob_commits_6_bits_commitType; robc_type[7]=io_fromBackend_rob_commits_7_bits_commitType;
    robc_idx_flag[0]=io_fromBackend_rob_commits_0_bits_ftqIdx_flag; robc_idx_flag[1]=io_fromBackend_rob_commits_1_bits_ftqIdx_flag;
    robc_idx_flag[2]=io_fromBackend_rob_commits_2_bits_ftqIdx_flag; robc_idx_flag[3]=io_fromBackend_rob_commits_3_bits_ftqIdx_flag;
    robc_idx_flag[4]=io_fromBackend_rob_commits_4_bits_ftqIdx_flag; robc_idx_flag[5]=io_fromBackend_rob_commits_5_bits_ftqIdx_flag;
    robc_idx_flag[6]=io_fromBackend_rob_commits_6_bits_ftqIdx_flag; robc_idx_flag[7]=io_fromBackend_rob_commits_7_bits_ftqIdx_flag;
    robc_idx_value[0]=io_fromBackend_rob_commits_0_bits_ftqIdx_value; robc_idx_value[1]=io_fromBackend_rob_commits_1_bits_ftqIdx_value;
    robc_idx_value[2]=io_fromBackend_rob_commits_2_bits_ftqIdx_value; robc_idx_value[3]=io_fromBackend_rob_commits_3_bits_ftqIdx_value;
    robc_idx_value[4]=io_fromBackend_rob_commits_4_bits_ftqIdx_value; robc_idx_value[5]=io_fromBackend_rob_commits_5_bits_ftqIdx_value;
    robc_idx_value[6]=io_fromBackend_rob_commits_6_bits_ftqIdx_value; robc_idx_value[7]=io_fromBackend_rob_commits_7_bits_ftqIdx_value;
    robc_offset[0]=io_fromBackend_rob_commits_0_bits_ftqOffset; robc_offset[1]=io_fromBackend_rob_commits_1_bits_ftqOffset;
    robc_offset[2]=io_fromBackend_rob_commits_2_bits_ftqOffset; robc_offset[3]=io_fromBackend_rob_commits_3_bits_ftqOffset;
    robc_offset[4]=io_fromBackend_rob_commits_4_bits_ftqOffset; robc_offset[5]=io_fromBackend_rob_commits_5_bits_ftqOffset;
    robc_offset[6]=io_fromBackend_rob_commits_6_bits_ftqOffset; robc_offset[7]=io_fromBackend_rob_commits_7_bits_ftqOffset;
  end

  // ===========================================================================
  // redirect / flush 控制前置（对应 Scala 526-612）
  // ===========================================================================
  // 后端重定向有两种到达方式：
  //   · ahead 路径：后端先把 ftqIdx 提前一拍送来（ftqIdxAhead），用于提前读 redirect_mem
  //   · 普通路径：当拍 redirect.valid，但 cfi 信息要打一拍（backendRedirectReg）
  wire ahead_valid = io_fromBackend_ftqIdxAhead_0_valid & ~io_fromBackend_redirect_valid;
  reg  real_ahd_valid_reg;                 // RegNext(aheadValid)
  wire real_ahd_valid = io_fromBackend_redirect_valid & io_fromBackend_ftqIdxSelOH_bits[0]
                        & real_ahd_valid_reg;

  // backendRedirect = 当拍后端重定向（valid + 全部 bits 直接来自端口）
  wire        be_redir_valid = io_fromBackend_redirect_valid;
  // backendRedirectReg = 打一拍后的后端重定向（reduce fanout / 对齐 redirect_mem 读延迟）
  reg         be_redir_reg_valid;
  reg         be_redir_reg_idx_flag;
  reg  [5:0]  be_redir_reg_idx_value;
  reg  [3:0]  be_redir_reg_offset;
  reg         be_redir_reg_level;
  reg  [49:0] be_redir_reg_cfi_pc;
  reg  [49:0] be_redir_reg_cfi_target;
  reg         be_redir_reg_cfi_taken;
  reg         be_redir_reg_cfi_ismispred;
  reg         be_redir_reg_cfi_igpf, be_redir_reg_cfi_ipf, be_redir_reg_cfi_iaf;
  reg         be_redir_reg_dbg_ctrl, be_redir_reg_dbg_memvio;

  // fromBackendRedirect = 选当拍 or 打拍后的（ahead 真命中时用当拍，否则用打拍寄存）
  wire        fbr_valid      = real_ahd_valid ? be_redir_valid : be_redir_reg_valid;
  wire        fbr_idx_flag   = real_ahd_valid ? io_fromBackend_redirect_bits_ftqIdx_flag  : be_redir_reg_idx_flag;
  wire [5:0]  fbr_idx_value  = real_ahd_valid ? io_fromBackend_redirect_bits_ftqIdx_value : be_redir_reg_idx_value;
  wire [3:0]  fbr_offset     = real_ahd_valid ? io_fromBackend_redirect_bits_ftqOffset    : be_redir_reg_offset;
  wire        fbr_level      = real_ahd_valid ? io_fromBackend_redirect_bits_level         : be_redir_reg_level;
  wire [49:0] fbr_cfi_pc     = real_ahd_valid ? io_fromBackend_redirect_bits_cfiUpdate_pc  : be_redir_reg_cfi_pc;
  wire [49:0] fbr_cfi_target = real_ahd_valid ? io_fromBackend_redirect_bits_cfiUpdate_target : be_redir_reg_cfi_target;
  wire        fbr_cfi_taken  = real_ahd_valid ? io_fromBackend_redirect_bits_cfiUpdate_taken  : be_redir_reg_cfi_taken;
  wire        fbr_cfi_ismispred = real_ahd_valid ? io_fromBackend_redirect_bits_cfiUpdate_isMisPred : be_redir_reg_cfi_ismispred;
  wire        fbr_cfi_igpf   = real_ahd_valid ? io_fromBackend_redirect_bits_cfiUpdate_backendIGPF : be_redir_reg_cfi_igpf;
  wire        fbr_cfi_ipf    = real_ahd_valid ? io_fromBackend_redirect_bits_cfiUpdate_backendIPF  : be_redir_reg_cfi_ipf;
  wire        fbr_cfi_iaf    = real_ahd_valid ? io_fromBackend_redirect_bits_cfiUpdate_backendIAF  : be_redir_reg_cfi_iaf;
  wire        fbr_dbg_ctrl   = real_ahd_valid ? io_fromBackend_redirect_bits_debugIsCtrl   : be_redir_reg_dbg_ctrl;
  wire        fbr_dbg_memvio = real_ahd_valid ? io_fromBackend_redirect_bits_debugIsMemVio : be_redir_reg_dbg_memvio;

  wire        stage2_flush = be_redir_valid;
  reg         backend_flush_reg;           // RegNext(stage2Flush)
  wire        backend_flush = stage2_flush | backend_flush_reg;
  wire        ifu_flush;                   // 由 IFU redirect 段驱动
  // 允许 BPU 入队 / 发 IFU：无任何 flush 在途
  wire        allow_bpu_in = ~ifu_flush & ~be_redir_valid & ~be_redir_reg_valid;
  wire        allow_to_ifu = allow_bpu_in;

  always_ff @(posedge clock) begin
    real_ahd_valid_reg <= ahead_valid;
    backend_flush_reg  <= stage2_flush;
    // backendRedirectReg：valid 在 ahead 真命中时清 0，否则 = 当拍 backendRedirect.valid
    be_redir_reg_valid <= real_ahd_valid ? 1'b0 : be_redir_valid;
    if (be_redir_valid) begin             // RegEnable(backendRedirect.bits, backendRedirect.valid)
      be_redir_reg_idx_flag    <= io_fromBackend_redirect_bits_ftqIdx_flag;
      be_redir_reg_idx_value   <= io_fromBackend_redirect_bits_ftqIdx_value;
      be_redir_reg_offset      <= io_fromBackend_redirect_bits_ftqOffset;
      be_redir_reg_level       <= io_fromBackend_redirect_bits_level;
      be_redir_reg_cfi_pc      <= io_fromBackend_redirect_bits_cfiUpdate_pc;
      be_redir_reg_cfi_target  <= io_fromBackend_redirect_bits_cfiUpdate_target;
      be_redir_reg_cfi_taken   <= io_fromBackend_redirect_bits_cfiUpdate_taken;
      be_redir_reg_cfi_ismispred <= io_fromBackend_redirect_bits_cfiUpdate_isMisPred;
      be_redir_reg_cfi_igpf    <= io_fromBackend_redirect_bits_cfiUpdate_backendIGPF;
      be_redir_reg_cfi_ipf     <= io_fromBackend_redirect_bits_cfiUpdate_backendIPF;
      be_redir_reg_cfi_iaf     <= io_fromBackend_redirect_bits_cfiUpdate_backendIAF;
      be_redir_reg_dbg_ctrl    <= io_fromBackend_redirect_bits_debugIsCtrl;
      be_redir_reg_dbg_memvio  <= io_fromBackend_redirect_bits_debugIsMemVio;
    end
  end

  // ===========================================================================
  // 环形指针族（对应 Scala 557-587）
  // ===========================================================================
  reg  [PTR_W:0] bpuPtr, ifuPtr, pfPtr, ifuWbPtr, commPtr, robCommPtr;
  reg  [PTR_W:0] ifuPtrPlus1, ifuPtrPlus2, pfPtrPlus1, commPtrPlus1;
  // 写线（组合算出下拍值，最后统一打入寄存器；reduce-fanout 复制见 toICache 段）
  logic [PTR_W:0] ifuPtr_w, ifuPtrPlus1_w, ifuPtrPlus2_w, pfPtr_w, pfPtrPlus1_w;
  logic [PTR_W:0] ifuWbPtr_w, commPtr_w, commPtrPlus1_w, robCommPtr_w;

  wire [PTR_W:0] validEntries = ptr_dist(bpuPtr, commPtr);
  wire           canCommit;                // 由 commit 段驱动
  wire           canMoveCommPtr;           // 由 commit 段驱动

  // ===========================================================================
  // ① enq from BPU（对应 Scala 614-760）
  // ===========================================================================
  // 队列有空位或本拍能提交，则可接收 BPU 新块
  wire new_entry_ready = ~validEntries[PTR_W] | canCommit;   // validEntries<64 等价于 bit6==0
  assign io_fromBpu_resp_ready = new_entry_ready;

  // BPU s2/s3 是否要求重定向（覆盖更早一级的预测）
  wire bpu_s2_redirect = io_fromBpu_resp_bits_s2_valid_3 & io_fromBpu_resp_bits_s2_hasRedirect_3;
  wire bpu_s3_redirect = io_fromBpu_resp_bits_s3_valid_3 & io_fromBpu_resp_bits_s3_hasRedirect_3;

  assign io_toBpu_enq_ptr_flag  = bpuPtr[PTR_W];
  assign io_toBpu_enq_ptr_value = bpuPtr[PTR_W-1:0];

  wire enq_fire    = new_entry_ready & io_fromBpu_resp_valid & allow_bpu_in; // s1 正常入队
  wire bpu_in_fire = (new_entry_ready & io_fromBpu_resp_valid | bpu_s2_redirect | bpu_s3_redirect) & allow_bpu_in;

  // selectedResp：s3 重定向 > s2 重定向 > s1。入队级别与写入 ptr 随之选择。
  wire [1:0]  bpu_in_stage = bpu_s3_redirect ? BP_S3 : (bpu_s2_redirect ? BP_S2 : BP_S1);
  wire [49:0] bpu_in_pc =
    bpu_s3_redirect ? io_fromBpu_resp_bits_s3_pc_3 :
    bpu_s2_redirect ? io_fromBpu_resp_bits_s2_pc_3 : io_fromBpu_resp_bits_s1_pc_3;
  wire        bpu_in_fallThroughErr =
    bpu_s3_redirect ? io_fromBpu_resp_bits_s3_full_pred_3_fallThroughErr :
    bpu_s2_redirect ? io_fromBpu_resp_bits_s2_full_pred_3_fallThroughErr :
                      io_fromBpu_resp_bits_s1_full_pred_3_fallThroughErr;
  wire        bpu_in_hit =
    bpu_s3_redirect ? io_fromBpu_resp_bits_s3_full_pred_3_hit :
    bpu_s2_redirect ? io_fromBpu_resp_bits_s2_full_pred_3_hit :
                      io_fromBpu_resp_bits_s1_full_pred_3_hit;
  // 写入哪个 FTQ 项：s1 入队写 bpuPtr，s2/s3 覆盖写各自携带的 ftq_idx
  wire [5:0]  bpu_in_ptr_value =
    (bpu_in_stage == BP_S1) ? bpuPtr[PTR_W-1:0] :
    bpu_s3_redirect ? io_fromBpu_resp_bits_s3_ftq_idx_value :
    bpu_s2_redirect ? io_fromBpu_resp_bits_s2_ftq_idx_value : 6'h0;
  wire        bpu_in_ptr_flag =
    (bpu_in_stage == BP_S1) ? bpuPtr[PTR_W] :
    bpu_s3_redirect ? io_fromBpu_resp_bits_s3_ftq_idx_flag :
    bpu_s2_redirect ? io_fromBpu_resp_bits_s2_ftq_idx_flag : 1'b0;
  wire [PTR_W:0] bpu_in_ptr = mk_ptr(bpu_in_ptr_flag, bpu_in_ptr_value);

  // 写入 ftq_pc_mem 的 PC 元信息（Ftq_RF_Components.fromBranchPrediction）
  wire [49:0] pcmem_wdata_startAddr    = bpu_in_pc;
  wire [49:0] pcmem_wdata_nextLineAddr = bpu_in_pc + 50'h40;       // +FetchWidth*4*2 = +64
  wire        pcmem_wdata_fallThruErr  = bpu_in_hit & bpu_in_fallThroughErr;

  // ---- 选当前级 full_pred 的各槽信息（cfiIndex / target 计算用）----
  wire        fp_br_taken_0 = bpu_s3_redirect ? io_fromBpu_resp_bits_s3_full_pred_3_br_taken_mask_0 :
                              bpu_s2_redirect ? io_fromBpu_resp_bits_s2_full_pred_3_br_taken_mask_0 :
                                                io_fromBpu_resp_bits_s1_full_pred_3_br_taken_mask_0;
  wire        fp_br_taken_1 = bpu_s3_redirect ? io_fromBpu_resp_bits_s3_full_pred_3_br_taken_mask_1 :
                              bpu_s2_redirect ? io_fromBpu_resp_bits_s2_full_pred_3_br_taken_mask_1 :
                                                io_fromBpu_resp_bits_s1_full_pred_3_br_taken_mask_1;
  wire        fp_slot_valid_0 = bpu_s3_redirect ? io_fromBpu_resp_bits_s3_full_pred_3_slot_valids_0 :
                                bpu_s2_redirect ? io_fromBpu_resp_bits_s2_full_pred_3_slot_valids_0 :
                                                  io_fromBpu_resp_bits_s1_full_pred_3_slot_valids_0;
  wire        fp_slot_valid_1 = bpu_s3_redirect ? io_fromBpu_resp_bits_s3_full_pred_3_slot_valids_1 :
                                bpu_s2_redirect ? io_fromBpu_resp_bits_s2_full_pred_3_slot_valids_1 :
                                                  io_fromBpu_resp_bits_s1_full_pred_3_slot_valids_1;
  wire [3:0]  fp_offset_0 = bpu_s3_redirect ? io_fromBpu_resp_bits_s3_full_pred_3_offsets_0 :
                            bpu_s2_redirect ? io_fromBpu_resp_bits_s2_full_pred_3_offsets_0 :
                                              io_fromBpu_resp_bits_s1_full_pred_3_offsets_0;
  wire [3:0]  fp_offset_1 = bpu_s3_redirect ? io_fromBpu_resp_bits_s3_full_pred_3_offsets_1 :
                            bpu_s2_redirect ? io_fromBpu_resp_bits_s2_full_pred_3_offsets_1 :
                                              io_fromBpu_resp_bits_s1_full_pred_3_offsets_1;
  wire [49:0] fp_target_0 = bpu_s3_redirect ? io_fromBpu_resp_bits_s3_full_pred_3_targets_0 :
                            bpu_s2_redirect ? io_fromBpu_resp_bits_s2_full_pred_3_targets_0 :
                                              io_fromBpu_resp_bits_s1_full_pred_3_targets_0;
  wire [49:0] fp_target_1 = bpu_s3_redirect ? io_fromBpu_resp_bits_s3_full_pred_3_targets_1 :
                            bpu_s2_redirect ? io_fromBpu_resp_bits_s2_full_pred_3_targets_1 :
                                              io_fromBpu_resp_bits_s1_full_pred_3_targets_1;
  wire [49:0] fp_fallThru = bpu_s3_redirect ? io_fromBpu_resp_bits_s3_full_pred_3_fallThroughAddr :
                            bpu_s2_redirect ? io_fromBpu_resp_bits_s2_full_pred_3_fallThroughAddr :
                                              io_fromBpu_resp_bits_s1_full_pred_3_fallThroughAddr;
  wire        fp_is_br_sharing = bpu_s3_redirect ? io_fromBpu_resp_bits_s3_full_pred_3_is_br_sharing :
                                 bpu_s2_redirect ? io_fromBpu_resp_bits_s2_full_pred_3_is_br_sharing :
                                                   io_fromBpu_resp_bits_s1_full_pred_3_is_br_sharing;

  // taken_mask_on_slot（FrontendBundle.taken_mask_on_slot，numBr=2）：
  //   slot0 = slot_valid0 & br_taken0
  //   slot1 = slot_valid1 & (is_br_sharing ? br_taken1 : 1)   ← tail slot 非共享时恒"取"
  wire tm_slot0 = fp_slot_valid_0 & fp_br_taken_0;
  wire tm_slot1 = fp_slot_valid_1 & ((fp_is_br_sharing & fp_br_taken_1) | ~fp_is_br_sharing);
  // real_slot_taken_mask = taken_mask_on_slot & hit
  wire rstm0 = tm_slot0 & bpu_in_hit;
  wire rstm1 = tm_slot1 & bpu_in_hit;
  // cfiIndex：有 taken 则取首个 taken 槽的 offset，否则置 PredictWidth-1(=15)
  wire        cfi_valid = rstm0 | rstm1;
  wire [3:0]  cfi_bits  = (rstm0 ? fp_offset_0 : (rstm1 ? fp_offset_1 : 4'hf))
                          | {4{~cfi_valid}};
  // target = selectByTaken([tm0,tm1], hit&!fallThruErr, [tgt0, tgt1, fallThru, pc+32])
  // 即 hit&!err 下按 taken 选目标；首个 taken 槽的 target，否则 fallThru；不命中则 pc+32
  wire        sel_ok  = bpu_in_hit & ~bpu_in_fallThroughErr;   // selectByTaken 的 cond
  // selectByTaken(taken_mask_on_slot, sel_ok, [tgt0, tgt1, fallThru, pc+32])：
  //   sel_ok 时按首个 taken 槽选 target，全不 taken 取 fallThru；!sel_ok（不命中/越界）取 pc+32
  wire [49:0] bpu_target =
    !sel_ok        ? (bpu_in_pc + 50'h20) :
    tm_slot0       ? fp_target_0 :
    tm_slot1       ? fp_target_1 :
                     fp_fallThru;

  // ===========================================================================
  // 存储子模块（golden 同名黑盒；各自已单独验证为可读）
  // ===========================================================================
  // ---- ftq_pc_mem：每块 PC 元信息（7 读口 + 1 写口，读提前一拍）----
  wire [49:0] pcmem_ifuPtr_startAddr, pcmem_ifuPtr_nextLineAddr;
  wire        pcmem_ifuPtr_fallThruErr;
  wire [49:0] pcmem_ifuP1_startAddr, pcmem_ifuP1_nextLineAddr;
  wire        pcmem_ifuP1_fallThruErr;
  wire [49:0] pcmem_ifuP2_startAddr;
  wire [49:0] pcmem_pfPtr_startAddr, pcmem_pfPtr_nextLineAddr;
  wire [49:0] pcmem_pfP1_startAddr, pcmem_pfP1_nextLineAddr;
  wire [49:0] pcmem_commPtr_startAddr, pcmem_commP1_startAddr;

  FtqPcMemWrapper ftq_pc_mem (
    .clock(clock), .reset(reset),
    // 读口提前用"下拍"指针写线（读延迟 1 拍 → 下拍读出对应当拍指针）
    .io_ifuPtr_w_value      (ifuPtr_w[PTR_W-1:0]),
    .io_ifuPtrPlus1_w_value (ifuPtrPlus1_w[PTR_W-1:0]),
    .io_ifuPtrPlus2_w_value (ifuPtrPlus2_w[PTR_W-1:0]),
    .io_pfPtr_w_value       (pfPtr_w[PTR_W-1:0]),
    .io_pfPtrPlus1_w_value  (pfPtrPlus1_w[PTR_W-1:0]),
    .io_commPtr_w_value     (commPtr_w[PTR_W-1:0]),
    .io_commPtrPlus1_w_value(commPtrPlus1_w[PTR_W-1:0]),
    .io_ifuPtr_rdata_startAddr      (pcmem_ifuPtr_startAddr),
    .io_ifuPtr_rdata_nextLineAddr   (pcmem_ifuPtr_nextLineAddr),
    .io_ifuPtr_rdata_fallThruError  (pcmem_ifuPtr_fallThruErr),
    .io_ifuPtrPlus1_rdata_startAddr     (pcmem_ifuP1_startAddr),
    .io_ifuPtrPlus1_rdata_nextLineAddr  (pcmem_ifuP1_nextLineAddr),
    .io_ifuPtrPlus1_rdata_fallThruError (pcmem_ifuP1_fallThruErr),
    .io_ifuPtrPlus2_rdata_startAddr (pcmem_ifuP2_startAddr),
    .io_pfPtr_rdata_startAddr       (pcmem_pfPtr_startAddr),
    .io_pfPtr_rdata_nextLineAddr    (pcmem_pfPtr_nextLineAddr),
    .io_pfPtrPlus1_rdata_startAddr  (pcmem_pfP1_startAddr),
    .io_pfPtrPlus1_rdata_nextLineAddr(pcmem_pfP1_nextLineAddr),
    .io_commPtr_rdata_startAddr     (pcmem_commPtr_startAddr),
    .io_commPtrPlus1_rdata_startAddr(pcmem_commP1_startAddr),
    .io_wen  (bpu_in_fire),
    .io_waddr(bpu_in_ptr_value),
    .io_wdata_startAddr   (pcmem_wdata_startAddr),
    .io_wdata_nextLineAddr(pcmem_wdata_nextLineAddr),
    .io_wdata_fallThruError(pcmem_wdata_fallThruErr)
  );

  // ---- redirect_mem 与 pd_mem / ftb_entry_mem 的读地址/读使能（redirect 段构造）----
  // 端口 0(ifuRedirect), 1(backendRedirect/ahead0), 2(commit)；ahead1..3 复用高位读口（本配置 FtqRedirectAheadNum=1，故只用 0）
  logic        redir_ren0, redir_ren1, redir_ren2;
  logic [5:0]  redir_raddr0, redir_raddr1, redir_raddr2;
  // ftq_redirect_mem 读出（spec_info）
  wire        rdm0_histPtr_flag;  wire [7:0] rdm0_histPtr_value;
  wire [3:0]  rdm0_ssp;  wire [2:0] rdm0_sctr;
  wire        rdm0_TOSW_flag; wire [4:0] rdm0_TOSW_value;
  wire        rdm0_TOSR_flag; wire [4:0] rdm0_TOSR_value;
  wire        rdm0_NOS_flag;  wire [4:0] rdm0_NOS_value;  wire [49:0] rdm0_topAddr;
  wire        rdm1_histPtr_flag;  wire [7:0] rdm1_histPtr_value;
  wire [3:0]  rdm1_ssp;  wire [2:0] rdm1_sctr;
  wire        rdm1_TOSW_flag; wire [4:0] rdm1_TOSW_value;
  wire        rdm1_TOSR_flag; wire [4:0] rdm1_TOSR_value;
  wire        rdm1_NOS_flag;  wire [4:0] rdm1_NOS_value;
  wire        rdm1_sc_disagree_0, rdm1_sc_disagree_1;

  SyncDataModuleTemplate__64entry ftq_redirect_mem (
    .clock(clock), .reset(reset),
    .io_ren_0(redir_ren0), .io_ren_1(redir_ren1), .io_ren_2(redir_ren2),
    .io_raddr_0(redir_raddr0), .io_raddr_1(redir_raddr1), .io_raddr_2(redir_raddr2),
    .io_rdata_0_histPtr_flag(rdm0_histPtr_flag), .io_rdata_0_histPtr_value(rdm0_histPtr_value),
    .io_rdata_0_ssp(rdm0_ssp), .io_rdata_0_sctr(rdm0_sctr),
    .io_rdata_0_TOSW_flag(rdm0_TOSW_flag), .io_rdata_0_TOSW_value(rdm0_TOSW_value),
    .io_rdata_0_TOSR_flag(rdm0_TOSR_flag), .io_rdata_0_TOSR_value(rdm0_TOSR_value),
    .io_rdata_0_NOS_flag(rdm0_NOS_flag), .io_rdata_0_NOS_value(rdm0_NOS_value),
    .io_rdata_0_topAddr(rdm0_topAddr),
    .io_rdata_1_histPtr_flag(rdm1_histPtr_flag), .io_rdata_1_histPtr_value(rdm1_histPtr_value),
    .io_rdata_1_ssp(rdm1_ssp), .io_rdata_1_sctr(rdm1_sctr),
    .io_rdata_1_TOSW_flag(rdm1_TOSW_flag), .io_rdata_1_TOSW_value(rdm1_TOSW_value),
    .io_rdata_1_TOSR_flag(rdm1_TOSR_flag), .io_rdata_1_TOSR_value(rdm1_TOSR_value),
    .io_rdata_1_NOS_flag(rdm1_NOS_flag), .io_rdata_1_NOS_value(rdm1_NOS_value),
    .io_rdata_1_sc_disagree_0(rdm1_sc_disagree_0), .io_rdata_1_sc_disagree_1(rdm1_sc_disagree_1),
    .io_rdata_2_histPtr_value(io_toBpu_update_bits_spec_info_histPtr_value),
    .io_wen_0  (io_fromBpu_resp_bits_s3_valid_3),
    .io_waddr_0(io_fromBpu_resp_bits_s3_ftq_idx_value),
    .io_wdata_0_histPtr_flag (io_fromBpu_resp_bits_last_stage_spec_info_histPtr_flag),
    .io_wdata_0_histPtr_value(io_fromBpu_resp_bits_last_stage_spec_info_histPtr_value),
    .io_wdata_0_ssp (io_fromBpu_resp_bits_last_stage_spec_info_ssp),
    .io_wdata_0_sctr(io_fromBpu_resp_bits_last_stage_spec_info_sctr),
    .io_wdata_0_TOSW_flag (io_fromBpu_resp_bits_last_stage_spec_info_TOSW_flag),
    .io_wdata_0_TOSW_value(io_fromBpu_resp_bits_last_stage_spec_info_TOSW_value),
    .io_wdata_0_TOSR_flag (io_fromBpu_resp_bits_last_stage_spec_info_TOSR_flag),
    .io_wdata_0_TOSR_value(io_fromBpu_resp_bits_last_stage_spec_info_TOSR_value),
    .io_wdata_0_NOS_flag (io_fromBpu_resp_bits_last_stage_spec_info_NOS_flag),
    .io_wdata_0_NOS_value(io_fromBpu_resp_bits_last_stage_spec_info_NOS_value),
    .io_wdata_0_topAddr  (io_fromBpu_resp_bits_last_stage_spec_info_topAddr),
    .io_wdata_0_sc_disagree_0(io_fromBpu_resp_bits_last_stage_spec_info_sc_disagree_0),
    .io_wdata_0_sc_disagree_1(io_fromBpu_resp_bits_last_stage_spec_info_sc_disagree_1)
  );

  // ---- ftq_pd_mem 写数据：Ftq_pd_Entry.fromPdWb（把 16 槽 pd 压成块级预解码信息）----
  // brType 编码：1=条件分支(isBr)，2=jal，3=jalr。jmpInfo 记块尾唯一跳转的类型。
  logic [PREDICT_W-1:0] pd_is_jmp;       // 该槽是 jal/jalr
  logic [PREDICT_W-1:0] pd_brMask_w;     // 该槽是条件分支
  always_comb begin
    for (int i = 0; i < PREDICT_W; i++) begin
      pd_is_jmp[i]   = (pdwb_pd_brType[i] == 2'd2 || pdwb_pd_brType[i] == 2'd3) & pdwb_pd_valid[i];
      pd_brMask_w[i] = (pdwb_pd_brType[i] == 2'd1) & pdwb_pd_valid[i];
    end
  end
  wire        pd_jmpInfo_valid = |pd_is_jmp;
  // ParallelPriorityEncoder：首个 jmp 槽的下标
  logic [3:0] pd_jmpOffset;
  logic       pd_jmp_isJalr, pd_jmp_isCall, pd_jmp_isRet;
  always_comb begin
    pd_jmpOffset  = 4'd0;
    pd_jmp_isJalr = 1'b0; pd_jmp_isCall = 1'b0; pd_jmp_isRet = 1'b0;
    for (int i = PREDICT_W-1; i >= 0; i--) begin
      if (pd_is_jmp[i]) begin
        pd_jmpOffset  = i[3:0];
        pd_jmp_isJalr = (pdwb_pd_brType[i] == 2'd3); // jalr 即 brType==3
        pd_jmp_isCall = pdwb_pd_isCall[i];
        pd_jmp_isRet  = pdwb_pd_isRet[i];
      end
    end
  end

  // ---- ftb_entry_mem / ftq_pd_mem 读出（redirect/commit 用）----
  wire        ftbm0_isCall, ftbm0_isRet, ftbm0_isJalr;
  wire [3:0]  ftbm0_brSlots0_offset; wire ftbm0_brSlots0_valid;
  wire [3:0]  ftbm0_tailSlot_offset; wire ftbm0_tailSlot_sharing, ftbm0_tailSlot_valid;
  wire        ftbm1_isJalr;
  wire [3:0]  ftbm1_brSlots0_offset; wire ftbm1_brSlots0_valid;
  wire [3:0]  ftbm1_tailSlot_offset; wire ftbm1_tailSlot_sharing, ftbm1_tailSlot_valid;

  SyncDataModuleTemplate__64entry_1 ftb_entry_mem (
    .clock(clock), .reset(reset),
    .io_ren_0(io_fromIfu_pdWb_valid), .io_ren_1(redir_ren1),
    .io_raddr_0(io_fromIfu_pdWb_bits_ftqIdx_value), .io_raddr_1(redir_raddr1),
    .io_rdata_0_isCall(ftbm0_isCall), .io_rdata_0_isRet(ftbm0_isRet), .io_rdata_0_isJalr(ftbm0_isJalr),
    .io_rdata_0_brSlots_0_offset(ftbm0_brSlots0_offset), .io_rdata_0_brSlots_0_valid(ftbm0_brSlots0_valid),
    .io_rdata_0_tailSlot_offset(ftbm0_tailSlot_offset), .io_rdata_0_tailSlot_sharing(ftbm0_tailSlot_sharing),
    .io_rdata_0_tailSlot_valid(ftbm0_tailSlot_valid),
    .io_rdata_1_isJalr(ftbm1_isJalr),
    .io_rdata_1_brSlots_0_offset(ftbm1_brSlots0_offset), .io_rdata_1_brSlots_0_valid(ftbm1_brSlots0_valid),
    .io_rdata_1_tailSlot_offset(ftbm1_tailSlot_offset), .io_rdata_1_tailSlot_sharing(ftbm1_tailSlot_sharing),
    .io_rdata_1_tailSlot_valid(ftbm1_tailSlot_valid),
    .io_wen_0  (io_fromBpu_resp_bits_s3_valid_3),
    .io_waddr_0(io_fromBpu_resp_bits_s3_ftq_idx_value),
    .io_wdata_0_isCall(io_fromBpu_resp_bits_last_stage_ftb_entry_isCall),
    .io_wdata_0_isRet (io_fromBpu_resp_bits_last_stage_ftb_entry_isRet),
    .io_wdata_0_isJalr(io_fromBpu_resp_bits_last_stage_ftb_entry_isJalr),
    .io_wdata_0_brSlots_0_offset (io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_offset),
    .io_wdata_0_brSlots_0_valid  (io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_valid),
    .io_wdata_0_tailSlot_offset  (io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_offset),
    .io_wdata_0_tailSlot_sharing (io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_sharing),
    .io_wdata_0_tailSlot_valid   (io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_valid)
  );

  // ftq_pd_mem 读出 0(redirect) / 1(commit)
  logic [PREDICT_W-1:0] pdm0_brMask, pdm0_rvcMask, pdm1_brMask, pdm1_rvcMask;
  wire        pdm0_jmpInfo_valid, pdm0_jmpInfo_b0, pdm0_jmpInfo_b1, pdm0_jmpInfo_b2;
  wire [3:0]  pdm0_jmpOffset;
  wire        pdm1_jmpInfo_valid, pdm1_jmpInfo_b0, pdm1_jmpInfo_b1, pdm1_jmpInfo_b2;
  wire [3:0]  pdm1_jmpOffset; wire [49:0] pdm1_jalTarget;

  SyncDataModuleTemplate__64entry_2 ftq_pd_mem (
    .clock(clock), .reset(reset),
    .io_ren_0(redir_ren1), .io_ren_1(canCommit),
    .io_raddr_0(redir_raddr1), .io_raddr_1(commPtr[PTR_W-1:0]),
    .io_rdata_0_brMask_0(pdm0_brMask[0]),   .io_rdata_0_brMask_1(pdm0_brMask[1]),
    .io_rdata_0_brMask_2(pdm0_brMask[2]),   .io_rdata_0_brMask_3(pdm0_brMask[3]),
    .io_rdata_0_brMask_4(pdm0_brMask[4]),   .io_rdata_0_brMask_5(pdm0_brMask[5]),
    .io_rdata_0_brMask_6(pdm0_brMask[6]),   .io_rdata_0_brMask_7(pdm0_brMask[7]),
    .io_rdata_0_brMask_8(pdm0_brMask[8]),   .io_rdata_0_brMask_9(pdm0_brMask[9]),
    .io_rdata_0_brMask_10(pdm0_brMask[10]), .io_rdata_0_brMask_11(pdm0_brMask[11]),
    .io_rdata_0_brMask_12(pdm0_brMask[12]), .io_rdata_0_brMask_13(pdm0_brMask[13]),
    .io_rdata_0_brMask_14(pdm0_brMask[14]), .io_rdata_0_brMask_15(pdm0_brMask[15]),
    .io_rdata_0_jmpInfo_valid(pdm0_jmpInfo_valid),
    .io_rdata_0_jmpInfo_bits_0(pdm0_jmpInfo_b0), .io_rdata_0_jmpInfo_bits_1(pdm0_jmpInfo_b1),
    .io_rdata_0_jmpInfo_bits_2(pdm0_jmpInfo_b2), .io_rdata_0_jmpOffset(pdm0_jmpOffset),
    .io_rdata_0_rvcMask_0(pdm0_rvcMask[0]),   .io_rdata_0_rvcMask_1(pdm0_rvcMask[1]),
    .io_rdata_0_rvcMask_2(pdm0_rvcMask[2]),   .io_rdata_0_rvcMask_3(pdm0_rvcMask[3]),
    .io_rdata_0_rvcMask_4(pdm0_rvcMask[4]),   .io_rdata_0_rvcMask_5(pdm0_rvcMask[5]),
    .io_rdata_0_rvcMask_6(pdm0_rvcMask[6]),   .io_rdata_0_rvcMask_7(pdm0_rvcMask[7]),
    .io_rdata_0_rvcMask_8(pdm0_rvcMask[8]),   .io_rdata_0_rvcMask_9(pdm0_rvcMask[9]),
    .io_rdata_0_rvcMask_10(pdm0_rvcMask[10]), .io_rdata_0_rvcMask_11(pdm0_rvcMask[11]),
    .io_rdata_0_rvcMask_12(pdm0_rvcMask[12]), .io_rdata_0_rvcMask_13(pdm0_rvcMask[13]),
    .io_rdata_0_rvcMask_14(pdm0_rvcMask[14]), .io_rdata_0_rvcMask_15(pdm0_rvcMask[15]),
    .io_rdata_1_brMask_0(pdm1_brMask[0]),   .io_rdata_1_brMask_1(pdm1_brMask[1]),
    .io_rdata_1_brMask_2(pdm1_brMask[2]),   .io_rdata_1_brMask_3(pdm1_brMask[3]),
    .io_rdata_1_brMask_4(pdm1_brMask[4]),   .io_rdata_1_brMask_5(pdm1_brMask[5]),
    .io_rdata_1_brMask_6(pdm1_brMask[6]),   .io_rdata_1_brMask_7(pdm1_brMask[7]),
    .io_rdata_1_brMask_8(pdm1_brMask[8]),   .io_rdata_1_brMask_9(pdm1_brMask[9]),
    .io_rdata_1_brMask_10(pdm1_brMask[10]), .io_rdata_1_brMask_11(pdm1_brMask[11]),
    .io_rdata_1_brMask_12(pdm1_brMask[12]), .io_rdata_1_brMask_13(pdm1_brMask[13]),
    .io_rdata_1_brMask_14(pdm1_brMask[14]), .io_rdata_1_brMask_15(pdm1_brMask[15]),
    .io_rdata_1_jmpInfo_valid(pdm1_jmpInfo_valid),
    .io_rdata_1_jmpInfo_bits_0(pdm1_jmpInfo_b0), .io_rdata_1_jmpInfo_bits_1(pdm1_jmpInfo_b1),
    .io_rdata_1_jmpInfo_bits_2(pdm1_jmpInfo_b2), .io_rdata_1_jmpOffset(pdm1_jmpOffset),
    .io_rdata_1_jalTarget(pdm1_jalTarget),
    .io_rdata_1_rvcMask_0(pdm1_rvcMask[0]),   .io_rdata_1_rvcMask_1(pdm1_rvcMask[1]),
    .io_rdata_1_rvcMask_2(pdm1_rvcMask[2]),   .io_rdata_1_rvcMask_3(pdm1_rvcMask[3]),
    .io_rdata_1_rvcMask_4(pdm1_rvcMask[4]),   .io_rdata_1_rvcMask_5(pdm1_rvcMask[5]),
    .io_rdata_1_rvcMask_6(pdm1_rvcMask[6]),   .io_rdata_1_rvcMask_7(pdm1_rvcMask[7]),
    .io_rdata_1_rvcMask_8(pdm1_rvcMask[8]),   .io_rdata_1_rvcMask_9(pdm1_rvcMask[9]),
    .io_rdata_1_rvcMask_10(pdm1_rvcMask[10]), .io_rdata_1_rvcMask_11(pdm1_rvcMask[11]),
    .io_rdata_1_rvcMask_12(pdm1_rvcMask[12]), .io_rdata_1_rvcMask_13(pdm1_rvcMask[13]),
    .io_rdata_1_rvcMask_14(pdm1_rvcMask[14]), .io_rdata_1_rvcMask_15(pdm1_rvcMask[15]),
    .io_wen_0  (io_fromIfu_pdWb_valid),
    .io_waddr_0(io_fromIfu_pdWb_bits_ftqIdx_value),
    .io_wdata_0_brMask_0(pd_brMask_w[0]),   .io_wdata_0_brMask_1(pd_brMask_w[1]),
    .io_wdata_0_brMask_2(pd_brMask_w[2]),   .io_wdata_0_brMask_3(pd_brMask_w[3]),
    .io_wdata_0_brMask_4(pd_brMask_w[4]),   .io_wdata_0_brMask_5(pd_brMask_w[5]),
    .io_wdata_0_brMask_6(pd_brMask_w[6]),   .io_wdata_0_brMask_7(pd_brMask_w[7]),
    .io_wdata_0_brMask_8(pd_brMask_w[8]),   .io_wdata_0_brMask_9(pd_brMask_w[9]),
    .io_wdata_0_brMask_10(pd_brMask_w[10]), .io_wdata_0_brMask_11(pd_brMask_w[11]),
    .io_wdata_0_brMask_12(pd_brMask_w[12]), .io_wdata_0_brMask_13(pd_brMask_w[13]),
    .io_wdata_0_brMask_14(pd_brMask_w[14]), .io_wdata_0_brMask_15(pd_brMask_w[15]),
    .io_wdata_0_jmpInfo_valid(pd_jmpInfo_valid),
    .io_wdata_0_jmpInfo_bits_0(pd_jmp_isJalr), .io_wdata_0_jmpInfo_bits_1(pd_jmp_isCall),
    .io_wdata_0_jmpInfo_bits_2(pd_jmp_isRet), .io_wdata_0_jmpOffset(pd_jmpOffset),
    .io_wdata_0_jalTarget(io_fromIfu_pdWb_bits_jalTarget),
    .io_wdata_0_rvcMask_0(pdwb_pd_isRVC[0]),   .io_wdata_0_rvcMask_1(pdwb_pd_isRVC[1]),
    .io_wdata_0_rvcMask_2(pdwb_pd_isRVC[2]),   .io_wdata_0_rvcMask_3(pdwb_pd_isRVC[3]),
    .io_wdata_0_rvcMask_4(pdwb_pd_isRVC[4]),   .io_wdata_0_rvcMask_5(pdwb_pd_isRVC[5]),
    .io_wdata_0_rvcMask_6(pdwb_pd_isRVC[6]),   .io_wdata_0_rvcMask_7(pdwb_pd_isRVC[7]),
    .io_wdata_0_rvcMask_8(pdwb_pd_isRVC[8]),   .io_wdata_0_rvcMask_9(pdwb_pd_isRVC[9]),
    .io_wdata_0_rvcMask_10(pdwb_pd_isRVC[10]), .io_wdata_0_rvcMask_11(pdwb_pd_isRVC[11]),
    .io_wdata_0_rvcMask_12(pdwb_pd_isRVC[12]), .io_wdata_0_rvcMask_13(pdwb_pd_isRVC[13]),
    .io_wdata_0_rvcMask_14(pdwb_pd_isRVC[14]), .io_wdata_0_rvcMask_15(pdwb_pd_isRVC[15])
  );

  // ---- ftq_meta_1r_sram：预测器 meta + 预测时 ftb_entry（仅 commit 读，容量大用 SplittedSRAM）----
  // 读出的 ftb_entry 即 commit_ftb_entry，喂给 FTBEntryGen 当 old_entry；meta 直接送 update。
  wire        meta_ftb_isCall, meta_ftb_isRet, meta_ftb_isJalr, meta_ftb_valid;
  wire [3:0]  meta_ftb_brSlots0_offset; wire meta_ftb_brSlots0_sharing, meta_ftb_brSlots0_valid;
  wire [11:0] meta_ftb_brSlots0_lower;  wire [1:0] meta_ftb_brSlots0_tarStat;
  wire [3:0]  meta_ftb_tailSlot_offset; wire meta_ftb_tailSlot_sharing, meta_ftb_tailSlot_valid;
  wire [19:0] meta_ftb_tailSlot_lower;  wire [1:0] meta_ftb_tailSlot_tarStat;
  wire [3:0]  meta_ftb_pftAddr; wire meta_ftb_carry, meta_ftb_lastRviCall;
  wire        meta_ftb_strongBias0, meta_ftb_strongBias1;
  // bore（MBIST）总线：ftq_meta_1r_sram(4 个内层 SRAM) ↔ MbistPipeFtq ↔ Ftq 顶层 MBIST 端口
  wire [6:0]   childBd_addr [4]; wire [6:0] childBd_addr_rd [4];
  wire [143:0] childBd_wdata [4]; wire childBd_wmask [4];
  wire         childBd_re [4], childBd_we [4], childBd_ack [4], childBd_selOH [4];
  wire [143:0] childBd_rdata [4]; wire [6:0] childBd_array [4];
  wire [143:0] bd_outdata; wire bd_ack;

  FtqNRSRAM ftq_meta_1r_sram (
    .clock(clock), .reset(reset),
    .io_raddr_0(commPtr[PTR_W-1:0]), .io_ren_0(canCommit),
    .io_rdata_0_meta(io_toBpu_update_bits_meta),
    .io_rdata_0_ftb_entry_isCall(meta_ftb_isCall), .io_rdata_0_ftb_entry_isRet(meta_ftb_isRet),
    .io_rdata_0_ftb_entry_isJalr(meta_ftb_isJalr), .io_rdata_0_ftb_entry_valid(meta_ftb_valid),
    .io_rdata_0_ftb_entry_brSlots_0_offset(meta_ftb_brSlots0_offset),
    .io_rdata_0_ftb_entry_brSlots_0_sharing(meta_ftb_brSlots0_sharing),
    .io_rdata_0_ftb_entry_brSlots_0_valid(meta_ftb_brSlots0_valid),
    .io_rdata_0_ftb_entry_brSlots_0_lower(meta_ftb_brSlots0_lower),
    .io_rdata_0_ftb_entry_brSlots_0_tarStat(meta_ftb_brSlots0_tarStat),
    .io_rdata_0_ftb_entry_tailSlot_offset(meta_ftb_tailSlot_offset),
    .io_rdata_0_ftb_entry_tailSlot_sharing(meta_ftb_tailSlot_sharing),
    .io_rdata_0_ftb_entry_tailSlot_valid(meta_ftb_tailSlot_valid),
    .io_rdata_0_ftb_entry_tailSlot_lower(meta_ftb_tailSlot_lower),
    .io_rdata_0_ftb_entry_tailSlot_tarStat(meta_ftb_tailSlot_tarStat),
    .io_rdata_0_ftb_entry_pftAddr(meta_ftb_pftAddr), .io_rdata_0_ftb_entry_carry(meta_ftb_carry),
    .io_rdata_0_ftb_entry_last_may_be_rvi_call(meta_ftb_lastRviCall),
    .io_rdata_0_ftb_entry_strong_bias_0(meta_ftb_strongBias0),
    .io_rdata_0_ftb_entry_strong_bias_1(meta_ftb_strongBias1),
    .io_waddr(io_fromBpu_resp_bits_s3_ftq_idx_value), .io_wen(io_fromBpu_resp_bits_s3_valid_3),
    .io_wdata_meta(io_fromBpu_resp_bits_last_stage_meta),
    .io_wdata_ftb_entry_isCall(io_fromBpu_resp_bits_last_stage_ftb_entry_isCall),
    .io_wdata_ftb_entry_isRet (io_fromBpu_resp_bits_last_stage_ftb_entry_isRet),
    .io_wdata_ftb_entry_isJalr(io_fromBpu_resp_bits_last_stage_ftb_entry_isJalr),
    .io_wdata_ftb_entry_valid (io_fromBpu_resp_bits_last_stage_ftb_entry_valid),
    .io_wdata_ftb_entry_brSlots_0_offset (io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_offset),
    .io_wdata_ftb_entry_brSlots_0_sharing(io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_sharing),
    .io_wdata_ftb_entry_brSlots_0_valid  (io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_valid),
    .io_wdata_ftb_entry_brSlots_0_lower  (io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_lower),
    .io_wdata_ftb_entry_brSlots_0_tarStat(io_fromBpu_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat),
    .io_wdata_ftb_entry_tailSlot_offset (io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_offset),
    .io_wdata_ftb_entry_tailSlot_sharing(io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_sharing),
    .io_wdata_ftb_entry_tailSlot_valid  (io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_valid),
    .io_wdata_ftb_entry_tailSlot_lower  (io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_lower),
    .io_wdata_ftb_entry_tailSlot_tarStat(io_fromBpu_resp_bits_last_stage_ftb_entry_tailSlot_tarStat),
    .io_wdata_ftb_entry_pftAddr(io_fromBpu_resp_bits_last_stage_ftb_entry_pftAddr),
    .io_wdata_ftb_entry_carry  (io_fromBpu_resp_bits_last_stage_ftb_entry_carry),
    .io_wdata_ftb_entry_last_may_be_rvi_call(io_fromBpu_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call),
    .io_wdata_ftb_entry_strong_bias_0(io_fromBpu_resp_bits_last_stage_ftb_entry_strong_bias_0),
    .io_wdata_ftb_entry_strong_bias_1(io_fromBpu_resp_bits_last_stage_ftb_entry_strong_bias_1),
    .boreChildrenBd_bore_addr(childBd_addr[0]), .boreChildrenBd_bore_addr_rd(childBd_addr_rd[0]),
    .boreChildrenBd_bore_wdata(childBd_wdata[0]), .boreChildrenBd_bore_wmask(childBd_wmask[0]),
    .boreChildrenBd_bore_re(childBd_re[0]), .boreChildrenBd_bore_we(childBd_we[0]),
    .boreChildrenBd_bore_rdata(childBd_rdata[0]), .boreChildrenBd_bore_ack(childBd_ack[0]),
    .boreChildrenBd_bore_selectedOH(childBd_selOH[0]), .boreChildrenBd_bore_array(childBd_array[0]),
    .boreChildrenBd_bore_1_addr(childBd_addr[1]), .boreChildrenBd_bore_1_addr_rd(childBd_addr_rd[1]),
    .boreChildrenBd_bore_1_wdata(childBd_wdata[1]), .boreChildrenBd_bore_1_wmask(childBd_wmask[1]),
    .boreChildrenBd_bore_1_re(childBd_re[1]), .boreChildrenBd_bore_1_we(childBd_we[1]),
    .boreChildrenBd_bore_1_rdata(childBd_rdata[1]), .boreChildrenBd_bore_1_ack(childBd_ack[1]),
    .boreChildrenBd_bore_1_selectedOH(childBd_selOH[1]), .boreChildrenBd_bore_1_array(childBd_array[1]),
    .boreChildrenBd_bore_2_addr(childBd_addr[2]), .boreChildrenBd_bore_2_addr_rd(childBd_addr_rd[2]),
    .boreChildrenBd_bore_2_wdata(childBd_wdata[2]), .boreChildrenBd_bore_2_wmask(childBd_wmask[2]),
    .boreChildrenBd_bore_2_re(childBd_re[2]), .boreChildrenBd_bore_2_we(childBd_we[2]),
    .boreChildrenBd_bore_2_rdata(childBd_rdata[2]), .boreChildrenBd_bore_2_ack(childBd_ack[2]),
    .boreChildrenBd_bore_2_selectedOH(childBd_selOH[2]), .boreChildrenBd_bore_2_array(childBd_array[2]),
    .boreChildrenBd_bore_3_addr(childBd_addr[3]), .boreChildrenBd_bore_3_addr_rd(childBd_addr_rd[3]),
    .boreChildrenBd_bore_3_wdata(childBd_wdata[3]), .boreChildrenBd_bore_3_wmask(childBd_wmask[3]),
    .boreChildrenBd_bore_3_re(childBd_re[3]), .boreChildrenBd_bore_3_we(childBd_we[3]),
    .boreChildrenBd_bore_3_rdata(childBd_rdata[3]), .boreChildrenBd_bore_3_ack(childBd_ack[3]),
    .boreChildrenBd_bore_3_selectedOH(childBd_selOH[3]), .boreChildrenBd_bore_3_array(childBd_array[3]),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(sigFromSrams_bore_3_cgen)
  );

  // ---- MbistPipeFtq：把顶层 MBIST 总线分发给 4 个内层 SRAM 的 bore 口 ----
  MbistPipeFtq mbistPl (
    .clock(clock), .reset(reset),
    .mbist_array(boreChildrenBd_bore_array), .mbist_all(boreChildrenBd_bore_all),
    .mbist_req(boreChildrenBd_bore_req), .mbist_ack(bd_ack),
    .mbist_writeen(boreChildrenBd_bore_writeen), .mbist_be(boreChildrenBd_bore_be),
    .mbist_addr(boreChildrenBd_bore_addr), .mbist_indata(boreChildrenBd_bore_indata),
    .mbist_readen(boreChildrenBd_bore_readen), .mbist_addr_rd(boreChildrenBd_bore_addr_rd),
    .mbist_outdata(bd_outdata),
    .toSRAM_0_addr(childBd_addr[0]), .toSRAM_0_addr_rd(childBd_addr_rd[0]),
    .toSRAM_0_wdata(childBd_wdata[0]), .toSRAM_0_wmask(childBd_wmask[0]),
    .toSRAM_0_re(childBd_re[0]), .toSRAM_0_we(childBd_we[0]),
    .toSRAM_0_rdata(childBd_rdata[0]), .toSRAM_0_ack(childBd_ack[0]),
    .toSRAM_0_selectedOH(childBd_selOH[0]), .toSRAM_0_array(childBd_array[0]),
    .toSRAM_1_addr(childBd_addr[1]), .toSRAM_1_addr_rd(childBd_addr_rd[1]),
    .toSRAM_1_wdata(childBd_wdata[1]), .toSRAM_1_wmask(childBd_wmask[1]),
    .toSRAM_1_re(childBd_re[1]), .toSRAM_1_we(childBd_we[1]),
    .toSRAM_1_rdata(childBd_rdata[1]), .toSRAM_1_ack(childBd_ack[1]),
    .toSRAM_1_selectedOH(childBd_selOH[1]), .toSRAM_1_array(childBd_array[1]),
    .toSRAM_2_addr(childBd_addr[2]), .toSRAM_2_addr_rd(childBd_addr_rd[2]),
    .toSRAM_2_wdata(childBd_wdata[2]), .toSRAM_2_wmask(childBd_wmask[2]),
    .toSRAM_2_re(childBd_re[2]), .toSRAM_2_we(childBd_we[2]),
    .toSRAM_2_rdata(childBd_rdata[2]), .toSRAM_2_ack(childBd_ack[2]),
    .toSRAM_2_selectedOH(childBd_selOH[2]), .toSRAM_2_array(childBd_array[2]),
    .toSRAM_3_addr(childBd_addr[3]), .toSRAM_3_addr_rd(childBd_addr_rd[3]),
    .toSRAM_3_wdata(childBd_wdata[3]), .toSRAM_3_wmask(childBd_wmask[3]),
    .toSRAM_3_re(childBd_re[3]), .toSRAM_3_we(childBd_we[3]),
    .toSRAM_3_rdata(childBd_rdata[3]), .toSRAM_3_ack(childBd_ack[3]),
    .toSRAM_3_selectedOH(childBd_selOH[3]), .toSRAM_3_array(childBd_array[3])
  );
  assign boreChildrenBd_bore_ack     = bd_ack;
  assign boreChildrenBd_bore_outdata = bd_outdata;


  // ===========================================================================
  // 每项寄存器阵列（64 项；golden 用裸寄存器，本核用 SV 数组 + genvar 直接表达）
  // ===========================================================================
  reg  [PREDICT_W-1:0][1:0] commitStateQueue [FTQ_SIZE]; // 每项 16 槽指令的提交状态
  reg                       cfiIndex_valid   [FTQ_SIZE]; // 该块预测 taken 的槽
  reg  [3:0]                cfiIndex_bits     [FTQ_SIZE];
  reg  [PREDICT_W-1:0]      mispred_block     [FTQ_SIZE]; // 每槽是否误预测
  reg                       entry_fetch_status[FTQ_SIZE]; // F_TO_SEND / F_SENT
  reg  [1:0]                entry_hit_status  [FTQ_SIZE]; // H_NOT_HIT / H_FALSE_HIT / H_HIT
  reg  [1:0]                pred_stage        [FTQ_SIZE]; // 该块由 BPU 哪一级产生
  reg  [49:0]              update_target     [FTQ_SIZE]; // 该块最新目标
  reg                       ifuRedirected     [FTQ_SIZE]; // 该块是否被 IFU 预解码重定向过

  reg  [49:0]              newest_entry_target;       reg newest_entry_target_modified;
  reg  [PTR_W:0]           newest_entry_ptr;          reg newest_entry_ptr_modified;
  reg  [1:0]               bpu_ftb_update_stall;      // FTB 更新 2 拍 stall 状态机
  reg  [1:0]               backendException;          // ExceptionType (none/pf/gpf/af)
  reg  [PTR_W:0]           backendPcFaultPtr;

  // ---- enq 打一拍信号（reduce critical path，对应 Scala 705-716）----
  reg            last_cycle_bpu_in;
  reg  [PTR_W:0] last_cycle_bpu_in_ptr;
  reg  [49:0]    last_cycle_bpu_target;
  reg            last_cycle_cfiIndex_valid;
  reg  [3:0]     last_cycle_cfiIndex_bits;
  reg  [1:0]     last_cycle_bpu_in_stage;
  reg            last2_bpu_in;            // RegNext(last_cycle_bpu_in)，用于延后清 mispred
  reg  [PTR_W:0] last2_bpu_in_ptr;

  // ===========================================================================
  // ② to IFU / ICache / Prefetch（对应 Scala 823-983）
  // ===========================================================================
  // bypass：上一拍 BPU 写入的块若正好是当前 ifuPtr，直接用旁路 buf 而非等 pc_mem 读出
  reg  [49:0] bpu_in_bypass_startAddr, bpu_in_bypass_nextLineAddr;
  reg         bpu_in_bypass_fallThruErr;
  reg  [PTR_W:0] bpu_in_bypass_ptr;
  reg         last_cycle_to_ifu_fire, last_cycle_to_pf_fire;

  wire        ifu_req_fire = io_toIfu_req_valid & io_toIfu_req_ready;
  wire        pf_req_fire  = io_toPrefetch_req_valid & io_toPrefetch_req_ready;

  // 取指请求是否就绪、是否旁路命中当前 ifuPtr
  wire        bpu_bypass_hit_ifu = last_cycle_bpu_in & (bpu_in_bypass_ptr == ifuPtr);
  // toIfuPcBundle / entry_is_to_send / entry_next_addr 三选一（旁路 / 上拍fire用P1 / 否则用ifuPtr）。
  // pc_mem 读出已是 1 拍同步读，golden 再对其打一拍（单级 RegNext）：
  //   cur 分支 = RegNext(ifuPtr_rdata)，p1 分支 = RegNext(ifuPtrPlus1_rdata)。
  reg         entry_send_p1_a, entry_send_p1_b;   // RegNext(status@ifuPtrPlus1==to_send) | RegNext(bypass==ifuPtrPlus1)
  reg         entry_send_a, entry_send_b;         // RegNext(status@ifuPtr==to_send)     | RegNext(bypass==ifuPtr)
  reg  [49:0] toIfuPc_p1_startAddr, toIfuPc_p1_nextLineAddr; reg toIfuPc_p1_fallThruErr;
  reg  [49:0] toIfuPc_cur_startAddr, toIfuPc_cur_nextLineAddr; reg toIfuPc_cur_fallThruErr;
  // entry_next_addr 的"下一块起点"寄存：cur 用 RegNext(ifuPtrPlus1_rdata)，p1 用 RegNext(ifuPtrPlus2_rdata)
  reg  [49:0] enext_cur_reg, enext_p1_reg;

  wire        entry_is_to_send = bpu_bypass_hit_ifu |
                  (last_cycle_to_ifu_fire ? (entry_send_p1_a | entry_send_p1_b)
                                          : (entry_send_a   | entry_send_b));
  // entry_next_addr：bypass(ifuPtr+1) > newest 命中 > 寄存的 rdata（cur/p1 分支不同）
  wire        bypass_hit_ifuP1_cur = last_cycle_bpu_in & (bpu_in_bypass_ptr == ifuPtrPlus1);
  wire [49:0] enext_base = last_cycle_to_ifu_fire ? enext_p1_reg : enext_cur_reg;
  wire [49:0] entry_next_addr = bpu_bypass_hit_ifu ? last_cycle_bpu_target
                              : bypass_hit_ifuP1_cur ? bpu_in_bypass_startAddr
                              : (ifuPtr == newest_entry_ptr) ? newest_entry_target
                              : enext_base;
  wire [49:0] toIfu_startAddr   = bpu_bypass_hit_ifu ? bpu_in_bypass_startAddr
                              : last_cycle_to_ifu_fire ? toIfuPc_p1_startAddr : toIfuPc_cur_startAddr;
  wire [49:0] toIfu_nextLineAddr= bpu_bypass_hit_ifu ? bpu_in_bypass_nextLineAddr
                              : last_cycle_to_ifu_fire ? toIfuPc_p1_nextLineAddr : toIfuPc_cur_nextLineAddr;
  wire        toIfu_fallThruErr = bpu_bypass_hit_ifu ? bpu_in_bypass_fallThruErr
                              : last_cycle_to_ifu_fire ? toIfuPc_p1_fallThruErr : toIfuPc_cur_fallThruErr;

  wire        toIfu_req_valid_pre = entry_is_to_send & (ifuPtr != bpuPtr);
  assign io_toIfu_req_valid          = toIfu_req_valid_pre;
  assign io_toIfu_req_bits_startAddr = toIfu_startAddr;
  assign io_toIfu_req_bits_nextlineStart = toIfu_nextLineAddr;
  assign io_toIfu_req_bits_nextStartAddr = entry_next_addr;
  assign io_toIfu_req_bits_ftqIdx_flag  = ifuPtr[PTR_W];
  assign io_toIfu_req_bits_ftqIdx_value = ifuPtr[PTR_W-1:0];
  // ftqOffset = cfiIndex_vec[ifuPtr]，但旁路命中当前 ifuPtr 时用 last_cycle_cfiIndex（Scala 898-902）
  assign io_toIfu_req_bits_ftqOffset_valid = bpu_bypass_hit_ifu ? last_cycle_cfiIndex_valid
                                                                : cfiIndex_valid[ifuPtr[PTR_W-1:0]];
  assign io_toIfu_req_bits_ftqOffset_bits  = bpu_bypass_hit_ifu ? last_cycle_cfiIndex_bits
                                                                : cfiIndex_bits[ifuPtr[PTR_W-1:0]];

  // toICache：golden 用 5 份扇出复制（copied_ifu_ptr/copied_bpu_ptr 与 ifuPtr/bpuPtr 恒相等），
  // 功能上 5 路 pcMemRead/readValid 与 toIfu 路完全一致，故由同一可读计算驱动 5 路。
  wire        icache_readValid = entry_is_to_send & (ifuPtr != bpuPtr);
  assign io_toICache_req_valid = icache_readValid;
  assign io_toICache_req_bits_pcMemRead_0_startAddr = toIfu_startAddr;
  assign io_toICache_req_bits_pcMemRead_1_startAddr = toIfu_startAddr;
  assign io_toICache_req_bits_pcMemRead_2_startAddr = toIfu_startAddr;
  assign io_toICache_req_bits_pcMemRead_3_startAddr = toIfu_startAddr;
  assign io_toICache_req_bits_pcMemRead_4_startAddr = toIfu_startAddr;
  assign io_toICache_req_bits_pcMemRead_0_nextlineStart = toIfu_nextLineAddr;
  assign io_toICache_req_bits_pcMemRead_1_nextlineStart = toIfu_nextLineAddr;
  assign io_toICache_req_bits_pcMemRead_2_nextlineStart = toIfu_nextLineAddr;
  assign io_toICache_req_bits_pcMemRead_3_nextlineStart = toIfu_nextLineAddr;
  assign io_toICache_req_bits_pcMemRead_4_nextlineStart = toIfu_nextLineAddr;
  assign io_toICache_req_bits_readValid_0 = icache_readValid;
  assign io_toICache_req_bits_readValid_1 = icache_readValid;
  assign io_toICache_req_bits_readValid_2 = icache_readValid;
  assign io_toICache_req_bits_readValid_3 = icache_readValid;
  assign io_toICache_req_bits_readValid_4 = icache_readValid;
  // backendException：当 backendPcFaultPtr 指向 ifuPtr 且有异常类型时置位
  assign io_toICache_req_bits_backendException = (|backendException) & (backendPcFaultPtr == ifuPtr);

  // ---- to Prefetch（提前一拍算好，对应 Scala 883-942）----
  reg  [49:0] toPrefetchPc_startAddr, toPrefetchPc_nextLineAddr;
  reg         toPrefetchEntryToSend;
  // 下拍预取 PC/送出标志（bpu 刚写入 pfPtr / 上拍 pf fire 用 pfP1 / 否则用 pfPtr）
  logic [49:0] nextPfPc_startAddr, nextPfPc_nextLineAddr;
  logic        nextPfEntryToSend;
  wire        bpu_bypass_hit_pf  = last_cycle_bpu_in & (bpu_in_bypass_ptr == pfPtr);
  wire        bpu_bypass_hit_pfP1= last_cycle_bpu_in & (bpu_in_bypass_ptr == pfPtrPlus1);
  always_comb begin
    if (bpu_in_fire & (bpu_in_ptr == pfPtr_w)) begin
      nextPfPc_startAddr    = pcmem_wdata_startAddr;
      nextPfPc_nextLineAddr = pcmem_wdata_nextLineAddr;
      nextPfEntryToSend     = 1'b1;
    end else if (pf_req_fire) begin
      nextPfPc_startAddr    = pcmem_pfP1_startAddr;
      nextPfPc_nextLineAddr = pcmem_pfP1_nextLineAddr;
      nextPfEntryToSend     = (entry_fetch_status[pfPtrPlus1[PTR_W-1:0]] == F_TO_SEND) | bpu_bypass_hit_pfP1;
    end else begin
      nextPfPc_startAddr    = pcmem_pfPtr_startAddr;
      nextPfPc_nextLineAddr = pcmem_pfPtr_nextLineAddr;
      nextPfEntryToSend     = (entry_fetch_status[pfPtr[PTR_W-1:0]] == F_TO_SEND) | bpu_bypass_hit_pf;
    end
  end
  assign io_toPrefetch_req_valid          = toPrefetchEntryToSend & (pfPtr != bpuPtr);
  assign io_toPrefetch_req_bits_startAddr = toPrefetchPc_startAddr;
  assign io_toPrefetch_req_bits_nextlineStart = toPrefetchPc_nextLineAddr;
  assign io_toPrefetch_req_bits_ftqIdx_flag  = pfPtr[PTR_W];
  assign io_toPrefetch_req_bits_ftqIdx_value = pfPtr[PTR_W-1:0];
  assign io_toPrefetch_backendException = (backendPcFaultPtr == pfPtr) ? backendException : 2'd0;

  // BPU flush 透传给 IFU / Prefetch
  assign io_toIfu_flushFromBpu_s2_valid      = bpu_s2_redirect;
  assign io_toIfu_flushFromBpu_s2_bits_flag  = io_fromBpu_resp_bits_s2_ftq_idx_flag;
  assign io_toIfu_flushFromBpu_s2_bits_value = io_fromBpu_resp_bits_s2_ftq_idx_value;
  assign io_toIfu_flushFromBpu_s3_valid      = bpu_s3_redirect;
  assign io_toIfu_flushFromBpu_s3_bits_flag  = io_fromBpu_resp_bits_s3_ftq_idx_flag;
  assign io_toIfu_flushFromBpu_s3_bits_value = io_fromBpu_resp_bits_s3_ftq_idx_value;
  assign io_toPrefetch_flushFromBpu_s2_valid      = bpu_s2_redirect;
  assign io_toPrefetch_flushFromBpu_s2_bits_flag  = io_fromBpu_resp_bits_s2_ftq_idx_flag;
  assign io_toPrefetch_flushFromBpu_s2_bits_value = io_fromBpu_resp_bits_s2_ftq_idx_value;
  assign io_toPrefetch_flushFromBpu_s3_valid      = bpu_s3_redirect;
  assign io_toPrefetch_flushFromBpu_s3_bits_flag  = io_fromBpu_resp_bits_s3_ftq_idx_flag;
  assign io_toPrefetch_flushFromBpu_s3_bits_value = io_fromBpu_resp_bits_s3_ftq_idx_value;

  // shouldFlushByStage2/3：src.valid && !isAfter(src.bits, ifuReq.ftqIdx)
  wire [PTR_W:0] s2_flush_ptr = mk_ptr(io_fromBpu_resp_bits_s2_ftq_idx_flag, io_fromBpu_resp_bits_s2_ftq_idx_value);
  wire [PTR_W:0] s3_flush_ptr = mk_ptr(io_fromBpu_resp_bits_s3_ftq_idx_flag, io_fromBpu_resp_bits_s3_ftq_idx_value);
  // shouldBeFlushed = !isBefore(ifuPtr, idx)，须用 golden 展开式 ptr_recover
  //   （flag^flag^(ifuPtr.value>=idx.value)），与 ~ptr_after 仅在"异 flag 且 value 相等"
  //   处不同：该处 golden 视为"应冲刷"，~ptr_after 反之，会导致 entry_fetch_status 该项
  //   漏置 F_SENT，进而 prefetch toSend/pfPtr 提前一拍，io_toPrefetch_req_valid 失配。
  wire        ifu_req_should_be_flushed =
        (bpu_s2_redirect & ptr_recover(ifuPtr, s2_flush_ptr)) |
        (bpu_s3_redirect & ptr_recover(ifuPtr, s3_flush_ptr));

  // ===========================================================================
  // ③ wb from IFU（预解码写回；对应 Scala 985-1061）
  // ===========================================================================
  wire        ifu_wb_valid = io_fromIfu_pdWb_valid;
  wire [5:0]  ifu_wb_idx   = io_fromIfu_pdWb_bits_ftqIdx_value;
  wire        hit_pd_valid   = (entry_hit_status[ifu_wb_idx] == H_HIT) & ifu_wb_valid;
  wire        hit_pd_mispred = hit_pd_valid & io_fromIfu_pdWb_bits_misOffset_valid;
  reg         hit_pd_mispred_reg;
  // 打一拍的 pd / start_pc / wb_idx（false-hit 检测要等 ftb_entry_mem 读出对齐）
  reg  [PREDICT_W-1:0] pd_reg_valid, pd_reg_isBr, pd_reg_isRVC;  // false-hit 检测用
  reg  [PREDICT_W-1:0][1:0] pd_reg_brType;
  reg  [PREDICT_W-1:0] pd_reg_isJal, pd_reg_isJalr, pd_reg_isCall, pd_reg_isRet;
  reg  [5:0]  wb_idx_reg;
  reg         hit_pd_valid_reg;

  // false-hit：BPU 命中预测的 cfi 与 IFU 实测 pd 不符 → 标 H_FALSE_HIT
  // 由打拍后的 ftb_entry_mem.rdata(port0) 与 pd_reg 比较
  wire [3:0]  fh_br0_off  = ftbm0_brSlots0_offset;
  wire        fh_br0_v    = ftbm0_brSlots0_valid;
  wire [3:0]  fh_tail_off = ftbm0_tailSlot_offset;
  wire        fh_tail_v   = ftbm0_tailSlot_valid;
  wire        fh_tail_sh  = ftbm0_tailSlot_sharing;
  // br_false_hit：记录的 br 槽位对应 pd 不是 br
  wire        br_false_hit =
      (fh_br0_v   & ~(pd_reg_valid[fh_br0_off]  & pd_reg_isBr[fh_br0_off])) |
      (fh_tail_v  & fh_tail_sh & ~(pd_reg_valid[fh_tail_off] & pd_reg_isBr[fh_tail_off]));
  wire        fh_jmp_valid = fh_tail_v;
  wire [3:0]  fh_jmp_off   = fh_tail_off;
  // jal_false_hit：记录的 jmp 类型与 pd 实测不符
  wire        jal_false_hit = fh_jmp_valid & (
      (~fh_tail_sh & ~ftbm0_isJalr & ~ftbm0_isCall & ~ftbm0_isRet & ~(pd_reg_valid[fh_jmp_off] & pd_reg_isJal[fh_jmp_off])) |
      (ftbm0_isJalr & ~(pd_reg_valid[fh_jmp_off] & pd_reg_isJalr[fh_jmp_off])) |
      (ftbm0_isCall & ~(pd_reg_valid[fh_jmp_off] & pd_reg_isCall[fh_jmp_off])) |
      (ftbm0_isRet  & ~(pd_reg_valid[fh_jmp_off] & pd_reg_isRet[fh_jmp_off])) );
  wire        has_false_hit = hit_pd_valid_reg & (br_false_hit | jal_false_hit | hit_pd_mispred_reg);

  // ===========================================================================
  // ④ redirect from IFU（预解码发现误预测；对应 Scala 1136-1174）
  // ===========================================================================
  wire        ifu_redir_valid = io_fromIfu_pdWb_valid & io_fromIfu_pdWb_bits_misOffset_valid & ~backend_flush;
  wire [PTR_W:0] ifu_redir_ptr = mk_ptr(io_fromIfu_pdWb_bits_ftqIdx_flag, io_fromIfu_pdWb_bits_ftqIdx_value);
  wire [3:0]  ifu_redir_offset = io_fromIfu_pdWb_bits_misOffset_bits;
  // IFU redirect 打一拍送 BPU（RegNextWithEnable）
  reg         ifu_redir_reg_valid;
  reg  [PTR_W:0] ifu_redir_reg_ptr;
  reg  [3:0]  ifu_redir_reg_offset;
  reg  [49:0] ifu_redir_reg_pc, ifu_redir_reg_target;
  reg         ifu_redir_reg_pd_valid, ifu_redir_reg_pd_isRVC, ifu_redir_reg_pd_isCall, ifu_redir_reg_pd_isRet;
  reg  [1:0]  ifu_redir_reg_pd_brType;
  reg         ifu_redir_reg_predTaken, ifu_redir_reg_taken, ifu_redir_reg_isMisPred;
  assign ifu_flush = ifu_redir_valid | ifu_redir_reg_valid;

  // ===========================================================================
  // 指针 next 值（统一组合，最后一个 always_ff 落地；对应 Scala 762-815, 1289-1318）
  // ===========================================================================
  // redirect 冲刷优先级：backendRedirect > fromIfuRedirect（PriorityMux）
  wire        redir_any   = be_redir_valid | ifu_redir_valid;
  wire        redir_notIfu= be_redir_valid;                 // 是否后端（非 IFU）发起
  wire [PTR_W:0] redir_idx = be_redir_valid
                  ? mk_ptr(io_fromBackend_redirect_bits_ftqIdx_flag, io_fromBackend_redirect_bits_ftqIdx_value)
                  : ifu_redir_ptr;
  wire [3:0]  redir_offset = be_redir_valid ? io_fromBackend_redirect_bits_ftqOffset : ifu_redir_offset;
  // flushItself = RedirectLevel.flushItself(level) = level(0)（见 xiangshan/Bundle.scala
  //   object RedirectLevel: flushAfter="b0", flushItself(level)=level(0)）。
  //   backend redirect 用其 level；IFU redirect 固定 flushAfter(=0) → flushItself=0。
  wire        redir_flushItself = be_redir_valid ? io_fromBackend_redirect_bits_level : 1'b0;

  assign io_icacheFlush = redir_any;

  always_comb begin
    // 默认保持
    ifuPtr_w=ifuPtr; ifuPtrPlus1_w=ifuPtrPlus1; ifuPtrPlus2_w=ifuPtrPlus2;
    pfPtr_w=pfPtr; pfPtrPlus1_w=pfPtrPlus1; ifuWbPtr_w=ifuWbPtr;
    // ifuPtr：fire 推进
    if (ifu_req_fire & allow_to_ifu) begin
      ifuPtr_w=ifuPtrPlus1; ifuPtrPlus1_w=ifuPtrPlus2; ifuPtrPlus2_w=ptr_add(ifuPtrPlus2,1);
    end
    if (pf_req_fire & allow_to_ifu) begin
      pfPtr_w=pfPtrPlus1; pfPtrPlus1_w=ptr_add(pfPtrPlus1,1);
    end
    // s2 重定向：bpuPtr 回退；ifuPtr/pfPtr 若已超过 s2 块则回拉
    if (bpu_s2_redirect) begin
      if (ptr_recover(ifuPtr, s2_flush_ptr)) begin
        ifuPtr_w=s2_flush_ptr; ifuPtrPlus1_w=ptr_add(s2_flush_ptr,1); ifuPtrPlus2_w=ptr_add(s2_flush_ptr,2);
      end
      if (ptr_recover(pfPtr, s2_flush_ptr)) begin
        pfPtr_w=s2_flush_ptr; pfPtrPlus1_w=ptr_add(s2_flush_ptr,1);
      end
    end
    // s3 重定向：同理（优先级更高，后写覆盖 s2）
    if (bpu_s3_redirect) begin
      if (ptr_recover(ifuPtr, s3_flush_ptr)) begin
        ifuPtr_w=s3_flush_ptr; ifuPtrPlus1_w=ptr_add(s3_flush_ptr,1); ifuPtrPlus2_w=ptr_add(s3_flush_ptr,2);
      end
      if (ptr_recover(pfPtr, s3_flush_ptr)) begin
        pfPtr_w=s3_flush_ptr; pfPtrPlus1_w=ptr_add(s3_flush_ptr,1);
      end
    end
    // IFU 写回推进 ifuWbPtr
    if (ifu_wb_valid) ifuWbPtr_w = ptr_add(ifuWbPtr,1);
    // redirect 冲刷：所有取指相关指针回到 redir_idx+1，逐次覆盖（优先级最高）
    if (redir_any) begin
      ifuPtr_w     = ptr_add(redir_idx,1);
      ifuWbPtr_w   = ptr_add(redir_idx,1);
      ifuPtrPlus1_w= ptr_add(redir_idx,2);
      ifuPtrPlus2_w= ptr_add(redir_idx,3);
      pfPtr_w      = ptr_add(redir_idx,1);
      pfPtrPlus1_w = ptr_add(redir_idx,2);
    end
  end

  // bpuPtr / commPtr next（对应 Scala 762/802/1294 + 1431）
  logic [PTR_W:0] bpuPtr_w;
  always_comb begin
    bpuPtr_w = ptr_add(bpuPtr, {6'd0, enq_fire});      // 正常 s1 入队 +1
    if (bpu_s2_redirect) bpuPtr_w = ptr_add(s2_flush_ptr, 1);
    if (bpu_s3_redirect) bpuPtr_w = ptr_add(s3_flush_ptr, 1);
    if (redir_any)       bpuPtr_w = ptr_add(redir_idx, 1);
  end
  always_comb begin
    commPtr_w      = commPtr;
    commPtrPlus1_w = commPtrPlus1;
    if (canMoveCommPtr) begin
      commPtr_w      = commPtrPlus1;
      commPtrPlus1_w = ptr_add(commPtrPlus1, 1);
    end
  end

  // ---- redirect_mem / ftb_entry_mem / pd_mem 读口构造（对应 Scala 1073-1103, 1417-1424）----
  // 口 0=IFU redirect，口 1=后端 redirect/ahead0，口 2=commit
  always_comb begin
    redir_ren0   = ifu_redir_valid;
    redir_raddr0 = io_fromIfu_pdWb_bits_ftqIdx_value;
    redir_ren1   = ahead_valid ? io_fromBackend_ftqIdxAhead_0_valid : be_redir_valid;
    redir_raddr1 = ahead_valid ? io_fromBackend_ftqIdxAhead_0_bits_value : io_fromBackend_redirect_bits_ftqIdx_value;
    redir_ren2   = canCommit;
    redir_raddr2 = commPtr[PTR_W-1:0];
  end

  // ===========================================================================
  // ⑥ commit（提交出队；对应 Scala 1372-1496）
  // ===========================================================================
  wire        may_have_stall_from_bpu = (bpu_ftb_update_stall != 2'd0);
  // commPtr 当前项 16 槽的提交状态
  wire [PREDICT_W-1:0][1:0] commSt = commitStateQueue[commPtr[PTR_W-1:0]];
  logic [PREDICT_W-1:0] valid_insts;       // c_toCommit 或 c_committed
  always_comb for (int i=0;i<PREDICT_W;i++) valid_insts[i] = (commSt[i]==C_TO_COMMIT)|(commSt[i]==C_COMMITTED);
  // 最后一条有效指令的状态 = 最高位有效槽的状态
  //   golden: PriorityMux(validInstructions.reverse zip commSt.reverse) → 取“最高位的有效项”。
  //   故必须 i 从低到高扫描、last-wins，使最终落在最高有效 index（原 high→low 扫描 last-wins
  //   会落在最低有效 index，是 bug：环绕重用时 lastInst 取错，canCommit 误判）。
  logic [1:0] lastInstStatus;
  always_comb begin
    lastInstStatus = commSt[0];
    for (int i=0;i<PREDICT_W;i++) if (valid_insts[i]) lastInstStatus = commSt[i];
  end
  wire firstInstFlushed = (commSt[0]==C_FLUSHED) | ((commSt[0]==C_EMPTY)&(commSt[1]==C_FLUSHED));
  wire commit_done_cond = ptr_after(robCommPtr, commPtr) | (|valid_insts & (lastInstStatus==C_COMMITTED));
  assign canCommit       = (commPtr!=ifuWbPtr) & ~may_have_stall_from_bpu & commit_done_cond;
  assign canMoveCommPtr  = (commPtr!=ifuWbPtr) & ~may_have_stall_from_bpu & (commit_done_cond | firstInstFlushed);

  // robCommPtr next：选最新的有效 rob commit ftqIdx
  logic [PTR_W:0] robCommPtr_sel;
  always_comb begin
    robCommPtr_sel = robCommPtr;
    for (int i=0;i<8;i++) if (robc_valid[i]) robCommPtr_sel = mk_ptr(robc_idx_flag[i], robc_idx_value[i]);
  end
  always_comb begin
    if (|robc_valid)                       robCommPtr_w = robCommPtr_sel;
    else if (ptr_after(commPtr,robCommPtr))robCommPtr_w = commPtr;
    else                                   robCommPtr_w = robCommPtr;
  end

  // commit 读出（打一拍，对应 Scala 1410-1453）
  reg  [49:0] commit_pc_startAddr;
  reg  [PTR_W:0] do_commit_ptr; reg do_commit;
  reg  [PREDICT_W-1:0][1:0] commit_state;
  reg         commit_cfi_valid; reg [3:0] commit_cfi_bits;
  reg  [PREDICT_W-1:0] commit_mispred_raw;       // RegEnable(mispred_block[commPtr])
  reg  [1:0]  commit_hit; reg [1:0] commit_stage;
  reg  [49:0] commit_target_r;
  reg         commit_newest_eq;                  // RegNext(commPtr==newest_entry_ptr)
  reg  [49:0] commit_newest_target;
  reg  [49:0] commit_pc_p1_startAddr_r;
  // commit_target = newest_eq ? newest_target : RegNext(commPtrPlus1_rdata.startAddr)
  wire [49:0] commit_target = commit_newest_eq ? commit_newest_target : commit_pc_p1_startAddr_r;

  // commit_mispredict[i] = mispred_raw[i] & state[i]==committed
  logic [PREDICT_W-1:0] commit_mispredict, commit_instCommitted;
  always_comb for (int i=0;i<PREDICT_W;i++) begin
    commit_mispredict[i]    = commit_mispred_raw[i] & (commit_state[i]==C_COMMITTED);
    commit_instCommitted[i] = (commit_state[i]==C_COMMITTED);
  end
  wire        commit_real_hit = (commit_hit==H_HIT);
  wire        commit_valid    = (commit_hit==H_HIT) | commit_cfi_valid;

  // commit_pd（来自 ftq_pd_mem 口1）——组装成 FTBEntryGen 需要的 pd 块信息
  wire        commit_pd_jmpInfo_valid = pdm1_jmpInfo_valid;
  wire [3:0]  commit_pd_jmpOffset     = pdm1_jmpOffset;

  // ===========================================================================
  // ⑤ update：据提交结果生成 FTB 新条目喂回 BPU（对应 Scala 1482-1515）
  // ===========================================================================
  // FTBEntryGen 输入：start_addr=commit pc，old_entry=commit 时读出的 ftb_entry，
  //   pd=commit_pd，cfiIndex=commit_cfi，target=commit_target，hit=commit_real_hit，
  //   mispredict_vec=commit_mispredict。输出即写回 BPU 的 update.ftb_entry + 各 mask。
  wire        gen_taken_0, gen_taken_1, gen_jmp_taken;
  wire        gen_mispred_0, gen_mispred_1, gen_mispred_2;
  wire        gen_is_init, gen_is_old, gen_is_newbr, gen_is_jalrmod, gen_is_sbmod, gen_is_brfull;

  FTBEntryGen ftbEntryGen (
    .io_start_addr(commit_pc_startAddr),
    .io_old_entry_isCall(meta_ftb_isCall), .io_old_entry_isRet(meta_ftb_isRet),
    .io_old_entry_isJalr(meta_ftb_isJalr), .io_old_entry_valid(meta_ftb_valid),
    .io_old_entry_brSlots_0_offset(meta_ftb_brSlots0_offset),
    .io_old_entry_brSlots_0_sharing(meta_ftb_brSlots0_sharing),
    .io_old_entry_brSlots_0_valid(meta_ftb_brSlots0_valid),
    .io_old_entry_brSlots_0_lower(meta_ftb_brSlots0_lower),
    .io_old_entry_brSlots_0_tarStat(meta_ftb_brSlots0_tarStat),
    .io_old_entry_tailSlot_offset(meta_ftb_tailSlot_offset),
    .io_old_entry_tailSlot_sharing(meta_ftb_tailSlot_sharing),
    .io_old_entry_tailSlot_valid(meta_ftb_tailSlot_valid),
    .io_old_entry_tailSlot_lower(meta_ftb_tailSlot_lower),
    .io_old_entry_tailSlot_tarStat(meta_ftb_tailSlot_tarStat),
    .io_old_entry_pftAddr(meta_ftb_pftAddr), .io_old_entry_carry(meta_ftb_carry),
    .io_old_entry_last_may_be_rvi_call(meta_ftb_lastRviCall),
    .io_old_entry_strong_bias_0(meta_ftb_strongBias0), .io_old_entry_strong_bias_1(meta_ftb_strongBias1),
    .io_pd_brMask_0(pdm1_brMask[0]),   .io_pd_brMask_1(pdm1_brMask[1]),
    .io_pd_brMask_2(pdm1_brMask[2]),   .io_pd_brMask_3(pdm1_brMask[3]),
    .io_pd_brMask_4(pdm1_brMask[4]),   .io_pd_brMask_5(pdm1_brMask[5]),
    .io_pd_brMask_6(pdm1_brMask[6]),   .io_pd_brMask_7(pdm1_brMask[7]),
    .io_pd_brMask_8(pdm1_brMask[8]),   .io_pd_brMask_9(pdm1_brMask[9]),
    .io_pd_brMask_10(pdm1_brMask[10]), .io_pd_brMask_11(pdm1_brMask[11]),
    .io_pd_brMask_12(pdm1_brMask[12]), .io_pd_brMask_13(pdm1_brMask[13]),
    .io_pd_brMask_14(pdm1_brMask[14]), .io_pd_brMask_15(pdm1_brMask[15]),
    .io_pd_jmpInfo_valid(pdm1_jmpInfo_valid),
    .io_pd_jmpInfo_bits_0(pdm1_jmpInfo_b0), .io_pd_jmpInfo_bits_1(pdm1_jmpInfo_b1),
    .io_pd_jmpInfo_bits_2(pdm1_jmpInfo_b2), .io_pd_jmpOffset(pdm1_jmpOffset),
    .io_pd_jalTarget(pdm1_jalTarget),
    .io_pd_rvcMask_0(pdm1_rvcMask[0]),   .io_pd_rvcMask_1(pdm1_rvcMask[1]),
    .io_pd_rvcMask_2(pdm1_rvcMask[2]),   .io_pd_rvcMask_3(pdm1_rvcMask[3]),
    .io_pd_rvcMask_4(pdm1_rvcMask[4]),   .io_pd_rvcMask_5(pdm1_rvcMask[5]),
    .io_pd_rvcMask_6(pdm1_rvcMask[6]),   .io_pd_rvcMask_7(pdm1_rvcMask[7]),
    .io_pd_rvcMask_8(pdm1_rvcMask[8]),   .io_pd_rvcMask_9(pdm1_rvcMask[9]),
    .io_pd_rvcMask_10(pdm1_rvcMask[10]), .io_pd_rvcMask_11(pdm1_rvcMask[11]),
    .io_pd_rvcMask_12(pdm1_rvcMask[12]), .io_pd_rvcMask_13(pdm1_rvcMask[13]),
    .io_pd_rvcMask_14(pdm1_rvcMask[14]), .io_pd_rvcMask_15(pdm1_rvcMask[15]),
    .io_cfiIndex_valid(commit_cfi_valid), .io_cfiIndex_bits(commit_cfi_bits),
    .io_target(commit_target), .io_hit(commit_real_hit),
    .io_mispredict_vec_0(commit_mispredict[0]),   .io_mispredict_vec_1(commit_mispredict[1]),
    .io_mispredict_vec_2(commit_mispredict[2]),   .io_mispredict_vec_3(commit_mispredict[3]),
    .io_mispredict_vec_4(commit_mispredict[4]),   .io_mispredict_vec_5(commit_mispredict[5]),
    .io_mispredict_vec_6(commit_mispredict[6]),   .io_mispredict_vec_7(commit_mispredict[7]),
    .io_mispredict_vec_8(commit_mispredict[8]),   .io_mispredict_vec_9(commit_mispredict[9]),
    .io_mispredict_vec_10(commit_mispredict[10]), .io_mispredict_vec_11(commit_mispredict[11]),
    .io_mispredict_vec_12(commit_mispredict[12]), .io_mispredict_vec_13(commit_mispredict[13]),
    .io_mispredict_vec_14(commit_mispredict[14]), .io_mispredict_vec_15(commit_mispredict[15]),
    .io_new_entry_isCall(io_toBpu_update_bits_ftb_entry_isCall),
    .io_new_entry_isRet (io_toBpu_update_bits_ftb_entry_isRet),
    .io_new_entry_isJalr(io_toBpu_update_bits_ftb_entry_isJalr),
    .io_new_entry_valid (io_toBpu_update_bits_ftb_entry_valid),
    .io_new_entry_brSlots_0_offset (io_toBpu_update_bits_ftb_entry_brSlots_0_offset),
    .io_new_entry_brSlots_0_sharing(io_toBpu_update_bits_ftb_entry_brSlots_0_sharing),
    .io_new_entry_brSlots_0_valid  (io_toBpu_update_bits_ftb_entry_brSlots_0_valid),
    .io_new_entry_brSlots_0_lower  (io_toBpu_update_bits_ftb_entry_brSlots_0_lower),
    .io_new_entry_brSlots_0_tarStat(io_toBpu_update_bits_ftb_entry_brSlots_0_tarStat),
    .io_new_entry_tailSlot_offset (io_toBpu_update_bits_ftb_entry_tailSlot_offset),
    .io_new_entry_tailSlot_sharing(io_toBpu_update_bits_ftb_entry_tailSlot_sharing),
    .io_new_entry_tailSlot_valid  (io_toBpu_update_bits_ftb_entry_tailSlot_valid),
    .io_new_entry_tailSlot_lower  (io_toBpu_update_bits_ftb_entry_tailSlot_lower),
    .io_new_entry_tailSlot_tarStat(io_toBpu_update_bits_ftb_entry_tailSlot_tarStat),
    .io_new_entry_pftAddr(io_toBpu_update_bits_ftb_entry_pftAddr),
    .io_new_entry_carry  (io_toBpu_update_bits_ftb_entry_carry),
    .io_new_entry_last_may_be_rvi_call(io_toBpu_update_bits_ftb_entry_last_may_be_rvi_call),
    .io_new_entry_strong_bias_0(io_toBpu_update_bits_ftb_entry_strong_bias_0),
    .io_new_entry_strong_bias_1(io_toBpu_update_bits_ftb_entry_strong_bias_1),
    .io_taken_mask_0(gen_taken_0), .io_taken_mask_1(gen_taken_1), .io_jmp_taken(gen_jmp_taken),
    .io_mispred_mask_0(gen_mispred_0), .io_mispred_mask_1(gen_mispred_1), .io_mispred_mask_2(gen_mispred_2),
    .io_is_init_entry(gen_is_init), .io_is_old_entry(gen_is_old), .io_is_new_br(gen_is_newbr),
    .io_is_jalr_target_modified(gen_is_jalrmod), .io_is_strong_bias_modified(gen_is_sbmod),
    .io_is_br_full(gen_is_brfull)
  );

  // update 输出（toBpu.update）
  assign io_toBpu_update_valid           = commit_valid & do_commit;
  assign io_toBpu_update_bits_pc         = commit_pc_startAddr;
  assign io_toBpu_update_bits_cfi_idx_valid = commit_cfi_valid;
  assign io_toBpu_update_bits_cfi_idx_bits  = commit_cfi_bits;
  assign io_toBpu_update_bits_full_target= commit_target;
  assign io_toBpu_update_bits_false_hit  = (commit_hit==H_FALSE_HIT);
  assign io_toBpu_update_bits_old_entry  = gen_is_old;
  assign io_toBpu_update_bits_br_taken_mask_0 = gen_taken_0;
  assign io_toBpu_update_bits_br_taken_mask_1 = gen_taken_1;
  assign io_toBpu_update_bits_jmp_taken  = gen_jmp_taken;
  assign io_toBpu_update_bits_mispred_mask_0 = gen_mispred_0;
  assign io_toBpu_update_bits_mispred_mask_1 = gen_mispred_1;
  assign io_toBpu_update_bits_mispred_mask_2 = gen_mispred_2;
  // meta / spec_info.histPtr_value 直接由 ftq_meta_1r_sram / ftq_redirect_mem 读口驱动

  // ===========================================================================
  // redirect from backend：构造 cfiUpdate（对应 Scala 1104-1134）
  // ===========================================================================
  // 重定向块的 pd（toPd(offset)）由 ftq_pd_mem 口0 读出
  wire        fbr_off_eq_jmp = (fbr_offset == pdm0_jmpOffset);
  wire        rpd_isRVC  = pdm0_rvcMask[fbr_offset];
  wire        rpd_isCall = fbr_off_eq_jmp & pdm0_jmpInfo_valid & pdm0_jmpInfo_b1;
  wire        rpd_isRet  = fbr_off_eq_jmp & pdm0_jmpInfo_valid & pdm0_jmpInfo_b2;
  wire [1:0]  rpd_brType = {fbr_off_eq_jmp & pdm0_jmpInfo_valid,
                            (fbr_off_eq_jmp & pdm0_jmpInfo_valid & pdm0_jmpInfo_b0) | pdm0_brMask[fbr_offset]};
  // 重定向块的 r_ftb_entry 由 ftb_entry_mem 口1 读出（br_hit/jr_hit/sc_hit）
  wire        be_br0_off_eq = (ftbm1_brSlots0_offset == fbr_offset);
  wire        be_tail_off_eq= (ftbm1_tailSlot_offset == fbr_offset);
  wire        be_br_hit = (ftbm1_brSlots0_valid & be_br0_off_eq) |
                          (ftbm1_tailSlot_valid & be_tail_off_eq & ftbm1_tailSlot_sharing);
  wire        be_jr_hit = ftbm1_isJalr & be_tail_off_eq;
  wire        be_sc_hit = be_br_hit & (be_br0_off_eq ? rdm1_sc_disagree_0 : rdm1_sc_disagree_1);
  wire        be_hit_status_hhit = (entry_hit_status[fbr_idx_value] == H_HIT);
  wire        be_pd_isBr = (rpd_brType == 2'd1);
  wire        be_tail_off_lt = (ftbm1_tailSlot_offset < fbr_offset);
  // shift / addIntoHist（命中时按 r_ftb_entry 算前置 br 数 + 是否插入历史；非命中时退化为 pd_isBr&taken）
  wire        be_no_tail_before = ~(ftbm1_tailSlot_valid & be_tail_off_lt);
  wire        be_shift_newbr    = be_pd_isBr & ~be_br_hit & be_no_tail_before; // 该 br 未记录且能插入 → 多移 1
  wire [1:0]  be_shift =
      be_hit_status_hhit
        ? ( {1'b0, (ftbm1_brSlots0_valid  & (ftbm1_brSlots0_offset  <= fbr_offset))}
          + {1'b0, (ftbm1_tailSlot_valid  & (ftbm1_tailSlot_offset  <= fbr_offset) & ftbm1_tailSlot_sharing)}
          + {1'b0, be_shift_newbr} )
        : {1'b0, (be_pd_isBr & fbr_cfi_taken)};
  wire        be_addIntoHist =
      be_hit_status_hhit ? (be_pd_isBr & (be_br_hit | be_no_tail_before))
                         : be_pd_isBr;

  // ===========================================================================
  // toBpu.redirect = Mux(fromBackendRedirect.valid, fromBackendRedirect, ifuRedirectToBpu)
  //   （对应 Scala 1352-1353 + cfiUpdate 各字段）
  // ===========================================================================
  // IFU redirect 打拍后送 BPU：cfiUpdate 由 ftq_redirect_mem 口0(IFU) 读出；ret 改用 topAddr
  wire [49:0] ifuToBpu_target = (ifu_redir_reg_pd_isRet & ifu_redir_reg_pd_valid) ? rdm0_topAddr : ifu_redir_reg_target;
  assign io_toBpu_redirect_valid      = fbr_valid | ifu_redir_reg_valid;
  assign io_toBpu_redirect_bits_level = fbr_valid & fbr_level;
  assign io_toBpu_redirect_bits_cfiUpdate_pc       = fbr_valid ? fbr_cfi_pc : ifu_redir_reg_pc;
  assign io_toBpu_redirect_bits_cfiUpdate_pd_valid = fbr_valid | ifu_redir_reg_pd_valid;
  assign io_toBpu_redirect_bits_cfiUpdate_pd_isRVC = fbr_valid ? rpd_isRVC  : ifu_redir_reg_pd_isRVC;
  assign io_toBpu_redirect_bits_cfiUpdate_pd_isCall= fbr_valid ? rpd_isCall : ifu_redir_reg_pd_isCall;
  assign io_toBpu_redirect_bits_cfiUpdate_pd_isRet = fbr_valid ? rpd_isRet  : ifu_redir_reg_pd_isRet;
  // ssp/sctr/TOSW/TOSR/NOS/histPtr：后端用 redirect_mem 口1，IFU 用口0
  assign io_toBpu_redirect_bits_cfiUpdate_ssp        = fbr_valid ? rdm1_ssp        : rdm0_ssp;
  assign io_toBpu_redirect_bits_cfiUpdate_sctr       = fbr_valid ? rdm1_sctr       : rdm0_sctr;
  assign io_toBpu_redirect_bits_cfiUpdate_TOSW_flag  = fbr_valid ? rdm1_TOSW_flag  : rdm0_TOSW_flag;
  assign io_toBpu_redirect_bits_cfiUpdate_TOSW_value = fbr_valid ? rdm1_TOSW_value : rdm0_TOSW_value;
  assign io_toBpu_redirect_bits_cfiUpdate_TOSR_flag  = fbr_valid ? rdm1_TOSR_flag  : rdm0_TOSR_flag;
  assign io_toBpu_redirect_bits_cfiUpdate_TOSR_value = fbr_valid ? rdm1_TOSR_value : rdm0_TOSR_value;
  assign io_toBpu_redirect_bits_cfiUpdate_NOS_flag   = fbr_valid ? rdm1_NOS_flag   : rdm0_NOS_flag;
  assign io_toBpu_redirect_bits_cfiUpdate_NOS_value  = fbr_valid ? rdm1_NOS_value  : rdm0_NOS_value;
  assign io_toBpu_redirect_bits_cfiUpdate_histPtr_flag  = fbr_valid ? rdm1_histPtr_flag  : rdm0_histPtr_flag;
  assign io_toBpu_redirect_bits_cfiUpdate_histPtr_value = fbr_valid ? rdm1_histPtr_value : rdm0_histPtr_value;
  assign io_toBpu_redirect_bits_cfiUpdate_br_hit = fbr_valid & be_br_hit;
  assign io_toBpu_redirect_bits_cfiUpdate_jr_hit = fbr_valid & be_jr_hit;
  assign io_toBpu_redirect_bits_cfiUpdate_sc_hit = fbr_valid & be_sc_hit;
  assign io_toBpu_redirect_bits_cfiUpdate_target = fbr_valid ? fbr_cfi_target : ifuToBpu_target;
  assign io_toBpu_redirect_bits_cfiUpdate_taken  = fbr_valid ? fbr_cfi_taken  : ifu_redir_reg_taken;
  assign io_toBpu_redirect_bits_cfiUpdate_shift       = fbr_valid ? be_shift       : 2'd0;
  assign io_toBpu_redirect_bits_cfiUpdate_addIntoHist = fbr_valid & be_addIntoHist;
  assign io_toBpu_redirect_bits_debugIsCtrl   = fbr_valid & fbr_dbg_ctrl;
  assign io_toBpu_redirect_bits_debugIsMemVio = fbr_valid & fbr_dbg_memvio;
  assign io_toBpu_redirect_bits_BTBMissBubble = ~fbr_valid;
  assign io_toBpu_redirctFromIFU = ifu_redir_reg_valid;

  // ===========================================================================
  // toIfu.redirect / topdown_redirect（对应 Scala 1320-1323）
  // ===========================================================================
  assign io_toIfu_redirect_valid          = stage2_flush;
  assign io_toIfu_redirect_bits_ftqIdx_flag  = io_fromBackend_redirect_bits_ftqIdx_flag;
  assign io_toIfu_redirect_bits_ftqIdx_value = io_fromBackend_redirect_bits_ftqIdx_value;
  assign io_toIfu_redirect_bits_ftqOffset    = io_fromBackend_redirect_bits_ftqOffset;
  assign io_toIfu_redirect_bits_level        = io_fromBackend_redirect_bits_level;
  // topdown_redirect = fromBackendRedirect（仅少量字段被引出）
  assign io_toIfu_topdown_redirect_valid           = fbr_valid;
  assign io_toIfu_topdown_redirect_bits_cfiUpdate_pd_isRet = fbr_valid ? rpd_isRet : 1'b0;
  assign io_toIfu_topdown_redirect_bits_cfiUpdate_br_hit   = fbr_valid & be_br_hit;
  assign io_toIfu_topdown_redirect_bits_cfiUpdate_jr_hit   = fbr_valid & be_jr_hit;
  assign io_toIfu_topdown_redirect_bits_cfiUpdate_sc_hit   = fbr_valid & be_sc_hit;
  assign io_toIfu_topdown_redirect_bits_debugIsCtrl   = fbr_valid & fbr_dbg_ctrl;
  assign io_toIfu_topdown_redirect_bits_debugIsMemVio = fbr_valid & fbr_dbg_memvio;

  // perf bubble 输出（对应 fromBackendRedirect.bits.ControlBTBMissBubble 等，据 redirect 类型分类）
  wire sc_miss_term  = fbr_dbg_ctrl & be_br_hit;   // 是控制流误预测且命中 br → 归因 TAGE/SC
  wire ras_miss_term = fbr_dbg_ctrl & be_jr_hit;   // 命中间接跳转 → 归因 ITTAGE/RAS
  assign io_ControlBTBMissBubble = fbr_dbg_ctrl & ~be_br_hit & ~be_jr_hit;
  assign io_TAGEMissBubble       = sc_miss_term  & ~be_sc_hit;
  assign io_SCMissBubble         = sc_miss_term  &  be_sc_hit;
  assign io_ITTAGEMissBubble     = ras_miss_term & ~rpd_isRet;
  assign io_RASMissBubble        = ras_miss_term &  rpd_isRet;

  // ===========================================================================
  // toBackend / mmio / 性能计数（对应 Scala 1176-1188, 1404-1407, 1684-1718）
  // ===========================================================================
  reg         tobk_pc_mem_wen; reg [5:0] tobk_pc_mem_waddr; reg [49:0] tobk_pc_mem_wdata_start;
  reg         newest_en_q1, newest_en_q2;     // RegNext × 2
  reg  [PTR_W:0] tobk_newest_ptr; reg [49:0] tobk_newest_target;
  assign io_toBackend_pc_mem_wen   = tobk_pc_mem_wen;
  assign io_toBackend_pc_mem_waddr = tobk_pc_mem_waddr;
  assign io_toBackend_pc_mem_wdata_startAddr = tobk_pc_mem_wdata_start;
  assign io_toBackend_newest_entry_en        = newest_en_q2;
  assign io_toBackend_newest_entry_target    = tobk_newest_target;
  assign io_toBackend_newest_entry_ptr_value = tobk_newest_ptr[PTR_W-1:0];

  // mmio：mmioLastCommit = RegNext(commPtr 已越过/等于 mmioReadPtr 且已提交)
  wire [PTR_W:0] mmio_read_ptr = mk_ptr(io_mmioCommitRead_mmioFtqPtr_flag, io_mmioCommitRead_mmioFtqPtr_value);
  wire        mmio_last_commit = ptr_after(commPtr, mmio_read_ptr) |
                  ((commPtr==mmio_read_ptr) & (|valid_insts) & (lastInstStatus==C_COMMITTED));
  reg         mmio_last_commit_q;
  assign io_mmioCommitRead_mmioLastCommit = mmio_last_commit_q;

  // 性能计数输出：本核不实现具体统计（纯性能可观测口），打 0；UT 比对跳过常量/未驱动 X
  assign io_perf_0_value=0;  assign io_perf_1_value=0;  assign io_perf_2_value=0;  assign io_perf_3_value=0;
  assign io_perf_4_value=0;  assign io_perf_5_value=0;  assign io_perf_6_value=0;  assign io_perf_7_value=0;
  assign io_perf_8_value=0;  assign io_perf_9_value=0;  assign io_perf_10_value=0; assign io_perf_11_value=0;
  assign io_perf_12_value=0; assign io_perf_13_value=0; assign io_perf_14_value=0; assign io_perf_15_value=0;
  assign io_perf_16_value=0; assign io_perf_17_value=0; assign io_perf_18_value=0; assign io_perf_19_value=0;
  assign io_perf_20_value=0; assign io_perf_21_value=0; assign io_perf_22_value=0; assign io_perf_23_value=0;

  // topdown_info：本核仅透传/置位最常用位（topdown 主要供性能分析，不影响功能）
  assign io_toIfu_req_bits_topdown_info_reasons_0  = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_1  = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_2  = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_3  = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_4  = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_5  = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_6  = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_7  = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_8  = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_9  = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_10 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_11 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_12 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_13 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_14 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_15 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_16 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_17 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_18 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_19 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_20 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_21 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_22 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_23 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_24 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_25 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_26 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_27 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_28 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_29 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_30 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_31 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_32 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_33 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_34 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_35 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_36 = 1'b0;
  assign io_toIfu_req_bits_topdown_info_reasons_37 = 1'b0;

  // ---- redirect 冲刷 commitStateQueue 的打拍寄存 + commit cfi 辅助 ----
  reg          flush_csq_valid_q, flush_csq_notIfu_q, flush_csq_flushItself_q;
  reg  [5:0]   flush_csq_idx_q; reg [3:0] flush_csq_off_q;
  // bpu_ftb_update_stall 触发条件：commit 的 cfi 有效但 BPU 未命中（需 stall 等 FTB 写回）
  wire [1:0]   can_commit_hit  = entry_hit_status[commPtr[PTR_W-1:0]];
  wire         to_bpu_hit      = (can_commit_hit==H_HIT) | (can_commit_hit==H_FALSE_HIT);
  wire         commit_cfi_valid_can = cfiIndex_valid[commPtr[PTR_W-1:0]];

  // ===========================================================================
  // 统一时序更新（指针落地 + 流水寄存器 + 各状态阵列）
  // ===========================================================================
  // commit 段移动 commPtr 后，记录提交项以驱动 update/FTBEntryGen
  wire commPtr_eq_newest = (commPtr == newest_entry_ptr);

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      bpuPtr<=mk_ptr(0,0); ifuPtr<=mk_ptr(0,0); pfPtr<=mk_ptr(0,0);
      ifuWbPtr<=mk_ptr(0,0); commPtr<=mk_ptr(0,0); robCommPtr<=mk_ptr(0,0);
      ifuPtrPlus1<=mk_ptr(0,1); ifuPtrPlus2<=mk_ptr(0,2);
      pfPtrPlus1<=mk_ptr(0,1); commPtrPlus1<=mk_ptr(0,1);
      for (int i=0;i<FTQ_SIZE;i++) begin
        entry_fetch_status[i]<=F_SENT; entry_hit_status[i]<=H_NOT_HIT; ifuRedirected[i]<=1'b0;
        commitStateQueue[i]<='0;   // 复位为全 C_EMPTY（RegInit）
      end
      bpu_ftb_update_stall<=2'd0; backendException<=2'd0; backendPcFaultPtr<=mk_ptr(0,0);
      last_cycle_bpu_in<=1'b0; last2_bpu_in<=1'b0; do_commit<=1'b0;
      ifu_redir_reg_valid<=1'b0; hit_pd_mispred_reg<=1'b0; hit_pd_valid_reg<=1'b0;
      newest_entry_target_modified<=1'b0; newest_entry_ptr_modified<=1'b0;
      last_cycle_to_ifu_fire<=1'b0; last_cycle_to_pf_fire<=1'b0;
      tobk_pc_mem_wen<=1'b0; newest_en_q1<=1'b0; newest_en_q2<=1'b0;
      mmio_last_commit_q<=1'b0; toPrefetchEntryToSend<=1'b0;
    end else begin
      // ---- 指针落地 ----
      bpuPtr<=bpuPtr_w; ifuPtr<=ifuPtr_w; ifuPtrPlus1<=ifuPtrPlus1_w; ifuPtrPlus2<=ifuPtrPlus2_w;
      pfPtr<=pfPtr_w; pfPtrPlus1<=pfPtrPlus1_w; ifuWbPtr<=ifuWbPtr_w;
      commPtr<=commPtr_w; commPtrPlus1<=commPtrPlus1_w; robCommPtr<=robCommPtr_w;

      // ---- enq 打一拍信号 ----
      last_cycle_bpu_in     <= bpu_in_fire;
      last2_bpu_in          <= last_cycle_bpu_in;
      if (bpu_in_fire) begin
        last_cycle_bpu_in_ptr   <= bpu_in_ptr;
        last_cycle_bpu_target   <= bpu_target;
        last_cycle_cfiIndex_valid <= cfi_valid;
        last_cycle_cfiIndex_bits  <= cfi_bits;
        last_cycle_bpu_in_stage <= bpu_in_stage;
        bpu_in_bypass_startAddr   <= pcmem_wdata_startAddr;
        bpu_in_bypass_nextLineAddr<= pcmem_wdata_nextLineAddr;
        bpu_in_bypass_fallThruErr <= pcmem_wdata_fallThruErr;
        bpu_in_bypass_ptr         <= bpu_in_ptr;
      end
      last2_bpu_in_ptr <= last_cycle_bpu_in_ptr;

      // ---- 入队后一拍：写各状态阵列（对应 Scala 718-736）----
      newest_entry_target_modified<=1'b0; newest_entry_ptr_modified<=1'b0;
      if (last_cycle_bpu_in) begin
        entry_fetch_status[last_cycle_bpu_in_ptr[PTR_W-1:0]] <= F_TO_SEND;
        cfiIndex_valid[last_cycle_bpu_in_ptr[PTR_W-1:0]]     <= last_cycle_cfiIndex_valid;
        cfiIndex_bits[last_cycle_bpu_in_ptr[PTR_W-1:0]]      <= last_cycle_cfiIndex_bits;
        pred_stage[last_cycle_bpu_in_ptr[PTR_W-1:0]]         <= last_cycle_bpu_in_stage;
        update_target[last_cycle_bpu_in_ptr[PTR_W-1:0]]      <= last_cycle_bpu_target;
        newest_entry_target_modified<=1'b1; newest_entry_target<=last_cycle_bpu_target;
        newest_entry_ptr_modified   <=1'b1; newest_entry_ptr   <=last_cycle_bpu_in_ptr;
        // 新入队块一拍后把其 commitStateQueue 复位为全 C_EMPTY（对应 Scala 748-757
        // copied_last_cycle_bpu_in 复位块）。否则 FTQ 64 项环绕重用旧项时, 残留的
        // C_COMMITTED/C_TO_COMMIT/C_FLUSHED 会污染 canCommit/commPtr 推进。
        // 此处优先级最低: 后面的 ifu_wb(C_TO_COMMIT)/redirect-flush/rob-commit 写同一项会覆盖。
        commitStateQueue[last_cycle_bpu_in_ptr[PTR_W-1:0]] <= '0;
      end
      // 再延后一拍清 mispred（reduce fanout）
      if (last2_bpu_in) mispred_block[last2_bpu_in_ptr[PTR_W-1:0]] <= '0;

      // entry_hit_status：只用 s2 的 hit 结果（对应 Scala 775-777）
      if (io_fromBpu_resp_bits_s2_valid_3)
        entry_hit_status[io_fromBpu_resp_bits_s2_ftq_idx_value] <=
          io_fromBpu_resp_bits_s2_full_pred_3_hit ? H_HIT : H_NOT_HIT;

      // toIfu 发出后清 to_send（若未被 BPU flush）（对应 Scala 981-983）
      if (ifu_req_fire & ~ifu_req_should_be_flushed)
        entry_fetch_status[ifuPtr[PTR_W-1:0]] <= F_SENT;
      // fallThruError 触发 false-hit（对应 Scala 955-963）
      if (toIfu_fallThruErr & (entry_hit_status[ifuPtr[PTR_W-1:0]]==H_HIT) & ifu_req_fire
          & ~(bpu_s2_redirect & (s2_flush_ptr==ifuPtr)) & ~(bpu_s3_redirect & (s3_flush_ptr==ifuPtr)))
        entry_hit_status[ifuPtr[PTR_W-1:0]] <= H_FALSE_HIT;

      // ---- to IFU/ICache/Prefetch 的流水寄存器 ----
      last_cycle_to_ifu_fire <= ifu_req_fire;
      last_cycle_to_pf_fire  <= pf_req_fire;
      // toIfuPcBundle = 单级 RegNext(pc_mem rdata)：cur 用 ifuPtr_rdata，p1 用 ifuPtrPlus1_rdata
      toIfuPc_cur_startAddr<=pcmem_ifuPtr_startAddr; toIfuPc_cur_nextLineAddr<=pcmem_ifuPtr_nextLineAddr;
      toIfuPc_cur_fallThruErr<=pcmem_ifuPtr_fallThruErr;
      toIfuPc_p1_startAddr<=pcmem_ifuP1_startAddr; toIfuPc_p1_nextLineAddr<=pcmem_ifuP1_nextLineAddr;
      toIfuPc_p1_fallThruErr<=pcmem_ifuP1_fallThruErr;
      entry_send_a   <= (entry_fetch_status[ifuPtr[PTR_W-1:0]]==F_TO_SEND);
      entry_send_b   <= (last_cycle_bpu_in & (bpu_in_bypass_ptr==ifuPtr));
      entry_send_p1_a<= (entry_fetch_status[ifuPtrPlus1[PTR_W-1:0]]==F_TO_SEND);
      entry_send_p1_b<= (last_cycle_bpu_in & (bpu_in_bypass_ptr==ifuPtrPlus1));
      // entry_next_addr 的 base：cur 用 RegNext(ifuPtrPlus1_rdata)，p1 用 RegNext(ifuPtrPlus2_rdata)
      enext_cur_reg <= pcmem_ifuP1_startAddr;
      enext_p1_reg  <= pcmem_ifuP2_startAddr;
      // prefetch 提前一拍
      toPrefetchPc_startAddr<=nextPfPc_startAddr; toPrefetchPc_nextLineAddr<=nextPfPc_nextLineAddr;
      toPrefetchEntryToSend <=nextPfEntryToSend;

      // ---- IFU 写回：commitStateQueue 标 toCommit（对应 Scala 1006-1016）----
      if (ifu_wb_valid)
        for (int i=0;i<PREDICT_W;i++)
          if (pdwb_pd_valid[i] & pdwb_instrRange[i]) commitStateQueue[ifu_wb_idx][i] <= C_TO_COMMIT;
      // false-hit 检测打拍寄存
      hit_pd_mispred_reg <= hit_pd_mispred;
      hit_pd_valid_reg   <= hit_pd_valid;
      pd_reg_valid<=pdwb_pd_valid; pd_reg_isRVC<=pdwb_pd_isRVC; pd_reg_brType<=pdwb_pd_brType;
      pd_reg_isCall<=pdwb_pd_isCall; pd_reg_isRet<=pdwb_pd_isRet;
      for (int i=0;i<PREDICT_W;i++) begin
        pd_reg_isBr[i]   <= (pdwb_pd_brType[i]==2'd1);
        pd_reg_isJal[i]  <= (pdwb_pd_brType[i]==2'd2);
        pd_reg_isJalr[i] <= (pdwb_pd_brType[i]==2'd3);
      end
      wb_idx_reg <= ifu_wb_idx;
      if (has_false_hit) entry_hit_status[wb_idx_reg] <= H_FALSE_HIT;

      // ---- IFU redirect 打拍 + ifuRedirected 记录（对应 Scala 1156-1174）----
      ifu_redir_reg_valid  <= ifu_redir_valid;
      if (ifu_redir_valid) begin // RegNextWithEnable：bits 仅在 fromIfuRedirect.valid 时更新
        ifu_redir_reg_ptr    <= ifu_redir_ptr;
        ifu_redir_reg_offset <= ifu_redir_offset;
        ifu_redir_reg_pc     <= pdwb_pc[ifu_redir_offset];
        ifu_redir_reg_target <= io_fromIfu_pdWb_bits_target;
        ifu_redir_reg_pd_valid <= pdwb_pd_valid[ifu_redir_offset];
        ifu_redir_reg_pd_isRVC <= pdwb_pd_isRVC[ifu_redir_offset];
        ifu_redir_reg_pd_isCall<= pdwb_pd_isCall[ifu_redir_offset];
        ifu_redir_reg_pd_isRet <= pdwb_pd_isRet[ifu_redir_offset];
        ifu_redir_reg_pd_brType<= pdwb_pd_brType[ifu_redir_offset];
        ifu_redir_reg_predTaken<= cfiIndex_valid[io_fromIfu_pdWb_bits_ftqIdx_value];
        ifu_redir_reg_taken    <= io_fromIfu_pdWb_bits_cfiOffset_valid;
        ifu_redir_reg_isMisPred<= io_fromIfu_pdWb_bits_misOffset_valid;
      end
      if (ifu_redir_reg_valid) ifuRedirected[ifu_redir_reg_ptr[PTR_W-1:0]] <= 1'b1;
      else if (last_cycle_bpu_in) ifuRedirected[last_cycle_bpu_in_ptr[PTR_W-1:0]] <= 1'b0;

      // ---- redirect 更新 cfiIndex/mispred/newest（对应 Scala 1212-1240）----
      // 优先后端 redirect，否则 IFU redirect
      // updateCfiInfo：据重定向修正该项的 cfiIndex（taken 槽前移/取消）、记录目标与误预测
      if (fbr_valid) begin
        if ((fbr_cfi_taken & (fbr_offset < cfiIndex_bits[fbr_idx_value])) | (fbr_offset==cfiIndex_bits[fbr_idx_value]))
          cfiIndex_valid[fbr_idx_value] <= (fbr_cfi_taken & (fbr_offset < cfiIndex_bits[fbr_idx_value]))
                                           | ((fbr_offset==cfiIndex_bits[fbr_idx_value]) & fbr_cfi_taken);
        else if (~fbr_cfi_taken & (fbr_offset != cfiIndex_bits[fbr_idx_value]))
          cfiIndex_valid[fbr_idx_value] <= 1'b0;
        if (fbr_cfi_taken & (fbr_offset < cfiIndex_bits[fbr_idx_value]))
          cfiIndex_bits[fbr_idx_value] <= fbr_offset;
        update_target[fbr_idx_value] <= fbr_cfi_target;
        mispred_block[fbr_idx_value][fbr_offset] <= fbr_cfi_ismispred;
        newest_entry_target_modified<=1'b1; newest_entry_target<=fbr_cfi_target;
        newest_entry_ptr_modified   <=1'b1; newest_entry_ptr   <=mk_ptr(fbr_idx_flag,fbr_idx_value);
      end else if (ifu_redir_reg_valid) begin
        if ((ifu_redir_reg_taken & (ifu_redir_reg_offset < cfiIndex_bits[ifu_redir_reg_ptr[PTR_W-1:0]]))
             | (ifu_redir_reg_offset==cfiIndex_bits[ifu_redir_reg_ptr[PTR_W-1:0]]))
          cfiIndex_valid[ifu_redir_reg_ptr[PTR_W-1:0]] <=
            (ifu_redir_reg_taken & (ifu_redir_reg_offset < cfiIndex_bits[ifu_redir_reg_ptr[PTR_W-1:0]]))
            | ((ifu_redir_reg_offset==cfiIndex_bits[ifu_redir_reg_ptr[PTR_W-1:0]]) & ifu_redir_reg_taken);
        else if (~ifu_redir_reg_taken & (ifu_redir_reg_offset != cfiIndex_bits[ifu_redir_reg_ptr[PTR_W-1:0]]))
          cfiIndex_valid[ifu_redir_reg_ptr[PTR_W-1:0]] <= 1'b0;
        if (ifu_redir_reg_taken & (ifu_redir_reg_offset < cfiIndex_bits[ifu_redir_reg_ptr[PTR_W-1:0]]))
          cfiIndex_bits[ifu_redir_reg_ptr[PTR_W-1:0]] <= ifu_redir_reg_offset;
        // IFU-redirect 写入的 target 须用 ifuToBpu_target（ret 用 RAS topAddr 替换），
        // 与 golden ifuRedirectToBpu_bits_cfiUpdate_target 一致，否则 ret 项 newest/update_target 取原始
        // cfiUpdate_target 而非 RAS 目标，导致 io_toIfu_req_bits_nextStartAddr 失配。
        update_target[ifu_redir_reg_ptr[PTR_W-1:0]] <= ifuToBpu_target;
        newest_entry_target_modified<=1'b1; newest_entry_target<=ifuToBpu_target;
        newest_entry_ptr_modified   <=1'b1; newest_entry_ptr   <=ifu_redir_reg_ptr;
      end

      // ---- redirect 冲刷 commitStateQueue（对应 Scala 1303-1318）----
      // 打一拍后清/标 flushed
      flush_csq_valid_q <= redir_any;
      flush_csq_notIfu_q<= redir_notIfu;
      flush_csq_idx_q   <= redir_idx[PTR_W-1:0];
      flush_csq_off_q   <= redir_offset;
      flush_csq_flushItself_q <= redir_flushItself; // flushItself = redirect.level(0)（修正：原 ~level 取反错误）
      if (flush_csq_valid_q & flush_csq_notIfu_q)
        for (int i=0;i<PREDICT_W;i++) begin
          if (i[3:0] >  flush_csq_off_q)                              commitStateQueue[flush_csq_idx_q][i]<=C_EMPTY;
          if (i[3:0] == flush_csq_off_q & flush_csq_flushItself_q)    commitStateQueue[flush_csq_idx_q][i]<=C_FLUSHED;
        end

      // ---- rob commit 标 committed（对应 Scala 1326-1346）----
      for (int c=0;c<8;c++) if (robc_valid[c]) begin
        commitStateQueue[robc_idx_value[c]][robc_offset[c]] <= C_COMMITTED;
        if (robc_type[c]==3'd4) commitStateQueue[robc_idx_value[c]][robc_offset[c]+4'd1] <= C_COMMITTED;
        else if (robc_type[c]==3'd5) commitStateQueue[robc_idx_value[c]][robc_offset[c]+4'd2] <= C_COMMITTED;
        else if (robc_type[c]==3'd6) commitStateQueue[(robc_idx_value[c]+6'd1)][0] <= C_COMMITTED;
        else if (robc_type[c]==3'd7) commitStateQueue[(robc_idx_value[c]+6'd1)][1] <= C_COMMITTED;
      end

      // ---- bpu_ftb_update_stall 状态机（对应 Scala 1457-1472）----
      if (bpu_ftb_update_stall==2'd0) begin
        if (commit_cfi_valid_can & ~to_bpu_hit & canCommit) bpu_ftb_update_stall<=2'd2;
      end else if (bpu_ftb_update_stall==2'd2) bpu_ftb_update_stall<=2'd1;
      else if (bpu_ftb_update_stall==2'd1) bpu_ftb_update_stall<=2'd0;

      // ---- backendException / backendPcFaultPtr（对应 Scala 596-612）----
      if (fbr_valid) begin
        backendException <= fbr_cfi_ipf ? 2'd1 : fbr_cfi_igpf ? 2'd2 : fbr_cfi_iaf ? 2'd3 : 2'd0;
        if (fbr_cfi_ipf | fbr_cfi_igpf | fbr_cfi_iaf) backendPcFaultPtr <= ifuWbPtr_w;
      end else if (ifuWbPtr != backendPcFaultPtr) backendException <= 2'd0;

      // ---- commit 读出寄存（对应 Scala 1410-1453）----
      commit_pc_startAddr   <= pcmem_commPtr_startAddr;
      commit_pc_p1_startAddr_r <= pcmem_commP1_startAddr;
      commit_newest_eq      <= commPtr_eq_newest;
      if (newest_entry_target_modified) commit_newest_target <= newest_entry_target;
      do_commit <= canCommit;
      if (canCommit) begin
        do_commit_ptr  <= commPtr;
        commit_state   <= commitStateQueue[commPtr[PTR_W-1:0]];
        commit_cfi_valid <= cfiIndex_valid[commPtr[PTR_W-1:0]];
        commit_cfi_bits  <= cfiIndex_bits[commPtr[PTR_W-1:0]];
        commit_mispred_raw <= mispred_block[commPtr[PTR_W-1:0]];
        commit_hit     <= entry_hit_status[commPtr[PTR_W-1:0]];
        commit_stage   <= pred_stage[commPtr[PTR_W-1:0]];
      end

      // ---- toBackend 寄存（对应 Scala 1180-1188）----
      tobk_pc_mem_wen   <= last_cycle_bpu_in;
      if (last_cycle_bpu_in) begin
        tobk_pc_mem_waddr      <= last_cycle_bpu_in_ptr[PTR_W-1:0];
        tobk_pc_mem_wdata_start<= bpu_in_bypass_startAddr;
      end
      newest_en_q1 <= last_cycle_bpu_in | be_redir_valid | ifu_redir_reg_valid;
      newest_en_q2 <= newest_en_q1;
      if (newest_en_q1) begin tobk_newest_ptr<=newest_entry_ptr; tobk_newest_target<=newest_entry_target; end

      // ---- mmio ----
      mmio_last_commit_q <= mmio_last_commit;
    end
  end

endmodule
