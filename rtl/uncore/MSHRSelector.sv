// =============================================================================
//  MSHRSelector —— L2 缓存 MSHR 空闲槽优先分配器 (可读重写核 xs_MSHRSelector_core)
// -----------------------------------------------------------------------------
//  纯组合叶子，无寄存器、无子模块、无 SRAM。
//
//  功能 (源自 coupledL2/tl2chi/MSHRCtl.scala 内部类 MSHRSelector)：
//    在 16 个 MSHR 条目里，按下标从低到高取第一个 idle(空闲) 的槽，
//    输出 (1 << 该下标) 的 16 位 one-hot 分配指针。
//
//  对外只暴露 io_idle_0..14 共 15 个 idle 输入：第 16 个槽 (下标 15) 在本次
//  单态化中被 firtool 判定恒空闲 (idle[15]=1)，因此当低 15 个槽都不空闲时，
//  优先选择器一定落到下标 15，输出 16'h8000，相当于一个"兜底空闲槽"。
//
//  实现说明：
//    本核把 idle[15] 显式置 1，凑齐 16 位 idle 向量，再用一个标准的
//    "lowest-set-bit (LSB isolation)" 取最低位 1：
//        oh = idle & (~idle + 1)
//    该式天然就是 ParallelPriorityMux((idle_i, 1<<i)) 的低优先结果。
//    由于 idle[15] 恒 1，向量必非全 0，oh 必为合法 one-hot，无需额外兜底。
// =============================================================================
module xs_MSHRSelector_core
  import mshrselector_pkg::*;
(
  input  logic                  io_idle_0,
  input  logic                  io_idle_1,
  input  logic                  io_idle_2,
  input  logic                  io_idle_3,
  input  logic                  io_idle_4,
  input  logic                  io_idle_5,
  input  logic                  io_idle_6,
  input  logic                  io_idle_7,
  input  logic                  io_idle_8,
  input  logic                  io_idle_9,
  input  logic                  io_idle_10,
  input  logic                  io_idle_11,
  input  logic                  io_idle_12,
  input  logic                  io_idle_13,
  input  logic                  io_idle_14,
  output logic [MSHRS_ALL-1:0]  io_out_bits
);

  // ---------------------------------------------------------------------------
  //  组装 16 位 idle 向量：低 15 位为外部输入，下标 15 恒空闲 (idle[15]=1)。
  // ---------------------------------------------------------------------------
  logic [MSHRS_ALL-1:0] idle;
  always_comb begin
    idle[0]  = io_idle_0;
    idle[1]  = io_idle_1;
    idle[2]  = io_idle_2;
    idle[3]  = io_idle_3;
    idle[4]  = io_idle_4;
    idle[5]  = io_idle_5;
    idle[6]  = io_idle_6;
    idle[7]  = io_idle_7;
    idle[8]  = io_idle_8;
    idle[9]  = io_idle_9;
    idle[10] = io_idle_10;
    idle[11] = io_idle_11;
    idle[12] = io_idle_12;
    idle[13] = io_idle_13;
    idle[14] = io_idle_14;
    idle[15] = 1'b1;        // golden: idle[15] 被折叠为常量 true (兜底空闲槽)
  end

  // ---------------------------------------------------------------------------
  //  取最低位 1 的 one-hot：oh = idle & (-idle)。
  //  即 ParallelPriorityMux 的低下标优先结果；idle[15]=1 保证结果非全 0。
  // ---------------------------------------------------------------------------
  assign io_out_bits = idle & (~idle + {{(MSHRS_ALL-1){1'b0}}, 1'b1});

endmodule
