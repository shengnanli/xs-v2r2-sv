// =============================================================================
// C53.sv —— 5:3 压缩器，Wallace 树里的主力算子（乘法阵列中例化 989 次）
//
// 在哪一层：ArrayMulDataModule 的压缩树算子之一。压缩树把每一列按 4 个一组切块，
//   每个满 4 的块配一个 C53：4 个本列加数 + 1 个来自低一列的进位（cin）→
//   1 个本列和位 + 2 个进上一列的进位。剩下不足 4 的尾块才用 C22/C32 或直通。
//   本仓实测 golden ArrayMulDataModule.sv 例化 C22×293 / C32×84 / C53×989。
//
// 核心机制：**它不是一个真正的 5:3 计数器，而是两个全加器串起来的链**
//   （Chisel `class CSA5_3` 就是 `Array.fill(2)(Module(new CSA3_2(len)))`）：
//     FA0: (in_0,in_1,in_2) → s0(本列), c0(进位)
//     FA1: (s0,  in_3,in_4) → s1(本列), c1(进位)
//     输出 out_0 = s1（和位，留在本列）
//          out_1 = c0、out_2 = c1（两个进位，都进到高一列）
//   5 个权重 2^k 的输入压成 1 个 2^k + 2 个 2^(k+1)，位数守恒（5 = 1 + 2 + 2）。
//   ★两个进位 out_1/out_2 在阵列里去向不同★：out_1(cout1) 作为**同一压缩层里
//   下一列**某个 C53 的第 5 个输入（cin），out_2(cout2) 则挂到**下一层**高一列的
//   列尾——见 rtl/backend/ArrayMulDataModule.sv §4 的说明。
//
// 复位域：★纯组合，一个寄存器都没有★（golden C53.sv `always` 块计数 = 0，
//   模块体只有一条 wire 和两个子实例；无 clock/reset 端口）。
//
// ★子实例★：golden C53 例化 `CSA3_2` 两次（实例名 CSA3_2 / CSA3_2_1）。本仓不把
//   它黑盒化：可读核直接例化两份 xs_CSA3_2_core（核体见 rtl/backend/CSA3_2.sv），
//   与 golden 的两实例一一对应，结构照抄不合并。
//
// 设计源：src/main/scala/xiangshan/backend/fu/util/CSA.scala (class CSA5_3 / C53)
// golden 对照：G1-canonical/golden-rtl/C53.sv（+ CSA3_2.sv）
// =============================================================================

// -----------------------------------------------------------------------------
// xs_CSA5_3_core —— 参数化 5:3 压缩器（两级全加器链）
// -----------------------------------------------------------------------------
module xs_CSA5_3_core #(
  parameter int WIDTH = 1          // golden 的 C53 是 WIDTH=1
) (
  input  logic [WIDTH-1:0] in_0,
  input  logic [WIDTH-1:0] in_1,
  input  logic [WIDTH-1:0] in_2,
  input  logic [WIDTH-1:0] in_3,
  input  logic [WIDTH-1:0] in_4,   // 阵列里这一路接低一列的 cout1（没有则接常数 0）
  output logic [WIDTH-1:0] out_0,  // 和位，留在本列
  output logic [WIDTH-1:0] out_1,  // 第一级进位 → 同层下一列的 cin
  output logic [WIDTH-1:0] out_2   // 第二级进位 → 下一层高一列的列尾
);
  // 第一级：压 in_0/in_1/in_2，和位 fa0_sum 再喂给第二级。
  logic [WIDTH-1:0] fa0_sum;

  xs_CSA3_2_core #(.WIDTH(WIDTH)) u_fa0 (
    .in_0  (in_0),
    .in_1  (in_1),
    .in_2  (in_2),
    .out_0 (fa0_sum),
    .out_1 (out_1)
  );

  // 第二级：把第一级的和位与剩下两路（in_3 与 cin）再压一次。
  xs_CSA3_2_core #(.WIDTH(WIDTH)) u_fa1 (
    .in_0  (fa0_sum),
    .in_1  (in_3),
    .in_2  (in_4),
    .out_0 (out_0),
    .out_1 (out_2)
  );
endmodule

// -----------------------------------------------------------------------------
// C53 —— golden 同名 wrapper
// -----------------------------------------------------------------------------
module C53(
  input  io_in_0,
  input  io_in_1,
  input  io_in_2,
  input  io_in_3,
  input  io_in_4,
  output io_out_0,
  output io_out_1,
  output io_out_2
);
  xs_CSA5_3_core #(.WIDTH(1)) u_core (
    .in_0  (io_in_0),
    .in_1  (io_in_1),
    .in_2  (io_in_2),
    .in_3  (io_in_3),
    .in_4  (io_in_4),
    .out_0 (io_out_0),
    .out_1 (io_out_1),
    .out_2 (io_out_2)
  );
endmodule
