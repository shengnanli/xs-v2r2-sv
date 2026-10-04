// =============================================================================
// Prefetcher —— L2 预取总控：三个预取源 → 入队仲裁 → 预取队列 → 一级流水 → Slice 的 SinkA
//
// Scala：coupledL2/src/main/scala/coupledL2/prefetch/Prefetcher.scala，class Prefetcher。
// 位置：TL2CHICoupledL2 里（实例名 prefetcher）。本配置 hasBOP=true、hasReceiver=true、
//   hasTPPrefetcher=false（没有 TP，也就没有 tpmeta 端口）。
//
// 数据流（所有方框都是已签核的 child，本层只做胶合）：
//
//   io_train ──(滤掉 L1DataPrefetch 来的训练)──▶ pbop（物理地址 BOP）──┐
//            └────────────────────────────────▶ vbop（虚拟地址 BOP，带 TLB 口）─┤
//   io_recv_addr ──打两拍──▶ pfRcv（接收核侧 SMS/Stream/Stride/Berti 推来的预取）┤
//                                                                              ▼
//            pftQueueEnqArb（固定优先级：pfRcv > vbop > pbop）▶ pftQueue ▶ pipe ▶ io_req
//   io_resp（预取回填）── 按 pfSource 分给 pbop（PBOP=9）/ vbop（BOP=8）
//   MBIST：mbistPl（MbistPipeL2Prefetcher）把外部 MBIST 口分发到 pbop / vbop 的 RRT SRAM。
//
// 本层手写的只有胶合逻辑（xs_Prefetcher_core，§1–§4）：
//   §1 使能：pbop/vbop 的使能 = master_en & 各自 en（组合）；pfRcv 的使能打两拍（复位为 1）。
//   §2 训练过滤：reqsource == L1DataPrefetch(6) 的训练请求不喂给 BOP。
//   §3 回填分发：resp.valid 按 pfSource 只送给发出它的那个 BOP。
//   §4 出口让路：入队仲裁是固定优先级，但 Scala 额外把低优先级源的 req.ready 直接压成
//      "比我优先的源都没 valid"——不看仲裁器 / 队列是否 ready（照搬，见怪癖）。
//   §5 recv_addr 延迟两拍（ValidIODelay(io.recv_addr, 2)）：valid 复位 0；数据只在 valid 时锁存、不复位。
//
// 怪癖（照 golden）：
//   * vbop/pbop 的 io_req_ready 与仲裁器 / pftQueue 的 ready 无关：仲裁器没接住时 BOP 也认为发出去了
//     （golden 同）。pfRcv 的 req.ready 在 Scala 里恒 true，golden 的 PrefetchReceiver 已把它消掉。
//   * pfRcv_en 两级寄存器复位值是 1（RegNextN(..., 2, Some(true.B))）。
//   * Scala 里对 pfRcv.req.pfSource 的 assert（只能是 SMS/Stream/Stride/Berti）不综合，本文件不写。
//
// 本文件导航：xs_Prefetcher_core（手写胶合）→ Prefetcher（golden 同名端口表 + 7 个 child，实例名同 golden）
// =============================================================================

