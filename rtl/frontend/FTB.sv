// =============================================================================
// xs_FTB_core —— FTB（Fetch Target Buffer）预测器顶层（可读重写核）
//
// 对应 Chisel: xiangshan.frontend.FTB（FTB.scala）
//
// 【FTB 在 BPU 中的角色】
//   香山前端用「多级覆盖式」分支预测：S1 级有零气泡的微型 uFTB（xs_FauFTB），
//   随后是这个大容量 FTB——它在 S1 发起 SRAM 读、S2 给出命中条目并解码出
//   「分支槽目标 / fall-through 地址 / 是否命中」、S3 再寄存一拍输出最终预测，
//   覆盖（override）uFTB 的结果交给 FTQ。提交（commit/redirect）时 FTQ 把已
//   生成好的新条目经 update 通道写回 FTB 的 SRAM。
//
// 【三级流水（s1→s2→s3）】
//   s0(组合)：BPU 给 s0_pc，本模块把 (s0_fire & !close) 作为 FTBBank 的预测读请求。
//   s1      ：FTBBank 输出 read_resp（命中条目）+ read_hits；本级算 s1_hit。
//   s2      ：把 read_resp / uFTB 条目 / hit 寄存进来，按 close_ftb_req 二选一得到
//             「本拍要用的条目 s2_ftb_entry」，并组合解码出 targets/fallThrough/各标志。
//   s3      ：再寄存一拍（含 multi-hit 兜底替换），输出 last_stage 预测与 ftb_entry。
//
//   每个流水量都按 4 路「dup」复制（io_*_fire_0..3 / *_dup_0..3）——这是物理扇出
//   复制（同值多副本，降低长线负载），不是功能多端口。本核用 [NDUP] 数组 + genvar
//   表达，与 golden 的 _dup_n 一一对应。dup0 额外承载 close_ftb/meta/一致性计数等
//   全局状态（其余 dup 只有 entry/pc/hit）。
//
// 【目标地址解码（last_stage_pc 的 higher/middle 三段）】
//   slot 只存目标低位 lower 与高位状态 tarStat（FIT/OVF/UDF，见 xs_ftb_pkg）。
//   重建完整目标要 PC 高位 ±1。为放松时序，golden 在打拍时预先算好
//   pc_higher / pc_middle / 各自的 ±1，组合期只做 Mux1H 选择拼接。本核保留这套
//   预算结构（last_stage_pc_*），并用纯函数 decode_target 表达拼接，复用语义。
//
// 【fall-through 地址与 fallThroughErr】
//   pftAddr(4b)+carry 描述顺序落点的块内低位。fallThroughErr：落点早于 PC 当前
//   offset、或落点超出一个取指块(>16 半字) → 视为非法，回退成 pc+0x20。
//
// 【close_ftb_req（关闭 FTB 请求）】
//   当连续多拍发现 FTB 与 uFTB 给出的条目完全一致（一致计数器 > 阈值 0x1F3），
//   说明 uFTB 已足够，便「关闭」FTB 预测读（节能/省带宽）：close 时改用 uFTB 条目，
//   且不再向 FTBBank 发读。遇到 false_hit 或 IFU 重定向(needReopen)时重开。
//
// 【multi-hit 兜底】
//   FTBBank 在 s2 报多路同时命中(read_multi_*)；本核在 s2→s3 用 multi 条目替换正常
//   条目并把 multiHit 标志带到 s3，让上层在 s3 触发纠正性重定向。
//
// 【update 写回路径】
//   FTQ 经 update 通道给来「已算好的」新 ftb_entry（注意：新条目的生成在 FTQ 的
//   FTBEntryGen 内，不在本模块）。本核：
//     · 把 update_bits 打一拍成 update_r；据 meta[64]（old_entry 标志的 update_now）
//       决定「立即写」还是「先读后写」(need_read：先查命中路再延 2 拍写)；
//     · need_read 时向 FTBBank 发更新读(u_req)，FTBBank 回 update_hits 决定改写命中路
//       还是新分配；本核把写 way/alloc 打一拍 (ftbBank_io_update_write_*_REG)；
//     · 写数据/写 PC 经 DelayNWithValid 延 2 拍与读结果对齐，再驱动 FTBBank 写口。
//
//   注：golden 的 `ifndef SYNTHESIS 断言块（一致性 assert、fallThrough assert）、
//   debug pc「modified」标志只是把「是否变化」单独提出、s2_pc_dup_debug_s2_pc_addr
//   等纯 debug 线，对端口输出无影响，本核不实现可观测逻辑之外的部分。
//
// 子模块（FTBBank / DelayNWithValid / DelayNWithValid_1 / DelayN_1）按 golden 同名
// 当黑盒，由 FTB_wrapper 例化；本核通过结构化端口与之对接。复用 xs_ftb_pkg。
// =============================================================================
module xs_FTB_core
  import xs_ftb_pkg::*;
