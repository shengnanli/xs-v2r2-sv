// =============================================================================
// FTB.sv —— FTB 预测器（Fetch Target Buffer，主 BTB）：BPU 的 S2/S3 级"块级"预测
//
// 【在 BPU 里的位置】Composer 菊花链的第二环（uFTB -> FTB -> TAGE-SC -> ITTage -> RAS）。
//   S0 用取指 PC 读大容量组相联 FTBBank（512 组 x 4 路，已签核子模块）；S1 拿到命中条目；
//   S2 把条目展开成一份"完整预测"（两个 CFI 槽的有效位/偏移/目标、fall-through 地址、
//   jal/jalr/call/ret 标志、命中位）覆盖 uFTB 在 S1 给出的结果；S3 再打一拍给出 S3 预测，
//   并把 S3 的条目/meta 留给 FTQ（训练时随 update 回来）。
//   （Chisel：src/main/scala/xiangshan/frontend/FTB.scala class FTB，外壳 BPU.scala BasePredictor）
//
// 【FTB 读请求的"关闭"机制】uFTB 与 FTB 存的是同一种 FTB 条目。若连续 500 次二者都命中且
//   条目逐字段一致（fauftb_ftb_entry_consistent_counter 计到 > 499），就认为 uFTB 已足够，
//   关掉 FTB 的 SRAM 读请求省功耗：s0_close -> s1_close -> s2_close 随流水下传，被关闭时
//   S2 直接用 S1 锁存的 uFTB 条目/命中顶上。遇到 update.false_hit 或 IFU 重定向就重新打开
//   并清零计数器。
//
// 【multi-hit 兜底】FTBBank 另报"一组里多路同时命中"（read_multi_*），本层在 S2 发现时
//   （且未关闭）用 bank 选出的那一路条目替代 S2 条目送进 S3，并在 S3 报 multiHit。
//
// 【目标重建的时序技巧】条目里只存目标低位 + tarStat（高位相对 PC 高位 = / +1 / -1）。
//   为了不在 S2 现做加减，S1 fire 时就把 s1_pc 的高位/中位以及它们 ±1 的结果打进寄存器
//   （last_stage_pc_*），S2 只需按 tarStat 选；S3 同理用 S2 fire 时打下的 s2_pc 分段。
//   S2 的 fall-through 进位也用 S1 时刻 FTB 读出的 carry（stashed_carry）而不是 S2 条目的。
//
// 【更新】FTQ 提交 update（pc / 新条目 / meta / false_hit / old_entry）先锁存一拍。
//   meta.hit=1：直接写回预测时命中的那一路（update_now）；meta.hit=0：先用 update pc
//   读一次 bank 查 tag（update_need_read，期间 s1_ready 拉低两拍），两拍后按查到的命中路
//   或新分配一路写入（条目与 pc 经 DelayNWithValid 打两拍对齐）。
//
// 【4 份 dup】PC/fire 与各级寄存器在 BPU 里复制 4 份（纯扇出复制、值恒等），逐份独立。
//   ★firtool 按读者删字段★：副本 1..3 的 S2/S3 条目寄存器没有 valid 与 brSlot.sharing
//   （只有副本 0 参与一致性比较和 last_stage_ftb_entry 输出），这里照搬：副本 0 用完整
//   ftb_entry_t，副本 1..3 用去掉这两个字段的 ftb_entry_lite_t。
//
// 【子模块】ftbBank(FTBBank) / delay2_pc_pipMod(DelayNWithValid) /
//   delay2_entry_pipMod(DelayNWithValid_1) / write_valid_delay(DelayN_1) 均为已签核件，
//   例化在本文件末尾的 golden 同名 wrapper 里（与 golden 同层同实例名），核只管 FTB 本层逻辑。
//
// 复位域（与 golden 逐一对齐）：modified_reset、s2/s3 段 PC、三级 close、s2_ftb_hit、s3_hit、
//   两个 64 位周期计数器、一致性计数器、update_valid 为异步复位；s1_pc 无复位（复位脉冲那拍
//   装复位向量）；其余数据寄存器无复位。
// 死寄存器照搬不删（FM 侧按 vmucp 对称死位证）：update_meta_r 存满 516 位只读 [66:64]；
//   s2_ftb_meta / s2_multi_hit_meta 的 64 位周期计数器只进 last_stage_meta；
//   s0_fire 打一拍的两个寄存器（REG / REG_1）只喂 perf 探针。
// golden 的四条断言（S2 条目一致性两条、S3 fall-through、写入 fall-through）只在仿真
//   非 SYNTHESIS 下存在，不影响功能，本文件不重复实现。
// =============================================================================
package ftb_pred_pkg;
  import xs_ftb_pkg::*;

  localparam int unsigned NUM_DUP = 4;
  localparam int unsigned PC_W    = 50;
  localparam int unsigned META_W  = 516;
  localparam int unsigned FMETA_W = 67;   // FTBMeta = {writeWay[1:0], hit, pred_cycle[63:0]}

  // ---- 副本 1..3 的条目寄存器：比 ftb_entry_t 少 valid 与 brSlot.sharing ----
  typedef struct packed {
    logic [OFFSET_W-1:0]   offset;
    logic                  valid;
    logic [BR_OFF_LEN-1:0] lower;
    logic [1:0]            tarStat;
  } ftb_br_slot_lite_t;

  typedef struct packed {
    ftb_br_slot_lite_t   brSlot;
    ftb_slot_t           tailSlot;
    logic [OFFSET_W-1:0] pftAddr;
    logic                carry;
    logic                isCall;
    logic                isRet;
    logic                isJalr;
    logic                last_may_be_rvi_call;
    logic [1:0]          strong_bias;
  } ftb_entry_lite_t;

  function automatic ftb_entry_lite_t to_lite(input ftb_entry_t e);
    ftb_entry_lite_t l;
    l.brSlot.offset        = e.brSlot.offset;
    l.brSlot.valid         = e.brSlot.valid;
    l.brSlot.lower         = e.brSlot.lower;
    l.brSlot.tarStat       = e.brSlot.tarStat;
    l.tailSlot             = e.tailSlot;
    l.pftAddr              = e.pftAddr;
    l.carry                = e.carry;
    l.isCall               = e.isCall;
    l.isRet                = e.isRet;
    l.isJalr               = e.isJalr;
    l.last_may_be_rvi_call = e.last_may_be_rvi_call;
    l.strong_bias          = e.strong_bias;
    return l;
  endfunction

  // 补回完整条目：缺的两个字段填 0 —— 副本 1..3 的读者（预测展开）本来就不看它们
  function automatic ftb_entry_t from_lite(input ftb_entry_lite_t l);
    ftb_entry_t e;
    e.valid                = 1'b0;
    e.brSlot.offset        = l.brSlot.offset;
    e.brSlot.sharing       = 1'b0;
    e.brSlot.valid         = l.brSlot.valid;
    e.brSlot.lower         = l.brSlot.lower;
    e.brSlot.tarStat       = l.brSlot.tarStat;
    e.tailSlot             = l.tailSlot;
    e.pftAddr              = l.pftAddr;
    e.carry                = l.carry;
    e.isCall               = l.isCall;
    e.isRet                = l.isRet;
    e.isJalr               = l.isJalr;
    e.last_may_be_rvi_call = l.last_may_be_rvi_call;
    e.strong_bias          = l.strong_bias;
    return e;
  endfunction

  // ---- 上一级 PC 预先算好的目标高位（FTBEntry.getTargetVec 的 last_stage 版本）----
  //   higher = pc[49:21]（tailSlot 不共享时 20 位低位之上的部分）
  //   middle = pc[20:13]（brSlot / 共享 tailSlot 的 12 位低位与 20 位低位之间的 8 位）
  //   *_p1 / *_m1 = 各自 +1 / -1；middle 的 ±1 多留一位进/借位，用来决定 higher 是否跟着变
  typedef struct packed {
    logic [28:0] higher;
    logic [7:0]  middle;
    logic [28:0] higher_p1;
    logic [28:0] higher_m1;
    logic [8:0]  middle_p1;
    logic [8:0]  middle_m1;
  } tgt_base_t;

  function automatic tgt_base_t tgt_base_of(input logic [PC_W-1:0] pc);
    tgt_base_t b;
    b.higher    = pc[49:21];
    b.middle    = pc[20:13];
    b.higher_p1 = pc[49:21] + 29'd1;
    b.higher_m1 = pc[49:21] - 29'd1;
    b.middle_p1 = {1'b0, pc[20:13]} + 9'd1;
    b.middle_m1 = {1'b0, pc[20:13]} - 9'd1;
    return b;
  endfunction

  // Mux1H((OVF, plus_one), (UDF, minus_one), (FIT, same))：tarStat=3 时三项都不选，得 0
  function automatic logic [36:0] pick37(input logic [1:0] stat, input logic [36:0] p1,
                                         input logic [36:0] m1, input logic [36:0] same);
    return ({37{stat == TAR_OVF}} & p1) | ({37{stat == TAR_UDF}} & m1)
         | ({37{stat == TAR_FIT}} & same);
  endfunction

  function automatic logic [28:0] pick29(input logic [1:0] stat, input logic [28:0] p1,
                                         input logic [28:0] m1, input logic [28:0] same);
    return ({29{stat == TAR_OVF}} & p1) | ({29{stat == TAR_UDF}} & m1)
         | ({29{stat == TAR_FIT}} & same);
  endfunction

  // 两个槽的目标：brSlot 与"共享"的 tailSlot 用 12 位低位 + 37 位高位；
  // 独占的 tailSlot 用 20 位低位 + 29 位高位
  function automatic logic [1:0][PC_W-1:0] targets_of(input ftb_entry_t e, input tgt_base_t b);
    logic [36:0]          br_same, br_p1, br_m1;
    logic [1:0][PC_W-1:0] t;
    br_same = {b.higher, b.middle};
    br_p1   = {b.middle_p1[8] ? b.higher_p1 : b.higher, b.middle_p1[7:0]};
    br_m1   = {b.middle_m1[8] ? b.higher_m1 : b.higher, b.middle_m1[7:0]};
    t[0] = {pick37(e.brSlot.tarStat, br_p1, br_m1, br_same), e.brSlot.lower, 1'b0};
    t[1] = e.tailSlot.sharing
             ? {pick37(e.tailSlot.tarStat, br_p1, br_m1, br_same), e.tailSlot.lower[11:0], 1'b0}
             : {pick29(e.tailSlot.tarStat, b.higher_p1, b.higher_m1, b.higher),
                e.tailSlot.lower, 1'b0};
    return t;
  endfunction

  // fall-through 合法性：块起点（块内指令号）必须严格小于终点，且终点不超过起点 + 16
  function automatic logic fall_through_err(input logic [PC_W-1:0] pc, input logic carry,
                                            input logic [3:0] pft_addr);
    logic [4:0] start_lower, end_lower;
    start_lower = {1'b0, pc[4:1]};
    end_lower   = {carry, pft_addr};
    return (start_lower >= end_lower) || (end_lower > 5'(start_lower + 5'd16));
  endfunction

  // fall-through 地址：非法时取 pc + 32（一整个取指块），否则 {pc 高位(+进位), pftAddr, 0}
  function automatic logic [PC_W-1:0] fall_through_addr(input logic [PC_W-1:0] pc,
                                                        input logic err, input logic carry,
                                                        input logic [3:0] pft_addr);
    return err ? PC_W'(pc + 50'd32)
               : {(carry ? 45'(pc[49:5] + 45'd1) : pc[49:5]), pft_addr, 1'b0};
  endfunction

  // FullBranchPrediction 在本层输出的字段（S2 没有 multiHit 端口，S3 没有 jalr_target 端口）
  typedef struct packed {
    logic [1:0]           br_taken_mask;
    logic [1:0]           slot_valids;      // [0]=brSlot, [1]=tailSlot
    logic [1:0][PC_W-1:0] targets;          // jalr_target = targets[1]
    logic [1:0][3:0]      offsets;
    logic [PC_W-1:0]      fall_through_addr;
    logic                 fall_through_err;
    logic                 multi_hit;
    logic                 is_jal;
    logic                 is_jalr;
    logic                 is_call;
    logic                 is_ret;
    logic                 last_may_be_rvi_call;
    logic                 is_br_sharing;
    logic                 hit;
  } ftb_pred_t;

  // FullBranchPrediction.fromFtbEntry 里与 PC 无关的那部分 + "always taken"：
  // 条件分支方向 = 上游（uFTB）给的方向 | (命中 & strong_bias)
  function automatic ftb_pred_t pred_flags(input ftb_entry_t e, input logic hit,
                                           input logic [1:0] in_taken);
    ftb_pred_t p;
    p                      = '0;
    p.br_taken_mask        = in_taken | ({2{hit}} & e.strong_bias);
    p.slot_valids          = {e.tailSlot.valid, e.brSlot.valid};
    p.offsets              = {e.tailSlot.offset, e.brSlot.offset};
    p.is_jal               = e.tailSlot.valid && !e.isJalr;
    p.is_jalr              = e.tailSlot.valid && e.isJalr;
    p.is_call              = e.tailSlot.valid && e.isCall;
    p.is_ret               = e.tailSlot.valid && e.isRet;
    p.last_may_be_rvi_call = e.last_may_be_rvi_call;
    p.is_br_sharing        = e.tailSlot.valid && e.tailSlot.sharing;
    p.hit                  = hit;
    return p;
  endfunction

endpackage

module xs_FTB_core
  import xs_ftb_pkg::*;
  import ftb_pred_pkg::*;
(
  input  logic                clock,
  input  logic                reset,
  input  logic [47:0]         reset_vector,
  // ---- BPU 各级握手（4 份 dup）----
  input  logic [PC_W-1:0]     s0_pc          [NUM_DUP],
  input  logic                s0_fire        [NUM_DUP],
  input  logic                s1_fire        [NUM_DUP],
  input  logic                s2_fire        [NUM_DUP],
  // ---- 上游（uFTB）给的预测：方向 + S1 命中条目 ----
  input  logic [1:0]          in_s2_taken    [NUM_DUP],
  input  logic [1:0]          in_s3_taken    [NUM_DUP],
  input  ftb_entry_t          fau_entry_in,
  input  logic                fau_hit_in,
  input  logic                btb_enable,
  // ---- 预测输出 ----
  output ftb_pred_t           s2_pred        [NUM_DUP],
  output ftb_pred_t           s3_pred        [NUM_DUP],
  output logic                s1_uftb_hit,
  output logic                s1_uftb_has_indirect,
  output logic                s1_close_req,
  output logic [META_W-1:0]   last_stage_meta,
  output ftb_entry_t          last_stage_entry,
  output logic                s1_ready,
  // ---- 更新 ----
  input  logic                update_valid_in,
  input  logic [PC_W-1:0]     update_pc,
  input  ftb_entry_t          update_entry_in,
  input  logic                update_false_hit_in,
  input  logic                update_old_entry_in,
  input  logic [META_W-1:0]   update_meta_in,
  input  logic                redirect_from_ifu,
  output logic                perf_commit_hit,
  output logic                perf_commit_miss,
  // ---- FTBBank 接口 ----
  input  logic                bank_req_ready,
  output logic                bank_req_valid,
  input  ftb_entry_t          bank_read_entry,
  input  logic                bank_read_hit,
  input  logic [1:0]          bank_read_way,
  input  ftb_entry_t          bank_multi_entry,
  input  logic                bank_multi_hit,
  input  logic [1:0]          bank_multi_way,
  output logic                bank_u_req_valid,
  input  logic                bank_update_hit,
  input  logic [1:0]          bank_update_way,
  output logic                bank_update_access,
  output logic [PC_W-1:0]     bank_write_pc,
  output logic                bank_write_valid,
  output ftb_entry_t          bank_write_entry,
  output logic [19:0]         bank_write_tag,
  output logic [1:0]          bank_write_way,
  output logic                bank_write_alloc,
  // ---- 更新通路的两拍延迟件接口（DelayNWithValid / DelayNWithValid_1 / DelayN_1）----
  output logic                u_valid,               // 两个 DelayNWithValid 的 valid
  input  logic [PC_W-1:0]     delay2_pc,
  output ftb_entry_t          update_entry,           // 锁存后的 update 条目（DelayNWithValid_1 的输入）
  input  ftb_entry_t          delay2_entry,
  output logic                write_valid_delay_in,
  input  logic                write_valid_delay_out
);

  // ===========================================================================
  // §0 BPU 公共外壳：各级 PC（BasePredictor）
  //   s1_pc：s0 fire 时锁存；复位刚放开那一拍（modified_reset）装复位向量。无复位端。
  //   s2/s3：SegmentedAddrNext —— 50 位 PC 切成 [49:24]/[23:12]/[11:0] 三段，
  //   高两段"值变了且本级 fire"才打拍，最低段每次 fire 都打。段寄存器异步复位为 0。
  // ===========================================================================
  logic              modified_reset;
  logic [PC_W-1:0]   s1_pc     [NUM_DUP];
  logic [25:0]       s2_pc_hi  [NUM_DUP];
  logic [11:0]       s2_pc_mid [NUM_DUP];
  logic [11:0]       s2_pc_lo  [NUM_DUP];
  logic [25:0]       s3_pc_hi  [NUM_DUP];
  logic [11:0]       s3_pc_mid [NUM_DUP];
  logic [11:0]       s3_pc_lo  [NUM_DUP];
  logic [PC_W-1:0]   s2_pc     [NUM_DUP];
  logic [PC_W-1:0]   s3_pc     [NUM_DUP];

  always_ff @(posedge clock or posedge reset) begin
    if (reset) modified_reset <= 1'b1;
    else       modified_reset <= 1'b0;
  end

  for (genvar d = 0; d < NUM_DUP; d++) begin : g_stage_pc
    assign s2_pc[d] = {s2_pc_hi[d], s2_pc_mid[d], s2_pc_lo[d]};
    assign s3_pc[d] = {s3_pc_hi[d], s3_pc_mid[d], s3_pc_lo[d]};

    always_ff @(posedge clock) begin
      if (modified_reset)  s1_pc[d] <= {2'h0, reset_vector};
      else if (s0_fire[d]) s1_pc[d] <= s0_pc[d];
    end

    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        s2_pc_hi[d]  <= '0;
        s2_pc_mid[d] <= '0;
        s2_pc_lo[d]  <= '0;
        s3_pc_hi[d]  <= '0;
        s3_pc_mid[d] <= '0;
        s3_pc_lo[d]  <= '0;
      end else begin
        if (s1_fire[d] && s2_pc_hi[d]  != s1_pc[d][49:24]) s2_pc_hi[d]  <= s1_pc[d][49:24];
        if (s1_fire[d] && s2_pc_mid[d] != s1_pc[d][23:12]) s2_pc_mid[d] <= s1_pc[d][23:12];
        if (s1_fire[d])                                     s2_pc_lo[d]  <= s1_pc[d][11:0];
        if (s2_fire[d] && s3_pc_hi[d]  != s2_pc_hi[d])      s3_pc_hi[d]  <= s2_pc_hi[d];
        if (s2_fire[d] && s3_pc_mid[d] != s2_pc_mid[d])     s3_pc_mid[d] <= s2_pc_mid[d];
        if (s2_fire[d])                                     s3_pc_lo[d]  <= s2_pc_lo[d];
      end
    end
  end

  // ===========================================================================
  // §1 S0/S1：关闭开关下传、发 SRAM 读、S1 命中
  // ===========================================================================
  logic       s0_close, s1_close, s2_close;
  logic [8:0] consist_cnt;            // uFTB/FTB 条目连续一致计数（> 499 就关 FTB 读）
  logic       need_reopen;
  logic       s1_hit;                 // FTB 自己的 S1 命中（关闭时恒 0）
  ftb_entry_t s1_read_entry;          // S1 的"读出条目"：关闭时就是 uFTB 的条目

  assign bank_req_valid = s0_fire[0] && !s0_close;
  assign s1_hit         = !s1_close && bank_read_hit && btb_enable;
  assign s1_read_entry  = s1_close ? fau_entry_in : bank_read_entry;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s0_close <= 1'b0;
      s1_close <= 1'b0;
      s2_close <= 1'b0;
    end else begin
      // 计数满（且本拍 s0 fire）就关；需要重开时优先清
      s0_close <= !need_reopen && ((consist_cnt > 9'd499 && s0_fire[0]) || s0_close);
      if (s0_fire[0]) s1_close <= s0_close;
      if (s1_fire[0]) s2_close <= s1_close;
    end
  end

  assign s1_uftb_hit          = fau_hit_in;
  // uFTB 认定的"真 jalr"：独占 tailSlot（jmpValid）、是 jalr 且不是 ret
  assign s1_uftb_has_indirect = fau_entry_in.tailSlot.valid && !fau_entry_in.tailSlot.sharing
                                && fau_entry_in.isJalr && !fau_entry_in.isRet;
  assign s1_close_req         = s1_close;

  // ===========================================================================
  // §2 S1 -> S2 锁存：uFTB 条目/命中、FTB 读出条目/命中、目标高位、stashed carry
  //   （副本 0 全字段；副本 1..3 少 valid 与 brSlot.sharing，见文件头）
  // ===========================================================================
  ftb_entry_t      s2_fau_entry0,  s2_bank_entry0;
  ftb_entry_lite_t s2_fau_entry_lite  [1:NUM_DUP-1];
  ftb_entry_lite_t s2_bank_entry_lite [1:NUM_DUP-1];
  logic            s2_fau_hit     [NUM_DUP];
  logic            s2_ftb_hit     [NUM_DUP];
  tgt_base_t       s2_tgt         [NUM_DUP];
  logic            s2_stash_carry [NUM_DUP];
  logic [63:0]     pred_cycle_ftb;          // GTimer()：FTBMeta.pred_cycle（两份独立计数器）
  logic [63:0]     pred_cycle_multi;
  logic [FMETA_W-1:0] s2_ftb_meta;

  always_ff @(posedge clock) begin
    if (s1_fire[0]) begin
      s2_fau_entry0  <= fau_entry_in;
      s2_bank_entry0 <= bank_read_entry;
      // FTBMeta：关闭时写路 0
      s2_ftb_meta    <= {(s1_close ? 2'd0 : bank_read_way), s1_hit, pred_cycle_ftb};
    end
    for (int d = 1; d < NUM_DUP; d++) begin
      if (s1_fire[d]) begin
        s2_fau_entry_lite[d]  <= to_lite(fau_entry_in);
        s2_bank_entry_lite[d] <= to_lite(bank_read_entry);
      end
    end
    for (int d = 0; d < NUM_DUP; d++) begin
      if (s1_fire[d]) begin
        s2_fau_hit[d]     <= fau_hit_in;
        s2_tgt[d]         <= tgt_base_of(s1_pc[d]);
        s2_stash_carry[d] <= s1_read_entry.carry;
      end
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int d = 0; d < NUM_DUP; d++) s2_ftb_hit[d] <= 1'b0;
      pred_cycle_ftb   <= '0;
      pred_cycle_multi <= '0;
    end else begin
      for (int d = 0; d < NUM_DUP; d++)
        if (s1_fire[d]) s2_ftb_hit[d] <= s1_hit;
      pred_cycle_ftb   <= pred_cycle_ftb + 64'd1;
      pred_cycle_multi <= pred_cycle_multi + 64'd1;
    end
  end

  // ===========================================================================
  // §3 S2：选条目（关闭时用 uFTB 的）、展开成预测、multi-hit 判定
  // ===========================================================================
  ftb_entry_t s2_entry [NUM_DUP];
  logic       s2_hit   [NUM_DUP];
  logic       s2_multi_hit;          // bank 报多路命中（本拍 S2 fire）
  logic       s2_multi_hit_enable;   // 且未关闭 —— 才真的替换
  ftb_entry_t real_s2_entry;         // 进 S3 的副本 0 条目（multi-hit 时换成 bank 选的那路）
  logic       real_s2_ft_err;

  assign s2_entry[0] = s2_close ? s2_fau_entry0 : s2_bank_entry0;
  for (genvar d = 1; d < NUM_DUP; d++) begin : g_s2_entry
    assign s2_entry[d] = from_lite(s2_close ? s2_fau_entry_lite[d] : s2_bank_entry_lite[d]);
  end

  for (genvar d = 0; d < NUM_DUP; d++) begin : g_s2_pred
    logic s2_ft_err;
    assign s2_hit[d]  = s2_close ? s2_fau_hit[d] : s2_ftb_hit[d];
    assign s2_ft_err  = fall_through_err(s2_pc[d], s2_entry[d].carry, s2_entry[d].pftAddr);
    always_comb begin
      s2_pred[d]                   = pred_flags(s2_entry[d], s2_hit[d], in_s2_taken[d]);
      s2_pred[d].targets           = targets_of(s2_entry[d], s2_tgt[d]);
      s2_pred[d].fall_through_err  = s2_ft_err;
      s2_pred[d].fall_through_addr = fall_through_addr(s2_pc[d], s2_ft_err, s2_stash_carry[d],
                                                       s2_entry[d].pftAddr);
    end
  end

  assign s2_multi_hit        = bank_multi_hit && s2_fire[0];
  assign s2_multi_hit_enable = s2_multi_hit && !s2_close;
  assign real_s2_entry       = s2_multi_hit_enable ? bank_multi_entry : s2_entry[0];
  assign real_s2_ft_err      = fall_through_err(s2_pc[0], real_s2_entry.carry,
                                                real_s2_entry.pftAddr);

  // uFTB 与 FTB 条目连续一致计数（FTBEntry.entryConsistent = 全字段相等）
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      consist_cnt <= '0;
    else if (need_reopen)
      consist_cnt <= '0;
    else if (s2_fire[0] && s2_fau_hit[0] && s2_ftb_hit[0])
      consist_cnt <= (s2_fau_entry0 == s2_bank_entry0) ? 9'(consist_cnt + 9'd1) : 9'd0;
    else if (s2_fire[0] && !s2_fau_hit[0] && s2_ftb_hit[0])
      consist_cnt <= '0;
  end

  // ===========================================================================
  // §4 S2 -> S3 锁存 与 S3 预测输出
  // ===========================================================================
  ftb_entry_t         s3_entry0;
  ftb_entry_lite_t    s3_entry_lite [1:NUM_DUP-1];
  logic               s3_hit        [NUM_DUP];
  logic               s3_multi_hit  [NUM_DUP];
  logic               s3_ft_err     [NUM_DUP];
  tgt_base_t          s3_tgt        [NUM_DUP];
  logic [FMETA_W-1:0] last_stage_meta_r;
  ftb_entry_t         s3_entry      [NUM_DUP];

  always_ff @(posedge clock) begin
    if (s2_fire[0]) begin
      s3_entry0         <= real_s2_entry;
      last_stage_meta_r <= s2_multi_hit_enable ? {bank_multi_way, s2_multi_hit, pred_cycle_multi}
                                               : s2_ftb_meta;
    end
    for (int d = 1; d < NUM_DUP; d++)
      if (s2_fire[d])
        s3_entry_lite[d] <= to_lite(s2_multi_hit_enable ? bank_multi_entry : s2_entry[d]);
    for (int d = 0; d < NUM_DUP; d++) begin
      if (s2_fire[d]) begin
        // 各副本的 fall-through 合法性都取副本 0 的"真实 S2"结果
        s3_ft_err[d]    <= real_s2_ft_err;
        s3_multi_hit[d] <= s2_multi_hit_enable;
        s3_tgt[d]       <= tgt_base_of(s2_pc[d]);
      end
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int d = 0; d < NUM_DUP; d++) s3_hit[d] <= 1'b0;
    end else begin
      for (int d = 0; d < NUM_DUP; d++)
        if (s2_fire[d]) s3_hit[d] <= s2_multi_hit_enable ? s2_multi_hit : s2_hit[d];
    end
  end

  assign s3_entry[0] = s3_entry0;
  for (genvar d = 1; d < NUM_DUP; d++) begin : g_s3_entry
    assign s3_entry[d] = from_lite(s3_entry_lite[d]);
  end

  for (genvar d = 0; d < NUM_DUP; d++) begin : g_s3_pred
    always_comb begin
      s3_pred[d]                   = pred_flags(s3_entry[d], s3_hit[d], in_s3_taken[d]);
      s3_pred[d].targets           = targets_of(s3_entry[d], s3_tgt[d]);
      s3_pred[d].multi_hit         = s3_multi_hit[d];
      s3_pred[d].fall_through_err  = s3_ft_err[d];
      s3_pred[d].fall_through_addr = fall_through_addr(s3_pc[d], s3_ft_err[d], s3_entry[d].carry,
                                                       s3_entry[d].pftAddr);
    end
  end

  assign last_stage_entry = s3_entry0;
  assign last_stage_meta  = {{(META_W - FMETA_W){1'b0}}, last_stage_meta_r};

  // ===========================================================================
  // §5 更新：锁存 update，命中则当拍写，未命中则先读 tag、两拍后写
  // ===========================================================================
  logic              update_valid;
  logic              update_false_hit;
  logic              update_old_entry;
  logic [META_W-1:0] update_meta_r;       // 只读 [66:64]：meta.writeWay / meta.hit
  logic              update_meta_hit;
  logic [1:0]        update_meta_way;
  logic              update_now;          // meta 说预测时命中：直接写回那一路
  logic              update_need_read;    // 未命中：先读一次 bank 查 tag
  logic              s1_ready_block_r;    // 上一拍也在读 tag
  logic [1:0]        write_way_r;         // bank 查 tag 的结果，下一拍才用
  logic              write_alloc_r;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) update_valid <= 1'b0;
    else       update_valid <= update_valid_in;
  end

  always_ff @(posedge clock) begin
    if (update_valid_in) begin
      update_entry     <= update_entry_in;
      update_false_hit <= update_false_hit_in;
      update_old_entry <= update_old_entry_in;
    end
    // 训练旧条目（old_entry）不需要 meta，省一次 516 位翻转
    if (update_valid_in && !update_old_entry_in)
      update_meta_r <= update_meta_in;
    s1_ready_block_r <= update_need_read;
    write_way_r      <= bank_update_way;
    write_alloc_r    <= !bank_update_hit;
  end

  assign need_reopen      = s0_close && ((update_valid && update_false_hit) || redirect_from_ifu);
  assign update_meta_hit  = update_meta_r[64];
  assign update_meta_way  = update_meta_r[66:65];
  // 关闭期间不训练 FTB（uFTB 在顶）
  assign u_valid          = update_valid && !update_old_entry && !s0_close;
  assign update_now       = u_valid && update_meta_hit;
  assign update_need_read = u_valid && !update_meta_hit;

  // 读 tag 那一拍及下一拍不接受新的预测读（SRAM 单端口）
  assign s1_ready = bank_req_ready && !update_need_read && !s1_ready_block_r;

  assign bank_u_req_valid     = update_need_read;
  assign bank_update_access   = update_need_read;
  assign write_valid_delay_in = update_need_read;
  assign bank_write_valid     = (update_now || write_valid_delay_out) && !update_need_read;
  assign bank_write_pc        = update_now ? update_pc : delay2_pc;
  assign bank_write_entry     = update_now ? update_entry : delay2_entry;
  assign bank_write_tag       = bank_write_pc[29:10];          // FTBTableAddr.getTag
  assign bank_write_way       = update_now ? update_meta_way : write_way_r;
  assign bank_write_alloc     = !update_now && write_alloc_r;

  // ===========================================================================
  // §6 性能计数：提交时命中 / 未命中，各打两拍出
  // ===========================================================================
  logic       s0_fire_hit_perf_r;      // golden REG：只喂 perf 探针 ftb_read_hits
  logic       s0_fire_miss_perf_r;     // golden REG_1：只喂 perf 探针 ftb_read_misses
  logic [1:0] perf_hit_r;
  logic [1:0] perf_miss_r;

  always_ff @(posedge clock) begin
    s0_fire_hit_perf_r  <= s0_fire[0];
    s0_fire_miss_perf_r <= s0_fire[0];
    perf_hit_r          <= {perf_hit_r[0], update_valid && update_meta_hit};
    perf_miss_r         <= {perf_miss_r[0], update_valid && !update_meta_hit};
  end

  assign perf_commit_hit  = perf_hit_r[1];
  assign perf_commit_miss = perf_miss_r[1];

endmodule

// BEGIN GENERATED(FTB) —— scripts/gen_ftb.py（端口表与连线从 G1 golden 机械生成，勿手改）
module FTB
  import xs_ftb_pkg::*;
  import ftb_pred_pkg::*;
(
  input  logic clock,
  input  logic reset,
  input  logic [47:0] io_reset_vector,
  input  logic [49:0] io_in_bits_s0_pc_0,
  input  logic [49:0] io_in_bits_s0_pc_1,
  input  logic [49:0] io_in_bits_s0_pc_2,
  input  logic [49:0] io_in_bits_s0_pc_3,
  input  logic io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0,
  input  logic io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1,
  input  logic io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0,
  input  logic io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1,
  input  logic io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0,
  input  logic io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1,
  input  logic io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0,
  input  logic io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1,
  input  logic io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0,
  input  logic io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1,
  input  logic io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0,
  input  logic io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1,
  input  logic io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0,
  input  logic io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1,
  input  logic io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0,
  input  logic io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1,
  input  logic io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0,
  input  logic io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1,
  output logic io_out_s2_full_pred_0_br_taken_mask_0,
  output logic io_out_s2_full_pred_0_br_taken_mask_1,
  output logic io_out_s2_full_pred_0_slot_valids_0,
  output logic io_out_s2_full_pred_0_slot_valids_1,
  output logic [49:0] io_out_s2_full_pred_0_targets_0,
  output logic [49:0] io_out_s2_full_pred_0_targets_1,
  output logic [49:0] io_out_s2_full_pred_0_jalr_target,
  output logic [3:0] io_out_s2_full_pred_0_offsets_0,
  output logic [3:0] io_out_s2_full_pred_0_offsets_1,
  output logic [49:0] io_out_s2_full_pred_0_fallThroughAddr,
  output logic io_out_s2_full_pred_0_fallThroughErr,
  output logic io_out_s2_full_pred_0_is_jal,
  output logic io_out_s2_full_pred_0_is_jalr,
  output logic io_out_s2_full_pred_0_is_call,
  output logic io_out_s2_full_pred_0_is_ret,
  output logic io_out_s2_full_pred_0_last_may_be_rvi_call,
  output logic io_out_s2_full_pred_0_is_br_sharing,
  output logic io_out_s2_full_pred_0_hit,
  output logic io_out_s2_full_pred_1_br_taken_mask_0,
  output logic io_out_s2_full_pred_1_br_taken_mask_1,
  output logic io_out_s2_full_pred_1_slot_valids_0,
  output logic io_out_s2_full_pred_1_slot_valids_1,
  output logic [49:0] io_out_s2_full_pred_1_targets_0,
  output logic [49:0] io_out_s2_full_pred_1_targets_1,
  output logic [49:0] io_out_s2_full_pred_1_jalr_target,
  output logic [3:0] io_out_s2_full_pred_1_offsets_0,
  output logic [3:0] io_out_s2_full_pred_1_offsets_1,
  output logic [49:0] io_out_s2_full_pred_1_fallThroughAddr,
  output logic io_out_s2_full_pred_1_fallThroughErr,
  output logic io_out_s2_full_pred_1_is_jal,
  output logic io_out_s2_full_pred_1_is_jalr,
  output logic io_out_s2_full_pred_1_is_call,
  output logic io_out_s2_full_pred_1_is_ret,
  output logic io_out_s2_full_pred_1_last_may_be_rvi_call,
  output logic io_out_s2_full_pred_1_is_br_sharing,
  output logic io_out_s2_full_pred_1_hit,
  output logic io_out_s2_full_pred_2_br_taken_mask_0,
  output logic io_out_s2_full_pred_2_br_taken_mask_1,
  output logic io_out_s2_full_pred_2_slot_valids_0,
  output logic io_out_s2_full_pred_2_slot_valids_1,
  output logic [49:0] io_out_s2_full_pred_2_targets_0,
  output logic [49:0] io_out_s2_full_pred_2_targets_1,
  output logic [49:0] io_out_s2_full_pred_2_jalr_target,
  output logic [3:0] io_out_s2_full_pred_2_offsets_0,
  output logic [3:0] io_out_s2_full_pred_2_offsets_1,
  output logic [49:0] io_out_s2_full_pred_2_fallThroughAddr,
  output logic io_out_s2_full_pred_2_fallThroughErr,
  output logic io_out_s2_full_pred_2_is_jal,
  output logic io_out_s2_full_pred_2_is_jalr,
  output logic io_out_s2_full_pred_2_is_call,
  output logic io_out_s2_full_pred_2_is_ret,
  output logic io_out_s2_full_pred_2_last_may_be_rvi_call,
  output logic io_out_s2_full_pred_2_is_br_sharing,
  output logic io_out_s2_full_pred_2_hit,
  output logic io_out_s2_full_pred_3_br_taken_mask_0,
  output logic io_out_s2_full_pred_3_br_taken_mask_1,
  output logic io_out_s2_full_pred_3_slot_valids_0,
  output logic io_out_s2_full_pred_3_slot_valids_1,
  output logic [49:0] io_out_s2_full_pred_3_targets_0,
  output logic [49:0] io_out_s2_full_pred_3_targets_1,
  output logic [49:0] io_out_s2_full_pred_3_jalr_target,
  output logic [3:0] io_out_s2_full_pred_3_offsets_0,
  output logic [3:0] io_out_s2_full_pred_3_offsets_1,
  output logic [49:0] io_out_s2_full_pred_3_fallThroughAddr,
  output logic io_out_s2_full_pred_3_fallThroughErr,
  output logic io_out_s2_full_pred_3_is_jal,
  output logic io_out_s2_full_pred_3_is_jalr,
  output logic io_out_s2_full_pred_3_is_call,
  output logic io_out_s2_full_pred_3_is_ret,
  output logic io_out_s2_full_pred_3_last_may_be_rvi_call,
  output logic io_out_s2_full_pred_3_is_br_sharing,
  output logic io_out_s2_full_pred_3_hit,
  output logic io_out_s3_full_pred_0_br_taken_mask_0,
  output logic io_out_s3_full_pred_0_br_taken_mask_1,
  output logic io_out_s3_full_pred_0_slot_valids_0,
  output logic io_out_s3_full_pred_0_slot_valids_1,
  output logic [49:0] io_out_s3_full_pred_0_targets_0,
  output logic [49:0] io_out_s3_full_pred_0_targets_1,
  output logic [3:0] io_out_s3_full_pred_0_offsets_0,
  output logic [3:0] io_out_s3_full_pred_0_offsets_1,
  output logic [49:0] io_out_s3_full_pred_0_fallThroughAddr,
  output logic io_out_s3_full_pred_0_fallThroughErr,
  output logic io_out_s3_full_pred_0_multiHit,
  output logic io_out_s3_full_pred_0_is_jal,
  output logic io_out_s3_full_pred_0_is_jalr,
  output logic io_out_s3_full_pred_0_is_call,
  output logic io_out_s3_full_pred_0_is_ret,
  output logic io_out_s3_full_pred_0_last_may_be_rvi_call,
  output logic io_out_s3_full_pred_0_is_br_sharing,
  output logic io_out_s3_full_pred_0_hit,
  output logic io_out_s3_full_pred_1_br_taken_mask_0,
  output logic io_out_s3_full_pred_1_br_taken_mask_1,
  output logic io_out_s3_full_pred_1_slot_valids_0,
  output logic io_out_s3_full_pred_1_slot_valids_1,
  output logic [49:0] io_out_s3_full_pred_1_targets_0,
  output logic [49:0] io_out_s3_full_pred_1_targets_1,
  output logic [3:0] io_out_s3_full_pred_1_offsets_0,
  output logic [3:0] io_out_s3_full_pred_1_offsets_1,
  output logic [49:0] io_out_s3_full_pred_1_fallThroughAddr,
  output logic io_out_s3_full_pred_1_fallThroughErr,
  output logic io_out_s3_full_pred_1_multiHit,
  output logic io_out_s3_full_pred_1_is_jal,
  output logic io_out_s3_full_pred_1_is_jalr,
  output logic io_out_s3_full_pred_1_is_call,
  output logic io_out_s3_full_pred_1_is_ret,
  output logic io_out_s3_full_pred_1_last_may_be_rvi_call,
  output logic io_out_s3_full_pred_1_is_br_sharing,
  output logic io_out_s3_full_pred_1_hit,
  output logic io_out_s3_full_pred_2_br_taken_mask_0,
  output logic io_out_s3_full_pred_2_br_taken_mask_1,
  output logic io_out_s3_full_pred_2_slot_valids_0,
  output logic io_out_s3_full_pred_2_slot_valids_1,
  output logic [49:0] io_out_s3_full_pred_2_targets_0,
  output logic [49:0] io_out_s3_full_pred_2_targets_1,
  output logic [3:0] io_out_s3_full_pred_2_offsets_0,
  output logic [3:0] io_out_s3_full_pred_2_offsets_1,
  output logic [49:0] io_out_s3_full_pred_2_fallThroughAddr,
  output logic io_out_s3_full_pred_2_fallThroughErr,
  output logic io_out_s3_full_pred_2_multiHit,
  output logic io_out_s3_full_pred_2_is_jal,
  output logic io_out_s3_full_pred_2_is_jalr,
  output logic io_out_s3_full_pred_2_is_call,
  output logic io_out_s3_full_pred_2_is_ret,
  output logic io_out_s3_full_pred_2_last_may_be_rvi_call,
  output logic io_out_s3_full_pred_2_is_br_sharing,
  output logic io_out_s3_full_pred_2_hit,
  output logic io_out_s3_full_pred_3_br_taken_mask_0,
  output logic io_out_s3_full_pred_3_br_taken_mask_1,
  output logic io_out_s3_full_pred_3_slot_valids_0,
  output logic io_out_s3_full_pred_3_slot_valids_1,
  output logic [49:0] io_out_s3_full_pred_3_targets_0,
  output logic [49:0] io_out_s3_full_pred_3_targets_1,
  output logic [3:0] io_out_s3_full_pred_3_offsets_0,
  output logic [3:0] io_out_s3_full_pred_3_offsets_1,
  output logic [49:0] io_out_s3_full_pred_3_fallThroughAddr,
  output logic io_out_s3_full_pred_3_fallThroughErr,
  output logic io_out_s3_full_pred_3_multiHit,
  output logic io_out_s3_full_pred_3_is_jal,
  output logic io_out_s3_full_pred_3_is_jalr,
  output logic io_out_s3_full_pred_3_is_call,
  output logic io_out_s3_full_pred_3_is_ret,
  output logic io_out_s3_full_pred_3_last_may_be_rvi_call,
  output logic io_out_s3_full_pred_3_is_br_sharing,
  output logic io_out_s3_full_pred_3_hit,
  output logic io_out_s1_uftbHit,
  output logic io_out_s1_uftbHasIndirect,
  output logic io_out_s1_ftbCloseReq,
  output logic [515:0] io_out_last_stage_meta,
  output logic io_out_last_stage_spec_info_sc_disagree_0,
  output logic io_out_last_stage_spec_info_sc_disagree_1,
  output logic io_out_last_stage_ftb_entry_isCall,
  output logic io_out_last_stage_ftb_entry_isRet,
  output logic io_out_last_stage_ftb_entry_isJalr,
  output logic io_out_last_stage_ftb_entry_valid,
  output logic [3:0] io_out_last_stage_ftb_entry_brSlots_0_offset,
  output logic io_out_last_stage_ftb_entry_brSlots_0_sharing,
  output logic io_out_last_stage_ftb_entry_brSlots_0_valid,
  output logic [11:0] io_out_last_stage_ftb_entry_brSlots_0_lower,
  output logic [1:0] io_out_last_stage_ftb_entry_brSlots_0_tarStat,
  output logic [3:0] io_out_last_stage_ftb_entry_tailSlot_offset,
  output logic io_out_last_stage_ftb_entry_tailSlot_sharing,
  output logic io_out_last_stage_ftb_entry_tailSlot_valid,
  output logic [19:0] io_out_last_stage_ftb_entry_tailSlot_lower,
  output logic [1:0] io_out_last_stage_ftb_entry_tailSlot_tarStat,
  output logic [3:0] io_out_last_stage_ftb_entry_pftAddr,
  output logic io_out_last_stage_ftb_entry_carry,
  output logic io_out_last_stage_ftb_entry_last_may_be_rvi_call,
  output logic io_out_last_stage_ftb_entry_strong_bias_0,
  output logic io_out_last_stage_ftb_entry_strong_bias_1,
  input  logic io_fauftb_entry_in_isCall,
  input  logic io_fauftb_entry_in_isRet,
  input  logic io_fauftb_entry_in_isJalr,
  input  logic io_fauftb_entry_in_valid,
  input  logic [3:0] io_fauftb_entry_in_brSlots_0_offset,
  input  logic io_fauftb_entry_in_brSlots_0_sharing,
  input  logic io_fauftb_entry_in_brSlots_0_valid,
  input  logic [11:0] io_fauftb_entry_in_brSlots_0_lower,
  input  logic [1:0] io_fauftb_entry_in_brSlots_0_tarStat,
  input  logic [3:0] io_fauftb_entry_in_tailSlot_offset,
  input  logic io_fauftb_entry_in_tailSlot_sharing,
  input  logic io_fauftb_entry_in_tailSlot_valid,
  input  logic [19:0] io_fauftb_entry_in_tailSlot_lower,
  input  logic [1:0] io_fauftb_entry_in_tailSlot_tarStat,
  input  logic [3:0] io_fauftb_entry_in_pftAddr,
  input  logic io_fauftb_entry_in_carry,
  input  logic io_fauftb_entry_in_last_may_be_rvi_call,
  input  logic io_fauftb_entry_in_strong_bias_0,
  input  logic io_fauftb_entry_in_strong_bias_1,
  input  logic io_fauftb_entry_hit_in,
  input  logic io_ctrl_btb_enable,
  input  logic io_s0_fire_0,
  input  logic io_s0_fire_1,
  input  logic io_s0_fire_2,
  input  logic io_s0_fire_3,
  input  logic io_s1_fire_0,
  input  logic io_s1_fire_1,
  input  logic io_s1_fire_2,
  input  logic io_s1_fire_3,
  input  logic io_s2_fire_0,
  input  logic io_s2_fire_1,
  input  logic io_s2_fire_2,
  input  logic io_s2_fire_3,
  input  logic io_s3_fire_0,
  output logic io_s1_ready,
  input  logic io_update_valid,
  input  logic [49:0] io_update_bits_pc,
  input  logic io_update_bits_ftb_entry_isCall,
  input  logic io_update_bits_ftb_entry_isRet,
  input  logic io_update_bits_ftb_entry_isJalr,
  input  logic io_update_bits_ftb_entry_valid,
  input  logic [3:0] io_update_bits_ftb_entry_brSlots_0_offset,
  input  logic io_update_bits_ftb_entry_brSlots_0_sharing,
  input  logic io_update_bits_ftb_entry_brSlots_0_valid,
  input  logic [11:0] io_update_bits_ftb_entry_brSlots_0_lower,
  input  logic [1:0] io_update_bits_ftb_entry_brSlots_0_tarStat,
  input  logic [3:0] io_update_bits_ftb_entry_tailSlot_offset,
  input  logic io_update_bits_ftb_entry_tailSlot_sharing,
  input  logic io_update_bits_ftb_entry_tailSlot_valid,
  input  logic [19:0] io_update_bits_ftb_entry_tailSlot_lower,
  input  logic [1:0] io_update_bits_ftb_entry_tailSlot_tarStat,
  input  logic [3:0] io_update_bits_ftb_entry_pftAddr,
  input  logic io_update_bits_ftb_entry_carry,
  input  logic io_update_bits_ftb_entry_last_may_be_rvi_call,
  input  logic io_update_bits_ftb_entry_strong_bias_0,
  input  logic io_update_bits_ftb_entry_strong_bias_1,
  input  logic io_update_bits_false_hit,
  input  logic io_update_bits_old_entry,
  input  logic [515:0] io_update_bits_meta,
  input  logic io_redirectFromIFU,
  output logic [5:0] io_perf_0_value,
  output logic [5:0] io_perf_1_value,
  input  logic [5:0] boreChildrenBd_bore_array,
  input  logic boreChildrenBd_bore_all,
  input  logic boreChildrenBd_bore_req,
  output logic boreChildrenBd_bore_ack,
  input  logic boreChildrenBd_bore_writeen,
  input  logic [3:0] boreChildrenBd_bore_be,
  input  logic [9:0] boreChildrenBd_bore_addr,
  input  logic [39:0] boreChildrenBd_bore_indata,
  input  logic boreChildrenBd_bore_readen,
  input  logic [9:0] boreChildrenBd_bore_addr_rd,
  output logic [39:0] boreChildrenBd_bore_outdata,
  input  logic sigFromSrams_bore_ram_hold,
  input  logic sigFromSrams_bore_ram_bypass,
  input  logic sigFromSrams_bore_ram_bp_clken,
  input  logic sigFromSrams_bore_ram_aux_clk,
  input  logic sigFromSrams_bore_ram_aux_ckbp,
  input  logic sigFromSrams_bore_ram_mcp_hold,
  input  logic sigFromSrams_bore_cgen,
  input  logic sigFromSrams_bore_1_ram_hold,
  input  logic sigFromSrams_bore_1_ram_bypass,
  input  logic sigFromSrams_bore_1_ram_bp_clken,
  input  logic sigFromSrams_bore_1_ram_aux_clk,
  input  logic sigFromSrams_bore_1_ram_aux_ckbp,
  input  logic sigFromSrams_bore_1_ram_mcp_hold,
  input  logic sigFromSrams_bore_1_cgen,
  input  logic sigFromSrams_bore_2_ram_hold,
  input  logic sigFromSrams_bore_2_ram_bypass,
  input  logic sigFromSrams_bore_2_ram_bp_clken,
  input  logic sigFromSrams_bore_2_ram_aux_clk,
  input  logic sigFromSrams_bore_2_ram_aux_ckbp,
  input  logic sigFromSrams_bore_2_ram_mcp_hold,
  input  logic sigFromSrams_bore_2_cgen,
  input  logic sigFromSrams_bore_3_ram_hold,
  input  logic sigFromSrams_bore_3_ram_bypass,
  input  logic sigFromSrams_bore_3_ram_bp_clken,
  input  logic sigFromSrams_bore_3_ram_aux_clk,
  input  logic sigFromSrams_bore_3_ram_aux_ckbp,
  input  logic sigFromSrams_bore_3_ram_mcp_hold,
  input  logic sigFromSrams_bore_3_cgen,
  input  logic sigFromSrams_bore_4_ram_hold,
  input  logic sigFromSrams_bore_4_ram_bypass,
  input  logic sigFromSrams_bore_4_ram_bp_clken,
  input  logic sigFromSrams_bore_4_ram_aux_clk,
  input  logic sigFromSrams_bore_4_ram_aux_ckbp,
  input  logic sigFromSrams_bore_4_ram_mcp_hold,
  input  logic sigFromSrams_bore_4_cgen,
  input  logic sigFromSrams_bore_5_ram_hold,
  input  logic sigFromSrams_bore_5_ram_bypass,
  input  logic sigFromSrams_bore_5_ram_bp_clken,
  input  logic sigFromSrams_bore_5_ram_aux_clk,
  input  logic sigFromSrams_bore_5_ram_aux_ckbp,
  input  logic sigFromSrams_bore_5_ram_mcp_hold,
  input  logic sigFromSrams_bore_5_cgen,
  input  logic sigFromSrams_bore_6_ram_hold,
  input  logic sigFromSrams_bore_6_ram_bypass,
  input  logic sigFromSrams_bore_6_ram_bp_clken,
  input  logic sigFromSrams_bore_6_ram_aux_clk,
  input  logic sigFromSrams_bore_6_ram_aux_ckbp,
  input  logic sigFromSrams_bore_6_ram_mcp_hold,
  input  logic sigFromSrams_bore_6_cgen,
  input  logic sigFromSrams_bore_7_ram_hold,
  input  logic sigFromSrams_bore_7_ram_bypass,
  input  logic sigFromSrams_bore_7_ram_bp_clken,
  input  logic sigFromSrams_bore_7_ram_aux_clk,
  input  logic sigFromSrams_bore_7_ram_aux_ckbp,
  input  logic sigFromSrams_bore_7_ram_mcp_hold,
  input  logic sigFromSrams_bore_7_cgen
);

  // ---- 核侧结构化信号 ----
  logic [PC_W-1:0] s0_pc       [NUM_DUP];
  logic            s0_fire     [NUM_DUP];
  logic            s1_fire     [NUM_DUP];
  logic            s2_fire     [NUM_DUP];
  logic [1:0]      in_s2_taken [NUM_DUP];
  logic [1:0]      in_s3_taken [NUM_DUP];
  ftb_pred_t       s2_pred     [NUM_DUP];
  ftb_pred_t       s3_pred     [NUM_DUP];
  ftb_entry_t      fau_entry_in, update_entry_in, last_stage_entry;
  logic            perf_commit_hit, perf_commit_miss;
  // FTBBank / 延迟件接口
  logic            bank_req_ready, bank_req_valid, bank_read_hit, bank_multi_hit;
  logic [1:0]      bank_read_way, bank_multi_way, bank_update_way, bank_write_way;
  ftb_entry_t      bank_read_entry, bank_multi_entry, bank_write_entry;
  logic            bank_u_req_valid, bank_update_hit, bank_update_access;
  logic [PC_W-1:0] bank_write_pc;
  logic            bank_write_valid, bank_write_alloc;
  logic [19:0]     bank_write_tag;
  logic            u_valid, write_valid_delay_in, write_valid_delay_out;
  logic [PC_W-1:0] delay2_pc;
  ftb_entry_t      update_entry, delay2_entry;

  // ---- 端口 <-> 结构化信号（逐端口一条）----
  assign s0_pc[0] = io_in_bits_s0_pc_0;
  assign s0_pc[1] = io_in_bits_s0_pc_1;
  assign s0_pc[2] = io_in_bits_s0_pc_2;
  assign s0_pc[3] = io_in_bits_s0_pc_3;
  assign in_s2_taken[0][0] = io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0;
  assign in_s2_taken[0][1] = io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1;
  assign in_s2_taken[1][0] = io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0;
  assign in_s2_taken[1][1] = io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1;
  assign in_s2_taken[2][0] = io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0;
  assign in_s2_taken[2][1] = io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1;
  assign in_s2_taken[3][0] = io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0;
  assign in_s2_taken[3][1] = io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1;
  assign in_s3_taken[0][0] = io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0;
  assign in_s3_taken[0][1] = io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1;
  assign in_s3_taken[1][0] = io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0;
  assign in_s3_taken[1][1] = io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1;
  assign in_s3_taken[2][0] = io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0;
  assign in_s3_taken[2][1] = io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1;
  assign in_s3_taken[3][0] = io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0;
  assign in_s3_taken[3][1] = io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1;
  assign io_out_s2_full_pred_0_br_taken_mask_0 = s2_pred[0].br_taken_mask[0];
  assign io_out_s2_full_pred_0_br_taken_mask_1 = s2_pred[0].br_taken_mask[1];
  assign io_out_s2_full_pred_0_slot_valids_0 = s2_pred[0].slot_valids[0];
  assign io_out_s2_full_pred_0_slot_valids_1 = s2_pred[0].slot_valids[1];
  assign io_out_s2_full_pred_0_targets_0 = s2_pred[0].targets[0];
  assign io_out_s2_full_pred_0_targets_1 = s2_pred[0].targets[1];
  assign io_out_s2_full_pred_0_jalr_target = s2_pred[0].targets[1];
  assign io_out_s2_full_pred_0_offsets_0 = s2_pred[0].offsets[0];
  assign io_out_s2_full_pred_0_offsets_1 = s2_pred[0].offsets[1];
  assign io_out_s2_full_pred_0_fallThroughAddr = s2_pred[0].fall_through_addr;
  assign io_out_s2_full_pred_0_fallThroughErr = s2_pred[0].fall_through_err;
  assign io_out_s2_full_pred_0_is_jal = s2_pred[0].is_jal;
  assign io_out_s2_full_pred_0_is_jalr = s2_pred[0].is_jalr;
  assign io_out_s2_full_pred_0_is_call = s2_pred[0].is_call;
  assign io_out_s2_full_pred_0_is_ret = s2_pred[0].is_ret;
  assign io_out_s2_full_pred_0_last_may_be_rvi_call = s2_pred[0].last_may_be_rvi_call;
  assign io_out_s2_full_pred_0_is_br_sharing = s2_pred[0].is_br_sharing;
  assign io_out_s2_full_pred_0_hit = s2_pred[0].hit;
  assign io_out_s2_full_pred_1_br_taken_mask_0 = s2_pred[1].br_taken_mask[0];
  assign io_out_s2_full_pred_1_br_taken_mask_1 = s2_pred[1].br_taken_mask[1];
  assign io_out_s2_full_pred_1_slot_valids_0 = s2_pred[1].slot_valids[0];
  assign io_out_s2_full_pred_1_slot_valids_1 = s2_pred[1].slot_valids[1];
  assign io_out_s2_full_pred_1_targets_0 = s2_pred[1].targets[0];
  assign io_out_s2_full_pred_1_targets_1 = s2_pred[1].targets[1];
  assign io_out_s2_full_pred_1_jalr_target = s2_pred[1].targets[1];
  assign io_out_s2_full_pred_1_offsets_0 = s2_pred[1].offsets[0];
  assign io_out_s2_full_pred_1_offsets_1 = s2_pred[1].offsets[1];
  assign io_out_s2_full_pred_1_fallThroughAddr = s2_pred[1].fall_through_addr;
  assign io_out_s2_full_pred_1_fallThroughErr = s2_pred[1].fall_through_err;
  assign io_out_s2_full_pred_1_is_jal = s2_pred[1].is_jal;
  assign io_out_s2_full_pred_1_is_jalr = s2_pred[1].is_jalr;
  assign io_out_s2_full_pred_1_is_call = s2_pred[1].is_call;
  assign io_out_s2_full_pred_1_is_ret = s2_pred[1].is_ret;
  assign io_out_s2_full_pred_1_last_may_be_rvi_call = s2_pred[1].last_may_be_rvi_call;
  assign io_out_s2_full_pred_1_is_br_sharing = s2_pred[1].is_br_sharing;
  assign io_out_s2_full_pred_1_hit = s2_pred[1].hit;
  assign io_out_s2_full_pred_2_br_taken_mask_0 = s2_pred[2].br_taken_mask[0];
  assign io_out_s2_full_pred_2_br_taken_mask_1 = s2_pred[2].br_taken_mask[1];
  assign io_out_s2_full_pred_2_slot_valids_0 = s2_pred[2].slot_valids[0];
  assign io_out_s2_full_pred_2_slot_valids_1 = s2_pred[2].slot_valids[1];
  assign io_out_s2_full_pred_2_targets_0 = s2_pred[2].targets[0];
  assign io_out_s2_full_pred_2_targets_1 = s2_pred[2].targets[1];
  assign io_out_s2_full_pred_2_jalr_target = s2_pred[2].targets[1];
  assign io_out_s2_full_pred_2_offsets_0 = s2_pred[2].offsets[0];
  assign io_out_s2_full_pred_2_offsets_1 = s2_pred[2].offsets[1];
  assign io_out_s2_full_pred_2_fallThroughAddr = s2_pred[2].fall_through_addr;
  assign io_out_s2_full_pred_2_fallThroughErr = s2_pred[2].fall_through_err;
  assign io_out_s2_full_pred_2_is_jal = s2_pred[2].is_jal;
  assign io_out_s2_full_pred_2_is_jalr = s2_pred[2].is_jalr;
  assign io_out_s2_full_pred_2_is_call = s2_pred[2].is_call;
  assign io_out_s2_full_pred_2_is_ret = s2_pred[2].is_ret;
  assign io_out_s2_full_pred_2_last_may_be_rvi_call = s2_pred[2].last_may_be_rvi_call;
  assign io_out_s2_full_pred_2_is_br_sharing = s2_pred[2].is_br_sharing;
  assign io_out_s2_full_pred_2_hit = s2_pred[2].hit;
  assign io_out_s2_full_pred_3_br_taken_mask_0 = s2_pred[3].br_taken_mask[0];
  assign io_out_s2_full_pred_3_br_taken_mask_1 = s2_pred[3].br_taken_mask[1];
  assign io_out_s2_full_pred_3_slot_valids_0 = s2_pred[3].slot_valids[0];
  assign io_out_s2_full_pred_3_slot_valids_1 = s2_pred[3].slot_valids[1];
  assign io_out_s2_full_pred_3_targets_0 = s2_pred[3].targets[0];
  assign io_out_s2_full_pred_3_targets_1 = s2_pred[3].targets[1];
  assign io_out_s2_full_pred_3_jalr_target = s2_pred[3].targets[1];
  assign io_out_s2_full_pred_3_offsets_0 = s2_pred[3].offsets[0];
  assign io_out_s2_full_pred_3_offsets_1 = s2_pred[3].offsets[1];
  assign io_out_s2_full_pred_3_fallThroughAddr = s2_pred[3].fall_through_addr;
  assign io_out_s2_full_pred_3_fallThroughErr = s2_pred[3].fall_through_err;
  assign io_out_s2_full_pred_3_is_jal = s2_pred[3].is_jal;
  assign io_out_s2_full_pred_3_is_jalr = s2_pred[3].is_jalr;
  assign io_out_s2_full_pred_3_is_call = s2_pred[3].is_call;
  assign io_out_s2_full_pred_3_is_ret = s2_pred[3].is_ret;
  assign io_out_s2_full_pred_3_last_may_be_rvi_call = s2_pred[3].last_may_be_rvi_call;
  assign io_out_s2_full_pred_3_is_br_sharing = s2_pred[3].is_br_sharing;
  assign io_out_s2_full_pred_3_hit = s2_pred[3].hit;
  assign io_out_s3_full_pred_0_br_taken_mask_0 = s3_pred[0].br_taken_mask[0];
  assign io_out_s3_full_pred_0_br_taken_mask_1 = s3_pred[0].br_taken_mask[1];
  assign io_out_s3_full_pred_0_slot_valids_0 = s3_pred[0].slot_valids[0];
  assign io_out_s3_full_pred_0_slot_valids_1 = s3_pred[0].slot_valids[1];
  assign io_out_s3_full_pred_0_targets_0 = s3_pred[0].targets[0];
  assign io_out_s3_full_pred_0_targets_1 = s3_pred[0].targets[1];
  assign io_out_s3_full_pred_0_offsets_0 = s3_pred[0].offsets[0];
  assign io_out_s3_full_pred_0_offsets_1 = s3_pred[0].offsets[1];
  assign io_out_s3_full_pred_0_fallThroughAddr = s3_pred[0].fall_through_addr;
  assign io_out_s3_full_pred_0_fallThroughErr = s3_pred[0].fall_through_err;
  assign io_out_s3_full_pred_0_multiHit = s3_pred[0].multi_hit;
  assign io_out_s3_full_pred_0_is_jal = s3_pred[0].is_jal;
  assign io_out_s3_full_pred_0_is_jalr = s3_pred[0].is_jalr;
  assign io_out_s3_full_pred_0_is_call = s3_pred[0].is_call;
  assign io_out_s3_full_pred_0_is_ret = s3_pred[0].is_ret;
  assign io_out_s3_full_pred_0_last_may_be_rvi_call = s3_pred[0].last_may_be_rvi_call;
  assign io_out_s3_full_pred_0_is_br_sharing = s3_pred[0].is_br_sharing;
  assign io_out_s3_full_pred_0_hit = s3_pred[0].hit;
  assign io_out_s3_full_pred_1_br_taken_mask_0 = s3_pred[1].br_taken_mask[0];
  assign io_out_s3_full_pred_1_br_taken_mask_1 = s3_pred[1].br_taken_mask[1];
  assign io_out_s3_full_pred_1_slot_valids_0 = s3_pred[1].slot_valids[0];
  assign io_out_s3_full_pred_1_slot_valids_1 = s3_pred[1].slot_valids[1];
  assign io_out_s3_full_pred_1_targets_0 = s3_pred[1].targets[0];
  assign io_out_s3_full_pred_1_targets_1 = s3_pred[1].targets[1];
  assign io_out_s3_full_pred_1_offsets_0 = s3_pred[1].offsets[0];
  assign io_out_s3_full_pred_1_offsets_1 = s3_pred[1].offsets[1];
  assign io_out_s3_full_pred_1_fallThroughAddr = s3_pred[1].fall_through_addr;
  assign io_out_s3_full_pred_1_fallThroughErr = s3_pred[1].fall_through_err;
  assign io_out_s3_full_pred_1_multiHit = s3_pred[1].multi_hit;
  assign io_out_s3_full_pred_1_is_jal = s3_pred[1].is_jal;
  assign io_out_s3_full_pred_1_is_jalr = s3_pred[1].is_jalr;
  assign io_out_s3_full_pred_1_is_call = s3_pred[1].is_call;
  assign io_out_s3_full_pred_1_is_ret = s3_pred[1].is_ret;
  assign io_out_s3_full_pred_1_last_may_be_rvi_call = s3_pred[1].last_may_be_rvi_call;
  assign io_out_s3_full_pred_1_is_br_sharing = s3_pred[1].is_br_sharing;
  assign io_out_s3_full_pred_1_hit = s3_pred[1].hit;
  assign io_out_s3_full_pred_2_br_taken_mask_0 = s3_pred[2].br_taken_mask[0];
  assign io_out_s3_full_pred_2_br_taken_mask_1 = s3_pred[2].br_taken_mask[1];
  assign io_out_s3_full_pred_2_slot_valids_0 = s3_pred[2].slot_valids[0];
  assign io_out_s3_full_pred_2_slot_valids_1 = s3_pred[2].slot_valids[1];
  assign io_out_s3_full_pred_2_targets_0 = s3_pred[2].targets[0];
  assign io_out_s3_full_pred_2_targets_1 = s3_pred[2].targets[1];
  assign io_out_s3_full_pred_2_offsets_0 = s3_pred[2].offsets[0];
  assign io_out_s3_full_pred_2_offsets_1 = s3_pred[2].offsets[1];
  assign io_out_s3_full_pred_2_fallThroughAddr = s3_pred[2].fall_through_addr;
  assign io_out_s3_full_pred_2_fallThroughErr = s3_pred[2].fall_through_err;
  assign io_out_s3_full_pred_2_multiHit = s3_pred[2].multi_hit;
  assign io_out_s3_full_pred_2_is_jal = s3_pred[2].is_jal;
  assign io_out_s3_full_pred_2_is_jalr = s3_pred[2].is_jalr;
  assign io_out_s3_full_pred_2_is_call = s3_pred[2].is_call;
  assign io_out_s3_full_pred_2_is_ret = s3_pred[2].is_ret;
  assign io_out_s3_full_pred_2_last_may_be_rvi_call = s3_pred[2].last_may_be_rvi_call;
  assign io_out_s3_full_pred_2_is_br_sharing = s3_pred[2].is_br_sharing;
  assign io_out_s3_full_pred_2_hit = s3_pred[2].hit;
  assign io_out_s3_full_pred_3_br_taken_mask_0 = s3_pred[3].br_taken_mask[0];
  assign io_out_s3_full_pred_3_br_taken_mask_1 = s3_pred[3].br_taken_mask[1];
  assign io_out_s3_full_pred_3_slot_valids_0 = s3_pred[3].slot_valids[0];
  assign io_out_s3_full_pred_3_slot_valids_1 = s3_pred[3].slot_valids[1];
  assign io_out_s3_full_pred_3_targets_0 = s3_pred[3].targets[0];
  assign io_out_s3_full_pred_3_targets_1 = s3_pred[3].targets[1];
  assign io_out_s3_full_pred_3_offsets_0 = s3_pred[3].offsets[0];
  assign io_out_s3_full_pred_3_offsets_1 = s3_pred[3].offsets[1];
  assign io_out_s3_full_pred_3_fallThroughAddr = s3_pred[3].fall_through_addr;
  assign io_out_s3_full_pred_3_fallThroughErr = s3_pred[3].fall_through_err;
  assign io_out_s3_full_pred_3_multiHit = s3_pred[3].multi_hit;
  assign io_out_s3_full_pred_3_is_jal = s3_pred[3].is_jal;
  assign io_out_s3_full_pred_3_is_jalr = s3_pred[3].is_jalr;
  assign io_out_s3_full_pred_3_is_call = s3_pred[3].is_call;
  assign io_out_s3_full_pred_3_is_ret = s3_pred[3].is_ret;
  assign io_out_s3_full_pred_3_last_may_be_rvi_call = s3_pred[3].last_may_be_rvi_call;
  assign io_out_s3_full_pred_3_is_br_sharing = s3_pred[3].is_br_sharing;
  assign io_out_s3_full_pred_3_hit = s3_pred[3].hit;
  assign io_out_last_stage_spec_info_sc_disagree_0 = io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0;
  assign io_out_last_stage_spec_info_sc_disagree_1 = io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1;
  assign io_out_last_stage_ftb_entry_isCall = last_stage_entry.isCall;
  assign io_out_last_stage_ftb_entry_isRet = last_stage_entry.isRet;
  assign io_out_last_stage_ftb_entry_isJalr = last_stage_entry.isJalr;
  assign io_out_last_stage_ftb_entry_valid = last_stage_entry.valid;
  assign io_out_last_stage_ftb_entry_brSlots_0_offset = last_stage_entry.brSlot.offset;
  assign io_out_last_stage_ftb_entry_brSlots_0_sharing = last_stage_entry.brSlot.sharing;
  assign io_out_last_stage_ftb_entry_brSlots_0_valid = last_stage_entry.brSlot.valid;
  assign io_out_last_stage_ftb_entry_brSlots_0_lower = last_stage_entry.brSlot.lower;
  assign io_out_last_stage_ftb_entry_brSlots_0_tarStat = last_stage_entry.brSlot.tarStat;
  assign io_out_last_stage_ftb_entry_tailSlot_offset = last_stage_entry.tailSlot.offset;
  assign io_out_last_stage_ftb_entry_tailSlot_sharing = last_stage_entry.tailSlot.sharing;
  assign io_out_last_stage_ftb_entry_tailSlot_valid = last_stage_entry.tailSlot.valid;
  assign io_out_last_stage_ftb_entry_tailSlot_lower = last_stage_entry.tailSlot.lower;
  assign io_out_last_stage_ftb_entry_tailSlot_tarStat = last_stage_entry.tailSlot.tarStat;
  assign io_out_last_stage_ftb_entry_pftAddr = last_stage_entry.pftAddr;
  assign io_out_last_stage_ftb_entry_carry = last_stage_entry.carry;
  assign io_out_last_stage_ftb_entry_last_may_be_rvi_call = last_stage_entry.last_may_be_rvi_call;
  assign io_out_last_stage_ftb_entry_strong_bias_0 = last_stage_entry.strong_bias[0];
  assign io_out_last_stage_ftb_entry_strong_bias_1 = last_stage_entry.strong_bias[1];
  assign fau_entry_in.isCall = io_fauftb_entry_in_isCall;
  assign fau_entry_in.isRet = io_fauftb_entry_in_isRet;
  assign fau_entry_in.isJalr = io_fauftb_entry_in_isJalr;
  assign fau_entry_in.valid = io_fauftb_entry_in_valid;
  assign fau_entry_in.brSlot.offset = io_fauftb_entry_in_brSlots_0_offset;
  assign fau_entry_in.brSlot.sharing = io_fauftb_entry_in_brSlots_0_sharing;
  assign fau_entry_in.brSlot.valid = io_fauftb_entry_in_brSlots_0_valid;
  assign fau_entry_in.brSlot.lower = io_fauftb_entry_in_brSlots_0_lower;
  assign fau_entry_in.brSlot.tarStat = io_fauftb_entry_in_brSlots_0_tarStat;
  assign fau_entry_in.tailSlot.offset = io_fauftb_entry_in_tailSlot_offset;
  assign fau_entry_in.tailSlot.sharing = io_fauftb_entry_in_tailSlot_sharing;
  assign fau_entry_in.tailSlot.valid = io_fauftb_entry_in_tailSlot_valid;
  assign fau_entry_in.tailSlot.lower = io_fauftb_entry_in_tailSlot_lower;
  assign fau_entry_in.tailSlot.tarStat = io_fauftb_entry_in_tailSlot_tarStat;
  assign fau_entry_in.pftAddr = io_fauftb_entry_in_pftAddr;
  assign fau_entry_in.carry = io_fauftb_entry_in_carry;
  assign fau_entry_in.last_may_be_rvi_call = io_fauftb_entry_in_last_may_be_rvi_call;
  assign fau_entry_in.strong_bias[0] = io_fauftb_entry_in_strong_bias_0;
  assign fau_entry_in.strong_bias[1] = io_fauftb_entry_in_strong_bias_1;
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
  assign update_entry_in.isCall = io_update_bits_ftb_entry_isCall;
  assign update_entry_in.isRet = io_update_bits_ftb_entry_isRet;
  assign update_entry_in.isJalr = io_update_bits_ftb_entry_isJalr;
  assign update_entry_in.valid = io_update_bits_ftb_entry_valid;
  assign update_entry_in.brSlot.offset = io_update_bits_ftb_entry_brSlots_0_offset;
  assign update_entry_in.brSlot.sharing = io_update_bits_ftb_entry_brSlots_0_sharing;
  assign update_entry_in.brSlot.valid = io_update_bits_ftb_entry_brSlots_0_valid;
  assign update_entry_in.brSlot.lower = io_update_bits_ftb_entry_brSlots_0_lower;
  assign update_entry_in.brSlot.tarStat = io_update_bits_ftb_entry_brSlots_0_tarStat;
  assign update_entry_in.tailSlot.offset = io_update_bits_ftb_entry_tailSlot_offset;
  assign update_entry_in.tailSlot.sharing = io_update_bits_ftb_entry_tailSlot_sharing;
  assign update_entry_in.tailSlot.valid = io_update_bits_ftb_entry_tailSlot_valid;
  assign update_entry_in.tailSlot.lower = io_update_bits_ftb_entry_tailSlot_lower;
  assign update_entry_in.tailSlot.tarStat = io_update_bits_ftb_entry_tailSlot_tarStat;
  assign update_entry_in.pftAddr = io_update_bits_ftb_entry_pftAddr;
  assign update_entry_in.carry = io_update_bits_ftb_entry_carry;
  assign update_entry_in.last_may_be_rvi_call = io_update_bits_ftb_entry_last_may_be_rvi_call;
  assign update_entry_in.strong_bias[0] = io_update_bits_ftb_entry_strong_bias_0;
  assign update_entry_in.strong_bias[1] = io_update_bits_ftb_entry_strong_bias_1;
  assign io_perf_0_value = {5'h0, perf_commit_hit};
  assign io_perf_1_value = {5'h0, perf_commit_miss};
  // io_s3_fire_0：golden 里只喂 S3 fall-through 断言（非 SYNTHESIS），无功能读者

  xs_FTB_core u_core (
    .clock                  (clock),
    .reset                  (reset),
    .reset_vector           (io_reset_vector),
    .s0_pc                  (s0_pc),
    .s0_fire                (s0_fire),
    .s1_fire                (s1_fire),
    .s2_fire                (s2_fire),
    .in_s2_taken            (in_s2_taken),
    .in_s3_taken            (in_s3_taken),
    .fau_entry_in           (fau_entry_in),
    .fau_hit_in             (io_fauftb_entry_hit_in),
    .btb_enable             (io_ctrl_btb_enable),
    .s2_pred                (s2_pred),
    .s3_pred                (s3_pred),
    .s1_uftb_hit            (io_out_s1_uftbHit),
    .s1_uftb_has_indirect   (io_out_s1_uftbHasIndirect),
    .s1_close_req           (io_out_s1_ftbCloseReq),
    .last_stage_meta        (io_out_last_stage_meta),
    .last_stage_entry       (last_stage_entry),
    .s1_ready               (io_s1_ready),
    .update_valid_in        (io_update_valid),
    .update_pc              (io_update_bits_pc),
    .update_entry_in        (update_entry_in),
    .update_false_hit_in    (io_update_bits_false_hit),
    .update_old_entry_in    (io_update_bits_old_entry),
    .update_meta_in         (io_update_bits_meta),
    .redirect_from_ifu      (io_redirectFromIFU),
    .perf_commit_hit        (perf_commit_hit),
    .perf_commit_miss       (perf_commit_miss),
    .bank_req_ready         (bank_req_ready),
    .bank_req_valid         (bank_req_valid),
    .bank_read_entry        (bank_read_entry),
    .bank_read_hit          (bank_read_hit),
    .bank_read_way          (bank_read_way),
    .bank_multi_entry       (bank_multi_entry),
    .bank_multi_hit         (bank_multi_hit),
    .bank_multi_way         (bank_multi_way),
    .bank_u_req_valid       (bank_u_req_valid),
    .bank_update_hit        (bank_update_hit),
    .bank_update_way        (bank_update_way),
    .bank_update_access     (bank_update_access),
    .bank_write_pc          (bank_write_pc),
    .bank_write_valid       (bank_write_valid),
    .bank_write_entry       (bank_write_entry),
    .bank_write_tag         (bank_write_tag),
    .bank_write_way         (bank_write_way),
    .bank_write_alloc       (bank_write_alloc),
    .u_valid                (u_valid),
    .delay2_pc              (delay2_pc),
    .update_entry           (update_entry),
    .delay2_entry           (delay2_entry),
    .write_valid_delay_in   (write_valid_delay_in),
    .write_valid_delay_out  (write_valid_delay_out)
  );

  // ---- 子模块：FTBBank（512 组 x 4 路 SRAM + tag 比较 + PLRU 替换，已签核）----
  FTBBank ftbBank (
    .clock                                                (clock),
    .reset                                                (reset),
    .io_s1_fire                                           (s1_fire[0]),
    .io_req_pc_ready                                      (bank_req_ready),
    .io_req_pc_valid                                      (bank_req_valid),
    .io_req_pc_bits                                       (io_in_bits_s0_pc_0),
    .io_read_resp_isCall                                  (bank_read_entry.isCall),
    .io_read_resp_isRet                                   (bank_read_entry.isRet),
    .io_read_resp_isJalr                                  (bank_read_entry.isJalr),
    .io_read_resp_valid                                   (bank_read_entry.valid),
    .io_read_resp_brSlots_0_offset                        (bank_read_entry.brSlot.offset),
    .io_read_resp_brSlots_0_sharing                       (bank_read_entry.brSlot.sharing),
    .io_read_resp_brSlots_0_valid                         (bank_read_entry.brSlot.valid),
    .io_read_resp_brSlots_0_lower                         (bank_read_entry.brSlot.lower),
    .io_read_resp_brSlots_0_tarStat                       (bank_read_entry.brSlot.tarStat),
    .io_read_resp_tailSlot_offset                         (bank_read_entry.tailSlot.offset),
    .io_read_resp_tailSlot_sharing                        (bank_read_entry.tailSlot.sharing),
    .io_read_resp_tailSlot_valid                          (bank_read_entry.tailSlot.valid),
    .io_read_resp_tailSlot_lower                          (bank_read_entry.tailSlot.lower),
    .io_read_resp_tailSlot_tarStat                        (bank_read_entry.tailSlot.tarStat),
    .io_read_resp_pftAddr                                 (bank_read_entry.pftAddr),
    .io_read_resp_carry                                   (bank_read_entry.carry),
    .io_read_resp_last_may_be_rvi_call                    (bank_read_entry.last_may_be_rvi_call),
    .io_read_resp_strong_bias_0                           (bank_read_entry.strong_bias[0]),
    .io_read_resp_strong_bias_1                           (bank_read_entry.strong_bias[1]),
    .io_read_hits_valid                                   (bank_read_hit),
    .io_read_hits_bits                                    (bank_read_way),
    .io_read_multi_entry_isCall                           (bank_multi_entry.isCall),
    .io_read_multi_entry_isRet                            (bank_multi_entry.isRet),
    .io_read_multi_entry_isJalr                           (bank_multi_entry.isJalr),
    .io_read_multi_entry_valid                            (bank_multi_entry.valid),
    .io_read_multi_entry_brSlots_0_offset                 (bank_multi_entry.brSlot.offset),
    .io_read_multi_entry_brSlots_0_sharing                (bank_multi_entry.brSlot.sharing),
    .io_read_multi_entry_brSlots_0_valid                  (bank_multi_entry.brSlot.valid),
    .io_read_multi_entry_brSlots_0_lower                  (bank_multi_entry.brSlot.lower),
    .io_read_multi_entry_brSlots_0_tarStat                (bank_multi_entry.brSlot.tarStat),
    .io_read_multi_entry_tailSlot_offset                  (bank_multi_entry.tailSlot.offset),
    .io_read_multi_entry_tailSlot_sharing                 (bank_multi_entry.tailSlot.sharing),
    .io_read_multi_entry_tailSlot_valid                   (bank_multi_entry.tailSlot.valid),
    .io_read_multi_entry_tailSlot_lower                   (bank_multi_entry.tailSlot.lower),
    .io_read_multi_entry_tailSlot_tarStat                 (bank_multi_entry.tailSlot.tarStat),
    .io_read_multi_entry_pftAddr                          (bank_multi_entry.pftAddr),
    .io_read_multi_entry_carry                            (bank_multi_entry.carry),
    .io_read_multi_entry_last_may_be_rvi_call             (bank_multi_entry.last_may_be_rvi_call),
    .io_read_multi_entry_strong_bias_0                    (bank_multi_entry.strong_bias[0]),
    .io_read_multi_entry_strong_bias_1                    (bank_multi_entry.strong_bias[1]),
    .io_read_multi_hits_valid                             (bank_multi_hit),
    .io_read_multi_hits_bits                              (bank_multi_way),
    .io_u_req_pc_valid                                    (bank_u_req_valid),
    .io_u_req_pc_bits                                     (io_update_bits_pc),
    .io_update_hits_valid                                 (bank_update_hit),
    .io_update_hits_bits                                  (bank_update_way),
    .io_update_access                                     (bank_update_access),
    .io_update_pc                                         (bank_write_pc),
    .io_update_write_data_valid                           (bank_write_valid),
    .io_update_write_data_bits_entry_isCall               (bank_write_entry.isCall),
    .io_update_write_data_bits_entry_isRet                (bank_write_entry.isRet),
    .io_update_write_data_bits_entry_isJalr               (bank_write_entry.isJalr),
    .io_update_write_data_bits_entry_valid                (bank_write_entry.valid),
    .io_update_write_data_bits_entry_brSlots_0_offset     (bank_write_entry.brSlot.offset),
    .io_update_write_data_bits_entry_brSlots_0_sharing    (bank_write_entry.brSlot.sharing),
    .io_update_write_data_bits_entry_brSlots_0_valid      (bank_write_entry.brSlot.valid),
    .io_update_write_data_bits_entry_brSlots_0_lower      (bank_write_entry.brSlot.lower),
    .io_update_write_data_bits_entry_brSlots_0_tarStat    (bank_write_entry.brSlot.tarStat),
    .io_update_write_data_bits_entry_tailSlot_offset      (bank_write_entry.tailSlot.offset),
    .io_update_write_data_bits_entry_tailSlot_sharing     (bank_write_entry.tailSlot.sharing),
    .io_update_write_data_bits_entry_tailSlot_valid       (bank_write_entry.tailSlot.valid),
    .io_update_write_data_bits_entry_tailSlot_lower       (bank_write_entry.tailSlot.lower),
    .io_update_write_data_bits_entry_tailSlot_tarStat     (bank_write_entry.tailSlot.tarStat),
    .io_update_write_data_bits_entry_pftAddr              (bank_write_entry.pftAddr),
    .io_update_write_data_bits_entry_carry                (bank_write_entry.carry),
    .io_update_write_data_bits_entry_last_may_be_rvi_call (bank_write_entry.last_may_be_rvi_call),
    .io_update_write_data_bits_entry_strong_bias_0        (bank_write_entry.strong_bias[0]),
    .io_update_write_data_bits_entry_strong_bias_1        (bank_write_entry.strong_bias[1]),
    .io_update_write_data_bits_tag                        (bank_write_tag),
    .io_update_write_way                                  (bank_write_way),
    .io_update_write_alloc                                (bank_write_alloc),
    .boreChildrenBd_bore_array                            (boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all                              (boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req                              (boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack                              (boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen                          (boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be                               (boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr                             (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata                           (boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen                           (boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd                          (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata                          (boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold                           (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass                         (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken                       (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk                        (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp                       (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold                       (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen                               (sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold                         (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass                       (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken                     (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk                      (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp                     (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold                     (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                             (sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold                         (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass                       (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken                     (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk                      (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp                     (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold                     (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen                             (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold                         (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass                       (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken                     (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk                      (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp                     (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold                     (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen                             (sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold                         (sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass                       (sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken                     (sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk                      (sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp                     (sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold                     (sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen                             (sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold                         (sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass                       (sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken                     (sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk                      (sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp                     (sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold                     (sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen                             (sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold                         (sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass                       (sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken                     (sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk                      (sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp                     (sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold                     (sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen                             (sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold                         (sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass                       (sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken                     (sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk                      (sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp                     (sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold                     (sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen                             (sigFromSrams_bore_7_cgen)
  );

  // ---- 子模块：update pc / 条目 / "需写"标志各打两拍（已签核延迟件）----
  DelayNWithValid delay2_pc_pipMod (
    .clock       (clock),
    .reset       (reset),
    .io_in_bits  (io_update_bits_pc),
    .io_in_valid (u_valid),
    .io_out_bits (delay2_pc)
  );

  DelayNWithValid_1 delay2_entry_pipMod (
    .clock                            (clock),
    .reset                            (reset),
    .io_in_bits_isCall                (update_entry.isCall),
    .io_in_bits_isRet                 (update_entry.isRet),
    .io_in_bits_isJalr                (update_entry.isJalr),
    .io_in_bits_valid                 (update_entry.valid),
    .io_in_bits_brSlots_0_offset      (update_entry.brSlot.offset),
    .io_in_bits_brSlots_0_sharing     (update_entry.brSlot.sharing),
    .io_in_bits_brSlots_0_valid       (update_entry.brSlot.valid),
    .io_in_bits_brSlots_0_lower       (update_entry.brSlot.lower),
    .io_in_bits_brSlots_0_tarStat     (update_entry.brSlot.tarStat),
    .io_in_bits_tailSlot_offset       (update_entry.tailSlot.offset),
    .io_in_bits_tailSlot_sharing      (update_entry.tailSlot.sharing),
    .io_in_bits_tailSlot_valid        (update_entry.tailSlot.valid),
    .io_in_bits_tailSlot_lower        (update_entry.tailSlot.lower),
    .io_in_bits_tailSlot_tarStat      (update_entry.tailSlot.tarStat),
    .io_in_bits_pftAddr               (update_entry.pftAddr),
    .io_in_bits_carry                 (update_entry.carry),
    .io_in_bits_last_may_be_rvi_call  (update_entry.last_may_be_rvi_call),
    .io_in_bits_strong_bias_0         (update_entry.strong_bias[0]),
    .io_in_bits_strong_bias_1         (update_entry.strong_bias[1]),
    .io_in_valid                      (u_valid),
    .io_out_bits_isCall               (delay2_entry.isCall),
    .io_out_bits_isRet                (delay2_entry.isRet),
    .io_out_bits_isJalr               (delay2_entry.isJalr),
    .io_out_bits_valid                (delay2_entry.valid),
    .io_out_bits_brSlots_0_offset     (delay2_entry.brSlot.offset),
    .io_out_bits_brSlots_0_sharing    (delay2_entry.brSlot.sharing),
    .io_out_bits_brSlots_0_valid      (delay2_entry.brSlot.valid),
    .io_out_bits_brSlots_0_lower      (delay2_entry.brSlot.lower),
    .io_out_bits_brSlots_0_tarStat    (delay2_entry.brSlot.tarStat),
    .io_out_bits_tailSlot_offset      (delay2_entry.tailSlot.offset),
    .io_out_bits_tailSlot_sharing     (delay2_entry.tailSlot.sharing),
    .io_out_bits_tailSlot_valid       (delay2_entry.tailSlot.valid),
    .io_out_bits_tailSlot_lower       (delay2_entry.tailSlot.lower),
    .io_out_bits_tailSlot_tarStat     (delay2_entry.tailSlot.tarStat),
    .io_out_bits_pftAddr              (delay2_entry.pftAddr),
    .io_out_bits_carry                (delay2_entry.carry),
    .io_out_bits_last_may_be_rvi_call (delay2_entry.last_may_be_rvi_call),
    .io_out_bits_strong_bias_0        (delay2_entry.strong_bias[0]),
    .io_out_bits_strong_bias_1        (delay2_entry.strong_bias[1])
  );

  DelayN_1 write_valid_delay (
    .clock  (clock),
    .io_in  (write_valid_delay_in),
    .io_out (write_valid_delay_out)
  );

endmodule
// END GENERATED(FTB)
