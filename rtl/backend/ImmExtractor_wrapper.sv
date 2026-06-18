// =============================================================================
// ImmExtractor (wrapper) —— golden 同名顶层,端口与 golden/chisel-rtl/ImmExtractor.sv 一致。
// -----------------------------------------------------------------------------
// 该 golden 变体对应整数 IQ 的最小立即数集合:immTypeSet = {IMM_I, IMM_U, IMM_LUI32},
// dataBits = 64。见 golden 模块体只含 0xB(LUI32)/0x4(I)/0x2(U) 三个分支、其余 0。
//
// 用 TYPE_EN 掩码把可读核裁剪到这三种类型:bit2(U) | bit4(I) | bit11(LUI32) = 0x0814。
// 本层是机械的端口适配 + 参数固化,供 Formality 等价比对与系统级替换。
// =============================================================================
module ImmExtractor (
  input  logic [31:0] io_in_imm,
  input  logic [3:0]  io_in_immType,
  output logic [63:0] io_out_imm
);

  xs_imm_extractor_core #(
    .DATA_BITS(64),
    .TYPE_EN  (16'h0814)   // IMM_U(2) | IMM_I(4) | IMM_LUI32(11)
  ) u_core (
    .io_in_imm    (io_in_imm),
    .io_in_immType(io_in_immType),
    .io_out_imm   (io_out_imm)
  );

endmodule
