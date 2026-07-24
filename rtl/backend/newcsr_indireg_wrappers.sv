// 自动生成: scripts/gen_newcsr_indireg.py —— 勿手改
// NewCSR indirect-register family thin wrappers ({S,M,VS}iregNModule, 18 modules).
// base (SiregModule/MiregModule/VSiregModule): xs_indireg (write-latch + external
//   rdata passthrough + regOut_ALL); numbered (N=2..6): xs_indireg_wo (latch +
//   regOut_ALL). golden 无 reset —— clock-only 写锁存, 逐位照搬。
// FM-verified against golden in signoff-strict mode.

module SiregModule(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input  [63:0] iregRead_sireg
);
  xs_indireg u_core (
    .clock      (clock),
    .w_wen      (w_wen),
    .w_wdata    (w_wdata),
    .iread      (iregRead_sireg),
    .rdata      (rdata),
    .regOut_ALL (regOut_ALL)
  );
endmodule

module Sireg2Module(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
  xs_indireg_wo u_core (
    .clock      (clock),
    .w_wen      (w_wen),
    .w_wdata    (w_wdata),
    .regOut_ALL (regOut_ALL)
  );
endmodule

module Sireg3Module(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
  xs_indireg_wo u_core (
    .clock      (clock),
    .w_wen      (w_wen),
    .w_wdata    (w_wdata),
    .regOut_ALL (regOut_ALL)
  );
endmodule

module Sireg4Module(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
  xs_indireg_wo u_core (
    .clock      (clock),
    .w_wen      (w_wen),
    .w_wdata    (w_wdata),
    .regOut_ALL (regOut_ALL)
  );
endmodule

module Sireg5Module(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
  xs_indireg_wo u_core (
    .clock      (clock),
    .w_wen      (w_wen),
    .w_wdata    (w_wdata),
    .regOut_ALL (regOut_ALL)
  );
endmodule

module Sireg6Module(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
  xs_indireg_wo u_core (
    .clock      (clock),
    .w_wen      (w_wen),
    .w_wdata    (w_wdata),
    .regOut_ALL (regOut_ALL)
  );
endmodule

module MiregModule(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input  [63:0] iregRead_mireg
);
  xs_indireg u_core (
    .clock      (clock),
    .w_wen      (w_wen),
    .w_wdata    (w_wdata),
    .iread      (iregRead_mireg),
    .rdata      (rdata),
    .regOut_ALL (regOut_ALL)
  );
endmodule

module Mireg2Module(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
  xs_indireg_wo u_core (
    .clock      (clock),
    .w_wen      (w_wen),
    .w_wdata    (w_wdata),
    .regOut_ALL (regOut_ALL)
  );
endmodule

module Mireg3Module(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
  xs_indireg_wo u_core (
    .clock      (clock),
    .w_wen      (w_wen),
    .w_wdata    (w_wdata),
    .regOut_ALL (regOut_ALL)
  );
endmodule

module Mireg4Module(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
  xs_indireg_wo u_core (
    .clock      (clock),
    .w_wen      (w_wen),
    .w_wdata    (w_wdata),
    .regOut_ALL (regOut_ALL)
  );
endmodule

module Mireg5Module(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
  xs_indireg_wo u_core (
    .clock      (clock),
    .w_wen      (w_wen),
    .w_wdata    (w_wdata),
    .regOut_ALL (regOut_ALL)
  );
endmodule

module Mireg6Module(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
  xs_indireg_wo u_core (
    .clock      (clock),
    .w_wen      (w_wen),
    .w_wdata    (w_wdata),
    .regOut_ALL (regOut_ALL)
  );
endmodule

module VSiregModule(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input  [63:0] iregRead_sireg
);
  xs_indireg u_core (
    .clock      (clock),
    .w_wen      (w_wen),
    .w_wdata    (w_wdata),
    .iread      (iregRead_sireg),
    .rdata      (rdata),
    .regOut_ALL (regOut_ALL)
  );
endmodule

module VSireg2Module(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
  xs_indireg_wo u_core (
    .clock      (clock),
    .w_wen      (w_wen),
    .w_wdata    (w_wdata),
    .regOut_ALL (regOut_ALL)
  );
endmodule

module VSireg3Module(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
  xs_indireg_wo u_core (
    .clock      (clock),
    .w_wen      (w_wen),
    .w_wdata    (w_wdata),
    .regOut_ALL (regOut_ALL)
  );
endmodule

module VSireg4Module(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
  xs_indireg_wo u_core (
    .clock      (clock),
    .w_wen      (w_wen),
    .w_wdata    (w_wdata),
    .regOut_ALL (regOut_ALL)
  );
endmodule

module VSireg5Module(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
  xs_indireg_wo u_core (
    .clock      (clock),
    .w_wen      (w_wen),
    .w_wdata    (w_wdata),
    .regOut_ALL (regOut_ALL)
  );
endmodule

module VSireg6Module(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] regOut_ALL
);
  xs_indireg_wo u_core (
    .clock      (clock),
    .w_wen      (w_wen),
    .w_wdata    (w_wdata),
    .regOut_ALL (regOut_ALL)
  );
endmodule
