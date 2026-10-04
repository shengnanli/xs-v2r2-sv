// =============================================================================
// FauFTB.sv —— uFTB（微 FTB）：32 路全相联的小 FTB，BPU 的 S1 零气泡预测器
//
// 【在 BPU 里的位置】Composer 菊花链的链头。S0 给出取指 PC，S1 当拍用 PC 的 16 位 tag
//   在 32 路里全相联比较；命中就把那一路存的 FTB 条目当场展开成一份"完整预测"
//   （两个 CFI 槽的有效位/偏移/目标、fall-through 地址、jal/jalr/call/ret 标志，
//   以及每个条件分支的方向），直接作为 S1 预测送给取指——不用等 SRAM，所以零气泡。
//   之后更慢更准的 FTB/TAGE 在 S2/S3 覆盖它。
//   （Chisel：src/main/scala/xiangshan/frontend/FauFTB.scala class FauFTB）
//
// 【每一路存什么】FauFTBWay（已签核子模块，32 份）：一个 FTB 条目 + 16 位 tag + valid。
//   本层另为每一路存两个 2 位饱和计数器 ctrs[way][br]（复位为 2 = 弱跳），
//   条件分支的预测方向 = 计数器高位 | 条目里的 strong_bias。
//
// 【预测（S1）】
//   hit_oh[w] = ways[w] 的 tag 等于 s1_pc[16:1] 且有效。
//   ★多路同时命中按 Mux1H 的"按位或"合成（与 golden 一致，不是优先选择）★——
//   正常运行时写旁路保证不会多命中，但状态空间里允许，FM 逐点比所以必须照搬。
//   输出 hit = 有命中 且 ubtb_enable（CSR 开关，打一拍后用）。
//
// 【更新（两拍）】FTQ 提交时送来 update（pc / 新 FTB 条目 / 实际跳转掩码 / 预测时的 meta）。
//   u_s0（update 到达后一拍）：u_bits 锁存条目；用 update_pc 的 tag 现场查 32 路
//     （查找口带写旁路：本拍正在写的 tag 也算命中，防止同一 tag 落进两路）；
//     算每个分支槽的计数器是否该更新（槽有效、非 strong_bias、前面的分支没跳）。
//   u_s1：命中就写回命中那一路，否则写 PLRU 选出的替换路；被写那一路的计数器饱和 ±1。
//
// 【PLRU 替换】32 路树形伪 LRU（31 位状态）。每拍最多两次 touch，按顺序叠加：
//   先是"上一拍 S1 预测命中的那一路"（打一拍），再是"本拍 u_s1 写的那一路"。
//
// 【meta】预测命中与命中路号经 S1->S2->S3 两级打拍后放在 last_stage_meta 的低 6 位，
//   随 FTQ 回到 update.meta；本层只用其中 hit 位做性能计数。
//
// 复位域：ways 的 valid、ctrs、PLRU 状态、u_valid、BPU 公共外壳的 modified_reset 与
//   s2/s3 段寄存器异步复位；其余（各级打拍、u_bits、u_s1_*、meta、perf）无复位，照 golden。
//   死寄存器照搬不删：u_bits_meta 存满 516 位但只读 [0]；uftb_write_pc 只喂断言；
//   s0_fire_next_cycle 只喂 perf 探针；s2/s3 段 PC 无消费者（FM 侧按 vmucp 对称死位证）。
// =============================================================================
package fauftb_pkg;
  import xs_ftb_pkg::*;

  localparam int unsigned NUM_WAYS = 32;
  localparam int unsigned WAY_W    = 5;
  localparam int unsigned TAG_W    = 16;
  localparam int unsigned NUM_DUP  = 4;
  localparam int unsigned PC_W     = 50;
  localparam int unsigned META_W   = 516;

  // FullBranchPrediction（S1 用的那一版：isNotS3，无 predCycle）。hit 单独给。
  typedef struct packed {
    logic [1:0]            br_taken_mask;
    logic [1:0]            slot_valids;      // [0]=brSlot, [1]=tailSlot
    logic [1:0][PC_W-1:0]  targets;
    logic [PC_W-1:0]       jalr_target;
    logic [1:0][3:0]       offsets;
    logic [PC_W-1:0]       fall_through_addr;
    logic                  fall_through_err;
    logic                  is_jal;
    logic                  is_jalr;
    logic                  is_call;
    logic                  is_ret;
    logic                  last_may_be_rvi_call;
    logic                  is_br_sharing;
  } full_pred_t;

  // FullBranchPrediction.fromFtbEntry(entry, pc) + 每个条件分支方向 = ctr 高位 | strong_bias
  function automatic full_pred_t pred_from_entry(input ftb_entry_t e, input logic [1:0] ctr_hi,
                                                 input logic [PC_W-1:0] pc);
    full_pred_t       p;
    logic [4:0]       start_lower;
    logic [4:0]       end_lower;
    p.br_taken_mask = ctr_hi | e.strong_bias;
    p.slot_valids   = {e.tailSlot.valid, e.brSlot.valid};
    // 目标重建：PC 高位 ±1 / 原样（按 tarStat），拼上存的低位。tailSlot 被共享成第二个
    // 条件分支时按 12 位低位宽算，否则按 20 位。
    p.targets[0]    = get_target(pc, JMP_OFF_LEN'(e.brSlot.lower), e.brSlot.tarStat, BR_OFF_LEN);
    p.targets[1]    = e.tailSlot.sharing
                        ? get_target(pc, e.tailSlot.lower, e.tailSlot.tarStat, BR_OFF_LEN)
                        : get_target(pc, e.tailSlot.lower, e.tailSlot.tarStat, JMP_OFF_LEN);
    p.jalr_target   = p.targets[1];
    p.offsets       = {e.tailSlot.offset, e.brSlot.offset};
    p.is_jal        = e.tailSlot.valid && !e.isJalr;
    p.is_jalr       = e.tailSlot.valid && e.isJalr;
    p.is_call       = e.tailSlot.valid && e.isCall;
    p.is_ret        = e.tailSlot.valid && e.isRet;
    p.last_may_be_rvi_call = e.last_may_be_rvi_call;
    p.is_br_sharing = e.tailSlot.valid && e.tailSlot.sharing;
    // fall-through 合法性：块起点（块内指令号）必须严格小于终点，且终点不超过起点 + 16
    start_lower        = {1'b0, pc[4:1]};
    end_lower          = {e.carry, e.pftAddr};
    p.fall_through_err = (start_lower >= end_lower) || (end_lower > 5'(start_lower + 5'd16));
    p.fall_through_addr = p.fall_through_err
                            ? PC_W'(pc + 50'd32)
                            : {(e.carry ? 45'(pc[49:5] + 45'd1) : pc[49:5]), e.pftAddr, 1'b0};
    return p;
  endfunction

  // ---- 32 路树形 PLRU（rocket-chip PseudoLRU 编码，同 rtl/common/xs_PlruReplacer.sv）----
  // 状态段 [offset +: m-1] 描述覆盖 m 路的子树，段最高位是根：1 = 下次替换高半边。
  function automatic logic [WAY_W-1:0] plru_victim(input logic [NUM_WAYS-2:0] s);
    int unsigned offset, m;
    logic [WAY_W-1:0] way;
    offset = 0; m = NUM_WAYS; way = '0;
    for (int unsigned l = 0; l < WAY_W; l++) begin
      way = {way[WAY_W-2:0], s[offset + m - 2]};
      if (s[offset + m - 2]) offset += m / 2 - 1;
      m /= 2;
    end
    return way;
  endfunction

  // touch：沿该路的树路径，把每个节点写成"指向另一半边"
  function automatic logic [NUM_WAYS-2:0] plru_touch(input logic [NUM_WAYS-2:0] s,
                                                     input logic [WAY_W-1:0] way);
    int unsigned offset, m;
    logic b;
    offset = 0; m = NUM_WAYS;
    for (int unsigned l = 0; l < WAY_W; l++) begin
      b = way[WAY_W - 1 - l];
      s[offset + m - 2] = ~b;
      if (b) offset += m / 2 - 1;
      m /= 2;
    end
    return s;
  endfunction

  // 独热 -> 下标（OHToUInt：各置位下标按位或）
  function automatic logic [WAY_W-1:0] oh_to_index(input logic [NUM_WAYS-1:0] oh);
    logic [WAY_W-1:0] idx;
    idx = '0;
    for (int unsigned i = 0; i < NUM_WAYS; i++)
      if (oh[i]) idx |= WAY_W'(i);
    return idx;
  endfunction

  // 2 位无符号饱和计数器 ±1（BPU.scala satUpdate）
  function automatic logic [1:0] sat2_update(input logic [1:0] old, input logic taken);
    if (old == 2'd3 && taken)       return 2'd3;
    else if (old == 2'd0 && !taken) return 2'd0;
    else if (taken)                 return old + 2'd1;
    else                            return old - 2'd1;
  endfunction

endpackage

module xs_FauFTB_core
  import xs_ftb_pkg::*;
  import fauftb_pkg::*;
(
  input  logic                clock,
  input  logic                reset,
  input  logic [47:0]         reset_vector,
  input  logic [PC_W-1:0]     s0_pc    [NUM_DUP],
  input  logic                s0_fire  [NUM_DUP],
  input  logic                s1_fire  [NUM_DUP],
  input  logic                s2_fire  [NUM_DUP],
  input  logic                ubtb_enable,
  // ---- S1 预测输出 ----
  output logic [PC_W-1:0]     s1_pc    [NUM_DUP],
  output full_pred_t          s1_pred,
  output logic                s1_hit_out,          // 命中且 uFTB 使能
  output ftb_entry_t          s1_entry_out,        // 命中那一路的原始条目（给 FTB 用）
  output logic [META_W-1:0]   last_stage_meta,
  // ---- 更新 ----
  input  logic                update_valid,
  input  logic [PC_W-1:0]     update_pc,
  input  ftb_entry_t          update_entry,
  input  logic [1:0]          update_br_taken,
  input  logic [META_W-1:0]   update_meta,
  // ---- 性能计数（各 1 位有效）----
  output logic                perf_commit_hit,
  output logic                perf_commit_miss
);

  // ===========================================================================
  // §0 BPU 公共外壳：各级 PC（s2/s3 段 PC 在本预测器里无消费者）
  // ===========================================================================
  logic [PC_W-1:0] s2_pc_unused [NUM_DUP];
  logic [PC_W-1:0] s3_pc_unused [NUM_DUP];

  xs_BpuStagePc #(
    .NUM_DUP (NUM_DUP),
    .PC_W    (PC_W)
  ) u_stage_pc (
    .clock        (clock),
    .reset        (reset),
    .reset_vector (reset_vector),
    .s0_pc        (s0_pc),
    .s0_fire      (s0_fire),
    .s1_fire      (s1_fire),
    .s2_fire      (s2_fire),
    .s1_pc        (s1_pc),
    .s2_pc        (s2_pc_unused),
    .s3_pc        (s3_pc_unused)
  );

  // ===========================================================================
  // 32 路存储与每路计数器
  // ===========================================================================
  ftb_entry_t          way_entry     [NUM_WAYS];
  logic [NUM_WAYS-1:0] s1_hit_oh;          // 预测口命中
  logic [NUM_WAYS-1:0] u_s0_hit_oh;        // 更新查找口命中（含写旁路）
  logic [NUM_WAYS-1:0] way_write_valid;
  logic [TAG_W-1:0]    u_s1_tag;
  ftb_entry_t          u_s1_entry;
  logic [1:0]          ctrs          [NUM_WAYS][2];   // [way][br]，复位为 2

  for (genvar w = 0; w < NUM_WAYS; w++) begin : g_way
    FauFTBWay u_way (
      .clock                               (clock),
      .reset                               (reset),
      .io_req_tag                          (s1_pc[0][TAG_W:1]),
      .io_resp_isCall                      (way_entry[w].isCall),
      .io_resp_isRet                       (way_entry[w].isRet),
      .io_resp_isJalr                      (way_entry[w].isJalr),
      .io_resp_valid                       (way_entry[w].valid),
      .io_resp_brSlots_0_offset            (way_entry[w].brSlot.offset),
      .io_resp_brSlots_0_sharing           (way_entry[w].brSlot.sharing),
      .io_resp_brSlots_0_valid             (way_entry[w].brSlot.valid),
      .io_resp_brSlots_0_lower             (way_entry[w].brSlot.lower),
      .io_resp_brSlots_0_tarStat           (way_entry[w].brSlot.tarStat),
      .io_resp_tailSlot_offset             (way_entry[w].tailSlot.offset),
      .io_resp_tailSlot_sharing            (way_entry[w].tailSlot.sharing),
      .io_resp_tailSlot_valid              (way_entry[w].tailSlot.valid),
      .io_resp_tailSlot_lower              (way_entry[w].tailSlot.lower),
      .io_resp_tailSlot_tarStat            (way_entry[w].tailSlot.tarStat),
      .io_resp_pftAddr                     (way_entry[w].pftAddr),
      .io_resp_carry                       (way_entry[w].carry),
      .io_resp_last_may_be_rvi_call        (way_entry[w].last_may_be_rvi_call),
      .io_resp_strong_bias_0               (way_entry[w].strong_bias[0]),
      .io_resp_strong_bias_1               (way_entry[w].strong_bias[1]),
      .io_resp_hit                         (s1_hit_oh[w]),
      .io_update_req_tag                   (update_pc[TAG_W:1]),
      .io_update_hit                       (u_s0_hit_oh[w]),
      .io_write_valid                      (way_write_valid[w]),
      .io_write_entry_isCall               (u_s1_entry.isCall),
      .io_write_entry_isRet                (u_s1_entry.isRet),
      .io_write_entry_isJalr               (u_s1_entry.isJalr),
      .io_write_entry_valid                (u_s1_entry.valid),
      .io_write_entry_brSlots_0_offset     (u_s1_entry.brSlot.offset),
      .io_write_entry_brSlots_0_sharing    (u_s1_entry.brSlot.sharing),
      .io_write_entry_brSlots_0_valid      (u_s1_entry.brSlot.valid),
      .io_write_entry_brSlots_0_lower      (u_s1_entry.brSlot.lower),
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
  end

  // ===========================================================================
  // §1 S1 预测：全相联命中 -> 每路展开成完整预测 -> Mux1H（按位或）合成
  // ===========================================================================
  logic             s1_hit;
  logic [WAY_W-1:0] s1_hit_way;
  logic             fauftb_enable;           // RegNext(ubtb_enable)，无复位

  assign s1_hit     = |s1_hit_oh;
  assign s1_hit_way = oh_to_index(s1_hit_oh);

  always_comb begin
    s1_pred      = '0;
    s1_entry_out = '0;
    for (int w = 0; w < NUM_WAYS; w++) begin
      if (s1_hit_oh[w]) begin
        s1_pred      |= pred_from_entry(way_entry[w], {ctrs[w][1][1], ctrs[w][0][1]}, s1_pc[0]);
        s1_entry_out |= way_entry[w];
      end
    end
  end

  assign s1_hit_out = s1_hit && fauftb_enable;

  // ===========================================================================
  // §2 meta：命中与命中路号 S1->S2->S3 两级打拍，放在 last_stage_meta 低 6 位
  // ===========================================================================
  logic             meta_hit_s2, meta_hit_s3;
  logic [WAY_W-1:0] meta_way_s2, meta_way_s3;

  always_ff @(posedge clock) begin
    fauftb_enable <= ubtb_enable;
    if (s1_fire[0]) begin
      meta_hit_s2 <= s1_hit;
      meta_way_s2 <= s1_hit_way;
    end
    if (s2_fire[0]) begin
      meta_hit_s3 <= meta_hit_s2;
      meta_way_s3 <= meta_way_s2;
    end
  end

  // FauFTBMeta = {pred_way, hit}（pred_way 在高位）
  assign last_stage_meta = {{(META_W - WAY_W - 1){1'b0}}, meta_way_s3, meta_hit_s3};

  // ===========================================================================
  // §3 更新 u_s0：锁存 update，查 32 路，算各分支槽计数器是否更新
  // ===========================================================================
  logic              u_valid;                // RegNext(update.valid)，异步复位
  ftb_entry_t        u_bits_entry;
  logic [1:0]        u_bits_br_taken;
  logic [META_W-1:0] u_bits_meta;            // 只读 [0]（meta.hit）
  logic              u_s0_hit;
  logic [1:0]        u_s0_br_update_valids;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) u_valid <= 1'b0;
    else       u_valid <= update_valid;
  end

  always_ff @(posedge clock) begin
    if (update_valid) begin
      u_bits_entry    <= update_entry;
      u_bits_br_taken <= update_br_taken;
      u_bits_meta     <= update_meta;
    end
  end

  assign u_s0_hit = |u_s0_hit_oh;
  // 槽 0（brSlot）：有效且非强偏置；槽 1（被共享的 tailSlot）：另要求槽 0 没跳
  // （!(PriorityEncoder(br_taken_mask) < 1)）
  assign u_s0_br_update_valids[0] = u_bits_entry.brSlot.valid && u_valid && !u_bits_entry.strong_bias[0];
  assign u_s0_br_update_valids[1] = u_bits_entry.tailSlot.valid && u_bits_entry.tailSlot.sharing
                                    && u_valid && !u_bits_entry.strong_bias[1] && !u_bits_br_taken[0];

  // ===========================================================================
  // §4 更新 u_s1：选写哪一路（命中路 / PLRU 替换路），写条目，计数器饱和 ±1
  // ===========================================================================
  logic                u_s1_valid;
  logic [NUM_WAYS-1:0] u_s1_hit_oh;
  logic                u_s1_hit;
  logic [PC_W-1:0]     uftb_write_pc;        // 只喂断言（SYNTHESIS 下无读者）
  logic [1:0]          u_s1_br_update_valids;
  logic [1:0]          u_s1_br_takens;
  logic [NUM_WAYS-2:0] plru_state;
  logic [WAY_W-1:0]    u_s1_alloc_way;
  logic [NUM_WAYS-1:0] u_s1_write_way_oh;

  always_ff @(posedge clock) begin
    u_s1_valid <= u_valid;
    if (u_valid) begin
      u_s1_tag              <= update_pc[TAG_W:1];
      u_s1_hit_oh           <= u_s0_hit_oh;
      u_s1_hit              <= u_s0_hit;
      u_s1_entry            <= u_bits_entry;
      uftb_write_pc         <= update_pc;
      u_s1_br_update_valids <= u_s0_br_update_valids;
      u_s1_br_takens        <= u_bits_br_taken;
    end
  end

  assign u_s1_alloc_way    = plru_victim(plru_state);
  assign u_s1_write_way_oh = u_s1_hit ? u_s1_hit_oh : (NUM_WAYS'(1) << u_s1_alloc_way);
  assign way_write_valid   = u_s1_write_way_oh & {NUM_WAYS{u_s1_valid}};

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int w = 0; w < NUM_WAYS; w++) begin
        ctrs[w][0] <= 2'd2;
        ctrs[w][1] <= 2'd2;
      end
    end else begin
      for (int w = 0; w < NUM_WAYS; w++)
        for (int br = 0; br < 2; br++)
          if (way_write_valid[w] && u_s1_br_update_valids[br])
            ctrs[w][br] <= sat2_update(ctrs[w][br], u_s1_br_takens[br]);
    end
  end

  // ===========================================================================
  // §5 PLRU：先叠加"上一拍预测命中那一路"，再叠加"本拍写的那一路"
  // ===========================================================================
  logic             touch_pred_valid;        // RegNext(s1_fire && s1_hit)，无复位
  logic [WAY_W-1:0] touch_pred_way;          // RegEnable(s1_hit_way, s1_fire && s1_hit)
  logic [NUM_WAYS-2:0] plru_after_pred;

  always_ff @(posedge clock) begin
    touch_pred_valid <= s1_fire[0] && s1_hit;
    if (s1_fire[0] && s1_hit) touch_pred_way <= s1_hit_way;
  end

  assign plru_after_pred = touch_pred_valid ? plru_touch(plru_state, touch_pred_way) : plru_state;

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      plru_state <= '0;
    else if (u_s1_valid)
      plru_state <= plru_touch(plru_after_pred, oh_to_index(u_s1_write_way_oh));
    else if (touch_pred_valid)
      plru_state <= plru_after_pred;
  end

  // ===========================================================================
  // §6 perf：提交时命中 / 未命中（各打 2 拍）
  // ===========================================================================
  logic s0_fire_next_cycle;                  // 只喂 perf 探针（SYNTHESIS 下无读者）
  logic perf_hit_d1, perf_miss_d1;

  always_ff @(posedge clock) begin
    s0_fire_next_cycle <= s0_fire[0];
    perf_hit_d1        <= u_valid && u_bits_meta[0];
    perf_commit_hit    <= perf_hit_d1;
    perf_miss_d1       <= u_valid && !u_bits_meta[0];
    perf_commit_miss   <= perf_miss_d1;
  end

endmodule

// =============================================================================
// FauFTB —— golden 同名 wrapper：端口展平 / 打包（端口表逐位照 G1 golden）
// =============================================================================
module FauFTB
  import xs_ftb_pkg::*;
  import fauftb_pkg::*;
(
  input  clock,
  input  reset,
  input  [47:0] io_reset_vector,
  input  [49:0] io_in_bits_s0_pc_0,
  input  [49:0] io_in_bits_s0_pc_1,
  input  [49:0] io_in_bits_s0_pc_2,
  input  [49:0] io_in_bits_s0_pc_3,
  output [49:0] io_out_s1_pc_0,
  output [49:0] io_out_s1_pc_1,
  output [49:0] io_out_s1_pc_2,
  output [49:0] io_out_s1_pc_3,
  output io_out_s1_full_pred_0_br_taken_mask_0,
  output io_out_s1_full_pred_0_br_taken_mask_1,
  output io_out_s1_full_pred_0_slot_valids_0,
  output io_out_s1_full_pred_0_slot_valids_1,
  output [49:0] io_out_s1_full_pred_0_targets_0,
  output [49:0] io_out_s1_full_pred_0_targets_1,
  output [49:0] io_out_s1_full_pred_0_jalr_target,
  output [3:0] io_out_s1_full_pred_0_offsets_0,
  output [3:0] io_out_s1_full_pred_0_offsets_1,
  output [49:0] io_out_s1_full_pred_0_fallThroughAddr,
  output io_out_s1_full_pred_0_fallThroughErr,
  output io_out_s1_full_pred_0_is_jal,
  output io_out_s1_full_pred_0_is_jalr,
  output io_out_s1_full_pred_0_is_call,
  output io_out_s1_full_pred_0_is_ret,
  output io_out_s1_full_pred_0_last_may_be_rvi_call,
  output io_out_s1_full_pred_0_is_br_sharing,
  output io_out_s1_full_pred_0_hit,
  output io_out_s1_full_pred_1_br_taken_mask_0,
  output io_out_s1_full_pred_1_br_taken_mask_1,
  output io_out_s1_full_pred_1_slot_valids_0,
  output io_out_s1_full_pred_1_slot_valids_1,
  output [49:0] io_out_s1_full_pred_1_targets_0,
  output [49:0] io_out_s1_full_pred_1_targets_1,
  output [49:0] io_out_s1_full_pred_1_jalr_target,
  output [3:0] io_out_s1_full_pred_1_offsets_0,
  output [3:0] io_out_s1_full_pred_1_offsets_1,
  output [49:0] io_out_s1_full_pred_1_fallThroughAddr,
  output io_out_s1_full_pred_1_fallThroughErr,
  output io_out_s1_full_pred_1_is_jal,
  output io_out_s1_full_pred_1_is_jalr,
  output io_out_s1_full_pred_1_is_call,
  output io_out_s1_full_pred_1_is_ret,
  output io_out_s1_full_pred_1_last_may_be_rvi_call,
  output io_out_s1_full_pred_1_is_br_sharing,
  output io_out_s1_full_pred_1_hit,
  output io_out_s1_full_pred_2_br_taken_mask_0,
  output io_out_s1_full_pred_2_br_taken_mask_1,
  output io_out_s1_full_pred_2_slot_valids_0,
  output io_out_s1_full_pred_2_slot_valids_1,
  output [49:0] io_out_s1_full_pred_2_targets_0,
  output [49:0] io_out_s1_full_pred_2_targets_1,
  output [49:0] io_out_s1_full_pred_2_jalr_target,
  output [3:0] io_out_s1_full_pred_2_offsets_0,
  output [3:0] io_out_s1_full_pred_2_offsets_1,
  output [49:0] io_out_s1_full_pred_2_fallThroughAddr,
  output io_out_s1_full_pred_2_fallThroughErr,
  output io_out_s1_full_pred_2_is_jal,
  output io_out_s1_full_pred_2_is_jalr,
  output io_out_s1_full_pred_2_is_call,
  output io_out_s1_full_pred_2_is_ret,
  output io_out_s1_full_pred_2_last_may_be_rvi_call,
  output io_out_s1_full_pred_2_is_br_sharing,
  output io_out_s1_full_pred_2_hit,
  output io_out_s1_full_pred_3_br_taken_mask_0,
  output io_out_s1_full_pred_3_br_taken_mask_1,
  output io_out_s1_full_pred_3_slot_valids_0,
  output io_out_s1_full_pred_3_slot_valids_1,
  output [49:0] io_out_s1_full_pred_3_targets_0,
  output [49:0] io_out_s1_full_pred_3_targets_1,
  output [49:0] io_out_s1_full_pred_3_jalr_target,
  output [3:0] io_out_s1_full_pred_3_offsets_0,
  output [3:0] io_out_s1_full_pred_3_offsets_1,
  output [49:0] io_out_s1_full_pred_3_fallThroughAddr,
  output io_out_s1_full_pred_3_fallThroughErr,
  output io_out_s1_full_pred_3_is_jal,
  output io_out_s1_full_pred_3_is_jalr,
  output io_out_s1_full_pred_3_is_call,
  output io_out_s1_full_pred_3_is_ret,
  output io_out_s1_full_pred_3_last_may_be_rvi_call,
  output io_out_s1_full_pred_3_is_br_sharing,
  output io_out_s1_full_pred_3_hit,
  output [515:0] io_out_last_stage_meta,
  output io_fauftb_entry_out_isCall,
  output io_fauftb_entry_out_isRet,
  output io_fauftb_entry_out_isJalr,
  output io_fauftb_entry_out_valid,
  output [3:0] io_fauftb_entry_out_brSlots_0_offset,
  output io_fauftb_entry_out_brSlots_0_sharing,
  output io_fauftb_entry_out_brSlots_0_valid,
  output [11:0] io_fauftb_entry_out_brSlots_0_lower,
  output [1:0] io_fauftb_entry_out_brSlots_0_tarStat,
  output [3:0] io_fauftb_entry_out_tailSlot_offset,
  output io_fauftb_entry_out_tailSlot_sharing,
  output io_fauftb_entry_out_tailSlot_valid,
  output [19:0] io_fauftb_entry_out_tailSlot_lower,
  output [1:0] io_fauftb_entry_out_tailSlot_tarStat,
  output [3:0] io_fauftb_entry_out_pftAddr,
  output io_fauftb_entry_out_carry,
  output io_fauftb_entry_out_last_may_be_rvi_call,
  output io_fauftb_entry_out_strong_bias_0,
  output io_fauftb_entry_out_strong_bias_1,
  output io_fauftb_entry_hit_out,
  input  io_ctrl_ubtb_enable,
  input  io_s0_fire_0,
  input  io_s0_fire_1,
  input  io_s0_fire_2,
  input  io_s0_fire_3,
  input  io_s1_fire_0,
  input  io_s1_fire_1,
  input  io_s1_fire_2,
  input  io_s1_fire_3,
  input  io_s2_fire_0,
  input  io_s2_fire_1,
  input  io_s2_fire_2,
  input  io_s2_fire_3,
  input  io_update_valid,
  input  [49:0] io_update_bits_pc,
  input  io_update_bits_ftb_entry_isCall,
  input  io_update_bits_ftb_entry_isRet,
  input  io_update_bits_ftb_entry_isJalr,
  input  io_update_bits_ftb_entry_valid,
  input  [3:0] io_update_bits_ftb_entry_brSlots_0_offset,
  input  io_update_bits_ftb_entry_brSlots_0_sharing,
  input  io_update_bits_ftb_entry_brSlots_0_valid,
  input  [11:0] io_update_bits_ftb_entry_brSlots_0_lower,
  input  [1:0] io_update_bits_ftb_entry_brSlots_0_tarStat,
  input  [3:0] io_update_bits_ftb_entry_tailSlot_offset,
  input  io_update_bits_ftb_entry_tailSlot_sharing,
  input  io_update_bits_ftb_entry_tailSlot_valid,
  input  [19:0] io_update_bits_ftb_entry_tailSlot_lower,
  input  [1:0] io_update_bits_ftb_entry_tailSlot_tarStat,
  input  [3:0] io_update_bits_ftb_entry_pftAddr,
  input  io_update_bits_ftb_entry_carry,
  input  io_update_bits_ftb_entry_last_may_be_rvi_call,
  input  io_update_bits_ftb_entry_strong_bias_0,
  input  io_update_bits_ftb_entry_strong_bias_1,
  input  io_update_bits_br_taken_mask_0,
  input  io_update_bits_br_taken_mask_1,
  input  [515:0] io_update_bits_meta,
  output [5:0] io_perf_0_value,
  output [5:0] io_perf_1_value
);

  logic [PC_W-1:0] s0_pc   [NUM_DUP];
  logic            s0_fire [NUM_DUP];
  logic            s1_fire [NUM_DUP];
  logic            s2_fire [NUM_DUP];
  logic [PC_W-1:0] s1_pc   [NUM_DUP];
  full_pred_t      s1_pred;
  logic            s1_hit_out;
  ftb_entry_t      s1_entry_out;
  ftb_entry_t      update_entry;
  logic            perf_commit_hit;
  logic            perf_commit_miss;

  // ---- 4 份 dup 的 PC 与各级 fire ----
  assign s0_pc[0]   = io_in_bits_s0_pc_0;
  assign s0_pc[1]   = io_in_bits_s0_pc_1;
  assign s0_pc[2]   = io_in_bits_s0_pc_2;
  assign s0_pc[3]   = io_in_bits_s0_pc_3;
  assign s0_fire[0] = io_s0_fire_0;
  assign s0_fire[1] = io_s0_fire_1;
  assign s0_fire[2] = io_s0_fire_2;
  assign s0_fire[3] = io_s0_fire_3;
  assign s1_fire[0] = io_s1_fire_0;
  assign s1_fire[1] = io_s1_fire_1;
  assign s1_fire[2] = io_s1_fire_2;
  assign s1_fire[3] = io_s1_fire_3;
  assign s2_fire[0] = io_s2_fire_0;
  assign s2_fire[1] = io_s2_fire_1;
  assign s2_fire[2] = io_s2_fire_2;
  assign s2_fire[3] = io_s2_fire_3;

  // ---- 更新条目打包 ----
  assign update_entry.isCall = io_update_bits_ftb_entry_isCall;
  assign update_entry.isRet = io_update_bits_ftb_entry_isRet;
  assign update_entry.isJalr = io_update_bits_ftb_entry_isJalr;
  assign update_entry.valid = io_update_bits_ftb_entry_valid;
  assign update_entry.brSlot.offset = io_update_bits_ftb_entry_brSlots_0_offset;
  assign update_entry.brSlot.sharing = io_update_bits_ftb_entry_brSlots_0_sharing;
  assign update_entry.brSlot.valid = io_update_bits_ftb_entry_brSlots_0_valid;
  assign update_entry.brSlot.lower = io_update_bits_ftb_entry_brSlots_0_lower;
  assign update_entry.brSlot.tarStat = io_update_bits_ftb_entry_brSlots_0_tarStat;
  assign update_entry.tailSlot.offset = io_update_bits_ftb_entry_tailSlot_offset;
  assign update_entry.tailSlot.sharing = io_update_bits_ftb_entry_tailSlot_sharing;
  assign update_entry.tailSlot.valid = io_update_bits_ftb_entry_tailSlot_valid;
  assign update_entry.tailSlot.lower = io_update_bits_ftb_entry_tailSlot_lower;
  assign update_entry.tailSlot.tarStat = io_update_bits_ftb_entry_tailSlot_tarStat;
  assign update_entry.pftAddr = io_update_bits_ftb_entry_pftAddr;
  assign update_entry.carry = io_update_bits_ftb_entry_carry;
  assign update_entry.last_may_be_rvi_call = io_update_bits_ftb_entry_last_may_be_rvi_call;
  assign update_entry.strong_bias[0] = io_update_bits_ftb_entry_strong_bias_0;
  assign update_entry.strong_bias[1] = io_update_bits_ftb_entry_strong_bias_1;

  xs_FauFTB_core u_core (
    .clock            (clock),
    .reset            (reset),
    .reset_vector     (io_reset_vector),
    .s0_pc            (s0_pc),
    .s0_fire          (s0_fire),
    .s1_fire          (s1_fire),
    .s2_fire          (s2_fire),
    .ubtb_enable      (io_ctrl_ubtb_enable),
    .s1_pc            (s1_pc),
    .s1_pred          (s1_pred),
    .s1_hit_out       (s1_hit_out),
    .s1_entry_out     (s1_entry_out),
    .last_stage_meta  (io_out_last_stage_meta),
    .update_valid     (io_update_valid),
    .update_pc        (io_update_bits_pc),
    .update_entry     (update_entry),
    .update_br_taken  ({io_update_bits_br_taken_mask_1, io_update_bits_br_taken_mask_0}),
    .update_meta      (io_update_bits_meta),
    .perf_commit_hit  (perf_commit_hit),
    .perf_commit_miss (perf_commit_miss)
  );

  // ---- S1 预测：4 份 dup 输出同一份预测（golden 同样只用 dup 0 的 PC 算）----
  assign io_out_s1_pc_0 = s1_pc[0];
  assign io_out_s1_pc_1 = s1_pc[1];
  assign io_out_s1_pc_2 = s1_pc[2];
  assign io_out_s1_pc_3 = s1_pc[3];
  assign io_out_s1_full_pred_0_br_taken_mask_0 = s1_pred.br_taken_mask[0];
  assign io_out_s1_full_pred_0_br_taken_mask_1 = s1_pred.br_taken_mask[1];
  assign io_out_s1_full_pred_0_slot_valids_0 = s1_pred.slot_valids[0];
  assign io_out_s1_full_pred_0_slot_valids_1 = s1_pred.slot_valids[1];
  assign io_out_s1_full_pred_0_targets_0 = s1_pred.targets[0];
  assign io_out_s1_full_pred_0_targets_1 = s1_pred.targets[1];
  assign io_out_s1_full_pred_0_jalr_target = s1_pred.jalr_target;
  assign io_out_s1_full_pred_0_offsets_0 = s1_pred.offsets[0];
  assign io_out_s1_full_pred_0_offsets_1 = s1_pred.offsets[1];
  assign io_out_s1_full_pred_0_fallThroughAddr = s1_pred.fall_through_addr;
  assign io_out_s1_full_pred_0_fallThroughErr = s1_pred.fall_through_err;
  assign io_out_s1_full_pred_0_is_jal = s1_pred.is_jal;
  assign io_out_s1_full_pred_0_is_jalr = s1_pred.is_jalr;
  assign io_out_s1_full_pred_0_is_call = s1_pred.is_call;
  assign io_out_s1_full_pred_0_is_ret = s1_pred.is_ret;
  assign io_out_s1_full_pred_0_last_may_be_rvi_call = s1_pred.last_may_be_rvi_call;
  assign io_out_s1_full_pred_0_is_br_sharing = s1_pred.is_br_sharing;
  assign io_out_s1_full_pred_0_hit = s1_hit_out;
  assign io_out_s1_full_pred_1_br_taken_mask_0 = s1_pred.br_taken_mask[0];
  assign io_out_s1_full_pred_1_br_taken_mask_1 = s1_pred.br_taken_mask[1];
  assign io_out_s1_full_pred_1_slot_valids_0 = s1_pred.slot_valids[0];
  assign io_out_s1_full_pred_1_slot_valids_1 = s1_pred.slot_valids[1];
  assign io_out_s1_full_pred_1_targets_0 = s1_pred.targets[0];
  assign io_out_s1_full_pred_1_targets_1 = s1_pred.targets[1];
  assign io_out_s1_full_pred_1_jalr_target = s1_pred.jalr_target;
  assign io_out_s1_full_pred_1_offsets_0 = s1_pred.offsets[0];
  assign io_out_s1_full_pred_1_offsets_1 = s1_pred.offsets[1];
  assign io_out_s1_full_pred_1_fallThroughAddr = s1_pred.fall_through_addr;
  assign io_out_s1_full_pred_1_fallThroughErr = s1_pred.fall_through_err;
  assign io_out_s1_full_pred_1_is_jal = s1_pred.is_jal;
  assign io_out_s1_full_pred_1_is_jalr = s1_pred.is_jalr;
  assign io_out_s1_full_pred_1_is_call = s1_pred.is_call;
  assign io_out_s1_full_pred_1_is_ret = s1_pred.is_ret;
  assign io_out_s1_full_pred_1_last_may_be_rvi_call = s1_pred.last_may_be_rvi_call;
  assign io_out_s1_full_pred_1_is_br_sharing = s1_pred.is_br_sharing;
  assign io_out_s1_full_pred_1_hit = s1_hit_out;
  assign io_out_s1_full_pred_2_br_taken_mask_0 = s1_pred.br_taken_mask[0];
  assign io_out_s1_full_pred_2_br_taken_mask_1 = s1_pred.br_taken_mask[1];
  assign io_out_s1_full_pred_2_slot_valids_0 = s1_pred.slot_valids[0];
  assign io_out_s1_full_pred_2_slot_valids_1 = s1_pred.slot_valids[1];
  assign io_out_s1_full_pred_2_targets_0 = s1_pred.targets[0];
  assign io_out_s1_full_pred_2_targets_1 = s1_pred.targets[1];
  assign io_out_s1_full_pred_2_jalr_target = s1_pred.jalr_target;
  assign io_out_s1_full_pred_2_offsets_0 = s1_pred.offsets[0];
  assign io_out_s1_full_pred_2_offsets_1 = s1_pred.offsets[1];
  assign io_out_s1_full_pred_2_fallThroughAddr = s1_pred.fall_through_addr;
  assign io_out_s1_full_pred_2_fallThroughErr = s1_pred.fall_through_err;
  assign io_out_s1_full_pred_2_is_jal = s1_pred.is_jal;
  assign io_out_s1_full_pred_2_is_jalr = s1_pred.is_jalr;
  assign io_out_s1_full_pred_2_is_call = s1_pred.is_call;
  assign io_out_s1_full_pred_2_is_ret = s1_pred.is_ret;
  assign io_out_s1_full_pred_2_last_may_be_rvi_call = s1_pred.last_may_be_rvi_call;
  assign io_out_s1_full_pred_2_is_br_sharing = s1_pred.is_br_sharing;
  assign io_out_s1_full_pred_2_hit = s1_hit_out;
  assign io_out_s1_full_pred_3_br_taken_mask_0 = s1_pred.br_taken_mask[0];
  assign io_out_s1_full_pred_3_br_taken_mask_1 = s1_pred.br_taken_mask[1];
  assign io_out_s1_full_pred_3_slot_valids_0 = s1_pred.slot_valids[0];
  assign io_out_s1_full_pred_3_slot_valids_1 = s1_pred.slot_valids[1];
  assign io_out_s1_full_pred_3_targets_0 = s1_pred.targets[0];
  assign io_out_s1_full_pred_3_targets_1 = s1_pred.targets[1];
  assign io_out_s1_full_pred_3_jalr_target = s1_pred.jalr_target;
  assign io_out_s1_full_pred_3_offsets_0 = s1_pred.offsets[0];
  assign io_out_s1_full_pred_3_offsets_1 = s1_pred.offsets[1];
  assign io_out_s1_full_pred_3_fallThroughAddr = s1_pred.fall_through_addr;
  assign io_out_s1_full_pred_3_fallThroughErr = s1_pred.fall_through_err;
  assign io_out_s1_full_pred_3_is_jal = s1_pred.is_jal;
  assign io_out_s1_full_pred_3_is_jalr = s1_pred.is_jalr;
  assign io_out_s1_full_pred_3_is_call = s1_pred.is_call;
  assign io_out_s1_full_pred_3_is_ret = s1_pred.is_ret;
  assign io_out_s1_full_pred_3_last_may_be_rvi_call = s1_pred.last_may_be_rvi_call;
  assign io_out_s1_full_pred_3_is_br_sharing = s1_pred.is_br_sharing;
  assign io_out_s1_full_pred_3_hit = s1_hit_out;
  assign io_fauftb_entry_out_isCall = s1_entry_out.isCall;
  assign io_fauftb_entry_out_isRet = s1_entry_out.isRet;
  assign io_fauftb_entry_out_isJalr = s1_entry_out.isJalr;
  assign io_fauftb_entry_out_valid = s1_entry_out.valid;
  assign io_fauftb_entry_out_brSlots_0_offset = s1_entry_out.brSlot.offset;
  assign io_fauftb_entry_out_brSlots_0_sharing = s1_entry_out.brSlot.sharing;
  assign io_fauftb_entry_out_brSlots_0_valid = s1_entry_out.brSlot.valid;
  assign io_fauftb_entry_out_brSlots_0_lower = s1_entry_out.brSlot.lower;
  assign io_fauftb_entry_out_brSlots_0_tarStat = s1_entry_out.brSlot.tarStat;
  assign io_fauftb_entry_out_tailSlot_offset = s1_entry_out.tailSlot.offset;
  assign io_fauftb_entry_out_tailSlot_sharing = s1_entry_out.tailSlot.sharing;
  assign io_fauftb_entry_out_tailSlot_valid = s1_entry_out.tailSlot.valid;
  assign io_fauftb_entry_out_tailSlot_lower = s1_entry_out.tailSlot.lower;
  assign io_fauftb_entry_out_tailSlot_tarStat = s1_entry_out.tailSlot.tarStat;
  assign io_fauftb_entry_out_pftAddr = s1_entry_out.pftAddr;
  assign io_fauftb_entry_out_carry = s1_entry_out.carry;
  assign io_fauftb_entry_out_last_may_be_rvi_call = s1_entry_out.last_may_be_rvi_call;
  assign io_fauftb_entry_out_strong_bias_0 = s1_entry_out.strong_bias[0];
  assign io_fauftb_entry_out_strong_bias_1 = s1_entry_out.strong_bias[1];
  assign io_fauftb_entry_hit_out = s1_hit_out;
  assign io_perf_0_value = {5'h0, perf_commit_hit};
  assign io_perf_1_value = {5'h0, perf_commit_miss};

endmodule