module xs_Prefetcher_core (
  input  logic        clock,
  input  logic        reset,
  // 核来的预取控制（CSR）
  input  logic        pf_master_en,
  input  logic        pf_recv_en,
  input  logic        pbop_en,
  input  logic        vbop_en,
  output logic        pbop_enable,
  output logic        vbop_enable,
  output logic        rcv_enable,
  // §2 训练过滤
  input  logic        train_valid,
  input  logic [4:0]  train_reqsource,
  output logic        bop_train_valid,
  // §3 回填分发
  input  logic        resp_valid,
  input  logic [4:0]  resp_pfSource,
  output logic        pbop_resp_valid,
  output logic        vbop_resp_valid,
  // §4 出口让路
  input  logic        rcv_req_valid,
  input  logic        vbop_req_valid,
  output logic        vbop_req_ready,
  output logic        pbop_req_ready,
  // §5 recv_addr 延迟两拍
  input  logic        recv_addr_valid,
  input  logic [63:0] recv_addr_addr,
  input  logic [4:0]  recv_addr_pfSource,
  output logic        rcv_recv_valid,
  output logic [63:0] rcv_recv_addr,
  output logic [4:0]  rcv_recv_pfSource
);

  // MemReqSource 编号（utility/TLUtils/BusKeyField.scala）
  localparam logic [4:0] SRC_L1_DATA_PREFETCH = 5'd6;
  localparam logic [4:0] SRC_PREFETCH2L2_BOP  = 5'd8;   // vbop 发出的预取
  localparam logic [4:0] SRC_PREFETCH2L2_PBOP = 5'd9;   // pbop 发出的预取

  // ===========================================================================
  // §1 使能
  // ===========================================================================
  logic pfRcv_en_d1;   // 第一拍
  logic pfRcv_en;      // 第二拍 = 送给 pfRcv 的使能

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      pfRcv_en_d1 <= 1'b1;
      pfRcv_en    <= 1'b1;
    end else begin
      pfRcv_en_d1 <= pf_master_en & pf_recv_en;
      pfRcv_en    <= pfRcv_en_d1;
    end
  end

  assign pbop_enable = pf_master_en & pbop_en;
  assign vbop_enable = pf_master_en & vbop_en;
  assign rcv_enable  = pfRcv_en;

  // ===========================================================================
  // §2 训练过滤：L1 数据预取引起的访问不用来训练 BOP
  // ===========================================================================
  assign bop_train_valid = train_valid & (train_reqsource != SRC_L1_DATA_PREFETCH);

  // ===========================================================================
  // §3 回填分发
  // ===========================================================================
  assign pbop_resp_valid = resp_valid & (resp_pfSource == SRC_PREFETCH2L2_PBOP);
  assign vbop_resp_valid = resp_valid & (resp_pfSource == SRC_PREFETCH2L2_BOP);

  // ===========================================================================
  // §4 出口让路：pfRcv > vbop > pbop
  // ===========================================================================
  assign vbop_req_ready = ~rcv_req_valid;
  assign pbop_req_ready = ~rcv_req_valid & ~vbop_req_valid;

  // ===========================================================================
  // §5 recv_addr 延迟两拍（ValidIODelay）
  // ===========================================================================
  logic        recvAddr_valid_d1;
  logic [63:0] recvAddr_addr_d1;
  logic [4:0]  recvAddr_pfSource_d1;
  logic        recvAddr_valid_d2;
  logic [63:0] recvAddr_addr_d2;
  logic [4:0]  recvAddr_pfSource_d2;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      recvAddr_valid_d1 <= 1'b0;
      recvAddr_valid_d2 <= 1'b0;
    end else begin
      recvAddr_valid_d1 <= recv_addr_valid;
      recvAddr_valid_d2 <= recvAddr_valid_d1;
    end
  end

  always_ff @(posedge clock) begin
    if (recv_addr_valid) begin
      recvAddr_addr_d1     <= recv_addr_addr;
      recvAddr_pfSource_d1 <= recv_addr_pfSource;
    end
    if (recvAddr_valid_d1) begin
      recvAddr_addr_d2     <= recvAddr_addr_d1;
      recvAddr_pfSource_d2 <= recvAddr_pfSource_d1;
    end
  end

  assign rcv_recv_valid    = recvAddr_valid_d2;
  assign rcv_recv_addr     = recvAddr_addr_d2;
  assign rcv_recv_pfSource = recvAddr_pfSource_d2;

endmodule

