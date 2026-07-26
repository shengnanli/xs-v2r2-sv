// indireg _xs UT variants (与 wrapper 同, 模块名改 _xs)。
module SiregModule_xs(
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

module Sireg2Module_xs(
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

