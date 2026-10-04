// Composer UT —— golden Composer 与重写 Composer_xs 双例化逐拍比对。
//
// 【为什么不能只比输出】
//   Composer 是装配壳：293 个输出里 282 个是子模块直连（两侧接的是同一份 golden
//   子模块，天然一致），真正由本层算出来的只有 11 个。如果只比输出，等于只验了
//   那 11 根，而且下面两块**一根输出都不经过**：
//     · MBIST boreChildrenBd_bore_{2..5}_addr 这轮由 9 位收窄到 8 位 —— 激励不打
//       最高位就等于没验位宽（本轮已发生过 3 次"位宽错但 UT 照过"）；
//     · s1/s2/s3 影子 PC 流水（utility.SegmentedAddrNext）是 cone-dead 的，值不出现
//       在任何输出上。
//   所以本 tb 除逐拍比 293 个输出外，另加：
//     (a) 层次探针：两侧 29 个内部寄存器（modified_reset / s1_pc×4 / s2、s3 各 12 段）
//         逐拍比 —— 把 cone-dead 那条链直接钉住；
//     (b) 覆盖闸：关键事件计数为 0 即判 FAIL（见文件尾的判定段）。
//
// 【激励设计要点】
//   · s0_pc 大部分拍只在低 12 位小步走（让 SegmentedAddrNext 的高段"没变"分支生效），
//     少数拍整段跳（让"变了"分支生效）—— 两条分支都要打到。
//   · reset 在运行中反复拉起放下，让 modified_reset 那一拍脉冲被反复观测
//     （G1 相对 G0 正是把这个脉冲提前了一拍，只复位一次就只有一次机会看到）。
//   · MBIST addr / addr_rd 全宽随机，最高位必须被打到。
//
// 自动生成：tools/predictor_composer/gen_ut.py —— 勿手改
`timescale 1ns/1ps
`define CHECK(SIG) begin \
  if (!$isunknown(g_``SIG)) begin \
    checks++; \
    if (g_``SIG !== i_``SIG) begin \
      errors++; \
      if (errors <= 30) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \
    end \
  end \
