// =============================================================================
// SplittedSRAMTemplate 变体包装层（golden 同名，FM/ST 用）
//
// 对应 Chisel: utility.sram.SplittedSRAMTemplate —— 把一个逻辑 SRAM 按
// setSplit×waySplit×dataSplit 拆到多个物理 SRAMTemplate 实例。纯结构层（本变体
// setSplit=1/dataSplit=1，无自身时序逻辑）。内层 SRAMTemplate 作为已单独验证的
// 子模块复用（FM 时当黑盒）。
//
// 已覆盖变体：
//   SplittedSRAMTemplate : 逻辑 128set×4way×37b(struct{meta_tag[35:0],code})
//     waySplit=2 → 2 个 SRAMTemplate(128×2×37, icsh_tag)：
//       way0,1 → array_0_0_0   way2,3 → array_0_1_0
//     两套 MBIST bore（bore→inner0, bore_1→inner1）
// =============================================================================

module SplittedSRAMTemplate_4(
  input         clock,
  input         reset,
  output        io_r_req_ready,
  input         io_r_req_valid,
  input  [8:0]  io_r_req_bits_setIdx,
  output        io_r_resp_data_0_valid,
  output [7:0]  io_r_resp_data_0_tag,
  output [2:0]  io_r_resp_data_0_ctr,
  output        io_r_resp_data_1_valid,
  output [7:0]  io_r_resp_data_1_tag,
  output [2:0]  io_r_resp_data_1_ctr,
  input         io_w_req_valid,
  input  [8:0]  io_w_req_bits_setIdx,
  input  [7:0]  io_w_req_bits_data_0_tag,
  input  [2:0]  io_w_req_bits_data_0_ctr,
  input  [7:0]  io_w_req_bits_data_1_tag,
  input  [2:0]  io_w_req_bits_data_1_ctr,
  input  [1:0]  io_w_req_bits_waymask,
  input  [9:0]  boreChildrenBd_bore_addr,
  input  [9:0]  boreChildrenBd_bore_addr_rd,
  input  [23:0] boreChildrenBd_bore_wdata,
  input  [1:0]  boreChildrenBd_bore_wmask,
  input         boreChildrenBd_bore_re,
  input         boreChildrenBd_bore_we,
  output [23:0] boreChildrenBd_bore_rdata,
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
  // 每路 TAGE 条目 = {valid, tag[7:0], ctr[2:0]} = 12 位
  wire [11:0] way0_rdata, way1_rdata;

  SRAMTemplate_45 array_0_0_0 (
    .clock(clock), .reset(reset),
    .io_r_req_ready(io_r_req_ready),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data_0(way0_rdata), .io_r_resp_data_1(way1_rdata),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    // 写入 valid 恒 1：分配条目即有效
    .io_w_req_bits_data_0({1'b1, io_w_req_bits_data_0_tag, io_w_req_bits_data_0_ctr}),
    .io_w_req_bits_data_1({1'b1, io_w_req_bits_data_1_tag, io_w_req_bits_data_1_ctr}),
    .io_w_req_bits_waymask(io_w_req_bits_waymask),
    .io_broadcast_ram_hold(sigFromSrams_bore_ram_hold),
    .io_broadcast_ram_bypass(sigFromSrams_bore_ram_bypass),
    .io_broadcast_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .io_broadcast_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .io_broadcast_ram_ctl(64'h0), .io_broadcast_cgen(sigFromSrams_bore_cgen),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_array)
  );

  // 读：拆回 struct 字段
  assign io_r_resp_data_0_valid = way0_rdata[11];
  assign io_r_resp_data_0_tag   = way0_rdata[10:3];
  assign io_r_resp_data_0_ctr   = way0_rdata[2:0];
  assign io_r_resp_data_1_valid = way1_rdata[11];
  assign io_r_resp_data_1_tag   = way1_rdata[10:3];
  assign io_r_resp_data_1_ctr   = way1_rdata[2:0];
endmodule

// =============================================================================
// SplittedSRAMTemplate_25 —— ITTAGE 表：单 array + 逐位写掩码（bitmask）
//
// 逻辑 128set×2way×38b（ITTAGE 条目）。waySplit=1/dataSplit=1，整体一个
// SRAMTemplate_76。两个新看点：
//
// 1) struct 打包（每路 38 位，与 golden 位序一致，MSB→LSB）：
//      {valid=1'b1, tag[8:0], ctr[1:0], target_offset.offset[19:0],
//       target_offset.pointer[3:0], target_offset.usePCRegion, useful}
//    写时 valid 恒 1（同 TAGE）。
//
// 2) 逐位写掩码 flattened_bitmask：内层支持「按位」写使能（不是只能整路写）。
//    上层给 38 位 bitmask（每个条目字段一位粒度），Splitted 层把它「按路」铺开：
//      lane(way,bit) = waymask[way] & bitmask[bit]
//    即只有「该路被选中(waymask)」且「该位允许更新(bitmask)」时才写。
//    这让 ITTAGE 能只更新条目的部分字段（如只更 ctr / 只更 useful），不动其它。
//    用 genvar 表达 way×bit 二维铺开，避免 76 行手工展开。
// =============================================================================
