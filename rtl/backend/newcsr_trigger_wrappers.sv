// NewCSR Trigger family AUX wrappers (10 golden modules).
// Thin wrappers over the readable primitives in rtl/backend/newcsr_trigger.sv,
// binding golden per-instance port names. FM-verified per module (strict).

// ===== Tdata{1,2}Module: pure-comb read of selected trigger's tdata bus =====
module Tdata1Module(
  output [63:0] rdata, output [63:0] regOut_ALL, input [63:0] tdataRead_tdata1
);
  xs_tdata_read u_core (.rdata(rdata), .regOut_ALL(regOut_ALL), .tdata_read(tdataRead_tdata1));
endmodule

module Tdata2Module(
  output [63:0] rdata, output [63:0] regOut_ALL, input [63:0] tdataRead_tdata2
);
  xs_tdata_read u_core (.rdata(rdata), .regOut_ALL(regOut_ALL), .tdata_read(tdataRead_tdata2));
endmodule

// ===== Trigger{0..3}_Tdata1Module: mcontrol6 control word + WARL write =====
module Trigger0_Tdata1Module(
  input clock, input reset, input w_wen, input [63:0] w_wdata,
  output [63:0] rdata, input canWriteDmode, input chainable
);
  xs_trigger_tdata1 u_core (.clock(clock), .reset(reset), .w_wen(w_wen),
    .w_wdata(w_wdata), .rdata(rdata), .canWriteDmode(canWriteDmode), .chainable(chainable));
endmodule

module Trigger1_Tdata1Module(
  input clock, input reset, input w_wen, input [63:0] w_wdata,
  output [63:0] rdata, input canWriteDmode, input chainable
);
  xs_trigger_tdata1 u_core (.clock(clock), .reset(reset), .w_wen(w_wen),
    .w_wdata(w_wdata), .rdata(rdata), .canWriteDmode(canWriteDmode), .chainable(chainable));
endmodule

module Trigger2_Tdata1Module(
  input clock, input reset, input w_wen, input [63:0] w_wdata,
  output [63:0] rdata, input canWriteDmode, input chainable
);
  xs_trigger_tdata1 u_core (.clock(clock), .reset(reset), .w_wen(w_wen),
    .w_wdata(w_wdata), .rdata(rdata), .canWriteDmode(canWriteDmode), .chainable(chainable));
endmodule

module Trigger3_Tdata1Module(
  input clock, input reset, input w_wen, input [63:0] w_wdata,
  output [63:0] rdata, input canWriteDmode, input chainable
);
  xs_trigger_tdata1 u_core (.clock(clock), .reset(reset), .w_wen(w_wen),
    .w_wdata(w_wdata), .rdata(rdata), .canWriteDmode(canWriteDmode), .chainable(chainable));
endmodule

// ===== Trigger{0..3}_Tdata2Module: plain 64-bit match register (no reset) =====
module Trigger0_Tdata2Module(
  input clock, input w_wen, input [63:0] w_wdata, output [63:0] rdata
);
  xs_trigger_tdata2 u_core (.clock(clock), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(rdata));
endmodule

module Trigger1_Tdata2Module(
  input clock, input w_wen, input [63:0] w_wdata, output [63:0] rdata
);
  xs_trigger_tdata2 u_core (.clock(clock), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(rdata));
endmodule

module Trigger2_Tdata2Module(
  input clock, input w_wen, input [63:0] w_wdata, output [63:0] rdata
);
  xs_trigger_tdata2 u_core (.clock(clock), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(rdata));
endmodule

module Trigger3_Tdata2Module(
  input clock, input w_wen, input [63:0] w_wdata, output [63:0] rdata
);
  xs_trigger_tdata2 u_core (.clock(clock), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(rdata));
endmodule
