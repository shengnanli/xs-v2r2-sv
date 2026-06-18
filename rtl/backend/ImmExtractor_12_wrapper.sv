// =============================================================================
// ImmExtractor_12 (wrapper) —— golden 同名顶层(向量 IQ 全类型集, dataBits=128)。
// 端口与 golden/chisel-rtl/ImmExtractor_12.sv 一致。
// 使能类型(见 golden 模块体):SB(1) U(2) UJ(3) I(4) OPIVIS(9) OPIVIU(A)
//   VSETVLI(C) VSETIVLI(D) VRORVI(F) => 掩码 0xB61E。
// =============================================================================
module ImmExtractor_12 (
  input  logic [31:0]  io_in_imm,
  input  logic [3:0]   io_in_immType,
  output logic [127:0] io_out_imm
);
  xs_imm_extractor_core #(.DATA_BITS(128), .TYPE_EN(16'hB61E)) u_core (
    .io_in_imm(io_in_imm), .io_in_immType(io_in_immType), .io_out_imm(io_out_imm));
endmodule
