// =============================================================================
// TagArray —— DCache 一份完整的 4 路 tag 阵列（2 个 TagSRAMBank 拼成）
//
// 对应 Chisel：xiangshan.cache.TagArray（src/main/scala/xiangshan/cache/dcache/meta/TagArray.scala）
//
// 【结构】4 路按 DCacheWayDiv = 2 拆成 2 个存储体：tag_arrays_0 存路 0-1，tag_arrays_1 存路 2-3。
//   读：两个存储体用同一个 set 下标同时读，4 路结果按路号拼回 io_resp_0..3。
//   写：写请求广播给两个存储体，路使能 way_en[1:0] / [3:2] 各取一半。
// 【ready】Chisel 用 `<>` 把两个存储体的 read.ready 依次接到 io.read.ready，后接的覆盖前者，
//   所以 io_read_ready 取的是 tag_arrays_1 的（两者其实同值：同一时刻写、同一上电清零进度）。
//   tag_arrays_0 的 ready 悬空，照 golden。
// 【穿线端口】boreChildrenBd_bore*（MBIST）/ sigFromSrams_bore*（SRAM 控制）各两套，
//   无后缀那套给 tag_arrays_0，_1 那套给 tag_arrays_1，本件只透传。
// =============================================================================

module TagArray(
  input         clock,
  input         reset,
  output        io_read_ready,
  input         io_read_valid,
  input  [7:0]  io_read_bits_idx,
  output [42:0] io_resp_0,
  output [42:0] io_resp_1,
  output [42:0] io_resp_2,
  output [42:0] io_resp_3,
  input         io_write_valid,
  input  [7:0]  io_write_bits_idx,
  input  [3:0]  io_write_bits_way_en,
  input  [35:0] io_write_bits_tag,
  input  [6:0]  io_write_bits_ecc,
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
  input  [8:0]  boreChildrenBd_bore_1_addr,
  input  [8:0]  boreChildrenBd_bore_1_addr_rd,
  input  [85:0] boreChildrenBd_bore_1_wdata,
  input  [1:0]  boreChildrenBd_bore_1_wmask,
  input         boreChildrenBd_bore_1_re,
  input         boreChildrenBd_bore_1_we,
  output [85:0] boreChildrenBd_bore_1_rdata,
  input         boreChildrenBd_bore_1_ack,
  input         boreChildrenBd_bore_1_selectedOH,
  input  [5:0]  boreChildrenBd_bore_1_array,
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
  input         sigFromSrams_bore_1_cgen
);

  // 存储体 0：路 0-1
  TagSRAMBank tag_arrays_0 (
    .clock                          (clock),
    .reset                          (reset),
    .io_read_ready                  (),
    .io_read_valid                  (io_read_valid),
    .io_read_bits_idx               (io_read_bits_idx),
    .io_resp_0                      (io_resp_0),
    .io_resp_1                      (io_resp_1),
    .io_write_valid                 (io_write_valid),
    .io_write_bits_idx              (io_write_bits_idx),
    .io_write_bits_tag              (io_write_bits_tag),
    .io_write_bits_ecc              (io_write_bits_ecc),
    .io_write_bits_way_en           (io_write_bits_way_en[1:0]),
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

  // 存储体 1：路 2-3（它的 read.ready 作为本件的 io_read_ready）
  TagSRAMBank tag_arrays_1 (
    .clock                          (clock),
    .reset                          (reset),
    .io_read_ready                  (io_read_ready),
    .io_read_valid                  (io_read_valid),
    .io_read_bits_idx               (io_read_bits_idx),
    .io_resp_0                      (io_resp_2),
    .io_resp_1                      (io_resp_3),
    .io_write_valid                 (io_write_valid),
    .io_write_bits_idx              (io_write_bits_idx),
    .io_write_bits_tag              (io_write_bits_tag),
    .io_write_bits_ecc              (io_write_bits_ecc),
    .io_write_bits_way_en           (io_write_bits_way_en[3:2]),
    .boreChildrenBd_bore_addr       (boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_addr_rd    (boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_wdata      (boreChildrenBd_bore_1_wdata),
    .boreChildrenBd_bore_wmask      (boreChildrenBd_bore_1_wmask),
    .boreChildrenBd_bore_re         (boreChildrenBd_bore_1_re),
    .boreChildrenBd_bore_we         (boreChildrenBd_bore_1_we),
    .boreChildrenBd_bore_rdata      (boreChildrenBd_bore_1_rdata),
    .boreChildrenBd_bore_ack        (boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_selectedOH (boreChildrenBd_bore_1_selectedOH),
    .boreChildrenBd_bore_array      (boreChildrenBd_bore_1_array),
    .sigFromSrams_bore_ram_hold     (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_ram_bypass   (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk  (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_cgen         (sigFromSrams_bore_1_cgen)
  );

endmodule
