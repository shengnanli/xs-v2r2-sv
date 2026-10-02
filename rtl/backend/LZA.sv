// =============================================================================
// LZA —— 前导 1 位置图样（Leading Zero Anticipator 在加数 a=0 时的退化形态）
//
// 位置：fudian 整数转浮点闭包的最底层，只被 IntToFP_prenorm 例化。
// 输入 io_b 恒为「~原码」（负数的绝对值减 1），输出 io_f 供 CLZ 数前导零。
//
// 核心机制：io_f[i] = io_b[i] ^ io_b[i-1]（i >= 1），io_f[0] 恒 0。
// 相邻位异或标出「从最高位往下第一个位值发生变化的位置」：对 io_b = 幅值-1
// 而言，这个位置要么是幅值最高 1 本身，要么是它上面一位（幅值非 2 的幂时），
// 调用方（IntToFP_prenorm）用 one-mask 检测后一种情况并纠正。
// 纯组合，无寄存器、无子模块。
// =============================================================================
module xs_LZA_core (
  input  logic [63:0] operand_b,
  output logic [63:0] change_pattern
);
  assign change_pattern = {operand_b[63:1] ^ operand_b[62:0], 1'b0};
endmodule

module LZA (
  input  logic [63:0] io_b,
  output logic [63:0] io_f
);
  xs_LZA_core u_core (
    .operand_b     (io_b),
    .change_pattern(io_f)
  );
endmodule
