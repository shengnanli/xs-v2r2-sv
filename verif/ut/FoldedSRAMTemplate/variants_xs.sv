module FoldedSRAMTemplate_xs(
  input         clock,
  input         reset,
  output        io_r_req_ready,
  input         io_r_req_valid,
  input  [10:0] io_r_req_bits_setIdx,
  output        io_r_resp_data_0,
  output        io_r_resp_data_1,
  input         io_w_req_valid,
  input  [10:0] io_w_req_bits_setIdx,
  input         io_w_req_bits_data_0,
  input         io_w_req_bits_data_1,
  input  [1:0]  io_w_req_bits_waymask,
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
  // 内层 16 way 读出：way = 组g(0..7)*2 + 逻辑way(0/1)，即 inner_w[2g+lw]
  wire [15:0] inner_rdata;

  // 折叠组索引：读请求时锁存 setIdx 低 3 位，再延一拍（hold）做输出选择。
  // golden 用两套相同寄存器（data_0/data_1 各一份），此处分别保留以对齐命名。
  reg  [2:0] ridx;
  reg        holdRidx_last_REG, holdRidx_last_REG_1;
  reg  [2:0] holdRidx_hold_data, holdRidx_hold_data_1;
  wire [2:0] holdRidx   = holdRidx_last_REG   ? ridx : holdRidx_hold_data;
  wire [2:0] holdRidx_1 = holdRidx_last_REG_1 ? ridx : holdRidx_hold_data_1;

  always @(posedge clock) begin
    if (io_r_req_valid)   ridx                 <= io_r_req_bits_setIdx[2:0];
    if (holdRidx_last_REG)   holdRidx_hold_data   <= ridx;
    if (holdRidx_last_REG_1) holdRidx_hold_data_1 <= ridx;
  end
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      holdRidx_last_REG   <= 1'h0;
      holdRidx_last_REG_1 <= 1'h0;
    end else begin
      holdRidx_last_REG   <= io_r_req_valid;
      holdRidx_last_REG_1 <= io_r_req_valid;
    end
  end

  // 写折叠组选择：setIdx 低 3 位 == g 时，把该组 2 个 way 的 waymask 打开。
  wire we0 = io_w_req_bits_setIdx[2:0] == 3'h0;
  wire we1 = io_w_req_bits_setIdx[2:0] == 3'h1;
  wire we2 = io_w_req_bits_setIdx[2:0] == 3'h2;
  wire we3 = io_w_req_bits_setIdx[2:0] == 3'h3;
  wire we4 = io_w_req_bits_setIdx[2:0] == 3'h4;
  wire we5 = io_w_req_bits_setIdx[2:0] == 3'h5;
  wire we6 = io_w_req_bits_setIdx[2:0] == 3'h6;
  wire we7 = &io_w_req_bits_setIdx[2:0];  // == 3'h7

  SplittedSRAMTemplate_3 array (
    .clock(clock), .reset(reset),
    .io_r_req_ready(io_r_req_ready),
    .io_r_req_valid(io_r_req_valid),
    .io_r_req_bits_setIdx(io_r_req_bits_setIdx[10:3]),   // 内层物理 set = 高 8 位
    .io_r_resp_data_0(inner_rdata[0]),   .io_r_resp_data_1(inner_rdata[1]),
    .io_r_resp_data_2(inner_rdata[2]),   .io_r_resp_data_3(inner_rdata[3]),
    .io_r_resp_data_4(inner_rdata[4]),   .io_r_resp_data_5(inner_rdata[5]),
    .io_r_resp_data_6(inner_rdata[6]),   .io_r_resp_data_7(inner_rdata[7]),
    .io_r_resp_data_8(inner_rdata[8]),   .io_r_resp_data_9(inner_rdata[9]),
    .io_r_resp_data_10(inner_rdata[10]), .io_r_resp_data_11(inner_rdata[11]),
    .io_r_resp_data_12(inner_rdata[12]), .io_r_resp_data_13(inner_rdata[13]),
    .io_r_resp_data_14(inner_rdata[14]), .io_r_resp_data_15(inner_rdata[15]),
    .io_w_req_valid(io_w_req_valid),
    .io_w_req_bits_setIdx(io_w_req_bits_setIdx[10:3]),
    // 写数据：16 个 way = 8 组 × {way0=data_0, way1=data_1}，所有组同值
    .io_w_req_bits_data_0(io_w_req_bits_data_0),  .io_w_req_bits_data_1(io_w_req_bits_data_1),
    .io_w_req_bits_data_2(io_w_req_bits_data_0),  .io_w_req_bits_data_3(io_w_req_bits_data_1),
    .io_w_req_bits_data_4(io_w_req_bits_data_0),  .io_w_req_bits_data_5(io_w_req_bits_data_1),
    .io_w_req_bits_data_6(io_w_req_bits_data_0),  .io_w_req_bits_data_7(io_w_req_bits_data_1),
    .io_w_req_bits_data_8(io_w_req_bits_data_0),  .io_w_req_bits_data_9(io_w_req_bits_data_1),
    .io_w_req_bits_data_10(io_w_req_bits_data_0), .io_w_req_bits_data_11(io_w_req_bits_data_1),
    .io_w_req_bits_data_12(io_w_req_bits_data_0), .io_w_req_bits_data_13(io_w_req_bits_data_1),
    .io_w_req_bits_data_14(io_w_req_bits_data_0), .io_w_req_bits_data_15(io_w_req_bits_data_1),
    // waymask[15:0]：仅命中组 g 的两 way 受 io_w_req_bits_waymask[1:0] 控制
    .io_w_req_bits_waymask({
      we7 & io_w_req_bits_waymask[1], we7 & io_w_req_bits_waymask[0],
      we6 & io_w_req_bits_waymask[1], we6 & io_w_req_bits_waymask[0],
      we5 & io_w_req_bits_waymask[1], we5 & io_w_req_bits_waymask[0],
      we4 & io_w_req_bits_waymask[1], we4 & io_w_req_bits_waymask[0],
      we3 & io_w_req_bits_waymask[1], we3 & io_w_req_bits_waymask[0],
      we2 & io_w_req_bits_waymask[1], we2 & io_w_req_bits_waymask[0],
      we1 & io_w_req_bits_waymask[1], we1 & io_w_req_bits_waymask[0],
      we0 & io_w_req_bits_waymask[1], we0 & io_w_req_bits_waymask[0]}),
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
    .boreChildrenBd_bore_array(boreChildrenBd_bore_array),
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen)
  );

  // 读输出：way0 取偶数下标组（2g+0），way1 取奇数下标组（2g+1），按 holdRidx 选组
  assign io_r_resp_data_0 =
      holdRidx == 3'h0 & inner_rdata[0]  | holdRidx == 3'h1 & inner_rdata[2]
    | holdRidx == 3'h2 & inner_rdata[4]  | holdRidx == 3'h3 & inner_rdata[6]
    | holdRidx == 3'h4 & inner_rdata[8]  | holdRidx == 3'h5 & inner_rdata[10]
    | holdRidx == 3'h6 & inner_rdata[12] | (&holdRidx)       & inner_rdata[14];
  assign io_r_resp_data_1 =
      holdRidx_1 == 3'h0 & inner_rdata[1]  | holdRidx_1 == 3'h1 & inner_rdata[3]
    | holdRidx_1 == 3'h2 & inner_rdata[5]  | holdRidx_1 == 3'h3 & inner_rdata[7]
    | holdRidx_1 == 3'h4 & inner_rdata[9]  | holdRidx_1 == 3'h5 & inner_rdata[11]
    | holdRidx_1 == 3'h6 & inner_rdata[13] | (&holdRidx_1)      & inner_rdata[15];
endmodule
