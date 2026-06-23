// 自动生成:scripts/gen_exeunit.py（ExeUnit_8）—— 勿手改(逻辑为从设计意图的可读重写)

// ============================================================================
// xs_ExeUnit_8_core —— 执行单元包装(香山 V2R2 昆明湖)
// ----------------------------------------------------------------------------
// 设计意图来源:src/main/scala/xiangshan/backend/exu/ExeUnit.scala  class ExeUnit
//
// 本执行单元含 4 个功能单元(FU):Falu(lat1), Fcvt(lat2), f2v(lat0), Fmac(lat3)。
// ExeUnit 自身不运算,只做 FU 周围的 glue:
//   §0 分发  in1ToN(Dispatcher 黑盒):按 fuType 把 io_in 路由到正确的 FU。
//   §1 inPipe:控制位/有效位打拍对齐,供有延迟 FU 在出结果那拍取到原 uop 控制位
//            (有效位链每拍做 flush-kill)。
//   §2 时钟门控:每个有延迟 FU 一条有效链,链上有在飞 uop 则 clk_en=1,喂 ClockGate。
//   §3 输出仲裁:各 FU 至多一个有效,逐字段 one-hot 或归约成唯一 io_out。
//
//        io_in ─▶ in1ToN(Dispatcher 黑盒) ─┬─▶ FU0 ─┐
//                                          ├─▶ FU1 ─┤ §3 one-hot
//   flush ─▶ §1 inPipe(ctrl/valid 打拍)──┘   ...  ├──或归约──▶ io_out
//   §2 fuvld 链 ─▶ ClockGate(黑盒) ─▶ FU.clk     FUn ─┘
//
// FU(Alu/Mul/Bku/FAlu/...)、Dispatcher、ClockGate 在 UT/FM 两侧均为 golden 黑盒。
// ============================================================================
module xs_ExeUnit_8_core
  import exeunit_8_pkg::*;
(
  input  clock,
  input  reset,
  `include "exeunit_8_ports.svh"
);

  `include "exeunit_8_decls.svh"    // 子模块输出网 + 流水/门控状态声明
  `include "exeunit_8_logic.svh"    // §1 inPipe / §2 时钟门控使能(可读重写)
  `include "exeunit_8_connect.svh"  // FU/Dispatcher/ClockGate 黑盒例化 + §3 仲裁

endmodule
