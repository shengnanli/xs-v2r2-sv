// probe.sv —— 调试辅助（**不在验收流程里**，Makefile 默认不编它）。
//
// 用途：逐拍比对 golden 侧 dut_g.predictors 与重写侧 dut_i.predictors 的
// **全部 98 个功能输入**，找出最早发散的那一根。本轮就是靠它一把定位到
// wrapper 漏接了 Composer 的 io_in_bits_ghist（整根悬空成 z）。
//
// 用法（注意两个坑）：
//   1. probe 是独立 root，`-top tb` 不会 elaborate 它 —— 必须在 tb 里
//      instantiate 一句 `probe u_probe();`（拷一份 tb.sv 改即可）；
//   2. 改了 TB_SRCS 也未必重编，先 `rm -rf simv simv.daidir csrc`。
//   make compile TB_SRCS="tb_probe.sv probe.sv" && ./simv +ncycles=3000 -l sim_probe.log
module probe;
  longint n = 0;
  bit reported = 0;
  bit reported2 = 0;
  task automatic chk(string nm, logic [255:0] g, logic [255:0] i);
    if (!reported && !$isunknown(g) && g !== i) begin
      $display("[PROBE %0t] FIRST DIVERGE on %s  g=%h i=%h", $time, nm, g, i);
      reported = 1; end
  endtask
  always @(posedge tb.clk) begin
    n++;
    if (n == 40) $display("[PROBE] alive at n=40, t=%0t", $time);
    if (n > 0) begin
      chk("io_reset_vector", tb.dut_g.predictors.io_reset_vector, tb.dut_i.predictors.io_reset_vector);
      chk("io_in_bits_s0_pc_0", tb.dut_g.predictors.io_in_bits_s0_pc_0, tb.dut_i.predictors.io_in_bits_s0_pc_0);
      chk("io_in_bits_s0_pc_1", tb.dut_g.predictors.io_in_bits_s0_pc_1, tb.dut_i.predictors.io_in_bits_s0_pc_1);
      chk("io_in_bits_s0_pc_2", tb.dut_g.predictors.io_in_bits_s0_pc_2, tb.dut_i.predictors.io_in_bits_s0_pc_2);
      chk("io_in_bits_s0_pc_3", tb.dut_g.predictors.io_in_bits_s0_pc_3, tb.dut_i.predictors.io_in_bits_s0_pc_3);
      chk("io_in_bits_folded_hist_1_hist_17_folded_hist", tb.dut_g.predictors.io_in_bits_folded_hist_1_hist_17_folded_hist, tb.dut_i.predictors.io_in_bits_folded_hist_1_hist_17_folded_hist);
      chk("io_in_bits_folded_hist_1_hist_16_folded_hist", tb.dut_g.predictors.io_in_bits_folded_hist_1_hist_16_folded_hist, tb.dut_i.predictors.io_in_bits_folded_hist_1_hist_16_folded_hist);
      chk("io_in_bits_folded_hist_1_hist_15_folded_hist", tb.dut_g.predictors.io_in_bits_folded_hist_1_hist_15_folded_hist, tb.dut_i.predictors.io_in_bits_folded_hist_1_hist_15_folded_hist);
      chk("io_in_bits_folded_hist_1_hist_14_folded_hist", tb.dut_g.predictors.io_in_bits_folded_hist_1_hist_14_folded_hist, tb.dut_i.predictors.io_in_bits_folded_hist_1_hist_14_folded_hist);
      chk("io_in_bits_folded_hist_1_hist_9_folded_hist", tb.dut_g.predictors.io_in_bits_folded_hist_1_hist_9_folded_hist, tb.dut_i.predictors.io_in_bits_folded_hist_1_hist_9_folded_hist);
      chk("io_in_bits_folded_hist_1_hist_8_folded_hist", tb.dut_g.predictors.io_in_bits_folded_hist_1_hist_8_folded_hist, tb.dut_i.predictors.io_in_bits_folded_hist_1_hist_8_folded_hist);
      chk("io_in_bits_folded_hist_1_hist_7_folded_hist", tb.dut_g.predictors.io_in_bits_folded_hist_1_hist_7_folded_hist, tb.dut_i.predictors.io_in_bits_folded_hist_1_hist_7_folded_hist);
      chk("io_in_bits_folded_hist_1_hist_5_folded_hist", tb.dut_g.predictors.io_in_bits_folded_hist_1_hist_5_folded_hist, tb.dut_i.predictors.io_in_bits_folded_hist_1_hist_5_folded_hist);
      chk("io_in_bits_folded_hist_1_hist_4_folded_hist", tb.dut_g.predictors.io_in_bits_folded_hist_1_hist_4_folded_hist, tb.dut_i.predictors.io_in_bits_folded_hist_1_hist_4_folded_hist);
      chk("io_in_bits_folded_hist_1_hist_3_folded_hist", tb.dut_g.predictors.io_in_bits_folded_hist_1_hist_3_folded_hist, tb.dut_i.predictors.io_in_bits_folded_hist_1_hist_3_folded_hist);
      chk("io_in_bits_folded_hist_1_hist_1_folded_hist", tb.dut_g.predictors.io_in_bits_folded_hist_1_hist_1_folded_hist, tb.dut_i.predictors.io_in_bits_folded_hist_1_hist_1_folded_hist);
      chk("io_in_bits_folded_hist_3_hist_12_folded_hist", tb.dut_g.predictors.io_in_bits_folded_hist_3_hist_12_folded_hist, tb.dut_i.predictors.io_in_bits_folded_hist_3_hist_12_folded_hist);
      chk("io_in_bits_folded_hist_3_hist_11_folded_hist", tb.dut_g.predictors.io_in_bits_folded_hist_3_hist_11_folded_hist, tb.dut_i.predictors.io_in_bits_folded_hist_3_hist_11_folded_hist);
      chk("io_in_bits_folded_hist_3_hist_2_folded_hist", tb.dut_g.predictors.io_in_bits_folded_hist_3_hist_2_folded_hist, tb.dut_i.predictors.io_in_bits_folded_hist_3_hist_2_folded_hist);
      chk("io_in_bits_s1_folded_hist_3_hist_14_folded_hist", tb.dut_g.predictors.io_in_bits_s1_folded_hist_3_hist_14_folded_hist, tb.dut_i.predictors.io_in_bits_s1_folded_hist_3_hist_14_folded_hist);
      chk("io_in_bits_s1_folded_hist_3_hist_13_folded_hist", tb.dut_g.predictors.io_in_bits_s1_folded_hist_3_hist_13_folded_hist, tb.dut_i.predictors.io_in_bits_s1_folded_hist_3_hist_13_folded_hist);
      chk("io_in_bits_s1_folded_hist_3_hist_12_folded_hist", tb.dut_g.predictors.io_in_bits_s1_folded_hist_3_hist_12_folded_hist, tb.dut_i.predictors.io_in_bits_s1_folded_hist_3_hist_12_folded_hist);
      chk("io_in_bits_s1_folded_hist_3_hist_10_folded_hist", tb.dut_g.predictors.io_in_bits_s1_folded_hist_3_hist_10_folded_hist, tb.dut_i.predictors.io_in_bits_s1_folded_hist_3_hist_10_folded_hist);
      chk("io_in_bits_s1_folded_hist_3_hist_6_folded_hist", tb.dut_g.predictors.io_in_bits_s1_folded_hist_3_hist_6_folded_hist, tb.dut_i.predictors.io_in_bits_s1_folded_hist_3_hist_6_folded_hist);
      chk("io_in_bits_s1_folded_hist_3_hist_4_folded_hist", tb.dut_g.predictors.io_in_bits_s1_folded_hist_3_hist_4_folded_hist, tb.dut_i.predictors.io_in_bits_s1_folded_hist_3_hist_4_folded_hist);
      chk("io_in_bits_s1_folded_hist_3_hist_3_folded_hist", tb.dut_g.predictors.io_in_bits_s1_folded_hist_3_hist_3_folded_hist, tb.dut_i.predictors.io_in_bits_s1_folded_hist_3_hist_3_folded_hist);
      chk("io_in_bits_s1_folded_hist_3_hist_2_folded_hist", tb.dut_g.predictors.io_in_bits_s1_folded_hist_3_hist_2_folded_hist, tb.dut_i.predictors.io_in_bits_s1_folded_hist_3_hist_2_folded_hist);
      chk("io_in_bits_ghist", tb.dut_g.predictors.io_in_bits_ghist, tb.dut_i.predictors.io_in_bits_ghist);
      chk("io_ctrl_ubtb_enable", tb.dut_g.predictors.io_ctrl_ubtb_enable, tb.dut_i.predictors.io_ctrl_ubtb_enable);
      chk("io_ctrl_btb_enable", tb.dut_g.predictors.io_ctrl_btb_enable, tb.dut_i.predictors.io_ctrl_btb_enable);
      chk("io_ctrl_tage_enable", tb.dut_g.predictors.io_ctrl_tage_enable, tb.dut_i.predictors.io_ctrl_tage_enable);
      chk("io_ctrl_sc_enable", tb.dut_g.predictors.io_ctrl_sc_enable, tb.dut_i.predictors.io_ctrl_sc_enable);
      chk("io_ctrl_ras_enable", tb.dut_g.predictors.io_ctrl_ras_enable, tb.dut_i.predictors.io_ctrl_ras_enable);
      chk("io_s0_fire_0", tb.dut_g.predictors.io_s0_fire_0, tb.dut_i.predictors.io_s0_fire_0);
      chk("io_s0_fire_1", tb.dut_g.predictors.io_s0_fire_1, tb.dut_i.predictors.io_s0_fire_1);
      chk("io_s0_fire_2", tb.dut_g.predictors.io_s0_fire_2, tb.dut_i.predictors.io_s0_fire_2);
      chk("io_s0_fire_3", tb.dut_g.predictors.io_s0_fire_3, tb.dut_i.predictors.io_s0_fire_3);
      chk("io_s1_fire_0", tb.dut_g.predictors.io_s1_fire_0, tb.dut_i.predictors.io_s1_fire_0);
      chk("io_s1_fire_1", tb.dut_g.predictors.io_s1_fire_1, tb.dut_i.predictors.io_s1_fire_1);
      chk("io_s1_fire_2", tb.dut_g.predictors.io_s1_fire_2, tb.dut_i.predictors.io_s1_fire_2);
      chk("io_s1_fire_3", tb.dut_g.predictors.io_s1_fire_3, tb.dut_i.predictors.io_s1_fire_3);
      chk("io_s2_fire_0", tb.dut_g.predictors.io_s2_fire_0, tb.dut_i.predictors.io_s2_fire_0);
      chk("io_s2_fire_1", tb.dut_g.predictors.io_s2_fire_1, tb.dut_i.predictors.io_s2_fire_1);
      chk("io_s2_fire_2", tb.dut_g.predictors.io_s2_fire_2, tb.dut_i.predictors.io_s2_fire_2);
      chk("io_s2_fire_3", tb.dut_g.predictors.io_s2_fire_3, tb.dut_i.predictors.io_s2_fire_3);
      chk("io_s3_fire_0", tb.dut_g.predictors.io_s3_fire_0, tb.dut_i.predictors.io_s3_fire_0);
      chk("io_s3_fire_2", tb.dut_g.predictors.io_s3_fire_2, tb.dut_i.predictors.io_s3_fire_2);
      chk("io_s3_redirect_2", tb.dut_g.predictors.io_s3_redirect_2, tb.dut_i.predictors.io_s3_redirect_2);
      chk("io_update_valid", tb.dut_g.predictors.io_update_valid, tb.dut_i.predictors.io_update_valid);
      chk("io_update_bits_pc", tb.dut_g.predictors.io_update_bits_pc, tb.dut_i.predictors.io_update_bits_pc);
      chk("io_update_bits_ftb_entry_isCall", tb.dut_g.predictors.io_update_bits_ftb_entry_isCall, tb.dut_i.predictors.io_update_bits_ftb_entry_isCall);
      chk("io_update_bits_ftb_entry_isRet", tb.dut_g.predictors.io_update_bits_ftb_entry_isRet, tb.dut_i.predictors.io_update_bits_ftb_entry_isRet);
      chk("io_update_bits_ftb_entry_isJalr", tb.dut_g.predictors.io_update_bits_ftb_entry_isJalr, tb.dut_i.predictors.io_update_bits_ftb_entry_isJalr);
      chk("io_update_bits_ftb_entry_valid", tb.dut_g.predictors.io_update_bits_ftb_entry_valid, tb.dut_i.predictors.io_update_bits_ftb_entry_valid);
      chk("io_update_bits_ftb_entry_brSlots_0_offset", tb.dut_g.predictors.io_update_bits_ftb_entry_brSlots_0_offset, tb.dut_i.predictors.io_update_bits_ftb_entry_brSlots_0_offset);
      chk("io_update_bits_ftb_entry_brSlots_0_sharing", tb.dut_g.predictors.io_update_bits_ftb_entry_brSlots_0_sharing, tb.dut_i.predictors.io_update_bits_ftb_entry_brSlots_0_sharing);
      chk("io_update_bits_ftb_entry_brSlots_0_valid", tb.dut_g.predictors.io_update_bits_ftb_entry_brSlots_0_valid, tb.dut_i.predictors.io_update_bits_ftb_entry_brSlots_0_valid);
      chk("io_update_bits_ftb_entry_brSlots_0_lower", tb.dut_g.predictors.io_update_bits_ftb_entry_brSlots_0_lower, tb.dut_i.predictors.io_update_bits_ftb_entry_brSlots_0_lower);
      chk("io_update_bits_ftb_entry_brSlots_0_tarStat", tb.dut_g.predictors.io_update_bits_ftb_entry_brSlots_0_tarStat, tb.dut_i.predictors.io_update_bits_ftb_entry_brSlots_0_tarStat);
      chk("io_update_bits_ftb_entry_tailSlot_offset", tb.dut_g.predictors.io_update_bits_ftb_entry_tailSlot_offset, tb.dut_i.predictors.io_update_bits_ftb_entry_tailSlot_offset);
      chk("io_update_bits_ftb_entry_tailSlot_sharing", tb.dut_g.predictors.io_update_bits_ftb_entry_tailSlot_sharing, tb.dut_i.predictors.io_update_bits_ftb_entry_tailSlot_sharing);
      chk("io_update_bits_ftb_entry_tailSlot_valid", tb.dut_g.predictors.io_update_bits_ftb_entry_tailSlot_valid, tb.dut_i.predictors.io_update_bits_ftb_entry_tailSlot_valid);
      chk("io_update_bits_ftb_entry_tailSlot_lower", tb.dut_g.predictors.io_update_bits_ftb_entry_tailSlot_lower, tb.dut_i.predictors.io_update_bits_ftb_entry_tailSlot_lower);
      chk("io_update_bits_ftb_entry_tailSlot_tarStat", tb.dut_g.predictors.io_update_bits_ftb_entry_tailSlot_tarStat, tb.dut_i.predictors.io_update_bits_ftb_entry_tailSlot_tarStat);
      chk("io_update_bits_ftb_entry_pftAddr", tb.dut_g.predictors.io_update_bits_ftb_entry_pftAddr, tb.dut_i.predictors.io_update_bits_ftb_entry_pftAddr);
      chk("io_update_bits_ftb_entry_carry", tb.dut_g.predictors.io_update_bits_ftb_entry_carry, tb.dut_i.predictors.io_update_bits_ftb_entry_carry);
      chk("io_update_bits_ftb_entry_last_may_be_rvi_call", tb.dut_g.predictors.io_update_bits_ftb_entry_last_may_be_rvi_call, tb.dut_i.predictors.io_update_bits_ftb_entry_last_may_be_rvi_call);
      chk("io_update_bits_ftb_entry_strong_bias_0", tb.dut_g.predictors.io_update_bits_ftb_entry_strong_bias_0, tb.dut_i.predictors.io_update_bits_ftb_entry_strong_bias_0);
      chk("io_update_bits_ftb_entry_strong_bias_1", tb.dut_g.predictors.io_update_bits_ftb_entry_strong_bias_1, tb.dut_i.predictors.io_update_bits_ftb_entry_strong_bias_1);
      chk("io_update_bits_cfi_idx_valid", tb.dut_g.predictors.io_update_bits_cfi_idx_valid, tb.dut_i.predictors.io_update_bits_cfi_idx_valid);
      chk("io_update_bits_cfi_idx_bits", tb.dut_g.predictors.io_update_bits_cfi_idx_bits, tb.dut_i.predictors.io_update_bits_cfi_idx_bits);
      chk("io_update_bits_br_taken_mask_0", tb.dut_g.predictors.io_update_bits_br_taken_mask_0, tb.dut_i.predictors.io_update_bits_br_taken_mask_0);
      chk("io_update_bits_br_taken_mask_1", tb.dut_g.predictors.io_update_bits_br_taken_mask_1, tb.dut_i.predictors.io_update_bits_br_taken_mask_1);
      chk("io_update_bits_jmp_taken", tb.dut_g.predictors.io_update_bits_jmp_taken, tb.dut_i.predictors.io_update_bits_jmp_taken);
      chk("io_update_bits_mispred_mask_0", tb.dut_g.predictors.io_update_bits_mispred_mask_0, tb.dut_i.predictors.io_update_bits_mispred_mask_0);
      chk("io_update_bits_mispred_mask_1", tb.dut_g.predictors.io_update_bits_mispred_mask_1, tb.dut_i.predictors.io_update_bits_mispred_mask_1);
      chk("io_update_bits_mispred_mask_2", tb.dut_g.predictors.io_update_bits_mispred_mask_2, tb.dut_i.predictors.io_update_bits_mispred_mask_2);
      chk("io_update_bits_false_hit", tb.dut_g.predictors.io_update_bits_false_hit, tb.dut_i.predictors.io_update_bits_false_hit);
      chk("io_update_bits_old_entry", tb.dut_g.predictors.io_update_bits_old_entry, tb.dut_i.predictors.io_update_bits_old_entry);
      chk("io_update_bits_meta", tb.dut_g.predictors.io_update_bits_meta, tb.dut_i.predictors.io_update_bits_meta);
      chk("io_update_bits_full_target", tb.dut_g.predictors.io_update_bits_full_target, tb.dut_i.predictors.io_update_bits_full_target);
      chk("io_update_bits_ghist", tb.dut_g.predictors.io_update_bits_ghist, tb.dut_i.predictors.io_update_bits_ghist);
      chk("io_redirect_valid", tb.dut_g.predictors.io_redirect_valid, tb.dut_i.predictors.io_redirect_valid);
      chk("io_redirect_bits_level", tb.dut_g.predictors.io_redirect_bits_level, tb.dut_i.predictors.io_redirect_bits_level);
      chk("io_redirect_bits_cfiUpdate_pc", tb.dut_g.predictors.io_redirect_bits_cfiUpdate_pc, tb.dut_i.predictors.io_redirect_bits_cfiUpdate_pc);
      chk("io_redirect_bits_cfiUpdate_pd_valid", tb.dut_g.predictors.io_redirect_bits_cfiUpdate_pd_valid, tb.dut_i.predictors.io_redirect_bits_cfiUpdate_pd_valid);
      chk("io_redirect_bits_cfiUpdate_pd_isRVC", tb.dut_g.predictors.io_redirect_bits_cfiUpdate_pd_isRVC, tb.dut_i.predictors.io_redirect_bits_cfiUpdate_pd_isRVC);
      chk("io_redirect_bits_cfiUpdate_pd_isCall", tb.dut_g.predictors.io_redirect_bits_cfiUpdate_pd_isCall, tb.dut_i.predictors.io_redirect_bits_cfiUpdate_pd_isCall);
      chk("io_redirect_bits_cfiUpdate_pd_isRet", tb.dut_g.predictors.io_redirect_bits_cfiUpdate_pd_isRet, tb.dut_i.predictors.io_redirect_bits_cfiUpdate_pd_isRet);
      chk("io_redirect_bits_cfiUpdate_ssp", tb.dut_g.predictors.io_redirect_bits_cfiUpdate_ssp, tb.dut_i.predictors.io_redirect_bits_cfiUpdate_ssp);
      chk("io_redirect_bits_cfiUpdate_sctr", tb.dut_g.predictors.io_redirect_bits_cfiUpdate_sctr, tb.dut_i.predictors.io_redirect_bits_cfiUpdate_sctr);
      chk("io_redirect_bits_cfiUpdate_TOSW_flag", tb.dut_g.predictors.io_redirect_bits_cfiUpdate_TOSW_flag, tb.dut_i.predictors.io_redirect_bits_cfiUpdate_TOSW_flag);
      chk("io_redirect_bits_cfiUpdate_TOSW_value", tb.dut_g.predictors.io_redirect_bits_cfiUpdate_TOSW_value, tb.dut_i.predictors.io_redirect_bits_cfiUpdate_TOSW_value);
      chk("io_redirect_bits_cfiUpdate_TOSR_flag", tb.dut_g.predictors.io_redirect_bits_cfiUpdate_TOSR_flag, tb.dut_i.predictors.io_redirect_bits_cfiUpdate_TOSR_flag);
      chk("io_redirect_bits_cfiUpdate_TOSR_value", tb.dut_g.predictors.io_redirect_bits_cfiUpdate_TOSR_value, tb.dut_i.predictors.io_redirect_bits_cfiUpdate_TOSR_value);
      chk("io_redirect_bits_cfiUpdate_NOS_flag", tb.dut_g.predictors.io_redirect_bits_cfiUpdate_NOS_flag, tb.dut_i.predictors.io_redirect_bits_cfiUpdate_NOS_flag);
      chk("io_redirect_bits_cfiUpdate_NOS_value", tb.dut_g.predictors.io_redirect_bits_cfiUpdate_NOS_value, tb.dut_i.predictors.io_redirect_bits_cfiUpdate_NOS_value);
      chk("io_redirectFromIFU", tb.dut_g.predictors.io_redirectFromIFU, tb.dut_i.predictors.io_redirectFromIFU);
    end
    // Composer 输出侧：输入全同而输出不同 => 两个实例内部状态不同
    if (!reported2 && !$isunknown(tb.dut_g.predictors.io_out_s3_pc_0)
        && tb.dut_g.predictors.io_out_s3_pc_0 !== tb.dut_i.predictors.io_out_s3_pc_0) begin
      $display("[PROBE %0t] Composer OUT s3_pc_0 diverge g=%h i=%h (n=%0d)", $time,
               tb.dut_g.predictors.io_out_s3_pc_0, tb.dut_i.predictors.io_out_s3_pc_0, n);
      reported2 = 1;
    end
  end
endmodule
