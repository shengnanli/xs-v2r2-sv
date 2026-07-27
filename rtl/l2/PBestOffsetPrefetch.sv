// PBestOffsetPrefetch —— 手写可读实现(TL2 shard D, AUX signoff)。
//
// 物理地址版 BestOffset 预取器顶层。装配三个可读子核(在 PBestOffset_children.sv):
//   scoreTable(xs_OffsetScoreTable_core) —— BestOffset 学习, 产出 prefetchOffset/Disable。
//   rrTable   (xs_RecentRequestTable_core) —— 最近请求表, 供 scoreTable 测试候选 offset。
//   delayQueue(xs_DelayQueue_core)        —— 训练地址延迟 300 拍后写入 rrTable。
//
// 顶层逻辑(本核):
//   - newAddr = 训练地址(tag,set,块内 0) + (prefetchOffset 符号扩展 << 6)。
//   - crossPage: 预取目标是否跨 4KB 页(newAddr[47:12] != {tag,set[8:6]}), 跨页则不发。
//   - req 寄存器流水: scoreTable 吃到训练请求那拍(_s0_fire = scoreTable.ready & train.valid)
//     锁存 newAddr 的 {tag,set} 及 needT/source; req_valid = ~crossPage & ~prefetchDisable。
//   - io_req_valid = io_enable & req_valid(enable 门控); 出握手后清 req_valid。
//   - io_train_ready = scoreTable.ready & (~req_valid | io_req_ready)(req 槽空或将出才收训练)。
//
// 唯一黑盒 = rrTable 内厂商 SRAM 宏(见 children 文件)。0 dont_verify/stub。
//
// 本文件定义可读核 xs_PBestOffsetPrefetch_core; golden 同名扁平端口包装在
// rtl/l2/PBestOffsetPrefetch_wrapper.sv(仅 FM impl 侧例化本核)。
module xs_PBestOffsetPrefetch_core(
  input         clock,
  input         reset,
  input         io_enable,
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

  // ---- 子核互连线 ----
  wire        scoreTable_req_ready;
  wire [6:0]  scoreTable_prefetchOffset;
  wire        scoreTable_prefetchDisable;
  wire        scoreTable_test_req_valid;
  wire [47:0] scoreTable_test_req_bits_addr;
  wire [6:0]  scoreTable_test_req_bits_testOffset;
  wire [5:0]  scoreTable_test_req_bits_ptr;
  wire        rrTable_w_ready;
  wire        rrTable_r_resp_valid;
  wire [5:0]  rrTable_r_resp_bits_ptr;
  wire        rrTable_r_resp_bits_hit;
  wire        delayQueue_out_valid;
  wire [47:0] delayQueue_out_bits;

  // ---- 预取目标地址 = 训练地址 + (offset << 6), offset 符号扩展 ----
  wire [47:0] newAddr =
    48'({io_train_bits_tag, io_train_bits_set, 6'h0}
        + {{35{scoreTable_prefetchOffset[6]}}, scoreTable_prefetchOffset, 6'h0});

  wire crossPage = newAddr[47:12] != {io_train_bits_tag, io_train_bits_set[8:6]};

  // ---- req 寄存器流水 ----
  reg  [32:0] req_tag;
  reg  [8:0]  req_set;
  reg         req_needT;
  reg  [6:0]  req_source;
  reg         req_valid;

  wire s0_fire     = scoreTable_req_ready & io_train_valid; // scoreTable 吃训练请求那拍
  wire reqHandshake = io_req_ready & (io_enable & req_valid);

  always @(posedge clock) begin
    if (s0_fire) begin
      req_tag    <= newAddr[47:15];
      req_set    <= newAddr[14:6];
      req_needT  <= io_train_bits_needT;
      req_source <= io_train_bits_source;
    end
  end

  always @(posedge clock or posedge reset) begin
    if (reset)
      req_valid <= 1'h0;
    else if (s0_fire)
      req_valid <= ~crossPage & ~scoreTable_prefetchDisable;
    else
      req_valid <= ~reqHandshake & req_valid;
  end

  wire io_req_valid_int   = io_enable & req_valid;
  wire io_train_ready_int = scoreTable_req_ready & (~req_valid | io_req_ready);

  // ---- 子核例化 ----
  xs_DelayQueue_core delayQueue (
    .clock        (clock),
    .reset        (reset),
    .io_in_valid  (io_train_valid),
    .io_in_bits   ({io_train_bits_tag, io_train_bits_set}),
    .io_out_ready (rrTable_w_ready),
    .io_out_valid (delayQueue_out_valid),
    .io_out_bits  (delayQueue_out_bits)
  );

  xs_RecentRequestTable_core rrTable (
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

  xs_OffsetScoreTable_core scoreTable (
    .clock                       (clock),
    .reset                       (reset),
    .io_req_ready                (scoreTable_req_ready),
    .io_req_valid                (io_train_valid),
    .io_req_bits                 ({io_train_bits_tag, io_train_bits_set, 6'h0}),
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

  assign io_train_ready     = io_train_ready_int;
  assign io_req_valid       = io_req_valid_int;
  assign io_req_bits_tag     = req_tag;
  assign io_req_bits_set     = req_set;
  assign io_req_bits_vaddr   = 44'h0;
  assign io_req_bits_needT   = req_needT;
  assign io_req_bits_source  = req_source;
  assign io_resp_ready      = rrTable_w_ready;

endmodule
