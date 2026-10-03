// FDPrefetcherMonitor —— 反馈式预取（Feedback-Directed Prefetching）统计器：本配置下只剩端口壳
//
// 位置：DCacheImp 例化一份（fdpMonitor）。设计意图（Scala mem/prefetch/FDP.scala）：
//   以"refill 次数 8192"为一个区间，统计预取准确率（useful/total）、迟到率（late/total）、
//   污染率（pollution/demand_miss），区间结束时把本区间计数折半并入历史计数，
//   据此给预取器出 pf_ctrl（调深度/开关）。
//
// ★本配置下为什么是空壳★（golden FDPrefetcherMonitor.sv 现读）：
//   - `io.pf_ctrl := DontCare`，DCache 也不读它 —— 模块没有任何输出；
//   - 所有区间/历史计数器只被 XSPerfRolling / XSPerfAccumulate 这类性能计数读，
//     本配置下它们不产生硬件（无输出、无寄存器），firtool 全部删掉；
//   - io.refill、io.accuracy.total_prefetch、io.debugRolling 这些输入在 DCache 里
//     只连到被删掉的计数器，端口也跟着被删，只剩下面 10 个 1 位输入。
//   golden 体内只剩三个无人读的 PopCount 加法（性能计数的探针残留），同样没有观察者。
//   ⇒ 本模块没有任何可观测行为：0 输出、0 寄存器。重写件只保留与 golden 逐位一致的端口表。
//   形式上无比较点可证（与 StorePipe 同类），它的"正确"只由端口契约与父级 DCache 的
//   闭包证明（两侧都不产生观测）承担。

module FDPrefetcherMonitor(
  input io_accuracy_useful_prefetch_0,
  input io_accuracy_useful_prefetch_1,
  input io_accuracy_useful_prefetch_2,
  input io_timely_late_prefetch,
  input io_pollution_demand_miss_0,
  input io_pollution_demand_miss_1,
  input io_pollution_demand_miss_2,
  input io_pollution_cache_pollution_0,
  input io_pollution_cache_pollution_1,
  input io_pollution_cache_pollution_2
);
  // 无输出、无状态：全部输入在本配置下没有观察者（见文件头）。
endmodule
