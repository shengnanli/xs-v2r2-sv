// NewCSR topi/topei family AUX wrappers ({M,S,VS}topiModule,
// {M,S,VS}topeiModule). Thin wrappers over the readable combinational primitives
// xs_topi / xs_topei (rtl/backend/newcsr_topi.sv). FM-verified strict, no black
// box. VS variants are H-extension (Kunminghu V2R2 is hypervisor-capable).

module MtopiModule(
  output [63:0] rdata,
  input  [11:0] topIR_mtopi_IID,
  input  [7:0]  topIR_mtopi_IPRIO
);
  xs_topi u_core (.rdata(rdata), .topIR_IID(topIR_mtopi_IID), .topIR_IPRIO(topIR_mtopi_IPRIO));
endmodule

module StopiModule(
  output [63:0] rdata,
  input  [11:0] topIR_stopi_IID,
  input  [7:0]  topIR_stopi_IPRIO
);
  xs_topi u_core (.rdata(rdata), .topIR_IID(topIR_stopi_IID), .topIR_IPRIO(topIR_stopi_IPRIO));
endmodule

module VStopiModule(
  output [63:0] rdata,
  input  [11:0] topIR_vstopi_IID,
  input  [7:0]  topIR_vstopi_IPRIO
);
  xs_topi u_core (.rdata(rdata), .topIR_IID(topIR_vstopi_IID), .topIR_IPRIO(topIR_vstopi_IPRIO));
endmodule

module MtopeiModule(
  output [63:0] rdata,
  output [10:0] regOut_IID,
  output [10:0] regOut_IPRIO,
  input  [10:0] aiaToCSR_mtopei_IID,
  input  [10:0] aiaToCSR_mtopei_IPRIO
);
  xs_topei u_core (.rdata(rdata), .regOut_IID(regOut_IID), .regOut_IPRIO(regOut_IPRIO),
    .aiaToCSR_IID(aiaToCSR_mtopei_IID), .aiaToCSR_IPRIO(aiaToCSR_mtopei_IPRIO));
endmodule

module StopeiModule(
  output [63:0] rdata,
  output [10:0] regOut_IID,
  output [10:0] regOut_IPRIO,
  input  [10:0] aiaToCSR_stopei_IID,
  input  [10:0] aiaToCSR_stopei_IPRIO
);
  xs_topei u_core (.rdata(rdata), .regOut_IID(regOut_IID), .regOut_IPRIO(regOut_IPRIO),
    .aiaToCSR_IID(aiaToCSR_stopei_IID), .aiaToCSR_IPRIO(aiaToCSR_stopei_IPRIO));
endmodule

module VStopeiModule(
  output [63:0] rdata,
  output [10:0] regOut_IID,
  output [10:0] regOut_IPRIO,
  input  [10:0] aiaToCSR_vstopei_IID,
  input  [10:0] aiaToCSR_vstopei_IPRIO
);
  xs_topei u_core (.rdata(rdata), .regOut_IID(regOut_IID), .regOut_IPRIO(regOut_IPRIO),
    .aiaToCSR_IID(aiaToCSR_vstopei_IID), .aiaToCSR_IPRIO(aiaToCSR_vstopei_IPRIO));
endmodule
