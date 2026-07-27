// Pipeline_11 包装层(golden 同名扁平端口 ↔ xs_Pipeline_11_core)。
// 端口逐一直连, 仅供 FM impl 侧与 ST 替换。
module Pipeline_11(
  input         clock,
  input         reset,
  input         io_in_valid,
  input  [31:0] io_in_bits,
  output        io_out_valid,
  output [31:0] io_out_bits
);

  xs_Pipeline_11_core u_core (
    .clock       (clock),
    .reset       (reset),
    .io_in_valid (io_in_valid),
    .io_in_bits  (io_in_bits),
    .io_out_valid(io_out_valid),
    .io_out_bits (io_out_bits)
  );

endmodule
