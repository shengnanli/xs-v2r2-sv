// =============================================================================
// xs_FauFTB_core —— uFTB（micro-FTB / Fast FTB，全相联微型取指目标缓冲）预测器核
//
// 对应 Chisel: xiangshan.frontend.FauFTB（FauFTB.scala，extends BasePredictor）
//
// 【它在前端 BPU 的位置】
//   香山前端用「多级覆盖式」分支预测：S1 级有一个极快、零气泡的 uFTB（本模块），
//   随后 S2/S3 级有容量更大但更慢的 FTB/TAGE/ITTAGE 做覆盖修正。uFTB 的使命是
//   在取指地址产生的下一拍（S1）就给出「这一取指块里有没有 CFI、跳到哪、是否 taken」，
//   让取指流水在大多数顺序/强偏置场景下完全不停顿。它命中率不必最高，但必须最快。
//
//   s0_pc ──(s0_fire)──▶ [s1_pc 寄存] ──tag──▶ 32 路全相联查询 ──Mux1H──▶ S1 预测
//                                                                  │
//   FTQ commit ──update──▶ [s0 比较命中] ──▶ [s1 PLRU 选路 / 写入 + 饱和计数更新]
//
// 【为什么是"全相联 + 微型"】
//   uFTB 只有 NUM_WAYS=32 个条目，且全相联（无 set index，直接拿 16-bit tag 并行比所有路）。
//   全相联让小容量也有高利用率（任何 PC 都能落到任意一路），而 32 路的并行 tag 比较在
//   面积/时序上仍可接受。条目本身就是一个标准 FTBEntry（与大 FTB 同构，见 xs_ftb_pkg）。
//
// 【两条数据通路】
//   预测 (S1，纯组合 + 1 拍 pc 寄存)：
//     用 s1_pc 的 tag 并行查 32 路 → 命中 one-hot → 选中那一路的条目解码成
//     FullBranchPrediction（目标地址重建、fall-through、is_jal/jalr/call/ret 等），
//     br_taken = 该路 2-bit 饱和计数器最高位 | 强偏置位。
//   更新 (s0→s1 两级)：
//     s0：寄存 FTQ 送来的 update 请求，并用 update_pc 的 tag 比所有路得到命中。
//     s1：命中则原路改写；未命中则由 PLRU 选一路替换写入。同时按本次真实 taken
//         更新被写路的饱和计数器。PLRU 状态另受「预测命中」触摸（让常被预测命中的
//         路更不容易被替换）。
//
// 【与大 FTB 的区别】
//   - 容量：uFTB 32 条全相联 vs FTB 几千条组相联（带 SRAM）。
//   - 延迟：uFTB S1 当拍出结果（寄存器实现）vs FTB 需读 SRAM、晚一两级。
//   - 替换：uFTB 用 PLRU 在 32 路里替换 vs FTB 用 set 内替换。
//   - 计数：uFTB 自带每路每分支的 2-bit 饱和计数做方向预测；条目命中即可独立给出方向。
//
// 【可读性要点】
//   - 每路条目用 xs_ftb_pkg::ftb_entry_t 结构体数组 way_entry[NUM_WAYS] 表达，
//     不再展平成几十个 w_resp_* 标量数组。
//   - S1 预测结果用 full_pred_t 结构体；fromFtbEntry 写成纯函数 decode_full_pred()。
//   - 目标地址重建复用 xs_ftb_pkg::get_target()（与 FTBEntryGen 同一套压缩编码）。
//   - PLRU 二叉树的"选路"和"触摸翻转"各写成纯函数，名字直述其意。
//   - 32 路、2 分支均用 genvar/for 展开，不手工堆叠。
//
// 【端口说明】
//   端口沿用 Chisel 生成 RTL（golden）的扁平命名以便 FM 对齐；full_pred 在核内只算
//   一份逻辑值（s0_pc 四份 dup 内容相同），由 wrapper 复制到 4 个 dup 输出。
//
//   注：golden 含若干被 firtool 保留但对所有输出无影响的结构（s2/s3 pc 寄存器、
//   `ifndef SYNTHESIS 断言、性能 _probe 中间量）。它们是 unread compare point，核内不实现；
//   FM 已设 verification_verify_unread_compare_points=false。
// =============================================================================
module xs_FauFTB_core
  import xs_ftb_pkg::*;
