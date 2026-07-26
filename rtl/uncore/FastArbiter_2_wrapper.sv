// 自动生成：scripts/gen_fastarbiter.py —— 勿手改
module FastArbiter_2(
  input clock,
  input reset,
  output io_in_0_ready,
  input io_in_0_valid,
  input [4:0] io_in_0_bits_pfSource,
  output io_in_1_ready,
  input io_in_1_valid,
  input [4:0] io_in_1_bits_pfSource,
  output io_in_2_ready,
  input io_in_2_valid,
  input [4:0] io_in_2_bits_pfSource,
  output io_in_3_ready,
  input io_in_3_valid,
  input [4:0] io_in_3_bits_pfSource,
  input io_out_ready,
  output io_out_valid,
  output [4:0] io_out_bits_pfSource
);
  xs_FastArbiter_2_core u_core (
    .clock(clock),
    .reset(reset),
    .io_in_0_ready(io_in_0_ready),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_pfSource(io_in_0_bits_pfSource),
    .io_in_1_ready(io_in_1_ready),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_pfSource(io_in_1_bits_pfSource),
    .io_in_2_ready(io_in_2_ready),
    .io_in_2_valid(io_in_2_valid),
    .io_in_2_bits_pfSource(io_in_2_bits_pfSource),
    .io_in_3_ready(io_in_3_ready),
    .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_pfSource(io_in_3_bits_pfSource),
    .io_out_ready(io_out_ready),
    .io_out_valid(io_out_valid),
    .io_out_bits_pfSource(io_out_bits_pfSource)
  );
endmodule
