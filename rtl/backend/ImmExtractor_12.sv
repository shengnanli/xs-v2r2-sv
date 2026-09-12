// ImmExtractor_12 —— ImmExtractor 单态化变体 wrapper（核体见 ImmExtractor.sv）
// 本变体参数：DATA_BITS=128，TYPE_EN=16'hB61E
// 端口规模：2 输入 / 1 输出。家族共性与逻辑说明见核体文件头。

module ImmExtractor_12 (
  input  logic [31:0]  io_in_imm,
  input  logic [3:0]   io_in_immType,
  output logic [127:0] io_out_imm
);
  xs_imm_extractor_core #(.DATA_BITS(128), .TYPE_EN(16'hB61E)) u_core (
    .io_in_imm(io_in_imm), .io_in_immType(io_in_immType), .io_out_imm(io_out_imm));
endmodule
