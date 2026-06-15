// =============================================================================
// FTB（golden 同名顶层 wrapper）—— 机械端口适配层
//
// 作用：把可读核 xs_FTB_core 的 struct/数组端口拆成 golden 扁平端口，并在内部例化
//       golden 同名子模块（FTBBank / DelayNWithValid / DelayNWithValid_1 / DelayN_1）
//       作为黑盒，与核对接。供 FM 等价比对与 ST 替换。
//
// 本层只做端口搬运 + 子模块例化，不含算法逻辑（算法全在 xs_FTB_core 与子模块内）。
//
// 关于 MBIST / bore 扫描链与 sigFromSrams：
//   这些 DFT 端口经 FTBBank → SRAM，对 FTB 功能输出无影响。本层把模块级 bore_*
//   与 sigFromSrams_* 直通给 golden FTBBank（与 golden 完全一致的接线）。
// =============================================================================
module FTB_xs
  import xs_ftb_pkg::*;
(
  input          clock,
  input          reset,
  input  [47:0]  io_reset_vector,
  input  [49:0]  io_in_bits_s0_pc_0,
  input  [49:0]  io_in_bits_s0_pc_1,
  input  [49:0]  io_in_bits_s0_pc_2,
  input  [49:0]  io_in_bits_s0_pc_3,
  input          io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0,
  input          io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1,
  input          io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0,
  input          io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1,
  input          io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0,
  input          io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1,
  input          io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0,
  input          io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1,
  input          io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0,
  input          io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1,
  input          io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0,
  input          io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1,
  input          io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0,
  input          io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1,
  input          io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0,
  input          io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1,
  input          io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0,
  input          io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1,
  output         io_out_s2_full_pred_0_br_taken_mask_0,
  output         io_out_s2_full_pred_0_br_taken_mask_1,
  output         io_out_s2_full_pred_0_slot_valids_0,
  output         io_out_s2_full_pred_0_slot_valids_1,
  output [49:0]  io_out_s2_full_pred_0_targets_0,
  output [49:0]  io_out_s2_full_pred_0_targets_1,
  output [49:0]  io_out_s2_full_pred_0_jalr_target,
  output [3:0]   io_out_s2_full_pred_0_offsets_0,
  output [3:0]   io_out_s2_full_pred_0_offsets_1,
  output [49:0]  io_out_s2_full_pred_0_fallThroughAddr,
  output         io_out_s2_full_pred_0_fallThroughErr,
  output         io_out_s2_full_pred_0_is_jal,
  output         io_out_s2_full_pred_0_is_jalr,
  output         io_out_s2_full_pred_0_is_call,
  output         io_out_s2_full_pred_0_is_ret,
  output         io_out_s2_full_pred_0_last_may_be_rvi_call,
  output         io_out_s2_full_pred_0_is_br_sharing,
  output         io_out_s2_full_pred_0_hit,
  output         io_out_s2_full_pred_1_br_taken_mask_0,
  output         io_out_s2_full_pred_1_br_taken_mask_1,
  output         io_out_s2_full_pred_1_slot_valids_0,
  output         io_out_s2_full_pred_1_slot_valids_1,
  output [49:0]  io_out_s2_full_pred_1_targets_0,
  output [49:0]  io_out_s2_full_pred_1_targets_1,
  output [49:0]  io_out_s2_full_pred_1_jalr_target,
  output [3:0]   io_out_s2_full_pred_1_offsets_0,
  output [3:0]   io_out_s2_full_pred_1_offsets_1,
  output [49:0]  io_out_s2_full_pred_1_fallThroughAddr,
  output         io_out_s2_full_pred_1_fallThroughErr,
  output         io_out_s2_full_pred_1_is_jal,
  output         io_out_s2_full_pred_1_is_jalr,
  output         io_out_s2_full_pred_1_is_call,
  output         io_out_s2_full_pred_1_is_ret,
  output         io_out_s2_full_pred_1_last_may_be_rvi_call,
  output         io_out_s2_full_pred_1_is_br_sharing,
  output         io_out_s2_full_pred_1_hit,
  output         io_out_s2_full_pred_2_br_taken_mask_0,
  output         io_out_s2_full_pred_2_br_taken_mask_1,
  output         io_out_s2_full_pred_2_slot_valids_0,
  output         io_out_s2_full_pred_2_slot_valids_1,
  output [49:0]  io_out_s2_full_pred_2_targets_0,
  output [49:0]  io_out_s2_full_pred_2_targets_1,
  output [49:0]  io_out_s2_full_pred_2_jalr_target,
  output [3:0]   io_out_s2_full_pred_2_offsets_0,
  output [3:0]   io_out_s2_full_pred_2_offsets_1,
  output [49:0]  io_out_s2_full_pred_2_fallThroughAddr,
  output         io_out_s2_full_pred_2_fallThroughErr,
  output         io_out_s2_full_pred_2_is_jal,
  output         io_out_s2_full_pred_2_is_jalr,
  output         io_out_s2_full_pred_2_is_call,
  output         io_out_s2_full_pred_2_is_ret,
  output         io_out_s2_full_pred_2_last_may_be_rvi_call,
  output         io_out_s2_full_pred_2_is_br_sharing,
  output         io_out_s2_full_pred_2_hit,
  output         io_out_s2_full_pred_3_br_taken_mask_0,
  output         io_out_s2_full_pred_3_br_taken_mask_1,
  output         io_out_s2_full_pred_3_slot_valids_0,
  output         io_out_s2_full_pred_3_slot_valids_1,
  output [49:0]  io_out_s2_full_pred_3_targets_0,
  output [49:0]  io_out_s2_full_pred_3_targets_1,
  output [49:0]  io_out_s2_full_pred_3_jalr_target,
  output [3:0]   io_out_s2_full_pred_3_offsets_0,
  output [3:0]   io_out_s2_full_pred_3_offsets_1,
  output [49:0]  io_out_s2_full_pred_3_fallThroughAddr,
  output         io_out_s2_full_pred_3_fallThroughErr,
  output         io_out_s2_full_pred_3_is_jal,
  output         io_out_s2_full_pred_3_is_jalr,
  output         io_out_s2_full_pred_3_is_call,
  output         io_out_s2_full_pred_3_is_ret,
  output         io_out_s2_full_pred_3_last_may_be_rvi_call,
  output         io_out_s2_full_pred_3_is_br_sharing,
  output         io_out_s2_full_pred_3_hit,
  output         io_out_s3_full_pred_0_br_taken_mask_0,
  output         io_out_s3_full_pred_0_br_taken_mask_1,
  output         io_out_s3_full_pred_0_slot_valids_0,
  output         io_out_s3_full_pred_0_slot_valids_1,
  output [49:0]  io_out_s3_full_pred_0_targets_0,
  output [49:0]  io_out_s3_full_pred_0_targets_1,
  output [3:0]   io_out_s3_full_pred_0_offsets_0,
  output [3:0]   io_out_s3_full_pred_0_offsets_1,
  output [49:0]  io_out_s3_full_pred_0_fallThroughAddr,
  output         io_out_s3_full_pred_0_fallThroughErr,
  output         io_out_s3_full_pred_0_multiHit,
  output         io_out_s3_full_pred_0_is_jal,
  output         io_out_s3_full_pred_0_is_jalr,
  output         io_out_s3_full_pred_0_is_call,
  output         io_out_s3_full_pred_0_is_ret,
  output         io_out_s3_full_pred_0_last_may_be_rvi_call,
  output         io_out_s3_full_pred_0_is_br_sharing,
  output         io_out_s3_full_pred_0_hit,
  output         io_out_s3_full_pred_1_br_taken_mask_0,
  output         io_out_s3_full_pred_1_br_taken_mask_1,
  output         io_out_s3_full_pred_1_slot_valids_0,
  output         io_out_s3_full_pred_1_slot_valids_1,
  output [49:0]  io_out_s3_full_pred_1_targets_0,
  output [49:0]  io_out_s3_full_pred_1_targets_1,
  output [3:0]   io_out_s3_full_pred_1_offsets_0,
  output [3:0]   io_out_s3_full_pred_1_offsets_1,
  output [49:0]  io_out_s3_full_pred_1_fallThroughAddr,
  output         io_out_s3_full_pred_1_fallThroughErr,
  output         io_out_s3_full_pred_1_multiHit,
  output         io_out_s3_full_pred_1_is_jal,
  output         io_out_s3_full_pred_1_is_jalr,
  output         io_out_s3_full_pred_1_is_call,
  output         io_out_s3_full_pred_1_is_ret,
  output         io_out_s3_full_pred_1_last_may_be_rvi_call,
  output         io_out_s3_full_pred_1_is_br_sharing,
  output         io_out_s3_full_pred_1_hit,
  output         io_out_s3_full_pred_2_br_taken_mask_0,
  output         io_out_s3_full_pred_2_br_taken_mask_1,
  output         io_out_s3_full_pred_2_slot_valids_0,
  output         io_out_s3_full_pred_2_slot_valids_1,
  output [49:0]  io_out_s3_full_pred_2_targets_0,
  output [49:0]  io_out_s3_full_pred_2_targets_1,
  output [3:0]   io_out_s3_full_pred_2_offsets_0,
  output [3:0]   io_out_s3_full_pred_2_offsets_1,
  output [49:0]  io_out_s3_full_pred_2_fallThroughAddr,
  output         io_out_s3_full_pred_2_fallThroughErr,
  output         io_out_s3_full_pred_2_multiHit,
  output         io_out_s3_full_pred_2_is_jal,
  output         io_out_s3_full_pred_2_is_jalr,
  output         io_out_s3_full_pred_2_is_call,
  output         io_out_s3_full_pred_2_is_ret,
  output         io_out_s3_full_pred_2_last_may_be_rvi_call,
  output         io_out_s3_full_pred_2_is_br_sharing,
  output         io_out_s3_full_pred_2_hit,
  output         io_out_s3_full_pred_3_br_taken_mask_0,
  output         io_out_s3_full_pred_3_br_taken_mask_1,
  output         io_out_s3_full_pred_3_slot_valids_0,
  output         io_out_s3_full_pred_3_slot_valids_1,
  output [49:0]  io_out_s3_full_pred_3_targets_0,
  output [49:0]  io_out_s3_full_pred_3_targets_1,
  output [3:0]   io_out_s3_full_pred_3_offsets_0,
  output [3:0]   io_out_s3_full_pred_3_offsets_1,
  output [49:0]  io_out_s3_full_pred_3_fallThroughAddr,
  output         io_out_s3_full_pred_3_fallThroughErr,
  output         io_out_s3_full_pred_3_multiHit,
  output         io_out_s3_full_pred_3_is_jal,
  output         io_out_s3_full_pred_3_is_jalr,
  output         io_out_s3_full_pred_3_is_call,
  output         io_out_s3_full_pred_3_is_ret,
  output         io_out_s3_full_pred_3_last_may_be_rvi_call,
  output         io_out_s3_full_pred_3_is_br_sharing,
  output         io_out_s3_full_pred_3_hit,
  output         io_out_s1_uftbHit,
  output         io_out_s1_uftbHasIndirect,
  output         io_out_s1_ftbCloseReq,
  output [515:0] io_out_last_stage_meta,
  output         io_out_last_stage_spec_info_sc_disagree_0,
  output         io_out_last_stage_spec_info_sc_disagree_1,
  output         io_out_last_stage_ftb_entry_isCall,
  output         io_out_last_stage_ftb_entry_isRet,
  output         io_out_last_stage_ftb_entry_isJalr,
  output         io_out_last_stage_ftb_entry_valid,
  output [3:0]   io_out_last_stage_ftb_entry_brSlots_0_offset,
  output         io_out_last_stage_ftb_entry_brSlots_0_sharing,
  output         io_out_last_stage_ftb_entry_brSlots_0_valid,
  output [11:0]  io_out_last_stage_ftb_entry_brSlots_0_lower,
  output [1:0]   io_out_last_stage_ftb_entry_brSlots_0_tarStat,
  output [3:0]   io_out_last_stage_ftb_entry_tailSlot_offset,
  output         io_out_last_stage_ftb_entry_tailSlot_sharing,
  output         io_out_last_stage_ftb_entry_tailSlot_valid,
  output [19:0]  io_out_last_stage_ftb_entry_tailSlot_lower,
  output [1:0]   io_out_last_stage_ftb_entry_tailSlot_tarStat,
  output [3:0]   io_out_last_stage_ftb_entry_pftAddr,
  output         io_out_last_stage_ftb_entry_carry,
  output         io_out_last_stage_ftb_entry_last_may_be_rvi_call,
  output         io_out_last_stage_ftb_entry_strong_bias_0,
  output         io_out_last_stage_ftb_entry_strong_bias_1,
  input          io_fauftb_entry_in_isCall,
  input          io_fauftb_entry_in_isRet,
  input          io_fauftb_entry_in_isJalr,
  input          io_fauftb_entry_in_valid,
  input  [3:0]   io_fauftb_entry_in_brSlots_0_offset,
  input          io_fauftb_entry_in_brSlots_0_sharing,
  input          io_fauftb_entry_in_brSlots_0_valid,
  input  [11:0]  io_fauftb_entry_in_brSlots_0_lower,
  input  [1:0]   io_fauftb_entry_in_brSlots_0_tarStat,
  input  [3:0]   io_fauftb_entry_in_tailSlot_offset,
  input          io_fauftb_entry_in_tailSlot_sharing,
  input          io_fauftb_entry_in_tailSlot_valid,
  input  [19:0]  io_fauftb_entry_in_tailSlot_lower,
  input  [1:0]   io_fauftb_entry_in_tailSlot_tarStat,
  input  [3:0]   io_fauftb_entry_in_pftAddr,
  input          io_fauftb_entry_in_carry,
  input          io_fauftb_entry_in_last_may_be_rvi_call,
  input          io_fauftb_entry_in_strong_bias_0,
  input          io_fauftb_entry_in_strong_bias_1,
  input          io_fauftb_entry_hit_in,
  input          io_ctrl_btb_enable,
  input          io_s0_fire_0,
  input          io_s0_fire_1,
  input          io_s0_fire_2,
  input          io_s0_fire_3,
  input          io_s1_fire_0,
  input          io_s1_fire_1,
  input          io_s1_fire_2,
  input          io_s1_fire_3,
  input          io_s2_fire_0,
  input          io_s2_fire_1,
  input          io_s2_fire_2,
  input          io_s2_fire_3,
  input          io_s3_fire_0,
  output         io_s1_ready,
  input          io_update_valid,
  input  [49:0]  io_update_bits_pc,
  input          io_update_bits_ftb_entry_isCall,
  input          io_update_bits_ftb_entry_isRet,
  input          io_update_bits_ftb_entry_isJalr,
  input          io_update_bits_ftb_entry_valid,
  input  [3:0]   io_update_bits_ftb_entry_brSlots_0_offset,
  input          io_update_bits_ftb_entry_brSlots_0_sharing,
  input          io_update_bits_ftb_entry_brSlots_0_valid,
  input  [11:0]  io_update_bits_ftb_entry_brSlots_0_lower,
  input  [1:0]   io_update_bits_ftb_entry_brSlots_0_tarStat,
  input  [3:0]   io_update_bits_ftb_entry_tailSlot_offset,
  input          io_update_bits_ftb_entry_tailSlot_sharing,
  input          io_update_bits_ftb_entry_tailSlot_valid,
  input  [19:0]  io_update_bits_ftb_entry_tailSlot_lower,
  input  [1:0]   io_update_bits_ftb_entry_tailSlot_tarStat,
  input  [3:0]   io_update_bits_ftb_entry_pftAddr,
  input          io_update_bits_ftb_entry_carry,
  input          io_update_bits_ftb_entry_last_may_be_rvi_call,
  input          io_update_bits_ftb_entry_strong_bias_0,
  input          io_update_bits_ftb_entry_strong_bias_1,
  input          io_update_bits_false_hit,
  input          io_update_bits_old_entry,
  input  [515:0] io_update_bits_meta,
  input          io_redirectFromIFU,
  output [5:0]   io_perf_0_value,
  output [5:0]   io_perf_1_value,
  input  [5:0]   boreChildrenBd_bore_array,
  input          boreChildrenBd_bore_all,
  input          boreChildrenBd_bore_req,
  output         boreChildrenBd_bore_ack,
  input          boreChildrenBd_bore_writeen,
  input  [3:0]   boreChildrenBd_bore_be,
  input  [9:0]   boreChildrenBd_bore_addr,
  input  [39:0]  boreChildrenBd_bore_indata,
  input          boreChildrenBd_bore_readen,
  input  [9:0]   boreChildrenBd_bore_addr_rd,
  output [39:0]  boreChildrenBd_bore_outdata,
  input          sigFromSrams_bore_ram_hold,
  input          sigFromSrams_bore_ram_bypass,
  input          sigFromSrams_bore_ram_bp_clken,
  input          sigFromSrams_bore_ram_aux_clk,
  input          sigFromSrams_bore_ram_aux_ckbp,
  input          sigFromSrams_bore_ram_mcp_hold,
  input          sigFromSrams_bore_cgen,
  input          sigFromSrams_bore_1_ram_hold,
  input          sigFromSrams_bore_1_ram_bypass,
  input          sigFromSrams_bore_1_ram_bp_clken,
  input          sigFromSrams_bore_1_ram_aux_clk,
  input          sigFromSrams_bore_1_ram_aux_ckbp,
  input          sigFromSrams_bore_1_ram_mcp_hold,
  input          sigFromSrams_bore_1_cgen,
  input          sigFromSrams_bore_2_ram_hold,
  input          sigFromSrams_bore_2_ram_bypass,
  input          sigFromSrams_bore_2_ram_bp_clken,
  input          sigFromSrams_bore_2_ram_aux_clk,
  input          sigFromSrams_bore_2_ram_aux_ckbp,
  input          sigFromSrams_bore_2_ram_mcp_hold,
  input          sigFromSrams_bore_2_cgen,
  input          sigFromSrams_bore_3_ram_hold,
  input          sigFromSrams_bore_3_ram_bypass,
  input          sigFromSrams_bore_3_ram_bp_clken,
  input          sigFromSrams_bore_3_ram_aux_clk,
  input          sigFromSrams_bore_3_ram_aux_ckbp,
  input          sigFromSrams_bore_3_ram_mcp_hold,
  input          sigFromSrams_bore_3_cgen,
  input          sigFromSrams_bore_4_ram_hold,
  input          sigFromSrams_bore_4_ram_bypass,
  input          sigFromSrams_bore_4_ram_bp_clken,
  input          sigFromSrams_bore_4_ram_aux_clk,
  input          sigFromSrams_bore_4_ram_aux_ckbp,
  input          sigFromSrams_bore_4_ram_mcp_hold,
  input          sigFromSrams_bore_4_cgen,
  input          sigFromSrams_bore_5_ram_hold,
  input          sigFromSrams_bore_5_ram_bypass,
  input          sigFromSrams_bore_5_ram_bp_clken,
  input          sigFromSrams_bore_5_ram_aux_clk,
  input          sigFromSrams_bore_5_ram_aux_ckbp,
  input          sigFromSrams_bore_5_ram_mcp_hold,
  input          sigFromSrams_bore_5_cgen,
  input          sigFromSrams_bore_6_ram_hold,
  input          sigFromSrams_bore_6_ram_bypass,
  input          sigFromSrams_bore_6_ram_bp_clken,
  input          sigFromSrams_bore_6_ram_aux_clk,
  input          sigFromSrams_bore_6_ram_aux_ckbp,
  input          sigFromSrams_bore_6_ram_mcp_hold,
  input          sigFromSrams_bore_6_cgen,
  input          sigFromSrams_bore_7_ram_hold,
  input          sigFromSrams_bore_7_ram_bypass,
  input          sigFromSrams_bore_7_ram_bp_clken,
  input          sigFromSrams_bore_7_ram_aux_clk,
  input          sigFromSrams_bore_7_ram_aux_ckbp,
  input          sigFromSrams_bore_7_ram_mcp_hold,
  input          sigFromSrams_bore_7_cgen
);

  // ---- 扁平 ftb_entry → struct（uFTB 输入条目 / update 输入条目）----
  function automatic ftb_entry_t pack_entry(
      input logic isCall, input logic isRet, input logic isJalr, input logic valid,
      input logic [3:0] br_off, input logic br_sh, input logic br_v,
      input logic [11:0] br_lo, input logic [1:0] br_ts,
      input logic [3:0] tl_off, input logic tl_sh, input logic tl_v,
      input logic [19:0] tl_lo, input logic [1:0] tl_ts,
      input logic [3:0] pft, input logic carry, input logic lastrvi,
      input logic sb0, input logic sb1);
    ftb_entry_t e;
    e = '0;
    e.valid = valid; e.isCall = isCall; e.isRet = isRet; e.isJalr = isJalr;
    e.brSlot.offset = br_off; e.brSlot.sharing = br_sh; e.brSlot.valid = br_v;
    e.brSlot.lower = {{(JMP_OFF_LEN-BR_OFF_LEN){1'b0}}, br_lo}; e.brSlot.tarStat = br_ts;
    e.tailSlot.offset = tl_off; e.tailSlot.sharing = tl_sh; e.tailSlot.valid = tl_v;
    e.tailSlot.lower = tl_lo; e.tailSlot.tarStat = tl_ts;
    e.pftAddr = pft; e.carry = carry; e.last_may_be_rvi_call = lastrvi;
    e.strong_bias = {sb1, sb0};
    return e;
  endfunction

  ftb_entry_t fauftb_entry, update_entry;
  assign fauftb_entry = pack_entry(
    io_fauftb_entry_in_isCall, io_fauftb_entry_in_isRet, io_fauftb_entry_in_isJalr, io_fauftb_entry_in_valid,
    io_fauftb_entry_in_brSlots_0_offset, io_fauftb_entry_in_brSlots_0_sharing, io_fauftb_entry_in_brSlots_0_valid,
    io_fauftb_entry_in_brSlots_0_lower, io_fauftb_entry_in_brSlots_0_tarStat,
    io_fauftb_entry_in_tailSlot_offset, io_fauftb_entry_in_tailSlot_sharing, io_fauftb_entry_in_tailSlot_valid,
    io_fauftb_entry_in_tailSlot_lower, io_fauftb_entry_in_tailSlot_tarStat,
    io_fauftb_entry_in_pftAddr, io_fauftb_entry_in_carry, io_fauftb_entry_in_last_may_be_rvi_call,
    io_fauftb_entry_in_strong_bias_0, io_fauftb_entry_in_strong_bias_1);
  assign update_entry = pack_entry(
    io_update_bits_ftb_entry_isCall, io_update_bits_ftb_entry_isRet, io_update_bits_ftb_entry_isJalr, io_update_bits_ftb_entry_valid,
    io_update_bits_ftb_entry_brSlots_0_offset, io_update_bits_ftb_entry_brSlots_0_sharing, io_update_bits_ftb_entry_brSlots_0_valid,
    io_update_bits_ftb_entry_brSlots_0_lower, io_update_bits_ftb_entry_brSlots_0_tarStat,
    io_update_bits_ftb_entry_tailSlot_offset, io_update_bits_ftb_entry_tailSlot_sharing, io_update_bits_ftb_entry_tailSlot_valid,
    io_update_bits_ftb_entry_tailSlot_lower, io_update_bits_ftb_entry_tailSlot_tarStat,
    io_update_bits_ftb_entry_pftAddr, io_update_bits_ftb_entry_carry, io_update_bits_ftb_entry_last_may_be_rvi_call,
    io_update_bits_ftb_entry_strong_bias_0, io_update_bits_ftb_entry_strong_bias_1);

  // ---- 数组化的输入 / fire ----
  logic [49:0] s0_pc       [4];
  logic        s0_fire     [4];
  logic        s1_fire     [4];
  logic        s2_fire     [4];
  logic [1:0]  in_s2_btm   [4];
  logic [1:0]  in_s3_btm   [4];
  assign s0_pc[0]=io_in_bits_s0_pc_0; assign s0_pc[1]=io_in_bits_s0_pc_1;
  assign s0_pc[2]=io_in_bits_s0_pc_2; assign s0_pc[3]=io_in_bits_s0_pc_3;
  assign s0_fire[0]=io_s0_fire_0; assign s0_fire[1]=io_s0_fire_1;
  assign s0_fire[2]=io_s0_fire_2; assign s0_fire[3]=io_s0_fire_3;
  assign s1_fire[0]=io_s1_fire_0; assign s1_fire[1]=io_s1_fire_1;
  assign s1_fire[2]=io_s1_fire_2; assign s1_fire[3]=io_s1_fire_3;
  assign s2_fire[0]=io_s2_fire_0; assign s2_fire[1]=io_s2_fire_1;
  assign s2_fire[2]=io_s2_fire_2; assign s2_fire[3]=io_s2_fire_3;
  assign in_s2_btm[0]={io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1, io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0};
  assign in_s2_btm[1]={io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1, io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0};
  assign in_s2_btm[2]={io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1, io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0};
  assign in_s2_btm[3]={io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1, io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0};
  assign in_s3_btm[0]={io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1, io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0};
  assign in_s3_btm[1]={io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1, io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0};
  assign in_s3_btm[2]={io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1, io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0};
  assign in_s3_btm[3]={io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1, io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0};

  // ---- 核的数组输出 ----
  logic [1:0]  o_s2_btm  [4]; logic [1:0] o_s2_sv [4];
  logic [49:0] o_s2_t0 [4]; logic [49:0] o_s2_t1 [4]; logic [49:0] o_s2_jt [4];
  logic [3:0]  o_s2_o0 [4]; logic [3:0] o_s2_o1 [4];
  logic [49:0] o_s2_fta [4]; logic o_s2_fte [4];
  logic o_s2_jal [4]; logic o_s2_jalr [4]; logic o_s2_call [4]; logic o_s2_ret [4];
  logic o_s2_lrvi [4]; logic o_s2_brsh [4]; logic o_s2_hit [4];
  logic [1:0]  o_s3_btm  [4]; logic [1:0] o_s3_sv [4];
  logic [49:0] o_s3_t0 [4]; logic [49:0] o_s3_t1 [4];
  logic [3:0]  o_s3_o0 [4]; logic [3:0] o_s3_o1 [4];
  logic [49:0] o_s3_fta [4]; logic o_s3_fte [4]; logic o_s3_mh [4];
  logic o_s3_jal [4]; logic o_s3_jalr [4]; logic o_s3_call [4]; logic o_s3_ret [4];
  logic o_s3_lrvi [4]; logic o_s3_brsh [4]; logic o_s3_hit [4];

  ftb_entry_t last_stage_entry;
  logic [1:0] last_stage_scd;

  // ---- 核 ↔ FTBBank 连线 ----
  logic        bk_s1_fire, bk_req_valid; logic [49:0] bk_req_bits; logic bk_req_ready;
  ftb_entry_t  bk_read_resp; logic bk_rh_v; logic [1:0] bk_rh_b;
  ftb_entry_t  bk_read_multi; logic bk_mh_v; logic [1:0] bk_mh_b;
  logic        bk_u_req_valid; logic [49:0] bk_u_req_bits; logic bk_uh_v; logic [1:0] bk_uh_b;
  logic        bk_u_access; logic [49:0] bk_u_pc; logic bk_w_valid;
  ftb_entry_t  bk_w_entry; logic [19:0] bk_w_tag; logic [1:0] bk_w_way; logic bk_w_alloc;

  // ---- 核 ↔ Delay 连线 ----
  logic [49:0] d_pc_in; logic d_pc_inv; logic [49:0] d_pc_out;
  ftb_entry_t  d_e_in;  logic d_e_inv;  ftb_entry_t  d_e_out;
  logic        d_wv_in, d_wv_out;

  // ---- 可读核 ----
  xs_FTB_core u_core (
    .clock(clock), .reset(reset), .io_reset_vector(io_reset_vector),
    .io_in_bits_s0_pc(s0_pc), .io_s0_fire(s0_fire), .io_s1_fire(s1_fire),
    .io_s2_fire(s2_fire), .io_s3_fire_0(io_s3_fire_0),
    .io_s1_ready(io_s1_ready), .io_ctrl_btb_enable(io_ctrl_btb_enable),
    .io_in_s2_br_taken_mask(in_s2_btm), .io_in_s3_br_taken_mask(in_s3_btm),
    .io_in_last_stage_sc_disagree({io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1,
                                   io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0}),
    .io_fauftb_entry_in(fauftb_entry), .io_fauftb_entry_hit_in(io_fauftb_entry_hit_in),
    .io_out_s2_br_taken_mask(o_s2_btm), .io_out_s2_slot_valids(o_s2_sv),
    .io_out_s2_targets_0(o_s2_t0), .io_out_s2_targets_1(o_s2_t1), .io_out_s2_jalr_target(o_s2_jt),
    .io_out_s2_offsets_0(o_s2_o0), .io_out_s2_offsets_1(o_s2_o1),
    .io_out_s2_fallThroughAddr(o_s2_fta), .io_out_s2_fallThroughErr(o_s2_fte),
    .io_out_s2_is_jal(o_s2_jal), .io_out_s2_is_jalr(o_s2_jalr), .io_out_s2_is_call(o_s2_call),
    .io_out_s2_is_ret(o_s2_ret), .io_out_s2_last_may_be_rvi_call(o_s2_lrvi),
    .io_out_s2_is_br_sharing(o_s2_brsh), .io_out_s2_hit(o_s2_hit),
    .io_out_s3_br_taken_mask(o_s3_btm), .io_out_s3_slot_valids(o_s3_sv),
    .io_out_s3_targets_0(o_s3_t0), .io_out_s3_targets_1(o_s3_t1),
    .io_out_s3_offsets_0(o_s3_o0), .io_out_s3_offsets_1(o_s3_o1),
    .io_out_s3_fallThroughAddr(o_s3_fta), .io_out_s3_fallThroughErr(o_s3_fte),
    .io_out_s3_multiHit(o_s3_mh),
    .io_out_s3_is_jal(o_s3_jal), .io_out_s3_is_jalr(o_s3_jalr), .io_out_s3_is_call(o_s3_call),
    .io_out_s3_is_ret(o_s3_ret), .io_out_s3_last_may_be_rvi_call(o_s3_lrvi),
    .io_out_s3_is_br_sharing(o_s3_brsh), .io_out_s3_hit(o_s3_hit),
    .io_out_s1_uftbHit(io_out_s1_uftbHit), .io_out_s1_uftbHasIndirect(io_out_s1_uftbHasIndirect),
    .io_out_s1_ftbCloseReq(io_out_s1_ftbCloseReq),
    .io_out_last_stage_meta(io_out_last_stage_meta),
    .io_out_last_stage_sc_disagree(last_stage_scd),
    .io_out_last_stage_ftb_entry(last_stage_entry),
    .io_update_valid(io_update_valid), .io_update_bits_pc(io_update_bits_pc),
    .io_update_bits_ftb_entry(update_entry),
    .io_update_bits_false_hit(io_update_bits_false_hit),
    .io_update_bits_old_entry(io_update_bits_old_entry),
    .io_update_bits_meta(io_update_bits_meta), .io_redirectFromIFU(io_redirectFromIFU),
    .io_perf_0_value(io_perf_0_value), .io_perf_1_value(io_perf_1_value),
    // FTBBank
    .ftbBank_io_s1_fire(bk_s1_fire), .ftbBank_io_req_pc_valid(bk_req_valid),
    .ftbBank_io_req_pc_bits(bk_req_bits), .ftbBank_io_req_pc_ready(bk_req_ready),
    .ftbBank_read_resp(bk_read_resp), .ftbBank_io_read_hits_valid(bk_rh_v),
    .ftbBank_io_read_hits_bits(bk_rh_b), .ftbBank_read_multi_entry(bk_read_multi),
    .ftbBank_io_read_multi_hits_valid(bk_mh_v), .ftbBank_io_read_multi_hits_bits(bk_mh_b),
    .ftbBank_io_u_req_pc_valid(bk_u_req_valid), .ftbBank_io_u_req_pc_bits(bk_u_req_bits),
    .ftbBank_io_update_hits_valid(bk_uh_v), .ftbBank_io_update_hits_bits(bk_uh_b),
    .ftbBank_io_update_access(bk_u_access), .ftbBank_io_update_pc(bk_u_pc),
    .ftbBank_io_update_write_data_valid(bk_w_valid),
    .ftbBank_update_write_entry(bk_w_entry), .ftbBank_io_update_write_tag(bk_w_tag),
    .ftbBank_io_update_write_way(bk_w_way), .ftbBank_io_update_write_alloc(bk_w_alloc),
    // Delay
    .delay_pc_in_bits(d_pc_in), .delay_pc_in_valid(d_pc_inv), .delay_pc_out_bits(d_pc_out),
    .delay_entry_in_bits(d_e_in), .delay_entry_in_valid(d_e_inv), .delay_entry_out_bits(d_e_out),
    .delay_wv_in(d_wv_in), .delay_wv_out(d_wv_out)
  );

  // ---- 核数组输出 → 扁平端口（逐 dup 展开宏）----
  `define S2OUT(N) \
    assign io_out_s2_full_pred_``N``_br_taken_mask_0 = o_s2_btm[N][0]; \
    assign io_out_s2_full_pred_``N``_br_taken_mask_1 = o_s2_btm[N][1]; \
    assign io_out_s2_full_pred_``N``_slot_valids_0   = o_s2_sv[N][0]; \
    assign io_out_s2_full_pred_``N``_slot_valids_1   = o_s2_sv[N][1]; \
    assign io_out_s2_full_pred_``N``_targets_0       = o_s2_t0[N]; \
    assign io_out_s2_full_pred_``N``_targets_1       = o_s2_t1[N]; \
    assign io_out_s2_full_pred_``N``_jalr_target     = o_s2_jt[N]; \
    assign io_out_s2_full_pred_``N``_offsets_0       = o_s2_o0[N]; \
    assign io_out_s2_full_pred_``N``_offsets_1       = o_s2_o1[N]; \
    assign io_out_s2_full_pred_``N``_fallThroughAddr = o_s2_fta[N]; \
    assign io_out_s2_full_pred_``N``_fallThroughErr  = o_s2_fte[N]; \
    assign io_out_s2_full_pred_``N``_is_jal          = o_s2_jal[N]; \
    assign io_out_s2_full_pred_``N``_is_jalr         = o_s2_jalr[N]; \
    assign io_out_s2_full_pred_``N``_is_call         = o_s2_call[N]; \
    assign io_out_s2_full_pred_``N``_is_ret          = o_s2_ret[N]; \
    assign io_out_s2_full_pred_``N``_last_may_be_rvi_call = o_s2_lrvi[N]; \
    assign io_out_s2_full_pred_``N``_is_br_sharing   = o_s2_brsh[N]; \
    assign io_out_s2_full_pred_``N``_hit             = o_s2_hit[N]
  `define S3OUT(N) \
    assign io_out_s3_full_pred_``N``_br_taken_mask_0 = o_s3_btm[N][0]; \
    assign io_out_s3_full_pred_``N``_br_taken_mask_1 = o_s3_btm[N][1]; \
    assign io_out_s3_full_pred_``N``_slot_valids_0   = o_s3_sv[N][0]; \
    assign io_out_s3_full_pred_``N``_slot_valids_1   = o_s3_sv[N][1]; \
    assign io_out_s3_full_pred_``N``_targets_0       = o_s3_t0[N]; \
    assign io_out_s3_full_pred_``N``_targets_1       = o_s3_t1[N]; \
    assign io_out_s3_full_pred_``N``_offsets_0       = o_s3_o0[N]; \
    assign io_out_s3_full_pred_``N``_offsets_1       = o_s3_o1[N]; \
    assign io_out_s3_full_pred_``N``_fallThroughAddr = o_s3_fta[N]; \
    assign io_out_s3_full_pred_``N``_fallThroughErr  = o_s3_fte[N]; \
    assign io_out_s3_full_pred_``N``_multiHit        = o_s3_mh[N]; \
    assign io_out_s3_full_pred_``N``_is_jal          = o_s3_jal[N]; \
    assign io_out_s3_full_pred_``N``_is_jalr         = o_s3_jalr[N]; \
    assign io_out_s3_full_pred_``N``_is_call         = o_s3_call[N]; \
    assign io_out_s3_full_pred_``N``_is_ret          = o_s3_ret[N]; \
    assign io_out_s3_full_pred_``N``_last_may_be_rvi_call = o_s3_lrvi[N]; \
    assign io_out_s3_full_pred_``N``_is_br_sharing   = o_s3_brsh[N]; \
    assign io_out_s3_full_pred_``N``_hit             = o_s3_hit[N]
  `S2OUT(0); `S2OUT(1); `S2OUT(2); `S2OUT(3);
  `S3OUT(0); `S3OUT(1); `S3OUT(2); `S3OUT(3);

  // ---- last_stage spec_info / ftb_entry 扁平化 ----
  assign io_out_last_stage_spec_info_sc_disagree_0 = last_stage_scd[0];
  assign io_out_last_stage_spec_info_sc_disagree_1 = last_stage_scd[1];
  assign io_out_last_stage_ftb_entry_isCall  = last_stage_entry.isCall;
  assign io_out_last_stage_ftb_entry_isRet   = last_stage_entry.isRet;
  assign io_out_last_stage_ftb_entry_isJalr  = last_stage_entry.isJalr;
  assign io_out_last_stage_ftb_entry_valid   = last_stage_entry.valid;
  assign io_out_last_stage_ftb_entry_brSlots_0_offset  = last_stage_entry.brSlot.offset;
  assign io_out_last_stage_ftb_entry_brSlots_0_sharing = last_stage_entry.brSlot.sharing;
  assign io_out_last_stage_ftb_entry_brSlots_0_valid   = last_stage_entry.brSlot.valid;
  assign io_out_last_stage_ftb_entry_brSlots_0_lower   = last_stage_entry.brSlot.lower[11:0];
  assign io_out_last_stage_ftb_entry_brSlots_0_tarStat = last_stage_entry.brSlot.tarStat;
  assign io_out_last_stage_ftb_entry_tailSlot_offset  = last_stage_entry.tailSlot.offset;
  assign io_out_last_stage_ftb_entry_tailSlot_sharing = last_stage_entry.tailSlot.sharing;
  assign io_out_last_stage_ftb_entry_tailSlot_valid   = last_stage_entry.tailSlot.valid;
  assign io_out_last_stage_ftb_entry_tailSlot_lower   = last_stage_entry.tailSlot.lower;
  assign io_out_last_stage_ftb_entry_tailSlot_tarStat = last_stage_entry.tailSlot.tarStat;
  assign io_out_last_stage_ftb_entry_pftAddr = last_stage_entry.pftAddr;
  assign io_out_last_stage_ftb_entry_carry   = last_stage_entry.carry;
  assign io_out_last_stage_ftb_entry_last_may_be_rvi_call = last_stage_entry.last_may_be_rvi_call;
  assign io_out_last_stage_ftb_entry_strong_bias_0 = last_stage_entry.strong_bias[0];
  assign io_out_last_stage_ftb_entry_strong_bias_1 = last_stage_entry.strong_bias[1];

  // ===========================================================================
  // golden 同名子模块例化（黑盒）
  // ===========================================================================
  FTBBank ftbBank (
    .clock(clock), .reset(reset), .io_s1_fire(bk_s1_fire),
    .io_req_pc_ready(bk_req_ready), .io_req_pc_valid(bk_req_valid), .io_req_pc_bits(bk_req_bits),
    .io_read_resp_isCall(bk_read_resp.isCall), .io_read_resp_isRet(bk_read_resp.isRet),
    .io_read_resp_isJalr(bk_read_resp.isJalr), .io_read_resp_valid(bk_read_resp.valid),
    .io_read_resp_brSlots_0_offset(bk_read_resp.brSlot.offset),
    .io_read_resp_brSlots_0_sharing(bk_read_resp.brSlot.sharing),
    .io_read_resp_brSlots_0_valid(bk_read_resp.brSlot.valid),
    .io_read_resp_brSlots_0_lower(bk_read_resp.brSlot.lower[11:0]),
    .io_read_resp_brSlots_0_tarStat(bk_read_resp.brSlot.tarStat),
    .io_read_resp_tailSlot_offset(bk_read_resp.tailSlot.offset),
    .io_read_resp_tailSlot_sharing(bk_read_resp.tailSlot.sharing),
    .io_read_resp_tailSlot_valid(bk_read_resp.tailSlot.valid),
    .io_read_resp_tailSlot_lower(bk_read_resp.tailSlot.lower),
    .io_read_resp_tailSlot_tarStat(bk_read_resp.tailSlot.tarStat),
    .io_read_resp_pftAddr(bk_read_resp.pftAddr), .io_read_resp_carry(bk_read_resp.carry),
    .io_read_resp_last_may_be_rvi_call(bk_read_resp.last_may_be_rvi_call),
    .io_read_resp_strong_bias_0(bk_read_resp.strong_bias[0]),
    .io_read_resp_strong_bias_1(bk_read_resp.strong_bias[1]),
    .io_read_hits_valid(bk_rh_v), .io_read_hits_bits(bk_rh_b),
    .io_read_multi_entry_isCall(bk_read_multi.isCall), .io_read_multi_entry_isRet(bk_read_multi.isRet),
    .io_read_multi_entry_isJalr(bk_read_multi.isJalr), .io_read_multi_entry_valid(bk_read_multi.valid),
    .io_read_multi_entry_brSlots_0_offset(bk_read_multi.brSlot.offset),
    .io_read_multi_entry_brSlots_0_sharing(bk_read_multi.brSlot.sharing),
    .io_read_multi_entry_brSlots_0_valid(bk_read_multi.brSlot.valid),
    .io_read_multi_entry_brSlots_0_lower(bk_read_multi.brSlot.lower[11:0]),
    .io_read_multi_entry_brSlots_0_tarStat(bk_read_multi.brSlot.tarStat),
    .io_read_multi_entry_tailSlot_offset(bk_read_multi.tailSlot.offset),
    .io_read_multi_entry_tailSlot_sharing(bk_read_multi.tailSlot.sharing),
    .io_read_multi_entry_tailSlot_valid(bk_read_multi.tailSlot.valid),
    .io_read_multi_entry_tailSlot_lower(bk_read_multi.tailSlot.lower),
    .io_read_multi_entry_tailSlot_tarStat(bk_read_multi.tailSlot.tarStat),
    .io_read_multi_entry_pftAddr(bk_read_multi.pftAddr), .io_read_multi_entry_carry(bk_read_multi.carry),
    .io_read_multi_entry_last_may_be_rvi_call(bk_read_multi.last_may_be_rvi_call),
    .io_read_multi_entry_strong_bias_0(bk_read_multi.strong_bias[0]),
    .io_read_multi_entry_strong_bias_1(bk_read_multi.strong_bias[1]),
    .io_read_multi_hits_valid(bk_mh_v), .io_read_multi_hits_bits(bk_mh_b),
    .io_u_req_pc_valid(bk_u_req_valid), .io_u_req_pc_bits(bk_u_req_bits),
    .io_update_hits_valid(bk_uh_v), .io_update_hits_bits(bk_uh_b),
    .io_update_access(bk_u_access), .io_update_pc(bk_u_pc),
    .io_update_write_data_valid(bk_w_valid),
    .io_update_write_data_bits_entry_isCall(bk_w_entry.isCall),
    .io_update_write_data_bits_entry_isRet(bk_w_entry.isRet),
    .io_update_write_data_bits_entry_isJalr(bk_w_entry.isJalr),
    .io_update_write_data_bits_entry_valid(bk_w_entry.valid),
    .io_update_write_data_bits_entry_brSlots_0_offset(bk_w_entry.brSlot.offset),
    .io_update_write_data_bits_entry_brSlots_0_sharing(bk_w_entry.brSlot.sharing),
    .io_update_write_data_bits_entry_brSlots_0_valid(bk_w_entry.brSlot.valid),
    .io_update_write_data_bits_entry_brSlots_0_lower(bk_w_entry.brSlot.lower[11:0]),
    .io_update_write_data_bits_entry_brSlots_0_tarStat(bk_w_entry.brSlot.tarStat),
    .io_update_write_data_bits_entry_tailSlot_offset(bk_w_entry.tailSlot.offset),
    .io_update_write_data_bits_entry_tailSlot_sharing(bk_w_entry.tailSlot.sharing),
    .io_update_write_data_bits_entry_tailSlot_valid(bk_w_entry.tailSlot.valid),
    .io_update_write_data_bits_entry_tailSlot_lower(bk_w_entry.tailSlot.lower),
    .io_update_write_data_bits_entry_tailSlot_tarStat(bk_w_entry.tailSlot.tarStat),
    .io_update_write_data_bits_entry_pftAddr(bk_w_entry.pftAddr),
    .io_update_write_data_bits_entry_carry(bk_w_entry.carry),
    .io_update_write_data_bits_entry_last_may_be_rvi_call(bk_w_entry.last_may_be_rvi_call),
    .io_update_write_data_bits_entry_strong_bias_0(bk_w_entry.strong_bias[0]),
    .io_update_write_data_bits_entry_strong_bias_1(bk_w_entry.strong_bias[1]),
    .io_update_write_data_bits_tag(bk_w_tag),
    .io_update_write_way(bk_w_way), .io_update_write_alloc(bk_w_alloc),
    .boreChildrenBd_bore_array(boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all(boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req(boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack(boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen(boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be(boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata(boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen(boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata(boreChildrenBd_bore_outdata),
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
    .sigFromSrams_bore_1_cgen(sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold(sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass(sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken(sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk(sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp(sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold(sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen(sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold(sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass(sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken(sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk(sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp(sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold(sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen(sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold(sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass(sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken(sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk(sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp(sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold(sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen(sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold(sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass(sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken(sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk(sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp(sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold(sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen(sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold(sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass(sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken(sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk(sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp(sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold(sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen(sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold(sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass(sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken(sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk(sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp(sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold(sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen(sigFromSrams_bore_7_cgen)
  );

  // pc 延 2 拍（DelayNWithValid）
  DelayNWithValid delay2_pc_pipMod (
    .clock(clock), .reset(reset),
    .io_in_bits(d_pc_in), .io_in_valid(d_pc_inv), .io_out_bits(d_pc_out)
  );

  // entry 延 2 拍（DelayNWithValid_1，扁平字段）
  DelayNWithValid_1 delay2_entry_pipMod (
    .clock(clock), .reset(reset),
    .io_in_bits_isCall(d_e_in.isCall), .io_in_bits_isRet(d_e_in.isRet),
    .io_in_bits_isJalr(d_e_in.isJalr), .io_in_bits_valid(d_e_in.valid),
    .io_in_bits_brSlots_0_offset(d_e_in.brSlot.offset),
    .io_in_bits_brSlots_0_sharing(d_e_in.brSlot.sharing),
    .io_in_bits_brSlots_0_valid(d_e_in.brSlot.valid),
    .io_in_bits_brSlots_0_lower(d_e_in.brSlot.lower[11:0]),
    .io_in_bits_brSlots_0_tarStat(d_e_in.brSlot.tarStat),
    .io_in_bits_tailSlot_offset(d_e_in.tailSlot.offset),
    .io_in_bits_tailSlot_sharing(d_e_in.tailSlot.sharing),
    .io_in_bits_tailSlot_valid(d_e_in.tailSlot.valid),
    .io_in_bits_tailSlot_lower(d_e_in.tailSlot.lower),
    .io_in_bits_tailSlot_tarStat(d_e_in.tailSlot.tarStat),
    .io_in_bits_pftAddr(d_e_in.pftAddr), .io_in_bits_carry(d_e_in.carry),
    .io_in_bits_last_may_be_rvi_call(d_e_in.last_may_be_rvi_call),
    .io_in_bits_strong_bias_0(d_e_in.strong_bias[0]),
    .io_in_bits_strong_bias_1(d_e_in.strong_bias[1]),
    .io_in_valid(d_e_inv),
    .io_out_bits_isCall(d_e_out.isCall), .io_out_bits_isRet(d_e_out.isRet),
    .io_out_bits_isJalr(d_e_out.isJalr), .io_out_bits_valid(d_e_out.valid),
    .io_out_bits_brSlots_0_offset(d_e_out.brSlot.offset),
    .io_out_bits_brSlots_0_sharing(d_e_out.brSlot.sharing),
    .io_out_bits_brSlots_0_valid(d_e_out.brSlot.valid),
    .io_out_bits_brSlots_0_lower(d_e_out.brSlot.lower[11:0]),
    .io_out_bits_brSlots_0_tarStat(d_e_out.brSlot.tarStat),
    .io_out_bits_tailSlot_offset(d_e_out.tailSlot.offset),
    .io_out_bits_tailSlot_sharing(d_e_out.tailSlot.sharing),
    .io_out_bits_tailSlot_valid(d_e_out.tailSlot.valid),
    .io_out_bits_tailSlot_lower(d_e_out.tailSlot.lower),
    .io_out_bits_tailSlot_tarStat(d_e_out.tailSlot.tarStat),
    .io_out_bits_pftAddr(d_e_out.pftAddr), .io_out_bits_carry(d_e_out.carry),
    .io_out_bits_last_may_be_rvi_call(d_e_out.last_may_be_rvi_call),
    .io_out_bits_strong_bias_0(d_e_out.strong_bias[0]),
    .io_out_bits_strong_bias_1(d_e_out.strong_bias[1])
  );

  // d_e_out 的 brSlot.lower 高位补 0（核侧用低 12 位）
  assign d_e_out.brSlot.lower[19:12] = 8'h0;

  // write_valid 延 2 拍（DelayN_1）
  DelayN_1 write_valid_delay (
    .clock(clock), .io_in(d_wv_in), .io_out(d_wv_out)
  );

endmodule
