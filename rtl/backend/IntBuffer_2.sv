// =============================================================================
// IntBuffer_2 —— PLIC 外部中断的一拍缓冲（两条中断边、每条 1 根线）
//
// 在哪一层：XSTile 把 PLIC 的外部中断送进 MemBlock 时插的缓冲节点
//   （XSTile.scala `memBlock.plic_int_sink :*= IntBuffer() :*= plic_int_node`，实例 intBuffer_1）。
//   `:*=` 是"星号连接"：PLIC 给本 hart 连了两条中断边（M 态外部中断、S 态外部中断），
//   每条边 1 根线，所以端口名是 auto_in_<边>_<线> = auto_in_1_0 / auto_in_0_0。
//   Scala：utility/IntBuffer.scala，depth=1、cdc=false。
// 机制：与 IntBuffer / IntBuffer_1 完全相同——每根线 RegNextN(in, 1, 初值 0)，打一拍切断跨层组合路径。
// 边界：★异步高有效复位★，复位值 0。
// 端口顺序：golden 先列边 1 再列边 0（diplomacy 生成顺序），本文件照抄以过端口顺序闸。
// golden 对照：G1-canonical/golden-rtl/IntBuffer_2.sv
// =============================================================================
module IntBuffer_2 (
  input  logic clock,
  input  logic reset,
  input  logic auto_in_1_0,
  input  logic auto_in_0_0,
  output logic auto_out_1_0,
  output logic auto_out_0_0
);

  // ---- 一拍缓冲：每条边一根线、一个触发器，异步复位到 0 ----
  logic edge0_irq_q;
  logic edge1_irq_q;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      edge0_irq_q <= 1'b0;
      edge1_irq_q <= 1'b0;
    end else begin
      edge0_irq_q <= auto_in_0_0;
      edge1_irq_q <= auto_in_1_0;
    end
  end

  assign auto_out_1_0 = edge1_irq_q;
  assign auto_out_0_0 = edge0_irq_q;
endmodule
