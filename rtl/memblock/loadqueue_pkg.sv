// ============================================================================
// loadqueue_pkg —— LoadQueue 顶层（load 队列层）的公共类型与参数
// ----------------------------------------------------------------------------
// 设计意图来源：src/main/scala/xiangshan/mem/lsqueue/LoadQueue.scala（class LoadQueue）
//
// LoadQueue 是香山 V2R2 乱序访存（LSU）里 load 侧的“队列层”顶层：它把 6 个子队列
// 拼装成统一的 load 队列接口，本层只做**路由 / 分发 / 汇聚 / 仲裁的 glue**，队列
// 算法本身都在子队列里：
//   * VirtualLoadQueue —— load 地址/状态主体；给出已写回指针 ldWbPtr（= lqDeqPtr）
//   * LoadQueueRAR     —— load-load(read-after-read) 违例检测
//   * LoadQueueRAW     —— store-load(read-after-write / nuke) 违例检测；nuke_rollback
//   * LoadQueueReplay  —— 重放调度
//   * LoadQueueUncache —— 非缓存 / MMIO load；nack_rollback 与 mmio exception
//   * LqExceptionBuffer—— 异常聚合，给出 exceptionAddr
//
// 本 pkg 仅定义少量本层 glue 用到的类型/参数；子队列内部类型不在此声明（它们是
// golden 黑盒，UT/FM 两侧共用同一份 golden 定义）。
// ============================================================================
package loadqueue_pkg;

  // ---- 流水宽度 / 队列规模（与本配置的 firtool 展开一致）----
  localparam int LD_PIPE_WIDTH      = 3;   // load 流水/查询条数（nuke_query 为 0..2）
  localparam int VEC_LD_PIPE_WIDTH  = 2;   // 向量 load 反馈条数（vecFeedback 0..1）
  localparam int SQ_SIZE            = 56;  // StoreQueue 表项数（地址/数据就绪向量宽度）

  // ---- LqExceptionBuffer 的 req 路数：3 路标量 ldin + 2 路向量反馈 + 1 路 mmio ----
  localparam int EXC_REQ_NUM        = LD_PIPE_WIDTH + VEC_LD_PIPE_WIDTH + 1; // 6

  // ---- 性能事件 ----
  //  io_perf_0..27 共 28 路：
  //    0      ← VirtualLoadQueue.perf_0
  //    1..2   ← LoadQueueRAR.perf_0..1
  //    3..4   ← LoadQueueRAW.perf_0..1
  //    5..17  ← LoadQueueReplay.perf_0..12
  //   （以上 18 路为子队列给出的 6-bit 计数，PERF_SUBQ_NUM=18）
  //    18..25 ← full_mask 8 个译码：0..6（18..24）+ 全 1（=7，25）
  //    26     ← nuke_rollback（RAW 任一路回滚）
  //    27     ← uncache(nack) rollback
  //   （后 10 路为 1-bit 组合条件，零扩展到 6 bit；与 LoadQueue.sv:116-137 一致）
  localparam int PERF_NUM      = 28;
  localparam int PERF_SUBQ_NUM = 18;  // 前 18 路来自子队列（6-bit 计数）
  localparam int PERF_W        = 6;   // 每个计数器位宽

  // ---- 环形队列指针：{flag, value}（对应 Scala 的 CircularQueuePtr / LqPtr）----
  //  VirtualLoadQueue 的已写回指针 ldWbPtr 即此类型；本层把它扇出给 RAR/Replay，
  //  并镜像到顶层 lqDeqPtr。value 为队列内序号，flag 为环形回绕标志。
  localparam int LQ_PTR_VALUE_W = 7;
  typedef struct packed {
    logic                      flag;
    logic [LQ_PTR_VALUE_W-1:0] value;
  } lq_ptr_t;

  // ---- full_mask：三个会“满”的子队列的拥塞汇聚 ----
  //  bit2 = RAR 满，bit1 = RAW 满，bit0 = Replay 满（与 golden Cat 顺序一致）。
  //  full_mask 用于 perf 译码——统计“哪些子队列同时满”这一拥塞状态的发生次数。
  localparam int FULL_MASK_W = 3;

  // 把 3-bit full_mask 看作一个拥塞状态枚举，给 8 种组合命名，便于 perf 译码
  // 阅读（哪个子队列满 → 哪条性能事件计数）。命名中 R=RAR、W=RAW、P=Replay，
  // 列出当前为“满”的子队列；编码与 {RAR,RAW,Replay} 的二进制值一一对应。
  typedef enum logic [FULL_MASK_W-1:0] {
    FULL_NONE = 3'd0,  // 都不满
    FULL_P    = 3'd1,  // 仅 Replay 满
    FULL_W    = 3'd2,  // 仅 RAW 满
    FULL_WP   = 3'd3,  // RAW + Replay 满
    FULL_R    = 3'd4,  // 仅 RAR 满
    FULL_RP   = 3'd5,  // RAR + Replay 满
    FULL_RW   = 3'd6,  // RAR + RAW 满
    FULL_RWP  = 3'd7   // 三者同时满
  } full_state_e;

  // ----------------------------------------------------------------------
  // full_is：判断当前 full_mask 是否等于某个拥塞状态。
  //   用于 perf 18..24（full_mask == 0..6）与 25（==7 / 全满）的译码，
  //   把“哪些子队列同时满”用有名字的状态表达，而非裸比较常数。
  // ----------------------------------------------------------------------
  function automatic logic full_is(input logic [FULL_MASK_W-1:0] mask,
                                   input full_state_e             st);
    return mask == st;
  endfunction

endpackage
