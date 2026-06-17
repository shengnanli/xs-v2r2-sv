// 自动生成:scripts/gen_datapath.py —— 勿手改(逻辑为从设计意图的可读重写)

// =====================================================================
// xs_DataPath_core —— 香山 V2R2 数据通路可读核。
// 五条数据流(读口仲裁请求 / 写口流水 / s0->s1 流水 / s1 操作数选择 / RegCache 路由
// + og 响应 + 立即数透传)用 datapath_pkg 纯函数 + genvar/struct 重写,见 logic/ctrl
// svh;子模块(各域 RegFile / RFReadArbiter×5 / RFWBCollideChecker×5 / RegCache /
// UIntExtractor / difftest 探针)全部 golden 黑盒,见 connect svh。
// =====================================================================
import datapath_pkg::*;
import datapath_cfg_pkg::*;

module xs_DataPath_core (
  input clock,
  input reset,
`include "datapath_ports.svh"
);

`include "datapath_decls.svh"
`include "datapath_ctrl.svh"
`include "datapath_logic.svh"
`include "datapath_connect.svh"

endmodule : xs_DataPath_core
