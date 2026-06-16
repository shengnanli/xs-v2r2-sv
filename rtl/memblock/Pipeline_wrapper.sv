// 自动生成：scripts/gen_pipeline.py —— 勿手改
module Pipeline(
  input clock,
  input reset,
  output io_in_ready,
  input io_in_valid,
  input [47:0] io_in_bits_paddr,
  input [1:0] io_in_bits_alias,
  input io_in_bits_confidence,
  input io_in_bits_is_store,
  input [2:0] io_in_bits_pf_source_value,
  input io_out_ready,
  output io_out_valid,
  output [47:0] io_out_bits_paddr,
  output [1:0] io_out_bits_alias,
  output io_out_bits_confidence,
  output io_out_bits_is_store,
  output [2:0] io_out_bits_pf_source_value
);
  xs_Pipeline_core u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits_paddr(io_in_bits_paddr),
    .io_in_bits_alias(io_in_bits_alias),
    .io_in_bits_confidence(io_in_bits_confidence),
    .io_in_bits_is_store(io_in_bits_is_store),
    .io_in_bits_pf_source_value(io_in_bits_pf_source_value),
    .io_out_ready(io_out_ready),
    .io_out_valid(io_out_valid),
    .io_out_bits_paddr(io_out_bits_paddr),
    .io_out_bits_alias(io_out_bits_alias),
    .io_out_bits_confidence(io_out_bits_confidence),
    .io_out_bits_is_store(io_out_bits_is_store),
    .io_out_bits_pf_source_value(io_out_bits_pf_source_value)
  );
endmodule
