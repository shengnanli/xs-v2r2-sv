// SplittedSRAMTemplate_3 —— SplittedSRAMTemplate 家族变体
// 家族共性（结构原理、保持逻辑、与内层的关系）见 SplittedSRAMTemplate.sv 文件头；
// 本文件只放本变体的参数与端口。

module SplittedSRAMTemplate_3(
  input         clock,
  input         reset,
  output        io_r_req_ready,
  input         io_r_req_valid,
  input  [7:0]  io_r_req_bits_setIdx,
  output        io_r_resp_data_0,  output io_r_resp_data_1,
  output        io_r_resp_data_2,  output io_r_resp_data_3,
  output        io_r_resp_data_4,  output io_r_resp_data_5,
  output        io_r_resp_data_6,  output io_r_resp_data_7,
  output        io_r_resp_data_8,  output io_r_resp_data_9,
  output        io_r_resp_data_10, output io_r_resp_data_11,
  output        io_r_resp_data_12, output io_r_resp_data_13,
  output        io_r_resp_data_14, output io_r_resp_data_15,
  input         io_w_req_valid,
  input  [7:0]  io_w_req_bits_setIdx,
  input         io_w_req_bits_data_0,  input io_w_req_bits_data_1,
  input         io_w_req_bits_data_2,  input io_w_req_bits_data_3,
  input         io_w_req_bits_data_4,  input io_w_req_bits_data_5,
  input         io_w_req_bits_data_6,  input io_w_req_bits_data_7,
  input         io_w_req_bits_data_8,  input io_w_req_bits_data_9,
  input         io_w_req_bits_data_10, input io_w_req_bits_data_11,
  input         io_w_req_bits_data_12, input io_w_req_bits_data_13,
  input         io_w_req_bits_data_14, input io_w_req_bits_data_15,
  input  [15:0] io_w_req_bits_waymask,
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
  // 1:1 透传到唯一内层（无拆分）
  SRAMTemplate_44 array_0_0_0 (
    .clock(clock), .reset(reset),
    .io_r_req_ready(io_r_req_ready),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data_0(io_r_resp_data_0),   .io_r_resp_data_1(io_r_resp_data_1),
    .io_r_resp_data_2(io_r_resp_data_2),   .io_r_resp_data_3(io_r_resp_data_3),
    .io_r_resp_data_4(io_r_resp_data_4),   .io_r_resp_data_5(io_r_resp_data_5),
    .io_r_resp_data_6(io_r_resp_data_6),   .io_r_resp_data_7(io_r_resp_data_7),
    .io_r_resp_data_8(io_r_resp_data_8),   .io_r_resp_data_9(io_r_resp_data_9),
    .io_r_resp_data_10(io_r_resp_data_10), .io_r_resp_data_11(io_r_resp_data_11),
    .io_r_resp_data_12(io_r_resp_data_12), .io_r_resp_data_13(io_r_resp_data_13),
    .io_r_resp_data_14(io_r_resp_data_14), .io_r_resp_data_15(io_r_resp_data_15),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data_0(io_w_req_bits_data_0),   .io_w_req_bits_data_1(io_w_req_bits_data_1),
    .io_w_req_bits_data_2(io_w_req_bits_data_2),   .io_w_req_bits_data_3(io_w_req_bits_data_3),
    .io_w_req_bits_data_4(io_w_req_bits_data_4),   .io_w_req_bits_data_5(io_w_req_bits_data_5),
    .io_w_req_bits_data_6(io_w_req_bits_data_6),   .io_w_req_bits_data_7(io_w_req_bits_data_7),
    .io_w_req_bits_data_8(io_w_req_bits_data_8),   .io_w_req_bits_data_9(io_w_req_bits_data_9),
    .io_w_req_bits_data_10(io_w_req_bits_data_10), .io_w_req_bits_data_11(io_w_req_bits_data_11),
    .io_w_req_bits_data_12(io_w_req_bits_data_12), .io_w_req_bits_data_13(io_w_req_bits_data_13),
    .io_w_req_bits_data_14(io_w_req_bits_data_14), .io_w_req_bits_data_15(io_w_req_bits_data_15),
    .io_w_req_bits_waymask(io_w_req_bits_waymask),
    .io_broadcast_ram_hold(sigFromSrams_bore_ram_hold),
    .io_broadcast_ram_bypass(sigFromSrams_bore_ram_bypass),
    .io_broadcast_ram_bp_clken(sigFromSrams_bore_ram_bp_clken),
    .io_broadcast_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp),
    .io_broadcast_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .io_broadcast_ram_ctl(64'h0), .io_broadcast_cgen(sigFromSrams_bore_cgen),
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
    .boreChildrenBd_bore_array(boreChildrenBd_bore_array)
  );
endmodule

// =============================================================================
// SplittedSRAMTemplate_4 —— TAGE 表：dataSplit=1，struct{valid,tag,ctr} 打包
//
// 逻辑 512set×2way×12b（TAGE 表条目 = valid(1)+tag(8)+ctr(3)）。waySplit=1，
// 整个逻辑 SRAM 是一个 SRAMTemplate_45（512×2×12）。Splitted 层在此只做
// struct↔扁平位 的打包/解包：
//   写：每路打包成 {valid=1'b1, tag[7:0], ctr[2:0]}（写入即有效，valid 恒 1）
//   读：拆回 valid=[11], tag=[10:3], ctr=[2:0]
// 「写时 valid 硬连 1」是 TAGE 的设计：分配一条目即视为有效。
// =============================================================================
