// =============================================================================
// IntBuffer_1 —— 两根中断线的一拍缓冲（diplomacy 中断节点上的 RegNext）
//
// 在哪一层：XSTile 把 CLINT（msip/mtip 两根）与 NMI（两根）中断送进 MemBlock 时
//   各插一个 IntBuffer 节点（XSTile.scala `memBlock.clint_int_sink := IntBuffer() := ...`，
//   实例 intBuffer / intBuffer_3）。一个节点上有 2 根中断线，所以单态化成本变体。
//   Scala：utility/IntBuffer.scala，depth=1、cdc=false。
// 机制：cdc=false 那一支就是 RegNextN(in, 1, 初值 0)：每拍把输入中断电平锁存一拍再送出，
//   切断跨层组合路径。中断是电平信号，晚一拍不影响语义。两根线互不相干，各一个触发器。
// 边界：★异步高有效复位★（golden 为 always @(posedge clock or posedge reset)），复位值 0——
//   复位期间中断输出恒为 0，不会把上电随机值当成中断送出去。
// 同族：IntBuffer（1 根线）、IntBuffer_2（PLIC 两条边各 1 根线，端口名带 _N_0 后缀）。
// golden 对照：G1-canonical/golden-rtl/IntBuffer_1.sv
// =============================================================================
module IntBuffer_1 (
  input  logic clock,
  input  logic reset,
  input  logic auto_in_0,
  input  logic auto_in_1,
  output logic auto_out_0,
  output logic auto_out_1
);

  // ---- 一拍缓冲：两根中断线各一个触发器，异步复位到 0，其余每拍跟随输入 ----
  logic irq0_q;
  logic irq1_q;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      irq0_q <= 1'b0;
      irq1_q <= 1'b0;
    end else begin
      irq0_q <= auto_in_0;
      irq1_q <= auto_in_1;
    end
  end

  assign auto_out_0 = irq0_q;
  assign auto_out_1 = irq1_q;
endmodule
