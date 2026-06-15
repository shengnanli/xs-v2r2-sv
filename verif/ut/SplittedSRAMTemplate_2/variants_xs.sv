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
  input  [9:0]  boreChildrenBd_bore_addr,    input [9:0] boreChildrenBd_bore_addr_rd,
  input  [39:0] boreChildrenBd_bore_wdata,   input [3:0] boreChildrenBd_bore_wmask,
  input         boreChildrenBd_bore_re,      input boreChildrenBd_bore_we,
  output [39:0] boreChildrenBd_bore_rdata,   input boreChildrenBd_bore_ack,
  input         boreChildrenBd_bore_selectedOH, input [5:0] boreChildrenBd_bore_array,
  input  [9:0]  boreChildrenBd_bore_1_addr,  input [9:0] boreChildrenBd_bore_1_addr_rd,
  input  [39:0] boreChildrenBd_bore_1_wdata, input [3:0] boreChildrenBd_bore_1_wmask,
  input         boreChildrenBd_bore_1_re,    input boreChildrenBd_bore_1_we,
  output [39:0] boreChildrenBd_bore_1_rdata, input boreChildrenBd_bore_1_ack,
  input         boreChildrenBd_bore_1_selectedOH, input [5:0] boreChildrenBd_bore_1_array,
  input  [9:0]  boreChildrenBd_bore_2_addr,  input [9:0] boreChildrenBd_bore_2_addr_rd,
  input  [39:0] boreChildrenBd_bore_2_wdata, input [3:0] boreChildrenBd_bore_2_wmask,
  input         boreChildrenBd_bore_2_re,    input boreChildrenBd_bore_2_we,
  output [39:0] boreChildrenBd_bore_2_rdata, input boreChildrenBd_bore_2_ack,
  input         boreChildrenBd_bore_2_selectedOH, input [5:0] boreChildrenBd_bore_2_array,
  input  [9:0]  boreChildrenBd_bore_3_addr,  input [9:0] boreChildrenBd_bore_3_addr_rd,
  input  [39:0] boreChildrenBd_bore_3_wdata, input [3:0] boreChildrenBd_bore_3_wmask,
  input         boreChildrenBd_bore_3_re,    input boreChildrenBd_bore_3_we,
  output [39:0] boreChildrenBd_bore_3_rdata, input boreChildrenBd_bore_3_ack,
  input         boreChildrenBd_bore_3_selectedOH, input [5:0] boreChildrenBd_bore_3_array,
  input  [9:0]  boreChildrenBd_bore_4_addr,  input [9:0] boreChildrenBd_bore_4_addr_rd,
  input  [39:0] boreChildrenBd_bore_4_wdata, input [3:0] boreChildrenBd_bore_4_wmask,
  input         boreChildrenBd_bore_4_re,    input boreChildrenBd_bore_4_we,
  output [39:0] boreChildrenBd_bore_4_rdata, input boreChildrenBd_bore_4_ack,
  input         boreChildrenBd_bore_4_selectedOH, input [5:0] boreChildrenBd_bore_4_array,
  input  [9:0]  boreChildrenBd_bore_5_addr,  input [9:0] boreChildrenBd_bore_5_addr_rd,
  input  [39:0] boreChildrenBd_bore_5_wdata, input [3:0] boreChildrenBd_bore_5_wmask,
  input         boreChildrenBd_bore_5_re,    input boreChildrenBd_bore_5_we,
  output [39:0] boreChildrenBd_bore_5_rdata, input boreChildrenBd_bore_5_ack,
  input         boreChildrenBd_bore_5_selectedOH, input [5:0] boreChildrenBd_bore_5_array,
  input  [9:0]  boreChildrenBd_bore_6_addr,  input [9:0] boreChildrenBd_bore_6_addr_rd,
  input  [39:0] boreChildrenBd_bore_6_wdata, input [3:0] boreChildrenBd_bore_6_wmask,
  input         boreChildrenBd_bore_6_re,    input boreChildrenBd_bore_6_we,
  output [39:0] boreChildrenBd_bore_6_rdata, input boreChildrenBd_bore_6_ack,
  input         boreChildrenBd_bore_6_selectedOH, input [5:0] boreChildrenBd_bore_6_array,
  input  [9:0]  boreChildrenBd_bore_7_addr,  input [9:0] boreChildrenBd_bore_7_addr_rd,
  input  [39:0] boreChildrenBd_bore_7_wdata, input [3:0] boreChildrenBd_bore_7_wmask,
  input         boreChildrenBd_bore_7_re,    input boreChildrenBd_bore_7_we,
  output [39:0] boreChildrenBd_bore_7_rdata, input boreChildrenBd_bore_7_ack,
  input         boreChildrenBd_bore_7_selectedOH, input [5:0] boreChildrenBd_bore_7_array,
  input         sigFromSrams_bore_ram_hold,   input sigFromSrams_bore_ram_bypass,
  input         sigFromSrams_bore_ram_bp_clken, input sigFromSrams_bore_ram_aux_clk,
  input         sigFromSrams_bore_ram_aux_ckbp, input sigFromSrams_bore_ram_mcp_hold,
  input         sigFromSrams_bore_cgen,
  input         sigFromSrams_bore_1_ram_hold,   input sigFromSrams_bore_1_ram_bypass,
  input         sigFromSrams_bore_1_ram_bp_clken, input sigFromSrams_bore_1_ram_aux_clk,
  input         sigFromSrams_bore_1_ram_aux_ckbp, input sigFromSrams_bore_1_ram_mcp_hold,
  input         sigFromSrams_bore_1_cgen,
  input         sigFromSrams_bore_2_ram_hold,   input sigFromSrams_bore_2_ram_bypass,
  input         sigFromSrams_bore_2_ram_bp_clken, input sigFromSrams_bore_2_ram_aux_clk,
  input         sigFromSrams_bore_2_ram_aux_ckbp, input sigFromSrams_bore_2_ram_mcp_hold,
  input         sigFromSrams_bore_2_cgen,
  input         sigFromSrams_bore_3_ram_hold,   input sigFromSrams_bore_3_ram_bypass,
  input         sigFromSrams_bore_3_ram_bp_clken, input sigFromSrams_bore_3_ram_aux_clk,
  input         sigFromSrams_bore_3_ram_aux_ckbp, input sigFromSrams_bore_3_ram_mcp_hold,
  input         sigFromSrams_bore_3_cgen,
  input         sigFromSrams_bore_4_ram_hold,   input sigFromSrams_bore_4_ram_bypass,
  input         sigFromSrams_bore_4_ram_bp_clken, input sigFromSrams_bore_4_ram_aux_clk,
  input         sigFromSrams_bore_4_ram_aux_ckbp, input sigFromSrams_bore_4_ram_mcp_hold,
  input         sigFromSrams_bore_4_cgen,
  input         sigFromSrams_bore_5_ram_hold,   input sigFromSrams_bore_5_ram_bypass,
  input         sigFromSrams_bore_5_ram_bp_clken, input sigFromSrams_bore_5_ram_aux_clk,
  input         sigFromSrams_bore_5_ram_aux_ckbp, input sigFromSrams_bore_5_ram_mcp_hold,
  input         sigFromSrams_bore_5_cgen,
  input         sigFromSrams_bore_6_ram_hold,   input sigFromSrams_bore_6_ram_bypass,
  input         sigFromSrams_bore_6_ram_bp_clken, input sigFromSrams_bore_6_ram_aux_clk,
  input         sigFromSrams_bore_6_ram_aux_ckbp, input sigFromSrams_bore_6_ram_mcp_hold,
  input         sigFromSrams_bore_6_cgen,
  input         sigFromSrams_bore_7_ram_hold,   input sigFromSrams_bore_7_ram_bypass,
  input         sigFromSrams_bore_7_ram_bp_clken, input sigFromSrams_bore_7_ram_aux_clk,
  input         sigFromSrams_bore_7_ram_aux_ckbp, input sigFromSrams_bore_7_ram_mcp_hold,
  input         sigFromSrams_bore_7_cgen
);
  localparam int N_SPLIT = 8;    // dataSplit
  localparam int CHUNK_W = 10;   // 每切片位宽
  localparam int WORD_W  = 80;   // 每路物理打包字宽 = N_SPLIT*CHUNK_W

  // ---- 写：把每路 struct 铺成 80 位物理字（chunk i = bits [10*i+9:10*i]）----
  // 用 function 把单路所有字段拼成 80 位，顺序见模块头注释。
  function automatic [WORD_W-1:0] pack_way(
    input        isCall, input isRet, input isJalr, input e_valid,
    input [3:0]  br_offset, input br_sharing, input br_valid,
    input [11:0] br_lower,  input [1:0] br_tarStat,
    input [3:0]  tl_offset, input tl_sharing, input tl_valid,
    input [19:0] tl_lower,  input [1:0] tl_tarStat,
    input [3:0]  pftAddr,   input carry, input last_rvi_call,
    input        sb0, input sb1, input [19:0] tag
  );
    pack_way = {
      // chunk7 [79:70]
      isCall, isRet, isJalr, e_valid, br_offset, br_sharing, br_valid,
      // chunk6 [69:60]
      br_lower[11:2],
      // chunk5 [59:50]
      br_lower[1:0], br_tarStat, tl_offset, tl_sharing, tl_valid,
      // chunk4 [49:40]
      tl_lower[19:10],
      // chunk3 [39:30]
      tl_lower[9:0],
      // chunk2 [29:20]
      tl_tarStat, pftAddr, carry, last_rvi_call, sb1, sb0,
      // chunk1 [19:10]
      tag[19:10],
      // chunk0 [9:0]
      tag[9:0]
    };
  endfunction

  wire [WORD_W-1:0] w_word [4];
  assign w_word[0] = pack_way(
    io_w_req_bits_data_0_entry_isCall, io_w_req_bits_data_0_entry_isRet,
    io_w_req_bits_data_0_entry_isJalr, io_w_req_bits_data_0_entry_valid,
    io_w_req_bits_data_0_entry_brSlots_0_offset, io_w_req_bits_data_0_entry_brSlots_0_sharing,
    io_w_req_bits_data_0_entry_brSlots_0_valid, io_w_req_bits_data_0_entry_brSlots_0_lower,
    io_w_req_bits_data_0_entry_brSlots_0_tarStat,
    io_w_req_bits_data_0_entry_tailSlot_offset, io_w_req_bits_data_0_entry_tailSlot_sharing,
    io_w_req_bits_data_0_entry_tailSlot_valid, io_w_req_bits_data_0_entry_tailSlot_lower,
    io_w_req_bits_data_0_entry_tailSlot_tarStat,
    io_w_req_bits_data_0_entry_pftAddr, io_w_req_bits_data_0_entry_carry,
    io_w_req_bits_data_0_entry_last_may_be_rvi_call,
    io_w_req_bits_data_0_entry_strong_bias_0, io_w_req_bits_data_0_entry_strong_bias_1,
    io_w_req_bits_data_0_tag);
  assign w_word[1] = pack_way(
    io_w_req_bits_data_1_entry_isCall, io_w_req_bits_data_1_entry_isRet,
    io_w_req_bits_data_1_entry_isJalr, io_w_req_bits_data_1_entry_valid,
    io_w_req_bits_data_1_entry_brSlots_0_offset, io_w_req_bits_data_1_entry_brSlots_0_sharing,
    io_w_req_bits_data_1_entry_brSlots_0_valid, io_w_req_bits_data_1_entry_brSlots_0_lower,
    io_w_req_bits_data_1_entry_brSlots_0_tarStat,
    io_w_req_bits_data_1_entry_tailSlot_offset, io_w_req_bits_data_1_entry_tailSlot_sharing,
    io_w_req_bits_data_1_entry_tailSlot_valid, io_w_req_bits_data_1_entry_tailSlot_lower,
    io_w_req_bits_data_1_entry_tailSlot_tarStat,
    io_w_req_bits_data_1_entry_pftAddr, io_w_req_bits_data_1_entry_carry,
    io_w_req_bits_data_1_entry_last_may_be_rvi_call,
    io_w_req_bits_data_1_entry_strong_bias_0, io_w_req_bits_data_1_entry_strong_bias_1,
    io_w_req_bits_data_1_tag);
  assign w_word[2] = pack_way(
    io_w_req_bits_data_2_entry_isCall, io_w_req_bits_data_2_entry_isRet,
    io_w_req_bits_data_2_entry_isJalr, io_w_req_bits_data_2_entry_valid,
    io_w_req_bits_data_2_entry_brSlots_0_offset, io_w_req_bits_data_2_entry_brSlots_0_sharing,
    io_w_req_bits_data_2_entry_brSlots_0_valid, io_w_req_bits_data_2_entry_brSlots_0_lower,
    io_w_req_bits_data_2_entry_brSlots_0_tarStat,
    io_w_req_bits_data_2_entry_tailSlot_offset, io_w_req_bits_data_2_entry_tailSlot_sharing,
    io_w_req_bits_data_2_entry_tailSlot_valid, io_w_req_bits_data_2_entry_tailSlot_lower,
    io_w_req_bits_data_2_entry_tailSlot_tarStat,
    io_w_req_bits_data_2_entry_pftAddr, io_w_req_bits_data_2_entry_carry,
    io_w_req_bits_data_2_entry_last_may_be_rvi_call,
    io_w_req_bits_data_2_entry_strong_bias_0, io_w_req_bits_data_2_entry_strong_bias_1,
    io_w_req_bits_data_2_tag);
  assign w_word[3] = pack_way(
    io_w_req_bits_data_3_entry_isCall, io_w_req_bits_data_3_entry_isRet,
    io_w_req_bits_data_3_entry_isJalr, io_w_req_bits_data_3_entry_valid,
    io_w_req_bits_data_3_entry_brSlots_0_offset, io_w_req_bits_data_3_entry_brSlots_0_sharing,
    io_w_req_bits_data_3_entry_brSlots_0_valid, io_w_req_bits_data_3_entry_brSlots_0_lower,
    io_w_req_bits_data_3_entry_brSlots_0_tarStat,
    io_w_req_bits_data_3_entry_tailSlot_offset, io_w_req_bits_data_3_entry_tailSlot_sharing,
    io_w_req_bits_data_3_entry_tailSlot_valid, io_w_req_bits_data_3_entry_tailSlot_lower,
    io_w_req_bits_data_3_entry_tailSlot_tarStat,
    io_w_req_bits_data_3_entry_pftAddr, io_w_req_bits_data_3_entry_carry,
    io_w_req_bits_data_3_entry_last_may_be_rvi_call,
    io_w_req_bits_data_3_entry_strong_bias_0, io_w_req_bits_data_3_entry_strong_bias_1,
    io_w_req_bits_data_3_tag);

  // 读出切片：rd_chunk[split][way] = 该内层第 way 路读出的 10 位
  wire [CHUNK_W-1:0] rd_chunk [N_SPLIT][4];

  // ---- 把各 bore/broadcast 信号收成数组，便于 genvar 例化 8 个内层 ----
  wire [9:0]  bore_addr   [N_SPLIT], bore_addr_rd [N_SPLIT];
  wire [39:0] bore_wdata  [N_SPLIT];
  wire [3:0]  bore_wmask  [N_SPLIT];
  wire        bore_re     [N_SPLIT], bore_we [N_SPLIT], bore_ack [N_SPLIT], bore_sel [N_SPLIT];
  wire [5:0]  bore_array  [N_SPLIT];
  wire [39:0] bore_rdata  [N_SPLIT];
  wire        bc_hold[N_SPLIT], bc_bypass[N_SPLIT], bc_bpclken[N_SPLIT];
  wire        bc_auxclk[N_SPLIT], bc_auxckbp[N_SPLIT], bc_mcphold[N_SPLIT], bc_cgen[N_SPLIT];

  `define BIND_BORE(I, S) \
    assign bore_addr[I]=boreChildrenBd_``S``_addr;       assign bore_addr_rd[I]=boreChildrenBd_``S``_addr_rd; \
    assign bore_wdata[I]=boreChildrenBd_``S``_wdata;     assign bore_wmask[I]=boreChildrenBd_``S``_wmask; \
    assign bore_re[I]=boreChildrenBd_``S``_re;           assign bore_we[I]=boreChildrenBd_``S``_we; \
    assign bore_ack[I]=boreChildrenBd_``S``_ack;         assign bore_sel[I]=boreChildrenBd_``S``_selectedOH; \
    assign bore_array[I]=boreChildrenBd_``S``_array;     assign boreChildrenBd_``S``_rdata=bore_rdata[I]; \
    assign bc_hold[I]=sigFromSrams_``S``_ram_hold;       assign bc_bypass[I]=sigFromSrams_``S``_ram_bypass; \
    assign bc_bpclken[I]=sigFromSrams_``S``_ram_bp_clken;assign bc_auxclk[I]=sigFromSrams_``S``_ram_aux_clk; \
    assign bc_auxckbp[I]=sigFromSrams_``S``_ram_aux_ckbp;assign bc_mcphold[I]=sigFromSrams_``S``_ram_mcp_hold; \
    assign bc_cgen[I]=sigFromSrams_``S``_cgen;
  `BIND_BORE(0, bore)
  `BIND_BORE(1, bore_1)
  `BIND_BORE(2, bore_2)
  `BIND_BORE(3, bore_3)
  `BIND_BORE(4, bore_4)
  `BIND_BORE(5, bore_5)
  `BIND_BORE(6, bore_6)
  `BIND_BORE(7, bore_7)
  `undef BIND_BORE

  // io_r_req_ready 只从第 0 个内层引出（各内层 ready 一致）
  wire [N_SPLIT-1:0] inner_ready;
  assign io_r_req_ready = inner_ready[0];

  // ---- 8 个内层 SRAMTemplate_36（512×4×10），每个存一个 10 位切片 ----
  genvar s;
  generate
    for (s = 0; s < N_SPLIT; s++) begin : g_split
      SRAMTemplate_36 array_inst (
        .clock(clock), .reset(reset),
        .io_r_req_ready(inner_ready[s]),
        .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),
        .io_r_resp_data_0(rd_chunk[s][0]), .io_r_resp_data_1(rd_chunk[s][1]),
        .io_r_resp_data_2(rd_chunk[s][2]), .io_r_resp_data_3(rd_chunk[s][3]),
        .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),
        // 每路取本切片对应的 10 位
        .io_w_req_bits_data_0(w_word[0][s*CHUNK_W +: CHUNK_W]),
        .io_w_req_bits_data_1(w_word[1][s*CHUNK_W +: CHUNK_W]),
        .io_w_req_bits_data_2(w_word[2][s*CHUNK_W +: CHUNK_W]),
        .io_w_req_bits_data_3(w_word[3][s*CHUNK_W +: CHUNK_W]),
        .io_w_req_bits_waymask(io_w_req_bits_waymask),
        .io_broadcast_ram_hold(bc_hold[s]), .io_broadcast_ram_bypass(bc_bypass[s]),
        .io_broadcast_ram_bp_clken(bc_bpclken[s]), .io_broadcast_ram_aux_clk(bc_auxclk[s]),
        .io_broadcast_ram_aux_ckbp(bc_auxckbp[s]), .io_broadcast_ram_mcp_hold(bc_mcphold[s]),
        .io_broadcast_ram_ctl(64'h0), .io_broadcast_cgen(bc_cgen[s]),
        .boreChildrenBd_bore_addr(bore_addr[s]), .boreChildrenBd_bore_addr_rd(bore_addr_rd[s]),
        .boreChildrenBd_bore_wdata(bore_wdata[s]), .boreChildrenBd_bore_wmask(bore_wmask[s]),
        .boreChildrenBd_bore_re(bore_re[s]), .boreChildrenBd_bore_we(bore_we[s]),
        .boreChildrenBd_bore_rdata(bore_rdata[s]), .boreChildrenBd_bore_ack(bore_ack[s]),
        .boreChildrenBd_bore_selectedOH(bore_sel[s]), .boreChildrenBd_bore_array(bore_array[s])
      );
    end
  endgenerate

  // ---- 读：把每路 8 个切片拼回 80 位字，再拆 struct（拆位序见模块头）----
  wire [WORD_W-1:0] r_word [4];
  generate
    for (s = 0; s < N_SPLIT; s++) begin : g_rword
      assign r_word[0][s*CHUNK_W +: CHUNK_W] = rd_chunk[s][0];
      assign r_word[1][s*CHUNK_W +: CHUNK_W] = rd_chunk[s][1];
      assign r_word[2][s*CHUNK_W +: CHUNK_W] = rd_chunk[s][2];
      assign r_word[3][s*CHUNK_W +: CHUNK_W] = rd_chunk[s][3];
    end
  endgenerate

  // 解包 way0
  assign io_r_resp_data_0_entry_isCall               = r_word[0][79];
  assign io_r_resp_data_0_entry_isRet                = r_word[0][78];
  assign io_r_resp_data_0_entry_isJalr               = r_word[0][77];
  assign io_r_resp_data_0_entry_valid                = r_word[0][76];
  assign io_r_resp_data_0_entry_brSlots_0_offset     = r_word[0][75:72];
  assign io_r_resp_data_0_entry_brSlots_0_sharing    = r_word[0][71];
  assign io_r_resp_data_0_entry_brSlots_0_valid      = r_word[0][70];
  assign io_r_resp_data_0_entry_brSlots_0_lower      = r_word[0][69:58];
  assign io_r_resp_data_0_entry_brSlots_0_tarStat    = r_word[0][57:56];
  assign io_r_resp_data_0_entry_tailSlot_offset      = r_word[0][55:52];
  assign io_r_resp_data_0_entry_tailSlot_sharing     = r_word[0][51];
  assign io_r_resp_data_0_entry_tailSlot_valid       = r_word[0][50];
  assign io_r_resp_data_0_entry_tailSlot_lower       = r_word[0][49:30];
  assign io_r_resp_data_0_entry_tailSlot_tarStat     = r_word[0][29:28];
  assign io_r_resp_data_0_entry_pftAddr              = r_word[0][27:24];
  assign io_r_resp_data_0_entry_carry                = r_word[0][23];
  assign io_r_resp_data_0_entry_last_may_be_rvi_call = r_word[0][22];
  assign io_r_resp_data_0_entry_strong_bias_1        = r_word[0][21];
  assign io_r_resp_data_0_entry_strong_bias_0        = r_word[0][20];
  assign io_r_resp_data_0_tag                        = r_word[0][19:0];
  // 解包 way1
  assign io_r_resp_data_1_entry_isCall               = r_word[1][79];
  assign io_r_resp_data_1_entry_isRet                = r_word[1][78];
  assign io_r_resp_data_1_entry_isJalr               = r_word[1][77];
  assign io_r_resp_data_1_entry_valid                = r_word[1][76];
  assign io_r_resp_data_1_entry_brSlots_0_offset     = r_word[1][75:72];
  assign io_r_resp_data_1_entry_brSlots_0_sharing    = r_word[1][71];
  assign io_r_resp_data_1_entry_brSlots_0_valid      = r_word[1][70];
  assign io_r_resp_data_1_entry_brSlots_0_lower      = r_word[1][69:58];
  assign io_r_resp_data_1_entry_brSlots_0_tarStat    = r_word[1][57:56];
  assign io_r_resp_data_1_entry_tailSlot_offset      = r_word[1][55:52];
  assign io_r_resp_data_1_entry_tailSlot_sharing     = r_word[1][51];
  assign io_r_resp_data_1_entry_tailSlot_valid       = r_word[1][50];
  assign io_r_resp_data_1_entry_tailSlot_lower       = r_word[1][49:30];
  assign io_r_resp_data_1_entry_tailSlot_tarStat     = r_word[1][29:28];
  assign io_r_resp_data_1_entry_pftAddr              = r_word[1][27:24];
  assign io_r_resp_data_1_entry_carry                = r_word[1][23];
  assign io_r_resp_data_1_entry_last_may_be_rvi_call = r_word[1][22];
  assign io_r_resp_data_1_entry_strong_bias_1        = r_word[1][21];
  assign io_r_resp_data_1_entry_strong_bias_0        = r_word[1][20];
  assign io_r_resp_data_1_tag                        = r_word[1][19:0];
  // 解包 way2
  assign io_r_resp_data_2_entry_isCall               = r_word[2][79];
  assign io_r_resp_data_2_entry_isRet                = r_word[2][78];
  assign io_r_resp_data_2_entry_isJalr               = r_word[2][77];
  assign io_r_resp_data_2_entry_valid                = r_word[2][76];
  assign io_r_resp_data_2_entry_brSlots_0_offset     = r_word[2][75:72];
  assign io_r_resp_data_2_entry_brSlots_0_sharing    = r_word[2][71];
  assign io_r_resp_data_2_entry_brSlots_0_valid      = r_word[2][70];
  assign io_r_resp_data_2_entry_brSlots_0_lower      = r_word[2][69:58];
  assign io_r_resp_data_2_entry_brSlots_0_tarStat    = r_word[2][57:56];
  assign io_r_resp_data_2_entry_tailSlot_offset      = r_word[2][55:52];
  assign io_r_resp_data_2_entry_tailSlot_sharing     = r_word[2][51];
  assign io_r_resp_data_2_entry_tailSlot_valid       = r_word[2][50];
  assign io_r_resp_data_2_entry_tailSlot_lower       = r_word[2][49:30];
  assign io_r_resp_data_2_entry_tailSlot_tarStat     = r_word[2][29:28];
  assign io_r_resp_data_2_entry_pftAddr              = r_word[2][27:24];
  assign io_r_resp_data_2_entry_carry                = r_word[2][23];
  assign io_r_resp_data_2_entry_last_may_be_rvi_call = r_word[2][22];
  assign io_r_resp_data_2_entry_strong_bias_1        = r_word[2][21];
  assign io_r_resp_data_2_entry_strong_bias_0        = r_word[2][20];
  assign io_r_resp_data_2_tag                        = r_word[2][19:0];
  // 解包 way3
  assign io_r_resp_data_3_entry_isCall               = r_word[3][79];
  assign io_r_resp_data_3_entry_isRet                = r_word[3][78];
  assign io_r_resp_data_3_entry_isJalr               = r_word[3][77];
  assign io_r_resp_data_3_entry_valid                = r_word[3][76];
  assign io_r_resp_data_3_entry_brSlots_0_offset     = r_word[3][75:72];
  assign io_r_resp_data_3_entry_brSlots_0_sharing    = r_word[3][71];
  assign io_r_resp_data_3_entry_brSlots_0_valid      = r_word[3][70];
  assign io_r_resp_data_3_entry_brSlots_0_lower      = r_word[3][69:58];
  assign io_r_resp_data_3_entry_brSlots_0_tarStat    = r_word[3][57:56];
  assign io_r_resp_data_3_entry_tailSlot_offset      = r_word[3][55:52];
  assign io_r_resp_data_3_entry_tailSlot_sharing     = r_word[3][51];
  assign io_r_resp_data_3_entry_tailSlot_valid       = r_word[3][50];
  assign io_r_resp_data_3_entry_tailSlot_lower       = r_word[3][49:30];
  assign io_r_resp_data_3_entry_tailSlot_tarStat     = r_word[3][29:28];
  assign io_r_resp_data_3_entry_pftAddr              = r_word[3][27:24];
  assign io_r_resp_data_3_entry_carry                = r_word[3][23];
  assign io_r_resp_data_3_entry_last_may_be_rvi_call = r_word[3][22];
  assign io_r_resp_data_3_entry_strong_bias_1        = r_word[3][21];
  assign io_r_resp_data_3_entry_strong_bias_0        = r_word[3][20];
  assign io_r_resp_data_3_tag                        = r_word[3][19:0];
endmodule
