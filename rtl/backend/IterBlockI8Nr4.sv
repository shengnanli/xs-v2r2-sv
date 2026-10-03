// =============================================================================
// IterBlockI8Nr4 —— 8 位非恢复（non-restoring）除法迭代块（I8DivNr4 使用）
//
// 每拍消耗余数低位部分 pre_w_low 的 2 位、产出 2 个商数位：余数非负（符号位 0）
//   商 1。pre_w 是部分余数的高 9 位（带符号），pre_w_low 是低 8 位。
// 机制：第一档把 w 左移 1 位、补入 w_low[7]，与 divisor_cons[上拍符号+1]
//   （非负取 1 号、负取 2 号；golden 写法是 2'({1'h0, pre_w[8]} + 2'h1)，
//   2 位回绕后恰为 {1,2}）试加得 trial_rem；第二档再左移 1 位（累计 2 位），
//   按 {上拍符号, trial 符号} 四选一 divisor_cons 得新余数。
//   所有加法均为 9 位回绕（golden 的 9'(...)）。
// divisor_cons 是 I8DivNr4 预存的四个除数倍数档，本块只做选择，不解释其语义。
// 结构：golden 端口 -> xs_IterBlockI8Nr4_core（可读核）-> 直接出。纯组合。
// 自动生成：scripts/gen_srt_divsqrt_leaves10.py —— 勿手改
// =============================================================================

module xs_IterBlockI8Nr4_core (
  input  logic [8:0] divisor_cons [0:3],
  input  logic [8:0] pre_w,
  input  logic [7:0] pre_w_low,
  output logic [8:0] nxt_w,
  output logic [7:0] nxt_w_low,
  input  logic [7:0] pre_q,
  output logic [7:0] nxt_q
);
  // 第一档试加：w 左移 1 位补入 w_low[7]；倍数由上拍余数符号选择
  logic [1:0] trial_sel;
  logic [8:0] w_shift1, trial_rem;
  assign trial_sel = {1'b0, pre_w[8]} + 2'd1;
  assign w_shift1  = {pre_w[7:0], pre_w_low[7]};
  assign trial_rem = divisor_cons[trial_sel] + w_shift1;  // 9 位回绕

  // 第二档：累计左移 2 位，按 {上拍符号, trial 符号} 选倍数
  logic [1:0] next_sel;
  logic [8:0] w_shift2;
  assign next_sel = {pre_w[8], trial_rem[8]};
  assign w_shift2 = {pre_w[6:0], pre_w_low[7:6]};

  always_comb begin
    case (next_sel)
      2'b00:   nxt_w = divisor_cons[0] + w_shift2;
      2'b01:   nxt_w = divisor_cons[1] + w_shift2;
      2'b10:   nxt_w = divisor_cons[2] + w_shift2;
      default: nxt_w = divisor_cons[3] + w_shift2;
    endcase
  end

  // 两个商数位：余数非负（符号位 0）则商 1；低位部分左移 2 位出
  assign nxt_q     = {pre_q[5:0], ~trial_rem[8], ~nxt_w[8]};
  assign nxt_w_low = {pre_w_low[5:0], 2'b00};
endmodule

module IterBlockI8Nr4 (
  input  logic [8:0] io_d_cons_0,
  input  logic [8:0] io_d_cons_1,
  input  logic [8:0] io_d_cons_2,
  input  logic [8:0] io_d_cons_3,
  input  logic [8:0] io_pre_w,
  input  logic [7:0] io_pre_w_low,
  output logic [8:0] io_nxt_w,
  output logic [7:0] io_nxt_w_low,
  input  logic [7:0] io_pre_q,
  output logic [7:0] io_nxt_q
);
  logic [8:0] divisor_cons [0:3];

  assign divisor_cons[0] = io_d_cons_0;
  assign divisor_cons[1] = io_d_cons_1;
  assign divisor_cons[2] = io_d_cons_2;
  assign divisor_cons[3] = io_d_cons_3;

  xs_IterBlockI8Nr4_core u_core (
    .divisor_cons (divisor_cons),
    .pre_w        (io_pre_w),
    .pre_w_low    (io_pre_w_low),
    .nxt_w        (io_nxt_w),
    .nxt_w_low    (io_nxt_w_low),
    .pre_q        (io_pre_q),
    .nxt_q        (io_nxt_q)
  );
endmodule
