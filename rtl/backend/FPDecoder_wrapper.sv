// =============================================================================
// FPDecoder (wrapper) —— golden 同名顶层,端口与 golden/chisel-rtl/FPDecoder.sv 一致。
// 机械适配层:把可读核 xs_FPDecoder_core 的 packed struct 输出拆成 golden 扁平端口。
// =============================================================================
import fpdecoder_pkg::*;

module FPDecoder (
  input  [31:0] io_instr,
  output [1:0]  io_fpCtrl_typeTagOut,
  output        io_fpCtrl_wflags,
  output [1:0]  io_fpCtrl_typ,
  output [1:0]  io_fpCtrl_fmt,
  output [2:0]  io_fpCtrl_rm
);

  fp_ctrl_t ctrl;
  xs_FPDecoder_core u_core (.instr(io_instr), .fp_ctrl(ctrl));

  assign io_fpCtrl_typeTagOut = ctrl.typeTagOut;
  assign io_fpCtrl_wflags     = ctrl.wflags;
  assign io_fpCtrl_typ        = ctrl.typ;
  assign io_fpCtrl_fmt        = ctrl.fmt;
  assign io_fpCtrl_rm         = ctrl.rm;

endmodule
