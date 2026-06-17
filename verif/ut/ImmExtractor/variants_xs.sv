// =============================================================================
// ImmExtractor 可读核的 UT 包装(改名避免与 golden 同名冲突)。
// 覆盖两个有代表性的 golden 变体:
//   ImmExtractor_xs    <-> golden ImmExtractor    (整数最小集 I/U/LUI32, 64 位)
//   ImmExtractor_12_xs <-> golden ImmExtractor_12 (全类型集, 128 位向量通路)
// 每个仅例化可读核并固化对应 TYPE_EN/DATA_BITS。
// =============================================================================

// --- 变体 1:整数最小集,dataBits=64 ---
module ImmExtractor_xs (
  input  logic [31:0] io_in_imm,
  input  logic [3:0]  io_in_immType,
  output logic [63:0] io_out_imm
);
  xs_imm_extractor_core #(.DATA_BITS(64), .TYPE_EN(16'h0814)) u_core (
    .io_in_imm(io_in_imm), .io_in_immType(io_in_immType), .io_out_imm(io_out_imm));
endmodule

// --- 变体 2:全类型集,dataBits=128(向量 IQ) ---
// golden ImmExtractor_12 含的类型(见其模块体):
//   0xF VRORVI, 0xD VSETIVLI, 0xC VSETVLI, 0xA OPIVIU, 0x9 OPIVIS,
//   0x4 I, 0x3 UJ, 0x2 U, 0x1 SB。掩码 = 对应 bit 置 1。
//   bit1|bit2|bit3|bit4|bit9|bit10|bit12|bit13|bit15
//   = 0x001E(1,2,3,4) | 0x0600(9,10) | 0x3000(12,13) | 0x8000(15) = 0xB61E
module ImmExtractor_12_xs (
  input  logic [31:0]  io_in_imm,
  input  logic [3:0]   io_in_immType,
  output logic [127:0] io_out_imm
);
  xs_imm_extractor_core #(.DATA_BITS(128), .TYPE_EN(16'hB61E)) u_core (
    .io_in_imm(io_in_imm), .io_in_immType(io_in_immType), .io_out_imm(io_out_imm));
endmodule
