// =============================================================================
// FarPathAdderF64WidenPipeline —— f64 far path 的 54 位"先打拍再相加"加法器
//
// 在哪一层：FarPathFloatAdderF64WidenPipeline 里的 U_FS0 / U_FS1（A + B 与 A + 2ulp + B 两份），
//   AW=54、stage0AdderWidth=0（yunsuan/vector/VectorFloatAdder.scala class FarPathAdderF64WidenPipeline）。
// 机制：stage0AdderWidth=0 这一支最简单——两个加数在第 0 拍末各自打一拍（fire 使能），
//   第 1 拍做一次完整的 54 位加法，结果 = (A + B) mod 2^54，晚一拍出来。
//   与 f32 那份（FarPathF32WidenF16MixedAdderPipeline，切段进位）对比：这里没有把进位链拆到两拍。
// 怪癖（照 golden）：寄存器 RegEnable(fire)，不复位；加法 54 位回绕（最高进位丢弃）。
// 结构：golden 端口 -> xs_FarPathAdderF64WidenPipeline_core（可读核）。
// golden 对照：G1-canonical/golden-rtl/FarPathAdderF64WidenPipeline.sv
// =============================================================================
module xs_FarPathAdderF64WidenPipeline_core (
  input  logic        clock,
  input  logic        fire,
  input  logic [53:0] a,
  input  logic [53:0] b,
  output logic [53:0] sum
);
  // ---- 第 0 拍：两个加数原样打拍 ----
  logic [53:0] a_q, b_q;
  always_ff @(posedge clock) begin
    if (fire) begin
      a_q <= a;
      b_q <= b;
    end
  end

  // ---- 第 1 拍：完整相加（54 位回绕）----
  assign sum = a_q + b_q;
endmodule

module FarPathAdderF64WidenPipeline (
  input  logic        clock,
  input  logic        io_fire,
  input  logic [53:0] io_A,
  input  logic [53:0] io_B,
  output logic [53:0] io_result
);
  xs_FarPathAdderF64WidenPipeline_core u_core (
    .clock (clock),
    .fire  (io_fire),
    .a     (io_A),
    .b     (io_B),
    .sum   (io_result)
  );
endmodule
