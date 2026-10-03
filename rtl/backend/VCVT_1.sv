// VCVT_1.sv —— 向量浮点转换的一条通道壳（yunsuan VCVT(width=32)，纯连线）
// -----------------------------------------------------------------------------
// 在哪一层：VectorCvt 把 64 位源按元素拆成 4 条通道，每条通道是一个 VCVT 壳，壳里按宽度
//   例化真正的转换器。本壳是 width=32 的那种 ——
//   32 位通道（第 1 条）：CVT32，处理不超过 32 位的元素；它自己按 sew/opType 译码，
//   所以壳上没有 input1H / output1H，而多一个 sew。
// 机制：Scala 里就是 `io <> vcvtImpl.io` 一句；firtool 按实例把用不到的端口（isFpToVecInst /
//   isFround / isFcvtmod 恒 0、以及本宽度用不到的选择口）消掉，所以三种壳的端口表各不相同。
// 子模块：CVT32（本 lane 重写）。
// golden 对照：G1-canonical/golden-rtl/VCVT_1.sv
// =============================================================================

module VCVT_1(
  input         clock,
  input         reset,
  input         io_fire,
  input  [31:0] io_src,
  input  [7:0]  io_opType,
  input  [1:0]  io_sew,
  input  [2:0]  io_rm,
  output [31:0] io_result,
  output [4:0]  io_fflags
);

  CVT32 vcvtImpl (
    .clock     (clock),
    .reset     (reset),
    .io_fire   (io_fire),
    .io_src    (io_src),
    .io_opType (io_opType),
    .io_sew    (io_sew),
    .io_rm     (io_rm),
    .io_result (io_result),
    .io_fflags (io_fflags)
  );

endmodule