end
`define CHECKH(NAME, G, I) begin \
  if (!$isunknown(G)) begin \
    hchecks++; \
    if ((G) !== (I)) begin \
      herrors++; \
      if (herrors <= 30) $display("[%0t] HIER MISMATCH %s g=%0h i=%0h", $time, NAME, G, I); \
    end \
  end \
end

module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  logic reset;
  int errors = 0, checks = 0;
  int herrors = 0, hchecks = 0;
  always #5 clock = ~clock;

  // ---- 覆盖计数（0 即判 FAIL，见文件尾）----
  logic [3:0] fire_s0, fire_s1, fire_s2;   // 采样用临时向量
  int reset_pulses = 0;            // 复位放开次数（每次给 modified_reset 一次脉冲）
  int mres_hi = 0;                 // 观测到 modified_reset==1 的拍数
  int s0f[4], s1f[4], s2f[4];      // 各 dup 的 fire 拍数
  int seg_hi_same = 0, seg_hi_diff = 0;   // s2 高段"没变/变了"两条分支
  int seg_mid_same = 0, seg_mid_diff = 0;
  int s3_hi_same = 0, s3_hi_diff = 0;
  int mbist_addr_msb[4], mbist_addrrd_msb[4];  // bore2..5 的 addr[7]/addr_rd[7] 命中数
  logic [7:0] mbist_addr_or[4], mbist_addrrd_or[4];  // 逐位或（每位都要翻过）
  int mbist_outdata_checks = 0;    // bore2..5 outdata 真被比到的拍数（X 不算）
  int s1_ready_hi = 0, s1_ready_lo = 0;
  int s1r_lo[3];                   // tage / ftb / ittage 各自为 0 的拍数
  int s1r_only_lo[3];              // 只有这一路为 0（其余两路为 1）的拍数：
                                   // 只有这种拍才能分辨"与门里少了这一路"
  int seg_hi_trap = 0;             // 定向激励命中数（见 drive_random_inputs）
  int btm_hi = 0;                  // uFTB s1 br_taken_mask 出过 1 的拍数（G1 新增旁路给 TAGE）
  int meta_nz = 0;                 // last_stage_meta 非零的拍数
  int perf_nz = 0;                 // 任一 perf 输出非零的拍数

  // ---- 输入 ----
  logic [47:0]     io_reset_vector;
  logic [49:0]     io_in_bits_s0_pc_0;
  logic [49:0]     io_in_bits_s0_pc_1;
  logic [49:0]     io_in_bits_s0_pc_2;
  logic [49:0]     io_in_bits_s0_pc_3;
  logic [10:0]     io_in_bits_folded_hist_1_hist_17_folded_hist;
  logic [10:0]     io_in_bits_folded_hist_1_hist_16_folded_hist;
  logic [6:0]      io_in_bits_folded_hist_1_hist_15_folded_hist;
  logic [7:0]      io_in_bits_folded_hist_1_hist_14_folded_hist;
  logic [6:0]      io_in_bits_folded_hist_1_hist_9_folded_hist;
  logic [7:0]      io_in_bits_folded_hist_1_hist_8_folded_hist;
  logic [6:0]      io_in_bits_folded_hist_1_hist_7_folded_hist;
  logic [6:0]      io_in_bits_folded_hist_1_hist_5_folded_hist;
  logic [7:0]      io_in_bits_folded_hist_1_hist_4_folded_hist;
  logic [7:0]      io_in_bits_folded_hist_1_hist_3_folded_hist;
  logic [10:0]     io_in_bits_folded_hist_1_hist_1_folded_hist;
  logic [3:0]      io_in_bits_folded_hist_3_hist_12_folded_hist;
  logic [7:0]      io_in_bits_folded_hist_3_hist_11_folded_hist;
  logic [7:0]      io_in_bits_folded_hist_3_hist_2_folded_hist;
  logic [7:0]      io_in_bits_s1_folded_hist_3_hist_14_folded_hist;
  logic [8:0]      io_in_bits_s1_folded_hist_3_hist_13_folded_hist;
  logic [3:0]      io_in_bits_s1_folded_hist_3_hist_12_folded_hist;
  logic [8:0]      io_in_bits_s1_folded_hist_3_hist_10_folded_hist;
  logic [8:0]      io_in_bits_s1_folded_hist_3_hist_6_folded_hist;
  logic [7:0]      io_in_bits_s1_folded_hist_3_hist_4_folded_hist;
  logic [7:0]      io_in_bits_s1_folded_hist_3_hist_3_folded_hist;
  logic [7:0]      io_in_bits_s1_folded_hist_3_hist_2_folded_hist;
  logic [255:0]    io_in_bits_ghist;
  logic            io_ctrl_ubtb_enable;
  logic            io_ctrl_btb_enable;
  logic            io_ctrl_tage_enable;
  logic            io_ctrl_sc_enable;
  logic            io_ctrl_ras_enable;
  logic            io_s0_fire_0;
  logic            io_s0_fire_1;
  logic            io_s0_fire_2;
  logic            io_s0_fire_3;
  logic            io_s1_fire_0;
  logic            io_s1_fire_1;
  logic            io_s1_fire_2;
  logic            io_s1_fire_3;
  logic            io_s2_fire_0;
  logic            io_s2_fire_1;
  logic            io_s2_fire_2;
  logic            io_s2_fire_3;
  logic            io_s3_fire_0;
  logic            io_s3_fire_2;
  logic            io_s3_redirect_2;
  logic            io_update_valid;
  logic [49:0]     io_update_bits_pc;
  logic            io_update_bits_ftb_entry_isCall;
  logic            io_update_bits_ftb_entry_isRet;
  logic            io_update_bits_ftb_entry_isJalr;
  logic            io_update_bits_ftb_entry_valid;
  logic [3:0]      io_update_bits_ftb_entry_brSlots_0_offset;
  logic            io_update_bits_ftb_entry_brSlots_0_sharing;
  logic            io_update_bits_ftb_entry_brSlots_0_valid;
  logic [11:0]     io_update_bits_ftb_entry_brSlots_0_lower;
  logic [1:0]      io_update_bits_ftb_entry_brSlots_0_tarStat;
  logic [3:0]      io_update_bits_ftb_entry_tailSlot_offset;
  logic            io_update_bits_ftb_entry_tailSlot_sharing;
  logic            io_update_bits_ftb_entry_tailSlot_valid;
  logic [19:0]     io_update_bits_ftb_entry_tailSlot_lower;
  logic [1:0]      io_update_bits_ftb_entry_tailSlot_tarStat;
  logic [3:0]      io_update_bits_ftb_entry_pftAddr;
  logic            io_update_bits_ftb_entry_carry;
  logic            io_update_bits_ftb_entry_last_may_be_rvi_call;
  logic            io_update_bits_ftb_entry_strong_bias_0;
  logic            io_update_bits_ftb_entry_strong_bias_1;
  logic            io_update_bits_cfi_idx_valid;
  logic [3:0]      io_update_bits_cfi_idx_bits;
  logic            io_update_bits_br_taken_mask_0;
  logic            io_update_bits_br_taken_mask_1;
  logic            io_update_bits_jmp_taken;
  logic            io_update_bits_mispred_mask_0;
  logic            io_update_bits_mispred_mask_1;
  logic            io_update_bits_mispred_mask_2;
  logic            io_update_bits_false_hit;
  logic            io_update_bits_old_entry;
  logic [515:0]    io_update_bits_meta;
  logic [49:0]     io_update_bits_full_target;
  logic [255:0]    io_update_bits_ghist;
  logic            io_redirect_valid;
  logic            io_redirect_bits_level;
  logic [49:0]     io_redirect_bits_cfiUpdate_pc;
  logic            io_redirect_bits_cfiUpdate_pd_valid;
  logic            io_redirect_bits_cfiUpdate_pd_isRVC;
  logic            io_redirect_bits_cfiUpdate_pd_isCall;
  logic            io_redirect_bits_cfiUpdate_pd_isRet;
  logic [3:0]      io_redirect_bits_cfiUpdate_ssp;
  logic [2:0]      io_redirect_bits_cfiUpdate_sctr;
  logic            io_redirect_bits_cfiUpdate_TOSW_flag;
  logic [4:0]      io_redirect_bits_cfiUpdate_TOSW_value;
  logic            io_redirect_bits_cfiUpdate_TOSR_flag;
  logic [4:0]      io_redirect_bits_cfiUpdate_TOSR_value;
  logic            io_redirect_bits_cfiUpdate_NOS_flag;
  logic [4:0]      io_redirect_bits_cfiUpdate_NOS_value;
  logic            io_redirectFromIFU;
  logic [5:0]      boreChildrenBd_bore_array;
  logic            boreChildrenBd_bore_all;
  logic            boreChildrenBd_bore_req;
  logic            boreChildrenBd_bore_writeen;
  logic [3:0]      boreChildrenBd_bore_be;
  logic [9:0]      boreChildrenBd_bore_addr;
  logic [39:0]     boreChildrenBd_bore_indata;
  logic            boreChildrenBd_bore_readen;
  logic [9:0]      boreChildrenBd_bore_addr_rd;
  logic [6:0]      boreChildrenBd_bore_1_array;
  logic            boreChildrenBd_bore_1_all;
  logic            boreChildrenBd_bore_1_req;
  logic            boreChildrenBd_bore_1_writeen;
  logic [15:0]     boreChildrenBd_bore_1_be;
  logic [9:0]      boreChildrenBd_bore_1_addr;
  logic [23:0]     boreChildrenBd_bore_1_indata;
  logic            boreChildrenBd_bore_1_readen;
  logic [9:0]      boreChildrenBd_bore_1_addr_rd;
  logic [6:0]      boreChildrenBd_bore_2_array;
  logic            boreChildrenBd_bore_2_all;
  logic            boreChildrenBd_bore_2_req;
  logic            boreChildrenBd_bore_2_writeen;
  logic [3:0]      boreChildrenBd_bore_2_be;
  logic [7:0]      boreChildrenBd_bore_2_addr;
  logic [23:0]     boreChildrenBd_bore_2_indata;
  logic            boreChildrenBd_bore_2_readen;
  logic [7:0]      boreChildrenBd_bore_2_addr_rd;
  logic [6:0]      boreChildrenBd_bore_3_array;
  logic            boreChildrenBd_bore_3_all;
  logic            boreChildrenBd_bore_3_req;
  logic            boreChildrenBd_bore_3_writeen;
  logic [3:0]      boreChildrenBd_bore_3_be;
  logic [7:0]      boreChildrenBd_bore_3_addr;
  logic [23:0]     boreChildrenBd_bore_3_indata;
  logic            boreChildrenBd_bore_3_readen;
  logic [7:0]      boreChildrenBd_bore_3_addr_rd;
  logic [6:0]      boreChildrenBd_bore_4_array;
  logic            boreChildrenBd_bore_4_all;
  logic            boreChildrenBd_bore_4_req;
  logic            boreChildrenBd_bore_4_writeen;
  logic [3:0]      boreChildrenBd_bore_4_be;
  logic [7:0]      boreChildrenBd_bore_4_addr;
  logic [23:0]     boreChildrenBd_bore_4_indata;
  logic            boreChildrenBd_bore_4_readen;
  logic [7:0]      boreChildrenBd_bore_4_addr_rd;
  logic [6:0]      boreChildrenBd_bore_5_array;
  logic            boreChildrenBd_bore_5_all;
  logic            boreChildrenBd_bore_5_req;
  logic            boreChildrenBd_bore_5_writeen;
  logic [3:0]      boreChildrenBd_bore_5_be;
  logic [7:0]      boreChildrenBd_bore_5_addr;
  logic [23:0]     boreChildrenBd_bore_5_indata;
  logic            boreChildrenBd_bore_5_readen;
  logic [7:0]      boreChildrenBd_bore_5_addr_rd;
  logic [6:0]      boreChildrenBd_bore_6_array;
  logic            boreChildrenBd_bore_6_all;
  logic            boreChildrenBd_bore_6_req;
  logic            boreChildrenBd_bore_6_writeen;
  logic [75:0]     boreChildrenBd_bore_6_be;
  logic [7:0]      boreChildrenBd_bore_6_addr;
  logic [75:0]     boreChildrenBd_bore_6_indata;
  logic            boreChildrenBd_bore_6_readen;
  logic [7:0]      boreChildrenBd_bore_6_addr_rd;
  logic [6:0]      boreChildrenBd_bore_7_array;
  logic            boreChildrenBd_bore_7_all;
  logic            boreChildrenBd_bore_7_req;
  logic            boreChildrenBd_bore_7_writeen;
  logic [75:0]     boreChildrenBd_bore_7_be;
  logic [7:0]      boreChildrenBd_bore_7_addr;
  logic [75:0]     boreChildrenBd_bore_7_indata;
  logic            boreChildrenBd_bore_7_readen;
  logic [7:0]      boreChildrenBd_bore_7_addr_rd;
  logic [6:0]      boreChildrenBd_bore_8_array;
  logic            boreChildrenBd_bore_8_all;
  logic            boreChildrenBd_bore_8_req;
  logic            boreChildrenBd_bore_8_writeen;
  logic [75:0]     boreChildrenBd_bore_8_be;
  logic [7:0]      boreChildrenBd_bore_8_addr;
  logic [75:0]     boreChildrenBd_bore_8_indata;
  logic            boreChildrenBd_bore_8_readen;
  logic [7:0]      boreChildrenBd_bore_8_addr_rd;
  logic [6:0]      boreChildrenBd_bore_9_array;
  logic            boreChildrenBd_bore_9_all;
  logic            boreChildrenBd_bore_9_req;
  logic            boreChildrenBd_bore_9_writeen;
  logic [75:0]     boreChildrenBd_bore_9_be;
  logic [7:0]      boreChildrenBd_bore_9_addr;
  logic [75:0]     boreChildrenBd_bore_9_indata;
  logic            boreChildrenBd_bore_9_readen;
  logic [7:0]      boreChildrenBd_bore_9_addr_rd;
  logic [6:0]      boreChildrenBd_bore_10_array;
  logic            boreChildrenBd_bore_10_all;
  logic            boreChildrenBd_bore_10_req;
  logic            boreChildrenBd_bore_10_writeen;
  logic [75:0]     boreChildrenBd_bore_10_be;
  logic [7:0]      boreChildrenBd_bore_10_addr;
  logic [75:0]     boreChildrenBd_bore_10_indata;
  logic            boreChildrenBd_bore_10_readen;
  logic [7:0]      boreChildrenBd_bore_10_addr_rd;
  logic            sigFromSrams_bore_ram_hold;
  logic            sigFromSrams_bore_ram_bypass;
  logic            sigFromSrams_bore_ram_bp_clken;
  logic            sigFromSrams_bore_ram_aux_clk;
  logic            sigFromSrams_bore_ram_aux_ckbp;
  logic            sigFromSrams_bore_ram_mcp_hold;
  logic            sigFromSrams_bore_cgen;
  logic            sigFromSrams_bore_1_ram_hold;
  logic            sigFromSrams_bore_1_ram_bypass;
  logic            sigFromSrams_bore_1_ram_bp_clken;
  logic            sigFromSrams_bore_1_ram_aux_clk;
  logic            sigFromSrams_bore_1_ram_aux_ckbp;
  logic            sigFromSrams_bore_1_ram_mcp_hold;
  logic            sigFromSrams_bore_1_cgen;
  logic            sigFromSrams_bore_2_ram_hold;
  logic            sigFromSrams_bore_2_ram_bypass;
  logic            sigFromSrams_bore_2_ram_bp_clken;
  logic            sigFromSrams_bore_2_ram_aux_clk;
  logic            sigFromSrams_bore_2_ram_aux_ckbp;
  logic            sigFromSrams_bore_2_ram_mcp_hold;
  logic            sigFromSrams_bore_2_cgen;
  logic            sigFromSrams_bore_3_ram_hold;
  logic            sigFromSrams_bore_3_ram_bypass;
  logic            sigFromSrams_bore_3_ram_bp_clken;
  logic            sigFromSrams_bore_3_ram_aux_clk;
  logic            sigFromSrams_bore_3_ram_aux_ckbp;
  logic            sigFromSrams_bore_3_ram_mcp_hold;
  logic            sigFromSrams_bore_3_cgen;
  logic            sigFromSrams_bore_4_ram_hold;
  logic            sigFromSrams_bore_4_ram_bypass;
  logic            sigFromSrams_bore_4_ram_bp_clken;
  logic            sigFromSrams_bore_4_ram_aux_clk;
  logic            sigFromSrams_bore_4_ram_aux_ckbp;
  logic            sigFromSrams_bore_4_ram_mcp_hold;
  logic            sigFromSrams_bore_4_cgen;
  logic            sigFromSrams_bore_5_ram_hold;
  logic            sigFromSrams_bore_5_ram_bypass;
  logic            sigFromSrams_bore_5_ram_bp_clken;
  logic            sigFromSrams_bore_5_ram_aux_clk;
  logic            sigFromSrams_bore_5_ram_aux_ckbp;
  logic            sigFromSrams_bore_5_ram_mcp_hold;
  logic            sigFromSrams_bore_5_cgen;
  logic            sigFromSrams_bore_6_ram_hold;
  logic            sigFromSrams_bore_6_ram_bypass;
  logic            sigFromSrams_bore_6_ram_bp_clken;
  logic            sigFromSrams_bore_6_ram_aux_clk;
  logic            sigFromSrams_bore_6_ram_aux_ckbp;
  logic            sigFromSrams_bore_6_ram_mcp_hold;
  logic            sigFromSrams_bore_6_cgen;
  logic            sigFromSrams_bore_7_ram_hold;
  logic            sigFromSrams_bore_7_ram_bypass;
  logic            sigFromSrams_bore_7_ram_bp_clken;
  logic            sigFromSrams_bore_7_ram_aux_clk;
  logic            sigFromSrams_bore_7_ram_aux_ckbp;
  logic            sigFromSrams_bore_7_ram_mcp_hold;
  logic            sigFromSrams_bore_7_cgen;
  logic            sigFromSrams_bore_8_ram_hold;
  logic            sigFromSrams_bore_8_ram_bypass;
  logic            sigFromSrams_bore_8_ram_bp_clken;
  logic            sigFromSrams_bore_8_ram_aux_clk;
  logic            sigFromSrams_bore_8_ram_aux_ckbp;
  logic            sigFromSrams_bore_8_ram_mcp_hold;
  logic            sigFromSrams_bore_8_cgen;
  logic            sigFromSrams_bore_9_ram_hold;
  logic            sigFromSrams_bore_9_ram_bypass;
  logic            sigFromSrams_bore_9_ram_bp_clken;
  logic            sigFromSrams_bore_9_ram_aux_clk;
  logic            sigFromSrams_bore_9_ram_aux_ckbp;
  logic            sigFromSrams_bore_9_ram_mcp_hold;
  logic            sigFromSrams_bore_9_cgen;
  logic            sigFromSrams_bore_10_ram_hold;
  logic            sigFromSrams_bore_10_ram_bypass;
  logic            sigFromSrams_bore_10_ram_bp_clken;
  logic            sigFromSrams_bore_10_ram_aux_clk;
  logic            sigFromSrams_bore_10_ram_aux_ckbp;
  logic            sigFromSrams_bore_10_ram_mcp_hold;
  logic            sigFromSrams_bore_10_cgen;
  logic            sigFromSrams_bore_11_ram_hold;
  logic            sigFromSrams_bore_11_ram_bypass;
  logic            sigFromSrams_bore_11_ram_bp_clken;
  logic            sigFromSrams_bore_11_ram_aux_clk;
  logic            sigFromSrams_bore_11_ram_aux_ckbp;
  logic            sigFromSrams_bore_11_ram_mcp_hold;
  logic            sigFromSrams_bore_11_cgen;
  logic            sigFromSrams_bore_12_ram_hold;
  logic            sigFromSrams_bore_12_ram_bypass;
  logic            sigFromSrams_bore_12_ram_bp_clken;
  logic            sigFromSrams_bore_12_ram_aux_clk;
  logic            sigFromSrams_bore_12_ram_aux_ckbp;
  logic            sigFromSrams_bore_12_ram_mcp_hold;
  logic            sigFromSrams_bore_12_cgen;
  logic            sigFromSrams_bore_13_ram_hold;
  logic            sigFromSrams_bore_13_ram_bypass;
  logic            sigFromSrams_bore_13_ram_bp_clken;
  logic            sigFromSrams_bore_13_ram_aux_clk;
  logic            sigFromSrams_bore_13_ram_aux_ckbp;
  logic            sigFromSrams_bore_13_ram_mcp_hold;
  logic            sigFromSrams_bore_13_cgen;
  logic            sigFromSrams_bore_14_ram_hold;
  logic            sigFromSrams_bore_14_ram_bypass;
  logic            sigFromSrams_bore_14_ram_bp_clken;
  logic            sigFromSrams_bore_14_ram_aux_clk;
  logic            sigFromSrams_bore_14_ram_aux_ckbp;
  logic            sigFromSrams_bore_14_ram_mcp_hold;
  logic            sigFromSrams_bore_14_cgen;
  logic            sigFromSrams_bore_15_ram_hold;
  logic            sigFromSrams_bore_15_ram_bypass;
  logic            sigFromSrams_bore_15_ram_bp_clken;
  logic            sigFromSrams_bore_15_ram_aux_clk;
  logic            sigFromSrams_bore_15_ram_aux_ckbp;
  logic            sigFromSrams_bore_15_ram_mcp_hold;
  logic            sigFromSrams_bore_15_cgen;
  logic            sigFromSrams_bore_16_ram_hold;
  logic            sigFromSrams_bore_16_ram_bypass;
  logic            sigFromSrams_bore_16_ram_bp_clken;
  logic            sigFromSrams_bore_16_ram_aux_clk;
  logic            sigFromSrams_bore_16_ram_aux_ckbp;
  logic            sigFromSrams_bore_16_ram_mcp_hold;
  logic            sigFromSrams_bore_16_cgen;
  logic            sigFromSrams_bore_17_ram_hold;
  logic            sigFromSrams_bore_17_ram_bypass;
  logic            sigFromSrams_bore_17_ram_bp_clken;
  logic            sigFromSrams_bore_17_ram_aux_clk;
  logic            sigFromSrams_bore_17_ram_aux_ckbp;
  logic            sigFromSrams_bore_17_ram_mcp_hold;
  logic            sigFromSrams_bore_17_cgen;
  logic            sigFromSrams_bore_18_ram_hold;
  logic            sigFromSrams_bore_18_ram_bypass;
  logic            sigFromSrams_bore_18_ram_bp_clken;
  logic            sigFromSrams_bore_18_ram_aux_clk;
  logic            sigFromSrams_bore_18_ram_aux_ckbp;
  logic            sigFromSrams_bore_18_ram_mcp_hold;
  logic            sigFromSrams_bore_18_cgen;
  logic            sigFromSrams_bore_19_ram_hold;
  logic            sigFromSrams_bore_19_ram_bypass;
  logic            sigFromSrams_bore_19_ram_bp_clken;
  logic            sigFromSrams_bore_19_ram_aux_clk;
  logic            sigFromSrams_bore_19_ram_aux_ckbp;
  logic            sigFromSrams_bore_19_ram_mcp_hold;
  logic            sigFromSrams_bore_19_cgen;
  logic            sigFromSrams_bore_20_ram_hold;
  logic            sigFromSrams_bore_20_ram_bypass;
  logic            sigFromSrams_bore_20_ram_bp_clken;
  logic            sigFromSrams_bore_20_ram_aux_clk;
  logic            sigFromSrams_bore_20_ram_aux_ckbp;
  logic            sigFromSrams_bore_20_ram_mcp_hold;
  logic            sigFromSrams_bore_20_cgen;
  logic            sigFromSrams_bore_21_ram_hold;
  logic            sigFromSrams_bore_21_ram_bypass;
  logic            sigFromSrams_bore_21_ram_bp_clken;
  logic            sigFromSrams_bore_21_ram_aux_clk;
  logic            sigFromSrams_bore_21_ram_aux_ckbp;
  logic            sigFromSrams_bore_21_ram_mcp_hold;
  logic            sigFromSrams_bore_21_cgen;
  logic            sigFromSrams_bore_22_ram_hold;
  logic            sigFromSrams_bore_22_ram_bypass;
  logic            sigFromSrams_bore_22_ram_bp_clken;
  logic            sigFromSrams_bore_22_ram_aux_clk;
  logic            sigFromSrams_bore_22_ram_aux_ckbp;
  logic            sigFromSrams_bore_22_ram_mcp_hold;
  logic            sigFromSrams_bore_22_cgen;
  logic            sigFromSrams_bore_23_ram_hold;
  logic            sigFromSrams_bore_23_ram_bypass;
  logic            sigFromSrams_bore_23_ram_bp_clken;
  logic            sigFromSrams_bore_23_ram_aux_clk;
  logic            sigFromSrams_bore_23_ram_aux_ckbp;
  logic            sigFromSrams_bore_23_ram_mcp_hold;
  logic            sigFromSrams_bore_23_cgen;
  logic            sigFromSrams_bore_24_ram_hold;
  logic            sigFromSrams_bore_24_ram_bypass;
  logic            sigFromSrams_bore_24_ram_bp_clken;
  logic            sigFromSrams_bore_24_ram_aux_clk;
  logic            sigFromSrams_bore_24_ram_aux_ckbp;
  logic            sigFromSrams_bore_24_ram_mcp_hold;
  logic            sigFromSrams_bore_24_cgen;
  logic            sigFromSrams_bore_25_ram_hold;
  logic            sigFromSrams_bore_25_ram_bypass;
  logic            sigFromSrams_bore_25_ram_bp_clken;
  logic            sigFromSrams_bore_25_ram_aux_clk;
  logic            sigFromSrams_bore_25_ram_aux_ckbp;
  logic            sigFromSrams_bore_25_ram_mcp_hold;
  logic            sigFromSrams_bore_25_cgen;
  logic            sigFromSrams_bore_26_ram_hold;
  logic            sigFromSrams_bore_26_ram_bypass;
  logic            sigFromSrams_bore_26_ram_bp_clken;
  logic            sigFromSrams_bore_26_ram_aux_clk;
  logic            sigFromSrams_bore_26_ram_aux_ckbp;
  logic            sigFromSrams_bore_26_ram_mcp_hold;
  logic            sigFromSrams_bore_26_cgen;
  logic            sigFromSrams_bore_27_ram_hold;
  logic            sigFromSrams_bore_27_ram_bypass;
  logic            sigFromSrams_bore_27_ram_bp_clken;
  logic            sigFromSrams_bore_27_ram_aux_clk;
  logic            sigFromSrams_bore_27_ram_aux_ckbp;
  logic            sigFromSrams_bore_27_ram_mcp_hold;
  logic            sigFromSrams_bore_27_cgen;
  logic            sigFromSrams_bore_28_ram_hold;
  logic            sigFromSrams_bore_28_ram_bypass;
  logic            sigFromSrams_bore_28_ram_bp_clken;
  logic            sigFromSrams_bore_28_ram_aux_clk;
  logic            sigFromSrams_bore_28_ram_aux_ckbp;
  logic            sigFromSrams_bore_28_ram_mcp_hold;
  logic            sigFromSrams_bore_28_cgen;
  logic            sigFromSrams_bore_29_ram_hold;
  logic            sigFromSrams_bore_29_ram_bypass;
  logic            sigFromSrams_bore_29_ram_bp_clken;
  logic            sigFromSrams_bore_29_ram_aux_clk;
  logic            sigFromSrams_bore_29_ram_aux_ckbp;
  logic            sigFromSrams_bore_29_ram_mcp_hold;
  logic            sigFromSrams_bore_29_cgen;
  logic            sigFromSrams_bore_30_ram_hold;
  logic            sigFromSrams_bore_30_ram_bypass;
  logic            sigFromSrams_bore_30_ram_bp_clken;
  logic            sigFromSrams_bore_30_ram_aux_clk;
  logic            sigFromSrams_bore_30_ram_aux_ckbp;
  logic            sigFromSrams_bore_30_ram_mcp_hold;
  logic            sigFromSrams_bore_30_cgen;
  logic            sigFromSrams_bore_31_ram_hold;
  logic            sigFromSrams_bore_31_ram_bypass;
  logic            sigFromSrams_bore_31_ram_bp_clken;
  logic            sigFromSrams_bore_31_ram_aux_clk;
  logic            sigFromSrams_bore_31_ram_aux_ckbp;
  logic            sigFromSrams_bore_31_ram_mcp_hold;
  logic            sigFromSrams_bore_31_cgen;
  logic            sigFromSrams_bore_32_ram_hold;
  logic            sigFromSrams_bore_32_ram_bypass;
  logic            sigFromSrams_bore_32_ram_bp_clken;
  logic            sigFromSrams_bore_32_ram_aux_clk;
  logic            sigFromSrams_bore_32_ram_aux_ckbp;
  logic            sigFromSrams_bore_32_ram_mcp_hold;
  logic            sigFromSrams_bore_32_cgen;
  logic            sigFromSrams_bore_33_ram_hold;
  logic            sigFromSrams_bore_33_ram_bypass;
  logic            sigFromSrams_bore_33_ram_bp_clken;
  logic            sigFromSrams_bore_33_ram_aux_clk;
  logic            sigFromSrams_bore_33_ram_aux_ckbp;
  logic            sigFromSrams_bore_33_ram_mcp_hold;
  logic            sigFromSrams_bore_33_cgen;
  logic            sigFromSrams_bore_34_ram_hold;
  logic            sigFromSrams_bore_34_ram_bypass;
  logic            sigFromSrams_bore_34_ram_bp_clken;
  logic            sigFromSrams_bore_34_ram_aux_clk;
  logic            sigFromSrams_bore_34_ram_aux_ckbp;
  logic            sigFromSrams_bore_34_ram_mcp_hold;
  logic            sigFromSrams_bore_34_cgen;
  logic            sigFromSrams_bore_35_ram_hold;
  logic            sigFromSrams_bore_35_ram_bypass;
  logic            sigFromSrams_bore_35_ram_bp_clken;
  logic            sigFromSrams_bore_35_ram_aux_clk;
  logic            sigFromSrams_bore_35_ram_aux_ckbp;
  logic            sigFromSrams_bore_35_ram_mcp_hold;
  logic            sigFromSrams_bore_35_cgen;
  logic            sigFromSrams_bore_36_ram_hold;
  logic            sigFromSrams_bore_36_ram_bypass;
  logic            sigFromSrams_bore_36_ram_bp_clken;
  logic            sigFromSrams_bore_36_ram_aux_clk;
  logic            sigFromSrams_bore_36_ram_aux_ckbp;
  logic            sigFromSrams_bore_36_ram_mcp_hold;
  logic            sigFromSrams_bore_36_cgen;
  logic            sigFromSrams_bore_37_ram_hold;
  logic            sigFromSrams_bore_37_ram_bypass;
  logic            sigFromSrams_bore_37_ram_bp_clken;
  logic            sigFromSrams_bore_37_ram_aux_clk;
  logic            sigFromSrams_bore_37_ram_aux_ckbp;
  logic            sigFromSrams_bore_37_ram_mcp_hold;
  logic            sigFromSrams_bore_37_cgen;
  logic            sigFromSrams_bore_38_ram_hold;
  logic            sigFromSrams_bore_38_ram_bypass;
  logic            sigFromSrams_bore_38_ram_bp_clken;
  logic            sigFromSrams_bore_38_ram_aux_clk;
  logic            sigFromSrams_bore_38_ram_aux_ckbp;
  logic            sigFromSrams_bore_38_ram_mcp_hold;
  logic            sigFromSrams_bore_38_cgen;
  logic            sigFromSrams_bore_39_ram_hold;
  logic            sigFromSrams_bore_39_ram_bypass;
  logic            sigFromSrams_bore_39_ram_bp_clken;
  logic            sigFromSrams_bore_39_ram_aux_clk;
  logic            sigFromSrams_bore_39_ram_aux_ckbp;
  logic            sigFromSrams_bore_39_ram_mcp_hold;
  logic            sigFromSrams_bore_39_cgen;
  logic            sigFromSrams_bore_40_ram_hold;
  logic            sigFromSrams_bore_40_ram_bypass;
  logic            sigFromSrams_bore_40_ram_bp_clken;
  logic            sigFromSrams_bore_40_ram_aux_clk;
  logic            sigFromSrams_bore_40_ram_aux_ckbp;
  logic            sigFromSrams_bore_40_ram_mcp_hold;
  logic            sigFromSrams_bore_40_cgen;
  logic            sigFromSrams_bore_41_ram_hold;
  logic            sigFromSrams_bore_41_ram_bypass;
  logic            sigFromSrams_bore_41_ram_bp_clken;
  logic            sigFromSrams_bore_41_ram_aux_clk;
  logic            sigFromSrams_bore_41_ram_aux_ckbp;
  logic            sigFromSrams_bore_41_ram_mcp_hold;
  logic            sigFromSrams_bore_41_cgen;
  logic            sigFromSrams_bore_42_ram_hold;
  logic            sigFromSrams_bore_42_ram_bypass;
  logic            sigFromSrams_bore_42_ram_bp_clken;
  logic            sigFromSrams_bore_42_ram_aux_clk;
  logic            sigFromSrams_bore_42_ram_aux_ckbp;
  logic            sigFromSrams_bore_42_ram_mcp_hold;
  logic            sigFromSrams_bore_42_cgen;
  logic            sigFromSrams_bore_43_ram_hold;
  logic            sigFromSrams_bore_43_ram_bypass;
  logic            sigFromSrams_bore_43_ram_bp_clken;
  logic            sigFromSrams_bore_43_ram_aux_clk;
  logic            sigFromSrams_bore_43_ram_aux_ckbp;
  logic            sigFromSrams_bore_43_ram_mcp_hold;
  logic            sigFromSrams_bore_43_cgen;
  logic            sigFromSrams_bore_44_ram_hold;
  logic            sigFromSrams_bore_44_ram_bypass;
  logic            sigFromSrams_bore_44_ram_bp_clken;
  logic            sigFromSrams_bore_44_ram_aux_clk;
  logic            sigFromSrams_bore_44_ram_aux_ckbp;
  logic            sigFromSrams_bore_44_ram_mcp_hold;
  logic            sigFromSrams_bore_44_cgen;
  logic            sigFromSrams_bore_45_ram_hold;
  logic            sigFromSrams_bore_45_ram_bypass;
  logic            sigFromSrams_bore_45_ram_bp_clken;
  logic            sigFromSrams_bore_45_ram_aux_clk;
  logic            sigFromSrams_bore_45_ram_aux_ckbp;
  logic            sigFromSrams_bore_45_ram_mcp_hold;
  logic            sigFromSrams_bore_45_cgen;
  logic            sigFromSrams_bore_46_ram_hold;
  logic            sigFromSrams_bore_46_ram_bypass;
  logic            sigFromSrams_bore_46_ram_bp_clken;
  logic            sigFromSrams_bore_46_ram_aux_clk;
  logic            sigFromSrams_bore_46_ram_aux_ckbp;
  logic            sigFromSrams_bore_46_ram_mcp_hold;
  logic            sigFromSrams_bore_46_cgen;
  logic            sigFromSrams_bore_47_ram_hold;
  logic            sigFromSrams_bore_47_ram_bypass;
  logic            sigFromSrams_bore_47_ram_bp_clken;
  logic            sigFromSrams_bore_47_ram_aux_clk;
  logic            sigFromSrams_bore_47_ram_aux_ckbp;
  logic            sigFromSrams_bore_47_ram_mcp_hold;
  logic            sigFromSrams_bore_47_cgen;

  // ---- 输出（g_ = golden, i_ = 重写）----
  wire  [49:0]     g_io_out_s1_pc_0;
  wire  [49:0]     i_io_out_s1_pc_0;
  wire  [49:0]     g_io_out_s1_pc_1;
  wire  [49:0]     i_io_out_s1_pc_1;
  wire  [49:0]     g_io_out_s1_pc_2;
  wire  [49:0]     i_io_out_s1_pc_2;
  wire  [49:0]     g_io_out_s1_pc_3;
  wire  [49:0]     i_io_out_s1_pc_3;
  wire             g_io_out_s1_full_pred_0_br_taken_mask_0;
  wire             i_io_out_s1_full_pred_0_br_taken_mask_0;
  wire             g_io_out_s1_full_pred_0_br_taken_mask_1;
  wire             i_io_out_s1_full_pred_0_br_taken_mask_1;
  wire             g_io_out_s1_full_pred_0_slot_valids_0;
  wire             i_io_out_s1_full_pred_0_slot_valids_0;
  wire             g_io_out_s1_full_pred_0_slot_valids_1;
  wire             i_io_out_s1_full_pred_0_slot_valids_1;
  wire  [49:0]     g_io_out_s1_full_pred_0_targets_0;
  wire  [49:0]     i_io_out_s1_full_pred_0_targets_0;
  wire  [49:0]     g_io_out_s1_full_pred_0_targets_1;
  wire  [49:0]     i_io_out_s1_full_pred_0_targets_1;
  wire  [49:0]     g_io_out_s1_full_pred_0_jalr_target;
  wire  [49:0]     i_io_out_s1_full_pred_0_jalr_target;
  wire  [3:0]      g_io_out_s1_full_pred_0_offsets_0;
  wire  [3:0]      i_io_out_s1_full_pred_0_offsets_0;
  wire  [3:0]      g_io_out_s1_full_pred_0_offsets_1;
  wire  [3:0]      i_io_out_s1_full_pred_0_offsets_1;
  wire  [49:0]     g_io_out_s1_full_pred_0_fallThroughAddr;
  wire  [49:0]     i_io_out_s1_full_pred_0_fallThroughAddr;
  wire             g_io_out_s1_full_pred_0_fallThroughErr;
  wire             i_io_out_s1_full_pred_0_fallThroughErr;
  wire             g_io_out_s1_full_pred_0_is_jal;
  wire             i_io_out_s1_full_pred_0_is_jal;
  wire             g_io_out_s1_full_pred_0_is_jalr;
  wire             i_io_out_s1_full_pred_0_is_jalr;
  wire             g_io_out_s1_full_pred_0_is_call;
  wire             i_io_out_s1_full_pred_0_is_call;
  wire             g_io_out_s1_full_pred_0_is_ret;
  wire             i_io_out_s1_full_pred_0_is_ret;
  wire             g_io_out_s1_full_pred_0_last_may_be_rvi_call;
  wire             i_io_out_s1_full_pred_0_last_may_be_rvi_call;
  wire             g_io_out_s1_full_pred_0_is_br_sharing;
  wire             i_io_out_s1_full_pred_0_is_br_sharing;
  wire             g_io_out_s1_full_pred_0_hit;
  wire             i_io_out_s1_full_pred_0_hit;
  wire             g_io_out_s1_full_pred_1_br_taken_mask_0;
  wire             i_io_out_s1_full_pred_1_br_taken_mask_0;
  wire             g_io_out_s1_full_pred_1_br_taken_mask_1;
  wire             i_io_out_s1_full_pred_1_br_taken_mask_1;
  wire             g_io_out_s1_full_pred_1_slot_valids_0;
  wire             i_io_out_s1_full_pred_1_slot_valids_0;
  wire             g_io_out_s1_full_pred_1_slot_valids_1;
  wire             i_io_out_s1_full_pred_1_slot_valids_1;
  wire  [49:0]     g_io_out_s1_full_pred_1_targets_0;
  wire  [49:0]     i_io_out_s1_full_pred_1_targets_0;
  wire  [49:0]     g_io_out_s1_full_pred_1_targets_1;
  wire  [49:0]     i_io_out_s1_full_pred_1_targets_1;
  wire  [49:0]     g_io_out_s1_full_pred_1_jalr_target;
  wire  [49:0]     i_io_out_s1_full_pred_1_jalr_target;
  wire  [3:0]      g_io_out_s1_full_pred_1_offsets_0;
  wire  [3:0]      i_io_out_s1_full_pred_1_offsets_0;
  wire  [3:0]      g_io_out_s1_full_pred_1_offsets_1;
  wire  [3:0]      i_io_out_s1_full_pred_1_offsets_1;
  wire  [49:0]     g_io_out_s1_full_pred_1_fallThroughAddr;
  wire  [49:0]     i_io_out_s1_full_pred_1_fallThroughAddr;
  wire             g_io_out_s1_full_pred_1_fallThroughErr;
  wire             i_io_out_s1_full_pred_1_fallThroughErr;
  wire             g_io_out_s1_full_pred_1_is_jal;
  wire             i_io_out_s1_full_pred_1_is_jal;
  wire             g_io_out_s1_full_pred_1_is_jalr;
  wire             i_io_out_s1_full_pred_1_is_jalr;
  wire             g_io_out_s1_full_pred_1_is_call;
  wire             i_io_out_s1_full_pred_1_is_call;
  wire             g_io_out_s1_full_pred_1_is_ret;
  wire             i_io_out_s1_full_pred_1_is_ret;
  wire             g_io_out_s1_full_pred_1_last_may_be_rvi_call;
  wire             i_io_out_s1_full_pred_1_last_may_be_rvi_call;
  wire             g_io_out_s1_full_pred_1_is_br_sharing;
  wire             i_io_out_s1_full_pred_1_is_br_sharing;
  wire             g_io_out_s1_full_pred_1_hit;
  wire             i_io_out_s1_full_pred_1_hit;
  wire             g_io_out_s1_full_pred_2_br_taken_mask_0;
  wire             i_io_out_s1_full_pred_2_br_taken_mask_0;
  wire             g_io_out_s1_full_pred_2_br_taken_mask_1;
  wire             i_io_out_s1_full_pred_2_br_taken_mask_1;
  wire             g_io_out_s1_full_pred_2_slot_valids_0;
  wire             i_io_out_s1_full_pred_2_slot_valids_0;
  wire             g_io_out_s1_full_pred_2_slot_valids_1;
  wire             i_io_out_s1_full_pred_2_slot_valids_1;
  wire  [49:0]     g_io_out_s1_full_pred_2_targets_0;
  wire  [49:0]     i_io_out_s1_full_pred_2_targets_0;
  wire  [49:0]     g_io_out_s1_full_pred_2_targets_1;
  wire  [49:0]     i_io_out_s1_full_pred_2_targets_1;
  wire  [49:0]     g_io_out_s1_full_pred_2_jalr_target;
  wire  [49:0]     i_io_out_s1_full_pred_2_jalr_target;
  wire  [3:0]      g_io_out_s1_full_pred_2_offsets_0;
  wire  [3:0]      i_io_out_s1_full_pred_2_offsets_0;
  wire  [3:0]      g_io_out_s1_full_pred_2_offsets_1;
  wire  [3:0]      i_io_out_s1_full_pred_2_offsets_1;
  wire  [49:0]     g_io_out_s1_full_pred_2_fallThroughAddr;
  wire  [49:0]     i_io_out_s1_full_pred_2_fallThroughAddr;
  wire             g_io_out_s1_full_pred_2_fallThroughErr;
  wire             i_io_out_s1_full_pred_2_fallThroughErr;
  wire             g_io_out_s1_full_pred_2_is_jal;
  wire             i_io_out_s1_full_pred_2_is_jal;
  wire             g_io_out_s1_full_pred_2_is_jalr;
  wire             i_io_out_s1_full_pred_2_is_jalr;
  wire             g_io_out_s1_full_pred_2_is_call;
  wire             i_io_out_s1_full_pred_2_is_call;
  wire             g_io_out_s1_full_pred_2_is_ret;
  wire             i_io_out_s1_full_pred_2_is_ret;
  wire             g_io_out_s1_full_pred_2_last_may_be_rvi_call;
  wire             i_io_out_s1_full_pred_2_last_may_be_rvi_call;
  wire             g_io_out_s1_full_pred_2_is_br_sharing;
  wire             i_io_out_s1_full_pred_2_is_br_sharing;
  wire             g_io_out_s1_full_pred_2_hit;
  wire             i_io_out_s1_full_pred_2_hit;
  wire             g_io_out_s1_full_pred_3_br_taken_mask_0;
  wire             i_io_out_s1_full_pred_3_br_taken_mask_0;
  wire             g_io_out_s1_full_pred_3_br_taken_mask_1;
  wire             i_io_out_s1_full_pred_3_br_taken_mask_1;
  wire             g_io_out_s1_full_pred_3_slot_valids_0;
  wire             i_io_out_s1_full_pred_3_slot_valids_0;
  wire             g_io_out_s1_full_pred_3_slot_valids_1;
  wire             i_io_out_s1_full_pred_3_slot_valids_1;
  wire  [49:0]     g_io_out_s1_full_pred_3_targets_0;
  wire  [49:0]     i_io_out_s1_full_pred_3_targets_0;
  wire  [49:0]     g_io_out_s1_full_pred_3_targets_1;
  wire  [49:0]     i_io_out_s1_full_pred_3_targets_1;
  wire  [49:0]     g_io_out_s1_full_pred_3_jalr_target;
  wire  [49:0]     i_io_out_s1_full_pred_3_jalr_target;
  wire  [3:0]      g_io_out_s1_full_pred_3_offsets_0;
  wire  [3:0]      i_io_out_s1_full_pred_3_offsets_0;
  wire  [3:0]      g_io_out_s1_full_pred_3_offsets_1;
  wire  [3:0]      i_io_out_s1_full_pred_3_offsets_1;
  wire  [49:0]     g_io_out_s1_full_pred_3_fallThroughAddr;
  wire  [49:0]     i_io_out_s1_full_pred_3_fallThroughAddr;
  wire             g_io_out_s1_full_pred_3_fallThroughErr;
  wire             i_io_out_s1_full_pred_3_fallThroughErr;
  wire             g_io_out_s1_full_pred_3_is_jal;
  wire             i_io_out_s1_full_pred_3_is_jal;
  wire             g_io_out_s1_full_pred_3_is_jalr;
  wire             i_io_out_s1_full_pred_3_is_jalr;
  wire             g_io_out_s1_full_pred_3_is_call;
  wire             i_io_out_s1_full_pred_3_is_call;
  wire             g_io_out_s1_full_pred_3_is_ret;
  wire             i_io_out_s1_full_pred_3_is_ret;
  wire             g_io_out_s1_full_pred_3_last_may_be_rvi_call;
  wire             i_io_out_s1_full_pred_3_last_may_be_rvi_call;
  wire             g_io_out_s1_full_pred_3_is_br_sharing;
  wire             i_io_out_s1_full_pred_3_is_br_sharing;
  wire             g_io_out_s1_full_pred_3_hit;
  wire             i_io_out_s1_full_pred_3_hit;
  wire  [49:0]     g_io_out_s2_pc_0;
  wire  [49:0]     i_io_out_s2_pc_0;
  wire  [49:0]     g_io_out_s2_pc_1;
  wire  [49:0]     i_io_out_s2_pc_1;
  wire  [49:0]     g_io_out_s2_pc_2;
  wire  [49:0]     i_io_out_s2_pc_2;
  wire  [49:0]     g_io_out_s2_pc_3;
  wire  [49:0]     i_io_out_s2_pc_3;
  wire             g_io_out_s2_full_pred_0_br_taken_mask_0;
  wire             i_io_out_s2_full_pred_0_br_taken_mask_0;
  wire             g_io_out_s2_full_pred_0_br_taken_mask_1;
  wire             i_io_out_s2_full_pred_0_br_taken_mask_1;
  wire             g_io_out_s2_full_pred_0_slot_valids_0;
  wire             i_io_out_s2_full_pred_0_slot_valids_0;
  wire             g_io_out_s2_full_pred_0_slot_valids_1;
  wire             i_io_out_s2_full_pred_0_slot_valids_1;
  wire  [49:0]     g_io_out_s2_full_pred_0_targets_0;
  wire  [49:0]     i_io_out_s2_full_pred_0_targets_0;
  wire  [49:0]     g_io_out_s2_full_pred_0_targets_1;
  wire  [49:0]     i_io_out_s2_full_pred_0_targets_1;
  wire  [49:0]     g_io_out_s2_full_pred_0_jalr_target;
  wire  [49:0]     i_io_out_s2_full_pred_0_jalr_target;
  wire  [3:0]      g_io_out_s2_full_pred_0_offsets_0;
  wire  [3:0]      i_io_out_s2_full_pred_0_offsets_0;
  wire  [3:0]      g_io_out_s2_full_pred_0_offsets_1;
  wire  [3:0]      i_io_out_s2_full_pred_0_offsets_1;
  wire  [49:0]     g_io_out_s2_full_pred_0_fallThroughAddr;
  wire  [49:0]     i_io_out_s2_full_pred_0_fallThroughAddr;
  wire             g_io_out_s2_full_pred_0_fallThroughErr;
  wire             i_io_out_s2_full_pred_0_fallThroughErr;
  wire             g_io_out_s2_full_pred_0_is_jal;
  wire             i_io_out_s2_full_pred_0_is_jal;
  wire             g_io_out_s2_full_pred_0_is_jalr;
  wire             i_io_out_s2_full_pred_0_is_jalr;
  wire             g_io_out_s2_full_pred_0_is_call;
  wire             i_io_out_s2_full_pred_0_is_call;
  wire             g_io_out_s2_full_pred_0_is_ret;
  wire             i_io_out_s2_full_pred_0_is_ret;
  wire             g_io_out_s2_full_pred_0_last_may_be_rvi_call;
  wire             i_io_out_s2_full_pred_0_last_may_be_rvi_call;
  wire             g_io_out_s2_full_pred_0_is_br_sharing;
  wire             i_io_out_s2_full_pred_0_is_br_sharing;
  wire             g_io_out_s2_full_pred_0_hit;
  wire             i_io_out_s2_full_pred_0_hit;
  wire             g_io_out_s2_full_pred_1_br_taken_mask_0;
  wire             i_io_out_s2_full_pred_1_br_taken_mask_0;
  wire             g_io_out_s2_full_pred_1_br_taken_mask_1;
  wire             i_io_out_s2_full_pred_1_br_taken_mask_1;
  wire             g_io_out_s2_full_pred_1_slot_valids_0;
  wire             i_io_out_s2_full_pred_1_slot_valids_0;
  wire             g_io_out_s2_full_pred_1_slot_valids_1;
  wire             i_io_out_s2_full_pred_1_slot_valids_1;
  wire  [49:0]     g_io_out_s2_full_pred_1_targets_0;
  wire  [49:0]     i_io_out_s2_full_pred_1_targets_0;
  wire  [49:0]     g_io_out_s2_full_pred_1_targets_1;
  wire  [49:0]     i_io_out_s2_full_pred_1_targets_1;
  wire  [49:0]     g_io_out_s2_full_pred_1_jalr_target;
  wire  [49:0]     i_io_out_s2_full_pred_1_jalr_target;
  wire  [3:0]      g_io_out_s2_full_pred_1_offsets_0;
  wire  [3:0]      i_io_out_s2_full_pred_1_offsets_0;
  wire  [3:0]      g_io_out_s2_full_pred_1_offsets_1;
  wire  [3:0]      i_io_out_s2_full_pred_1_offsets_1;
  wire  [49:0]     g_io_out_s2_full_pred_1_fallThroughAddr;
  wire  [49:0]     i_io_out_s2_full_pred_1_fallThroughAddr;
  wire             g_io_out_s2_full_pred_1_fallThroughErr;
  wire             i_io_out_s2_full_pred_1_fallThroughErr;
  wire             g_io_out_s2_full_pred_1_is_jal;
  wire             i_io_out_s2_full_pred_1_is_jal;
  wire             g_io_out_s2_full_pred_1_is_jalr;
  wire             i_io_out_s2_full_pred_1_is_jalr;
  wire             g_io_out_s2_full_pred_1_is_call;
  wire             i_io_out_s2_full_pred_1_is_call;
  wire             g_io_out_s2_full_pred_1_is_ret;
  wire             i_io_out_s2_full_pred_1_is_ret;
  wire             g_io_out_s2_full_pred_1_last_may_be_rvi_call;
  wire             i_io_out_s2_full_pred_1_last_may_be_rvi_call;
  wire             g_io_out_s2_full_pred_1_is_br_sharing;
  wire             i_io_out_s2_full_pred_1_is_br_sharing;
  wire             g_io_out_s2_full_pred_1_hit;
  wire             i_io_out_s2_full_pred_1_hit;
  wire             g_io_out_s2_full_pred_2_br_taken_mask_0;
  wire             i_io_out_s2_full_pred_2_br_taken_mask_0;
  wire             g_io_out_s2_full_pred_2_br_taken_mask_1;
  wire             i_io_out_s2_full_pred_2_br_taken_mask_1;
  wire             g_io_out_s2_full_pred_2_slot_valids_0;
  wire             i_io_out_s2_full_pred_2_slot_valids_0;
  wire             g_io_out_s2_full_pred_2_slot_valids_1;
  wire             i_io_out_s2_full_pred_2_slot_valids_1;
  wire  [49:0]     g_io_out_s2_full_pred_2_targets_0;
  wire  [49:0]     i_io_out_s2_full_pred_2_targets_0;
  wire  [49:0]     g_io_out_s2_full_pred_2_targets_1;
  wire  [49:0]     i_io_out_s2_full_pred_2_targets_1;
  wire  [49:0]     g_io_out_s2_full_pred_2_jalr_target;
  wire  [49:0]     i_io_out_s2_full_pred_2_jalr_target;
  wire  [3:0]      g_io_out_s2_full_pred_2_offsets_0;
  wire  [3:0]      i_io_out_s2_full_pred_2_offsets_0;
  wire  [3:0]      g_io_out_s2_full_pred_2_offsets_1;
  wire  [3:0]      i_io_out_s2_full_pred_2_offsets_1;
  wire  [49:0]     g_io_out_s2_full_pred_2_fallThroughAddr;
  wire  [49:0]     i_io_out_s2_full_pred_2_fallThroughAddr;
  wire             g_io_out_s2_full_pred_2_fallThroughErr;
  wire             i_io_out_s2_full_pred_2_fallThroughErr;
  wire             g_io_out_s2_full_pred_2_is_jal;
  wire             i_io_out_s2_full_pred_2_is_jal;
  wire             g_io_out_s2_full_pred_2_is_jalr;
  wire             i_io_out_s2_full_pred_2_is_jalr;
  wire             g_io_out_s2_full_pred_2_is_call;
  wire             i_io_out_s2_full_pred_2_is_call;
  wire             g_io_out_s2_full_pred_2_is_ret;
  wire             i_io_out_s2_full_pred_2_is_ret;
  wire             g_io_out_s2_full_pred_2_last_may_be_rvi_call;
  wire             i_io_out_s2_full_pred_2_last_may_be_rvi_call;
  wire             g_io_out_s2_full_pred_2_is_br_sharing;
  wire             i_io_out_s2_full_pred_2_is_br_sharing;
  wire             g_io_out_s2_full_pred_2_hit;
  wire             i_io_out_s2_full_pred_2_hit;
  wire             g_io_out_s2_full_pred_3_br_taken_mask_0;
  wire             i_io_out_s2_full_pred_3_br_taken_mask_0;
  wire             g_io_out_s2_full_pred_3_br_taken_mask_1;
  wire             i_io_out_s2_full_pred_3_br_taken_mask_1;
  wire             g_io_out_s2_full_pred_3_slot_valids_0;
  wire             i_io_out_s2_full_pred_3_slot_valids_0;
  wire             g_io_out_s2_full_pred_3_slot_valids_1;
  wire             i_io_out_s2_full_pred_3_slot_valids_1;
  wire  [49:0]     g_io_out_s2_full_pred_3_targets_0;
  wire  [49:0]     i_io_out_s2_full_pred_3_targets_0;
  wire  [49:0]     g_io_out_s2_full_pred_3_targets_1;
  wire  [49:0]     i_io_out_s2_full_pred_3_targets_1;
  wire  [49:0]     g_io_out_s2_full_pred_3_jalr_target;
  wire  [49:0]     i_io_out_s2_full_pred_3_jalr_target;
  wire  [3:0]      g_io_out_s2_full_pred_3_offsets_0;
  wire  [3:0]      i_io_out_s2_full_pred_3_offsets_0;
  wire  [3:0]      g_io_out_s2_full_pred_3_offsets_1;
  wire  [3:0]      i_io_out_s2_full_pred_3_offsets_1;
  wire  [49:0]     g_io_out_s2_full_pred_3_fallThroughAddr;
  wire  [49:0]     i_io_out_s2_full_pred_3_fallThroughAddr;
  wire             g_io_out_s2_full_pred_3_fallThroughErr;
  wire             i_io_out_s2_full_pred_3_fallThroughErr;
  wire             g_io_out_s2_full_pred_3_is_jal;
  wire             i_io_out_s2_full_pred_3_is_jal;
  wire             g_io_out_s2_full_pred_3_is_jalr;
  wire             i_io_out_s2_full_pred_3_is_jalr;
  wire             g_io_out_s2_full_pred_3_is_call;
  wire             i_io_out_s2_full_pred_3_is_call;
  wire             g_io_out_s2_full_pred_3_is_ret;
  wire             i_io_out_s2_full_pred_3_is_ret;
  wire             g_io_out_s2_full_pred_3_last_may_be_rvi_call;
  wire             i_io_out_s2_full_pred_3_last_may_be_rvi_call;
  wire             g_io_out_s2_full_pred_3_is_br_sharing;
  wire             i_io_out_s2_full_pred_3_is_br_sharing;
  wire             g_io_out_s2_full_pred_3_hit;
  wire             i_io_out_s2_full_pred_3_hit;
  wire  [49:0]     g_io_out_s3_pc_0;
  wire  [49:0]     i_io_out_s3_pc_0;
  wire  [49:0]     g_io_out_s3_pc_1;
  wire  [49:0]     i_io_out_s3_pc_1;
  wire  [49:0]     g_io_out_s3_pc_2;
  wire  [49:0]     i_io_out_s3_pc_2;
  wire  [49:0]     g_io_out_s3_pc_3;
  wire  [49:0]     i_io_out_s3_pc_3;
  wire             g_io_out_s3_full_pred_0_br_taken_mask_0;
  wire             i_io_out_s3_full_pred_0_br_taken_mask_0;
  wire             g_io_out_s3_full_pred_0_br_taken_mask_1;
  wire             i_io_out_s3_full_pred_0_br_taken_mask_1;
  wire             g_io_out_s3_full_pred_0_slot_valids_0;
  wire             i_io_out_s3_full_pred_0_slot_valids_0;
  wire             g_io_out_s3_full_pred_0_slot_valids_1;
  wire             i_io_out_s3_full_pred_0_slot_valids_1;
  wire  [49:0]     g_io_out_s3_full_pred_0_targets_0;
  wire  [49:0]     i_io_out_s3_full_pred_0_targets_0;
  wire  [49:0]     g_io_out_s3_full_pred_0_targets_1;
  wire  [49:0]     i_io_out_s3_full_pred_0_targets_1;
  wire  [49:0]     g_io_out_s3_full_pred_0_jalr_target;
  wire  [49:0]     i_io_out_s3_full_pred_0_jalr_target;
  wire  [3:0]      g_io_out_s3_full_pred_0_offsets_0;
  wire  [3:0]      i_io_out_s3_full_pred_0_offsets_0;
  wire  [3:0]      g_io_out_s3_full_pred_0_offsets_1;
  wire  [3:0]      i_io_out_s3_full_pred_0_offsets_1;
  wire  [49:0]     g_io_out_s3_full_pred_0_fallThroughAddr;
  wire  [49:0]     i_io_out_s3_full_pred_0_fallThroughAddr;
  wire             g_io_out_s3_full_pred_0_fallThroughErr;
  wire             i_io_out_s3_full_pred_0_fallThroughErr;
  wire             g_io_out_s3_full_pred_0_multiHit;
  wire             i_io_out_s3_full_pred_0_multiHit;
  wire             g_io_out_s3_full_pred_0_is_jal;
  wire             i_io_out_s3_full_pred_0_is_jal;
  wire             g_io_out_s3_full_pred_0_is_jalr;
  wire             i_io_out_s3_full_pred_0_is_jalr;
  wire             g_io_out_s3_full_pred_0_is_call;
  wire             i_io_out_s3_full_pred_0_is_call;
  wire             g_io_out_s3_full_pred_0_is_ret;
  wire             i_io_out_s3_full_pred_0_is_ret;
  wire             g_io_out_s3_full_pred_0_last_may_be_rvi_call;
  wire             i_io_out_s3_full_pred_0_last_may_be_rvi_call;
  wire             g_io_out_s3_full_pred_0_is_br_sharing;
  wire             i_io_out_s3_full_pred_0_is_br_sharing;
  wire             g_io_out_s3_full_pred_0_hit;
  wire             i_io_out_s3_full_pred_0_hit;
  wire             g_io_out_s3_full_pred_1_br_taken_mask_0;
  wire             i_io_out_s3_full_pred_1_br_taken_mask_0;
  wire             g_io_out_s3_full_pred_1_br_taken_mask_1;
  wire             i_io_out_s3_full_pred_1_br_taken_mask_1;
  wire             g_io_out_s3_full_pred_1_slot_valids_0;
  wire             i_io_out_s3_full_pred_1_slot_valids_0;
  wire             g_io_out_s3_full_pred_1_slot_valids_1;
  wire             i_io_out_s3_full_pred_1_slot_valids_1;
  wire  [49:0]     g_io_out_s3_full_pred_1_targets_0;
  wire  [49:0]     i_io_out_s3_full_pred_1_targets_0;
  wire  [49:0]     g_io_out_s3_full_pred_1_targets_1;
  wire  [49:0]     i_io_out_s3_full_pred_1_targets_1;
  wire  [49:0]     g_io_out_s3_full_pred_1_jalr_target;
  wire  [49:0]     i_io_out_s3_full_pred_1_jalr_target;
  wire  [3:0]      g_io_out_s3_full_pred_1_offsets_0;
  wire  [3:0]      i_io_out_s3_full_pred_1_offsets_0;
  wire  [3:0]      g_io_out_s3_full_pred_1_offsets_1;
  wire  [3:0]      i_io_out_s3_full_pred_1_offsets_1;
  wire  [49:0]     g_io_out_s3_full_pred_1_fallThroughAddr;
  wire  [49:0]     i_io_out_s3_full_pred_1_fallThroughAddr;
  wire             g_io_out_s3_full_pred_1_fallThroughErr;
  wire             i_io_out_s3_full_pred_1_fallThroughErr;
  wire             g_io_out_s3_full_pred_1_multiHit;
  wire             i_io_out_s3_full_pred_1_multiHit;
  wire             g_io_out_s3_full_pred_1_is_jal;
  wire             i_io_out_s3_full_pred_1_is_jal;
  wire             g_io_out_s3_full_pred_1_is_jalr;
  wire             i_io_out_s3_full_pred_1_is_jalr;
  wire             g_io_out_s3_full_pred_1_is_call;
  wire             i_io_out_s3_full_pred_1_is_call;
  wire             g_io_out_s3_full_pred_1_is_ret;
  wire             i_io_out_s3_full_pred_1_is_ret;
  wire             g_io_out_s3_full_pred_1_last_may_be_rvi_call;
  wire             i_io_out_s3_full_pred_1_last_may_be_rvi_call;
  wire             g_io_out_s3_full_pred_1_is_br_sharing;
  wire             i_io_out_s3_full_pred_1_is_br_sharing;
  wire             g_io_out_s3_full_pred_1_hit;
  wire             i_io_out_s3_full_pred_1_hit;
  wire             g_io_out_s3_full_pred_2_br_taken_mask_0;
  wire             i_io_out_s3_full_pred_2_br_taken_mask_0;
  wire             g_io_out_s3_full_pred_2_br_taken_mask_1;
  wire             i_io_out_s3_full_pred_2_br_taken_mask_1;
  wire             g_io_out_s3_full_pred_2_slot_valids_0;
  wire             i_io_out_s3_full_pred_2_slot_valids_0;
  wire             g_io_out_s3_full_pred_2_slot_valids_1;
  wire             i_io_out_s3_full_pred_2_slot_valids_1;
  wire  [49:0]     g_io_out_s3_full_pred_2_targets_0;
  wire  [49:0]     i_io_out_s3_full_pred_2_targets_0;
  wire  [49:0]     g_io_out_s3_full_pred_2_targets_1;
  wire  [49:0]     i_io_out_s3_full_pred_2_targets_1;
  wire  [49:0]     g_io_out_s3_full_pred_2_jalr_target;
  wire  [49:0]     i_io_out_s3_full_pred_2_jalr_target;
  wire  [3:0]      g_io_out_s3_full_pred_2_offsets_0;
  wire  [3:0]      i_io_out_s3_full_pred_2_offsets_0;
  wire  [3:0]      g_io_out_s3_full_pred_2_offsets_1;
  wire  [3:0]      i_io_out_s3_full_pred_2_offsets_1;
  wire  [49:0]     g_io_out_s3_full_pred_2_fallThroughAddr;
  wire  [49:0]     i_io_out_s3_full_pred_2_fallThroughAddr;
  wire             g_io_out_s3_full_pred_2_fallThroughErr;
  wire             i_io_out_s3_full_pred_2_fallThroughErr;
  wire             g_io_out_s3_full_pred_2_multiHit;
  wire             i_io_out_s3_full_pred_2_multiHit;
  wire             g_io_out_s3_full_pred_2_is_jal;
  wire             i_io_out_s3_full_pred_2_is_jal;
  wire             g_io_out_s3_full_pred_2_is_jalr;
  wire             i_io_out_s3_full_pred_2_is_jalr;
  wire             g_io_out_s3_full_pred_2_is_call;
  wire             i_io_out_s3_full_pred_2_is_call;
  wire             g_io_out_s3_full_pred_2_is_ret;
  wire             i_io_out_s3_full_pred_2_is_ret;
  wire             g_io_out_s3_full_pred_2_last_may_be_rvi_call;
  wire             i_io_out_s3_full_pred_2_last_may_be_rvi_call;
  wire             g_io_out_s3_full_pred_2_is_br_sharing;
  wire             i_io_out_s3_full_pred_2_is_br_sharing;
  wire             g_io_out_s3_full_pred_2_hit;
  wire             i_io_out_s3_full_pred_2_hit;
  wire             g_io_out_s3_full_pred_3_br_taken_mask_0;
  wire             i_io_out_s3_full_pred_3_br_taken_mask_0;
  wire             g_io_out_s3_full_pred_3_br_taken_mask_1;
  wire             i_io_out_s3_full_pred_3_br_taken_mask_1;
  wire             g_io_out_s3_full_pred_3_slot_valids_0;
  wire             i_io_out_s3_full_pred_3_slot_valids_0;
  wire             g_io_out_s3_full_pred_3_slot_valids_1;
  wire             i_io_out_s3_full_pred_3_slot_valids_1;
  wire  [49:0]     g_io_out_s3_full_pred_3_targets_0;
  wire  [49:0]     i_io_out_s3_full_pred_3_targets_0;
  wire  [49:0]     g_io_out_s3_full_pred_3_targets_1;
  wire  [49:0]     i_io_out_s3_full_pred_3_targets_1;
  wire  [49:0]     g_io_out_s3_full_pred_3_jalr_target;
  wire  [49:0]     i_io_out_s3_full_pred_3_jalr_target;
  wire  [3:0]      g_io_out_s3_full_pred_3_offsets_0;
  wire  [3:0]      i_io_out_s3_full_pred_3_offsets_0;
  wire  [3:0]      g_io_out_s3_full_pred_3_offsets_1;
  wire  [3:0]      i_io_out_s3_full_pred_3_offsets_1;
  wire  [49:0]     g_io_out_s3_full_pred_3_fallThroughAddr;
  wire  [49:0]     i_io_out_s3_full_pred_3_fallThroughAddr;
  wire             g_io_out_s3_full_pred_3_fallThroughErr;
  wire             i_io_out_s3_full_pred_3_fallThroughErr;
  wire             g_io_out_s3_full_pred_3_multiHit;
  wire             i_io_out_s3_full_pred_3_multiHit;
  wire             g_io_out_s3_full_pred_3_is_jal;
  wire             i_io_out_s3_full_pred_3_is_jal;
  wire             g_io_out_s3_full_pred_3_is_jalr;
  wire             i_io_out_s3_full_pred_3_is_jalr;
  wire             g_io_out_s3_full_pred_3_is_call;
  wire             i_io_out_s3_full_pred_3_is_call;
  wire             g_io_out_s3_full_pred_3_is_ret;
  wire             i_io_out_s3_full_pred_3_is_ret;
  wire             g_io_out_s3_full_pred_3_last_may_be_rvi_call;
  wire             i_io_out_s3_full_pred_3_last_may_be_rvi_call;
  wire             g_io_out_s3_full_pred_3_is_br_sharing;
  wire             i_io_out_s3_full_pred_3_is_br_sharing;
  wire             g_io_out_s3_full_pred_3_hit;
  wire             i_io_out_s3_full_pred_3_hit;
  wire  [515:0]    g_io_out_last_stage_meta;
  wire  [515:0]    i_io_out_last_stage_meta;
  wire  [3:0]      g_io_out_last_stage_spec_info_ssp;
  wire  [3:0]      i_io_out_last_stage_spec_info_ssp;
  wire  [2:0]      g_io_out_last_stage_spec_info_sctr;
  wire  [2:0]      i_io_out_last_stage_spec_info_sctr;
  wire             g_io_out_last_stage_spec_info_TOSW_flag;
  wire             i_io_out_last_stage_spec_info_TOSW_flag;
  wire  [4:0]      g_io_out_last_stage_spec_info_TOSW_value;
  wire  [4:0]      i_io_out_last_stage_spec_info_TOSW_value;
  wire             g_io_out_last_stage_spec_info_TOSR_flag;
  wire             i_io_out_last_stage_spec_info_TOSR_flag;
  wire  [4:0]      g_io_out_last_stage_spec_info_TOSR_value;
  wire  [4:0]      i_io_out_last_stage_spec_info_TOSR_value;
  wire             g_io_out_last_stage_spec_info_NOS_flag;
  wire             i_io_out_last_stage_spec_info_NOS_flag;
  wire  [4:0]      g_io_out_last_stage_spec_info_NOS_value;
  wire  [4:0]      i_io_out_last_stage_spec_info_NOS_value;
  wire  [49:0]     g_io_out_last_stage_spec_info_topAddr;
  wire  [49:0]     i_io_out_last_stage_spec_info_topAddr;
  wire             g_io_out_last_stage_spec_info_sc_disagree_0;
  wire             i_io_out_last_stage_spec_info_sc_disagree_0;
  wire             g_io_out_last_stage_spec_info_sc_disagree_1;
  wire             i_io_out_last_stage_spec_info_sc_disagree_1;
  wire             g_io_out_last_stage_ftb_entry_isCall;
  wire             i_io_out_last_stage_ftb_entry_isCall;
  wire             g_io_out_last_stage_ftb_entry_isRet;
  wire             i_io_out_last_stage_ftb_entry_isRet;
  wire             g_io_out_last_stage_ftb_entry_isJalr;
  wire             i_io_out_last_stage_ftb_entry_isJalr;
  wire             g_io_out_last_stage_ftb_entry_valid;
  wire             i_io_out_last_stage_ftb_entry_valid;
  wire  [3:0]      g_io_out_last_stage_ftb_entry_brSlots_0_offset;
  wire  [3:0]      i_io_out_last_stage_ftb_entry_brSlots_0_offset;
  wire             g_io_out_last_stage_ftb_entry_brSlots_0_sharing;
  wire             i_io_out_last_stage_ftb_entry_brSlots_0_sharing;
  wire             g_io_out_last_stage_ftb_entry_brSlots_0_valid;
  wire             i_io_out_last_stage_ftb_entry_brSlots_0_valid;
  wire  [11:0]     g_io_out_last_stage_ftb_entry_brSlots_0_lower;
  wire  [11:0]     i_io_out_last_stage_ftb_entry_brSlots_0_lower;
  wire  [1:0]      g_io_out_last_stage_ftb_entry_brSlots_0_tarStat;
  wire  [1:0]      i_io_out_last_stage_ftb_entry_brSlots_0_tarStat;
  wire  [3:0]      g_io_out_last_stage_ftb_entry_tailSlot_offset;
  wire  [3:0]      i_io_out_last_stage_ftb_entry_tailSlot_offset;
  wire             g_io_out_last_stage_ftb_entry_tailSlot_sharing;
  wire             i_io_out_last_stage_ftb_entry_tailSlot_sharing;
  wire             g_io_out_last_stage_ftb_entry_tailSlot_valid;
  wire             i_io_out_last_stage_ftb_entry_tailSlot_valid;
  wire  [19:0]     g_io_out_last_stage_ftb_entry_tailSlot_lower;
  wire  [19:0]     i_io_out_last_stage_ftb_entry_tailSlot_lower;
  wire  [1:0]      g_io_out_last_stage_ftb_entry_tailSlot_tarStat;
  wire  [1:0]      i_io_out_last_stage_ftb_entry_tailSlot_tarStat;
  wire  [3:0]      g_io_out_last_stage_ftb_entry_pftAddr;
  wire  [3:0]      i_io_out_last_stage_ftb_entry_pftAddr;
  wire             g_io_out_last_stage_ftb_entry_carry;
  wire             i_io_out_last_stage_ftb_entry_carry;
  wire             g_io_out_last_stage_ftb_entry_last_may_be_rvi_call;
  wire             i_io_out_last_stage_ftb_entry_last_may_be_rvi_call;
  wire             g_io_out_last_stage_ftb_entry_strong_bias_0;
  wire             i_io_out_last_stage_ftb_entry_strong_bias_0;
  wire             g_io_out_last_stage_ftb_entry_strong_bias_1;
  wire             i_io_out_last_stage_ftb_entry_strong_bias_1;
  wire             g_io_s1_ready;
  wire             i_io_s1_ready;
  wire  [5:0]      g_io_perf_0_value;
  wire  [5:0]      i_io_perf_0_value;
  wire  [5:0]      g_io_perf_1_value;
  wire  [5:0]      i_io_perf_1_value;
  wire  [5:0]      g_io_perf_2_value;
  wire  [5:0]      i_io_perf_2_value;
  wire  [5:0]      g_io_perf_3_value;
  wire  [5:0]      i_io_perf_3_value;
  wire  [5:0]      g_io_perf_4_value;
  wire  [5:0]      i_io_perf_4_value;
  wire  [5:0]      g_io_perf_5_value;
  wire  [5:0]      i_io_perf_5_value;
  wire  [5:0]      g_io_perf_6_value;
  wire  [5:0]      i_io_perf_6_value;
  wire             g_boreChildrenBd_bore_ack;
  wire             i_boreChildrenBd_bore_ack;
  wire  [39:0]     g_boreChildrenBd_bore_outdata;
  wire  [39:0]     i_boreChildrenBd_bore_outdata;
  wire             g_boreChildrenBd_bore_1_ack;
  wire             i_boreChildrenBd_bore_1_ack;
  wire  [23:0]     g_boreChildrenBd_bore_1_outdata;
  wire  [23:0]     i_boreChildrenBd_bore_1_outdata;
  wire             g_boreChildrenBd_bore_2_ack;
  wire             i_boreChildrenBd_bore_2_ack;
  wire  [23:0]     g_boreChildrenBd_bore_2_outdata;
  wire  [23:0]     i_boreChildrenBd_bore_2_outdata;
  wire             g_boreChildrenBd_bore_3_ack;
  wire             i_boreChildrenBd_bore_3_ack;
  wire  [23:0]     g_boreChildrenBd_bore_3_outdata;
  wire  [23:0]     i_boreChildrenBd_bore_3_outdata;
  wire             g_boreChildrenBd_bore_4_ack;
  wire             i_boreChildrenBd_bore_4_ack;
  wire  [23:0]     g_boreChildrenBd_bore_4_outdata;
  wire  [23:0]     i_boreChildrenBd_bore_4_outdata;
  wire             g_boreChildrenBd_bore_5_ack;
  wire             i_boreChildrenBd_bore_5_ack;
  wire  [23:0]     g_boreChildrenBd_bore_5_outdata;
  wire  [23:0]     i_boreChildrenBd_bore_5_outdata;
  wire             g_boreChildrenBd_bore_6_ack;
  wire             i_boreChildrenBd_bore_6_ack;
  wire  [75:0]     g_boreChildrenBd_bore_6_outdata;
  wire  [75:0]     i_boreChildrenBd_bore_6_outdata;
  wire             g_boreChildrenBd_bore_7_ack;
  wire             i_boreChildrenBd_bore_7_ack;
  wire  [75:0]     g_boreChildrenBd_bore_7_outdata;
  wire  [75:0]     i_boreChildrenBd_bore_7_outdata;
  wire             g_boreChildrenBd_bore_8_ack;
  wire             i_boreChildrenBd_bore_8_ack;
  wire  [75:0]     g_boreChildrenBd_bore_8_outdata;
  wire  [75:0]     i_boreChildrenBd_bore_8_outdata;
  wire             g_boreChildrenBd_bore_9_ack;
  wire             i_boreChildrenBd_bore_9_ack;
  wire  [75:0]     g_boreChildrenBd_bore_9_outdata;
  wire  [75:0]     i_boreChildrenBd_bore_9_outdata;
  wire             g_boreChildrenBd_bore_10_ack;
  wire             i_boreChildrenBd_bore_10_ack;
  wire  [75:0]     g_boreChildrenBd_bore_10_outdata;
  wire  [75:0]     i_boreChildrenBd_bore_10_outdata;

  Composer g_dut (
    .clock (clock),
    .reset (reset),
    .io_reset_vector (io_reset_vector),
    .io_in_bits_s0_pc_0 (io_in_bits_s0_pc_0),
    .io_in_bits_s0_pc_1 (io_in_bits_s0_pc_1),
    .io_in_bits_s0_pc_2 (io_in_bits_s0_pc_2),
    .io_in_bits_s0_pc_3 (io_in_bits_s0_pc_3),
    .io_in_bits_folded_hist_1_hist_17_folded_hist (io_in_bits_folded_hist_1_hist_17_folded_hist),
    .io_in_bits_folded_hist_1_hist_16_folded_hist (io_in_bits_folded_hist_1_hist_16_folded_hist),
    .io_in_bits_folded_hist_1_hist_15_folded_hist (io_in_bits_folded_hist_1_hist_15_folded_hist),
    .io_in_bits_folded_hist_1_hist_14_folded_hist (io_in_bits_folded_hist_1_hist_14_folded_hist),
    .io_in_bits_folded_hist_1_hist_9_folded_hist (io_in_bits_folded_hist_1_hist_9_folded_hist),
    .io_in_bits_folded_hist_1_hist_8_folded_hist (io_in_bits_folded_hist_1_hist_8_folded_hist),
    .io_in_bits_folded_hist_1_hist_7_folded_hist (io_in_bits_folded_hist_1_hist_7_folded_hist),
    .io_in_bits_folded_hist_1_hist_5_folded_hist (io_in_bits_folded_hist_1_hist_5_folded_hist),
    .io_in_bits_folded_hist_1_hist_4_folded_hist (io_in_bits_folded_hist_1_hist_4_folded_hist),
    .io_in_bits_folded_hist_1_hist_3_folded_hist (io_in_bits_folded_hist_1_hist_3_folded_hist),
    .io_in_bits_folded_hist_1_hist_1_folded_hist (io_in_bits_folded_hist_1_hist_1_folded_hist),
    .io_in_bits_folded_hist_3_hist_12_folded_hist (io_in_bits_folded_hist_3_hist_12_folded_hist),
    .io_in_bits_folded_hist_3_hist_11_folded_hist (io_in_bits_folded_hist_3_hist_11_folded_hist),
    .io_in_bits_folded_hist_3_hist_2_folded_hist (io_in_bits_folded_hist_3_hist_2_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_14_folded_hist (io_in_bits_s1_folded_hist_3_hist_14_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_13_folded_hist (io_in_bits_s1_folded_hist_3_hist_13_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_12_folded_hist (io_in_bits_s1_folded_hist_3_hist_12_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_10_folded_hist (io_in_bits_s1_folded_hist_3_hist_10_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_6_folded_hist (io_in_bits_s1_folded_hist_3_hist_6_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_4_folded_hist (io_in_bits_s1_folded_hist_3_hist_4_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_3_folded_hist (io_in_bits_s1_folded_hist_3_hist_3_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_2_folded_hist (io_in_bits_s1_folded_hist_3_hist_2_folded_hist),
    .io_in_bits_ghist (io_in_bits_ghist),
    .io_out_s1_pc_0 (g_io_out_s1_pc_0),
    .io_out_s1_pc_1 (g_io_out_s1_pc_1),
    .io_out_s1_pc_2 (g_io_out_s1_pc_2),
    .io_out_s1_pc_3 (g_io_out_s1_pc_3),
    .io_out_s1_full_pred_0_br_taken_mask_0 (g_io_out_s1_full_pred_0_br_taken_mask_0),
    .io_out_s1_full_pred_0_br_taken_mask_1 (g_io_out_s1_full_pred_0_br_taken_mask_1),
    .io_out_s1_full_pred_0_slot_valids_0 (g_io_out_s1_full_pred_0_slot_valids_0),
    .io_out_s1_full_pred_0_slot_valids_1 (g_io_out_s1_full_pred_0_slot_valids_1),
    .io_out_s1_full_pred_0_targets_0 (g_io_out_s1_full_pred_0_targets_0),
    .io_out_s1_full_pred_0_targets_1 (g_io_out_s1_full_pred_0_targets_1),
    .io_out_s1_full_pred_0_jalr_target (g_io_out_s1_full_pred_0_jalr_target),
    .io_out_s1_full_pred_0_offsets_0 (g_io_out_s1_full_pred_0_offsets_0),
    .io_out_s1_full_pred_0_offsets_1 (g_io_out_s1_full_pred_0_offsets_1),
    .io_out_s1_full_pred_0_fallThroughAddr (g_io_out_s1_full_pred_0_fallThroughAddr),
    .io_out_s1_full_pred_0_fallThroughErr (g_io_out_s1_full_pred_0_fallThroughErr),
    .io_out_s1_full_pred_0_is_jal (g_io_out_s1_full_pred_0_is_jal),
    .io_out_s1_full_pred_0_is_jalr (g_io_out_s1_full_pred_0_is_jalr),
    .io_out_s1_full_pred_0_is_call (g_io_out_s1_full_pred_0_is_call),
    .io_out_s1_full_pred_0_is_ret (g_io_out_s1_full_pred_0_is_ret),
    .io_out_s1_full_pred_0_last_may_be_rvi_call (g_io_out_s1_full_pred_0_last_may_be_rvi_call),
    .io_out_s1_full_pred_0_is_br_sharing (g_io_out_s1_full_pred_0_is_br_sharing),
    .io_out_s1_full_pred_0_hit (g_io_out_s1_full_pred_0_hit),
    .io_out_s1_full_pred_1_br_taken_mask_0 (g_io_out_s1_full_pred_1_br_taken_mask_0),
    .io_out_s1_full_pred_1_br_taken_mask_1 (g_io_out_s1_full_pred_1_br_taken_mask_1),
    .io_out_s1_full_pred_1_slot_valids_0 (g_io_out_s1_full_pred_1_slot_valids_0),
    .io_out_s1_full_pred_1_slot_valids_1 (g_io_out_s1_full_pred_1_slot_valids_1),
    .io_out_s1_full_pred_1_targets_0 (g_io_out_s1_full_pred_1_targets_0),
    .io_out_s1_full_pred_1_targets_1 (g_io_out_s1_full_pred_1_targets_1),
    .io_out_s1_full_pred_1_jalr_target (g_io_out_s1_full_pred_1_jalr_target),
    .io_out_s1_full_pred_1_offsets_0 (g_io_out_s1_full_pred_1_offsets_0),
    .io_out_s1_full_pred_1_offsets_1 (g_io_out_s1_full_pred_1_offsets_1),
    .io_out_s1_full_pred_1_fallThroughAddr (g_io_out_s1_full_pred_1_fallThroughAddr),
    .io_out_s1_full_pred_1_fallThroughErr (g_io_out_s1_full_pred_1_fallThroughErr),
    .io_out_s1_full_pred_1_is_jal (g_io_out_s1_full_pred_1_is_jal),
    .io_out_s1_full_pred_1_is_jalr (g_io_out_s1_full_pred_1_is_jalr),
    .io_out_s1_full_pred_1_is_call (g_io_out_s1_full_pred_1_is_call),
    .io_out_s1_full_pred_1_is_ret (g_io_out_s1_full_pred_1_is_ret),
    .io_out_s1_full_pred_1_last_may_be_rvi_call (g_io_out_s1_full_pred_1_last_may_be_rvi_call),
    .io_out_s1_full_pred_1_is_br_sharing (g_io_out_s1_full_pred_1_is_br_sharing),
    .io_out_s1_full_pred_1_hit (g_io_out_s1_full_pred_1_hit),
    .io_out_s1_full_pred_2_br_taken_mask_0 (g_io_out_s1_full_pred_2_br_taken_mask_0),
    .io_out_s1_full_pred_2_br_taken_mask_1 (g_io_out_s1_full_pred_2_br_taken_mask_1),
    .io_out_s1_full_pred_2_slot_valids_0 (g_io_out_s1_full_pred_2_slot_valids_0),
    .io_out_s1_full_pred_2_slot_valids_1 (g_io_out_s1_full_pred_2_slot_valids_1),
    .io_out_s1_full_pred_2_targets_0 (g_io_out_s1_full_pred_2_targets_0),
    .io_out_s1_full_pred_2_targets_1 (g_io_out_s1_full_pred_2_targets_1),
    .io_out_s1_full_pred_2_jalr_target (g_io_out_s1_full_pred_2_jalr_target),
    .io_out_s1_full_pred_2_offsets_0 (g_io_out_s1_full_pred_2_offsets_0),
    .io_out_s1_full_pred_2_offsets_1 (g_io_out_s1_full_pred_2_offsets_1),
    .io_out_s1_full_pred_2_fallThroughAddr (g_io_out_s1_full_pred_2_fallThroughAddr),
    .io_out_s1_full_pred_2_fallThroughErr (g_io_out_s1_full_pred_2_fallThroughErr),
    .io_out_s1_full_pred_2_is_jal (g_io_out_s1_full_pred_2_is_jal),
    .io_out_s1_full_pred_2_is_jalr (g_io_out_s1_full_pred_2_is_jalr),
    .io_out_s1_full_pred_2_is_call (g_io_out_s1_full_pred_2_is_call),
    .io_out_s1_full_pred_2_is_ret (g_io_out_s1_full_pred_2_is_ret),
    .io_out_s1_full_pred_2_last_may_be_rvi_call (g_io_out_s1_full_pred_2_last_may_be_rvi_call),
    .io_out_s1_full_pred_2_is_br_sharing (g_io_out_s1_full_pred_2_is_br_sharing),
    .io_out_s1_full_pred_2_hit (g_io_out_s1_full_pred_2_hit),
    .io_out_s1_full_pred_3_br_taken_mask_0 (g_io_out_s1_full_pred_3_br_taken_mask_0),
    .io_out_s1_full_pred_3_br_taken_mask_1 (g_io_out_s1_full_pred_3_br_taken_mask_1),
    .io_out_s1_full_pred_3_slot_valids_0 (g_io_out_s1_full_pred_3_slot_valids_0),
    .io_out_s1_full_pred_3_slot_valids_1 (g_io_out_s1_full_pred_3_slot_valids_1),
    .io_out_s1_full_pred_3_targets_0 (g_io_out_s1_full_pred_3_targets_0),
    .io_out_s1_full_pred_3_targets_1 (g_io_out_s1_full_pred_3_targets_1),
    .io_out_s1_full_pred_3_jalr_target (g_io_out_s1_full_pred_3_jalr_target),
    .io_out_s1_full_pred_3_offsets_0 (g_io_out_s1_full_pred_3_offsets_0),
    .io_out_s1_full_pred_3_offsets_1 (g_io_out_s1_full_pred_3_offsets_1),
    .io_out_s1_full_pred_3_fallThroughAddr (g_io_out_s1_full_pred_3_fallThroughAddr),
    .io_out_s1_full_pred_3_fallThroughErr (g_io_out_s1_full_pred_3_fallThroughErr),
    .io_out_s1_full_pred_3_is_jal (g_io_out_s1_full_pred_3_is_jal),
    .io_out_s1_full_pred_3_is_jalr (g_io_out_s1_full_pred_3_is_jalr),
    .io_out_s1_full_pred_3_is_call (g_io_out_s1_full_pred_3_is_call),
    .io_out_s1_full_pred_3_is_ret (g_io_out_s1_full_pred_3_is_ret),
    .io_out_s1_full_pred_3_last_may_be_rvi_call (g_io_out_s1_full_pred_3_last_may_be_rvi_call),
    .io_out_s1_full_pred_3_is_br_sharing (g_io_out_s1_full_pred_3_is_br_sharing),
    .io_out_s1_full_pred_3_hit (g_io_out_s1_full_pred_3_hit),
    .io_out_s2_pc_0 (g_io_out_s2_pc_0),
    .io_out_s2_pc_1 (g_io_out_s2_pc_1),
    .io_out_s2_pc_2 (g_io_out_s2_pc_2),
    .io_out_s2_pc_3 (g_io_out_s2_pc_3),
    .io_out_s2_full_pred_0_br_taken_mask_0 (g_io_out_s2_full_pred_0_br_taken_mask_0),
    .io_out_s2_full_pred_0_br_taken_mask_1 (g_io_out_s2_full_pred_0_br_taken_mask_1),
    .io_out_s2_full_pred_0_slot_valids_0 (g_io_out_s2_full_pred_0_slot_valids_0),
    .io_out_s2_full_pred_0_slot_valids_1 (g_io_out_s2_full_pred_0_slot_valids_1),
    .io_out_s2_full_pred_0_targets_0 (g_io_out_s2_full_pred_0_targets_0),
    .io_out_s2_full_pred_0_targets_1 (g_io_out_s2_full_pred_0_targets_1),
    .io_out_s2_full_pred_0_jalr_target (g_io_out_s2_full_pred_0_jalr_target),
    .io_out_s2_full_pred_0_offsets_0 (g_io_out_s2_full_pred_0_offsets_0),
    .io_out_s2_full_pred_0_offsets_1 (g_io_out_s2_full_pred_0_offsets_1),
    .io_out_s2_full_pred_0_fallThroughAddr (g_io_out_s2_full_pred_0_fallThroughAddr),
    .io_out_s2_full_pred_0_fallThroughErr (g_io_out_s2_full_pred_0_fallThroughErr),
    .io_out_s2_full_pred_0_is_jal (g_io_out_s2_full_pred_0_is_jal),
    .io_out_s2_full_pred_0_is_jalr (g_io_out_s2_full_pred_0_is_jalr),
    .io_out_s2_full_pred_0_is_call (g_io_out_s2_full_pred_0_is_call),
    .io_out_s2_full_pred_0_is_ret (g_io_out_s2_full_pred_0_is_ret),
    .io_out_s2_full_pred_0_last_may_be_rvi_call (g_io_out_s2_full_pred_0_last_may_be_rvi_call),
    .io_out_s2_full_pred_0_is_br_sharing (g_io_out_s2_full_pred_0_is_br_sharing),
    .io_out_s2_full_pred_0_hit (g_io_out_s2_full_pred_0_hit),
    .io_out_s2_full_pred_1_br_taken_mask_0 (g_io_out_s2_full_pred_1_br_taken_mask_0),
    .io_out_s2_full_pred_1_br_taken_mask_1 (g_io_out_s2_full_pred_1_br_taken_mask_1),
    .io_out_s2_full_pred_1_slot_valids_0 (g_io_out_s2_full_pred_1_slot_valids_0),
    .io_out_s2_full_pred_1_slot_valids_1 (g_io_out_s2_full_pred_1_slot_valids_1),
    .io_out_s2_full_pred_1_targets_0 (g_io_out_s2_full_pred_1_targets_0),
    .io_out_s2_full_pred_1_targets_1 (g_io_out_s2_full_pred_1_targets_1),
    .io_out_s2_full_pred_1_jalr_target (g_io_out_s2_full_pred_1_jalr_target),
    .io_out_s2_full_pred_1_offsets_0 (g_io_out_s2_full_pred_1_offsets_0),
    .io_out_s2_full_pred_1_offsets_1 (g_io_out_s2_full_pred_1_offsets_1),
    .io_out_s2_full_pred_1_fallThroughAddr (g_io_out_s2_full_pred_1_fallThroughAddr),
    .io_out_s2_full_pred_1_fallThroughErr (g_io_out_s2_full_pred_1_fallThroughErr),
    .io_out_s2_full_pred_1_is_jal (g_io_out_s2_full_pred_1_is_jal),
    .io_out_s2_full_pred_1_is_jalr (g_io_out_s2_full_pred_1_is_jalr),
    .io_out_s2_full_pred_1_is_call (g_io_out_s2_full_pred_1_is_call),
    .io_out_s2_full_pred_1_is_ret (g_io_out_s2_full_pred_1_is_ret),
    .io_out_s2_full_pred_1_last_may_be_rvi_call (g_io_out_s2_full_pred_1_last_may_be_rvi_call),
    .io_out_s2_full_pred_1_is_br_sharing (g_io_out_s2_full_pred_1_is_br_sharing),
    .io_out_s2_full_pred_1_hit (g_io_out_s2_full_pred_1_hit),
    .io_out_s2_full_pred_2_br_taken_mask_0 (g_io_out_s2_full_pred_2_br_taken_mask_0),
    .io_out_s2_full_pred_2_br_taken_mask_1 (g_io_out_s2_full_pred_2_br_taken_mask_1),
    .io_out_s2_full_pred_2_slot_valids_0 (g_io_out_s2_full_pred_2_slot_valids_0),
    .io_out_s2_full_pred_2_slot_valids_1 (g_io_out_s2_full_pred_2_slot_valids_1),
    .io_out_s2_full_pred_2_targets_0 (g_io_out_s2_full_pred_2_targets_0),
    .io_out_s2_full_pred_2_targets_1 (g_io_out_s2_full_pred_2_targets_1),
    .io_out_s2_full_pred_2_jalr_target (g_io_out_s2_full_pred_2_jalr_target),
    .io_out_s2_full_pred_2_offsets_0 (g_io_out_s2_full_pred_2_offsets_0),
    .io_out_s2_full_pred_2_offsets_1 (g_io_out_s2_full_pred_2_offsets_1),
    .io_out_s2_full_pred_2_fallThroughAddr (g_io_out_s2_full_pred_2_fallThroughAddr),
    .io_out_s2_full_pred_2_fallThroughErr (g_io_out_s2_full_pred_2_fallThroughErr),
    .io_out_s2_full_pred_2_is_jal (g_io_out_s2_full_pred_2_is_jal),
    .io_out_s2_full_pred_2_is_jalr (g_io_out_s2_full_pred_2_is_jalr),
    .io_out_s2_full_pred_2_is_call (g_io_out_s2_full_pred_2_is_call),
    .io_out_s2_full_pred_2_is_ret (g_io_out_s2_full_pred_2_is_ret),
    .io_out_s2_full_pred_2_last_may_be_rvi_call (g_io_out_s2_full_pred_2_last_may_be_rvi_call),
    .io_out_s2_full_pred_2_is_br_sharing (g_io_out_s2_full_pred_2_is_br_sharing),
    .io_out_s2_full_pred_2_hit (g_io_out_s2_full_pred_2_hit),
    .io_out_s2_full_pred_3_br_taken_mask_0 (g_io_out_s2_full_pred_3_br_taken_mask_0),
    .io_out_s2_full_pred_3_br_taken_mask_1 (g_io_out_s2_full_pred_3_br_taken_mask_1),
    .io_out_s2_full_pred_3_slot_valids_0 (g_io_out_s2_full_pred_3_slot_valids_0),
    .io_out_s2_full_pred_3_slot_valids_1 (g_io_out_s2_full_pred_3_slot_valids_1),
    .io_out_s2_full_pred_3_targets_0 (g_io_out_s2_full_pred_3_targets_0),
    .io_out_s2_full_pred_3_targets_1 (g_io_out_s2_full_pred_3_targets_1),
    .io_out_s2_full_pred_3_jalr_target (g_io_out_s2_full_pred_3_jalr_target),
    .io_out_s2_full_pred_3_offsets_0 (g_io_out_s2_full_pred_3_offsets_0),
    .io_out_s2_full_pred_3_offsets_1 (g_io_out_s2_full_pred_3_offsets_1),
    .io_out_s2_full_pred_3_fallThroughAddr (g_io_out_s2_full_pred_3_fallThroughAddr),
    .io_out_s2_full_pred_3_fallThroughErr (g_io_out_s2_full_pred_3_fallThroughErr),
    .io_out_s2_full_pred_3_is_jal (g_io_out_s2_full_pred_3_is_jal),
    .io_out_s2_full_pred_3_is_jalr (g_io_out_s2_full_pred_3_is_jalr),
    .io_out_s2_full_pred_3_is_call (g_io_out_s2_full_pred_3_is_call),
    .io_out_s2_full_pred_3_is_ret (g_io_out_s2_full_pred_3_is_ret),
    .io_out_s2_full_pred_3_last_may_be_rvi_call (g_io_out_s2_full_pred_3_last_may_be_rvi_call),
    .io_out_s2_full_pred_3_is_br_sharing (g_io_out_s2_full_pred_3_is_br_sharing),
    .io_out_s2_full_pred_3_hit (g_io_out_s2_full_pred_3_hit),
    .io_out_s3_pc_0 (g_io_out_s3_pc_0),
    .io_out_s3_pc_1 (g_io_out_s3_pc_1),
    .io_out_s3_pc_2 (g_io_out_s3_pc_2),
    .io_out_s3_pc_3 (g_io_out_s3_pc_3),
    .io_out_s3_full_pred_0_br_taken_mask_0 (g_io_out_s3_full_pred_0_br_taken_mask_0),
    .io_out_s3_full_pred_0_br_taken_mask_1 (g_io_out_s3_full_pred_0_br_taken_mask_1),
    .io_out_s3_full_pred_0_slot_valids_0 (g_io_out_s3_full_pred_0_slot_valids_0),
    .io_out_s3_full_pred_0_slot_valids_1 (g_io_out_s3_full_pred_0_slot_valids_1),
    .io_out_s3_full_pred_0_targets_0 (g_io_out_s3_full_pred_0_targets_0),
    .io_out_s3_full_pred_0_targets_1 (g_io_out_s3_full_pred_0_targets_1),
    .io_out_s3_full_pred_0_jalr_target (g_io_out_s3_full_pred_0_jalr_target),
    .io_out_s3_full_pred_0_offsets_0 (g_io_out_s3_full_pred_0_offsets_0),
    .io_out_s3_full_pred_0_offsets_1 (g_io_out_s3_full_pred_0_offsets_1),
    .io_out_s3_full_pred_0_fallThroughAddr (g_io_out_s3_full_pred_0_fallThroughAddr),
    .io_out_s3_full_pred_0_fallThroughErr (g_io_out_s3_full_pred_0_fallThroughErr),
    .io_out_s3_full_pred_0_multiHit (g_io_out_s3_full_pred_0_multiHit),
    .io_out_s3_full_pred_0_is_jal (g_io_out_s3_full_pred_0_is_jal),
    .io_out_s3_full_pred_0_is_jalr (g_io_out_s3_full_pred_0_is_jalr),
    .io_out_s3_full_pred_0_is_call (g_io_out_s3_full_pred_0_is_call),
    .io_out_s3_full_pred_0_is_ret (g_io_out_s3_full_pred_0_is_ret),
    .io_out_s3_full_pred_0_last_may_be_rvi_call (g_io_out_s3_full_pred_0_last_may_be_rvi_call),
    .io_out_s3_full_pred_0_is_br_sharing (g_io_out_s3_full_pred_0_is_br_sharing),
    .io_out_s3_full_pred_0_hit (g_io_out_s3_full_pred_0_hit),
    .io_out_s3_full_pred_1_br_taken_mask_0 (g_io_out_s3_full_pred_1_br_taken_mask_0),
    .io_out_s3_full_pred_1_br_taken_mask_1 (g_io_out_s3_full_pred_1_br_taken_mask_1),
    .io_out_s3_full_pred_1_slot_valids_0 (g_io_out_s3_full_pred_1_slot_valids_0),
    .io_out_s3_full_pred_1_slot_valids_1 (g_io_out_s3_full_pred_1_slot_valids_1),
    .io_out_s3_full_pred_1_targets_0 (g_io_out_s3_full_pred_1_targets_0),
    .io_out_s3_full_pred_1_targets_1 (g_io_out_s3_full_pred_1_targets_1),
    .io_out_s3_full_pred_1_jalr_target (g_io_out_s3_full_pred_1_jalr_target),
    .io_out_s3_full_pred_1_offsets_0 (g_io_out_s3_full_pred_1_offsets_0),
    .io_out_s3_full_pred_1_offsets_1 (g_io_out_s3_full_pred_1_offsets_1),
    .io_out_s3_full_pred_1_fallThroughAddr (g_io_out_s3_full_pred_1_fallThroughAddr),
    .io_out_s3_full_pred_1_fallThroughErr (g_io_out_s3_full_pred_1_fallThroughErr),
    .io_out_s3_full_pred_1_multiHit (g_io_out_s3_full_pred_1_multiHit),
    .io_out_s3_full_pred_1_is_jal (g_io_out_s3_full_pred_1_is_jal),
    .io_out_s3_full_pred_1_is_jalr (g_io_out_s3_full_pred_1_is_jalr),
    .io_out_s3_full_pred_1_is_call (g_io_out_s3_full_pred_1_is_call),
    .io_out_s3_full_pred_1_is_ret (g_io_out_s3_full_pred_1_is_ret),
    .io_out_s3_full_pred_1_last_may_be_rvi_call (g_io_out_s3_full_pred_1_last_may_be_rvi_call),
    .io_out_s3_full_pred_1_is_br_sharing (g_io_out_s3_full_pred_1_is_br_sharing),
    .io_out_s3_full_pred_1_hit (g_io_out_s3_full_pred_1_hit),
    .io_out_s3_full_pred_2_br_taken_mask_0 (g_io_out_s3_full_pred_2_br_taken_mask_0),
    .io_out_s3_full_pred_2_br_taken_mask_1 (g_io_out_s3_full_pred_2_br_taken_mask_1),
    .io_out_s3_full_pred_2_slot_valids_0 (g_io_out_s3_full_pred_2_slot_valids_0),
    .io_out_s3_full_pred_2_slot_valids_1 (g_io_out_s3_full_pred_2_slot_valids_1),
    .io_out_s3_full_pred_2_targets_0 (g_io_out_s3_full_pred_2_targets_0),
    .io_out_s3_full_pred_2_targets_1 (g_io_out_s3_full_pred_2_targets_1),
    .io_out_s3_full_pred_2_jalr_target (g_io_out_s3_full_pred_2_jalr_target),
    .io_out_s3_full_pred_2_offsets_0 (g_io_out_s3_full_pred_2_offsets_0),
    .io_out_s3_full_pred_2_offsets_1 (g_io_out_s3_full_pred_2_offsets_1),
    .io_out_s3_full_pred_2_fallThroughAddr (g_io_out_s3_full_pred_2_fallThroughAddr),
    .io_out_s3_full_pred_2_fallThroughErr (g_io_out_s3_full_pred_2_fallThroughErr),
    .io_out_s3_full_pred_2_multiHit (g_io_out_s3_full_pred_2_multiHit),
    .io_out_s3_full_pred_2_is_jal (g_io_out_s3_full_pred_2_is_jal),
    .io_out_s3_full_pred_2_is_jalr (g_io_out_s3_full_pred_2_is_jalr),
    .io_out_s3_full_pred_2_is_call (g_io_out_s3_full_pred_2_is_call),
    .io_out_s3_full_pred_2_is_ret (g_io_out_s3_full_pred_2_is_ret),
    .io_out_s3_full_pred_2_last_may_be_rvi_call (g_io_out_s3_full_pred_2_last_may_be_rvi_call),
    .io_out_s3_full_pred_2_is_br_sharing (g_io_out_s3_full_pred_2_is_br_sharing),
    .io_out_s3_full_pred_2_hit (g_io_out_s3_full_pred_2_hit),
    .io_out_s3_full_pred_3_br_taken_mask_0 (g_io_out_s3_full_pred_3_br_taken_mask_0),
    .io_out_s3_full_pred_3_br_taken_mask_1 (g_io_out_s3_full_pred_3_br_taken_mask_1),
    .io_out_s3_full_pred_3_slot_valids_0 (g_io_out_s3_full_pred_3_slot_valids_0),
    .io_out_s3_full_pred_3_slot_valids_1 (g_io_out_s3_full_pred_3_slot_valids_1),
    .io_out_s3_full_pred_3_targets_0 (g_io_out_s3_full_pred_3_targets_0),
    .io_out_s3_full_pred_3_targets_1 (g_io_out_s3_full_pred_3_targets_1),
    .io_out_s3_full_pred_3_jalr_target (g_io_out_s3_full_pred_3_jalr_target),
    .io_out_s3_full_pred_3_offsets_0 (g_io_out_s3_full_pred_3_offsets_0),
    .io_out_s3_full_pred_3_offsets_1 (g_io_out_s3_full_pred_3_offsets_1),
    .io_out_s3_full_pred_3_fallThroughAddr (g_io_out_s3_full_pred_3_fallThroughAddr),
    .io_out_s3_full_pred_3_fallThroughErr (g_io_out_s3_full_pred_3_fallThroughErr),
    .io_out_s3_full_pred_3_multiHit (g_io_out_s3_full_pred_3_multiHit),
    .io_out_s3_full_pred_3_is_jal (g_io_out_s3_full_pred_3_is_jal),
    .io_out_s3_full_pred_3_is_jalr (g_io_out_s3_full_pred_3_is_jalr),
    .io_out_s3_full_pred_3_is_call (g_io_out_s3_full_pred_3_is_call),
    .io_out_s3_full_pred_3_is_ret (g_io_out_s3_full_pred_3_is_ret),
    .io_out_s3_full_pred_3_last_may_be_rvi_call (g_io_out_s3_full_pred_3_last_may_be_rvi_call),
    .io_out_s3_full_pred_3_is_br_sharing (g_io_out_s3_full_pred_3_is_br_sharing),
    .io_out_s3_full_pred_3_hit (g_io_out_s3_full_pred_3_hit),
    .io_out_last_stage_meta (g_io_out_last_stage_meta),
    .io_out_last_stage_spec_info_ssp (g_io_out_last_stage_spec_info_ssp),
    .io_out_last_stage_spec_info_sctr (g_io_out_last_stage_spec_info_sctr),
    .io_out_last_stage_spec_info_TOSW_flag (g_io_out_last_stage_spec_info_TOSW_flag),
    .io_out_last_stage_spec_info_TOSW_value (g_io_out_last_stage_spec_info_TOSW_value),
    .io_out_last_stage_spec_info_TOSR_flag (g_io_out_last_stage_spec_info_TOSR_flag),
    .io_out_last_stage_spec_info_TOSR_value (g_io_out_last_stage_spec_info_TOSR_value),
    .io_out_last_stage_spec_info_NOS_flag (g_io_out_last_stage_spec_info_NOS_flag),
    .io_out_last_stage_spec_info_NOS_value (g_io_out_last_stage_spec_info_NOS_value),
    .io_out_last_stage_spec_info_topAddr (g_io_out_last_stage_spec_info_topAddr),
    .io_out_last_stage_spec_info_sc_disagree_0 (g_io_out_last_stage_spec_info_sc_disagree_0),
    .io_out_last_stage_spec_info_sc_disagree_1 (g_io_out_last_stage_spec_info_sc_disagree_1),
    .io_out_last_stage_ftb_entry_isCall (g_io_out_last_stage_ftb_entry_isCall),
    .io_out_last_stage_ftb_entry_isRet (g_io_out_last_stage_ftb_entry_isRet),
    .io_out_last_stage_ftb_entry_isJalr (g_io_out_last_stage_ftb_entry_isJalr),
    .io_out_last_stage_ftb_entry_valid (g_io_out_last_stage_ftb_entry_valid),
    .io_out_last_stage_ftb_entry_brSlots_0_offset (g_io_out_last_stage_ftb_entry_brSlots_0_offset),
    .io_out_last_stage_ftb_entry_brSlots_0_sharing (g_io_out_last_stage_ftb_entry_brSlots_0_sharing),
    .io_out_last_stage_ftb_entry_brSlots_0_valid (g_io_out_last_stage_ftb_entry_brSlots_0_valid),
    .io_out_last_stage_ftb_entry_brSlots_0_lower (g_io_out_last_stage_ftb_entry_brSlots_0_lower),
    .io_out_last_stage_ftb_entry_brSlots_0_tarStat (g_io_out_last_stage_ftb_entry_brSlots_0_tarStat),
    .io_out_last_stage_ftb_entry_tailSlot_offset (g_io_out_last_stage_ftb_entry_tailSlot_offset),
    .io_out_last_stage_ftb_entry_tailSlot_sharing (g_io_out_last_stage_ftb_entry_tailSlot_sharing),
    .io_out_last_stage_ftb_entry_tailSlot_valid (g_io_out_last_stage_ftb_entry_tailSlot_valid),
    .io_out_last_stage_ftb_entry_tailSlot_lower (g_io_out_last_stage_ftb_entry_tailSlot_lower),
    .io_out_last_stage_ftb_entry_tailSlot_tarStat (g_io_out_last_stage_ftb_entry_tailSlot_tarStat),
    .io_out_last_stage_ftb_entry_pftAddr (g_io_out_last_stage_ftb_entry_pftAddr),
    .io_out_last_stage_ftb_entry_carry (g_io_out_last_stage_ftb_entry_carry),
    .io_out_last_stage_ftb_entry_last_may_be_rvi_call (g_io_out_last_stage_ftb_entry_last_may_be_rvi_call),
    .io_out_last_stage_ftb_entry_strong_bias_0 (g_io_out_last_stage_ftb_entry_strong_bias_0),
    .io_out_last_stage_ftb_entry_strong_bias_1 (g_io_out_last_stage_ftb_entry_strong_bias_1),
    .io_ctrl_ubtb_enable (io_ctrl_ubtb_enable),
    .io_ctrl_btb_enable (io_ctrl_btb_enable),
    .io_ctrl_tage_enable (io_ctrl_tage_enable),
    .io_ctrl_sc_enable (io_ctrl_sc_enable),
    .io_ctrl_ras_enable (io_ctrl_ras_enable),
    .io_s0_fire_0 (io_s0_fire_0),
    .io_s0_fire_1 (io_s0_fire_1),
    .io_s0_fire_2 (io_s0_fire_2),
    .io_s0_fire_3 (io_s0_fire_3),
    .io_s1_fire_0 (io_s1_fire_0),
    .io_s1_fire_1 (io_s1_fire_1),
    .io_s1_fire_2 (io_s1_fire_2),
    .io_s1_fire_3 (io_s1_fire_3),
    .io_s2_fire_0 (io_s2_fire_0),
    .io_s2_fire_1 (io_s2_fire_1),
    .io_s2_fire_2 (io_s2_fire_2),
    .io_s2_fire_3 (io_s2_fire_3),
    .io_s3_fire_0 (io_s3_fire_0),
    .io_s3_fire_2 (io_s3_fire_2),
    .io_s3_redirect_2 (io_s3_redirect_2),
    .io_s1_ready (g_io_s1_ready),
    .io_update_valid (io_update_valid),
    .io_update_bits_pc (io_update_bits_pc),
    .io_update_bits_ftb_entry_isCall (io_update_bits_ftb_entry_isCall),
    .io_update_bits_ftb_entry_isRet (io_update_bits_ftb_entry_isRet),
    .io_update_bits_ftb_entry_isJalr (io_update_bits_ftb_entry_isJalr),
    .io_update_bits_ftb_entry_valid (io_update_bits_ftb_entry_valid),
    .io_update_bits_ftb_entry_brSlots_0_offset (io_update_bits_ftb_entry_brSlots_0_offset),
    .io_update_bits_ftb_entry_brSlots_0_sharing (io_update_bits_ftb_entry_brSlots_0_sharing),
    .io_update_bits_ftb_entry_brSlots_0_valid (io_update_bits_ftb_entry_brSlots_0_valid),
    .io_update_bits_ftb_entry_brSlots_0_lower (io_update_bits_ftb_entry_brSlots_0_lower),
    .io_update_bits_ftb_entry_brSlots_0_tarStat (io_update_bits_ftb_entry_brSlots_0_tarStat),
    .io_update_bits_ftb_entry_tailSlot_offset (io_update_bits_ftb_entry_tailSlot_offset),
    .io_update_bits_ftb_entry_tailSlot_sharing (io_update_bits_ftb_entry_tailSlot_sharing),
    .io_update_bits_ftb_entry_tailSlot_valid (io_update_bits_ftb_entry_tailSlot_valid),
    .io_update_bits_ftb_entry_tailSlot_lower (io_update_bits_ftb_entry_tailSlot_lower),
    .io_update_bits_ftb_entry_tailSlot_tarStat (io_update_bits_ftb_entry_tailSlot_tarStat),
    .io_update_bits_ftb_entry_pftAddr (io_update_bits_ftb_entry_pftAddr),
    .io_update_bits_ftb_entry_carry (io_update_bits_ftb_entry_carry),
    .io_update_bits_ftb_entry_last_may_be_rvi_call (io_update_bits_ftb_entry_last_may_be_rvi_call),
    .io_update_bits_ftb_entry_strong_bias_0 (io_update_bits_ftb_entry_strong_bias_0),
    .io_update_bits_ftb_entry_strong_bias_1 (io_update_bits_ftb_entry_strong_bias_1),
    .io_update_bits_cfi_idx_valid (io_update_bits_cfi_idx_valid),
    .io_update_bits_cfi_idx_bits (io_update_bits_cfi_idx_bits),
    .io_update_bits_br_taken_mask_0 (io_update_bits_br_taken_mask_0),
    .io_update_bits_br_taken_mask_1 (io_update_bits_br_taken_mask_1),
    .io_update_bits_jmp_taken (io_update_bits_jmp_taken),
    .io_update_bits_mispred_mask_0 (io_update_bits_mispred_mask_0),
    .io_update_bits_mispred_mask_1 (io_update_bits_mispred_mask_1),
    .io_update_bits_mispred_mask_2 (io_update_bits_mispred_mask_2),
    .io_update_bits_false_hit (io_update_bits_false_hit),
    .io_update_bits_old_entry (io_update_bits_old_entry),
    .io_update_bits_meta (io_update_bits_meta),
    .io_update_bits_full_target (io_update_bits_full_target),
    .io_update_bits_ghist (io_update_bits_ghist),
    .io_redirect_valid (io_redirect_valid),
    .io_redirect_bits_level (io_redirect_bits_level),
    .io_redirect_bits_cfiUpdate_pc (io_redirect_bits_cfiUpdate_pc),
    .io_redirect_bits_cfiUpdate_pd_valid (io_redirect_bits_cfiUpdate_pd_valid),
    .io_redirect_bits_cfiUpdate_pd_isRVC (io_redirect_bits_cfiUpdate_pd_isRVC),
    .io_redirect_bits_cfiUpdate_pd_isCall (io_redirect_bits_cfiUpdate_pd_isCall),
    .io_redirect_bits_cfiUpdate_pd_isRet (io_redirect_bits_cfiUpdate_pd_isRet),
    .io_redirect_bits_cfiUpdate_ssp (io_redirect_bits_cfiUpdate_ssp),
    .io_redirect_bits_cfiUpdate_sctr (io_redirect_bits_cfiUpdate_sctr),
    .io_redirect_bits_cfiUpdate_TOSW_flag (io_redirect_bits_cfiUpdate_TOSW_flag),
    .io_redirect_bits_cfiUpdate_TOSW_value (io_redirect_bits_cfiUpdate_TOSW_value),
    .io_redirect_bits_cfiUpdate_TOSR_flag (io_redirect_bits_cfiUpdate_TOSR_flag),
    .io_redirect_bits_cfiUpdate_TOSR_value (io_redirect_bits_cfiUpdate_TOSR_value),
    .io_redirect_bits_cfiUpdate_NOS_flag (io_redirect_bits_cfiUpdate_NOS_flag),
    .io_redirect_bits_cfiUpdate_NOS_value (io_redirect_bits_cfiUpdate_NOS_value),
    .io_redirectFromIFU (io_redirectFromIFU),
    .io_perf_0_value (g_io_perf_0_value),
    .io_perf_1_value (g_io_perf_1_value),
    .io_perf_2_value (g_io_perf_2_value),
    .io_perf_3_value (g_io_perf_3_value),
    .io_perf_4_value (g_io_perf_4_value),
    .io_perf_5_value (g_io_perf_5_value),
    .io_perf_6_value (g_io_perf_6_value),
    .boreChildrenBd_bore_array (boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all (boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req (boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack (g_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen (boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be (boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata (boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen (boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata (g_boreChildrenBd_bore_outdata),
    .boreChildrenBd_bore_1_array (boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_1_all (boreChildrenBd_bore_1_all),
    .boreChildrenBd_bore_1_req (boreChildrenBd_bore_1_req),
    .boreChildrenBd_bore_1_ack (g_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_writeen (boreChildrenBd_bore_1_writeen),
    .boreChildrenBd_bore_1_be (boreChildrenBd_bore_1_be),
    .boreChildrenBd_bore_1_addr (boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_indata (boreChildrenBd_bore_1_indata),
    .boreChildrenBd_bore_1_readen (boreChildrenBd_bore_1_readen),
    .boreChildrenBd_bore_1_addr_rd (boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_outdata (g_boreChildrenBd_bore_1_outdata),
    .boreChildrenBd_bore_2_array (boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_2_all (boreChildrenBd_bore_2_all),
    .boreChildrenBd_bore_2_req (boreChildrenBd_bore_2_req),
    .boreChildrenBd_bore_2_ack (g_boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_2_writeen (boreChildrenBd_bore_2_writeen),
    .boreChildrenBd_bore_2_be (boreChildrenBd_bore_2_be),
    .boreChildrenBd_bore_2_addr (boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_2_indata (boreChildrenBd_bore_2_indata),
    .boreChildrenBd_bore_2_readen (boreChildrenBd_bore_2_readen),
    .boreChildrenBd_bore_2_addr_rd (boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_2_outdata (g_boreChildrenBd_bore_2_outdata),
    .boreChildrenBd_bore_3_array (boreChildrenBd_bore_3_array),
    .boreChildrenBd_bore_3_all (boreChildrenBd_bore_3_all),
    .boreChildrenBd_bore_3_req (boreChildrenBd_bore_3_req),
    .boreChildrenBd_bore_3_ack (g_boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_3_writeen (boreChildrenBd_bore_3_writeen),
    .boreChildrenBd_bore_3_be (boreChildrenBd_bore_3_be),
    .boreChildrenBd_bore_3_addr (boreChildrenBd_bore_3_addr),
    .boreChildrenBd_bore_3_indata (boreChildrenBd_bore_3_indata),
    .boreChildrenBd_bore_3_readen (boreChildrenBd_bore_3_readen),
    .boreChildrenBd_bore_3_addr_rd (boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_3_outdata (g_boreChildrenBd_bore_3_outdata),
    .boreChildrenBd_bore_4_array (boreChildrenBd_bore_4_array),
    .boreChildrenBd_bore_4_all (boreChildrenBd_bore_4_all),
    .boreChildrenBd_bore_4_req (boreChildrenBd_bore_4_req),
    .boreChildrenBd_bore_4_ack (g_boreChildrenBd_bore_4_ack),
    .boreChildrenBd_bore_4_writeen (boreChildrenBd_bore_4_writeen),
    .boreChildrenBd_bore_4_be (boreChildrenBd_bore_4_be),
    .boreChildrenBd_bore_4_addr (boreChildrenBd_bore_4_addr),
    .boreChildrenBd_bore_4_indata (boreChildrenBd_bore_4_indata),
    .boreChildrenBd_bore_4_readen (boreChildrenBd_bore_4_readen),
    .boreChildrenBd_bore_4_addr_rd (boreChildrenBd_bore_4_addr_rd),
    .boreChildrenBd_bore_4_outdata (g_boreChildrenBd_bore_4_outdata),
    .boreChildrenBd_bore_5_array (boreChildrenBd_bore_5_array),
    .boreChildrenBd_bore_5_all (boreChildrenBd_bore_5_all),
    .boreChildrenBd_bore_5_req (boreChildrenBd_bore_5_req),
    .boreChildrenBd_bore_5_ack (g_boreChildrenBd_bore_5_ack),
    .boreChildrenBd_bore_5_writeen (boreChildrenBd_bore_5_writeen),
    .boreChildrenBd_bore_5_be (boreChildrenBd_bore_5_be),
    .boreChildrenBd_bore_5_addr (boreChildrenBd_bore_5_addr),
    .boreChildrenBd_bore_5_indata (boreChildrenBd_bore_5_indata),
    .boreChildrenBd_bore_5_readen (boreChildrenBd_bore_5_readen),
    .boreChildrenBd_bore_5_addr_rd (boreChildrenBd_bore_5_addr_rd),
    .boreChildrenBd_bore_5_outdata (g_boreChildrenBd_bore_5_outdata),
    .boreChildrenBd_bore_6_array (boreChildrenBd_bore_6_array),
    .boreChildrenBd_bore_6_all (boreChildrenBd_bore_6_all),
    .boreChildrenBd_bore_6_req (boreChildrenBd_bore_6_req),
    .boreChildrenBd_bore_6_ack (g_boreChildrenBd_bore_6_ack),
    .boreChildrenBd_bore_6_writeen (boreChildrenBd_bore_6_writeen),
    .boreChildrenBd_bore_6_be (boreChildrenBd_bore_6_be),
    .boreChildrenBd_bore_6_addr (boreChildrenBd_bore_6_addr),
    .boreChildrenBd_bore_6_indata (boreChildrenBd_bore_6_indata),
    .boreChildrenBd_bore_6_readen (boreChildrenBd_bore_6_readen),
    .boreChildrenBd_bore_6_addr_rd (boreChildrenBd_bore_6_addr_rd),
    .boreChildrenBd_bore_6_outdata (g_boreChildrenBd_bore_6_outdata),
    .boreChildrenBd_bore_7_array (boreChildrenBd_bore_7_array),
    .boreChildrenBd_bore_7_all (boreChildrenBd_bore_7_all),
    .boreChildrenBd_bore_7_req (boreChildrenBd_bore_7_req),
    .boreChildrenBd_bore_7_ack (g_boreChildrenBd_bore_7_ack),
    .boreChildrenBd_bore_7_writeen (boreChildrenBd_bore_7_writeen),
    .boreChildrenBd_bore_7_be (boreChildrenBd_bore_7_be),
    .boreChildrenBd_bore_7_addr (boreChildrenBd_bore_7_addr),
    .boreChildrenBd_bore_7_indata (boreChildrenBd_bore_7_indata),
    .boreChildrenBd_bore_7_readen (boreChildrenBd_bore_7_readen),
    .boreChildrenBd_bore_7_addr_rd (boreChildrenBd_bore_7_addr_rd),
    .boreChildrenBd_bore_7_outdata (g_boreChildrenBd_bore_7_outdata),
    .boreChildrenBd_bore_8_array (boreChildrenBd_bore_8_array),
    .boreChildrenBd_bore_8_all (boreChildrenBd_bore_8_all),
    .boreChildrenBd_bore_8_req (boreChildrenBd_bore_8_req),
    .boreChildrenBd_bore_8_ack (g_boreChildrenBd_bore_8_ack),
    .boreChildrenBd_bore_8_writeen (boreChildrenBd_bore_8_writeen),
    .boreChildrenBd_bore_8_be (boreChildrenBd_bore_8_be),
    .boreChildrenBd_bore_8_addr (boreChildrenBd_bore_8_addr),
    .boreChildrenBd_bore_8_indata (boreChildrenBd_bore_8_indata),
    .boreChildrenBd_bore_8_readen (boreChildrenBd_bore_8_readen),
    .boreChildrenBd_bore_8_addr_rd (boreChildrenBd_bore_8_addr_rd),
    .boreChildrenBd_bore_8_outdata (g_boreChildrenBd_bore_8_outdata),
    .boreChildrenBd_bore_9_array (boreChildrenBd_bore_9_array),
    .boreChildrenBd_bore_9_all (boreChildrenBd_bore_9_all),
    .boreChildrenBd_bore_9_req (boreChildrenBd_bore_9_req),
    .boreChildrenBd_bore_9_ack (g_boreChildrenBd_bore_9_ack),
    .boreChildrenBd_bore_9_writeen (boreChildrenBd_bore_9_writeen),
    .boreChildrenBd_bore_9_be (boreChildrenBd_bore_9_be),
    .boreChildrenBd_bore_9_addr (boreChildrenBd_bore_9_addr),
    .boreChildrenBd_bore_9_indata (boreChildrenBd_bore_9_indata),
    .boreChildrenBd_bore_9_readen (boreChildrenBd_bore_9_readen),
    .boreChildrenBd_bore_9_addr_rd (boreChildrenBd_bore_9_addr_rd),
    .boreChildrenBd_bore_9_outdata (g_boreChildrenBd_bore_9_outdata),
    .boreChildrenBd_bore_10_array (boreChildrenBd_bore_10_array),
    .boreChildrenBd_bore_10_all (boreChildrenBd_bore_10_all),
    .boreChildrenBd_bore_10_req (boreChildrenBd_bore_10_req),
    .boreChildrenBd_bore_10_ack (g_boreChildrenBd_bore_10_ack),
    .boreChildrenBd_bore_10_writeen (boreChildrenBd_bore_10_writeen),
    .boreChildrenBd_bore_10_be (boreChildrenBd_bore_10_be),
    .boreChildrenBd_bore_10_addr (boreChildrenBd_bore_10_addr),
    .boreChildrenBd_bore_10_indata (boreChildrenBd_bore_10_indata),
    .boreChildrenBd_bore_10_readen (boreChildrenBd_bore_10_readen),
    .boreChildrenBd_bore_10_addr_rd (boreChildrenBd_bore_10_addr_rd),
    .boreChildrenBd_bore_10_outdata (g_boreChildrenBd_bore_10_outdata),
    .sigFromSrams_bore_ram_hold (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen (sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen (sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen (sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold (sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass (sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken (sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk (sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp (sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold (sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen (sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold (sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass (sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken (sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk (sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp (sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold (sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen (sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold (sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass (sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken (sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk (sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp (sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold (sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen (sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold (sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass (sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken (sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk (sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp (sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold (sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen (sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold (sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass (sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken (sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk (sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp (sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold (sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen (sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold (sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass (sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken (sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk (sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp (sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold (sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen (sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold (sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass (sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken (sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk (sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp (sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold (sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen (sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_11_ram_hold (sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_11_ram_bypass (sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken (sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk (sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp (sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold (sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen (sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_12_ram_hold (sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_12_ram_bypass (sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken (sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk (sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp (sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold (sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen (sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_13_ram_hold (sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_13_ram_bypass (sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken (sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk (sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp (sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold (sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen (sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_14_ram_hold (sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_14_ram_bypass (sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken (sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk (sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp (sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold (sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen (sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_15_ram_hold (sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_15_ram_bypass (sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken (sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk (sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp (sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold (sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen (sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_16_ram_hold (sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_16_ram_bypass (sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken (sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk (sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp (sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold (sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen (sigFromSrams_bore_16_cgen),
    .sigFromSrams_bore_17_ram_hold (sigFromSrams_bore_17_ram_hold),
    .sigFromSrams_bore_17_ram_bypass (sigFromSrams_bore_17_ram_bypass),
    .sigFromSrams_bore_17_ram_bp_clken (sigFromSrams_bore_17_ram_bp_clken),
    .sigFromSrams_bore_17_ram_aux_clk (sigFromSrams_bore_17_ram_aux_clk),
    .sigFromSrams_bore_17_ram_aux_ckbp (sigFromSrams_bore_17_ram_aux_ckbp),
    .sigFromSrams_bore_17_ram_mcp_hold (sigFromSrams_bore_17_ram_mcp_hold),
    .sigFromSrams_bore_17_cgen (sigFromSrams_bore_17_cgen),
    .sigFromSrams_bore_18_ram_hold (sigFromSrams_bore_18_ram_hold),
    .sigFromSrams_bore_18_ram_bypass (sigFromSrams_bore_18_ram_bypass),
    .sigFromSrams_bore_18_ram_bp_clken (sigFromSrams_bore_18_ram_bp_clken),
    .sigFromSrams_bore_18_ram_aux_clk (sigFromSrams_bore_18_ram_aux_clk),
    .sigFromSrams_bore_18_ram_aux_ckbp (sigFromSrams_bore_18_ram_aux_ckbp),
    .sigFromSrams_bore_18_ram_mcp_hold (sigFromSrams_bore_18_ram_mcp_hold),
    .sigFromSrams_bore_18_cgen (sigFromSrams_bore_18_cgen),
    .sigFromSrams_bore_19_ram_hold (sigFromSrams_bore_19_ram_hold),
    .sigFromSrams_bore_19_ram_bypass (sigFromSrams_bore_19_ram_bypass),
    .sigFromSrams_bore_19_ram_bp_clken (sigFromSrams_bore_19_ram_bp_clken),
    .sigFromSrams_bore_19_ram_aux_clk (sigFromSrams_bore_19_ram_aux_clk),
    .sigFromSrams_bore_19_ram_aux_ckbp (sigFromSrams_bore_19_ram_aux_ckbp),
    .sigFromSrams_bore_19_ram_mcp_hold (sigFromSrams_bore_19_ram_mcp_hold),
    .sigFromSrams_bore_19_cgen (sigFromSrams_bore_19_cgen),
    .sigFromSrams_bore_20_ram_hold (sigFromSrams_bore_20_ram_hold),
    .sigFromSrams_bore_20_ram_bypass (sigFromSrams_bore_20_ram_bypass),
    .sigFromSrams_bore_20_ram_bp_clken (sigFromSrams_bore_20_ram_bp_clken),
    .sigFromSrams_bore_20_ram_aux_clk (sigFromSrams_bore_20_ram_aux_clk),
    .sigFromSrams_bore_20_ram_aux_ckbp (sigFromSrams_bore_20_ram_aux_ckbp),
    .sigFromSrams_bore_20_ram_mcp_hold (sigFromSrams_bore_20_ram_mcp_hold),
    .sigFromSrams_bore_20_cgen (sigFromSrams_bore_20_cgen),
    .sigFromSrams_bore_21_ram_hold (sigFromSrams_bore_21_ram_hold),
    .sigFromSrams_bore_21_ram_bypass (sigFromSrams_bore_21_ram_bypass),
    .sigFromSrams_bore_21_ram_bp_clken (sigFromSrams_bore_21_ram_bp_clken),
    .sigFromSrams_bore_21_ram_aux_clk (sigFromSrams_bore_21_ram_aux_clk),
    .sigFromSrams_bore_21_ram_aux_ckbp (sigFromSrams_bore_21_ram_aux_ckbp),
    .sigFromSrams_bore_21_ram_mcp_hold (sigFromSrams_bore_21_ram_mcp_hold),
    .sigFromSrams_bore_21_cgen (sigFromSrams_bore_21_cgen),
    .sigFromSrams_bore_22_ram_hold (sigFromSrams_bore_22_ram_hold),
    .sigFromSrams_bore_22_ram_bypass (sigFromSrams_bore_22_ram_bypass),
    .sigFromSrams_bore_22_ram_bp_clken (sigFromSrams_bore_22_ram_bp_clken),
    .sigFromSrams_bore_22_ram_aux_clk (sigFromSrams_bore_22_ram_aux_clk),
    .sigFromSrams_bore_22_ram_aux_ckbp (sigFromSrams_bore_22_ram_aux_ckbp),
    .sigFromSrams_bore_22_ram_mcp_hold (sigFromSrams_bore_22_ram_mcp_hold),
    .sigFromSrams_bore_22_cgen (sigFromSrams_bore_22_cgen),
    .sigFromSrams_bore_23_ram_hold (sigFromSrams_bore_23_ram_hold),
    .sigFromSrams_bore_23_ram_bypass (sigFromSrams_bore_23_ram_bypass),
    .sigFromSrams_bore_23_ram_bp_clken (sigFromSrams_bore_23_ram_bp_clken),
    .sigFromSrams_bore_23_ram_aux_clk (sigFromSrams_bore_23_ram_aux_clk),
    .sigFromSrams_bore_23_ram_aux_ckbp (sigFromSrams_bore_23_ram_aux_ckbp),
    .sigFromSrams_bore_23_ram_mcp_hold (sigFromSrams_bore_23_ram_mcp_hold),
    .sigFromSrams_bore_23_cgen (sigFromSrams_bore_23_cgen),
    .sigFromSrams_bore_24_ram_hold (sigFromSrams_bore_24_ram_hold),
    .sigFromSrams_bore_24_ram_bypass (sigFromSrams_bore_24_ram_bypass),
    .sigFromSrams_bore_24_ram_bp_clken (sigFromSrams_bore_24_ram_bp_clken),
    .sigFromSrams_bore_24_ram_aux_clk (sigFromSrams_bore_24_ram_aux_clk),
    .sigFromSrams_bore_24_ram_aux_ckbp (sigFromSrams_bore_24_ram_aux_ckbp),
    .sigFromSrams_bore_24_ram_mcp_hold (sigFromSrams_bore_24_ram_mcp_hold),
    .sigFromSrams_bore_24_cgen (sigFromSrams_bore_24_cgen),
    .sigFromSrams_bore_25_ram_hold (sigFromSrams_bore_25_ram_hold),
    .sigFromSrams_bore_25_ram_bypass (sigFromSrams_bore_25_ram_bypass),
    .sigFromSrams_bore_25_ram_bp_clken (sigFromSrams_bore_25_ram_bp_clken),
    .sigFromSrams_bore_25_ram_aux_clk (sigFromSrams_bore_25_ram_aux_clk),
    .sigFromSrams_bore_25_ram_aux_ckbp (sigFromSrams_bore_25_ram_aux_ckbp),
    .sigFromSrams_bore_25_ram_mcp_hold (sigFromSrams_bore_25_ram_mcp_hold),
    .sigFromSrams_bore_25_cgen (sigFromSrams_bore_25_cgen),
    .sigFromSrams_bore_26_ram_hold (sigFromSrams_bore_26_ram_hold),
    .sigFromSrams_bore_26_ram_bypass (sigFromSrams_bore_26_ram_bypass),
    .sigFromSrams_bore_26_ram_bp_clken (sigFromSrams_bore_26_ram_bp_clken),
    .sigFromSrams_bore_26_ram_aux_clk (sigFromSrams_bore_26_ram_aux_clk),
    .sigFromSrams_bore_26_ram_aux_ckbp (sigFromSrams_bore_26_ram_aux_ckbp),
    .sigFromSrams_bore_26_ram_mcp_hold (sigFromSrams_bore_26_ram_mcp_hold),
    .sigFromSrams_bore_26_cgen (sigFromSrams_bore_26_cgen),
    .sigFromSrams_bore_27_ram_hold (sigFromSrams_bore_27_ram_hold),
    .sigFromSrams_bore_27_ram_bypass (sigFromSrams_bore_27_ram_bypass),
    .sigFromSrams_bore_27_ram_bp_clken (sigFromSrams_bore_27_ram_bp_clken),
    .sigFromSrams_bore_27_ram_aux_clk (sigFromSrams_bore_27_ram_aux_clk),
    .sigFromSrams_bore_27_ram_aux_ckbp (sigFromSrams_bore_27_ram_aux_ckbp),
    .sigFromSrams_bore_27_ram_mcp_hold (sigFromSrams_bore_27_ram_mcp_hold),
    .sigFromSrams_bore_27_cgen (sigFromSrams_bore_27_cgen),
    .sigFromSrams_bore_28_ram_hold (sigFromSrams_bore_28_ram_hold),
    .sigFromSrams_bore_28_ram_bypass (sigFromSrams_bore_28_ram_bypass),
    .sigFromSrams_bore_28_ram_bp_clken (sigFromSrams_bore_28_ram_bp_clken),
    .sigFromSrams_bore_28_ram_aux_clk (sigFromSrams_bore_28_ram_aux_clk),
    .sigFromSrams_bore_28_ram_aux_ckbp (sigFromSrams_bore_28_ram_aux_ckbp),
    .sigFromSrams_bore_28_ram_mcp_hold (sigFromSrams_bore_28_ram_mcp_hold),
    .sigFromSrams_bore_28_cgen (sigFromSrams_bore_28_cgen),
    .sigFromSrams_bore_29_ram_hold (sigFromSrams_bore_29_ram_hold),
    .sigFromSrams_bore_29_ram_bypass (sigFromSrams_bore_29_ram_bypass),
    .sigFromSrams_bore_29_ram_bp_clken (sigFromSrams_bore_29_ram_bp_clken),
    .sigFromSrams_bore_29_ram_aux_clk (sigFromSrams_bore_29_ram_aux_clk),
    .sigFromSrams_bore_29_ram_aux_ckbp (sigFromSrams_bore_29_ram_aux_ckbp),
    .sigFromSrams_bore_29_ram_mcp_hold (sigFromSrams_bore_29_ram_mcp_hold),
    .sigFromSrams_bore_29_cgen (sigFromSrams_bore_29_cgen),
    .sigFromSrams_bore_30_ram_hold (sigFromSrams_bore_30_ram_hold),
    .sigFromSrams_bore_30_ram_bypass (sigFromSrams_bore_30_ram_bypass),
    .sigFromSrams_bore_30_ram_bp_clken (sigFromSrams_bore_30_ram_bp_clken),
    .sigFromSrams_bore_30_ram_aux_clk (sigFromSrams_bore_30_ram_aux_clk),
    .sigFromSrams_bore_30_ram_aux_ckbp (sigFromSrams_bore_30_ram_aux_ckbp),
    .sigFromSrams_bore_30_ram_mcp_hold (sigFromSrams_bore_30_ram_mcp_hold),
    .sigFromSrams_bore_30_cgen (sigFromSrams_bore_30_cgen),
    .sigFromSrams_bore_31_ram_hold (sigFromSrams_bore_31_ram_hold),
    .sigFromSrams_bore_31_ram_bypass (sigFromSrams_bore_31_ram_bypass),
    .sigFromSrams_bore_31_ram_bp_clken (sigFromSrams_bore_31_ram_bp_clken),
    .sigFromSrams_bore_31_ram_aux_clk (sigFromSrams_bore_31_ram_aux_clk),
    .sigFromSrams_bore_31_ram_aux_ckbp (sigFromSrams_bore_31_ram_aux_ckbp),
    .sigFromSrams_bore_31_ram_mcp_hold (sigFromSrams_bore_31_ram_mcp_hold),
    .sigFromSrams_bore_31_cgen (sigFromSrams_bore_31_cgen),
    .sigFromSrams_bore_32_ram_hold (sigFromSrams_bore_32_ram_hold),
    .sigFromSrams_bore_32_ram_bypass (sigFromSrams_bore_32_ram_bypass),
    .sigFromSrams_bore_32_ram_bp_clken (sigFromSrams_bore_32_ram_bp_clken),
    .sigFromSrams_bore_32_ram_aux_clk (sigFromSrams_bore_32_ram_aux_clk),
    .sigFromSrams_bore_32_ram_aux_ckbp (sigFromSrams_bore_32_ram_aux_ckbp),
    .sigFromSrams_bore_32_ram_mcp_hold (sigFromSrams_bore_32_ram_mcp_hold),
    .sigFromSrams_bore_32_cgen (sigFromSrams_bore_32_cgen),
    .sigFromSrams_bore_33_ram_hold (sigFromSrams_bore_33_ram_hold),
    .sigFromSrams_bore_33_ram_bypass (sigFromSrams_bore_33_ram_bypass),
    .sigFromSrams_bore_33_ram_bp_clken (sigFromSrams_bore_33_ram_bp_clken),
    .sigFromSrams_bore_33_ram_aux_clk (sigFromSrams_bore_33_ram_aux_clk),
    .sigFromSrams_bore_33_ram_aux_ckbp (sigFromSrams_bore_33_ram_aux_ckbp),
    .sigFromSrams_bore_33_ram_mcp_hold (sigFromSrams_bore_33_ram_mcp_hold),
    .sigFromSrams_bore_33_cgen (sigFromSrams_bore_33_cgen),
    .sigFromSrams_bore_34_ram_hold (sigFromSrams_bore_34_ram_hold),
    .sigFromSrams_bore_34_ram_bypass (sigFromSrams_bore_34_ram_bypass),
    .sigFromSrams_bore_34_ram_bp_clken (sigFromSrams_bore_34_ram_bp_clken),
    .sigFromSrams_bore_34_ram_aux_clk (sigFromSrams_bore_34_ram_aux_clk),
    .sigFromSrams_bore_34_ram_aux_ckbp (sigFromSrams_bore_34_ram_aux_ckbp),
    .sigFromSrams_bore_34_ram_mcp_hold (sigFromSrams_bore_34_ram_mcp_hold),
    .sigFromSrams_bore_34_cgen (sigFromSrams_bore_34_cgen),
    .sigFromSrams_bore_35_ram_hold (sigFromSrams_bore_35_ram_hold),
    .sigFromSrams_bore_35_ram_bypass (sigFromSrams_bore_35_ram_bypass),
    .sigFromSrams_bore_35_ram_bp_clken (sigFromSrams_bore_35_ram_bp_clken),
    .sigFromSrams_bore_35_ram_aux_clk (sigFromSrams_bore_35_ram_aux_clk),
    .sigFromSrams_bore_35_ram_aux_ckbp (sigFromSrams_bore_35_ram_aux_ckbp),
    .sigFromSrams_bore_35_ram_mcp_hold (sigFromSrams_bore_35_ram_mcp_hold),
    .sigFromSrams_bore_35_cgen (sigFromSrams_bore_35_cgen),
    .sigFromSrams_bore_36_ram_hold (sigFromSrams_bore_36_ram_hold),
    .sigFromSrams_bore_36_ram_bypass (sigFromSrams_bore_36_ram_bypass),
    .sigFromSrams_bore_36_ram_bp_clken (sigFromSrams_bore_36_ram_bp_clken),
    .sigFromSrams_bore_36_ram_aux_clk (sigFromSrams_bore_36_ram_aux_clk),
    .sigFromSrams_bore_36_ram_aux_ckbp (sigFromSrams_bore_36_ram_aux_ckbp),
    .sigFromSrams_bore_36_ram_mcp_hold (sigFromSrams_bore_36_ram_mcp_hold),
    .sigFromSrams_bore_36_cgen (sigFromSrams_bore_36_cgen),
    .sigFromSrams_bore_37_ram_hold (sigFromSrams_bore_37_ram_hold),
    .sigFromSrams_bore_37_ram_bypass (sigFromSrams_bore_37_ram_bypass),
    .sigFromSrams_bore_37_ram_bp_clken (sigFromSrams_bore_37_ram_bp_clken),
    .sigFromSrams_bore_37_ram_aux_clk (sigFromSrams_bore_37_ram_aux_clk),
    .sigFromSrams_bore_37_ram_aux_ckbp (sigFromSrams_bore_37_ram_aux_ckbp),
    .sigFromSrams_bore_37_ram_mcp_hold (sigFromSrams_bore_37_ram_mcp_hold),
    .sigFromSrams_bore_37_cgen (sigFromSrams_bore_37_cgen),
    .sigFromSrams_bore_38_ram_hold (sigFromSrams_bore_38_ram_hold),
    .sigFromSrams_bore_38_ram_bypass (sigFromSrams_bore_38_ram_bypass),
    .sigFromSrams_bore_38_ram_bp_clken (sigFromSrams_bore_38_ram_bp_clken),
    .sigFromSrams_bore_38_ram_aux_clk (sigFromSrams_bore_38_ram_aux_clk),
    .sigFromSrams_bore_38_ram_aux_ckbp (sigFromSrams_bore_38_ram_aux_ckbp),
    .sigFromSrams_bore_38_ram_mcp_hold (sigFromSrams_bore_38_ram_mcp_hold),
    .sigFromSrams_bore_38_cgen (sigFromSrams_bore_38_cgen),
    .sigFromSrams_bore_39_ram_hold (sigFromSrams_bore_39_ram_hold),
    .sigFromSrams_bore_39_ram_bypass (sigFromSrams_bore_39_ram_bypass),
    .sigFromSrams_bore_39_ram_bp_clken (sigFromSrams_bore_39_ram_bp_clken),
    .sigFromSrams_bore_39_ram_aux_clk (sigFromSrams_bore_39_ram_aux_clk),
    .sigFromSrams_bore_39_ram_aux_ckbp (sigFromSrams_bore_39_ram_aux_ckbp),
    .sigFromSrams_bore_39_ram_mcp_hold (sigFromSrams_bore_39_ram_mcp_hold),
    .sigFromSrams_bore_39_cgen (sigFromSrams_bore_39_cgen),
    .sigFromSrams_bore_40_ram_hold (sigFromSrams_bore_40_ram_hold),
    .sigFromSrams_bore_40_ram_bypass (sigFromSrams_bore_40_ram_bypass),
    .sigFromSrams_bore_40_ram_bp_clken (sigFromSrams_bore_40_ram_bp_clken),
    .sigFromSrams_bore_40_ram_aux_clk (sigFromSrams_bore_40_ram_aux_clk),
    .sigFromSrams_bore_40_ram_aux_ckbp (sigFromSrams_bore_40_ram_aux_ckbp),
    .sigFromSrams_bore_40_ram_mcp_hold (sigFromSrams_bore_40_ram_mcp_hold),
    .sigFromSrams_bore_40_cgen (sigFromSrams_bore_40_cgen),
    .sigFromSrams_bore_41_ram_hold (sigFromSrams_bore_41_ram_hold),
    .sigFromSrams_bore_41_ram_bypass (sigFromSrams_bore_41_ram_bypass),
    .sigFromSrams_bore_41_ram_bp_clken (sigFromSrams_bore_41_ram_bp_clken),
    .sigFromSrams_bore_41_ram_aux_clk (sigFromSrams_bore_41_ram_aux_clk),
    .sigFromSrams_bore_41_ram_aux_ckbp (sigFromSrams_bore_41_ram_aux_ckbp),
    .sigFromSrams_bore_41_ram_mcp_hold (sigFromSrams_bore_41_ram_mcp_hold),
    .sigFromSrams_bore_41_cgen (sigFromSrams_bore_41_cgen),
    .sigFromSrams_bore_42_ram_hold (sigFromSrams_bore_42_ram_hold),
    .sigFromSrams_bore_42_ram_bypass (sigFromSrams_bore_42_ram_bypass),
    .sigFromSrams_bore_42_ram_bp_clken (sigFromSrams_bore_42_ram_bp_clken),
    .sigFromSrams_bore_42_ram_aux_clk (sigFromSrams_bore_42_ram_aux_clk),
    .sigFromSrams_bore_42_ram_aux_ckbp (sigFromSrams_bore_42_ram_aux_ckbp),
    .sigFromSrams_bore_42_ram_mcp_hold (sigFromSrams_bore_42_ram_mcp_hold),
    .sigFromSrams_bore_42_cgen (sigFromSrams_bore_42_cgen),
    .sigFromSrams_bore_43_ram_hold (sigFromSrams_bore_43_ram_hold),
    .sigFromSrams_bore_43_ram_bypass (sigFromSrams_bore_43_ram_bypass),
    .sigFromSrams_bore_43_ram_bp_clken (sigFromSrams_bore_43_ram_bp_clken),
    .sigFromSrams_bore_43_ram_aux_clk (sigFromSrams_bore_43_ram_aux_clk),
    .sigFromSrams_bore_43_ram_aux_ckbp (sigFromSrams_bore_43_ram_aux_ckbp),
    .sigFromSrams_bore_43_ram_mcp_hold (sigFromSrams_bore_43_ram_mcp_hold),
    .sigFromSrams_bore_43_cgen (sigFromSrams_bore_43_cgen),
    .sigFromSrams_bore_44_ram_hold (sigFromSrams_bore_44_ram_hold),
    .sigFromSrams_bore_44_ram_bypass (sigFromSrams_bore_44_ram_bypass),
    .sigFromSrams_bore_44_ram_bp_clken (sigFromSrams_bore_44_ram_bp_clken),
    .sigFromSrams_bore_44_ram_aux_clk (sigFromSrams_bore_44_ram_aux_clk),
    .sigFromSrams_bore_44_ram_aux_ckbp (sigFromSrams_bore_44_ram_aux_ckbp),
    .sigFromSrams_bore_44_ram_mcp_hold (sigFromSrams_bore_44_ram_mcp_hold),
    .sigFromSrams_bore_44_cgen (sigFromSrams_bore_44_cgen),
    .sigFromSrams_bore_45_ram_hold (sigFromSrams_bore_45_ram_hold),
    .sigFromSrams_bore_45_ram_bypass (sigFromSrams_bore_45_ram_bypass),
    .sigFromSrams_bore_45_ram_bp_clken (sigFromSrams_bore_45_ram_bp_clken),
    .sigFromSrams_bore_45_ram_aux_clk (sigFromSrams_bore_45_ram_aux_clk),
    .sigFromSrams_bore_45_ram_aux_ckbp (sigFromSrams_bore_45_ram_aux_ckbp),
    .sigFromSrams_bore_45_ram_mcp_hold (sigFromSrams_bore_45_ram_mcp_hold),
    .sigFromSrams_bore_45_cgen (sigFromSrams_bore_45_cgen),
    .sigFromSrams_bore_46_ram_hold (sigFromSrams_bore_46_ram_hold),
    .sigFromSrams_bore_46_ram_bypass (sigFromSrams_bore_46_ram_bypass),
    .sigFromSrams_bore_46_ram_bp_clken (sigFromSrams_bore_46_ram_bp_clken),
    .sigFromSrams_bore_46_ram_aux_clk (sigFromSrams_bore_46_ram_aux_clk),
    .sigFromSrams_bore_46_ram_aux_ckbp (sigFromSrams_bore_46_ram_aux_ckbp),
    .sigFromSrams_bore_46_ram_mcp_hold (sigFromSrams_bore_46_ram_mcp_hold),
    .sigFromSrams_bore_46_cgen (sigFromSrams_bore_46_cgen),
    .sigFromSrams_bore_47_ram_hold (sigFromSrams_bore_47_ram_hold),
    .sigFromSrams_bore_47_ram_bypass (sigFromSrams_bore_47_ram_bypass),
    .sigFromSrams_bore_47_ram_bp_clken (sigFromSrams_bore_47_ram_bp_clken),
    .sigFromSrams_bore_47_ram_aux_clk (sigFromSrams_bore_47_ram_aux_clk),
    .sigFromSrams_bore_47_ram_aux_ckbp (sigFromSrams_bore_47_ram_aux_ckbp),
    .sigFromSrams_bore_47_ram_mcp_hold (sigFromSrams_bore_47_ram_mcp_hold),
    .sigFromSrams_bore_47_cgen (sigFromSrams_bore_47_cgen)
  );

  Composer_xs i_dut (
    .clock (clock),
    .reset (reset),
    .io_reset_vector (io_reset_vector),
    .io_in_bits_s0_pc_0 (io_in_bits_s0_pc_0),
    .io_in_bits_s0_pc_1 (io_in_bits_s0_pc_1),
    .io_in_bits_s0_pc_2 (io_in_bits_s0_pc_2),
    .io_in_bits_s0_pc_3 (io_in_bits_s0_pc_3),
    .io_in_bits_folded_hist_1_hist_17_folded_hist (io_in_bits_folded_hist_1_hist_17_folded_hist),
    .io_in_bits_folded_hist_1_hist_16_folded_hist (io_in_bits_folded_hist_1_hist_16_folded_hist),
    .io_in_bits_folded_hist_1_hist_15_folded_hist (io_in_bits_folded_hist_1_hist_15_folded_hist),
    .io_in_bits_folded_hist_1_hist_14_folded_hist (io_in_bits_folded_hist_1_hist_14_folded_hist),
    .io_in_bits_folded_hist_1_hist_9_folded_hist (io_in_bits_folded_hist_1_hist_9_folded_hist),
    .io_in_bits_folded_hist_1_hist_8_folded_hist (io_in_bits_folded_hist_1_hist_8_folded_hist),
    .io_in_bits_folded_hist_1_hist_7_folded_hist (io_in_bits_folded_hist_1_hist_7_folded_hist),
    .io_in_bits_folded_hist_1_hist_5_folded_hist (io_in_bits_folded_hist_1_hist_5_folded_hist),
    .io_in_bits_folded_hist_1_hist_4_folded_hist (io_in_bits_folded_hist_1_hist_4_folded_hist),
    .io_in_bits_folded_hist_1_hist_3_folded_hist (io_in_bits_folded_hist_1_hist_3_folded_hist),
    .io_in_bits_folded_hist_1_hist_1_folded_hist (io_in_bits_folded_hist_1_hist_1_folded_hist),
    .io_in_bits_folded_hist_3_hist_12_folded_hist (io_in_bits_folded_hist_3_hist_12_folded_hist),
    .io_in_bits_folded_hist_3_hist_11_folded_hist (io_in_bits_folded_hist_3_hist_11_folded_hist),
    .io_in_bits_folded_hist_3_hist_2_folded_hist (io_in_bits_folded_hist_3_hist_2_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_14_folded_hist (io_in_bits_s1_folded_hist_3_hist_14_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_13_folded_hist (io_in_bits_s1_folded_hist_3_hist_13_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_12_folded_hist (io_in_bits_s1_folded_hist_3_hist_12_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_10_folded_hist (io_in_bits_s1_folded_hist_3_hist_10_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_6_folded_hist (io_in_bits_s1_folded_hist_3_hist_6_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_4_folded_hist (io_in_bits_s1_folded_hist_3_hist_4_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_3_folded_hist (io_in_bits_s1_folded_hist_3_hist_3_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_2_folded_hist (io_in_bits_s1_folded_hist_3_hist_2_folded_hist),
    .io_in_bits_ghist (io_in_bits_ghist),
    .io_out_s1_pc_0 (i_io_out_s1_pc_0),
    .io_out_s1_pc_1 (i_io_out_s1_pc_1),
    .io_out_s1_pc_2 (i_io_out_s1_pc_2),
    .io_out_s1_pc_3 (i_io_out_s1_pc_3),
    .io_out_s1_full_pred_0_br_taken_mask_0 (i_io_out_s1_full_pred_0_br_taken_mask_0),
    .io_out_s1_full_pred_0_br_taken_mask_1 (i_io_out_s1_full_pred_0_br_taken_mask_1),
    .io_out_s1_full_pred_0_slot_valids_0 (i_io_out_s1_full_pred_0_slot_valids_0),
    .io_out_s1_full_pred_0_slot_valids_1 (i_io_out_s1_full_pred_0_slot_valids_1),
    .io_out_s1_full_pred_0_targets_0 (i_io_out_s1_full_pred_0_targets_0),
    .io_out_s1_full_pred_0_targets_1 (i_io_out_s1_full_pred_0_targets_1),
    .io_out_s1_full_pred_0_jalr_target (i_io_out_s1_full_pred_0_jalr_target),
    .io_out_s1_full_pred_0_offsets_0 (i_io_out_s1_full_pred_0_offsets_0),
    .io_out_s1_full_pred_0_offsets_1 (i_io_out_s1_full_pred_0_offsets_1),
    .io_out_s1_full_pred_0_fallThroughAddr (i_io_out_s1_full_pred_0_fallThroughAddr),
    .io_out_s1_full_pred_0_fallThroughErr (i_io_out_s1_full_pred_0_fallThroughErr),
    .io_out_s1_full_pred_0_is_jal (i_io_out_s1_full_pred_0_is_jal),
    .io_out_s1_full_pred_0_is_jalr (i_io_out_s1_full_pred_0_is_jalr),
    .io_out_s1_full_pred_0_is_call (i_io_out_s1_full_pred_0_is_call),
    .io_out_s1_full_pred_0_is_ret (i_io_out_s1_full_pred_0_is_ret),
    .io_out_s1_full_pred_0_last_may_be_rvi_call (i_io_out_s1_full_pred_0_last_may_be_rvi_call),
    .io_out_s1_full_pred_0_is_br_sharing (i_io_out_s1_full_pred_0_is_br_sharing),
    .io_out_s1_full_pred_0_hit (i_io_out_s1_full_pred_0_hit),
    .io_out_s1_full_pred_1_br_taken_mask_0 (i_io_out_s1_full_pred_1_br_taken_mask_0),
    .io_out_s1_full_pred_1_br_taken_mask_1 (i_io_out_s1_full_pred_1_br_taken_mask_1),
    .io_out_s1_full_pred_1_slot_valids_0 (i_io_out_s1_full_pred_1_slot_valids_0),
    .io_out_s1_full_pred_1_slot_valids_1 (i_io_out_s1_full_pred_1_slot_valids_1),
    .io_out_s1_full_pred_1_targets_0 (i_io_out_s1_full_pred_1_targets_0),
    .io_out_s1_full_pred_1_targets_1 (i_io_out_s1_full_pred_1_targets_1),
    .io_out_s1_full_pred_1_jalr_target (i_io_out_s1_full_pred_1_jalr_target),
    .io_out_s1_full_pred_1_offsets_0 (i_io_out_s1_full_pred_1_offsets_0),
    .io_out_s1_full_pred_1_offsets_1 (i_io_out_s1_full_pred_1_offsets_1),
    .io_out_s1_full_pred_1_fallThroughAddr (i_io_out_s1_full_pred_1_fallThroughAddr),
    .io_out_s1_full_pred_1_fallThroughErr (i_io_out_s1_full_pred_1_fallThroughErr),
    .io_out_s1_full_pred_1_is_jal (i_io_out_s1_full_pred_1_is_jal),
    .io_out_s1_full_pred_1_is_jalr (i_io_out_s1_full_pred_1_is_jalr),
    .io_out_s1_full_pred_1_is_call (i_io_out_s1_full_pred_1_is_call),
    .io_out_s1_full_pred_1_is_ret (i_io_out_s1_full_pred_1_is_ret),
    .io_out_s1_full_pred_1_last_may_be_rvi_call (i_io_out_s1_full_pred_1_last_may_be_rvi_call),
    .io_out_s1_full_pred_1_is_br_sharing (i_io_out_s1_full_pred_1_is_br_sharing),
    .io_out_s1_full_pred_1_hit (i_io_out_s1_full_pred_1_hit),
    .io_out_s1_full_pred_2_br_taken_mask_0 (i_io_out_s1_full_pred_2_br_taken_mask_0),
    .io_out_s1_full_pred_2_br_taken_mask_1 (i_io_out_s1_full_pred_2_br_taken_mask_1),
    .io_out_s1_full_pred_2_slot_valids_0 (i_io_out_s1_full_pred_2_slot_valids_0),
    .io_out_s1_full_pred_2_slot_valids_1 (i_io_out_s1_full_pred_2_slot_valids_1),
    .io_out_s1_full_pred_2_targets_0 (i_io_out_s1_full_pred_2_targets_0),
    .io_out_s1_full_pred_2_targets_1 (i_io_out_s1_full_pred_2_targets_1),
    .io_out_s1_full_pred_2_jalr_target (i_io_out_s1_full_pred_2_jalr_target),
    .io_out_s1_full_pred_2_offsets_0 (i_io_out_s1_full_pred_2_offsets_0),
    .io_out_s1_full_pred_2_offsets_1 (i_io_out_s1_full_pred_2_offsets_1),
    .io_out_s1_full_pred_2_fallThroughAddr (i_io_out_s1_full_pred_2_fallThroughAddr),
    .io_out_s1_full_pred_2_fallThroughErr (i_io_out_s1_full_pred_2_fallThroughErr),
    .io_out_s1_full_pred_2_is_jal (i_io_out_s1_full_pred_2_is_jal),
    .io_out_s1_full_pred_2_is_jalr (i_io_out_s1_full_pred_2_is_jalr),
    .io_out_s1_full_pred_2_is_call (i_io_out_s1_full_pred_2_is_call),
    .io_out_s1_full_pred_2_is_ret (i_io_out_s1_full_pred_2_is_ret),
    .io_out_s1_full_pred_2_last_may_be_rvi_call (i_io_out_s1_full_pred_2_last_may_be_rvi_call),
    .io_out_s1_full_pred_2_is_br_sharing (i_io_out_s1_full_pred_2_is_br_sharing),
    .io_out_s1_full_pred_2_hit (i_io_out_s1_full_pred_2_hit),
    .io_out_s1_full_pred_3_br_taken_mask_0 (i_io_out_s1_full_pred_3_br_taken_mask_0),
    .io_out_s1_full_pred_3_br_taken_mask_1 (i_io_out_s1_full_pred_3_br_taken_mask_1),
    .io_out_s1_full_pred_3_slot_valids_0 (i_io_out_s1_full_pred_3_slot_valids_0),
    .io_out_s1_full_pred_3_slot_valids_1 (i_io_out_s1_full_pred_3_slot_valids_1),
    .io_out_s1_full_pred_3_targets_0 (i_io_out_s1_full_pred_3_targets_0),
    .io_out_s1_full_pred_3_targets_1 (i_io_out_s1_full_pred_3_targets_1),
    .io_out_s1_full_pred_3_jalr_target (i_io_out_s1_full_pred_3_jalr_target),
    .io_out_s1_full_pred_3_offsets_0 (i_io_out_s1_full_pred_3_offsets_0),
    .io_out_s1_full_pred_3_offsets_1 (i_io_out_s1_full_pred_3_offsets_1),
    .io_out_s1_full_pred_3_fallThroughAddr (i_io_out_s1_full_pred_3_fallThroughAddr),
    .io_out_s1_full_pred_3_fallThroughErr (i_io_out_s1_full_pred_3_fallThroughErr),
    .io_out_s1_full_pred_3_is_jal (i_io_out_s1_full_pred_3_is_jal),
    .io_out_s1_full_pred_3_is_jalr (i_io_out_s1_full_pred_3_is_jalr),
    .io_out_s1_full_pred_3_is_call (i_io_out_s1_full_pred_3_is_call),
    .io_out_s1_full_pred_3_is_ret (i_io_out_s1_full_pred_3_is_ret),
    .io_out_s1_full_pred_3_last_may_be_rvi_call (i_io_out_s1_full_pred_3_last_may_be_rvi_call),
    .io_out_s1_full_pred_3_is_br_sharing (i_io_out_s1_full_pred_3_is_br_sharing),
    .io_out_s1_full_pred_3_hit (i_io_out_s1_full_pred_3_hit),
    .io_out_s2_pc_0 (i_io_out_s2_pc_0),
    .io_out_s2_pc_1 (i_io_out_s2_pc_1),
    .io_out_s2_pc_2 (i_io_out_s2_pc_2),
    .io_out_s2_pc_3 (i_io_out_s2_pc_3),
    .io_out_s2_full_pred_0_br_taken_mask_0 (i_io_out_s2_full_pred_0_br_taken_mask_0),
    .io_out_s2_full_pred_0_br_taken_mask_1 (i_io_out_s2_full_pred_0_br_taken_mask_1),
    .io_out_s2_full_pred_0_slot_valids_0 (i_io_out_s2_full_pred_0_slot_valids_0),
    .io_out_s2_full_pred_0_slot_valids_1 (i_io_out_s2_full_pred_0_slot_valids_1),
    .io_out_s2_full_pred_0_targets_0 (i_io_out_s2_full_pred_0_targets_0),
    .io_out_s2_full_pred_0_targets_1 (i_io_out_s2_full_pred_0_targets_1),
    .io_out_s2_full_pred_0_jalr_target (i_io_out_s2_full_pred_0_jalr_target),
    .io_out_s2_full_pred_0_offsets_0 (i_io_out_s2_full_pred_0_offsets_0),
    .io_out_s2_full_pred_0_offsets_1 (i_io_out_s2_full_pred_0_offsets_1),
    .io_out_s2_full_pred_0_fallThroughAddr (i_io_out_s2_full_pred_0_fallThroughAddr),
    .io_out_s2_full_pred_0_fallThroughErr (i_io_out_s2_full_pred_0_fallThroughErr),
    .io_out_s2_full_pred_0_is_jal (i_io_out_s2_full_pred_0_is_jal),
    .io_out_s2_full_pred_0_is_jalr (i_io_out_s2_full_pred_0_is_jalr),
    .io_out_s2_full_pred_0_is_call (i_io_out_s2_full_pred_0_is_call),
    .io_out_s2_full_pred_0_is_ret (i_io_out_s2_full_pred_0_is_ret),
    .io_out_s2_full_pred_0_last_may_be_rvi_call (i_io_out_s2_full_pred_0_last_may_be_rvi_call),
    .io_out_s2_full_pred_0_is_br_sharing (i_io_out_s2_full_pred_0_is_br_sharing),
    .io_out_s2_full_pred_0_hit (i_io_out_s2_full_pred_0_hit),
    .io_out_s2_full_pred_1_br_taken_mask_0 (i_io_out_s2_full_pred_1_br_taken_mask_0),
    .io_out_s2_full_pred_1_br_taken_mask_1 (i_io_out_s2_full_pred_1_br_taken_mask_1),
    .io_out_s2_full_pred_1_slot_valids_0 (i_io_out_s2_full_pred_1_slot_valids_0),
    .io_out_s2_full_pred_1_slot_valids_1 (i_io_out_s2_full_pred_1_slot_valids_1),
    .io_out_s2_full_pred_1_targets_0 (i_io_out_s2_full_pred_1_targets_0),
    .io_out_s2_full_pred_1_targets_1 (i_io_out_s2_full_pred_1_targets_1),
    .io_out_s2_full_pred_1_jalr_target (i_io_out_s2_full_pred_1_jalr_target),
    .io_out_s2_full_pred_1_offsets_0 (i_io_out_s2_full_pred_1_offsets_0),
    .io_out_s2_full_pred_1_offsets_1 (i_io_out_s2_full_pred_1_offsets_1),
    .io_out_s2_full_pred_1_fallThroughAddr (i_io_out_s2_full_pred_1_fallThroughAddr),
    .io_out_s2_full_pred_1_fallThroughErr (i_io_out_s2_full_pred_1_fallThroughErr),
    .io_out_s2_full_pred_1_is_jal (i_io_out_s2_full_pred_1_is_jal),
    .io_out_s2_full_pred_1_is_jalr (i_io_out_s2_full_pred_1_is_jalr),
    .io_out_s2_full_pred_1_is_call (i_io_out_s2_full_pred_1_is_call),
    .io_out_s2_full_pred_1_is_ret (i_io_out_s2_full_pred_1_is_ret),
    .io_out_s2_full_pred_1_last_may_be_rvi_call (i_io_out_s2_full_pred_1_last_may_be_rvi_call),
    .io_out_s2_full_pred_1_is_br_sharing (i_io_out_s2_full_pred_1_is_br_sharing),
    .io_out_s2_full_pred_1_hit (i_io_out_s2_full_pred_1_hit),
    .io_out_s2_full_pred_2_br_taken_mask_0 (i_io_out_s2_full_pred_2_br_taken_mask_0),
    .io_out_s2_full_pred_2_br_taken_mask_1 (i_io_out_s2_full_pred_2_br_taken_mask_1),
    .io_out_s2_full_pred_2_slot_valids_0 (i_io_out_s2_full_pred_2_slot_valids_0),
    .io_out_s2_full_pred_2_slot_valids_1 (i_io_out_s2_full_pred_2_slot_valids_1),
    .io_out_s2_full_pred_2_targets_0 (i_io_out_s2_full_pred_2_targets_0),
    .io_out_s2_full_pred_2_targets_1 (i_io_out_s2_full_pred_2_targets_1),
    .io_out_s2_full_pred_2_jalr_target (i_io_out_s2_full_pred_2_jalr_target),
    .io_out_s2_full_pred_2_offsets_0 (i_io_out_s2_full_pred_2_offsets_0),
    .io_out_s2_full_pred_2_offsets_1 (i_io_out_s2_full_pred_2_offsets_1),
    .io_out_s2_full_pred_2_fallThroughAddr (i_io_out_s2_full_pred_2_fallThroughAddr),
    .io_out_s2_full_pred_2_fallThroughErr (i_io_out_s2_full_pred_2_fallThroughErr),
    .io_out_s2_full_pred_2_is_jal (i_io_out_s2_full_pred_2_is_jal),
    .io_out_s2_full_pred_2_is_jalr (i_io_out_s2_full_pred_2_is_jalr),
    .io_out_s2_full_pred_2_is_call (i_io_out_s2_full_pred_2_is_call),
    .io_out_s2_full_pred_2_is_ret (i_io_out_s2_full_pred_2_is_ret),
    .io_out_s2_full_pred_2_last_may_be_rvi_call (i_io_out_s2_full_pred_2_last_may_be_rvi_call),
    .io_out_s2_full_pred_2_is_br_sharing (i_io_out_s2_full_pred_2_is_br_sharing),
    .io_out_s2_full_pred_2_hit (i_io_out_s2_full_pred_2_hit),
    .io_out_s2_full_pred_3_br_taken_mask_0 (i_io_out_s2_full_pred_3_br_taken_mask_0),
    .io_out_s2_full_pred_3_br_taken_mask_1 (i_io_out_s2_full_pred_3_br_taken_mask_1),
    .io_out_s2_full_pred_3_slot_valids_0 (i_io_out_s2_full_pred_3_slot_valids_0),
    .io_out_s2_full_pred_3_slot_valids_1 (i_io_out_s2_full_pred_3_slot_valids_1),
    .io_out_s2_full_pred_3_targets_0 (i_io_out_s2_full_pred_3_targets_0),
    .io_out_s2_full_pred_3_targets_1 (i_io_out_s2_full_pred_3_targets_1),
    .io_out_s2_full_pred_3_jalr_target (i_io_out_s2_full_pred_3_jalr_target),
    .io_out_s2_full_pred_3_offsets_0 (i_io_out_s2_full_pred_3_offsets_0),
    .io_out_s2_full_pred_3_offsets_1 (i_io_out_s2_full_pred_3_offsets_1),
    .io_out_s2_full_pred_3_fallThroughAddr (i_io_out_s2_full_pred_3_fallThroughAddr),
    .io_out_s2_full_pred_3_fallThroughErr (i_io_out_s2_full_pred_3_fallThroughErr),
    .io_out_s2_full_pred_3_is_jal (i_io_out_s2_full_pred_3_is_jal),
    .io_out_s2_full_pred_3_is_jalr (i_io_out_s2_full_pred_3_is_jalr),
    .io_out_s2_full_pred_3_is_call (i_io_out_s2_full_pred_3_is_call),
    .io_out_s2_full_pred_3_is_ret (i_io_out_s2_full_pred_3_is_ret),
    .io_out_s2_full_pred_3_last_may_be_rvi_call (i_io_out_s2_full_pred_3_last_may_be_rvi_call),
    .io_out_s2_full_pred_3_is_br_sharing (i_io_out_s2_full_pred_3_is_br_sharing),
    .io_out_s2_full_pred_3_hit (i_io_out_s2_full_pred_3_hit),
    .io_out_s3_pc_0 (i_io_out_s3_pc_0),
    .io_out_s3_pc_1 (i_io_out_s3_pc_1),
    .io_out_s3_pc_2 (i_io_out_s3_pc_2),
    .io_out_s3_pc_3 (i_io_out_s3_pc_3),
    .io_out_s3_full_pred_0_br_taken_mask_0 (i_io_out_s3_full_pred_0_br_taken_mask_0),
    .io_out_s3_full_pred_0_br_taken_mask_1 (i_io_out_s3_full_pred_0_br_taken_mask_1),
    .io_out_s3_full_pred_0_slot_valids_0 (i_io_out_s3_full_pred_0_slot_valids_0),
    .io_out_s3_full_pred_0_slot_valids_1 (i_io_out_s3_full_pred_0_slot_valids_1),
    .io_out_s3_full_pred_0_targets_0 (i_io_out_s3_full_pred_0_targets_0),
    .io_out_s3_full_pred_0_targets_1 (i_io_out_s3_full_pred_0_targets_1),
    .io_out_s3_full_pred_0_jalr_target (i_io_out_s3_full_pred_0_jalr_target),
    .io_out_s3_full_pred_0_offsets_0 (i_io_out_s3_full_pred_0_offsets_0),
    .io_out_s3_full_pred_0_offsets_1 (i_io_out_s3_full_pred_0_offsets_1),
    .io_out_s3_full_pred_0_fallThroughAddr (i_io_out_s3_full_pred_0_fallThroughAddr),
    .io_out_s3_full_pred_0_fallThroughErr (i_io_out_s3_full_pred_0_fallThroughErr),
    .io_out_s3_full_pred_0_multiHit (i_io_out_s3_full_pred_0_multiHit),
    .io_out_s3_full_pred_0_is_jal (i_io_out_s3_full_pred_0_is_jal),
    .io_out_s3_full_pred_0_is_jalr (i_io_out_s3_full_pred_0_is_jalr),
    .io_out_s3_full_pred_0_is_call (i_io_out_s3_full_pred_0_is_call),
    .io_out_s3_full_pred_0_is_ret (i_io_out_s3_full_pred_0_is_ret),
    .io_out_s3_full_pred_0_last_may_be_rvi_call (i_io_out_s3_full_pred_0_last_may_be_rvi_call),
    .io_out_s3_full_pred_0_is_br_sharing (i_io_out_s3_full_pred_0_is_br_sharing),
    .io_out_s3_full_pred_0_hit (i_io_out_s3_full_pred_0_hit),
    .io_out_s3_full_pred_1_br_taken_mask_0 (i_io_out_s3_full_pred_1_br_taken_mask_0),
    .io_out_s3_full_pred_1_br_taken_mask_1 (i_io_out_s3_full_pred_1_br_taken_mask_1),
    .io_out_s3_full_pred_1_slot_valids_0 (i_io_out_s3_full_pred_1_slot_valids_0),
    .io_out_s3_full_pred_1_slot_valids_1 (i_io_out_s3_full_pred_1_slot_valids_1),
    .io_out_s3_full_pred_1_targets_0 (i_io_out_s3_full_pred_1_targets_0),
    .io_out_s3_full_pred_1_targets_1 (i_io_out_s3_full_pred_1_targets_1),
    .io_out_s3_full_pred_1_jalr_target (i_io_out_s3_full_pred_1_jalr_target),
    .io_out_s3_full_pred_1_offsets_0 (i_io_out_s3_full_pred_1_offsets_0),
    .io_out_s3_full_pred_1_offsets_1 (i_io_out_s3_full_pred_1_offsets_1),
    .io_out_s3_full_pred_1_fallThroughAddr (i_io_out_s3_full_pred_1_fallThroughAddr),
    .io_out_s3_full_pred_1_fallThroughErr (i_io_out_s3_full_pred_1_fallThroughErr),
    .io_out_s3_full_pred_1_multiHit (i_io_out_s3_full_pred_1_multiHit),
    .io_out_s3_full_pred_1_is_jal (i_io_out_s3_full_pred_1_is_jal),
    .io_out_s3_full_pred_1_is_jalr (i_io_out_s3_full_pred_1_is_jalr),
    .io_out_s3_full_pred_1_is_call (i_io_out_s3_full_pred_1_is_call),
    .io_out_s3_full_pred_1_is_ret (i_io_out_s3_full_pred_1_is_ret),
    .io_out_s3_full_pred_1_last_may_be_rvi_call (i_io_out_s3_full_pred_1_last_may_be_rvi_call),
    .io_out_s3_full_pred_1_is_br_sharing (i_io_out_s3_full_pred_1_is_br_sharing),
    .io_out_s3_full_pred_1_hit (i_io_out_s3_full_pred_1_hit),
    .io_out_s3_full_pred_2_br_taken_mask_0 (i_io_out_s3_full_pred_2_br_taken_mask_0),
    .io_out_s3_full_pred_2_br_taken_mask_1 (i_io_out_s3_full_pred_2_br_taken_mask_1),
    .io_out_s3_full_pred_2_slot_valids_0 (i_io_out_s3_full_pred_2_slot_valids_0),
    .io_out_s3_full_pred_2_slot_valids_1 (i_io_out_s3_full_pred_2_slot_valids_1),
    .io_out_s3_full_pred_2_targets_0 (i_io_out_s3_full_pred_2_targets_0),
    .io_out_s3_full_pred_2_targets_1 (i_io_out_s3_full_pred_2_targets_1),
    .io_out_s3_full_pred_2_jalr_target (i_io_out_s3_full_pred_2_jalr_target),
    .io_out_s3_full_pred_2_offsets_0 (i_io_out_s3_full_pred_2_offsets_0),
    .io_out_s3_full_pred_2_offsets_1 (i_io_out_s3_full_pred_2_offsets_1),
    .io_out_s3_full_pred_2_fallThroughAddr (i_io_out_s3_full_pred_2_fallThroughAddr),
    .io_out_s3_full_pred_2_fallThroughErr (i_io_out_s3_full_pred_2_fallThroughErr),
    .io_out_s3_full_pred_2_multiHit (i_io_out_s3_full_pred_2_multiHit),
    .io_out_s3_full_pred_2_is_jal (i_io_out_s3_full_pred_2_is_jal),
    .io_out_s3_full_pred_2_is_jalr (i_io_out_s3_full_pred_2_is_jalr),
    .io_out_s3_full_pred_2_is_call (i_io_out_s3_full_pred_2_is_call),
    .io_out_s3_full_pred_2_is_ret (i_io_out_s3_full_pred_2_is_ret),
    .io_out_s3_full_pred_2_last_may_be_rvi_call (i_io_out_s3_full_pred_2_last_may_be_rvi_call),
    .io_out_s3_full_pred_2_is_br_sharing (i_io_out_s3_full_pred_2_is_br_sharing),
    .io_out_s3_full_pred_2_hit (i_io_out_s3_full_pred_2_hit),
    .io_out_s3_full_pred_3_br_taken_mask_0 (i_io_out_s3_full_pred_3_br_taken_mask_0),
    .io_out_s3_full_pred_3_br_taken_mask_1 (i_io_out_s3_full_pred_3_br_taken_mask_1),
    .io_out_s3_full_pred_3_slot_valids_0 (i_io_out_s3_full_pred_3_slot_valids_0),
    .io_out_s3_full_pred_3_slot_valids_1 (i_io_out_s3_full_pred_3_slot_valids_1),
    .io_out_s3_full_pred_3_targets_0 (i_io_out_s3_full_pred_3_targets_0),
    .io_out_s3_full_pred_3_targets_1 (i_io_out_s3_full_pred_3_targets_1),
    .io_out_s3_full_pred_3_jalr_target (i_io_out_s3_full_pred_3_jalr_target),
    .io_out_s3_full_pred_3_offsets_0 (i_io_out_s3_full_pred_3_offsets_0),
    .io_out_s3_full_pred_3_offsets_1 (i_io_out_s3_full_pred_3_offsets_1),
    .io_out_s3_full_pred_3_fallThroughAddr (i_io_out_s3_full_pred_3_fallThroughAddr),
    .io_out_s3_full_pred_3_fallThroughErr (i_io_out_s3_full_pred_3_fallThroughErr),
    .io_out_s3_full_pred_3_multiHit (i_io_out_s3_full_pred_3_multiHit),
    .io_out_s3_full_pred_3_is_jal (i_io_out_s3_full_pred_3_is_jal),
    .io_out_s3_full_pred_3_is_jalr (i_io_out_s3_full_pred_3_is_jalr),
    .io_out_s3_full_pred_3_is_call (i_io_out_s3_full_pred_3_is_call),
    .io_out_s3_full_pred_3_is_ret (i_io_out_s3_full_pred_3_is_ret),
    .io_out_s3_full_pred_3_last_may_be_rvi_call (i_io_out_s3_full_pred_3_last_may_be_rvi_call),
    .io_out_s3_full_pred_3_is_br_sharing (i_io_out_s3_full_pred_3_is_br_sharing),
    .io_out_s3_full_pred_3_hit (i_io_out_s3_full_pred_3_hit),
    .io_out_last_stage_meta (i_io_out_last_stage_meta),
    .io_out_last_stage_spec_info_ssp (i_io_out_last_stage_spec_info_ssp),
    .io_out_last_stage_spec_info_sctr (i_io_out_last_stage_spec_info_sctr),
    .io_out_last_stage_spec_info_TOSW_flag (i_io_out_last_stage_spec_info_TOSW_flag),
    .io_out_last_stage_spec_info_TOSW_value (i_io_out_last_stage_spec_info_TOSW_value),
    .io_out_last_stage_spec_info_TOSR_flag (i_io_out_last_stage_spec_info_TOSR_flag),
    .io_out_last_stage_spec_info_TOSR_value (i_io_out_last_stage_spec_info_TOSR_value),
    .io_out_last_stage_spec_info_NOS_flag (i_io_out_last_stage_spec_info_NOS_flag),
    .io_out_last_stage_spec_info_NOS_value (i_io_out_last_stage_spec_info_NOS_value),
    .io_out_last_stage_spec_info_topAddr (i_io_out_last_stage_spec_info_topAddr),
    .io_out_last_stage_spec_info_sc_disagree_0 (i_io_out_last_stage_spec_info_sc_disagree_0),
    .io_out_last_stage_spec_info_sc_disagree_1 (i_io_out_last_stage_spec_info_sc_disagree_1),
    .io_out_last_stage_ftb_entry_isCall (i_io_out_last_stage_ftb_entry_isCall),
    .io_out_last_stage_ftb_entry_isRet (i_io_out_last_stage_ftb_entry_isRet),
    .io_out_last_stage_ftb_entry_isJalr (i_io_out_last_stage_ftb_entry_isJalr),
    .io_out_last_stage_ftb_entry_valid (i_io_out_last_stage_ftb_entry_valid),
    .io_out_last_stage_ftb_entry_brSlots_0_offset (i_io_out_last_stage_ftb_entry_brSlots_0_offset),
    .io_out_last_stage_ftb_entry_brSlots_0_sharing (i_io_out_last_stage_ftb_entry_brSlots_0_sharing),
    .io_out_last_stage_ftb_entry_brSlots_0_valid (i_io_out_last_stage_ftb_entry_brSlots_0_valid),
    .io_out_last_stage_ftb_entry_brSlots_0_lower (i_io_out_last_stage_ftb_entry_brSlots_0_lower),
    .io_out_last_stage_ftb_entry_brSlots_0_tarStat (i_io_out_last_stage_ftb_entry_brSlots_0_tarStat),
    .io_out_last_stage_ftb_entry_tailSlot_offset (i_io_out_last_stage_ftb_entry_tailSlot_offset),
    .io_out_last_stage_ftb_entry_tailSlot_sharing (i_io_out_last_stage_ftb_entry_tailSlot_sharing),
    .io_out_last_stage_ftb_entry_tailSlot_valid (i_io_out_last_stage_ftb_entry_tailSlot_valid),
    .io_out_last_stage_ftb_entry_tailSlot_lower (i_io_out_last_stage_ftb_entry_tailSlot_lower),
    .io_out_last_stage_ftb_entry_tailSlot_tarStat (i_io_out_last_stage_ftb_entry_tailSlot_tarStat),
    .io_out_last_stage_ftb_entry_pftAddr (i_io_out_last_stage_ftb_entry_pftAddr),
    .io_out_last_stage_ftb_entry_carry (i_io_out_last_stage_ftb_entry_carry),
    .io_out_last_stage_ftb_entry_last_may_be_rvi_call (i_io_out_last_stage_ftb_entry_last_may_be_rvi_call),
    .io_out_last_stage_ftb_entry_strong_bias_0 (i_io_out_last_stage_ftb_entry_strong_bias_0),
    .io_out_last_stage_ftb_entry_strong_bias_1 (i_io_out_last_stage_ftb_entry_strong_bias_1),
    .io_ctrl_ubtb_enable (io_ctrl_ubtb_enable),
    .io_ctrl_btb_enable (io_ctrl_btb_enable),
    .io_ctrl_tage_enable (io_ctrl_tage_enable),
    .io_ctrl_sc_enable (io_ctrl_sc_enable),
    .io_ctrl_ras_enable (io_ctrl_ras_enable),
    .io_s0_fire_0 (io_s0_fire_0),
    .io_s0_fire_1 (io_s0_fire_1),
    .io_s0_fire_2 (io_s0_fire_2),
    .io_s0_fire_3 (io_s0_fire_3),
    .io_s1_fire_0 (io_s1_fire_0),
    .io_s1_fire_1 (io_s1_fire_1),
    .io_s1_fire_2 (io_s1_fire_2),
    .io_s1_fire_3 (io_s1_fire_3),
    .io_s2_fire_0 (io_s2_fire_0),
    .io_s2_fire_1 (io_s2_fire_1),
    .io_s2_fire_2 (io_s2_fire_2),
    .io_s2_fire_3 (io_s2_fire_3),
    .io_s3_fire_0 (io_s3_fire_0),
    .io_s3_fire_2 (io_s3_fire_2),
    .io_s3_redirect_2 (io_s3_redirect_2),
    .io_s1_ready (i_io_s1_ready),
    .io_update_valid (io_update_valid),
    .io_update_bits_pc (io_update_bits_pc),
    .io_update_bits_ftb_entry_isCall (io_update_bits_ftb_entry_isCall),
    .io_update_bits_ftb_entry_isRet (io_update_bits_ftb_entry_isRet),
    .io_update_bits_ftb_entry_isJalr (io_update_bits_ftb_entry_isJalr),
    .io_update_bits_ftb_entry_valid (io_update_bits_ftb_entry_valid),
    .io_update_bits_ftb_entry_brSlots_0_offset (io_update_bits_ftb_entry_brSlots_0_offset),
    .io_update_bits_ftb_entry_brSlots_0_sharing (io_update_bits_ftb_entry_brSlots_0_sharing),
    .io_update_bits_ftb_entry_brSlots_0_valid (io_update_bits_ftb_entry_brSlots_0_valid),
    .io_update_bits_ftb_entry_brSlots_0_lower (io_update_bits_ftb_entry_brSlots_0_lower),
    .io_update_bits_ftb_entry_brSlots_0_tarStat (io_update_bits_ftb_entry_brSlots_0_tarStat),
    .io_update_bits_ftb_entry_tailSlot_offset (io_update_bits_ftb_entry_tailSlot_offset),
    .io_update_bits_ftb_entry_tailSlot_sharing (io_update_bits_ftb_entry_tailSlot_sharing),
    .io_update_bits_ftb_entry_tailSlot_valid (io_update_bits_ftb_entry_tailSlot_valid),
    .io_update_bits_ftb_entry_tailSlot_lower (io_update_bits_ftb_entry_tailSlot_lower),
    .io_update_bits_ftb_entry_tailSlot_tarStat (io_update_bits_ftb_entry_tailSlot_tarStat),
    .io_update_bits_ftb_entry_pftAddr (io_update_bits_ftb_entry_pftAddr),
    .io_update_bits_ftb_entry_carry (io_update_bits_ftb_entry_carry),
    .io_update_bits_ftb_entry_last_may_be_rvi_call (io_update_bits_ftb_entry_last_may_be_rvi_call),
    .io_update_bits_ftb_entry_strong_bias_0 (io_update_bits_ftb_entry_strong_bias_0),
    .io_update_bits_ftb_entry_strong_bias_1 (io_update_bits_ftb_entry_strong_bias_1),
    .io_update_bits_cfi_idx_valid (io_update_bits_cfi_idx_valid),
    .io_update_bits_cfi_idx_bits (io_update_bits_cfi_idx_bits),
    .io_update_bits_br_taken_mask_0 (io_update_bits_br_taken_mask_0),
    .io_update_bits_br_taken_mask_1 (io_update_bits_br_taken_mask_1),
    .io_update_bits_jmp_taken (io_update_bits_jmp_taken),
    .io_update_bits_mispred_mask_0 (io_update_bits_mispred_mask_0),
    .io_update_bits_mispred_mask_1 (io_update_bits_mispred_mask_1),
    .io_update_bits_mispred_mask_2 (io_update_bits_mispred_mask_2),
    .io_update_bits_false_hit (io_update_bits_false_hit),
    .io_update_bits_old_entry (io_update_bits_old_entry),
    .io_update_bits_meta (io_update_bits_meta),
    .io_update_bits_full_target (io_update_bits_full_target),
    .io_update_bits_ghist (io_update_bits_ghist),
    .io_redirect_valid (io_redirect_valid),
    .io_redirect_bits_level (io_redirect_bits_level),
    .io_redirect_bits_cfiUpdate_pc (io_redirect_bits_cfiUpdate_pc),
    .io_redirect_bits_cfiUpdate_pd_valid (io_redirect_bits_cfiUpdate_pd_valid),
    .io_redirect_bits_cfiUpdate_pd_isRVC (io_redirect_bits_cfiUpdate_pd_isRVC),
    .io_redirect_bits_cfiUpdate_pd_isCall (io_redirect_bits_cfiUpdate_pd_isCall),
    .io_redirect_bits_cfiUpdate_pd_isRet (io_redirect_bits_cfiUpdate_pd_isRet),
    .io_redirect_bits_cfiUpdate_ssp (io_redirect_bits_cfiUpdate_ssp),
    .io_redirect_bits_cfiUpdate_sctr (io_redirect_bits_cfiUpdate_sctr),
    .io_redirect_bits_cfiUpdate_TOSW_flag (io_redirect_bits_cfiUpdate_TOSW_flag),
    .io_redirect_bits_cfiUpdate_TOSW_value (io_redirect_bits_cfiUpdate_TOSW_value),
    .io_redirect_bits_cfiUpdate_TOSR_flag (io_redirect_bits_cfiUpdate_TOSR_flag),
    .io_redirect_bits_cfiUpdate_TOSR_value (io_redirect_bits_cfiUpdate_TOSR_value),
    .io_redirect_bits_cfiUpdate_NOS_flag (io_redirect_bits_cfiUpdate_NOS_flag),
    .io_redirect_bits_cfiUpdate_NOS_value (io_redirect_bits_cfiUpdate_NOS_value),
    .io_redirectFromIFU (io_redirectFromIFU),
    .io_perf_0_value (i_io_perf_0_value),
    .io_perf_1_value (i_io_perf_1_value),
    .io_perf_2_value (i_io_perf_2_value),
    .io_perf_3_value (i_io_perf_3_value),
    .io_perf_4_value (i_io_perf_4_value),
    .io_perf_5_value (i_io_perf_5_value),
    .io_perf_6_value (i_io_perf_6_value),
    .boreChildrenBd_bore_array (boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all (boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req (boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack (i_boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen (boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be (boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata (boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen (boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata (i_boreChildrenBd_bore_outdata),
    .boreChildrenBd_bore_1_array (boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_1_all (boreChildrenBd_bore_1_all),
    .boreChildrenBd_bore_1_req (boreChildrenBd_bore_1_req),
    .boreChildrenBd_bore_1_ack (i_boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_writeen (boreChildrenBd_bore_1_writeen),
    .boreChildrenBd_bore_1_be (boreChildrenBd_bore_1_be),
    .boreChildrenBd_bore_1_addr (boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_indata (boreChildrenBd_bore_1_indata),
    .boreChildrenBd_bore_1_readen (boreChildrenBd_bore_1_readen),
    .boreChildrenBd_bore_1_addr_rd (boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_outdata (i_boreChildrenBd_bore_1_outdata),
    .boreChildrenBd_bore_2_array (boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_2_all (boreChildrenBd_bore_2_all),
    .boreChildrenBd_bore_2_req (boreChildrenBd_bore_2_req),
    .boreChildrenBd_bore_2_ack (i_boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_2_writeen (boreChildrenBd_bore_2_writeen),
    .boreChildrenBd_bore_2_be (boreChildrenBd_bore_2_be),
    .boreChildrenBd_bore_2_addr (boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_2_indata (boreChildrenBd_bore_2_indata),
    .boreChildrenBd_bore_2_readen (boreChildrenBd_bore_2_readen),
    .boreChildrenBd_bore_2_addr_rd (boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_2_outdata (i_boreChildrenBd_bore_2_outdata),
    .boreChildrenBd_bore_3_array (boreChildrenBd_bore_3_array),
    .boreChildrenBd_bore_3_all (boreChildrenBd_bore_3_all),
    .boreChildrenBd_bore_3_req (boreChildrenBd_bore_3_req),
    .boreChildrenBd_bore_3_ack (i_boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_3_writeen (boreChildrenBd_bore_3_writeen),
    .boreChildrenBd_bore_3_be (boreChildrenBd_bore_3_be),
    .boreChildrenBd_bore_3_addr (boreChildrenBd_bore_3_addr),
    .boreChildrenBd_bore_3_indata (boreChildrenBd_bore_3_indata),
    .boreChildrenBd_bore_3_readen (boreChildrenBd_bore_3_readen),
    .boreChildrenBd_bore_3_addr_rd (boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_3_outdata (i_boreChildrenBd_bore_3_outdata),
    .boreChildrenBd_bore_4_array (boreChildrenBd_bore_4_array),
    .boreChildrenBd_bore_4_all (boreChildrenBd_bore_4_all),
    .boreChildrenBd_bore_4_req (boreChildrenBd_bore_4_req),
    .boreChildrenBd_bore_4_ack (i_boreChildrenBd_bore_4_ack),
    .boreChildrenBd_bore_4_writeen (boreChildrenBd_bore_4_writeen),
    .boreChildrenBd_bore_4_be (boreChildrenBd_bore_4_be),
    .boreChildrenBd_bore_4_addr (boreChildrenBd_bore_4_addr),
    .boreChildrenBd_bore_4_indata (boreChildrenBd_bore_4_indata),
    .boreChildrenBd_bore_4_readen (boreChildrenBd_bore_4_readen),
    .boreChildrenBd_bore_4_addr_rd (boreChildrenBd_bore_4_addr_rd),
    .boreChildrenBd_bore_4_outdata (i_boreChildrenBd_bore_4_outdata),
    .boreChildrenBd_bore_5_array (boreChildrenBd_bore_5_array),
    .boreChildrenBd_bore_5_all (boreChildrenBd_bore_5_all),
    .boreChildrenBd_bore_5_req (boreChildrenBd_bore_5_req),
    .boreChildrenBd_bore_5_ack (i_boreChildrenBd_bore_5_ack),
    .boreChildrenBd_bore_5_writeen (boreChildrenBd_bore_5_writeen),
    .boreChildrenBd_bore_5_be (boreChildrenBd_bore_5_be),
    .boreChildrenBd_bore_5_addr (boreChildrenBd_bore_5_addr),
    .boreChildrenBd_bore_5_indata (boreChildrenBd_bore_5_indata),
    .boreChildrenBd_bore_5_readen (boreChildrenBd_bore_5_readen),
    .boreChildrenBd_bore_5_addr_rd (boreChildrenBd_bore_5_addr_rd),
    .boreChildrenBd_bore_5_outdata (i_boreChildrenBd_bore_5_outdata),
    .boreChildrenBd_bore_6_array (boreChildrenBd_bore_6_array),
    .boreChildrenBd_bore_6_all (boreChildrenBd_bore_6_all),
    .boreChildrenBd_bore_6_req (boreChildrenBd_bore_6_req),
    .boreChildrenBd_bore_6_ack (i_boreChildrenBd_bore_6_ack),
    .boreChildrenBd_bore_6_writeen (boreChildrenBd_bore_6_writeen),
    .boreChildrenBd_bore_6_be (boreChildrenBd_bore_6_be),
    .boreChildrenBd_bore_6_addr (boreChildrenBd_bore_6_addr),
    .boreChildrenBd_bore_6_indata (boreChildrenBd_bore_6_indata),
    .boreChildrenBd_bore_6_readen (boreChildrenBd_bore_6_readen),
    .boreChildrenBd_bore_6_addr_rd (boreChildrenBd_bore_6_addr_rd),
    .boreChildrenBd_bore_6_outdata (i_boreChildrenBd_bore_6_outdata),
    .boreChildrenBd_bore_7_array (boreChildrenBd_bore_7_array),
    .boreChildrenBd_bore_7_all (boreChildrenBd_bore_7_all),
    .boreChildrenBd_bore_7_req (boreChildrenBd_bore_7_req),
    .boreChildrenBd_bore_7_ack (i_boreChildrenBd_bore_7_ack),
    .boreChildrenBd_bore_7_writeen (boreChildrenBd_bore_7_writeen),
    .boreChildrenBd_bore_7_be (boreChildrenBd_bore_7_be),
    .boreChildrenBd_bore_7_addr (boreChildrenBd_bore_7_addr),
    .boreChildrenBd_bore_7_indata (boreChildrenBd_bore_7_indata),
    .boreChildrenBd_bore_7_readen (boreChildrenBd_bore_7_readen),
    .boreChildrenBd_bore_7_addr_rd (boreChildrenBd_bore_7_addr_rd),
    .boreChildrenBd_bore_7_outdata (i_boreChildrenBd_bore_7_outdata),
    .boreChildrenBd_bore_8_array (boreChildrenBd_bore_8_array),
    .boreChildrenBd_bore_8_all (boreChildrenBd_bore_8_all),
    .boreChildrenBd_bore_8_req (boreChildrenBd_bore_8_req),
    .boreChildrenBd_bore_8_ack (i_boreChildrenBd_bore_8_ack),
    .boreChildrenBd_bore_8_writeen (boreChildrenBd_bore_8_writeen),
    .boreChildrenBd_bore_8_be (boreChildrenBd_bore_8_be),
    .boreChildrenBd_bore_8_addr (boreChildrenBd_bore_8_addr),
    .boreChildrenBd_bore_8_indata (boreChildrenBd_bore_8_indata),
    .boreChildrenBd_bore_8_readen (boreChildrenBd_bore_8_readen),
    .boreChildrenBd_bore_8_addr_rd (boreChildrenBd_bore_8_addr_rd),
    .boreChildrenBd_bore_8_outdata (i_boreChildrenBd_bore_8_outdata),
    .boreChildrenBd_bore_9_array (boreChildrenBd_bore_9_array),
    .boreChildrenBd_bore_9_all (boreChildrenBd_bore_9_all),
    .boreChildrenBd_bore_9_req (boreChildrenBd_bore_9_req),
    .boreChildrenBd_bore_9_ack (i_boreChildrenBd_bore_9_ack),
    .boreChildrenBd_bore_9_writeen (boreChildrenBd_bore_9_writeen),
    .boreChildrenBd_bore_9_be (boreChildrenBd_bore_9_be),
    .boreChildrenBd_bore_9_addr (boreChildrenBd_bore_9_addr),
    .boreChildrenBd_bore_9_indata (boreChildrenBd_bore_9_indata),
    .boreChildrenBd_bore_9_readen (boreChildrenBd_bore_9_readen),
    .boreChildrenBd_bore_9_addr_rd (boreChildrenBd_bore_9_addr_rd),
    .boreChildrenBd_bore_9_outdata (i_boreChildrenBd_bore_9_outdata),
    .boreChildrenBd_bore_10_array (boreChildrenBd_bore_10_array),
    .boreChildrenBd_bore_10_all (boreChildrenBd_bore_10_all),
    .boreChildrenBd_bore_10_req (boreChildrenBd_bore_10_req),
    .boreChildrenBd_bore_10_ack (i_boreChildrenBd_bore_10_ack),
    .boreChildrenBd_bore_10_writeen (boreChildrenBd_bore_10_writeen),
    .boreChildrenBd_bore_10_be (boreChildrenBd_bore_10_be),
    .boreChildrenBd_bore_10_addr (boreChildrenBd_bore_10_addr),
    .boreChildrenBd_bore_10_indata (boreChildrenBd_bore_10_indata),
    .boreChildrenBd_bore_10_readen (boreChildrenBd_bore_10_readen),
    .boreChildrenBd_bore_10_addr_rd (boreChildrenBd_bore_10_addr_rd),
    .boreChildrenBd_bore_10_outdata (i_boreChildrenBd_bore_10_outdata),
    .sigFromSrams_bore_ram_hold (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen (sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen (sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen (sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold (sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass (sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken (sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk (sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp (sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold (sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen (sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold (sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass (sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken (sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk (sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp (sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold (sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen (sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold (sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass (sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken (sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk (sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp (sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold (sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen (sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold (sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass (sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken (sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk (sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp (sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold (sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen (sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold (sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass (sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken (sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk (sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp (sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold (sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen (sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold (sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass (sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken (sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk (sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp (sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold (sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen (sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold (sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass (sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken (sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk (sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp (sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold (sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen (sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_11_ram_hold (sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_11_ram_bypass (sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken (sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk (sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp (sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold (sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen (sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_12_ram_hold (sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_12_ram_bypass (sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken (sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk (sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp (sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold (sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen (sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_13_ram_hold (sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_13_ram_bypass (sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken (sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk (sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp (sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold (sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen (sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_14_ram_hold (sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_14_ram_bypass (sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken (sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk (sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp (sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold (sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen (sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_15_ram_hold (sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_15_ram_bypass (sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken (sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk (sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp (sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold (sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen (sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_16_ram_hold (sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_16_ram_bypass (sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken (sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk (sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp (sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold (sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen (sigFromSrams_bore_16_cgen),
    .sigFromSrams_bore_17_ram_hold (sigFromSrams_bore_17_ram_hold),
    .sigFromSrams_bore_17_ram_bypass (sigFromSrams_bore_17_ram_bypass),
    .sigFromSrams_bore_17_ram_bp_clken (sigFromSrams_bore_17_ram_bp_clken),
    .sigFromSrams_bore_17_ram_aux_clk (sigFromSrams_bore_17_ram_aux_clk),
    .sigFromSrams_bore_17_ram_aux_ckbp (sigFromSrams_bore_17_ram_aux_ckbp),
    .sigFromSrams_bore_17_ram_mcp_hold (sigFromSrams_bore_17_ram_mcp_hold),
    .sigFromSrams_bore_17_cgen (sigFromSrams_bore_17_cgen),
    .sigFromSrams_bore_18_ram_hold (sigFromSrams_bore_18_ram_hold),
    .sigFromSrams_bore_18_ram_bypass (sigFromSrams_bore_18_ram_bypass),
    .sigFromSrams_bore_18_ram_bp_clken (sigFromSrams_bore_18_ram_bp_clken),
    .sigFromSrams_bore_18_ram_aux_clk (sigFromSrams_bore_18_ram_aux_clk),
    .sigFromSrams_bore_18_ram_aux_ckbp (sigFromSrams_bore_18_ram_aux_ckbp),
    .sigFromSrams_bore_18_ram_mcp_hold (sigFromSrams_bore_18_ram_mcp_hold),
    .sigFromSrams_bore_18_cgen (sigFromSrams_bore_18_cgen),
    .sigFromSrams_bore_19_ram_hold (sigFromSrams_bore_19_ram_hold),
    .sigFromSrams_bore_19_ram_bypass (sigFromSrams_bore_19_ram_bypass),
    .sigFromSrams_bore_19_ram_bp_clken (sigFromSrams_bore_19_ram_bp_clken),
    .sigFromSrams_bore_19_ram_aux_clk (sigFromSrams_bore_19_ram_aux_clk),
    .sigFromSrams_bore_19_ram_aux_ckbp (sigFromSrams_bore_19_ram_aux_ckbp),
    .sigFromSrams_bore_19_ram_mcp_hold (sigFromSrams_bore_19_ram_mcp_hold),
    .sigFromSrams_bore_19_cgen (sigFromSrams_bore_19_cgen),
    .sigFromSrams_bore_20_ram_hold (sigFromSrams_bore_20_ram_hold),
    .sigFromSrams_bore_20_ram_bypass (sigFromSrams_bore_20_ram_bypass),
    .sigFromSrams_bore_20_ram_bp_clken (sigFromSrams_bore_20_ram_bp_clken),
    .sigFromSrams_bore_20_ram_aux_clk (sigFromSrams_bore_20_ram_aux_clk),
    .sigFromSrams_bore_20_ram_aux_ckbp (sigFromSrams_bore_20_ram_aux_ckbp),
    .sigFromSrams_bore_20_ram_mcp_hold (sigFromSrams_bore_20_ram_mcp_hold),
    .sigFromSrams_bore_20_cgen (sigFromSrams_bore_20_cgen),
    .sigFromSrams_bore_21_ram_hold (sigFromSrams_bore_21_ram_hold),
    .sigFromSrams_bore_21_ram_bypass (sigFromSrams_bore_21_ram_bypass),
    .sigFromSrams_bore_21_ram_bp_clken (sigFromSrams_bore_21_ram_bp_clken),
    .sigFromSrams_bore_21_ram_aux_clk (sigFromSrams_bore_21_ram_aux_clk),
    .sigFromSrams_bore_21_ram_aux_ckbp (sigFromSrams_bore_21_ram_aux_ckbp),
    .sigFromSrams_bore_21_ram_mcp_hold (sigFromSrams_bore_21_ram_mcp_hold),
    .sigFromSrams_bore_21_cgen (sigFromSrams_bore_21_cgen),
    .sigFromSrams_bore_22_ram_hold (sigFromSrams_bore_22_ram_hold),
    .sigFromSrams_bore_22_ram_bypass (sigFromSrams_bore_22_ram_bypass),
    .sigFromSrams_bore_22_ram_bp_clken (sigFromSrams_bore_22_ram_bp_clken),
    .sigFromSrams_bore_22_ram_aux_clk (sigFromSrams_bore_22_ram_aux_clk),
    .sigFromSrams_bore_22_ram_aux_ckbp (sigFromSrams_bore_22_ram_aux_ckbp),
    .sigFromSrams_bore_22_ram_mcp_hold (sigFromSrams_bore_22_ram_mcp_hold),
    .sigFromSrams_bore_22_cgen (sigFromSrams_bore_22_cgen),
    .sigFromSrams_bore_23_ram_hold (sigFromSrams_bore_23_ram_hold),
    .sigFromSrams_bore_23_ram_bypass (sigFromSrams_bore_23_ram_bypass),
    .sigFromSrams_bore_23_ram_bp_clken (sigFromSrams_bore_23_ram_bp_clken),
    .sigFromSrams_bore_23_ram_aux_clk (sigFromSrams_bore_23_ram_aux_clk),
    .sigFromSrams_bore_23_ram_aux_ckbp (sigFromSrams_bore_23_ram_aux_ckbp),
    .sigFromSrams_bore_23_ram_mcp_hold (sigFromSrams_bore_23_ram_mcp_hold),
    .sigFromSrams_bore_23_cgen (sigFromSrams_bore_23_cgen),
    .sigFromSrams_bore_24_ram_hold (sigFromSrams_bore_24_ram_hold),
    .sigFromSrams_bore_24_ram_bypass (sigFromSrams_bore_24_ram_bypass),
    .sigFromSrams_bore_24_ram_bp_clken (sigFromSrams_bore_24_ram_bp_clken),
    .sigFromSrams_bore_24_ram_aux_clk (sigFromSrams_bore_24_ram_aux_clk),
    .sigFromSrams_bore_24_ram_aux_ckbp (sigFromSrams_bore_24_ram_aux_ckbp),
    .sigFromSrams_bore_24_ram_mcp_hold (sigFromSrams_bore_24_ram_mcp_hold),
    .sigFromSrams_bore_24_cgen (sigFromSrams_bore_24_cgen),
    .sigFromSrams_bore_25_ram_hold (sigFromSrams_bore_25_ram_hold),
    .sigFromSrams_bore_25_ram_bypass (sigFromSrams_bore_25_ram_bypass),
    .sigFromSrams_bore_25_ram_bp_clken (sigFromSrams_bore_25_ram_bp_clken),
    .sigFromSrams_bore_25_ram_aux_clk (sigFromSrams_bore_25_ram_aux_clk),
    .sigFromSrams_bore_25_ram_aux_ckbp (sigFromSrams_bore_25_ram_aux_ckbp),
    .sigFromSrams_bore_25_ram_mcp_hold (sigFromSrams_bore_25_ram_mcp_hold),
    .sigFromSrams_bore_25_cgen (sigFromSrams_bore_25_cgen),
    .sigFromSrams_bore_26_ram_hold (sigFromSrams_bore_26_ram_hold),
    .sigFromSrams_bore_26_ram_bypass (sigFromSrams_bore_26_ram_bypass),
    .sigFromSrams_bore_26_ram_bp_clken (sigFromSrams_bore_26_ram_bp_clken),
    .sigFromSrams_bore_26_ram_aux_clk (sigFromSrams_bore_26_ram_aux_clk),
    .sigFromSrams_bore_26_ram_aux_ckbp (sigFromSrams_bore_26_ram_aux_ckbp),
    .sigFromSrams_bore_26_ram_mcp_hold (sigFromSrams_bore_26_ram_mcp_hold),
    .sigFromSrams_bore_26_cgen (sigFromSrams_bore_26_cgen),
    .sigFromSrams_bore_27_ram_hold (sigFromSrams_bore_27_ram_hold),
    .sigFromSrams_bore_27_ram_bypass (sigFromSrams_bore_27_ram_bypass),
    .sigFromSrams_bore_27_ram_bp_clken (sigFromSrams_bore_27_ram_bp_clken),
    .sigFromSrams_bore_27_ram_aux_clk (sigFromSrams_bore_27_ram_aux_clk),
    .sigFromSrams_bore_27_ram_aux_ckbp (sigFromSrams_bore_27_ram_aux_ckbp),
    .sigFromSrams_bore_27_ram_mcp_hold (sigFromSrams_bore_27_ram_mcp_hold),
    .sigFromSrams_bore_27_cgen (sigFromSrams_bore_27_cgen),
    .sigFromSrams_bore_28_ram_hold (sigFromSrams_bore_28_ram_hold),
    .sigFromSrams_bore_28_ram_bypass (sigFromSrams_bore_28_ram_bypass),
    .sigFromSrams_bore_28_ram_bp_clken (sigFromSrams_bore_28_ram_bp_clken),
    .sigFromSrams_bore_28_ram_aux_clk (sigFromSrams_bore_28_ram_aux_clk),
    .sigFromSrams_bore_28_ram_aux_ckbp (sigFromSrams_bore_28_ram_aux_ckbp),
    .sigFromSrams_bore_28_ram_mcp_hold (sigFromSrams_bore_28_ram_mcp_hold),
    .sigFromSrams_bore_28_cgen (sigFromSrams_bore_28_cgen),
    .sigFromSrams_bore_29_ram_hold (sigFromSrams_bore_29_ram_hold),
    .sigFromSrams_bore_29_ram_bypass (sigFromSrams_bore_29_ram_bypass),
    .sigFromSrams_bore_29_ram_bp_clken (sigFromSrams_bore_29_ram_bp_clken),
    .sigFromSrams_bore_29_ram_aux_clk (sigFromSrams_bore_29_ram_aux_clk),
    .sigFromSrams_bore_29_ram_aux_ckbp (sigFromSrams_bore_29_ram_aux_ckbp),
    .sigFromSrams_bore_29_ram_mcp_hold (sigFromSrams_bore_29_ram_mcp_hold),
    .sigFromSrams_bore_29_cgen (sigFromSrams_bore_29_cgen),
    .sigFromSrams_bore_30_ram_hold (sigFromSrams_bore_30_ram_hold),
    .sigFromSrams_bore_30_ram_bypass (sigFromSrams_bore_30_ram_bypass),
    .sigFromSrams_bore_30_ram_bp_clken (sigFromSrams_bore_30_ram_bp_clken),
    .sigFromSrams_bore_30_ram_aux_clk (sigFromSrams_bore_30_ram_aux_clk),
    .sigFromSrams_bore_30_ram_aux_ckbp (sigFromSrams_bore_30_ram_aux_ckbp),
    .sigFromSrams_bore_30_ram_mcp_hold (sigFromSrams_bore_30_ram_mcp_hold),
    .sigFromSrams_bore_30_cgen (sigFromSrams_bore_30_cgen),
    .sigFromSrams_bore_31_ram_hold (sigFromSrams_bore_31_ram_hold),
    .sigFromSrams_bore_31_ram_bypass (sigFromSrams_bore_31_ram_bypass),
    .sigFromSrams_bore_31_ram_bp_clken (sigFromSrams_bore_31_ram_bp_clken),
    .sigFromSrams_bore_31_ram_aux_clk (sigFromSrams_bore_31_ram_aux_clk),
    .sigFromSrams_bore_31_ram_aux_ckbp (sigFromSrams_bore_31_ram_aux_ckbp),
    .sigFromSrams_bore_31_ram_mcp_hold (sigFromSrams_bore_31_ram_mcp_hold),
    .sigFromSrams_bore_31_cgen (sigFromSrams_bore_31_cgen),
    .sigFromSrams_bore_32_ram_hold (sigFromSrams_bore_32_ram_hold),
    .sigFromSrams_bore_32_ram_bypass (sigFromSrams_bore_32_ram_bypass),
    .sigFromSrams_bore_32_ram_bp_clken (sigFromSrams_bore_32_ram_bp_clken),
    .sigFromSrams_bore_32_ram_aux_clk (sigFromSrams_bore_32_ram_aux_clk),
    .sigFromSrams_bore_32_ram_aux_ckbp (sigFromSrams_bore_32_ram_aux_ckbp),
    .sigFromSrams_bore_32_ram_mcp_hold (sigFromSrams_bore_32_ram_mcp_hold),
    .sigFromSrams_bore_32_cgen (sigFromSrams_bore_32_cgen),
    .sigFromSrams_bore_33_ram_hold (sigFromSrams_bore_33_ram_hold),
    .sigFromSrams_bore_33_ram_bypass (sigFromSrams_bore_33_ram_bypass),
    .sigFromSrams_bore_33_ram_bp_clken (sigFromSrams_bore_33_ram_bp_clken),
    .sigFromSrams_bore_33_ram_aux_clk (sigFromSrams_bore_33_ram_aux_clk),
    .sigFromSrams_bore_33_ram_aux_ckbp (sigFromSrams_bore_33_ram_aux_ckbp),
    .sigFromSrams_bore_33_ram_mcp_hold (sigFromSrams_bore_33_ram_mcp_hold),
    .sigFromSrams_bore_33_cgen (sigFromSrams_bore_33_cgen),
    .sigFromSrams_bore_34_ram_hold (sigFromSrams_bore_34_ram_hold),
    .sigFromSrams_bore_34_ram_bypass (sigFromSrams_bore_34_ram_bypass),
    .sigFromSrams_bore_34_ram_bp_clken (sigFromSrams_bore_34_ram_bp_clken),
    .sigFromSrams_bore_34_ram_aux_clk (sigFromSrams_bore_34_ram_aux_clk),
    .sigFromSrams_bore_34_ram_aux_ckbp (sigFromSrams_bore_34_ram_aux_ckbp),
    .sigFromSrams_bore_34_ram_mcp_hold (sigFromSrams_bore_34_ram_mcp_hold),
    .sigFromSrams_bore_34_cgen (sigFromSrams_bore_34_cgen),
    .sigFromSrams_bore_35_ram_hold (sigFromSrams_bore_35_ram_hold),
    .sigFromSrams_bore_35_ram_bypass (sigFromSrams_bore_35_ram_bypass),
    .sigFromSrams_bore_35_ram_bp_clken (sigFromSrams_bore_35_ram_bp_clken),
    .sigFromSrams_bore_35_ram_aux_clk (sigFromSrams_bore_35_ram_aux_clk),
    .sigFromSrams_bore_35_ram_aux_ckbp (sigFromSrams_bore_35_ram_aux_ckbp),
    .sigFromSrams_bore_35_ram_mcp_hold (sigFromSrams_bore_35_ram_mcp_hold),
    .sigFromSrams_bore_35_cgen (sigFromSrams_bore_35_cgen),
    .sigFromSrams_bore_36_ram_hold (sigFromSrams_bore_36_ram_hold),
    .sigFromSrams_bore_36_ram_bypass (sigFromSrams_bore_36_ram_bypass),
    .sigFromSrams_bore_36_ram_bp_clken (sigFromSrams_bore_36_ram_bp_clken),
    .sigFromSrams_bore_36_ram_aux_clk (sigFromSrams_bore_36_ram_aux_clk),
    .sigFromSrams_bore_36_ram_aux_ckbp (sigFromSrams_bore_36_ram_aux_ckbp),
    .sigFromSrams_bore_36_ram_mcp_hold (sigFromSrams_bore_36_ram_mcp_hold),
    .sigFromSrams_bore_36_cgen (sigFromSrams_bore_36_cgen),
    .sigFromSrams_bore_37_ram_hold (sigFromSrams_bore_37_ram_hold),
    .sigFromSrams_bore_37_ram_bypass (sigFromSrams_bore_37_ram_bypass),
    .sigFromSrams_bore_37_ram_bp_clken (sigFromSrams_bore_37_ram_bp_clken),
    .sigFromSrams_bore_37_ram_aux_clk (sigFromSrams_bore_37_ram_aux_clk),
    .sigFromSrams_bore_37_ram_aux_ckbp (sigFromSrams_bore_37_ram_aux_ckbp),
    .sigFromSrams_bore_37_ram_mcp_hold (sigFromSrams_bore_37_ram_mcp_hold),
    .sigFromSrams_bore_37_cgen (sigFromSrams_bore_37_cgen),
    .sigFromSrams_bore_38_ram_hold (sigFromSrams_bore_38_ram_hold),
    .sigFromSrams_bore_38_ram_bypass (sigFromSrams_bore_38_ram_bypass),
    .sigFromSrams_bore_38_ram_bp_clken (sigFromSrams_bore_38_ram_bp_clken),
    .sigFromSrams_bore_38_ram_aux_clk (sigFromSrams_bore_38_ram_aux_clk),
    .sigFromSrams_bore_38_ram_aux_ckbp (sigFromSrams_bore_38_ram_aux_ckbp),
    .sigFromSrams_bore_38_ram_mcp_hold (sigFromSrams_bore_38_ram_mcp_hold),
    .sigFromSrams_bore_38_cgen (sigFromSrams_bore_38_cgen),
    .sigFromSrams_bore_39_ram_hold (sigFromSrams_bore_39_ram_hold),
    .sigFromSrams_bore_39_ram_bypass (sigFromSrams_bore_39_ram_bypass),
    .sigFromSrams_bore_39_ram_bp_clken (sigFromSrams_bore_39_ram_bp_clken),
    .sigFromSrams_bore_39_ram_aux_clk (sigFromSrams_bore_39_ram_aux_clk),
    .sigFromSrams_bore_39_ram_aux_ckbp (sigFromSrams_bore_39_ram_aux_ckbp),
    .sigFromSrams_bore_39_ram_mcp_hold (sigFromSrams_bore_39_ram_mcp_hold),
    .sigFromSrams_bore_39_cgen (sigFromSrams_bore_39_cgen),
    .sigFromSrams_bore_40_ram_hold (sigFromSrams_bore_40_ram_hold),
    .sigFromSrams_bore_40_ram_bypass (sigFromSrams_bore_40_ram_bypass),
    .sigFromSrams_bore_40_ram_bp_clken (sigFromSrams_bore_40_ram_bp_clken),
    .sigFromSrams_bore_40_ram_aux_clk (sigFromSrams_bore_40_ram_aux_clk),
    .sigFromSrams_bore_40_ram_aux_ckbp (sigFromSrams_bore_40_ram_aux_ckbp),
    .sigFromSrams_bore_40_ram_mcp_hold (sigFromSrams_bore_40_ram_mcp_hold),
    .sigFromSrams_bore_40_cgen (sigFromSrams_bore_40_cgen),
    .sigFromSrams_bore_41_ram_hold (sigFromSrams_bore_41_ram_hold),
    .sigFromSrams_bore_41_ram_bypass (sigFromSrams_bore_41_ram_bypass),
    .sigFromSrams_bore_41_ram_bp_clken (sigFromSrams_bore_41_ram_bp_clken),
    .sigFromSrams_bore_41_ram_aux_clk (sigFromSrams_bore_41_ram_aux_clk),
    .sigFromSrams_bore_41_ram_aux_ckbp (sigFromSrams_bore_41_ram_aux_ckbp),
    .sigFromSrams_bore_41_ram_mcp_hold (sigFromSrams_bore_41_ram_mcp_hold),
    .sigFromSrams_bore_41_cgen (sigFromSrams_bore_41_cgen),
    .sigFromSrams_bore_42_ram_hold (sigFromSrams_bore_42_ram_hold),
    .sigFromSrams_bore_42_ram_bypass (sigFromSrams_bore_42_ram_bypass),
    .sigFromSrams_bore_42_ram_bp_clken (sigFromSrams_bore_42_ram_bp_clken),
    .sigFromSrams_bore_42_ram_aux_clk (sigFromSrams_bore_42_ram_aux_clk),
    .sigFromSrams_bore_42_ram_aux_ckbp (sigFromSrams_bore_42_ram_aux_ckbp),
    .sigFromSrams_bore_42_ram_mcp_hold (sigFromSrams_bore_42_ram_mcp_hold),
    .sigFromSrams_bore_42_cgen (sigFromSrams_bore_42_cgen),
    .sigFromSrams_bore_43_ram_hold (sigFromSrams_bore_43_ram_hold),
    .sigFromSrams_bore_43_ram_bypass (sigFromSrams_bore_43_ram_bypass),
    .sigFromSrams_bore_43_ram_bp_clken (sigFromSrams_bore_43_ram_bp_clken),
    .sigFromSrams_bore_43_ram_aux_clk (sigFromSrams_bore_43_ram_aux_clk),
    .sigFromSrams_bore_43_ram_aux_ckbp (sigFromSrams_bore_43_ram_aux_ckbp),
    .sigFromSrams_bore_43_ram_mcp_hold (sigFromSrams_bore_43_ram_mcp_hold),
    .sigFromSrams_bore_43_cgen (sigFromSrams_bore_43_cgen),
    .sigFromSrams_bore_44_ram_hold (sigFromSrams_bore_44_ram_hold),
    .sigFromSrams_bore_44_ram_bypass (sigFromSrams_bore_44_ram_bypass),
    .sigFromSrams_bore_44_ram_bp_clken (sigFromSrams_bore_44_ram_bp_clken),
    .sigFromSrams_bore_44_ram_aux_clk (sigFromSrams_bore_44_ram_aux_clk),
    .sigFromSrams_bore_44_ram_aux_ckbp (sigFromSrams_bore_44_ram_aux_ckbp),
    .sigFromSrams_bore_44_ram_mcp_hold (sigFromSrams_bore_44_ram_mcp_hold),
    .sigFromSrams_bore_44_cgen (sigFromSrams_bore_44_cgen),
    .sigFromSrams_bore_45_ram_hold (sigFromSrams_bore_45_ram_hold),
    .sigFromSrams_bore_45_ram_bypass (sigFromSrams_bore_45_ram_bypass),
    .sigFromSrams_bore_45_ram_bp_clken (sigFromSrams_bore_45_ram_bp_clken),
    .sigFromSrams_bore_45_ram_aux_clk (sigFromSrams_bore_45_ram_aux_clk),
    .sigFromSrams_bore_45_ram_aux_ckbp (sigFromSrams_bore_45_ram_aux_ckbp),
    .sigFromSrams_bore_45_ram_mcp_hold (sigFromSrams_bore_45_ram_mcp_hold),
    .sigFromSrams_bore_45_cgen (sigFromSrams_bore_45_cgen),
    .sigFromSrams_bore_46_ram_hold (sigFromSrams_bore_46_ram_hold),
    .sigFromSrams_bore_46_ram_bypass (sigFromSrams_bore_46_ram_bypass),
    .sigFromSrams_bore_46_ram_bp_clken (sigFromSrams_bore_46_ram_bp_clken),
    .sigFromSrams_bore_46_ram_aux_clk (sigFromSrams_bore_46_ram_aux_clk),
    .sigFromSrams_bore_46_ram_aux_ckbp (sigFromSrams_bore_46_ram_aux_ckbp),
    .sigFromSrams_bore_46_ram_mcp_hold (sigFromSrams_bore_46_ram_mcp_hold),
    .sigFromSrams_bore_46_cgen (sigFromSrams_bore_46_cgen),
    .sigFromSrams_bore_47_ram_hold (sigFromSrams_bore_47_ram_hold),
    .sigFromSrams_bore_47_ram_bypass (sigFromSrams_bore_47_ram_bypass),
    .sigFromSrams_bore_47_ram_bp_clken (sigFromSrams_bore_47_ram_bp_clken),
    .sigFromSrams_bore_47_ram_aux_clk (sigFromSrams_bore_47_ram_aux_clk),
    .sigFromSrams_bore_47_ram_aux_ckbp (sigFromSrams_bore_47_ram_aux_ckbp),
    .sigFromSrams_bore_47_ram_mcp_hold (sigFromSrams_bore_47_ram_mcp_hold),
    .sigFromSrams_bore_47_cgen (sigFromSrams_bore_47_cgen)
  );

  // 宽端口随机填充：$urandom 一次 32 位，按位宽拼够。
  function automatic logic [1023:0] rnd(input int w);
    logic [1023:0] v;
    v = 1024'b0;
    for (int k = 0; k < (w + 31) / 32; k++) v[k*32 +: 32] = $urandom();
    return v;
  endfunction

  // s0_pc 的"基址 + 小步"驱动：大多数拍只动低 12 位（高两段不变 ->
  // SegmentedAddrNext 走"没变"分支），偶尔整段跳（走"变了"分支）。
  logic [49:0] pc_base = 50'h0;

  logic [1023:0] rtmp;
  task automatic drive_random_inputs();
    rtmp = rnd(50);
    if ($urandom_range(0, 63) == 0) begin
      pc_base = rtmp[49:0];
    end
    else if ($urandom_range(0, 15) == 0 &&
             !$isunknown(g_dut.s2_pc_dup_s2_pc_seg_0_value)) begin
      // 定向：让 pc[48:23] 恰好等于当前 s2 高段存值。这样"高段比较"若误取
      // [48:23] 就会判成"没变"而漏掉一次更新 —— 随机激励撞不到这种巧合，
      // 只能这样构造（阴性对照里 M4 就是靠它才被抓住的）。
      pc_base = {~g_dut.s2_pc_dup_s2_pc_seg_0_value[25],
                 g_dut.s2_pc_dup_s2_pc_seg_0_value, rtmp[22:0]};
      seg_hi_trap++;
    end
    else                            pc_base = {pc_base[49:12], rtmp[11:0]};
    rtmp = rnd(2);
    io_in_bits_s0_pc_0 = pc_base ^ {48'h0, rtmp[1:0]};
    rtmp = rnd(2);
    io_in_bits_s0_pc_1 = pc_base ^ {48'h0, rtmp[1:0]};
    rtmp = rnd(2);
    io_in_bits_s0_pc_2 = pc_base ^ {48'h0, rtmp[1:0]};
    rtmp = rnd(2);
    io_in_bits_s0_pc_3 = pc_base ^ {48'h0, rtmp[1:0]};
    // ctrl 开关大多数时候打开，让各预测器真的在跑
    io_ctrl_ubtb_enable = ($urandom_range(0, 9) != 0);
    io_ctrl_btb_enable = ($urandom_range(0, 9) != 0);
    io_ctrl_tage_enable = ($urandom_range(0, 9) != 0);
    io_ctrl_sc_enable = ($urandom_range(0, 9) != 0);
    io_ctrl_ras_enable = ($urandom_range(0, 9) != 0);
    io_reset_vector = rnd(48);
    io_in_bits_folded_hist_1_hist_17_folded_hist = rnd(11);
    io_in_bits_folded_hist_1_hist_16_folded_hist = rnd(11);
    io_in_bits_folded_hist_1_hist_15_folded_hist = rnd(7);
    io_in_bits_folded_hist_1_hist_14_folded_hist = rnd(8);
    io_in_bits_folded_hist_1_hist_9_folded_hist = rnd(7);
    io_in_bits_folded_hist_1_hist_8_folded_hist = rnd(8);
    io_in_bits_folded_hist_1_hist_7_folded_hist = rnd(7);
    io_in_bits_folded_hist_1_hist_5_folded_hist = rnd(7);
    io_in_bits_folded_hist_1_hist_4_folded_hist = rnd(8);
    io_in_bits_folded_hist_1_hist_3_folded_hist = rnd(8);
    io_in_bits_folded_hist_1_hist_1_folded_hist = rnd(11);
    io_in_bits_folded_hist_3_hist_12_folded_hist = rnd(4);
    io_in_bits_folded_hist_3_hist_11_folded_hist = rnd(8);
    io_in_bits_folded_hist_3_hist_2_folded_hist = rnd(8);
    io_in_bits_s1_folded_hist_3_hist_14_folded_hist = rnd(8);
    io_in_bits_s1_folded_hist_3_hist_13_folded_hist = rnd(9);
    io_in_bits_s1_folded_hist_3_hist_12_folded_hist = rnd(4);
    io_in_bits_s1_folded_hist_3_hist_10_folded_hist = rnd(9);
    io_in_bits_s1_folded_hist_3_hist_6_folded_hist = rnd(9);
    io_in_bits_s1_folded_hist_3_hist_4_folded_hist = rnd(8);
    io_in_bits_s1_folded_hist_3_hist_3_folded_hist = rnd(8);
    io_in_bits_s1_folded_hist_3_hist_2_folded_hist = rnd(8);
    io_in_bits_ghist = rnd(256);
    io_s0_fire_0 = rnd(1);
    io_s0_fire_1 = rnd(1);
    io_s0_fire_2 = rnd(1);
    io_s0_fire_3 = rnd(1);
    io_s1_fire_0 = rnd(1);
    io_s1_fire_1 = rnd(1);
    io_s1_fire_2 = rnd(1);
    io_s1_fire_3 = rnd(1);
    io_s2_fire_0 = rnd(1);
    io_s2_fire_1 = rnd(1);
    io_s2_fire_2 = rnd(1);
    io_s2_fire_3 = rnd(1);
    io_s3_fire_0 = rnd(1);
    io_s3_fire_2 = rnd(1);
    io_s3_redirect_2 = rnd(1);
    io_update_valid = rnd(1);
    io_update_bits_pc = rnd(50);
    io_update_bits_ftb_entry_isCall = rnd(1);
    io_update_bits_ftb_entry_isRet = rnd(1);
    io_update_bits_ftb_entry_isJalr = rnd(1);
    io_update_bits_ftb_entry_valid = rnd(1);
    io_update_bits_ftb_entry_brSlots_0_offset = rnd(4);
    io_update_bits_ftb_entry_brSlots_0_sharing = rnd(1);
    io_update_bits_ftb_entry_brSlots_0_valid = rnd(1);
    io_update_bits_ftb_entry_brSlots_0_lower = rnd(12);
    io_update_bits_ftb_entry_brSlots_0_tarStat = rnd(2);
    io_update_bits_ftb_entry_tailSlot_offset = rnd(4);
    io_update_bits_ftb_entry_tailSlot_sharing = rnd(1);
    io_update_bits_ftb_entry_tailSlot_valid = rnd(1);
    io_update_bits_ftb_entry_tailSlot_lower = rnd(20);
    io_update_bits_ftb_entry_tailSlot_tarStat = rnd(2);
    io_update_bits_ftb_entry_pftAddr = rnd(4);
    io_update_bits_ftb_entry_carry = rnd(1);
    io_update_bits_ftb_entry_last_may_be_rvi_call = rnd(1);
    io_update_bits_ftb_entry_strong_bias_0 = rnd(1);
    io_update_bits_ftb_entry_strong_bias_1 = rnd(1);
    io_update_bits_cfi_idx_valid = rnd(1);
    io_update_bits_cfi_idx_bits = rnd(4);
    io_update_bits_br_taken_mask_0 = rnd(1);
    io_update_bits_br_taken_mask_1 = rnd(1);
    io_update_bits_jmp_taken = rnd(1);
    io_update_bits_mispred_mask_0 = rnd(1);
    io_update_bits_mispred_mask_1 = rnd(1);
    io_update_bits_mispred_mask_2 = rnd(1);
    io_update_bits_false_hit = rnd(1);
    io_update_bits_old_entry = rnd(1);
    io_update_bits_meta = rnd(516);
    io_update_bits_full_target = rnd(50);
    io_update_bits_ghist = rnd(256);
    io_redirect_valid = rnd(1);
    io_redirect_bits_level = rnd(1);
    io_redirect_bits_cfiUpdate_pc = rnd(50);
    io_redirect_bits_cfiUpdate_pd_valid = rnd(1);
    io_redirect_bits_cfiUpdate_pd_isRVC = rnd(1);
    io_redirect_bits_cfiUpdate_pd_isCall = rnd(1);
    io_redirect_bits_cfiUpdate_pd_isRet = rnd(1);
    io_redirect_bits_cfiUpdate_ssp = rnd(4);
    io_redirect_bits_cfiUpdate_sctr = rnd(3);
    io_redirect_bits_cfiUpdate_TOSW_flag = rnd(1);
    io_redirect_bits_cfiUpdate_TOSW_value = rnd(5);
    io_redirect_bits_cfiUpdate_TOSR_flag = rnd(1);
    io_redirect_bits_cfiUpdate_TOSR_value = rnd(5);
    io_redirect_bits_cfiUpdate_NOS_flag = rnd(1);
    io_redirect_bits_cfiUpdate_NOS_value = rnd(5);
    io_redirectFromIFU = rnd(1);
    boreChildrenBd_bore_array = rnd(6);
    boreChildrenBd_bore_all = rnd(1);
    boreChildrenBd_bore_req = rnd(1);
    boreChildrenBd_bore_writeen = rnd(1);
    boreChildrenBd_bore_be = rnd(4);
    boreChildrenBd_bore_addr = rnd(10);
    boreChildrenBd_bore_indata = rnd(40);
    boreChildrenBd_bore_readen = rnd(1);
    boreChildrenBd_bore_addr_rd = rnd(10);
    boreChildrenBd_bore_1_array = rnd(7);
    boreChildrenBd_bore_1_all = rnd(1);
    boreChildrenBd_bore_1_req = rnd(1);
    boreChildrenBd_bore_1_writeen = rnd(1);
    boreChildrenBd_bore_1_be = rnd(16);
    boreChildrenBd_bore_1_addr = rnd(10);
    boreChildrenBd_bore_1_indata = rnd(24);
    boreChildrenBd_bore_1_readen = rnd(1);
    boreChildrenBd_bore_1_addr_rd = rnd(10);
    boreChildrenBd_bore_2_array = rnd(7);
    boreChildrenBd_bore_2_all = rnd(1);
    boreChildrenBd_bore_2_req = rnd(1);
    boreChildrenBd_bore_2_writeen = rnd(1);
    boreChildrenBd_bore_2_be = rnd(4);
    boreChildrenBd_bore_2_addr = rnd(8);
    boreChildrenBd_bore_2_indata = rnd(24);
    boreChildrenBd_bore_2_readen = rnd(1);
    boreChildrenBd_bore_2_addr_rd = rnd(8);
    boreChildrenBd_bore_3_array = rnd(7);
    boreChildrenBd_bore_3_all = rnd(1);
    boreChildrenBd_bore_3_req = rnd(1);
    boreChildrenBd_bore_3_writeen = rnd(1);
    boreChildrenBd_bore_3_be = rnd(4);
    boreChildrenBd_bore_3_addr = rnd(8);
    boreChildrenBd_bore_3_indata = rnd(24);
    boreChildrenBd_bore_3_readen = rnd(1);
    boreChildrenBd_bore_3_addr_rd = rnd(8);
    boreChildrenBd_bore_4_array = rnd(7);
    boreChildrenBd_bore_4_all = rnd(1);
    boreChildrenBd_bore_4_req = rnd(1);
    boreChildrenBd_bore_4_writeen = rnd(1);
    boreChildrenBd_bore_4_be = rnd(4);
    boreChildrenBd_bore_4_addr = rnd(8);
    boreChildrenBd_bore_4_indata = rnd(24);
    boreChildrenBd_bore_4_readen = rnd(1);
    boreChildrenBd_bore_4_addr_rd = rnd(8);
    boreChildrenBd_bore_5_array = rnd(7);
    boreChildrenBd_bore_5_all = rnd(1);
    boreChildrenBd_bore_5_req = rnd(1);
    boreChildrenBd_bore_5_writeen = rnd(1);
    boreChildrenBd_bore_5_be = rnd(4);
    boreChildrenBd_bore_5_addr = rnd(8);
    boreChildrenBd_bore_5_indata = rnd(24);
    boreChildrenBd_bore_5_readen = rnd(1);
    boreChildrenBd_bore_5_addr_rd = rnd(8);
    boreChildrenBd_bore_6_array = rnd(7);
    boreChildrenBd_bore_6_all = rnd(1);
    boreChildrenBd_bore_6_req = rnd(1);
    boreChildrenBd_bore_6_writeen = rnd(1);
    boreChildrenBd_bore_6_be = rnd(76);
    boreChildrenBd_bore_6_addr = rnd(8);
    boreChildrenBd_bore_6_indata = rnd(76);
    boreChildrenBd_bore_6_readen = rnd(1);
    boreChildrenBd_bore_6_addr_rd = rnd(8);
    boreChildrenBd_bore_7_array = rnd(7);
    boreChildrenBd_bore_7_all = rnd(1);
    boreChildrenBd_bore_7_req = rnd(1);
    boreChildrenBd_bore_7_writeen = rnd(1);
    boreChildrenBd_bore_7_be = rnd(76);
    boreChildrenBd_bore_7_addr = rnd(8);
    boreChildrenBd_bore_7_indata = rnd(76);
    boreChildrenBd_bore_7_readen = rnd(1);
    boreChildrenBd_bore_7_addr_rd = rnd(8);
    boreChildrenBd_bore_8_array = rnd(7);
    boreChildrenBd_bore_8_all = rnd(1);
    boreChildrenBd_bore_8_req = rnd(1);
    boreChildrenBd_bore_8_writeen = rnd(1);
    boreChildrenBd_bore_8_be = rnd(76);
    boreChildrenBd_bore_8_addr = rnd(8);
    boreChildrenBd_bore_8_indata = rnd(76);
    boreChildrenBd_bore_8_readen = rnd(1);
    boreChildrenBd_bore_8_addr_rd = rnd(8);
    boreChildrenBd_bore_9_array = rnd(7);
    boreChildrenBd_bore_9_all = rnd(1);
    boreChildrenBd_bore_9_req = rnd(1);
    boreChildrenBd_bore_9_writeen = rnd(1);
    boreChildrenBd_bore_9_be = rnd(76);
    boreChildrenBd_bore_9_addr = rnd(8);
    boreChildrenBd_bore_9_indata = rnd(76);
    boreChildrenBd_bore_9_readen = rnd(1);
    boreChildrenBd_bore_9_addr_rd = rnd(8);
    boreChildrenBd_bore_10_array = rnd(7);
    boreChildrenBd_bore_10_all = rnd(1);
    boreChildrenBd_bore_10_req = rnd(1);
    boreChildrenBd_bore_10_writeen = rnd(1);
    boreChildrenBd_bore_10_be = rnd(76);
    boreChildrenBd_bore_10_addr = rnd(8);
    boreChildrenBd_bore_10_indata = rnd(76);
    boreChildrenBd_bore_10_readen = rnd(1);
    boreChildrenBd_bore_10_addr_rd = rnd(8);
    sigFromSrams_bore_ram_hold = rnd(1);
    sigFromSrams_bore_ram_bypass = rnd(1);
    sigFromSrams_bore_ram_bp_clken = rnd(1);
    sigFromSrams_bore_ram_aux_clk = rnd(1);
    sigFromSrams_bore_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_cgen = rnd(1);
    sigFromSrams_bore_1_ram_hold = rnd(1);
    sigFromSrams_bore_1_ram_bypass = rnd(1);
    sigFromSrams_bore_1_ram_bp_clken = rnd(1);
    sigFromSrams_bore_1_ram_aux_clk = rnd(1);
    sigFromSrams_bore_1_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_1_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_1_cgen = rnd(1);
    sigFromSrams_bore_2_ram_hold = rnd(1);
    sigFromSrams_bore_2_ram_bypass = rnd(1);
    sigFromSrams_bore_2_ram_bp_clken = rnd(1);
    sigFromSrams_bore_2_ram_aux_clk = rnd(1);
    sigFromSrams_bore_2_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_2_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_2_cgen = rnd(1);
    sigFromSrams_bore_3_ram_hold = rnd(1);
    sigFromSrams_bore_3_ram_bypass = rnd(1);
    sigFromSrams_bore_3_ram_bp_clken = rnd(1);
    sigFromSrams_bore_3_ram_aux_clk = rnd(1);
    sigFromSrams_bore_3_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_3_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_3_cgen = rnd(1);
    sigFromSrams_bore_4_ram_hold = rnd(1);
    sigFromSrams_bore_4_ram_bypass = rnd(1);
    sigFromSrams_bore_4_ram_bp_clken = rnd(1);
    sigFromSrams_bore_4_ram_aux_clk = rnd(1);
    sigFromSrams_bore_4_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_4_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_4_cgen = rnd(1);
    sigFromSrams_bore_5_ram_hold = rnd(1);
    sigFromSrams_bore_5_ram_bypass = rnd(1);
    sigFromSrams_bore_5_ram_bp_clken = rnd(1);
    sigFromSrams_bore_5_ram_aux_clk = rnd(1);
    sigFromSrams_bore_5_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_5_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_5_cgen = rnd(1);
    sigFromSrams_bore_6_ram_hold = rnd(1);
    sigFromSrams_bore_6_ram_bypass = rnd(1);
    sigFromSrams_bore_6_ram_bp_clken = rnd(1);
    sigFromSrams_bore_6_ram_aux_clk = rnd(1);
    sigFromSrams_bore_6_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_6_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_6_cgen = rnd(1);
    sigFromSrams_bore_7_ram_hold = rnd(1);
    sigFromSrams_bore_7_ram_bypass = rnd(1);
    sigFromSrams_bore_7_ram_bp_clken = rnd(1);
    sigFromSrams_bore_7_ram_aux_clk = rnd(1);
    sigFromSrams_bore_7_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_7_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_7_cgen = rnd(1);
    sigFromSrams_bore_8_ram_hold = rnd(1);
    sigFromSrams_bore_8_ram_bypass = rnd(1);
    sigFromSrams_bore_8_ram_bp_clken = rnd(1);
    sigFromSrams_bore_8_ram_aux_clk = rnd(1);
    sigFromSrams_bore_8_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_8_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_8_cgen = rnd(1);
    sigFromSrams_bore_9_ram_hold = rnd(1);
    sigFromSrams_bore_9_ram_bypass = rnd(1);
    sigFromSrams_bore_9_ram_bp_clken = rnd(1);
    sigFromSrams_bore_9_ram_aux_clk = rnd(1);
    sigFromSrams_bore_9_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_9_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_9_cgen = rnd(1);
    sigFromSrams_bore_10_ram_hold = rnd(1);
    sigFromSrams_bore_10_ram_bypass = rnd(1);
    sigFromSrams_bore_10_ram_bp_clken = rnd(1);
    sigFromSrams_bore_10_ram_aux_clk = rnd(1);
    sigFromSrams_bore_10_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_10_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_10_cgen = rnd(1);
    sigFromSrams_bore_11_ram_hold = rnd(1);
    sigFromSrams_bore_11_ram_bypass = rnd(1);
    sigFromSrams_bore_11_ram_bp_clken = rnd(1);
    sigFromSrams_bore_11_ram_aux_clk = rnd(1);
    sigFromSrams_bore_11_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_11_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_11_cgen = rnd(1);
    sigFromSrams_bore_12_ram_hold = rnd(1);
    sigFromSrams_bore_12_ram_bypass = rnd(1);
    sigFromSrams_bore_12_ram_bp_clken = rnd(1);
    sigFromSrams_bore_12_ram_aux_clk = rnd(1);
    sigFromSrams_bore_12_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_12_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_12_cgen = rnd(1);
    sigFromSrams_bore_13_ram_hold = rnd(1);
    sigFromSrams_bore_13_ram_bypass = rnd(1);
    sigFromSrams_bore_13_ram_bp_clken = rnd(1);
    sigFromSrams_bore_13_ram_aux_clk = rnd(1);
    sigFromSrams_bore_13_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_13_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_13_cgen = rnd(1);
    sigFromSrams_bore_14_ram_hold = rnd(1);
    sigFromSrams_bore_14_ram_bypass = rnd(1);
    sigFromSrams_bore_14_ram_bp_clken = rnd(1);
    sigFromSrams_bore_14_ram_aux_clk = rnd(1);
    sigFromSrams_bore_14_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_14_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_14_cgen = rnd(1);
    sigFromSrams_bore_15_ram_hold = rnd(1);
    sigFromSrams_bore_15_ram_bypass = rnd(1);
    sigFromSrams_bore_15_ram_bp_clken = rnd(1);
    sigFromSrams_bore_15_ram_aux_clk = rnd(1);
    sigFromSrams_bore_15_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_15_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_15_cgen = rnd(1);
    sigFromSrams_bore_16_ram_hold = rnd(1);
    sigFromSrams_bore_16_ram_bypass = rnd(1);
    sigFromSrams_bore_16_ram_bp_clken = rnd(1);
    sigFromSrams_bore_16_ram_aux_clk = rnd(1);
    sigFromSrams_bore_16_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_16_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_16_cgen = rnd(1);
    sigFromSrams_bore_17_ram_hold = rnd(1);
    sigFromSrams_bore_17_ram_bypass = rnd(1);
    sigFromSrams_bore_17_ram_bp_clken = rnd(1);
    sigFromSrams_bore_17_ram_aux_clk = rnd(1);
    sigFromSrams_bore_17_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_17_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_17_cgen = rnd(1);
    sigFromSrams_bore_18_ram_hold = rnd(1);
    sigFromSrams_bore_18_ram_bypass = rnd(1);
    sigFromSrams_bore_18_ram_bp_clken = rnd(1);
    sigFromSrams_bore_18_ram_aux_clk = rnd(1);
    sigFromSrams_bore_18_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_18_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_18_cgen = rnd(1);
    sigFromSrams_bore_19_ram_hold = rnd(1);
    sigFromSrams_bore_19_ram_bypass = rnd(1);
    sigFromSrams_bore_19_ram_bp_clken = rnd(1);
    sigFromSrams_bore_19_ram_aux_clk = rnd(1);
    sigFromSrams_bore_19_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_19_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_19_cgen = rnd(1);
    sigFromSrams_bore_20_ram_hold = rnd(1);
    sigFromSrams_bore_20_ram_bypass = rnd(1);
    sigFromSrams_bore_20_ram_bp_clken = rnd(1);
    sigFromSrams_bore_20_ram_aux_clk = rnd(1);
    sigFromSrams_bore_20_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_20_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_20_cgen = rnd(1);
    sigFromSrams_bore_21_ram_hold = rnd(1);
    sigFromSrams_bore_21_ram_bypass = rnd(1);
    sigFromSrams_bore_21_ram_bp_clken = rnd(1);
    sigFromSrams_bore_21_ram_aux_clk = rnd(1);
    sigFromSrams_bore_21_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_21_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_21_cgen = rnd(1);
    sigFromSrams_bore_22_ram_hold = rnd(1);
    sigFromSrams_bore_22_ram_bypass = rnd(1);
    sigFromSrams_bore_22_ram_bp_clken = rnd(1);
    sigFromSrams_bore_22_ram_aux_clk = rnd(1);
    sigFromSrams_bore_22_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_22_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_22_cgen = rnd(1);
    sigFromSrams_bore_23_ram_hold = rnd(1);
    sigFromSrams_bore_23_ram_bypass = rnd(1);
    sigFromSrams_bore_23_ram_bp_clken = rnd(1);
    sigFromSrams_bore_23_ram_aux_clk = rnd(1);
    sigFromSrams_bore_23_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_23_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_23_cgen = rnd(1);
    sigFromSrams_bore_24_ram_hold = rnd(1);
    sigFromSrams_bore_24_ram_bypass = rnd(1);
    sigFromSrams_bore_24_ram_bp_clken = rnd(1);
    sigFromSrams_bore_24_ram_aux_clk = rnd(1);
    sigFromSrams_bore_24_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_24_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_24_cgen = rnd(1);
    sigFromSrams_bore_25_ram_hold = rnd(1);
    sigFromSrams_bore_25_ram_bypass = rnd(1);
    sigFromSrams_bore_25_ram_bp_clken = rnd(1);
    sigFromSrams_bore_25_ram_aux_clk = rnd(1);
    sigFromSrams_bore_25_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_25_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_25_cgen = rnd(1);
    sigFromSrams_bore_26_ram_hold = rnd(1);
    sigFromSrams_bore_26_ram_bypass = rnd(1);
    sigFromSrams_bore_26_ram_bp_clken = rnd(1);
    sigFromSrams_bore_26_ram_aux_clk = rnd(1);
    sigFromSrams_bore_26_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_26_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_26_cgen = rnd(1);
    sigFromSrams_bore_27_ram_hold = rnd(1);
    sigFromSrams_bore_27_ram_bypass = rnd(1);
    sigFromSrams_bore_27_ram_bp_clken = rnd(1);
    sigFromSrams_bore_27_ram_aux_clk = rnd(1);
    sigFromSrams_bore_27_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_27_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_27_cgen = rnd(1);
    sigFromSrams_bore_28_ram_hold = rnd(1);
    sigFromSrams_bore_28_ram_bypass = rnd(1);
    sigFromSrams_bore_28_ram_bp_clken = rnd(1);
    sigFromSrams_bore_28_ram_aux_clk = rnd(1);
    sigFromSrams_bore_28_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_28_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_28_cgen = rnd(1);
    sigFromSrams_bore_29_ram_hold = rnd(1);
    sigFromSrams_bore_29_ram_bypass = rnd(1);
    sigFromSrams_bore_29_ram_bp_clken = rnd(1);
    sigFromSrams_bore_29_ram_aux_clk = rnd(1);
    sigFromSrams_bore_29_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_29_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_29_cgen = rnd(1);
    sigFromSrams_bore_30_ram_hold = rnd(1);
    sigFromSrams_bore_30_ram_bypass = rnd(1);
    sigFromSrams_bore_30_ram_bp_clken = rnd(1);
    sigFromSrams_bore_30_ram_aux_clk = rnd(1);
    sigFromSrams_bore_30_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_30_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_30_cgen = rnd(1);
    sigFromSrams_bore_31_ram_hold = rnd(1);
    sigFromSrams_bore_31_ram_bypass = rnd(1);
    sigFromSrams_bore_31_ram_bp_clken = rnd(1);
    sigFromSrams_bore_31_ram_aux_clk = rnd(1);
    sigFromSrams_bore_31_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_31_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_31_cgen = rnd(1);
    sigFromSrams_bore_32_ram_hold = rnd(1);
    sigFromSrams_bore_32_ram_bypass = rnd(1);
    sigFromSrams_bore_32_ram_bp_clken = rnd(1);
    sigFromSrams_bore_32_ram_aux_clk = rnd(1);
    sigFromSrams_bore_32_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_32_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_32_cgen = rnd(1);
    sigFromSrams_bore_33_ram_hold = rnd(1);
    sigFromSrams_bore_33_ram_bypass = rnd(1);
    sigFromSrams_bore_33_ram_bp_clken = rnd(1);
    sigFromSrams_bore_33_ram_aux_clk = rnd(1);
    sigFromSrams_bore_33_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_33_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_33_cgen = rnd(1);
    sigFromSrams_bore_34_ram_hold = rnd(1);
    sigFromSrams_bore_34_ram_bypass = rnd(1);
    sigFromSrams_bore_34_ram_bp_clken = rnd(1);
    sigFromSrams_bore_34_ram_aux_clk = rnd(1);
    sigFromSrams_bore_34_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_34_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_34_cgen = rnd(1);
    sigFromSrams_bore_35_ram_hold = rnd(1);
    sigFromSrams_bore_35_ram_bypass = rnd(1);
    sigFromSrams_bore_35_ram_bp_clken = rnd(1);
    sigFromSrams_bore_35_ram_aux_clk = rnd(1);
    sigFromSrams_bore_35_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_35_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_35_cgen = rnd(1);
    sigFromSrams_bore_36_ram_hold = rnd(1);
    sigFromSrams_bore_36_ram_bypass = rnd(1);
    sigFromSrams_bore_36_ram_bp_clken = rnd(1);
    sigFromSrams_bore_36_ram_aux_clk = rnd(1);
    sigFromSrams_bore_36_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_36_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_36_cgen = rnd(1);
    sigFromSrams_bore_37_ram_hold = rnd(1);
    sigFromSrams_bore_37_ram_bypass = rnd(1);
    sigFromSrams_bore_37_ram_bp_clken = rnd(1);
    sigFromSrams_bore_37_ram_aux_clk = rnd(1);
    sigFromSrams_bore_37_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_37_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_37_cgen = rnd(1);
    sigFromSrams_bore_38_ram_hold = rnd(1);
    sigFromSrams_bore_38_ram_bypass = rnd(1);
    sigFromSrams_bore_38_ram_bp_clken = rnd(1);
    sigFromSrams_bore_38_ram_aux_clk = rnd(1);
    sigFromSrams_bore_38_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_38_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_38_cgen = rnd(1);
    sigFromSrams_bore_39_ram_hold = rnd(1);
    sigFromSrams_bore_39_ram_bypass = rnd(1);
    sigFromSrams_bore_39_ram_bp_clken = rnd(1);
    sigFromSrams_bore_39_ram_aux_clk = rnd(1);
    sigFromSrams_bore_39_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_39_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_39_cgen = rnd(1);
    sigFromSrams_bore_40_ram_hold = rnd(1);
    sigFromSrams_bore_40_ram_bypass = rnd(1);
    sigFromSrams_bore_40_ram_bp_clken = rnd(1);
    sigFromSrams_bore_40_ram_aux_clk = rnd(1);
    sigFromSrams_bore_40_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_40_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_40_cgen = rnd(1);
    sigFromSrams_bore_41_ram_hold = rnd(1);
    sigFromSrams_bore_41_ram_bypass = rnd(1);
    sigFromSrams_bore_41_ram_bp_clken = rnd(1);
    sigFromSrams_bore_41_ram_aux_clk = rnd(1);
    sigFromSrams_bore_41_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_41_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_41_cgen = rnd(1);
    sigFromSrams_bore_42_ram_hold = rnd(1);
    sigFromSrams_bore_42_ram_bypass = rnd(1);
    sigFromSrams_bore_42_ram_bp_clken = rnd(1);
    sigFromSrams_bore_42_ram_aux_clk = rnd(1);
    sigFromSrams_bore_42_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_42_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_42_cgen = rnd(1);
    sigFromSrams_bore_43_ram_hold = rnd(1);
    sigFromSrams_bore_43_ram_bypass = rnd(1);
    sigFromSrams_bore_43_ram_bp_clken = rnd(1);
    sigFromSrams_bore_43_ram_aux_clk = rnd(1);
    sigFromSrams_bore_43_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_43_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_43_cgen = rnd(1);
    sigFromSrams_bore_44_ram_hold = rnd(1);
    sigFromSrams_bore_44_ram_bypass = rnd(1);
    sigFromSrams_bore_44_ram_bp_clken = rnd(1);
    sigFromSrams_bore_44_ram_aux_clk = rnd(1);
    sigFromSrams_bore_44_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_44_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_44_cgen = rnd(1);
    sigFromSrams_bore_45_ram_hold = rnd(1);
    sigFromSrams_bore_45_ram_bypass = rnd(1);
    sigFromSrams_bore_45_ram_bp_clken = rnd(1);
    sigFromSrams_bore_45_ram_aux_clk = rnd(1);
    sigFromSrams_bore_45_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_45_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_45_cgen = rnd(1);
    sigFromSrams_bore_46_ram_hold = rnd(1);
    sigFromSrams_bore_46_ram_bypass = rnd(1);
    sigFromSrams_bore_46_ram_bp_clken = rnd(1);
    sigFromSrams_bore_46_ram_aux_clk = rnd(1);
    sigFromSrams_bore_46_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_46_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_46_cgen = rnd(1);
    sigFromSrams_bore_47_ram_hold = rnd(1);
    sigFromSrams_bore_47_ram_bypass = rnd(1);
    sigFromSrams_bore_47_ram_bp_clken = rnd(1);
    sigFromSrams_bore_47_ram_aux_clk = rnd(1);
    sigFromSrams_bore_47_ram_aux_ckbp = rnd(1);
    sigFromSrams_bore_47_ram_mcp_hold = rnd(1);
    sigFromSrams_bore_47_cgen = rnd(1);
  endtask

  task automatic check_outputs();
    `CHECK(io_out_s1_pc_0)
    `CHECK(io_out_s1_pc_1)
    `CHECK(io_out_s1_pc_2)
    `CHECK(io_out_s1_pc_3)
    `CHECK(io_out_s1_full_pred_0_br_taken_mask_0)
    `CHECK(io_out_s1_full_pred_0_br_taken_mask_1)
    `CHECK(io_out_s1_full_pred_0_slot_valids_0)
    `CHECK(io_out_s1_full_pred_0_slot_valids_1)
    `CHECK(io_out_s1_full_pred_0_targets_0)
    `CHECK(io_out_s1_full_pred_0_targets_1)
    `CHECK(io_out_s1_full_pred_0_jalr_target)
    `CHECK(io_out_s1_full_pred_0_offsets_0)
    `CHECK(io_out_s1_full_pred_0_offsets_1)
    `CHECK(io_out_s1_full_pred_0_fallThroughAddr)
    `CHECK(io_out_s1_full_pred_0_fallThroughErr)
    `CHECK(io_out_s1_full_pred_0_is_jal)
    `CHECK(io_out_s1_full_pred_0_is_jalr)
    `CHECK(io_out_s1_full_pred_0_is_call)
    `CHECK(io_out_s1_full_pred_0_is_ret)
    `CHECK(io_out_s1_full_pred_0_last_may_be_rvi_call)
    `CHECK(io_out_s1_full_pred_0_is_br_sharing)
    `CHECK(io_out_s1_full_pred_0_hit)
    `CHECK(io_out_s1_full_pred_1_br_taken_mask_0)
    `CHECK(io_out_s1_full_pred_1_br_taken_mask_1)
    `CHECK(io_out_s1_full_pred_1_slot_valids_0)
    `CHECK(io_out_s1_full_pred_1_slot_valids_1)
    `CHECK(io_out_s1_full_pred_1_targets_0)
    `CHECK(io_out_s1_full_pred_1_targets_1)
    `CHECK(io_out_s1_full_pred_1_jalr_target)
    `CHECK(io_out_s1_full_pred_1_offsets_0)
    `CHECK(io_out_s1_full_pred_1_offsets_1)
    `CHECK(io_out_s1_full_pred_1_fallThroughAddr)
    `CHECK(io_out_s1_full_pred_1_fallThroughErr)
    `CHECK(io_out_s1_full_pred_1_is_jal)
    `CHECK(io_out_s1_full_pred_1_is_jalr)
    `CHECK(io_out_s1_full_pred_1_is_call)
    `CHECK(io_out_s1_full_pred_1_is_ret)
    `CHECK(io_out_s1_full_pred_1_last_may_be_rvi_call)
    `CHECK(io_out_s1_full_pred_1_is_br_sharing)
    `CHECK(io_out_s1_full_pred_1_hit)
    `CHECK(io_out_s1_full_pred_2_br_taken_mask_0)
    `CHECK(io_out_s1_full_pred_2_br_taken_mask_1)
    `CHECK(io_out_s1_full_pred_2_slot_valids_0)
    `CHECK(io_out_s1_full_pred_2_slot_valids_1)
    `CHECK(io_out_s1_full_pred_2_targets_0)
    `CHECK(io_out_s1_full_pred_2_targets_1)
    `CHECK(io_out_s1_full_pred_2_jalr_target)
    `CHECK(io_out_s1_full_pred_2_offsets_0)
    `CHECK(io_out_s1_full_pred_2_offsets_1)
    `CHECK(io_out_s1_full_pred_2_fallThroughAddr)
    `CHECK(io_out_s1_full_pred_2_fallThroughErr)
    `CHECK(io_out_s1_full_pred_2_is_jal)
    `CHECK(io_out_s1_full_pred_2_is_jalr)
    `CHECK(io_out_s1_full_pred_2_is_call)
    `CHECK(io_out_s1_full_pred_2_is_ret)
    `CHECK(io_out_s1_full_pred_2_last_may_be_rvi_call)
    `CHECK(io_out_s1_full_pred_2_is_br_sharing)
    `CHECK(io_out_s1_full_pred_2_hit)
    `CHECK(io_out_s1_full_pred_3_br_taken_mask_0)
    `CHECK(io_out_s1_full_pred_3_br_taken_mask_1)
    `CHECK(io_out_s1_full_pred_3_slot_valids_0)
    `CHECK(io_out_s1_full_pred_3_slot_valids_1)
    `CHECK(io_out_s1_full_pred_3_targets_0)
    `CHECK(io_out_s1_full_pred_3_targets_1)
    `CHECK(io_out_s1_full_pred_3_jalr_target)
    `CHECK(io_out_s1_full_pred_3_offsets_0)
    `CHECK(io_out_s1_full_pred_3_offsets_1)
    `CHECK(io_out_s1_full_pred_3_fallThroughAddr)
    `CHECK(io_out_s1_full_pred_3_fallThroughErr)
    `CHECK(io_out_s1_full_pred_3_is_jal)
    `CHECK(io_out_s1_full_pred_3_is_jalr)
    `CHECK(io_out_s1_full_pred_3_is_call)
    `CHECK(io_out_s1_full_pred_3_is_ret)
    `CHECK(io_out_s1_full_pred_3_last_may_be_rvi_call)
    `CHECK(io_out_s1_full_pred_3_is_br_sharing)
    `CHECK(io_out_s1_full_pred_3_hit)
    `CHECK(io_out_s2_pc_0)
    `CHECK(io_out_s2_pc_1)
    `CHECK(io_out_s2_pc_2)
    `CHECK(io_out_s2_pc_3)
    `CHECK(io_out_s2_full_pred_0_br_taken_mask_0)
    `CHECK(io_out_s2_full_pred_0_br_taken_mask_1)
    `CHECK(io_out_s2_full_pred_0_slot_valids_0)
    `CHECK(io_out_s2_full_pred_0_slot_valids_1)
    `CHECK(io_out_s2_full_pred_0_targets_0)
    `CHECK(io_out_s2_full_pred_0_targets_1)
    `CHECK(io_out_s2_full_pred_0_jalr_target)
    `CHECK(io_out_s2_full_pred_0_offsets_0)
    `CHECK(io_out_s2_full_pred_0_offsets_1)
    `CHECK(io_out_s2_full_pred_0_fallThroughAddr)
    `CHECK(io_out_s2_full_pred_0_fallThroughErr)
    `CHECK(io_out_s2_full_pred_0_is_jal)
    `CHECK(io_out_s2_full_pred_0_is_jalr)
    `CHECK(io_out_s2_full_pred_0_is_call)
    `CHECK(io_out_s2_full_pred_0_is_ret)
    `CHECK(io_out_s2_full_pred_0_last_may_be_rvi_call)
    `CHECK(io_out_s2_full_pred_0_is_br_sharing)
    `CHECK(io_out_s2_full_pred_0_hit)
    `CHECK(io_out_s2_full_pred_1_br_taken_mask_0)
    `CHECK(io_out_s2_full_pred_1_br_taken_mask_1)
    `CHECK(io_out_s2_full_pred_1_slot_valids_0)
    `CHECK(io_out_s2_full_pred_1_slot_valids_1)
    `CHECK(io_out_s2_full_pred_1_targets_0)
    `CHECK(io_out_s2_full_pred_1_targets_1)
    `CHECK(io_out_s2_full_pred_1_jalr_target)
    `CHECK(io_out_s2_full_pred_1_offsets_0)
    `CHECK(io_out_s2_full_pred_1_offsets_1)
    `CHECK(io_out_s2_full_pred_1_fallThroughAddr)
    `CHECK(io_out_s2_full_pred_1_fallThroughErr)
    `CHECK(io_out_s2_full_pred_1_is_jal)
    `CHECK(io_out_s2_full_pred_1_is_jalr)
    `CHECK(io_out_s2_full_pred_1_is_call)
    `CHECK(io_out_s2_full_pred_1_is_ret)
    `CHECK(io_out_s2_full_pred_1_last_may_be_rvi_call)
    `CHECK(io_out_s2_full_pred_1_is_br_sharing)
    `CHECK(io_out_s2_full_pred_1_hit)
    `CHECK(io_out_s2_full_pred_2_br_taken_mask_0)
    `CHECK(io_out_s2_full_pred_2_br_taken_mask_1)
    `CHECK(io_out_s2_full_pred_2_slot_valids_0)
    `CHECK(io_out_s2_full_pred_2_slot_valids_1)
    `CHECK(io_out_s2_full_pred_2_targets_0)
    `CHECK(io_out_s2_full_pred_2_targets_1)
    `CHECK(io_out_s2_full_pred_2_jalr_target)
    `CHECK(io_out_s2_full_pred_2_offsets_0)
    `CHECK(io_out_s2_full_pred_2_offsets_1)
    `CHECK(io_out_s2_full_pred_2_fallThroughAddr)
    `CHECK(io_out_s2_full_pred_2_fallThroughErr)
    `CHECK(io_out_s2_full_pred_2_is_jal)
    `CHECK(io_out_s2_full_pred_2_is_jalr)
    `CHECK(io_out_s2_full_pred_2_is_call)
    `CHECK(io_out_s2_full_pred_2_is_ret)
    `CHECK(io_out_s2_full_pred_2_last_may_be_rvi_call)
    `CHECK(io_out_s2_full_pred_2_is_br_sharing)
    `CHECK(io_out_s2_full_pred_2_hit)
    `CHECK(io_out_s2_full_pred_3_br_taken_mask_0)
    `CHECK(io_out_s2_full_pred_3_br_taken_mask_1)
    `CHECK(io_out_s2_full_pred_3_slot_valids_0)
    `CHECK(io_out_s2_full_pred_3_slot_valids_1)
    `CHECK(io_out_s2_full_pred_3_targets_0)
    `CHECK(io_out_s2_full_pred_3_targets_1)
    `CHECK(io_out_s2_full_pred_3_jalr_target)
    `CHECK(io_out_s2_full_pred_3_offsets_0)
    `CHECK(io_out_s2_full_pred_3_offsets_1)
    `CHECK(io_out_s2_full_pred_3_fallThroughAddr)
    `CHECK(io_out_s2_full_pred_3_fallThroughErr)
    `CHECK(io_out_s2_full_pred_3_is_jal)
    `CHECK(io_out_s2_full_pred_3_is_jalr)
    `CHECK(io_out_s2_full_pred_3_is_call)
    `CHECK(io_out_s2_full_pred_3_is_ret)
    `CHECK(io_out_s2_full_pred_3_last_may_be_rvi_call)
    `CHECK(io_out_s2_full_pred_3_is_br_sharing)
    `CHECK(io_out_s2_full_pred_3_hit)
    `CHECK(io_out_s3_pc_0)
    `CHECK(io_out_s3_pc_1)
    `CHECK(io_out_s3_pc_2)
    `CHECK(io_out_s3_pc_3)
    `CHECK(io_out_s3_full_pred_0_br_taken_mask_0)
    `CHECK(io_out_s3_full_pred_0_br_taken_mask_1)
    `CHECK(io_out_s3_full_pred_0_slot_valids_0)
    `CHECK(io_out_s3_full_pred_0_slot_valids_1)
    `CHECK(io_out_s3_full_pred_0_targets_0)
    `CHECK(io_out_s3_full_pred_0_targets_1)
    `CHECK(io_out_s3_full_pred_0_jalr_target)
    `CHECK(io_out_s3_full_pred_0_offsets_0)
    `CHECK(io_out_s3_full_pred_0_offsets_1)
    `CHECK(io_out_s3_full_pred_0_fallThroughAddr)
    `CHECK(io_out_s3_full_pred_0_fallThroughErr)
    `CHECK(io_out_s3_full_pred_0_multiHit)
    `CHECK(io_out_s3_full_pred_0_is_jal)
    `CHECK(io_out_s3_full_pred_0_is_jalr)
    `CHECK(io_out_s3_full_pred_0_is_call)
    `CHECK(io_out_s3_full_pred_0_is_ret)
    `CHECK(io_out_s3_full_pred_0_last_may_be_rvi_call)
    `CHECK(io_out_s3_full_pred_0_is_br_sharing)
    `CHECK(io_out_s3_full_pred_0_hit)
    `CHECK(io_out_s3_full_pred_1_br_taken_mask_0)
    `CHECK(io_out_s3_full_pred_1_br_taken_mask_1)
    `CHECK(io_out_s3_full_pred_1_slot_valids_0)
    `CHECK(io_out_s3_full_pred_1_slot_valids_1)
    `CHECK(io_out_s3_full_pred_1_targets_0)
    `CHECK(io_out_s3_full_pred_1_targets_1)
    `CHECK(io_out_s3_full_pred_1_jalr_target)
    `CHECK(io_out_s3_full_pred_1_offsets_0)
    `CHECK(io_out_s3_full_pred_1_offsets_1)
    `CHECK(io_out_s3_full_pred_1_fallThroughAddr)
    `CHECK(io_out_s3_full_pred_1_fallThroughErr)
    `CHECK(io_out_s3_full_pred_1_multiHit)
    `CHECK(io_out_s3_full_pred_1_is_jal)
    `CHECK(io_out_s3_full_pred_1_is_jalr)
    `CHECK(io_out_s3_full_pred_1_is_call)
    `CHECK(io_out_s3_full_pred_1_is_ret)
    `CHECK(io_out_s3_full_pred_1_last_may_be_rvi_call)
    `CHECK(io_out_s3_full_pred_1_is_br_sharing)
    `CHECK(io_out_s3_full_pred_1_hit)
    `CHECK(io_out_s3_full_pred_2_br_taken_mask_0)
    `CHECK(io_out_s3_full_pred_2_br_taken_mask_1)
    `CHECK(io_out_s3_full_pred_2_slot_valids_0)
    `CHECK(io_out_s3_full_pred_2_slot_valids_1)
    `CHECK(io_out_s3_full_pred_2_targets_0)
    `CHECK(io_out_s3_full_pred_2_targets_1)
    `CHECK(io_out_s3_full_pred_2_jalr_target)
    `CHECK(io_out_s3_full_pred_2_offsets_0)
    `CHECK(io_out_s3_full_pred_2_offsets_1)
    `CHECK(io_out_s3_full_pred_2_fallThroughAddr)
    `CHECK(io_out_s3_full_pred_2_fallThroughErr)
    `CHECK(io_out_s3_full_pred_2_multiHit)
    `CHECK(io_out_s3_full_pred_2_is_jal)
    `CHECK(io_out_s3_full_pred_2_is_jalr)
    `CHECK(io_out_s3_full_pred_2_is_call)
    `CHECK(io_out_s3_full_pred_2_is_ret)
    `CHECK(io_out_s3_full_pred_2_last_may_be_rvi_call)
    `CHECK(io_out_s3_full_pred_2_is_br_sharing)
    `CHECK(io_out_s3_full_pred_2_hit)
    `CHECK(io_out_s3_full_pred_3_br_taken_mask_0)
    `CHECK(io_out_s3_full_pred_3_br_taken_mask_1)
    `CHECK(io_out_s3_full_pred_3_slot_valids_0)
    `CHECK(io_out_s3_full_pred_3_slot_valids_1)
    `CHECK(io_out_s3_full_pred_3_targets_0)
    `CHECK(io_out_s3_full_pred_3_targets_1)
    `CHECK(io_out_s3_full_pred_3_jalr_target)
    `CHECK(io_out_s3_full_pred_3_offsets_0)
    `CHECK(io_out_s3_full_pred_3_offsets_1)
    `CHECK(io_out_s3_full_pred_3_fallThroughAddr)
    `CHECK(io_out_s3_full_pred_3_fallThroughErr)
    `CHECK(io_out_s3_full_pred_3_multiHit)
    `CHECK(io_out_s3_full_pred_3_is_jal)
    `CHECK(io_out_s3_full_pred_3_is_jalr)
    `CHECK(io_out_s3_full_pred_3_is_call)
    `CHECK(io_out_s3_full_pred_3_is_ret)
    `CHECK(io_out_s3_full_pred_3_last_may_be_rvi_call)
    `CHECK(io_out_s3_full_pred_3_is_br_sharing)
    `CHECK(io_out_s3_full_pred_3_hit)
    `CHECK(io_out_last_stage_meta)
    `CHECK(io_out_last_stage_spec_info_ssp)
    `CHECK(io_out_last_stage_spec_info_sctr)
    `CHECK(io_out_last_stage_spec_info_TOSW_flag)
    `CHECK(io_out_last_stage_spec_info_TOSW_value)
    `CHECK(io_out_last_stage_spec_info_TOSR_flag)
    `CHECK(io_out_last_stage_spec_info_TOSR_value)
    `CHECK(io_out_last_stage_spec_info_NOS_flag)
    `CHECK(io_out_last_stage_spec_info_NOS_value)
    `CHECK(io_out_last_stage_spec_info_topAddr)
    `CHECK(io_out_last_stage_spec_info_sc_disagree_0)
    `CHECK(io_out_last_stage_spec_info_sc_disagree_1)
    `CHECK(io_out_last_stage_ftb_entry_isCall)
    `CHECK(io_out_last_stage_ftb_entry_isRet)
    `CHECK(io_out_last_stage_ftb_entry_isJalr)
    `CHECK(io_out_last_stage_ftb_entry_valid)
    `CHECK(io_out_last_stage_ftb_entry_brSlots_0_offset)
    `CHECK(io_out_last_stage_ftb_entry_brSlots_0_sharing)
    `CHECK(io_out_last_stage_ftb_entry_brSlots_0_valid)
    `CHECK(io_out_last_stage_ftb_entry_brSlots_0_lower)
    `CHECK(io_out_last_stage_ftb_entry_brSlots_0_tarStat)
    `CHECK(io_out_last_stage_ftb_entry_tailSlot_offset)
    `CHECK(io_out_last_stage_ftb_entry_tailSlot_sharing)
    `CHECK(io_out_last_stage_ftb_entry_tailSlot_valid)
    `CHECK(io_out_last_stage_ftb_entry_tailSlot_lower)
    `CHECK(io_out_last_stage_ftb_entry_tailSlot_tarStat)
    `CHECK(io_out_last_stage_ftb_entry_pftAddr)
    `CHECK(io_out_last_stage_ftb_entry_carry)
    `CHECK(io_out_last_stage_ftb_entry_last_may_be_rvi_call)
    `CHECK(io_out_last_stage_ftb_entry_strong_bias_0)
    `CHECK(io_out_last_stage_ftb_entry_strong_bias_1)
    `CHECK(io_s1_ready)
    `CHECK(io_perf_0_value)
    `CHECK(io_perf_1_value)
    `CHECK(io_perf_2_value)
    `CHECK(io_perf_3_value)
    `CHECK(io_perf_4_value)
    `CHECK(io_perf_5_value)
    `CHECK(io_perf_6_value)
    `CHECK(boreChildrenBd_bore_ack)
    `CHECK(boreChildrenBd_bore_outdata)
    `CHECK(boreChildrenBd_bore_1_ack)
    `CHECK(boreChildrenBd_bore_1_outdata)
    `CHECK(boreChildrenBd_bore_2_ack)
    `CHECK(boreChildrenBd_bore_2_outdata)
    `CHECK(boreChildrenBd_bore_3_ack)
    `CHECK(boreChildrenBd_bore_3_outdata)
    `CHECK(boreChildrenBd_bore_4_ack)
    `CHECK(boreChildrenBd_bore_4_outdata)
    `CHECK(boreChildrenBd_bore_5_ack)
    `CHECK(boreChildrenBd_bore_5_outdata)
    `CHECK(boreChildrenBd_bore_6_ack)
    `CHECK(boreChildrenBd_bore_6_outdata)
    `CHECK(boreChildrenBd_bore_7_ack)
    `CHECK(boreChildrenBd_bore_7_outdata)
    `CHECK(boreChildrenBd_bore_8_ack)
    `CHECK(boreChildrenBd_bore_8_outdata)
    `CHECK(boreChildrenBd_bore_9_ack)
    `CHECK(boreChildrenBd_bore_9_outdata)
    `CHECK(boreChildrenBd_bore_10_ack)
    `CHECK(boreChildrenBd_bore_10_outdata)
  endtask

  // 层次探针：cone-dead 的影子 PC 流水 + modified_reset，输出端口看不到，
  // 只能这样钉。golden 侧名字直接来自 G1 golden Composer.sv。
  task automatic check_hier();
    `CHECKH("modified_reset", g_dut.modified_reset, i_dut.u_core.modified_reset)
    `CHECKH("s1_pc[0]", g_dut.s1_pc_dup_0, i_dut.u_core.s1_pc[0])
    `CHECKH("s2_pc_hi[0]", g_dut.s2_pc_dup_s2_pc_seg_0_value, i_dut.u_core.s2_pc_hi[0])
    `CHECKH("s2_pc_mid[0]", g_dut.s2_pc_dup_s2_pc_seg_1_value, i_dut.u_core.s2_pc_mid[0])
    `CHECKH("s2_pc_lo[0]", g_dut.s2_pc_dup_s2_pc_seg_2_value, i_dut.u_core.s2_pc_lo[0])
    `CHECKH("s3_pc_hi[0]", g_dut.s3_pc_dup_s3_pc_seg_0_value, i_dut.u_core.s3_pc_hi[0])
    `CHECKH("s3_pc_mid[0]", g_dut.s3_pc_dup_s3_pc_seg_1_value, i_dut.u_core.s3_pc_mid[0])
    `CHECKH("s3_pc_lo[0]", g_dut.s3_pc_dup_s3_pc_seg_2_value, i_dut.u_core.s3_pc_lo[0])
    `CHECKH("s1_pc[1]", g_dut.s1_pc_dup_1, i_dut.u_core.s1_pc[1])
    `CHECKH("s2_pc_hi[1]", g_dut.s2_pc_dup_s2_pc_seg_0_value_1, i_dut.u_core.s2_pc_hi[1])
    `CHECKH("s2_pc_mid[1]", g_dut.s2_pc_dup_s2_pc_seg_1_value_1, i_dut.u_core.s2_pc_mid[1])
    `CHECKH("s2_pc_lo[1]", g_dut.s2_pc_dup_s2_pc_seg_2_value_1, i_dut.u_core.s2_pc_lo[1])
    `CHECKH("s3_pc_hi[1]", g_dut.s3_pc_dup_s3_pc_seg_0_value_1, i_dut.u_core.s3_pc_hi[1])
    `CHECKH("s3_pc_mid[1]", g_dut.s3_pc_dup_s3_pc_seg_1_value_1, i_dut.u_core.s3_pc_mid[1])
    `CHECKH("s3_pc_lo[1]", g_dut.s3_pc_dup_s3_pc_seg_2_value_1, i_dut.u_core.s3_pc_lo[1])
    `CHECKH("s1_pc[2]", g_dut.s1_pc_dup_2, i_dut.u_core.s1_pc[2])
    `CHECKH("s2_pc_hi[2]", g_dut.s2_pc_dup_s2_pc_seg_0_value_2, i_dut.u_core.s2_pc_hi[2])
    `CHECKH("s2_pc_mid[2]", g_dut.s2_pc_dup_s2_pc_seg_1_value_2, i_dut.u_core.s2_pc_mid[2])
    `CHECKH("s2_pc_lo[2]", g_dut.s2_pc_dup_s2_pc_seg_2_value_2, i_dut.u_core.s2_pc_lo[2])
    `CHECKH("s3_pc_hi[2]", g_dut.s3_pc_dup_s3_pc_seg_0_value_2, i_dut.u_core.s3_pc_hi[2])
    `CHECKH("s3_pc_mid[2]", g_dut.s3_pc_dup_s3_pc_seg_1_value_2, i_dut.u_core.s3_pc_mid[2])
    `CHECKH("s3_pc_lo[2]", g_dut.s3_pc_dup_s3_pc_seg_2_value_2, i_dut.u_core.s3_pc_lo[2])
    `CHECKH("s1_pc[3]", g_dut.s1_pc_dup_3, i_dut.u_core.s1_pc[3])
    `CHECKH("s2_pc_hi[3]", g_dut.s2_pc_dup_s2_pc_seg_0_value_3, i_dut.u_core.s2_pc_hi[3])
    `CHECKH("s2_pc_mid[3]", g_dut.s2_pc_dup_s2_pc_seg_1_value_3, i_dut.u_core.s2_pc_mid[3])
    `CHECKH("s2_pc_lo[3]", g_dut.s2_pc_dup_s2_pc_seg_2_value_3, i_dut.u_core.s2_pc_lo[3])
    `CHECKH("s3_pc_hi[3]", g_dut.s3_pc_dup_s3_pc_seg_0_value_3, i_dut.u_core.s3_pc_hi[3])
    `CHECKH("s3_pc_mid[3]", g_dut.s3_pc_dup_s3_pc_seg_1_value_3, i_dut.u_core.s3_pc_mid[3])
    `CHECKH("s3_pc_lo[3]", g_dut.s3_pc_dup_s3_pc_seg_2_value_3, i_dut.u_core.s3_pc_lo[3])
  endtask

  task automatic sample_coverage();
    if (g_dut.modified_reset === 1'b1) mres_hi++;
    fire_s0 = {io_s0_fire_3, io_s0_fire_2, io_s0_fire_1, io_s0_fire_0};
    fire_s1 = {io_s1_fire_3, io_s1_fire_2, io_s1_fire_1, io_s1_fire_0};
    fire_s2 = {io_s2_fire_3, io_s2_fire_2, io_s2_fire_1, io_s2_fire_0};
    for (int d = 0; d < 4; d++) begin
      if (fire_s0[d]) s0f[d]++;
      if (fire_s1[d]) s1f[d]++;
      if (fire_s2[d]) s2f[d]++;
    end
    // SegmentedAddrNext 两条分支各自被打到多少次（用 dup0 采样）
    if (!$isunknown(g_dut.s1_pc_dup_0) && !$isunknown(g_dut.s2_pc_dup_s2_pc_seg_0_value)) begin
      if (g_dut.s2_pc_dup_s2_pc_seg_0_value == g_dut.s1_pc_dup_0[49:24]) seg_hi_same++;
      else                                                              seg_hi_diff++;
      if (g_dut.s2_pc_dup_s2_pc_seg_1_value == g_dut.s1_pc_dup_0[23:12]) seg_mid_same++;
      else                                                              seg_mid_diff++;
      if (g_dut.s3_pc_dup_s3_pc_seg_0_value == g_dut.s2_pc_dup_s2_pc_seg_0_value) s3_hi_same++;
      else                                                                       s3_hi_diff++;
    end
    // MBIST：G1 收窄到 8 位的那 4 个 bore 的 addr / addr_rd
    if (boreChildrenBd_bore_2_addr[7])    mbist_addr_msb[0]++;
    if (boreChildrenBd_bore_2_addr_rd[7]) mbist_addrrd_msb[0]++;
    mbist_addr_or[0]   |= boreChildrenBd_bore_2_addr;
    mbist_addrrd_or[0] |= boreChildrenBd_bore_2_addr_rd;
    if (!$isunknown(g_boreChildrenBd_bore_2_outdata)) mbist_outdata_checks++;
    if (boreChildrenBd_bore_3_addr[7])    mbist_addr_msb[1]++;
    if (boreChildrenBd_bore_3_addr_rd[7]) mbist_addrrd_msb[1]++;
    mbist_addr_or[1]   |= boreChildrenBd_bore_3_addr;
    mbist_addrrd_or[1] |= boreChildrenBd_bore_3_addr_rd;
    if (!$isunknown(g_boreChildrenBd_bore_3_outdata)) mbist_outdata_checks++;
    if (boreChildrenBd_bore_4_addr[7])    mbist_addr_msb[2]++;
    if (boreChildrenBd_bore_4_addr_rd[7]) mbist_addrrd_msb[2]++;
    mbist_addr_or[2]   |= boreChildrenBd_bore_4_addr;
    mbist_addrrd_or[2] |= boreChildrenBd_bore_4_addr_rd;
    if (!$isunknown(g_boreChildrenBd_bore_4_outdata)) mbist_outdata_checks++;
    if (boreChildrenBd_bore_5_addr[7])    mbist_addr_msb[3]++;
    if (boreChildrenBd_bore_5_addr_rd[7]) mbist_addrrd_msb[3]++;
    mbist_addr_or[3]   |= boreChildrenBd_bore_5_addr;
    mbist_addrrd_or[3] |= boreChildrenBd_bore_5_addr_rd;
    if (!$isunknown(g_boreChildrenBd_bore_5_outdata)) mbist_outdata_checks++;
    if (g_io_s1_ready === 1'b1) s1_ready_hi++; else if (g_io_s1_ready === 1'b0) s1_ready_lo++;
    if (g_dut._tage_io_s1_ready   === 1'b0) s1r_lo[0]++;
    if (g_dut._ftb_io_s1_ready    === 1'b0) s1r_lo[1]++;
    if (g_dut._ittage_io_s1_ready === 1'b0) s1r_lo[2]++;
    if (!g_dut._tage_io_s1_ready &&  g_dut._ftb_io_s1_ready &&  g_dut._ittage_io_s1_ready) s1r_only_lo[0]++;
    if ( g_dut._tage_io_s1_ready && !g_dut._ftb_io_s1_ready &&  g_dut._ittage_io_s1_ready) s1r_only_lo[1]++;
    if ( g_dut._tage_io_s1_ready &&  g_dut._ftb_io_s1_ready && !g_dut._ittage_io_s1_ready) s1r_only_lo[2]++;
    if (g_io_out_s1_full_pred_0_br_taken_mask_0 === 1'b1 ||
        g_io_out_s1_full_pred_0_br_taken_mask_1 === 1'b1) btm_hi++;
    if (!$isunknown(g_io_out_last_stage_meta) && g_io_out_last_stage_meta != 0) meta_nz++;
    if (!$isunknown(g_io_perf_0_value) && (g_io_perf_0_value | g_io_perf_1_value |
        g_io_perf_2_value | g_io_perf_3_value | g_io_perf_4_value |
        g_io_perf_5_value | g_io_perf_6_value) != 0) perf_nz++;
  endtask

  int unsigned c;
  // +warmup=<n>（2026-10-03 agent/bpu-tables 加）：前 n 拍不比。initreg 随机初值档下，两侧各自同源的
  // golden 子模块（FTB / RAS 等）里不复位的流水寄存器上电值互不相同（两个实例各摇各的），要等随机激励把它们
  // 写一遍才一致 —— tb 先写后读契约；initreg 0 档默认 0 拍（行为与原 tb 完全相同）。
  int unsigned WARMUP = 0;
  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    if ($value$plusargs("warmup=%d", WARMUP)) begin end
    for (int d = 0; d < 4; d++) begin s0f[d]=0; s1f[d]=0; s2f[d]=0; end
    for (int k = 0; k < 3; k++) begin s1r_lo[k]=0; s1r_only_lo[k]=0; end
    for (int k = 0; k < 4; k++) begin
      mbist_addr_msb[k]=0; mbist_addrrd_msb[k]=0;
      mbist_addr_or[k]=8'h0; mbist_addrrd_or[k]=8'h0;
    end
    reset = 1'b1;
    drive_random_inputs();
    repeat (8) @(posedge clock);
    reset = 1'b0; reset_pulses++;
    for (c = 0; c < NCYCLES; c++) begin
      @(negedge clock);
      // 每 ~4000 拍再复位一次：modified_reset 的一拍脉冲要被反复观测
      if (c != 0 && c % 4000 == 0) reset = 1'b1;
      else if (reset) begin reset = 1'b0; reset_pulses++; end
      drive_random_inputs();
      @(posedge clock);
      #1;
      if (c >= WARMUP) begin
        check_outputs();
        check_hier();
      end
      sample_coverage();
    end

    $display("Composer checks=%0d errors=%0d  hier_checks=%0d hier_errors=%0d",
             checks, errors, hchecks, herrors);
    $display("COV reset_pulses=%0d modified_reset_cycles=%0d", reset_pulses, mres_hi);
    $display("COV fire s0=%p s1=%p s2=%p", s0f, s1f, s2f);
    $display("COV seg_hi same=%0d diff=%0d | seg_mid same=%0d diff=%0d | s3_hi same=%0d diff=%0d",
             seg_hi_same, seg_hi_diff, seg_mid_same, seg_mid_diff, s3_hi_same, s3_hi_diff);
    $display("COV mbist addr_msb=%p addr_rd_msb=%p addr_or=%p addr_rd_or=%p outdata_checks=%0d",
             mbist_addr_msb, mbist_addrrd_msb, mbist_addr_or, mbist_addrrd_or, mbist_outdata_checks);
    $display("COV s1_ready hi=%0d lo=%0d src_lo(tage,ftb,ittage)=%p only_lo=%p | br_taken_mask hi=%0d | meta_nz=%0d | perf_nz=%0d | seg_hi_trap=%0d",
             s1_ready_hi, s1_ready_lo, s1r_lo, s1r_only_lo, btm_hi, meta_nz, perf_nz, seg_hi_trap);

    // ---- 覆盖闸：任一为 0 即判 FAIL（装配层极易假绿）----
    if (reset_pulses < 2 || mres_hi == 0) begin
      $display("COVERAGE HOLE: modified_reset 脉冲没被反复观测");
      $display("TEST FAILED"); $fatal(1);
    end
    for (int d = 0; d < 4; d++)
      if (s0f[d] == 0 || s1f[d] == 0 || s2f[d] == 0) begin
        $display("COVERAGE HOLE: dup %0d 的某一级 fire 从未发生", d);
        $display("TEST FAILED"); $fatal(1);
      end
    if (seg_hi_same == 0 || seg_hi_diff == 0 || seg_mid_same == 0 ||
        seg_mid_diff == 0 || s3_hi_same == 0 || s3_hi_diff == 0) begin
      $display("COVERAGE HOLE: SegmentedAddrNext 的\"变了/没变\"两条分支没都打到");
      $display("TEST FAILED"); $fatal(1);
    end
    for (int k = 0; k < 4; k++)
      if (mbist_addr_msb[k] == 0 || mbist_addrrd_msb[k] == 0 ||
          mbist_addr_or[k] != 8'hff || mbist_addrrd_or[k] != 8'hff) begin
        $display("COVERAGE HOLE: bore%0d 的 8 位 MBIST 地址没被打满（G1 正是把它从 9 位收窄到 8 位）", k+2);
        $display("TEST FAILED"); $fatal(1);
      end
    if (s1_ready_hi == 0 || s1_ready_lo == 0) begin
      $display("COVERAGE HOLE: io_s1_ready 只出现过一种值");
      $display("TEST FAILED"); $fatal(1);
    end
    // 与门的每一路都要被单独压低过：某一路恒 1 时，把它从与门里删掉
    // 也测不出来（阴性对照 M6 就是这么逃掉的）。
    // 每一路都必须被观测为 0 过（否则连它接没接对都不知道）。
    for (int k = 0; k < 3; k++)
      if (s1r_lo[k] == 0) begin
        $display("COVERAGE HOLE: s1_ready 第 %0d 路(0=tage 1=ftb 2=ittage) 全程为 1", k);
        $display("TEST FAILED"); $fatal(1);
      end
    // 更强的一条：只有"只有这一路为 0"的拍才能分辨与门里少了它。
    // tage / ftb 两路做硬闸；ittage 这一路**结构上做不到**——它的
    // io_s1_ready = 5 个 ITTageTable 的 ~powerOnResetState，低电平窗口
    // 完全落在 tage 的窗口里，任何激励都分不开。所以这一项如实打印、
    // 不假装验过：`& ittage` 这一项的正确性由 FM 负责（FM 不做可达性
    // 分析，a&b&c 与 a&b 作为函数就不等价，一定会被抓）。
    for (int k = 0; k < 2; k++)
      if (s1r_only_lo[k] == 0) begin
        $display("COVERAGE HOLE: s1_ready 第 %0d 路没有过\"只有它为 0\"的拍", k);
        $display("TEST FAILED"); $fatal(1);
      end
    if (s1r_only_lo[2] == 0)
      $display("NOTE: ittage 一路无法单独压低（结构性，见上），该项由 FM 覆盖");
    if (seg_hi_trap == 0) begin
      $display("COVERAGE HOLE: 高段比较的定向激励一次都没打出去");
      $display("TEST FAILED"); $fatal(1);
    end
    if (meta_nz == 0 || perf_nz == 0) begin
      $display("COVERAGE HOLE: meta 或 perf 全程为 0 —— 拼接/打拍路径没被激励");
      $display("TEST FAILED"); $fatal(1);
    end
    if (herrors != 0 || hchecks == 0) begin
      $display("TEST FAILED"); $fatal(1);
    end
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
