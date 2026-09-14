// =============================================================================
// xs_FTBEntryGen —— FTB 条目生成（纯组合）
//
// 对应 Chisel: xiangshan.frontend.FTBEntryGen（NewFtq.scala）
// 位置：FTQ 在分支/取指结果提交时，据「本取指块的预解码信息(pd) + 实际命中的 CFI
//       (cfiIndex) + 实际目标(target) + 是否命中旧 FTB 条目(hit)」生成要写回 FTB 的
//       新条目，并产出 taken_mask / mispredict 信息与一组 perf 标志。
//
// 两条主路径：
//   ① 未命中(!hit)：新建条目 init_entry——按 pd 把命中的分支/跳转填入 slot。
//   ② 命中(hit)：在旧条目 old_entry 基础上做三种可能修正之一（互斥优先级）：
//        a. 发现新分支(is_new_br)        → 插入新 br slot（可能挤掉 fall-through）
//        b. jalr 目标变化(jalr_modified) → 重算 tailSlot 目标
//        c. 强偏置修正(strong_bias)      → 据本次是否仍命中调整 strong_bias
//
// FTB 条目/ slot 的目标压缩编码见 xs_ftb_pkg（FTBBank 也用它，故住在跨模块公共包
// rtl/frontend/frontend_common_pkg.sv；编译/FM 时它必须排在本文件之前）。numBr=2：slot0=brSlot, slot1=tailSlot
// （tailSlot 可「共享」为第 2 个条件分支）。
// =============================================================================

module xs_FTBEntryGen
  import xs_ftb_pkg::*;   // 共享包，见 rtl/frontend/frontend_common_pkg.sv
