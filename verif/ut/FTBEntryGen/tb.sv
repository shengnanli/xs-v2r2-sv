// 自动生成：scripts/gen_ftbentrygen.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NVEC = 200000;
  int errors = 0, checks = 0;

  logic [49:0] io_start_addr;
  logic io_old_entry_isCall;
  logic io_old_entry_isRet;
  logic io_old_entry_isJalr;
  logic io_old_entry_valid;
  logic [3:0] io_old_entry_brSlots_0_offset;
  logic io_old_entry_brSlots_0_sharing;
  logic io_old_entry_brSlots_0_valid;
  logic [11:0] io_old_entry_brSlots_0_lower;
  logic [1:0] io_old_entry_brSlots_0_tarStat;
  logic [3:0] io_old_entry_tailSlot_offset;
  logic io_old_entry_tailSlot_sharing;
  logic io_old_entry_tailSlot_valid;
  logic [19:0] io_old_entry_tailSlot_lower;
  logic [1:0] io_old_entry_tailSlot_tarStat;
  logic [3:0] io_old_entry_pftAddr;
  logic io_old_entry_carry;
  logic io_old_entry_last_may_be_rvi_call;
  logic io_old_entry_strong_bias_0;
  logic io_old_entry_strong_bias_1;
  logic io_pd_brMask_0;
  logic io_pd_brMask_1;
  logic io_pd_brMask_2;
  logic io_pd_brMask_3;
  logic io_pd_brMask_4;
  logic io_pd_brMask_5;
  logic io_pd_brMask_6;
  logic io_pd_brMask_7;
  logic io_pd_brMask_8;
  logic io_pd_brMask_9;
  logic io_pd_brMask_10;
  logic io_pd_brMask_11;
  logic io_pd_brMask_12;
  logic io_pd_brMask_13;
  logic io_pd_brMask_14;
  logic io_pd_brMask_15;
  logic io_pd_jmpInfo_valid;
  logic io_pd_jmpInfo_bits_0;
  logic io_pd_jmpInfo_bits_1;
  logic io_pd_jmpInfo_bits_2;
  logic [3:0] io_pd_jmpOffset;
  logic [49:0] io_pd_jalTarget;
  logic io_pd_rvcMask_0;
  logic io_pd_rvcMask_1;
  logic io_pd_rvcMask_2;
  logic io_pd_rvcMask_3;
  logic io_pd_rvcMask_4;
  logic io_pd_rvcMask_5;
  logic io_pd_rvcMask_6;
  logic io_pd_rvcMask_7;
  logic io_pd_rvcMask_8;
  logic io_pd_rvcMask_9;
  logic io_pd_rvcMask_10;
  logic io_pd_rvcMask_11;
  logic io_pd_rvcMask_12;
  logic io_pd_rvcMask_13;
  logic io_pd_rvcMask_14;
  logic io_pd_rvcMask_15;
  logic io_cfiIndex_valid;
  logic [3:0] io_cfiIndex_bits;
  logic [49:0] io_target;
  logic io_hit;
  logic io_mispredict_vec_0;
  logic io_mispredict_vec_1;
  logic io_mispredict_vec_2;
  logic io_mispredict_vec_3;
  logic io_mispredict_vec_4;
  logic io_mispredict_vec_5;
  logic io_mispredict_vec_6;
  logic io_mispredict_vec_7;
  logic io_mispredict_vec_8;
  logic io_mispredict_vec_9;
  logic io_mispredict_vec_10;
  logic io_mispredict_vec_11;
  logic io_mispredict_vec_12;
  logic io_mispredict_vec_13;
  logic io_mispredict_vec_14;
  logic io_mispredict_vec_15;
  wire g_io_new_entry_isCall;
  wire i_io_new_entry_isCall;
  wire g_io_new_entry_isRet;
  wire i_io_new_entry_isRet;
  wire g_io_new_entry_isJalr;
  wire i_io_new_entry_isJalr;
  wire g_io_new_entry_valid;
  wire i_io_new_entry_valid;
  wire [3:0] g_io_new_entry_brSlots_0_offset;
  wire [3:0] i_io_new_entry_brSlots_0_offset;
  wire g_io_new_entry_brSlots_0_sharing;
  wire i_io_new_entry_brSlots_0_sharing;
  wire g_io_new_entry_brSlots_0_valid;
  wire i_io_new_entry_brSlots_0_valid;
  wire [11:0] g_io_new_entry_brSlots_0_lower;
  wire [11:0] i_io_new_entry_brSlots_0_lower;
  wire [1:0] g_io_new_entry_brSlots_0_tarStat;
  wire [1:0] i_io_new_entry_brSlots_0_tarStat;
  wire [3:0] g_io_new_entry_tailSlot_offset;
  wire [3:0] i_io_new_entry_tailSlot_offset;
  wire g_io_new_entry_tailSlot_sharing;
  wire i_io_new_entry_tailSlot_sharing;
  wire g_io_new_entry_tailSlot_valid;
  wire i_io_new_entry_tailSlot_valid;
  wire [19:0] g_io_new_entry_tailSlot_lower;
  wire [19:0] i_io_new_entry_tailSlot_lower;
  wire [1:0] g_io_new_entry_tailSlot_tarStat;
  wire [1:0] i_io_new_entry_tailSlot_tarStat;
  wire [3:0] g_io_new_entry_pftAddr;
  wire [3:0] i_io_new_entry_pftAddr;
  wire g_io_new_entry_carry;
  wire i_io_new_entry_carry;
  wire g_io_new_entry_last_may_be_rvi_call;
  wire i_io_new_entry_last_may_be_rvi_call;
  wire g_io_new_entry_strong_bias_0;
  wire i_io_new_entry_strong_bias_0;
  wire g_io_new_entry_strong_bias_1;
  wire i_io_new_entry_strong_bias_1;
  wire g_io_taken_mask_0;
  wire i_io_taken_mask_0;
  wire g_io_taken_mask_1;
  wire i_io_taken_mask_1;
  wire g_io_jmp_taken;
  wire i_io_jmp_taken;
  wire g_io_mispred_mask_0;
  wire i_io_mispred_mask_0;
  wire g_io_mispred_mask_1;
  wire i_io_mispred_mask_1;
  wire g_io_mispred_mask_2;
  wire i_io_mispred_mask_2;
  wire g_io_is_init_entry;
  wire i_io_is_init_entry;
  wire g_io_is_old_entry;
  wire i_io_is_old_entry;
  wire g_io_is_new_br;
  wire i_io_is_new_br;
  wire g_io_is_jalr_target_modified;
  wire i_io_is_jalr_target_modified;
  wire g_io_is_strong_bias_modified;
  wire i_io_is_strong_bias_modified;
  wire g_io_is_br_full;
  wire i_io_is_br_full;
  FTBEntryGen    u_g (.io_start_addr(io_start_addr), .io_old_entry_isCall(io_old_entry_isCall), .io_old_entry_isRet(io_old_entry_isRet), .io_old_entry_isJalr(io_old_entry_isJalr), .io_old_entry_valid(io_old_entry_valid), .io_old_entry_brSlots_0_offset(io_old_entry_brSlots_0_offset), .io_old_entry_brSlots_0_sharing(io_old_entry_brSlots_0_sharing), .io_old_entry_brSlots_0_valid(io_old_entry_brSlots_0_valid), .io_old_entry_brSlots_0_lower(io_old_entry_brSlots_0_lower), .io_old_entry_brSlots_0_tarStat(io_old_entry_brSlots_0_tarStat), .io_old_entry_tailSlot_offset(io_old_entry_tailSlot_offset), .io_old_entry_tailSlot_sharing(io_old_entry_tailSlot_sharing), .io_old_entry_tailSlot_valid(io_old_entry_tailSlot_valid), .io_old_entry_tailSlot_lower(io_old_entry_tailSlot_lower), .io_old_entry_tailSlot_tarStat(io_old_entry_tailSlot_tarStat), .io_old_entry_pftAddr(io_old_entry_pftAddr), .io_old_entry_carry(io_old_entry_carry), .io_old_entry_last_may_be_rvi_call(io_old_entry_last_may_be_rvi_call), .io_old_entry_strong_bias_0(io_old_entry_strong_bias_0), .io_old_entry_strong_bias_1(io_old_entry_strong_bias_1), .io_pd_brMask_0(io_pd_brMask_0), .io_pd_brMask_1(io_pd_brMask_1), .io_pd_brMask_2(io_pd_brMask_2), .io_pd_brMask_3(io_pd_brMask_3), .io_pd_brMask_4(io_pd_brMask_4), .io_pd_brMask_5(io_pd_brMask_5), .io_pd_brMask_6(io_pd_brMask_6), .io_pd_brMask_7(io_pd_brMask_7), .io_pd_brMask_8(io_pd_brMask_8), .io_pd_brMask_9(io_pd_brMask_9), .io_pd_brMask_10(io_pd_brMask_10), .io_pd_brMask_11(io_pd_brMask_11), .io_pd_brMask_12(io_pd_brMask_12), .io_pd_brMask_13(io_pd_brMask_13), .io_pd_brMask_14(io_pd_brMask_14), .io_pd_brMask_15(io_pd_brMask_15), .io_pd_jmpInfo_valid(io_pd_jmpInfo_valid), .io_pd_jmpInfo_bits_0(io_pd_jmpInfo_bits_0), .io_pd_jmpInfo_bits_1(io_pd_jmpInfo_bits_1), .io_pd_jmpInfo_bits_2(io_pd_jmpInfo_bits_2), .io_pd_jmpOffset(io_pd_jmpOffset), .io_pd_jalTarget(io_pd_jalTarget), .io_pd_rvcMask_0(io_pd_rvcMask_0), .io_pd_rvcMask_1(io_pd_rvcMask_1), .io_pd_rvcMask_2(io_pd_rvcMask_2), .io_pd_rvcMask_3(io_pd_rvcMask_3), .io_pd_rvcMask_4(io_pd_rvcMask_4), .io_pd_rvcMask_5(io_pd_rvcMask_5), .io_pd_rvcMask_6(io_pd_rvcMask_6), .io_pd_rvcMask_7(io_pd_rvcMask_7), .io_pd_rvcMask_8(io_pd_rvcMask_8), .io_pd_rvcMask_9(io_pd_rvcMask_9), .io_pd_rvcMask_10(io_pd_rvcMask_10), .io_pd_rvcMask_11(io_pd_rvcMask_11), .io_pd_rvcMask_12(io_pd_rvcMask_12), .io_pd_rvcMask_13(io_pd_rvcMask_13), .io_pd_rvcMask_14(io_pd_rvcMask_14), .io_pd_rvcMask_15(io_pd_rvcMask_15), .io_cfiIndex_valid(io_cfiIndex_valid), .io_cfiIndex_bits(io_cfiIndex_bits), .io_target(io_target), .io_hit(io_hit), .io_mispredict_vec_0(io_mispredict_vec_0), .io_mispredict_vec_1(io_mispredict_vec_1), .io_mispredict_vec_2(io_mispredict_vec_2), .io_mispredict_vec_3(io_mispredict_vec_3), .io_mispredict_vec_4(io_mispredict_vec_4), .io_mispredict_vec_5(io_mispredict_vec_5), .io_mispredict_vec_6(io_mispredict_vec_6), .io_mispredict_vec_7(io_mispredict_vec_7), .io_mispredict_vec_8(io_mispredict_vec_8), .io_mispredict_vec_9(io_mispredict_vec_9), .io_mispredict_vec_10(io_mispredict_vec_10), .io_mispredict_vec_11(io_mispredict_vec_11), .io_mispredict_vec_12(io_mispredict_vec_12), .io_mispredict_vec_13(io_mispredict_vec_13), .io_mispredict_vec_14(io_mispredict_vec_14), .io_mispredict_vec_15(io_mispredict_vec_15), .io_new_entry_isCall(g_io_new_entry_isCall), .io_new_entry_isRet(g_io_new_entry_isRet), .io_new_entry_isJalr(g_io_new_entry_isJalr), .io_new_entry_valid(g_io_new_entry_valid), .io_new_entry_brSlots_0_offset(g_io_new_entry_brSlots_0_offset), .io_new_entry_brSlots_0_sharing(g_io_new_entry_brSlots_0_sharing), .io_new_entry_brSlots_0_valid(g_io_new_entry_brSlots_0_valid), .io_new_entry_brSlots_0_lower(g_io_new_entry_brSlots_0_lower), .io_new_entry_brSlots_0_tarStat(g_io_new_entry_brSlots_0_tarStat), .io_new_entry_tailSlot_offset(g_io_new_entry_tailSlot_offset), .io_new_entry_tailSlot_sharing(g_io_new_entry_tailSlot_sharing), .io_new_entry_tailSlot_valid(g_io_new_entry_tailSlot_valid), .io_new_entry_tailSlot_lower(g_io_new_entry_tailSlot_lower), .io_new_entry_tailSlot_tarStat(g_io_new_entry_tailSlot_tarStat), .io_new_entry_pftAddr(g_io_new_entry_pftAddr), .io_new_entry_carry(g_io_new_entry_carry), .io_new_entry_last_may_be_rvi_call(g_io_new_entry_last_may_be_rvi_call), .io_new_entry_strong_bias_0(g_io_new_entry_strong_bias_0), .io_new_entry_strong_bias_1(g_io_new_entry_strong_bias_1), .io_taken_mask_0(g_io_taken_mask_0), .io_taken_mask_1(g_io_taken_mask_1), .io_jmp_taken(g_io_jmp_taken), .io_mispred_mask_0(g_io_mispred_mask_0), .io_mispred_mask_1(g_io_mispred_mask_1), .io_mispred_mask_2(g_io_mispred_mask_2), .io_is_init_entry(g_io_is_init_entry), .io_is_old_entry(g_io_is_old_entry), .io_is_new_br(g_io_is_new_br), .io_is_jalr_target_modified(g_io_is_jalr_target_modified), .io_is_strong_bias_modified(g_io_is_strong_bias_modified), .io_is_br_full(g_io_is_br_full));
  FTBEntryGen_xs u_i (.io_start_addr(io_start_addr), .io_old_entry_isCall(io_old_entry_isCall), .io_old_entry_isRet(io_old_entry_isRet), .io_old_entry_isJalr(io_old_entry_isJalr), .io_old_entry_valid(io_old_entry_valid), .io_old_entry_brSlots_0_offset(io_old_entry_brSlots_0_offset), .io_old_entry_brSlots_0_sharing(io_old_entry_brSlots_0_sharing), .io_old_entry_brSlots_0_valid(io_old_entry_brSlots_0_valid), .io_old_entry_brSlots_0_lower(io_old_entry_brSlots_0_lower), .io_old_entry_brSlots_0_tarStat(io_old_entry_brSlots_0_tarStat), .io_old_entry_tailSlot_offset(io_old_entry_tailSlot_offset), .io_old_entry_tailSlot_sharing(io_old_entry_tailSlot_sharing), .io_old_entry_tailSlot_valid(io_old_entry_tailSlot_valid), .io_old_entry_tailSlot_lower(io_old_entry_tailSlot_lower), .io_old_entry_tailSlot_tarStat(io_old_entry_tailSlot_tarStat), .io_old_entry_pftAddr(io_old_entry_pftAddr), .io_old_entry_carry(io_old_entry_carry), .io_old_entry_last_may_be_rvi_call(io_old_entry_last_may_be_rvi_call), .io_old_entry_strong_bias_0(io_old_entry_strong_bias_0), .io_old_entry_strong_bias_1(io_old_entry_strong_bias_1), .io_pd_brMask_0(io_pd_brMask_0), .io_pd_brMask_1(io_pd_brMask_1), .io_pd_brMask_2(io_pd_brMask_2), .io_pd_brMask_3(io_pd_brMask_3), .io_pd_brMask_4(io_pd_brMask_4), .io_pd_brMask_5(io_pd_brMask_5), .io_pd_brMask_6(io_pd_brMask_6), .io_pd_brMask_7(io_pd_brMask_7), .io_pd_brMask_8(io_pd_brMask_8), .io_pd_brMask_9(io_pd_brMask_9), .io_pd_brMask_10(io_pd_brMask_10), .io_pd_brMask_11(io_pd_brMask_11), .io_pd_brMask_12(io_pd_brMask_12), .io_pd_brMask_13(io_pd_brMask_13), .io_pd_brMask_14(io_pd_brMask_14), .io_pd_brMask_15(io_pd_brMask_15), .io_pd_jmpInfo_valid(io_pd_jmpInfo_valid), .io_pd_jmpInfo_bits_0(io_pd_jmpInfo_bits_0), .io_pd_jmpInfo_bits_1(io_pd_jmpInfo_bits_1), .io_pd_jmpInfo_bits_2(io_pd_jmpInfo_bits_2), .io_pd_jmpOffset(io_pd_jmpOffset), .io_pd_jalTarget(io_pd_jalTarget), .io_pd_rvcMask_0(io_pd_rvcMask_0), .io_pd_rvcMask_1(io_pd_rvcMask_1), .io_pd_rvcMask_2(io_pd_rvcMask_2), .io_pd_rvcMask_3(io_pd_rvcMask_3), .io_pd_rvcMask_4(io_pd_rvcMask_4), .io_pd_rvcMask_5(io_pd_rvcMask_5), .io_pd_rvcMask_6(io_pd_rvcMask_6), .io_pd_rvcMask_7(io_pd_rvcMask_7), .io_pd_rvcMask_8(io_pd_rvcMask_8), .io_pd_rvcMask_9(io_pd_rvcMask_9), .io_pd_rvcMask_10(io_pd_rvcMask_10), .io_pd_rvcMask_11(io_pd_rvcMask_11), .io_pd_rvcMask_12(io_pd_rvcMask_12), .io_pd_rvcMask_13(io_pd_rvcMask_13), .io_pd_rvcMask_14(io_pd_rvcMask_14), .io_pd_rvcMask_15(io_pd_rvcMask_15), .io_cfiIndex_valid(io_cfiIndex_valid), .io_cfiIndex_bits(io_cfiIndex_bits), .io_target(io_target), .io_hit(io_hit), .io_mispredict_vec_0(io_mispredict_vec_0), .io_mispredict_vec_1(io_mispredict_vec_1), .io_mispredict_vec_2(io_mispredict_vec_2), .io_mispredict_vec_3(io_mispredict_vec_3), .io_mispredict_vec_4(io_mispredict_vec_4), .io_mispredict_vec_5(io_mispredict_vec_5), .io_mispredict_vec_6(io_mispredict_vec_6), .io_mispredict_vec_7(io_mispredict_vec_7), .io_mispredict_vec_8(io_mispredict_vec_8), .io_mispredict_vec_9(io_mispredict_vec_9), .io_mispredict_vec_10(io_mispredict_vec_10), .io_mispredict_vec_11(io_mispredict_vec_11), .io_mispredict_vec_12(io_mispredict_vec_12), .io_mispredict_vec_13(io_mispredict_vec_13), .io_mispredict_vec_14(io_mispredict_vec_14), .io_mispredict_vec_15(io_mispredict_vec_15), .io_new_entry_isCall(i_io_new_entry_isCall), .io_new_entry_isRet(i_io_new_entry_isRet), .io_new_entry_isJalr(i_io_new_entry_isJalr), .io_new_entry_valid(i_io_new_entry_valid), .io_new_entry_brSlots_0_offset(i_io_new_entry_brSlots_0_offset), .io_new_entry_brSlots_0_sharing(i_io_new_entry_brSlots_0_sharing), .io_new_entry_brSlots_0_valid(i_io_new_entry_brSlots_0_valid), .io_new_entry_brSlots_0_lower(i_io_new_entry_brSlots_0_lower), .io_new_entry_brSlots_0_tarStat(i_io_new_entry_brSlots_0_tarStat), .io_new_entry_tailSlot_offset(i_io_new_entry_tailSlot_offset), .io_new_entry_tailSlot_sharing(i_io_new_entry_tailSlot_sharing), .io_new_entry_tailSlot_valid(i_io_new_entry_tailSlot_valid), .io_new_entry_tailSlot_lower(i_io_new_entry_tailSlot_lower), .io_new_entry_tailSlot_tarStat(i_io_new_entry_tailSlot_tarStat), .io_new_entry_pftAddr(i_io_new_entry_pftAddr), .io_new_entry_carry(i_io_new_entry_carry), .io_new_entry_last_may_be_rvi_call(i_io_new_entry_last_may_be_rvi_call), .io_new_entry_strong_bias_0(i_io_new_entry_strong_bias_0), .io_new_entry_strong_bias_1(i_io_new_entry_strong_bias_1), .io_taken_mask_0(i_io_taken_mask_0), .io_taken_mask_1(i_io_taken_mask_1), .io_jmp_taken(i_io_jmp_taken), .io_mispred_mask_0(i_io_mispred_mask_0), .io_mispred_mask_1(i_io_mispred_mask_1), .io_mispred_mask_2(i_io_mispred_mask_2), .io_is_init_entry(i_io_is_init_entry), .io_is_old_entry(i_io_is_old_entry), .io_is_new_br(i_io_is_new_br), .io_is_jalr_target_modified(i_io_is_jalr_target_modified), .io_is_strong_bias_modified(i_io_is_strong_bias_modified), .io_is_br_full(i_io_is_br_full));
  initial begin
    for (int t = 0; t < NVEC; t++) begin
      io_start_addr = 50'({$urandom(), $urandom()});
      io_old_entry_isCall = 1'($urandom);
      io_old_entry_isRet = 1'($urandom);
      io_old_entry_isJalr = 1'($urandom);
      io_old_entry_valid = 1'($urandom);
      io_old_entry_brSlots_0_offset = 4'($urandom);
      io_old_entry_brSlots_0_sharing = 1'($urandom);
      io_old_entry_brSlots_0_valid = 1'($urandom);
      io_old_entry_brSlots_0_lower = 12'($urandom);
      io_old_entry_brSlots_0_tarStat = 2'($urandom);
      io_old_entry_tailSlot_offset = 4'($urandom);
      io_old_entry_tailSlot_sharing = 1'($urandom);
      io_old_entry_tailSlot_valid = 1'($urandom);
      io_old_entry_tailSlot_lower = 20'($urandom);
      io_old_entry_tailSlot_tarStat = 2'($urandom);
      io_old_entry_pftAddr = 4'($urandom);
      io_old_entry_carry = 1'($urandom);
      io_old_entry_last_may_be_rvi_call = 1'($urandom);
      io_old_entry_strong_bias_0 = 1'($urandom);
      io_old_entry_strong_bias_1 = 1'($urandom);
      io_pd_brMask_0 = 1'($urandom);
      io_pd_brMask_1 = 1'($urandom);
      io_pd_brMask_2 = 1'($urandom);
      io_pd_brMask_3 = 1'($urandom);
      io_pd_brMask_4 = 1'($urandom);
      io_pd_brMask_5 = 1'($urandom);
      io_pd_brMask_6 = 1'($urandom);
      io_pd_brMask_7 = 1'($urandom);
      io_pd_brMask_8 = 1'($urandom);
      io_pd_brMask_9 = 1'($urandom);
      io_pd_brMask_10 = 1'($urandom);
      io_pd_brMask_11 = 1'($urandom);
      io_pd_brMask_12 = 1'($urandom);
      io_pd_brMask_13 = 1'($urandom);
      io_pd_brMask_14 = 1'($urandom);
      io_pd_brMask_15 = 1'($urandom);
      io_pd_jmpInfo_valid = 1'($urandom);
      io_pd_jmpInfo_bits_0 = 1'($urandom);
      io_pd_jmpInfo_bits_1 = 1'($urandom);
      io_pd_jmpInfo_bits_2 = 1'($urandom);
      io_pd_jmpOffset = 4'($urandom);
      io_pd_jalTarget = 50'({$urandom(), $urandom()});
      io_pd_rvcMask_0 = 1'($urandom);
      io_pd_rvcMask_1 = 1'($urandom);
      io_pd_rvcMask_2 = 1'($urandom);
      io_pd_rvcMask_3 = 1'($urandom);
      io_pd_rvcMask_4 = 1'($urandom);
      io_pd_rvcMask_5 = 1'($urandom);
      io_pd_rvcMask_6 = 1'($urandom);
      io_pd_rvcMask_7 = 1'($urandom);
      io_pd_rvcMask_8 = 1'($urandom);
      io_pd_rvcMask_9 = 1'($urandom);
      io_pd_rvcMask_10 = 1'($urandom);
      io_pd_rvcMask_11 = 1'($urandom);
      io_pd_rvcMask_12 = 1'($urandom);
      io_pd_rvcMask_13 = 1'($urandom);
      io_pd_rvcMask_14 = 1'($urandom);
      io_pd_rvcMask_15 = 1'($urandom);
      io_cfiIndex_valid = 1'($urandom);
      io_cfiIndex_bits = 4'($urandom);
      io_target = 50'({$urandom(), $urandom()});
      io_hit = 1'($urandom);
      io_mispredict_vec_0 = 1'($urandom);
      io_mispredict_vec_1 = 1'($urandom);
      io_mispredict_vec_2 = 1'($urandom);
      io_mispredict_vec_3 = 1'($urandom);
      io_mispredict_vec_4 = 1'($urandom);
      io_mispredict_vec_5 = 1'($urandom);
      io_mispredict_vec_6 = 1'($urandom);
      io_mispredict_vec_7 = 1'($urandom);
      io_mispredict_vec_8 = 1'($urandom);
      io_mispredict_vec_9 = 1'($urandom);
      io_mispredict_vec_10 = 1'($urandom);
      io_mispredict_vec_11 = 1'($urandom);
      io_mispredict_vec_12 = 1'($urandom);
      io_mispredict_vec_13 = 1'($urandom);
      io_mispredict_vec_14 = 1'($urandom);
      io_mispredict_vec_15 = 1'($urandom);
      #1; checks++;
      if (g_io_new_entry_isCall !== i_io_new_entry_isCall) begin errors++;
        if (errors<=20) $display("vec %0d io_new_entry_isCall: g=%h i=%h", t, g_io_new_entry_isCall, i_io_new_entry_isCall); end
      if (g_io_new_entry_isRet !== i_io_new_entry_isRet) begin errors++;
        if (errors<=20) $display("vec %0d io_new_entry_isRet: g=%h i=%h", t, g_io_new_entry_isRet, i_io_new_entry_isRet); end
      if (g_io_new_entry_isJalr !== i_io_new_entry_isJalr) begin errors++;
        if (errors<=20) $display("vec %0d io_new_entry_isJalr: g=%h i=%h", t, g_io_new_entry_isJalr, i_io_new_entry_isJalr); end
      if (g_io_new_entry_valid !== i_io_new_entry_valid) begin errors++;
        if (errors<=20) $display("vec %0d io_new_entry_valid: g=%h i=%h", t, g_io_new_entry_valid, i_io_new_entry_valid); end
      if (g_io_new_entry_brSlots_0_offset !== i_io_new_entry_brSlots_0_offset) begin errors++;
        if (errors<=20) $display("vec %0d io_new_entry_brSlots_0_offset: g=%h i=%h", t, g_io_new_entry_brSlots_0_offset, i_io_new_entry_brSlots_0_offset); end
      if (g_io_new_entry_brSlots_0_sharing !== i_io_new_entry_brSlots_0_sharing) begin errors++;
        if (errors<=20) $display("vec %0d io_new_entry_brSlots_0_sharing: g=%h i=%h", t, g_io_new_entry_brSlots_0_sharing, i_io_new_entry_brSlots_0_sharing); end
      if (g_io_new_entry_brSlots_0_valid !== i_io_new_entry_brSlots_0_valid) begin errors++;
        if (errors<=20) $display("vec %0d io_new_entry_brSlots_0_valid: g=%h i=%h", t, g_io_new_entry_brSlots_0_valid, i_io_new_entry_brSlots_0_valid); end
      if (g_io_new_entry_brSlots_0_lower !== i_io_new_entry_brSlots_0_lower) begin errors++;
        if (errors<=20) $display("vec %0d io_new_entry_brSlots_0_lower: g=%h i=%h", t, g_io_new_entry_brSlots_0_lower, i_io_new_entry_brSlots_0_lower); end
      if (g_io_new_entry_brSlots_0_tarStat !== i_io_new_entry_brSlots_0_tarStat) begin errors++;
        if (errors<=20) $display("vec %0d io_new_entry_brSlots_0_tarStat: g=%h i=%h", t, g_io_new_entry_brSlots_0_tarStat, i_io_new_entry_brSlots_0_tarStat); end
      if (g_io_new_entry_tailSlot_offset !== i_io_new_entry_tailSlot_offset) begin errors++;
        if (errors<=20) $display("vec %0d io_new_entry_tailSlot_offset: g=%h i=%h", t, g_io_new_entry_tailSlot_offset, i_io_new_entry_tailSlot_offset); end
      if (g_io_new_entry_tailSlot_sharing !== i_io_new_entry_tailSlot_sharing) begin errors++;
        if (errors<=20) $display("vec %0d io_new_entry_tailSlot_sharing: g=%h i=%h", t, g_io_new_entry_tailSlot_sharing, i_io_new_entry_tailSlot_sharing); end
      if (g_io_new_entry_tailSlot_valid !== i_io_new_entry_tailSlot_valid) begin errors++;
        if (errors<=20) $display("vec %0d io_new_entry_tailSlot_valid: g=%h i=%h", t, g_io_new_entry_tailSlot_valid, i_io_new_entry_tailSlot_valid); end
      if (g_io_new_entry_tailSlot_lower !== i_io_new_entry_tailSlot_lower) begin errors++;
        if (errors<=20) $display("vec %0d io_new_entry_tailSlot_lower: g=%h i=%h", t, g_io_new_entry_tailSlot_lower, i_io_new_entry_tailSlot_lower); end
      if (g_io_new_entry_tailSlot_tarStat !== i_io_new_entry_tailSlot_tarStat) begin errors++;
        if (errors<=20) $display("vec %0d io_new_entry_tailSlot_tarStat: g=%h i=%h", t, g_io_new_entry_tailSlot_tarStat, i_io_new_entry_tailSlot_tarStat); end
      if (g_io_new_entry_pftAddr !== i_io_new_entry_pftAddr) begin errors++;
        if (errors<=20) $display("vec %0d io_new_entry_pftAddr: g=%h i=%h", t, g_io_new_entry_pftAddr, i_io_new_entry_pftAddr); end
      if (g_io_new_entry_carry !== i_io_new_entry_carry) begin errors++;
        if (errors<=20) $display("vec %0d io_new_entry_carry: g=%h i=%h", t, g_io_new_entry_carry, i_io_new_entry_carry); end
      if (g_io_new_entry_last_may_be_rvi_call !== i_io_new_entry_last_may_be_rvi_call) begin errors++;
        if (errors<=20) $display("vec %0d io_new_entry_last_may_be_rvi_call: g=%h i=%h", t, g_io_new_entry_last_may_be_rvi_call, i_io_new_entry_last_may_be_rvi_call); end
      if (g_io_new_entry_strong_bias_0 !== i_io_new_entry_strong_bias_0) begin errors++;
        if (errors<=20) $display("vec %0d io_new_entry_strong_bias_0: g=%h i=%h", t, g_io_new_entry_strong_bias_0, i_io_new_entry_strong_bias_0); end
      if (g_io_new_entry_strong_bias_1 !== i_io_new_entry_strong_bias_1) begin errors++;
        if (errors<=20) $display("vec %0d io_new_entry_strong_bias_1: g=%h i=%h", t, g_io_new_entry_strong_bias_1, i_io_new_entry_strong_bias_1); end
      if (g_io_taken_mask_0 !== i_io_taken_mask_0) begin errors++;
        if (errors<=20) $display("vec %0d io_taken_mask_0: g=%h i=%h", t, g_io_taken_mask_0, i_io_taken_mask_0); end
      if (g_io_taken_mask_1 !== i_io_taken_mask_1) begin errors++;
        if (errors<=20) $display("vec %0d io_taken_mask_1: g=%h i=%h", t, g_io_taken_mask_1, i_io_taken_mask_1); end
      if (g_io_jmp_taken !== i_io_jmp_taken) begin errors++;
        if (errors<=20) $display("vec %0d io_jmp_taken: g=%h i=%h", t, g_io_jmp_taken, i_io_jmp_taken); end
      if (g_io_mispred_mask_0 !== i_io_mispred_mask_0) begin errors++;
        if (errors<=20) $display("vec %0d io_mispred_mask_0: g=%h i=%h", t, g_io_mispred_mask_0, i_io_mispred_mask_0); end
      if (g_io_mispred_mask_1 !== i_io_mispred_mask_1) begin errors++;
        if (errors<=20) $display("vec %0d io_mispred_mask_1: g=%h i=%h", t, g_io_mispred_mask_1, i_io_mispred_mask_1); end
      if (g_io_mispred_mask_2 !== i_io_mispred_mask_2) begin errors++;
        if (errors<=20) $display("vec %0d io_mispred_mask_2: g=%h i=%h", t, g_io_mispred_mask_2, i_io_mispred_mask_2); end
      if (g_io_is_init_entry !== i_io_is_init_entry) begin errors++;
        if (errors<=20) $display("vec %0d io_is_init_entry: g=%h i=%h", t, g_io_is_init_entry, i_io_is_init_entry); end
      if (g_io_is_old_entry !== i_io_is_old_entry) begin errors++;
        if (errors<=20) $display("vec %0d io_is_old_entry: g=%h i=%h", t, g_io_is_old_entry, i_io_is_old_entry); end
      if (g_io_is_new_br !== i_io_is_new_br) begin errors++;
        if (errors<=20) $display("vec %0d io_is_new_br: g=%h i=%h", t, g_io_is_new_br, i_io_is_new_br); end
      if (g_io_is_jalr_target_modified !== i_io_is_jalr_target_modified) begin errors++;
        if (errors<=20) $display("vec %0d io_is_jalr_target_modified: g=%h i=%h", t, g_io_is_jalr_target_modified, i_io_is_jalr_target_modified); end
      if (g_io_is_strong_bias_modified !== i_io_is_strong_bias_modified) begin errors++;
        if (errors<=20) $display("vec %0d io_is_strong_bias_modified: g=%h i=%h", t, g_io_is_strong_bias_modified, i_io_is_strong_bias_modified); end
      if (g_io_is_br_full !== i_io_is_br_full) begin errors++;
        if (errors<=20) $display("vec %0d io_is_br_full: g=%h i=%h", t, g_io_is_br_full, i_io_is_br_full); end
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
