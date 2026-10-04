// RecentRequestTable.sv —— L2 Best-Offset 预取器的"最近请求表"（RR 表），带 2 拍读流水
//
// 位置：coupledL2 BestOffsetPrefetch（coupledL2/prefetch/BestOffsetPrefetch.scala:151）。
//   BOP 的学习过程：每来一次访问 X，拿当前候选偏移 d 去查"X - d 这条行最近是否被访问过"；
//   命中就给 d 加分。RR 表就是那张"最近访问过的行"的记录：
//     写口 w：一条行地址（L2 refill / 预取完成）写进表；
//     读口 r：给 {addr, testOffset, ptr}，查 addr - (testOffset << 6) 这一行在不在表里，
//             两拍后回 {ptr, hit}（ptr 原样带回，ScoreTable 用它定位候选偏移）。
//   本模块两个变体：RecentRequestTable（PBestOffsetPrefetch，物理地址 48 位、偏移 7 位、ptr 6 位）
//   与 RecentRequestTable_1（VBestOffsetPrefetch，虚地址 50 位、偏移 10 位、ptr 7 位）。
//
// 表结构：直接映射 256 项，每项 {valid, 12 位 partial tag}，存在单口 SRAM（SRAMTemplate_146）里。
//   行地址 lineAddr = addr[.., 6]；
//     idx = lineAddr[7:0] ^ lineAddr[15:8]        （hash1 ^ hash2）
//     tag = lineAddr[19:8]                         （= addr[25:14]）
//   只用到地址的低 26 位，所以 48/50 位两个变体的数据通路完全一样，差别只在端口宽度。
//
// 单口 SRAM 的读写仲裁：读优先。io_r_req_valid 当拍压住写（w.ready = sram.w.ready & ~r.valid）。
//
// 读流水（Scala 原样）：
//   s0  r.req.fire（= r.req.valid，r.req.ready 恒 1）发 SRAM 读；同时把 tag(rAddr) 与 ptr 打一拍
//   s1  SRAM 数据回来：hit = 读出项 valid & tag 相等；s1_valid = 上一拍 SRAM 真的接了读请求
//   s2  resp.valid = s2_valid；resp.{ptr,hit} 是 s1_valid 时才更新的保持寄存器（RegEnable）
//   s1_valid / s2_valid 异步复位；其余流水寄存器不复位（golden 同）。
//
// ★断言寄存器照 golden 保留★：Scala `assert(!RegNext(io.w.fire && io.r.req.fire))` 产生一个
//   只被 `ifndef SYNTHESIS 断言读的寄存器（golden: REG）。综合视图里它没有读者，但 golden 有它，
//   这里同样保留（断言本身不写）。
// golden 228 行 / 29 端口；唯一子模块 SRAMTemplate_146（rrTable，已独立签核）。

