// ============================================================================
// xscore_pkg —— 香山 V2R2 单核最高层(XSCore)类型与参数包
// ----------------------------------------------------------------------------
// 设计意图来源:src/main/scala/xiangshan/XSCore.scala(class XSCoreImp)
//
// XSCore 是「单核最高层」总集成,但本层极薄——仅例化 3 个子模块并互联:
//   frontend (Frontend)  前端:BPU 分支预测 / NewIFU 取指 / ICache 全族 /
//                         IBuffer / InstrUncache / Ftq;对外有 icache·instr_uncache
//                         的 diplomacy TileLink client 节点(由 memBlock 的
//                         frontendBridge 桥接)。
//   backend  (Backend)   后端:DecodeUnit / Rename / Dispatch / 4 调度器 /
//                         DataPath / BypassNetwork / 3 ExuBlock / WbDataPath /
//                         Rob / NewCSR。
//   memBlock (MemBlock)  访存:LoadUnit / StoreUnit / LSQ 全族 / Sbuffer /
//                         DCache 全族 / TLB / PTW-L2TLB / frontendBridge(给前端
//                         的 TL 桥 + icachectrl)。
//
// 这 3 个子模块**已各自重写完成并独立验证**,对本层是 golden 黑盒(UT/FM 两侧
// 共用同一份 golden 定义)。
//
// 本层真正属于「顶层逻辑」的部分,几乎只有「互联布线」(Scala 里全是 `<>`/`:=`):
//   · 前端↔后端:io.frontend / sfence / tlbCsr / csrCtrl / fencei。
//   · 访存↔后端:topToBackendBypass / stIn / lsqEnqIO / writeback×6 /
//     feedback×5 / issue×5 / robLsqIO / exceptionAddr / sfence / redirect /
//     csrCtrl / tlbCsr。
//   · CSR↔Mem 边界:clintTime / msiInfo / hartId / l2_flush_done。
//   · top↔mem / top↔frontend:reset_vector / l2_hint / l2_tlb_req / l2_pmp_resp /
//     traceCoreInterface / topDownInfo / dft / dft_reset。
//   · diplomacy TL 桥:memBlock.frontendBridge.icache/instr_uncache/icachectrl 节点
//     ↔ frontend.icache/instrUncache client 节点(golden 里展开成 auto_* 扁平 TL 引脚)。
//
// 顶层唯一的「组合 glue」只有 3 处(BEU 错误聚合 / l2 prefetch recv_en 直连),
// golden XSCore.sv 全文 `_T_`/`_GEN_`/`inner_` 临时名 = 0;故本包不需放任何
// 打拍寄存器类型,仅放架构常量(其余全是子模块直通,落在 *_ports.svh /
// *_decls.svh / *_inst.svh)。
// ============================================================================
package xscore_pkg;

  // ----- 顶层宽度参数(昆明湖 V2R2 默认配置,与 golden 端口宽度一致)-----
  localparam int HartIdLen   = 6;    // io_hartId 位宽(单核 hartId)
  localparam int PAddrBits   = 48;   // 物理地址位宽(reset_vector / robHeadPaddr)
  localparam int VAddrBits   = 50;   // 虚拟地址位宽(l2_tlb_req vaddr)
  localparam int MsiInfoW    = 11;   // IMSIC MSI_INFO_WIDTH

  // ----- BEU(总线错误单元)错误聚合:icache/dcache 各一路 ecc_error_valid。
  //   valid = 子模块 error.valid & error.bits.report_to_beu(toL1BusErrorUnitInfo
  //   的展开),在可读核里用具名 wire 显式 AND(见 XSCore.sv)。本包仅作注释占位。

endpackage
