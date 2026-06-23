// 手写核 + 自动生成机械连线(scripts/gen_ctrlblock.py 后续接管 inst/wrapper/stub)。
// =====================================================================
// xs_CtrlBlock_core —— 香山 V2R2 后端控制平面可读核。
// 6 块顶层 glue(重定向流水 s0-s5 / decode buffer FSM / 写回打拍压缩 /
// 快照选择 / frontend flush 路由 / pcMem 读口驱动)从 CtrlBlock.scala 设计
// 意图重写,见 ctrlblock_logic.svh;类型/函数见 ctrlblock_pkg.sv。
// 22 个子模块(Rob/NewDispatch/DecodeStage/FusionDecoder/RenameTableWrapper/
// Rename/RedirectGenerator/pcMem/MemCtrl/Trace/GPAMem/Snapshot/6×PipelineConnect/
// PipeGroupConnect/DelayN×3)全部 golden 黑盒,例化与机械连线见 ctrlblock_inst.svh,
// 黑盒输出网见 ctrlblock_decls.svh。
// =====================================================================
import ctrlblock_pkg::*;

module xs_CtrlBlock_core (
  input clock,
  input reset,
`include "ctrlblock_ports.svh"
);

  // ---- 可读聚合别名:把若干顶层扁平 io 收成向量,供 glue 使用 ----
  wire [DecodeWidth-1:0] frontend_cfVec_valid = {
      io_frontend_cfVec_5_valid, io_frontend_cfVec_4_valid, io_frontend_cfVec_3_valid,
      io_frontend_cfVec_2_valid, io_frontend_cfVec_1_valid, io_frontend_cfVec_0_valid };

  // frontend 输出(由 glue 驱动)
  wire frontend_canAccept;
  wire frontend_toFtq_redirect_valid;          // 块5 产出;由 outglue 驱顶层 redirect.valid
  wire [2:0] frontend_toFtq_ftqIdxSelOH_bits;  // 块5 产出;由 outglue 驱顶层 ftqIdxSelOH.bits
  assign io_frontend_canAccept            = frontend_canAccept;
  // io_frontend_toFtq_redirect_valid / ftqIdxSelOH_bits 由 ctrlblock_outglue.svh ⑥⑦ 驱动
  // （那里连同 redirect.bits 全字段一并产出,避免双驱动）。

  // io.frontend.toFtq.redirect.valid 打拍清 pending 用(块1):取自本核输出
  wire frontend_toFtq_redirect_valid_i = frontend_toFtq_redirect_valid;
  // logic.svh 中 frontendRedirectValidReg 的源(避免组合环:用上一拍输出)
  wire frontend_toFtq_redirect_valid_src = frontend_toFtq_redirect_valid;

  // 写回 robIdx 聚合(0..24 共 25 路)
  wire        wbRobFlag  [0:24];
  wire [7:0]  wbRobValue [0:24];
  assign wbRobFlag[0]  = io_fromWB_wbData_0_bits_robIdx_flag;
  assign wbRobValue[0] = io_fromWB_wbData_0_bits_robIdx_value;
`include "ctrlblock_wb_robidx.svh"

  // 黑盒子模块输出网 + glue 内部信号声明
`include "ctrlblock_decls.svh"

  // 6 块顶层 glue
`include "ctrlblock_logic.svh"

  // 数据通路 glue(写回打拍/压缩 + enqRob 入队打拍 + redirect 广播输出),round3
`include "ctrlblock_datapath.svh"

  // 散余 glue(exuRedirect 选最旧 / mdpFlodPcVec / decode 输入 foldpc),round4
`include "ctrlblock_glue2.svh"

  // 输出侧 glue(io_perf / s2_s4_redirect / newestTarget / toFtq.redirect 链 / commits->FTQ)
`include "ctrlblock_outglue.svh"

  // 剩余小 glue(CSR 控制打拍 / loadReplay / instrAddrTransType / fusion 覆盖 / 别名),round6
`include "ctrlblock_glue3.svh"

  // 22 子模块黑盒例化 + 机械连线(rewrite RHS -> 核内具名信号)
`include "ctrlblock_inst.svh"

  // decode/fusion 入口 valid glue(引用 inst.svh 声明的 decode 黑盒输出网,故置其后),round6
`include "ctrlblock_glue4.svh"

  // 漏驱顶层输出端口补全(rob/rat/trace -> robio/wfi/error/cfVec.ready/commits6,7/
  // ratOldPest/traceCoreInterface),round7 由 UT 双例化逐拍比对暴露
`include "ctrlblock_outglue2.svh"

endmodule : xs_CtrlBlock_core
