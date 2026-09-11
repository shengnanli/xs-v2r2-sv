// ImmExtractor_12 —— ImmExtractor 单态化变体 wrapper（核体见 ImmExtractor.sv）

module ImmExtractor_12 (
  input  logic [31:0]  io_in_imm,
  input  logic [3:0]   io_in_immType,
  output logic [127:0] io_out_imm
);
  xs_imm_extractor_core #(.DATA_BITS(128), .TYPE_EN(16'hB61E)) u_core (
    .io_in_imm(io_in_imm), .io_in_immType(io_in_immType), .io_out_imm(io_out_imm));
endmodule
