// VBestOffsetPrefetch —— 手写可读实现(TL2 shard D, AUX signoff, 作用域部分)。
//
// 虚拟地址版 BestOffset 预取器顶层。装配四个子核:
//   scoreTable(xs_OffsetScoreTable_1_core) —— BestOffset 学习, 10 位 offset。
//   rrTable   (xs_RecentRequestTable_1_core) —— 最近请求表。
//   delayQueue(xs_DelayQueue_1_core)        —— 训练地址延迟队列。
//   reqFilter (PrefetchReqBuffer)           —— TLB 请求过滤缓冲(★本轮作用域外, 对称黑盒★)。
//
// 顶层逻辑(本核, 可读且受 FM 验证):
//   - s0_fire = scoreTable.ready & io_train_valid; scoreTable 每训练请求发一个 test req。
//   - s1 流水寄存器: s0_fire 锁存 needT/source/newFullAddr(=vaddr<<6 + offset<<6 符号扩展)/reqVaddr。
//     s1_valid 跟随(s0_fire | 保持未被 reqFilter 消费)。
//   - reqFilter 输入: io_in_req_valid = ~prefetchDisable & s1_req_valid(_probe), 载荷来自 s1。
//   - io_req_valid = io_enable & reqFilter.out.valid; io_tlb_req_valid = reqFilter.tlb.valid。
//   - s1_ready = io_req_ready | ~io_req_valid_int(下游 out 可走或本级空)。
//
// ★作用域: reqFilter(PrefetchReqBuffer, 1715 行 + 2 个 RRArbiterInit) 本轮未可读重写,
//   两侧对称黑盒(golden 同名, 不解析 → hdlin_unresolved_modules=black_box)。故 reqFilter
//   输出锥(io_out_req_*, io_tlb_req_*)为黑盒输出, FM 不验其内部; 本核证明覆盖 s0/s1 流水、
//   newFullAddr、三小子核(DelayQueue_1/OffsetScoreTable_1/RecentRequestTable_1)全逻辑及
//   reqFilter 输入侧连接。residual = PrefetchReqBuffer 独立子证明(见返回说明)。★
//
// 本文件定义可读核 xs_VBestOffsetPrefetch_core; golden 同名扁平端口包装在
// rtl/l2/VBestOffsetPrefetch_wrapper.sv(仅 FM impl 侧例化本核)。
module xs_VBestOffsetPrefetch_core(
  input         clock,
  input         reset,
  input         io_enable,
  input         io_train_valid,
  input         io_train_bits_needT,
  input  [6:0]  io_train_bits_source,
  input  [43:0] io_train_bits_vaddr,
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

  // ---- 子核互连线 ----
  wire        scoreTable_req_ready;
  wire [9:0]  scoreTable_prefetchOffset;
  wire        scoreTable_prefetchDisable;
  wire        scoreTable_test_req_valid;
  wire [49:0] scoreTable_test_req_bits_addr;
  wire [9:0]  scoreTable_test_req_bits_testOffset;
  wire [6:0]  scoreTable_test_req_bits_ptr;
  wire        rrTable_w_ready;
  wire        rrTable_r_resp_valid;
  wire [6:0]  rrTable_r_resp_bits_ptr;
  wire        rrTable_r_resp_bits_hit;
  wire        delayQueue_out_valid;
  wire [49:0] delayQueue_out_bits;
  wire        reqFilter_out_req_valid;
  wire        reqFilter_tlb_req_req_valid;

  // ---- s0 fire ----
  wire s0_fire = scoreTable_req_ready & io_train_valid;

  // ---- s1 流水寄存器 ----
  reg         s1_req_valid;
  reg         s1_needT;
  reg  [6:0]  s1_source;
  reg  [49:0] s1_newFullAddr;
  reg  [43:0] s1_reqVaddr;

  wire        io_req_valid_int = io_enable & reqFilter_out_req_valid;
  wire        s1_ready = io_req_ready | ~io_req_valid_int;

  always @(posedge clock or posedge reset) begin
    if (reset)
      s1_req_valid <= 1'h0;
    else
      s1_req_valid <= s0_fire | ~(s1_ready & s1_req_valid) & s1_req_valid;
  end

  always @(posedge clock) begin
    if (s0_fire) begin
      s1_needT  <= io_train_bits_needT;
      s1_source <= io_train_bits_source;
      s1_newFullAddr <=
        50'({io_train_bits_vaddr, 6'h0}
            + {{34{scoreTable_prefetchOffset[9]}}, scoreTable_prefetchOffset, 6'h0});
      s1_reqVaddr <= io_train_bits_vaddr;
    end
  end

  wire probe = ~scoreTable_prefetchDisable & s1_req_valid;

  // ---- 子核例化 ----
  xs_DelayQueue_1_core delayQueue (
    .clock        (clock),
    .reset        (reset),
    .io_in_valid  (io_train_valid),
    .io_in_bits   (io_train_bits_vaddr),
    .io_out_ready (rrTable_w_ready),
    .io_out_valid (delayQueue_out_valid),
    .io_out_bits  (delayQueue_out_bits)
  );

  xs_RecentRequestTable_1_core rrTable (
    .clock                          (clock),
    .reset                          (reset),
    .io_w_ready                     (rrTable_w_ready),
    .io_w_valid                     (delayQueue_out_valid),
    .io_w_bits                      (delayQueue_out_bits),
    .io_r_req_valid                 (scoreTable_test_req_valid),
    .io_r_req_bits_addr             (scoreTable_test_req_bits_addr),
    .io_r_req_bits_testOffset       (scoreTable_test_req_bits_testOffset),
    .io_r_req_bits_ptr              (scoreTable_test_req_bits_ptr),
    .io_r_resp_valid                (rrTable_r_resp_valid),
    .io_r_resp_bits_ptr             (rrTable_r_resp_bits_ptr),
    .io_r_resp_bits_hit             (rrTable_r_resp_bits_hit),
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

  xs_OffsetScoreTable_1_core scoreTable (
    .clock                       (clock),
    .reset                       (reset),
    .io_req_ready                (scoreTable_req_ready),
    .io_req_valid                (io_train_valid),
    .io_req_bits                 ({io_train_bits_vaddr, 6'h0}),
    .io_prefetchOffset           (scoreTable_prefetchOffset),
    .io_prefetchDisable          (scoreTable_prefetchDisable),
    .io_test_req_valid           (scoreTable_test_req_valid),
    .io_test_req_bits_addr       (scoreTable_test_req_bits_addr),
    .io_test_req_bits_testOffset (scoreTable_test_req_bits_testOffset),
    .io_test_req_bits_ptr        (scoreTable_test_req_bits_ptr),
    .io_test_resp_valid          (rrTable_r_resp_valid),
    .io_test_resp_bits_ptr       (rrTable_r_resp_bits_ptr),
    .io_test_resp_bits_hit       (rrTable_r_resp_bits_hit)
  );

  // reqFilter —— 本轮作用域外, 对称黑盒(golden 同名 PrefetchReqBuffer)。
  PrefetchReqBuffer reqFilter (
    .clock                              (clock),
    .reset                              (reset),
    .io_in_req_valid                    (probe),
    .io_in_req_bits_full_vaddr          (s1_newFullAddr),
    .io_in_req_bits_base_vaddr          (s1_reqVaddr),
    .io_in_req_bits_needT               (s1_needT),
    .io_in_req_bits_source              (s1_source),
    .io_tlb_req_req_valid               (reqFilter_tlb_req_req_valid),
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
    .io_out_req_ready                   (io_req_ready),
    .io_out_req_valid                   (reqFilter_out_req_valid),
    .io_out_req_bits_tag                (io_req_bits_tag),
    .io_out_req_bits_set                (io_req_bits_set),
    .io_out_req_bits_vaddr              (io_req_bits_vaddr),
    .io_out_req_bits_needT              (io_req_bits_needT),
    .io_out_req_bits_source             (io_req_bits_source)
  );

  assign io_tlb_req_req_valid = reqFilter_tlb_req_req_valid;
  assign io_req_valid         = io_req_valid_int;

endmodule
