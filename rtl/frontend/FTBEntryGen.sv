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
// FTB 条目/ slot 的目标压缩编码见 xs_ftb_pkg。numBr=2：slot0=brSlot, slot1=tailSlot
// （tailSlot 可「共享」为第 2 个条件分支）。
// =============================================================================
module xs_FTBEntryGen
  import xs_ftb_pkg::*;
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
      init_entry.brSlot.lower   = calc_lower(io_target, BR_OFF_LEN)[BR_OFF_LEN-1:0];  // brSlot.lower 12 位
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
      mod_newbr.brSlot.lower   = calc_lower(io_target, BR_OFF_LEN)[BR_OFF_LEN-1:0];  // brSlot.lower 12 位
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