#(
  parameter int unsigned NDUP   = 4,   // 流水扇出复制份数（dup_0..3）
  parameter int unsigned PC_W   = 50,
  parameter int unsigned META_W = 67   // {way[1:0], hit, counter[63:0]} = 2+1+64
)(
  input  logic              clock,
  input  logic              reset,

  input  logic [47:0]       io_reset_vector,

  // ---- s0 输入 PC（4 路 dup）+ 各级 fire / ready ----
  input  logic [PC_W-1:0]   io_in_bits_s0_pc [NDUP],
  input  logic              io_s0_fire [NDUP],
  input  logic              io_s1_fire [NDUP],
  input  logic              io_s2_fire [NDUP],
  input  logic              io_s3_fire_0,
  output logic              io_s1_ready,
  input  logic              io_ctrl_btb_enable,

  // ---- 上游预测结果透传（br_taken_mask 取或；sc_disagree 直通） ----
  input  logic [1:0]        io_in_s2_br_taken_mask [NDUP],
  input  logic [1:0]        io_in_s3_br_taken_mask [NDUP],
  input  logic [1:0]        io_in_last_stage_sc_disagree,

  // ---- uFTB(FauFTB) 在 s1 给来的条目（命中则可关闭 FTB） ----
  input  ftb_entry_t        io_fauftb_entry_in,
  input  logic              io_fauftb_entry_hit_in,

  // ---- s2 预测输出（4 路 dup，各字段见接口表） ----
  output logic [1:0]        io_out_s2_br_taken_mask [NDUP],
  output logic [1:0]        io_out_s2_slot_valids   [NDUP],
  output logic [PC_W-1:0]   io_out_s2_targets_0     [NDUP],  // brSlot 目标
  output logic [PC_W-1:0]   io_out_s2_targets_1     [NDUP],  // tailSlot 目标
  output logic [PC_W-1:0]   io_out_s2_jalr_target   [NDUP],  // = targets_1
  output logic [OFFSET_W-1:0] io_out_s2_offsets_0   [NDUP],
  output logic [OFFSET_W-1:0] io_out_s2_offsets_1   [NDUP],
  output logic [PC_W-1:0]   io_out_s2_fallThroughAddr [NDUP],
  output logic              io_out_s2_fallThroughErr  [NDUP],
  output logic              io_out_s2_is_jal   [NDUP],
  output logic              io_out_s2_is_jalr  [NDUP],
  output logic              io_out_s2_is_call  [NDUP],
  output logic              io_out_s2_is_ret   [NDUP],
  output logic              io_out_s2_last_may_be_rvi_call [NDUP],
  output logic              io_out_s2_is_br_sharing [NDUP],
  output logic              io_out_s2_hit      [NDUP],

  // ---- s3 预测输出（4 路 dup，多 multiHit，无 jalr_target） ----
  output logic [1:0]        io_out_s3_br_taken_mask [NDUP],
  output logic [1:0]        io_out_s3_slot_valids   [NDUP],
  output logic [PC_W-1:0]   io_out_s3_targets_0     [NDUP],
  output logic [PC_W-1:0]   io_out_s3_targets_1     [NDUP],
  output logic [OFFSET_W-1:0] io_out_s3_offsets_0   [NDUP],
  output logic [OFFSET_W-1:0] io_out_s3_offsets_1   [NDUP],
  output logic [PC_W-1:0]   io_out_s3_fallThroughAddr [NDUP],
  output logic              io_out_s3_fallThroughErr  [NDUP],
  output logic              io_out_s3_multiHit [NDUP],
  output logic              io_out_s3_is_jal   [NDUP],
  output logic              io_out_s3_is_jalr  [NDUP],
  output logic              io_out_s3_is_call  [NDUP],
  output logic              io_out_s3_is_ret   [NDUP],
  output logic              io_out_s3_last_may_be_rvi_call [NDUP],
  output logic              io_out_s3_is_br_sharing [NDUP],
  output logic              io_out_s3_hit      [NDUP],

  // ---- s1 杂项输出 ----
  output logic              io_out_s1_uftbHit,
  output logic              io_out_s1_uftbHasIndirect,
  output logic              io_out_s1_ftbCloseReq,

  // ---- last_stage meta / spec_info / ftb_entry（s3 dup0） ----
  output logic [515:0]      io_out_last_stage_meta,
  output logic [1:0]        io_out_last_stage_sc_disagree,
  output ftb_entry_t        io_out_last_stage_ftb_entry,

  // ---- update 写回通道（← FTQ commit；新条目已由 FTQ 算好） ----
  input  logic              io_update_valid,
  input  logic [PC_W-1:0]   io_update_bits_pc,
  input  ftb_entry_t        io_update_bits_ftb_entry,
  input  logic              io_update_bits_false_hit,
  input  logic              io_update_bits_old_entry,
  input  logic [515:0]      io_update_bits_meta,
  input  logic              io_redirectFromIFU,

  // ---- perf ----
  output logic [5:0]        io_perf_0_value,
  output logic [5:0]        io_perf_1_value,

  // ===== 与 FTBBank（黑盒）对接：预测读 / 更新读 / 更新写 =====
  output logic              ftbBank_io_s1_fire,
  output logic              ftbBank_io_req_pc_valid,
  output logic [PC_W-1:0]   ftbBank_io_req_pc_bits,
  input  logic              ftbBank_io_req_pc_ready,
  input  ftb_entry_t        ftbBank_read_resp,
  input  logic              ftbBank_io_read_hits_valid,
  input  logic [1:0]        ftbBank_io_read_hits_bits,
  input  ftb_entry_t        ftbBank_read_multi_entry,
  input  logic              ftbBank_io_read_multi_hits_valid,
  input  logic [1:0]        ftbBank_io_read_multi_hits_bits,
  output logic              ftbBank_io_u_req_pc_valid,
  output logic [PC_W-1:0]   ftbBank_io_u_req_pc_bits,
  input  logic              ftbBank_io_update_hits_valid,
  input  logic [1:0]        ftbBank_io_update_hits_bits,
  output logic              ftbBank_io_update_access,
  output logic [PC_W-1:0]   ftbBank_io_update_pc,
  output logic              ftbBank_io_update_write_data_valid,
  output ftb_entry_t        ftbBank_update_write_entry,
  output logic [19:0]       ftbBank_io_update_write_tag,
  output logic [1:0]        ftbBank_io_update_write_way,
  output logic              ftbBank_io_update_write_alloc,

  // ===== 与 DelayNWithValid（pc 延 2 拍，黑盒）对接 =====
  output logic [PC_W-1:0]   delay_pc_in_bits,
  output logic              delay_pc_in_valid,
  input  logic [PC_W-1:0]   delay_pc_out_bits,

  // ===== 与 DelayNWithValid_1（entry 延 2 拍，黑盒）对接 =====
  output ftb_entry_t        delay_entry_in_bits,
  output logic              delay_entry_in_valid,
  input  ftb_entry_t        delay_entry_out_bits,

  // ===== 与 DelayN_1（write_valid 延 2 拍，黑盒）对接 =====
  output logic              delay_wv_in,
  input  logic              delay_wv_out
);

  localparam int unsigned CONSISTENT_THRESH = 9'h1F3; // 一致计数关闭 FTB 阈值
  localparam logic [1:0]   TS_OVF = TAR_OVF;           // 2'h1
  localparam logic [1:0]   TS_UDF = TAR_UDF;           // 2'h2
  localparam logic [1:0]   TS_FIT = TAR_FIT;           // 2'h0

  // ===========================================================================
  // 纯函数
  // ===========================================================================

  // 目标高位重建：据 tarStat 在 {h, h+1, h-1} 中 one-hot 选一个（Mux1H）。
  // higher 是预算好的「PC 高位段」，p1/m1 是其 ±1。返回 37b（高 29 + 中 8）。
  function automatic logic [36:0] sel_higher(
      input logic [1:0]  tarStat,
      input logic [36:0] higher, input logic [36:0] higher_p1, input logic [36:0] higher_m1);
    return ({37{tarStat == TS_OVF}} & higher_p1)
         | ({37{tarStat == TS_UDF}} & higher_m1)
         | ({37{tarStat == TS_FIT}} & higher);
  endfunction

  // 目标高 29b（仅高段，用于非共享 tailSlot 的 20b lower 情形）。
  function automatic logic [28:0] sel_higher29(
      input logic [1:0]  tarStat,
      input logic [28:0] higher, input logic [28:0] higher_p1, input logic [28:0] higher_m1);
    return ({29{tarStat == TS_OVF}} & higher_p1)
         | ({29{tarStat == TS_UDF}} & higher_m1)
         | ({29{tarStat == TS_FIT}} & higher);
  endfunction

  // fallThroughErr：落点(endLowerwithCarry 5b) 不在 [pc_off, pc_off+16] 区间内。
  //   pc_off = pc_seg2[4:1]（块内 offset 低位，0 扩到 5b）。
  function automatic logic ft_err(input logic [3:0] pc_off, input logic [4:0] end_lc);
    logic [4:0] base; base = {1'b0, pc_off};
    return (base >= end_lc) | (end_lc > (base - 5'h10));
  endfunction

  // 两条 FTB 条目「内容相等」（uFTB 一致性判定用）：逐有意义字段比较，
  // brSlot.lower 只比有效低 12 位（高 8 位无意义/不驱动），与 golden 比较项一致。
  function automatic logic entry_eq(input ftb_entry_t a, input ftb_entry_t b);
    return  (a.valid     == b.valid)
          & (a.brSlot.offset  == b.brSlot.offset)
          & (a.brSlot.lower[BR_OFF_LEN-1:0] == b.brSlot.lower[BR_OFF_LEN-1:0])
          & (a.brSlot.tarStat == b.brSlot.tarStat)
          & (a.brSlot.sharing == b.brSlot.sharing)
          & (a.brSlot.valid   == b.brSlot.valid)
          & (a.tailSlot.offset  == b.tailSlot.offset)
          & (a.tailSlot.lower   == b.tailSlot.lower)
          & (a.tailSlot.tarStat == b.tailSlot.tarStat)
          & (a.tailSlot.sharing == b.tailSlot.sharing)
          & (a.tailSlot.valid   == b.tailSlot.valid)
          & (a.pftAddr == b.pftAddr)
          & (a.carry   == b.carry)
          & (a.isCall  == b.isCall)
          & (a.isRet   == b.isRet)
          & (a.isJalr  == b.isJalr)
          & (a.last_may_be_rvi_call == b.last_may_be_rvi_call)
          & (a.strong_bias[0] == b.strong_bias[0])
          & (a.strong_bias[1] == b.strong_bias[1]);
  endfunction

  // ===========================================================================
  // s0/s1：复位向量注入 + s1 PC 寄存（4 路 dup）
  //   上电头两拍把 reset_vector 当 s1_pc（REG/REG_1 链同 golden）。
  // ===========================================================================
  logic                 REG, REG_1;
  logic [PC_W-1:0]      s1_pc [NDUP];
  wire  [PC_W-1:0]      reset_vec_pc = {2'h0, io_reset_vector};

  always_ff @(posedge clock) begin
    REG   <= reset;
    REG_1 <= REG & ~reset;
    if (REG_1) begin
      for (int d = 0; d < NDUP; d++) s1_pc[d] <= reset_vec_pc;
    end else begin
      for (int d = 0; d < NDUP; d++) if (io_s0_fire[d]) s1_pc[d] <= io_in_bits_s0_pc[d];
    end
  end

  // ===========================================================================
  // close_ftb_req 流水（s0→s1→s2）+ uFTB 一致性计数器
  // ===========================================================================
  logic s0_close, s1_close, s2_close;
  logic [8:0] consistent_cnt;

  // ===========================================================================
  // s1 命中：!close & FTBBank 命中 & btb 使能
  // ===========================================================================
  wire s1_hit = ~s1_close & ftbBank_io_read_hits_valid & io_ctrl_btb_enable;

  // ===========================================================================
  // s2 寄存：uFTB 条目 / FTBBank 条目 / hit；s2 选用条目 = close ? uFTB : FTBBank
  // ===========================================================================
  ftb_entry_t s2_fauftb_entry [NDUP];
  logic       s2_fauftb_hit   [NDUP];
  ftb_entry_t s2_ftbBank      [NDUP];
  logic       s2_ftb_hit      [NDUP];

  // s2 实际使用条目 / hit（按 close 二选一）
  ftb_entry_t s2_entry [NDUP];
  logic       s2_hit   [NDUP];
  always_comb begin
    for (int d = 0; d < NDUP; d++) begin
      s2_entry[d] = s2_close ? s2_fauftb_entry[d] : s2_ftbBank[d];
      s2_hit[d]   = s2_close ? s2_fauftb_hit[d]   : s2_ftb_hit[d];
    end
  end

  // ===========================================================================
  // s2 PC 三段分割：seg0=pc[49:24](26b), seg1=pc[23:12](12b), seg2=pc[11:0](12b)
  //   golden 用「modified」门控仅在变化时更新（功能上等价于 fire 时更新），
  //   且异步复位清 0。每拍只在「该段与上一拍 s1_pc 对应段不同 且 s1_fire」时更新。
  // ===========================================================================
  logic [25:0] s2_seg0 [NDUP];
  logic [11:0] s2_seg1 [NDUP];
  logic [11:0] s2_seg2 [NDUP];

  // ===========================================================================
  // s2 last_stage_pc 预算段（用于目标高位重建）：higher(29)/middle(8)/各 ±1
  //   来源：s1_pc[49:21] 为 higher、s1_pc[20:13] 为 middle。
  // ===========================================================================
  logic [28:0] s2_pc_higher    [NDUP];
  logic [7:0]  s2_pc_middle    [NDUP];
  logic [28:0] s2_pc_higher_p1 [NDUP];
  logic [28:0] s2_pc_higher_m1 [NDUP];
  logic [8:0]  s2_pc_middle_p1 [NDUP];
  logic [8:0]  s2_pc_middle_m1 [NDUP];
  logic        s2_stashed_carry [NDUP];  // s1 read_resp.carry 打拍（fallThrough 用）

  // s1 选用条目的 carry（close 时取 uFTB）
  wire s1_read_resp_carry = s1_close ? io_fauftb_entry_in.carry : ftbBank_read_resp.carry;

  // ===========================================================================
  // s2 meta：{way, hit, counter}（counter 是自由计数，仅占位）
  // ===========================================================================
  logic [63:0] s2_meta_cnt;          // s2_ftb_meta_c
  logic [63:0] s2_multi_meta_cnt;    // s2_multi_hit_meta_c
  logic [META_W-1:0] s2_meta;        // {hits_bits, s1_hit, cnt}

  // ===========================================================================
  // s2 multi-hit 探测（FTBBank 报多命中 & s2_fire & !close）
  // ===========================================================================
  wire s2_multi_hit       = ftbBank_io_read_multi_hits_valid & io_s2_fire[0];
  wire s2_multi_hit_en    = s2_multi_hit & ~s2_close;

  // ===========================================================================
  // s2 组合解码：targets / fallThrough / 各 CFI 标志（逐 dup）
  //   higher_br = {higher, middle}（37b）；targets_0 用 brSlot，targets_1 用 tailSlot
  //   （tailSlot 共享时 lower 仅低 12 位、否则 20 位 → 高位段宽不同）。
  // ===========================================================================
  // 组合 higher 段（每 dup）
  wire [36:0] s2_higher_br    [NDUP];
  wire [36:0] s2_higher_p1_br [NDUP];
  wire [36:0] s2_higher_m1_br [NDUP];
  generate
    for (genvar gd = 0; gd < NDUP; gd++) begin : g_s2_higher
      assign s2_higher_br[gd]    = {s2_pc_higher[gd], s2_pc_middle[gd]};
      // middle±1 的进位决定 higher 段是否换 ±1（与 golden 拼接逻辑一致）
      assign s2_higher_p1_br[gd] = {s2_pc_middle_p1[gd][8] ? s2_pc_higher_p1[gd] : s2_pc_higher[gd],
                                    s2_pc_middle_p1[gd][7:0]};
      assign s2_higher_m1_br[gd] = {s2_pc_middle_m1[gd][8] ? s2_pc_higher_m1[gd] : s2_pc_higher[gd],
                                    s2_pc_middle_m1[gd][7:0]};
    end
  endgenerate

  // s2 fallThroughErr（用「修正后」条目：multi-hit 时用 multi 条目的 pft/carry）
  //   注意：fallThroughErr 影响 s3 寄存（real_s3_fallThroughErr），故 dup0 用 real_*。
  wire [3:0] s2_pf_off [NDUP];          // pc_seg2[4:1]
  wire [4:0] s2_endlc  [NDUP];          // {carry, pftAddr}（正常条目）
  generate
    for (genvar gd = 0; gd < NDUP; gd++) begin : g_s2_ft
      assign s2_pf_off[gd] = s2_seg2[gd][4:1];
      assign s2_endlc[gd]  = {s2_entry[gd].carry, s2_entry[gd].pftAddr};
    end
  endgenerate
  wire [4:0] s2_endlc0_err = {s2_entry[0].carry, s2_entry[0].pftAddr};
  // multi-hit 时 dup0 用 multi 条目的 pft/carry 算 fallThroughErr（real_s2_*）
  wire [3:0] real_s2_pft   = s2_multi_hit_en ? ftbBank_read_multi_entry.pftAddr : s2_entry[0].pftAddr;
  wire       real_s2_carry = s2_multi_hit_en ? ftbBank_read_multi_entry.carry   : s2_entry[0].carry;
  wire       real_s2_ft_err = ft_err(s2_pf_off[0], {real_s2_carry, real_s2_pft});

  // s2 各 dup 的 fallThroughErr（输出用，恒按正常条目；dup0 输出也按正常条目）
  wire s2_ft_err [NDUP];
  generate
    for (genvar gd = 0; gd < NDUP; gd++) begin : g_s2_fterr
      assign s2_ft_err[gd] = ft_err(s2_pf_off[gd], s2_endlc[gd]);
    end
  endgenerate

  // ---- s2 输出组合：逐 dup ----
  generate
    for (genvar gd = 0; gd < NDUP; gd++) begin : g_s2_out
      ftb_entry_t e; assign e = s2_entry[gd];
      // br_taken_mask：上游 | (hit & strong_bias)
      assign io_out_s2_br_taken_mask[gd][0] = io_in_s2_br_taken_mask[gd][0] | (s2_hit[gd] & e.strong_bias[0]);
      assign io_out_s2_br_taken_mask[gd][1] = io_in_s2_br_taken_mask[gd][1] | (s2_hit[gd] & e.strong_bias[1]);
      assign io_out_s2_slot_valids[gd][0]   = e.brSlot.valid;
      assign io_out_s2_slot_valids[gd][1]   = e.tailSlot.valid;
      // targets_0：brSlot 目标 = {higher(由 tarStat 选), lower[11:0], 1'b0}
      assign io_out_s2_targets_0[gd] =
        {sel_higher(e.brSlot.tarStat, s2_higher_br[gd], s2_higher_p1_br[gd], s2_higher_m1_br[gd]),
         e.brSlot.lower[11:0], 1'b0};
      // targets_1 / jalr_target：tailSlot 目标
      //   共享(作 br)：lower 取低 12b，高位用 37b higher 段；
      //   非共享(真 jmp)：lower 取 20b，高位仅用 29b higher。
      assign io_out_s2_targets_1[gd] = e.tailSlot.sharing
        ? {sel_higher(e.tailSlot.tarStat, s2_higher_br[gd], s2_higher_p1_br[gd], s2_higher_m1_br[gd]),
           e.tailSlot.lower[11:0], 1'b0}
        : {sel_higher29(e.tailSlot.tarStat, s2_pc_higher[gd], s2_pc_higher_p1[gd], s2_pc_higher_m1[gd]),
           e.tailSlot.lower, 1'b0};
      assign io_out_s2_jalr_target[gd] = io_out_s2_targets_1[gd];
      assign io_out_s2_offsets_0[gd]   = e.brSlot.offset;
      assign io_out_s2_offsets_1[gd]   = e.tailSlot.offset;
      // fallThroughAddr：err → pc+0x20；否则 {pc高位(carry?+1), pftAddr, 1'b0}
      assign io_out_s2_fallThroughAddr[gd] = s2_ft_err[gd]
        ? (PC_W'({s2_seg0[gd], s2_seg1[gd], s2_seg2[gd]}) + PC_W'('h20))
        : {s2_stashed_carry[gd]
             ? (45'({s2_seg0[gd], s2_seg1[gd], s2_seg2[gd][11:5]}) + 45'h1)
             : {s2_seg0[gd], s2_seg1[gd], s2_seg2[gd][11:5]},
           e.pftAddr, 1'b0};
      assign io_out_s2_fallThroughErr[gd] = s2_ft_err[gd];
      assign io_out_s2_is_jal[gd]  = e.tailSlot.valid & ~e.isJalr;
      assign io_out_s2_is_jalr[gd] = e.tailSlot.valid &  e.isJalr;
      assign io_out_s2_is_call[gd] = e.tailSlot.valid &  e.isCall;
      assign io_out_s2_is_ret[gd]  = e.tailSlot.valid &  e.isRet;
      assign io_out_s2_last_may_be_rvi_call[gd] = e.last_may_be_rvi_call;
      assign io_out_s2_is_br_sharing[gd] = e.tailSlot.valid & e.tailSlot.sharing;
      assign io_out_s2_hit[gd] = s2_hit[gd];
    end
  endgenerate

  // ===========================================================================
  // s3 寄存：条目(multi-hit 时替换为 multi 条目) / hit / multiHit / fallThroughErr
  //          + s3 last_stage_pc 预算段 + meta
  // ===========================================================================
  ftb_entry_t s3_entry [NDUP];
  logic       s3_hit   [NDUP];
  logic       s3_multi_hit [NDUP];
  logic       s3_ft_err [NDUP];

  logic [25:0] s3_seg0 [NDUP];
  logic [11:0] s3_seg1 [NDUP];
  logic [11:0] s3_seg2 [NDUP];

  logic [28:0] s3_pc_higher    [NDUP];
  logic [7:0]  s3_pc_middle    [NDUP];
  logic [28:0] s3_pc_higher_p1 [NDUP];
  logic [28:0] s3_pc_higher_m1 [NDUP];
  logic [8:0]  s3_pc_middle_p1 [NDUP];
  logic [8:0]  s3_pc_middle_m1 [NDUP];

  logic [META_W-1:0] s3_meta;

  // s3 组合 higher 段
  wire [36:0] s3_higher_br    [NDUP];
  wire [36:0] s3_higher_p1_br [NDUP];
  wire [36:0] s3_higher_m1_br [NDUP];
  generate
    for (genvar gd = 0; gd < NDUP; gd++) begin : g_s3_higher
      assign s3_higher_br[gd]    = {s3_pc_higher[gd], s3_pc_middle[gd]};
      assign s3_higher_p1_br[gd] = {s3_pc_middle_p1[gd][8] ? s3_pc_higher_p1[gd] : s3_pc_higher[gd],
                                    s3_pc_middle_p1[gd][7:0]};
      assign s3_higher_m1_br[gd] = {s3_pc_middle_m1[gd][8] ? s3_pc_higher_m1[gd] : s3_pc_higher[gd],
                                    s3_pc_middle_m1[gd][7:0]};
    end
  endgenerate

  // ---- s3 输出组合：逐 dup（结构同 s2，fallThrough 直接用 s3_entry.carry） ----
  generate
    for (genvar gd = 0; gd < NDUP; gd++) begin : g_s3_out
      ftb_entry_t e; assign e = s3_entry[gd];
      assign io_out_s3_br_taken_mask[gd][0] = io_in_s3_br_taken_mask[gd][0] | (s3_hit[gd] & e.strong_bias[0]);
      assign io_out_s3_br_taken_mask[gd][1] = io_in_s3_br_taken_mask[gd][1] | (s3_hit[gd] & e.strong_bias[1]);
      assign io_out_s3_slot_valids[gd][0]   = e.brSlot.valid;
      assign io_out_s3_slot_valids[gd][1]   = e.tailSlot.valid;
      assign io_out_s3_targets_0[gd] =
        {sel_higher(e.brSlot.tarStat, s3_higher_br[gd], s3_higher_p1_br[gd], s3_higher_m1_br[gd]),
         e.brSlot.lower[11:0], 1'b0};
      assign io_out_s3_targets_1[gd] = e.tailSlot.sharing
        ? {sel_higher(e.tailSlot.tarStat, s3_higher_br[gd], s3_higher_p1_br[gd], s3_higher_m1_br[gd]),
           e.tailSlot.lower[11:0], 1'b0}
        : {sel_higher29(e.tailSlot.tarStat, s3_pc_higher[gd], s3_pc_higher_p1[gd], s3_pc_higher_m1[gd]),
           e.tailSlot.lower, 1'b0};
      assign io_out_s3_offsets_0[gd] = e.brSlot.offset;
      assign io_out_s3_offsets_1[gd] = e.tailSlot.offset;
      assign io_out_s3_fallThroughAddr[gd] = s3_ft_err[gd]
        ? (PC_W'({s3_seg0[gd], s3_seg1[gd], s3_seg2[gd]}) + PC_W'('h20))
        : {e.carry
             ? (45'({s3_seg0[gd], s3_seg1[gd], s3_seg2[gd][11:5]}) + 45'h1)
             : {s3_seg0[gd], s3_seg1[gd], s3_seg2[gd][11:5]},
           e.pftAddr, 1'b0};
      assign io_out_s3_fallThroughErr[gd] = s3_ft_err[gd];
      assign io_out_s3_multiHit[gd] = s3_multi_hit[gd];
      assign io_out_s3_is_jal[gd]  = e.tailSlot.valid & ~e.isJalr;
      assign io_out_s3_is_jalr[gd] = e.tailSlot.valid &  e.isJalr;
      assign io_out_s3_is_call[gd] = e.tailSlot.valid &  e.isCall;
      assign io_out_s3_is_ret[gd]  = e.tailSlot.valid &  e.isRet;
      assign io_out_s3_last_may_be_rvi_call[gd] = e.last_may_be_rvi_call;
      assign io_out_s3_is_br_sharing[gd] = e.tailSlot.valid & e.tailSlot.sharing;
      assign io_out_s3_hit[gd] = s3_hit[gd];
    end
  endgenerate

  // ===========================================================================
  // update 写回路径
  // ===========================================================================
  ftb_entry_t update_r_entry;
  logic       update_r_false_hit, update_r_old_entry;
  logic [515:0] update_meta_r;
  logic       update_valid;

  // meta[64]：old_entry(update_now) 标志位。update_now=立即写；need_read=先读后写。
  wire u_valid       = update_valid & ~update_r_old_entry & ~s0_close;
  wire update_now    = u_valid &  update_meta_r[64];
  wire update_need_read = u_valid & ~update_meta_r[64];

  wire ftb_false_hit = update_valid & update_r_false_hit;
  wire needReopen    = s0_close & (ftb_false_hit | io_redirectFromIFU);

  // 写 way/alloc 打一拍（与延 2 拍的写数据对齐）
  logic [1:0] write_way_REG;
  logic       write_alloc_REG;

  // 写数据二选一：update_now 用 update_r 直接写；否则用延 2 拍的条目
  ftb_entry_t ftb_write_entry;
  always_comb begin
    ftb_write_entry = update_now ? update_r_entry : delay_entry_out_bits;
    // golden 单独把 pftAddr/carry 提成 ftb_write_entry_*（同一二选一，含义相同）
  end
  wire [PC_W-1:0] write_pc    = update_now ? io_update_bits_pc : delay_pc_out_bits;
  wire            write_valid = update_now | delay_wv_out;

  // perf / ready 抑制 打拍寄存器（声明在使用前）
  logic io_s1_ready_REG;
  logic REG_2, REG_3;
  logic perf0_REG, perf0_REG_1, perf1_REG, perf1_REG_1;

  // ===========================================================================
  // 时序逻辑：流水寄存（同步复位段用 always_ff，异步复位段单列）
  // ===========================================================================
  // ---- 同步更新段（s1_pc/REG 链/s2/s3 寄存/update 寄存）----
  always_ff @(posedge clock) begin
    // s2 寄存（每 dup 在各自 s1_fire 时更新）
    for (int d = 0; d < NDUP; d++) begin
      if (io_s1_fire[d]) begin
        s2_fauftb_entry[d] <= io_fauftb_entry_in;
        s2_fauftb_hit[d]   <= io_fauftb_entry_hit_in;
        s2_ftbBank[d]      <= ftbBank_read_resp;
        s2_pc_higher[d]    <= s1_pc[d][49:21];
        s2_pc_middle[d]    <= s1_pc[d][20:13];
        s2_pc_higher_p1[d] <= 29'(s1_pc[d][49:21] + 29'h1);
        s2_pc_higher_m1[d] <= 29'(s1_pc[d][49:21] - 29'h1);
        s2_pc_middle_p1[d] <= 9'({1'b0, s1_pc[d][20:13]} + 9'h1);
        s2_pc_middle_m1[d] <= 9'({1'b0, s1_pc[d][20:13]} - 9'h1);
        s2_stashed_carry[d]<= s1_read_resp_carry;
      end
    end
    // s2 meta（dup0 在 s1_fire[0] 时寄存 hits_bits/hit）
    if (io_s1_fire[0])
      s2_meta <= {s1_close ? 2'h0 : ftbBank_io_read_hits_bits, s1_hit, s2_meta_cnt};

    // s3 寄存（每 dup 在各自 s2_fire 时更新；multi-hit 时整条目替换为 multi）
    for (int d = 0; d < NDUP; d++) begin
      if (io_s2_fire[d]) begin
        s3_entry[d]     <= s2_multi_hit_en ? ftbBank_read_multi_entry : s2_entry[d];
        s3_multi_hit[d] <= s2_multi_hit_en;
        s3_pc_higher[d]    <= {s2_seg0[d], s2_seg1[d][11:9]};
        s3_pc_middle[d]    <= s2_seg1[d][8:1];
        s3_pc_higher_p1[d] <= 29'({s2_seg0[d], s2_seg1[d][11:9]} + 29'h1);
        s3_pc_higher_m1[d] <= 29'({s2_seg0[d], s2_seg1[d][11:9]} - 29'h1);
        s3_pc_middle_p1[d] <= 9'({1'b0, s2_seg1[d][8:1]} + 9'h1);
        s3_pc_middle_m1[d] <= 9'({1'b0, s2_seg1[d][8:1]} - 9'h1);
      end
    end
    // s3 fallThroughErr：所有 dup 都取 real_s2（dup0 的 s2 计算，含 multi-hit 修正）
    //   —— golden 各 real_s3_fallThroughErr_dup_N 均 <= real_s2_fallThroughErr。
    for (int d = 0; d < NDUP; d++)
      if (io_s2_fire[d]) s3_ft_err[d] <= real_s2_ft_err;

    // s3 meta（dup0 在 s2_fire[0] 时；multi-hit 时换 multi meta）
    if (io_s2_fire[0])
      s3_meta <= s2_multi_hit_en
                   ? {ftbBank_io_read_multi_hits_bits, s2_multi_hit, s2_multi_meta_cnt}
                   : s2_meta;

    // update_r：update_valid 时锁存来自 FTQ 的新条目/标志
    if (io_update_valid) begin
      update_r_entry     <= io_update_bits_ftb_entry;
      update_r_false_hit <= io_update_bits_false_hit;
      update_r_old_entry <= io_update_bits_old_entry;
    end
    if (io_update_valid & ~io_update_bits_old_entry)
      update_meta_r <= io_update_bits_meta;

    // 写 way/alloc 打拍：way=FTBBank 命中路；alloc=未命中（需新分配）
    write_way_REG   <= ftbBank_io_update_hits_bits;
    write_alloc_REG <= ~ftbBank_io_update_hits_valid;

    // s1_ready 抑制（need_read 那拍打一拍，用于下一拍压低 ready）
    io_s1_ready_REG <= update_need_read;

    // perf 打拍链
    REG_2 <= io_s0_fire[0];
    REG_3 <= io_s0_fire[0];
    perf0_REG   <= update_valid & update_meta_r[64];
    perf0_REG_1 <= perf0_REG;
    perf1_REG   <= update_valid & ~update_meta_r[64];
    perf1_REG_1 <= perf1_REG;
  end

  // ---- 异步复位段（close 流水 / hit 流水 / 计数器 / pc 段 / update_valid）----
  // s2 各 dup hit：s1_fire 时寄存 s1_hit
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s0_close <= 1'b0; s1_close <= 1'b0; s2_close <= 1'b0;
      consistent_cnt <= 9'h0;
      update_valid <= 1'b0;
      s2_meta_cnt <= 64'h0; s2_multi_meta_cnt <= 64'h0;
      for (int d = 0; d < NDUP; d++) begin
        s2_ftb_hit[d] <= 1'b0; s3_hit[d] <= 1'b0;
        s2_seg0[d] <= '0; s2_seg1[d] <= '0; s2_seg2[d] <= '0;
        s3_seg0[d] <= '0; s3_seg1[d] <= '0; s3_seg2[d] <= '0;
      end
    end else begin
      // s2 pc 段：仅在「与上拍 s1_pc 对应段不同 且 s1_fire」时更新（同 golden modified 门控）
      for (int d = 0; d < NDUP; d++) begin
        if (io_s1_fire[d]) begin
          if (s2_seg0[d] != s1_pc[d][49:24]) s2_seg0[d] <= s1_pc[d][49:24];
          if (s2_seg1[d] != s1_pc[d][23:12]) s2_seg1[d] <= s1_pc[d][23:12];
          s2_seg2[d] <= s1_pc[d][11:0];  // seg2 modified 恒真常量 → 直接更新
        end
      end
      // s3 pc 段：仅在与上拍 s2 段不同 且 s2_fire 时更新
      for (int d = 0; d < NDUP; d++) begin
        if (io_s2_fire[d]) begin
          if (s3_seg0[d] != s2_seg0[d]) s3_seg0[d] <= s2_seg0[d];
          if (s3_seg1[d] != s2_seg1[d]) s3_seg1[d] <= s2_seg1[d];
          s3_seg2[d] <= s2_seg2[d];      // seg2 modified 恒真常量
        end
      end

      // close 流水：阈值满 & s0_fire → 关闭；needReopen → 维持关闭判定为 0
      s0_close <= ~needReopen & ((consistent_cnt > CONSISTENT_THRESH & io_s0_fire[0]) | s0_close);
      if (io_s0_fire[0]) s1_close <= s0_close;
      if (io_s1_fire[0]) s2_close <= s1_close;

      // s2/s3 hit 流水
      if (io_s1_fire[0]) s2_ftb_hit[0] <= s1_hit;
      for (int d = 1; d < NDUP; d++) if (io_s1_fire[d]) s2_ftb_hit[d] <= s1_hit;
      for (int d = 0; d < NDUP; d++)
        if (io_s2_fire[d]) s3_hit[d] <= s2_multi_hit_en ? s2_multi_hit : s2_hit[d];

      // meta 自由计数器（仅占位，每拍 +1）
      s2_meta_cnt       <= 64'(s2_meta_cnt + 64'h1);
      s2_multi_meta_cnt <= 64'(s2_multi_meta_cnt + 64'h1);

      // uFTB 一致性计数器：连续多拍 FTB 与 uFTB 条目完全一致则累加，否则清 0
      if (needReopen)
        consistent_cnt <= 9'h0;
      else if (io_s2_fire[0] & s2_fauftb_hit[0] & s2_ftb_hit[0])
        consistent_cnt <= entry_eq(s2_fauftb_entry[0], s2_ftbBank[0])
                            ? 9'(consistent_cnt + 9'h1) : 9'h0;
      else if (io_s2_fire[0] & ~s2_fauftb_hit[0] & s2_ftb_hit[0])
        consistent_cnt <= 9'h0;

      update_valid <= io_update_valid;
    end
  end

  // ===========================================================================
  // FTBBank / Delay 子模块端口驱动
  // ===========================================================================
  assign ftbBank_io_s1_fire      = io_s1_fire[0];
  assign ftbBank_io_req_pc_valid = io_s0_fire[0] & ~s0_close;
  assign ftbBank_io_req_pc_bits  = io_in_bits_s0_pc[0];

  assign ftbBank_io_u_req_pc_valid = update_need_read;
  assign ftbBank_io_u_req_pc_bits  = io_update_bits_pc;
  assign ftbBank_io_update_access  = u_valid & ~update_meta_r[64];
  assign ftbBank_io_update_pc      = write_pc;
  assign ftbBank_io_update_write_data_valid = write_valid;
  assign ftbBank_update_write_entry         = ftb_write_entry;
  assign ftbBank_io_update_write_tag        = write_pc[29:10];
  // 写 way：update_now 用 meta[66:65]（FTQ 给的命中路）；否则用打拍的命中路
  assign ftbBank_io_update_write_way   = update_now ? update_meta_r[66:65] : write_way_REG;
  assign ftbBank_io_update_write_alloc = ~update_now & write_alloc_REG;

  // pc / entry 延 2 拍（DelayNWithValid），write_valid 延 2 拍（DelayN_1）
  assign delay_pc_in_bits     = io_update_bits_pc;
  assign delay_pc_in_valid    = u_valid;
  assign delay_entry_in_bits  = update_r_entry;
  assign delay_entry_in_valid = u_valid;
  assign delay_wv_in          = u_valid & ~update_meta_r[64];

  // ===========================================================================
  // s1 杂项 / last_stage / perf 输出
  // ===========================================================================
  assign io_out_s1_uftbHit = io_fauftb_entry_hit_in;
  assign io_out_s1_uftbHasIndirect =
      io_fauftb_entry_in.tailSlot.valid & ~io_fauftb_entry_in.tailSlot.sharing
    & io_fauftb_entry_in.isJalr & ~io_fauftb_entry_in.isRet;
  assign io_out_s1_ftbCloseReq = s1_close;

  assign io_out_last_stage_meta      = {449'h0, s3_meta};
  assign io_out_last_stage_sc_disagree = io_in_last_stage_sc_disagree;
  assign io_out_last_stage_ftb_entry = s3_entry[0];

  assign io_s1_ready    = ftbBank_io_req_pc_ready & ~update_need_read & ~io_s1_ready_REG;
  assign io_perf_0_value = {5'h0, perf0_REG_1};
  assign io_perf_1_value = {5'h0, perf1_REG_1};

endmodule
