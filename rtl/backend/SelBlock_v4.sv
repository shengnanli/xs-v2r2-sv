// =============================================================================
// SelBlock_v4.sv —— SRT radix-16 整数除法：「下一拍第一个商位」的选择块
//
// 在哪一层：VectorIdiv → SRT16Divint{,_4,_6} → IterBlock_v4{,_4,_6} → 本块（selB）。
//   SRT16Divint 每拍出两个 radix-4 商位（4×4 = radix-16），记作 q1（本拍第一个）、
//   q2（本拍第二个）。本块做两件事：
//     (1) 用上一拍留下的 4 对进位保留（carry-save）比较值 pre_sel，各做一次短进位
//         加法取符号位，4 个符号经 SignDec 译成本拍的 q1（io_q_j_1）；
//     (2) 为**下一拍**的 q1 预备比较值 nxt_sel：把「余数估计」与「按本拍 q2 选出的
//         比较常数」用 3:2 CSA 压成 carry-save 形式，留到下一拍再做 (1)。
//   这样「比较 = 加法 + 取符号」中最慢的进位传播被挪到下一拍开头，与 CSA 分开——
//   这就是 Scala 注释里说的 "reschedule"（重定时）。
//
// 商位编码（全族统一，★与直觉相反★）：5 位独热，第 i 位代表商位 2-i：
//   bit0=+2  bit1=+1  bit2=0  bit3=-1  bit4=-2。
//   radix-4 最小冗余商位集 {-2..2}，冗余度 ρ=2/3，所以选择只需看余数的短截断估计。
// 比较常数 io_cons_<u>_<k>：u = 本拍 q2 的独热下标（同上编码），k = 0..3 对应 4 条
//   选择阈值 m_{-1}, m_0, m_1, m_2（SRT4qdsCons 按除数高 3 位查表，父级预先把
//   「-4·q2·d 的截断值 − m_k」算好）。故 nxt_sel[k] = 估计 + cons[q2][k]，其符号
//   就是「4·w(下一步) 是否越过第 k 条阈值」。
// 位宽：选择路径 8 位 = 3 位整数 + 5 位小数（Scala "sel 3+5"），io_rem_3_5 即由此得名。
//   carry 半边的 CSA 进位权重高一位，出块前左移 1 位（最高位丢弃，golden 同）。
//
// 子模块（两侧白盒，均为本仓已签核重写件）：CSA3_2_3988（8 位 3:2 CSA）×4、SignDec ×1。
// 纯组合：零寄存器、无 clock/reset。
// 设计源：yunsuan/src/main/scala/yunsuan/vector/VectorIdiv/SRT16Divint.scala (class SelBlock_v4)
// golden 对照：G1-canonical/golden-rtl/SelBlock_v4.sv
// wrapper 由 scripts/gen_srt_divblocks.py 生成（GENERATED 区），核为手写。
// =============================================================================

