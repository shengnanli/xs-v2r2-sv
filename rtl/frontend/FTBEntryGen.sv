// FTBEntryGen —— FTB 条目生成（纯组合）手工可读重写
//
// 对应 Chisel: XiangShan/src/main/scala/xiangshan/frontend/NewFtq.scala  class FTBEntryGen
// 参数（kunminghu-v2r2 默认单态化）:
//   VAddrBits=50, PredictWidth=16, numBr=2(brSlot 1 个 + tailSlot),
//   BR_OFFSET_LEN=12, JMP_OFFSET_LEN=20, instOffsetBits=1, carryPos=5,
//   TAR_STAT: FIT=0, OVF=1, UDF=2
//
// 功能：在一次预测/重定向后，依据 hit / 旧条目 / 预译码信息 / cfi 等，
//   组合生成新的 FTB 条目（init 全新条目，或在旧条目基础上派生），并输出
//   taken_mask / mispred_mask 及若干性能计数标志。
//
// 端口完全沿用 golden（io_* 扁平命名）以便 FM 端口自动配对。

module xs_FTBEntryGen_core (
  input  logic [49:0] io_start_addr,
  input  logic        io_old_entry_isCall,
  input  logic        io_old_entry_isRet,
  input  logic        io_old_entry_isJalr,
  input  logic        io_old_entry_valid,
  input  logic [3:0]  io_old_entry_brSlots_0_offset,
  input  logic        io_old_entry_brSlots_0_sharing,
  input  logic        io_old_entry_brSlots_0_valid,
  input  logic [11:0] io_old_entry_brSlots_0_lower,
  input  logic [1:0]  io_old_entry_brSlots_0_tarStat,
  input  logic [3:0]  io_old_entry_tailSlot_offset,
  input  logic        io_old_entry_tailSlot_sharing,
  input  logic        io_old_entry_tailSlot_valid,
  input  logic [19:0] io_old_entry_tailSlot_lower,
  input  logic [1:0]  io_old_entry_tailSlot_tarStat,
  input  logic [3:0]  io_old_entry_pftAddr,
  input  logic        io_old_entry_carry,
  input  logic        io_old_entry_last_may_be_rvi_call,
  input  logic        io_old_entry_strong_bias_0,
  input  logic        io_old_entry_strong_bias_1,
  input  logic        io_pd_brMask_0,
  input  logic        io_pd_brMask_1,
  input  logic        io_pd_brMask_2,
  input  logic        io_pd_brMask_3,
  input  logic        io_pd_brMask_4,
  input  logic        io_pd_brMask_5,
  input  logic        io_pd_brMask_6,
  input  logic        io_pd_brMask_7,
  input  logic        io_pd_brMask_8,
  input  logic        io_pd_brMask_9,
  input  logic        io_pd_brMask_10,
  input  logic        io_pd_brMask_11,
  input  logic        io_pd_brMask_12,
  input  logic        io_pd_brMask_13,
  input  logic        io_pd_brMask_14,
  input  logic        io_pd_brMask_15,
  input  logic        io_pd_jmpInfo_valid,
  input  logic        io_pd_jmpInfo_bits_0,
  input  logic        io_pd_jmpInfo_bits_1,
  input  logic        io_pd_jmpInfo_bits_2,
  input  logic [3:0]  io_pd_jmpOffset,
  input  logic [49:0] io_pd_jalTarget,
  input  logic        io_pd_rvcMask_0,
  input  logic        io_pd_rvcMask_1,
  input  logic        io_pd_rvcMask_2,
  input  logic        io_pd_rvcMask_3,
  input  logic        io_pd_rvcMask_4,
  input  logic        io_pd_rvcMask_5,
  input  logic        io_pd_rvcMask_6,
  input  logic        io_pd_rvcMask_7,
  input  logic        io_pd_rvcMask_8,
  input  logic        io_pd_rvcMask_9,
  input  logic        io_pd_rvcMask_10,
  input  logic        io_pd_rvcMask_11,
  input  logic        io_pd_rvcMask_12,
  input  logic        io_pd_rvcMask_13,
  input  logic        io_pd_rvcMask_14,
  input  logic        io_pd_rvcMask_15,
  input  logic        io_cfiIndex_valid,
  input  logic [3:0]  io_cfiIndex_bits,
  input  logic [49:0] io_target,
  input  logic        io_hit,
  input  logic        io_mispredict_vec_0,
  input  logic        io_mispredict_vec_1,
  input  logic        io_mispredict_vec_2,
  input  logic        io_mispredict_vec_3,
  input  logic        io_mispredict_vec_4,
  input  logic        io_mispredict_vec_5,
  input  logic        io_mispredict_vec_6,
  input  logic        io_mispredict_vec_7,
  input  logic        io_mispredict_vec_8,
  input  logic        io_mispredict_vec_9,
  input  logic        io_mispredict_vec_10,
  input  logic        io_mispredict_vec_11,
  input  logic        io_mispredict_vec_12,
  input  logic        io_mispredict_vec_13,
  input  logic        io_mispredict_vec_14,
  input  logic        io_mispredict_vec_15,
  output logic        io_new_entry_isCall,
  output logic        io_new_entry_isRet,
  output logic        io_new_entry_isJalr,
  output logic        io_new_entry_valid,
  output logic [3:0]  io_new_entry_brSlots_0_offset,
  output logic        io_new_entry_brSlots_0_sharing,
  output logic        io_new_entry_brSlots_0_valid,
  output logic [11:0] io_new_entry_brSlots_0_lower,
  output logic [1:0]  io_new_entry_brSlots_0_tarStat,
  output logic [3:0]  io_new_entry_tailSlot_offset,
  output logic        io_new_entry_tailSlot_sharing,
  output logic        io_new_entry_tailSlot_valid,
  output logic [19:0] io_new_entry_tailSlot_lower,
  output logic [1:0]  io_new_entry_tailSlot_tarStat,
  output logic [3:0]  io_new_entry_pftAddr,
  output logic        io_new_entry_carry,
  output logic        io_new_entry_last_may_be_rvi_call,
  output logic        io_new_entry_strong_bias_0,
  output logic        io_new_entry_strong_bias_1,
  output logic        io_taken_mask_0,
  output logic        io_taken_mask_1,
  output logic        io_jmp_taken,
  output logic        io_mispred_mask_0,
  output logic        io_mispred_mask_1,
  output logic        io_mispred_mask_2,
  output logic        io_is_init_entry,
  output logic        io_is_old_entry,
  output logic        io_is_new_br,
  output logic        io_is_jalr_target_modified,
  output logic        io_is_strong_bias_modified,
  output logic        io_is_br_full
);

  localparam logic [1:0] TAR_FIT = 2'd0;
  localparam logic [1:0] TAR_OVF = 2'd1;
  localparam logic [1:0] TAR_UDF = 2'd2;

  // ---------------------------------------------------------------------------
  // 把 16 个分立的掩码/向量打包，方便用 cfiIndex/jmpOffset 索引
  // ---------------------------------------------------------------------------
  logic [15:0] pd_brMask, pd_rvcMask, mispredict_vec;
  assign pd_brMask = {io_pd_brMask_15, io_pd_brMask_14, io_pd_brMask_13, io_pd_brMask_12,
                      io_pd_brMask_11, io_pd_brMask_10, io_pd_brMask_9,  io_pd_brMask_8,
                      io_pd_brMask_7,  io_pd_brMask_6,  io_pd_brMask_5,  io_pd_brMask_4,
                      io_pd_brMask_3,  io_pd_brMask_2,  io_pd_brMask_1,  io_pd_brMask_0};
  assign pd_rvcMask = {io_pd_rvcMask_15, io_pd_rvcMask_14, io_pd_rvcMask_13, io_pd_rvcMask_12,
                       io_pd_rvcMask_11, io_pd_rvcMask_10, io_pd_rvcMask_9,  io_pd_rvcMask_8,
                       io_pd_rvcMask_7,  io_pd_rvcMask_6,  io_pd_rvcMask_5,  io_pd_rvcMask_4,
                       io_pd_rvcMask_3,  io_pd_rvcMask_2,  io_pd_rvcMask_1,  io_pd_rvcMask_0};
  assign mispredict_vec = {io_mispredict_vec_15, io_mispredict_vec_14, io_mispredict_vec_13, io_mispredict_vec_12,
                           io_mispredict_vec_11, io_mispredict_vec_10, io_mispredict_vec_9,  io_mispredict_vec_8,
                           io_mispredict_vec_7,  io_mispredict_vec_6,  io_mispredict_vec_5,  io_mispredict_vec_4,
                           io_mispredict_vec_3,  io_mispredict_vec_2,  io_mispredict_vec_1,  io_mispredict_vec_0};

  // start_addr 的低位字段：getLower(pc) = pc[carryPos-1:instOffsetBits] = pc[4:1]
  logic [3:0] start_lower;
  assign start_lower = io_start_addr[4:1];

  // ---------------------------------------------------------------------------
  // cfi / jmp 类型判定
  // ---------------------------------------------------------------------------
  logic entry_has_jmp;
  logic cfi_is_br;
  logic new_jmp_is_jal, new_jmp_is_jalr, new_jmp_is_call, new_jmp_is_ret;
  logic last_jmp_rvi;
  logic cfi_is_jalr;

  assign entry_has_jmp   = io_pd_jmpInfo_valid;
  assign cfi_is_br       = pd_brMask[io_cfiIndex_bits] & io_cfiIndex_valid;
  assign new_jmp_is_jal  = entry_has_jmp & ~io_pd_jmpInfo_bits_0 & io_cfiIndex_valid;
  assign new_jmp_is_jalr = entry_has_jmp &  io_pd_jmpInfo_bits_0 & io_cfiIndex_valid;
  assign new_jmp_is_call = entry_has_jmp &  io_pd_jmpInfo_bits_1 & io_cfiIndex_valid;
  assign new_jmp_is_ret  = entry_has_jmp &  io_pd_jmpInfo_bits_2 & io_cfiIndex_valid;
  // 最后一个 slot 是 rvi（占两 byte），fall-through 会指到指令中间
  assign last_jmp_rvi    = entry_has_jmp & (&io_pd_jmpOffset) & ~io_pd_rvcMask_15;
  assign cfi_is_jalr     = (io_cfiIndex_bits == io_pd_jmpOffset) & new_jmp_is_jalr;

  // jalr 命中时用真实 target，否则用预译码算出的 jal target（取 [49:1]）
  logic [48:0] jmp_target_hi;
  assign jmp_target_hi = cfi_is_jalr ? io_target[49:1] : io_pd_jalTarget[49:1];

  // ---------------------------------------------------------------------------
  // init_entry（!hit 时的全新条目）相关计算
  // ---------------------------------------------------------------------------
  // jmpPft = getLower(start) +& jmpOffset +& (rvc ? 1 : 2)  —— 5 位含进位
  logic [4:0] jmpPft;
  assign jmpPft = {1'b0, start_lower}
                + ({1'b0, io_pd_jmpOffset} + (pd_rvcMask[io_pd_jmpOffset] ? 5'd1 : 5'd2));

  // setLowerStatByTarget 的 tarStat：比较高位（不含 lower 区段）
  // br slot（offsetLen=12）：高位 = [49:13]；tail slot 非 share（offsetLen=20）：高位 = [49:21]
  function automatic logic [1:0] tarStat_hi13(input logic [49:0] tgt, pc);
    if (tgt[49:13] > pc[49:13])      tarStat_hi13 = TAR_OVF;
    else if (tgt[49:13] < pc[49:13]) tarStat_hi13 = TAR_UDF;
    else                             tarStat_hi13 = TAR_FIT;
  endfunction
  function automatic logic [1:0] tarStat_hi21(input logic [49:0] tgt, pc);
    if (tgt[49:21] > pc[49:21])      tarStat_hi21 = TAR_OVF;
    else if (tgt[49:21] < pc[49:21]) tarStat_hi21 = TAR_UDF;
    else                             tarStat_hi21 = TAR_FIT;
  endfunction

  // ---------------------------------------------------------------------------
  // hit 路径：旧条目命中后的新分支检测与插入
  // ---------------------------------------------------------------------------
  // br_recorded_vec：cfi 是否已记录在 brSlot0 / tailSlot(share)
  logic br_recorded_vec_0, br_recorded_vec_1;
  logic is_new_br;
  assign br_recorded_vec_0 = io_old_entry_brSlots_0_valid
                           & (io_old_entry_brSlots_0_offset == io_cfiIndex_bits);
  assign br_recorded_vec_1 = io_old_entry_tailSlot_valid
                           & (io_old_entry_tailSlot_offset == io_cfiIndex_bits)
                           & io_old_entry_tailSlot_sharing;
  assign is_new_br = cfi_is_br & ~(br_recorded_vec_1 | br_recorded_vec_0);

  // 新 br 插入 onehot：插到 slot0 前 / slot1(tail) 前
  logic new_br_insert_0, new_br_insert_1;
  logic cfi_gt_br0;     // cfiIndex > brSlot0.offset
  logic cfi_gt_tail;    // cfiIndex > tailSlot.offset
  assign cfi_gt_br0  = io_cfiIndex_bits > io_old_entry_brSlots_0_offset;
  assign cfi_gt_tail = io_cfiIndex_bits > io_old_entry_tailSlot_offset;
  assign new_br_insert_0 = ~io_old_entry_brSlots_0_valid
                         | (io_cfiIndex_bits < io_old_entry_brSlots_0_offset);
  assign new_br_insert_1 = io_old_entry_brSlots_0_valid & cfi_gt_br0
                         & (~io_old_entry_tailSlot_valid
                            | (io_cfiIndex_bits < io_old_entry_tailSlot_offset));

  // 是否需要替换 pft：两个 br slot 都满 且 检测到新 br
  logic may_have_to_replace, pft_need_to_change;
  assign may_have_to_replace = io_old_entry_brSlots_0_valid & io_old_entry_tailSlot_valid;
  assign pft_need_to_change  = is_new_br & may_have_to_replace;

  // new_pft_offset：无插入位则取 cfi，否则取旧 tail(最后 br) 的 offset
  logic [3:0] new_pft_offset;
  assign new_pft_offset = (~(new_br_insert_1 | new_br_insert_0))
                        ? io_cfiIndex_bits
                        : io_old_entry_tailSlot_offset;
  logic [4:0] modified_pft;  // getLower(start) +& new_pft_offset
  assign modified_pft = {1'b0, start_lower} + {1'b0, new_pft_offset};

  // GEN_4: 旧 tail slot 是否给 slot1 让位（cfi 在旧 tail 之后 或 旧 br0 无效）
  logic slot1_keep_tail;
  assign slot1_keep_tail = cfi_gt_tail | ~io_old_entry_brSlots_0_valid;

  // ---------------------------------------------------------------------------
  // jalr target modified：旧 tail 是 jmp(非 share) 且解算出的 old_target != 真实 target
  // ---------------------------------------------------------------------------
  logic [1:0] old_tail_tarStat;
  assign old_tail_tarStat = io_old_entry_tailSlot_tarStat;

  // old_target 重建：share 用 13 位高位 + lower[11:0]，非 share 用 21 位高位 + lower
  logic [49:0] old_target;
  logic [36:0] old_hi13;
  logic [28:0] old_hi21;
  // 注意：tarStat 为非法值 3 时 golden 三个 onehot 项全为 0（高位 = 0），
  // 因此这里对 TAR_FIT 用显式相等判断而非 else，否则 tarStat==3 会误取 start 高位。
  assign old_hi13 = (old_tail_tarStat == TAR_OVF) ? (io_start_addr[49:13] + 37'd1) :
                    (old_tail_tarStat == TAR_UDF) ? (io_start_addr[49:13] - 37'd1) :
                    (old_tail_tarStat == TAR_FIT) ?  io_start_addr[49:13]          :
                                                     37'd0;
  assign old_hi21 = (old_tail_tarStat == TAR_OVF) ? (io_start_addr[49:21] + 29'd1) :
                    (old_tail_tarStat == TAR_UDF) ? (io_start_addr[49:21] - 29'd1) :
                    (old_tail_tarStat == TAR_FIT) ?  io_start_addr[49:21]          :
                                                     29'd0;
  assign old_target = io_old_entry_tailSlot_sharing
                    ? {old_hi13, io_old_entry_tailSlot_lower[11:0], 1'b0}
                    : {old_hi21, io_old_entry_tailSlot_lower,       1'b0};

  logic jalr_target_modified;
  assign jalr_target_modified = cfi_is_jalr
                              & (old_target != io_target)
                              & ~io_old_entry_tailSlot_sharing;

  // ---------------------------------------------------------------------------
  // strong_bias 修正
  // ---------------------------------------------------------------------------
  logic tail_is_shared_br;   // tail slot 当前作为共享 br 使用
  assign tail_is_shared_br = io_old_entry_tailSlot_valid & io_old_entry_tailSlot_sharing;

  logic sb0_kept, sb1_kept;  // strong_bias 修正后的值
  assign sb0_kept = br_recorded_vec_0
                  ? (io_old_entry_strong_bias_0 & io_cfiIndex_valid & io_old_entry_brSlots_0_valid
                     & (io_cfiIndex_bits == io_old_entry_brSlots_0_offset))
                  : (~br_recorded_vec_1 & io_old_entry_strong_bias_0);
  assign sb1_kept = (br_recorded_vec_0 | ~br_recorded_vec_1
                     | (io_cfiIndex_valid & tail_is_shared_br
                        & (io_cfiIndex_bits == io_old_entry_tailSlot_offset)))
                  & io_old_entry_strong_bias_1;

  logic strong_bias_modified;
  assign strong_bias_modified =
      (io_old_entry_strong_bias_0 & io_old_entry_brSlots_0_valid & ~sb0_kept)
    | (io_old_entry_strong_bias_1 & tail_is_shared_br & ~sb1_kept);

  // ---------------------------------------------------------------------------
  // 派生类型标志：当 pft 因新 br 被替换时，旧 jmp 类型清零
  // ---------------------------------------------------------------------------
  logic keep_old_type;      // 保留旧条目的 isCall/isRet/isJalr/last_may_be_rvi_call
  logic insert_at_slot0;    // 新 br 插到 slot0
  assign keep_old_type   = ~is_new_br | ~pft_need_to_change;
  assign insert_at_slot0 = is_new_br & new_br_insert_0;

  // ===========================================================================
  // 输出：new_entry 各字段
  // ===========================================================================

  // --- brSlot0 ---
  assign io_new_entry_brSlots_0_offset =
      io_hit ? (insert_at_slot0 ? io_cfiIndex_bits : io_old_entry_brSlots_0_offset)
             : (cfi_is_br       ? io_cfiIndex_bits : 4'h0);
  assign io_new_entry_brSlots_0_valid =
      io_hit ? (insert_at_slot0 | io_old_entry_brSlots_0_valid) : cfi_is_br;
  assign io_new_entry_brSlots_0_sharing =
      io_hit & (~is_new_br | ~new_br_insert_0) & io_old_entry_brSlots_0_sharing;
  assign io_new_entry_brSlots_0_lower =
      io_hit ? (insert_at_slot0 ? io_target[12:1] : io_old_entry_brSlots_0_lower)
             : (cfi_is_br       ? io_target[12:1] : 12'h0);
  assign io_new_entry_brSlots_0_tarStat =
      io_hit ? (insert_at_slot0 ? tarStat_hi13(io_target, io_start_addr)
                                : io_old_entry_brSlots_0_tarStat)
             : (cfi_is_br       ? tarStat_hi13(io_target, io_start_addr) : TAR_FIT);

  // --- tailSlot ---
  // hit && is_new_br：依插入位置决定 tail 取新 br / 旧 tail / 旧 br0
  assign io_new_entry_tailSlot_offset =
      io_hit ? (is_new_br ? (new_br_insert_1 ? io_cfiIndex_bits
                             : slot1_keep_tail ? io_old_entry_tailSlot_offset
                                               : io_old_entry_brSlots_0_offset)
                          : io_old_entry_tailSlot_offset)
             : (entry_has_jmp ? io_pd_jmpOffset : 4'h0);
  assign io_new_entry_tailSlot_sharing =
      io_hit & (is_new_br ? (new_br_insert_1 | (~cfi_gt_tail & io_old_entry_brSlots_0_valid)
                             | io_old_entry_tailSlot_sharing)
                          : (~jalr_target_modified & io_old_entry_tailSlot_sharing));
  assign io_new_entry_tailSlot_valid =
      io_hit ? (is_new_br ? (new_br_insert_1
                             | (slot1_keep_tail ? io_old_entry_tailSlot_valid
                                                : io_old_entry_brSlots_0_valid))
                          : io_old_entry_tailSlot_valid)
             : (new_jmp_is_jal | new_jmp_is_jalr);
  assign io_new_entry_tailSlot_lower =
      io_hit ? (is_new_br ? (new_br_insert_1 ? {8'h0, io_target[12:1]}
                             : slot1_keep_tail ? io_old_entry_tailSlot_lower
                                               : {8'h0, io_old_entry_brSlots_0_lower})
                          : (jalr_target_modified ? io_target[20:1]
                                                  : io_old_entry_tailSlot_lower))
             : (entry_has_jmp ? jmp_target_hi[19:0] : 20'h0);
  assign io_new_entry_tailSlot_tarStat =
      io_hit ? (is_new_br ? (new_br_insert_1 ? tarStat_hi13(io_target, io_start_addr)
                             : slot1_keep_tail ? io_old_entry_tailSlot_tarStat
                                               : io_old_entry_brSlots_0_tarStat)
                          : (jalr_target_modified ? tarStat_hi21(io_target, io_start_addr)
                                                  : io_old_entry_tailSlot_tarStat))
             : (entry_has_jmp ? (jmp_target_hi[48:20] > io_start_addr[49:21] ? TAR_OVF :
                                 jmp_target_hi[48:20] < io_start_addr[49:21] ? TAR_UDF : TAR_FIT)
                              : TAR_FIT);

  // --- 标量字段 ---
  assign io_new_entry_valid  = ~io_hit | io_old_entry_valid;
  assign io_new_entry_isCall = io_hit ? (keep_old_type & io_old_entry_isCall) : new_jmp_is_call;
  assign io_new_entry_isRet  = io_hit ? (keep_old_type & io_old_entry_isRet)  : new_jmp_is_ret;
  assign io_new_entry_isJalr = io_hit ? (keep_old_type & io_old_entry_isJalr) : new_jmp_is_jalr;

  assign io_new_entry_pftAddr =
      io_hit ? (pft_need_to_change ? (start_lower + new_pft_offset) : io_old_entry_pftAddr)
             : ((entry_has_jmp & ~last_jmp_rvi) ? jmpPft[3:0] : start_lower);
  assign io_new_entry_carry =
      io_hit ? (pft_need_to_change ? modified_pft[4] : io_old_entry_carry)
             : (~(entry_has_jmp & ~last_jmp_rvi) | jmpPft[4]);
  assign io_new_entry_last_may_be_rvi_call =
      io_hit ? (keep_old_type & io_old_entry_last_may_be_rvi_call)
             : ((&io_pd_jmpOffset) & ~pd_rvcMask[io_pd_jmpOffset]);

  assign io_new_entry_strong_bias_0 =
      io_hit ? (is_new_br ? (new_br_insert_0 | (~cfi_gt_br0 & io_old_entry_strong_bias_0))
                          : (jalr_target_modified ? (~jalr_target_modified & io_old_entry_strong_bias_0)
                                                  : sb0_kept))
             : cfi_is_br;
  assign io_new_entry_strong_bias_1 =
      io_hit ? (is_new_br ? (new_br_insert_1 | (~cfi_gt_tail & io_old_entry_strong_bias_1))
                          : (jalr_target_modified ? (~jalr_target_modified & io_old_entry_strong_bias_1)
                                                  : sb1_kept))
             : (entry_has_jmp & new_jmp_is_jalr);

  // ===========================================================================
  // 其它输出
  // ===========================================================================
  assign io_taken_mask_0 = (io_cfiIndex_bits == io_new_entry_brSlots_0_offset)
                         & io_cfiIndex_valid & io_new_entry_brSlots_0_valid;
  assign io_taken_mask_1 = (io_cfiIndex_bits == io_new_entry_tailSlot_offset)
                         & io_cfiIndex_valid
                         & (io_new_entry_tailSlot_valid & io_new_entry_tailSlot_sharing);

  // jmpValid = tail valid && !tail sharing
  assign io_jmp_taken = io_new_entry_tailSlot_valid & ~io_new_entry_tailSlot_sharing
                      & (io_new_entry_tailSlot_offset == io_cfiIndex_bits);

  assign io_mispred_mask_0 = io_new_entry_brSlots_0_valid
                           & mispredict_vec[io_new_entry_brSlots_0_offset];
  assign io_mispred_mask_1 = (io_new_entry_tailSlot_valid & io_new_entry_tailSlot_sharing)
                           & mispredict_vec[io_new_entry_tailSlot_offset];
  assign io_mispred_mask_2 = io_new_entry_tailSlot_valid & ~io_new_entry_tailSlot_sharing
                           & mispredict_vec[io_pd_jmpOffset];

  // 性能计数标志
  assign io_is_init_entry           = ~io_hit;
  assign io_is_new_br               = io_hit & is_new_br;
  assign io_is_old_entry            = io_hit & ~is_new_br & ~jalr_target_modified & ~strong_bias_modified;
  assign io_is_jalr_target_modified = io_hit & jalr_target_modified;
  assign io_is_strong_bias_modified = io_hit & strong_bias_modified;
  assign io_is_br_full              = (io_hit & is_new_br) & may_have_to_replace;

endmodule
