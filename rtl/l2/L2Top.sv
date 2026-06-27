// 手写核 + 自动生成机械连线(scripts/gen_l2top.py 接管 ports/decls/glue/inst/outassign/wrapper/stub/UT)。
// =====================================================================
// xs_L2Top_core —— 香山 V2R2 L2 顶层装配可读核。
//
// L2Top(src/main/scala/xiangshan/L2Top.scala,class L2TopImp)是 L2 cache 子系统的
// 顶层装配壳:把 CoupledL2 主体(TL2CHICoupledL2,L2 阵列 + TileLink<->CHI 桥)与一圈
// TileLink 互联器件(xbar/buffer/logger)、BEU(总线错误单元)、BusPerfMonitor 拼起来,
// 并把 L2 边界(core 侧 TL client 节点 / CHI 总线 / 中断 / PTW(l2_tlb_req)/ trace /
// hartId / reset_vector / l2_hint)拉直对外。
//
// 子模块(15 种类型 / 21 个实例,**本层全部 golden 黑盒**,UT/FM 两侧共用):
//   TL2CHICoupledL2 ×1   L2 cache 主体(L2 阵列 + TileLink<->CHI 桥)
//   TLXbar_5 / TLXbar_6  TileLink 交叉开关(core 多 master 汇聚到 L2 入口)
//   TLBuffer_*      ×11  TileLink 寄存缓冲(A/B/C/D/E 通道按需打拍隔离时序)
//   TLLogger ×3          TileLink 事务日志(difftest/perf,综合时纯透传)
//   BusErrorUnit    ×1   总线错误单元(L2 ECC error 上报本地中断)
//   BusPerfMonitor  ×1   总线性能监视(非综合统计)
//   DelayN_334      ×1   reset_vector 延迟链(fromTile -> 延迟 -> toCore)
//
// 本层逻辑 = 互联布线 + trace 打拍 + 中断/控制量直通转发,共五类(见 _glue/_inst/
// _outassign.svh),golden L2Top.sv 全文实测无 `_T_<n>`/`_GEN_<n>`/`_REG_<编号>` 匿名
// 临时名,带运算引脚 rhs = 0,带运算 assign 仅 1 处位选([3:0])。
//
// 类型/参数见 l2top_pkg.sv;子模块黑盒输出/互联网见 l2top_decls.svh;
// 顶层 glue(输入改名/组合直通/trace 打拍/hartIsInReset)见 l2top_glue.svh;
// 子模块例化+引脚连核内具名信号/互联网见 l2top_inst.svh;
// 顶层 io 输出 + 中断直通 assign 见 l2top_outassign.svh。
// =====================================================================
import l2top_pkg::*;

module xs_L2Top_core (
  input clock,
  input reset,
`include "l2top_ports.svh"
);

  // ===================================================================
  // 子模块黑盒输出/互联网声明(供 glue/inst/outassign 消费)。
  //   _inner_<inst>_*  : 子模块输出网(含 diplomacy 扁平 TileLink 引脚 _auto_*);
  //   inner_io_chi_*   : CHI 输出网(子模块输出引脚 -> 此 wire -> io assign)。
  // ===================================================================
`include "l2top_decls.svh"

  // ===================================================================
  // 顶层 glue(从 Scala 意图重写,golden 已具名可读):
  //   (A) 输入 fanin 改名 wire inner_io_X = io_X;
  //   (B) 组合直通改名(hartId / cpu_halt / cpu_critical_error);
  //   (D) trace 接口打拍流水级 + hartIsInReset(本层唯一时序 glue,两个 always)。
  // ===================================================================
`include "l2top_glue.svh"

  // ===================================================================
  // 21 子模块黑盒例化 + 引脚连核内具名信号/互联网(纯机械,gen_l2top.py 生成)。
  //   client 侧:core 来的 TL master 经 xbar/buffer 汇聚进 l2cache 的 in 节点;
  //   mem 侧:  l2cache 的 out 节点经 buffer 到对外 auto_inner_buffers_out(CHI/mem);
  //   旁路:    logger(透传)/ beu(error 收集)/ busPMU(统计)/ resetDelayN。
  // ===================================================================
`include "l2top_inst.svh"

  // ===================================================================
  // 顶层 io 输出 assign + 中断端口直通(auto_inner_*_int_out = in,L2Top 仅中转)。
  //   绝大多数纯连线;唯一带运算:io_l2_hint_bits_sourceId 取 sourceId[3:0]。
  // ===================================================================
`include "l2top_outassign.svh"

endmodule
