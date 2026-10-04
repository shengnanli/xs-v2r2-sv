// =============================================================================
// Tage_SC.sv —— TAGE-SC：BPU 的主方向预测器（TAGE + 统计校正器 SC）
//
// 【在 BPU 里的位置】Composer 菊花链 2/5（链头 uFTB 之后）。每个取指块最多两条条件分支
//   （两个"槽" br=0/1），本模块给出每个槽的跳/不跳：S2 给 TAGE 的方向（覆盖 uFTB 的 S1 方向），
//   S3 给 SC 校正后的方向；其余预测字段原样透传。
//   （Chisel：src/main/scala/xiangshan/frontend/Tage.scala class Tage + SC.scala trait HasSC）
//
// 【TAGE 部分】4 张带标签的 TageTable（历史长度递增，已签核子模块）+ 1 张无标签的基础表
//   TageBTable（2 位计数器，已签核）。S0 发查表，S1 拿到各表结果：
//   · provider = 命中的表里历史最长的那张；没有命中时 provider 字段取第 0 张表的那份（照搬）。
//   · provider 计数器"不自信"（ctr = 3 或 4）且 useAltOnNa 计数器高位为 1 时改用 alt 预测
//     （= 基础表；基础表本拍无效时用 uFTB 的 S1 方向）。useAltOnNa 是按 pc[7:1] 索引的
//     2×128 个 4 位饱和计数器，学"不自信时用 alt 是否更准"。
//   · S2 输出 = tage_enable ? TAGE 方向 : 0（golden 的 resp_in 里没有 S2 方向这一路输入）。
//
// 【SC 部分】4 张 SCTable（本 lane 已签）给每个槽、每个"TAGE 预测方向"各一个 6 位有符号计数器。
//   S1 把 4 张表的居中值（2c+1）相加，S2 再加上 provider 计数器的居中值 (2(ctr-4)+1)*8：
//   · 只有 TAGE 有 provider 且 |SC 和| 超过阈值（每槽一个自适应阈值 scThresholds）时，
//     才用 SC 的符号推翻 TAGE；S3 输出 = sc_enable ? 该结果 : 0。
//
// 【更新（提交时）】update 锁存一拍后：
//   · TAGE：provider 表更新计数器 / u；预测错且需要时在比 provider 历史长的表里分配
//     （LFSR 随机挑一张可分配的），并维护每槽的 tick 计数（分配失败多于成功就涨，涨满清零 + reset_u）。
//   · 基础表：用了 alt 预测的那次更新基础表。
//   · useAltOnNa：provider 不自信且 alt 与 provider 方向不同时，按 alt 对错饱和 ±1。
//   · SC：SC 预测错或不过阈值时更新 4 张表；阈值在"推翻了但和接近阈值"时自适应。
//   每张表的 update 口都再打一拍（RegNext / RegEnable）送出。
//   ★Chisel 里赋 DontCare 的字段按 golden（firtool）实际取值照抄★（见 §8）。
//
// 【perf 寄存器初值（bug-for-bug，勿"顺手"加复位）】s2_provideds / s2_providers / s2_providerResps 等
//   S2 寄存器只在 s1_fire 时更新、没有复位，上电值来自 RANDOMIZE_REG_INIT；perf 计数用到它们时
//   初值伪差即来源于此（tage-initmem lane 已查明，记录在该 lane 的工作树里，未合入本仓）。重写件与 golden 一样不复位。
//
// 复位域（与 golden 一致）：公共外壳 modified_reset / s2·s3 段 PC、bankTickCtrs / DistanceToTops、
//   useAltOnNaCtrs（复位 8）、u_valid、pred_cycle（GTimer）、scThresholds（ctr=16, thres=6）异步复位；
//   其余全部无复位。
//
// 本文件：package tage_sc_pkg + 可读核 xs_Tage_SC_core + golden 同名 wrapper Tage_SC。
// wrapper 的端口表、子模块（tables_0..3 / bt / mbistPl / allocLFSR_prng{,_1} / scTables_0..3，
// 实例名同 golden）、MBIST 子链连线与透传赋值由 scripts/gen_bpu_wrappers.py 从 G1 golden 生成。
// =============================================================================
// 本文件导航（共 2518 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L21    在 BPU 里的位置】Composer 菊花链 2/5
//   L26    TAGE 部分】4 张带标签的 TageTable
//   L34    SC 部分】4 张 SCTable
//   L39    更新
//   L48    perf 寄存器初值
//   L260   §0 BPU 公共外壳：各级 PC
//   L291   §1 S1：TAGE provider 选择、alt 判定、S1 方向；SC 的 S1 和
//   L342   §2 S2：TAGE 结果打拍
//   L380   §3 SC 预测：S1 和打拍
//   L421   §4 S3：SC 方向与 meta 打拍
//   L464   §5 更新：锁存一拍
//   L517   §6 TAGE 更新：每槽算 provider 更新、useAltOnNa、分配、tick
//   L637   §7 SC 更新：阈值自适应、决定是否更新 SC 表
//   L692   §8 各表的 update 口：再打一拍送出
//   L753   §9 perf：provider 命中数 / SC 因预测错更新数 / SC 因不自信更新数
//
package tage_sc_pkg;

  localparam int unsigned NUM_BR      = 2;
  localparam int unsigned NUM_TABLES  = 4;     // TageNTables
  localparam int unsigned TBL_IDX_W   = 2;
  localparam int unsigned NUM_SC      = 4;     // SCNTables
  localparam int unsigned NUM_DUP     = 4;
  localparam int unsigned PC_W        = 50;
  localparam int unsigned META_W      = 516;
  localparam int unsigned TAGE_META_W = 144;
  localparam int unsigned NUM_ALT     = 128;   // NUM_USE_ALT_ON_NA
  localparam int unsigned TICK_W      = 7;

  typedef struct packed {
    logic       valid;
    logic [2:0] ctr;
    logic       u;
    logic       unconf;
  } tage_resp_t;

  // 一张 TageTable 的 update 口（pc / ghist 单列成核的独立输出，见 §8）
  typedef struct packed {
    logic [NUM_BR-1:0]           mask;
    logic [NUM_BR-1:0]           takens;
    logic [NUM_BR-1:0]           alloc;
    logic [NUM_BR-1:0][2:0]      old_ctrs;
    logic [NUM_BR-1:0]           u_mask;
    logic [NUM_BR-1:0]           us;
    logic [NUM_BR-1:0]           reset_u;
  } tage_upd_t;

  // TageBTable 的 update 口（pc 单列）
  typedef struct packed {
    logic [NUM_BR-1:0]           mask;
    logic [NUM_BR-1:0][1:0]      cnt;
    logic [NUM_BR-1:0]           takens;
  } bt_upd_t;

  // 一张 SCTable 的 update 口（pc / ghist 单列）
  typedef struct packed {
    logic [NUM_BR-1:0]           mask;
    logic [NUM_BR-1:0]           tage_preds;
    logic [NUM_BR-1:0]           takens;
    logic [NUM_BR-1:0][5:0]      old_ctrs;
  } sc_upd_t;

  // TageMeta（asUInt 布局：先声明的字段在高位；Vec 的 [1] 在 [0] 之上）
  typedef struct packed {
    logic [NUM_BR-1:0][2:0]                provider;        // 每槽 {valid, bits[1:0]}
    logic [NUM_BR-1:0][3:0]                provider_resp;   // 每槽 {ctr[2:0], u}
    logic [NUM_BR-1:0]                     alt_used;
    logic [NUM_BR-1:0][1:0]                basecnt;
    logic [NUM_BR-1:0][NUM_TABLES-1:0]     allocates;
    logic [NUM_BR-1:0]                     sc_preds;
    logic [NUM_BR-1:0][NUM_SC-1:0][5:0]    sc_ctrs;
    logic [63:0]                           pred_cycle;
    logic [NUM_BR-1:0]                     use_alt_on_na;
  } tage_meta_t;

  // ---- 饱和计数器 ----
  function automatic logic [3:0] sat4_update(input logic [3:0] old, input logic up);
    if (old == 4'hF && up)        return 4'hF;
    else if (old == 4'h0 && !up)  return 4'h0;
    else if (up)                  return old + 4'd1;
    else                          return old - 4'd1;
  endfunction

  function automatic logic [4:0] sat5_update(input logic [4:0] old, input logic up);
    if (old == 5'h1F && up)       return 5'h1F;
    else if (old == 5'h00 && !up) return 5'h00;
    else if (up)                  return old + 5'd1;
    else                          return old - 5'd1;
  endfunction

  // TAGE provider 计数器的居中值 (2(ctr-4)+1)*8 = Cat(ctr ^ 4, 1, 000)，7 位有符号
  function automatic logic signed [6:0] pvdr_centered(input logic [2:0] ctr);
    return {ctr ^ 3'b100, 4'b1000};
  endfunction

  // SC 计数器居中值 2c+1，7 位有符号
  function automatic logic signed [6:0] sc_centered(input logic [5:0] c);
    return {c, 1'b1};
  endfunction

  // 4 张 SC 表居中值之和（ParallelSingedExpandingAdd：两两 +& 扩位，7->8->9 位）
  function automatic logic signed [8:0] sc_sum4(input logic [5:0] c0, input logic [5:0] c1,
                                                input logic [5:0] c2, input logic [5:0] c3);
    logic signed [6:0] e0, e1, e2, e3;
    logic signed [7:0] s01, s23;
    e0  = sc_centered(c0);
    e1  = sc_centered(c1);
    e2  = sc_centered(c2);
    e3  = sc_centered(c3);
    s01 = 8'(e0) + 8'(e1);
    s23 = 8'(e2) + 8'(e3);
    return 9'(s01) + 9'(s23);
  endfunction

  // aboveThreshold（S2 版，阈值 = thres 本身，9 位运算）：
  //   (sum > thres - pvdr 且 sum+pvdr >= 0) 或 (sum < -thres - pvdr 且 sum+pvdr < 0)
  function automatic logic above_thres_s2(input logic signed [8:0] sum, input logic [2:0] pvdr_ctr,
                                          input logic [7:0] thres);
    logic signed [8:0] pvdr9, thr9, hi_bound, lo_bound;
    logic signed [9:0] total;
    pvdr9    = 9'(signed'(pvdr_centered(pvdr_ctr)));
    thr9     = {1'b0, thres};
    hi_bound = thr9 - pvdr9;
    lo_bound = 9'(9'(0) - thr9) - pvdr9;
    total    = 10'(signed'(sum)) + 10'(signed'(pvdr_centered(pvdr_ctr)));
    return ((sum > hi_bound) && !total[9]) || ((sum < lo_bound) && total[9]);
  endfunction

  // aboveThreshold（更新版，阈值 = (thres << 3) + 21，13 位运算）
  function automatic logic above_thres_upd(input logic signed [8:0] sum, input logic [2:0] pvdr_ctr,
                                           input logic [7:0] thres);
    logic signed [12:0] pvdr13, thr13, sum13, hi_bound, lo_bound;
    logic signed [9:0]  total;
    pvdr13   = 13'(signed'(pvdr_centered(pvdr_ctr)));
    thr13    = {1'b0, 12'({1'b0, thres, 3'b000} + 12'd21)};
    sum13    = 13'(sum);
    hi_bound = thr13 - pvdr13;
    lo_bound = 13'(13'(0) - thr13) - pvdr13;
    total    = 10'(sum) + 10'(signed'(pvdr_centered(pvdr_ctr)));
    return ((sum13 > hi_bound) && !total[9]) || ((sum13 < lo_bound) && total[9]);
  endfunction

  // LowerMask(UIntToOH(idx), 4)：idx 及以下各位
  function automatic logic [NUM_TABLES-1:0] lower_mask_of(input logic [TBL_IDX_W-1:0] idx);
    logic [NUM_TABLES-1:0] oh, acc;
    oh  = NUM_TABLES'(1) << idx;
    acc = '0;
    for (int i = 0; i < NUM_TABLES; i++) acc |= oh >> i;
    return acc;
  endfunction

  // PriorityEncoder（4 位，全 0 时为 3）
  function automatic logic [TBL_IDX_W-1:0] prio_enc4(input logic [NUM_TABLES-1:0] x);
    for (int i = 0; i < NUM_TABLES - 1; i++)
      if (x[i]) return TBL_IDX_W'(i);
    return TBL_IDX_W'(NUM_TABLES - 1);
  endfunction

  function automatic logic [2:0] popcount4(input logic [3:0] x);
    return 3'(x[0]) + 3'(x[1]) + 3'(x[2]) + 3'(x[3]);
  endfunction

endpackage

module xs_Tage_SC_core
  import tage_sc_pkg::*;
(
  input  logic                  clock,
  input  logic                  reset,
  input  logic [47:0]           reset_vector,
  input  logic [PC_W-1:0]       s0_pc    [NUM_DUP],
  input  logic                  s0_fire  [NUM_DUP],
  input  logic                  s1_fire  [NUM_DUP],
  input  logic                  s2_fire  [NUM_DUP],
  input  logic                  tage_enable,
  input  logic                  sc_enable,
  input  logic [NUM_BR-1:0]     s1_uftb_taken,          // uFTB 在 S1 给的方向（resp_in s1 dup 0）
  // ---- 4 张 TageTable + 基础表 ----
  input  logic                  tbl_req_ready [NUM_TABLES],
  input  tage_resp_t            tbl_resp      [NUM_TABLES][NUM_BR],
  output tage_upd_t             tbl_upd       [NUM_TABLES],
  output logic [PC_W-1:0]       tbl_upd_pc    [NUM_TABLES],
  output logic [255:0]          tbl_upd_ghist [NUM_TABLES],
  input  logic                  bt_req_ready,
  input  logic [1:0]            bt_s1_cnt     [NUM_BR],
  input  logic                  bt_s1_resp_valid,
  output bt_upd_t               bt_upd,
  output logic [PC_W-1:0]       bt_upd_pc,
  // ---- 4 张 SCTable ----
  input  logic [5:0]            sc_resp       [NUM_SC][NUM_BR][2],   // [表][槽][TAGE 方向]
  output sc_upd_t               sc_upd        [NUM_SC],
  output logic [PC_W-1:0]       sc_upd_pc     [NUM_SC],
  output logic [255:0]          sc_upd_ghist  [1:NUM_SC-1], // 第 0 张 SC 表历史长度 0，没有 ghist 口
  // ---- 分配随机源（两份 LFSR 的低 3 位，每槽一份）----
  input  logic [2:0]            lfsr_bits     [NUM_BR],
  // ---- 更新 ----
  input  logic                  update_valid,
  input  logic [PC_W-1:0]       update_pc,
  input  logic                  update_br0_valid,       // ftb_entry.brSlots(0).valid
  input  logic                  update_tail_sharing,
  input  logic                  update_tail_valid,
  input  logic [NUM_BR-1:0]     update_strong_bias,
  input  logic [NUM_BR-1:0]     update_br_taken,
  input  logic [NUM_BR-1:0]     update_mispred,
  input  logic [META_W-1:0]     update_meta,
  input  logic [255:0]          update_ghist,
  // ---- 输出 ----
  output logic [NUM_BR-1:0]     s2_taken  [NUM_DUP],
  output logic [NUM_BR-1:0]     s3_taken  [NUM_DUP],
  output logic [NUM_BR-1:0]     s3_sc_disagree,
  output logic [META_W-1:0]     last_stage_meta,
  output logic                  s1_ready,
  output logic [1:0]            perf      [3]
);

  // ===========================================================================
  // §0 BPU 公共外壳：各级 PC（本预测器只用 s1 dup 0 的 pc[7:1] 选 useAltOnNa 计数器）
  // ===========================================================================
  logic [PC_W-1:0] s1_pc [NUM_DUP];
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

  always_comb begin
    s1_ready = bt_req_ready;
    for (int t = 0; t < NUM_TABLES; t++) s1_ready &= tbl_req_ready[t];
  end

  // useAltOnNa 计数器：[槽][pc[7:1]]，4 位饱和，复位 8（弱"用 alt"）
  logic [3:0] useAltOnNaCtrs [NUM_BR][NUM_ALT];

  // ===========================================================================
  // §1 S1：TAGE provider 选择、alt 判定、S1 方向；SC 的 S1 和
  // ===========================================================================
  logic                  s1_provided   [NUM_BR];
  logic [TBL_IDX_W-1:0]  s1_provider   [NUM_BR];
  tage_resp_t            s1_pvdr_resp  [NUM_BR];
  logic                  s1_use_alt_on_na [NUM_BR];
  logic                  s1_alt_used   [NUM_BR];
  logic                  s1_tage_taken [NUM_BR];
  logic [1:0]            s1_basecnt    [NUM_BR];
  logic [NUM_TABLES-1:0] s1_allocatable[NUM_BR];
  logic signed [8:0]     s1_sc_sum     [NUM_BR][2];

  for (genvar b = 0; b < NUM_BR; b++) begin : g_s1
    logic use_alt_ctr_hi;
    assign use_alt_ctr_hi = useAltOnNaCtrs[b][s1_pc[0][7:1]][3];

    // provider = 历史最长的命中表；都不命中时取第 0 张表的那份
    always_comb begin
      s1_provided[b]  = 1'b0;
      s1_provider[b]  = '0;
      s1_pvdr_resp[b] = tbl_resp[0][b];
      for (int t = 0; t < NUM_TABLES; t++) begin
        if (tbl_resp[t][b].valid) begin
          s1_provided[b]  = 1'b1;
          s1_provider[b]  = TBL_IDX_W'(t);
          s1_pvdr_resp[b] = tbl_resp[t][b];
        end
      end
    end

    assign s1_use_alt_on_na[b] = s1_pvdr_resp[b].unconf && use_alt_ctr_hi;
    assign s1_alt_used[b]      = !s1_provided[b] || s1_use_alt_on_na[b];
    // alt 预测 = 基础表（本拍有效时）或 uFTB 的 S1 方向
    assign s1_tage_taken[b]    = s1_alt_used[b] ? (bt_s1_resp_valid ? bt_s1_cnt[b][1] : s1_uftb_taken[b])
                                                : s1_pvdr_resp[b].ctr[2];
    assign s1_basecnt[b]       = bt_s1_resp_valid ? bt_s1_cnt[b] : (s1_uftb_taken[b] ? 2'd2 : 2'd1);

    // 可分配：没命中且 u=0，且历史比 provider 长
    always_comb begin
      for (int t = 0; t < NUM_TABLES; t++)
        s1_allocatable[b][t] = !tbl_resp[t][b].valid && !tbl_resp[t][b].u;
      s1_allocatable[b] &= ~(lower_mask_of(s1_provider[b]) & {NUM_TABLES{s1_provided[b]}});
    end

    for (genvar dir = 0; dir < 2; dir++) begin : g_sc_sum
      assign s1_sc_sum[b][dir] = sc_sum4(sc_resp[0][b][dir], sc_resp[1][b][dir],
                                         sc_resp[2][b][dir], sc_resp[3][b][dir]);
    end
  end

  // ===========================================================================
  // §2 S2：TAGE 结果打拍（s1_fire(1)），S2 方向按 dup 各自打拍并受 tage_enable 门控
  // ===========================================================================
  logic                  s2_provideds  [NUM_BR];
  logic [TBL_IDX_W-1:0]  s2_providers  [NUM_BR];
  logic [2:0]            s2_pvdr_ctr   [NUM_BR];
  logic                  s2_pvdr_u     [NUM_BR];
  logic                  s2_altUsed    [NUM_BR];
  logic [1:0]            s2_basecnts   [NUM_BR];
  logic                  s2_useAltOnNa [NUM_BR];
  logic [NUM_TABLES-1:0] allocatableSlots [NUM_BR];
  logic                  s2_tageTakens_dup [NUM_DUP][NUM_BR];
  logic                  tage_enable_dup_REG [NUM_BR];   // RegNext(ctrl.tage_enable)，每槽一份

  always_ff @(posedge clock) begin
    for (int b = 0; b < NUM_BR; b++) begin
      if (s1_fire[1]) begin
        s2_provideds[b]     <= s1_provided[b];
        s2_providers[b]     <= s1_provider[b];
        s2_pvdr_ctr[b]      <= s1_pvdr_resp[b].ctr;
        s2_pvdr_u[b]        <= s1_pvdr_resp[b].u;
        s2_altUsed[b]       <= s1_alt_used[b];
        s2_basecnts[b]      <= s1_basecnt[b];
        s2_useAltOnNa[b]    <= s1_use_alt_on_na[b];
        allocatableSlots[b] <= s1_allocatable[b];
      end
      for (int d = 0; d < NUM_DUP; d++)
        if (s1_fire[d]) s2_tageTakens_dup[d][b] <= s1_tage_taken[b];
      tage_enable_dup_REG[b] <= tage_enable;
    end
  end

  for (genvar d = 0; d < NUM_DUP; d++) begin : g_s2_out
    for (genvar b = 0; b < NUM_BR; b++) begin : g_br
      assign s2_taken[d][b] = tage_enable_dup_REG[b] && s2_tageTakens_dup[d][b];
    end
  end

  // ===========================================================================
  // §3 SC 预测：S1 和打拍（s1_fire(3)），S2 加 provider 居中值、过阈值才推翻 TAGE
  // ===========================================================================
  logic [4:0]        scThresholds_ctr   [NUM_BR];
  logic [7:0]        scThresholds_thres [NUM_BR];
  logic signed [8:0] s2_scTableSums     [NUM_BR][2];
  logic [2:0]        s2_tagePrvdCtr     [NUM_BR];          // provider ctr（S1 打拍，未居中）
  logic [5:0]        s2_scResps         [NUM_BR][NUM_SC][2];
  logic              s2_sc_above        [NUM_BR];
  logic              s2_sc_pred         [NUM_BR];
  logic              s2_pred            [NUM_BR];
  logic              s2_disagree        [NUM_BR];

  always_ff @(posedge clock) begin
    if (s1_fire[3]) begin
      for (int b = 0; b < NUM_BR; b++) begin
        s2_scTableSums[b][0] <= s1_sc_sum[b][0];
        s2_scTableSums[b][1] <= s1_sc_sum[b][1];
        s2_tagePrvdCtr[b]    <= s1_pvdr_resp[b].ctr;
        for (int k = 0; k < NUM_SC; k++) begin
          s2_scResps[b][k][0] <= sc_resp[k][b][0];
          s2_scResps[b][k][1] <= sc_resp[k][b][1];
        end
      end
    end
  end

  for (genvar b = 0; b < NUM_BR; b++) begin : g_s2_sc
    // chooseBit = TAGE 的 S2 方向（dup 3）：用对应方向那一路的 SC 和
    logic              choose;
    logic signed [8:0] sum_sel;
    logic signed [9:0] total_sel;
    assign choose      = s2_tageTakens_dup[3][b];
    assign sum_sel     = s2_scTableSums[b][choose];
    assign total_sel   = 10'(sum_sel) + 10'(pvdr_centered(s2_tagePrvdCtr[b]));
    assign s2_sc_above[b] = above_thres_s2(sum_sel, s2_tagePrvdCtr[b], scThresholds_thres[b]);
    assign s2_sc_pred[b]  = !total_sel[9];                         // 总和 >= 0 预测跳
    assign s2_pred[b]     = (s2_provideds[b] && s2_sc_above[b]) ? s2_sc_pred[b] : choose;
    assign s2_disagree[b] = s2_provideds[b] && s2_sc_above[b] && (choose != s2_sc_pred[b]);
  end

  // ===========================================================================
  // §4 S3：SC 方向与 meta 打拍
  // ===========================================================================
  logic                  s3_pred_dup  [NUM_DUP][NUM_BR];
  logic                  sc_enable_dup_REG [NUM_BR];
  logic [63:0]           pred_cycle;                          // GTimer()
  tage_meta_t            resp_meta;

  always_ff @(posedge clock) begin
    for (int b = 0; b < NUM_BR; b++) begin
      for (int d = 0; d < NUM_DUP; d++)
        if (s2_fire[d]) s3_pred_dup[d][b] <= s2_pred[b];
      sc_enable_dup_REG[b] <= sc_enable;
    end
    if (s2_fire[3]) begin
      for (int b = 0; b < NUM_BR; b++) begin
        s3_sc_disagree[b]          <= s2_disagree[b];
        resp_meta.sc_preds[b]      <= s2_sc_pred[b];
        for (int k = 0; k < NUM_SC; k++)
          resp_meta.sc_ctrs[b][k]  <= s2_scResps[b][k][s2_tageTakens_dup[3][b]];
      end
    end
    if (s2_fire[1]) begin
      for (int b = 0; b < NUM_BR; b++) begin
        resp_meta.provider[b]      <= {s2_provideds[b], s2_providers[b]};
        resp_meta.provider_resp[b] <= {s2_pvdr_ctr[b], s2_pvdr_u[b]};
        resp_meta.use_alt_on_na[b] <= s2_useAltOnNa[b];
        resp_meta.allocates[b]     <= allocatableSlots[b];
        resp_meta.alt_used[b]      <= s2_altUsed[b];
        resp_meta.basecnt[b]       <= s2_basecnts[b];
      end
      resp_meta.pred_cycle         <= pred_cycle;
    end
  end

  for (genvar d = 0; d < NUM_DUP; d++) begin : g_s3_out
    for (genvar b = 0; b < NUM_BR; b++) begin : g_br
      assign s3_taken[d][b] = sc_enable_dup_REG[b] && s3_pred_dup[d][b];
    end
  end

  assign last_stage_meta = {{(META_W - TAGE_META_W){1'b0}}, resp_meta};

  // ===========================================================================
  // §5 更新：锁存一拍（各字段按 golden 的使能分别锁存，省翻转）
  // ===========================================================================
  tage_meta_t        in_meta;
  logic [NUM_BR-1:0] u_valids_for_cge;     // 该槽在本次 update 里是有效分支
  assign in_meta = update_meta[TAGE_META_W-1:0];
  assign u_valids_for_cge[0] = update_br0_valid && update_valid;
  assign u_valids_for_cge[1] = update_tail_valid && update_tail_sharing && update_valid;

  logic                  u_valid;
  logic                  u_br0_valid, u_tail_sharing, u_tail_valid;
  logic [NUM_BR-1:0]     u_strong_bias, u_br_taken, u_mispred;
  logic [255:0]          update_ghist_r;
  logic                  um_provider_valid [NUM_BR];
  logic [TBL_IDX_W-1:0]  um_provider       [NUM_BR];
  logic [2:0]            um_pvdr_ctr       [NUM_BR];
  logic                  um_alt_used       [NUM_BR];
  logic [1:0]            um_basecnt        [NUM_BR];
  logic [NUM_TABLES-1:0] um_allocates      [NUM_BR];
  logic                  um_use_alt_on_na  [NUM_BR];    // 只喂 perf 探针
  logic                  um_sc_pred        [NUM_BR];
  logic [5:0]            um_sc_ctrs        [NUM_BR][NUM_SC];

  always_ff @(posedge clock) begin
    if (update_valid) begin
      u_br0_valid    <= update_br0_valid;
      u_tail_sharing <= update_tail_sharing;
      u_tail_valid   <= update_tail_valid;
      u_strong_bias  <= update_strong_bias;
      u_br_taken     <= update_br_taken;
      u_mispred      <= update_mispred;
      update_ghist_r <= update_ghist;
    end
    for (int b = 0; b < NUM_BR; b++) begin
      if (update_valid) begin
        um_provider_valid[b] <= in_meta.provider[b][2];
        um_basecnt[b]        <= in_meta.basecnt[b];
        um_use_alt_on_na[b]  <= in_meta.use_alt_on_na[b];
        um_allocates[b]      <= in_meta.allocates[b];
      end
      if (in_meta.provider[b][2] && u_valids_for_cge[b]) begin
        um_provider[b] <= in_meta.provider[b][1:0];
        um_pvdr_ctr[b] <= in_meta.provider_resp[b][3:1];
      end
      if (u_valids_for_cge[b])
        um_alt_used[b] <= in_meta.alt_used[b];
      if (u_valids_for_cge[b] && in_meta.provider[b][2]) begin
        um_sc_pred[b] <= in_meta.sc_preds[b];
        for (int k = 0; k < NUM_SC; k++) um_sc_ctrs[b][k] <= in_meta.sc_ctrs[b][k];
      end
    end
  end

  // ===========================================================================
  // §6 TAGE 更新：每槽算 provider 更新、useAltOnNa、分配、tick
  // ===========================================================================
  logic [NUM_BR-1:0]     update_valids;      // 该槽真有一条条件分支要更新
  logic [NUM_BR-1:0]     update_taken;
  logic [NUM_BR-1:0]     update_sc_used;     // 有更新且当初有 provider
  logic [NUM_BR-1:0]     provider_correct;
  logic [NUM_BR-1:0]     alt_differs;
  logic [NUM_BR-1:0]     alt_correct;
  logic [NUM_BR-1:0]     provider_weak;
  logic [NUM_BR-1:0]     need_to_allocate;
  logic [NUM_BR-1:0]     can_allocate;
  logic [NUM_BR-1:0]     update_reset_u;
  logic [NUM_BR-1:0]     base_update;
  logic [TBL_IDX_W-1:0]  alloc_entry   [NUM_BR];
  logic [NUM_TABLES-1:0] alloc_tbl     [NUM_BR];     // [槽] 在第 t 张表分配
  logic [NUM_TABLES-1:0] pvdr_tbl      [NUM_BR];     // [槽] 第 t 张表是 provider 且要更新
  logic [TICK_W-1:0]     bankTickCtrs              [NUM_BR];
  logic [TICK_W-1:0]     bankTickCtrDistanceToTops [NUM_BR];
  logic [TICK_W-1:0]     tick_next     [NUM_BR];
  logic [TICK_W-1:0]     dist_next     [NUM_BR];

  // 槽 0 = brSlot；槽 1 = 共享成条件分支的 tailSlot，且槽 0 没跳（!(PriorityEncoder(taken) < 1)）
  assign update_valids[0] = u_br0_valid && u_valid && !u_strong_bias[0];
  assign update_valids[1] = u_tail_valid && u_tail_sharing && u_valid && !u_strong_bias[1] && !u_br_taken[0];

  for (genvar b = 0; b < NUM_BR; b++) begin : g_upd
    logic [NUM_TABLES-1:0] longer_mask, can_alloc_mask, fail_mask;
    logic [2:0]            n_can, n_fail, inc_val, dec_val;
    logic                  tick_inc, tick_dec;
    logic [TBL_IDX_W-1:0]  first_entry, masked_entry;
    logic [NUM_TABLES-1:0] masked_vec;

    assign update_taken[b]     = update_valids[b] && u_br_taken[b];
    assign update_sc_used[b]   = update_valids[b] && um_provider_valid[b];
    assign provider_correct[b] = (um_pvdr_ctr[b][2] == update_taken[b]);
    assign alt_differs[b]      = (um_basecnt[b][1] != um_pvdr_ctr[b][2]);
    assign alt_correct[b]      = (um_basecnt[b][1] == update_taken[b]);
    assign provider_weak[b]    = (um_pvdr_ctr[b] == 3'd4) || (um_pvdr_ctr[b] == 3'd3);
    assign base_update[b]      = update_valids[b] && um_alt_used[b];
    assign need_to_allocate[b] = update_valids[b] && u_mispred[b]
                                 && !(um_alt_used[b] && provider_correct[b] && um_provider_valid[b]);
    assign can_allocate[b]     = |um_allocates[b];
    assign update_reset_u[b]   = need_to_allocate[b] && (&bankTickCtrs[b]);

    // 只在比 provider 历史长的表里分配
    assign longer_mask    = ~(lower_mask_of(um_provider[b]) & {NUM_TABLES{um_provider_valid[b]}});
    assign can_alloc_mask = um_allocates[b] & longer_mask;
    assign fail_mask      = ~um_allocates[b] & longer_mask;
    assign masked_vec     = can_alloc_mask & {1'b0, lfsr_bits[b]};
    assign first_entry    = prio_enc4(can_alloc_mask);
    assign masked_entry   = prio_enc4(masked_vec);
    assign alloc_entry[b] = can_alloc_mask[masked_entry] ? masked_entry : first_entry;

    // tick：分配失败的表多于可分配的表就涨，反之就降；到顶饱和
    assign n_can    = popcount4(can_alloc_mask);
    assign n_fail   = popcount4(fail_mask);
    assign tick_inc = n_fail > n_can;
    assign tick_dec = n_can > n_fail;
    assign inc_val  = n_fail - n_can;
    assign dec_val  = n_can - n_fail;

    always_comb begin
      tick_next[b] = bankTickCtrs[b];
      dist_next[b] = bankTickCtrDistanceToTops[b];
      if (need_to_allocate[b]) begin
        if (&bankTickCtrs[b]) begin                       // 涨满：清零并 reset_u
          tick_next[b] = '0;
          dist_next[b] = '1;
        end else if (tick_inc) begin
          if (TICK_W'(inc_val) >= bankTickCtrDistanceToTops[b]) begin
            tick_next[b] = '1;
            dist_next[b] = '0;
          end else begin
            tick_next[b] = bankTickCtrs[b] + TICK_W'(inc_val);
            dist_next[b] = bankTickCtrDistanceToTops[b] - TICK_W'(inc_val);
          end
        end else if (tick_dec) begin
          if (TICK_W'(dec_val) >= bankTickCtrs[b]) begin
            tick_next[b] = '0;
            dist_next[b] = '1;
          end else begin
            tick_next[b] = bankTickCtrs[b] - TICK_W'(dec_val);
            dist_next[b] = bankTickCtrDistanceToTops[b] + TICK_W'(dec_val);
          end
        end
      end
    end

    for (genvar t = 0; t < NUM_TABLES; t++) begin : g_tbl
      assign alloc_tbl[b][t] = need_to_allocate[b] && can_allocate[b] && (alloc_entry[b] == TBL_IDX_W'(t));
      assign pvdr_tbl[b][t]  = update_sc_used[b] && (um_provider[b] == TBL_IDX_W'(t));
    end
  end

  // useAltOnNa / tick 的寄存器
  logic [NUM_BR-1:0] use_alt_upd;
  for (genvar b = 0; b < NUM_BR; b++) begin : g_use_alt_upd
    assign use_alt_upd[b] = update_valids[b] && um_provider_valid[b] && provider_weak[b] && alt_differs[b];
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int b = 0; b < NUM_BR; b++) begin
        bankTickCtrs[b]              <= '0;
        bankTickCtrDistanceToTops[b] <= '1;
        for (int i = 0; i < NUM_ALT; i++) useAltOnNaCtrs[b][i] <= 4'h8;
      end
    end else begin
      for (int b = 0; b < NUM_BR; b++) begin
        bankTickCtrs[b]              <= tick_next[b];
        bankTickCtrDistanceToTops[b] <= dist_next[b];
        // 索引用 io.update.bits.pc（未锁存那份）的 [7:1]，照 golden
        for (int i = 0; i < NUM_ALT; i++)
          if (use_alt_upd[b] && update_pc[7:1] == 7'(i))
            useAltOnNaCtrs[b][i] <= sat4_update(useAltOnNaCtrs[b][i], alt_correct[b]);
      end
    end
  end

  // ===========================================================================
  // §7 SC 更新：阈值自适应、决定是否更新 SC 表
  // ===========================================================================
  logic [NUM_BR-1:0] tage_pred;          // 当初 TAGE 的最终方向
  logic [NUM_BR-1:0] sc_sum_above;       // 用更新阈值判的"过阈值"
  logic [NUM_BR-1:0] sc_upd_mask;        // 该槽更新全部 4 张 SC 表
  logic [NUM_BR-1:0] thres_upd;
  logic [NUM_BR-1:0] update_on_mispred, update_on_unconf;

  for (genvar b = 0; b < NUM_BR; b++) begin : g_sc_upd
    logic signed [8:0] table_sum;
    logic signed [9:0] total_sum;
    logic [9:0]        total_abs;
    logic [7:0]        thres_m4, thres_m2;
    assign tage_pred[b]    = um_alt_used[b] ? um_basecnt[b][1] : um_pvdr_ctr[b][2];
    assign table_sum       = sc_sum4(um_sc_ctrs[b][0], um_sc_ctrs[b][1], um_sc_ctrs[b][2], um_sc_ctrs[b][3]);
    assign total_sum       = 10'(table_sum) + 10'(pvdr_centered(um_pvdr_ctr[b]));
    assign total_abs       = total_sum[9] ? 10'(10'd0 - total_sum) : total_sum;
    assign thres_m4        = scThresholds_thres[b] - 8'd4;
    assign thres_m2        = scThresholds_thres[b] - 8'd2;
    assign sc_sum_above[b] = above_thres_upd(table_sum, um_pvdr_ctr[b], scThresholds_thres[b]);
    assign thres_upd[b]    = update_sc_used[b] && (um_sc_pred[b] != tage_pred[b])
                             && (total_abs >= {2'b0, thres_m4}) && (total_abs <= {2'b0, thres_m2});
    assign sc_upd_mask[b]  = update_sc_used[b] && ((um_sc_pred[b] != u_br_taken[b]) || !sc_sum_above[b]);
    assign update_on_mispred[b] = sc_upd_mask[b] && (um_sc_pred[b] != u_br_taken[b]);
    assign update_on_unconf[b]  = sc_upd_mask[b] && (um_sc_pred[b] == u_br_taken[b]);
  end

  // SCThreshold.update(cause = scPred != taken)：ctr 5 位饱和 ±1，饱和时归中 16 并把阈值 ±2
  logic [4:0] thres_new_ctr [NUM_BR];
  always_comb begin
    for (int b = 0; b < NUM_BR; b++)
      thres_new_ctr[b] = sat5_update(scThresholds_ctr[b], um_sc_pred[b] != u_br_taken[b]);
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int b = 0; b < NUM_BR; b++) begin
        scThresholds_ctr[b]   <= 5'd16;
        scThresholds_thres[b] <= 8'd6;
      end
    end else begin
      for (int b = 0; b < NUM_BR; b++) begin
        if (thres_upd[b]) begin
          scThresholds_ctr[b] <= (thres_new_ctr[b] == 5'h1F || thres_new_ctr[b] == 5'h00) ? 5'd16
                                                                                        : thres_new_ctr[b];
          if (thres_new_ctr[b] == 5'h1F && scThresholds_thres[b] <= 8'd31)
            scThresholds_thres[b] <= scThresholds_thres[b] + 8'd2;
          else if (thres_new_ctr[b] == 5'h00 && scThresholds_thres[b] >= 8'd6)
            scThresholds_thres[b] <= scThresholds_thres[b] - 8'd2;
        end
      end
    end
  end

  // ===========================================================================
  // §8 各表的 update 口：再打一拍送出
  //   DontCare 字段按 golden 实际取值：takens = updateTaken、oldCtrs = providerCtr（分配项亦然）；
  //   SC 的 tagePreds / takens / oldCtrs 无条件取本槽的值。
  //   各表的 pc / ghist 寄存器单列成独立数组（tbl_upd_pc 等）：它们的高位在子模块里没有读者，
  //   FM 侧要逐位钉到 golden 的 tables_k_io_update_pc_r_1 等（见 verif/ut/Tage_SC/fm_pins_pre.tcl）。
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      u_valid    <= 1'b0;
      pred_cycle <= '0;
    end else begin
      u_valid    <= update_valid;
      pred_cycle <= pred_cycle + 64'd1;
    end
  end

  always_ff @(posedge clock) begin
    for (int t = 0; t < NUM_TABLES; t++) begin
      for (int b = 0; b < NUM_BR; b++) begin
        tbl_upd[t].reset_u[b] <= update_reset_u[b];
        tbl_upd[t].mask[b]    <= alloc_tbl[b][t] || pvdr_tbl[b][t];
      end
      if (alloc_tbl[0][t] || pvdr_tbl[0][t] || alloc_tbl[1][t] || pvdr_tbl[1][t]) begin
        for (int b = 0; b < NUM_BR; b++) begin
          tbl_upd[t].takens[b]   <= update_taken[b];
          tbl_upd[t].alloc[b]    <= alloc_tbl[b][t];
          tbl_upd[t].old_ctrs[b] <= um_pvdr_ctr[b];
          tbl_upd[t].u_mask[b]   <= alloc_tbl[b][t] || (pvdr_tbl[b][t] && alt_differs[b]);
          tbl_upd[t].us[b]       <= !alloc_tbl[b][t] && provider_correct[b];
        end
        tbl_upd_pc[t]    <= update_pc;           // io.update.bits.pc（未锁存那份）
        tbl_upd_ghist[t] <= update_ghist_r;
      end
    end
    // 基础表：用了 alt 预测的那次更新基础表
    bt_upd.mask <= base_update;
    if (|base_update) begin
      for (int b = 0; b < NUM_BR; b++) begin
        bt_upd.cnt[b]    <= um_basecnt[b];
        bt_upd.takens[b] <= update_taken[b];
      end
      bt_upd_pc <= update_pc;
    end
    // SC 表：4 张表同一份掩码
    for (int k = 0; k < NUM_SC; k++) begin
      sc_upd[k].mask <= sc_upd_mask;
      if (|sc_upd_mask) begin
        for (int b = 0; b < NUM_BR; b++) begin
          sc_upd[k].tage_preds[b] <= tage_pred[b];
          sc_upd[k].takens[b]     <= u_br_taken[b];
          sc_upd[k].old_ctrs[b]   <= um_sc_ctrs[b][k];
        end
        sc_upd_pc[k] <= update_pc;
      end
    end
    // 第 0 张 SC 表历史长度 0，没有 ghist 口（golden 里也就没有这个寄存器）
    for (int k = 1; k < NUM_SC; k++)
      if (|sc_upd_mask) sc_upd_ghist[k] <= update_ghist_r;
  end

  // ===========================================================================
  // §9 perf：provider 命中数 / SC 因预测错更新数 / SC 因不自信更新数（各 2 拍对齐）
  // ===========================================================================
  logic [1:0] perf_d1 [3];
  always_ff @(posedge clock) begin
    perf_d1[0] <= 2'(um_provider_valid[0]) + 2'(um_provider_valid[1]);
    perf_d1[1] <= 2'(update_on_mispred[0]) + 2'(update_on_mispred[1]);
    perf_d1[2] <= 2'(update_on_unconf[0]) + 2'(update_on_unconf[1]);
    for (int p = 0; p < 3; p++) perf[p] <= perf_d1[p];
  end

endmodule

// BEGIN GENERATED(bpu-wrapper) —— scripts/gen_bpu_wrappers.py 生成，勿手改
module Tage_SC
  import tage_sc_pkg::*;
(
  input  clock,
  input  reset,
  input  [47:0] io_reset_vector,
  input  [49:0] io_in_bits_s0_pc_0,
  input  [49:0] io_in_bits_s0_pc_1,
  input  [49:0] io_in_bits_s0_pc_2,
  input  [49:0] io_in_bits_s0_pc_3,
  input  [10:0] io_in_bits_folded_hist_1_hist_17_folded_hist,
  input  [10:0] io_in_bits_folded_hist_1_hist_16_folded_hist,
  input  [6:0] io_in_bits_folded_hist_1_hist_15_folded_hist,
  input  [7:0] io_in_bits_folded_hist_1_hist_14_folded_hist,
  input  [6:0] io_in_bits_folded_hist_1_hist_9_folded_hist,
  input  [7:0] io_in_bits_folded_hist_1_hist_8_folded_hist,
  input  [6:0] io_in_bits_folded_hist_1_hist_7_folded_hist,
  input  [6:0] io_in_bits_folded_hist_1_hist_5_folded_hist,
  input  [7:0] io_in_bits_folded_hist_1_hist_4_folded_hist,
  input  [7:0] io_in_bits_folded_hist_1_hist_3_folded_hist,
  input  [10:0] io_in_bits_folded_hist_1_hist_1_folded_hist,
  input  [3:0] io_in_bits_folded_hist_3_hist_12_folded_hist,
  input  [7:0] io_in_bits_folded_hist_3_hist_11_folded_hist,
  input  [7:0] io_in_bits_folded_hist_3_hist_2_folded_hist,
  input  [255:0] io_in_bits_ghist,
  input  io_in_bits_resp_in_0_s1_full_pred_0_br_taken_mask_0,
  input  io_in_bits_resp_in_0_s1_full_pred_0_br_taken_mask_1,
  output io_out_s2_full_pred_0_br_taken_mask_0,
  output io_out_s2_full_pred_0_br_taken_mask_1,
  output io_out_s2_full_pred_1_br_taken_mask_0,
  output io_out_s2_full_pred_1_br_taken_mask_1,
  output io_out_s2_full_pred_2_br_taken_mask_0,
  output io_out_s2_full_pred_2_br_taken_mask_1,
  output io_out_s2_full_pred_3_br_taken_mask_0,
  output io_out_s2_full_pred_3_br_taken_mask_1,
  output io_out_s3_full_pred_0_br_taken_mask_0,
  output io_out_s3_full_pred_0_br_taken_mask_1,
  output io_out_s3_full_pred_1_br_taken_mask_0,
  output io_out_s3_full_pred_1_br_taken_mask_1,
  output io_out_s3_full_pred_2_br_taken_mask_0,
  output io_out_s3_full_pred_2_br_taken_mask_1,
  output io_out_s3_full_pred_3_br_taken_mask_0,
  output io_out_s3_full_pred_3_br_taken_mask_1,
  output [515:0] io_out_last_stage_meta,
  output io_out_last_stage_spec_info_sc_disagree_0,
  output io_out_last_stage_spec_info_sc_disagree_1,
  input  io_ctrl_tage_enable,
  input  io_ctrl_sc_enable,
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
  input  io_update_bits_ftb_entry_brSlots_0_valid,
  input  io_update_bits_ftb_entry_tailSlot_sharing,
  input  io_update_bits_ftb_entry_tailSlot_valid,
  input  io_update_bits_ftb_entry_strong_bias_0,
  input  io_update_bits_ftb_entry_strong_bias_1,
  input  io_update_bits_br_taken_mask_0,
  input  io_update_bits_br_taken_mask_1,
  input  io_update_bits_mispred_mask_0,
  input  io_update_bits_mispred_mask_1,
  input  [515:0] io_update_bits_meta,
  input  [255:0] io_update_bits_ghist,
  output [5:0] io_perf_0_value,
  output [5:0] io_perf_1_value,
  output [5:0] io_perf_2_value,
  input  [6:0] boreChildrenBd_bore_array,
  input  boreChildrenBd_bore_all,
  input  boreChildrenBd_bore_req,
  output boreChildrenBd_bore_ack,
  input  boreChildrenBd_bore_writeen,
  input  [15:0] boreChildrenBd_bore_be,
  input  [9:0] boreChildrenBd_bore_addr,
  input  [23:0] boreChildrenBd_bore_indata,
  input  boreChildrenBd_bore_readen,
  input  [9:0] boreChildrenBd_bore_addr_rd,
  output [23:0] boreChildrenBd_bore_outdata,
  input  [6:0] boreChildrenBd_bore_1_array,
  input  boreChildrenBd_bore_1_all,
  input  boreChildrenBd_bore_1_req,
  output boreChildrenBd_bore_1_ack,
  input  boreChildrenBd_bore_1_writeen,
  input  [3:0] boreChildrenBd_bore_1_be,
  input  [7:0] boreChildrenBd_bore_1_addr,
  input  [23:0] boreChildrenBd_bore_1_indata,
  input  boreChildrenBd_bore_1_readen,
  input  [7:0] boreChildrenBd_bore_1_addr_rd,
  output [23:0] boreChildrenBd_bore_1_outdata,
  input  [6:0] boreChildrenBd_bore_2_array,
  input  boreChildrenBd_bore_2_all,
  input  boreChildrenBd_bore_2_req,
  output boreChildrenBd_bore_2_ack,
  input  boreChildrenBd_bore_2_writeen,
  input  [3:0] boreChildrenBd_bore_2_be,
  input  [7:0] boreChildrenBd_bore_2_addr,
  input  [23:0] boreChildrenBd_bore_2_indata,
  input  boreChildrenBd_bore_2_readen,
  input  [7:0] boreChildrenBd_bore_2_addr_rd,
  output [23:0] boreChildrenBd_bore_2_outdata,
  input  [6:0] boreChildrenBd_bore_3_array,
  input  boreChildrenBd_bore_3_all,
  input  boreChildrenBd_bore_3_req,
  output boreChildrenBd_bore_3_ack,
  input  boreChildrenBd_bore_3_writeen,
  input  [3:0] boreChildrenBd_bore_3_be,
  input  [7:0] boreChildrenBd_bore_3_addr,
  input  [23:0] boreChildrenBd_bore_3_indata,
  input  boreChildrenBd_bore_3_readen,
  input  [7:0] boreChildrenBd_bore_3_addr_rd,
  output [23:0] boreChildrenBd_bore_3_outdata,
  input  [6:0] boreChildrenBd_bore_4_array,
  input  boreChildrenBd_bore_4_all,
  input  boreChildrenBd_bore_4_req,
  output boreChildrenBd_bore_4_ack,
  input  boreChildrenBd_bore_4_writeen,
  input  [3:0] boreChildrenBd_bore_4_be,
  input  [7:0] boreChildrenBd_bore_4_addr,
  input  [23:0] boreChildrenBd_bore_4_indata,
  input  boreChildrenBd_bore_4_readen,
  input  [7:0] boreChildrenBd_bore_4_addr_rd,
  output [23:0] boreChildrenBd_bore_4_outdata,
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
  input  sigFromSrams_bore_7_cgen,
  input  sigFromSrams_bore_8_ram_hold,
  input  sigFromSrams_bore_8_ram_bypass,
  input  sigFromSrams_bore_8_ram_bp_clken,
  input  sigFromSrams_bore_8_ram_aux_clk,
  input  sigFromSrams_bore_8_ram_aux_ckbp,
  input  sigFromSrams_bore_8_ram_mcp_hold,
  input  sigFromSrams_bore_8_cgen,
  input  sigFromSrams_bore_9_ram_hold,
  input  sigFromSrams_bore_9_ram_bypass,
  input  sigFromSrams_bore_9_ram_bp_clken,
  input  sigFromSrams_bore_9_ram_aux_clk,
  input  sigFromSrams_bore_9_ram_aux_ckbp,
  input  sigFromSrams_bore_9_ram_mcp_hold,
  input  sigFromSrams_bore_9_cgen,
  input  sigFromSrams_bore_10_ram_hold,
  input  sigFromSrams_bore_10_ram_bypass,
  input  sigFromSrams_bore_10_ram_bp_clken,
  input  sigFromSrams_bore_10_ram_aux_clk,
  input  sigFromSrams_bore_10_ram_aux_ckbp,
  input  sigFromSrams_bore_10_ram_mcp_hold,
  input  sigFromSrams_bore_10_cgen,
  input  sigFromSrams_bore_11_ram_hold,
  input  sigFromSrams_bore_11_ram_bypass,
  input  sigFromSrams_bore_11_ram_bp_clken,
  input  sigFromSrams_bore_11_ram_aux_clk,
  input  sigFromSrams_bore_11_ram_aux_ckbp,
  input  sigFromSrams_bore_11_ram_mcp_hold,
  input  sigFromSrams_bore_11_cgen,
  input  sigFromSrams_bore_12_ram_hold,
  input  sigFromSrams_bore_12_ram_bypass,
  input  sigFromSrams_bore_12_ram_bp_clken,
  input  sigFromSrams_bore_12_ram_aux_clk,
  input  sigFromSrams_bore_12_ram_aux_ckbp,
  input  sigFromSrams_bore_12_ram_mcp_hold,
  input  sigFromSrams_bore_12_cgen,
  input  sigFromSrams_bore_13_ram_hold,
  input  sigFromSrams_bore_13_ram_bypass,
  input  sigFromSrams_bore_13_ram_bp_clken,
  input  sigFromSrams_bore_13_ram_aux_clk,
  input  sigFromSrams_bore_13_ram_aux_ckbp,
  input  sigFromSrams_bore_13_ram_mcp_hold,
  input  sigFromSrams_bore_13_cgen,
  input  sigFromSrams_bore_14_ram_hold,
  input  sigFromSrams_bore_14_ram_bypass,
  input  sigFromSrams_bore_14_ram_bp_clken,
  input  sigFromSrams_bore_14_ram_aux_clk,
  input  sigFromSrams_bore_14_ram_aux_ckbp,
  input  sigFromSrams_bore_14_ram_mcp_hold,
  input  sigFromSrams_bore_14_cgen,
  input  sigFromSrams_bore_15_ram_hold,
  input  sigFromSrams_bore_15_ram_bypass,
  input  sigFromSrams_bore_15_ram_bp_clken,
  input  sigFromSrams_bore_15_ram_aux_clk,
  input  sigFromSrams_bore_15_ram_aux_ckbp,
  input  sigFromSrams_bore_15_ram_mcp_hold,
  input  sigFromSrams_bore_15_cgen,
  input  sigFromSrams_bore_16_ram_hold,
  input  sigFromSrams_bore_16_ram_bypass,
  input  sigFromSrams_bore_16_ram_bp_clken,
  input  sigFromSrams_bore_16_ram_aux_clk,
  input  sigFromSrams_bore_16_ram_aux_ckbp,
  input  sigFromSrams_bore_16_ram_mcp_hold,
  input  sigFromSrams_bore_16_cgen,
  input  sigFromSrams_bore_17_ram_hold,
  input  sigFromSrams_bore_17_ram_bypass,
  input  sigFromSrams_bore_17_ram_bp_clken,
  input  sigFromSrams_bore_17_ram_aux_clk,
  input  sigFromSrams_bore_17_ram_aux_ckbp,
  input  sigFromSrams_bore_17_ram_mcp_hold,
  input  sigFromSrams_bore_17_cgen,
  input  sigFromSrams_bore_18_ram_hold,
  input  sigFromSrams_bore_18_ram_bypass,
  input  sigFromSrams_bore_18_ram_bp_clken,
  input  sigFromSrams_bore_18_ram_aux_clk,
  input  sigFromSrams_bore_18_ram_aux_ckbp,
  input  sigFromSrams_bore_18_ram_mcp_hold,
  input  sigFromSrams_bore_18_cgen,
  input  sigFromSrams_bore_19_ram_hold,
  input  sigFromSrams_bore_19_ram_bypass,
  input  sigFromSrams_bore_19_ram_bp_clken,
  input  sigFromSrams_bore_19_ram_aux_clk,
  input  sigFromSrams_bore_19_ram_aux_ckbp,
  input  sigFromSrams_bore_19_ram_mcp_hold,
  input  sigFromSrams_bore_19_cgen,
  input  sigFromSrams_bore_20_ram_hold,
  input  sigFromSrams_bore_20_ram_bypass,
  input  sigFromSrams_bore_20_ram_bp_clken,
  input  sigFromSrams_bore_20_ram_aux_clk,
  input  sigFromSrams_bore_20_ram_aux_ckbp,
  input  sigFromSrams_bore_20_ram_mcp_hold,
  input  sigFromSrams_bore_20_cgen,
  input  sigFromSrams_bore_21_ram_hold,
  input  sigFromSrams_bore_21_ram_bypass,
  input  sigFromSrams_bore_21_ram_bp_clken,
  input  sigFromSrams_bore_21_ram_aux_clk,
  input  sigFromSrams_bore_21_ram_aux_ckbp,
  input  sigFromSrams_bore_21_ram_mcp_hold,
  input  sigFromSrams_bore_21_cgen,
  input  sigFromSrams_bore_22_ram_hold,
  input  sigFromSrams_bore_22_ram_bypass,
  input  sigFromSrams_bore_22_ram_bp_clken,
  input  sigFromSrams_bore_22_ram_aux_clk,
  input  sigFromSrams_bore_22_ram_aux_ckbp,
  input  sigFromSrams_bore_22_ram_mcp_hold,
  input  sigFromSrams_bore_22_cgen,
  input  sigFromSrams_bore_23_ram_hold,
  input  sigFromSrams_bore_23_ram_bypass,
  input  sigFromSrams_bore_23_ram_bp_clken,
  input  sigFromSrams_bore_23_ram_aux_clk,
  input  sigFromSrams_bore_23_ram_aux_ckbp,
  input  sigFromSrams_bore_23_ram_mcp_hold,
  input  sigFromSrams_bore_23_cgen,
  input  sigFromSrams_bore_24_ram_hold,
  input  sigFromSrams_bore_24_ram_bypass,
  input  sigFromSrams_bore_24_ram_bp_clken,
  input  sigFromSrams_bore_24_ram_aux_clk,
  input  sigFromSrams_bore_24_ram_aux_ckbp,
  input  sigFromSrams_bore_24_ram_mcp_hold,
  input  sigFromSrams_bore_24_cgen,
  input  sigFromSrams_bore_25_ram_hold,
  input  sigFromSrams_bore_25_ram_bypass,
  input  sigFromSrams_bore_25_ram_bp_clken,
  input  sigFromSrams_bore_25_ram_aux_clk,
  input  sigFromSrams_bore_25_ram_aux_ckbp,
  input  sigFromSrams_bore_25_ram_mcp_hold,
  input  sigFromSrams_bore_25_cgen,
  input  sigFromSrams_bore_26_ram_hold,
  input  sigFromSrams_bore_26_ram_bypass,
  input  sigFromSrams_bore_26_ram_bp_clken,
  input  sigFromSrams_bore_26_ram_aux_clk,
  input  sigFromSrams_bore_26_ram_aux_ckbp,
  input  sigFromSrams_bore_26_ram_mcp_hold,
  input  sigFromSrams_bore_26_cgen,
  input  sigFromSrams_bore_27_ram_hold,
  input  sigFromSrams_bore_27_ram_bypass,
  input  sigFromSrams_bore_27_ram_bp_clken,
  input  sigFromSrams_bore_27_ram_aux_clk,
  input  sigFromSrams_bore_27_ram_aux_ckbp,
  input  sigFromSrams_bore_27_ram_mcp_hold,
  input  sigFromSrams_bore_27_cgen,
  input  sigFromSrams_bore_28_ram_hold,
  input  sigFromSrams_bore_28_ram_bypass,
  input  sigFromSrams_bore_28_ram_bp_clken,
  input  sigFromSrams_bore_28_ram_aux_clk,
  input  sigFromSrams_bore_28_ram_aux_ckbp,
  input  sigFromSrams_bore_28_ram_mcp_hold,
  input  sigFromSrams_bore_28_cgen,
  input  sigFromSrams_bore_29_ram_hold,
  input  sigFromSrams_bore_29_ram_bypass,
  input  sigFromSrams_bore_29_ram_bp_clken,
  input  sigFromSrams_bore_29_ram_aux_clk,
  input  sigFromSrams_bore_29_ram_aux_ckbp,
  input  sigFromSrams_bore_29_ram_mcp_hold,
  input  sigFromSrams_bore_29_cgen,
  input  sigFromSrams_bore_30_ram_hold,
  input  sigFromSrams_bore_30_ram_bypass,
  input  sigFromSrams_bore_30_ram_bp_clken,
  input  sigFromSrams_bore_30_ram_aux_clk,
  input  sigFromSrams_bore_30_ram_aux_ckbp,
  input  sigFromSrams_bore_30_ram_mcp_hold,
  input  sigFromSrams_bore_30_cgen,
  input  sigFromSrams_bore_31_ram_hold,
  input  sigFromSrams_bore_31_ram_bypass,
  input  sigFromSrams_bore_31_ram_bp_clken,
  input  sigFromSrams_bore_31_ram_aux_clk,
  input  sigFromSrams_bore_31_ram_aux_ckbp,
  input  sigFromSrams_bore_31_ram_mcp_hold,
  input  sigFromSrams_bore_31_cgen
);

  logic [PC_W-1:0]      s0_pc    [NUM_DUP];
  logic                 s0_fire  [NUM_DUP];
  logic                 s1_fire  [NUM_DUP];
  logic                 s2_fire  [NUM_DUP];
  logic                 tbl_req_ready [NUM_TABLES];
  tage_resp_t           tbl_resp      [NUM_TABLES][NUM_BR];
  tage_upd_t            tbl_upd       [NUM_TABLES];
  logic [PC_W-1:0]      tbl_upd_pc    [NUM_TABLES];
  logic [255:0]         tbl_upd_ghist [NUM_TABLES];
  logic                 bt_req_ready;
  logic [1:0]           bt_s1_cnt     [NUM_BR];
  logic                 bt_s1_resp_valid;
  bt_upd_t              bt_upd;
  logic [PC_W-1:0]      bt_upd_pc;
  logic [5:0]           sc_resp       [NUM_SC][NUM_BR][2];
  sc_upd_t              sc_upd        [NUM_SC];
  logic [PC_W-1:0]      sc_upd_pc     [NUM_SC];
  logic [255:0]         sc_upd_ghist  [1:NUM_SC-1];
  logic [2:0]           lfsr_bits     [NUM_BR];
  logic [NUM_BR-1:0]    s2_taken      [NUM_DUP];
  logic [NUM_BR-1:0]    s3_taken      [NUM_DUP];
  logic [NUM_BR-1:0]    s3_sc_disagree;
  logic [1:0]           perf          [3];

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
  xs_Tage_SC_core u_core (
    .clock                 (clock),
    .reset                 (reset),
    .reset_vector          (io_reset_vector),
    .s0_pc                 (s0_pc),
    .s0_fire               (s0_fire),
    .s1_fire               (s1_fire),
    .s2_fire               (s2_fire),
    .tage_enable           (io_ctrl_tage_enable),
    .sc_enable             (io_ctrl_sc_enable),
    .s1_uftb_taken         ({io_in_bits_resp_in_0_s1_full_pred_0_br_taken_mask_1, io_in_bits_resp_in_0_s1_full_pred_0_br_taken_mask_0}),
    .tbl_req_ready         (tbl_req_ready),
    .tbl_resp              (tbl_resp),
    .tbl_upd               (tbl_upd),
    .tbl_upd_pc            (tbl_upd_pc),
    .tbl_upd_ghist         (tbl_upd_ghist),
    .bt_req_ready          (bt_req_ready),
    .bt_s1_cnt             (bt_s1_cnt),
    .bt_s1_resp_valid      (bt_s1_resp_valid),
    .bt_upd                (bt_upd),
    .bt_upd_pc             (bt_upd_pc),
    .sc_resp               (sc_resp),
    .sc_upd                (sc_upd),
    .sc_upd_pc             (sc_upd_pc),
    .sc_upd_ghist          (sc_upd_ghist),
    .lfsr_bits             (lfsr_bits),
    .update_valid          (io_update_valid),
    .update_pc             (io_update_bits_pc),
    .update_br0_valid      (io_update_bits_ftb_entry_brSlots_0_valid),
    .update_tail_sharing   (io_update_bits_ftb_entry_tailSlot_sharing),
    .update_tail_valid     (io_update_bits_ftb_entry_tailSlot_valid),
    .update_strong_bias    ({io_update_bits_ftb_entry_strong_bias_1, io_update_bits_ftb_entry_strong_bias_0}),
    .update_br_taken       ({io_update_bits_br_taken_mask_1, io_update_bits_br_taken_mask_0}),
    .update_mispred        ({io_update_bits_mispred_mask_1, io_update_bits_mispred_mask_0}),
    .update_meta           (io_update_bits_meta),
    .update_ghist          (io_update_bits_ghist),
    .s2_taken              (s2_taken),
    .s3_taken              (s3_taken),
    .s3_sc_disagree        (s3_sc_disagree),
    .last_stage_meta       (io_out_last_stage_meta),
    .s1_ready              (io_s1_ready),
    .perf                  (perf)
  );

  // ---- 子模块（实例名 / 端口顺序同 golden）----
  // MBIST 子链：子模块之间的直连网（名字同 golden）
  wire childBd_1_ack;
  wire [9:0] childBd_1_addr;
  wire [9:0] childBd_1_addr_rd;
  wire [5:0] childBd_1_array;
  wire [23:0] childBd_1_rdata;
  wire childBd_1_re;
  wire childBd_1_selectedOH;
  wire [23:0] childBd_1_wdata;
  wire childBd_1_we;
  wire [1:0] childBd_1_wmask;
  wire childBd_2_ack;
  wire [9:0] childBd_2_addr;
  wire [9:0] childBd_2_addr_rd;
  wire [5:0] childBd_2_array;
  wire [23:0] childBd_2_rdata;
  wire childBd_2_re;
  wire childBd_2_selectedOH;
  wire [23:0] childBd_2_wdata;
  wire childBd_2_we;
  wire [1:0] childBd_2_wmask;
  wire childBd_3_ack;
  wire [9:0] childBd_3_addr;
  wire [9:0] childBd_3_addr_rd;
  wire [5:0] childBd_3_array;
  wire [23:0] childBd_3_rdata;
  wire childBd_3_re;
  wire childBd_3_selectedOH;
  wire [23:0] childBd_3_wdata;
  wire childBd_3_we;
  wire [1:0] childBd_3_wmask;
  wire childBd_4_ack;
  wire [9:0] childBd_4_addr;
  wire [9:0] childBd_4_addr_rd;
  wire [5:0] childBd_4_array;
  wire [23:0] childBd_4_rdata;
  wire childBd_4_re;
  wire childBd_4_selectedOH;
  wire [23:0] childBd_4_wdata;
  wire childBd_4_we;
  wire [1:0] childBd_4_wmask;
  wire childBd_5_ack;
  wire [8:0] childBd_5_addr;
  wire [8:0] childBd_5_addr_rd;
  wire [5:0] childBd_5_array;
  wire [15:0] childBd_5_rdata;
  wire childBd_5_re;
  wire childBd_5_selectedOH;
  wire [15:0] childBd_5_wdata;
  wire childBd_5_we;
  wire [15:0] childBd_5_wmask;
  wire childBd_6_ack;
  wire [9:0] childBd_6_addr;
  wire [9:0] childBd_6_addr_rd;
  wire [5:0] childBd_6_array;
  wire [23:0] childBd_6_rdata;
  wire childBd_6_re;
  wire childBd_6_selectedOH;
  wire [23:0] childBd_6_wdata;
  wire childBd_6_we;
  wire [1:0] childBd_6_wmask;
  wire childBd_7_ack;
  wire [9:0] childBd_7_addr;
  wire [9:0] childBd_7_addr_rd;
  wire [5:0] childBd_7_array;
  wire [23:0] childBd_7_rdata;
  wire childBd_7_re;
  wire childBd_7_selectedOH;
  wire [23:0] childBd_7_wdata;
  wire childBd_7_we;
  wire [1:0] childBd_7_wmask;
  wire childBd_8_ack;
  wire [9:0] childBd_8_addr;
  wire [9:0] childBd_8_addr_rd;
  wire [5:0] childBd_8_array;
  wire [23:0] childBd_8_rdata;
  wire childBd_8_re;
  wire childBd_8_selectedOH;
  wire [23:0] childBd_8_wdata;
  wire childBd_8_we;
  wire [1:0] childBd_8_wmask;
  wire childBd_9_ack;
  wire [9:0] childBd_9_addr;
  wire [9:0] childBd_9_addr_rd;
  wire [5:0] childBd_9_array;
  wire [23:0] childBd_9_rdata;
  wire childBd_9_re;
  wire childBd_9_selectedOH;
  wire [23:0] childBd_9_wdata;
  wire childBd_9_we;
  wire [1:0] childBd_9_wmask;
  wire childBd_10_ack;
  wire [8:0] childBd_10_addr;
  wire [8:0] childBd_10_addr_rd;
  wire [5:0] childBd_10_array;
  wire [15:0] childBd_10_rdata;
  wire childBd_10_re;
  wire childBd_10_selectedOH;
  wire [15:0] childBd_10_wdata;
  wire childBd_10_we;
  wire [15:0] childBd_10_wmask;
  wire childBd_11_ack;
  wire [9:0] childBd_11_addr;
  wire [9:0] childBd_11_addr_rd;
  wire [5:0] childBd_11_array;
  wire [23:0] childBd_11_rdata;
  wire childBd_11_re;
  wire childBd_11_selectedOH;
  wire [23:0] childBd_11_wdata;
  wire childBd_11_we;
  wire [1:0] childBd_11_wmask;
  wire childBd_12_ack;
  wire [9:0] childBd_12_addr;
  wire [9:0] childBd_12_addr_rd;
  wire [5:0] childBd_12_array;
  wire [23:0] childBd_12_rdata;
  wire childBd_12_re;
  wire childBd_12_selectedOH;
  wire [23:0] childBd_12_wdata;
  wire childBd_12_we;
  wire [1:0] childBd_12_wmask;
  wire childBd_13_ack;
  wire [9:0] childBd_13_addr;
  wire [9:0] childBd_13_addr_rd;
  wire [5:0] childBd_13_array;
  wire [23:0] childBd_13_rdata;
  wire childBd_13_re;
  wire childBd_13_selectedOH;
  wire [23:0] childBd_13_wdata;
  wire childBd_13_we;
  wire [1:0] childBd_13_wmask;
  wire childBd_14_ack;
  wire [9:0] childBd_14_addr;
  wire [9:0] childBd_14_addr_rd;
  wire [5:0] childBd_14_array;
  wire [23:0] childBd_14_rdata;
  wire childBd_14_re;
  wire childBd_14_selectedOH;
  wire [23:0] childBd_14_wdata;
  wire childBd_14_we;
  wire [1:0] childBd_14_wmask;
  wire childBd_15_ack;
  wire [8:0] childBd_15_addr;
  wire [8:0] childBd_15_addr_rd;
  wire [5:0] childBd_15_array;
  wire [15:0] childBd_15_rdata;
  wire childBd_15_re;
  wire childBd_15_selectedOH;
  wire [15:0] childBd_15_wdata;
  wire childBd_15_we;
  wire [15:0] childBd_15_wmask;
  wire childBd_16_ack;
  wire [9:0] childBd_16_addr;
  wire [9:0] childBd_16_addr_rd;
  wire [5:0] childBd_16_array;
  wire [23:0] childBd_16_rdata;
  wire childBd_16_re;
  wire childBd_16_selectedOH;
  wire [23:0] childBd_16_wdata;
  wire childBd_16_we;
  wire [1:0] childBd_16_wmask;
  wire childBd_17_ack;
  wire [9:0] childBd_17_addr;
  wire [9:0] childBd_17_addr_rd;
  wire [5:0] childBd_17_array;
  wire [23:0] childBd_17_rdata;
  wire childBd_17_re;
  wire childBd_17_selectedOH;
  wire [23:0] childBd_17_wdata;
  wire childBd_17_we;
  wire [1:0] childBd_17_wmask;
  wire childBd_18_ack;
  wire [9:0] childBd_18_addr;
  wire [9:0] childBd_18_addr_rd;
  wire [5:0] childBd_18_array;
  wire [23:0] childBd_18_rdata;
  wire childBd_18_re;
  wire childBd_18_selectedOH;
  wire [23:0] childBd_18_wdata;
  wire childBd_18_we;
  wire [1:0] childBd_18_wmask;
  wire childBd_19_ack;
  wire [9:0] childBd_19_addr;
  wire [9:0] childBd_19_addr_rd;
  wire [5:0] childBd_19_array;
  wire [23:0] childBd_19_rdata;
  wire childBd_19_re;
  wire childBd_19_selectedOH;
  wire [23:0] childBd_19_wdata;
  wire childBd_19_we;
  wire [1:0] childBd_19_wmask;
  wire childBd_20_ack;
  wire [8:0] childBd_20_addr;
  wire [8:0] childBd_20_addr_rd;
  wire [6:0] childBd_20_array;
  wire [7:0] childBd_20_rdata;
  wire childBd_20_re;
  wire childBd_20_selectedOH;
  wire [7:0] childBd_20_wdata;
  wire childBd_20_we;
  wire [3:0] childBd_20_wmask;
  wire childBd_21_ack;
  wire [8:0] childBd_21_addr;
  wire [8:0] childBd_21_addr_rd;
  wire [6:0] childBd_21_array;
  wire [7:0] childBd_21_rdata;
  wire childBd_21_re;
  wire childBd_21_selectedOH;
  wire [7:0] childBd_21_wdata;
  wire childBd_21_we;
  wire [3:0] childBd_21_wmask;
  wire childBd_22_ack;
  wire [8:0] childBd_22_addr;
  wire [8:0] childBd_22_addr_rd;
  wire [6:0] childBd_22_array;
  wire [7:0] childBd_22_rdata;
  wire childBd_22_re;
  wire childBd_22_selectedOH;
  wire [7:0] childBd_22_wdata;
  wire childBd_22_we;
  wire [3:0] childBd_22_wmask;
  wire childBd_23_ack;
  wire [8:0] childBd_23_addr;
  wire [8:0] childBd_23_addr_rd;
  wire [6:0] childBd_23_array;
  wire [7:0] childBd_23_rdata;
  wire childBd_23_re;
  wire childBd_23_selectedOH;
  wire [7:0] childBd_23_wdata;
  wire childBd_23_we;
  wire [3:0] childBd_23_wmask;
  wire childBd_ack;
  wire [8:0] childBd_addr;
  wire [8:0] childBd_addr_rd;
  wire [5:0] childBd_array;
  wire [15:0] childBd_rdata;
  wire childBd_re;
  wire childBd_selectedOH;
  wire [15:0] childBd_wdata;
  wire childBd_we;
  wire [15:0] childBd_wmask;

  TageTable tables_0 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_req_ready                             (tbl_req_ready[0]),
    .io_req_valid                             (io_s0_fire_1),
    .io_req_bits_pc                           (io_in_bits_s0_pc_1),
    .io_req_bits_ghist                        (io_in_bits_ghist),
    .io_req_bits_folded_hist_hist_14_folded_hist (io_in_bits_folded_hist_1_hist_14_folded_hist),
    .io_req_bits_folded_hist_hist_7_folded_hist (io_in_bits_folded_hist_1_hist_7_folded_hist),
    .io_resps_0_valid                         (tbl_resp[0][0].valid),
    .io_resps_0_bits_ctr                      (tbl_resp[0][0].ctr),
    .io_resps_0_bits_u                        (tbl_resp[0][0].u),
    .io_resps_0_bits_unconf                   (tbl_resp[0][0].unconf),
    .io_resps_1_valid                         (tbl_resp[0][1].valid),
    .io_resps_1_bits_ctr                      (tbl_resp[0][1].ctr),
    .io_resps_1_bits_u                        (tbl_resp[0][1].u),
    .io_resps_1_bits_unconf                   (tbl_resp[0][1].unconf),
    .io_update_pc                             (tbl_upd_pc[0]),
    .io_update_ghist                          (tbl_upd_ghist[0]),
    .io_update_mask_0                         (tbl_upd[0].mask[0]),
    .io_update_mask_1                         (tbl_upd[0].mask[1]),
    .io_update_takens_0                       (tbl_upd[0].takens[0]),
    .io_update_takens_1                       (tbl_upd[0].takens[1]),
    .io_update_alloc_0                        (tbl_upd[0].alloc[0]),
    .io_update_alloc_1                        (tbl_upd[0].alloc[1]),
    .io_update_oldCtrs_0                      (tbl_upd[0].old_ctrs[0]),
    .io_update_oldCtrs_1                      (tbl_upd[0].old_ctrs[1]),
    .io_update_uMask_0                        (tbl_upd[0].u_mask[0]),
    .io_update_uMask_1                        (tbl_upd[0].u_mask[1]),
    .io_update_us_0                           (tbl_upd[0].us[0]),
    .io_update_us_1                           (tbl_upd[0].us[1]),
    .io_update_reset_u_0                      (tbl_upd[0].reset_u[0]),
    .io_update_reset_u_1                      (tbl_upd[0].reset_u[1]),
    .boreChildrenBd_bore_addr                 (childBd_addr),
    .boreChildrenBd_bore_addr_rd              (childBd_addr_rd),
    .boreChildrenBd_bore_wdata                (childBd_wdata),
    .boreChildrenBd_bore_wmask                (childBd_wmask),
    .boreChildrenBd_bore_re                   (childBd_re),
    .boreChildrenBd_bore_we                   (childBd_we),
    .boreChildrenBd_bore_rdata                (childBd_rdata),
    .boreChildrenBd_bore_ack                  (childBd_ack),
    .boreChildrenBd_bore_selectedOH           (childBd_selectedOH),
    .boreChildrenBd_bore_array                (childBd_array),
    .boreChildrenBd_bore_1_addr               (childBd_1_addr),
    .boreChildrenBd_bore_1_addr_rd            (childBd_1_addr_rd),
    .boreChildrenBd_bore_1_wdata              (childBd_1_wdata),
    .boreChildrenBd_bore_1_wmask              (childBd_1_wmask),
    .boreChildrenBd_bore_1_re                 (childBd_1_re),
    .boreChildrenBd_bore_1_we                 (childBd_1_we),
    .boreChildrenBd_bore_1_rdata              (childBd_1_rdata),
    .boreChildrenBd_bore_1_ack                (childBd_1_ack),
    .boreChildrenBd_bore_1_selectedOH         (childBd_1_selectedOH),
    .boreChildrenBd_bore_1_array              (childBd_1_array),
    .boreChildrenBd_bore_2_addr               (childBd_2_addr),
    .boreChildrenBd_bore_2_addr_rd            (childBd_2_addr_rd),
    .boreChildrenBd_bore_2_wdata              (childBd_2_wdata),
    .boreChildrenBd_bore_2_wmask              (childBd_2_wmask),
    .boreChildrenBd_bore_2_re                 (childBd_2_re),
    .boreChildrenBd_bore_2_we                 (childBd_2_we),
    .boreChildrenBd_bore_2_rdata              (childBd_2_rdata),
    .boreChildrenBd_bore_2_ack                (childBd_2_ack),
    .boreChildrenBd_bore_2_selectedOH         (childBd_2_selectedOH),
    .boreChildrenBd_bore_2_array              (childBd_2_array),
    .boreChildrenBd_bore_3_addr               (childBd_3_addr),
    .boreChildrenBd_bore_3_addr_rd            (childBd_3_addr_rd),
    .boreChildrenBd_bore_3_wdata              (childBd_3_wdata),
    .boreChildrenBd_bore_3_wmask              (childBd_3_wmask),
    .boreChildrenBd_bore_3_re                 (childBd_3_re),
    .boreChildrenBd_bore_3_we                 (childBd_3_we),
    .boreChildrenBd_bore_3_rdata              (childBd_3_rdata),
    .boreChildrenBd_bore_3_ack                (childBd_3_ack),
    .boreChildrenBd_bore_3_selectedOH         (childBd_3_selectedOH),
    .boreChildrenBd_bore_3_array              (childBd_3_array),
    .boreChildrenBd_bore_4_addr               (childBd_4_addr),
    .boreChildrenBd_bore_4_addr_rd            (childBd_4_addr_rd),
    .boreChildrenBd_bore_4_wdata              (childBd_4_wdata),
    .boreChildrenBd_bore_4_wmask              (childBd_4_wmask),
    .boreChildrenBd_bore_4_re                 (childBd_4_re),
    .boreChildrenBd_bore_4_we                 (childBd_4_we),
    .boreChildrenBd_bore_4_rdata              (childBd_4_rdata),
    .boreChildrenBd_bore_4_ack                (childBd_4_ack),
    .boreChildrenBd_bore_4_selectedOH         (childBd_4_selectedOH),
    .boreChildrenBd_bore_4_array              (childBd_4_array),
    .sigFromSrams_bore_ram_hold               (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass             (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken           (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk            (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp           (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold           (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen                   (sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold             (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass           (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken         (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk          (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp         (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold         (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                 (sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold             (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass           (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken         (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk          (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp         (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold         (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen                 (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold             (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass           (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken         (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk          (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp         (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold         (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen                 (sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold             (sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass           (sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken         (sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk          (sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp         (sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold         (sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen                 (sigFromSrams_bore_4_cgen)
  );
  TageTable_1 tables_1 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_req_ready                             (tbl_req_ready[1]),
    .io_req_valid                             (io_s0_fire_1),
    .io_req_bits_pc                           (io_in_bits_s0_pc_1),
    .io_req_bits_ghist                        (io_in_bits_ghist),
    .io_req_bits_folded_hist_hist_15_folded_hist (io_in_bits_folded_hist_1_hist_15_folded_hist),
    .io_req_bits_folded_hist_hist_4_folded_hist (io_in_bits_folded_hist_1_hist_4_folded_hist),
    .io_req_bits_folded_hist_hist_1_folded_hist (io_in_bits_folded_hist_1_hist_1_folded_hist),
    .io_resps_0_valid                         (tbl_resp[1][0].valid),
    .io_resps_0_bits_ctr                      (tbl_resp[1][0].ctr),
    .io_resps_0_bits_u                        (tbl_resp[1][0].u),
    .io_resps_0_bits_unconf                   (tbl_resp[1][0].unconf),
    .io_resps_1_valid                         (tbl_resp[1][1].valid),
    .io_resps_1_bits_ctr                      (tbl_resp[1][1].ctr),
    .io_resps_1_bits_u                        (tbl_resp[1][1].u),
    .io_resps_1_bits_unconf                   (tbl_resp[1][1].unconf),
    .io_update_pc                             (tbl_upd_pc[1]),
    .io_update_ghist                          (tbl_upd_ghist[1]),
    .io_update_mask_0                         (tbl_upd[1].mask[0]),
    .io_update_mask_1                         (tbl_upd[1].mask[1]),
    .io_update_takens_0                       (tbl_upd[1].takens[0]),
    .io_update_takens_1                       (tbl_upd[1].takens[1]),
    .io_update_alloc_0                        (tbl_upd[1].alloc[0]),
    .io_update_alloc_1                        (tbl_upd[1].alloc[1]),
    .io_update_oldCtrs_0                      (tbl_upd[1].old_ctrs[0]),
    .io_update_oldCtrs_1                      (tbl_upd[1].old_ctrs[1]),
    .io_update_uMask_0                        (tbl_upd[1].u_mask[0]),
    .io_update_uMask_1                        (tbl_upd[1].u_mask[1]),
    .io_update_us_0                           (tbl_upd[1].us[0]),
    .io_update_us_1                           (tbl_upd[1].us[1]),
    .io_update_reset_u_0                      (tbl_upd[1].reset_u[0]),
    .io_update_reset_u_1                      (tbl_upd[1].reset_u[1]),
    .boreChildrenBd_bore_addr                 (childBd_5_addr),
    .boreChildrenBd_bore_addr_rd              (childBd_5_addr_rd),
    .boreChildrenBd_bore_wdata                (childBd_5_wdata),
    .boreChildrenBd_bore_wmask                (childBd_5_wmask),
    .boreChildrenBd_bore_re                   (childBd_5_re),
    .boreChildrenBd_bore_we                   (childBd_5_we),
    .boreChildrenBd_bore_rdata                (childBd_5_rdata),
    .boreChildrenBd_bore_ack                  (childBd_5_ack),
    .boreChildrenBd_bore_selectedOH           (childBd_5_selectedOH),
    .boreChildrenBd_bore_array                (childBd_5_array),
    .boreChildrenBd_bore_1_addr               (childBd_6_addr),
    .boreChildrenBd_bore_1_addr_rd            (childBd_6_addr_rd),
    .boreChildrenBd_bore_1_wdata              (childBd_6_wdata),
    .boreChildrenBd_bore_1_wmask              (childBd_6_wmask),
    .boreChildrenBd_bore_1_re                 (childBd_6_re),
    .boreChildrenBd_bore_1_we                 (childBd_6_we),
    .boreChildrenBd_bore_1_rdata              (childBd_6_rdata),
    .boreChildrenBd_bore_1_ack                (childBd_6_ack),
    .boreChildrenBd_bore_1_selectedOH         (childBd_6_selectedOH),
    .boreChildrenBd_bore_1_array              (childBd_6_array),
    .boreChildrenBd_bore_2_addr               (childBd_7_addr),
    .boreChildrenBd_bore_2_addr_rd            (childBd_7_addr_rd),
    .boreChildrenBd_bore_2_wdata              (childBd_7_wdata),
    .boreChildrenBd_bore_2_wmask              (childBd_7_wmask),
    .boreChildrenBd_bore_2_re                 (childBd_7_re),
    .boreChildrenBd_bore_2_we                 (childBd_7_we),
    .boreChildrenBd_bore_2_rdata              (childBd_7_rdata),
    .boreChildrenBd_bore_2_ack                (childBd_7_ack),
    .boreChildrenBd_bore_2_selectedOH         (childBd_7_selectedOH),
    .boreChildrenBd_bore_2_array              (childBd_7_array),
    .boreChildrenBd_bore_3_addr               (childBd_8_addr),
    .boreChildrenBd_bore_3_addr_rd            (childBd_8_addr_rd),
    .boreChildrenBd_bore_3_wdata              (childBd_8_wdata),
    .boreChildrenBd_bore_3_wmask              (childBd_8_wmask),
    .boreChildrenBd_bore_3_re                 (childBd_8_re),
    .boreChildrenBd_bore_3_we                 (childBd_8_we),
    .boreChildrenBd_bore_3_rdata              (childBd_8_rdata),
    .boreChildrenBd_bore_3_ack                (childBd_8_ack),
    .boreChildrenBd_bore_3_selectedOH         (childBd_8_selectedOH),
    .boreChildrenBd_bore_3_array              (childBd_8_array),
    .boreChildrenBd_bore_4_addr               (childBd_9_addr),
    .boreChildrenBd_bore_4_addr_rd            (childBd_9_addr_rd),
    .boreChildrenBd_bore_4_wdata              (childBd_9_wdata),
    .boreChildrenBd_bore_4_wmask              (childBd_9_wmask),
    .boreChildrenBd_bore_4_re                 (childBd_9_re),
    .boreChildrenBd_bore_4_we                 (childBd_9_we),
    .boreChildrenBd_bore_4_rdata              (childBd_9_rdata),
    .boreChildrenBd_bore_4_ack                (childBd_9_ack),
    .boreChildrenBd_bore_4_selectedOH         (childBd_9_selectedOH),
    .boreChildrenBd_bore_4_array              (childBd_9_array),
    .sigFromSrams_bore_ram_hold               (sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_ram_bypass             (sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken           (sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk            (sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp           (sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold           (sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_cgen                   (sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_1_ram_hold             (sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_1_ram_bypass           (sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken         (sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk          (sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp         (sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold         (sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                 (sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_2_ram_hold             (sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_2_ram_bypass           (sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken         (sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk          (sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp         (sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold         (sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen                 (sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_3_ram_hold             (sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_3_ram_bypass           (sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken         (sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk          (sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp         (sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold         (sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen                 (sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_4_ram_hold             (sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_4_ram_bypass           (sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken         (sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk          (sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp         (sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold         (sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen                 (sigFromSrams_bore_9_cgen)
  );
  TageTable_2 tables_2 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_req_ready                             (tbl_req_ready[2]),
    .io_req_valid                             (io_s0_fire_1),
    .io_req_bits_pc                           (io_in_bits_s0_pc_1),
    .io_req_bits_ghist                        (io_in_bits_ghist),
    .io_req_bits_folded_hist_hist_17_folded_hist (io_in_bits_folded_hist_1_hist_17_folded_hist),
    .io_req_bits_folded_hist_hist_9_folded_hist (io_in_bits_folded_hist_1_hist_9_folded_hist),
    .io_req_bits_folded_hist_hist_3_folded_hist (io_in_bits_folded_hist_1_hist_3_folded_hist),
    .io_resps_0_valid                         (tbl_resp[2][0].valid),
    .io_resps_0_bits_ctr                      (tbl_resp[2][0].ctr),
    .io_resps_0_bits_u                        (tbl_resp[2][0].u),
    .io_resps_0_bits_unconf                   (tbl_resp[2][0].unconf),
    .io_resps_1_valid                         (tbl_resp[2][1].valid),
    .io_resps_1_bits_ctr                      (tbl_resp[2][1].ctr),
    .io_resps_1_bits_u                        (tbl_resp[2][1].u),
    .io_resps_1_bits_unconf                   (tbl_resp[2][1].unconf),
    .io_update_pc                             (tbl_upd_pc[2]),
    .io_update_ghist                          (tbl_upd_ghist[2]),
    .io_update_mask_0                         (tbl_upd[2].mask[0]),
    .io_update_mask_1                         (tbl_upd[2].mask[1]),
    .io_update_takens_0                       (tbl_upd[2].takens[0]),
    .io_update_takens_1                       (tbl_upd[2].takens[1]),
    .io_update_alloc_0                        (tbl_upd[2].alloc[0]),
    .io_update_alloc_1                        (tbl_upd[2].alloc[1]),
    .io_update_oldCtrs_0                      (tbl_upd[2].old_ctrs[0]),
    .io_update_oldCtrs_1                      (tbl_upd[2].old_ctrs[1]),
    .io_update_uMask_0                        (tbl_upd[2].u_mask[0]),
    .io_update_uMask_1                        (tbl_upd[2].u_mask[1]),
    .io_update_us_0                           (tbl_upd[2].us[0]),
    .io_update_us_1                           (tbl_upd[2].us[1]),
    .io_update_reset_u_0                      (tbl_upd[2].reset_u[0]),
    .io_update_reset_u_1                      (tbl_upd[2].reset_u[1]),
    .boreChildrenBd_bore_addr                 (childBd_10_addr),
    .boreChildrenBd_bore_addr_rd              (childBd_10_addr_rd),
    .boreChildrenBd_bore_wdata                (childBd_10_wdata),
    .boreChildrenBd_bore_wmask                (childBd_10_wmask),
    .boreChildrenBd_bore_re                   (childBd_10_re),
    .boreChildrenBd_bore_we                   (childBd_10_we),
    .boreChildrenBd_bore_rdata                (childBd_10_rdata),
    .boreChildrenBd_bore_ack                  (childBd_10_ack),
    .boreChildrenBd_bore_selectedOH           (childBd_10_selectedOH),
    .boreChildrenBd_bore_array                (childBd_10_array),
    .boreChildrenBd_bore_1_addr               (childBd_11_addr),
    .boreChildrenBd_bore_1_addr_rd            (childBd_11_addr_rd),
    .boreChildrenBd_bore_1_wdata              (childBd_11_wdata),
    .boreChildrenBd_bore_1_wmask              (childBd_11_wmask),
    .boreChildrenBd_bore_1_re                 (childBd_11_re),
    .boreChildrenBd_bore_1_we                 (childBd_11_we),
    .boreChildrenBd_bore_1_rdata              (childBd_11_rdata),
    .boreChildrenBd_bore_1_ack                (childBd_11_ack),
    .boreChildrenBd_bore_1_selectedOH         (childBd_11_selectedOH),
    .boreChildrenBd_bore_1_array              (childBd_11_array),
    .boreChildrenBd_bore_2_addr               (childBd_12_addr),
    .boreChildrenBd_bore_2_addr_rd            (childBd_12_addr_rd),
    .boreChildrenBd_bore_2_wdata              (childBd_12_wdata),
    .boreChildrenBd_bore_2_wmask              (childBd_12_wmask),
    .boreChildrenBd_bore_2_re                 (childBd_12_re),
    .boreChildrenBd_bore_2_we                 (childBd_12_we),
    .boreChildrenBd_bore_2_rdata              (childBd_12_rdata),
    .boreChildrenBd_bore_2_ack                (childBd_12_ack),
    .boreChildrenBd_bore_2_selectedOH         (childBd_12_selectedOH),
    .boreChildrenBd_bore_2_array              (childBd_12_array),
    .boreChildrenBd_bore_3_addr               (childBd_13_addr),
    .boreChildrenBd_bore_3_addr_rd            (childBd_13_addr_rd),
    .boreChildrenBd_bore_3_wdata              (childBd_13_wdata),
    .boreChildrenBd_bore_3_wmask              (childBd_13_wmask),
    .boreChildrenBd_bore_3_re                 (childBd_13_re),
    .boreChildrenBd_bore_3_we                 (childBd_13_we),
    .boreChildrenBd_bore_3_rdata              (childBd_13_rdata),
    .boreChildrenBd_bore_3_ack                (childBd_13_ack),
    .boreChildrenBd_bore_3_selectedOH         (childBd_13_selectedOH),
    .boreChildrenBd_bore_3_array              (childBd_13_array),
    .boreChildrenBd_bore_4_addr               (childBd_14_addr),
    .boreChildrenBd_bore_4_addr_rd            (childBd_14_addr_rd),
    .boreChildrenBd_bore_4_wdata              (childBd_14_wdata),
    .boreChildrenBd_bore_4_wmask              (childBd_14_wmask),
    .boreChildrenBd_bore_4_re                 (childBd_14_re),
    .boreChildrenBd_bore_4_we                 (childBd_14_we),
    .boreChildrenBd_bore_4_rdata              (childBd_14_rdata),
    .boreChildrenBd_bore_4_ack                (childBd_14_ack),
    .boreChildrenBd_bore_4_selectedOH         (childBd_14_selectedOH),
    .boreChildrenBd_bore_4_array              (childBd_14_array),
    .sigFromSrams_bore_ram_hold               (sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_ram_bypass             (sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken           (sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk            (sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp           (sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold           (sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_cgen                   (sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_1_ram_hold             (sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_1_ram_bypass           (sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken         (sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk          (sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp         (sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold         (sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                 (sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_2_ram_hold             (sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_2_ram_bypass           (sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken         (sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk          (sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp         (sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold         (sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen                 (sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_3_ram_hold             (sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_3_ram_bypass           (sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken         (sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk          (sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp         (sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold         (sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen                 (sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_4_ram_hold             (sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_4_ram_bypass           (sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken         (sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk          (sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp         (sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold         (sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen                 (sigFromSrams_bore_14_cgen)
  );
  TageTable_3 tables_3 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_req_ready                             (tbl_req_ready[3]),
    .io_req_valid                             (io_s0_fire_1),
    .io_req_bits_pc                           (io_in_bits_s0_pc_1),
    .io_req_bits_ghist                        (io_in_bits_ghist),
    .io_req_bits_folded_hist_hist_16_folded_hist (io_in_bits_folded_hist_1_hist_16_folded_hist),
    .io_req_bits_folded_hist_hist_8_folded_hist (io_in_bits_folded_hist_1_hist_8_folded_hist),
    .io_req_bits_folded_hist_hist_5_folded_hist (io_in_bits_folded_hist_1_hist_5_folded_hist),
    .io_resps_0_valid                         (tbl_resp[3][0].valid),
    .io_resps_0_bits_ctr                      (tbl_resp[3][0].ctr),
    .io_resps_0_bits_u                        (tbl_resp[3][0].u),
    .io_resps_0_bits_unconf                   (tbl_resp[3][0].unconf),
    .io_resps_1_valid                         (tbl_resp[3][1].valid),
    .io_resps_1_bits_ctr                      (tbl_resp[3][1].ctr),
    .io_resps_1_bits_u                        (tbl_resp[3][1].u),
    .io_resps_1_bits_unconf                   (tbl_resp[3][1].unconf),
    .io_update_pc                             (tbl_upd_pc[3]),
    .io_update_ghist                          (tbl_upd_ghist[3]),
    .io_update_mask_0                         (tbl_upd[3].mask[0]),
    .io_update_mask_1                         (tbl_upd[3].mask[1]),
    .io_update_takens_0                       (tbl_upd[3].takens[0]),
    .io_update_takens_1                       (tbl_upd[3].takens[1]),
    .io_update_alloc_0                        (tbl_upd[3].alloc[0]),
    .io_update_alloc_1                        (tbl_upd[3].alloc[1]),
    .io_update_oldCtrs_0                      (tbl_upd[3].old_ctrs[0]),
    .io_update_oldCtrs_1                      (tbl_upd[3].old_ctrs[1]),
    .io_update_uMask_0                        (tbl_upd[3].u_mask[0]),
    .io_update_uMask_1                        (tbl_upd[3].u_mask[1]),
    .io_update_us_0                           (tbl_upd[3].us[0]),
    .io_update_us_1                           (tbl_upd[3].us[1]),
    .io_update_reset_u_0                      (tbl_upd[3].reset_u[0]),
    .io_update_reset_u_1                      (tbl_upd[3].reset_u[1]),
    .boreChildrenBd_bore_addr                 (childBd_15_addr),
    .boreChildrenBd_bore_addr_rd              (childBd_15_addr_rd),
    .boreChildrenBd_bore_wdata                (childBd_15_wdata),
    .boreChildrenBd_bore_wmask                (childBd_15_wmask),
    .boreChildrenBd_bore_re                   (childBd_15_re),
    .boreChildrenBd_bore_we                   (childBd_15_we),
    .boreChildrenBd_bore_rdata                (childBd_15_rdata),
    .boreChildrenBd_bore_ack                  (childBd_15_ack),
    .boreChildrenBd_bore_selectedOH           (childBd_15_selectedOH),
    .boreChildrenBd_bore_array                (childBd_15_array),
    .boreChildrenBd_bore_1_addr               (childBd_16_addr),
    .boreChildrenBd_bore_1_addr_rd            (childBd_16_addr_rd),
    .boreChildrenBd_bore_1_wdata              (childBd_16_wdata),
    .boreChildrenBd_bore_1_wmask              (childBd_16_wmask),
    .boreChildrenBd_bore_1_re                 (childBd_16_re),
    .boreChildrenBd_bore_1_we                 (childBd_16_we),
    .boreChildrenBd_bore_1_rdata              (childBd_16_rdata),
    .boreChildrenBd_bore_1_ack                (childBd_16_ack),
    .boreChildrenBd_bore_1_selectedOH         (childBd_16_selectedOH),
    .boreChildrenBd_bore_1_array              (childBd_16_array),
    .boreChildrenBd_bore_2_addr               (childBd_17_addr),
    .boreChildrenBd_bore_2_addr_rd            (childBd_17_addr_rd),
    .boreChildrenBd_bore_2_wdata              (childBd_17_wdata),
    .boreChildrenBd_bore_2_wmask              (childBd_17_wmask),
    .boreChildrenBd_bore_2_re                 (childBd_17_re),
    .boreChildrenBd_bore_2_we                 (childBd_17_we),
    .boreChildrenBd_bore_2_rdata              (childBd_17_rdata),
    .boreChildrenBd_bore_2_ack                (childBd_17_ack),
    .boreChildrenBd_bore_2_selectedOH         (childBd_17_selectedOH),
    .boreChildrenBd_bore_2_array              (childBd_17_array),
    .boreChildrenBd_bore_3_addr               (childBd_18_addr),
    .boreChildrenBd_bore_3_addr_rd            (childBd_18_addr_rd),
    .boreChildrenBd_bore_3_wdata              (childBd_18_wdata),
    .boreChildrenBd_bore_3_wmask              (childBd_18_wmask),
    .boreChildrenBd_bore_3_re                 (childBd_18_re),
    .boreChildrenBd_bore_3_we                 (childBd_18_we),
    .boreChildrenBd_bore_3_rdata              (childBd_18_rdata),
    .boreChildrenBd_bore_3_ack                (childBd_18_ack),
    .boreChildrenBd_bore_3_selectedOH         (childBd_18_selectedOH),
    .boreChildrenBd_bore_3_array              (childBd_18_array),
    .boreChildrenBd_bore_4_addr               (childBd_19_addr),
    .boreChildrenBd_bore_4_addr_rd            (childBd_19_addr_rd),
    .boreChildrenBd_bore_4_wdata              (childBd_19_wdata),
    .boreChildrenBd_bore_4_wmask              (childBd_19_wmask),
    .boreChildrenBd_bore_4_re                 (childBd_19_re),
    .boreChildrenBd_bore_4_we                 (childBd_19_we),
    .boreChildrenBd_bore_4_rdata              (childBd_19_rdata),
    .boreChildrenBd_bore_4_ack                (childBd_19_ack),
    .boreChildrenBd_bore_4_selectedOH         (childBd_19_selectedOH),
    .boreChildrenBd_bore_4_array              (childBd_19_array),
    .sigFromSrams_bore_ram_hold               (sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_ram_bypass             (sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken           (sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk            (sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp           (sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold           (sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_cgen                   (sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_1_ram_hold             (sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_1_ram_bypass           (sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken         (sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk          (sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp         (sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold         (sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                 (sigFromSrams_bore_16_cgen),
    .sigFromSrams_bore_2_ram_hold             (sigFromSrams_bore_17_ram_hold),
    .sigFromSrams_bore_2_ram_bypass           (sigFromSrams_bore_17_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken         (sigFromSrams_bore_17_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk          (sigFromSrams_bore_17_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp         (sigFromSrams_bore_17_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold         (sigFromSrams_bore_17_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen                 (sigFromSrams_bore_17_cgen),
    .sigFromSrams_bore_3_ram_hold             (sigFromSrams_bore_18_ram_hold),
    .sigFromSrams_bore_3_ram_bypass           (sigFromSrams_bore_18_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken         (sigFromSrams_bore_18_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk          (sigFromSrams_bore_18_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp         (sigFromSrams_bore_18_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold         (sigFromSrams_bore_18_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen                 (sigFromSrams_bore_18_cgen),
    .sigFromSrams_bore_4_ram_hold             (sigFromSrams_bore_19_ram_hold),
    .sigFromSrams_bore_4_ram_bypass           (sigFromSrams_bore_19_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken         (sigFromSrams_bore_19_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk          (sigFromSrams_bore_19_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp         (sigFromSrams_bore_19_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold         (sigFromSrams_bore_19_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen                 (sigFromSrams_bore_19_cgen)
  );
  TageBTable bt (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_req_ready                             (bt_req_ready),
    .io_req_valid                             (io_s0_fire_1),
    .io_req_bits                              (io_in_bits_s0_pc_1),
    .io_s1_cnt_0                              (bt_s1_cnt[0]),
    .io_s1_cnt_1                              (bt_s1_cnt[1]),
    .io_s1_resp_valid                         (bt_s1_resp_valid),
    .io_update_mask_0                         (bt_upd.mask[0]),
    .io_update_mask_1                         (bt_upd.mask[1]),
    .io_update_pc                             (bt_upd_pc),
    .io_update_cnt_0                          (bt_upd.cnt[0]),
    .io_update_cnt_1                          (bt_upd.cnt[1]),
    .io_update_takens_0                       (bt_upd.takens[0]),
    .io_update_takens_1                       (bt_upd.takens[1]),
    .boreChildrenBd_bore_addr                 (childBd_20_addr),
    .boreChildrenBd_bore_addr_rd              (childBd_20_addr_rd),
    .boreChildrenBd_bore_wdata                (childBd_20_wdata),
    .boreChildrenBd_bore_wmask                (childBd_20_wmask),
    .boreChildrenBd_bore_re                   (childBd_20_re),
    .boreChildrenBd_bore_we                   (childBd_20_we),
    .boreChildrenBd_bore_rdata                (childBd_20_rdata),
    .boreChildrenBd_bore_ack                  (childBd_20_ack),
    .boreChildrenBd_bore_selectedOH           (childBd_20_selectedOH),
    .boreChildrenBd_bore_array                (childBd_20_array),
    .boreChildrenBd_bore_1_addr               (childBd_21_addr),
    .boreChildrenBd_bore_1_addr_rd            (childBd_21_addr_rd),
    .boreChildrenBd_bore_1_wdata              (childBd_21_wdata),
    .boreChildrenBd_bore_1_wmask              (childBd_21_wmask),
    .boreChildrenBd_bore_1_re                 (childBd_21_re),
    .boreChildrenBd_bore_1_we                 (childBd_21_we),
    .boreChildrenBd_bore_1_rdata              (childBd_21_rdata),
    .boreChildrenBd_bore_1_ack                (childBd_21_ack),
    .boreChildrenBd_bore_1_selectedOH         (childBd_21_selectedOH),
    .boreChildrenBd_bore_1_array              (childBd_21_array),
    .boreChildrenBd_bore_2_addr               (childBd_22_addr),
    .boreChildrenBd_bore_2_addr_rd            (childBd_22_addr_rd),
    .boreChildrenBd_bore_2_wdata              (childBd_22_wdata),
    .boreChildrenBd_bore_2_wmask              (childBd_22_wmask),
    .boreChildrenBd_bore_2_re                 (childBd_22_re),
    .boreChildrenBd_bore_2_we                 (childBd_22_we),
    .boreChildrenBd_bore_2_rdata              (childBd_22_rdata),
    .boreChildrenBd_bore_2_ack                (childBd_22_ack),
    .boreChildrenBd_bore_2_selectedOH         (childBd_22_selectedOH),
    .boreChildrenBd_bore_2_array              (childBd_22_array),
    .boreChildrenBd_bore_3_addr               (childBd_23_addr),
    .boreChildrenBd_bore_3_addr_rd            (childBd_23_addr_rd),
    .boreChildrenBd_bore_3_wdata              (childBd_23_wdata),
    .boreChildrenBd_bore_3_wmask              (childBd_23_wmask),
    .boreChildrenBd_bore_3_re                 (childBd_23_re),
    .boreChildrenBd_bore_3_we                 (childBd_23_we),
    .boreChildrenBd_bore_3_rdata              (childBd_23_rdata),
    .boreChildrenBd_bore_3_ack                (childBd_23_ack),
    .boreChildrenBd_bore_3_selectedOH         (childBd_23_selectedOH),
    .boreChildrenBd_bore_3_array              (childBd_23_array),
    .sigFromSrams_bore_ram_hold               (sigFromSrams_bore_20_ram_hold),
    .sigFromSrams_bore_ram_bypass             (sigFromSrams_bore_20_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken           (sigFromSrams_bore_20_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk            (sigFromSrams_bore_20_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp           (sigFromSrams_bore_20_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold           (sigFromSrams_bore_20_ram_mcp_hold),
    .sigFromSrams_bore_cgen                   (sigFromSrams_bore_20_cgen),
    .sigFromSrams_bore_1_ram_hold             (sigFromSrams_bore_21_ram_hold),
    .sigFromSrams_bore_1_ram_bypass           (sigFromSrams_bore_21_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken         (sigFromSrams_bore_21_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk          (sigFromSrams_bore_21_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp         (sigFromSrams_bore_21_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold         (sigFromSrams_bore_21_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                 (sigFromSrams_bore_21_cgen),
    .sigFromSrams_bore_2_ram_hold             (sigFromSrams_bore_22_ram_hold),
    .sigFromSrams_bore_2_ram_bypass           (sigFromSrams_bore_22_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken         (sigFromSrams_bore_22_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk          (sigFromSrams_bore_22_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp         (sigFromSrams_bore_22_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold         (sigFromSrams_bore_22_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen                 (sigFromSrams_bore_22_cgen),
    .sigFromSrams_bore_3_ram_hold             (sigFromSrams_bore_23_ram_hold),
    .sigFromSrams_bore_3_ram_bypass           (sigFromSrams_bore_23_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken         (sigFromSrams_bore_23_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk          (sigFromSrams_bore_23_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp         (sigFromSrams_bore_23_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold         (sigFromSrams_bore_23_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen                 (sigFromSrams_bore_23_cgen)
  );
  MbistPipeTage mbistPl (
    .clock                                    (clock),
    .reset                                    (reset),
    .mbist_array                              (boreChildrenBd_bore_array),
    .mbist_all                                (boreChildrenBd_bore_all),
    .mbist_req                                (boreChildrenBd_bore_req),
    .mbist_ack                                (boreChildrenBd_bore_ack),
    .mbist_writeen                            (boreChildrenBd_bore_writeen),
    .mbist_be                                 (boreChildrenBd_bore_be),
    .mbist_addr                               (boreChildrenBd_bore_addr),
    .mbist_indata                             (boreChildrenBd_bore_indata),
    .mbist_readen                             (boreChildrenBd_bore_readen),
    .mbist_addr_rd                            (boreChildrenBd_bore_addr_rd),
    .mbist_outdata                            (boreChildrenBd_bore_outdata),
    .toSRAM_0_addr                            (childBd_addr),
    .toSRAM_0_addr_rd                         (childBd_addr_rd),
    .toSRAM_0_wdata                           (childBd_wdata),
    .toSRAM_0_wmask                           (childBd_wmask),
    .toSRAM_0_re                              (childBd_re),
    .toSRAM_0_we                              (childBd_we),
    .toSRAM_0_rdata                           (childBd_rdata),
    .toSRAM_0_ack                             (childBd_ack),
    .toSRAM_0_selectedOH                      (childBd_selectedOH),
    .toSRAM_0_array                           (childBd_array),
    .toSRAM_1_addr                            (childBd_1_addr),
    .toSRAM_1_addr_rd                         (childBd_1_addr_rd),
    .toSRAM_1_wdata                           (childBd_1_wdata),
    .toSRAM_1_wmask                           (childBd_1_wmask),
    .toSRAM_1_re                              (childBd_1_re),
    .toSRAM_1_we                              (childBd_1_we),
    .toSRAM_1_rdata                           (childBd_1_rdata),
    .toSRAM_1_ack                             (childBd_1_ack),
    .toSRAM_1_selectedOH                      (childBd_1_selectedOH),
    .toSRAM_1_array                           (childBd_1_array),
    .toSRAM_2_addr                            (childBd_2_addr),
    .toSRAM_2_addr_rd                         (childBd_2_addr_rd),
    .toSRAM_2_wdata                           (childBd_2_wdata),
    .toSRAM_2_wmask                           (childBd_2_wmask),
    .toSRAM_2_re                              (childBd_2_re),
    .toSRAM_2_we                              (childBd_2_we),
    .toSRAM_2_rdata                           (childBd_2_rdata),
    .toSRAM_2_ack                             (childBd_2_ack),
    .toSRAM_2_selectedOH                      (childBd_2_selectedOH),
    .toSRAM_2_array                           (childBd_2_array),
    .toSRAM_3_addr                            (childBd_3_addr),
    .toSRAM_3_addr_rd                         (childBd_3_addr_rd),
    .toSRAM_3_wdata                           (childBd_3_wdata),
    .toSRAM_3_wmask                           (childBd_3_wmask),
    .toSRAM_3_re                              (childBd_3_re),
    .toSRAM_3_we                              (childBd_3_we),
    .toSRAM_3_rdata                           (childBd_3_rdata),
    .toSRAM_3_ack                             (childBd_3_ack),
    .toSRAM_3_selectedOH                      (childBd_3_selectedOH),
    .toSRAM_3_array                           (childBd_3_array),
    .toSRAM_4_addr                            (childBd_4_addr),
    .toSRAM_4_addr_rd                         (childBd_4_addr_rd),
    .toSRAM_4_wdata                           (childBd_4_wdata),
    .toSRAM_4_wmask                           (childBd_4_wmask),
    .toSRAM_4_re                              (childBd_4_re),
    .toSRAM_4_we                              (childBd_4_we),
    .toSRAM_4_rdata                           (childBd_4_rdata),
    .toSRAM_4_ack                             (childBd_4_ack),
    .toSRAM_4_selectedOH                      (childBd_4_selectedOH),
    .toSRAM_4_array                           (childBd_4_array),
    .toSRAM_5_addr                            (childBd_5_addr),
    .toSRAM_5_addr_rd                         (childBd_5_addr_rd),
    .toSRAM_5_wdata                           (childBd_5_wdata),
    .toSRAM_5_wmask                           (childBd_5_wmask),
    .toSRAM_5_re                              (childBd_5_re),
    .toSRAM_5_we                              (childBd_5_we),
    .toSRAM_5_rdata                           (childBd_5_rdata),
    .toSRAM_5_ack                             (childBd_5_ack),
    .toSRAM_5_selectedOH                      (childBd_5_selectedOH),
    .toSRAM_5_array                           (childBd_5_array),
    .toSRAM_6_addr                            (childBd_6_addr),
    .toSRAM_6_addr_rd                         (childBd_6_addr_rd),
    .toSRAM_6_wdata                           (childBd_6_wdata),
    .toSRAM_6_wmask                           (childBd_6_wmask),
    .toSRAM_6_re                              (childBd_6_re),
    .toSRAM_6_we                              (childBd_6_we),
    .toSRAM_6_rdata                           (childBd_6_rdata),
    .toSRAM_6_ack                             (childBd_6_ack),
    .toSRAM_6_selectedOH                      (childBd_6_selectedOH),
    .toSRAM_6_array                           (childBd_6_array),
    .toSRAM_7_addr                            (childBd_7_addr),
    .toSRAM_7_addr_rd                         (childBd_7_addr_rd),
    .toSRAM_7_wdata                           (childBd_7_wdata),
    .toSRAM_7_wmask                           (childBd_7_wmask),
    .toSRAM_7_re                              (childBd_7_re),
    .toSRAM_7_we                              (childBd_7_we),
    .toSRAM_7_rdata                           (childBd_7_rdata),
    .toSRAM_7_ack                             (childBd_7_ack),
    .toSRAM_7_selectedOH                      (childBd_7_selectedOH),
    .toSRAM_7_array                           (childBd_7_array),
    .toSRAM_8_addr                            (childBd_8_addr),
    .toSRAM_8_addr_rd                         (childBd_8_addr_rd),
    .toSRAM_8_wdata                           (childBd_8_wdata),
    .toSRAM_8_wmask                           (childBd_8_wmask),
    .toSRAM_8_re                              (childBd_8_re),
    .toSRAM_8_we                              (childBd_8_we),
    .toSRAM_8_rdata                           (childBd_8_rdata),
    .toSRAM_8_ack                             (childBd_8_ack),
    .toSRAM_8_selectedOH                      (childBd_8_selectedOH),
    .toSRAM_8_array                           (childBd_8_array),
    .toSRAM_9_addr                            (childBd_9_addr),
    .toSRAM_9_addr_rd                         (childBd_9_addr_rd),
    .toSRAM_9_wdata                           (childBd_9_wdata),
    .toSRAM_9_wmask                           (childBd_9_wmask),
    .toSRAM_9_re                              (childBd_9_re),
    .toSRAM_9_we                              (childBd_9_we),
    .toSRAM_9_rdata                           (childBd_9_rdata),
    .toSRAM_9_ack                             (childBd_9_ack),
    .toSRAM_9_selectedOH                      (childBd_9_selectedOH),
    .toSRAM_9_array                           (childBd_9_array),
    .toSRAM_10_addr                           (childBd_10_addr),
    .toSRAM_10_addr_rd                        (childBd_10_addr_rd),
    .toSRAM_10_wdata                          (childBd_10_wdata),
    .toSRAM_10_wmask                          (childBd_10_wmask),
    .toSRAM_10_re                             (childBd_10_re),
    .toSRAM_10_we                             (childBd_10_we),
    .toSRAM_10_rdata                          (childBd_10_rdata),
    .toSRAM_10_ack                            (childBd_10_ack),
    .toSRAM_10_selectedOH                     (childBd_10_selectedOH),
    .toSRAM_10_array                          (childBd_10_array),
    .toSRAM_11_addr                           (childBd_11_addr),
    .toSRAM_11_addr_rd                        (childBd_11_addr_rd),
    .toSRAM_11_wdata                          (childBd_11_wdata),
    .toSRAM_11_wmask                          (childBd_11_wmask),
    .toSRAM_11_re                             (childBd_11_re),
    .toSRAM_11_we                             (childBd_11_we),
    .toSRAM_11_rdata                          (childBd_11_rdata),
    .toSRAM_11_ack                            (childBd_11_ack),
    .toSRAM_11_selectedOH                     (childBd_11_selectedOH),
    .toSRAM_11_array                          (childBd_11_array),
    .toSRAM_12_addr                           (childBd_12_addr),
    .toSRAM_12_addr_rd                        (childBd_12_addr_rd),
    .toSRAM_12_wdata                          (childBd_12_wdata),
    .toSRAM_12_wmask                          (childBd_12_wmask),
    .toSRAM_12_re                             (childBd_12_re),
    .toSRAM_12_we                             (childBd_12_we),
    .toSRAM_12_rdata                          (childBd_12_rdata),
    .toSRAM_12_ack                            (childBd_12_ack),
    .toSRAM_12_selectedOH                     (childBd_12_selectedOH),
    .toSRAM_12_array                          (childBd_12_array),
    .toSRAM_13_addr                           (childBd_13_addr),
    .toSRAM_13_addr_rd                        (childBd_13_addr_rd),
    .toSRAM_13_wdata                          (childBd_13_wdata),
    .toSRAM_13_wmask                          (childBd_13_wmask),
    .toSRAM_13_re                             (childBd_13_re),
    .toSRAM_13_we                             (childBd_13_we),
    .toSRAM_13_rdata                          (childBd_13_rdata),
    .toSRAM_13_ack                            (childBd_13_ack),
    .toSRAM_13_selectedOH                     (childBd_13_selectedOH),
    .toSRAM_13_array                          (childBd_13_array),
    .toSRAM_14_addr                           (childBd_14_addr),
    .toSRAM_14_addr_rd                        (childBd_14_addr_rd),
    .toSRAM_14_wdata                          (childBd_14_wdata),
    .toSRAM_14_wmask                          (childBd_14_wmask),
    .toSRAM_14_re                             (childBd_14_re),
    .toSRAM_14_we                             (childBd_14_we),
    .toSRAM_14_rdata                          (childBd_14_rdata),
    .toSRAM_14_ack                            (childBd_14_ack),
    .toSRAM_14_selectedOH                     (childBd_14_selectedOH),
    .toSRAM_14_array                          (childBd_14_array),
    .toSRAM_15_addr                           (childBd_15_addr),
    .toSRAM_15_addr_rd                        (childBd_15_addr_rd),
    .toSRAM_15_wdata                          (childBd_15_wdata),
    .toSRAM_15_wmask                          (childBd_15_wmask),
    .toSRAM_15_re                             (childBd_15_re),
    .toSRAM_15_we                             (childBd_15_we),
    .toSRAM_15_rdata                          (childBd_15_rdata),
    .toSRAM_15_ack                            (childBd_15_ack),
    .toSRAM_15_selectedOH                     (childBd_15_selectedOH),
    .toSRAM_15_array                          (childBd_15_array),
    .toSRAM_16_addr                           (childBd_16_addr),
    .toSRAM_16_addr_rd                        (childBd_16_addr_rd),
    .toSRAM_16_wdata                          (childBd_16_wdata),
    .toSRAM_16_wmask                          (childBd_16_wmask),
    .toSRAM_16_re                             (childBd_16_re),
    .toSRAM_16_we                             (childBd_16_we),
    .toSRAM_16_rdata                          (childBd_16_rdata),
    .toSRAM_16_ack                            (childBd_16_ack),
    .toSRAM_16_selectedOH                     (childBd_16_selectedOH),
    .toSRAM_16_array                          (childBd_16_array),
    .toSRAM_17_addr                           (childBd_17_addr),
    .toSRAM_17_addr_rd                        (childBd_17_addr_rd),
    .toSRAM_17_wdata                          (childBd_17_wdata),
    .toSRAM_17_wmask                          (childBd_17_wmask),
    .toSRAM_17_re                             (childBd_17_re),
    .toSRAM_17_we                             (childBd_17_we),
    .toSRAM_17_rdata                          (childBd_17_rdata),
    .toSRAM_17_ack                            (childBd_17_ack),
    .toSRAM_17_selectedOH                     (childBd_17_selectedOH),
    .toSRAM_17_array                          (childBd_17_array),
    .toSRAM_18_addr                           (childBd_18_addr),
    .toSRAM_18_addr_rd                        (childBd_18_addr_rd),
    .toSRAM_18_wdata                          (childBd_18_wdata),
    .toSRAM_18_wmask                          (childBd_18_wmask),
    .toSRAM_18_re                             (childBd_18_re),
    .toSRAM_18_we                             (childBd_18_we),
    .toSRAM_18_rdata                          (childBd_18_rdata),
    .toSRAM_18_ack                            (childBd_18_ack),
    .toSRAM_18_selectedOH                     (childBd_18_selectedOH),
    .toSRAM_18_array                          (childBd_18_array),
    .toSRAM_19_addr                           (childBd_19_addr),
    .toSRAM_19_addr_rd                        (childBd_19_addr_rd),
    .toSRAM_19_wdata                          (childBd_19_wdata),
    .toSRAM_19_wmask                          (childBd_19_wmask),
    .toSRAM_19_re                             (childBd_19_re),
    .toSRAM_19_we                             (childBd_19_we),
    .toSRAM_19_rdata                          (childBd_19_rdata),
    .toSRAM_19_ack                            (childBd_19_ack),
    .toSRAM_19_selectedOH                     (childBd_19_selectedOH),
    .toSRAM_19_array                          (childBd_19_array),
    .toSRAM_20_addr                           (childBd_20_addr),
    .toSRAM_20_addr_rd                        (childBd_20_addr_rd),
    .toSRAM_20_wdata                          (childBd_20_wdata),
    .toSRAM_20_wmask                          (childBd_20_wmask),
    .toSRAM_20_re                             (childBd_20_re),
    .toSRAM_20_we                             (childBd_20_we),
    .toSRAM_20_rdata                          (childBd_20_rdata),
    .toSRAM_20_ack                            (childBd_20_ack),
    .toSRAM_20_selectedOH                     (childBd_20_selectedOH),
    .toSRAM_20_array                          (childBd_20_array),
    .toSRAM_21_addr                           (childBd_21_addr),
    .toSRAM_21_addr_rd                        (childBd_21_addr_rd),
    .toSRAM_21_wdata                          (childBd_21_wdata),
    .toSRAM_21_wmask                          (childBd_21_wmask),
    .toSRAM_21_re                             (childBd_21_re),
    .toSRAM_21_we                             (childBd_21_we),
    .toSRAM_21_rdata                          (childBd_21_rdata),
    .toSRAM_21_ack                            (childBd_21_ack),
    .toSRAM_21_selectedOH                     (childBd_21_selectedOH),
    .toSRAM_21_array                          (childBd_21_array),
    .toSRAM_22_addr                           (childBd_22_addr),
    .toSRAM_22_addr_rd                        (childBd_22_addr_rd),
    .toSRAM_22_wdata                          (childBd_22_wdata),
    .toSRAM_22_wmask                          (childBd_22_wmask),
    .toSRAM_22_re                             (childBd_22_re),
    .toSRAM_22_we                             (childBd_22_we),
    .toSRAM_22_rdata                          (childBd_22_rdata),
    .toSRAM_22_ack                            (childBd_22_ack),
    .toSRAM_22_selectedOH                     (childBd_22_selectedOH),
    .toSRAM_22_array                          (childBd_22_array),
    .toSRAM_23_addr                           (childBd_23_addr),
    .toSRAM_23_addr_rd                        (childBd_23_addr_rd),
    .toSRAM_23_wdata                          (childBd_23_wdata),
    .toSRAM_23_wmask                          (childBd_23_wmask),
    .toSRAM_23_re                             (childBd_23_re),
    .toSRAM_23_we                             (childBd_23_we),
    .toSRAM_23_rdata                          (childBd_23_rdata),
    .toSRAM_23_ack                            (childBd_23_ack),
    .toSRAM_23_selectedOH                     (childBd_23_selectedOH),
    .toSRAM_23_array                          (childBd_23_array)
  );
  MaxPeriodFibonacciLFSR allocLFSR_prng (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_out_0                                 (lfsr_bits[0][0]),
    .io_out_1                                 (lfsr_bits[0][1]),
    .io_out_2                                 (lfsr_bits[0][2]),
    .io_out_3                                 (),
    .io_out_4                                 (),
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
  MaxPeriodFibonacciLFSR allocLFSR_prng_1 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_out_0                                 (lfsr_bits[1][0]),
    .io_out_1                                 (lfsr_bits[1][1]),
    .io_out_2                                 (lfsr_bits[1][2]),
    .io_out_3                                 (),
    .io_out_4                                 (),
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
  SCTable scTables_0 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_req_valid                             (io_s0_fire_3),
    .io_req_bits_pc                           (io_in_bits_s0_pc_3),
    .io_resp_ctrs_0_0                         (sc_resp[0][0][0]),
    .io_resp_ctrs_0_1                         (sc_resp[0][0][1]),
    .io_resp_ctrs_1_0                         (sc_resp[0][1][0]),
    .io_resp_ctrs_1_1                         (sc_resp[0][1][1]),
    .io_update_pc                             (sc_upd_pc[0]),
    .io_update_mask_0                         (sc_upd[0].mask[0]),
    .io_update_mask_1                         (sc_upd[0].mask[1]),
    .io_update_oldCtrs_0                      (sc_upd[0].old_ctrs[0]),
    .io_update_oldCtrs_1                      (sc_upd[0].old_ctrs[1]),
    .io_update_tagePreds_0                    (sc_upd[0].tage_preds[0]),
    .io_update_tagePreds_1                    (sc_upd[0].tage_preds[1]),
    .io_update_takens_0                       (sc_upd[0].takens[0]),
    .io_update_takens_1                       (sc_upd[0].takens[1]),
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
    .sigFromSrams_bore_ram_hold               (sigFromSrams_bore_24_ram_hold),
    .sigFromSrams_bore_ram_bypass             (sigFromSrams_bore_24_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken           (sigFromSrams_bore_24_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk            (sigFromSrams_bore_24_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp           (sigFromSrams_bore_24_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold           (sigFromSrams_bore_24_ram_mcp_hold),
    .sigFromSrams_bore_cgen                   (sigFromSrams_bore_24_cgen),
    .sigFromSrams_bore_1_ram_hold             (sigFromSrams_bore_25_ram_hold),
    .sigFromSrams_bore_1_ram_bypass           (sigFromSrams_bore_25_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken         (sigFromSrams_bore_25_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk          (sigFromSrams_bore_25_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp         (sigFromSrams_bore_25_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold         (sigFromSrams_bore_25_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                 (sigFromSrams_bore_25_cgen)
  );
  SCTable_1 scTables_1 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_req_valid                             (io_s0_fire_3),
    .io_req_bits_pc                           (io_in_bits_s0_pc_3),
    .io_req_bits_folded_hist_hist_12_folded_hist (io_in_bits_folded_hist_3_hist_12_folded_hist),
    .io_resp_ctrs_0_0                         (sc_resp[1][0][0]),
    .io_resp_ctrs_0_1                         (sc_resp[1][0][1]),
    .io_resp_ctrs_1_0                         (sc_resp[1][1][0]),
    .io_resp_ctrs_1_1                         (sc_resp[1][1][1]),
    .io_update_pc                             (sc_upd_pc[1]),
    .io_update_ghist                          (sc_upd_ghist[1]),
    .io_update_mask_0                         (sc_upd[1].mask[0]),
    .io_update_mask_1                         (sc_upd[1].mask[1]),
    .io_update_oldCtrs_0                      (sc_upd[1].old_ctrs[0]),
    .io_update_oldCtrs_1                      (sc_upd[1].old_ctrs[1]),
    .io_update_tagePreds_0                    (sc_upd[1].tage_preds[0]),
    .io_update_tagePreds_1                    (sc_upd[1].tage_preds[1]),
    .io_update_takens_0                       (sc_upd[1].takens[0]),
    .io_update_takens_1                       (sc_upd[1].takens[1]),
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
    .sigFromSrams_bore_ram_hold               (sigFromSrams_bore_26_ram_hold),
    .sigFromSrams_bore_ram_bypass             (sigFromSrams_bore_26_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken           (sigFromSrams_bore_26_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk            (sigFromSrams_bore_26_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp           (sigFromSrams_bore_26_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold           (sigFromSrams_bore_26_ram_mcp_hold),
    .sigFromSrams_bore_cgen                   (sigFromSrams_bore_26_cgen),
    .sigFromSrams_bore_1_ram_hold             (sigFromSrams_bore_27_ram_hold),
    .sigFromSrams_bore_1_ram_bypass           (sigFromSrams_bore_27_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken         (sigFromSrams_bore_27_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk          (sigFromSrams_bore_27_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp         (sigFromSrams_bore_27_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold         (sigFromSrams_bore_27_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                 (sigFromSrams_bore_27_cgen)
  );
  SCTable_2 scTables_2 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_req_valid                             (io_s0_fire_3),
    .io_req_bits_pc                           (io_in_bits_s0_pc_3),
    .io_req_bits_folded_hist_hist_11_folded_hist (io_in_bits_folded_hist_3_hist_11_folded_hist),
    .io_resp_ctrs_0_0                         (sc_resp[2][0][0]),
    .io_resp_ctrs_0_1                         (sc_resp[2][0][1]),
    .io_resp_ctrs_1_0                         (sc_resp[2][1][0]),
    .io_resp_ctrs_1_1                         (sc_resp[2][1][1]),
    .io_update_pc                             (sc_upd_pc[2]),
    .io_update_ghist                          (sc_upd_ghist[2]),
    .io_update_mask_0                         (sc_upd[2].mask[0]),
    .io_update_mask_1                         (sc_upd[2].mask[1]),
    .io_update_oldCtrs_0                      (sc_upd[2].old_ctrs[0]),
    .io_update_oldCtrs_1                      (sc_upd[2].old_ctrs[1]),
    .io_update_tagePreds_0                    (sc_upd[2].tage_preds[0]),
    .io_update_tagePreds_1                    (sc_upd[2].tage_preds[1]),
    .io_update_takens_0                       (sc_upd[2].takens[0]),
    .io_update_takens_1                       (sc_upd[2].takens[1]),
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
    .sigFromSrams_bore_ram_hold               (sigFromSrams_bore_28_ram_hold),
    .sigFromSrams_bore_ram_bypass             (sigFromSrams_bore_28_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken           (sigFromSrams_bore_28_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk            (sigFromSrams_bore_28_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp           (sigFromSrams_bore_28_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold           (sigFromSrams_bore_28_ram_mcp_hold),
    .sigFromSrams_bore_cgen                   (sigFromSrams_bore_28_cgen),
    .sigFromSrams_bore_1_ram_hold             (sigFromSrams_bore_29_ram_hold),
    .sigFromSrams_bore_1_ram_bypass           (sigFromSrams_bore_29_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken         (sigFromSrams_bore_29_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk          (sigFromSrams_bore_29_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp         (sigFromSrams_bore_29_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold         (sigFromSrams_bore_29_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                 (sigFromSrams_bore_29_cgen)
  );
  SCTable_3 scTables_3 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_req_valid                             (io_s0_fire_3),
    .io_req_bits_pc                           (io_in_bits_s0_pc_3),
    .io_req_bits_folded_hist_hist_2_folded_hist (io_in_bits_folded_hist_3_hist_2_folded_hist),
    .io_resp_ctrs_0_0                         (sc_resp[3][0][0]),
    .io_resp_ctrs_0_1                         (sc_resp[3][0][1]),
    .io_resp_ctrs_1_0                         (sc_resp[3][1][0]),
    .io_resp_ctrs_1_1                         (sc_resp[3][1][1]),
    .io_update_pc                             (sc_upd_pc[3]),
    .io_update_ghist                          (sc_upd_ghist[3]),
    .io_update_mask_0                         (sc_upd[3].mask[0]),
    .io_update_mask_1                         (sc_upd[3].mask[1]),
    .io_update_oldCtrs_0                      (sc_upd[3].old_ctrs[0]),
    .io_update_oldCtrs_1                      (sc_upd[3].old_ctrs[1]),
    .io_update_tagePreds_0                    (sc_upd[3].tage_preds[0]),
    .io_update_tagePreds_1                    (sc_upd[3].tage_preds[1]),
    .io_update_takens_0                       (sc_upd[3].takens[0]),
    .io_update_takens_1                       (sc_upd[3].takens[1]),
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
    .sigFromSrams_bore_ram_hold               (sigFromSrams_bore_30_ram_hold),
    .sigFromSrams_bore_ram_bypass             (sigFromSrams_bore_30_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken           (sigFromSrams_bore_30_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk            (sigFromSrams_bore_30_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp           (sigFromSrams_bore_30_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold           (sigFromSrams_bore_30_ram_mcp_hold),
    .sigFromSrams_bore_cgen                   (sigFromSrams_bore_30_cgen),
    .sigFromSrams_bore_1_ram_hold             (sigFromSrams_bore_31_ram_hold),
    .sigFromSrams_bore_1_ram_bypass           (sigFromSrams_bore_31_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken         (sigFromSrams_bore_31_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk          (sigFromSrams_bore_31_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp         (sigFromSrams_bore_31_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold         (sigFromSrams_bore_31_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                 (sigFromSrams_bore_31_cgen)
  );

  // ---- 顶层输出 ----
  assign io_out_s2_full_pred_0_br_taken_mask_0 = s2_taken[0][0];
  assign io_out_s2_full_pred_0_br_taken_mask_1 = s2_taken[0][1];
  assign io_out_s2_full_pred_1_br_taken_mask_0 = s2_taken[1][0];
  assign io_out_s2_full_pred_1_br_taken_mask_1 = s2_taken[1][1];
  assign io_out_s2_full_pred_2_br_taken_mask_0 = s2_taken[2][0];
  assign io_out_s2_full_pred_2_br_taken_mask_1 = s2_taken[2][1];
  assign io_out_s2_full_pred_3_br_taken_mask_0 = s2_taken[3][0];
  assign io_out_s2_full_pred_3_br_taken_mask_1 = s2_taken[3][1];
  assign io_out_s3_full_pred_0_br_taken_mask_0 = s3_taken[0][0];
  assign io_out_s3_full_pred_0_br_taken_mask_1 = s3_taken[0][1];
  assign io_out_s3_full_pred_1_br_taken_mask_0 = s3_taken[1][0];
  assign io_out_s3_full_pred_1_br_taken_mask_1 = s3_taken[1][1];
  assign io_out_s3_full_pred_2_br_taken_mask_0 = s3_taken[2][0];
  assign io_out_s3_full_pred_2_br_taken_mask_1 = s3_taken[2][1];
  assign io_out_s3_full_pred_3_br_taken_mask_0 = s3_taken[3][0];
  assign io_out_s3_full_pred_3_br_taken_mask_1 = s3_taken[3][1];
  assign io_out_last_stage_spec_info_sc_disagree_0 = s3_sc_disagree[0];
  assign io_out_last_stage_spec_info_sc_disagree_1 = s3_sc_disagree[1];
  assign io_perf_0_value = {4'h0, perf[0]};
  assign io_perf_1_value = {4'h0, perf[1]};
  assign io_perf_2_value = {4'h0, perf[2]};

endmodule
// END GENERATED(bpu-wrapper)
