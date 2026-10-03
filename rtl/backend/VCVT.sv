// VCVT.sv —— 向量浮点转换的一条通道壳（yunsuan VCVT(width=64)，纯连线）
// -----------------------------------------------------------------------------
// 在哪一层：VectorCvt 把 64 位源按元素拆成 4 条通道，每条通道是一个 VCVT 壳，壳里按宽度
//   例化真正的转换器。本壳是 width=64 的那种 ——
//   64 位通道（第 0 条）：CVT64_1，能处理 8/16/32/64 位元素。上层按 VectorCvt 的宽度译码给出
//   input1H / output1H（CVT64 用独热宽度选通道，不看 sew）。
// 机制：Scala 里就是 `io <> vcvtImpl.io` 一句；firtool 按实例把用不到的端口（isFpToVecInst /
//   isFround / isFcvtmod 恒 0、以及本宽度用不到的选择口）消掉，所以三种壳的端口表各不相同。
// 子模块：CVT64_1（本 lane 重写）。
// golden 对照：G1-canonical/golden-rtl/VCVT.sv
// =============================================================================

module VCVT(
  input         clock,
  input         reset,
  input         io_fire,
  input  [63:0] io_src,
  input  [7:0]  io_opType,
  input  [2:0]  io_rm,
  input  [3:0]  io_input1H,
  input  [3:0]  io_output1H,
  output [63:0] io_result,
  output [4:0]  io_fflags
);

  CVT64_1 vcvtImpl (
    .clock       (clock),
    .reset       (reset),
    .io_fire     (io_fire),
    .io_src      (io_src),
    .io_opType   (io_opType),
    .io_rm       (io_rm),
    .io_input1H  (io_input1H),
    .io_output1H (io_output1H),
    .io_result   (io_result),
    .io_fflags   (io_fflags)
  );

endmodule
