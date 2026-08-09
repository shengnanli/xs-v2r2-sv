// DiffExt DPI-C sink stubs — exact port directions (all inputs, zero outputs).
// Purpose (codex 0107 harness fix (a)/(b)): the golden dep DummyDPICWrapper.sv /
// DummyDPICWrapper_8.sv instantiate extern DPI modules DiffExtInstrCommit /
// DiffExtTrapEvent with no RTL definition -> Formality creates FM_BBOX designs
// with 519 unknown-direction pins (FM-230) + 2 missing references (FM-064).
// These DPI modules are pure difftest SINKS (no outputs, no feedback into the
// design), so providing exact-direction empty modules lets FM resolve them and
// sweep the whole sink cone as unread logic: unknown-dir BBPin -> 0, missing
// references -> 0, zero functional impact. Port lists/widths transcribed 1:1
// from the golden instantiations in DummyDPICWrapper.sv / DummyDPICWrapper_8.sv.
// NO dont_verify / NO assumption / NO new functional blackbox.

module DiffExtInstrCommit(
  input        clock,
  input        enable,
  input        io_valid,
  input        io_skip,
  input        io_isRVC,
  input        io_rfwen,
  input        io_fpwen,
  input        io_vecwen,
  input        io_v0wen,
  input [7:0]  io_wpdest,
  input [7:0]  io_wdest,
  input [7:0]  io_otherwpdest_0,
  input [7:0]  io_otherwpdest_1,
  input [7:0]  io_otherwpdest_2,
  input [7:0]  io_otherwpdest_3,
  input [7:0]  io_otherwpdest_4,
  input [7:0]  io_otherwpdest_5,
  input [7:0]  io_otherwpdest_6,
  input [7:0]  io_otherwpdest_7,
  input        io_otherV0Wen_0,
  input        io_otherV0Wen_1,
  input        io_otherV0Wen_2,
  input        io_otherV0Wen_3,
  input        io_otherV0Wen_4,
  input        io_otherV0Wen_5,
  input        io_otherV0Wen_6,
  input        io_otherV0Wen_7,
  input [63:0] io_pc,
  input [31:0] io_instr,
  input [9:0]  io_robIdx,
  input [6:0]  io_lqIdx,
  input [6:0]  io_sqIdx,
  input        io_isLoad,
  input        io_isStore,
  input [7:0]  io_nFused,
  input [7:0]  io_special,
  input [7:0]  io_coreid,
  input [7:0]  io_index
);
endmodule

module DiffExtTrapEvent(
  input        clock,
  input        enable,
  input        io_hasTrap,
  input [63:0] io_cycleCnt,
  input [63:0] io_instrCnt,
  input        io_hasWFI,
  input [63:0] io_code,
  input [63:0] io_pc,
  input [7:0]  io_coreid
);
endmodule