module xs_RecentRequestTable_core #(
  parameter int unsigned ADDR_W   = 48,   // 地址位宽（P: 48 物理 / V: 50 虚拟）
  parameter int unsigned OFFSET_W = 7,    // testOffset 位宽（有符号，以 cacheline 为单位）
  parameter int unsigned PTR_W    = 6     // ptr 位宽（ScoreTable 候选偏移下标）
)(
  input  logic                clock,
  input  logic                reset,
  // 写口：记录一条最近访问的地址
  output logic                w_ready,
  input  logic                w_valid,
  input  logic [ADDR_W-1:0]   w_addr,
  // 读口：查 addr - testOffset 行
  input  logic                r_req_valid,
  input  logic [ADDR_W-1:0]   r_req_addr,
  input  logic [OFFSET_W-1:0] r_req_test_offset,
  input  logic [PTR_W-1:0]    r_req_ptr,
  output logic                r_resp_valid,
  output logic [PTR_W-1:0]    r_resp_ptr,
  output logic                r_resp_hit,
  // ---- DFT 透传（MBIST bore 口 + SRAM 控制广播），原样接到 rrTable ----
  input  logic [8:0]          bore_addr,
  input  logic [8:0]          bore_addr_rd,
  input  logic [12:0]         bore_wdata,
  input  logic                bore_wmask,
  input  logic                bore_re,
  input  logic                bore_we,
  output logic [12:0]         bore_rdata,
  input  logic                bore_ack,
  input  logic                bore_selectedOH,
  input  logic                bore_array,
  input  logic                sram_ram_hold,
  input  logic                sram_ram_bypass,
  input  logic                sram_ram_bp_clken,
  input  logic                sram_ram_aux_clk,
  input  logic                sram_ram_aux_ckbp,
  input  logic                sram_ram_mcp_hold,
  input  logic                sram_cgen
);

  localparam int unsigned OFFSET_BITS = 6;    // 64B cacheline
  localparam int unsigned IDX_W       = 8;    // rrTableEntries = 256
  localparam int unsigned TAG_W       = 12;   // rrTagBits

  // 行地址 → 表下标 / partial tag
  function automatic logic [IDX_W-1:0] rr_idx(input logic [ADDR_W-1:0] addr);
    logic [ADDR_W-OFFSET_BITS-1:0] line;
    line = addr[ADDR_W-1:OFFSET_BITS];
    return line[IDX_W-1:0] ^ line[2*IDX_W-1:IDX_W];          // hash1 ^ hash2
  endfunction
  function automatic logic [TAG_W-1:0] rr_tag(input logic [ADDR_W-1:0] addr);
    logic [ADDR_W-OFFSET_BITS-1:0] line;
    line = addr[ADDR_W-1:OFFSET_BITS];
    return line[TAG_W+IDX_W-1:IDX_W];
  endfunction

  // ---------------------------------------------------------------------------
  // s0：读地址 = addr - signExt(testOffset << 6)；单口 SRAM 读优先
  // ---------------------------------------------------------------------------
  logic [ADDR_W-1:0] r_addr;
  assign r_addr = r_req_addr - ADDR_W'($signed({r_req_test_offset, {OFFSET_BITS{1'b0}}}));

  logic             sram_r_ready, sram_w_ready;
  logic             sram_rdata_valid;
  logic [TAG_W-1:0] sram_rdata_tag;

  assign w_ready = sram_w_ready & ~r_req_valid;

  // ---------------------------------------------------------------------------
  // s1 / s2 流水
  // ---------------------------------------------------------------------------
  logic             s1_valid, s2_valid;      // 异步复位
  logic [PTR_W-1:0] s1_ptr;
  logic [TAG_W-1:0] s1_tag;                  // golden: s1_hit_REG（RegNext(tag(rAddr))）
  logic [PTR_W-1:0] resp_ptr_q;              // golden: io_r_resp_bits_ptr_r
  logic             resp_hit_q;              // golden: io_r_resp_bits_hit_r
  logic             rw_same_cycle_q;         // golden: REG，只给断言用

  logic s1_hit;
  assign s1_hit = sram_rdata_valid & (sram_rdata_tag == s1_tag);

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s1_valid <= 1'b0;
      s2_valid <= 1'b0;
    end else begin
      s1_valid <= sram_r_ready & r_req_valid;
      s2_valid <= s1_valid;
    end
  end

  always_ff @(posedge clock) begin
    rw_same_cycle_q <= w_ready & w_valid & r_req_valid;   // w.fire && r.req.fire
    s1_ptr          <= r_req_ptr;
    s1_tag          <= rr_tag(r_addr);
    if (s1_valid) begin
      resp_ptr_q <= s1_ptr;
      resp_hit_q <= s1_hit;
    end
  end

  assign r_resp_valid = s2_valid;
  assign r_resp_ptr   = resp_ptr_q;
  assign r_resp_hit   = resp_hit_q;

  // ---------------------------------------------------------------------------
  // rrTable：256 项 × {valid, tag}，单口 SRAM；写入的 valid 恒 1 已被 firtool 折进子模块
  // ---------------------------------------------------------------------------
  SRAMTemplate_146 rrTable (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_ready                 (sram_r_ready),
    .io_r_req_valid                 (r_req_valid),
    .io_r_req_bits_setIdx           (rr_idx(r_addr)),
    .io_r_resp_data_0_valid         (sram_rdata_valid),
    .io_r_resp_data_0_tag           (sram_rdata_tag),
    .io_w_req_ready                 (sram_w_ready),
    .io_w_req_valid                 (w_valid & ~r_req_valid),
    .io_w_req_bits_setIdx           (rr_idx(w_addr)),
    .io_w_req_bits_data_0_tag       (rr_tag(w_addr)),
    .io_broadcast_ram_hold          (sram_ram_hold),
    .io_broadcast_ram_bypass        (sram_ram_bypass),
    .io_broadcast_ram_bp_clken      (sram_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sram_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sram_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sram_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sram_cgen),
    .boreChildrenBd_bore_addr       (bore_addr),
    .boreChildrenBd_bore_addr_rd    (bore_addr_rd),
    .boreChildrenBd_bore_wdata      (bore_wdata),
    .boreChildrenBd_bore_wmask      (bore_wmask),
    .boreChildrenBd_bore_re         (bore_re),
    .boreChildrenBd_bore_we         (bore_we),
    .boreChildrenBd_bore_rdata      (bore_rdata),
    .boreChildrenBd_bore_ack        (bore_ack),
    .boreChildrenBd_bore_selectedOH (bore_selectedOH),
    .boreChildrenBd_bore_array      (bore_array)
  );

