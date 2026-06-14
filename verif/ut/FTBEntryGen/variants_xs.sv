// FTBEntryGen 包装层（golden 同名扁平端口 ↔ xs_FTBEntryGen 的 ftb_entry_t struct）
// 仅做机械的端口打包/拆包，供 FM 对比与 ST 替换。
module FTBEntryGen_xs
  import xs_ftb_pkg::*;
(
  input  [49:0] io_start_addr,
  input         io_old_entry_isCall,
  input         io_old_entry_isRet,
  input         io_old_entry_isJalr,
  input         io_old_entry_valid,
  input  [3:0]  io_old_entry_brSlots_0_offset,
  input         io_old_entry_brSlots_0_sharing,
  input         io_old_entry_brSlots_0_valid,
  input  [11:0] io_old_entry_brSlots_0_lower,
  input  [1:0]  io_old_entry_brSlots_0_tarStat,
  input  [3:0]  io_old_entry_tailSlot_offset,
  input         io_old_entry_tailSlot_sharing,
  input         io_old_entry_tailSlot_valid,
  input  [19:0] io_old_entry_tailSlot_lower,
  input  [1:0]  io_old_entry_tailSlot_tarStat,
  input  [3:0]  io_old_entry_pftAddr,
  input         io_old_entry_carry,
  input         io_old_entry_last_may_be_rvi_call,
  input         io_old_entry_strong_bias_0,
  input         io_old_entry_strong_bias_1,
  input         io_pd_brMask_0, io_pd_brMask_1, io_pd_brMask_2, io_pd_brMask_3,
  input         io_pd_brMask_4, io_pd_brMask_5, io_pd_brMask_6, io_pd_brMask_7,
  input         io_pd_brMask_8, io_pd_brMask_9, io_pd_brMask_10, io_pd_brMask_11,
  input         io_pd_brMask_12, io_pd_brMask_13, io_pd_brMask_14, io_pd_brMask_15,
  input         io_pd_jmpInfo_valid,
  input         io_pd_jmpInfo_bits_0, io_pd_jmpInfo_bits_1, io_pd_jmpInfo_bits_2,
  input  [3:0]  io_pd_jmpOffset,
  input  [49:0] io_pd_jalTarget,
  input         io_pd_rvcMask_0, io_pd_rvcMask_1, io_pd_rvcMask_2, io_pd_rvcMask_3,
  input         io_pd_rvcMask_4, io_pd_rvcMask_5, io_pd_rvcMask_6, io_pd_rvcMask_7,
  input         io_pd_rvcMask_8, io_pd_rvcMask_9, io_pd_rvcMask_10, io_pd_rvcMask_11,
  input         io_pd_rvcMask_12, io_pd_rvcMask_13, io_pd_rvcMask_14, io_pd_rvcMask_15,
  input         io_cfiIndex_valid,
  input  [3:0]  io_cfiIndex_bits,
  input  [49:0] io_target,
  input         io_hit,
  input         io_mispredict_vec_0, io_mispredict_vec_1, io_mispredict_vec_2, io_mispredict_vec_3,
  input         io_mispredict_vec_4, io_mispredict_vec_5, io_mispredict_vec_6, io_mispredict_vec_7,
  input         io_mispredict_vec_8, io_mispredict_vec_9, io_mispredict_vec_10, io_mispredict_vec_11,
  input         io_mispredict_vec_12, io_mispredict_vec_13, io_mispredict_vec_14, io_mispredict_vec_15,
  output        io_new_entry_isCall,
  output        io_new_entry_isRet,
  output        io_new_entry_isJalr,
  output        io_new_entry_valid,
  output [3:0]  io_new_entry_brSlots_0_offset,
  output        io_new_entry_brSlots_0_sharing,
  output        io_new_entry_brSlots_0_valid,
  output [11:0] io_new_entry_brSlots_0_lower,
  output [1:0]  io_new_entry_brSlots_0_tarStat,
  output [3:0]  io_new_entry_tailSlot_offset,
  output        io_new_entry_tailSlot_sharing,
  output        io_new_entry_tailSlot_valid,
  output [19:0] io_new_entry_tailSlot_lower,
  output [1:0]  io_new_entry_tailSlot_tarStat,
  output [3:0]  io_new_entry_pftAddr,
  output        io_new_entry_carry,
  output        io_new_entry_last_may_be_rvi_call,
  output        io_new_entry_strong_bias_0,
  output        io_new_entry_strong_bias_1,
  output        io_taken_mask_0,
  output        io_taken_mask_1,
  output        io_jmp_taken,
  output        io_mispred_mask_0,
  output        io_mispred_mask_1,
  output        io_mispred_mask_2,
  output        io_is_init_entry,
  output        io_is_old_entry,
  output        io_is_new_br,
  output        io_is_jalr_target_modified,
  output        io_is_strong_bias_modified,
  output        io_is_br_full
);
  // flat → struct（old_entry）
  ftb_entry_t old_e;
  assign old_e.valid                = io_old_entry_valid;
  assign old_e.brSlot.offset        = io_old_entry_brSlots_0_offset;
  assign old_e.brSlot.sharing       = io_old_entry_brSlots_0_sharing;
  assign old_e.brSlot.valid         = io_old_entry_brSlots_0_valid;
  assign old_e.brSlot.lower         = {8'b0, io_old_entry_brSlots_0_lower}; // br lower 12→20 零扩展
  assign old_e.brSlot.tarStat       = io_old_entry_brSlots_0_tarStat;
  assign old_e.tailSlot.offset      = io_old_entry_tailSlot_offset;
  assign old_e.tailSlot.sharing     = io_old_entry_tailSlot_sharing;
  assign old_e.tailSlot.valid       = io_old_entry_tailSlot_valid;
  assign old_e.tailSlot.lower       = io_old_entry_tailSlot_lower;
  assign old_e.tailSlot.tarStat     = io_old_entry_tailSlot_tarStat;
  assign old_e.pftAddr              = io_old_entry_pftAddr;
  assign old_e.carry                = io_old_entry_carry;
  assign old_e.isCall               = io_old_entry_isCall;
  assign old_e.isRet                = io_old_entry_isRet;
  assign old_e.isJalr               = io_old_entry_isJalr;
  assign old_e.last_may_be_rvi_call = io_old_entry_last_may_be_rvi_call;
  assign old_e.strong_bias          = {io_old_entry_strong_bias_1, io_old_entry_strong_bias_0};

  wire [15:0] brMask  = {io_pd_brMask_15,io_pd_brMask_14,io_pd_brMask_13,io_pd_brMask_12,
                         io_pd_brMask_11,io_pd_brMask_10,io_pd_brMask_9,io_pd_brMask_8,
                         io_pd_brMask_7,io_pd_brMask_6,io_pd_brMask_5,io_pd_brMask_4,
                         io_pd_brMask_3,io_pd_brMask_2,io_pd_brMask_1,io_pd_brMask_0};
  wire [15:0] rvcMask = {io_pd_rvcMask_15,io_pd_rvcMask_14,io_pd_rvcMask_13,io_pd_rvcMask_12,
                         io_pd_rvcMask_11,io_pd_rvcMask_10,io_pd_rvcMask_9,io_pd_rvcMask_8,
                         io_pd_rvcMask_7,io_pd_rvcMask_6,io_pd_rvcMask_5,io_pd_rvcMask_4,
                         io_pd_rvcMask_3,io_pd_rvcMask_2,io_pd_rvcMask_1,io_pd_rvcMask_0};
  wire [15:0] mispVec = {io_mispredict_vec_15,io_mispredict_vec_14,io_mispredict_vec_13,io_mispredict_vec_12,
                         io_mispredict_vec_11,io_mispredict_vec_10,io_mispredict_vec_9,io_mispredict_vec_8,
                         io_mispredict_vec_7,io_mispredict_vec_6,io_mispredict_vec_5,io_mispredict_vec_4,
                         io_mispredict_vec_3,io_mispredict_vec_2,io_mispredict_vec_1,io_mispredict_vec_0};

  ftb_entry_t new_e;
  wire [1:0] taken_mask, insert_pos;
  wire [2:0] mispred_mask;

  xs_FTBEntryGen u_core (
    .io_start_addr(io_start_addr), .io_old_entry(old_e),
    .io_pd_brMask(brMask),
    .io_pd_jmpInfo_valid(io_pd_jmpInfo_valid),
    .io_pd_jmpInfo_bits({io_pd_jmpInfo_bits_2, io_pd_jmpInfo_bits_1, io_pd_jmpInfo_bits_0}),
    .io_pd_jmpOffset(io_pd_jmpOffset), .io_pd_jalTarget(io_pd_jalTarget), .io_pd_rvcMask(rvcMask),
    .io_cfiIndex_valid(io_cfiIndex_valid), .io_cfiIndex_bits(io_cfiIndex_bits),
    .io_target(io_target), .io_hit(io_hit), .io_mispredict_vec(mispVec),
    .io_new_entry(new_e), .io_new_br_insert_pos(insert_pos),
    .io_taken_mask(taken_mask), .io_jmp_taken(io_jmp_taken), .io_mispred_mask(mispred_mask),
    .io_is_init_entry(io_is_init_entry), .io_is_old_entry(io_is_old_entry),
    .io_is_new_br(io_is_new_br), .io_is_jalr_target_modified(io_is_jalr_target_modified),
    .io_is_strong_bias_modified(io_is_strong_bias_modified), .io_is_br_full(io_is_br_full)
  );

  // struct → flat（new_entry）
  assign io_new_entry_valid            = new_e.valid;
  assign io_new_entry_brSlots_0_offset = new_e.brSlot.offset;
  assign io_new_entry_brSlots_0_sharing= new_e.brSlot.sharing;
  assign io_new_entry_brSlots_0_valid  = new_e.brSlot.valid;
  assign io_new_entry_brSlots_0_lower  = new_e.brSlot.lower[11:0];
  assign io_new_entry_brSlots_0_tarStat= new_e.brSlot.tarStat;
  assign io_new_entry_tailSlot_offset  = new_e.tailSlot.offset;
  assign io_new_entry_tailSlot_sharing = new_e.tailSlot.sharing;
  assign io_new_entry_tailSlot_valid   = new_e.tailSlot.valid;
  assign io_new_entry_tailSlot_lower   = new_e.tailSlot.lower;
  assign io_new_entry_tailSlot_tarStat = new_e.tailSlot.tarStat;
  assign io_new_entry_pftAddr          = new_e.pftAddr;
  assign io_new_entry_carry            = new_e.carry;
  assign io_new_entry_isCall           = new_e.isCall;
  assign io_new_entry_isRet            = new_e.isRet;
  assign io_new_entry_isJalr           = new_e.isJalr;
  assign io_new_entry_last_may_be_rvi_call = new_e.last_may_be_rvi_call;
  assign io_new_entry_strong_bias_0    = new_e.strong_bias[0];
  assign io_new_entry_strong_bias_1    = new_e.strong_bias[1];
  assign io_taken_mask_0 = taken_mask[0];
  assign io_taken_mask_1 = taken_mask[1];
  assign io_mispred_mask_0 = mispred_mask[0];
  assign io_mispred_mask_1 = mispred_mask[1];
  assign io_mispred_mask_2 = mispred_mask[2];
endmodule
