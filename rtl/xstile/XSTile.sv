// 手写核 + 自动生成机械连线(scripts/gen_xstile.py 接管 ports/decls/inst/outassign/wrapper/stub/UT)。
// =====================================================================
// xs_XSTile_core —— 香山 V2R2 tile 级集成可读核。
//
// XSTile(src/main/scala/xiangshan/XSTile.scala,class XSTileImp)是 tile 顶层:
// 在已重写的单核 XSCore 之上绑定 L2 cache(L2Top)与中断缓冲(IntBuffer),并把
// tile 边界(CHI 总线 / 中断 / TLB / trace / debug-topdown / reset)拉直对外。
// 本层极薄,仅例化 3 个子模块并互联——
//   core      (XSCore)   单核(前端+后端+访存)
//   l2top     (L2Top)    L2 cache + TileLink<->CHI 桥 + 中断对接 + 核控制量转发
//   intBuffer (IntBuffer)beu 本地中断单 bit 缓冲(汇聚一拍给上层 PLIC)
// **3 个子模块已各自重写完成,在本顶层作 golden 黑盒例化**(UT/FM 两侧共用)。
//
// 顶层自身的真逻辑 = 模块间互联布线(在 xstile_inst.svh,纯例化连线)。
// golden XSTile.sv 全文实测:`_T_`/`_GEN_`/`inner_` 临时名 = 0,reg/always = 0,
// 即本层**没有任何顶层时序 glue**,也**没有顶层组合 glue**(无带运算的引脚 rhs /
// 带运算的 assign)——比 XSCore 还薄(XSCore 尚有 3 处 BEU/pf 组合 glue,本层一处
// 都没有)。所有边界打拍与组合都已下沉到各子模块内部(尤其 L2Top 内的桥/转发)。
//
// 本层唯一的「顶层逻辑」是 2 条把 core 输出直连顶层 io 的 assign(纯连线):
//   assign io_debugTopDown_robHeadPaddr_valid = _core_io_debugTopDown_robHeadPaddr_valid;
//   assign io_debugTopDown_robHeadPaddr_bits  = _core_io_debugTopDown_robHeadPaddr_bits;
// 见 xstile_outassign.svh(由 gen_xstile.py 从 golden 末尾 assign 机械搬运)。
//
// 子模块例化里有 2 个故意悬空的输入引脚(L2Top 的 io_l2_flush_en /
// io_power_down_en,golden 写作 `(/* unused */)`),本层落成合法悬空端口 `( )`。
//
// 类型/参数见 xstile_pkg.sv;3 子模块黑盒输出/互联网见 xstile_decls.svh;
// 3 子模块例化+引脚连核内具名信号/互联网见 xstile_inst.svh。
// =====================================================================
import xstile_pkg::*;

module xs_XSTile_core (
  input clock,
  input reset,
`include "xstile_ports.svh"
);

  // ===================================================================
  // 3 子模块黑盒输出/互联网声明(供 inst.svh 引脚与 outassign 消费)。
  //   全部是 _core_* / _l2top_* / _intBuffer_* 前缀的子模块输出网,
  //   含 diplomacy TileLink 节点的 _*_auto_* 扁平 TL 引脚。
  // ===================================================================
`include "xstile_decls.svh"

  // ===================================================================
  // 3 子模块黑盒例化 + 引脚连核内具名信号/互联网(纯机械,gen_xstile.py 生成)。
  //   core  输入引脚 <- l2top 转发量(msiInfo/clintTime/reset_vector/hartId/...)/
  //                      l2 回送(l2_hint/l2_tlb_req/l2_pmp_resp/l2PfCtrl)/ io;
  //         输出引脚 -> _core_* 网(memBlock TL client / trace / topdown / beu)。
  //   l2top 输入引脚 <- core 的 memBlock TL client / beu / io_chi / 中断 in / io;
  //         输出引脚 -> _l2top_* 网(转发量 / l2 回送 / 中断 out / 对外 TL)。
  //   intBuffer 输入 <- l2top 的 beu_local_int_source_out;输出 -> _intBuffer_auto_out。
  // ===================================================================
`include "xstile_inst.svh"

  // ===================================================================
  // 顶层 io 输出 assign(子模块输出直连 io;XSTile 全是纯连线,无 glue)。
  // ===================================================================
`include "xstile_outassign.svh"

endmodule
