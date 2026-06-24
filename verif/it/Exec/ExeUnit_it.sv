// 后端 Exec 簇 IT 装配（ExeUnit = Alu+Mul+Bku）—— 由 gen_it.py 生成，勿手改。
// 顶层 ExeUnit_it 端口 = golden ExeUnit 端口（逐字相同）。
// 内部例化 xs_ExeUnit_core_it（include exeunit_connect_it.svh，FU 换 _xs 适配器）。

// 自动生成:scripts/gen_exeunit.py（ExeUnit）—— 勿手改(逻辑为从设计意图的可读重写)

// ============================================================================
// xs_ExeUnit_core —— 执行单元包装(香山 V2R2 昆明湖)
// ----------------------------------------------------------------------------
// 设计意图来源:src/main/scala/xiangshan/backend/exu/ExeUnit.scala  class ExeUnit
//
// 本执行单元含 3 个功能单元(FU):Alu(lat0), Mul(lat2), Bku(lat2)。
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
module xs_ExeUnit_core_it
  import exeunit_pkg::*;
(
  input  clock,
  input  reset,
  `include "exeunit_ports.svh"
);

  `include "exeunit_decls.svh"    // 子模块输出网 + 流水/门控状态声明
  `include "exeunit_logic.svh"    // §1 inPipe / §2 时钟门控使能(可读重写)
  `include "exeunit_connect_it.svh"  // FU/Dispatcher/ClockGate 黑盒例化 + §3 仲裁

endmodule


// ---- golden 同名扁平 wrapper(改名 ExeUnit_it)：tb u_i 例化此模块 ----
// 自动生成:scripts/gen_exeunit.py（ExeUnit）—— 勿手改(逻辑为从设计意图的可读重写)
// golden 同名扁平 wrapper(FM/ST 用):例化可读核。
module ExeUnit_it(
  input  clock,
  input  reset,
  input  io_flush_valid,
  input  io_flush_bits_robIdx_flag,
  input  [7:0] io_flush_bits_robIdx_value,
  input  io_flush_bits_level,
  input  io_in_valid,
  input  [34:0] io_in_bits_fuType,
  input  [8:0] io_in_bits_fuOpType,
  input  [63:0] io_in_bits_src_0,
  input  [63:0] io_in_bits_src_1,
  input  io_in_bits_robIdx_flag,
  input  [7:0] io_in_bits_robIdx_value,
  input  [7:0] io_in_bits_pdest,
  input  io_in_bits_rfWen,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  output io_out_valid,
  output [63:0] io_out_bits_data_0,
  output [63:0] io_out_bits_data_1,
  output [7:0] io_out_bits_pdest,
  output io_out_bits_robIdx_flag,
  output [7:0] io_out_bits_robIdx_value,
  output io_out_bits_intWen,
  output [63:0] io_out_bits_debugInfo_enqRsTime,
  output [63:0] io_out_bits_debugInfo_selectTime,
  output [63:0] io_out_bits_debugInfo_issueTime,
  input  cg_bore_cgen,
  input  cg_bore_1_cgen
);
  xs_ExeUnit_core_it u_core (
    .clock(clock),
    .reset(reset),
    .io_flush_valid(io_flush_valid),
    .io_flush_bits_robIdx_flag(io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value(io_flush_bits_robIdx_value),
    .io_flush_bits_level(io_flush_bits_level),
    .io_in_valid(io_in_valid),
    .io_in_bits_fuType(io_in_bits_fuType),
    .io_in_bits_fuOpType(io_in_bits_fuOpType),
    .io_in_bits_src_0(io_in_bits_src_0),
    .io_in_bits_src_1(io_in_bits_src_1),
    .io_in_bits_robIdx_flag(io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(io_in_bits_robIdx_value),
    .io_in_bits_pdest(io_in_bits_pdest),
    .io_in_bits_rfWen(io_in_bits_rfWen),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_out_valid(io_out_valid),
    .io_out_bits_data_0(io_out_bits_data_0),
    .io_out_bits_data_1(io_out_bits_data_1),
    .io_out_bits_pdest(io_out_bits_pdest),
    .io_out_bits_robIdx_flag(io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(io_out_bits_robIdx_value),
    .io_out_bits_intWen(io_out_bits_intWen),
    .io_out_bits_debugInfo_enqRsTime(io_out_bits_debugInfo_enqRsTime),
    .io_out_bits_debugInfo_selectTime(io_out_bits_debugInfo_selectTime),
    .io_out_bits_debugInfo_issueTime(io_out_bits_debugInfo_issueTime),
    .cg_bore_cgen(cg_bore_cgen),
    .cg_bore_1_cgen(cg_bore_1_cgen)
  );
endmodule

