// =============================================================================
//  storepipe_pkg —— StorePipe(DCache store 探测流水) 可读核的类型/参数包
// -----------------------------------------------------------------------------
//  设计意图来源：XiangShan/src/main/scala/xiangshan/cache/dcache/storepipe/StorePipe.scala
//  官方 reference：G0-StorePipe-observable-v1 canonical-derivative(codex_0088 §3)。
//
//  ⚠️ 本顶层配置(KunmingHu V2R2)下, 全芯片 firtool 会因 DCache 把 StorePipe 所有输出
//     悬空(EnableStorePrefetchAtIssue=false)而跨层 DCE 掉整个功能锥, golden StorePipe.sv
//     退化为 5 行空壳。codex_0088 §3 批准: 从同一冻结 G0 `SimTop.fir` 的 production
//     pre-DCE StorePipe FIRRTL 机械派生的 canonical-derivative(锁定 firtool-1.62.1 +
//     G0 flags: disallowLocalVariables 等) 作官方 reference。该 derivative 保留完整
//     可观测面(50 output leaves + 6 perf probes) 与真实 s1/s2 双 RegNext 流水寄存器。
//
//  可读核 xs_StorePipe_core 对齐该 derivative 的端口/shape/reset/双 RegNext 语义:
//     - 可观测面 = 36 output leaves + 6 perf probes(与 derivative 逐位一致比较)。
//     - 14 个 invalidate-only leaves = UNSPECIFIED_BY_SOURCE(Chisel `:= DontCare`),
//       不具体化为 0, 不 dont_verify, 从比较面排除(见 StorePipe.sv 头注)。
//     - 寄存器 exactly 11(无 shadow DFF; G0 flags 下 automatic-local 全 hoist 成组合
//       wire, 不成 flop), 且 init-free(无 async reset)。
// =============================================================================
package storepipe_pkg;

  // ---- DCache 几何参数(同 LoadPipe)------------------------------------------
  localparam int N_WAYS    = 4;       // 组相联路数
  localparam int IDX_BITS  = 8;       // set 索引 vaddr[13:6]
  localparam int TAG_BITS  = 36;      // 物理 tag paddr[47:12]

  // instrtype: 硬件预取来源编码(DCACHE_PREFETCH_SOURCE)
  localparam logic [3:0] PREFETCH_SOURCE = 4'h3;

  // ---- TileLink ClientStates(2 位 coh 状态), 与 golden Metadata.scala 编码一致 ------
  //  Nothing=0 Branch=1 Trunk=2 Dirty=3
  typedef enum logic [1:0] {
    COH_NOTHING = 2'h0,   // 无副本
    COH_BRANCH  = 2'h1,   // 共享只读
    COH_TRUNK   = 2'h2,   // 独占可写
    COH_DIRTY   = 2'h3    // 独占已改
  } coh_e;

  // ---- s1 流水级寄存的请求上下文(derivative: s1_req_cmd/vaddr/instrtype)-----------
  typedef struct packed {
    logic [4:0]  cmd;        // store 访问命令
    logic [49:0] vaddr;      // 虚拟地址
    logic [3:0]  instrtype;  // 来源类型(==PREFETCH_SOURCE 表示硬件预取)
  } s1_req_t;

endpackage
