// EnqPolicy.sv —— 发射队列入队策略（W=22）薄包装层
// -----------------------------------------------------------------------------
// 逻辑全在 xs_EnqPolicy_core.sv（家族共享核，按位宽参数化）；本文件只给 W 并改名接线。
//   口 0 = 最低位的空槽，valid = 至少 1 个空槽；
//   口 1 = 最高位的空槽，valid = 至少 2 个空槽。
// 端口表逐字取自 G1 golden EnqPolicy.sv。
//
// 自动生成：scripts/gen_enqpolicy.py —— 勿手改
// =============================================================================
module EnqPolicy(
  input  [21:0] io_canEnq,
  output        io_enqSelOHVec_0_valid,
  output [21:0] io_enqSelOHVec_0_bits,
  output        io_enqSelOHVec_1_valid,
  output [21:0] io_enqSelOHVec_1_bits
);

  xs_EnqPolicy_core #(
    .W(22)
  ) u_core (
    .can_enq    (io_canEnq),
    .sel0_valid (io_enqSelOHVec_0_valid),
    .sel0_oh    (io_enqSelOHVec_0_bits),
    .sel1_valid (io_enqSelOHVec_1_valid),
    .sel1_oh    (io_enqSelOHVec_1_bits)
  );

endmodule
