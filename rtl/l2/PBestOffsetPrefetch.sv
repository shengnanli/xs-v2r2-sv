// =============================================================================
// PBestOffsetPrefetch —— L2 的 Best-Offset 预取器（物理地址训练版，"PBOP"）
//
// Scala：coupledL2/src/main/scala/coupledL2/prefetch/BestOffsetPrefetch.scala，
//   class PBestOffsetPrefetch。L2 Prefetcher 里与 VBOP（虚地址版）并列。
//
// 算法（Michaud 2016 的 BOP）：
//   * 每个训练请求（L2 的 miss / 预取命中，物理块地址 {tag,set}）同时送三处：
//       - scoreTable（OffsetScoreTable，37 个候选偏移轮流打分，选出当前最佳偏移 D）；
//       - delayQueue（DelayQueue，按 io_pfCtrlOfDelayLatency 把地址延迟若干拍）
//         → rrTable（RecentRequestTable，"最近请求表"，存延迟后的地址）；
//       - 本层：用当前最佳偏移 D 算出预取地址 newAddr = trainAddr + D*64，打一拍发出去。
//   * scoreTable 打分时问 rrTable："trainAddr - 候选偏移 最近被请求过吗"，命中就给该候选加分。
//
// 本层自己的逻辑只有一级"预取请求寄存器"：
//   §1 训练握手：scoreTable 收下训练（st_fire）时算 newAddr 与跨页判断；
//   §2 请求寄存器 req_*：st_fire 时装入；跨页或 scoreTable 说"禁用"就不发（req_valid=0）；
//      L2 收下请求（io_req fire）清 valid；
//   §3 输出：io_req_bits_vaddr 恒 0（物理版没有虚地址）。
//
// 怪癖（照 golden）：
//   * io_train_ready = scoreTable.ready & (~req_valid | io_req_ready)，用的是**未经 enable 门控**的
//     req_valid；而 io_req_valid = enable & req_valid。enable=0 时请求寄存器满着就会一直反压训练。
//   * Scala 还有 delayQueue.io.in.ready 一项，DelayQueue 恒 ready，firtool 已折掉。
//   * io_resp（预取回填响应）只用到 ready：io_resp_ready = rrTable.io_w_ready；io_resp_valid 仅进
//     perf 计数，综合视图零扇出。
//   * golden 里大量 _GEN_n（prefetchOffset == 常数）是被删掉的 perf 计数器残骸，零扇出，不照抄。
//
// child（实例名与 golden 一致，均已签核，两侧白盒）：
//   delayQueue = DelayQueue（rtl/l2/DelayQueue.sv）
//   rrTable    = RecentRequestTable（rtl/uncore/RecentRequestTable.sv，内含 SRAMTemplate_146 + 厂商宏）
//   scoreTable = OffsetScoreTable（rtl/l2/OffsetScoreTable.sv）
//   boreChildrenBd_* / sigFromSrams_* 是 MBIST / SRAM DFT 穿线，原样接给 rrTable。
// =============================================================================

