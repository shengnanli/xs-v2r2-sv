// =============================================================================
// FarPathF32WidenF16MixedAdderPipeline —— far path 的 25 位"切段进位"两拍加法器
//
// 在哪一层：FarPathF32WidenF16MixedPipeline 里的 U_FS0 / U_FS1（A + B 与 A + 2ulp + B 两份），
//   AW=25、stage0AdderWidth=18（yunsuan/vector/VectorFloatAdder.scala
//   class FarPathF32WidenF16MixedAdderPipeline）。
// 机制：25 位加法拆成跨拍的两段，缩短第 0 拍的进位链——
//   第 0 拍：低 18 位做带进位输出的加法（19 位结果），高 7 位单独相加（不含低段进位，7 位回绕）；
//            三样东西都打拍（fire 使能）。
//   第 1 拍：高段和 + 低段进位（7 位回绕），拼上低 18 位和。
//   结果 = (A + B) mod 2^25，只是晚一拍出来。
// 怪癖（照 golden）：
//   - Scala 把低段进位当成"高段的 7 位加数" {6'h0, carry} 整个打拍（高 6 位恒 0），本件照样存 7 位，
//     与 golden 寄存器逐位对应（恒 0 的 6 位两侧都是常量寄存器）。
//   - 寄存器全部 RegEnable(fire)，不复位。
// 结构：golden 端口 -> xs_FarPathF32WidenF16MixedAdderPipeline_core（可读核）。
// golden 对照：G1-canonical/golden-rtl/FarPathF32WidenF16MixedAdderPipeline.sv
// =============================================================================
module xs_FarPathF32WidenF16MixedAdderPipeline_core (
  input  logic        clock,
  input  logic        fire,
  input  logic [24:0] a,
  input  logic [24:0] b,
  output logic [24:0] sum
);
  localparam int LO_W = 18;   // 第 0 拍完整相加的低段宽度
  localparam int HI_W = 7;    // 第 1 拍才收进位的高段宽度

  // ---- 第 0 拍：两段分别相加 ----
  logic [LO_W:0]   lo_sum_full;   // 低段和，含进位输出
  logic [HI_W-1:0] hi_sum_part;   // 高段和，未加低段进位
  assign lo_sum_full = {1'b0, a[LO_W-1:0]} + {1'b0, b[LO_W-1:0]};
  assign hi_sum_part = a[24:LO_W] + b[24:LO_W];

  logic [HI_W-1:0] hi_sum_q;
  logic [HI_W-1:0] lo_carry_q;    // 低段进位，已扩成高段宽度的加数
  logic [LO_W-1:0] lo_sum_q;
  always_ff @(posedge clock) begin
    if (fire) begin
      hi_sum_q   <= hi_sum_part;
      lo_carry_q <= HI_W'(lo_sum_full[LO_W]);
      lo_sum_q   <= lo_sum_full[LO_W-1:0];
    end
  end

  // ---- 第 1 拍：高段收进位 ----
  logic [HI_W-1:0] hi_sum;
  assign hi_sum = hi_sum_q + lo_carry_q;
  assign sum    = {hi_sum, lo_sum_q};
endmodule

module FarPathF32WidenF16MixedAdderPipeline (
  input  logic        clock,
  input  logic        io_fire,
  input  logic [24:0] io_A,
  input  logic [24:0] io_B,
  output logic [24:0] io_result
);
  xs_FarPathF32WidenF16MixedAdderPipeline_core u_core (
    .clock (clock),
    .fire  (io_fire),
    .a     (io_A),
    .b     (io_B),
    .sum   (io_result)
  );
endmodule
