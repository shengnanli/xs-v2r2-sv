// Queue72_CoupledL2Imp_Anon 包装层(golden 同名扁平端口 ↔ 可读核)。
// 端口逐一直连, 仅供 FM impl 侧与 ST 替换。
module Queue72_CoupledL2Imp_Anon(
  input         clock,
  input         reset,
  output        io_enq_ready,
  input         io_enq_valid,
  input  [3:0]  io_enq_bits_pCrdType,
  input  [10:0] io_enq_bits_srcID,
  input         io_deq_ready,
  output        io_deq_valid,
  output [3:0]  io_deq_bits_pCrdType,
  output [10:0] io_deq_bits_srcID
);

  xs_Queue72_CoupledL2Imp_Anon_core u_core (
    .clock                (clock),
    .reset                (reset),
    .io_enq_ready         (io_enq_ready),
    .io_enq_valid         (io_enq_valid),
    .io_enq_bits_pCrdType (io_enq_bits_pCrdType),
    .io_enq_bits_srcID    (io_enq_bits_srcID),
    .io_deq_ready         (io_deq_ready),
    .io_deq_valid         (io_deq_valid),
    .io_deq_bits_pCrdType (io_deq_bits_pCrdType),
    .io_deq_bits_srcID    (io_deq_bits_srcID)
  );

endmodule
