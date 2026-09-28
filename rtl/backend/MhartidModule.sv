// Machine hart ID zero-extends the six-bit platform identifier.
// The semantic core names the operation; the exact-name wrapper preserves integration.
// This leaf is combinational and contains no hidden architectural state.
module xs_MhartidModule_core(input logic [5:0] hart_id,output logic [63:0] value); assign value={58'b0,hart_id}; endmodule
module MhartidModule(output logic [63:0] rdata,input logic [5:0] hartid); xs_MhartidModule_core u_core(.hart_id(hartid),.value(rdata)); endmodule