#(
  parameter int unsigned NUM_WAYS = 32,
  parameter int unsigned NUM_BR   = 2,
  parameter int unsigned TAG_W    = 16,
  parameter int unsigned PC_W     = 50,
  parameter int unsigned RV_W     = 48,  // reset_vector 宽度
  parameter int unsigned META_W   = 516
)(
  input  logic                clock,
  input  logic                reset,
  input  logic [RV_W-1:0]     io_reset_vector,

  // ---- 预测输入流水（s0_pc 四份 dup，内容相同；dup 仅为物理布线扇出） ----
  input  logic [PC_W-1:0]     io_in_bits_s0_pc_0,
  input  logic [PC_W-1:0]     io_in_bits_s0_pc_1,
  input  logic [PC_W-1:0]     io_in_bits_s0_pc_2,
  input  logic [PC_W-1:0]     io_in_bits_s0_pc_3,

  // ---- 预测输出 s1：四份 pc dup ----
  output logic [PC_W-1:0]     io_out_s1_pc_0,
  output logic [PC_W-1:0]     io_out_s1_pc_1,
  output logic [PC_W-1:0]     io_out_s1_pc_2,
  output logic [PC_W-1:0]     io_out_s1_pc_3,

  // ---- 预测输出 full_pred（一份逻辑值，wrapper 复制到 4 dup） ----
  output logic                fp_br_taken_mask_0,
  output logic                fp_br_taken_mask_1,
  output logic                fp_slot_valids_0,
  output logic                fp_slot_valids_1,
  output logic [PC_W-1:0]     fp_targets_0,
  output logic [PC_W-1:0]     fp_targets_1,
  output logic [PC_W-1:0]     fp_jalr_target,
  output logic [3:0]          fp_offsets_0,
  output logic [3:0]          fp_offsets_1,
  output logic [PC_W-1:0]     fp_fallThroughAddr,
  output logic                fp_fallThroughErr,
  output logic                fp_is_jal,
  output logic                fp_is_jalr,
  output logic                fp_is_call,
  output logic                fp_is_ret,
  output logic                fp_last_may_be_rvi_call,
  output logic                fp_is_br_sharing,
  output logic                fp_hit,

  output logic [META_W-1:0]   io_out_last_stage_meta,

  // ---- fauftb_entry_out：命中路的原始 FTBEntry（供后级 FTB/FTQ 做条目复用/比对） ----
  output logic                io_fauftb_entry_out_isCall,
  output logic                io_fauftb_entry_out_isRet,
  output logic                io_fauftb_entry_out_isJalr,
  output logic                io_fauftb_entry_out_valid,
  output logic [3:0]          io_fauftb_entry_out_brSlots_0_offset,
  output logic                io_fauftb_entry_out_brSlots_0_sharing,
  output logic                io_fauftb_entry_out_brSlots_0_valid,
  output logic [11:0]         io_fauftb_entry_out_brSlots_0_lower,
  output logic [1:0]          io_fauftb_entry_out_brSlots_0_tarStat,
  output logic [3:0]          io_fauftb_entry_out_tailSlot_offset,
  output logic                io_fauftb_entry_out_tailSlot_sharing,
  output logic                io_fauftb_entry_out_tailSlot_valid,
  output logic [19:0]         io_fauftb_entry_out_tailSlot_lower,
  output logic [1:0]          io_fauftb_entry_out_tailSlot_tarStat,
  output logic [3:0]          io_fauftb_entry_out_pftAddr,
  output logic                io_fauftb_entry_out_carry,
  output logic                io_fauftb_entry_out_last_may_be_rvi_call,
  output logic                io_fauftb_entry_out_strong_bias_0,
  output logic                io_fauftb_entry_out_strong_bias_1,
  output logic                io_fauftb_entry_hit_out,

  // ---- 控制 / 各级 fire（dup） ----
  input  logic                io_ctrl_ubtb_enable,
  input  logic                io_s0_fire_0,
  input  logic                io_s0_fire_1,
  input  logic                io_s0_fire_2,
  input  logic                io_s0_fire_3,
  input  logic                io_s1_fire_0,
  input  logic                io_s1_fire_1,
  input  logic                io_s1_fire_2,
  input  logic                io_s1_fire_3,
  input  logic                io_s2_fire_0,
  input  logic                io_s2_fire_1,
  input  logic                io_s2_fire_2,
  input  logic                io_s2_fire_3,

  // ---- 更新输入（FTQ commit → BPU） ----
  input  logic                io_update_valid,
  input  logic [PC_W-1:0]     io_update_bits_pc,
  input  logic                io_update_bits_ftb_entry_isCall,
  input  logic                io_update_bits_ftb_entry_isRet,
  input  logic                io_update_bits_ftb_entry_isJalr,
  input  logic                io_update_bits_ftb_entry_valid,
  input  logic [3:0]          io_update_bits_ftb_entry_brSlots_0_offset,
  input  logic                io_update_bits_ftb_entry_brSlots_0_sharing,
  input  logic                io_update_bits_ftb_entry_brSlots_0_valid,
  input  logic [11:0]         io_update_bits_ftb_entry_brSlots_0_lower,
  input  logic [1:0]          io_update_bits_ftb_entry_brSlots_0_tarStat,
  input  logic [3:0]          io_update_bits_ftb_entry_tailSlot_offset,
  input  logic                io_update_bits_ftb_entry_tailSlot_sharing,
  input  logic                io_update_bits_ftb_entry_tailSlot_valid,
  input  logic [19:0]         io_update_bits_ftb_entry_tailSlot_lower,
  input  logic [1:0]          io_update_bits_ftb_entry_tailSlot_tarStat,
  input  logic [3:0]          io_update_bits_ftb_entry_pftAddr,
  input  logic                io_update_bits_ftb_entry_carry,
  input  logic                io_update_bits_ftb_entry_last_may_be_rvi_call,
  input  logic                io_update_bits_ftb_entry_strong_bias_0,
  input  logic                io_update_bits_ftb_entry_strong_bias_1,
  input  logic                io_update_bits_br_taken_mask_0,
  input  logic                io_update_bits_br_taken_mask_1,
  input  logic [META_W-1:0]   io_update_bits_meta,

  // ---- perf ----
  output logic [5:0]          io_perf_0_value,
  output logic [5:0]          io_perf_1_value
);

  localparam int unsigned WAY_IDX_W = $clog2(NUM_WAYS);   // =5

  // ===========================================================================
  // 局部类型与纯函数
  // ===========================================================================

  // S1 给取指流水的完整分支预测（FullBranchPrediction 的 uFTB 相关字段子集）
  typedef struct packed {
    logic [1:0]          br_taken_mask;   // 每个条件分支本次是否预测 taken
    logic [1:0]          slot_valids;     // {tailSlot.valid, brSlot.valid}
    logic [PC_W-1:0]     target_br;       // brSlot 目标（条件分支跳转目标）
    logic [PC_W-1:0]     target_tail;     // tailSlot 目标（== jalr_target）
    logic [3:0]          offset_br;       // brSlot 在块内 offset
    logic [3:0]          offset_tail;     // tailSlot 在块内 offset
    logic [PC_W-1:0]     fall_through;    // 顺序执行落到的下一块起点
    logic                fall_through_err;// fall-through 越界（条目非法）
    logic                is_jal;
    logic                is_jalr;
    logic                is_call;
    logic                is_ret;
    logic                last_may_be_rvi_call;
    logic                is_br_sharing;   // tailSlot 被共享作第 2 条件分支
  } full_pred_t;

  // FTB 条目的 tag 提取：pc[tagSize+instOffsetBits-1 : instOffsetBits] = pc[16:1]
  function automatic logic [TAG_W-1:0] get_tag(input logic [PC_W-1:0] pc);
    return pc[TAG_W : INST_OFF_BITS];
  endfunction

  // ---- fromFtbEntry：把一路命中的 FTBEntry + 该路饱和计数器解码成 full_pred ----
  // 目标重建复用 ftb_pkg::get_target（与大 FTB / FTBEntryGen 同一套压缩编码）：
  //   - brSlot 始终按 BR_OFF_LEN(12) 低位宽；
  //   - tailSlot 若 sharing 则按 BR_OFF_LEN，否则按 JMP_OFF_LEN(20)。
  // fall-through 用条目存的 pftAddr/carry 与 s1_pc 高位拼接；越界则回退到 pc + 取指块字节数。
  function automatic full_pred_t decode_full_pred(
      input logic [PC_W-1:0] pc,
      input ftb_entry_t      e,
      input logic [1:0]      ctr_hi   // {ctr[tail][1], ctr[br][1]}：饱和计数最高位
  );
    full_pred_t        fp;
    logic [4:0]        start_lower;        // {1'b0, pc[4:1]}：取指块起点低位（含进位位）
    logic [4:0]        end_lower_carry;    // {carry, pftAddr}：条目记录的 fall-through 低位
    logic [PC_W-1:0]   pft_in_range;       // fall-through 在合法范围时的值
    logic [PC_W-1:0]   pft_overflow;       // 越界回退值

    fp = '0;

    // 目标地址（压缩编码 → 完整 50-bit）
    fp.target_br   = get_target(pc, {{(JMP_OFF_LEN-BR_OFF_LEN){1'b0}}, e.brSlot.lower[BR_OFF_LEN-1:0]},
                                e.brSlot.tarStat, BR_OFF_LEN);
    fp.target_tail = get_target(pc, e.tailSlot.lower, e.tailSlot.tarStat,
                                eff_len(e.tailSlot.sharing, JMP_OFF_LEN));

    // fall-through 地址与越界判定
    start_lower     = {1'b0, pc[CARRY_POS-1:INST_OFF_BITS]};
    end_lower_carry = {e.carry, e.pftAddr};
    // 非法：起点已 ≥ 终点，或 终点超出"起点 + 一个取指块(16 槽)"上界
    fp.fall_through_err = (start_lower >= end_lower_carry)
                        | (end_lower_carry > (start_lower - 5'd16));
    pft_overflow = pc + PC_W'(PREDICT_WIDTH * 2);   // 一块 = 16 个 2 字节槽 = 32 字节
    pft_in_range = { (e.carry ? (pc[PC_W-1:CARRY_POS] + 1'b1) : pc[PC_W-1:CARRY_POS]),
                     e.pftAddr, 1'b0 };
    fp.fall_through = fp.fall_through_err ? pft_overflow : pft_in_range;

    // CFI 种类（仅当 tailSlot 有效才成立）
    fp.is_jal   = e.tailSlot.valid & ~e.isJalr;
    fp.is_jalr  = e.tailSlot.valid &  e.isJalr;
    fp.is_call  = e.tailSlot.valid &  e.isCall;
    fp.is_ret   = e.tailSlot.valid &  e.isRet;
    fp.is_br_sharing        = e.tailSlot.valid & e.tailSlot.sharing;
    fp.last_may_be_rvi_call = e.last_may_be_rvi_call;

    // slot 元数据
    fp.offset_br    = e.brSlot.offset;
    fp.offset_tail  = e.tailSlot.offset;
    fp.slot_valids  = {e.tailSlot.valid, e.brSlot.valid};

    // 方向预测：饱和计数最高位为 1（弱/强 taken），或强偏置位置位 → 预测 taken
    fp.br_taken_mask = {ctr_hi[1] | e.strong_bias[1],
                        ctr_hi[0] | e.strong_bias[0]};
    return fp;
  endfunction

  // ---- 2-bit 饱和计数器更新（satUpdate）：taken 时 +1（封顶 3），否则 -1（封底 0） ----
  function automatic logic [1:0] sat_update(input logic [1:0] cnt, input logic taken);
    if (taken) return (cnt == 2'd3) ? 2'd3 : (cnt + 2'd1);
    else       return (cnt == 2'd0) ? 2'd0 : (cnt - 2'd1);
  endfunction

  // ---- one-hot → 二进制（OHToUInt）----
  function automatic logic [WAY_IDX_W-1:0] oh_to_idx(input logic [NUM_WAYS-1:0] oh);
    logic [WAY_IDX_W-1:0] idx;
    idx = '0;
    for (int b = 0; b < WAY_IDX_W; b++)
      for (int i = 0; i < NUM_WAYS; i++)
        if (i[b]) idx[b] = idx[b] | oh[i];
    return idx;
  endfunction

  // ===========================================================================
  // 二叉树 PLRU（pseudo-LRU）替换器
  //
  //   32 路 = 满二叉树 5 层，用 NUM_WAYS-1 = 31 个状态位。每个内部节点存 1 位，
  //   指向"较近被使用"的那一侧的反面，即"victim 应往哪边走"。
  //   - 选 victim：从根沿状态位逐层下行，拼出 5-bit way 号。
  //   - 触摸 way：把根到该叶路径上的每个节点翻向"远离该叶"的一侧，路径外子树不动；
  //     这样刚被访问的叶最不容易被选为下一个 victim。
  //
  //   状态位编排（与 golden 一致）：state[30] 为根；其下高半子树用 state[29:15]、
  //   低半用 state[14:0]，各为一棵 16 叶（4 层 15 位）子树。下面三个 plru_touch_* 纯函数
  //   分别处理 4 叶/8 叶/16 叶子树的递归翻转，名字直述层数。
  // ===========================================================================

  // 4 叶子树（3 位状态，2-bit way）：翻根位；按根选中的半边递归翻 1 位
  function automatic logic [2:0] plru_touch4(input logic [2:0] st, input logic [1:0] way);
    return {~way[1], way[1] ? ~way[0] : st[1], way[1] ? st[0] : ~way[0]};
  endfunction
  // 8 叶子树（7 位，3-bit way）
  function automatic logic [6:0] plru_touch8(input logic [6:0] st, input logic [2:0] way);
    return {~way[2],
            way[2] ? plru_touch4(st[5:3], way[1:0]) : st[5:3],
            way[2] ? st[2:0] : plru_touch4(st[2:0], way[1:0])};
  endfunction
  // 16 叶子树（15 位，4-bit way）
  function automatic logic [14:0] plru_touch16(input logic [14:0] st, input logic [3:0] way);
    return {~way[3],
            way[3] ? plru_touch8(st[13:7], way[2:0]) : st[13:7],
            way[3] ? st[6:0] : plru_touch8(st[6:0], way[2:0])};
  endfunction

  // 选 victim：从 31 位状态读出 5-bit way 号（与 golden 自顶向下的遍历完全一致）
  function automatic logic [WAY_IDX_W-1:0] plru_victim(input logic [NUM_WAYS-2:0] st);
    logic [3:0] low4;
    // 先选根（st[30]）决定走高半/低半，再在对应 16 叶子树里逐层下行
    if (st[30])
      low4 = { st[29], st[29] ? { st[28], st[28] ? { st[27], st[27] ? st[26] : st[25] }
                                                  : { st[24], st[24] ? st[23] : st[22] } }
                              : { st[21], st[21] ? { st[20], st[20] ? st[19] : st[18] }
                                                  : { st[17], st[17] ? st[16] : st[15] } } };
    else
      low4 = { st[14], st[14] ? { st[13], st[13] ? { st[12], st[12] ? st[11] : st[10] }
                                                  : { st[9],  st[9]  ? st[8]  : st[7]  } }
                              : { st[6],  st[6]  ? { st[5],  st[5]  ? st[4]  : st[3]  }
                                                  : { st[2],  st[2]  ? st[1]  : st[0]  } } };
    return {st[30], low4};
  endfunction

  // 触摸一路 way：返回更新后的 31 位状态（根 + 被选半边 16 叶子树翻转，另半保持）
  function automatic logic [NUM_WAYS-2:0] plru_touch(
      input logic [NUM_WAYS-2:0] st, input logic [WAY_IDX_W-1:0] way);
    logic [14:0] hi, lo;
    hi = way[4] ? plru_touch16(st[29:15], way[3:0]) : st[29:15];
    lo = way[4] ? st[14:0] : plru_touch16(st[14:0], way[3:0]);
    return {~way[4], hi, lo};
  endfunction

  // ===========================================================================
  // S1 流水：取指 PC 寄存
  //   复位释放后第一拍把 reset_vector 灌入 s1_pc（让首次取指从复位向量开始）；
  //   其后每当 s0_fire 就把 s0_pc 推进到 s1_pc。
  // ===========================================================================
  logic [PC_W-1:0] s1_pc_dup_0, s1_pc_dup_1, s1_pc_dup_2, s1_pc_dup_3;
  logic            reset_d0, reset_d1;
  wire  [PC_W-1:0] reset_pc = {{(PC_W-RV_W){1'b0}}, io_reset_vector};

  always_ff @(posedge clock) begin
    if (reset_d1) begin
      s1_pc_dup_0 <= reset_pc;
      s1_pc_dup_1 <= reset_pc;
      s1_pc_dup_2 <= reset_pc;
      s1_pc_dup_3 <= reset_pc;
    end else begin
      if (io_s0_fire_0) s1_pc_dup_0 <= io_in_bits_s0_pc_0;
      if (io_s0_fire_1) s1_pc_dup_1 <= io_in_bits_s0_pc_1;
      if (io_s0_fire_2) s1_pc_dup_2 <= io_in_bits_s0_pc_2;
      if (io_s0_fire_3) s1_pc_dup_3 <= io_in_bits_s0_pc_3;
    end
    reset_d0 <= reset;
    reset_d1 <= reset_d0 & ~reset;   // 复位结束沿后第一拍脉冲
  end

  assign io_out_s1_pc_0 = s1_pc_dup_0;
  assign io_out_s1_pc_1 = s1_pc_dup_1;
  assign io_out_s1_pc_2 = s1_pc_dup_2;
  assign io_out_s1_pc_3 = s1_pc_dup_3;

  // ===========================================================================
  // 32 路全相联存储：例化 FauFTBWay（每路 = 一个 FTBEntry + tag + valid）
  //
  //   FauFTBWay 是 golden 同名子模块（FauFTBWay_wrapper.sv，核 xs_FauFTBWay），用扁平
  //   命名端口。本核把每路扁平 resp 打包进 ftb_entry_t 数组 way_entry[]，后续逻辑只
  //   面向结构体，干净许多。写口同理由 u_s1_entry（ftb_entry_t）拆出扁平字段送回。
  // ===========================================================================
  ftb_entry_t          way_entry [NUM_WAYS];   // 各路读出的条目（结构体）
  logic [NUM_WAYS-1:0] way_resp_hit;           // 预测 tag 命中向量（one-hot）
  logic [NUM_WAYS-1:0] way_update_hit;         // 更新 tag 命中向量（含写旁路）
  logic [NUM_WAYS-1:0] way_write_valid;        // 各路本拍写使能
  logic [1:0]          ctrs [NUM_WAYS][NUM_BR];// 每路每分支的 2-bit 饱和计数器

  // s1 写入信息（由更新流水算出，所有路共享同一条目/同一 tag）
  ftb_entry_t        u_s1_entry;
  logic [TAG_W-1:0]  u_s1_tag;

  wire [TAG_W-1:0] pred_tag   = get_tag(s1_pc_dup_0);
  wire [TAG_W-1:0] update_tag = get_tag(io_update_bits_pc);

  genvar gw;
  generate
    for (gw = 0; gw < NUM_WAYS; gw++) begin : g_ways
      // 该路扁平 resp 字段（FauFTBWay 输出），随后打包进 way_entry[gw]
      logic       r_isCall, r_isRet, r_isJalr, r_valid;
      logic [3:0] r_brOff;  logic r_brShar, r_brVal;  logic [11:0] r_brLow;  logic [1:0] r_brTar;
      logic [3:0] r_tailOff; logic r_tailShar, r_tailVal; logic [19:0] r_tailLow; logic [1:0] r_tailTar;
      logic [3:0] r_pftAddr; logic r_carry, r_lmbrc, r_sb0, r_sb1;

      FauFTBWay ways (
        .clock                               (clock),
        .reset                               (reset),
        .io_req_tag                          (pred_tag),
        .io_resp_isCall                      (r_isCall),
        .io_resp_isRet                       (r_isRet),
        .io_resp_isJalr                      (r_isJalr),
        .io_resp_valid                       (r_valid),
        .io_resp_brSlots_0_offset            (r_brOff),
        .io_resp_brSlots_0_sharing           (r_brShar),
        .io_resp_brSlots_0_valid             (r_brVal),
        .io_resp_brSlots_0_lower             (r_brLow),
        .io_resp_brSlots_0_tarStat           (r_brTar),
        .io_resp_tailSlot_offset             (r_tailOff),
        .io_resp_tailSlot_sharing            (r_tailShar),
        .io_resp_tailSlot_valid              (r_tailVal),
        .io_resp_tailSlot_lower              (r_tailLow),
        .io_resp_tailSlot_tarStat            (r_tailTar),
        .io_resp_pftAddr                     (r_pftAddr),
        .io_resp_carry                       (r_carry),
        .io_resp_last_may_be_rvi_call        (r_lmbrc),
        .io_resp_strong_bias_0               (r_sb0),
        .io_resp_strong_bias_1               (r_sb1),
        .io_resp_hit                         (way_resp_hit[gw]),
        .io_update_req_tag                   (update_tag),
        .io_update_hit                       (way_update_hit[gw]),
        .io_write_valid                      (way_write_valid[gw]),
        .io_write_entry_isCall               (u_s1_entry.isCall),
        .io_write_entry_isRet                (u_s1_entry.isRet),
        .io_write_entry_isJalr               (u_s1_entry.isJalr),
        .io_write_entry_valid                (u_s1_entry.valid),
        .io_write_entry_brSlots_0_offset     (u_s1_entry.brSlot.offset),
        .io_write_entry_brSlots_0_sharing    (u_s1_entry.brSlot.sharing),
        .io_write_entry_brSlots_0_valid      (u_s1_entry.brSlot.valid),
        .io_write_entry_brSlots_0_lower      (u_s1_entry.brSlot.lower[BR_OFF_LEN-1:0]),
        .io_write_entry_brSlots_0_tarStat    (u_s1_entry.brSlot.tarStat),
        .io_write_entry_tailSlot_offset      (u_s1_entry.tailSlot.offset),
        .io_write_entry_tailSlot_sharing     (u_s1_entry.tailSlot.sharing),
        .io_write_entry_tailSlot_valid       (u_s1_entry.tailSlot.valid),
        .io_write_entry_tailSlot_lower       (u_s1_entry.tailSlot.lower),
        .io_write_entry_tailSlot_tarStat     (u_s1_entry.tailSlot.tarStat),
        .io_write_entry_pftAddr              (u_s1_entry.pftAddr),
        .io_write_entry_carry                (u_s1_entry.carry),
        .io_write_entry_last_may_be_rvi_call (u_s1_entry.last_may_be_rvi_call),
        .io_write_entry_strong_bias_0        (u_s1_entry.strong_bias[0]),
        .io_write_entry_strong_bias_1        (u_s1_entry.strong_bias[1]),
        .io_write_tag                        (u_s1_tag)
      );

      // 扁平 resp → ftb_entry_t（brSlot.lower 高位补 0，与条目存储约定一致）
      always_comb begin
        way_entry[gw]                  = '0;
        way_entry[gw].valid            = r_valid;
        way_entry[gw].isCall           = r_isCall;
        way_entry[gw].isRet            = r_isRet;
        way_entry[gw].isJalr           = r_isJalr;
        way_entry[gw].brSlot.offset    = r_brOff;
        way_entry[gw].brSlot.sharing   = r_brShar;
        way_entry[gw].brSlot.valid     = r_brVal;
        way_entry[gw].brSlot.lower     = r_brLow;   // brSlot.lower 现为 12 位
        way_entry[gw].brSlot.tarStat   = r_brTar;
        way_entry[gw].tailSlot.offset  = r_tailOff;
        way_entry[gw].tailSlot.sharing = r_tailShar;
        way_entry[gw].tailSlot.valid   = r_tailVal;
        way_entry[gw].tailSlot.lower   = r_tailLow;
        way_entry[gw].tailSlot.tarStat = r_tailTar;
        way_entry[gw].pftAddr          = r_pftAddr;
        way_entry[gw].carry            = r_carry;
        way_entry[gw].last_may_be_rvi_call = r_lmbrc;
        way_entry[gw].strong_bias      = {r_sb1, r_sb0};
      end
    end
  endgenerate

  // ===========================================================================
  // S1 预测合成
  //   每路条目解码成 full_pred，再用命中 one-hot 做 Mux1H（命中互斥 → 按位 OR）。
  //   uFTB 保证最多一路命中（golden 有断言）；此处 OR 形式即等价 Mux1H。
  // ===========================================================================
  wire                 s1_hit     = |way_resp_hit;
  wire [WAY_IDX_W-1:0] s1_hit_way = oh_to_idx(way_resp_hit);

  full_pred_t way_pred [NUM_WAYS];   // 每路解码出的预测
  generate
    for (gw = 0; gw < NUM_WAYS; gw++) begin : g_decode
      assign way_pred[gw] =
          decode_full_pred(s1_pc_dup_0, way_entry[gw], {ctrs[gw][1][1], ctrs[gw][0][1]});
    end
  endgenerate

  // Mux1H 合成预测 + 命中路原始条目
  full_pred_t s1_pred;
  ftb_entry_t s1_hit_entry;
  always_comb begin
    s1_pred      = '0;
    s1_hit_entry = '0;
    for (int i = 0; i < NUM_WAYS; i++) begin
      if (way_resp_hit[i]) begin
        s1_pred      = s1_pred      | way_pred[i];
        s1_hit_entry = s1_hit_entry | way_entry[i];
      end
    end
  end

  // fauftb_enable = RegNext(io_ctrl_ubtb_enable)：ubtb 开关延一拍对齐 s1
  logic fauftb_enable;
  always_ff @(posedge clock) fauftb_enable <= io_ctrl_ubtb_enable;

  wire pred_hit = s1_hit & fauftb_enable;

  // ---- full_pred 输出 ----
  assign fp_br_taken_mask_0      = s1_pred.br_taken_mask[0];
  assign fp_br_taken_mask_1      = s1_pred.br_taken_mask[1];
  assign fp_slot_valids_0        = s1_pred.slot_valids[0];
  assign fp_slot_valids_1        = s1_pred.slot_valids[1];
  assign fp_targets_0            = s1_pred.target_br;
  assign fp_targets_1            = s1_pred.target_tail;
  assign fp_jalr_target          = s1_pred.target_tail;
  assign fp_offsets_0            = s1_pred.offset_br;
  assign fp_offsets_1            = s1_pred.offset_tail;
  assign fp_fallThroughAddr      = s1_pred.fall_through;
  assign fp_fallThroughErr       = s1_pred.fall_through_err;
  assign fp_is_jal               = s1_pred.is_jal;
  assign fp_is_jalr              = s1_pred.is_jalr;
  assign fp_is_call              = s1_pred.is_call;
  assign fp_is_ret               = s1_pred.is_ret;
  assign fp_last_may_be_rvi_call = s1_pred.last_may_be_rvi_call;
  assign fp_is_br_sharing        = s1_pred.is_br_sharing;
  assign fp_hit                  = pred_hit;

  // ---- fauftb_entry_out：命中路原始条目（结构体 → 扁平端口） ----
  assign io_fauftb_entry_out_isCall              = s1_hit_entry.isCall;
  assign io_fauftb_entry_out_isRet               = s1_hit_entry.isRet;
  assign io_fauftb_entry_out_isJalr              = s1_hit_entry.isJalr;
  assign io_fauftb_entry_out_valid               = s1_hit_entry.valid;
  assign io_fauftb_entry_out_brSlots_0_offset    = s1_hit_entry.brSlot.offset;
  assign io_fauftb_entry_out_brSlots_0_sharing   = s1_hit_entry.brSlot.sharing;
  assign io_fauftb_entry_out_brSlots_0_valid     = s1_hit_entry.brSlot.valid;
  assign io_fauftb_entry_out_brSlots_0_lower     = s1_hit_entry.brSlot.lower[BR_OFF_LEN-1:0];
  assign io_fauftb_entry_out_brSlots_0_tarStat   = s1_hit_entry.brSlot.tarStat;
  assign io_fauftb_entry_out_tailSlot_offset     = s1_hit_entry.tailSlot.offset;
  assign io_fauftb_entry_out_tailSlot_sharing    = s1_hit_entry.tailSlot.sharing;
  assign io_fauftb_entry_out_tailSlot_valid      = s1_hit_entry.tailSlot.valid;
  assign io_fauftb_entry_out_tailSlot_lower      = s1_hit_entry.tailSlot.lower;
  assign io_fauftb_entry_out_tailSlot_tarStat    = s1_hit_entry.tailSlot.tarStat;
  assign io_fauftb_entry_out_pftAddr             = s1_hit_entry.pftAddr;
  assign io_fauftb_entry_out_carry               = s1_hit_entry.carry;
  assign io_fauftb_entry_out_last_may_be_rvi_call = s1_hit_entry.last_may_be_rvi_call;
  assign io_fauftb_entry_out_strong_bias_0       = s1_hit_entry.strong_bias[0];
  assign io_fauftb_entry_out_strong_bias_1       = s1_hit_entry.strong_bias[1];
  assign io_fauftb_entry_hit_out                 = pred_hit;

  // ===========================================================================
  // meta：last_stage_meta = {0..., pred_way[4:0], hit}
  //   两级延迟（s1_fire 锁存 → s2_fire 再延一拍）使 meta 与最终预测结果对齐后随
  //   last_stage 一起送出，供 FTQ 在 commit 时回传（pred_way 用于性能统计）。
  // ===========================================================================
  logic                 meta_hit_s2,  meta_hit_s3;
  logic [WAY_IDX_W-1:0] meta_way_s2,  meta_way_s3;
  always_ff @(posedge clock) begin
    if (io_s1_fire_0) begin
      meta_hit_s2 <= s1_hit;
      meta_way_s2 <= s1_hit_way;
    end
    if (io_s2_fire_0) begin
      meta_hit_s3 <= meta_hit_s2;
      meta_way_s3 <= meta_way_s2;
    end
  end
  assign io_out_last_stage_meta =
      {{(META_W-1-WAY_IDX_W){1'b0}}, meta_way_s3, meta_hit_s3};

  // ===========================================================================
  // 更新流水 s0：寄存 FTQ 送来的 update 请求
  //   u_valid 带异步复位初值 0；u_bits_* 仅在 update.valid 时锁存（省翻转）。
  // ===========================================================================
  logic        u_valid;
  ftb_entry_t  u_bits_entry;
  logic        u_bits_br_taken_0, u_bits_br_taken_1;
  logic [META_W-1:0] u_bits_meta;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) u_valid <= 1'b0;
    else       u_valid <= io_update_valid;
  end

  always_ff @(posedge clock) begin
    if (io_update_valid) begin
      u_bits_entry.valid            <= io_update_bits_ftb_entry_valid;
      u_bits_entry.isCall           <= io_update_bits_ftb_entry_isCall;
      u_bits_entry.isRet            <= io_update_bits_ftb_entry_isRet;
      u_bits_entry.isJalr           <= io_update_bits_ftb_entry_isJalr;
      u_bits_entry.brSlot.offset    <= io_update_bits_ftb_entry_brSlots_0_offset;
      u_bits_entry.brSlot.sharing   <= io_update_bits_ftb_entry_brSlots_0_sharing;
      u_bits_entry.brSlot.valid     <= io_update_bits_ftb_entry_brSlots_0_valid;
      u_bits_entry.brSlot.lower     <= io_update_bits_ftb_entry_brSlots_0_lower;   // 12 位
      u_bits_entry.brSlot.tarStat   <= io_update_bits_ftb_entry_brSlots_0_tarStat;
      u_bits_entry.tailSlot.offset  <= io_update_bits_ftb_entry_tailSlot_offset;
      u_bits_entry.tailSlot.sharing <= io_update_bits_ftb_entry_tailSlot_sharing;
      u_bits_entry.tailSlot.valid   <= io_update_bits_ftb_entry_tailSlot_valid;
      u_bits_entry.tailSlot.lower   <= io_update_bits_ftb_entry_tailSlot_lower;
      u_bits_entry.tailSlot.tarStat <= io_update_bits_ftb_entry_tailSlot_tarStat;
      u_bits_entry.pftAddr          <= io_update_bits_ftb_entry_pftAddr;
      u_bits_entry.carry            <= io_update_bits_ftb_entry_carry;
      u_bits_entry.last_may_be_rvi_call <= io_update_bits_ftb_entry_last_may_be_rvi_call;
      u_bits_entry.strong_bias      <= {io_update_bits_ftb_entry_strong_bias_1,
                                        io_update_bits_ftb_entry_strong_bias_0};
      u_bits_br_taken_0 <= io_update_bits_br_taken_mask_0;
      u_bits_br_taken_1 <= io_update_bits_br_taken_mask_1;
      u_bits_meta       <= io_update_bits_meta;
    end
  end

  wire [NUM_WAYS-1:0] u_s0_hit_oh = way_update_hit;

  // 各分支本次是否需要更新其饱和计数器（s0 算，s1 用）：
  //   - 该分支 slot 有效，且本次 update 有效，且非强偏置（强偏置不靠计数器）。
  //   - 对第 2 分支(tail 共享)：还要求第 1 分支本次未 taken——因为若 br0 已 taken，
  //     取指会从 br0 跳走，根本走不到 br1，br1 的方向信息这次不可信。
  wire u_s0_br_upd_valid_0 = u_bits_entry.brSlot.valid & u_valid & ~u_bits_entry.strong_bias[0];
  wire u_s0_br_upd_valid_1 = u_bits_entry.tailSlot.valid & u_bits_entry.tailSlot.sharing
                           & u_valid & ~u_bits_entry.strong_bias[1] & ~u_bits_br_taken_0;

  // ===========================================================================
  // 更新流水 s1：选写入路（命中→原路；未命中→PLRU victim）+ 写使能 + 计数更新有效
  // ===========================================================================
  logic                u_s1_valid;
  logic [NUM_WAYS-1:0] u_s1_hit_oh;
  logic                u_s1_hit;
  logic                u_s1_br_upd_valid_0, u_s1_br_upd_valid_1;
  logic                u_s1_br_taken_0, u_s1_br_taken_1;

  always_ff @(posedge clock) begin
    if (u_valid) begin
      u_s1_tag    <= update_tag;
      u_s1_hit_oh <= u_s0_hit_oh;
      u_s1_hit    <= |u_s0_hit_oh;
      u_s1_entry  <= u_bits_entry;
      u_s1_br_upd_valid_0 <= u_s0_br_upd_valid_0;
      u_s1_br_upd_valid_1 <= u_s0_br_upd_valid_1;
      u_s1_br_taken_0     <= u_bits_br_taken_0;
      u_s1_br_taken_1     <= u_bits_br_taken_1;
    end
  end
  always_ff @(posedge clock) u_s1_valid <= u_valid;

  // PLRU 状态寄存器（31 位）
  logic [NUM_WAYS-2:0]  plru_state;
  wire [WAY_IDX_W-1:0]  u_s1_alloc_way = plru_victim(plru_state);

  // 写哪一路：命中沿用命中路；未命中用 PLRU victim（one-hot）
  wire [NUM_WAYS-1:0] u_s1_write_oh =
      u_s1_hit ? u_s1_hit_oh : (NUM_WAYS'(1) << u_s1_alloc_way);

  always_comb begin
    for (int i = 0; i < NUM_WAYS; i++)
      way_write_valid[i] = u_s1_write_oh[i] & u_s1_valid;
  end

  // ===========================================================================
  // PLRU 状态更新：两个 touch 源依次作用
  //   1) 预测命中触摸（pred touch）：S1 预测命中过的路被"用过"，应远离 victim。
  //      该信号比命中晚一拍寄存（与 golden 的 replacer_touch_ways(0) 时序一致）。
  //   2) commit 写入触摸（commit touch）：本拍真正写入的路（命中改写或新分配）也"用过"。
  //   commit 作用在 pred 已更新过的状态上（顺序串联）。
  // ===========================================================================
  logic                 pred_touch_valid;
  logic [WAY_IDX_W-1:0] pred_touch_way;
  always_ff @(posedge clock) begin
    pred_touch_valid <= io_s1_fire_0 & s1_hit;
    if (io_s1_fire_0 & s1_hit) pred_touch_way <= s1_hit_way;
  end

  wire [WAY_IDX_W-1:0] commit_touch_way = oh_to_idx(u_s1_write_oh);

  wire [NUM_WAYS-2:0] state_after_pred =
      pred_touch_valid ? plru_touch(plru_state, pred_touch_way) : plru_state;
  wire [NUM_WAYS-2:0] state_after_commit =
      u_s1_valid ? plru_touch(state_after_pred, commit_touch_way) : state_after_pred;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) plru_state <= '0;
    else       plru_state <= state_after_commit;
  end

  // ===========================================================================
  // 饱和计数器更新：仅本拍被写入(write_valid)且该分支需更新(upd_valid)的路才动。
  //   复位为弱 taken(2)；据本次真实 taken satUpdate。
  // ===========================================================================
  genvar gc, gb;
  generate
    for (gc = 0; gc < NUM_WAYS; gc++) begin : g_ctr_way
      for (gb = 0; gb < NUM_BR; gb++) begin : g_ctr_br
        wire upd_valid = (gb == 0) ? u_s1_br_upd_valid_0 : u_s1_br_upd_valid_1;
        wire taken     = (gb == 0) ? u_s1_br_taken_0     : u_s1_br_taken_1;
        always_ff @(posedge clock or posedge reset) begin
          if (reset)
            ctrs[gc][gb] <= 2'd2;
          else if (way_write_valid[gc] & upd_valid)
            ctrs[gc][gb] <= sat_update(ctrs[gc][gb], taken);
        end
      end
    end
  endgenerate

  // ===========================================================================
  // 性能计数：io_perf_*_value = {5'h0, 延两拍的事件}
  //   perf0 = commit 命中（u_valid 且 meta.hit）；perf1 = commit 未命中。
  //   meta.hit 即 update.bits.meta[0]（uFTB meta 最低位存当初预测是否命中）。
  // ===========================================================================
  logic perf_hit_d0, perf_hit_d1, perf_miss_d0, perf_miss_d1;
  always_ff @(posedge clock) begin
    perf_hit_d0  <= u_valid &  u_bits_meta[0];
    perf_hit_d1  <= perf_hit_d0;
    perf_miss_d0 <= u_valid & ~u_bits_meta[0];
    perf_miss_d1 <= perf_miss_d0;
  end
  assign io_perf_0_value = {5'h0, perf_hit_d1};
  assign io_perf_1_value = {5'h0, perf_miss_d1};

  // 抑制未使用 dup fire 端口（1..3 与 s2_fire_0 之外的 dup）的 lint 警告
  wire _unused = &{1'b0, io_s1_fire_1, io_s1_fire_2, io_s1_fire_3,
                   io_s2_fire_1, io_s2_fire_2, io_s2_fire_3, 1'b0};

endmodule
