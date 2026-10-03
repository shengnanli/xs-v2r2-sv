// =============================================================================
// FarPathAdderF16Pipeline —— f16 加法 far path 的 12 位"先打拍再相加"加法器
//
// 在哪一层：FarPathF16Pipeline 里的 far-path 尾数加法（yunsuan/vector/VectorFloatAdder.scala
//   class FarPathAdderF16Pipeline，AW=12，stage0AdderWidth=0）。
// 机制：stage0AdderWidth=0 是"不切段"的那一支——两个操作数在 fire 时各打一拍
//   （RegEnable，不复位），下一拍把两份寄存值相加，取低 12 位（加法回绕，进位丢弃）。
//   即 result = (A_q + B_q) mod 2^12，比组合输入晚一拍。
// 边界：只有 clock，没有 reset；fire=0 时两寄存器保持原值，result 随之保持。
// 结构：golden 端口 -> xs_FarPathAdderF16Pipeline_core（可读核）。
// golden 对照：G1-canonical/golden-rtl/FarPathAdderF16Pipeline.sv
// =============================================================================
module xs_FarPathAdderF16Pipeline_core (
  input  logic        clock,
  input  logic        fire,
  input  logic [11:0] a,
  input  logic [11:0] b,
  output logic [11:0] sum
);
  // ---- 第 0 拍：fire 时锁存两个加数（不复位，与 golden RegEnable 一致）----
  logic [11:0] a_q;
  logic [11:0] b_q;
  always_ff @(posedge clock) begin
    if (fire) begin
      a_q <= a;
      b_q <= b;
    end
  end

  // ---- 第 1 拍：寄存值相加，12 位回绕 ----
  assign sum = a_q + b_q;
endmodule

module FarPathAdderF16Pipeline (
  input  logic        clock,
  input  logic        io_fire,
  input  logic [11:0] io_A,
  input  logic [11:0] io_B,
  output logic [11:0] io_result
);
  xs_FarPathAdderF16Pipeline_core u_core (
    .clock (clock),
    .fire  (io_fire),
    .a     (io_A),
    .b     (io_B),
    .sum   (io_result)
  );
endmodule
