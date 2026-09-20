// =============================================================================
// CSA3_2.sv —— 3:2 进位保留加法器（全加器）单元
//
// 在哪一层：乘法器 ArrayMulDataModule 的 Wallace 压缩树最底层的算子。乘法阵列把
//   33 行 Booth 部分积按权重堆成 130 个"列"，再一层层把每列的高度压下来；压缩用
//   的算子只有三种：C22(2:2)、C32(3:2)、C53(5:3)。本文件是 3:2 那一种的通用核，
//   golden 里它以两个名字各出现一次：`CSA3_2`（被 C53 例化两次）与 `C32`
//   （被乘法阵列直接例化 84 次）。两者的 Chisel 定义同为 `CSA3_2(1)`，
//   golden 生成的模块体逐字相同，但**是两个独立模块**，故本仓也保持两个文件
//   （rtl/backend/C32.sv 是薄 wrapper，复用本文件的核，核体不复制）。
//
// 核心机制：进位保留加法。把 n 个同权重的 1 位加数压成 "和位 + 进位位"，
//   和位留在本列（权重 2^k），进位位进到高一列（权重 2^(k+1)）。不做进位传播，
//   所以延迟与位宽无关——这正是 Wallace 树比逐位进位链快的原因。
//   3 个输入 a,b,c → sum = a^b^c（本列），cout = ab | (a^b)c（进上一列）。
//
// 复位域：★本模块一个寄存器都没有★（纯组合，golden CSA3_2.sv / C32.sv 里
//   `always` 块计数 = 0，只有两条 assign）。既无 clock 也无 reset 端口。
//
// 设计源：src/main/scala/xiangshan/backend/fu/util/CSA.scala (class CSA3_2 / C32)
// golden 对照：G1-canonical/golden-rtl/CSA3_2.sv（与 C32.sv 模块体逐字相同）
// =============================================================================

// -----------------------------------------------------------------------------
// xs_CSA3_2_core —— 参数化 3:2 压缩器（WIDTH 条互不相干的全加器并排）
//
// Chisel 的 CSA3_2(len) 是"len 条独立的全加器"，位与位之间没有任何进位链——
// io.in(k) 的第 i 位只和 io.in(其它)的第 i 位作用。所以这里直接用整字的位运算
// 表达，语义与逐位展开完全一致（golden 的 len=1 实例自然退化成单条）。
// -----------------------------------------------------------------------------
module xs_CSA3_2_core #(
  parameter int WIDTH = 1          // golden 的 C32/CSA3_2 都是 WIDTH=1
) (
  input  logic [WIDTH-1:0] in_0,
  input  logic [WIDTH-1:0] in_1,
  input  logic [WIDTH-1:0] in_2,   // "cin"：与 in_0/in_1 同权重的第三个加数
  output logic [WIDTH-1:0] out_0,  // sum  —— 留在本列
  output logic [WIDTH-1:0] out_1   // cout —— 进到高一列
);
  // 先算半加器的两个中间量，全加器的 sum/cout 都由它们组合而成。
  // golden 把 a^b 单独提成了 wire a_xor_b（两处复用），这里同构。
  logic [WIDTH-1:0] a_xor_b;
  assign a_xor_b = in_0 ^ in_1;

  assign out_0 = a_xor_b ^ in_2;
  assign out_1 = (in_0 & in_1) | (a_xor_b & in_2);
endmodule

// -----------------------------------------------------------------------------
// CSA3_2 —— golden 同名 wrapper（C53 内部例化的那个名字）
// -----------------------------------------------------------------------------
module CSA3_2(
  input  io_in_0,
  input  io_in_1,
  input  io_in_2,
  output io_out_0,
  output io_out_1
);
  xs_CSA3_2_core #(.WIDTH(1)) u_core (
    .in_0  (io_in_0),
    .in_1  (io_in_1),
    .in_2  (io_in_2),
    .out_0 (io_out_0),
    .out_1 (io_out_1)
  );
endmodule
