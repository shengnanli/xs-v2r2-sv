// FoldedSRAMTemplate_20 —— FoldedSRAMTemplate 家族变体
// 家族共性（结构原理、保持逻辑、与内层的关系）见 FoldedSRAMTemplate.sv 文件头；
// 本文件只放本变体的参数与端口。
// FoldedSRAMTemplate_20 —— 折叠式 SRAM 中间层（G1 形态：逻辑 1024set×2way，
// 折叠系数 WIDTH=2 → 内层 SplittedSRAMTemplate_23 为 512set×4way）。
// 折叠系数由 4 降为 2（逻辑 set 2048→1024），地址切分与物理路数同步收窄。

module FoldedSRAMTemplate_20(
  input        clock,
  input        reset,
  input        io_r_req_valid,
  input  [9:0] io_r_req_bits_setIdx,
  output [1:0] io_r_resp_data_0,
  output [1:0] io_r_resp_data_1,
  input        io_w_req_valid,
  input  [9:0] io_w_req_bits_setIdx,
  input  [1:0] io_w_req_bits_data_0,
  input  [1:0] io_w_req_bits_data_1,
  input  [1:0] io_w_req_bits_waymask,
  input  [8:0] boreChildrenBd_bore_addr,
  input  [8:0] boreChildrenBd_bore_addr_rd,
  input  [7:0] boreChildrenBd_bore_wdata,
  input  [3:0] boreChildrenBd_bore_wmask,
  input        boreChildrenBd_bore_re,
  input        boreChildrenBd_bore_we,
  output [7:0] boreChildrenBd_bore_rdata,
  input        boreChildrenBd_bore_ack,
  input        boreChildrenBd_bore_selectedOH,
  input  [6:0] boreChildrenBd_bore_array,
  input  [8:0] boreChildrenBd_bore_1_addr,
  input  [8:0] boreChildrenBd_bore_1_addr_rd,
  input  [7:0] boreChildrenBd_bore_1_wdata,
  input  [3:0] boreChildrenBd_bore_1_wmask,
  input        boreChildrenBd_bore_1_re,
  input        boreChildrenBd_bore_1_we,
  output [7:0] boreChildrenBd_bore_1_rdata,
  input        boreChildrenBd_bore_1_ack,
  input        boreChildrenBd_bore_1_selectedOH,
  input  [6:0] boreChildrenBd_bore_1_array,
  input        sigFromSrams_bore_ram_hold,
  input        sigFromSrams_bore_ram_bypass,
  input        sigFromSrams_bore_ram_bp_clken,
  input        sigFromSrams_bore_ram_aux_clk,
  input        sigFromSrams_bore_ram_aux_ckbp,
  input        sigFromSrams_bore_ram_mcp_hold,
  input        sigFromSrams_bore_cgen,
  input        sigFromSrams_bore_1_ram_hold,
  input        sigFromSrams_bore_1_ram_bypass,
  input        sigFromSrams_bore_1_ram_bp_clken,
  input        sigFromSrams_bore_1_ram_aux_clk,
  input        sigFromSrams_bore_1_ram_aux_ckbp,
  input        sigFromSrams_bore_1_ram_mcp_hold,
  input        sigFromSrams_bore_1_cgen
);
  localparam int unsigned WIDTH = 2;   // 折叠系数 = 1024/512（G1 由 4 改为 2）
  localparam int unsigned WAY   = 2;   // 逻辑路数

  // 折叠地址：高位 → 内层 set；最低 1 位 → 折叠组
  wire [8:0] raddr   = io_r_req_bits_setIdx[9:1];
  wire [8:0] waddr   = io_w_req_bits_setIdx[9:1];
  wire       w_group = io_w_req_bits_setIdx[0];

  // 折叠组寄存一拍（对齐内层 SRAM 1 拍读延迟）
  reg        ridx;
  reg        last_read;
  reg        hold_data;
  wire       holdRidx = last_read ? ridx : hold_data;
  always @(posedge clock) begin
    if (io_r_req_valid) ridx <= io_r_req_bits_setIdx[0];
    if (last_read)      hold_data <= ridx;
  end
  always @(posedge clock or posedge reset) begin
    if (reset) last_read <= 1'b0;
    else       last_read <= io_r_req_valid;
  end

  // 物理 waymask[2*group+w] = (w_group==group) & 逻辑waymask[w]
  wire [3:0] phys_waymask;
  genvar g, w;
  generate for (g = 0; g < WIDTH; g++) for (w = 0; w < WAY; w++) begin : g_wm
    assign phys_waymask[2*g + w] = (w_group == g[0:0]) & io_w_req_bits_waymask[w];
  end endgenerate

  wire [1:0] rd [4];   // 内层 4 路读出

  SplittedSRAMTemplate_23 array (
    .clock(clock), .reset(reset),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(raddr),
    .io_r_resp_data_0(rd[0]), .io_r_resp_data_1(rd[1]), .io_r_resp_data_2(rd[2]),
    .io_r_resp_data_3(rd[3]),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(waddr),
    // 逻辑 way0 数据 → 物理偶路(0,2)；way1 → 物理奇路(1,3)
    .io_w_req_bits_data_0(io_w_req_bits_data_0), .io_w_req_bits_data_1(io_w_req_bits_data_1),
    .io_w_req_bits_data_2(io_w_req_bits_data_0), .io_w_req_bits_data_3(io_w_req_bits_data_1),
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