// -----------------------------------------------------------------------------
// xs_SelBlock_v4_core —— 可读核（端口名沿用 Scala 的 io 字段名，数组即 Scala 的 Vec）
// -----------------------------------------------------------------------------
module xs_SelBlock_v4_core (
  input  logic [4:0] q_j,                   // 本拍第二个商位 q2（独热，选比较常数）
  output logic [4:0] q_j_1,                 // 本拍第一个商位 q1（由上一拍的 pre_sel 定）
  input  logic [7:0] cons      [0:4][0:3],  // [q2 下标][阈值 k] 的比较常数
  input  logic [7:0] rem_3_5   [0:1],       // 余数估计（carry-save：[0]=sum, [1]=carry 已左移）
  input  logic [7:0] pre_sel   [0:3][0:1],  // 上一拍算好的 4 对比较值（[k][sum/carry]）
  output logic [7:0] nxt_sel   [0:3][0:1]   // 留给下一拍的 4 对比较值
);

  // ---------------------------------------------------------------------------
  // §1 按 q2 选比较常数：独热选择写成「按位或」（Chisel Mux1H 的原样语义）。
  //    q2 若非独热，golden 是把几档常数按位或在一起——这里照做，不改成优先级。
  // ---------------------------------------------------------------------------
  logic [7:0] cons_u [0:3];
  always_comb begin
    for (int k = 0; k < 4; k++) begin
      cons_u[k] = '0;
      for (int u = 0; u < 5; u++)
        if (q_j[u]) cons_u[k] = cons_u[k] | cons[u][k];
    end
  end

  // ---------------------------------------------------------------------------
  // §2 为下一拍准备比较值：4 条阈值各一个 3:2 CSA，(估计 sum, 估计 carry, 常数)
  //    → (sum, carry)。carry 的权重是本位的 2 倍，出块前左移 1 位对齐。
  // ---------------------------------------------------------------------------
  logic [7:0] csa_carry [0:3];
  for (genvar k = 0; k < 4; k++) begin : g_thresh
    CSA3_2_3988 u_csa (
      .io_in_0  (rem_3_5[0]),
      .io_in_1  (rem_3_5[1]),
      .io_in_2  (cons_u[k]),
      .io_out_0 (nxt_sel[k][0]),
      .io_out_1 (csa_carry[k])
    );
    assign nxt_sel[k][1] = {csa_carry[k][6:0], 1'b0};
  end

  // ---------------------------------------------------------------------------
  // §3 本拍的 q1：上一拍的每对比较值做一次 8 位进位传播加法，最高位就是
  //    「估计值 − 阈值」的符号；4 个符号是温度计码，交 SignDec 译成独热商位。
  // ---------------------------------------------------------------------------
  logic [7:0] pre_sum [0:3];
  logic [3:0] sign;
  always_comb begin
    for (int k = 0; k < 4; k++) begin
      pre_sum[k] = pre_sel[k][0] + pre_sel[k][1];   // 8 位回绕
      sign[k]    = pre_sum[k][7];
    end
  end

  SignDec u_sign_dec (
    .io_sign_0 (sign[0]),
    .io_sign_1 (sign[1]),
    .io_sign_2 (sign[2]),
    .io_sign_3 (sign[3]),
    .io_q      (q_j_1)
  );
endmodule

// BEGIN GENERATED(selblock-wrapper)
// -----------------------------------------------------------------------------
// SelBlock_v4 —— golden 同名 wrapper：端口表逐字取 golden，展平端口 <-> 核数组（机械生成）
// -----------------------------------------------------------------------------
module SelBlock_v4(
  input  [4:0] io_q_j,
  output [4:0] io_q_j_1,
  input  [7:0] io_cons_0_0,
  input  [7:0] io_cons_0_1,
  input  [7:0] io_cons_0_2,
  input  [7:0] io_cons_0_3,
  input  [7:0] io_cons_1_0,
  input  [7:0] io_cons_1_1,
  input  [7:0] io_cons_1_2,
  input  [7:0] io_cons_1_3,
  input  [7:0] io_cons_2_0,
  input  [7:0] io_cons_2_1,
  input  [7:0] io_cons_2_2,
  input  [7:0] io_cons_2_3,
  input  [7:0] io_cons_3_0,
  input  [7:0] io_cons_3_1,
  input  [7:0] io_cons_3_2,
  input  [7:0] io_cons_3_3,
  input  [7:0] io_cons_4_0,
  input  [7:0] io_cons_4_1,
  input  [7:0] io_cons_4_2,
  input  [7:0] io_cons_4_3,
  input  [7:0] io_rem_3_5_0,
  input  [7:0] io_rem_3_5_1,
  input  [7:0] io_pre_sel_0_0,
  input  [7:0] io_pre_sel_0_1,
  input  [7:0] io_pre_sel_1_0,
  input  [7:0] io_pre_sel_1_1,
  input  [7:0] io_pre_sel_2_0,
  input  [7:0] io_pre_sel_2_1,
  input  [7:0] io_pre_sel_3_0,
  input  [7:0] io_pre_sel_3_1,
  output [7:0] io_nxt_sel_0_0,
  output [7:0] io_nxt_sel_0_1,
  output [7:0] io_nxt_sel_1_0,
  output [7:0] io_nxt_sel_1_1,
  output [7:0] io_nxt_sel_2_0,
  output [7:0] io_nxt_sel_2_1,
  output [7:0] io_nxt_sel_3_0,
  output [7:0] io_nxt_sel_3_1
);

  // 展平端口 <-> 核的数组（Scala Vec）
  logic [7:0] cons [0:4] [0:3];
  logic [7:0] rem_3_5 [0:1];
  logic [7:0] pre_sel [0:3] [0:1];
  logic [7:0] nxt_sel [0:3] [0:1];

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
  assign rem_3_5[0] = io_rem_3_5_0;
  assign rem_3_5[1] = io_rem_3_5_1;
  assign pre_sel[0][0] = io_pre_sel_0_0;
  assign pre_sel[0][1] = io_pre_sel_0_1;
  assign pre_sel[1][0] = io_pre_sel_1_0;
  assign pre_sel[1][1] = io_pre_sel_1_1;
  assign pre_sel[2][0] = io_pre_sel_2_0;
  assign pre_sel[2][1] = io_pre_sel_2_1;
  assign pre_sel[3][0] = io_pre_sel_3_0;
  assign pre_sel[3][1] = io_pre_sel_3_1;

  xs_SelBlock_v4_core u_core (
    .q_j     (io_q_j),
    .q_j_1   (io_q_j_1),
    .cons    (cons),
    .rem_3_5 (rem_3_5),
    .pre_sel (pre_sel),
    .nxt_sel (nxt_sel)
  );

  assign io_nxt_sel_0_0 = nxt_sel[0][0];
  assign io_nxt_sel_0_1 = nxt_sel[0][1];
  assign io_nxt_sel_1_0 = nxt_sel[1][0];
  assign io_nxt_sel_1_1 = nxt_sel[1][1];
  assign io_nxt_sel_2_0 = nxt_sel[2][0];
  assign io_nxt_sel_2_1 = nxt_sel[2][1];
  assign io_nxt_sel_3_0 = nxt_sel[3][0];
  assign io_nxt_sel_3_1 = nxt_sel[3][1];
endmodule
// END GENERATED
