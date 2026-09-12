// SplittedSRAMTemplate_25 —— SplittedSRAMTemplate 家族变体
// 家族共性（结构原理、保持逻辑、与内层的关系）见 SplittedSRAMTemplate.sv 文件头；
// 本文件只放本变体的参数与端口。
// G1 重编号: 上轮名 SplittedSRAMTemplate_24 → 本轮 SplittedSRAMTemplate_25（含其例化的内层名同步改）

module SplittedSRAMTemplate_25(
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

  SRAMTemplate_76 array_0_0_0 (
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
// SplittedSRAMTemplate_27 —— ITTAGE 表：dataSplit=2 + 逐位写掩码 + 双 bore
//
// 逻辑 128set×4way×38b（同 _24 的 ITTAGE 条目，但 4 路）。这里 dataSplit=2：
// 把每路 38 位条目「沿数据维」切成两半，各 19 位，分别存进两个 SRAMTemplate_78
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
