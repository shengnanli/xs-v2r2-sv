// 手写核 + 自动生成机械连线(scripts/gen_xstop.py 接管 ports/decls/glue/inst/outassign/wrapper/stub/UT)。
// =====================================================================
// xs_XSTop_core —— 香山 V2R2 SoC 顶层可读核。
//
// XSTop(src/main/scala/top/Top.scala)是 SoC 顶层总集成:在已重写的 tile 顶层
// XSTile(实例名 core_with_l2)之上,挂接末级 cache(OpenLLC)、CHI 桥(OpenNCB)、
// CHI 多 die link 监视/仲裁、SoC misc(DebugModule/CLINT/PLIC/AXI4 xbar/L3),把
// SoC 边界(AXI4 peripheral/memory、CHI 多 die、JTAG、中断、trace)拉直对外。
// **所有子模块已各自完成,在本顶层作 golden 黑盒例化**(UT/FM 两侧共用)。
//
// 注意:XSTop 是 LazyRawModuleImp,没有独立 clock/reset 端口——时钟/复位是功能
// 端口(io_clock / io_reset / io_rtc_clock / io_systemjtag_reset ...),复位经
// ResetGen 同步后再分发,故本核端口表里照列(无 clock/reset 形参)。
//
// 与更下层(XSCore/XSTile 几乎纯互联)不同,XSTop 含一处**真实的顶层组合 glue**:
// CHI 多 die(2 个 outer 节点 die0/die1)的 Tx/Rx 路由。这处 glue 已从 Scala 设计
// 意图重写成具名可读 wire(见 xstop_glue.svh),核里保留 golden 的布尔/算术结构、
// 仅把 golden 的 `_T_`/`inner_`/`outer_` 临时名换成可读名:
//   ① tileReset            —— core_with_l2 复位 = 同步复位 | DebugModule hart 复位请求。
//   ② txReqTgtID/txReqTgtSel —— Tx-REQ 按地址区间译码出目标 die 的 CHI tgtID。
//   ③ tx{Req,Rsp,Dat}ToDie{0,1}Valid —— Tx 通道按 tgtID 把本端 valid 分发到两 die。
//   ④ 本端 linkMonitor 的 tx_*_ready —— 两 die ready & 各自 valid 的 reduction-OR(在 inst.svh 引脚处)。
//   ⑤ rx{Snp,Rsp,Dat}ReadyAndArbValid —— outer die Rx ready 中间量(本端 ready & 仲裁 out valid),
//                                          再在引脚处 & [~]arb_chosen 分发到 die0/die1。
//   ⑥ trace 输出           —— 把 core 的 3 个 retire group 字段拼接对外(见 outassign.svh)。
//
// 类型/参数见 xstop_pkg.sv;子模块黑盒输出/互联网见 xstop_decls.svh;
// CHI 多 die 路由 glue 见 xstop_glue.svh;子模块例化+引脚连线见 xstop_inst.svh。
// =====================================================================
import xstop_pkg::*;

module xs_XSTop_core (
`include "xstop_ports.svh"
);

  // ===================================================================
  // 子模块黑盒输出/互联网声明(供 glue / inst.svh 引脚 / outassign 消费)。
  //   全部是 _<inst>_* 前缀的子模块输出网(core_with_l2 / nocMisc / chi_* /
  //   linkMonitor* / rx*Arb / *Logger / intBuffer / *resetSync),
  //   含 diplomacy TileLink / CHI / AXI4 的扁平引脚。
  // ===================================================================
`include "xstop_decls.svh"

  // ===================================================================
  // CHI 多 die(die0/die1)Tx/Rx 路由 glue(从 Scala 意图重写的具名可读 wire)。
  //   tileReset / txReqTgtID / tx*ToDie{0,1}Valid / rx*ReadyAndArbValid。
  //   保留 golden 布尔结构,临时名已换可读名(详见文件头 ①~⑤ 与 svh 内注释)。
  // ===================================================================
`include "xstop_glue.svh"

  // ===================================================================
  // 子模块黑盒例化 + 引脚连核内具名信号/互联网/glue(纯机械,gen_xstop.py 生成)。
  //   引脚 rhs:io_* 顶层端口 / _<inst>_* 互联网 / 常量 / 悬空端口 /
  //   CHI 路由 glue 具名 wire(含引脚处的 reduction-OR / 仲裁 chosen 分发)。
  // ===================================================================
`include "xstop_inst.svh"

  // ===================================================================
  // 顶层 io 输出 assign(子模块输出直连 io;trace 输出为 retire group 拼接)。
  // ===================================================================
`include "xstop_outassign.svh"

endmodule
