// Pipeline_3 包装层(golden 同名扁平端口 ↔ xs_Pipeline_3_core)。
// 端口逐一直连(golden 端口已是扁平标量), 仅供 FM impl 侧与 ST 替换。
module Pipeline_3(
  input         clock,
  input         reset,
  output        io_in_ready,
  input         io_in_valid,
  input  [32:0] io_in_bits_tag,
  input  [8:0]  io_in_bits_set,
  input  [43:0] io_in_bits_vaddr,
  input  [4:0]  io_in_bits_pfSource,
  input         io_out_ready,
  output        io_out_valid,
  output [4:0]  io_out_bits_pfSource
);

  xs_Pipeline_3_core u_core (
    .clock               (clock),
    .reset               (reset),
    .io_in_ready         (io_in_ready),
    .io_in_valid         (io_in_valid),
    .io_in_bits_tag      (io_in_bits_tag),
    .io_in_bits_set      (io_in_bits_set),
    .io_in_bits_vaddr    (io_in_bits_vaddr),
    .io_in_bits_pfSource (io_in_bits_pfSource),
    .io_out_ready        (io_out_ready),
    .io_out_valid        (io_out_valid),
    .io_out_bits_pfSource(io_out_bits_pfSource)
  );

endmodule
