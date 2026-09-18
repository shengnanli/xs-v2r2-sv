// =============================================================================
// C22.sv —— 2:2 压缩器（半加器），Wallace 树里"某列只剩 2 个加数"时用的算子
//
// 在哪一层：ArrayMulDataModule 的压缩树算子之一，被直接例化 293 次
//   （本仓实测：golden ArrayMulDataModule.sv 里 C22×293 / C32×84 / C53×989）。
//
// 核心机制：进位保留（不传播进位）。两个同权重的 1 位加数压成
//   sum = a^b（留在本列，权重 2^k）与 cout = a&b（进到高一列，权重 2^(k+1)）。
//
// 本变体的参数与规模：WIDTH=1（Chisel `class C22 extends CSA2_2(1)`），
//   2 个 1 位输入、2 个 1 位输出。★纯组合，一个寄存器都没有★——golden C22.sv
//   里 `always` 块计数 = 0，模块体只有两条 assign，没有 clock/reset 端口。
//
// 设计源：src/main/scala/xiangshan/backend/fu/util/CSA.scala (class CSA2_2 / C22)
// golden 对照：G1-canonical/golden-rtl/C22.sv
// =============================================================================

// -----------------------------------------------------------------------------
// xs_CSA2_2_core —— 参数化 2:2 压缩器（WIDTH 条互不相干的半加器并排）
// Chisel 的 CSA2_2(len) 位与位之间没有进位链，故整字位运算与逐位展开等价。
// -----------------------------------------------------------------------------
module xs_CSA2_2_core #(
  parameter int WIDTH = 1          // golden 的 C22 是 WIDTH=1
) (
  input  logic [WIDTH-1:0] in_0,
  input  logic [WIDTH-1:0] in_1,
  output logic [WIDTH-1:0] out_0,  // sum  —— 留在本列
  output logic [WIDTH-1:0] out_1   // cout —— 进到高一列
);
  assign out_0 = in_0 ^ in_1;
  assign out_1 = in_0 & in_1;
endmodule

// -----------------------------------------------------------------------------
// C22 —— golden 同名 wrapper
// -----------------------------------------------------------------------------
module C22(
  input  io_in_0,
  input  io_in_1,
  output io_out_0,
  output io_out_1
);
  xs_CSA2_2_core #(.WIDTH(1)) u_core (
    .in_0  (io_in_0),
    .in_1  (io_in_1),
    .out_0 (io_out_0),
    .out_1 (io_out_1)
  );
endmodule
