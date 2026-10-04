// AsyncResetSynchronizerShiftReg_w1_d3_i0.sv —— 1 位宽、3 级、异步复位到 0 的跨时钟域同步器（rocket-chip util）
//
// Scala：rocket-chip/src/main/scala/util/SynchronizerReg.scala，class AsyncResetSynchronizerShiftReg
//   (w = 1, sync = 3, init = 0)。它对每一位例化一条 SynchronizerPrimitiveShiftReg，
//   名字叫 output_chain（w=1 时只有这一条，Chisel 不加下标）。
//
// 位置：凡是跨时钟域的单比特电平都用它——核内 IMSICGateWay 把 AIA 送来的 MSI-valid
//   同步进核时钟域（CSR -> IMSIC_WRAP -> IMSIC -> IMSICGateWay.msi_vld_req_cpu_chain）；
//   核外 AsyncQueueSource/Sink、AsyncValidSync、TimeAsync、SYSCNT、调试模块也用。
//
// 本层没有任何逻辑：io_d 直接进 3 级同步链，链尾就是 io_q。
//   io_d -> sync_2 -> sync_1 -> sync_0 -> io_q   （全部 posedge reset 异步清 0）
// 真正的寄存器在 child AsyncResetSynchronizerPrimitiveShiftReg_d3_i0
// （rtl/uncore/AsyncResetSynchronizerPrimitiveShiftReg_d3_i0.sv，已签核）。
// 实例名 output_chain 与 golden 一致，FM 按名配对 child 内部寄存器。

module AsyncResetSynchronizerShiftReg_w1_d3_i0 (
  input  clock,
  input  reset,
  input  io_d,
  output io_q
);

  AsyncResetSynchronizerPrimitiveShiftReg_d3_i0 output_chain (
    .clock (clock),
    .reset (reset),
    .io_d  (io_d),
    .io_q  (io_q)
  );

endmodule
