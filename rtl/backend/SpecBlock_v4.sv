// =============================================================================
// SpecBlock_v4.sv —— SRT radix-16 整数除法：「第二个商位」的投机（speculative）选择块
//
// 在哪一层：VectorIdiv → SRT16Divint{,_4,_6} → IterBlock_v4{,_4,_6} → 本块（specB）。
//   每拍两个 radix-4 商位 q1、q2。q2 的选择要用「已经减掉 q1·d 的余数」，可 q1 在
//   本拍才由 SelBlock 定出来——串起来就太慢。办法是**投机**：上一拍就对 q1 的全部
//   5 种可能取值 u∈{+2,+1,0,-1,-2} 各算一套比较值（pre_spec[u]），本拍各自取符号、
//   各自经 SignDec 得到 5 个候选 q2，等 q1 一到，用 q1 独热一选即得 q2（io_q_j_2）。
//   本拍同时为**下一拍**的 q2 准备 5×4 对比较值 nxt_spec（下一拍的 q1 同样未知）。
//
// 每个候选 u 的比较值 = 余数估计 + (-u·d 的截断) + 比较常数[本拍 q2][k]：
//   - 「余数估计 + (-u·d)」先用一级 3:2 CSA 得 (sum, carry)，u=0 时不加，直接用估计；
//     io_d_trunc_0..3 依次是 u=+2,+1,-1,-2 的 -u·d 截断（u=0 无此项，故只有 4 个）；
//   - 再与「按本拍 q2 选出的常数」过第二级 3:2 CSA，得到 nxt_spec[u][k]。
//   比较常数 io_cons_<v>_<k> 同 SelBlock：v 为本拍 q2 的独热下标，k 为 4 条阈值。
// 商位编码（全族统一）：独热第 i 位代表商位 2-i（bit0=+2 … bit4=-2）。
//   因此投机候选的下标也按此排：nxt_spec[0]=u=+2 … nxt_spec[2]=u=0 … nxt_spec[4]=u=-2。
//   Scala 里先按 {+2,+1,-1,-2,0} 算 temp 再重排成上述顺序，本核直接按目标顺序写。
// 位宽：投机路径 9 位 = 3 位整数 + 6 位小数（Scala "spec 3+6"，比选择路径多 1 位小数，
//   因为它要再往前看一个商位）。carry 半边出 CSA 后左移 1 位、最高位丢弃（golden 同）。
//
// 子模块（两侧白盒，本仓已签核重写件）：CSA3_2_3992（9 位 3:2 CSA）×24、SignDec ×5。
// 纯组合：零寄存器、无 clock/reset。
// 设计源：yunsuan/src/main/scala/yunsuan/vector/VectorIdiv/SRT16Divint.scala (class SpecBlock_v4)
// golden 对照：G1-canonical/golden-rtl/SpecBlock_v4.sv
// wrapper 由 scripts/gen_srt_divblocks.py 生成（GENERATED 区），核为手写。
// =============================================================================

