// =============================================================================
// IntBuffer —— 单路中断线的一拍缓冲（diplomacy 中断节点上的 RegNext）
//
// 在哪一层：L2Top / XSTile / XSTop 把单根中断线（BEU 总线错误中断、debug 中断）跨层传递时插入的
//   缓冲节点（utility/IntBuffer.scala，depth=1、cdc=false，本变体只有 1 根中断线）。
// 机制：cdc=false 那一支就是 RegNextN(in, 1, 初值 0)：每拍把输入中断电平锁存一拍再送出，
//   切断跨层组合路径。中断是电平信号，晚一拍不影响语义。
// 边界：★异步高有效复位★（golden 为 always @(posedge clock or posedge reset)），复位值 0——
//   复位期间中断输出恒为 0，不会把上电随机值当成中断送出去。
// 结构：golden 端口 -> xs_IntBuffer_core（可读核）。
// golden 对照：G1-canonical/golden-rtl/IntBuffer.sv
// =============================================================================
module xs_IntBuffer_core (
  input  logic clock,
  input  logic reset,
  input  logic irq_in,
  output logic irq_out
);
  // ---- 一拍缓冲：异步复位到 0，其余每拍跟随输入 ----
  logic irq_q;
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      irq_q <= 1'b0;
    else
      irq_q <= irq_in;
  end

  assign irq_out = irq_q;
endmodule

module IntBuffer (
  input  logic clock,
  input  logic reset,
  input  logic auto_in_0,
  output logic auto_out_0
);
  xs_IntBuffer_core u_core (
    .clock   (clock),
    .reset   (reset),
    .irq_in  (auto_in_0),
    .irq_out (auto_out_0)
  );
endmodule