module PBestOffsetPrefetch(
  input         clock,
  input         reset,
  input         io_enable,
  input  [9:0]  io_pfCtrlOfDelayLatency,
  output        io_train_ready,
  input         io_train_valid,
  input  [32:0] io_train_bits_tag,
  input  [8:0]  io_train_bits_set,
  input         io_train_bits_needT,
  input  [6:0]  io_train_bits_source,
  input         io_req_ready,
  output        io_req_valid,
  output [32:0] io_req_bits_tag,
  output [8:0]  io_req_bits_set,
  output [43:0] io_req_bits_vaddr,
  output        io_req_bits_needT,
  output [6:0]  io_req_bits_source,
  output        io_resp_ready,
  input         io_resp_valid,
  input  [8:0]  boreChildrenBd_bore_addr,
  input  [8:0]  boreChildrenBd_bore_addr_rd,
  input  [12:0] boreChildrenBd_bore_wdata,
  input         boreChildrenBd_bore_wmask,
  input         boreChildrenBd_bore_re,
  input         boreChildrenBd_bore_we,
  output [12:0] boreChildrenBd_bore_rdata,
  input         boreChildrenBd_bore_ack,
  input         boreChildrenBd_bore_selectedOH,
  input         boreChildrenBd_bore_array,
  input         sigFromSrams_bore_ram_hold,
  input         sigFromSrams_bore_ram_bypass,
  input         sigFromSrams_bore_ram_bp_clken,
  input         sigFromSrams_bore_ram_aux_clk,
  input         sigFromSrams_bore_ram_aux_ckbp,
  input         sigFromSrams_bore_ram_mcp_hold,
  input         sigFromSrams_bore_cgen
);

  localparam int unsigned BLOCK_OFF_W = 6;    // 64B cache 块
  localparam int unsigned PAGE_OFF_W  = 12;   // 4KB 页
  localparam int unsigned ADDR_W      = 48;   // 物理地址宽

  // ---- child 互连 ----
  logic                st_reqReady;          // scoreTable 能收训练
  logic [6:0]          st_prefetchOffset;    // 当前最佳偏移（单位：块，7 位补码）
  logic                st_prefetchDisable;   // 最佳得分太低：不发预取
  logic                st_testValid;         // scoreTable -> rrTable 查询
  logic [ADDR_W-1:0]   st_testAddr;
  logic [6:0]          st_testOffset;
  logic [5:0]          st_testPtr;
  logic                rrt_wReady;           // rrTable 能收写
  logic                rrt_respValid;        // rrTable -> scoreTable 查询结果
  logic [5:0]          rrt_respPtr;
  logic                rrt_respHit;
  logic                dq_outValid;          // delayQueue -> rrTable
  logic [ADDR_W-1:0]   dq_outBits;

  // ===========================================================================
  // §1 训练握手与预取地址
  //   训练地址 = {tag, set, 块内偏移 0}；预取地址 = 训练地址 + 最佳偏移 × 64（偏移符号扩展）。
  //   跨页 = 两者页号（地址 [47:12]）不同；BOP 不跨页预取。
  // ===========================================================================
  logic [ADDR_W-1:0] trainAddr;
  logic [ADDR_W-1:0] prefetchAddr;
  logic              crossPage;
  logic              st_fire;      // scoreTable 收下本拍训练

  assign trainAddr    = {io_train_bits_tag, io_train_bits_set, 6'h0};
  assign prefetchAddr = trainAddr + {{(ADDR_W - 7 - BLOCK_OFF_W){st_prefetchOffset[6]}},
                                     st_prefetchOffset, 6'h0};
  assign crossPage    = prefetchAddr[ADDR_W-1:PAGE_OFF_W] != trainAddr[ADDR_W-1:PAGE_OFF_W];
  assign st_fire      = st_reqReady & io_train_valid;

  // ===========================================================================
  // §2 预取请求寄存器（一项）
  //   st_fire 时装入新请求；跨页或被禁用则装入但不置 valid。
  //   否则 L2 收下请求（io_req fire）时清 valid。
  // ===========================================================================
  logic [32:0] req_tag;
  logic [8:0]  req_set;
  logic        req_needT;
  logic [6:0]  req_source;
  logic        req_valid;
  logic        req_fire;

  assign req_fire = io_req_ready & io_req_valid;

  always_ff @(posedge clock) begin
    if (st_fire) begin
      req_tag    <= prefetchAddr[ADDR_W-1:15];
      req_set    <= prefetchAddr[14:BLOCK_OFF_W];
      req_needT  <= io_train_bits_needT;
      req_source <= io_train_bits_source;
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      req_valid <= 1'b0;
    else if (st_fire)
      req_valid <= ~crossPage & ~st_prefetchDisable;
    else if (req_fire)
      req_valid <= 1'b0;
  end

  // ===========================================================================
  // §3 输出
  // ===========================================================================
  assign io_train_ready     = st_reqReady & (~req_valid | io_req_ready);
  assign io_req_valid       = io_enable & req_valid;
  assign io_req_bits_tag    = req_tag;
  assign io_req_bits_set    = req_set;
  assign io_req_bits_vaddr  = 44'h0;
  assign io_req_bits_needT  = req_needT;
  assign io_req_bits_source = req_source;
  assign io_resp_ready      = rrt_wReady;

  // ===========================================================================
  // §4 child：延迟队列 → 最近请求表 ← 偏移评分表
  // ===========================================================================
  DelayQueue delayQueue (
    .clock                   (clock),
    .reset                   (reset),
    .io_pfCtrlOfDelayLatency (io_pfCtrlOfDelayLatency),
    .io_in_valid             (io_train_valid),
    .io_in_bits              ({io_train_bits_tag, io_train_bits_set}),
    .io_out_ready            (rrt_wReady),
    .io_out_valid            (dq_outValid),
    .io_out_bits             (dq_outBits)
  );

  RecentRequestTable rrTable (
    .clock                          (clock),
    .reset                          (reset),
    .io_w_ready                     (rrt_wReady),
    .io_w_valid                     (dq_outValid),
    .io_w_bits                      (dq_outBits),
    .io_r_req_valid                 (st_testValid),
    .io_r_req_bits_addr             (st_testAddr),
    .io_r_req_bits_testOffset       (st_testOffset),
    .io_r_req_bits_ptr              (st_testPtr),
    .io_r_resp_valid                (rrt_respValid),
    .io_r_resp_bits_ptr             (rrt_respPtr),
    .io_r_resp_bits_hit             (rrt_respHit),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_cgen)
  );

  OffsetScoreTable scoreTable (
    .clock                       (clock),
    .reset                       (reset),
    .io_req_ready                (st_reqReady),
    .io_req_valid                (io_train_valid),
    .io_req_bits                 (trainAddr),
    .io_prefetchOffset           (st_prefetchOffset),
    .io_prefetchDisable          (st_prefetchDisable),
    .io_test_req_valid           (st_testValid),
    .io_test_req_bits_addr       (st_testAddr),
    .io_test_req_bits_testOffset (st_testOffset),
    .io_test_req_bits_ptr        (st_testPtr),
    .io_test_resp_valid          (rrt_respValid),
    .io_test_resp_bits_ptr       (rrt_respPtr),
    .io_test_resp_bits_hit       (rrt_respHit)
  );

endmodule
