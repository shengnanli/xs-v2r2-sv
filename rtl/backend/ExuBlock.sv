// 自动生成:scripts/gen_exublock.py（ExuBlock）—— 勿手改(逻辑为从设计意图的可读重写)

// ============================================================================
// xs_ExuBlock_core —— 执行单元簇容器(香山 V2R2 昆明湖)
// ----------------------------------------------------------------------------
// 设计意图来源:src/main/scala/xiangshan/backend/exu/ExuBlock.scala  class ExuBlock
//
// ExuBlock 把一个调度块(SchdBlock)里的全部 ExeUnit(执行单元)拼成一簇:
//   * 自身**没有**数据通路逻辑(分发/仲裁/旁路都在 ExeUnit 子模块或上游 Dispatch);
//   * 容器层只做三件事(见 *_logic.svh):
//       §1 frm 打拍——每个吃 frm 的 vf-exu 把 io_frm 打一拍(RegNext)后喂入;
//       §2 error 聚合——含 CSR 的 exu 的 critical-error 经多级寄存后输出 io_error_0;
//       §3 反压/CSR 透传——exu 的 in_ready / instrAddrTransType 直连顶层。
//   * 其余数百个端口为 input<>exu.in / exu.out<>output 的同构连线(见 *_connect.svh)。
//
//   上游 issue            ExeUnit 黑盒(FU 实体)            下游写回
//   ┌──────────┐      ┌────────────────────────────┐    ┌──────────┐
//   │ in[i][j] │─────▶│ exus / exus_1 / ...(Alu/   │───▶│ out[i][j]│
//   └──────────┘      │  Mul/Div/Brh/Jump/CSR/...) │    └──────────┘
//   flush ───广播────▶│                            │
//   frm  ─§1 打拍───▶│ vf-exu                     │
//                     │ csr-exu ──§2 error 打拍──▶ │──▶ io_error_0
//                     └────────────────────────────┘
//
// ExeUnit 各变体在 UT/FM 两侧均为 golden 黑盒(它们封装真正的功能单元)。
// ============================================================================
module xs_ExuBlock_core
  import exublock_pkg::*;
(
  input  clock,
  input  reset,
  `include "exublock_ports.svh"
);

  `include "exublock_decls.svh"    // 子模块输出网 + 流水寄存器状态声明
  `include "exublock_logic.svh"    // §1 frm 流水 / §2 error 流水(可读重写)
  `include "exublock_connect.svh"  // ExeUnit 黑盒例化 + 端口机械连线

endmodule