endmodule

module RecentRequestTable (
  input  logic        clock,
  input  logic        reset,
  output logic        io_w_ready,
  input  logic        io_w_valid,
  input  logic [47:0] io_w_bits,
  input  logic        io_r_req_valid,
  input  logic [47:0] io_r_req_bits_addr,
  input  logic [6:0]  io_r_req_bits_testOffset,
  input  logic [5:0]  io_r_req_bits_ptr,
  output logic        io_r_resp_valid,
  output logic [5:0]  io_r_resp_bits_ptr,
  output logic        io_r_resp_bits_hit,
  input  logic [8:0]  boreChildrenBd_bore_addr,
  input  logic [8:0]  boreChildrenBd_bore_addr_rd,
  input  logic [12:0] boreChildrenBd_bore_wdata,
  input  logic        boreChildrenBd_bore_wmask,
  input  logic        boreChildrenBd_bore_re,
  input  logic        boreChildrenBd_bore_we,
  output logic [12:0] boreChildrenBd_bore_rdata,
  input  logic        boreChildrenBd_bore_ack,
  input  logic        boreChildrenBd_bore_selectedOH,
  input  logic        boreChildrenBd_bore_array,
  input  logic        sigFromSrams_bore_ram_hold,
  input  logic        sigFromSrams_bore_ram_bypass,
  input  logic        sigFromSrams_bore_ram_bp_clken,
  input  logic        sigFromSrams_bore_ram_aux_clk,
  input  logic        sigFromSrams_bore_ram_aux_ckbp,
  input  logic        sigFromSrams_bore_ram_mcp_hold,
  input  logic        sigFromSrams_bore_cgen
);

  xs_RecentRequestTable_core #(.ADDR_W(48), .OFFSET_W(7), .PTR_W(6)) u_core (
    .clock             (clock),
    .reset             (reset),
    .w_ready           (io_w_ready),
    .w_valid           (io_w_valid),
    .w_addr            (io_w_bits),
    .r_req_valid       (io_r_req_valid),
    .r_req_addr        (io_r_req_bits_addr),
    .r_req_test_offset (io_r_req_bits_testOffset),
    .r_req_ptr         (io_r_req_bits_ptr),
    .r_resp_valid      (io_r_resp_valid),
    .r_resp_ptr        (io_r_resp_bits_ptr),
    .r_resp_hit        (io_r_resp_bits_hit),
    .bore_addr         (boreChildrenBd_bore_addr),
    .bore_addr_rd      (boreChildrenBd_bore_addr_rd),
    .bore_wdata        (boreChildrenBd_bore_wdata),
    .bore_wmask        (boreChildrenBd_bore_wmask),
    .bore_re           (boreChildrenBd_bore_re),
    .bore_we           (boreChildrenBd_bore_we),
    .bore_rdata        (boreChildrenBd_bore_rdata),
    .bore_ack          (boreChildrenBd_bore_ack),
    .bore_selectedOH   (boreChildrenBd_bore_selectedOH),
    .bore_array        (boreChildrenBd_bore_array),
    .sram_ram_hold     (sigFromSrams_bore_ram_hold),
    .sram_ram_bypass   (sigFromSrams_bore_ram_bypass),
    .sram_ram_bp_clken (sigFromSrams_bore_ram_bp_clken),
    .sram_ram_aux_clk  (sigFromSrams_bore_ram_aux_clk),
    .sram_ram_aux_ckbp (sigFromSrams_bore_ram_aux_ckbp),
    .sram_ram_mcp_hold (sigFromSrams_bore_ram_mcp_hold),
    .sram_cgen         (sigFromSrams_bore_cgen)
  );

endmodule
