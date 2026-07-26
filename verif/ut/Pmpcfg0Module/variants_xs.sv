// Pmpcfg0Module_xs —— UT 用变体(与 wrapper 同, 仅模块名改 _xs), 例化可读 primitive。
module Pmpcfg0Module_xs(
  output [63:0]  rdata,
  output [63:0]  regOut_ALL,
  input  [127:0] cfgRData
);
  xs_pmpcfg #(.HI(1'b0)) u_core (
    .rdata      (rdata),
    .regOut_ALL (regOut_ALL),
    .cfgRData   (cfgRData)
  );
endmodule
