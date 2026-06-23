// ============================================================================
// LoadQueue 簇 IT 装配（LSU load 侧队列层）
// ----------------------------------------------------------------------------
// = 重写 glue 核 xs_LoadQueue_core 的本体（子队列互联 / full_mask 汇聚 / 异常 req
//   组装 / rollback 广播 / perf 两级打拍），但把它例化的 6 个子队列**全部换成重写
//   叶子的 _xs 适配器**（drop-in，端口与 golden 同名模块逐字一致）：
//     LoadQueueRAR      -> LoadQueueRAR_xs      (-> xs_LoadQueueRAR_core)
//     LoadQueueRAW      -> LoadQueueRAW_xs      (-> xs_LoadQueueRAW_core)
//     LoadQueueReplay   -> LoadQueueReplay_xs   (-> xs_LoadQueueReplay_core)
//     VirtualLoadQueue  -> VirtualLoadQueue_xs  (-> xs_VirtualLoadQueue_core)
//     LqExceptionBuffer -> LqExceptionBuffer_xs (-> xs_LqExceptionBuffer_core)
//     LoadQueueUncache  -> LoadQueueUncache_xs  (-> xs_LoadQueueUncache_core)
//
//   每个 _xs 内部只例化重写核 xs_<M>_core；算法逻辑全部是重写件。
//   叶子边界 = golden 存储/结构原语（两侧共享、非算法）：
//     xs_LoadQueueReplay_core 内：LqVAddrModule / FreeList_5 / AgeDetector_38
//     xs_LoadQueueUncache_core 内：UncacheEntry* / FreeList_6 / RRArbiterInit_9 /
//                                  PipelineRegModule*
//   这些是存储模型 / 仲裁结构件，按 IT 规则作为共享 golden 叶子保留。
//
//   => 本装配真正把「重写 glue 核 ↔ 6 个重写子队列核」的集成边界全部连起来跑，
//      这正是 per-module UT（单核被 golden 子队列包围）覆盖不到的部分。
//
//   顶层端口 = golden LoadQueue 端口（逐字相同），供 tb 双例化逐拍比对。
// ============================================================================
module LoadQueue_it
  import loadqueue_pkg::*;
(
  `include "LoadQueue_ports.svh"
);

  // ---- 子队列之间 / 子队列->顶层的内部互联网（与 xs_LoadQueue_core 一致）----
  lq_ptr_t vlq_ldWbPtr;

  logic rar_full;
  logic raw_full;
  logic replay_full;

  logic [LD_PIPE_WIDTH-2:0] raw_rollback_valid;

  logic unc_rollback_valid;

  logic        unc_exc_valid;
  logic        unc_exc_bits_uop_exceptionVec_3;
  logic        unc_exc_bits_uop_exceptionVec_4;
  logic        unc_exc_bits_uop_exceptionVec_5;
  logic        unc_exc_bits_uop_exceptionVec_13;
  logic        unc_exc_bits_uop_exceptionVec_19;
  logic        unc_exc_bits_uop_exceptionVec_21;
  logic [6:0]  unc_exc_bits_uop_uopIdx;
  logic        unc_exc_bits_uop_robIdx_flag;
  logic [7:0]  unc_exc_bits_uop_robIdx_value;
  logic [63:0] unc_exc_bits_fullva;
  logic [63:0] unc_exc_bits_gpaddr;
  logic        unc_exc_bits_isHyper;
  logic        unc_exc_bits_isForVSnonLeafPTE;

  // ---- 1. 子队列互联（ldWbPtr 镜像到顶层 lqDeqPtr）----
  assign io_lqDeqPtr_flag  = vlq_ldWbPtr.flag;
  assign io_lqDeqPtr_value = vlq_ldWbPtr.value;

  // ---- 2. 拥塞汇聚 full_mask ----
  full_state_e full_mask;
  assign full_mask = full_state_e'({rar_full, raw_full, replay_full});

  // ---- 3. rollback 广播 ----
  assign io_nuke_rollback_0_valid = raw_rollback_valid[0];
  assign io_nuke_rollback_1_valid = raw_rollback_valid[1];
  assign io_nack_rollback_0_valid = unc_rollback_valid;

  // ---- 4. perf：源选择 + 两级打拍 ----
  logic [PERF_W-1:0] perf_src   [PERF_NUM];
  logic [PERF_W-1:0] perf_stage1[PERF_NUM];
  logic [PERF_W-1:0] perf_stage2[PERF_NUM];

  always_comb begin
    perf_src[18] = perf_bit(full_is(full_mask, FULL_NONE));
    perf_src[19] = perf_bit(full_is(full_mask, FULL_P));
    perf_src[20] = perf_bit(full_is(full_mask, FULL_W));
    perf_src[21] = perf_bit(full_is(full_mask, FULL_WP));
    perf_src[22] = perf_bit(full_is(full_mask, FULL_R));
    perf_src[23] = perf_bit(full_is(full_mask, FULL_RP));
    perf_src[24] = perf_bit(full_is(full_mask, FULL_RW));
    perf_src[25] = perf_bit(full_is(full_mask, FULL_RWP));
    perf_src[26] = perf_bit(raw_rollback_valid[0] | raw_rollback_valid[1]);
    perf_src[27] = perf_bit(unc_rollback_valid);
  end

  for (genvar i = 0; i < PERF_NUM; i++) begin : g_perf
    always_ff @(posedge clock) begin
      perf_stage1[i] <= perf_src[i];
      perf_stage2[i] <= perf_stage1[i];
    end
  end

  `include "LoadQueue_perf_out.svh"

  // ---- 5. 六个子队列实例：全部用重写叶子的 _xs 适配器（本目录 inst_xs 连接表）----
  `include "LoadQueue_inst_xs.svh"

endmodule
