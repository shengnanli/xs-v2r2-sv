// =============================================================================
// FoldedSRAMTemplate 变体包装层（golden 同名，FM/ST 用）
//
// 对应 Chisel: utility.sram.FoldedSRAMTemplate —— 「折叠式」SRAM 中间层。
//
// 【folding（折叠）原理】
// 逻辑上有 nRows 个 set，但物理 SRAM 不想做这么「深」（深 SRAM 面积/时序差），
// 于是把逻辑 set 沿「行」折叠成 width 份：物理阵列只有 nRows/width 个 set，
// 但每个物理 set 横向放 width 组（每组 = 逻辑的若干路）。即：
//   物理 way 数 = width × 逻辑 way 数
//   物理 set 数 = 逻辑 set 数 / width
//
//   逻辑 setIdx  ──┬─► 高位 setIdx[..:log2(width)]  = 物理 set 地址（raddr）
//                 └─► 低位 setIdx[log2(width)-1:0]  = 折叠组号（ridx，选哪一组）
//
// 读：用 raddr 读出物理 set 的「全部 width 组」，再用「寄存后的 ridx」选出本次
//     请求那一组的输出（读延迟 1 拍，故 ridx 要打一拍对齐数据）。
// 写：只写「ridx 对应那一组」的路 —— 通过把 waymask 按组展开（只有该组的位为 1）。
//
// 【holdRidx：读保持】
// SRAMTemplate 自带 holdRead（读结果保持到下次读）。Folded 层的 ridx 选择也要
// 跟着「保持」：当本拍没有新读请求时，沿用上一次锁存的 ridx，使输出与内层保持的
// 数据对齐。holdRidx = last_read ? ridx : hold_data，其中 last_read 是「上一拍有读」。
// 每条输出数据 lane 有独立的一套 ridx 保持（golden 如此，逐 lane 复制）。
//
// 内层是已验证的 SplittedSRAMTemplate_*（FM 时当黑盒）。
// =============================================================================

// -----------------------------------------------------------------------------
// FoldedSRAMTemplate —— width=8，逻辑 2048set×2way×1b（折叠到 256set×16way）
//   内层 SplittedSRAMTemplate_3（256×16×1，TAGE useful 表）。
//   raddr = setIdx[10:3]（8 位），ridx = setIdx[2:0]（3 位，8 个折叠组）。
//   物理 16 路 = 8 组 × 2 逻辑路。
// -----------------------------------------------------------------------------

