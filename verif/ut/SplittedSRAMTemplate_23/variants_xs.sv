// UT impl 副本：SplittedSRAMTemplate_23_xs（同体，仅名加 _xs）
module SplittedSRAMTemplate_23_xs(
  input         clock,
  input         reset,
  input         io_r_req_valid,
  input  [8:0]  io_r_req_bits_setIdx,
  output [1:0]  io_r_resp_data_0, output [1:0] io_r_resp_data_1,
  output [1:0]  io_r_resp_data_2, output [1:0] io_r_resp_data_3,
  output [1:0]  io_r_resp_data_4, output [1:0] io_r_resp_data_5,
  output [1:0]  io_r_resp_data_6, output [1:0] io_r_resp_data_7,
  input         io_w_req_valid,
  input  [8:0]  io_w_req_bits_setIdx,
  input  [1:0]  io_w_req_bits_data_0, input [1:0] io_w_req_bits_data_1,
  input  [1:0]  io_w_req_bits_data_2, input [1:0] io_w_req_bits_data_3,
  input  [1:0]  io_w_req_bits_data_4, input [1:0] io_w_req_bits_data_5,
  input  [1:0]  io_w_req_bits_data_6, input [1:0] io_w_req_bits_data_7,
  input  [7:0]  io_w_req_bits_waymask,
  input  [8:0]  boreChildrenBd_bore_addr, boreChildrenBd_bore_addr_rd,
  input  [15:0] boreChildrenBd_bore_wdata,
  input  [7:0]  boreChildrenBd_bore_wmask,
  input         boreChildrenBd_bore_re, boreChildrenBd_bore_we,
  output [15:0] boreChildrenBd_bore_rdata,
  input         boreChildrenBd_bore_ack, boreChildrenBd_bore_selectedOH,
  input  [6:0]  boreChildrenBd_bore_array,
  input  [8:0]  boreChildrenBd_bore_1_addr, boreChildrenBd_bore_1_addr_rd,
  input  [15:0] boreChildrenBd_bore_1_wdata,
  input  [7:0]  boreChildrenBd_bore_1_wmask,
  input         boreChildrenBd_bore_1_re, boreChildrenBd_bore_1_we,
  output [15:0] boreChildrenBd_bore_1_rdata,
  input         boreChildrenBd_bore_1_ack, boreChildrenBd_bore_1_selectedOH,
  input  [6:0]  boreChildrenBd_bore_1_array,
  input         sigFromSrams_bore_ram_hold, sigFromSrams_bore_ram_bypass,
  input         sigFromSrams_bore_ram_bp_clken, sigFromSrams_bore_ram_aux_clk,
  input         sigFromSrams_bore_ram_aux_ckbp, sigFromSrams_bore_ram_mcp_hold,
  input         sigFromSrams_bore_cgen,
  input         sigFromSrams_bore_1_ram_hold, sigFromSrams_bore_1_ram_bypass,
  input         sigFromSrams_bore_1_ram_bp_clken, sigFromSrams_bore_1_ram_aux_clk,
  input         sigFromSrams_bore_1_ram_aux_ckbp, sigFromSrams_bore_1_ram_mcp_hold,
  input         sigFromSrams_bore_1_cgen
);
  localparam int unsigned W = 8;
  wire        rsel = io_r_req_bits_setIdx[0];   // 读 bank：0→bank0, 1→bank1
  wire        wsel = io_w_req_bits_setIdx[0];   // 写 bank
  wire [7:0]  inner_raddr = io_r_req_bits_setIdx[8:1];
  wire [7:0]  inner_waddr = io_w_req_bits_setIdx[8:1];

  // 读出 bank 选择寄存一拍（对齐 SRAM 1 拍读延迟）；ren_vec[0]=选bank0, [1]=选bank1
  reg  [1:0]  ren_vec;
  always_ff @(posedge clock or posedge reset) begin
    if (reset)               ren_vec <= 2'b00;
    else if (io_r_req_valid) ren_vec <= {rsel, ~rsel};
  end

  wire [1:0] b0_rd [W];   // bank0 八路读出
  wire [1:0] b1_rd [W];   // bank1 八路读出

  SRAMTemplate_64 array_0_0_0 (
    .clock(clock), .reset(reset),
    .io_r_req_valid(io_r_req_valid & ~rsel), .io_r_req_bits_setIdx(inner_raddr),
    .io_r_resp_data_0(b0_rd[0]), .io_r_resp_data_1(b0_rd[1]), .io_r_resp_data_2(b0_rd[2]),
    .io_r_resp_data_3(b0_rd[3]), .io_r_resp_data_4(b0_rd[4]), .io_r_resp_data_5(b0_rd[5]),
    .io_r_resp_data_6(b0_rd[6]), .io_r_resp_data_7(b0_rd[7]),
    .io_w_req_valid(io_w_req_valid & ~wsel), .io_w_req_bits_setIdx(inner_waddr),
    .io_w_req_bits_data_0(io_w_req_bits_data_0), .io_w_req_bits_data_1(io_w_req_bits_data_1),
    .io_w_req_bits_data_2(io_w_req_bits_data_2), .io_w_req_bits_data_3(io_w_req_bits_data_3),
    .io_w_req_bits_data_4(io_w_req_bits_data_4), .io_w_req_bits_data_5(io_w_req_bits_data_5),
    .io_w_req_bits_data_6(io_w_req_bits_data_6), .io_w_req_bits_data_7(io_w_req_bits_data_7),
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
  SRAMTemplate_64 array_1_0_0 (
    .clock(clock), .reset(reset),
    .io_r_req_valid(io_r_req_valid & rsel), .io_r_req_bits_setIdx(inner_raddr),
    .io_r_resp_data_0(b1_rd[0]), .io_r_resp_data_1(b1_rd[1]), .io_r_resp_data_2(b1_rd[2]),
    .io_r_resp_data_3(b1_rd[3]), .io_r_resp_data_4(b1_rd[4]), .io_r_resp_data_5(b1_rd[5]),
    .io_r_resp_data_6(b1_rd[6]), .io_r_resp_data_7(b1_rd[7]),
    .io_w_req_valid(io_w_req_valid & wsel), .io_w_req_bits_setIdx(inner_waddr),
    .io_w_req_bits_data_0(io_w_req_bits_data_0), .io_w_req_bits_data_1(io_w_req_bits_data_1),
    .io_w_req_bits_data_2(io_w_req_bits_data_2), .io_w_req_bits_data_3(io_w_req_bits_data_3),
    .io_w_req_bits_data_4(io_w_req_bits_data_4), .io_w_req_bits_data_5(io_w_req_bits_data_5),
    .io_w_req_bits_data_6(io_w_req_bits_data_6), .io_w_req_bits_data_7(io_w_req_bits_data_7),
    .io_w_req_bits_waymask(io_w_req_bits_waymask),
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

  // 读响应：按寄存的 bank 选择做 Mux1H（未选 bank 贡献 0）
  wire [1:0] resp [W];
  genvar w;
  generate for (w = 0; w < W; w++) begin : g_resp
    assign resp[w] = (ren_vec[0] ? b0_rd[w] : 2'b0) | (ren_vec[1] ? b1_rd[w] : 2'b0);
  end endgenerate
  assign io_r_resp_data_0 = resp[0]; assign io_r_resp_data_1 = resp[1];
  assign io_r_resp_data_2 = resp[2]; assign io_r_resp_data_3 = resp[3];
  assign io_r_resp_data_4 = resp[4]; assign io_r_resp_data_5 = resp[5];
  assign io_r_resp_data_6 = resp[6]; assign io_r_resp_data_7 = resp[7];
endmodule
