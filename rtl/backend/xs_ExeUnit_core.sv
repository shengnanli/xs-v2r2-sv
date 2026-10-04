// =============================================================================
// xs_ExeUnit_core —— 执行单元（ExeUnit）外壳的控制核：发射口握手、功能单元时钟门控、
//                    控制字段延迟流水（带冲刷）、不定延迟单元的 busy、写回有效
// -----------------------------------------------------------------------------
// 设计源：src/main/scala/xiangshan/backend/exu/ExeUnit.scala（class ExeUnitImp）。
// 在哪一层：每个 ExeUnit_<k> 是一组功能单元（FU）的外壳 ——
//     io.in ──► Dispatcher（按 fuType 选一个 FU）──► FU_0 … FU_{N-1} ──► 写回 Mux1H ──► io.out
//   FU 与 Dispatcher 的例化、端口连线在各变体的 wrapper（ExeUnit_<k>.sv，由
//   scripts/gen_exeunit.py 从 golden 机械生成）里；本核是这些外壳**共有的那部分逻辑**，
//   七个变体只差参数（FU 个数 / 各 FU 延迟 / 哪些控制字段要打几拍 …）。
//
// 本核做五件事（各节开头有细节）：
//   §1 发射口握手：busy（只有含不定延迟 FU 的外壳才有）拦住新指令；
//   §2 控制字段延迟流水 inPipe：把 robIdx / pdest / 写使能 … 按「最晚一个读它的 FU 的
//      流水级」逐级打拍，供定延迟 FU 在写回级取用（FU 自己不打这些拍）；每一级随
//      robIdx 判冲刷，被冲刷的指令在下一级失效；
//   §3 每个 FU 的时钟门控使能（EnableClockGate）：只在 FU 里还有活时打开时钟；
//   §4 第 2 拍起的 instrAddrTransType 打一拍（BranchUnit / JumpUnit 用）；
//   §5 写回有效 = 任一 FU 写回有效（FU 写回按构造 one-hot）。
//   写回数据的选择（Mux1H）在同文件的 xs_ExeUnit_wbsel 里，由 wrapper 按字段分组例化。
//
// 参数怎么来：全部由 scripts/gen_exeunit.py 从 golden 解析（fail-closed：golden 里每个外壳
//   寄存器都必须能对上本核按参数会生成的那一个，多一个少一个都拒绝生成）。
//
// ★两个容易看错的地方★
//   (a) inPipe 的字段集合每级不同：firtool 删掉了没人读的寄存器。Scala 里每级都是整份
//       ExuInput，这里按「字段 f 保留到第 FIELD_DEPTH[f] 级」只生成真被读到的那些位 ——
//       字段 f 在第 s 级要存，当且仅当某个 FU 读 ctrlPipe(s).f，或第 s+1 级还要它
//       （robIdx 另有一条：第 s < LAT_MAX 级的 robIdx 要拿来判下一级的冲刷）。
//   (b) 时钟门控的 valid 链（§3）与 inPipe 的 valid 链（§2）是两条独立的链：前者跟着
//       FU 的 ready 走（会被反压冻住），后者每拍无条件前移只看冲刷。照 golden。
// 复位：§1 busy、§2 valid 链、§3 门控链异步复位；其余（字段流水、rob 快照、§4）不复位。
// =============================================================================

