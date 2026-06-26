// ============================================================================
// xstile_pkg —— 香山 V2R2 tile 级集成(XSTile)类型与参数包
// ----------------------------------------------------------------------------
// 设计意图来源:src/main/scala/xiangshan/XSTile.scala(class XSTileImp)
//
// XSTile 是「tile 级」总集成:在已重写的单核 XSCore 之上绑定 L2 cache 与中断
// 缓冲,把 tile 边界拉直对外。本层极薄——仅例化 3 个子模块并互联:
//   core      (XSCore)   单核:前端(BPU/IFU/ICache/IBuffer/Ftq)+ 后端(译码/重命名
//                         /调度/执行/写回/Rob/CSR)+ 访存(LSU/LSQ/DCache/MMU)。
//                         **已重写完成并独立验证,对本层是 golden 黑盒。**
//   l2top     (L2Top)    L2 cache 子系统 + TileLink<->CHI 桥 + CLINT/PLIC/IMSIC
//                         中断对接 + msiInfo/clintTime/reset_vector/hartId 转发
//                         给 core + L2 PTW(l2_tlb_req)/ L2 PMP /  L2 hint。
//   intBuffer (IntBuffer)中断单 bit 缓冲(把 l2 的 beu_local_int_source 汇聚一拍
//                         再送给上层 PLIC,XSTop 才接)。
//
// 这 3 个子模块对本层都是 golden 黑盒(UT/FM 两侧共用同一份 golden 定义)。
//
// 本层真正属于「顶层逻辑」的部分,只有「互联布线」(Scala 里全是 `<>`/`:=`):
//   · core ↔ l2top:core 的 memBlock TileLink client(dcache/buffers/ptw_to_l2/
//     frontendBridge icache·instr_uncache·icachectrl)接入 l2top 的 inner TL 节点;
//     l2 的 l2_hint / l2_pf_ctrl / l2_tlb_req(PTW)/ l2_pmp_resp 回到 core。
//   · l2top 转发的核控制量:msiInfo / clintTime / reset_vector / hartId /
//     debugTopDown(l2/l3 miss)/ l3Miss 等,经 l2top 中转再给 core。
//   · 中断分发:clint/debug/nmi/plic/beu 经 l2top 的 inner int 节点对外,
//     beu_local_int_source -> intBuffer -> auto_out(给 XSTop 的 PLIC)。
//   · tile 边界透传:io_chi(CHI 总线)/ traceCoreInterface / debugTopDown /
//     l3Miss / hartIsInReset / cpu_halt / cpu_crtical_error / reset_vector。
//
// golden XSTile.sv 全文实测:`_T_`/`_GEN_`/`inner_` 临时名 = 0,reg/always = 0,
// 顶层时序 glue = 0,顶层组合 glue = 0(无任何带运算的引脚 rhs / 带运算的 assign)。
// 顶层唯一「逻辑」是 2 条把 core 输出直连 io 的 assign(纯连线,见 XSTile.sv 末尾)。
// 故本包不需放任何打拍寄存器/组合常量类型,仅放架构宽度常量(其余全是子模块直通,
// 落在 *_ports.svh / *_decls.svh / *_inst.svh / *_outassign.svh)。
// ============================================================================
package xstile_pkg;

  // ----- tile 边界宽度参数(昆明湖 V2R2 默认配置,与 golden 端口宽度一致)-----
  localparam int HartIdLen   = 6;    // io_hartId 位宽(单核 hartId)
  localparam int PAddrBits   = 48;   // 物理地址位宽(reset_vector / robHeadPaddr)
  localparam int MsiInfoW    = 11;   // IMSIC MSI_INFO_WIDTH(io_msiInfo_bits)
  localparam int ChiReqW     = 162;  // CHI tx/rx REQ flit 位宽
  localparam int ChiRspW     = 73;   // CHI tx/rx RSP flit 位宽
  localparam int ChiDatW     = 422;  // CHI tx/rx DAT flit 位宽
  localparam int ChiSnpW     = 105;  // CHI rx SNP flit 位宽

  // 本层无组合/时序 glue,故无额外类型定义。

endpackage
