module FoldedSRAMTemplate_23_xs(
  input         clock,
  input         reset,
  output        io_r_req_ready,
  input         io_r_req_valid,
  input  [8:0]  io_r_req_bits_setIdx,
  output        io_r_resp_data_0_valid,
  output [8:0]  io_r_resp_data_0_tag,
  output [1:0]  io_r_resp_data_0_ctr,
  output [19:0] io_r_resp_data_0_target_offset_offset,
  output [3:0]  io_r_resp_data_0_target_offset_pointer,
  output        io_r_resp_data_0_target_offset_usePCRegion,
  output        io_r_resp_data_0_useful,
  input         io_w_req_valid,
  input  [8:0]  io_w_req_bits_setIdx,
  input  [8:0]  io_w_req_bits_data_0_tag,
  input  [1:0]  io_w_req_bits_data_0_ctr,
  input  [19:0] io_w_req_bits_data_0_target_offset_offset,
  input  [3:0]  io_w_req_bits_data_0_target_offset_pointer,
  input         io_w_req_bits_data_0_target_offset_usePCRegion,
  input         io_w_req_bits_data_0_useful,
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
  localparam int WIDTH = 4;
  // 折叠地址拆分（width=4）
  wire [6:0] raddr = io_r_req_bits_setIdx[8:2];
  wire [1:0] r_group = io_r_req_bits_setIdx[1:0];
  wire [6:0] waddr = io_w_req_bits_setIdx[8:2];
  wire [1:0] w_group = io_w_req_bits_setIdx[1:0];

  // ridx 保持（单 lane，2 位组号）
  reg  [1:0] ridx;
  reg        last_read;
  reg  [1:0] hold_data;
  wire [1:0] holdRidx = last_read ? ridx : hold_data;
  always @(posedge clock) begin
    if (io_r_req_valid) ridx <= r_group;
    if (last_read)      hold_data <= ridx;
  end
  always @(posedge clock or posedge reset) begin
    if (reset) last_read <= 1'b0;
    else       last_read <= io_r_req_valid;
  end

  // 内层 4 路读出，收成数组便于 holdRidx 四选一
  wire        v  [WIDTH];
  wire [8:0]  tg [WIDTH];
  wire [1:0]  ct [WIDTH];
  wire [19:0] of [WIDTH];
  wire [3:0]  pt [WIDTH];
  wire        up [WIDTH];
  wire        uf [WIDTH];

  SplittedSRAMTemplate_26 array (
    .clock(clock), .reset(reset),
    .io_r_req_ready(io_r_req_ready),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(raddr),
    .io_r_resp_data_0_valid(v[0]), .io_r_resp_data_0_tag(tg[0]), .io_r_resp_data_0_ctr(ct[0]),
    .io_r_resp_data_0_target_offset_offset(of[0]),
    .io_r_resp_data_0_target_offset_pointer(pt[0]),
    .io_r_resp_data_0_target_offset_usePCRegion(up[0]), .io_r_resp_data_0_useful(uf[0]),
    .io_r_resp_data_1_valid(v[1]), .io_r_resp_data_1_tag(tg[1]), .io_r_resp_data_1_ctr(ct[1]),
    .io_r_resp_data_1_target_offset_offset(of[1]),
    .io_r_resp_data_1_target_offset_pointer(pt[1]),
    .io_r_resp_data_1_target_offset_usePCRegion(up[1]), .io_r_resp_data_1_useful(uf[1]),
    .io_r_resp_data_2_valid(v[2]), .io_r_resp_data_2_tag(tg[2]), .io_r_resp_data_2_ctr(ct[2]),
    .io_r_resp_data_2_target_offset_offset(of[2]),
    .io_r_resp_data_2_target_offset_pointer(pt[2]),
    .io_r_resp_data_2_target_offset_usePCRegion(up[2]), .io_r_resp_data_2_useful(uf[2]),
    .io_r_resp_data_3_valid(v[3]), .io_r_resp_data_3_tag(tg[3]), .io_r_resp_data_3_ctr(ct[3]),
    .io_r_resp_data_3_target_offset_offset(of[3]),
    .io_r_resp_data_3_target_offset_pointer(pt[3]),
    .io_r_resp_data_3_target_offset_usePCRegion(up[3]), .io_r_resp_data_3_useful(uf[3]),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(waddr),
    // 4 个折叠组都写同一份数据，靠 waymask 选组
    .io_w_req_bits_data_0_tag(io_w_req_bits_data_0_tag),
    .io_w_req_bits_data_0_ctr(io_w_req_bits_data_0_ctr),
    .io_w_req_bits_data_0_target_offset_offset(io_w_req_bits_data_0_target_offset_offset),
    .io_w_req_bits_data_0_target_offset_pointer(io_w_req_bits_data_0_target_offset_pointer),
    .io_w_req_bits_data_0_target_offset_usePCRegion(io_w_req_bits_data_0_target_offset_usePCRegion),
    .io_w_req_bits_data_0_useful(io_w_req_bits_data_0_useful),
    .io_w_req_bits_data_1_tag(io_w_req_bits_data_0_tag),
    .io_w_req_bits_data_1_ctr(io_w_req_bits_data_0_ctr),
    .io_w_req_bits_data_1_target_offset_offset(io_w_req_bits_data_0_target_offset_offset),
    .io_w_req_bits_data_1_target_offset_pointer(io_w_req_bits_data_0_target_offset_pointer),
    .io_w_req_bits_data_1_target_offset_usePCRegion(io_w_req_bits_data_0_target_offset_usePCRegion),
    .io_w_req_bits_data_1_useful(io_w_req_bits_data_0_useful),
    .io_w_req_bits_data_2_tag(io_w_req_bits_data_0_tag),
    .io_w_req_bits_data_2_ctr(io_w_req_bits_data_0_ctr),
    .io_w_req_bits_data_2_target_offset_offset(io_w_req_bits_data_0_target_offset_offset),
    .io_w_req_bits_data_2_target_offset_pointer(io_w_req_bits_data_0_target_offset_pointer),
    .io_w_req_bits_data_2_target_offset_usePCRegion(io_w_req_bits_data_0_target_offset_usePCRegion),
    .io_w_req_bits_data_2_useful(io_w_req_bits_data_0_useful),
    .io_w_req_bits_data_3_tag(io_w_req_bits_data_0_tag),
    .io_w_req_bits_data_3_ctr(io_w_req_bits_data_0_ctr),
    .io_w_req_bits_data_3_target_offset_offset(io_w_req_bits_data_0_target_offset_offset),
    .io_w_req_bits_data_3_target_offset_pointer(io_w_req_bits_data_0_target_offset_pointer),
    .io_w_req_bits_data_3_target_offset_usePCRegion(io_w_req_bits_data_0_target_offset_usePCRegion),
    .io_w_req_bits_data_3_useful(io_w_req_bits_data_0_useful),
    .io_w_req_bits_waymask(4'h1 << w_group),  // 只写 w_group 这一折叠组
    .io_w_req_bits_bitmask(io_w_req_bits_bitmask),
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

  // 读输出：holdRidx 在 4 个折叠组中四选一
  assign io_r_resp_data_0_valid                     = v[holdRidx];
  assign io_r_resp_data_0_tag                       = tg[holdRidx];
  assign io_r_resp_data_0_ctr                       = ct[holdRidx];
  assign io_r_resp_data_0_target_offset_offset      = of[holdRidx];
  assign io_r_resp_data_0_target_offset_pointer     = pt[holdRidx];
  assign io_r_resp_data_0_target_offset_usePCRegion = up[holdRidx];
  assign io_r_resp_data_0_useful                    = uf[holdRidx];
endmodule