module FoldedSRAMTemplate(
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
  localparam int WIDTH    = 8;   // 折叠因子
  localparam int LOG2_W   = 3;   // log2(WIDTH)
  localparam int NWAY     = 2;   // 逻辑 way 数

  // 折叠地址拆分：高位选物理 set，低位选折叠组
  wire [7:0]       raddr = io_r_req_bits_setIdx[10:3];
  wire [LOG2_W-1:0] r_group = io_r_req_bits_setIdx[2:0];
  wire [7:0]       waddr = io_w_req_bits_setIdx[10:3];
  wire [LOG2_W-1:0] w_group = io_w_req_bits_setIdx[2:0];

  // ---- 每条输出 lane 独立的 ridx 保持（读延迟 1 拍 + holdRead 对齐）----
  // last_read：上一拍是否有读请求；hold_data：上次锁存的组号
  reg  [LOG2_W-1:0] ridx;
  reg               last_read [NWAY];
  reg  [LOG2_W-1:0] hold_data [NWAY];
  wire [LOG2_W-1:0] holdRidx  [NWAY];
  genvar k;
  generate
    for (k = 0; k < NWAY; k++) begin : g_hold
      assign holdRidx[k] = last_read[k] ? ridx : hold_data[k];
    end
  endgenerate

  always @(posedge clock) begin
    if (io_r_req_valid) ridx <= r_group;          // 锁存本拍读组号
    for (int j = 0; j < NWAY; j++)
      if (last_read[j]) hold_data[j] <= ridx;     // 有读时更新保持值
  end
  always @(posedge clock or posedge reset) begin
    if (reset) for (int j = 0; j < NWAY; j++) last_read[j] <= 1'b0;
    else       for (int j = 0; j < NWAY; j++) last_read[j] <= io_r_req_valid;
  end

  // ---- 写 waymask 按折叠组展开：只有「w_group 这一组」的 NWAY 路被使能 ----
  // 物理 way 编号 = group*NWAY + logical_way。物理 16 位 waymask。
  wire [WIDTH*NWAY-1:0] phys_waymask;
  genvar g, w;
  generate
    for (g = 0; g < WIDTH; g++) begin : g_wmask_grp
      for (w = 0; w < NWAY; w++) begin : g_wmask_way
        assign phys_waymask[g*NWAY + w] = (w_group == g[LOG2_W-1:0]) & io_w_req_bits_waymask[w];
      end
    end
  endgenerate

  // ---- 写数据：每个折叠组都接同一份逻辑数据（只有被选中的组真正写）----
  wire phys_wdata [WIDTH*NWAY];
  generate
    for (g = 0; g < WIDTH; g++) begin : g_wdata_grp
      assign phys_wdata[g*NWAY + 0] = io_w_req_bits_data_0;
      assign phys_wdata[g*NWAY + 1] = io_w_req_bits_data_1;
    end
  endgenerate

  // 内层 16 路读出
  wire phys_rdata [WIDTH*NWAY];

  SplittedSRAMTemplate_3 array (
    .clock(clock), .reset(reset),
    .io_r_req_ready(io_r_req_ready),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(raddr),
    .io_r_resp_data_0(phys_rdata[0]),   .io_r_resp_data_1(phys_rdata[1]),
    .io_r_resp_data_2(phys_rdata[2]),   .io_r_resp_data_3(phys_rdata[3]),
    .io_r_resp_data_4(phys_rdata[4]),   .io_r_resp_data_5(phys_rdata[5]),
    .io_r_resp_data_6(phys_rdata[6]),   .io_r_resp_data_7(phys_rdata[7]),
    .io_r_resp_data_8(phys_rdata[8]),   .io_r_resp_data_9(phys_rdata[9]),
    .io_r_resp_data_10(phys_rdata[10]), .io_r_resp_data_11(phys_rdata[11]),
    .io_r_resp_data_12(phys_rdata[12]), .io_r_resp_data_13(phys_rdata[13]),
    .io_r_resp_data_14(phys_rdata[14]), .io_r_resp_data_15(phys_rdata[15]),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(waddr),
    .io_w_req_bits_data_0(phys_wdata[0]),   .io_w_req_bits_data_1(phys_wdata[1]),
    .io_w_req_bits_data_2(phys_wdata[2]),   .io_w_req_bits_data_3(phys_wdata[3]),
    .io_w_req_bits_data_4(phys_wdata[4]),   .io_w_req_bits_data_5(phys_wdata[5]),
    .io_w_req_bits_data_6(phys_wdata[6]),   .io_w_req_bits_data_7(phys_wdata[7]),
    .io_w_req_bits_data_8(phys_wdata[8]),   .io_w_req_bits_data_9(phys_wdata[9]),
    .io_w_req_bits_data_10(phys_wdata[10]), .io_w_req_bits_data_11(phys_wdata[11]),
    .io_w_req_bits_data_12(phys_wdata[12]), .io_w_req_bits_data_13(phys_wdata[13]),
    .io_w_req_bits_data_14(phys_wdata[14]), .io_w_req_bits_data_15(phys_wdata[15]),
    .io_w_req_bits_waymask(phys_waymask),
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

  // ---- 读输出：用 holdRidx 选出本次请求那一折叠组的两路 ----
  // 物理 way = holdRidx*NWAY + logical_way
  reg way0_sel, way1_sel;
  always_comb begin
    way0_sel = 1'b0;
    way1_sel = 1'b0;
    for (int gi = 0; gi < WIDTH; gi++) begin
      if (holdRidx[0] == gi[LOG2_W-1:0]) way0_sel = phys_rdata[gi*NWAY + 0];
      if (holdRidx[1] == gi[LOG2_W-1:0]) way1_sel = phys_rdata[gi*NWAY + 1];
    end
  end
  assign io_r_resp_data_0 = way0_sel;
  assign io_r_resp_data_1 = way1_sel;
endmodule

// -----------------------------------------------------------------------------
// FoldedSRAMTemplate_1 —— width=1（不折叠）：纯透传到 SplittedSRAMTemplate_4
//   逻辑 512set×2way×12b（TAGE 表）。folding 因子为 1，没有 ridx/折叠逻辑，
//   Folded 层退化为对内层的 1:1 端口透传。保留它是为了说明「width=1 即关闭折叠」。
// -----------------------------------------------------------------------------
