// FPDecoder_xs —— UT 用可读核包装(golden 同端口,改名避免与 golden 冲突)。
import fpdecoder_pkg::*;

module FPDecoder_it (
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
