// ============================================================================
// coupledl2_pkg —— 香山 V2R2 L2 缓存主体(TL2CHICoupledL2)装配层类型与参数包
// ----------------------------------------------------------------------------
// 设计意图来源:coupledL2 仓库 TL2CHICoupledL2 / CoupledL2Imp(TileLink<->CHI 桥
// + 多 bank L2 cache 阵列)。本层是 L2 cache 的**主体装配**:把 4 个 L2 slice
// (cache 流水:RequestArb/MainPipe/Directory/DataStorage/MSHR/snoop filter)与
// prefetcher、MMIO 桥、CHI 链路监视、各通道仲裁器、MBIST 自测分发拼起来。
//
//   · 北侧(TileLink,接 L1/core 集群):auto_in_0..3 client 节点 + mmioBridge。
//   · 南侧(CHI,接 L3/home node):io_chi_* 五通道(REQ/RSP/DAT/SNP + 链路层)。
//
// 子模块(23 种类型 / 29 个实例,本层全部 golden 黑盒,UT/FM 两侧共用):
//   Slice / Slice_1 / Slice_2 / Slice_3  ×4   L2 slice(每 bank 一个,真正的
//                         cache 流水 + 目录 + 数据 + MSHR;每个 ~480 行)。
//   Pipeline_2 / Pipeline_3              ×8   每 slice 的 train/resp prefetch 流水。
//   Prefetcher                           ×1   预取器(SMS/BOP 等)。
//   MMIOBridge                           ×1   MMIO(uncacheable)请求桥。
//   FastArbiter_1/_2/_27/_28/_29         ×5   prefetch train/resp、CHI txrsp/txdat、
//                                             pCrdGrant 的快速仲裁器。
//   RRArbiterInit_18                     ×1   CHI txreq 轮询仲裁。
//   Arbiter4_L2CacheErrorInfo            ×1   4 slice 的 ECC error 汇聚仲裁。
//   Arbiter4_L2ToL1Hint                  ×1   4 slice 的 L2->L1 hint 汇聚仲裁。
//   Pipeline_10 / Pipeline_11            ×2   hint 输出打拍流水(hintPipe1/2)。
//   TopDownMonitor                       ×1   性能/调试监视(l2MissMatch)。
//   L2Cache(mbistPl)                     ×1   MBIST 流水分发(自测内存树)。
//   MbistIntfL2                          ×1   MBIST 接口适配。
//   Queue72_CoupledL2Imp_Anon            ×1   pCrdGrant 信息队列(CHI P-Credit)。
//   LinkMonitor                          ×1   CHI 链路层监视(linkactive/lcredit/flit)。
//
// 本层属于「顶层 glue」的真实时序/组合逻辑(从 firtool 意图重写为具名可读,见
// coupledl2_glue.svh):
//   (1) L2->L1 hint 与各 slice D 通道发射仲裁(hintFire / sliceCanFire / allCanFire
//       延迟链,把 hint 发射拍让位给被选中 slice 的 GrantData);
//   (2) Grant 数据节拍计数 + hint 命中精度探针(dontTouch 统计);
//   (3) 48 路性能计数 2 级打拍(4 slice × 12 事件,RegNext∘RegNext);
//   (4) l2Miss 汇聚打拍(io.l2Miss := RegNext(OR(各 slice l2Miss)));
//   (5) CHI rx 五通道按 bank(txnID[10:9] / snp addr[4:3])路由译码;
//   (6) P-Credit grant 流水(rxrsp PCrdGrant -> pCrdGrantQueue)+ grant 计数。
//
// golden TL2CHICoupledL2.sv 全文 6469 行,firtool 产出 131 个 reg / 2 个 always /
// 80 条 assign,含 71 个 `_REG_<n>` 流水寄存器、20 个 `_T_<n>` / 6 个裸 `_T`、2 个
// `_GEN_<n>` 匿名临时名——本层把它们全部重写为具名信号 + 数组 + generate-for。
//
// 子模块端口/CHI 位宽巨大,全部从 golden wire 声明收割到 coupledl2_decls.svh,
// 无需在本包重复声明。本包仅放装配结构常量(作文档/可读性)。
// ============================================================================
package coupledl2_pkg;

  // ---- L2 装配结构常量(来自 CoupledL2 参数,仅作文档/可读性)----
  localparam int BANKS      = 4;   // L2 bank 数 = slice 实例数(slices_0..3)。
  localparam int L1_HINT_SRC_LO = 6'h24;  // L2->L1 hint 的有效 sourceId 上界(< 0x24)。
  localparam int PERF_EVENTS = 48; // 顶层 perf 输出路数 = 4 slice × 12 事件。

endpackage
