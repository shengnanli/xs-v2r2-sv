// 手写核 + 自动生成机械连线(scripts/gen_xscore.py 接管 ports/decls/inst/outassign/wrapper/stub/UT)。
// =====================================================================
// xs_XSCore_core —— 香山 V2R2 单核最高层可读核(capstone)。
//
// XSCore(src/main/scala/xiangshan/XSCore.scala,class XSCoreImp)是单核
// 最高层总集成,但本层极薄:仅例化 3 个子模块并互联——
//   frontend (Frontend)  前端:BPU/NewIFU/ICache/IBuffer/InstrUncache/Ftq
//   backend  (Backend)   后端:Decode/Rename/Dispatch/Sched×4/DataPath/Exu/Wb/Rob/CSR
//   memBlock (MemBlock)  访存:LSU/LSQ/Sbuffer/DCache/TLB/PTW/frontendBridge(TL 桥)
// **3 个子模块已各自重写完成,在本顶层作 golden 黑盒例化**(UT/FM 两侧共用)。
//
// 顶层自身的真逻辑 = 模块间互联布线(在 xscore_inst.svh,纯例化连线)。
// golden XSCore.sv 全文 `_T_`/`_GEN_`/`inner_` 临时名 = 0,即本层**没有顶层
// 时序 glue**(无打拍/无计数/无状态机)——所有边界打拍都已下沉到各子模块内部
// (Backend/MemBlock 各自的 *WbDelayed/CSR 边界打拍)。
//
// 本层唯一的「组合 glue」只有 3 处(BEU 总线错误聚合 / l2 prefetch recv_en),
// 都在本核里用具名 wire / assign 显式写出,绝不抽进 svh 套壳:
//   ① icacheBeuEccErrorValid —— frontend.io.error 经 toL1BusErrorUnitInfo 展开:
//        = _frontend_io_error_valid & _frontend_io_error_bits_report_to_beu
//      送 memBlock.io_inner_beu_errors_icache_ecc_error_valid 引脚(见 inst.svh)。
//   ② dcacheBeuEccErrorValid —— memBlock.io.dcacheError 同样 toL1BusErrorUnitInfo:
//        = _memBlock_io_dcacheError_valid & _memBlock_io_dcacheError_bits_report_to_beu
//      直连顶层 io_beu_errors_dcache_ecc_error_valid(见 outassign.svh)。
//   ③ io_l2PfCtrl_l2_pf_recv_en —— backend pf_ctrl.toL2PrefetchCtrl() 的 recv_en
//        = _backend_io_mem_csrCtrl_pf_ctrl_l2_pf_recv_enable(直连,见 outassign.svh)。
//
// 类型/参数见 xscore_pkg.sv;3 子模块黑盒输出/互联网见 xscore_decls.svh;
// 3 子模块例化+引脚连核内具名信号/互联网见 xscore_inst.svh。
// =====================================================================
import xscore_pkg::*;

module xs_XSCore_core (
  input clock,
  input reset,
`include "xscore_ports.svh"
);

  // ===================================================================
  // 3 子模块黑盒输出/互联网声明(供 glue 与 inst.svh 引脚消费)。
  //   全部是 _frontend_* / _backend_* / _memBlock_* 前缀的子模块输出网,
  //   含 diplomacy TileLink 桥的 _*_auto_* 扁平 TL 引脚。
  // ===================================================================
`include "xscore_decls.svh"

  // ===================================================================
  // 顶层组合 glue(BEU 总线错误聚合)——从 Scala 设计意图重写。
  //   Scala: frontend.io.error.bits.toL1BusErrorUnitInfo(frontend.io.error.valid)
  //          memBlock.io.dcacheError.bits.toL1BusErrorUnitInfo(...)
  //   toL1BusErrorUnitInfo 的语义:ecc_error_valid = error.valid & report_to_beu;
  //   其余字段(paddr 等)直接搬运。这里只有「有效位」是 AND,给可读具名 wire。
  // ===================================================================
  // icache BEU:送 memBlock 的 io_inner_beu_errors_icache_ecc_error_valid 引脚。
  wire icacheBeuEccErrorValid =
      _frontend_io_error_valid & _frontend_io_error_bits_report_to_beu;
  // dcache BEU:直连顶层 io_beu_errors_dcache_ecc_error_valid 输出。
  wire dcacheBeuEccErrorValid =
      _memBlock_io_dcacheError_valid & _memBlock_io_dcacheError_bits_report_to_beu;

  // ===================================================================
  // 3 子模块黑盒例化 + 引脚连核内具名信号/互联网(纯机械,gen_xscore.py 生成)。
  //   前端输入引脚 <- memBlock TL 桥/backend 输出;前端输出引脚 -> _frontend_* 网。
  //   后端输入引脚 <- memBlock/frontend/io;后端输出引脚 -> _backend_* 网。
  //   访存输入引脚 <- backend/frontend/io/icacheBeuEccErrorValid;输出 -> _memBlock_* 网。
  // ===================================================================
`include "xscore_inst.svh"

  // ===================================================================
  // 顶层 io 输出 assign(子模块输出直连 io;含 dcache BEU AND / l2 recv_en)。
  // ===================================================================
`include "xscore_outassign.svh"

endmodule
