// ImmExtractor_57 —— issue queue 使用的 I 型 12 位立即数提取器。
// 只有 immType=0xe 时立即数有效，此时把 imm[11:0] 符号扩展到 64 位；
// 其他类型输出零。高于 bit 11 的输入位不会影响结果。

module xs_ImmExtractor_57_core (
  input  logic [31:0] encoded_immediate,
  input  logic [3:0]  immediate_type,
  output logic [63:0] immediate
);
  always_comb begin
    if (immediate_type == 4'he)
      immediate = {{52{encoded_immediate[11]}}, encoded_immediate[11:0]};
    else
      immediate = 64'b0;
  end
endmodule


module ImmExtractor_57 (
  input  logic [31:0] io_in_imm,
  input  logic [3:0]  io_in_immType,
  output logic [63:0] io_out_imm
);
  xs_ImmExtractor_57_core u_core (
    .encoded_immediate(io_in_imm),
    .immediate_type   (io_in_immType),
    .immediate        (io_out_imm)
  );
endmodule