(
  input  logic [VADDR_BITS-1:0]    io_start_addr,
  input  ftb_entry_t               io_old_entry,
  // 预解码信息 pd
  input  logic [PREDICT_WIDTH-1:0] io_pd_brMask,        // 各 offset 是否为条件分支
  input  logic                     io_pd_jmpInfo_valid, // 块内是否有跳转
  input  logic [2:0]               io_pd_jmpInfo_bits,  // {isRet, isCall, isJalr}
  input  logic [OFFSET_W-1:0]      io_pd_jmpOffset,
  input  logic [VADDR_BITS-1:0]    io_pd_jalTarget,
  input  logic [PREDICT_WIDTH-1:0] io_pd_rvcMask,       // 各 offset 是否 RVC(16bit)
  // 实际执行结果
  input  logic                     io_cfiIndex_valid,   // 本块是否有 taken 的 CFI
  input  logic [OFFSET_W-1:0]      io_cfiIndex_bits,    // taken CFI 的 offset
  input  logic [VADDR_BITS-1:0]    io_target,           // 实际跳转目标
  input  logic                     io_hit,              // 是否命中旧 FTB 条目
  input  logic [PREDICT_WIDTH-1:0] io_mispredict_vec,

  output ftb_entry_t               io_new_entry,
  output logic [1:0]               io_new_br_insert_pos, // 新 br 插到哪个 slot 前(one-hot)
  output logic [1:0]               io_taken_mask,        // 各 br slot 本次是否 taken
  output logic                     io_jmp_taken,
  output logic [2:0]               io_mispred_mask,      // [1:0]=br, [2]=jmp
  // perf
  output logic                     io_is_init_entry,
  output logic                     io_is_old_entry,
  output logic                     io_is_new_br,
  output logic                     io_is_jalr_target_modified,
  output logic                     io_is_strong_bias_modified,
  output logic                     io_is_br_full
);

  // ---- pd 派生信号 ----
  wire        cfi_is_br      = io_pd_brMask[io_cfiIndex_bits] & io_cfiIndex_valid;
  wire        has_jmp        = io_pd_jmpInfo_valid;
  wire        jmp_is_jalr    = io_pd_jmpInfo_bits[0];
  wire        jmp_is_call    = io_pd_jmpInfo_bits[1];
  wire        jmp_is_ret     = io_pd_jmpInfo_bits[2];
  wire        new_jmp_is_jal  = has_jmp & ~jmp_is_jalr & io_cfiIndex_valid;
  wire        new_jmp_is_jalr = has_jmp &  jmp_is_jalr & io_cfiIndex_valid;
  wire        new_jmp_is_call = has_jmp &  jmp_is_call & io_cfiIndex_valid;
  wire        new_jmp_is_ret  = has_jmp &  jmp_is_ret  & io_cfiIndex_valid;
  // 块尾跳转是 RVI(非压缩)且正好落在最后一个 offset → fall-through 跨过它
  wire        last_jmp_rvi   = has_jmp & (io_pd_jmpOffset == (PREDICT_WIDTH-1)) & ~io_pd_rvcMask[PREDICT_WIDTH-1];
  wire        cfi_is_jal     = (io_cfiIndex_bits == io_pd_jmpOffset) & new_jmp_is_jal;
  wire        cfi_is_jalr    = (io_cfiIndex_bits == io_pd_jmpOffset) & new_jmp_is_jalr;

  // getLower(pc) = pc[CARRY_POS-1:INST_OFF_BITS]，本配置 = pc[4:1]
  wire [OFFSET_W-1:0] start_lower = io_start_addr[CARRY_POS-1:INST_OFF_BITS];
  // fall-through = 起点低位 + 跳转 offset + (RVC?1:2)，多 1 位为 carry
  wire [OFFSET_W:0]   jmp_pft = {1'b0, start_lower} + {1'b0, io_pd_jmpOffset}
                              + (io_pd_rvcMask[io_pd_jmpOffset] ? 5'd1 : 5'd2);

  // =========================================================================
  // 路径①：未命中 → 新建条目
  // =========================================================================
  ftb_entry_t init_entry;
  always_comb begin
    init_entry = '0;
    init_entry.valid = 1'b1;

    // 条件分支填入 brSlot（slot0，非共享）
    if (cfi_is_br) begin
      init_entry.brSlot.valid   = 1'b1;
      init_entry.brSlot.offset  = io_cfiIndex_bits;
      init_entry.brSlot.sharing = 1'b0;
      init_entry.brSlot.tarStat = calc_tarstat(io_start_addr, io_target, BR_OFF_LEN);
      init_entry.brSlot.lower   = calc_lower(io_target, BR_OFF_LEN);  // 截断到 brSlot.lower 12 位(calc_lower 已按 eff=12 掩码, 值本在低 12 位)
      init_entry.strong_bias[0] = 1'b1;     // 新建即置强偏置
    end

    // 跳转填入 tailSlot（slot1，非共享）
    if (has_jmp) begin
      init_entry.tailSlot.offset  = io_pd_jmpOffset;
      init_entry.tailSlot.valid   = new_jmp_is_jal | new_jmp_is_jalr;
      init_entry.tailSlot.sharing = 1'b0;
      init_entry.tailSlot.tarStat = calc_tarstat(io_start_addr,
                                       cfi_is_jalr ? io_target : io_pd_jalTarget, JMP_OFF_LEN);
      init_entry.tailSlot.lower   = calc_lower(
                                       cfi_is_jalr ? io_target : io_pd_jalTarget, JMP_OFF_LEN);
      init_entry.strong_bias[1]   = new_jmp_is_jalr;
    end

    // fall-through：有跳转且非末尾 RVI 时落在跳转之后，否则为整块末尾
    init_entry.pftAddr = (has_jmp & ~last_jmp_rvi) ? jmp_pft[OFFSET_W-1:0] : start_lower;
    init_entry.carry   = (has_jmp & ~last_jmp_rvi) ? jmp_pft[OFFSET_W]     : 1'b1;
    init_entry.isJalr  = new_jmp_is_jalr;
    init_entry.isCall  = new_jmp_is_call;
    init_entry.isRet   = new_jmp_is_ret;
    init_entry.last_may_be_rvi_call =
        (io_pd_jmpOffset == (PREDICT_WIDTH-1)) & ~io_pd_rvcMask[PREDICT_WIDTH-1];
  end

  // =========================================================================
  // 命中路径公共量
  // =========================================================================
  ftb_entry_t oe;  assign oe = io_old_entry;
  // 该 cfi offset 是否已被旧条目记录为分支
  wire br_rec0 = oe.brSlot.valid  & (oe.brSlot.offset  == io_cfiIndex_bits);
  wire br_rec1 = oe.tailSlot.valid & (oe.tailSlot.offset == io_cfiIndex_bits) & oe.tailSlot.sharing;
  wire is_new_br = cfi_is_br & ~(br_rec0 | br_rec1);
  wire [OFFSET_W-1:0] new_br_off = io_cfiIndex_bits;

  // 新 br 应插入到哪个 slot 之前（one-hot，按 offset 升序）
  wire ins0 = ~oe.brSlot.valid  | (new_br_off < oe.brSlot.offset);
  wire ins1 =  oe.brSlot.valid  & (new_br_off > oe.brSlot.offset)
             & (~oe.tailSlot.valid | (new_br_off < oe.tailSlot.offset));
  wire [1:0] insert_onehot = {ins1, ins0};
  wire may_have_to_replace = oe.brSlot.valid & oe.tailSlot.valid;  // 两 br slot 都满

  // =========================================================================
  // 路径②a：命中 + 新分支 → 插入新 br（可能挤掉 fall-through 的 jmp）
  // =========================================================================
  ftb_entry_t mod_newbr;
  always_comb begin
    // 组合临时量提到顶层并默认赋值,避免 always_comb 内条件赋值被推断为闩锁
    logic [OFFSET_W-1:0] new_pft_off;
    logic [OFFSET_W:0]   sum;
    new_pft_off = '0;
    sum         = '0;
    mod_newbr = oe;
    // slot0 (brSlot)
    if (ins0) begin
      mod_newbr.brSlot.valid   = 1'b1;
      mod_newbr.brSlot.offset  = new_br_off;
      mod_newbr.brSlot.sharing = 1'b0;
      mod_newbr.brSlot.tarStat = calc_tarstat(io_start_addr, io_target, BR_OFF_LEN);
      mod_newbr.brSlot.lower   = calc_lower(io_target, BR_OFF_LEN);  // 截断到 12 位(calc_lower 已掩码)
      mod_newbr.strong_bias[0] = 1'b1;
    end else if (new_br_off > oe.brSlot.offset) begin
      mod_newbr.strong_bias[0] = 1'b0;          // 越过旧 br0 → 清强偏置
    end
    // slot1 (tailSlot 作 br)
    if (ins1) begin
      mod_newbr.tailSlot.valid   = 1'b1;
      mod_newbr.tailSlot.offset  = new_br_off;
      mod_newbr.tailSlot.sharing = 1'b1;        // i==numBr-1 → 共享
      mod_newbr.tailSlot.tarStat = calc_tarstat(io_start_addr, io_target, BR_OFF_LEN);
      mod_newbr.tailSlot.lower   = calc_lower(io_target, BR_OFF_LEN);
      mod_newbr.strong_bias[1]   = 1'b1;
    end else if (new_br_off > oe.tailSlot.offset) begin
      mod_newbr.strong_bias[1] = 1'b0;
    end else if (oe.brSlot.valid) begin
      // 否则把 slot0 的内容下移到 slot1（仅当 slot0 有效，即需要腾位）
      mod_newbr.tailSlot.offset  = oe.brSlot.offset;
      mod_newbr.tailSlot.tarStat = oe.brSlot.tarStat;
      mod_newbr.tailSlot.valid   = oe.brSlot.valid;
      mod_newbr.tailSlot.sharing = 1'b1;        // tail 承接 br → 共享
      mod_newbr.tailSlot.lower   = {{(JMP_OFF_LEN-BR_OFF_LEN){1'b0}}, oe.brSlot.lower[BR_OFF_LEN-1:0]};
      mod_newbr.strong_bias[1]   = oe.strong_bias[1];
    end
    // 两 slot 都满还要插新 br → 必须牺牲 jmp，fall-through 改到新边界
    if (is_new_br & may_have_to_replace) begin
      new_pft_off = (insert_onehot == 2'b0) ? new_br_off : oe.tailSlot.offset;
      sum         = {1'b0, start_lower} + {1'b0, new_pft_off};
      mod_newbr.pftAddr              = sum[OFFSET_W-1:0];
      mod_newbr.carry                = sum[OFFSET_W];
      mod_newbr.last_may_be_rvi_call = 1'b0;
      mod_newbr.isCall               = 1'b0;
      mod_newbr.isRet                = 1'b0;
      mod_newbr.isJalr               = 1'b0;
    end
  end

  // =========================================================================
  // 路径②b：命中 + jalr 目标变化 → 重算 tailSlot 目标
  // =========================================================================
  // 旧条目记录的 jalr 目标（tailSlot 非共享时按 jmp 低位宽重建）
  wire [VADDR_BITS-1:0] old_target = get_target(io_start_addr, oe.tailSlot.lower, oe.tailSlot.tarStat,
                                                eff_len(oe.tailSlot.sharing, JMP_OFF_LEN));
  wire old_tail_is_jmp       = ~oe.tailSlot.sharing;
  wire jalr_target_modified  = cfi_is_jalr & (old_target != io_target) & old_tail_is_jmp;

  ftb_entry_t mod_jalr;
  always_comb begin
    mod_jalr = oe;
    if (jalr_target_modified) begin
      mod_jalr.tailSlot.sharing = 1'b0;
      mod_jalr.tailSlot.tarStat = calc_tarstat(io_start_addr, io_target, JMP_OFF_LEN);
      mod_jalr.tailSlot.lower   = calc_lower(io_target, JMP_OFF_LEN);
      mod_jalr.strong_bias      = '0;
    end
  end

  // =========================================================================
  // 路径②c：命中 + 强偏置修正
  // =========================================================================
  wire [1:0] br_valids = {oe.tailSlot.valid & oe.tailSlot.sharing, oe.brSlot.valid};
  wire [OFFSET_W-1:0] br_off0 = oe.brSlot.offset;
  wire [OFFSET_W-1:0] br_off1 = oe.tailSlot.offset;

  ftb_entry_t mod_sb;
  logic [1:0] sb_modified_vec;
  always_comb begin
    mod_sb = oe;
    if (br_rec0)
      mod_sb.strong_bias[0] = oe.strong_bias[0] & io_cfiIndex_valid & br_valids[0] & (io_cfiIndex_bits == br_off0);
    else if (br_rec1) begin
      mod_sb.strong_bias[0] = 1'b0;
      mod_sb.strong_bias[1] = oe.strong_bias[1] & io_cfiIndex_valid & br_valids[1] & (io_cfiIndex_bits == br_off1);
    end
    sb_modified_vec[0] = oe.strong_bias[0] & br_valids[0] & ~mod_sb.strong_bias[0];
    sb_modified_vec[1] = oe.strong_bias[1] & br_valids[1] & ~mod_sb.strong_bias[1];
  end
  wire strong_bias_modified = |sb_modified_vec;

  // =========================================================================
  // 汇总：选择最终条目（命中时三路互斥优先级：新br > jalr目标 > 强偏置）
  // =========================================================================
  ftb_entry_t derived, ne;
  assign derived = is_new_br            ? mod_newbr
                 : jalr_target_modified ? mod_jalr
                 : mod_sb;
  assign ne = io_hit ? derived : init_entry;
  assign io_new_entry = ne;

  // 输出
  wire [1:0] ne_br_valids = {ne.tailSlot.valid & ne.tailSlot.sharing, ne.brSlot.valid};
  wire [OFFSET_W-1:0] ne_br_off0 = ne.brSlot.offset;
  wire [OFFSET_W-1:0] ne_br_off1 = ne.tailSlot.offset;
  wire ne_jmp_valid = ne.tailSlot.valid & ~ne.tailSlot.sharing;

  assign io_new_br_insert_pos = insert_onehot;
  assign io_taken_mask[0] = (io_cfiIndex_bits == ne_br_off0) & io_cfiIndex_valid & ne_br_valids[0];
  assign io_taken_mask[1] = (io_cfiIndex_bits == ne_br_off1) & io_cfiIndex_valid & ne_br_valids[1];
  assign io_jmp_taken     = ne_jmp_valid & (ne.tailSlot.offset == io_cfiIndex_bits);
  assign io_mispred_mask[0] = ne_br_valids[0] & io_mispredict_vec[ne_br_off0];
  assign io_mispred_mask[1] = ne_br_valids[1] & io_mispredict_vec[ne_br_off1];
  assign io_mispred_mask[2] = ne_jmp_valid    & io_mispredict_vec[io_pd_jmpOffset];

  assign io_is_init_entry           = ~io_hit;
  assign io_is_old_entry            = io_hit & ~is_new_br & ~jalr_target_modified & ~strong_bias_modified;
  assign io_is_new_br               = io_hit & is_new_br;
  assign io_is_jalr_target_modified = io_hit & jalr_target_modified;
  assign io_is_strong_bias_modified = io_hit & strong_bias_modified;
  assign io_is_br_full              = io_hit & is_new_br & may_have_to_replace;

endmodule

// FTBEntryGen 包装层（golden 同名扁平端口 ↔ xs_FTBEntryGen 的 ftb_entry_t struct）
// 仅做机械的端口打包/拆包，供 FM 对比与 ST 替换。

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module FTBEntryGen
  import xs_ftb_pkg::*;   // 共享包，见 rtl/frontend/frontend_common_pkg.sv
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
