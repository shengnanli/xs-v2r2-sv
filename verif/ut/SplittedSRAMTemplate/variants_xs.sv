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
module SplittedSRAMTemplate_xs(
  input         clock,
  input         reset,
  output        io_r_req_ready,
  input         io_r_req_valid,
  input  [6:0]  io_r_req_bits_setIdx,
  output [35:0] io_r_resp_data_0_meta_tag,
  output        io_r_resp_data_0_code,
  output [35:0] io_r_resp_data_1_meta_tag,
  output        io_r_resp_data_1_code,
  output [35:0] io_r_resp_data_2_meta_tag,
  output        io_r_resp_data_2_code,
  output [35:0] io_r_resp_data_3_meta_tag,
  output        io_r_resp_data_3_code,
  input         io_w_req_valid,
  input  [6:0]  io_w_req_bits_setIdx,
  input  [35:0] io_w_req_bits_data_0_meta_tag,
  input         io_w_req_bits_data_0_code,
  input  [35:0] io_w_req_bits_data_1_meta_tag,
  input         io_w_req_bits_data_1_code,
  input  [35:0] io_w_req_bits_data_2_meta_tag,
  input         io_w_req_bits_data_2_code,
  input  [35:0] io_w_req_bits_data_3_meta_tag,
  input         io_w_req_bits_data_3_code,
  input  [3:0]  io_w_req_bits_waymask,
  input  [7:0]  boreChildrenBd_bore_addr,
  input  [7:0]  boreChildrenBd_bore_addr_rd,
  input  [73:0] boreChildrenBd_bore_wdata,
  input  [1:0]  boreChildrenBd_bore_wmask,
  input         boreChildrenBd_bore_re,
  input         boreChildrenBd_bore_we,
  output [73:0] boreChildrenBd_bore_rdata,
  input         boreChildrenBd_bore_ack,
  input         boreChildrenBd_bore_selectedOH,
  input         boreChildrenBd_bore_array,
  input  [7:0]  boreChildrenBd_bore_1_addr,
  input  [7:0]  boreChildrenBd_bore_1_addr_rd,
  input  [73:0] boreChildrenBd_bore_1_wdata,
  input  [1:0]  boreChildrenBd_bore_1_wmask,
  input         boreChildrenBd_bore_1_re,
  input         boreChildrenBd_bore_1_we,
  output [73:0] boreChildrenBd_bore_1_rdata,
  input         boreChildrenBd_bore_1_ack,
  input         boreChildrenBd_bore_1_selectedOH,
  input         boreChildrenBd_bore_1_array,
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
  // 每路数据 = {meta_tag[35:0], code} = 37 位（与内层 SRAMTemplate 一致）
  wire [36:0] inner0_rdata_0, inner0_rdata_1;  // way0, way1
  wire [36:0] inner1_rdata_0, inner1_rdata_1;  // way2, way3

  // inner0：承载 way0/way1，bore/broadcast 用第 0 套
  SRAMTemplate array_0_0_0 (
    .clock(clock), .reset(reset),
    .io_r_req_ready(io_r_req_ready),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data_0(inner0_rdata_0), .io_r_resp_data_1(inner0_rdata_1),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data_0({io_w_req_bits_data_0_meta_tag, io_w_req_bits_data_0_code}),
    .io_w_req_bits_data_1({io_w_req_bits_data_1_meta_tag, io_w_req_bits_data_1_code}),
    .io_w_req_bits_waymask(io_w_req_bits_waymask[1:0]),
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

  // inner1：承载 way2/way3，bore/broadcast 用第 1 套；ready 不引出
  SRAMTemplate array_0_1_0 (
    .clock(clock), .reset(reset),
    .io_r_req_ready(/* unused */),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data_0(inner1_rdata_0), .io_r_resp_data_1(inner1_rdata_1),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data_0({io_w_req_bits_data_2_meta_tag, io_w_req_bits_data_2_code}),
    .io_w_req_bits_data_1({io_w_req_bits_data_3_meta_tag, io_w_req_bits_data_3_code}),
    .io_w_req_bits_waymask(io_w_req_bits_waymask[3:2]),
    .io_broadcast_ram_hold(sigFromSrams_bore_1_ram_hold),
    .io_broadcast_ram_bypass(sigFromSrams_bore_1_ram_bypass),
    .io_broadcast_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .io_broadcast_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .io_broadcast_ram_ctl(64'h0), .io_broadcast_cgen(sigFromSrams_bore_1_cgen),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_wdata(boreChildrenBd_bore_1_wdata),
    .boreChildrenBd_bore_wmask(boreChildrenBd_bore_1_wmask),
    .boreChildrenBd_bore_re(boreChildrenBd_bore_1_re),
    .boreChildrenBd_bore_we(boreChildrenBd_bore_1_we),
    .boreChildrenBd_bore_rdata(boreChildrenBd_bore_1_rdata),
    .boreChildrenBd_bore_ack(boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_selectedOH(boreChildrenBd_bore_1_selectedOH),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_1_array)
  );

  // 读响应：每路 37 位拆回 {meta_tag[36:1], code[0]}
  assign io_r_resp_data_0_meta_tag = inner0_rdata_0[36:1];
  assign io_r_resp_data_0_code     = inner0_rdata_0[0];
  assign io_r_resp_data_1_meta_tag = inner0_rdata_1[36:1];
  assign io_r_resp_data_1_code     = inner0_rdata_1[0];
  assign io_r_resp_data_2_meta_tag = inner1_rdata_0[36:1];
  assign io_r_resp_data_2_code     = inner1_rdata_0[0];
  assign io_r_resp_data_3_meta_tag = inner1_rdata_1[36:1];
  assign io_r_resp_data_3_code     = inner1_rdata_1[0];

endmodule
