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

// G1 重编号: 上轮名 FoldedSRAMTemplate_21 → 本轮 FoldedSRAMTemplate_22（含其例化的内层名同步改）
module FoldedSRAMTemplate_22(
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

  SplittedSRAMTemplate_25 array (
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
// FoldedSRAMTemplate_24 —— width=4，逻辑 512set×1way×38b（ITTAGE）
//   折叠到内层 SplittedSRAMTemplate_27（128set×4way×38b，内层还 dataSplit=2）。
//   raddr = setIdx[8:2]，ridx = setIdx[1:0]（4 个折叠组），物理 4 路 = 4 组 × 1 逻辑路。
//   单逻辑 way、单 lane → 一套 ridx 保持；4 路读出按 holdRidx 四选一。双 bore 透传。
//   是「折叠 + 内层 dataSplit + bitmask」的组合范例。
// -----------------------------------------------------------------------------
