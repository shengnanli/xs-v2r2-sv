// =============================================================================
// VBestOffsetPrefetch —— L2 的 Best-Offset 预取器（虚地址训练版，"VBOP"）
//
// Scala：coupledL2/src/main/scala/coupledL2/prefetch/BestOffsetPrefetch.scala，
//   class VBestOffsetPrefetch（virtualTrain = true 分支）。L2 Prefetcher 里与 PBOP（物理版）并列。
//
// 与 PBOP 同一套 BOP 算法（scoreTable 选偏移 / delayQueue → rrTable 记最近请求），区别在于：
//   * 训练地址是**虚拟块地址** io_train_bits_vaddr（44 位块号，补 6 位块内偏移成 50 位 VA）；
//   * 算出的预取虚地址不能直接发给 L2，要先经 reqFilter（PrefetchReqBuffer）查 TLB 翻译成
//     物理地址，再由它发 io_req；所以本层的出口全是 reqFilter 的端口直通。
//   * 虚地址允许跨页（TLB 会翻译），没有 PBOP 那个跨页丢弃。
//
// 本层自己的逻辑是一个两级流水：
//   §1 s0：scoreTable 收下训练（s0_fire）时，用当前最佳偏移算 s1_newFullAddr = VA + 偏移×64；
//   §2 s1：一项寄存器 s1_*；s0_fire 置 valid，s1_fire（下游能收）清 valid；
//   §3 送 reqFilter：scoreTable 说"禁用"时不送（valid 门控）；io_req_valid 再与 io_enable 相与。
//
// 怪癖（照 golden）：
//   * s1_ready = io_req_ready | ~io_req_valid，看的是**本层输出**的 io_req（reqFilter 出口），
//     不是 reqFilter 的入口握手——Scala 里 s1_ready := io.req.ready || !io.req.valid。
//     而 reqFilter.io_in_req 没有 ready，s1 一旦 s1_ready 就当作已交付。
//   * Scala 的 s0_fire 还与 io.pbopCrossPage 相与，golden 里该输入已被常量折掉（恒 1），本层不出现。
//   * s0_ready / io.train.ready 与 io.tlb_req.resp.ready 在 golden 里无端口（父级未用，firtool 已删）。
//   * golden 里大量"prefetchOffset == 常数"的比较线是被删掉的 perf 计数器残骸，零扇出，不照抄；
//     io_resp_valid 同理只进 perf，零扇出。
//
// child（实例名与 golden 一致，均已签核，两侧白盒）：
//   delayQueue = DelayQueue_1、rrTable = RecentRequestTable_1、scoreTable = OffsetScoreTable_1、
//   reqFilter = PrefetchReqBuffer。boreChildrenBd_* / sigFromSrams_* 原样接给 rrTable。
// =============================================================================

