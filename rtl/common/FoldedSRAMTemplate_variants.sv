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
module FoldedSRAMTemplate_1(
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
  SplittedSRAMTemplate_4 array (
    .clock(clock), .reset(reset),
    .io_r_req_ready(io_r_req_ready),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data_0_valid(io_r_resp_data_0_valid),
    .io_r_resp_data_0_tag(io_r_resp_data_0_tag),
    .io_r_resp_data_0_ctr(io_r_resp_data_0_ctr),
    .io_r_resp_data_1_valid(io_r_resp_data_1_valid),
    .io_r_resp_data_1_tag(io_r_resp_data_1_tag),
    .io_r_resp_data_1_ctr(io_r_resp_data_1_ctr),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data_0_tag(io_w_req_bits_data_0_tag),
    .io_w_req_bits_data_0_ctr(io_w_req_bits_data_0_ctr),
    .io_w_req_bits_data_1_tag(io_w_req_bits_data_1_tag),
    .io_w_req_bits_data_1_ctr(io_w_req_bits_data_1_ctr),
    .io_w_req_bits_waymask(io_w_req_bits_waymask),
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
endmodule

// -----------------------------------------------------------------------------
// FoldedSRAMTemplate_21 —— width=2，逻辑 256set×1way×38b（ITTAGE）
//   折叠到内层 SplittedSRAMTemplate_24（128set×2way×38b）。
//   raddr = setIdx[7:1]，ridx = setIdx[0]（2 个折叠组），物理 2 路 = 2 组 × 1 逻辑路。
//   单逻辑 way，单 lane → 一套 ridx 保持。带逐位 bitmask 透传。
// -----------------------------------------------------------------------------
module FoldedSRAMTemplate_21(
  input         clock,
  input         reset,
  output        io_r_req_ready,
  input         io_r_req_valid,
  input  [7:0]  io_r_req_bits_setIdx,
  output        io_r_resp_data_0_valid,
  output [8:0]  io_r_resp_data_0_tag,
  output [1:0]  io_r_resp_data_0_ctr,
  output [19:0] io_r_resp_data_0_target_offset_offset,
  output [3:0]  io_r_resp_data_0_target_offset_pointer,
  output        io_r_resp_data_0_target_offset_usePCRegion,
  output        io_r_resp_data_0_useful,
  input         io_w_req_valid,
  input  [7:0]  io_w_req_bits_setIdx,
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
  input         sigFromSrams_bore_ram_hold,
  input         sigFromSrams_bore_ram_bypass,
  input         sigFromSrams_bore_ram_bp_clken,
  input         sigFromSrams_bore_ram_aux_clk,
  input         sigFromSrams_bore_ram_aux_ckbp,
  input         sigFromSrams_bore_ram_mcp_hold,
  input         sigFromSrams_bore_cgen
);
  // 折叠地址拆分（width=2）
  wire [6:0] raddr = io_r_req_bits_setIdx[7:1];
  wire       r_group = io_r_req_bits_setIdx[0];
  wire [6:0] waddr = io_w_req_bits_setIdx[7:1];
  wire       w_group = io_w_req_bits_setIdx[0];

  // ridx 保持（单 lane）
  reg  ridx;
  reg  last_read;
  reg  hold_data;
  wire holdRidx = last_read ? ridx : hold_data;
  always @(posedge clock) begin
    if (io_r_req_valid) ridx <= r_group;
    if (last_read)      hold_data <= ridx;
  end
  always @(posedge clock or posedge reset) begin
    if (reset) last_read <= 1'b0;
    else       last_read <= io_r_req_valid;
  end

  // 内层 2 路读出（way0=组0，way1=组1）
  wire        v0,  v1;
  wire [8:0]  tg0, tg1;
  wire [1:0]  ct0, ct1;
  wire [19:0] of0, of1;
  wire [3:0]  pt0, pt1;
  wire        up0, up1;
  wire        uf0, uf1;

  SplittedSRAMTemplate_24 array (
    .clock(clock), .reset(reset),
    .io_r_req_ready(io_r_req_ready),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(raddr),
    .io_r_resp_data_0_valid(v0), .io_r_resp_data_0_tag(tg0), .io_r_resp_data_0_ctr(ct0),
    .io_r_resp_data_0_target_offset_offset(of0),
    .io_r_resp_data_0_target_offset_pointer(pt0),
    .io_r_resp_data_0_target_offset_usePCRegion(up0), .io_r_resp_data_0_useful(uf0),
    .io_r_resp_data_1_valid(v1), .io_r_resp_data_1_tag(tg1), .io_r_resp_data_1_ctr(ct1),
    .io_r_resp_data_1_target_offset_offset(of1),
    .io_r_resp_data_1_target_offset_pointer(pt1),
    .io_r_resp_data_1_target_offset_usePCRegion(up1), .io_r_resp_data_1_useful(uf1),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(waddr),
    // 两组写同一份数据，靠 waymask 选组
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
    .io_w_req_bits_waymask(2'h1 << w_group),  // 只写 w_group 这一折叠组
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
    .sigFromSrams_bore_ram_hold(sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass(sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen(sigFromSrams_bore_cgen)
  );

  // 读输出：holdRidx 选组（0→way0，1→way1）
  assign io_r_resp_data_0_valid                     = holdRidx ? v1  : v0;
  assign io_r_resp_data_0_tag                       = holdRidx ? tg1 : tg0;
  assign io_r_resp_data_0_ctr                       = holdRidx ? ct1 : ct0;
  assign io_r_resp_data_0_target_offset_offset      = holdRidx ? of1 : of0;
  assign io_r_resp_data_0_target_offset_pointer     = holdRidx ? pt1 : pt0;
  assign io_r_resp_data_0_target_offset_usePCRegion = holdRidx ? up1 : up0;
  assign io_r_resp_data_0_useful                    = holdRidx ? uf1 : uf0;
endmodule

// -----------------------------------------------------------------------------
// FoldedSRAMTemplate_23 —— width=4，逻辑 512set×1way×38b（ITTAGE）
//   折叠到内层 SplittedSRAMTemplate_26（128set×4way×38b，内层还 dataSplit=2）。
//   raddr = setIdx[8:2]，ridx = setIdx[1:0]（4 个折叠组），物理 4 路 = 4 组 × 1 逻辑路。
//   单逻辑 way、单 lane → 一套 ridx 保持；4 路读出按 holdRidx 四选一。双 bore 透传。
//   是「折叠 + 内层 dataSplit + bitmask」的组合范例。
// -----------------------------------------------------------------------------
module FoldedSRAMTemplate_23(
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

// =============================================================================
// FoldedSRAMTemplate_20 —— 折叠 SRAM：逻辑 2048row×2way×2bit，折叠系数 WIDTH=4
//   → 内层 SplittedSRAMTemplate_23(512set×8way×2bit)。TageBTable 的存储。
// 折叠：逻辑 setIdx[10:0] 拆成「内层 set=setIdx[10:2]」+「折叠组 group=setIdx[1:0]」。
//   2 逻辑 way × 4 折叠组 = 8 物理 way，物理 way 编号 = 2*group + 逻辑way。
//   读延迟 1 拍 → 把 group 寄存成 holdRidx，下一拍据此从 8 路读出里选 2 路。
// 内层 Splitted_23 为已验证子模块（FM 当黑盒），它本身又是 setSplit=2 的双 bank，
//   故有 2 套 bore/sig，全部透传。
// =============================================================================
module FoldedSRAMTemplate_20(
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
