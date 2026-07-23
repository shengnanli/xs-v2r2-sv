// =============================================================================
// xs_ITTage_core —— ITTAGE 间接跳转目标预测器「顶层」核
//
// 对应 Chisel: xiangshan.frontend.ITTage（ITTage.scala，class ITTage）
//
// 【它在前端 BPU 的位置：把 N 张几何历史标签表组合成一个间接跳转目标预测器】
//   普通 TAGE 预测条件分支「方向」；ITTAGE 预测**间接跳转目标地址**（jalr / 虚函数派发 /
//   switch 跳转表）。同一条间接跳转在不同调用上下文跳到不同目标，必须用全局历史区分。
//   ITTAGE 结构 = N 张带 tag 的几何历史长度标签表（本核例化的 5 张 ITTageTable_*，
//   已单独验证）。N 张表用「几何递增」的全局历史长度各自索引并行查询：
//     - **provider** = 命中且历史最长的表，给出目标；
//     - **altpred**  = 命中且历史次长的表（provider 的「备胎」）；
//     - provider 置信(ctr)足够高就信 provider，否则回退 altpred；都不命中回退 s2 输入目标。
//   本核不含 SRAM/折叠历史等存储——那些在每张 ITTageTable 内部；本核只做**表间组合**：
//   provider/altpred 选择、目标重建、分配新条目、提交时更新各表的 ctr/useful。
//
// 【三级流水（与 BPU 主流水对齐）】
//   s1：各表收到 req（折叠历史由外层算好，pc 用 s1_pc）→ 表内读 SRAM。
//   s2：各表给出 resp（valid/ctr/u/target_offset）。本核在 s2 组合算：
//         - selectedInfo：从 5 张表的 valid 里挑出最长命中(provider)与次长命中(altpred)；
//         - 目标重建：target_offset(区内偏移) + RegionWays 给的区域基址 → 50 位目标；
//         - 分配槽：在「比 provider 更长 且 useful=0」的表里用 LFSR 随机挑一张待分配。
//       结果（s2_tageTarget 等）在 s2_fire 时寄存进 s3。
//   s3：输出 jalr_target = s3_tageTarget；并把 provider/altpred 元信息打包进 last_stage_meta
//       带去提交侧（更新时回读，决定更新谁、是否分配）。
//
// 【更新（commit）路径——两拍】
//   io_update 当拍：寄存 update 请求 + 解包 meta（取出当年预测的 provider/altProvider/
//                  ctr/target 等快照）→ update_r_* / updateMeta_r_*。
//   下一拍：据 meta 算「更新哪几张表、各表写什么」：
//     - provider 命中且对/错 → 更新 provider 表 ctr（对+错-）；altpred 也按需更新；
//     - provider 预测错 且 无更长可分配的有用表为空 → tickCtr 调节、择机分配新表条目；
//     - useful 老化：tickCtr 饱和(全 1)时给所有表发 reset_u，逐表清 useful。
//   每张表的 update_* 端口由本核算好（correct/alloc/oldCtr/u/target/old_target/...），
//   寄一拍后送进表。RegionWays 负责把 50 位目标的高 30 位「区域基址」压成 4 位 pointer。
//
// 【为什么用 RegionWays（区域基址表）压缩目标】
//   表条目只存 20 位区内 offset + 4 位 pointer + 1 位 usePCRegion，省面积。RegionWays 是
//   16 项的小 CAM：预测时用 pointer 反查 30 位区域基址、提交时用真实目标高位查/写 pointer。
//   usePCRegion=1 表示区域基址直接取「当前 s2_pc 所在区」，连 pointer 都不必查。
//
// 【4 份 dup 的处理】
//   BPU 把同一预测复制成 4 份（dup 0..3）喂给下游不同消费者，各自有独立 fire。s3_tageTarget
//   有 4 个 dup 寄存器，**仅 fire 使能不同**（值都来自同一份 s2_tageTarget 组合）。故本核用
//   长度 4 的数组表达 s1_pc_dup / s3_tageTarget_dup，按各自 fire 使能推进。s2/s3 的其余
//   full_pred 字段对本预测器是**纯旁路**（ITTAGE 只改 jalr_target），原样透传 io_in→io_out。
//
// 【分层：核 vs wrapper】
//   5 张表 / RegionWays / LFSR 都是 firtool 单态化命名的 golden 黑盒；本核把它们的端口
//   全部引出，由 golden 同名 wrapper(`ITTage`) 例化正确命名的子模块并对接。核只含纯组合/
//   时序功能逻辑，最易读；wrapper 是机械端口适配层（生成器产出）。s2/s3 旁路透传与
//   last_stage_* 旁路也在 wrapper 里直连（与本核无关），核只产出 ITTAGE 真正计算的信号。
// =============================================================================
module xs_ITTage_core #(
  parameter int unsigned PC_W     = 50,   // VAddrBits
  parameter int unsigned NUM_TBL  = 5,    // 标签表张数
  parameter int unsigned CTR_W    = 2,    // 置信计数器位宽
  parameter int unsigned OFF_W    = 20,   // target_offset.offset
  parameter int unsigned PTR_W    = 4,    // target_offset.pointer / RegionWays 下标
  parameter int unsigned REGION_W = 30,   // 区域基址位宽（= PC_W - OFF_W）
  parameter int unsigned GHIST_W  = 256,  // 全局历史位宽
  parameter int unsigned META_W   = 516,  // last_stage_meta 位宽
  parameter int unsigned TICK_W   = 8,    // useful 老化 tick 计数器位宽
  parameter int unsigned RV_W     = 48    // reset_vector 位宽
)(
  input  logic                clock,
  input  logic                reset,

  input  logic [RV_W-1:0]     io_reset_vector,

  // ---- s0 取指 PC（4 份 dup）与各级 fire ----
  input  logic [PC_W-1:0]     io_in_s0_pc [4],
  input  logic                io_s0_fire  [4],
  input  logic                io_s1_fire  [4],
  input  logic                io_s2_fire  [4],

  // ---- s1 给各表的 req 控制：是否是间接跳转（由 uftb 命中信息推出）----
  input  logic                io_s1_uftbHit,
  input  logic                io_s1_uftbHasIndirect,
  input  logic                io_s1_ftbCloseReq,

  // ---- s2 输入的回退目标（provider/altpred 都不命中时用 dup3 的 jalr_target）----
  input  logic [PC_W-1:0]     io_in_s2_jalr_target_3,

  // ---- 各级 ready / s3 预测目标输出（4 份 dup）----
  output logic                io_s1_ready,
  output logic [PC_W-1:0]     io_out_s3_jalr_target [4],

  // ---- s3 元信息（打包进 last_stage_meta 低位，高位补 0）----
  output logic [META_W-1:0]   io_out_last_stage_meta,

  // ===========================================================================
  // 更新（commit）输入
  // ===========================================================================
  input  logic                io_update_valid,
  input  logic [PC_W-1:0]     io_update_pc,
  input  logic                io_update_ftb_isRet,
  input  logic                io_update_ftb_isJalr,
  input  logic [PTR_W-1:0]    io_update_ftb_tailSlot_offset,
  input  logic                io_update_ftb_tailSlot_sharing,
  input  logic                io_update_ftb_tailSlot_valid,
  input  logic                io_update_ftb_strong_bias_1,
  input  logic                io_update_cfi_idx_valid,
  input  logic [PTR_W-1:0]    io_update_cfi_idx_bits,
  input  logic                io_update_jmp_taken,
  input  logic                io_update_mispred_mask_2,   // jalr 槽是否预测错
  input  logic [META_W-1:0]   io_update_meta,             // 当年预测打包的 meta
  input  logic [PC_W-1:0]     io_update_full_target,      // commit 的真实目标
  input  logic [GHIST_W-1:0]  io_update_ghist,            // commit 的原始全局历史

  // ===========================================================================
  // 与 wrapper 内 5 张 ITTageTable_* 黑盒对接的端口（数组打平，每张一份）
  // ===========================================================================
  // 各表 req（本核驱动）
  output logic                tbl_req_valid,              // 5 张表共用同一 req_valid
  output logic [PC_W-1:0]     tbl_req_pc,                 // 5 张表共用 s1_pc(dup3)
  input  logic                tbl_req_ready  [NUM_TBL],
  // 各表 resp（s2，黑盒返回）
  input  logic                tbl_resp_valid [NUM_TBL],
  input  logic [CTR_W-1:0]    tbl_resp_ctr   [NUM_TBL],
  input  logic                tbl_resp_u     [NUM_TBL],
  input  logic [OFF_W-1:0]    tbl_resp_off   [NUM_TBL],
  input  logic [PTR_W-1:0]    tbl_resp_ptr   [NUM_TBL],
  input  logic                tbl_resp_usePCRegion [NUM_TBL],
  // 各表 update（本核驱动，已寄存一拍）
  output logic                tbl_upd_valid  [NUM_TBL],
  output logic                tbl_upd_correct[NUM_TBL],
  output logic                tbl_upd_alloc  [NUM_TBL],
  output logic [CTR_W-1:0]    tbl_upd_oldCtr [NUM_TBL],
  output logic                tbl_upd_uValid [NUM_TBL],
  output logic                tbl_upd_u      [NUM_TBL],
  output logic                tbl_upd_reset_u[NUM_TBL],
  output logic [PC_W-1:0]     tbl_upd_pc     [NUM_TBL],
  output logic [GHIST_W-1:0]  tbl_upd_ghist  [NUM_TBL],
  output logic [OFF_W-1:0]    tbl_upd_off    [NUM_TBL],
  output logic [PTR_W-1:0]    tbl_upd_ptr    [NUM_TBL],
  output logic                tbl_upd_usePCRegion [NUM_TBL],
  output logic [OFF_W-1:0]    tbl_upd_old_off [NUM_TBL],
  output logic [PTR_W-1:0]    tbl_upd_old_ptr [NUM_TBL],
  output logic                tbl_upd_old_usePCRegion [NUM_TBL],

  // ===========================================================================
  // 与 wrapper 内 RegionWays 黑盒对接（区域基址表）
  // ===========================================================================
  // 预测读口：各表 pointer 反查得到的命中/区域基址（pointer 由 wrapper 直连各表，
  //   不经本核——保持与 golden 同构的黑盒驱动路径，便于 FM 配对）
  input  logic                rt_resp_hit    [NUM_TBL],
  input  logic [REGION_W-1:0] rt_resp_region [NUM_TBL],
  // 更新读口：用 meta 里的 provider/altProvider 目标高位查 pointer/hit
  output logic [REGION_W-1:0] rt_update_region_0,         // providerTarget 高 30 位
  output logic [REGION_W-1:0] rt_update_region_1,         // altProviderTarget 高 30 位
  input  logic                rt_update_hit_0,
  input  logic                rt_update_hit_1,
  input  logic [PTR_W-1:0]    rt_update_pointer_0,
  input  logic [PTR_W-1:0]    rt_update_pointer_1,
  // 写口：把 commit 真实目标高位写进区域表，拿到分配的 pointer
  output logic                rt_write_valid,
  output logic [REGION_W-1:0] rt_write_region,            // full_target 高 30 位
  input  logic [PTR_W-1:0]    rt_write_pointer,

  // ===========================================================================
  // 与 wrapper 内 MaxPeriodFibonacciLFSR 黑盒对接（分配随机数，取低 5 位）
  // ===========================================================================
  input  logic                lfsr_out [NUM_TBL]
);

  // ===========================================================================
  // 局部参数 / 派生常量
  // ===========================================================================
  localparam int unsigned TIDX_W = 3;             // 表序号位宽（0..4，3 位）
  localparam int unsigned ALLOC_INIT_OFF_W = REGION_W; // 目标高位宽

  // ===========================================================================
  // s1：判定本拍 req 是否是「间接跳转」——只有间接跳转才查 ITTAGE
  //   ~uftbHit & ~ftbCloseReq ：uftb 没命中（可能是没见过的间接跳转）；
  //   | uftbHasIndirect       ：或 uftb 明确说这块里有间接跳转。
  // ===========================================================================
  wire s1_is_indirect = (~io_s1_uftbHit & ~io_s1_ftbCloseReq) | io_s1_uftbHasIndirect;

  // 5 张表共用同一 req：用 dup3 的 s1_pc、dup3 的 s1_fire 作触发（与 golden 一致）
  wire s1_req_fire = io_s1_fire[3] & s1_is_indirect;

  // s1_pc 寄存（s0→s1）：4 份 dup，复位首拍灌 reset_vector
  logic [PC_W-1:0] s1_pc_dup [4];
  logic            reg_reset, reg_reset_d;   // golden REG / REG_1：复位边沿打两拍
  wire [PC_W-1:0]  reset_pc = {{(PC_W-RV_W){1'b0}}, io_reset_vector};

  always_ff @(posedge clock) begin
    reg_reset   <= reset;
    reg_reset_d <= reg_reset & ~reset;
    if (reg_reset_d) begin
      for (int unsigned d = 0; d < 4; d++) s1_pc_dup[d] <= reset_pc;
    end else begin
      for (int unsigned d = 0; d < 4; d++)
        if (io_s0_fire[d]) s1_pc_dup[d] <= io_in_s0_pc[d];
    end
  end

  assign tbl_req_valid = s1_req_fire;
  assign tbl_req_pc    = s1_pc_dup[3];

  // s1_ready = 所有表都 ready（上电完成）
  always_comb begin
    io_s1_ready = 1'b1;
    for (int unsigned t = 0; t < NUM_TBL; t++) io_s1_ready &= tbl_req_ready[t];
  end

  // ===========================================================================
  // s2：provider / altpred 选择
  //   规则：表序号越大 = 历史越长。provider 取「命中的表里序号最大者」，
  //         altpred 取「命中的表里序号次大者」。
  //   golden 用分治的 selectedInfo（先在 {4,3}、{2}、{1,0} 三组里各选，再合并），
  //   这里直接用「从高到低扫描」表达同一选择，更可读，UT/FM 保证等价。
  // ===========================================================================
  // provider：最高命中表
  logic                sel_provided;       // 是否有任一表命中
  logic [TIDX_W-1:0]   sel_provider_idx;   // provider 表序号
  logic [CTR_W-1:0]    sel_provider_ctr;
  logic                sel_provider_u;
  // altpred：次高命中表
  logic                sel_alt_provided;   // 是否有第二张命中
  logic [TIDX_W-1:0]   sel_alt_provider_idx;
  logic [CTR_W-1:0]    sel_alt_provider_ctr;

  // 注：provider/alt 的 ctr/u 不用「array[变量下标]」取（变量下标会触 FMR_ELAB-147），
  // 而在扫描循环里随选中同步赋值——既避免越界索引，又精确复刻 golden 的兜底语义：
  // 无任何命中时 ctr/u 落到表 0 的 resp 值（这些字段此时是 don't-care，但 meta 需逐位等价）。
  always_comb begin
    sel_provided         = 1'b0;
    sel_provider_idx     = '0;
    sel_alt_provided     = 1'b0;
    sel_alt_provider_idx = '0;
    sel_provider_ctr     = tbl_resp_ctr[0];   // 兜底 = 表 0
    sel_provider_u       = tbl_resp_u[0];
    sel_alt_provider_ctr = tbl_resp_ctr[0];
    // 从最长历史(序号大)往短扫；第一张命中作 provider、第二张作 altpred
    for (int t = NUM_TBL - 1; t >= 0; t--) begin
      if (tbl_resp_valid[t]) begin
        if (!sel_provided) begin
          sel_provided     = 1'b1;
          sel_provider_idx = TIDX_W'(t);
          sel_provider_ctr = tbl_resp_ctr[t];
          sel_provider_u   = tbl_resp_u[t];
        end else if (!sel_alt_provided) begin
          sel_alt_provided     = 1'b1;
          sel_alt_provider_idx = TIDX_W'(t);
          sel_alt_provider_ctr = tbl_resp_ctr[t];
        end
      end
    end
  end

  // provider 是否「置信不足」(ctr==0)：是则预测回退到 altpred
  wire provider_null = (sel_provider_ctr == '0);

  // ===========================================================================
  // s2：目标重建——每张表的 target_offset → 50 位绝对目标
  //   高 30 位区域基址 region：
  //     usePCRegion=1 或 RegionWays 未命中 → 用当前 s2_pc 所在区(region_pc)；
  //     否则用 RegionWays 反查到的 region。
  //   低 20 位 = 表给的 offset。
  //   region_pc 取 s2_pc[49:20]（与 golden 的 s2_pc_seg 拼法一致）。
  // ===========================================================================
  // s2_pc：s1_pc 寄一拍。按 golden 的分段布局存储(seg_0=PC[49:24]/seg_1=PC[23:12]/
  // seg_2=PC[11:0]),使 FM 与 golden 的 s2_pc_dup_s2_pc_seg_* 寄存器逐段双射匹配。
  // 功能只读 region = {seg_0, seg_1[11:8]} = PC[49:20];seg_1[7:0]/seg_2 是 golden
  // 调试流水复制位(本核存而不读, 与 golden 同值 → vmucp 双射验证)。dup0 足够:
  // golden 各 dup 重建 region 结果相同, 其余 dup 为 golden-only 调试复制(dead-ref)。
  localparam int unsigned SEG0_W = PC_W - 24;      // 26 = PC[49:24]
  logic [SEG0_W-1:0] s2_pc_seg_0;
  logic [11:0]       s2_pc_seg_1;
  logic [11:0]       s2_pc_seg_2;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s2_pc_seg_0 <= '0;
      s2_pc_seg_1 <= '0;
      s2_pc_seg_2 <= '0;
    end else if (io_s1_fire[0]) begin
      s2_pc_seg_0 <= s1_pc_dup[0][PC_W-1:24];
      s2_pc_seg_1 <= s1_pc_dup[0][23:12];
      s2_pc_seg_2 <= s1_pc_dup[0][11:0];
    end
  end
  wire [REGION_W-1:0] region_pc = {s2_pc_seg_0, s2_pc_seg_1[11:8]};

  // 每张表重建的目标
  logic [PC_W-1:0] region_target [NUM_TBL];
  always_comb begin
    for (int unsigned t = 0; t < NUM_TBL; t++) begin
      logic [REGION_W-1:0] region;
      // RegionWays 命中且不强制用 PC 区 → 用查到的 region；否则用 PC 区
      if (rt_resp_hit[t] & ~tbl_resp_usePCRegion[t])
        region = rt_resp_region[t];
      else
        region = region_pc;
      region_target[t] = {region, tbl_resp_off[t]};
    end
  end

  // provider / altpred 的重建目标——同样用扫描选取（避免变量下标 FMR_ELAB-147）。
  // 无命中兜底到 region_target[0]，与 golden providerCatTarget/altproviderCatTarget 一致。
  logic [PC_W-1:0] provider_target, altprovider_target;
  always_comb begin
    logic got_p, got_a;
    got_p = 1'b0; got_a = 1'b0;
    provider_target    = region_target[0];
    altprovider_target = region_target[0];
    for (int t = NUM_TBL - 1; t >= 0; t--) begin
      if (tbl_resp_valid[t]) begin
        if (!got_p)      begin got_p = 1'b1; provider_target    = region_target[t]; end
        else if (!got_a) begin got_a = 1'b1; altprovider_target = region_target[t]; end
      end
    end
  end

  // s2 最终预测目标：
  //   有 provider 且 ~(provider_null 且 有 altpred) → 用 provider；
  //   有 altpred 且 provider_null                  → 用 altpred；
  //   都没有                                       → 回退 s2 输入目标(dup3)。
  wire [PC_W-1:0] s2_tage_target =
      ( sel_provided & ~(provider_null & sel_alt_provided)) ? provider_target
    : ( sel_alt_provided & provider_null)                   ? altprovider_target
    :                                                         io_in_s2_jalr_target_3;

  // ===========================================================================
  // s2：分配槽选择（alloc）
  //   候选 = 「序号比 provider 大（历史更长）且 当前 resp 既未命中又 useful=0」的表。
  //   allocatableSlots：在 provider 之上的、可被替换的表的 one-hot。
  //   再与 LFSR 随机位相与、取最低有效位，得到本次分配目标表 s2_alloc_idx。
  // ===========================================================================
  // 比 provider 更长的表 mask：provider 之上全 1（若有 provider）。
  // golden: (1<<provider)*2-1 取反风格；这里直接「t > provider」可读表达。
  logic [NUM_TBL-1:0] longer_than_provider;
  always_comb begin
    for (int unsigned t = 0; t < NUM_TBL; t++)
      longer_than_provider[t] =
          sel_provided ? (TIDX_W'(t) > sel_provider_idx) : 1'b1;
  end

  // 可分配 = 更长 且 该表本拍 ~命中 且 ~useful
  logic [NUM_TBL-1:0] allocatable;
  always_comb begin
    for (int unsigned t = 0; t < NUM_TBL; t++)
      allocatable[t] = longer_than_provider[t]
                     & ~tbl_resp_valid[t] & ~tbl_resp_u[t];
  end

  // 与 LFSR 随机位相与，挑「随机优先」的待分配表
  logic [NUM_TBL-1:0] alloc_lfsr_masked;
  always_comb begin
    for (int unsigned t = 0; t < NUM_TBL; t++)
      alloc_lfsr_masked[t] = allocatable[t] & lfsr_out[t];
  end

  // masked 里最低位 → s2_masked_entry；若 masked 全 0 则退回 allocatable 最低位
  function automatic logic [TIDX_W-1:0] lowest_set(input logic [NUM_TBL-1:0] m);
    lowest_set = TIDX_W'(7);   // 全 0 时返回非法 7（与 golden 一致）
    for (int t = NUM_TBL - 1; t >= 0; t--)
      if (m[t]) lowest_set = TIDX_W'(t);
  endfunction

  wire [TIDX_W-1:0] s2_masked_entry = lowest_set(alloc_lfsr_masked);
  // golden: _s2_allocEntry_T = allocatable >> masked_entry，bit0 表示 masked 命中
  wire s2_masked_hit = alloc_lfsr_masked != '0;
  wire [TIDX_W-1:0] s2_alloc_idx =
      s2_masked_hit ? s2_masked_entry : lowest_set(allocatable);
  wire s2_alloc_valid = (allocatable != '0);

  // ===========================================================================
  // s3：把 s2 选择/目标/分配结果寄存（各 dup 用各自 s2_fire 使能）
  // ===========================================================================
  logic [PC_W-1:0]   s3_tage_target_dup [4];
  logic [PC_W-1:0]   s3_provider_target;
  logic [PC_W-1:0]   s3_altprovider_target;
  logic              s3_provided;
  logic [TIDX_W-1:0] s3_provider;
  logic              s3_alt_provided;
  logic [TIDX_W-1:0] s3_alt_provider;
  logic              s3_provider_u;
  logic [CTR_W-1:0]  s3_provider_ctr;
  logic [CTR_W-1:0]  s3_alt_provider_ctr;
  logic              s3_alloc_valid;
  logic [TIDX_W-1:0] s3_alloc_bits;

  always_ff @(posedge clock) begin
    for (int unsigned d = 0; d < 4; d++)
      if (io_s2_fire[d]) s3_tage_target_dup[d] <= s2_tage_target;
    if (io_s2_fire[3]) begin
      s3_provider_target    <= provider_target;
      s3_altprovider_target <= altprovider_target;
      s3_provided           <= sel_provided;
      s3_provider           <= sel_provider_idx;
      s3_alt_provided       <= sel_alt_provided;
      s3_alt_provider       <= sel_alt_provider_idx;
      s3_provider_u         <= sel_provider_u;
      s3_provider_ctr       <= sel_provider_ctr;
      s3_alt_provider_ctr   <= sel_alt_provider_ctr;
      s3_alloc_valid        <= s2_alloc_valid;
      s3_alloc_bits         <= s2_alloc_idx;
    end
  end

  // pred_cycle 计数器（仅作 meta 里的调试戳，自由计数）
  logic [63:0] resp_meta_pred_cycle;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) resp_meta_pred_cycle <= '0;
    else       resp_meta_pred_cycle <= resp_meta_pred_cycle + 64'h1;
  end

  // s3 输出目标
  always_comb begin
    for (int unsigned d = 0; d < 4; d++) io_out_s3_jalr_target[d] = s3_tage_target_dup[d];
  end

  // altDiffers：provider 与 altpred 目标是否不同（更新时判 useful 用）
  wire s3_alt_differs = (s3_provider_target != s3_altprovider_target);

  // last_stage_meta 打包（高位补 0，与 golden 位序完全一致）
  always_comb begin
    io_out_last_stage_meta = '0;
    io_out_last_stage_meta[181]     = s3_provided;
    io_out_last_stage_meta[180:178] = s3_provider;
    io_out_last_stage_meta[177]     = s3_alt_provided;
    io_out_last_stage_meta[176:174] = s3_alt_provider;
    io_out_last_stage_meta[173]     = s3_alt_differs;
    io_out_last_stage_meta[172]     = s3_provider_u;
    io_out_last_stage_meta[171:170] = s3_provider_ctr;
    io_out_last_stage_meta[169:168] = s3_alt_provider_ctr;
    io_out_last_stage_meta[167]     = s3_alloc_valid;
    io_out_last_stage_meta[166:164] = s3_alloc_bits;
    io_out_last_stage_meta[163:114] = s3_provider_target;
    io_out_last_stage_meta[113:64]  = s3_altprovider_target;
    io_out_last_stage_meta[63:0]    = resp_meta_pred_cycle;
  end

  // ===========================================================================
  // 更新（commit）路径——第 1 拍：寄存 update 请求 + 解包 meta
  // ===========================================================================
  // update 请求寄存（io_update_valid 当拍打入）
  logic [PC_W-1:0]   upd_pc;
  logic              upd_ftb_isRet, upd_ftb_isJalr;
  logic [PTR_W-1:0]  upd_ftb_tailSlot_offset;
  logic              upd_ftb_tailSlot_sharing, upd_ftb_tailSlot_valid;
  logic              upd_ftb_strong_bias_1;
  logic              upd_cfi_idx_valid, upd_jmp_taken, upd_mispred;
  logic [PC_W-1:0]   upd_full_target;
  logic [GHIST_W-1:0]upd_ghist;
  logic [PTR_W-1:0]  upd_cfi_idx_bits;
  // meta 解包寄存（当年预测快照）
  logic              um_provider_valid, um_alt_provider_valid, um_alt_differs, um_provider_u;
  logic [CTR_W-1:0]  um_provider_ctr, um_alt_provider_ctr;
  logic              um_allocate_valid;
  logic [TIDX_W-1:0] um_provider_bits, um_allocate_bits, um_alt_provider_bits;
  logic [PC_W-1:0]   um_provider_target, um_alt_provider_target;
  // u_valid：io_update_valid 打一拍（更新有效需上一拍 update 真有效）
  logic              u_valid;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      u_valid <= 1'b0;
    end else begin
      u_valid <= io_update_valid;
    end
  end

  always_ff @(posedge clock) begin
    if (io_update_valid) begin
      upd_pc                   <= io_update_pc;
      upd_ftb_isRet            <= io_update_ftb_isRet;
      upd_ftb_isJalr           <= io_update_ftb_isJalr;
      upd_ftb_tailSlot_offset  <= io_update_ftb_tailSlot_offset;
      upd_ftb_tailSlot_sharing <= io_update_ftb_tailSlot_sharing;
      upd_ftb_tailSlot_valid   <= io_update_ftb_tailSlot_valid;
      upd_ftb_strong_bias_1    <= io_update_ftb_strong_bias_1;
      upd_cfi_idx_valid        <= io_update_cfi_idx_valid;
      upd_jmp_taken            <= io_update_jmp_taken;
      upd_mispred              <= io_update_mispred_mask_2;
      upd_full_target          <= io_update_full_target;
      upd_ghist                <= io_update_ghist;
      um_provider_valid        <= io_update_meta[181];
      um_alt_provider_valid    <= io_update_meta[177];
      um_alt_differs           <= io_update_meta[173];
      um_provider_u            <= io_update_meta[172];
      um_provider_ctr          <= io_update_meta[171:170];
      um_alt_provider_ctr      <= io_update_meta[169:168];
      um_allocate_valid        <= io_update_meta[167];
    end
    // provider_bits / providerTarget：io_update_valid & meta[181]（provider_valid）才更新
    if (io_update_valid & io_update_meta[181]) begin
      um_provider_bits   <= io_update_meta[180:178];
      um_provider_target <= io_update_meta[163:114];
    end
    if (io_update_valid & io_update_meta[167])
      um_allocate_bits <= io_update_meta[166:164];
    if (io_update_valid & io_update_meta[177])
      um_alt_provider_bits <= io_update_meta[176:174];
    // altProviderTarget：provider_valid & altProvider_valid & providerCtr==0 才更新
    if (io_update_valid & io_update_meta[181] & io_update_meta[177]
        & (io_update_meta[171:170] == 2'h0))
      um_alt_provider_target <= io_update_meta[113:64];
    if (io_update_valid & io_update_cfi_idx_valid)
      upd_cfi_idx_bits <= io_update_cfi_idx_bits;
  end

  // ===========================================================================
  // 更新路径——本次 commit 是否真的要更新 ITTAGE（updateValid）
  //   条件：tailSlot 是有效 jalr（非 ret、非 sharing）、本块确实跳了、cfi 命中 jalr 槽、
  //         非强偏置（强偏置由别的预测器主管）。
  // ===========================================================================
  wire update_valid =
       upd_ftb_tailSlot_valid & upd_ftb_isJalr
     & ~(upd_ftb_tailSlot_valid & upd_ftb_isRet) & u_valid
     & ~upd_ftb_tailSlot_sharing & upd_jmp_taken & upd_cfi_idx_valid
     & (upd_cfi_idx_bits == upd_ftb_tailSlot_offset)
     & ~upd_ftb_strong_bias_1;

  // 提交侧的「用 provider / altpred」判定（与预测侧同构，但用 meta 快照）
  wire commit_use_provider     = um_provider_valid & (um_provider_ctr != '0);
  wire commit_use_altpred      = um_provider_valid & (um_provider_ctr == '0);
  wire commit_use_ht_as_altpred= commit_use_altpred & um_alt_provider_valid;

  // provider 预测目标是否猜对（与真实目标比）
  wire update_provider_correct = (um_provider_target == upd_full_target);
  // 真实目标是否落在当前 PC 区（usePCRegion）
  wire update_real_use_pc_region = (upd_full_target[PC_W-1:OFF_W] == upd_pc[PC_W-1:OFF_W]);

  // ===========================================================================
  // 分配决策（commit 侧）
  //   仅在 provider 预测错（且不是「provider 命中真目标但 ctr 已饱和到 0」这种情形）时，
  //   才考虑分配；并且要 meta 当年记录了 allocate_valid（s2 找到过可分配槽）。
  //   alloc_to[t] = 分配给第 t 张表（allocate_bits 指向 t）。
  // ===========================================================================
  // provider 命中真目标 且 ctr==0：屡试不爽的旧目标已耗尽置信，按「需重训」处理，不算可省
  wire provider_hit_target_satlow =
       um_provider_valid & (um_provider_target == upd_full_target) & (um_provider_ctr == '0);
  // 需要更新（misprediction 触发的训练）：跳了、预测错、且不是上面那种已耗尽情形
  wire need_train = update_valid & upd_mispred & ~provider_hit_target_satlow;
  wire do_alloc   = need_train & um_allocate_valid;

  logic [NUM_TBL-1:0] alloc_to;
  always_comb begin
    for (int unsigned t = 0; t < NUM_TBL; t++)
      alloc_to[t] = do_alloc & (um_allocate_bits == TIDX_W'(t));
  end

  // ===========================================================================
  // 各表「是否被本次 commit 触及」的写掩码 updateMask[t]
  //   两种来源：
  //     (a) 被分配：alloc_to[t]；
  //     (b) 作为 provider 或 altpred 被更新：
  //         - provider 表（um_provider_bits==t）在 commit_use_provider 时更新；
  //         - altpred 表（um_alt_provider_bits==t）在「provider ctr==0 且 altProvider 有效」
  //           的 mispred 情形下更新。
  //   golden 用 _GEN_2/_GEN_3 等表达，这里逐表用可读布尔。
  // ===========================================================================
  // _GEN_3：本次确要更新 且 provider 有效
  wire upd_prov = update_valid & um_provider_valid;
  // _GEN_2：altpred 有效 且 provider ctr==0 且 mispred —— 触发 altpred 表更新
  wire upd_alt  = um_alt_provider_valid & (um_provider_ctr == '0) & upd_mispred;

  logic [NUM_TBL-1:0] update_mask;
  always_comb begin
    for (int unsigned t = 0; t < NUM_TBL; t++) begin
      logic is_provider, is_altpred;
      is_provider = (um_provider_bits     == TIDX_W'(t));
      is_altpred  = (um_alt_provider_bits == TIDX_W'(t));
      update_mask[t] = alloc_to[t]
                     | (upd_prov & (is_provider | (upd_alt & is_altpred)));
    end
  end

  // ===========================================================================
  // useful 更新值 _updateU_T_2：
  //   provider 与 altpred 目标不同(um_alt_differs) → useful = provider 是否猜对；
  //   否则保留旧 useful(um_provider_u)。（"纠正了 altpred 的错"才算有用）
  // ===========================================================================
  wire update_u_value = um_alt_differs ? update_provider_correct : um_provider_u;

  // ===========================================================================
  // RegionWays 更新/写口驱动
  //   写：真实目标不在 PC 区(~usePCRegion) 且 本次有分配 → 把目标高位写进区域表。
  //   读：provider/altProvider 目标高位查 pointer/hit（更新各表 old_target 用）。
  // ===========================================================================
  assign rt_update_region_0 = um_provider_target[PC_W-1:OFF_W];
  assign rt_update_region_1 = um_alt_provider_target[PC_W-1:OFF_W];
  assign rt_write_region    = upd_full_target[PC_W-1:OFF_W];
  assign rt_write_valid     = ~update_real_use_pc_region & (alloc_to != '0);

  // 写进表的 usePCRegion：真实目标落在 PC 区，或本次没有分配（没写区域表）
  wire update_real_use_pc_region_out = update_real_use_pc_region | (alloc_to == '0);

  // ===========================================================================
  // 各表 update_* 端口的「下一拍寄存」值计算
  //   对每张表 t：若它是 provider，则 oldCtr/old_target 取 providerMeta；否则取 altMeta。
  //   golden 对 table0 特判 (|provider_bits)==0（即 provider 是表 0）；其余表用
  //   provider_bits==t。统一逻辑：is_provider_t 决定取 provider 还是 alt 的快照。
  // ===========================================================================
  // 每张表寄存前的组合候选（next 值），随后在 always_ff 里按 update_mask 选择性打入
  logic              n_correct [NUM_TBL];
  logic              n_alloc   [NUM_TBL];
  logic [CTR_W-1:0]  n_oldCtr  [NUM_TBL];
  logic [OFF_W-1:0]  n_off     [NUM_TBL];
  logic [PTR_W-1:0]  n_ptr     [NUM_TBL];
  logic              n_usePCRegion [NUM_TBL];
  logic [OFF_W-1:0]  n_old_off [NUM_TBL];
  logic [PTR_W-1:0]  n_old_ptr [NUM_TBL];
  logic              n_old_usePCRegion [NUM_TBL];
  logic              n_u       [NUM_TBL];
  logic              n_uValid  [NUM_TBL];

  always_comb begin
    for (int unsigned t = 0; t < NUM_TBL; t++) begin
      logic is_provider_t;   // 这张表当年是 provider 吗
      is_provider_t = (um_provider_bits == TIDX_W'(t));
      // correct：仅当本表是 provider 时，用 provider 是否猜对；否则该表当 altpred 训练，correct=0
      n_correct[t] = is_provider_t & update_provider_correct;
      n_alloc[t]   = alloc_to[t];
      // oldCtr：provider 表用 providerCtr；altpred 表用 altProviderCtr
      n_oldCtr[t]  = is_provider_t ? um_provider_ctr : um_alt_provider_ctr;
      // 新目标：commit 真实目标低 20 位 + RegionWays 写回 pointer + usePCRegion
      n_off[t]         = upd_full_target[OFF_W-1:0];
      n_ptr[t]         = rt_write_pointer;
      n_usePCRegion[t] = update_real_use_pc_region_out;
      // 旧目标（保留用）：provider 表用 providerTarget/查 pointer_0/hit_0；
      //                   altpred 表用 altProviderTarget/pointer_1/hit_1
      n_old_off[t] = is_provider_t ? um_provider_target[OFF_W-1:0]
                                   : um_alt_provider_target[OFF_W-1:0];
      n_old_ptr[t] = is_provider_t ? rt_update_pointer_0 : rt_update_pointer_1;
      n_old_usePCRegion[t] = is_provider_t ? ~rt_update_hit_0 : ~rt_update_hit_1;
      // useful 写值：被分配时不写 useful（u=0 由 uValid 控制），否则写 update_u_value
      n_u[t]      = ~alloc_to[t] & update_u_value;
      // uValid：被分配 或 (本表是 provider 且本次 upd_prov)
      n_uValid[t] = alloc_to[t] | (upd_prov & is_provider_t);
    end
  end

  // ===========================================================================
  // useful 老化 tick 计数器（与 golden tickCtr 同语义）
  //   每次 need_train：有可分配槽(allocate_valid) → tick 递减（说明表还有空位，少老化）；
  //                    无可分配槽               → tick 递增（表满了，催促老化）。
  //   tick 饱和(全 1) → 下拍给所有表发 reset_u，并清零 tick。
  // ===========================================================================
  logic [TICK_W-1:0] tick_ctr;
  wire tick_sat = &tick_ctr;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      tick_ctr <= '0;
    end else begin
      if (tick_sat)
        tick_ctr <= '0;
      else if (need_train) begin
        if (tick_sat & ~um_allocate_valid)        tick_ctr <= '1;
        else if ((tick_ctr == '0) & um_allocate_valid) tick_ctr <= '0;
        else if (um_allocate_valid)               tick_ctr <= tick_ctr - 1'b1;
        else                                      tick_ctr <= tick_ctr + 1'b1;
      end
    end
  end

  // ===========================================================================
  // 各表 update_* 端口寄存（下一拍送进表）
  //   valid/reset_u/uValid 在带复位的 always_ff 里（需复位清 0）；
  //   其余数据端口在无复位 always_ff（仅 update_mask 命中时打入，省翻转）。
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int unsigned t = 0; t < NUM_TBL; t++) begin
        tbl_upd_valid[t]   <= 1'b0;
        tbl_upd_reset_u[t] <= 1'b0;
        tbl_upd_uValid[t]  <= 1'b0;
      end
    end else begin
      for (int unsigned t = 0; t < NUM_TBL; t++) begin
        tbl_upd_valid[t]   <= update_mask[t];
        tbl_upd_reset_u[t] <= tick_sat;
        if (update_mask[t]) tbl_upd_uValid[t] <= n_uValid[t];
      end
    end
  end

  always_ff @(posedge clock) begin
    for (int unsigned t = 0; t < NUM_TBL; t++) begin
      if (update_mask[t]) begin
        tbl_upd_correct[t]         <= n_correct[t];
        tbl_upd_alloc[t]           <= n_alloc[t];
        tbl_upd_oldCtr[t]          <= n_oldCtr[t];
        tbl_upd_off[t]             <= n_off[t];
        tbl_upd_ptr[t]             <= n_ptr[t];
        tbl_upd_usePCRegion[t]     <= n_usePCRegion[t];
        tbl_upd_old_off[t]         <= n_old_off[t];
        tbl_upd_old_ptr[t]         <= n_old_ptr[t];
        tbl_upd_old_usePCRegion[t] <= n_old_usePCRegion[t];
        tbl_upd_u[t]               <= n_u[t];
        tbl_upd_pc[t]              <= io_update_pc;
        tbl_upd_ghist[t]           <= upd_ghist;
      end
    end
  end

endmodule
