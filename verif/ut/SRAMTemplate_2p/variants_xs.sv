// 双端口 SRAM 变体包装层（UT impl 用，_xs 名）：与 rtl/common/SRAMTemplate_2p_variants.sv
// 同体，仅模块名加 _xs 后缀，供 tb 与 golden 双例化逐拍比对。
module SRAMTemplate_66_xs(
  input         clock,
  input         reset,
  input         io_r_req_valid,
  input  [7:0]  io_r_req_bits_setIdx,
  output [5:0]  io_r_resp_data_0,
  output [5:0]  io_r_resp_data_1,
  output [5:0]  io_r_resp_data_2,
  output [5:0]  io_r_resp_data_3,
  input         io_w_req_valid,
  input  [7:0]  io_w_req_bits_setIdx,
  input  [5:0]  io_w_req_bits_data_0,
  input  [5:0]  io_w_req_bits_data_1,
  input  [5:0]  io_w_req_bits_data_2,
  input  [5:0]  io_w_req_bits_data_3,
  input  [3:0]  io_w_req_bits_waymask,
  input         io_broadcast_ram_hold,
  input         io_broadcast_ram_bypass,
  input         io_broadcast_ram_bp_clken,
  input         io_broadcast_ram_aux_clk,
  input         io_broadcast_ram_aux_ckbp,
  input         io_broadcast_ram_mcp_hold,
  input  [63:0] io_broadcast_ram_ctl,
  input         io_broadcast_cgen,
  input  [8:0]  boreChildrenBd_bore_addr,
  input  [8:0]  boreChildrenBd_bore_addr_rd,
  input  [23:0] boreChildrenBd_bore_wdata,
  input  [3:0]  boreChildrenBd_bore_wmask,
  input         boreChildrenBd_bore_re,
  input         boreChildrenBd_bore_we,
  output [23:0] boreChildrenBd_bore_rdata,
  input         boreChildrenBd_bore_ack,
  input         boreChildrenBd_bore_selectedOH,
  input  [6:0]  boreChildrenBd_bore_array
);
  wire        r_clk, r_en, w_clk, w_en, ram_bypass, ram_bp_clken;
  wire [7:0]  r_addr, w_addr;
  wire [23:0] r_data, w_data;
  wire [3:0]  w_mask;
  xs_SRAMTemplate_2p_core #(.SET(256), .WAY(4), .DATA_WIDTH(6), .BORE_AW(9)) u_core (
    .clock(clock), .reset(reset),
    .io_r_req_ready(/*open*/),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data({io_r_resp_data_3, io_r_resp_data_2, io_r_resp_data_1, io_r_resp_data_0}),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data({io_w_req_bits_data_3, io_w_req_bits_data_2, io_w_req_bits_data_1, io_w_req_bits_data_0}),
    .io_w_req_bits_waymask(io_w_req_bits_waymask),
    .io_broadcast_ram_hold(io_broadcast_ram_hold),
    .io_broadcast_ram_bypass(io_broadcast_ram_bypass),
    .io_broadcast_ram_bp_clken(io_broadcast_ram_bp_clken),
    .io_broadcast_cgen(io_broadcast_cgen),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(boreChildrenBd_bore_selectedOH),
    .ram_bypass(ram_bypass), .ram_bp_clken(ram_bp_clken),
    .r_clk(r_clk), .r_addr(r_addr), .r_en(r_en), .r_data(r_data),
    .w_clk(w_clk), .w_addr(w_addr), .w_en(w_en), .w_data(w_data), .w_mask(w_mask)
  );
  sram_array_2p256x24m6s1h0l1b_bp_sc array (
    .mbist_dft_ram_bypass(ram_bypass), .mbist_dft_ram_bp_clken(ram_bp_clken),
    .R0_clk(r_clk), .R0_addr(r_addr), .R0_en(r_en), .R0_data(r_data),
    .W0_clk(w_clk), .W0_addr(w_addr), .W0_en(w_en), .W0_data(w_data), .W0_mask(w_mask)
  );
endmodule
