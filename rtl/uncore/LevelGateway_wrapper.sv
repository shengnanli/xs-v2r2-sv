// 自动生成：scripts/gen_levelgateway.py —— 勿手改
module LevelGateway(
  input clock,
  input reset,
  input io_interrupt,
  output io_plic_valid,
  input io_plic_ready,
  input io_plic_complete
);
  xs_LevelGateway_core u_core (
    .clock(clock),
    .reset(reset),
    .io_interrupt(io_interrupt),
    .io_plic_valid(io_plic_valid),
    .io_plic_ready(io_plic_ready),
    .io_plic_complete(io_plic_complete)
  );
endmodule
