// ImmExtractor_2 —— ImmExtractor 单态化变体 wrapper（核体见 ImmExtractor.sv 的 xs_imm_extractor_core）
// 位置：BypassNetwork 里整数分支/跳转执行单元（BRU/JMP）前的立即数还原，dataBits=64。
// 本变体参数：DATA_BITS=64，TYPE_EN=16'h001E
//   使能类型（见 golden 模块体只含 0x4/0x3/0x2/0x1 四个分支、其余 0）：
//   SB(1) U(2) UJ(3) I(4) => bit1|bit2|bit3|bit4 = 0x001E。
// 端口规模：2 输入 / 1 输出。golden 对照：G1-canonical/golden-rtl/ImmExtractor_2.sv

module ImmExtractor_2 (
  input  logic [31:0] io_in_imm,
  input  logic [3:0]  io_in_immType,
  output logic [63:0] io_out_imm
);
  xs_imm_extractor_core #(
    .DATA_BITS(64),
    .TYPE_EN  (16'h001E)   // IMM_SB(1) | IMM_U(2) | IMM_UJ(3) | IMM_I(4)
  ) u_core (
    .io_in_imm    (io_in_imm),
    .io_in_immType(io_in_immType),
    .io_out_imm   (io_out_imm)
  );
endmodule