// =============================================================================
// Prefetcher —— golden 同名端口表；7 个 child 的实例名与 golden 一致
// =============================================================================
module Prefetcher (
  input         clock,
  input         reset,
  output        io_train_ready,
  input         io_train_valid,
  input  [32:0] io_train_bits_tag,
  input  [8:0]  io_train_bits_set,
  input         io_train_bits_needT,
  input  [6:0]  io_train_bits_source,
  input  [43:0] io_train_bits_vaddr,
  input  [4:0]  io_train_bits_reqsource,
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
  output [4:0]  io_req_bits_pfSource,
  output        io_resp_ready,
  input         io_resp_valid,
  input  [4:0]  io_resp_bits_pfSource,
  input         io_recv_addr_valid,
  input  [63:0] io_recv_addr_bits_addr,
  input  [4:0]  io_recv_addr_bits_pfSource,
  input         pfCtrlFromCore_l2_pf_master_en,
  input         pfCtrlFromCore_l2_pf_recv_en,
  input         pfCtrlFromCore_l2_pbop_en,
  input         pfCtrlFromCore_l2_vbop_en,
  input  [9:0]  pfCtrlFromCore_l2_pf_delay_latency,
  input         sigFromSrams_bore_ram_hold,
  input         sigFromSrams_bore_ram_bypass,
  input         sigFromSrams_bore_ram_bp_clken,
  input         sigFromSrams_bore_ram_aux_clk,
  input         sigFromSrams_bore_ram_aux_ckbp,
  input         sigFromSrams_bore_ram_mcp_hold,
  input         sigFromSrams_bore_cgen,
  input         sigFromSrams_bore_1_ram_hold,
  input         sigFromSrams_bore_1_ram_bypass,
  input         sigFromSrams_bore_1_ram_bp_clken,
  input         sigFromSrams_bore_1_ram_aux_clk,
  input         sigFromSrams_bore_1_ram_aux_ckbp,
  input         sigFromSrams_bore_1_ram_mcp_hold,
  input         sigFromSrams_bore_1_cgen,
  input         boreChildrenBd_bore_array,
  input         boreChildrenBd_bore_all,
  input         boreChildrenBd_bore_req,
  output        boreChildrenBd_bore_ack,
  input         boreChildrenBd_bore_writeen,
  input         boreChildrenBd_bore_be,
  input  [8:0]  boreChildrenBd_bore_addr,
  input  [12:0] boreChildrenBd_bore_indata,
  input         boreChildrenBd_bore_readen,
  input  [8:0]  boreChildrenBd_bore_addr_rd,
  output [12:0] boreChildrenBd_bore_outdata
);

  // ---------------------------------------------------------------------------
  // 胶合核的输出
  // ---------------------------------------------------------------------------
  logic        pbop_enable, vbop_enable, rcv_enable;
  logic        bop_train_valid;
  logic        pbop_resp_valid, vbop_resp_valid;
  logic        vbop_req_ready, pbop_req_ready;
  logic        rcv_recv_valid;
  logic [63:0] rcv_recv_addr;
  logic [4:0]  rcv_recv_pfSource;

  // ---------------------------------------------------------------------------
  // 三个预取源发出的请求（PrefetchReq）
  // ---------------------------------------------------------------------------
  logic        rcv_req_valid;
  logic [32:0] rcv_req_tag;
  logic [8:0]  rcv_req_set;
  logic [4:0]  rcv_req_pfSource;

  logic        vbop_req_valid;
  logic [32:0] vbop_req_tag;
  logic [8:0]  vbop_req_set;
  logic [43:0] vbop_req_vaddr;
  logic        vbop_req_needT;
  logic [6:0]  vbop_req_source;

  logic        pbop_req_valid;
  logic [32:0] pbop_req_tag;
  logic [8:0]  pbop_req_set;
  logic [43:0] pbop_req_vaddr;
  logic        pbop_req_needT;
  logic [6:0]  pbop_req_source;

  // 入队仲裁 → pftQueue → pipe
  logic        arb_vbop_ready, arb_pbop_ready;   // 仲裁器给 vbop / pbop 的 ready（golden 同样不用）
  logic        enq_valid;
  logic [32:0] enq_tag;
  logic [8:0]  enq_set;
  logic [43:0] enq_vaddr;
  logic        enq_needT;
  logic [6:0]  enq_source;
  logic [4:0]  enq_pfSource;

  logic        deq_valid, deq_ready;
  logic [32:0] deq_tag;
  logic [8:0]  deq_set;
  logic [43:0] deq_vaddr;
  logic        deq_needT;
  logic [6:0]  deq_source;
  logic [4:0]  deq_pfSource;

  // MBIST：mbistPl → pbop（toSRAM_0） / vbop（toSRAM_1）
  logic [8:0]  pbopBd_addr, pbopBd_addr_rd, vbopBd_addr, vbopBd_addr_rd;
  logic [12:0] pbopBd_wdata, pbopBd_rdata, vbopBd_wdata, vbopBd_rdata;
  logic        pbopBd_wmask, pbopBd_re, pbopBd_we, pbopBd_ack, pbopBd_selectedOH, pbopBd_array;
  logic        vbopBd_wmask, vbopBd_re, vbopBd_we, vbopBd_ack, vbopBd_selectedOH, vbopBd_array;

  xs_Prefetcher_core u_core (
    .clock              (clock),
    .reset              (reset),
    .pf_master_en       (pfCtrlFromCore_l2_pf_master_en),
    .pf_recv_en         (pfCtrlFromCore_l2_pf_recv_en),
    .pbop_en            (pfCtrlFromCore_l2_pbop_en),
    .vbop_en            (pfCtrlFromCore_l2_vbop_en),
    .pbop_enable        (pbop_enable),
    .vbop_enable        (vbop_enable),
    .rcv_enable         (rcv_enable),
    .train_valid        (io_train_valid),
    .train_reqsource    (io_train_bits_reqsource),
    .bop_train_valid    (bop_train_valid),
    .resp_valid         (io_resp_valid),
    .resp_pfSource      (io_resp_bits_pfSource),
    .pbop_resp_valid    (pbop_resp_valid),
    .vbop_resp_valid    (vbop_resp_valid),
    .rcv_req_valid      (rcv_req_valid),
    .vbop_req_valid     (vbop_req_valid),
    .vbop_req_ready     (vbop_req_ready),
    .pbop_req_ready     (pbop_req_ready),
    .recv_addr_valid    (io_recv_addr_valid),
    .recv_addr_addr     (io_recv_addr_bits_addr),
    .recv_addr_pfSource (io_recv_addr_bits_pfSource),
    .rcv_recv_valid     (rcv_recv_valid),
    .rcv_recv_addr      (rcv_recv_addr),
    .rcv_recv_pfSource  (rcv_recv_pfSource)
  );

  // ---------------------------------------------------------------------------
  // 物理地址 BOP
  // ---------------------------------------------------------------------------
  PBestOffsetPrefetch pbop (
    .clock                          (clock),
    .reset                          (reset),
    .io_enable                      (pbop_enable),
    .io_pfCtrlOfDelayLatency        (pfCtrlFromCore_l2_pf_delay_latency),
    .io_train_ready                 (io_train_ready),
    .io_train_valid                 (bop_train_valid),
    .io_train_bits_tag              (io_train_bits_tag),
    .io_train_bits_set              (io_train_bits_set),
    .io_train_bits_needT            (io_train_bits_needT),
    .io_train_bits_source           (io_train_bits_source),
    .io_req_ready                   (pbop_req_ready),
    .io_req_valid                   (pbop_req_valid),
    .io_req_bits_tag                (pbop_req_tag),
    .io_req_bits_set                (pbop_req_set),
    .io_req_bits_vaddr              (pbop_req_vaddr),
    .io_req_bits_needT              (pbop_req_needT),
    .io_req_bits_source             (pbop_req_source),
    .io_resp_ready                  (io_resp_ready),
    .io_resp_valid                  (pbop_resp_valid),
    .boreChildrenBd_bore_addr       (pbopBd_addr),
    .boreChildrenBd_bore_addr_rd    (pbopBd_addr_rd),
    .boreChildrenBd_bore_wdata      (pbopBd_wdata),
    .boreChildrenBd_bore_wmask      (pbopBd_wmask),
    .boreChildrenBd_bore_re         (pbopBd_re),
    .boreChildrenBd_bore_we         (pbopBd_we),
    .boreChildrenBd_bore_rdata      (pbopBd_rdata),
    .boreChildrenBd_bore_ack        (pbopBd_ack),
    .boreChildrenBd_bore_selectedOH (pbopBd_selectedOH),
    .boreChildrenBd_bore_array      (pbopBd_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_cgen)
  );

  // ---------------------------------------------------------------------------
  // 虚拟地址 BOP（自己发 TLB 请求，翻译后再出预取）
  // ---------------------------------------------------------------------------
  VBestOffsetPrefetch vbop (
    .clock                              (clock),
    .reset                              (reset),
    .io_enable                          (vbop_enable),
    .io_pfCtrlOfDelayLatency            (pfCtrlFromCore_l2_pf_delay_latency),
    .io_train_valid                     (bop_train_valid),
    .io_train_bits_needT                (io_train_bits_needT),
    .io_train_bits_source               (io_train_bits_source),
    .io_train_bits_vaddr                (io_train_bits_vaddr),
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
    .io_req_ready                       (vbop_req_ready),
    .io_req_valid                       (vbop_req_valid),
    .io_req_bits_tag                    (vbop_req_tag),
    .io_req_bits_set                    (vbop_req_set),
    .io_req_bits_vaddr                  (vbop_req_vaddr),
    .io_req_bits_needT                  (vbop_req_needT),
    .io_req_bits_source                 (vbop_req_source),
    .io_resp_valid                      (vbop_resp_valid),
    .boreChildrenBd_bore_addr           (vbopBd_addr),
    .boreChildrenBd_bore_addr_rd        (vbopBd_addr_rd),
    .boreChildrenBd_bore_wdata          (vbopBd_wdata),
    .boreChildrenBd_bore_wmask          (vbopBd_wmask),
    .boreChildrenBd_bore_re             (vbopBd_re),
    .boreChildrenBd_bore_we             (vbopBd_we),
    .boreChildrenBd_bore_rdata          (vbopBd_rdata),
    .boreChildrenBd_bore_ack            (vbopBd_ack),
    .boreChildrenBd_bore_selectedOH     (vbopBd_selectedOH),
    .boreChildrenBd_bore_array          (vbopBd_array),
    .sigFromSrams_bore_ram_hold         (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_ram_bypass       (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken     (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk      (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp     (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold     (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_cgen             (sigFromSrams_bore_1_cgen)
  );

  // ---------------------------------------------------------------------------
  // 接收核侧推来的预取（地址已延迟两拍）
  // ---------------------------------------------------------------------------
  PrefetchReceiver pfRcv (
    .io_req_valid               (rcv_req_valid),
    .io_req_bits_tag            (rcv_req_tag),
    .io_req_bits_set            (rcv_req_set),
    .io_req_bits_pfSource       (rcv_req_pfSource),
    .io_recv_addr_valid         (rcv_recv_valid),
    .io_recv_addr_bits_addr     (rcv_recv_addr),
    .io_recv_addr_bits_pfSource (rcv_recv_pfSource),
    .io_enable                  (rcv_enable)
  );

  // ---------------------------------------------------------------------------
  // MBIST 分发：外部 MBIST 口 → pbop / vbop 的 RRT SRAM
  // ---------------------------------------------------------------------------
  MbistPipeL2Prefetcher mbistPl (
    .clock               (clock),
    .reset               (reset),
    .mbist_array         (boreChildrenBd_bore_array),
    .mbist_all           (boreChildrenBd_bore_all),
    .mbist_req           (boreChildrenBd_bore_req),
    .mbist_ack           (boreChildrenBd_bore_ack),
    .mbist_writeen       (boreChildrenBd_bore_writeen),
    .mbist_be            (boreChildrenBd_bore_be),
    .mbist_addr          (boreChildrenBd_bore_addr),
    .mbist_indata        (boreChildrenBd_bore_indata),
    .mbist_readen        (boreChildrenBd_bore_readen),
    .mbist_addr_rd       (boreChildrenBd_bore_addr_rd),
    .mbist_outdata       (boreChildrenBd_bore_outdata),
    .toSRAM_0_addr       (pbopBd_addr),
    .toSRAM_0_addr_rd    (pbopBd_addr_rd),
    .toSRAM_0_wdata      (pbopBd_wdata),
    .toSRAM_0_wmask      (pbopBd_wmask),
    .toSRAM_0_re         (pbopBd_re),
    .toSRAM_0_we         (pbopBd_we),
    .toSRAM_0_rdata      (pbopBd_rdata),
    .toSRAM_0_ack        (pbopBd_ack),
    .toSRAM_0_selectedOH (pbopBd_selectedOH),
    .toSRAM_0_array      (pbopBd_array),
    .toSRAM_1_addr       (vbopBd_addr),
    .toSRAM_1_addr_rd    (vbopBd_addr_rd),
    .toSRAM_1_wdata      (vbopBd_wdata),
    .toSRAM_1_wmask      (vbopBd_wmask),
    .toSRAM_1_re         (vbopBd_re),
    .toSRAM_1_we         (vbopBd_we),
    .toSRAM_1_rdata      (vbopBd_rdata),
    .toSRAM_1_ack        (vbopBd_ack),
    .toSRAM_1_selectedOH (vbopBd_selectedOH),
    .toSRAM_1_array      (vbopBd_array)
  );

  // ---------------------------------------------------------------------------
  // 入队仲裁（Arbiter：in0=pfRcv > in1=vbop > in2=pbop；in3=TP 本配置不存在，golden 已消掉）
  // ---------------------------------------------------------------------------
  Arbiter4_PrefetchReq pftQueueEnqArb (
    .io_in_0_valid         (rcv_req_valid),
    .io_in_0_bits_tag      (rcv_req_tag),
    .io_in_0_bits_set      (rcv_req_set),
    .io_in_0_bits_pfSource (rcv_req_pfSource),
    .io_in_1_ready         (arb_vbop_ready),
    .io_in_1_valid         (vbop_req_valid),
    .io_in_1_bits_tag      (vbop_req_tag),
    .io_in_1_bits_set      (vbop_req_set),
    .io_in_1_bits_vaddr    (vbop_req_vaddr),
    .io_in_1_bits_needT    (vbop_req_needT),
    .io_in_1_bits_source   (vbop_req_source),
    .io_in_2_ready         (arb_pbop_ready),
    .io_in_2_valid         (pbop_req_valid),
    .io_in_2_bits_tag      (pbop_req_tag),
    .io_in_2_bits_set      (pbop_req_set),
    .io_in_2_bits_vaddr    (pbop_req_vaddr),
    .io_in_2_bits_needT    (pbop_req_needT),
    .io_in_2_bits_source   (pbop_req_source),
    .io_out_valid          (enq_valid),
    .io_out_bits_tag       (enq_tag),
    .io_out_bits_set       (enq_set),
    .io_out_bits_vaddr     (enq_vaddr),
    .io_out_bits_needT     (enq_needT),
    .io_out_bits_source    (enq_source),
    .io_out_bits_pfSource  (enq_pfSource)
  );

  // ---------------------------------------------------------------------------
  // 预取队列（满了覆盖最老项，所以入队方向没有 ready）
  // ---------------------------------------------------------------------------
  PrefetchQueue pftQueue (
    .clock                (clock),
    .reset                (reset),
    .io_enq_valid         (enq_valid),
    .io_enq_bits_tag      (enq_tag),
    .io_enq_bits_set      (enq_set),
    .io_enq_bits_vaddr    (enq_vaddr),
    .io_enq_bits_needT    (enq_needT),
    .io_enq_bits_source   (enq_source),
    .io_enq_bits_pfSource (enq_pfSource),
    .io_deq_ready         (deq_ready),
    .io_deq_valid         (deq_valid),
    .io_deq_bits_tag      (deq_tag),
    .io_deq_bits_set      (deq_set),
    .io_deq_bits_vaddr    (deq_vaddr),
    .io_deq_bits_needT    (deq_needT),
    .io_deq_bits_source   (deq_source),
    .io_deq_bits_pfSource (deq_pfSource)
  );

  // ---------------------------------------------------------------------------
  // 一级流水 → io_req（送 Slice 的 SinkA）
  // ---------------------------------------------------------------------------
  Pipeline_1 pipe (
    .clock                (clock),
    .reset                (reset),
    .io_in_ready          (deq_ready),
    .io_in_valid          (deq_valid),
    .io_in_bits_tag       (deq_tag),
    .io_in_bits_set       (deq_set),
    .io_in_bits_vaddr     (deq_vaddr),
    .io_in_bits_needT     (deq_needT),
    .io_in_bits_source    (deq_source),
    .io_in_bits_pfSource  (deq_pfSource),
    .io_out_ready         (io_req_ready),
    .io_out_valid         (io_req_valid),
    .io_out_bits_tag      (io_req_bits_tag),
    .io_out_bits_set      (io_req_bits_set),
    .io_out_bits_vaddr    (io_req_bits_vaddr),
    .io_out_bits_needT    (io_req_bits_needT),
    .io_out_bits_source   (io_req_bits_source),
    .io_out_bits_pfSource (io_req_bits_pfSource)
  );

endmodule
