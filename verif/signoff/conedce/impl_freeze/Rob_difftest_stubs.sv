// =====================================================================
// Rob_difftest_stubs —— difftest DPI 叶子模块的空 sink 占位
// ---------------------------------------------------------------------
// golden 的 DummyDPICWrapper / DummyDPICWrapper_8 里例化的 DiffExtInstrCommit /
// DiffExtTrapEvent 由 difftest 库提供(DPI-C 探针)。在「无 difftest 库」的本地
// 等价仿真里, 这两个是纯输出 sink(把提交流送参考模型, 对 RTL 无任何反向影响),
// 所以两侧(golden Rob 与 Rob_wrapper)都用同一份空壳即可配平。
//
// 端口名严格对齐 golden 例化, 全部声明为足够宽的 input, 模块体为空。
// =====================================================================

module DiffExtInstrCommit (
  input               clock,
  input               enable,
  input               io_valid,
  input               io_skip,
  input               io_isRVC,
  input               io_rfwen,
  input               io_fpwen,
  input               io_vecwen,
  input               io_v0wen,
  input  [7:0]        io_wpdest,
  input  [7:0]        io_wdest,
  input  [7:0]        io_otherwpdest_0,
  input  [7:0]        io_otherwpdest_1,
  input  [7:0]        io_otherwpdest_2,
  input  [7:0]        io_otherwpdest_3,
  input  [7:0]        io_otherwpdest_4,
  input  [7:0]        io_otherwpdest_5,
  input  [7:0]        io_otherwpdest_6,
  input  [7:0]        io_otherwpdest_7,
  input               io_otherV0Wen_0,
  input               io_otherV0Wen_1,
  input               io_otherV0Wen_2,
  input               io_otherV0Wen_3,
  input               io_otherV0Wen_4,
  input               io_otherV0Wen_5,
  input               io_otherV0Wen_6,
  input               io_otherV0Wen_7,
  input  [63:0]       io_pc,
  input  [31:0]       io_instr,
  input  [9:0]        io_robIdx,
  input  [6:0]        io_lqIdx,
  input  [6:0]        io_sqIdx,
  input               io_isLoad,
  input               io_isStore,
  input  [7:0]        io_nFused,
  input  [7:0]        io_special,
  input  [7:0]        io_coreid,
  input  [7:0]        io_index
);
endmodule

module DiffExtTrapEvent (
  input               clock,
  input               enable,
  input               io_hasTrap,
  input  [63:0]       io_cycleCnt,
  input  [63:0]       io_instrCnt,
  input               io_hasWFI,
  input  [63:0]       io_code,
  input  [63:0]       io_pc,
  input  [7:0]        io_coreid
);
endmodule
