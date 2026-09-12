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
// FoldedSRAMTemplate_22 —— width=2，逻辑 256set×1way×38b（ITTAGE）
//   折叠到内层 SplittedSRAMTemplate_25（128set×2way×38b）。
//   raddr = setIdx[7:1]，ridx = setIdx[0]（2 个折叠组），物理 2 路 = 2 组 × 1 逻辑路。
//   单逻辑 way，单 lane → 一套 ridx 保持。带逐位 bitmask 透传。
// -----------------------------------------------------------------------------
