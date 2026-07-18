// =============================================================================
// xs_Tage_SC_core —— TAGE-SC 条件分支「方向」预测器顶层核
//
// 对应 Chisel: xiangshan.frontend.Tage_SC（= class Tage with trait HasSC,
//   见 Tage.scala / SC.scala），是香山 BPU 的主方向预测器。
//
// ─────────────────────────────────────────────────────────────────────────
// 【它在前端 BPU 的位置】
//   方向预测主力是 TAGE-SC-L。本模块组合：
//     · N 张带 tag 的几何历史标签表 TageTable_0..3（历史 8/13/32/119，已单独验证）；
//     · 1 张基预测器 TageBTable（bimodal，2bit 饱和，PC 直接索引，已验证）；
//     · N 张无 tag 的统计校正表 SCTable_0..3（带符号 6bit 计数，已验证）。
//   本核**不含任何 SRAM / 折叠历史存储**——那些都在各子表内部。本核只做表间组合：
//   provider/altpred 选择、TAGE 方向合成、SC 求和与阈值校正、分配与老化、提交更新。
//
// 【两条「分支槽」(numBr=2)】
//   一个取指块最多含 2 条条件分支（bank 0 / bank 1）。本核所有预测/更新逻辑都按
//   bank 成对存在，故大量信号用 [NUM_BR] 数组表达。
//
// ─────────────────────────────────────────────────────────────────────────
// 【TAGE 预测（s1→s2）】每个 bank：
//   1. 各表并行给 resp(valid/ctr/u/unconf)。provider = 命中且历史最长的表
//      （golden 用 reverse 的 ParallelPriorityMux；本核用从高到低扫描）。
//   2. unconf：provider 的 ctr 处于中点(3/4)，即「弱置信」新条目。
//   3. useAltOnNa：一张 128 项 4bit 计数表（按 pc 索引），其最高位决定
//      「弱置信时是否改用 altpred(基预测器)」。
//   4. altUsed = 无 provider 或 (provider 弱置信 且 useAltOnNa)；
//      tageTaken = altUsed ? 基预测器方向 : provider.ctr 最高位。
//   5. allocatableSlots：命中失败且 useful=0、且历史比 provider 长的表的 one-hot
//      （分配新条目的候选），随预测打入 meta。
//
// 【SC 校正（s1→s2→s3）】每个 bank：
//   1. s1 把 4 张 SCTable 该 bank 的「居中化」计数器做带符号求和(scSum)。
//   2. s2 加上 provider 的「居中化」ctr → totalSum。scPred = totalSum>=0。
//   3. aboveThreshold：|scSum 偏移量| 是否超过自适应阈值(scThresholds[bank])。
//   4. 最终方向 s2_pred = (有 provider 且超阈值) ? scPred : tageTaken（SC 翻转 TAGE）。
//   5. s3 用 s2_pred 覆盖 br_taken_mask（受 io_ctrl_sc_enable 门控）。
//      s2 阶段先用 TAGE 方向输出 br_taken_mask（受 io_ctrl_tage_enable 门控）。
//
// 【提交更新（commit）——两拍】
//   io_update_valid 当拍：寄存 update 请求 + 解包 meta（当年预测的 provider/ctr/
//     altUsed/basecnt/allocates/scPreds/scCtrs 快照）。
//   下一拍：
//     · TAGE：更新 useAltOnNa；据 provider 是否猜对更新 provider 表 ctr/useful；
//       mispred 时按 tick 计数器(bankTickCtrs / bankTickCtrDistanceToTops)节奏择机
//       分配更长历史的空表；tick 饱和时给该 bank 所有表发 reset_u 老化 useful；
//       altUsed 时更新基预测器。
//     · SC：据 scPred/tagePred/真实方向更新自适应阈值 scThresholds[bank]；当
//       「SC 猜错 或 未超阈值」时更新 4 张 SCTable 的计数器。
//   各子表 update_* 端口由本核算好并寄一拍后送进（与 golden RegNext/RegEnable 同步）。
//
// 【4 份 dup】BPU 把同一预测复制 4 份喂下游，各有独立 fire。本核里 s2_tageTakens
//   与 s3 的 SC 最终预测各有 4 份 dup 寄存器（值同源、仅 fire 使能不同）。其余
//   full_pred 字段对本预测器是纯旁路，由 wrapper 透传 io_in→io_out。
//
// 【分层：核 vs wrapper】各子表 + LFSR + MbistPipeTage 都是 golden 黑盒；本核把
//   它们的功能端口全部引出（tbl_* / bt_* / sc_*），由 golden 同名 wrapper(Tage_SC)
//   例化子模块并对接，DFT/MBIST 链也在 wrapper 里（机械适配，与本核无关）。
// =============================================================================
module xs_Tage_SC_core #(
  parameter int unsigned PC_W      = 50,   // VAddrBits
  parameter int unsigned NUM_BR    = 2,    // 分支槽数 numBr / TageBanks
  parameter int unsigned NUM_TBL   = 4,    // TAGE 标签表张数 TageNTables
  parameter int unsigned SC_NTBL   = 4,    // SC 表张数 SCNTables
  parameter int unsigned TAGE_CTR_W= 3,    // TAGE ctr 位宽 TageCtrBits
  parameter int unsigned SC_CTR_W  = 6,    // SC ctr 位宽 SCCtrBits
  parameter int unsigned GHIST_W   = 256,  // 全局历史位宽 HistoryLength
  parameter int unsigned META_W    = 516,  // last_stage_meta 位宽
  parameter int unsigned TICK_W    = 7,    // TickWidth
  parameter int unsigned UAON_W    = 4,    // USE_ALT_ON_NA_WIDTH
  parameter int unsigned NUM_UAON  = 128,  // NUM_USE_ALT_ON_NA
  parameter int unsigned SC_THR_W  = 5,    // SCThreshold ctr 位宽（SCThreshold(5)）
  parameter int unsigned RV_W      = 48    // reset_vector 位宽
)(
  input  logic                clock,
  input  logic                reset,

  input  logic [RV_W-1:0]     io_reset_vector,

  // ---- s0 取指 PC（4 份 dup）与各级 fire ----
  input  logic [PC_W-1:0]     io_in_s0_pc [4],
  input  logic                io_s0_fire  [4],
  input  logic                io_s1_fire  [4],
  input  logic                io_s2_fire  [4],

  // ---- 控制 ----
  input  logic                io_ctrl_tage_enable,
  input  logic                io_ctrl_sc_enable,

  // ---- 输出：方向预测（s2 = TAGE，s3 = SC 校正后），每 bank 1 位 × 4 dup ----
  output logic                io_out_s2_taken [4][NUM_BR],
  output logic                io_out_s3_taken [4][NUM_BR],
  output logic [META_W-1:0]   io_out_last_stage_meta,
  output logic                io_out_sc_disagree [NUM_BR],   // last_stage_spec_info.sc_disagree
  output logic                io_s1_ready,
  // perf 计数（golden io_perf_{0,1,2}_value：事件打两拍，高 4 位补零）
  output logic [5:0]          io_perf_0_value,
  output logic [5:0]          io_perf_1_value,
  output logic [5:0]          io_perf_2_value,

  // ---- 更新（commit）输入 ----
  input  logic                io_update_valid,
  input  logic [PC_W-1:0]     io_update_pc,
  input  logic                io_update_br_valid  [NUM_BR],  // ftb_entry.brValids（bank0=brSlots_0_valid，bank1=tailSlot_valid&sharing 当拍积）
  // bank1 的两只原始位（golden 分别寄存 tailSlot_valid/sharing 再在下游相与；
  // 若只寄存乘积则与 golden 寄存器 1:1 失配 → FM 锥输入毒化大片失配）
  input  logic                io_update_tailSlot_valid,
  input  logic                io_update_tailSlot_sharing,
  input  logic                io_update_strong_bias [NUM_BR],
  input  logic                io_update_br_taken    [NUM_BR],
  input  logic                io_update_mispred     [NUM_BR],
  input  logic [META_W-1:0]   io_update_meta,
  input  logic [GHIST_W-1:0]  io_update_ghist,

  // ===========================================================================
  // 与 wrapper 内 4 张 TageTable 黑盒对接
  // ===========================================================================
  output logic                tbl_req_valid,                 // s0_fire(1) 触发各表读
  output logic [PC_W-1:0]     tbl_req_pc,                    // s0_pc(1)
  input  logic                tbl_req_ready [NUM_TBL],
  // 各表 resp（每表 numBr 个 bank）
  input  logic                tbl_resp_valid  [NUM_TBL][NUM_BR],
  input  logic [TAGE_CTR_W-1:0] tbl_resp_ctr  [NUM_TBL][NUM_BR],
  input  logic                tbl_resp_u      [NUM_TBL][NUM_BR],
  input  logic                tbl_resp_unconf [NUM_TBL][NUM_BR],
  // 各表 update（本核驱动，已寄一拍）
  output logic [PC_W-1:0]     tbl_upd_pc      [NUM_TBL],
  output logic [GHIST_W-1:0]  tbl_upd_ghist   [NUM_TBL],
  output logic                tbl_upd_mask    [NUM_TBL][NUM_BR],
  output logic                tbl_upd_takens  [NUM_TBL][NUM_BR],
  output logic                tbl_upd_alloc   [NUM_TBL][NUM_BR],
  output logic [TAGE_CTR_W-1:0] tbl_upd_oldCtrs [NUM_TBL][NUM_BR],
  output logic                tbl_upd_uMask   [NUM_TBL][NUM_BR],
  output logic                tbl_upd_us      [NUM_TBL][NUM_BR],
  output logic                tbl_upd_reset_u [NUM_TBL][NUM_BR],

  // ===========================================================================
  // 与 wrapper 内 TageBTable 基预测器黑盒对接
  // ===========================================================================
  output logic                bt_req_valid,                  // s0_fire(1)
  output logic [PC_W-1:0]     bt_req_pc,                     // s0_pc(1)
  input  logic                bt_req_ready,
  input  logic [1:0]          bt_s1_cnt [NUM_BR],            // 基预测器 2bit 计数（每 bank）
  output logic                bt_upd_mask   [NUM_BR],
  output logic [PC_W-1:0]     bt_upd_pc,
  output logic [1:0]          bt_upd_cnt    [NUM_BR],
  output logic                bt_upd_takens [NUM_BR],

  // ===========================================================================
  // 与 wrapper 内 4 张 SCTable 黑盒对接
  // ===========================================================================
  output logic                sc_req_valid,                  // s0_fire(3)
  output logic [PC_W-1:0]     sc_req_pc,                     // s0_pc(3)
  // 各 SC 表 resp：每表每 bank 2 个桶（[0]=TAGE not-taken, [1]=TAGE taken）
  input  logic signed [SC_CTR_W-1:0] sc_resp_ctrs [SC_NTBL][NUM_BR][2],
  // 各 SC 表 update（本核驱动，已寄一拍）
  output logic [PC_W-1:0]     sc_upd_pc     [SC_NTBL],
  output logic [GHIST_W-1:0]  sc_upd_ghist  [SC_NTBL],
  output logic                sc_upd_mask   [SC_NTBL][NUM_BR],
  output logic signed [SC_CTR_W-1:0] sc_upd_oldCtrs [SC_NTBL][NUM_BR],
  output logic                sc_upd_tagePreds [SC_NTBL][NUM_BR],
  output logic                sc_upd_takens    [SC_NTBL][NUM_BR],

  // ===========================================================================
  // 分配随机数：每 bank 一个 15bit Fibonacci LFSR（golden allocLFSR_prng/_1 子模块），
  //   本核取低 NUM_TBL 位用于「在可分配空表里随机挑一张」。由 wrapper 例化黑盒后喂入。
  // ===========================================================================
  input  logic [NUM_TBL-1:0]  alloc_lfsr [NUM_BR]
);

  // ===========================================================================
  // 局部参数 / 派生常量
  // ===========================================================================
  localparam int unsigned TIDX_W   = $clog2(NUM_TBL);              // 表序号位宽 = 2
  localparam int unsigned UAON_IDXW = $clog2(NUM_UAON);            // useAltOnNa 索引位宽 = 7
  localparam logic [TICK_W-1:0] TICK_MAX = '1;                     // (1<<TickWidth)-1
  localparam int unsigned INST_OFF = 1;                            // instOffsetBits

  // ===========================================================================
  // s0/s1 PC 寄存（与 golden s0_pc_dup / s1_pc_dup 对齐）
  //   TAGE 表用 dup1，SC 表用 dup3。各 dup 在自己的 s0_fire 时打入。
  //   复位首拍灌 reset_vector（golden REG/REG_1：复位边沿打两拍）。
  // ===========================================================================
  logic [PC_W-1:0] s1_pc_dup [4];
  logic            reg_reset, reg_reset_d;
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

  // TAGE 表 / 基预测器读 req：s0_fire(1) + s0_pc(1)（直连 s0，表内自寄一拍）
  assign tbl_req_valid = io_s0_fire[1];
  assign tbl_req_pc    = io_in_s0_pc[1];
  assign bt_req_valid  = io_s0_fire[1];
  assign bt_req_pc     = io_in_s0_pc[1];
  // SC 表读 req：s0_fire(3) + s0_pc(3)
  assign sc_req_valid  = io_s0_fire[3];
  assign sc_req_pc     = io_in_s0_pc[3];

  // s1_ready = 所有 TAGE 表 + 基预测器都 ready
  always_comb begin
    io_s1_ready = bt_req_ready;
    for (int unsigned t = 0; t < NUM_TBL; t++) io_s1_ready &= tbl_req_ready[t];
  end

  // ===========================================================================
  // useAltOnNa 计数表：[bank][128] × 4bit；初值 = 中点(1<<(W-1)=8)
  //   预测侧按 s1_pc(0) 索引取最高位决定弱置信时是否改用 altpred。
  //   提交侧按 update_pc 索引、provider 弱置信且 altpred 与 provider 方向不同时饱和增减。
  // ===========================================================================
  logic [UAON_W-1:0] use_alt_on_na [NUM_BR][NUM_UAON];
  wire [UAON_IDXW-1:0] pred_alt_idx = s1_pc_dup[0][INST_OFF +: UAON_IDXW];

  // ===========================================================================
  // s1：TAGE provider 选择 + 方向合成（每 bank）
  //   provider = 命中的表里序号最大者（历史最长）。golden 用 reverse PriorityMux，
  //   本核用从高到低扫描；无命中时 provider 字段兜底到表 0 的 resp（don't-care，
  //   但 meta 需逐位等价；并避免 array[变量下标] 触 FMR_ELAB-147）。
  // ===========================================================================
  logic            s1_provided   [NUM_BR];
  logic [TIDX_W-1:0] s1_provider [NUM_BR];
  logic [TAGE_CTR_W-1:0] s1_prov_ctr [NUM_BR];
  logic            s1_prov_u     [NUM_BR];
  logic            s1_prov_unconf[NUM_BR];   // provider.unconf
  logic            s1_alt_used   [NUM_BR];
  logic            s1_use_alt_on_na [NUM_BR];
  logic            s1_tage_taken [NUM_BR];
  logic [1:0]      s1_basecnt    [NUM_BR];
  logic [NUM_TBL-1:0] s1_allocatable [NUM_BR];

  always_comb begin
    for (int unsigned b = 0; b < NUM_BR; b++) begin
      // useAltOnNa 当前值（按 pc 索引），最高位 = useAltOnNa 决策位
      logic [UAON_W-1:0] use_alt_ctr;
      logic              use_alt_on_na_bit;
      use_alt_ctr       = use_alt_on_na[b][pred_alt_idx];
      use_alt_on_na_bit = use_alt_ctr[UAON_W-1];

      // provider 扫描（从高序号往低）：第一张命中即 provider
      s1_provided[b]    = 1'b0;
      s1_provider[b]    = '0;
      s1_prov_ctr[b]    = tbl_resp_ctr[0][b];
      s1_prov_u[b]      = tbl_resp_u[0][b];
      s1_prov_unconf[b] = tbl_resp_unconf[0][b];
      for (int t = NUM_TBL - 1; t >= 0; t--) begin
        if (tbl_resp_valid[t][b] & ~s1_provided[b]) begin
          s1_provided[b]    = 1'b1;
          s1_provider[b]    = TIDX_W'(t);
          s1_prov_ctr[b]    = tbl_resp_ctr[t][b];
          s1_prov_u[b]      = tbl_resp_u[t][b];
          s1_prov_unconf[b] = tbl_resp_unconf[t][b];
        end
      end

      // use_alt_on_unconf = provider 弱置信 且 useAltOnNa 决策位为 1
      s1_use_alt_on_na[b] = s1_prov_unconf[b] & use_alt_on_na_bit;
      // altUsed = 无 provider 或 弱置信改用 altpred
      s1_alt_used[b]      = ~s1_provided[b] | s1_use_alt_on_na[b];
      // 基预测器方向 = bt_s1_cnt 最高位
      s1_basecnt[b]       = bt_s1_cnt[b];
      // tageTaken = altUsed ? 基预测器方向 : provider.ctr 最高位
      s1_tage_taken[b]    = s1_alt_used[b] ? bt_s1_cnt[b][1]
                                           : s1_prov_ctr[b][TAGE_CTR_W-1];

      // allocatableSlots = (~valid & ~u) & ~(provider 及更短的表)（即只留更长历史的空表）
      //   golden: allocatable & ~(LowerMask(OH(provider)) & Fill(provided))
      //   即「序号 > provider 或 无 provider」的 ~valid&~u 表。
      for (int unsigned t = 0; t < NUM_TBL; t++) begin
        logic longer;   // 历史比 provider 长（或无 provider）
        longer = ~s1_provided[b] | (TIDX_W'(t) > s1_provider[b]);
        s1_allocatable[b][t] = ~tbl_resp_valid[t][b] & ~tbl_resp_u[t][b] & longer;
      end
    end
  end

  // ===========================================================================
  // s2：寄存 TAGE provider 选择结果（s1_fire(1) 使能）
  // ===========================================================================
  logic            s2_provided   [NUM_BR];
  logic [TIDX_W-1:0] s2_provider [NUM_BR];
  logic [TAGE_CTR_W-1:0] s2_prov_ctr [NUM_BR];
  logic            s2_prov_u     [NUM_BR];
  logic            s2_alt_used   [NUM_BR];
  logic [1:0]      s2_basecnt    [NUM_BR];
  logic            s2_use_alt_on_na [NUM_BR];
  logic [NUM_TBL-1:0] s2_allocatable [NUM_BR];
  logic            s2_tage_taken_dup [4][NUM_BR];   // 4 dup（各自 s1_fire）

  always_ff @(posedge clock) begin
    if (io_s1_fire[1]) begin
      for (int unsigned b = 0; b < NUM_BR; b++) begin
        s2_provided[b]      <= s1_provided[b];
        s2_provider[b]      <= s1_provider[b];
        s2_prov_ctr[b]      <= s1_prov_ctr[b];
        s2_prov_u[b]        <= s1_prov_u[b];
        s2_alt_used[b]      <= s1_alt_used[b];
        s2_basecnt[b]       <= s1_basecnt[b];
        s2_use_alt_on_na[b] <= s1_use_alt_on_na[b];
        s2_allocatable[b]   <= s1_allocatable[b];
      end
    end
    for (int unsigned d = 0; d < 4; d++)
      if (io_s1_fire[d])
        for (int unsigned b = 0; b < NUM_BR; b++)
          s2_tage_taken_dup[d][b] <= s1_tage_taken[b];
  end

  // ===========================================================================
  // s2 输出：TAGE 方向（受 tage_enable 门控；各 dup 用自己的 s2_tageTakens）
  //   golden：tage_enable 打一拍后，when(tage_enable) fp.br_taken_mask := s2_tageTakens
  //   未使能时保持 io_in 旁路值——本核只在使能时驱动，旁路由 wrapper 处理。
  // ===========================================================================
  logic tage_enable_d;
  always_ff @(posedge clock) tage_enable_d <= io_ctrl_tage_enable;

  always_comb begin
    for (int unsigned d = 0; d < 4; d++)
      for (int unsigned b = 0; b < NUM_BR; b++)
        io_out_s2_taken[d][b] = tage_enable_d & s2_tage_taken_dup[d][b];
  end

  // ===========================================================================
  // pred_cycle 自由计数（meta 调试戳）
  // ===========================================================================
  logic [63:0] pred_cycle;
  always_ff @(posedge clock or posedge reset)
    if (reset) pred_cycle <= '0; else pred_cycle <= pred_cycle + 64'h1;

  // ===========================================================================
  // SC 求和与阈值（每 bank）
  // ===========================================================================
  // scThresholds[bank]：自适应阈值（ctr 5bit + thres 8bit）。初值 ctr=neutral(16), thres=6。
  logic [SC_THR_W-1:0] sc_thr_ctr   [NUM_BR];
  logic [7:0]          sc_thr_thres [NUM_BR];

  // 「居中化」函数（纯组合，避免 function automatic+genvar 的 X 坑，直接内联）：
  //   getCentered(ctr)      = {ctr, 1'b1}（SC ctr：6bit → 7bit 带符号，*2+1）
  //   getPvdrCentered(ctr)  = {ctr ^ 4, 1'b1, 3'b0}（TAGE ctr：翻最高位居中、左移 3）
  // scSum = ParallelSignedExpandingAdd(4 张 SC 表的 getCentered)
  //   4 个 7bit 带符号相加 → 需 9bit（7 + ceil(log2 4)）带符号容纳。

  // s1 求和：每 bank、每个「选择桶」(0/1) 把 4 张表对应桶的居中值相加
  logic signed [8:0] s1_sc_sum [NUM_BR][2];
  always_comb begin
    for (int unsigned b = 0; b < NUM_BR; b++) begin
      for (int unsigned i = 0; i < 2; i++) begin
        logic signed [8:0] acc;
        acc = '0;
        for (int unsigned t = 0; t < SC_NTBL; t++)
          // getCentered: {ctr,1'b1} 是 (SC_CTR_W+1) 位带符号
          acc += $signed({sc_resp_ctrs[t][b][i], 1'b1});
        s1_sc_sum[b][i] = acc;
      end
    end
  end

  // s2 寄存：scSum、provider 居中 ctr、scResps（更新 meta 用）
  logic signed [8:0]  s2_sc_sum [NUM_BR][2];
  logic [2:0]         s2_pvdr_ctr_r [NUM_BR];      // golden s2_tagePrvdCtrCentered_r：寄存**原始** 3 位 provider ctr
                                                     //（居中值下游组合展开；寄存展开值会与 golden 寄存器失配）
  logic signed [SC_CTR_W-1:0] s2_sc_resps [NUM_BR][SC_NTBL][2];
  always_ff @(posedge clock) begin
    if (io_s1_fire[3]) begin
      for (int unsigned b = 0; b < NUM_BR; b++) begin
        for (int unsigned i = 0; i < 2; i++) s2_sc_sum[b][i] <= s1_sc_sum[b][i];
        // 寄存原始 provider ctr（golden s2_tagePrvdCtrCentered_r）
        s2_pvdr_ctr_r[b] <= s1_prov_ctr[b];
        for (int unsigned t = 0; t < SC_NTBL; t++)
          for (int unsigned i = 0; i < 2; i++)
            s2_sc_resps[b][t][i] <= sc_resp_ctrs[t][b][i];
      end
    end
  end

  // s2：阈值比较与 SC 预测
  //   aboveThreshold(scSum, tagePvdr, thr):
  //     signedThres = thr;  totalSum = scSum + tagePvdr;
  //     (scSum >  thr - tagePvdr) & totalSum>=0  ||
  //     (scSum < -thr - tagePvdr) & totalSum<0
  logic [9:0]         s2_total_sum [NUM_BR][2];   // golden s2_totalSums_N（10 位）
  logic               s2_above_thr [NUM_BR][2];
  logic               s2_sc_pred   [NUM_BR][2];
  logic               s2_pred      [NUM_BR];     // SC 校正后的最终方向（s3 前）
  logic               s2_choose    [NUM_BR];     // 选择桶 = s2_tageTaken(dup3)
  logic               s2_disagree  [NUM_BR];

  always_comb begin
    for (int unsigned b = 0; b < NUM_BR; b++) begin
      logic [2:0] t3;
      logic [9:0] pvdr10;
      logic [8:0] thres9, pvdr9;
      logic sel_choose;
      logic sel_above_thr;
      logic sel_sc_pred;
      // 位宽逐一对齐 golden：pvdr 居中 10/9 位、thres 零扩 9 位、totalSum 10 位。
      t3     = s2_pvdr_ctr_r[b] ^ 3'h4;
      pvdr10 = {{3{t3[2]}}, t3, 4'h8};                 // golden _GEN_78
      thres9 = {1'b0, sc_thr_thres[b]};                // golden _GEN_79
      pvdr9  = {{2{t3[2]}}, t3, 4'h8};                 // golden _GEN_80
      for (int unsigned i = 0; i < 2; i++) begin
        logic signed [8:0] sum;
        logic [9:0] tot;
        sum = s2_sc_sum[b][i];
        tot = 10'({sum[8], sum} + pvdr10);
        s2_total_sum[b][i] = tot;
        s2_above_thr[b][i] =
          (($signed(sum) > $signed(9'(thres9 - pvdr9))) & ~tot[9]) |
          (($signed(sum) < $signed(9'(9'(9'h0 - thres9) - pvdr9))) & tot[9]);
        s2_sc_pred[b][i]   = ($signed(tot) > -10'sh1);
      end
      // 选中桶 = s2_tageTaken(dup3)。注意：必须用三元 mux（cond ? bucket1 : bucket0）
      // 选桶，**不能**用 s2_above_thr[b][s2_choose[b]] 这种「变量下标取数组」——
      // 当 s2_choose 为 X（基表 doing_reset 窗口 bt_s1_cnt 读 X 传到 dup3）时，
      // array[X] 在 SV 中**恒为 X**（即使两桶取值相同），而 golden 的 (X ? a : b)
      // 在 a===b 时仍收敛为定值。两者语义差异正是 seed7 偶发 X 不匹配的根因。
      sel_choose    = s2_tage_taken_dup[3][b];
      sel_above_thr = sel_choose ? s2_above_thr[b][1] : s2_above_thr[b][0];
      sel_sc_pred   = sel_choose ? s2_sc_pred[b][1]   : s2_sc_pred[b][0];
      s2_choose[b]  = sel_choose;
      // s2_pred = (有 provider 且选中桶超阈值) ? SC 预测 : TAGE 方向
      s2_pred[b] = (s2_provided[b] & sel_above_thr)
                     ? sel_sc_pred
                     : s2_tage_taken_dup[3][b];
      // disagree：有 provider 且超阈值 且 SC 与 TAGE 方向不同
      s2_disagree[b] = s2_provided[b] & sel_above_thr
                     & (s2_tage_taken_dup[3][b] != sel_sc_pred);
    end
  end

  // ===========================================================================
  // s3：SC 最终预测寄存（4 dup）+ disagree 寄存 + scMeta 寄存
  // ===========================================================================
  logic s3_pred_dup [4][NUM_BR];
  logic s3_disagree [NUM_BR];
  logic sc_enable_d;
  // scMeta 快照（meta 打包用）：scPreds（选中桶的 SC 预测）+ scCtrs（选中桶的 4 表计数）
  logic               m_sc_preds [NUM_BR];
  logic signed [SC_CTR_W-1:0] m_sc_ctrs [NUM_BR][SC_NTBL];

  always_ff @(posedge clock) begin
    sc_enable_d <= io_ctrl_sc_enable;
    for (int unsigned d = 0; d < 4; d++)
      if (io_s2_fire[d])
        for (int unsigned b = 0; b < NUM_BR; b++)
          s3_pred_dup[d][b] <= s2_pred[b];
    if (io_s2_fire[3]) begin
      for (int unsigned b = 0; b < NUM_BR; b++) begin
        s3_disagree[b] <= s2_disagree[b];
        // 同 s2_pred：用三元 mux 选桶（不可用 array[s2_choose] 否则 choose=X 时恒 X，
        // 与 golden r_4_* <= s2_tageTakens_dup_3 ? ctrs_1 : ctrs_0 的 X 收敛语义不一致）。
        m_sc_preds[b]  <= s2_choose[b] ? s2_sc_pred[b][1] : s2_sc_pred[b][0];
        for (int unsigned t = 0; t < SC_NTBL; t++)
          m_sc_ctrs[b][t] <= s2_choose[b] ? s2_sc_resps[b][t][1] : s2_sc_resps[b][t][0];
      end
    end
  end

  // s3 输出：SC 校正后的方向（受 sc_enable 门控；同 s2 的处理，旁路由 wrapper 负责）
  always_comb begin
    for (int unsigned d = 0; d < 4; d++)
      for (int unsigned b = 0; b < NUM_BR; b++)
        io_out_s3_taken[d][b] = sc_enable_d & s3_pred_dup[d][b];
  end
  always_comb
    for (int unsigned b = 0; b < NUM_BR; b++) io_out_sc_disagree[b] = s3_disagree[b];

  // ===========================================================================
  // last_stage_meta 打包（s2_fire(1)/s2_fire(3) 寄存的 resp_meta）
  // ===========================================================================
  // resp_meta 各字段在 s2_fire 时寄存（与 golden RegEnable(..., io.s2_fire) 对齐）
  logic               rm_prov_valid [NUM_BR];
  logic [TIDX_W-1:0]  rm_prov_bits  [NUM_BR];
  logic [TAGE_CTR_W-1:0] rm_prov_ctr [NUM_BR];
  logic               rm_prov_u     [NUM_BR];
  logic               rm_alt_used   [NUM_BR];
  logic [1:0]         rm_basecnt    [NUM_BR];
  logic [NUM_TBL-1:0] rm_allocates  [NUM_BR];
  logic               rm_use_alt_on_na [NUM_BR];
  logic [63:0]        rm_pred_cycle;

  always_ff @(posedge clock) begin
    if (io_s2_fire[1]) begin
      for (int unsigned b = 0; b < NUM_BR; b++) begin
        rm_prov_valid[b]    <= s2_provided[b];
        rm_prov_bits[b]     <= s2_provider[b];
        rm_prov_ctr[b]      <= s2_prov_ctr[b];
        rm_prov_u[b]        <= s2_prov_u[b];
        rm_alt_used[b]      <= s2_alt_used[b];
        rm_basecnt[b]       <= s2_basecnt[b];
        rm_allocates[b]     <= s2_allocatable[b];
        rm_use_alt_on_na[b] <= s2_use_alt_on_na[b];
      end
      rm_pred_cycle <= pred_cycle;
    end
  end

  // 打包（位序见模块头 / docs；高位补 0）
  always_comb begin
    io_out_last_stage_meta = '0;
    io_out_last_stage_meta[143]     = rm_prov_valid[1];
    io_out_last_stage_meta[142:141] = rm_prov_bits[1];
    io_out_last_stage_meta[140]     = rm_prov_valid[0];
    io_out_last_stage_meta[139:138] = rm_prov_bits[0];
    io_out_last_stage_meta[137:135] = rm_prov_ctr[1];
    io_out_last_stage_meta[134]     = rm_prov_u[1];
    io_out_last_stage_meta[133:131] = rm_prov_ctr[0];
    io_out_last_stage_meta[130]     = rm_prov_u[0];
    io_out_last_stage_meta[129]     = rm_alt_used[1];
    io_out_last_stage_meta[128]     = rm_alt_used[0];
    io_out_last_stage_meta[127:126] = rm_basecnt[1];
    io_out_last_stage_meta[125:124] = rm_basecnt[0];
    io_out_last_stage_meta[123:120] = rm_allocates[1];
    io_out_last_stage_meta[119:116] = rm_allocates[0];
    io_out_last_stage_meta[115]     = m_sc_preds[1];
    io_out_last_stage_meta[114]     = m_sc_preds[0];
    // r_5_3..r_5_0 = bank1 scCtrs[3..0]；r_4_3..r_4_0 = bank0 scCtrs[3..0]
    io_out_last_stage_meta[113:108] = m_sc_ctrs[1][3];
    io_out_last_stage_meta[107:102] = m_sc_ctrs[1][2];
    io_out_last_stage_meta[101:96]  = m_sc_ctrs[1][1];
    io_out_last_stage_meta[95:90]   = m_sc_ctrs[1][0];
    io_out_last_stage_meta[89:84]   = m_sc_ctrs[0][3];
    io_out_last_stage_meta[83:78]   = m_sc_ctrs[0][2];
    io_out_last_stage_meta[77:72]   = m_sc_ctrs[0][1];
    io_out_last_stage_meta[71:66]   = m_sc_ctrs[0][0];
    io_out_last_stage_meta[65:2]    = rm_pred_cycle;
    io_out_last_stage_meta[1]       = rm_use_alt_on_na[1];
    io_out_last_stage_meta[0]       = rm_use_alt_on_na[0];
  end

  // ===========================================================================
  // ============================ 更新（commit）路径 ===========================
  // ===========================================================================
  // 第 1 拍：寄存 update 请求 + 解包 meta（当年预测快照）
  // ---------------------------------------------------------------------------
  logic            u_valid;            // io_update_valid 打一拍
  logic            upd_br_valid [NUM_BR];
  logic            upd_tailSlot_valid;    // golden update_r_ftb_entry_tailSlot_valid
  logic            upd_tailSlot_sharing;  // golden update_r_ftb_entry_tailSlot_sharing
  logic            upd_strong_bias [NUM_BR];
  logic            upd_br_taken [NUM_BR];
  logic            upd_mispred  [NUM_BR];
  logic [GHIST_W-1:0] upd_ghist;
  // 解包寄存的 meta
  logic            um_prov_valid [NUM_BR];
  logic [TIDX_W-1:0] um_prov_bits [NUM_BR];
  logic [TAGE_CTR_W-1:0] um_prov_ctr [NUM_BR];
  logic            um_prov_u     [NUM_BR];
  logic            um_alt_used   [NUM_BR];
  logic [1:0]      um_basecnt    [NUM_BR];
  logic [NUM_TBL-1:0] um_allocates [NUM_BR];
  logic            um_sc_preds   [NUM_BR];
  logic signed [SC_CTR_W-1:0] um_sc_ctrs [NUM_BR][SC_NTBL];

  // u_valids_for_cge：本 bank brValid 且 update.valid（用于 provider/scMeta 解包的使能）
  wire u_valids_for_cge [NUM_BR];
  // 注：golden 用 io.update.bits.ftb_entry.brValids（io_update_valid 当拍的输入）
  assign u_valids_for_cge[0] = io_update_br_valid[0] & io_update_valid;
  assign u_valids_for_cge[1] = io_update_br_valid[1] & io_update_valid;
  // meta 当拍解包（输入 io_update_meta 的字段，给条件使能用）
  wire iu_prov_valid [NUM_BR];
  assign iu_prov_valid[0] = io_update_meta[140];
  assign iu_prov_valid[1] = io_update_meta[143];

  always_ff @(posedge clock or posedge reset) begin
    if (reset) u_valid <= 1'b0;
    else       u_valid <= io_update_valid;
  end

  always_ff @(posedge clock) begin
    // update.bits := RegEnable(io.update.bits, io.update.valid)
    if (io_update_valid) begin
      // bank0 寄存原始位；bank1 改为分别寄存 tailSlot_valid/sharing（下游相与）
      upd_br_valid[0]      <= io_update_br_valid[0];
      upd_tailSlot_valid   <= io_update_tailSlot_valid;
      upd_tailSlot_sharing <= io_update_tailSlot_sharing;
      for (int unsigned b = 0; b < NUM_BR; b++) begin
        upd_strong_bias[b] <= io_update_strong_bias[b];
        upd_br_taken[b]    <= io_update_br_taken[b];
        upd_mispred[b]     <= io_update_mispred[b];
      end
      upd_ghist <= io_update_ghist;
      // updateMeta := RegEnable(u_meta, io.update.valid) —— altUsed/basecnt/use_alt_on_na 等
      for (int unsigned b = 0; b < NUM_BR; b++) begin
        um_prov_valid[b] <= iu_prov_valid[b];
      end
      // allocates: RegEnable(..., io.update.valid)
      um_allocates[0] <= io_update_meta[119:116];
      um_allocates[1] <= io_update_meta[123:120];
    end
    // altUsed(i) := RegEnable(u_meta.altUsed(i), u_valids_for_cge(i))
    if (u_valids_for_cge[0]) um_alt_used[0] <= io_update_meta[128];
    if (u_valids_for_cge[1]) um_alt_used[1] <= io_update_meta[129];
    // providers(i).bits / providerResps(i) := RegEnable(..., u_meta.providers(i).valid && u_valids_for_cge(i))
    if (iu_prov_valid[0] & u_valids_for_cge[0]) begin
      um_prov_bits[0] <= io_update_meta[139:138];
      um_prov_ctr[0]  <= io_update_meta[133:131];
      um_prov_u[0]    <= io_update_meta[130];
    end
    if (iu_prov_valid[1] & u_valids_for_cge[1]) begin
      um_prov_bits[1] <= io_update_meta[142:141];
      um_prov_ctr[1]  <= io_update_meta[137:135];
      um_prov_u[1]    <= io_update_meta[134];
    end
    // basecnts(i) := RegEnable(u_meta.basecnts(i), io.s2_fire) —— 在 resp_meta 侧；
    //   但 updateMeta 的 basecnt 走的是 RegEnable(u_meta, io.update.valid)（整体）。
    //   golden: updateMeta := RegEnable(u_meta, io.update.valid) 覆盖 basecnts/use_alt_on_na。
    if (io_update_valid) begin
      um_basecnt[0]  <= io_update_meta[125:124];
      um_basecnt[1]  <= io_update_meta[127:126];
    end
    // scMeta: scPreds/ctrs := RegEnable(..., u_valids_for_cge(w) && u_meta.providers(w).valid)
    if (u_valids_for_cge[0] & iu_prov_valid[0]) begin
      um_sc_preds[0]   <= io_update_meta[114];
      um_sc_ctrs[0][0] <= io_update_meta[71:66];   // r_4_0
      um_sc_ctrs[0][1] <= io_update_meta[77:72];   // r_4_1
      um_sc_ctrs[0][2] <= io_update_meta[83:78];   // r_4_2
      um_sc_ctrs[0][3] <= io_update_meta[89:84];   // r_4_3
    end
    if (u_valids_for_cge[1] & iu_prov_valid[1]) begin
      um_sc_preds[1] <= io_update_meta[115];
      um_sc_ctrs[1][0] <= io_update_meta[95:90];
      um_sc_ctrs[1][1] <= io_update_meta[101:96];
      um_sc_ctrs[1][2] <= io_update_meta[107:102];
      um_sc_ctrs[1][3] <= io_update_meta[113:108];
    end
  end

  // updateValids[w] = brValid & u_valid & ~strong_bias & ~(PriorityEncoder(br_taken_mask) < w)
  //   PriorityEncoder(br_taken_mask) < w：bank1 在「bank0 已跳」时被屏蔽（更高优先级 cfi 在前）。
  wire update_valids [NUM_BR];
  // bank0：~(prioEnc < 0) 恒真（prioEnc 不可能 <0）
  assign update_valids[0] = upd_br_valid[0] & u_valid & ~upd_strong_bias[0];
  // bank1：被屏蔽当 bank0 是首个 taken（prioEnc==0 即 br_taken_mask[0]==1）
  assign update_valids[1] = (upd_tailSlot_valid & upd_tailSlot_sharing)
                          & u_valid & ~upd_strong_bias[1]
                          & ~upd_br_taken[0];

  // ---- perf 计数（golden io_perf_N_value_REG/REG_1，无复位两拍流水）----
  logic [1:0] perf0_s1, perf0_s2, perf1_s1, perf1_s2, perf2_s1, perf2_s2;
  assign io_perf_0_value = {4'h0, perf0_s2};
  assign io_perf_1_value = {4'h0, perf1_s2};
  assign io_perf_2_value = {4'h0, perf2_s2};

  // updateAltIdx：按 update_pc 索引 useAltOnNa（用 io_update_pc 当拍，pc 不打拍）
  wire [UAON_IDXW-1:0] upd_alt_idx = io_update_pc[INST_OFF +: UAON_IDXW];

  // ===========================================================================
  // 每 bank 的 TAGE 更新中间量
  // ===========================================================================
  // provider 是否猜对、altpred 是否猜对、provider 弱置信等
  logic           u_has_update   [NUM_BR];
  logic           u_taken        [NUM_BR];
  logic           u_prov_correct [NUM_BR];
  logic           u_alt_pred     [NUM_BR];
  logic           u_alt_correct  [NUM_BR];
  logic           u_alt_differs  [NUM_BR];
  logic           u_prov_weak    [NUM_BR];

  // 各表/各 bank 的更新写口（组合算出 next，下面寄一拍）
  logic               u_updateResetU [NUM_BR];
  // 合入分配后的各表最终写口（fin_*）
  logic [NUM_TBL-1:0] fin_updateMask  [NUM_BR];
  logic [NUM_TBL-1:0] fin_updateUMask [NUM_BR];
  logic [NUM_TBL-1:0] fin_updateAlloc [NUM_BR];
  logic               fin_updateU     [NUM_BR][NUM_TBL];
  logic               fin_updateTaken [NUM_BR][NUM_TBL];
  logic [TAGE_CTR_W-1:0] fin_updateOldCtr [NUM_BR][NUM_TBL];
  // 基预测器更新
  logic               u_baseupdate  [NUM_BR];
  logic [1:0]         u_updatebcnt  [NUM_BR];
  logic               u_bUpdTaken   [NUM_BR];

  // tick 计数器（每 bank）：bankTickCtrs / bankTickCtrDistanceToTops
  logic [TICK_W-1:0]  bank_tick_ctr [NUM_BR];
  logic [TICK_W-1:0]  bank_tick_dist[NUM_BR];

  // ---- 分配候选 / 分配序号（组合）----
  //   候选 canAllocMask = meta.allocates & 「历史比 provider 长」；分配序号用 alloc_lfsr
  //   在候选里随机挑（见下方「分配序号选择」）。
  logic [NUM_TBL-1:0] u_canAllocMask [NUM_BR];
  logic [NUM_TBL-1:0] u_allocFailMask[NUM_BR];
  logic [TIDX_W-1:0]  u_alloc_idx    [NUM_BR];
  logic               u_canAllocate  [NUM_BR];
  logic               u_needToAlloc  [NUM_BR];

  // tickInc/Dec 数量（PopCount 差）
  logic [TIDX_W:0]    u_tickIncVal [NUM_BR];
  logic [TIDX_W:0]    u_tickDecVal [NUM_BR];
  logic               u_tickInc [NUM_BR];
  logic               u_tickDec [NUM_BR];

  // ---- SC 更新中间量（每 bank）----
  logic               sc_upd_valid_b [NUM_BR];   // scUpdateMask 是否置位
  logic               u_sc_tagePred  [NUM_BR];
  logic               u_sc_taken     [NUM_BR];

  // ---- TAGE per-bank 更新组合逻辑 ----
  always_comb begin
    for (int unsigned b = 0; b < NUM_BR; b++) begin
      u_has_update[b] = update_valids[b];
      u_taken[b]      = u_has_update[b] & upd_br_taken[b];
      // provider 是否猜对：providerResp.ctr 最高位 == updateTaken
      u_prov_correct[b] = (um_prov_ctr[b][TAGE_CTR_W-1] == u_taken[b]);
      // altpred = basecnt 最高位
      u_alt_pred[b]     = um_basecnt[b][1];
      u_alt_correct[b]  = (u_alt_pred[b] == u_taken[b]);
      // altDiffers = basecnt[1] != providerResp.ctr 最高位
      u_alt_differs[b]  = (um_basecnt[b][1] != um_prov_ctr[b][TAGE_CTR_W-1]);
      // provider 弱置信 unconf：ctr == 中点(3 或 4)
      u_prov_weak[b]    = (um_prov_ctr[b] == TAGE_CTR_W'(1 << (TAGE_CTR_W-1)))     // posUnconf=4
                        | (um_prov_ctr[b] == TAGE_CTR_W'((1 << (TAGE_CTR_W-1))-1)); // negUnconf=3

      // 默认全 0
      // 分配候选：canAllocMask = allocates(meta) & longerMask；allocFailMask = ~allocates & longerMask
      //   longerHistoryTableMask = ~(LowerMask(OH(provider)) & Fill(provided))
      for (int unsigned t = 0; t < NUM_TBL; t++) begin
        logic longer;
        longer = ~um_prov_valid[b] | (TIDX_W'(t) > um_prov_bits[b]);
        u_canAllocMask[b][t]  = um_allocates[b][t] & longer;
        u_allocFailMask[b][t] = ~um_allocates[b][t] & longer;
      end

      u_needToAlloc[b] = u_has_update[b] & upd_mispred[b]
                       & ~(um_alt_used[b] & u_prov_correct[b] & um_prov_valid[b]);
      u_canAllocate[b] = |um_allocates[b];   // allocateValid(i) = allocates(i).orR
    end
  end

  // PopCount 差与 tick 增减判定（依赖 canAllocMask/allocFailMask）
  always_comb begin
    for (int unsigned b = 0; b < NUM_BR; b++) begin
      logic [TIDX_W:0] pc_can, pc_fail;
      pc_can = '0; pc_fail = '0;
      for (int unsigned t = 0; t < NUM_TBL; t++) begin
        pc_can  += (TIDX_W+1)'(u_canAllocMask[b][t]);
        pc_fail += (TIDX_W+1)'(u_allocFailMask[b][t]);
      end
      u_tickInc[b]    = pc_fail > pc_can;
      u_tickDec[b]    = pc_can  > pc_fail;
      u_tickIncVal[b] = pc_fail - pc_can;
      u_tickDecVal[b] = pc_can  - pc_fail;
    end
  end

  // ===========================================================================
  // ---- 分配序号选择 + 合入分配写口（fin_*）----
  //   firstEntry  = canAllocMask 最低位
  //   maskedEntry = (canAllocMask & alloc_lfsr) 最低位
  //   allocate    = canAllocMask[maskedEntry] ? maskedEntry : firstEntry
  //   needToAllocate & canAllocate 时：给 allocate 表置 mask/alloc/uMask、清 U、写 taken。
  //   fin_* = provider 更新写口(u_*) 合入分配写口。
  always_comb begin
    for (int unsigned b = 0; b < NUM_BR; b++) begin
      logic [TIDX_W-1:0] firstEntry, maskedEntry, allocate;
      logic [NUM_TBL-1:0] lfsr_masked;
      logic do_alloc, masked_hit;
      // PriorityEncoder（4 表）与 golden 完全同构：只检查 bit0/1/2，无命中默认落到表 3。
      //   firstEntry  = PriorityEncoder(canAllocMask)
      //   maskedEntry = PriorityEncoder(canAllocMask & allocLFSR[2:0])
      // golden: x[0]?0 : x[1]?1 : {1'b1, ~x[2]}
      firstEntry = u_canAllocMask[b][0] ? TIDX_W'(0)
                 : u_canAllocMask[b][1] ? TIDX_W'(1)
                 : {1'b1, ~u_canAllocMask[b][2]};
      for (int unsigned t = 0; t < NUM_TBL; t++) lfsr_masked[t] = u_canAllocMask[b][t] & alloc_lfsr[b][t];
      maskedEntry = lfsr_masked[0] ? TIDX_W'(0)
                  : lfsr_masked[1] ? TIDX_W'(1)
                  : {1'b1, ~lfsr_masked[2]};
      // allocate = canAllocMask[maskedEntry] ? maskedEntry : firstEntry
      //   (canAllocMask >> maskedEntry)[0]：用扫描复刻变量下标，避免 FMR_ELAB-147
      masked_hit = 1'b0;
      for (int unsigned t = 0; t < NUM_TBL; t++)
        if (TIDX_W'(t) == maskedEntry) masked_hit = u_canAllocMask[b][t];
      allocate = masked_hit ? maskedEntry : firstEntry;
      u_alloc_idx[b] = allocate;

      do_alloc = u_needToAlloc[b] & u_canAllocate[b];

      // 逐表最终写口（与 golden 各 *_r 表达式逐位对齐；含 don't-care 兜底）：
      //   alloc_to_t    = do_alloc & (allocate==t)
      //   is_prov_t     = prov_valid & (provider==t)
      //   mask[t]       = alloc_to_t | (updateValids & is_prov_t)
      //   alloc[t]      = alloc_to_t
      //   uMask[t]      = alloc_to_t | (updateValids & is_prov_t & altDiffers)
      //   us[t]         = ~alloc_to_t & updateProviderCorrect      （don't-care 填 provCorrect）
      //   takens[t]     = updateTaken                              （don't-care 填 updateTaken）
      //   oldCtr[t]     = providerResps.ctr                        （don't-care 填 providerResps.ctr）
      for (int unsigned t = 0; t < NUM_TBL; t++) begin
        logic alloc_to_t, is_prov_t;
        alloc_to_t = do_alloc & (allocate == TIDX_W'(t));
        is_prov_t  = um_prov_valid[b] & (um_prov_bits[b] == TIDX_W'(t));
        fin_updateMask[b][t]   = alloc_to_t | (u_has_update[b] & is_prov_t);
        fin_updateAlloc[b][t]  = alloc_to_t;
        fin_updateUMask[b][t]  = alloc_to_t | (u_has_update[b] & is_prov_t & u_alt_differs[b]);
        fin_updateU[b][t]      = ~alloc_to_t & u_prov_correct[b];
        fin_updateTaken[b][t]  = u_taken[b];
        fin_updateOldCtr[b][t] = um_prov_ctr[b];
      end
    end
  end

  // ===========================================================================
  // SC 更新组合逻辑（每 bank）
  //   tableSum = ParallelSignedExpandingAdd(scOldCtrs.map(getCentered))
  //   sumAboveThreshold = aboveThreshold(tableSum, getPvdrCentered(pvdrCtr), updateThres)
  //   updateThres = (useThreshold<<3) + 21
  //   阈值自适应：scPred != tagePred 且 |totalSum| 在 [thres-4, thres-2] → scThresholds.update
  //   写表：scPred != taken 或 ~sumAboveThreshold → scUpdateMask 全置；
  // ===========================================================================
  logic signed [8:0]  u_sc_tableSum [NUM_BR];
  logic [9:0]         u_sc_tot10    [NUM_BR];   // golden sumAboveThreshold_totalSum（10 位）
  logic [9:0]         u_sc_totAbs10 [NUM_BR];   // golden _totalSumAbs_T_8（10 位）
  logic               u_sc_aboveThr [NUM_BR];
  logic               u_sc_thr_cause [NUM_BR];     // scPred != taken（阈值 ctr 增减方向）
  logic               u_sc_do_thr_upd [NUM_BR];
  logic               u_sc_do_write   [NUM_BR];

  // 位宽逐一对齐 golden（10/12/13 位；8 位 thres-4 减法带回绕）——
  // 常规值域下与原 12 位写法等值，但 FM 视寄存器为自由变量，位宽/回绕必须逐位一致。
  always_comb begin
    for (int unsigned b = 0; b < NUM_BR; b++) begin
      logic signed [8:0]  ts;
      logic [2:0]         t3;
      logic [9:0]         pvdr10;
      logic [11:0]        thres12;
      logic [12:0]        thres13, pvdr13, ts13;
      ts = '0;
      for (int unsigned t = 0; t < SC_NTBL; t++)
        ts += $signed({um_sc_ctrs[b][t], 1'b1});       // getCentered
      u_sc_tableSum[b] = ts;

      t3      = um_prov_ctr[b] ^ 3'h4;                  // getPvdrCentered 的 ctr^4
      pvdr10  = {{3{t3[2]}}, t3, 4'h8};                 // golden _GEN_85
      u_sc_tot10[b]    = 10'({ts[8], ts} + pvdr10);     // golden totalSum（10 位）
      u_sc_totAbs10[b] = u_sc_tot10[b][9] ? 10'(10'h0 - u_sc_tot10[b]) : u_sc_tot10[b];

      thres12 = 12'({1'b0, sc_thr_thres[b], 3'h0} + 12'h15);  // useThreshold<<3 + 21
      thres13 = {1'b0, thres12};                        // golden _GEN_86
      pvdr13  = {{6{t3[2]}}, t3, 4'h8};                 // golden _GEN_87
      ts13    = {{4{ts[8]}}, ts};                       // golden _GEN_88
      u_sc_aboveThr[b] =
        (($signed(ts13) > $signed(13'(thres13 - pvdr13))) & ~u_sc_tot10[b][9]) |
        (($signed(ts13) < $signed(13'(13'(13'h0 - thres13) - pvdr13))) & u_sc_tot10[b][9]);

      // tagePred = updateMeta.takens(w) = altUsed ? basecnt[1] : providerResp.ctr 最高位
      u_sc_tagePred[b] = um_alt_used[b] ? um_basecnt[b][1] : um_prov_ctr[b][TAGE_CTR_W-1];
      u_sc_taken[b]    = upd_br_taken[b];

      u_sc_thr_cause[b] = (um_sc_preds[b] != upd_br_taken[b]);
      // 阈值更新条件：scPred != tagePred 且 |totalSum| ∈ [thres-4, thres-2]
      //（golden：8 位减法带回绕后 {2'h0,...} 零扩到 10 位再比较）
      u_sc_do_thr_upd[b] = update_valids[b] & um_prov_valid[b]
                         & (um_sc_preds[b] != u_sc_tagePred[b])
                         & (u_sc_totAbs10[b] >= {2'h0, 8'(sc_thr_thres[b] - 8'h4)})
                         & (u_sc_totAbs10[b] <= {2'h0, 8'(sc_thr_thres[b] - 8'h2)});
      // 写表条件：scPred != taken 或 ~sumAboveThreshold
      u_sc_do_write[b] = update_valids[b] & um_prov_valid[b]
                       & ((um_sc_preds[b] != upd_br_taken[b]) | ~u_sc_aboveThr[b]);
      sc_upd_valid_b[b] = u_sc_do_write[b];
    end
  end

  // perf 事件两拍流水（golden io_perf_N_value_REG/REG_1 在无复位块）：
  //   perf0 = 两 bank provider 命中数；perf1 = sc 更新且 scPred 错；perf2 = sc 更新且 scPred 对
  always_ff @(posedge clock) begin
    perf0_s1 <= 2'({1'b0, um_prov_valid[0]} + {1'b0, um_prov_valid[1]});
    perf0_s2 <= perf0_s1;
    perf1_s1 <= 2'({1'b0, u_sc_do_write[0] & u_sc_thr_cause[0]}
                 + {1'b0, u_sc_do_write[1] & u_sc_thr_cause[1]});
    perf1_s2 <= perf1_s1;
    perf2_s1 <= 2'({1'b0, u_sc_do_write[0] & ~u_sc_thr_cause[0]}
                 + {1'b0, u_sc_do_write[1] & ~u_sc_thr_cause[1]});
    perf2_s2 <= perf2_s1;
  end

  // ===========================================================================
  // 寄存器更新：useAltOnNa / scThresholds / tick / 基预测器更新值
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int unsigned b = 0; b < NUM_BR; b++) begin
        for (int unsigned k = 0; k < NUM_UAON; k++)
          use_alt_on_na[b][k] <= UAON_W'(1 << (UAON_W-1));   // 初值中点 8
        bank_tick_ctr[b]  <= '0;
        bank_tick_dist[b] <= TICK_MAX;
        sc_thr_ctr[b]     <= SC_THR_W'(1 << (SC_THR_W-1));    // neutral 16
        sc_thr_thres[b]   <= 8'd6;                            // initVal 6
      end
    end else begin
      for (int unsigned b = 0; b < NUM_BR; b++) begin
        // useAltOnNa：provider 弱置信 且 altDiffers → 按 altCorrect 饱和增减
        if (u_has_update[b] & um_prov_valid[b] & u_prov_weak[b] & u_alt_differs[b]) begin
          logic [UAON_W-1:0] cur, nxt;
          cur = use_alt_on_na[b][upd_alt_idx];
          // satUpdate(ctr, W, up)：up 时 +1 封顶，down 时 -1 封底
          if (u_alt_correct[b]) nxt = (cur == '1) ? cur : (cur + 1'b1);
          else                  nxt = (cur == '0) ? cur : (cur - 1'b1);
          use_alt_on_na[b][upd_alt_idx] <= nxt;
        end

        // SC 阈值自适应
        if (u_sc_do_thr_upd[b]) begin
          logic [SC_THR_W-1:0] newctr;
          logic                satpos, satneg;
          // satUpdate(ctr, W, cause)：cause=scPred!=taken
          if (u_sc_thr_cause[b]) newctr = (sc_thr_ctr[b] == '1) ? sc_thr_ctr[b] : (sc_thr_ctr[b] + 1'b1);
          else                   newctr = (sc_thr_ctr[b] == '0) ? sc_thr_ctr[b] : (sc_thr_ctr[b] - 1'b1);
          satpos = (newctr == '1);
          satneg = (newctr == '0);
          // newThres
          if (satpos & (sc_thr_thres[b] <= 8'd31)) sc_thr_thres[b] <= sc_thr_thres[b] + 8'd2;
          else if (satneg & (sc_thr_thres[b] >= 8'd6)) sc_thr_thres[b] <= sc_thr_thres[b] - 8'd2;
          // newCtr：饱和则回中点，否则 newctr
          sc_thr_ctr[b] <= (satpos | satneg) ? SC_THR_W'(1 << (SC_THR_W-1)) : newctr;
        end

        // tick 计数器（needToAllocate 时调节）
        if (u_needToAlloc[b]) begin
          logic tickToPosSat, tickToNegSat;
          tickToPosSat = (u_tickIncVal[b] >= bank_tick_dist[b]) & u_tickInc[b];
          tickToNegSat = (u_tickDecVal[b] >= bank_tick_ctr[b])  & u_tickDec[b];
          if (u_tickInc[b]) begin
            if (tickToPosSat) begin
              bank_tick_ctr[b]  <= TICK_MAX;
              bank_tick_dist[b] <= '0;
            end else begin
              bank_tick_ctr[b]  <= bank_tick_ctr[b]  + u_tickIncVal[b];
              bank_tick_dist[b] <= bank_tick_dist[b] - u_tickIncVal[b];
            end
          end else if (u_tickDec[b]) begin
            if (tickToNegSat) begin
              bank_tick_ctr[b]  <= '0;
              bank_tick_dist[b] <= TICK_MAX;
            end else begin
              bank_tick_ctr[b]  <= bank_tick_ctr[b]  - u_tickDecVal[b];
              bank_tick_dist[b] <= bank_tick_dist[b] + u_tickDecVal[b];
            end
          end
          // tick 饱和（== MAX）→ 复位 + reset_u（注：在 needToAllocate 块内，覆盖上面的赋值）
          if (bank_tick_ctr[b] == TICK_MAX) begin
            bank_tick_ctr[b]  <= '0;
            bank_tick_dist[b] <= TICK_MAX;
          end
        end
      end
    end
  end

  // updateResetU：needToAllocate 且 bankTickCtrs==MAX
  always_comb
    for (int unsigned b = 0; b < NUM_BR; b++)
      u_updateResetU[b] = u_needToAlloc[b] & (bank_tick_ctr[b] == TICK_MAX);

  // 基预测器更新
  always_comb begin
    for (int unsigned b = 0; b < NUM_BR; b++) begin
      u_baseupdate[b] = u_has_update[b] & um_alt_used[b];
      u_updatebcnt[b] = um_basecnt[b];
      u_bUpdTaken[b]  = u_taken[b];
    end
  end

  // ===========================================================================
  // 各子表 / 基表 update 端口寄存（下一拍送进表）
  //   realWen[t] = OR over banks of fin_updateMask[b][t]（合入分配后的写使能）
  //   golden: tables(i).io.update.mask(w) := RegNext(updateMask(w)(i))
  //           takens/alloc/oldCtrs/uMask/us := RegEnable(..., realWen)
  //           reset_u(w) := RegNext(updateResetU(w))；pc/ghist := RegEnable(..., realWen)
  // ===========================================================================
  wire realWen [NUM_TBL];
  genvar gt;
  generate
    for (gt = 0; gt < NUM_TBL; gt++) begin : g_realwen
      assign realWen[gt] = fin_updateMask[0][gt] | fin_updateMask[1][gt];
    end
  endgenerate

  always_ff @(posedge clock) begin
    for (int unsigned t = 0; t < NUM_TBL; t++) begin
      // mask = RegNext(updateMask)；reset_u = RegNext(updateResetU)
      for (int unsigned b = 0; b < NUM_BR; b++) begin
        tbl_upd_mask[t][b]    <= fin_updateMask[b][t];
        tbl_upd_reset_u[t][b] <= u_updateResetU[b];
      end
      // 数据端口：realWen 使能打入
      if (realWen[t]) begin
        for (int unsigned b = 0; b < NUM_BR; b++) begin
          tbl_upd_takens[t][b] <= fin_updateTaken[b][t];
          tbl_upd_alloc[t][b]  <= fin_updateAlloc[b][t];
          tbl_upd_oldCtrs[t][b]<= fin_updateOldCtr[b][t];
          tbl_upd_uMask[t][b]  <= fin_updateUMask[b][t];
          tbl_upd_us[t][b]     <= fin_updateU[b][t];
        end
        tbl_upd_pc[t]    <= io_update_pc;
        tbl_upd_ghist[t] <= upd_ghist;
      end
    end
  end

  // 基预测器 update 寄存
  wire any_baseupdate = u_baseupdate[0] | u_baseupdate[1];
  always_ff @(posedge clock) begin
    for (int unsigned b = 0; b < NUM_BR; b++)
      bt_upd_mask[b] <= u_baseupdate[b];
    if (any_baseupdate) begin
      for (int unsigned b = 0; b < NUM_BR; b++) begin
        bt_upd_cnt[b]    <= u_updatebcnt[b];
        bt_upd_takens[b] <= u_bUpdTaken[b];
      end
      bt_upd_pc <= io_update_pc;
    end
  end

  // SC 子表 update 寄存
  //   scTables(i).io.update.mask(b) := RegNext(scUpdateMask(b)(i))
  //   tagePreds/takens/oldCtrs/pc/ghist := RegEnable(..., realWen_sc(i))
  wire sc_realWen [SC_NTBL];
  genvar gs;
  generate
    for (gs = 0; gs < SC_NTBL; gs++) begin : g_sc_realwen
      // scUpdateMask(b)(i)：写表时整行 4 表都置位，故 realWen = OR bank
      assign sc_realWen[gs] = sc_upd_valid_b[0] | sc_upd_valid_b[1];
    end
  endgenerate

  always_ff @(posedge clock) begin
    for (int unsigned t = 0; t < SC_NTBL; t++) begin
      for (int unsigned b = 0; b < NUM_BR; b++)
        sc_upd_mask[t][b] <= sc_upd_valid_b[b];
      if (sc_realWen[t]) begin
        for (int unsigned b = 0; b < NUM_BR; b++) begin
          sc_upd_tagePreds[t][b] <= u_sc_tagePred[b];
          sc_upd_takens[t][b]    <= u_sc_taken[b];
          sc_upd_oldCtrs[t][b]   <= um_sc_ctrs[b][t];
        end
        sc_upd_pc[t]    <= io_update_pc;
        sc_upd_ghist[t] <= upd_ghist;
      end
    end
  end

endmodule
