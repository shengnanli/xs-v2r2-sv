// =============================================================================
// CSA4to2_15 —— 16 位 4:2 压缩器（四个加数压成 sum/carry 两个，不做进位传播）
//
// 在哪一层：向量 ALU 的归约单元 Reduction（yunsuan/vector/VectorALU/Reduction.scala
//   `csa_4to2_sew16 = Module(new CSA4to2(width = 16))`），把 SEW=16 的四个部分和压成两个，
//   最后再用一个加法器相加。Scala 类：yunsuan/vector/VectorFloatFMA.scala `class CSA4to2(width)`。
// 机制（每一位两级全加器，逐位对应 Scala）：
//   第一级  cout[i] = Mux(a^b, c, a)                    —— a、b、c 的多数表决（进位，送往第 i+1 位）
//   第二级  s1      = a^b^c^d（四个输入的异或）
//           sum[i]  = s1 ^ cout[i-1]                      —— 第 0 位没有 cout[-1]，等价于 cin = 0
//           car[i]  = Mux(s1, cout[i-1], d)               —— (a^b^c)、d、cout[i-1] 的多数表决
//   最后按奇偶位交错装进两个输出（Scala 的 sum_temp_vec / carry_temp_vec）：
//     out_sum[0] = sum[0]；              out_car[0] = 0
//     奇数位 i：out_car[i] = sum[i]，    out_sum[i] = car[i-1]
//     偶数位 i：out_sum[i] = sum[i]，    out_car[i] = car[i-1]
//   即：本位的 sum 与来自下一位的 car 分别落在两个输出里，保证 out_sum + out_car ≡ a+b+c+d (mod 2^16)。
//   最高位 car[15] 被丢掉（截断在 16 位）；cout[15] 也不被任何位用到。
// 同族：CSA4to2_16（8 位版本，rtl/backend/CSA4to2_16.sv）。
// 无状态、无时钟。golden 对照：G1-canonical/golden-rtl/CSA4to2_15.sv（146 行）
// =============================================================================
module CSA4to2_15 (
  input  logic [15:0] io_in_a,
  input  logic [15:0] io_in_b,
  input  logic [15:0] io_in_c,
  input  logic [15:0] io_in_d,
  output logic [15:0] io_out_sum,
  output logic [15:0] io_out_car
);

  localparam int W = 16;

  logic [W-1:0] cout_vec;    // 第一级：a、b、c 的多数表决
  logic [W-1:0] sum_vec;     // 第二级：本位和
  logic [W-1:0] carry_vec;   // 第二级：送往高一位的进位

  // ---- 两级全加器，逐位 ----
  always_comb begin
    for (int i = 0; i < W; i++) begin
      logic xor4;
      logic cin;
      cout_vec[i]  = (io_in_a[i] ^ io_in_b[i]) ? io_in_c[i] : io_in_a[i];
      xor4         = io_in_a[i] ^ io_in_b[i] ^ io_in_c[i] ^ io_in_d[i];
      cin          = (i == 0) ? 1'b0 : cout_vec[i-1];
      sum_vec[i]   = xor4 ^ cin;
      carry_vec[i] = xor4 ? cin : io_in_d[i];
    end
  end

  // ---- 奇偶交错装进两个输出 ----
  always_comb begin
    io_out_sum[0] = sum_vec[0];
    io_out_car[0] = 1'b0;
    for (int i = 1; i < W; i++) begin
      if (i % 2 == 1) begin
        io_out_car[i] = sum_vec[i];
        io_out_sum[i] = carry_vec[i-1];
      end else begin
        io_out_sum[i] = sum_vec[i];
        io_out_car[i] = carry_vec[i-1];
      end
    end
  end
endmodule
