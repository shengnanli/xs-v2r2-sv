// =============================================================================
//  MSHRSelector 类型/常量包 (mshrselector_pkg)
// -----------------------------------------------------------------------------
//  MSHRSelector 是 coupledL2 (香山 L2 缓存) MSHRCtl 内的一个纯组合优先选择器，
//  负责为新进入 L2 的 miss 请求分配一个空闲的 MSHR 条目 (miss status holding
//  register)，输出 one-hot 的分配指针。
//
//  Scala 设计意图 (coupledL2/tl2chi/MSHRCtl.scala 的内部类 MSHRSelector)：
//      io.out.valid := ParallelOR(io.idle)
//      io.out.bits  := ParallelPriorityMux(io.idle.zipWithIndex.map {
//                        case (b, i) => (b, 1.U << i)
//                      })
//  即：在所有 idle (空闲) 的 MSHR 中，按下标从低到高取**第一个**空闲槽，
//  输出 (1 << 该下标) 的 one-hot 编码；该 one-hot 直接驱动各 MSHR 的
//  alloc.valid，并经 OHToUInt 转成分配指针 mshr_alloc_ptr。
//
//  本实例 mshrsAll = cacheParams.mshrs = 16 (共 16 个 MSHR 条目，输出 16 位)。
//  firtool 在本次单态化中把 idle[15] 折叠成了常量 true，故对外只暴露
//  io_idle_0..14 共 15 个输入；当 idle_0..14 全为 0 (无低位空闲) 时，
//  优先选择器落到下标 15 这一"兜底空闲槽"，输出 16'h8000。
//
//  注意 golden 顶层没有 io_out_valid 端口 (ParallelOR 的结果在上层用不到、
//  被 firtool 消除)，对外只保留 io_out_bits。
// =============================================================================
package mshrselector_pkg;
  // ---- MSHR 条目总数 / 输出 one-hot 位宽 (cacheParams.mshrs) ----
  localparam int MSHRS_ALL = 16;

  // ---- 对外暴露的 idle 输入个数 (idle[15] 被 firtool 折叠为常量 true) ----
  localparam int IDLE_INPUTS = 15;
endpackage

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

// 自动生成：xs-v2r2-sv/scripts/gen_mshrselector.py —— 该脚本未移植到本轮(它按上一轮规范产出独立 _wrapper.sv)，本文件手工维护

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module MSHRSelector(
  input io_idle_0,
  input io_idle_1,
  input io_idle_2,
  input io_idle_3,
  input io_idle_4,
  input io_idle_5,
  input io_idle_6,
  input io_idle_7,
  input io_idle_8,
  input io_idle_9,
  input io_idle_10,
  input io_idle_11,
  input io_idle_12,
  input io_idle_13,
  input io_idle_14,
  output [15:0] io_out_bits
);
  xs_MSHRSelector_core u_core (
    .io_idle_0(io_idle_0),
    .io_idle_1(io_idle_1),
    .io_idle_2(io_idle_2),
    .io_idle_3(io_idle_3),
    .io_idle_4(io_idle_4),
    .io_idle_5(io_idle_5),
    .io_idle_6(io_idle_6),
    .io_idle_7(io_idle_7),
    .io_idle_8(io_idle_8),
    .io_idle_9(io_idle_9),
    .io_idle_10(io_idle_10),
    .io_idle_11(io_idle_11),
    .io_idle_12(io_idle_12),
    .io_idle_13(io_idle_13),
    .io_idle_14(io_idle_14),
    .io_out_bits(io_out_bits)
  );
endmodule
