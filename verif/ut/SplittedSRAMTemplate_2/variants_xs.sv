module SplittedSRAMTemplate_2_xs(
  input         clock,
  input         reset,
  output        io_r_req_ready,
  input         io_r_req_valid,
  input  [8:0]  io_r_req_bits_setIdx,
  output        io_r_resp_data_0_entry_isCall,
  output        io_r_resp_data_0_entry_isRet,
  output        io_r_resp_data_0_entry_isJalr,
  output        io_r_resp_data_0_entry_valid,
  output [3:0]  io_r_resp_data_0_entry_brSlots_0_offset,
  output        io_r_resp_data_0_entry_brSlots_0_sharing,
  output        io_r_resp_data_0_entry_brSlots_0_valid,
  output [11:0] io_r_resp_data_0_entry_brSlots_0_lower,
  output [1:0]  io_r_resp_data_0_entry_brSlots_0_tarStat,
  output [3:0]  io_r_resp_data_0_entry_tailSlot_offset,
  output        io_r_resp_data_0_entry_tailSlot_sharing,
  output        io_r_resp_data_0_entry_tailSlot_valid,
  output [19:0] io_r_resp_data_0_entry_tailSlot_lower,
  output [1:0]  io_r_resp_data_0_entry_tailSlot_tarStat,
  output [3:0]  io_r_resp_data_0_entry_pftAddr,
  output        io_r_resp_data_0_entry_carry,
  output        io_r_resp_data_0_entry_last_may_be_rvi_call,
  output        io_r_resp_data_0_entry_strong_bias_0,
  output        io_r_resp_data_0_entry_strong_bias_1,
  output [19:0] io_r_resp_data_0_tag,
  output        io_r_resp_data_1_entry_isCall,
  output        io_r_resp_data_1_entry_isRet,
  output        io_r_resp_data_1_entry_isJalr,
  output        io_r_resp_data_1_entry_valid,
  output [3:0]  io_r_resp_data_1_entry_brSlots_0_offset,
  output        io_r_resp_data_1_entry_brSlots_0_sharing,
  output        io_r_resp_data_1_entry_brSlots_0_valid,
  output [11:0] io_r_resp_data_1_entry_brSlots_0_lower,
  output [1:0]  io_r_resp_data_1_entry_brSlots_0_tarStat,
  output [3:0]  io_r_resp_data_1_entry_tailSlot_offset,
  output        io_r_resp_data_1_entry_tailSlot_sharing,
  output        io_r_resp_data_1_entry_tailSlot_valid,
  output [19:0] io_r_resp_data_1_entry_tailSlot_lower,
  output [1:0]  io_r_resp_data_1_entry_tailSlot_tarStat,
  output [3:0]  io_r_resp_data_1_entry_pftAddr,
  output        io_r_resp_data_1_entry_carry,
  output        io_r_resp_data_1_entry_last_may_be_rvi_call,
  output        io_r_resp_data_1_entry_strong_bias_0,
  output        io_r_resp_data_1_entry_strong_bias_1,
  output [19:0] io_r_resp_data_1_tag,
  output        io_r_resp_data_2_entry_isCall,
  output        io_r_resp_data_2_entry_isRet,
  output        io_r_resp_data_2_entry_isJalr,
  output        io_r_resp_data_2_entry_valid,
  output [3:0]  io_r_resp_data_2_entry_brSlots_0_offset,
  output        io_r_resp_data_2_entry_brSlots_0_sharing,
  output        io_r_resp_data_2_entry_brSlots_0_valid,
  output [11:0] io_r_resp_data_2_entry_brSlots_0_lower,
  output [1:0]  io_r_resp_data_2_entry_brSlots_0_tarStat,
  output [3:0]  io_r_resp_data_2_entry_tailSlot_offset,
  output        io_r_resp_data_2_entry_tailSlot_sharing,
  output        io_r_resp_data_2_entry_tailSlot_valid,
  output [19:0] io_r_resp_data_2_entry_tailSlot_lower,
  output [1:0]  io_r_resp_data_2_entry_tailSlot_tarStat,
  output [3:0]  io_r_resp_data_2_entry_pftAddr,
  output        io_r_resp_data_2_entry_carry,
  output        io_r_resp_data_2_entry_last_may_be_rvi_call,
  output        io_r_resp_data_2_entry_strong_bias_0,
  output        io_r_resp_data_2_entry_strong_bias_1,
  output [19:0] io_r_resp_data_2_tag,
  output        io_r_resp_data_3_entry_isCall,
  output        io_r_resp_data_3_entry_isRet,
  output        io_r_resp_data_3_entry_isJalr,
  output        io_r_resp_data_3_entry_valid,
  output [3:0]  io_r_resp_data_3_entry_brSlots_0_offset,
  output        io_r_resp_data_3_entry_brSlots_0_sharing,
  output        io_r_resp_data_3_entry_brSlots_0_valid,
  output [11:0] io_r_resp_data_3_entry_brSlots_0_lower,
  output [1:0]  io_r_resp_data_3_entry_brSlots_0_tarStat,
  output [3:0]  io_r_resp_data_3_entry_tailSlot_offset,
  output        io_r_resp_data_3_entry_tailSlot_sharing,
  output        io_r_resp_data_3_entry_tailSlot_valid,
  output [19:0] io_r_resp_data_3_entry_tailSlot_lower,
  output [1:0]  io_r_resp_data_3_entry_tailSlot_tarStat,
  output [3:0]  io_r_resp_data_3_entry_pftAddr,
  output        io_r_resp_data_3_entry_carry,
  output        io_r_resp_data_3_entry_last_may_be_rvi_call,
  output        io_r_resp_data_3_entry_strong_bias_0,
  output        io_r_resp_data_3_entry_strong_bias_1,
  output [19:0] io_r_resp_data_3_tag,
  input         io_w_req_valid,
  input  [8:0]  io_w_req_bits_setIdx,
  input         io_w_req_bits_data_0_entry_isCall,
  input         io_w_req_bits_data_0_entry_isRet,
  input         io_w_req_bits_data_0_entry_isJalr,
  input         io_w_req_bits_data_0_entry_valid,
  input  [3:0]  io_w_req_bits_data_0_entry_brSlots_0_offset,
  input         io_w_req_bits_data_0_entry_brSlots_0_sharing,
  input         io_w_req_bits_data_0_entry_brSlots_0_valid,
  input  [11:0] io_w_req_bits_data_0_entry_brSlots_0_lower,
  input  [1:0]  io_w_req_bits_data_0_entry_brSlots_0_tarStat,
  input  [3:0]  io_w_req_bits_data_0_entry_tailSlot_offset,
  input         io_w_req_bits_data_0_entry_tailSlot_sharing,
  input         io_w_req_bits_data_0_entry_tailSlot_valid,
  input  [19:0] io_w_req_bits_data_0_entry_tailSlot_lower,
  input  [1:0]  io_w_req_bits_data_0_entry_tailSlot_tarStat,
  input  [3:0]  io_w_req_bits_data_0_entry_pftAddr,
  input         io_w_req_bits_data_0_entry_carry,
  input         io_w_req_bits_data_0_entry_last_may_be_rvi_call,
  input         io_w_req_bits_data_0_entry_strong_bias_0,
  input         io_w_req_bits_data_0_entry_strong_bias_1,
  input  [19:0] io_w_req_bits_data_0_tag,
  input         io_w_req_bits_data_1_entry_isCall,
  input         io_w_req_bits_data_1_entry_isRet,
  input         io_w_req_bits_data_1_entry_isJalr,
  input         io_w_req_bits_data_1_entry_valid,
  input  [3:0]  io_w_req_bits_data_1_entry_brSlots_0_offset,
  input         io_w_req_bits_data_1_entry_brSlots_0_sharing,
  input         io_w_req_bits_data_1_entry_brSlots_0_valid,
  input  [11:0] io_w_req_bits_data_1_entry_brSlots_0_lower,
  input  [1:0]  io_w_req_bits_data_1_entry_brSlots_0_tarStat,
  input  [3:0]  io_w_req_bits_data_1_entry_tailSlot_offset,
  input         io_w_req_bits_data_1_entry_tailSlot_sharing,
  input         io_w_req_bits_data_1_entry_tailSlot_valid,
  input  [19:0] io_w_req_bits_data_1_entry_tailSlot_lower,
  input  [1:0]  io_w_req_bits_data_1_entry_tailSlot_tarStat,
  input  [3:0]  io_w_req_bits_data_1_entry_pftAddr,
  input         io_w_req_bits_data_1_entry_carry,
  input         io_w_req_bits_data_1_entry_last_may_be_rvi_call,
  input         io_w_req_bits_data_1_entry_strong_bias_0,
  input         io_w_req_bits_data_1_entry_strong_bias_1,
  input  [19:0] io_w_req_bits_data_1_tag,
  input         io_w_req_bits_data_2_entry_isCall,
  input         io_w_req_bits_data_2_entry_isRet,
  input         io_w_req_bits_data_2_entry_isJalr,
  input         io_w_req_bits_data_2_entry_valid,
  input  [3:0]  io_w_req_bits_data_2_entry_brSlots_0_offset,
  input         io_w_req_bits_data_2_entry_brSlots_0_sharing,
  input         io_w_req_bits_data_2_entry_brSlots_0_valid,
  input  [11:0] io_w_req_bits_data_2_entry_brSlots_0_lower,
  input  [1:0]  io_w_req_bits_data_2_entry_brSlots_0_tarStat,
  input  [3:0]  io_w_req_bits_data_2_entry_tailSlot_offset,
  input         io_w_req_bits_data_2_entry_tailSlot_sharing,
  input         io_w_req_bits_data_2_entry_tailSlot_valid,
  input  [19:0] io_w_req_bits_data_2_entry_tailSlot_lower,
  input  [1:0]  io_w_req_bits_data_2_entry_tailSlot_tarStat,
  input  [3:0]  io_w_req_bits_data_2_entry_pftAddr,
  input         io_w_req_bits_data_2_entry_carry,
  input         io_w_req_bits_data_2_entry_last_may_be_rvi_call,
  input         io_w_req_bits_data_2_entry_strong_bias_0,
  input         io_w_req_bits_data_2_entry_strong_bias_1,
  input  [19:0] io_w_req_bits_data_2_tag,
  input         io_w_req_bits_data_3_entry_isCall,
  input         io_w_req_bits_data_3_entry_isRet,
  input         io_w_req_bits_data_3_entry_isJalr,
  input         io_w_req_bits_data_3_entry_valid,
  input  [3:0]  io_w_req_bits_data_3_entry_brSlots_0_offset,
  input         io_w_req_bits_data_3_entry_brSlots_0_sharing,
  input         io_w_req_bits_data_3_entry_brSlots_0_valid,
  input  [11:0] io_w_req_bits_data_3_entry_brSlots_0_lower,
  input  [1:0]  io_w_req_bits_data_3_entry_brSlots_0_tarStat,
  input  [3:0]  io_w_req_bits_data_3_entry_tailSlot_offset,
  input         io_w_req_bits_data_3_entry_tailSlot_sharing,
  input         io_w_req_bits_data_3_entry_tailSlot_valid,
  input  [19:0] io_w_req_bits_data_3_entry_tailSlot_lower,
  input  [1:0]  io_w_req_bits_data_3_entry_tailSlot_tarStat,
  input  [3:0]  io_w_req_bits_data_3_entry_pftAddr,
  input         io_w_req_bits_data_3_entry_carry,
  input         io_w_req_bits_data_3_entry_last_may_be_rvi_call,
  input         io_w_req_bits_data_3_entry_strong_bias_0,
  input         io_w_req_bits_data_3_entry_strong_bias_1,
  input  [19:0] io_w_req_bits_data_3_tag,
  input  [3:0]  io_w_req_bits_waymask,
  input  [9:0]  boreChildrenBd_bore_addr,
  input  [9:0]  boreChildrenBd_bore_addr_rd,
  input  [39:0] boreChildrenBd_bore_wdata,
  input  [3:0]  boreChildrenBd_bore_wmask,
  input         boreChildrenBd_bore_re,
  input         boreChildrenBd_bore_we,
  output [39:0] boreChildrenBd_bore_rdata,
  input         boreChildrenBd_bore_ack,
  input         boreChildrenBd_bore_selectedOH,
  input  [5:0]  boreChildrenBd_bore_array,
  input  [9:0]  boreChildrenBd_bore_1_addr,
  input  [9:0]  boreChildrenBd_bore_1_addr_rd,
  input  [39:0] boreChildrenBd_bore_1_wdata,
  input  [3:0]  boreChildrenBd_bore_1_wmask,
  input         boreChildrenBd_bore_1_re,
  input         boreChildrenBd_bore_1_we,
  output [39:0] boreChildrenBd_bore_1_rdata,
  input         boreChildrenBd_bore_1_ack,
  input         boreChildrenBd_bore_1_selectedOH,
  input  [5:0]  boreChildrenBd_bore_1_array,
  input  [9:0]  boreChildrenBd_bore_2_addr,
  input  [9:0]  boreChildrenBd_bore_2_addr_rd,
  input  [39:0] boreChildrenBd_bore_2_wdata,
  input  [3:0]  boreChildrenBd_bore_2_wmask,
  input         boreChildrenBd_bore_2_re,
  input         boreChildrenBd_bore_2_we,
  output [39:0] boreChildrenBd_bore_2_rdata,
  input         boreChildrenBd_bore_2_ack,
  input         boreChildrenBd_bore_2_selectedOH,
  input  [5:0]  boreChildrenBd_bore_2_array,
  input  [9:0]  boreChildrenBd_bore_3_addr,
  input  [9:0]  boreChildrenBd_bore_3_addr_rd,
  input  [39:0] boreChildrenBd_bore_3_wdata,
  input  [3:0]  boreChildrenBd_bore_3_wmask,
  input         boreChildrenBd_bore_3_re,
  input         boreChildrenBd_bore_3_we,
  output [39:0] boreChildrenBd_bore_3_rdata,
  input         boreChildrenBd_bore_3_ack,
  input         boreChildrenBd_bore_3_selectedOH,
  input  [5:0]  boreChildrenBd_bore_3_array,
  input  [9:0]  boreChildrenBd_bore_4_addr,
  input  [9:0]  boreChildrenBd_bore_4_addr_rd,
  input  [39:0] boreChildrenBd_bore_4_wdata,
  input  [3:0]  boreChildrenBd_bore_4_wmask,
  input         boreChildrenBd_bore_4_re,
  input         boreChildrenBd_bore_4_we,
  output [39:0] boreChildrenBd_bore_4_rdata,
  input         boreChildrenBd_bore_4_ack,
  input         boreChildrenBd_bore_4_selectedOH,
  input  [5:0]  boreChildrenBd_bore_4_array,
  input  [9:0]  boreChildrenBd_bore_5_addr,
  input  [9:0]  boreChildrenBd_bore_5_addr_rd,
  input  [39:0] boreChildrenBd_bore_5_wdata,
  input  [3:0]  boreChildrenBd_bore_5_wmask,
  input         boreChildrenBd_bore_5_re,
  input         boreChildrenBd_bore_5_we,
  output [39:0] boreChildrenBd_bore_5_rdata,
  input         boreChildrenBd_bore_5_ack,
  input         boreChildrenBd_bore_5_selectedOH,
  input  [5:0]  boreChildrenBd_bore_5_array,
  input  [9:0]  boreChildrenBd_bore_6_addr,
  input  [9:0]  boreChildrenBd_bore_6_addr_rd,
  input  [39:0] boreChildrenBd_bore_6_wdata,
  input  [3:0]  boreChildrenBd_bore_6_wmask,
  input         boreChildrenBd_bore_6_re,
  input         boreChildrenBd_bore_6_we,
  output [39:0] boreChildrenBd_bore_6_rdata,
  input         boreChildrenBd_bore_6_ack,
  input         boreChildrenBd_bore_6_selectedOH,
  input  [5:0]  boreChildrenBd_bore_6_array,
  input  [9:0]  boreChildrenBd_bore_7_addr,
  input  [9:0]  boreChildrenBd_bore_7_addr_rd,
  input  [39:0] boreChildrenBd_bore_7_wdata,
  input  [3:0]  boreChildrenBd_bore_7_wmask,
  input         boreChildrenBd_bore_7_re,
  input         boreChildrenBd_bore_7_we,
  output [39:0] boreChildrenBd_bore_7_rdata,
  input         boreChildrenBd_bore_7_ack,
  input         boreChildrenBd_bore_7_selectedOH,
  input  [5:0]  boreChildrenBd_bore_7_array,
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
  input         sigFromSrams_bore_1_cgen,
  input         sigFromSrams_bore_2_ram_hold,
  input         sigFromSrams_bore_2_ram_bypass,
  input         sigFromSrams_bore_2_ram_bp_clken,
  input         sigFromSrams_bore_2_ram_aux_clk,
  input         sigFromSrams_bore_2_ram_aux_ckbp,
  input         sigFromSrams_bore_2_ram_mcp_hold,
  input         sigFromSrams_bore_2_cgen,
  input         sigFromSrams_bore_3_ram_hold,
  input         sigFromSrams_bore_3_ram_bypass,
  input         sigFromSrams_bore_3_ram_bp_clken,
  input         sigFromSrams_bore_3_ram_aux_clk,
  input         sigFromSrams_bore_3_ram_aux_ckbp,
  input         sigFromSrams_bore_3_ram_mcp_hold,
  input         sigFromSrams_bore_3_cgen,
  input         sigFromSrams_bore_4_ram_hold,
  input         sigFromSrams_bore_4_ram_bypass,
  input         sigFromSrams_bore_4_ram_bp_clken,
  input         sigFromSrams_bore_4_ram_aux_clk,
  input         sigFromSrams_bore_4_ram_aux_ckbp,
  input         sigFromSrams_bore_4_ram_mcp_hold,
  input         sigFromSrams_bore_4_cgen,
  input         sigFromSrams_bore_5_ram_hold,
  input         sigFromSrams_bore_5_ram_bypass,
  input         sigFromSrams_bore_5_ram_bp_clken,
  input         sigFromSrams_bore_5_ram_aux_clk,
  input         sigFromSrams_bore_5_ram_aux_ckbp,
  input         sigFromSrams_bore_5_ram_mcp_hold,
  input         sigFromSrams_bore_5_cgen,
  input         sigFromSrams_bore_6_ram_hold,
  input         sigFromSrams_bore_6_ram_bypass,
  input         sigFromSrams_bore_6_ram_bp_clken,
  input         sigFromSrams_bore_6_ram_aux_clk,
  input         sigFromSrams_bore_6_ram_aux_ckbp,
  input         sigFromSrams_bore_6_ram_mcp_hold,
  input         sigFromSrams_bore_6_cgen,
  input         sigFromSrams_bore_7_ram_hold,
  input         sigFromSrams_bore_7_ram_bypass,
  input         sigFromSrams_bore_7_ram_bp_clken,
  input         sigFromSrams_bore_7_ram_aux_clk,
  input         sigFromSrams_bore_7_ram_aux_ckbp,
  input         sigFromSrams_bore_7_ram_mcp_hold,
  input         sigFromSrams_bore_7_cgen
);
  // 8 个物理 SRAM，每个 4 way × 10b。di[g][w] = group g 的 way w 读出。
  wire [9:0] d0_0,d0_1,d0_2,d0_3;  // array_0_0_0 : tag[9:0]
  wire [9:0] d1_0,d1_1,d1_2,d1_3;  // array_0_0_1 : tag[19:10]
  wire [9:0] d2_0,d2_1,d2_2,d2_3;  // array_0_0_2 : tailSlot_tarStat..strong_bias
  wire [9:0] d3_0,d3_1,d3_2,d3_3;  // array_0_0_3 : tailSlot_lower[9:0]
  wire [9:0] d4_0,d4_1,d4_2,d4_3;  // array_0_0_4 : tailSlot_lower[19:10]
  wire [9:0] d5_0,d5_1,d5_2,d5_3;  // array_0_0_5 : brSlots_0_lower[1:0]..tailSlot_valid
  wire [9:0] d6_0,d6_1,d6_2,d6_3;  // array_0_0_6 : brSlots_0_lower[11:2]
  wire [9:0] d7_0,d7_1,d7_2,d7_3;  // array_0_0_7 : isCall..brSlots_0_valid

  SRAMTemplate_36 array_0_0_0 (
    .clock(clock), .reset(reset), .io_r_req_ready(io_r_req_ready),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data_0(d0_0), .io_r_resp_data_1(d0_1), .io_r_resp_data_2(d0_2), .io_r_resp_data_3(d0_3),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data_0(io_w_req_bits_data_0_tag[9:0]),
    .io_w_req_bits_data_1(io_w_req_bits_data_1_tag[9:0]),
    .io_w_req_bits_data_2(io_w_req_bits_data_2_tag[9:0]),
    .io_w_req_bits_data_3(io_w_req_bits_data_3_tag[9:0]),
    .io_w_req_bits_waymask(io_w_req_bits_waymask),
    .io_broadcast_ram_hold(sigFromSrams_bore_ram_hold), .io_broadcast_ram_bypass(sigFromSrams_bore_ram_bypass),
    .io_broadcast_ram_bp_clken(sigFromSrams_bore_ram_bp_clken), .io_broadcast_ram_aux_clk(sigFromSrams_bore_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp(sigFromSrams_bore_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(sigFromSrams_bore_ram_mcp_hold),
    .io_broadcast_ram_ctl(64'h0), .io_broadcast_cgen(sigFromSrams_bore_cgen),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr), .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_wdata(boreChildrenBd_bore_wdata), .boreChildrenBd_bore_wmask(boreChildrenBd_bore_wmask),
    .boreChildrenBd_bore_re(boreChildrenBd_bore_re), .boreChildrenBd_bore_we(boreChildrenBd_bore_we),
    .boreChildrenBd_bore_rdata(boreChildrenBd_bore_rdata), .boreChildrenBd_bore_ack(boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_selectedOH(boreChildrenBd_bore_selectedOH), .boreChildrenBd_bore_array(boreChildrenBd_bore_array)
  );
  SRAMTemplate_36 array_0_0_1 (
    .clock(clock), .reset(reset), .io_r_req_ready(/* unused */),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data_0(d1_0), .io_r_resp_data_1(d1_1), .io_r_resp_data_2(d1_2), .io_r_resp_data_3(d1_3),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data_0(io_w_req_bits_data_0_tag[19:10]),
    .io_w_req_bits_data_1(io_w_req_bits_data_1_tag[19:10]),
    .io_w_req_bits_data_2(io_w_req_bits_data_2_tag[19:10]),
    .io_w_req_bits_data_3(io_w_req_bits_data_3_tag[19:10]),
    .io_w_req_bits_waymask(io_w_req_bits_waymask),
    .io_broadcast_ram_hold(sigFromSrams_bore_1_ram_hold), .io_broadcast_ram_bypass(sigFromSrams_bore_1_ram_bypass),
    .io_broadcast_ram_bp_clken(sigFromSrams_bore_1_ram_bp_clken), .io_broadcast_ram_aux_clk(sigFromSrams_bore_1_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp(sigFromSrams_bore_1_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(sigFromSrams_bore_1_ram_mcp_hold),
    .io_broadcast_ram_ctl(64'h0), .io_broadcast_cgen(sigFromSrams_bore_1_cgen),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_1_addr), .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_wdata(boreChildrenBd_bore_1_wdata), .boreChildrenBd_bore_wmask(boreChildrenBd_bore_1_wmask),
    .boreChildrenBd_bore_re(boreChildrenBd_bore_1_re), .boreChildrenBd_bore_we(boreChildrenBd_bore_1_we),
    .boreChildrenBd_bore_rdata(boreChildrenBd_bore_1_rdata), .boreChildrenBd_bore_ack(boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_selectedOH(boreChildrenBd_bore_1_selectedOH), .boreChildrenBd_bore_array(boreChildrenBd_bore_1_array)
  );
  SRAMTemplate_36 array_0_0_2 (
    .clock(clock), .reset(reset), .io_r_req_ready(/* unused */),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data_0(d2_0), .io_r_resp_data_1(d2_1), .io_r_resp_data_2(d2_2), .io_r_resp_data_3(d2_3),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data_0({io_w_req_bits_data_0_entry_tailSlot_tarStat, io_w_req_bits_data_0_entry_pftAddr,
      io_w_req_bits_data_0_entry_carry, io_w_req_bits_data_0_entry_last_may_be_rvi_call,
      io_w_req_bits_data_0_entry_strong_bias_1, io_w_req_bits_data_0_entry_strong_bias_0}),
    .io_w_req_bits_data_1({io_w_req_bits_data_1_entry_tailSlot_tarStat, io_w_req_bits_data_1_entry_pftAddr,
      io_w_req_bits_data_1_entry_carry, io_w_req_bits_data_1_entry_last_may_be_rvi_call,
      io_w_req_bits_data_1_entry_strong_bias_1, io_w_req_bits_data_1_entry_strong_bias_0}),
    .io_w_req_bits_data_2({io_w_req_bits_data_2_entry_tailSlot_tarStat, io_w_req_bits_data_2_entry_pftAddr,
      io_w_req_bits_data_2_entry_carry, io_w_req_bits_data_2_entry_last_may_be_rvi_call,
      io_w_req_bits_data_2_entry_strong_bias_1, io_w_req_bits_data_2_entry_strong_bias_0}),
    .io_w_req_bits_data_3({io_w_req_bits_data_3_entry_tailSlot_tarStat, io_w_req_bits_data_3_entry_pftAddr,
      io_w_req_bits_data_3_entry_carry, io_w_req_bits_data_3_entry_last_may_be_rvi_call,
      io_w_req_bits_data_3_entry_strong_bias_1, io_w_req_bits_data_3_entry_strong_bias_0}),
    .io_w_req_bits_waymask(io_w_req_bits_waymask),
    .io_broadcast_ram_hold(sigFromSrams_bore_2_ram_hold), .io_broadcast_ram_bypass(sigFromSrams_bore_2_ram_bypass),
    .io_broadcast_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken), .io_broadcast_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold),
    .io_broadcast_ram_ctl(64'h0), .io_broadcast_cgen(sigFromSrams_bore_2_cgen),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_2_addr), .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_wdata(boreChildrenBd_bore_2_wdata), .boreChildrenBd_bore_wmask(boreChildrenBd_bore_2_wmask),
    .boreChildrenBd_bore_re(boreChildrenBd_bore_2_re), .boreChildrenBd_bore_we(boreChildrenBd_bore_2_we),
    .boreChildrenBd_bore_rdata(boreChildrenBd_bore_2_rdata), .boreChildrenBd_bore_ack(boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_selectedOH(boreChildrenBd_bore_2_selectedOH), .boreChildrenBd_bore_array(boreChildrenBd_bore_2_array)
  );
  SRAMTemplate_36 array_0_0_3 (
    .clock(clock), .reset(reset), .io_r_req_ready(/* unused */),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data_0(d3_0), .io_r_resp_data_1(d3_1), .io_r_resp_data_2(d3_2), .io_r_resp_data_3(d3_3),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data_0(io_w_req_bits_data_0_entry_tailSlot_lower[9:0]),
    .io_w_req_bits_data_1(io_w_req_bits_data_1_entry_tailSlot_lower[9:0]),
    .io_w_req_bits_data_2(io_w_req_bits_data_2_entry_tailSlot_lower[9:0]),
    .io_w_req_bits_data_3(io_w_req_bits_data_3_entry_tailSlot_lower[9:0]),
    .io_w_req_bits_waymask(io_w_req_bits_waymask),
    .io_broadcast_ram_hold(sigFromSrams_bore_3_ram_hold), .io_broadcast_ram_bypass(sigFromSrams_bore_3_ram_bypass),
    .io_broadcast_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken), .io_broadcast_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold),
    .io_broadcast_ram_ctl(64'h0), .io_broadcast_cgen(sigFromSrams_bore_3_cgen),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_3_addr), .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_wdata(boreChildrenBd_bore_3_wdata), .boreChildrenBd_bore_wmask(boreChildrenBd_bore_3_wmask),
    .boreChildrenBd_bore_re(boreChildrenBd_bore_3_re), .boreChildrenBd_bore_we(boreChildrenBd_bore_3_we),
    .boreChildrenBd_bore_rdata(boreChildrenBd_bore_3_rdata), .boreChildrenBd_bore_ack(boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_selectedOH(boreChildrenBd_bore_3_selectedOH), .boreChildrenBd_bore_array(boreChildrenBd_bore_3_array)
  );
  SRAMTemplate_36 array_0_0_4 (
    .clock(clock), .reset(reset), .io_r_req_ready(/* unused */),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data_0(d4_0), .io_r_resp_data_1(d4_1), .io_r_resp_data_2(d4_2), .io_r_resp_data_3(d4_3),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data_0(io_w_req_bits_data_0_entry_tailSlot_lower[19:10]),
    .io_w_req_bits_data_1(io_w_req_bits_data_1_entry_tailSlot_lower[19:10]),
    .io_w_req_bits_data_2(io_w_req_bits_data_2_entry_tailSlot_lower[19:10]),
    .io_w_req_bits_data_3(io_w_req_bits_data_3_entry_tailSlot_lower[19:10]),
    .io_w_req_bits_waymask(io_w_req_bits_waymask),
    .io_broadcast_ram_hold(sigFromSrams_bore_4_ram_hold), .io_broadcast_ram_bypass(sigFromSrams_bore_4_ram_bypass),
    .io_broadcast_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken), .io_broadcast_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold),
    .io_broadcast_ram_ctl(64'h0), .io_broadcast_cgen(sigFromSrams_bore_4_cgen),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_4_addr), .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_4_addr_rd),
    .boreChildrenBd_bore_wdata(boreChildrenBd_bore_4_wdata), .boreChildrenBd_bore_wmask(boreChildrenBd_bore_4_wmask),
    .boreChildrenBd_bore_re(boreChildrenBd_bore_4_re), .boreChildrenBd_bore_we(boreChildrenBd_bore_4_we),
    .boreChildrenBd_bore_rdata(boreChildrenBd_bore_4_rdata), .boreChildrenBd_bore_ack(boreChildrenBd_bore_4_ack),
    .boreChildrenBd_bore_selectedOH(boreChildrenBd_bore_4_selectedOH), .boreChildrenBd_bore_array(boreChildrenBd_bore_4_array)
  );
  SRAMTemplate_36 array_0_0_5 (
    .clock(clock), .reset(reset), .io_r_req_ready(/* unused */),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data_0(d5_0), .io_r_resp_data_1(d5_1), .io_r_resp_data_2(d5_2), .io_r_resp_data_3(d5_3),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data_0({io_w_req_bits_data_0_entry_brSlots_0_lower[1:0], io_w_req_bits_data_0_entry_brSlots_0_tarStat,
      io_w_req_bits_data_0_entry_tailSlot_offset, io_w_req_bits_data_0_entry_tailSlot_sharing, io_w_req_bits_data_0_entry_tailSlot_valid}),
    .io_w_req_bits_data_1({io_w_req_bits_data_1_entry_brSlots_0_lower[1:0], io_w_req_bits_data_1_entry_brSlots_0_tarStat,
      io_w_req_bits_data_1_entry_tailSlot_offset, io_w_req_bits_data_1_entry_tailSlot_sharing, io_w_req_bits_data_1_entry_tailSlot_valid}),
    .io_w_req_bits_data_2({io_w_req_bits_data_2_entry_brSlots_0_lower[1:0], io_w_req_bits_data_2_entry_brSlots_0_tarStat,
      io_w_req_bits_data_2_entry_tailSlot_offset, io_w_req_bits_data_2_entry_tailSlot_sharing, io_w_req_bits_data_2_entry_tailSlot_valid}),
    .io_w_req_bits_data_3({io_w_req_bits_data_3_entry_brSlots_0_lower[1:0], io_w_req_bits_data_3_entry_brSlots_0_tarStat,
      io_w_req_bits_data_3_entry_tailSlot_offset, io_w_req_bits_data_3_entry_tailSlot_sharing, io_w_req_bits_data_3_entry_tailSlot_valid}),
    .io_w_req_bits_waymask(io_w_req_bits_waymask),
    .io_broadcast_ram_hold(sigFromSrams_bore_5_ram_hold), .io_broadcast_ram_bypass(sigFromSrams_bore_5_ram_bypass),
    .io_broadcast_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken), .io_broadcast_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold),
    .io_broadcast_ram_ctl(64'h0), .io_broadcast_cgen(sigFromSrams_bore_5_cgen),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_5_addr), .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_5_addr_rd),
    .boreChildrenBd_bore_wdata(boreChildrenBd_bore_5_wdata), .boreChildrenBd_bore_wmask(boreChildrenBd_bore_5_wmask),
    .boreChildrenBd_bore_re(boreChildrenBd_bore_5_re), .boreChildrenBd_bore_we(boreChildrenBd_bore_5_we),
    .boreChildrenBd_bore_rdata(boreChildrenBd_bore_5_rdata), .boreChildrenBd_bore_ack(boreChildrenBd_bore_5_ack),
    .boreChildrenBd_bore_selectedOH(boreChildrenBd_bore_5_selectedOH), .boreChildrenBd_bore_array(boreChildrenBd_bore_5_array)
  );
  SRAMTemplate_36 array_0_0_6 (
    .clock(clock), .reset(reset), .io_r_req_ready(/* unused */),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data_0(d6_0), .io_r_resp_data_1(d6_1), .io_r_resp_data_2(d6_2), .io_r_resp_data_3(d6_3),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data_0(io_w_req_bits_data_0_entry_brSlots_0_lower[11:2]),
    .io_w_req_bits_data_1(io_w_req_bits_data_1_entry_brSlots_0_lower[11:2]),
    .io_w_req_bits_data_2(io_w_req_bits_data_2_entry_brSlots_0_lower[11:2]),
    .io_w_req_bits_data_3(io_w_req_bits_data_3_entry_brSlots_0_lower[11:2]),
    .io_w_req_bits_waymask(io_w_req_bits_waymask),
    .io_broadcast_ram_hold(sigFromSrams_bore_6_ram_hold), .io_broadcast_ram_bypass(sigFromSrams_bore_6_ram_bypass),
    .io_broadcast_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken), .io_broadcast_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold),
    .io_broadcast_ram_ctl(64'h0), .io_broadcast_cgen(sigFromSrams_bore_6_cgen),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_6_addr), .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_6_addr_rd),
    .boreChildrenBd_bore_wdata(boreChildrenBd_bore_6_wdata), .boreChildrenBd_bore_wmask(boreChildrenBd_bore_6_wmask),
    .boreChildrenBd_bore_re(boreChildrenBd_bore_6_re), .boreChildrenBd_bore_we(boreChildrenBd_bore_6_we),
    .boreChildrenBd_bore_rdata(boreChildrenBd_bore_6_rdata), .boreChildrenBd_bore_ack(boreChildrenBd_bore_6_ack),
    .boreChildrenBd_bore_selectedOH(boreChildrenBd_bore_6_selectedOH), .boreChildrenBd_bore_array(boreChildrenBd_bore_6_array)
  );
  SRAMTemplate_36 array_0_0_7 (
    .clock(clock), .reset(reset), .io_r_req_ready(/* unused */),
    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
    .io_r_resp_data_0(d7_0), .io_r_resp_data_1(d7_1), .io_r_resp_data_2(d7_2), .io_r_resp_data_3(d7_3),
    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
    .io_w_req_bits_data_0({io_w_req_bits_data_0_entry_isCall, io_w_req_bits_data_0_entry_isRet, io_w_req_bits_data_0_entry_isJalr,
      io_w_req_bits_data_0_entry_valid, io_w_req_bits_data_0_entry_brSlots_0_offset,
      io_w_req_bits_data_0_entry_brSlots_0_sharing, io_w_req_bits_data_0_entry_brSlots_0_valid}),
    .io_w_req_bits_data_1({io_w_req_bits_data_1_entry_isCall, io_w_req_bits_data_1_entry_isRet, io_w_req_bits_data_1_entry_isJalr,
      io_w_req_bits_data_1_entry_valid, io_w_req_bits_data_1_entry_brSlots_0_offset,
      io_w_req_bits_data_1_entry_brSlots_0_sharing, io_w_req_bits_data_1_entry_brSlots_0_valid}),
    .io_w_req_bits_data_2({io_w_req_bits_data_2_entry_isCall, io_w_req_bits_data_2_entry_isRet, io_w_req_bits_data_2_entry_isJalr,
      io_w_req_bits_data_2_entry_valid, io_w_req_bits_data_2_entry_brSlots_0_offset,
      io_w_req_bits_data_2_entry_brSlots_0_sharing, io_w_req_bits_data_2_entry_brSlots_0_valid}),
    .io_w_req_bits_data_3({io_w_req_bits_data_3_entry_isCall, io_w_req_bits_data_3_entry_isRet, io_w_req_bits_data_3_entry_isJalr,
      io_w_req_bits_data_3_entry_valid, io_w_req_bits_data_3_entry_brSlots_0_offset,
      io_w_req_bits_data_3_entry_brSlots_0_sharing, io_w_req_bits_data_3_entry_brSlots_0_valid}),
    .io_w_req_bits_waymask(io_w_req_bits_waymask),
    .io_broadcast_ram_hold(sigFromSrams_bore_7_ram_hold), .io_broadcast_ram_bypass(sigFromSrams_bore_7_ram_bypass),
    .io_broadcast_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken), .io_broadcast_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk),
    .io_broadcast_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp), .io_broadcast_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold),
    .io_broadcast_ram_ctl(64'h0), .io_broadcast_cgen(sigFromSrams_bore_7_cgen),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_7_addr), .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_7_addr_rd),
    .boreChildrenBd_bore_wdata(boreChildrenBd_bore_7_wdata), .boreChildrenBd_bore_wmask(boreChildrenBd_bore_7_wmask),
    .boreChildrenBd_bore_re(boreChildrenBd_bore_7_re), .boreChildrenBd_bore_we(boreChildrenBd_bore_7_we),
    .boreChildrenBd_bore_rdata(boreChildrenBd_bore_7_rdata), .boreChildrenBd_bore_ack(boreChildrenBd_bore_7_ack),
    .boreChildrenBd_bore_selectedOH(boreChildrenBd_bore_7_selectedOH), .boreChildrenBd_bore_array(boreChildrenBd_bore_7_array)
  );

  // 读侧重组：每路从 8 个 group 切片拼回 struct（way w 用各 group 的 d*_w）
  // way0
  assign io_r_resp_data_0_entry_isCall                = d7_0[9];
  assign io_r_resp_data_0_entry_isRet                 = d7_0[8];
  assign io_r_resp_data_0_entry_isJalr                = d7_0[7];
  assign io_r_resp_data_0_entry_valid                 = d7_0[6];
  assign io_r_resp_data_0_entry_brSlots_0_offset      = d7_0[5:2];
  assign io_r_resp_data_0_entry_brSlots_0_sharing     = d7_0[1];
  assign io_r_resp_data_0_entry_brSlots_0_valid       = d7_0[0];
  assign io_r_resp_data_0_entry_brSlots_0_lower       = {d6_0, d5_0[9:8]};
  assign io_r_resp_data_0_entry_brSlots_0_tarStat     = d5_0[7:6];
  assign io_r_resp_data_0_entry_tailSlot_offset       = d5_0[5:2];
  assign io_r_resp_data_0_entry_tailSlot_sharing      = d5_0[1];
  assign io_r_resp_data_0_entry_tailSlot_valid        = d5_0[0];
  assign io_r_resp_data_0_entry_tailSlot_lower        = {d4_0, d3_0};
  assign io_r_resp_data_0_entry_tailSlot_tarStat      = d2_0[9:8];
  assign io_r_resp_data_0_entry_pftAddr               = d2_0[7:4];
  assign io_r_resp_data_0_entry_carry                 = d2_0[3];
  assign io_r_resp_data_0_entry_last_may_be_rvi_call  = d2_0[2];
  assign io_r_resp_data_0_entry_strong_bias_0         = d2_0[0];
  assign io_r_resp_data_0_entry_strong_bias_1         = d2_0[1];
  assign io_r_resp_data_0_tag                         = {d1_0, d0_0};
  // way1
  assign io_r_resp_data_1_entry_isCall                = d7_1[9];
  assign io_r_resp_data_1_entry_isRet                 = d7_1[8];
  assign io_r_resp_data_1_entry_isJalr                = d7_1[7];
  assign io_r_resp_data_1_entry_valid                 = d7_1[6];
  assign io_r_resp_data_1_entry_brSlots_0_offset      = d7_1[5:2];
  assign io_r_resp_data_1_entry_brSlots_0_sharing     = d7_1[1];
  assign io_r_resp_data_1_entry_brSlots_0_valid       = d7_1[0];
  assign io_r_resp_data_1_entry_brSlots_0_lower       = {d6_1, d5_1[9:8]};
  assign io_r_resp_data_1_entry_brSlots_0_tarStat     = d5_1[7:6];
  assign io_r_resp_data_1_entry_tailSlot_offset       = d5_1[5:2];
  assign io_r_resp_data_1_entry_tailSlot_sharing      = d5_1[1];
  assign io_r_resp_data_1_entry_tailSlot_valid        = d5_1[0];
  assign io_r_resp_data_1_entry_tailSlot_lower        = {d4_1, d3_1};
  assign io_r_resp_data_1_entry_tailSlot_tarStat      = d2_1[9:8];
  assign io_r_resp_data_1_entry_pftAddr               = d2_1[7:4];
  assign io_r_resp_data_1_entry_carry                 = d2_1[3];
  assign io_r_resp_data_1_entry_last_may_be_rvi_call  = d2_1[2];
  assign io_r_resp_data_1_entry_strong_bias_0         = d2_1[0];
  assign io_r_resp_data_1_entry_strong_bias_1         = d2_1[1];
  assign io_r_resp_data_1_tag                         = {d1_1, d0_1};
  // way2
  assign io_r_resp_data_2_entry_isCall                = d7_2[9];
  assign io_r_resp_data_2_entry_isRet                 = d7_2[8];
  assign io_r_resp_data_2_entry_isJalr                = d7_2[7];
  assign io_r_resp_data_2_entry_valid                 = d7_2[6];
  assign io_r_resp_data_2_entry_brSlots_0_offset      = d7_2[5:2];
  assign io_r_resp_data_2_entry_brSlots_0_sharing     = d7_2[1];
  assign io_r_resp_data_2_entry_brSlots_0_valid       = d7_2[0];
  assign io_r_resp_data_2_entry_brSlots_0_lower       = {d6_2, d5_2[9:8]};
  assign io_r_resp_data_2_entry_brSlots_0_tarStat     = d5_2[7:6];
  assign io_r_resp_data_2_entry_tailSlot_offset       = d5_2[5:2];
  assign io_r_resp_data_2_entry_tailSlot_sharing      = d5_2[1];
  assign io_r_resp_data_2_entry_tailSlot_valid        = d5_2[0];
  assign io_r_resp_data_2_entry_tailSlot_lower        = {d4_2, d3_2};
  assign io_r_resp_data_2_entry_tailSlot_tarStat      = d2_2[9:8];
  assign io_r_resp_data_2_entry_pftAddr               = d2_2[7:4];
  assign io_r_resp_data_2_entry_carry                 = d2_2[3];
  assign io_r_resp_data_2_entry_last_may_be_rvi_call  = d2_2[2];
  assign io_r_resp_data_2_entry_strong_bias_0         = d2_2[0];
  assign io_r_resp_data_2_entry_strong_bias_1         = d2_2[1];
  assign io_r_resp_data_2_tag                         = {d1_2, d0_2};
  // way3
  assign io_r_resp_data_3_entry_isCall                = d7_3[9];
  assign io_r_resp_data_3_entry_isRet                 = d7_3[8];
  assign io_r_resp_data_3_entry_isJalr                = d7_3[7];
  assign io_r_resp_data_3_entry_valid                 = d7_3[6];
  assign io_r_resp_data_3_entry_brSlots_0_offset      = d7_3[5:2];
  assign io_r_resp_data_3_entry_brSlots_0_sharing     = d7_3[1];
  assign io_r_resp_data_3_entry_brSlots_0_valid       = d7_3[0];
  assign io_r_resp_data_3_entry_brSlots_0_lower       = {d6_3, d5_3[9:8]};
  assign io_r_resp_data_3_entry_brSlots_0_tarStat     = d5_3[7:6];
  assign io_r_resp_data_3_entry_tailSlot_offset       = d5_3[5:2];
  assign io_r_resp_data_3_entry_tailSlot_sharing      = d5_3[1];
  assign io_r_resp_data_3_entry_tailSlot_valid        = d5_3[0];
  assign io_r_resp_data_3_entry_tailSlot_lower        = {d4_3, d3_3};
  assign io_r_resp_data_3_entry_tailSlot_tarStat      = d2_3[9:8];
  assign io_r_resp_data_3_entry_pftAddr               = d2_3[7:4];
  assign io_r_resp_data_3_entry_carry                 = d2_3[3];
  assign io_r_resp_data_3_entry_last_may_be_rvi_call  = d2_3[2];
  assign io_r_resp_data_3_entry_strong_bias_0         = d2_3[0];
  assign io_r_resp_data_3_entry_strong_bias_1         = d2_3[1];
  assign io_r_resp_data_3_tag                         = {d1_3, d0_3};
endmodule
