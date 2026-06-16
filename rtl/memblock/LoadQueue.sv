// ============================================================================
// xs_LoadQueue_core —— Load 队列层顶层（香山 V2R2 LSU load 侧队列总集成）
// ----------------------------------------------------------------------------
// 设计意图来源：src/main/scala/xiangshan/mem/lsqueue/LoadQueue.scala（class LoadQueue）
//
// 在乱序访存子系统里，本模块把 6 个子队列拼装成统一的 load 队列层。它**只承担
// 路由 / 分发 / 汇聚 / 仲裁的 glue**，队列算法本身都封装在子队列里（这些子队列对
// 本层而言是黑盒，UT/FM 两侧共用同一份 golden 定义）：
//   * VirtualLoadQueue —— load 地址/状态主体；给出已写回指针 ldWbPtr（= lqDeqPtr）
//   * LoadQueueRAR     —— load-load(read-after-read) 违例检测
//   * LoadQueueRAW     —— store-load(read-after-write / nuke) 违例检测；nuke_rollback
//   * LoadQueueReplay  —— 重放调度
//   * LoadQueueUncache —— 非缓存 / MMIO load；nack_rollback 与 mmio exception
//   * LqExceptionBuffer—— 异常聚合，给出 exceptionAddr
//
// LoadQueue 顶层真正手写的 glue 只有以下几件（绝大多数端口是上游/下游与子队列之间
// 的直通连线，见 LoadQueue_inst.svh）：
//   1) 分发：enq / nuke_query / sta / std / redirect / release 等向各子队列直通
//      （由生成的连接表完成，不在本文件出现逻辑）。
//   2) 子队列互联：VirtualLoadQueue 的 ldWbPtr 扇出给 RAR / Replay（以及顶层
//      lqDeqPtr）；RAR / RAW 的 lqFull 喂给 Replay 做反压。
//   3) 拥塞汇聚：full_mask = {RAR, RAW, Replay}.lqFull，供 perf 译码。
//   4) 异常 req 组装：LqExceptionBuffer 的 6 路 req（3 路标量 ldin、2 路向量反馈、
//      1 路 mmio 非数据异常）。其中“是否为标量 load”等 valid 修饰在连接表里以
//      与运算给出；第 6 路来自 uncacheBuffer 的 exception 输出（核内 readable 网）。
//   5) rollback 广播：RAW 的两路 rollback → nuke_rollback；uncacheBuffer 的 rollback
//      → nack_rollback。
//   6) perf：28 路性能事件各打两拍后输出（前 18 路取自子队列，后 10 路为 full_mask
//      译码与 rollback 等组合条件）。
//
// 验证：UT 与 golden LoadQueue 双例化逐拍比对全部输出；FM 以 6 个子队列为两侧共享
//       golden 黑盒、对本层 glue 做签名等价。
// ============================================================================
module xs_LoadQueue_core
  import loadqueue_pkg::*;
