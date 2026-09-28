// =============================================================================
// TagSRAMBank —— DCache tag 阵列的一个"路组"存储体（2 路 × 256 组 × 43 位 {ecc, tag}）
//
// 对应 Chisel：xiangshan.cache.TagSRAMBank（src/main/scala/xiangshan/cache/dcache/meta/TagArray.scala）
//
// 【位置】TagArray 把 4 路 tag 拆成 2 个本件（DCacheWayDiv = 2，路 0-1 / 路 2-3），
//   DuplicatedTagArray 再把 TagArray 复制 4 份给 4 个读口。
// 【存储】单口 SRAM（SRAMTemplate_116 → 厂商宏 sram_array_1p256x86m43s1h0l1b_dcsh_tag），
//   一个地址 2 路 × 43 位，写按路掩码。单口 ⇒ 读写互斥，**写优先**：本拍有写就不接读
//   （io_read_ready = ~wen）。
// 【上电清零】rst_cnt 从 0 数到 256：前 256 拍把每一组两路都写成 0（coh 在 meta 阵列里，
//   tag 清 0 只是为了 ECC 一致），这期间外部写被挡住、读也不接。计满后 rst_cnt[8] 恒 1。
// 【MBIST / SRAM 控制】boreChildrenBd_* / sigFromSrams_* 是 MBIST 与 SRAM 电源/时钟控制的
//   穿线端口，本件只透传给 SRAMTemplate（io_broadcast_ram_ctl 在本配置下接常量 0）。
// =============================================================================

module TagSRAMBank(
  input         clock,
  input         reset,
  output        io_read_ready,
  input         io_read_valid,
  input  [7:0]  io_read_bits_idx,
  output [42:0] io_resp_0,
  output [42:0] io_resp_1,
  input         io_write_valid,
  input  [7:0]  io_write_bits_idx,
  input  [35:0] io_write_bits_tag,
  input  [6:0]  io_write_bits_ecc,
  input  [1:0]  io_write_bits_way_en,
  input  [8:0]  boreChildrenBd_bore_addr,
  input  [8:0]  boreChildrenBd_bore_addr_rd,
  input  [85:0] boreChildrenBd_bore_wdata,
  input  [1:0]  boreChildrenBd_bore_wmask,
  input         boreChildrenBd_bore_re,
  input         boreChildrenBd_bore_we,
  output [85:0] boreChildrenBd_bore_rdata,
  input         boreChildrenBd_bore_ack,
  input         boreChildrenBd_bore_selectedOH,
  input  [5:0]  boreChildrenBd_bore_array,
  input         sigFromSrams_bore_ram_hold,
  input         sigFromSrams_bore_ram_bypass,
  input         sigFromSrams_bore_ram_bp_clken,
  input         sigFromSrams_bore_ram_aux_clk,
  input         sigFromSrams_bore_ram_aux_ckbp,
  input         sigFromSrams_bore_ram_mcp_hold,
  input         sigFromSrams_bore_cgen
);

  localparam int N_SETS = 256;

  // ---- 上电清零计数器：0..256，最高位置 1 即清零完成 ----
  logic [8:0] rst_cnt;
  wire        in_reset_sweep = ~rst_cnt[8];    // = rst_cnt < N_SETS
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      rst_cnt <= 9'h0;
    else if (in_reset_sweep)
      rst_cnt <= rst_cnt + 9'h1;
  end

  // ---- 写口：清零期间写 0 到两路，之后是外部写 ----
  wire        wen     = in_reset_sweep | io_write_valid;
  wire [7:0]  waddr   = in_reset_sweep ? rst_cnt[7:0] : io_write_bits_idx;
  wire [42:0] wdata   = in_reset_sweep ? 43'h0 : {io_write_bits_ecc, io_write_bits_tag};
  wire [1:0]  wmask   = in_reset_sweep ? 2'b11 : io_write_bits_way_en;

  // ---- 读口：单口 SRAM，写优先 ----
  assign io_read_ready = ~wen;
  wire ren = io_read_valid & ~wen;

  SRAMTemplate_116 tag_array (
    .clock                          (clock),
    .reset                          (reset),
    .io_r_req_valid                 (ren),
    .io_r_req_bits_setIdx           (io_read_bits_idx),
    .io_r_resp_data_0               (io_resp_0),
    .io_r_resp_data_1               (io_resp_1),
    .io_w_req_valid                 (wen),
    .io_w_req_bits_setIdx           (waddr),
    .io_w_req_bits_data_0           (wdata),
    .io_w_req_bits_data_1           (wdata),
    .io_w_req_bits_waymask          (wmask),
    .io_broadcast_ram_hold          (sigFromSrams_bore_ram_hold),
    .io_broadcast_ram_bypass        (sigFromSrams_bore_ram_bypass),
    .io_broadcast_ram_bp_clken      (sigFromSrams_bore_ram_bp_clken),
    .io_broadcast_ram_aux_clk       (sigFromSrams_bore_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp      (sigFromSrams_bore_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold      (sigFromSrams_bore_ram_mcp_hold),
    .io_broadcast_ram_ctl           (64'h0),
    .io_broadcast_cgen              (sigFromSrams_bore_cgen),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_array)
  );

endmodule
