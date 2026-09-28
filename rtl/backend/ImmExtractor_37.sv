// ImmExtractor_37 —— ImmExtractor 单态化变体 wrapper（核体见 ImmExtractor.sv 的 xs_imm_extractor_core）
// 位置：BypassNetwork 里 vset 类执行单元前的立即数还原，dataBits=128（向量数据通路宽度）。
// 本变体参数：DATA_BITS=128，TYPE_EN=16'h3000
//   使能类型（见 golden 模块体只含 0xD/0xC 两个分支、其余 0，高 64 位恒 0）：
//   VSETVLI(C) VSETIVLI(D) => bit12|bit13 = 0x3000。
// 端口规模：2 输入 / 1 输出。golden 对照：G1-canonical/golden-rtl/ImmExtractor_37.sv

module ImmExtractor_37 (
  input  logic [31:0]  io_in_imm,
  input  logic [3:0]   io_in_immType,
  output logic [127:0] io_out_imm
);
  xs_imm_extractor_core #(
    .DATA_BITS(128),
    .TYPE_EN  (16'h3000)   // IMM_VSETVLI(C) | IMM_VSETIVLI(D)
  ) u_core (
    .io_in_imm    (io_in_imm),
    .io_in_immType(io_in_immType),
    .io_out_imm   (io_out_imm)
  );
endmodule
