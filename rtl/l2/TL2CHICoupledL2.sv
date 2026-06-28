// 手写核 + 自动生成机械连线(scripts/gen_coupledl2.py 接管 ports/decls/inst/outassign/
// wrapper/stub/UT;glue 由该脚本以「具名可读重写」方式发出)。
// =====================================================================
// xs_TL2CHICoupledL2_core —— 香山 V2R2 L2 缓存主体(TL2CHICoupledL2)装配可读核。
//
// TL2CHICoupledL2(coupledL2 仓库,TileLink<->CHI 桥 + 多 bank L2 cache 阵列)是 L2
// cache 的**主体装配**:北侧接 L1/core 集群(TileLink client 节点 auto_in_0..3 +
// MMIO 桥),南侧接 L3/home node(CHI 五通道 io_chi_*)。本层把 4 个 L2 slice、
// prefetcher、各通道仲裁器、CHI 链路监视、MBIST 自测分发拼成整体,并把 L2 边界拉直。
//
// 子模块(23 种类型 / 29 个实例,**本层全部 golden 黑盒**,UT/FM 两侧共用):
//   Slice/Slice_1/Slice_2/Slice_3 ×4  L2 slice(每 bank 一个:RequestArb/MainPipe/
//                       Directory/DataStorage/MSHR/snoop filter,真正的 cache 流水)。
//   Pipeline_2/Pipeline_3 ×8          每 slice 的 train/resp prefetch 流水。
//   Prefetcher ×1                     预取器。     MMIOBridge ×1  MMIO 请求桥。
//   FastArbiter_1/_2/_27/_28/_29 ×5   prefetch train/resp、CHI txrsp/txdat、pCrdGrant 仲裁。
//   RRArbiterInit_18 ×1               CHI txreq 轮询仲裁。
//   Arbiter4_L2CacheErrorInfo ×1      4 slice ECC error 汇聚。
//   Arbiter4_L2ToL1Hint ×1            4 slice L2->L1 hint 汇聚。
//   Pipeline_10/Pipeline_11 ×2        hint 输出打拍(hintPipe1/2)。
//   TopDownMonitor ×1                 性能/调试监视(l2MissMatch)。
//   L2Cache(mbistPl) ×1 / MbistIntfL2 ×1  MBIST 流水分发 + 接口。
//   Queue72_CoupledL2Imp_Anon ×1      pCrdGrant 信息队列(CHI P-Credit)。
//   LinkMonitor ×1                    CHI 链路层监视(linkactive/lcredit/flit)。
//
// 本层「顶层 glue」(从 firtool 意图重写为具名可读,见 coupledl2_glue.svh)分 6 组:
//   (1) MBIST 广播常量(全 0,未接,dontTouch);
//   (2) L2->L1 hint 与各 slice D 通道发射仲裁(hintFire / sliceCanFire / allCanFire
//       延迟链,把 hint 发射拍让位给被选中 slice 的 GrantData);
//   (3) Grant 数据节拍计数 + hint 命中精度探针(dontTouch 统计);
//   (4) 48 路性能计数 2 级打拍(4 slice × 12 事件,RegNext∘RegNext;事件 #2 恒 0);
//   (5) l2Miss 汇聚打拍;
//   (6) CHI rx 五通道按 bank 路由译码 + P-Credit grant 流水。
//
// golden TL2CHICoupledL2.sv 全文 6469 行,firtool 产出 131 reg / 2 always / 80 assign,
// 含 71 个 `_REG_<n>` 流水寄存器、20 个 `_T_<n>` + 6 个裸 `_T`、2 个 `_GEN_<n>` 匿名
// 临时名——本核全部重写为具名信号 + 数组 + generate-for,套壳闸门(`_REG_<n>`/
// `_T_<n>`/`_GEN_`/`io_*_n_m`/RANDOMIZE,去注释)= 0。
//
// 类型/参数见 coupledl2_pkg.sv;子模块黑盒输出/互联网见 coupledl2_decls.svh;
// 顶层 glue 见 coupledl2_glue.svh;子模块例化见 coupledl2_inst.svh;
// 顶层 io/auto 输出 + probe assign 见 coupledl2_outassign.svh。
// =====================================================================
import coupledl2_pkg::*;

module xs_TL2CHICoupledL2_core (
  input clock,
  input reset,
`include "coupledl2_ports.svh"
);

  // ===================================================================
  // 子模块黑盒输出/互联网声明(供 glue/inst/outassign 消费)。
  // ===================================================================
`include "coupledl2_decls.svh"

  // ===================================================================
  // 顶层 glue(从 firtool 意图重写为具名可读:hint/D 仲裁、grant 计数、perf 打拍、
  // l2Miss 汇聚、CHI rx bank 路由、P-Credit grant 流水)。
  // ===================================================================
`include "coupledl2_glue.svh"

  // ===================================================================
  // 29 子模块黑盒例化 + 引脚连核内具名信号/互联网(纯机械,gen_coupledl2.py 生成)。
  // ===================================================================
`include "coupledl2_inst.svh"

  // ===================================================================
  // 顶层 io/auto 输出 assign + _probe 探针(纯连线 / 位选 / bank 号插入 / 打拍输出)。
  // ===================================================================
`include "coupledl2_outassign.svh"

endmodule
