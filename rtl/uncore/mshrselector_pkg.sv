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
