// UT impl 副本：FoldedSRAMTemplate_20_xs（同体，仅名加 _xs）
module FoldedSRAMTemplate_20_xs(
  input         clock,
  input         reset,
  input         io_r_req_valid,
  input  [10:0] io_r_req_bits_setIdx,
  output [1:0]  io_r_resp_data_0,
  output [1:0]  io_r_resp_data_1,
  input         io_w_req_valid,
  input  [10:0] io_w_req_bits_setIdx,
  input  [1:0]  io_w_req_bits_data_0,
  input  [1:0]  io_w_req_bits_data_1,
  input  [1:0]  io_w_req_bits_waymask,
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
  localparam int unsigned WIDTH = 4;   // 折叠系数 = 2048/512
  localparam int unsigned WAY   = 2;   // 逻辑路数

  // 折叠地址：高位 → 内层 set；低 2 位 → 折叠组
  wire [8:0] raddr   = io_r_req_bits_setIdx[10:2];
  wire [8:0] waddr   = io_w_req_bits_setIdx[10:2];
  wire [1:0] w_group = io_w_req_bits_setIdx[1:0];

  // 折叠组寄存一拍（对齐内层 SRAM 1 拍读延迟）
  reg  [1:0] ridx;
  reg        last_read;
  reg  [1:0] hold_data;
  wire [1:0] holdRidx = last_read ? ridx : hold_data;
  always @(posedge clock) begin
    if (io_r_req_valid) ridx <= io_r_req_bits_setIdx[1:0];
    if (last_read)      hold_data <= ridx;
  end
  always @(posedge clock or posedge reset) begin
    if (reset) last_read <= 1'b0;
    else       last_read <= io_r_req_valid;
  end

  // 物理 waymask[2*group+w] = (w_group==group) & 逻辑waymask[w]
  wire [7:0] phys_waymask;
  genvar g, w;
  generate for (g = 0; g < WIDTH; g++) for (w = 0; w < WAY; w++) begin : g_wm
    assign phys_waymask[2*g + w] = (w_group == g[1:0]) & io_w_req_bits_waymask[w];
  end endgenerate

  wire [1:0] rd [8];   // 内层 8 路读出

  SplittedSRAMTemplate_23 array (
    .clock(clock), .reset(reset),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(raddr),
    .io_r_resp_data_0(rd[0]), .io_r_resp_data_1(rd[1]), .io_r_resp_data_2(rd[2]),
    .io_r_resp_data_3(rd[3]), .io_r_resp_data_4(rd[4]), .io_r_resp_data_5(rd[5]),
    .io_r_resp_data_6(rd[6]), .io_r_resp_data_7(rd[7]),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(waddr),
    // 逻辑 way0 数据 → 物理偶路(0,2,4,6)；way1 → 物理奇路(1,3,5,7)
    .io_w_req_bits_data_0(io_w_req_bits_data_0), .io_w_req_bits_data_1(io_w_req_bits_data_1),
    .io_w_req_bits_data_2(io_w_req_bits_data_0), .io_w_req_bits_data_3(io_w_req_bits_data_1),
    .io_w_req_bits_data_4(io_w_req_bits_data_0), .io_w_req_bits_data_5(io_w_req_bits_data_1),
    .io_w_req_bits_data_6(io_w_req_bits_data_0), .io_w_req_bits_data_7(io_w_req_bits_data_1),
    .io_w_req_bits_waymask(phys_waymask),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(boreChildrenBd_bore_wdata),
    .boreChildrenBd_bore_wmask(boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(boreChildrenBd_bore_re),
    .boreChildrenBd_bore_we(boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(boreChildrenBd_bore_rdata),
    .boreChildrenBd_bore_ack(boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(boreChildrenBd_bore_selectedOH),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_array),
    .boreChildrenBd_bore_1_addr(boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_addr_rd(boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_wdata(boreChildrenBd_bore_1_wdata),
    .boreChildrenBd_bore_1_wmask(boreChildrenBd_bore_1_wmask),
    .boreChildrenBd_bore_1_re(boreChildrenBd_bore_1_re),
    .boreChildrenBd_bore_1_we(boreChildrenBd_bore_1_we),
    .boreChildrenBd_bore_1_rdata(boreChildrenBd_bore_1_rdata),
    .boreChildrenBd_bore_1_ack(boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_selectedOH(boreChildrenBd_bore_1_selectedOH),
    .boreChildrenBd_bore_1_array(boreChildrenBd_bore_1_array),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold(sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass(sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen)
  );

  // 读响应：按折叠组选物理 way 组（way0=偶路 2*group, way1=奇路 2*group+1）
  assign io_r_resp_data_0 = rd[2*holdRidx];
  assign io_r_resp_data_1 = rd[2*holdRidx + 1];
endmodule
