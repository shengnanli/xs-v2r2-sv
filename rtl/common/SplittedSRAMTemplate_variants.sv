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
module SplittedSRAMTemplate(
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

// =============================================================================
// SplittedSRAMTemplate_1 —— 与 base 同构（icsh_tag 的另一处例化）
//
// 逻辑 128set×4way×37b（struct{meta_tag[35:0],code}），waySplit=2，内层 SRAMTemplate_2
// （同样 128×2×37 的 icsh_tag 宏，只是 firtool 去重后的另一个名字）。
// 与 base SplittedSRAMTemplate 的唯一区别：内层模块名 + bore_array 是 [1:0]
// （两个 mbist 物理 array 各 1 位）而非 1 位。结构连线完全一致。
// =============================================================================
module SplittedSRAMTemplate_1(
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
  input  [1:0]  boreChildrenBd_bore_array,
  input  [7:0]  boreChildrenBd_bore_1_addr,
  input  [7:0]  boreChildrenBd_bore_1_addr_rd,
  input  [73:0] boreChildrenBd_bore_1_wdata,
  input  [1:0]  boreChildrenBd_bore_1_wmask,
  input         boreChildrenBd_bore_1_re,
  input         boreChildrenBd_bore_1_we,
  output [73:0] boreChildrenBd_bore_1_rdata,
  input         boreChildrenBd_bore_1_ack,
  input         boreChildrenBd_bore_1_selectedOH,
  input  [1:0]  boreChildrenBd_bore_1_array,
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
  // 每路数据 = {meta_tag[35:0], code} = 37 位
  wire [36:0] inner0_rdata_0, inner0_rdata_1;  // way0, way1
  wire [36:0] inner1_rdata_0, inner1_rdata_1;  // way2, way3

  // inner0：way0/way1
  SRAMTemplate_2 array_0_0_0 (
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

  // inner1：way2/way3
  SRAMTemplate_2 array_0_1_0 (
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

  assign io_r_resp_data_0_meta_tag = inner0_rdata_0[36:1];
  assign io_r_resp_data_0_code     = inner0_rdata_0[0];
  assign io_r_resp_data_1_meta_tag = inner0_rdata_1[36:1];
  assign io_r_resp_data_1_code     = inner0_rdata_1[0];
  assign io_r_resp_data_2_meta_tag = inner1_rdata_0[36:1];
  assign io_r_resp_data_2_code     = inner1_rdata_0[0];
  assign io_r_resp_data_3_meta_tag = inner1_rdata_1[36:1];
  assign io_r_resp_data_3_code     = inner1_rdata_1[0];
endmodule

// =============================================================================
// SplittedSRAMTemplate_3 —— 退化情形：setSplit=waySplit=dataSplit=1（纯透传）
//
// 逻辑 256set×16way×1b（TAGE useful 表），不拆分：整个逻辑 SRAM 就是一个物理
// SRAMTemplate_44。Splitted 层在这里只是把 16 路平铺端口一一接到内层、并把
// 单套 bore/broadcast 直通。带 extra_reset（useful 表周期性清零）。
// 作为 FoldedSRAMTemplate 的内层使用。
// =============================================================================
module SplittedSRAMTemplate_3(
  input         clock,
  input         reset,
  output        io_r_req_ready,
  input         io_r_req_valid,
  input  [7:0]  io_r_req_bits_setIdx,
  output        io_r_resp_data_0,  output io_r_resp_data_1,
  output        io_r_resp_data_2,  output io_r_resp_data_3,
  output        io_r_resp_data_4,  output io_r_resp_data_5,
  output        io_r_resp_data_6,  output io_r_resp_data_7,
  output        io_r_resp_data_8,  output io_r_resp_data_9,
  output        io_r_resp_data_10, output io_r_resp_data_11,
  output        io_r_resp_data_12, output io_r_resp_data_13,
  output        io_r_resp_data_14, output io_r_resp_data_15,
  input         io_w_req_valid,
  input  [7:0]  io_w_req_bits_setIdx,
  input         io_w_req_bits_data_0,  input io_w_req_bits_data_1,
  input         io_w_req_bits_data_2,  input io_w_req_bits_data_3,
  input         io_w_req_bits_data_4,  input io_w_req_bits_data_5,
  input         io_w_req_bits_data_6,  input io_w_req_bits_data_7,
  input         io_w_req_bits_data_8,  input io_w_req_bits_data_9,
  input         io_w_req_bits_data_10, input io_w_req_bits_data_11,
  input         io_w_req_bits_data_12, input io_w_req_bits_data_13,
  input         io_w_req_bits_data_14, input io_w_req_bits_data_15,
  input  [15:0] io_w_req_bits_waymask,
  input         extra_reset,
  input  [8:0]  boreChildrenBd_bore_addr,
  input  [8:0]  boreChildrenBd_bore_addr_rd,
  input  [15:0] boreChildrenBd_bore_wdata,
  input  [15:0] boreChildrenBd_bore_wmask,
  input         boreChildrenBd_bore_re,
  input         boreChildrenBd_bore_we,
  output [15:0] boreChildrenBd_bore_rdata,
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
  // 1:1 透传到唯一内层（无拆分）
  SRAMTemplate_44 array_0_0_0 (
    .clock(clock), .reset(reset),
    .io_r_req_ready(io_r_req_ready),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data_0(io_r_resp_data_0),   .io_r_resp_data_1(io_r_resp_data_1),
    .io_r_resp_data_2(io_r_resp_data_2),   .io_r_resp_data_3(io_r_resp_data_3),
    .io_r_resp_data_4(io_r_resp_data_4),   .io_r_resp_data_5(io_r_resp_data_5),
    .io_r_resp_data_6(io_r_resp_data_6),   .io_r_resp_data_7(io_r_resp_data_7),
    .io_r_resp_data_8(io_r_resp_data_8),   .io_r_resp_data_9(io_r_resp_data_9),
    .io_r_resp_data_10(io_r_resp_data_10), .io_r_resp_data_11(io_r_resp_data_11),
    .io_r_resp_data_12(io_r_resp_data_12), .io_r_resp_data_13(io_r_resp_data_13),
    .io_r_resp_data_14(io_r_resp_data_14), .io_r_resp_data_15(io_r_resp_data_15),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data_0(io_w_req_bits_data_0),   .io_w_req_bits_data_1(io_w_req_bits_data_1),
    .io_w_req_bits_data_2(io_w_req_bits_data_2),   .io_w_req_bits_data_3(io_w_req_bits_data_3),
    .io_w_req_bits_data_4(io_w_req_bits_data_4),   .io_w_req_bits_data_5(io_w_req_bits_data_5),
    .io_w_req_bits_data_6(io_w_req_bits_data_6),   .io_w_req_bits_data_7(io_w_req_bits_data_7),
    .io_w_req_bits_data_8(io_w_req_bits_data_8),   .io_w_req_bits_data_9(io_w_req_bits_data_9),
    .io_w_req_bits_data_10(io_w_req_bits_data_10), .io_w_req_bits_data_11(io_w_req_bits_data_11),
    .io_w_req_bits_data_12(io_w_req_bits_data_12), .io_w_req_bits_data_13(io_w_req_bits_data_13),
    .io_w_req_bits_data_14(io_w_req_bits_data_14), .io_w_req_bits_data_15(io_w_req_bits_data_15),
    .io_w_req_bits_waymask(io_w_req_bits_waymask),
    .io_broadcast_ram_hold(sigFromSrams_bore_ram_hold),
    .io_broadcast_ram_bypass(sigFromSrams_bore_ram_bypass),
    .io_broadcast_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .io_broadcast_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .io_broadcast_ram_ctl(64'h0), .io_broadcast_cgen(sigFromSrams_bore_cgen),
    .extra_reset(extra_reset),
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
endmodule

// =============================================================================
// SplittedSRAMTemplate_4 —— TAGE 表：dataSplit=1，struct{valid,tag,ctr} 打包
//
// 逻辑 512set×2way×12b（TAGE 表条目 = valid(1)+tag(8)+ctr(3)）。waySplit=1，
// 整个逻辑 SRAM 是一个 SRAMTemplate_45（512×2×12）。Splitted 层在此只做
// struct↔扁平位 的打包/解包：
//   写：每路打包成 {valid=1'b1, tag[7:0], ctr[2:0]}（写入即有效，valid 恒 1）
//   读：拆回 valid=[11], tag=[10:3], ctr=[2:0]
// 「写时 valid 硬连 1」是 TAGE 的设计：分配一条目即视为有效。
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
// SplittedSRAMTemplate_24 —— ITTAGE 表：单 array + 逐位写掩码（bitmask）
//
// 逻辑 128set×2way×38b（ITTAGE 条目）。waySplit=1/dataSplit=1，整体一个
// SRAMTemplate_70。两个新看点：
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
module SplittedSRAMTemplate_24(
  input         clock,
  input         reset,
  output        io_r_req_ready,
  input         io_r_req_valid,
  input  [6:0]  io_r_req_bits_setIdx,
  output        io_r_resp_data_0_valid,
  output [8:0]  io_r_resp_data_0_tag,
  output [1:0]  io_r_resp_data_0_ctr,
  output [19:0] io_r_resp_data_0_target_offset_offset,
  output [3:0]  io_r_resp_data_0_target_offset_pointer,
  output        io_r_resp_data_0_target_offset_usePCRegion,
  output        io_r_resp_data_0_useful,
  output        io_r_resp_data_1_valid,
  output [8:0]  io_r_resp_data_1_tag,
  output [1:0]  io_r_resp_data_1_ctr,
  output [19:0] io_r_resp_data_1_target_offset_offset,
  output [3:0]  io_r_resp_data_1_target_offset_pointer,
  output        io_r_resp_data_1_target_offset_usePCRegion,
  output        io_r_resp_data_1_useful,
  input         io_w_req_valid,
  input  [6:0]  io_w_req_bits_setIdx,
  input  [8:0]  io_w_req_bits_data_0_tag,
  input  [1:0]  io_w_req_bits_data_0_ctr,
  input  [19:0] io_w_req_bits_data_0_target_offset_offset,
  input  [3:0]  io_w_req_bits_data_0_target_offset_pointer,
  input         io_w_req_bits_data_0_target_offset_usePCRegion,
  input         io_w_req_bits_data_0_useful,
  input  [8:0]  io_w_req_bits_data_1_tag,
  input  [1:0]  io_w_req_bits_data_1_ctr,
  input  [19:0] io_w_req_bits_data_1_target_offset_offset,
  input  [3:0]  io_w_req_bits_data_1_target_offset_pointer,
  input         io_w_req_bits_data_1_target_offset_usePCRegion,
  input         io_w_req_bits_data_1_useful,
  input  [1:0]  io_w_req_bits_waymask,
  input  [37:0] io_w_req_bits_bitmask,
  input  [7:0]  boreChildrenBd_bore_addr,
  input  [7:0]  boreChildrenBd_bore_addr_rd,
  input  [75:0] boreChildrenBd_bore_wdata,
  input  [75:0] boreChildrenBd_bore_wmask,
  input         boreChildrenBd_bore_re,
  input         boreChildrenBd_bore_we,
  output [75:0] boreChildrenBd_bore_rdata,
  input         boreChildrenBd_bore_ack,
  input         boreChildrenBd_bore_selectedOH,
  input  [6:0]  boreChildrenBd_bore_array,
  input         sigFromSrams_bore_ram_hold,
  input         sigFromSrams_bore_ram_bypass,
  input         sigFromSrams_bore_ram_bp_clken,
  input         sigFromSrams_bore_ram_aux_clk,
  input         sigFromSrams_bore_ram_aux_ckbp,
  input         sigFromSrams_bore_ram_mcp_hold,
  input         sigFromSrams_bore_cgen
);
  localparam int ENTRY_W = 38;  // 每路条目位宽

  // 每路打包数据（38 位，与 golden 位序一致）
  wire [ENTRY_W-1:0] way0_wd = {1'b1, io_w_req_bits_data_0_tag, io_w_req_bits_data_0_ctr,
                                io_w_req_bits_data_0_target_offset_offset,
                                io_w_req_bits_data_0_target_offset_pointer,
                                io_w_req_bits_data_0_target_offset_usePCRegion,
                                io_w_req_bits_data_0_useful};
  wire [ENTRY_W-1:0] way1_wd = {1'b1, io_w_req_bits_data_1_tag, io_w_req_bits_data_1_ctr,
                                io_w_req_bits_data_1_target_offset_offset,
                                io_w_req_bits_data_1_target_offset_pointer,
                                io_w_req_bits_data_1_target_offset_usePCRegion,
                                io_w_req_bits_data_1_useful};

  // 逐位写掩码按路铺开：lane[way][bit] = waymask[way] & bitmask[bit]
  // 内层 flattened_bitmask 排布为 {way1[37:0], way0[37:0]}。
  wire [2*ENTRY_W-1:0] flat_bitmask;
  genvar w, b;
  generate
    for (w = 0; w < 2; w++) begin : g_way
      for (b = 0; b < ENTRY_W; b++) begin : g_bit
        assign flat_bitmask[w*ENTRY_W + b] = io_w_req_bits_waymask[w] & io_w_req_bits_bitmask[b];
      end
    end
  endgenerate

  wire [ENTRY_W-1:0] way0_rdata, way1_rdata;

  SRAMTemplate_70 array_0_0_0 (
    .clock(clock), .reset(reset),
    .io_r_req_ready(io_r_req_ready),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data_0(way0_rdata), .io_r_resp_data_1(way1_rdata),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data_0(way0_wd), .io_w_req_bits_data_1(way1_wd),
    .io_w_req_bits_flattened_bitmask(flat_bitmask),
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

  // 读：拆回 struct 字段（与 golden 位序一致）
  assign io_r_resp_data_0_valid                     = way0_rdata[37];
  assign io_r_resp_data_0_tag                       = way0_rdata[36:28];
  assign io_r_resp_data_0_ctr                       = way0_rdata[27:26];
  assign io_r_resp_data_0_target_offset_offset      = way0_rdata[25:6];
  assign io_r_resp_data_0_target_offset_pointer     = way0_rdata[5:2];
  assign io_r_resp_data_0_target_offset_usePCRegion = way0_rdata[1];
  assign io_r_resp_data_0_useful                    = way0_rdata[0];
  assign io_r_resp_data_1_valid                     = way1_rdata[37];
  assign io_r_resp_data_1_tag                       = way1_rdata[36:28];
  assign io_r_resp_data_1_ctr                       = way1_rdata[27:26];
  assign io_r_resp_data_1_target_offset_offset      = way1_rdata[25:6];
  assign io_r_resp_data_1_target_offset_pointer     = way1_rdata[5:2];
  assign io_r_resp_data_1_target_offset_usePCRegion = way1_rdata[1];
  assign io_r_resp_data_1_useful                    = way1_rdata[0];
endmodule

// =============================================================================
// SplittedSRAMTemplate_26 —— ITTAGE 表：dataSplit=2 + 逐位写掩码 + 双 bore
//
// 逻辑 128set×4way×38b（同 _24 的 ITTAGE 条目，但 4 路）。这里 dataSplit=2：
// 把每路 38 位条目「沿数据维」切成两半，各 19 位，分别存进两个 SRAMTemplate_72
// （每个 128×4×19）。这是「逻辑字太宽，按数据位拆到多个物理 array」的范例。
//
// 切分（与 golden 精确位序一致）：
//   inner0（低半，19 位）= {offset[12:0], pointer[3:0], usePCRegion, useful}
//   inner1（高半，19 位）= {valid=1'b1, tag[8:0], ctr[1:0], offset[19:13]}
//   读时高低半拼回：offset = {inner1[6:0], inner0[18:6]}。
//
// 逐位写掩码同 _24，但要按「数据切分」分给两半：
//   inner0 的 19 位掩码 = bitmask[18:0]，inner1 的 19 位掩码 = bitmask[37:19]，
//   再各自按 4 路用 waymask 铺成 76 位。
//
// 两套 bore：inner0↔bore，inner1↔bore_1。
// =============================================================================
module SplittedSRAMTemplate_26(
  input         clock,
  input         reset,
  output        io_r_req_ready,
  input         io_r_req_valid,
  input  [6:0]  io_r_req_bits_setIdx,
  output        io_r_resp_data_0_valid,
  output [8:0]  io_r_resp_data_0_tag,
  output [1:0]  io_r_resp_data_0_ctr,
  output [19:0] io_r_resp_data_0_target_offset_offset,
  output [3:0]  io_r_resp_data_0_target_offset_pointer,
  output        io_r_resp_data_0_target_offset_usePCRegion,
  output        io_r_resp_data_0_useful,
  output        io_r_resp_data_1_valid,
  output [8:0]  io_r_resp_data_1_tag,
  output [1:0]  io_r_resp_data_1_ctr,
  output [19:0] io_r_resp_data_1_target_offset_offset,
  output [3:0]  io_r_resp_data_1_target_offset_pointer,
  output        io_r_resp_data_1_target_offset_usePCRegion,
  output        io_r_resp_data_1_useful,
  output        io_r_resp_data_2_valid,
  output [8:0]  io_r_resp_data_2_tag,
  output [1:0]  io_r_resp_data_2_ctr,
  output [19:0] io_r_resp_data_2_target_offset_offset,
  output [3:0]  io_r_resp_data_2_target_offset_pointer,
  output        io_r_resp_data_2_target_offset_usePCRegion,
  output        io_r_resp_data_2_useful,
  output        io_r_resp_data_3_valid,
  output [8:0]  io_r_resp_data_3_tag,
  output [1:0]  io_r_resp_data_3_ctr,
  output [19:0] io_r_resp_data_3_target_offset_offset,
  output [3:0]  io_r_resp_data_3_target_offset_pointer,
  output        io_r_resp_data_3_target_offset_usePCRegion,
  output        io_r_resp_data_3_useful,
  input         io_w_req_valid,
  input  [6:0]  io_w_req_bits_setIdx,
  input  [8:0]  io_w_req_bits_data_0_tag,
  input  [1:0]  io_w_req_bits_data_0_ctr,
  input  [19:0] io_w_req_bits_data_0_target_offset_offset,
  input  [3:0]  io_w_req_bits_data_0_target_offset_pointer,
  input         io_w_req_bits_data_0_target_offset_usePCRegion,
  input         io_w_req_bits_data_0_useful,
  input  [8:0]  io_w_req_bits_data_1_tag,
  input  [1:0]  io_w_req_bits_data_1_ctr,
  input  [19:0] io_w_req_bits_data_1_target_offset_offset,
  input  [3:0]  io_w_req_bits_data_1_target_offset_pointer,
  input         io_w_req_bits_data_1_target_offset_usePCRegion,
  input         io_w_req_bits_data_1_useful,
  input  [8:0]  io_w_req_bits_data_2_tag,
  input  [1:0]  io_w_req_bits_data_2_ctr,
  input  [19:0] io_w_req_bits_data_2_target_offset_offset,
  input  [3:0]  io_w_req_bits_data_2_target_offset_pointer,
  input         io_w_req_bits_data_2_target_offset_usePCRegion,
  input         io_w_req_bits_data_2_useful,
  input  [8:0]  io_w_req_bits_data_3_tag,
  input  [1:0]  io_w_req_bits_data_3_ctr,
  input  [19:0] io_w_req_bits_data_3_target_offset_offset,
  input  [3:0]  io_w_req_bits_data_3_target_offset_pointer,
  input         io_w_req_bits_data_3_target_offset_usePCRegion,
  input         io_w_req_bits_data_3_useful,
  input  [3:0]  io_w_req_bits_waymask,
  input  [37:0] io_w_req_bits_bitmask,
  input  [7:0]  boreChildrenBd_bore_addr,
  input  [7:0]  boreChildrenBd_bore_addr_rd,
  input  [75:0] boreChildrenBd_bore_wdata,
  input  [75:0] boreChildrenBd_bore_wmask,
  input         boreChildrenBd_bore_re,
  input         boreChildrenBd_bore_we,
  output [75:0] boreChildrenBd_bore_rdata,
  input         boreChildrenBd_bore_ack,
  input         boreChildrenBd_bore_selectedOH,
  input  [6:0]  boreChildrenBd_bore_array,
  input  [7:0]  boreChildrenBd_bore_1_addr,
  input  [7:0]  boreChildrenBd_bore_1_addr_rd,
  input  [75:0] boreChildrenBd_bore_1_wdata,
  input  [75:0] boreChildrenBd_bore_1_wmask,
  input         boreChildrenBd_bore_1_re,
  input         boreChildrenBd_bore_1_we,
  output [75:0] boreChildrenBd_bore_1_rdata,
  input         boreChildrenBd_bore_1_ack,
  input         boreChildrenBd_bore_1_selectedOH,
  input  [6:0]  boreChildrenBd_bore_1_array,
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
  localparam int HALF_W = 19;  // 每个数据切片的位宽（38/2）

  // ---- 把 4 路 struct 打包成「低半 / 高半」两个 19 位切片 ----
  wire [HALF_W-1:0] lo_wd [4];  // inner0：每路低半
  wire [HALF_W-1:0] hi_wd [4];  // inner1：每路高半
  // 用数组聚合 4 路输入，便于 genvar 打包（避免 4×手抄）
  wire [8:0]  in_tag       [4];
  wire [1:0]  in_ctr       [4];
  wire [19:0] in_offset    [4];
  wire [3:0]  in_pointer   [4];
  wire        in_usePCReg  [4];
  wire        in_useful    [4];
  assign in_tag[0]=io_w_req_bits_data_0_tag; assign in_tag[1]=io_w_req_bits_data_1_tag;
  assign in_tag[2]=io_w_req_bits_data_2_tag; assign in_tag[3]=io_w_req_bits_data_3_tag;
  assign in_ctr[0]=io_w_req_bits_data_0_ctr; assign in_ctr[1]=io_w_req_bits_data_1_ctr;
  assign in_ctr[2]=io_w_req_bits_data_2_ctr; assign in_ctr[3]=io_w_req_bits_data_3_ctr;
  assign in_offset[0]=io_w_req_bits_data_0_target_offset_offset;
  assign in_offset[1]=io_w_req_bits_data_1_target_offset_offset;
  assign in_offset[2]=io_w_req_bits_data_2_target_offset_offset;
  assign in_offset[3]=io_w_req_bits_data_3_target_offset_offset;
  assign in_pointer[0]=io_w_req_bits_data_0_target_offset_pointer;
  assign in_pointer[1]=io_w_req_bits_data_1_target_offset_pointer;
  assign in_pointer[2]=io_w_req_bits_data_2_target_offset_pointer;
  assign in_pointer[3]=io_w_req_bits_data_3_target_offset_pointer;
  assign in_usePCReg[0]=io_w_req_bits_data_0_target_offset_usePCRegion;
  assign in_usePCReg[1]=io_w_req_bits_data_1_target_offset_usePCRegion;
  assign in_usePCReg[2]=io_w_req_bits_data_2_target_offset_usePCRegion;
  assign in_usePCReg[3]=io_w_req_bits_data_3_target_offset_usePCRegion;
  assign in_useful[0]=io_w_req_bits_data_0_useful; assign in_useful[1]=io_w_req_bits_data_1_useful;
  assign in_useful[2]=io_w_req_bits_data_2_useful; assign in_useful[3]=io_w_req_bits_data_3_useful;

  genvar wy, bt;
  generate
    for (wy = 0; wy < 4; wy++) begin : g_pack
      // 低半 = {offset[12:0], pointer[3:0], usePCRegion, useful}
      assign lo_wd[wy] = {in_offset[wy][12:0], in_pointer[wy], in_usePCReg[wy], in_useful[wy]};
      // 高半 = {valid=1, tag[8:0], ctr[1:0], offset[19:13]}
      assign hi_wd[wy] = {1'b1, in_tag[wy], in_ctr[wy], in_offset[wy][19:13]};
    end
  endgenerate

  // ---- 逐位写掩码：先按数据维取该切片对应的 19 位，再按 4 路用 waymask 铺开 ----
  wire [4*HALF_W-1:0] lo_bitmask;  // inner0：{way3..way0} 各 19 位
  wire [4*HALF_W-1:0] hi_bitmask;  // inner1
  generate
    for (wy = 0; wy < 4; wy++) begin : g_mask_way
      for (bt = 0; bt < HALF_W; bt++) begin : g_mask_bit
        // 低半对应原 bitmask[18:0]，高半对应原 bitmask[37:19]
        assign lo_bitmask[wy*HALF_W + bt] = io_w_req_bits_waymask[wy] & io_w_req_bits_bitmask[bt];
        assign hi_bitmask[wy*HALF_W + bt] = io_w_req_bits_waymask[wy] & io_w_req_bits_bitmask[HALF_W + bt];
      end
    end
  endgenerate

  wire [HALF_W-1:0] lo_rd [4];  // inner0 读出
  wire [HALF_W-1:0] hi_rd [4];  // inner1 读出

  // inner0：低半切片（bore）
  SRAMTemplate_72 array_0_0_0 (
    .clock(clock), .reset(reset),
    .io_r_req_ready(io_r_req_ready),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data_0(lo_rd[0]), .io_r_resp_data_1(lo_rd[1]),
    .io_r_resp_data_2(lo_rd[2]), .io_r_resp_data_3(lo_rd[3]),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data_0(lo_wd[0]), .io_w_req_bits_data_1(lo_wd[1]),
    .io_w_req_bits_data_2(lo_wd[2]), .io_w_req_bits_data_3(lo_wd[3]),
    .io_w_req_bits_flattened_bitmask(lo_bitmask),
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

  // inner1：高半切片（bore_1）
  SRAMTemplate_72 array_0_0_1 (
    .clock(clock), .reset(reset),
    .io_r_req_ready(/* unused */),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data_0(hi_rd[0]), .io_r_resp_data_1(hi_rd[1]),
    .io_r_resp_data_2(hi_rd[2]), .io_r_resp_data_3(hi_rd[3]),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data_0(hi_wd[0]), .io_w_req_bits_data_1(hi_wd[1]),
    .io_w_req_bits_data_2(hi_wd[2]), .io_w_req_bits_data_3(hi_wd[3]),
    .io_w_req_bits_flattened_bitmask(hi_bitmask),
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

  // ---- 读：高低半拼回 struct 字段 ----
  // 低半：[18:6]=offset[12:0], [5:2]=pointer, [1]=usePCRegion, [0]=useful
  // 高半：[18]=valid, [17:9]=tag, [8:7]=ctr, [6:0]=offset[19:13]
  assign io_r_resp_data_0_valid                     = hi_rd[0][18];
  assign io_r_resp_data_0_tag                       = hi_rd[0][17:9];
  assign io_r_resp_data_0_ctr                       = hi_rd[0][8:7];
  assign io_r_resp_data_0_target_offset_offset      = {hi_rd[0][6:0], lo_rd[0][18:6]};
  assign io_r_resp_data_0_target_offset_pointer     = lo_rd[0][5:2];
  assign io_r_resp_data_0_target_offset_usePCRegion = lo_rd[0][1];
  assign io_r_resp_data_0_useful                    = lo_rd[0][0];
  assign io_r_resp_data_1_valid                     = hi_rd[1][18];
  assign io_r_resp_data_1_tag                       = hi_rd[1][17:9];
  assign io_r_resp_data_1_ctr                       = hi_rd[1][8:7];
  assign io_r_resp_data_1_target_offset_offset      = {hi_rd[1][6:0], lo_rd[1][18:6]};
  assign io_r_resp_data_1_target_offset_pointer     = lo_rd[1][5:2];
  assign io_r_resp_data_1_target_offset_usePCRegion = lo_rd[1][1];
  assign io_r_resp_data_1_useful                    = lo_rd[1][0];
  assign io_r_resp_data_2_valid                     = hi_rd[2][18];
  assign io_r_resp_data_2_tag                       = hi_rd[2][17:9];
  assign io_r_resp_data_2_ctr                       = hi_rd[2][8:7];
  assign io_r_resp_data_2_target_offset_offset      = {hi_rd[2][6:0], lo_rd[2][18:6]};
  assign io_r_resp_data_2_target_offset_pointer     = lo_rd[2][5:2];
  assign io_r_resp_data_2_target_offset_usePCRegion = lo_rd[2][1];
  assign io_r_resp_data_2_useful                    = lo_rd[2][0];
  assign io_r_resp_data_3_valid                     = hi_rd[3][18];
  assign io_r_resp_data_3_tag                       = hi_rd[3][17:9];
  assign io_r_resp_data_3_ctr                       = hi_rd[3][8:7];
  assign io_r_resp_data_3_target_offset_offset      = {hi_rd[3][6:0], lo_rd[3][18:6]};
  assign io_r_resp_data_3_target_offset_pointer     = lo_rd[3][5:2];
  assign io_r_resp_data_3_target_offset_usePCRegion = lo_rd[3][1];
  assign io_r_resp_data_3_useful                    = lo_rd[3][0];
endmodule

// =============================================================================
// SplittedSRAMTemplate_2 —— FTB 表：dataSplit=8（把每路 80 位条目切成 8×10 位）
//
// 逻辑 512set×4way×80b（FTB 条目 entry + tag）。dataSplit=8：每路 80 位沿数据维
// 等分成 8 个 10 位切片，分别存进 8 个 SRAMTemplate_36（每个 512×4×10）。这是
// dataSplit 拉满的范例——FTB 条目很宽，按 10 位粒度铺到 8 个窄物理 array，便于
// 物理实现（窄而规整的 SRAM 宏）。
//
// 【每路 80 位的「物理打包字」布局】（chunk i = array_0_0_i，[10*i+9 : 10*i]）：
//   chunk0 = tag[9:0]
//   chunk1 = tag[19:10]
//   chunk2 = {tailSlot.tarStat[1:0], pftAddr[3:0], carry, last_may_be_rvi_call,
//             strong_bias_1, strong_bias_0}
//   chunk3 = tailSlot.lower[9:0]
//   chunk4 = tailSlot.lower[19:10]
//   chunk5 = {brSlot.lower[1:0], brSlot.tarStat[1:0], tailSlot.offset[3:0],
//             tailSlot.sharing, tailSlot.valid}
//   chunk6 = brSlot.lower[11:2]
//   chunk7 = {isCall, isRet, isJalr, valid, brSlot.offset[3:0],
//             brSlot.sharing, brSlot.valid}
// 此布局即 firtool 对 FTBEntry 的物理位序（非 struct 直接 flatten），读写两侧严格一致。
//
// 每路无 valid/掩码概念（整条目按 waymask 整体写），8 个内层共用 waymask[3:0]。
// 8 套 bore（bore..bore_7 → array_0_0_0..7）、8 套 broadcast。
// =============================================================================
module SplittedSRAMTemplate_2(
  input         clock,
  input         reset,
  output        io_r_req_ready,
  input         io_r_req_valid,
  input  [8:0]  io_r_req_bits_setIdx,
  output        io_r_resp_data_0_entry_isCall,
  output        io_r_resp_data_0_entry_isRet,
  output        io_r_resp_data_0_entry_isJalr,
  output        io_r_resp_data_0_entry_valid,
  output [3:0]  io_r_resp_data_0_entry_brSlots_0_offset,
  output        io_r_resp_data_0_entry_brSlots_0_sharing,
  output        io_r_resp_data_0_entry_brSlots_0_valid,
  output [11:0] io_r_resp_data_0_entry_brSlots_0_lower,
  output [1:0]  io_r_resp_data_0_entry_brSlots_0_tarStat,
  output [3:0]  io_r_resp_data_0_entry_tailSlot_offset,
  output        io_r_resp_data_0_entry_tailSlot_sharing,
  output        io_r_resp_data_0_entry_tailSlot_valid,
  output [19:0] io_r_resp_data_0_entry_tailSlot_lower,
  output [1:0]  io_r_resp_data_0_entry_tailSlot_tarStat,
  output [3:0]  io_r_resp_data_0_entry_pftAddr,
  output        io_r_resp_data_0_entry_carry,
  output        io_r_resp_data_0_entry_last_may_be_rvi_call,
  output        io_r_resp_data_0_entry_strong_bias_0,
  output        io_r_resp_data_0_entry_strong_bias_1,
  output [19:0] io_r_resp_data_0_tag,
  output        io_r_resp_data_1_entry_isCall,
  output        io_r_resp_data_1_entry_isRet,
  output        io_r_resp_data_1_entry_isJalr,
  output        io_r_resp_data_1_entry_valid,
  output [3:0]  io_r_resp_data_1_entry_brSlots_0_offset,
  output        io_r_resp_data_1_entry_brSlots_0_sharing,
  output        io_r_resp_data_1_entry_brSlots_0_valid,
  output [11:0] io_r_resp_data_1_entry_brSlots_0_lower,
  output [1:0]  io_r_resp_data_1_entry_brSlots_0_tarStat,
  output [3:0]  io_r_resp_data_1_entry_tailSlot_offset,
  output        io_r_resp_data_1_entry_tailSlot_sharing,
  output        io_r_resp_data_1_entry_tailSlot_valid,
  output [19:0] io_r_resp_data_1_entry_tailSlot_lower,
  output [1:0]  io_r_resp_data_1_entry_tailSlot_tarStat,
  output [3:0]  io_r_resp_data_1_entry_pftAddr,
  output        io_r_resp_data_1_entry_carry,
  output        io_r_resp_data_1_entry_last_may_be_rvi_call,
  output        io_r_resp_data_1_entry_strong_bias_0,
  output        io_r_resp_data_1_entry_strong_bias_1,
  output [19:0] io_r_resp_data_1_tag,
  output        io_r_resp_data_2_entry_isCall,
  output        io_r_resp_data_2_entry_isRet,
  output        io_r_resp_data_2_entry_isJalr,
  output        io_r_resp_data_2_entry_valid,
  output [3:0]  io_r_resp_data_2_entry_brSlots_0_offset,
  output        io_r_resp_data_2_entry_brSlots_0_sharing,
  output        io_r_resp_data_2_entry_brSlots_0_valid,
  output [11:0] io_r_resp_data_2_entry_brSlots_0_lower,
  output [1:0]  io_r_resp_data_2_entry_brSlots_0_tarStat,
  output [3:0]  io_r_resp_data_2_entry_tailSlot_offset,
  output        io_r_resp_data_2_entry_tailSlot_sharing,
  output        io_r_resp_data_2_entry_tailSlot_valid,
  output [19:0] io_r_resp_data_2_entry_tailSlot_lower,
  output [1:0]  io_r_resp_data_2_entry_tailSlot_tarStat,
  output [3:0]  io_r_resp_data_2_entry_pftAddr,
  output        io_r_resp_data_2_entry_carry,
  output        io_r_resp_data_2_entry_last_may_be_rvi_call,
  output        io_r_resp_data_2_entry_strong_bias_0,
  output        io_r_resp_data_2_entry_strong_bias_1,
  output [19:0] io_r_resp_data_2_tag,
  output        io_r_resp_data_3_entry_isCall,
  output        io_r_resp_data_3_entry_isRet,
  output        io_r_resp_data_3_entry_isJalr,
  output        io_r_resp_data_3_entry_valid,
  output [3:0]  io_r_resp_data_3_entry_brSlots_0_offset,
  output        io_r_resp_data_3_entry_brSlots_0_sharing,
  output        io_r_resp_data_3_entry_brSlots_0_valid,
  output [11:0] io_r_resp_data_3_entry_brSlots_0_lower,
  output [1:0]  io_r_resp_data_3_entry_brSlots_0_tarStat,
  output [3:0]  io_r_resp_data_3_entry_tailSlot_offset,
  output        io_r_resp_data_3_entry_tailSlot_sharing,
  output        io_r_resp_data_3_entry_tailSlot_valid,
  output [19:0] io_r_resp_data_3_entry_tailSlot_lower,
  output [1:0]  io_r_resp_data_3_entry_tailSlot_tarStat,
  output [3:0]  io_r_resp_data_3_entry_pftAddr,
  output        io_r_resp_data_3_entry_carry,
  output        io_r_resp_data_3_entry_last_may_be_rvi_call,
  output        io_r_resp_data_3_entry_strong_bias_0,
  output        io_r_resp_data_3_entry_strong_bias_1,
  output [19:0] io_r_resp_data_3_tag,
  input         io_w_req_valid,
  input  [8:0]  io_w_req_bits_setIdx,
  input         io_w_req_bits_data_0_entry_isCall,
  input         io_w_req_bits_data_0_entry_isRet,
  input         io_w_req_bits_data_0_entry_isJalr,
  input         io_w_req_bits_data_0_entry_valid,
  input  [3:0]  io_w_req_bits_data_0_entry_brSlots_0_offset,
  input         io_w_req_bits_data_0_entry_brSlots_0_sharing,
  input         io_w_req_bits_data_0_entry_brSlots_0_valid,
  input  [11:0] io_w_req_bits_data_0_entry_brSlots_0_lower,
  input  [1:0]  io_w_req_bits_data_0_entry_brSlots_0_tarStat,
  input  [3:0]  io_w_req_bits_data_0_entry_tailSlot_offset,
  input         io_w_req_bits_data_0_entry_tailSlot_sharing,
  input         io_w_req_bits_data_0_entry_tailSlot_valid,
  input  [19:0] io_w_req_bits_data_0_entry_tailSlot_lower,
  input  [1:0]  io_w_req_bits_data_0_entry_tailSlot_tarStat,
  input  [3:0]  io_w_req_bits_data_0_entry_pftAddr,
  input         io_w_req_bits_data_0_entry_carry,
  input         io_w_req_bits_data_0_entry_last_may_be_rvi_call,
  input         io_w_req_bits_data_0_entry_strong_bias_0,
  input         io_w_req_bits_data_0_entry_strong_bias_1,
  input  [19:0] io_w_req_bits_data_0_tag,
  input         io_w_req_bits_data_1_entry_isCall,
  input         io_w_req_bits_data_1_entry_isRet,
  input         io_w_req_bits_data_1_entry_isJalr,
  input         io_w_req_bits_data_1_entry_valid,
  input  [3:0]  io_w_req_bits_data_1_entry_brSlots_0_offset,
  input         io_w_req_bits_data_1_entry_brSlots_0_sharing,
  input         io_w_req_bits_data_1_entry_brSlots_0_valid,
  input  [11:0] io_w_req_bits_data_1_entry_brSlots_0_lower,
  input  [1:0]  io_w_req_bits_data_1_entry_brSlots_0_tarStat,
  input  [3:0]  io_w_req_bits_data_1_entry_tailSlot_offset,
  input         io_w_req_bits_data_1_entry_tailSlot_sharing,
  input         io_w_req_bits_data_1_entry_tailSlot_valid,
  input  [19:0] io_w_req_bits_data_1_entry_tailSlot_lower,
  input  [1:0]  io_w_req_bits_data_1_entry_tailSlot_tarStat,
  input  [3:0]  io_w_req_bits_data_1_entry_pftAddr,
  input         io_w_req_bits_data_1_entry_carry,
  input         io_w_req_bits_data_1_entry_last_may_be_rvi_call,
  input         io_w_req_bits_data_1_entry_strong_bias_0,
  input         io_w_req_bits_data_1_entry_strong_bias_1,
  input  [19:0] io_w_req_bits_data_1_tag,
  input         io_w_req_bits_data_2_entry_isCall,
  input         io_w_req_bits_data_2_entry_isRet,
  input         io_w_req_bits_data_2_entry_isJalr,
  input         io_w_req_bits_data_2_entry_valid,
  input  [3:0]  io_w_req_bits_data_2_entry_brSlots_0_offset,
  input         io_w_req_bits_data_2_entry_brSlots_0_sharing,
  input         io_w_req_bits_data_2_entry_brSlots_0_valid,
  input  [11:0] io_w_req_bits_data_2_entry_brSlots_0_lower,
  input  [1:0]  io_w_req_bits_data_2_entry_brSlots_0_tarStat,
  input  [3:0]  io_w_req_bits_data_2_entry_tailSlot_offset,
  input         io_w_req_bits_data_2_entry_tailSlot_sharing,
  input         io_w_req_bits_data_2_entry_tailSlot_valid,
  input  [19:0] io_w_req_bits_data_2_entry_tailSlot_lower,
  input  [1:0]  io_w_req_bits_data_2_entry_tailSlot_tarStat,
  input  [3:0]  io_w_req_bits_data_2_entry_pftAddr,
  input         io_w_req_bits_data_2_entry_carry,
  input         io_w_req_bits_data_2_entry_last_may_be_rvi_call,
  input         io_w_req_bits_data_2_entry_strong_bias_0,
  input         io_w_req_bits_data_2_entry_strong_bias_1,
  input  [19:0] io_w_req_bits_data_2_tag,
  input         io_w_req_bits_data_3_entry_isCall,
  input         io_w_req_bits_data_3_entry_isRet,
  input         io_w_req_bits_data_3_entry_isJalr,
  input         io_w_req_bits_data_3_entry_valid,
  input  [3:0]  io_w_req_bits_data_3_entry_brSlots_0_offset,
  input         io_w_req_bits_data_3_entry_brSlots_0_sharing,
  input         io_w_req_bits_data_3_entry_brSlots_0_valid,
  input  [11:0] io_w_req_bits_data_3_entry_brSlots_0_lower,
  input  [1:0]  io_w_req_bits_data_3_entry_brSlots_0_tarStat,
  input  [3:0]  io_w_req_bits_data_3_entry_tailSlot_offset,
  input         io_w_req_bits_data_3_entry_tailSlot_sharing,
  input         io_w_req_bits_data_3_entry_tailSlot_valid,
  input  [19:0] io_w_req_bits_data_3_entry_tailSlot_lower,
  input  [1:0]  io_w_req_bits_data_3_entry_tailSlot_tarStat,
  input  [3:0]  io_w_req_bits_data_3_entry_pftAddr,
  input         io_w_req_bits_data_3_entry_carry,
  input         io_w_req_bits_data_3_entry_last_may_be_rvi_call,
  input         io_w_req_bits_data_3_entry_strong_bias_0,
  input         io_w_req_bits_data_3_entry_strong_bias_1,
  input  [19:0] io_w_req_bits_data_3_tag,
  input  [3:0]  io_w_req_bits_waymask,
  input  [9:0]  boreChildrenBd_bore_addr,    input [9:0] boreChildrenBd_bore_addr_rd,
  input  [39:0] boreChildrenBd_bore_wdata,   input [3:0] boreChildrenBd_bore_wmask,
  input         boreChildrenBd_bore_re,      input boreChildrenBd_bore_we,
  output [39:0] boreChildrenBd_bore_rdata,   input boreChildrenBd_bore_ack,
  input         boreChildrenBd_bore_selectedOH, input [5:0] boreChildrenBd_bore_array,
  input  [9:0]  boreChildrenBd_bore_1_addr,  input [9:0] boreChildrenBd_bore_1_addr_rd,
  input  [39:0] boreChildrenBd_bore_1_wdata, input [3:0] boreChildrenBd_bore_1_wmask,
  input         boreChildrenBd_bore_1_re,    input boreChildrenBd_bore_1_we,
  output [39:0] boreChildrenBd_bore_1_rdata, input boreChildrenBd_bore_1_ack,
  input         boreChildrenBd_bore_1_selectedOH, input [5:0] boreChildrenBd_bore_1_array,
  input  [9:0]  boreChildrenBd_bore_2_addr,  input [9:0] boreChildrenBd_bore_2_addr_rd,
  input  [39:0] boreChildrenBd_bore_2_wdata, input [3:0] boreChildrenBd_bore_2_wmask,
  input         boreChildrenBd_bore_2_re,    input boreChildrenBd_bore_2_we,
  output [39:0] boreChildrenBd_bore_2_rdata, input boreChildrenBd_bore_2_ack,
  input         boreChildrenBd_bore_2_selectedOH, input [5:0] boreChildrenBd_bore_2_array,
  input  [9:0]  boreChildrenBd_bore_3_addr,  input [9:0] boreChildrenBd_bore_3_addr_rd,
  input  [39:0] boreChildrenBd_bore_3_wdata, input [3:0] boreChildrenBd_bore_3_wmask,
  input         boreChildrenBd_bore_3_re,    input boreChildrenBd_bore_3_we,
  output [39:0] boreChildrenBd_bore_3_rdata, input boreChildrenBd_bore_3_ack,
  input         boreChildrenBd_bore_3_selectedOH, input [5:0] boreChildrenBd_bore_3_array,
  input  [9:0]  boreChildrenBd_bore_4_addr,  input [9:0] boreChildrenBd_bore_4_addr_rd,
  input  [39:0] boreChildrenBd_bore_4_wdata, input [3:0] boreChildrenBd_bore_4_wmask,
  input         boreChildrenBd_bore_4_re,    input boreChildrenBd_bore_4_we,
  output [39:0] boreChildrenBd_bore_4_rdata, input boreChildrenBd_bore_4_ack,
  input         boreChildrenBd_bore_4_selectedOH, input [5:0] boreChildrenBd_bore_4_array,
  input  [9:0]  boreChildrenBd_bore_5_addr,  input [9:0] boreChildrenBd_bore_5_addr_rd,
  input  [39:0] boreChildrenBd_bore_5_wdata, input [3:0] boreChildrenBd_bore_5_wmask,
  input         boreChildrenBd_bore_5_re,    input boreChildrenBd_bore_5_we,
  output [39:0] boreChildrenBd_bore_5_rdata, input boreChildrenBd_bore_5_ack,
  input         boreChildrenBd_bore_5_selectedOH, input [5:0] boreChildrenBd_bore_5_array,
  input  [9:0]  boreChildrenBd_bore_6_addr,  input [9:0] boreChildrenBd_bore_6_addr_rd,
  input  [39:0] boreChildrenBd_bore_6_wdata, input [3:0] boreChildrenBd_bore_6_wmask,
  input         boreChildrenBd_bore_6_re,    input boreChildrenBd_bore_6_we,
  output [39:0] boreChildrenBd_bore_6_rdata, input boreChildrenBd_bore_6_ack,
  input         boreChildrenBd_bore_6_selectedOH, input [5:0] boreChildrenBd_bore_6_array,
  input  [9:0]  boreChildrenBd_bore_7_addr,  input [9:0] boreChildrenBd_bore_7_addr_rd,
  input  [39:0] boreChildrenBd_bore_7_wdata, input [3:0] boreChildrenBd_bore_7_wmask,
  input         boreChildrenBd_bore_7_re,    input boreChildrenBd_bore_7_we,
  output [39:0] boreChildrenBd_bore_7_rdata, input boreChildrenBd_bore_7_ack,
  input         boreChildrenBd_bore_7_selectedOH, input [5:0] boreChildrenBd_bore_7_array,
  input         sigFromSrams_bore_ram_hold,   input sigFromSrams_bore_ram_bypass,
  input         sigFromSrams_bore_ram_bp_clken, input sigFromSrams_bore_ram_aux_clk,
  input         sigFromSrams_bore_ram_aux_ckbp, input sigFromSrams_bore_ram_mcp_hold,
  input         sigFromSrams_bore_cgen,
  input         sigFromSrams_bore_1_ram_hold,   input sigFromSrams_bore_1_ram_bypass,
  input         sigFromSrams_bore_1_ram_bp_clken, input sigFromSrams_bore_1_ram_aux_clk,
  input         sigFromSrams_bore_1_ram_aux_ckbp, input sigFromSrams_bore_1_ram_mcp_hold,
  input         sigFromSrams_bore_1_cgen,
  input         sigFromSrams_bore_2_ram_hold,   input sigFromSrams_bore_2_ram_bypass,
  input         sigFromSrams_bore_2_ram_bp_clken, input sigFromSrams_bore_2_ram_aux_clk,
  input         sigFromSrams_bore_2_ram_aux_ckbp, input sigFromSrams_bore_2_ram_mcp_hold,
  input         sigFromSrams_bore_2_cgen,
  input         sigFromSrams_bore_3_ram_hold,   input sigFromSrams_bore_3_ram_bypass,
  input         sigFromSrams_bore_3_ram_bp_clken, input sigFromSrams_bore_3_ram_aux_clk,
  input         sigFromSrams_bore_3_ram_aux_ckbp, input sigFromSrams_bore_3_ram_mcp_hold,
  input         sigFromSrams_bore_3_cgen,
  input         sigFromSrams_bore_4_ram_hold,   input sigFromSrams_bore_4_ram_bypass,
  input         sigFromSrams_bore_4_ram_bp_clken, input sigFromSrams_bore_4_ram_aux_clk,
  input         sigFromSrams_bore_4_ram_aux_ckbp, input sigFromSrams_bore_4_ram_mcp_hold,
  input         sigFromSrams_bore_4_cgen,
  input         sigFromSrams_bore_5_ram_hold,   input sigFromSrams_bore_5_ram_bypass,
  input         sigFromSrams_bore_5_ram_bp_clken, input sigFromSrams_bore_5_ram_aux_clk,
  input         sigFromSrams_bore_5_ram_aux_ckbp, input sigFromSrams_bore_5_ram_mcp_hold,
  input         sigFromSrams_bore_5_cgen,
  input         sigFromSrams_bore_6_ram_hold,   input sigFromSrams_bore_6_ram_bypass,
  input         sigFromSrams_bore_6_ram_bp_clken, input sigFromSrams_bore_6_ram_aux_clk,
  input         sigFromSrams_bore_6_ram_aux_ckbp, input sigFromSrams_bore_6_ram_mcp_hold,
  input         sigFromSrams_bore_6_cgen,
  input         sigFromSrams_bore_7_ram_hold,   input sigFromSrams_bore_7_ram_bypass,
  input         sigFromSrams_bore_7_ram_bp_clken, input sigFromSrams_bore_7_ram_aux_clk,
  input         sigFromSrams_bore_7_ram_aux_ckbp, input sigFromSrams_bore_7_ram_mcp_hold,
  input         sigFromSrams_bore_7_cgen
);
  localparam int N_SPLIT = 8;    // dataSplit
  localparam int CHUNK_W = 10;   // 每切片位宽
  localparam int WORD_W  = 80;   // 每路物理打包字宽 = N_SPLIT*CHUNK_W

  // ---- 写：把每路 struct 铺成 80 位物理字（chunk i = bits [10*i+9:10*i]）----
  // 用 function 把单路所有字段拼成 80 位，顺序见模块头注释。
  function automatic [WORD_W-1:0] pack_way(
    input        isCall, input isRet, input isJalr, input e_valid,
    input [3:0]  br_offset, input br_sharing, input br_valid,
    input [11:0] br_lower,  input [1:0] br_tarStat,
    input [3:0]  tl_offset, input tl_sharing, input tl_valid,
    input [19:0] tl_lower,  input [1:0] tl_tarStat,
    input [3:0]  pftAddr,   input carry, input last_rvi_call,
    input        sb0, input sb1, input [19:0] tag
  );
    pack_way = {
      // chunk7 [79:70]
      isCall, isRet, isJalr, e_valid, br_offset, br_sharing, br_valid,
      // chunk6 [69:60]
      br_lower[11:2],
      // chunk5 [59:50]
      br_lower[1:0], br_tarStat, tl_offset, tl_sharing, tl_valid,
      // chunk4 [49:40]
      tl_lower[19:10],
      // chunk3 [39:30]
      tl_lower[9:0],
      // chunk2 [29:20]
      tl_tarStat, pftAddr, carry, last_rvi_call, sb1, sb0,
      // chunk1 [19:10]
      tag[19:10],
      // chunk0 [9:0]
      tag[9:0]
    };
  endfunction

  wire [WORD_W-1:0] w_word [4];
  assign w_word[0] = pack_way(
    io_w_req_bits_data_0_entry_isCall, io_w_req_bits_data_0_entry_isRet,
    io_w_req_bits_data_0_entry_isJalr, io_w_req_bits_data_0_entry_valid,
    io_w_req_bits_data_0_entry_brSlots_0_offset, io_w_req_bits_data_0_entry_brSlots_0_sharing,
    io_w_req_bits_data_0_entry_brSlots_0_valid, io_w_req_bits_data_0_entry_brSlots_0_lower,
    io_w_req_bits_data_0_entry_brSlots_0_tarStat,
    io_w_req_bits_data_0_entry_tailSlot_offset, io_w_req_bits_data_0_entry_tailSlot_sharing,
    io_w_req_bits_data_0_entry_tailSlot_valid, io_w_req_bits_data_0_entry_tailSlot_lower,
    io_w_req_bits_data_0_entry_tailSlot_tarStat,
    io_w_req_bits_data_0_entry_pftAddr, io_w_req_bits_data_0_entry_carry,
    io_w_req_bits_data_0_entry_last_may_be_rvi_call,
    io_w_req_bits_data_0_entry_strong_bias_0, io_w_req_bits_data_0_entry_strong_bias_1,
    io_w_req_bits_data_0_tag);
  assign w_word[1] = pack_way(
    io_w_req_bits_data_1_entry_isCall, io_w_req_bits_data_1_entry_isRet,
    io_w_req_bits_data_1_entry_isJalr, io_w_req_bits_data_1_entry_valid,
    io_w_req_bits_data_1_entry_brSlots_0_offset, io_w_req_bits_data_1_entry_brSlots_0_sharing,
    io_w_req_bits_data_1_entry_brSlots_0_valid, io_w_req_bits_data_1_entry_brSlots_0_lower,
    io_w_req_bits_data_1_entry_brSlots_0_tarStat,
    io_w_req_bits_data_1_entry_tailSlot_offset, io_w_req_bits_data_1_entry_tailSlot_sharing,
    io_w_req_bits_data_1_entry_tailSlot_valid, io_w_req_bits_data_1_entry_tailSlot_lower,
    io_w_req_bits_data_1_entry_tailSlot_tarStat,
    io_w_req_bits_data_1_entry_pftAddr, io_w_req_bits_data_1_entry_carry,
    io_w_req_bits_data_1_entry_last_may_be_rvi_call,
    io_w_req_bits_data_1_entry_strong_bias_0, io_w_req_bits_data_1_entry_strong_bias_1,
    io_w_req_bits_data_1_tag);
  assign w_word[2] = pack_way(
    io_w_req_bits_data_2_entry_isCall, io_w_req_bits_data_2_entry_isRet,
    io_w_req_bits_data_2_entry_isJalr, io_w_req_bits_data_2_entry_valid,
    io_w_req_bits_data_2_entry_brSlots_0_offset, io_w_req_bits_data_2_entry_brSlots_0_sharing,
    io_w_req_bits_data_2_entry_brSlots_0_valid, io_w_req_bits_data_2_entry_brSlots_0_lower,
    io_w_req_bits_data_2_entry_brSlots_0_tarStat,
    io_w_req_bits_data_2_entry_tailSlot_offset, io_w_req_bits_data_2_entry_tailSlot_sharing,
    io_w_req_bits_data_2_entry_tailSlot_valid, io_w_req_bits_data_2_entry_tailSlot_lower,
    io_w_req_bits_data_2_entry_tailSlot_tarStat,
    io_w_req_bits_data_2_entry_pftAddr, io_w_req_bits_data_2_entry_carry,
    io_w_req_bits_data_2_entry_last_may_be_rvi_call,
    io_w_req_bits_data_2_entry_strong_bias_0, io_w_req_bits_data_2_entry_strong_bias_1,
    io_w_req_bits_data_2_tag);
  assign w_word[3] = pack_way(
    io_w_req_bits_data_3_entry_isCall, io_w_req_bits_data_3_entry_isRet,
    io_w_req_bits_data_3_entry_isJalr, io_w_req_bits_data_3_entry_valid,
    io_w_req_bits_data_3_entry_brSlots_0_offset, io_w_req_bits_data_3_entry_brSlots_0_sharing,
    io_w_req_bits_data_3_entry_brSlots_0_valid, io_w_req_bits_data_3_entry_brSlots_0_lower,
    io_w_req_bits_data_3_entry_brSlots_0_tarStat,
    io_w_req_bits_data_3_entry_tailSlot_offset, io_w_req_bits_data_3_entry_tailSlot_sharing,
    io_w_req_bits_data_3_entry_tailSlot_valid, io_w_req_bits_data_3_entry_tailSlot_lower,
    io_w_req_bits_data_3_entry_tailSlot_tarStat,
    io_w_req_bits_data_3_entry_pftAddr, io_w_req_bits_data_3_entry_carry,
    io_w_req_bits_data_3_entry_last_may_be_rvi_call,
    io_w_req_bits_data_3_entry_strong_bias_0, io_w_req_bits_data_3_entry_strong_bias_1,
    io_w_req_bits_data_3_tag);

  // 读出切片：rd_chunk[split][way] = 该内层第 way 路读出的 10 位
  wire [CHUNK_W-1:0] rd_chunk [N_SPLIT][4];

  // ---- 把各 bore/broadcast 信号收成数组，便于 genvar 例化 8 个内层 ----
  wire [9:0]  bore_addr   [N_SPLIT], bore_addr_rd [N_SPLIT];
  wire [39:0] bore_wdata  [N_SPLIT];
  wire [3:0]  bore_wmask  [N_SPLIT];
  wire        bore_re     [N_SPLIT], bore_we [N_SPLIT], bore_ack [N_SPLIT], bore_sel [N_SPLIT];
  wire [5:0]  bore_array  [N_SPLIT];
  wire [39:0] bore_rdata  [N_SPLIT];
  wire        bc_hold[N_SPLIT], bc_bypass[N_SPLIT], bc_bpclken[N_SPLIT];
  wire        bc_auxclk[N_SPLIT], bc_auxckbp[N_SPLIT], bc_mcphold[N_SPLIT], bc_cgen[N_SPLIT];

  `define BIND_BORE(I, S) \
    assign bore_addr[I]=boreChildrenBd_``S``_addr;       assign bore_addr_rd[I]=boreChildrenBd_``S``_addr_rd; \
    assign bore_wdata[I]=boreChildrenBd_``S``_wdata;     assign bore_wmask[I]=boreChildrenBd_``S``_wmask; \
    assign bore_re[I]=boreChildrenBd_``S``_re;           assign bore_we[I]=boreChildrenBd_``S``_we; \
    assign bore_ack[I]=boreChildrenBd_``S``_ack;         assign bore_sel[I]=boreChildrenBd_``S``_selectedOH; \
    assign bore_array[I]=boreChildrenBd_``S``_array;     assign boreChildrenBd_``S``_rdata=bore_rdata[I]; \
    assign bc_hold[I]=sigFromSrams_``S``_ram_hold;       assign bc_bypass[I]=sigFromSrams_``S``_ram_bypass; \
    assign bc_bpclken[I]=sigFromSrams_``S``_ram_bp_clken;assign bc_auxclk[I]=sigFromSrams_``S``_ram_aux_clk; \
    assign bc_auxckbp[I]=sigFromSrams_``S``_ram_aux_ckbp;assign bc_mcphold[I]=sigFromSrams_``S``_ram_mcp_hold; \
    assign bc_cgen[I]=sigFromSrams_``S``_cgen;
  `BIND_BORE(0, bore)
  `BIND_BORE(1, bore_1)
  `BIND_BORE(2, bore_2)
  `BIND_BORE(3, bore_3)
  `BIND_BORE(4, bore_4)
  `BIND_BORE(5, bore_5)
  `BIND_BORE(6, bore_6)
  `BIND_BORE(7, bore_7)
  `undef BIND_BORE

  // io_r_req_ready 只从第 0 个内层引出（各内层 ready 一致）
  wire [N_SPLIT-1:0] inner_ready;
  assign io_r_req_ready = inner_ready[0];

  // ---- 8 个内层 SRAMTemplate_36（512×4×10），每个存一个 10 位切片 ----
  genvar s;
  generate
    for (s = 0; s < N_SPLIT; s++) begin : g_split
      SRAMTemplate_36 array_inst (
        .clock(clock), .reset(reset),
        .io_r_req_ready(inner_ready[s]),
        .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
        .io_r_resp_data_0(rd_chunk[s][0]), .io_r_resp_data_1(rd_chunk[s][1]),
        .io_r_resp_data_2(rd_chunk[s][2]), .io_r_resp_data_3(rd_chunk[s][3]),
        .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
        // 每路取本切片对应的 10 位
        .io_w_req_bits_data_0(w_word[0][s*CHUNK_W +: CHUNK_W]),
        .io_w_req_bits_data_1(w_word[1][s*CHUNK_W +: CHUNK_W]),
        .io_w_req_bits_data_2(w_word[2][s*CHUNK_W +: CHUNK_W]),
        .io_w_req_bits_data_3(w_word[3][s*CHUNK_W +: CHUNK_W]),
        .io_w_req_bits_waymask(io_w_req_bits_waymask),
        .io_broadcast_ram_hold(bc_hold[s]), .io_broadcast_ram_bypass(bc_bypass[s]),
        .io_broadcast_ram_bp_clken(bc_bpclken[s]), .io_broadcast_ram_aux_clk(bc_auxclk[s]),
        .io_broadcast_ram_aux_ckbp(bc_auxckbp[s]), .io_broadcast_ram_mcp_hold(bc_mcphold[s]),
        .io_broadcast_ram_ctl(64'h0), .io_broadcast_cgen(bc_cgen[s]),
        .boreChildrenBd_bore_addr(bore_addr[s]), .boreChildrenBd_bore_addr_rd(bore_addr_rd[s]),
        .boreChildrenBd_bore_wdata(bore_wdata[s]), .boreChildrenBd_bore_wmask(bore_wmask[s]),
        .boreChildrenBd_bore_re(bore_re[s]), .boreChildrenBd_bore_we(bore_we[s]),
        .boreChildrenBd_bore_rdata(bore_rdata[s]), .boreChildrenBd_bore_ack(bore_ack[s]),
        .boreChildrenBd_bore_selectedOH(bore_sel[s]), .boreChildrenBd_bore_array(bore_array[s])
      );
    end
  endgenerate

  // ---- 读：把每路 8 个切片拼回 80 位字，再拆 struct（拆位序见模块头）----
  wire [WORD_W-1:0] r_word [4];
  generate
    for (s = 0; s < N_SPLIT; s++) begin : g_rword
      assign r_word[0][s*CHUNK_W +: CHUNK_W] = rd_chunk[s][0];
      assign r_word[1][s*CHUNK_W +: CHUNK_W] = rd_chunk[s][1];
      assign r_word[2][s*CHUNK_W +: CHUNK_W] = rd_chunk[s][2];
      assign r_word[3][s*CHUNK_W +: CHUNK_W] = rd_chunk[s][3];
    end
  endgenerate

  // 解包 way0
  assign io_r_resp_data_0_entry_isCall               = r_word[0][79];
  assign io_r_resp_data_0_entry_isRet                = r_word[0][78];
  assign io_r_resp_data_0_entry_isJalr               = r_word[0][77];
  assign io_r_resp_data_0_entry_valid                = r_word[0][76];
  assign io_r_resp_data_0_entry_brSlots_0_offset     = r_word[0][75:72];
  assign io_r_resp_data_0_entry_brSlots_0_sharing    = r_word[0][71];
  assign io_r_resp_data_0_entry_brSlots_0_valid      = r_word[0][70];
  assign io_r_resp_data_0_entry_brSlots_0_lower      = r_word[0][69:58];
  assign io_r_resp_data_0_entry_brSlots_0_tarStat    = r_word[0][57:56];
  assign io_r_resp_data_0_entry_tailSlot_offset      = r_word[0][55:52];
  assign io_r_resp_data_0_entry_tailSlot_sharing     = r_word[0][51];
  assign io_r_resp_data_0_entry_tailSlot_valid       = r_word[0][50];
  assign io_r_resp_data_0_entry_tailSlot_lower       = r_word[0][49:30];
  assign io_r_resp_data_0_entry_tailSlot_tarStat     = r_word[0][29:28];
  assign io_r_resp_data_0_entry_pftAddr              = r_word[0][27:24];
  assign io_r_resp_data_0_entry_carry                = r_word[0][23];
  assign io_r_resp_data_0_entry_last_may_be_rvi_call = r_word[0][22];
  assign io_r_resp_data_0_entry_strong_bias_1        = r_word[0][21];
  assign io_r_resp_data_0_entry_strong_bias_0        = r_word[0][20];
  assign io_r_resp_data_0_tag                        = r_word[0][19:0];
  // 解包 way1
  assign io_r_resp_data_1_entry_isCall               = r_word[1][79];
  assign io_r_resp_data_1_entry_isRet                = r_word[1][78];
  assign io_r_resp_data_1_entry_isJalr               = r_word[1][77];
  assign io_r_resp_data_1_entry_valid                = r_word[1][76];
  assign io_r_resp_data_1_entry_brSlots_0_offset     = r_word[1][75:72];
  assign io_r_resp_data_1_entry_brSlots_0_sharing    = r_word[1][71];
  assign io_r_resp_data_1_entry_brSlots_0_valid      = r_word[1][70];
  assign io_r_resp_data_1_entry_brSlots_0_lower      = r_word[1][69:58];
  assign io_r_resp_data_1_entry_brSlots_0_tarStat    = r_word[1][57:56];
  assign io_r_resp_data_1_entry_tailSlot_offset      = r_word[1][55:52];
  assign io_r_resp_data_1_entry_tailSlot_sharing     = r_word[1][51];
  assign io_r_resp_data_1_entry_tailSlot_valid       = r_word[1][50];
  assign io_r_resp_data_1_entry_tailSlot_lower       = r_word[1][49:30];
  assign io_r_resp_data_1_entry_tailSlot_tarStat     = r_word[1][29:28];
  assign io_r_resp_data_1_entry_pftAddr              = r_word[1][27:24];
  assign io_r_resp_data_1_entry_carry                = r_word[1][23];
  assign io_r_resp_data_1_entry_last_may_be_rvi_call = r_word[1][22];
  assign io_r_resp_data_1_entry_strong_bias_1        = r_word[1][21];
  assign io_r_resp_data_1_entry_strong_bias_0        = r_word[1][20];
  assign io_r_resp_data_1_tag                        = r_word[1][19:0];
  // 解包 way2
  assign io_r_resp_data_2_entry_isCall               = r_word[2][79];
  assign io_r_resp_data_2_entry_isRet                = r_word[2][78];
  assign io_r_resp_data_2_entry_isJalr               = r_word[2][77];
  assign io_r_resp_data_2_entry_valid                = r_word[2][76];
  assign io_r_resp_data_2_entry_brSlots_0_offset     = r_word[2][75:72];
  assign io_r_resp_data_2_entry_brSlots_0_sharing    = r_word[2][71];
  assign io_r_resp_data_2_entry_brSlots_0_valid      = r_word[2][70];
  assign io_r_resp_data_2_entry_brSlots_0_lower      = r_word[2][69:58];
  assign io_r_resp_data_2_entry_brSlots_0_tarStat    = r_word[2][57:56];
  assign io_r_resp_data_2_entry_tailSlot_offset      = r_word[2][55:52];
  assign io_r_resp_data_2_entry_tailSlot_sharing     = r_word[2][51];
  assign io_r_resp_data_2_entry_tailSlot_valid       = r_word[2][50];
  assign io_r_resp_data_2_entry_tailSlot_lower       = r_word[2][49:30];
  assign io_r_resp_data_2_entry_tailSlot_tarStat     = r_word[2][29:28];
  assign io_r_resp_data_2_entry_pftAddr              = r_word[2][27:24];
  assign io_r_resp_data_2_entry_carry                = r_word[2][23];
  assign io_r_resp_data_2_entry_last_may_be_rvi_call = r_word[2][22];
  assign io_r_resp_data_2_entry_strong_bias_1        = r_word[2][21];
  assign io_r_resp_data_2_entry_strong_bias_0        = r_word[2][20];
  assign io_r_resp_data_2_tag                        = r_word[2][19:0];
  // 解包 way3
  assign io_r_resp_data_3_entry_isCall               = r_word[3][79];
  assign io_r_resp_data_3_entry_isRet                = r_word[3][78];
  assign io_r_resp_data_3_entry_isJalr               = r_word[3][77];
  assign io_r_resp_data_3_entry_valid                = r_word[3][76];
  assign io_r_resp_data_3_entry_brSlots_0_offset     = r_word[3][75:72];
  assign io_r_resp_data_3_entry_brSlots_0_sharing    = r_word[3][71];
  assign io_r_resp_data_3_entry_brSlots_0_valid      = r_word[3][70];
  assign io_r_resp_data_3_entry_brSlots_0_lower      = r_word[3][69:58];
  assign io_r_resp_data_3_entry_brSlots_0_tarStat    = r_word[3][57:56];
  assign io_r_resp_data_3_entry_tailSlot_offset      = r_word[3][55:52];
  assign io_r_resp_data_3_entry_tailSlot_sharing     = r_word[3][51];
  assign io_r_resp_data_3_entry_tailSlot_valid       = r_word[3][50];
  assign io_r_resp_data_3_entry_tailSlot_lower       = r_word[3][49:30];
  assign io_r_resp_data_3_entry_tailSlot_tarStat     = r_word[3][29:28];
  assign io_r_resp_data_3_entry_pftAddr              = r_word[3][27:24];
  assign io_r_resp_data_3_entry_carry                = r_word[3][23];
  assign io_r_resp_data_3_entry_last_may_be_rvi_call = r_word[3][22];
  assign io_r_resp_data_3_entry_strong_bias_1        = r_word[3][21];
  assign io_r_resp_data_3_entry_strong_bias_0        = r_word[3][20];
  assign io_r_resp_data_3_tag                        = r_word[3][19:0];
endmodule
