module SplittedSRAMTemplate_4_xs(
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
  // 每路 12 位 = {valid, tag[7:0], ctr[2:0]}
  wire [11:0] inner_rdata_0, inner_rdata_1;
  SRAMTemplate_45 array_0_0_0 (
    .clock(clock), .reset(reset),
    .io_r_req_ready(io_r_req_ready),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data_0(inner_rdata_0), .io_r_resp_data_1(inner_rdata_1),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data_0({1'h1, io_w_req_bits_data_0_tag, io_w_req_bits_data_0_ctr}),
    .io_w_req_bits_data_1({1'h1, io_w_req_bits_data_1_tag, io_w_req_bits_data_1_ctr}),
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
  assign io_r_resp_data_0_valid = inner_rdata_0[11];
  assign io_r_resp_data_0_tag   = inner_rdata_0[10:3];
  assign io_r_resp_data_0_ctr   = inner_rdata_0[2:0];
  assign io_r_resp_data_1_valid = inner_rdata_1[11];
  assign io_r_resp_data_1_tag   = inner_rdata_1[10:3];
  assign io_r_resp_data_1_ctr   = inner_rdata_1[2:0];
endmodule
