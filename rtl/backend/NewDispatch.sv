// 自动生成:scripts/gen_newdispatch.py —— 勿手改(逻辑为从 NewDispatch.scala 设计意图的可读重写)

// =====================================================================
// xs_NewDispatch_core —— 香山 V2R2(昆明湖)派遣级可读核。
// 三大职责(就绪查询 / 路由+负载均衡 / 容量反压 + singleStep FSM)的「真逻辑」全部
// 在 newdispatch_logic.svh 里以命名网 / generate-for / 纯函数重写(无 _GEN_/_T_);
// 7 个真子模块(RegCacheTagTable / BusyTable×4 / VlBusyTable / LsqEnqCtrl)黑盒例化
// 与 34 enq 端口的统一选择展开见 newdispatch_connect.svh。
// 设计源:src/main/scala/xiangshan/backend/dispatch/NewDispatch.scala。
// =====================================================================
import newdispatch_pkg::*;

module xs_NewDispatch_core (
  input clock,
  input reset,
`include "newdispatch_ports.svh"
);

`include "newdispatch_logic.svh"
`include "newdispatch_connect.svh"

endmodule : xs_NewDispatch_core
