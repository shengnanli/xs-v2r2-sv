// =============================================================================
// xs_FastArbiter_core —— 带「挂起记忆」的 N 路轮转仲裁器（FastArbiter 家族的参数化核）
//
// 对应 Chisel: utility.FastArbiter(gen, n)（utility/FastArbiter.scala）。
// 与普通 RRArbiter 的区别：它不只记"上一个赢家是谁"，还记"上一拍被晾着的有谁"。
// 每次握手成功（out.fire）锁存两张掩码：
//   pendingMask  = 本拍 valid 却没被选中的那些路（"欠着的"）；
//   rrGrantMask  = 赢家**以上**的所有位置（下一轮从赢家的下一位开始找）。
// 下一拍先在 "欠着的 ∩ 赢家以上" 里挑最低位（rrSelOH）；若它此刻仍 valid 就给它，
// 否则退回"当前 valid 里最低的那一路"（firstOneOH，固定优先级兜底）。
//
//   例：rrGrantMask 第 i 位 = "chosenOH[i-1:0] 里有 1"，即赢家**以上**的位置。
//   4 路时 chosenOH=0100 ⇒ rrGrantMask=1000。Scala 源码注释写的是 0011，与它自己的
//   代码不符（那是"赢家以下"）；这里以代码 / golden 为准。
//
// ★两个结构性恒值（照抄，不许"优化"掉）★
//   · rrGrantMask[0] 恒 0：没有比第 0 路更低的位置，Scala 里直接写 false.B。
//     golden 仍保留这一位寄存器（复位 0、写入 0），FM 里是 Constant reg。
//   · 因而 pendingMask[0] 永远不被读（rrSelOH[0] = rrGrantMask[0] & pendingMask[0] ≡ 0）。
//     它是两侧对称的结构死位，FM 里走 vmucp（verify_matched_unread）实开比较。
//   两者都照 golden 位宽保留 N 位 —— 收窄就会变成 golden 独有的死位，反而证不了。
//
// 握手：in_ready[i] = chosenOH[i] & out_ready；out_valid = |in_valid（与 ready 无关）。
// 载荷：Mux1H(chosenOH, in_bits) —— 按位或归约（chosenOH 必为 one-hot 或全 0，
//   全 0 时输出全 0；golden 也是按位或，不是优先级选择）。
//   因此"所有路都喂同一个常量 K"的字段，输出等于 K & {W{|chosenOH}}：
//   golden 里那些没有输入端口的常量输出字段（如 TXREQ 的 size=6）就是这样来的，
//   变体薄文件把常量喂进每一路，核不需要特判。
// 复位：两张掩码都是**异步**复位到 0（golden `always @(posedge clock or posedge reset)`）。
// =============================================================================
module xs_FastArbiter_core #(
  parameter int unsigned N = 16,   // 输入路数
  parameter int unsigned W = 1     // 载荷打平后的位宽
)(
  input  logic                clock,
  input  logic                reset,
  input  logic [N-1:0]        in_valid,
  input  logic [N-1:0][W-1:0] in_bits,
  output logic [N-1:0]        in_ready,
  input  logic                out_ready,
  output logic                out_valid,
  output logic [W-1:0]        out_bits
);

  // ---------------------------------------------------------------------------
  // 1. 选择：先轮转（欠着的 ∩ 赢家以上，取最低位），不中再固定优先级（valid 里最低位）
  // ---------------------------------------------------------------------------
  logic [N-1:0] pendingMask;   // 上次握手时 valid 却落选的路
  logic [N-1:0] rrGrantMask;   // 上次赢家以上的位置；[0] 恒 0
  logic [N-1:0] rrCandidates;  // = rrGrantMask & pendingMask
  logic [N-1:0] rrSelOH;       // rrCandidates 的最低位（one-hot）
  logic [N-1:0] firstOneOH;    // in_valid 的最低位（one-hot）
  logic         rrValid;       // 轮转候选此刻仍 valid
  logic [N-1:0] chosenOH;      // 最终赢家（one-hot，或无人 valid 时全 0）

  assign rrCandidates = rrGrantMask & pendingMask;

  // MaskToOH：保留最低的那个 1。逐位写成"我是 1 且比我低的全是 0"。
  always_comb begin
    logic lower_rr, lower_valid;
    lower_rr    = 1'b0;
    lower_valid = 1'b0;
    for (int i = 0; i < N; i++) begin
      rrSelOH[i]    = rrCandidates[i] & ~lower_rr;
      firstOneOH[i] = in_valid[i]     & ~lower_valid;
      lower_rr      = lower_rr    | rrCandidates[i];
      lower_valid   = lower_valid | in_valid[i];
    end
  end

  assign rrValid  = |(rrSelOH & in_valid);
  assign chosenOH = rrValid ? rrSelOH : firstOneOH;

  // ---------------------------------------------------------------------------
  // 2. 握手与载荷
  // ---------------------------------------------------------------------------
  logic out_fire;
  assign out_valid = |in_valid;
  assign out_fire  = out_ready & out_valid;
  assign in_ready  = chosenOH & {N{out_ready}};

  always_comb begin
    out_bits = '0;
    for (int i = 0; i < N; i++)
      out_bits = out_bits | (chosenOH[i] ? in_bits[i] : '0);
  end

  // ---------------------------------------------------------------------------
  // 3. 状态更新：只在握手成功那拍锁存（RegEnable），异步复位到 0
  // ---------------------------------------------------------------------------
  logic [N-1:0] above_winner;  // above_winner[i] = chosenOH[i-1:0] 里有 1
  always_comb begin
    above_winner[0] = 1'b0;
    for (int i = 1; i < N; i++)
      above_winner[i] = above_winner[i-1] | chosenOH[i-1];
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      pendingMask <= '0;
      rrGrantMask <= '0;
    end
    else if (out_fire) begin
      pendingMask <= in_valid & ~chosenOH;
      rrGrantMask <= above_winner;
    end
  end

endmodule
