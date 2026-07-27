// 自动生成: gen_pipe_ut.py —— Pipeline_10_xs (UT 变体, 例化可读核 xs_Pipeline_10_core)
module Pipeline_10_xs(
  input clock,
  input reset,
  input io_in_valid,
  input [31:0] io_in_bits,
  output io_out_valid,
  output [31:0] io_out_bits
);
  xs_Pipeline_10_core u_core (
    .clock(clock),
    .reset(reset),
    .io_in_valid(io_in_valid),
    .io_in_bits(io_in_bits),
    .io_out_valid(io_out_valid),
    .io_out_bits(io_out_bits)
  );
endmodule