module xs_ExeUnit_core #(
  parameter int N_FU                     = 1,          // 本外壳的 FU 个数（= Dispatcher 出口数）
  parameter int FU_LAT       [N_FU]      = '{default: 0}, // 各 FU 的确定延迟（0 = 组合）
  parameter bit FU_UNCERTAIN [N_FU]      = '{default: 0}, // 各 FU 是否不定延迟（FDivSqrt）
  parameter bit HAS_BUSY                 = 1'b0,       // 外壳整体延迟不确定 ⇒ 有 busy
  parameter int LAT_MAX                  = 0,          // inPipe 级数 = 各 FU 延迟的最大值
  parameter int NF                       = 1,          // inPipe 字段数；字段 0 固定是 robIdx
  parameter int FIELD_W      [NF]        = '{9},       // 各字段位宽（robIdx = {flag, value[7:0]}）
  parameter int FIELD_DEPTH  [NF]        = '{0},       // 各字段保留到第几级（0 = 不打拍）
  parameter int PAY_W                    = 9,          // = ΣFIELD_W
  parameter int N_ATT                    = 0           // 要各自打一拍 instrAddrTransType 的 FU 数
) (
  input  logic                      clock,
  input  logic                      reset,

  // ---- 冲刷（Redirect）------------------------------------------------------
  input  logic                      flush_valid,
  input  logic                      flush_rob_flag,
  input  logic [7:0]                flush_rob_value,
  input  logic                      flush_level,     // 1 = 连自己一起冲（flushItself）

  // ---- 发射口 / Dispatcher 入口 ---------------------------------------------
  input  logic                      in_valid,
  output logic                      in_ready,
  input  logic [PAY_W-1:0]          in_payload,      // 第 0 级字段（[8:0] = robIdx）
  output logic                      disp_in_valid,
  input  logic                      disp_in_ready,

  // ---- inPipe：第 s 级的 valid 与字段（s = 0 即本拍输入）---------------------
  output logic [LAT_MAX:0]           pipe_valid,
  output logic [LAT_MAX:0][PAY_W-1:0] pipe_data,

  // ---- 各 FU 的握手观测与时钟使能 -------------------------------------------
  input  logic [N_FU-1:0]           fu_in_valid,     // Dispatcher 出口 valid
  input  logic [N_FU-1:0]           fu_in_ready,     // FU 的 in.ready
  input  logic [N_FU-1:0]           fu_out_valid,    // FU 的 out.valid
  input  logic                      out_ready,       // 外壳 io.out.ready（同时就是各 FU 的 out.ready）
  output logic [N_FU-1:0]           fu_clk_en,       // 送 ClockGate.E（只对有门控的 FU 有意义）

  // ---- instrAddrTransType 打一拍 --------------------------------------------
  input  logic [4:0]                att_in,          // {sv48x4, sv48, sv39x4, sv39, bare}
  output logic [(N_ATT > 0 ? N_ATT : 1)-1:0][4:0] att_q,

  // ---- 写回有效 -------------------------------------------------------------
  output logic                      out_valid
);

  // 字段 f 在 payload 里的最低位 = 前面各字段位宽之和
  function automatic int field_lo(input int f);
    int lo = 0;
    for (int k = 0; k < f; k++) lo += FIELD_W[k];
    return lo;
  endfunction

  // Redirect.needFlush：flush 有效，且（level=flushItself 时同一条也冲，或本条比 flush 那条更年轻）。
  // isAfter(a, b) = a.flag ^ b.flag ^ (a.value > b.value)：环形 ROB 指针的「更年轻」。
  // （flush 作为参数传入：函数里不许读模块级信号，FM 会判 FMR_VLOG-091 并拒绝建模）
  function automatic logic need_flush(input logic [8:0] rob,
                                      input logic       f_valid,
                                      input logic [8:0] f_rob,
                                      input logic       f_level);
    logic same, after;
    same  = (rob == f_rob);
    after = rob[8] ^ f_rob[8] ^ (rob[7:0] > f_rob[7:0]);
    return f_valid & ((f_level & same) | after);
  endfunction

  logic [8:0] flush_rob;
  assign flush_rob = {flush_rob_flag, flush_rob_value};

  // ===========================================================================
  // §1 发射口握手与 busy
  // ===========================================================================
  // 含不定延迟 FU（FDivSqrt）的外壳一次只放一条进去：收下后 busy=1，直到写回、或这条被
  // 冲刷（收下的同一拍就判冲刷，也用快照的 robIdx 在之后每拍判）。其余外壳 busy 恒 0。
  logic busy;
  logic in_fire;
  assign in_ready      = ~busy & disp_in_ready;
  assign disp_in_valid = in_valid & ~busy;
  assign in_fire       = in_ready & in_valid;

  generate
    if (HAS_BUSY) begin : g_busy
      logic [8:0] rob_q;          // 在途那条的 robIdx（in.fire 时快照）
      logic       busy_q;
      logic       in_flushed, rob_flushed;
      assign in_flushed  = need_flush(in_payload[8:0], flush_valid, flush_rob, flush_level);
      assign rob_flushed = need_flush(rob_q,           flush_valid, flush_rob, flush_level);

      always_ff @(posedge clock) begin
        if (in_fire) rob_q <= in_payload[8:0];
      end

      always_ff @(posedge clock or posedge reset) begin
        if (reset)
          busy_q <= 1'b0;
        else if (in_fire & in_flushed)   busy_q <= 1'b0;   // 刚收下就被冲
        else if (busy_q & rob_flushed)   busy_q <= 1'b0;   // 在途时被冲
        else if (out_ready & out_valid)  busy_q <= 1'b0;   // 写回完成
        else if (in_fire)                busy_q <= 1'b1;   // 收下新指令
      end
      assign busy = busy_q;
    end else begin : g_nobusy
      assign busy = 1'b0;
    end
  endgenerate

  // ===========================================================================
  // §2 控制字段延迟流水 inPipe（valid 链带冲刷 + 各字段移位寄存器）
  // ===========================================================================
  // 第 0 级 = 本拍输入。第 s 级 valid = 第 s-1 级 valid 且第 s-1 级那条没被冲刷；
  // 字段寄存器无使能（每拍跟着前移），valid 决定它是否算数。
  assign pipe_valid[0] = in_valid;
  assign pipe_data[0]  = in_payload;

  generate
    if (LAT_MAX > 0) begin : g_pipe
      logic [LAT_MAX:1] stage_valid_q;

      always_ff @(posedge clock or posedge reset) begin
        if (reset)
          stage_valid_q <= '0;
        else
          for (int s = 1; s <= LAT_MAX; s++)
            stage_valid_q[s] <= pipe_valid[s-1]
                              & ~need_flush(pipe_data[s-1][8:0], flush_valid, flush_rob, flush_level);
      end

      for (genvar s = 1; s <= LAT_MAX; s++) begin : g_stage_valid
        assign pipe_valid[s] = stage_valid_q[s];
      end

      // 每个字段一条移位寄存器，深度 = 该字段保留到的级数 D（只生成真被读到的那些位）
      for (genvar f = 0; f < NF; f++) begin : g_fld
        localparam int LO = field_lo(f);
        localparam int W  = FIELD_W[f];
        localparam int D  = FIELD_DEPTH[f];

        if (D > 0) begin : g_reg
          logic [W-1:0] q [1:D];
          always_ff @(posedge clock) begin
            q[1] <= in_payload[LO +: W];
            for (int s = 2; s <= D; s++) q[s] <= q[s-1];
          end
          for (genvar s = 1; s <= D; s++) begin : g_out
            assign pipe_data[s][LO +: W] = q[s];
          end
        end

        // 超过保留深度的级：没有 FU 读，给 0（不是寄存器）
        for (genvar s = D + 1; s <= LAT_MAX; s++) begin : g_dropped
          assign pipe_data[s][LO +: W] = '0;
        end
      end
    end
  endgenerate

  // ===========================================================================
  // §3 FU 时钟门控使能（ExeUnit.scala 的 EnableClockGate 段）
  // ===========================================================================
  // 三种 FU：
  //   · 确定延迟 L>0：自带一条跟 FU 流水同步的 valid 链 vld[1..L]（第 0 级 = FU 的 in.valid），
  //     随 FU 的 ready 反压前移；链上任一级有活、或上一拍有活，就开时钟（多开一拍收尾）；
  //   · 不定延迟：in.fire 置位、out.fire 清零的一个标志，有标志或本拍 in.fire 就开；
  //   · 延迟 0：没有 ClockGate；这里给的 in.fire 只是 golden 同名探针，没有寄存器。
  logic [N_FU-1:0] fu_in_fire;
  assign fu_in_fire = fu_in_ready & fu_in_valid;

  for (genvar i = 0; i < N_FU; i++) begin : g_fu
    localparam int L = FU_LAT[i];

    if (L > 0) begin : g_lat
      logic [L:1] vld_q;       // fuVldVec(1..L)：FU 流水第 s 级有活
      logic       en_q;        // fuVld_en_reg：上一拍链上有活
      logic [L:0] vld;         // [0] = FU 的 in.valid
      logic [L:0] rdy;         // rdy[s] = 第 s 级能前移

      // 下一级空着、或下一级自己能前移，本级就能前移；最后一级看外壳的 out.ready
      always_comb begin
        vld = {vld_q, fu_in_valid[i]};
        rdy[L] = out_ready;
        for (int s = L - 1; s >= 0; s--) rdy[s] = ~vld[s+1] | rdy[s+1];
      end

      always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
          vld_q <= '0;
          en_q  <= 1'b0;
        end else begin
          for (int s = 1; s <= L; s++) begin
            if (rdy[s-1] & vld[s-1]) vld_q[s] <= vld[s-1];   // 前移
            else if (rdy[s])         vld_q[s] <= 1'b0;       // 被下一级取走
          end
          en_q <= |vld;
        end
      end

      assign fu_clk_en[i] = (|vld) | en_q;

    end else if (FU_UNCERTAIN[i]) begin : g_unc
      logic uncer_q;           // uncer_en_reg：已收下、还没写回

      always_ff @(posedge clock or posedge reset) begin
        if (reset)                              uncer_q <= 1'b0;
        else if (fu_in_fire[i])                 uncer_q <= 1'b1;
        else if (out_ready & fu_out_valid[i])   uncer_q <= 1'b0;
      end

      assign fu_clk_en[i] = fu_in_fire[i] | uncer_q;

    end else begin : g_lat0
      assign fu_clk_en[i] = fu_in_fire[i];       // 探针：延迟 0 的 FU 不门控
    end
  end

  // ===========================================================================
  // §4 instrAddrTransType 打一拍（RegNext，每个用到它的 FU 各一份，不复位）
  // ===========================================================================
  generate
    if (N_ATT > 0) begin : g_att
      always_ff @(posedge clock) begin
        for (int k = 0; k < N_ATT; k++) att_q[k] <= att_in;
      end
    end else begin : g_noatt
      assign att_q = '0;
    end
  endgenerate

  // ===========================================================================
  // §5 写回有效
  // ===========================================================================
  assign out_valid = |fu_out_valid;

