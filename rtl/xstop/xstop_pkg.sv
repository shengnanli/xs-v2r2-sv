// ============================================================================
// xstop_pkg —— 香山 V2R2 SoC 顶层(XSTop)类型与参数包
// ----------------------------------------------------------------------------
// 设计意图来源:src/main/scala/top/Top.scala(class XSTop / SoCMisc / XSTileWrap)
//
// XSTop 是「SoC 顶层」总集成:在已重写的 tile 顶层 XSTile(core_with_l2)之上,
// 挂接末级 cache(OpenLLC)、CHI 桥(OpenNCB)、CHI 多 die link 监视/仲裁、
// SoC misc(DebugModule/CLINT/PLIC/AXI4 xbar/L3),并把 SoC 边界拉直对外:
//   peripheral_* / memory_* (AXI4 总线)、CHI 多 die 链路、JTAG、中断、trace。
// 子模块清单(对本层均为 golden 黑盒,UT/FM 共用):
//   core_with_l2 (XSTile)          单 tile(XSCore+L2)
//   nocMisc      (MemMisc)         DebugModule/CLINT/PLIC/AXI4 xbar/L3 等
//   chi_openllc_opt (OpenLLC)      open-source 末级 cache
//   chi_llcBridge_opt (OpenNCB)    LLC TL<->CHI 桥
//   chi_mmioBridge_opt (OpenNCB_1) MMIO TL<->CHI 桥
//   linkMonitor / _1 / _2          CHI link 监视器(本端 + 2 outer die)
//   rxsnpArb / rxrspArb / rxdatArb (FastArbiter) outer 两 die Rx 通道仲裁
//   llcLogger / memLogger / mmioLogger (CHILogger) CHI 总线 logger
//   intBuffer (IntBuffer)          中断单 bit 缓冲
//   reset_sync_resetSync / jtag_reset_sync_resetSync (ResetGen) 复位同步
//
// 与更下层(XSCore/XSTile 几乎纯互联)不同,XSTop 含一处**真实的顶层组合 glue**:
// CHI 多 die(2 个 outer 节点)的 Tx/Rx 路由(地址译码选 die、reduction-OR 归并
// ready、仲裁 chosen 分发)。这处 glue 已从 Scala 意图重写成具名可读 wire,放在
// rtl/xstop/xstop_glue.svh(核里有完整中文注释)。golden 的 `_T_`/`inner_`/`outer_`
// 临时名经 gen_xstop.py 的 _RENAME 逐一改名,改写后核+svh 全文 `_T_`/`_GEN_` = 0。
//
// 本包仅放 SoC 边界宽度常量;glue 不需新类型(全是 1~11 bit 组合 wire)。
// ============================================================================
package xstop_pkg;

  // ----- SoC 边界宽度参数(昆明湖 V2R2 默认配置,与 golden 端口宽度一致)-----
  localparam int ChiReqW   = 162;  // CHI tx/rx REQ flit 位宽
  localparam int ChiRspW   = 73;   // CHI tx/rx RSP flit 位宽
  localparam int ChiDatW   = 422;  // CHI tx/rx DAT flit 位宽
  localparam int ChiSnpW   = 105;  // CHI rx SNP flit 位宽
  localparam int TgtIDW    = 11;   // CHI tgtID 位宽(多 die 路由目标)
  localparam int PAddrBits = 48;   // 物理地址位宽

  // CHI 多 die 路由 glue 全是组合 wire(见 xstop_glue.svh),本包不需额外类型。

endpackage
