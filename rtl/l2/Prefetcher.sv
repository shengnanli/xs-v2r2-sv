// Prefetcher —— 手写可读实现(TL2 shard 3, AUX assembly signoff)。
//
// L2 预取器顶层装配 + glue。例化 6 个子模块并做优先级仲裁/地址分级流水:
//   pbop     = PBestOffsetPrefetch   (物理地址 BestOffset 预取器, 绿 AUX child)
//   vbop     = VBestOffsetPrefetch   (虚拟地址 BestOffset 预取器, 绿 AUX child)
//   pfRcv    = PrefetchReceiver      (外部预取地址接收器, 绿 AUX child)
//   mbistPl  = MbistPipeL2Prefetcher (MBIST 分发级, 绿 AUX child)
//   pftQueue = PrefetchQueue         (预取请求去重队列, 两侧 elaborate 逻辑 child)
//   pipe     = Pipeline_1            (深度1 skid buffer, 绿 AUX child)
//
// ★ 本文件是"可读核" xs_Prefetcher_core: 顶层 glue 用可读命名重写, 子模块按
//   golden 名例化。FM impl 侧 5 绿 child(pbop/vbop/pfRcv/mbistPl/pipe)两侧
//   unresolved → 对称黑盒(assembly depends_on); pftQueue 两侧 elaborate golden RTL。
//
// glue 逻辑(Prefetcher.scala 意图):
//  (1) pfRcv enable 二级流水: en_REG <= master_en&recv_en; en <= en_REG。
//  (2) recv_addr 二级延迟流水: valid/addr/pfSource 打两拍后喂 pfRcv。
//        v_last_REG <= io_recv_addr_valid; v_last_REG_1 <= v_last_REG;
//        addr/pfSource d <= 输入(recv_valid 门控); d_1 <= d(v_last_REG 门控)。
//  (3) pftQueue 入队优先级仲裁: pfRcv > vbop > pbop。
//        enq_valid = pfRcv_valid | vbop_valid | pbop_valid;
//        各字段按优先级选中源的对应字段(pfRcv 无 vaddr/source/needT 用默认)。
//  (4) 子模块 ready 反压:
//        pbop.req_ready = ~pfRcv_valid & ~vbop_valid;
//        vbop.req_ready = ~pfRcv_valid;
//        (pfRcv 无 req_ready, 恒接受)。
//  (5) train 门控: pbop/vbop 训练输入 = io_train_valid & (reqsource != 5'h6)。
//        pbop 额外走 io_train_ready(唯一驱动 train_ready 的子模块)。
//  (6) resp 路由: pfSource==0x9→pbop, 0x8→vbop; io_resp_ready 由 pbop 驱动。
//  (7) MBIST bore 直连 mbistPl(childBd_* 连 pbop/vbop 的 boreChildrenBd)。
module xs_Prefetcher_core(
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

  // ---- 子模块间连线 ----
  wire        pipe_in_ready;
  wire        q_deq_valid;
  wire [32:0] q_deq_tag;
  wire [8:0]  q_deq_set;
  wire [43:0] q_deq_vaddr;
  wire        q_deq_needT;
  wire [6:0]  q_deq_source;
  wire [4:0]  q_deq_pfSource;
  wire        pfRcv_valid;
  wire [32:0] pfRcv_tag;
  wire [8:0]  pfRcv_set;
  wire [4:0]  pfRcv_pfSource;
  wire        vbop_valid;
  wire [32:0] vbop_tag;
  wire [8:0]  vbop_set;
  wire [43:0] vbop_vaddr;
  wire        vbop_needT;
  wire [6:0]  vbop_source;
  wire        pbop_valid;
  wire [32:0] pbop_tag;
  wire [8:0]  pbop_set;
  wire [43:0] pbop_vaddr;
  wire        pbop_needT;
  wire [6:0]  pbop_source;

  // ---- MBIST bore 直连(顶层端口 -> mbistPl) ----
  wire [12:0] bd_outdata;
  wire        bd_ack;
  wire        bd_array    = boreChildrenBd_bore_array;
  wire        bd_all      = boreChildrenBd_bore_all;
  wire        bd_req      = boreChildrenBd_bore_req;
  wire        bd_writeen  = boreChildrenBd_bore_writeen;
  wire        bd_be       = boreChildrenBd_bore_be;
  wire [8:0]  bd_addr     = boreChildrenBd_bore_addr;
  wire [12:0] bd_indata   = boreChildrenBd_bore_indata;
  wire        bd_readen   = boreChildrenBd_bore_readen;
  wire [8:0]  bd_addr_rd  = boreChildrenBd_bore_addr_rd;

  // ---- (1) pfRcv enable 二级流水 ----
  reg  pfRcv_en_REG;
  reg  pfRcv_en;
  // ---- (2) recv_addr 二级延迟流水 ----
  reg         recv_v_last_REG;
  reg  [63:0] recv_d_addr;
  reg  [4:0]  recv_d_pfSource;
  reg         recv_v_last_REG_1;
  reg  [63:0] recv_d_1_addr;
  reg  [4:0]  recv_d_1_pfSource;

  // train 门控: reqsource != 6(避免自训练回环)
  wire train_valid_gated = io_train_bits_reqsource != 5'h6;

  // childBd_* / childBd_1_* 由 mbistPl 分发, pbop/vbop 消费(前置声明避免前向引用)。
  wire [8:0]  childBd_addr;
  wire [8:0]  childBd_addr_rd;
  wire [12:0] childBd_wdata;
  wire        childBd_wmask;
  wire        childBd_re;
  wire        childBd_we;
  wire [12:0] childBd_rdata;
  wire        childBd_ack;
  wire        childBd_selectedOH;
  wire        childBd_array;
  wire [8:0]  childBd_1_addr;
  wire [8:0]  childBd_1_addr_rd;
  wire [12:0] childBd_1_wdata;
  wire        childBd_1_wmask;
  wire        childBd_1_re;
  wire        childBd_1_we;
  wire [12:0] childBd_1_rdata;
  wire        childBd_1_ack;
  wire        childBd_1_selectedOH;
  wire        childBd_1_array;

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      pfRcv_en_REG      <= 1'h1;
      pfRcv_en          <= 1'h1;
      recv_v_last_REG   <= 1'h0;
      recv_v_last_REG_1 <= 1'h0;
    end
    else begin
      pfRcv_en_REG      <= pfCtrlFromCore_l2_pf_master_en & pfCtrlFromCore_l2_pf_recv_en;
      pfRcv_en          <= pfRcv_en_REG;
      recv_v_last_REG   <= io_recv_addr_valid;
      recv_v_last_REG_1 <= recv_v_last_REG;
    end
  end
  always @(posedge clock) begin
    if (io_recv_addr_valid) begin
      recv_d_addr     <= io_recv_addr_bits_addr;
      recv_d_pfSource <= io_recv_addr_bits_pfSource;
    end
    if (recv_v_last_REG) begin
      recv_d_1_addr     <= recv_d_addr;
      recv_d_1_pfSource <= recv_d_pfSource;
    end
  end

  // ---- (3) pftQueue 入队优先级仲裁: pfRcv > vbop > pbop ----
  // enq_bits_T: pfRcv 或 vbop 有效(选高优先两源之一), 否则用 pbop。
  wire enq_valid    = pfRcv_valid | vbop_valid | pbop_valid;
  wire enq_bits_hi  = pfRcv_valid | vbop_valid;  // 高优先两源
  wire [32:0] enq_tag =
      enq_bits_hi ? (pfRcv_valid ? pfRcv_tag : vbop_tag)
                  : (pbop_valid  ? pbop_tag  : 33'h0);
  wire [8:0]  enq_set =
      enq_bits_hi ? (pfRcv_valid ? pfRcv_set : vbop_set)
                  : (pbop_valid  ? pbop_set  : 9'h0);
  wire [43:0] enq_vaddr =
      enq_bits_hi ? (pfRcv_valid ? 44'h0 : vbop_vaddr)
                  : (pbop_valid  ? pbop_vaddr : 44'h0);
  wire        enq_needT =
      enq_bits_hi ? (~pfRcv_valid & vbop_needT)
                  : (pbop_valid  & pbop_needT);
  wire [6:0]  enq_source =
      enq_bits_hi ? (pfRcv_valid ? 7'h0 : vbop_source)
                  : (pbop_valid  ? pbop_source : 7'h0);
  wire [4:0]  enq_pfSource =
      enq_bits_hi ? (pfRcv_valid ? pfRcv_pfSource : 5'h8)
                  : (pbop_valid  ? 5'h9 : 5'h0);

  // ---- 子模块例化 ----
  PBestOffsetPrefetch pbop (
    .clock                          (clock),
    .reset                          (reset),
    .io_enable                      (pfCtrlFromCore_l2_pf_master_en & pfCtrlFromCore_l2_pbop_en),
    .io_train_ready                 (io_train_ready),
    .io_train_valid                 (io_train_valid & train_valid_gated),
    .io_train_bits_tag              (io_train_bits_tag),
    .io_train_bits_set              (io_train_bits_set),
    .io_train_bits_needT            (io_train_bits_needT),
    .io_train_bits_source           (io_train_bits_source),
    .io_req_ready                   (~pfRcv_valid & ~vbop_valid),
    .io_req_valid                   (pbop_valid),
    .io_req_bits_tag                (pbop_tag),
    .io_req_bits_set                (pbop_set),
    .io_req_bits_vaddr              (pbop_vaddr),
    .io_req_bits_needT              (pbop_needT),
    .io_req_bits_source             (pbop_source),
    .io_resp_ready                  (io_resp_ready),
    .io_resp_valid                  (io_resp_valid & io_resp_bits_pfSource == 5'h9),
    .boreChildrenBd_bore_addr       (childBd_addr),
    .boreChildrenBd_bore_addr_rd    (childBd_addr_rd),
    .boreChildrenBd_bore_wdata      (childBd_wdata),
    .boreChildrenBd_bore_wmask      (childBd_wmask),
    .boreChildrenBd_bore_re         (childBd_re),
    .boreChildrenBd_bore_we         (childBd_we),
    .boreChildrenBd_bore_rdata      (childBd_rdata),
    .boreChildrenBd_bore_ack        (childBd_ack),
    .boreChildrenBd_bore_selectedOH (childBd_selectedOH),
    .boreChildrenBd_bore_array      (childBd_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_cgen)
  );

  VBestOffsetPrefetch vbop (
    .clock                              (clock),
    .reset                              (reset),
    .io_enable                          (pfCtrlFromCore_l2_pf_master_en & pfCtrlFromCore_l2_vbop_en),
    .io_train_valid                     (io_train_valid & train_valid_gated),
    .io_train_bits_needT                (io_train_bits_needT),
    .io_train_bits_source               (io_train_bits_source),
    .io_train_bits_vaddr                (io_train_bits_vaddr),
    .io_tlb_req_req_valid               (io_tlb_req_req_valid),
    .io_tlb_req_req_bits_vaddr          (io_tlb_req_req_bits_vaddr),
    .io_tlb_req_req_bits_cmd            (io_tlb_req_req_bits_cmd),
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
    .io_req_ready                       (~pfRcv_valid),
    .io_req_valid                       (vbop_valid),
    .io_req_bits_tag                    (vbop_tag),
    .io_req_bits_set                    (vbop_set),
    .io_req_bits_vaddr                  (vbop_vaddr),
    .io_req_bits_needT                  (vbop_needT),
    .io_req_bits_source                 (vbop_source),
    .io_resp_valid                      (io_resp_valid & io_resp_bits_pfSource == 5'h8),
    .boreChildrenBd_bore_addr           (childBd_1_addr),
    .boreChildrenBd_bore_addr_rd        (childBd_1_addr_rd),
    .boreChildrenBd_bore_wdata          (childBd_1_wdata),
    .boreChildrenBd_bore_wmask          (childBd_1_wmask),
    .boreChildrenBd_bore_re             (childBd_1_re),
    .boreChildrenBd_bore_we             (childBd_1_we),
    .boreChildrenBd_bore_rdata          (childBd_1_rdata),
    .boreChildrenBd_bore_ack            (childBd_1_ack),
    .boreChildrenBd_bore_selectedOH     (childBd_1_selectedOH),
    .boreChildrenBd_bore_array          (childBd_1_array),
    .sigFromSrams_bore_ram_hold         (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_ram_bypass       (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken     (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk      (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp     (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold     (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_cgen             (sigFromSrams_bore_1_cgen)
  );

  PrefetchReceiver pfRcv (
    .io_req_valid               (pfRcv_valid),
    .io_req_bits_tag            (pfRcv_tag),
    .io_req_bits_set            (pfRcv_set),
    .io_req_bits_pfSource       (pfRcv_pfSource),
    .io_recv_addr_valid         (recv_v_last_REG_1),
    .io_recv_addr_bits_addr     (recv_d_1_addr),
    .io_recv_addr_bits_pfSource (recv_d_1_pfSource),
    .io_enable                  (pfRcv_en)
  );

  MbistPipeL2Prefetcher mbistPl (
    .clock               (clock),
    .reset               (reset),
    .mbist_array         (bd_array),
    .mbist_all           (bd_all),
    .mbist_req           (bd_req),
    .mbist_ack           (bd_ack),
    .mbist_writeen       (bd_writeen),
    .mbist_be            (bd_be),
    .mbist_addr          (bd_addr),
    .mbist_indata        (bd_indata),
    .mbist_readen        (bd_readen),
    .mbist_addr_rd       (bd_addr_rd),
    .mbist_outdata       (bd_outdata),
    .toSRAM_0_addr       (childBd_addr),
    .toSRAM_0_addr_rd    (childBd_addr_rd),
    .toSRAM_0_wdata      (childBd_wdata),
    .toSRAM_0_wmask      (childBd_wmask),
    .toSRAM_0_re         (childBd_re),
    .toSRAM_0_we         (childBd_we),
    .toSRAM_0_rdata      (childBd_rdata),
    .toSRAM_0_ack        (childBd_ack),
    .toSRAM_0_selectedOH (childBd_selectedOH),
    .toSRAM_0_array      (childBd_array),
    .toSRAM_1_addr       (childBd_1_addr),
    .toSRAM_1_addr_rd    (childBd_1_addr_rd),
    .toSRAM_1_wdata      (childBd_1_wdata),
    .toSRAM_1_wmask      (childBd_1_wmask),
    .toSRAM_1_re         (childBd_1_re),
    .toSRAM_1_we         (childBd_1_we),
    .toSRAM_1_rdata      (childBd_1_rdata),
    .toSRAM_1_ack        (childBd_1_ack),
    .toSRAM_1_selectedOH (childBd_1_selectedOH),
    .toSRAM_1_array      (childBd_1_array)
  );

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
    .io_deq_ready         (pipe_in_ready),
    .io_deq_valid         (q_deq_valid),
    .io_deq_bits_tag      (q_deq_tag),
    .io_deq_bits_set      (q_deq_set),
    .io_deq_bits_vaddr    (q_deq_vaddr),
    .io_deq_bits_needT    (q_deq_needT),
    .io_deq_bits_source   (q_deq_source),
    .io_deq_bits_pfSource (q_deq_pfSource)
  );

  Pipeline_1 pipe (
    .clock                (clock),
    .reset                (reset),
    .io_in_ready          (pipe_in_ready),
    .io_in_valid          (q_deq_valid),
    .io_in_bits_tag       (q_deq_tag),
    .io_in_bits_set       (q_deq_set),
    .io_in_bits_vaddr     (q_deq_vaddr),
    .io_in_bits_needT     (q_deq_needT),
    .io_in_bits_source    (q_deq_source),
    .io_in_bits_pfSource  (q_deq_pfSource),
    .io_out_ready         (io_req_ready),
    .io_out_valid         (io_req_valid),
    .io_out_bits_tag      (io_req_bits_tag),
    .io_out_bits_set      (io_req_bits_set),
    .io_out_bits_vaddr    (io_req_bits_vaddr),
    .io_out_bits_needT    (io_req_bits_needT),
    .io_out_bits_source   (io_req_bits_source),
    .io_out_bits_pfSource (io_req_bits_pfSource)
  );

  assign boreChildrenBd_bore_ack     = bd_ack;
  assign boreChildrenBd_bore_outdata = bd_outdata;

endmodule