module VBestOffsetPrefetch(
  input         clock,
  input         reset,
  input         io_enable,
  input  [9:0]  io_pfCtrlOfDelayLatency,
  input         io_train_valid,
  input         io_train_bits_needT,
  input  [6:0]  io_train_bits_source,
  input  [43:0] io_train_bits_vaddr,
  output        io_tlb_req_req_valid,
  output [49:0] io_tlb_req_req_bits_vaddr,
  output [2:0]  io_tlb_req_req_bits_cmd,
  output        io_tlb_req_req_bits_isPrefetch,
  output        io_tlb_req_req_bits_kill,
  output        io_tlb_req_req_bits_no_translate,
  input         io_tlb_req_resp_valid,
  input  [47:0] io_tlb_req_resp_bits_paddr_0,
  input  [1:0]  io_tlb_req_resp_bits_pbmt,
  input         io_tlb_req_resp_bits_miss,
  input         io_tlb_req_resp_bits_excp_0_gpf_ld,
  input         io_tlb_req_resp_bits_excp_0_pf_ld,
  input         io_tlb_req_resp_bits_excp_0_af_ld,
  input         io_tlb_req_pmp_resp_ld,
  input         io_tlb_req_pmp_resp_mmio,
  input         io_req_ready,
  output        io_req_valid,
  output [32:0] io_req_bits_tag,
  output [8:0]  io_req_bits_set,
  output [43:0] io_req_bits_vaddr,
  output        io_req_bits_needT,
  output [6:0]  io_req_bits_source,
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

  localparam int unsigned VADDR_W = 50;   // 虚地址宽（含 6 位块内偏移）

  // ---- child 互连 ----
  logic                st_reqReady;          // scoreTable 能收训练
  logic [9:0]          st_prefetchOffset;    // 当前最佳偏移（单位：块，10 位补码）
  logic                st_prefetchDisable;   // 最佳得分太低：不发预取
  logic                st_testValid;         // scoreTable -> rrTable 查询
  logic [VADDR_W-1:0]  st_testAddr;
  logic [9:0]          st_testOffset;
  logic [6:0]          st_testPtr;
  logic                rrt_wReady;
  logic                rrt_respValid;
  logic [6:0]          rrt_respPtr;
  logic                rrt_respHit;
  logic                dq_outValid;
  logic [VADDR_W-1:0]  dq_outBits;
  logic                rf_outValid;          // reqFilter 出口 valid（未经 enable 门控）

  // ===========================================================================
  // §1 s0：训练握手与预取虚地址
  // ===========================================================================
  logic [VADDR_W-1:0] trainFullAddr;   // {块号, 6 位 0}
  logic [VADDR_W-1:0] newFullAddr;     // trainFullAddr + 偏移 × 64（偏移符号扩展）
  logic               s0_fire;

  assign trainFullAddr = {io_train_bits_vaddr, 6'h0};
  assign newFullAddr   = trainFullAddr + {{(VADDR_W - 10 - 6){st_prefetchOffset[9]}},
                                          st_prefetchOffset, 6'h0};
  assign s0_fire       = st_reqReady & io_train_valid;

  // ===========================================================================
  // §2 s1：一项寄存器
  //   s0_fire 优先：装入新请求并置 valid；否则 s1_fire（s1_ready 且 valid）清 valid。
  // ===========================================================================
  logic              s1_req_valid;
  logic              s1_needT;
  logic [6:0]        s1_source;
  logic [VADDR_W-1:0] s1_newFullAddr;
  logic [43:0]       s1_reqVaddr;      // 训练时的原始块号（reqFilter 用作 base_vaddr）
  logic              s1_ready;
  logic              s1_fire;
  logic              s1_toFilterValid; // 送 reqFilter 的 valid（scoreTable 禁用时压掉）

  assign s1_ready = io_req_ready | ~io_req_valid;
  assign s1_fire  = s1_ready & s1_req_valid;

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      s1_req_valid <= 1'b0;
    else if (s0_fire)
      s1_req_valid <= 1'b1;
    else if (s1_fire)
      s1_req_valid <= 1'b0;
  end

  always_ff @(posedge clock) begin
    if (s0_fire) begin
      s1_needT       <= io_train_bits_needT;
      s1_source      <= io_train_bits_source;
      s1_newFullAddr <= newFullAddr;
      s1_reqVaddr    <= io_train_bits_vaddr;
    end
  end

  // ===========================================================================
  // §3 输出：reqFilter 出口直通；io_req_valid 与 io_enable 相与
  // ===========================================================================
  assign s1_toFilterValid = ~st_prefetchDisable & s1_req_valid;
  assign io_req_valid     = io_enable & rf_outValid;

  // ===========================================================================
  // §4 child：延迟队列 → 最近请求表 ← 偏移评分表；s1 → 请求过滤/翻译缓冲
  // ===========================================================================
  DelayQueue_1 delayQueue (
    .clock                   (clock),
    .reset                   (reset),
    .io_pfCtrlOfDelayLatency (io_pfCtrlOfDelayLatency),
    .io_in_valid             (io_train_valid),
    .io_in_bits              (io_train_bits_vaddr),
    .io_out_ready            (rrt_wReady),
    .io_out_valid            (dq_outValid),
    .io_out_bits             (dq_outBits)
  );

  RecentRequestTable_1 rrTable (
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

  OffsetScoreTable_1 scoreTable (
    .clock                       (clock),
    .reset                       (reset),
    .io_req_ready                (st_reqReady),
    .io_req_valid                (io_train_valid),
    .io_req_bits                 (trainFullAddr),
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

  PrefetchReqBuffer reqFilter (
    .clock                              (clock),
    .reset                              (reset),
    .io_in_req_valid                    (s1_toFilterValid),
    .io_in_req_bits_full_vaddr          (s1_newFullAddr),
    .io_in_req_bits_base_vaddr          (s1_reqVaddr),
    .io_in_req_bits_needT               (s1_needT),
    .io_in_req_bits_source              (s1_source),
    .io_tlb_req_req_valid               (io_tlb_req_req_valid),
    .io_tlb_req_req_bits_vaddr          (io_tlb_req_req_bits_vaddr),
    .io_tlb_req_req_bits_cmd            (io_tlb_req_req_bits_cmd),
    .io_tlb_req_req_bits_isPrefetch     (io_tlb_req_req_bits_isPrefetch),
    .io_tlb_req_req_bits_kill           (io_tlb_req_req_bits_kill),
    .io_tlb_req_req_bits_no_translate   (io_tlb_req_req_bits_no_translate),
    .io_tlb_req_resp_valid              (io_tlb_req_resp_valid),
    .io_tlb_req_resp_bits_paddr_0       (io_tlb_req_resp_bits_paddr_0),
    .io_tlb_req_resp_bits_pbmt          (io_tlb_req_resp_bits_pbmt),
    .io_tlb_req_resp_bits_miss          (io_tlb_req_resp_bits_miss),
    .io_tlb_req_resp_bits_excp_0_gpf_ld (io_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_tlb_req_resp_bits_excp_0_pf_ld  (io_tlb_req_resp_bits_excp_0_pf_ld),
    .io_tlb_req_resp_bits_excp_0_af_ld  (io_tlb_req_resp_bits_excp_0_af_ld),
    .io_tlb_req_pmp_resp_ld             (io_tlb_req_pmp_resp_ld),
    .io_tlb_req_pmp_resp_mmio           (io_tlb_req_pmp_resp_mmio),
    .io_out_req_ready                   (io_req_ready),
    .io_out_req_valid                   (rf_outValid),
    .io_out_req_bits_tag                (io_req_bits_tag),
    .io_out_req_bits_set                (io_req_bits_set),
    .io_out_req_bits_vaddr              (io_req_bits_vaddr),
    .io_out_req_bits_needT              (io_req_bits_needT),
    .io_out_req_bits_source             (io_req_bits_source)
  );

endmodule
