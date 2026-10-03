// CSA4to2.sv —— 107 位 4:2 进位保留压缩器（VectorFloatFMA / FloatFMA 的乘积部分积归约树里用）
// -----------------------------------------------------------------------------
// 在哪一层：CSA_Nto2With3to2MainPipeline 把 Booth 部分积逐层压缩，其中一层用 3 个本模块
//   把 4 个 107 位操作数压成 2 个（sum / carry），使 a+b+c+d ≡ sum+carry (mod 2^107)。
// 机制（对着 yunsuan/vector/VectorFloatFMA.scala class CSA4to2 写）：每一位是一个"两级全加器"：
//   第一级 cout[i] = Mux(a^b, c, a)（= a/b/c 的多数，送到第 i+1 位当进位入）；
//   第二级 sum[i]  = a^b^c^d^cout[i-1]，carry[i] = Mux(a^b^c^d, cout[i-1], d)（第 0 位进位入为 0）。
//   carry[i] 的权重是 2^(i+1)。
// 怪癖（照 Scala/golden）：输出不是"sum 一路、carry 左移一位另一路"，而是按列奇偶交错——
//   偶数列 j：out_sum[j] = sum[j]，out_car[j] = carry[j-1]；
//   奇数列 j：out_sum[j] = carry[j-1]，out_car[j] = sum[j]；
//   out_car[0] = 0，out_sum[0] = sum[0]。两路之和不变；最高位的 carry[106] 被固定位宽丢弃。
// 纯组合，无寄存器、无子模块。golden 对照：G1-canonical/golden-rtl/CSA4to2.sv
// =============================================================================
module xs_CSA4to2_core #(
  parameter int WIDTH = 107
) (
  input  logic [WIDTH-1:0] in_a,
  input  logic [WIDTH-1:0] in_b,
  input  logic [WIDTH-1:0] in_c,
  input  logic [WIDTH-1:0] in_d,
  output logic [WIDTH-1:0] out_sum,
  output logic [WIDTH-1:0] out_car
);
  logic [WIDTH-1:0] abc_carry;   // 第一级：a/b/c 的多数位（第 i 位送往第 i+1 位）
  logic [WIDTH-1:0] carry_in;    // 第二级的进位入：第 i 位 = abc_carry[i-1]，第 0 位 = 0
  logic [WIDTH-1:0] parity4;     // a^b^c^d
  logic [WIDTH-1:0] col_sum;     // 第二级本位和（权重 2^i）
  logic [WIDTH-1:0] col_carry;   // 第二级进位（权重 2^(i+1)）

  always_comb begin
    for (int i = 0; i < WIDTH; i++)
      abc_carry[i] = (in_a[i] ^ in_b[i]) ? in_c[i] : in_a[i];
    carry_in  = {abc_carry[WIDTH-2:0], 1'b0};
    parity4   = in_a ^ in_b ^ in_c ^ in_d;
    col_sum   = parity4 ^ carry_in;
    for (int i = 0; i < WIDTH; i++)
      col_carry[i] = parity4[i] ? carry_in[i] : in_d[i];

    // 按列奇偶交错输出：col_carry[j-1] 与 col_sum[j] 同权（2^j），一个进 sum 一个进 car
    out_sum[0] = col_sum[0];
    out_car[0] = 1'b0;
    for (int j = 1; j < WIDTH; j++) begin
      if (j % 2 == 1) begin
        out_sum[j] = col_carry[j-1];
        out_car[j] = col_sum[j];
      end else begin
        out_sum[j] = col_sum[j];
        out_car[j] = col_carry[j-1];
      end
    end
  end
endmodule

module CSA4to2 (
  input  logic [106:0] io_in_a,
  input  logic [106:0] io_in_b,
  input  logic [106:0] io_in_c,
  input  logic [106:0] io_in_d,
  output logic [106:0] io_out_sum,
  output logic [106:0] io_out_car
);
  xs_CSA4to2_core #(
    .WIDTH(107)
  ) u_core (
    .in_a(io_in_a),
    .in_b(io_in_b),
    .in_c(io_in_c),
    .in_d(io_in_d),
    .out_sum(io_out_sum),
    .out_car(io_out_car)
  );
endmodule