(
  `include "LoadQueue_ports.svh"
);

  // ==========================================================================
  // 0. 子队列之间 / 子队列→顶层的内部互联网声明
  // --------------------------------------------------------------------------
  // 这些网由 LoadQueue_inst.svh 里的子队列实例驱动或消费，是本层 glue 的载体。
  // ==========================================================================

  // -- VirtualLoadQueue 的已写回指针（ldWbPtr，环形队列指针）：扇出给 RAR / Replay --
  //    及顶层 lqDeqPtr。用 lq_ptr_t 结构体表达 {flag, value}，与 Scala 的 LqPtr 对应。
  lq_ptr_t vlq_ldWbPtr;

  // -- 三个会“满”的子队列的拥塞标志（用于反压与 perf 译码）--
  logic rar_full;     // LoadQueueRAR 满
  logic raw_full;     // LoadQueueRAW 满
  logic replay_full;  // LoadQueueReplay 满

  // -- RAW 的两路 store-load 违例回滚有效（→ nuke_rollback + perf）--
  logic [LD_PIPE_WIDTH-2:0] raw_rollback_valid;  // 两路（LdPipe-1=2 路：[1:0]）

  // -- uncacheBuffer 的回滚（→ nack_rollback + perf）--
  logic unc_rollback_valid;

  // -- uncacheBuffer 的 mmio 非数据异常输出（→ LqExceptionBuffer 第 6 路 req）--
  //    字段与 golden 一致：robIdx_value/uopIdx 多 bit，fullva/gpaddr 64 bit，其余 1 bit。
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

  // ==========================================================================
  // 1. 子队列互联（ldWbPtr / lqFull）
  // --------------------------------------------------------------------------
  // 这些互联的方向已在连接表里给出（RAR/Replay 的 ldWbPtr 输入连 vlq_ldWbPtr_*、
  // Replay 的 rarFull/rawFull 输入连 rar_full/raw_full）。本层只把 VirtualLoadQueue
  // 的 ldWbPtr 再镜像到顶层 lqDeqPtr 输出（队列出队指针对外可见）。
  // ==========================================================================
  assign io_lqDeqPtr_flag  = vlq_ldWbPtr.flag;
  assign io_lqDeqPtr_value = vlq_ldWbPtr.value;

  // ==========================================================================
  // 2. 拥塞汇聚 full_mask
  // --------------------------------------------------------------------------
  // 把三个会“满”的子队列的满标志拼成 3 bit：{RAR, RAW, Replay}（与 Scala 的
  //   Cat(loadQueueRAR.lqFull, loadQueueRAW.lqFull, loadQueueReplay.lqFull) 一致）。
  // full_mask 不出顶层，仅用于 perf 译码“哪些子队列同时满”，用于性能分析。
  // ==========================================================================
  full_state_e full_mask;
  assign full_mask = full_state_e'({rar_full, raw_full, replay_full});

  // ==========================================================================
  // 3. rollback 广播
  // --------------------------------------------------------------------------
  // store-load(nuke) 违例由 RAW 检出，两路 rollback 直接广播到顶层 nuke_rollback
  // （bits 字段在连接表里由 RAW 直连顶层，这里只接 valid）。
  // 非缓存 load 的 nack 回滚由 uncacheBuffer 给出，接到 nack_rollback（单路）。
  // ==========================================================================
  assign io_nuke_rollback_0_valid = raw_rollback_valid[0];
  assign io_nuke_rollback_1_valid = raw_rollback_valid[1];
  assign io_nack_rollback_0_valid = unc_rollback_valid;

  // ==========================================================================
  // 4. 性能事件（perf）：源选择 + 两级打拍
  // --------------------------------------------------------------------------
  // 28 路性能计数：
  //   前 18 路（perf_src[0..17]）由子队列直接给出 6-bit 计数（连接表已把子队列
  //   的 perf 输出接到 perf_src[*]）。
  //   后 10 路（perf_src[18..27]）是本层产生的 1-bit 组合条件：
  //     18..24 ：full_mask == 0..6（各拥塞组合各计一次）
  //     25     ：full_mask 全 1（三队列同时满）
  //     26     ：nuke_rollback（RAW 任一路回滚）
  //     27     ：nack_rollback（uncache 回滚）
  // 全部各打两拍对齐后输出，降低长扇出对时序的影响（与 Scala 的两级寄存器一致）。
  // ==========================================================================
  logic [PERF_W-1:0] perf_src   [PERF_NUM];
  logic [PERF_W-1:0] perf_stage1[PERF_NUM];
  logic [PERF_W-1:0] perf_stage2[PERF_NUM];

  // 后 10 路组合条件（前 18 路 perf_src[0..17] 由连接表里的子队列输出驱动）。
  // 18..25 是 full_mask 落在 8 种拥塞状态各一路；26 是 nuke 回滚、27 是 nack 回滚。
  // full_is / perf_bit 为纯函数，避免裸常数比较与位拼接魔数。
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

  `include "LoadQueue_perf_out.svh"  // assign io_perf_<i>_value = perf_stage2[i]（后 10 路零扩展）

  // ==========================================================================
  // 5. 六个子队列实例（与 golden 完全一致；黑盒）
  // --------------------------------------------------------------------------
  // 直通端口连顶层同名口；子队列互联 / 汇聚 glue 连上面的 readable 网；
  // 异常 req 的 valid 修饰（如 ldin.valid & ~isvec、ldin.valid & ~nc_with_data）
  // 在连接表里以与运算就地给出。
  // ==========================================================================
  `include "LoadQueue_inst.svh"

endmodule
