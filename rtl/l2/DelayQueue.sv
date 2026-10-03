// =============================================================================
// DelayQueue —— BOP 延迟队列（xs_DelayQueue_core 家族变体，地址宽 42 位）
//
// 本变体例化在 PBestOffsetPrefetch 里（golden：fullAddrBits=48 → 去 6 位块内偏移 = 42）。
// 机制与怪癖见 xs_DelayQueue_core.sv；本层只做端口改名与设参。
// =============================================================================

module DelayQueue(
  input         clock,
  input         reset,
  input  [9:0]  io_pfCtrlOfDelayLatency,
  input         io_in_valid,
  input  [41:0] io_in_bits,
  input         io_out_ready,
  output        io_out_valid,
  output [47:0] io_out_bits
);

  xs_DelayQueue_core #(
    .ADDR_W         (42),
    .OFFSET_BITS    (6),
    .ENTRIES        (16),
    .CNT_W          (10),
    .DEFAULT_LATENCY(300)
  ) u_core (
    .clock       (clock),
    .reset       (reset),
    .latency_ctrl(io_pfCtrlOfDelayLatency),
    .in_valid    (io_in_valid),
    .in_addr     (io_in_bits),
    .out_ready   (io_out_ready),
    .out_valid   (io_out_valid),
    .out_addr    (io_out_bits)
  );

endmodule
