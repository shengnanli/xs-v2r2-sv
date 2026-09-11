// NewPipelineConnectPipe_31 —— NewPipelineConnectPipe_25 单态化变体 wrapper（核体见 NewPipelineConnectPipe_25.sv）

module NewPipelineConnectPipe_31(
  input  clock,
  input  reset,
  output io_in_ready,
  input  io_in_valid,
  input  [49:0] io_in_bits_vaddr,
  input  [127:0] io_in_bits_data,
  input  [15:0] io_in_bits_mask,
  input  [47:0] io_in_bits_addr,
  input  io_in_bits_vecValid,
  input  io_out_ready,
  output io_out_valid,
  output [49:0] io_out_bits_vaddr,
  output [127:0] io_out_bits_data,
  output [15:0] io_out_bits_mask,
  output [47:0] io_out_bits_addr,
  output io_out_bits_vecValid,
  input  io_rightOutFire
);
  wire [242:0] out_bus;
  assign io_out_bits_vaddr = out_bus[242:193];
  assign io_out_bits_data = out_bus[192:65];
  assign io_out_bits_mask = out_bus[64:49];
  assign io_out_bits_addr = out_bus[48:1];
  assign io_out_bits_vecValid = out_bus[0:0];
  xs_PipelineConnect #(.DATA_WIDTH(243)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_vaddr, io_in_bits_data, io_in_bits_mask, io_in_bits_addr, io_in_bits_vecValid}),
    .io_out_ready(io_out_ready),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(1'b0)
  );
endmodule
