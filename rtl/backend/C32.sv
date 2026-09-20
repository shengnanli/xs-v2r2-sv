// =============================================================================
// C32.sv —— 3:2 压缩器（全加器），Wallace 树里"某列恰好剩 3 个加数"时用的算子
//
// 在哪一层：ArrayMulDataModule 的压缩树算子之一，被直接例化 84 次
//   （本仓实测：golden ArrayMulDataModule.sv 里 C22×293 / C32×84 / C53×989）。
//
// 本变体的参数与规模：WIDTH=1（Chisel `class C32 extends CSA3_2(1)`），
//   3 个 1 位输入、2 个 1 位输出，纯组合，**零寄存器零子实例**，golden 模块体
//   只有 3 行（一个 wire + 两条 assign），`always` 块计数 = 0。
//
// ★为什么本文件只有 wrapper★：C32 与 CSA3_2 在 Chisel 里是同一个类的同一组参数
//   （`CSA3_2(1)`），golden 生成了两个模块名、模块体逐字相同。按本仓"值恒等不等于
//   可证等价、golden 是两个独立模块就保持两个"的规矩，这里不合并成一个模块；
//   但按"核体绝不复制"的家族规矩，逻辑核只写一份，放在 rtl/backend/CSA3_2.sv
//   （模块 xs_CSA3_2_core），本文件只做例化与端口对位。
//
// 设计源：src/main/scala/xiangshan/backend/fu/util/CSA.scala (class C32)
// golden 对照：G1-canonical/golden-rtl/C32.sv
// =============================================================================
module C32(
  input  io_in_0,
  input  io_in_1,
  input  io_in_2,
  output io_out_0,   // sum  —— 留在本列
  output io_out_1    // cout —— 进到高一列
);
  xs_CSA3_2_core #(.WIDTH(1)) u_core (
    .in_0  (io_in_0),
    .in_1  (io_in_1),
    .in_2  (io_in_2),
    .out_0 (io_out_0),
    .out_1 (io_out_1)
  );
endmodule
