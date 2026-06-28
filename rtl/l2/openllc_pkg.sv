// ============================================================================
// openllc_pkg —— 香山 V2R2 外挂 L3 缓存(OpenLLC)装配层类型与参数包
// ----------------------------------------------------------------------------
// 设计意图来源:openLLC/src/main/scala/openLLC/OpenLLC.scala(class OpenLLC)
//
// OpenLLC 是香山外挂的**独立 L3 缓存 IP**——一个 CHI 协议的 home node(归属节点)。
// 它把若干 LLC slice(cache 流水 + 目录 + 数据 + snoop filter)与一圈 CHI 互联/链路
// 器件拼起来:
//   · 北侧(RN,Request Node):接 core 集群,经 CHI 收发请求/响应/数据/snoop。
//   · 南侧(SN,Subordinate Node):接内存(NoSnp 端口),把 miss 的访存请求发往内存。
//
// 子模块(8 种类型 / 11 个实例,本层 golden 黑盒,UT/FM 两侧共用):
//   Slice_4          ×4   LLC slice。banks=4,每 bank 一个。slice 内含 RequestArb /
//                         MainPipe / Directory / DataStorage / MSHR / snoop filter,
//                         是 L3 真正的 cache 流水与目录/数据存储。
//   RNXbar           ×1   RN 侧 CHI 交叉开关:把各 RN 的 cacheable 请求按地址(bank)
//                         路由到对应 slice;并回收 slice 的 snpMask。
//   SNXbar           ×1   SN 侧 CHI 交叉开关:把各 slice 的访存请求汇聚到内存侧。
//   MMIODiverger     ×1   按地址把每个 RN 的流量分流为 cacheable(进 rnXbar/slice)
//                         与 uncacheable(MMIO,绕过缓存直送 mmioMerger)。
//   MMIOMerger       ×1   把 cacheable(snXbar 出)与 uncacheable(MMIO)两路合并送 SN。
//   RNLinkMonitor    ×1   RN 侧 CHI 链路层监视:linkactive 握手 / lcredit 信用流控 /
//                         flit 收发。numRNs=1 故仅一个。
//   SNLinkMonitor    ×1   SN 侧 CHI 链路层监视。
//   TopDownMonitor_1 ×1   性能/调试监视:读各 slice 的 msStatus,产生 debugTopDown.addrMatch。
//
// 连接拓扑(见 Scala class OpenLLC,本层在 SV 里就是 11 个例化 + 引脚互联):
//   io.rn(i) <-> rnLinkMonitor <-> mmioDiverger.in(i)
//   mmioDiverger.out.cache(i) -> rnXbar.in(i);  rnXbar.out(i) <-> slices(i).in
//   slices(i).snpMask -> rnXbar.snpMasks(i);     slices(i).out -> snXbar.in(i)
//   snXbar.out -> mmioMerger.in.cache;  mmioDiverger.out.uncache -> mmioMerger.in.uncache
//   mmioMerger.out -> snLinkMonitor.in <-> io.sn
//   topDown 读 slices.msStatus -> io.debugTopDown.addrMatch
//
// 本层真正属于「顶层逻辑」的部分:
//   io.l3Miss := RegNext(Cat(slices.map(_.io.l3Miss)).orR)
//   ——4 个 slice 的 l3Miss 按位或后打一拍寄存,作为 L3 整体 miss 指示。这是本层
//   **唯一的时序 glue**(一个 always 块 / 一个具名寄存器 io_l3Miss_REG)。
//
// golden OpenLLC.sv 全文实测:`_T_<n>`/`_GEN_<n>`/`_REG_<编号>` 匿名临时名 = 0;
// reg 仅 1 个(io_l3Miss_REG,具名);always 块仅 1 个;assign 仅 3 条;1983 个子模块
// 引脚的 rhs 全是 io_* 端口 / _<inst>_io_* 互联网 / clock / reset 直连——无任何拼接 /
// 位选 / 常量 / 悬空。故本层逻辑 = 互联布线 + 1 拍 l3Miss 汇聚寄存。
//
// 本包仅放 L3 边界结构常量(其余全是子模块直通,落在 *_ports/_decls/_glue/_inst/
// _outassign.svh)。CHI flit 宽度等具体位宽从 golden wire 声明收割到 openllc_decls.svh,
// 无需在此重复声明。
// ============================================================================
package openllc_pkg;

  // ---- L3 装配结构常量(来自 LLCParam,仅作文档/可读性,核内不直接参数化展开)----
  localparam int NUM_RN  = 1;   // Request Node 数(接 core 集群);此配置 numRNs=1。
  localparam int BANKS   = 4;   // LLC bank 数 = slice 实例数。
  localparam int NUM_SN  = 1;   // Subordinate Node 数(接内存)。

  // ---- CHI 五通道 flit 位宽(来自 golden OpenLLC 端口,作可读性参考)----
  //   REQ=162b  RSP=73b  DAT=422b  SNP=115b(rx.snp,LLC->RN)
  localparam int CHI_REQ_W = 162;
  localparam int CHI_RSP_W = 73;
  localparam int CHI_DAT_W = 422;
  localparam int CHI_SNP_W = 115;

endpackage
