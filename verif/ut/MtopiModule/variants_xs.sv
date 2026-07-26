// topi/topei UT variants (_xs): the readable combinational primitives.
module MtopiModule_xs(
  output [63:0] rdata, input [11:0] topIR_mtopi_IID, input [7:0] topIR_mtopi_IPRIO
);
  xs_topi u_core (.rdata(rdata), .topIR_IID(topIR_mtopi_IID), .topIR_IPRIO(topIR_mtopi_IPRIO));
endmodule

module MtopeiModule_xs(
  output [63:0] rdata, output [10:0] regOut_IID, output [10:0] regOut_IPRIO,
  input [10:0] aiaToCSR_mtopei_IID, input [10:0] aiaToCSR_mtopei_IPRIO
);
  xs_topei u_core (.rdata(rdata), .regOut_IID(regOut_IID), .regOut_IPRIO(regOut_IPRIO),
    .aiaToCSR_IID(aiaToCSR_mtopei_IID), .aiaToCSR_IPRIO(aiaToCSR_mtopei_IPRIO));
endmodule
