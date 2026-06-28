// 手写核 + 自动生成机械连线(scripts/gen_openllc.py 接管 ports/decls/glue/inst/outassign/wrapper/stub/UT)。
// =====================================================================
// xs_OpenLLC_core —— 香山 V2R2 外挂 L3 缓存(OpenLLC)装配可读核。
//
// OpenLLC(openLLC/src/main/scala/openLLC/OpenLLC.scala,class OpenLLC)是香山外挂的
// **独立 L3 缓存 IP**:一个 CHI 协议的 home node。北侧接 core 集群(RN,经 CHI),南侧
// 接内存(SN,NoSnp 端口)。本层把若干 LLC slice(cache 流水 + 目录 + 数据 + snoop
// filter)与一圈 CHI 互联/链路器件(xbar / linkMonitor / mmioDiverger / mmioMerger)
// 拼起来,并把 L3 边界(RN/SN CHI 总线 / debugTopDown / l3Miss)拉直对外。
//
// 子模块(8 种类型 / 11 个实例,**本层全部 golden 黑盒**,UT/FM 两侧共用):
//   Slice_4          ×4   LLC slice(cache 流水:RequestArb/MainPipe/Directory/
//                         DataStorage/MSHR/snoop filter),banks=4 每 bank 一个。
//   RNXbar           ×1   RN 侧 CHI 交叉开关(各 RN cacheable 请求按 bank 路由到 slice)。
//   SNXbar           ×1   SN 侧 CHI 交叉开关(各 slice 访存请求汇聚到内存侧)。
//   MMIODiverger     ×1   分流 cacheable / uncacheable(MMIO)。
//   MMIOMerger       ×1   合并 cacheable(snXbar 出)与 uncacheable(MMIO)送 SN。
//   RNLinkMonitor    ×1   RN 侧 CHI 链路层监视(linkactive/lcredit 流控)。
//   SNLinkMonitor    ×1   SN 侧 CHI 链路层监视。
//   TopDownMonitor_1 ×1   性能/调试监视(读 slice msStatus -> debugTopDown.addrMatch)。
//
// 连接拓扑:
//   io.rn(i) <-> rnLinkMonitor <-> mmioDiverger.in(i)
//   mmioDiverger.out.cache(i) -> rnXbar.in(i);  rnXbar.out(i) <-> slices(i).in
//   slices(i).snpMask -> rnXbar.snpMasks(i);     slices(i).out -> snXbar.in(i)
//   snXbar.out -> mmioMerger.in.cache;  mmioDiverger.out.uncache -> mmioMerger.in.uncache
//   mmioMerger.out -> snLinkMonitor.in <-> io.sn
//   topDown 读 slices.msStatus -> io.debugTopDown.addrMatch
//
// 本层逻辑 = 互联布线 + 1 拍 l3Miss 汇聚寄存(io.l3Miss := RegNext(OR(slices.l3Miss)))。
// golden OpenLLC.sv 全文实测无 `_T_<n>`/`_GEN_<n>`/`_REG_<编号>` 匿名临时名;reg 仅 1 个
// (具名 io_l3Miss_REG);always 块仅 1 个;assign 仅 3 条;1983 个引脚 rhs 全是
// io_*/_<inst>_io_*/clock/reset 直连——无任何拼接/位选/常量/悬空。
//
// 类型/参数见 openllc_pkg.sv;子模块黑盒输出/互联网见 openllc_decls.svh;
// 顶层 glue(l3Miss 打拍)见 openllc_glue.svh;
// 子模块例化+引脚连核内具名信号/互联网见 openllc_inst.svh;
// 顶层 io 输出 + probe assign 见 openllc_outassign.svh。
// =====================================================================
import openllc_pkg::*;

module xs_OpenLLC_core (
  input clock,
  input reset,
`include "openllc_ports.svh"
);

  // ===================================================================
  // 子模块黑盒输出/互联网声明(供 glue/inst/outassign 消费)。
  //   _<inst>_io_*  : 子模块输出引脚网(slice/xbar/linkmon/mmio 之间的 CHI 互联);
  //   _probe        : difftest/dontTouch 探针(topDown 的 addrMatch 镜像)。
  // ===================================================================
`include "openllc_decls.svh"

  // ===================================================================
  // 顶层 glue(本层唯一时序逻辑):io.l3Miss := RegNext(OR(各 slice 的 l3Miss))。
  // ===================================================================
`include "openllc_glue.svh"

  // ===================================================================
  // 11 子模块黑盒例化 + 引脚连核内具名信号/互联网(纯机械,gen_openllc.py 生成)。
  //   RN 侧:io.rn -> rnLinkMonitor -> mmioDiverger -(cache)-> rnXbar -> slices;
  //   SN 侧:slices -> snXbar -(cache)-> mmioMerger <-(uncache)- mmioDiverger ->
  //          snLinkMonitor -> io.sn;
  //   旁路:topDown(读 slice msStatus,产生 addrMatch)。
  // ===================================================================
`include "openllc_inst.svh"

  // ===================================================================
  // 顶层 io 输出 assign + probe(共 3 条,全部纯连线):
  //   _probe = topDown.addrMatch(difftest 探针);
  //   io_debugTopDown_addrMatch_0 = topDown.addrMatch;
  //   io_l3Miss = io_l3Miss_REG(打拍后的 l3Miss)。
  // ===================================================================
`include "openllc_outassign.svh"

endmodule
