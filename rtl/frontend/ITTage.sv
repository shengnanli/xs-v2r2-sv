// =============================================================================
// ITTage.sv —— ITTAGE：间接跳转目标预测器（BPU 链 4/5，S3 改写 jalr_target）
//
// 【在 BPU 里的位置】Composer 菊花链中 FTB 之后、RAS 之前。它只对一种指令下结论：
//   间接跳转（jalr，非 ret）的目标地址。S1 发查表，S2 拿到 5 张 ITTageTable 的结果选出
//   provider / altProvider，算出目标；S3 把目标写进各份 dup 预测的 jalr_target 送出。
//   其余预测字段原样透传（io_in.resp_in -> io_out）。
//   （Chisel：src/main/scala/xiangshan/frontend/ITTAGE.scala class ITTage）
//
// 【表与区域压缩】5 张 ITTageTable（已签核子模块）历史长度递增，命中项存
//   {2 位置信计数 ctr, 1 位 useful u, 目标低 20 位 offset, 4 位区域指针 pointer, usePCRegion}。
//   目标高 30 位（region）不存在表里，存在 16 项共享的 RegionWays（本 lane 已签）里；
//   usePCRegion=1 表示"高位就用当前 PC 的高位"。
//
// 【S2 选择】5 张表里**历史最长的命中**做 provider，次长的命中做 altProvider
//   （utility.ParallelSelectTwo，按 tables.reverse 两两归并）。provider 计数器为 0
//   （不自信）且有 alt 时用 alt 的目标；都没命中时用 FTB 给的 jalr_target（base）。
//   ★都不命中 / 只命中一个时，first / second 取第 0 张表的那份数据（归并树的结果，照搬）★。
//
// 【分配候选（S2）】"没命中且 u=0" 且历史比 provider 长的表可分配；用 15 位 LFSR 的
//   低 5 位随机掩一下，掩后有候选就取掩后最低的，否则取未掩最低的。结果随 meta 走。
//
// 【更新（提交时）】update 先整体锁存一拍（u_* / updateMeta_*），然后：
//   · 只有真正的间接跳转（is_jalr && !is_ret、tailSlot 有效且非共享、跳了、cfi 位置 = tailSlot）才更新；
//   · provider 有效：更新 provider（ctr、u、目标）；若当初用的是 alt（provider ctr=0）且预测错，也更新 alt；
//   · 预测错且不是"provider 对但不自信"：tick 饱和计数（没分配 +1，分配 -1），有分配候选就在那张表分配；
//     tick 计满 255 时清零并让所有表 reset_u。
//   · 新目标的高位若不同于 PC 高位且发生分配，写进 RegionWays（指针随表项走）。
//   每张表的 update 口再打一拍（RegEnable(updateMask(i))）送出。
//   ★Chisel 里赋 DontCare 的字段（分配项的 correct/oldCtr、alt 项的 u 等）按 firtool 实际取值照抄★。
//
// 【meta（182 位，放在 last_stage_meta 低位）】provider/alt 的有效与表号、altDiffers、providerU、
//   两个 ctr、allocate、两个目标、pred_cycle（64 位自由计数器 GTimer，异步复位）。
//
// 复位域：tickCtr、u_valid、pred_cycle、每张表 update 口的 valid/reset_u/uValid 寄存器、
//   公共外壳的 modified_reset 与 s2/s3 段寄存器异步复位；其余无复位，照 golden。
//
// 本文件：package ittage_pkg + 可读核 xs_ITTage_core + golden 同名 wrapper ITTage。
// wrapper 的端口表、子模块（tables_0..4 / rTable / s2_allocLFSR_prng，实例名同 golden）与
// 透传赋值是机械派生区，由 scripts/gen_bpu_wrappers.py 从 G1 golden 生成（GENERATED 区）。
// =============================================================================
// 本文件导航（共 1623 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L19    在 BPU 里的位置】Composer 菊花链中 FTB 之后、RAS 之前
//   L25    表与区域压缩】5 张 ITTageTable
//   L30    S2 选择】5 张表里**历史最长的命中**做 provider，次长的命中做 altProvider
//   L35    分配候选
//   L38    更新
//   L47    meta
//   L193   §0 BPU 公共外壳：各级 PC
//   L216   §1 S1：只在"可能是间接跳转"时查表
//   L229   §2 S2：选 provider / altProvider，拼目标，算分配候选
//   L306   §3 S3：打拍出目标与 meta
//   L356   §4 更新：锁存一拍
//   L414   §5 更新：决定每张表更新什么
//   L464   §6 每张表的 update 口：再打一拍送出
//
package ittage_pkg;

  localparam int unsigned NUM_TABLES  = 5;     // ITTageNTables
  localparam int unsigned TBL_IDX_W   = 3;
  localparam int unsigned NUM_DUP     = 4;
  localparam int unsigned PC_W        = 50;
  localparam int unsigned OFFSET_W    = 20;    // TargetOffsetBits
  localparam int unsigned REGION_W    = 30;    // VAddrBits - TargetOffsetBits
  localparam int unsigned PTR_W       = 4;     // log2(RegionNums)
  localparam int unsigned META_W      = 516;
  localparam int unsigned IT_META_W   = 182;

  // ITTageOffset：目标低位 + 区域指针 + "高位用 PC 的"
  typedef struct packed {
    logic [OFFSET_W-1:0] offset;
    logic [PTR_W-1:0]    pointer;
    logic                usePCRegion;
  } ittage_offset_t;

  // 一张表的 update 口（ITTageUpdate，按 golden 实际存在的字段）
  typedef struct packed {
    logic [PC_W-1:0]  pc;
    logic [255:0]     ghist;
    logic             valid;
    logic             correct;
    logic             alloc;
    logic [1:0]       old_ctr;
    logic             u_valid;
    logic             u;
    logic             reset_u;
    ittage_offset_t   target_offset;
    ittage_offset_t   old_target_offset;
  } ittage_upd_t;

  // ITTageMeta（asUInt 布局：先声明的字段在高位）
  typedef struct packed {
    logic                 provider_valid;
    logic [TBL_IDX_W-1:0] provider;
    logic                 alt_provider_valid;
    logic [TBL_IDX_W-1:0] alt_provider;
    logic                 alt_differs;
    logic                 provider_u;
    logic [1:0]           provider_ctr;
    logic [1:0]           alt_provider_ctr;
    logic                 allocate_valid;
    logic [TBL_IDX_W-1:0] allocate;
    logic [PC_W-1:0]      provider_target;
    logic [PC_W-1:0]      alt_provider_target;
    logic [63:0]          pred_cycle;
  } ittage_meta_t;

  // 8 位无符号饱和计数器 ±1（satUpdate(ctr, 8, up)）
  function automatic logic [7:0] sat8_update(input logic [7:0] old, input logic up);
    if (old == 8'hFF && up)        return 8'hFF;
    else if (old == 8'h00 && !up)  return 8'h00;
    else if (up)                   return old + 8'd1;
    else                           return old - 8'd1;
  endfunction

  // PriorityEncoder(x)，x 全 0 时为 7（golden 的实际取值）
  function automatic logic [TBL_IDX_W-1:0] prio_enc_or7(input logic [NUM_TABLES-1:0] x);
    for (int i = 0; i < NUM_TABLES; i++)
      if (x[i]) return TBL_IDX_W'(i);
    return 3'd7;
  endfunction

  // LowerMask(UIntToOH(idx), 5)：idx 及以下各位（按 8 位独热右移再或，取低 5 位）
  function automatic logic [NUM_TABLES-1:0] lower_mask_of(input logic [TBL_IDX_W-1:0] idx);
    logic [7:0] oh;
    logic [7:0] acc;
    oh  = 8'd1 << idx;
    acc = '0;
    for (int i = 0; i < NUM_TABLES; i++) acc |= oh >> i;
    return acc[NUM_TABLES-1:0];
  endfunction

endpackage

module xs_ITTage_core
  import ittage_pkg::*;
(
  input  logic                 clock,
  input  logic                 reset,
  input  logic [47:0]          reset_vector,
  input  logic [PC_W-1:0]      s0_pc    [NUM_DUP],
  input  logic                 s0_fire  [NUM_DUP],
  input  logic                 s1_fire  [NUM_DUP],
  input  logic                 s2_fire  [NUM_DUP],
  // ---- 上游（菊花链 resp_in[0]）给的提示 ----
  input  logic                 s1_uftb_hit,
  input  logic                 s1_uftb_has_indirect,
  input  logic                 s1_ftb_close_req,
  input  logic [PC_W-1:0]      base_target,        // FTB 在 S2 给的 jalr_target（dup 3）
  // ---- 5 张 ITTageTable ----
  output logic                 tbl_req_valid,
  output logic [PC_W-1:0]      tbl_req_pc,
  input  logic                 tbl_req_ready [NUM_TABLES],
  input  logic                 tbl_resp_valid[NUM_TABLES],
  input  logic [1:0]           tbl_resp_ctr  [NUM_TABLES],
  input  logic                 tbl_resp_u    [NUM_TABLES],
  input  ittage_offset_t       tbl_resp_off  [NUM_TABLES],
  output ittage_upd_t          tbl_upd       [NUM_TABLES],
  // ---- RegionWays ----
  input  logic                 rt_resp_hit     [NUM_TABLES],
  input  logic [REGION_W-1:0]  rt_resp_region  [NUM_TABLES],
  output logic [REGION_W-1:0]  rt_update_region[2],
  input  logic                 rt_update_hit   [2],
  input  logic [PTR_W-1:0]     rt_update_pointer[2],
  output logic                 rt_write_valid,
  output logic [REGION_W-1:0]  rt_write_region,
  input  logic [PTR_W-1:0]     rt_write_pointer,
  // ---- 分配随机源（MaxPeriodFibonacciLFSR 低 5 位）----
  input  logic [NUM_TABLES-1:0] lfsr_bits,
  // ---- 更新 ----
  input  logic                 update_valid,
  input  logic [PC_W-1:0]      update_pc,
  input  logic                 update_is_ret_raw,      // ftb_entry.isRet
  input  logic                 update_is_jalr_raw,     // ftb_entry.isJalr
  input  logic [3:0]           update_tail_offset,
  input  logic                 update_tail_sharing,
  input  logic                 update_tail_valid,
  input  logic                 update_strong_bias_1,
  input  logic                 update_cfi_valid,
  input  logic [3:0]           update_cfi_idx,
  input  logic                 update_jmp_taken,
  input  logic                 update_jmp_mispred,     // mispred_mask(numBr)：跳转那一位
  input  logic [META_W-1:0]    update_meta,
  input  logic [PC_W-1:0]      update_full_target,
  input  logic [255:0]         update_ghist,
  // ---- 输出 ----
  output logic [PC_W-1:0]      s3_target [NUM_DUP],
  output logic [META_W-1:0]    last_stage_meta,
  output logic                 s1_ready
);

  // ===========================================================================
  // §0 BPU 公共外壳：各级 PC（S2 用 dup 0 的 PC 高位补目标 region）
  // ===========================================================================
  logic [PC_W-1:0] s1_pc [NUM_DUP];
  logic [PC_W-1:0] s2_pc [NUM_DUP];
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
    .s2_pc        (s2_pc),
    .s3_pc        (s3_pc_unused)
  );

  // ===========================================================================
  // §1 S1：只在"可能是间接跳转"时查表（uFTB 没命中且 FTB 没关请求，或 uFTB 说有间接跳转）
  // ===========================================================================
  logic s1_is_indirect;
  assign s1_is_indirect = (!s1_uftb_hit && !s1_ftb_close_req) || s1_uftb_has_indirect;
  assign tbl_req_valid  = s1_fire[3] && s1_is_indirect;
  assign tbl_req_pc     = s1_pc[3];

  always_comb begin
    s1_ready = 1'b1;
    for (int i = 0; i < NUM_TABLES; i++) s1_ready &= tbl_req_ready[i];
  end

  // ===========================================================================
  // §2 S2：选 provider / altProvider，拼目标，算分配候选
  // ===========================================================================
  logic                 s2_provided, s2_alt_provided;
  logic [TBL_IDX_W-1:0] s2_provider, s2_alt_provider;
  logic [PC_W-1:0]      region_target [NUM_TABLES];
  logic [PC_W-1:0]      s2_provider_target, s2_alt_provider_target, s2_target;
  logic                 provider_null;

  // provider = 历史最长的命中表，alt = 次长的命中表；不足时取第 0 张（见文件头）
  always_comb begin
    int unsigned n_hit;
    s2_provider     = '0;
    s2_alt_provider = '0;
    n_hit           = 0;
    for (int i = NUM_TABLES - 1; i >= 0; i--) begin
      if (tbl_resp_valid[i]) begin
        if (n_hit == 0)      s2_provider     = TBL_IDX_W'(i);
        else if (n_hit == 1) s2_alt_provider = TBL_IDX_W'(i);
        n_hit++;
      end
    end
    s2_provided     = (n_hit >= 1);
    s2_alt_provided = (n_hit >= 2);
  end

  // 每张表的完整目标：区域命中且不用 PC 区域 -> RegionWays 的 region，否则 S2 PC 的高 30 位
  for (genvar i = 0; i < NUM_TABLES; i++) begin : g_region_target
    assign region_target[i] = {(rt_resp_hit[i] && !tbl_resp_off[i].usePCRegion) ? rt_resp_region[i]
                                                                                : s2_pc[0][PC_W-1:OFFSET_W],
                               tbl_resp_off[i].offset};
  end

  // 按表号取 provider / alt 的那一份（逐表比较选通：表号 3 位、表只有 5 张，
  // 不用变量下标直接索引 5 项数组，免得出现越界读）
  logic       s2_provider_u;
  logic [1:0] s2_provider_ctr, s2_alt_provider_ctr;
  always_comb begin
    s2_provider_target     = '0;
    s2_alt_provider_target = '0;
    s2_provider_u          = 1'b0;
    s2_provider_ctr        = '0;
    s2_alt_provider_ctr    = '0;
    for (int i = 0; i < NUM_TABLES; i++) begin
      if (s2_provider == TBL_IDX_W'(i)) begin
        s2_provider_target = region_target[i];
        s2_provider_u      = tbl_resp_u[i];
        s2_provider_ctr    = tbl_resp_ctr[i];
      end
      if (s2_alt_provider == TBL_IDX_W'(i)) begin
        s2_alt_provider_target = region_target[i];
        s2_alt_provider_ctr    = tbl_resp_ctr[i];
      end
    end
  end
  assign provider_null = (s2_provider_ctr == 2'd0);
  assign s2_target = !s2_provided                      ? base_target
                   : (provider_null && s2_alt_provided) ? s2_alt_provider_target
                   :                                      s2_provider_target;

  // 分配候选：没命中且 u=0，且历史比 provider 长（provider 及以下的表排除）
  logic [NUM_TABLES-1:0] s2_allocatable;
  logic [NUM_TABLES-1:0] s2_masked;
  logic [TBL_IDX_W-1:0]  s2_first_entry, s2_masked_entry, s2_alloc_entry;
  logic [7:0]            masked_hit_vec;

  always_comb begin
    for (int i = 0; i < NUM_TABLES; i++)
      s2_allocatable[i] = !tbl_resp_valid[i] && !tbl_resp_u[i];
    s2_allocatable &= ~(lower_mask_of(s2_provider) & {NUM_TABLES{s2_provided}});
  end
  assign s2_masked       = s2_allocatable & lfsr_bits;
  assign s2_first_entry  = prio_enc_or7(s2_allocatable);
  assign s2_masked_entry = prio_enc_or7(s2_masked);
  assign masked_hit_vec  = {3'b0, s2_allocatable} >> s2_masked_entry;
  assign s2_alloc_entry  = masked_hit_vec[0] ? s2_masked_entry : s2_first_entry;

  // ===========================================================================
  // §3 S3：打拍出目标与 meta
  // ===========================================================================
  logic                 s3_provided, s3_alt_provided;
  logic [TBL_IDX_W-1:0] s3_provider, s3_alt_provider;
  logic                 s3_provider_u;
  logic [1:0]           s3_provider_ctr, s3_alt_provider_ctr;
  logic [PC_W-1:0]      s3_provider_target, s3_alt_provider_target;
  logic                 s3_alloc_valid;
  logic [TBL_IDX_W-1:0] s3_alloc_entry;
  logic [63:0]          pred_cycle;          // GTimer()：自由计数，异步复位

  for (genvar d = 0; d < NUM_DUP; d++) begin : g_s3_target
    always_ff @(posedge clock) if (s2_fire[d]) s3_target[d] <= s2_target;
  end

  always_ff @(posedge clock) begin
    if (s2_fire[3]) begin
      s3_provider_target     <= s2_provider_target;
      s3_alt_provider_target <= s2_alt_provider_target;
      s3_provided            <= s2_provided;
      s3_provider            <= s2_provider;
      s3_alt_provided        <= s2_alt_provided;
      s3_alt_provider        <= s2_alt_provider;
      s3_provider_u          <= s2_provider_u;
      s3_provider_ctr        <= s2_provider_ctr;
      s3_alt_provider_ctr    <= s2_alt_provider_ctr;
      s3_alloc_valid         <= |s2_allocatable;
      s3_alloc_entry         <= s2_alloc_entry;
    end
  end

  ittage_meta_t resp_meta;
  always_comb begin
    resp_meta.provider_valid      = s3_provided;
    resp_meta.provider            = s3_provider;
    resp_meta.alt_provider_valid  = s3_alt_provided;
    resp_meta.alt_provider        = s3_alt_provider;
    resp_meta.alt_differs         = (s3_provider_target != s3_alt_provider_target);
    resp_meta.provider_u          = s3_provider_u;
    resp_meta.provider_ctr        = s3_provider_ctr;
    resp_meta.alt_provider_ctr    = s3_alt_provider_ctr;
    resp_meta.allocate_valid      = s3_alloc_valid;
    resp_meta.allocate            = s3_alloc_entry;
    resp_meta.provider_target     = s3_provider_target;
    resp_meta.alt_provider_target = s3_alt_provider_target;
    resp_meta.pred_cycle          = pred_cycle;
  end
  assign last_stage_meta = {{(META_W - IT_META_W){1'b0}}, resp_meta};

  // ===========================================================================
  // §4 更新：锁存一拍（u_* / updateMeta_*，各字段按 golden 的使能分别锁存）
  // ===========================================================================
  ittage_meta_t in_meta;
  assign in_meta = update_meta[IT_META_W-1:0];

  logic             u_valid;
  logic [PC_W-1:0]  u_pc;
  logic             u_is_ret_raw, u_is_jalr_raw;
  logic [3:0]       u_tail_offset;
  logic             u_tail_sharing, u_tail_valid, u_strong_bias_1;
  logic             u_cfi_valid, u_jmp_taken, u_jmp_mispred;
  logic [3:0]       u_cfi_idx;
  logic [PC_W-1:0]  u_full_target;
  logic [255:0]     u_ghist;
  // updateMeta：大部分字段随 update.valid 锁存；表号/目标只在对应 valid 时锁存（省翻转）
  logic                 um_provider_valid, um_alt_provider_valid, um_alt_differs, um_provider_u;
  logic [1:0]           um_provider_ctr, um_alt_provider_ctr;
  logic                 um_allocate_valid;
  logic [TBL_IDX_W-1:0] um_provider, um_alt_provider, um_allocate;
  logic [PC_W-1:0]      um_provider_target, um_alt_provider_target;

  always_ff @(posedge clock) begin
    if (update_valid) begin
      u_pc                  <= update_pc;
      u_is_ret_raw          <= update_is_ret_raw;
      u_is_jalr_raw         <= update_is_jalr_raw;
      u_tail_offset         <= update_tail_offset;
      u_tail_sharing        <= update_tail_sharing;
      u_tail_valid          <= update_tail_valid;
      u_strong_bias_1       <= update_strong_bias_1;
      u_cfi_valid           <= update_cfi_valid;
      u_jmp_taken           <= update_jmp_taken;
      u_jmp_mispred         <= update_jmp_mispred;
      um_provider_valid     <= in_meta.provider_valid;
      um_alt_provider_valid <= in_meta.alt_provider_valid;
      um_alt_differs        <= in_meta.alt_differs;
      um_provider_u         <= in_meta.provider_u;
      um_provider_ctr       <= in_meta.provider_ctr;
      um_alt_provider_ctr   <= in_meta.alt_provider_ctr;
      um_allocate_valid     <= in_meta.allocate_valid;
      u_full_target         <= update_full_target;
      u_ghist               <= update_ghist;
    end
    if (update_valid && in_meta.provider_valid) begin
      um_provider        <= in_meta.provider;
      um_provider_target <= in_meta.provider_target;
    end
    if (update_valid && in_meta.allocate_valid)
      um_allocate <= in_meta.allocate;
    if (update_valid && in_meta.alt_provider_valid)
      um_alt_provider <= in_meta.alt_provider;
    if (update_valid && in_meta.provider_valid && in_meta.alt_provider_valid && in_meta.provider_ctr == 2'd0)
      um_alt_provider_target <= in_meta.alt_provider_target;
    if (update_valid && update_cfi_valid)
      u_cfi_idx <= update_cfi_idx;
  end

  // ===========================================================================
  // §5 更新：决定每张表更新什么
  // ===========================================================================
  logic update_real;                // 是一次真正的间接跳转提交
  logic used_altpred_mispred;       // 当初用的是 alt（provider ctr=0）且预测错
  logic provider_update;            // 更新 provider
  logic do_alloc_path;              // 预测错且不是"provider 对但不自信"
  logic provider_correct;           // provider 目标 == 实际目标
  logic [7:0] tick_ctr;
  logic       reset_u_all;
  logic [NUM_TABLES-1:0] tbl_is_provider, tbl_is_alt, tbl_alloc, update_mask;
  logic       real_use_pc_region;   // 实际目标高位 == PC 高位
  logic       any_alloc;
  logic       update_u_value;

  assign update_real = u_tail_valid && u_is_jalr_raw && !(u_tail_valid && u_is_ret_raw) && u_valid
                       && !u_tail_sharing && u_jmp_taken && u_cfi_valid
                       && (u_cfi_idx == u_tail_offset) && !u_strong_bias_1;
  assign provider_correct     = (um_provider_target == u_full_target);
  assign used_altpred_mispred = um_alt_provider_valid && (um_provider_ctr == 2'd0) && u_jmp_mispred;
  assign provider_update      = update_real && um_provider_valid;
  assign do_alloc_path        = update_real && u_jmp_mispred
                                && !(um_provider_valid && provider_correct && (um_provider_ctr == 2'd0));
  assign reset_u_all          = &tick_ctr;
  // updateU(provider)：alt 与 provider 目标不同时看 provider 对不对，否则保持 providerU
  assign update_u_value       = um_alt_differs ? provider_correct : um_provider_u;

  for (genvar i = 0; i < NUM_TABLES; i++) begin : g_update_mask
    assign tbl_is_provider[i] = (um_provider == TBL_IDX_W'(i));
    assign tbl_is_alt[i]      = (um_alt_provider == TBL_IDX_W'(i));
    assign tbl_alloc[i]       = do_alloc_path && um_allocate_valid && (um_allocate == TBL_IDX_W'(i));
    assign update_mask[i]     = tbl_alloc[i]
                              || (provider_update && (tbl_is_provider[i] || (used_altpred_mispred && tbl_is_alt[i])));
  end
  assign any_alloc = |tbl_alloc;

  // tick：分配路径上每次 +1（没分配）/-1（分配了）；计满 255 清零并 reset_u
  always_ff @(posedge clock or posedge reset) begin
    if (reset)              tick_ctr <= '0;
    else if (reset_u_all)   tick_ctr <= '0;
    else if (do_alloc_path) tick_ctr <= sat8_update(tick_ctr, !um_allocate_valid);
  end

  // RegionWays：分配且新目标高位不同于 PC 高位时写入 region；更新口查 provider / alt 旧目标的 region
  assign real_use_pc_region  = (u_full_target[PC_W-1:OFFSET_W] == u_pc[PC_W-1:OFFSET_W]);
  assign rt_write_valid      = !real_use_pc_region && any_alloc;
  assign rt_write_region     = u_full_target[PC_W-1:OFFSET_W];
  assign rt_update_region[0] = um_provider_target[PC_W-1:OFFSET_W];
  assign rt_update_region[1] = um_alt_provider_target[PC_W-1:OFFSET_W];

  // ===========================================================================
  // §6 每张表的 update 口：再打一拍送出
  // ===========================================================================
  ittage_offset_t real_target_off;     // 新目标：低 20 位 + 写指针 + usePCRegion
  ittage_offset_t provider_old_off, alt_old_off;

  assign real_target_off.offset      = u_full_target[OFFSET_W-1:0];
  assign real_target_off.pointer     = rt_write_pointer;
  assign real_target_off.usePCRegion = real_use_pc_region || !any_alloc;
  assign provider_old_off.offset      = um_provider_target[OFFSET_W-1:0];
  assign provider_old_off.pointer     = rt_update_pointer[0];
  assign provider_old_off.usePCRegion = !rt_update_hit[0];
  assign alt_old_off.offset           = um_alt_provider_target[OFFSET_W-1:0];
  assign alt_old_off.pointer          = rt_update_pointer[1];
  assign alt_old_off.usePCRegion      = !rt_update_hit[1];

  logic [63:0] pred_cycle_next;
  assign pred_cycle_next = pred_cycle + 64'd1;

  // 每张表 update 口的寄存器：逐字段一个数组（FM 钉点按字段逐位对到 golden 的 tables_<i>_io_update_*）
  logic                 upd_valid_q   [NUM_TABLES];   // RegNext(updateMask(i))，异步复位
  logic                 upd_reset_u_q [NUM_TABLES];   // RegNext(updateResetU)，异步复位
  logic                 upd_u_valid_q [NUM_TABLES];   // RegEnable(updateUMask(i), false, updateMask(i))
  logic                 upd_correct_q [NUM_TABLES];
  logic                 upd_alloc_q   [NUM_TABLES];
  logic [1:0]           upd_old_ctr_q [NUM_TABLES];
  ittage_offset_t       upd_tgt_off_q [NUM_TABLES];
  ittage_offset_t       upd_old_off_q [NUM_TABLES];
  logic                 upd_u_q       [NUM_TABLES];
  logic [PC_W-1:0]      upd_pc_q      [NUM_TABLES];
  logic [255:0]         upd_ghist_q   [NUM_TABLES];

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      u_valid    <= 1'b0;
      pred_cycle <= '0;
      for (int i = 0; i < NUM_TABLES; i++) begin
        upd_valid_q[i]   <= 1'b0;
        upd_reset_u_q[i] <= 1'b0;
        upd_u_valid_q[i] <= 1'b0;
      end
    end else begin
      u_valid    <= update_valid;
      pred_cycle <= pred_cycle_next;
      for (int i = 0; i < NUM_TABLES; i++) begin
        upd_valid_q[i]   <= update_mask[i];
        upd_reset_u_q[i] <= reset_u_all;
        // uValid：分配项与 provider 置 1；只因"用了 alt"而更新的 alt 项为 0
        if (update_mask[i]) upd_u_valid_q[i] <= tbl_alloc[i] || (provider_update && tbl_is_provider[i]);
      end
    end
  end

  // 无复位字段：RegEnable(..., updateMask(i))。分配项的 correct / oldCtr 与 alt 项的 u 在 Chisel
  // 里是 DontCare，下面按 golden（firtool）的实际取值照抄：
  //   correct = (本表是 provider) && provider 目标正确
  //   old_ctr = 本表是 provider ? providerCtr : altProviderCtr
  //   u       = !分配 && updateU(provider)
  always_ff @(posedge clock) begin
    for (int i = 0; i < NUM_TABLES; i++) begin
      if (update_mask[i]) begin
        upd_correct_q[i] <= tbl_is_provider[i] && provider_correct;
        upd_alloc_q[i]   <= tbl_alloc[i];
        upd_old_ctr_q[i] <= tbl_is_provider[i] ? um_provider_ctr : um_alt_provider_ctr;
        upd_tgt_off_q[i] <= real_target_off;
        upd_old_off_q[i] <= tbl_is_provider[i] ? provider_old_off : alt_old_off;
        upd_u_q[i]       <= !tbl_alloc[i] && update_u_value;
        upd_pc_q[i]      <= update_pc;     // ★直接取 io.update.bits.pc（未锁存那份），照 golden★
        upd_ghist_q[i]   <= u_ghist;
      end
    end
  end

  always_comb begin
    for (int i = 0; i < NUM_TABLES; i++) begin
      tbl_upd[i].pc                = upd_pc_q[i];
      tbl_upd[i].ghist             = upd_ghist_q[i];
      tbl_upd[i].valid             = upd_valid_q[i];
      tbl_upd[i].correct           = upd_correct_q[i];
      tbl_upd[i].alloc             = upd_alloc_q[i];
      tbl_upd[i].old_ctr           = upd_old_ctr_q[i];
      tbl_upd[i].u_valid           = upd_u_valid_q[i];
      tbl_upd[i].u                 = upd_u_q[i];
      tbl_upd[i].reset_u           = upd_reset_u_q[i];
      tbl_upd[i].target_offset     = upd_tgt_off_q[i];
      tbl_upd[i].old_target_offset = upd_old_off_q[i];
    end
  end

endmodule

// BEGIN GENERATED(bpu-wrapper) —— scripts/gen_bpu_wrappers.py 生成，勿手改
module ITTage
  import ittage_pkg::*;
(
  input  clock,
  input  reset,
  input  [47:0] io_reset_vector,
  input  [49:0] io_in_bits_s0_pc_0,
  input  [49:0] io_in_bits_s0_pc_1,
  input  [49:0] io_in_bits_s0_pc_2,
  input  [49:0] io_in_bits_s0_pc_3,
  input  [7:0] io_in_bits_s1_folded_hist_3_hist_14_folded_hist,
  input  [8:0] io_in_bits_s1_folded_hist_3_hist_13_folded_hist,
  input  [3:0] io_in_bits_s1_folded_hist_3_hist_12_folded_hist,
  input  [8:0] io_in_bits_s1_folded_hist_3_hist_10_folded_hist,
  input  [8:0] io_in_bits_s1_folded_hist_3_hist_6_folded_hist,
  input  [7:0] io_in_bits_s1_folded_hist_3_hist_4_folded_hist,
  input  [7:0] io_in_bits_s1_folded_hist_3_hist_3_folded_hist,
  input  [7:0] io_in_bits_s1_folded_hist_3_hist_2_folded_hist,
  input  io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0,
  input  io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1,
  input  io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_0,
  input  io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_1,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_0_targets_0,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_0_targets_1,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_0_jalr_target,
  input  [3:0] io_in_bits_resp_in_0_s2_full_pred_0_offsets_0,
  input  [3:0] io_in_bits_resp_in_0_s2_full_pred_0_offsets_1,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_0_fallThroughAddr,
  input  io_in_bits_resp_in_0_s2_full_pred_0_fallThroughErr,
  input  io_in_bits_resp_in_0_s2_full_pred_0_is_jal,
  input  io_in_bits_resp_in_0_s2_full_pred_0_is_jalr,
  input  io_in_bits_resp_in_0_s2_full_pred_0_is_call,
  input  io_in_bits_resp_in_0_s2_full_pred_0_is_ret,
  input  io_in_bits_resp_in_0_s2_full_pred_0_last_may_be_rvi_call,
  input  io_in_bits_resp_in_0_s2_full_pred_0_is_br_sharing,
  input  io_in_bits_resp_in_0_s2_full_pred_0_hit,
  input  io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0,
  input  io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1,
  input  io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_0,
  input  io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_1,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_1_targets_0,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_1_targets_1,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_1_jalr_target,
  input  [3:0] io_in_bits_resp_in_0_s2_full_pred_1_offsets_0,
  input  [3:0] io_in_bits_resp_in_0_s2_full_pred_1_offsets_1,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_1_fallThroughAddr,
  input  io_in_bits_resp_in_0_s2_full_pred_1_fallThroughErr,
  input  io_in_bits_resp_in_0_s2_full_pred_1_is_jal,
  input  io_in_bits_resp_in_0_s2_full_pred_1_is_jalr,
  input  io_in_bits_resp_in_0_s2_full_pred_1_is_call,
  input  io_in_bits_resp_in_0_s2_full_pred_1_is_ret,
  input  io_in_bits_resp_in_0_s2_full_pred_1_last_may_be_rvi_call,
  input  io_in_bits_resp_in_0_s2_full_pred_1_is_br_sharing,
  input  io_in_bits_resp_in_0_s2_full_pred_1_hit,
  input  io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0,
  input  io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1,
  input  io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_0,
  input  io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_1,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_2_targets_0,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_2_targets_1,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_2_jalr_target,
  input  [3:0] io_in_bits_resp_in_0_s2_full_pred_2_offsets_0,
  input  [3:0] io_in_bits_resp_in_0_s2_full_pred_2_offsets_1,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_2_fallThroughAddr,
  input  io_in_bits_resp_in_0_s2_full_pred_2_fallThroughErr,
  input  io_in_bits_resp_in_0_s2_full_pred_2_is_jal,
  input  io_in_bits_resp_in_0_s2_full_pred_2_is_jalr,
  input  io_in_bits_resp_in_0_s2_full_pred_2_is_call,
  input  io_in_bits_resp_in_0_s2_full_pred_2_is_ret,
  input  io_in_bits_resp_in_0_s2_full_pred_2_last_may_be_rvi_call,
  input  io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing,
  input  io_in_bits_resp_in_0_s2_full_pred_2_hit,
  input  io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0,
  input  io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1,
  input  io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_0,
  input  io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_1,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_3_targets_0,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_3_targets_1,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_3_jalr_target,
  input  [3:0] io_in_bits_resp_in_0_s2_full_pred_3_offsets_0,
  input  [3:0] io_in_bits_resp_in_0_s2_full_pred_3_offsets_1,
  input  [49:0] io_in_bits_resp_in_0_s2_full_pred_3_fallThroughAddr,
  input  io_in_bits_resp_in_0_s2_full_pred_3_fallThroughErr,
  input  io_in_bits_resp_in_0_s2_full_pred_3_is_jal,
  input  io_in_bits_resp_in_0_s2_full_pred_3_is_jalr,
  input  io_in_bits_resp_in_0_s2_full_pred_3_is_call,
  input  io_in_bits_resp_in_0_s2_full_pred_3_is_ret,
  input  io_in_bits_resp_in_0_s2_full_pred_3_last_may_be_rvi_call,
  input  io_in_bits_resp_in_0_s2_full_pred_3_is_br_sharing,
  input  io_in_bits_resp_in_0_s2_full_pred_3_hit,
  input  io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0,
  input  io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1,
  input  io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_0,
  input  io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_1,
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_0_targets_0,
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_0_targets_1,
  input  [3:0] io_in_bits_resp_in_0_s3_full_pred_0_offsets_0,
  input  [3:0] io_in_bits_resp_in_0_s3_full_pred_0_offsets_1,
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_0_fallThroughAddr,
  input  io_in_bits_resp_in_0_s3_full_pred_0_fallThroughErr,
  input  io_in_bits_resp_in_0_s3_full_pred_0_multiHit,
  input  io_in_bits_resp_in_0_s3_full_pred_0_is_jal,
  input  io_in_bits_resp_in_0_s3_full_pred_0_is_jalr,
  input  io_in_bits_resp_in_0_s3_full_pred_0_is_call,
  input  io_in_bits_resp_in_0_s3_full_pred_0_is_ret,
  input  io_in_bits_resp_in_0_s3_full_pred_0_last_may_be_rvi_call,
  input  io_in_bits_resp_in_0_s3_full_pred_0_is_br_sharing,
  input  io_in_bits_resp_in_0_s3_full_pred_0_hit,
  input  io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0,
  input  io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1,
  input  io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_0,
  input  io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_1,
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_1_targets_0,
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_1_targets_1,
  input  [3:0] io_in_bits_resp_in_0_s3_full_pred_1_offsets_0,
  input  [3:0] io_in_bits_resp_in_0_s3_full_pred_1_offsets_1,
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_1_fallThroughAddr,
  input  io_in_bits_resp_in_0_s3_full_pred_1_fallThroughErr,
  input  io_in_bits_resp_in_0_s3_full_pred_1_multiHit,
  input  io_in_bits_resp_in_0_s3_full_pred_1_is_jal,
  input  io_in_bits_resp_in_0_s3_full_pred_1_is_jalr,
  input  io_in_bits_resp_in_0_s3_full_pred_1_is_call,
  input  io_in_bits_resp_in_0_s3_full_pred_1_is_ret,
  input  io_in_bits_resp_in_0_s3_full_pred_1_last_may_be_rvi_call,
  input  io_in_bits_resp_in_0_s3_full_pred_1_is_br_sharing,
  input  io_in_bits_resp_in_0_s3_full_pred_1_hit,
  input  io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0,
  input  io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1,
  input  io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_0,
  input  io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_1,
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_2_targets_0,
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_2_targets_1,
  input  [3:0] io_in_bits_resp_in_0_s3_full_pred_2_offsets_0,
  input  [3:0] io_in_bits_resp_in_0_s3_full_pred_2_offsets_1,
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_2_fallThroughAddr,
  input  io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr,
  input  io_in_bits_resp_in_0_s3_full_pred_2_multiHit,
  input  io_in_bits_resp_in_0_s3_full_pred_2_is_jal,
  input  io_in_bits_resp_in_0_s3_full_pred_2_is_jalr,
  input  io_in_bits_resp_in_0_s3_full_pred_2_is_call,
  input  io_in_bits_resp_in_0_s3_full_pred_2_is_ret,
  input  io_in_bits_resp_in_0_s3_full_pred_2_last_may_be_rvi_call,
  input  io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing,
  input  io_in_bits_resp_in_0_s3_full_pred_2_hit,
  input  io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0,
  input  io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1,
  input  io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_0,
  input  io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_1,
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_3_targets_0,
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_3_targets_1,
  input  [3:0] io_in_bits_resp_in_0_s3_full_pred_3_offsets_0,
  input  [3:0] io_in_bits_resp_in_0_s3_full_pred_3_offsets_1,
  input  [49:0] io_in_bits_resp_in_0_s3_full_pred_3_fallThroughAddr,
  input  io_in_bits_resp_in_0_s3_full_pred_3_fallThroughErr,
  input  io_in_bits_resp_in_0_s3_full_pred_3_multiHit,
  input  io_in_bits_resp_in_0_s3_full_pred_3_is_jal,
  input  io_in_bits_resp_in_0_s3_full_pred_3_is_jalr,
  input  io_in_bits_resp_in_0_s3_full_pred_3_is_call,
  input  io_in_bits_resp_in_0_s3_full_pred_3_is_ret,
  input  io_in_bits_resp_in_0_s3_full_pred_3_last_may_be_rvi_call,
  input  io_in_bits_resp_in_0_s3_full_pred_3_is_br_sharing,
  input  io_in_bits_resp_in_0_s3_full_pred_3_hit,
  input  io_in_bits_resp_in_0_s1_uftbHit,
  input  io_in_bits_resp_in_0_s1_uftbHasIndirect,
  input  io_in_bits_resp_in_0_s1_ftbCloseReq,
  input  io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0,
  input  io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1,
  input  io_in_bits_resp_in_0_last_stage_ftb_entry_isCall,
  input  io_in_bits_resp_in_0_last_stage_ftb_entry_isRet,
  input  io_in_bits_resp_in_0_last_stage_ftb_entry_isJalr,
  input  io_in_bits_resp_in_0_last_stage_ftb_entry_valid,
  input  [3:0] io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_offset,
  input  io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_sharing,
  input  io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_valid,
  input  [11:0] io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_lower,
  input  [1:0] io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_tarStat,
  input  [3:0] io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_offset,
  input  io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_sharing,
  input  io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_valid,
  input  [19:0] io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_lower,
  input  [1:0] io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_tarStat,
  input  [3:0] io_in_bits_resp_in_0_last_stage_ftb_entry_pftAddr,
  input  io_in_bits_resp_in_0_last_stage_ftb_entry_carry,
  input  io_in_bits_resp_in_0_last_stage_ftb_entry_last_may_be_rvi_call,
  input  io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_0,
  input  io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_1,
  output io_out_s2_full_pred_0_br_taken_mask_0,
  output io_out_s2_full_pred_0_br_taken_mask_1,
  output io_out_s2_full_pred_0_slot_valids_0,
  output io_out_s2_full_pred_0_slot_valids_1,
  output [49:0] io_out_s2_full_pred_0_targets_0,
  output [49:0] io_out_s2_full_pred_0_targets_1,
  output [49:0] io_out_s2_full_pred_0_jalr_target,
  output [3:0] io_out_s2_full_pred_0_offsets_0,
  output [3:0] io_out_s2_full_pred_0_offsets_1,
  output [49:0] io_out_s2_full_pred_0_fallThroughAddr,
  output io_out_s2_full_pred_0_fallThroughErr,
  output io_out_s2_full_pred_0_is_jal,
  output io_out_s2_full_pred_0_is_jalr,
  output io_out_s2_full_pred_0_is_call,
  output io_out_s2_full_pred_0_is_ret,
  output io_out_s2_full_pred_0_last_may_be_rvi_call,
  output io_out_s2_full_pred_0_is_br_sharing,
  output io_out_s2_full_pred_0_hit,
  output io_out_s2_full_pred_1_br_taken_mask_0,
  output io_out_s2_full_pred_1_br_taken_mask_1,
  output io_out_s2_full_pred_1_slot_valids_0,
  output io_out_s2_full_pred_1_slot_valids_1,
  output [49:0] io_out_s2_full_pred_1_targets_0,
  output [49:0] io_out_s2_full_pred_1_targets_1,
  output [49:0] io_out_s2_full_pred_1_jalr_target,
  output [3:0] io_out_s2_full_pred_1_offsets_0,
  output [3:0] io_out_s2_full_pred_1_offsets_1,
  output [49:0] io_out_s2_full_pred_1_fallThroughAddr,
  output io_out_s2_full_pred_1_fallThroughErr,
  output io_out_s2_full_pred_1_is_jal,
  output io_out_s2_full_pred_1_is_jalr,
  output io_out_s2_full_pred_1_is_call,
  output io_out_s2_full_pred_1_is_ret,
  output io_out_s2_full_pred_1_last_may_be_rvi_call,
  output io_out_s2_full_pred_1_is_br_sharing,
  output io_out_s2_full_pred_1_hit,
  output io_out_s2_full_pred_2_br_taken_mask_0,
  output io_out_s2_full_pred_2_br_taken_mask_1,
  output io_out_s2_full_pred_2_slot_valids_0,
  output io_out_s2_full_pred_2_slot_valids_1,
  output [49:0] io_out_s2_full_pred_2_targets_0,
  output [49:0] io_out_s2_full_pred_2_targets_1,
  output [49:0] io_out_s2_full_pred_2_jalr_target,
  output [3:0] io_out_s2_full_pred_2_offsets_0,
  output [3:0] io_out_s2_full_pred_2_offsets_1,
  output [49:0] io_out_s2_full_pred_2_fallThroughAddr,
  output io_out_s2_full_pred_2_fallThroughErr,
  output io_out_s2_full_pred_2_is_jal,
  output io_out_s2_full_pred_2_is_jalr,
  output io_out_s2_full_pred_2_is_call,
  output io_out_s2_full_pred_2_is_ret,
  output io_out_s2_full_pred_2_last_may_be_rvi_call,
  output io_out_s2_full_pred_2_is_br_sharing,
  output io_out_s2_full_pred_2_hit,
  output io_out_s2_full_pred_3_br_taken_mask_0,
  output io_out_s2_full_pred_3_br_taken_mask_1,
  output io_out_s2_full_pred_3_slot_valids_0,
  output io_out_s2_full_pred_3_slot_valids_1,
  output [49:0] io_out_s2_full_pred_3_targets_0,
  output [49:0] io_out_s2_full_pred_3_targets_1,
  output [49:0] io_out_s2_full_pred_3_jalr_target,
  output [3:0] io_out_s2_full_pred_3_offsets_0,
  output [3:0] io_out_s2_full_pred_3_offsets_1,
  output [49:0] io_out_s2_full_pred_3_fallThroughAddr,
  output io_out_s2_full_pred_3_fallThroughErr,
  output io_out_s2_full_pred_3_is_jal,
  output io_out_s2_full_pred_3_is_jalr,
  output io_out_s2_full_pred_3_is_call,
  output io_out_s2_full_pred_3_is_ret,
  output io_out_s2_full_pred_3_last_may_be_rvi_call,
  output io_out_s2_full_pred_3_is_br_sharing,
  output io_out_s2_full_pred_3_hit,
  output io_out_s3_full_pred_0_br_taken_mask_0,
  output io_out_s3_full_pred_0_br_taken_mask_1,
  output io_out_s3_full_pred_0_slot_valids_0,
  output io_out_s3_full_pred_0_slot_valids_1,
  output [49:0] io_out_s3_full_pred_0_targets_0,
  output [49:0] io_out_s3_full_pred_0_targets_1,
  output [49:0] io_out_s3_full_pred_0_jalr_target,
  output [3:0] io_out_s3_full_pred_0_offsets_0,
  output [3:0] io_out_s3_full_pred_0_offsets_1,
  output [49:0] io_out_s3_full_pred_0_fallThroughAddr,
  output io_out_s3_full_pred_0_fallThroughErr,
  output io_out_s3_full_pred_0_multiHit,
  output io_out_s3_full_pred_0_is_jal,
  output io_out_s3_full_pred_0_is_jalr,
  output io_out_s3_full_pred_0_is_call,
  output io_out_s3_full_pred_0_is_ret,
  output io_out_s3_full_pred_0_last_may_be_rvi_call,
  output io_out_s3_full_pred_0_is_br_sharing,
  output io_out_s3_full_pred_0_hit,
  output io_out_s3_full_pred_1_br_taken_mask_0,
  output io_out_s3_full_pred_1_br_taken_mask_1,
  output io_out_s3_full_pred_1_slot_valids_0,
  output io_out_s3_full_pred_1_slot_valids_1,
  output [49:0] io_out_s3_full_pred_1_targets_0,
  output [49:0] io_out_s3_full_pred_1_targets_1,
  output [49:0] io_out_s3_full_pred_1_jalr_target,
  output [3:0] io_out_s3_full_pred_1_offsets_0,
  output [3:0] io_out_s3_full_pred_1_offsets_1,
  output [49:0] io_out_s3_full_pred_1_fallThroughAddr,
  output io_out_s3_full_pred_1_fallThroughErr,
  output io_out_s3_full_pred_1_multiHit,
  output io_out_s3_full_pred_1_is_jal,
  output io_out_s3_full_pred_1_is_jalr,
  output io_out_s3_full_pred_1_is_call,
  output io_out_s3_full_pred_1_is_ret,
  output io_out_s3_full_pred_1_last_may_be_rvi_call,
  output io_out_s3_full_pred_1_is_br_sharing,
  output io_out_s3_full_pred_1_hit,
  output io_out_s3_full_pred_2_br_taken_mask_0,
  output io_out_s3_full_pred_2_br_taken_mask_1,
  output io_out_s3_full_pred_2_slot_valids_0,
  output io_out_s3_full_pred_2_slot_valids_1,
  output [49:0] io_out_s3_full_pred_2_targets_0,
  output [49:0] io_out_s3_full_pred_2_targets_1,
  output [49:0] io_out_s3_full_pred_2_jalr_target,
  output [3:0] io_out_s3_full_pred_2_offsets_0,
  output [3:0] io_out_s3_full_pred_2_offsets_1,
  output [49:0] io_out_s3_full_pred_2_fallThroughAddr,
  output io_out_s3_full_pred_2_fallThroughErr,
  output io_out_s3_full_pred_2_multiHit,
  output io_out_s3_full_pred_2_is_jal,
  output io_out_s3_full_pred_2_is_jalr,
  output io_out_s3_full_pred_2_is_call,
  output io_out_s3_full_pred_2_is_ret,
  output io_out_s3_full_pred_2_last_may_be_rvi_call,
  output io_out_s3_full_pred_2_is_br_sharing,
  output io_out_s3_full_pred_2_hit,
  output io_out_s3_full_pred_3_br_taken_mask_0,
  output io_out_s3_full_pred_3_br_taken_mask_1,
  output io_out_s3_full_pred_3_slot_valids_0,
  output io_out_s3_full_pred_3_slot_valids_1,
  output [49:0] io_out_s3_full_pred_3_targets_0,
  output [49:0] io_out_s3_full_pred_3_targets_1,
  output [49:0] io_out_s3_full_pred_3_jalr_target,
  output [3:0] io_out_s3_full_pred_3_offsets_0,
  output [3:0] io_out_s3_full_pred_3_offsets_1,
  output [49:0] io_out_s3_full_pred_3_fallThroughAddr,
  output io_out_s3_full_pred_3_fallThroughErr,
  output io_out_s3_full_pred_3_multiHit,
  output io_out_s3_full_pred_3_is_jal,
  output io_out_s3_full_pred_3_is_jalr,
  output io_out_s3_full_pred_3_is_call,
  output io_out_s3_full_pred_3_is_ret,
  output io_out_s3_full_pred_3_last_may_be_rvi_call,
  output io_out_s3_full_pred_3_is_br_sharing,
  output io_out_s3_full_pred_3_hit,
  output [515:0] io_out_last_stage_meta,
  output io_out_last_stage_spec_info_sc_disagree_0,
  output io_out_last_stage_spec_info_sc_disagree_1,
  output io_out_last_stage_ftb_entry_isCall,
  output io_out_last_stage_ftb_entry_isRet,
  output io_out_last_stage_ftb_entry_isJalr,
  output io_out_last_stage_ftb_entry_valid,
  output [3:0] io_out_last_stage_ftb_entry_brSlots_0_offset,
  output io_out_last_stage_ftb_entry_brSlots_0_sharing,
  output io_out_last_stage_ftb_entry_brSlots_0_valid,
  output [11:0] io_out_last_stage_ftb_entry_brSlots_0_lower,
  output [1:0] io_out_last_stage_ftb_entry_brSlots_0_tarStat,
  output [3:0] io_out_last_stage_ftb_entry_tailSlot_offset,
  output io_out_last_stage_ftb_entry_tailSlot_sharing,
  output io_out_last_stage_ftb_entry_tailSlot_valid,
  output [19:0] io_out_last_stage_ftb_entry_tailSlot_lower,
  output [1:0] io_out_last_stage_ftb_entry_tailSlot_tarStat,
  output [3:0] io_out_last_stage_ftb_entry_pftAddr,
  output io_out_last_stage_ftb_entry_carry,
  output io_out_last_stage_ftb_entry_last_may_be_rvi_call,
  output io_out_last_stage_ftb_entry_strong_bias_0,
  output io_out_last_stage_ftb_entry_strong_bias_1,
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
  output io_s1_ready,
  input  io_update_valid,
  input  [49:0] io_update_bits_pc,
  input  io_update_bits_ftb_entry_isRet,
  input  io_update_bits_ftb_entry_isJalr,
  input  [3:0] io_update_bits_ftb_entry_tailSlot_offset,
  input  io_update_bits_ftb_entry_tailSlot_sharing,
  input  io_update_bits_ftb_entry_tailSlot_valid,
  input  io_update_bits_ftb_entry_strong_bias_1,
  input  io_update_bits_cfi_idx_valid,
  input  [3:0] io_update_bits_cfi_idx_bits,
  input  io_update_bits_jmp_taken,
  input  io_update_bits_mispred_mask_2,
  input  [515:0] io_update_bits_meta,
  input  [49:0] io_update_bits_full_target,
  input  [255:0] io_update_bits_ghist,
  input  [6:0] boreChildrenBd_bore_array,
  input  boreChildrenBd_bore_all,
  input  boreChildrenBd_bore_req,
  output boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_writeen,
  input  [75:0] boreChildrenBd_bore_be,
  input  [7:0] boreChildrenBd_bore_addr,
  input  [75:0] boreChildrenBd_bore_indata,
  input  boreChildrenBd_bore_readen,
  input  [7:0] boreChildrenBd_bore_addr_rd,
  output [75:0] boreChildrenBd_bore_outdata,
  input  [6:0] boreChildrenBd_bore_1_array,
  input  boreChildrenBd_bore_1_all,
  input  boreChildrenBd_bore_1_req,
  output boreChildrenBd_bore_1_ack,
  input  boreChildrenBd_bore_1_writeen,
  input  [75:0] boreChildrenBd_bore_1_be,
  input  [7:0] boreChildrenBd_bore_1_addr,
  input  [75:0] boreChildrenBd_bore_1_indata,
  input  boreChildrenBd_bore_1_readen,
  input  [7:0] boreChildrenBd_bore_1_addr_rd,
  output [75:0] boreChildrenBd_bore_1_outdata,
  input  [6:0] boreChildrenBd_bore_2_array,
  input  boreChildrenBd_bore_2_all,
  input  boreChildrenBd_bore_2_req,
  output boreChildrenBd_bore_2_ack,
  input  boreChildrenBd_bore_2_writeen,
  input  [75:0] boreChildrenBd_bore_2_be,
  input  [7:0] boreChildrenBd_bore_2_addr,
  input  [75:0] boreChildrenBd_bore_2_indata,
  input  boreChildrenBd_bore_2_readen,
  input  [7:0] boreChildrenBd_bore_2_addr_rd,
  output [75:0] boreChildrenBd_bore_2_outdata,
  input  [6:0] boreChildrenBd_bore_3_array,
  input  boreChildrenBd_bore_3_all,
  input  boreChildrenBd_bore_3_req,
  output boreChildrenBd_bore_3_ack,
  input  boreChildrenBd_bore_3_writeen,
  input  [75:0] boreChildrenBd_bore_3_be,
  input  [7:0] boreChildrenBd_bore_3_addr,
  input  [75:0] boreChildrenBd_bore_3_indata,
  input  boreChildrenBd_bore_3_readen,
  input  [7:0] boreChildrenBd_bore_3_addr_rd,
  output [75:0] boreChildrenBd_bore_3_outdata,
  input  [6:0] boreChildrenBd_bore_4_array,
  input  boreChildrenBd_bore_4_all,
  input  boreChildrenBd_bore_4_req,
  output boreChildrenBd_bore_4_ack,
  input  boreChildrenBd_bore_4_writeen,
  input  [75:0] boreChildrenBd_bore_4_be,
  input  [7:0] boreChildrenBd_bore_4_addr,
  input  [75:0] boreChildrenBd_bore_4_indata,
  input  boreChildrenBd_bore_4_readen,
  input  [7:0] boreChildrenBd_bore_4_addr_rd,
  output [75:0] boreChildrenBd_bore_4_outdata,
  input  sigFromSrams_bore_ram_hold,
  input  sigFromSrams_bore_ram_bypass,
  input  sigFromSrams_bore_ram_bp_clken,
  input  sigFromSrams_bore_ram_aux_clk,
  input  sigFromSrams_bore_ram_aux_ckbp,
  input  sigFromSrams_bore_ram_mcp_hold,
  input  sigFromSrams_bore_cgen,
  input  sigFromSrams_bore_1_ram_hold,
  input  sigFromSrams_bore_1_ram_bypass,
  input  sigFromSrams_bore_1_ram_bp_clken,
  input  sigFromSrams_bore_1_ram_aux_clk,
  input  sigFromSrams_bore_1_ram_aux_ckbp,
  input  sigFromSrams_bore_1_ram_mcp_hold,
  input  sigFromSrams_bore_1_cgen,
  input  sigFromSrams_bore_2_ram_hold,
  input  sigFromSrams_bore_2_ram_bypass,
  input  sigFromSrams_bore_2_ram_bp_clken,
  input  sigFromSrams_bore_2_ram_aux_clk,
  input  sigFromSrams_bore_2_ram_aux_ckbp,
  input  sigFromSrams_bore_2_ram_mcp_hold,
  input  sigFromSrams_bore_2_cgen,
  input  sigFromSrams_bore_3_ram_hold,
  input  sigFromSrams_bore_3_ram_bypass,
  input  sigFromSrams_bore_3_ram_bp_clken,
  input  sigFromSrams_bore_3_ram_aux_clk,
  input  sigFromSrams_bore_3_ram_aux_ckbp,
  input  sigFromSrams_bore_3_ram_mcp_hold,
  input  sigFromSrams_bore_3_cgen,
  input  sigFromSrams_bore_4_ram_hold,
  input  sigFromSrams_bore_4_ram_bypass,
  input  sigFromSrams_bore_4_ram_bp_clken,
  input  sigFromSrams_bore_4_ram_aux_clk,
  input  sigFromSrams_bore_4_ram_aux_ckbp,
  input  sigFromSrams_bore_4_ram_mcp_hold,
  input  sigFromSrams_bore_4_cgen,
  input  sigFromSrams_bore_5_ram_hold,
  input  sigFromSrams_bore_5_ram_bypass,
  input  sigFromSrams_bore_5_ram_bp_clken,
  input  sigFromSrams_bore_5_ram_aux_clk,
  input  sigFromSrams_bore_5_ram_aux_ckbp,
  input  sigFromSrams_bore_5_ram_mcp_hold,
  input  sigFromSrams_bore_5_cgen,
  input  sigFromSrams_bore_6_ram_hold,
  input  sigFromSrams_bore_6_ram_bypass,
  input  sigFromSrams_bore_6_ram_bp_clken,
  input  sigFromSrams_bore_6_ram_aux_clk,
  input  sigFromSrams_bore_6_ram_aux_ckbp,
  input  sigFromSrams_bore_6_ram_mcp_hold,
  input  sigFromSrams_bore_6_cgen,
  input  sigFromSrams_bore_7_ram_hold,
  input  sigFromSrams_bore_7_ram_bypass,
  input  sigFromSrams_bore_7_ram_bp_clken,
  input  sigFromSrams_bore_7_ram_aux_clk,
  input  sigFromSrams_bore_7_ram_aux_ckbp,
  input  sigFromSrams_bore_7_ram_mcp_hold,
  input  sigFromSrams_bore_7_cgen
);

  logic [PC_W-1:0]      s0_pc    [NUM_DUP];
  logic                 s0_fire  [NUM_DUP];
  logic                 s1_fire  [NUM_DUP];
  logic                 s2_fire  [NUM_DUP];
  logic [PC_W-1:0]      s3_target[NUM_DUP];
  logic                 tbl_req_valid;
  logic [PC_W-1:0]      tbl_req_pc;
  logic                 tbl_req_ready [NUM_TABLES];
  logic                 tbl_resp_valid[NUM_TABLES];
  logic [1:0]           tbl_resp_ctr  [NUM_TABLES];
  logic                 tbl_resp_u    [NUM_TABLES];
  ittage_offset_t       tbl_resp_off  [NUM_TABLES];
  ittage_upd_t          tbl_upd       [NUM_TABLES];
  logic                 rt_resp_hit      [NUM_TABLES];
  logic [REGION_W-1:0]  rt_resp_region   [NUM_TABLES];
  logic [REGION_W-1:0]  rt_update_region [2];
  logic                 rt_update_hit    [2];
  logic [PTR_W-1:0]     rt_update_pointer[2];
  logic                 rt_write_valid;
  logic [REGION_W-1:0]  rt_write_region;
  logic [PTR_W-1:0]     rt_write_pointer;
  logic [NUM_TABLES-1:0] lfsr_bits;

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

  // ---- 可读核：本预测器自己的全部逻辑 ----
  xs_ITTage_core u_core (
    .clock                 (clock),
    .reset                 (reset),
    .reset_vector          (io_reset_vector),
    .s0_pc                 (s0_pc),
    .s0_fire               (s0_fire),
    .s1_fire               (s1_fire),
    .s2_fire               (s2_fire),
    .s1_uftb_hit           (io_in_bits_resp_in_0_s1_uftbHit),
    .s1_uftb_has_indirect  (io_in_bits_resp_in_0_s1_uftbHasIndirect),
    .s1_ftb_close_req      (io_in_bits_resp_in_0_s1_ftbCloseReq),
    .base_target           (io_in_bits_resp_in_0_s2_full_pred_3_jalr_target),
    .tbl_req_valid         (tbl_req_valid),
    .tbl_req_pc            (tbl_req_pc),
    .tbl_req_ready         (tbl_req_ready),
    .tbl_resp_valid        (tbl_resp_valid),
    .tbl_resp_ctr          (tbl_resp_ctr),
    .tbl_resp_u            (tbl_resp_u),
    .tbl_resp_off          (tbl_resp_off),
    .tbl_upd               (tbl_upd),
    .rt_resp_hit           (rt_resp_hit),
    .rt_resp_region        (rt_resp_region),
    .rt_update_region      (rt_update_region),
    .rt_update_hit         (rt_update_hit),
    .rt_update_pointer     (rt_update_pointer),
    .rt_write_valid        (rt_write_valid),
    .rt_write_region       (rt_write_region),
    .rt_write_pointer      (rt_write_pointer),
    .lfsr_bits             (lfsr_bits),
    .update_valid          (io_update_valid),
    .update_pc             (io_update_bits_pc),
    .update_is_ret_raw     (io_update_bits_ftb_entry_isRet),
    .update_is_jalr_raw    (io_update_bits_ftb_entry_isJalr),
    .update_tail_offset    (io_update_bits_ftb_entry_tailSlot_offset),
    .update_tail_sharing   (io_update_bits_ftb_entry_tailSlot_sharing),
    .update_tail_valid     (io_update_bits_ftb_entry_tailSlot_valid),
    .update_strong_bias_1  (io_update_bits_ftb_entry_strong_bias_1),
    .update_cfi_valid      (io_update_bits_cfi_idx_valid),
    .update_cfi_idx        (io_update_bits_cfi_idx_bits),
    .update_jmp_taken      (io_update_bits_jmp_taken),
    .update_jmp_mispred    (io_update_bits_mispred_mask_2),
    .update_meta           (io_update_bits_meta),
    .update_full_target    (io_update_bits_full_target),
    .update_ghist          (io_update_bits_ghist),
    .s3_target             (s3_target),
    .last_stage_meta       (io_out_last_stage_meta),
    .s1_ready              (io_s1_ready)
  );

  // ---- 子模块（实例名 / 端口顺序同 golden）----
  ITTageTable tables_0 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_req_ready                             (tbl_req_ready[0]),
    .io_req_valid                             (tbl_req_valid),
    .io_req_bits_pc                           (tbl_req_pc),
    .io_req_bits_folded_hist_hist_12_folded_hist (io_in_bits_s1_folded_hist_3_hist_12_folded_hist),
    .io_resp_valid                            (tbl_resp_valid[0]),
    .io_resp_bits_ctr                         (tbl_resp_ctr[0]),
    .io_resp_bits_u                           (tbl_resp_u[0]),
    .io_resp_bits_target_offset_offset        (tbl_resp_off[0].offset),
    .io_resp_bits_target_offset_pointer       (tbl_resp_off[0].pointer),
    .io_resp_bits_target_offset_usePCRegion   (tbl_resp_off[0].usePCRegion),
    .io_update_pc                             (tbl_upd[0].pc),
    .io_update_ghist                          (tbl_upd[0].ghist),
    .io_update_valid                          (tbl_upd[0].valid),
    .io_update_correct                        (tbl_upd[0].correct),
    .io_update_alloc                          (tbl_upd[0].alloc),
    .io_update_oldCtr                         (tbl_upd[0].old_ctr),
    .io_update_uValid                         (tbl_upd[0].u_valid),
    .io_update_u                              (tbl_upd[0].u),
    .io_update_reset_u                        (tbl_upd[0].reset_u),
    .io_update_target_offset_offset           (tbl_upd[0].target_offset.offset),
    .io_update_target_offset_pointer          (tbl_upd[0].target_offset.pointer),
    .io_update_target_offset_usePCRegion      (tbl_upd[0].target_offset.usePCRegion),
    .io_update_old_target_offset_offset       (tbl_upd[0].old_target_offset.offset),
    .io_update_old_target_offset_pointer      (tbl_upd[0].old_target_offset.pointer),
    .io_update_old_target_offset_usePCRegion  (tbl_upd[0].old_target_offset.usePCRegion),
    .boreChildrenBd_bore_array                (boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all                  (boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req                  (boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack                  (boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen              (boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be                   (boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr                 (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata               (boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen               (boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd              (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata              (boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold               (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass             (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken           (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk            (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp           (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold           (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen                   (sigFromSrams_bore_cgen)
  );
  ITTageTable_1 tables_1 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_req_ready                             (tbl_req_ready[1]),
    .io_req_valid                             (tbl_req_valid),
    .io_req_bits_pc                           (tbl_req_pc),
    .io_req_bits_folded_hist_hist_14_folded_hist (io_in_bits_s1_folded_hist_3_hist_14_folded_hist),
    .io_resp_valid                            (tbl_resp_valid[1]),
    .io_resp_bits_ctr                         (tbl_resp_ctr[1]),
    .io_resp_bits_u                           (tbl_resp_u[1]),
    .io_resp_bits_target_offset_offset        (tbl_resp_off[1].offset),
    .io_resp_bits_target_offset_pointer       (tbl_resp_off[1].pointer),
    .io_resp_bits_target_offset_usePCRegion   (tbl_resp_off[1].usePCRegion),
    .io_update_pc                             (tbl_upd[1].pc),
    .io_update_ghist                          (tbl_upd[1].ghist),
    .io_update_valid                          (tbl_upd[1].valid),
    .io_update_correct                        (tbl_upd[1].correct),
    .io_update_alloc                          (tbl_upd[1].alloc),
    .io_update_oldCtr                         (tbl_upd[1].old_ctr),
    .io_update_uValid                         (tbl_upd[1].u_valid),
    .io_update_u                              (tbl_upd[1].u),
    .io_update_reset_u                        (tbl_upd[1].reset_u),
    .io_update_target_offset_offset           (tbl_upd[1].target_offset.offset),
    .io_update_target_offset_pointer          (tbl_upd[1].target_offset.pointer),
    .io_update_target_offset_usePCRegion      (tbl_upd[1].target_offset.usePCRegion),
    .io_update_old_target_offset_offset       (tbl_upd[1].old_target_offset.offset),
    .io_update_old_target_offset_pointer      (tbl_upd[1].old_target_offset.pointer),
    .io_update_old_target_offset_usePCRegion  (tbl_upd[1].old_target_offset.usePCRegion),
    .boreChildrenBd_bore_array                (boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_all                  (boreChildrenBd_bore_1_all),
    .boreChildrenBd_bore_req                  (boreChildrenBd_bore_1_req),
    .boreChildrenBd_bore_ack                  (boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_writeen              (boreChildrenBd_bore_1_writeen),
    .boreChildrenBd_bore_be                   (boreChildrenBd_bore_1_be),
    .boreChildrenBd_bore_addr                 (boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_indata               (boreChildrenBd_bore_1_indata),
    .boreChildrenBd_bore_readen               (boreChildrenBd_bore_1_readen),
    .boreChildrenBd_bore_addr_rd              (boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_outdata              (boreChildrenBd_bore_1_outdata),
    .sigFromSrams_bore_ram_hold               (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_ram_bypass             (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken           (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk            (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp           (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold           (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_cgen                   (sigFromSrams_bore_1_cgen)
  );
  ITTageTable_2 tables_2 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_req_ready                             (tbl_req_ready[2]),
    .io_req_valid                             (tbl_req_valid),
    .io_req_bits_pc                           (tbl_req_pc),
    .io_req_bits_folded_hist_hist_13_folded_hist (io_in_bits_s1_folded_hist_3_hist_13_folded_hist),
    .io_req_bits_folded_hist_hist_4_folded_hist (io_in_bits_s1_folded_hist_3_hist_4_folded_hist),
    .io_resp_valid                            (tbl_resp_valid[2]),
    .io_resp_bits_ctr                         (tbl_resp_ctr[2]),
    .io_resp_bits_u                           (tbl_resp_u[2]),
    .io_resp_bits_target_offset_offset        (tbl_resp_off[2].offset),
    .io_resp_bits_target_offset_pointer       (tbl_resp_off[2].pointer),
    .io_resp_bits_target_offset_usePCRegion   (tbl_resp_off[2].usePCRegion),
    .io_update_pc                             (tbl_upd[2].pc),
    .io_update_ghist                          (tbl_upd[2].ghist),
    .io_update_valid                          (tbl_upd[2].valid),
    .io_update_correct                        (tbl_upd[2].correct),
    .io_update_alloc                          (tbl_upd[2].alloc),
    .io_update_oldCtr                         (tbl_upd[2].old_ctr),
    .io_update_uValid                         (tbl_upd[2].u_valid),
    .io_update_u                              (tbl_upd[2].u),
    .io_update_reset_u                        (tbl_upd[2].reset_u),
    .io_update_target_offset_offset           (tbl_upd[2].target_offset.offset),
    .io_update_target_offset_pointer          (tbl_upd[2].target_offset.pointer),
    .io_update_target_offset_usePCRegion      (tbl_upd[2].target_offset.usePCRegion),
    .io_update_old_target_offset_offset       (tbl_upd[2].old_target_offset.offset),
    .io_update_old_target_offset_pointer      (tbl_upd[2].old_target_offset.pointer),
    .io_update_old_target_offset_usePCRegion  (tbl_upd[2].old_target_offset.usePCRegion),
    .boreChildrenBd_bore_array                (boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_all                  (boreChildrenBd_bore_2_all),
    .boreChildrenBd_bore_req                  (boreChildrenBd_bore_2_req),
    .boreChildrenBd_bore_ack                  (boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_writeen              (boreChildrenBd_bore_2_writeen),
    .boreChildrenBd_bore_be                   (boreChildrenBd_bore_2_be),
    .boreChildrenBd_bore_addr                 (boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_indata               (boreChildrenBd_bore_2_indata),
    .boreChildrenBd_bore_readen               (boreChildrenBd_bore_2_readen),
    .boreChildrenBd_bore_addr_rd              (boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_outdata              (boreChildrenBd_bore_2_outdata),
    .sigFromSrams_bore_ram_hold               (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_ram_bypass             (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken           (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk            (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp           (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold           (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_cgen                   (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_1_ram_hold             (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_1_ram_bypass           (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken         (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk          (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp         (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold         (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                 (sigFromSrams_bore_3_cgen)
  );
  ITTageTable_3 tables_3 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_req_ready                             (tbl_req_ready[3]),
    .io_req_valid                             (tbl_req_valid),
    .io_req_bits_pc                           (tbl_req_pc),
    .io_req_bits_folded_hist_hist_6_folded_hist (io_in_bits_s1_folded_hist_3_hist_6_folded_hist),
    .io_req_bits_folded_hist_hist_2_folded_hist (io_in_bits_s1_folded_hist_3_hist_2_folded_hist),
    .io_resp_valid                            (tbl_resp_valid[3]),
    .io_resp_bits_ctr                         (tbl_resp_ctr[3]),
    .io_resp_bits_u                           (tbl_resp_u[3]),
    .io_resp_bits_target_offset_offset        (tbl_resp_off[3].offset),
    .io_resp_bits_target_offset_pointer       (tbl_resp_off[3].pointer),
    .io_resp_bits_target_offset_usePCRegion   (tbl_resp_off[3].usePCRegion),
    .io_update_pc                             (tbl_upd[3].pc),
    .io_update_ghist                          (tbl_upd[3].ghist),
    .io_update_valid                          (tbl_upd[3].valid),
    .io_update_correct                        (tbl_upd[3].correct),
    .io_update_alloc                          (tbl_upd[3].alloc),
    .io_update_oldCtr                         (tbl_upd[3].old_ctr),
    .io_update_uValid                         (tbl_upd[3].u_valid),
    .io_update_u                              (tbl_upd[3].u),
    .io_update_reset_u                        (tbl_upd[3].reset_u),
    .io_update_target_offset_offset           (tbl_upd[3].target_offset.offset),
    .io_update_target_offset_pointer          (tbl_upd[3].target_offset.pointer),
    .io_update_target_offset_usePCRegion      (tbl_upd[3].target_offset.usePCRegion),
    .io_update_old_target_offset_offset       (tbl_upd[3].old_target_offset.offset),
    .io_update_old_target_offset_pointer      (tbl_upd[3].old_target_offset.pointer),
    .io_update_old_target_offset_usePCRegion  (tbl_upd[3].old_target_offset.usePCRegion),
    .boreChildrenBd_bore_array                (boreChildrenBd_bore_3_array),
    .boreChildrenBd_bore_all                  (boreChildrenBd_bore_3_all),
    .boreChildrenBd_bore_req                  (boreChildrenBd_bore_3_req),
    .boreChildrenBd_bore_ack                  (boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_writeen              (boreChildrenBd_bore_3_writeen),
    .boreChildrenBd_bore_be                   (boreChildrenBd_bore_3_be),
    .boreChildrenBd_bore_addr                 (boreChildrenBd_bore_3_addr),
    .boreChildrenBd_bore_indata               (boreChildrenBd_bore_3_indata),
    .boreChildrenBd_bore_readen               (boreChildrenBd_bore_3_readen),
    .boreChildrenBd_bore_addr_rd              (boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_outdata              (boreChildrenBd_bore_3_outdata),
    .sigFromSrams_bore_ram_hold               (sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_ram_bypass             (sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken           (sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk            (sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp           (sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold           (sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_cgen                   (sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_1_ram_hold             (sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_1_ram_bypass           (sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken         (sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk          (sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp         (sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold         (sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                 (sigFromSrams_bore_5_cgen)
  );
  ITTageTable_4 tables_4 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_req_ready                             (tbl_req_ready[4]),
    .io_req_valid                             (tbl_req_valid),
    .io_req_bits_pc                           (tbl_req_pc),
    .io_req_bits_folded_hist_hist_10_folded_hist (io_in_bits_s1_folded_hist_3_hist_10_folded_hist),
    .io_req_bits_folded_hist_hist_3_folded_hist (io_in_bits_s1_folded_hist_3_hist_3_folded_hist),
    .io_resp_valid                            (tbl_resp_valid[4]),
    .io_resp_bits_ctr                         (tbl_resp_ctr[4]),
    .io_resp_bits_u                           (tbl_resp_u[4]),
    .io_resp_bits_target_offset_offset        (tbl_resp_off[4].offset),
    .io_resp_bits_target_offset_pointer       (tbl_resp_off[4].pointer),
    .io_resp_bits_target_offset_usePCRegion   (tbl_resp_off[4].usePCRegion),
    .io_update_pc                             (tbl_upd[4].pc),
    .io_update_ghist                          (tbl_upd[4].ghist),
    .io_update_valid                          (tbl_upd[4].valid),
    .io_update_correct                        (tbl_upd[4].correct),
    .io_update_alloc                          (tbl_upd[4].alloc),
    .io_update_oldCtr                         (tbl_upd[4].old_ctr),
    .io_update_uValid                         (tbl_upd[4].u_valid),
    .io_update_u                              (tbl_upd[4].u),
    .io_update_reset_u                        (tbl_upd[4].reset_u),
    .io_update_target_offset_offset           (tbl_upd[4].target_offset.offset),
    .io_update_target_offset_pointer          (tbl_upd[4].target_offset.pointer),
    .io_update_target_offset_usePCRegion      (tbl_upd[4].target_offset.usePCRegion),
    .io_update_old_target_offset_offset       (tbl_upd[4].old_target_offset.offset),
    .io_update_old_target_offset_pointer      (tbl_upd[4].old_target_offset.pointer),
    .io_update_old_target_offset_usePCRegion  (tbl_upd[4].old_target_offset.usePCRegion),
    .boreChildrenBd_bore_array                (boreChildrenBd_bore_4_array),
    .boreChildrenBd_bore_all                  (boreChildrenBd_bore_4_all),
    .boreChildrenBd_bore_req                  (boreChildrenBd_bore_4_req),
    .boreChildrenBd_bore_ack                  (boreChildrenBd_bore_4_ack),
    .boreChildrenBd_bore_writeen              (boreChildrenBd_bore_4_writeen),
    .boreChildrenBd_bore_be                   (boreChildrenBd_bore_4_be),
    .boreChildrenBd_bore_addr                 (boreChildrenBd_bore_4_addr),
    .boreChildrenBd_bore_indata               (boreChildrenBd_bore_4_indata),
    .boreChildrenBd_bore_readen               (boreChildrenBd_bore_4_readen),
    .boreChildrenBd_bore_addr_rd              (boreChildrenBd_bore_4_addr_rd),
    .boreChildrenBd_bore_outdata              (boreChildrenBd_bore_4_outdata),
    .sigFromSrams_bore_ram_hold               (sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_ram_bypass             (sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken           (sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk            (sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp           (sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold           (sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_cgen                   (sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_1_ram_hold             (sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_1_ram_bypass           (sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken         (sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk          (sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp         (sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold         (sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                 (sigFromSrams_bore_7_cgen)
  );
  RegionWays rTable (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_req_pointer_0                         (tbl_resp_off[0].pointer),
    .io_req_pointer_1                         (tbl_resp_off[1].pointer),
    .io_req_pointer_2                         (tbl_resp_off[2].pointer),
    .io_req_pointer_3                         (tbl_resp_off[3].pointer),
    .io_req_pointer_4                         (tbl_resp_off[4].pointer),
    .io_resp_hit_0                            (rt_resp_hit[0]),
    .io_resp_hit_1                            (rt_resp_hit[1]),
    .io_resp_hit_2                            (rt_resp_hit[2]),
    .io_resp_hit_3                            (rt_resp_hit[3]),
    .io_resp_hit_4                            (rt_resp_hit[4]),
    .io_resp_region_0                         (rt_resp_region[0]),
    .io_resp_region_1                         (rt_resp_region[1]),
    .io_resp_region_2                         (rt_resp_region[2]),
    .io_resp_region_3                         (rt_resp_region[3]),
    .io_resp_region_4                         (rt_resp_region[4]),
    .io_update_region_0                       (rt_update_region[0]),
    .io_update_region_1                       (rt_update_region[1]),
    .io_update_hit_0                          (rt_update_hit[0]),
    .io_update_hit_1                          (rt_update_hit[1]),
    .io_update_pointer_0                      (rt_update_pointer[0]),
    .io_update_pointer_1                      (rt_update_pointer[1]),
    .io_write_valid                           (rt_write_valid),
    .io_write_region                          (rt_write_region),
    .io_write_pointer                         (rt_write_pointer)
  );
  MaxPeriodFibonacciLFSR s2_allocLFSR_prng (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_out_0                                 (lfsr_bits[0]),
    .io_out_1                                 (lfsr_bits[1]),
    .io_out_2                                 (lfsr_bits[2]),
    .io_out_3                                 (lfsr_bits[3]),
    .io_out_4                                 (lfsr_bits[4]),
    .io_out_5                                 (),
    .io_out_6                                 (),
    .io_out_7                                 (),
    .io_out_8                                 (),
    .io_out_9                                 (),
    .io_out_10                                (),
    .io_out_11                                (),
    .io_out_12                                (),
    .io_out_13                                (),
    .io_out_14                                ()
  );

  // ---- 顶层输出 ----
  assign io_out_s2_full_pred_0_br_taken_mask_0 = io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0;  // 透传
  assign io_out_s2_full_pred_0_br_taken_mask_1 = io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1;  // 透传
  assign io_out_s2_full_pred_0_slot_valids_0 = io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_0;  // 透传
  assign io_out_s2_full_pred_0_slot_valids_1 = io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_1;  // 透传
  assign io_out_s2_full_pred_0_targets_0 = io_in_bits_resp_in_0_s2_full_pred_0_targets_0;  // 透传
  assign io_out_s2_full_pred_0_targets_1 = io_in_bits_resp_in_0_s2_full_pred_0_targets_1;  // 透传
  assign io_out_s2_full_pred_0_jalr_target = io_in_bits_resp_in_0_s2_full_pred_0_jalr_target;  // 透传
  assign io_out_s2_full_pred_0_offsets_0 = io_in_bits_resp_in_0_s2_full_pred_0_offsets_0;  // 透传
  assign io_out_s2_full_pred_0_offsets_1 = io_in_bits_resp_in_0_s2_full_pred_0_offsets_1;  // 透传
  assign io_out_s2_full_pred_0_fallThroughAddr = io_in_bits_resp_in_0_s2_full_pred_0_fallThroughAddr;  // 透传
  assign io_out_s2_full_pred_0_fallThroughErr = io_in_bits_resp_in_0_s2_full_pred_0_fallThroughErr;  // 透传
  assign io_out_s2_full_pred_0_is_jal = io_in_bits_resp_in_0_s2_full_pred_0_is_jal;  // 透传
  assign io_out_s2_full_pred_0_is_jalr = io_in_bits_resp_in_0_s2_full_pred_0_is_jalr;  // 透传
  assign io_out_s2_full_pred_0_is_call = io_in_bits_resp_in_0_s2_full_pred_0_is_call;  // 透传
  assign io_out_s2_full_pred_0_is_ret = io_in_bits_resp_in_0_s2_full_pred_0_is_ret;  // 透传
  assign io_out_s2_full_pred_0_last_may_be_rvi_call = io_in_bits_resp_in_0_s2_full_pred_0_last_may_be_rvi_call;  // 透传
  assign io_out_s2_full_pred_0_is_br_sharing = io_in_bits_resp_in_0_s2_full_pred_0_is_br_sharing;  // 透传
  assign io_out_s2_full_pred_0_hit = io_in_bits_resp_in_0_s2_full_pred_0_hit;  // 透传
  assign io_out_s2_full_pred_1_br_taken_mask_0 = io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0;  // 透传
  assign io_out_s2_full_pred_1_br_taken_mask_1 = io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1;  // 透传
  assign io_out_s2_full_pred_1_slot_valids_0 = io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_0;  // 透传
  assign io_out_s2_full_pred_1_slot_valids_1 = io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_1;  // 透传
  assign io_out_s2_full_pred_1_targets_0 = io_in_bits_resp_in_0_s2_full_pred_1_targets_0;  // 透传
  assign io_out_s2_full_pred_1_targets_1 = io_in_bits_resp_in_0_s2_full_pred_1_targets_1;  // 透传
  assign io_out_s2_full_pred_1_jalr_target = io_in_bits_resp_in_0_s2_full_pred_1_jalr_target;  // 透传
  assign io_out_s2_full_pred_1_offsets_0 = io_in_bits_resp_in_0_s2_full_pred_1_offsets_0;  // 透传
  assign io_out_s2_full_pred_1_offsets_1 = io_in_bits_resp_in_0_s2_full_pred_1_offsets_1;  // 透传
  assign io_out_s2_full_pred_1_fallThroughAddr = io_in_bits_resp_in_0_s2_full_pred_1_fallThroughAddr;  // 透传
  assign io_out_s2_full_pred_1_fallThroughErr = io_in_bits_resp_in_0_s2_full_pred_1_fallThroughErr;  // 透传
  assign io_out_s2_full_pred_1_is_jal = io_in_bits_resp_in_0_s2_full_pred_1_is_jal;  // 透传
  assign io_out_s2_full_pred_1_is_jalr = io_in_bits_resp_in_0_s2_full_pred_1_is_jalr;  // 透传
  assign io_out_s2_full_pred_1_is_call = io_in_bits_resp_in_0_s2_full_pred_1_is_call;  // 透传
  assign io_out_s2_full_pred_1_is_ret = io_in_bits_resp_in_0_s2_full_pred_1_is_ret;  // 透传
  assign io_out_s2_full_pred_1_last_may_be_rvi_call = io_in_bits_resp_in_0_s2_full_pred_1_last_may_be_rvi_call;  // 透传
  assign io_out_s2_full_pred_1_is_br_sharing = io_in_bits_resp_in_0_s2_full_pred_1_is_br_sharing;  // 透传
  assign io_out_s2_full_pred_1_hit = io_in_bits_resp_in_0_s2_full_pred_1_hit;  // 透传
  assign io_out_s2_full_pred_2_br_taken_mask_0 = io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0;  // 透传
  assign io_out_s2_full_pred_2_br_taken_mask_1 = io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1;  // 透传
  assign io_out_s2_full_pred_2_slot_valids_0 = io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_0;  // 透传
  assign io_out_s2_full_pred_2_slot_valids_1 = io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_1;  // 透传
  assign io_out_s2_full_pred_2_targets_0 = io_in_bits_resp_in_0_s2_full_pred_2_targets_0;  // 透传
  assign io_out_s2_full_pred_2_targets_1 = io_in_bits_resp_in_0_s2_full_pred_2_targets_1;  // 透传
  assign io_out_s2_full_pred_2_jalr_target = io_in_bits_resp_in_0_s2_full_pred_2_jalr_target;  // 透传
  assign io_out_s2_full_pred_2_offsets_0 = io_in_bits_resp_in_0_s2_full_pred_2_offsets_0;  // 透传
  assign io_out_s2_full_pred_2_offsets_1 = io_in_bits_resp_in_0_s2_full_pred_2_offsets_1;  // 透传
  assign io_out_s2_full_pred_2_fallThroughAddr = io_in_bits_resp_in_0_s2_full_pred_2_fallThroughAddr;  // 透传
  assign io_out_s2_full_pred_2_fallThroughErr = io_in_bits_resp_in_0_s2_full_pred_2_fallThroughErr;  // 透传
  assign io_out_s2_full_pred_2_is_jal = io_in_bits_resp_in_0_s2_full_pred_2_is_jal;  // 透传
  assign io_out_s2_full_pred_2_is_jalr = io_in_bits_resp_in_0_s2_full_pred_2_is_jalr;  // 透传
  assign io_out_s2_full_pred_2_is_call = io_in_bits_resp_in_0_s2_full_pred_2_is_call;  // 透传
  assign io_out_s2_full_pred_2_is_ret = io_in_bits_resp_in_0_s2_full_pred_2_is_ret;  // 透传
  assign io_out_s2_full_pred_2_last_may_be_rvi_call = io_in_bits_resp_in_0_s2_full_pred_2_last_may_be_rvi_call;  // 透传
  assign io_out_s2_full_pred_2_is_br_sharing = io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing;  // 透传
  assign io_out_s2_full_pred_2_hit = io_in_bits_resp_in_0_s2_full_pred_2_hit;  // 透传
  assign io_out_s2_full_pred_3_br_taken_mask_0 = io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0;  // 透传
  assign io_out_s2_full_pred_3_br_taken_mask_1 = io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1;  // 透传
  assign io_out_s2_full_pred_3_slot_valids_0 = io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_0;  // 透传
  assign io_out_s2_full_pred_3_slot_valids_1 = io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_1;  // 透传
  assign io_out_s2_full_pred_3_targets_0 = io_in_bits_resp_in_0_s2_full_pred_3_targets_0;  // 透传
  assign io_out_s2_full_pred_3_targets_1 = io_in_bits_resp_in_0_s2_full_pred_3_targets_1;  // 透传
  assign io_out_s2_full_pred_3_jalr_target = io_in_bits_resp_in_0_s2_full_pred_3_jalr_target;  // 透传
  assign io_out_s2_full_pred_3_offsets_0 = io_in_bits_resp_in_0_s2_full_pred_3_offsets_0;  // 透传
  assign io_out_s2_full_pred_3_offsets_1 = io_in_bits_resp_in_0_s2_full_pred_3_offsets_1;  // 透传
  assign io_out_s2_full_pred_3_fallThroughAddr = io_in_bits_resp_in_0_s2_full_pred_3_fallThroughAddr;  // 透传
  assign io_out_s2_full_pred_3_fallThroughErr = io_in_bits_resp_in_0_s2_full_pred_3_fallThroughErr;  // 透传
  assign io_out_s2_full_pred_3_is_jal = io_in_bits_resp_in_0_s2_full_pred_3_is_jal;  // 透传
  assign io_out_s2_full_pred_3_is_jalr = io_in_bits_resp_in_0_s2_full_pred_3_is_jalr;  // 透传
  assign io_out_s2_full_pred_3_is_call = io_in_bits_resp_in_0_s2_full_pred_3_is_call;  // 透传
  assign io_out_s2_full_pred_3_is_ret = io_in_bits_resp_in_0_s2_full_pred_3_is_ret;  // 透传
  assign io_out_s2_full_pred_3_last_may_be_rvi_call = io_in_bits_resp_in_0_s2_full_pred_3_last_may_be_rvi_call;  // 透传
  assign io_out_s2_full_pred_3_is_br_sharing = io_in_bits_resp_in_0_s2_full_pred_3_is_br_sharing;  // 透传
  assign io_out_s2_full_pred_3_hit = io_in_bits_resp_in_0_s2_full_pred_3_hit;  // 透传
  assign io_out_s3_full_pred_0_br_taken_mask_0 = io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0;  // 透传
  assign io_out_s3_full_pred_0_br_taken_mask_1 = io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1;  // 透传
  assign io_out_s3_full_pred_0_slot_valids_0 = io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_0;  // 透传
  assign io_out_s3_full_pred_0_slot_valids_1 = io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_1;  // 透传
  assign io_out_s3_full_pred_0_targets_0 = io_in_bits_resp_in_0_s3_full_pred_0_targets_0;  // 透传
  assign io_out_s3_full_pred_0_targets_1 = io_in_bits_resp_in_0_s3_full_pred_0_targets_1;  // 透传
  assign io_out_s3_full_pred_0_jalr_target = s3_target[0];
  assign io_out_s3_full_pred_0_offsets_0 = io_in_bits_resp_in_0_s3_full_pred_0_offsets_0;  // 透传
  assign io_out_s3_full_pred_0_offsets_1 = io_in_bits_resp_in_0_s3_full_pred_0_offsets_1;  // 透传
  assign io_out_s3_full_pred_0_fallThroughAddr = io_in_bits_resp_in_0_s3_full_pred_0_fallThroughAddr;  // 透传
  assign io_out_s3_full_pred_0_fallThroughErr = io_in_bits_resp_in_0_s3_full_pred_0_fallThroughErr;  // 透传
  assign io_out_s3_full_pred_0_multiHit = io_in_bits_resp_in_0_s3_full_pred_0_multiHit;  // 透传
  assign io_out_s3_full_pred_0_is_jal = io_in_bits_resp_in_0_s3_full_pred_0_is_jal;  // 透传
  assign io_out_s3_full_pred_0_is_jalr = io_in_bits_resp_in_0_s3_full_pred_0_is_jalr;  // 透传
  assign io_out_s3_full_pred_0_is_call = io_in_bits_resp_in_0_s3_full_pred_0_is_call;  // 透传
  assign io_out_s3_full_pred_0_is_ret = io_in_bits_resp_in_0_s3_full_pred_0_is_ret;  // 透传
  assign io_out_s3_full_pred_0_last_may_be_rvi_call = io_in_bits_resp_in_0_s3_full_pred_0_last_may_be_rvi_call;  // 透传
  assign io_out_s3_full_pred_0_is_br_sharing = io_in_bits_resp_in_0_s3_full_pred_0_is_br_sharing;  // 透传
  assign io_out_s3_full_pred_0_hit = io_in_bits_resp_in_0_s3_full_pred_0_hit;  // 透传
  assign io_out_s3_full_pred_1_br_taken_mask_0 = io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0;  // 透传
  assign io_out_s3_full_pred_1_br_taken_mask_1 = io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1;  // 透传
  assign io_out_s3_full_pred_1_slot_valids_0 = io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_0;  // 透传
  assign io_out_s3_full_pred_1_slot_valids_1 = io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_1;  // 透传
  assign io_out_s3_full_pred_1_targets_0 = io_in_bits_resp_in_0_s3_full_pred_1_targets_0;  // 透传
  assign io_out_s3_full_pred_1_targets_1 = io_in_bits_resp_in_0_s3_full_pred_1_targets_1;  // 透传
  assign io_out_s3_full_pred_1_jalr_target = s3_target[1];
  assign io_out_s3_full_pred_1_offsets_0 = io_in_bits_resp_in_0_s3_full_pred_1_offsets_0;  // 透传
  assign io_out_s3_full_pred_1_offsets_1 = io_in_bits_resp_in_0_s3_full_pred_1_offsets_1;  // 透传
  assign io_out_s3_full_pred_1_fallThroughAddr = io_in_bits_resp_in_0_s3_full_pred_1_fallThroughAddr;  // 透传
  assign io_out_s3_full_pred_1_fallThroughErr = io_in_bits_resp_in_0_s3_full_pred_1_fallThroughErr;  // 透传
  assign io_out_s3_full_pred_1_multiHit = io_in_bits_resp_in_0_s3_full_pred_1_multiHit;  // 透传
  assign io_out_s3_full_pred_1_is_jal = io_in_bits_resp_in_0_s3_full_pred_1_is_jal;  // 透传
  assign io_out_s3_full_pred_1_is_jalr = io_in_bits_resp_in_0_s3_full_pred_1_is_jalr;  // 透传
  assign io_out_s3_full_pred_1_is_call = io_in_bits_resp_in_0_s3_full_pred_1_is_call;  // 透传
  assign io_out_s3_full_pred_1_is_ret = io_in_bits_resp_in_0_s3_full_pred_1_is_ret;  // 透传
  assign io_out_s3_full_pred_1_last_may_be_rvi_call = io_in_bits_resp_in_0_s3_full_pred_1_last_may_be_rvi_call;  // 透传
  assign io_out_s3_full_pred_1_is_br_sharing = io_in_bits_resp_in_0_s3_full_pred_1_is_br_sharing;  // 透传
  assign io_out_s3_full_pred_1_hit = io_in_bits_resp_in_0_s3_full_pred_1_hit;  // 透传
  assign io_out_s3_full_pred_2_br_taken_mask_0 = io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0;  // 透传
  assign io_out_s3_full_pred_2_br_taken_mask_1 = io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1;  // 透传
  assign io_out_s3_full_pred_2_slot_valids_0 = io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_0;  // 透传
  assign io_out_s3_full_pred_2_slot_valids_1 = io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_1;  // 透传
  assign io_out_s3_full_pred_2_targets_0 = io_in_bits_resp_in_0_s3_full_pred_2_targets_0;  // 透传
  assign io_out_s3_full_pred_2_targets_1 = io_in_bits_resp_in_0_s3_full_pred_2_targets_1;  // 透传
  assign io_out_s3_full_pred_2_jalr_target = s3_target[2];
  assign io_out_s3_full_pred_2_offsets_0 = io_in_bits_resp_in_0_s3_full_pred_2_offsets_0;  // 透传
  assign io_out_s3_full_pred_2_offsets_1 = io_in_bits_resp_in_0_s3_full_pred_2_offsets_1;  // 透传
  assign io_out_s3_full_pred_2_fallThroughAddr = io_in_bits_resp_in_0_s3_full_pred_2_fallThroughAddr;  // 透传
  assign io_out_s3_full_pred_2_fallThroughErr = io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr;  // 透传
  assign io_out_s3_full_pred_2_multiHit = io_in_bits_resp_in_0_s3_full_pred_2_multiHit;  // 透传
  assign io_out_s3_full_pred_2_is_jal = io_in_bits_resp_in_0_s3_full_pred_2_is_jal;  // 透传
  assign io_out_s3_full_pred_2_is_jalr = io_in_bits_resp_in_0_s3_full_pred_2_is_jalr;  // 透传
  assign io_out_s3_full_pred_2_is_call = io_in_bits_resp_in_0_s3_full_pred_2_is_call;  // 透传
  assign io_out_s3_full_pred_2_is_ret = io_in_bits_resp_in_0_s3_full_pred_2_is_ret;  // 透传
  assign io_out_s3_full_pred_2_last_may_be_rvi_call = io_in_bits_resp_in_0_s3_full_pred_2_last_may_be_rvi_call;  // 透传
  assign io_out_s3_full_pred_2_is_br_sharing = io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing;  // 透传
  assign io_out_s3_full_pred_2_hit = io_in_bits_resp_in_0_s3_full_pred_2_hit;  // 透传
  assign io_out_s3_full_pred_3_br_taken_mask_0 = io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0;  // 透传
  assign io_out_s3_full_pred_3_br_taken_mask_1 = io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1;  // 透传
  assign io_out_s3_full_pred_3_slot_valids_0 = io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_0;  // 透传
  assign io_out_s3_full_pred_3_slot_valids_1 = io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_1;  // 透传
  assign io_out_s3_full_pred_3_targets_0 = io_in_bits_resp_in_0_s3_full_pred_3_targets_0;  // 透传
  assign io_out_s3_full_pred_3_targets_1 = io_in_bits_resp_in_0_s3_full_pred_3_targets_1;  // 透传
  assign io_out_s3_full_pred_3_jalr_target = s3_target[3];
  assign io_out_s3_full_pred_3_offsets_0 = io_in_bits_resp_in_0_s3_full_pred_3_offsets_0;  // 透传
  assign io_out_s3_full_pred_3_offsets_1 = io_in_bits_resp_in_0_s3_full_pred_3_offsets_1;  // 透传
  assign io_out_s3_full_pred_3_fallThroughAddr = io_in_bits_resp_in_0_s3_full_pred_3_fallThroughAddr;  // 透传
  assign io_out_s3_full_pred_3_fallThroughErr = io_in_bits_resp_in_0_s3_full_pred_3_fallThroughErr;  // 透传
  assign io_out_s3_full_pred_3_multiHit = io_in_bits_resp_in_0_s3_full_pred_3_multiHit;  // 透传
  assign io_out_s3_full_pred_3_is_jal = io_in_bits_resp_in_0_s3_full_pred_3_is_jal;  // 透传
  assign io_out_s3_full_pred_3_is_jalr = io_in_bits_resp_in_0_s3_full_pred_3_is_jalr;  // 透传
  assign io_out_s3_full_pred_3_is_call = io_in_bits_resp_in_0_s3_full_pred_3_is_call;  // 透传
  assign io_out_s3_full_pred_3_is_ret = io_in_bits_resp_in_0_s3_full_pred_3_is_ret;  // 透传
  assign io_out_s3_full_pred_3_last_may_be_rvi_call = io_in_bits_resp_in_0_s3_full_pred_3_last_may_be_rvi_call;  // 透传
  assign io_out_s3_full_pred_3_is_br_sharing = io_in_bits_resp_in_0_s3_full_pred_3_is_br_sharing;  // 透传
  assign io_out_s3_full_pred_3_hit = io_in_bits_resp_in_0_s3_full_pred_3_hit;  // 透传
  assign io_out_last_stage_spec_info_sc_disagree_0 = io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0;  // 透传
  assign io_out_last_stage_spec_info_sc_disagree_1 = io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1;  // 透传
  assign io_out_last_stage_ftb_entry_isCall = io_in_bits_resp_in_0_last_stage_ftb_entry_isCall;  // 透传
  assign io_out_last_stage_ftb_entry_isRet = io_in_bits_resp_in_0_last_stage_ftb_entry_isRet;  // 透传
  assign io_out_last_stage_ftb_entry_isJalr = io_in_bits_resp_in_0_last_stage_ftb_entry_isJalr;  // 透传
  assign io_out_last_stage_ftb_entry_valid = io_in_bits_resp_in_0_last_stage_ftb_entry_valid;  // 透传
  assign io_out_last_stage_ftb_entry_brSlots_0_offset = io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_offset;  // 透传
  assign io_out_last_stage_ftb_entry_brSlots_0_sharing = io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_sharing;  // 透传
  assign io_out_last_stage_ftb_entry_brSlots_0_valid = io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_valid;  // 透传
  assign io_out_last_stage_ftb_entry_brSlots_0_lower = io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_lower;  // 透传
  assign io_out_last_stage_ftb_entry_brSlots_0_tarStat = io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_tarStat;  // 透传
  assign io_out_last_stage_ftb_entry_tailSlot_offset = io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_offset;  // 透传
  assign io_out_last_stage_ftb_entry_tailSlot_sharing = io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_sharing;  // 透传
  assign io_out_last_stage_ftb_entry_tailSlot_valid = io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_valid;  // 透传
  assign io_out_last_stage_ftb_entry_tailSlot_lower = io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_lower;  // 透传
  assign io_out_last_stage_ftb_entry_tailSlot_tarStat = io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_tarStat;  // 透传
  assign io_out_last_stage_ftb_entry_pftAddr = io_in_bits_resp_in_0_last_stage_ftb_entry_pftAddr;  // 透传
  assign io_out_last_stage_ftb_entry_carry = io_in_bits_resp_in_0_last_stage_ftb_entry_carry;  // 透传
  assign io_out_last_stage_ftb_entry_last_may_be_rvi_call = io_in_bits_resp_in_0_last_stage_ftb_entry_last_may_be_rvi_call;  // 透传
  assign io_out_last_stage_ftb_entry_strong_bias_0 = io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_0;  // 透传
  assign io_out_last_stage_ftb_entry_strong_bias_1 = io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_1;  // 透传

endmodule
// END GENERATED(bpu-wrapper)
