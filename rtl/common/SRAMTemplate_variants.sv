// 自动生成：scripts/gen_sram_wrappers.py —— 勿手改
// 变体包装层：例化 xs_SRAMTemplate_core + 厂商 SRAM 宏黑盒
module SRAMTemplate(
  input  clock,
  input  reset,
  output io_r_req_ready,
  input  io_r_req_valid,
  input  [6:0] io_r_req_bits_setIdx,
  output [36:0] io_r_resp_data_0,
  output [36:0] io_r_resp_data_1,
  input  io_w_req_valid,
  input  [6:0] io_w_req_bits_setIdx,
  input  [36:0] io_w_req_bits_data_0,
  input  [36:0] io_w_req_bits_data_1,
  input  [1:0] io_w_req_bits_waymask,
  input  io_broadcast_ram_hold,
  input  io_broadcast_ram_bypass,
  input  io_broadcast_ram_bp_clken,
  input  io_broadcast_ram_aux_clk,
  input  io_broadcast_ram_aux_ckbp,
  input  io_broadcast_ram_mcp_hold,
  input  [63:0] io_broadcast_ram_ctl,
  input  io_broadcast_cgen,
  input  [7:0] boreChildrenBd_bore_addr,
  input  [7:0] boreChildrenBd_bore_addr_rd,
  input  [73:0] boreChildrenBd_bore_wdata,
  input  [1:0] boreChildrenBd_bore_wmask,
  input  boreChildrenBd_bore_re,
  input  boreChildrenBd_bore_we,
  output [73:0] boreChildrenBd_bore_rdata,
  input  boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_selectedOH,
  input  boreChildrenBd_bore_array
);
  wire        ram_clk, ram_bypass, ram_bp_clken, ram_en, ram_wmode;
  wire [6:0]  ram_addr;
  wire [1:0]  ram_wmask;
  wire [73:0] ram_wdata, ram_rdata;
  xs_SRAMTemplate_core #(
    .SET(128), .WAY(2), .DATA_WIDTH(37), .BORE_AW(8),
    .ENABLE_RESET(1), .ENABLE_HOLDREAD(1),
    .ENABLE_CLOCKGATE(1), .EXTRA_RESET(0),
    .USE_BITMASK(0)
  ) u_core (
    .clock(clock), .reset(reset), .io_extra_reset(1'b0),
    .io_r_req_ready(io_r_req_ready),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data({io_r_resp_data_1, io_r_resp_data_0}),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data({io_w_req_bits_data_1, io_w_req_bits_data_0}), .io_w_mask(io_w_req_bits_waymask),
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
    .ram_clk(ram_clk), .ram_bypass(ram_bypass), .ram_bp_clken(ram_bp_clken),
    .ram_addr(ram_addr), .ram_en(ram_en), .ram_wmode(ram_wmode),
    .ram_wmask(ram_wmask), .ram_wdata(ram_wdata), .ram_rdata(ram_rdata)
  );
  sram_array_1p128x74m37s1h0l1b_icsh_tag array (
    .mbist_dft_ram_bypass(ram_bypass), .mbist_dft_ram_bp_clken(ram_bp_clken),
    .RW0_clk(ram_clk), .RW0_addr(ram_addr), .RW0_en(ram_en), .RW0_wmode(ram_wmode),
    .RW0_wmask(ram_wmask),
    .RW0_wdata(ram_wdata), .RW0_rdata(ram_rdata)
  );
endmodule

module SRAMTemplate_2(
  input  clock,
  input  reset,
  output io_r_req_ready,
  input  io_r_req_valid,
  input  [6:0] io_r_req_bits_setIdx,
  output [36:0] io_r_resp_data_0,
  output [36:0] io_r_resp_data_1,
  input  io_w_req_valid,
  input  [6:0] io_w_req_bits_setIdx,
  input  [36:0] io_w_req_bits_data_0,
  input  [36:0] io_w_req_bits_data_1,
  input  [1:0] io_w_req_bits_waymask,
  input  io_broadcast_ram_hold,
  input  io_broadcast_ram_bypass,
  input  io_broadcast_ram_bp_clken,
  input  io_broadcast_ram_aux_clk,
  input  io_broadcast_ram_aux_ckbp,
  input  io_broadcast_ram_mcp_hold,
  input  [63:0] io_broadcast_ram_ctl,
  input  io_broadcast_cgen,
  input  [7:0] boreChildrenBd_bore_addr,
  input  [7:0] boreChildrenBd_bore_addr_rd,
  input  [73:0] boreChildrenBd_bore_wdata,
  input  [1:0] boreChildrenBd_bore_wmask,
  input  boreChildrenBd_bore_re,
  input  boreChildrenBd_bore_we,
  output [73:0] boreChildrenBd_bore_rdata,
  input  boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_selectedOH,
  input  [1:0] boreChildrenBd_bore_array
);
  wire        ram_clk, ram_bypass, ram_bp_clken, ram_en, ram_wmode;
  wire [6:0]  ram_addr;
  wire [1:0]  ram_wmask;
  wire [73:0] ram_wdata, ram_rdata;
  xs_SRAMTemplate_core #(
    .SET(128), .WAY(2), .DATA_WIDTH(37), .BORE_AW(8),
    .ENABLE_RESET(1), .ENABLE_HOLDREAD(1),
    .ENABLE_CLOCKGATE(1), .EXTRA_RESET(0),
    .USE_BITMASK(0)
  ) u_core (
    .clock(clock), .reset(reset), .io_extra_reset(1'b0),
    .io_r_req_ready(io_r_req_ready),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data({io_r_resp_data_1, io_r_resp_data_0}),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data({io_w_req_bits_data_1, io_w_req_bits_data_0}), .io_w_mask(io_w_req_bits_waymask),
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
    .ram_clk(ram_clk), .ram_bypass(ram_bypass), .ram_bp_clken(ram_bp_clken),
    .ram_addr(ram_addr), .ram_en(ram_en), .ram_wmode(ram_wmode),
    .ram_wmask(ram_wmask), .ram_wdata(ram_wdata), .ram_rdata(ram_rdata)
  );
  sram_array_1p128x74m37s1h0l1b_icsh_tag array (
    .mbist_dft_ram_bypass(ram_bypass), .mbist_dft_ram_bp_clken(ram_bp_clken),
    .RW0_clk(ram_clk), .RW0_addr(ram_addr), .RW0_en(ram_en), .RW0_wmode(ram_wmode),
    .RW0_wmask(ram_wmask),
    .RW0_wdata(ram_wdata), .RW0_rdata(ram_rdata)
  );
endmodule

module SRAMTemplate_4(
  input  clock,
  input  reset,
  input  io_r_req_valid,
  input  [7:0] io_r_req_bits_setIdx,
  output [65:0] io_r_resp_data_0,
  input  io_w_req_valid,
  input  [7:0] io_w_req_bits_setIdx,
  input  [65:0] io_w_req_bits_data_0,
  input  io_broadcast_ram_hold,
  input  io_broadcast_ram_bypass,
  input  io_broadcast_ram_bp_clken,
  input  io_broadcast_ram_aux_clk,
  input  io_broadcast_ram_aux_ckbp,
  input  io_broadcast_ram_mcp_hold,
  input  [63:0] io_broadcast_ram_ctl,
  input  io_broadcast_cgen,
  input  [8:0] boreChildrenBd_bore_addr,
  input  [8:0] boreChildrenBd_bore_addr_rd,
  input  [65:0] boreChildrenBd_bore_wdata,
  input  boreChildrenBd_bore_wmask,
  input  boreChildrenBd_bore_re,
  input  boreChildrenBd_bore_we,
  output [65:0] boreChildrenBd_bore_rdata,
  input  boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_selectedOH,
  input  [2:0] boreChildrenBd_bore_array
);
  wire        ram_clk, ram_bypass, ram_bp_clken, ram_en, ram_wmode;
  wire [7:0]  ram_addr;
  wire [0:0]  ram_wmask;
  wire [65:0] ram_wdata, ram_rdata;
  xs_SRAMTemplate_core #(
    .SET(256), .WAY(1), .DATA_WIDTH(66), .BORE_AW(9),
    .ENABLE_RESET(1), .ENABLE_HOLDREAD(1),
    .ENABLE_CLOCKGATE(0), .EXTRA_RESET(0),
    .USE_BITMASK(0)
  ) u_core (
    .clock(clock), .reset(reset), .io_extra_reset(1'b0),
    .io_r_req_ready(/* no ready port */),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data(io_r_resp_data_0),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data(io_w_req_bits_data_0), .io_w_mask(1'b1),
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
    .ram_clk(ram_clk), .ram_bypass(ram_bypass), .ram_bp_clken(ram_bp_clken),
    .ram_addr(ram_addr), .ram_en(ram_en), .ram_wmode(ram_wmode),
    .ram_wmask(ram_wmask), .ram_wdata(ram_wdata), .ram_rdata(ram_rdata)
  );
  sram_array_1p256x66m66s1h0l1b_icsh_dat array (
    .mbist_dft_ram_bypass(ram_bypass), .mbist_dft_ram_bp_clken(ram_bp_clken),
    .RW0_clk(ram_clk), .RW0_addr(ram_addr), .RW0_en(ram_en), .RW0_wmode(ram_wmode),
    .RW0_wdata(ram_wdata), .RW0_rdata(ram_rdata)
  );
endmodule

module SRAMTemplate_8(
  input  clock,
  input  reset,
  input  io_r_req_valid,
  input  [7:0] io_r_req_bits_setIdx,
  output [65:0] io_r_resp_data_0,
  input  io_w_req_valid,
  input  [7:0] io_w_req_bits_setIdx,
  input  [65:0] io_w_req_bits_data_0,
  input  io_broadcast_ram_hold,
  input  io_broadcast_ram_bypass,
  input  io_broadcast_ram_bp_clken,
  input  io_broadcast_ram_aux_clk,
  input  io_broadcast_ram_aux_ckbp,
  input  io_broadcast_ram_mcp_hold,
  input  [63:0] io_broadcast_ram_ctl,
  input  io_broadcast_cgen,
  input  [8:0] boreChildrenBd_bore_addr,
  input  [8:0] boreChildrenBd_bore_addr_rd,
  input  [65:0] boreChildrenBd_bore_wdata,
  input  boreChildrenBd_bore_wmask,
  input  boreChildrenBd_bore_re,
  input  boreChildrenBd_bore_we,
  output [65:0] boreChildrenBd_bore_rdata,
  input  boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_selectedOH,
  input  [3:0] boreChildrenBd_bore_array
);
  wire        ram_clk, ram_bypass, ram_bp_clken, ram_en, ram_wmode;
  wire [7:0]  ram_addr;
  wire [0:0]  ram_wmask;
  wire [65:0] ram_wdata, ram_rdata;
  xs_SRAMTemplate_core #(
    .SET(256), .WAY(1), .DATA_WIDTH(66), .BORE_AW(9),
    .ENABLE_RESET(1), .ENABLE_HOLDREAD(1),
    .ENABLE_CLOCKGATE(0), .EXTRA_RESET(0),
    .USE_BITMASK(0)
  ) u_core (
    .clock(clock), .reset(reset), .io_extra_reset(1'b0),
    .io_r_req_ready(/* no ready port */),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data(io_r_resp_data_0),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data(io_w_req_bits_data_0), .io_w_mask(1'b1),
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
    .ram_clk(ram_clk), .ram_bypass(ram_bypass), .ram_bp_clken(ram_bp_clken),
    .ram_addr(ram_addr), .ram_en(ram_en), .ram_wmode(ram_wmode),
    .ram_wmask(ram_wmask), .ram_wdata(ram_wdata), .ram_rdata(ram_rdata)
  );
  sram_array_1p256x66m66s1h0l1b_icsh_dat array (
    .mbist_dft_ram_bypass(ram_bypass), .mbist_dft_ram_bp_clken(ram_bp_clken),
    .RW0_clk(ram_clk), .RW0_addr(ram_addr), .RW0_en(ram_en), .RW0_wmode(ram_wmode),
    .RW0_wdata(ram_wdata), .RW0_rdata(ram_rdata)
  );
endmodule

module SRAMTemplate_16(
  input  clock,
  input  reset,
  input  io_r_req_valid,
  input  [7:0] io_r_req_bits_setIdx,
  output [65:0] io_r_resp_data_0,
  input  io_w_req_valid,
  input  [7:0] io_w_req_bits_setIdx,
  input  [65:0] io_w_req_bits_data_0,
  input  io_broadcast_ram_hold,
  input  io_broadcast_ram_bypass,
  input  io_broadcast_ram_bp_clken,
  input  io_broadcast_ram_aux_clk,
  input  io_broadcast_ram_aux_ckbp,
  input  io_broadcast_ram_mcp_hold,
  input  [63:0] io_broadcast_ram_ctl,
  input  io_broadcast_cgen,
  input  [8:0] boreChildrenBd_bore_addr,
  input  [8:0] boreChildrenBd_bore_addr_rd,
  input  [65:0] boreChildrenBd_bore_wdata,
  input  boreChildrenBd_bore_wmask,
  input  boreChildrenBd_bore_re,
  input  boreChildrenBd_bore_we,
  output [65:0] boreChildrenBd_bore_rdata,
  input  boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_selectedOH,
  input  [4:0] boreChildrenBd_bore_array
);
  wire        ram_clk, ram_bypass, ram_bp_clken, ram_en, ram_wmode;
  wire [7:0]  ram_addr;
  wire [0:0]  ram_wmask;
  wire [65:0] ram_wdata, ram_rdata;
  xs_SRAMTemplate_core #(
    .SET(256), .WAY(1), .DATA_WIDTH(66), .BORE_AW(9),
    .ENABLE_RESET(1), .ENABLE_HOLDREAD(1),
    .ENABLE_CLOCKGATE(0), .EXTRA_RESET(0),
    .USE_BITMASK(0)
  ) u_core (
    .clock(clock), .reset(reset), .io_extra_reset(1'b0),
    .io_r_req_ready(/* no ready port */),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data(io_r_resp_data_0),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data(io_w_req_bits_data_0), .io_w_mask(1'b1),
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
    .ram_clk(ram_clk), .ram_bypass(ram_bypass), .ram_bp_clken(ram_bp_clken),
    .ram_addr(ram_addr), .ram_en(ram_en), .ram_wmode(ram_wmode),
    .ram_wmask(ram_wmask), .ram_wdata(ram_wdata), .ram_rdata(ram_rdata)
  );
  sram_array_1p256x66m66s1h0l1b_icsh_dat array (
    .mbist_dft_ram_bypass(ram_bypass), .mbist_dft_ram_bp_clken(ram_bp_clken),
    .RW0_clk(ram_clk), .RW0_addr(ram_addr), .RW0_en(ram_en), .RW0_wmode(ram_wmode),
    .RW0_wdata(ram_wdata), .RW0_rdata(ram_rdata)
  );
endmodule

module SRAMTemplate_32(
  input  clock,
  input  reset,
  input  io_r_req_valid,
  input  [7:0] io_r_req_bits_setIdx,
  output [65:0] io_r_resp_data_0,
  input  io_w_req_valid,
  input  [7:0] io_w_req_bits_setIdx,
  input  [65:0] io_w_req_bits_data_0,
  input  io_broadcast_ram_hold,
  input  io_broadcast_ram_bypass,
  input  io_broadcast_ram_bp_clken,
  input  io_broadcast_ram_aux_clk,
  input  io_broadcast_ram_aux_ckbp,
  input  io_broadcast_ram_mcp_hold,
  input  [63:0] io_broadcast_ram_ctl,
  input  io_broadcast_cgen,
  input  [8:0] boreChildrenBd_bore_addr,
  input  [8:0] boreChildrenBd_bore_addr_rd,
  input  [65:0] boreChildrenBd_bore_wdata,
  input  boreChildrenBd_bore_wmask,
  input  boreChildrenBd_bore_re,
  input  boreChildrenBd_bore_we,
  output [65:0] boreChildrenBd_bore_rdata,
  input  boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_selectedOH,
  input  [5:0] boreChildrenBd_bore_array
);
  wire        ram_clk, ram_bypass, ram_bp_clken, ram_en, ram_wmode;
  wire [7:0]  ram_addr;
  wire [0:0]  ram_wmask;
  wire [65:0] ram_wdata, ram_rdata;
  xs_SRAMTemplate_core #(
    .SET(256), .WAY(1), .DATA_WIDTH(66), .BORE_AW(9),
    .ENABLE_RESET(1), .ENABLE_HOLDREAD(1),
    .ENABLE_CLOCKGATE(0), .EXTRA_RESET(0),
    .USE_BITMASK(0)
  ) u_core (
    .clock(clock), .reset(reset), .io_extra_reset(1'b0),
    .io_r_req_ready(/* no ready port */),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data(io_r_resp_data_0),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data(io_w_req_bits_data_0), .io_w_mask(1'b1),
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
    .ram_clk(ram_clk), .ram_bypass(ram_bypass), .ram_bp_clken(ram_bp_clken),
    .ram_addr(ram_addr), .ram_en(ram_en), .ram_wmode(ram_wmode),
    .ram_wmask(ram_wmask), .ram_wdata(ram_wdata), .ram_rdata(ram_rdata)
  );
  sram_array_1p256x66m66s1h0l1b_icsh_dat array (
    .mbist_dft_ram_bypass(ram_bypass), .mbist_dft_ram_bp_clken(ram_bp_clken),
    .RW0_clk(ram_clk), .RW0_addr(ram_addr), .RW0_en(ram_en), .RW0_wmode(ram_wmode),
    .RW0_wdata(ram_wdata), .RW0_rdata(ram_rdata)
  );
endmodule

module SRAMTemplate_36(
  input  clock,
  input  reset,
  output io_r_req_ready,
  input  io_r_req_valid,
  input  [8:0] io_r_req_bits_setIdx,
  output [9:0] io_r_resp_data_0,
  output [9:0] io_r_resp_data_1,
  output [9:0] io_r_resp_data_2,
  output [9:0] io_r_resp_data_3,
  input  io_w_req_valid,
  input  [8:0] io_w_req_bits_setIdx,
  input  [9:0] io_w_req_bits_data_0,
  input  [9:0] io_w_req_bits_data_1,
  input  [9:0] io_w_req_bits_data_2,
  input  [9:0] io_w_req_bits_data_3,
  input  [3:0] io_w_req_bits_waymask,
  input  io_broadcast_ram_hold,
  input  io_broadcast_ram_bypass,
  input  io_broadcast_ram_bp_clken,
  input  io_broadcast_ram_aux_clk,
  input  io_broadcast_ram_aux_ckbp,
  input  io_broadcast_ram_mcp_hold,
  input  [63:0] io_broadcast_ram_ctl,
  input  io_broadcast_cgen,
  input  [9:0] boreChildrenBd_bore_addr,
  input  [9:0] boreChildrenBd_bore_addr_rd,
  input  [39:0] boreChildrenBd_bore_wdata,
  input  [3:0] boreChildrenBd_bore_wmask,
  input  boreChildrenBd_bore_re,
  input  boreChildrenBd_bore_we,
  output [39:0] boreChildrenBd_bore_rdata,
  input  boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_selectedOH,
  input  [5:0] boreChildrenBd_bore_array
);
  wire        ram_clk, ram_bypass, ram_bp_clken, ram_en, ram_wmode;
  wire [8:0]  ram_addr;
  wire [3:0]  ram_wmask;
  wire [39:0] ram_wdata, ram_rdata;
  xs_SRAMTemplate_core #(
    .SET(512), .WAY(4), .DATA_WIDTH(10), .BORE_AW(10),
    .ENABLE_RESET(1), .ENABLE_HOLDREAD(0),
    .ENABLE_CLOCKGATE(1), .EXTRA_RESET(0),
    .USE_BITMASK(0)
  ) u_core (
    .clock(clock), .reset(reset), .io_extra_reset(1'b0),
    .io_r_req_ready(io_r_req_ready),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data({io_r_resp_data_3, io_r_resp_data_2, io_r_resp_data_1, io_r_resp_data_0}),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data({io_w_req_bits_data_3, io_w_req_bits_data_2, io_w_req_bits_data_1, io_w_req_bits_data_0}), .io_w_mask(io_w_req_bits_waymask),
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
    .ram_clk(ram_clk), .ram_bypass(ram_bypass), .ram_bp_clken(ram_bp_clken),
    .ram_addr(ram_addr), .ram_en(ram_en), .ram_wmode(ram_wmode),
    .ram_wmask(ram_wmask), .ram_wdata(ram_wdata), .ram_rdata(ram_rdata)
  );
  sram_array_1p512x40m10s1h0l1b_bp_ftb array (
    .mbist_dft_ram_bypass(ram_bypass), .mbist_dft_ram_bp_clken(ram_bp_clken),
    .RW0_clk(ram_clk), .RW0_addr(ram_addr), .RW0_en(ram_en), .RW0_wmode(ram_wmode),
    .RW0_wmask(ram_wmask),
    .RW0_wdata(ram_wdata), .RW0_rdata(ram_rdata)
  );
endmodule

module SRAMTemplate_45(
  input  clock,
  input  reset,
  output io_r_req_ready,
  input  io_r_req_valid,
  input  [8:0] io_r_req_bits_setIdx,
  output [11:0] io_r_resp_data_0,
  output [11:0] io_r_resp_data_1,
  input  io_w_req_valid,
  input  [8:0] io_w_req_bits_setIdx,
  input  [11:0] io_w_req_bits_data_0,
  input  [11:0] io_w_req_bits_data_1,
  input  [1:0] io_w_req_bits_waymask,
  input  io_broadcast_ram_hold,
  input  io_broadcast_ram_bypass,
  input  io_broadcast_ram_bp_clken,
  input  io_broadcast_ram_aux_clk,
  input  io_broadcast_ram_aux_ckbp,
  input  io_broadcast_ram_mcp_hold,
  input  [63:0] io_broadcast_ram_ctl,
  input  io_broadcast_cgen,
  input  [9:0] boreChildrenBd_bore_addr,
  input  [9:0] boreChildrenBd_bore_addr_rd,
  input  [23:0] boreChildrenBd_bore_wdata,
  input  [1:0] boreChildrenBd_bore_wmask,
  input  boreChildrenBd_bore_re,
  input  boreChildrenBd_bore_we,
  output [23:0] boreChildrenBd_bore_rdata,
  input  boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_selectedOH,
  input  [5:0] boreChildrenBd_bore_array
);
  wire        ram_clk, ram_bypass, ram_bp_clken, ram_en, ram_wmode;
  wire [8:0]  ram_addr;
  wire [1:0]  ram_wmask;
  wire [23:0] ram_wdata, ram_rdata;
  xs_SRAMTemplate_core #(
    .SET(512), .WAY(2), .DATA_WIDTH(12), .BORE_AW(10),
    .ENABLE_RESET(1), .ENABLE_HOLDREAD(1),
    .ENABLE_CLOCKGATE(1), .EXTRA_RESET(0),
    .USE_BITMASK(0)
  ) u_core (
    .clock(clock), .reset(reset), .io_extra_reset(1'b0),
    .io_r_req_ready(io_r_req_ready),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data({io_r_resp_data_1, io_r_resp_data_0}),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data({io_w_req_bits_data_1, io_w_req_bits_data_0}), .io_w_mask(io_w_req_bits_waymask),
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
    .ram_clk(ram_clk), .ram_bypass(ram_bypass), .ram_bp_clken(ram_bp_clken),
    .ram_addr(ram_addr), .ram_en(ram_en), .ram_wmode(ram_wmode),
    .ram_wmask(ram_wmask), .ram_wdata(ram_wdata), .ram_rdata(ram_rdata)
  );
  sram_array_1p512x24m12s1h0l1b_bp_tage array (
    .mbist_dft_ram_bypass(ram_bypass), .mbist_dft_ram_bp_clken(ram_bp_clken),
    .RW0_clk(ram_clk), .RW0_addr(ram_addr), .RW0_en(ram_en), .RW0_wmode(ram_wmode),
    .RW0_wmask(ram_wmask),
    .RW0_wdata(ram_wdata), .RW0_rdata(ram_rdata)
  );
endmodule

module SRAMTemplate_44(
  input  clock,
  input  reset,
  output io_r_req_ready,
  input  io_r_req_valid,
  input  [7:0] io_r_req_bits_setIdx,
  output io_r_resp_data_0,
  output io_r_resp_data_1,
  output io_r_resp_data_2,
  output io_r_resp_data_3,
  output io_r_resp_data_4,
  output io_r_resp_data_5,
  output io_r_resp_data_6,
  output io_r_resp_data_7,
  output io_r_resp_data_8,
  output io_r_resp_data_9,
  output io_r_resp_data_10,
  output io_r_resp_data_11,
  output io_r_resp_data_12,
  output io_r_resp_data_13,
  output io_r_resp_data_14,
  output io_r_resp_data_15,
  input  io_w_req_valid,
  input  [7:0] io_w_req_bits_setIdx,
  input  io_w_req_bits_data_0,
  input  io_w_req_bits_data_1,
  input  io_w_req_bits_data_2,
  input  io_w_req_bits_data_3,
  input  io_w_req_bits_data_4,
  input  io_w_req_bits_data_5,
  input  io_w_req_bits_data_6,
  input  io_w_req_bits_data_7,
  input  io_w_req_bits_data_8,
  input  io_w_req_bits_data_9,
  input  io_w_req_bits_data_10,
  input  io_w_req_bits_data_11,
  input  io_w_req_bits_data_12,
  input  io_w_req_bits_data_13,
  input  io_w_req_bits_data_14,
  input  io_w_req_bits_data_15,
  input  [15:0] io_w_req_bits_waymask,
  input  io_broadcast_ram_hold,
  input  io_broadcast_ram_bypass,
  input  io_broadcast_ram_bp_clken,
  input  io_broadcast_ram_aux_clk,
  input  io_broadcast_ram_aux_ckbp,
  input  io_broadcast_ram_mcp_hold,
  input  [63:0] io_broadcast_ram_ctl,
  input  io_broadcast_cgen,
  input  extra_reset,
  input  [8:0] boreChildrenBd_bore_addr,
  input  [8:0] boreChildrenBd_bore_addr_rd,
  input  [15:0] boreChildrenBd_bore_wdata,
  input  [15:0] boreChildrenBd_bore_wmask,
  input  boreChildrenBd_bore_re,
  input  boreChildrenBd_bore_we,
  output [15:0] boreChildrenBd_bore_rdata,
  input  boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_selectedOH,
  input  [5:0] boreChildrenBd_bore_array
);
  wire        ram_clk, ram_bypass, ram_bp_clken, ram_en, ram_wmode;
  wire [7:0]  ram_addr;
  wire [15:0]  ram_wmask;
  wire [15:0] ram_wdata, ram_rdata;
  xs_SRAMTemplate_core #(
    .SET(256), .WAY(16), .DATA_WIDTH(1), .BORE_AW(9),
    .ENABLE_RESET(1), .ENABLE_HOLDREAD(1),
    .ENABLE_CLOCKGATE(1), .EXTRA_RESET(1),
    .USE_BITMASK(0)
  ) u_core (
    .clock(clock), .reset(reset), .io_extra_reset(extra_reset),
    .io_r_req_ready(io_r_req_ready),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data({io_r_resp_data_15, io_r_resp_data_14, io_r_resp_data_13, io_r_resp_data_12, io_r_resp_data_11, io_r_resp_data_10, io_r_resp_data_9, io_r_resp_data_8, io_r_resp_data_7, io_r_resp_data_6, io_r_resp_data_5, io_r_resp_data_4, io_r_resp_data_3, io_r_resp_data_2, io_r_resp_data_1, io_r_resp_data_0}),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data({io_w_req_bits_data_15, io_w_req_bits_data_14, io_w_req_bits_data_13, io_w_req_bits_data_12, io_w_req_bits_data_11, io_w_req_bits_data_10, io_w_req_bits_data_9, io_w_req_bits_data_8, io_w_req_bits_data_7, io_w_req_bits_data_6, io_w_req_bits_data_5, io_w_req_bits_data_4, io_w_req_bits_data_3, io_w_req_bits_data_2, io_w_req_bits_data_1, io_w_req_bits_data_0}), .io_w_mask(io_w_req_bits_waymask),
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
    .ram_clk(ram_clk), .ram_bypass(ram_bypass), .ram_bp_clken(ram_bp_clken),
    .ram_addr(ram_addr), .ram_en(ram_en), .ram_wmode(ram_wmode),
    .ram_wmask(ram_wmask), .ram_wdata(ram_wdata), .ram_rdata(ram_rdata)
  );
  sram_array_1p256x16m1s1h0l1b_bp_tage_us array (
    .mbist_dft_ram_bypass(ram_bypass), .mbist_dft_ram_bp_clken(ram_bp_clken),
    .RW0_clk(ram_clk), .RW0_addr(ram_addr), .RW0_en(ram_en), .RW0_wmode(ram_wmode),
    .RW0_wmask(ram_wmask),
    .RW0_wdata(ram_wdata), .RW0_rdata(ram_rdata)
  );
endmodule

module SRAMTemplate_70(
  input  clock,
  input  reset,
  output io_r_req_ready,
  input  io_r_req_valid,
  input  [6:0] io_r_req_bits_setIdx,
  output [37:0] io_r_resp_data_0,
  output [37:0] io_r_resp_data_1,
  input  io_w_req_valid,
  input  [6:0] io_w_req_bits_setIdx,
  input  [37:0] io_w_req_bits_data_0,
  input  [37:0] io_w_req_bits_data_1,
  input  [75:0] io_w_req_bits_flattened_bitmask,
  input  io_broadcast_ram_hold,
  input  io_broadcast_ram_bypass,
  input  io_broadcast_ram_bp_clken,
  input  io_broadcast_ram_aux_clk,
  input  io_broadcast_ram_aux_ckbp,
  input  io_broadcast_ram_mcp_hold,
  input  [63:0] io_broadcast_ram_ctl,
  input  io_broadcast_cgen,
  input  [7:0] boreChildrenBd_bore_addr,
  input  [7:0] boreChildrenBd_bore_addr_rd,
  input  [75:0] boreChildrenBd_bore_wdata,
  input  [75:0] boreChildrenBd_bore_wmask,
  input  boreChildrenBd_bore_re,
  input  boreChildrenBd_bore_we,
  output [75:0] boreChildrenBd_bore_rdata,
  input  boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_selectedOH,
  input  [6:0] boreChildrenBd_bore_array
);
  wire        ram_clk, ram_bypass, ram_bp_clken, ram_en, ram_wmode;
  wire [6:0]  ram_addr;
  wire [75:0]  ram_wmask;
  wire [75:0] ram_wdata, ram_rdata;
  xs_SRAMTemplate_core #(
    .SET(128), .WAY(2), .DATA_WIDTH(38), .BORE_AW(8),
    .ENABLE_RESET(1), .ENABLE_HOLDREAD(1),
    .ENABLE_CLOCKGATE(1), .EXTRA_RESET(0),
    .USE_BITMASK(1)
  ) u_core (
    .clock(clock), .reset(reset), .io_extra_reset(1'b0),
    .io_r_req_ready(io_r_req_ready),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data({io_r_resp_data_1, io_r_resp_data_0}),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data({io_w_req_bits_data_1, io_w_req_bits_data_0}), .io_w_mask(io_w_req_bits_flattened_bitmask),
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
    .ram_clk(ram_clk), .ram_bypass(ram_bypass), .ram_bp_clken(ram_bp_clken),
    .ram_addr(ram_addr), .ram_en(ram_en), .ram_wmode(ram_wmode),
    .ram_wmask(ram_wmask), .ram_wdata(ram_wdata), .ram_rdata(ram_rdata)
  );
  sram_array_1p128x76m1s1h0l1b_bp_ittage array (
    .mbist_dft_ram_bypass(ram_bypass), .mbist_dft_ram_bp_clken(ram_bp_clken),
    .RW0_clk(ram_clk), .RW0_addr(ram_addr), .RW0_en(ram_en), .RW0_wmode(ram_wmode),
    .RW0_wmask(ram_wmask),
    .RW0_wdata(ram_wdata), .RW0_rdata(ram_rdata)
  );
endmodule

module SRAMTemplate_72(
  input  clock,
  input  reset,
  output io_r_req_ready,
  input  io_r_req_valid,
  input  [6:0] io_r_req_bits_setIdx,
  output [18:0] io_r_resp_data_0,
  output [18:0] io_r_resp_data_1,
  output [18:0] io_r_resp_data_2,
  output [18:0] io_r_resp_data_3,
  input  io_w_req_valid,
  input  [6:0] io_w_req_bits_setIdx,
  input  [18:0] io_w_req_bits_data_0,
  input  [18:0] io_w_req_bits_data_1,
  input  [18:0] io_w_req_bits_data_2,
  input  [18:0] io_w_req_bits_data_3,
  input  [75:0] io_w_req_bits_flattened_bitmask,
  input  io_broadcast_ram_hold,
  input  io_broadcast_ram_bypass,
  input  io_broadcast_ram_bp_clken,
  input  io_broadcast_ram_aux_clk,
  input  io_broadcast_ram_aux_ckbp,
  input  io_broadcast_ram_mcp_hold,
  input  [63:0] io_broadcast_ram_ctl,
  input  io_broadcast_cgen,
  input  [7:0] boreChildrenBd_bore_addr,
  input  [7:0] boreChildrenBd_bore_addr_rd,
  input  [75:0] boreChildrenBd_bore_wdata,
  input  [75:0] boreChildrenBd_bore_wmask,
  input  boreChildrenBd_bore_re,
  input  boreChildrenBd_bore_we,
  output [75:0] boreChildrenBd_bore_rdata,
  input  boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_selectedOH,
  input  [6:0] boreChildrenBd_bore_array
);
  wire        ram_clk, ram_bypass, ram_bp_clken, ram_en, ram_wmode;
  wire [6:0]  ram_addr;
  wire [75:0]  ram_wmask;
  wire [75:0] ram_wdata, ram_rdata;
  xs_SRAMTemplate_core #(
    .SET(128), .WAY(4), .DATA_WIDTH(19), .BORE_AW(8),
    .ENABLE_RESET(1), .ENABLE_HOLDREAD(1),
    .ENABLE_CLOCKGATE(1), .EXTRA_RESET(0),
    .USE_BITMASK(1)
  ) u_core (
    .clock(clock), .reset(reset), .io_extra_reset(1'b0),
    .io_r_req_ready(io_r_req_ready),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data({io_r_resp_data_3, io_r_resp_data_2, io_r_resp_data_1, io_r_resp_data_0}),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data({io_w_req_bits_data_3, io_w_req_bits_data_2, io_w_req_bits_data_1, io_w_req_bits_data_0}), .io_w_mask(io_w_req_bits_flattened_bitmask),
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
    .ram_clk(ram_clk), .ram_bypass(ram_bypass), .ram_bp_clken(ram_bp_clken),
    .ram_addr(ram_addr), .ram_en(ram_en), .ram_wmode(ram_wmode),
    .ram_wmask(ram_wmask), .ram_wdata(ram_wdata), .ram_rdata(ram_rdata)
  );
  sram_array_1p128x76m1s1h0l1b_bp_ittage array (
    .mbist_dft_ram_bypass(ram_bypass), .mbist_dft_ram_bp_clken(ram_bp_clken),
    .RW0_clk(ram_clk), .RW0_addr(ram_addr), .RW0_en(ram_en), .RW0_wmode(ram_wmode),
    .RW0_wmask(ram_wmask),
    .RW0_wdata(ram_wdata), .RW0_rdata(ram_rdata)
  );
endmodule
