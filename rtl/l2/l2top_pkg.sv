// ============================================================================
// l2top_pkg —— 香山 V2R2 L2 顶层装配(L2Top)类型与参数包
// ----------------------------------------------------------------------------
// 设计意图来源:src/main/scala/xiangshan/L2Top.scala(class L2TopImp)
//
// L2Top 是「L2 cache 子系统」的顶层装配壳:把 CoupledL2 主体与一圈 TileLink 互联
// 器件拼起来,把 L2 边界(core 侧 TL client 节点 / CHI 总线 / 中断 / PTW / trace /
// hartId / reset_vector / l2_hint)拉直对外。本层是**纯互联壳**——仅例化子模块并
// 互联,外加 trace 打拍 / hartIsInReset / 中断与控制量直通转发。
//
// 子模块(15 种类型 / 21 个实例,本层 golden 黑盒,UT/FM 两侧共用):
//   TL2CHICoupledL2 ×1   L2 cache 主体:L2 阵列(目录/数据/MSHR)+ TileLink<->CHI 桥。
//   TLXbar_5 / TLXbar_6  TileLink 交叉开关:把 core 来的多 master(dcache/ptw/icache
//                        /uncache 等)汇聚到 L2 client 入口。
//   TLBuffer_*      ×11  TileLink 寄存缓冲:沿 A/B/C/D/E 五通道按需打拍,隔离时序、
//                        平衡 diplomacy 链路(_6/_8/_13/_15/_20/_22 是不同打拍配置)。
//   TLLogger/_1/_2  ×3   TileLink 事务日志:difftest/性能用,综合时旁路(纯透传)。
//   BusErrorUnit    ×1   总线错误单元:汇聚 L2 ECC error 地址,上报本地中断给 PLIC。
//   BusPerfMonitor  ×1   总线性能监视:非综合统计(综合时纯透传)。
//   DelayN_334      ×1   reset_vector 延迟链:fromTile -> 延迟 N 拍 -> toCore。
//
// 本层真正属于「顶层逻辑」的部分(Scala 里多为 `<>`/`:=` 连线 + 少量打拍):
//   (A) 输入 fanin 改名:wire inner_io_X = io_X;(19 条,纯连线)
//   (B) 组合直通改名:  hartId / cpu_halt / cpu_critical_error 从 fromTile/fromCore
//                       直通到 toCore/toTile(3 条,纯连线)。
//   (C) 中断端口直通:  nmi/plic/debug/clint 中断 in->out 直穿(7 条 assign,L2Top 仅
//                       作 diplomacy 中转,中断本身不在此层产生)。
//   (D) trace 打拍 + hartIsInReset:本层**唯一的时序 glue**(两个 always)——
//         · trace 流水级:core 来的 traceCoreInterface(toEncoder groups/trap/priv)
//           打一拍寄存(部分受 group_valid / itype 异常门控)再送 toTile;fromEncoder
//           的 enable/stall 打一拍回灌 fromCore。
//         · hartIsInReset:resetInFrontend | reset 经异步置位寄存器输出 toTile。
//   (E) 顶层 io 输出 assign:50 条,绝大多数子模块输出网 / inner_io_* 直连 io;唯一
//       带运算的是 io_l2_hint_bits_sourceId 取低 4 位([3:0])。
//
// golden L2Top.sv 全文实测:`_T_<n>`/`_GEN_<n>`/`_REG_<编号>` 匿名临时名 = 0(只有
// 后缀 _REG/_r 的具名 trace 寄存器),带运算的引脚 rhs = 0,带运算的 assign 仅 1 处位选。
// 故本包仅放 L2 边界宽度常量(其余全是子模块直通/打拍,落在 *_ports/_decls/_glue/
// _inst/_outassign.svh)。
// ============================================================================
package l2top_pkg;

  // ----- L2 边界宽度参数(昆明湖 V2R2 默认配置,与 golden 端口宽度一致)-----
  localparam int HartIdLen   = 64;   // io_hartId_fromTile/toCore 位宽
  localparam int PAddrBits   = 48;   // 物理地址位宽(reset_vector / l2 error_address)
  localparam int MsiInfoW    = 11;   // IMSIC MSI_INFO_WIDTH(io_msiInfo_*_bits)
  localparam int ChiReqW     = 162;  // CHI tx REQ flit 位宽
  localparam int ChiRspW     = 73;   // CHI tx/rx RSP flit 位宽
  localparam int ChiDatW     = 422;  // CHI tx/rx DAT flit 位宽
  localparam int ChiSnpW     = 115;  // CHI rx SNP flit 位宽
  localparam int L2HintSrcW  = 4;    // io_l2_hint_bits_sourceId 位宽(取 sourceId[3:0])

  // 本层 glue 为「具名」trace 寄存器 + 纯连线改名,无额外抽象类型需放本包。

endpackage