// -----------------------------------------------------------------------------
// xs_SpecBlock_v4_core —— 可读核（端口名沿用 Scala 的 io 字段名）
// -----------------------------------------------------------------------------
module xs_SpecBlock_v4_core (
  input  logic [4:0] q_j,                        // 本拍 q2（独热，选比较常数）
  input  logic [8:0] cons     [0:4][0:3],        // [q2 下标][阈值 k] 的比较常数
  input  logic [8:0] d_trunc  [0:3],             // u=+2,+1,-1,-2 时的 -u·d 截断
  input  logic [4:0] q_j_1,                      // 本拍 q1（独热，从 5 个候选里挑 q2）
  input  logic [8:0] rem_3_5  [0:1],             // 余数估计（[0]=sum, [1]=carry 已左移）
  output logic [4:0] q_j_2,                      // 本拍 q2
  input  logic [8:0] pre_spec [0:4][0:3][0:1],   // 上一拍的投机比较值 [u][k][sum/carry]
  output logic [8:0] nxt_spec [0:4][0:3][0:1]    // 留给下一拍的投机比较值
);

  // 候选 u（独热下标 0..4）对应哪一个 d_trunc；u=+0（下标 2）不加除数倍数。
  localparam int NO_D = -1;
  localparam int D_TRUNC_OF [0:4] = '{0, 1, NO_D, 2, 3};

  // ---------------------------------------------------------------------------
  // §1 按本拍 q2 选比较常数（Mux1H = 按位或，非独热时照 golden 叠加）
  // ---------------------------------------------------------------------------
  logic [8:0] cons_u [0:3];
  always_comb begin
    for (int k = 0; k < 4; k++) begin
      cons_u[k] = '0;
      for (int v = 0; v < 5; v++)
        if (q_j[v]) cons_u[k] = cons_u[k] | cons[v][k];
    end
  end

  // ---------------------------------------------------------------------------
  // §2 投机余数：对下一拍 q1 的 5 种可能 u，各得一份 carry-save 余数估计 cand[u]。
  //    u≠0：估计 + (-u·d) 过一级 CSA；u=0：估计原样。
  // ---------------------------------------------------------------------------
  logic [8:0] cand [0:4][0:1];      // [u][sum/carry]
  for (genvar u = 0; u < 5; u++) begin : g_cand
    if (D_TRUNC_OF[u] == NO_D) begin : g_zero
      assign cand[u][0] = rem_3_5[0];
      assign cand[u][1] = rem_3_5[1];
    end else begin : g_sub
      logic [8:0] carry;
      CSA3_2_3992 u_csa (
        .io_in_0  (rem_3_5[0]),
        .io_in_1  (rem_3_5[1]),
        .io_in_2  (d_trunc[D_TRUNC_OF[u]]),
        .io_out_0 (cand[u][0]),
        .io_out_1 (carry)
      );
      assign cand[u][1] = {carry[7:0], 1'b0};
    end
  end

  // ---------------------------------------------------------------------------
  // §3 为下一拍准备 5×4 对比较值：cand[u] 与 4 档常数各过一级 CSA
  // ---------------------------------------------------------------------------
  for (genvar u = 0; u < 5; u++) begin : g_spec
    for (genvar k = 0; k < 4; k++) begin : g_thresh
      logic [8:0] carry;
      CSA3_2_3992 u_csa (
        .io_in_0  (cand[u][0]),
        .io_in_1  (cand[u][1]),
        .io_in_2  (cons_u[k]),
        .io_out_0 (nxt_spec[u][k][0]),
        .io_out_1 (carry)
      );
      assign nxt_spec[u][k][1] = {carry[7:0], 1'b0};
    end
  end

  // ---------------------------------------------------------------------------
  // §4 本拍的 q2：上一拍的每份投机比较值做 9 位进位加法取符号位，每个候选 u
  //    得 4 个符号 → SignDec → 候选 q2；最后由本拍 q1 独热选（Mux1H = 按位或）。
  // ---------------------------------------------------------------------------
  logic [8:0] pre_sum [0:4][0:3];
  logic [3:0] sign    [0:4];
  logic [4:0] q2_cand [0:4];
  always_comb begin
    for (int u = 0; u < 5; u++)
      for (int k = 0; k < 4; k++) begin
        pre_sum[u][k] = pre_spec[u][k][0] + pre_spec[u][k][1];   // 9 位回绕
        sign[u][k]    = pre_sum[u][k][8];
      end
  end

  for (genvar u = 0; u < 5; u++) begin : g_dec
    SignDec u_sign_dec (
      .io_sign_0 (sign[u][0]),
      .io_sign_1 (sign[u][1]),
      .io_sign_2 (sign[u][2]),
      .io_sign_3 (sign[u][3]),
      .io_q      (q2_cand[u])
    );
  end

  always_comb begin
    q_j_2 = '0;
    for (int u = 0; u < 5; u++)
      if (q_j_1[u]) q_j_2 = q_j_2 | q2_cand[u];
  end
endmodule

// BEGIN GENERATED(specblock-wrapper)
// -----------------------------------------------------------------------------
// SpecBlock_v4 —— golden 同名 wrapper：端口表逐字取 golden，展平端口 <-> 核数组（机械生成）
// -----------------------------------------------------------------------------
module SpecBlock_v4(
  input  [4:0] io_q_j,
  input  [8:0] io_cons_0_0,
  input  [8:0] io_cons_0_1,
  input  [8:0] io_cons_0_2,
  input  [8:0] io_cons_0_3,
  input  [8:0] io_cons_1_0,
  input  [8:0] io_cons_1_1,
  input  [8:0] io_cons_1_2,
  input  [8:0] io_cons_1_3,
  input  [8:0] io_cons_2_0,
  input  [8:0] io_cons_2_1,
  input  [8:0] io_cons_2_2,
  input  [8:0] io_cons_2_3,
  input  [8:0] io_cons_3_0,
  input  [8:0] io_cons_3_1,
  input  [8:0] io_cons_3_2,
  input  [8:0] io_cons_3_3,
  input  [8:0] io_cons_4_0,
  input  [8:0] io_cons_4_1,
  input  [8:0] io_cons_4_2,
  input  [8:0] io_cons_4_3,
  input  [8:0] io_d_trunc_0,
  input  [8:0] io_d_trunc_1,
  input  [8:0] io_d_trunc_2,
  input  [8:0] io_d_trunc_3,
  input  [4:0] io_q_j_1,
  input  [8:0] io_rem_3_5_0,
  input  [8:0] io_rem_3_5_1,
  output [4:0] io_q_j_2,
  input  [8:0] io_pre_spec_0_0_0,
  input  [8:0] io_pre_spec_0_0_1,
  input  [8:0] io_pre_spec_0_1_0,
  input  [8:0] io_pre_spec_0_1_1,
  input  [8:0] io_pre_spec_0_2_0,
  input  [8:0] io_pre_spec_0_2_1,
  input  [8:0] io_pre_spec_0_3_0,
  input  [8:0] io_pre_spec_0_3_1,
  input  [8:0] io_pre_spec_1_0_0,
  input  [8:0] io_pre_spec_1_0_1,
  input  [8:0] io_pre_spec_1_1_0,
  input  [8:0] io_pre_spec_1_1_1,
  input  [8:0] io_pre_spec_1_2_0,
  input  [8:0] io_pre_spec_1_2_1,
  input  [8:0] io_pre_spec_1_3_0,
  input  [8:0] io_pre_spec_1_3_1,
  input  [8:0] io_pre_spec_2_0_0,
  input  [8:0] io_pre_spec_2_0_1,
  input  [8:0] io_pre_spec_2_1_0,
  input  [8:0] io_pre_spec_2_1_1,
  input  [8:0] io_pre_spec_2_2_0,
  input  [8:0] io_pre_spec_2_2_1,
  input  [8:0] io_pre_spec_2_3_0,
  input  [8:0] io_pre_spec_2_3_1,
  input  [8:0] io_pre_spec_3_0_0,
  input  [8:0] io_pre_spec_3_0_1,
  input  [8:0] io_pre_spec_3_1_0,
  input  [8:0] io_pre_spec_3_1_1,
  input  [8:0] io_pre_spec_3_2_0,
  input  [8:0] io_pre_spec_3_2_1,
  input  [8:0] io_pre_spec_3_3_0,
  input  [8:0] io_pre_spec_3_3_1,
  input  [8:0] io_pre_spec_4_0_0,
  input  [8:0] io_pre_spec_4_0_1,
  input  [8:0] io_pre_spec_4_1_0,
  input  [8:0] io_pre_spec_4_1_1,
  input  [8:0] io_pre_spec_4_2_0,
  input  [8:0] io_pre_spec_4_2_1,
  input  [8:0] io_pre_spec_4_3_0,
  input  [8:0] io_pre_spec_4_3_1,
  output [8:0] io_nxt_spec_0_0_0,
  output [8:0] io_nxt_spec_0_0_1,
  output [8:0] io_nxt_spec_0_1_0,
  output [8:0] io_nxt_spec_0_1_1,
  output [8:0] io_nxt_spec_0_2_0,
  output [8:0] io_nxt_spec_0_2_1,
  output [8:0] io_nxt_spec_0_3_0,
  output [8:0] io_nxt_spec_0_3_1,
  output [8:0] io_nxt_spec_1_0_0,
  output [8:0] io_nxt_spec_1_0_1,
  output [8:0] io_nxt_spec_1_1_0,
  output [8:0] io_nxt_spec_1_1_1,
  output [8:0] io_nxt_spec_1_2_0,
  output [8:0] io_nxt_spec_1_2_1,
  output [8:0] io_nxt_spec_1_3_0,
  output [8:0] io_nxt_spec_1_3_1,
  output [8:0] io_nxt_spec_2_0_0,
  output [8:0] io_nxt_spec_2_0_1,
  output [8:0] io_nxt_spec_2_1_0,
  output [8:0] io_nxt_spec_2_1_1,
  output [8:0] io_nxt_spec_2_2_0,
  output [8:0] io_nxt_spec_2_2_1,
  output [8:0] io_nxt_spec_2_3_0,
  output [8:0] io_nxt_spec_2_3_1,
  output [8:0] io_nxt_spec_3_0_0,
  output [8:0] io_nxt_spec_3_0_1,
  output [8:0] io_nxt_spec_3_1_0,
  output [8:0] io_nxt_spec_3_1_1,
  output [8:0] io_nxt_spec_3_2_0,
  output [8:0] io_nxt_spec_3_2_1,
  output [8:0] io_nxt_spec_3_3_0,
  output [8:0] io_nxt_spec_3_3_1,
  output [8:0] io_nxt_spec_4_0_0,
  output [8:0] io_nxt_spec_4_0_1,
  output [8:0] io_nxt_spec_4_1_0,
  output [8:0] io_nxt_spec_4_1_1,
  output [8:0] io_nxt_spec_4_2_0,
  output [8:0] io_nxt_spec_4_2_1,
  output [8:0] io_nxt_spec_4_3_0,
  output [8:0] io_nxt_spec_4_3_1
);

  // 展平端口 <-> 核的数组（Scala Vec）
  logic [8:0] cons [0:4] [0:3];
  logic [8:0] d_trunc [0:3];
  logic [8:0] rem_3_5 [0:1];
  logic [8:0] pre_spec [0:4] [0:3] [0:1];
  logic [8:0] nxt_spec [0:4] [0:3] [0:1];

  assign cons[0][0] = io_cons_0_0;
  assign cons[0][1] = io_cons_0_1;
  assign cons[0][2] = io_cons_0_2;
  assign cons[0][3] = io_cons_0_3;
  assign cons[1][0] = io_cons_1_0;
  assign cons[1][1] = io_cons_1_1;
  assign cons[1][2] = io_cons_1_2;
  assign cons[1][3] = io_cons_1_3;
  assign cons[2][0] = io_cons_2_0;
  assign cons[2][1] = io_cons_2_1;
  assign cons[2][2] = io_cons_2_2;
  assign cons[2][3] = io_cons_2_3;
  assign cons[3][0] = io_cons_3_0;
  assign cons[3][1] = io_cons_3_1;
  assign cons[3][2] = io_cons_3_2;
  assign cons[3][3] = io_cons_3_3;
  assign cons[4][0] = io_cons_4_0;
  assign cons[4][1] = io_cons_4_1;
  assign cons[4][2] = io_cons_4_2;
  assign cons[4][3] = io_cons_4_3;
  assign d_trunc[0] = io_d_trunc_0;
  assign d_trunc[1] = io_d_trunc_1;
  assign d_trunc[2] = io_d_trunc_2;
  assign d_trunc[3] = io_d_trunc_3;
  assign rem_3_5[0] = io_rem_3_5_0;
  assign rem_3_5[1] = io_rem_3_5_1;
  assign pre_spec[0][0][0] = io_pre_spec_0_0_0;
  assign pre_spec[0][0][1] = io_pre_spec_0_0_1;
  assign pre_spec[0][1][0] = io_pre_spec_0_1_0;
  assign pre_spec[0][1][1] = io_pre_spec_0_1_1;
  assign pre_spec[0][2][0] = io_pre_spec_0_2_0;
  assign pre_spec[0][2][1] = io_pre_spec_0_2_1;
  assign pre_spec[0][3][0] = io_pre_spec_0_3_0;
  assign pre_spec[0][3][1] = io_pre_spec_0_3_1;
  assign pre_spec[1][0][0] = io_pre_spec_1_0_0;
  assign pre_spec[1][0][1] = io_pre_spec_1_0_1;
  assign pre_spec[1][1][0] = io_pre_spec_1_1_0;
  assign pre_spec[1][1][1] = io_pre_spec_1_1_1;
  assign pre_spec[1][2][0] = io_pre_spec_1_2_0;
  assign pre_spec[1][2][1] = io_pre_spec_1_2_1;
  assign pre_spec[1][3][0] = io_pre_spec_1_3_0;
  assign pre_spec[1][3][1] = io_pre_spec_1_3_1;
  assign pre_spec[2][0][0] = io_pre_spec_2_0_0;
  assign pre_spec[2][0][1] = io_pre_spec_2_0_1;
  assign pre_spec[2][1][0] = io_pre_spec_2_1_0;
  assign pre_spec[2][1][1] = io_pre_spec_2_1_1;
  assign pre_spec[2][2][0] = io_pre_spec_2_2_0;
  assign pre_spec[2][2][1] = io_pre_spec_2_2_1;
  assign pre_spec[2][3][0] = io_pre_spec_2_3_0;
  assign pre_spec[2][3][1] = io_pre_spec_2_3_1;
  assign pre_spec[3][0][0] = io_pre_spec_3_0_0;
  assign pre_spec[3][0][1] = io_pre_spec_3_0_1;
  assign pre_spec[3][1][0] = io_pre_spec_3_1_0;
  assign pre_spec[3][1][1] = io_pre_spec_3_1_1;
  assign pre_spec[3][2][0] = io_pre_spec_3_2_0;
  assign pre_spec[3][2][1] = io_pre_spec_3_2_1;
  assign pre_spec[3][3][0] = io_pre_spec_3_3_0;
  assign pre_spec[3][3][1] = io_pre_spec_3_3_1;
  assign pre_spec[4][0][0] = io_pre_spec_4_0_0;
  assign pre_spec[4][0][1] = io_pre_spec_4_0_1;
  assign pre_spec[4][1][0] = io_pre_spec_4_1_0;
  assign pre_spec[4][1][1] = io_pre_spec_4_1_1;
  assign pre_spec[4][2][0] = io_pre_spec_4_2_0;
  assign pre_spec[4][2][1] = io_pre_spec_4_2_1;
  assign pre_spec[4][3][0] = io_pre_spec_4_3_0;
  assign pre_spec[4][3][1] = io_pre_spec_4_3_1;

  xs_SpecBlock_v4_core u_core (
    .q_j      (io_q_j),
    .cons     (cons),
    .d_trunc  (d_trunc),
    .q_j_1    (io_q_j_1),
    .rem_3_5  (rem_3_5),
    .q_j_2    (io_q_j_2),
    .pre_spec (pre_spec),
    .nxt_spec (nxt_spec)
  );

  assign io_nxt_spec_0_0_0 = nxt_spec[0][0][0];
  assign io_nxt_spec_0_0_1 = nxt_spec[0][0][1];
  assign io_nxt_spec_0_1_0 = nxt_spec[0][1][0];
  assign io_nxt_spec_0_1_1 = nxt_spec[0][1][1];
  assign io_nxt_spec_0_2_0 = nxt_spec[0][2][0];
  assign io_nxt_spec_0_2_1 = nxt_spec[0][2][1];
  assign io_nxt_spec_0_3_0 = nxt_spec[0][3][0];
  assign io_nxt_spec_0_3_1 = nxt_spec[0][3][1];
  assign io_nxt_spec_1_0_0 = nxt_spec[1][0][0];
  assign io_nxt_spec_1_0_1 = nxt_spec[1][0][1];
  assign io_nxt_spec_1_1_0 = nxt_spec[1][1][0];
  assign io_nxt_spec_1_1_1 = nxt_spec[1][1][1];
  assign io_nxt_spec_1_2_0 = nxt_spec[1][2][0];
  assign io_nxt_spec_1_2_1 = nxt_spec[1][2][1];
  assign io_nxt_spec_1_3_0 = nxt_spec[1][3][0];
  assign io_nxt_spec_1_3_1 = nxt_spec[1][3][1];
  assign io_nxt_spec_2_0_0 = nxt_spec[2][0][0];
  assign io_nxt_spec_2_0_1 = nxt_spec[2][0][1];
  assign io_nxt_spec_2_1_0 = nxt_spec[2][1][0];
  assign io_nxt_spec_2_1_1 = nxt_spec[2][1][1];
  assign io_nxt_spec_2_2_0 = nxt_spec[2][2][0];
  assign io_nxt_spec_2_2_1 = nxt_spec[2][2][1];
  assign io_nxt_spec_2_3_0 = nxt_spec[2][3][0];
  assign io_nxt_spec_2_3_1 = nxt_spec[2][3][1];
  assign io_nxt_spec_3_0_0 = nxt_spec[3][0][0];
  assign io_nxt_spec_3_0_1 = nxt_spec[3][0][1];
  assign io_nxt_spec_3_1_0 = nxt_spec[3][1][0];
  assign io_nxt_spec_3_1_1 = nxt_spec[3][1][1];
  assign io_nxt_spec_3_2_0 = nxt_spec[3][2][0];
  assign io_nxt_spec_3_2_1 = nxt_spec[3][2][1];
  assign io_nxt_spec_3_3_0 = nxt_spec[3][3][0];
  assign io_nxt_spec_3_3_1 = nxt_spec[3][3][1];
  assign io_nxt_spec_4_0_0 = nxt_spec[4][0][0];
  assign io_nxt_spec_4_0_1 = nxt_spec[4][0][1];
  assign io_nxt_spec_4_1_0 = nxt_spec[4][1][0];
  assign io_nxt_spec_4_1_1 = nxt_spec[4][1][1];
  assign io_nxt_spec_4_2_0 = nxt_spec[4][2][0];
  assign io_nxt_spec_4_2_1 = nxt_spec[4][2][1];
  assign io_nxt_spec_4_3_0 = nxt_spec[4][3][0];
  assign io_nxt_spec_4_3_1 = nxt_spec[4][3][1];
endmodule
// END GENERATED