endmodule

// =============================================================================
// xs_ExeUnit_wbsel —— 写回字段选择（Chisel Mux1H）
// -----------------------------------------------------------------------------
// 一组「由同一批 FU 产出」的写回字段拼成 W 位，按各 FU 的 out.valid 选一个：
//   out = Σ(sel[i] ? data[i] : 0)（按位或）。FU 的写回 valid 按构造 one-hot（ExeUnit 里有
//   XSError 断言），所以按位或就是选择。只有一个 FU 产出、但 Scala 是在全部 FU 上做 Mux1H、
//   其余 FU 给常 0 的字段（如 vecWen）也走这里（N=1，仍与 valid 相与）。
// 另一种「单元素」：Scala 先按写回类型过滤 FU、过滤后只剩一个（如向量写回数据只来自
//   i2v / f2v），Chisel 的 Mux1H 对单元素列表直接返回该元素、**不与 valid 相与** ——
//   那种字段 wrapper 直接连线，不经过本模块。
// =============================================================================
module xs_ExeUnit_wbsel #(
  parameter int N = 1,
  parameter int W = 1
) (
  input  logic [N-1:0]        sel,
  input  logic [N-1:0][W-1:0] data,
  output logic [W-1:0]        out
);

  always_comb begin
    out = '0;
    for (int i = 0; i < N; i++) out |= sel[i] ? data[i] : '0;
  end

endmodule
